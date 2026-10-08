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
	check("galactic (3, 4, 0) -> world (-4, 0, -3) (SkyFrame, D-28)", Vector3(sf.pos[0], sf.pos[1], sf.pos[2]).distance_to(Vector3(-4, 0, -3)), 0.0, 0.0)
	check("custom data: |p|^2 = 25 ly^2", sf.custom[3], 25.0, 0.0)
	sf.set_ship_position(-4.0 * 0.5, 0.0, -3.0 * 0.5)
	check("flux at the ship = E_v x |p|^2 / r^2 (halfway: 4x)", sf.flux_at_ship(0) / Relativity.illuminance_from_v(2.0), 4.0, 1e-6)
	sf.free()
	# only_flags: the HIP-filled rows of a tier (flag 8), nothing else
	var hipcat := _tier_fixture([[1.0, 2.0, 3.0, 9900.0, -1.44, 8.0], [2.0, 2.0, 2.0, 3000.0, 11.0, 0.0], [5.0, 0.0, 0.0, 0.0, 99.0, 2.0]])
	var sh := Starfield.new()
	sh.append_catalogue(hipcat, StarCatalogue.FLAG_HIP)
	check("only_flags = FLAG_HIP keeps just the HIP-filled row", sh.count, 1, 0.0)
	check("and it is the V -1.44 row", sh.custom[1] / Relativity.illuminance_from_v(-1.44), 1.0, 1e-6)
	sh.free()
	# the committed tiers: medium (GCNS) + bright + quick rows GCNS lacks (HIP fill) must draw Sirius
	# (Gl 244: SIMBAD l 227.230, b -8.890, 8.6 ly; GCNS has no Gaia photometry for it)
	var sm := Starfield.new()
	check("medium tier loads with bright + HIP fill", 1.0 if sm.load_tiers("medium") else 0.0, 1.0, 0.0)
	check("stacked tiers are medium, quick:rest, bright", 1.0 if sm.tiers == ["medium", "quick:rest", "bright"] else 0.0, 1.0, 0.0)
	var sdir := SkyFrame.world_dir_lb(227.230, -8.890)
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
	var star := SkyFrame.to_world64(g) # galactic -> world, float64 scalars
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
	# M4.6 R3: the alpha Cen cruise mirror; `runtime/bin/ailang run --quiet --caps IO --package-dir sim --entry main sim/tools/m4_physics_probe.ail`
	# line "cruise gammaOf(rapidityOfBeta(0.99)) 7.088812050083356" (the coastAt / planBurnCoastBurn rows are sim-only: sim/m4_physics_test.ail)
	check("gamma(0.99c) = package gammaOf 7.088812050083356 (exact)", g, 7.088812050083356, 1e-13)
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
	# the gamma 40-60 ring (fix/cmb-ring): the profile's colour was 0/0 = NaN where the
	# blurred radiance underflowed float32, and the shader drew NaN texels as a white ring
	for gr: float in [40.0, 50.0, 60.0, 275.0, 707.0]:
		var omb_r := 1.0 - sqrt(1.0 - 1.0 / (gr * gr)) if gr < 700.0 else cap
		for sig: float in [Exposure.psf_sigma_angle(), 0.0]:
			_check_profile_shape(gr, omb_r, sig)
	var slow := CmbGlow.new()
	slow.build(0.01, Exposure.psf_sigma_angle())
	check("0.99c: no visible CMB (profile empty, illuminance 0)", slow.theta_max + slow.illuminance, 0.0, 0.0)


## Every profile texel finite, radiance non-increasing outward (no ring), and
## nothing left at the cutoff (no step): the last sample <= 1e-12 of the pole.
func _check_profile_shape(g: float, omb: float, sigma: float) -> void:
	var c := CmbGlow.new()
	c.build(omb, sigma)
	var finite := 1.0
	var mono := 1.0
	var prev := INF
	for i in CmbGlow.PROFILE_SIZE:
		var px := c.image.get_pixel(i, 0)
		for ch in [px.r, px.g, px.b, px.a]:
			if is_nan(ch) or is_inf(ch): finite = 0.0
		if px.a > prev + 1e-9: mono = 0.0
		prev = px.a
	var tag := "gamma %.0f %s" % [g, "PSF" if sigma > 0.0 else "sharp"]
	check("%s: every CMB profile texel is finite (no NaN colour)" % tag, finite, 1.0, 0.0)
	check("%s: radiance never rises outward (no ring)" % tag, mono, 1.0, 0.0)
	var edge := pow(10.0, c.image.get_pixel(CmbGlow.PROFILE_SIZE - 1, 0).a)
	var pole := pow(10.0, c.image.get_pixel(0, 0).a)
	check("%s: no step at theta_max (edge <= 1e-12 x pole or below 1e-30 cd/m^2)" % tag, 1.0 if edge <= 1e-12 * pole or edge < 1e-30 else 0.0, 1.0, 0.0)


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


## Every game script compiles. A parse error in one class (e.g. two PRs that each add the
## same `var`, merged cleanly by git: #101 + #102 both added SimBridge.want_minor) otherwise
## surfaces only as a distant "main.gd loads" failure, and Godot exits 0 on it.
func test_scripts_compile() -> void:
	print("Game scripts compile (load + can_instantiate)")
	for dir in ["res://bridge", "res://interior", "res://sky", "res://ui", "res://ui/conversation", "res://ui/settings", "res://physics"]:
		for f in DirAccess.get_files_at(dir):
			if f.ends_with(".gd"):
				var sc := load(dir.path_join(f)) as GDScript
				check("%s compiles" % dir.path_join(f).trim_prefix("res://"), 1.0 if sc != null and sc.can_instantiate() else 0.0, 1.0, 0.0)
	var m := load("res://main.gd") as GDScript
	check("main.gd compiles", 1.0 if m != null and m.can_instantiate() else 0.0, 1.0, 0.0)


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


## D-28 (Mark, 2026-10-03): ONE right-handed galactic -> world map (sky/sky_frame.gd and its shader
## include), used everywhere. Before D-28 the map was (x, y, z) -> (y, z, -x), det -1, and the whole
## M1 sky rendered as the real sky's mirror image; GPU-vs-CPU goldens could not see it because both
## sides shared the map. The oracle here is independent of the map: SIMBAD galactic l, b of real
## objects seen through the real free-look camera, whose screen right is forward x up.
const SKY_ORACLE := {
	"Antares": [351.947, 15.064], "alpha Cen A": [315.734, -0.680], "Vega": [67.448, 19.237],
	"Scutum star cloud": [27.0, -2.5], "Mintaka": [203.856, -17.740], "Alnilam": [205.212, -17.243],
	"Alnitak": [206.452, -16.585], "LMC": [280.465, -32.888], "SMC": [302.797, -44.299], "Acrux": [300.128, -0.359],
}
## Hand copies of the map (any order of components with a minus) that must not exist outside
## sky/sky_frame.gd(shaderinc). Backreferences keep them to one variable's components.
const MAP_COPY_PATTERNS := [
	"(\\w+)\\.y,\\s*\\1\\.z,\\s*-\\1\\.x", "-(\\w+)\\.z,\\s*-?\\1\\.x,\\s*-?\\1\\.y",
	"(\\w+)\\[1\\],\\s*\\1\\[2\\],\\s*-\\1\\[0\\]", "-(\\w+)\\[2\\],\\s*-?\\1\\[0\\],\\s*-?\\1\\[1\\]",
	"(\\w+)\\[\"y\"\\],\\s*\\1\\[\"z\"\\],\\s*-\\1\\[\"x\"\\]",
]


func _sky_dir(name: String) -> Vector3:
	var lb: Array = SKY_ORACLE[name]
	var w := SkyFrame.world_dir_lb(lb[0], lb[1])
	return Vector3(w[0], w[1], w[2])


## A camera looking at world direction d with roll 0 (its up = the NGP projected).
func _face(cam: FreeLookCamera, d: Vector3) -> void:
	cam.look(atan2(-d.x, -d.z), asin(clampf(d.y, -1.0, 1.0)), 0.0)


