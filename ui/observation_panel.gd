extends PanelContainer
## One information-only panel, shared by Navigation, chair screens and the chart.
const Cache = preload("res://ui/observation_tiles.gd")
const ProjectionMath = preload("res://physics/observation_projection.gd")
const Facts = preload("res://ui/object_info.gd")
const Live = preload("res://ui/telescope_view.gd")
signal closed
signal open_map(reference: Dictionary)
signal open_field_map(plate_id: String)
var reference: Dictionary = {}
var plate: Dictionary = {}
var index
var catalogue
var world: Dictionary = {}
var system_view
var cache := Cache.new()
var tile_index: Dictionary = {}
var zoom := 1.0
var pan := Vector2.ZERO
var mode := "archive"
var heading := Label.new()
var source_line := Label.new()
var state_line := Label.new()
var detail := RichTextLabel.new()
var image_area := Control.new()
var field_picker := OptionButton.new()
var live_button := Button.new()
var archive_button := Button.new()
var map_button := Button.new()
var live_view := Live.new()
var source_picker := PopupMenu.new()
var _hits: Array = []
var _drag := false
var _dragged := false
var _drag_start := Vector2.ZERO
var session_pack_id := ""
var session_pin: Dictionary = {}
var archive_mismatch := false
var last_error := ""
var show_details := false
var show_sources := false

func _init() -> void:
	name = "Telescope"
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = StapledonTheme.theme()
	theme_type_variation = "HUDSheet"
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Keep the established ink border, with opaque backing so route labels never
	# show through the observation image/facts sheet.
	var backing := ColorRect.new()
	backing.color = StapledonTheme.NIGHT
	backing.mouse_filter = Control.MOUSE_FILTER_IGNORE
	backing.show_behind_parent = true
	add_child(backing)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 14)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)
	var top := HBoxContainer.new()
	column.add_child(top)
	heading.text = "Telescope"
	heading.theme_type_variation = "HUDTitle"
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.clip_text = true
	top.add_child(heading)
	var close := Button.new()
	close.text = "Back [Esc]"
	close.pressed.connect(close_panel)
	top.add_child(close)
	var controls := HFlowContainer.new()
	column.add_child(controls)
	live_button.text = "Live star"
	live_button.pressed.connect(func(): set_mode("live"))
	archive_button.text = "Survey archive"
	archive_button.pressed.connect(func(): set_mode("archive"))
	controls.add_child(live_button); controls.add_child(archive_button)
	field_picker.custom_minimum_size.x = 180
	field_picker.item_selected.connect(func(i): select_plate(str(field_picker.get_item_metadata(i))))
	controls.add_child(field_picker)
	for spec in [["−", 1.0 / 1.5], ["+", 1.5], ["Fit field", 0.0]]:
		var button := Button.new()
		button.text = spec[0]
		button.pressed.connect(func():
			if float(spec[1]) == 0.0: zoom = 1.0; pan = Vector2.ZERO; _update_tiles()
			else: zoom_at(float(spec[1]), image_area.size * 0.5))
		controls.add_child(button)
	map_button.text = "Open in map"
	map_button.pressed.connect(func():
		if not reference.is_empty(): open_map.emit(reference.duplicate(true))
		elif not plate.is_empty() and plate.get("registered", false): open_field_map.emit(str(plate.id)))
	controls.add_child(map_button)
	source_line.theme_type_variation = "HUDHint"
	source_line.clip_text = true
	column.add_child(source_line)
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(row)
	image_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	image_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	image_area.custom_minimum_size = Vector2(180, 150)
	image_area.clip_contents = true
	image_area.mouse_filter = Control.MOUSE_FILTER_STOP
	image_area.focus_mode = Control.FOCUS_ALL
	image_area.draw.connect(_draw_image)
	image_area.gui_input.connect(_image_input)
	image_area.resized.connect(_update_tiles)
	row.add_child(image_area)
	var aside := VBoxContainer.new()
	aside.custom_minimum_size.x = 220
	row.add_child(aside)
	var disclosures := HBoxContainer.new()
	aside.add_child(disclosures)
	for spec in [["Details", "details"], ["Sources", "sources"]]:
		var toggle := CheckButton.new()
		toggle.text = spec[0]
		toggle.name = str(spec[0]) + "Toggle"
		toggle.toggled.connect(func(on):
			if spec[1] == "details": show_details = on
			else: show_sources = on
			_refresh_details())
		disclosures.add_child(toggle)
	detail.custom_minimum_size.x = 220
	detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail.bbcode_enabled = false
	detail.selection_enabled = true
	aside.add_child(detail)
	state_line.theme_type_variation = "HUDHint"
	state_line.clip_text = true
	column.add_child(state_line)
	image_area.add_child(live_view)
	live_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	live_view.hide()
	var disc: Control = live_view.find_child("StellarDisc", true, false)
	if disc != null:
		disc.custom_minimum_size = Vector2(180, 150)
		disc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		disc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		disc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		disc.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(source_picker)
	source_picker.id_pressed.connect(func(i):
		if i >= 0 and i < _hits.size(): select_object(_hits[i].id))
	visibility_changed.connect(func():
		if not is_visible_in_tree(): cache.close(); live_view.set_active(false))

