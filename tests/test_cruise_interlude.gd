extends SceneTree
## RT3: the cruise-interlude seam and its demo card (D-41). Headless, no sim:
## the host loop is exercised for real in tests/test_solar_departure.gd.
var failures := 0
func check(ok: bool, label: String) -> void:
	print(("ok " if ok else "FAIL ") + label)
	if not ok: failures += 1

func world(year: float, tau: float, news: float, omb: float, gamma: float, dist: float) -> Dictionary:
	return {"journey": {"plan": {"target": {"id": "X"}, "cruise_beta": 1.0 - omb, "cruise_one_minus_beta": omb, "cruise_gamma": gamma, "distance": dist}},
		"clock": {"year": year, "tau": tau, "age": 30.0 + tau}, "consequence": {"news_age_years": news, "distance_remaining": dist * 0.5}}

func _initialize() -> void:
	# The base seam consumes nothing and is immediately done: a safe default.
	var base := CruiseInterlude.new()
	base.begin(CruiseInterlude.facts_from(world(4.3, 0.2, 4.3, 0.0001, 70.7, 41.8), "TRAPPIST-1"))
	check(base.advance(1.0, 0.05) == 0.0 and base.done(), "base interlude consumes nothing and is done")

	# Below 2.10 (no cruise section) the card hands over exactly the remaining cruise, once, then holds.
	var card := CardInterlude.new()
	var before := world(4.30980295176308, 0.1927134937008, 4.305, 0.0001, 70.7124459519056, 41.8)
	card.begin(CruiseInterlude.facts_from(before, "TRAPPIST-1"))
	var remaining := 0.5741234567
	check(card.advance(remaining, 0.05) == remaining, "below 2.10: first frame consumes exactly the remaining cruise")
	check(card.advance(remaining, 0.05) == 0.0 and card.advance(remaining, 0.05) == 0.0, "later frames consume nothing")
	check(card.done(), "with no reader (a headless host) the crossing is done at the braking boundary")
	# R2-INTERLUDE I3 (G1, AC7): with a reader the review is done only when the player brakes; no
	# timer ends it (600 s of frames leave it open).
	var read := CardInterlude.new(); read.awaits_reader = true; read.begin(card.facts)
	read.advance(remaining, 0.05)
	for i in int(600.0 / 0.05):
		read.advance(0.0, 0.05)
	check(read.crossed() and not read.done(), "with a reader, 600 s at the boundary leave the review open")
	read.finish()
	check(read.done(), "Brake (finish) ends it once the cruise was consumed")
	var unconsumed := CardInterlude.new(); unconsumed.awaits_reader = true; unconsumed.begin(card.facts); unconsumed.finish()
	check(not unconsumed.done(), "Brake cannot end a crossing that has not consumed the cruise")
	check(card.advance(-5.0, 0.05) == 0.0, "never consumes a negative amount")

	# 2.10 (R2-INTERLUDE I1): the crossing goes in chunks, each exactly the sim's next stop and never
	# more than next_stop_years or the cruise left; the braking stop ends it.
	var chunked := CardInterlude.new()
	var cw := before.duplicate(true)
	cw["cruise"] = {"next_stop_years": 0.0821355236139630, "stop_kind": "check_in"}
	chunked.begin(CruiseInterlude.facts_from(cw, "TRAPPIST-1"))
	var left := remaining
	var never_over := true
	var frames := 0
	var kinds := []
	while not chunked.crossed() and frames < 100:
		var stop: Dictionary = chunked.latest.cruise
		var step := chunked.advance(left, 0.05)
		never_over = never_over and step <= float(stop.next_stop_years) and step <= left and step >= 0.0
		kinds.append(stop.stop_kind)
		left -= step
		frames += 1
		# the sim's next stop after this chunk: a check-in a month on, or the braking boundary when nearer
		var month := 30.0 / 365.25
		cw["cruise"] = {"next_stop_years": minf(month, left), "stop_kind": "braking" if left <= month else "check_in"}
		chunked.observe(cw)
	check(never_over, "advance() never returns more than next_stop_years (nor the cruise left)")
	check(frames == 7 and kinds.count("check_in") == 6 and kinds.back() == "braking" and absf(left) < 1e-12, "a 0.574-year crossing is six check-ins and the braking stop (%d frames, %s, left %s)" % [frames, kinds, left])
	check(chunked.done() and chunked.advance(left, 0.05) == 0.0, "after the braking stop it consumes nothing (no reader: done at the boundary)")
	var mid := CardInterlude.new()
	mid.begin(CruiseInterlude.facts_from(cw, "TRAPPIST-1"))
	mid.latest.cruise = {"next_stop_years": 0.5, "stop_kind": "chunk"}
	check(mid.advance(0.25, 0.05) == 0.25 and mid.crossed(), "the cruise left caps a longer stop and ends the crossing")
	var mid2 := CardInterlude.new()
	mid2.begin(CruiseInterlude.facts_from(cw, "TRAPPIST-1"))
	mid2.latest.cruise = {"next_stop_years": 0.1, "stop_kind": "check_in"}
	mid2.finish()
	check(mid2.advance(0.25, 0.05) == 0.1 and not mid2.crossed() and not mid2.done(), "Brake cannot end a crossing that has not reached braking")
	check(mid2.progress_text() == "Crossing… the crew's monthly check-in.", "the Crossing… line follows the sim's stop kind: " + str(mid2.progress_text()))
	mid2.latest.cruise = {"next_stop_years": 0.3, "stop_kind": "chunk"}
	check(mid2.progress_text().begins_with("Crossing…") and mid2.progress_text() != "Crossing… the crew's monthly check-in.", "mutating stop_kind changes the Crossing… line")
	check(SimBridge.parse_cruise({"next_stop_years": 0.1, "stop_kind": "check_in"}) == {"next_stop_years": 0.1, "stop_kind": "check_in"} and SimBridge.parse_cruise({"next_stop_years": -1.0, "stop_kind": "chunk"}).is_empty() and SimBridge.parse_cruise({"next_stop_years": 0.1, "stop_kind": "lunch"}).is_empty() and SimBridge.parse_cruise(3).is_empty(), "the bridge checks the 2.10 cruise section")
	var dg := {"time": {"ship_days": 3}, "home": {}, "medium": {}, "crew": null}
	check(SimBridge.parse_cruise({"digest": dg}) == {"digest": dg} and SimBridge.parse_cruise({"next_stop_years": 0.1, "stop_kind": "chunk", "digest": dg}).get("digest") == dg
		and SimBridge.parse_cruise({"digest": {"time": {}}}).is_empty() and SimBridge.parse_cruise({}).is_empty() and SimBridge.parse_cruise({"stop_kind": "chunk"}).is_empty(),
		"I2: the cruise section may carry the digest, alone on the arrival tick")

	# R2-INTERLUDE I3: the review formats sim fields and computes nothing. The lines, the clocks and
	# the tier table left Godot (sim/cruise_digest.ail; tests/test_crossing_review.gd); these are the
	# formats the review's bindings use (mutation: change a field, the text follows).
	var pv := {"journey": {"plan": {"cruise_beta": 0.9999, "cruise_one_minus_beta": 0.0001}}, "cruise": {"digest": {"time": {"tier_line": "%s years at home. The news you left with is history.", "years_at_home": 4.0}}}}
	check(DisplayBinding.format_field(pv, "journey.plan", "speed_c") == "0.9999c", "speed_c formats the plan's exact 1 - beta")
	check(DisplayBinding.format_field(pv, "cruise.digest.time", "tier_line") == "4 years at home. The news you left with is history.", "tier_line fills the sim's line with the sim's whole years")
	pv.cruise.digest.time.years_at_home = 7.0
	check(DisplayBinding.format_field(pv, "cruise.digest.time", "tier_line").begins_with("7 years at home"), "mutating years_at_home changes the tier line")
	pv.cruise.digest.time.tier_line = "A year at home. The news you left with is history."
	check(DisplayBinding.format_field(pv, "cruise.digest.time", "tier_line") == "A year at home. The news you left with is history.", "a tier line with no %s is shown as the sim wrote it")
	check(DisplayBinding.format_field({"n": 3.0}, "n", "words") == "three" and DisplayBinding.format_field({}, "n", "words") == "-", "counts in words (no digits in crew text)")
	check(GalaxyMap.field_value({"a": [{"b": 1}, {"b": 2}]}, "a.1.b") == 2 and GalaxyMap.field_value({"a": [1]}, "a.3") == null, "a whole-number segment indexes a sim array")
	check(CardInterlude.speed_text(0.999999, 0.000001) == "0.999999c" and CardInterlude.speed_text(0.999, 0.001) == "0.999c", "speed text from exact 1 - beta")
	check(CardInterlude.speed_text(0.75, 0.25) == "0.750000c", "non-decade speeds print six decimals")
	# Compact HUD (demos/ship_geometry_demo.gd): speed from exact 1 - beta, readable clocks.
	var D = load("res://demos/ship_geometry_demo.gd")
	check(D.speed_text({"beta": 0.0}) == "At rest", "HUD: at rest")
	check(D.speed_text({"beta": 0.99, "gamma": 7.0888, "one_minus_beta": 0.01}) == "0.9900c · γ 7.09 · 296,795 km/s", "HUD: 0.99c line")
	check(D.speed_text({"beta": 0.999999, "gamma": 707.1, "one_minus_beta": 0.000001}).begins_with("0.999999c · γ 707.10"), "HUD: exact nines at γ 707")
	check(D.duration_text(0.00005) == "26.3 min" and D.duration_text(0.891) == "325.4 days" and D.duration_text(120.47) == "120.47 yr", "HUD: durations")
	# HUD distances: units and the three parts from sim fields.
	check(D.distance_text(12903.37 / 9460730472580.8) == "12,903 km" and D.distance_text(1.0 / 63241.077) == "1.000 AU" and D.distance_text(0.0158) == "999.2 AU" and D.distance_text(4.32) == "4.32 ly" and D.distance_text(120.47) == "120.5 ly", "HUD: distance units (%s, %s, %s)" % [D.distance_text(1.0 / 63241.077), D.distance_text(0.0158), D.distance_text(120.47)])
	var w := {"journey": {"state": "committed", "plan": {"target": {"id": "jupiter"}, "departure": {"x": 0.0, "y": 0.0, "z": 0.0}}}, "ship": {"pos": {"x": 3.0 / 63241.077, "y": 4.0 / 63241.077, "z": 0.0}}, "consequence": {"distance_remaining": 2.0 / 63241.077}, "system": {"bodies": []}}
	var d: String = D.distances_text(w, null)
	check(d == "To jupiter 2.000 AU · from last stop 5.000 AU · from Earth 5.000 AU", "HUD: distances line from fields: " + d)
	check(D.distances_text(w, null, {"jupiter": "Jupiter"}, "Mars") == "To Jupiter 2.000 AU · from Mars 5.000 AU · from Earth 5.000 AU", "HUD: committed leg uses catalogue names")
	# Stopped (Mark, 2026-10-08): at the target, from the stop the leg left, from Earth.
	w.journey.state = "arrived"
	w.journey.plan.target["pos"] = {"x": 3.0 / 63241.077, "y": 4.0 / 63241.077 + 1000.0 / 63241.077, "z": 0.0}
	w.journey.plan.departure = {"x": 3.0 / 63241.077, "y": 0.0, "z": 0.0}
	var a: String = D.distances_text(w, null, {"jupiter": "Alpha Centauri A"}, "Sirius A")
	check(a == "At Alpha Centauri A 1000 AU · from Sirius A 4.000 AU · from Earth 5.000 AU", "HUD: stopped shows at/from-last-stop/from-Earth: " + a)
	check(D.distances_text(w, null, {}, "Earth") == "At jupiter 1000 AU · from Earth 5.000 AU", "HUD: a leg that left Earth says from Earth once")
	var star_body := {"id": "acen-a", "name": "Alpha Centauri A", "catalogue_id": "jupiter", "rel_km": {"x": 0.0, "y": 0.0, "z": 2.0 * 149597870.7}}
	w["system"] = {"bodies": [star_body]}
	check(D.distances_text(w, null, {}, "Earth").begins_with("At Alpha Centauri A 2.000 AU"), "HUD: a finite star standing for the target gives the distance and its name: " + D.distances_text(w, null, {}, "Earth"))
	w.journey.erase("plan")
	check(D.distances_text(w, null) == "from Earth 5.000 AU", "HUD: no plan shows only the distance from Earth")
	print("cruise-interlude: %d failures" % failures)
	quit(1 if failures else 0)
