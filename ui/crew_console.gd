class_name CrewConsole
extends VBoxContainer
## R2-CREW-CONSOLE-V2 V3 (design crew-console-v2.md §V3-§V5, §V7): the Crew console as an internal
## videocom. Decisions at consoles, information in the HUD (D-56); the page decides nothing (D-20):
## every member's state is the sim's (protocol 2.11 crew.members[].work_state), coloured, iconed and
## worded by CrewPalette; what each state allows is CrewConsoleModel's.
##   the board  the roster, whose move first, one chip and one quick action per row; the ship
##              default (Ask or Order) and auto-run in the header strip; the ship's free resources
##              as dot gauges; the legend
##   the call   two panels: the call window (a large portrait at the sim's emotion, their words, their
##              bars) and the work and decisions beside it (the work card, the next legal actions
##              first, a disabled action with its reason, Ask or Order inline, the mini-roster)
## Every decision arms on the first press and is sent on the second (no twitch, NT1). Once an intent
## about a member is queued, all their actions wait until the tick that carries it is answered (the
## `sending` state). A call opens when the captain picks someone, or on an incoming concern or hold
## when no call is open and nothing is armed (OQ4); otherwise the row pulses. It never closes on a
## timer. Every Label is a DisplayBinding or ComposedBinding (V7): sim fields, or the client's own
## call state under client.crew.*.

signal intents(list: Array)
signal title_changed(text: String)

const TITLE_BOARD := "Crew console · the crew and their work"
const TITLE_CALL := "Crew console · on the internal videocom"
const ROW_H := 64.0
const FACE_ROW := 56.0
const PORTRAIT := 240.0
const CALL_W := 430.0
const DECIDE_W := 470.0
const SHORT_PRESET := {"off": "Off", "critical_only": "Critical only", "hands_on": "Hands on"}

var crew: Dictionary = {}
var call_id := ""            ## the member on the call ("" is the board)
var opened_by := ""          ## "select" or "incoming"
var armed := ""              ## the decision awaiting its confirming press
var sending: Dictionary = {} ## member id -> true while an intent about them is queued
var how: Dictionary = {}     ## member id -> "consent" | "orders" (the inline Ask or Order; ship default when absent)
var pulse: Dictionary = {}   ## member id -> true: something came in while a call or a confirm was open
var notices: Dictionary = {} ## member id -> why their last action was refused, in words
var said: Dictionary = {}    ## member id -> the captain's last words to them ("You: ...")
var ai_text: Dictionary = {} ## ai_req -> accepted AI words
var help: Dictionary = {}    ## V7b: rule key -> true while its full text is open ("?"); "legend" for the board's legend
var focus_action := ""       ## V6: the focused control's action (the console keeps its own focus ring)
static var _serial := 0      ## ids count across every console in the process (a reused id is refused)
var _states: Dictionary = {}
var _title := ""


func _init() -> void:
	name = "CrewConsole"
	add_theme_constant_override("separation", 6)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL


# ------------------------------------------------------------------ the sim's side

## Show a crew section (empty: no crew aboard). A member who newly needs the captain opens their
## call when nothing is open or armed; otherwise their row pulses (OQ4).
func show_crew(section: Dictionary) -> void:
	var before := _states.duplicate()
	crew = section
	_states = {}
	var incoming := []
	for m in crew.get("members", []):
		if not m is Dictionary:
			continue
		var id := str(m.get("id", ""))
		var s := str(m.get("work_state", "free"))
		_states[id] = s
		if not before.is_empty() and CrewConsoleModel.needs_you(s) and before.get(id, "") != s:
			incoming.append(id)
	if call_id != "" and CrewConsoleModel.member(crew, call_id).is_empty():
		call_id = ""
	for id in incoming:
		if call_id == "" and armed == "":
			_open(id, "incoming")
		elif id != call_id:
			pulse[id] = true
	_build()


## An accepted AI line for a request (AiRelay's accepted text); the template is shown until then.
func set_ai_text(ai_req: String, text: String) -> void:
	ai_text[ai_req] = text
	_build()


## A tick's events (SimBridge.stepped): accepted AI text for a crew line replaces its template.
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


## The answer to the tick that carried this console's intents (SimBridge.queued_refused, with the
## intents it carried): every member they were about is answered, so their `sending` lock lifts;
## a refused one says why, in words, on that member (never silent).
func on_refused(refused: Array, carried: Array = []) -> void:
	var about := {}
	for i in carried:
		if i is Dictionary:
			about[CrewPage.intent_actor(i, crew)] = true
	if carried.is_empty():
		about = sending.duplicate()
	for id in about:
		sending.erase(id)
		notices.erase(id)
	for r in refused:
		var reason := str(r.get("reason", "")) if r is Dictionary else str(r)
		if not reason.begins_with("crew:"):
			continue
		var who := CrewPage.intent_actor(r["intent"], crew) if r is Dictionary and r.get("intent") is Dictionary else ""
		if who != "" and not notices.has(who):
			notices[who] = CrewPage.refusal_words(reason, crew)
			sending.erase(who)
	_build()


# ------------------------------------------------------------------ the captain's side

## Open a member's call (picking them, or an incoming message). Not a decision: no intent.
func open_call(id: String) -> void:
	_open(id, "select")
	_build()


func _open(id: String, by: String) -> void:
	if call_id != id:
		armed = ""
		focus_action = CrewConsoleModel.first_focus(CrewConsoleModel.member(crew, id), crew, _client())
	call_id = id
	opened_by = by
	pulse.erase(id)


func end_call() -> void:
	if call_id != "":
		focus_action = "call:" + call_id
	call_id = ""
	armed = ""
	_build()


## The captain's press. Navigation (call, end_call, how, quick) never emits; every decision arms on
## the first press and is sent on the second. A member whose intent is still on its way takes none.
func press(action: String) -> Array:
	var kind := action.get_slice(":", 0)
	match kind:
		"call":
			open_call(action.get_slice(":", 1))
			return []
		"end_call":
			end_call()
			return []
		"how":
			how[action.get_slice(":", 1)] = action.get_slice(":", 2)
			if armed.begins_with("offer:" + action.get_slice(":", 1)):
				armed = ""
			_build()
			return []
		"help": # V7b: a rule's full words, or the board's legend (no intent)
			var k := action.get_slice(":", 1)
			if help.has(k): help.erase(k)
			else: help[k] = true
			_build()
			return []
		"quick":
			var id := action.get_slice(":", 1)
			_open(id, "select")
			var sub := action.substr(("quick:%s:" % id).length())
			if sub != "" and not sending.has(id):
				armed = sub
			_build()
			return []
	var who := actor_of(action)
	if who != "" and sending.has(who):
		return []
	if armed != action:
		armed = action
		_build()
		return []
	armed = ""
	var list := intents_for(action)
	if list.is_empty():
		_build()
		return []
	if who != "":
		sending[who] = true
		notices.erase(who)
		said[who] = captain_words(action)
	intents.emit(list)
	_build()
	return list


