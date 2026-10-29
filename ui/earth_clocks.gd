class_name EarthClocks
extends HBoxContainer
## R3-EARTH-LINK EL3b.3: the comms station's twin clocks. Each hand is one turn per day of its own
## clock, drawn straight from a sim field: the ship's from clock.tau, Earth's from
## earth.newest_light_t (Earth's time in the newest light). So Earth's hand turns D times as fast
## as the ship's with nothing computed from D: crawling flying away, whirling flying home (the
## band's whirl blurs it once it outruns the eye). The rate under it is a binding.

var ship_dial := Dial.new()
var earth_dial := Dial.new()
var rate := ComposedBinding.new()


func _init() -> void:
	name = "EarthClocks"
	add_theme_constant_override("separation", 14)
	alignment = BoxContainer.ALIGNMENT_CENTER
	var w: Dictionary = EarthFeed.copy().words
	for d: Array in [[ship_dial, str(w.ship), StapledonTheme.TEAL_LIGHT], [earth_dial, str(w.earth), StapledonTheme.OCHRE_LIGHT]]:
		var box := VBoxContainer.new()
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		var dial: Dial = d[0]
		dial.color = d[2]
		box.add_child(dial)
		var cap := Label.new()
		cap.text = d[1]
		cap.theme_type_variation = "HUDCaption"
		cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(cap)
		if dial == earth_dial:
			rate.theme_type_variation = "HUDCaption"
			rate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			box.add_child(rate)
		add_child(box)


func refresh(view: Dictionary) -> void:
	var e: Variant = view.get("earth")
	visible = e is Dictionary
	if not visible:
		return
	ship_dial.turns = float(GalaxyMap.field_value(view, "clock.tau")) if GalaxyMap.field_value(view, "clock.tau") != null else 0.0
	earth_dial.turns = float(e.get("newest_light_t", 0.0))
	earth_dial.whirl = EarthFeed.band_for(float(e.get("rate", 1.0))).get("whirl", false)
	rate.compose(["×", ["earth.rate", "sci"]])
	rate.update_from(view)
	ship_dial.queue_redraw()
	earth_dial.queue_redraw()


## One dial: a hand at the fraction of the current day of `turns` (years of its clock).
class Dial extends Control:
	var turns := 0.0
	var whirl := false
	var color := Color.WHITE

	func _init() -> void:
		custom_minimum_size = Vector2(96, 96)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.46
		draw_circle(c, r, StapledonTheme.INK)
		draw_arc(c, r, 0.0, TAU, 64, StapledonTheme.VIOLET, 2.0, true)
		for i in 12:
			var a := TAU * i / 12.0
			var d := Vector2(sin(a), -cos(a))
			draw_line(c + d * r * 0.84, c + d * r * 0.96, Color(StapledonTheme.CREAM, 0.5), 2.0 if i % 3 == 0 else 1.0)
		if whirl:
			draw_circle(c, r * 0.8, Color(color, 0.25))
		var day := fposmod(turns * 365.25, 1.0) # the hour of the clock's own day
		var h := Vector2(sin(TAU * day), -cos(TAU * day))
		draw_line(c, c + h * r * 0.78, color, 3.0, true)
		draw_circle(c, 3.5, color)
