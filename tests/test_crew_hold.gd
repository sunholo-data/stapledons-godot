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
	# R2-CREW-CONSOLE-V2: a hold opens the held person's call on the Crew console, with the sim's
	# words as a banner and Resume beside them; the board's strip carries the auto-run presets.
	var board: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/crew/console_v2/board.json"))
	var section: Dictionary = board.duplicate(true)
	section["auto"] = "hands_on"
	section["holds"] = [{"id": "h1-breakdown-medic", "rule": "breakdown", "actor": "medic", "name": "Ligaya Reyes", "task": "", "tick": 1, "detail": "stress 70", "line": "is close to breaking down."}]
	section.members[0]["work_state"] = "held"
	section.members[0]["emotion"] = "sad"
	var page := CrewConsole.new()
	root.add_child(page)
	page.show_crew(board)
	page.show_crew(section)
	var all := texts(page)
	check("the hold opens the medic's call, its words as a banner", page.call_id == "medic" and all.has("Auto-run held: Ligaya Reyes is close to breaking down.") and page.find_child("HoldBanner", true, false) != null)
	check("during a hold the call faces the person who needs you, strained", (page.find_child("CallPortrait", true, false) as TextureRect).texture == CrewPage.face("medic", "sad"))
	check("Resume needs a confirming press", page.press("resume:h1-breakdown-medic").is_empty())
	var r := page.press("resume:h1-breakdown-medic")
	check("the confirmed Resume is crew_resume for that hold", r.size() == 1 and r[0]["k"] == "crew_resume" and line_of(r[0]) == {"command": "resume", "hold": "h1-breakdown-medic"})
	page.on_refused([], r)
	page.end_call()
	all = texts(page)
	check("the board's strip shows the preset and the others", page.find_child("AutoNow", true, false).text == "Hands on" and page.find_child("Auto_critical_only", true, false) != null and page.find_child("Auto_off", true, false) != null)
	check("the held row says so on the board", all.has("Auto-run held: is close to breaking down."))
	page.press("orders:critical_only")
	var o := page.press("orders:critical_only")
	check("choosing a preset is a confirmed crew_orders", o.size() == 1 and o[0]["k"] == "crew_orders" and line_of(o[0]) == {"command": "orders", "preset": "critical_only"})

	# The real sim: hands-on auto-run, three days, a hold; the voyage holds ship time; Resume clears it.
	var sim := SimBridge.new()
	sim.want_minor = SimBridge.CONSOLE_MINOR
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

	# Playtest (dev.31): with the guided tour paused (P), turning, or waiting on a stop choice, an
	# offer pressed on the Crew page still reaches the sim on a zero-dtau tick: the member answers
	# and ship time does not move. While the offer waits, the Offer button is disabled, with why.
	var ps := SimBridge.new()
	ps.want_minor = SimBridge.CONSOLE_MINOR
	var pok := ps.start() and ps.new_game(1, "free_nav", false, {}, "", "orders")
	var tour = load("res://demos/solar_departure.gd").new()
	tour.sim = ps
	var pp := CrewConsole.new()
	root.add_child(pp)
	pp.show_crew(ps.crew)
	pp.intents.connect(ps.queue) # the console's wiring (ShipConsoles._crew_section / _on_crew_step)
	ps.stepped.connect(func(_e: Array) -> void:
		if not ps.last_queued.is_empty(): pp.on_refused(ps.queued_refused(), ps.last_queued)
		pp.show_crew(ps.crew))
	tour.paused = true
	var idle_tick := int(ps.world.tick)
	check("paused with nothing queued, the tour sends nothing (replays unchanged)", pok and tour.step() and int(ps.world.tick) == idle_tick)
	for c in [["paused", "counselor"], ["attitude_hold", "pilot"], ["pending_index", "engineer"]]:
		tour.paused = c[0] == "paused"
		tour.attitude_hold = c[0] == "attitude_hold"
		tour.pending_index = 0 if c[0] == "pending_index" else -1
		var id: String = c[1]
		var t0 := float(ps.world.clock.tau)
		var y0 := float(ps.world.clock.year)
		var k0 := int(ps.world.tick)
		var lines0: int = ps.crew.get("lines", []).size()
		pp.press("call:" + id)
		pp.press("offer:" + id)
		var sent := pp.press("offer:" + id)
		var btn := pp.find_child("Offer_" + id, true, false) as Button
		check("%s: the confirmed offer is sent once and Offer waits, disabled, saying why" % c[0], sent.size() == 2 and btn != null and btn.disabled and btn.text == CrewPage.OFFER_PENDING
			and texts(pp).has(CrewConsoleModel.REASONS["sending"]))
		check("%s: pressing again while it waits sends nothing more" % c[0], pp.press("offer:" + id).is_empty() and ps.queued.size() == 2)
		var stepped_ok: bool = tour.step()
		var work = ps.crew["members"].filter(func(m): return m["id"] == id)[0].get("work")
		check("%s: the offer rides a zero-dtau tick and %s answers" % [c[0], id], stepped_ok and tour.failed.is_empty() and int(ps.world.tick) == k0 + 1 and ps.queued.is_empty()
			and work is Dictionary and ps.crew["lines"].size() == lines0 + 1 and ps.crew["lines"][-1]["actor"] == id)
		check("%s: no ship time passed and no stage moved" % c[0], float(ps.world.clock.tau) == t0 and float(ps.world.clock.year) == y0 and tour.leg_index == -1 and ps.world.journey.state != "committed")
		check("%s: the answer clears the sending lock" % c[0], not pp.sending.has(id) and pp.find_child("Offer_" + id, true, false) == null)
		pp.end_call()
	tour.paused = false
	tour.attitude_hold = false
	tour.pending_index = -1
	ps.stop()
	guided_crossing()
	print("crew-hold: %d failures" % failures)
	quit(1 if failures else 0)


