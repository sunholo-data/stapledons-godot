extends SceneTree
## make star-surface-bench (R2-STAR-SURFACES AC11, OQ2; GPU window): the surface map's cost at the
## worst stop. Free navigation to Aldebaran (61 deg across, the largest disc any stop shows), the Bow
## view as the player sees it, vsync off, and the sky viewport's measured GPU time with the map on
## and off, alternated off/on/off/on so drift cancels. Run on Vulkan: Godot 4.7's Metal driver reports
## no GPU time (the spike's 0.0 readings; tools/bh_ship_bench.gd notes the same), so the tool first
## requires a non-zero reading and fails if it gets none. Pass: on - off <= 0.50 ms at p50.
const WARMUP := 90
const SAMPLES := 240
const LIMIT_MS := 0.50
var demo: Node


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var size := Vector2i(2560, 1440)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--bench-size="):
			var p := a.trim_prefix("--bench-size=").split("x")
			size = Vector2i(int(p[0]), int(p[1]))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	root.size = size
	demo = load("res://demos/ship_geometry_demo.tscn").instantiate()
	root.add_child(demo)
	demo.auto = false
	await process_frame
	if not demo.ready_ok:
		print("star-surface-bench: FAIL the ship did not start")
		quit(1)
		return
	demo.journey_auto_tick = false
	demo.sky.system_view.surface_norm_wait = true
	var rid: RID = demo.sky.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)
	demo.open_navigation()
	demo.journey_map.preselect(demo.journey_map.index_of("CNS5:1142"))
	var map = demo.journey_map
	demo.journey_tick()
	if not (map.open_commit_dialog() and map.hold_commit(GalaxyMap.HOLD_S) and demo.journey_tick() and demo.live_journey):
		print("star-surface-bench: FAIL commit: ", map.status_text())
		quit(1)
		return
	for i in 6000:
		if not demo.journey_tick() or not demo.live_journey:
			break
	if map.journey_state() != "arrived":
		print("star-surface-bench: FAIL no arrival at Aldebaran")
		quit(1)
		return
	demo.set_auto_view(true)
	var root_size := root.get_texture().get_size()
	print("star-surface-bench: %s, %s, frame %dx%d, Aldebaran stop, Bow view, Auto" % [RenderingServer.get_video_adapter_name(), RenderingServer.get_current_rendering_method(), root_size.x, root_size.y])
	var off := []
	var on := []
	for k in 4:
		var enabled := k % 2 == 1
		demo.sky.system_view.surfaces_enabled = enabled
		for i in WARMUP:
			await process_frame
		var v := []
		for i in SAMPLES:
			await RenderingServer.frame_post_draw
			v.append(RenderingServer.viewport_get_measured_render_time_gpu(rid))
		(on if enabled else off).append_array(v)
	var o := _p50(off)
	var n := _p50(on)
	if o <= 0.0 or n <= 0.0:
		print("star-surface-bench: FAIL no GPU time (off %.3f on %.3f ms): run with --rendering-driver vulkan" % [o, n])
		quit(1)
		return
	var d := n - o
	print("star-surface-bench: sky GPU p50 off %.3f ms, on %.3f ms, delta %+.3f ms (limit +%.2f): %s" % [o, n, d, LIMIT_MS, "OK" if d <= LIMIT_MS else "FAIL"])
	quit(0 if d <= LIMIT_MS else 1)


static func _p50(v: Array) -> float:
	var s := v.duplicate()
	s.sort()
	return float(s[int(s.size() * 0.5)]) if not s.is_empty() else 0.0
