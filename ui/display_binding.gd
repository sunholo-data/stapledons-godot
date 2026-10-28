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
var record_context := false # sampler uses the producer view instead of the shared HUD view
var _last_view: Dictionary = {}


func bind(f: String, format: String) -> DisplayBinding:
	field = f
	fmt = format
	return self


func update_from(view: Dictionary) -> void:
	_record_fields(view, [field])
	_shown = format_field(view, field, fmt)
	text = _shown


## Freeze only the source fields this contract reads. Recording an entire world once
## per label would repeat the system catalogue dozens of times in every sample.
func _record_fields(view: Dictionary, fields: Array) -> void:
	if not record_context: return
	_last_view = {}
	for path: String in fields:
		var raw: Variant = GalaxyMap.field_value(view, path)
		if raw == null: continue # absent stays absent; replay must reject it
		var keys := path.split(".")
		var section := _last_view
		for i in keys.size() - 1:
			if not section.has(keys[i]): section[keys[i]] = {}
			section = section[keys[i]]
		section[keys[-1]] = raw.duplicate(true) if raw is Dictionary or raw is Array else raw


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
	# R2-INTERLUDE I3 (the crossing review): formatting only, every input a sim field.
	if format == "words": # a small count in words (CrewPage.words; D-21 crew text has no digits)
		return "-" if raw == null else CrewPage.words(int(raw))
	# R2-CREW-CONSOLE-V2 V3: the Crew console's formats (CrewConsoleModel.format): formatting only,
	# a sim field (or the client's sending/selector state) in words.
	if format.begins_with("crew_"):
		return CrewConsoleModel.format(format, raw)
	# R3-EARTH-LINK EL3: the comms station's formats (CommsPanel.format): calendar years, spans,
	# beam words and port names, formatting only.
	if format.begins_with("comms_"):
		return CommsPanel.format(format, raw)
	if format.begins_with("feed_"): # R3-EARTH-LINK EL3b: the feed's words for sim booleans and kinds
		return EarthFeed.format(format, raw)
	if format == "days": # a whole number of days, singular at one ("1 day", "70 days")
		return "-" if raw == null else ("%d day" if int(raw) == 1 else "%d days") % int(raw)
	if format == "days_into": # a moment's crew day in the crossing (0 is the day it began)
		if raw == null: return "-"
		return "The day the crossing began" if int(raw) == 0 else ("%d day into the crossing" if int(raw) == 1 else "%d days into the crossing") % int(raw)
	if format == "tier_line": # cruise.digest.time: the sim's tier line, its %s the sim's whole years
		if not raw is Dictionary: return "-"
		var line := str(raw.get("tier_line", ""))
		return line % int(raw.get("years_at_home", 0)) if line.contains("%s") else line
	if format == "speed_c": # journey.plan: "0.9999c" from the plan's exact 1 - beta, else six decimals
		if not raw is Dictionary: return "-"
		return CardInterlude.speed_text(float(raw.get("cruise_beta", 0.0)), float(raw.get("cruise_one_minus_beta", 1.0)))
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
