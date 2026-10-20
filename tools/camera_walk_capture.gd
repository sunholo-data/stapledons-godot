extends SceneTree
## R2-CAMERA-FORWARD (design_docs/planned/r2/camera-forward.md): the player camera over a scripted
## walk around the spire, driven by the real CameraDirector (no override): for each walk sample the
## captain is put down, the camera settles (follow, slide, fades: 1.5 s of play at 60 Hz), and the
## frame is grabbed with where the forward pole (the bow, D-92) and the captain's head land.
##   passes: bow_rest, bow_cruise (the "cruise" sky state, 0.99c), astern_rest
##   out:    renders/camera_walk/<pass>_r<radius>_<i>.png, contact_sheet.png, walk.json
## make camera-walk-capture (GPU window; open every frame). Fails a Bow sample without the pole in
## frame, or any sample without the captain's head in frame.
var demo: Node
var out := "res://renders/camera_walk"
var px := Vector2i(1280, 720)
var rows := []
var failures := 0
const ANGLES := 8
const RADII := [10.0, 17.0]
const TILE := Vector2i(320, 180)
const PASSES := [["bow_rest", "bow", "rest"], ["bow_cruise", "bow", "cruise"], ["astern_rest", "astern", "rest"]]
var sheet: Image


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
	sheet = Image.create(TILE.x * ANGLES, TILE.y * RADII.size() * PASSES.size(), false, Image.FORMAT_RGB8)
	var row := 0
	for p: Array in PASSES:
		if not await _new_demo({"sky_state": p[2]}):
			print("FAIL could not build %s" % p[0])
			failures += 1
			continue
		demo.ship_hud.visible = false
		demo.director.walk(p[1])
		for k in 240: # a 180 deg switch eases for up to 3 s
			demo._process(1.0 / 60.0)
		for r: float in RADII:
			for i in ANGLES:
				await _sample(p[0], p[1], r, i, row)
			row += 1
		await _free()
	sheet.save_png(out + "/contact_sheet.png")
	var f := FileAccess.open(out + "/walk.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"about": "R2-CAMERA-FORWARD: the director's walk views over a scripted walk around the spire (yaw/pitch deg, screen px at 1280x720; the pole is the bow, glTF -z)", "samples": rows}, "  "))
	f.close()
	for p: Array in PASSES:
		var s: Array = rows.filter(func(x): return x.pass == p[0])
		var yaws: Array = s.map(func(x): return x.yaw_deg)
		print("camera-walk %s: samples=%d yaw_spread_deg=%.4f pole_in_frame=%d head_in_frame=%d" % [p[0], s.size(), _spread(yaws),
			s.filter(func(x): return x.pole_in_frame).size(), s.filter(func(x): return x.head_in_frame).size()])
	print("camera-walk-capture: %d frames, %d failures" % [rows.size(), failures])
	quit(1 if failures else 0)


## The widest circular spread of a set of yaws (deg): 0 when the camera never turns.
func _spread(yaws: Array) -> float:
	var worst := 0.0
	for a: float in yaws:
		for b: float in yaws:
			worst = maxf(worst, absf(wrapf(a - b, -180.0, 180.0)))
	return worst


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
	demo.geometry_view.size = px
	demo._sync_observer()
	return true


func _free() -> void:
	if is_instance_valid(demo):
		demo.queue_free()
		await process_frame
	demo = null


func _sample(pass_name: String, view: String, r: float, i: int, row: int) -> void:
	var a := TAU * float(i) / ANGLES
	var foot: Variant = demo.walk_bridge.closest_walkable(Vector3(r * cos(a), 82.0, r * sin(a)), 4.0)
	if not foot is Vector3:
		print("FAIL %s r=%.0f i=%d: no walkable point" % [pass_name, r, i])
		failures += 1
		return
	demo.consoles.cancel_walk()
	demo.avatar_pos = foot
	for k in 90:
		demo._process(1.0 / 60.0)
	for k in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var name := "%s_r%02d_%d" % [pass_name, int(r), i]
	image.save_png(out + "/" + name + ".png")
	var pose: Transform3D = demo.camera.global_transform
	var yp := CameraDirector.yaw_pitch(pose)
	var v := Vector2(px)
	var pole := CameraDirector.screen_point(pose, pose.origin + CameraDirector.pole_dir() * 1000.0, v)
	var head := CameraDirector.screen_point(pose, (foot as Vector3) + Vector3.UP * 1.6, v)
	var frame := Rect2(Vector2.ZERO, v)
	var s := {"pass": pass_name, "view": demo.director.view_id, "name": name, "foot_m": [foot.x, foot.y, foot.z],
		"yaw_deg": rad_to_deg(yp.x), "pitch_deg": rad_to_deg(yp.y), "walk_yaw_deg": rad_to_deg(demo.director.walk_yaw()),
		"pole_px": [pole.x, pole.y], "pole_in_frame": not is_nan(pole.x) and frame.has_point(pole),
		"head_px": [head.x, head.y], "head_in_frame": not is_nan(head.x) and frame.has_point(head),
		"figure_px": CameraDirector.figure_px(pose, foot, 1.6, v.y), "eye_radius_m": pose.origin.length(), "beta": demo.sky.beta,
		"fading": demo.director.occ_fading.map(func(n): return str(n.name))}
	rows.append(s)
	if (view == "bow" and not s.pole_in_frame) or not s.head_in_frame or demo.director.view_id != view:
		print("FAIL %s: pole %s head %s view %s" % [name, s.pole_in_frame, s.head_in_frame, demo.director.view_id])
		failures += 1
	var tile := image.duplicate() as Image
	tile.convert(Image.FORMAT_RGB8)
	tile.resize(TILE.x, TILE.y, Image.INTERPOLATE_BILINEAR)
	sheet.blit_rect(tile, Rect2i(Vector2i.ZERO, TILE), Vector2i(i * TILE.x, row * TILE.y))
	print("%s yaw %.2f pitch %.2f pole %s head %s fig %.0f px fading %s" % [name, s.yaw_deg, s.pitch_deg, "in" if s.pole_in_frame else "out", "in" if s.head_in_frame else "out", s.figure_px, s.fading])
