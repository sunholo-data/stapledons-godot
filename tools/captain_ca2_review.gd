extends SceneTree
## R2-CAPTAIN-ANIMATION CA2 review set (GPU window, 1280 x 720, the captain ~67-81 px): the held poses as
## the game plays them, through the real views, at 60 fps (in-game time):
##   seq/<beat>_<view>/fNNN.png   station_low (the Voyage desk) and station_mid (the navigation pods):
##                                reach, hold, then step back (the reach reversed); chair: sit, seated,
##                                stand (the sit reversed); look_up on a cue; start_stop: a walk to
##                                starboard starting and stopping, with the procedural lean (and the same
##                                under reduced motion: no lean); lift: the lift pose in all five facings
##   every frame has a cyan line on the deck under the captain; ca2.json: per sequence the clip of every
##   frame and the lowest painted sole against the deck (screen px, + = below; measured on the sprite alone)
## Usage: godot --path . --resolution 1280x720 --script tools/captain_ca2_review.gd -- --out=<dir>
const CAPTAIN := "res://assets/characters/captain"
const CROP := 240
const DT := 1.0 / 60.0
const BOW := Vector3(0, 0, -1)
var demo: Node
var out := ""
var px := Vector2i(1280, 720)
var failures := 0
var report := {"sequences": {}}
var _iso: SubViewport
var _iso_cam: Camera3D
var _iso_sprite: Sprite3D


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	root.size = px
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.content_scale_size = px
	demo = load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options = {"size": px, "sky_state": "rest"}
	root.add_child(demo)
	await process_frame
	if not demo.ready_ok:
		print("FAIL demo did not build"); quit(1); return
	demo.auto = false
	demo.journey_auto_tick = false
	demo.geometry_view.size = px
	demo.ship_hud.visible = false
	demo.process_mode = Node.PROCESS_MODE_DISABLED
	demo.captain_anim_auto = false
	var voyage: Vector3 = demo.consoles.stations["voyage"].use
	var nav: Vector3 = demo.consoles.stations["navigation"].use
	var seat: Vector3 = demo.chair_seat()
	for view in ["bow", "astern"]:
		# Stations: 1.2 s at the desk or the pods, then the step back and idle.
		for pair in [["station_low", voyage, "use_low"], ["station_mid", nav, "use_mid"]]:
			await _sequence("%s_%s" % [pair[0], view], view, pair[1], func(k: int) -> Dictionary:
				return {"station": pair[2] if k < 72 else "", "face_dir": BOW}, 110)
		# The chair: sit, seated 1 s, a move key stands.
		await _sequence("chair_" + view, view, seat, func(k: int) -> Dictionary:
			return {"chair": "sit" if k == 0 else "", "face_dir": BOW, "move_request": k == 100}, 140)
		# The look-up on a cue, at rest.
		await _sequence("look_up_" + view, view, demo.bridge_spawn(), func(k: int) -> Dictionary:
			return {"cue": "look_up" if k == 5 else ""}, 150)
	# Start and stop: a walk to starboard (the Bow view's screen right), with and without reduced motion.
	for reduced in [false, true]:
		var start: Vector3 = demo.walk_bridge.closest_walkable(Vector3(-8, 82, -6), 4.0)
		await _sequence("start_stop_bow" + ("_reduced" if reduced else ""), "bow", start, func(k: int) -> Dictionary:
			return {"velocity": Vector3(1, 0, 0) * ShipConsoles.WALK_SPEED_MPS if k >= 10 and k < 70 else Vector3.ZERO, "reduced": reduced}, 100, true)
	# The lift pose in every facing (one frame each, Bow view).
	var dirs := {"back": BOW, "back_34": Vector3(0.7071, 0, -0.7071), "profile": Vector3(1, 0, 0), "front_34": Vector3(0.7071, 0, 0.7071), "front": Vector3(0, 0, 1)}
	for facing: String in dirs:
		await _sequence("lift_" + facing, "bow", demo.bridge_spawn(), func(k: int) -> Dictionary:
			return {"lift": true, "face_dir": dirs[facing], "heading": dirs[facing]}, 12)
	var f := FileAccess.open(out.path_join("ca2.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  "))
	f.close()
	print("captain-ca2-review: %d sequences, %d failures" % [report.sequences.size(), failures])
	quit(1 if failures else 0)