func test_sky_frame() -> void:
	print("Sky frame (D-28): one right-handed galactic -> world map, real sky orientation")
	var ex := SkyFrame.to_world(Vector3(1, 0, 0))
	var ey := SkyFrame.to_world(Vector3(0, 1, 0))
	var ez := SkyFrame.to_world(Vector3(0, 0, 1))
	check("det [to_world(x) to_world(y) to_world(z)] = +1 (a rotation, not a mirror)", Basis(ex, ey, ez).determinant(), 1.0, 0.0)
	var r: Array = SkyFrame.R
	var det_r: float = r[0][0] * (r[1][1] * r[2][2] - r[1][2] * r[2][1]) - r[0][1] * (r[1][0] * r[2][2] - r[1][2] * r[2][0]) + r[0][2] * (r[1][0] * r[2][1] - r[1][1] * r[2][0])
	check("det SkyFrame.R = +1 (float64)", det_r, 1.0, 0.0)
	check("to_world(x) x to_world(y) = to_world(z) (handedness kept)", ex.cross(ey).distance_to(ez), 0.0, 0.0)
	var probe := Vector3(0.3, -0.7, 0.2)
	var worst := 0.0
	for i in 3:
		var row: Array = r[i]
		worst = maxf(worst, absf(SkyFrame.to_world(probe)[i] - (row[0] * probe.x + row[1] * probe.y + row[2] * probe.z)))
	check("to_world = R g (the const rows)", worst, 0.0, 0.0)
	check("to_galactic(to_world(g)) = g", SkyFrame.to_galactic(SkyFrame.to_world(probe)).distance_to(probe), 0.0, 0.0)
	check("to_world(to_galactic(w)) = w", SkyFrame.to_world(SkyFrame.to_galactic(probe)).distance_to(probe), 0.0, 0.0)
	var g64 := PackedFloat64Array([0.123456789012345, -4.5678901234567, 8.9012345678901])
	var w64 := SkyFrame.to_world64(g64)
	var back := SkyFrame.to_galactic64(w64)
	check("float64 round trip exact", absf(back[0] - g64[0]) + absf(back[1] - g64[1]) + absf(back[2] - g64[2]), 0.0, 0.0)
	check("float64 and Vector3 forms agree", Vector3(w64[0], w64[1], w64[2]).distance_to(SkyFrame.to_world(Vector3(g64[0], g64[1], g64[2]))), 0.0, 1e-5)
	check("Starfield.galactic_to_world is SkyFrame.to_world (public API kept)", Starfield.galactic_to_world(probe).distance_to(SkyFrame.to_world(probe)), 0.0, 0.0)
	check("Starfield.world_to_galactic is SkyFrame.to_galactic", Starfield.world_to_galactic(probe).distance_to(SkyFrame.to_galactic(probe)), 0.0, 0.0)
	check("galactic centre -> world -Z (Godot forward)", SkyFrame.to_world(Vector3(1, 0, 0)).distance_to(Vector3(0, 0, -1)), 0.0, 0.0)
	check("north galactic pole -> world +Y", SkyFrame.to_world(Vector3(0, 0, 1)).distance_to(Vector3(0, 1, 0)), 0.0, 0.0)
	check("l 270 -> world +X (starboard: right of a ship facing the centre, NGP up)", SkyFrame.to_world(Vector3(0, -1, 0)).distance_to(Vector3(1, 0, 0)), 0.0, 0.0)
	check("l 90 -> world -X (port)", SkyFrame.to_world(Vector3(0, 1, 0)).distance_to(Vector3(-1, 0, 0)), 0.0, 0.0)

	# the shader include carries the same map: evaluate its two return expressions here
	var inc := FileAccess.get_file_as_string("res://sky/sky_frame.gdshaderinc")
	var re := RegEx.create_from_string("vec3\\s+(sky_\\w+)\\(vec3\\s+(\\w)\\)\\s*\\{\\s*return\\s+vec3(\\([^;]*\\));")
	var found := {}
	for m in re.search_all(inc):
		var e := Expression.new()
		if e.parse("Vector3" + m.get_string(3), [m.get_string(2)]) == OK:
			found[m.get_string(1)] = e.execute([probe])
	check("shader include: sky_galactic_to_world(g) = SkyFrame.to_world(g)", (found["sky_galactic_to_world"] as Vector3).distance_to(SkyFrame.to_world(probe)) if found.has("sky_galactic_to_world") else 99.0, 0.0, 0.0)
	check("shader include: sky_world_to_galactic(w) = SkyFrame.to_galactic(w)", (found["sky_world_to_galactic"] as Vector3).distance_to(SkyFrame.to_galactic(probe)) if found.has("sky_world_to_galactic") else 99.0, 0.0, 0.0)
	var bg := FileAccess.get_file_as_string("res://sky/background.gdshader")
	check("background.gdshader includes sky_frame.gdshaderinc and calls it", 1.0 if bg.contains("#include \"res://sky/sky_frame.gdshaderinc\"") and bg.contains("sky_world_to_galactic(") else 0.0, 1.0, 0.0)

	# no hand copy left anywhere (GDScript and shaders)
	var copies := []
	var regs := []
	for p: String in MAP_COPY_PATTERNS:
		regs.append(RegEx.create_from_string(p))
	for path: String in _source_files("res://"):
		if path.begins_with("res://sky/sky_frame."):
			continue
		var text := FileAccess.get_file_as_string(path)
		for rg: RegEx in regs:
			var m := rg.search(text)
			if m != null:
				copies.append("%s: %s" % [path, m.get_string()])
	for c in copies:
		print("        hand copy: %s" % c)
	check("no hand copy of the map outside sky/sky_frame.* (%d found)" % copies.size(), copies.size(), 0, 0.0)

	# the oracle: facing the galactic centre with the NGP up (FreeLookCamera yaw 0 = KEY_1 forward)
	var cam := FreeLookCamera.new()
	cam.look(0.0, 0.0, 0.0)
	var lb := SkyFrame.lb_of_world([cam.view_dir().x, cam.view_dir().y, cam.view_dir().z])
	check("forward view (yaw 0) looks at l 0, b 0", absf(fposmod(lb[0] + 180.0, 360.0) - 180.0) + absf(lb[1]), 0.0, 1e-6)
	check("forward view: screen up = NGP", cam.screen_up().dot(SkyFrame.to_world(Vector3(0, 0, 1))), 1.0, 1e-6)
	for name: String in ["Antares", "alpha Cen A"]:
		check("facing the centre, NGP up: %s (l %.0f) is RIGHT of centre" % [name, SKY_ORACLE[name][0]], 1.0 if _sky_dir(name).dot(cam.screen_right()) > 0.05 else 0.0, 1.0, 0.0)
	for name: String in ["Vega", "Scutum star cloud"]:
		check("facing the centre, NGP up: %s (l %.0f) is LEFT of centre" % [name, SKY_ORACLE[name][0]], 1.0 if _sky_dir(name).dot(cam.screen_right()) < -0.05 else 0.0, 1.0, 0.0)
	check("facing the centre: Antares (b +15) is above the plane", 1.0 if _sky_dir("Antares").dot(cam.screen_up()) > 0.2 else 0.0, 1.0, 0.0)
	# the same through the catalogue and the Starfield loader (stars.json x, y, z -> tier -> pos)
	var stars: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/starmap/stars.json"))["stars"]
	var rows := []
	var want_right := []
	for pair in [["CNS5:3627", true], ["CNS5:4607", false]]: # alpha Cen A right, Vega left
		for s in stars:
			if s["id"] == pair[0]:
				rows.append([s["x"], s["y"], s["z"], 5800.0, 1.0, 0.0])
				want_right.append(pair[1])
	var cat := _tier_fixture(rows)
	var sf := Starfield.new()
	sf.append_catalogue(cat)
	var sides_ok := sf.count == 2
	for k in sf.count:
		var right := Vector3(sf.pos[3 * k], sf.pos[3 * k + 1], sf.pos[3 * k + 2]).normalized().dot(cam.screen_right()) > 0.05
		sides_ok = sides_ok and right == want_right[k]
	check("catalogue through Starfield.append_catalogue: alpha Cen A right, Vega left", 1.0 if sides_ok else 0.0, 1.0, 0.0)
	sf.free()

	# the capture / KEY_1-4 views: starboard (yaw -90) looks at l 270, port (yaw +90) at l 90
	var main_script: GDScript = load("res://main.gd")
	var views: Dictionary = main_script.VIEW_YAW
	for v in [["starboard", 270.0], ["port", 90.0], ["astern", 180.0]]:
		cam.look(views[v[0]], 0.0, 0.0)
		var d := cam.view_dir()
		check("%s view (yaw %+.0f deg) looks at l %.0f" % [v[0], rad_to_deg(views[v[0]]), v[1]], SkyFrame.lb_of_world([d.x, d.y, d.z])[0], v[1], 1e-6)

	# Orion's belt, facing Alnilam with the NGP up: Mintaka (west) right, Alnitak (east) left
	_face(cam, _sky_dir("Alnilam"))
	var xm := _sky_dir("Mintaka").dot(cam.screen_right())
	var xa := _sky_dir("Alnilam").dot(cam.screen_right())
	var xz := _sky_dir("Alnitak").dot(cam.screen_right())
	check("Orion's belt left to right: Alnitak, Alnilam, Mintaka", 1.0 if xz < xa and xa < xm else 0.0, 1.0, 0.0)
	# LMC vs Crux, facing l 290 b -16: the LMC lower right, Acrux upper left
	var mid := SkyFrame.world_dir_lb(290.0, -16.0)
	_face(cam, Vector3(mid[0], mid[1], mid[2]))
	var lmc := _sky_dir("LMC")
	var acrux := _sky_dir("Acrux")
	check("facing l 290: the LMC (l 280) is right of Acrux (l 300)", 1.0 if lmc.dot(cam.screen_right()) > 0.05 and acrux.dot(cam.screen_right()) < -0.05 else 0.0, 1.0, 0.0)
	check("facing l 290: Acrux is above the LMC", 1.0 if acrux.dot(cam.screen_up()) > lmc.dot(cam.screen_up()) + 0.3 else 0.0, 1.0, 0.0)
	cam.free()

	# stars and panorama share the frame: the world direction of (l, b) samples the panorama at
	# u = 0.5 - l / 360 (l grows leftward, D-10), v = 0.5 - b / 180, for every oracle object
	var worst_uv := 0.0
	for name: String in SKY_ORACLE:
		var o: Array = SKY_ORACLE[name]
		var uv := SkyModel.equirect_uv(_sky_dir(name))
		var du := absf(fposmod(uv.x - (0.5 - o[0] / 360.0) + 0.5, 1.0) - 0.5)
		worst_uv = maxf(worst_uv, maxf(du, absf(uv.y - (0.5 - o[1] / 180.0))))
	check("panorama (u, v) at each oracle object's world direction = its (l, b)", worst_uv, 0.0, 1e-6)
	_panorama_alignment()


