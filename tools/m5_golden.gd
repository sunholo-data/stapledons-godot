extends RefCounted
## M5 planet goldens and reference renders (make golden / make golden-m5 /
## make capture-m5a; gate 2). main.gd loads this by path (tools/ is not exported).
##   G-M5-4  Jupiter at opposition, ~200 px across, linear tonemapper on black:
##           the disc's integrated illuminance (sum of pixel luminance / k x each
##           pixel's pinhole solid angle) equals the package's discIlluminance
##           within 2%, uniform albedo and (when fetched) the normalised texture;
##           the disc's centroid lands within 0.75 px of the camera projection.
##   G-M5-6  point/disc handoff: the same body at 1.9 px (a starfield point) and
##           2.1 px (a supersampled disc): integrated flux / e_v_lux agree within 2%.
## Bodies are fed to SystemView as `system` dictionaries with every sim field,
## so the goldens drive exactly the path the game uses.

const FIXTURE := "res://tests/fixtures/system_sol.ndjson"
const E1 := 127057.41052085394 # relativity illuminanceFromV(-26.74), the sim's Sun at 1 AU (probe)
const AU := 149597870.7
const R_JUP := 71492.0


func run(main: Node) -> int:
	var sv := _setup(main, false)
	var failures := 0
	failures += await _opposition(main, sv, false)
	sv.queue_free()
	var tex := SystemView.new()
	tex.setup(main.starfield, true)
	main.add_child(tex)
	if not tex._textures("jupiter").is_empty():
		failures += await _opposition(main, tex, true)
	else:
		print("skip  G-M5-4 textured Jupiter: textures not fetched (make planet-assets)")
	tex.queue_free()
	sv = _setup(main, false)
	failures += await _crossover(main, sv)
	sv.queue_free()
	main.starfield.clear_point_sources()
	print("m5 golden: %d failures" % failures)
	return failures


func _setup(main: Node, textures: bool) -> SystemView:
	var env: Environment = main.env
	env.background_mode = Environment.BG_COLOR # drop any sky: a pixel is the planet alone
	env.background_color = Color.BLACK
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.glow_enabled = false
	if main.starfield.multimesh == null: # --golden-m5 runs before any tier is loaded
		main.starfield.build()
	main.starfield.set_custom_stars([])
	main.starfield.set_ship_position(0.0, 0.0, 0.0)
	main.starfield.set_velocity(Vector3(0, 0, -1), 0.0, 1.0)
	main.starfield.set_floor(Vector2.ZERO)
	main.camera.look(0.0, 0.0, 0.0)
	main._configure_pixel()
	var sv := SystemView.new()
	sv.setup(main.starfield, textures)
	main.add_child(sv)
	return sv


## A body straight ahead (galactic +x = world -Z) at d km, lit from behind the camera.
static func body(id: String, radius: float, d: float, p_v: float, k: float, alpha_deg := 0.0) -> Dictionary:
	var a := deg_to_rad(alpha_deg)
	return {"id": id, "name": id, "kind": "planet", "host": "", "status": "confirmed",
		"rel_km": {"x": d, "y": 0.0, "z": 0.0}, "radius_km": radius, "flattening": 0.0,
		"pole": {"x": 0.0, "y": 0.0, "z": 1.0}, "w_deg": 0.0,
		"sun_dir": {"x": -cos(a), "y": sin(a), "z": 0.0}, "r_au": 5.2, "phase_deg": alpha_deg,
		"e_v_lux": Planets.disc_illuminance(E1, p_v, radius, 5.2, d, a, k), "p_v": p_v, "minnaert_k": k,
		"ring_id": "", "light_age_s": 0.0, "visitable": true, "source": "golden"}


static func section(bodies: Array) -> Dictionary:
	return {"jd": 2460251.5, "ephemeris": "jpl-approx", "frame": "galactic", "bodies": bodies}


