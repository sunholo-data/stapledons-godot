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
	test_control_table()
	await test_strip_and_cards()
	await test_dev_gating()
	print("ship-ui: %d passed, %d failures" % [passes, failures])
	quit(1 if failures else 0)


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
	check("AC7 source has a key match (%d keys)" % code.size(), code.size() >= 20)
	var missing_in_table := Array(code).filter(func(k: String) -> bool: return not table.has(k))
	var missing_in_code := Array(table).filter(func(k: String) -> bool: return not code.has(k))
	check("AC7 every key the demo matches is a table row %s" % [missing_in_table], missing_in_table.is_empty())
	check("AC7 every matched table row is matched by the demo %s" % [missing_in_code], missing_in_code.is_empty())
	var kinds := ["display", "pacing", "camera", "move", "dev", "console"]
	check("AC7 every row has a §F kind", ShipControls.KEYS.all(func(r: Dictionary) -> bool: return r.kind in kinds))
	check("AC7 every console row names a station", ShipControls.CONSOLE.all(func(r: Dictionary) -> bool: return r.station in ["navigation", "voyage", "archive"]))
	check("AC7 display controls (V J I Tab H Esc M-chart and the camera keys) are never console", ["KEY_V", "KEY_J", "KEY_I", "KEY_TAB", "KEY_H", "KEY_ESCAPE", "KEY_1", "KEY_R", "KEY_7"].all(func(k: String) -> bool: return ShipControls.row(k).kind != "console"))
	check("Tab help groups the controls", ShipControls.help_text(false).contains("Display:") and not ShipControls.help_text(false).contains("Developer:") and ShipControls.help_text(true).contains("Developer:"))


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


func test_strip_and_cards() -> void:
	var demo: Node = await new_demo({"live_start": true, "sky_state": "rest"})
	var hud: ShipHud = demo.ship_hud
	check("HUD built, the button column retired", hud != null and demo.hud == hud.strip and not demo.has_method("hud_text"))
	strip_ok(demo, "rest")
	check("rest: no cards", hud.cards.is_empty())
	# A free-navigation commit (the navigation map; the helm in R1-SHIP-UI U4).
	demo.open_navigation()
	var committed: bool = demo.journey_map.open_commit_dialog() and demo.journey_map.hold_commit(GalaxyMap.HOLD_S) and demo.journey_tick()
	check("a journey commits", committed and demo.live_journey)
	demo.close_navigation()
	demo._process(0.016)
	strip_ok(demo, "boost")
	check("AC3 transit card appears on commit", hud.has_card("transit"))
	var transit_fields: Array = hud.card_body("transit").find_children("*", "DisplayBinding", true, false).map(func(b): return b.field)
	check("AC3 transit card: compact JourneyHud rows %s" % [transit_fields], transit_fields.has("ship.phase") and transit_fields.has("consequence.gap_years") and transit_fields.has("client.warp") and transit_fields.size() == ShipHud.TRANSIT_COMPACT.size())
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
	demo._process(0.016)
	strip_ok(demo, "tour dwell")
	check("AC3 tour card appears with Pause / Skip dwell / Skip stage", hud.has_card("tour") and hud.card_body("tour").get_node("Buttons").get_child_count() == 3)
	demo.toggle_tour_pause()
	demo._process(0.016)
	check("P pauses: the tour card says PAUSED", demo.solar_tour.paused and hud.all_text().contains("PAUSED"))
	demo.toggle_tour_pause()
	for i in 80:
		demo._process(0.05) # the arrival attitude turn (3 s) holds the tour
	check("Skip dwell brings the itinerary's next leg forward", demo.skip_dwell() and demo.solar_tour.pending_index == 0)
	for i in 100:
		if demo.live_journey:
			break
		demo._process(0.05) # the departure turn, then the tour commits its own leg
	check("the tour commits the itinerary's leg after its turn", demo.live_journey)
	# The interlude state: the tour's D-41 card over a committed leg (driven directly; the
	# host loop that reaches it is tests/test_solar_departure.gd's).
	var card := CardInterlude.new()
	card.begin(CruiseInterlude.facts_from(demo.journey_sim.world, demo.solar_tour.leg_name()))
	demo.solar_tour.interlude = card
	demo._show_interlude()
	demo._process(0.5)
	var interlude: bool = demo.interlude_card.visible
	strip_ok(demo, "interlude")
	check("AC3 interlude chip in the stack while the D-41 card shows", demo.ship_hud.has_card("interlude"))
	check("AC3 at most two cards expanded %s" % [hud.expanded()], hud.expanded().size() <= ShipHud.MAX_EXPANDED)
	cards_clear_centre(hud, "tour + transit + interlude")
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
	check("AC11 menu launch: B, G, 5 and 6 do nothing", menu.guides.visible == guides and menu.sky_state == state and not menu.benchmark.running)
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
