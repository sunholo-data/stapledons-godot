extends SceneTree
## R1-SHIP-UI (D-56) U0-U2: the HUD informs. make ship-ui-test.
##   AC1  the status strip shows ship clock, home clock and distance in every scene state; each
##        value equals its sim field formatted (DisplayBinding); captions are digit-free
##   AC2  both clocks the same size; speed only while moving, from ship.one_minus_beta
##   AC3  each contextual card appears and leaves on its trigger; at most two expanded; none
##        over the centre third at 1280x720 and 2560x1440 (and a small UI-scaled canvas)
##   AC7  NT5: ShipControls and _unhandled_input match both ways
##   AC11 developer controls absent on a menu launch, present on a command-line launch
## Time is the HUD's fake clock (advance via _process(dt)); no wall-clock reads (AC13).

const Demo := preload("res://demos/ship_geometry_demo.gd")
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
	await test_mouse_look()
	await test_ism_hud()
	await test_ism_body_pick_guard()
	if failures:
		print("ship-ui: %d passed, %d failures" % [passes, failures])
		quit(1)
		return
	test_control_table()
	await test_strip_and_cards()
	await test_dev_gating()
	await test_dwell()
	await test_final_leg_look()
	print("ship-ui: %d passed, %d failures" % [passes, failures])
	quit(1 if failures else 0)


func ism_view(medium := "LIC", density := 0.2474) -> Dictionary:
	return {"clock": {"tau": 1.0, "year": 3.0}, "ship": {"phase": "cruising", "ism": {"model": "lism-1", "medium": medium, "n_h_cm3": density, "n_eff_m3": 347000.0, "dust": {"visible_rate": 17.5, "bright_rate": 4.5, "leg_grains": 1200000.0, "leg_drawn": 42, "leg_expected": 43.2, "largest_um": 3.2, "largest_j": 12345.0}}}, "journey": {"state": "committed", "plan": {"ism_model": "lism-1", "distance": 4.0, "media": [{"name": "LIC", "length_ly": 1.0}, {"name": "G", "length_ly": 2.0}, {"name": "hot", "length_ly": 1.0}]}}, "consequence": {"distance_remaining": 3.5}, "hud": {}}


func test_ism_hud() -> void:
	var hud := ShipHud.new()
	root.add_child(hud)
	hud.setup(false)
	check("ISM HUD has the session-reset seam", hud.has_method("reset_medium"))
	if not hud.has_method("reset_medium"):
		hud.queue_free()
		return
	var view := ism_view()
	hud.call("reset_medium", view)
	hud.show_card("transit", "Transit")
	hud.update(view)
	check("ISM initial world is not a boundary notice", not hud.has_card("medium_notice"))
	var fields: Array = hud.card_body("transit").find_children("*", "DisplayBinding", true, false).map(func(b): return b.field)
	check("ISM compact medium/density/impact rows come from bindings", fields.has("ship.ism.medium") and fields.has("ship.ism.n_h_cm3") and fields.has("hud.ism.impacts"))
	check("ISM density formats atoms per litre", hud.all_text().contains("247.4 H atoms/L"))
	check("ISM flashes explicitly per ship second", hud.all_text().contains("17.50/ship-s") and hud.all_text().contains("3.20 µm"))
	check("ISM all numbers use clean bindings", DisplayBinding.audit(hud).is_empty())
	view = ism_view("G")
	hud.update(view)
	check("ISM real medium change emits one notice", hud.has_card("medium_notice") and hud.all_text().contains("Leaving the Local Interstellar Cloud") and hud.all_text().contains("Entering G cloud"))
	var expires: float = hud.cards.medium_notice.expires
	hud.advance(2.0)
	hud.update(view)
	check("ISM repeated world/refusal cannot refresh boundary notice", hud.cards.medium_notice.expires == expires)
	hud.advance(6.1)
	check("ISM boundary notice expires after eight fake seconds", not hud.has_card("medium_notice"))
	hud.advance(0.7)
	hud.update(ism_view("hot", 0.004))
	check("ISM entering bubble has hot-gas wording", hud.all_text().contains("Local Bubble"))
	var compressed := ism_view("hot", 0.004)
	compressed.tick = 42
	compressed.ship.ism.crossed_media = [{"name": "hot", "n_h_cm3": 0.004}, {"name": "Hyades", "n_h_cm3": 0.2474}, {"name": "hot", "n_h_cm3": 0.004}]
	hud.update(compressed)
	check("ISM compressed same-endpoint tick reports both actual boundaries", hud.all_text().contains("Entering Hyades cloud") and hud.all_text().contains("Leaving Hyades cloud"))
	var compressed_expires: float = hud.cards.medium_notice.expires
	hud.advance(1.0)
	hud.update(compressed)
	check("ISM compressed boundary list is consumed once per simulation tick", hud.cards.medium_notice.expires == compressed_expires)
	var uniform := ism_view()
	uniform.ship.ism.model = "uniform"
	hud.update(uniform)
	check("ISM uniform stream hides medium rows and notices", not hud.has_card("medium_notice") and not hud.card_body("transit").get_node("IsmTransit").visible and not hud.ism_details.visible)
	hud.update({"ship": {"ism": {"glow_w_m2": 0.0}}, "hud": {}})
	check("ISM old stream stays hidden", not hud.ism_details.visible)
	hud.update(ism_view("Hyades"))
	check("ISM first enriched world after old stream is quiet", not hud.has_card("medium_notice"))
	hud.toggle_tab()
	check("ISM Tab has route media and full dust totals", hud.ism_details.visible and hud.ism_details.find_children("*", "DisplayBinding", true, false).any(func(b): return b.field == "ship.ism.dust.leg_grains"))
	cards_clear_centre(hud, "ISM medium rows")
	# R2-INTERLUDE I3: the crossing review's medium page reads the sim's digest (media crossed in
	# order, grains swept this leg, the largest impact); Godot no longer slices or subtracts.
	var rv := ism_view("G")
	rv["cruise"] = {"digest": {"time": {"ship_days": 70.0}, "home": {"tier": 1.0}, "crew": null,
		"medium": {"model": "lism-1", "media": [{"name": "LIC", "n_h_cm3": 0.2474}, {"name": "G", "n_h_cm3": 0.2474}], "grains_swept": 2000000.0, "largest_um": 3.5, "largest_j": 1000000.0}}}
	rv["review"] = {"leg": "alpha Cen", "target": "alpha Cen"}
	var panel := CrossingReview.new()
	root.add_child(panel)
	panel.show_review(rv, true)
	panel.go(panel.page_ids().find("medium"))
	var shown: Array = panel.find_children("*", "Label", true, false).filter(func(l): return l.is_visible_in_tree()).map(func(l): return l.text)
	check("ISM review medium page lists the sim's media in order", panel.current() == "medium" and shown.any(func(s): return s.begins_with("Local Interstellar Cloud · ")) and shown.any(func(s): return s.begins_with("G cloud · ")))
	check("ISM review grains are the digest's grains_swept", shown.has("Grains swept (≥ 1 µm): 2.000e6") and shown.any(func(s): return s.begins_with("Largest displayed impact this leg: 3.50 µm")))
	panel.custom_minimum_size = Vector2(600, 360)
	panel.reset_size()
	await process_frame
	await process_frame
	var nav: Control = panel.find_child("Nav", true, false)
	var scroll: ScrollContainer = panel.find_children("*", "ScrollContainer", true, false)[0]
	check("ISM review fits a reduced canvas height", panel.size.y <= 360.5)
	check("ISM review page buttons stay outside the scrolling page", not scroll.is_ancestor_of(nav) and nav.get_global_rect().end.y <= panel.get_global_rect().end.y)
	panel.queue_free()
	hud.queue_free()
	await process_frame


