extends SceneTree
## TB6 evidence (trappist1-planets-sprint.md): the guided voyage to the TRAPPIST-1
## habitable-zone stop, driven through demos/solar_departure.gd with its Skip
## (skip_stage: the sim stepped exactly to each phase boundary, as the player's
## Skip does), then frames at the stop: the red star with its planets, the
## nearest planets, and narrow-field views. Open every PNG in
## renders/trappist1/ before merge; metrics.json records each frame's bodies.
##   godot --path . --script tools/trappist1_capture.gd   (GPU window)
const SolarDeparture := preload("res://demos/solar_departure.gd")
const OUT := "res://renders/trappist1"
const STOP_LEG := 7 # "trappist-1" in solar_departure.legs
var sky: InteriorSky
var tour
var records := []
var frame := 0
var failures := 0

func _initialize() -> void: run.call_deferred()

func run() -> void:
	root.size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(OUT)
	sky = InteriorSky.new(); root.add_child(sky)
	sky.setup({"position_m": [0, 0, 0], "forward": [0, 0, 1], "up": [0, 1, 0]}, 78., root.size, {"stars": true, "background": true, "planet_textures": true})
	var rect := TextureRect.new(); rect.texture = sky.get_texture()
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.add_child(rect)
	sky.exposure.fixed = true; sky.exposure.fixed_ev = sky.exposure.ev_dark() - 2.; sky.set_temporal_exposure(false)
	var sim := SimBridge.new(); sim.want_minor = 5
	if not sim.start() or not sim.new_game(424242, "solar_departure", false, SolarDeparture.guided_params()):
		print("trappist1-capture: start FAIL ", sim.last_error); quit(1); return
	var catalogue: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/starmap/stars.json")).get("stars", [])
	tour = SolarDeparture.new()
	if not tour.attach(sim, catalogue): print("trappist1-capture: attach FAIL"); quit(1); return
	tour.pin_destinations(sky.starfield)
	for leg in STOP_LEG + 1:
		if not tour.advance(): print("leg ", leg, " FAIL ", tour.failed); failures += 1; break
		for i in 200:
			if sim.world.journey.state == "arrived": break
			if not tour.skip_stage() and not tour.step(): print("skip FAIL ", tour.failed); failures += 1; break
		print("leg ", leg, " ", tour.itinerary[leg].id, " ", sim.world.journey.state, " Earth+", snappedf(sim.world.clock.year, 0.001))
	if failures == 0: await stop_frames(sim)
	var f := FileAccess.open(OUT.path_join("metrics.json"), FileAccess.WRITE); f.store_string(JSON.stringify(records, "  ")); f.close()
	sim.stop()
	print("trappist1-capture: %d frames, %d failures" % [records.size(), failures]); quit(1 if failures else 0)

func body(world: Dictionary, id: String) -> Dictionary:
	for b: Dictionary in world.system.bodies:
		if b.id == id: return b
	return {}

func dir_of(b: Dictionary) -> Vector3:
	var w := Planets.world_of(b.rel_km); return Vector3(w[0], w[1], w[2]).normalized()

func deg_across(b: Dictionary) -> float:
	return rad_to_deg(2. * Planets.angular_radius(b.radius_km, Planets.length64(Planets.world_of(b.rel_km))))

