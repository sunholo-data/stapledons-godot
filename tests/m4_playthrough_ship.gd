extends SceneTree
## M4.5aR3: real scene/sim, console decisions only, time supplied by step().
const Main := preload("res://main.gd")
# The driver's script argument is not a game launch flag: exercise the plain route.
class PlainLaunch extends Main:
	func _user_args() -> Dictionary:
		return {}

var passed := 0
var failures := 0
var demo: Node
var events: FileAccess
var samples: FileAccess
var frame := 0
var phase := ""
var poles := {}
var scratch := ProjectSettings.globalize_path("res://.godot/tmp/playthrough")


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> bool:
	if ok: passed += 1
	else:
		failures += 1
		print("FAIL " + message)
	return ok


func event(row: Dictionary) -> void:
	events.store_line(JSON.stringify(row))


func refusal() -> String:
	if not demo.ship_hud.has_card("refusal"): return ""
	return demo.caption # the binding is filled on the next presentation frame


func sample() -> void:
	frame += 1
	# This milestone records bindings only; M4.5bR3 audits their values.
	var bindings := []
	for n in demo.find_children("*", "Label", true, false):
		if n is DisplayBinding:
			bindings.append({"node": str(n.get_path()), "field": n.field, "fmt": n.fmt,
				"text": n.text, "visible": n.is_visible_in_tree()})
	samples.store_line(JSON.stringify({"frame": frame, "view": demo.hud_view(), "bindings": bindings}))
	var next: String = demo.journey_sim.world.ship.phase
	if next != phase:
		phase = next
		event({"type": "phase", "phase": phase})
	# D-68 applies to every action list and all currently visible text, including windows.
	for actions: Array in ShipConsoles.ACTIONS.values():
		for a: String in actions:
			check(a.to_lower() not in ["begin again", "new game", "new_game"], "console offers a new voyage")
	for n in demo.find_children("*", "Control", true, false):
		if n.is_visible_in_tree() and (n is Label or n is Button or n is RichTextLabel):
			var txt: String = n.text.to_lower()
			check(not txt.contains("begin again") and not txt.contains("new game"), "ship UI offers a new voyage")


func step(seconds: float, tick := false) -> void:
	var elapsed := 0.0
	while elapsed < seconds - 1e-9 and failures == 0:
		if tick and not check(demo.journey_tick(), "journey tick completes"): return
		demo._process(0.05)
		sample()
		if not check(refusal().is_empty(), "unscripted refusal: " + refusal()): return
		elapsed += 0.05


func walk(id: String) -> void:
	var c: ShipConsoles = demo.consoles
	# Leaving is presentation only; all scored travel still goes through walk_to.
	if not c.focused.is_empty():
		c.leave()
		step(0.65)
	if not check(c.walk_to(id), "walk has a path: " + id): return
	var previous: Vector3 = demo.avatar_pos
	var path_m := 0.0
	for point: Vector3 in c.walking:
		path_m += previous.distance_to(point)
		previous = point
	event({"type": "walk", "to": id, "path_m": path_m})
	print("walk %s path_m=%.9f" % [id, path_m])
	if not check(path_m <= 40.0, "walk exceeds 40 m: " + id): return
	step(path_m / ShipConsoles.WALK_SPEED_MPS + 0.1)
	check(c.walking.is_empty() and demo.avatar_pos.distance_to(c.stations[id].use) < 0.01, "walk completes: " + id)


func player_intents() -> Array:
	return demo.journey_sim.sent_log.filter(func(e: Dictionary) -> bool: return e.source == "player").map(func(e: Dictionary) -> Array: return e.intents)


