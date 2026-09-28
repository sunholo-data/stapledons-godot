extends SceneTree
## Physics reference tests. Run:  godot --headless --path . --script tests/test_physics.gd
## Exits non-zero on any failure.

var failures := 0
var passes := 0


func check(name: String, got: float, want: float, tol: float) -> void:
	if absf(got - want) <= tol:
		passes += 1
		print("  ok    %-64s %.9f" % [name, got])
	else:
		failures += 1
		print("  FAIL  %-64s got %.12f want %.12f (tol %s)" % [name, got, want, tol])


func angle_deg(a: Vector3, b: Vector3) -> float:
	return rad_to_deg(acos(clampf(a.dot(b), -1.0, 1.0)))

func test_off_axis_cpu_spec_values() -> void:
	var headings := [Vector3.RIGHT, Vector3.LEFT, Vector3.UP, Vector3.DOWN,
		Vector3(1, 1, -1).normalized()]
	for heading: Vector3 in headings:
		var side: Vector3 = heading.cross(Vector3.FORWARD).normalized()
		if side.length() < 0.5:
			side = heading.cross(Vector3.UP).normalized()
		check("off-axis transverse aberration %s" % heading, angle_deg(Relativity.aberrate(side, heading, 0.9), heading), rad_to_deg(acos(0.9)), 1e-4)
		check("off-axis forward Doppler %s" % heading, Relativity.doppler(heading, heading, 0.9), sqrt(19.0), 1e-6)
		check("off-axis transverse Doppler %s" % heading, Relativity.doppler(side, heading, 0.9), 1.0 / sqrt(0.19), 1e-6)


