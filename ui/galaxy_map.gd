class_name GalaxyMap
extends Node3D
## Galaxy map and plan panel (design m2-journey-core §M2.6, sprint M2.6a).
##
## Pick a star, choose a cruise speed, read the sim's plan. The map has no
## physics: every number on the panel is a field of the sim's `journey.plan`
## (or `clock`), and Godot only formats it. Selection sends `plan` with the
## star's catalogue index, id and float64 position taken from the parsed JSON
## dictionary (never from a Vector3), plus the slider's rapidity.
##
## The slider is linear in rapidity between the sim's bounds (D-14: default
## 0.99c). The clock runs at a fixed host rate and never pauses (D-12).
## Mouse: drag to orbit, wheel to zoom, click a star to select it.

signal target_selected(star_id: String)

const STAR_SHADER := preload("res://ui/star_point.gdshader")
const TICK_HZ := 20.0
## Fixed host clock rate at rest (D-12): one ship-day per real second.
const HOST_RATE := 1.0 / 365.25
const HOST_DTAU := HOST_RATE / TICK_HZ
const PICK_RADIUS_PX := 12.0
const DEFAULT_BETA := 0.99 # D-14 slice default
const RINGS_LY := [5.0, 10.0, 20.0, 50.0]
const PANEL_WIDTH := 430

## Panel rows in display order: [label, sim field, format]. Both clocks first,
## then arrival, the crew-age placeholders, then speed, energy, ISM and CMB.
const ROWS := [
	["Ship time", "journey.plan.ship_years", "sci ship-yr"],
	["Earth time", "journey.plan.earth_years", "%.3f Earth-yr"],
	["Arrival, if committed now", "journey.plan.arrive_year", "Earth +%.3f yr"],
	["Age on arrival (placeholder)", "journey.plan.age_on_arrival", "%.2f yr"],
	["Years left (placeholder)", "journey.plan.years_left", "%.2f yr"],
	["Distance", "journey.plan.distance", "%.3f ly"],
	["Cruise speed", "journey.plan.cruise_beta", "%.6fc"],
	["Cruise 1 - beta", "journey.plan.cruise_one_minus_beta", "sci"],
	["Cruise gamma", "journey.plan.cruise_gamma", "%.4f"],
	["Boost, each end", "journey.plan.boost_minutes", "%.2f min"],
	["Boost energy", "journey.plan.energy.boost_j", "sci J"],
	["Brake energy", "journey.plan.energy.brake_j", "sci J"],
	["Drag energy", "journey.plan.energy.drag_j", "sci J"],
	["Total radiated", "journey.plan.energy.total_j", "sci J"],
	["Total as mass", "journey.plan.energy.total_kg", "%.3f kg"],
	["ISM load", "journey.plan.ism.load_w_m2", "sci W/m2"],
	["Glow, inward", "journey.plan.ism.glow_w_m2", "sci W/m2"],
	["Drag force", "journey.plan.ism.drag_n", "sci N"],
	["Hold power", "journey.plan.ism.hold_w", "sci W"],
	["Forward CMB", "journey.plan.cmb_forward_k", "%.2f K"],
	["Profile", "journey.plan.profile", "%s"],
]

var sim: SimBridge
var auto_tick := true
var catalogue: Array = [] # parsed stars.json dictionaries (float64 x, y, z)
var phi_min := 0.0
var phi_max := 0.0
var phi_default := 0.0
var cruise_phi := 0.0
var selected_index := -1

var camera := Camera3D.new()
var slider := HSlider.new()
var pivot := Vector3.ZERO
var yaw := 0.6
var pitch := -0.45
var dist := 18.0

var _points := MultiMeshInstance3D.new()
var _overlay := Control.new()
var _title := Label.new()
var _status := Label.new()
var _clock := Label.new()
var _grid := GridContainer.new()
var _speed := Label.new()
var _pending: Dictionary = {}
var _accum := 0.0
var _drag_from := Vector2.ZERO
var _dragging := false
var _built := false


func _ready() -> void:
	_build()