func test_ism_body_pick_guard() -> void:
	var demo: Node = await new_demo({"live_start": true, "sky_state": "rest"})
	var sv: SystemView = demo.sky.system_view
	var saved: Dictionary = sv.last_system
	var visible := sv.visible
	sv.visible = true
	sv.last_system = {"bodies": [{"id": "observer-coincident", "kind": "star", "radius_km": 1.0, "rel_km": {"x": 0.0, "y": 0.0, "z": 0.0}}]}
	demo.star_identification.candidates.clear()
	demo.star_identification._add_body_candidates(demo.sky, Basis.IDENTITY, 100.0, Vector2(1280, 720), Transform2D.IDENTITY)
	check("ISM I fallback never offers an observer-coincident body", demo.star_identification.candidates.is_empty())
	sv.last_system = saved
	sv.visible = visible
	demo.queue_free()
	await process_frame


## The keys _unhandled_input matches (the match on event.physical_keycode).
static func matched_in_source() -> PackedStringArray:
	var src := FileAccess.get_file_as_string("res://demos/ship_geometry_demo.gd")
	var body := src.substr(src.find("func _unhandled_input("))
	body = body.substr(0, body.find("\nfunc ", 10))
	var block := body.substr(body.find("match event.physical_keycode:"))
	var re := RegEx.new()
	re.compile("\\n\\t\\t\\t(KEY_[A-Z0-9_]+):")
	var out := PackedStringArray()
	for m in re.search_all(block):
		out.append(m.get_string(1))
	return out


