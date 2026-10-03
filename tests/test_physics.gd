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


## AC4 (camera part, M1.6b): the spec §2 check values seen through the real
## free-look camera (the one main.gd flies), rolled and off-axis. The camera
## only rotates the view, so RS-1/RS-2 must come out as the same angle off the
## screen centre, at the pinhole radius f tan(theta'), turned on screen by the
## roll; RS-3/RS-4/RS-Q2 follow the camera's own view direction. Godot's
## unproject_position (float32 basis) must agree with the camera's float64
## CPU projection, which the golden uses as its reference.
func test_rolled_camera_cpu_spec_values(vp: SubViewport) -> void:
	print("Rolled and off-axis free-look camera (AC4 camera part)")
	var cam := FreeLookCamera.new()
	vp.add_child(cam)
	var size := Vector2(vp.size)
	var f := 0.5 * size.y / tan(deg_to_rad(cam.fov) * 0.5)
	var centre := size * 0.5
	for heading: Vector3 in [Vector3(0, 0, -1), Vector3(1, 1, -1).normalized(), Vector3.RIGHT]:
		for roll_deg: float in [0.0, 30.0, -115.0]:
			# look straight along the velocity, then roll about the view axis
			var yaw := atan2(-heading.x, -heading.z)
			var pitch := asin(clampf(heading.y, -1.0, 1.0))
			var roll := deg_to_rad(roll_deg)
			cam.look(yaw, pitch, roll)
			var tag := "heading %s roll %+.0f" % [heading, roll_deg]
			check("%s: camera looks along the velocity (angle deg)" % tag, cam.view_velocity_angle(heading), 0.0, 1e-4)
			check("%s: RS-3 Doppler of the view centre at 0.9c" % tag, Relativity.doppler_apparent(cam.view_dir(), heading, 0.9), sqrt(19.0), 1e-5)
			# a 90 deg source on the camera's own right-hand side at rest
			var right := cam.screen_right()
			var up := cam.screen_up()
			for row in [[0.9, 25.842], [0.5, 60.0]]:
				var app := Relativity.aberrate(right, heading, row[0])
				var p := cam.project(app, size)
				var r := p.distance_to(centre)
				check("%s: RS at %.1fc, 90 deg appears %.3f deg off centre" % [tag, row[0], row[1]], rad_to_deg(atan(r / f)), row[1], 2e-3)
				# rolled or not, it stays on the camera's horizontal (right of centre, same row)
				check("%s: %.1fc source stays on the screen's horizontal (px)" % [tag, row[0]], p.y - centre.y, 0.0, 1e-3)
				check("%s: %.1fc Godot unproject == CPU projection (px)" % [tag, row[0]], cam.unproject_position(app * 100.0).distance_to(p), 0.0, 2e-3)
			# RS-Q1: dead ahead lands on the centre whatever the roll; dead astern is behind the camera
			check("%s: RS-Q1 dead ahead projects to the centre (px)" % tag, cam.project(Relativity.aberrate(heading, heading, 0.9), size).distance_to(centre), 0.0, 1e-3)
			check("%s: RS-Q1 dead astern is behind the camera" % tag, 1.0 if cam.is_behind(Relativity.aberrate(-heading, heading, 0.9)) else 0.0, 1.0, 0.0)
			check("%s: screen up is a unit vector at 90 deg to the view" % tag, absf(up.dot(cam.view_dir())) + absf(up.length() - 1.0), 0.0, 1e-6)
	# Roll sense: positive roll turns the camera counter-clockwise about its view
	# axis, so the sky turns clockwise on screen. A star 20 deg to the right of
	# the unrolled view sits f tan 20 sin(roll) BELOW centre (screen y down).
	var star := Vector3(sin(deg_to_rad(20.0)), 0.0, -cos(deg_to_rad(20.0)))
	for roll_deg: float in [30.0, -50.0, 90.0]:
		cam.look(0.0, 0.0, deg_to_rad(roll_deg))
		var p := cam.project(star, size) - centre
		check("roll %+.0f: star at 20 deg right moves to x = f tan20 cos(roll) (px)" % roll_deg, p.x, f * tan(deg_to_rad(20.0)) * cos(deg_to_rad(roll_deg)), 1e-3)
		check("roll %+.0f: and y = f tan20 sin(roll), below centre for roll > 0 (px)" % roll_deg, p.y, f * tan(deg_to_rad(20.0)) * sin(deg_to_rad(roll_deg)), 1e-3)
		check("roll %+.0f: Godot unproject agrees (px)" % roll_deg, cam.unproject_position(star * 100.0).distance_to(p + centre), 0.0, 2e-3)
	# Off-axis (yawed + pitched + rolled) camera against Godot's own transform
	for o in [[70.0, -25.0, 0.0], [-120.0, 40.0, -65.0], [10.0, 80.0, 170.0]]:
		cam.look(deg_to_rad(o[0]), deg_to_rad(o[1]), deg_to_rad(o[2]))
		var fwd := -cam.global_transform.basis.z
		check("look %s: view_dir == Godot camera -Z" % [o], cam.view_dir().distance_to(fwd), 0.0, 1e-6)
		for k in 8:
			var d := (cam.view_dir() + 0.3 * cos(k * 0.785) * cam.screen_right() + 0.2 * sin(k * 0.785) * cam.screen_up()).normalized()
			check("look %s: probe %d Godot unproject == CPU projection (px)" % [o, k], cam.unproject_position(d * 100.0).distance_to(cam.project(d, size)), 0.0, 2e-3)
	# Astern view and a transverse view: Doppler of the view centre (RS-4, RS-Q2)
	cam.look(PI, 0.0, deg_to_rad(40.0))
	check("looking astern, rolled 40: RS-4 Doppler of view centre at 0.9c", Relativity.doppler_apparent(cam.view_dir(), Vector3(0, 0, -1), 0.9), sqrt(1.0 / 19.0), 1e-5)
	cam.look(-PI / 2, 0.0, deg_to_rad(-70.0))
	check("looking starboard, rolled -70: RS-Q2 view centre D = 1/gamma at 0.9c", Relativity.doppler_apparent(cam.view_dir(), Vector3(0, 0, -1), 0.9), sqrt(0.19), 1e-5)
	cam.queue_free()


## The HUD's view-to-velocity angle (M1.6b): float64, independent of roll,
## exact at 0 and 180 (atan2 form, no acos rounding near the poles).
func test_view_velocity_angle(vp: SubViewport) -> void:
	print("View-to-velocity angle (HUD)")
	var cam := FreeLookCamera.new()
	vp.add_child(cam)
	var fwd := Vector3(0, 0, -1)
	var rows := [
		["forward", 0.0, 0.0, 0.0, fwd, 0.0],
		["forward rolled 75", 0.0, 0.0, 75.0, fwd, 0.0],
		["starboard", -90.0, 0.0, 0.0, fwd, 90.0],
		["starboard rolled -30", -90.0, 0.0, -30.0, fwd, 90.0],
		["astern", 180.0, 0.0, 0.0, fwd, 180.0],
		["astern rolled 120", 180.0, 0.0, 120.0, fwd, 180.0],
		["up", 0.0, 90.0, 0.0, fwd, 90.0],
		["30 deg left, 40 up", 30.0, 40.0, 10.0, fwd, rad_to_deg(acos(cos(deg_to_rad(30.0)) * cos(deg_to_rad(40.0))))],
		["forward vs (1,1,-1)/sqrt3", 0.0, 0.0, 0.0, Vector3(1, 1, -1).normalized(), rad_to_deg(acos(1.0 / sqrt(3.0)))],
		["forward vs +X", 0.0, 0.0, 45.0, Vector3.RIGHT, 90.0],
		["0.5 deg off forward", 0.5, 0.0, 0.0, fwd, 0.5],
		["1e-4 deg off forward", 1e-4, 0.0, 0.0, fwd, 1e-4],
	]
	for r in rows:
		cam.look(deg_to_rad(r[1]), deg_to_rad(r[2]), deg_to_rad(r[3]))
		check("view-velocity angle, %s (deg)" % r[0], cam.view_velocity_angle(r[4]), r[5], 1e-5)
	cam.look(0.0, 0.0, 0.0)
	check("HUD line reads the angle", 1.0 if cam.hud_line(Vector3.RIGHT) == "view/v  90.0 deg  roll   +0.0 deg" else 0.0, 1.0, 0.0)
	cam.look(deg_to_rad(-30.0), 0.0, deg_to_rad(-20.0))
	check("HUD line reads the roll", 1.0 if cam.hud_line(fwd) == "view/v  30.0 deg  roll  -20.0 deg" else 0.0, 1.0, 0.0)
	cam.queue_free()