## The NOIRLab panorama against the oracle (skipped when the sky textures are not fetched, as in
## CI; make sky-assets): the Magellanic Clouds are bright where the frame puts them and the
## mirror-image positions (l -> 360 - l) are dark sky.
func _panorama_alignment() -> void:
	if not FileAccess.file_exists(SkyBackground.PHOTO):
		print("  skip  panorama alignment (no %s; make sky-assets)" % SkyBackground.PHOTO)
		return
	var img := Image.new()
	if img.load_png_from_buffer(FileAccess.get_file_as_bytes(SkyBackground.PHOTO)) != OK:
		check("panorama loads", 0.0, 1.0, 0.0)
		return
	img.resize(img.get_width() / 8, img.get_height() / 8, Image.INTERPOLATE_BILINEAR)
	for name: String in ["LMC", "SMC"]:
		var o: Array = SKY_ORACLE[name]
		var here := _pano_mean(img, _sky_dir(name))
		var w := SkyFrame.world_dir_lb(360.0 - o[0], o[1])
		var mirror := _pano_mean(img, Vector3(w[0], w[1], w[2]))
		check("panorama: %s where the frame puts it is > 2x its mirror position (ratio)" % name, 1.0 if here > 2.0 * mirror else 0.0, 1.0, 0.0)
		print("        %s mean luminance %.4f, mirror %.4f, ratio %.2f" % [name, here, mirror, here / maxf(mirror, 1e-9)])


func _pano_mean(img: Image, d: Vector3) -> float:
	var uv := SkyModel.equirect_uv(d)
	var cx := int(uv.x * img.get_width())
	var cy := int(uv.y * img.get_height())
	var r := int(1.5 / 360.0 * img.get_width()) # a 3 deg box
	var s := 0.0
	var n := 0
	for y in range(cy - r, cy + r + 1):
		for x in range(cx - r, cx + r + 1):
			s += img.get_pixel(posmod(x, img.get_width()), clampi(y, 0, img.get_height() - 1)).get_luminance()
			n += 1
	return s / n


## Every tracked-style source file (.gd, .gdshader, .gdshaderinc) under dir, skipping data,
## caches, the runtime and hidden folders.
func _source_files(dir: String) -> Array:
	var out := []
	var d := DirAccess.open(dir)
	if d == null:
		return out
	for f in d.get_files():
		if f.ends_with(".gd") or f.ends_with(".gdshader") or f.ends_with(".gdshaderinc"):
			out.append(dir.path_join(f))
	for sub in d.get_directories():
		if sub.begins_with(".") or sub in ["data", "runtime", "renders", "website", "node_modules", "sky_bundle", "areas_bundle", "assets"]:
			continue
		out.append_array(_source_files(dir.path_join(sub)))
	return out