## Plays `n` frames of a scripted CaptainAnim input at `foot` in `view`, saving every frame (crop) and
## measuring the lowest painted sole against the deck on the sprite alone. `walks`: move the captain.
func _sequence(name: String, view: String, foot: Vector3, script: Callable, n: int, walks := false) -> void:
	demo.director.walk(view)
	demo.avatar_pos = foot
	for k in 240:
		demo._process(DT)
	var a := CaptainAnim.new()
	a.use_gait(demo.avatar.anim.get("clips", {}).get("walk", {}))
	a.heading = BOW
	var dir := out.path_join("seq/" + name)
	DirAccess.make_dir_recursive_absolute(dir)
	var rows := []
	for k in n:
		var inp: Dictionary = script.call(k)
		if inp.has("heading"):
			a.heading = inp.heading
		inp["view_yaw"] = demo.director.walk_yaw()
		var v: Vector3 = inp.get("velocity", Vector3.ZERO)
		if walks and v.length() > 0.0:
			demo.avatar_pos = demo.walk.step(demo.avatar_pos, v * DT)
		var o := a.step(inp, DT)
		demo.avatar.show_anim(o)
		demo._process(DT)
		demo.avatar.show_anim(o)
		var img := await _crop(demo.avatar_pos)
		var deck_y := float(CROP) / 2.0 + _deck_offset()
		var low := _lowest_alpha(await _alone(demo.avatar_pos))
		var below := snappedf(low + 1.0 - deck_y, 0.1)
		_line(img, int(round(deck_y)), Color(0.2, 0.9, 1.0))
		img.save_png(dir.path_join("f%03d.png" % k))
		rows.append({"clip": o.clip, "frame": demo.avatar.shown.get("frame", 0), "source": demo.avatar.shown.get("source", ""), "lean_tan": snappedf(float(demo.avatar.shown.get("lean_tan", 0.0)), 0.0001), "sole_below_px": below})
		if below > 1.0 and demo.avatar.shown.get("source", "") == "frame":
			failures += 1
			print("FAIL %s f%03d: a painted sole %.1f px below the deck" % [name, k, below])
	report.sequences[name] = {"view": view, "frames": n, "ms_per_frame": snappedf(1000.0 * DT, 0.01), "rows": rows}
	print("seq %s: %d frames, clips %s" % [name, n, _runs(rows)])


static func _runs(rows: Array) -> String:
	var s := []
	var last := ""
	var count := 0
	for r: Dictionary in rows:
		if r.clip != last:
			if last != "":
				s.append("%s x%d" % [last, count])
			last = r.clip
			count = 0
		count += 1
	s.append("%s x%d" % [last, count])
	return ", ".join(s)


func _deck_offset() -> float:
	var foot: Vector2 = demo.camera.unproject_position(demo.avatar_pos)
	var mid: Vector2 = demo.camera.unproject_position(demo.avatar_pos + Vector3.UP * 0.88)
	return foot.y - mid.y


func _crop(foot: Vector3) -> Image:
	for k in 2:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	var mid: Vector2 = demo.camera.unproject_position(foot + Vector3.UP * 0.88) * Vector2(img.get_size()) / Vector2(demo.geometry_view.size)
	return img.get_region(Rect2i(Vector2i(mid) - Vector2i(CROP / 2, CROP / 2), Vector2i(CROP, CROP)))


## The captain alone (as tools/captain_fx_review.gd): the same sprite and camera in an empty world.
func _alone(foot: Vector3) -> Image:
	if _iso == null:
		_iso = SubViewport.new()
		_iso.size = px
		_iso.transparent_bg = true
		_iso.own_world_3d = true
		_iso.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(_iso)
		_iso_cam = Camera3D.new()
		_iso.add_child(_iso_cam)
		_iso_sprite = Sprite3D.new()
		_iso.add_child(_iso_sprite)
	var src: CaptainAvatar = demo.avatar
	var cam: Camera3D = demo.camera
	_iso_cam.global_transform = cam.global_transform
	_iso_cam.fov = cam.fov
	_iso_cam.near = cam.near
	_iso_cam.far = cam.far
	_iso_cam.keep_aspect = cam.keep_aspect
	_iso_sprite.texture = src.texture
	_iso_sprite.offset = src.offset
	_iso_sprite.pixel_size = src.pixel_size
	_iso_sprite.flip_h = src.flip_h
	_iso_sprite.centered = src.centered
	_iso_sprite.billboard = src.billboard
	_iso_sprite.shaded = false
	_iso_sprite.alpha_cut = src.alpha_cut
	_iso_sprite.texture_filter = src.texture_filter
	_iso_sprite.global_position = src.global_position
	for k in 2:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := _iso.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	var mid: Vector2 = cam.unproject_position(foot + Vector3.UP * 0.88) * Vector2(img.get_size()) / Vector2(demo.geometry_view.size)
	return img.get_region(Rect2i(Vector2i(mid) - Vector2i(CROP / 2, CROP / 2), Vector2i(CROP, CROP)))


static func _lowest_alpha(img: Image) -> float:
	for y in range(CROP - 1, -1, -1):
		for x in CROP:
			if img.get_pixel(x, y).a > 0.5:
				return float(y)
	return -1.0


static func _line(img: Image, y: int, c: Color) -> void:
	if y < 0 or y >= img.get_height():
		return
	for x in range(0, img.get_width(), 2):
		img.set_pixel(x, y, c)
