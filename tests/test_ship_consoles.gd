extends SceneTree
## R1-SHIP-UI (D-56, D-57) U3-U5: the bridge consoles decide. make ship-console-test.
##   AC8   every station loads from ship.glb node names; each active one has a use point within
##         2.5 m and a non-empty WalkArea.path from the bridge spawn (lengths printed, 40 m
##         ceiling); the prompt shows in reach and facing only
##   AC6   NT3/NT4: hold and press-twice confirms; release restarts with no penalty; the intent
##         payload does not depend on the delay
##   AC9   each station's panel; helm commit = today's map commit; voyage = start_solar_departure();
##         Sgr A* approach / leave = bh_next_stop() / leave_black_hole(); the Archive opens the codex
##   AC10  the chart (M) has no slider, commit, cancel, Return to Sol, in-system list or Sgr A*
##         entry, does not pause the tour, sends no plan, and hands its selection to the helm
##   AC14a the Tab "Walk to" list is keyboard reachable and walks to each station; on the lower
##         deck the prompt says decisions need the bridge (lift)
## Time is the fake clock (_process(dt) / ShipConsoles.advance); no wall-clock reads (AC13).

const BlackHoleVisit := preload("res://demos/black_hole_visit.gd")
var failures := 0
var passes := 0


func check(label: String, ok: bool) -> void:
	if ok:
		passes += 1
	else:
		failures += 1
	print("%s %s" % ["ok" if ok else "FAIL", label])


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await test_stations()
	await test_confirm_and_helm()
	await test_chart()
	await test_voyage_archive_sgr()
	await test_walk_to()
	await test_onboarding()
	print("ship-consoles: %d passed, %d failures" % [passes, failures])
	quit(1 if failures else 0)


func new_demo(opts := {}) -> Node:
	var demo: Node = load("res://demos/ship_geometry_demo.tscn").instantiate()
	var o := {"stars": false, "background": false, "live_start": true, "sky_state": "rest"}
	o.merge(opts, true)
	demo.setup_options = o
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


func player_intents(sim: SimBridge) -> Array:
	return sim.sent_log.filter(func(e: Dictionary) -> bool: return e.source == "player").map(func(e: Dictionary) -> Array: return e.intents)


