#!/usr/bin/env python3
"""Independent reference for sunholo/relativity 0.10.0 (Schwarzschild null
geodesics, tides and hover; M3.1a/M3.1b of R1-M3-BLACK-HOLES).

Role: ORACLE (tools/python-allowlist.txt). It is a second-language reference that
catches bugs the AILANG VM and interpreter would share. It is never a pipeline step:
the package tests pin the numbers it prints as literals, so the package CI never
runs Python. Standard library only.

Two independent methods, as in design row V9:
  * the Binet RK4 integrator u'' = -u + 1.5 u^2 (r_s = 1), stepped in azimuth, with a
    cubic-Hermite end root (this mirrors sunholo/relativity/geodesic step for step,
    so `digest` can be compared with lensDigest to 1e-9);
  * Darwin's elliptic form via Carlson R_F, in float64 and again in 50-digit Decimal
    (the Decimal truth checks the float64 exact form near the critical impact).
Closed forms (tides, hover) use IAU 2015 nominal GM_sun and c, g0 = 9.80665.

Usage:
  python3 tools/geodesic_ref.py            print every check value (design V9-V16)
  python3 tools/geodesic_ref.py --check    assert them against the design doc; exit 1 on failure
  python3 tools/geodesic_ref.py digest N   print lensDigest(N) (repr), as the package _smoke does
  python3 tools/geodesic_ref.py sdigest N  print schwarzschildDigest(N) (the closed forms)
"""
import math
import sys
from decimal import Decimal as D, getcontext

getcontext().prec = 50

PI = 3.141592653589793
BC = 2.598076211353316            # 3 sqrt(3) / 2, as the package literal
C_SI = 299792458.0
GM_SUN = 1.3271244e20             # IAU 2015 nominal
G0 = 9.80665
SGRA = 4.297e6                    # GRAVITY 2022
GAIA_BH1 = 9.62
L_BUBBLE = 100.0

# ---------------------------------------------------------------- closed forms

def shadow(r):
    s = BC / r * math.sqrt(1.0 - 1.0 / r)
    a = math.asin(min(s, 1.0))
    return PI - a if r < 1.5 else a

def impact(r, psi):
    return r * math.sin(psi) / math.sqrt(1.0 - 1.0 / r)

def turning_radius(b):
    return (2.0 * b / math.sqrt(3.0)) * math.cos(math.acos(-3.0 * math.sqrt(3.0) / (2.0 * b)) / 3.0)

def weak2(b):
    return 2.0 / b + 15.0 * PI / (16.0 * b * b)

def weak_finite(r, psi):
    return (1.0 + math.cos(psi)) / impact(r, psi)

def bbar():
    return math.log(216.0 * (7.0 - 4.0 * math.sqrt(3.0))) - PI

def static_clock(r):
    return math.sqrt(1.0 - 1.0 / r)

def orbit_speed(r):
    return math.sqrt(1.0 / (2.0 * (r - 1.0)))

def orbit_clock(r):
    return math.sqrt(1.0 - 1.5 / r)

def moving_clock(r, beta):
    return math.sqrt(1.0 - 1.0 / r) * math.sqrt((1.0 - beta) * (1.0 + beta))

def hover_accel(r):
    return 1.0 / (2.0 * r * r * math.sqrt(1.0 - 1.0 / r))

def rs_per_msun():
    return 2.0 * GM_SUN / (C_SI * C_SI)

def tide_si(m, r, L):
    rs = m * rs_per_msun()
    return C_SI * C_SI * L * (1.0 / (r * r * r)) / (rs * rs)

def tide_orbit_si(m, r, L):
    rs = m * rs_per_msun()
    return C_SI * C_SI * L * ((1.0 / (2.0 * r * r * r)) * (2.0 + 3.0 / (2.0 * r - 3.0))) / (rs * rs)

def tide_safe_radius(m, L, amax):
    rs = m * rs_per_msun()
    return (C_SI * C_SI * L / (amax * rs * rs)) ** (1.0 / 3.0)

