class_name ArchiveNarration
extends RefCounted
## R2-INTERLUDE I4 (design interlude-card.md D3, Rulings §6): the Archive tells the crossing.
## The crossing review's pages 1 and 3 always carry the Archive's authored framing, picked in the
## pure sim (cruise.digest.narration: key, crossing, aboard; no digits, in-world). With live AI on
## and a key present (D-8: the relay is live, or the tests' stub, and routes text), once per
## crossing, when the crossing is over, the host asks the Archive for its own telling:
## ai_open{text, purpose archive, entity archive} with the digest's fields as context (at most 8,
## sim/ai.ail). The service screens the reply (ai/reply.ail screen: markers, digits, length,
## out-of-world words) and the sim validates and records it (record -> ai_accepted), so a replay is
## byte-identical with no service. The accepted telling replaces the authored crossing line on
## page 1, and is voiced once (ai_open{voice} naming that line: ai/voice.ail, Gemini TTS with a
## key, the stub voice under the stub service), cached by its voice key (AiCache, AiRelay).
## Without live AI nothing is opened and the authored lines stand, silent.
## Everything shown here speaks in-world (D-67, D-68; `make in-world-voice-check` scans it).

const ENTITY := "archive"
const EMOTIONS := ["neutral", "curious", "sad", "loving", "fearful"]
const CANON := ["archive.two-clocks"]
const QUESTION := "Tell me what happened while we crossed, aboard and at home."
const D := "cruise.digest."

var state := "idle" # idle (authored lines) | waiting | told | authored (the telling fell back)
var crossing := "" # the crossing the telling is for (the digest's begin clocks)
var req := "" # the telling's request id, once its ai_request event arrives
var telling := "" # the accepted telling, without its markers
var voice_req := "" # the voice request id
var voice := {} # the accepted voice event {req, sha256, descriptor}
var opened := 0 # telling requests opened (one per crossing)
var voiced := 0 # voice requests opened (one per crossing)
var _relay: AiRelay = null
var _voice_asked := false


## Live AI on with a key for text (D-8); the stub service counts (tests, CI). Off, replay, no relay
## or no text route: nothing is opened.
static func can_open(relay: AiRelay) -> bool:
	return relay != null and relay.enabled and not relay.mode in ["off", "replay"] and relay.route_for("text") != ""


## The crossing a digest belongs to: its begin clocks (a new commit begins a new digest).
static func crossing_id(view: Dictionary) -> String:
	var tau0: Variant = GalaxyMap.field_value(view, D + "time.tau0")
	var year0: Variant = GalaxyMap.field_value(view, D + "time.year0")
	if tau0 == null or year0 == null:
		return ""
	return "%s@%s" % [str(tau0), str(year0)]


## The ai_open fields: the question, the narration key, and the digest's fields in words and sim
## numbers (at most 8 context fields; strings or string lists). Formatting only: every value is a
## sim field of the view.
static func open_fields(view: Dictionary) -> Dictionary:
	var ctx := {"question": QUESTION, "narration": str(GalaxyMap.field_value(view, D + "narration.key"))}
	var leg: Variant = GalaxyMap.field_value(view, "review.leg")
	if leg != null and str(leg) != "":
		ctx["crossing"] = "to %s; %s days lived aboard; %s years passed at home" % [str(leg), str(GalaxyMap.field_value(view, D + "time.ship_days")), str(GalaxyMap.field_value(view, D + "time.earth_years"))]
	var line: Variant = GalaxyMap.field_value(view, D + "time.tier_line")
	if line != null:
		ctx["home"] = str(line).replace("%s", str(GalaxyMap.field_value(view, D + "time.years_at_home")))
	var counts: Variant = GalaxyMap.field_value(view, D + "crew.counts")
	if counts is Dictionary:
		var parts := PackedStringArray()
		for k: String in counts.keys():
			if float(counts[k]) > 0.0 and k != "days":
				parts.append("%s %s" % [k.replace("_", " "), str(counts[k])])
		ctx["crew"] = ", ".join(parts) if not parts.is_empty() else "the crew kept to their work"
	var moments: Variant = GalaxyMap.field_value(view, D + "crew.moments")
	if moments is Array and not moments.is_empty():
		ctx["moments"] = (moments as Array).map(func(m): return "%s: %s" % [str(m.get("name", "")), str(m.get("text", ""))])
	var media: Variant = GalaxyMap.field_value(view, D + "medium.media")
	if media is Array and not media.is_empty():
		ctx["medium"] = (media as Array).map(func(m): return str(m.get("name", "")).replace("_", " "))
	ctx["canon"] = CANON.duplicate()
	return {"emotions": EMOTIONS.duplicate(), "context": ctx}


