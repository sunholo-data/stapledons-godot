class_name DisplayBinding
extends Label
## A HUD label whose text is one sim field, formatted and nothing more (M4 design: every
## displayed value goes through a binding; Godot formats and never computes). `field` is a dotted
## path into the view dictionary (the sim's world, plus the client's own "client.*" section).
## `fmt` is a GDScript format ("%.4f") or one of galaxy_map's "sci ..." formats, or "onoff".
## `audit()` is the positive-control check M4.5 runs: a numeric label that is not a binding, a
## binding with no field, or a binding whose text was set by hand, is a violation.

var field := ""
var fmt := "%s"
var _shown := "" # the text this binding last produced


func bind(f: String, format: String) -> DisplayBinding:
	field = f
	fmt = format
	return self


func update_from(view: Dictionary) -> void:
	_shown = format_field(view, field, fmt)
	text = _shown


static func format_field(view: Dictionary, f: String, format: String) -> String:
	var raw: Variant = GalaxyMap.field_value(view, f)
	if format == "ism_density":
		return "—" if raw == null else IsmHud.density_text(float(raw))
	if format == "ism_medium":
		return "—" if raw == null else IsmHud.medium_name(str(raw)).trim_prefix("the ")
	if format == "onoff":
		return "-" if raw == null else ("on" if raw > 0.0 else "off")
	if format == "dur_yr": # R1-SHIP-UI strip clocks: years as s, min, h, days or yr (ShipHud.duration_text)
		return "-" if raw == null else "+" + ShipHud.duration_text(float(raw))
	if format == "text": # a sim-derived line formatted upstream (the strip's distance, where and speed)
		return "" if raw == null else str(raw)
	return GalaxyMap.format_value(format, raw)


## Every Label under `root` that shows a number without being a clean binding.
static func audit(root: Node) -> Array:
	var bad: Array = []
	for n in root.find_children("*", "Label", true, false):
		if n is DisplayBinding:
			if n.field == "" or n.text != n._shown:
				bad.append(n)
		elif _has_digit(n.text):
			bad.append(n)
	return bad


static func _has_digit(s: String) -> bool:
	for c in s:
		if c >= "0" and c <= "9":
			return true
	return false
