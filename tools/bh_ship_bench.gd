extends SceneTree
## make bench-bh (M3.6): the 3D ship's frame cost with GR on, against GR off, at the large star tier.
## Both are measured in this one session, vsync off, at BENCH (default 1920x1080, the ship
## benchmark's size). Per case: wall time between frames (p50/p99, includes CPU and presentation)
## and the GPU time of the sky viewport and of the ship-geometry viewport (RenderingServer's
## measured render time), so a GPU-bound and a CPU-bound cost can be told apart.
##   off_bridge / off_forward   Sol at rest (the review snapshot), GR off
##   r10_bridge / r10_forward   Sgr A*, hovering at 10 r_s (state unchanged per frame)
##   r3orbit_bridge / _forward  Sgr A*, orbiting at 3 r_s, live ticks at 20 Hz (set_gr every tick)

const WARMUP := 120
const SAMPLES := 300

var demo: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var size := Vector2i(1920, 1080)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--bench-size="):
			var p := a.trim_prefix("--bench-size=").split("x")
			size = Vector2i(int(p[0]), int(p[1]))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	root.size = size
	demo = load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options = {"sky_state": "rest", "size": size, "tier": "large"}
	root.add_child(demo)
	await process_frame
	demo.auto = false
	demo.journey_auto_tick = false
	print("bench-bh: %s, %s %s, %d stars (tier %s), %dx%d" % [RenderingServer.get_video_adapter_name(), RenderingServer.get_current_rendering_method(), OS.get_name(), demo.sky.starfield.count, Starfield.last_loaded.get("tier", "?"), size.x, size.y])
	for vp: Viewport in [demo.sky, demo.geometry_view]:
		RenderingServer.viewport_set_measure_render_time(vp.get_viewport_rid(), true)
	await _views("off")
	if not demo.start_black_hole():
		print("bench-bh: FAIL Sgr A* did not start")
		quit(1)
		return
	demo.bh_next_stop()
	demo.bh_finish_approach()
	await _views("r10")
	for r in [5.0, 3.0]:
		demo.bh_next_stop()
		demo.bh_finish_approach()
	demo.bh_next_stop() # orbit at 3 r_s
	demo.journey_auto_tick = true
	await _views("r3orbit")
	demo.journey_auto_tick = false
	print("bench-bh: gr %s; ring stars %d (overflow %d)" % [demo.gr_status(), demo.sky.gr_lens.ring.size(), demo.sky.gr_lens.ring_overflow])
	print("bench-bh: OK")
	demo.leave_black_hole()
	quit(0)


func _views(tag: String) -> void:
	for view in ["bridge", "forward"]:
		demo.set_preset("bridge")
		if view == "forward":
			demo.look_direction("forward")
		for i in WARMUP:
			await process_frame
		var wall := []
		var sky_gpu := []
		var ship_gpu := []
		var prev := Time.get_ticks_usec()
		for i in SAMPLES:
			await process_frame
			var now := Time.get_ticks_usec()
			wall.append((now - prev) / 1000.0)
			prev = now
			sky_gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(demo.sky.get_viewport_rid()))
			ship_gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(demo.geometry_view.get_viewport_rid()))
		var w := _stats(wall)
		var s := _stats(sky_gpu)
		var g := _stats(ship_gpu)
		var over := wall.filter(func(x: float) -> bool: return x > 1000.0 / 60.0).size()
		print("bench-bh: %-16s wall p50 %6.2f p99 %6.2f ms (%d of %d frames over 16.7 ms) · GPU sky p50 %5.2f p99 %5.2f ms · GPU ship p50 %5.2f p99 %5.2f ms" % [tag + "_" + view, w[0], w[1], over, SAMPLES, s[0], s[1], g[0], g[1]])


static func _stats(v: Array) -> Array:
	var s := v.duplicate()
	s.sort()
	return [s[int(s.size() * 0.5)], s[mini(s.size() - 1, int(ceil(s.size() * 0.99)) - 1)]]
