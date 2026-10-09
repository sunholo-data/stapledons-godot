extends SceneTree
## R1-SHIP-UI U7 (AC14): the ship UI's review frames from the real sim, in the player's
## default Auto view (D-55), at 1280x720 and 2560x1440, plus a contact sheet.
## make ship-ui-capture -> renders/ship_ui/<frame>_<w>x<h>.png and contact_sheet.png.
## Fails on a missing frame or a uniform one (per-frame luminance standard deviation below a
## floor). A person opens every frame; the inspection notes live in the sprint JSON.
## Args after --: sizes=1280x720,2560x1440  frames=a,b (a subset; default all).

const OUT := "res://renders/ship_ui"
const STD_FLOOR := 0.02
const FRAMES := ["strip_rest", "transit_cruise", "tour_interlude", "arrival", "tour_dwell", "sgr_a_gravity", "lower_deck"]
var demo: Node
var sizes: Array = [Vector2i(1280, 720), Vector2i(2560, 1440)]
var only: PackedStringArray = []
var written: Array = []
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
	_run.call_deferred()


func want(frame: String) -> bool:
	return only.is_empty() or only.has(frame)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for sz: Vector2i in sizes:
		await capture_size(sz)
	contact_sheet()
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
	var path := "%s/%s_%dx%d.png" % [OUT, frame, sz.x, sz.y]
	var sd := luminance_sd(img)
	if img.get_size() != sz or sd < STD_FLOOR:
		push_error("frame %s: size %s, luminance sd %.4f" % [frame, img.get_size(), sd])
		failed = true
	img.save_png(path)
	written.append(path)
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
			# The D-41 interlude card over this real cruise (strip and card read the same
			# state); the guided voyage shows it on its long legs.
			var card := CardInterlude.new()
			card.begin(CruiseInterlude.facts_from(demo.journey_sim.world, demo.stop_name()))
			card.observe(demo.journey_sim.world, demo.stop_name())
			demo.interlude_card.show_interlude(card)
			demo.interlude_card.visible = true
			await shot("tour_interlude", sz)
			demo.interlude_card.visible = false
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
	# The lower deck: decisions need the lift.
	demo.set_preset("reset")
	demo.lift.board()
	demo.lift.advance(0.81); demo.lift.advance(11.01); demo.lift.advance(0.81)
	demo.look_direction("side")
	await shot("lower_deck", sz)
	demo.queue_free()
	await process_frame


## Frames the later milestones add (consoles, helm, chart, Voyage, Archive).
func more_frames(_sz: Vector2i) -> void:
	pass


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
