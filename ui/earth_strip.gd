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
## R3-COMMS-V2 CV2 (design r3/comms-station-v2.md §D1.4, §D1.6): with the 2.17 log, each beamed record is
## also a ray of Earth's light, from Earth's line at sent.t to the ship at (arrived.t, arrived.ly): lone
## rays outbound, a faint fan homeward. Frame mode (set_frame(i), the history wall's selection) turns
## the strip into that week's light-cone diagram on equal axes (one year = one light-year, so light runs
## at 45 degrees): Earth's line, the ship's track (the log's arrival points), the send event, the light,
## the arrival, the ship when Earth sent it (ship_at_sent) and x D. Its numbers are ComposedBindings on
## the record's fields; its words are labels. The galaxy map's beams show Earth's aim now; this shows a
## week of light that actually arrived, so the two never draw the same thing.

const SHOWN := 3 # the newest plans on the strip
const PAD := Vector2(14, 12)

## The strip's elements, rebuilt by refresh: [{kind, a: Vector2(t, ly), b: Vector2(t, ly)}], kind in
## ship, plan (light home), reply (Earth's beam out), wait (at the port, arrive_t to reply_t), light
## (Earth's newest light reaching the ship now).
var elements: Array = []
var now := Vector2.ZERO # (clock.t, earth.light_age_years): the ship now
var span := Rect2() # (t, ly) shown
var recs: Array = [] # earth_log.records (2.17), oldest first
var frame := -1 # the selected record (frame mode), -1 for the strip
var view: Dictionary = {}
var tags: Array[ComposedBinding] = [] # frame mode: Earth date sent, ship date arrived, x D
var inset := FrameInset.new()


func _init() -> void:
	name = "EarthStrip"
	custom_minimum_size = Vector2(0, 116)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	inset.visible = false
	add_child(inset)


static func num(d: Dictionary, k: String) -> float:
	return float(d.get(k, 0.0)) if d.get(k) != null else 0.0


func refresh(v: Dictionary) -> void:
	view = v
	var lg: Variant = v.get("earth_log")
	recs = lg.get("records", []) if lg is Dictionary and lg.get("records") is Array else []
	if frame >= recs.size():
		frame = -1
	_refresh_strip(v)
	_place_tags()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_place_tags()


## Frame mode on the record i of earth_log.records (-1 returns the strip). The diagram takes more height
## than the strip (light at 45 degrees needs room for the distance axis).
const FRAME_HEIGHT := 132.0
var strip_height := -1.0
func set_frame(i: int) -> void:
	frame = i if i >= 0 and i < recs.size() else -1
	if strip_height < 0.0:
		strip_height = custom_minimum_size.y
	custom_minimum_size.y = FRAME_HEIGHT if frame >= 0 else strip_height
	_place_tags()
	queue_redraw()


func _refresh_strip(view: Dictionary) -> void:
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
	if frame >= 0:
		_draw_frame()
		return
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
	_draw_rays()


## Each beamed record as a ray of Earth's light (sent.t on Earth's line to the arrival): bright where
## the rays stand apart, faint where they crowd into a fan.
func _draw_rays() -> void:
	var prev := -1e9
	for r: Dictionary in recs:
		if r.get("beamed") != true:
			continue
		var arr: Dictionary = r.get("arrived", {})
		if float(arr.get("t", 0.0)) < span.position.x:
			continue
		var a := at(Vector2(maxf(float(r.get("sent", {}).get("t", 0.0)), span.position.x), 0.0))
		var b := at(Vector2(float(arr.get("t", 0.0)), float(arr.get("ly", 0.0))))
		draw_line(a, b, Color(StapledonTheme.CREAM, 0.45 if absf(b.x - prev) > 4.0 else 0.06), 1.0, true)
		prev = b.x


