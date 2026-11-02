class_name Kerr
extends RefCounted
## Float64 CPU mirror of sunholo/relativity/kerr 0.14.0 candidate.
## Input u is GM/c²; returned radii are r_s. No Vector3 physics arithmetic.
## Legacy Schwarzschild operation order, from the package's existing exports.
static func _schwarz_clock(r: float) -> float:
	return sqrt(1.0 - 1.0 / r)

static func valid_spin(s: float) -> bool:
	return is_finite(s) and s >= 0.0 and s < 1.0

static func horizon_r(s: float) -> float:
	return (1.0 + sqrt((1.0 - s) * (1.0 + s))) / 2.0 if valid_spin(s) else NAN

static func horizon_inner_r(s: float) -> float:
	return s * s / (2.0 * (1.0 + sqrt((1.0 - s) * (1.0 + s)))) if valid_spin(s) else NAN

static func static_limit_r(s: float, c: float) -> float:
	if not valid_spin(s) or not is_finite(c) or absf(c) > 1.0:
		return NAN
	var x := s * c
	return (1.0 + sqrt((1.0 - x) * (1.0 + x))) / 2.0

static func horizon_omega(s: float) -> float:
	return s / (4.0 * horizon_r(s)) if valid_spin(s) else NAN

static func metric_delta(u: float, s: float) -> float:
	return (u - 2.0 * horizon_r(s)) * (u - 2.0 * horizon_inner_r(s)) if valid_spin(s) and is_finite(u) and u >= 0.0 and u <= 2e6 else NAN

static func _a_scaled(u: float, c: float, s: float) -> float:
	var x2 := (s / u) * (s / u)
	return (1.0 + x2) * (1.0 + x2) - x2 * (1.0 - 2.0 / u + x2) * (1.0 - c * c)

static func _exterior(u: float, c: float, s: float) -> bool:
	return valid_spin(s) and is_finite(c) and absf(c) <= 1.0 and is_finite(u) and u > 2.0 * horizon_r(s)

static func frame_drag_omega(u: float, c: float, s: float) -> float:
	if not _exterior(u, c, s):
		return NAN
	return 0.0 if s == 0.0 else 2.0 * (s / u) / u / u / _a_scaled(u, c, s)

static func zamo_clock_rate(u: float, c: float, s: float) -> float:
	if not _exterior(u, c, s):
		return NAN
	if s == 0.0:
		return _schwarz_clock(u / 2.0)
	return sqrt((1.0 - 2.0 * horizon_r(s) / u) * (1.0 - 2.0 * horizon_inner_r(s) / u) * (1.0 + (s / u) * (s / u) * c * c) / _a_scaled(u, c, s))

static func static_clock_rate(u: float, c: float, s: float) -> float:
	if not _exterior(u, c, s) or u <= 2.0 * static_limit_r(s, c):
		return NAN
	if s == 0.0 or c == 0.0:
		return _schwarz_clock(u / 2.0)
	return sqrt(1.0 - 2.0 / u / (1.0 + (s / u) * (s / u) * c * c))

static func photon_r(s: float, sense: float) -> float:
	if not valid_spin(s) or absf(sense) != 1.0:
		return NAN
	return 1.5 if s == 0.0 else 1.0 + cos((2.0 / 3.0) * acos(-sense * s))

static func isco_r(s: float, sense: float) -> float:
	if not valid_spin(s) or absf(sense) != 1.0:
		return NAN
	if s == 0.0:
		return 3.0
	if s < 0.01:
		var x := sqrt(6.0)
		for _i in range(4):
			x -= (x*x*x*x - 6.0*x*x + 8.0*sense*s*x - 3.0*s*s) / (4.0*x*x*x - 12.0*x + 8.0*sense*s)
		return x*x / 2.0
	var q := 1.0 - s
	var z1 := 1.0 + pow(q * (1.0 + s), 1.0/3.0) * (pow(1.0 + s, 1.0/3.0) + pow(q, 1.0/3.0))
	var z2 := sqrt(3.0*s*s + z1*z1)
	return (3.0 + z2 - sense * sqrt(maxf(0.0, (3.0-z1)*(3.0+z1+2.0*z2)))) / 2.0

static func _orbit(u: float, s: float, sense: float) -> bool:
	return valid_spin(s) and is_finite(u) and absf(sense) == 1.0 and u > 2.0 * photon_r(s, sense)

static func orbit_omega(u: float, s: float, sense: float) -> float:
	if not _orbit(u, s, sense):
		return NAN
	var r := u / 2.0
	return sense * sqrt(1.0 / (2.0 * r * r * r)) / 2.0 if s == 0.0 else sense / (u * sqrt(u) + sense * s)

