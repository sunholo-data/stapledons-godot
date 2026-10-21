extends SceneTree
## R2-STAR-SURFACES SS2 (design star-surfaces.md §D2, §D5; AC3, AC5, AC6, AC7, AC8): the CPU mirror of
## a resolved star's surface (physics/star_surface.gd) and SystemView's use of it. Headless.
## Expected values are closed forms, the package's numbers (sim/data, sunholo/celestial stellar) or
## Blackbody's exact CPU path, never the mirror's own output.
var failures := 0


func check(name: String, ok: bool, detail := "") -> void:
	if ok:
		print("  ok    %s" % name)
	else:
		failures += 1
		print("  FAIL  %s %s" % [name, detail])


func near(a: float, b: float, tol: float) -> bool:
	return absf(a - b) <= tol


func _initialize() -> void:
	print("star-surface test (R2-STAR-SURFACES SS2)")
	_laws()
	_hash_and_shape()
	_gate()
	_flux()
	_spot_oracle()
	_colour()
	_phases()
	_fader()
	_uniforms()
	_basis()
	print("star-surface: %s (%d failures)" % ["OK" if failures == 0 else "FAIL", failures])
	quit(1 if failures > 0 else 0)


## The quadratic law and its mean (sunholo/celestial stellar), and the Sun's linear law kept.
func _laws() -> void:
	check("ld(0.4650, 0.2565, 1) = 1", StarSurface.ld(0.4650, 0.2565, 1.0) == 1.0)
	check("ld(0.4650, 0.2565, 0.3) by hand", near(StarSurface.ld(0.4650, 0.2565, 0.3), 1.0 - 0.4650 * 0.7 - 0.2565 * 0.49, 1e-15))
	check("ld clamps at 0 (PHOENIX 2,000 K: 1 - 1.6811 - (-0.6783) < 0)", StarSurface.ld(1.6811, -0.6783, 0.0) == 0.0)
	check("ld_mean = 1 - a/3 - b/6", near(StarSurface.ld_mean(0.4650, 0.2565), 1.0 - 0.4650 / 3.0 - 0.2565 / 6.0, 1e-15))
	check("linear b = 0 is the Sun's law exactly: ld(0.6, 0, mu) == 1 - 0.6 (1 - mu)", StarSurface.ld(0.6, 0.0, 0.37) == 1.0 - 0.6 * (1.0 - 0.37))