## Frame mode's window and its equal-axes map (one year = one light-year).
func _frame_box() -> Dictionary:
	var r: Dictionary = recs[frame]
	var arr: Dictionary = r.get("arrived", {})
	var sent := float(r.get("sent", {}).get("t", 0.0))
	var then: Variant = r.get("ship_at_sent")
	var t0 := minf(sent, float(then.get("t", sent)) if then is Dictionary else sent)
	var t1 := float(arr.get("t", 0.0))
	var pad := maxf((t1 - t0) * 0.12, 0.05)
	t0 -= pad
	t1 += pad
	var top := maxf(float(arr.get("ly", 0.0)), float(then.get("ly", 0.0)) if then is Dictionary else 0.0)
	for q: Dictionary in recs:
		var qa: Dictionary = q.get("arrived", {})
		if float(qa.get("t", 0.0)) >= t0 and float(qa.get("t", 0.0)) <= float(arr.get("t", 0.0)):
			top = maxf(top, float(qa.get("ly", 0.0)))
	top = maxf(top * 1.15, 0.05)
	var plot := Rect2(PAD, Vector2(size.x * 0.66, size.y - PAD.y * 2.0))
	var k := minf(plot.size.x / (t1 - t0), plot.size.y / top)
	return {"t0": t0, "k": k, "plot": plot}


func eq(box: Dictionary, p: Vector2) -> Vector2:
	var plot: Rect2 = box.plot
	return Vector2(plot.position.x + (p.x - float(box.t0)) * float(box.k), plot.end.y - p.y * float(box.k))


func _draw_frame() -> void:
	var r: Dictionary = recs[frame]
	var arr: Dictionary = r.get("arrived", {})
	var box := _frame_box()
	var plot: Rect2 = box.plot
	var font := get_theme_default_font()
	var w: Dictionary = EarthFeed.copy().words
	draw_line(Vector2(plot.position.x, plot.end.y), Vector2(plot.end.x, plot.end.y), StapledonTheme.OCHRE_LIGHT, 3.0, true)
	draw_string(font, Vector2(plot.end.x - 44.0, plot.end.y - 6.0), str(w.earth), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, StapledonTheme.OCHRE_LIGHT)
	var pts := PackedVector2Array()
	for q: Dictionary in recs:
		var qa: Dictionary = q.get("arrived", {})
		var p := eq(box, Vector2(float(qa.get("t", 0.0)), float(qa.get("ly", 0.0))))
		if float(qa.get("t", 0.0)) <= float(arr.get("t", 0.0)) and float(qa.get("t", 0.0)) >= float(box.t0):
			pts.append(p)
	if pts.size() > 1:
		draw_polyline(pts, StapledonTheme.TEAL_LIGHT, 5.0, true)
	var sent := eq(box, Vector2(float(r.get("sent", {}).get("t", 0.0)), 0.0))
	var hit := eq(box, Vector2(float(arr.get("t", 0.0)), float(arr.get("ly", 0.0))))
	draw_line(sent, hit, StapledonTheme.CREAM, 2.0, true)
	draw_string(font, (sent + hit) * 0.5 + Vector2(8, 4), str(w.get("light", "light")), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, StapledonTheme.CREAM)
	var then: Variant = r.get("ship_at_sent")
	if then is Dictionary:
		var tp := eq(box, Vector2(float(then.get("t", 0.0)), float(then.get("ly", 0.0))))
		draw_dashed_line(sent, tp, Color(StapledonTheme.CREAM, 0.35), 1.0, 4.0)
		draw_arc(tp, 6.0, 0.0, TAU, 24, StapledonTheme.TEAL_LIGHT, 2.0, true)
		draw_string(font, tp + Vector2(10, 4), str(w.get("ship_then", "ship then")), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(StapledonTheme.TEAL_LIGHT, 0.85))
	draw_circle(sent, 6.0, StapledonTheme.OCHRE_LIGHT)
	draw_circle(hit, 7.0, StapledonTheme.TEAL_LIGHT)


