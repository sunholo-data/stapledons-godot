extends SceneTree
## M4.6rR3: wall-time frame cost of the ship's own live journey heartbeat.
const SIZE := Vector2i(2560, 1440)
const BENCH_S := 30.0
const P99_TARGET_MS := 16.7
const MIN_FRAMES := 300   # 10 fps over 30 s; the spike measured 821
const DECK := [30.0, 0.47]
const Summary := preload("res://demos/ship_demo_benchmark.gd")
var demo: Node
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = SIZE
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.content_scale_size = SIZE
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var tier := "medium"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--tier="):
			tier = arg.trim_prefix("--tier=")
	# Settle the host window clamp before the demo sizes its two viewports.
	await process_frame
	demo = load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options = {"size": SIZE, "sky_state": "rest", "seed": 424242, "ai": false, "tier": tier}
	root.add_child(demo)
	await process_frame
	demo.auto = false
	demo.journey_auto_tick = false
	if not _check(demo.ready_ok, "demo not ready"):
		quit(1)
		return
	_check(demo.sky.has_background, "no sky panorama: make sky-assets")
	_check(demo.sky.starfield.count >= 60000, "fewer than 60000 stars")
	var load_output := []
	var load_rc := OS.execute("uptime", PackedStringArray(), load_output)
	var host_load := str(load_output[0]).strip_edges() if load_rc == 0 and not load_output.is_empty() else "unavailable"
	var hardware := {"adapter": RenderingServer.get_video_adapter_name(), "method": RenderingServer.get_current_rendering_method(),
		"driver": RenderingServer.get_current_rendering_driver_name(), "cpu": OS.get_processor_name(), "os": OS.get_name(),
		"host_load": host_load, "tier": Starfield.last_loaded.get("tier"), "requested_tier": tier,
		"stars": demo.sky.starfield.count, "background": demo.sky.has_background, "vsync": DisplayServer.window_get_vsync_mode()}
	var viewport := root.get_visible_rect().size
	print("bench-bridge: %s, %s, viewport %dx%d (window %dx%d), tier %s, %d stars, background %s, vsync %s, host load %s" % [
		hardware.adapter, hardware.method, int(viewport.x), int(viewport.y), root.size.x, root.size.y, hardware.tier,
		hardware.stars, hardware.background, "off" if hardware.vsync == DisplayServer.VSYNC_DISABLED else "on", host_load])
	for vp: Viewport in [demo.sky, demo.geometry_view]:
		RenderingServer.viewport_set_measure_render_time(vp.get_viewport_rid(), true)
	_pose()
	for i in 120:
		await process_frame
	var docked := []
	var previous := Time.get_ticks_usec()
	for i in 300:
		await process_frame
		var now := Time.get_ticks_usec()
		docked.append((now - previous) / 1000.0)
		previous = now
	var control := Summary.summarize(docked)
	print("bench-bridge: docked control 300 frames p50 %.2f p95 %.2f p99 %.2f ms (no journey ticks; not gated)" % [control.p50_ms, control.p95_ms, control.p99_ms])
	if not await _commit():
		_stop(1)
		return
	for i in 30:
		await process_frame
	# Departure's normal console dolly must finish before setting the eye pose.
	var deadline := Time.get_ticks_msec() + 30000
	while demo.consoles.dolly_active() and Time.get_ticks_msec() < deadline:
		await process_frame
	_check(not demo.consoles.dolly_active(), "console dolly did not finish")
	_pose()
	demo.journey_auto_tick = true
	for i in 120:
		await process_frame
	var committed: bool = demo.live_journey and demo.journey_sim.world.journey.state == "committed"
	_check(committed, "journey not committed at start")
	var times := []
	var phases := []
	var waits := []
	var sky_gpu := []
	var ship_gpu := []
	var counts := {"boosting": 0, "cruising": 0}
	previous = Time.get_ticks_usec()
	var started := previous
	var previous_wait: float = demo.journey_sim.send_ms_total
	while (previous - started) / 1e6 < BENCH_S:
		await process_frame
		var now := Time.get_ticks_usec()
		times.append((now - previous) / 1000.0)
		previous = now
		var phase: String = demo.journey_sim.world.ship.phase
		phases.append(phase)
		counts[phase] = int(counts.get(phase, 0)) + 1
		var wait_total: float = demo.journey_sim.send_ms_total
		waits.append(wait_total - previous_wait)
		previous_wait = wait_total
		sky_gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(demo.sky.get_viewport_rid()))
		ship_gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(demo.geometry_view.get_viewport_rid()))
	demo.journey_auto_tick = false
	var seconds := (previous - started) / 1e6
	_check(times.size() >= MIN_FRAMES, "measured %d frames (want >= 300)" % times.size())
	viewport = root.get_visible_rect().size
	_check(viewport == Vector2(SIZE), "viewport %dx%d (want 2560x1440)" % [int(viewport.x), int(viewport.y)])
	for spec in [["geometry", demo.geometry_view], ["sky", demo.sky]]:
		var vp: SubViewport = spec[1]
		_check(vp.size == SIZE, "subviewport %s %dx%d (want 2560x1440)" % [spec[0], vp.size.x, vp.size.y])
	_check(DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_DISABLED, "vsync is enabled")
	_check(Starfield.last_loaded.get("tier") == tier, "tier differs from requested " + tier)
	_check(counts.boosting > 0, "no boosting frames")
	_check(counts.cruising > 0, "no cruising frames")
	var timing := Summary.summarize(times) # Empty samples produce {samples: 0}, never an index.
	var sim_wait := Summary.summarize(waits)
	var sky_timing := Summary.summarize(sky_gpu)
	var ship_timing := Summary.summarize(ship_gpu)
	print("bench-bridge: live transit %d frames in %.1f s (boosting %d, cruising %d), end beta %.4f, sim wait p50 %.2f ms/frame" % [
		times.size(), seconds, counts.boosting, counts.cruising, demo.journey_sim.world.ship.beta, sim_wait.get("p50_ms", 0.0)])
	var miss := true
	if not times.is_empty():
		miss = timing.p99_ms >= P99_TARGET_MS
		var over := times.filter(func(ms: float) -> bool: return ms > 16.7).size()
		print("bench-bridge: frame ms p50 %.3f  p95 %.3f  p99 %.3f  max %.2f; %d of %d frames over 16.7 ms (target p99 < %.1f: %s)" % [
			timing.p50_ms, timing.p95_ms, timing.p99_ms, timing.maximum_ms, over, times.size(), P99_TARGET_MS, "MISS" if miss else "ok"])
	var gpu_available: bool = sky_timing.get("p99_ms", 0.0) > 0.0 or ship_timing.get("p99_ms", 0.0) > 0.0
	print("bench-bridge: GPU sky p50 %.3f ms, ship p50 %.3f ms" % [sky_timing.get("p50_ms", 0.0), ship_timing.get("p50_ms", 0.0)] if gpu_available else "bench-bridge: GPU time n/a on Metal (no measured GPU timestamps)")
	_check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.godot/tmp")) == OK, "create report directory")
	var file := FileAccess.open("res://.godot/tmp/bench-bridge.json", FileAccess.WRITE)
	if _check(file != null, "write bench-bridge.json"):
		file.store_string(SimBridge.encode({"hardware": hardware, "size": [SIZE.x, SIZE.y], "viewport": [viewport.x, viewport.y],
			"window": [root.size.x, root.size.y], "seed": 424242, "ailang": demo.journey_sim.hello_reply, "seconds": seconds,
			"committed_start": committed, "target_p99_ms": P99_TARGET_MS, "minimum_frames": MIN_FRAMES,
			"frame_times_ms": times, "phases": phases, "phase_counts": counts, "sim_wait_ms": waits,
			"sky_gpu_ms": sky_gpu, "ship_gpu_ms": ship_gpu, "docked_control": control, "timing": timing,
			"structural_failures": failures, "verdict": "MISS" if miss else "ok"}) + "\n")
		_check(file.get_error() == OK, "store bench-bridge.json")
		file.close()
	if failures == 0:
		print("bench-bridge: OK")
	_stop(1 if failures else (2 if miss else 0))


func _pose() -> void:
	demo.camera.follow(demo.avatar_pos, DECK[0], DECK[1], 0.0)
	demo._sync_observer()


func _commit() -> bool:
	if not _check(demo.consoles.walk_to("navigation"), "walk to navigation"):
		return false
	# Walking is real-time, so bound it in wall time, not frames.
	var deadline := Time.get_ticks_msec() + 30000
	while not demo.consoles.walking.is_empty() and Time.get_ticks_msec() < deadline:
		await process_frame
	if not _check(demo.consoles.walking.is_empty(), "walk to navigation exceeded 30 s"):
		return false
	for action in [["open", null], ["select", "CNS5:3627"], ["commit", null]]:
		if not _check(demo.consoles.use("navigation", action[0], action[1]), "console navigation/" + str(action[0])):
			return false
	var ok: bool = demo.journey_tick()
	return _check(ok and demo.live_journey and demo.journey_sim.world.journey.state == "committed", "departure tick not committed")


func _check(ok: bool, what: String) -> bool:
	if not ok:
		failures += 1
		print("bench-bridge: FAIL " + what)
	return ok


func _stop(code: int) -> void:
	if demo != null and demo.journey_sim != null:
		demo.journey_sim.stop()
	quit(code)