## The member a decision is about ("" for the ship-wide ones: the ship default and auto-run).
func actor_of(action: String) -> String:
	var parts := action.split(":")
	match parts[0]:
		"offer":
			return parts[1]
		"start", "order":
			for m in crew.get("members", []):
				if m.get("work") is Dictionary and str(m["work"].get("task", "")) == parts[1]:
					return str(m["id"])
		"relief":
			for r in crew.get("reliefs", []):
				if str(r.get("id", "")) == parts[1]:
					return str(r.get("author", ""))
		"reply":
			for q in crew.get("concerns", []):
				if str(q.get("issue", "")) == parts[1]:
					return str(q.get("actor", ""))
		"resume":
			for h in crew.get("holds", []):
				if str(h.get("id", "")) == parts[1]:
					return str(h.get("actor", ""))
		"standdown":
			for m in crew.get("members", []):
				if m is Dictionary and str(m.get("stand_down", "")) == parts[1]:
					return str(m["id"])
	return ""


## The crew intents a confirmed decision sends.
func intents_for(action: String) -> Array:
	var parts := action.split(":")
	match parts[0]:
		"offer":
			return offer_intents(parts[1], "now" if CrewConsoleModel.how_of(crew, parts[1], _client()) == "orders" else "on_accept")
		"start":
			return [SimBridge.crew_intent("crew_start", {"command": "start_task", "task": parts[1]})]
		"order":
			return [SimBridge.crew_intent("crew_start", {"command": "start_task", "task": parts[1]}, {"as": "orders"})]
		"relief":
			return [SimBridge.crew_intent("crew_relief", {"command": "resolve_relief", "id": parts[1], "release": parts[2] == "true"})]
		"policy":
			return [SimBridge.crew_intent("crew_policy", {"command": "policy", "policy": parts[1]})]
		"orders":
			return [SimBridge.crew_intent("crew_orders", {"command": "orders", "preset": parts[1]})]
		"resume":
			return [SimBridge.crew_intent("crew_resume", {"command": "resume", "hold": parts[1]})]
		"reply":
			return reply_intents(parts[1], parts[2])
		"standdown": # V8 (crew_core 0.6): let them rest, or ask them to carry on
			return [SimBridge.crew_intent("crew_stand_down", {"command": "resolve_stand_down", "id": parts[1], "release": parts[2] == "true"})]
	return []


## Offer the member's work and ask at once (they answer in the same tick); `start` says when the
## work starts (2.11: on_accept for Ask, now for Order).
func offer_intents(id: String, start := "") -> Array:
	_serial += 1
	var tag := "c%d-%d-%d" % [int(crew.get("turn", 0)), int(crew.get("revision", 0)), _serial]
	var task := "t" + tag + "-" + id
	return [SimBridge.crew_intent("crew_offer", {"command": "offer", "worker": id, "recipe": "work_" + id, "id": task}, {"start": start} if start != "" else {}),
		SimBridge.crew_intent("crew_ask", {"command": "ask", "actor": id, "task": task, "id": "r" + tag + "-" + id})]


## The captain's reply to a concern (crew_core captain_reply) at the crew's tick and revision: the
## suggested words for an approach, or Insist in the game's own words (OQ5).
func reply_intents(issue: String, approach: String) -> Array:
	for q in crew.get("concerns", []):
		if str(q.get("issue", "")) != issue:
			continue
		var text := CrewConsoleModel.INSIST_TEXT if approach == "assert_authority" else ""
		for o in q.get("options", []):
			if str(o.get("approach", "")) == approach:
				text = str(o.get("text", ""))
		if text == "":
			return []
		_serial += 1
		# V4 (2.11): they reconsider at once, and the work starts if they now agree (OQ3).
		return [SimBridge.crew_intent("crew_reply", {"command": "captain_reply", "id": "s%d-%s-%d" % [int(crew.get("tick", 0)), str(q.get("task", "")), _serial],
			"issue": issue, "text": text, "approach": approach, "tick": int(crew.get("tick", 0)), "revision": int(crew.get("revision", 0))}, {"start": "on_accept"})]
	return []


## What the captain said, for the call's transcript ("You: ..."), until they answer.
func captain_words(action: String) -> String:
	var parts := action.split(":")
	var m := CrewConsoleModel.member(crew, actor_of(action))
	match parts[0]:
		"offer":
			var verb := CrewConsoleModel.work_verb("work_" + parts[1])
			return ("Will you %s?" if CrewConsoleModel.how_of(crew, parts[1], _client()) != "orders" else "I need you to %s, starting now.") % verb
		"start": return "Then let's begin."
		"order": return "I'm making it an order. Start now."
		"relief": return "You can step back." if parts[2] == "true" else "I need you to keep going."
		"standdown": return "Rest now; we'll manage." if parts[2] == "true" else "I need you to keep going a while longer."
		"resume": return "Carry on; auto-run can take it from here."
		"reply":
			for q in crew.get("concerns", []):
				if str(q.get("issue", "")) == parts[1]:
					if parts[2] == "assert_authority": return CrewConsoleModel.INSIST_TEXT
					for o in q.get("options", []):
						if str(o.get("approach", "")) == parts[2]: return str(o.get("text", ""))
	return "" if m.is_empty() else "…"


# ------------------------------------------------------------------ the view (V7)

func _client() -> Dictionary:
	return {"sending": sending, "how": how}


## The view every binding reads: the sim's crew section, and the client's own call state.
func view() -> Dictionary:
	var send := {}
	for id in sending:
		send[id] = "sending"
	var howv := {}
	for m in crew.get("members", []):
		if m is Dictionary:
			howv[str(m["id"])] = CrewConsoleModel.how_of(crew, str(m["id"]), _client())
	return {"crew": crew, "client": {"crew": {"call": call_id, "sending": send, "how": howv, "notice": notices.duplicate(), "said": said.duplicate(), "ai_text": ai_text.duplicate(), "empty": ""}}}


func _bind(field: String, fmt: String, px: int, color: Color) -> DisplayBinding:
	var b := DisplayBinding.new()
	b.bind(field, fmt)
	b.record_context = field.begins_with("client.")
	_style(b, px, color)
	b.update_from(view())
	return b


func _compose(parts: Array, px: int, color: Color) -> ComposedBinding:
	var b := ComposedBinding.new()
	b.compose(parts)
	b.record_context = parts.any(func(p): return p is Array and str(p[0]).begins_with("client."))
	_style(b, px, color)
	b.update_from(view())
	return b


func _style(l: Label, px: int, color: Color) -> void:
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", px)
	l.add_theme_color_override("font_color", color)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _copy(key: String, px: int, color: Color, field := "crew.captaincy") -> DisplayBinding:
	return _bind(field, "crew_copy:" + key, px, color)


