class_name CrewPage
extends VBoxContainer
## R2-CREW C6 (design crew-integration.md §CI-4, AC10): the Crew page, on the Crew console
## (crew-work W1, Mark 2026-10-14: "put it in its own console"; the Voyage console keeps a summary).
## Decisions at consoles, information in the HUD (D-56). It shows the sim's `crew` section
## (protocol 2.9, SimBridge.parse_crew) and turns the captain's choices into crew intents
## (SimBridge.crew_intent), emitted on `intents` for the console to queue on the bridge. It never
## decides anything itself: every reaction comes from the sim (D-20).
##   per member: generated name (D-74) and role, stress / fatigue / trust bars, regard only when
##   low, current work, and the latest line (the template, then the AI words once accepted)
##   actions:    offer work (offer + ask, one press); start offered work, grant / deny relief and
##   switch consent / orders need a second press to confirm (no twitch, NT1)
## Work cards (crew-work W1, Mark 2026-10-14: "I can offer work but no idea what I'm offering"):
##   each member's work by name, what it is for, how long it takes, what it needs from the ship and
##   what it costs them (data/crew/scenario.json, the synced pack the sim embeds); offered, waiting,
##   agreed, day k of n, finished; a refused start says why (on_refused). The ship's resources show
##   free and in use. Crew days pass as the ship travels.
## Portraits (trial, 2026-10-14): the website's concept portraits (data/crew/portraits, SOURCES),
##   one face per role until the D-7 per-person sets exist. A row shows each member's face; the call
##   panel at the top shows whoever spoke last, larger, with their words, like a video call in
##   stills. The face follows the speaker's latest reply (emotion_of), falling back to neutral.

signal intents(list: Array)

const CAST_DIR := "res://data/ai/cast"
const BAR_KEYS := ["stress", "fatigue"]
const LOW := Color(0.95, 0.6, 0.4)
const DIM := Color(0.62, 0.68, 0.8)
const STRAINED := 70.0 ## the pack's overextended threshold (scenario.json overextended.threshold)
const TEXT := Color(0.86, 0.9, 0.98)
const PORTRAIT_DIR := "res://data/crew/portraits"
## A reply's emotion, and the faces to try for it in order (D-7's eight emotions; the trial set
## has neutral for every role and loving and grieving for the medic).
## The reply's emotion: declining shows anger, a concern shows fear, asking to step back (or stress at
## the strained line) shows sadness, accepting shows happiness. A face missing that emotion falls back
## along its list (the medic has all eight since 2026-10-14; the others are neutral for now).
const STRAINED_LABELS := ["request_relief"]
const WARM_LABELS := ["accept"]
const LABEL_EMOTION := {"decline": "angry", "concern": "fearful"}
const FALLBACK := {"sad": ["sad", "grieving", "neutral"], "happy": ["happy", "loving", "neutral"], "angry": ["angry", "sad", "neutral"],
	"fearful": ["fearful", "sad", "grieving", "neutral"], "curious": ["curious", "neutral"], "loving": ["loving", "happy", "neutral"],
	"grieving": ["grieving", "sad", "neutral"], "neutral": ["neutral"]}
const SCENARIO := "res://data/crew/scenario.json"
## A work effect in words (crew_core indicator deltas), by indicator and sign.
const EFFECT_WORDS := {
	"fatigue": ["tiring", "restful"], "stress": ["stressful", "eases their stress"],
	"morale": ["lifts their morale", "lowers their morale"], "readiness": ["readies them", "unsettles them"],
	"observations": ["adds to the ship's observations", "loses observations"],
}
const NUMBER_WORDS := ["no", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten",
	"eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen", "twenty"]
const REPLY_WORDS := {
	"accept": "They agreed.", "decline": "They declined.", "concern": "They raised a concern first.",
	"defer": "They asked to wait.", "continue": "They're keeping at it.", "request_relief": "They asked to step back.",
}

var crew: Dictionary = {}
var roles: Dictionary = {}          ## entity_id -> role name from the cast ("The Medic")
var ai_text: Dictionary = {}        ## ai_req -> accepted AI words (set_ai_text)
var armed := ""                     ## the action awaiting its confirming press
var _serial := 0
var _faces: Dictionary = {}         ## portrait path -> Texture2D (or null when absent)
var work_info: Dictionary = {}      ## recipe id -> {name, purpose, duration, costs, effects} (scenario.json)
var resource_names: Dictionary = {} ## resource id -> name in words ("Archive compute slots")
var notices: Dictionary = {}        ## member id -> why their last action was refused (on_refused)
var _last_actor := ""               ## the member the last emitted intents were about