func use(s: Dictionary) -> void:
	var c: ShipConsoles = demo.consoles
	var expected: String = s.get("expected_refusal", "")
	var before: Dictionary = demo.journey_sim.world.duplicate(true)
	var sent := player_intents().size()
	if s.action == "commit" and expected.is_empty():
		step(ShipConsoles.HOLD_S)
		if not check(player_intents().size() == sent, "hold has no early decision"): return
	var ok := c.use(s.use, s.action, s.get("arg"))
	event({"type": "use", "station": s.use, "action": s.action, "ok": ok})
	if expected.is_empty() and not check(refusal().is_empty(), "unscripted refusal: " + refusal()): return
	if not check(ok, "console action completes: %s/%s (%s)" % [s.use, s.action, refusal()]): return
	if not expected.is_empty():
		demo._process(0.1) # fade the refusal card in, with the journey clock held
		var refused: Array = demo.journey_sim.last_refused
		check(refused.size() == 1 and str(refused[0].reason) == expected, "expected sim refusal: " + expected)
		for section in ["journey", "clock"]:
			check(before[section] == demo.journey_sim.world[section], "refusal preserves " + section)
		for field: String in before.ship:
			if field == "ism": continue # per-tick dust display samples are not journey state
			check(before.ship[field] == demo.journey_sim.world.ship[field], "refusal preserves ship." + field)
		for field: String in before.ship.ism:
			if field not in ["dust", "glitter", "impacts"]:
				check(before.ship.ism[field] == demo.journey_sim.world.ship.ism[field], "refusal preserves ISM." + field)
		for field in ["leg_drawn", "leg_expected", "leg_grains", "largest_um", "largest_j"]:
			check(before.ship.ism.dust[field] == demo.journey_sim.world.ship.ism.dust[field], "refusal preserves dust." + field)
		check(not refusal().is_empty() and demo.ship_hud.cards.refusal.panel.is_visible_in_tree()
			and demo.ship_hud.cards.refusal.panel.modulate.a > 0.0, "expected refusal card is visible")
		check(player_intents().size() == sent + 1, "refused intent reaches sim through console")
		sample()
		demo.ship_hud.hide_card("refusal")
		return
	if not check(refusal().is_empty(), "unscripted refusal: " + refusal()): return
	if s.action in ["select", "home", "commit", "cancel", "speed"]:
		if not check(demo.journey_tick(), "console decision tick completes"): return
		if not check(demo.journey_sim.last_refused.is_empty(), "unscripted sim refusal"): return
	step(0.65) # console dolly, including the step back at departure
	if s.use == "archive" and s.action in ["news", "log"]: read(s.action)


func read(what: String) -> void:
	var c: ShipConsoles = demo.consoles
	if what == "news":
		var p: NewsPanel = c.news_panel
		check(p.is_visible_in_tree() and p.header.is_visible_in_tree() and not p.header.text.is_empty()
			and p.body.is_visible_in_tree() and not p.body.text.is_empty(), "news header and body visible")
		event({"type": "read", "what": what, "header": p.header.text, "body": p.body.text,
			"body_source": GalaxyMap.field_value(demo.sky_world, "consequence.news.body_source")})
	else:
		var p: LegacyScreen = c.legacy_screen
		check(p.is_visible_in_tree() and p.closing.is_visible_in_tree() and not p.closing.text.is_empty()
			and not p.entries.is_empty() and LegacyScreen.is_home(demo.sky_world), "Voyage log and closing line visible at home")
		event({"type": "read", "what": what, "closing": p.closing.text, "entries": p.entries})


func pole() -> void:
	var h: Dictionary = demo.journey_sim.world.ship.heading
	var heading := PackedFloat64Array([h.x, h.y, h.z])
	var norm := sqrt(heading[0]*heading[0] + heading[1]*heading[1] + heading[2]*heading[2])
	# Float64 until the Camera3D projection boundary. The scene's sky camera is
	# oriented by the real ship camera; look straight up (+ship Z = travel).
	var cam: Camera3D = demo.sky.camera
	var direction := SkyFrame.to_world(Vector3(heading[0]/norm, heading[1]/norm, heading[2]/norm))
	var pixel := cam.unproject_position(cam.global_position + direction * 100.0)
	var forward := cam.unproject_position(cam.global_position - cam.global_basis.z * 100.0)
	var offset: float = pixel.distance_to(forward)
	var viewport_size := cam.get_viewport().get_visible_rect().size
	check(viewport_size.x >= 1280.0 and viewport_size.y >= 720.0
		and forward.distance_to(viewport_size * 0.5) <= 0.01, "pole projection uses a full viewport")
	check(is_finite(offset) and not cam.is_position_behind(cam.global_position + direction * 100.0)
		and offset <= 0.75, "forward pole %s offset %.9f px" % [phase, offset])
	poles[phase] = maxf(float(poles.get(phase, 0.0)), offset)