func test_control_table() -> void:
	var code := matched_in_source()
	var table := ShipControls.matched_keys()
	check("AC7 source has a key match (%d keys)" % code.size(), code.size() >= 15)
	var missing_in_table := Array(code).filter(func(k: String) -> bool: return not table.has(k))
	var missing_in_code := Array(table).filter(func(k: String) -> bool: return not code.has(k))
	check("AC7 every key the demo matches is a table row %s" % [missing_in_table], missing_in_table.is_empty())
	check("AC7 every matched table row is matched by the demo %s" % [missing_in_code], missing_in_code.is_empty())
	var kinds := ["display", "pacing", "camera", "move", "dev", "console"]
	check("AC7 every row has a §F kind", ShipControls.KEYS.all(func(r: Dictionary) -> bool: return r.kind in kinds))
	check("AC7 every console row names a station action use() accepts", ShipControls.CONSOLE.all(func(r: Dictionary) -> bool: return ShipConsoles.ACTIONS.has(r.station) and ShipConsoles.ACTIONS[r.station].has(r.action)))
	check("AC7 NT5 no key row has kind console", ShipControls.KEYS.all(func(r: Dictionary) -> bool: return r.kind != "console"))
	check("AC7 N, L and C no longer decide (N is the tour's skip dwell)", ShipControls.row("KEY_N").kind == "pacing" and ShipControls.row("KEY_L").is_empty() and ShipControls.row("KEY_C").is_empty() and ShipControls.row("KEY_M").kind == "display")
	check("AC7 display controls (V J I Tab H Esc M-chart and the camera keys) are never console", ["KEY_V", "KEY_J", "KEY_I", "KEY_TAB", "KEY_H", "KEY_ESCAPE", "KEY_1", "KEY_R", "KEY_7", "KEY_EQUAL", "KEY_MINUS"].all(func(k: String) -> bool: return ShipControls.row(k).kind != "console"))
	# F4: near c the digits follow one_minus_beta (never 1 - beta), up to 15 places.
	check("speed near c: 1 - beta = 1e-12 shows twelve nines (%s)" % Demo.speed_text({"beta": 1.0 - 1e-12, "one_minus_beta": 1e-12, "gamma": 707106.8}), Demo.speed_text({"beta": 1.0 - 1e-12, "one_minus_beta": 1e-12, "gamma": 707106.8}).begins_with("0.999999999999c"))
	check("Tab help groups the controls", ShipControls.help_text(false).contains("Display:") and not ShipControls.help_text(false).contains("Developer:") and ShipControls.help_text(true).contains("Developer:"))
	# R2-CAMERA D5: the camera keys are named InputMap actions; NT5 both ways for them too.
	CameraDirector.ensure_actions()
	var bound := ShipControls.action_keys()
	var src := FileAccess.get_file_as_string("res://demos/ship_geometry_demo.gd")
	var body := src.substr(src.find("func _camera_action("))
	body = body.substr(0, body.find("\nfunc ", 10))
	var unbound := []
	for k: String in bound:
		var e := InputEventKey.new()
		e.physical_keycode = {"KEY_1": KEY_1, "KEY_2": KEY_2, "KEY_3": KEY_3, "KEY_EQUAL": KEY_EQUAL, "KEY_MINUS": KEY_MINUS, "KEY_R": KEY_R, "KEY_7": KEY_7, "KEY_8": KEY_8, "KEY_9": KEY_9, "KEY_F8": KEY_F8}.get(k, KEY_NONE)
		if not InputMap.has_action(bound[k]) or not InputMap.action_has_event(bound[k], e):
			unbound.append(k)
	check("D5 every action row's key is bound to its InputMap action %s" % [unbound], unbound.is_empty() and bound.size() >= 10)
	var unhandled := Array(CameraDirector.ACTIONS.keys()).filter(func(a: String) -> bool: return not body.contains('"%s"' % a))
	check("D5 the demo handles every camera action by name %s" % [unhandled], unhandled.is_empty())
	var untabled := Array(CameraDirector.ACTIONS.keys()).filter(func(a: String) -> bool: return not bound.values().has(a))
	check("D5 every camera action has a control-table row %s" % [untabled], untabled.is_empty())
	check("D7 the player help names no mouse look; the developer help names F8", not ShipControls.help_text(false).to_lower().contains("mouse to look") and not ShipControls.help_text(false).contains("F8") and ShipControls.help_text(true).contains("F8"))


func new_demo(opts: Dictionary) -> Node:
	var demo: Node = load("res://demos/ship_geometry_demo.tscn").instantiate()
	var o := {"stars": false, "background": false}
	o.merge(opts, true)
	demo.setup_options = o
	root.add_child(demo)
	await process_frame
	demo.auto = false
	demo.journey_auto_tick = false
	return demo


static func digit_free(s: String) -> bool:
	for c in s:
		if c >= "0" and c <= "9":
			return false
	return true


## AC1/AC2 in one scene state.
func strip_ok(demo: Node, state: String) -> void:
	demo._process(0.016)
	var hud: ShipHud = demo.ship_hud
	var view: Dictionary = demo.hud_view()
	var ship: Dictionary = view.get("ship", {})
	check("AC1 %s: strip visible" % state, hud.strip.is_visible_in_tree())
	check("AC1 %s: ship clock = clock.tau formatted (%s)" % [state, hud.ship_clock.text], hud.ship_clock.text == DisplayBinding.format_field(view, "clock.tau", "dur_yr") and hud.ship_clock.text != "-")
	check("AC1 %s: home clock = clock.year formatted (%s)" % [state, hud.home_clock.text], hud.home_clock.text == DisplayBinding.format_field(view, "clock.year", "dur_yr") and hud.home_clock.text != "-")
	check("AC1 %s: distance shown (%s)" % [state, hud.distance.text], not hud.distance.text.is_empty() and hud.distance.visible and hud.distance.text == str(view.hud.distance))
	check("AC1 %s: where shown (%s)" % [state, hud.where.text], not hud.where.text.is_empty())
	check("AC1 %s: captions digit-free" % state, digit_free(hud.ship_cap.text) and digit_free(hud.home_cap.text))
	check("AC1 %s: every HUD number is a clean binding" % state, DisplayBinding.audit(hud).is_empty())
	check("AC2 %s: clocks the same size" % state, hud.ship_clock.get_theme_font_size("font_size") == hud.home_clock.get_theme_font_size("font_size"))
	var moving := float(ship.get("beta", 0.0)) > 0.0
	check("AC2 %s: speed shown only while moving (beta %s)" % [state, ship.get("beta", 0.0)], hud.speed.visible == moving)
	if moving:
		check("AC2 %s: the sim emits one_minus_beta" % state, ship.has("one_minus_beta"))
		check("AC2 %s: speed formatted from the sim fields" % state, hud.speed.text == Demo.speed_text(ship))