func _build() -> void:
	if _built:
		return
	_built = true
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.01, 0.012, 0.02)
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	camera.near = 0.05
	camera.far = 2000.0
	camera.fov = 60.0
	add_child(camera)
	camera.current = true
	add_child(_points)
	var layer := CanvasLayer.new()
	add_child(layer)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.draw.connect(_draw_overlay)
	layer.add_child(_overlay)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	panel.offset_left = -PANEL_WIDTH
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.06, 0.09, 0.92)
	style.set_content_margin_all(14)
	panel.add_theme_stylebox_override("panel", style)
	layer.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	_title.add_theme_font_size_override("font_size", 20)
	_title.text = "Select a star"
	for l in [_title, _status, _clock]:
		box.add_child(l)
	_grid.columns = 2
	_grid.add_theme_constant_override("h_separation", 14)
	box.add_child(_grid)
	box.add_child(HSeparator.new())
	box.add_child(_speed)
	slider.step = 0.0
	slider.custom_minimum_size = Vector2(PANEL_WIDTH - 40, 24)
	slider.value_changed.connect(func(v: float) -> void: set_cruise_phi(v))
	box.add_child(slider)
	var help := Label.new()
	help.text = "Slider: cruise speed, 0.9c to the cap (uniform in rapidity)\nDrag: orbit · wheel: zoom · click: select a star"
	help.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))
	help.add_theme_font_size_override("font_size", 13)
	box.add_child(help)
	_update_camera()


## Catalogue as parsed dictionaries; positions stay float64 for the sim. The
## point cloud is drawn from float32 copies (drawing only).
func load_catalogue(path: String) -> void:
	_build()
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	catalogue = data["stars"]
	var quad := QuadMesh.new()
	var mat := ShaderMaterial.new()
	mat.shader = STAR_SHADER
	quad.material = mat
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = quad
	mm.instance_count = catalogue.size()
	for i in catalogue.size():
		var s: Dictionary = catalogue[i]
		var rgb := Blackbody.rgb_unit_luminance(Relativity.temperature_for_class(s["spectral"]))
		rgb /= maxf(rgb.x, maxf(rgb.y, rgb.z))
		var px := clampf(5.5 - 0.3 * float(s["vmag"]), 1.3, 6.0)
		var glow := clampf(0.95 - 0.04 * float(s["vmag"]), 0.3, 0.95)
		mm.set_instance_transform(i, Transform3D(Basis(), world_pos(i)))
		mm.set_instance_custom_data(i, Color(rgb.x * glow, rgb.y * glow, rgb.z * glow, px))
	_points.multimesh = mm
	_points.extra_cull_margin = 16384.0


## Read the slider's range from the sim's `params` echo (first full state).
## The bounds use the same expressions as sunholo/relativity's
## rapidityOfBeta / rapidityOfOneMinusBeta, so the slider ends are exactly the
## sim's accepted ends (tests/test_galaxy_map.gd probes one ulp past each).
func attach(bridge: SimBridge) -> void:
	_build()
	sim = bridge
	var params: Dictionary = sim.world["params"]
	phi_min = rapidity_of_beta(params["cruise_min_beta"])
	var e: float = params["cap_one_minus_beta"]
	phi_max = 0.5 * (log(2.0 - e) - log(e))
	phi_default = clampf(rapidity_of_beta(DEFAULT_BETA), phi_min, phi_max)
	slider.min_value = phi_min
	slider.max_value = phi_max
	set_cruise_phi(phi_default)
	refresh()


## Rapidity of a speed well below c (the slider's lower bound and default only).
static func rapidity_of_beta(b: float) -> float:
	return 0.5 * log((1.0 + b) / (1.0 - b))


func world_pos(i: int) -> Vector3:
	var s: Dictionary = catalogue[i]
	return Starfield.galactic_to_world(Vector3(s["x"], s["y"], s["z"]))


func plan_intent(i: int) -> Dictionary:
	var s: Dictionary = catalogue[i]
	return {"k": "plan", "target": {"index": i, "id": s["id"], "pos": {"x": s["x"], "y": s["y"], "z": s["z"]}}, "cruise_phi": cruise_phi}


## The player picked star i: plan it on the next tick and tell listeners.
func select(i: int) -> bool:
	if not preselect(i):
		return false
	target_selected.emit(catalogue[i]["id"])
	return true


## Select star i without emitting target_selected (a caller opening the map
## on a known star, M4).
func preselect(i: int) -> bool:
	if i < 0 or i >= catalogue.size():
		return false
	selected_index = i
	_pending = plan_intent(i)
	_overlay.queue_redraw()
	return true


