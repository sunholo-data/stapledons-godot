extends SceneTree
## M4.5aR3: real scene/sim, console decisions only, time supplied by step().
const Main := preload("res://main.gd")
const ReviewDrive := preload("res://tests/review_drive.gd")
# The driver's script argument is not a game launch flag: exercise the plain route.
class PlainLaunch extends Main:
	func _user_args() -> Dictionary:
		return {}

var passed := 0
var failures := 0
var demo: Node
var events: FileAccess
var samples: FileAccess
var states: FileAccess
var ai_mode := "none"
var ai_bridge: AiBridge
var ai_relay: AiRelay
var frame := 0
var phase := ""
var poles := {}
var commits_min := 2
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
	var next: String = demo.journey_sim.world.ship.phase
	var changed := next != phase
	if changed:
		phase = next
		event({"type": "phase", "phase": phase})
	# Every fourth presentation frame, plus every phase edge: >500 samples.
	if frame % 4 != 0 and not changed: return
	var bindings := []
	var labels := []
	var view: Dictionary = demo.ship_hud._last_view
	for n in demo.find_children("*", "Label", true, false):
		if not n.is_visible_in_tree(): continue
		if n is DisplayBinding:
			var b := {"node": str(n.get_path()), "field": n.field, "fmt": n.fmt, "text": n.text, "visible": true}
			if n.record_context: b["context"] = n._last_view
			if n is ComposedBinding: b["parts"] = n.parts
			elif n is NewsPanel.CopyBinding: b["map"] = n.map
			elif n is NewsPanel.TemplateText: b["template"] = true
			if n.field.begins_with("entry."):
				var log: LegacyScreen = demo.consoles.legacy_screen
				for i in log.rows.size():
					if n in log.rows[i]: b["entry"] = log.readable(log.entries[i])
			bindings.append(b)
		else: labels.append({"node": str(n.get_path()), "text": n.text, "bound": false})
	var lore := {}
	if demo.codex != null and demo.codex.panel.is_visible_in_tree() and not demo.codex.selected.is_empty():
		var e: Dictionary = demo.codex._entry(demo.codex.selected)
		lore = {"id": demo.codex.selected, "body": demo.codex.shown_body_source(), "title": e.title, "rendered": demo.codex.body_label().text}
	var news := {}
	if demo.consoles.news_panel != null and demo.consoles.news_panel.is_visible_in_tree():
		news = demo.consoles.news_panel.snapshot()
	var cards := []
	for id: String in demo.ship_hud.cards:
		var card: Dictionary = demo.ship_hud.cards[id]
		cards.append({"node": str(card.panel.get_path()), "visible": card.panel.is_visible_in_tree(),
			"expanded": card.body.is_visible_in_tree(), "leaving": card.leaving})
	samples.store_line(SimBridge.encode({"frame": frame, "view": view, "bindings": bindings,
		"labels": labels, "cards": cards, "lore": lore, "news": news, "ai_mode": ai_mode, "review": review_row(), "crew": crew_row()}))
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
		# The engine would run the map's own _process each frame (the harness disables child process); run it with no tick.
		if demo.journey_map != null: demo.journey_map._process(0.0)
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
	if s.use == "archive" and s.action == "news" and ai_mode != "none":
		await finish_ai_news()
		step(0.2)
	if s.use == "archive" and s.action in ["news", "log"]: read(s.action)


func read(what: String) -> void:
	var c: ShipConsoles = demo.consoles
	if what == "news":
		var p: NewsPanel = c.news_panel
		var snap := p.snapshot()
		check(p.is_visible_in_tree() and p.header.is_visible_in_tree() and not p.header.text.is_empty()
			and not snap.body.is_empty(), "news header and body visible")
		event({"type": "read", "what": what, "header": p.header.text, "body": snap.body,
			"words": word_count(" ".join([snap.header, snap.body, snap.tag, snap.notice, snap.reason])),
			"body_source": GalaxyMap.field_value(demo.sky_world, "consequence.news.body_source")})
	else:
		var p: LegacyScreen = c.legacy_screen
		check(p.is_visible_in_tree() and p.closing.is_visible_in_tree() and not p.closing.text.is_empty()
			and not p.entries.is_empty() and LegacyScreen.is_home(demo.sky_world), "Voyage log and closing line visible at home")
		var text := p.closing.text
		for n in p.find_children("*", "Label", true, false):
			if n != p.closing and n.is_visible_in_tree(): text += " " + n.text
		event({"type": "read", "what": what, "closing": p.closing.text, "entries": p.entries, "words": word_count(text)})


