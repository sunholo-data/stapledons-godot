#!/usr/bin/env python3
"""ORACLE ONLY: independent astrometry/centroid verification, never a pipeline.

No Astropy/WCSLIB claim or dependency. Standard-library primary FITS decoding:
https://fits.gsfc.nasa.gov/fits_standard.html (FITS 4.0, 80/2880-byte records,
big-endian IEEE -32 primary array). Spherical gnomonic equations follow
Calabretta & Greisen 2002, A&A 395,1077, section 5.1.3:
https://arxiv.org/abs/astro-ph/0207413 . This scalar spherical derivation is
independent of the package/Godot tangent-basis vector implementation. The
Godot subprocess supplies observations only; it supplies no expected values.

Five centroids are remeasured from pinned science bytes and catalogue RA/Dec:
median background in Chebyshev annulus 6..8; peak search +/-3 pixels; positive
background-subtracted flux centroid in radius 3 about that peak; MAD noise.
This reproduces the documented empirical method, NOT a second centroid
estimator or a sub-pixel accuracy claim. The acceptance limit is one source
pixel, with peak SNR >6. An analytic alignment check alone cannot prove this.
No downloads, generated assets, production imports, or /tmp evidence required.
"""
import argparse
import csv
import hashlib
import io
import json
import math
from pathlib import Path
import re
import statistics
import struct
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
PACK = ROOT / "data/observations/euclid_dr1"
FITS = ROOT / "data/raw/observations/abell3128-vis/source.fits"
FITS_HASH = "529e7a571d083d3788362700e467674fe0ee1df6098d011ce99222280221b57a"
CSV_HASH = "51cd1972fbbc4e2cdbca315b8090d4d09043b19cf4b0456808726fe728b25444"
IDS = ("-524917322525922548", "-524951615526029436", "-525046902526047878", "-524910541526083866", "-525091456525955019")
FIELDS = ("crpixX", "crpixY", "crvalRaDeg", "crvalDecDeg", "cd11", "cd12", "cd21", "cd22")
passed = 0
max_astrometric_error = 0.0


def check(condition, label):
    global passed
    if not condition:
        raise AssertionError(label)
    passed += 1


def rejects(call, label):
    try:
        call()
    except (ValueError, AssertionError):
        check(True, label)
        return
    raise AssertionError("negative control accepted: " + label)


def finite(*values):
    if not all(type(v) in (float, int) and math.isfinite(v) for v in values):
        raise ValueError("non-finite or non-numeric coordinate")


def pinned(blob, digest):
    if hashlib.sha256(blob).hexdigest() != digest:
        raise ValueError("pinned source hash mismatch")
    return blob


def validate_wcs(w):
    finite(*(w[k] for k in FIELDS))
    if not (0 <= w["crvalRaDeg"] < 360 and abs(w["crvalDecDeg"]) <= 90):
        raise ValueError("invalid reference sky")
    if any(abs(w[k]) > (1e9 if k.startswith("crpix") else 360) for k in FIELDS if k.startswith(("cd", "crpix"))):
        raise ValueError("unsupported numeric WCS domain")
    if abs(w["cd11"] * w["cd22"] - w["cd12"] * w["cd21"]) < 1e-24:
        raise ValueError("singular CD")


def header_wcs(h):
    if (h.get("CTYPE1"), h.get("CTYPE2"), h.get("RADESYS"), h.get("CUNIT1"), h.get("CUNIT2")) != ("RA---TAN", "DEC--TAN", "ICRS", "deg", "deg"):
        raise ValueError("only undistorted ICRS RA/DEC TAN in degrees supported")
    distortion = r"^(PV|PS)\d_|^(CPDIS|DP\d|D2IM|DET2IM)|^(A|B|AP|BP)_ORDER$|^PC\d_|^CDELT"
    if any(re.search(distortion, k) for k in h):
        raise ValueError("distortion or mixed linear convention refused")
    w = dict(zip(FIELDS, (float(h[k].replace("D", "E")) for k in ("CRPIX1", "CRPIX2", "CRVAL1", "CRVAL2", "CD1_1", "CD1_2", "CD2_1", "CD2_2"))))
    validate_wcs(w)
    return w


def fits_value(text):
    # A slash inside a FITS quoted string is data, not a comment delimiter.
    if text.lstrip().startswith("'"):
        text = text.lstrip()[1:]
        result, i = "", 0
        while i < len(text):
            if text[i] == "'":
                if i + 1 < len(text) and text[i + 1] == "'":
                    result += "'"
                    i += 2
                    continue
                return result.strip()
            result += text[i]
            i += 1
        raise ValueError("unclosed FITS string")
    return text.split("/", 1)[0].strip()