func _init() -> void:
	var fwd := Vector3(0, 0, -1)
	var side := Vector3(1, 0, 0)
	var back := -fwd
	test_off_axis_cpu_spec_values()

	print("Aberration (sources crowd toward the direction of motion)")
	check("90 deg source at 0.9c appears at acos(0.9) = 25.842 deg", angle_deg(Relativity.aberrate(side, fwd, 0.9), fwd), rad_to_deg(acos(0.9)), 1e-4)
	check("90 deg source at 0.5c appears at 60 deg", angle_deg(Relativity.aberrate(side, fwd, 0.5), fwd), 60.0, 1e-4)
	check("source dead ahead stays ahead", angle_deg(Relativity.aberrate(fwd, fwd, 0.9), fwd), 0.0, 1e-6)
	check("source dead astern stays astern", angle_deg(Relativity.aberrate(back, fwd, 0.9), fwd), 180.0, 1e-6)
	check("aberrated direction is unit length", Relativity.aberrate(Vector3(0.3, 0.4, -0.866).normalized(), fwd, 0.97).length(), 1.0, 1e-6)
	var n := Vector3(0.2, -0.5, 0.3).normalized()
	check("deaberrate inverts aberrate", Relativity.deaberrate(Relativity.aberrate(n, fwd, 0.99), fwd, 0.99).distance_to(n), 0.0, 1e-6)
	# Half the sky (theta <= 90) is compressed into a cone of half-angle acos(beta).
	check("cos(theta') = (cos theta + b)/(1 + b cos theta) at 120 deg, 0.8c", cos(deg_to_rad(angle_deg(Relativity.aberrate(Vector3(sin(deg_to_rad(120.0)), 0, -cos(deg_to_rad(120.0))), fwd, 0.8), fwd))), (cos(deg_to_rad(120.0)) + 0.8) / (1.0 + 0.8 * cos(deg_to_rad(120.0))), 1e-6)

	print("Doppler factor")
	check("ahead at 0.9c: sqrt(1.9/0.1) = 4.3589", Relativity.doppler(fwd, fwd, 0.9), sqrt(19.0), 1e-9)
	check("astern at 0.9c: sqrt(0.1/1.9) = 0.22942", Relativity.doppler(back, fwd, 0.9), sqrt(1.0 / 19.0), 1e-9)
	check("transverse (galaxy frame 90 deg) at 0.9c: gamma = 2.2942", Relativity.doppler(side, fwd, 0.9), 1.0 / sqrt(0.19), 1e-9)
	check("apparent-frame form agrees (float32 direction)", Relativity.doppler_apparent(Relativity.aberrate(n, fwd, 0.9), fwd, 0.9), Relativity.doppler(n, fwd, 0.9), 1e-6)
	check("source appearing at 90 deg is redshifted by 1/gamma", Relativity.doppler_apparent(side, fwd, 0.9), sqrt(0.19), 1e-9)

	print("Blackbody colour (CIE 1931, Wyman et al. fit)")
	# Planckian locus reference chromaticities (CIE 15:2004 / Wyszecki & Stiles).
	var c2856 := Blackbody.chromaticity(2856.0) # CIE illuminant A
	check("2856 K x = 0.4476 (illuminant A)", c2856.x, 0.4476, 0.002)
	check("2856 K y = 0.4074 (illuminant A)", c2856.y, 0.4074, 0.002)
	var c6500 := Blackbody.chromaticity(6500.0)
	check("6500 K Planckian x = 0.3135", c6500.x, 0.3135, 0.002)
	check("6500 K Planckian y = 0.3236", c6500.y, 0.3236, 0.002)
	var c10k := Blackbody.chromaticity(10000.0)
	check("10000 K Planckian x = 0.2807", c10k.x, 0.2807, 0.002)
	var rgb3000 := Blackbody.rgb_unit_luminance(3000.0)
	check("3000 K renders orange (r > g > b)", 1.0 if rgb3000.x > rgb3000.y and rgb3000.y > rgb3000.z else 0.0, 1.0, 0.0)
	var rgb20k := Blackbody.rgb_unit_luminance(20000.0)
	check("20000 K renders blue (b > g > r)", 1.0 if rgb20k.z > rgb20k.y and rgb20k.y > rgb20k.x else 0.0, 1.0, 0.0)

	print("Blackbody lookup table (sampled by the starfield shader)")
	var lut := Blackbody.build_lut().get_image()
	var finite := 1.0
	var monotonic := 1.0
	var prev := -INF
	for i in Blackbody.LUT_SIZE:
		var px := lut.get_pixel(i, 0)
		for ch in [px.r, px.g, px.b, px.a]:
			if is_nan(ch) or is_inf(ch): finite = 0.0
		if px.a <= prev: monotonic = 0.0
		prev = px.a
	check("every LUT texel is finite (no NaN/inf colours)", finite, 1.0, 0.0)
	check("log luminance rises monotonically with temperature", monotonic, 1.0, 0.0)

	print("Relativistic beaming of a point source")
	check("D = 1 leaves flux unchanged", Relativity.point_flux_ratio(5700.0, 1.0), 1.0, 1e-12)
	# Bolometric: integral of B(DT) = D^4 integral B(T); / D^2 solid angle -> D^2.
	var bol := func(t: float) -> float:
		var s := 0.0
		var lam := 50.0
		while lam < 200000.0:
			s += Blackbody.planck(lam, t) * lam * 0.01
			lam *= 1.01
		return s
	check("bolometric point flux scales as D^2 (D = 3)", bol.call(5700.0 * 3.0) / bol.call(5700.0) / 9.0, 9.0, 0.02)
	check("red dwarf (3300 K) ahead at 0.9c brightens in V by > D^2", 1.0 if Relativity.point_flux_ratio(3300.0, sqrt(19.0)) > 19.0 else 0.0, 1.0, 0.0)
	check("Sun-like star astern at 0.9c fades by > 100x", 1.0 if Relativity.point_flux_ratio(5700.0, sqrt(1.0 / 19.0)) < 0.01 else 0.0, 1.0, 0.0)

	print("Constant proper acceleration (sim cross-check reference)")
	var a := 1.032295275553596 # 1 g in c/yr (sunholo/relativity standardGravity)
	check("beta after 1 ship-year at 1 g = tanh(a)", tanh(a), 0.774827262642545, 1e-12)
	check("Earth years after 1 ship-year = sinh(a)/a", sinh(a) / a, 1.187312401712, 1e-11)

	print("\n%d passed, %d failed" % [passes, failures])
	quit(1 if failures > 0 else 0)
