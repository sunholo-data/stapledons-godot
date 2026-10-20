extends SceneTree
## R2-CAMERA-FORWARD F1 review set (the dev-build pause point): the player's walk views as Mark will
## see them, through the real director (no override), at 1280x720:
##   bow_rest_spawn, bow_rest_helm, bow_fade_spire (the captain sternward of the spire: the needle
##   faded), astern_rest_spawn, bow_cruise_spawn and bow_cruise_port (0.99c), bow_stop (the guided
##   voyage's first stop, after the stop turn: the body 30 deg off the bow) and bow_stop_walk (the
##   captain walked 3 m toward the bow: the camera slid, never turned)
## out: renders/camera_forward/<name>.png + review.json. make camera-forward-review (GPU window; open
## every frame). Fails a frame without the captain's head in frame, or a Bow frame without the pole.
var demo: Node
var out := "res://renders/camera_forward"
var px := Vector2i(1280, 720)
var rows := []
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	root.size = px
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.content_scale_size = px
	if await _new_demo({"sky_state": "rest"}):
		await _shot("bow_rest_spawn", "bow", demo.bridge_spawn())
		await _shot("bow_rest_helm", "bow", demo.consoles.stations["navigation"].use)
		await _shot("bow_fade_spire", "bow", demo.walk_bridge.closest_walkable(Vector3(0, 82, 12), 4.0))
		await _shot("astern_rest_spawn", "astern", demo.bridge_spawn())
		await _free()
	if await _new_demo({"sky_state": "cruise"}):
		await _shot("bow_cruise_spawn", "bow", demo.bridge_spawn())
		await _shot("bow_cruise_port", "bow", demo.walk_bridge.closest_walkable(Vector3(-12, 82, 4), 4.0))
		await _free()
	if await _new_demo({"live_start": true}):
		var ok: bool = demo.start_solar_departure()
		var guard := 0
		# The first stop: the turn done (attitude hold released) and the ship not under way.
		while guard < 2400 and (demo.solar_tour.attitude_hold or demo.under_way() or demo._attitude_stop < -1):
			demo._process(1.0 / 60.0)
			if demo.solar_tour.attitude_hold:
				demo.journey_tick()
			guard += 1
		if not ok or demo.under_way():
			print("FAIL guided voyage: no stop reached (guard %d)" % guard)
			failures += 1
		else:
			demo.ship_hud.visible = false
			await _shot("bow_stop", "bow", demo.walk_bridge.closest_walkable(Vector3(-12, 82, 6), 4.0)) # clear deck ahead (the spawn faces the lift)
			await _shot("bow_stop_walk", "bow", null)
		await _free()
	var f := FileAccess.open(out + "/review.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"about": "R2-CAMERA-FORWARD F1 review frames (1280x720): the director's walk views; px are screen positions", "frames": rows}, "  "))
	f.close()
	print("camera-forward-review: %d frames, %d failures" % [rows.size(), failures])
	quit(1 if failures else 0)


func _new_demo(opts: Dictionary) -> bool:
	demo = load("res://demos/ship_geometry_demo.tscn").instantiate()
	var o := {"size": px}
	o.merge(opts, true)
	demo.setup_options = o
	root.add_child(demo)
	await process_frame
	if not demo.ready_ok:
		print("FAIL demo did not build %s" % opts)
		failures += 1
		return false
	demo.auto = false
	demo.journey_auto_tick = false
	demo.geometry_view.size = px
	demo.ship_hud.visible = false
	return true


func _free() -> void:
	if is_instance_valid(demo):
		demo.queue_free()
		await process_frame
	demo = null


## foot null: walk the captain 3 m toward the bow (W held 0.86 s) from where it stands.
func _shot(name: String, view: String, foot: Variant) -> void:
	demo.consoles.cancel_walk()
	demo.director.walk(view)
	if foot is Vector3:
		demo.avatar_pos = foot
		for k in 240: # a 180 deg switch eases for up to 3 s; the follow and the fades settle
			demo._process(1.0 / 60.0)
	else:
		var before: Transform3D = demo.camera.global_transform
		var start: Vector3 = demo.avatar_pos
		for k in 52:
			demo.walk_motion(Vector2(0, 1), 1.0 / 60.0)
			demo._process(1.0 / 60.0)
		demo.walk_motion(Vector2.ZERO, 1.0 / 60.0)
		for k in 60:
			demo._process(1.0 / 60.0)
		print("%s: walked %.2f m; yaw before %.4f after %.4f deg; eye moved %s" % [name, start.distance_to(demo.avatar_pos), rad_to_deg(CameraDirector.yaw_pitch(before).x), rad_to_deg(CameraDirector.yaw_pitch(demo.camera.global_transform).x), demo.camera.global_transform.origin - before.origin])
	for k in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(out + "/" + name + ".png")
	var pose: Transform3D = demo.camera.global_transform
	var v := Vector2(px)
	var at: Vector3 = demo.avatar_pos
	var pole := CameraDirector.screen_point(pose, pose.origin + CameraDirector.pole_dir() * 1000.0, v)
	var head := CameraDirector.screen_point(pose, at + Vector3.UP * 1.6, v)
	var frame := Rect2(Vector2.ZERO, v)
	var r := {"name": name, "view": demo.director.view_id, "foot_m": [at.x, at.y, at.z], "yaw_deg": rad_to_deg(CameraDirector.yaw_pitch(pose).x),
		"pole_px": [pole.x, pole.y], "head_px": [head.x, head.y], "beta": demo.sky.beta,
		"fading": demo.director.occ_fading.map(func(n): return str(n.name)), "figure_px": CameraDirector.figure_px(pose, at, 1.754, v.y)}
	rows.append(r)
	var ok: bool = not is_nan(head.x) and frame.has_point(head) and demo.director.view_id == view and (view != "bow" or (not is_nan(pole.x) and frame.has_point(pole)))
	if not ok:
		failures += 1
	print("%s %s view %s yaw %.2f pole %s head %s beta %.4f fading %s" % ["ok  " if ok else "FAIL", name, r.view, r.yaw_deg, pole, head, r.beta, r.fading])