## data/starmap/stars.json galactic directions against the literature.
## Each row: catalogue id (M1.7: the map is the quick + bright tier rows, ids
## "Gaia DR3 n" / "CNS5:n" / "HIP n"), name, SIMBAD ICRS J2000 RA / Dec, and the
## IAU galactic (l, b) of that position computed with astropy 7
## (SkyCoord(ra, dec, frame="icrs").galactic), an implementation independent of
## this repo. The catalogue rows are float64 at their own epoch (mostly Gaia
## J2016.0; CNS5 rows filled from Hipparcos keep the CNS5 position), so the
## budget is 0.1 deg: the largest proper motion here, Barnard's Star, moves
## 0.046 deg between J2000 and J2016. Until 2026-10-02 every longitude was
## mirrored (l_cat = 245.86 - l); before M1.7 the rows were CNS3 at 0.01 ly.
const GALACTIC_CHECK := [
	["Gaia DR3 5853498713190525696", "Proxima Cen", "14 29 42.946", "-62 40 46.16", 313.940, -1.927],
	["CNS5:3627", "alpha Cen A", "14 39 36.494", "-60 50 02.37", 315.734, -0.680],
	["Gaia DR3 4472832130942575872", "Barnard's Star", "17 57 48.498", "+04 41 36.11", 31.009, 14.063],
	["Gaia DR3 3864972938605115520", "Wolf 359", "10 56 28.86", "+07 00 52.8", 244.054, 56.120],
	["Gaia DR3 762815470562110464", "Lalande 21185", "11 03 20.19", "+35 58 11.6", 185.118, 65.432],
	["CNS5:1676", "Sirius", "06 45 08.917", "-16 42 58.02", 227.230, -8.890],
	["Gaia DR3 5164707970261890560", "epsilon Eri", "03 32 55.845", "-09 27 29.73", 195.845, -48.051],
	["Gaia DR3 1872046609345556480", "61 Cyg A", "21 06 53.94", "+38 44 57.9", 82.320, -5.818],
	["Gaia DR3 2452378776434477184", "tau Cet", "01 44 04.083", "-15 56 14.93", 173.101, -73.440],
	["CNS5:1895", "Procyon", "07 39 18.119", "+05 13 29.96", 213.702, 13.019],
	["CNS5:4912", "Altair", "19 50 47.00", "+08 52 06.0", 47.744, -8.909],
	["CNS5:5665", "Fomalhaut", "22 57 39.05", "-29 37 20.1", 20.488, -64.910],
	["CNS5:4607", "Vega", "18 36 56.336", "+38 47 01.28", 67.448, 19.237],
	["CNS5:1912", "Pollux", "07 45 18.95", "+28 01 34.3", 192.229, 23.406],
	["CNS5:3517", "Arcturus", "14 15 39.67", "+19 10 56.7", 15.050, 69.111],
	["CNS5:1318", "Capella", "05 16 41.36", "+45 59 52.8", 162.588, 4.566],
]

func test_catalogue_galactic_directions() -> void:
	print("Catalogue galactic directions (stars.json vs SIMBAD J2000 -> IAU galactic)")
	var stars: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/starmap/stars.json"))["stars"]
	for row in GALACTIC_CHECK:
		var star: Dictionary = {}
		for s in stars:
			if s["id"] == row[0]:
				star = s
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
		var l_cat := fposmod(rad_to_deg(atan2(y, x)), 360.0)
		check("%s (%s): l %.2f b %+.2f, catalogue l %.2f -> sep deg" % [row[1], row[0], row[4], row[5], l_cat], sep, 0.0, 0.1)
		check("%s: stars.json dist_ly = |(x, y, z)| (float64)" % row[1], float(star["dist_ly"]), r, 1.0e-12)


## M1.3 (O-1): the colour LUT reaches 1e7 K at the old log-T step, its top
## texel is finite and equals the CPU value, and its top end agrees with the
## package (luminance ratio 1e7 K / 1e6 K from sunholo/relativity 0.5.1
## blackbody.luminance). The every-texel finite and monotonic loop is the
## "Blackbody lookup table" block in _init, which now spans the 1320 texels.
func test_lut_range() -> void:
	print("Blackbody LUT range (O-1, M1.3)")
	check("LUT_T_MAX >= 1e7 K", 1.0 if Blackbody.LUT_T_MAX >= 1.0e7 else 0.0, 1.0, 0.0)
	check("LUT_SIZE = 1320 (log-T step kept ~0.79%)", Blackbody.LUT_SIZE, 1320, 0.0)
	var step := (log(Blackbody.LUT_T_MAX) - log(Blackbody.LUT_T_MIN)) / Blackbody.LUT_SIZE
	check("log-T step per texel <= 0.0080", 1.0 if step <= 0.0080 else 0.0, 1.0, 0.0)
	check("package: Y(1e7 K) / Y(1e6 K) = 10.11998569367005", Blackbody.luminance(1.0e7) / Blackbody.luminance(1.0e6), 10.11998569367005, 1e-9)
	var img := Blackbody.build_lut().get_image()
	var top := img.get_pixel(Blackbody.LUT_SIZE - 1, 0)
	check("top texel log10 Y = CPU log10 Y at its temperature (finite)", top.a, log(Blackbody.luminance(exp(log(Blackbody.LUT_T_MIN) + (Blackbody.LUT_SIZE - 0.5) / Blackbody.LUT_SIZE * (log(Blackbody.LUT_T_MAX) - log(Blackbody.LUT_T_MIN))))) / log(10.0), 1e-4)
	check("2.682 MK (60 kK x D 44.7) maps inside the LUT (u < 1)", 1.0 if Blackbody.lut_u(60000.0 * 44.7) < 1.0 else 0.0, 1.0, 0.0)


