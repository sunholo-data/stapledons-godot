class_name CrewConsoleModel
extends RefCounted
## R2-CREW-CONSOLE-V2 V2 (design crew-console-v2.md §V2, §V4): what the Crew console shows for a
## member, as pure functions of the sim's crew section and the client's own state. It reads the
## sim's `work_state` (protocol 2.11) and never derives it (D-20); the one client overlay is
## `sending`: an intent about the member is queued and the ship has not ticked yet.
##   client: {sending: {member id: true}, how: {member id: "consent" | "orders"}}
## Every action is a dictionary {action, text, enabled, why, primary}; `action` is CrewConsole's
## press() vocabulary ("offer:<id>", "start:<task>", "order:<task>", "reply:<issue>:<approach>",
## "relief:<id>:<true|false>", "resume:<hold>").

const NEEDS := ["held", "concern", "declined", "deferred", "relief_asked", "stand_down_asked"]
## The decision block's reason line per state, worded (D-21: no digits). Start is disabled with it.
const REASONS := {
	"sending": "Sent. The ship passes it on at its next moment; nothing to do.",
	"asked": "Waiting for their answer.",
	"offered": "Offered. They haven't agreed yet; if you leave it, the offer lapses.",
	"concern": "Waiting: answer their concern first.",
	"declined": "They said no. Talk it through, or make it an order.",
	"deferred": "Waiting: they asked for time.",
	"relief_asked": "They ask to step back from this work.",
	"stand_down_asked": "They need to stand down for a while.",
	"agreed": "They agreed.",
	"working": "Crew days pass as the ship travels.",
	"resting": "Resting. Crew days pass as the ship travels.",
	"done": "Their last work is done.",
	"stopped": "Their last work stopped.",
	"held": "Auto-run waits until you resume it.",
	"free": "Free for work.",
}
## crew_core 0.4.1 reply approaches as the captain's choices; Insist (assert_authority) is the
## game's own fourth answer (OQ5): crew_core's suggestions offer three.
const APPROACH_WORDS := {
	"clear_scope": "Make the job clearer", "ask_advice": "Ask their advice", "stage_plan": "Plan it in stages",
	"explain_priority": "Explain why it matters", "assert_authority": "Insist: it's an order",
}
const RESUME_AFTER_STAND_DOWN := "Answer the stand-down first: resuming now would let it lapse, and a lapsed stand-down counts as refusing their rest."
const RESUME_AFTER_STAND_DOWN_SHORT := "Answer them first; then auto-run can resume."
const COST_KEYS := {"stand_down": "stand_down_cost", "relief": "relief_cost"}
## The words Insist sends (crew_core captain_reply text; no digits, under 280 characters).
const INSIST_TEXT := "I've heard you. This needs doing, and I'm asking you to do it."
## What each choice costs, as the rule in words (crew_core codec.traitDelta, conversations.reaction);
## never a forecast for this person (Pillar 1).
const COST := {
	"ask": "Ask: they decide. The work starts only if they agree. Agreed work: trust in you rises a little.",
	"order": "Order: the work starts now, whatever they say. Over a refusal or a concern, trust in you falls sharply, most of all for someone who doesn't easily go along.",
	"insist": "An order in words. It raises their stress. For most people trust falls, though someone dutiful and unstrained may respect it. They still decide afterwards.",
	"answers": "No answer is always right. It depends on who they are and how stretched they are.",
	"make_order": "Starts now, over their answer. Trust in you falls sharply, most of all for someone who doesn't easily go along.",
	"lapse": "If you leave it, the offer lapses.",
}


static func member(crew: Dictionary, id: String) -> Dictionary:
	for m in crew.get("members", []):
		if m is Dictionary and str(m.get("id", "")) == id:
			return m
	return {}


static func index_of(crew: Dictionary, id: String) -> int:
	var ms: Array = crew.get("members", [])
	for i in ms.size():
		if ms[i] is Dictionary and str(ms[i].get("id", "")) == id:
			return i
	return -1


## The member's state: the client's `sending` while an intent about them is queued, else the sim's.
static func state(m: Dictionary, client: Dictionary) -> String:
	var id := str(m.get("id", ""))
	if client.get("sending", {}).has(id):
		return "sending"
	var s := str(m.get("work_state", "free"))
	return s if CrewPalette.STATES.has(s) else "free"


