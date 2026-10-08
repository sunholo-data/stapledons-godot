class_name Schwarzschild
extends RefCounted
## CPU reference for the Schwarzschild lens (M3.3 of R1-M3-BLACK-HOLES; relativity spec §3).
##
## A float64 mirror of sunholo/relativity 0.10.0 (`schwarzschild`, `geodesic`) and of the
## lens tables that sim/tools/lens_lut.ail bakes from it. It is never the only copy: every
## formula here is the package's, and tests/test_physics.gd pins it to the package's own
## check values. The GPU include (M3.5a) mirrors the table half of this file function for
## function, using the same float32 texels.
##
## Conventions (package and spec §1): radii and impact parameters in r_s = 1 (horizon at
## r = 1), angles in radians. h is the unit vector from the observer TOWARD the hole; psi is a
## ray's angle from h in the static observer's frame; F = psi - delta is the angle of the
## source at infinity from h in the same plane (F < 0: the far side of the hole).
## Vectors are Godot float32 (Vector3); every scalar here is float64.

const B_C := 2.598076211353316 # 3 sqrt(3) / 2 (package criticalImpact)
const PHOTON_SPHERE := 1.5
const R_WEAK := 1000000.0 # beyond the last table row: first-order weakDeflectionFinite
const N_COLS := 2048
const N_ROWS := 256
const LENS_DIR := "res://data/lens"

static var _fwd := PackedFloat32Array()
static var _inv := PackedFloat32Array()
static var _x_min := 0.0
static var _y_min := 0.0
static var _y_max := 0.0
static var headers := {}
static var load_error := "not loaded"


# ---------------------------------------------------------------- closed forms

## Synge: sin alpha = (b_c / r) sqrt(1 - 1/r); alpha > pi/2 inside the photon sphere.
static func shadow_angle(r: float) -> float:
	var s := B_C / r * sqrt(1.0 - 1.0 / r)
	var a := asin(minf(s, 1.0))
	return PI - a if r < PHOTON_SPHERE else a


## Static observer's blueshift of light from infinity, 1/sqrt(1 - 1/r). Tests only: the HUD
## shows the sim's value, never this one.
static func static_blueshift(r: float) -> float:
	return 1.0 / sqrt(1.0 - 1.0 / r)


static func impact(r: float, psi: float) -> float:
	return r * sin(psi) / sqrt(1.0 - 1.0 / r)


## First-order deflection seen at r of a source at infinity (package weakDeflectionFinite).
static func weak_deflection_finite(r: float, psi: float) -> float:
	var b := impact(r, psi)
	return (1.0 + cos(psi)) / b if b > 0.0 else 0.0


## The r-only factor of weak_deflection_finite: delta = weak_k(r) cot(psi / 2), since
## (1 + cos psi) / b = cot(psi / 2) / impact(r, pi / 2). The shader's gr_weak_k (M3.6: moved
## here from sky/gr_lens.gd so no client file holds a Schwarzschild formula).
static func weak_k(r: float) -> float:
	return 1.0 / impact(r, PI / 2.0)


static func weak_deflection2(b: float) -> float:
	return 2.0 / b + 15.0 * PI / (16.0 * b * b)


## A ray escapes iff it is outgoing or ingoing with b > b_c (r >= 1.5), i.e. iff psi > alpha_sh.
static func escapes(r: float, psi: float) -> bool:
	return psi >= PI * 0.5 or impact(r, psi) > B_C


# ---------------------------------------------------------------- exact form (oracle mirror)

static func _rf_series(x: float, y: float, z: float) -> float:
	var a := (x + y + z) / 3.0
	var dx := 1.0 - x / a
	var dy := 1.0 - y / a
	var dz := 1.0 - z / a
	var e2 := dx * dy - dz * dz
	var e3 := dx * dy * dz
	return (1.0 - e2 / 10.0 + e3 / 14.0 + e2 * e2 / 24.0 - 3.0 * e2 * e3 / 44.0) / sqrt(a)


## Carlson R_F by 40 fixed duplications then the degree-5 series (package carlsonRF).
static func carlson_rf(x: float, y: float, z: float) -> float:
	for i in 40:
		var sx := sqrt(x)
		var sy := sqrt(y)
		var sz := sqrt(z)
		var lam := sx * sy + sx * sz + sy * sz
		x = (x + lam) * 0.25
		y = (y + lam) * 0.25
		z = (z + lam) * 0.25
	return _rf_series(x, y, z)


static func _polish(u: float, b: float) -> float:
	return u - (u * u * u - u * u + 1.0 / (b * b)) / (3.0 * u * u - 2.0 * u)


