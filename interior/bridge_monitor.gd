class_name BridgeMonitor
extends Node3D
## R3-COMMS-V2 CV6 (design r3/comms-station-v2.md §D3, §D5): an ambient bridge monitor, a new class of
## bridge furniture read while walking and through the fixed views, with no interaction. Its frame and
## stand are a prop (Blender, bridge_monitors.glb, `monitor_<id>`); this node is its live face: a 16:9
## quad, 4.0 x 2.25 m, on the prop's screen anchor (the manifest's monitors.<id>.screen_ship_m and its
## facing), showing a BridgeScreens face rendered into a SubViewport.
##   - the face renders only while the quad is on screen (VisibleOnScreenNotifier3D), the signal face
##     every frame (its waterfall scrolls), the others at most REFRESH_HZ;
##   - the quad is unshaded and casts no shadow (a screen gives light, it does not take it);
##   - the quad and the frame are camera occluders (family "monitor"): they fade when they would hide
##     the captain, like the rim fronds.
## Presentation only: every number on a face is a binding on a sim field.

const FACE_M := Vector2(4.0, 2.25)
const REFRESH_HZ := 10.0

var id := ""
var kind := ""
var face: Control = null
var viewport := SubViewport.new()
var quad := MeshInstance3D.new()
var notifier := VisibleOnScreenNotifier3D.new()
var on_screen := false
var _since := 1e9
var _view: Dictionary = {}
var _receiver := true
var _bed := ""


## A monitor at `centre` (glTF metres) facing `toward` (glTF, the deck), showing face `k`.
func setup(monitor_id: String, k: String, centre: Vector3, toward: Vector3) -> void:
	id = monitor_id
	kind = k
	name = "monitor_face_" + monitor_id
	viewport.size = BridgeScreens.SIZE
	viewport.transparent_bg = false
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(viewport)
	face = BridgeScreens.make(k)
	if face != null:
		viewport.add_child(face)
	var qm := QuadMesh.new()
	qm.size = FACE_M
	quad.mesh = qm
	quad.name = "monitor_screen_" + monitor_id
	quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_texture = viewport.get_texture()
	quad.material_override = mat
	quad.add_to_group(CameraDirector.OCCLUDER_GROUP)
	add_child(quad)
	notifier.aabb = AABB(Vector3(-FACE_M.x * 0.5, -FACE_M.y * 0.5, -0.05), Vector3(FACE_M.x, FACE_M.y, 0.1))
	notifier.screen_entered.connect(func() -> void: on_screen = true)
	notifier.screen_exited.connect(func() -> void: on_screen = false)
	add_child(notifier)
	var away := centre - Vector3(toward.x, centre.y, toward.z)
	transform = Transform3D(Basis.looking_at(away, Vector3.UP), centre) # the quad's +Z faces the deck


## The frame's world and the comms setting (the waterfall's Receiver line, the week's bed).
func refresh(view: Dictionary, receiver: bool, bed: String) -> void:
	_view = view
	_receiver = receiver
	_bed = bed


func _process(dt: float) -> void:
	_since += dt
	if face == null or not (on_screen or Engine.is_editor_hint()):
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		return
	if kind == "signal" or _since >= 1.0 / REFRESH_HZ:
		_since = 0.0
		face.refresh(_view, _receiver, _bed)
		viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


## Monitors from a manifest section {<id>: {face, screen_ship_m: [x, y, z], toward_ship_m: [x, y]}}
## (ship metres: Blender +Z up; glTF (x, z, -y)), added under `parent`.
static func build(parent: Node, spec: Variant) -> Array[BridgeMonitor]:
	var out: Array[BridgeMonitor] = []
	if not spec is Dictionary:
		return out
	for mid: String in spec:
		var m: Dictionary = spec[mid]
		var c: Array = m.get("screen_ship_m", [])
		var t: Array = m.get("toward_ship_m", [0.0, 0.0])
		if c.size() != 3 or t.size() != 2:
			continue
		var mon := BridgeMonitor.new()
		parent.add_child(mon)
		mon.setup(mid, str(m.get("face", mid)), Vector3(float(c[0]), float(c[2]), -float(c[1])), Vector3(float(t[0]), 0.0, -float(t[1])))
		out.append(mon)
	return out