## M4.0 frame contract (interior/ship_frame.gd, float64): ship +Z = direction of
## travel, up = direction of travel for the whole journey (D-14, no flip), roll
## from the north galactic pole projected normal to the heading, galactic +X
## within 1e-6 of a pole. M4.6 extends these (AC9).
func test_ship_frame() -> void:
	print("Ship frame (M4.0 frame contract, D-14: up = direction of travel, no flip)")
	var headings: Array[PackedFloat64Array] = [
		PackedFloat64Array([1.0, 0.0, 0.0]), PackedFloat64Array([0.0, 1.0, 0.0]),
		PackedFloat64Array([-1.0, 0.0, 0.0]), PackedFloat64Array([0.0, -1.0, 0.0]),
		PackedFloat64Array([0.0, 0.0, 1.0]), PackedFloat64Array([0.0, 0.0, -1.0]),
		PackedFloat64Array([1e-7, 0.0, 1.0]), PackedFloat64Array([0.0, -3e-7, -1.0]),
		PackedFloat64Array([1e-5, 0.0, 1.0]),
	]
	# a fixed spread of off-axis headings (deterministic LCG, no hidden state)
	var seed := 12345
	for i in 64:
		var v := PackedFloat64Array()
		for k in 3:
			seed = (seed * 1103515245 + 12345) % 2147483648
			v.append(float(seed) / 1073741824.0 - 1.0)
		headings.append(v)
	var worst_ortho := 0.0
	var worst_z := 0.0
	var worst_det := 0.0
	var worst_pole_x := 0.0
	for h in headings:
		var n := sqrt(h[0] * h[0] + h[1] * h[1] + h[2] * h[2])
		var u := PackedFloat64Array([h[0] / n, h[1] / n, h[2] / n])
		var b := ShipFrame.ship_basis(h)
		for i in 3:
			for j in 3:
				var d := b[3 * i] * b[3 * j] + b[3 * i + 1] * b[3 * j + 1] + b[3 * i + 2] * b[3 * j + 2]
				worst_ortho = maxf(worst_ortho, absf(d - (1.0 if i == j else 0.0)))
		for k in 3:
			worst_z = maxf(worst_z, absf(b[6 + k] - u[k]))
		worst_det = maxf(worst_det, absf(ShipFrame.det(b) - 1.0))
		# away from the poles ship X lies in the galactic plane (NGP is in the ship Y-Z plane)
		if absf(u[2]) < 1.0 - 1e-6:
			worst_pole_x = maxf(worst_pole_x, absf(b[2]))
	check("ship basis orthonormal to 1e-12 (73 headings incl. poles)", worst_ortho, 0.0, 1e-12)
	check("ship +Z = heading to 1e-12 (direction of travel is up)", worst_z, 0.0, 1e-12)
	check("ship basis is right-handed (det +1)", worst_det, 0.0, 1e-12)
	check("off-pole roll: ship X in the galactic plane (X . NGP = 0)", worst_pole_x, 0.0, 1e-12)
	var gc := ShipFrame.ship_basis(PackedFloat64Array([1.0, 0.0, 0.0]))
	check("heading galactic centre: ship +Y = north galactic pole (z)", gc[5], 1.0, 1e-12)
	check("heading galactic centre: ship +X = Y x Z = galactic +y", gc[1], 1.0, 1e-12)
	var np := ShipFrame.ship_basis(PackedFloat64Array([0.0, 0.0, 1.0]))
	check("heading NGP (pole fallback): ship +Y = galactic +X", np[3], 1.0, 1e-12)
	var near := ShipFrame.ship_basis(PackedFloat64Array([0.0, 4e-7, 1.0]))
	check("heading 4e-7 rad from NGP: fallback, ship +Y . galactic +X ~ 1", near[3], 1.0, 1e-12)
	var sp := ShipFrame.ship_basis(PackedFloat64Array([0.0, 0.0, -1.0]))
	check("heading SGP (pole fallback): ship +Y = galactic +X", sp[3], 1.0, 1e-12)
	check("heading SGP: ship +Z = galactic -z (no flip, still up)", sp[8], -1.0, 1e-12)
	var outside := ShipFrame.ship_basis(PackedFloat64Array([0.0, 1e-5, 1.0]))
	check("heading 1e-5 rad from NGP: no fallback, ship +Y follows the pole projection (galactic -y)", outside[4], -1.0, 1e-9)
	check("short heading array is refused (empty basis, no error)", float(ShipFrame.ship_basis(PackedFloat64Array([1.0, 0.0])).size()), 0.0, 0.0)
	# Just outside the pole fallback (1.0-1.3e-6 rad) the NGP projection is ~1e-6 long, so plain
	# Gram-Schmidt leaves |Y . Z| ~1e-10; ship_basis re-derives Y = Z x X and stays at 1e-12.
	var naive_worst := 0.0
	var near_worst := 0.0
	for i in 200:
		var ang := 1.0e-6 * (1.0 + i * 0.0015)
		var phi := i * 0.37
		for sgn in [1.0, -1.0]:
			var nh := PackedFloat64Array([sin(ang) * cos(phi), sin(ang) * sin(phi), sgn * cos(ang)])
			var nb := ShipFrame.ship_basis(nh)
			var e := 0.0
			for i2 in 3:
				for j2 in 3:
					var dd := nb[3 * i2] * nb[3 * j2] + nb[3 * i2 + 1] * nb[3 * j2 + 1] + nb[3 * i2 + 2] * nb[3 * j2 + 2]
					e = maxf(e, absf(dd - (1.0 if i2 == j2 else 0.0)))
			near_worst = maxf(near_worst, e)
			# the naive reference: Y = unit(NGP - (NGP . Z) Z)
			var zd := nh[2]
			var gy := [-zd * nh[0], -zd * nh[1], 1.0 - zd * nh[2]]
			var gn := sqrt(gy[0] * gy[0] + gy[1] * gy[1] + gy[2] * gy[2])
			naive_worst = maxf(naive_worst, absf((gy[0] * nh[0] + gy[1] * nh[1] + gy[2] * nh[2]) / gn))
	check("near-pole headings defeat plain Gram-Schmidt (|Y.Z| > 1e-12): the test has teeth", 1.0 if naive_worst > 1e-12 else 0.0, 1.0, 0.0)
	check("near-pole headings (1.0-1.3e-6 rad): ship basis still orthonormal to 1e-12", near_worst, 0.0, 1e-12)
	check("zero heading is refused (empty basis)", float(ShipFrame.ship_basis(PackedFloat64Array([0.0, 0.0, 0.0])).size()), 0.0, 0.0)
	# the round trip ship -> galactic -> ship is exact to float64
	var hb := ShipFrame.ship_basis(headings[20])
	var v := PackedFloat64Array([0.3, -0.7, 0.2])
	var back := ShipFrame.to_ship(hb, ShipFrame.to_galactic(hb, v))
	check("to_ship(to_galactic(v)) = v", absf(back[0] - v[0]) + absf(back[1] - v[1]) + absf(back[2] - v[2]), 0.0, 1e-15)
	# the sky camera = ship_basis(heading) x cam.forward/up, the same for boost and brake (no flip)
	var cam := {"forward": [-0.5302520394325256, 0.26512596011161804, 0.8053204417228699],
		"up": [0.7203004956245422, -0.3601502478122711, 0.592839777469635]}
	var sc := ShipFrame.sky_camera(PackedFloat64Array([1.0, 0.0, 0.0]), cam)
	check("bridge cam forward . heading = cam forward z (0.80532)", sc["forward"][0], 0.8053204417228699, 1e-12)
	check("bridge cam up . NGP = cam up y when heading galactic centre", sc["up"][2], -0.3601502478122711, 1e-12)
	# M4.6 R2: the same through the shipped assets/areas/bridge/cam_bridge.json itself (not a copy of it), and a
	# galactic direction projected onto the camera. Heading galactic centre: ship X = galactic +y, Y = +z, Z = +x
	# (the gc[] cases above), so a ship-frame vector (a, b, c) is galactic (c, a, b): pure permutation, exact.
	var cj: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/areas/bridge/cam_bridge.json"))
	var cf: Array = cj["forward"]
	var cu: Array = cj["up"]
	var jc := ShipFrame.sky_camera(PackedFloat64Array([1.0, 0.0, 0.0]), cj)
	check("cam_bridge.json forward through the GC-heading basis = (f.z, f.x, f.y)", absf(jc["forward"][0] - cf[2]) + absf(jc["forward"][1] - cf[0]) + absf(jc["forward"][2] - cf[1]), 0.0, 1e-15)
	check("cam_bridge.json up through the GC-heading basis = (u.z, u.x, u.y)", absf(jc["up"][0] - cu[2]) + absf(jc["up"][1] - cu[0]) + absf(jc["up"][2] - cu[1]), 0.0, 1e-15)
	# galactic +x (the heading) lies at camera forward-coordinate f.z and up-coordinate u.z; galactic +z (NGP) at f.y, u.y
	check("galactic +x (the heading) projects on the camera forward axis at f.z = 0.80532", jc["forward"][0], 0.8053204417228699, 1e-12)
	check("galactic +x projects on the camera up axis at u.z = 0.592840", jc["up"][0], 0.592839777469635, 1e-12)
	check("galactic +z (NGP) projects on the camera forward axis at f.y = 0.265126", jc["forward"][2], 0.26512596011161804, 1e-12)
	check("galactic +z (NGP) projects on the camera up axis at u.y = -0.360150", jc["up"][2], -0.3601502478122711, 1e-12)
	check("camera forward and up stay a unit pair after the basis (|f| = |u| = 1, f.u = 0)", absf(Vector3(jc["forward"][0], jc["forward"][1], jc["forward"][2]).length() - 1.0) + absf(Vector3(jc["up"][0], jc["up"][1], jc["up"][2]).length() - 1.0) + absf(Vector3(jc["forward"][0], jc["forward"][1], jc["forward"][2]).dot(Vector3(jc["up"][0], jc["up"][1], jc["up"][2]))), 0.0, 1e-12)
	# heading the north galactic pole (fallback basis X = -y, Y = +x, Z = +z): ship (a, b, c) is galactic (b, -a, c)
	var jn := ShipFrame.sky_camera(PackedFloat64Array([0.0, 0.0, 1.0]), cj)
	check("cam_bridge.json forward through the NGP-heading basis = (f.y, -f.x, f.z)", absf(jn["forward"][0] - cf[1]) + absf(jn["forward"][1] + cf[0]) + absf(jn["forward"][2] - cf[2]), 0.0, 1e-15)


