extends SceneTree
## R2-CREW C8 (AC15): crew holds. The Crew page shows a hold as a card that says who and what in
## words, and Resume is a confirmed crew_resume; the auto-run presets are confirmed crew_orders. With
## the real sim (protocol 2.9), hands-on auto-run escalates the medic's stress into a hold; the
## guided voyage (SolarDeparture.step) then holds ship time while still ticking, so the page's
## queued Resume reaches the sim and the hold clears.
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
	print("crew-hold: %d failures" % failures)
	quit(1 if failures else 0)