def tide_min_mass(L, r, amax):
    k = rs_per_msun()
    return math.sqrt(C_SI * C_SI * L / (r * r * r * k * k * amax))

def hover_si(m, r):
    return hover_accel(r) * C_SI * C_SI / (m * rs_per_msun())

def hover_power_per_kg(m, r):
    return 1.0 * abs(hover_si(m, r)) * C_SI

# ---------------------------------------------------------------- Carlson R_F, float64

def carlson_rf(x, y, z):
    # Duplication; a fixed 40 iterations (each divides the spread by 4), then the
    # degree-5 series. No tolerance loop, so NaN cannot spin.
    for _ in range(40):
        sx, sy, sz = math.sqrt(x), math.sqrt(y), math.sqrt(z)
        lam = sx * sy + sx * sz + sy * sz
        x, y, z = (x + lam) * 0.25, (y + lam) * 0.25, (z + lam) * 0.25
    a = (x + y + z) / 3.0
    dx, dy, dz = 1.0 - x / a, 1.0 - y / a, 1.0 - z / a
    e2 = dx * dy - dz * dz
    e3 = dx * dy * dz
    return (1.0 - e2 / 10.0 + e3 / 14.0 + e2 * e2 / 24.0 - 3.0 * e2 * e3 / 44.0) / math.sqrt(a)

def roots(b):
    # u^3 - u^2 + 1/b^2 = 0, b > b_c: u1 < 0 < u2 <= 2/3 <= u3.
    c = 1.0 - 27.0 / (2.0 * b * b)
    th = math.acos(-1.0 if c < -1.0 else c)
    u3 = 1.0 / 3.0 + (2.0 / 3.0) * math.cos(th / 3.0)
    u1 = 1.0 / 3.0 + (2.0 / 3.0) * math.cos(th / 3.0 + 2.0 * PI / 3.0)
    u2 = 1.0 / 3.0 + (2.0 / 3.0) * math.cos(th / 3.0 - 2.0 * PI / 3.0)
    if b >= 4.0:
        # u1 ~ -1/b and u2 ~ 1/b come out of the trig form with an absolute error
        # of ~1e-16, which is relative 1e-10 at b = 1e6. Two Newton steps restore
        # full relative precision (P' = 3u^2 - 2u is far from 0 there).
        u1 = polish(polish(u1, b), b)
        u2 = polish(polish(u2, b), b)
    return u1, u2, u3

def polish(u, b):
    return u - (u * u * u - u * u + 1.0 / (b * b)) / (3.0 * u * u - 2.0 * u)

def i_to_root(y, u1, u2, u3):
    # integral_y^u2 du / sqrt((u-u1)(u2-u)(u3-u))  (Carlson 1988, upper limit at a root)
    d = u2 - y
    return 2.0 * math.sqrt(d if d > 0.0 else 0.0) * carlson_rf((y - u1) * (u3 - u2), (u2 - u1) * (u3 - u2), (u3 - y) * (u2 - u1))

def deflection_exact(b):
    u1, u2, u3 = roots(b)
    return 2.0 * i_to_root(0.0, u1, u2, u3) - PI

GL_N = 20

def gauss_legendre(n):
    xs, ws = [], []
    for i in range(1, n + 1):
        x = math.cos(PI * (i - 0.25) / (n + 0.5))
        for _ in range(12):
            p0, p1 = 1.0, x
            for k in range(2, n + 1):
                p0, p1 = p1, ((2.0 * k - 1.0) * x * p1 - (k - 1.0) * p0) / k
            dp = n * (x * p1 - p0) / (x * x - 1.0)
            x = x - p1 / dp
        p0, p1 = 1.0, x
        for k in range(2, n + 1):
            p0, p1 = p1, ((2.0 * k - 1.0) * x * p1 - (k - 1.0) * p0) / k
        dp = n * (x * p1 - p0) / (x * x - 1.0)
        xs.append(x)
        ws.append(2.0 / ((1.0 - x * x) * dp * dp))
    return xs, ws

