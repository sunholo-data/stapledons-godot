extends RefCounted
## Test-only observer. Real sim snapshots establish phases/arrivals; console reads carry their location.
const TARGETS := ["CNS5:3627", "Sol"]
const PHASES := ["boosting", "cruising", "braking"]
var phases := {}
var arrivals := {}
var reads: Array = []

static func target(world: Dictionary) -> String:
	var plan: Variant = world.get("journey", {}).get("plan")
	return str(plan.get("target", {}).get("id", "")) if plan is Dictionary else ""

func observe_world(world: Dictionary) -> void:
	var id := target(world)
	if id not in TARGETS: return
	var state: String = world.get("journey", {}).get("state", "")
	var phase: String = world.get("ship", {}).get("phase", "")
	if state == "committed" and phase in PHASES:
		if not phases.has(id): phases[id] = []
		if phase not in phases[id]: phases[id].append(phase)
	if state == "arrived" and phase == "at_rest" and world.ship.get("beta", -1.0) == 0.0:
		arrivals[id] = true

func observe_event(row: Dictionary) -> void:
	if row.get("type") != "read": return
	var read := {}
	for key in ["what", "location", "tick", "journey_state", "phase"]: read[key] = row.get(key)
	reads.append(read)

func errors(session: Array, final_world: Dictionary) -> Array[String]:
	var failures: Array[String] = []
	var games := 0
	var commits := 0
	for row: Dictionary in session:
		if row.get("type") == "new_game": games += 1
		if row.get("type") == "input":
			for intent: Dictionary in row.get("intents", []):
				if intent.get("k") == "commit": commits += 1
	if games != 1: failures.append("completion exactly one new_game")
	if commits != 2: failures.append("completion exactly two commits")
	if target(final_world) != "Sol" or final_world.get("journey", {}).get("state") != "arrived" or final_world.get("ship", {}).get("phase") != "at_rest" or final_world.ship.get("beta", -1.0) != 0.0:
		failures.append("completion missing return to Sol at rest")
	for id: String in TARGETS:
		if not arrivals.has(id): failures.append("completion missing observed arrival: " + id)
		for phase: String in PHASES:
			if phase not in phases.get(id, []): failures.append("completion missing phase: " + id + "/" + phase)
	var expected := [["CNS5:3627", "news", "destination news"], ["Sol", "news", "home news"], ["Sol", "log", "final home log"]]
	var next := 0
	var previous_tick := -1
	for read: Dictionary in reads:
		if not read.tick is int and not read.tick is float:
			failures.append("completion read tick missing"); continue
		if int(read.tick) < previous_tick or int(read.tick) > int(final_world.get("tick", -1)):
			failures.append("completion read ticks do not go backwards")
		previous_tick = int(read.tick)
		if next < expected.size() and read.location == expected[next][0] and read.what == expected[next][1] and read.journey_state == "arrived" and read.phase == "at_rest": next += 1
	for i in range(next, expected.size()): failures.append("completion missing " + expected[i][2])
	return failures

func witness() -> Dictionary:
	return {"phases": phases, "arrivals": arrivals.keys(), "reads": reads}
