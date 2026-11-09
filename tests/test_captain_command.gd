extends SceneTree
## D-149: one seated command origin, five existing systems, safe lifecycle/input.
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
	check("command keeps the seated captain visible", demo.avatar.visible)
	check("overview cannot schedule walking while seated", not demo.consoles.walk_to("crew") and not demo.consoles.walk_to_point(demo.bridge_spawn(), "spawn"))
	demo.walk_motion(Vector2.RIGHT, .1)
	check("movement input inside command does not stand", demo.captain_anim.chair == "seated" and not demo._chair_stand)
	check("overview is the initial view", command.selected == "overview")
	check("all five existing systems have tabs", command.system_buttons.size() == 5)
	var anchor: Vector3 = demo.avatar_pos
	var view: String = demo.director.view_id
	# Voyage/Archive need no fresh sim. Crew and Comms explain unavailable sessions.
	for id in ["voyage", "crew", "comms", "archive"]:
		check("chair opens " + id, command.select_system(id) and demo.consoles.focused == id)
		check(id + " keeps captain at the chair and camera away from desk", demo.avatar_pos.is_equal_approx(anchor) and demo.director.view_id == view)
	command.select_system("voyage")
	demo.consoles.set_confirm_mode("twice")
	demo.consoles.confirm_press("voyage", "begin")
	check("existing confirmation still arms first", demo.consoles.confirm_armed() and demo.solar_tour == null)
	command.select_system("crew")
	check("tab change cancels the armed decision", not demo.consoles.confirm_armed() and demo.solar_tour == null)
	command.close()
	check("closing leaves the captain seated, with no active system", demo.seated() and not command.visible and demo.consoles.focused == "")
	check("E reopens the command screen", demo.consoles.press_e() and command.visible)
	var next := InputEventKey.new()
	next.physical_keycode = KEY_TAB; next.ctrl_pressed = true; next.pressed = true
	check("Ctrl Tab changes system", command.key(next) and command.selected == "navigation")
	if demo.journey_map != null:
		check("opening the chair Navigation tab does not synthesize a plan", demo.journey_map._pending.is_empty() and demo.journey_map._queue.is_empty())
	# If navigation cannot start, the shell still leaves its tabs and close action usable.
	command.select_system("overview")
	var shoulder := InputEventJoypadButton.new()
	shoulder.button_index = JOY_BUTTON_RIGHT_SHOULDER; shoulder.pressed = true
	check("pad shoulder changes system", command.key(shoulder) and command.selected == "navigation")
	command.select_system("overview")
	for sz in [Vector2(960, 540), Vector2(1280, 720), Vector2(2560, 1440)]:
		command.layout_for(sz, 60.)
		print("layout ", sz, " content ", command.content_rect(), " frame ", command.frame.size)
		check("command content fits %s" % sz, Rect2(Vector2.ZERO, sz).encloses(command.content_rect()) and command.content_rect().size.x > 240.)
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
