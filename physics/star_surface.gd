class_name StarSurface
extends RefCounted
## R2-STAR-SURFACES SS2 (design_docs/planned/r2/star-surfaces.md §D2, §D5): the CPU mirror of a
## resolved star's surface as planets/planet.gdshader draws it. The shader mirrors this file; the
## numbers (limb-darkening law, cell size, temperature contrast, lifetimes, spots) come from the
## sim's protocol-2.13 `surface` record, computed by sunholo/celestial stellar. Nothing here invents
## a stellar number; the only choices are the pattern (seeded, labelled "chosen") and the gate.
##
## The surface is a map of local temperature T(x) = Teff (1 + delta(x)); each element is a blackbody
## at T(x), seen at D T(x) (relativity-spec §2), and the map is normalised so the disc's light is the
## uniform disc's (RS-24). A layer contributes only where its features resolve on screen: below the
## gate's lower edge its amplitude is exactly zero, so an unresolved star is today's disc bit for bit.
##
## Precision (gate 5): the pattern's epoch and cross-fade weight are reduced from t_emit in float64
## here; the shader receives a uint epoch salt and a [0, 1) weight, never a large time.

## Gate edges in pixels: a convection cell (size at disc centre x mu) and a spot (radius).
const GRAN_LO := 1.2
const GRAN_HI := 4.0
const SPOT_LO := 0.6
const SPOT_HI := 2.0
## The raw granulation shape's mean and standard deviation over random points (tests/test_star_surface.gd
## measures them from 40,000 points and requires these to 2 %): delta = sigma_T (shape - MEAN) / STD.
const SHAPE_MEAN := 0.5176
const SHAPE_STD := 0.3616
const M32 := 0xFFFFFFFF
## The runtime quadrature size (n^2 pi / 4 lattice points; ~1 s for a giant in a worker thread).
const NORM_GRID := 192


## The quadratic limb-darkening law I(mu)/I(1) = 1 - a (1 - mu) - b (1 - mu)^2, clamped at 0
## (sunholo/celestial stellar ldQuadratic). b = 0 is the linear law.
static func ld(a: float, b: float, mu: float) -> float:
	var s := 1.0 - mu
	return maxf(0.0, 1.0 - a * s - b * s * s)


## Its disc mean 1 - a/3 - b/6 (ldQuadraticMean).
static func ld_mean(a: float, b: float) -> float:
	return 1.0 - a / 3.0 - b / 6.0


## pcg3d (Jarzynski & Olano 2020), uint32 arithmetic; the shader's uvec3 version wraps the same way.
static func pcg3d(x: int, y: int, z: int) -> Array:
	var vx := (x & M32) * 1664525 + 1013904223 & M32
	var vy := (y & M32) * 1664525 + 1013904223 & M32
	var vz := (z & M32) * 1664525 + 1013904223 & M32
	vx = vx + vy * vz & M32
	vy = vy + vz * vx & M32
	vz = vz + vx * vy & M32
	vx ^= vx >> 16
	vy ^= vy >> 16
	vz ^= vz >> 16
	vx = vx + vy * vz & M32
	vy = vy + vz * vx & M32
	vz = vz + vx * vy & M32
	return [vx, vy, vz]


## A cell's feature point offset in [0, 1)^3 for cell (cx, cy, cz) and a salt.
static func hash01(cx: int, cy: int, cz: int, salt: int) -> Vector3:
	var h := pcg3d(cx + salt, cy + salt * 7, cz + salt * 13)
	return Vector3(float(h[0]), float(h[1]), float(h[2])) / 4294967296.0


## The salt's phase for the domain warp, in [0, 2 pi).
static func seed_phase(salt: int) -> float:
	return float(salt & 1023) * (TAU / 1024.0)