func _init() -> void:
	name = "CrewPage"
	add_theme_constant_override("separation", 6)
	roles = load_roles(CAST_DIR)
	var pack = JSON.parse_string(FileAccess.get_file_as_string(SCENARIO)) if FileAccess.file_exists(SCENARIO) else null
	if pack is Dictionary:
		for c in pack.get("crew", []):
			for w in c.get("work", []):
				work_info[str(w.get("id", ""))] = w
		for r in pack.get("resources", []):
			resource_names[str(r.get("id", ""))] = str(r.get("name", r.get("id", ""))).split(" (")[0]


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


## Show a crew section (empty: no crew aboard).
func show_crew(section: Dictionary) -> void:
	crew = section
	_build()


## An accepted AI line for a request (AiRelay's accepted text); the template is shown until then.
func set_ai_text(ai_req: String, text: String) -> void:
	ai_text[ai_req] = text
	_build()


## A tick's events (SimBridge.stepped): accepted AI text for a crew line replaces its template.
## Only requests the crew section names are taken, so other AI text (news, the Archive) is ignored.
func on_events(events: Array) -> void:
	var reqs := {}
	for l in crew.get("lines", []):
		reqs[str(l.get("ai_req", ""))] = true
	var changed := false
	for e in events:
		if e is Dictionary and e.get("k") == "ai_accepted" and e.get("kind") == "text" and reqs.has(str(e.get("req", ""))):
			ai_text[str(e["req"])] = str(e.get("text", ""))
			changed = true
	if changed:
		_build()


## A tick's refusals (SimBridge.last_refused) for the crew intents this page emitted: the member
## they were about gets a notice in words. A later accepted action clears it.
func on_refused(refused: Array) -> void:
	if _last_actor == "":
		return
	var why := ""
	for r in refused:
		var reason := str(r.get("reason", "")) if r is Dictionary else str(r)
		if reason.begins_with("crew:"):
			why = refusal_words(reason)
			break
	if why == "":
		notices.erase(_last_actor)
	else:
		notices[_last_actor] = why
	_last_actor = ""
	_build()


## A crew refusal in words: a blocked start names the resource and who holds it.
func refusal_words(reason: String) -> String:
	var parts := reason.trim_prefix("crew:").split(":")
	if parts.size() >= 3 and parts[0] == "blocked" and parts[1] == "insufficient_resource":
		var res := parts[2]
		var users := []
		for m in crew.get("members", []):
			var w = m.get("work")
			if w is Dictionary and str(w.get("status", "")) == "working":
				for c in work_info.get(str(w.get("recipe", "")), {}).get("costs", []):
					if str(c.get("resource", "")) == res and int(c.get("reserve", 0)) > 0:
						users.append(display_name(str(m["id"])))
		var holder := (" %s %s using them." % [" and ".join(users), "is" if users.size() == 1 else "are"]) if not users.is_empty() else ""
		return "Couldn't start: not enough %s free.%s" % [resource_names.get(res, res).to_lower(), holder]
	if parts.size() >= 2 and parts[0] == "blocked":
		return "Couldn't do that: %s." % parts[1].replace("_", " ")
	var host = JSON.parse_string(reason.trim_prefix("crew:")) if reason.trim_prefix("crew:").begins_with("{") else null
	if host is Dictionary and host.has("host"):
		return "Couldn't do that: %s." % str(host["host"]).trim_suffix(".")
	return "Couldn't do that (%s)." % reason.trim_prefix("crew:")


func _build() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	if crew.is_empty():
		add_child(_label("No crew aboard yet.", 14, DIM))
		return
	for h in crew.get("holds", []):
		add_child(_hold_card(h))
	var call := _call_panel()
	if call != null:
		add_child(call)
	var head := HBoxContainer.new()
	head.add_child(_label("Captaincy: %s" % str(crew.get("captaincy", "consent")), 14))
	var other := "orders" if str(crew.get("captaincy", "consent")) == "consent" else "consent"
	head.add_child(_button("Policy", "Switch to %s" % other, "policy:" + other))
	add_child(head)
	add_child(_auto_row())
	add_child(_resources_row())
	for m in crew.get("members", []):
		add_child(_member_row(m))