## Plan an arbitrary target (design check rows; not a catalogue selection).
func plan_target(target: Dictionary) -> void:
	_pending = {"k": "plan", "target": target, "cruise_phi": cruise_phi}


## clamp=false sends phi as given (tests probe the sim's bounds with it).
func set_cruise_phi(phi: float, clamp: bool = true) -> void:
	cruise_phi = clampf(phi, phi_min, phi_max) if clamp else phi
	slider.set_value_no_signal(cruise_phi)
	if selected_index >= 0:
		_pending = plan_intent(selected_index)


## One sim tick at the fixed host rate, carrying any pending plan.
func tick() -> bool:
	if sim == null:
		return false
	var intents := [] if _pending.is_empty() else [_pending]
	_pending = {}
	var sent := sim.send(intents, HOST_DTAU)
	refresh()
	return sent


func _process(delta: float) -> void:
	if not auto_tick or sim == null:
		return
	_accum = minf(_accum + delta, 4.0 / TICK_HZ)
	while _accum >= 1.0 / TICK_HZ:
		_accum -= 1.0 / TICK_HZ
		tick()
	_overlay.queue_redraw()


## Value of a dotted sim field ("journey.plan.energy.total_j") in a world.
static func field_value(world: Dictionary, field: String) -> Variant:
	var v: Variant = world
	for k in field.split("."):
		if typeof(v) != TYPE_DICTIONARY or not v.has(k):
			return null
		v = v[k]
	return v


static func format_row(field: String, raw: Variant) -> String:
	for r in ROWS:
		if r[1] == field:
			var f: String = r[2]
			if f.begins_with("sci"):
				return (sci(raw) + f.substr(3)).strip_edges()
			return f % raw
	return str(raw)


## Four significant figures: plain between 10^-4 and 10^4, else scientific
## notation (GDScript's % has no %e or %g).
static func sci(x: float) -> String:
	if x == 0.0 or not is_finite(x):
		return str(x)
	var e := int(floor(log(absf(x)) / log(10.0)))
	var m := x / pow(10.0, e)
	if absf(m) < 1.0:
		m *= 10.0
		e -= 1
	if absf(m) >= 9.9995:
		m /= 10.0
		e += 1
	if e >= -4 and e < 4:
		return "%.*f" % [3 - e, x]
	return "%.3fe%d" % [m, e]


## Panel rows for the current plan: {label, field, raw, text}. Empty with no plan.
func panel_rows() -> Array:
	var out := []
	if sim == null or field_value(sim.world, "journey.plan") == null:
		return out
	for r in ROWS:
		var raw = field_value(sim.world, r[1])
		out.append({"label": r[0], "field": r[1], "raw": raw, "text": format_row(r[1], raw)})
	return out


static func speed_label(plan: Dictionary) -> String:
	return "Cruise %.6fc  ·  gamma %.4f" % [plan["cruise_beta"], plan["cruise_gamma"]]


func speed_text() -> String:
	var plan = field_value(sim.world, "journey.plan") if sim != null else null
	return speed_label(plan) if plan != null else "Cruise speed: select a star to see the sim's value"


func status_text() -> String:
	if sim == null:
		return "no sim"
	if sim.world.get("status", "ok") != "ok":
		return "sim stopped: %s" % sim.last_error
	var s := "journey: %s" % field_value(sim.world, "journey.state")
	if not sim.last_refused.is_empty():
		s += "  ·  refused: %s" % ", ".join(sim.last_refused.map(func(r): return str(r["reason"])))
	if field_value(sim.world, "journey.plan.fell_back") == true:
		s += "  ·  fell back to flip-and-burn"
	return s


func refresh() -> void:
	if sim == null:
		return
	var plan = field_value(sim.world, "journey.plan")
	if plan != null:
		var t: Dictionary = plan["target"]
		_title.text = "%s  (catalogue #%d)" % [t["id"], t["index"]]
	_status.text = status_text()
	var c = field_value(sim.world, "clock")
	if c != null:
		_clock.text = "Now: Earth +%.4f yr  ·  ship +%.4f yr  ·  tick %d" % [c["year"], c["tau"], sim.world["tick"]]
	var rows := panel_rows()
	while _grid.get_child_count() < rows.size() * 2:
		var l := Label.new()
		l.add_theme_font_size_override("font_size", 15)
		_grid.add_child(l)
	for i in _grid.get_child_count():
		var l: Label = _grid.get_child(i)
		var r: Dictionary = rows[i / 2] if i / 2 < rows.size() else {}
		l.text = "" if r.is_empty() else (r["label"] if i % 2 == 0 else r["text"])
		if i % 2 == 0:
			l.add_theme_color_override("font_color", Color(0.85, 0.75, 0.4) if i < 4 else Color(0.65, 0.7, 0.8))
	_speed.text = speed_text()


