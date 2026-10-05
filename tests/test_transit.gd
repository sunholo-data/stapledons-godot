extends SceneTree
## M4.3a headless test (design m4-first-journey M4.3, sprint M4.3a): the transit clock, the HUD
## and the arrival card over the real sim on the sky-only harness.
##   warp: 0.01 default, recorded as an intent, changeable only while committed
##   dtau: each burn phase spans 3 s of real time whatever its length in ship time
##   HUD: every number is a DisplayBinding; a hand-set number fails the audit (positive control)
##   phases: boost -> cruise -> brake -> arrival, no flip or turnover event, brake = legacy entry + notice
##   stand-off: the client sends standoff_au 1000 (D-14)
## Run:  godot --headless --path . --script tests/test_transit.gd
## `make transit-test` requires the summary line, because a parse error exits 0.

const LOG := "user://test_transit_input.ndjson"
const SESSION_LOG := "res://tests/replays/m4_transit_harness.ndjson"

var failures := 0
var checks := 0


func ok(name: String, cond: bool) -> void:
	checks += 1
	if not cond: failures += 1
	print("  %s  %s" % ["ok  " if cond else "FAIL", name])


func harness(params: Dictionary, record: String = "") -> TransitHarness:
	var sim := SimBridge.new()
	sim.want_minor = 2
	sim.record_path = record
	if not sim.start() or not sim.new_game(0, "sol", false, params):
		ok("sim session starts (%s)" % sim.last_error, false)
		return null
	var h := TransitHarness.new()
	root.add_child(h)
	h.attach(sim)
	return h


func lines_of(path: String) -> Array:
	var out: Array = []
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return out
	while not f.eof_reached():
		var l := f.get_line()
		if l != "":
			out.append(JSON.parse_string(l))
	return out


func warp_levels(log: Array) -> Array:
	var out: Array = []
	for m in log:
		if m.get("type") == "input":
			for i in m["intents"]:
				if i["k"] == "warp":
					out.append([int(m["tick"]), i["level"]])
	return out


func test_warp(h: TransitHarness, res: Dictionary, log: Array) -> void:
	var t := Transit.new()
	ok("warp levels are 0.002 / 0.01 / 0.05, default 0.01", Transit.WARP_LEVELS == [0.002, 0.01, 0.05] and t.warp == 0.01 and Transit.WARP_DEFAULT == 0.01)
	ok("no warp request before a commit (idle world)", not t.request_warp(0.05, {"journey": {"state": "planned"}}))
	ok("a warp request while committed is taken", t.request_warp(0.05, {"journey": {"state": "committed"}}))
	ok("an unknown level is never taken", not Transit.new().request_warp(0.02, {"journey": {"state": "committed"}}))
	var w := warp_levels(log)
	ok("the log records the sim's refusal of a warp before the commit and after arrival", res["refusals"].filter(func(r): return r[1].has("not_committed")).size() == 2)
	ok("the default level 0.01 is the first committed warp intent, then 0.05 (2 accepted + 2 refused in the log)", w.size() == 4 and w[0][1] == 0.05 and w[1][1] == 0.01 and w[2][1] == 0.05 and w[3][1] == 0.01)
	ok("the 0.01 announcement rides the first tick after the commit tick (commit 8, warp 9)", w[0][0] == 6 and w[1][0] == 9)
	ok("the level in force at the end is 0.05; the client saw the sim accept it", h.transit.warp == 0.05)
	ok("cruise ticks at the default warp send dtau = 0.01 * real dt", res["cruise_dtau"].size() == 3 and res["cruise_dtau"].all(func(d): return d == 0.01 * TransitHarness.TICK_DT))


func test_pacing(res: Dictionary, label: String) -> void:
	for p in ["boosting", "braking"]:
		var n: int = res["phase_ticks"].get(p, 0)
		ok("%s: %s spans 3 s of real time (%d ticks of 0.05 s)" % [label, p, n], absf(n * TransitHarness.TICK_DT - 3.0) < 1e-9)


func test_phases(res: Dictionary) -> void:
	ok("phase sequence is boosting, cruising, braking", res["phases"] == ["boosting", "cruising", "braking"])
	var bad: Array = res["events"].filter(func(k): return k.contains("flip") or k.contains("turnover") or k.contains("turn"))
	ok("no flip or turnover event", bad.is_empty() and res["events"].count("phase") == 4 and res["events"].count("arrived") == 1)
	ok("the brake is a legacy entry (brake, then arrival, once each)", res["legacy"].count("brake") == 1 and res["legacy"].count("arrival") == 1 and res["legacy"].find("brake") < res["legacy"].find("arrival"))
	ok("the HUD shows a one-line brake notice, with no number in it", res["notice_in_brake"] and not DisplayBinding._has_digit(JourneyHud.BRAKE_NOTICE) and "\n" not in JourneyHud.BRAKE_NOTICE)


