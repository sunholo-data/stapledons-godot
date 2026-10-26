extends SceneTree
## R2-DECK-LAYOUT re-plan for the Bow view (design_docs/planned/r2/deck-layout.md §Evidence, ledger
## D-94): scores candidate bridge layouts through the real Bow and Astern walk views (D-93) and,
## with a GPU window, captures them. A layout file (schema stapledons.deck.layout/1, DeckLayout)
## moves the named prop groups in-engine and rebuilds the walk; the Blender export stays the source
## of truth (this is search and review evidence only).
##
## The measurements are DeckBowMetrics' (tools/deck_bow_metrics.gd, the bow evaluator's). Per layout,
## over every bridge walk sample (0.5 m grid) and both walk views:
##   fade       samples where an occluder must fade (CameraDirector.occluders_for), by family
##   blocked    samples not clear after the fades (pole ray / captain's head / eye inside)
##   body       samples whose ray toward a stop body (30 deg off the bow, port or starboard, at the
##              horizon) hits ship geometry (members included: they fade only for the pole)
##   spawn      the open walk straight ahead (bow-ward) of the spawn, and the first thing hit
##   stations   per active station's use point: the station in the Bow frame, the head clear, fades
##   near       the share of a 64x36 frame grid hitting geometry nearer than the captain (spawn)
## Usage: godot --headless --path . --script tools/deck_bow_probe.gd -- --layouts a.json,b.json
##        [--capture] [--out res://renders/deck_bow]
var demo: Node
var dl: DeckLayout
var out := "res://renders/deck_bow"
var px := Vector2i(1280, 720)
var capture := false
var dump := false
var sheet: Array = []
var report := {}
const BASE := "res://art/deck-layout-v1/layout_current.json"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var layouts: Array = [BASE]
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--layouts="):
			layouts = Array(a.trim_prefix("--layouts=").split(","))
		elif a.begins_with("--sheet="):
			sheet = Array(a.trim_prefix("--sheet=").split(","))
		elif a == "--capture":
			capture = true
		elif a == "--dump":
			dump = true
		elif a.begins_with("--out="):
			out = a.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	if not sheet.is_empty():
		_sheet(sheet)
		quit(0)
		return
	if capture:
		root.size = px
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
		root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
		root.content_scale_size = px
	var base := DeckLayout.load_layout(BASE)
	for path: String in layouts:
		var lay := DeckLayout.load_layout(path)
		var tag := str(lay.get("name", path.get_file().get_basename()))
		if not await _new_demo({"sky_state": "rest"}, lay, base):
			continue
		if dump:
			_dump()
		report[tag] = _metrics()
		_print(tag, report[tag])
		if capture:
			await _plan(tag)
			var sp := dl.spawn()
			await _shot(tag, "bow_rest_spawn", "bow", sp)
			await _shot(tag, "astern_rest_spawn", "astern", sp)
			var helm: Variant = _use_point("console_navigation_1")
			if helm is Vector3:
				await _shot(tag, "bow_rest_helm", "bow", helm)
			await _shot(tag, "bow_rest_walk3", "bow", null)
			await _free()
			if await _new_demo({"sky_state": "cruise"}, lay, base):
				await _shot(tag, "bow_cruise_spawn", "bow", dl.spawn())
				for id: String in ["navigation", "voyage", "crew"]:
					await _console(tag, id)
			await _free()
			if await _new_demo({"live_start": true, "sky_state": "rest"}, lay, base) and demo.start_solar_departure():
				var guard := 0
				while guard < 2400 and (demo.solar_tour.attitude_hold or demo.under_way() or demo._attitude_stop < -1):
					demo._process(1.0 / 60.0)
					if demo.solar_tour.attitude_hold:
						demo.journey_tick()
					guard += 1
				demo.ship_hud.visible = false
				if not demo.under_way():
					await _shot(tag, "bow_stop_spawn", "bow", dl.spawn())
		await _free()
	var f := FileAccess.open(out + "/probe.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  "))
	f.close()
	print("deck-bow-probe: %d layouts" % report.size())
	quit(0)


func _new_demo(opts: Dictionary, lay: Dictionary, base: Dictionary) -> bool:
	demo = load("res://demos/ship_geometry_demo.tscn").instantiate()
	var o := {"size": px}
	o.merge(opts, true)
	demo.setup_options = o
	root.add_child(demo)
	await process_frame
	if not demo.ready_ok:
		print("FAIL demo did not build %s" % opts)
		return false
	demo.auto = false
	demo.journey_auto_tick = false
	demo.ship_hud.visible = false
	if capture:
		demo.geometry_view.size = px
	dl = DeckLayout.new(demo)
	var errs := dl.apply(lay, base)
	if not errs.is_empty():
		print("FAIL layout %s: %s" % [lay.get("name", "?"), errs])
		return false
	# Moved props' colliders reach the physics space only after the transform notifications flush.
	for k in 3:
		await process_frame
		await physics_frame
	return true