## M1.3 brightness: splat energy = E_v x pointFluxRatio(T, D), with E_v from
## the package's illuminanceFromV mirrored in GDScript. Package values from
## sunholo/relativity 0.5.1 (photometry.illuminanceFromV, blackbody.pointFluxRatio).
func test_star_brightness() -> void:
	print("Star brightness proportional to E_v (M1.3)")
	check("package: illuminanceFromV(0) = 2.558585886905643e-6 lux", Relativity.illuminance_from_v(0.0) / 2.558585886905643e-6, 1.0, 1e-12)
	check("package: illuminanceFromV(-1.46) (Sirius) = 9.817479430199844e-6 lux", Relativity.illuminance_from_v(-1.46) / 9.817479430199844e-6, 1.0, 1e-12)
	check("5 magnitudes = 100x in E_v", Relativity.illuminance_from_v(0.0) / Relativity.illuminance_from_v(5.0), 100.0, 1e-9)
	check("package: pointFluxRatio(60 kK, 44.7) = 0.027970449496092183", Relativity.point_flux_ratio(60000.0, 44.7) / 0.027970449496092183, 1.0, 1e-9)
	check("package: pointFluxRatio(60 kK, 1/44.7) = 7.522327389995562e-6", Relativity.point_flux_ratio(60000.0, 1.0 / 44.7) / 7.522327389995562e-6, 1.0, 1e-9)
	check("package: pointFluxRatio(3300 K, sqrt 19) = 26.28143112310455", Relativity.point_flux_ratio(3300.0, sqrt(19.0)) / 26.28143112310455, 1.0, 1e-9)
	for d: float in [1.0 / 44.7, 0.3, 1.0, 4.3589, 44.7]:
		var e0 := Starfield.splat_energy(Relativity.illuminance_from_v(1.0), 5800.0, d)
		var e1 := Starfield.splat_energy(Relativity.illuminance_from_v(3.5), 5800.0, d)
		check("same T, D %.4f: splat energy ratio = E_v ratio (10^(2.5 x 0.4))" % d, e0 / e1, pow(10.0, 1.0), 1e-9)
	check("splat energy at D = 1 equals E_v", Starfield.splat_energy(3.0e-7, 4200.0, 1.0), 3.0e-7, 1e-18)
	# a real tier record through the loader: E_v in custom data, missing photometry skipped
	var rows := [[3.0, 4.0, 0.0, 5800.0, 2.0, 0.0], [1.0, 0.0, 0.0, 0.0, 99.0, 2.0], [0.0, 0.0, -10.0, 9000.0, 7.5, 5.0]]
	var cat := _tier_fixture(rows)
	var sf := Starfield.new()
	if cat == null:
		check("fixture tier loads", 0.0, 1.0, 0.0)
		return
	sf.append_catalogue(cat)
	check("missing-photometry row skipped (2 of 3 drawn)", sf.count, 2, 0.0)
	check("skipped_missing counts it", sf.skipped_missing, 1, 0.0)
	check("custom data: T_eff", sf.custom[0], 5800.0, 0.0)
	check("custom data: E_v = illuminanceFromV(2.0) lux (float32)", sf.custom[1] / Relativity.illuminance_from_v(2.0), 1.0, 1e-6)
	check("custom data: flags", sf.custom[6], 5.0, 0.0)
	check("galactic (3, 4, 0) -> world (4, 0, -3)", Vector3(sf.pos[0], sf.pos[1], sf.pos[2]).distance_to(Vector3(4, 0, -3)), 0.0, 0.0)
	check("custom data: |p|^2 = 25 ly^2", sf.custom[3], 25.0, 0.0)
	sf.set_ship_position(4.0 * 0.5, 0.0, -3.0 * 0.5)
	check("flux at the ship = E_v x |p|^2 / r^2 (halfway: 4x)", sf.flux_at_ship(0) / Relativity.illuminance_from_v(2.0), 4.0, 1e-6)
	sf.free()
	# only_flags: the HIP-filled rows of a tier (flag 8), nothing else
	var hipcat := _tier_fixture([[1.0, 2.0, 3.0, 9900.0, -1.44, 8.0], [2.0, 2.0, 2.0, 3000.0, 11.0, 0.0], [5.0, 0.0, 0.0, 0.0, 99.0, 2.0]])
	var sh := Starfield.new()
	sh.append_catalogue(hipcat, StarCatalogue.FLAG_HIP)
	check("only_flags = FLAG_HIP keeps just the HIP-filled row", sh.count, 1, 0.0)
	check("and it is the V -1.44 row", sh.custom[1] / Relativity.illuminance_from_v(-1.44), 1.0, 1e-6)
	sh.free()
	# the committed tiers: medium (GCNS) + bright + quick's HIP fill must draw Sirius
	# (Gl 244: SIMBAD l 227.230, b -8.890, 8.6 ly; GCNS has no Gaia photometry for it)
	var sm := Starfield.new()
	check("medium tier loads with bright + HIP fill", 1.0 if sm.load_tiers("medium") else 0.0, 1.0, 0.0)
	check("stacked tiers are medium, quick:hip, bright", 1.0 if sm.tiers == ["medium", "quick:hip", "bright"] else 0.0, 1.0, 0.0)
	var sl := deg_to_rad(227.230)
	var sb := deg_to_rad(-8.890)
	var sdir := [cos(sb) * sin(sl), sin(sb), -cos(sb) * cos(sl)] # galactic -> world
	var best := -1.0
	for k in sm.count:
		var px := sm.pos[3 * k]
		var py := sm.pos[3 * k + 1]
		var pz := sm.pos[3 * k + 2]
		var r := sqrt(px * px + py * py + pz * pz)
		if (px * sdir[0] + py * sdir[1] + pz * sdir[2]) / r > cos(deg_to_rad(0.2)):
			best = maxf(best, sm.custom[4 * k + 1])
	check("Sirius drawn within 0.2 deg of SIMBAD, E_v of V -1.44 (+-0.05 mag)", -2.5 * log(best / Relativity.illuminance_from_v(0.0)) / log(10.0) if best > 0.0 else 99.0, -1.44, 0.05)
	sm.free()