## Roots u1 < 0 < u2 <= 2/3 <= u3 of u^3 - u^2 + 1/b^2 (b > b_c).
static func _roots(b: float) -> Array[float]:
	var c := 1.0 - 27.0 / (2.0 * b * b)
	var th := acos(maxf(c, -1.0))
	var u3 := 1.0 / 3.0 + (2.0 / 3.0) * cos(th / 3.0)
	var u1 := 1.0 / 3.0 + (2.0 / 3.0) * cos(th / 3.0 + 2.0 * PI / 3.0)
	var u2 := 1.0 / 3.0 + (2.0 / 3.0) * cos(th / 3.0 - 2.0 * PI / 3.0)
	if b >= 4.0:
		u1 = _polish(_polish(u1, b), b)
		u2 = _polish(_polish(u2, b), b)
	return [u1, u2, u3]


static func _to_root(y: float, rt: Array[float]) -> float:
	var d := rt[1] - y
	return 2.0 * sqrt(maxf(d, 0.0)) * carlson_rf((y - rt[0]) * (rt[2] - rt[1]), (rt[1] - rt[0]) * (rt[2] - rt[1]), (rt[2] - y) * (rt[1] - rt[0]))


## Exact deflection from infinity (Darwin): 2 I(0, u2) - pi.
static func deflection_from_infinity_exact(b: float) -> float:
	return 2.0 * _to_root(0.0, _roots(b)) - PI


const _GL_X := [0.07652652113349734, 0.22778585114164507, 0.37370608871541955, 0.5108670019508271,
	0.636053680726515, 0.7463319064601508, 0.8391169718222189, 0.912234428251326,
	0.9639719272779138, 0.9931285991850949]
const _GL_W := [0.15275338713072598, 0.14917298647260382, 0.14209610931838215, 0.1316886384491765,
	0.11819453196151831, 0.10193011981724048, 0.08327674157670474, 0.06267204833410904,
	0.04060142980038705, 0.017614007139152264]


static func _out_int(u: float, b: float) -> float:
	return b / sqrt(1.0 - b * b * u * u * (1.0 - u))


## Azimuth swept from the observer to infinity, exact (package escapeAzimuthExact, r >= 2);
## -1.0 when captured.
static func escape_azimuth_exact(r: float, psi: float) -> float:
	var b := impact(r, psi)
	var ingoing := psi < PI * 0.5
	if ingoing and b <= B_C:
		return -1.0
	if b > B_C:
		var rt := _roots(b)
		var full := _to_root(0.0, rt)
		var part := _to_root(1.0 / r, rt)
		return full + part if ingoing else full - part
	# outgoing with b <= b_c: 20-point Gauss-Legendre on [0, 1/r] (smooth for r >= 2)
	var mid := 0.5 / r
	var s := 0.0
	for k in _GL_X.size():
		s += _GL_W[k] * (_out_int(mid + mid * _GL_X[k], b) + _out_int(mid - mid * _GL_X[k], b))
	return s * mid


## Exact deflection seen at r (NaN when captured).
static func deflection_exact(r: float, psi: float) -> float:
	var dphi := escape_azimuth_exact(r, psi)
	return NAN if dphi < 0.0 else dphi - (PI - psi)


## Exact image angle (64 bisections of F(psi) = psi - delta = +beta order 0, -beta order 1).
static func image_angle_exact(r: float, beta: float, order: int) -> float:
	var a := shadow_angle(r)
	var lo := a + a * 1e-12
	var hi := PI
	var target := beta if order == 0 else -beta
	for i in 64:
		var mid := 0.5 * (lo + hi)
		if mid - deflection_exact(r, mid) < target:
			lo = mid
		else:
			hi = mid
	return 0.5 * (lo + hi)


static func einstein_angle(r: float) -> float:
	return image_angle_exact(r, 0.0, 0)


## Magnification (sin psi / |sin F|) |dpsi/dF| by a central difference of the exact form.
static func image_magnification_exact(r: float, psi: float) -> float:
	var a := shadow_angle(r)
	var d := 1e-6 * minf(minf(psi - a, PI - psi), 1.0)
	var fp := (psi + d) - deflection_exact(r, psi + d)
	var fm := (psi - d) - deflection_exact(r, psi - d)
	var f := psi - deflection_exact(r, psi)
	return (sin(psi) / absf(sin(f))) * absf(2.0 * d / (fp - fm))


# ---------------------------------------------------------------- tables

