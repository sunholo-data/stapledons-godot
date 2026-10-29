extends SceneTree
## R1-SHIP-UI U7 (AC14): the ship UI's review frames from the real sim, in the player's
## default Auto view (D-55), at 1280x720 and 2560x1440, plus a contact sheet.
## make ship-ui-capture -> renders/ship_ui/<frame>_<w>x<h>.png and contact_sheet.png.
## Fails on a missing frame or a uniform one (per-frame luminance standard deviation below a
## floor). A person opens every frame; the inspection notes live in the sprint JSON.
## Args after --: sizes=1280x720,2560x1440 scales=1,1.5 frames=a,b (subset; default all).
## VFU: bridge_help, lower_help, commons_<stage> and commons_<stage>_help use actual
## player camera poses; manifest.json records pixel/canvas size and the actual UI scale.

const OUT := "res://renders/ship_ui"
const STD_FLOOR := 0.02
const FRAMES := ["strip_rest", "prompt_navigation", "helm_focused", "chart", "voyage_console", "archive_terminal", "archive_question", "voyage_log", "transit_cruise", "tour_interlude", "arrival", "tour_dwell", "sgr_a_gravity", "lower_deck"]
const JOURNEY_FRAMES := ["transit_cruise", "tour_interlude", "arrival", "tour_dwell", "sgr_a_gravity"]
var demo: Node
var sizes: Array = [Vector2i(1280, 720), Vector2i(2560, 1440)]
var scales: Array = [1.0]
var ui_scale := 1.0
var only: PackedStringArray = []
var written: Array = []
var records: Array = []
var failed := false


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("sizes="):
			sizes = []
			for s in a.trim_prefix("sizes=").split(","):
				var p := s.split("x")
				sizes.append(Vector2i(int(p[0]), int(p[1])))
		if a.begins_with("frames="):
			only = a.trim_prefix("frames=").split(",")
		if a.begins_with("scales="):
			scales = []
			for s in a.trim_prefix("scales=").split(","): scales.append(clampf(float(s), UiScale.MIN, UiScale.MAX))
	_run.call_deferred()


func want(frame: String) -> bool:
	return only.is_empty() or only.has(frame)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for sz: Vector2i in sizes:
		for scale: float in scales:
			ui_scale = scale
			await capture_size(sz)
	for frame: String in only:
		if records.filter(func(r: Dictionary) -> bool: return r.frame == frame).size() != sizes.size() * scales.size():
			push_error("Missing requested UI review frame: " + frame)
			failed = true
	contact_sheet()
	var manifest := FileAccess.open(OUT + "/manifest.json", FileAccess.WRITE)
	manifest.store_string(JSON.stringify({"about": "Actual player camera and HUD; logical canvas and pixel size recorded independently", "frames": records}, "  "))
	print("ship-ui-capture: %s (%d frames)" % ["FAIL" if failed else "OK", written.size()])
	quit(1 if failed else 0)


func settle(frames := 8) -> void:
	for i in frames:
		demo._process(0.05)
		await process_frame
	await RenderingServer.frame_post_draw


func shot(frame: String, sz: Vector2i) -> void:
	if not want(frame):
		return
	await settle()
	var img := root.get_texture().get_image()
	var suffix := "" if is_equal_approx(ui_scale, 1.0) else "_ui%s" % str(ui_scale).replace(".", "p")
	var path := "%s/%s_%dx%d%s.png" % [OUT, frame, sz.x, sz.y, suffix]
	var sd := luminance_sd(img)
	if img.get_size() != sz or sd < STD_FLOOR:
		push_error("frame %s: size %s, luminance sd %.4f" % [frame, img.get_size(), sd])
		failed = true
	img.save_png(path)
	written.append(path)
	records.append({"frame": frame, "file": path.get_file(), "pixels": [sz.x, sz.y], "ui_scale": root.content_scale_factor, "canvas": [demo.ship_hud.size.x, demo.ship_hud.size.y], "camera": demo.director.view_id, "level": demo.level_context() if demo.has_method("level_context") else {"id": "commons" if demo.active_level == 1 else "bridge", "legacy_views": demo.active_level == 1}})
	print("frame %s %dx%d sd=%.4f" % [frame, img.get_width(), img.get_height(), sd])


static func luminance_sd(img: Image) -> float:
	var small := img.duplicate() as Image
	small.resize(160, 90, Image.INTERPOLATE_BILINEAR)
	var n := 0
	var s := 0.0
	var s2 := 0.0
	for y in small.get_height():
		for x in small.get_width():
			var c := small.get_pixel(x, y)
			var l := 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
			s += l
			s2 += l * l
			n += 1
	var m := s / n
	return sqrt(maxf(0.0, s2 / n - m * m))


