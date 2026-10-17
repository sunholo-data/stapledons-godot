class_name CrewChip
extends PanelContainer
## R2-CREW-CONSOLE-V2 V2: a work-state chip: the state's colour token, its icon and its word
## (CrewPalette). The word is a display binding the caller makes (V7); the icon is drawn, so it
## reads at any scale and needs no glyph in the font. Edges: solid (filled, dark words), outline
## (hollow, words in the token's colour), dashed (sending: nothing has happened yet) and striped
## (held: auto-run is waiting).

var state := "free"
var token := "st-free"
var icon: ChipIcon
var word: Label


static func make(st: String, label: Label, font_px := 12) -> CrewChip:
	var c := CrewChip.new()
	c.state = st
	c.token = CrewPalette.token_of(st)
	c.name = "Chip"
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var edge := CrewPalette.edge_of(st)
	var col := CrewPalette.color_of(st)
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(int(font_px * 0.9))
	sb.content_margin_left = font_px * 0.5
	sb.content_margin_right = font_px * 0.7
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	if edge in ["solid", "striped"]:
		sb.bg_color = col
		c.clip_contents = edge == "striped"
	else:
		sb.bg_color = Color(col, 0.08)
		if edge == "outline":
			sb.set_border_width_all(2)
			sb.border_color = col
	c.add_theme_stylebox_override("panel", sb)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", int(font_px * 0.4))
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.add_child(row)
	c.icon = ChipIcon.new()
	c.icon.kind = CrewPalette.icon_of(st)
	c.icon.color = CrewPalette.ON_CHIP if edge in ["solid", "striped"] else col
	c.icon.custom_minimum_size = Vector2(font_px, font_px)
	c.icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(c.icon)
	c.word = label
	label.add_theme_font_size_override("font_size", font_px)
	label.add_theme_color_override("font_color", CrewPalette.ON_CHIP if edge in ["solid", "striped"] else col)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)
	return c


func _draw() -> void:
	var edge := CrewPalette.edge_of(state)
	var col := CrewPalette.color_of(state)
	var r := Rect2(Vector2.ZERO, size)
	if edge == "dashed":
		var dash := 5.0
		var gap := 3.0
		var w := 1.5
		for side in [[r.position, Vector2(r.end.x, r.position.y)], [Vector2(r.position.x, r.end.y), r.end]]:
			var x: float = side[0].x + 4.0
			while x < side[1].x - 4.0:
				draw_line(Vector2(x, side[0].y + w / 2.0 if side[0].y == 0.0 else side[0].y - w / 2.0), Vector2(minf(x + dash, side[1].x - 4.0), side[0].y + w / 2.0 if side[0].y == 0.0 else side[0].y - w / 2.0), col, w)
				x += dash + gap
		for xs in [r.position.x + w / 2.0, r.end.x - w / 2.0]:
			draw_line(Vector2(xs, 4.0), Vector2(xs, r.end.y - 4.0), col, w)
	elif edge == "striped":
		var dark := col.darkened(0.22)
		var x := 0.0
		while x < r.size.x + r.size.y:
			draw_line(Vector2(x, 0.0), Vector2(x - r.size.y, r.size.y), dark, 3.0)
			x += 9.0