func until(s: Dictionary) -> void:
	var c: ShipConsoles = demo.consoles
	if not c.focused.is_empty(): c.leave()
	step(0.65)
	# A view choice, never a decision key; aim the captain's eye at the forward pole.
	# Stay off the exact zenith, where Basis.looking_at's up vector is collinear.
	demo.camera.follow(demo.avatar_pos, 89.99, 0.0, 0.0)
	for i in 2400: # 120 fake seconds, bounded even when the sim cannot arrive
		var w: Dictionary = demo.journey_sim.world
		if str(w.journey.state) == s.until or str(w.ship.phase) == s.until:
			if s.has("target"): check(str(w.journey.plan.target.id) == s.target, "arrival target: " + s.target)
			return
		step(0.05, true)
		if failures: return
		if phase in ["boosting", "cruising", "braking"]: pole()
	check(false, "no arrival or phase: " + s.until)


func session_check() -> void:
	var path := scratch.path_join("session.ndjson")
	if not check(FileAccess.file_exists(path), "missing session file"): return
	var lines := FileAccess.get_file_as_string(path).split("\n", false)
	var games := 0
	var commits := 0
	for line: String in lines:
		var row: Variant = JSON.parse_string(line)
		if not check(row is Dictionary and row.get("v") == 2, "session protocol schema"): return
		if row.type == "new_game": games += 1
		if row.type == "input":
			check(row.has("tick") and row.has("dtau") and row.intents is Array, "session input schema")
			for intent: Dictionary in row.intents:
				if intent.k == "commit": commits += 1
	check(not lines.is_empty() and games == 1 and commits >= 2, "session has new_game and two commits")
	print("session lines=%d new_game=%d commit=%d" % [lines.size(), games, commits])


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 1: scratch = ProjectSettings.globalize_path(args[1])
	var path := args[0] if not args.is_empty() else "res://tests/playthrough_min.json"
	var script: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not check(script is Dictionary and script.get("steps") is Array and not script.steps.is_empty(), "valid script"):
		quit(1); return
	DirAccess.make_dir_recursive_absolute(scratch)
	DirAccess.remove_absolute(scratch.path_join("session.ndjson")) # a stale tee cannot satisfy H1
	events = FileAccess.open(scratch.path_join("events.ndjson"), FileAccess.WRITE)
	samples = FileAccess.open(scratch.path_join("display_samples.ndjson"), FileAccess.WRITE)
	if not check(events != null and samples != null, "evidence files open"): quit(1); return
	Main.title_overrides = {"sky": false, "settings_dir": scratch}
	root.size = Vector2i(1280, 720)
	Main.demo_overrides = {"stars": false, "background": false, "ai": false, "seed": 424242,
		"size": Vector2i(1280, 720), "confirm_mode": "hold", "record": scratch.path_join("session.ndjson")}
	var main := PlainLaunch.new()
	root.add_child(main)
	current_scene = main
	if check(main.title != null and main.title.buttons.ship.text == "New game", "plain launch shows title New game"):
		main.title.buttons.ship.pressed.emit()
		await process_frame
		demo = current_scene
	if not check(demo != null and demo.get_script() == preload("res://demos/ship_geometry_demo.gd") and demo.ready_ok, "New game opens ship"):
		quit(1); return
	demo.auto = false
	demo.journey_auto_tick = false
	# Disable engine-driven updates; every subsequent frame is supplied by step().
	demo.set_process(false)
	for n in demo.find_children("*", "", true, false): n.set_process(false)
	demo.journey_sim.record_sent = true
	check(demo.journey_sim.last_seed == 424242, "seed pinned through title route")
	for s: Dictionary in script.steps:
		if s.has("walk"): walk(s.walk)
		elif s.has("use"): use(s)
		elif s.has("until"): until(s)
		else: check(false, "unknown script step")
		if failures: break
	demo.journey_sim.stop() # close H1's tee, including the quit line, before checking it
	if failures == 0:
		session_check()
		for p in ["boosting", "cruising", "braking"]:
			check(poles.has(p), "pole sampled in " + p)
			print("pole %s max_px=%.9f" % [p, float(poles.get(p, INF))])
	events.close(); samples.close()
	demo.queue_free()
	await process_frame
	print("playthrough: %d passed, %d failures" % [passed, failures])
	quit(1 if failures else 0)