## M4.2 forward glow (design m4-first-journey.md "M4.2" / "M4.6"; higgs-bubble.md §6, HB-95..HB-112).
## Every expected value is copied from the AILANG probe (tools/glow_probe, make glow-probe:
## sunholo/relativity 0.8.0 at n 0.1 cm^-3, f_in 0.5, VM = interpreter), never computed here;
## e-notation because Godot parses long plain decimals inexactly. eps = 1e-10 (HB-111, the
## D-29 follow-up chosen from renders/glow/eps_compare: the brightest candidate that keeps the
## starbow, the Doppler colours and the CMB disc readable at every speed).
func test_forward_glow() -> void:
	print("Forward glow: ForwardGlow mirrors glowEmittanceAt / glowTemperatureAt / glowLuminanceAt (blackbody, D-30); Lambertian E/pi; the off-centre camera's wall point")
	var mean_099 := 2.407194217926631e-06
	var mean_cap := 0.028127107577632853
	var pole_099 := 9.628776871706523e-06
	var pole_cap := 0.11250843031053141
	var t_099 := 1357.5234659678836
	var t_cap := 14114.023335759706
	check("glow_w_m2 at 0.99c, eps 1e-10 = canon HB-109 2.41e-6", mean_099, 2.41e-06, 5e-09)
	check("glow_w_m2 at 0.999999c = canon HB-110 2.81e-2, <= 1 W/m^2 (HB-61)", mean_cap, 0.0281, 5e-05)
	check("pole = 4 x glow_w_m2 at 0.99c (package)", pole_099 / (4.0 * mean_099), 1.0, 1e-12)
	check("pole at 0.99c = canon HB-102 9.63e-6", pole_099, 9.63e-06, 5e-09)
	check("pole at 0.999999c = canon HB-103 0.1125", pole_cap, 0.1125, 5e-05)
	check("pole temperature at 0.99c = canon HB-96 1,358 K", t_099, 1358.0, 0.5)
	check("pole temperature at 0.999999c = canon HB-98 14,114 K", t_cap, 14114.0, 0.5)
	# [theta, cos theta (probe), glowEmittanceAt at eps 1e-9 (probe; the shape)] at 0.99c and the cap
	var rows := [[0.0, 1.0, 9.628776871706524e-05, 1.1250843031053142], [45.0, 0.7071067811865476, 6.808573420515876e-05, 0.7955547401323088],
		[80.0, 0.17364817766693041, 1.672019556933325e-05, 0.19536883895590618],
		[90.0, 6.123233995736757e-17, 5.895925387819721e-21, 6.889154452844258e-17], [120.0, -0.4999999999999998, 0.0, 0.0]]
	for r: Array in rows:
		for k in 2:
			var pole: float = [9.628776871706524e-05, 1.1250843031053142][k]
			var want: float = r[2 + k]
			var got := ForwardGlow.profile(pole, r[1])
			check("glow_profile %s theta %3.0f deg (rel. to the package, 1e-12)" % [["0.99c", "cap"][k], r[0]], got / want if want != 0.0 else got, 1.0 if want != 0.0 else 0.0, 1e-12)
	# M4.6 R5: the same profile at the sim's eps 1e-10 (the plan quoted 1e-9: the glow is 10x fainter, the shape the same).
	# `runtime/bin/ailang run --quiet --caps IO --package-dir sim --entry main sim/tools/m4_physics_probe.ail`, lines "glow b099|cap theta ...":
	# [theta, cos theta, glowEmittanceAt at 0.99c, glowEmittanceAt at the cap]
	var rows10 := [[0.0, 1.0, 9.628776871706523e-06, 0.11250843031053141], [45.0, 0.7071067811865476, 6.8085734205158745e-06, 0.07955547401323088],
		[80.0, 0.17364817766693041, 1.672019556933325e-06, 0.019536883895590617],
		[90.0, 6.123233995736757e-17, 5.8959253878197215e-22, 6.889154452844258e-18], [120.0, -0.4999999999999998, 0.0, 0.0]]
	for r: Array in rows10:
		for k in 2:
			var pole10: float = [pole_099, pole_cap][k]
			var want10: float = r[2 + k]
			var got10 := ForwardGlow.profile(pole10, r[1])
			check("glow_profile eps 1e-10 %s theta %3.0f deg (rel. to glowEmittanceAt, 1e-12)" % [["0.99c", "cap"][k], r[0]], got10 / want10 if want10 != 0.0 else got10, 1.0 if want10 != 0.0 else 0.0, 1e-12)
	check("glow is 0 at rest (pole 0, any angle)", ForwardGlow.profile(0.0, 0.7), 0.0, 0.0)
	check("Lambertian radiance = E / pi at the 0.99c pole (glowRadianceAt 3.06493e-6)", ForwardGlow.radiance(pole_099) / 3.0649348701220195e-06, 1.0, 1e-12)
	# glowLuminanceAt (probe, eps 1e-10): 7.1437e-8 cd/m^2 at 0.99c, 1.5643 at the cap
	check("luminance at the 0.99c pole = glowLuminanceAt 7.14366e-8 cd/m^2 (1e-7)", ForwardGlow.luminance(pole_099, t_099) / 7.143664288681888e-08, 1.0, 1e-7)
	check("luminance at the cap pole = glowLuminanceAt 1.56432 cd/m^2 (1e-7)", ForwardGlow.luminance(pole_cap, t_cap) / 1.5643160647071177, 1.0, 1e-7)
	check("luminance at the 0.999c pole = glowLuminanceAt 2.61896e-4 cd/m^2 (1e-7)", ForwardGlow.luminance(0.00010757658235978286, 2481.898408081983) / 0.00026189628614000504, 1.0, 1e-7)
	check("efficacy at the 0.99c pole = canon HB-100 0.0233 lm/W", ForwardGlow.efficacy(t_099), 0.0233, 5e-05)
	check("efficacy at the cap pole = canon HB-101 43.7 lm/W", ForwardGlow.efficacy(t_cap), 43.7, 0.05)
	var l_dark := Exposure.dark_sky_luminance()
	check("0.99c pole / the 23.5 mag/arcsec^2 dark sky = canon HB-105 1.65e-3 (faint: the starbow is untouched)", ForwardGlow.luminance(pole_099, t_099) / l_dark, 1.65e-03, 2e-05)
	check("cap pole / the dark sky = canon HB-107 3.61e4", ForwardGlow.luminance(pole_cap, t_cap) / l_dark, 36100.0, 400.0)
	check("0.999c pole / the dark sky ~6 (visible from about 0.997c, HB-112)", ForwardGlow.luminance(0.00010757658235978286, 2481.898408081983) / l_dark, 6.04, 0.1)
	var cam := PackedFloat64Array([16.0, -8.0, 83.7]) # cam_bridge.json position_m (ship frame)
	check("bridge camera straight up: wall cos = sqrt(R^2 - 16^2 - 8^2) / R", ForwardGlow.wall_cos(cam, PackedFloat64Array([0, 0, 1]), 100.0), 0.9838699100999074, 1e-15)
	check("bridge camera, ray straight down: the aft wall (cos < 0, glow 0)", ForwardGlow.profile(1.0, ForwardGlow.wall_cos(cam, PackedFloat64Array([0, 0, -1]), 100.0)), 0.0, 0.0)
	check("finite flux at every stop: pole finite at rest and the cap", 1.0 if is_finite(ForwardGlow.profile(pole_cap, 1.0)) and is_finite(ForwardGlow.profile(0.0, 1.0)) else 0.0, 1.0, 0.0)
	check("finite luminance at rest (T 0) and the cap", 1.0 if ForwardGlow.luminance(0.0, 0.0) == 0.0 and is_finite(ForwardGlow.luminance(pole_cap, t_cap)) else 0.0, 1.0, 0.0)
	# M4.6 R6: finite flux at EVERY stop. The list is the guided voyage, sim/solar_departure.ail legs() (10 legs, HEAD: D-37/D-46/D-47/D-48):
	# seven 0.99c legs (sun, jupiter, callisto, saturn, acen-a, trappist-1, aldebaran), then the star hops at
	# 1 - beta 0.001 (alpha Cen), 1e-4 (TRAPPIST-1), 1e-6 (Aldebaran); plus rest and the guided drive cap (1 - beta 2e-9, GUIDED_DRIVE).
	# [label, pole W/m^2, T_pole K, glowLuminanceAt cd/m^2] from the probe's "stop ..." lines (n 0.1 cm^-3, eps 1e-10, f_in 0.5):
	var stops := [["0.99c legs", pole_099, t_099, 7.143664288681888e-08], ["alpha Cen hop 0.999c", 1.0757658235978293e-04, 2481.8984080819832, 2.618962861400054e-04],
		["TRAPPIST-1 hop 0.9999c", 1.110689450883596e-03, 4448.900845148536, 0.024205822857622995], ["Aldebaran hop 0.999999c", pole_cap, t_cap, 1.5643160647071177],
		["guided cap 1-b 2e-9", 56.3303485183483, 66763.66576978598, 17.67401691969147], ["rest", 0.0, 0.0, 0.0]]
	for st: Array in stops:
		var sp_: float = st[1]
		var sl: float = ForwardGlow.luminance(sp_, st[2])
		var lut: float = ForwardGlow.efficacy_lut(st[2])
		var col: Vector3 = ForwardGlow.colour(st[2])
		var fin := is_finite(sl) and is_finite(lut) and is_finite(col.x) and is_finite(col.y) and is_finite(col.z) and is_finite(ForwardGlow.profile(sp_, 1.0)) and is_finite(ForwardGlow.temperature(st[2], 1.0)) and sl >= 0.0
		check("stop %s: pole, luminance, LUT efficacy and colour are finite" % st[0], 1.0 if fin else 0.0, 1.0, 0.0)
		check("stop %s: luminance = glowLuminanceAt (rel. 1e-7)" % st[0], sl / st[3] if st[3] != 0.0 else sl, 1.0 if st[3] != 0.0 else 0.0, 1e-7)


## The camera cases need a node in a viewport, so they run once the main loop
## has started; everything else runs in _init.

