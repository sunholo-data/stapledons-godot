extends SceneTree
## D-150: one seated command origin, five existing systems, safe lifecycle/input.
var passes := 0
var failures := 0

func check(label: String, ok: bool) -> void:
	if ok: passes += 1
	else: failures += 1
	print("%s %s" % ["ok" if ok else "FAIL", label])

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var demo: Node = load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options = {"stars": false, "background": false}
	root.add_child(demo)
	await process_frame
	demo.auto = false
	demo.journey_auto_tick = false
	demo.escape_exits = false
	var command: Variant = demo.consoles.get("command")
	check("the real ship installs a chair command host", command != null)
	if command != null:
		await exercise(demo, command)
	demo.queue_free()
	await process_frame
	print("captain-command: %d passed, %d failures" % [passes, failures])
	quit(1 if failures else 0)

func exercise(demo: Node, command: Variant) -> void:
	check("standing cannot claim chair authority", not command.open())
	var seat: Vector3 = demo.chair_seat()
	demo.avatar_pos = demo.walk_bridge.closest_walkable(seat + Vector3(0, 0, .8), 3.)
	check("E begins sitting at the chair", demo.consoles.press_e() and demo.seated())
	for k in 50: demo._process(1. / 60.)
	check("sitting opens the combined command screen", command.visible and command.authorized())
	for k in 180: demo._process(1. / 60.)
	check("captain sees through seated eyes without own billboard clipping", not demo.avatar.visible and demo.camera.global_position.distance_to(command.cockpit.overview_pose().origin) < .02)
	check("five physical displays surround the seat", command.cockpit.display_nodes.size() == 5)
	check("actual controls render in the display viewport", demo.consoles.panel.get_viewport() == command.screen_host.viewport)
	check("overview cannot schedule walking while seated", not demo.consoles.walk_to("crew") and not demo.consoles.walk_to_point(demo.bridge_spawn(), "spawn"))
	demo.walk_motion(Vector2.RIGHT, .1)
	check("movement input inside command does not stand", demo.captain_anim.chair == "seated" and not demo._chair_stand)
	check("overview is the initial view", command.selected == "overview")
	check("all five existing systems have tabs", command.system_buttons.size() == 5)
	var anchor: Vector3 = demo.avatar_pos
	var overview_pose: Transform3D = command.cockpit.overview_pose()
	# Click a physical console, then a real Control drawn in its viewport. This checks
	# the whole projection/UV/input path without rendering or issuing a ship decision.
	var display: MeshInstance3D = command.cockpit.display_nodes.voyage
	var pick := InputEventMouseButton.new()
	pick.button_index = MOUSE_BUTTON_LEFT; pick.pressed = true
	pick.position = demo.get_viewport().get_stretch_transform().affine_inverse() * demo.camera.unproject_position(display.global_position)
	command.key(pick)
	check("clicking a physical screen selects its system", command.selected == "voyage")
	for k in 180: demo._process(1. / 60.)
	var clicks := [0]
	var probe := Button.new()
	probe.text = "Input probe"; probe.position = Vector2(400, 290); probe.size = Vector2(200, 60)
	probe.pressed.connect(func(): clicks[0] += 1)
	command.screen_host.layer.add_child(probe)
	for k in 3: await process_frame
	var uv := Vector2(500., 320.) / Vector2(command.screen_host.viewport.size)
	var world: Vector3 = display.global_transform * Vector3((uv.x - .5) * ChairCockpit.SCREEN_SIZE.x, (.5 - uv.y) * ChairCockpit.SCREEN_SIZE.y, 0.)
	pick.position = demo.get_viewport().get_stretch_transform().affine_inverse() * demo.camera.unproject_position(world)
	command.key(pick)
	pick.pressed = false; command.key(pick)
	check("projected screen clicks reach the actual GUI once", clicks[0] == 1)
	probe.queue_free()
	# Voyage/Archive need no fresh sim. Crew and Comms explain unavailable sessions.
	for id in ["voyage", "crew", "comms", "archive"]:
		check("chair opens " + id, command.select_system(id) and demo.consoles.focused == id)
		check(id + " keeps captain seated while view moves to its screen", demo.avatar_pos.is_equal_approx(anchor) and demo.director.view_id == "console" and demo.director.console_pose.is_equal_approx(command.cockpit.focus_pose(id)) and not demo.director.console_pose.is_equal_approx(overview_pose))
	# Real key events typed into the Archive question on the chair's display (its own SubViewport):
	# hold-I (star identification, read in _input) must not swallow the letter i while typing.
	check("chair opens the Archive question field", command.select_system("archive") and demo.consoles.ask_field != null)
	demo.consoles.ask_field.text = ""
	demo.consoles.ask_field.grab_focus()
	await process_frame
	for ch in "it is":
		for down in [true, false]:
			var e := InputEventKey.new()
			e.keycode = KEY_SPACE if ch == " " else OS.find_keycode_from_string(ch.to_upper())
			e.physical_keycode = e.keycode
			e.pressed = down
			if down: e.unicode = ch.unicode_at(0)
			root.push_input(e)
			await process_frame
	check("typing at the chair reaches the Archive field, letter i included", demo.consoles.ask_field.text == "it is")
	check("typing i at the chair does not hold star identification", not demo.star_identification.held)
	demo.consoles.ask_field.release_focus()
	command.select_system("voyage")
	demo.consoles.set_confirm_mode("twice")
	demo.consoles.confirm_press("voyage", "begin")
	check("existing confirmation still arms first", demo.consoles.confirm_armed() and demo.solar_tour == null)
	command._dragging = true
	command.select_system("crew")
	check("tab change cancels the armed decision", not demo.consoles.confirm_armed() and demo.solar_tour == null)
	check("switching screens clears the old pointer drag", not command._dragging)
	command.select_system("voyage")
	demo.consoles.confirm_press("voyage", "begin")
	var back := InputEventKey.new()
	back.physical_keycode = KEY_ESCAPE; back.pressed = true
	command.key(back)
	check("first Esc disarms the decision and stays at Voyage", not demo.consoles.confirm_armed() and command.selected == "voyage" and command.visible)
	command.key(back)
	check("second Esc looks up while remaining seated", command.visible and command.selected == "overview" and command.authorized())
	command.key(back)
	check("third Esc closes cockpit while remaining seated", not command.visible and demo.seated())
	command.open()
	command._dragging = true
	command.close()
	check("closing clears the pointer drag", not command._dragging)
	check("closing leaves the captain seated, with no active system", demo.seated() and not command.visible and demo.consoles.focused == "")
	check("closing returns panel to ordinary station viewport", demo.consoles.panel.get_parent() == demo.consoles.panel_layer and not command.cockpit.visible and demo.director.view_id != "console")
	check("E reopens the command screen", demo.consoles.press_e() and command.visible)
	var next := InputEventKey.new()
	next.physical_keycode = KEY_TAB; next.ctrl_pressed = true; next.pressed = true
	check("Ctrl Tab changes system", command.key(next) and command.selected == "navigation")
	if demo.journey_map != null:
		check("opening the chair Navigation tab does not synthesize a plan", demo.journey_map._pending.is_empty() and demo.journey_map._queue.is_empty())
		check("Navigation renders inside cockpit instead of a floating window", demo.journey_map.get_viewport() == command.screen_host.viewport and not demo.navigation_window.visible)
		for k in 180: demo._process(1. / 60.)
		for k in 3: await process_frame
		var map: Node = demo.journey_map
		var nav_display: MeshInstance3D = command.cockpit.display_nodes.navigation
		var telescope_at: Vector2 = map.telescope_button.get_global_rect().get_center()
		var telescope_uv := telescope_at / Vector2(command.screen_host.viewport.size)
		var telescope_world: Vector3 = nav_display.global_transform * Vector3((telescope_uv.x - .5) * ChairCockpit.SCREEN_SIZE.x, (.5 - telescope_uv.y) * ChairCockpit.SCREEN_SIZE.y, 0.)
		pick.position = demo.get_viewport().get_stretch_transform().affine_inverse() * demo.camera.unproject_position(telescope_world)
		pick.pressed = true; command.key(pick)
		pick.pressed = false; command.key(pick)
		check("physical chair Telescope button opens shared observation panel", map.observation_panel.visible)
		check("chair telescope keeps captain and decisions unchanged", demo.avatar_pos.is_equal_approx(anchor) and map._pending.is_empty() and map._queue.is_empty())
		command.key(back)
		check("Esc closes telescope before leaving Navigation", not map.observation_panel.visible and command.selected == "navigation")
		map.open_observation()
		var pad_back := InputEventJoypadButton.new(); pad_back.button_index = JOY_BUTTON_B; pad_back.pressed = true
		command.key(pad_back)
		check("pad B closes telescope before leaving Navigation", not map.observation_panel.visible and command.selected == "navigation")
		map.open_observation()
		var shared_panel: Control = map.observation_panel
		command.select_system("crew")
		check("screen switch releases archive cache and live viewport", not shared_panel.visible and not shared_panel.cache.active and shared_panel.live_view._vp.render_target_update_mode == SubViewport.UPDATE_DISABLED)
		command.select_system("navigation")
		map.open_observation()
		check("reopening reuses one observation panel and callback", map.observation_panel == shared_panel and shared_panel.open_map.get_connections().size() == 1)
	# If navigation cannot start, the shell still leaves its tabs and close action usable.
	command.select_system("overview")
	var shoulder := InputEventJoypadButton.new()
	shoulder.button_index = JOY_BUTTON_RIGHT_SHOULDER; shoulder.pressed = true
	check("pad shoulder changes system", command.key(shoulder) and command.selected == "navigation")
	command.select_system("overview")
	for sz in [Vector2(960, 540), Vector2(1280, 720), Vector2(2560, 1440)]:
		command.layout_for(sz, 60.)
		print("layout ", sz, " content ", command.content_rect(), " frame ", command.frame.size)
		check("display content has fixed readable resolution at %s" % sz, Rect2(Vector2.ZERO, Vector2(command.screen_host.viewport.size)).encloses(command.content_rect()) and command.content_rect().size.x > 900.)
	command.stand()
	check("standing closes and invalidates command authority immediately", not command.visible and not command.authorized())
	check("standing animation cannot reopen the command screen", not command.open())
	for k in 50: demo._process(1. / 60.)
	check("standing returns to a walkable point", not demo.seated() and demo.walk_bridge.is_walkable(demo.avatar_pos))
	check("distant physical station remains reach protected", not demo.consoles.use("crew", "open"))
	demo.avatar_pos = demo.bridge_spawn()
	check("Walk to offers a real chair path", demo.consoles.walk_to("chair") and not demo.consoles.walking.is_empty())
	for k in 500:
		demo._process(.05)
		if demo.consoles.command.visible: break
	check("Walk to chair arrives, sits and opens command", demo.consoles.command.visible and demo.consoles.command.authorized())
	command.close()
