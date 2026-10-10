extends SceneTree
## R1-ISM-DUST I5: the dust-flash CPU reference (interior/dust_flash.gd) against the package's
## values, every lookup finite over its range (AC15), and the glitter sampler's mirrors of the
## sim's stateless stream and the package's Poisson draw. Headless:
##   godot --headless --path . --script tests/test_dust_flash.gd      (make dust-flash-test)
## The GPU half (G-ISM-1..4) is tools/ism_golden.gd (make golden).

## tools/ism_dust_ref.py --emit-relativity (= sunholo/relativity 0.12.0 dust_test.ail): a 5 um
## grain (3,300 kg/m^3) at 0.999c, r_s 0.5 m, tau 0.2 s, eps 1e-10, f_in 0.5:
## [t s, T K, E W/m^2, L cd/m^2].
const KE5 := 3318048.4379902543
const AG := [[0.0, 4393.268808506808, 0.0010561676206489823, 0.022493611688749904],
	[0.1, 3877.0461157287746, 0.0006405980437193497, 0.010325915137666883],
	[0.4, 2664.6522287185694, 0.00014293674408586936, 0.0005245991708946924]]
## celestial ism_test.ail poissonDraw rows [mean, u, v, k] (oracle).
const POISSON := [[0.0, 0.1, 0.2, 0], [0.5, 0.97, 0.3, 2], [4.0, 0.1, 0.2, 2], [4.0, 0.5, 0.5, 4], [4.0, 0.97, 0.3, 8],
	[29.9, 0.1, 0.2, 23], [29.9, 0.97, 0.3, 41], [30.0, 0.1, 0.2, 31], [30.0, 0.5, 0.5, 24], [1000.0, 0.1, 0.2, 1004], [1000.0, 0.97, 0.3, 974]]

var failures := 0
var passes := 0


func check(name: String, ok: bool, detail := "") -> void:
	if ok:
		passes += 1
		print("  ok    %s" % name)
	else:
		failures += 1
		print("  FAIL  %s %s" % [name, detail])


func rel(a: float, b: float, tol: float) -> bool:
	return absf(a - b) <= tol * absf(b)


func _init() -> void:
	_afterglow()
	_finite()
	_stream()
	_glitter()
	_live()
	_overlap_masks()
	print("dust-flash: %d passed, %d failures" % [passes, failures])
	quit(1 if failures > 0 else 0)


func _overlap_masks() -> void:
	var flashes := PackedVector4Array()
	flashes.resize(64)
	flashes[0] = Vector4(0, 0, 1, 1)
	var close := DustFlash.wall_dir(0.009, 0)
	var far := DustFlash.wall_dir(0.011, 0)
	flashes[31] = Vector4(close.x, close.y, close.z, 1)
	flashes[32] = Vector4(far.x, far.y, far.z, 1)
	flashes[63] = flashes[0]
	var masks := DustFlash.overlap_masks(flashes, 64, 100.0, 0.5)
	check("spot masks retain nearby and coincident caps across bit31/63", (masks[0][0] & (1 << 31)) != 0 and (masks[1][0] & (1 << 31)) != 0)
	check("spot masks reject physically disjoint caps", (masks[1][0] & 1) == 0)
	check("spot masks are symmetric and preserve self", (masks[0][31] & 1) != 0 and (masks[0][63] & 1) != 0 and (masks[1][63] & (1 << 31)) != 0)


func _afterglow() -> void:
	for r: Array in AG:
		var t: float = r[0]
		check("G-AG T at t = %.1f s: %.1f K" % [t, r[1]], rel(DustFlash.temperature(KE5, 0.5, 0.2, t), r[1], 1e-12))
		check("G-AG E at t = %.1f s" % t, rel(DustFlash.emittance(KE5, 1e-10, 0.5, 0.5, 0.2, t), r[2], 1e-12))
		# ForwardGlow.efficacy is the exact package efficacy (its CPU mirror, tested in test_interior)
		check("G-AG L at t = %.1f s: %s cd/m^2" % [t, String.num_scientific(r[3])], rel(DustFlash.luminance(KE5, 1e-10, 0.5, 0.5, 0.2, t), r[3], 1e-6))
	# eps f_in KE = E(0) tau pi r_s^2 (the total light)
	check("G-AG total light E(0) tau pi r_s^2 = eps f_in KE", rel(DustFlash.emittance(KE5, 1e-10, 0.5, 0.5, 0.2, 0.0) * 0.2 * PI * 0.25, 1e-10 * 0.5 * KE5, 1e-12))
	check("no light before the impact, none with no energy, NaN stays NaN",
		DustFlash.temperature(KE5, 0.5, 0.2, -0.1) == 0.0 and DustFlash.emittance(KE5, 1e-10, 0.5, 0.5, 0.2, -0.1) == 0.0
		and DustFlash.temperature(0.0, 0.5, 0.2, 0.0) == 0.0 and is_nan(DustFlash.temperature(NAN, 0.5, 0.2, 0.0)) and is_nan(DustFlash.emittance(KE5, 1e-10, 0.5, 0.5, 0.2, NAN)))
	var d := DustFlash.wall_dir(0.6, 0.0)
	check("wall_dir: (0.6, 0) on the projected disc is the unit normal (0.6, 0, 0.8)", d.is_equal_approx(Vector3(0.6, 0.0, 0.8)) and is_equal_approx(d.length(), 1.0))


