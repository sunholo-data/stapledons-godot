class_name AiRelay
extends RefCounted
## Turns the sim's AI events into AI work and the outcomes back into intents
## (design ai-service-foundation (a3)). Attached to a SimBridge
## (`attach(sim)` sets `sim.ai_relay`), it sees each accepted tick's events
## and its queued intents ride on the next `send`, so the tick never waits
## and the bridge's tee logs them like any intent. For each `ai_request`:
##   1. text-only mode and a media kind: `ai_cancel{text_only}`;
##   2. a cache hit (AiCache): `record` straight away, no service call;
##   3. live AI off: `ai_cancel{offline}`; no key for the kind's route:
##      `ai_cancel{no_key}`;
##   4. else forward to AiBridge; an `ok` result becomes a `record`, an error
##      or a bridge cancel an `ai_cancel` with the mapped reason.
## Replay mode observes only: the log already holds every record and cancel,
## so nothing is queued and the service is never started. The relay is
## enabled only when the sim's hello says protocol minor >= 1.

## Mode: "stub" (tests, CI: the stub service), "live" (opt-in, AI.9), "off"
## (live AI off: no service), "replay" (observe only).
var mode := "stub"
var bridge: AiBridge
var cache: AiCache
var text_only := false
## Providers whose key is present (stub: the set the stub pretends to have).
var keys: Array = ["gemini", "openrouter"]
var routing_path := "res://data/ai/routing.json"
## Cast entries sent with a request (the voice id names a voice line's variant).
var cast: Dictionary = {"medic": {"name": "The Medic", "voice": "Aoede"}}

var enabled := false
var hits := 0
var forwarded := 0
var cancelled := 0
var missing_blobs := 0
## Every AI event seen, in order (tests and the visual replay read them).
var seen: Array = []

var _queue: Array = []
var _routes: Dictionary = {}
## Accepted text lines by req: a voice request names one (`line_req`).
var _lines: Dictionary = {}


func _init(b: AiBridge = null, c: AiCache = null) -> void:
	bridge = b
	cache = c if c != null else AiCache.new()
	var r = JSON.parse_string(FileAccess.get_file_as_string(routing_path))
	_routes = r["routes"] if r is Dictionary and r.get("routes") is Dictionary else {}
	cache.load_layers()
	if bridge != null:
		bridge.outcome.connect(_on_outcome)


## Hook into `sim` and enable when its hello answers minor >= 1. An older sim
## runs on templates: the relay stays off and queues nothing.
func attach(sim: SimBridge) -> bool:
	var proto = sim.hello_reply.get("proto", {})
	enabled = proto is Dictionary and SimBridge._is_count(proto.get("minor")) and int(proto["minor"]) >= 1
	sim.ai_relay = self if enabled else null
	return enabled


## Queue an `ai_open` (the game's way to ask). Text-only mode never opens voice
## or portrait: false, nothing queued.
func open(kind: String, purpose: String, entity_id: String, fields: Dictionary = {}) -> bool:
	if not enabled or mode == "replay" or (text_only and kind != "text"):
		return false
	var o := {"k": "ai_open", "kind": kind, "purpose": purpose, "entity_id": entity_id}
	o.merge(fields)
	_queue.append(o)
	return true


func take_intents() -> Array:
	var out := _queue
	_queue = []
	return out


func queued() -> int:
	return _queue.size()


## The provider the routing table picks for `kind` with the keys present, or
## "" (no_key). Mirrors ai/route.ail resolve; tests compare it with the
## service's hello `routes`.
func route_for(kind: String) -> String:
	return route_in(_routes, kind, keys, text_only)


## The same over any routing table and key set (AiSettings uses it).
static func route_in(routes: Dictionary, kind: String, have: Array, only_text: bool) -> String:
	if only_text and kind != "text":
		return ""
	for hop in routes.get(kind, []):
		var p: String = hop.get("provider", "")
		if p in have and (p == "gemini" or (p == "openrouter" and kind == "text")):
			return p
	return ""


func on_events(events: Array) -> void:
	for e in events:
		var k = e.get("k") if e is Dictionary else null
		if typeof(k) != TYPE_STRING or not k.begins_with("ai_"):
			continue
		e = AiCache.ints(e)
		seen.append(e)
		match k:
			"ai_request":
				if enabled and mode != "replay":
					_on_request(e)
			"ai_accepted":
				if e.get("kind") == "text":
					_lines[e["req"]] = e.get("segments", [])
				elif not cache.has_blob(str(e.get("sha256"))):
					missing_blobs += 1 # a visual replay flags it and skips the asset


func _on_request(r: Dictionary) -> void:
	var kind: String = r.get("kind", "")
	if text_only and kind != "text":
		_cancel(r["req"], "text_only")
		return
	var req := r.duplicate(true)
	req.erase("k")
	var who: Dictionary = cast.get(r.get("entity_id", r["key"].get("entity_id")), {})
	if not who.is_empty():
		req["cast"] = who
	var key: Dictionary = r["key"].duplicate()
	if kind == "voice":
		if not _lines.has(r.get("line_req")):
			_cancel(r["req"], "provider_error") # a line this relay never saw: nothing to voice
			return
		req["segments"] = _lines[r["line_req"]]
		key["variant"] = AiCache.voice_variant(who.get("voice", "Aoede"), req["segments"])
	var hit := cache.lookup(key, int(key.get("age_stage", 0)))
	if not hit.is_empty():
		hits += 1
		_record_hit(r, hit)
		return
	if mode == "off":
		_cancel(r["req"], "offline")
		return
	if route_for(kind) == "" or bridge == null:
		_cancel(r["req"], "no_key")
		return
	forwarded += 1
	bridge.request(req)


func _record_hit(r: Dictionary, e: Dictionary) -> void:
	if r["kind"] == "text":
		var body := FileAccess.get_file_as_string(cache.blob_path(e))
		_queue.append(_record(r["req"], "text", e["sha256"], body))
	else:
		_queue.append(_record(r["req"], r["kind"], e["sha256"], SimBridge.encode(cache.descriptor(e, r["key"]))))


func _record(req: String, kind: String, sha: String, body: String) -> Dictionary:
	return {"k": "record", "source": "ai", "req": req, "kind": kind, "sha256": sha, "body": body}


## Service error codes and bridge cancels -> the sim's ai_cancel reasons.
const REASONS := {"no_key": "no_key", "budget": "budget", "text_only": "text_only", "timeout_internal": "timeout",
	"timeout": "timeout", "service_down": "service_down"}


func _on_outcome(o: Dictionary) -> void:
	if mode == "replay":
		return
	if o.get("type") == "result" and o.get("status") == "ok":
		_queue.append(_record(o["req"], o["kind"], o["sha256"], o["body"]))
		cache.refresh()
	else:
		_cancel(o["req"], REASONS.get(o.get("code", o.get("reason")), "provider_error"))


func _cancel(req: String, reason: String) -> void:
	cancelled += 1
	_queue.append({"k": "ai_cancel", "req": req, "reason": reason})
