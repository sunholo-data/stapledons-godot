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
	check(not card.done(), "not done before CARD_S")
	for i in int(CardInterlude.CARD_S / 0.05) + 1:
		card.advance(0.0, 0.05)
	check(card.done(), "done after CARD_S seconds")
	var early := CardInterlude.new(); early.begin(card.facts); early.advance(0.1, 0.05); early.finish()
	check(early.done(), "Continue ends the card early, after the cruise was consumed")
	var unconsumed := CardInterlude.new(); unconsumed.begin(card.facts); unconsumed.finish()
	check(not unconsumed.done(), "Continue cannot end a card that has not consumed the cruise")
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
	check(not chunked.done() and chunked.advance(left, 0.05) == 0.0, "after the braking stop the card holds and consumes nothing")
	var mid := CardInterlude.new()
	mid.begin(CruiseInterlude.facts_from(cw, "TRAPPIST-1"))
	mid.latest.cruise = {"next_stop_years": 0.5, "stop_kind": "chunk"}
	check(mid.advance(0.25, 0.05) == 0.25 and mid.crossed(), "the cruise left caps a longer stop and ends the crossing")
	var mid2 := CardInterlude.new()
	mid2.begin(CruiseInterlude.facts_from(cw, "TRAPPIST-1"))
	mid2.latest.cruise = {"next_stop_years": 0.1, "stop_kind": "check_in"}
	mid2.finish()
	check(mid2.advance(0.25, 0.05) == 0.1 and not mid2.crossed() and not mid2.done(), "Continue cannot end a crossing that has not reached braking")
	check(mid2.lines().cut == "Crossing… the crew's monthly check-in.", "the Crossing… line follows the sim's stop kind: " + str(mid2.lines().cut))
	mid2.latest.cruise = {"next_stop_years": 0.3, "stop_kind": "chunk"}
	check(mid2.lines().cut.begins_with("Crossing…") and mid2.lines().cut != "Crossing… the crew's monthly check-in.", "mutating stop_kind changes the Crossing… line")
	check(SimBridge.parse_cruise({"next_stop_years": 0.1, "stop_kind": "check_in"}) == {"next_stop_years": 0.1, "stop_kind": "check_in"} and SimBridge.parse_cruise({"next_stop_years": -1.0, "stop_kind": "chunk"}).is_empty() and SimBridge.parse_cruise({"next_stop_years": 0.1, "stop_kind": "lunch"}).is_empty() and SimBridge.parse_cruise(3).is_empty(), "the bridge checks the 2.10 cruise section")

	# Lines follow the simulation fields (mutation test: change a field, the line follows).
	card.observe(world(46.1, 0.78, 46.0, 0.0001, 70.7124459519056, 41.8))
	var l: Dictionary = card.lines()
	check(l.speed.begins_with("0.9999c") and l.speed.contains("γ 70.7"), "speed and γ from plan fields: " + l.speed)
	check(l.title == "CRUISE · TRAPPIST-1" and l.distance == "41.8 light-years", "leg name and plan distance")
	check(l.lived.contains("%.0f days" % ((0.78 - 0.1927134937008) * 365.25)) and l.lived.contains("41.79 years"), "lived/Earth from clock fields: " + l.lived)
	check(l.news.contains("46.0 years old"), "news age from consequence field")
	check(l.tier.begins_with("46 years at home") and l.tier.contains("parents"), "46 Earth years selects the middle tier")
	card.observe(world(46.1, 0.78, 12.5, 0.0001, 70.7124459519056, 41.8))
	check(card.lines().news.contains("12.5 years old"), "mutating news_age_years changes the card")
	card.observe(world(120.4, 0.88, 120.0, 0.0001, 70.7124459519056, 41.8))
	check(card.lines().tier.begins_with("120 years.") and card.lines().tier.contains("Everyone you knew is gone"), "120 Earth years selects the last tier")
	check(CardInterlude.tier_text(4.3).begins_with("4 years have passed at home"), "4.3 Earth years selects the first tier")
	check(CardInterlude.tier_text(9.99).contains("history") and CardInterlude.tier_text(10.0).contains("parents") and CardInterlude.tier_text(80.0).contains("Everyone"), "tier boundaries at 10 and 80 years")
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
