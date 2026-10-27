#!/usr/bin/env python3
"""Independent Kerr closed-form oracle for R2-KERR K1.1a-a.

ROLE: oracle. Listed in tools/python-allowlist.txt with role `oracle`: a
second-language reference that catches bugs the AILANG VM and interpreter would
share. It is never a pipeline step and never runs at runtime. Standard library
only (json, os, sys, decimal); it opens no socket and spawns no process.

PROVENANCE: design_docs/planned/r2/kerr-black-holes.md -- the "Design" RK table
(the 17-significant-digit fixtures), Verification log V31 (DI-01 precise RK
closed forms and SI conversions), V40 (RK-8b), and the "Scratch oracle source
(reproducible)" listing in that document, which this file replaces as the
tracked, reviewed provenance. The formulas below are re-expressed here, not
imported from sunholo/relativity and not read out of the document: the photon
orbits are the real roots of a cubic found by bisection rather than the
package's arccos form, the cube roots are Newton iterates rather than
ln/exp, every square root goes through one guarded helper, and each derived
root carries a residual self-check. The document's numbers are therefore
independent evidence about this file, and this file about them.

PRECISION: CPython Decimal with context precision 60 for every value in this
slice. All rows here are Decimal60 and printed to 17 significant digits; the
members the design pins exactly (s = 0 in RK-Q1, the RK-3 identity, RK-13 at
the static limit) are printed as the exact integers they are. There are no
binary64 rows in K1.1a-a: V34's binary64 operation-order probes are a package
evaluation-order question, not an oracle value.

DISPLAY ROUNDING IS SEPARATE. `display6` is a six-decimal rendering for spec
text and HUD prose ("The spec may round its display values; tests of such text
use half a unit in its last printed place, separately from physics
assertions"). It is computed by its own function from the precise value and is
never a physics assertion, and a display string must never be reused as a
pinned value -- `check` fails loudly if one is.

REGENERATE THE FIXTURE (writes tests/fixtures/kerr/rk.json):

    python3 -I tools/kerr_ref.py fixture

VERIFY IT (exit 0 only if every value re-derives):

    python3 -I tools/kerr_ref.py check

The other commands are the test's eyes: `closed` prints the V31 precise rows,
`display` the six-decimal display strings, `exact` the members pinned exactly,
and `probe <s> [u]` evaluates at a spin and radius, refusing invalid domains
before any square root. tools/test_kerr_oracle.sh pins all of it.
"""
import json
import os
import sys
from decimal import Decimal as D, InvalidOperation, getcontext

PRECISION = 60
getcontext().prec = PRECISION

DIGITS = 17                      # pinned precise rendering, as the design's 17
DISPLAY = 6                      # display rendering only; never a physics assertion

SCHEMA = "kerr-rk-fixtures/1"
SOURCE = "design_docs/planned/r2/kerr-black-holes.md (Design RK table; V31, V40)"
C_SI = D("299792458")
GM_SUN_NOMINAL = D("1.3271244e20")      # IAU 2015 nominal, m^3/s^2
PI = D("3.14159265358979323846264338327950288419716939937510582097494459")

HERE = os.path.dirname(os.path.abspath(__file__))
FIXTURE = os.path.join(os.path.dirname(HERE), "tests", "fixtures", "kerr", "rk.json")

EXIT_OK, EXIT_CHECK, EXIT_REFUSED, EXIT_USAGE = 0, 1, 2, 3

# Citations, one per formula family; each record carries the one that applies.
CITE_HORIZON = "BPT72 section II (Bardeen, Press & Teukolsky 1972, ApJ 178, 347)"
CITE_STATIC_LIMIT = "Chandrasekhar 1983, The Mathematical Theory of Black Holes, section 54"
CITE_PHOTON = "BPT72 section II; Bardeen 1973 Table II; solved here as the real roots of u(u-3)^2 - 4 s^2 = 0"
CITE_ISCO = "BPT72 eq. 2.21 (Z1, Z2 form); Misner, Thorne & Wheeler 1973 section 25.6 for the a = 0 member"
CITE_ORBIT = "BPT72 section II (circular equatorial orbits)"
CITE_ZAMO = "Bardeen 1970, ApJ 162, 71 (locally non-rotating frame); BPT72 section III eqs. 3.1-3.3"
CITE_LAPSE = "Bardeen 1973 (3+1 lapse N = sqrt(Delta Sigma / A))"
CITE_HORIZON_OMEGA = "BPT72 section II (Omega_H = s / (2 u_+))"
CITE_CLOCK = "BPT72 eqs. 2.1, 2.7 (static clock); evaluated in the package's order at s = 0 (V34)"
CITE_SI = "IAU 2015 nominal GM_sun = 1.3271244e20 m^3/s^2 and c = 299792458 m/s"

