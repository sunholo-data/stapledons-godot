class_name ChairCockpit
extends Node3D
## Physical captain displays. Contact and public camera/ray coordinates are world-space.
## Add to the scene tree before setup(); no collision bodies or simulation state are created.
const PALETTE = preload("res://ui/stapledon_theme.gd")
const IDS := ["archive", "voyage", "navigation", "crew", "comms"]
const ANGLES := [-68.0, -34.0, 0.0, 34.0, 68.0]
const TITLES := ["ARCHIVE", "VOYAGE", "NAVIGATION", "CREW", "COMMS"]
const DEFAULT_SUMMARIES := ["Ship knowledge", "Crossing & ship systems", "Course & destination", "People aboard", "Signals & conversations"]
const SCREEN_SIZE := Vector2(1.15, 0.72)
const EYE_HEIGHT_M := 0.72
const SCREEN_DISTANCE_M := 2.1
const FOCUS_DISTANCE_M := 0.65
var display_nodes: Dictionary = {}
var _frames: Dictionary = {}
var _overview := Transform3D.IDENTITY
var _selected := ""

func setup(contact: Dictionary) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	display_nodes.clear()
	_frames.clear()
	_selected = ""
	var seat: Vector3 = contact.get("seat", Vector3.ZERO)
	var forward: Vector3 = contact.get("forward", Vector3.FORWARD)
	forward.y = 0.0
	if forward.length_squared() < 0.001:
		forward = Vector3.FORWARD
	forward = forward.normalized()
	var eye := seat + Vector3.UP * EYE_HEIGHT_M
	_overview = Transform3D(Basis.looking_at(forward, Vector3.UP), eye)
	var right := forward.cross(Vector3.UP).normalized()
	for i in IDS.size():
		var angle := deg_to_rad(ANGLES[i])
		var radial := forward * cos(angle) + right * sin(angle)
		var centre := eye + radial * SCREEN_DISTANCE_M - Vector3.UP * 0.16
		var normal := (eye - centre).normalized()
		var screen_right := Vector3.UP.cross(normal).normalized()
		var screen_up := normal.cross(screen_right).normalized()
		var carrier := Node3D.new()
		carrier.name = "Cockpit_" + IDS[i]
		add_child(carrier)
		carrier.global_transform = Transform3D(Basis(screen_right, screen_up, normal), centre)
		# Layered, softened silhouettes have no hard box corners or physical collisions.
		var outer := _rounded_panel(SCREEN_SIZE + Vector2(0.16, 0.18), 0.13, PALETTE.INK)
		outer.position.z = -0.018
		carrier.add_child(outer)
		var rim := _rounded_panel(SCREEN_SIZE + Vector2(0.105, 0.125), 0.105, PALETTE.OCHRE)
		rim.position.z = -0.012
		carrier.add_child(rim)
		_frames[IDS[i]] = rim
		var display := MeshInstance3D.new()
		display.name = "Display"
		var plane := QuadMesh.new()
		plane.size = SCREEN_SIZE
		display.mesh = plane
		display.material_override = _material(PALETTE.NIGHT)
		carrier.add_child(display)
		display_nodes[IDS[i]] = display
		_add_label(display, "Title", TITLES[i], Vector3(0, 0.105, 0.004), 42, PALETTE.OCHRE_LIGHT)
		_add_label(display, "Summary", DEFAULT_SUMMARIES[i], Vector3(0, -0.055, 0.004), 28, PALETTE.CREAM)

func overview_pose() -> Transform3D:
	return _overview

func focus_pose(id: String) -> Transform3D:
	if not display_nodes.has(id):
		return _overview
	var display: MeshInstance3D = display_nodes[id]
	var eye := display.global_position + display.global_basis.z.normalized() * FOCUS_DISTANCE_M
	return Transform3D(Basis.looking_at(display.global_position - eye, Vector3.UP), eye)

func set_display_texture(id: String, texture: Texture2D) -> void:
	if not display_nodes.has(id):
		return
	var display: MeshInstance3D = display_nodes[id]
	var material := display.material_override as StandardMaterial3D
	material.albedo_texture = texture
	material.albedo_color = Color.WHITE if texture != null else PALETTE.NIGHT

