extends SceneTree
## R2-CREW C8 (AC15): crew holds. The Crew page shows a hold as a card that says who and what in
## words, and Resume is a confirmed crew_resume; the auto-run presets are confirmed crew_orders. With
## the real sim (protocol 2.9), hands-on auto-run escalates the medic's stress into a hold; the
## guided voyage (SolarDeparture.step) then holds ship time while still ticking, so the page's
## queued Resume reaches the sim and the hold clears.
## R2-INTERLUDE I1 (AC5): on the guided voyage (protocol 2.10) the cruise interlude crosses in chunks
## to the sim's next stop, so a hold raised on a monthly check-in stops the crossing on that day;
## Resume continues it to the braking boundary.
## Run:  make crew-hold-test

var failures := 0

func check(label: String, ok: bool) -> void:
	if not ok: failures += 1
	print("%s %s" % ["ok" if ok else "FAIL", label])

func texts(n: Node) -> Array:
	var out := []
	for c in n.get_children():
		if c is Label: out.append((c as Label).text)
		if c is Button: out.append((c as Button).text)
		out.append_array(texts(c))
	return out

func line_of(intent: Dictionary) -> Dictionary:
	return JSON.parse_string(intent["line"])

func _initialize() -> void:
	var section: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/crew/console_state.json"))
	section["auto"] = "hands_on"
	section["holds"] = [{"id": "h1-breakdown-medic", "rule": "breakdown", "actor": "medic", "name": "Ligaya Reyes", "task": "", "tick": 1, "detail": "stress 70"}]
	var page := CrewPage.new()
	root.add_child(page)
	page.show_crew(section)
	var all := texts(page)
	check("the hold card says who and what, in words", all.has("Needs you: Ligaya Reyes is close to breaking down.") and page.find_child("Hold_h1-breakdown-medic", true, false) != null)
	check("the card says auto-run waits", all.has("Auto-run waits until you resume it."))
	var call := page.get_node_or_null("Call")
	check("during a hold the call panel faces the person who needs you, strained", call != null and texts(call).has("Ligaya Reyes · The Medic") and call.find_child("CallPortrait", true, false).texture == page.portrait("medic", "sad"))
	check("the auto-run row shows the preset and the others", all.has("Auto-run: Hands on") and page.find_child("Auto_critical_only", true, false) != null and page.find_child("Auto_off", true, false) != null)
	check("Resume needs a confirming press", page.press("resume:h1-breakdown-medic").is_empty())
	var r := page.press("resume:h1-breakdown-medic")
	check("the confirmed Resume is crew_resume for that hold", r.size() == 1 and r[0]["k"] == "crew_resume" and line_of(r[0]) == {"command": "resume", "hold": "h1-breakdown-medic"})
	page.press("orders:critical_only")
	var o := page.press("orders:critical_only")
	check("choosing a preset is a confirmed crew_orders", o.size() == 1 and o[0]["k"] == "crew_orders" and line_of(o[0]) == {"command": "orders", "preset": "critical_only"})

	# The real sim: hands-on auto-run, three days, a hold; the voyage holds ship time; Resume clears it.
	var sim := SimBridge.new()
	sim.want_minor = SimBridge.CREW_MINOR
	var ok := sim.start() and sim.new_game(2, "free_nav", false, {}, "", "consent")
	ok = ok and sim.send([SimBridge.crew_intent("crew_orders", {"command": "orders", "preset": "hands_on"})], 0.0) and sim.crew.get("auto") == "hands_on"
	ok = ok and sim.send([], 3.0 / 365.25 + 0.000001)
	var holds: Array = sim.crew.get("holds", [])
	check("hands-on auto-run escalates into one hold, with a crew_hold event", ok and holds.size() == 1 and sim.last_events.any(func(e): return e.get("k") == "crew_hold"))
	var dep = load("res://demos/solar_departure.gd").new()
	dep.sim = sim
	var tau0 := float(sim.world.clock.tau)
	var tick0 := int(sim.world.tick)
	var held: bool = dep.crew_held() and dep.step() and dep.step()
	check("while held, the voyage ticks but ship time waits", held and int(sim.world.tick) == tick0 + 2 and float(sim.world.clock.tau) == tau0)
	page.show_crew(sim.crew)
	page.intents.connect(sim.queue)
	page.press("resume:" + str(holds[0]["id"]) if holds.size() > 0 else "resume:none")
	page.press("resume:" + str(holds[0]["id"]) if holds.size() > 0 else "resume:none")
	var stepped: bool = dep.step()
	check("the page's queued Resume rides the held tick and clears the hold", stepped and sim.last_refused.is_empty() and not dep.crew_held())
	sim.stop()
	guided_crossing()
	print("crew-hold: %d failures" % failures)
	quit(1 if failures else 0)