## M5.2a (AC7, photometry half): physics/planets.gd against the pinned package.
## Every expected value is sunholo/celestial 0.1.0 reflect (and relativity
## 0.7.0 illuminanceFromV) as printed by sim/tools/planets_probe.ail; none is
## computed here. Relative tolerance 1e-12 (zeros exactly).
func _m5_photometry() -> void:
	print("M5.2a reflected-light photometry (sunholo/celestial reflect probe)")
	var rel := func(name: String, got: float, want: float) -> void:
		check(name, got / want if want != 0.0 else got, 1.0 if want != 0.0 else 0.0, 1e-12)
	var e1 := Relativity.illuminance_from_v(-26.74)
	var d2r := func(d: float) -> float: return d * 3.141592653589793 / 180.0
	var au := 149597870.7
	rel.call("illuminanceFromV(-26.74) = e1AU 127,057.41 lux", e1, 127057.41052085394)
	rel.call("starIlluminanceAt(e1, 5.2 AU)", Planets.star_illuminance_at(e1, 5.2), 4698.868732280101)
	rel.call("starIlluminanceAt(e1, 0.3871 AU)", Planets.star_illuminance_at(e1, 0.3871), 847917.6145818504)
	rel.call("lambertPhase(0) = 1", Planets.lambert_phase(0.0), 1.0)
	rel.call("lambertPhase(30 deg)", Planets.lambert_phase(d2r.call(30.0)), 0.8808427795789276)
	rel.call("lambertPhase(90 deg) = 1/pi", Planets.lambert_phase(d2r.call(90.0)), 0.3183098861837907)
	rel.call("lambertPhase(150 deg)", Planets.lambert_phase(d2r.call(150.0)), 0.014817375794488915)
	rel.call("minnaertRadiance(0.75, k 1, 1000 lx, 0.6, 0.8) Lambert", Planets.minnaert_radiance(0.75, 1.0, 1000.0, 0.6, 0.8), 143.2394487827058)
	rel.call("minnaertRadiance(0.7071, k 0.825, 1305 lx, 0.6, 0.8)", Planets.minnaert_radiance(0.7071, 0.825, 1305.0, 0.6, 0.8), 200.3897530480214)
	rel.call("minnaertRadiance(0.7071, k 1.2, 1305 lx, 0.3, 0.5)", Planets.minnaert_radiance(0.7071, 1.2, 1305.0, 0.3, 0.5), 60.29495602547271)
	rel.call("minnaertRadiance unlit (cos i -0.1) = 0", Planets.minnaert_radiance(0.7071, 0.825, 1305.0, -0.1, 0.5), 0.0)
	rel.call("minnaertPhase(30 deg, k 0.825) (Simpson 256)", Planets.minnaert_phase(d2r.call(30.0), 0.825), 0.8868218817547876)
	rel.call("minnaertPhase(90 deg, k 0.825)", Planets.minnaert_phase(d2r.call(90.0), 0.825), 0.35370683872336034)
	rel.call("rhoFromGeometricAlbedo(0.538, 1) Jupiter", Planets.rho_from_geometric_albedo(0.538, 1.0), 0.807)
	rel.call("rhoFromGeometricAlbedo(0.499, 0.825) Saturn", Planets.rho_from_geometric_albedo(0.499, 0.825), 0.661175)
	rel.call("discIlluminance Jupiter at opposition, 4.2 AU", Planets.disc_illuminance(e1, 0.538, 71492.0, 5.2, 4.2 * au, 0.0, 1.0), 0.00003272962857913474)
	rel.call("discIlluminance Saturn at 6 deg, 8.6 AU (Minnaert phase)", Planets.disc_illuminance(e1, 0.499, 60268.0, 9.6, 8.6 * au, d2r.call(6.0), 0.825), 0.000001501607259141241)
	rel.call("discIlluminance Moon at quadrature, 384,400 km", Planets.disc_illuminance(e1, 0.12, 1737.4, 1.0, 384400.0, d2r.call(90.0), 1.0), 0.09914350074248762)
	# the disc the shader draws integrates to the package's discIlluminance (CPU, midpoint grid)
	for c: Array in [[0.538, 1.0, 0.0], [0.499, 0.825, 6.0], [0.12, 1.0, 90.0]]:
		var ang := 1e-4
		var lux := Planets.star_illuminance_at(e1, 5.2)
		var want := Planets.disc_illuminance(e1, c[0], ang, 5.2, 1.0, d2r.call(c[2]), c[1])
		var got := Planets.integrate_disc(Planets.rho_from_geometric_albedo(c[0], c[1]), c[1], lux, d2r.call(c[2]), ang, 600)
		check("disc integral of minnaertRadiance / discIlluminance (p %.3f, k %.3f, phase %.0f deg)" % c, got / want, 1.0, 0.003)
	check("limb-darkened Sun (u 0.6): disc mean of L(mu) = the mean it was given", _limb_mean(), 1.0, 1e-4)


func _limb_mean() -> float:
	# area-weighted mean of L(mu) over the disc: integral of 2 r L(sqrt(1 - r^2)) dr
	var s := 0.0
	var n := 20000
	for i in n:
		var r := (i + 0.5) / n
		s += 2.0 * r * Planets.limb_darkened(1.0, sqrt(1.0 - r * r)) / n
	return s

## M3.3 (R1-M3-BLACK-HOLES): Schwarzschild (spec §3). The CPU mirror physics/schwarzschild.gd
## against the spec's RS check values, the package's pinned check41-47 values (sunholo/relativity
## 0.10.0 geodesic_test.ail), and the lens tables (AC-5, AC-8 mirror half, AC-9 CPU half).
func test_schwarzschild() -> void:
	print("Schwarzschild (spec §3)")
	var deg := func(x: float) -> float: return x * PI / 180.0
	# RS-9, RS-21: b_c = 3 sqrt3 / 2, and the tangent ray at the photon sphere has exactly b_c
	check("RS-9 b_c = 3 sqrt(3)/2 (package literal)", Schwarzschild.B_C, 1.5 * sqrt(3.0), 1e-15)
	check("RS-9 b_c = 2.598 r_s", Schwarzschild.B_C, 2.598, 5e-4)
	check("RS-21 photon sphere r = 1.5 r_s", Schwarzschild.PHOTON_SPHERE, 1.5, 0.0)
	check("RS-21 tangent ray at r = 1.5 has b = b_c", Schwarzschild.impact(1.5, PI * 0.5), Schwarzschild.B_C, 1e-14)
	# RS-10..RS-13: Synge's shadow
	for row: Array in [[10.0, 14.269027328, 14.27, "RS-10"], [5.0, 27.694561451, 27.69, "RS-11"], [3.0, 45.0, 45.00, "RS-12"], [1.5, 90.0, 90.0, "RS-13"]]:
		var a := rad_to_deg(Schwarzschild.shadow_angle(row[0]))
		check("%s shadow at %s r_s = %.9f deg" % [row[3], row[0], row[1]], a, row[1], 1e-8)
		check("%s shadow at %s r_s = %s deg (spec rounding)" % [row[3], row[0], row[2]], a, row[2], 0.005)
	# RS-16..RS-20: static observer factor 1/sqrt(1 - 1/r)
	for row: Array in [[10.0, 1.05409255338946, 1.054, "RS-16"], [5.0, 1.11803398874989, 1.118, "RS-17"], [3.0, 1.22474487139159, 1.225, "RS-18"],
			[2.0, sqrt(2.0), 1.414, "RS-19"], [1.5, sqrt(3.0), 1.732, "RS-20"]]:
		check("%s static factor at %s r_s" % [row[3], row[0]], Schwarzschild.static_blueshift(row[0]), row[1], 1e-14)
		check("%s static factor at %s r_s = %s (spec rounding)" % [row[3], row[0], row[2]], Schwarzschild.static_blueshift(row[0]), row[2], 5e-4)
	# The exact form (the mirror's oracle) against the package's pinned values
	check("check41 exact alpha(100) = 0.0202999662395031", Schwarzschild.deflection_from_infinity_exact(100.0), 0.0202999662395031, 1e-12)
	check("check42 exact alpha(1000) = 0.00200295058718769", Schwarzschild.deflection_from_infinity_exact(1000.0), 0.00200295058718769, 1e-12)
	check("RS-14 |alpha(1000)/(2/b) - 1| <= 1 % (measured 0.148 %)", Schwarzschild.deflection_from_infinity_exact(1000.0) / (2.0 / 1000.0) - 1.0, 0.0014753, 1e-6)
	check("RS-15 |alpha(100)/(2/b + 15 pi/16b^2) - 1| <= 3e-4 (measured 2.68e-4)", Schwarzschild.deflection_from_infinity_exact(100.0) / Schwarzschild.weak_deflection2(100.0) - 1.0, 0.0, 3e-4)
	# check44 (50-digit truth; at eps = 1e-8 float64 holds ~1e-9, so 3e-9 there: design doc dated note 2026-10-08)
	for row: Array in [[1e-4, 8.810486354996266, 1e-9], [1e-6, 13.4152855578804, 1e-9], [1e-8, 18.02045076953216, 3e-9]]:
		check("check44 near-critical eps = %s vs the 50-digit truth" % row[0], Schwarzschild.deflection_from_infinity_exact(Schwarzschild.B_C * (1.0 + row[0])), row[1], row[2])
	for row: Array in [[10.0, 0.5, 3.1947588798162605], [3.0, 1.0, 3.4453145251885964], [5.0, 2.0, 1.2969414231071164], [10.0, 0.26, 5.701107605230479]]:
		check("check45 exact azimuth at (r %s, psi %s)" % [row[0], row[1]], Schwarzschild.escape_azimuth_exact(row[0], row[1]), row[2], 1e-12 * row[2])
	# check46 / AC-9 CPU half: Einstein angles to 1e-7 rad
	for row: Array in [[10.0, 29.828317906], [5.0, 44.874561077], [3.0, 61.888756430], [100.0, 8.520443413], [1000.0, 2.604361342]]:
		check("check46 AC-9 Einstein angle at r = %s: %.9f deg (rad, 1e-7)" % row, Schwarzschild.einstein_angle(row[0]), deg.call(row[1]), 1e-7)
	check("check46 Einstein angle at r = 10 = 0.5206023577867371 (package, 1e-12)", Schwarzschild.einstein_angle(10.0), 0.5206023577867371, 1e-12)
	# check47: images and magnifications, exact form
	for row: Array in [[10.0, 20.0, 39.837659068, 23.543122070, 1.118821, 0.276451], [1000.0, 1.0, 3.144406661, 2.160968686, 1.847367, 0.856138]]:
		for order in 2:
			var psi := Schwarzschild.image_angle_exact(row[0], deg.call(row[1]), order)
			check("check47 r %s beta %s deg: order-%d image (exact, rad)" % [row[0], row[1], order], psi, deg.call(row[2 + order]), 1e-7)
			check("check47 r %s beta %s deg: order-%d mu (exact, rel)" % [row[0], row[1], order], Schwarzschild.image_magnification_exact(row[0], psi) / row[4 + order], 1.0, 1e-4)
	_schwarzschild_tables(deg)


