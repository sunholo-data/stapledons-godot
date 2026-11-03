class_name EarthHistory
extends Control
## R3-COMMS-V2 CV2 (design r3/comms-station-v2.md §D1.4): the history wall, every Earth week the ship
## has received this voyage, on a film along ship time. Visual first: the gaps are the Earth-rate
## history (weeks ~99 ship days apart flying out at 0.99c, a flood flying home), static where the light
## came without Earth's beam, and the only words are two stamps per picture.
##   x            a record's arrived.tau (the ship's clock when its weeks arrived); now at the right
##   pictures     a beamed record shows its newest week's picture (EarthFeed.picked_source: the library,
##                painted frames already in the AI cache, the sky); in full where there is room, a slit
##                where records crowd, with offset frames behind it when it holds several weeks
##   static       the ship-time span of unbeamed records
##   stamps       ComposedBindings: earth_log.records.<i>.earth_from_year (ochre) and .arrived.tau
##                (teal), both comms_clock; no counts, no totals
##   line         the Earth time received (earth_to_year) against ship time: its slope is the rate
## Selecting a picture emits week_selected(i) (the console's frame diagram); selecting it again, or
## Escape, deselects (-1). The wheel zooms the ship-time axis about the pointer. Every value is a sim
## field of the 2.17 log (earth_log); the wall places and never computes. It opens no AI request.

signal week_selected(index: int)

const THUMB := Vector2(62, 35)
const BAND_Y := 14.0
const STAMP_POOL := 40

var records: Array = []
var view: Dictionary = {}
var feed: EarthFeed = null ## the station's feed: its picked_source and texture cache
var tau_from := 0.0
var tau_to := 1.0
var zoomed := false
var selected := -1
var _noise: Texture2D = null
var _stamps: Array[ComposedBinding] = []
var _full: Array = [] # [index, centre x] of the records drawn in full this frame


func _init() -> void:
	name = "EarthHistory"
	clip_contents = true
	custom_minimum_size = Vector2(0, 88)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var img := Image.create(240, 40, false, Image.FORMAT_L8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for y in 40:
		for x in 240:
			img.set_pixel(x, y, Color.from_hsv(0, 0, rng.randf()))
	_noise = ImageTexture.create_from_image(img)


## The k-th stamp label, made on first use (a binding is never left without a field: the display audit).
func _stamp(k: int) -> ComposedBinding:
	while _stamps.size() <= k:
		var b := ComposedBinding.new()
		b.theme = StapledonTheme.theme()
		b.theme_type_variation = "HUDCaption"
		b.add_theme_font_size_override("font_size", 10)
		b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(b)
		_stamps.append(b)
	return _stamps[k]


## The frame's world (2.17): the log's records and the ship's clock now. Nothing from the future can
## be here: the sim logs only light that has arrived (D-68).
func refresh(v: Dictionary) -> void:
	view = v
	var lg: Variant = v.get("earth_log")
	records = lg.get("records", []) if lg is Dictionary and lg.get("records") is Array else []
	visible = not records.is_empty()
	if not zoomed:
		tau_from = 0.0
		tau_to = maxf(_tau_now(), 1e-9)
	if selected >= records.size():
		selected = -1
	queue_redraw()


func _tau_now() -> float:
	var t: Variant = GalaxyMap.field_value(view, "clock.tau")
	return float(t) if t != null else 0.0


func tx(tau: float) -> float:
	return 10.0 + (tau - tau_from) / maxf(tau_to - tau_from, 1e-12) * (size.x - 22.0)


func _texture(rec: Dictionary) -> Texture2D:
	var fd: Dictionary = rec.get("feed", {})
	if feed == null:
		return EarthFeed.sky_texture(int(fd.get("frame", 0)))
	return feed.texture_of(feed.picked_source(fd))


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.035, 0.03, 0.06))
	var x := 4.0
	while x < size.x:
		draw_rect(Rect2(x, 3, 6, 4), Color(StapledonTheme.CREAM, 0.10))
		draw_rect(Rect2(x, size.y - 7, 6, 4), Color(StapledonTheme.CREAM, 0.10))
		x += 14.0
	for s in _stamps:
		s.visible = false
	_full = []
	if records.is_empty():
		return
	var band := Rect2(0, BAND_Y, size.x, THUMB.y)
	# static where light came without Earth's beam: from the previous record's arrival to this run's last
	var i := 0
	while i < records.size():
		if records[i].get("beamed") == true:
			i += 1
			continue
		var j := i
		while j + 1 < records.size() and records[j + 1].get("beamed") != true:
			j += 1
		var a := tx(_tau(i - 1 if i > 0 else i))
		var b := tx(_tau(j))
		draw_texture_rect(_noise, Rect2(a, band.position.y, maxf(b - a, 2.0), band.size.y), true, Color(0.75, 0.75, 0.8, 0.55))
		i = j + 1
	# the beamed weeks: in full where there is room, a slit where they crowd
	var last_full := -1e9
	var prev_x := -1e9
	var stamp := 0
	for k in records.size():
		var r: Dictionary = records[k]
		if r.get("beamed") != true:
			prev_x = -1e9
			continue
		var cx := tx(_tau(k))
		if cx < -THUMB.x or cx > size.x + THUMB.x:
			prev_x = cx
			continue
		var t := _texture(r)
		if cx - last_full >= THUMB.x + 4.0:
			var rect := Rect2(cx - THUMB.x * 0.5, band.position.y, THUMB.x, THUMB.y)
			var weeks := int(r.get("to_frame", 0)) - int(r.get("from_frame", 0)) + 1
			for depth in range(mini(weeks - 1, 3), 0, -1): # a stack: several weeks arrived together
				draw_rect(Rect2(rect.position + Vector2(2.5 * depth, -2.0 * depth), rect.size), Color(StapledonTheme.CREAM, 0.12 + 0.05 * depth), false, 1.0)
			draw_texture_rect(t, rect, false)
			draw_rect(rect, StapledonTheme.CORAL if k == selected else Color(StapledonTheme.CREAM, 0.5), false, 3.0 if k == selected else 1.0)
			_full.append([k, cx])
			if stamp + 1 < STAMP_POOL:
				_place_stamp(_stamp(stamp), k, "earth_from_year", cx, band.end.y + 2.0, "HUDCaption")
				_place_stamp(_stamp(stamp + 1), k, "arrived.tau", cx, band.end.y + 14.0, "HUDAccent")
				stamp += 2
			last_full = cx
		else:
			var w := clampf(cx - prev_x, 1.0, THUMB.x)
			var ts := t.get_size()
			var src := Rect2(ts.x * 0.5 - w * ts.x / THUMB.x * 0.5, 0, w * ts.x / THUMB.x, ts.y)
			draw_texture_rect_region(t, Rect2(cx - w, band.position.y, w, THUMB.y), src)
			if k == selected:
				draw_rect(Rect2(cx - w - 1, band.position.y - 2, w + 2, THUMB.y + 4), StapledonTheme.CORAL, false, 2.0)
		prev_x = cx
	# Earth time received against ship time (positions only)
	var te_max := 1e-9
	for r: Dictionary in records:
		te_max = maxf(te_max, float(r.get("earth_to_year", 0.0)) - float(records[0].get("earth_from_year", 0.0)))
	var pts := PackedVector2Array()
	for k in records.size():
		var r: Dictionary = records[k]
		var e := float(r.get("earth_to_year", 0.0)) - float(records[0].get("earth_from_year", 0.0))
		pts.append(Vector2(tx(_tau(k)), band.end.y - 2.0 - e / te_max * (band.size.y - 6.0)))
	if pts.size() > 1:
		draw_polyline(pts, Color(StapledonTheme.CREAM, 0.55), 1.2, true)
	var nx := tx(_tau_now())
	draw_colored_polygon(PackedVector2Array([Vector2(nx + 4, band.position.y - 6), Vector2(nx - 3, band.position.y - 10), Vector2(nx - 3, band.position.y - 2)]), StapledonTheme.TEAL_LIGHT)