## The guided voyage with an orders crew under critical_only (the live demo queues critical_only for
## every crew game): straight to the Alpha Centauri leg, whose ~70-day cruise is an interlude.
## Holds are resumed at once, as a captain would; each one raised in the crossing must have stopped
## it on its own check-in day, with ship time waiting until Resume.
func guided_crossing() -> void:
	var g := SimBridge.new()
	g.want_minor = SimBridge.CONSOLE_MINOR
	var Tour = load("res://demos/solar_departure.gd")
	var ok := g.start() and g.new_game(42, "solar_departure", false, Tour.guided_params(), "", "orders")
	check("2.11 guided voyage with an orders crew starts (%s)" % g.last_error, ok and int(g.hello_reply.proto.minor) == SimBridge.CONSOLE_MINOR and not g.crew.is_empty())
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
	var hold_words := true
	for i in 40000:
		if tour.interludes_done > 0 or not tour.failed.is_empty():
			break
		if tour.crew_held():
			var card: CardInterlude = tour.interlude as CardInterlude
			stops.append({"turn": int(g.crew.turn), "in_crossing": card != null, "crossed": card != null and card.crossed(), "left_yr": tour.pacing.cruise_remaining(g.world), "hold": str(g.crew.holds[0].id)})
			var p := CrewConsole.new()
			p.show_crew(g.crew)
			p.press("call:" + str(g.crew.holds[0].actor))
			hold_words = hold_words and str(g.crew.holds[0].get("line", "")) != "" and texts(p).has("Auto-run held: %s %s" % [CrewPage.display_name(g.crew, str(g.crew.holds[0].actor)), g.crew.holds[0].line])
			p.free()
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
	check("2.10: each hold carries the sim's words (holdLine) and the Crew console shows them", hold_words and not stops.is_empty())
	check("Resume continued the crossing to the braking boundary within 1e-12 of plan (%s yr)" % tour.last_boundary_error, tour.last_boundary_error >= 0.0 and tour.last_boundary_error <= 1e-12 * float(g.world.journey.plan.ship_years))
	g.stop()