func test_stations() -> void:
	var demo: Node = await new_demo()
	var c: ShipConsoles = demo.consoles
	check("AC8 consoles built", c != null and c.stations.size() == ShipConsoles.STATIONS.size())
	for id: String in ShipConsoles.STATIONS:
		var st: Dictionary = c.stations[id]
		check("AC8 %s: every mesh found in ship.glb (%d)" % [id, st.meshes.size()], st.meshes.size() == ShipConsoles.STATIONS[id].meshes.size())
		var near := true
		for m: Dictionary in st.meshes:
			near = near and demo.walk_bridge.is_walkable(m.use) and Vector2(m.use.x, m.use.z).distance_to(Vector2(m.origin.x, m.origin.z)) <= ShipConsoles.REACH_M
		check("AC8 %s: use points walkable within 2.5 m" % id, near)
		if st.active:
			var length := c.path_length(id)
			print("path %s %.1f m" % [id, length])
			check("AC8 %s: a walkable path from the bridge spawn, %.1f m <= 40 m" % [id, length], length > 0.0 and length <= ShipConsoles.PATH_CEILING_M)
	check("AC8 reserved consoles are dark and offline", ["reserved_1", "reserved_2", "reserved_3"].all(func(id: String) -> bool: return not c.stations[id].active and c.screen_text(id) == "offline"))
	# The prompt: in reach and facing, not otherwise.
	c.go_to("navigation")
	demo._process(0.016)
	check("AC8 in reach and facing: the prompt names the station (%s)" % demo.ship_hud.prompt.text, demo.ship_hud.prompt.text == "Navigation station · E use")
	demo.camera.yaw += PI
	demo._process(0.016)
	check("AC8 in reach, facing away: no station prompt (%s)" % demo.ship_hud.prompt.text, not demo.ship_hud.prompt.text.contains("Navigation station"))
	demo.avatar_pos = Vector3(8, 82, 4.0)
	demo._process(0.016)
	check("AC8 out of reach: no station prompt", not demo.ship_hud.prompt.text.contains("· E use"))
	c.go_to("voyage")
	demo._process(0.016)
	check("AC8 the Voyage console's prompt", demo.ship_hud.prompt.text == "Voyage console · E use")
	# E priority: the nearest interactable in reach and facing; the lift is one of them.
	demo.set_preset("reset")
	demo._process(0.016)
	check("E priority: at the landing E names the lift", demo.ship_hud.prompt.text.begins_with("Lift · E") and c.e_target().kind == "lift")
	c.go_to("archive")
	check("E at the Archive terminal opens it (camera dolly, panel)", c.press_e() and c.focused == "archive" and c.panel.visible and demo.camera_mode == "console")
	var start: Transform3D = c._dolly.from
	step(demo, 0.3)
	check("the dolly is under way at 0.3 s", c.dolly_active())
	step(demo, 0.35)
	check("the dolly lands on the focus pose in 0.6 s", not c.dolly_active() and demo.camera.global_transform.origin.distance_to(c.focus_pose(c.focus_mesh).origin) < 1e-3 and start.origin.distance_to(demo.camera.global_transform.origin) > 0.1)
	check("walking is suspended in console focus", demo.camera_mode == "console")
	check("Esc steps back: the dolly returns to the captain's eye", c.escape() and c.focused == "" and not c.panel.visible)
	step(demo, 0.7)
	check("back at the captain's eye", demo.camera_mode == "player" and demo.camera.position.distance_to(demo.avatar_pos + Vector3.UP * 1.7) < 1e-3)
	check("use() refuses a decision away from its console", not c.use("voyage", "begin") and demo.solar_tour == null and demo.ship_hud.has_card("refusal"))
	check("use() refuses to open a console out of reach", not c.use("navigation", "open") and c.focused == "")
	c.go_to("reserved_2")
	check("a reserved console refuses: offline", not c.use("reserved_2", "open") and c.focused == "")
	demo.queue_free()
	await process_frame