static func locked(id: String, client: Dictionary) -> bool:
	return client.get("sending", {}).has(id)


static func needs_you(s: String) -> bool:
	return s in NEEDS


static func reason(s: String) -> String:
	return str(REASONS.get(s, ""))


## The ship default's word: "Ask" for consent, "Order" for orders.
static func how_word(captaincy: String) -> String:
	return "Order" if captaincy == "orders" else "Ask"


static func how_of(crew: Dictionary, id: String, client: Dictionary) -> String:
	return str(client.get("how", {}).get(id, crew.get("captaincy", "consent")))


static func concern_of(crew: Dictionary, id: String) -> Dictionary:
	for q in crew.get("concerns", []):
		if q is Dictionary and str(q.get("actor", "")) == id:
			return q
	return {}


static func hold_of(crew: Dictionary, id: String) -> Dictionary:
	for h in crew.get("holds", []):
		if h is Dictionary and str(h.get("actor", "")) == id:
			return h
	return {}


static func relief_of(crew: Dictionary, id: String) -> Dictionary:
	for r in crew.get("reliefs", []):
		if r is Dictionary and str(r.get("author", "")) == id:
			return r
	return {}


## The board's order: whose move it is first (needs you, then agreed), then the crew's order.
static func board_order(crew: Dictionary, client: Dictionary) -> Array:
	var ms: Array = crew.get("members", []).filter(func(m): return m is Dictionary)
	var keyed := []
	for i in ms.size():
		keyed.append([int(CrewPalette.SORT.get(state(ms[i], client), 2)), i, ms[i]])
	keyed.sort_custom(func(a, b): return a[0] < b[0] or (a[0] == b[0] and a[1] < b[1]))
	return keyed.map(func(k): return k[2])


## The one quick action a board row offers, or {}: Offer (free), Start (agreed), Answer (needs
## you), Resume (held). The row opens the call; the action then waits in it, armed or focused.
static func quick(m: Dictionary, crew: Dictionary, client: Dictionary) -> Dictionary:
	var s := state(m, client)
	var id := str(m.get("id", ""))
	match s:
		"free", "done", "stopped": return {"text": "Offer ▸", "action": "offer:" + id}
		"agreed": return {"text": "Start ▸", "action": "start:" + str(m.get("work", {}).get("task", ""))}
		"held": return {"text": "Resume ▸", "action": "resume:" + str(hold_of(crew, id).get("id", ""))}
	if needs_you(s):
		return {"text": "Answer ▸", "action": ""}
	return {}


