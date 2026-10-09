extends SceneTree
## R1-SHIP-UI (D-56: "no twitch gaming ever") §E. make no-twitch-test.
##   NT1 (AC4) with no console focused, no key, mouse button, pan gesture or HUD element sends
##       a player-originated decision intent (plan, commit, cancel, approach, leave) or starts or
##       drops a session, aboard at rest, in transit, on the guided voyage and at Sgr A*. Tour
##       intents (the itinerary's own legs) are allowed and must be the itinerary's next leg.
##   NT2 (AC5) an open commit dialog, an open console panel and an unanswered confirm survive
##       600 s of fake time unchanged (the sim keeps its host tick).
## Deterministic (AC13): fixed seed, fake clock, no wall-clock reads; the log has no timings,
## so two runs print identical logs.

var failures := 0
var passes := 0
const KEYS := [KEY_A, KEY_B, KEY_C, KEY_D, KEY_E, KEY_F, KEY_G, KEY_H, KEY_I, KEY_J, KEY_K, KEY_L, KEY_M,
	KEY_N, KEY_O, KEY_P, KEY_Q, KEY_R, KEY_S, KEY_T, KEY_U, KEY_V, KEY_W, KEY_X, KEY_Y, KEY_Z,
	KEY_0, KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9,
	KEY_F1, KEY_F2, KEY_F3, KEY_F4, KEY_F5, KEY_F6, KEY_F7, KEY_F8, KEY_F9, KEY_F10, KEY_F11, KEY_F12,
	KEY_ENTER, KEY_SPACE, KEY_TAB, KEY_ESCAPE, KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]
const DECISIONS := ["plan", "commit", "cancel", "body_plan"]


func check(label: String, ok: bool) -> void:
	if ok:
		passes += 1
	else:
		failures += 1
	print("%s %s" % ["ok" if ok else "FAIL", label])


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await sweep_state("at rest")
	await sweep_state("in transit")
	await sweep_state("guided voyage")
	await sweep_state("Sgr A*")
	await test_no_deadlines()
	print("no-twitch: %d passed, %d failures" % [passes, failures])
	quit(1 if failures else 0)


func new_demo() -> Node:
	var demo: Node = load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options = {"stars": false, "background": false, "live_start": true, "sky_state": "rest", "from_menu": true, "settings_dir": "user://test_no_twitch"}
	DirAccess.make_dir_recursive_absolute("user://test_no_twitch")
	root.add_child(demo)
	await process_frame
	demo.auto = false
	demo.journey_auto_tick = false
	demo.escape_exits = false
	return demo


func step(demo: Node, seconds: float, dt := 0.05) -> void:
	var t := 0.0
	while t < seconds - 1e-9:
		demo._process(dt)
		t += dt


func session(demo: Node) -> SimBridge:
	return demo.black_hole.sim if demo.black_hole != null else demo.journey_sim


## Put the ship in a state the honest way (through the consoles).
func enter(demo: Node, state: String) -> void:
	var c: ShipConsoles = demo.consoles
	match state:
		"in transit":
			c.go_to("navigation")
			c.use("navigation", "open")
			c.use("navigation", "commit")
			demo.journey_tick()
		"guided voyage":
			c.go_to("voyage")
			c.use("voyage", "open")
			c.use("voyage", "begin")
		"Sgr A*":
			c.go_to("navigation")
			c.use("navigation", "open")
			c.use("navigation", "sgr_a")
	c.leave()
	step(demo, 0.7)
	demo.set_preset("reset")


func events() -> Array:
	var out: Array = []
	for k in KEYS:
		for pressed in [true, false]:
			var e := InputEventKey.new()
			e.physical_keycode = k
			e.keycode = k
			e.pressed = pressed
			out.append(e)
	for pos in [Vector2(480, 270), Vector2(820, 200), Vector2(60, 30), Vector2(480, 500)]:
		for button in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			for pressed in [true, false]:
				var m := InputEventMouseButton.new()
				m.button_index = button
				m.pressed = pressed
				m.position = pos
				m.global_position = pos
				out.append(m)
	var pan := InputEventPanGesture.new()
	pan.delta = Vector2(0, 1)
	out.append(pan)
	return out