func cards_clear_centre(hud: ShipHud, label: String) -> void:
	for sz in [Vector2(960, 540), Vector2(1280, 720), Vector2(2560, 1440), Vector2(640, 360)]:
		hud.size = sz
		hud._layout()
		var ok := true
		for id: String in hud.cards:
			var p: Control = hud.cards[id].panel
			var x0: float = hud.column.position.x
			var w: float = maxf(hud.card_width(), p.get_combined_minimum_size().x)
			if x0 < sz.x * 2.0 / 3.0 or x0 + w > sz.x + 0.5:
				ok = false
		check("AC3 %s: no card over the centre third at %s" % [label, sz], ok)


func arrive(demo: Node, phases: Dictionary) -> void:
	for i in 4000:
		if not demo.live_journey:
			break
		demo.journey_tick()
		var p: String = demo.sky_world.ship.phase
		if not phases.has(p):
			phases[p] = true
			demo._process(0.016)
			if p == "cruising":
				strip_ok(demo, "cruise")
			elif p == "braking":
				strip_ok(demo, "brake")
				check("AC3 brake notice appears at brake entry", demo.ship_hud.has_card("notice") and demo.ship_hud.all_text().contains("Braking"))
				demo._process(8.7)
				check("AC3 brake notice leaves after its 8 s", not demo.ship_hud.has_card("notice"))
			elif p == "approaching":
				check("AC3 final-approach notice appears", demo.ship_hud.has_card("notice") and demo.ship_hud.all_text().contains("Final approach"))


func test_archive_label_identity(demo: Node) -> void:
	var saved: Dictionary = demo.sky_world
	var cases: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/display_audit/archive_text_identity.json"))
	for c: Dictionary in cases:
		demo.sky_world = {"consequence": {"archive": {"unlocked": c.unlocked}}}
		demo.consoles._refresh_screens()
		var label: Label = demo.consoles.screens.archive.label
		check("7ia Archive old exact text %s" % c.text, label.text == c.text and demo.consoles.screen_text("archive") == c.text)
		check("7ia Archive is a clean binding", label is ComposedBinding and DisplayBinding.audit(demo.consoles.screens.archive.viewport).is_empty())
		if label is ComposedBinding:
			var recorded: Dictionary = JSON.parse_string(SimBridge.encode(label._last_view))
			var replayed := ComposedBinding.new().compose(label.parts)
			replayed.update_from(recorded)
			check("7ia Archive reconstructs after JSON number conversion", replayed.text == c.text)
			replayed.free()
	demo.sky_world = saved
	demo.consoles._refresh_screens()