## A label that sits inline in a row: one line, its own width.
func _inline(l: Label) -> Label:
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.size_flags_horizontal = 0
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return l


# ------------------------------------------------------------------ building

func _build() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	var t := TITLE_CALL if call_id != "" else TITLE_BOARD
	if t != _title:
		_title = t
		title_changed.emit(t)
	if crew.is_empty():
		add_child(_bind("client.crew.empty", "crew_copy:empty", 14, CrewPalette.DIM))
		return
	if call_id == "":
		_board()
	else:
		_call()
	_apply_focus()


func title() -> String:
	return TITLE_CALL if call_id != "" else TITLE_BOARD


func _member_field(id: String, key: String) -> String:
	return "crew.members.%d.%s" % [CrewConsoleModel.index_of(crew, id), key]


## A member's chip: the client's sending, else the sim's work_state (with the day while working).
func chip_for(id: String, px := 12, long := true) -> CrewChip:
	var m := CrewConsoleModel.member(crew, id)
	var s := CrewConsoleModel.state(m, _client())
	var i := CrewConsoleModel.index_of(crew, id)
	var label: Label
	if s == "sending":
		label = _bind("client.crew.sending." + id, "crew_state", px, CrewPalette.ON_CHIP)
	elif s == "working" and long:
		label = _compose([[_member_field(id, "work_state"), "crew_state"], ", ", ["crew", "crew_day:%d" % i]], px, CrewPalette.ON_CHIP)
	elif s == "working":
		label = _compose([[_member_field(id, "work_state"), "crew_state"], " · ", [_member_field(id, "work.terms"), "crew_terms"]], px, CrewPalette.ON_CHIP) if str(m.get("work", {}).get("terms", "")) != "" else _bind(_member_field(id, "work_state"), "crew_state", px, CrewPalette.ON_CHIP)
	else:
		label = _bind(_member_field(id, "work_state"), "crew_state", px, CrewPalette.ON_CHIP)
	var c := CrewChip.make(s, label, px)
	c.name = "Chip_" + id
	return c


## A short chip for the mini-roster: the member's name in their state's colour and icon.
func mini_chip(id: String) -> CrewChip:
	var m := CrewConsoleModel.member(crew, id)
	var s := CrewConsoleModel.state(m, _client())
	var c := CrewChip.make(s, _bind(_member_field(id, "name"), "crew_first", 12, CrewPalette.ON_CHIP), 12)
	c.name = "Mini_" + id
	return c


