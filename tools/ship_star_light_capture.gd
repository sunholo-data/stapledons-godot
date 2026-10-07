extends SceneTree
## R1-SHIP-STAR-LIGHT renders: the guided solar departure (real sim, fast ticks as in
## tools/solar_departure_capture.gd), the ship lit by the star the player sees.
## Poses per stop: the tour's own bridge view, a bridge overlook looking down-light
## (where the shadows fall), and the Commons arcade. Writes renders/ship_star_light/.
var captures := []
var failed := false
var demo: Node
const OUT := "res://renders/ship_star_light"

func _initialize() -> void: _run.call_deferred()

func settle() -> void:
	for frame in 4: await process_frame
	demo.star_light.update(demo.lighting, demo.sky, 0.0, true)
	demo.sky.update_exposure()
	for frame in 10: await process_frame
	await RenderingServer.frame_post_draw

func shot(name: String) -> void:
	await settle()
	root.get_texture().get_image().save_png(OUT + "/" + name + ".png")
	var w: Dictionary = demo.journey_sim.world
	captures.append({"name": name, "phase": w.ship.phase, "beta": w.ship.beta, "gamma": w.ship.gamma, "epoch_jd": w.system.jd, "eye_m": [demo.camera.position.x, demo.camera.position.y, demo.camera.position.z], "tilt_deg": demo.camera.tilt, "yaw_rad": demo.camera.yaw, "attitude": Array(demo.camera.attitude_basis), "lighting": demo.lighting_manifest()})
	print("capture ", name, " · ", demo.star_light.hud_line(), " · interior dir ", demo.star_light.interior_dir, " · key ", demo.lighting.key.light_energy)

## The tour's view, then an overlook down-light, then the Commons; the bridge eye is restored.
func poses(stem: String, which := ["bridge", "overlook", "commons"]) -> void:
	var saved_pos: Vector3 = demo.avatar_pos
	var saved := Vector2(demo.camera.tilt, demo.camera.yaw)
	var view_active: bool = demo._tour_view_active
	demo._tour_view_active = false
	if which.has("bridge"): await shot(stem + "_bridge")
	if which.has("overlook"):
		var d: Vector3 = demo.star_light.interior_dir
		var yaw := atan2(-d.z, -d.x) if Vector2(d.x, d.z).length() > 0.05 else saved.y
		demo.camera.follow(demo.avatar_pos, -35.0, yaw, 0.0)
		await shot(stem + "_overlook")
	if which.has("commons"):
		demo.active_level = 1; demo.walk = demo.walk_lower; demo.avatar_pos = Vector3(46, 57, -5)
		demo.camera.follow(demo.avatar_pos, 0.0, 1.6, 0.0)
		await shot(stem + "_commons")
		demo.active_level = 0; demo.walk = demo.walk_bridge
	demo.avatar_pos = saved_pos
	demo.camera.follow(demo.avatar_pos, saved.x, saved.y, 0.0)
	demo._tour_view_active = view_active
	await settle()

func turn_stationary(sample_stem := "") -> void:
	demo._update_tour_attitude(0.)
	await process_frame
	var frames := 0
	var taken := 0
	for frame in 1200:
		if not demo.solar_tour.attitude_hold: break
		if not demo.journey_tick(): failed = true; return
		frames += 1
		# The ship turns under a fixed Sun: the shadows sweep across the bridge.
		if not sample_stem.is_empty() and demo.tour_attitude.turning() and frames % 40 == 20 and taken < 3:
			taken += 1
			# Hold one overlook while the ship (and so the Sun in ship axes) turns.
			var view_active: bool = demo._tour_view_active
			demo._tour_view_active = false
			var keep := Vector2(demo.camera.tilt, demo.camera.yaw)
			demo.camera.follow(demo.avatar_pos, -35.0, 0.6, 0.0)
			await shot("%s_turn_%d" % [sample_stem, taken])
			demo.camera.follow(demo.avatar_pos, keep.x, keep.y, 0.0)
			demo._tour_view_active = view_active
		await process_frame

func _run() -> void:
	root.size = Vector2i(1280, 720); UiScale.configure(root, true)
	DirAccess.make_dir_recursive_absolute(OUT)
	demo = load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options = {"size": root.size, "sky_state": "rest"}; root.add_child(demo); await process_frame
	demo.auto = true; demo.journey_auto_tick = false
	if not demo.start_solar_departure(): print("ship-star-light-capture: FAIL start"); quit(1); return
	await turn_stationary()
	await poses("01_earth_start")
	var itinerary: Array = demo.solar_tour.itinerary.duplicate(true)
	var arrivals := {"jupiter": "02_jupiter", "trappist-1": "05_trappist1", "aldebaran": "06_aldebaran"}
	for spec: Dictionary in itinerary:
		var id: String = spec.id
		if not demo.solar_tour.prepare_next(): print("capture-prepare-failed: ", demo.solar_tour.failed); failed = true; break
		await turn_stationary("01b_departure" if id == "sun" else "")
		if failed or not demo.live_journey: print("capture-departure-failed: ", demo.solar_tour.failed); failed = true; break
		if OS.get_cmdline_user_args().has("--quick"): break # iterate on the Earth start and the first turn
		var phase_ticks := 0
		var old_phase := ""
		for tick in 6000:
			if not demo.journey_tick(): failed = true; break
			var phase: String = demo.sky_world.ship.phase
			if phase != old_phase: phase_ticks = 0; old_phase = phase
			phase_ticks += 1
			if id == "CNS5:3627" and phase == "cruising" and phase_ticks == 120:
				await poses("04_interstellar_cruise", ["bridge", "overlook"])
			if id == "jupiter" and phase == "approaching" and phase_ticks == 60:
				await poses("02a_near_jupiter", ["overlook"])
			if demo.journey_sim.world.journey.state == "arrived": break
			await process_frame
		if demo.journey_sim.world.journey.state != "arrived": print("capture-arrival-failed: ", id); failed = true; break
		await turn_stationary()
		if arrivals.has(id): await poses(arrivals[id] + "_arrival")
		if id == "saturn": await poses("03_saturn_arrival", ["overlook"])
		if failed: break
	var file := FileAccess.open(OUT + "/capture-manifest.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"captures": captures, "itinerary": itinerary, "note": "Guided solar departure, real sim, fast capture ticks (normal play is 20 Hz). Ship lit by the star the player sees: direction and colour physical, brightness log-compressed (see lighting.star_light). No GR."}, "  "))
	print("ship-star-light-capture-images: %d" % captures.size())
	print("ship-star-light-capture: %s" % ("FAIL" if failed else "OK"))
	demo.queue_free(); await process_frame; quit(1 if failed else 0)
