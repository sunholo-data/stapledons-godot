class_name ReasonCard
extends Control
## R3-REASONS RT5 (design r3/reasons-to-travel.md, "The idea in one picture"): the reason card. One
## candidate world answers three questions in pictures: what the ship saw (the spectrum, how sure, how
## old the light), what the world could change aboard (the ship's eight resources, lit by the chance
## this kind of world could improve each; the ship's tightest ringed), and what going costs (Earth
## years and ship years large, mass small: time is the expensive currency, Mark 2026-11-12). Under
## them, the likely states when the light left and at arrival.
## Every number is a sim field of the finder section (protocol 2.19, planned), shown through a
## ComposedBinding (D-21); Godot only places marks. Words come from data/ui/finder.json. The card
## carries no score, no ranking and no recommendation (pillar 2; finder AC 5).
## True and Processed (standing order 2026-10-30): True draws the recorded counts; Processed lays the
## fitted model over them. Neither draws a line the instrument did not record.

const COPY_PATH := "res://data/ui/finder.json"
const RESOURCES := ["mass", "water", "power", "heat", "garden", "fabrication", "compute", "signal"]
const STATES := ["sterile", "microbial", "complex", "pretech", "technological", "remnant", "transcended", "ecocide"]
const STATE_COLOR := {
	"sterile": Color("#3a4257"), "microbial": Color("#3F7F86"), "complex": Color("#A8DDB0"), "pretech": Color("#E3B26B"),
	"technological": Color("#f2d180"), "remnant": Color("#8a78b0"), "transcended": Color("#EFE3C8"), "ecocide": Color("#F2967E")}
const PANE := Color("#111827")
const WELL := Color("#070a11")
const EDGE := Color("#26324a")
const OFF := Color("#4a5670")
const PAD := 14.0
const MIN_SIZE := Vector2(1000, 520)
## Glyphs as polylines in a 44-unit box (drawn, not fonts: the standing order asks for pictures).
const GLYPH := {
	"mass": [[22, 8, 34, 15, 34, 29, 22, 36, 10, 29, 10, 15, 22, 8], [10, 15, 22, 22, 34, 15], [22, 22, 22, 36]],
	"water": [[22, 7, 28, 16, 32, 22, 32, 27, 29, 33, 22, 36, 15, 33, 12, 27, 12, 22, 16, 16, 22, 7]],
	"power": [[25, 6, 12, 24, 21, 24, 18, 38, 32, 19, 23, 19, 25, 6]],
	"heat": [[12, 34, 9, 28, 14, 22, 9, 16, 12, 8], [22, 34, 19, 28, 24, 22, 19, 16, 22, 8], [32, 34, 29, 28, 34, 22, 29, 16, 32, 8]],
	"garden": [[22, 37, 22, 20], [22, 24, 14, 22, 10, 12, 18, 14, 22, 24], [22, 20, 24, 12, 34, 8, 32, 16, 22, 20]],
	"fabrication": [[22, 8, 34, 15, 34, 29, 22, 36, 10, 29, 10, 15, 22, 8], [22, 17, 26, 19, 27, 23, 24, 27, 20, 27, 17, 23, 18, 19, 22, 17]],
	"compute": [[13, 13, 31, 13, 31, 31, 13, 31, 13, 13], [18, 13, 18, 7], [26, 13, 26, 7], [18, 31, 18, 37], [26, 31, 26, 37], [13, 18, 7, 18], [13, 26, 7, 26], [31, 18, 37, 18], [31, 26, 37, 26]],
	"signal": [[10, 30, 12, 22, 17, 16, 24, 13, 27, 13, 10, 30], [19, 21, 28, 12], [31, 7, 35, 10, 37, 14]],
	"mind": [[10, 22, 10, 12, 14, 8, 20, 8, 24, 12, 24, 22], [6, 36, 8, 28, 13, 26, 21, 26, 26, 28, 28, 36], [28, 10, 38, 10, 38, 19, 33, 19, 30, 23, 30, 19, 28, 19, 28, 10]]}

