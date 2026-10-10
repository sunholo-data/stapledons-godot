extends SceneTree
## R1-SHIP-UI U4a (AC15): the navigation station's map host in a real GPU window. The helm is
## GalaxyMap in an embedded, borderless Window laid over the console panel (the spike's choice:
## the map keeps its own 3D world and its own input; see the design's execution notes). This
## opens it at the console, clicks a star, opens the commit dialog by clicking Commit, holds
## the hold button for 1.5 s of real frames, and checks the commit reached the sim.
## make ship-ui-window-check -> renders/ship_ui/window_check_helm.png (open it).

const OUT := "res://renders/ship_ui"
var demo: Node


func _initialize() -> void:
	_run.call_deferred()


func fail(why: String) -> void:
	print("ship-ui-window-check: FAIL " + why)
	quit(1)


## A click at a point of the map's canvas (its content coordinates): the window scales its
## content by content_scale_factor, so the event goes in at window coordinates.
## A real mouse event at a point of the map's canvas, delivered the way the OS delivers one:
## to the ship's window in pixels, routed by Godot to the embedded helm window (which scales
## its content by content_scale_factor). Viewport.push_input into an embedded window does
## not reach its GUI controls, so this is the honest path.
func screen_of(w: Window, content: Vector2) -> Vector2:
	return root.get_stretch_transform() * (Vector2(w.position) + content * w.content_scale_factor)


func mouse(at: Vector2, pressed: Variant) -> void:
	var m := InputEventMouseMotion.new()
	m.position = at
	m.global_position = at
	Input.parse_input_event(m)
	if pressed != null:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		e.position = at
		e.global_position = at
		e.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		Input.parse_input_event(e)
	for k in 2: await process_frame


func click_at(w: Window, content: Vector2, down := true, up := true) -> void:
	var at := screen_of(w, content)
	await mouse(at, null)
	if down: await mouse(at, true)
	if up: await mouse(at, false)


func _run() -> void:
	root.size = Vector2i(1280, 720)
	demo = load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options = {"live_start": true, "sky_state": "rest", "auto_view": true}
	root.add_child(demo)
	await process_frame
	demo.journey_auto_tick = true
	var c: ShipConsoles = demo.consoles
	c.go_to("navigation")
	if not c.use("navigation", "open"):
		return fail("the navigation station did not open")
	for i in 30: await process_frame
	var w: Window = demo.navigation_window
	var map: GalaxyMap = demo.journey_map
	if w == null or not w.visible or map.mode != "helm":
		return fail("no helm window")
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	root.get_texture().get_image().save_png(OUT + "/window_check_open.png")
	print("host: embedded=%s borderless=%s rect=%s panel=%s" % [w.is_embedded(), w.borderless, Rect2i(w.position, w.size), c.panel_rect()])
	if not w.is_embedded():
		return fail("the helm window is not embedded in the ship's window")
	var i := map.index_of("Gaia DR3 4472832130942575872")
	map.frame_star(i)
	for k in 10: await process_frame
	await click_at(w, map.screen_position(i))
	for k in 6: await process_frame
	print("click on Barnard's Star: selected %d (want %d)" % [map.selected_index, i])
	if map.selected_index != i:
		return fail("a click on Barnard's Star did not select it")
	for k in 6: await process_frame # the plan tick
	await click_at(w, map.commit_button.get_global_rect().get_center())
	for k in 4: await process_frame
	if not map.dialog.visible:
		return fail("clicking Commit... did not open the dialog (state %s)" % map.journey_state())
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + "/window_check_helm.png")
	demo.journey_sim.record_sent = true
	var hb := map.hold_button.get_global_rect().get_center()
	await click_at(w, hb, true, false)
	var t0 := Time.get_ticks_msec()
	while map.dialog.visible and Time.get_ticks_msec() - t0 < 4000:
		await process_frame
	await click_at(w, hb, false, true)
	for k in 10: await process_frame
	print("held %.2f s; journey %s; %s; queue %s" % [(Time.get_ticks_msec() - t0) / 1000.0, map.journey_state(), map.status_text(), map._queue])
	for e in demo.journey_sim.sent_log.filter(func(x): return x.source == "player"):
		print("sent ", e)
	if not demo.live_journey:
		return fail("the hold did not commit")
	print("ship-ui-window-check: OK")
	quit(0)