func select(id: String) -> void:
	_selected = id if display_nodes.has(id) else ""
	for key in display_nodes:
		var display: MeshInstance3D = display_nodes[key]
		display.get_node("Title").visible = key != _selected
		display.get_node("Summary").visible = key != _selected
		var rim: MeshInstance3D = _frames[key]
		(rim.material_override as StandardMaterial3D).albedo_color = PALETTE.TEAL_LIGHT if key == _selected else PALETTE.OCHRE

func set_summaries(summaries: Dictionary) -> void:
	for id in summaries:
		if display_nodes.has(id):
			display_nodes[id].get_node("Summary").text = str(summaries[id])

## World-space corners ordered top-left, top-right, bottom-right, bottom-left.
func screen_corners(id: String) -> Array[Vector3]:
	var corners: Array[Vector3] = []
	if not display_nodes.has(id):
		return corners
	var display: MeshInstance3D = display_nodes[id]
	for uv in [Vector2.ZERO, Vector2.RIGHT, Vector2.ONE, Vector2.DOWN]:
		corners.append(display.global_transform * Vector3((uv.x - 0.5) * SCREEN_SIZE.x, (0.5 - uv.y) * SCREEN_SIZE.y, 0))
	return corners

## Nearest front-facing display. UV uses the same top-left origin as a SubViewport.
func pick_ray(origin: Vector3, direction: Vector3) -> Dictionary:
	if not origin.is_finite() or not direction.is_finite() or direction.length_squared() < 0.000001:
		return {}
	var ray := direction.normalized()
	var nearest := INF
	var result := {}
	for id in display_nodes:
		var display: MeshInstance3D = display_nodes[id]
		var normal := display.global_basis.z.normalized()
		var denominator := ray.dot(normal)
		if denominator >= -0.00001:
			continue
		var distance := (display.global_position - origin).dot(normal) / denominator
		if distance <= 0.00001 or distance >= nearest:
			continue
		var local := display.to_local(origin + ray * distance)
		var uv := Vector2(local.x / SCREEN_SIZE.x + 0.5, 0.5 - local.y / SCREEN_SIZE.y)
		# World-space float32 coordinates at the outer decks need submillimetre
		# of edge tolerance; clamp only this numerical sliver to viewport bounds.
		if uv.x < -0.0001 or uv.x > 1.0001 or uv.y < -0.0001 or uv.y > 1.0001:
			continue
		nearest = distance
		result = {"id": id, "uv": uv.clamp(Vector2.ZERO, Vector2.ONE)}
	return result

func _material(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = colour
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	return material

func _add_label(display: MeshInstance3D, label_name: String, text: String, at: Vector3, size: int, colour: Color) -> void:
	var label := Label3D.new()
	label.name = label_name
	label.text = text
	label.position = at
	var font := FontFile.new()
	font.load_dynamic_font(PALETTE.DISPLAY_FONT if label_name == "Title" else PALETTE.TEXT_FONT)
	label.font = font
	label.font_size = size
	label.pixel_size = 0.001
	label.modulate = colour
	label.outline_size = 0
	label.no_depth_test = false
	label.shaded = false
	display.add_child(label)

func _rounded_panel(size: Vector2, radius: float, colour: Color) -> MeshInstance3D:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	vertices.append(Vector3.ZERO)
	normals.append(Vector3.BACK)
	# Clockwise winding as viewed from the seated captain (+local Z).
	for corner in 4:
		var signs := [Vector2(1, 1), Vector2(1, -1), Vector2(-1, -1), Vector2(-1, 1)]
		var centre: Vector2 = signs[corner] * (size * 0.5 - Vector2.ONE * radius)
		for step in 9:
			var angle := deg_to_rad(90.0 - corner * 90.0 - step * 90.0 / 8.0)
			vertices.append(Vector3(centre.x + cos(angle) * radius, centre.y + sin(angle) * radius, 0))
			normals.append(Vector3.BACK)
	for i in vertices.size() - 1:
		indices.append_array(PackedInt32Array([0, i + 1, (i + 1) % (vertices.size() - 1) + 1]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = _material(colour)
	return instance
