extends SceneTree
## Independent scenes with one seed and identical logical clock inputs: compare the actual
## dispatcher/crew UI intents and authoritative worlds, not a second implementation of them.
var passes := 0
var failures := 0

func check(label: String, ok: bool) -> void:
	if ok: passes += 1
	else: failures += 1
	print("%s %s" % ["ok" if ok else "FAIL", label])

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var chair := await journey(true)
	var station := await journey(false)
	check("both routes recorded a real journey", chair.has("world") and station.has("world"))
	if chair.has("world") and station.has("world"):
		check("chair and station send identical ordered intents and logical dtau", chair.inputs == station.inputs)
		check("chair and station input journals match byte for byte, including dtau", chair.journal == station.journal)
		check("chair and station produce identical authoritative worlds", chair.world == station.world)
		if chair.world != station.world:
			for key in chair.world:
				if chair.world[key] != station.world.get(key): print("world differs: ", key)
	await held_crew()
	print("captain-command-parity: %d passed, %d failures" % [passes, failures])
	quit(1 if failures else 0)

func enter(d: Node, chair: bool, system: String) -> bool:
	if chair: return d.consoles.command.select_system(system)
	d.consoles.leave()
	d.consoles.go_to(system)
	return d.consoles.use(system, "open")

func journey(chair: bool) -> Dictionary:
	var route := "chair" if chair else "station"
	# Each route represents a fresh process. Reset only the process-wide UI offer-id
	# serial in this harness (the simulation never reads it); keep production ids global.
	CrewConsole._serial = 0
	var d: Node = load("res://demos/ship_geometry_demo.tscn").instantiate()
	var journal_path := "/tmp/stapledon-command-" + route + ".ndjson"
	d.setup_options = {"stars": false, "background": false, "live_start": true, "sky_state": "rest", "seed": 1, "record": journal_path}
	d.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(d)
	await process_frame
	d.auto = false; d.journey_auto_tick = false; d.escape_exits = false
	if d.journey_sim == null or not d.ready_ok:
		check(route + " real sim started", false)
		d.queue_free(); await process_frame
		return {}
	d.journey_sim.record_sent = true
	if chair:
		d.avatar_pos = d.walk_bridge.closest_walkable(d.chair_seat() + Vector3(0, 0, .8), 3.)
		check("chair sit starts", d.use_nearest())
		for k in 50: d._process(1. / 60.)
		check("chair authority established", d.consoles.command.authorized())
	var sim: SimBridge = d.journey_sim
	check(route + " opens crew", enter(d, chair, "crew"))
	var cc: CrewConsole = d.consoles.crew_console
	# Actual crew UI: all five offers produce the seed-1 accepting/concern/declining mix.
	for id in ["medic", "engineer", "analyst", "pilot", "counselor"]:
		cc.press("offer:" + id); cc.press("offer:" + id)
	check(route + " sends real crew offers", d.journey_tick())
	var concerns: Array = sim.crew.get("concerns", [])
	var pending: Dictionary = concerns[0] if not concerns.is_empty() else {}
	check(route + " crew raise a seeded concern", not pending.is_empty())
	if not pending.is_empty():
		cc.open_call(str(pending.actor))
		var reply := "reply:" + str(pending.issue) + ":" + str(pending.options[1].approach)
		cc.press(reply); cc.press(reply)
		# Queue a real answer, switch away, then let the existing queue complete it.
		check(route + " switches with a crew answer in flight", enter(d, chair, "comms"))
		check(route + " queued answer completes while hidden", d.journey_tick())
	check(route + " returns to the same crew instance", enter(d, chair, "crew") and d.consoles.crew_console == cc)
	check(route + " one crew step subscription", sim.stepped.get_connections().filter(func(c): return c.callable == d.consoles._on_crew_step).size() == 1)
	if chair:
		cc.open_call("pilot")
		for k in 3: await process_frame
		d.consoles.command.layout_for(Vector2(960, 540), 60.)
		d.consoles._layout_panel()
		for k in 3: await process_frame
		check("960-wide real crew call panel remains on screen", Rect2(Vector2.ZERO, Vector2(960, 540)).encloses(d.consoles.panel.get_global_rect()))
		check("960-wide crew call has no hidden horizontal overflow", d.consoles.panel_body.size.x <= d.consoles.body_scroll.size.x + .1)
	# Archive access and retained answer use the real existing UI, with deterministic offline AI.
	check(route + " opens Archive", enter(d, chair, "archive"))
	d.consoles.ask_field.text = "What is the bubble?"
	check(route + " asks Archive through the dispatcher", d.consoles.use("archive", "ask") and d.consoles.archive_ask.state == "offline")
	check(route + " leaves Archive", enter(d, chair, "comms"))
	check(route + " returns to Archive", enter(d, chair, "archive"))
	await process_frame
	check(route + " retains Archive answer", d.consoles.answer_panel.visible and d.consoles.answer_text.text == ArchiveAsk.OFFLINE)
	check(route + " opens real navigation", enter(d, chair, "navigation"))
	check(route + " plots Alpha Centauri", d.consoles.use("navigation", "select", "CNS5:3627") and d.journey_tick())
	check(route + " commits through existing hold", d.consoles.use("navigation", "commit") and d.journey_tick() and d.live_journey)
	var ticks := 0
	while d.live_journey and ticks < 1600:
		if not d.journey_tick(): break
		ticks += 1
	check(route + " completes the real journey", not d.live_journey and sim.world.journey.state == "arrived")
	check(route + " both clocks advanced", float(sim.world.clock.tau) > .1 and float(sim.world.clock.year) > 1.)
	if chair:
		check("chair remains usable through departure and arrival", d.consoles.command.visible and d.consoles.command.authorized())
		check("chair reopens crew after arrival", enter(d, true, "crew") and d.consoles.crew_console == cc)
	# Normalize no inputs: these are the actual bridge journal entries (including dtau).
	var inputs: Array = sim.sent_log.duplicate(true)
	var world := sim.world.duplicate(true)
	var journal := FileAccess.get_file_as_string(journal_path)
	check(route + " records nonempty NDJSON input evidence", journal.count("\n") > 1000)
	print(route, " journey ticks ", ticks, " journal rows ", inputs.size())
	d.queue_free()
	await process_frame
	return {"inputs": inputs, "world": world, "journal": journal}