FORM_HORIZON_OUT = "u_+ = 1 + sqrt(1 - s^2)"
FORM_HORIZON_IN = "u_- = 1 - sqrt(1 - s^2)"
FORM_STATIC_LIMIT = ("staticLimitR = (1 + sqrt(1 - s^2 cos^2 theta))/2 r_s, i.e. "
                     "u_sl = 1 + sqrt(1 - s^2 cos^2 theta); on the equator cos(theta) = 0, "
                     "so u_sl = 2 for every s")
FORM_PHOTON_PRO = ("u_ph = 2{1 + cos[(2/3) arccos(-s)]} (prograde); this oracle solves "
                   "u(u-3)^2 - 4 s^2 = 0 on [1, 3] by bisection instead")
FORM_PHOTON_RET = ("u_ph = 2{1 + cos[(2/3) arccos(+s)]} (retrograde); this oracle solves "
                   "u(u-3)^2 - 4 s^2 = 0 on [3, 4] by bisection instead")
FORM_ISCO = ("Z1 = 1 + (1 - s^2)^(1/3)[(1+s)^(1/3) + (1-s)^(1/3)], Z2 = sqrt(3 s^2 + Z1^2), "
             "u_ISCO = 3 + Z2 -/+ sqrt((3 - Z1)(3 + Z1 + 2 Z2))")
FORM_CLOCK = ("d tau/dt = u^(3/4) sqrt(u^(3/2) - 3 sqrt(u) + 2 k s) / (u^(3/2) + k s), "
              "k = +1 prograde, -1 retrograde")
FORM_HORIZON_OMEGA = "Omega_H = s / (2 u_+)"
FORM_FRAME_DRAG = ("omega = 2 s u / A, A = (u^2 + s^2)^2 - Delta s^2 sin^2 theta, "
                   "Delta = u^2 - 2u + s^2")
FORM_LAPSE = "N = sqrt(Delta Sigma / A), Sigma = u^2 + s^2 cos^2 theta"
FORM_ZAMO_SPEED = ("v_Z = (Omega - omega) h / N, h = sqrt(A/Sigma) sin(theta), "
                   "Omega = k/(u^(3/2) + k s)")
FORM_STATIC_CLOCK = ("staticClockRateKerr = sqrt(1 - 2u/Sigma); at s = 0 dispatch to the "
                     "package's staticClockRate(u/2) = sqrt(1 - 1/(u/2))")
FORM_RS = "r_s = 2 G M / c^2"
FORM_RS_STATIC_LIMIT = "equatorial static limit = r_s = 2 G M / c^2"
FORM_RS_HORIZON = "r_+ = r_s (1 + sqrt(1 - s^2))/2"
FORM_RS_ISCO = "r_ISCO = r_s u_ISCO / 2"
FORM_RS_PERIOD = "T = 2 pi (u_ISCO^(3/2) + s) GM / c^3"
FORM_RS_OMEGA = "Omega_H = s / (2 u_+) c^3 / (GM)"


class Refused(Exception):
    """A domain refusal: invalid input, detected before any arithmetic."""


def _refuse(message):
    raise Refused(message)


# --------------------------------------------------------------------- guarded input
# Every public formula below validates its spin, radius and angle through these
# helpers as its first statement, so an invalid input can never reach a square
# root; `_sqrt` refuses a non-finite or negative argument rather than returning a
# NaN that would flow silently into a printed value.

def _text(value):
    return value if isinstance(value, str) else str(value)


def _number(value, what):
    text = _text(value)
    try:
        v = D(text)
    except (InvalidOperation, ValueError, ArithmeticError, TypeError):
        _refuse("%s%s is not a decimal number" % (what, text))
    if not v.is_finite():
        _refuse("%s%s is not a finite number" % (what, text))
    return v


def spin(value):
    """The dimensionless spin s in [0, 1); validated before anything is computed."""
    s = _number(value, "spin s=")
    if s < 0:
        _refuse("spin s=%s is negative (the domain is 0 <= s < 1)" % _text(value))
    if s >= 1:
        _refuse("spin s=%s is not below 1 (s = 1 is the extremal hole; the domain is "
                "0 <= s < 1)" % _text(value))
    return s