## AC15: every lookup the flash uses is finite over its whole range: the afterglow up to 1e7 K
## (a grain of 1e-11 kg at gamma 1e6 is ~4e6 K), the colour lookup, and the samplers at u = 0, 1.
func _finite() -> void:
	var ok := true
	var worst_t := 0.0
	var ke := 1e-6
	while ke <= 1e22:
		var t := DustFlash.temperature(ke, 0.5, 0.2, 0.0)
		var l := DustFlash.luminance(ke, 1e-10, 0.5, 0.5, 0.2, 0.0)
		worst_t = maxf(worst_t, t)
		ok = ok and is_finite(t) and is_finite(l) and l >= 0.0
		ke *= 3.0
	check("AC15: afterglow T and L finite for KE 1e-6 .. 1e22 J (T up to %s K)" % String.num_scientific(worst_t), ok and worst_t >= 1e7)
	var lut_ok := true
	var t2 := 300.0
	while t2 <= 1.0e7:
		var c := ForwardGlow.colour_lut(t2)
		lut_ok = lut_ok and is_finite(c.x) and is_finite(c.y) and is_finite(c.z) and is_finite(ForwardGlow.efficacy_lut(t2))
		t2 *= 1.1
	check("AC15: colour and efficacy lookups finite over 300 K .. 1e7 K", lut_ok and is_finite(ForwardGlow.efficacy_lut(1.0e9)))
	check("AC15: the tail sampler at u = 0 and u = 1 gives a_lo and a_hi",
		is_equal_approx(DustFlash.radius_at(1.3e-6, 2.8e-6, 3.1, 0.0), 1.3e-6) and rel(DustFlash.radius_at(1.3e-6, 2.8e-6, 3.1, 1.0), 2.8e-6, 1e-12))
	check("AC15: the Poisson draw at u = 1 (normal branch) and NaN means stays finite",
		DustFlash.poisson(60.0, 1.0, 0.0) > 60 and DustFlash.poisson(60.0, 1.0, 0.0) < 200 and DustFlash.poisson(NAN, 0.5, 0.5) == 0)


## The stream mirror: SplitMix64 seeded 0 starts 0xE220A8397B1DCDAF (Vigna's reference), and the
## Poisson mirror reproduces the package's rows.
func _stream() -> void:
	check("splitmix64(0, 0) = 0xE220A8397B1DCDAF (sim/rng.ail's algorithm)", DustFlash.splitmix64(0, 0) == -2152535657050944081)
	check("u53 in [0, 1)", DustFlash.u53(-1) < 1.0 and DustFlash.u53(0) == 0.0)
	var ok := true
	for r: Array in POISSON:
		ok = ok and DustFlash.poisson(r[0], r[1], r[2]) == int(r[3])
	check("poisson mirrors celestial.ism.poissonDraw on 11 oracle rows", ok)


func _glitter() -> void:
	var g := {"rate": 600.0, "a_lo_um": 1.3, "a_hi_um": 2.8, "q": 3.1, "seed": 424242}
	var a := DustFlash.glitter_events(g, 0.05, 707.1, 64)
	var b := DustFlash.glitter_events(g, 0.05, 707.1, 64)
	var same := a.size() == b.size()
	for i in a.size():
		same = same and a[i].x == b[i].x and a[i].a == b[i].a and a[i].t == b[i].t
	check("glitter: the same seed gives the same flashes (%d)" % a.size(), same and a.size() > 10)
	var inside := true
	for e: Dictionary in a:
		inside = inside and e.x * e.x + e.y * e.y <= 1.0 and e.a >= 1.3e-6 and e.a <= 2.8e-6 and e.t >= 0.0 and e.t < 0.05 and e.ke > 0.0
	check("glitter flashes lie on the disc, in the radius range and the window", inside)
	var n := DustFlash.poisson(600.0 * 0.05, DustFlash.u53(DustFlash.splitmix64(424242, 0)), DustFlash.u53(DustFlash.splitmix64(424242, 1)))
	check("glitter count is the Poisson draw of rate x window on slots 0-1 (%d)" % n, n == a.size())
	check("no glitter at a zero rate", DustFlash.glitter_events({"rate": 0.0, "seed": 1}, 0.05, 707.1, 64).is_empty())


func _live() -> void:
	var df := DustFlash.new()
	var world := {"ship": {"gamma": 22.4, "ism": {"impacts": [{"a_um": 5.0, "ke_j": KE5, "x": 0.1, "y": 0.0, "t_s": 0.01, "medium": "LIC"},
		{"a_um": 3.0, "ke_j": KE5 / 4.6, "x": -0.2, "y": 0.3, "t_s": 0.02, "medium": "LIC"}],
		"dust": {"window_s": 0.05}, "glitter": {"rate": 0.0}}}}
	var n := df.ingest(world, 10.0)
	var at := df.live(10.03)
	check("ingest takes the sim's impacts; live() orders by emittance", n == 2 and at.size() == 2 and at[0].e >= at[1].e)
	check("a flash not yet born is not drawn", df.live(10.015).size() == 1)
	check("flashes expire after 6 tau", df.live(10.02 + 6.0 * 0.2 + 0.01).is_empty() and df.flashes.is_empty())