## Linear luminance x pinhole solid angle summed over the frame, / k: lux.
func _integrated(main: Node, img: Image, k: float) -> float:
	var size := Vector2(img.get_width(), img.get_height())
	var f: float = 0.5 * size.y / tan(deg_to_rad(main.camera.fov) * 0.5)
	var e := 0.0
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.r == 0.0 and c.g == 0.0 and c.b == 0.0:
				continue
			c = c.srgb_to_linear()
			var u := (x + 0.5 - size.x / 2.0) / f
			var v := (y + 0.5 - size.y / 2.0) / f
			e += (0.2126729 * c.r + 0.7151522 * c.g + 0.0721750 * c.b) / pow(1.0 + u * u + v * v, 1.5) / (f * f)
	return e / k


func _opposition(main: Node, sv: SystemView, textured: bool) -> int:
	# A 1 deg view (Camera3D's minimum): 200 px across is then a 0.37 deg globe. The shader draws
	# the exact finite-distance view (converging rays, sunlight parallel), whose disc integral
	# exceeds discIlluminance's far-field (R/d)^2 form by about 1.5 R/d: +1.2% at 0.9 deg
	# (measured at 5 deg), +19% for a 30 deg globe (the same 200 px at 70 deg).
	var fov0: float = main.camera.fov
	main.camera.fov = 1.0
	main._configure_pixel()
	var size: Vector2 = main.get_viewport().get_texture().get_size()
	var px_rad: float = main.exposure.pixel_rad
	sv.set_view(px_rad, size.y)
	var d := R_JUP / sin(100.0 * px_rad) # 200 px across
	var b := body("jupiter", R_JUP, d, 0.538, 1.0)
	var rho := Planets.rho_from_geometric_albedo(0.538, 1.0)
	var k := 0.6 / (rho * Planets.star_illuminance_at(E1, 5.2) / PI) / (2.0 if textured else 1.0) # disc-centre radiance -> linear 0.6
	# textured: an equatorial view (the table's normalisation is the rotational mean there) at
	# four rotations, as Jupiter's disc-integrated albedo varies +-2.5% with longitude (the GRS)
	var spins := [10.0, 100.0, 190.0, 280.0] if textured else [0.0]
	var got := 0.0
	var img: Image
	for w: float in spins:
		b["w_deg"] = w
		sv.update(section([b]), k)
		img = await main._grab()
		got += _integrated(main, img, k) / spins.size()
	var want: float = b["e_v_lux"]
	var expected: Vector2 = main.camera.project(Vector3(0, 0, -1), size)
	var centroid: Vector2 = main._centroid(img)
	var err := centroid.distance_to(expected)
	# the lit extent along the centre row and column = the pinhole diameter 2 f tan(asin(R/d)) within 1 px (an unclipped disc)
	var f: float = 0.5 * size.y / tan(deg_to_rad(main.camera.fov) * 0.5)
	var want_w := 2.0 * f * tan(asin(R_JUP / d))
	var w_row := _extent(img, true)
	var w_col := _extent(img, false)
	main.camera.fov = fov0
	main._configure_pixel()
	# the centroid is a geometry check on the uniform disc (a texture's bands move the light-weighted centre)
	var ok := absf(got / want - 1.0) < 0.02 and (textured or (err < 0.75 and absf(w_row - want_w) < 1.0 and absf(w_col - want_w) < 1.0))
	print("%s  G-M5-4 Jupiter at opposition (%s, %.0f px across): integrated %s lux, discIlluminance %s (ratio %.4f, limit 2%%); centroid (%.2f, %.2f) expected (%.2f, %.2f) error %.3f px; extent %.2f x %.2f px, pinhole %.2f px" % [
		"ok  " if ok else "FAIL", "normalised texture, mean of 4 rotations" if textured else "uniform p_V", Planets.diameter_px(R_JUP, d, px_rad), String.num_scientific(got), String.num_scientific(want), got / want, centroid.x, centroid.y, expected.x, expected.y, err, w_row, w_col, want_w])
	return 0 if ok else 1


## Lit extent through the frame centre (row or column), in pixels, with sub-pixel
## edges from the covered fraction (alpha) of the two edge pixels.
func _extent(img: Image, row: bool) -> float:
	var n := img.get_width() if row else img.get_height()
	var c := (img.get_height() if row else img.get_width()) / 2
	var peak := 0.0
	var vals := PackedFloat64Array()
	for i in n:
		var p := img.get_pixel(i, c) if row else img.get_pixel(c, i)
		vals.append(p.srgb_to_linear().get_luminance())
	var first := -1
	var last := -1
	for i in n:
		if vals[i] > 0.0:
			last = i
			if first < 0:
				first = i
	return 0.0 if first < 0 else float(last - first + 1)