def radius(value):
    """A Boyer-Lindquist radius u = r/(GM/c^2) in the oracle's own units."""
    u = _number(value, "radius u=")
    if u <= 0:
        _refuse("radius u=%s is not positive (u = r/(GM/c^2) and u = 0 is the ring "
                "singularity)" % _text(value))
    return u


def cos_squared(value):
    """cos^2(theta), so that sin^2(theta) = 1 - cos^2(theta) stays non-negative."""
    c2 = _number(value, "cos^2 theta=")
    if c2 < 0 or c2 > 1:
        _refuse("cos^2 theta=%s is outside [0, 1]" % _text(value))
    return c2


def _sqrt(x, what="argument"):
    if not x.is_finite():
        _refuse("square root of a non-finite %s (%s)" % (what, x))
    if x < 0:
        _refuse("square root of a negative %s (%s): the input is outside the domain "
                "where this quantity is real" % (what, x))
    return x.sqrt()


def _cbrt(x, what="argument"):
    """Cube root by Newton's method: independent of Decimal's ln/exp route."""
    if not x.is_finite():
        _refuse("cube root of a non-finite %s (%s)" % (what, x))
    if x < 0:
        _refuse("cube root of a negative %s (%s)" % (what, x))
    if x == 0:
        return D(0)
    y = D(1)
    for _ in range(400):
        next_y = (2 * y + x / (y * y)) / 3
        if next_y == y:
            break
        y = next_y
    return y


def _bisect(f, lo, hi, what):
    """A bracketed root of a continuous, single-rooted f on [lo, hi], by bisection."""
    a, b = D(lo), D(hi)
    fa = f(a)
    for _ in range(400):
        m = (a + b) / 2
        if m == a or m == b:
            break
        fm = f(m)
        if fm * fa > 0:
            a, fa = m, fm
        else:
            b = m
    root = (a + b) / 2
    scale = max(abs(root), D(1))
    if abs(f(root)) > scale * D(10) ** (-(PRECISION - 10)):
        _refuse("the %s root at u=%s failed its residual self-check" % (what, root))
    return root


# ------------------------------------------------------------------------- formulas

def horizon_u(s_value):
    """Outer horizon u_+ = 1 + sqrt(1 - s^2) in GM/c^2 (BPT72 II; RK-1)."""
    s = spin(s_value)
    return 1 + _sqrt((1 - s) * (1 + s), "horizon discriminant 1 - s^2")


def horizon_inner_u(s_value):
    """Inner horizon u_- = 1 - sqrt(1 - s^2) in GM/c^2 (BPT72 II; RK-2)."""
    s = spin(s_value)
    return 1 - _sqrt((1 - s) * (1 + s), "horizon discriminant 1 - s^2")


def static_limit_u(s_value, cos2_value=D(0)):
    """Ergosphere boundary in u units: 1 + sqrt(1 - s^2 cos^2 theta). On the equator
    cos(theta) = 0, so this is exactly 2 for every s (RK-3)."""
    s = spin(s_value)
    c2 = cos_squared(cos2_value)
    return 1 + _sqrt(1 - s * s * c2, "static-limit discriminant 1 - s^2 cos^2 theta")


def photon_orbits_u(s_value):
    """Equatorial photon orbits (prograde, retrograde) in GM/c^2 (RK-4/5).

    The design writes u_ph = 2{1 + cos[(2/3) arccos(-/+s)]}. The same roots are the
    real roots of u(u - 3)^2 = 4 s^2, which this oracle brackets on [1, 3] and
    [3, 4]; no arccos implementation is shared with the package. s = 0 is the
    degenerate double root 3 (1.5 r_s, RS-21) and is returned exactly.
    """
    s = spin(s_value)
    if s == 0:
        return D(3), D(3)

    def residual(u):
        return u * (u - 3) * (u - 3) - 4 * s * s

    return _bisect(residual, 1, 3, "prograde photon-orbit"), _bisect(residual, 3, 4, "retrograde photon-orbit")


def isco_u(s_value):
    """ISCO (prograde, retrograde) in GM/c^2 from the Z1/Z2 form (BPT72 eq. 2.21; RK-6/7).

    At s = 0 both members are exactly 6 GM/c^2 = 3 r_s, the package's isco().
    """
    s = spin(s_value)
    if s == 0:
        return D(6), D(6)
    q = 1 - s
    z1 = 1 + _cbrt(q * (1 + s), "ISCO (1 - s^2)^(1/3)") * (
        _cbrt(1 + s, "ISCO (1+s)^(1/3)") + _cbrt(q, "ISCO (1-s)^(1/3)"))
    z2 = _sqrt(3 * s * s + z1 * z1, "ISCO Z2")
    disc = (3 - z1) * (3 + z1 + 2 * z2)
    if disc < 0:
        _refuse("the ISCO discriminant (3 - Z1)(3 + Z1 + 2 Z2) is negative (%s)" % disc)
    d = _sqrt(disc, "ISCO discriminant")
    return 3 + z2 - d, 3 + z2 + d