def read_fits(blob):
    if len(blob) > 32 * 1024 * 1024 or len(blob) % 2880:
        raise ValueError("unbounded or incomplete FITS blocks")
    h, start = {}, None
    for offset in range(0, min(len(blob), 2880 * 64), 80):
        card = blob[offset:offset + 80].decode("ascii")
        key = card[:8].strip()
        if key == "END":
            start = (offset // 2880 + 1) * 2880
            break
        if card[8:10] == "= ":
            if key in h:
                raise ValueError("duplicate FITS keyword")
            h[key] = fits_value(card[10:])
    if start is None or (h.get("SIMPLE"), h.get("BITPIX"), h.get("NAXIS")) != ("T", "-32", "2"):
        raise ValueError("unsupported primary FITS array")
    width, height = int(h["NAXIS1"]), int(h["NAXIS2"])
    if not (1 <= width <= 4096 and 1 <= height <= 4096) or start + width * height * 4 > len(blob):
        raise ValueError("invalid/truncated FITS dimensions")
    w = header_wcs(h)
    scale, zero = float(h.get("BSCALE", "1")), float(h.get("BZERO", "0"))
    finite(scale, zero)
    values = [v[0] * scale + zero for v in struct.iter_unpack(">f", blob[start:start + width * height * 4])]
    finite(*values)
    return h, w, width, height, values


def sky_to_pixel(w, ra, dec):
    """Scalar spherical TAN + independent 2x2 inverse, FITS ONE-based."""
    validate_wcs(w)
    finite(ra, dec)
    if not (0 <= ra < 360 and abs(dec) <= 90):
        raise ValueError("invalid sky")
    a, d, a0, d0 = map(math.radians, (ra, dec, w["crvalRaDeg"], w["crvalDecDeg"]))
    delta = a - a0
    denominator = math.sin(d0) * math.sin(d) + math.cos(d0) * math.cos(d) * math.cos(delta)
    if denominator <= 1e-12:
        raise ValueError("outside tangent hemisphere")
    xi = math.degrees(math.cos(d) * math.sin(delta) / denominator)
    eta = math.degrees((math.cos(d0) * math.sin(d) - math.sin(d0) * math.cos(d) * math.cos(delta)) / denominator)
    det = w["cd11"] * w["cd22"] - w["cd12"] * w["cd21"]
    return (w["crpixX"] + (w["cd22"] * xi - w["cd12"] * eta) / det,
            w["crpixY"] + (w["cd11"] * eta - w["cd21"] * xi) / det)


def pixel_to_sky(w, x, y):
    """Inverse spherical gnomonic using angular radius c=atan(rho)."""
    validate_wcs(w)
    finite(x, y)
    if max(abs(x), abs(y)) > 1e9:
        raise ValueError("pixel outside numerical domain")
    dx, dy = x - w["crpixX"], y - w["crpixY"]
    xi, eta = map(math.radians, (w["cd11"] * dx + w["cd12"] * dy, w["cd21"] * dx + w["cd22"] * dy))
    rho = math.hypot(xi, eta)
    if rho == 0:
        return w["crvalRaDeg"], w["crvalDecDeg"]
    a0, d0 = map(math.radians, (w["crvalRaDeg"], w["crvalDecDeg"]))
    c = math.atan(rho)
    dec = math.asin(max(-1, min(1, math.cos(c) * math.sin(d0) + eta * math.sin(c) * math.cos(d0) / rho)))
    ra = a0 + math.atan2(xi * math.sin(c), rho * math.cos(d0) * math.cos(c) - eta * math.sin(d0) * math.sin(c))
    return math.degrees(ra) % 360, math.degrees(dec)


def centroid(values, width, height, x, y):
    finite(x, y)
    ix, iy = round(x), round(y)
    if not (8 <= ix < width - 8 and 8 <= iy < height - 8):
        raise ValueError("centroid measurement window outside source")
    annulus = [values[j * width + i] for j in range(iy - 8, iy + 9) for i in range(ix - 8, ix + 9) if max(abs(i - ix), abs(j - iy)) >= 6]
    background = statistics.median(annulus)
    sigma = 1.4826 * statistics.median(abs(v - background) for v in annulus)
    peak, px, py = max((values[j * width + i], i, j) for j in range(iy - 3, iy + 4) for i in range(ix - 3, ix + 4))
    samples = [(i, j, max(0, values[j * width + i] - background)) for j in range(py - 3, py + 4) for i in range(px - 3, px + 4) if (i - px)**2 + (j - py)**2 <= 9]
    total = sum(v for _, _, v in samples)
    if total <= 0 or sigma <= 0:
        raise ValueError("centroid has no positive flux or measurable noise")
    return sum(i * v for i, _, v in samples) / total, sum(j * v for _, j, v in samples) / total, (peak - background) / sigma


def close_pixel(actual, expected, label, limit=0.1):
    global max_astrometric_error
    finite(*actual, *expected)
    error = math.dist(actual, expected)
    check(error < limit, label)
    if label.startswith(("Godot", "independent forward versus")):
        max_astrometric_error = max(max_astrometric_error, error)


def galactic(ra, dec):
    # Spherical rotation from Hipparcos SP-1200 vol1 eq1.5.11 defining angles;
    # avoids reusing the game's rounded Cartesian rotation matrix.
    a, d, ag, dg = map(math.radians, (ra, dec, 192.85948, 27.12825))
    b = math.asin(math.sin(d) * math.sin(dg) + math.cos(d) * math.cos(dg) * math.cos(a - ag))
    l = math.radians(122.93192) - math.atan2(math.cos(d) * math.sin(a - ag), math.sin(d) * math.cos(dg) - math.cos(d) * math.sin(dg) * math.cos(a - ag))
    return math.cos(b) * math.cos(l), math.cos(b) * math.sin(l), math.sin(b)


def main(godot, probe_fault):
    blob = pinned(FITS.read_bytes(), FITS_HASH)
    catalogue = pinned((PACK / "sources.csv").read_bytes(), CSV_HASH)
    h, w, width, height, values = read_fits(blob)
    check((width, height) == (724, 724), "pinned real FITS dimensions")
    rows = list(csv.DictReader(io.StringIO(catalogue.decode())))
    chosen = []
    for identity in IDS:
        matches = [r for r in rows if r["object_id"] == identity and r["tile_index"] == "102017310"]
        check(len(matches) == 1, "unambiguous pinned composite source identity")
        chosen.append(matches[0])
    manifest = json.loads((PACK / "manifest.json").read_text())
    plate = next(p for p in manifest["plates"] if p["id"] == "abell3128-vis")
    check(plate["source_sha256"] == FITS_HASH, "manifest source bytes pinned")
    check(plate["registration"]["wcs"] == w, "manifest WCS equals independent actual FITS header")
    cases, centroid_residuals, centroid_snrs = [], [], []
    for row in chosen:
        ra, dec = float(row["right_ascension"]), float(row["declination"])
        x, y = sky_to_pixel(w, ra, dec)
        mx, my, snr = centroid(values, width, height, x - 1, y - 1)
        close_pixel((mx, my), (x - 1, y - 1), "empirical source centroid <1 pixel", 1.0)
        check(snr > 6, "empirical centroid SNR >6")
        centroid_residuals.append(math.hypot(mx - (x - 1), my - (y - 1)))
        centroid_snrs.append(snr)
        anchor = next(a for a in plate["registration"]["anchors"] if a["source_id"].endswith(":" + row["object_id"]))
        check((anchor["ra_deg"], anchor["dec_deg"]) == (ra, dec), "anchor sky equals pinned catalogue")
        close_pixel((x - 1, height - y), (anchor["source_x"], anchor["source_y"]), "recomputed analytic anchor", 1e-6)
        close_pixel((mx, height - 1 - my), (anchor["reference_x"], anchor["reference_y"]), "remeasured empirical anchor", 1e-6)
        cases.append({"op": "sky", "wcs": w, "a": ra, "b": dec})
    simple = dict(zip(FIELDS, (1.0, 1.0, 0.0, 0.0, -0.02, 0.01, 0.015, 0.03)))
    # Check controls before comparing observations: a permissive comparator is
    # itself a defect. These deliberate wrong answers must fail this same check.
    rejects(lambda: close_pixel((1.5, 1.0), (1.0, 1.0), "half-pixel mutation"), "half-pixel negative")
    swapped = dict(simple, cd12=simple["cd21"], cd21=simple["cd12"])
    target = pixel_to_sky(simple, 123, 77)
    rejects(lambda: close_pixel(sky_to_pixel(swapped, *target), (123, 77), "CD transpose mutation"), "CD orientation negative")
    rejects(lambda: pinned(blob[:-1] + bytes([blob[-1] ^ 1]), FITS_HASH), "source byte mutation")
    rejects(lambda: header_wcs(dict(h, CTYPE1="RA---TAN-SIP")), "SIP distortion refused")
    rejects(lambda: header_wcs(dict(h, PV1_0="1.0")), "PV distortion refused")
    rejects(lambda: sky_to_pixel(w, math.nan, 0), "non-finite reference sky")
    rejects(lambda: pixel_to_sky(w, math.inf, 0), "non-finite reference pixel")
    rejects(lambda: validate_wcs(dict(simple, cd11=0, cd12=0)), "singular reference CD")
    rejects(lambda: sky_to_pixel(simple, 180, 0), "reference back hemisphere")
    rejects(lambda: centroid([0.0] * 400, 20, 20, 10, 10), "empty-flux centroid")
    for i in range(25):
        cases.append({"op": "pixel", "wcs": w, "a": 1.0 + 29 * i, "b": 1.0 + 17 * i})
    for centre_ra, centre_dec in [(0, 0), (359.99, 20), (42, 90), (42, -90)]:
        test_wcs = dict(simple, crvalRaDeg=centre_ra, crvalDecDeg=centre_dec)
        for x, y in [(1, 1), (12, -7), (-300, 200), (2, 3)]:
            cases.append({"op": "pixel", "wcs": test_wcs, "a": x, "b": y})
    # Footprint centre and physical pixel edges, independently read from FITS.
    edge_pixels = [((width + 1) / 2, (height + 1) / 2), (0.5, 0.5), (width + 0.5, 0.5), (width + 0.5, height + 0.5), (0.5, height + 0.5)]
    footprint = json.loads((PACK / "footprints.json").read_text())["fields"][0]
    vectors = [footprint["centre_galactic"], *footprint["corners_galactic"]]
    for xy, stored in zip(edge_pixels, vectors):
        expected = galactic(*pixel_to_sky(w, *xy))
        # Published matrix is rounded to 10 decimals; spherical defining angles
        # differ by <1e-10 per component. This tolerance is still <<0.1 pixel.
        check(max(abs(v - stored[k]) for v, k in zip(expected, "xyz")) < 2e-10, "independent physical footprint and galactic rotation")
        cases.append({"op": "pixel", "wcs": w, "a": xy[0], "b": xy[1]})
    with tempfile.TemporaryDirectory(prefix="observation-oracle-") as temporary:
        for case in cases:
            if case["op"] == "pixel":
                case["oracle_ra"], case["oracle_dec"] = pixel_to_sky(case["wcs"], case["a"], case["b"])
        path = Path(temporary) / "requests.json"
        path.write_text(json.dumps({"cases": cases, "probe_fault": probe_fault}, allow_nan=False))
        run = subprocess.run([godot, "--headless", "--path", str(ROOT), "--script", "tools/observation_projection_oracle_probe.gd", "--", str(path)], text=True, capture_output=True, timeout=20)
    check(run.returncode == 0 and "SCRIPT ERROR" not in run.stdout + run.stderr, "Godot probe exit and script errors")
    output = [line.split(":", 1)[1] for line in run.stdout.splitlines() if line.startswith("OBSERVATION_ORACLE_JSON:")]
    check(len(output) == 1, "exactly one structured probe response")
    response = json.loads(output[0])
    check(len(response["results"]) == len(cases), "probe response count")
    for case, actual in zip(cases, response["results"]):
        check(actual.get("ok") is True, "valid projection accepted")
        cw = case["wcs"]
        if case["op"] == "sky":
            close_pixel((actual["x"], actual["y"]), sky_to_pixel(cw, case["a"], case["b"]), "Godot inverse versus independent spherical TAN")
        else:
            close_pixel(sky_to_pixel(cw, actual["ra_deg"], actual["dec_deg"]), (case["a"], case["b"]), "Godot forward versus independent inverse")
            mirror_inverse = actual["oracle_sky_inverse"]
            check(mirror_inverse.get("ok") is True, "independent forward sky accepted by Godot inverse")
            close_pixel((mirror_inverse["x"], mirror_inverse["y"]), (case["a"], case["b"]), "independent forward versus Godot inverse")
            # oracle_ra/dec were computed before running Godot, never from actual
            # results. Keeps the two directions independently tested.
    check(response["rejected"] == [True] * 4, "Godot non-finite/singular/back-hemisphere controls rejected")
    print("oracle: %d cases; max astrometric error %.3g source px; 5 centroids max %.6f px, min SNR %.6f" % (len(cases), max_astrometric_error, max(centroid_residuals), min(centroid_snrs)))
    print("observation-projection-oracle: %d passed, 0 failures" % passed)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default="godot")
    parser.add_argument("--probe-fault", choices=("half-pixel",), help="test-only deliberate wrong observation; this run MUST fail")
    args = parser.parse_args()
    try:
        main(args.godot, args.probe_fault)
    except (AssertionError, ValueError, KeyError, OSError, subprocess.TimeoutExpired) as error:
        print("FAIL observation-projection-oracle:", error)
        print("observation-projection-oracle: %d passed, 1 failures" % passed)
        raise SystemExit(1)