var view: Dictionary = {}
var index := 0 # which finder.candidates row
var processed := false
var copy: Dictionary = {}
## Placed marks, rebuilt by refresh and on resize; the tests read them.
var panes: Array[Rect2] = []
var glyphs: Array = [] # [{id, strength, need, rect}]
var mind := {} # {strength, rect}
var bars := {} # earth, ship, mass: {track: Rect2, fill: Rect2}
var earth_ticks: Array = [] # [{x, word}]
var states_then: Array = [] # [{state, rect, p}]
var states_arrival: Array = []
var spectrum_box := Rect2()
var dial_sure := {} # {center, radius, fraction, hint, strong}
var dial_age := {} # {center, radius, now, added}
## The best picture: the target through the ship's telescope at its real resolution. box, px (pixels per
## lambda/D), iwa_px, au_px (Earth's orbit at that distance, for scale), planet (its place, or null when
## it sits inside the inner working angle and cannot be separated from the star), color.
var image := {}
const IMAGE_SPAN := 12.0 # the picture's half-width in lambda/D
## What the last _draw put on screen, for the tests (a drawn string is not a Label, so the display
## audit cannot see it): every string, and which marks were drawn.
var drawn_text: Array[String] = []
var drawn := {"planet": false, "model": false, "rings": [], "hidden_note": false}
var _labels := {} # name -> ComposedBinding
var _toggle_true: Button
var _toggle_processed: Button


static var _words_cache: Dictionary = {}


static func words() -> Dictionary:
	if not _words_cache.is_empty():
		return _words_cache
	var f := FileAccess.open(COPY_PATH, FileAccess.READ)
	if f == null:
		return {}
	var j: Variant = JSON.parse_string(f.get_as_text())
	_words_cache = j if j is Dictionary else {}
	return _words_cache


## Formats for the card's bindings: formatting only, one sim field in, no arithmetic on it.
static func format(fmt: String, raw: Variant) -> String:
	if raw == null:
		return "-"
	match fmt:
		"finder_years": return "%s years" % _fixed(float(raw), 1)
		"finder_ago": return "%s years ago" % _fixed(float(raw), 1)
		"finder_ly": return "%s light-years" % _fixed(float(raw), 1)
		"finder_kg": return "%s kg" % _thousands(int(round(float(raw))))
		"finder_sure":
			var w: Dictionary = words().get("words", {})
			return str(w.get(str(raw), str(raw)))
	return str(raw)


static func _fixed(v: float, places: int) -> String:
	return ("%." + str(places) + "f") % v