def _metric(u_value, s_value, cos2_value):
    """Delta, Sigma, A, lapse N, frame dragging omega and h = sqrt(g_phi phi)."""
    u = radius(u_value)
    s = spin(s_value)
    c2 = cos_squared(cos2_value)
    sin2 = 1 - c2
    sigma = u * u + s * s * c2
    delta = u * u - 2 * u + s * s
    if delta < 0:
        _refuse("u=%s is between the horizons (Delta(u) = %s < 0): there is no ZAMO "
                "frame and no static observer there" % (u, delta))
    a_metric = (u * u + s * s) ** 2 - delta * s * s * sin2
    if sigma <= 0 or a_metric <= 0:
        _refuse("the metric at u=%s, s=%s has Sigma=%s, A=%s, so the frame is degenerate"
                % (u, s, sigma, a_metric))
    lapse = _sqrt(delta * sigma / a_metric, "ZAMO lapse N = sqrt(Delta Sigma / A)")
    omega = 2 * s * u / a_metric
    h = _sqrt(a_metric / sigma, "sqrt(g_phi phi)") * _sqrt(sin2, "sin(theta)")
    return delta, sigma, a_metric, lapse, omega, h


def frame_drag_omega(u_value, s_value, cos2_value=D(0)):
    """omega = -g_t phi / g_phi phi, in c^3/GM (Bardeen 1970; RK-10)."""
    return _metric(u_value, s_value, cos2_value)[4]


def zamo_lapse(u_value, s_value, cos2_value=D(0)):
    """The ZAMO lapse N = sqrt(Delta Sigma / A) (Bardeen 1973; RK-11)."""
    return _metric(u_value, s_value, cos2_value)[3]


def horizon_omega(s_value):
    """Horizon angular velocity Omega_H = s/(2 u_+) in c^3/GM (BPT72 II; RK-9)."""
    s = spin(s_value)
    if s == 0:
        return D(0)
    return s / (2 * horizon_u(s))


def orbit_omega(u_value, s_value, k):
    """Circular equatorial orbit angular velocity Omega = k/(u^(3/2) + k s), c^3/GM."""
    u = radius(u_value)
    s = spin(s_value)
    if k not in (1, -1):
        _refuse("orbit sense k=%r must be +1 (prograde) or -1 (retrograde)" % (k,))
    return D(k) / (u * _sqrt(u, "u") + D(k) * s)


def orbit_clock(u_value, s_value, k):
    """Circular equatorial orbit clock d tau/dt (BPT72 II; RK-8, RK-8b)."""
    u = radius(u_value)
    s = spin(s_value)
    if k not in (1, -1):
        _refuse("orbit sense k=%r must be +1 (prograde) or -1 (retrograde)" % (k,))
    root_u = _sqrt(u, "u")
    u32 = u * root_u
    inner = u32 - 3 * root_u + 2 * D(k) * s
    if inner < 0:
        _refuse("the circular orbit at u=%s, s=%s is not timelike (its clock is "
                "imaginary): %s < 0" % (u, s, inner))
    return _sqrt(inner, "orbit clock radicand") * _sqrt(u32, "u^(3/2)") / (u32 + D(k) * s)


def orbit_zamo_speed(u_value, s_value, k):
    """Signed ZAMO local speed of a circular orbit, v_Z = (Omega - omega) h / N (RK-12)."""
    u = radius(u_value)
    _, _, _, lapse, omega, h = _metric(u, s_value, 0)
    return (orbit_omega(u, s_value, k) - omega) * h / lapse


def static_clock(u_value, s_value, cos2_value=D(0)):
    """Static observer's d tau/dt. sqrt(1 - 2u/Sigma) for s > 0; at s = 0 the design
    dispatches to the package's staticClockRate(u/2), whose order is sqrt(1 - 1/(u/2))
    (RK-13, V34). On the equator the two agree exactly at the static limit."""
    u = radius(u_value)
    s = spin(s_value)
    c2 = cos_squared(cos2_value)
    if s == 0:
        return _sqrt(1 - 1 / (u / 2), "static clock radicand 1 - 1/(u/2)")
    sigma = u * u + s * s * c2
    return _sqrt(1 - 2 * u / sigma, "static clock radicand 1 - 2u/Sigma")


