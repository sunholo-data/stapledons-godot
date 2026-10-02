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


## data/starmap/stars.json galactic directions against the literature.
## Each row: catalogue id, name, SIMBAD ICRS J2000 RA / Dec, and the IAU galactic
## (l, b) of that position computed with astropy 7
## (SkyCoord(ra, dec, frame="icrs").galactic), an implementation independent of
## this repo. Until 2026-10-02 every longitude was mirrored, l_cat = 245.86 - l
## (process_stars.sh added atan2(...) to l_NCP instead of subtracting it), while
## b and |r| were right. x, y, z are rounded to 0.01 ly, so the budget is 0.1 deg
## plus atan(0.005 sqrt(3) / d) (0.12 deg at Proxima, < 0.03 deg past 20 ly).
const GALACTIC_CHECK := [
	["Gl 551", "Proxima Cen", "14 29 42.946", "-62 40 46.16", 313.940, -1.927],
	["Gl 559", "alpha Cen A", "14 39 36.494", "-60 50 02.37", 315.734, -0.680],
	["Gl 699", "Barnard's Star", "17 57 48.498", "+04 41 36.11", 31.009, 14.063],
	["Gl 406", "Wolf 359", "10 56 28.86", "+07 00 52.8", 244.054, 56.120],
	["Gl 411", "Lalande 21185", "11 03 20.19", "+35 58 11.6", 185.118, 65.432],
	["Gl 244", "Sirius", "06 45 08.917", "-16 42 58.02", 227.230, -8.890],
	["Gl 144", "epsilon Eri", "03 32 55.845", "-09 27 29.73", 195.845, -48.051],
	["Gl 820", "61 Cyg A", "21 06 53.94", "+38 44 57.9", 82.320, -5.818],
	["Gl 71", "tau Cet", "01 44 04.083", "-15 56 14.93", 173.101, -73.440],
	["Gl 280", "Procyon", "07 39 18.119", "+05 13 29.96", 213.702, 13.019],
	["Gl 768", "Altair", "19 50 47.00", "+08 52 06.0", 47.744, -8.909],
	["Gl 881", "Fomalhaut", "22 57 39.05", "-29 37 20.1", 20.488, -64.910],
	["Gl 721", "Vega", "18 36 56.336", "+38 47 01.28", 67.448, 19.237],
	["Gl 286", "Pollux", "07 45 18.95", "+28 01 34.3", 192.229, 23.406],
	["Gl 541", "Arcturus", "14 15 39.67", "+19 10 56.7", 15.050, 69.111],
	["Gl 194", "Capella", "05 16 41.36", "+45 59 52.8", 162.588, 4.566],
]

func test_catalogue_galactic_directions() -> void:
	print("Catalogue galactic directions (stars.json vs SIMBAD J2000 -> IAU galactic)")
	var stars: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/starmap/stars.json"))["stars"]
	for row in GALACTIC_CHECK:
		var star: Dictionary = {}
		for s in stars:
			if s["id"] == row[0]:
				star = s # components share the system's position
				break
		if star.is_empty():
			check("%s (%s) is in stars.json" % [row[1], row[0]], 0.0, 1.0, 0.0)
			continue
		# float64 scalars throughout (no Vector3)
		var x: float = star["x"]
		var y: float = star["y"]
		var z: float = star["z"]
		var r := sqrt(x * x + y * y + z * z)
		var l := deg_to_rad(float(row[4]))
		var b := deg_to_rad(float(row[5]))
		var cos_sep := (x * cos(b) * cos(l) + y * cos(b) * sin(l) + z * sin(b)) / r
		var sep := rad_to_deg(acos(clampf(cos_sep, -1.0, 1.0)))
		var tol := 0.1 + rad_to_deg(atan(0.005 * sqrt(3.0) / r))
		var l_cat := fposmod(rad_to_deg(atan2(y, x)), 360.0)
		check("%s (%s): l %.2f b %+.2f, catalogue l %.2f -> sep deg" % [row[1], row[0], row[4], row[5], l_cat], sep, 0.0, tol)