func test_confirm_and_helm() -> void:
	# Today's map commit (the reference): the map's own dialog and hold, on a fresh session.
	var ref: Node = await new_demo()
	ref.journey_sim.record_sent = true
	ref.open_navigation()
	ref.journey_map.open_commit_dialog()
	ref.journey_map.hold_commit(GalaxyMap.HOLD_S)
	ref.journey_tick()
	var want: Array = player_intents(ref.journey_sim)
	check("reference: today's map commit sends a commit (%s)" % [want], want.size() >= 1 and want.back().any(func(i: Dictionary) -> bool: return i.k == "commit"))
	ref.queue_free()
	await process_frame
	# The helm, hold mode: release restarts with no penalty, 1.5 s commits.
	var demo: Node = await new_demo()
	var c: ShipConsoles = demo.consoles
	demo.journey_sim.record_sent = true
	c.go_to("navigation")
	check("helm opens at the navigation station", c.use("navigation", "open") and demo.journey_map.mode == "helm" and demo.navigation_window.visible)
	check("helm has commit, cancel, slider, Return to Sol and the Sgr A* entry", demo.journey_map.commit_button.visible and demo.journey_map.cancel_button.visible and demo.journey_map.slider.visible and demo.journey_map.home_button.visible and demo.navigation_window.find_child("SgrAEntry", true, false).visible)
	check("the commit dialog opens on the plan", demo.journey_map.open_commit_dialog())
	demo.journey_map._holding = true
	demo.journey_map.hold_commit(1.0)
	demo.journey_map.release_commit()
	step(demo, 5.0, 0.5)
	check("NT3 hold released at 1.0 s: no commit, the hold restarts at 0", demo.journey_map.hold_s == 0.0 and demo.journey_map.dialog.visible and demo.journey_map.journey_state() == "planned" and player_intents(demo.journey_sim).is_empty())
	demo.journey_map.hold_commit(GalaxyMap.HOLD_S)
	demo.journey_tick()
	var got: Array = player_intents(demo.journey_sim)
	check("AC9 helm commit sends the same intent as today's map commit (%s)" % [got], got == want)
	check("committed: the ship is under way", demo.live_journey)
	demo.queue_free()
	await process_frame
	# NT4: the same plan commits the same way after 1 s or after 60 s at the helm.
	var payloads := []
	for wait_s in [1.0, 60.0]:
		var d: Node = await new_demo()
		d.journey_sim.record_sent = true
		d.consoles.go_to("navigation")
		d.consoles.use("navigation", "open")
		d.consoles.use("navigation", "select", "CNS5:3627")
		d.journey_tick()
		step(d, wait_s, 1.0)
		check("NT4 commit after %.0f s via use()" % wait_s, d.consoles.use("navigation", "commit") and d.journey_tick() and d.live_journey)
		payloads.append(player_intents(d.journey_sim))
		d.queue_free()
		await process_frame
	check("NT4 the plan and commit payloads do not depend on the delay", payloads[0] == payloads[1] and payloads[0].size() >= 2)
	# Press-twice (the accessibility setting): any interval, even zero frames; Esc backs out.
	var t: Node = await new_demo({"confirm_mode": "twice"})
	t.journey_sim.record_sent = true
	t.consoles.go_to("navigation")
	t.consoles.use("navigation", "open")
	check("press-twice mode reaches the map", t.journey_map.confirm_twice)
	t.journey_map.open_commit_dialog()
	t.journey_map.confirm_press()
	check("NT3 first press arms: relabelled Confirm, nothing sent", t.journey_map.armed and t.journey_map.hold_button.text.begins_with("Confirm") and player_intents(t.journey_sim).is_empty())
	t.consoles.escape()
	check("Esc backs out of an armed confirm only", not t.journey_map.armed and t.consoles.focused == "navigation")
	t.journey_map.open_commit_dialog()
	t.journey_map.confirm_press()
	t.journey_map.confirm_press()
	t.journey_tick()
	check("NT3 two presses zero frames apart commit", t.live_journey and player_intents(t.journey_sim).back()[0].k == "commit")
	t.queue_free()
	await process_frame


func test_chart() -> void:
	var demo: Node = await new_demo()
	demo.journey_sim.record_sent = true
	var e := InputEventKey.new()
	e.physical_keycode = KEY_M
	e.pressed = true
	demo._unhandled_input(e)
	var map: GalaxyMap = demo.journey_map
	check("AC10 M opens the chart", map != null and map.mode == "chart" and demo.navigation_window.visible)
	check("AC10 chart: no slider, commit, cancel, Return to Sol, in-system list", not map.slider.visible and not map.commit_button.visible and not map.cancel_button.visible and not map.home_button.visible and not map.system_box.visible)
	check("AC10 chart: no Sgr A* entry", not demo.navigation_window.find_child("SgrAEntry", true, false).visible)
	check("AC10 chart: a banner sends plotting to the navigation station", map.chart_banner.visible and map.chart_banner.text.contains("navigation station"))
	var i := map.index_of("Gaia DR3 4472832130942575872")
	check("AC10 chart: a star selects", map.select(i) and map.selected_index == i)
	demo.journey_tick()
	check("AC10 chart: selecting sends no plan", player_intents(demo.journey_sim).is_empty() and not map.open_commit_dialog())
	demo.close_navigation()
	demo.consoles.go_to("navigation")
	demo.consoles.use("navigation", "open")
	demo.journey_tick()
	check("AC10 the chart's selection carries to the helm and plans there", map.mode == "helm" and map.selected_index == i and str(GalaxyMap.field_value(demo.journey_sim.world, "journey.plan.target.id")) == "Gaia DR3 4472832130942575872")
	demo.consoles.leave()
	step(demo, 0.7)
	check("stepping back closes the helm; the map rests in chart mode (plans nothing)", not demo.navigation_window.visible and map.mode == "chart")
	# The guided voyage: M browses without pausing it.
	demo.consoles.go_to("voyage")
	demo.consoles.use("voyage", "open")
	demo.consoles.use("voyage", "begin")
	demo.consoles.leave()
	step(demo, 0.7)
	demo._unhandled_input(e)
	check("AC10 M during the guided voyage: the chart opens and the voyage is not paused", demo.navigation_window.visible and demo.journey_map.mode == "chart" and not demo.solar_tour.paused)
	demo.close_navigation()
	demo.queue_free()
	await process_frame


