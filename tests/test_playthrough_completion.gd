extends SceneTree
## Completion is evidence of both arrivals and location-bound reads, not just two commit intents.
var passed := 0
var failures := 0
var contract: Script

func check(ok: bool, message: String) -> void:
	if ok: passed += 1
	else: failures += 1; print("FAIL " + message)

func world(target: String, state := "arrived", phase := "at_rest", tick := 40) -> Dictionary:
	return {"tick": tick, "journey": {"state": state, "plan": {"target": {"id": target}}}, "ship": {"phase": phase, "beta": 0.0}}

func recording(commits := 2, games := 1) -> Array:
	var rows: Array = []
	for i in games: rows.append({"v": 2, "type": "new_game"})
	for i in commits: rows.append({"v": 2, "type": "input", "intents": [{"k": "commit"}]})
	return rows

func read_at(target: String, what: String, tick: int) -> Dictionary:
	return {"type": "read", "what": what, "location": target, "tick": tick, "journey_state": "arrived", "phase": "at_rest"}

func journey(skip_phase := "", skip_arrival := "") -> RefCounted:
	var c: RefCounted = contract.new()
	for target in ["CNS5:3627", "Sol"]:
		for phase in ["boosting", "cruising", "braking"]:
			if target + "/" + phase != skip_phase: c.observe_world(world(target, "committed", phase))
		if target != skip_arrival: c.observe_world(world(target))
	return c

func reads(c: RefCounted, home_news := true, final_log := true) -> void:
	c.observe_event(read_at("CNS5:3627", "news", 10))
	if home_news: c.observe_event(read_at("Sol", "news", 30))
	if final_log: c.observe_event(read_at("Sol", "log", 40))

func _initialize() -> void:
	contract = load("res://tests/playthrough_completion.gd")
	check(contract != null, "completion contract exists")
	if contract != null:
		check(contract.target({"journey": {"plan": null}}) == "", "rest before first plan has no target")
		var c := journey(); reads(c)
		check(c.errors(recording(), world("Sol")).is_empty(), "complete voyage accepted")
		check(c.errors(recording(3), world("Sol")).has("completion exactly two commits"), "extra commit rejected")
		check(c.errors(recording(2, 2), world("Sol")).has("completion exactly one new_game"), "restart rejected")
		check(c.errors(recording(), world("Sol", "committed", "braking")).has("completion missing return to Sol at rest"), "unfinished return rejected")
		c = journey("", "Sol"); reads(c)
		check(c.errors(recording(), world("Sol")).has("completion missing observed arrival: Sol"), "unobserved return cannot pass from final snapshot")
		c = journey("Sol/cruising"); reads(c)
		check(c.errors(recording(), world("Sol")).has("completion missing phase: Sol/cruising"), "outbound phases cannot stand in for return phases")
		c = journey(); reads(c, false)
		check(c.errors(recording(), world("Sol")).has("completion missing home news"), "home news required")
		c = journey(); reads(c, true, false)
		check(c.errors(recording(), world("Sol")).has("completion missing final home log"), "home log required")
		c = journey(); c.observe_event(read_at("CNS5:3627", "news", 10)); c.observe_event(read_at("CNS5:3627", "news", 30)); c.observe_event(read_at("Sol", "log", 40))
		check(c.errors(recording(), world("Sol")).has("completion missing home news"), "duplicate away news cannot satisfy home read")
		c = journey(); c.observe_event(read_at("Sol", "news", 10)); c.observe_event(read_at("CNS5:3627", "news", 30)); c.observe_event(read_at("Sol", "log", 40))
		check(not c.errors(recording(), world("Sol")).is_empty(), "wrong read order rejected")
		c = journey(); reads(c); c.reads[1].tick = 5
		check(c.errors(recording(), world("Sol")).has("completion read ticks do not go backwards"), "stale read tick rejected")
		c = journey(); reads(c); c.reads[1].journey_state = "committed"
		check(c.errors(recording(), world("Sol")).has("completion missing home news"), "in-transit read cannot satisfy home read")
	print("playthrough-completion: %d passed, %d failures" % [passed, failures])
	quit(1 if failures else 0)
