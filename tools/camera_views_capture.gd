extends SceneTree
## R2-CAMERA-FORWARD (D-91, D-92; AC-R1): the player camera's views rendered for review (open every
## frame; the contact sheets put each size on one page). make camera-views-capture -> renders/camera_views/
##   views:  bow and astern (the bridge's walk views, fixed yaw, sliding), commons (the legacy lower
##           deck's default, z2_lower) and lift
##   states: rest and 0.99c cruise (sky_review.json), a guided stop (the guided voyage's first stop, the
##           stop turn done: the body 30 deg off the bow) and Sgr A* (the demo's first hover)
##   sizes:  1280x720 and 2560x1440 (the root viewport is rendered at exactly that size)
##   gates:  every frame: |eye| <= 95 m, the captain's head in frame, the view the director reports;
##           Bow also frames its target: the forward pole (rest, cruise), the stop body (stop), the
##           hole (Sgr A*)
##   fade:   a forced-fade frame (Bow, the spire between the eye and the captain): fails unless an
##           occluder is fading; opened by eye for the sort order against the sky
##   cruise: the DEFAULT player view of a real committed voyage (Bow) at beta >= 0.9, 0.99 and 0.999
##           (cruise_default_b*.png): the pole and the starbow edge must be in frame
##   Sgr A*: the DEFAULT player view (Bow) at every stop of the visit, 10^6, 10, 5 and 3 r_s hovers,
##           the 3 r_s orbit and the last hover (sgr_a_stop<n>_*.png): fails unless the hole's centre
##           is in frame and, once the shadow is wider than a pixel, dark there (the shadow)
var demo: Node
var out := "res://renders/camera_views"
var shots := []
var failures := 0
var px := Vector2i(1280, 720)
var sheet := {} # size -> Image
const VIEWS := ["bow", "astern", "commons", "lift"]
## The view id the director reports for each captured view.
const VIEW_ID := {"bow": "bow", "astern": "astern", "commons": "z2_lower", "lift": "lift"}
## A clear bridge foot ahead of the spire (the spawn faces the lift: the deck re-plan, D-90).
const BRIDGE_FOOT := Vector3(-12, 82, 6)
## A foot sternward of the spire: the needle crosses the line to the captain (the forced fade).
const FADE_FOOT := Vector3(0, 82, 12)
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
			if state == "rest":
				await _fade_shot()
			await _free()
		(sheet[px.y] as Image).save_png(out + "/contact_sheet_%dp.png" % px.y)
		await _cruise_default()
		await _sgr_a_stops()
	var f := FileAccess.open(out + "/manifest.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"about": "R2-CAMERA-FORWARD player views (D-91/D-92: fixed walk views that slide, never turn; FOV 78, eye inside the 95 m envelope); sky rendered through the same pose", "views": VIEWS, "states": STATES, "shots": shots}, "  "))
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
				if not demo.solar_tour.attitude_hold and demo._attitude_mode.is_empty() and not demo.tour_attitude.turning() and i > 10:
					break
		"sgr_a":
			if not await _new_demo({"live_start": true, "sky_state": "rest"}) or not demo.start_black_hole():
				return false
	demo.director.set_motion("reduced") # each view is a cut: no half-eased frames
	demo.ship_hud.visible = false
	return true


## Put the captain where the view needs them and select it.
func _select(id: String, at := BRIDGE_FOOT) -> Vector3:
	var dir: CameraDirector = demo.director
	demo.consoles.cancel_walk()
	if demo.lift.travelling() or demo.active_level != 0:
		demo.lift.reset()
		demo.active_level = 0
		demo.walk = demo.walk_bridge
	var foot: Vector3 = demo.walk_bridge.closest_walkable(at, 4.0)
	match id:
		"commons":
			demo.active_level = 1
			demo.walk = demo.walk_lower
			foot = Vector3(8, 57, -4.8)
			demo.avatar_pos = foot
			demo._process(0.25)
			dir.set_level(int(dir.views["z2_lower"].level))
		"lift":
			foot = Vector3(8, 82, -4.8)
			demo.avatar_pos = foot
			demo._process(0.25)
			demo.lift.board()
			demo.lift.advance(0.81)
			demo.lift.advance(5.5)
			foot = demo.avatar_pos
		_:
			demo.avatar_pos = foot
			demo._process(0.25)
			dir.walk(id)
	for i in 4:
		demo._process(0.25) # settle the follow, the fades and the cut's fade
	return foot


## The direction (glTF) of the guided stop's body: the body the stop turn turned to, through the
## attitude the sky is oriented with (as hole_direction() does for the hole).
func _stop_body_dir() -> Vector3:
	var id: String = "earth" if demo.solar_tour.leg_index < 0 else str(demo.solar_tour.itinerary[demo.solar_tour.leg_index].id)
	for body: Dictionary in demo.sky_world.get("system", {}).get("bodies", []):
		if body.id == id or str(body.get("catalogue_id", "")) == id:
			var s := ShipFrame.to_ship(demo.camera.attitude_basis, PackedFloat64Array(ShipFrame._unit([float(body.rel_km.x), float(body.rel_km.y), float(body.rel_km.z)])))
			return ShipCamera.gltf_from_ship([s[0], s[1], s[2]]).normalized()
	return Vector3.ZERO


## What the Bow view must frame in this state: the pole, the stop body or the hole.
func _target(state: String) -> Dictionary:
	match state:
		"stop":
			return {"name": "stop_body", "dir": _stop_body_dir()}
		"sgr_a":
			return {"name": "hole", "dir": demo.hole_direction()}
	return {"name": "pole", "dir": CameraDirector.pole_dir()}


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
	var sp := CameraDirector.screen_point(pose, demo.avatar_pos + Vector3.UP * 1.6, Vector2(px))
	var frame := Rect2(Vector2.ZERO, Vector2(px))
	var head_in := not is_nan(sp.x) and frame.has_point(sp)
	var row_out := {"name": name, "view": dir.view_id, "state": state, "eye_m": [pose.origin.x, pose.origin.y, pose.origin.z], "eye_radius_m": pose.origin.length(), "captain_foot_m": [foot.x, foot.y, foot.z], "head_px": [sp.x, sp.y], "resolution": [image.get_width(), image.get_height()], "beta": demo.sky.beta}
	var target_ok := true
	if id == "bow":
		var t := _target(state)
		var tp := CameraDirector.screen_point(pose, pose.origin + (t.dir as Vector3) * 1000.0, Vector2(px))
		target_ok = (t.dir as Vector3).length() > 0.5 and not is_nan(tp.x) and frame.has_point(tp)
		row_out[t.name + "_px"] = [tp.x, tp.y]
		row_out["target"] = t.name
		row_out["target_off_bow_deg"] = rad_to_deg((t.dir as Vector3).angle_to(ShipCamera.BOW))
	var ok: bool = pose.origin.length() <= 95.0 and head_in and target_ok and demo.avatar.visible and dir.view_id == VIEW_ID[id] and not dir.overridden
	if not ok:
		failures += 1
	row_out["ok"] = ok
	var tile := image.duplicate() as Image
	tile.convert(Image.FORMAT_RGB8)
	tile.resize(TILE.x, TILE.y, Image.INTERPOLATE_BILINEAR)
	(sheet[px.y] as Image).blit_rect(tile, Rect2i(Vector2i.ZERO, TILE), Vector2i(col * TILE.x, row * TILE.y))
	shots.append(row_out)
	print("%s %s view %s |eye| %.2f m head %s%s" % ["ok  " if ok else "FAIL", name, dir.view_id, pose.origin.length(), sp, (" %s %s" % [row_out.get("target", ""), row_out.get(str(row_out.get("target", "")) + "_px", "")]) if id == "bow" else ""])


## The forced fade: Bow with the spire between the eye and the captain; an occluder must be fading
## (25 % opacity) and the frame is opened by eye for the sort order against the sky.
func _fade_shot() -> void:
	var dir: CameraDirector = demo.director
	var foot := _select("bow", FADE_FOOT)
	var name := "bow_fade_rest_%dp" % px.y
	await _grab(name)
	var fading: Array = dir.occ_fading.map(func(n): return str(n.name))
	var ok: bool = not fading.is_empty() and dir.view_id == "bow"
	if not ok:
		failures += 1
	shots.append({"name": name, "ok": ok, "view": dir.view_id, "state": "rest, forced fade", "captain_foot_m": [foot.x, foot.y, foot.z], "fading": fading})
	print("%s %s fading %s" % ["ok  " if ok else "FAIL", name, fading])


## A real voyage committed at the helm: whatever the player camera does by default (the departure
## cue: Bow), captured as the ship passes 0.9, 0.99 and 0.999c.
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
			var frame := Rect2(Vector2.ZERO, Vector2(px))
			var pole := CameraDirector.screen_point(pose, pose.origin + CameraDirector.pole_dir() * 1000.0, Vector2(px))
			# relativity-spec §2: a rest-frame 90 deg star appears at acos(beta) from the pole
			var a := acos(b)
			var edge := CameraDirector.screen_point(pose, pose.origin + Vector3(0.0, sin(a), -cos(a)) * 1000.0, Vector2(px))
			var head := CameraDirector.screen_point(pose, demo.avatar_pos + Vector3.UP * 1.6, Vector2(px))
			var ok: bool = demo.director.view_id == "bow" and not is_nan(pole.x) and frame.has_point(pole) and not is_nan(edge.x) and frame.has_point(edge) and frame.has_point(head)
			if not ok:
				failures += 1
			shots.append({"name": name, "ok": ok, "view": demo.director.view_id, "state": "committed voyage", "beta": b, "gamma": demo.sky_world.ship.gamma, "phase": demo.sky_world.ship.phase, "pole_px": [pole.x, pole.y], "starbow_edge_px": [edge.x, edge.y], "head_px": [head.x, head.y]})
			print("%s %s beta %.6f view %s pole %s starbow edge %s" % ["ok  " if ok else "FAIL", name, b, demo.director.view_id, pole, edge])
			marks.pop_front()
		if not demo.journey_tick():
			break
		demo._process(0.05)
	if not marks.is_empty():
		print("FAIL the voyage did not reach %s (best beta %.6f)" % [marks, best])
		failures += 1
	await _free()


## The Sgr A* visit as a player flies it: each stop by the navigation's own call, the camera left to
## its cue (Bow: the hole sits on the bow), captured on arrival.
func _sgr_a_stops() -> void:
	if not await _new_demo({"live_start": true, "sky_state": "rest"}) or not demo.start_black_hole():
		print("FAIL Sgr A* did not start")
		failures += 1
		await _free()
		return
	var BlackHoleVisit := load("res://demos/black_hole_visit.gd")
	for stop in BlackHoleVisit.STOPS.size() + 1:
		if stop > 0:
			if not demo.bh_next_stop():
				print("FAIL Sgr A* stop %d refused" % stop)
				failures += 1
				break
			if demo.black_hole.approaching():
				demo.bh_finish_approach()
			else:
				demo._arrived()
		for i in 300:
			demo._process(1.0 / 60.0) # the cue's ease (full motion, the player's default)
		demo.sky.update_exposure()
		var g: Dictionary = demo.black_hole.gr()
		var r := float(g.r)
		var name := "sgr_a_stop%d_%s_r%s_%dp" % [stop, str(g.get("mode", "")), ("%.0f" % r) if r < 100.0 else "1e6", px.y]
		var image := await _grab(name)
		var pose: Transform3D = demo.camera.global_transform
		var h: Vector3 = demo.hole_direction()
		var c := CameraDirector.screen_point(pose, pose.origin + h * 1000.0, Vector2(px))
		var shadow_deg := rad_to_deg(Schwarzschild.shadow_angle(r))
		var shadow_px := tan(deg_to_rad(shadow_deg)) / tan(deg_to_rad(39.0)) * px.y * 0.5
		var in_frame := not is_nan(c.x) and Rect2(Vector2.ZERO, Vector2(px)).has_point(c)
		var lum := image.get_pixelv(Vector2i(c)).get_luminance() if in_frame else 1.0
		var ok: bool = demo.director.view_id == "bow" and in_frame and (shadow_px < 2.0 or lum < 0.03)
		if not ok:
			failures += 1
		shots.append({"name": name, "ok": ok, "view": demo.director.view_id, "state": "Sgr A* stop %d" % stop, "mode": g.get("mode", ""), "r_rs": r, "shadow_radius_deg": shadow_deg, "shadow_radius_px": shadow_px, "hole_px": [c.x, c.y], "luminance_at_centre": lum})
		print("%s %s view %s hole %s shadow %.3f deg (%.0f px) centre luminance %.4f" % ["ok  " if ok else "FAIL", name, demo.director.view_id, c, shadow_deg, shadow_px, lum])
	await _free()