func _panel(bg: Color, border: Color, bw := 1, radius := 6, pad := 8.0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = pad
	sb.content_margin_right = pad
	sb.content_margin_top = pad * 0.75
	sb.content_margin_bottom = pad * 0.75
	return sb


func _face(node_name: String, id: String, emotion: String, px: float) -> TextureRect:
	var t := TextureRect.new()
	t.name = node_name
	t.texture = CrewPage.face(id, emotion)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	t.custom_minimum_size = Vector2(px, px)
	t.tooltip_text = emotion
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


func _button(node_name: String, text: String, action: String, big := false, primary := false) -> Button:
	var b := Button.new()
	b.name = node_name
	b.focus_mode = Control.FOCUS_NONE
	b.text = ("Confirm: " + text) if armed == action and action != "" else text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT if big else HORIZONTAL_ALIGNMENT_CENTER
	b.add_theme_font_size_override("font_size", 14 if big else 13)
	var normal := _panel(Color("#22304a") if primary else Color("#1a2234"), Color("#4b6390") if primary else Color("#33415e"), 1, 6, 10.0 if big else 8.0)
	normal.content_margin_top = 4
	normal.content_margin_bottom = 4
	if armed == action and action != "":
		normal.border_color = CrewPalette.TEXT
		normal.set_border_width_all(2)
	var hover := normal.duplicate()
	hover.bg_color = normal.bg_color.lightened(0.08)
	var dis := normal.duplicate()
	dis.bg_color = Color("#151b28")
	dis.border_color = Color("#283247")
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("disabled", dis)
	b.add_theme_color_override("font_color", CrewPalette.TEXT)
	b.add_theme_color_override("font_disabled_color", Color(CrewPalette.DIM, 0.6))
	if big:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if action != "":
		b.pressed.connect(func() -> void: press(action))
		b.set_meta("action", action)
	return b


# ------------------------------------------------------------------ V7b: icons over words

func _icon(kind: String, color: Color, px: float, tip := "") -> CrewChip.ChipIcon:
	var ic := CrewChip.ChipIcon.new()
	ic.kind = kind
	ic.color = color
	ic.custom_minimum_size = Vector2(px, px)
	ic.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if tip != "":
		ic.tooltip_text = tip
		ic.mouse_filter = Control.MOUSE_FILTER_PASS
	return ic


## A rule in one short line; its full words are the tooltip, and "?" opens them below (V7b).
func _rule(key: String, field: String, color := CrewPalette.DIM) -> Control:
	var box := VBoxContainer.new()
	box.name = "Rule_" + key
	box.add_theme_constant_override("separation", 2)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	var full_key := key + "_cost" if CrewConsoleModel.COPY.has(key + "_cost") else key
	var short_key := key + "_short" if CrewConsoleModel.COPY.has(key + "_short") else key
	var short := _bind(field, "crew_copy:" + short_key, 12, color)
	short.tooltip_text = str(CrewConsoleModel.COPY.get(full_key, ""))
	short.mouse_filter = Control.MOUSE_FILTER_PASS
	short.size_flags_horizontal = 0
	short.autowrap_mode = TextServer.AUTOWRAP_OFF
	short.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(short)
	if full_key != short_key:
		var q := _button("Help_" + key, "", "help:" + key)
		q.flat = true
		q.custom_minimum_size = Vector2(18, 18)
		q.tooltip_text = short.tooltip_text
		q.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var qi := _icon("help", CrewPalette.TEXT if help.has(key) else CrewPalette.DIM, 13)
		qi.position = Vector2(2, 2)
		q.add_child(qi)
		row.add_child(q)
	box.add_child(row)
	if help.has(key) and full_key != short_key:
		box.add_child(_bind(field, "crew_copy:" + full_key, 12, CrewPalette.DIM))
	return box


## The work's terms as icons (V7b): day pips, each resource it needs with a pip per unit (amber when
## used up), each effect on them with its arrow. The sentence is the row's tooltip.
func _terms_row(id: String) -> Control:
	var info := CrewPage.work_info("work_" + id)
	var row := HFlowContainer.new()
	row.name = "Terms"
	row.add_theme_constant_override("h_separation", 4)
	row.add_theme_constant_override("v_separation", 2)
	row.tooltip_text = CrewPage.work_terms(info)
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	var days := int(info.get("duration", 0))
	var d := HBoxContainer.new()
	d.name = "Days"
	d.add_theme_constant_override("separation", 2)
	d.tooltip_text = "Takes %s day%s" % [CrewPage.words(days), "" if days == 1 else "s"]
	d.mouse_filter = Control.MOUSE_FILTER_PASS
	d.add_child(_icon("clock", CrewPalette.DIM, 14, d.tooltip_text))
	for i in days:
		d.add_child(_icon("pip", CrewPalette.TEXT, 10, d.tooltip_text))
	row.add_child(d)
	for c in info.get("costs", []):
		var res := str(c.get("resource", ""))
		var n := maxi(int(c.get("reserve", 0)), int(c.get("consume", 0)))
		var used := int(c.get("consume", 0)) > 0
		var g := HBoxContainer.new()
		g.name = "Cost_" + res
		g.add_theme_constant_override("separation", 2)
		var tip := "Needs %s %s%s" % [CrewPage.words(n), CrewPage.resource_name(res).to_lower(), " (used up)" if used else ""]
		g.tooltip_text = tip
		g.mouse_filter = Control.MOUSE_FILTER_PASS
		g.add_child(_spacer(8))
		g.add_child(_icon(res, CrewPalette.color_of("asked"), 15, tip))
		for i in n:
			g.add_child(_icon("pip", CrewPalette.color_of("concern") if used else CrewPalette.color_of("asked"), 9, tip))
		row.add_child(g)
	for k in info.get("effects", {}):
		var v := float(info["effects"][k])
		if v == 0.0 or not CrewPage.EFFECT_WORDS.has(k):
			continue
		var e := HBoxContainer.new()
		e.name = "Effect_" + k
		e.add_theme_constant_override("separation", 1)
		var tip := str(CrewPage.EFFECT_WORDS[k][0 if v > 0.0 else 1])
		e.tooltip_text = tip
		e.mouse_filter = Control.MOUSE_FILTER_PASS
		e.add_child(_spacer(8))
		e.add_child(_icon(k, CrewPalette.DIM, 15, tip))
		e.add_child(_icon("up" if v > 0.0 else "down", CrewPalette.TEXT, 9, tip))
		row.add_child(e)
	return row


func _spacer(px: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(px, 0)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


## A crew member as a face and a chip (their state's colour and icon, their first name): the
## mini-roster and "waiting on whom" (V7b). Pressing it switches the call.
func _face_chip(oid: String) -> Control:
	var m := CrewConsoleModel.member(crew, oid)
	var st := CrewConsoleModel.state(m, _client())
	var p := PanelContainer.new()
	p.name = "Switch_" + oid
	var sb := _panel(CrewPalette.ROW, CrewPalette.color_of(st), 2, 15, 3.0)
	sb.content_margin_right = 9
	if pulse.has(oid):
		sb.border_color = CrewPalette.TEXT
		sb.set_border_width_all(3)
		p.set_meta("pulse", true)
	p.add_theme_stylebox_override("panel", sb)
	p.tooltip_text = CrewPalette.word_of(st)
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	p.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	p.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT: press("call:" + oid))
	p.set_meta("action", "call:" + oid)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(row)
	row.add_child(_face("Face_" + oid, oid, str(m.get("emotion", "neutral")), 26))
	row.add_child(_icon(CrewPalette.icon_of(st), CrewPalette.color_of(st), 12))
	var nm := _bind(_member_field(oid, "name"), "crew_first", 12, CrewPalette.TEXT)
	nm.autowrap_mode = TextServer.AUTOWRAP_OFF
	nm.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	nm.size_flags_horizontal = 0
	row.add_child(nm)
	return p


# ------------------------------------------------------------------ the board

func _board() -> void:
	add_child(_strip())
	var rows := VBoxContainer.new()
	rows.name = "Roster"
	rows.add_theme_constant_override("separation", 4)
	for m in CrewConsoleModel.board_order(crew, _client()):
		rows.add_child(_row(m))
	add_child(rows)
	for h in crew.get("holds", []):
		if str(h.get("actor", "")) == "":
			add_child(_compose(["Needs you: ", ["crew.holds.%d.name" % crew.get("holds", []).find(h), "%s"], " ", ["crew.holds.%d.line" % crew.get("holds", []).find(h), "%s"]], 13, CrewPalette.color_of("held")))
	var lg := HFlowContainer.new()
	lg.name = "LegendRow"
	lg.add_theme_constant_override("h_separation", 6)
	lg.add_theme_constant_override("v_separation", 4)
	var t := _button("LegendToggle", "", "help:legend")
	t.flat = true
	t.custom_minimum_size = Vector2(18, 18)
	t.tooltip_text = "Legend [?]"
	var ti := _icon("help", CrewPalette.TEXT if help.has("legend") else CrewPalette.DIM, 13)
	ti.position = Vector2(2, 2)
	t.add_child(ti)
	lg.add_child(t)
	if help.has("legend"):
		var full := _legend()
		for chip in full.get_children():
			full.remove_child(chip)
			lg.add_child(chip)
		full.free()
	else:
		lg.add_child(_inline(_copy("legend", 12, CrewPalette.DIM)))
	add_child(lg)


## The header strip: the ship default and auto-run (both global, both confirmed), and the ship's
## free resources as dot gauges (the numbers in words in each gauge's tooltip; D-21).
func _strip() -> Control:
	var box := PanelContainer.new()
	box.name = "Strip"
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0)
	sb.border_color = CrewPalette.EDGE
	sb.border_width_bottom = 1
	sb.content_margin_bottom = 6
	box.add_theme_stylebox_override("panel", sb)
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 10)
	row.add_theme_constant_override("v_separation", 4)
	box.add_child(row)
	var cap := str(crew.get("captaincy", "consent"))
	var other := "orders" if cap == "consent" else "consent"
	row.add_child(_inline(_copy("ship", 13, CrewPalette.DIM)))
	var pol := _button("Policy", "%s (%s) ▾" % [CrewConsoleModel.how_word(cap), cap], "policy:" + other)
	if armed == "policy:" + other:
		pol.text = "Confirm: make %s the ship default" % CrewConsoleModel.how_word(other)
	pol.tooltip_text = CrewConsoleModel.COPY["default_note"]
	row.add_child(pol)
	row.add_child(_inline(_copy("auto", 13, CrewPalette.DIM)))
	var cur := str(crew.get("auto", "off"))
	var curb := _button("AutoNow", "%s" % SHORT_PRESET.get(cur, cur), "")
	curb.disabled = true
	curb.add_theme_color_override("font_disabled_color", CrewPalette.TEXT)
	row.add_child(curb)
	for p in ["critical_only", "hands_on", "off"]:
		if p != cur:
			var b := _button("Auto_" + p, SHORT_PRESET[p], "orders:" + p)
			if armed == "orders:" + p:
				b.text = "Confirm: auto-run %s" % str(CrewPage.PRESETS[p]).to_lower()
			b.tooltip_text = CrewPage.PRESETS[p]
			b.add_theme_font_size_override("font_size", 12)
			row.add_child(b)
	row.add_child(_inline(_copy("free", 13, CrewPalette.DIM)))
	var rs: Array = crew.get("resources", [])
	for k in rs.size():
		var g := HBoxContainer.new()
		g.name = "Gauge_" + str(rs[k].get("id", ""))
		g.add_theme_constant_override("separation", 3)
		g.add_child(_inline(_bind("crew.resources.%d.id" % k, "crew_resource_short", 12, CrewPalette.DIM)))
		var dots := Dots.new()
		dots.free_n = int(rs[k].get("available", 0))
		dots.total = int(rs[k].get("available", 0)) + int(rs[k].get("reserved", 0))
		dots.tooltip_text = "%s: %s free of %s" % [CrewPage.resource_name(str(rs[k].get("id", ""))), CrewPage.words(dots.free_n), CrewPage.words(dots.total)]
		g.add_child(dots)
		row.add_child(g)
	return box