func capture_size(sz: Vector2i) -> void:
	root.size = sz
	get_root().get_window().size = sz
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	root.content_scale_size = sz
	root.content_scale_factor = ui_scale
	demo = load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options = {"live_start": true, "sky_state": "rest", "auto_view": true, "size": sz}
	root.add_child(demo)
	await process_frame
	demo.auto = false
	demo.journey_auto_tick = false
	if not demo.ready_ok:
		failed = true
		return
	demo.set_preset("bridge")
	demo.look_direction("forward")
	await shot("strip_rest", sz)
	await more_frames(sz)
	# UI-only review rounds avoid replaying an unrelated voyage for every size/zoom.
	if not only.is_empty() and not Array(only).any(func(f: String) -> bool: return f in JOURNEY_FRAMES):
		await commons_frames(sz)
		demo.queue_free()
		await process_frame
		return
	# A free-navigation commit to alpha Cen, then cruise and arrival.
	demo.open_navigation()
	if not (demo.journey_map.open_commit_dialog() and demo.journey_map.hold_commit(GalaxyMap.HOLD_S) and demo.journey_tick()):
		failed = true
		return
	demo.close_navigation()
	var cruised := false
	for i in 4000:
		if not demo.live_journey:
			break
		demo.journey_tick()
		if not cruised and demo.sky_world.ship.phase == "cruising":
			cruised = true
			demo.look_direction("forward")
			await shot("transit_cruise", sz)
			# R2-INTERLUDE I3: the crossing review over this real cruise (strip and review read the
			# same state); the guided voyage shows it on its long legs.
			var rv: Dictionary = demo.hud_view()
			rv["review"] = {"leg": demo.stop_name(), "target": demo.stop_name()}
			demo.crossing_review.visible = true
			demo.crossing_review.show_review(rv, true)
			demo._place_interlude()
			await shot("tour_interlude", sz)
			demo.crossing_review.visible = false
	demo.look_direction("side")
	await shot("arrival", sz)
	demo.dismiss_arrival()
	# The guided voyage: the tour card at a stop's dwell, then its first leg under way.
	demo.start_solar_departure()
	for i in 80:
		demo._process(0.05)
	await shot("tour_dwell", sz)
	demo.skip_dwell()
	for i in 100:
		if demo.live_journey:
			break
		demo._process(0.05)
	for i in 200:
		if not demo.live_journey:
			break
		demo.skip_stage()
		demo.journey_tick()
	# Sgr A*: the gravity card (mockup C).
	if demo.start_black_hole():
		demo.bh_next_stop()
		demo.bh_finish_approach()
		demo.look_direction("forward")
		await shot("sgr_a_gravity", sz)
		demo.leave_black_hole()
	await commons_frames(sz)
	demo.queue_free()
	await process_frame


func commons_frames(sz: Vector2i) -> void:
	demo.set_preset("reset")
	demo.avatar_pos = Vector3(8, 82, -4.8) # the lift's landing (R2-DECK-LAYOUT: no longer the spawn)
	demo.lift.board()
	demo.lift.advance(0.81); demo.lift.advance(11.01); demo.lift.advance(0.81)
	demo.look_direction("side")
	await shot("lower_deck", sz)
	demo.ship_hud.toggle_tab()
	await shot("lower_help", sz)
	demo.ship_hud.toggle_tab()
	var commons: Dictionary = demo.director.levels.get("commons", {})
	for stage: Dictionary in commons.get("manifest", {}).get("stages", []):
		demo.avatar_pos = ShipFrame.gltf_from_structure(stage.spawn)
		demo.walk = demo.walk_lower
		demo.director.zoom_preset = false
		demo.director.has_pose = false
		await shot("commons_" + str(stage.id), sz)
		demo.ship_hud.toggle_tab()
		await shot("commons_" + str(stage.id) + "_help", sz)
		demo.ship_hud.toggle_tab()


## The bridge consoles (U3-U5): the prompt in reach, the helm, the chart, Voyage, Archive.
func more_frames(sz: Vector2i) -> void:
	demo.ship_hud.toggle_tab()
	await shot("bridge_help", sz)
	demo.ship_hud.toggle_tab()
	var c: ShipConsoles = demo.consoles
	c.go_to("navigation")
	await shot("prompt_navigation", sz)
	c.use("navigation", "open")
	for i in 14:
		demo._process(0.05)
	await shot("helm_focused", sz)
	c.leave()
	for i in 14:
		demo._process(0.05)
	demo.open_chart()
	await shot("chart", sz)
	demo.close_navigation()
	c.go_to("voyage")
	c.use("voyage", "open")
	for i in 14:
		demo._process(0.05)
	await shot("voyage_console", sz)
	c.leave()
	c.go_to("archive")
	c.use("archive", "open")
	for i in 14:
		demo._process(0.05)
	await shot("archive_terminal", sz)
	# R1-ARCHIVE-VOICE: a question typed into Ask the Archive (not sent: no live provider here).
	c.ask_field.text = "Do you remember the last captain?"
	await shot("archive_question", sz)
	c.ask_field.text = ""
	c.use("archive", "log")
	for i in 14:
		demo._process(0.05)
	await shot("voyage_log", sz)
	c.leave()
	for i in 14:
		demo._process(0.05)
	demo.set_preset("reset")
	demo.look_direction("forward")


func contact_sheet() -> void:
	var cell := Vector2i(480, 270)
	var cols := 4
	var rows := ceili(written.size() / float(cols))
	if rows == 0:
		failed = true
		return
	var sheet := Image.create(cell.x * cols, cell.y * rows, false, Image.FORMAT_RGB8)
	for i in written.size():
		var img := Image.load_from_file(ProjectSettings.globalize_path(written[i]))
		img.convert(Image.FORMAT_RGB8)
		img.resize(cell.x, cell.y, Image.INTERPOLATE_BILINEAR)
		sheet.blit_rect(img, Rect2i(Vector2i.ZERO, cell), Vector2i((i % cols) * cell.x, (i / cols) * cell.y))
	sheet.save_png(OUT + "/contact_sheet.png")