## pcg3d is exact uint32 arithmetic (the shader's uvec3 wraps the same way); the granulation shape's
## mean and standard deviation constants (StarSurface.SHAPE_MEAN, SHAPE_STD) are what 40,000 random
## points measure, to 2 %.
func _hash_and_shape() -> void:
	var h: Array = StarSurface.pcg3d(1, 2, 3)
	check("pcg3d(1, 2, 3) is three uint32", h.size() == 3 and h[0] >= 0 and h[0] < 4294967296 and h[1] >= 0 and h[2] < 4294967296)
	check("pcg3d is deterministic and sensitive", StarSurface.pcg3d(1, 2, 3) == h and StarSurface.pcg3d(1, 2, 4) != h)
	var neg: Array = StarSurface.pcg3d(-1, -7, 0)
	check("negative cell indices wrap to uint32 as the shader's uvec3(ivec3) does", neg[0] >= 0 and neg[0] < 4294967296 and neg == StarSurface.pcg3d(4294967295, 4294967289, 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var s := 0.0
	var s2 := 0.0
	var n := 40000
	for i in n:
		var p := Vector3(rng.randf_range(-50.0, 50.0), rng.randf_range(-50.0, 50.0), rng.randf_range(-50.0, 50.0))
		var v := StarSurface.shape(p, 12345)
		s += v
		s2 += v * v
	var mean := s / n
	var sd := sqrt(maxf(0.0, s2 / n - mean * mean))
	check("granulation shape mean %.4f = SHAPE_MEAN %.4f (2 %%)" % [mean, StarSurface.SHAPE_MEAN], near(mean, StarSurface.SHAPE_MEAN, 0.02 * StarSurface.SHAPE_MEAN))
	check("granulation shape std %.4f = SHAPE_STD %.4f (2 %%)" % [sd, StarSurface.SHAPE_STD], near(sd, StarSurface.SHAPE_STD, 0.02 * StarSurface.SHAPE_STD))


## The resolution gate: below 1.2 px a cell contributes exactly nothing, below 0.6 px a spot does;
## a star with nothing resolved is drawn by today's path (surf_on false).
func _gate() -> void:
	var sun := _sun_params(4.95) # the Sun from home: 9.9 px across
	check("Sun from 1 AU: nothing resolves (surf_on false)", not StarSurface.any_resolved(sun))
	check("Sun from 1 AU: temperature map is exactly Teff everywhere", StarSurface.temperature(Vector3(0, 0, 1), 1.0, sun) == 5772.0 and StarSurface.temperature(Vector3(0.6, 0.0, 0.8), 0.8, sun) == 5772.0)
	var acen := _acen_params(91.3) # alpha Cen A at its stop: 183 px across
	check("alpha Cen A: granulation gated off (cells 0.15 px), granulation amplitude exactly 0", StarSurface.gran_gate(acen, 1.0) == 0.0)
	var ald := _ald_params(503.0) # Aldebaran at its stop: 1,006 px across
	check("Aldebaran: cells ~30 px, granulation fully on at the centre", StarSurface.gran_gate(ald, 1.0) == 1.0 and StarSurface.any_resolved(ald))
	check("Aldebaran: the gate falls toward the limb (foreshortening)", StarSurface.gran_gate(ald, 0.02) < 1.0)


## RS-24 at beta = 0: the normaliser makes the mapped disc's mean radiance the uniform disc's. The
## runtime quadrature (NORM_GRID 192) agrees with one twice as fine (384) to 1e-3, and the normalised mean is 1 to 1e-12 by
## construction; the views are fixed seeds (tests/fixtures/star_surface/views.json).
func _flux() -> void:
	var views: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/star_surface/views.json"))
	for star: Dictionary in [{"name": "Aldebaran", "p": _ald_params(503.0)}, {"name": "TRAPPIST-1", "p": _t1_params(28.6)}, {"name": "alpha Cen A", "p": _acen_params(91.3)}]:
		for v: Array in views:
			var view := Vector3(v[0], v[1], v[2]).normalized()
			var a: Dictionary = StarSurface.normaliser(star.p, view, StarSurface.NORM_GRID)
			var b: Dictionary = StarSurface.normaliser(star.p, view, 2 * StarSurface.NORM_GRID)
			check("%s view (%.2f, %.2f, %.2f): N 192 %.6f vs 384 %.6f (1e-3)" % [star.name, view.x, view.y, view.z, a.n, b.n], near(a.n, b.n, 1e-3) and a.n > 0.5 and a.n < 1.5)


## A single sharp-edged spot of radius r at the disc centre (granulation gated off: 1 m cells): the mapped disc's mean
## is 1 - (1 - Yr) F, F = the limb-darkened flux fraction inside the cap, closed form for the
## quadratic law: integral of 2 mu (1 - a(1 - mu) - b(1 - mu)^2) d mu from cos r to 1, over its mean.
func _spot_oracle() -> void:
	var a := 0.4650
	var b := 0.2565
	var r := 0.3
	var t_spot := 4100.0
	var p := {"teff": 5772.0, "ld_a": a, "ld_b": b, "px_per_radius": 400.0, "cell_km": 1.0e-3, "radius_km": 695700.0, "sigma_t": 0.0357, "facula_sigma_t": 0.0,
		"spots": [{"dir": Vector3(0, 0, 1), "radius_rad": r, "umbra_k": t_spot, "penumbra_k": t_spot}], "sharp": true, "salt0": 1, "salt1": 2, "w": 0.0}
	var got: Dictionary = StarSurface.normaliser(p, Vector3(0, 0, 1), 512)
	var mu0 := cos(r)
	var prim := func(m: float) -> float:
		# antiderivative of 2 m (1 - a (1 - m) - b (1 - m)^2)
		return m * m * (1.0 - a - b) + (2.0 / 3.0) * m * m * m * (a + 2.0 * b) - 0.5 * b * m * m * m * m
	var f: float = (prim.call(1.0) - prim.call(mu0)) / (prim.call(1.0) - prim.call(0.0))
	var yr := pow(10.0, Blackbody.lut_log10_y(t_spot) - Blackbody.lut_log10_y(5772.0))
	var want := 1.0 - (1.0 - yr) * f
	check("single sharp spot at disc centre: N %.6f = closed form %.6f (2e-4: a 512^2 quadrature of a hard edge)" % [got.n, want], near(got.n, want, 2e-4))


## Colour from temperature: an element's colour is the LUT's unit-luminance colour at T (at rest) and
## at D T (moving); against Blackbody's exact CPU colour, chromaticity within 0.002 (RS-5 method).
func _colour() -> void:
	for t: float in [4100.0, 2209.0, 3927.0]:
		var c := StarSurface.element_rgb(t, 1.0)
		var e := Blackbody.rgb_unit_luminance(t)
		check("spot colour at %.0f K (rest) = blackbody, chromaticity 0.002" % t, _chroma_near(c, e, 0.002))
	var d := sqrt(19.0)
	var cm := StarSurface.element_rgb(4100.0, d)
	check("spot colour seen ahead at 0.9c = blackbody at D T (%.0f K)" % (4100.0 * d), _chroma_near(cm, Blackbody.rgb_unit_luminance(4100.0 * d), 0.002))


func _chroma_near(a: Vector3, b: Vector3, tol: float) -> bool:
	var sa := a.x + a.y + a.z
	var sb := b.x + b.y + b.z
	return near(a.x / sa, b.x / sb, tol) and near(a.y / sa, b.y / sb, tol)


## The phase the shader gets is reduced in float64 on the CPU (gate 5): at t_e = 3e9 s (95 years) a
## 1 s step moves the cross-fade weight by exactly 1 / lifetime; float32 would move it by 0 or 256 s.
func _phases() -> void:
	var a: Dictionary = StarSurface.phases(3.0e9, 360.0)
	var b: Dictionary = StarSurface.phases(3.0e9 + 1.0, 360.0)
	check("epoch = floor(t_e / lifetime) as an int", a.epoch == int(floorf(3.0e9 / 360.0)) and a.epoch is int)
	check("1 s at t_e 3e9 s moves the weight by 1/360 (1e-9)", near(b.w - a.w, 1.0 / 360.0, 1e-9) or (b.epoch == a.epoch + 1))
	var f32 := float(PackedFloat32Array([3.0e9 + 1.0])[0]) - float(PackedFloat32Array([3.0e9])[0])
	check("(control) float32 cannot hold the step: %.0f s" % f32, f32 != 1.0)


## The Auto fader's peak includes the map's maximum, so the hottest cell stays at the target.
func _fader() -> void:
	var p := _ald_params(503.0)
	var nz: Dictionary = StarSurface.normaliser(p, Vector3(0, 0, 1), 64)
	check("peak factor >= 1 when cells are on (the hottest cell outshines the mean)", nz.peak > 1.0 and nz.peak < 2.0, "peak %.4f" % nz.peak)
	var sun: Dictionary = StarSurface.normaliser(_sun_params(4.95), Vector3(0, 0, 1), 64)
	check("nothing resolved: N 1 and peak 1 exactly", sun.n == 1.0 and sun.peak == 1.0)


## The uniforms SystemView passes: the Sun at home keeps today's path (surf_on false, linear law),
## Aldebaran gets the quadratic law, the map and the LUT.
func _uniforms() -> void:
	var sun_s := {"ld": {"a": 0.4650, "b": 0.2565}, "cell_km": 1276.5, "sigma_t": 0.0357, "lifetime_s": 360.0, "facula_sigma_t": 0.02, "spots": [], "t_emit_s": 1.0e8, "salt": 99, "teff_k": 5772.0}
	var u_sun: Dictionary = StarSurface.uniforms(sun_s, "sun", 695700.0, 4.95, Basis.IDENTITY, Vector3(0, 0, 1))
	check("Sun: surf_on false and ld_quad false (linear u 0.6 kept, bit-identical path)", u_sun.surf_on == false and u_sun.ld_quad == false)
	var ald_s := {"ld": {"a": 0.93, "b": -0.09}, "cell_km": 1.86e6, "sigma_t": 0.0357, "lifetime_s": 5.2e5, "facula_sigma_t": 0.0, "spots": [], "t_emit_s": 1.0e8, "salt": 7, "teff_k": 3927.0}
	var u_ald: Dictionary = StarSurface.uniforms(ald_s, "aldebaran", 31453988.4, 503.0, Basis.IDENTITY, Vector3(0, 0, 1))
	check("Aldebaran: surf_on, quadratic law (0.93, -0.09), cells ~33.8 across", u_ald.surf_on and u_ald.ld_quad and near(u_ald.ld_a, 0.93, 1e-12) and near(u_ald.cells_across, 2.0 * 31453988.4 / 1.86e6, 1e-9))


## The star frame is orthonormal for a pole on the NCP (every destination star's and alpha Cen's pole):
## Planets.body_basis's NCP x pole is rounding noise there (the control: not orthonormal), which put
## every spot in the wrong place on TRAPPIST-1 in the first SS2 capture.
func _basis() -> void:
	var n: Array = Planets.NCP_GAL
	var ncp := {"x": n[0], "y": n[1], "z": n[2]}
	var b := StarSurface.basis_of(ncp)
	var ortho := func(m: Basis) -> bool:
		return near(m.x.length(), 1.0, 1e-5) and near(m.y.length(), 1.0, 1e-5) and near(m.z.length(), 1.0, 1e-5) and near(m.x.dot(m.y), 0.0, 1e-5) and near(m.x.dot(m.z), 0.0, 1e-5) and near(m.determinant(), 1.0, 1e-5)
	check("star frame with the pole on the NCP is orthonormal, right-handed", ortho.call(b))
	var w := SkyFrame.to_world(Vector3(n[0], n[1], n[2]))
	check("its z column is the pole (world)", b.z.distance_to(w) < 1e-5)
	check("(control) Planets.body_basis at the NCP is not orthonormal", not ortho.call(Planets.body_basis(ncp, 0.0)))
	var other := StarSurface.basis_of({"x": 0.3, "y": 0.2, "z": 0.93})
	check("an ordinary pole: orthonormal too", ortho.call(other))


func _sun_params(px_r: float) -> Dictionary:
	return {"teff": 5772.0, "ld_a": 0.6, "ld_b": 0.0, "px_per_radius": px_r, "cell_km": 1276.5, "radius_km": 695700.0, "sigma_t": 0.0357, "facula_sigma_t": 0.02,
		"spots": [{"dir": Vector3(0.0, 0.25, 0.97).normalized(), "radius_rad": 0.025, "umbra_k": 4100.0, "penumbra_k": 5400.0}], "salt0": 11, "salt1": 12, "w": 0.4}


func _acen_params(px_r: float) -> Dictionary:
	var p := _sun_params(px_r)
	p.radius_km = 851119.0
	p.teff = 5795.0
	p.ld_a = 0.46
	p.ld_b = 0.26
	return p


func _ald_params(px_r: float) -> Dictionary:
	return {"teff": 3927.0, "ld_a": 0.9353, "ld_b": -0.0971, "px_per_radius": px_r, "cell_km": 1.86e6, "radius_km": 31453988.4, "sigma_t": 0.0357, "facula_sigma_t": 0.0,
		"spots": [], "salt0": 21, "salt1": 22, "w": 0.25}


func _t1_params(px_r: float) -> Dictionary:
	return {"teff": 2566.0, "ld_a": 1.12, "ld_b": -0.116, "px_per_radius": px_r, "cell_km": 2.0, "radius_km": 82927.0, "sigma_t": 0.0357, "facula_sigma_t": 0.02,
		"spots": [{"dir": Vector3(0.3, 0.2, 0.93).normalized(), "radius_rad": 0.2, "umbra_k": 2207.0, "penumbra_k": 2386.0},
			{"dir": Vector3(-0.5, 0.1, 0.86).normalized(), "radius_rad": 0.12, "umbra_k": 2207.0, "penumbra_k": 2386.0}], "salt0": 31, "salt1": 32, "w": 0.0}
