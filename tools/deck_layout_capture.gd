extends SceneTree
## R2-DECK-LAYOUT §D3 / AC11: the GPU half of make deck-layout-capture (the camera views
## themselves are tools/camera_views_capture.gd --out renders/deck_layout/<TAG>).
##   sky-mask control  the evaluator's sky fraction (ray grid on the collision) against the rendered
##                     geometry layer's alpha (the sky shows where nothing opaque is drawn) for the
##                     Sky forward pose at the spawn and at the rail bearings 0 and 180 deg: within
##                     2 % (the design's positive control)
##   eval              the evaluator's report for the deck rendered, beside the frames
## --out <dir> (default res://renders/deck_layout/capture), --assets <dir> (a candidate deck).

var out := "res://renders/deck_layout/capture"
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.find("--out") >= 0:
		out = args[args.find("--out") + 1]
	var assets := args[args.find("--assets") + 1] if args.find("--assets") >= 0 else ""
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var px := Vector2i(1280, 720)
	root.size = px
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_size = px
	var demo: Node = load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options = {"stars": false, "background": false, "sky_state": "rest", "size": px, "asset_dir": assets}
	root.add_child(demo)
	await process_frame
	await physics_frame
	if not demo.ready_ok:
		print("FAIL the ship demo did not start")
		quit(1)
		return
	demo.auto = false
	demo.journey_auto_tick = false
	demo.ship_hud.visible = false
	var dl := DeckLayout.new(demo)
	var dir: CameraDirector = demo.director
	var fwd: Dictionary = dir.views["sky_forward"]
	var poses := {"spawn": dl._landing(fwd, dl.spawn(), true)}
	for deg in [0, 180]:
		poses["rail_%d" % deg] = dl._landing(fwd, dir.anchor_of(fwd, Vector3(cos(deg_to_rad(deg)), 0, sin(deg_to_rad(deg))) * 10.0 + Vector3(0, 82, 0)), false)
	demo.avatar.visible = false
	demo.avatar_shadow.visible = false
	demo.captain_ring.visible = false
	demo.process_mode = Node.PROCESS_MODE_DISABLED
	var rows := []
	for k: String in poses:
		if poses[k] == null:
			print("FAIL sky-mask %s: no Sky forward pose" % k)
			failures += 1
			continue
		var pose: Transform3D = poses[k]
		demo.camera.global_transform = pose
		for i in 4:
			await process_frame
		await RenderingServer.frame_post_draw
		var img: Image = demo.geometry_view.get_texture().get_image()
		img.save_png(out + "/sky_mask_%s.png" % k)
		var sky := 0
		var n := 0
		for y in range(0, img.get_height(), 4):
			for x in range(0, img.get_width(), 4):
				n += 1
				if img.get_pixel(x, y).a < 0.5:
					sky += 1
		var rendered := float(sky) / float(n)
		var rays := dl.sky_fraction(pose)
		var ok := absf(rendered - rays) <= 0.02
		if not ok:
			failures += 1
		rows.append({"pose": k, "rendered": rendered, "rays": rays, "ok": ok})
		print("%s sky-mask %s: rendered %.3f, evaluator %.3f (|d| %.3f <= 0.02)" % ["ok  " if ok else "FAIL", k, rendered, rays, absf(rendered - rays)])
	demo.process_mode = Node.PROCESS_MODE_INHERIT
	demo.camera.current = true
	var report := dl.evaluate(["bridge", "lower"])
	report.sky_mask_control = rows
	var f := FileAccess.open(out + "/eval.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  "))
	f.close()
	for line in DeckLayout.summary(report):
		print(line)
	print("deck-layout-capture: %d sky-mask poses, %d failures" % [rows.size(), failures])
	demo.queue_free()
	await process_frame
	quit(1 if failures else 0)