func test_strip_and_cards() -> void:
	var demo: Node = await new_demo({"live_start": true, "sky_state": "rest"})
	test_archive_label_identity(demo)
	var hud: ShipHud = demo.ship_hud
	check("HUD built, the button column retired", hud != null and demo.hud == hud.strip and not demo.has_method("hud_text"))
	strip_ok(demo, "rest")
	check("rest: no cards", hud.cards.is_empty())
	# The medium I card uses exactly the star inspector's empty-sky fallback.
	demo.journey_sim.record_sent = true
	var before_intents: int = demo.journey_sim.sent_log.size()
	demo.toggle_sky_only()
	demo.look_direction("forward")
	var centre: Vector2 = hud.size * 0.5
	demo.star_identification.set_held(true)
	demo.star_identification.update_candidates()
	var empty_open:=false
	# The playable start is now beside Earth: the centre ray can hit a body.
	for y:float in [.1,.25,.4,.55,.7,.85,.95]:
		for x:float in [.05,.2,.35,.5,.65,.8,.95]:
			var point:Vector2=hud.size*Vector2(x,y)
			if not empty_open and demo.show_medium_at(point):centre=point;empty_open=true
	check("AC17 actual empty forward sky opens the medium I card", empty_open and hud.has_card("medium_here"))
	demo._process(0.5)
	check("AC17 I card uses the actual sim medium/density", hud.all_text().contains("Local Interstellar Cloud") and hud.all_text().contains(IsmHud.density_text(float(demo.sky_world.ship.ism.n_h_cm3))))
	check("AC17 medium display sends no simulation intent", demo.journey_sim.sent_log.size() == before_intents)
	demo.star_identification.candidates = [{"id": "existing-star", "point": centre}]
	check("AC17 star pick wins over medium I fallback", not demo.show_medium_at(centre))
	demo.star_identification.set_held(false)
	demo.look_direction("aft")
	check("AC17 aft sky does not open medium card", not demo.show_medium_at(centre))
	demo.escape()
	demo._process(0.7)
	check("AC17 Esc closes medium I card", not hud.has_card("medium_here"))
	demo.toggle_sky_only()
	demo.set_preset("reset")
	# A free-navigation commit (the navigation map; the helm in R1-SHIP-UI U4).
	demo.journey_sim.record_sent = true
	demo.open_navigation()
	var committed: bool = demo.journey_map.open_commit_dialog() and demo.journey_map.hold_commit(GalaxyMap.HOLD_S) and demo.journey_tick()
	check("a journey commits", committed and demo.live_journey)
	var log: Array = demo.journey_sim.sent_log
	check("U0 seam: the commit line is recorded with source player", log.any(func(e: Dictionary) -> bool: return e.source == "player" and e.intents.any(func(i: Dictionary) -> bool: return i.get("k", "") == "commit")))
	demo.journey_tick()
	check("U0 seam: an empty tick is recorded with source tick", demo.journey_sim.sent_log.back().source == "tick" and demo.journey_sim.sent_log.back().intents.is_empty())
	demo.close_navigation()
	demo._process(0.016)
	strip_ok(demo, "boost")
	check("AC3 transit card appears on commit", hud.has_card("transit"))
	var transit_fields: Array = hud.card_body("transit").find_children("*", "DisplayBinding", true, false).map(func(b): return b.field)
	check("AC3 transit card: compact JourneyHud rows %s" % [transit_fields], transit_fields.has("ship.phase") and transit_fields.has("consequence.gap_years") and transit_fields.has("client.warp") and transit_fields.filter(func(f): return f in ShipHud.TRANSIT_COMPACT).size() == ShipHud.TRANSIT_COMPACT.size())
	check("AC17 real protocol-2.8 world populates transit medium rows", demo.journey_sim.hello_reply.proto.minor == SimBridge.HOME_TIERS_MINOR and demo.journey_sim.world.ship.ism.model == "lism-1" and transit_fields.has("ship.ism.medium") and transit_fields.has("ship.ism.n_h_cm3"))
	check("Tab holds every JourneyHud row", hud.transit_rows.find_children("*", "DisplayBinding", true, false).size() == JourneyHud.ROWS.size())
	var phases := {}
	await arrive(demo, phases)
	demo._process(0.016)
	check("journey arrived through every phase %s" % [phases.keys()], demo.journey_map.journey_state() == "arrived" and phases.has("braking"))
	strip_ok(demo, "arrived")
	check("AC3 transit card leaves at arrival", not hud.has_card("transit"))
	check("AC3 arrival card appears at arrival", hud.has_card("arrival"))
	var arrival_fields: Array = hud.card_body("arrival").find_children("*", "DisplayBinding", true, false).map(func(b): return b.field)
	check("AC3 arrival card: the M4.3a rows", arrival_fields == ArrivalCard.ROWS.map(func(r): return r[1]))
	demo.refuse("Finish the committed journey first.")
	demo._process(0.5)
	check("AC3 refusal card appears verbatim", hud.has_card("refusal") and hud.all_text().contains("Finish the committed journey first."))
	cards_clear_centre(hud, "arrival + refusal")
	demo._process(8.0)
	check("AC3 refusal leaves after 8 s; arrival stays until dismissed", not hud.has_card("refusal") and hud.has_card("arrival"))
	demo.escape()
	demo._process(0.7)
	check("AC3 Esc dismisses the arrival card (and it is freed after the fade)", not hud.cards.has("arrival"))
	# Guided voyage: dwell, the tour card and its pacing buttons.
	check("the guided voyage starts", demo.start_solar_departure())
	# R2-INTERLUDE ruling 4: a new guided voyage with crew sends critical_only before its first commit.
	var orders_queued: bool = demo.journey_sim.queued.any(func(i: Dictionary) -> bool: return i.get("k", "") == "crew_orders" and JSON.parse_string(i.line) == {"command": "orders", "preset": "critical_only"})
	check("ruling 4: the guided voyage with crew queues crew_orders critical_only before its first commit", not demo.journey_sim.crew.is_empty() and orders_queued and demo.journey_sim.world.journey.state != "committed")
	demo._process(0.016)
	strip_ok(demo, "tour dwell")
	check("AC3 tour card appears with Pause / Skip dwell / Skip stage", hud.has_card("tour") and hud.card_body("tour").get_node("Buttons").get_child_count() == 3)
	demo.toggle_tour_pause()
	demo._process(0.016)
	check("P pauses: the tour card says PAUSED", demo.solar_tour.paused and hud.all_text().contains("PAUSED"))
	demo.toggle_tour_pause()
	for i in 80:
		demo._process(0.05) # the arrival attitude turn (3 s) holds the tour
	demo.journey_sim.record_sent = true
	check("Skip dwell brings the itinerary's next leg forward", demo.skip_dwell() and demo.solar_tour.pending_index == 0)
	check("U0 seam: the itinerary's own plan is recorded with source tour", demo.journey_sim.sent_log.size() == 1 and demo.journey_sim.sent_log[0].source == "tour" and demo.journey_sim.sent_log[0].intents[0].k == "plan")
	for i in 100:
		if demo.live_journey:
			break
		demo._process(0.05) # the departure turn, then the tour commits its own leg
	check("the tour commits the itinerary's leg after its turn", demo.live_journey)
	check("ruling 4: the committed guided leg runs critical_only auto-run", demo.journey_sim.crew.get("auto", "") == "critical_only")
	# The interlude state: the tour's D-41 card over a committed leg (driven directly; the
	# host loop that reaches it is tests/test_solar_departure.gd's).
	var card := CardInterlude.new()
	card.begin(CruiseInterlude.facts_from(demo.journey_sim.world, demo.solar_tour.leg_name()))
	demo.solar_tour.interlude = card
	demo._show_interlude()
	demo._process(0.5)
	var interlude: bool = demo.crossing_review.visible
	strip_ok(demo, "interlude")
	check("AC3 interlude chip in the stack while the crossing review shows", demo.ship_hud.has_card("interlude"))
	check("AC3 at most two cards expanded %s" % [hud.expanded()], hud.expanded().size() <= ShipHud.MAX_EXPANDED)
	cards_clear_centre(hud, "tour + transit + interlude")
	# The D-41 interlude card is the one exemption from the centre third (AC3 note): it keeps
	# clear of the status strip and of the card column.
	for sz in [Vector2(960, 540), Vector2(1280, 720), Vector2(2560, 1440)]:
		hud.size = sz
		hud._layout()
		demo._place_interlude()
		var r := Rect2(demo.crossing_review.position, demo.crossing_review.get_combined_minimum_size().max(demo.crossing_review.size))
		check("AC3 crossing review clear of the strip and the column at %s (%s)" % [sz, r], r.position.y >= hud.strip_bottom() and r.end.x <= hud.column.position.x)
	demo.solar_tour.interlude = null
	demo._show_interlude()
	demo._process(0.7)
	check("AC3 interlude chip leaves with the interlude", not hud.has_card("interlude"))
	check("a cruise interlude was reached", interlude)
	# Sgr A*: the gravity card replaces the tour; the home clock is the far-away clock.
	check("Sgr A* is refused while the tour's leg is committed (refusal card)", not demo.start_black_hole() and demo.ship_hud.has_card("refusal"))
	for i in 200:
		if not demo.live_journey:
			break
		demo.skip_stage() # K: pacing to the leg's end
		demo.journey_tick()
	demo._process(0.016)
	check("Sgr A* starts once the leg is done", demo.start_black_hole())
	demo._process(0.7)
	strip_ok(demo, "Sgr A*")
	check("AC3 gravity card appears at Sgr A*", hud.has_card("gravity"))
	check("AC3 tour card leaves with the tour", not hud.cards.has("tour"))
	check("Sgr A*: home clock captioned far-away", hud.home_cap.text.contains("far-away") and hud.distance.text.begins_with("r = "))
	var lines := BlackHoleVisit.hud_lines(demo.black_hole.gr())
	check("gravity card shows the sim's lines", Array(lines).all(func(l: String) -> bool: return hud.all_text().contains(l)))
	var before: int = demo._unlocked_seen.size()
	demo.bh_next_stop()
	demo.bh_finish_approach()
	demo._process(0.5)
	check("AC3 Archive unlock card appears when consequence.archive.unlocked grows", demo._unlocked_seen.size() > before and hud.has_card("unlock") and hud.all_text().contains("at the Archive terminal"))
	check("AC3 priority: gravity above unlock", hud.ordered().find("gravity") < hud.ordered().find("unlock"))
	demo.refuse("Approach under way.")
	demo.note("A notice.")
	demo._process(0.5)
	check("AC3 four cards: two expanded, the rest collapsed chips %s" % [hud.ordered()], hud.cards.size() >= 4 and hud.expanded() == hud.ordered().slice(0, 2) and hud.expanded() == ["refusal", "gravity"])
	cards_clear_centre(hud, "four cards")
	demo._process(10.5)
	check("AC3 unlock card leaves after 10 s", not hud.has_card("unlock"))
	demo.leave_black_hole()
	demo._process(0.7)
	check("AC3 gravity card leaves on leaving", not hud.cards.has("gravity"))
	# Lower deck.
	demo.set_preset("reset")
	demo.lift.board()
	demo.lift.advance(0.81); demo.lift.advance(11.01); demo.lift.advance(0.81)
	demo._process(0.016)
	strip_ok(demo, "lower deck")
	check("lower deck: the prompt says decisions need the bridge", demo.active_level == 1 and (hud.prompt.text.contains("bridge")))
	demo.queue_free()
	await process_frame