class ChipIcon extends Control:
	## plus, arrow, clock, alert, check, play, moon, cross, double_check, pause
	var kind := "plus"
	var color := Color.WHITE

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var s := minf(size.x, size.y)
		var o := (size - Vector2(s, s)) / 2.0
		var w := maxf(1.5, s * 0.14)
		var p := func(x: float, y: float) -> Vector2: return o + Vector2(x * s, y * s)
		match kind:
			"plus":
				draw_line(p.call(0.5, 0.15), p.call(0.5, 0.85), color, w)
				draw_line(p.call(0.15, 0.5), p.call(0.85, 0.5), color, w)
			"arrow":
				draw_line(p.call(0.1, 0.5), p.call(0.8, 0.5), color, w)
				draw_colored_polygon(PackedVector2Array([p.call(0.95, 0.5), p.call(0.6, 0.22), p.call(0.6, 0.78)]), color)
			"clock":
				draw_arc(p.call(0.5, 0.5), s * 0.4, 0.0, TAU, 24, color, w * 0.8, true)
				draw_line(p.call(0.5, 0.5), p.call(0.5, 0.24), color, w * 0.8)
				draw_line(p.call(0.5, 0.5), p.call(0.7, 0.6), color, w * 0.8)
			"alert":
				draw_colored_polygon(PackedVector2Array([p.call(0.5, 0.05), p.call(0.97, 0.92), p.call(0.03, 0.92)]), color)
				var inner := CrewPalette.color_of("concern") if color == CrewPalette.ON_CHIP else CrewPalette.PANEL
				draw_line(p.call(0.5, 0.35), p.call(0.5, 0.62), inner, w * 0.9)
				draw_circle(p.call(0.5, 0.77), w * 0.55, inner)
			"check":
				draw_polyline(PackedVector2Array([p.call(0.12, 0.52), p.call(0.4, 0.8), p.call(0.9, 0.22)]), color, w, true)
			"double_check":
				draw_polyline(PackedVector2Array([p.call(0.02, 0.52), p.call(0.25, 0.78), p.call(0.62, 0.25)]), color, w * 0.85, true)
				draw_polyline(PackedVector2Array([p.call(0.36, 0.62), p.call(0.5, 0.78), p.call(0.98, 0.25)]), color, w * 0.85, true)
			"play":
				draw_colored_polygon(PackedVector2Array([p.call(0.22, 0.12), p.call(0.9, 0.5), p.call(0.22, 0.88)]), color)
			"moon":
				draw_circle(p.call(0.5, 0.5), s * 0.42, color)
				var bg := CrewPalette.color_of("resting") if color == CrewPalette.ON_CHIP else CrewPalette.PANEL
				draw_circle(p.call(0.68, 0.38), s * 0.36, bg)
			"cross":
				draw_line(p.call(0.18, 0.18), p.call(0.82, 0.82), color, w)
				draw_line(p.call(0.82, 0.18), p.call(0.18, 0.82), color, w)
			"pause":
				draw_rect(Rect2(p.call(0.2, 0.15), Vector2(s * 0.2, s * 0.7)), color)
				draw_rect(Rect2(p.call(0.6, 0.15), Vector2(s * 0.2, s * 0.7)), color)
			# R2-CREW-CONSOLE-V2 V7b: the work card's icon rows, the bars and the answers.
			"pip":
				draw_circle(p.call(0.5, 0.5), s * 0.32, color)
			"pip_empty":
				draw_arc(p.call(0.5, 0.5), s * 0.3, 0.0, TAU, 16, color, w * 0.7, true)
			"mass":
				draw_colored_polygon(PackedVector2Array([p.call(0.5, 0.08), p.call(0.92, 0.3), p.call(0.5, 0.52), p.call(0.08, 0.3)]), color)
				draw_colored_polygon(PackedVector2Array([p.call(0.08, 0.36), p.call(0.46, 0.57), p.call(0.46, 0.95), p.call(0.08, 0.74)]), color.darkened(0.25))
				draw_colored_polygon(PackedVector2Array([p.call(0.54, 0.57), p.call(0.92, 0.36), p.call(0.92, 0.74), p.call(0.54, 0.95)]), color.darkened(0.45))
			"stress":
				draw_polyline(PackedVector2Array([p.call(0.04, 0.6), p.call(0.22, 0.3), p.call(0.38, 0.72), p.call(0.56, 0.22), p.call(0.72, 0.7), p.call(0.96, 0.4)]), color, w * 0.8, true)
			"power":
				draw_colored_polygon(PackedVector2Array([p.call(0.6, 0.02), p.call(0.18, 0.56), p.call(0.47, 0.56), p.call(0.36, 0.98), p.call(0.84, 0.4), p.call(0.54, 0.4)]), color)
			"compute":
				draw_rect(Rect2(p.call(0.24, 0.24), Vector2(s * 0.52, s * 0.52)), color, false, w * 0.8)
				draw_rect(Rect2(p.call(0.38, 0.38), Vector2(s * 0.24, s * 0.24)), color)
				for t in [0.34, 0.5, 0.66]:
					draw_line(p.call(t, 0.06), p.call(t, 0.22), color, w * 0.6)
					draw_line(p.call(t, 0.78), p.call(t, 0.94), color, w * 0.6)
					draw_line(p.call(0.06, t), p.call(0.22, t), color, w * 0.6)
					draw_line(p.call(0.78, t), p.call(0.94, t), color, w * 0.6)
			"signal":
				draw_circle(p.call(0.22, 0.78), s * 0.1, color)
				for r in [0.32, 0.55, 0.78]:
					draw_arc(p.call(0.22, 0.78), s * r, -PI / 2.0 + 0.1, -0.1, 12, color, w * 0.7, true)
			"fatigue":
				draw_rect(Rect2(p.call(0.06, 0.28), Vector2(s * 0.78, s * 0.44)), color, false, w * 0.7)
				draw_rect(Rect2(p.call(0.86, 0.4), Vector2(s * 0.1, s * 0.2)), color)
				draw_rect(Rect2(p.call(0.14, 0.36), Vector2(s * 0.2, s * 0.28)), color)
			"trust":
				draw_circle(p.call(0.32, 0.36), s * 0.21, color)
				draw_circle(p.call(0.68, 0.36), s * 0.21, color)
				draw_colored_polygon(PackedVector2Array([p.call(0.13, 0.46), p.call(0.87, 0.46), p.call(0.5, 0.9)]), color)
			"morale":
				draw_circle(p.call(0.5, 0.5), s * 0.22, color)
				for k in 8:
					var a := k * TAU / 8.0
					draw_line(p.call(0.5 + 0.32 * cos(a), 0.5 + 0.32 * sin(a)), p.call(0.5 + 0.46 * cos(a), 0.5 + 0.46 * sin(a)), color, w * 0.6)
			"readiness":
				draw_arc(p.call(0.5, 0.5), s * 0.42, 0.0, TAU, 20, color, w * 0.6, true)
				draw_arc(p.call(0.5, 0.5), s * 0.24, 0.0, TAU, 16, color, w * 0.6, true)
				draw_circle(p.call(0.5, 0.5), s * 0.08, color)
			"observations":
				draw_arc(p.call(0.5, 0.8), s * 0.48, -PI + 0.5, -0.5, 16, color, w * 0.7, true)
				draw_arc(p.call(0.5, 0.2), s * 0.48, 0.5, PI - 0.5, 16, color, w * 0.7, true)
				draw_circle(p.call(0.5, 0.5), s * 0.14, color)
			"up":
				draw_colored_polygon(PackedVector2Array([p.call(0.5, 0.15), p.call(0.88, 0.75), p.call(0.12, 0.75)]), color)
			"down":
				draw_colored_polygon(PackedVector2Array([p.call(0.5, 0.85), p.call(0.88, 0.25), p.call(0.12, 0.25)]), color)
			"clear_scope":
				for y in [0.22, 0.5, 0.78]:
					draw_circle(p.call(0.14, y), s * 0.07, color)
					draw_line(p.call(0.3, y), p.call(0.9, y), color, w * 0.7)
			"ask_advice":
				draw_colored_polygon(PackedVector2Array([p.call(0.08, 0.12), p.call(0.92, 0.12), p.call(0.92, 0.66), p.call(0.42, 0.66), p.call(0.2, 0.9), p.call(0.24, 0.66), p.call(0.08, 0.66)]), color)
			"explain_priority":
				var pts := PackedVector2Array()
				for k in 10:
					var a := -PI / 2.0 + k * PI / 5.0
					var r := 0.46 if k % 2 == 0 else 0.2
					pts.append(p.call(0.5 + r * cos(a), 0.52 + r * sin(a)))
				draw_colored_polygon(pts, color)
			"stage_plan":
				draw_polyline(PackedVector2Array([p.call(0.06, 0.9), p.call(0.06, 0.68), p.call(0.36, 0.68), p.call(0.36, 0.44), p.call(0.64, 0.44), p.call(0.64, 0.2), p.call(0.94, 0.2)]), color, w * 0.8)
			"assert_authority":
				draw_line(p.call(0.2, 0.06), p.call(0.2, 0.96), color, w * 0.8)
				draw_colored_polygon(PackedVector2Array([p.call(0.24, 0.1), p.call(0.88, 0.28), p.call(0.24, 0.48)]), color)
			"help":
				draw_arc(p.call(0.5, 0.5), s * 0.44, 0.0, TAU, 20, color, w * 0.6, true)
				draw_arc(p.call(0.5, 0.38), s * 0.15, -PI, PI * 0.35, 10, color, w * 0.7, true)
				draw_line(p.call(0.56, 0.5), p.call(0.5, 0.6), color, w * 0.7)
				draw_circle(p.call(0.5, 0.76), w * 0.45, color)
			"rest":
				draw_circle(p.call(0.5, 0.5), s * 0.42, color)
				draw_circle(p.call(0.68, 0.38), s * 0.36, CrewPalette.ROW)