## The guided voyage with an orders crew under critical_only (the live demo queues critical_only for
## every crew game): straight to the Alpha Centauri leg, whose ~70-day cruise is an interlude.
## Holds are resumed at once, as a captain would; each one raised in the crossing must have stopped
## it on its own check-in day, with ship time waiting until Resume.
func guided_crossing() -> void:
	var g := SimBridge.new()
	g.want_minor = SimBridge.INTERLUDE_MINOR
	var Tour = load("res://demos/solar_departure.gd")
	var ok := g.start() and g.new_game(42, "solar_departure", false, Tour.guided_params(), "", "orders")
	check("2.10 guided voyage with an orders crew starts (%s)" % g.last_error, ok and int(g.hello_reply.proto.minor) == SimBridge.INTERLUDE_MINOR and not g.crew.is_empty())
	if not ok:
		g.stop(); return
	g.queue([SimBridge.crew_intent("crew_orders", {"command": "orders", "preset": "critical_only"})])
	var catalogue: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/starmap/stars.json"))
	var tour = Tour.new()
	ok = tour.attach(g, catalogue.stars)
	tour.leg_index = 3 # the next leg is CNS5:3627, Alpha Centauri
	ok = ok and tour.advance() and g.world.journey.state == "committed" and g.crew.get("auto") == "critical_only"
	check("the Alpha Centauri leg commits with critical_only auto-run (%s)" % tour.failed, ok)
	if not ok:
		g.stop(); return
	var stops := [] # {turn, in_crossing, crossed, left_yr}
	var waits := true
	var chunk_kinds := {}
	var turn_at_start := -1
	for i in 40000:
		if tour.interludes_done > 0 or not tour.failed.is_empty():
			break
		if tour.crew_held():
			var card: CardInterlude = tour.interlude as CardInterlude
			stops.append({"turn": int(g.crew.turn), "in_crossing": card != null, "crossed": card != null and card.crossed(), "left_yr": tour.pacing.cruise_remaining(g.world), "hold": str(g.crew.holds[0].id)})
			var tau := float(g.world.clock.tau)
			var held: bool = tour.step() and tour.step()
			waits = waits and held and float(g.world.clock.tau) == tau and tour.interlude == card
			for h: Dictionary in g.crew.holds:
				g.queue([SimBridge.crew_intent("crew_resume", {"command": "resume", "hold": h.id})])
		if tour.interlude != null and turn_at_start < 0:
			turn_at_start = int(g.crew.turn)
		if tour.interlude != null and g.world.has("cruise"):
			chunk_kinds[str(g.world.cruise.stop_kind)] = true
		if not tour.step():
			break
	var crossing: Array = stops.filter(func(s: Dictionary) -> bool: return s.in_crossing)
	print("    guided crossing: start day %d, holds %s, stop kinds %s, interlude chunks %d" % [turn_at_start, stops.map(func(s): return "%s@%d" % [s.hold, s.turn]), chunk_kinds.keys(), tour.interludes_done])
	check("the voyage reached and finished the Alpha Centauri interlude (%s)" % tour.failed, tour.failed.is_empty() and tour.interludes_done == 1)
	check("the crossing stopped for holds, each on its monthly check-in day, with cruise still to go", crossing.size() >= 2 and crossing.all(func(s: Dictionary) -> bool: return s.turn % 30 == 1 and not s.crossed and s.left_yr > 0.0))
	check("a hold in month 2 stopped the crossing in month 2 (day 31)", crossing.any(func(s: Dictionary) -> bool: return s.turn == 31))
	check("while held, ship time waits and the interlude stays", waits)
	check("Resume continued the crossing to the braking boundary within 1e-12 of plan (%s yr)" % tour.last_boundary_error, tour.last_boundary_error >= 0.0 and tour.last_boundary_error <= 1e-12 * float(g.world.journey.plan.ship_years))
	g.stop()
