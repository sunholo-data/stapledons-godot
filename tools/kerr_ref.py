#!/usr/bin/env python3
"""Independent Decimal60 RK-1/2 and RK-4..8, RK-8b seed; u=r/(GM/c^2), package R=u/2 in r_s."""
import json
import sys
from decimal import Decimal, getcontext
from pathlib import Path

getcontext().prec = 60

UNIT = "radii GM/c^2 (package R=u/2 in r_s); clocks dimensionless dtau/dt"
SOURCE = "BPT72 ApJ178,347 §II; design_docs/planned/r2/kerr-black-holes.md V31, V40"
PHOTON = "u(u-3)^2=4spin^2; prograde root in (1,3), retrograde in (3,4)"
ISCO = "BPT72 ISCO Z1/Z2; prograde = smaller root, retrograde = larger"
CLOCK = "dtau/dt=sqrt(u^1.5-3sqrt(u)+2k spin)u^0.75/(u^1.5+k spin), k=+1 at prograde ISCO, -1 at retrograde ISCO"

def spin_value(spin):
    s = Decimal(spin)
    if not s.is_finite() or not 0 <= s < 1:
        raise ValueError("spin must be finite 0 <= spin < 1")
    return s

def horizons(spin):
    s = spin_value(spin)
    delta = (1 - s * s).sqrt()
    return 1 + delta, 1 - delta

def root(fn, a, b):
    a, b = Decimal(a), Decimal(b)
    fa = fn(a)
    for _ in range(230):
        m = (a + b) / 2
        if fn(m) * fa > 0:
            a = m
            fa = fn(a)
        else:
            b = m
    return (a + b) / 2

def photon_orbits(spin):
    s = spin_value(spin)
    def cubic(u):
        return u * (u - 3) ** 2 - 4 * s * s
    return root(cubic, 1, 3), root(cubic, 3, 4)

def isco_radii(spin):
    s = spin_value(spin)
    def cbrt(x):
        return (x.ln() / 3).exp()
    z1 = 1 + cbrt(1 - s * s) * (cbrt(1 + s) + cbrt(1 - s))
    z2 = (3 * s * s + z1 * z1).sqrt()
    d = ((3 - z1) * (3 + z1 + 2 * z2)).sqrt()
    return 3 + z2 - d, 3 + z2 + d

def orbit_clock(spin, k):
    s = spin_value(spin)
    u = isco_radii(spin)[0 if k == 1 else 1]
    numerator = (u ** Decimal("1.5") - 3 * u.sqrt() + 2 * k * s).sqrt() * u ** Decimal("0.75")
    return numerator / (u ** Decimal("1.5") + k * s)

def radius_row(rid, spin, quantity, u, formula):
    return {"id": rid, "spin": spin, "quantity": quantity, "precise": format(u, ".17g"),
            "display": format(u, ".6f"), "package_R": format(u / 2, ".17g"), "formula": formula}

def clock_row(rid, spin, quantity, value):
    return {"id": rid, "spin": spin, "quantity": quantity, "precise": format(value, ".17g"),
            "display": format(value, ".6f"), "package_R": None, "formula": CLOCK}

def fixture():
    records = []
    for spin in ("0", "0.5", "0.9", "0.998"):
        outer, inner = horizons(spin)
        for number, (quantity, u, sign) in enumerate((("outer", outer, "+"), ("inner", inner, "-")), 1):
            records.append({"id": f"RK-{number}", "spin": spin, "quantity": quantity,
                            "precise": format(u, ".17g"), "display": format(u, ".6f"),
                            "package_R": format(u / 2, ".17g"), "formula": f"u=1{sign}sqrt(1-spin^2)"})
    for rid, spin in (("RK-4", "0.9"), ("RK-5", "0.998")):
        pro, retro = photon_orbits(spin)
        records.append(radius_row(rid, spin, "photon-pro", pro, PHOTON))
        records.append(radius_row(rid, spin, "photon-retro", retro, PHOTON))
    for rid, spin in (("RK-6", "0.5"), ("RK-7", "0.9")):
        pro, retro = isco_radii(spin)
        records.append(radius_row(rid, spin, "isco-pro", pro, ISCO))
        records.append(radius_row(rid, spin, "isco-retro", retro, ISCO))
    records.append(clock_row("RK-8", "0.9", "clock-pro", orbit_clock("0.9", 1)))
    records.append(clock_row("RK-8", "0.9", "clock-retro", orbit_clock("0.9", -1)))
    records.append(clock_row("RK-8b", "0.998", "clock-pro", orbit_clock("0.998", 1)))
    return {"schema": "kerr-rk-seed-v1", "unit": UNIT, "source": SOURCE, "records": records}

def unique_keys(pairs):
    result = dict(pairs)
    if len(result) != len(pairs):
        raise ValueError("duplicate JSON key")
    return result

def main():
    expected = fixture()
    if len(sys.argv) == 1:
        print("{")
        for key, value in expected.items():
            if key != "records":
                print(f"  {json.dumps(key)}: {json.dumps(value)},")
        print('  "records": [')
        print(",\n".join("    " + json.dumps(row) for row in expected["records"]))
        print("  ]\n}")
    elif len(sys.argv) == 3 and sys.argv[1] in ("--check", "check"):
        actual = json.loads(Path(sys.argv[2]).read_text(), object_pairs_hook=unique_keys)
        if actual != expected:
            raise ValueError("fixture schema/metadata/records mismatch")
    else:
        raise ValueError("usage: kerr_ref.py [--check|check <path>]")

if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError) as error:
        print(f"kerr-oracle: {error}", file=sys.stderr)
        sys.exit(1)