func test_dev_gating() -> void:
	var menu: Node = await new_demo({"live_start": true, "sky_state": "rest", "from_menu": true, "settings_dir": "user://test_ship_ui"})
	DirAccess.make_dir_recursive_absolute("user://test_ship_ui")
	check("AC11 menu launch: developer controls absent", not menu.ship_hud.dev_box.visible and not menu.ship_hud.help.text.contains("Developer"))
	var guides: bool = menu.guides.visible
	var state: String = menu.sky_state
	for k in [KEY_G, KEY_5, KEY_6, KEY_B]:
		var e := InputEventKey.new()
		e.physical_keycode = k
		e.pressed = true
		menu._unhandled_input(e)
	check("AC11 menu launch: G, 5 and 6 do nothing; B only measures (frame check), changing no state", menu.guides.visible == guides and menu.sky_state == state and not menu.benchmark.running)
	check("menu launch: Main menu button in the strip corner", menu.menu_button.visible and menu.menu_button.get_parent() == menu.ship_hud.corner)
	menu.queue_free()
	await process_frame
	var cli: Node = await new_demo({"sky_state": "rest"})
	check("AC11 command-line launch: developer controls present", cli.ship_hud.dev_box.visible and cli.ship_hud.help.text.contains("Developer"))
	var e2 := InputEventKey.new()
	e2.physical_keycode = KEY_G
	e2.pressed = true
	cli._unhandled_input(e2)
	check("AC11 command-line launch: G toggles guides", cli.guides.visible)
	cli.queue_free()
	await process_frame