func _tier_fixture(rows: Array) -> StarCatalogue:
	var dir := "user://test_physics_tier"
	DirAccess.make_dir_recursive_absolute(dir)
	var b := PackedByteArray()
	b.resize(24 * rows.size())
	for r in rows.size():
		for f in 6:
			b.encode_float(24 * r + 4 * f, rows[r][f])
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(b)
	var meta := {"tier": "fixture", "count": rows.size(), "count_excluded": 0, "format_version": 1, "record_bytes": 24,
		"fields": ["x", "y", "z", "teff", "v", "flags"], "sha256": {"bin": ctx.finish().hex_encode()}}
	var f := FileAccess.open(dir + "/stars_fixture.bin", FileAccess.WRITE)
	f.store_buffer(b)
	f.close()
	f = FileAccess.open(dir + "/stars_fixture.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(meta))
	f.close()
	return StarCatalogue.load_tier("fixture", dir)


## M1.3 rebasing (gate 5): alpha Cen A (SIMBAD l 315.734, b -0.680, 4.37 ly)
## seen from the 1,000 AU stand-off, a little off the Sol line. The float64 CPU
## direction through the rebased coordinates must match the direct one within
## 1e-9 rad; the vertex shader's float32 hi/lo path (emulated op by op) within
## 1e-6 rad (a pixel is ~8.5e-4 rad); a single float32 position from Sol would
## be ~1e-5 rad off, so the hi/lo pair is what carries the precision.
func test_rebasing_precision() -> void:
	print("Rebasing precision at the 1,000 AU stand-off (M1.3, gate 5)")
	var l := deg_to_rad(315.734)
	var b := deg_to_rad(-0.680)
	var d := 4.37
	var g := [d * cos(b) * cos(l), d * cos(b) * sin(l), d * sin(b)]
	var star := [g[1], g[2], -g[0]] # galactic -> world, float64 scalars
	var au := 1.0 / 63241.07708426628 # ly
	var stand := 1000.0 * au
	# ship: 1,000 AU short of the star along the Sol line, then 300 AU sideways
	var u := [star[0] / d, star[1] / d, star[2] / d]
	var side := [u[2], 0.0, -u[0]]
	var sn := sqrt(side[0] * side[0] + side[2] * side[2])
	var ship := []
	for a in 3:
		ship.append(star[a] - u[a] * stand + side[a] / sn * 300.0 * au)
	var want := [star[0] - ship[0], star[1] - ship[1], star[2] - ship[2]]
	var wn := sqrt(want[0] ** 2 + want[1] ** 2 + want[2] ** 2)
	check("stand-off distance is ~1,044 AU (float64)", wn / au, sqrt(1000.0 ** 2 + 300.0 ** 2), 1e-6)
	for mode in [Starfield.Rebase.GPU, Starfield.Rebase.CPU]:
		var sf := Starfield.new()
		sf.rebase_mode = mode
		sf.set_custom_stars([{"pos": [9.0, -2.0, 30.0], "t": 5000.0, "flux": 1.0}, {"pos": star, "t": 5790.0, "flux": 1.0}])
		sf.multimesh = MultiMesh.new() # buffer only; no material in a headless test
		sf.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		sf.multimesh.use_custom_data = true
		sf._fill()
		# fly in from Sol in 0.4 ly steps so a CPU rebase lands near (not at) the ship
		for step in 12:
			var f := step / 11.0
			sf.set_ship_position(ship[0] * f + 0.003, ship[1] * f, ship[2] * f)
		sf.set_ship_position(ship[0], ship[1], ship[2])
		var tag := "GPU (origin Sol)" if mode == Starfield.Rebase.GPU else "CPU (origin %.4f ly from the ship)" % Starfield._dist(sf.origin, sf.ship)
		var cpu := sf.direction_to(1)
		check("%s: float64 rebased direction to alpha Cen A (rad)" % tag, _ang(cpu, want), 0.0, 1e-9)
		check("%s: vertex shader float32 hi/lo direction (rad)" % tag, _ang(sf.shader_rel(1), want), 0.0, 1e-6)
		if mode == Starfield.Rebase.CPU:
			check("CPU mode rebased at least once and the origin is within 0.01 ly", 1.0 if sf.rebases > 0 and Starfield._dist(sf.origin, sf.ship) <= Starfield.REBASE_LY else 0.0, 1.0, 0.0)
		sf.free()
	# what the hi/lo pair buys: float32 positions from Sol, no lo terms
	var naive := []
	for a in 3:
		naive.append(Starfield.f32(Starfield.f32(star[a]) - Starfield.f32(ship[a])))
	check("float32 positions from Sol alone miss by > 1e-6 rad (the test can tell)", 1.0 if _ang(naive, want) > 1e-6 else 0.0, 1.0, 0.0)


func _ang(a: Array, b: Array) -> float:
	var na := sqrt(a[0] * a[0] + a[1] * a[1] + a[2] * a[2])
	var nb := sqrt(b[0] * b[0] + b[1] * b[1] + b[2] * b[2])
	# atan2(|a x b|, a.b): exact near 0, unlike acos
	var cx: float = a[1] * b[2] - a[2] * b[1]
	var cy: float = a[2] * b[0] - a[0] * b[2]
	var cz: float = a[0] * b[1] - a[1] * b[0]
	return atan2(sqrt(cx * cx + cy * cy + cz * cz), (a[0] * b[0] + a[1] * b[1] + a[2] * b[2])) if na > 0.0 and nb > 0.0 else INF


## M1.5a scene units and exposure (F5). Package values from sunholo/relativity
## 0.5.1 (photometry.luminanceFromSurfaceMag, pointThresholdIlluminance,
## limitingMagnitude), printed by `ailang run` on the VM and the interpreter (identical).
func test_exposure_units() -> void:
	print("Photometric exposure: scene units (M1.5a)")
	var l22 := Relativity.luminance_from_surface_mag(22.0)
	check("package: luminanceFromSurfaceMag(22) = 1.725242969719464e-4 cd/m^2", l22 / 1.725242969719464e-4, 1.0, 1e-12)
	check("package: luminanceFromSurfaceMag(0) = 1.0886e5 cd/m^2 (doc value)", Relativity.luminance_from_surface_mag(0.0) / 1.0886e5, 1.0, 1e-4)
	check("package: pointThresholdIlluminance(L22) = 4.024468740009986e-9 lux", Relativity.point_threshold_illuminance(l22) / 4.024468740009986e-9, 1.0, 1e-12)
	check("package: pointThresholdIlluminance(2e-4) = 4.276147913741731e-9 lux", Relativity.point_threshold_illuminance(0.0002) / 4.276147913741731e-9, 1.0, 1e-12)
	check("package: pointThresholdIlluminance(1) = 6.19362769e-8 lux (bright branch)", Relativity.point_threshold_illuminance(1.0) / 6.19362769e-8, 1.0, 1e-8)
	check("package: pointThresholdIlluminance(0) = zeta 1.1495286872003704e-9 (dark cut-off)", Relativity.point_threshold_illuminance(0.0) / 1.1495286872003704e-9, 1.0, 1e-12)
	check("NaN background clamps before the branch (= dark cut-off)", Relativity.point_threshold_illuminance(NAN) / 1.1495286872003704e-9, 1.0, 1e-12)
	check("package: limitingMagnitude(L22, 2) = 6.25565361492508", Relativity.limiting_magnitude(l22, 2.0), 6.25565361492508, 1e-9)
	check("package: limitingMagnitude(L22, 1) = 7.00822860408503", Relativity.limiting_magnitude(l22, 1.0), 7.00822860408503, 1e-9)
	check("package doc: limitingMagnitude(2e-4, 1) = 6.942", Relativity.limiting_magnitude(0.0002, 1.0), 6.942, 5e-4)
	check("vFromIlluminance inverts illuminanceFromV", Relativity.v_from_illuminance(Relativity.illuminance_from_v(6.3)), 6.3, 1e-12)
	# D-25: the dark sky is the deep-space value at the galactic caps, 23.5 mag/arcsec^2 (package 0.5.2 values)
	var l235 := Relativity.luminance_from_surface_mag(23.5)
	check("package: luminanceFromSurfaceMag(23.5) = 4.33361440669562e-5 cd/m^2", l235 / 4.33361440669562e-05, 1.0, 1e-12)
	check("package: pointThresholdIlluminance(L23.5) = 2.228685011649177e-9 lux", Relativity.point_threshold_illuminance(l235) / 2.228685011649177e-09, 1.0, 1e-12)
	check("package: limitingMagnitude(L23.5, 2) = 6.897303279936935", Relativity.limiting_magnitude(l235, 2.0), 6.897303279936935, 1e-9)
	check("package: limitingMagnitude(L23.5, 1) = 7.6498782690968845", Relativity.limiting_magnitude(l235, 1.0), 7.6498782690968845, 1e-9)
	check("Exposure.DARK_SKY_MAG = 23.5 (D-25)", Exposure.DARK_SKY_MAG, 23.5, 0.0)
	check("Exposure dark sky = L(23.5 mag/arcsec^2)", Exposure.dark_sky_luminance(), l235, 0.0)
	check("Exposure.FIELD_FACTOR = 2 (Crumey typical)", Exposure.FIELD_FACTOR, 2.0, 0.0)
	check("threshold_lux = 2 x pointThresholdIlluminance(L(dark))", Exposure.threshold_lux() / (2.0 * Relativity.point_threshold_illuminance(l235)), 1.0, 1e-12)
	check("AC8 window = 6.6-7.4 (D-25: moved with the dark sky)", Exposure.AC8.distance_to(Vector2(6.6, 7.4)), 0.0, 1e-6)
	var vm := Relativity.limiting_magnitude(l235, Exposure.FIELD_FACTOR)
	check("model limit at the default field factor is inside AC8", 1.0 if vm >= Exposure.AC8.x and vm <= Exposure.AC8.y else 0.0, 1.0, 0.0)
	# camera: EV100 saturation-based mapping and the reflected-light meter
	check("L_white(EV 0) = 1.2 cd/m^2", Exposure.l_white(0.0), 1.2, 1e-12)
	check("one EV halves the sensitivity", Exposure.l_white(3.0) / Exposure.l_white(2.0), 2.0, 1e-12)
	check("meter: L_avg = 0.125 cd/m^2 gives EV 0 (K = 12.5)", Exposure.metered_ev(0.125), 0.0, 1e-12)
	check("meter maps L_avg to 1 / (1.2 x 8) = 0.104 linear", 0.125 / Exposure.l_white(Exposure.metered_ev(0.125)), 1.0 / 9.6, 1e-12)
	var sr := Exposure.centre_pixel_sr(70.0, 540.0)
	check("centre pixel of a 70 deg x 540 px pinhole = (2 tan 35 / 540)^2 sr", sr, pow(2.0 * tan(deg_to_rad(35.0)) / 540.0, 2.0), 1e-18)
	var e := Exposure.new()
	e.configure(70.0, 540.0)
	check("eye mode at the dark sky sits at EV_dark", e.ev, e.ev_dark(), 1e-12)
	var peak := Exposure.threshold_lux() * e.star_scale()
	var hi := Exposure.new()
	hi.configure(70.0, 1440.0)
	check("the threshold star (F = 2) peaks at the display floor at EV_dark (unclamped PSF, 1440 rows)", Exposure.threshold_lux() * hi.star_scale(), Exposure.DISPLAY_FLOOR, 1e-12)
	check("star scale: splat sum (peak x 2 pi sigma_px^2) x Omega_px = E k", peak * TAU * pow(e.psf_sigma_px(), 2.0) * sr / Exposure.threshold_lux() / e.k(), 1.0, 1e-12)
	e.update(1.0)
	check("eye light-adapts once the meter wants less sensitivity (L_avg 1 cd/m^2)", e.ev, Exposure.metered_ev(1.0), 1e-12)
	e.mode = Exposure.Mode.CAMERA
	e.update(l22)
	check("camera mode meters the dark sky (EV below EV_dark)", e.ev, Exposure.metered_ev(l22), 1e-12)
	e.set_fixed(true, l22)
	var locked := e.ev
	e.update(l22 / 50.0)
	check("fixed EV ignores the meter", e.ev, locked, 0.0)
	e.set_fixed(false, 0.0)
	e.bias = 1.5
	e.update(l22)
	check("bias aid adds EV", e.ev, Exposure.metered_ev(l22) + 1.5, 1e-12)
	check("bias aid is labelled on the HUD", 1.0 if e.hud_line().contains("aid: bias +1.5 EV") else 0.0, 1.0, 0.0)
	check("camera mode HUD says auto", 1.0 if e.hud_line().contains("auto") else 0.0, 1.0, 0.0)
	var pin := Exposure.new()
	pin.configure(70.0, 540.0)
	check("eye mode pinned at EV_dark: HUD says pinned, not auto", 1.0 if pin.hud_line().contains("pinned at EV_dark") and not pin.hud_line().contains("auto") else 0.0, 1.0, 0.0)
	pin.update(10.0)
	check("eye mode light-adapting: HUD says light-adapted", 1.0 if pin.hud_line().contains("light-adapted") else 0.0, 1.0, 0.0)
	check("default EV clamp floor = -14 (ISO 102400, f/1.4, 30 s = EV100 -13.9)", Exposure.EV_CLAMP.x, -14.0, 0.0)
	check("EV100 of ISO 102400, f/1.4, 30 s = log2(1.4^2 / 30) - log2(102400 / 100) = -13.9", log(1.4 * 1.4 / 30.0) / log(2.0) - log(1024.0) / log(2.0), -13.94, 0.01)
	var cam := Exposure.new()
	cam.configure(70.0, 540.0)
	cam.mode = Exposure.Mode.CAMERA
	cam.update(1e-9)
	check("camera meter on a near-black sky stops at the clamp, -14", cam.ev, -14.0, 0.0)
	var d := Exposure.new()
	check("aids are off by default (no aid line, floor off, bias 0)", 1.0 if not d.hud_line().contains("aid") and not d.floor_on and d.bias == 0.0 and d.mode == Exposure.Mode.EYE else 0.0, 1.0, 0.0)
	check("magnitude floor off by default sends zeros to the shader", d.floor_params().length(), 0.0, 0.0)


## Panorama calibration (SkyBackground): the dark patch is the median of the
## galactic caps |b| >= 70 deg, whatever the rest of the photo holds.
func test_sky_calibration() -> void:
	print("Sky background calibration to 23.5 mag/arcsec^2 (M1.5a, D-25)")
	var w := 1024
	var h := 512
	var photo := Image.create(w, h, false, Image.FORMAT_RGB8)
	photo.fill(Color8(200, 200, 200)) # a bright band everywhere
	var dark := Color8(30, 30, 30)
	for j in h:
		if absf(90.0 - 180.0 * (j + 0.5) / h) >= 72.0:
			for i in w:
				photo.set_pixel(i, j, dark)
	var model := Image.create(w, h, false, Image.FORMAT_RGBA8)
	model.fill(Color8(SkyModel.encode_t(5000.0), 0, 0, 255))
	var sb := SkyBackground.new()
	var env := Environment.new()
	sb.attach(env, 540.0, 70.0, photo, model)
	var y_lin := 0.2126729 * dark.srgb_to_linear().r + 0.7151522 * dark.srgb_to_linear().g + 0.0721750 * dark.srgb_to_linear().b
	check("dark patch = the caps' linear luminance, not the bright band", sb.dark_patch_y / y_lin, 1.0, 0.02)
	check("cd/m^2 per photo unit puts the patch at L(dark)", sb.cdm2_per_unit * sb.dark_patch_y, Exposure.dark_sky_luminance(), 1e-15)
	var pole := Vector3(0, 1, 0)
	check("CPU seen luminance at the pole at rest = L(dark) (+-2%)", sb.seen_luminance(pole, Vector3(0, 0, -1), 0.0) / Exposure.dark_sky_luminance(), 1.0, 0.02)
	# un-stretch: the band is the photo's peak quantile, 44x the patch in the photo; it must read 20.8 mag/arcsec^2
	check("SkyBackground.MILKY_WAY_MAG = 20.8 (D-25)", SkyBackground.MILKY_WAY_MAG, 20.8, 0.0)
	check("un-stretch exponent = 0.4 (23.5 - 20.8) ln 10 / ln(Y_band / Y_dark)", sb.stretch, 1.08 * log(10.0) / log(sb.peak_y / sb.dark_patch_y), 1e-12)
	check("stretch < 1 for this high-contrast photo", 1.0 if sb.stretch < 1.0 else 0.0, 1.0, 0.0)
	check("band (peak quantile) reads MILKY_WAY_MAG = 20.8 mag/arcsec^2: 10^1.08 x L(dark) (+-2%)", sb.seen_luminance(Vector3(0, 0, -1), Vector3(0, 0, -1), 0.0) / Exposure.dark_sky_luminance() / pow(10.0, 1.08), 1.0, 0.02)
	var flat := SkyBackground.new()
	var grey := Image.create(64, 32, false, Image.FORMAT_RGB8)
	grey.fill(Color8(90, 90, 90))
	flat.attach(env, 540.0, 70.0, grey, model)
	check("a uniform photo keeps stretch = 1 (goldens unchanged)", flat.stretch, 1.0, 0.0)
	var meter_fwd := sb.seen_luminance(Vector3(0, 0, -1), Vector3(0, 0, -1), 0.9)
	var rest_fwd := sb.seen_luminance(Vector3(0, 0, -1), Vector3(0, 0, -1), 0.0)
	check("CPU meter mirror: forward at 0.9c = rest x surfaceBrightnessRatio(5000 K, sqrt 19) (+-2%)", meter_fwd / rest_fwd / Relativity.surface_brightness_ratio(SkyModel.decode_t(SkyModel.encode_t(5000.0)), sqrt(19.0)), 1.0, 0.02)


## Corrected F5: with theta' the APPARENT angle from the direction of travel,
## D = 1 / (gamma (1 - beta cos theta')). Sideways at speed is redshifted and
## darker (D = 1/gamma), the rest-frame 90 deg direction (theta' = 8.1 deg at
## 0.99c) is brighter (D = gamma), and D = 1 at cos theta' = (1 - 1/gamma) / beta.
## Patch luminance is checked two ways: the sky background (extended thermal
## source, SkyModel.radiance) and an isotropic starfield (counted stars x
## pointFluxRatio over the patch's apparent solid angle).
func test_sideways_darker() -> void:
	print("Exposure honesty: sideways is darker at speed (corrected F5)")
	var b := 0.99
	var g := Relativity.gamma_of(b)
	var fwd := Vector3(0, 0, -1)
	var side := Vector3(1, 0, 0)
	check("D at theta' = 90 deg, 0.99c = 1/gamma = 0.14107", Relativity.doppler_apparent(side, fwd, b), 1.0 / g, 1e-9)
	check("1/gamma at 0.99c = 0.141067", 1.0 / g, 0.14106736, 1e-7)
	var th8 := acos(b)
	check("rest-frame 90 deg appears at theta' = acos(0.99) = 8.1096 deg", rad_to_deg(th8), 8.1096144, 1e-6)
	check("D there = gamma = 7.0888", Relativity.doppler_apparent(Vector3(sin(th8), 0, -cos(th8)), fwd, b), g, 1e-5)
	var c1 := (1.0 - 1.0 / g) / b
	check("D = 1 boundary: theta' = acos((1 - 1/gamma)/beta) = 29.818 deg (29.8) at 0.99c", rad_to_deg(acos(c1)), 29.818, 0.001)
	check("D = 1 exactly on the boundary", Relativity.doppler_apparent(Vector3(sqrt(1.0 - c1 * c1), 0, -c1), fwd, b), 1.0, 1e-6)
	check("just inside the boundary is blueshifted (D > 1)", 1.0 if Relativity.doppler_apparent(Vector3(sin(acos(c1) - 0.01), 0, -cos(acos(c1) - 0.01)), fwd, b) > 1.0 else 0.0, 1.0, 0.0)
	check("just outside is redshifted (D < 1)", 1.0 if Relativity.doppler_apparent(Vector3(sin(acos(c1) + 0.01), 0, -cos(acos(c1) + 0.01)), fwd, b) < 1.0 else 0.0, 1.0, 0.0)
	# the sky background: a 4600 K texel seen at theta' = 90 deg and 8.1 deg
	var lin := Blackbody.rgb_unit_luminance(4600.0) * 0.2
	var y0 := SkyModel.radiance(lin, 4600.0, 1.0).dot(Vector3(0.2126729, 0.7151522, 0.0721750))
	var y90 := SkyModel.radiance(lin, 4600.0, Relativity.doppler_apparent(side, fwd, b)).dot(Vector3(0.2126729, 0.7151522, 0.0721750))
	var y8 := SkyModel.radiance(lin, 4600.0, g).dot(Vector3(0.2126729, 0.7151522, 0.0721750))
	check("sky patch at theta' = 90 deg, 0.99c is BELOW rest (ratio < 1e-3)", 1.0 if y90 < 1e-3 * y0 else 0.0, 1.0, 0.0)
	check("sky patch at theta' = 8.1 deg (D = gamma) is ABOVE rest", 1.0 if y8 > y0 else 0.0, 1.0, 0.0)
	# an isotropic starfield (Fibonacci sphere, 5800 K, unit flux): mean seen luminance of a cone
	var n_stars := 400000
	var cones := [[90.0, 10.0], [rad_to_deg(th8), 0.75]] # [centre theta' deg, half-angle deg]
	var y_t := Blackbody.luminance(5800.0)
	for cone in cones:
		var axis := Vector3(sin(deg_to_rad(cone[0])), 0, -cos(deg_to_rad(cone[0])))
		var cmin := cos(deg_to_rad(cone[1]))
		var rest_sum := 0.0
		var seen_sum := 0.0
		var seen_n := 0
		for k in n_stars:
			var z := 1.0 - 2.0 * (k + 0.5) / n_stars
			var r := sqrt(1.0 - z * z)
			var ph := k * 2.399963229728653
			var n := Vector3(r * cos(ph), r * sin(ph), z)
			if n.dot(axis) >= cmin:
				rest_sum += 1.0
			var a := Relativity.aberrate(n, fwd, b)
			if a.dot(axis) >= cmin:
				var dd := Relativity.doppler(n, fwd, b)
				seen_sum += Blackbody.luminance(5800.0 * dd) / y_t / (dd * dd)
				seen_n += 1
		var ratio := seen_sum / rest_sum
		if cone[0] > 45.0:
			check("starfield patch at theta' = 90 deg, 0.99c is BELOW rest (%d stars vs %d; luminance ratio %s)" % [seen_n, int(rest_sum), str(ratio)], 1.0 if ratio < 1e-3 else 0.0, 1.0, 0.0)
			check("star count per apparent sr at 90 deg = D^2 = 1/gamma^2 (+-20%)", seen_n / rest_sum * g * g, 1.0, 0.2)
		else:
			check("starfield patch at theta' = 8.1 deg, 0.99c is ABOVE rest (luminance ratio %.1f)" % ratio, 1.0 if ratio > 1.0 else 0.0, 1.0, 0.0)
	# at a FIXED exposure the sideways frame is darker; the auto meter would hide it
	var e := Exposure.new()
	e.configure(70.0, 540.0)
	e.mode = Exposure.Mode.CAMERA
	e.set_fixed(true, y0)
	var rest_px := y0 * e.k()
	var fixed_px := y90 * e.k()
	e.set_fixed(false, 0.0)
	e.update(y90)
	var auto_px := y90 * e.k()
	check("fixed EV: the 0.99c sideways sky renders below 1e-3 of the rest frame", 1.0 if fixed_px < 1e-3 * rest_px else 0.0, 1.0, 0.0)
	check("auto (camera) meter re-brightens it > 1000x, up to the EV clamp (metering, not physics)", 1.0 if auto_px > 1000.0 * fixed_px else 0.0, 1.0, 0.0)


## M1.8 follow-up 1: the PSF is fixed in angle, so EV_dark is one number and
## the extended sky shows the same linear value at every render size (the
## M1.5a evaluation measured L(dark) 7.1x brighter at 540 rows than at 1440).
func test_angular_psf() -> void:
	print("Angular PSF: EV_dark and the sky's displayed value do not depend on the render size (M1.8)")
	var lo := Exposure.new()
	lo.configure(70.0, 540.0)
	var hi := Exposure.new()
	hi.configure(70.0, 1440.0)
	check("PSF sigma = 6 arcmin", Exposure.psf_sigma_angle(), deg_to_rad(0.1), 1e-15)
	check("EV_dark is the same at 960x540 and 2560x1440", lo.ev_dark() - hi.ev_dark(), 0.0, 0.0)
	check("EV_dark = log2(E_thr / (2 pi sigma^2) / floor / 1.2)", lo.ev_dark(), log(Exposure.threshold_lux() / (TAU * pow(deg_to_rad(0.1), 2.0)) / Exposure.DISPLAY_FLOOR / Exposure.SAT) / log(2.0), 1e-12)
	var l := Exposure.dark_sky_luminance()
	check("the dark sky's displayed linear value is the same at both sizes (was 7.1x apart)", l * lo.k() / (l * hi.k()), 1.0, 1e-12)
	check("and it is L(23.5) / L_white(EV_dark)", l * hi.k(), l / Exposure.l_white(Exposure.dark_adapted_ev()), 1e-15)
	check("1440 rows: sigma = 6' / pixel angle = 1.81 px (unclamped)", hi.psf_sigma_px(), deg_to_rad(0.1) / (2.0 * tan(deg_to_rad(35.0)) / 1440.0), 1e-9)
	check("540 rows: 6' is 0.67 px, clamped to PSF_MIN_PX = 0.7", lo.psf_sigma_px(), 0.7, 1e-12)
	check("a clamped PSF keeps the splat energy (peak x 2 pi sigma_px^2 x Omega_px = E k)", lo.star_scale() * TAU * 0.49 * lo.pixel_sr / lo.k(), 1.0, 1e-12)
	var drop := -2.5 * log(pow(Exposure.psf_sigma_angle() / lo.psf_sigma_rad(), 2.0)) / log(10.0)
	check("the clamp at 540 rows costs V_lim %.3f mag (< 0.25, AC8 margin)" % drop, 1.0 if drop < 0.25 and drop > 0.0 else 0.0, 1.0, 0.0)
	check("a sampled Gaussian of sigma 0.7 px sums to 2 pi sigma^2 within 0.1%", _gauss_sum(0.7) / (TAU * 0.49), 1.0, 1e-3)


func _gauss_sum(sigma: float) -> float:
	var s := 0.0
	for y in range(-8, 9):
		for x in range(-8, 9):
			s += exp(-(x * x + y * y) / (2.0 * sigma * sigma))
	return s


## M1.8: the forward CMB (queue row 6a, D-11). Check values from the design
## repo's physics/higgs-bubble.md (HB-62, HB-63) and sunholo/relativity 0.5.2
## (optics.cmbSeenTemperature / cmbSeenTemperatureApparent,
## blackbody.photopicRadiance), printed by `ailang run` on the package.
func test_cmb() -> void:
	print("Forward CMB disc (M1.8, D-11)")
	var cap := 1e-6 # 1 - beta at the cruise cap (D-15)
	var g := Relativity.gamma_of_one_minus_beta(cap)
	check("package: gamma at 1 - beta = 1e-6 = 707.1069579633089", g, 707.1069579633089, 1e-9)
	var fwd := Vector3(0, 0, -1)
	check("HB-63: T ahead at the cap = 3,853.7 K", Relativity.cmb_temperature_apparent(0.0, cap), 3853.7, 0.05)
	check("package: T ahead at the cap = 3853.7309940335736 K", Relativity.cmb_temperature_apparent(0.0, cap) / 3853.7309940335736, 1.0, 1e-12)
	check("rest-frame 90 deg at the cap: gamma T0 = 1,926.9 K", Relativity.cmb_seen_temperature(Vector3(1, 0, 0), fwd, cap), 1926.866460450017, 1e-6)
	check("it APPEARS at theta' = asin(1/gamma) = 0.081 deg", rad_to_deg(Relativity.angle_between(Relativity.aberrate(Vector3(1, 0, 0), fwd, 1.0 - cap), fwd)), rad_to_deg(asin(1.0 / g)), 1e-5)
	check("package: apparent theta' = 1/gamma: 1926.867102770845 K (half the pole, HB-68)", Relativity.cmb_temperature_apparent(1.0 / g, cap) / 1926.867102770845, 1.0, 1e-9)
	check("package: apparent theta' = 2/gamma: 770.7475347575637 K", Relativity.cmb_temperature_apparent(2.0 / g, cap) / 770.7475347575637, 1.0, 1e-9)
	check("package: apparent 45 deg: 0.013157428860723783 K", Relativity.cmb_temperature_apparent(PI / 4.0, cap) / 0.013157428860723783, 1.0, 1e-9)
	check("package: apparent 90 deg: T0 / gamma = 0.003853730994033576 K (redshifted)", Relativity.cmb_temperature_apparent(PI / 2.0, cap) / 0.003853730994033576, 1.0, 1e-9)
	check("HB-62: T ahead at 0.99c = 38.44 K", Relativity.cmb_temperature_apparent(0.0, 0.01), 38.44, 0.005)
	check("package: T ahead at 0.99c = 38.44085554458952 K", Relativity.cmb_temperature_apparent(0.0, 0.01) / 38.44085554458952, 1.0, 1e-12)
	check("vector form agrees with the angle form (theta' = 1/gamma)", Relativity.cmb_temperature_apparent(Relativity.angle_between(Vector3(sin(1.0 / g), 0, -cos(1.0 / g)), fwd), cap) / 1926.867102770845, 1.0, 1e-6)
	check("at rest the CMB is T0 = 2.725 K everywhere", Relativity.cmb_temperature_apparent(1.0, 1.0), 2.725, 1e-12)
	# absolute photopic radiance (cd/m^2)
	check("package: photopicRadiance(3853.7309940335736 K) = 1.9842652619286108e8 cd/m^2", Blackbody.photopic_radiance(3853.7309940335736) / 198426526.19286108, 1.0, 1e-6)
	check("package: photopicRadiance(1926.867 K) = 290755.1033757559 cd/m^2", Blackbody.photopic_radiance(1926.8671027324722) / 290755.1033757559, 1.0, 1e-6)
	check("package: photopicRadiance(770.75 K) = 0.0027554421731427795 cd/m^2", Blackbody.photopic_radiance(770.7475347575637) / 0.0027554421731427795, 1.0, 1e-6)
	check("package doc: photopicRadiance(2856 K, illuminant A) = 1.978e7 cd/m^2", Blackbody.photopic_radiance(2856.0) / 1.978e7, 1.0, 2e-3)
	check("package doc: photopicRadiance(5772 K) = 1.845e9 cd/m^2", Blackbody.photopic_radiance(5772.0) / 1.845e9, 1.0, 2e-3)
	check("photopicRadiance(2.725 K) underflows to exactly 0", Blackbody.photopic_radiance(2.725), 0.0, 0.0)
	check("photopicRadiance(0) = 0 and of NaN = 0", Blackbody.photopic_radiance(0.0) + Blackbody.photopic_radiance(NAN), 0.0, 0.0)
	var l_dark := Exposure.dark_sky_luminance()
	check("CMB radiance at beta = 0 is below 1e-30 of the dark sky (it is 0)", 1.0 if CmbGlow.sharp(0.0, 1.0) <= 1e-30 * l_dark and CmbGlow.sharp(PI, 1.0) <= 1e-30 * l_dark else 0.0, 1.0, 0.0)
	# the finite lookup over T in [0, 5000 K] (gate 5)
	var tab := CmbGlow.lut()
	var finite := 1.0
	var mono := 1.0
	for i in tab.size():
		if is_nan(tab[i]) or is_inf(tab[i]): finite = 0.0
		if i > 0 and tab[i] < tab[i - 1]: mono = 0.0
	check("the lookup's range covers the cap pole (T_MAX >= 3,853.7 K: the table, not the exact fallback, serves the disc)", 1.0 if CmbGlow.T_MAX >= Relativity.cmb_temperature_apparent(0.0, cap) else 0.0, 1.0, 0.0)
	check("CmbGlow.T_MAX = 5000 K (plan: lookup over [0, 5000 K])", CmbGlow.T_MAX, 5000.0, 0.0)
	check("CMB lookup over [0, 5000 K]: %d entries, every one finite" % tab.size(), finite, 1.0, 0.0)
	check("CMB lookup is non-decreasing in T", mono, 1.0, 0.0)
	check("lookup at T = 0 is the floor (reads back exactly 0)", CmbGlow.radiance(0.0), 0.0, 0.0)
	for t: float in [700.0, 1000.0, 1499.0, 2000.0, 3000.0, 3853.7309940335736, 4999.0]:
		check("lookup = photopicRadiance at %.1f K (0.2%%)" % t, CmbGlow.radiance(t) / Blackbody.photopic_radiance(t), 1.0, 2e-3)
	check("above T_MAX the lookup is exact", CmbGlow.radiance(6000.0) / Blackbody.photopic_radiance(6000.0), 1.0, 1e-12)
	# radial profiles: sharp mirrors the package; the PSF keeps the illuminance
	var sharp := CmbGlow.new()
	sharp.build(cap, 0.0)
	check("sharp profile at the pole = photopicRadiance(3853.7 K) (0.2%)", sharp.profile(0.0) / 198426526.19286108, 1.0, 2e-3)
	check("sharp profile at 1/gamma = photopicRadiance(1926.9 K) (1%)", sharp.profile(1.0 / g) / 290755.1033757559, 1.0, 0.01)
	check("sharp profile is 0 at 45 and 90 deg", sharp.profile(PI / 4.0) + sharp.profile(PI / 2.0), 0.0, 0.0)
	var blur := CmbGlow.new()
	blur.build(cap, Exposure.psf_sigma_angle())
	check("PSF keeps the disc's illuminance (%s lux)" % String.num_scientific(sharp.illuminance), blur.illuminance / sharp.illuminance, 1.0, 1e-12)
	check("blurred profile integrates to the same illuminance (1%)", _profile_flux(blur) / sharp.illuminance, 1.0, 0.01)
	check("sharp profile integrates to its illuminance (1%)", _profile_flux(sharp) / sharp.illuminance, 1.0, 0.01)
	check("a 6' PSF lowers the 4.9' core's peak", 1.0 if blur.profile(0.0) < sharp.profile(0.0) else 0.0, 1.0, 0.0)
	check("disc illuminance at the cap is daylight-bright (> 10 lux)", 1.0 if sharp.illuminance > 10.0 else 0.0, 1.0, 0.0)
	var g275 := CmbGlow.new()
	var omb275 := 1.0 - sqrt(1.0 - 1.0 / (275.0 * 275.0))
	g275.build(omb275, Exposure.psf_sigma_angle())
	check("gamma 275: pole at gamma (1 + beta) T0 = 1,498.7 K", g275.pole_temperature, 2.725 * 275.0 * (2.0 - omb275), 1e-6)
	check("gamma 275: the disc is visible to the dark-adapted eye (centre > 100 x L_dark)", 1.0 if g275.profile(0.0) > 100.0 * l_dark else 0.0, 1.0, 0.0)
	var slow := CmbGlow.new()
	slow.build(0.01, Exposure.psf_sigma_angle())
	check("0.99c: no visible CMB (profile empty, illuminance 0)", slow.theta_max + slow.illuminance, 0.0, 0.0)


func _profile_flux(c: CmbGlow) -> float:
	var s := 0.0
	var n := 4000
	var h := c.theta_max / n
	for i in n:
		var r := (i + 0.5) * h
		s += TAU * r * c.profile(r) * h
	return s


## M1.8 follow-up 2: the eye's meter is centre-weighted and sees the stars and
## the CMB, so the eye light-adapts to a blinding disc ahead and stays pinned
## at EV_dark otherwise.
func test_sky_meter() -> void:
	print("Centre-weighted eye meter with stars and CMB (M1.8)")
	var cam := FreeLookCamera.new()
	cam.fov = 70.0
	cam.look(0.0, 0.0, 0.0)
	var size := Vector2(960, 540)
	var fwd := Vector3(0, 0, -1)
	var l_dark := Exposure.dark_sky_luminance()
	var flat := func(_n: Vector3) -> float: return l_dark
	var m := SkyMeter.new()
	check("a uniform sky meters as itself", m.centre_weighted(cam, size, fwd, 0.0, flat, null, null) / l_dark, 1.0, 1e-12)
	var sf := Starfield.new()
	sf.set_custom_stars([{"pos": Vector3(0, 0, -100.0), "t": 5800.0, "flux": 1e-3}])
	m.build(sf)
	var centre := m.centre_weighted(cam, size, fwd, 0.0, flat, sf, null)
	sf.set_custom_stars([{"pos": Vector3(60.0, 0, -100.0), "t": 5800.0, "flux": 1e-3}]) # 31 deg off centre
	m.build(sf)
	var edge := m.centre_weighted(cam, size, fwd, 0.0, flat, sf, null)
	sf.set_custom_stars([{"pos": Vector3(0, 0, 100.0), "t": 5800.0, "flux": 1e-3}]) # behind the camera
	m.build(sf)
	var behind := m.centre_weighted(cam, size, fwd, 0.0, flat, sf, null)
	check("a 1e-3 lux star at the centre raises the meter", 1.0 if centre > 2.0 * l_dark else 0.0, 1.0, 0.0)
	check("the same star 31 deg off centre counts less (centre weight)", 1.0 if edge - l_dark < 0.2 * (centre - l_dark) else 0.0, 1.0, 0.0)
	check("a star behind the camera does not count", behind / l_dark, 1.0, 1e-12)
	check("near stars (< 20 ly) are metered one by one, far ones in bins", 1.0 if m.near.size() == 0 and m.bin_e.size() == 1 else 0.0, 1.0, 0.0)
	sf.set_custom_stars([{"pos": Vector3(0, 0, -5.0), "t": 5800.0, "flux": 1e-3}])
	m.build(sf)
	check("a star at 5 ly is a near star and meters like a far one", m.centre_weighted(cam, size, fwd, 0.0, flat, sf, null) / centre, 1.0, 1e-9)
	# the eye at the cap: forward the CMB disc light-adapts it; astern it stays pinned
	var cmb := CmbGlow.new()
	cmb.build(1e-6, Exposure.psf_sigma_angle())
	var e := Exposure.new()
	e.configure(70.0, 540.0)
	var l_fwd := m.centre_weighted(cam, size, fwd, 1.0 - 1e-6, flat, null, cmb)
	e.update(l_dark, l_fwd)
	check("gamma 707 forward: the eye light-adapts to the CMB disc (EV %+.1f > EV_dark %+.1f)" % [e.ev, e.ev_dark()], 1.0 if e.ev > e.ev_dark() + 5.0 else 0.0, 1.0, 0.0)
	check("and the HUD says light-adapted", 1.0 if e.state_name() == "light-adapted" else 0.0, 1.0, 0.0)
	cam.look(PI, 0.0, 0.0)
	e.update(l_dark, m.centre_weighted(cam, size, fwd, 1.0 - 1e-6, flat, null, cmb))
	check("gamma 707 astern: no disc in view, the eye stays at EV_dark", e.ev, e.ev_dark(), 1e-12)
	e.update(l_dark, l_dark)
	check("at rest on the dark sky the eye is pinned at EV_dark", e.ev, e.ev_dark(), 1e-12)
	e.mode = Exposure.Mode.CAMERA
	e.update(l_dark, l_fwd)
	check("camera mode keeps its log-average meter (ignores the eye meter)", e.ev, Exposure.metered_ev(l_dark), 1e-12)
	sf.free()
	cam.free()
	_test_main_eye_meter_wiring()


## main.gd's own wiring (not only the captures): the eye meter gets the
## background's CMB when moving and the panorama is attached, and no disc at
## rest. main.gd is instanced without entering the tree (no _ready, no sim).
func _test_main_eye_meter_wiring() -> void:
	var script: GDScript = load("res://main.gd")
	if script == null or not script.can_instantiate():
		check("main.gd loads for the eye-meter wiring test", 0.0, 1.0, 0.0)
		return
	var m: Node3D = script.new()
	var photo := Image.create(64, 32, false, Image.FORMAT_RGB8)
	photo.fill(Color8(30, 30, 30))
	var model := Image.create(64, 32, false, Image.FORMAT_RGBA8)
	model.fill(Color8(SkyModel.encode_t(5000.0), 0, 0, 255))
	m.has_background = m.background.attach(Environment.new(), 540.0, 70.0, photo, model)
	m.heading = Vector3(0, 0, -1)
	m.camera.fov = 70.0
	m.camera.look(0.0, 0.0, 0.0)
	m.background.set_psf(Exposure.psf_sigma_angle())
	var omb := 1e-6
	var g := Relativity.gamma_of_one_minus_beta(omb)
	m.background.set_velocity(m.heading, 1.0 - omb, g)
	var rest: float = m._meter_eye_now(0.0)
	var moving: float = m._meter_eye_now(1.0 - omb)
	check("main.gd eye meter at rest reads the sky (no CMB): L(dark) +-2%", rest / Exposure.dark_sky_luminance(), 1.0, 0.02)
	check("main.gd eye meter at gamma 707 forward includes the disc (> 100 cd/m^2; got %s)" % String.num_scientific(moving), 1.0 if moving > 100.0 else 0.0, 1.0, 0.0)
	var e := Exposure.new()
	e.configure(70.0, 540.0)
	e.update(rest, moving)
	check("so the eye light-adapts above EV_dark through main.gd's wiring", 1.0 if e.ev > e.ev_dark() + 5.0 else 0.0, 1.0, 0.0)
	m.camera.free()
	m.starfield.free()
	m.free()


## The camera cases need a node in a viewport, so they run once the main loop
## has started; everything else runs in _init.
func _initialize() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(960, 540)
	root.add_child(vp)
	await process_frame
	test_rolled_camera_cpu_spec_values(vp)
	test_view_velocity_angle(vp)
	print("\n%d passed, %d failed" % [passes, failures])
	quit(1 if failures > 0 else 0)


func _init() -> void:
	var fwd := Vector3(0, 0, -1)
	var side := Vector3(1, 0, 0)
	var back := -fwd
	test_off_axis_cpu_spec_values()
	test_catalogue_galactic_directions()
	test_lut_range()
	test_star_brightness()
	test_rebasing_precision()
	test_exposure_units()
	test_sky_calibration()
	test_sideways_darker()
	test_angular_psf()
	test_cmb()
	test_sky_meter()

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