## The crossing is over (the review's pages are the player's): ask once, when live AI may.
## True when a request was queued.
func maybe_open(view: Dictionary, relay: AiRelay, over: bool) -> bool:
	var id := crossing_id(view)
	if id != crossing:
		_reset(id)
	if not over or id == "" or state != "idle" or GalaxyMap.field_value(view, D + "narration.key") == null:
		return false
	# Without live AI nothing is asked and the authored lines stand; asked again on a later frame
	# (live AI switched on while the review is open still gets its one telling).
	if not can_open(relay) or not relay.open("text", "archive", ENTITY, open_fields(view)):
		return false
	_relay = relay
	state = "waiting"
	opened += 1
	return true


func _reset(id: String) -> void:
	crossing = id
	state = "idle"
	req = ""
	telling = ""
	voice_req = ""
	voice = {}
	_voice_asked = false


## True when an ai_request event is the telling's (its context carries the narration key).
static func is_narration(e: Dictionary) -> bool:
	return str(e.get("purpose", "")) == "archive" and e.get("context") is Dictionary and (e.context as Dictionary).has("narration")


## The sim's events for one step: the telling's request, its answer or fallback, then its voice.
func on_events(events: Array) -> void:
	for e in events:
		if not e is Dictionary:
			continue
		var k := str(e.get("k", ""))
		if k == "ai_request":
			if state == "waiting" and req.is_empty() and e.get("kind") == "text" and is_narration(e):
				req = str(e.get("req", ""))
			elif voice_req.is_empty() and e.get("kind") == "voice" and not req.is_empty() and str(e.get("line_req", "")) == req:
				voice_req = str(e.get("req", ""))
		elif k == "ai_accepted" and not req.is_empty() and str(e.get("req", "")) == req and e.get("kind") == "text" and state == "waiting":
			telling = ArchiveAsk.unmarked(str(e.get("text", "")))
			state = "told"
			_open_voice()
		elif k == "ai_accepted" and not voice_req.is_empty() and str(e.get("req", "")) == voice_req and e.get("kind") == "voice":
			voice = e
		elif k == "ai_fallback" and not req.is_empty() and str(e.get("req", "")) == req and state == "waiting":
			state = "authored" # the authored line stands


## Voice the telling once (the relay looks the voice key up in the cache first).
func _open_voice() -> void:
	if _relay == null or _voice_asked or req.is_empty():
		return
	_voice_asked = true
	if _relay.open("voice", "archive", ENTITY, {"line_req": req}):
		voiced += 1


## The words page 1 shows: the accepted telling, else the sim's authored crossing line.
func crossing_text(view: Dictionary) -> String:
	if state == "told" and crossing == crossing_id(view) and telling != "":
		return telling
	var a: Variant = GalaxyMap.field_value(view, D + "narration.crossing")
	return "" if a == null else str(a)


## The playable copy of the accepted voice (AiCache), or "" (none yet, or not on disk).
func voice_path(cache: AiCache) -> String:
	if voice.is_empty() or cache == null:
		return ""
	var e := cache.find_sha(str(voice.get("sha256", "")))
	if e.is_empty():
		return ""
	var pb: Dictionary = cache.playback(e)
	return str(pb.get("path", "")) if str(pb.get("error", "")) == "" else ""
