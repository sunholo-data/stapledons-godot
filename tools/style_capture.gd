extends SceneTree
## R2-BRIDGE-STYLE AC10 (design_docs/implemented/r2/bridge-styling-pass.md §S6): the review set through the
## real views, GPU window, 1280x720. Frames (each with the HUD off, and "<name>_hud" with it on):
##   bow_deep     the Bow view at the spawn, interstellar at rest (no star close: the spire keys the bridge)
##   bow_star     the same near the Sun (the star keys it, the spire at its floor)
##   bow_cruise   0.99c in interstellar space (the review "cruise" world)
##   bow_stop     the guided voyage's first stop, after the stop turn
##   astern_deep, astern_star   the Astern view at the spawn
##   bow_fade     the Bow view with the captain sternward of the spire (the mast fades), deep space
##   zoom_navigation, zoom_voyage, zoom_crew   the console close-ups (ShipConsoles.focus_pose), deep space
##   hud_arrival  the Bow view near the Sun with the HUD and the arrival card (review values)
## Writes renders/style/<tag>/*.png, style.json (the lights per frame) and contact_sheet.png; with
## --before=<dir> also before_after.png (rows: before, after) for the frames both runs have.
## Usage: godot --path . --script tools/style_capture.gd -- --tag=<tag> [--before=res://renders/style/before]
var demo: Node
var out := ""
var before := ""
var px := Vector2i(1280, 720)
var rows := []
var failures := 0
const ZOOMS := {"navigation": "console_navigation_1", "voyage": "console_decision_0", "crew": "console_decision_1"}
const SHEET := ["bow_deep", "bow_star", "bow_cruise", "bow_stop", "astern_deep", "astern_star", "bow_fade", "zoom_navigation", "zoom_voyage", "zoom_crew", "bow_deep_hud", "astern_deep_hud", "bow_star_hud", "bow_cruise_hud", "bow_stop_hud", "hud_arrival"]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var tag := "capture"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--tag="): tag = a.trim_prefix("--tag=")
		elif a.begins_with("--before="): before = a.trim_prefix("--before=")
	out = "res://renders/style/" + tag
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	root.size = px
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.content_scale_size = px
	var cap: GDScript = load("res://tools/deck_dl2_capture.gd") # its sky worlds (static helpers)
	if await _new_demo({"sky_state": "rest"}):
		var star: Dictionary = cap._with_sun(demo.sky_states.rest)
		demo.sky_states["star"] = star
		demo.sky_states["deep"] = cap._pushed(star, 2.5e8)
		for st: String in ["deep", "star"]:
			demo.set_sky_state(st)
			await _view("bow_" + st, "bow")
			await _view("astern_" + st, "astern")
		demo.set_sky_state("deep")
		await _view("bow_fade", "bow", demo.walk_bridge.closest_walkable(Vector3(0, 82, 12), 4.0))
		for id: String in ZOOMS:
			await _zoom("zoom_" + id, id)
		demo.set_sky_state("star")
		await _arrival()
		await _free()
	if await _new_demo({"sky_state": "cruise"}):
		await _view("bow_cruise", "bow")
		await _free()
	if await _new_demo({"live_start": true}):
		var ok: bool = demo.start_solar_departure()
		var guard := 0
		while guard < 2400 and (demo.solar_tour.attitude_hold or demo.under_way() or demo._attitude_stop < -1):
			demo._process(1.0 / 60.0)
			if demo.solar_tour.attitude_hold:
				demo.journey_tick()
			guard += 1
		if not ok or demo.under_way():
			print("FAIL guided voyage: no stop reached (guard %d)" % guard)
			failures += 1
		else:
			await _view("bow_stop", "bow")
		await _free()
	_sheet(SHEET, out + "/contact_sheet.png", [out])
	if before != "":
		var both: Array = SHEET.filter(func(n: String) -> bool: return FileAccess.file_exists(ProjectSettings.globalize_path("%s/%s.png" % [before, n])))
		_sheet(both, out + "/before_after.png", [before, out])
	var f := FileAccess.open(out + "/style.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"about": "R2-BRIDGE-STYLE review frames (1280x720): the lights per frame", "tag": tag, "frames": rows}, "  "))
	f.close()
	print("style-capture: %d frames, %d failures" % [rows.size(), failures])
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
	return true


func _free() -> void:
	if is_instance_valid(demo):
		demo.queue_free()
		await process_frame
	demo = null


func _view(name: String, view: String, foot: Variant = null) -> void:
	demo.consoles.cancel_walk()
	demo.director.release()
	demo.camera_mode = "player"
	demo.director.walk(view)
	demo.avatar_pos = foot if foot is Vector3 else (demo.bridge_spawn() if not name.begins_with("bow_stop") else demo.walk_bridge.closest_walkable(Vector3(-12, 82, 6), 4.0))
	for k in 240:
		demo._process(1.0 / 60.0)
	demo.ship_hud.visible = false
	await _save(name)
	demo.ship_hud.visible = true
	await _save(name + "_hud")
	demo.ship_hud.visible = false


## The arrival card as the game builds it (ship_geometry_demo: show_card("arrival"), one line per
## ArrivalCard.ROWS, the Dismiss button), its values review text (the journey's real values need a
## whole voyage), over the Bow view near the Sun with the HUD on.
func _arrival() -> void:
	demo.consoles.cancel_walk()
	demo.director.release()
	demo.camera_mode = "player"
	demo.director.walk("bow")
	demo.avatar_pos = demo.bridge_spawn()
	var hud: ShipHud = demo.ship_hud
	for k in 240:
		demo._process(1.0 / 60.0)
	hud.visible = true
	hud.show_card("arrival", "Arrived")
	var values := ["4.246 ly", "1.902 yr", "4.351 yr", "2.449 yr"]
	for i in ArrivalCard.ROWS.size():
		hud.set_card_value("review_%d" % i, values[i])
		hud._binding_row(hud.card_body("arrival"), ArrivalCard.ROWS[i][0], "hud.cardtext.review_%d" % i, "text")
	hud.card_button("arrival", "Dismiss [Enter]", func() -> void: pass)
	# The review world is not an arrived journey, so the demo's own HUD pass would close the card:
	# hold the demo for the shot and let only the HUD fade the card in.
	demo.process_mode = Node.PROCESS_MODE_DISABLED
	hud.update((hud._last_view as Dictionary).duplicate(true)) # the bindings read the review values (hud.cardtext); the strip keeps the world's
	for k in 60:
		hud.advance(1.0 / 60.0)
	print("arrival card present: %s" % hud.has_card("arrival"))
	await _save("hud_arrival")
	demo.process_mode = Node.PROCESS_MODE_INHERIT
	hud.visible = false
	hud.hide_card("arrival")


## The game's console close-up pose, held without opening the station (its panel would cover the frame).
func _zoom(name: String, id: String) -> void:
	var c: ShipConsoles = demo.consoles
	demo.director.override()
	demo.avatar_pos = c.stations[id].use
	for k in 240: # the star light eases (TAU_S) after a sky change: settle before the shot
		demo._process(1.0 / 60.0)
	demo.camera_mode = "review"
	var pullback: float = demo.camera.pullback
	demo.camera.pullback = 0.0 # the overridden director shows the captain only when pulled back: hidden, as at a console
	demo.camera.global_transform = c.focus_pose(ZOOMS[id])
	demo._sync_observer()
	demo.ship_hud.visible = false
	await _save(name)
	demo.camera.pullback = pullback
	demo.camera_mode = "player"
	demo.director.release()


func _save(name: String) -> void:
	for k in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [out, name])
	var rig: Dictionary = demo.lighting
	var r := {"name": name, "star": demo.star_light.target.get("name", ""), "star_energy": demo.star_light.light.light_energy, "star_shadow": demo.star_light.light.shadow_enabled,
		"key_energy": rig.key.light_energy, "key_shadow": rig.key.shadow_enabled, "spire_energy": rig.spire.light_energy, "spire_shadow": rig.spire.shadow_enabled, "beta": demo.sky.beta, "hud": demo.ship_hud.visible}
	rows.append(r)
	print("shot %s star %s %.2f key %.2f spire %.2f%s beta %.4f" % [name, r.star, r.star_energy, r.key_energy, r.spire_energy, " (shadow)" if r.spire_shadow else "", r.beta])


## Rows of thumbnails: one row per source dir (before, after) or, for one dir, 4 columns.
func _sheet(names: Array, path: String, dirs: Array) -> void:
	var w := 480
	var h := 270
	var g := 16
	var cols: int = names.size() if dirs.size() > 1 else 4
	var nrows: int = dirs.size() if dirs.size() > 1 else ceili(names.size() / 4.0)
	if names.is_empty(): return
	var img := Image.create(cols * (w + g) + g, nrows * (h + g) + g, false, Image.FORMAT_RGB8)
	img.fill(Color(0.06, 0.06, 0.08))
	for i in names.size():
		for d in dirs.size():
			var p := ProjectSettings.globalize_path("%s/%s.png" % [dirs[d], names[i]])
			if not FileAccess.file_exists(p): continue
			var f := Image.load_from_file(p)
			f.convert(Image.FORMAT_RGB8)
			f.resize(w, h, Image.INTERPOLATE_LANCZOS)
			var c: int = i if dirs.size() > 1 else i % 4
			var r: int = d if dirs.size() > 1 else i / 4
			img.blit_rect(f, Rect2i(0, 0, w, h), Vector2i(g + c * (w + g), g + r * (h + g)))
	img.save_png(ProjectSettings.globalize_path(path))
