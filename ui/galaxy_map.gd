class_name GalaxyMap
extends Node3D
## Galaxy map, plan panel, commit ritual and transit readout (design
## m2-journey-core §M2.6, sprints M2.6a and M2.6b).
##
## Pick a star, choose a cruise speed, read the sim's plan, commit, watch the
## transit. The map has no physics: every number shown is a sim field
## (`journey`, `clock`, `ship`, `ledger`, `params`) and Godot only formats it.
## Selection sends `plan` with the star's catalogue index, id and float64
## position taken from the parsed JSON dictionary (never from a Vector3),
## plus the slider's rapidity. The catalogue (M1.7, Q7) is the quick + bright
## tier rows within 25 pc; ids are stable ("Gaia DR3 n", "CNS5:n", "HIP n"), one
## per star, so alpha Cen A (CNS5:3627) and B (HIP 71681) are two rows.
##
## The slider is linear in rapidity between the bounds the sim echoes in
## `params` (cruise_phi_min/max; default cruise_phi_default = 0.99c, D-14).
## At rest the clock runs at a fixed host rate and never pauses (D-12).
## Commit is one dialog with both clocks and the years left, sent only after a
## 1.5 s hold (D-12). After the commit the Cancel button stays enabled: the
## sim, not the UI, refuses it (`committed`) and the panel shows the refusal.
## Star names come from data/starmap/names.json (D-17), keyed by catalogue id;
## the subtitle is the catalogue id and the catalogue's own distance.
## Mouse: drag to orbit, wheel to zoom, click a star to select it.
## Trackpad: pinch (InputEventMagnifyGesture) or two-finger scroll
## (InputEventPanGesture, one unit of delta.y = one wheel notch, same
## direction) zooms; two-finger scroll never orbits. Keys + / = and - zoom by
## one notch. Cmd/Ctrl with those keys is the window's UI zoom (UiScale), not
## the camera.

signal target_selected(star_id: String)

const STAR_SHADER := preload("res://ui/star_point.gdshader")
const TICK_HZ := 20.0
## Fixed host clock rate at rest (D-12): one ship-day per real second.
const HOST_RATE := 1.0 / 365.25
const HOST_DTAU := HOST_RATE / TICK_HZ
## Ship-years per real second while committed (transit is not planning; D-12
## fixes the rate at rest). Alpha Cen at 0.99c takes about 6 s.
const TRANSIT_RATE := 0.1
const TRANSIT_DTAU := TRANSIT_RATE / TICK_HZ
## Commit hold (D-12): the commit is sent only after the button has been held
## this long without release.
const HOLD_S := 1.5
## Largest frame delta one frame may add to the hold, so a frame stall
## (>= HOLD_S) cannot commit in a single frame.
const MAX_HOLD_DT := 0.1
const PICK_RADIUS_PX := 12.0
const NAME_SPACING_PX := 16.0
const RINGS_LY := [5.0, 10.0, 20.0, 50.0]
const PANEL_WIDTH := 430
## Camera distance limits and one zoom notch (wheel, key, pan-gesture unit).
const DIST_MIN := 2.0
const DIST_MAX := 400.0
const ZOOM_NOTCH := 0.9

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
## The commit dialog (D-12): both clocks and the years left at home.
const COMMIT_ROWS := [
	["Ship time (you)", "journey.plan.ship_years", "sci ship-yr"],
	["Earth time (home)", "journey.plan.earth_years", "%.3f Earth-yr"],
	["Arrival", "journey.plan.arrive_year", "Earth +%.3f yr"],
	["Years left (placeholder)", "journey.plan.years_left", "%.2f yr"],
]
## Transit readout while committed: phase, both clocks advancing, progress.
const TRANSIT_ROWS := [
	["Phase", "ship.phase", "%s"],
	["Ship clock", "clock.tau", "ship +%.4f yr"],
	["Earth clock", "clock.year", "Earth +%.4f yr"],
	["Crew age (placeholder)", "clock.age", "%.2f yr"],
	["Flown since commit", "ship.flown", "%.4f ly"],
	["Distance", "journey.plan.distance", "%.3f ly"],
	["Speed", "ship.beta", "%.6fc"],
	["1 - beta", "ship.one_minus_beta", "sci"],
	["Gamma", "ship.gamma", "%.4f"],
	["Arrives", "journey.plan.arrive_year", "Earth +%.3f yr"],
	["Age on arrival (placeholder)", "journey.plan.age_on_arrival", "%.2f yr"],
	["Radiated so far", "ledger.radiated_j", "sci J"],
	["Trip total (plan)", "journey.plan.energy.total_j", "sci J"],
]
## After arrival the sim rebases the line of motion at the target, so
## ship.flown is 0 again: the readout shows the plan distance (the sim snapped
## the ship onto the target) and the ship marker is drawn from ship.pos.
const ARRIVED_ROWS := [
	["Phase", "ship.phase", "%s"],
	["Ship clock", "clock.tau", "ship +%.4f yr"],
	["Earth clock", "clock.year", "Earth +%.4f yr"],
	["Crew age (placeholder)", "clock.age", "%.2f yr"],
	["Flown (arrived)", "journey.plan.distance", "%.3f ly"],
	["Arrived", "journey.plan.arrive_year", "Earth +%.3f yr"],
	["Radiated, whole trip", "ledger.radiated_j", "sci J"],
	["Trip total (plan)", "journey.plan.energy.total_j", "sci J"],
]

