class_name CrewPage
extends RefCounted
## The crew's words and faces, shared by every view of the crew: the Crew console (CrewConsole,
## R2-CREW-CONSOLE-V2), the Voyage console's summary and the crossing review (R2-INTERLUDE).
## Static and pure: the scenario pack's work, the cast's roles, the D-7 portraits with their
## fallback list, small counts in words (D-21) and refusals in words. Until R2-CREW-CONSOLE-V2 this
## was the Crew page itself (R2-CREW C6, crew-work W1); its layout moved to ui/crew_console.gd.
##   work cards (crew-work W1): each member's work by name, what it is for, how long it takes, what
##   it needs from the ship and what it costs them (data/crew/scenario.json, the synced pack the
##   sim embeds).
##   portraits (D-7): data/crew/portraits, one face per role and emotion; a face missing an emotion
##   falls back along FALLBACK. Which emotion is the sim's (protocol 2.10 crew.members[].emotion).

const CAST_DIR := "res://data/ai/cast"
const PORTRAIT_DIR := "res://data/crew/portraits"
const SCENARIO := "res://data/crew/scenario.json"
## The faces to try for an emotion, in order (D-7's eight emotions; the trial set has neutral for
## every role and all eight for the medic).
const FALLBACK := {"sad": ["sad", "grieving", "neutral"], "happy": ["happy", "loving", "neutral"], "angry": ["angry", "sad", "neutral"],
	"fearful": ["fearful", "sad", "grieving", "neutral"], "curious": ["curious", "neutral"], "loving": ["loving", "happy", "neutral"],
	"grieving": ["grieving", "sad", "neutral"], "neutral": ["neutral"]}
const OFFER_PENDING := "Offer sent. Waiting for their answer."
## A work effect in words (crew_core indicator deltas), by indicator and sign.
const EFFECT_WORDS := {
	"fatigue": ["tiring", "restful"], "stress": ["stressful", "eases their stress"],
	"morale": ["lifts their morale", "lowers their morale"], "readiness": ["readies them", "unsettles them"],
	"observations": ["adds to the ship's observations", "loses observations"],
}
const NUMBER_WORDS := ["no", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten",
	"eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen", "twenty"]
## C8 presets: off (every decision yours), critical only (the default when on), hands on.
const PRESETS := {"off": "Off", "critical_only": "Critical moments only", "hands_on": "Hands on"}

static var _face_cache: Dictionary = {} ## portrait path -> Texture2D (or null when absent)
static var _roles: Dictionary = {}
static var _work: Dictionary = {}
static var _resources: Dictionary = {}
static var _strained := 70.0
static var _loaded := false


## {entity_id: role name} from every cast file (the role name is the fallback display name).
static func load_roles(dir: String) -> Dictionary:
	var out := {}
	for f in DirAccess.get_files_at(dir):
		if not f.ends_with(".json"):
			continue
		var c = JSON.parse_string(FileAccess.get_file_as_string(dir.path_join(f)))
		if c is Dictionary and typeof(c.get("entity_id")) == TYPE_STRING:
			out[c["entity_id"]] = str(c.get("name", c["entity_id"]))
	return out


static func _load() -> void:
	if _loaded:
		return
	_loaded = true
	_roles = load_roles(CAST_DIR)
	var pack = JSON.parse_string(FileAccess.get_file_as_string(SCENARIO)) if FileAccess.file_exists(SCENARIO) else null
	if pack is Dictionary:
		for c in pack.get("crew", []):
			for w in c.get("work", []):
				_work[str(w.get("id", ""))] = w
		for r in pack.get("resources", []):
			_resources[str(r.get("id", ""))] = str(r.get("name", r.get("id", ""))).split(" (")[0]
		var over = pack.get("overextended")
		if over is Dictionary and over.has("threshold"):
			_strained = float(over["threshold"])


## The pack's overextended threshold (scenario.json overextended.threshold): an indicator at or
## above it shows as strained.
static func strained() -> float:
	_load()
	return _strained


