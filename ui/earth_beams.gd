class_name EarthBeams
extends Control
## R3-EARTH-LINK EL4 (F6; design r3/earth-link.md EL4): Earth's beams on the galaxy map, a layer over
## the map's overlay (drawn from GalaxyMap._draw_overlay, as IsmLayer is). Every element comes from
## one earth.* field and Godot only places it:
##   beam      the plan Earth aims at now: a solid line from Sol through the port and on past it (the
##             beam covers the ray), Earth's light-front on it at clock.t - heard_t      earth.beam
##   pending   a plan still in flight to Earth: a dashed line Sol -> port, and the message's light-front
##             on its way home along the line it was sent from, labelled with its arrival  earth.pending
##   stale     Earth still aiming at a port the ship has left, faded, "empty until ..."     earth.stale
##   window    the wait at the leg's port for Earth's light: a ring, open or with the wait  earth.window
##   silence   out of beam: the last beamed light's front around Sol, "silent since ..."   earth.last_beam_*
##   preview   a planned, uncommitted leg: the dashed line to its port, its wait and the beam the commit
##             would leave stale. While a plan is uncommitted nothing else of earth.* is read (design
##             AC12, pillar 1: the preview is a cost, never an outcome)               earth.preview
## Positions are the sim's galactic light-years; numbers on screen are ComposedBinding labels
## (children of this layer, so the display audit sees them). Below protocol 2.16 there is no earth
## section and nothing is drawn.

const COPY := "res://data/ui/earth_beams.json"
const FRONT_PX := 4.0

static var _copy: Dictionary = {}

## The elements, rebuilt by refresh: [{kind, a: Vector3, b: Vector3, front: Vector3 or null,
## dashed, label: line key or "", i: index in its list, open: bool (window)}], in galactic ly.
var elements: Array = []
## The earth.* keys the last refresh read (AC12: only "preview" while a plan is uncommitted).
var read: Array[String] = []
var silence_radius := 0.0
var _labels: Array[ComposedBinding] = []


static func copy() -> Dictionary:
	if _copy.is_empty():
		_copy = NewsCopy.load_json(COPY)
	return _copy


static func vec(d: Variant) -> Vector3:
	return Vector3(float(d.x), float(d.y), float(d.z)) if d is Dictionary and d.has("x") else Vector3.ZERO


func _init() -> void:
	name = "EarthBeams"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _get_earth(e: Dictionary, key: String) -> Variant:
	if not read.has(key):
		read.append(key)
	return e.get(key)


## The sim's view (the map's _last_view): rebuilds the elements and binds their labels.
func refresh(view: Dictionary) -> void:
	elements = []
	read.clear()
	silence_radius = 0.0
	var e: Variant = view.get("earth")
	if e is Dictionary:
		if str(GalaxyMap.field_value(view, "journey.state")) == "planned":
			_preview(e)
		else:
			_link(e, view)
	_bind(view)
	queue_redraw()


func _preview(e: Dictionary) -> void:
	var p: Variant = _get_earth(e, "preview")
	if not p is Dictionary:
		return
	var port := vec(p.port)
	elements.append({"kind": "preview", "a": Vector3.ZERO, "b": port, "front": null, "dashed": true,
		"label": "preview_wait" if float(p.get("wait_years", 0.0)) > 0.0 else "", "i": 0, "at": port})
	if p.get("would_stale") is Dictionary:
		var s := vec(p.would_stale.port)
		elements.append({"kind": "stale", "a": Vector3.ZERO, "b": s * float(copy().far), "front": null, "dashed": false, "label": "preview_stale", "i": 0, "at": s})


func _link(e: Dictionary, view: Dictionary) -> void:
	var t: Variant = GalaxyMap.field_value(view, "clock.t")
	var far := float(copy().far)
	var b: Variant = _get_earth(e, "beam")
	var st: Variant = _get_earth(e, "stale")
	if b is Dictionary:
		var port := vec(b.port)
		var front: Variant = null
		if t != null and port.length() > 0.0:
			front = port.normalized() * maxf(float(t) - float(b.heard_t), 0.0)
			if (front as Vector3).length() > port.length() * far:
				front = null
		# Earth still aiming at a port the ship has left: the beam is that stale beam, drawn faded once
		var left: bool = st is Array and (st as Array).any(func(s: Dictionary) -> bool: return str(s.get("port_id", "")) == str(b.port_id))
		elements.append({"kind": "beam", "a": Vector3.ZERO, "b": port * far, "front": front, "dashed": false, "label": "", "i": 0, "at": port, "left": left})
	var ms: Array = _get_earth(e, "messages") if _get_earth(e, "messages") is Array else []
	var pend: Variant = _get_earth(e, "pending")
	for i in (pend as Array).size() if pend is Array else 0:
		var m: Dictionary = pend[i]
		var from := Vector3.ZERO
		for msg: Dictionary in ms:
			if float(msg.get("sent_t", -1.0)) == float(m.sent_t) and str(msg.get("port_id", "")) == str(m.port_id):
				from = vec(msg.from)
		var front: Variant = null
		if t != null and from.length() > 0.0:
			front = from.normalized() * clampf(float(m.heard_t) - float(t), 0.0, from.length())
		elements.append({"kind": "pending", "a": Vector3.ZERO, "b": vec(m.port), "front": front, "dashed": true, "label": "pending", "i": i, "at": front if front != null else vec(m.port)})
	for i in (st as Array).size() if st is Array else 0:
		var port := vec(st[i].port)
		var drawn: bool = b is Dictionary and str(st[i].get("port_id", "")) == str(b.port_id) # the beam above draws it
		elements.append({"kind": "stale", "a": Vector3.ZERO, "b": port * far, "front": null, "dashed": false, "label": "stale", "i": i, "at": port, "line": not drawn})
	var w: Variant = _get_earth(e, "window")
	if w is Dictionary:
		var open := float(w.get("wait_years", 0.0)) <= 0.0
		elements.append({"kind": "window", "a": vec(w.port), "b": vec(w.port), "front": null, "dashed": false, "label": "" if open else "window_wait", "i": 0, "open": open, "at": vec(w.port)})
	if _get_earth(e, "in_beam") == false and t != null and _get_earth(e, "last_beam_t") != null:
		silence_radius = maxf(float(t) - float(e.last_beam_t), 0.0)
		var ship := vec(GalaxyMap.field_value(view, "ship.pos"))
		elements.append({"kind": "silence", "a": Vector3.ZERO, "b": Vector3.ZERO, "front": null, "dashed": false, "label": "silence", "i": 0, "at": ship})