func word_count(text: String) -> int:
	return text.replace("\n", " ").split(" ", false).size()


func finish_ai_news() -> void:
	if ai_mode == "digits":
		# The landed service's digits fixture travels in the sim's request context.
		ai_relay._queue[0]["context"] = {"stub_case": "digits"}
	check(demo.journey_sim.send([], 0.0), "AI request enters scene session")
	for i in 12000:
		ai_bridge.poll()
		if ai_relay.queued() > 0: break
		await process_frame
	if not check(ai_relay.queued() == 1, "local stub answered"): return
	check(demo.journey_sim.send([], 0.0), "AI record enters scene session")
	demo._apply_journey_world()
	demo.consoles.news_panel.show_world(demo.journey_sim.world)


func pole() -> void:
	var h: Dictionary = demo.journey_sim.world.ship.heading
	var heading := PackedFloat64Array([h.x, h.y, h.z])
	var norm := sqrt(heading[0]*heading[0] + heading[1]*heading[1] + heading[2]*heading[2])
	# Float64 until the Camera3D projection boundary. The scene's sky camera is
	# oriented by the real ship camera; look along the bow (+ship Z = travel, D-92).
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
	# A view choice, never a decision key; aim the captain's eye at the forward pole (D-92: the
	# bow, glTF -z, level).
	demo.director.override() # R2-CAMERA: a measurement pose; tools take the camera through the director
	demo.camera.follow(demo.avatar_pos, -0.01, -PI * 0.5, 0.0)
	for i in 2400: # 120 fake seconds, bounded even when the sim cannot arrive
		var w: Dictionary = demo.journey_sim.world
		if str(w.journey.state) == s.until or str(w.ship.phase) == s.until:
			if s.has("target"): check(str(w.journey.plan.target.id) == s.target, "arrival target: " + s.target)
			return
		step(0.05, true)
		if failures: return
		if phase in ["boosting", "cruising", "braking"]: pole()
	check(false, "no arrival or phase: " + s.until)


## R2-INTERLUDE I3 (AC8): the crossing review in the sample row: shown, which page, which pages.
func review_row() -> Dictionary:
	var r: CrossingReview = demo.crossing_review
	if r == null or not r.is_visible_in_tree(): return {}
	return {"page": r.current(), "pages": r.page_ids()}


## R2-CREW-CONSOLE-V2 V7 (AC14): the Crew console in the sample row: who is on the call, their state.
func crew_row() -> Dictionary:
	var cc: CrewConsole = demo.consoles.crew_console
	if cc == null or not cc.is_visible_in_tree(): return {}
	var m := CrewConsoleModel.member(cc.crew, cc.call_id)
	return {"call": cc.call_id, "state": CrewConsoleModel.state(m, {"sending": cc.sending}) if not m.is_empty() else ""}


## {"crew": [actions], "tick": bool}: press each action on the open Crew console (as the captain's
## clicks would), sampling after each; with "tick", one journey tick then carries what was queued.
func crew(s: Dictionary) -> void:
	var cc: CrewConsole = demo.consoles.crew_console
	if not check(cc != null and demo.consoles.focused == "crew", "the Crew console is open"): return
	for a: String in s.crew:
		cc.press(a)
		step(0.1)
	if s.get("tick", false):
		if not check(demo.journey_tick(), "crew tick completes"): return
		check(demo.journey_sim.last_refused.is_empty(), "the crew's intents are accepted (%s)" % [demo.journey_sim.last_refused])
		step(0.2)
	event({"type": "crew", "actions": s.crew, "states": cc.crew.get("members", []).map(func(m): return "%s=%s" % [m.get("id"), m.get("work_state")])})


## {"start": "guided", "leg": n}: Begin the guided voyage at the Voyage console (walked to, opened,
## Begin pressed), flying itinerary leg n next. The guided voyage is its own sim session, so the
## evidence (states, samples) restarts with it; the session tee records it from its new_game.
func start(s: Dictionary) -> void:
	walk("voyage")
	if failures: return
	if not check(demo.consoles.use("voyage", "open") and demo.consoles.use("voyage", "begin"), "the Voyage console begins the guided voyage"): return
	event({"type": "start", "what": s.start, "leg": int(s.get("leg", -1))})
	if not check(demo.solar_tour != null, "guided voyage started"): return
	if s.has("leg"): demo.solar_tour.leg_index = int(s.leg) - 1
	samples.close(); states.close()
	samples = FileAccess.open(scratch.path_join("display_samples.ndjson"), FileAccess.WRITE)
	states = FileAccess.open(scratch.path_join("states.ndjson"), FileAccess.WRITE)
	demo.journey_sim.record_sent = true
	states.store_line(SimBridge.encode({"type": "state", "tick": demo.journey_sim.world.tick,
		"status": "ok", "full": true, "changes": demo.journey_sim.world}))
	demo.journey_sim.stepped.connect(func(_events: Array) -> void: states.store_line(SimBridge.encode(demo.journey_sim.state)))
	demo.consoles.leave()
	step(0.65)