var sim: SimBridge
var auto_tick := true
var live_pacing := false # explicit opt-in; golden/replay capture inputs stay fixed
var pacing := preload("res://ui/journey_pacing.gd").new()
var catalogue: Array = [] # parsed stars.json dictionaries (float64 x, y, z)
var index_by_id: Dictionary = {} # catalogue id -> index (ids are unique, M1.7)
var names: Dictionary = {} # catalogue index -> common name (names.json rows are keyed by id, D-17)
var name_mismatches := 0 # names.json rows whose id is not in the catalogue
var phi_min := 0.0
var phi_max := 0.0
var phi_default := 0.0
var cruise_phi := 0.0
var selected_index := -1

var camera := Camera3D.new()
var slider := HSlider.new()
var commit_button := Button.new()
var cancel_button := Button.new()
var progress_bar := ProgressBar.new()
var dialog := PanelContainer.new()
var dialog_title := Label.new()
var dialog_grid := GridContainer.new()
var hold_button := Button.new()
var hold_bar := ProgressBar.new()
var back_button := Button.new()
var dialog_plan_id := -1
var hold_s := 0.0
var pivot := Vector3.ZERO
var yaw := 0.6
var pitch := -0.45
var dist := 18.0
## The footer's controls hint. Captures set this false before the map enters
## the tree so the committed capture PNGs do not change.
var show_hint := true
var hint := Label.new()
var credits := Credits.new() # M5.2a: attribution panel (C)