## C8: a hold is a moment the auto-run hands to the captain. The card says who and what in words,
## and Resume (confirmed) hands the crew back to the standing orders; the choices themselves are
## the page's usual actions (relief, start, offer) or the captaincy switch.
const HOLD_WORDS := {
	"breakdown": "is close to breaking down.",
	"trust_floor": "has lost trust in you.",
	"refusal_under_orders": "refused an order.",
	"major": "is shaken by news the whole ship heard.",
	"argument": "is arguing with the crew over what the ship lost.",
	"uncovered": "has raised something only you can answer.",
}
func _hold_card(h: Dictionary) -> Control:
	var box := VBoxContainer.new()
	box.name = "Hold_" + str(h.get("id", ""))
	var who := display_name(str(h.get("actor", ""))) if str(h.get("actor", "")) != "" else "The crew"
	box.add_child(_label("Needs you: %s %s" % [who, HOLD_WORDS.get(str(h.get("rule", "")), "needs the captain.")], 15, LOW))
	var row := HBoxContainer.new()
	row.add_child(_label("Auto-run waits until you resume it.", 12, DIM))
	row.add_child(_button("Resume_" + str(h.get("id", "")), "Resume auto-run", "resume:" + str(h.get("id", ""))))
	box.add_child(row)
	return box


## C8 presets: off (every decision yours), critical only (the default when on), hands on.
const PRESETS := {"off": "Off", "critical_only": "Critical moments only", "hands_on": "Hands on"}
func _auto_row() -> Control:
	var row := HBoxContainer.new()
	row.name = "AutoRun"
	var cur := str(crew.get("auto", "off"))
	row.add_child(_label("Auto-run: %s" % PRESETS.get(cur, cur), 13))
	for p in ["critical_only", "hands_on", "off"]:
		if p != cur:
			row.add_child(_button("Auto_" + p, PRESETS[p], "orders:" + p))
	return row


func display_name(id: String) -> String:
	for m in crew.get("members", []):
		if m.get("id") == id and typeof(m.get("name")) == TYPE_STRING and m["name"] != id:
			return m["name"]
	return roles.get(id, id)


func _member_row(m: Dictionary) -> Control:
	var box := VBoxContainer.new()
	box.name = "Member_" + str(m["id"])
	box.add_theme_constant_override("separation", 2)
	var id := str(m["id"])
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.add_child(_face("Portrait_" + id, id, emotion_of(id), 40))
	var who := _label("%s · %s" % [display_name(id), roles.get(id, id)], 14)
	who.custom_minimum_size = Vector2(170, 0)
	row.add_child(who)
	var ind: Dictionary = m.get("indicators", {})
	for k in BAR_KEYS:
		row.add_child(_bar(k, float(ind.get(k, 0))))
	if m.get("trust") != null:
		row.add_child(_bar("trust", float(m["trust"])))
	box.add_child(row)
	box.add_child(_work_card(m))
	var line := latest_line(id)
	if not line.is_empty():
		box.add_child(_label("“%s”" % line, 12, DIM))
	for r in crew.get("reliefs", []): # a relief request sits on the asker's card
		if str(r.get("author", "")) == id:
			var rr := HBoxContainer.new()
			rr.add_child(_label("%s asks to step back from this work." % display_name(id), 13, LOW))
			rr.add_child(_button("Grant_" + str(r["id"]), "Grant relief", "relief:%s:true" % r["id"]))
			rr.add_child(_button("Deny_" + str(r["id"]), "Deny relief", "relief:%s:false" % r["id"]))
			box.add_child(rr)
	if notices.has(id):
		box.add_child(_label(str(notices[id]), 12, LOW))
	for low in m.get("regard_low", []):
		box.add_child(_label("Strained with %s." % display_name(str(low.get("to", ""))), 12, LOW))
	return box