## (F1, F2): distances to the nearest two feature points (Worley 1996), 3x3x3 neighbourhood.
static func worley(p: Vector3, salt: int) -> Vector2:
	var ix := int(floorf(p.x))
	var iy := int(floorf(p.y))
	var iz := int(floorf(p.z))
	var f1 := 8.0
	var f2 := 8.0
	for k in range(-1, 2):
		for j in range(-1, 2):
			for i in range(-1, 2):
				var c := Vector3i(ix + i, iy + j, iz + k)
				var q := Vector3(c) + hash01(c.x, c.y, c.z, salt)
				var d := q.distance_to(p)
				if d < f1:
					f2 = f1
					f1 = d
				elif d < f2:
					f2 = d
	return Vector2(f1, f2)


## The raw granulation shape at p (cell coordinates): domain-warped Worley cells with bright, rounded
## centres and narrow dark lanes. Statistics: SHAPE_MEAN, SHAPE_STD.
static func shape(p: Vector3, salt: int) -> float:
	var s := seed_phase(salt)
	var w := p + 0.32 * Vector3(sin(p.y * 1.9 + s), sin(p.z * 1.9 + s), sin(p.x * 1.9 + s)) \
		+ 0.16 * Vector3(sin(p.z * 4.1 - s), sin(p.x * 4.1 - s), sin(p.y * 4.1 - s))
	var f := worley(w, salt)
	var lane := smoothstep(0.02, 0.22, f.y - f.x)
	var body := exp(-1.6 * f.x * f.x)
	return lane * (0.5 + 0.5 * body)


## Cells across the stellar diameter.
static func cells_across(p: Dictionary) -> float:
	return 2.0 * float(p.radius_km) / float(p.cell_km)


## The granulation gate at foreshortening mu: 0 below GRAN_LO px, 1 above GRAN_HI px.
static func gran_gate(p: Dictionary, mu: float) -> float:
	var cell_px := 2.0 * float(p.px_per_radius) / cells_across(p) * mu
	return smoothstep(GRAN_LO, GRAN_HI, cell_px)


## A spot's gate from its radius on screen.
static func spot_gate(p: Dictionary, sp: Dictionary) -> float:
	return smoothstep(SPOT_LO, SPOT_HI, float(sp.radius_rad) * float(p.px_per_radius))


static func any_resolved(p: Dictionary) -> bool:
	if gran_gate(p, 1.0) > 0.0:
		return true
	for sp: Dictionary in p.spots:
		if spot_gate(p, sp) > 0.0:
			return true
	return false


## delta T / T of the granulation at star-frame unit normal b, before the gate: a cross-fade of the
## patterns of two epochs (salt0 -> salt1, weight w), renormalised to unit rms.
static func gran_delta(p: Dictionary, b: Vector3) -> float:
	var q := b * (cells_across(p) * 0.5)
	var w := float(p.w)
	var g0 := (shape(q, int(p.salt0)) - SHAPE_MEAN) / SHAPE_STD
	var g1 := (shape(q, int(p.salt1)) - SHAPE_MEAN) / SHAPE_STD if w > 0.0 else 0.0
	return float(p.sigma_t) * ((1.0 - w) * g0 + w * g1) / sqrt((1.0 - w) * (1.0 - w) + w * w)


## The local temperature (K) at star-frame unit normal b, foreshortening mu.
static func temperature(b: Vector3, mu: float, p: Dictionary) -> float:
	var teff := float(p.teff)
	var gg := gran_gate(p, mu)
	var delta := 0.0
	if gg > 0.0:
		delta = gg * gran_delta(p, b) * sqrt(mu)
	var spot_mix := 0.0
	var spot_t := teff
	var fsig := float(p.get("facula_sigma_t", 0.0))
	var sharp: bool = p.get("sharp", false)
	for sp: Dictionary in p.spots:
		var vis := spot_gate(p, sp)
		if vis <= 0.0:
			continue
		var r := float(sp.radius_rad)
		var a := acos(clampf(b.dot(sp.dir), -1.0, 1.0))
		var pen := (1.0 if a < r else 0.0) if sharp else 1.0 - smoothstep(0.85 * r, r, a)
		var umb := pen if sharp else 1.0 - smoothstep(0.35 * r, 0.45 * r, a)
		if fsig > 0.0:
			delta += vis * fsig * (1.0 - smoothstep(r, 3.0 * r, a)) * (1.0 - pen) * pow(1.0 - mu, 1.5)
		if pen * vis > spot_mix:
			spot_mix = pen * vis
			spot_t = lerpf(float(sp.penumbra_k), float(sp.umbra_k), umb)
	if delta == 0.0 and spot_mix == 0.0:
		return teff
	return lerpf(teff * (1.0 + delta), spot_t, spot_mix)


