extends SceneTree
## Records tests/replays/ai_stub_session.ndjson (AI.7, design AC10/AC12):
## the sim, AiRelay and AiBridge running the stub service (`--caps IO,FS`)
## over a fresh library, written by SimBridge's tee. Between ticks it waits
## until the service has answered, so the log does not depend on latency:
##   tick 1  open a Medic line, a news item, a grieving portrait and a news
##           item the stub answers with digits
##   tick 2  their records: three accepted, the digits refused ai_numeral
##   tick 3  open a voice for the line and the same portrait again; the
##           portrait is a library hit (no service call)
##   tick 4  the portrait hit's record and the voice record
##   tick 5  nothing (the session ends at rest)
## Run:  godot --headless --path . --script tools/record_ai_session.gd -- OUT.ndjson
## then  make replay-record LOG=OUT.ndjson  (review the golden diff).

const SEED := 20261007


## The scripted session. `relay` must be attached to `sim` (a started sim with
## a new game). Returns the number of ticks sent, or -1 if the service never
## went idle.
static func run_session(sim: SimBridge, relay: AiRelay, bridge: AiBridge) -> int:
	relay.open("text", "line", "medic", {"emotions": ["neutral", "loving", "grieving"], "context": {"topic": "first_night_aboard"}})
	relay.open("text", "news", "medic")
	relay.open("portrait", "line", "medic", {"emotion": "grieving", "age_stage": 0})
	relay.open("text", "news", "medic", {"context": {"stub_case": "digits"}})
	var ticks := 0
	for step in 4:
		if not sim.send([], 0.0):
			return -1
		ticks += 1
		if step == 1:
			relay.open("voice", "line", "medic", {"line_req": first_accepted_line(relay)})
			relay.open("portrait", "line", "medic", {"emotion": "grieving", "age_stage": 0})
			if not sim.send([], 0.0):
				return -1
			ticks += 1
		if not idle(bridge, 30000):
			return -1
	return ticks


static func first_accepted_line(relay: AiRelay) -> String:
	for e in relay.seen:
		if e["k"] == "ai_accepted" and e["kind"] == "text":
			return e["req"]
	return ""


## Poll the bridge until nothing is queued or in flight (or `ms` pass).
static func idle(bridge: AiBridge, ms: int) -> bool:
	var end := Time.get_ticks_msec() + ms
	while Time.get_ticks_msec() < end:
		bridge.poll()
		if bridge.pending() == 0:
			return true
		OS.delay_msec(2)
	return false


## A sim + stub relay over `library`, tee to `log_path`. {sim, relay, bridge} or {}.
static func stub_rig(log_path: String, library: String, keys: Array = ["gemini", "openrouter"]) -> Dictionary:
	var sim := SimBridge.new()
	sim.record_path = log_path
	if not sim.start() or not sim.new_game(SEED, "sol", false):
		return {}
	var bridge := AiBridge.new()
	bridge.cache_dir = library
	bridge.stub_keys = keys
	var cache := AiCache.new()
	cache.core_dir = library.path_join("no_core")
	cache.library_dir = library
	var relay := AiRelay.new(bridge, cache)
	relay.keys = keys
	if not relay.attach(sim):
		return {}
	return {"sim": sim, "relay": relay, "bridge": bridge}


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		push_error("usage: ... -- OUT.ndjson")
		quit(2)
		return
	var library := ProjectSettings.globalize_path("res://.godot/tmp/record_ai_session")
	OS.execute("/bin/rm", PackedStringArray(["-rf", library]))
	DirAccess.make_dir_recursive_absolute(library)
	var rig := stub_rig(args[0], library)
	if rig.is_empty():
		push_error("sim session failed")
		quit(2)
		return
	var n := run_session(rig["sim"], rig["relay"], rig["bridge"])
	rig["sim"].stop()
	rig["bridge"].shutdown()
	rig["bridge"].free()
	print("recorded %s: %d ticks, %d hits, %d forwarded" % [args[0], n, rig["relay"].hits, rig["relay"].forwarded])
	quit(0 if n > 0 else 1)