## A member's work in words: what it is and costs before it is offered; offered (waiting for their
## answer, or their reply and Start); day k of n while working; the last finished work.
func _work_card(m: Dictionary) -> Control:
	var id := str(m["id"])
	var card := VBoxContainer.new()
	card.name = "Work_" + id
	card.add_theme_constant_override("separation", 1)
	var work = m.get("work")
	var recipe := str(work.get("recipe", "")) if work is Dictionary else "work_" + id
	var info: Dictionary = work_info.get(recipe, {})
	var title := str(info.get("name", "their work"))
	var row := HBoxContainer.new()
	if not (work is Dictionary):
		row.add_child(_label(title, 13))
		row.add_child(_button("Offer_" + id, "Offer this work", "offer:" + id))
		card.add_child(row)
		card.add_child(_label(work_terms(info), 12, DIM))
		var done = m.get("done")
		if done is Dictionary:
			card.add_child(_label("Last finished: %s." % str(work_info.get(str(done.get("recipe", "")), {}).get("name", "their work")), 12, DIM))
	elif str(work.get("status", "")) == "offered":
		var waiting: bool = crew.get("requests", []).any(func(q): return q.get("actor") == id)
		row.add_child(_label("Offered: %s. %s" % [title, "Waiting for their answer." if waiting else REPLY_WORDS.get(last_label(id), "")], 13))
		row.add_child(_button("Start_" + id, "Start the work", "start:" + str(work["task"])))
		card.add_child(row)
		card.add_child(_label(work_terms(info), 12, DIM))
	else:
		var n := maxi(1, int(work.get("due", 0)) - int(work.get("started", 0)))
		var k := clampi(int(crew.get("turn", 0)) - int(work.get("started", 0)) + 1, 1, n)
		card.add_child(_label("Working on %s: day %s of %s." % [title, words(k), words(n)], 13))
		card.add_child(_label("Crew days pass as the ship travels.", 12, DIM))
	return card


## A small count in words (D-21: the page shows no digits); beyond twenty, "many".
static func words(n: int) -> String:
	return NUMBER_WORDS[n] if n >= 0 and n < NUMBER_WORDS.size() else "many"


## What a piece of work is for, how long, what it needs from the ship and what it costs the person.
func work_terms(info: Dictionary) -> String:
	if info.is_empty():
		return ""
	var needs := []
	for c in info.get("costs", []):
		var nm: String = str(resource_names.get(str(c.get("resource", "")), str(c.get("resource", "")))).to_lower()
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


## The ship's resources: free now out of what the ship holds, and what work has used up.
func _resources_row() -> Control:
	var parts := []
	for r in crew.get("resources", []):
		var free := int(r.get("available", 0))
		var held := int(r.get("reserved", 0))
		parts.append("%s: %s free of %s" % [resource_names.get(str(r.get("id", "")), str(r.get("id", ""))), words(free), words(free + held)])
	var l := _label("Ship: " + " · ".join(parts), 12, DIM)
	l.name = "Resources"
	return l


## The member's latest reply label ("accept", "concern", ...), or "".
func last_label(id: String) -> String:
	var out := ""
	for l in crew.get("lines", []):
		if l.get("actor") == id:
			out = str(l.get("label", ""))
	return out


## The member's latest line: the accepted AI words for its request, else the authored template.
func latest_line(id: String) -> String:
	var out := ""
	for l in crew.get("lines", []):
		if l.get("actor") == id:
			out = ai_text.get(str(l.get("ai_req", "")), str(l.get("text", "")))
	return out


## The call panel: the crew member the captain is facing, larger, with their latest words. During
## a hold it is the person who needs the captain (strained); otherwise the latest line's speaker.
## None before anyone speaks.
func _call_panel() -> Control:
	var lines: Array = crew.get("lines", [])
	var holds: Array = crew.get("holds", [])
	var id := ""
	if not holds.is_empty() and str(holds[0].get("actor", "")) != "":
		id = str(holds[0]["actor"])
	elif not lines.is_empty():
		id = str(lines[lines.size() - 1].get("actor", ""))
	if id == "":
		return null
	var emotion := "sad" if not holds.is_empty() and str(holds[0].get("actor", "")) == id else emotion_of(id)
	var row := HBoxContainer.new()
	row.name = "Call"
	row.add_theme_constant_override("separation", 12)
	row.add_child(_face("CallPortrait", id, emotion, 112))
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_child(_label("%s · %s" % [display_name(id), roles.get(id, id)], 15))
	var line := latest_line(id)
	var said := _label("“%s”" % line if line != "" else "…", 14)
	said.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	said.custom_minimum_size = Vector2(220, 0)
	words.add_child(said)
	row.add_child(words)
	return row


## The emotion a member's face shows: strained after asking for relief, declining or raising a
## concern, or when stress is at the strained line; warm after accepting; else neutral.
func emotion_of(id: String) -> String:
	var label := ""
	for l in crew.get("lines", []):
		if l.get("actor") == id:
			label = str(l.get("label", ""))
	var stress := 0.0
	for m in crew.get("members", []):
		if m.get("id") == id:
			stress = float(m.get("indicators", {}).get("stress", 0))
	if LABEL_EMOTION.has(label):
		return LABEL_EMOTION[label]
	if STRAINED_LABELS.has(label) or stress >= STRAINED:
		return "sad"
	if WARM_LABELS.has(label):
		return "happy"
	return "neutral"