func _schwarzschild_tables(deg: Callable) -> void:
	print("Schwarzschild lens tables (data/lens, M3.2; AC-5)")
	var ok := Schwarzschild.load_tables()
	check("lens tables load, sizes and header sha256 match (%s)" % Schwarzschild.load_error, 1.0 if ok else 0.0, 1.0, 0.0)
	if not ok:
		return
	for t in ["fwd", "inv"]:
		var hdr: Dictionary = Schwarzschild.headers[t]
		var bin := "res://data/lens/lens_%s.bin" % t
		check("lens_%s header sha256 = sha256 of the bin" % t, 1.0 if FileAccess.get_sha256(bin) == hdr["sha256"]["bin"] else 0.0, 1.0, 0.0)
		check("lens_%s header: package sunholo/relativity 0.10.0" % t, 1.0 if hdr["package"]["version"] == "0.10.0" else 0.0, 1.0, 0.0)
		check("lens_%s header row y range = [ln 0.5, ln(1e6 - 1.5)]" % t, absf(float(hdr["row"]["min"]) - log(0.5)) + absf(float(hdr["row"]["max"]) - log(1e6 - 1.5)), 0.0, 1e-15)
	check("lens_fwd header column x_min = ln 1e-8, h = 0.0025", absf(float(Schwarzschild.headers["fwd"]["column"]["min"]) - log(1e-8)) + absf(float(Schwarzschild.headers["fwd"]["generator"]["h"]) - 0.0025), 0.0, 1e-15)
	check("row 0 is r = 2, row 255 is r = 1e6", absf(Schwarzschild.row_radius(0) - 2.0) + absf(Schwarzschild.row_radius(255) - 1e6), 0.0, 0.0)
	# every texel finite (both tables); lens_inv strictly monotone in F in every row, slope > 0
	var nonfinite := 0
	for tab: PackedFloat32Array in [Schwarzschild.fwd_table(), Schwarzschild.inv_table()]:
		for v in tab:
			if is_nan(v) or is_inf(v):
				nonfinite += 1
	check("every texel of lens_fwd and lens_inv is finite (2 x 1,048,576)", nonfinite, 0.0, 0.0)
	var inv := Schwarzschild.inv_table()
	var bad_rows := 0
	for j in Schwarzschild.N_ROWS:
		var prev := -INF
		for i in Schwarzschild.N_COLS:
			var k := (j * Schwarzschild.N_COLS + i) * 2
			if not (inv[k] > prev) or not (inv[k + 1] > 0.0):
				bad_rows += 1
				break
			prev = inv[k]
	check("lens_inv: psi - alpha_sh strictly increasing in F, dpsi/dF > 0, in all 256 rows", bad_rows, 0.0, 0.0)
	# AC-5: 10k deterministic probes (Weyl sequences), table vs exact form
	var worst_lo := 0.0
	var worst_hi := 0.0
	var worst_abs_tiny := 0.0
	var n_lo := 0
	var n_tiny := 0
	for k in 10000:
		var u := fmod(0.5 + k * 0.6180339887498949, 1.0)
		var v := fmod(0.5 + k * 0.7548776662466927, 1.0)
		var r := 1.5 + exp(log(0.5) + (log(1e6 - 1.5) - log(0.5)) * u)
		var a := Schwarzschild.shadow_angle(r)
		var x := log(1e-8) + (Schwarzschild.row_x_max(r) - log(1e-8)) * v
		var psi := minf(a + a * exp(x), PI)
		var exact := Schwarzschild.deflection_exact(r, psi)
		var err := absf(Schwarzschild.deflection(r, psi) - exact)
		if r <= 100.0:
			n_lo += 1
			worst_lo = maxf(worst_lo, err)
		elif absf(exact) >= 1e-5:
			worst_hi = maxf(worst_hi, err / absf(exact))
		else:
			# within ~1e-3 rad of the antipode delta -> 0, and a relative error of a vanishing
			# delta is meaningless: there the bound is absolute (design AC-5 note, 2026-10-08)
			n_tiny += 1
			worst_abs_tiny = maxf(worst_abs_tiny, err)
	print("        10k probes: %d at r <= 100, worst %s rad; %d above with delta >= 1e-5, worst %s relative; %d with delta < 1e-5, worst %s rad" % [n_lo, String.num_scientific(worst_lo), 10000 - n_lo - n_tiny, String.num_scientific(worst_hi), n_tiny, String.num_scientific(worst_abs_tiny)])
	check("AC-5 table vs exact, r <= 100: worst |delta error| <= 1.2e-4 rad", worst_lo, 0.0, 1.2e-4)
	check("AC-5 table vs exact, r > 100, delta >= 1e-5: worst relative error <= 1e-3", worst_hi, 0.0, 1e-3)
	check("AC-5 table vs exact, r > 100, delta < 1e-5 (near the antipode): worst error <= 1e-8 rad", worst_abs_tiny, 0.0, 1e-8)
	# AC-5: the r = 1e6 row hands off to weakDeflectionFinite to 1e-3 relative
	var worst_w := 0.0
	for psi: float in [0.01, 0.1, 0.5, 1.0, 2.0, 3.0]:
		worst_w = maxf(worst_w, absf(Schwarzschild.deflection(1e6, psi) / Schwarzschild.weak_deflection_finite(1e6, psi) - 1.0))
	check("AC-5 r = 1e6 row vs weakDeflectionFinite (psi 0.01..3): relative", worst_w, 0.0, 1e-3)
	for wk: Array in [[2e6, 0.5], [3e6, 0.01], [1.5e6, 3.0]]:
		check("M3.6 weak_k(r) cot(psi/2) == weakDeflectionFinite (r %d, psi %s), the shader gr_weak_k" % [int(wk[0]), wk[1]], Schwarzschild.weak_k(wk[0]) / tan(wk[1] / 2.0), Schwarzschild.weak_deflection_finite(wk[0], wk[1]), 1e-12 * Schwarzschild.weak_deflection_finite(wk[0], wk[1]))
	check("beyond r = 1e6 the weak branch is used (r = 2e6, psi 0.5)", Schwarzschild.deflection(2e6, 0.5), Schwarzschild.weak_deflection_finite(2e6, 0.5), 0.0)
	# AC-8 mirror half: the weak-field pair on the r -> infinity row (r = 1e6)
	for row: Array in [[1000.0, "RS-14 / AC-8: r = 1e6 row, b = 1000: |delta/(2/b) - 1| <= 1 %", 0.01, 2.0 / 1000.0], [100.0, "RS-15 / AC-8: r = 1e6 row, b = 100: |delta/(2/b + 15 pi/16 b^2) - 1| <= 3e-4", 3e-4, Schwarzschild.weak_deflection2(100.0)]]:
		var psi := asin(row[0] * sqrt(1.0 - 1e-6) / 1e6)
		check(row[1], Schwarzschild.deflection(1e6, psi) / row[3] - 1.0, 0.0, row[2])
	# AC-9 / check46 from the tables: a star exactly behind the hole images at psi_E
	for row: Array in [[10.0, 29.828317906], [5.0, 44.874561077], [3.0, 61.888756430], [100.0, 8.520443413], [1000.0, 2.604361342]]:
		check("check46 table Einstein angle at r = %s (lens_inv, rad, 1.2e-4)" % row[0], Schwarzschild.image(row[0], 0.0, 0)["psi"], deg.call(row[1]), 1.2e-4)
	for row: Array in [[10.0, 20.0, 39.837659068, 23.543122070, 1.118821, 0.276451], [1000.0, 1.0, 3.144406661, 2.160968686, 1.847367, 0.856138]]:
		for order in 2:
			var im := Schwarzschild.image(row[0], deg.call(row[1]), order)
			check("check47 table r %s beta %s: order-%d image (rad, 1.2e-4)" % [row[0], row[1], order], im["psi"], deg.call(row[2 + order]), 1.2e-4)
			check("check47 table r %s beta %s: order-%d mu (1 %%)" % [row[0], row[1], order], im["mu"] / row[4 + order], 1.0, 0.01)
	_schwarzschild_maps()