## The cast's role name ("The Medic"), or the id.
static func role(id: String) -> String:
	_load()
	return str(_roles.get(id, id))


## {recipe id: {name, purpose, duration, costs, effects}} from the scenario pack.
static func work_info(recipe: String) -> Dictionary:
	_load()
	return _work.get(recipe, {})


static func work_name(recipe: String) -> String:
	return str(work_info(recipe).get("name", ""))


## A resource's name in words ("Archive compute slots").
static func resource_name(id: String) -> String:
	_load()
	return str(_resources.get(id, id))


## A member's generated name (D-74), else their role.
static func display_name(crew: Dictionary, id: String) -> String:
	for m in crew.get("members", []):
		if m is Dictionary and m.get("id") == id and typeof(m.get("name")) == TYPE_STRING and m["name"] != id:
			return m["name"]
	return role(id)


## A hold in words, after the crew member's name: the sim's (protocol 2.10 crew.holds[].line,
## sim/protocol_crew.ail holdLine; one source for the console and the crossing review's Hold page).
static func hold_text(who: String, h: Dictionary) -> String:
	var line := str(h.get("line", ""))
	return "%s %s" % [who, line] if line != "" else who + "."


## A small count in words (D-21: the crew's text shows no digits); beyond twenty, "many".
static func words(n: int) -> String:
	return NUMBER_WORDS[n] if n >= 0 and n < NUMBER_WORDS.size() else "many"


## What a piece of work is for, how long, what it needs from the ship and what it costs the person.
static func work_terms(info: Dictionary) -> String:
	if info.is_empty():
		return ""
	var needs := []
	for c in info.get("costs", []):
		var nm: String = resource_name(str(c.get("resource", ""))).to_lower()
		var n := maxi(int(c.get("reserve", 0)), int(c.get("consume", 0)))
		if nm.ends_with("s") and not nm.ends_with("ss"): # a counted resource ("archive compute slots"): "one archive compute slot"
			nm = (words(n) + " " + (nm.trim_suffix("s") if n == 1 else nm)) if n > 0 else nm
		needs.append(nm + (" (used up)" if int(c.get("consume", 0)) > 0 else ""))
	var effects := []
	for k in info.get("effects", {}):
		var v := float(info["effects"][k])
		if v != 0.0 and EFFECT_WORDS.has(k):
			effects.append(EFFECT_WORDS[k][0 if v > 0.0 else 1])
	var days := int(info.get("duration", 0))
	var cost := ", ".join(effects) if not effects.is_empty() else "no cost to them"
	return "%s Takes %s day%s. Needs %s. %s." % [str(info.get("purpose", "")), words(days), "" if days == 1 else "s",
		", ".join(needs) if not needs.is_empty() else "nothing from the ship", cost.left(1).to_upper() + cost.substr(1)]


## The same, briefly, for a card already under way: how long, what it needs, what it costs them.
static func work_brief(info: Dictionary) -> String:
	if info.is_empty():
		return ""
	var needs := []
	for c in info.get("costs", []):
		var nm: String = resource_name(str(c.get("resource", ""))).to_lower()
		var n := maxi(int(c.get("reserve", 0)), int(c.get("consume", 0)))
		if nm.ends_with("s") and not nm.ends_with("ss"):
			nm = (words(n) + " " + (nm.trim_suffix("s") if n == 1 else nm)) if n > 0 else nm
		needs.append(nm)
	var effects := []
	for k in info.get("effects", {}):
		var v := float(info["effects"][k])
		if v != 0.0 and EFFECT_WORDS.has(k):
			effects.append(EFFECT_WORDS[k][0 if v > 0.0 else 1])
	var days := int(info.get("duration", 0))
	return " · ".join(["Takes %s day%s" % [words(days), "" if days == 1 else "s"], ", ".join(needs) if not needs.is_empty() else "nothing from the ship", ", ".join(effects) if not effects.is_empty() else "no cost to them"])


