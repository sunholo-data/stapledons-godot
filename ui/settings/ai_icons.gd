class_name AiIcons
extends RefCounted
## R3-AI-PANEL-V2 P3: the Live AI panel's icons, drawn as strokes in theme
## colours (standing order "visual UI, not text"). No image assets: each icon
## is a few lines in a 24-unit box, scaled to the control.
##   text      a speech bubble (crew and Archive lines)
##   voice     sound bars
##   portrait  a head and shoulders
##   feed      a framed picture (pictures from home)
##   lock      a padlock (keys stay on this computer)
##   ok / fail a check mark / an exclamation mark (reply dots)

const NAMES := ["text", "voice", "portrait", "feed", "lock", "ok", "fail"]


static func draw(ci: CanvasItem, name: String, rect: Rect2, color: Color, width: float = 2.0) -> void:
	var s := minf(rect.size.x, rect.size.y) / 24.0
	var o := rect.position + (rect.size - Vector2(24, 24) * s) / 2.0
	var pt := func(x: float, y: float) -> Vector2: return o + Vector2(x, y) * s
	var line := func(pts: Array) -> void:
		var pv := PackedVector2Array()
		for p in pts:
			pv.append(pt.call(p[0], p[1]))
		ci.draw_polyline(pv, color, width, true)
	match name:
		"text":
			line.call([[4, 5], [20, 5], [20, 16], [9, 16], [4, 20], [4, 5]])
			line.call([[8, 9], [16, 9]])
			line.call([[8, 12], [13, 12]])
		"voice":
			for b in [[4, 10, 14], [8, 7, 17], [12, 4, 20], [16, 8, 16], [20, 11, 13]]:
				line.call([[b[0], b[1]], [b[0], b[2]]])
		"portrait":
			ci.draw_arc(pt.call(12, 9), 4.0 * s, 0.0, TAU, 24, color, width, true)
			ci.draw_arc(pt.call(12, 22), 8.0 * s, PI * 1.08, PI * 1.92, 16, color, width, true)
		"feed":
			line.call([[3, 5], [21, 5], [21, 19], [3, 19], [3, 5]])
			line.call([[3, 16], [8, 11], [12, 15], [15, 12], [21, 18]])
			ci.draw_circle(pt.call(16, 9), 1.5 * s, color)
		"lock":
			line.call([[5, 11], [19, 11], [19, 20], [5, 20], [5, 11]])
			ci.draw_arc(pt.call(12, 8), 4.0 * s, PI, TAU, 12, color, width, true)
			line.call([[8, 8], [8, 11]])
			line.call([[16, 8], [16, 11]])
		"ok":
			line.call([[6, 12], [10, 16], [18, 8]])
		"fail":
			line.call([[12, 6], [12, 13]])
			ci.draw_circle(pt.call(12, 17.5), 1.4 * s, color)


## A drawn icon, optionally on a tile (filled or hollow round rect) or a disc.
class Glyph extends Control:
	var icon := "text"
	var color := StapledonTheme.CREAM
	## "": the icon alone; "tile": a capability tile; "disc": a reply dot.
	var frame := ""
	var frame_color := StapledonTheme.DIM
	var filled := false
	var line_width := 2.0

	func _init(name := "text", min_size := Vector2(24, 24)) -> void:
		icon = name
		custom_minimum_size = min_size
		mouse_filter = Control.MOUSE_FILTER_PASS

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		match frame:
			"tile":
				var pts := _round_rect(r.grow(-1.5), 8.0)
				if filled:
					draw_colored_polygon(pts, Color(frame_color, 0.22))
				pts.append(pts[0])
				draw_polyline(pts, frame_color, 1.5, true)
				r = r.grow(-size.x * 0.22)
			"disc":
				var c := size / 2.0
				var rad := minf(size.x, size.y) / 2.0 - 1.5
				if filled:
					draw_circle(c, rad, Color(frame_color, 0.22))
				draw_arc(c, rad, 0.0, TAU, 32, frame_color, 1.5, true)
				r = r.grow(-size.x * 0.2)
		AiIcons.draw(self, icon, r, color, line_width)

	static func _round_rect(r: Rect2, rad: float) -> PackedVector2Array:
		var pts := PackedVector2Array()
		var corners := [[r.end.x - rad, r.position.y + rad, -PI / 2.0], [r.end.x - rad, r.end.y - rad, 0.0],
			[r.position.x + rad, r.end.y - rad, PI / 2.0], [r.position.x + rad, r.position.y + rad, PI]]
		for c in corners:
			for i in 7:
				var a: float = c[2] + PI / 2.0 * i / 6.0
				pts.append(Vector2(c[0], c[1]) + Vector2(cos(a), sin(a)) * rad)
		return pts