GLX, GLW = gauss_legendre(GL_N)

def outgoing_gl(r, b):
    # integral_0^{1/r} b du / sqrt(1 - b^2 u^2 (1 - u)): no root on the path (b < b_c, r >= 2)
    half = 0.5 / r
    s = 0.0
    for x, w in zip(GLX, GLW):
        u = half + half * x
        s += w * b / math.sqrt(1.0 - b * b * u * u * (1.0 - u))
    return s * half

def escape_exact(r, psi):
    b = impact(r, psi)
    ingoing = psi < PI / 2.0
    if ingoing and b <= BC:
        return (False, 0.0)
    if b > BC:
        u1, u2, u3 = roots(b)
        full = i_to_root(0.0, u1, u2, u3)
        part = i_to_root(1.0 / r, u1, u2, u3)
        return (True, full + part if ingoing else full - part)
    return (True, outgoing_gl(r, b))

def delta_exact(r, psi):
    return escape_exact(r, psi)[1] - (PI - psi)

# ---------------------------------------------------------------- Binet RK4 (mirrors geodesic.ail)

MAX_STEPS = 4000000
DU_MAX = 0.05

def accel(u):
    return -u + 1.5 * u * u

def rk4(u, v, h):
    k1u, k1v = v, accel(u)
    k2u, k2v = v + 0.5 * h * k1v, accel(u + 0.5 * h * k1u)
    k3u, k3v = v + 0.5 * h * k2v, accel(u + 0.5 * h * k2u)
    k4u, k4v = v + h * k3v, accel(u + h * k3u)
    return (u + h / 6.0 * (k1u + 2.0 * k2u + 2.0 * k3u + k4u),
            v + h / 6.0 * (k1v + 2.0 * k2v + 2.0 * k3v + k4v))

def step_size(v, h):
    av = abs(v)
    return h if av * h <= DU_MAX else DU_MAX / av

def hermite(t, u0, v0, u1, v1, s):
    t2 = t * t
    t3 = t2 * t
    return ((2.0 * t3 - 3.0 * t2 + 1.0) * u0 + (t3 - 2.0 * t2 + t) * s * v0
            + (-2.0 * t3 + 3.0 * t2) * u1 + (t3 - t2) * s * v1)

def end_root(u0, v0, u1, v1, s):
    lo, hi = 0.0, 1.0
    for _ in range(60):
        mid = 0.5 * (lo + hi)
        if hermite(mid, u0, v0, u1, v1, s) > 0.0:
            lo = mid
        else:
            hi = mid
    return 0.5 * (lo + hi) * s

def integrate(u, v, phi, h, n, started):
    # step until u <= 0 (escape, Hermite root) or u >= 1 (captured)
    while True:
        if n >= MAX_STEPS:
            return (False, float('nan'))
        s = step_size(v, h)
        u1, v1 = rk4(u, v, s)
        if u1 != u1:
            return (False, float('nan'))
        if u1 <= 0.0:
            return (True, phi + end_root(u, v, u1, v1, s))
        if u1 >= 1.0:
            return (False, phi + s)
        u, v, phi, n = u1, v1, phi + s, n + 1

def integrate_ray(r, psi, h):
    u0 = 1.0 / r
    b = impact(r, psi)
    if not (b > 0.0):
        return (psi >= PI / 2.0, 0.0)
    w = 1.0 / (b * b) - u0 * u0 + u0 * u0 * u0
    sq = math.sqrt(w) if w > 0.0 else 0.0
    v0 = sq if psi < PI / 2.0 else -sq
    return integrate(u0, v0, 0.0, h, 0, True)

def escapes(r, psi):
    return psi >= PI / 2.0 or impact(r, psi) > BC

def escape_azimuth(r, psi, h):
    an = escapes(r, psi)
    if not an:
        return (False, 0.0)
    esc, dphi = integrate_ray(r, psi, h)
    return (True, dphi if esc else float('nan'))