func configure(source_index, star_info = null, snapshot := {}, sv = null, expected_pin: Dictionary = {}) -> bool:
	var candidate: Dictionary = source_index.pin()
	var expected := expected_pin if not expected_pin.is_empty() else (session_pin if not session_pin.is_empty() else candidate)
	var matches := not candidate.is_empty() and candidate == expected and (session_pin.is_empty() or session_pin == candidate)
	if session_pin.is_empty(): session_pin = expected.duplicate(true)
	session_pack_id = str(session_pin.get("id", ""))
	archive_mismatch = not matches
	last_error = "" if matches else "Observation data missing or changed for this session"
	if archive_mismatch: cache.close(); tile_index = {}
	if matches or index == null:
		var isolated: RefCounted = source_index.snapshot()
		index = isolated if isolated != null else source_index
	catalogue = star_info
	update_world(snapshot, sv)
	field_picker.clear()
	field_picker.add_item("Choose survey field…")
	field_picker.set_item_metadata(0, "")
	for id in index.plates:
		field_picker.add_item(str(index.plate(id).get("name", id)))
		field_picker.set_item_metadata(field_picker.item_count - 1, id)
	field_picker.disabled = archive_mismatch
	return matches

func update_world(snapshot: Dictionary, sv = null) -> void:
	world = snapshot
	system_view = sv
	live_view.sv = sv
	if visible:
		if mode == "live": _refresh_live()
		if reference.get("kind") in ["catalogue", "body"]: _refresh_details()

func open_reference(ref: Dictionary, preferred := "") -> bool:
	if index == null: return false
	if not ref.is_empty() and (not ref.get("kind") in ["catalogue","body","survey"] or not ref.get("id") is String or str(ref.id).is_empty()): return false
	reference = ref.duplicate(true)
	plate = {}; tile_index = {}; zoom = 1.0; pan = Vector2.ZERO
	field_picker.select(0)
	cache.close()
	if ref.get("kind") == "survey":
		var object: Dictionary = index.object(str(ref.get("id", "")))
		if not object.is_empty(): _load_plate(str(object.plate_id))
	elif ref.is_empty():
		_load_plate("m81-outreach")
	visible = true
	live_view.level = 1
	var body: Dictionary = Facts.live_body(reference, world, catalogue)
	set_mode(preferred if preferred in ["archive", "live"] else ("live" if not body.is_empty() and body.get("kind") == "star" else "archive"))
	_refresh_details()
	detail.scroll_to_line(0)
	image_area.grab_focus()
	return true

func set_mode(value: String) -> void:
	mode = "live" if value == "live" else "archive"
	live_view.visible = mode == "live"
	live_view.set_active(visible and mode == "live")
	heading.text = "Live stellar telescope" if mode == "live" else "Survey archive · observed near Earth"
	if mode == "live":
		cache.close()
		_refresh_live()
	else:
		_archive_source_line()
		cache.activate(str(index.version) + ":" + str(plate.get("id", "none")))
		_update_tiles()

