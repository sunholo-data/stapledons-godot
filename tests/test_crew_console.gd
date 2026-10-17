extends SceneTree
## R2-CREW-CONSOLE-V2 (design crew-console-v2.md; V2 palette and model, V3 board and call): the Crew
## console on crews recorded from the real sim at protocol 2.11 (tests/crew/console_v2/*.json,
## tools/crew_console_fixture.gd), then against the real sim. Earlier C6/W1 checks that still hold
## (portraits, refusal words, unique ids) carry over.
## Run:  make crew-console-test

var failures := 0

func check(label: String, ok: bool) -> void:
	if not ok: failures += 1
	print("%s %s" % ["ok" if ok else "FAIL", label])

func fixture(name: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://tests/crew/console_v2/%s.json" % name))

func texts(n: Node) -> Array:
	var out := []
	for c in n.find_children("*", "", true, false):
		if c is Label: out.append((c as Label).text)
		elif c is Button: out.append((c as Button).text)
	return out

func line_of(intent: Dictionary) -> Dictionary:
	return JSON.parse_string(intent["line"])

func member_of(crew: Dictionary, id: String) -> Dictionary:
	return CrewConsoleModel.member(crew, id)

func btn(c: Node, name: String) -> Button:
	return c.find_child(name, true, false) as Button

## Every Label on the console is a binding, and re-derives its own text from the console's view.
func bound(c: CrewConsole) -> Array:
	var bad := []
	var v := c.view()
	for l in c.find_children("*", "Label", true, false):
		if not l is DisplayBinding:
			bad.append("%s plain %s" % [l.name, (l as Label).text])
			continue
		var b: DisplayBinding
		if l is ComposedBinding:
			b = ComposedBinding.new().compose((l as ComposedBinding).parts)
		else:
			b = DisplayBinding.new().bind(l.field, l.fmt)
		b.update_from(v)
		if b.text != l.text or l.field == "":
			bad.append("%s %s != %s" % [l.field, b.text, l.text])
		b.free()
	return bad


func _initialize() -> void:
	palette()
	board()
	calls()
	locks()
	keys()
	stand_down()
	real_sim()
	print("crew-console: %d failures" % failures)
	quit(1 if failures else 0)


## AC6: every state maps to one token, icon and word; contrast and colour-blind separation.
func palette() -> void:
	var r: Dictionary = CrewPalette.check()
	for l in r.lines: print("    " + l)
	check("AC6 palette: contrast >= 3:1 on the panel, chip words >= 4.5:1, neighbours apart under deutan/protan/tritan (or icon and edge differ)", r.ok)
	var all_states: Array = SimBridge.WORK_STATES + ["sending"]
	check("AC6 every work_state and sending has exactly one token, icon and word", all_states.all(func(s): return CrewPalette.STATES.has(s) and CrewPalette.TOKENS.has(CrewPalette.token_of(s)) and CrewPalette.word_of(s) != "" and CrewPalette.icon_of(s) != ""))
	check("AC6 CIEDE2000 matches Sharma et al. (pairs 1 and 17)", absf(CrewPalette.delta_e2000_lab(Vector3(50, 2.6772, -79.7751), Vector3(50, 0, -82.7485)) - 2.0425) < 0.0001
		and absf(CrewPalette.delta_e2000_lab(Vector3(50, 2.5, 0), Vector3(73, 25, -18)) - 27.1492) < 0.0001)
	check("OQ9: a decline reads 'Needs you: declined, open to talk'", CrewPalette.word_of("declined") == "Needs you: declined, open to talk")
	check("colour is never alone: every token has an icon, and the legend names them all", CrewPalette.LEGEND.size() == CrewPalette.TOKENS.size())


func board() -> void:
	var c := CrewConsole.new()
	root.add_child(c)
	c.show_crew({})
	check("no crew: the console says so", texts(c) == ["No crew aboard yet."])
	c.show_crew(fixture("board"))
	check("the board: five rows, title for the board", c.find_children("Member_*", "", true, false).size() == 5 and c.title() == CrewConsole.TITLE_BOARD)
	check("every free member's row offers Offer, and their chip says Can offer", ["medic", "engineer", "analyst", "pilot", "counselor"].all(func(id): return btn(c, "Quick_" + id) != null and btn(c, "Quick_" + id).text == "Offer ▸" and (c.find_child("Chip_" + id, true, false) as CrewChip).state == "free"))
	check("the header strip: ship default Ask (consent), auto-run, the free resources as gauges", btn(c, "Policy").text.begins_with("Ask (consent)") and btn(c, "Auto_critical_only") != null and c.find_children("Gauge_*", "", true, false).size() == 4)
	check("V7b the legend waits behind ? (no intent); opened, it shows every token", c.find_children("Legend_*", "", true, false).is_empty() and c.press("help:legend").is_empty()
		and c.find_children("Legend_*", "", true, false).size() == CrewPalette.TOKENS.size())
	c.press("help:legend")
	check("V7: every Label on the board is a binding that re-derives its text %s" % [bound(c).slice(0, 2)], bound(c).is_empty())
	check("D-21: no digits on the board", texts(c).all(func(t): return not RegEx.create_from_string("[0-9]").search(t)))
	check("no label under 12 logical", c.find_children("*", "Label", true, false).all(func(l): return (l as Label).get_theme_font_size("font_size") >= 12))
	# Mixed (the five offered at once with start on_accept): whose move first.
	c.show_crew(fixture("mixed"))
	c.end_call()
	var order: Array = c.find_child("Roster", true, false).get_children().map(func(n): return str(n.name).trim_prefix("Member_"))
	check("needs-you rows sort first, then the rest in crew order (%s)" % [order], order == ["medic", "pilot", "engineer", "analyst", "counselor"])
	var row: Control = c.find_child("Member_pilot", true, false)
	check("the pulsing row says so (an inset ring)", row.has_meta("pulse"))
	check("needs-you rows offer Answer; working rows have no quick action", btn(c, "Quick_pilot").text == "Answer ▸" and btn(c, "Quick_engineer") == null)
	check("V7 on the mixed board %s" % [bound(c).slice(0, 2)], bound(c).is_empty())
	var c1 := CrewConsole.new()
	root.add_child(c1)
	c1.show_crew(fixture("board"))
	c1.show_crew(fixture("mixed"))
	check("AC10 an incoming decline opens that call when nothing is open; the pilot's concern, after it, pulses", c1.call_id == "medic" and c1.opened_by == "incoming" and c1.pulse.has("pilot"))
	c1.end_call()
	check("End call returns to the board", c1.call_id == "" and c1.find_child("Roster", true, false) != null)
	c.queue_free()
	c1.queue_free()


func calls() -> void:
	var c := CrewConsole.new()
	root.add_child(c)
	var mixed := fixture("mixed")
	c.show_crew(mixed)
	c.press("call:pilot")
	check("picking a member opens their call (no intent), on the internal videocom", c.call_id == "pilot" and c.title() == CrewConsole.TITLE_CALL and c.find_child("CallWindow", true, false) != null)
	var portrait := c.find_child("CallPortrait", true, false) as TextureRect
	check("the call portrait is >= 240 logical at the sim's emotion", portrait.custom_minimum_size.x >= 240.0 and portrait.texture == CrewPage.face("pilot", str(member_of(mixed, "pilot").emotion)))
	var start := btn(c, "Start_pilot")
	check("AC7 a concern: Start is disabled and the reason is a visible line", start != null and start.disabled and texts(c).has("Waiting: answer their concern first."))
	var answers: Array = c.find_child("Answers", true, false).get_children()
	check("AC7 four answers, Insist last, with its cost in one line (the full rule on ?)", answers.size() == 4 and str(answers[3].name) == "Reply_assert_authority"
		and texts(c).has(CrewConsoleModel.COPY["insist_short"]) and not texts(c).has(CrewConsoleModel.COPY["insist_cost"]))
	c.press("help:insist")
	check("V7b ? opens the full rule, no intent; again closes it", texts(c).has(CrewConsoleModel.COPY["insist_cost"]) and c.press("help:insist").is_empty() and not texts(c).has(CrewConsoleModel.COPY["insist_cost"]))
	var kinds := {}
	for b in answers:
		for x in b.get_children():
			if x is CrewChip.ChipIcon: kinds[x.kind] = true
	check("V7b each answer has its own icon %s" % [kinds.keys()], kinds.size() == 4)
	var terms := c.find_child("Terms", true, false)
	var info := CrewPage.work_info("work_pilot")
	check("V7b the terms are icons: a day pip per day, each resource with its pips, each effect with its arrow; the sentence is the tooltip",
		terms != null and terms.find_child("Days", true, false).get_children().filter(func(x): return x is CrewChip.ChipIcon and x.kind == "pip").size() == int(info.duration)
		and terms.find_children("Cost_*", "", true, false).size() == info.costs.size() and terms.tooltip_text == CrewPage.work_terms(info) and not texts(c).any(func(t): return t.begins_with("Takes ")))
	var bars := c.find_child("Bars", true, false)
	check("V7b the bars carry icons, not word captions", bars != null and ["stress", "fatigue", "trust"].all(func(k): return bars.find_children("*", "", true, false).any(func(x): return x is CrewChip.ChipIcon and x.kind == k))
		and not texts(bars).has("stress"))
	var ff := CrewConsoleModel.first_focus(member_of(mixed, "pilot"), mixed, {})
	check("AC7 the first focus is the first answer", ff.begins_with("reply:") and not ff.ends_with("assert_authority"))
	check("the concern's words are theirs, in the call", texts(c).has("“%s”" % str(mixed.concerns.filter(func(q): return q.actor == "pilot")[0].prompt)))
	check("Make it an order is offered, with its cost in one line", btn(c, "Order_pilot") != null and texts(c).has(CrewConsoleModel.COPY["make_order_short"]))
	check("the mini-roster shows the four others", c.find_children("Switch_*", "", true, false).size() == 4)
	check("V7 in the concern call %s" % [bound(c).slice(0, 2)], bound(c).is_empty())
	c.press("call:medic")
	check("a mini-roster chip switches the call", c.call_id == "medic" and texts(c).has("They said no. Talk it through, or make it an order."))
	var mutated: Dictionary = mixed.duplicate(true)
	for m in mutated.members:
		if m.id == "medic": m.emotion = "loving"
	c.show_crew(mutated)
	check("the sim's emotion picks the call's face (mutated to loving)", (c.find_child("CallPortrait", true, false) as TextureRect).texture == CrewPage.face("medic", "loving"))
	# OQ4: an incoming concern never steals an open call or an armed confirm.
	var c2 := CrewConsole.new()
	root.add_child(c2)
	c2.show_crew(fixture("board"))
	c2.press("call:counselor")
	c2.show_crew(mixed)
	check("AC10 with a call open, incoming concerns pulse and the call stays", c2.call_id == "counselor" and c2.pulse.has("medic") and c2.pulse.has("pilot"))
	var c3 := CrewConsole.new()
	root.add_child(c3)
	c3.show_crew(fixture("board"))
	c3.press("policy:orders")
	c3.show_crew(mixed)
	check("AC10 with a confirm armed, nothing opens; the rows pulse", c3.call_id == "" and c3.armed == "policy:orders" and c3.pulse.has("medic"))
	# Working: day k of n and whose move it is.
	var w := CrewConsole.new()
	root.add_child(w)
	w.show_crew(fixture("working"))
	w.press("call:analyst")
	check("working: the day in words and the others as faces with their state (V7b)", texts(w).any(func(t): return t.begins_with("On day ") and t.contains(" of "))
		and w.find_child("Whose", true, false) != null and w.find_child("Whose", true, false).get_children().size() == 4
		and w.find_child("Whose", true, false).get_children().all(func(x): return x.find_child("Face_*", true, false) is TextureRect))
	check("working: the chip carries the start terms (agreed)", texts(w.find_child("Chip_analyst", true, false)).has("Working · agreed"))
	check("V7 in the working call %s" % [bound(w).slice(0, 2)], bound(w).is_empty())
	# Hold: the hold's words and Resume in the call.
	var h := CrewConsole.new()
	root.add_child(h)
	var hold := fixture("hold")
	h.show_crew(fixture("board"))
	h.show_crew(hold)
	check("a hold opens on the held person, with the sim's words and Resume", h.call_id == str(hold.holds[0].actor) and h.find_child("HoldBanner", true, false) != null
		and texts(h).has("Auto-run held: %s %s" % [hold.holds[0].name, hold.holds[0].line]) and btn(h, "Resume_" + str(hold.holds[0].id)) != null)
	check("V7 in the hold call %s" % [bound(h).slice(0, 2)], bound(h).is_empty())
	check("the call never closes on a timer (no Timer nodes, no _process)", h.find_children("*", "Timer", true, false).is_empty() and not h.is_processing())
	for n in [c, c2, c3, w, h]: n.queue_free()


func locks() -> void:
	var c := CrewConsole.new()
	root.add_child(c)
	c.show_crew(fixture("board"))
	var got := []
	c.intents.connect(func(l): got.append(l))
	c.press("how:counselor:orders")
	check("AC11 the How selector changes without an intent", got.is_empty() and c.how["counselor"] == "orders")
	c.press("how:counselor:consent")
	check("AC11 How starts at the ship default (Ask under consent)", CrewConsoleModel.how_of(c.crew, "engineer", {"how": c.how}) == "consent")
	check("AC12 Offer arms on the first press (no intent)", c.press("quick:counselor:offer:counselor").is_empty() and c.armed == "offer:counselor" and got.is_empty() and c.call_id == "counselor")
	var sent := c.press("offer:counselor")
	check("AC12 the confirm sends offer (start on_accept) and ask", sent.size() == 2 and sent[0]["k"] == "crew_offer" and sent[0].get("start") == "on_accept" and sent[1]["k"] == "crew_ask" and got.size() == 1)
	check("AC8 sending: the member's state is sending, every action disabled, with why", CrewConsoleModel.state(member_of(c.crew, "counselor"), {"sending": c.sending}) == "sending"
		and btn(c, "Offer_counselor").disabled and btn(c, "Offer_counselor").text == CrewPage.OFFER_PENDING and texts(c).has(CrewConsoleModel.REASONS["sending"]))
	check("AC8 a second press on that member emits nothing", c.press("offer:counselor").is_empty() and c.press("offer:counselor").is_empty() and got.size() == 1)
	check("AC8 other members stay actionable", c.press("offer:engineer").is_empty() and c.armed == "offer:engineer")
	c.press("how:pilot:orders")
	var ord := c.press("offer:pilot") + c.press("offer:pilot")
	check("AC11 an Order offer carries start now", ord.size() == 2 and ord[0].get("start") == "now")
	c.on_refused([], sent)
	check("AC8 the tick that carried the counselor's intents lifts only her lock", not c.sending.has("counselor") and c.sending.has("pilot"))
	c.on_refused([{"i": 0, "reason": "crew:blocked:insufficient_resource:compute", "intent": ord[0]}], ord)
	c.end_call()
	check("a refusal is never silent: the pilot's lock lifts and the reason shows on the row", not c.sending.has("pilot") and texts(c).any(func(t): return t.begins_with("Couldn't start: not enough archive compute slots free.")))
	c.press("policy:orders")
	var pol := c.press("policy:orders")
	check("AC11 the ship default is a confirmed crew_policy", pol.size() == 1 and line_of(pol[0]) == {"command": "policy", "policy": "orders"})
	c.press("orders:hands_on")
	var ao := c.press("orders:hands_on")
	check("AC11 auto-run is a confirmed crew_orders", ao.size() == 1 and line_of(ao[0]) == {"command": "orders", "preset": "hands_on"})
	c.queue_free()


## V6 (AC13): the keyboard and the pad reach every action; no single key or button decides.
func kev(k: int) -> InputEventKey:
	var e := InputEventKey.new()
	e.pressed = true
	e.physical_keycode = k
	return e

func pev(b: int) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.pressed = true
	e.button_index = b
	return e

func keys() -> void:
	var c := CrewConsole.new()
	root.add_child(c)
	c.show_crew(fixture("board"))
	var got := []
	c.intents.connect(func(l): got.append(l))
	check("V6 down focuses the first row", c.key(kev(KEY_DOWN)) and c.focus_action == "call:medic" and (c.find_child("Member_medic", true, false) as Control).has_meta("focused"))
	c.key(kev(KEY_DOWN))
	check("V6 Enter opens the focused member's call (no intent)", c.key(kev(KEY_ENTER)) and c.call_id == "engineer" and got.is_empty())
	check("V6 the call's first focus is its first action", c.focus_action == "offer:engineer")
	check("V6 O toggles Ask and Order (no intent)", c.key(kev(KEY_O)) and c.how["engineer"] == "orders" and got.is_empty())
	c.key(kev(KEY_O))
	c.key(kev(KEY_ENTER))
	check("V6 Enter arms the offer; nothing is sent", c.armed == "offer:engineer" and got.is_empty())
	check("V6 Esc disarms first", c.key(kev(KEY_ESCAPE)) and c.armed == "" and c.call_id == "engineer")
	c.key(kev(KEY_ENTER))
	c.key(kev(KEY_ENTER))
	check("V6 Enter twice sends the offer (the confirm)", got.size() == 1 and got[0][0].k == "crew_offer")
	c.key(kev(KEY_BRACKETRIGHT))
	check("V6 ] switches the call to the next member", c.call_id == "analyst")
	check("V6 Esc ends the call, then is left for the ship (step back)", c.key(kev(KEY_ESCAPE)) and c.call_id == "" and not c.key(kev(KEY_ESCAPE)))
	var m := CrewConsole.new()
	root.add_child(m)
	m.show_crew(fixture("mixed"))
	m.end_call()
	m.press("call:pilot")
	var sent := []
	m.intents.connect(func(l): sent.append(l))
	m.key(kev(KEY_2))
	check("V6 2 arms the second answer; nothing is sent", m.armed.begins_with("reply:") and sent.is_empty())
	m.key(kev(KEY_2))
	check("V6 2 again sends that answer", sent.size() == 1 and sent[0][0].k == "crew_reply" and line_of(sent[0][0]).approach == str(CrewConsoleModel.concern_of(m.crew, "pilot").options[1].approach))
	# The pad: the same paths.
	var p := CrewConsole.new()
	root.add_child(p)
	p.show_crew(fixture("board"))
	var ps := []
	p.intents.connect(func(l): ps.append(l))
	p.key(pev(JOY_BUTTON_DPAD_DOWN))
	p.key(pev(JOY_BUTTON_A))
	check("V6 pad: D-pad and A open a call; RB switches; B ends it", p.call_id == "medic" and p.key(pev(JOY_BUTTON_RIGHT_SHOULDER)) and p.call_id == "engineer" and p.key(pev(JOY_BUTTON_B)) and p.call_id == "")
	var stick := InputEventJoypadMotion.new()
	stick.axis = JOY_AXIS_LEFT_Y
	stick.axis_value = 0.9
	var before := p.focus_action
	p.key(stick)
	check("V6 pad: the left stick moves the focus once per push", p.focus_action != before and not p.key(stick))
	# NT1/NT3 for the console: every key and button, pressed once, in every state, decides nothing.
	var bad := []
	for fx in ["board", "mixed", "working", "hold", "standdown"]:
		for who in ["", "medic", "pilot", "analyst"]:
			var q := CrewConsole.new()
			root.add_child(q)
			q.show_crew(fixture(fx))
			q.end_call()
			if who != "": q.press("call:" + who)
			var out := []
			q.intents.connect(func(l): out.append(l))
			for k in CrewConsole.KEYS:
				q.armed = ""
				q.key(kev(k))
			for b in CrewConsole.PAD:
				q.armed = ""
				q.key(pev(b))
			if not out.is_empty(): bad.append([fx, who, out[0][0].k])
			q.queue_free()
	check("V6 NT1/NT3: no single key or pad button sends a decision, in any state %s" % [bad.slice(0, 2)], bad.is_empty())
	for n in [c, m, p]: n.queue_free()


## V8 (AC16, crew_core 0.6): a stand-down recorded from the real sim (the guided crossing under
## hands_on): the held call offers Let them rest and Ask them to carry on, confirmed, as
## crew_stand_down; unheld, the state is stand_down_asked; once granted, resting.
func stand_down() -> void:
	var sd := fixture("standdown")
	var c := CrewConsole.new()
	root.add_child(c)
	c.show_crew(fixture("board"))
	c.show_crew(sd)
	var who := str(sd.holds[0].actor)
	var sid := str(CrewConsoleModel.member(sd, who).stand_down)
	check("V8 the stand-down hold opens the call with its words and both answers", c.call_id == who and texts(c).has("Auto-run held: %s %s" % [sd.holds[0].name, sd.holds[0].line])
		and btn(c, "Rest_" + sid) != null and btn(c, "CarryOn_" + sid) != null and texts(c).has(CrewConsoleModel.COPY["stand_down_short"]))
	check("V8 Let them rest needs a second press", c.press("standdown:%s:true" % sid).is_empty())
	var r := c.press("standdown:%s:true" % sid)
	check("V8 the confirmed answer is crew_stand_down resolve_stand_down, release true", r.size() == 1 and r[0].k == "crew_stand_down" and line_of(r[0]) == {"command": "resolve_stand_down", "id": sid, "release": true})
	var unheld: Dictionary = sd.duplicate(true)
	unheld.holds = []
	for m in unheld.members:
		if m.id == who: m.work_state = "stand_down_asked"
	var u := CrewConsole.new()
	root.add_child(u)
	u.show_crew(unheld)
	u.press("call:" + who)
	check("V8 unheld, the state is stand_down_asked: Needs you, with both answers", (u.find_child("Chip_" + who, true, false) as CrewChip).state == "stand_down_asked"
		and texts(u).has(CrewPalette.word_of("stand_down_asked")) and btn(u, "Rest_" + sid) != null)
	var rest := fixture("resting")
	var v := CrewConsole.new()
	root.add_child(v)
	v.show_crew(rest)
	check("V8 granted, they rest (the sim's resting state, its chip)", str(CrewConsoleModel.member(rest, who).work_state) == "resting" and (v.find_child("Chip_" + who, true, false) as CrewChip).state == "resting")
	check("V7 on the stand-down calls", bound(c).is_empty() and bound(u).is_empty() and bound(v).is_empty())
	for n in [c, u, v]: n.queue_free()


func real_sim() -> void:
	# AC12: free -> working in two presses on an accepting member, against the real sim.
	var sim := SimBridge.new()
	sim.want_minor = SimBridge.CONSOLE_MINOR
	var ok := sim.start() and sim.new_game(1, "free_nav", false, {}, "", "consent")
	check("2.11 game with a consent crew (%s)" % sim.last_error, ok and int(sim.hello_reply.proto.minor) == SimBridge.CONSOLE_MINOR and str(member_of(sim.crew, "engineer").get("work_state")) == "free")
	var c := CrewConsole.new()
	root.add_child(c)
	c.show_crew(sim.crew)
	c.intents.connect(sim.queue)
	var presses := 0
	presses += 1
	c.press("quick:engineer:offer:engineer")
	presses += 1
	c.press("offer:engineer")
	ok = ok and sim.send([], 0.0)
	c.on_refused(sim.queued_refused(), sim.last_queued)
	c.show_crew(sim.crew)
	var eng := member_of(sim.crew, "engineer")
	var lbl := str(sim.crew.lines[-1].label) if not sim.crew.get("lines", []).is_empty() else ""
	check("AC12 Ask, accepted: working in %d presses (answer %s, terms %s)" % [presses, lbl, eng.get("work", {}).get("terms") if eng.get("work") is Dictionary else null], ok and presses == 2 and sim.last_refused.is_empty() and lbl == "accept"
		and eng.work_state == "working" and eng.work.terms == "agreed_start" and not c.sending.has("engineer"))
	# Offer everyone else at once; then Insist on a concern (the sim accepts it) and order a decline.
	for id in ["medic", "pilot", "counselor"]: # the analyst stays free, so one compute slot is left for an order
		c.press("offer:" + id)
		c.press("offer:" + id)
	ok = ok and sim.send([], 0.0)
	c.on_refused(sim.queued_refused(), sim.last_queued)
	c.show_crew(sim.crew)
	var states := {}
	for m in sim.crew.members: states[m.id] = m.work_state
	print("    after the offers: %s refused %s" % [states, sim.last_refused])
	check("the sim names each answer's state (no client derivation)", states.values().all(func(s): return s in SimBridge.WORK_STATES))
	var needing: Array = states.keys().filter(func(id): return states[id] in ["concern", "declined", "deferred"])
	check("someone needs the captain after the offers (seed 1: a concern or a decline)", not needing.is_empty())
	if not needing.is_empty():
		var who: String = needing[0]
		c.press("call:" + who)
		var q := CrewConsoleModel.concern_of(sim.crew, who)
		var act := "reply:%s:assert_authority" % q.get("issue", "")
		c.press(act)
		var reply := c.press(act)
		ok = sim.send([], 0.0)
		check("OQ5 Insist is a captain_reply the real sim accepts, carrying start on_accept (V4) (%s)" % [sim.last_refused], ok and reply.size() == 1 and line_of(reply[0]).approach == "assert_authority" and reply[0].get("start") == "on_accept" and sim.last_refused.is_empty())
		c.on_refused(sim.queued_refused(), sim.last_queued)
		c.show_crew(sim.crew)
		var st_after := str(member_of(sim.crew, who).get("work_state", ""))
		check("V4 after the reply they reconsider at once: no longer asked (%s)" % st_after, st_after != "asked" and not sim.crew.requests.any(func(q): return q.actor == who))
		var w = member_of(sim.crew, who).get("work")
		if w is Dictionary and str(w.get("status", "")) == "offered":
			c.press("order:" + str(w.task))
			var o := c.press("order:" + str(w.task))
			ok = sim.send([], 0.0)
			var m := member_of(sim.crew, who)
			check("AC3 'Make it an order' is crew_start as orders: the work starts, refused_order, the ship default stays consent (%s, %s)" % [sim.last_refused, m], ok and o.size() == 1 and o[0].get("as") == "orders"
				and sim.last_refused.is_empty() and m.work_state == "working" and m.work.terms == "refused_order" and sim.crew.captaincy == "consent")
	sim.stop()
	# Ids never repeat across consoles rebuilt in the same crew turn; refusals have plain words.
	var us := SimBridge.new()
	us.want_minor = SimBridge.CONSOLE_MINOR
	ok = us.start() and us.new_game(1, "free_nav", false, {}, "", "orders")
	var pa := CrewConsole.new()
	pa.show_crew(us.crew)
	var oa := pa.offer_intents("counselor")
	ok = ok and us.send(oa, 0.0) and us.last_refused.is_empty()
	var pb := CrewConsole.new()
	pb.show_crew(us.crew)
	var ob := pb.offer_intents("counselor")
	check("a rebuilt console in the same crew turn makes new task and request ids", ok and line_of(ob[0])["id"] != line_of(oa[0])["id"] and line_of(ob[1])["id"] != line_of(oa[1])["id"])
	ok = ok and us.send(oa, 0.0)
	var dup: Array = us.last_refused.map(func(r): return str(r.get("reason", "")))
	check("re-sending an old id is refused (altered_duplicate, request capacity/id/clock)", ok and dup.size() == 2 and dup[0].begins_with("crew:blocked:altered_duplicate:"))
	for reason in dup:
		var words := CrewPage.refusal_words(reason, us.crew)
		check("plain words for %s: %s" % [reason, words], not words.contains("_") and not words.contains("/") and not words.contains("{") and not RegEx.create_from_string("[0-9]").search(words))
	us.stop()
	pa.free()
	pb.free()
	# Below 2.11 the envelope is refused (bad_intent): the console needs the console minor.
	var old := SimBridge.new()
	old.want_minor = SimBridge.INTERLUDE_MINOR
	ok = old.start() and old.new_game(1, "free_nav", false, {}, "", "consent")
	var pc := CrewConsole.new()
	pc.show_crew(old.crew)
	var sent_ok := old.send(pc.offer_intents("pilot", "now"), 0.0)
	check("below 2.11 an offer with start is bad_intent (%s)" % old.last_error, ok and not sent_ok and old.last_error.contains("bad_intent"))
	old.stop()
	pc.free()
	c.queue_free()
