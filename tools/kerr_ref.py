#!/usr/bin/env python3
"""Independent Decimal60 seed: RK-1/2, RK-4..8b, RK-10..13, RK-18, RK-Q1; u=r/(GM/c^2), package R=u/2 in r_s."""
import json
import sys
from decimal import Decimal, getcontext
from pathlib import Path

getcontext().prec = 60

UNIT = "radii GM/c^2 (package R=u/2 in r_s); clocks dimensionless; frequencies c^3/GM; speeds in c; RK-18 SI (km, ms, rad/s)"
SOURCE = "BPT72 ApJ178,347 §II; Bardeen 1970/1973; design_docs/planned/r2/kerr-black-holes.md V31, V34, V40"
GM_SUN = Decimal("1.3271244e20")  # IAU 2015 nominal GM_sun, m^3/s^2
C = Decimal(299792458)  # m/s, exact
PI = Decimal("3.14159265358979323846264338327950288419716939937510582097494459")
FRAME = "omega=2su/A, A=(u^2+s^2)^2-Delta s^2, Delta=u^2-2u+s^2; equator"
LAPSE = "N=sqrt(Delta Sigma/A), Sigma=u^2 on equator"
SPEED = "v=(Omega-omega)sqrt(g_pp)/N, prograde ISCO, Omega=1/(u^1.5+s); c"
STATIC_CLOCK = "sqrt(1-2u/Sigma), equator; requires u>=2 (static limit); s=0 form sqrt(1-1/R), R=u/2; no claim at u=0"
SI = "10 Msun, GM_sun=1.3271244e20 m^3/s^2 (IAU 2015 nominal), c=299792458 m/s"
Q1 = "RK-Q1 s=0 exact Schwarzschild member"
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

def equator(u, s):
    delta = u * u - 2 * u + s * s
    return delta, (u * u + s * s) ** 2 - delta * s * s

def frame_drag(u, spin):
    s = spin_value(spin)
    u = Decimal(u)
    return 2 * s * u / equator(u, s)[1]

def zamo_lapse(u, spin):
    s = spin_value(spin)
    u = Decimal(u)
    delta, area = equator(u, s)
    return (delta * u * u / area).sqrt()

def zamo_speed(spin):
    s = spin_value(spin)
    u = isco_radii(spin)[0]
    return (1 / (u ** Decimal("1.5") + s) - frame_drag(u, spin)) * (equator(u, s)[1].sqrt() / u) / zamo_lapse(u, spin)

def static_limit(spin, cos_theta=0):
    s = spin_value(spin)
    return 1 + (1 - (s * Decimal(cos_theta)) ** 2).sqrt()

def static_clock(u, spin):
    s = spin_value(spin)
    u = Decimal(u)
    if u < 2:
        raise ValueError("no static observer inside the static limit u=2")
    if s == 0:
        return (1 - 1 / (u / 2)).sqrt()
    return (1 - 2 * u / (u * u)).sqrt()

def horizon_omega(spin):
    s = spin_value(spin)
    return s / (2 * horizons(spin)[0])

def shadow_s0():
    u = photon_orbits("0")[0]
    return u * u.sqrt() / (u - 2).sqrt()

def si_rows(spin):
    gm = 10 * GM_SUN
    km = gm / C ** 2 / 1000
    u = isco_radii(spin)[0]
    return (("rs-km", 2 * km), ("static-limit-km", static_limit(spin) * km), ("horizon-km", horizons(spin)[0] * km),
            ("isco-pro-km", u * km), ("period-ms", 2 * PI * (u ** Decimal("1.5") + spin_value(spin)) * gm / C ** 3 * 1000),
            ("omega-h-rad-s", horizon_omega(spin) * C ** 3 / gm))

def value_row(rid, spin, quantity, value, formula):
    return {"id": rid, "spin": spin, "quantity": quantity, "precise": format(value, ".17g"),
            "display": format(value, ".6f"), "package_R": None, "formula": formula}

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
    records.append(value_row("RK-10", "0.9", "frame-drag-static-limit", frame_drag(2, "0.9"), FRAME))
    records.append(value_row("RK-11", "0.9", "lapse-static-limit", zamo_lapse(2, "0.9"), LAPSE))
    records.extend(value_row("RK-12", spin, "zamo-speed-isco-pro", zamo_speed(spin), SPEED) for spin in ("0.5", "0.9"))
    records.append(value_row("RK-13", "0.9", "static-clock-static-limit", static_clock(2, "0.9"), STATIC_CLOCK))
    records.extend(value_row("RK-18", "0.9", name, value, SI) for name, value in si_rows("0.9"))
    records.extend(radius_row("RK-Q1", "0", name, u, Q1) for name, u in (
        ("photon-pro", photon_orbits("0")[0]), ("photon-retro", photon_orbits("0")[1]),
        ("isco-pro", isco_radii("0")[0]), ("isco-retro", isco_radii("0")[1]), ("shadow", shadow_s0())))
    records.append(value_row("RK-Q1", "0", "frame-drag", frame_drag(3, "0"), FRAME))
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