func _refresh_live() -> void:
	var body: Dictionary = Facts.live_body(reference, world, catalogue)
	live_view.set_target(str(body.get("id", "unavailable:" + str(reference.get("id", "")))) if not reference.is_empty() else "")
	if system_view != null: live_view.refresh(world)
	else: live_view._label.text = "No live resolved view of this object"
	source_line.text = "Live ship-frame stellar model · true angular magnification · surface appearance modelled"
	state_line.text = "T: whole disc / close · recorded survey images are in Survey archive"
	if live_view.field_cropped: state_line.text = "Native field crop · star extends beyond the 14° telescope field · T: close / off"

func select_plate(id: String) -> void:
	if id.is_empty(): return
	reference = {}
	_load_plate(id)
	set_mode("archive")
	_refresh_details()
	detail.scroll_to_line(0)

static func _read_pinned(meta: Dictionary) -> Dictionary:
	var path := str(meta.get("path", ""))
	if not FileAccess.file_exists(path): path = path.replace("res://data/raw/observations/tiles/", "res://observation_bundle/") + ".bin"
	if not FileAccess.file_exists(path): return {}
	var bytes := FileAccess.get_file_as_bytes(path)
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256); hash.update(bytes)
	if hash.finish().hex_encode() != str(meta.get("sha256", "")): return {}
	var data: Variant = JSON.parse_string(bytes.get_string_from_utf8())
	return data if data is Dictionary else {}

func _load_plate(id: String) -> void:
	if archive_mismatch:
		plate = {}; tile_index = {}; cache.close()
		_archive_source_line()
		return
	plate = index.plate(id)
	tile_index = _read_pinned(plate.get("tiles", {}))
	zoom = 1.0; pan = Vector2.ZERO
	for i in field_picker.item_count:
		if field_picker.get_item_metadata(i) == id: field_picker.select(i)
	_archive_source_line()
	cache.activate(str(index.version) + ":" + id)
	_update_tiles()

func _archive_source_line() -> void:
	if archive_mismatch:
		source_line.text = last_error
		return
	source_line.text = "%s · %s · %s" % [plate.get("name", "No survey image"), plate.get("band", ""), (str(plate.get("observation_start")) if plate.get("observation_start") != null else "Observation date unavailable")]

func _refresh_details() -> void:
	if archive_mismatch and reference.get("kind") == "survey":
		map_button.disabled = true
		detail.text = "Survey information unavailable\n\n" + last_error + "\n\n" + str(reference.get("id", ""))
		return
	if reference.is_empty():
		map_button.disabled = not plate.get("registered", false)
		var lines: Array[String] = [str(plate.get("name", "Choose an object or a survey field")), "Registered source coordinates" if plate.get("registered", false) else "Unregistered image · depth not shown", str(plate.get("credit", ""))]
		if show_details: lines.append(str(plate.get("processing", "No associated survey image for this object")))
		if show_sources and not plate.is_empty():
			var licence := str(plate.get("licence", "unavailable"))
			lines.append("Source\n" + str(plate.get("source_url", "unavailable")))
			lines.append("Licence\n" + licence)
			if licence == "CC BY-NC 3.0 IGO": lines.append("https://creativecommons.org/licenses/by-nc/3.0/igo/")
			elif licence == "CC BY-SA 3.0 IGO": lines.append("https://creativecommons.org/licenses/by-sa/3.0/igo/")
		detail.text = "\n\n".join(lines)
	else:
		var facts: Dictionary = Facts.facts(reference, index, catalogue, world)
		if not facts.get("available", false):
			map_button.disabled = true
			detail.text = "Information unavailable\n\n" + str(reference.get("id", ""))
			return
		map_button.disabled = false
		var lines: Array[String] = [str(facts.title)]
		for row: Dictionary in facts.get("primary", []): lines.append("%s\n%s" % [row.label, row.value])
		if show_details:
			for section: Dictionary in facts.get("sections", []): lines.append("%s\n%s" % [section.title, section.text])
		if show_sources:
			lines.append(str(facts.id))
			for source: Dictionary in facts.get("sources", []): lines.append("%s\n%s" % [source.label, source.url])
		detail.text = "\n\n".join(lines)

