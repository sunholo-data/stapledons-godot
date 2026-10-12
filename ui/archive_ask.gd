class_name ArchiveAsk
extends RefCounted
## R1-ARCHIVE-VOICE: the captain asks the Archive a question at the Archive terminal.
## The question goes to the sim as ai_open{text, purpose archive, entity archive} with the
## Archive's sensor feed as context (at most 8 fields, sim/ai.ail). The answer is the sim's
## ai_accepted text for that request; a fallback, a refusal or no live AI leaves an in-world line.
## Asking is information, not a decision (D-56), so it is instant at the terminal.
## Everything shown here speaks in-world (D-67, D-68; `make in-world-voice-check` scans it).

const ENTITY := "archive"
const EMOTIONS := ["neutral", "curious", "fearful", "loving", "sad"]
const CANON := ["archive.bubble", "archive.two-clocks", "archive.weather-between-the-stars", "archive.nothing-crosses"]
const MAX_QUESTION := 200
const OFFLINE := "The Archive's deeper stores are not answering. Its entries are open on the terminal."
const DAMAGED := "The answer came back damaged. The Archive asks you to put the question again, perhaps in other words."
const THINKING := "The Archive is considering."

var question := ""
var answer := ""
var state := "idle" # idle | waiting | answered | offline | damaged
var req := "" # the sim's request id for the open question, once its ai_request event arrives
var asked := 0


## The sensor feed, from the sim's world (and the ship's own name for where it is).
## Field names and values are strings; nothing here is computed beyond formatting.
static func sensors(world: Dictionary, where := "") -> Dictionary:
	var out := {}
	var w := where if not where.is_empty() else _s(world, "hud.where")
	if not w.is_empty():
		out["location"] = w
	var sp := _s(world, "hud.speed")
	if not sp.is_empty():
		out["speed"] = sp
	var tau: Variant = GalaxyMap.field_value(world, "clock.tau")
	var year: Variant = GalaxyMap.field_value(world, "clock.year")
	if tau != null and year != null:
		out["clocks"] = "ship clock %s since departure; home calendar %s" % [ShipHud.duration_text(float(tau)), ShipHud.duration_text(float(year))]
	var med := _s(world, "ship.ism.medium")
	if not med.is_empty():
		out["medium"] = med.replace("_", " ")
	var st := _s(world, "journey.state")
	if not st.is_empty():
		var target := _s(world, "journey.plan.target.name")
		if target.is_empty():
			target = _s(world, "journey.plan.target.id")
		out["journey"] = st + ("" if target.is_empty() else " (course: %s)" % target)
	var news := _s(world, "consequence.news.star_id")
	if not news.is_empty():
		out["news"] = "a message from home has reached the ship at %s" % news
	return out


static func _s(world: Dictionary, path: String) -> String:
	var v: Variant = GalaxyMap.field_value(world, path)
	return "" if v == null else str(v)


## The ai_open fields: the question, the sensors (at most 6, so 8 with the question and canon).
static func open_fields(q: String, world: Dictionary, where := "") -> Dictionary:
	var ctx := {"question": q}
	var s := sensors(world, where)
	for k in ["location", "speed", "clocks", "medium", "journey", "news"]:
		if s.has(k):
			ctx[k] = s[k]
	ctx["canon"] = CANON.duplicate()
	return {"emotions": EMOTIONS.duplicate(), "context": ctx}


## Ask. False (and nothing queued) for an empty question. With no live AI the in-world
## offline line answers at once.
func ask(q: String, relay: AiRelay, world: Dictionary, where := "") -> bool:
	q = q.strip_edges().left(MAX_QUESTION)
	if q.is_empty():
		return false
	question = q
	req = ""
	asked += 1
	if relay == null or not relay.enabled or relay.mode in ["off", "replay"] or relay.route_for("text") == "":
		state = "offline"
		answer = OFFLINE
		return true
	if not relay.open("text", "archive", ENTITY, open_fields(q, world, where)):
		state = "offline"
		answer = OFFLINE
		return true
	state = "waiting"
	answer = THINKING
	return true


## The sim's events for one step: the request id, then its answer or its fallback.
func on_events(events: Array) -> void:
	if state != "waiting":
		return
	for e in events:
		if not e is Dictionary:
			continue
		var k := str(e.get("k", ""))
		if k == "ai_request" and req.is_empty() and str(e.get("purpose", "")) == "archive":
			req = str(e.get("req", ""))
		elif k == "ai_accepted" and str(e.get("req", "")) == req and not req.is_empty() and e.get("kind") == "text":
			answer = unmarked(str(e.get("text", "")))
			state = "answered"
		elif k == "ai_fallback" and str(e.get("req", "")) == req and not req.is_empty():
			answer = DAMAGED
			state = "damaged"


## The display text without its emotion markers ("{curious} The hull ..." -> "The hull ...").
static func unmarked(t: String) -> String:
	var re := RegEx.create_from_string("\\{[a-z_]+\\}\\s*")
	return re.sub(t, "", true).strip_edges()