# ---------------------------------------------------------------- camera, picking, overlay

func _update_camera() -> void:
	var off := Vector3(sin(yaw) * cos(pitch), -sin(pitch), cos(yaw) * cos(pitch)) * dist
	camera.look_at_from_position(pivot + off, pivot, Vector3.UP)


## Frame star i and Sol together.
func frame_star(i: int) -> void:
	var p := world_pos(i)
	pivot = p * 0.5
	dist = maxf(10.0, p.length() * 2.5)
	_update_camera()


func screen_position(i: int) -> Vector2:
	return camera.unproject_position(world_pos(i))


func pick(click: Vector2) -> int:
	var pts := PackedVector2Array()
	pts.resize(catalogue.size())
	for i in catalogue.size():
		var p := world_pos(i)
		pts[i] = Vector2(INF, INF) if camera.is_position_behind(p) else camera.unproject_position(p)
	return nearest_index(pts, click, PICK_RADIUS_PX)


static func nearest_index(pts: PackedVector2Array, click: Vector2, radius: float) -> int:
	var best := -1
	var best_d := radius
	for i in pts.size():
		var d := pts[i].distance_to(click)
		if d <= best_d:
			best = i
			best_d = d
	return best


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			dist = maxf(2.0, dist * 0.9)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			dist = minf(400.0, dist / 0.9)
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_drag_from = mb.position
				_dragging = false
			elif not _dragging:
				var hit := pick(mb.position)
				if hit >= 0:
					select(hit)
		_update_camera()
	elif event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT):
		var mm := event as InputEventMouseMotion
		if mm.position.distance_to(_drag_from) > 4.0:
			_dragging = true
		yaw -= mm.relative.x * 0.006
		pitch = clampf(pitch + mm.relative.y * 0.006, -1.5, 1.5)
		_update_camera()


func _draw_overlay() -> void:
	var font := ThemeDB.fallback_font
	var faint := Color(0.35, 0.45, 0.6, 0.35)
	for r: float in RINGS_LY: # scale rings in the galactic plane around Sol
		var pts := PackedVector2Array()
		var visible := true
		for k in 97:
			var a := TAU * k / 96.0
			var w := Starfield.galactic_to_world(Vector3(cos(a) * r, sin(a) * r, 0.0))
			if camera.is_position_behind(w):
				visible = false
				break
			pts.append(camera.unproject_position(w))
		if visible:
			_overlay.draw_polyline(pts, faint, 1.0, true)
			var view := Rect2(Vector2(8, 8), _overlay.size - Vector2(PANEL_WIDTH + 60, 24))
			var at := Vector2(-1, -1)
			for p in pts: # label at the lowest on-screen point of the ring
				if view.has_point(p) and p.y > at.y:
					at = p
			if at.y >= 0.0:
				_overlay.draw_string(font, at + Vector2(4, -4), "%d ly" % int(r), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.5, 0.6, 0.8, 0.8))
	if not camera.is_position_behind(Vector3.ZERO):
		var sol := camera.unproject_position(Vector3.ZERO)
		_overlay.draw_circle(sol, 4.0, Color(1.0, 0.9, 0.5))
		_overlay.draw_string(font, sol + Vector2(8, -6), "Sol", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1.0, 0.9, 0.5))
	if selected_index >= 0 and not camera.is_position_behind(world_pos(selected_index)):
		var sp := screen_position(selected_index)
		if not camera.is_position_behind(Vector3.ZERO):
			_overlay.draw_dashed_line(camera.unproject_position(Vector3.ZERO), sp, Color(0.5, 0.85, 1.0, 0.7), 1.5, 6.0)
		_overlay.draw_arc(sp, 11.0, 0.0, TAU, 40, Color(0.5, 0.85, 1.0), 2.0, true)
		_overlay.draw_string(font, sp + Vector2(14, 18), String(catalogue[selected_index]["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.6, 0.9, 1.0))