func _source_size() -> Vector2:
	return Vector2(float(tile_index.get("source_width", 1)), float(tile_index.get("source_height", 1)))
func _scale() -> float:
	var size := _source_size()
	return maxf(0.000001, minf(maxf(1.0, image_area.size.x) / size.x, maxf(1.0, image_area.size.y) / size.y) * zoom)
func _origin() -> Vector2:
	return (image_area.size - _source_size() * _scale()) * 0.5 + pan
func source_point(at: Vector2) -> Vector2:
	return (at - _origin()) / _scale()
func zoom_at(factor: float, at: Vector2) -> void:
	if mode != "archive" or not is_finite(factor) or factor <= 0.0: return
	var source := source_point(at)
	zoom = clampf(zoom * factor, 0.25, 64.0)
	pan = at - source * _scale() - (image_area.size - _source_size() * _scale()) * 0.5
	_update_tiles()

func _chosen_level() -> Dictionary:
	var levels: Array = tile_index.get("levels", [])
	for i in range(levels.size() - 1, -1, -1):
		if _source_size().x / float(levels[i].width) * _scale() <= 1.25: return levels[i]
	return levels[0] if not levels.is_empty() else {}
func _tile_rect(meta: Dictionary, level: Dictionary) -> Rect2:
	var ratio := _source_size() / Vector2(float(level.width), float(level.height))
	var r: Array = meta.source_rect
	return Rect2(_origin() + Vector2(r[0], r[1]) * ratio * _scale(), Vector2(r[2], r[3]) * ratio * _scale())
func _requested() -> Array:
	var levels: Array = tile_index.get("levels", [])
	if levels.is_empty(): return []
	var chosen := _chosen_level()
	var out: Array = []
	for level: Dictionary in [levels.back(), chosen]:
		for meta: Dictionary in level.get("tiles", []):
			if _tile_rect(meta, level).intersects(Rect2(Vector2.ZERO, image_area.size)) and not out.any(func(row): return row.key == meta.key): out.append(meta)
	return out
func _update_tiles() -> void:
	if not visible or mode != "archive": return
	if archive_mismatch:
		cache.close()
		state_line.text = "Archive unavailable · " + last_error
		image_area.queue_redraw()
		return
	var requested := _requested()
	cache.set_visible(requested.map(func(meta): return meta.key))
	for meta: Dictionary in requested: cache.request_tile(meta)
	var registration: Dictionary = plate.get("registration", {})
	state_line.text = "No survey image for this object · choose a field" if plate.is_empty() else ("Source file missing · fetch observation assets" if tile_index.is_empty() else ("Resolution limit · enlarged pixels" if _scale() > 1.0 else "Drag to pan · wheel/pinch/+/- to zoom"))
	if plate.get("registered", false): state_line.text += " · %.1f arcsec / source pixel" % float(registration.get("arcsec_per_source_pixel", 0.0))
	image_area.queue_redraw()

func _draw_image() -> void:
	image_area.draw_rect(Rect2(Vector2.ZERO, image_area.size), Color(0.006, 0.009, 0.015))
	if mode != "archive": return
	var levels: Array = tile_index.get("levels", [])
	if levels.is_empty(): return
	for level: Dictionary in [levels.back(), _chosen_level()]:
		for meta: Dictionary in level.get("tiles", []):
			var entry: Dictionary = cache.get_tile(meta.key)
			if entry.is_empty(): continue
			var c: Array = meta.content_rect
			image_area.draw_texture_rect_region(entry.texture, _tile_rect(meta, level), Rect2(c[0], c[1], c[2], c[3]))
	if reference.get("kind") == "survey" and plate.get("registered", false):
		var row: Dictionary = index.object(reference.id)
		var point: Vector2 = _source_centre(row)
		if point.is_finite(): image_area.draw_arc(_origin() + point * _scale(), 10.0, 0.0, TAU, 32, Color(0.95, 0.82, 0.45), 1.5, true)

