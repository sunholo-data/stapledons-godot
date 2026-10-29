class_name EarthStrip
extends Control
## R3-EARTH-LINK EL3b.5 (design r3/earth-link.md EL3b, "the exchange as light"): the comms station's
## spacetime strip. Time runs left to right, distance from home bottom to top: Earth's line along
## the bottom, the ship's line, each plan travelling home as light, Earth's reply travelling out to
## the port, and the wait at the port where the ship arrived before Earth's voice. A "now" line
## splits what has happened (solid) from what is still on its way (faint).
## Every endpoint is a sim field (earth.messages sent_t, from_ly, heard_t, reply_t, port_ly,
## arrive_t; clock.t, earth.light_age_years, earth.newest_light_t): Godot only places them. No
## numbers or sentences are drawn, only the word "Earth" on its line; it is a picture (standing order
## "Visual First, Words Last").

const SHOWN := 3 # the newest plans on the strip
const PAD := Vector2(14, 12)

## The strip's elements, rebuilt by refresh: [{kind, a: Vector2(t, ly), b: Vector2(t, ly)}], kind in
## ship, plan (light home), reply (Earth's beam out), wait (at the port, arrive_t to reply_t), light
## (Earth's newest light reaching the ship now).
var elements: Array = []
var now := Vector2.ZERO # (clock.t, earth.light_age_years): the ship now
var span := Rect2() # (t, ly) shown


func _init() -> void:
	name = "EarthStrip"
	custom_minimum_size = Vector2(0, 116)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


static func num(d: Dictionary, k: String) -> float:
	return float(d.get(k, 0.0)) if d.get(k) != null else 0.0


func refresh(view: Dictionary) -> void:
	var e: Variant = view.get("earth")
	var ms: Array = e.get("messages", []) if e is Dictionary and e.get("messages") is Array else []
	visible = not ms.is_empty() and GalaxyMap.field_value(view, "clock.t") != null
	elements = []
	if not visible:
		queue_redraw()
		return
	now = Vector2(float(GalaxyMap.field_value(view, "clock.t")), num(e, "light_age_years"))
	var shown := ms.slice(maxi(0, ms.size() - SHOWN))
	for i in shown.size():
		var m: Dictionary = shown[i]
		var sent := Vector2(num(m, "sent_t"), num(m, "from_ly"))
		var arrive := Vector2(num(m, "arrive_t"), num(m, "port_ly"))
		var heard := Vector2(num(m, "heard_t"), 0.0)
		var reply := Vector2(num(m, "reply_t"), num(m, "port_ly"))
		var next := i + 1 < shown.size()
		if not next and now.x > sent.x and now.x < arrive.x:
			# the leg in flight passes through the ship now (its distance from home need not move
			# straight: a leg can swing past home)
			elements.append({"kind": "ship", "a": sent, "b": now})
			elements.append({"kind": "ship", "a": now, "b": arrive})
		else:
			elements.append({"kind": "ship", "a": sent, "b": arrive})
		# at the port until the next plan leaves (the newest stays until now)
		var leaves: float = num(shown[i + 1], "sent_t") if next else now.x
		if leaves > arrive.x:
			elements.append({"kind": "ship", "a": arrive, "b": Vector2(leaves, arrive.y)})
		if heard.x > sent.x:
			elements.append({"kind": "plan", "a": sent, "b": heard})
		elements.append({"kind": "reply", "a": heard, "b": reply})
		# the wait at the port for Earth's voice, cut short if the ship left before it came
		var wait_end: float = minf(reply.x, num(shown[i + 1], "sent_t")) if next else reply.x
		if wait_end > arrive.x:
			elements.append({"kind": "wait", "a": arrive, "b": Vector2(wait_end, arrive.y)})
	elements.append({"kind": "light", "a": Vector2(num(e, "newest_light_t"), 0.0), "b": now})
	var lo := Vector2(now.x, 0.0)
	var hi := now
	for el: Dictionary in elements:
		for p: Vector2 in [el.a, el.b]:
			lo = Vector2(minf(lo.x, p.x), 0.0)
			hi = Vector2(maxf(hi.x, p.x), maxf(hi.y, p.y))
	span = Rect2(lo, Vector2(maxf(hi.x - lo.x, 1e-9), maxf(hi.y, 1e-9)))
	queue_redraw()


## A (t, ly) point on the strip, in pixels.
func at(p: Vector2) -> Vector2:
	var inner := size - PAD * 2.0
	return PAD + Vector2((p.x - span.position.x) / span.size.x * inner.x, (1.0 - p.y / span.size.y) * inner.y)


const COLORS := {"ship": StapledonTheme.TEAL_LIGHT, "plan": StapledonTheme.TEAL_LIGHT, "reply": StapledonTheme.OCHRE_LIGHT,
	"wait": StapledonTheme.OCHRE_LIGHT, "light": StapledonTheme.CREAM}
const WIDTHS := {"ship": 3.0, "plan": 1.5, "reply": 2.0, "wait": 7.0, "light": 1.0}


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(StapledonTheme.INK, 0.85))
	if elements.is_empty():
		return
	var earth_y := at(Vector2(span.position.x, 0.0)).y
	draw_line(Vector2(PAD.x, earth_y), Vector2(size.x - PAD.x, earth_y), StapledonTheme.OCHRE_LIGHT, 3.0, true)
	draw_circle(Vector2(PAD.x, earth_y), 5.0, StapledonTheme.OCHRE_LIGHT)
	var font := get_theme_default_font()
	draw_string(font, Vector2(PAD.x + 10.0, earth_y - 6.0), str(EarthFeed.copy().words.earth), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(StapledonTheme.OCHRE_LIGHT, 0.85))
	var nx := at(now).x
	for el: Dictionary in elements:
		var c: Color = COLORS[el.kind]
		var w: float = WIDTHS[el.kind]
		if el.kind == "wait": # a glowing band on the port's line, as bright to come as past
			draw_line(at(el.a), at(el.b), Color(c, 0.22), w * 2.2, true)
			draw_line(at(el.a), at(el.b), Color(c, 0.75), w * 0.5, true)
			continue
		_segment(at(el.a), at(el.b), nx, c, w, el.kind == "plan" or el.kind == "reply")
	draw_line(Vector2(nx, PAD.y * 0.5), Vector2(nx, size.y - PAD.y * 0.5), Color(StapledonTheme.CREAM, 0.35), 1.0)
	var ship := at(now)
	draw_circle(ship, 7.0, Color(StapledonTheme.TEAL_LIGHT, 0.3))
	draw_circle(ship, 4.0, StapledonTheme.TEAL_LIGHT)


## A segment, solid up to now and faint after it (still on its way); light dashes.
func _segment(a: Vector2, b: Vector2, nx: float, c: Color, w: float, dashed: bool) -> void:
	var cut := b
	if b.x > nx and a.x < nx:
		cut = a.lerp(b, (nx - a.x) / (b.x - a.x))
	var past_end := cut if b.x > nx else b
	if a.x < nx:
		if dashed:
			draw_dashed_line(a, past_end, c, w, 6.0, true, true)
		else:
			draw_line(a, past_end, c, w, true)
	if b.x > nx:
		var from := cut if a.x < nx else a
		draw_dashed_line(from, b, Color(c, c.a * 0.35), w, 3.0, true, true)