func _tau(k: int) -> float:
	return float(records[k].get("arrived", {}).get("tau", 0.0))


func _place_stamp(b: ComposedBinding, k: int, path: String, cx: float, y: float, variation: String) -> void:
	b.compose([["earth_log.records.%d.%s" % [k, path], "comms_clock"]])
	b.update_from(view)
	b.theme_type_variation = variation # Earth date ochre (HUDCaption), ship date teal (HUDAccent)
	b.size = Vector2(THUMB.x + 10.0, 12.0)
	b.position = Vector2(cx - b.size.x * 0.5, y)
	b.visible = true


## The record under a point: a picture drawn in full, else the beamed record nearest in x.
func record_at(p: Vector2) -> int:
	for f: Array in _full:
		if absf(p.x - float(f[1])) <= THUMB.x * 0.5 and p.y >= BAND_Y and p.y <= BAND_Y + THUMB.y:
			return int(f[0])
	var best := -1
	var bd := 6.0
	for k in records.size():
		if records[k].get("beamed") == true and absf(tx(_tau(k)) - p.x) < bd:
			bd = absf(tx(_tau(k)) - p.x)
			best = k
	return best


func select(k: int) -> void:
	selected = -1 if k == selected or k < 0 or k >= records.size() or records[k].get("beamed") != true else k
	queue_redraw()
	week_selected.emit(selected)


func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed:
		var mb := ev as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			select(record_at(mb.position))
			accept_event()
		elif mb.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			zoom_about(mb.position.x, 0.8 if mb.button_index == MOUSE_BUTTON_WHEEL_UP else 1.25)
			accept_event()
	elif ev is InputEventKey and ev.pressed and (ev as InputEventKey).keycode == KEY_ESCAPE and selected >= 0:
		select(selected)
		accept_event()


## Zoom the ship-time axis by `f` about the pointer's x; back out to the whole voyage resets it.
func zoom_about(px: float, f: float) -> void:
	var now := maxf(_tau_now(), 1e-9)
	var at := tau_from + (px - 10.0) / maxf(size.x - 22.0, 1.0) * (tau_to - tau_from)
	var span := clampf((tau_to - tau_from) * f, now / 400.0, now)
	tau_from = clampf(at - (at - tau_from) * span / maxf(tau_to - tau_from, 1e-12), 0.0, now - span)
	tau_to = tau_from + span
	zoomed = span < now * 0.999
	queue_redraw()