func labels(hud: JourneyHud) -> Dictionary:
	var out := {}
	for b in hud.bindings:
		out[b.field] = b.text
	return out


func test_hud(h: TransitHarness, res: Dictionary) -> void:
	var w: Dictionary = res["snap"]["cruising"]
	var v := w.duplicate()
	v["client"] = {"warp": 0.01}
	var hud: JourneyHud = load("res://ui/journey_hud.tscn").instantiate()
	root.add_child(hud)
	hud.show_world(v)
	var l := labels(hud)
	ok("beta to 4 dp, gamma to 3 dp", l["ship.beta"] == "%.4f c" % w["ship"]["beta"] and l["ship.gamma"] == "%.3f" % w["ship"]["gamma"] and l["ship.beta"].begins_with("0.99"))
	ok("tau and t are the sim's clocks", l["clock.tau"] == "%.4f yr" % w["clock"]["tau"] and l["clock.t"] == "%.4f yr" % w["clock"]["t"])
	ok("gap_years, distance left and Earth-years to arrival are the sim's fields", l["consequence.gap_years"] == "%.4f yr" % w["consequence"]["gap_years"] and l["consequence.distance_remaining"] == "%.3f ly" % w["consequence"]["distance_remaining"] and l["consequence.earth_years_remaining"] == "%.3f Earth-yr" % w["consequence"]["earth_years_remaining"])
	ok("ISM: load in W/m2 and suns, drag energy in J and kg, glow on", l["ship.ism.load_w_m2"].begins_with("2.2") and l["consequence.load_suns"] == "%.1f suns" % w["consequence"]["load_suns"] and l["ship.ism.drag_energy_j"] == GalaxyMap.format_value("sci J", w["ship"]["ism"]["drag_energy_j"]) and l["consequence.drag_energy_kg"] == "%.3f kg" % w["consequence"]["drag_energy_kg"] and l["ship.ism.glow_w_m2"] == "on")
	ok("phase and warp level are shown", l["ship.phase"] == "cruising" and l["client.warp"] == "0.010 ship-yr/s")
	ok("tau and t are side by side in one row, tau first, at the same size", hud.tau.get_parent() == hud.earth.get_parent() and hud.tau.get_index() < hud.earth.get_index() and hud.tau.get_theme_font_size("font_size") == hud.earth.get_theme_font_size("font_size") and hud.tau.get_theme_font_size("font_size") == JourneyHud.CLOCK_SIZE)
	ok("every numeric label is a DisplayBinding (audit finds nothing)", DisplayBinding.audit(hud).is_empty() and hud.bindings.size() == JourneyHud.CLOCKS.size() + JourneyHud.ROWS.size())
	var hand := Label.new()
	hand.text = "beta 0.9900"
	hud.add_child(hand)
	ok("positive control: a hand-set number label fails the audit", DisplayBinding.audit(hud) == [hand])
	hand.queue_free()
	hud.remove_child(hand)
	hud.tau.text = "0.62 yr"
	ok("positive control: a binding whose text was set by hand fails the audit", DisplayBinding.audit(hud) == [hud.tau])
	hud.show_world(v)
	ok("the next update restores it", DisplayBinding.audit(hud).is_empty())
	var rest := {"ship": {"phase": "at_rest", "beta": 0.0, "gamma": 1.0, "ism": {"glow_w_m2": 0}}}
	hud.show_world(rest)
	ok("glow reads off at rest; missing fields read as a dash, never a stale number", labels(hud)["ship.ism.glow_w_m2"] == "off" and labels(hud)["clock.tau"] == "-" and hud.notice.text == "")
	hud.queue_free()


func test_card(res: Dictionary) -> void:
	var w: Dictionary = res["snap"]["arrived"]
	var card: ArrivalCard = load("res://ui/arrival_card.tscn").instantiate()
	root.add_child(card)
	card.show_world(res["snap"]["cruising"])
	ok("the arrival card is hidden in flight", not card.visible)
	card.show_world(w)
	var p: Dictionary = w["journey"]["plan"]
	var texts := card.bindings.map(func(b): return b.text)
	ok("the card shows distance, ship years, Earth years and the gap, from the sim", card.visible and texts == ["%.3f ly" % p["distance"], "%.3f yr" % p["ship_years"], "%.3f yr" % p["earth_years"], "%.3f yr" % w["consequence"]["gap_years"]])
	ok("the card is all bindings", DisplayBinding.audit(card).is_empty())
	card.queue_free()