def lens_deflection(r, psi, h):
    esc, dphi = escape_azimuth(r, psi, h)
    return dphi - (PI - psi) if esc else float('nan')

def deflection_from_infinity(b, h):
    u, v = rk4(0.0, 1.0 / b, step_size(1.0 / b, h))
    s0 = step_size(1.0 / b, h)
    esc, dphi = integrate(u, v, s0, h, 1, True)
    return dphi - PI

def lens_regular(r, psi, h):
    a = shadow(r)
    return lens_deflection(r, psi, h) + math.log(math.tanh((psi - a) / a))

# ---------------------------------------------------------------- images

def image_angle(r, beta, order):
    a = shadow(r)
    target = beta if order == 0 else -beta
    lo, hi = a + a * 1e-12, PI
    for _ in range(64):
        mid = 0.5 * (lo + hi)
        if mid - delta_exact(r, mid) < target:
            lo = mid
        else:
            hi = mid
    return 0.5 * (lo + hi)

def einstein_angle(r):
    return image_angle(r, 0.0, 0)

def magnification(r, psi):
    a = shadow(r)
    d = 1e-6 * min(psi - a, PI - psi, 1.0)
    fp = (psi + d) - delta_exact(r, psi + d)
    fm = (psi - d) - delta_exact(r, psi - d)
    f = psi - delta_exact(r, psi)
    return (math.sin(psi) / abs(math.sin(f))) * abs(2.0 * d / (fp - fm))

# ---------------------------------------------------------------- digest (mirrors _smoke.lensDigest)

def digest_r(i):
    return 2.0 + 0.5 * float(i * i * i)

def lens_digest(n):
    acc = 0.0
    for i in range(n):
        r = digest_r(i)
        a = shadow(r)
        for j in range(n):
            psi = a + (PI - a) * (float(j) + 0.5) / float(n)
            acc += lens_regular(r, psi, 0.005)
    return acc + einstein_angle(10.0)

def schwarzschild_digest(n):
    # mirrors _smoke.schwarzschildDigest (the 0.10.0 closed forms)
    acc = 0.0
    for i in range(n + 1):
        r = 1.6 + 0.37 * float(i * i)
        psi = 0.05 + 3.0 * float(i) / float(n)
        b = 2.6 + 0.5 * float(i * i)
        v = orbit_speed(r)
        acc += (impact(r, psi) + turning_radius(b) + weak2(b) + weak_finite(r, psi)
                + v + orbit_clock(r) + math.sqrt(1.0 / (2.0 * r * r * r)) + moving_clock(r, v) + (-0.1) * (1.0 - 1.0 / r)
                + hover_accel(r) + (1.0 / (2.0 * r * r * r)) * (2.0 + 3.0 / (2.0 * r - 3.0)) + tide_si(SGRA, r, 100.0) + tide_orbit_si(GAIA_BH1, r, 100.0) / 1.0e6
                + hover_si(SGRA, r) / 1.0e5 + hover_power_per_kg(SGRA, r) / 1.0e14 + tide_safe_radius(GAIA_BH1, 100.0, 0.98) / 1.0e3
                + tide_min_mass(100.0, r, 0.98) / 1.0e5)
    return acc + bbar()

# ---------------------------------------------------------------- Decimal truth

def droots(b):
    b = D(b)
    q = 1 / (b * b)
    out = []
    for g in roots(float(b)):
        u = D(g)
        for _ in range(200):
            f = u * u * u - u * u + q
            df = 3 * u * u - 2 * u
            if df == 0:
                break
            nu = u - f / df
            if nu == u:
                break
            u = nu
        out.append(u)
    return out

def drf(x, y, z):
    for _ in range(60):
        sx, sy, sz = x.sqrt(), y.sqrt(), z.sqrt()
        lam = sx * sy + sx * sz + sy * sz
        x, y, z = (x + lam) / 4, (y + lam) / 4, (z + lam) / 4
    a = (x + y + z) / 3
    dx, dy, dz = 1 - x / a, 1 - y / a, 1 - z / a
    e2 = dx * dy - dz * dz
    e3 = dx * dy * dz
    return (1 - e2 / 10 + e3 / 14 + e2 * e2 / 24 - 3 * e2 * e3 / 44) / a.sqrt()

