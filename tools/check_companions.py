#!/usr/bin/env python3
"""Oracle for the companion rule (sim/tools/companions.ail, design_docs/planned/r1/m1-companion-parallax.md).

An independent second implementation in Python over CNS5 (data/raw/cns5.dat) and GCNS
(data/raw/table1c.dat.gz): its own fixed-width parsing, its own proper-motion propagation
(spherical linear in RA/Dec, not the AILANG vector form), true angles (asin) rather than chords,
and its own pair search (bisect on a z-sorted list). It recomputes every companion and compares
with the committed data/starmap/companions/companions.csv.

The bright tier (HIP2 rows kept by rule a) is not rebuilt here, so any table row whose id, parent
or root is a "HIP n" star is left out of the comparison and counted. Every other row must agree:
the same companions, parents and roots, the same root parallax (bit for bit: both parse the same
catalogue text), separations within 0.005 arcsec (the two propagations differ by up to ~1 mas for
fast stars at the Hipparcos epoch, 25 years from J2016.0).

Run by `make catalogue-verify` (needs data/raw). Exit 1 on any disagreement.
"""
import bisect
import gzip
import math
import sys

RAW = "data/raw/"
TABLE = "data/starmap/companions/companions.csv"
N_ARCSEC, MAX_AU, MAX_FRAC, CLOSE_FRAC, N_SIGMA, PM_FLOOR = 60.0, 2000.0, 0.2, 0.05, 3.0, 0.2
D = math.pi / 180.0


def num(line, lo, hi):
    t = line[lo - 1:hi].strip()
    if t in ("", "-"):
        return None
    try:
        v = float(t)
    except ValueError:
        return None
    return v if math.isfinite(v) else None


def star(sid, ra, de, ep, plx, eplx, pmra, pmde, mag):
    dt = 2016.0 - ep
    dec = de + pmde * dt / 3.6e6
    ra2 = ra + pmra * dt / 3.6e6 / math.cos(de * D)
    u = (math.cos(dec * D) * math.cos(ra2 * D), math.cos(dec * D) * math.sin(ra2 * D), math.sin(dec * D))
    return {"id": sid, "u": u, "plx": plx, "eplx": eplx, "pmra": pmra, "pmde": pmde, "mag": mag}


def cns5():
    out = []
    for line in open(RAW + "cns5.dat"):
        vals = [num(line, *c) for c in ((55, 74), (76, 98), (100, 108), (130, 148), (150, 162), (184, 206), (230, 252))]
        if any(v is None for v in vals) or vals[3] <= 0:
            continue
        gaia = line[27:46].strip()
        sid = gaia if gaia not in ("", "-") else "CNS5:" + line[0:4].strip()
        mag = next((m for m in (num(line, 362, 371), num(line, 461, 480), num(line, 544, 555)) if m is not None), 99.0)
        out.append(star(sid, *vals, mag))
    return out


def gcns(skip):
    out = []
    with gzip.open(RAW + "table1c.dat.gz", "rt") as f:
        for line in f:
            ra, de, plx, e, pa, pd = (num(line, *c) for c in ((23, 36), (46, 59), (69, 77), (79, 85), (87, 95), (105, 113)))
            if None in (ra, de, plx, e, pa, pd) or plx <= 0:
                continue
            sid = line[2:21].strip()
            if sid in skip:
                continue
            g = num(line, 123, 130)
            out.append(star(sid, ra, de, 2016.0, plx, e, pa, pd, 99.0 if g is None else g))
    return out


def key(s):
    return (s["mag"], s["eplx"], s["id"])


def same_system(p, q, sep):
    dp = abs(p["plx"] - q["plx"])
    dmu = math.hypot(p["pmra"] - q["pmra"], p["pmde"] - q["pmde"])
    mu = math.hypot(p["pmra"], p["pmde"])
    orbit = 0.44 * p["plx"] ** 1.5 / math.sqrt(max(sep, 0.01))
    return (sep * 1000.0 / p["plx"] <= MAX_AU and dp <= MAX_FRAC * p["plx"]
            and (dp <= CLOSE_FRAC * p["plx"] or dp <= N_SIGMA * math.hypot(p["eplx"], q["eplx"]))
            and dmu <= max(orbit, PM_FLOOR * mu))


def companions(stars):
    stars = sorted(stars, key=lambda s: s["u"][2])
    zs = [s["u"][2] for s in stars]
    lim = 2 * math.sin(N_ARCSEC / 206264.80624709636 / 2) * 1.000001
    parent = {}
    for i, q in enumerate(stars):
        best = None
        j = bisect.bisect_left(zs, zs[i] - lim)
        while j < len(stars) and zs[j] <= zs[i] + lim:
            p = stars[j]
            if j != i and key(p) < key(q):
                sep = 2 * math.asin(math.dist(p["u"], q["u"]) / 2) * 206264.80624709636
                if sep <= N_ARCSEC and same_system(p, q, sep) and (best is None or key(p) < key(best[0])):
                    best = (p, sep)
            j += 1
        if best:
            parent[q["id"]] = best
    out = {}
    for sid, (p, sep) in parent.items():
        r = p
        while r["id"] in parent:
            r = parent[r["id"]][0]
        out[sid] = {"parent": p["id"], "root": r["id"], "plx": r["plx"], "sep": sep}
    return out


def table():
    rows = {}
    for line in open(TABLE):
        if line.startswith("#") or line.startswith("id,"):
            continue
        f = line.rstrip("\n").split(",")
        rows[f[0]] = {"root": f[1], "plx": float(f[2]), "parent": f[4], "sep": float(f[5])}
    return rows


def main():
    c = cns5()
    py = companions(c + gcns({s["id"] for s in c}))
    ail = table()
    hip = lambda sid, r: sid.startswith("HIP ") or r["parent"].startswith("HIP ") or r["root"].startswith("HIP ")
    skipped = {sid for sid, r in ail.items() if hip(sid, r)}
    bad = []
    for sid, r in ail.items():
        if sid in skipped:
            continue
        o = py.get(sid)
        if o is None:
            bad.append(f"{sid}: in the table, not a companion here")
        elif (o["parent"], o["root"], o["plx"]) != (r["parent"], r["root"], r["plx"]) or abs(o["sep"] - r["sep"]) > 0.005:
            bad.append(f"{sid}: table {r} vs oracle {o}")
    for sid in py:
        if sid not in ail:
            bad.append(f"{sid}: a companion here, missing from the table")
    for pin, root in (("2947050466531873024", "CNS5:1676"), ("5140693571158946048", "5140693571158739840"),
                      ("3902874650601954816", "3902874650602495232")):
        if py.get(pin, {}).get("root") != root:
            bad.append(f"oracle: {pin} root {py.get(pin, {}).get('root')}, want {root}")
    print(f"check_companions: oracle {len(py)} companions over CNS5 + GCNS; table {len(ail)}, "
          f"{len(skipped)} involving bright (HIP) rows not compared; {len(bad)} disagreements")
    for b in bad[:20]:
        print("  " + b)
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