func _row(m: Dictionary) -> Control:
	var id := str(m["id"])
	var s := CrewConsoleModel.state(m, _client())
	var p := PanelContainer.new()
	p.name = "Member_" + id
	p.custom_minimum_size = Vector2(0, ROW_H)
	var sb := _panel(CrewPalette.ROW, CrewPalette.color_of(s), 0, 6, 8.0)
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	sb.border_width_left = 5
	if pulse.has(id):
		sb.set_border_width_all(2)
		sb.border_width_left = 5
		sb.border_color = CrewPalette.color_of("concern")
		p.set_meta("pulse", true)
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	p.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT: press("call:" + id))
	p.set_meta("action", "call:" + id)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(row)
	row.add_child(_face("Portrait_" + id, id, str(m.get("emotion", "neutral")), FACE_ROW))
	var who := VBoxContainer.new()
	who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	who.alignment = BoxContainer.ALIGNMENT_CENTER
	who.add_theme_constant_override("separation", 0)
	who.mouse_filter = Control.MOUSE_FILTER_IGNORE
	who.add_child(_bind(_member_field(id, "name"), "%s", 15, CrewPalette.TEXT))
	who.add_child(_compose([[_member_field(id, "id"), "crew_role"], " · ", [_member_field(id, "id"), "crew_job"]], 12, CrewPalette.DIM))
	var hold := CrewConsoleModel.hold_of(crew, id)
	if not hold.is_empty():
		who.add_child(_compose(["Auto-run held: ", ["crew.holds.%d.line" % crew.get("holds", []).find(hold), "%s"]], 12, CrewPalette.color_of("held")))
	if notices.has(id):
		who.add_child(_bind("client.crew.notice." + id, "%s", 12, CrewPalette.color_of("concern")))
	row.add_child(who)
	var chip := chip_for(id)
	row.add_child(chip)
	var q := CrewConsoleModel.quick(m, crew, _client())
	var slot := Control.new()
	slot.custom_minimum_size = Vector2(96, 0)
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not q.is_empty():
		var b := _button("Quick_" + id, str(q.text), "", false, true)
		b.custom_minimum_size = Vector2(96, 30)
		b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		b.pressed.connect(func() -> void: press("quick:%s:%s" % [id, q.action]))
		row.add_child(b)
	else:
		row.add_child(slot)
	return p


func _legend() -> Control:
	var row := HFlowContainer.new()
	row.name = "Legend"
	row.add_theme_constant_override("h_separation", 6)
	row.add_theme_constant_override("v_separation", 4)
	row.add_child(_inline(_copy("legend", 12, CrewPalette.DIM)))
	for e in CrewPalette.LEGEND:
		var st := ""
		for k in CrewPalette.STATES:
			if CrewPalette.STATES[k]["token"] == e[0]:
				st = k
				break
		var c := CrewChip.make(st, _bind("crew.captaincy", "crew_copy:legend_" + str(e[0]), 12, CrewPalette.ON_CHIP), 12)
		c.name = "Legend_" + str(e[0])
		row.add_child(c)
	return row


# ------------------------------------------------------------------ the call

func _call() -> void:
	var m := CrewConsoleModel.member(crew, call_id)
	var two := HBoxContainer.new()
	two.name = "Call"
	two.add_theme_constant_override("separation", 12)
	two.size_flags_vertical = Control.SIZE_EXPAND_FILL
	two.add_child(_call_window(m))
	two.add_child(_decisions(m))
	add_child(two)


## The call window: the person, at reading size, on the internal videocom: the portrait at the
## sim's emotion with who they are beside it, and their words under it (the latest line, an open
## concern's words, or the captain's own while the answer is on its way).
func _call_window(m: Dictionary) -> Control:
	var id := str(m.get("id", ""))
	var s := CrewConsoleModel.state(m, _client())
	var p := PanelContainer.new()
	p.name = "CallWindow"
	p.custom_minimum_size = Vector2(CALL_W, 0)
	p.add_theme_stylebox_override("panel", _panel(CrewPalette.CALL_BG, Color("#2c3a57"), 1, 8, 10.0))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	p.add_child(box)
	box.add_child(_copy("calling" if s == "sending" else "live", 12, CrewPalette.color_of("sending") if s == "sending" else Color("#5bd17a"), _member_field(id, "id")))
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	var frame := PanelContainer.new()
	frame.name = "PortraitFrame"
	frame.add_theme_stylebox_override("panel", _panel(Color("#10151f"), Color("#3a4a6c"), 1, 6, 1.0))
	frame.add_child(_face("CallPortrait", id, str(m.get("emotion", "neutral")), PORTRAIT))
	top.add_child(frame)
	var info := VBoxContainer.new()
	info.name = "Who"
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)
	info.add_child(_bind(_member_field(id, "name"), "%s", 16, CrewPalette.TEXT))
	info.add_child(_bind(_member_field(id, "id"), "crew_role", 13, CrewPalette.DIM))
	info.add_child(_bind(_member_field(id, "emotion"), "crew_emotion", 13, CrewPalette.DIM))
	info.add_child(_bars(m))
	top.add_child(info)
	box.add_child(top)
	var tr := VBoxContainer.new()
	tr.name = "Transcript"
	tr.add_theme_constant_override("separation", 4)
	var ls: Array = crew.get("lines", [])
	var last := -1
	for k in ls.size():
		if str(ls[k].get("actor", "")) == id:
			last = k
	if last >= 0:
		var req := str(ls[last].get("ai_req", ""))
		var line := _bind("client.crew.ai_text." + req, "crew_quote", 14, CrewPalette.TEXT) if ai_text.has(req) else _bind("crew.lines.%d.text" % last, "crew_quote", 14, CrewPalette.TEXT)
		tr.add_child(_say(line, Color("#4a5b80")))
	var qs: Array = crew.get("concerns", [])
	for k in qs.size():
		if str(qs[k].get("actor", "")) == id:
			tr.add_child(_say(_bind("crew.concerns.%d.prompt" % k, "crew_quote", 14, CrewPalette.TEXT), CrewPalette.color_of("concern")))
	if said.has(id) and (s == "sending" or s == "asked"):
		tr.add_child(_say(_compose(["You: ", ["client.crew.said." + id, "crew_quote"]], 14, CrewPalette.DIM), CrewPalette.TITLE))
	box.add_child(tr)
	return p