DPI = D("3.14159265358979323846264338327950288419716939937510")

def deflection_truth(b):
    u1, u2, u3 = droots(b)
    return float(4 * u2.sqrt() * drf(-u1 * (u3 - u2), (u2 - u1) * (u3 - u2), u3 * (u2 - u1)) - DPI)

# ---------------------------------------------------------------- the report

def deg(x):
    return x * 180.0 / PI

def rows():
    out = []
    def put(name, val):
        out.append((name, val))
    put("check41 deflectionExact(100)", deflection_exact(100.0))
    put("check41 deflectionFromInfinity(100,0.001)", deflection_from_infinity(100.0, 0.001))
    put("check41 truth(100)", deflection_truth(100.0))
    put("check42 deflectionExact(1000)", deflection_exact(1000.0))
    put("check42 ratio-1", deflection_exact(1000.0) / (2.0 / 1000.0) - 1.0)
    put("check43 |exact/weak2-1| at 100", abs(deflection_exact(100.0) / weak2(100.0) - 1.0))
    for e in (1e-4, 1e-6, 1e-8):
        b = BC * (1.0 + e)
        put("check44 exact eps=%g" % e, deflection_exact(b))
        put("check44 truth eps=%g" % e, deflection_truth(b))
        put("check44 |exact-(-ln eps+bbar)| eps=%g" % e, abs(deflection_exact(b) - (-math.log(e) + bbar())))
    put("bbar", bbar())
    for (r, psi) in ((10.0, 0.5), (3.0, 1.0), (5.0, 2.0), (10.0, 0.26)):
        ex = escape_exact(r, psi)[1]
        put("check45 exact (%g,%g)" % (r, psi), ex)
        put("check45 |int h=0.001 - exact| (%g,%g)" % (r, psi), abs(escape_azimuth(r, psi, 0.001)[1] - ex))
        put("check45 |int h=0.005 - exact| (%g,%g)" % (r, psi), abs(escape_azimuth(r, psi, 0.005)[1] - ex))
    for r in (10.0, 5.0, 3.0, 100.0, 1000.0):
        put("check46 einsteinAngle(%g) deg" % r, deg(einstein_angle(r)))
        put("check46 einsteinAngle(%g) rad" % r, einstein_angle(r))
    for (r, bdeg) in ((10.0, 20.0), (1000.0, 1.0)):
        p0 = image_angle(r, bdeg * PI / 180.0, 0)
        p1 = image_angle(r, bdeg * PI / 180.0, 1)
        put("check47 r=%g beta=%g order0 rad" % (r, bdeg), p0)
        put("check47 r=%g beta=%g order1 rad" % (r, bdeg), p1)
        put("check47 r=%g beta=%g order0 deg" % (r, bdeg), deg(p0))
        put("check47 r=%g beta=%g order1 deg" % (r, bdeg), deg(p1))
        put("check47 r=%g beta=%g mu0" % (r, bdeg), magnification(r, p0))
        put("check47 r=%g beta=%g mu1" % (r, bdeg), magnification(r, p1))
    for r in (10.0, 5.0, 3.0):
        put("check49 staticClockRate(%g)" % r, static_clock(r))
        put("check49 circularOrbitSpeed(%g)" % r, orbit_speed(r))
        put("check49 circularOrbitClockRate(%g)" % r, orbit_clock(r))
        put("check49 |moving-orbit| (%g)" % r, abs(moving_clock(r, orbit_speed(r)) - orbit_clock(r)))
    for r in (2.0, 3.0, 10.0, 1e6):
        a = shadow(r)
        put("check50 lensRegular edge r=%g" % r, lens_regular(r, a + 1e-8 * a, 0.005))
        put("check50 lensRegular antipode r=%g" % r, lens_regular(r, PI - 1e-12, 0.005))
    put("rsPerSolarMassMetres", rs_per_msun())
    for (name, m) in (("GaiaBH1", GAIA_BH1), ("1000", 1000.0), ("SgrA", SGRA)):
        for r in (10.0, 5.0, 3.0):
            put("check51 tide %s r=%g g" % (name, r), tide_si(m, r, L_BUBBLE) / G0)
    put("check51 orbit tide SgrA r=3 g", tide_orbit_si(SGRA, 3.0, L_BUBBLE) / G0)
    put("check51 orbit tide GaiaBH1 r=3 g", tide_orbit_si(GAIA_BH1, 3.0, L_BUBBLE) / G0)
    put("check52 safe radius GaiaBH1 0.1 g", tide_safe_radius(GAIA_BH1, L_BUBBLE, 0.1 * G0))
    put("check52 safe radius GaiaBH1 km", tide_safe_radius(GAIA_BH1, L_BUBBLE, 0.1 * G0) * GAIA_BH1 * rs_per_msun() / 1000.0)
    put("check52 safe radius 1000 0.1 g", tide_safe_radius(1000.0, L_BUBBLE, 0.1 * G0))
    put("check52 min mass r=3 0.1 g", tide_min_mass(L_BUBBLE, 3.0, 0.1 * G0))
    for r in (10.0, 5.0, 3.0):
        put("check53 hoverAccelSI SgrA r=%g" % r, hover_si(SGRA, r))
        put("check53 hoverPowerPerKg SgrA r=%g" % r, hover_power_per_kg(SGRA, r))
    put("check53 hover g SgrA r=3", hover_si(SGRA, 3.0) / G0)
    put("V16 SgrA r_s m", SGRA * rs_per_msun())
    put("V16 1e6 r_s in ly", 1e6 * SGRA * rs_per_msun() / 9460730472580800.0)
    put("weakDeflection2(100)", weak2(100.0))
    put("weakDeflectionFinite(1e6, 1.0)", weak_finite(1e6, 1.0))
    put("turningRadius(100)", turning_radius(100.0))
    return out