## D1: at arrival the card sits clear of the HUD (both were drawn at the top-left corner, unreadable).
func test_card_layout(h: TransitHarness) -> void:
	h.refresh()
	await process_frame
	await process_frame
	var c := h.card.get_global_rect()
	var u := h.hud.get_global_rect()
	ok("arrived: the card is visible and its rect (%s) does not overlap the HUD's (%s)" % [c, u], h.card.visible and h.hud.visible and c.size.x > 0.0 and not c.intersects(u))
	ok("the card is inside the viewport and its panel is opaque enough to read over the sky", Rect2(Vector2.ZERO, root.get_visible_rect().size).encloses(c) and (h.card.get_theme_stylebox("panel") as StyleBoxFlat).bg_color.a >= 0.9)


## F1: a refusal of the pending warp, matched by index, drops it; any other refusal does not.
func test_settle() -> void:
	var t := Transit.new()
	var w := {"journey": {"state": "committed"}}
	t.request_warp(0.05, w)
	t._pending_at = 1
	t.settle([{"i": 4}, {"i": 3}], 2) # index 2 + 1 = 3: refused
	ok("settle: a refusal at the pending intent's index keeps the old warp level", t.warp == Transit.WARP_DEFAULT and t._pending < 0.0)
	t.request_warp(0.05, w)
	t._pending_at = 1
	t.settle([{"i": 4}], 2)
	ok("settle: a refusal of some other intent does not stop the level changing", t.warp == 0.05)


func test_standoff(h: TransitHarness, res: Dictionary, log: Array) -> void:
	ok("the client's new_game params carry standoff_au 1000", Transit.new_game_params() == {"standoff_au": 1000.0} and Transit.STANDOFF_AU == 1000.0)
	var ng: Dictionary = log.filter(func(m): return m.get("type") == "new_game")[0]
	ok("the recorded new_game line has params.standoff_au 1000", ng.get("params") == {"standoff_au": 1000.0})
	var w: Dictionary = res["snap"]["boosting"]
	var d: float = w["journey"]["plan"]["distance"]
	var pos: Dictionary = TransitHarness.TARGET["pos"]
	var straight := sqrt(pos["x"] * pos["x"] + pos["y"] * pos["y"] + pos["z"] * pos["z"])
	ok("plan distance = target distance - 1,000 AU (the sim's standoff_ly 0.0158125)", absf(w["consequence"]["standoff_ly"] - 0.0158125) < 1e-7 and absf(d - (straight - w["consequence"]["standoff_ly"])) < 1e-5)
	ok("the interior run (main.gd) uses the same constant", load("res://main.gd").get_script_constant_map()["STANDOFF_AU"] == 1000.0)


## A script error inside _init leaves the tree running; the watchdog ends it with no summary line.
const WATCHDOG_S := 90.0
const EXPECTED_CHECKS := 43


func _init() -> void:
	create_timer(WATCHDOG_S).timeout.connect(func() -> void:
		print("transit: watchdog expired (a script error above?)")
		quit(2))
	var h := harness(Transit.new_game_params(), ProjectSettings.globalize_path(LOG))
	if h == null:
		quit(1)
		return
	var res := h.run_session()
	ok("the scripted session ran to arrival", res["ok"] and res["snap"].has("arrived") and h.sim.world["journey"]["state"] == "arrived")
	h.sim.stop()
	var log := lines_of(LOG)
	test_warp(h, res, log)
	test_pacing(res, "default boost")
	test_phases(res)
	test_hud(h, res)
	test_card(res)
	test_settle()
	await test_card_layout(h)
	test_standoff(h, res, log)
	ok("the committed replay session is this run's input log, byte for byte", FileAccess.get_file_as_string(LOG) == FileAccess.get_file_as_string(SESSION_LOG))
	# pacing is independent of the phase's ship time: 10x the boost length, the same 3 s
	var slow := harness({"standoff_au": Transit.STANDOFF_AU, "boost_g": 75000.0})
	if slow != null:
		var r2 := slow.run_session()
		var a: float = res["snap"]["boosting"]["journey"]["plan"]["boost_minutes"]
		var b: float = r2["snap"]["boosting"]["journey"]["plan"]["boost_minutes"]
		ok("the slow boost is 10x longer in ship time (%.2f vs %.2f min)" % [a, b], absf(b / a - 10.0) < 1e-6)
		test_pacing(r2, "75,000 g boost")
		slow.sim.stop()
	# a script error inside a check returns early and the run goes on: fewer checks than this is a failure
	ok("all %d checks ran" % EXPECTED_CHECKS, checks + 1 >= EXPECTED_CHECKS)
	print("transit: %d passed, %d failures" % [checks - failures, failures])
	quit(1 if failures > 0 else 0)