func _say(l: Label, edge: Color) -> Control:
	var p := PanelContainer.new()
	var sb := _panel(Color("#0e1420"), edge, 0, 6, 8.0)
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	sb.border_width_left = 3
	p.add_theme_stylebox_override("panel", sb)
	p.add_child(l)
	return p


func _bars(m: Dictionary) -> Control:
	var id := str(m.get("id", ""))
	var grid := GridContainer.new()
	grid.name = "Bars"
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 3)
	var ind: Dictionary = m.get("indicators", {})
	for k in ["stress", "fatigue", "trust"]:
		var v: Variant = m.get("trust") if k == "trust" else ind.get(k)
		if v == null:
			continue
		var f: String = "trust" if k == "trust" else "indicators." + k
		var hot: bool = k != "trust" and float(v) >= CrewPage.STRAINED
		var cap := HBoxContainer.new()
		cap.add_theme_constant_override("separation", 4)
		cap.add_child(_icon(k, CrewPalette.color_of("concern") if hot else CrewPalette.DIM, 13, k))
		if hot:
			cap.add_child(_inline(_bind(_member_field(id, f), "crew_copy:strained", 12, CrewPalette.color_of("concern"))))
		grid.add_child(cap)
		var bar := ProgressBar.new()
		bar.name = "Bar_" + k
		bar.min_value = 0.0
		bar.max_value = 100.0
		bar.value = float(v)
		bar.show_percentage = false # the bar is the readout; numbers come from the sim only (D-21)
		bar.custom_minimum_size = Vector2(60, 7)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var bg := StyleBoxFlat.new()
		bg.bg_color = Color("#26324a")
		bg.set_corner_radius_all(3)
		var fill := StyleBoxFlat.new()
		fill.set_corner_radius_all(3)
		fill.bg_color = CrewPalette.color_of("concern") if hot else Color("#8796b3")
		bar.add_theme_stylebox_override("background", bg)
		bar.add_theme_stylebox_override("fill", fill)
		grid.add_child(bar)
	return grid


## The work and the decisions: the next legal actions first; disabled ones say why.
func _decisions(m: Dictionary) -> Control:
	var id := str(m.get("id", ""))
	var s := CrewConsoleModel.state(m, _client())
	var p := PanelContainer.new()
	p.name = "Decision"
	p.custom_minimum_size = Vector2(DECIDE_W, 0)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_stylebox_override("panel", _panel(CrewPalette.ROW, CrewPalette.EDGE, 1, 8, 12.0))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	p.add_child(box)
	var hold := CrewConsoleModel.hold_of(crew, id)
	if not hold.is_empty():
		var hp := PanelContainer.new()
		hp.name = "HoldBanner"
		hp.add_theme_stylebox_override("panel", _panel(Color("#2b2606"), CrewPalette.color_of("held"), 1, 6, 8.0))
		var hrow := HBoxContainer.new()
		hrow.add_theme_constant_override("separation", 8)
		hp.add_child(hrow)
		var hi: int = crew.get("holds", []).find(hold)
		var hl := _compose(["Auto-run held: ", ["crew.holds.%d.name" % hi, "%s"], " ", ["crew.holds.%d.line" % hi, "%s"]], 14, CrewPalette.TEXT)
		hl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hrow.add_child(hl)
		var rb := _button("Resume_" + str(hold.get("id", "")), "Resume auto-run", "resume:" + str(hold.get("id", "")), false, true)
		rb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		hrow.add_child(rb)
		box.add_child(hp)
	var top := HBoxContainer.new()
	top.add_child(chip_for(id, 13, false))
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(gap)
	var end := _button("EndCall", "End call [Esc]", "end_call")
	top.add_child(end)
	box.add_child(top)
	box.add_child(_bind(_member_field(id, "id"), "crew_job", 16, CrewPalette.TEXT))
	if s in ["working", "resting"]:
		var bar := ProgressBar.new()
		bar.name = "Progress"
		bar.max_value = 1.0
		bar.value = CrewConsoleModel.day_fraction(crew, m)
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 8)
		var bg := StyleBoxFlat.new()
		bg.bg_color = Color("#26324a")
		bg.set_corner_radius_all(4)
		var fill := StyleBoxFlat.new()
		fill.bg_color = CrewPalette.color_of("working")
		fill.set_corner_radius_all(4)
		bar.add_theme_stylebox_override("background", bg)
		bar.add_theme_stylebox_override("fill", fill)
		box.add_child(bar)
		var i := CrewConsoleModel.index_of(crew, id)
		box.add_child(_compose(["On ", ["crew", "crew_day:%d" % i], "."], 13, CrewPalette.DIM))
		_whose(box, id)
	else:
		if s in ["free", "done", "stopped"]:
			box.add_child(_bind(_member_field(id, "id"), "crew_job_purpose", 12, CrewPalette.DIM))
		box.add_child(_terms_row(id))
		_decide(box, m, s)
	if notices.has(id):
		box.add_child(_bind("client.crew.notice." + id, "%s", 13, CrewPalette.color_of("concern")))
	var fill := Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(fill)
	if not s in ["working", "resting"]: # monitoring shows the others as "waiting on whom" instead
		box.add_child(_mini(id))
	return p


func _heading(key: String, id: String) -> Control:
	var h := _copy(key, 12, CrewPalette.DIM, _member_field(id, "work_state"))
	h.uppercase = true
	return h


