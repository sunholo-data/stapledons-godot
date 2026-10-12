class_name ConversationSession
extends RefCounted
## Where the conversation's events come from (AI.10a, design (c)). The
## conversation reads only the sim's `ai_accepted` events and the cache; this
## file produces those events three ways:
##   rehearse  the sim, AiRelay and the stub service (`--caps IO,FS`) over a
##             library: one Medic line with emotions neutral, loving and
##             grieving (stub case `medic_style_frame`), then its voice. The
##             tee writes the session log; between ticks it waits for the
##             service, so the log does not depend on latency
##             (tests/replays/medic_rehearsal.ndjson is re-recorded byte for byte).
##   session   the same script through AiSession (the player's settings; AI.10b
##             runs it attended with live AI on: `--ai-live`)
##   replay    an input log through SimBridge with the relay in replay mode:
##             no AI process starts, the log holds every record.
##   pick      the line to play from a list of AI events: the last accepted
##             text line of the entity, and the accepted voice whose request
##             named it (`line_req`).
## The rehearsal's ticks:
##   1  open the line                   2  its record: accepted; open its voice
##   3  the voice request               4  its record: accepted
##   5  nothing (the session ends at rest)

const SEED := 20261007
const EMOTIONS := ["neutral", "loving", "grieving"]
const STUB_CASE := "medic_style_frame"


## The `ai_open` fields of the style-frame line. The stub case names the
## fixture text; a live run (AI.10b) leaves it out.
static func line_fields(stub: bool) -> Dictionary:
	var ctx := {"topic": "infirmary_night"}
	if stub:
		ctx["stub_case"] = STUB_CASE
	return {"emotions": EMOTIONS.duplicate(), "context": ctx}


## A started sim (tee to `log_path`) with a new game, and a stub relay over
## `library` with no core layer of its own (the library is all it writes).
## {sim, relay, bridge} or {} on failure.
static func stub_rig(log_path: String, library: String) -> Dictionary:
	var sim := SimBridge.new()
	sim.record_path = log_path
	if not sim.start() or not sim.new_game(SEED, "sol", false):
		return {}
	var bridge := AiBridge.new()
	bridge.cache_dir = library
	var cache := AiCache.new()
	cache.core_dir = library.path_join("no_core")
	cache.library_dir = library
	var relay := AiRelay.new(bridge, cache)
	if not relay.attach(sim):
		return {}
	return {"sim": sim, "relay": relay, "bridge": bridge}


## The game's own AI wiring (AiSession: the player's settings decide; live
## only with a key and the tick, never in automation), for the attended live
## line (AI.10b): the same script with the provider the settings choose. With
## live off the relay is "off": the line falls back and no service starts.
## {sim, relay, bridge, session} or {}. The caller owns `session` (a Node).
static func session_rig(args: Dictionary, log_path: String, dir := "user://") -> Dictionary:
	var ai := AiSession.new(args, dir)
	var sim := SimBridge.new()
	sim.record_path = log_path
	if not sim.start() or not sim.new_game(SEED, "sol", false, {}, AiSession.ai_core()) or not ai.attach(sim):
		ai.free()
		return {}
	return {"sim": sim, "relay": ai.relay, "bridge": ai.bridge, "session": ai}


## The scripted rehearsal over an attached rig. Returns the ticks sent, or -1.
static func rehearse(sim: SimBridge, relay: AiRelay, bridge: AiBridge, entity := "medic", stub := true) -> int:
	relay.open("text", "line", entity, line_fields(stub))
	var ticks := 0
	for step in 4:
		if not sim.send([], 0.0):
			return -1
		ticks += 1
		if not idle(bridge, 60000):
			return -1
		if step == 1:
			var line: Dictionary = pick(relay.seen, entity).get("line", {})
			if line.is_empty():
				return -1
			relay.open("voice", "line", entity, {"line_req": line["req"]})
	if not sim.send([], 0.0):
		return -1
	return ticks + 1


## Poll the bridge until nothing is queued or in flight (or `ms` pass).
static func idle(bridge: AiBridge, ms: int) -> bool:
	var end := Time.get_ticks_msec() + ms
	while Time.get_ticks_msec() < end:
		bridge.poll()
		if bridge.pending() == 0:
			return true
		OS.delay_msec(2)
	return false


## Replay `log_path` through a sim, the relay observing only. Returns
## {ok, events (every AI event, in order), relay, launches} ; `cache` resolves
## blobs so missing ones are counted (relay.missing_blobs).
static func replay(log_path: String, cache: AiCache) -> Dictionary:
	var lines := FileAccess.get_file_as_string(log_path).split("\n", false)
	var out := {"ok": false, "events": [], "launches": 0}
	if lines.size() < 2:
		return out
	var ng = JSON.parse_string(lines[1])
	var sim := SimBridge.new()
	if not (ng is Dictionary) or not sim.start() or not sim.new_game(int(ng.get("seed", SEED)), ng.get("scenario", "sol"), ng.get("diag", false), {}, ng.get("ai_core", "")):
		sim.stop()
		return out
	var bridge := AiBridge.new()
	var relay := AiRelay.new(bridge, cache)
	relay.mode = "replay"
	var ok := relay.attach(sim)
	for i in range(2, lines.size()):
		var m = JSON.parse_string(lines[i])
		if not (m is Dictionary) or m.get("type") != "input":
			continue
		ok = ok and sim.send(AiCache.ints(m["intents"]), float(m["dtau"]))
	sim.stop()
	out["ok"] = ok
	out["events"] = relay.seen
	out["relay"] = relay
	out["launches"] = bridge.launch_count
	bridge.free()
	return out


## The line to play: the last accepted text line of `entity` (purpose line)
## and the last accepted voice whose request named that line. {} parts when
## absent: {line: {req, segments, text, sha256}, voice: {req, sha256, descriptor}}.
static func pick(events: Array, entity: String) -> Dictionary:
	var asked := {}
	for e in events:
		if e.get("k") == "ai_request":
			asked[e.get("req")] = e
	var line := {}
	for e in events:
		var rq: Dictionary = asked.get(e.get("req"), {})
		if e.get("k") == "ai_accepted" and e.get("kind") == "text" and rq.get("purpose") == "line" and rq.get("key", {}).get("entity_id") == entity:
			line = e
	var voice := {}
	if not line.is_empty():
		for e in events:
			if e.get("k") == "ai_accepted" and e.get("kind") == "voice" and asked.get(e.get("req"), {}).get("line_req") == line["req"]:
				voice = e
	return {"line": line, "voice": voice}