## The decision block for a member, in focus order: the next legal actions first. Disabled ones
## carry their reason (`why`), shown as a line, never only a tooltip.
static func actions(m: Dictionary, crew: Dictionary, client: Dictionary) -> Array:
	var id := str(m.get("id", ""))
	var s := state(m, client)
	var task := str(m.get("work", {}).get("task", "")) if m.get("work") is Dictionary else ""
	var out := []
	var hold := hold_of(crew, id)
	if s == "sending":
		out.append({"action": "offer:" + id, "text": CrewPage.OFFER_PENDING, "enabled": false, "why": reason("sending"), "primary": true})
		out.append({"action": "start:", "text": "Start the work", "enabled": false, "why": reason("sending"), "primary": false})
		return out
	var q := concern_of(crew, id)
	var sd := str(m.get("stand_down", ""))
	# Eval D1: a stand-down is answered first. Resuming auto-run before the answer would let the
	# duty check-in lapse, which crew_core counts as refusing their rest; so Resume waits, with why,
	# and "Ask them to carry on" is the explicit, confirmed way to refuse.
	if sd != "" and (s == "stand_down_asked" or s == "held"):
		out.append({"action": "standdown:%s:true" % sd, "text": "Let them rest", "enabled": true, "why": "", "primary": true, "cost": COST_KEYS["stand_down"]})
		out.append({"action": "standdown:%s:false" % sd, "text": "Ask them to carry on", "enabled": true, "why": "", "primary": true})
		if not hold.is_empty():
			out.append({"action": "resume:" + str(hold.get("id", "")), "text": "Resume auto-run", "enabled": false, "why": RESUME_AFTER_STAND_DOWN, "primary": false})
		return out
	if not hold.is_empty():
		out.append({"action": "resume:" + str(hold.get("id", "")), "text": "Resume auto-run", "enabled": true, "why": "", "primary": true})
	if s in ["concern", "declined", "deferred"] or (s == "held" and not q.is_empty()):
		var issue := str(q.get("issue", ""))
		for o in q.get("options", []):
			var ap := str(o.get("approach", ""))
			out.append({"action": "reply:%s:%s" % [issue, ap], "text": APPROACH_WORDS.get(ap, ap.replace("_", " ")), "enabled": issue != "", "why": "", "primary": true})
		out.append({"action": "reply:%s:assert_authority" % issue, "text": APPROACH_WORDS["assert_authority"], "enabled": issue != "", "why": "", "primary": false, "cost": COST["insist"]})
		out.append({"action": "start:" + task, "text": "Start the work", "enabled": false, "why": reason(s), "primary": false})
		if task != "":
			out.append({"action": "order:" + task, "text": "Make it an order instead…", "enabled": true, "why": "", "primary": false, "cost": COST["make_order"]})
		return out
	match s:
		"free", "done", "stopped":
			var verb := "Order" if how_of(crew, id, client) == "orders" else "Ask"
			out.append({"action": "offer:" + id, "text": "%s them to %s" % [verb, CrewConsoleModel.work_verb(str(m.get("work", {}).get("recipe", "work_" + id)) if m.get("work") is Dictionary else "work_" + id)], "enabled": true, "why": "", "primary": true})
		"asked", "offered":
			out.append({"action": "start:" + task, "text": "Start the work", "enabled": false, "why": reason(s), "primary": false})
		"agreed":
			out.append({"action": "start:" + task, "text": "Start the work", "enabled": true, "why": "", "primary": true})
		"relief_asked":
			var r := relief_of(crew, id)
			out.append({"action": "relief:%s:true" % r.get("id", ""), "text": "Grant relief", "enabled": true, "why": "", "primary": true})
			out.append({"action": "relief:%s:false" % r.get("id", ""), "text": "Deny relief", "enabled": true, "why": "", "primary": true})
	return out


## The first control in focus order when a call opens: the first enabled primary action.
static func first_focus(m: Dictionary, crew: Dictionary, client: Dictionary) -> String:
	for a in actions(m, crew, client):
		if a.enabled and a.primary:
			return str(a.action)
	return ""


## A work's name in the imperative after "Ask them to": the scenario's name, lower-cased first.
static func work_verb(recipe: String) -> String:
	var name := CrewPage.work_name(recipe)
	return name.left(1).to_lower() + name.substr(1) if name != "" else "take on their work"


# ------------------------------------------------------------------ display formats (V7)
## Fixed copy, each shown through a binding on the field it explains (format crew_copy:<key>).
const COPY := {
	"live": "●  LIVE · internal videocom", "calling": "⇢  Calling · internal videocom",
	"how": "How to give it", "answers": "Answer their concern", "decide": "Their decision", "work": "Their work",
	"whose": "Waiting on whom", "legend": "Legend", "ship": "Ship default:", "auto": "Auto-run:", "free": "Free:",
	"stress": "stress", "fatigue": "fatigue", "trust": "trust", "strained": "strained",
	"stress_strained": "stress, strained", "fatigue_strained": "fatigue, strained",
	"ask_cost": "Ask: they decide. The work starts only if they agree. Agreed work: trust in you rises a little.",
	"order_cost": "Order: the work starts now, whatever they say. Over a refusal or a concern, trust in you falls sharply, most of all for someone who doesn't easily go along.",
	"insist_cost": "Raises their stress. For most people trust falls, though someone dutiful and unstrained may respect it. They still decide afterwards.",
	"answers_note": "No answer is always right. It depends on who they are and how stretched they are.",
	"make_order_cost": "Starts now, over their answer. Trust in you falls sharply, most of all for someone who doesn't easily go along.",
	"lapse": "If you leave it, the offer lapses.", "on_accept": "Starts as soon as they agree.",
	# V7b: one short line each; the full rule is the tooltip, and "?" opens it.
	"ask_short": "They decide; it starts if they agree.", "order_short": "It starts now, whatever they say.",
	"insist_short": "An order in words: stress rises, trust may fall.", "make_order_short": "Starts now; trust falls sharply.",
	"armed_short": "Press again to send.", "lapse_short": "Left alone, the offer lapses.",
	"relief_short": "Granting lets them step back; denying costs trust.",
	"relief_cost": "Granting it: they step back from this work. Denying it: trust in you falls, more the longer they have waited.",
	"stand_down_short": "Rest now, or keep going; refusing costs trust.",
	"stand_down_cost": "Granting it: their work pauses while they rest, and trust rises. Refusing it: trust falls, more for an anxious person; they may ask again later.",
	"armed": "Pressed once, so it's armed. Press again to send; another choice cancels it.",
	"sending_note": "Every action for them waits until their answer arrives. You can still talk to the others.",
	"default_note": "New offers start as this. Auto-run uses it too.",
	"pick": "Pick someone to open a call.",
	"empty": "No crew aboard yet.",
	"crew_days": "Crew days pass as the ship travels.",
	"rest_title": "Standing down to rest",
	"resume_wait": "Answer them first; then auto-run can resume.", "key_days": "days", "key_stress": "stress", "key_fatigue": "fatigue", "key_trust": "trust",
}
const TERMS_WORDS := {"agreed_start": "agreed", "complied_start": "ordered", "strained_start": "ordered while strained", "refused_order": "ordered over their answer"}
const EMOTION_WORDS := {"neutral": "calm", "happy": "pleased", "sad": "sad", "angry": "angry", "fearful": "worried", "curious": "curious", "loving": "warm", "grieving": "grieving"}