## The decision block for the state (design §V4).
func _decide(box: VBoxContainer, m: Dictionary, s: String) -> void:
	var id := str(m.get("id", ""))
	var acts := CrewConsoleModel.actions(m, crew, _client())
	var wsf := _member_field(id, "work_state")
	match s:
		"free", "done", "stopped":
			box.add_child(_heading("how", id))
			var hr := HBoxContainer.new()
			hr.name = "How"
			hr.add_theme_constant_override("separation", 0)
			var cur := CrewConsoleModel.how_of(crew, id, _client())
			for mode in ["consent", "orders"]:
				var b := _button("How_" + mode, CrewConsoleModel.how_word(mode), "")
				b.toggle_mode = true
				b.button_pressed = cur == mode
				var sb: StyleBoxFlat = (b.get_theme_stylebox("normal") as StyleBoxFlat).duplicate()
				sb.bg_color = Color("#2c3e61") if cur == mode else Color("#141b2a")
				sb.border_color = Color("#4b6390")
				b.add_theme_stylebox_override("normal", sb)
				b.add_theme_stylebox_override("pressed", sb)
				b.custom_minimum_size = Vector2(64, 0)
				b.pressed.connect(func() -> void: press("how:%s:%s" % [id, mode]))
				hr.add_child(b)
			hr.add_child(_inline(_compose(["   ship default: ", ["crew.captaincy", "crew_how"]], 12, CrewPalette.DIM)))
			box.add_child(hr)
			box.add_child(_rule("order" if cur == "orders" else "ask", "client.crew.how." + id))
			for a in acts:
				var b := _button("Offer_" + id, str(a.text), str(a.action), true, true)
				if armed == str(a.action):
					b.text = "Confirm: %s %s to %s" % ["order" if cur == "orders" else "ask", CrewPage.display_name(crew, id).split(" ")[0], CrewConsoleModel.work_verb("work_" + id)]
				box.add_child(b)
			if armed.begins_with("offer:" + id):
				box.add_child(_rule("armed", wsf))
		"sending":
			box.add_child(_reason(s, id, "sending"))
			for a in acts:
				var b := _button(("Offer_" if str(a.action).begins_with("offer") else "Start_") + id, str(a.text), "", true)
				b.disabled = true
				b.tooltip_text = str(a.why)
				box.add_child(b)
			pass
		"held" when str(m.get("stand_down", "")) != "":
			_stand_down(box, acts, wsf)
		"concern", "declined", "deferred", "held":
			if s == "deferred":
				box.add_child(_rule("lapse", wsf))
			if s != "held" or not CrewConsoleModel.concern_of(crew, id).is_empty():
				box.add_child(_heading("answers", id))
			var grid := GridContainer.new()
			grid.name = "Answers"
			grid.columns = 2
			grid.add_theme_constant_override("h_separation", 6)
			grid.add_theme_constant_override("v_separation", 5)
			var insist := false
			for a in acts:
				var act := str(a.action)
				if act.begins_with("reply:"):
					var ap := act.get_slice(":", 2)
					var b := _button("Reply_" + ap, str(a.text), act, true, bool(a.primary))
					b.custom_minimum_size = Vector2(0, 28)
					for st_name in ["normal", "hover", "pressed", "disabled"]:
						var sbx: StyleBoxFlat = (b.get_theme_stylebox(st_name) as StyleBoxFlat).duplicate()
						sbx.content_margin_left = 30
						b.add_theme_stylebox_override(st_name, sbx)
					var bi := _icon(ap, CrewPalette.color_of("concern") if ap == "assert_authority" else CrewPalette.TEXT, 15)
					bi.position = Vector2(9, 7)
					b.add_child(bi)
					grid.add_child(b)
					insist = insist or a.has("cost")
			if grid.get_child_count() > 0:
				box.add_child(grid)
			if insist:
				box.add_child(_rule("insist", wsf))
			if s != "held":
				for a in acts:
					if str(a.action).begins_with("start:"):
						var row := HBoxContainer.new()
						row.name = "StartRow"
						row.add_theme_constant_override("separation", 10)
						var b := _button("Start_" + id, str(a.text), "", false)
						b.disabled = true
						b.tooltip_text = str(a.why)
						b.custom_minimum_size = Vector2(130, 28)
						b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
						row.add_child(b)
						var r := _reason(s, id, "concern")
						r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
						r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
						row.add_child(r)
						box.add_child(row)
				for a in acts:
					if str(a.action).begins_with("order:"):
						var row := HBoxContainer.new()
						row.name = "OrderRow"
						row.add_theme_constant_override("separation", 10)
						var ob := _button("Order_" + id, str(a.text), str(a.action), false)
						ob.custom_minimum_size = Vector2(0, 28)
						ob.size_flags_vertical = Control.SIZE_SHRINK_CENTER
						row.add_child(ob)
						row.add_child(_rule("make_order", wsf))
						box.add_child(row)
		"asked", "offered":
			box.add_child(_reason(s, id, s))
			if s == "offered":
				box.add_child(_rule("lapse", wsf))
			for a in acts:
				var b := _button("Start_" + id, str(a.text), "", true)
				b.disabled = true
				b.tooltip_text = str(a.why)
				box.add_child(b)
		"agreed":
			box.add_child(_reason(s, id, "agreed"))
			for a in acts:
				box.add_child(_button("Start_" + id, str(a.text), str(a.action), true, true))
		"relief_asked":
			box.add_child(_reason(s, id, "relief_asked"))
			for a in acts:
				box.add_child(_button(("Grant_" if str(a.action).ends_with("true") else "Deny_") + str(a.action).get_slice(":", 1), str(a.text), str(a.action), true, true))
			box.add_child(_rule("relief", wsf))
		"stand_down_asked":
			box.add_child(_reason(s, id, "stand_down_asked"))
			_stand_down(box, acts, wsf)


## V8 (crew_core 0.6): a stand-down's two answers, confirmed, with the rule in one line.
func _stand_down(box: VBoxContainer, acts: Array, wsf: String) -> void:
	var row := HBoxContainer.new()
	row.name = "StandDown"
	row.add_theme_constant_override("separation", 8)
	for a in acts:
		var act := str(a.action)
		if act.begins_with("standdown:"):
			var b := _button(("Rest_" if act.ends_with("true") else "CarryOn_") + act.get_slice(":", 1), str(a.text), act, true, true)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(b)
	box.add_child(row)
	box.add_child(_rule("stand_down", wsf))


## A reason line: the state's icon and its words, bound to the state they explain.
func _reason(s: String, id: String, icon_state: String) -> Control:
	var row := HBoxContainer.new()
	row.name = "Reason"
	row.add_theme_constant_override("separation", 6)
	var ic := CrewChip.ChipIcon.new()
	ic.kind = CrewPalette.icon_of(icon_state)
	ic.color = CrewPalette.color_of(icon_state)
	ic.custom_minimum_size = Vector2(14, 14)
	ic.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(ic)
	var field := "client.crew.sending." + id if s == "sending" else _member_field(id, "work_state")
	var l := _bind(field, "crew_reason", 14, CrewPalette.TEXT)
	row.add_child(l)
	return row


## Monitoring: whose move it is across the others, as faces with their state (V7b).
func _whose(box: VBoxContainer, id: String) -> void:
	var others: Array = CrewConsoleModel.board_order(crew, _client()).filter(func(o): return str(o.get("id", "")) != id)
	if others.is_empty():
		return
	box.add_child(_heading("whose", id))
	var row := HFlowContainer.new()
	row.name = "Whose"
	row.add_theme_constant_override("h_separation", 6)
	row.add_theme_constant_override("v_separation", 4)
	for o in others:
		row.add_child(_face_chip(str(o["id"])))
	box.add_child(row)


## The mini-roster: the others as faces with their state; pressing one switches the call.
func _mini(id: String) -> Control:
	var row := HFlowContainer.new()
	row.name = "MiniRoster"
	row.add_theme_constant_override("h_separation", 6)
	row.add_theme_constant_override("v_separation", 4)
	for m in crew.get("members", []):
		var oid := str(m.get("id", ""))
		if oid != id:
			row.add_child(_face_chip(oid))
	return row


