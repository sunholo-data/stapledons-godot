extends SceneTree
## R1-SHIP-STAR-LIGHT cost: paired frame times, moody ship lighting without and with the
## star light (a second shadowed DirectionalLight3D while both are partly on, the star
## alone at full). Method of tools/ship_lighting_bench.gd: 1920x1080, 120 warmup, 300 frames.
const Stats := preload("res://demos/ship_demo_benchmark.gd")
const FIXTURE := "res://tests/fixtures/system_sol.ndjson"

func _initialize() -> void: _run.call_deferred()

## Recorded sim state with the observer moved to Earth (as tests/test_ship_star_light.gd);
## lux_scale sets the Sun's seen illuminance (1 = 1.27e5 lx, full star light).
func world_at_earth(lux_scale: float) -> Dictionary:
	var lines := FileAccess.get_file_as_string(FIXTURE).strip_edges().split("\n")
	var world: Dictionary = JSON.parse_string(lines[1]).changes
	world.system = SimBridge.parse_system(world.system)
	var e := {}
	for b: Dictionary in world.system.bodies:
		if b.id == "earth": e = b.rel_km.duplicate()
	for b: Dictionary in world.system.bodies:
		b.rel_km = {"x": b.rel_km.x - e.x, "y": b.rel_km.y - e.y, "z": b.rel_km.z - e.z}
		if b.id == "earth": b.rel_km = {"x": 0.0, "y": 0.0, "z": 1.0e9} # out of the way
	for b: Dictionary in world.system.bodies:
		if b.id == "sun":
			var d := sqrt(b.rel_km.x * b.rel_km.x + b.rel_km.y * b.rel_km.y + b.rel_km.z * b.rel_km.z)
			b.e_v_lux = 1.27e5 * pow(SystemView.AU_KM / d, 2.0) * lux_scale
	return world

func _run() -> void:
	root.size = Vector2i(1920, 1080); UiScale.configure(root, true)
	var demo: Node = load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options = {"sky_state": "rest"}; root.add_child(demo); await process_frame
	demo.auto = false; demo.journey_auto_tick = false
	var report := {"resolution": [1920, 1080], "warmup": 120, "samples": 300, "air_pending": true, "timer": "Wall frame intervals include presentation/vsync; negative paired deltas are noise.", "pairs": []}
	var cases := {"moody_ship_only": {}, "moody_star_partial": world_at_earth(0.003), "moody_star_full": world_at_earth(1.0)}
	for pose in ["bridge_outward", "bridge_overlook", "commons_arcade"]:
		var pair := {"pose": pose, "measurements": []}
		for name: String in cases:
			match pose:
				"bridge_outward": demo.set_preset("bridge")
				"bridge_overlook": demo.set_preset("overlook")
				"commons_arcade": demo.active_level = 1; demo.avatar_pos = Vector3(46, 57, -5); demo.camera.follow(demo.avatar_pos, 0., 1.6, 0.)
			demo.camera_mode = "lighting benchmark"
			var w: Dictionary = cases[name]
			if w.is_empty(): demo.set_sky_state("rest")
			else: demo.sky.apply(w)
			demo.set_lighting("moody"); demo._sync_observer()
			demo.star_light.update(demo.lighting, demo.sky, 0.0, true)
			for frame in 120: await process_frame
			var times := []; var previous := Time.get_ticks_usec()
			for frame in 300:
				await process_frame
				var now := Time.get_ticks_usec(); times.append(float(now - previous) / 1000.); previous = now
			var m: Dictionary = demo.lighting_manifest()
			pair.measurements.append({"case": name, "star_energy": m.star_light.energy, "key_energy": m.key_energy, "shadowed_directional_lights": int(m.star_light.shadows) + int(m.key_shadows), "frame_times": Stats.summarize(times)})
		pair.star_partial_minus_ship_p95_ms = pair.measurements[1].frame_times.p95_ms - pair.measurements[0].frame_times.p95_ms
		pair.star_full_minus_ship_p95_ms = pair.measurements[2].frame_times.p95_ms - pair.measurements[0].frame_times.p95_ms
		print(pose, " p95 ms: ship ", pair.measurements[0].frame_times.p95_ms, " · star+key ", pair.measurements[1].frame_times.p95_ms, " · star ", pair.measurements[2].frame_times.p95_ms)
		report.pairs.append(pair)
	DirAccess.make_dir_recursive_absolute("res://renders/ship_star_light")
	var file := FileAccess.open("res://renders/ship_star_light/benchmark-aggregate.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  "))
	print("ship-star-light-bench: OK")
	demo.queue_free(); await process_frame; quit()