def si_rows(s_value, mass_msun):
    """RK-18: the 10 M_sun, s = 0.9 conversions (IAU 2015 nominal GM_sun)."""
    s = spin(s_value)
    m = _number(mass_msun, "mass (M_sun)=")
    if m <= 0:
        _refuse("mass %s M_sun is not positive" % _text(mass_msun))
    gm = m * GM_SUN_NOMINAL
    c2 = C_SI * C_SI
    c3 = c2 * C_SI
    r_s = 2 * gm / c2                                  # metres
    hi = horizon_u(s)
    pro = isco_u(s)[0]
    km = D(1000)
    return {
        "rsKm": r_s / km,
        "staticLimitKm": r_s * static_limit_u(s) / 2 / km,
        "horizonKm": r_s * hi / 2 / km,
        "iscoProgradeKm": r_s * pro / 2 / km,
        "iscoProgradePeriodMs": 2 * PI * (pro * _sqrt(pro, "u_ISCO") + s) * gm / c3 * km,
        "horizonOmegaRadPerSec": horizon_omega(s) * c3 / gm,
    }


# ------------------------------------------------------------------- renderings
# Three renderings of one precise value, kept apart on purpose. `precise` is the
# 17-significant-digit pin the design's fixtures use; `exact` is the bare integer
# for the members that are exact; `display6` is spec-text rounding and is never
# asserted as physics.

def precise(x):
    return format(x, "." + str(DIGITS) + "g")


def exact(x):
    """The bare rendering for a member the design pins exactly: no exponent noise.

    staticLimitU on the equator is exactly 2 for every s, but Decimal keeps the scale
    of the products that produced it (2.000 at s = 0.998), so an exact member is
    rendered through to_integral_value() rather than str().
    """
    if x == x.to_integral_value():
        return str(x.to_integral_value())
    return str(x.normalize())


def display6(x):
    return format(x, "." + str(DISPLAY) + "f")


def render(value, rendering):
    return exact(value) if rendering == "exact" else precise(value)


# ------------------------------------------------------------------ RK-18 rows

RK18_QUANTITIES = (
    ("rsKm", "r_s", "km", FORM_RS),
    ("staticLimitKm", "r_sl", "km", FORM_RS_STATIC_LIMIT),
    ("horizonKm", "r_+", "km", FORM_RS_HORIZON),
    ("iscoProgradeKm", "r_ISCO", "km", FORM_RS_ISCO),
    ("iscoProgradePeriodMs", "T_ISCO", "ms", FORM_RS_PERIOD),
    ("horizonOmegaRadPerSec", "Omega_H", "rad/s", FORM_RS_OMEGA),
)


def _record(rid, s_text, quantity, symbol, unit, formula, source, value, rendering="17g"):
    return {
        "id": rid,
        "spin": s_text,
        "quantity": quantity,
        "symbol": symbol,
        "unit": unit,
        "formula": formula,
        "source": source,
        "rendering": rendering,
        "value": render(value, rendering),
        "display6": display6(value),
    }