func _init() -> void:
	var fwd := Vector3(0, 0, -1)
	var side := Vector3(1, 0, 0)
	var back := -fwd
	test_off_axis_cpu_spec_values()
	test_catalogue_galactic_directions()

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

	print("Relativistic surface brightness of an extended source (sky background, M1.4)")
	check("D = 1 leaves surface brightness unchanged", Relativity.surface_brightness_ratio(5700.0, 1.0), 1.0, 1e-12)
	# Spec §2: radiance I' = D^4 I bolometrically; in a band it is the blackbody at D T.
	check("bolometric surface brightness scales as D^4 (D = 3)", bol.call(5700.0 * 3.0) / bol.call(5700.0), 81.0, 0.2)
	check("surface brightness = point flux ratio x D^2 (no solid-angle shrink)", Relativity.surface_brightness_ratio(4600.0, 2.5), Relativity.point_flux_ratio(4600.0, 2.5) * 6.25, 1e-9)
	check("diffuse 4600 K light astern at 0.9c fades below 1% in V", 1.0 if Relativity.surface_brightness_ratio(4600.0, sqrt(1.0 / 19.0)) < 0.01 else 0.0, 1.0, 0.0)

	print("Sky model (M1.4b texture contract, mirrored by sky/background.gdshader)")
	check("galactic centre (world -Z) samples the panorama centre u", SkyModel.equirect_uv(Vector3(0, 0, -1)).x, 0.5, 1e-9)
	check("galactic centre samples the panorama centre v", SkyModel.equirect_uv(Vector3(0, 0, -1)).y, 0.5, 1e-9)
	check("l = 90 deg (world +X) sits a quarter in from the left (l grows leftward)", SkyModel.equirect_uv(Vector3(1, 0, 0)).x, 0.25, 1e-9)
	check("l = 270 deg (world -X) sits at u = 0.75", SkyModel.equirect_uv(Vector3(-1, 0, 0)).x, 0.75, 1e-9)
	check("north galactic pole (world +Y) is the top row", SkyModel.equirect_uv(Vector3(0, 1, 0)).y, 0.0, 1e-9)
	check("b = -30 deg sits at v = 2/3", SkyModel.equirect_uv(Vector3(0, -0.5, -sqrt(0.75))).y, 2.0 / 3.0, 1e-6)
	var probe := Vector3(0.3, -0.4, 0.5).normalized()
	check("equirect_dir inverts equirect_uv", SkyModel.equirect_dir(SkyModel.equirect_uv(probe)).distance_to(probe), 0.0, 1e-6)
	check("T code 0 decodes to T_LO = 1500 K", SkyModel.decode_t(0), 1500.0, 1e-6)
	check("T code 255 decodes to T_HI = 30000 K", SkyModel.decode_t(255), 30000.0, 1e-6)
	check("T code round trip within 0.6% (4600 K)", SkyModel.decode_t(SkyModel.encode_t(4600.0)) / 4600.0, 1.0, 0.006)
	var report: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/sky/sky_model_report.json"))
	check("T code range matches sim/tools/sky_model.ail (report), low end", report["t_code_range_k"][0], SkyModel.T_LO, 0.0)
	check("T code range matches sim/tools/sky_model.ail (report), high end", report["t_code_range_k"][1], SkyModel.T_HI, 0.0)
	check("committed model fit: luminance-weighted median dxy <= 0.02 (else escalate)", 1.0 if report["luminance_weighted_median_dxy"] <= 0.02 else 0.0, 1.0, 0.0)
	var tint_t := 4600.0
	var lin := Blackbody.rgb_unit_luminance(tint_t) * 0.2
	check("a Planck-coloured texel has unit tint (rest frame reproduces the photo)", SkyModel.tint(lin, tint_t).distance_to(Vector3.ONE), 0.0, 1e-6)
	check("at D = 1 the sky colour equals the photo's linear colour", SkyModel.radiance(lin, tint_t, 1.0).distance_to(lin), 0.0, 1e-6)
	var seen := SkyModel.radiance(lin, tint_t, 3.0)
	var want := Blackbody.rgb_unit_luminance(tint_t * 3.0) * 0.2 * Relativity.surface_brightness_ratio(tint_t, 3.0)
	check("at D = 3 a Planck texel renders as rgb(D T) x Y x surface ratio", seen.distance_to(want) / want.length(), 0.0, 1e-6)

	print("Constant proper acceleration (sim cross-check reference)")
	var a := 1.032295275553596 # 1 g in c/yr (sunholo/relativity standardGravity)
	check("beta after 1 ship-year at 1 g = tanh(a)", tanh(a), 0.774827262642545, 1e-12)
	check("Earth years after 1 ship-year = sinh(a)/a", sinh(a) / a, 1.187312401712, 1e-11)

	print("\n%d passed, %d failed" % [passes, failures])
	quit(1 if failures > 0 else 0)
