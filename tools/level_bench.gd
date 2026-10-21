extends SceneTree
## R2-LEVELS AC13 (design_docs/planned/r2/levels.md §B6): make bench SCENE=level LEVEL=<id> [STAGE=].
## Frame time at 2560x1440, vsync off, through the stage's default view at its spawn, at 0.99c (the
## review cruise snapshot), the level's greybox laid when its document has one. Prints p50 / p95 / p99
## against the 16.7 ms target, the host load, and "bench-level: OK" for a valid measurement (exit 2
## on a p99 miss, 1 on an invalid measurement), like bench-bridge.

const SIZE := Vector2i(2560, 1440)
const P99_TARGET_MS := 16.7
const FRAMES := 600
const Summary := preload("res://demos/ship_demo_benchmark.gd")


func _initialize() -> void:
	_run.call_deferred()


func _arg(args: PackedStringArray, k: String, def := "") -> String:
	var i := args.find(k)
	return args[i + 1] if i >= 0 and i + 1 < args.size() else def


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var id := _arg(args, "--level", "bridge")
	var doc := LevelEval.load_doc(LevelEval.doc_path(id))
	if doc.is_empty():
		print("bench-level: FAIL no document for %s" % id)
		quit(1)
		return
	var stage: Dictionary = doc.stages[0]
	for s: Dictionary in doc.stages:
		if s.id == _arg(args, "--stage", str(stage.id)):
			stage = s
	root.size = SIZE
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.content_scale_size = SIZE
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	await process_frame
	var demo: Node = load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options = {"size": SIZE, "sky_state": "cruise", "seed": 424242, "ai": false}
	root.add_child(demo)
	await process_frame
	if not demo.ready_ok:
		print("bench-level: FAIL demo not ready")
		quit(1)
		return
	demo.auto = false
	demo.journey_auto_tick = false
	if not (doc.get("pieces", []) as Array).is_empty():
		LevelGreybox.build(doc, demo.geometry)
	var c := LevelMetrics.gltf(stage.spawn)
	demo.director.override()
	demo.avatar_pos = c
	demo.camera_mode = "review"
	var v: Dictionary = stage.views[0]
	for vv: Dictionary in stage.views:
		if vv.id == stage.default_view:
			v = vv
	demo.camera.global_transform = LevelMetrics.pose(v, c)
	demo._sync_observer()
	var load_output := []
	var host_load := str(load_output[0]).strip_edges() if OS.execute("uptime", PackedStringArray(), load_output) == 0 and not load_output.is_empty() else "unavailable"
	for i in 120:
		await process_frame
	var times := []
	var previous := Time.get_ticks_usec()
	for i in FRAMES:
		await process_frame
		var now := Time.get_ticks_usec()
		times.append((now - previous) / 1000.0)
		previous = now
	var t := Summary.summarize(times)
	var viewport := root.get_visible_rect().size
	var valid := times.size() == FRAMES and viewport == Vector2(SIZE)
	var miss: bool = t.p99_ms >= P99_TARGET_MS
	print("bench-level: %s stage %s view %s, viewport %dx%d, %s, host load %s" % [id, stage.id, v.id, int(viewport.x), int(viewport.y), RenderingServer.get_video_adapter_name(), host_load])
	print("bench-level: frame ms p50 %.3f  p95 %.3f  p99 %.3f  max %.2f (target p99 < %.1f: %s)" % [t.p50_ms, t.p95_ms, t.p99_ms, t.maximum_ms, P99_TARGET_MS, "MISS" if miss else "ok"])
	if not valid:
		print("bench-level: FAIL invalid measurement (%d frames, viewport %s)" % [times.size(), viewport])
		quit(1)
		return
	print("bench-level: OK")
	quit(2 if miss else 0)