func _bind(view: Dictionary) -> void:
	var lines: Dictionary = copy().lines
	var k := 0
	for el: Dictionary in elements:
		if str(el.label) == "":
			continue
		if k >= _labels.size():
			var l := ComposedBinding.new()
			l.add_theme_font_size_override("font_size", 12)
			l.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(l)
			_labels.append(l)
		var lab := _labels[k]
		var parts: Array = (lines[el.label] as Array).map(func(p: Variant) -> Variant:
			return [str(p[0]).replace("{i}", str(el.i)), p[1]] if p is Array else p)
		lab.compose(parts)
		lab.record_context = true # the map's own view, as its other bindings (display audit)
		lab.update_from(view)
		lab.add_theme_color_override("font_color", colour(el))
		lab.visible = true
		el["label_node"] = lab
		k += 1
	for j in range(k, _labels.size()):
		_labels[j].visible = false


func colour(el: Dictionary) -> Color:
	var c: Dictionary = copy().colors
	if el.kind == "window":
		return Color(str(c.window_open if el.get("open", false) else c.window_wait))
	return Color(str(c.get(el.kind, "#FFFFFF")))


## The projected geometry (also the golden's subject, EL5 G-EL-1): one row per element on screen,
## {kind, a, b (pixels), front (pixels or null), at (the label's anchor)}; elements behind the camera
## are left out.
func project(camera: Camera3D, to_world: Callable) -> Array:
	var out: Array = []
	for el: Dictionary in elements:
		var wa: Vector3 = to_world.call(el.a)
		var wb: Vector3 = to_world.call(el.b)
		if camera.is_position_behind(wa) or camera.is_position_behind(wb):
			continue
		var row := {"kind": el.kind, "a": camera.unproject_position(wa), "b": camera.unproject_position(wb), "front": null, "at": null}
		if el.front != null and not camera.is_position_behind(to_world.call(el.front)):
			row.front = camera.unproject_position(to_world.call(el.front))
		if el.has("at") and not camera.is_position_behind(to_world.call(el.at)):
			row.at = camera.unproject_position(to_world.call(el.at))
		row["el"] = el
		out.append(row)
	return out


## Draws into the map's overlay and places the labels.
func draw_on(overlay: Control, camera: Camera3D, to_world: Callable) -> int:
	for l in _labels:
		l.position = Vector2(-1000, -1000)
	if not visible:
		return 0
	var rows := project(camera, to_world)
	for r: Dictionary in rows:
		var el: Dictionary = r.el
		var c := colour(el)
		match str(el.kind):
			"beam":
				if el.get("left", false):
					c = colour({"kind": "stale"})
					overlay.draw_line(r.a, r.b, Color(c, 0.45), 1.5, true)
				else:
					overlay.draw_line(r.a, r.b, Color(c, 0.85), 2.0, true)
			"pending", "preview":
				if (r.a as Vector2).distance_to(r.b) > 1.0:
					overlay.draw_dashed_line(r.a, r.b, Color(c, 0.8), 1.5, 7.0, true)
				if r.front != null: # the message's way still to go, from its front home to Sol
					overlay.draw_dashed_line(r.front, r.a, Color(c, 0.55), 1.0, 3.0, true)
			"stale":
				if el.get("line", true):
					overlay.draw_line(r.a, r.b, Color(c, 0.45), 1.5, true)
			"window":
				overlay.draw_arc(r.a, 15.0, 0.0, TAU, 40, Color(c, 0.9), 2.5, true)
			"silence":
				_silence_ring(overlay, camera, to_world, Color(c, 0.6))
		if r.front != null:
			overlay.draw_circle(r.front, FRONT_PX, c)
			overlay.draw_circle(r.front, FRONT_PX * 2.2, Color(c, 0.25))
		var lab: Variant = el.get("label_node")
		if lab is ComposedBinding and r.at != null:
			# under the map's own port labels ("Current position", "Departure", the selected star's name)
			var off := Vector2(10, 4) if el.kind in ["pending", "silence"] else Vector2(12, 24)
			(lab as ComposedBinding).position = (r.at as Vector2) + off
	return rows.size()


func _silence_ring(overlay: Control, camera: Camera3D, to_world: Callable, c: Color) -> void:
	if silence_radius <= 0.0:
		return
	var pts := PackedVector2Array()
	for k in 97:
		var a := TAU * k / 96.0
		var w: Vector3 = to_world.call(Vector3(cos(a), sin(a), 0.0) * silence_radius)
		if camera.is_position_behind(w):
			return
		pts.append(camera.unproject_position(w))
	for k in range(0, pts.size() - 1, 2): # dashed, so it reads apart from the map's scale rings
		overlay.draw_line(pts[k], pts[k + 1], c, 1.5, true)