def derive():
    """Every RK record this slice pins, re-derived from the formulas above."""
    rows = []
    spins = ((D("0.5"), "0.5"), (D("0.9"), "0.9"), (D("0.998"), "0.998"))

    for s, text in spins:                                   # RK-1
        rows.append(_record("RK-1", text, "outerHorizonU", "u_+", "GM/c^2",
                            FORM_HORIZON_OUT, CITE_HORIZON, horizon_u(s)))
    for s, text in spins:                                   # RK-2
        rows.append(_record("RK-2", text, "innerHorizonU", "u_-", "GM/c^2",
                            FORM_HORIZON_IN, CITE_HORIZON, horizon_inner_u(s)))
    for s, text in ((D("0"), "0"), (D("0.9"), "0.9"), (D("0.998"), "0.998")):   # RK-3
        rows.append(_record("RK-3", text, "staticLimitU", "u_sl", "GM/c^2",
                            FORM_STATIC_LIMIT, CITE_STATIC_LIMIT,
                            static_limit_u(s), "exact"))

    for rid, s, text in (("RK-4", D("0.9"), "0.9"), ("RK-5", D("0.998"), "0.998")):
        pro, ret = photon_orbits_u(s)
        rows.append(_record(rid, text, "photonProgradeU", "u_ph,pro", "GM/c^2",
                            FORM_PHOTON_PRO, CITE_PHOTON, pro))
        rows.append(_record(rid, text, "photonRetrogradeU", "u_ph,ret", "GM/c^2",
                            FORM_PHOTON_RET, CITE_PHOTON, ret))

    for rid, s, text in (("RK-6", D("0.5"), "0.5"), ("RK-7", D("0.9"), "0.9")):
        pro, ret = isco_u(s)
        rows.append(_record(rid, text, "iscoProgradeU", "u_ISCO,pro", "GM/c^2",
                            FORM_ISCO, CITE_ISCO, pro))
        rows.append(_record(rid, text, "iscoRetrogradeU", "u_ISCO,ret", "GM/c^2",
                            FORM_ISCO, CITE_ISCO, ret))

    s09 = D("0.9")                                          # RK-8
    rows.append(_record("RK-8", "0.9", "iscoProgradeClock", "d tau/dt", "dimensionless",
                        FORM_CLOCK, CITE_ORBIT, orbit_clock(isco_u(s09)[0], s09, 1)))
    rows.append(_record("RK-8", "0.9", "iscoRetrogradeClock", "d tau/dt", "dimensionless",
                        FORM_CLOCK, CITE_ORBIT, orbit_clock(isco_u(s09)[1], s09, -1)))
    s998 = D("0.998")                                       # RK-8b
    rows.append(_record("RK-8b", "0.998", "iscoProgradeClock", "d tau/dt", "dimensionless",
                        FORM_CLOCK, CITE_ORBIT, orbit_clock(isco_u(s998)[0], s998, 1)))

    rows.append(_record("RK-9", "0.9", "horizonOmega", "Omega_H", "c^3/GM",
                        FORM_HORIZON_OMEGA, CITE_HORIZON_OMEGA, horizon_omega(s09)))
    rows.append(_record("RK-10", "0.9", "staticLimitFrameDragOmega", "omega", "c^3/GM",
                        FORM_FRAME_DRAG, CITE_ZAMO, frame_drag_omega(D(2), s09)))
    rows.append(_record("RK-11", "0.9", "staticLimitZamoLapse", "N", "dimensionless",
                        FORM_LAPSE, CITE_LAPSE, zamo_lapse(D(2), s09)))

    for s, text in ((D("0.9"), "0.9"), (D("0.5"), "0.5")):   # RK-12
        rows.append(_record("RK-12", text, "iscoProgradeZamoSpeed", "v_Z", "c",
                            FORM_ZAMO_SPEED, CITE_ORBIT,
                            orbit_zamo_speed(isco_u(s)[0], s, 1)))

    for s, text in ((D("0.9"), "0.9"), (D("0"), "0")):       # RK-13
        rows.append(_record("RK-13", text, "staticClockAtStaticLimit", "d tau/dt",
                            "dimensionless", FORM_STATIC_CLOCK, CITE_CLOCK,
                            static_clock(D(2), s), "exact"))

    si = si_rows(s09, D(10))                                # RK-18
    for quantity, symbol, unit, formula in RK18_QUANTITIES:
        rows.append(_record("RK-18", "0.9", quantity, symbol, unit, formula, CITE_SI,
                            si[quantity]))

    zero = D("0")                                           # RK-Q1, the s = 0 members
    rows.append(_record("RK-Q1", "0", "outerHorizonU", "u_+", "GM/c^2",
                        FORM_HORIZON_OUT, CITE_HORIZON, horizon_u(zero), "exact"))
    rows.append(_record("RK-Q1", "0", "innerHorizonU", "u_-", "GM/c^2",
                        FORM_HORIZON_IN, CITE_HORIZON, horizon_inner_u(zero), "exact"))
    rows.append(_record("RK-Q1", "0", "staticLimitU", "u_sl", "GM/c^2",
                        FORM_STATIC_LIMIT, CITE_STATIC_LIMIT,
                        static_limit_u(zero), "exact"))
    rows.append(_record("RK-Q1", "0", "photonProgradeU", "u_ph", "GM/c^2",
                        FORM_PHOTON_PRO, CITE_PHOTON, photon_orbits_u(zero)[0], "exact"))
    rows.append(_record("RK-Q1", "0", "iscoProgradeU", "u_ISCO", "GM/c^2",
                        FORM_ISCO, CITE_ISCO, isco_u(zero)[0], "exact"))
    rows.append(_record("RK-Q1", "0", "horizonOmega", "Omega_H", "c^3/GM",
                        FORM_HORIZON_OMEGA, CITE_HORIZON_OMEGA, horizon_omega(zero), "exact"))
    return rows