var _points := MultiMeshInstance3D.new()
var _overlay := Control.new()
var _title := Label.new()
var _subtitle := Label.new()
var _status := Label.new()
var _clock := Label.new()
var _grid := GridContainer.new()
var _speed := Label.new()
var _pending: Dictionary = {}
var _queue: Array = [] # commit / cancel intents for the next tick
var _refusal_note := "" # the sim's refusal of the last player intent (sticky)
var _holding := false
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
	_subtitle.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))
	_subtitle.add_theme_font_size_override("font_size", 13)
	for l in [_title, _subtitle, _status, _clock]:
		box.add_child(l)
	progress_bar.show_percentage = false
	progress_bar.step = 0.0
	_bar_style(progress_bar, Color(1.0, 0.6, 0.35))
	progress_bar.custom_minimum_size = Vector2(PANEL_WIDTH - 40, 10)
	progress_bar.visible = false
	box.add_child(progress_bar)
	_grid.columns = 2
	_grid.add_theme_constant_override("h_separation", 14)
	if live_pacing:
		var scroll:=ScrollContainer.new()
		scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
		scroll.custom_minimum_size.y=80
		scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
		_grid.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		box.add_child(scroll);scroll.add_child(_grid)
	else:box.add_child(_grid)
	box.add_child(HSeparator.new())
	box.add_child(_speed)
	slider.step = 0.0
	slider.custom_minimum_size = Vector2(PANEL_WIDTH - 40, 24)
	slider.value_changed.connect(func(v: float) -> void: set_cruise_phi(v))
	var track := StyleBoxFlat.new() # M2.6a eval: the default track was too faint
	track.bg_color = Color(0.34, 0.4, 0.52)
	track.set_content_margin_all(3)
	track.set_corner_radius_all(3)
	var filled: StyleBoxFlat = track.duplicate()
	filled.bg_color = Color(0.45, 0.75, 0.95)
	slider.add_theme_stylebox_override("slider", track)
	slider.add_theme_stylebox_override("grabber_area", filled)
	slider.add_theme_stylebox_override("grabber_area_highlight", filled)
	box.add_child(slider)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 10)
	commit_button.text = "Commit..."
	commit_button.disabled = true
	commit_button.pressed.connect(func() -> void: open_commit_dialog())
	cancel_button.text = "Cancel"
	cancel_button.pressed.connect(func() -> void: press_cancel())
	buttons.add_child(commit_button)
	buttons.add_child(cancel_button)
	box.add_child(buttons)
	var help := Label.new()
	help.text = "Slider: cruise speed, 0.9c to the cap (uniform in rapidity)\nDrag: orbit · wheel: zoom · click: select a star"
	help.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))
	help.add_theme_font_size_override("font_size", 13)
	box.add_child(help)
	hint.text = "Pinch or scroll to zoom · drag to orbit · %s+/− UI size" % ("⌘" if OS.get_name() == "macOS" else "Ctrl ")
	hint.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))
	hint.add_theme_font_size_override("font_size", 13)
	hint.visible = show_hint
	box.add_child(hint)
	_build_dialog(layer)
	credits.visible = show_hint # captures keep their pinned PNGs; C still toggles the panel in play
	layer.add_child(credits)
	_update_camera()


static func _bar_style(bar: ProgressBar, fill: Color) -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.2, 0.23, 0.3)
	bg.set_corner_radius_all(3)
	var fg: StyleBoxFlat = bg.duplicate()
	fg.bg_color = fill
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fg)