func stop_frames(sim: SimBridge) -> void:
	var w: Dictionary = sim.world
	var star := body(w, "trappist-1")
	var planets := []
	for b: Dictionary in w.system.bodies:
		if b.get("host", "") == "trappist-1": planets.append(b)
	var sizes := {}
	for p: Dictionary in planets: sizes[p.id] = snappedf(deg_across(p), 0.001)
	print("TRAPPIST-1 star ", snappedf(deg_across(star), 0.001), " deg; planets (deg across) ", sizes)
	# The planet nearest the star on the sky among those at least 0.25 deg across.
	var pair: Dictionary = {}
	for p: Dictionary in planets:
		if deg_across(p) >= 0.25 and (pair.is_empty() or dir_of(p).dot(dir_of(star)) > dir_of(pair).dot(dir_of(star))): pair = p
	var by_size := planets.duplicate(); by_size.sort_custom(func(a, c): return deg_across(a) > deg_across(c))
	await shot("star_auto", sim, dir_of(star), 78., true)
	await shot("star_realistic", sim, dir_of(star), 78., false)
	if not pair.is_empty():
		await shot("star_and_%s_auto" % pair.id, sim, (dir_of(star) + dir_of(pair)).normalized(), 78., true)
	if not pair.is_empty():
		var sep := rad_to_deg(dir_of(star).angle_to(dir_of(pair)))
		print("pair ", pair.id, " ", snappedf(sep, 0.1), " deg from the star")
		await shot("star_and_%s_fov45_auto" % pair.id, sim, (dir_of(star) + dir_of(pair)).normalized(), 45., true)
	await shot("%s_wide_auto" % by_size[0].id, sim, dir_of(by_size[0]), 78., true)
	# The largest planet with its nearest resolved neighbour on the sky.
	var near: Dictionary = {}
	for p: Dictionary in planets:
		if p.id != by_size[0].id and deg_across(p) >= 0.25 and (near.is_empty() or dir_of(p).dot(dir_of(by_size[0])) > dir_of(near).dot(dir_of(by_size[0]))): near = p
	if not near.is_empty():
		print("neighbour ", near.id, " ", snappedf(rad_to_deg(dir_of(by_size[0]).angle_to(dir_of(near))), 0.1), " deg from ", by_size[0].id)
		await shot("%s_and_%s_fov45_auto" % [by_size[0].id, near.id], sim, (dir_of(by_size[0]) + dir_of(near)).normalized(), 45., true)
	for p: Dictionary in by_size.slice(0, 3):
		await shot("%s_tele12_auto" % p.id, sim, dir_of(p), 12., true)
	await shot("star_tele12_auto", sim, dir_of(star), 12., true)

func shot(name: String, sim: SimBridge, n: Vector3, fov: float, auto_view: bool) -> void:
	sky.view_fov = fov; sky.camera.fov = fov; sky.configure_pixel()
	sky.system_view.body_fader = auto_view
	sky.apply(sim.world)
	for i in 6:
		sky.camera.look(atan2(-n.x, -n.z), asin(clampf(n.y, -1., 1.)), 0.)
		frame += 1; sky.finish_exposure_frame(1. / 60., frame)
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(OUT.path_join(name + ".png"))
	var nan := false
	for y in range(0, img.get_height(), 8):
		for x in range(0, img.get_width(), 8):
			var c := img.get_pixel(x, y); nan = nan or not (is_finite(c.r) and is_finite(c.g) and is_finite(c.b))
	if nan: failures += 1
	var bodies := []
	for b: Dictionary in sim.world.system.bodies:
		if b.get("host", "") != "trappist-1" and b.id != "trappist-1": continue
		var px := sky.camera.project(dir_of(b), Vector2(root.size))
		var peak := Color(0, 0, 0)
		var inside := dir_of(b).dot(sky.camera.view_dir()) > 0. and px.x >= 0 and px.y >= 0 and px.x < root.size.x and px.y < root.size.y
		if inside:
			for y in range(maxi(0, int(px.y) - 3), mini(img.get_height(), int(px.y) + 4)):
				for x in range(maxi(0, int(px.x) - 3), mini(img.get_width(), int(px.x) + 4)):
					var c := img.get_pixel(x, y)
					if c.r + c.g + c.b > peak.r + peak.g + peak.b: peak = c
		var diam_px := deg_across(b) / (fov / root.size.y)
		bodies.append({"id": b.id, "px": [px.x, px.y], "in_frame": inside, "deg": deg_across(b), "diam_px": diam_px, "phase_deg": b.get("phase_deg", 0.), "peak": [peak.r, peak.g, peak.b], "drawn_disc": b.id in sky.system_view.drawn_discs})
	records.append({"name": name, "fov": fov, "auto_view": auto_view, "earth_year": sim.world.clock.year, "finite": not nan, "bodies": bodies})
	print("SHOT ", name, " fov ", fov, " discs ", sky.system_view.drawn_discs.filter(func(i): return str(i).begins_with("trappist")))