## §A3 the dwell label: the I card's own pick, read only, named with its distance.
func test_dwell() -> void:
	var demo: Node = load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options = {"background": false, "live_start": true, "sky_state": "rest"}
	root.add_child(demo)
	await process_frame
	demo.auto = false
	demo.journey_auto_tick = false
	demo.look_direction("forward")
	await process_frame
	var ident = demo.star_identification
	ident.set_held(true)
	ident.update_candidates()
	var stars: Array = ident.candidates.filter(func(c): return not c.has("body") and ident.at_point(c.point).size() == 1 and ident.info.names.has(c.id))
	ident.set_held(false)
	check("dwell: the forward view has named stars (%d)" % stars.size(), not stars.is_empty())
	var unnamed: Array = ident.candidates.filter(func(c): return not c.has("body") and ident.at_point(c.point).size() == 1 and not ident.info.names.has(c.id))
	if not unnamed.is_empty():
		check("dwell: an unnamed catalogue row gets no label (the I card's job)", demo.dwell_text_at(unnamed[0].point) == "")
	if not stars.is_empty():
		var c: Dictionary = stars[0]
		var t: String = demo.dwell_text_at(c.point)
		check("dwell label names the star with its distance and I details (%s)" % t, t.begins_with(ident.info.display_name(c.id)) and (t.contains(" ly") or t.contains(" AU")) and t.ends_with("I details"))
		check("dwell probe leaves no I hold behind", not ident.held and ident.candidates.is_empty() and not ident.card.visible)
	demo._process(0.3)
	demo._process(0.3)
	check("dwell: the view at rest 0.5 s runs the pick once", demo._dwell_done)
	demo.camera.yaw += 0.4
	demo._process(0.016)
	check("dwell: moving the view clears the label", not demo._dwell_done and not demo.ship_hud.dwell.visible)
	var hud: ShipHud = demo.ship_hud
	hud.size = Vector2(960, 540)
	hud.set_dwell("Alpha Centauri A · 4.32 ly · I details and a long tail of text", Vector2(700, 300))
	hud.update(demo.hud_view())
	check("dwell label stays clear of the card column (%s)" % [hud.dwell.get_rect()], hud.dwell.position.x + hud.dwell.get_combined_minimum_size().x <= hud.column.position.x)
	hud.set_dwell("", Vector2.ZERO)
	demo.dwell_on = false
	demo._process(0.6)
	check("dwell: the Tab toggle turns it off", not demo.ship_hud.dwell.visible)
	demo.queue_free()
	await process_frame

