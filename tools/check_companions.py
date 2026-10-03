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

Cross-identifications (a CNS5 row without a Gaia id sitting within 2 arcsec of a GCNS source that is
not in CNS5, with the pair test's parallax and motion agreement) are the same star: the GCNS record
is dropped before pairing, as in the AILANG rule; the oracle finds them its own way and compares the
list with the table's "# same:" lines (HIP ones excepted).

Two more checks:
  * stars.json: every companion whose root is also a map row sits at the root's distance (1e-5 ly).
  * chance alignments, by the evaluator's method (companions round 1): a CRC32-selected half of all
    stars is rotated in RA by 0.7 and by 1.9 degrees; a pair whose members fall in different halves
    and pass the rule is a pure chance alignment. The count (x2 for the whole sky) is printed; more
    than 10 per sky fails.

Run by `make catalogue-verify` (needs data/raw). Exit 1 on any disagreement. With
`--precision CSV` it also writes the links where the root's parallax is less precise than the
companion's own (by over 3x) and differs from it by more than 5% (the design note's precision appendix).
"""
import bisect
import gzip
import json
import math
import sys
import zlib

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


def gcns(skip, g_only_ids=None):
    out = []
    with gzip.open(RAW + "table1c.dat.gz", "rt") as f:
        for line in f:
            ra, de, plx, e, pa, pd = (num(line, *c) for c in ((23, 36), (46, 59), (69, 77), (79, 85), (87, 95), (105, 113)))
            if None in (ra, de, plx, e, pa, pd) or plx <= 0:
                continue
            sid = line[2:21].strip()
            if sid in skip:
                continue
            if g_only_ids is not None:
                g_only_ids.add(sid)
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
    rows, same = {}, {}
    for line in open(TABLE):
        if line.startswith("# same: "):
            name, rest = line[8:].split(" = ")
            same[name] = rest.split(",")[0]
            continue
        if line.startswith("#") or line.startswith("id,"):
            continue
        f = line.rstrip("\n").split(",")
        rows[f[0]] = {"root": f[1], "plx": float(f[3]), "parent": f[5], "sep": float(f[6])}
    return rows, same


def sep_arcsec(p, q):
    return 2 * math.asin(math.dist(p["u"], q["u"]) / 2) * 206264.80624709636


def cross_ids(cns_stars, gcns_only):
    """CNS5 rows named CNS5:n (no Gaia id) -> the GCNS-only source they are."""
    by_dec = sorted(gcns_only, key=lambda s: s["u"][2])
    zs = [s["u"][2] for s in by_dec]
    lim = 2.0 / 206264.80624709636 * 1.000001
    out = {}
    for n in cns_stars:
        if not n["id"].startswith("CNS5:"):
            continue
        j = bisect.bisect_left(zs, n["u"][2] - lim)
        while j < len(by_dec) and zs[j] <= n["u"][2] + lim:
            g = by_dec[j]
            sep = sep_arcsec(n, g)
            if sep <= 2.0:
                p, q = (n, g) if key(n) < key(g) else (g, n)
                if same_system(p, q, sep):
                    out[n["id"]] = g["id"]
            j += 1
    return out


def chance(stars):
    """Pairs between two halves of the sky after rotating one half in RA (evaluator's method)."""
    total = []
    for deg in (0.7, 1.9):
        c, s_ = math.cos(math.radians(deg)), math.sin(math.radians(deg))
        moved = []
        for t in stars:
            if zlib.crc32(t["id"].encode()) & 1:
                x, y, z = t["u"]
                t = dict(t, u=(c * x - s_ * y, s_ * x + c * y, z), half=1)
            else:
                t = dict(t, half=0)
            moved.append(t)
        moved.sort(key=lambda t: t["u"][2])
        zs = [t["u"][2] for t in moved]
        lim = 2 * math.sin(N_ARCSEC / 206264.80624709636 / 2) * 1.000001
        n = 0
        for i, a in enumerate(moved):
            j = i + 1
            while j < len(moved) and zs[j] - zs[i] <= lim:
                b = moved[j]
                if a["half"] != b["half"]:
                    sep = sep_arcsec(a, b)
                    p, q = (a, b) if key(a) < key(b) else (b, a)
                    if sep <= N_ARCSEC and same_system(p, q, sep):
                        n += 1
                j += 1
        total.append(2 * n)
    return total


def write_precision(path, py, by):
    worse = big = 0
    rows = []
    for sid, o in sorted(py.items()):
        q, r = by[sid], by[o["root"]]
        if r["eplx"] > q["eplx"]:
            worse += 1
            if r["eplx"] > 3 * q["eplx"] and abs(q["plx"] - r["plx"]) > 0.05 * q["plx"]:
                big += 1
                rows.append(f"{sid},{o['root']},{q['plx']},{q['eplx']},{r['plx']},{r['eplx']},"
                            f"{1000 / q['plx'] * 3.261563777:.4f},{1000 / r['plx'] * 3.261563777:.4f}")
    with open(path, "w") as f:
        f.write(f"# companion rule precision appendix (tools/check_companions.py --precision): of {len(py)} CNS5/GCNS links,\n"
                f"# {worse} give the companion a less precise parallax than its own; in these {big} the root's error is over 3x the\n"
                f"# companion's and the move is over 5%.\n")
        f.write("id,root,own_plx,own_eplx,root_plx,root_eplx,own_dist_ly,root_dist_ly\n" + "\n".join(rows) + "\n")
    print(f"precision: {worse} of {len(py)} links less precise at the root; {big} over 3x and > 5% -> {path}")


def map_split():
    stars = json.load(open("data/starmap/stars.json"))["stars"]
    by = {s["id"].replace("Gaia DR3 ", ""): s for s in stars}
    ail, _ = table()
    bad = []
    for sid, r in ail.items():
        if sid in by and r["root"] in by and abs(by[sid]["dist_ly"] - by[r["root"]]["dist_ly"]) > 1e-5:
            bad.append(f"stars.json: {sid} at {by[sid]['dist_ly']} vs root {r['root']} at {by[r['root']]['dist_ly']}")
    return bad


def main():
    c = cns5()
    g_only = set()
    g = gcns({s["id"] for s in c}, g_only)
    same_py = cross_ids(c, g)
    g = [s for s in g if s["id"] not in set(same_py.values())]
    py = companions(c + g)
    ail, same_ail = table()
    if "--precision" in sys.argv:
        write_precision(sys.argv[sys.argv.index("--precision") + 1], py, {s["id"]: s for s in c + g})
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
    same_cns = {k: v for k, v in same_ail.items() if k.startswith("CNS5:")}
    if same_cns != same_py:
        bad.append(f"cross-identifications: table {sorted(same_cns.items())} vs oracle {sorted(same_py.items())}")
    bad += map_split()
    ch = chance(c + g)
    if max(ch) > 10:
        bad.append(f"chance alignments {ch} per sky exceed 10")
    print(f"check_companions: oracle {len(py)} companions over CNS5 + GCNS; table {len(ail)}, "
          f"{len(skipped)} involving bright (HIP) rows not compared; cross-identifications {len(same_py)} (CNS5) "
          f"agree; stars.json pairs together; chance alignments per sky at 0.7 / 1.9 deg: {ch[0]} / {ch[1]}; "
          f"{len(bad)} disagreements")
    for b in bad[:20]:
        print("  " + b)
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