func _free() -> void:
	if is_instance_valid(demo):
		demo.queue_free()
		await process_frame
	demo = null


func _family(n: Node) -> String:
	return DeckBowMetrics.family(demo, n)


## A station's use point by its walk mesh (DeckBowMetrics.use_point).
func _use_point(mesh_name: String) -> Variant:
	for id: String in ShipConsoles.STATIONS:
		if ShipConsoles.STATIONS[id].walk == mesh_name:
			return DeckBowMetrics.new(demo, dl).use_point(id)
	return null


func _metrics() -> Dictionary:
	return DeckBowMetrics.new(demo, dl).metrics()


## A comparison sheet from frames already in `out`: one row per layout tag, one column per shot
## (each 480x270 with a 24 px gap); missing frames stay dark.
const SHEET_COLS := ["plan", "bow_rest_spawn", "bow_cruise_spawn", "bow_stop_spawn", "astern_rest_spawn", "console_navigation"]
func _sheet(tags: Array) -> void:
	var w := 480
	var h := 270
	var g := 24
	var img := Image.create(SHEET_COLS.size() * (w + g) + g, tags.size() * (h + g) + g, false, Image.FORMAT_RGB8)
	img.fill(Color(0.06, 0.06, 0.08))
	for r in tags.size():
		for c in SHEET_COLS.size():
			var path := ProjectSettings.globalize_path("%s/%s_%s.png" % [out, tags[r], SHEET_COLS[c]])
			if not FileAccess.file_exists(path):
				continue
			var f := Image.load_from_file(path)
			f.convert(Image.FORMAT_RGB8)
			f.resize(w, h, Image.INTERPOLATE_LANCZOS)
			img.blit_rect(f, Rect2i(0, 0, w, h), Vector2i(g + c * (w + g), g + r * (h + g)))
	img.save_png("%s/contact_sheet.png" % out)
	print("deck-bow-probe: sheet rows %s, columns %s" % [tags, SHEET_COLS])


## Every prop group's plan centre: glTF (x, z), ship metres (x, y), bearing from the bow (deg,
## + starboard) and radius.
func _dump() -> void:
	for id: String in DeckLayout.GROUPS:
		var n := demo.geometry.find_child(DeckLayout.GROUPS[id][0], true, false) as MeshInstance3D
		if n == null:
			continue
		var c: Vector3 = (n.global_transform * n.mesh.get_aabb()).get_center()
		var sz: Vector3 = (n.global_transform * n.mesh.get_aabb()).size
		print("dump %-22s gltf (%6.2f, %6.2f) ship (%6.2f, %6.2f) bearing %7.1f r %5.2f size %s" % [id, c.x, c.z, c.x, -c.z, rad_to_deg(atan2(c.x, -c.z)), Vector2(c.x, c.z).length(), sz])
	for nm: String in ["archive_shrine_ribs", "spire_needle", "ramp_down", "Guardrail 82", "Guardrail 82_001", "Guardrail 82_002"]:
		var n := demo.geometry.find_child(nm, true, false) as MeshInstance3D
		if n != null:
			var a: AABB = n.global_transform * n.mesh.get_aabb()
			print("dump %-22s aabb %s" % [nm, a])


func _print(tag: String, m: Dictionary) -> void:
	print("== %s (%d samples)" % [tag, m.samples])
	for vid: String in ["bow", "astern"]:
		print("  %s: fade %d %s blocked %s%s" % [vid, m[vid].fade, m[vid].families, m[vid].blocked, (" body %s" % m[vid].body_blocked) if m[vid].has("body_blocked") else ""])
		print("    fronds %s captain_by %s%s" % [m[vid].frond_by, m[vid].captain_by, ("  body_by %s both %d" % [m[vid].body_by, m[vid].body_both]) if m[vid].has("body_by") else ""])
	print("  spawn %s" % m.spawn)
	for id: String in m.stations:
		print("  station %s %s" % [id, m.stations[id]])