func test_voyage_archive_sgr() -> void:
	var demo: Node = await new_demo()
	var c: ShipConsoles = demo.consoles
	c.go_to("voyage")
	check("AC9 the Voyage console's panel shows the itinerary and Begin", c.use("voyage", "open") and c.panel_body.find_child("Confirm_begin", true, false) != null and _panel_text(c).contains("Aldebaran"))
	var b: Button = c.panel_body.find_child("Confirm_begin", true, false)
	b.button_down.emit()
	step(demo, 1.0)
	b.button_up.emit()
	step(demo, 3.0)
	check("NT3 Begin held 1.0 s then released: nothing starts", demo.solar_tour == null)
	b = c.panel_body.find_child("Confirm_begin", true, false)
	b.button_down.emit()
	step(demo, 1.6)
	check("AC9 Begin held 1.5 s = start_solar_departure(): the guided voyage runs", demo.solar_tour != null and demo.journey_map.guided_read_only)
	c.leave()
	step(demo, 0.7)
	# The Archive terminal.
	c.go_to("archive")
	check("AC9 the Archive terminal opens the codex", c.use("archive", "open") and demo.codex != null and demo.codex.panel.visible)
	c.leave()
	step(demo, 0.7)
	check("stepping back closes the codex", not demo.codex.panel.visible)
	demo.queue_free()
	await process_frame
	# Sgr A*: the helm's entry, the stop ladder, approach and leave.
	var d: Node = await new_demo()
	c = d.consoles
	c.go_to("navigation")
	c.use("navigation", "open")
	check("AC9 helm: the Sgr A* entry starts the visit", c.use("navigation", "sgr_a") and d.black_hole != null)
	check("the helm shows the stop ladder with Approach and Leave", c.panel_body.find_child("Confirm_approach", true, false) != null and c.panel_body.find_child("Confirm_leave", true, false) != null and (d.navigation_window == null or not d.navigation_window.visible))
	var sim: SimBridge = d.black_hole.sim
	sim.record_sent = true
	check("AC9 Approach = bh_next_stop(): the first scripted stop's intents", c.use("navigation", "approach") and d.black_hole.stops_taken == 1 and player_intents(sim) == [BlackHoleVisit.STOPS[0].intents])
	d.bh_finish_approach()
	c.set_confirm_mode("twice")
	var leave: Button = c.panel_body.find_child("Confirm_leave", true, false)
	leave.button_down.emit()
	check("press-twice: Leave relabels to Confirm", d.black_hole != null and leave.text.begins_with("Confirm"))
	step(d, 600.0, 5.0)
	check("NT2 an armed confirm survives 600 s of fake time unchanged", d.black_hole != null and c.confirm_armed() and c.focused == "navigation")
	leave.button_down.emit()
	check("AC9 Leave = leave_black_hole(): back at Sol, GR off", d.black_hole == null and not d.sky.gr_lens.active)
	d.queue_free()
	await process_frame


func _panel_text(c: ShipConsoles) -> String:
	return "\n".join(c.panel_body.find_children("*", "Label", true, false).map(func(l: Label) -> String: return l.text))