# ------------------------------------------------------------------- commands

def cmd_closed():
    """The V31 rows, precise, in V31's shapes."""
    s05, s09, s998 = D("0.5"), D("0.9"), D("0.998")
    for text, s in (("0.5", s05), ("0.9", s09), ("0.998", s998)):
        print("RK-1/2 %s %s %s" % (text, precise(horizon_u(s)), precise(horizon_inner_u(s))))
    for text, s in (("0.9", s09), ("0.998", s998)):
        pro, ret = photon_orbits_u(s)
        print("RK-4/5 %s %s %s" % (text, precise(pro), precise(ret)))
    for text, s in (("0.5", s05), ("0.9", s09)):
        pro, ret = isco_u(s)
        print("RK-6/7 %s %s %s" % (text, precise(pro), precise(ret)))
    print("RK-8 %s %s" % (precise(orbit_clock(isco_u(s09)[0], s09, 1)),
                          precise(orbit_clock(isco_u(s09)[1], s09, -1))))
    print("RK-8b %s" % precise(orbit_clock(isco_u(s998)[0], s998, 1)))
    print("RK-9 %s" % precise(horizon_omega(s09)))
    print("RK-10/11 %s %s" % (precise(frame_drag_omega(D(2), s09)),
                              precise(zamo_lapse(D(2), s09))))
    print("RK-12 %s %s" % (precise(orbit_zamo_speed(isco_u(s09)[0], s09, 1)),
                           precise(orbit_zamo_speed(isco_u(D("0.5"))[0], D("0.5"), 1))))
    si = si_rows(s09, D(10))
    print("RK-18 " + " ".join(precise(si[q]) for q, _, _, _ in RK18_QUANTITIES))
    return EXIT_OK


def cmd_display():
    for rec in derive():
        print("%s %s %s %s" % (rec["id"], rec["spin"], rec["quantity"], rec["display6"]))
    return EXIT_OK


def cmd_exact():
    for rec in derive():
        if rec["rendering"] == "exact":
            print("%s %s %s %s" % (rec["id"], rec["spin"], rec["quantity"], rec["value"]))
    return EXIT_OK


def payload():
    records = derive()
    return {
        "schema": SCHEMA,
        "oracle": "tools/kerr_ref.py",
        "role": "oracle",
        "source": SOURCE,
        "provenance": ("CPython Decimal, context precision %d; values printed to %d "
                       "significant digits, or as exact integers where the design pins an "
                       "exact member. display6 is a six-decimal DISPLAY rendering, never a "
                       "physics assertion." % (PRECISION, DIGITS)),
        "units": ("radii in GM/c^2 unless the record says km; angular velocities in c^3/GM; "
                  "speeds in c; clocks dimensionless"),
        "generated_by": "python3 -I tools/kerr_ref.py fixture",
        "check_with": "python3 -I tools/kerr_ref.py check",
        "records": records,
    }


def cmd_fixture(path):
    data = payload()
    parent = os.path.dirname(os.path.abspath(path))
    if parent:
        os.makedirs(parent, exist_ok=True)
    with open(path, "w") as handle:
        json.dump(data, handle, indent=2)
        handle.write("\n")
    print("kerr_ref: wrote %s (%d records, Decimal precision %d)"
          % (path, len(data["records"]), PRECISION))
    return EXIT_OK


