extends SceneTree
## R2-CREW C2 (AC6, Godot side): the real AILANG sim over the bridge at protocol 2.9. A crew game
## mirrors the crew section; crew intents built with SimBridge.crew_intent are accepted or refused
## with a crew: reason; a 2.9 game without crew has no crew section; below 2.9 a crew game is refused.
## Run:  make crew-bridge-test

var failures := 0

func check(name: String, ok: bool) -> void:
	if not ok: failures += 1
	print("%s %s" % ["ok" if ok else "FAIL", name])

func bridge(minor: int) -> SimBridge:
	var b := SimBridge.new()
	b.want_minor = minor
	return b if b.start() else null

func _initialize() -> void:
	var b := bridge(SimBridge.CREW_MINOR)
	check("2.9 handshake", b != null and int(b.hello_reply["proto"]["minor"]) == 9)
	check("crew game starts", b != null and b.new_game(2, "free_nav", false, {}, "", "consent"))
	check("crew mirrored at new game", b.crew.get("captaincy") == "consent" and b.crew["members"].size() == 5)
	var medic: Dictionary = b.crew["members"][0]
	check("member has indicators and trust", medic["id"] == "medic" and medic["indicators"].has("stress") and int(medic["trust"]) == 55)
	var ok := b.send([SimBridge.crew_intent("crew_offer", {"command": "offer", "worker": "medic", "recipe": "work_medic", "id": "t1"}),
		SimBridge.crew_intent("crew_ask", {"command": "ask", "actor": "medic", "task": "t1", "id": "r1"})], 0.0)
	check("offer and ask accepted", ok and b.last_refused.is_empty())
	check("the offer shows in heard", b.crew["heard"].any(func(e): return e["id"] == "t1"))
	ok = b.send([SimBridge.crew_intent("crew_offer", {"command": "offer", "worker": "cook", "recipe": "work_cook", "id": "t2"})], 0.0)
	check("an unknown crew member is refused crew:", ok and b.last_refused.size() == 1 and str(b.last_refused[0]["reason"]).begins_with("crew:"))
	ok = b.send([], 3.0 / 365.25 + 0.000001)
	check("three ship-days pass three crew turns", ok and int(b.crew["turn"]) == 3)
	b.stop()

	var plain := bridge(SimBridge.CREW_MINOR)
	check("2.9 game without crew has no crew section", plain.new_game(2, "free_nav") and plain.crew.is_empty() and not plain.world.has("crew"))
	ok = plain.send([SimBridge.crew_intent("crew_offer", {"command": "offer", "worker": "medic", "recipe": "work_medic", "id": "t1"})], 0.0)
	check("crew intent without crew is crew:no_crew", ok and plain.last_refused.size() == 1 and plain.last_refused[0]["reason"] == "crew:no_crew")
	plain.stop()

	var old := bridge(SimBridge.ISM_MINOR)
	check("2.8 crew game is refused bad_game", not old.new_game(2, "free_nav", false, {}, "", "consent") and old.last_error == "bad_game")
	old.stop()
	print("crew-bridge: %d failures" % failures)
	quit(1 if failures else 0)