func _crossover(main: Node, sv: SystemView) -> int:
	var size: Vector2 = main.get_viewport().get_texture().get_size()
	var e: Exposure = main.exposure
	sv.set_view(e.pixel_rad, size.y)
	var ratios := []
	for px: float in [1.9, 2.1]:
		var d := R_JUP / sin(px * e.pixel_rad / 2.0)
		var b := body("jupiter", R_JUP, d, 0.538, 1.0)
		var lux: float = b["e_v_lux"]
		var k := 1.5 * e.pixel_sr / lux # integrated value E k / Omega_px = 1.5: peaks ~0.5, nothing clips
		main.starfield.set_exposure(k / (TAU * e.psf_sigma_rad() * e.psf_sigma_rad()))
		main.starfield.set_psf(e.psf_sigma_px())
		sv.update(section([b]), k)
		var img: Image = await main._grab()
		var got := _integrated(main, img, k)
		ratios.append(got / lux)
		print("      G-M5-6 %.1f px as a %s: integrated %s lux, e_v_lux %s (ratio %.4f)" % [px, "disc" if sv.drawn_discs.has("jupiter") else "point", String.num_scientific(got), String.num_scientific(lux), got / lux])
	var ok: bool = absf(ratios[1] / ratios[0] - 1.0) < 0.02 and absf(ratios[0] - 1.0) < 0.03 and absf(ratios[1] - 1.0) < 0.03
	print("%s  G-M5-6 point/disc handoff: flux / e_v_lux at 1.9 px (point) %.4f, 2.1 px (disc) %.4f, agree within %.2f%% (limit 2%%)" % ["ok  " if ok else "FAIL", ratios[0], ratios[1], 100.0 * absf(ratios[1] / ratios[0] - 1.0)])
	return 0 if ok else 1


## Entry from main.gd: `--golden-m5` (these goldens alone) or `--capture-m5=DIR`.
func main(host: Node, args: Dictionary) -> int:
	if args.has("golden-m5"):
		return 1 if await run(host) > 0 else 0
	return await capture(host, host._out_dir(args["capture-m5"] if args["capture-m5"] != "" else "renders/m5/m5.2a"))


# ------------------------------------------------------------ reference renders (gate 2)
## The production chain (AgX + glow, the sky panorama when bundled, the star
## tier): the sim's recorded Sol bodies (pole, W, sun direction, p_V, k at
## jd 2460251.5) seen from vantage points the sim cannot fly to until M5.5, each
## re-lit for that vantage with the package mirror (phase, discIlluminance).
## Each globe is exposed so its brightest radiance sits at linear 0.8 (a
## photographer's exposure, labelled per image); jupiter_eye.png is the same
## view in the default EYE mode, which does not meter planets until M5.4.
const SHOTS := [["jupiter", 8.0, 12.0], ["saturn", 7.0, 40.0], ["earth", 4.0, 50.0], ["moon", 6.0, 90.0],
	["mars", 6.0, 25.0], ["venus", 5.0, 60.0], ["mercury", 6.0, 70.0], ["uranus", 8.0, 20.0], ["neptune", 8.0, 15.0]]