## The portrait file for a role and emotion: the first in the emotion's fallback list that loads
## ("" when the role has no face yet).
func portrait_path(id: String, emotion: String) -> String:
	for e in FALLBACK.get(emotion, ["neutral"]):
		var path := PORTRAIT_DIR.path_join("%s_%s.png" % [id, e])
		if not _faces.has(path):
			_faces[path] = CaptainAvatar.make_texture(path) # imported when the editor has seen it, else the raw PNG
		if _faces[path] != null:
			return path
	return ""


func portrait(id: String, emotion: String) -> Texture2D:
	var path := portrait_path(id, emotion)
	return _faces[path] if path != "" else null


func _face(node_name: String, id: String, emotion: String, px: int) -> Control:
	var t := TextureRect.new()
	t.name = node_name
	t.texture = portrait(id, emotion)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(px, px)
	t.tooltip_text = emotion
	return t


## One press for an offer; a second press confirms start, relief and the captaincy switch.
func press(action: String) -> Array:
	if action.begins_with("offer:"):
		armed = ""
		_last_actor = action.trim_prefix("offer:")
		return _emit(offer_intents(_last_actor))
	if armed != action:
		armed = action
		_build()
		return []
	armed = ""
	var parts := action.split(":")
	_last_actor = actor_of(parts)
	match parts[0]:
		"start":
			return _emit([SimBridge.crew_intent("crew_start", {"command": "start_task", "task": parts[1]})])
		"relief":
			return _emit([SimBridge.crew_intent("crew_relief", {"command": "resolve_relief", "id": parts[1], "release": parts[2] == "true"})])
		"policy":
			return _emit([SimBridge.crew_intent("crew_policy", {"command": "policy", "policy": parts[1]})])
		"orders":
			return _emit([SimBridge.crew_intent("crew_orders", {"command": "orders", "preset": parts[1]})])
		"resume":
			return _emit([SimBridge.crew_intent("crew_resume", {"command": "resume", "hold": parts[1]})])
	return []


## The member an action is about: a start's worker, a relief's author ("" for ship-wide choices).
func actor_of(parts: PackedStringArray) -> String:
	match parts[0]:
		"start":
			for m in crew.get("members", []):
				var w = m.get("work")
				if w is Dictionary and str(w.get("task", "")) == parts[1]:
					return str(m["id"])
		"relief":
			for r in crew.get("reliefs", []):
				if str(r.get("id", "")) == parts[1]:
					return str(r.get("author", ""))
	return ""


## Offer the member's work and ask at once: the crew member answers in the same tick (authored).
func offer_intents(id: String) -> Array:
	_serial += 1
	var tag := "c%d-%d" % [int(crew.get("turn", 0)), _serial]
	var task := "t" + tag + "-" + id
	return [SimBridge.crew_intent("crew_offer", {"command": "offer", "worker": id, "recipe": "work_" + id, "id": task}),
		SimBridge.crew_intent("crew_ask", {"command": "ask", "actor": id, "task": task, "id": "r" + tag + "-" + id})]


func _emit(list: Array) -> Array:
	intents.emit(list)
	_build()
	return list


func _button(node_name: String, text: String, action: String) -> Button:
	var b := Button.new()
	b.name = node_name
	b.focus_mode = Control.FOCUS_NONE
	b.text = ("Confirm: " + text) if armed == action else text
	b.pressed.connect(func() -> void: press(action))
	return b


func _bar(key: String, value: float) -> Control:
	var box := VBoxContainer.new()
	box.name = "Bar_" + key
	var cap := _label(key, 11, DIM)
	cap.autowrap_mode = TextServer.AUTOWRAP_OFF
	cap.custom_minimum_size = Vector2.ZERO
	box.add_child(cap)
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.value = value
	bar.show_percentage = false # numbers come from the sim's fields only (D-21); the bar is the readout
	bar.custom_minimum_size = Vector2(56, 8)
	if key != "trust" and value >= STRAINED: # overextended (crew_core's threshold): warm, so it reads at a glance
		var fill := StyleBoxFlat.new()
		fill.bg_color = LOW
		bar.add_theme_stylebox_override("fill", fill)
	box.add_child(bar)
	return box


func _label(text: String, size := 14, color := TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL # a wrapping label needs width: in a row it takes the rest
	l.custom_minimum_size = Vector2(120, 0)
	return l
