extends SceneTree
## R2-CREW-CONSOLE-V2 V3: record the Crew console's fixtures from the real sim at protocol 2.11
## (tests/crew/console_v2/*.json; a reviewed diff, never in make test).
##   board.json   seed 1, consent: a fresh crew, everyone free
##   mixed.json   the five offered at once with start on_accept (Ask): who agreed started, a
##                concern, a decline, and one agreed whose start was blocked (no compute free)
##   working.json mixed, one crew day later
##   hold.json    an orders crew under hands_on after a few crew days: auto-run held for someone
##   standdown.json  crew_core 0.6: the guided voyage's Alpha Centauri crossing under hands_on; the
##                first duty check-in where someone asks to stand down (a hold, stand_down)
##   resting.json the same crew after the captain lets them rest and resumes auto-run
## Run:  make crew-console-fixtures

const OUT := "res://tests/crew/console_v2"


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var ok := true
	var sim := SimBridge.new()
	sim.want_minor = SimBridge.CONSOLE_MINOR
	ok = sim.start() and sim.new_game(1, "free_nav", false, {}, "", "consent")
	ok = ok and int(sim.hello_reply.proto.minor) == SimBridge.CONSOLE_MINOR
	_save("board.json", sim.crew)
	var c := CrewConsole.new()
	c.show_crew(sim.crew)
	var offers: Array = []
	for id in ["medic", "engineer", "analyst", "pilot", "counselor"]:
		offers.append_array(c.offer_intents(id, "on_accept"))
	ok = ok and sim.send(offers, 0.0)
	print("mixed refusals %s" % [sim.last_refused])
	_save("mixed.json", sim.crew)
	ok = ok and sim.send([], 1.0 / 365.25 + 0.000001)
	_save("working.json", sim.crew)
	sim.stop()
	var h := SimBridge.new()
	h.want_minor = SimBridge.CONSOLE_MINOR
	ok = ok and h.start() and h.new_game(1, "free_nav", false, {}, "", "orders")
	ok = ok and h.send([SimBridge.crew_intent("crew_orders", {"command": "orders", "preset": "hands_on"})], 0.0)
	for i in 30:
		if not (h.crew.get("holds", []) as Array).is_empty():
			break
		ok = ok and h.send([], 1.0 / 365.25 + 0.000001)
	_save("hold.json", h.crew)
	h.stop()
	ok = ok and stand_down()
	c.free()
	print("crew-console-fixtures: %s" % ("ok" if ok else "FAIL"))
	quit(0 if ok else 1)


## The guided crossing (as crew-hold-test's), hands_on, until a stand-down hold; grant it, resume.
func stand_down() -> bool:
	for seed in [42, 3, 7, 11]:
		for cap in ["consent", "orders"]:
			if stand_down_at(seed, cap):
				return true
	return false


func stand_down_at(seed: int, cap: String) -> bool:
	var g := SimBridge.new()
	g.want_minor = SimBridge.CONSOLE_MINOR
	var Tour = load("res://demos/solar_departure.gd")
	var ok := g.start() and g.new_game(seed, "solar_departure", false, Tour.guided_params(), "", cap)
	g.queue([SimBridge.crew_intent("crew_orders", {"command": "orders", "preset": "hands_on"})])
	var catalogue: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/starmap/stars.json"))
	var tour = Tour.new()
	ok = ok and tour.attach(g, catalogue.stars)
	tour.leg_index = 3
	ok = ok and tour.advance()
	var found := false
	for i in 40000:
		if not ok or tour.interludes_done > 0 or not tour.failed.is_empty():
			break
		if tour.crew_held():
			var h: Dictionary = g.crew.holds[0]
			print("  seed %d %s: hold %s day %d" % [seed, cap, h.id, int(g.crew.turn)])
			if str(h.rule) == "stand_down":
				_save("standdown.json", g.crew)
				var m := CrewConsoleModel.member(g.crew, str(h.actor))
				g.queue([SimBridge.crew_intent("crew_stand_down", {"command": "resolve_stand_down", "id": str(m.get("stand_down", h.detail)), "release": true}),
					SimBridge.crew_intent("crew_resume", {"command": "resume", "hold": h.id})])
				ok = tour.step()
				print("stand-down answered: refused %s" % [g.last_refused])
				_save("resting.json", g.crew)
				found = true
				break
			for x: Dictionary in g.crew.holds:
				g.queue([SimBridge.crew_intent("crew_resume", {"command": "resume", "hold": x.id})])
		ok = ok and tour.step()
	g.stop()
	print("stand-down fixture: %s" % ("found" if found else "none in the crossing"))
	return ok and found


func _save(name: String, crew: Dictionary) -> void:
	var f := FileAccess.open(ProjectSettings.globalize_path(OUT.path_join(name)), FileAccess.WRITE)
	f.store_string(JSON.stringify(crew, "  ", false) + "\n")
	f.close()
	var states := (crew.get("members", []) as Array).map(func(m): return "%s=%s" % [m.get("id"), m.get("work_state")])
	print("fixture %s %s holds %d" % [name, " ".join(states), (crew.get("holds", []) as Array).size()])