def cmd_check(path):
    try:
        with open(path) as handle:
            data = json.load(handle)
    except FileNotFoundError:
        print("kerr_ref: FAIL  no fixture at %s (generate it: python3 -I tools/kerr_ref.py "
              "fixture); a missing check is a failure, never a pass" % path)
        return EXIT_CHECK
    except ValueError as exc:
        print("kerr_ref: FAIL  %s is not valid JSON: %s" % (path, exc))
        return EXIT_CHECK
    if not isinstance(data, dict):
        print("kerr_ref: FAIL  %s is not a JSON object" % path)
        return EXIT_CHECK
    records = data.get("records")
    if not isinstance(records, list) or not records:
        print("kerr_ref: FAIL  %s holds no records; an empty or zero-record check is a "
              "failure, never a pass" % path)
        return EXIT_CHECK
    if data.get("schema") != SCHEMA:
        print("kerr_ref: FAIL  %s has schema %r, expected %r"
              % (path, data.get("schema"), SCHEMA))
        return EXIT_CHECK

    fails = 0
    for name in ("oracle", "role", "source", "provenance", "generated_by", "check_with"):
        if not str(data.get(name, "")).strip():
            print("kerr_ref: FAIL  the fixture header is missing %s" % name)
            fails += 1

    expected = {(rec["id"], rec["spin"], rec["quantity"]): rec for rec in derive()}
    seen = set()
    for stored in records:
        if not isinstance(stored, dict):
            print("kerr_ref: FAIL  a record is not a JSON object: %r" % (stored,))
            fails += 1
            continue
        key = (stored.get("id"), stored.get("spin"), stored.get("quantity"))
        name = " ".join(str(part) for part in key)
        if key in seen:
            print("kerr_ref: FAIL  %s appears more than once" % name)
            fails += 1
        seen.add(key)
        for field in ("symbol", "unit", "formula", "source", "value", "display6"):
            if not str(stored.get(field, "")).strip():
                print("kerr_ref: FAIL  %s carries no %s metadata" % (name, field))
                fails += 1
        want = expected.get(key)
        if want is None:
            print("kerr_ref: FAIL  %s is not a record this oracle derives" % name)
            fails += 1
            continue
        if stored.get("value") != want["value"]:
            print("kerr_ref: FAIL  %s says value %r; this oracle re-derives %r"
                  % (name, stored.get("value"), want["value"]))
            fails += 1
        elif stored.get("display6") != want["display6"]:
            print("kerr_ref: FAIL  %s says display6 %r; this oracle re-derives %r"
                  % (name, stored.get("display6"), want["display6"]))
            fails += 1
        elif stored.get("rendering") != want["rendering"]:
            print("kerr_ref: FAIL  %s says rendering %r; this oracle re-derives %r"
                  % (name, stored.get("rendering"), want["rendering"]))
            fails += 1
    for key in expected:
        if key not in seen:
            print("kerr_ref: FAIL  %s is missing from the fixture"
                  % " ".join(str(part) for part in key))
            fails += 1

    if fails:
        print("kerr_ref: FAIL  %d failure(s) against %s; regenerate with: python3 -I "
              "tools/kerr_ref.py fixture" % (fails, path))
        return EXIT_CHECK
    print("kerr_ref: ok  %d fixture records re-derived from this oracle at Decimal "
          "precision %d; every value and six-decimal display string matches %s"
          % (len(records), PRECISION, path))
    return EXIT_OK


def cmd_probe(args):
    """Evaluate at a spin (and optionally a radius), refusing invalid domains.

    Every input is validated and every value computed before anything is printed, so
    a refusal never leaves a half-printed result behind that a reader could mistake
    for an accepted input.
    """
    if not args:
        print("usage: kerr_ref.py probe <spin> [<radius u = r/(GM/c^2)>]", file=sys.stderr)
        return EXIT_USAGE
    s_text = args[0]
    u_text = args[1] if len(args) > 1 else None
    spin(s_text)
    if u_text is not None:
        radius(u_text)
    lines = ["probe s=%s u_plus=%s" % (_text(s_text), precise(horizon_u(s_text)))]
    if u_text is not None:
        lines.append("probe s=%s u=%s zamo_lapse=%s static_clock=%s frame_drag_omega=%s"
                     % (s_text, u_text, precise(zamo_lapse(u_text, s_text)),
                        precise(static_clock(u_text, s_text)),
                        precise(frame_drag_omega(u_text, s_text))))
    for line in lines:
        print(line)
    return EXIT_OK


COMMANDS = {
    "closed": lambda args: cmd_closed(),
    "display": lambda args: cmd_display(),
    "exact": lambda args: cmd_exact(),
    "fixture": lambda args: cmd_fixture(args[0] if args else FIXTURE),
    "check": lambda args: cmd_check(args[0] if args else FIXTURE),
    "probe": cmd_probe,
}


def main(argv):
    if len(argv) < 2 or argv[1] in ("-h", "--help"):
        print(__doc__.strip())
        return EXIT_OK if len(argv) > 1 else EXIT_USAGE
    command = COMMANDS.get(argv[1])
    if command is None:
        print("kerr_ref: unknown command %r; try: %s"
              % (argv[1], " ".join(sorted(COMMANDS))), file=sys.stderr)
        return EXIT_USAGE
    try:
        return command(argv[2:])
    except Refused as exc:
        print("kerr_ref: refused: %s" % exc, file=sys.stderr)
        return EXIT_REFUSED


if __name__ == "__main__":
    sys.exit(main(sys.argv))