## Frame mode's numbers, each a binding on the record's fields, beside its event.
func _place_tags() -> void:
	inset.visible = frame >= 0
	for t in tags:
		t.visible = frame >= 0
	if frame < 0 or size.x <= 0.0:
		return
	if tags.is_empty(): # made on first use, so no binding is ever without a field (the display audit)
		for v: String in ["HUDCaption", "HUDAccent", "HUDWarn"]: # sent (ochre), arrived (teal), x D (coral)
			var b := ComposedBinding.new()
			b.theme = StapledonTheme.theme()
			b.theme_type_variation = v
			b.add_theme_font_size_override("font_size", 16 if v == "HUDWarn" else 12)
			b.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(b)
			tags.append(b)
	var r: Dictionary = recs[frame]
	var arr: Dictionary = r.get("arrived", {})
	var box := _frame_box()
	var w: Dictionary = EarthFeed.copy().words
	var base := "earth_log.records.%d." % frame
	tags[0].compose([str(w.get("sent", "sent")) + " ", [base + "earth_from_year", "comms_clock"]])
	tags[1].compose([str(w.get("arrived", "arrived")) + " ", [base + "arrived.tau", "comms_clock"]])
	tags[2].compose(["×", [base + "arrived.rate", "sci"]])
	for t in tags:
		t.update_from(view)
		t.size = t.get_minimum_size()
	var sent := eq(box, Vector2(float(r.get("sent", {}).get("t", 0.0)), 0.0))
	var hit := eq(box, Vector2(float(arr.get("t", 0.0)), float(arr.get("ly", 0.0))))
	tags[0].position = sent + Vector2(-tags[0].size.x * 0.5, -tags[0].size.y - 10.0) # above the send event
	tags[1].position = hit + Vector2(12, -tags[1].size.y - 4.0) # beside the arrival
	tags[2].position = hit + Vector2(12, 4) # x D under it
	for t in tags: # inside the strip
		t.position = t.position.clamp(Vector2(4, 2), size - t.size - Vector2(inset.size.x + PAD.x * 2.0, 2))
	inset.size = Vector2(size.y - PAD.y * 2.0, size.y - PAD.y * 2.0)
	inset.position = Vector2(size.x - inset.size.x - PAD.x, PAD.y)
	inset.setup(recs, frame)


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



## Frame mode's plan inset, from above: Sol, the ship's track (the log's arrival positions), the ship
## at arrival and when Earth sent the light, and the light's straight path from Sol. The galaxy map's
## glyphs (Sol ochre, the ship teal); never Earth's current aim.
class FrameInset extends Control:
	var recs: Array = []
	var frame := -1

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func setup(r: Array, i: int) -> void:
		recs = r
		frame = i
		queue_redraw()

	static func xy(d: Variant) -> Vector2:
		return Vector2(float(d.get("x", 0.0)), float(d.get("y", 0.0))) if d is Dictionary else Vector2.ZERO

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(StapledonTheme.INK, 0.95))
		draw_rect(Rect2(Vector2.ZERO, size), Color(StapledonTheme.VIOLET, 0.9), false, 1.0)
		if frame < 0 or frame >= recs.size():
			return
		var r: Dictionary = recs[frame]
		var arr_t := float(r.get("arrived", {}).get("t", 0.0))
		var track: Array = []
		for q: Dictionary in recs:
			if float(q.get("arrived", {}).get("t", 0.0)) <= arr_t:
				track.append(xy(q.get("arrived", {}).get("p")))
		var then: Variant = r.get("ship_at_sent")
		var pts: Array = track + [Vector2.ZERO] + ([xy(then.get("p"))] if then is Dictionary else [])
		var lo := Vector2.ZERO
		var hi := Vector2.ZERO
		for q: Vector2 in pts:
			lo = lo.min(q)
			hi = hi.max(q)
		var span := maxf(hi.x - lo.x, hi.y - lo.y) * 1.3 + 0.1
		var c := (lo + hi) * 0.5
		var k := size.x / span
		var pa := func(q: Vector2) -> Vector2: return size * 0.5 + Vector2(q.x - c.x, -(q.y - c.y)) * k
		var tp := PackedVector2Array()
		for q: Vector2 in track:
			tp.append(pa.call(q))
		if tp.size() > 1:
			draw_polyline(tp, Color(StapledonTheme.TEAL_LIGHT, 0.8), 2.0, true)
		var hit: Vector2 = pa.call(xy(r.get("arrived", {}).get("p")))
		var sol: Vector2 = pa.call(Vector2.ZERO)
		draw_line(sol, hit, StapledonTheme.CREAM, 1.5, true)
		draw_circle(sol, 5.0, StapledonTheme.OCHRE_LIGHT)
		if then is Dictionary:
			draw_arc(pa.call(xy(then.get("p"))), 4.0, 0.0, TAU, 20, StapledonTheme.TEAL_LIGHT, 1.5, true)
		draw_circle(hit, 5.0, StapledonTheme.TEAL_LIGHT)