static func _thousands(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return ("-" if n < 0 else "") + s + out


func _init() -> void:
	name = "ReasonCard"
	custom_minimum_size = MIN_SIZE
	theme = StapledonTheme.theme()
	copy = words()
	for spec: Array in [["name", "HUDTitle", 22], ["sub", "HUDCaption", 14], ["sure", "HUDValue", 15], ["age", "HUDValue", 15],
			["earth", "HUDValue", 18], ["ship", "HUDValue", 18], ["mass", "HUDCaption", 13], ["stale", "HUDCaption", 12], ["seen", "HUDLabel", 15]]:
		var b := ComposedBinding.new()
		b.theme_type_variation = spec[1]
		b.add_theme_font_size_override("font_size", spec[2])
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.visible = false # shown once it has a field (the display audit never sees an unbound binding)
		add_child(b)
		_labels[spec[0]] = b
	_labels.seen.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var w: Dictionary = copy.get("words", {})
	_toggle_true = _toggle(str(w.get("true", "True")), false)
	_toggle_processed = _toggle(str(w.get("processed", "Processed")), true)
	resized.connect(_place)


func _toggle(text: String, to: bool) -> Button:
	var b := Button.new()
	b.text = text
	b.toggle_mode = true
	b.theme_type_variation = "HUDFlat"
	b.add_theme_font_size_override("font_size", 12)
	b.pressed.connect(func() -> void: set_processed(to))
	add_child(b)
	return b


func set_processed(on: bool) -> void:
	processed = on
	_toggle_true.set_pressed_no_signal(not on)
	_toggle_processed.set_pressed_no_signal(on)
	queue_redraw()


func candidate() -> Dictionary:
	var c: Variant = GalaxyMap.field_value(view, "finder.candidates.%d" % index)
	return c if c is Dictionary else {}


func refresh(v: Dictionary, i := -1) -> void:
	view = v
	if i >= 0:
		index = i
	var base := "finder.candidates.%d." % index
	var has := not candidate().is_empty()
	_labels.name.compose([[base + "name", "text"]])
	_labels.sub.compose([[base + "distance_ly", "finder_ly"], "  ·  ", [base + "host_class", "text"]])
	_labels.sure.compose([[base + "belief.sure", "finder_sure"]])
	_labels.age.compose([[base + "belief.light_age_years", "finder_ago"]])
	_labels.earth.compose([[base + "cost.earth_years", "finder_years"]])
	_labels.ship.compose([[base + "cost.ship_years", "finder_years"]])
	_labels.mass.compose([[base + "cost.mass_kg", "finder_kg"]])
	var w: Dictionary = copy.get("words", {})
	_labels.stale.compose([str(w.get("stale_before", "")), [base + "cost.stale_years", "finder_years"], str(w.get("stale_after", ""))])
	_labels.seen.compose([[base + "seen", "text"]])
	for k: String in _labels:
		_labels[k].visible = has
		_labels[k].update_from(view)
	set_processed(processed)
	_place()


static func _num(d: Variant, k: String) -> float:
	return float(d[k]) if d is Dictionary and d.get(k) != null else 0.0


## Places every mark from the sim fields. Positions only: a bar's length is its field against the
## scale the sim gives (finder.doom_years, voyage_years, free_mass_kg); nothing shown is computed here.
func _place() -> void:
	var c := candidate()
	var f: Variant = view.get("finder", {})
	var w := maxf(size.x, MIN_SIZE.x)
	var h := maxf(size.y, MIN_SIZE.y)
	var head := 46.0
	var foot := 172.0
	var pw := (w - PAD * 4.0) / 3.0
	var ph := h - head - foot - PAD
	panes.clear()
	for i in 3:
		panes.append(Rect2(PAD + i * (pw + PAD), head, pw, ph))
	_labels.name.position = Vector2(PAD, 8)
	_labels.sub.position = Vector2(PAD + _labels.name.get_minimum_size().x + 14.0, 16)
	# pane 0: the spectrum, the toggle, the two dials
	var a := panes[0]
	spectrum_box = Rect2(a.position + Vector2(10, 32), Vector2(a.size.x - 20, clampf(a.size.y - 230.0, 90.0, 140.0)))
	_toggle_true.position = Vector2(a.position.x + 10, spectrum_box.end.y + 8)
	_toggle_processed.position = _toggle_true.position + Vector2(_toggle_true.get_minimum_size().x + 6, 0)
	var side := clampf(a.end.y - spectrum_box.end.y - 62.0, 80.0, 130.0)
	var ib := Rect2(a.position.x + 10, spectrum_box.end.y + 50.0, side, side)
	var im: Dictionary = c.get("image", {})
	var px := side * 0.5 / IMAGE_SPAN
	var sep := _num(im, "separation_lambda_d")
	var iwa := _num(f, "iwa_lambda_d")
	var rgb: Array = im.get("star_rgb", [1.0, 1.0, 1.0])
	image = {"inside": sep < iwa and not im.is_empty(), "box": ib, "px": px, "iwa_px": iwa * px, "au_px": _num(im, "au_lambda_d") * px,
		"planet": ib.get_center() + Vector2(sep * px, 0).rotated(-0.6) if sep >= iwa and sep < IMAGE_SPAN and not im.is_empty() else null,
		"color": Color(float(rgb[0]), float(rgb[1]), float(rgb[2])) if rgb.size() == 3 else Color.WHITE}
	var dx := ib.end.x + 16.0
	var dy := ib.position.y + 30.0
	var strong := _num(f, "snr_strong")
	var snr := _num(c.get("belief", {}), "snr")
	dial_sure = {"center": Vector2(dx + 26, dy), "radius": 22.0,
		"fraction": clampf(snr / (strong * 1.5), 0.0, 1.0) if strong > 0.0 else 0.0,
		"hint": _num(f, "snr_hint") / (strong * 1.5) if strong > 0.0 else 0.0, "strong": 1.0 / 1.5}
	_labels.sure.position = Vector2(dx + 60, dy - 4)
	var age := _num(c.get("belief", {}), "light_age_years")
	var stale := _num(c.get("cost", {}), "stale_years")
	dial_age = {"center": Vector2(dx + 26, dy + 62.0), "radius": 22.0,
		"now": age / stale if stale > 0.0 else 0.0, "added": 1.0 - age / stale if stale > 0.0 else 0.0}
	_labels.age.position = Vector2(dx + 60, dy + 58.0)
	# pane 1: the eight resources and the crew
	var b := panes[1]
	var offer: Dictionary = c.get("offer", {})
	var needs: Array = f.get("needs", []) if f is Dictionary else []
	glyphs.clear()
	var cell := Vector2((b.size.x - 20.0) / 4.0, 82.0)
	for i in RESOURCES.size():
		var id: String = RESOURCES[i]
		var at := b.position + Vector2(10 + (i % 4) * cell.x + (cell.x - 44.0) * 0.5, 36 + (i / 4) * cell.y)
		glyphs.append({"id": id, "strength": clampf(_num(offer, id), 0.0, 1.0), "need": needs.has(id), "rect": Rect2(at, Vector2(44, 44))})
	mind = {"strength": clampf(_num(c, "mind"), 0.0, 1.0), "rect": Rect2(b.position + Vector2(14, 36 + 2 * cell.y + 6), Vector2(44, 44))}
	# pane 2: the cost. Time large, mass small.
	var k := panes[2]
	var x0 := k.position.x + 12.0
	var bw := k.size.x - 24.0
	var cost: Dictionary = c.get("cost", {})
	var doom := _num(f, "doom_years")
	bars = {
		"earth": _bar(x0, k.position.y + 62.0, bw, 18.0, _log_fraction(_num(cost, "earth_years"), doom)),
		"ship": _bar(x0, k.position.y + 138.0, bw, 18.0, _fraction(_num(cost, "ship_years"), _num(f, "voyage_years"))),
		"mass": _bar(x0, k.position.y + 204.0, bw, 6.0, _fraction(_num(cost, "mass_kg"), _num(f, "free_mass_kg")))}
	earth_ticks.clear()
	for m: Variant in copy.get("earth_marks", []):
		if m is Dictionary:
			earth_ticks.append({"x": x0 + bw * _log_fraction(float(m.get("years", 0.0)), doom), "word": str(m.get("word", ""))})
	_labels.earth.position = Vector2(k.end.x - 12 - _labels.earth.get_minimum_size().x, k.position.y + 34.0)
	_labels.ship.position = Vector2(k.end.x - 12 - _labels.ship.get_minimum_size().x, k.position.y + 110.0)
	_labels.mass.position = Vector2(k.end.x - 12 - _labels.mass.get_minimum_size().x, k.position.y + 182.0)
	_labels.stale.position = Vector2(x0, k.position.y + 222.0)
	# the foot: the two state bars and the line of what was seen
	var sy := head + ph + PAD + 26.0
	var sx := PAD + 170.0
	states_then = _states(c.get("belief", {}).get("p", {}), Rect2(sx, sy, w - sx - PAD, 20))
	states_arrival = _states(c.get("arrival", {}).get("p", {}), Rect2(sx, sy + 30, w - sx - PAD, 20))
	_labels.seen.position = Vector2(PAD, sy + 84)
	_labels.seen.size = Vector2(w - PAD * 2.0, 44)
	queue_redraw()


static func _fraction(v: float, of: float) -> float:
	return clampf(v / of, 0.0, 1.0) if of > 0.0 else 0.0


## The Earth bar is a log scale from one year to the doom clock, so a human span stays visible beside
## sixteen thousand years (on a linear bar a forty-year trip is one four-hundredth of the width).
static func _log_fraction(years: float, doom: float) -> float:
	if years <= 1.0 or doom <= 1.0:
		return 0.0
	return clampf(log(years) / log(doom), 0.0, 1.0)


static func _bar(x: float, y: float, w: float, h: float, fraction: float) -> Dictionary:
	return {"track": Rect2(x, y, w, h), "fill": Rect2(x, y, w * fraction, h)}


static func _states(p: Variant, box: Rect2) -> Array:
	var out: Array = []
	if not p is Dictionary:
		return out
	var total := 0.0
	for s: String in STATES:
		total += _num(p, s)
	if total <= 0.0:
		return out
	var x := box.position.x
	for s: String in STATES:
		var v := _num(p, s)
		if v > 0.0:
			var wd := box.size.x * v / total
			out.append({"state": s, "rect": Rect2(x, box.position.y, wd, box.size.y), "p": v})
			x += wd
	return out


func _say(font: Font, at: Vector2, text: String, align: HorizontalAlignment, width: float, font_size: int, col: Color) -> void:
	drawn_text.append(text)
	draw_string(font, at, text, align, width, font_size, col)


func _draw() -> void:
	drawn_text.clear()
	drawn = {"planet": false, "model": false, "rings": [], "hidden_note": false}
	var font := get_theme_default_font()
	var w: Dictionary = copy.get("words", {})
	var c := candidate()
	draw_rect(Rect2(Vector2.ZERO, size), Color(StapledonTheme.NIGHT, StapledonTheme.CARD_ALPHA))
	draw_rect(Rect2(Vector2.ZERO, size), EDGE, false, 1.0)
	if c.is_empty() or panes.size() < 3:
		return
	var titles := [str(w.get("seen", "")), str(w.get("change", "")), str(w.get("cost", ""))]
	for i in 3:
		draw_rect(panes[i], PANE)
		_say(font, panes[i].position + Vector2(10, 22), titles[i].to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, StapledonTheme.DIM)
	_draw_spectrum(font, c.get("spectrum", {}))
	_draw_image(font, w)
	_draw_dials(font, w)
	_draw_glyphs(font, w)
	_draw_cost(font, w)
	_draw_states(font, w)


func _draw_spectrum(font: Font, sp: Dictionary) -> void:
	draw_rect(spectrum_box, WELL)
	var lam: Array = sp.get("lambda_um", [])
	var counts: Array = sp.get("counts", [])
	if lam.size() < 2 or counts.size() != lam.size():
		return
	var lo := float(lam[0])
	var hi := float(lam[lam.size() - 1])
	var box := spectrum_box.grow(-8.0)
	var names: Dictionary = copy.get("lines", {})
	for l: Variant in sp.get("lines", []):
		if l is Dictionary:
			var x := box.position.x + (float(l.get("lambda_um", lo)) - lo) / (hi - lo) * box.size.x
			var col := StapledonTheme.OCHRE_LIGHT if bool(l.get("fired", false)) else OFF
			draw_line(Vector2(x, box.position.y + 14), Vector2(x, box.end.y), col, 1.0)
			_say(font, Vector2(x - 24, box.position.y + 10), str(names.get(str(l.get("id", "")), "")), HORIZONTAL_ALIGNMENT_CENTER, 48, 11, col)
	var at := func(i: int, v: float) -> Vector2:
		return Vector2(box.position.x + (float(lam[i]) - lo) / (hi - lo) * box.size.x, box.end.y - clampf(v, 0.0, 1.15) / 1.15 * (box.size.y - 16.0))
	for i in lam.size():
		draw_circle(at.call(i, float(counts[i])), 1.8, StapledonTheme.TEAL_LIGHT)
	var model: Array = sp.get("model", [])
	if processed and model.size() == lam.size():
		var pts := PackedVector2Array()
		for i in lam.size():
			pts.append(at.call(i, float(model[i])))
		draw_polyline(pts, StapledonTheme.CORAL, 2.0, true)
		drawn.model = true


## The best picture. True: what the telescope records, the star's diffraction pattern (a core and
## rings; the planet is some ten billion times fainter and is not drawn, because it is not seen).
## Processed: the starlight suppressed outside the inner working angle (the dashed circle); a planet
## beyond it shows as a speck, one inside it stays lost. Never a surface: nothing here is resolved.
func _draw_image(font: Font, w: Dictionary) -> void:
	if image.is_empty():
		return
	var b: Rect2 = image.box
	var c := b.get_center()
	var px: float = image.px
	var col: Color = image.color
	draw_rect(b, WELL)
	_say(font, Vector2(b.position.x, b.position.y - 6), str(w.get("picture", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, StapledonTheme.DIM)
	if processed:
		draw_circle(c, 1.22 * px, Color(col, 0.25))
		for i in 32: # the inner working angle
			if i % 2 == 0:
				draw_arc(c, image.iwa_px, TAU * i / 32.0, TAU * (i + 1) / 32.0, 4, Color(StapledonTheme.DIM, 0.7), 1.0, true)
		if image.planet != null:
			drawn.planet = true
			draw_circle(image.planet, 2.6, StapledonTheme.TEAL_LIGHT)
			draw_arc(image.planet, 6.0, 0.0, TAU, 20, Color(StapledonTheme.TEAL_LIGHT, 0.5), 1.0, true)
		elif image.inside: # lost in the glare; a planet beyond the frame gets no note
			drawn.hidden_note = true
			_say(font, Vector2(b.position.x + 4, b.end.y - 6), str(w.get("hidden", "")), HORIZONTAL_ALIGNMENT_LEFT, b.size.x - 8, 10, StapledonTheme.DIM)
	else:
		var zeros := [1.22, 2.233, 3.238, 4.241, 5.243, 6.244, 7.245, 8.245, 9.246, 10.246]
		for i in range(zeros.size() - 1, 0, -1): # the Airy rings, each fainter (about r to the minus three)
			var r: float = (zeros[i - 1] + zeros[i]) * 0.5
			draw_arc(c, r * px, 0.0, TAU, 64, Color(col, clampf(0.9 / pow(r, 1.6), 0.03, 0.6)), maxf(1.0, (zeros[i] - zeros[i - 1]) * px * 0.55), true)
		draw_circle(c, 1.22 * px, col)
		draw_circle(c, 0.6 * px, Color.WHITE)
	# Earth's orbit at this distance, for scale
	if image.au_px > 2.0 and image.au_px < b.size.x:
		var y := b.end.y + 8.0
		draw_line(Vector2(b.position.x, y), Vector2(b.position.x + image.au_px, y), StapledonTheme.CREAM, 1.5)
		_say(font, Vector2(b.position.x, y + 14), str(w.get("orbit", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, StapledonTheme.DIM)


func _draw_dials(font: Font, w: Dictionary) -> void:
	var s: Dictionary = dial_sure
	var from := deg_to_rad(135.0)
	var sweep := deg_to_rad(270.0)
	draw_arc(s.center, s.radius, from, from + sweep, 48, EDGE, 6.0, true)
	if s.fraction > 0.0:
		draw_arc(s.center, s.radius, from, from + sweep * s.fraction, 48, StapledonTheme.TEAL_LIGHT, 6.0, true)
	for t: float in [s.hint, s.strong]: # the two thresholds (finder.snr_hint, finder.snr_strong)
		var d := Vector2.from_angle(from + sweep * t)
		draw_line(s.center + d * (s.radius - 7.0), s.center + d * (s.radius + 7.0), StapledonTheme.CREAM, 1.5)
	_say(font, _labels.sure.position + Vector2(0, -4), str(w.get("sure", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, StapledonTheme.DIM)
	var a: Dictionary = dial_age
	draw_arc(a.center, a.radius, 0.0, TAU, 64, EDGE, 3.0, true)
	_wedge(a.center, a.radius - 3.0, 0.0, a.now, Color(StapledonTheme.OCHRE, 0.75)) # how old the light is now
	_wedge(a.center, a.radius - 3.0, a.now, a.now + a.added, Color(StapledonTheme.CORAL, 0.45)) # what the trip adds
	_say(font, _labels.age.position + Vector2(0, -4), str(w.get("light", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, StapledonTheme.DIM)


func _wedge(center: Vector2, radius: float, t0: float, t1: float, col: Color) -> void:
	if t1 - t0 <= 0.001:
		return
	var pts := PackedVector2Array([center])
	var n := maxi(3, int(48.0 * (t1 - t0)))
	for i in n + 1:
		pts.append(center + Vector2.from_angle(-PI * 0.5 + TAU * lerpf(t0, t1, float(i) / n)) * radius)
	draw_colored_polygon(pts, col)


func _draw_glyph(id: String, at: Vector2, col: Color, width: float) -> void:
	for stroke: Array in GLYPH.get(id, []):
		var pts := PackedVector2Array()
		for i in range(0, stroke.size(), 2):
			pts.append(at + Vector2(stroke[i], stroke[i + 1]))
		draw_polyline(pts, col, width, true)


func _draw_glyphs(font: Font, w: Dictionary) -> void:
	var names: Dictionary = copy.get("resources", {})
	for g: Dictionary in glyphs:
		var r: Rect2 = g.rect
		var lit: bool = g.strength > 0.05
		var col := Color(StapledonTheme.TEAL_LIGHT, 0.3 + 0.7 * g.strength) if lit else OFF
		_draw_glyph(g.id, r.position, col, 1.4 + 1.6 * g.strength)
		if g.need: # the ship's tightest: a dashed ring
			drawn.rings.append(g.id)
			for i in 24:
				if i % 2 == 0:
					draw_arc(r.get_center(), 27.0, TAU * i / 24.0, TAU * (i + 1) / 24.0, 4, StapledonTheme.OCHRE_LIGHT, 2.0, true)
		_say(font, Vector2(r.position.x - 28, r.end.y + 16), str(names.get(g.id, "")), HORIZONTAL_ALIGNMENT_CENTER, 100, 11,
			StapledonTheme.OCHRE_LIGHT if g.need else StapledonTheme.DIM)
	var m: Rect2 = mind.rect
	_draw_glyph("mind", m.position, Color("#8a78b0", 0.3 + 0.7 * mind.strength), 1.4 + 1.8 * mind.strength)
	_say(font, Vector2(m.end.x + 10, m.get_center().y + 4), str(w.get("crew", "")), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, StapledonTheme.CREAM)


func _draw_cost(font: Font, w: Dictionary) -> void:
	var cols := {"earth": StapledonTheme.CORAL, "ship": StapledonTheme.TEAL_LIGHT, "mass": StapledonTheme.DIM}
	for id: String in ["earth", "ship", "mass"]:
		var b: Dictionary = bars[id]
		var t: Rect2 = b.track
		draw_rect(t, WELL)
		draw_rect(b.fill, cols[id])
		_say(font, Vector2(t.position.x, t.position.y - 8), str(w.get(id, "")), HORIZONTAL_ALIGNMENT_LEFT, -1, 13 if id != "mass" else 12, StapledonTheme.CREAM)
	var e: Rect2 = bars.earth.track
	for tk: Dictionary in earth_ticks:
		draw_line(Vector2(tk.x, e.position.y), Vector2(tk.x, e.end.y), EDGE, 1.0)
		_say(font, Vector2(tk.x - 40, e.end.y + 13), tk.word, HORIZONTAL_ALIGNMENT_CENTER, 80, 10, StapledonTheme.DIM)


func _draw_states(font: Font, w: Dictionary) -> void:
	var rows := [[states_then, str(w.get("then", ""))], [states_arrival, str(w.get("arrival", ""))]]
	for row: Array in rows:
		var parts: Array = row[0]
		if parts.is_empty():
			continue
		var first: Rect2 = parts[0].rect
		_say(font, Vector2(PAD, first.position.y + 15), row[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, StapledonTheme.DIM)
		for p: Dictionary in parts:
			draw_rect(p.rect, STATE_COLOR[p.state])
	# the legend: a square and a word for each state present in either bar (no numbers: the bars carry them)
	var names: Dictionary = copy.get("states", {})
	if not states_then.is_empty():
		var lx: float = states_then[0].rect.position.x
		var ly: float = states_then[0].rect.position.y + 62.0
		for s: String in STATES:
			if states_then.any(func(p: Dictionary) -> bool: return p.state == s) or states_arrival.any(func(p: Dictionary) -> bool: return p.state == s):
				var label := str(names.get(s, s))
				draw_rect(Rect2(lx, ly, 10, 10), STATE_COLOR[s])
				_say(font, Vector2(lx + 15, ly + 10), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, StapledonTheme.DIM)
				lx += 15.0 + font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + 18.0
	if not states_then.is_empty():
		var top: Rect2 = states_then[0].rect
		_say(font, Vector2(PAD, top.position.y - 10), str(w.get("there", "")).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, StapledonTheme.DIM)