func point_candidates(at: Vector2) -> Array:
	if archive_mismatch or not plate.get("registered", false) or index == null: return []
	var hits: Array = []
	for id in index.objects:
		var row: Dictionary = index.object(id)
		if row.get("plate_id") != plate.id: continue
		var point: Vector2 = _source_centre(row)
		if point.is_finite() and Rect2(Vector2.ZERO, _source_size()).has_point(point) and (_origin() + point * _scale()).distance_to(at) <= 12.0: hits.append(row)
	return hits

func _source_centre(row: Dictionary) -> Vector2:
	# The projection adapter returns zero-based pixel-centre indices. Canvas
	# rectangles use pixel edges, so the first rendered texel is centred at .5.
	return ProjectionMath.display_point(plate, row) + Vector2(.5,.5)
func select_object(id: String) -> void:
	if archive_mismatch: return
	var source: Dictionary = index.object(id)
	if source.is_empty(): return
	if source.get("plate_id") != plate.get("id"): _load_plate(str(source.plate_id))
	reference = {"kind": "survey", "id": id}
	_refresh_details(); detail.scroll_to_line(0); image_area.queue_redraw()
func _image_input(event: InputEvent) -> void:
	if mode != "archive": return
	if event is InputEventMagnifyGesture:
		zoom_at(event.factor, event.position); image_area.accept_event()
	elif event is InputEventPanGesture:
		pan -= event.delta * 20.0; _update_tiles(); image_area.accept_event()
	elif event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN] and event.pressed:
			zoom_at(1.25 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 0.8, event.position)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			_drag = event.pressed
			if event.pressed: _dragged = false; _drag_start = event.position; image_area.grab_focus()
			elif not _dragged:
				_hits = point_candidates(event.position)
				if _hits.size() == 1: select_object(_hits[0].id)
				elif _hits.size() > 1:
					source_picker.clear()
					for i in _hits.size(): source_picker.add_item(str(_hits[i].get("source_id", _hits[i].id)), i)
					source_picker.popup(Rect2i(Vector2i(image_area.global_position + event.position), Vector2i(300, 0)))
		image_area.accept_event()
	elif event is InputEventMouseMotion and _drag:
		_dragged = _dragged or event.position.distance_to(_drag_start) > 3.0
		pan += event.relative; _update_tiles(); image_area.accept_event()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_PLUS, KEY_EQUAL, KEY_KP_ADD]: zoom_at(1.25, image_area.size * 0.5)
		elif event.keycode in [KEY_MINUS, KEY_KP_SUBTRACT]: zoom_at(0.8, image_area.size * 0.5)
		image_area.accept_event()

func close_panel() -> void:
	_drag = false; _dragged = false
	source_picker.hide()
	image_area.release_focus()
	cache.close(); live_view.set_active(false)
	visible = false
	closed.emit()

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not event is InputEventKey or not event.pressed or event.echo: return
	if event.is_command_or_control_pressed(): return
	if event.keycode == KEY_ESCAPE:
		close_panel(); get_viewport().set_input_as_handled()
	elif event.keycode == KEY_T:
		var focus := get_viewport().gui_get_focus_owner()
		if focus is LineEdit or focus is TextEdit: return
		if mode == "live":
			if live_view.level == 2: close_panel()
			else: live_view.level = 2; _refresh_live()
		get_viewport().set_input_as_handled()
func _process(_delta: float) -> void:
	if not is_visible_in_tree(): return
	if mode == "archive":
		cache.pump(1)
		for meta: Dictionary in _requested():
			var tile_state := cache.state(str(meta.key))
			if tile_state in ["missing", "corrupt", "invalid", "over_budget"]:
				state_line.text = "Image detail unavailable · %s image data" % tile_state
				break
		image_area.queue_redraw()
	elif system_view != null: live_view.refresh(world)