func capture(main: Node, out: String) -> int:
	DirAccess.make_dir_recursive_absolute(out)
	if not main.load_stars(""):
		return 2
	var bodies := _fixture_bodies()
	var sv: SystemView = main.system_view
	var e: Exposure = main.exposure
	var size: Vector2 = main.get_viewport().get_texture().get_size()
	sv.set_view(e.pixel_rad, size.y)
	var tiles := []
	for shot: Array in SHOTS:
		var b := vantage(bodies[shot[0]], shot[1], shot[2])
		var lux := Planets.star_illuminance_at(E1, b["r_au"])
		var peak := Planets.rho_from_geometric_albedo(b["p_v"], b["minnaert_k"]) * lux / PI * 2.0 # textures reach ~2x their mean
		_aim(main, b)
		e.fixed = true
		e.fixed_ev = log(peak / 0.8 / Exposure.SAT) / log(2.0)
		e.update(Exposure.dark_sky_luminance())
		main._push_exposure()
		sv.update(section([b]), e.k())
		var img: Image = await main._grab()
		var name := "%s_phase%d.png" % [shot[0], roundi(b["phase_deg"])]
		img.save_png(out.path_join(name))
		tiles.append(img)
		print("captured %s  %s from %.0f radii, phase %.1f deg, %.1f px across, EV %+.2f fixed for the globe (%s)" % [name, shot[0], shot[1], b["phase_deg"], Planets.diameter_px(b["radius_km"], shot[1] * b["radius_km"], e.pixel_rad), e.ev, "textured" if sv.albedo_table.has(shot[0]) and not sv._textures(shot[0]).is_empty() else "uniform albedo"])
	# the same Jupiter view in the default EYE mode (dark-adapted, pinned at EV_dark: the disc clips, stars stay)
	var jb := vantage(bodies["jupiter"], 8.0, 12.0)
	_aim(main, jb)
	e.fixed = false
	e.mode = Exposure.Mode.EYE
	e.update(Exposure.dark_sky_luminance(), main._meter_eye_now(0.0))
	main._push_exposure()
	sv.update(section([jb]), e.k())
	var eye: Image = await main._grab()
	eye.save_png(out.path_join("jupiter_eye.png"))
	print("captured jupiter_eye.png  EYE mode EV %+.2f %s (planets are not metered until M5.4)" % [e.ev, e.state_name()])
	tiles.append(eye)
	tiles.append(await _sun(main, sv, out))
	tiles.append(await _crossover_shot(main, sv, out))
	main._save_sheet(tiles, 4, out.path_join("m5_2a_sheet.png"))
	print("captured m5_2a_sheet.png (%d tiles)" % tiles.size())
	main.starfield.clear_point_sources()
	return 0


func _fixture_bodies() -> Dictionary:
	var out := {}
	for line in FileAccess.get_file_as_string(FIXTURE).split("\n"):
		var m = JSON.parse_string(line) if line.strip_edges() != "" else null
		if typeof(m) == TYPE_DICTIONARY and m.get("type") == "state" and m["changes"].has("system"):
			for b: Dictionary in SimBridge.parse_system(m["changes"]["system"])["bodies"]:
				out[b["id"]] = b
			return out
	return out


## The body seen from radii x R away at phase angle alpha (deg): the observer
## direction is the sun direction turned by alpha about the body's pole (the
## sun to the side, the pole up), and the phase is the angle that results.
static func vantage(b: Dictionary, radii: float, alpha_deg: float) -> Dictionary:
	var s := Vector3(b["sun_dir"]["x"], b["sun_dir"]["y"], b["sun_dir"]["z"]).normalized()
	var o := s.rotated(Vector3(b["pole"]["x"], b["pole"]["y"], b["pole"]["z"]).normalized(), deg_to_rad(alpha_deg))
	var alpha := acos(clampf(s.dot(o), -1.0, 1.0))
	var d: float = radii * b["radius_km"]
	var v := b.duplicate(true)
	v["rel_km"] = {"x": -o.x * d, "y": -o.y * d, "z": -o.z * d}
	v["phase_deg"] = rad_to_deg(alpha)
	v["e_v_lux"] = Planets.disc_illuminance(E1, b["p_v"], b["radius_km"], b["r_au"], d, alpha, b["minnaert_k"])
	return v


## Look at the body, rolled so its north pole points up the screen.
func _aim(main: Node, b: Dictionary) -> void:
	var w := Planets.world_of(b["rel_km"])
	var d := Planets.length64(w)
	var cam: FreeLookCamera = main.camera
	cam.look(atan2(-w[0] / d, -w[2] / d), asin(w[1] / d), 0.0)
	var p := Starfield.galactic_to_world(Vector3(b["pole"]["x"], b["pole"]["y"], b["pole"]["z"]))
	var pc: Array = cam._to_camera(p.x, p.y, p.z)
	cam.look(cam.yaw, cam.pitch, atan2(pc[1], pc[0]) - PI / 2.0)


