class_name BridgeScreens
extends RefCounted
## R3-COMMS-V2 CV6 (design r3/comms-station-v2.md §D3, §D4): the faces of the bridge's ambient
## monitors, each a Control drawn at 960 x 540 into its monitor's SubViewport and read from 10-20 m
## away through the Bow view. Bold, one idea per face, labels only; every number a ComposedBinding on
## a sim field (D-21), audited like the consoles.
##   signal   the signal from home: the waterfall (CommsWaterfall, bold; True with the Receiver's line
##            and x D), "Earth" or "no signal", the light's age, the link bar (teal in beam)
##   clocks   Earth's clock against the ship's (EarthClocks), the Earth year in the newest light and the
##            ship's clock
##   course   the leg on a chart (Sol, departure, target, the ship, Earth's beam ray), the phase, the
##            target, the Earth year at arrival and gamma
##   crew     the crew's faces at their home feeling (CommsStation.CrewFaces)

const FACES := ["signal", "clocks", "course", "crew"]
const SIZE := Vector2i(960, 540)


static func make(kind: String) -> Control:
	match kind:
		"signal": return SignalFace.new()
		"clocks": return ClocksFace.new()
		"course": return CourseFace.new()
		"crew": return CrewFace.new()
	return null


## A face's label in a theme colour: its type variation (HUDCaption ochre, HUDAccent teal, HUDWarn coral,
## HUDLabel cream), so every colour stays the theme's (ui-theme-check).
static func label(size: int, variation: String) -> ComposedBinding:
	var b := ComposedBinding.new()
	b.theme = StapledonTheme.theme()
	b.theme_type_variation = variation
	b.add_theme_font_size_override("font_size", size)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return b


class Face extends Control:
	func _init() -> void:
		size = Vector2(SIZE)
		theme = StapledonTheme.theme()
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.03, 0.025, 0.06))

	func refresh(_view: Dictionary, _receiver: bool, _bed: String) -> void:
		pass


class SignalFace extends Face:
	var wf := CommsWaterfall.new()
	var tag := BridgeScreens.label(34, "HUDCaption")
	var age := BridgeScreens.label(30, "HUDLabel")
	var beam := false

	func _init() -> void:
		super._init()
		wf.bold = true
		wf.position = Vector2(20, 70)
		wf.size = Vector2(920, 400)
		add_child(wf)
		tag.position = Vector2(28, 14)
		add_child(tag)
		age.position = Vector2(620, 18)
		add_child(age)

	func refresh(view: Dictionary, receiver: bool, bed: String) -> void:
		var e: Variant = view.get("earth")
		beam = e is Dictionary and e.get("in_beam") == true
		tag.compose([["earth.in_beam", "feed_signal"]])
		tag.update_from(view)
		tag.theme_type_variation = "HUDCaption" if beam else "HUDWarn"
		age.compose([["earth.light_age_years", "comms_years"], " old"])
		age.update_from(view)
		age.visible = e is Dictionary
		wf.refresh(view, receiver, bed)
		queue_redraw()

	func _draw() -> void:
		super._draw()
		draw_rect(Rect2(20, 486, 920, 30), Color(StapledonTheme.TEAL_LIGHT, 0.75) if beam else Color(0.4, 0.4, 0.45, 0.6))


class ClocksFace extends Face:
	var clocks := EarthClocks.new()
	var earth := BridgeScreens.label(34, "HUDCaption")
	var ship := BridgeScreens.label(34, "HUDAccent")

	func _init() -> void:
		super._init()
		clocks.ship_dial.custom_minimum_size = Vector2(330, 330)
		clocks.earth_dial.custom_minimum_size = Vector2(330, 330)
		clocks.add_theme_constant_override("separation", 80)
		clocks.position = Vector2(60, 10)
		clocks.size = Vector2(840, 450)
		add_child(clocks)
		ship.position = Vector2(170, 470)
		earth.position = Vector2(580, 470)
		add_child(ship)
		add_child(earth)

	func refresh(view: Dictionary, _receiver: bool, _bed: String) -> void:
		clocks.refresh(view)
		for box in clocks.get_children():
			for l in box.get_children():
				if l is Label:
					l.add_theme_font_size_override("font_size", 40)
		earth.compose([["earth.newest_light_year", "comms_clock"]])
		earth.update_from(view)
		ship.compose([["clock.tau", "comms_clock"]])
		ship.update_from(view)


