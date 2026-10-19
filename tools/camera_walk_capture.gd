extends SceneTree
## R2-CAMERA-FORWARD (design_docs/planned/r2/camera-forward.md): the player camera over a scripted
## walk around the spire. For each walk sample it records the camera's yaw and pitch, where the
## forward pole (+y, the travel axis) and the captain's head land on screen, and grabs a frame.
##   passes: "rest"  (the default level view, Z2, ship at rest)
##           "under_way" (a committed voyage: the default under-way view, cruise at >= 0.9c)
##   out:    renders/camera_walk/<pass>_<i>.png, contact_sheet.png, walk.json
## make camera-walk-capture (GPU window; open every frame). It measures; it does not judge:
## the acceptance thresholds live in the Makefile recipe and tests/test_camera_forward.gd.
var demo: Node
var out := "res://renders/camera_walk"
var px := Vector2i(1280, 720)
var rows := []
var failures := 0
const ANGLES := 8
const RADII := [10.0, 17.0]
const TILE := Vector2i(320, 180)
var sheet: Image
var bow := false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
		if a == "--bow":
			bow = true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	root.size = px
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.content_scale_size = px
	if bow:
		await _bow_run()
		return
	sheet = Image.create(TILE.x * ANGLES, TILE.y * RADII.size() * 2, false, Image.FORMAT_RGB8)
	var row := 0
	for pass_name in ["rest", "under_way"]:
		if not await _build(pass_name):
			print("FAIL could not build %s" % pass_name)
			failures += 1
			continue
		for r: float in RADII:
			for i in ANGLES:
				await _sample(pass_name, r, i, row)
			row += 1
		await _free()
	sheet.save_png(out + "/contact_sheet.png")
	var f := FileAccess.open(out + "/walk.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"about": "camera over a scripted walk around the spire (yaw/pitch deg, screen px at 1280x720)", "samples": rows}, "  "))
	f.close()
	for pass_name in ["rest", "under_way"]:
		var yaws: Array = rows.filter(func(s): return s.pass == pass_name).map(func(s): return s.yaw_deg)
		var spread := _spread(yaws)
		var pole_in: int = rows.filter(func(s): return s.pass == pass_name and s.pole_in_frame).size()
		var head_in: int = rows.filter(func(s): return s.pass == pass_name and s.head_in_frame).size()
		print("camera-walk %s: samples=%d yaw_spread_deg=%.1f pole_in_frame=%d head_in_frame=%d" % [pass_name, yaws.size(), spread, pole_in, head_in])
	print("camera-walk-capture: %d frames, %d failures" % [rows.size(), failures])
	quit(1 if failures else 0)


## The widest circular spread of a set of yaws (deg): 0 when the camera never turns.
func _spread(yaws: Array) -> float:
	if yaws.is_empty():
		return 0.0
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


func _build(pass_name: String) -> bool:
	if pass_name == "rest":
		if not await _new_demo({"sky_state": "rest"}):
			return false
		demo.ship_hud.visible = false
		return true
	# under way: a real voyage committed at the helm, then cruise (the departure cue's default view)
	if not await _new_demo({"live_start": true, "sky_state": "rest"}):
		return false
	var c: ShipConsoles = demo.consoles
	c.go_to("navigation")
	c.use("navigation", "open")
	c.use("navigation", "speed", Relativity.rapidity_of_beta(0.9999))
	if not (c.use("navigation", "commit") and demo.journey_tick()):
		return false
	var guard := 0
	while demo.sky.beta < 0.9 and guard < 4000:
		demo.journey_tick()
		guard += 1
	c.cancel_walk()
	c.escape()
	for i in 120:
		demo._process(1.0 / 60.0)
	demo.ship_hud.visible = false
	return demo.under_way()


func _sample(pass_name: String, r: float, i: int, row: int) -> void:
	var a := TAU * float(i) / ANGLES
	var want := Vector3(r * cos(a), 82.0, r * sin(a))
	var foot: Variant = demo.walk_bridge.closest_walkable(want, 4.0)
	if not foot is Vector3:
		print("skip %s r=%.0f i=%d: no walkable point near %s" % [pass_name, r, i, want])
		return
	demo.consoles.cancel_walk()
	demo.avatar_pos = foot
	demo.captain_yaw = atan2(-foot.z, -foot.x)
	for k in 90: # 1.5 s of play at 60 Hz: the follow and any sector swing settle
		demo._process(1.0 / 60.0)
	for k in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var name := "%s_r%02d_%d" % [pass_name, int(r), i]
	image.save_png(out + "/" + name + ".png")
	var pose: Transform3D = demo.camera.global_transform
	var yp := CameraDirector.yaw_pitch(pose)
	var pole := CameraDirector.screen_point(pose, pose.origin + Vector3.UP * 1000.0, Vector2(px))
	var head := CameraDirector.screen_point(pose, (foot as Vector3) + Vector3.UP * 1.6, Vector2(px))
	var frame := Rect2(Vector2.ZERO, Vector2(px))
	var s := {"pass": pass_name, "name": name, "foot_m": [foot.x, foot.y, foot.z], "view": demo.director.view_id, "situation": demo.director.situation,
		"yaw_deg": rad_to_deg(yp.x), "pitch_deg": rad_to_deg(yp.y), "walk_yaw_deg": rad_to_deg(demo.director.walk_yaw()),
		"pole_px": [pole.x, pole.y], "pole_in_frame": not is_nan(pole.x) and frame.has_point(pole),
		"head_px": [head.x, head.y], "head_in_frame": not is_nan(head.x) and frame.has_point(head), "eye_radius_m": pose.origin.length(), "beta": demo.sky.beta}
	rows.append(s)
	var tile := image.duplicate() as Image
	tile.convert(Image.FORMAT_RGB8)
	tile.resize(TILE.x, TILE.y, Image.INTERPOLATE_BILINEAR)
	sheet.blit_rect(tile, Rect2i(Vector2i.ZERO, TILE), Vector2i(i * TILE.x, row * TILE.y))
	print("%s yaw %.1f pitch %.1f pole %s head %s view %s" % [name, s.yaw_deg, s.pitch_deg, "in" if s.pole_in_frame else "out", "in" if s.head_in_frame else "out", s.view if s.situation == "" else s.situation])


# ------------------------------------------------------------------ D-92 candidates (--bow)
## Candidate default views under D-92 (travel along the deck, glTF -Z = the bow): a fixed yaw toward
## the bow, a fixed pitch, the eye back_m behind the captain's feet (toward +Z) and rise_m above the
## deck, sliding with the captain (no dead zone here: every sample is the settled pose). The sky is
## rendered with ShipCamera.travel_axis = "bow" (the prototype basis), so the starbow is where D-92
## puts it.
const CANDIDATES := {"A": [-8.0, 9.0, 5.5], "B": [-12.0, 9.0, 6.5], "C": [-16.0, 10.0, 8.5]}
const STARBOW := {"0.9c": 25.842, "0.99c": 8.1}


func _bow_run() -> void:
	load("res://demos/ship_demo_camera.gd").travel_axis = "bow"
	var states := ["rest", "cruise"]
	sheet = Image.create(TILE.x * ANGLES, TILE.y * RADII.size() * states.size() * CANDIDATES.size(), false, Image.FORMAT_RGB8)
	var row := 0
	for state: String in states:
		if not await _new_demo({"sky_state": state}):
			print("FAIL could not build %s" % state)
			failures += 1
			continue
		demo.ship_hud.visible = false
		demo.director.override()
		demo.camera_mode = "tool" # the demo then never re-poses the camera itself
		for cid: String in CANDIDATES:
			for r: float in RADII:
				for i in ANGLES:
					await _bow_sample(state, cid, r, i, row)
				row += 1
		await _free()
	sheet.save_png(out + "/contact_sheet_bow.png")
	var f := FileAccess.open(out + "/walk_bow.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"about": "D-92 candidate default views (pitch, back_m, rise_m) over the bridge walk; travel along glTF -Z; px at 1280x720", "candidates": CANDIDATES, "samples": rows}, "  "))
	f.close()
	for state: String in states:
		for cid: String in CANDIDATES:
			var s: Array = rows.filter(func(x): return x.state == state and x.candidate == cid)
			var n := s.size()
			var figs: Array = s.map(func(x): return x.figure_px)
			print("camera-walk bow %s %s %s: samples=%d pole_in_frame=%d pole_clear=%d starbow_0.9c_in=%d starbow_0.99c_in=%d head_in_frame=%d figure_px=%.0f..%.0f horizon_y=%.0f deck_frac=%.2f" % [state, cid, CANDIDATES[cid], n,
				s.filter(func(x): return x.pole_in_frame).size(), s.filter(func(x): return x.pole_clear).size(),
				s.filter(func(x): return x.starbow_09_in).size(), s.filter(func(x): return x.starbow_099_in).size(),
				s.filter(func(x): return x.head_in_frame).size(), figs.min() if n else 0.0, figs.max() if n else 0.0,
				s[0].pole_px[1] if n else 0.0, s[0].deck_frac if n else 0.0])
	print("camera-walk-capture: %d frames, %d failures" % [rows.size(), failures])
	quit(1 if failures else 0)


func _bow_sample(state: String, cid: String, r: float, i: int, row: int) -> void:
	var a := TAU * float(i) / ANGLES
	var foot: Variant = demo.walk_bridge.closest_walkable(Vector3(r * cos(a), 82.0, r * sin(a)), 4.0)
	if not foot is Vector3:
		print("skip bow %s r=%.0f i=%d" % [cid, r, i])
		return
	var c: Array = CANDIDATES[cid]
	var pitch := deg_to_rad(float(c[0]))
	var eye: Vector3 = foot + Vector3(0.0, float(c[2]), float(c[1]))
	var pose := Transform3D(Basis.looking_at(Vector3(0.0, sin(pitch), -cos(pitch)), Vector3.UP), eye)
	demo.avatar_pos = foot
	demo.captain_yaw = 0.0
	demo._process(1.0 / 60.0) # sky and lighting update as in play; the pose is written after it
	demo.avatar.position = foot
	demo.avatar.visible = true
	demo.camera.global_transform = pose
	demo._sync_observer()
	for k in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var name := "bow_%s_%s_r%02d_%d" % [state, cid, int(r), i]
	image.save_png(out + "/" + name + ".png")
	var v := Vector2(px)
	var inside := Rect2(Vector2(0, 40), v - Vector2(0, 80))
	var pole_dir := Vector3.FORWARD
	var pole := CameraDirector.screen_point(pose, eye + pole_dir * 1000.0, v)
	var sb9 := CameraDirector.screen_point(pose, eye + Vector3(0.0, sin(deg_to_rad(STARBOW["0.9c"])), -cos(deg_to_rad(STARBOW["0.9c"]))) * 1000.0, v)
	var sb99 := CameraDirector.screen_point(pose, eye + Vector3(0.0, sin(deg_to_rad(STARBOW["0.99c"])), -cos(deg_to_rad(STARBOW["0.99c"]))) * 1000.0, v)
	var head := CameraDirector.screen_point(pose, (foot as Vector3) + Vector3.UP * 1.6, v)
	var space: PhysicsDirectSpaceState3D = demo.camera.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(eye, eye + pole_dir * 120.0)
	q.hit_back_faces = true
	var hit := space.intersect_ray(q)
	var s := {"state": state, "candidate": cid, "name": name, "foot_m": [foot.x, foot.y, foot.z],
		"pole_px": [pole.x, pole.y], "pole_in_frame": not is_nan(pole.x) and inside.has_point(pole), "pole_clear": hit.is_empty(),
		"pole_hit": "" if hit.is_empty() else str((hit.collider as Node).name),
		"starbow_09_in": not is_nan(sb9.x) and inside.has_point(sb9), "starbow_099_in": not is_nan(sb99.x) and inside.has_point(sb99),
		"head_px": [head.x, head.y], "head_in_frame": not is_nan(head.x) and Rect2(Vector2.ZERO, v).has_point(head),
		"figure_px": CameraDirector.figure_px(pose, foot, 1.6, v.y), "deck_frac": clampf((v.y - pole.y) / v.y, 0.0, 1.0), "eye_radius_m": eye.length()}
	rows.append(s)
	var tile := image.duplicate() as Image
	tile.convert(Image.FORMAT_RGB8)
	tile.resize(TILE.x, TILE.y, Image.INTERPOLATE_BILINEAR)
	sheet.blit_rect(tile, Rect2i(Vector2i.ZERO, TILE), Vector2i(i * TILE.x, row * TILE.y))
	print("%s pole %s %s head %s fig %.0f px" % [name, "in" if s.pole_in_frame else "out", "clear" if s.pole_clear else "blocked:" + s.pole_hit, "in" if s.head_in_frame else "out", s.figure_px])
