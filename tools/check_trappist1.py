#!/usr/bin/env python3
"""Oracle for TRAPPIST-1's planets (sim/data/trappist1.ail, sim/trappist1.ail;
design_docs/planned/r1/trappist1-planets-sprint.md, TB2).

An independent second implementation in Python. It reads the pinned archive
snapshot itself (data/planets/trappist1_ps.csv, sha256 in
data/planets/EXOPLANETS.SHA256) and the star's catalogue row
(data/starmap/stars.json), and:
  * checks every transcribed number in the AILANG data against the archive rows
    (Agol et al. 2021, the default set, for P, a, R, M, i; Ducrot et al. 2020 for
    the mean ephemeris T0, P);
  * recomputes every planet's position about the star, in the galactic frame,
    from the closed-form circular orbit in the sky basis (north, east, toward
    Earth): r = a (cos M n + sin M (cos i e + sin i z)), M = 90 deg +
    2 pi (jd + D/c - T0) / P, with its own galactic north celestial pole
    (l = 122.93192 deg, b = 27.12825 deg; J2000, Hipparcos convention), and
    compares with the sim's within 2e-8 AU (3 km);
  * checks the light time D/c against the catalogue distance.
Input: the sim's dump (`trappistVm` output) on stdin or as argv[1]. Exit 1 on
any disagreement.
"""
import csv
import hashlib
import json
import math
import sys

SNAP = "data/planets/trappist1_ps.csv"
PIN = "data/planets/EXOPLANETS.SHA256"
STARS = "data/starmap/stars.json"
GAIA = "Gaia DR3 2635476908753563008"
failures = []


def fail(msg):
    failures.append(msg)
    print("FAIL", msg)


def pinned():
    want = None
    for line in open(PIN):
        parts = line.split()
        if len(parts) == 2 and parts[1] == SNAP:
            want = parts[0]
    got = hashlib.sha256(open(SNAP, "rb").read()).hexdigest()
    if got != want:
        fail("snapshot sha256 %s != pin %s" % (got, want))


def rows():
    agol, ducrot = {}, {}
    for r in csv.DictReader(open(SNAP)):
        letter = r["pl_letter"]
        if "AGOL_ET_AL__2021" in r["pl_refname"] and r["default_flag"] == "1":
            agol[letter] = r
        if "DUCROT_ET_AL__2020" in r["pl_refname"]:
            ducrot[letter] = r
    return agol, ducrot


def unit(v):
    n = math.sqrt(sum(x * x for x in v))
    return [x / n for x in v]


def cross(a, b):
    return [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]


def main():
    text = open(sys.argv[1]).read() if len(sys.argv) > 1 else sys.stdin.read()
    lines = text.strip().splitlines()
    if not lines or lines[0].strip() != "trappist1: OK":
        fail("sim checks did not pass: %r" % (lines[0] if lines else ""))
    pinned()
    agol, ducrot = rows()
    if sorted(agol) != list("bcdefgh") or sorted(ducrot) != list("bcdefgh"):
        fail("archive snapshot lacks a planet: agol %s ducrot %s" % (sorted(agol), sorted(ducrot)))
        return
    star = [s for s in json.load(open(STARS))["stars"] if s["id"] == GAIA][0]
    pos = [star["x"], star["y"], star["z"]]
    dist_ly = math.sqrt(sum(x * x for x in pos))
    # Galactic frame: x toward the centre, z the north galactic pole. The north
    # celestial pole in galactic coordinates (J2000).
    l, b = math.radians(122.93192), math.radians(27.12825)
    ncp = [math.cos(b) * math.cos(l), math.cos(b) * math.sin(l), math.sin(b)]
    radial = unit(pos)
    east = unit(cross(ncp, radial))
    north = unit(cross(radial, east))
    toward = [-x for x in radial]
    keys = ["period_d", "a_au", "radius_earth", "mass_earth", "incl_deg", "t0_bjd", "ephem_period_d"]
    data = {}
    positions = []
    light = None
    for line in lines[1:]:
        f = line.split()
        if f[0] == "row":
            data[f[1]] = dict(zip(keys, map(float, f[2:])))
        elif f[0] == "pos":
            positions.append((f[1], float(f[2]), [float(x) for x in f[3:6]]))
        elif f[0] == "lightdays":
            light = float(f[1])
    if light is None or abs(light - dist_ly * 365.25) > 1e-9:
        fail("light time %r != catalogue distance %.12f ly x 365.25" % (light, dist_ly))
    for letter in "bcdefgh":
        pid = "trappist-1" + letter
        a, d, got = agol[letter], ducrot[letter], data.get(pid)
        if got is None:
            fail("no data row for " + pid)
            continue
        want = {"period_d": a["pl_orbper"], "a_au": a["pl_orbsmax"], "radius_earth": a["pl_rade"], "mass_earth": a["pl_masse"],
                "incl_deg": a["pl_orbincl"], "t0_bjd": d["pl_tranmid"], "ephem_period_d": d["pl_orbper"]}
        for k, v in want.items():
            if got[k] != float(v):
                fail("%s %s: sim %r, archive %r" % (pid, k, got[k], v))
    worst = 0.0
    for pid, jd, p in positions:
        r = data[pid]
        m = math.pi / 2 + 2 * math.pi * (jd + dist_ly * 365.25 - r["t0_bjd"]) / r["ephem_period_d"]
        i = math.radians(r["incl_deg"])
        sky = [r["a_au"] * math.cos(m), r["a_au"] * math.sin(m) * math.cos(i), r["a_au"] * math.sin(m) * math.sin(i)]
        want = [sky[0] * north[k] + sky[1] * east[k] + sky[2] * toward[k] for k in range(3)]
        err = math.sqrt(sum((p[k] - want[k]) ** 2 for k in range(3)))
        worst = max(worst, err)
        if err > 2e-8:
            fail("%s at JD %.6f: sim %s, oracle %s (%.3g AU)" % (pid, jd, p, want, err))
    print("trappist1 oracle: %d rows, %d positions, worst %.2e AU (%.3f km), %d failures" % (len(data), len(positions), worst, worst * 149597870.7, len(failures)))
    sys.exit(1 if failures else 0)


if __name__ == "__main__":
    main()