## {"until": "review"}: fly the leg (Skip dwell, Skip stage through the boost, the cruise's real-time
## hold, then the crossing chunk by chunk) until the crossing review is over. A hold mid-crossing
## is answered on the review's Hold page with its confirmed Resume (two presses), sampled first.
func until_review() -> void:
	var r: CrossingReview = demo.crossing_review
	for i in 6000:
		var tour = demo.solar_tour
		if tour.crew_held() and tour.interlude != null and r.visible and r.current() == "hold":
			step(0.5)
			event({"type": "hold", "hold": str(demo.journey_sim.crew.holds[0].id)})
			r.press_resume()
			step(0.1)
			r.press_resume()
			step(0.05, true) # the held zero tick carries the queued crew_resume
			continue
		var st: String = ReviewDrive.frame(demo, true)
		if demo.journey_map != null: demo.journey_map._process(0.0) # as step() does: the engine would run it
		sample()
		if not check(refusal().is_empty(), "unscripted refusal: " + refusal()): return
		if st == "crossed":
			event({"type": "review", "pages": r.page_ids()})
			if ai_mode != "none": await narrate()
			return
		if not check(st != "failed", "the crossing reaches its review (%s)" % tour.failed): return
	check(false, "no crossing review")


## R2-INTERLUDE I4 (AI modes): the Archive's telling of the crossing through the local stub service,
## recorded in the session as sim input. stub: the telling is accepted (page 1 shows it) and voiced
## once (the stub voice); digits: the stub answers with digits, the sim refuses it (ai_numeral) and
## the authored line stands. The playthrough's own relay plays the live AI (no key, no provider).
func narrate() -> void:
	var n: ArchiveNarration = demo.archive_narration
	if demo.journey_sim.ai_relay != ai_relay: ai_relay.attach(demo.journey_sim) # the guided voyage's session
	if not check(n.maybe_open(demo.hud_view(), ai_relay, true) and ai_relay.queued() == 1, "I4 the Archive is asked for its telling once the crossing is over"): return
	if ai_mode == "digits":
		var ctx: Dictionary = ai_relay._queue[0]["context"]
		ctx.erase("canon") # at most 8 context fields: the stub's digits case takes the canon's place
		ctx["stub_case"] = "digits"
	for leg in ["text", "voice"]:
		check(demo.journey_sim.send([], 0.0), "I4 the %s request enters the session" % leg)
		for i in 12000:
			ai_bridge.poll()
			if ai_relay.queued() > 0: break
			await process_frame
		if not check(ai_relay.queued() == 1, "I4 the local stub answered the %s request" % leg): return
		check(demo.journey_sim.send([], 0.0), "I4 the %s record enters the session" % leg)
		if ai_mode == "digits" or leg == "voice": break
		if not check(n.state == "told" and ai_relay.queued() == 1, "I4 the telling is accepted and its voice asked (%s, %s)" % [n.state, n.telling]): return
	demo._show_interlude()
	var r: CrossingReview = demo.crossing_review
	var page := r.page
	r.go(r.page_ids().find("crossing"))
	var said: Label = r.find_child("Page_crossing", true, false).find_child("Narration", true, false)
	if ai_mode == "digits":
		check(n.state == "authored" and said != null and said.text.contains(str(GalaxyMap.field_value(demo.hud_view(), "cruise.digest.narration.crossing"))), "I4 digits: the telling is refused; the authored line stands")
	else:
		check(said != null and said.text.contains(n.telling) and n.telling.begins_with("Stub archive entry") and not n.voice.is_empty() and n.voiced == 1, "I4 stub: page 1 shows the telling; it is voiced once")
	event({"type": "narration", "mode": ai_mode, "state": n.state, "telling": n.telling, "voiced": n.voiced, "voice": str(n.voice.get("sha256", ""))})
	if failures == 0: print("narration: %s state=%s voiced=%d" % [ai_mode, n.state, n.voiced])
	sample()
	r.go(page)