## R2-CAMERA D7 (supersedes the Oct10 free mouse look for players): the player camera has no look,
## the pointer is never captured, and UI surfaces still own it; the developer free camera (F8) keeps
## today's look, with right-drag / Alt while a panel needs the pointer.
func test_mouse_look() -> void:
	var demo: Node = await new_demo({})
	check("the pointer seam exists", demo.has_method("pointer_required") and demo.has_method("free_camera_on"))
	if not demo.has_method("free_camera_on"):
		demo.queue_free();await process_frame;return
	check("player camera: no capture (the pointer is always visible)", not demo.wants_capture() and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE)
	check("closed bridge view needs no visible cursor for a panel", not demo.pointer_required())
	var motion := InputEventMouseMotion.new();motion.relative=Vector2(10,5)
	var pose: Transform3D = demo.camera.global_transform
	demo._unhandled_input(motion)
	check("player camera: mouse motion never turns the view", demo.camera.global_transform.is_equal_approx(pose))
	demo.toggle_controls()
	check("Tab still owns the pointer for its buttons", demo.pointer_required() and Input.mouse_mode==Input.MOUSE_MODE_VISIBLE)
	demo.escape()
	check("Esc closes Tab", not demo.pointer_required())
	demo.star_identification.set_held(true)
	check("I inspection owns the pointer", demo.pointer_required())
	demo.star_identification.set_held(false)
	# dev.31 (Mark): after arriving nothing said the game waited for Enter. R2-CAMERA: the line
	# names the key only (players have no look to name).
	demo.ship_hud.show_card("arrival","Arrived")
	demo._sync_pointer()
	check("arrival card: no pointer needed and nothing captured", not demo.pointer_required() and not demo.wants_capture())
	demo._update_wait_hint() # (a _process here would reset this demo's HUD session: no sim, so the card goes)
	check("arrival card: one centred line says the game waits for Enter, no look named (%s)" % demo.wait_hint.text, demo.wait_hint.visible and demo.wait_hint.text == "Press Enter to continue")
	demo.dismiss_arrival()
	demo._update_wait_hint()
	check("dismissed arrival: the waiting line goes", not demo.pointer_required() and not demo.wait_hint.visible)
	demo.crossing_review.visible = true
	check("the crossing review needs the pointer", demo.pointer_required())
	var right := InputEventMouseMotion.new();right.relative=Vector2(10,5);right.button_mask=MOUSE_BUTTON_MASK_RIGHT
	var alt := InputEventMouseMotion.new();alt.relative=Vector2(10,5);alt.alt_pressed=true
	pose = demo.camera.global_transform
	demo._unhandled_input(right);demo._unhandled_input(alt)
	check("review, player camera: right-drag and Alt+move do not turn the view", demo.camera.global_transform.is_equal_approx(pose))
	demo.crossing_review.visible = false
	# The developer free camera (command-line launch): today's look.
	demo.set_free_camera(true)
	Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
	var yaw:float=demo.camera.yaw;var tilt:float=demo.camera.tilt
	demo._unhandled_input(motion)
	check("free camera: unmodified mouse turns the view", not is_equal_approx(yaw,demo.camera.yaw) and not is_equal_approx(tilt,demo.camera.tilt))
	check("free camera: it wants the mouse captured when no panel needs it", demo.wants_capture())
	demo.toggle_controls()
	check("free camera: Tab releases the pointer to buttons", demo.pointer_required() and Input.mouse_mode==Input.MOUSE_MODE_VISIBLE)
	yaw=demo.camera.yaw;demo._unhandled_input(motion)
	check("free camera: UI pointer motion never turns the view", is_equal_approx(yaw,demo.camera.yaw))
	demo.escape()
	demo.crossing_review.visible = true
	yaw=demo.camera.yaw;demo._unhandled_input(motion)
	check("free camera review: a plain mouse move does not turn the view (it is the pointer)", is_equal_approx(yaw,demo.camera.yaw))
	yaw=demo.camera.yaw;demo._unhandled_input(right)
	check("free camera review: a right-drag turns the view", not is_equal_approx(yaw,demo.camera.yaw))
	yaw=demo.camera.yaw;demo._unhandled_input(alt)
	check("free camera review: Alt + move turns the view (trackpads)", not is_equal_approx(yaw,demo.camera.yaw))
	demo.crossing_review.visible = false
	demo.queue_free();await process_frame
	check("leaving ship releases pointer", Input.mouse_mode==Input.MOUSE_MODE_VISIBLE)


## dev.31 (Mark): the guided voyage's final leg (Aldebaran), flown as the player flies it, to its
## crossing review and its arrival: look works through both, and the waiting line says what to press.
const ReviewDrive := preload("res://tests/review_drive.gd")
func test_final_leg_look() -> void:
	var demo: Node = await new_demo({"live_start": true, "sky_state": "rest", "crew": "orders"})
	check("final leg: the guided voyage begins at Aldebaran's leg", ReviewDrive.begin(demo, 6))
	var state := ReviewDrive.reach(demo, false)
	var r: CrossingReview = demo.crossing_review
	check("final leg: the crossing reaches its review (%s)" % state, state == "crossed" and r.visible)
	if state != "crossed":
		demo.queue_free();await process_frame;return
	demo._process(0.016)
	check("final leg review: the waiting line names Enter and no mouse look (%s)" % demo.wait_hint.text, demo.wait_hint.visible and demo.wait_hint.text.contains("Enter") and not demo.wait_hint.text.contains("look"))
	# Coordinator review of #277: the console prompt ("Voyage console · E use") was drawn over the waiting
	# line at the bottom centre while the review was open. While the review is open the prompt is hidden,
	# and no two visible bottom hints intersect.
	var pr: Label = demo.ship_hud.prompt
	var prompt_shown := pr.is_visible_in_tree() and pr.text != ""
	check("final leg review: no console prompt while the review is open (%s)" % pr.text, not prompt_shown)
	check("final leg review: the prompt and the waiting line never overlap", not prompt_shown or not pr.get_global_rect().intersects(demo.wait_hint.get_global_rect()))
	check("final leg review: the player's pointer is visible for the review (never captured)", demo.pointer_required() and not demo.wants_capture())
	check("C2 interlude hold: the camera holds Sky forward behind the review (%s, hold %s)" % [demo.director.situation, demo.director.hold], demo.director.hold and demo.director.situation == "sky_forward")
	var k2 := InputEventKey.new();k2.physical_keycode = KEY_2;k2.pressed = true
	demo._unhandled_input(k2)
	check("C2 interlude hold: a level key does not move it while the review is open", demo.director.situation == "sky_forward")
	r.go(r.page_ids().size() - 1)
	r.key(KEY_ENTER) # Brake
	for i in 8000:
		if str(demo.journey_sim.world.journey.state) == "arrived" and demo.ship_hud.has_card("arrival"): break
		if ReviewDrive.frame(demo, true) == "failed": break
	check("final leg: arrived, the arrival card up", demo.ship_hud.has_card("arrival"))
	check("final leg arrival: the Dismiss button is not folded away %s" % [demo.ship_hud.expanded()], demo.ship_hud.expanded().has("arrival"))
	demo.dismiss_arrival()
	check("final leg: the voyage ends with the pointer free and nothing captured (clicks reach the consoles)", not demo.pointer_required() and not demo.wants_capture() and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE)
	demo.queue_free()
	await process_frame