func sweep_state(state: String) -> void:
	var demo: Node = await new_demo()
	await enter(demo, state)
	var sim := session(demo)
	sim.record_sent = true
	sim.sent_log.clear()
	var tour = demo.solar_tour
	var bh = demo.black_hole
	var journey_state := str(GalaxyMap.field_value(sim.world, "journey.state"))
	var plan: Variant = GalaxyMap.field_value(sim.world, "journey.plan")
	var plan_before := [GalaxyMap.field_value(sim.world, "journey.plan_id"), GalaxyMap.field_value(sim.world, "journey.plan.target.id")]
	var bad: Array = []
	var tour_bad: Array = []
	for e in events():
		root.push_input(e, false)
		await process_frame
		demo._process(0.05)
		if demo.consoles.focused != "":
			demo.consoles.leave() # E or a click may open a console: that is not a decision
		if demo.navigation_window != null and demo.navigation_window.visible:
			demo.close_navigation()
		# Flush: anything a key queued in the map is sent on the next tick.
		if demo.black_hole != null:
			demo.bh_tick()
		elif demo.journey_map != null:
			demo.journey_tick()
		for entry: Dictionary in sim.sent_log:
			if entry.source == "player":
				bad.append([OS.get_keycode_string(e.keycode) if e is InputEventKey else e.get_class(), entry.intents])
			elif entry.source == "tour":
				for i: Dictionary in entry.intents:
					if i.get("k", "") == "plan" and not _is_next_leg(tour, i):
						tour_bad.append(i)
		sim.sent_log.clear()
	check("NT1 %s: no player decision intent from any key, click or gesture %s" % [state, bad.slice(0, 3)], bad.is_empty())
	check("NT1 %s: every tour intent is the itinerary's own next leg" % state, tour_bad.is_empty())
	check("NT1 %s: no session started or dropped" % state, demo.solar_tour == tour and demo.black_hole == bh and session(demo) == sim)
	if tour == null and bh == null:
		var now := [GalaxyMap.field_value(sim.world, "journey.plan_id"), GalaxyMap.field_value(sim.world, "journey.plan.target.id")]
		check("NT1 %s: journey state and plan unchanged (%s)" % [state, journey_state], str(GalaxyMap.field_value(sim.world, "journey.state")) in [journey_state, "arrived"] and (journey_state != "planned" or now == plan_before))
	demo.queue_free()
	await process_frame


## A tour plan intent's target is the next leg of the itinerary (by catalogue id or body).
func _is_next_leg(tour, intent: Dictionary) -> bool:
	if tour == null:
		return false
	var next: Dictionary = tour.itinerary[tour.pending_index] if tour.pending_index >= 0 else tour.itinerary[mini(tour.leg_index + 1, tour.itinerary.size() - 1)]
	var t: Dictionary = intent.get("target", {}) if intent.get("target") is Dictionary else {}
	return str(t.get("id", intent.get("body", ""))) == str(next.id) or str(intent.get("body", "")) == str(next.id)


func test_no_deadlines() -> void:
	var demo: Node = await new_demo()
	var c: ShipConsoles = demo.consoles
	demo.journey_sim.record_sent = true
	c.go_to("navigation")
	c.use("navigation", "open")
	demo.journey_tick()
	demo.journey_sim.sent_log.clear()
	demo.journey_auto_tick = true # the sim keeps its normal host tick (D-12)
	check("NT2 setup: the commit dialog is open at the helm", demo.journey_map.open_commit_dialog())
	var tick0: int = demo.journey_sim.world.tick
	step(demo, 600.0, 1.0)
	check("NT2 600 s later: the dialog, the helm and the plan are unchanged", demo.journey_map.dialog.visible and c.focused == "navigation" and demo.journey_map.journey_state() == "planned")
	check("NT2 the sim kept its host tick (%d ticks)" % (demo.journey_sim.world.tick - tick0), demo.journey_sim.world.tick > tick0)
	check("NT2 nothing was decided on the timer", demo.journey_sim.sent_log.all(func(e: Dictionary) -> bool: return e.source == "tick"))
	demo.journey_map.close_commit_dialog()
	c.leave()
	step(demo, 0.7)
	demo.journey_auto_tick = false
	c.go_to("voyage")
	c.use("voyage", "open")
	c.set_confirm_mode("twice")
	var b: Button = c.panel_body.find_child("Confirm_begin", true, false)
	b.button_down.emit()
	step(demo, 600.0, 5.0)
	check("NT2 an armed press-twice confirm and its panel survive 600 s; nothing starts", c.confirm_armed() and c.focused == "voyage" and demo.solar_tour == null)
	c.set_confirm_mode("hold")
	b = c.panel_body.find_child("Confirm_begin", true, false)
	step(demo, 600.0, 5.0)
	check("NT2 an open panel with an unpressed hold survives 600 s; nothing starts", c.focused == "voyage" and demo.solar_tour == null)
	demo.queue_free()
	await process_frame