## The normaliser N (RS-24 at beta = 0) and the peak factor: quadrature over the disc as seen
## from view (star-frame unit vector toward the observer), orthographic. N = sum LD Yr / sum LD with
## Yr = Y(T)/Y(Teff) from the blackbody LUT the shader samples; peak = max Yr / N.
static func normaliser(p: Dictionary, view: Vector3, n: int) -> Dictionary:
	if not any_resolved(p):
		return {"n": 1.0, "peak": 1.0}
	var v := view.normalized()
	var e1 := (Vector3(0, 0, 1) if absf(v.z) < 0.9 else Vector3(1, 0, 0)).cross(v).normalized()
	var e2 := v.cross(e1)
	var a := float(p.ld_a)
	var bq := float(p.ld_b)
	var ly0 := Blackbody.lut_log10_y(float(p.teff))
	var s_ld := 0.0
	var s_ly := 0.0
	var ymax := 0.0
	# a Fibonacci (golden-angle) lattice on the projected disc: area-uniform, no grid axes to alias
	# with the cells; n^2 pi / 4 points, as many as an n x n grid has inside the disc
	var count := int(float(n * n) * PI / 4.0)
	var golden := PI * (3.0 - sqrt(5.0))
	for k in count:
		var rr := sqrt((k + 0.5) / count)
		var th := k * golden
		var x := rr * cos(th)
		var y := rr * sin(th)
		var mu := sqrt(maxf(0.0, 1.0 - rr * rr))
		var bn := x * e1 + y * e2 + mu * v
		var l := ld(a, bq, mu)
		var t := temperature(bn, mu, p)
		var yr := 1.0 if t == float(p.teff) else pow(10.0, Blackbody.lut_log10_y(t) - ly0)
		s_ld += l
		s_ly += l * yr
		ymax = maxf(ymax, yr)
	var nn := s_ly / s_ld
	return {"n": nn, "peak": ymax / nn}


## The pattern's epoch (int) and cross-fade weight in [0, 1), reduced in float64 (gate 5).
static func phases(t_emit_s: float, lifetime_s: float) -> Dictionary:
	var x := t_emit_s / lifetime_s
	var e := floorf(x)
	return {"epoch": int(e), "w": x - e}


## The uint32 salt of a star's pattern in one epoch.
static func epoch_salt(salt: int, epoch: int) -> int:
	return int(pcg3d(salt & M32, epoch & M32, 0x9E3779B9)[0])


## An element's unit-luminance colour at T, seen at Doppler factor d (the LUT the shader samples).
static func element_rgb(t: float, d: float) -> Vector3:
	return Blackbody.lut_rgb(t * d)