func _schwarzschild_maps() -> void:
	print("Schwarzschild lens maps (lens_direction, star_images, compose)")
	var h := Vector3(0, 0, -1)
	# captured inside the shadow, straight through at the antipode
	check("a ray at psi < alpha_sh is captured (r 5)", 1.0 if Schwarzschild.lens_direction(Vector3(sin(0.4), 0, -cos(0.4)), h, 5.0)["captured"] else 0.0, 1.0, 0.0)
	var out: Vector3 = Schwarzschild.lens_direction(-h, h, 5.0)["n_inf"]
	check("the outward radial ray (psi = pi) is undeflected", out.distance_to(-h), 0.0, 1e-6)
	# round trip: 1,000 deterministic (r, beta), both images map back onto the source
	var worst := 0.0
	var worst_img := 0.0
	var tested := 0
	var faint := 0
	for k in 1000:
		var u := fmod(0.5 + k * 0.6180339887498949, 1.0)
		var v := fmod(0.5 + k * 0.7548776662466927, 1.0)
		var w := fmod(0.5 + k * 0.5698402909980532, 1.0)
		var r := 1.5 + exp(log(0.5) + (log(1e6 - 1.5) - log(0.5)) * u)
		var beta := 0.01 + (PI - 0.02) * v
		var az := TAU * w
		var n_src := (h * cos(beta) + (Vector3(cos(az), sin(az), 0.0)) * sin(beta)).normalized()
		for im: Dictionary in Schwarzschild.star_images(n_src, h, r):
			var back: Dictionary = Schwarzschild.lens_direction(im["dir_static"], h, r)
			var err := INF if back["captured"] else Schwarzschild.angle(back["n_inf"], n_src)
			# the same miss seen in the image plane: source-plane error x dpsi/dF at the image
			var psi := Schwarzschild.angle(im["dir_static"], h)
			var slope: float = Schwarzschild.image(r, beta, im["order"])["slope"]
			worst_img = maxf(worst_img, err * absf(slope))
			if absf(slope) >= 1e-3:
				worst = maxf(worst, err)
			else:
				faint += 1 # deep edge images, demagnified > 1000x: dF/dpsi amplifies a 1e-10 rad image error
			tested += 1
	check("round trip in the source plane: lens_direction(star_images(n)) = n, %d images with dpsi/dF >= 1e-3 (rad, 2e-4)" % (tested - faint), worst, 0.0, 2e-4)
	check("round trip in the image plane: all %d images of 1,000 (r, beta) incl. %d deep-edge ones (rad, 2e-4)" % [tested, faint], worst_img, 0.0, 2e-4)
	# compose: at rest it is the lens map with D = static blueshift; moving, D = D_g D_SR
	var n := Vector3(0.3, 0.2, -0.9).normalized()
	var c0 := Schwarzschild.compose(n, h, 10.0, Vector3.RIGHT, 0.0)
	check("compose at rest: n_inf = lens_direction", (c0["n_inf"] as Vector3).distance_to(Schwarzschild.lens_direction(n, h, 10.0)["n_inf"]), 0.0, 1e-7)
	check("compose at rest: D = 1/sqrt(1 - 1/r) at r = 10", c0["D"], 1.05409255338946, 1e-12)
	var bo := 0.35355339059327373 # circular orbit speed at r = 5 (check49)
	var c1 := Schwarzschild.compose(n, h, 5.0, Vector3.RIGHT, bo)
	check("compose in orbit: D = D_g x D_SR", c1["D"], Schwarzschild.static_blueshift(5.0) * Relativity.doppler_apparent(n, Vector3.RIGHT, bo), 1e-12)
	check("compose in orbit: the static view is the de-aberrated ray", (c1["n_static"] as Vector3).distance_to(Relativity.deaberrate(n, Vector3.RIGHT, bo)), 0.0, 1e-7)
	_schwarzschild_gpu_handoff()


## M3.5a/b: what the CPU hands the shaders (sky/gr_lens.gd), and the CPU halves of the GPU paths.
func _schwarzschild_gpu_handoff() -> void:
	print("Schwarzschild GPU hand-off (M3.5a/b)")
	var f32 := func(v: float) -> float: return PackedFloat32Array([v])[0]
	var worst := 0.0
	var hi_exact := true
	for r in [2.0, 2.05, 3.0, 5.0, 10.0, 1000.0, 1e6, 2e6]:
		var a := Schwarzschild.shadow_angle(r)
		var p := Schwarzschild.hi_lo(a)
		worst = maxf(worst, absf((p[0] + p[1]) - a))
		hi_exact = hi_exact and p[0] == f32.call(p[0]) and p[1] == f32.call(p[1])
	check("alpha_sh as a float32 hi/lo pair reconstructs to 1e-12 (r 2 .. 2e6; plan review N-2)", worst, 0.0, 1e-12)
	check("both halves of the pair are float32 values (what a uniform holds)", 1.0 if hi_exact else 0.0, 1.0, 0.0)
	var lim := 0.0
	for t in [3000.0, 5700.0, 20000.0]:
		for d in [0.5, 1.0, 2.0]:
			lim = maxf(lim, absf(Schwarzschild.image_flux_ratio(1.0, t, 1.0, d) / Relativity.point_flux_ratio(t, d) - 1.0))
	check("star image flux: mu = 1, D_g = 1 is point_flux_ratio(T, D_SR) exactly (M3.5b)", lim, 0.0, 1e-15)
	check("star image flux scales with mu and colours at D_g D_SR", Schwarzschild.image_flux_ratio(2.0, 5700.0, 1.22474487139159, 1.0), 2.0 * Relativity.surface_brightness_ratio(5700.0, 1.22474487139159), 1e-12)
	for r in [3.0, 10.0, 1000.0]:
		var cones := Schwarzschild.ring_cones(r)
		var bn := cones[0]
		var bf := cones[1]
		var inside := maxf(Schwarzschild.image_stretch(r, 0.99 * bn, 0), Schwarzschild.image_stretch(r, 0.99 * bn, 1))
		var outside := maxf(Schwarzschild.image_stretch(r, 1.01 * bn, 0), Schwarzschild.image_stretch(r, 1.01 * bn, 1))
		check("ring cone at r = %s: stretch > 8 just inside beta_near = %.4f deg, < 8 just outside" % [r, rad_to_deg(bn)], 1.0 if inside > 8.0 and outside < 8.0 else 0.0, 1.0, 0.0)
		check("ring cone at r = %s: the order-1 photon-ring cone beta > 180 - %.4f deg holds stretch > 8" % [r, rad_to_deg(bf)], 1.0 if Schwarzschild.image_stretch(r, PI - 0.99 * bf, 1) > 8.0 and Schwarzschild.image_stretch(r, PI - 1.01 * bf, 1) < 8.0 else 0.0, 1.0, 0.0)
		check("ring cones lie inside asin(1/8) (GrLens.CONE is a superset)", 1.0 if maxf(bn, bf) < asin(0.125) and asin(0.125) < GrLens.CONE else 0.0, 1.0, 0.0)
	# the uniforms: only the sim's numbers and the mirror's per-r scalars
	var st := GrLens.reference_state(10.0, PackedFloat64Array([1.0, 0.0, 0.0]))
	var u := GrLens.uniforms(st)
	check("uniforms: gr_x_max is the row's last column ln((pi - alpha)/alpha)", u["gr_x_max"], Schwarzschild.row_x_max(10.0), 1e-15)
	check("uniforms: gr_row is the mirror's fractional row", u["gr_row"], Schwarzschild.row_coordinate(10.0), 0.0)
	check("uniforms: gr_dg is the state's blueshift", u["gr_dg"], 1.05409255338946, 1e-12)
	check("uniforms: gr_h, the hole at galactic +x, is world -Z", (u["gr_h"] as Vector3).distance_to(Vector3(0, 0, -1)), 0.0, 1e-7)
	var uw := GrLens.uniforms(GrLens.reference_state(2e6, PackedFloat64Array([1.0, 0.0, 0.0])))
	check("uniforms: beyond r = 1e6 the weak branch, k = sqrt(1 - 1/r)/r", (1.0 if uw["gr_weak"] and not u["gr_weak"] else 0.0) + uw["gr_weak_k"] * 2e6, 1.0 + sqrt(1.0 - 0.5e-6), 1e-15)
	# derivation check (not a shader check; GR10/GR12 test the shader): rule 2's sine-ratio form
	# used in sky/schwarzschild.gdshaderinc equals the cot-difference weight
	var wmax := 0.0
	for psi in [0.3, 1.0, 2.0, 3.0, 3.14]:
		var p0: float = psi - 0.004
		var p1: float = psi + 0.003
		var cot := func(x: float) -> float: return 1.0 / tan(0.5 * x)
		var w_cot: float = (cot.call(psi) - cot.call(p0)) / (cot.call(p1) - cot.call(p0))
		var w_sin: float = (sin(0.5 * (psi - p0)) / sin(0.5 * psi)) / (sin(0.5 * (p1 - p0)) / sin(0.5 * p1))
		wmax = maxf(wmax, absf(w_cot - w_sin))
	check("derivation: sin((psi - psi0)/2)/sin(psi/2) over sin((psi1 - psi0)/2)/sin(psi1/2) = the cot(psi/2) weight", wmax, 0.0, 1e-9)


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
	test_scripts_compile()
	test_sky_meter()
	test_forward_glow()
	test_ship_frame()
	test_sky_frame()
	_m5_photometry()
	test_schwarzschild()

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
	check("l = 90 deg (world -X, port) sits a quarter in from the left (l grows leftward)", SkyModel.equirect_uv(Vector3(-1, 0, 0)).x, 0.25, 1e-9)
	check("l = 270 deg (world +X, starboard) sits at u = 0.75", SkyModel.equirect_uv(Vector3(1, 0, 0)).x, 0.75, 1e-9)
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