## Row radius: y = ln(r - 1.5) uniform; the end rows are exactly r = 2 and r = 1e6.
static func row_radius(j: int) -> float:
	if j <= 0:
		return 2.0
	if j >= N_ROWS - 1:
		return R_WEAK
	return 1.5 + exp(_y_min + (_y_max - _y_min) * float(j) / float(N_ROWS - 1))


static func row_x_max(r: float) -> float:
	var a := shadow_angle(r)
	return log((PI - a) / a)


static func _read_header(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


## Load data/lens/lens_{fwd,inv}.{bin,json}; checks each bin's size and its header sha256.
## Returns false (and sets load_error) on any mismatch; make lens-assets fetches them.
static func load_tables(dir: String = LENS_DIR) -> bool:
	load_error = ""
	for t in ["fwd", "inv"]:
		var hdr := _read_header("%s/lens_%s.json" % [dir, t])
		var bin := "%s/lens_%s.bin" % [dir, t]
		if hdr.is_empty() or not FileAccess.file_exists(bin):
			load_error = "lens_%s missing (run make lens-assets)" % t
			return false
		if FileAccess.get_sha256(bin) != str(hdr.get("sha256", {}).get("bin", "")):
			load_error = "lens_%s.bin sha256 differs from its header" % t
			return false
		if int(hdr.get("width", 0)) != N_COLS or int(hdr.get("height", 0)) != N_ROWS:
			load_error = "lens_%s layout differs from the mirror" % t
			return false
		var data := FileAccess.get_file_as_bytes(bin).to_float32_array()
		if data.size() != N_COLS * N_ROWS * 2:
			load_error = "lens_%s.bin has %d floats" % [t, data.size()]
			return false
		headers[t] = hdr
		if t == "fwd":
			_fwd = data
		else:
			_inv = data
	_x_min = float(headers["fwd"]["column"]["min"])
	_y_min = float(headers["fwd"]["row"]["min"])
	_y_max = float(headers["fwd"]["row"]["max"])
	return true


static func fwd_table() -> PackedFloat32Array:
	return _fwd


static func inv_table() -> PackedFloat32Array:
	return _inv


## Fractional row of radius r (2 <= r <= 1e6).
static func row_coordinate(r: float) -> float:
	return clampf((log(r - 1.5) - _y_min) / (_y_max - _y_min) * float(N_ROWS - 1), 0.0, float(N_ROWS - 1))


## Catmull-Rom through p0..p3 at t in [0, 1] between p1 and p2.
static func catmull_rom(p0: float, p1: float, p2: float, p3: float, t: float) -> float:
	return 0.5 * ((2.0 * p1) + (p2 - p0) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t
		+ (3.0 * p1 - p0 - 3.0 * p2 + p3) * t * t * t)


## Linear in the column, channel ch of table tab at row j and fractional column c.
static func _texel_lerp(tab: PackedFloat32Array, j: int, c: float, ch: int) -> float:
	var cc := clampf(c, 0.0, float(N_COLS - 1))
	var i0 := mini(int(floor(cc)), N_COLS - 2)
	var f := cc - float(i0)
	var base := j * N_COLS
	return tab[(base + i0) * 2 + ch] * (1.0 - f) + tab[(base + i0 + 1) * 2 + ch] * f


## Catmull-Rom across rows of a per-row value v(j). Beyond the first and last rows the ghost
## point is the linear extrapolation 2 p1 - p2 (not a repeated row, which flattens the end
## intervals: 5e-4 rad near r = 2 in the AC-5 probe).
static func _rows_cr(r: float, v: Callable) -> float:
	var fy := row_coordinate(r)
	var j1 := mini(int(floor(fy)), N_ROWS - 2)
	var t := fy - float(j1)
	var p1: float = v.call(j1)
	var p2: float = v.call(j1 + 1)
	var p0: float = v.call(j1 - 1) if j1 > 0 else 2.0 * p1 - p2
	var p3: float = v.call(j1 + 2) if j1 + 2 < N_ROWS else 2.0 * p2 - p1
	return catmull_rom(p0, p1, p2, p3, t)


## Fractional column of x at radius r: columns span [x_min, x_max(r)] in every row, so the
## column fraction is what a texture coordinate holds; the shadow edge and the antipode fall on
## the first and last columns of every row.
static func fwd_column(r: float, x: float) -> float:
	return (x - _x_min) / (row_x_max(r) - _x_min) * float(N_COLS - 1)


## Regular part R from lens_fwd at the observer's fractional column, Catmull-Rom across rows at
## that same column (a texture fetch at u = column / (N - 1)). Within a column interval the weight
## is linear in cot(psi/2), not in x: in the weak field delta = (1 + cos psi)/b is exactly
## proportional to cot(psi/2) (from 2/psi near the hole to (pi - psi)/2 at the antipode), so the
## weight is exact there. An x-linear weight leaves up to dx/2 = 0.8 % relative error near the
## antipode and a psi-linear one 6e-5 at b = 100 (AC-5, AC-8 measured); near the shadow edge,
## where R is flat, any of the three changes R by under 1e-3 |R1 - R0|.
static func regular_part(r: float, x: float, ch: int = 0) -> float:
	var c := clampf(fwd_column(r, x), 0.0, float(N_COLS - 1))
	var i0 := mini(int(floor(c)), N_COLS - 2)
	var a := shadow_angle(r)
	var xm := row_x_max(r)
	var dx := (xm - _x_min) / float(N_COLS - 1)
	var psi0 := a + a * exp(_x_min + dx * float(i0))
	var psi1 := PI if i0 + 1 == N_COLS - 1 else a + a * exp(_x_min + dx * float(i0 + 1))
	var psi := minf(a + a * exp(_x_min + dx * c), PI)
	var k0 := 1.0 / tan(psi0 * 0.5)
	var k1 := 1.0 / tan(psi1 * 0.5)
	var cp := float(i0) + clampf((1.0 / tan(psi * 0.5) - k0) / (k1 - k0), 0.0, 1.0)
	return _rows_cr(r, func(j: int) -> float: return _texel_lerp(_fwd, j, cp, ch))


## Deflection delta(psi) seen by a static observer at r from the table plus the analytic
## singular part -ln tanh((psi - alpha_sh)/alpha_sh); first order beyond r = 1e6. NaN when
## the ray is captured (psi <= alpha_sh). Below the first column the regular part is clamped
## and the singular term carries the divergence exactly.
static func deflection(r: float, psi: float) -> float:
	if r > R_WEAK:
		return weak_deflection_finite(r, psi)
	var a := shadow_angle(r)
	var dpsi := psi - a
	if not (dpsi > 0.0):
		return NAN
	var t := dpsi / a
	var x := log(t)
	return regular_part(r, x) - log(tanh(t))


## d delta / dx (the G channel; mip selection), same interpolation.
static func deflection_slope(r: float, psi: float) -> float:
	var a := shadow_angle(r)
	return regular_part(r, log((psi - a) / a), 1)


## Image angle psi_k, magnification mu_k and dpsi/dF ("slope") of a source at angle beta from h (order 0: F = beta,
## order 1: F = -beta). From lens_inv up to r = 1e6, beyond by bisection of the first-order form.
static func image(r: float, beta: float, order: int) -> Dictionary:
	var f := beta if order == 0 else -beta
	var psi: float
	var slope: float
	if r > R_WEAK:
		var lo := shadow_angle(r)
		var hi := PI
		for i in 64:
			var mid := 0.5 * (lo + hi)
			if mid - weak_deflection_finite(r, mid) < f:
				lo = mid
			else:
				hi = mid
		psi = 0.5 * (lo + hi)
		var d := 1e-6 * minf(psi, PI - psi)
		slope = 2.0 * d / ((psi + d - weak_deflection_finite(r, psi + d)) - (psi - d - weak_deflection_finite(r, psi - d)))
	else:
		var c := (f + PI) / (2.0 * PI) * float(N_COLS - 1)
		psi = shadow_angle(r) + _rows_cr(r, func(j: int) -> float: return _texel_lerp(_inv, j, c, 0))
		slope = _rows_cr(r, func(j: int) -> float: return _texel_lerp(_inv, j, c, 1))
	var sf := absf(sin(f))
	var mu := INF if sf == 0.0 else (sin(psi) / sf) * absf(slope)
	return {"psi": psi, "mu": mu, "order": order, "slope": slope}


# ---------------------------------------------------------------- directions

## Unit vector perpendicular to h in the plane of h and n (any perpendicular when n is on the axis).
static func _perp(n: Vector3, h: Vector3) -> Vector3:
	var p := n - h * n.dot(h)
	if p.length() < 1e-7:
		p = h.cross(Vector3.UP if absf(h.y) < 0.9 else Vector3.RIGHT)
	return p.normalized()


## Angle between unit vectors, atan2 form (accurate near 0 and pi).
static func angle(a: Vector3, b: Vector3) -> float:
	return atan2(a.cross(b).length(), a.dot(b))


## The per-pixel map: a ray seen along n_static (static frame) comes from n_inf at infinity,
## n_inf = cos(psi - delta) h + sin(psi - delta) e_perp. Holds for any delta (windings too).
static func lens_direction(n_static: Vector3, h: Vector3, r: float) -> Dictionary:
	var psi := angle(n_static, h)
	if not escapes(r, psi):
		return {"captured": true, "n_inf": Vector3.ZERO}
	var f := psi - deflection(r, psi)
	var e := _perp(n_static, h)
	return {"captured": false, "n_inf": (h * cos(f) + e * sin(f)).normalized()}


## The inverse map for a star at n_src: its order-0 and order-1 images, each
## {dir_static, mu, order}. Order 0 lies on the source's side of h, order 1 on the far side.
static func star_images(n_src: Vector3, h: Vector3, r: float) -> Array:
	var beta := angle(n_src, h)
	var e := _perp(n_src, h)
	var out := []
	for order in [0, 1]:
		var im := image(r, beta, order)
		var side := e if order == 0 else -e
		out.append({"dir_static": (h * cos(im["psi"]) + side * sin(im["psi"])).normalized(), "mu": im["mu"], "order": order})
	return out


## The full per-pixel pipeline (design M3.5): ship-frame view n' -> static frame (inverse
## aberration by the ship's velocity relative to the local static observer, bh and b) ->
## capture test -> lens -> n_inf, with D = D_g D_SR (D_g = static blueshift).
static func compose(n_ship_view: Vector3, h: Vector3, r: float, bh: Vector3, b: float) -> Dictionary:
	var n_s := Relativity.deaberrate(n_ship_view, bh, b) if b > 0.0 else n_ship_view
	var d_sr := Relativity.doppler_apparent(n_ship_view, bh, b) if b > 0.0 else 1.0
	var ld := lens_direction(n_s, h, r)
	return {"captured": ld["captured"], "n_inf": ld["n_inf"], "n_static": n_s, "D": static_blueshift(r) * d_sr}


# ---------------------------------------------------------------- GPU hand-off (M3.5)

## The table's first column, x = ln 1e-8 (lens_fwd header).
static func x_min() -> float:
	return _x_min


## A float64 angle as a float32 pair [hi, lo], hi = f32(a), lo = f32(a - hi): the shader forms
## (theta - hi) - lo, which keeps psi - alpha_sh to ~1e-7 rad at the shadow edge (plan review N-2;
## Godot has no float64 uniforms). hi + lo reconstructs a to ~1e-15 relative.
static func hi_lo(a: float) -> PackedFloat64Array:
	var hi := PackedFloat32Array([a])[0]
	var lo := PackedFloat32Array([a - hi])[0]
	return PackedFloat64Array([hi, lo])


## Tangential stretch sin psi / |sin F| of the order-k image of a source at beta (the ring-star
## test: above RING_STRETCH the star leaves the splat path, design M3.5).
const RING_STRETCH := 8.0


static func image_stretch(r: float, beta: float, order: int) -> float:
	var f := beta if order == 0 else -beta
	var sf := absf(sin(f))
	return INF if sf == 0.0 else sin(image(r, beta, order)["psi"]) / sf


## The ring-star cones at r: [beta_near, beta_far]. A star at beta < beta_near (either order near
## the Einstein ring) or beta > pi - beta_far (the order-1 image of a star astern, at the photon
## ring) has an image stretched over RING_STRETCH. Stretch > 8 needs |sin F| < 1/8, so both lie
## inside asin(1/8) = 7.18 deg; each is found by 50 bisections of the monotone stretch.
static func ring_cones(r: float) -> PackedFloat64Array:
	var cap := asin(1.0 / RING_STRETCH)
	var out := PackedFloat64Array()
	for far in [false, true]:
		var best := 0.0
		for order in ([1] if far else [0, 1]):
			var lo := 0.0
			var hi := cap
			for i in 50:
				var mid := 0.5 * (lo + hi)
				var beta: float = PI - mid if far else mid
				if image_stretch(r, beta, order) > RING_STRETCH:
					lo = mid
				else:
					hi = mid
			best = maxf(best, lo)
		out.append(best)
	return out


## Seen flux of an image over the star's rest flux at the ship (the starfield shader's
## band_ratio): mu Y(D T)/Y(T) / D_SR^2 with D = D_g D_SR. With mu = 1 and D_g = 1 it is
## Relativity.point_flux_ratio(T, D_SR) exactly (M3.5b CPU test).
static func image_flux_ratio(mu: float, t_kelvin: float, d_g: float, d_sr: float) -> float:
	return mu * Relativity.surface_brightness_ratio(t_kelvin, d_g * d_sr) / (d_sr * d_sr)