func test_walk_to() -> void:
	var demo: Node = await new_demo()
	var c: ShipConsoles = demo.consoles
	var hud: ShipHud = demo.ship_hud
	demo.toggle_controls()
	check("AC14a Tab shows the Walk to list", hud.tab_panel.visible and hud.walk_box.visible and hud.walk_buttons.size() == 3)
	var first: Button = hud.walk_buttons["navigation"]
	first.grab_focus()
	var down := InputEventAction.new()
	down.action = "ui_down"
	down.pressed = true
	root.push_input(down)
	await process_frame
	check("AC14a arrows move the focus along the list", hud.walk_buttons["voyage"].has_focus())
	var accept := InputEventAction.new()
	accept.action = "ui_accept"
	accept.pressed = true
	root.push_input(accept)
	accept = accept.duplicate()
	accept.pressed = false
	root.push_input(accept)
	await process_frame
	check("AC14a Enter walks to the Voyage console", c.walk_target == "voyage" and not c.walking.is_empty())
	var walked := 0.0
	var from: Vector3 = demo.avatar_pos
	for i in 400:
		if c.walk_target.is_empty():
			break
		demo._process(0.05)
		walked += 0.05
	check("AC14a the captain arrives at its use point at 3.5 m/s (%.1f s)" % walked, demo.avatar_pos.distance_to(c.stations.voyage.use) < 0.05 and walked >= from.distance_to(c.stations.voyage.use) / ShipConsoles.WALK_SPEED_MPS - 0.1)
	check("AC14a and faces it: the prompt says E use", hud.prompt.text == "Voyage console · E use")
	for id in ["navigation", "archive"]:
		c.walk_to(id)
		for i in 400:
			if c.walk_target.is_empty():
				break
			demo._process(0.05)
		check("AC14a Walk to %s arrives in reach" % id, c.e_target().get("id", "") == id)
	c.walk_to("voyage")
	demo._process(0.05)
	c.cancel_walk() # WASD takes over (the demo cancels on any WASD input)
	check("WASD cancels an auto-walk", c.walk_target.is_empty() and c.walking.is_empty())
	# The lower deck: decisions need the lift.
	demo.set_preset("reset")
	demo.lift.board()
	demo.lift.advance(0.81); demo.lift.advance(11.01); demo.lift.advance(0.81)
	demo._process(0.016)
	check("AC14a lower deck: the prompt names the lift", demo.active_level == 1 and hud.prompt.text.contains("Lift · E to the bridge"))
	demo.avatar_pos += Vector3(4, 0, 0)
	demo._process(0.016)
	check("AC14a lower deck, away from the lift: decisions need the bridge", hud.prompt.text.contains("take the lift"))
	check("Walk to from the lower deck heads for the lift", c.walk_to("navigation") and c.walk_target == "lift")
	demo.queue_free()
	await process_frame


## §C5 onboarding: on a menu launch the Voyage console and the navigation station glow and
## one hint shows, until the first console use (a display cue: no timer ends it).
func test_onboarding() -> void:
	DirAccess.make_dir_recursive_absolute("user://test_ship_consoles")
	var demo: Node = await new_demo({"from_menu": true, "settings_dir": "user://test_ship_consoles"})
	var c: ShipConsoles = demo.consoles
	check("menu launch: the consoles glow and the hint shows", c.glowing() and demo.ship_hud.hint.visible and demo.ship_hud.hint_label.text.contains("Voyage console"))
	step(demo, 120.0, 1.0)
	check("the glow and hint do not end on a timer", c.glowing() and demo.ship_hud.hint.visible)
	c.go_to("voyage")
	c.use("voyage", "open")
	check("the first console use ends the glow and the hint", not c.glowing() and not demo.ship_hud.hint.visible)
	demo.queue_free()
	await process_frame
	var cli: Node = await new_demo()
	check("command-line launch: no onboarding glow or hint", not cli.consoles.glowing() and not cli.ship_hud.hint.visible)
	cli.queue_free()
	await process_frame