func held_crew() -> void:
	var d: Node = load("res://demos/ship_geometry_demo.tscn").instantiate()
	d.setup_options = {"stars": false, "background": false, "live_start": true, "sky_state": "rest", "seed": 1, "crew": "orders"}
	d.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(d)
	await process_frame
	d.auto = false; d.journey_auto_tick = false
	if d.journey_sim == null:
		check("hold scenario starts a real sim", false)
		d.queue_free(); await process_frame; return
	d.avatar_pos = d.walk_bridge.closest_walkable(d.chair_seat() - d.chair_facing(), 3.)
	d.sit_chair()
	for k in 50: d._process(1. / 60.)
	enter(d, true, "crew")
	var cc: CrewConsole = d.consoles.crew_console
	cc.press("orders:hands_on"); cc.press("orders:hands_on")
	d.journey_tick()
	var sim: SimBridge = d.journey_sim
	for day in 30:
		if not sim.crew.get("holds", []).is_empty(): break
		check("hold scenario advances one real crew day", sim.send([], 1. / 365.25 + .000000001))
	d._apply_journey_world()
	var holds: Array = sim.crew.get("holds", [])
	check("standing orders produce a real crew hold", not holds.is_empty())
	if not holds.is_empty():
		var h: Dictionary = holds[0]
		d.consoles.command.select_system("overview")
		d.consoles.command.refresh()
		var links: Array = d.consoles.command.attention.get_children().filter(func(c): return c is Button)
		check("overview exposes the hold as an actionable crew alert", not links.is_empty())
		if not links.is_empty():
			(links[0] as Button).pressed.emit()
			check("attention link opens the actual held actor", d.consoles.focused == "crew" and cc.call_id == str(h.actor))
		if h.rule == "stand_down":
			var m := CrewConsoleModel.member(sim.crew, str(h.actor))
			var release := "standdown:" + str(m.get("stand_down", h.detail)) + ":true"
			cc.press(release); cc.press(release); d.journey_tick()
		cc.press("resume:" + str(h.id)); cc.press("resume:" + str(h.id))
		d.journey_tick()
		check("existing crew confirmation resumes that hold from the chair", not sim.crew.get("holds", []).any(func(x): return x.id == h.id))
		check("handling a hold keeps captain seated", d.consoles.command.authorized())
	d.queue_free()
	await process_frame
