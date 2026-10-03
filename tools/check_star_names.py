#!/usr/bin/env python3
"""Verify data/starmap/names.json against data/starmap/stars.json (D-17; re-keyed in M1.7).

Each name row is keyed by the stable catalogue id ("Gaia DR3 n", "CNS5:n" or
"HIP n"), unique in both files. Its `ref` holds literature values (J2000
RA/Dec, distance, V; SIMBAD/RECONS). A row passes only when the catalogue
entry agrees with them:

  * the id is in stars.json, once, and named once;
  * direction within 0.1 degree of the J2000 position (the catalogue rows are
    at their own epoch, mostly Gaia J2016.0: Barnard's Star moves 0.046 degree
    in 16 years);
  * distance within 3 % (the CNS5/HIP2 parallaxes; alpha Cen sits at the CNS5
    system parallax, 4.321 ly against 4.37, per D-19), a note past 1 %;
  * V within 0.3 mag, unless the row has no photometry (flags bit 2, V 99:
    the identification then rests on direction + distance, and it is listed).

The IAU ICRS -> galactic matrix below is the one tools/extract.py used; it is
independent of the AILANG pipeline (sim/tools/extract.ail, bright.ail).
Negative controls: alpha Cen A and B ids swapped must fail, and so must a row
whose id is not in the catalogue.

stdlib only. Exit 0 when every row passes.
"""
import json
import math
import os
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
# IAU ICRS -> galactic rotation (rows x_gal, y_gal, z_gal), as tools/extract.py.
M = ((-0.0548755604162154, -0.8734370902348850, -0.4838350155487132),
     (0.4941094278755837, -0.4448296299600112, 0.7469822444972189),
     (-0.8676661490190047, -0.1980763734312015, 0.4559837761750669))


def galactic_unit(ra, dec):
    r, d = math.radians(ra), math.radians(dec)
    v = (math.cos(d) * math.cos(r), math.cos(d) * math.sin(r), math.sin(d))
    return [sum(M[i][k] * v[k] for k in range(3)) for i in range(3)]


def check(names, stars):
    bad = []
    by_id = {}
    for t in stars:
        by_id.setdefault(t["id"], []).append(t)
    for k, v in by_id.items():
        if len(v) > 1:
            bad.append("stars.json: id %s occurs %d times" % (k, len(v)))
    seen = set()
    for row in names:
        ref = row["ref"]
        tag = "%s (%s)" % (row["name"], row["id"])
        if row["id"] in seen:
            bad.append("%s: id named twice" % tag)
        seen.add(row["id"])
        if row["id"] not in by_id:
            bad.append("%s: id not in stars.json" % tag)
            continue
        s = by_id[row["id"]][0]
        d = math.sqrt(s["x"] ** 2 + s["y"] ** 2 + s["z"] ** 2)
        u = galactic_unit(ref["ra_deg"], ref["dec_deg"])
        sep = math.degrees(math.acos(max(-1.0, min(1.0, (s["x"] * u[0] + s["y"] * u[1] + s["z"] * u[2]) / d))))
        no_phot = (int(s["flags"]) & 2) != 0
        errs = []
        if sep > 0.1:
            errs.append("direction %.3f deg off" % sep)
        if abs(d - ref["dist_ly"]) > 0.03 * ref["dist_ly"]:
            errs.append("distance %.3f vs %.3f ly" % (d, ref["dist_ly"]))
        if not no_phot and abs(s["vmag"] - ref["vmag"]) > 0.3:
            errs.append("V %.2f vs %.2f" % (s["vmag"], ref["vmag"]))
        notes = []
        if abs(d - ref["dist_ly"]) > 0.01 * ref["dist_ly"]:
            notes.append("catalogue distance %+.1f %%" % (100.0 * (d / ref["dist_ly"] - 1.0)))
        if no_phot:
            notes.append("no photometry in the catalogue: V not checked")
        status = "ok  " if not errs else "FAIL"
        print("  %s %-30s %-30s sep %.4f  d %7.3f/%6.2f  V %5.2f/%5.2f %s" % (
            status, row["name"], row["id"], sep, d, ref["dist_ly"], s["vmag"], ref["vmag"],
            "; ".join(errs + notes)))
        if errs:
            bad.append("%s: %s" % (tag, "; ".join(errs)))
    return bad


def main():
    stars = json.load(open(os.path.join(ROOT, "data/starmap/stars.json")))["stars"]
    names = json.load(open(os.path.join(ROOT, "data/starmap/names.json")))["names"]
    bad = check(names, stars)
    # negative controls: alpha Cen A and B swapped, and an id the catalogue lacks, must both fail
    acen = {r["name"]: r for r in names if r["name"].startswith("Alpha Centauri ")}
    if len(acen) == 2:
        a, b = dict(acen["Alpha Centauri A"]), dict(acen["Alpha Centauri B"])
        a["id"], b["id"] = b["id"], a["id"]
        print("negative control (alpha Cen A/B ids swapped):")
        if len(check([a, b], stars)) != 2:
            bad.append("negative control: swapped A/B passed")
    else:
        bad.append("negative control: alpha Cen A and B are not both named")
    ghost = dict(names[0], id="CNS5:999999")
    print("negative control (id not in the catalogue):")
    if not check([ghost], stars):
        bad.append("negative control: unknown id passed")
    print("star names: %d rows, %d failures" % (len(names), len(bad)))
    for b in bad:
        print("  " + b)
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