## {"review": "all"}: read every page, turning with → (the player's key); "last": Brake on the last.
func review(s: Dictionary) -> void:
	var r: CrossingReview = demo.crossing_review
	if not check(r.visible, "the crossing review is shown"): return
	match str(s.review):
		"next", "all":
			for i in (r.page_ids().size() if s.review == "all" else 1):
				step(0.5)
				if r.last_page(): break
				var k := InputEventKey.new(); k.physical_keycode = KEY_RIGHT; k.keycode = KEY_RIGHT; k.pressed = true
				demo._unhandled_input(k)
			step(0.5)
		"last":
			check(r.last_page(), "the review is on its last page")
			var b: Button = r.find_child("Brake", true, false)
			if not check(b != null and b.is_visible_in_tree(), "the last page offers Brake"): return
			b.pressed.emit()
			step(0.5, true)
			check(demo.solar_tour.interlude == null and not r.visible, "Brake ends the review; the leg brakes")
		_: check(false, "unknown review step")


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
	check(not lines.is_empty() and games == 1 and commits >= commits_min, "session has new_game and %d commits" % commits_min)
	print("session lines=%d new_game=%d commit=%d" % [lines.size(), games, commits])


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 1: scratch = ProjectSettings.globalize_path(args[1])
	if args.size() > 2: ai_mode = args[2]
	if not check(ai_mode in ["none", "stub", "digits"], "known AI mode"): quit(1); return
	var path := args[0] if not args.is_empty() else "res://tests/playthrough_min.json"
	var script: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not check(script is Dictionary and script.get("steps") is Array and not script.steps.is_empty(), "valid script"):
		quit(1); return
	DirAccess.make_dir_recursive_absolute(scratch)
	DirAccess.remove_absolute(scratch.path_join("session.ndjson")) # a stale tee cannot satisfy H1
	events = FileAccess.open(scratch.path_join("events.ndjson"), FileAccess.WRITE)
	samples = FileAccess.open(scratch.path_join("display_samples.ndjson"), FileAccess.WRITE)
	states = FileAccess.open(scratch.path_join("states.ndjson"), FileAccess.WRITE)
	if not check(events != null and samples != null, "evidence files open"): quit(1); return
	Main.title_overrides = {"sky": false, "settings_dir": scratch}
	root.size = Vector2i(1280, 720)
	Main.demo_overrides = {"stars": false, "background": false, "ai": false, "seed": 424242,
		"size": Vector2i(1280, 720), "confirm_mode": "hold", "record": scratch.path_join("session.ndjson")}
	if script.has("crew"): Main.demo_overrides["crew"] = str(script.crew) # R2-INTERLUDE: an orders crew raises holds
	commits_min = int(script.get("commits_min", 2))
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
	states.store_line(SimBridge.encode({"type": "state", "tick": demo.journey_sim.world.tick,
		"status": "ok", "full": true, "changes": demo.journey_sim.world}))
	demo.journey_sim.stepped.connect(func(_events: Array) -> void: states.store_line(SimBridge.encode(demo.journey_sim.state)))
	if ai_mode != "none":
		ai_bridge = AiBridge.new(); ai_bridge.cache_dir = scratch.path_join("ai-cache"); root.add_child(ai_bridge)
		var cache := AiCache.new(); cache.library_dir = scratch.path_join("unused-cache")
		ai_relay = AiRelay.new(ai_bridge, cache); ai_relay.keys = ["gemini", "openrouter"]; ai_relay.attach(demo.journey_sim)
		ai_bridge.set_process(false)
	check(demo.journey_sim.last_seed == 424242, "seed pinned through title route")
	for s: Dictionary in script.steps:
		if s.has("walk"): walk(s.walk)
		elif s.has("use"): await use(s)
		elif s.has("until") and s.until == "review": await until_review()
		elif s.has("until"): until(s)
		elif s.has("start"): start(s)
		elif s.has("review"): review(s)
		elif s.has("crew"): crew(s)
		else: check(false, "unknown script step")
		if failures: break
	demo.journey_sim.stop() # close H1's tee, including the quit line, before checking it
	if failures == 0:
		session_check()
		for p in ([] if script.get("poles", true) == false else ["boosting", "cruising", "braking"]):
			check(poles.has(p), "pole sampled in " + p)
			print("pole %s max_px=%.9f" % [p, float(poles.get(p, INF))])
	events.close(); samples.close(); states.close()
	if ai_bridge != null: ai_bridge.shutdown(); ai_bridge.queue_free()
	demo.queue_free()
	await process_frame
	print("playthrough: %d passed, %d failures" % [passed, failures])
	quit(1 if failures else 0)