## The commit dialog (D-12), centred over the map: both clocks and the years
## left, a hold-to-commit button with its progress, and Back.
func _build_dialog(layer: CanvasLayer) -> void:
	dialog.visible = false
	dialog.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	dialog.offset_left = 60.0
	dialog.offset_top = -170.0
	dialog.custom_minimum_size = Vector2(460, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.08, 0.12, 0.97)
	style.border_color = Color(0.9, 0.75, 0.35)
	style.set_border_width_all(2)
	style.set_content_margin_all(18)
	dialog.add_theme_stylebox_override("panel", style)
	layer.add_child(dialog)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	dialog.add_child(box)
	dialog_title.add_theme_font_size_override("font_size", 21)
	box.add_child(dialog_title)
	dialog_grid.columns = 2
	dialog_grid.add_theme_constant_override("h_separation", 18)
	for i in COMMIT_ROWS.size() * 2:
		var l := Label.new()
		l.add_theme_font_size_override("font_size", 17)
		if i % 2 == 0:
			l.add_theme_color_override("font_color", Color(0.85, 0.75, 0.4))
		dialog_grid.add_child(l)
	box.add_child(dialog_grid)
	var warn := Label.new()
	warn.text = "A commitment cannot be undone. Hold for %.1f s to commit." % HOLD_S
	warn.add_theme_color_override("font_color", Color(0.95, 0.6, 0.4))
	box.add_child(warn)
	hold_bar.show_percentage = false
	hold_bar.step = 0.0
	_bar_style(hold_bar, Color(0.9, 0.75, 0.35))
	hold_bar.max_value = HOLD_S
	hold_bar.custom_minimum_size = Vector2(0, 12)
	box.add_child(hold_bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	hold_button.text = "Hold to commit"
	hold_button.button_down.connect(func() -> void: _holding = true)
	hold_button.button_up.connect(func() -> void: release_commit())
	back_button.text = "Back"
	back_button.pressed.connect(func() -> void: close_commit_dialog())
	row.add_child(hold_button)
	row.add_child(back_button)
	box.add_child(row)


## Catalogue as parsed dictionaries; positions stay float64 for the sim. The
## point cloud is drawn from float32 copies (drawing only).
func load_catalogue(path: String) -> void:
	_build()
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	catalogue = data["stars"]
	index_by_id.clear()
	for i in catalogue.size():
		index_by_id[String(catalogue[i]["id"])] = i
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
		var rgb := Blackbody.rgb_unit_luminance(point_teff(s))
		rgb /= maxf(rgb.x, maxf(rgb.y, rgb.z))
		var px := clampf(5.5 - 0.3 * float(s["vmag"]), 1.3, 6.0) # V 99 (no photometry): the smallest point
		var glow := clampf(0.95 - 0.04 * float(s["vmag"]), 0.3, 0.95)
		mm.set_instance_transform(i, Transform3D(Basis(), world_pos(i)))
		mm.set_instance_custom_data(i, Color(rgb.x * glow, rgb.y * glow, rgb.z * glow, px))
	_points.multimesh = mm
	_points.extra_cull_margin = 16384.0


## Point colour (drawing only): the catalogue teff, or a neutral 4,000 K for a
## row without photometry (teff 0, flags bit 2).
static func point_teff(s: Dictionary) -> float:
	var t := float(s.get("teff", 0.0))
	return t if t > 0.0 else 4000.0


## The index of catalogue id `id`, or -1.
func index_of(id: String) -> int:
	return index_by_id.get(id, -1)


## Common names (D-17): rows keyed by catalogue id (M1.7); a row whose id is
## not in the catalogue, or names an id twice, is ignored and counted.
## Returns the number of names loaded.
func load_names(path: String) -> int:
	names.clear()
	name_mismatches = 0
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(data) != TYPE_DICTIONARY:
		return 0
	for r: Dictionary in data.get("names", []):
		var i := index_of(String(r.get("id", "")))
		if i >= 0 and not names.has(i):
			names[i] = String(r["name"])
		else:
			name_mismatches += 1
	_overlay.queue_redraw()
	return names.size()


## The common name if the table has one, else the catalogue id.
func display_name(i: int) -> String:
	if i < 0 or i >= catalogue.size():
		return ""
	return names.get(i, String(catalogue[i]["id"]))


## Slider range and default straight from the sim's `params` echo (first full
## state): the planner's own accepted bounds, so Godot does no rapidity maths
## (tests/test_galaxy_map.gd probes one ulp past each end).
func attach(bridge: SimBridge) -> void:
	_build()
	sim = bridge
	var params: Dictionary = sim.world["params"]
	phi_min = params["cruise_phi_min"]
	phi_max = params["cruise_phi_max"]
	phi_default = params["cruise_phi_default"]
	slider.min_value = phi_min
	slider.max_value = phi_max
	set_cruise_phi(phi_default)
	refresh()


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


func journey_state() -> String:
	var s = field_value(sim.world, "journey.state") if sim != null else null
	return s if s != null else ""


func in_transit() -> bool:
	return journey_state() in ["committed", "arrived"]


## Open the commit dialog on the sim's current plan. Nothing is sent.
func open_commit_dialog() -> bool:
	if journey_state() != "planned" or field_value(sim.world, "journey.plan") == null:
		return false
	dialog_plan_id = int(sim.world["journey"]["plan_id"])
	release_commit()
	dialog.visible = true
	refresh()
	return true


func close_commit_dialog() -> void:
	dialog.visible = false
	release_commit()


## Accumulate hold time (real or fake clock). At HOLD_S the commit for the
## plan shown is queued for the next tick and the dialog closes; true then.
func hold_commit(delta: float) -> bool:
	if not dialog.visible:
		return false
	hold_s += delta
	hold_bar.value = minf(hold_s, HOLD_S)
	if hold_s < HOLD_S:
		return false
	_queue.append({"k": "commit", "plan_id": dialog_plan_id})
	close_commit_dialog()
	return true


## Releasing the button before HOLD_S starts the hold over.
func release_commit() -> void:
	_holding = false
	hold_s = 0.0
	hold_bar.value = 0.0


## Cancel is always available. Before a commit the sim clears the plan; after
## it the sim refuses (`committed`) and the panel shows that refusal.
func press_cancel() -> void:
	close_commit_dialog()
	_queue.append({"k": "cancel"})


## One sim tick carrying any pending plan, commit or cancel: at the fixed host
## rate at rest (D-12), at TRANSIT_RATE while committed.
func tick() -> bool:
	if sim == null:
		return false
	var intents := ([] if _pending.is_empty() else [_pending]) + _queue
	_pending = {}
	_queue = []
	var state := journey_state()
	var dtau := TRANSIT_DTAU if state == "committed" else HOST_DTAU
	if live_pacing:
		var committing := intents.any(func(i): return i.get("k", "") == "commit")
		dtau = pacing.step(sim.world, committing, HOST_DTAU, TICK_HZ)
	var sent := sim.send(intents, dtau)
	if sent and not intents.is_empty():
		_refusal_note = "" if sim.last_refused.is_empty() else "refused: %s" % ", ".join(sim.last_refused.map(func(r): return str(r["reason"])))
	elif sent and journey_state() != state:
		_refusal_note = "" # a new journey state (arrival) supersedes the old refusal
	if live_pacing and journey_state() != "committed":pacing.rate = HOST_RATE
	refresh()
	return sent


func _process(delta: float) -> void:
	if _holding:
		hold_commit(minf(delta, MAX_HOLD_DT))
	if not auto_tick or sim == null:
		return
	_accum = minf(_accum + delta, 4.0 / TICK_HZ)
	while _accum >= 1.0 / TICK_HZ:
		_accum -= 1.0 / TICK_HZ
		tick()
	_overlay.queue_redraw()


## Losing window focus releases the hold (the button-up may never arrive).
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		release_commit()


## Value of a dotted sim field ("journey.plan.energy.total_j") in a world.
static func field_value(world: Dictionary, field: String) -> Variant:
	var v: Variant = world
	for k in field.split("."):
		if typeof(v) != TYPE_DICTIONARY or not v.has(k):
			return null
		v = v[k]
	return v


static func format_row(field: String, raw: Variant) -> String:
	for table in [ROWS, COMMIT_ROWS, TRANSIT_ROWS]:
		for r in table:
			if r[1] == field:
				return format_value(r[2], raw)
	return str(raw)


static func format_value(f: String, raw: Variant) -> String:
	if raw == null:
		return "-"
	if f.begins_with("sci"):
		return (sci(raw) + f.substr(3)).strip_edges()
	return f % raw


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


## Rows of a table against the mirrored world: {label, field, raw, text}.
func rows_of(table: Array) -> Array:
	var out := []
	for r in table:
		var raw = field_value(sim.world, r[1])
		out.append({"label": r[0], "field": r[1], "raw": raw, "text": format_value(r[2], raw)})
	return out


## Panel rows: the plan while planning, the transit readout once committed,
## the arrival readout after. Empty with no plan.
func panel_rows() -> Array:
	if sim == null or field_value(sim.world, "journey.plan") == null:
		return []
	match journey_state():
		"committed":
			return rows_of(TRANSIT_ROWS)
		"arrived":
			return rows_of(ARRIVED_ROWS)
	return rows_of(ROWS)


func dialog_rows() -> Array:
	return rows_of(COMMIT_ROWS) if sim != null and field_value(sim.world, "journey.plan") != null else []


## The planned target's common name (its catalogue id if unnamed or if the
## plan's id is not that catalogue entry's).
func target_name() -> String:
	var t = field_value(sim.world, "journey.plan.target") if sim != null else null
	if t == null:
		return ""
	var i := int(t["index"])
	if i >= 0 and i < catalogue.size() and catalogue[i]["id"] == t["id"]:
		return display_name(i)
	return String(t["id"])


func title_text() -> String:
	if target_name() == "":
		return "Select a star"
	match journey_state():
		"committed":
			return "En route to %s" % target_name()
		"arrived":
			return "Arrived at %s" % target_name()
	return target_name()


## Under the name: the catalogue id and the catalogue's own distance (D-17),
## from stars.json (the panel's distance row is the sim's plan distance).
func subtitle_text() -> String:
	var t = field_value(sim.world, "journey.plan.target") if sim != null else null
	if t == null:
		return ""
	var i := int(t["index"])
	if i >= 0 and i < catalogue.size() and catalogue[i]["id"] == t["id"]:
		return preload("res://ui/star_info.gd").catalogue_subtitle(catalogue[i])
	return String(t["id"])


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
	if _refusal_note != "":
		s += "  ·  " + _refusal_note
	if field_value(sim.world, "journey.plan.fell_back") == true:
		s += "  ·  fell back to flip-and-burn"
	return s


## Progress bar: the sim's distance flown against the plan distance (the
## widget draws the ratio; nothing is computed here). Full once arrived.
func progress_values() -> Array:
	var plan = field_value(sim.world, "journey.plan")
	if plan == null or not in_transit():
		return []
	return [plan["distance"] if journey_state() == "arrived" else sim.world["ship"]["flown"], plan["distance"]]


func refresh() -> void:
	if sim == null:
		return
	_title.text = title_text()
	_subtitle.text = subtitle_text()
	_status.text = status_text()
	commit_button.disabled = journey_state() != "planned"
	var pv := progress_values()
	progress_bar.visible = not pv.is_empty()
	if not pv.is_empty():
		progress_bar.max_value = pv[1]
		progress_bar.value = pv[0]
	var c = field_value(sim.world, "clock")
	if c != null:
		_clock.text = "Now: Earth +%.4f yr  ·  ship +%.4f yr  ·  tick %d" % [c["year"], c["tau"], sim.world["tick"]]
		if live_pacing:_clock.text += "\nVariable time compression · %s ship-yr/real-s" % sci(pacing.rate)
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
	if dialog.visible:
		dialog_title.text = "Commit to %s?" % target_name()
		var drows := dialog_rows()
		for i in dialog_grid.get_child_count():
			var l: Label = dialog_grid.get_child(i)
			l.text = drows[i / 2]["label"] if i % 2 == 0 else drows[i / 2]["text"]
	_overlay.queue_redraw()


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


## The ship marker's world position: the sim's ship.pos (drawing only).
func ship_world_pos() -> Variant:
	var p = field_value(sim.world, "ship.pos") if sim != null else null
	return null if p == null else Starfield.galactic_to_world(Vector3(p["x"], p["y"], p["z"]))


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


## Scale the camera distance by `factor` (< 1 zooms in), clamped to
## [DIST_MIN, DIST_MAX] like the wheel.
func zoom_by(factor: float) -> void:
	if factor > 0.0 and is_finite(factor):
		dist = clampf(dist * factor, DIST_MIN, DIST_MAX)
	_update_camera()


## One wheel notch: in (dist * 0.9) or out (dist / 0.9), as the wheel does.
func zoom_notch(zoom_in: bool) -> void:
	dist = maxf(DIST_MIN, dist * ZOOM_NOTCH) if zoom_in else minf(DIST_MAX, dist / ZOOM_NOTCH)
	_update_camera()


## +1 / -1 for a plain + / = / - (or keypad) press, else 0. With Cmd/Ctrl the
## keys belong to the UI zoom (UiScale) and the camera leaves them alone.
static func zoom_key(event: InputEvent) -> int:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.is_command_or_control_pressed() or k.ctrl_pressed or k.meta_pressed or k.alt_pressed:
		return 0
	match k.keycode:
		KEY_EQUAL, KEY_PLUS, KEY_KP_ADD:
			return 1
		KEY_MINUS, KEY_KP_SUBTRACT:
			return -1
	return 0


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMagnifyGesture: # pinch: factor > 1 (fingers apart) zooms in
		zoom_by(1.0 / (event as InputEventMagnifyGesture).factor)
		_accept()
		return
	if event is InputEventPanGesture: # two-finger scroll: zoom only, never orbit
		zoom_by(pow(1.0 / ZOOM_NOTCH, (event as InputEventPanGesture).delta.y))
		_accept()
		return
	var zk := zoom_key(event)
	if zk != 0:
		zoom_notch(zk > 0)
		_accept()
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			dist = maxf(DIST_MIN, dist * ZOOM_NOTCH)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			dist = minf(DIST_MAX, dist / ZOOM_NOTCH)
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


func _accept() -> void:
	if is_inside_tree():
		get_viewport().set_input_as_handled()


## The screen box of a string drawn at baseline `at` (draw_string's origin), for label overlap tests.
static func label_box(font: Font, at: Vector2, text: String, size: int) -> Rect2:
	var sz := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	return Rect2(at - Vector2(0, font.get_ascent(size)), sz)


func _draw_overlay() -> void:
	var font := ThemeDB.fallback_font
	var faint := Color(0.35, 0.45, 0.6, 0.35)
	if _overlay.size.x <= PANEL_WIDTH + 60 or _overlay.size.y <= 24:return
	var view := Rect2(Vector2(8, 8), _overlay.size - Vector2(PANEL_WIDTH + 60, 24))
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
			var at := Vector2(-1, -1)
			for p in pts: # label at the lowest on-screen point of the ring
				if view.has_point(p) and p.y > at.y:
					at = p
			if at.y >= 0.0:
				_overlay.draw_string(font, at + Vector2(4, -4), "%d ly" % int(r), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.5, 0.6, 0.8, 0.8))
	var taken: Array[Vector2] = [] # label spots already used (A/B pairs share a position)
	var boxes: Array[Rect2] = [] # drawn label boxes: a faint name never overlaps one (M1.7 eval: Luyten 726-8 A over Gliese 1)
	if not camera.is_position_behind(Vector3.ZERO):
		var sol := camera.unproject_position(Vector3.ZERO)
		_overlay.draw_circle(sol, 4.0, Color(1.0, 0.9, 0.5))
		_overlay.draw_string(font, sol + Vector2(8, -6), "Sol", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1.0, 0.9, 0.5))
		taken.append(sol)
		boxes.append(label_box(font, sol + Vector2(8, -6), "Sol", 15))
	if selected_index >= 0 and not camera.is_position_behind(world_pos(selected_index)):
		var sp := screen_position(selected_index)
		if not camera.is_position_behind(Vector3.ZERO):
			_overlay.draw_dashed_line(camera.unproject_position(Vector3.ZERO), sp, Color(0.5, 0.85, 1.0, 0.7), 1.5, 6.0)
		_overlay.draw_arc(sp, 11.0, 0.0, TAU, 40, Color(0.5, 0.85, 1.0), 2.0, true)
		_overlay.draw_string(font, sp + Vector2(14, 18), display_name(selected_index), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(0.6, 0.9, 1.0))
		taken.append(sp)
		boxes.append(label_box(font, sp + Vector2(14, 18), display_name(selected_index), 16))
	for i: int in names: # faint names for the other named stars, without overlaps
		var w := world_pos(i)
		if i == selected_index or camera.is_position_behind(w):
			continue
		var p := camera.unproject_position(w)
		var box := label_box(font, p + Vector2(6, -4), names[i], 12)
		if not view.has_point(p) or taken.any(func(q: Vector2) -> bool: return q.distance_to(p) < NAME_SPACING_PX) \
				or boxes.any(func(b: Rect2) -> bool: return b.intersects(box)):
			continue
		_overlay.draw_string(font, p + Vector2(6, -4), names[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.62, 0.68, 0.8, 0.75))
		taken.append(p)
		boxes.append(box)
	var ship = ship_world_pos()
	if in_transit() and ship != null and not camera.is_position_behind(ship):
		var s := camera.unproject_position(ship)
		var diamond := PackedVector2Array([s + Vector2(0, -7), s + Vector2(6, 0), s + Vector2(0, 7), s + Vector2(-6, 0)])
		_overlay.draw_colored_polygon(diamond, Color(1.0, 0.55, 0.3))
		_overlay.draw_string(font, s + Vector2(-38, -8), "ship", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1.0, 0.6, 0.35))
