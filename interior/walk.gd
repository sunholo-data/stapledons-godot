class_name WalkArea
extends RefCounted
## M4.2 walking: the avatar is constrained to the bundle's WALK_ surface (brief §6: a flat,
## marked navmesh source). Positions are in the play GLB's frame (glTF: metres, Y up). This is
## presentation only: the avatar's position never goes to the sim (ADR 0001; it has no sim
## reference at all).
##
## A position is walkable when the centre and RING points at the agent radius around it all
## lie over a WALK_ triangle (in plan view, XZ). step() moves by a delta, sliding along one
## axis when the full move would leave the surface, and stands the avatar on the surface
## height. Triangles are bucketed on a 1 m grid.
## SPAWN_ points and INTERACT_ objects are read the way tools/validate_area.gd reads them:
## a childless SPAWN_/INTERACT_ node or a direct child of such a group node.

const CELL := 1.0
const RING := 8
const SPAWN_PREFERRED := "SPAWN_captain_0"

var radius := 0.35
var spawns := {} # name -> Vector3
var interactables := {} # name -> AABB (play frame)
var _tris := PackedVector3Array()
var _grid := {} # Vector2i -> PackedInt32Array of triangle indices


static func from_scene(root: Node3D, agent_radius: float) -> WalkArea:
	var w := WalkArea.new()
	w.radius = agent_radius
	w._scan(root, Transform3D.IDENTITY, "")
	w._index()
	return w


func triangle_count() -> int:
	return _tris.size() / 3


## The captain's spawn (SPAWN_captain_0 when present, else the first by name).
func spawn_point() -> Vector3:
	if spawns.has(SPAWN_PREFERRED):
		return spawns[SPAWN_PREFERRED]
	var names := spawns.keys()
	names.sort()
	return spawns[names[0]] if not names.is_empty() else Vector3.ZERO


## Height of the walk surface under (x, z), NaN off the surface (the highest when stacked).
func height_at(x: float, z: float) -> float:
	var best := NAN
	var cell := Vector2i(floori(x / CELL), floori(z / CELL))
	if not _grid.has(cell):
		return best
	for t: int in _grid[cell]:
		var y := _tri_height(t, x, z)
		if not is_nan(y) and (is_nan(best) or y > best):
			best = y
	return best


func is_walkable(p: Vector3) -> bool:
	if is_nan(height_at(p.x, p.z)):
		return false
	for i in RING:
		var a := TAU * i / RING
		if is_nan(height_at(p.x + radius * cos(a), p.z + radius * sin(a))):
			return false
	return true


## Move by delta (XZ used), sliding along X or Z when the full move would leave the surface.
func step(from: Vector3, delta: Vector3) -> Vector3:
	for d in [Vector3(delta.x, 0.0, delta.z), Vector3(delta.x, 0.0, 0.0), Vector3(0.0, 0.0, delta.z)]:
		var p: Vector3 = from + d
		if d != Vector3.ZERO and is_walkable(p):
			return Vector3(p.x, height_at(p.x, p.z), p.z)
	return from


## The walkable point nearest to target, searched on rings out to max_r metres (target if none).
func closest_walkable(target: Vector3, max_r := 6.0) -> Vector3:
	if is_walkable(target):
		return Vector3(target.x, height_at(target.x, target.z), target.z)
	var r := 0.1
	while r <= max_r:
		var n := maxi(8, int(TAU * r / 0.1))
		for i in n:
			var a := TAU * i / n
			var p := target + Vector3(r * cos(a), 0.0, r * sin(a))
			if is_walkable(p):
				return Vector3(p.x, height_at(p.x, p.z), p.z)
		r += 0.1
	return target


## The interactable whose plan-view footprint is within reach of p ("" when none); the nearest wins.
func nearest_interactable(p: Vector3, reach: float) -> String:
	var best := ""
	var best_d := INF
	for name: String in interactables:
		var box: AABB = interactables[name]
		var dx := maxf(0.0, maxf(box.position.x - p.x, p.x - box.end.x))
		var dz := maxf(0.0, maxf(box.position.z - p.z, p.z - box.end.z))
		var d := sqrt(dx * dx + dz * dz)
		if d <= reach and d < best_d:
			best = name
			best_d = d
	return best


func _scan(n: Node, parent: Transform3D, group: String) -> void:
	var xf := parent
	if n is Node3D:
		xf = parent * (n as Node3D).transform
	var nm := String(n.name)
	var in_group := group
	for prefix in ["WALK_", "SPAWN_", "INTERACT_"]:
		if nm.begins_with(prefix):
			in_group = prefix
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null and in_group == "WALK_":
		var faces := (n as MeshInstance3D).mesh.get_faces()
		for v in faces:
			_tris.append(xf * v)
	var leaf := n.get_child_count() == 0
	var parent_name := String(n.get_parent().name) if n.get_parent() != null else ""
	if nm.begins_with("SPAWN_") and leaf or group == "SPAWN_" and parent_name.begins_with("SPAWN_"):
		spawns[nm] = xf.origin
	if nm.begins_with("INTERACT_") and leaf or group == "INTERACT_" and parent_name.begins_with("INTERACT_"):
		var box := AABB(xf.origin, Vector3.ZERO)
		if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
			box = xf * (n as MeshInstance3D).mesh.get_aabb()
		interactables[nm] = box
	for c in n.get_children():
		_scan(c, xf, in_group)


func _index() -> void:
	for t in triangle_count():
		var a := _tris[3 * t]
		var b := _tris[3 * t + 1]
		var c := _tris[3 * t + 2]
		var lo := Vector2i(floori(minf(a.x, minf(b.x, c.x)) / CELL), floori(minf(a.z, minf(b.z, c.z)) / CELL))
		var hi := Vector2i(floori(maxf(a.x, maxf(b.x, c.x)) / CELL), floori(maxf(a.z, maxf(b.z, c.z)) / CELL))
		for i in range(lo.x, hi.x + 1):
			for j in range(lo.y, hi.y + 1):
				var k := Vector2i(i, j)
				if not _grid.has(k):
					_grid[k] = PackedInt32Array()
				_grid[k].append(t)


## Barycentric height of triangle t at (x, z), NaN when (x, z) is outside it in plan view.
func _tri_height(t: int, x: float, z: float) -> float:
	var a := _tris[3 * t]
	var b := _tris[3 * t + 1]
	var c := _tris[3 * t + 2]
	var det := (b.z - c.z) * (a.x - c.x) + (c.x - b.x) * (a.z - c.z)
	if absf(det) < 1e-12:
		return NAN
	var l1 := ((b.z - c.z) * (x - c.x) + (c.x - b.x) * (z - c.z)) / det
	var l2 := ((c.z - a.z) * (x - c.x) + (a.x - c.x) * (z - c.z)) / det
	var l3 := 1.0 - l1 - l2
	const E := -1e-9
	if l1 < E or l2 < E or l3 < E:
		return NAN
	return l1 * a.y + l2 * b.y + l3 * c.y