static func orbit_clock_rate(u: float, s: float, sense: float) -> float:
	if not _orbit(u, s, sense):
		return NAN
	if s == 0.0:
		return sqrt(1.0 - 1.5 / (u / 2.0))
	var x := sense * (s / u) / sqrt(u)
	return sqrt(1.0 - 3.0 / u + 2.0 * x) / (1.0 + x)

static func orbit_local_speed(u: float, s: float, sense: float) -> float:
	if not _orbit(u, s, sense):
		return NAN
	return sense * sqrt(1.0 / (2.0 * (u / 2.0 - 1.0))) if s == 0.0 else (orbit_omega(u, s, sense) - frame_drag_omega(u, 0.0, s)) * u * sqrt(_a_scaled(u, 0.0, s)) / zamo_clock_rate(u, 0.0, s)

## Mirrors kerr_frame. Components are (radial, theta, phi), source-directed.
static func metric_frame(u: float, s: float) -> Dictionary:
	return {"lapse": zamo_clock_rate(u, 0.0, s), "omega": frame_drag_omega(u, 0.0, s), "h": sqrt(u*u + s*s + 2.0*s*s/u)}

static func source_constants(u: float, s: float, n: PackedFloat64Array) -> Dictionary:
	var f := metric_frame(u, s)
	var energy: float = f.lapse - f.omega * f.h * n[2]
	return {"lambda": -f.h*n[2]/energy, "eta": pow(u*n[1]/energy, 2.0), "energy": energy}

static func static_velocity(u: float, s: float) -> PackedFloat64Array:
	var f := metric_frame(u, s)
	return PackedFloat64Array([0.0, 0.0, -f.omega*f.h/f.lapse])

static func radial_velocity(u: float, s: float, b: float) -> PackedFloat64Array:
	var v := static_velocity(u, s)
	return PackedFloat64Array([b*sqrt((1.0-v[2])*(1.0+v[2])), 0.0, v[2]])

static func circular_velocity(u: float, s: float, sense: float) -> PackedFloat64Array:
	return PackedFloat64Array([0.0, 0.0, orbit_local_speed(u, s, sense)])

static func dot64(a: PackedFloat64Array, b: PackedFloat64Array) -> float:
	return a[0]*b[0] + a[1]*b[1] + a[2]*b[2]

static func gamma_velocity(v: PackedFloat64Array) -> float:
	var b := sqrt(dot64(v, v))
	return 1.0 / sqrt((1.0-b)*(1.0+b))

static func boost_source(n: PackedFloat64Array, v: PackedFloat64Array, g: float) -> PackedFloat64Array:
	var b := sqrt(dot64(v, v))
	if b == 0.0:
		return n.duplicate()
	var d := dot64(n, v)
	var c := d / b
	var complement := ((1.0/g)/g)/(1.0+b)
	var den := g * (complement+b*(1.0+c) if c < 0.0 else 1.0+d)
	var f := g*(g/(g+1.0))*d+g
	return PackedFloat64Array([(n[0]+f*v[0])/den, (n[1]+f*v[1])/den, (n[2]+f*v[2])/den])

static func frequency_ratio(u: float, s: float, n: PackedFloat64Array, v: PackedFloat64Array) -> float:
	var f := metric_frame(u, s)
	var c := source_constants(u, s, n)
	return gamma_velocity(v) * (1.0 + dot64(v, n)) * (1.0 - f.omega*c.lambda) / f.lapse

## Mirror kerr_trace's regular action-angle reconstruction, all scalar float64.
static func lens_direction(u: float, s: float, psi: float, chi: float, bend: float, twist: float) -> PackedFloat64Array:
	var n := PackedFloat64Array([-cos(psi), sin(psi)*sin(chi), sin(psi)*cos(chi)])
	var c := source_constants(u, s, n)
	var lb: float = c.lambda / u
	var eb: float = (c.eta / u) / u
	var sb := s / u
	var aa := lb*lb + eb - sb*sb
	var disc := sqrt(aa*aa + 4.0*sb*sb*eb)
	var b := 0.0 if c.eta == 0.0 else ((aa+disc)/2.0 if aa >= 0.0 else 2.0*sb*sb*eb/(disc-aa))
	var ci := (-signf(lb) if c.eta == 0.0 else -lb/sqrt(b+sb*sb))
	var amp := 0.0 if c.eta == 0.0 else sqrt(eb/b)*(-1.0 if n[1]>0.0 else 1.0)
	var phase := bend + PI - psi
	var x := cos(phase)
	var y := ci*sin(phase)
	var v := PackedFloat64Array([cos(twist)*x-sin(twist)*y, sin(twist)*x+cos(twist)*y, amp*sin(phase)])
	var norm := sqrt(dot64(v, v))
	return PackedFloat64Array([v[0]/norm, v[1]/norm, v[2]/norm])
