extends SceneTree
## R2-CAMERA: the player camera's views on the bridge, rendered for review (open every frame).
## Each zoom level (Z1 Close, Z2 Deck, Z3 Whole level) at the bridge spawn, at rest and in the
## 0.99c cruise review snapshot (sky_review.json, gamma 7.09), at 1280x720 and 2560x1440; plus the
## three levels from a rail-ring and a stations-ring standing point at 1280x720 in cruise. The
## capture fails if a player view's eye leaves the 95 m envelope or the captain's head is off frame.
## make camera-views-capture -> renders/camera_views/*.png + manifest.json
var demo: Node
var out := "res://renders/camera_views"
var shots := []
var failures := 0
var px := Vector2i(1280, 720)


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	for size: Vector2i in [Vector2i(1280, 720), Vector2i(2560, 1440)]:
		px = size
		# A window can be clamped by the screen (2560x1288 here): render the root viewport at exactly
		# px and scale it into the window (as tools/bench.gd).
		root.size = px
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
		root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
		root.content_scale_size = px
		await _build(px)
		if demo == null:
			quit(1)
			return
		for state in ["rest", "cruise"]:
			demo.set_sky_state(state)
			for lv in [1, 2, 3]:
				await _shot(Vector3(8, 82, -4.8), lv, "spawn_z%d_%s_%dp" % [lv, state, px.y])
		if px.y == 720:
			demo.set_sky_state("cruise")
			var rail: Vector3 = demo.walk_bridge.closest_walkable(Vector3(18.0 * cos(deg_to_rad(100.0)), 82.0, 18.0 * sin(deg_to_rad(100.0))), 3.0)
			var stations: Vector3 = demo.consoles.stations["navigation"].use
			for lv in [1, 2, 3]:
				await _shot(rail, lv, "rail_z%d_cruise_720p" % lv)
				await _shot(stations, lv, "stations_z%d_cruise_720p" % lv)
		demo.queue_free()
		await process_frame
	var f := FileAccess.open(out + "/manifest.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"about": "R2-CAMERA player views (third person, FOV 78, eye inside the 95 m envelope); sky rendered through the same pose", "shots": shots}, "  "))
	f.close()
	print("camera-views-capture: %d frames, %d failures" % [shots.size(), failures])
	quit(1 if failures else 0)


func _build(px: Vector2i) -> void:
	demo = load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options = {"sky_state": "rest", "size": px}
	root.add_child(demo)
	await process_frame
	if not demo.ready_ok:
		demo = null
		return
	demo.auto = false
	demo.director.set_motion("reduced") # each level is a cut: no half-eased frames
	demo.ship_hud.visible = false
	demo.geometry_view.size = px
	demo._sync_observer()


func _shot(foot: Vector3, lv: int, name: String) -> void:
	var dir: CameraDirector = demo.director
	demo.avatar_pos = foot
	demo.captain_yaw = atan2(-foot.z, -foot.x)
	dir.set_level(lv)
	for i in 4:
		demo._process(0.25) # settle the follow and clear the cut's fade
	for i in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	demo.geometry_view.size = px
	var image := root.get_texture().get_image()
	image.save_png(out + "/" + name + ".png")
	if image.get_size() != px:
		push_error("%s: rendered %s, wanted %s" % [name, image.get_size(), px])
		failures += 1
	var pose: Transform3D = demo.camera.global_transform
	var head: Vector3 = dir.head_of(dir.views[dir.view_id], foot)
	var sp := CameraDirector.screen_point(pose, head, Vector2(px))
	var in_frame := not is_nan(sp.x) and Rect2(Vector2.ZERO, Vector2(px)).has_point(sp)
	var ok: bool = pose.origin.length() <= 95.0 and in_frame and demo.avatar.visible and dir.level == lv and not dir.overridden
	if not ok:
		failures += 1
	shots.append({"name": name, "ok": ok, "level": lv, "view": dir.view_id, "cell": dir.sector, "eye_m": [pose.origin.x, pose.origin.y, pose.origin.z], "eye_radius_m": pose.origin.length(), "captain_foot_m": [foot.x, foot.y, foot.z], "head_px": [sp.x, sp.y], "figure_px": CameraDirector.figure_px(pose, foot, 1.754, px.y), "resolution": [image.get_width(), image.get_height()], "sky_state": demo.sky_state, "beta": demo.sky.beta})
	print("%s %s |eye| %.2f m head %s" % ["ok  " if ok else "FAIL", name, pose.origin.length(), sp])
