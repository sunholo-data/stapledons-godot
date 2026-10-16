extends SceneTree
## R2-CREW-CONSOLE-V2 V3: record the Crew console's fixtures from the real sim at protocol 2.11
## (tests/crew/console_v2/*.json; a reviewed diff, never in make test).
##   board.json   seed 1, consent: a fresh crew, everyone free
##   mixed.json   the five offered at once with start on_accept (Ask): who agreed started, a
##                concern, a decline, and one agreed whose start was blocked (no compute free)
##   working.json mixed, one crew day later
##   hold.json    an orders crew under hands_on after a few crew days: auto-run held for someone
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
	c.free()
	print("crew-console-fixtures: %s" % ("ok" if ok else "FAIL"))
	quit(0 if ok else 1)


func _save(name: String, crew: Dictionary) -> void:
	var f := FileAccess.open(ProjectSettings.globalize_path(OUT.path_join(name)), FileAccess.WRITE)
	f.store_string(JSON.stringify(crew, "  ", false) + "\n")
	f.close()
	var states := (crew.get("members", []) as Array).map(func(m): return "%s=%s" % [m.get("id"), m.get("work_state")])
	print("fixture %s %s holds %d" % [name, " ".join(states), (crew.get("holds", []) as Array).size()])