## The star frame's columns in world: x a prime meridian, z the pole. Planets.body_basis takes the
## meridian from NCP x pole, which is rounding noise when the pole is the NCP itself (every destination
## star's and alpha Cen's pole here); this one falls back to galactic x below 1e-6 and works in float64
## until the final unit vectors.
static func basis_of(pole_gal: Dictionary) -> Basis:
	var p := [float(pole_gal["x"]), float(pole_gal["y"]), float(pole_gal["z"])]
	var lp := sqrt(p[0] * p[0] + p[1] * p[1] + p[2] * p[2])
	p = [p[0] / lp, p[1] / lp, p[2] / lp]
	var n: Array = Planets.NCP_GAL
	var q := [n[1] * p[2] - n[2] * p[1], n[2] * p[0] - n[0] * p[2], n[0] * p[1] - n[1] * p[0]]
	var lq := sqrt(q[0] * q[0] + q[1] * q[1] + q[2] * q[2])
	if lq < 1e-6:
		q = [0.0, -p[2], p[1]] # (1, 0, 0) x p
		lq = sqrt(q[1] * q[1] + q[2] * q[2])
	q = [q[0] / lq, q[1] / lq, q[2] / lq]
	var y := [p[1] * q[2] - p[2] * q[1], p[2] * q[0] - p[0] * q[2], p[0] * q[1] - p[1] * q[0]]
	var gw := func(g: Array) -> Vector3: return SkyFrame.to_world(Vector3(g[0], g[1], g[2]))
	return Basis(gw.call(q), gw.call(y), gw.call(p))


## The surface record's spots as star-frame unit vectors.
static func spots_of(surface: Dictionary) -> Array:
	var out := []
	for s: Dictionary in surface.get("spots", []):
		var lat := deg_to_rad(float(s.lat_deg))
		var lon := deg_to_rad(float(s.lon_deg))
		out.append({"dir": Vector3(cos(lat) * cos(lon), cos(lat) * sin(lon), sin(lat)), "radius_rad": float(s.radius_rad), "umbra_k": float(s.umbra_k), "penumbra_k": float(s.penumbra_k)})
	return out


## The parameter dictionary the functions above take, from the protocol's surface record.
static func params_of(surface: Dictionary, radius_km: float, px_per_radius: float) -> Dictionary:
	var ph: Dictionary = phases(float(surface.t_emit_s), maxf(1.0, float(surface.lifetime_s)))
	var salt := int(surface.salt)
	return {"teff": float(surface.teff_k), "ld_a": float(surface.ld.a), "ld_b": float(surface.ld.b), "px_per_radius": px_per_radius,
		"cell_km": float(surface.cell_km), "radius_km": radius_km, "sigma_t": float(surface.sigma_t), "facula_sigma_t": float(surface.facula_sigma_t),
		"spots": spots_of(surface), "salt0": epoch_salt(salt, ph.epoch), "salt1": epoch_salt(salt, ph.epoch + 1), "w": ph.w}


## The shader's uniforms for a star with a surface record. The Sun keeps today's linear law and path
## (ld_quad false; design §D2); a star with nothing resolved draws today's path (surf_on false). basis:
## the star frame's columns in world; view: unit vector from the star toward the observer, world.
static func uniforms(surface: Dictionary, id: String, radius_km: float, px_per_radius: float, basis: Basis, view: Vector3) -> Dictionary:
	var p := params_of(surface, radius_km, px_per_radius)
	var spots := PackedVector4Array()
	var temps := PackedVector2Array()
	for sp: Dictionary in p.spots:
		if spots.size() >= 12:
			break
		spots.append(Vector4(sp.dir.x, sp.dir.y, sp.dir.z, sp.radius_rad))
		temps.append(Vector2(sp.umbra_k, sp.penumbra_k))
	var n_spots := spots.size()
	while spots.size() < 12:
		spots.append(Vector4.ZERO)
		temps.append(Vector2.ZERO)
	return {"surf_on": any_resolved(p), "ld_quad": id != "sun", "ld_a": p.ld_a, "ld_b": p.ld_b, "cells_across": cells_across(p),
		"sigma_t": p.sigma_t, "facula_sigma_t": p.facula_sigma_t, "px_per_radius": px_per_radius, "spot_count": n_spots, "spots": spots, "spot_temps": temps,
		"salt0": p.salt0, "salt1": p.salt1, "fade_w": p.w, "teff": p.teff, "params": p, "view_star": basis.transposed() * view}
