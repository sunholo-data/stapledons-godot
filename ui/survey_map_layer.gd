extends Control
signal object_selected(reference: Dictionary)
signal field_selected(plate_id: String)
const FOOTPRINTS := "res://data/observations/euclid_dr1/footprints.json"
const DISPLAY_RADIUS := 8.0
const FRAME_LABEL := "Directions from Sol · outside view (sky mirrored) · depth not shown"
var fields := {}
var source_ids: Array[String] = []
var active_plate := ""
var selected_id := ""
var active := false
var last_error := ""
var field_choice := OptionButton.new()
var source_choice := OptionButton.new()
var _map: Node3D
var _index
var _built := false

func setup(map: Node3D, index) -> void:
	_map = map
	_index = index
	if not _built:
		_build()
	load_footprints()
	activate(false)

func load_footprints(path := FOOTPRINTS) -> bool:
	if not FileAccess.file_exists(path):return _fail("Footprint data unavailable")
	return set_footprints(JSON.parse_string(FileAccess.get_file_as_string(path)))

func set_footprints(data) -> bool:
	fields.clear()
	source_ids.clear()
	active_plate = ""
	selected_id = ""
	last_error = ""
	if _index == null or not data is Dictionary or data.get("format_version") != 1 or data.get("pack_id") != _index.version or not data.get("fields") is Array:
		return _fail("Footprint pack identity/version unavailable")
	for field in data.fields:
		if not field is Dictionary or not field.get("plate_id") is String:return _fail("Invalid footprint identity")
		var plate_id: String = field.plate_id
		var plate: Dictionary = _index.plate(plate_id)
		if fields.has(plate_id) or plate.is_empty() or not plate.get("registered",false):return _fail("Footprint must identify one registered plate")
		if not _unit(field.get("centre_galactic")) or not field.get("corners_galactic") is Array or field.corners_galactic.size() != 4:return _fail("Invalid footprint directions")
		for corner in field.corners_galactic:
			if not _unit(corner):return _fail("Invalid footprint corner")
		fields[plate_id] = field.duplicate(true)
	for id in _index.objects:
		var source: Dictionary = _index.object(id)
		if fields.has(source.get("plate_id","")) and _unit(source.get("galactic")):source_ids.append(id)
	source_ids.sort()
	_refresh_choices()
	queue_redraw()
	return true

func _fail(reason: String) -> bool:
	fields.clear()
	source_ids.clear()
	active_plate = ""
	selected_id = ""
	last_error = reason
	_refresh_choices()
	return false

func activate(on: bool) -> void:
	active = on
	visible = on
	set_process(on)
	queue_redraw()

func layout_for(full_size: Vector2, panel_width := 430.0) -> void:
	position = Vector2.ZERO
	size = Vector2(maxf(0.,full_size.x-panel_width),maxf(0.,full_size.y))
	field_choice.size.x = maxf(0.,minf(390.,size.x-24.))
	source_choice.size.x = maxf(0.,minf(590.,size.x-24.))
	queue_redraw()

func choose_field(plate_id: String) -> bool:
	if not fields.has(plate_id):return false
	active_plate = plate_id
	selected_id = ""
	_refresh_choices()
	field_selected.emit(plate_id)
	queue_redraw()
	return true

func choose_object(id: String) -> bool:
	if not source_ids.has(id):return false
	var source: Dictionary = _index.object(id)
	active_plate = str(source.plate_id)
	selected_id = id
	_refresh_choices()
	object_selected.emit({"kind":"survey","id":id})
	queue_redraw()
	return true

static func direction_world(direction: Dictionary) -> Vector3:
	return SkyFrame.to_world(Vector3(direction.x,direction.y,direction.z)) * DISPLAY_RADIUS

static func _unit(value) -> bool:
	if not value is Dictionary:return false
	for axis in ["x","y","z"]:
		if not (value.get(axis) is float or value.get(axis) is int) or not is_finite(float(value[axis])):return false
	# Validation only: positions themselves remain package-generated unit directions.
	return absf(Vector3(value.x,value.y,value.z).length()-1.) < 0.00001

func _build() -> void:
	_built = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	var label := Label.new()
	label.text = FRAME_LABEL
	label.position = Vector2(12,12)
	label.add_theme_color_override("font_color",Color(.65,.9,1.))
	add_child(label)
	field_choice.position = Vector2(12,42)
	field_choice.tooltip_text = "Registered survey fields; distances are not assigned"
	field_choice.item_selected.connect(func(i: int):
		var id = field_choice.get_item_metadata(i)
		if id is String:choose_field(id))
	add_child(field_choice)
	source_choice.position = Vector2(12,80)
	source_choice.tooltip_text = "Inspect exact published source identity"
	source_choice.item_selected.connect(func(i: int):
		var id = source_choice.get_item_metadata(i)
		if id is String:choose_object(id))
	add_child(source_choice)

func _refresh_choices() -> void:
	field_choice.clear()
	source_choice.clear()
	field_choice.add_item("Choose registered field (%d)" % fields.size())
	source_choice.add_item("Choose exact survey source (%d)" % source_ids.size())
	var ids := fields.keys()
	ids.sort()
	for id in ids:
		var plate: Dictionary = _index.plate(id)
		field_choice.add_item(str(plate.get("name",id)))
		field_choice.set_item_metadata(field_choice.item_count-1,id)
		if id == active_plate:field_choice.select(field_choice.item_count-1)
	for id in source_ids:
		var source: Dictionary = _index.object(id)
		if not active_plate.is_empty() and source.get("plate_id") != active_plate:continue
		source_choice.add_item(str(source.get("name",id)))
		source_choice.set_item_metadata(source_choice.item_count-1,id)
		if id == selected_id:source_choice.select(source_choice.item_count-1)

func _process(_delta: float) -> void:
	if active:queue_redraw()

func _draw() -> void:
	if not active or _map == null or not is_instance_valid(_map.camera):return
	var camera: Camera3D = _map.camera
	var font := ThemeDB.fallback_font
	var drawable := Rect2(Vector2(0,120),Vector2(size.x,maxf(0.,size.y-120)))
	for id in fields:
		var field: Dictionary = fields[id]
		var centre := direction_world(field.centre_galactic)
		if camera.is_position_behind(centre):continue
		var at := camera.unproject_position(centre)
		var points := PackedVector2Array()
		for corner in field.corners_galactic:
			var world := direction_world(corner)
			if camera.is_position_behind(world):points.clear();break
			points.append(camera.unproject_position(world))
		var color := Color(.5,.9,1.,.9) if id == active_plate else Color(.4,.75,.9,.65)
		if points.size() == 4:
			points.append(points[0])
			draw_polyline(points,color,1.5,true)
		if drawable.has_point(at):
			draw_circle(at,5.,color)
			draw_arc(at,9.,0.,TAU,24,color,1.,true)
			draw_string(font,at+Vector2(12,-9),str(_index.plate(id).get("name",id)),HORIZONTAL_ALIGNMENT_LEFT,-1,13,color)
	for id in source_ids:
		var source: Dictionary = _index.object(id)
		var world := direction_world(source.galactic)
		if camera.is_position_behind(world):continue
		var at := camera.unproject_position(world)
		if drawable.has_point(at):
			draw_circle(at,2.,Color(.8,.9,1.,.45))
			if id == selected_id:draw_arc(at,7.,0.,TAU,24,Color(.8,1.,1.),2.,true)