## A resource's short name for the gauges ("compute").
const SHORT_RESOURCE := {"mass": "mass", "power": "power", "compute": "compute", "signal": "antenna"}
static func resource_short(id: String) -> String:
	return str(SHORT_RESOURCE.get(id, resource_name(id).to_lower()))


## A crew refusal in words: a blocked start names the resource and who holds it.
static func refusal_words(reason: String, crew: Dictionary) -> String:
	var parts := reason.trim_prefix("crew:").split(":")
	if parts.size() >= 3 and parts[0] == "blocked" and parts[1] == "insufficient_resource":
		var res := parts[2]
		var users := []
		for m in crew.get("members", []):
			var w = m.get("work")
			if w is Dictionary and str(w.get("status", "")) == "working":
				for c in work_info(str(w.get("recipe", ""))).get("costs", []):
					if str(c.get("resource", "")) == res and int(c.get("reserve", 0)) > 0:
						users.append(display_name(crew, str(m["id"])))
		var holder := (" %s %s using them." % [" and ".join(users), "is" if users.size() == 1 else "are"]) if not users.is_empty() else ""
		return "Couldn't start: not enough %s free.%s" % [resource_name(res).to_lower(), holder]
	if parts.size() >= 2 and parts[0] == "blocked" and parts[1] == "altered_duplicate":
		return "Couldn't do that: it repeated an earlier request. Try again."
	if parts.size() >= 2 and parts[0] == "blocked":
		return "Couldn't do that: %s." % parts[1].replace("_", " ")
	var host = JSON.parse_string(reason.trim_prefix("crew:")) if reason.trim_prefix("crew:").begins_with("{") else null
	if host is Dictionary and str(host.get("host", "")) == "request capacity/id/clock":
		return "Couldn't ask them: that question was already asked, or too many are waiting for answers."
	if host is Dictionary and host.has("host"):
		return "Couldn't do that: %s." % str(host["host"]).trim_suffix(".")
	return "Couldn't do that (%s)." % reason.trim_prefix("crew:")


## The member a crew intent is about: an offer's worker, an ask's actor, a start's or a reply's.
static func intent_actor(intent: Dictionary, crew: Dictionary) -> String:
	var c = JSON.parse_string(str(intent.get("line", "")))
	if not (c is Dictionary):
		return ""
	if c.has("worker"):
		return str(c["worker"])
	if c.has("actor"):
		return str(c["actor"])
	match str(c.get("command", "")):
		"start_task":
			for m in crew.get("members", []):
				if m.get("work") is Dictionary and str(m["work"].get("task", "")) == str(c.get("task", "")):
					return str(m["id"])
		"resolve_relief":
			for r in crew.get("reliefs", []):
				if str(r.get("id", "")) == str(c.get("id", "")):
					return str(r.get("author", ""))
		"captain_reply":
			for q in crew.get("concerns", []):
				if str(q.get("issue", "")) == str(c.get("issue", "")):
					return str(q.get("actor", ""))
		"resume":
			for h in crew.get("holds", []):
				if str(h.get("id", "")) == str(c.get("hold", "")):
					return str(h.get("actor", ""))
	return ""


## The portrait file for a role and emotion: the first in the emotion's fallback list that loads
## ("" when the role has no face yet). One cache, so a face is one texture wherever it is shown.
static func face_path(id: String, emotion: String, portrait_dir: String = PORTRAIT_DIR) -> String:
	for e in FALLBACK.get(emotion, ["neutral"]):
		var path := portrait_dir.path_join("%s_%s.png" % [id, e])
		if not _face_cache.has(path):
			_face_cache[path] = CaptainAvatar.make_texture(path) # imported when the editor has seen it, else the raw PNG
		if _face_cache[path] != null:
			return path
	return ""


static func face(id: String, emotion: String) -> Texture2D:
	var path := face_path(id, emotion)
	return _face_cache[path] if path != "" else null