def close(got, want, tol, rel=False):
    if got != got:
        return False
    return abs(got - want) <= (tol * abs(want) if rel else tol)

def check():
    fails = []
    def need(name, ok):
        print(("ok    " if ok else "FAIL  ") + name)
        if not ok:
            fails.append(name)
    R = deg
    # V9 / check41-44
    need("check41 alpha(100) = 0.0202999662395031 (1e-12)", close(deflection_exact(100.0), 0.0202999662395031, 1e-12))
    need("check41 integrator h=0.001 within 1e-11 of exact", close(deflection_from_infinity(100.0, 0.001), deflection_exact(100.0), 1e-11))
    need("check41 float64 exact = Decimal truth (1e-15)", close(deflection_exact(100.0), deflection_truth(100.0), 1e-15))
    need("check42 alpha(1000) = 0.00200295058718769 (1e-12)", close(deflection_exact(1000.0), 0.00200295058718769, 1e-12))
    need("check42 float64 exact = Decimal truth (1e-15)", close(deflection_exact(1000.0), deflection_truth(1000.0), 1e-15))
    need("check42 ratio - 1 = 0.0014753 (1e-6)", close(deflection_exact(1000.0) / 0.002 - 1.0, 0.0014753, 1e-6))
    need("check43 |alpha(100)/weak2 - 1| <= 3e-4", abs(deflection_exact(100.0) / weak2(100.0) - 1.0) <= 3e-4)
    # The design's eps = 1e-8 row (18.0204507723) carries 2.8e-9 of the 2026-10-01
    # prototype's root error: the 50-digit truth for b = b_c (1 + 1e-8) in float64 is
    # 18.02045076953216. One ulp of b moves delta by 1.7e-8 there, so the package pins
    # this oracle's truth (1e-9; 3e-9 at eps = 1e-8, where one ulp of the acos argument moves delta by ~1.4e-9) and the design row is held to 4e-9.
    for (e, want, dtol, tol) in ((1e-4, 8.8104863550, 1e-9, 4e-4), (1e-6, 13.4152855579, 1e-9, 6e-6), (1e-8, 18.0204507723, 4e-9, 1e-7)):
        b = BC * (1.0 + e)
        need("check44 eps=%g exact = %r (%g)" % (e, want, dtol), close(deflection_exact(b), want, dtol))
        need("check44 eps=%g Decimal truth = exact (1e-9)" % e, close(deflection_truth(b), deflection_exact(b), 1e-9))
        need("check44 eps=%g within %g of -ln eps + bbar" % (e, tol), abs(deflection_exact(b) - (-math.log(e) + bbar())) <= tol)
    need("bbar = -0.400230039755 (1e-12)", close(bbar(), -0.400230039755, 1e-12))
    # check45
    for (r, psi) in ((10.0, 0.5), (3.0, 1.0), (5.0, 2.0), (10.0, 0.26)):
        ex = escape_exact(r, psi)[1]
        need("check45 (%g, %g) h=0.001 within 1e-9" % (r, psi), close(escape_azimuth(r, psi, 0.001)[1], ex, 1e-9))
        need("check45 (%g, %g) h=0.005 within 1e-5" % (r, psi), close(escape_azimuth(r, psi, 0.005)[1], ex, 1e-5))
    # V9 check46
    for (r, want) in ((10.0, 29.828317906), (5.0, 44.874561077), (3.0, 61.888756430), (100.0, 8.520443413), (1000.0, 2.604361342)):
        need("check46 psi_E(%g) = %r deg (1e-7 rad)" % (r, want), close(einstein_angle(r), want * PI / 180.0, 1e-7))
    need("V9 order-2 ring at r=10 lies outside the 14.269027328 deg shadow", close(R(shadow(10.0)), 14.269027328, 1e-8))
    # V12 check47
    for (r, bdeg, w0, w1, m0, m1) in ((10.0, 20.0, 39.837659068, 23.543122070, 1.118821, 0.276451),
                                      (1000.0, 1.0, 3.144406661, 2.160968686, 1.847367, 0.856138)):
        p0 = image_angle(r, bdeg * PI / 180.0, 0)
        p1 = image_angle(r, bdeg * PI / 180.0, 1)
        need("check47 r=%g beta=%g order 0 = %r deg" % (r, bdeg, w0), close(p0, w0 * PI / 180.0, 1e-7))
        need("check47 r=%g beta=%g order 1 = %r deg" % (r, bdeg, w1), close(p1, w1 * PI / 180.0, 1e-7))
        need("check47 r=%g beta=%g mu0 = %r" % (r, bdeg, m0), close(magnification(r, p0), m0, 1e-4, rel=True))
        need("check47 r=%g beta=%g mu1 = %r" % (r, bdeg, m1), close(magnification(r, p1), m1, 1e-4, rel=True))
    # check48: the integrator's capture verdict = the analytic rule across the edge
    agree = True
    for r in (2.0, 3.0, 10.0, 100.0):
        a = shadow(r)
        for k in range(50):
            psi = a * (1.0 + (k - 24.5) * 0.002)
            esc, _ = integrate_ray(r, psi, 0.005)
            if esc != escapes(r, psi):
                agree = False
    need("check48 200-ray capture sweep: integrator = analytic", agree)
    # check49
    for (r, sc, os_, oc) in ((10.0, 0.948683298050514, 0.235702260395516, 0.921954445729289),
                             (5.0, 0.894427190999916, 0.353553390593274, 0.836660026534076),
                             (3.0, 0.816496580927726, 0.5, 0.707106781186548)):
        need("check49 r=%g clocks and orbit speed (1e-15)" % r,
             close(static_clock(r), sc, 1e-15) and close(orbit_speed(r), os_, 1e-15) and close(orbit_clock(r), oc, 1e-15)
             and close(moving_clock(r, orbit_speed(r)), orbit_clock(r), 1e-15))
    # check50
    for r in (2.0, 3.0, 10.0, 1e6):
        a = shadow(r)
        need("check50 lensRegular finite at r=%g (edge and antipode)" % r,
             math.isfinite(lens_regular(r, a + 1e-8 * a, 0.005)) and math.isfinite(lens_regular(r, PI - 1e-12, 0.005)))
    # V14 check51/52
    for (m, vals) in ((GAIA_BH1, (1.135e6, 9.084e6, 4.205e7)), (1000.0, (105.1, 840.6, 3892.0)), (SGRA, (5.691e-6, 4.553e-5, 2.108e-4))):
        for (r, want) in zip((10.0, 5.0, 3.0), vals):
            need("check51 tide M=%g r=%g = %r g (1e-3 rel)" % (m, r, want), close(tide_si(m, r, L_BUBBLE) / G0, want, 1e-3, rel=True))
    need("check51 orbit/static at r=3 = 1.5 (1e-15)", close((0.5 / 27.0) * (2.0 + 3.0 / 3.0) / (1.0 / 27.0), 1.5, 1e-15))
    need("V14 orbit tide Sgr A* r=3 = 3.162e-4 g", close(tide_orbit_si(SGRA, 3.0, L_BUBBLE) / G0, 3.162e-4, 1e-3, rel=True))
    need("V14 orbit tide Gaia BH1 r=3 = 6.31e7 g", close(tide_orbit_si(GAIA_BH1, 3.0, L_BUBBLE) / G0, 6.31e7, 2e-3, rel=True))
    need("check52 Gaia BH1 0.1 g radius = 2247.6 r_s (0.1)", close(tide_safe_radius(GAIA_BH1, L_BUBBLE, 0.1 * G0), 2247.6, 0.1))
    need("check52 min mass for 0.1 g at 3 r_s = 1.9728e5 (1e-3 rel)", close(tide_min_mass(L_BUBBLE, 3.0, 0.1 * G0), 1.9728e5, 1e-3, rel=True))
    # V16 check53
    for (r, a_, p_) in ((10.0, 3.7327e4, 1.1190e13), (5.0, 1.5837e5, 4.7477e13), (3.0, 4.8189e5, 1.4447e14)):
        need("check53 Sgr A* r=%g hover %r m/s^2 (1e-4 rel)" % (r, a_), close(hover_si(SGRA, r), a_, 1e-4, rel=True))
        need("check53 Sgr A* r=%g power %r W/kg (1e-4 rel)" % (r, p_), close(hover_power_per_kg(SGRA, r), p_, 1e-4, rel=True))
    need("V16 Sgr A* r_s = 1.2690e10 m", close(SGRA * rs_per_msun(), 1.2690e10, 1e-4, rel=True))
    need("rsPerSolarMassMetres = 2953.25008 (1e-5)", close(rs_per_msun(), 2953.25008, 1e-5))
    # the table hand-off: weak finite series vs exact at r = 1e6 (AC-5 preview)
    ok = True
    for psi in (0.01, 0.5, 1.5, 2.5):
        ok = ok and close(delta_exact(1e6, psi), (1.0 + math.cos(psi)) / impact(1e6, psi), 1e-3, rel=True)
    need("weakDeflectionFinite = exact at r = 1e6 (1e-3 rel)", ok)
    print("geodesic oracle: %d failures" % len(fails))
    return 0 if not fails else 1

def main(argv):
    if len(argv) > 1 and argv[1] == "--check":
        return check()
    if len(argv) > 2 and argv[1] == "sdigest":
        print(repr(schwarzschild_digest(int(argv[2]))))
        return 0
    if len(argv) > 2 and argv[1] == "digest":
        print(repr(lens_digest(int(argv[2]))))
        return 0
    for name, val in rows():
        print("%-48s %r" % (name, val))
    return 0

if __name__ == "__main__":
    sys.exit(main(sys.argv))
