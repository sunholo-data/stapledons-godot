#!/usr/bin/env python3
"""Verify data/starmap/names.json against data/starmap/stars.json (M2.6b, D-17).

Each name row is keyed by catalogue index and must carry that entry's id.
Its `ref` holds literature values (J2000 RA/Dec, distance, V; SIMBAD/RECONS).
A row passes only when the catalogue entry agrees with them:

  * id equal, and the entry is the component nearest in V among the entries
    sharing that id (A/B pairs share an id, e.g. "Gl 559");
  * distance within 20 %, and a warning past 3 %: the committed stars.json
    disagrees with literature parallaxes by up to ~15 % for some stars
    (e.g. Fomalhaut 21.2 vs 25.1 ly, Tau Ceti 11.40 vs 11.91 ly), so the
    distance confirms the neighbourhood only; the identification rests on
    id + position on the sky + V;
  * galactic latitude b within 1 degree;
  * galactic longitude within 1 degree, see LONGITUDE below;
  * V within 0.5 mag (0.35 when components share the id).

LONGITUDE: the committed stars.json was built by the starmap-manager
`process_stars.sh` script, which adds the arctangent to l_NCP where the
IAU transformation subtracts it, so every catalogue longitude is mirrored:
l_cat = 2 * 122.93192 - l (latitude and distance are right). This checker
compares against the mirrored longitude and reports it; the positions are
not changed here (D-17: the map shows the catalogue's own value; the M1.2
tier pipeline, tools/extract.py, uses the IAU matrix).

stdlib only. Exit 0 when every row passes.
"""
import json
import math
import os
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
L_NCP = 122.93192
# IAU ICRS -> galactic rotation (rows x_gal, y_gal, z_gal), as tools/extract.py.
M = ((-0.0548755604162154, -0.8734370902348850, -0.4838350155487132),
     (0.4941094278755837, -0.4448296299600112, 0.7469822444972189),
     (-0.8676661490190047, -0.1980763734312015, 0.4559837761750669))


def galactic(ra, dec):
    r, d = math.radians(ra), math.radians(dec)
    v = (math.cos(d) * math.cos(r), math.cos(d) * math.sin(r), math.sin(d))
    g = [sum(M[i][k] * v[k] for k in range(3)) for i in range(3)]
    return math.degrees(math.atan2(g[1], g[0])) % 360.0, math.degrees(math.asin(g[2]))


def dl(a, b):
    return abs((a - b + 180.0) % 360.0 - 180.0)


def check(names, stars):
    bad = []
    seen = set()
    for row in names:
        i, ref = row["index"], row["ref"]
        tag = "%s (#%d %s)" % (row["name"], i, row["id"])
        if i in seen:
            bad.append("%s: index named twice" % tag)
        seen.add(i)
        if not 0 <= i < len(stars) or stars[i]["id"] != row["id"]:
            bad.append("%s: catalogue id is %r" % (tag, stars[i]["id"] if 0 <= i < len(stars) else None))
            continue
        s = stars[i]
        mates = [j for j, t in enumerate(stars) if t["id"] == row["id"]]
        nearest = min(mates, key=lambda j: abs(stars[j]["vmag"] - ref["vmag"]))
        d = math.sqrt(s["x"] ** 2 + s["y"] ** 2 + s["z"] ** 2)
        l_cat = math.degrees(math.atan2(s["y"], s["x"])) % 360.0
        b_cat = math.degrees(math.asin(s["z"] / d))
        l, b = galactic(ref["ra_deg"], ref["dec_deg"])
        l_mirror = (2.0 * L_NCP - l) % 360.0
        dv_tol = 0.5 if len(mates) == 1 else 0.35
        errs = []
        if nearest != i:
            errs.append("V nearer to component #%d" % nearest)
        if abs(d - ref["dist_ly"]) > 0.20 * ref["dist_ly"]:
            errs.append("distance %.3f vs %.3f ly" % (d, ref["dist_ly"]))
        warn = abs(d - ref["dist_ly"]) > 0.03 * ref["dist_ly"]
        if abs(b_cat - b) > 1.0:
            errs.append("b %.2f vs %.2f deg" % (b_cat, b))
        if dl(l_cat, l_mirror) > 1.0:
            errs.append("l %.2f vs mirrored %.2f deg (IAU %.2f)" % (l_cat, l_mirror, l))
        if abs(s["vmag"] - ref["vmag"]) > dv_tol:
            errs.append("V %.2f vs %.2f" % (s["vmag"], ref["vmag"]))
        status = "ok  " if not errs else "FAIL"
        print("  %s %-34s #%-4d %-8s d %6.3f/%6.2f  b %6.2f/%6.2f  l %6.2f/%6.2f  V %5.2f/%5.2f %s" % (
            status, row["name"], i, row["id"], d, ref["dist_ly"], b_cat, b, l_cat, l_mirror,
            s["vmag"], ref["vmag"], "; ".join(errs) + ("  (catalogue distance %+.1f %%)" % (100.0 * (d / ref["dist_ly"] - 1.0)) if warn else "")))
        if errs:
            bad.append("%s: %s" % (tag, "; ".join(errs)))
    return bad


def main():
    stars = json.load(open(os.path.join(ROOT, "data/starmap/stars.json")))["stars"]
    names = json.load(open(os.path.join(ROOT, "data/starmap/names.json")))["names"]
    bad = check(names, stars)
    # negative control: a swapped pair must fail
    swapped = [dict(r) for r in names if r["id"] == "Gl 559"]
    if len(swapped) == 2:
        swapped[0]["index"], swapped[1]["index"] = swapped[1]["index"], swapped[0]["index"]
        print("negative control (alpha Cen A/B indices swapped):")
        if not check(swapped, stars):
            bad.append("negative control: swapped A/B passed")
    print("star names: %d rows, %d failures" % (len(names), len(bad)))
    for b in bad:
        print("  " + b)
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
