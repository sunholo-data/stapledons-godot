class_name NewsCopy
extends RefCounted
## M4.4 the news copy: five tiers of template paragraphs (data/news/templates.json), the fixed
## labels and the reason -> phrase table (data/news/copy.json), and the lint behind `make
## news-lint`. A template holds NO numeral except inside a {slot}; a slot is filled from one sim
## field (consequence.news.slots.*), formatted and nothing more. Godot never computes a number
## shown here (D-21: numbers on screen come only from sim fields).

const TEMPLATES := "res://data/news/templates.json"
const COPY := "res://data/news/copy.json"
const PER_TIER := 4 # sim/consequence.ail templatesPerTier(); the lint cross-checks it
const TIERS := 5
const MAX_CHARS := 280 # D-21, sim/ai.ail maxCharsFor("news")
const SLOT_FMT := "%.2f"
const WORST_SLOT := 99999.99 # the widest slot the lint expects (digits only; width, not meaning)
const NO_AGE_BELOW := 0.005 # a value that renders as "0.00" with SLOT_FMT; the Sol return is exactly 0


static func load_json(path: String) -> Dictionary:
	var v: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return v if v is Dictionary else {}


## The paragraph for template id `id` (tier * PER_TIER + variant), slots filled from `slots`
## ({elapsed_years, news_epoch, news_age_years}, the sim's numbers). "" and a push_error when the
## id is out of range or a slot is missing: a wrong paragraph is never shown.
static func paragraph(templates: Dictionary, id: int, slots: Dictionary) -> String:
	var tiers: Array = templates.get("tiers", [])
	var t := id / PER_TIER
	var v := id % PER_TIER
	if id < 0 or t >= tiers.size() or v >= tiers[t]["templates"].size():
		push_error("news: no template %d" % id)
		return ""
	return fill(tiers[t]["templates"][v], slots)


static func fill(text: String, slots: Dictionary) -> String:
	var out := text
	for name: String in slot_names(text):
		if not slots.has(name) or not (slots[name] is float or slots[name] is int):
			push_error("news: template slot {%s} has no sim number" % name)
			return ""
		out = out.replace("{%s}" % name, SLOT_FMT % float(slots[name]))
	return out


static func slot_names(text: String) -> Array:
	var names: Array = []
	var rx := RegEx.create_from_string("\\{([a-z_]*)\\}")
	for m in rx.search_all(text):
		names.append(m.get_string(1))
	return names


static func without_slots(text: String) -> String:
	return RegEx.create_from_string("\\{[a-z_]*\\}").sub(text, "", true)


## D-45(B): true when the bound news age would render as "0.00" (the home arrival: light-time from
## Sol is nil). The panel then composes the header without the age clause and shows the no-age body
## phrase for a template paragraph; the sim's field is unchanged and merely formatted.
static func is_no_age(slots: Variant) -> bool:
	if not (slots is Dictionary) or not slots.has("news_age_years"):
		return false
	var v: Variant = slots["news_age_years"]
	return (v is float or v is int) and absf(float(v)) < NO_AGE_BELOW


## The header's parts for ComposedBinding: the lead, the epoch slot, and either the age clause or,
## when the age renders "0.00", the no-age tail. Labels carry no numeral (the lint enforces it).
static func header_parts(copy: Dictionary, no_age: bool) -> Array:
	var labels: Dictionary = copy.get("labels", {})
	if no_age:
		return [labels["header_lead"], ["consequence.news.slots.news_epoch", "+%.2f"], labels["header_no_age_tail"]]
	return [labels["header_lead"], ["consequence.news.slots.news_epoch", "+%.2f"], labels["header_mid"], ["consequence.news.slots.news_age_years", "%.2f"], labels["header_tail"]]


static func has_digit(s: String) -> bool:
	for c in s:
		if c >= "0" and c <= "9":
			return true
	return false


## The reason phrase for a sim reason code, "" (and a push_error) for one the table does not know.
## The caller shows an explicit unknown-reason line: never a silent blank.
static func reason_phrase(copy: Dictionary, code: String) -> String:
	var r: Dictionary = copy.get("reasons", {})
	if not r.has(code):
		push_error("news: unknown fallback reason code '%s'" % code)
		return ""
	return r[code]


## Every problem in a template file and copy file; empty when both are clean.
static func lint(templates: Dictionary, copy: Dictionary) -> Array:
	var bad: Array = []
	var allowed: Array = templates.get("slots", [])
	var tiers: Array = templates.get("tiers", [])
	if tiers.size() != TIERS:
		bad.append("expected %d tiers, found %d" % [TIERS, tiers.size()])
	var sample := {}
	for s: String in allowed:
		sample[s] = WORST_SLOT
	for i in tiers.size():
		var ts: Array = tiers[i].get("templates", [])
		if int(tiers[i].get("tier", -1)) != i:
			bad.append("tier %d is listed out of order" % i)
		if ts.size() != PER_TIER:
			bad.append("tier %d has %d templates, the sim draws among %d" % [i, ts.size(), PER_TIER])
		for j in ts.size():
			var t: String = ts[j]
			var where := "tier %d template %d" % [i, j]
			if has_digit(without_slots(t)):
				bad.append("%s: a numeral outside a slot" % where)
			for n: String in slot_names(t):
				if not allowed.has(n):
					bad.append("%s: unknown slot {%s}" % [where, n])
			if t.count("{") != t.count("}") or t.count("{") != slot_names(t).size():
				bad.append("%s: a malformed slot" % where)
			var filled := fill(t, sample)
			if filled.length() > MAX_CHARS or filled == "":
				bad.append("%s: %d characters filled, the cap is %d" % [where, filled.length(), MAX_CHARS])
	for k: String in copy.get("labels", {}):
		if has_digit(copy["labels"][k]):
			bad.append("label %s contains a numeral" % k)
	for code: String in copy.get("reasons", {}):
		var p: String = copy["reasons"][code]
		if p.strip_edges() == "":
			bad.append("reason %s has no phrase" % code)
		if has_digit(p):
			bad.append("reason %s: the phrase contains a numeral" % code)
	return bad