## A crew format (DisplayBinding.format_field): `raw` is the bound field's value.
static func format(fmt: String, raw: Variant) -> String:
	if raw == null:
		return "-"
	var key := fmt.get_slice(":", 1)
	match fmt.get_slice(":", 0):
		"crew_state": return CrewPalette.word_of(str(raw))
		"crew_reason": return reason(str(raw))
		"crew_role": return CrewPage.role(str(raw))
		"crew_job": return CrewPage.work_name("work_" + str(raw))
		"crew_job_terms": return CrewPage.work_terms(CrewPage.work_info("work_" + str(raw)))
		"crew_job_brief": return CrewPage.work_brief(CrewPage.work_info("work_" + str(raw)))
		"crew_job_purpose": return str(CrewPage.work_info("work_" + str(raw)).get("purpose", ""))
		"crew_resource_short": return CrewPage.resource_short(str(raw))
		"crew_job_verb": return work_verb("work_" + str(raw))
		"crew_copy":
			if key.begins_with("legend_"):
				for e in CrewPalette.LEGEND:
					if "legend_" + str(e[0]) == key: return str(e[1])
			return str(COPY.get(key, ""))
		"crew_quote": return "“%s”" % str(raw)
		"crew_emotion": return str(EMOTION_WORDS.get(str(raw), str(raw)))
		"crew_terms": return str(TERMS_WORDS.get(str(raw), ""))
		"crew_resource": return CrewPage.resource_name(str(raw)).to_lower()
		"crew_how": return how_word(str(raw))
		"crew_words": return CrewPage.words(int(raw))
		"crew_first": return str(raw).get_slice(" ", 0)
		"crew_effect": return str(CrewPage.EFFECT_WORDS.get(key, ["", ""])[0 if fmt.get_slice(":", 2) == "up" else 1])
		"crew_day": return day_words(raw, int(key))
	return str(raw)


## "day two of three" for member i of a crew section (its work's started and due, the crew's turn).
static func day_words(crew: Variant, i: int) -> String:
	if not crew is Dictionary:
		return "-"
	var ms: Array = crew.get("members", [])
	if i < 0 or i >= ms.size() or not ms[i].get("work") is Dictionary:
		return "-"
	var w: Dictionary = ms[i]["work"]
	var n := maxi(1, int(w.get("due", 0)) - int(w.get("started", 0)))
	var k := clampi(int(crew.get("turn", 0)) - int(w.get("started", 0)) + 1, 1, n)
	return "day %s of %s" % [CrewPage.words(k), CrewPage.words(n)]


static func day_fraction(crew: Dictionary, m: Dictionary) -> float:
	if not m.get("work") is Dictionary:
		return 0.0
	var w: Dictionary = m["work"]
	var n := maxi(1, int(w.get("due", 0)) - int(w.get("started", 0)))
	return clampf(float(int(crew.get("turn", 0)) - int(w.get("started", 0)) + 1) / float(n), 0.0, 1.0)