## The Sun from 0.05 AU (10.7 deg across): limb-darkened, exposed for the disc
## centre here; in play it is clipped at linear 1024 until row 6b's glare pass.
func _sun(main: Node, sv: SystemView, out: String) -> Image:
	var e: Exposure = main.exposure
	var d := 0.05 * AU
	var sun := {"id": "sun", "name": "Sun", "kind": "star", "host": "", "status": "star", "rel_km": {"x": d * 0.8, "y": d * 0.6, "z": 0.0},
		"radius_km": 695700.0, "flattening": 0.0, "pole": {"x": 0.0, "y": 0.0, "z": 1.0}, "w_deg": 0.0, "sun_dir": {"x": 0.0, "y": 0.0, "z": 0.0},
		"r_au": 0.0, "phase_deg": 0.0, "e_v_lux": Planets.star_illuminance_at(E1, 0.05), "p_v": 0.0, "minnaert_k": 1.0, "ring_id": "",
		"light_age_s": 0.0, "visitable": false, "source": "golden"}
	var ang := Planets.angular_radius(695700.0, d)
	var mean: float = sun["e_v_lux"] / (PI * sin(ang) * sin(ang))
	_aim(main, sun)
	e.fixed = true
	e.fixed_ev = log(Planets.limb_darkened(mean, 1.0) / 0.25 / Exposure.SAT) / log(2.0) # centre at linear 0.25: the limb darkening stays inside AgX
	e.update(Exposure.dark_sky_luminance())
	main._push_exposure()
	sv.update(section([sun]), e.k())
	var img: Image = await main._grab()
	img.save_png(out.path_join("sun_disc.png"))
	print("captured sun_disc.png  mean %s cd/m^2 (centre %s), limb darkening u 0.6, EV %+.2f fixed for the disc" % [String.num_scientific(mean), String.num_scientific(Planets.limb_darkened(mean, 1.0)), e.ev])
	return img


## Jupiter at 1.9 px (a starfield point) and 2.1 px (a disc), centre crops x8.
func _crossover_shot(main: Node, sv: SystemView, out: String) -> Image:
	var e: Exposure = main.exposure
	main.camera.look(0.0, 0.0, 0.0)
	var pair := Image.create(2 * 48 * 8 + 8, 48 * 8, false, Image.FORMAT_RGBA8)
	pair.fill(Color(0.25, 0.25, 0.25))
	for i in 2:
		var px: float = [1.9, 2.1][i]
		var d := R_JUP / sin(px * e.pixel_rad / 2.0)
		var b := body("jupiter", R_JUP, d, 0.538, 1.0)
		e.fixed = true
		e.fixed_ev = log(b["e_v_lux"] / e.pixel_sr / 0.6 / Exposure.SAT) / log(2.0) # integrated value ~0.6
		e.update(Exposure.dark_sky_luminance())
		main._push_exposure()
		sv.update(section([b]), e.k())
		var img: Image = await main._grab()
		var crop := img.get_region(Rect2i(img.get_width() / 2 - 24, img.get_height() / 2 - 24, 48, 48))
		crop.convert(Image.FORMAT_RGBA8)
		crop.resize(48 * 8, 48 * 8, Image.INTERPOLATE_NEAREST)
		pair.blit_rect(crop, Rect2i(0, 0, 48 * 8, 48 * 8), Vector2i(i * (48 * 8 + 8), 0))
	pair.save_png(out.path_join("crossover_pair.png"))
	print("captured crossover_pair.png  Jupiter at 1.9 px (starfield point, left) and 2.1 px (disc, right), centre 48 px x8")
	var tile := Image.create(main.get_viewport().get_texture().get_size().x, main.get_viewport().get_texture().get_size().y, false, Image.FORMAT_RGBA8)
	tile.fill(Color.BLACK)
	var small := pair.duplicate()
	small.resize(tile.get_width(), int(tile.get_width() * pair.get_height() / float(pair.get_width())), Image.INTERPOLATE_NEAREST)
	tile.blit_rect(small, Rect2i(Vector2i.ZERO, small.get_size()), Vector2i(0, (tile.get_height() - small.get_height()) / 2))
	return tile