## A dot gauge: free units filled, held units hollow.
class Dots extends Control:
	var free_n := 0
	var total := 0

	func _init() -> void:
		custom_minimum_size = Vector2(0, 12)
		mouse_filter = Control.MOUSE_FILTER_PASS
		size_flags_vertical = Control.SIZE_SHRINK_CENTER

	func _ready() -> void:
		custom_minimum_size = Vector2(maxi(total, 1) * 11.0, 12.0)

	func _draw() -> void:
		var col := CrewPalette.color_of("free")
		for i in total:
			var c := Vector2(5.0 + i * 11.0, size.y / 2.0)
			if i < free_n:
				draw_circle(c, 4.0, col)
			else:
				draw_arc(c, 3.5, 0.0, TAU, 16, col, 1.2, true)


# ------------------------------------------------------------------ V6: keyboard and controller
## The console's own focus ring (the engine's focus stays with the ship's controls): the focused
## control's action, drawn with a 2 px outline in TEXT (never a state colour). No single key or
## button decides: Enter / A presses the focused control, which arms a decision; the same press
## again sends it. Esc / B disarms, then ends the call, then (unhandled) steps back.
##   up / down, left / right, D-pad, left stick   move the focus
##   [ ] , LB / RB                                previous / next crew member (switch the call)
##   Enter, Space, A                              press the focused control
##   1 2 3 4                                      arm (then send) that answer to a concern
##   O, Y                                         Ask / Order on the offer in the call
##   ?, Select / View                             the board's legend
const KEYS := {KEY_UP: "up", KEY_DOWN: "down", KEY_LEFT: "left", KEY_RIGHT: "right", KEY_BRACKETLEFT: "prev", KEY_BRACKETRIGHT: "next",
	KEY_ENTER: "enter", KEY_KP_ENTER: "enter", KEY_SPACE: "enter", KEY_1: "1", KEY_2: "2", KEY_3: "3", KEY_4: "4", KEY_O: "how",
	KEY_ESCAPE: "back", KEY_QUESTION: "legend", KEY_SLASH: "legend"}
const PAD := {JOY_BUTTON_DPAD_UP: "up", JOY_BUTTON_DPAD_DOWN: "down", JOY_BUTTON_DPAD_LEFT: "left", JOY_BUTTON_DPAD_RIGHT: "right",
	JOY_BUTTON_LEFT_SHOULDER: "prev", JOY_BUTTON_RIGHT_SHOULDER: "next", JOY_BUTTON_A: "enter", JOY_BUTTON_B: "back", JOY_BUTTON_Y: "how", JOY_BUTTON_BACK: "legend"}
var _stick := 0 ## the left stick's last direction (-1, 0, 1): one move per push


## One input event while the console is the focused station. True when it was the console's.
func key(event: InputEvent) -> bool:
	var k := ""
	if event is InputEventKey and event.pressed and not event.echo:
		k = str(KEYS.get(event.physical_keycode if event.physical_keycode != 0 else event.keycode, ""))
	elif event is InputEventJoypadButton and event.pressed:
		k = str(PAD.get(event.button_index, ""))
	elif event is InputEventJoypadMotion and event.axis == JOY_AXIS_LEFT_Y:
		var d := 1 if event.axis_value > 0.6 else (-1 if event.axis_value < -0.6 else 0)
		if d != _stick and d != 0:
			k = "down" if d > 0 else "up"
		_stick = d
	if k == "" or crew.is_empty():
		return false
	match k:
		"up", "left": _move(-1)
		"down", "right": _move(1)
		"prev", "next": _switch(-1 if k == "prev" else 1)
		"enter":
			if focus_action == "":
				_move(1)
			else:
				press(focus_action)
		"1", "2", "3", "4":
			var answers := focusables().filter(func(c): return str(c.get_meta("action")).begins_with("reply:"))
			var n := int(k) - 1
			if call_id == "" or n >= answers.size():
				return false
			focus_action = str(answers[n].get_meta("action"))
			press(focus_action)
		"how":
			if call_id == "":
				return false
			press("how:%s:%s" % [call_id, "consent" if CrewConsoleModel.how_of(crew, call_id, _client()) == "orders" else "orders"])
		"legend":
			press("help:legend")
		"back":
			if armed != "":
				armed = ""
				_build()
			elif call_id != "":
				end_call()
			else:
				return false
	return true


## The focusable controls, in reading order (a disabled one is skipped).
## On the board the rows come first; in a call the decisions, then End call, then the others.
func focusables() -> Array:
	var fs := find_children("*", "Control", true, false).filter(func(c): return c.has_meta("action") and not (c is Button and (c as Button).disabled) and _shown(c))
	var rank := func(c: Control) -> int:
		var a := str(c.get_meta("action"))
		if call_id == "": return 0 if a.begins_with("call:") else 1
		return 2 if a.begins_with("call:") else (1 if a == "end_call" or a.begins_with("help:") else 0)
	var keyed := []
	for i in fs.size():
		keyed.append([rank.call(fs[i]), i, fs[i]])
	keyed.sort_custom(func(x, y): return x[0] < y[0] or (x[0] == y[0] and x[1] < y[1]))
	return keyed.map(func(k): return k[2])


## Visible within the console (the console's own visibility is the station's business).
func _shown(c: Node) -> bool:
	var n := c
	while n != null and n != self:
		if n is CanvasItem and not (n as CanvasItem).visible:
			return false
		n = n.get_parent()
	return n == self


func _move(step: int) -> void:
	var fs := focusables()
	if fs.is_empty():
		return
	var i := fs.map(func(c): return str(c.get_meta("action"))).find(focus_action)
	i = clampi(i + step, 0, fs.size() - 1) if i >= 0 else (0 if step > 0 else fs.size() - 1)
	focus_action = str(fs[i].get_meta("action"))
	_build()


func _switch(step: int) -> void:
	var ids: Array = crew.get("members", []).map(func(m): return str(m.get("id", "")))
	if ids.is_empty():
		return
	var i := ids.find(call_id)
	press("call:" + str(ids[posmod(i + step, ids.size()) if i >= 0 else 0]))


## Draw the focus ring on the focused control.
func _apply_focus() -> void:
	for c in focusables():
		if str(c.get_meta("action")) != focus_action:
			continue
		c.set_meta("focused", true)
		var sb_name := "normal" if c is Button else "panel"
		var sb: StyleBox = (c as Control).get_theme_stylebox(sb_name)
		if sb is StyleBoxFlat:
			var f: StyleBoxFlat = (sb as StyleBoxFlat).duplicate()
			f.border_color = CrewPalette.TEXT
			f.set_border_width_all(2)
			if c is Button:
				c.add_theme_stylebox_override("normal", f)
				c.add_theme_stylebox_override("hover", f)
			else:
				f.border_width_left = maxi(f.border_width_left, 2)
				c.add_theme_stylebox_override("panel", f)
		return
