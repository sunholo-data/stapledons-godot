extends SceneTree
## B frame check (Mark, 2026-10-14): one press measures what the player is doing, in any launch,
## changes no game state, reports frame times, stalls and the sim's share, and saves a report.
## Run:  make frame-check-test

var failures := 0

func check(label: String, ok: bool) -> void:
	if not ok: failures += 1
	print("%s %s" % ["ok" if ok else "FAIL", label])

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var r := FrameCheck.summarize([[16.0, 0.0, 0], [16.0, 5.0, 1], [40.0, 30.0, 1], [16.0, 0.0, 0]], [], {"x": 1})
	check("percentiles and the stall (40 ms, 30 ms of it the sim)", r.frames == 4 and r.frame_ms.max == 40.0 and r.stall_count == 1 and r.stalls_over_25ms[0].sim_ms == 30.0)
	check("the sim's share of frame time and per send", is_equal_approx(r.sim.share_of_frame_time, 0.398) and r.sim.sends == 2 and r.sim.ms_per_send == 17.5)
	var scene: PackedScene = load("res://demos/ship_geometry_demo.tscn")
	var demo: Node = scene.instantiate()
	demo.setup_options = {"stars": false, "background": false, "live_start": true, "sky_state": "rest", "from_menu": true, "settings_dir": "user://test_frame_check"}
	root.add_child(demo)
	for i in 5: await process_frame
	var fc: FrameCheck = demo.frame_check
	fc.seconds = 1.0
	fc.upload_enabled = false
	var sky: String = demo.sky_state
	var e := InputEventKey.new()
	e.physical_keycode = KEY_B
	e.pressed = true
	demo._unhandled_input(e)
	check("B starts a frame check in a menu launch", fc.running)
	var report := {}
	fc.finished.connect(func(rep): report.merge(rep)) # lambdas capture locals by value: fill the shared dictionary
	var deadline := Time.get_ticks_msec() + 20000
	while fc.running and Time.get_ticks_msec() < deadline:
		await process_frame
	check("it finishes and reports frames, the sim's sends and the context", report.get("frames", 0) > 0 and report.has("sim") and report.context.has("sky_state") and report.context.has("gpu"))
	check("the report is saved locally", FileAccess.file_exists(str(report.get("local", ""))))
	check("B changed no game state", demo.sky_state == sky)
	print("frame check report: fps %.1f p95 %.1f ms, sim %.0f%%, %d sends" % [report.get("fps_mean", 0.0), report.get("frame_ms", {}).get("p95", 0.0), report.get("sim", {}).get("share_of_frame_time", 0.0) * 100.0, report.get("sim", {}).get("sends", 0)])
	demo.queue_free()
	await process_frame
	print("frame-check: %d failures" % failures)
	quit(1 if failures else 0)
