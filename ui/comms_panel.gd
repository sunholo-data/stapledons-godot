class_name CommsPanel
extends VBoxContainer
## R3-EARTH-LINK EL3 (K1, design r3/earth-link.md): the comms station's two panes, Earth only.
## Listen: Earth's newest light and its age, the Earth rate D with a phrase chosen by D alone, in
## beam or the sim's reason, and the silence line. Exchange log: one row per plan sent home.
## Every line is one ComposedBinding whose numbers are earth.* fields (D-21): the copy and the
## rate-phrase bands are data (data/ui/comms_copy.json); GDScript picks a template and formats,
## never computes. refresh(view) takes the frame's HUD view, so the display audit replays it.

const COPY := "res://data/ui/comms_copy.json"
const NAMES := "res://data/starmap/names.json"
const PANES := ["listen", "log"]

static var _copy: Dictionary = {}
static var _names: Dictionary = {}

var pane := "listen"
var head := Label.new()
var lines := VBoxContainer.new()


static func copy() -> Dictionary:
	if _copy.is_empty():
		_copy = NewsCopy.load_json(COPY)
	return _copy


func _init() -> void:
	name = "CommsPanel"
	add_theme_constant_override("separation", 8)
	head.theme_type_variation = "HUDCardTitle"
	head.add_theme_font_size_override("font_size", 16)
	add_child(head)
	lines.add_theme_constant_override("separation", 6)
	add_child(lines)


func show_pane(p: String) -> void:
	if p in PANES:
		pane = p


## The lines of the current pane for this view: [parts] each, every part copy or [field, fmt].
static func pane_lines(p: String, view: Dictionary) -> Array:
	var c := copy()
	var e: Variant = view.get("earth")
	if not e is Dictionary:
		return []
	if p == "log":
		var ms: Array = e.get("messages", [])
		if ms.is_empty():
			return [c.log.empty]
		var out := []
		for i in ms.size():
			out.append(row(c.log.row, i))
		return out
	var out := [c.listen.light_home if e.get("at_home") == true else c.listen.light, c.listen.rate + rate_phrase(c.rate_bands, float(e.get("rate", 1.0)))]
	if e.get("in_beam") == true:
		out.append(c.listen.in_beam)
	else:
		var o: Variant = e.get("out")
		out.append(c.listen.out.get(str(o.get("reason", "")) if o is Dictionary else "", c.listen.out.off_line))
		out.append(c.listen.silence)
	return out


## The Exchange log row for message i: the template with {i} put in each field path.
static func row(template: Array, i: int) -> Array:
	return template.map(func(x: Variant) -> Variant: return [str(x[0]).replace("{i}", str(i)), x[1]] if x is Array else x)


## The phrase of the first band whose min <= rate (< max when given): chosen by D, never computed.
static func rate_phrase(bands: Array, rate: float) -> Array:
	for b: Dictionary in bands:
		if rate >= float(b.get("min", -INF)) and (not b.has("max") or rate < float(b.max)):
			return b.phrase
	return []


func refresh(view: Dictionary) -> void:
	var c := copy()
	var parts := pane_lines(pane, view)
	head.text = (c.listen.head if pane == "listen" else c.log.head) if not parts.is_empty() else c.no_link
	while lines.get_child_count() < parts.size():
		var b := ComposedBinding.new()
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.add_theme_font_size_override("font_size", 14)
		b.theme_type_variation = "HUDLabel"
		lines.add_child(b)
	while lines.get_child_count() > parts.size():
		var last := lines.get_child(lines.get_child_count() - 1)
		lines.remove_child(last)
		last.free()
	for i in parts.size():
		var b := lines.get_child(i) as ComposedBinding
		b.compose(parts[i])
		b.update_from(view)


## The comms formats (DisplayBinding.format_field): formatting only, one sim field each.
static func format(fmt: String, raw: Variant) -> String:
	if raw == null:
		return "-"
	var w: Dictionary = copy().words
	match fmt:
		"comms_clock": # an Earth-clock reading, as the HUD's: +4.31 yr (before the clock's zero: −8.2 min)
			return ("+" if float(raw) >= 0.0 else "−") + ShipHud.duration_text(absf(float(raw)))
		"comms_years": return ShipHud.duration_text(float(raw)) # a span in years: s, min, h, days or yr
		"comms_days": return ShipHud.duration_text(float(raw) / 365.25) # a span in days, the same units
		"comms_beam": return w.beam_on if raw == true else w.beam_off
		"comms_sending": return w.sending if raw == true else w.not_sending
		"comms_home": return w.home if raw == true else w.away
		"comms_home_short": return w.home_short if raw == true else w.away
		"comms_port": return port_name(str(raw))
	return str(raw)


## A port's common name (data/starmap/names.json), Sol, a body's id as a name, else its catalogue id.
static func port_name(id: String) -> String:
	if _names.is_empty():
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(NAMES))
		for r: Dictionary in (data.get("names", []) if data is Dictionary else []):
			_names[str(r.get("id", ""))] = str(r.get("name", ""))
	if id == "Sol":
		return copy().words.sol
	if _names.has(id):
		return _names[id]
	return id.capitalize() if id == id.to_lower() and not id.is_empty() else id