## Top-down plan of the bridge (orthographic, the bow up), with the spawn (green) and the active
## stations' use points (yellow).
func _plan(tag: String) -> void:
	var marks := []
	var spots := [[dl.spawn(), Color(0.2, 1.0, 0.3)]]
	for id: String in ShipConsoles.STATIONS:
		if ShipConsoles.STATIONS[id].active:
			var u: Variant = _use_point(ShipConsoles.STATIONS[id].walk)
			if u is Vector3:
				spots.append([u, Color(1.0, 0.85, 0.1)])
	for s: Array in spots:
		var mi := MeshInstance3D.new()
		var sph := SphereMesh.new()
		sph.radius = 0.6
		sph.height = 1.2
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = s[1]
		sph.material = mat
		mi.mesh = sph
		demo.camera.get_parent().add_child(mi)
		mi.global_position = (s[0] as Vector3) + Vector3.UP * 3.0
		marks.append(mi)
	var cam := Camera3D.new()
	demo.camera.get_parent().add_child(cam)
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 46.0
	cam.far = 400.0
	cam.global_transform = Transform3D(Basis.looking_at(Vector3.DOWN, ShipCamera.BOW), Vector3(0, 82.0 + 60.0, 0))
	cam.current = true
	for k in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s_plan.png" % [out, tag])
	cam.current = false
	demo.camera.current = true
	cam.queue_free()
	for mi: Node in marks:
		mi.queue_free()


## The console focus by ShipConsoles.focus_pose's rule (the eye 1.25 m out on the operator's side
## and 0.55 m above the console top, looking at it), from the moved mesh and its use point.
func _console(tag: String, id: String) -> void:
	if DeckBowMetrics.new(demo, dl).shipped():
		await _game_console(tag, id)
		return
	var mesh: String = ShipConsoles.STATIONS[id].walk
	var n := demo.geometry.find_child(mesh, true, false) as MeshInstance3D
	var u: Variant = _use_point(mesh)
	if n == null or not u is Vector3:
		return
	var box: AABB = n.global_transform * n.mesh.get_aabb()
	var c := box.get_center()
	var top := Vector3(c.x, box.end.y, c.z)
	var o := Vector3((u as Vector3).x - c.x, 0.0, (u as Vector3).z - c.z).normalized()
	var eye := top + o * 1.25 + Vector3.UP * 0.55
	demo.avatar_pos = u
	demo.director.override()
	demo.camera_mode = "console" # the game's console mode: no player follow, the captain hidden
	demo.avatar.visible = false
	demo.camera.global_transform = Transform3D(Basis.looking_at(top - eye + Vector3.UP * -0.1, Vector3.UP), eye)
	demo._sync_observer()
	for k in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s_console_%s.png" % [out, tag, id])
	demo.camera_mode = "player"
	demo.director.release()
	var pole := CameraDirector.screen_point(demo.camera.global_transform, eye + CameraDirector.pole_dir() * 1000.0, Vector2(px))
	var inf := (not is_nan(pole.x)) and Rect2(Vector2.ZERO, Vector2(px)).has_point(pole)
	print("shot %s_console_%s eye %s pole_px %s pole_in_frame %s" % [tag, id, eye, pole, inf])


## foot null: walk 3 m toward the bow (W held) from where the captain stands.
func _shot(tag: String, name: String, view: String, foot: Variant) -> void:
	demo.consoles.cancel_walk()
	demo.director.walk(view)
	if foot is Vector3:
		demo.avatar_pos = foot
		for k in 240:
			demo._process(1.0 / 60.0)
	else:
		for k in int(3.0 / ShipConsoles.WALK_SPEED_MPS * 60.0): # 3 m toward the bow at the walk speed
			demo.walk_motion(Vector2(0, 1), 1.0 / 60.0)
			demo._process(1.0 / 60.0)
		demo.walk_motion(Vector2.ZERO, 1.0 / 60.0)
		for k in 60:
			demo._process(1.0 / 60.0)
	for k in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s_%s.png" % [out, tag, name])
	print("shot %s_%s foot %s fading %s" % [tag, name, demo.avatar_pos, demo.director.occ_fading.map(func(n: Node) -> String: return _family(n))])


## The shipped deck: the game's own console zoom (walk there, E, the director's ease to the screen),
## the panel hidden so the frame shows the console, its idle screen and the sky beyond.
func _game_console(tag: String, id: String) -> void:
	var c: ShipConsoles = demo.consoles
	c.go_to(id)
	for k in 30:
		demo._process(1.0 / 60.0)
	var opened := c.use(id, "open")
	for k in 300:
		demo._process(1.0 / 60.0)
	c.panel.visible = false
	var map: Variant = demo.get("journey_map")
	if map is CanvasItem or map is Window:
		map.visible = false # the helm's chart opens over the zoom; hide it to show the console
	for k in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s_console_%s.png" % [out, tag, id])
	var cam: Transform3D = demo.camera.global_transform
	var pole := CameraDirector.screen_point(cam, cam.origin + CameraDirector.pole_dir() * 1000.0, Vector2(px))
	print("shot %s_console_%s opened %s mode %s eye %s pole_px %s pole_in_frame %s" % [tag, id, opened, demo.camera_mode, cam.origin, pole, (not is_nan(pole.x)) and Rect2(Vector2.ZERO, Vector2(px)).has_point(pole)])
	c.escape()
	for k in 300:
		demo._process(1.0 / 60.0)
