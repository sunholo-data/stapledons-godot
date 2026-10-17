extends SceneTree
## R2-CAMERA: the player camera's views rendered for review (open every frame; the contact sheets
## put each size on one page). make camera-views-capture -> renders/camera_views/
##   views:  z1 z2 z3 (bridge), sky_forward sky_side sky_aft, z1/z2/z3 lower deck, lift
##   states: rest and 0.99c cruise (sky_review.json), a guided stop (the guided voyage's first
##           stop, the stop turn done) and Sgr A* (the demo's first hover)
##   sizes:  1280x720 and 2560x1440 (the root viewport is rendered at exactly that size)
##   cruise: the DEFAULT player view of a real committed voyage (the departure cue) at
##           beta >= 0.9, 0.99 and 0.999 (cruise_default_b*.png): the starbow must be in frame
## The capture fails if a player view's eye leaves the 95 m envelope, the captain's head is off
## frame, or the default cruise view does not frame the forward pole.
var demo: Node
var out := "res://renders/camera_views"
var shots := []
var failures := 0
var px := Vector2i(1280, 720)
var sheet := {} # size -> Image
const VIEWS := ["z1", "z2", "z3_bridge", "sky_forward", "sky_side", "sky_aft", "z1_lower", "z2_lower", "z3_commons", "lift"]
const STATES := ["rest", "cruise", "stop", "sgr_a"]
const TILE := Vector2i(320, 180)


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var sizes: Array = [Vector2i(1280, 720), Vector2i(2560, 1440)]
	for a in OS.get_cmdline_user_args():
		if a == "--quick":
			sizes = [Vector2i(1280, 720)]
	for size: Vector2i in sizes:
		px = size
		root.size = px
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
		root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
		root.content_scale_size = px
		sheet[px.y] = Image.create(TILE.x * VIEWS.size(), TILE.y * STATES.size(), false, Image.FORMAT_RGB8)
		for state in STATES:
			if not await _build(state):
				print("FAIL could not build state %s" % state)
				failures += 1
				continue
			for i in VIEWS.size():
				await _shot(VIEWS[i], state, i, STATES.find(state))
			await _free()
		(sheet[px.y] as Image).save_png(out + "/contact_sheet_%dp.png" % px.y)
		await _cruise_default()
	var f := FileAccess.open(out + "/manifest.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"about": "R2-CAMERA player views (third person, FOV 78, eye inside the 95 m envelope); sky rendered through the same pose", "views": VIEWS, "states": STATES, "shots": shots}, "  "))
	f.close()
	print("camera-views-capture: %d frames, %d failures" % [shots.size(), failures])
	quit(1 if failures else 0)


func _new_demo(opts: Dictionary) -> bool:
	demo = load("res://demos/ship_geometry_demo.tscn").instantiate()
	var o := {"size": px}
	o.merge(opts, true)
	demo.setup_options = o
	root.add_child(demo)
	await process_frame
	if not demo.ready_ok:
		return false
	demo.auto = false
	demo.journey_auto_tick = false
	demo.ship_hud.visible = false
	demo.geometry_view.size = px
	demo._sync_observer()
	return true


func _free() -> void:
	if is_instance_valid(demo):
		if demo.black_hole != null:
			demo.leave_black_hole()
		demo.queue_free()
		await process_frame
	demo = null


func _build(state: String) -> bool:
	match state:
		"rest", "cruise":
			if not await _new_demo({"sky_state": state}):
				return false
		"stop":
			if not await _new_demo({"live_start": true, "sky_state": "rest"}) or not demo.start_solar_departure():
				return false
			for i in 900: # the first stop's turn (3 s) at 60 Hz, simulation held while it turns
				demo._process(1.0 / 60.0)
				if demo.solar_tour.attitude_hold:
					demo.journey_tick()
				if not demo.solar_tour.attitude_hold and demo._attitude_mode.is_empty() and i > 10:
					break
		"sgr_a":
			if not await _new_demo({"live_start": true, "sky_state": "rest"}) or not demo.start_black_hole():
				return false
	demo.director.set_motion("reduced") # each view is a cut: no half-eased frames
	demo.ship_hud.visible = false
	return true


## Put the captain where the view needs them and select it.
func _select(id: String) -> Vector3:
	var dir: CameraDirector = demo.director
	demo.consoles.cancel_walk()
	if demo.lift.travelling() or demo.active_level != 0:
		demo.lift.reset()
		demo.active_level = 0
		demo.walk = demo.walk_bridge
	dir.situation = ""
	dir._pending = ""
	dir.hold = false
	var foot := Vector3(8, 82, -4.8)
	var v: Dictionary = dir.views[id]
	if id.ends_with("_lower") or id == "z3_commons":
		demo.active_level = 1
		demo.walk = demo.walk_lower
		foot = Vector3(8, 57, -4.8)
	if id == "lift":
		demo.avatar_pos = foot
		demo._process(0.25)
		demo.lift.board()
		demo.lift.advance(0.81)
		demo.lift.advance(5.5)
		foot = demo.avatar_pos
	else:
		var anchor: Variant = dir.anchor_of(v, foot) if v.get("kind") == "situation" and id != "sky_forward" else null
		if anchor is Vector3:
			foot = anchor
		demo.avatar_pos = foot
		demo.captain_yaw = atan2(-foot.z, -foot.x)
		demo._process(0.25)
		if v.get("kind") == "situation":
			dir.sky(id)
		else:
			dir.set_level(int(v.level))
	for i in 4:
		demo._process(0.25) # settle the follow and clear the cut's fade
	return foot


func _grab(name: String) -> Image:
	demo.geometry_view.size = px
	for i in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(out + "/" + name + ".png")
	if image.get_size() != px:
		push_error("%s: rendered %s, wanted %s" % [name, image.get_size(), px])
		failures += 1
	return image


func _shot(id: String, state: String, col: int, row: int) -> void:
	var dir: CameraDirector = demo.director
	var foot := _select(id)
	var name := "%s_%s_%dp" % [id, state, px.y]
	var image := await _grab(name)
	var pose: Transform3D = demo.camera.global_transform
	var head: Vector3 = demo.avatar_pos + Vector3.UP * 1.6
	var sp := CameraDirector.screen_point(pose, head, Vector2(px))
	var in_frame := not is_nan(sp.x) and Rect2(Vector2.ZERO, Vector2(px)).has_point(sp)
	var ok: bool = pose.origin.length() <= 95.0 and in_frame and demo.avatar.visible and dir.view_id == id and not dir.overridden
	if not ok:
		failures += 1
	var tile := image.duplicate() as Image
	tile.convert(Image.FORMAT_RGB8)
	tile.resize(TILE.x, TILE.y, Image.INTERPOLATE_BILINEAR)
	(sheet[px.y] as Image).blit_rect(tile, Rect2i(Vector2i.ZERO, TILE), Vector2i(col * TILE.x, row * TILE.y))
	shots.append({"name": name, "ok": ok, "view": dir.view_id, "state": state, "eye_m": [pose.origin.x, pose.origin.y, pose.origin.z], "eye_radius_m": pose.origin.length(), "captain_foot_m": [foot.x, foot.y, foot.z], "head_px": [sp.x, sp.y], "resolution": [image.get_width(), image.get_height()], "beta": demo.sky.beta})
	print("%s %s view %s |eye| %.2f m head %s" % ["ok  " if ok else "FAIL", name, dir.view_id, pose.origin.length(), sp])


## A real voyage committed at the helm: whatever the player camera does by default (the departure
## cue: Sky forward), captured as the ship passes 0.9, 0.99 and 0.999c.
func _cruise_default() -> void:
	if not await _new_demo({"live_start": true, "sky_state": "rest"}):
		failures += 1
		return
	var c: ShipConsoles = demo.consoles
	c.go_to("navigation")
	c.use("navigation", "open")
	c.use("navigation", "speed", Relativity.rapidity_of_beta(0.9999))
	if not (c.use("navigation", "commit") and demo.journey_tick()):
		print("FAIL the helm did not commit")
		failures += 1
		await _free()
		return
	for i in 120:
		demo._process(1.0 / 60.0) # the cue's 1.5 s ease, full motion (the player's default)
	var marks := [0.9, 0.99, 0.999]
	var best := 0.0
	for i in 20000:
		if marks.is_empty() or not demo.live_journey:
			break
		var b: float = float(demo.sky_world.ship.beta)
		best = maxf(best, b)
		if b >= marks[0]:
			var name := "cruise_default_b%s_%dp" % [str(marks[0]).replace("0.", ""), px.y]
			demo._process(1.0 / 60.0)
			demo.sky.update_exposure()
			await _grab(name)
			var pose: Transform3D = demo.camera.global_transform
			var pole := CameraDirector.screen_point(pose, pose.origin + Vector3.UP * 1000.0, Vector2(px))
			var head := CameraDirector.screen_point(pose, demo.avatar_pos + Vector3.UP * 1.6, Vector2(px))
			var ok: bool = demo.director.situation == "sky_forward" and not is_nan(pole.x) and Rect2(Vector2.ZERO, Vector2(px)).has_point(pole) and Rect2(Vector2.ZERO, Vector2(px)).has_point(head)
			if not ok:
				failures += 1
			shots.append({"name": name, "ok": ok, "view": demo.director.view_id, "state": "committed voyage", "beta": b, "gamma": demo.sky_world.ship.gamma, "phase": demo.sky_world.ship.phase, "pole_px": [pole.x, pole.y], "head_px": [head.x, head.y]})
			print("%s %s beta %.6f view %s pole %s" % ["ok  " if ok else "FAIL", name, b, demo.director.view_id, pole])
			marks.pop_front()
		if not demo.journey_tick():
			break
		demo._process(0.05)
	if not marks.is_empty():
		print("FAIL the voyage did not reach %s (best beta %.6f)" % [marks, best])
		failures += 1
	await _free()
