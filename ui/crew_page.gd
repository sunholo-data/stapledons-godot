class_name CrewPage
extends VBoxContainer
## R2-CREW C6 (design crew-integration.md §CI-4, AC10): the Crew page on the Voyage console.
## Decisions at consoles, information in the HUD (D-56). It shows the sim's `crew` section
## (protocol 2.9, SimBridge.parse_crew) and turns the captain's choices into crew intents
## (SimBridge.crew_intent), emitted on `intents` for the console to queue on the bridge. It never
## decides anything itself: every reaction comes from the sim (D-20).
##   per member: generated name (D-74) and role, stress / fatigue / trust bars, regard only when
##   low, current work, and the latest line (the template, then the AI words once accepted)
##   actions:    offer work (offer + ask, one press); start offered work, grant / deny relief and
##   switch consent / orders need a second press to confirm (no twitch, NT1)
## Portraits are stub portraits until the D-7 sets exist (the cast marks them pending).

signal intents(list: Array)

const CAST_DIR := "res://data/ai/cast"
const BAR_KEYS := ["stress", "fatigue"]
const LOW := Color(0.95, 0.6, 0.4)
const DIM := Color(0.62, 0.68, 0.8)
const STRAINED := 70.0 ## the pack's overextended threshold (scenario.json overextended.threshold)
const TEXT := Color(0.86, 0.9, 0.98)

var crew: Dictionary = {}
var roles: Dictionary = {}          ## entity_id -> role name from the cast ("The Medic")
var ai_text: Dictionary = {}        ## ai_req -> accepted AI words (set_ai_text)
var armed := ""                     ## the action awaiting its confirming press
var _serial := 0

func _init() -> void:
	name = "CrewPage"
	add_theme_constant_override("separation", 6)
	roles = load_roles(CAST_DIR)


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


func _build() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	if crew.is_empty():
		add_child(_label("No crew aboard yet.", 14, DIM))
		return
	var head := HBoxContainer.new()
	head.add_child(_label("Captaincy: %s" % str(crew.get("captaincy", "consent")), 14))
	var other := "orders" if str(crew.get("captaincy", "consent")) == "consent" else "consent"
	head.add_child(_button("Policy", "Switch to %s" % other, "policy:" + other))
	add_child(head)
	for m in crew.get("members", []):
		add_child(_member_row(m))
	for r in crew.get("reliefs", []):
		var row := HBoxContainer.new()
		row.add_child(_label("%s asks for relief." % display_name(str(r.get("author", ""))), 13, LOW))
		row.add_child(_button("Grant_" + str(r["id"]), "Grant relief", "relief:%s:true" % r["id"]))
		row.add_child(_button("Deny_" + str(r["id"]), "Deny relief", "relief:%s:false" % r["id"]))
		add_child(row)


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
	var who := _label("%s · %s" % [display_name(id), roles.get(id, id)], 14)
	who.custom_minimum_size = Vector2(170, 0)
	row.add_child(who)
	var ind: Dictionary = m.get("indicators", {})
	for k in BAR_KEYS:
		row.add_child(_bar(k, float(ind.get(k, 0))))
	if m.get("trust") != null:
		row.add_child(_bar("trust", float(m["trust"])))
	var work = m.get("work")
	var slot := HBoxContainer.new() # a fixed-width action slot, so the bars line up row to row
	slot.custom_minimum_size = Vector2(124, 0)
	slot.alignment = BoxContainer.ALIGNMENT_END
	if work is Dictionary:
		if str(work.get("status", "")) == "offered":
			slot.add_child(_button("Start_" + id, "Start the work", "start:" + str(work["task"])))
	else:
		slot.add_child(_button("Offer_" + id, "Offer work", "offer:" + id))
	row.add_child(slot)
	box.add_child(row)
	var notes := []
	if work is Dictionary:
		notes.append("Working on assigned work." if str(work.get("status", "")) == "working" else "Work offered, not yet started.")
	var line := latest_line(id)
	if not line.is_empty():
		notes.append("“%s”" % line)
	if not notes.is_empty():
		box.add_child(_label("  ".join(notes), 12, DIM))
	for low in m.get("regard_low", []):
		box.add_child(_label("Strained with %s." % display_name(str(low.get("to", ""))), 12, LOW))
	return box


## The member's latest line: the accepted AI words for its request, else the authored template.
func latest_line(id: String) -> String:
	var out := ""
	for l in crew.get("lines", []):
		if l.get("actor") == id:
			out = ai_text.get(str(l.get("ai_req", "")), str(l.get("text", "")))
	return out


## One press for an offer; a second press confirms start, relief and the captaincy switch.
func press(action: String) -> Array:
	if action.begins_with("offer:"):
		armed = ""
		return _emit(offer_intents(action.trim_prefix("offer:")))
	if armed != action:
		armed = action
		_build()
		return []
	armed = ""
	var parts := action.split(":")
	match parts[0]:
		"start":
			return _emit([SimBridge.crew_intent("crew_start", {"command": "start_task", "task": parts[1]})])
		"relief":
			return _emit([SimBridge.crew_intent("crew_relief", {"command": "resolve_relief", "id": parts[1], "release": parts[2] == "true"})])
		"policy":
			return _emit([SimBridge.crew_intent("crew_policy", {"command": "policy", "policy": parts[1]})])
	return []


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