class CourseFace extends Face:
	var target := BridgeScreens.label(40, "HUDLabel")
	var arrive := BridgeScreens.label(32, "HUDCaption")
	var gamma := BridgeScreens.label(32, "HUDLabel")
	var left := BridgeScreens.label(32, "HUDAccent") ## CV5 (OQ12): the ship time left on the leg (course.ship_years_left)
	var view: Dictionary = {}

	func _init() -> void:
		super._init()
		target.position = Vector2(650, 140)
		arrive.position = Vector2(650, 210)
		gamma.position = Vector2(650, 330)
		left.position = Vector2(650, 270)
		for b in [target, arrive, gamma, left]:
			add_child(b)

	func refresh(v: Dictionary, _receiver: bool, _bed: String) -> void:
		view = v
		var plan: Variant = GalaxyMap.field_value(v, "journey.plan")
		target.compose([["journey.plan.target.id", "text"]])
		arrive.compose([str(EarthFeed.copy().words.earth) + " ", ["journey.plan.arrive_year", "comms_clock"]])
		gamma.compose(["γ ", ["ship.gamma", "%.2f"]])
		left.compose([str(EarthFeed.copy().words.ship) + " ", ["course.ship_years_left", "comms_years"], " " + str(EarthFeed.copy().words.get("to_go", "to go"))])
		for b in [target, arrive, gamma, left]:
			b.update_from(v)
			b.visible = plan is Dictionary
		left.visible = left.visible and str(GalaxyMap.field_value(v, "journey.state")) == "committed"
		queue_redraw()

	func _draw() -> void:
		super._draw()
		var f := get_theme_default_font()
		var ph := str(GalaxyMap.field_value(view, "ship.phase"))
		var i := 0
		for p: Array in [["boost", "▲"], ["cruising", "▶"], ["braking", "▼"]]:
			draw_string(f, Vector2(650 + 90 * i, 90), p[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 48, StapledonTheme.TEAL_LIGHT if ph == p[0] else Color(StapledonTheme.CREAM, 0.25))
			i += 1
		var plan: Variant = GalaxyMap.field_value(view, "journey.plan")
		var pos: Variant = GalaxyMap.field_value(view, "ship.pos")
		var chart := Rect2(10, 10, 600, 520)
		draw_rect(chart, Color(StapledonTheme.VIOLET, 0.25))
		if not plan is Dictionary or not pos is Dictionary:
			return
		var pts := [Vector2.ZERO, _v(plan.get("departure")), _v(plan.get("target", {}).get("pos")), _v(pos)]
		var beam: Variant = GalaxyMap.field_value(view, "earth.beam")
		if beam is Dictionary:
			pts.append(_v(beam.get("port")))
		var lo := Vector2(INF, INF)
		var hi := -lo
		for q: Vector2 in pts:
			lo = lo.min(q)
			hi = hi.max(q)
		var span := maxf(hi.x - lo.x, hi.y - lo.y) * 1.25 + 0.5
		var c := (lo + hi) * 0.5
		var k := minf(chart.size.x, chart.size.y) / span
		var at := func(q: Vector2) -> Vector2: return chart.get_center() + Vector2(q.x - c.x, -(q.y - c.y)) * k
		if beam is Dictionary: # Earth's aim now: the ray from Sol through the port it heard
			draw_dashed_line(at.call(Vector2.ZERO), at.call(_v(beam.get("port")) * 1.6), Color(StapledonTheme.OCHRE_LIGHT, 0.6), 3.0, 14.0)
		var dep: Vector2 = at.call(_v(plan.get("departure")))
		var tgt: Vector2 = at.call(_v(plan.get("target", {}).get("pos")))
		var shp: Vector2 = at.call(_v(pos))
		draw_line(dep, shp, StapledonTheme.TEAL_LIGHT, 5.0, true)
		draw_dashed_line(shp, tgt, Color(StapledonTheme.TEAL_LIGHT, 0.45), 4.0, 12.0)
		draw_circle(at.call(Vector2.ZERO), 12.0, StapledonTheme.OCHRE_LIGHT)
		draw_circle(dep, 8.0, Color(StapledonTheme.CREAM, 0.6))
		draw_arc(tgt, 18.0, 0.0, TAU, 48, StapledonTheme.CREAM, 3.0, true)
		var hd := (tgt - dep).normalized()
		var n := Vector2(-hd.y, hd.x)
		draw_colored_polygon(PackedVector2Array([shp + hd * 22.0, shp - hd * 12.0 + n * 12.0, shp - hd * 12.0 - n * 12.0]), StapledonTheme.TEAL_LIGHT)
		draw_string(f, at.call(Vector2.ZERO) + Vector2(16, 30), "Sol", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, StapledonTheme.OCHRE_LIGHT)

	static func _v(d: Variant) -> Vector2:
		return Vector2(float(d.get("x", 0.0)), float(d.get("y", 0.0))) if d is Dictionary else Vector2.ZERO


class CrewFace extends Face:
	var faces := CommsStation.CrewFaces.new()

	func _init() -> void:
		super._init()
		faces.columns = 5
		faces.face_px = 160.0
		faces.add_theme_constant_override("h_separation", 26)
		faces.position = Vector2(26, 120)
		add_child(faces)

	func refresh(view: Dictionary, _receiver: bool, _bed: String) -> void:
		faces.refresh(view)
		for box in faces.get_children():
			(box.get_node("Feeling") as Control).add_theme_font_size_override("font_size", 30)
			(box.get_node("Who") as Control).add_theme_font_size_override("font_size", 18)
