class_name DeckLayout
extends RefCounted
## R2-DECK-LAYOUT (design_docs/planned/r2/deck-layout.md §D2): layouts in-engine, for search,
## review and the walk bake. A layout (art/deck-layout-v2/*.json, schema stapledons.deck.layout/1)
## places the bridge's movable prop groups by their pivot in ship metres (Blender +Z up; glTF is
## (x, z, -y)) and a yaw about +Z. apply() moves the named nodes of a running ship demo and rebuilds
## the bridge walk surface (tools/deck_walk_bake.gd writes it out for the Blender generator). The
## measurements are DeckBowMetrics' (tools/deck_bow_metrics.gd); the sector-view metrics of the
## first plan went with the sector views (R2-CAMERA-FORWARD F3). Every acceptance check runs on
## the exported GLB.

const SCHEMA := "stapledons.deck.layout/1"
const SAMPLE_M := 0.5
const PX := Vector2(1280, 720)
const DECK_Y := 82.0
const LOWER_Y := 57.0
const WALK_CELL_M := 0.125
const WALK_RIM_M := 20.3 # a vacated hole is refilled only inside the deck's walkable disc
const HOLE_MARGIN_M := 1.0 # a group's walk hole is looked for this far around its footprint
## Prop groups the layout may move or remove: the pivot node first, then its companions.
const GROUPS := {
	"captain_chair": ["captain_chair", "v2_chair_detail_00"],
	"archive_terminal": ["archive_terminal", "v2_archive_detail_00"],
	"console_navigation_0": ["console_navigation_0", "v2_nav_detail_00"],
	"console_navigation_1": ["console_navigation_1", "v2_nav_detail_01"],
	"console_navigation_2": ["console_navigation_2", "v2_nav_detail_02"],
	"console_decision_0": ["console_decision_0", "v2_desk_props_00"],
	"console_decision_1": ["console_decision_1", "v2_desk_props_01"],
	"console_decision_2": ["console_decision_2", "v2_desk_props_02"],
	"console_decision_3": ["console_decision_3", "v2_desk_props_03"],
	"v2_bench_detail_00": ["v2_bench_detail_00"], "v2_bench_detail_01": ["v2_bench_detail_01"],
	"v2_bench_detail_02": ["v2_bench_detail_02"], "v2_bench_detail_03": ["v2_bench_detail_03"],
	"v2_conduit_00": ["v2_conduit_00"], "v2_conduit_01": ["v2_conduit_01"], "v2_conduit_02": ["v2_conduit_02"],
	"v2_conduit_03": ["v2_conduit_03"], "v2_conduit_04": ["v2_conduit_04"], "v2_conduit_05": ["v2_conduit_05"],
	"v2_conduit_06": ["v2_conduit_06"],
	"rim_frond_0": ["rim_frond_0"], "rim_frond_1": ["rim_frond_1"], "rim_frond_2": ["rim_frond_2"],
	"rim_frond_3": ["rim_frond_3"], "rim_frond_4": ["rim_frond_4"], "rim_frond_5": ["rim_frond_5"],
	"rim_frond_6": ["rim_frond_6"], "rim_frond_7": ["rim_frond_7"], "rim_frond_8": ["rim_frond_8"],
	"rim_frond_9": ["rim_frond_9"],
}
## The props the boom-intrusion rule looks for (node-name prefixes); structure (deck, spire,
## rail, lift shaft) is the clear-line rule's business.
const PROP_PREFIXES := ["console_", "captain_chair", "archive_terminal", "rim_frond_", "v2_desk_props_", "v2_nav_detail_", "v2_chair_detail_", "v2_archive_detail_", "v2_bench_detail_", "Guardrail 82"]
## The active stations (ShipConsoles.STATIONS), by their meshes.
## Fixed props whose walk holes a vacated group's margin must never open (with every unmoved group).
const STATIC_HOLES := ["archive_shrine_ribs", "spire_needle", "v2_spire_vents_00", "ramp_down", "Guardrail 82", "Guardrail 82_001", "Guardrail 82_002"]
const ACTIVE_STATIONS := {
	"navigation": ["console_navigation_0", "console_navigation_1", "console_navigation_2"],
	"voyage": ["console_decision_0"],
	"crew": ["console_decision_1"],
	"archive": ["archive_terminal"],
}

var demo: Node
var dir: CameraDirector
var layout := {}
var orig_walk: WalkArea
var _groups := {} # id -> {"nodes": [Node3D], "orig": [Transform3D], "box": Rect2 (plan, glTF xz, old footprint + margin), "old": Transform3D, "new": Transform3D, "removed": bool}
var _moved: Array = []
var _static: Array = [] # Rect2 (plan, glTF xz): fixed props' footprints + margin
var _extra: Array = [] # fixture boxes (tests only)


func _init(owner_demo: Node) -> void:
	demo = owner_demo
	dir = demo.director
	orig_walk = demo.walk_bridge


# ------------------------------------------------------------------ layout files

static func load_layout(path: String) -> Dictionary:
	var text := FileAccess.get_file_as_string(path)
	var d: Variant = JSON.parse_string(text)
	return d if d is Dictionary else {}


## Errors in a layout file (empty when it is valid). Fixture boxes are refused unless allowed.
static func validate(d: Dictionary, allow_test_boxes := false) -> PackedStringArray:
	var errs := PackedStringArray()
	if str(d.get("schema", "")) != SCHEMA:
		errs.append("schema is not %s" % SCHEMA)
	var b: Variant = d.get("bridge", {})
	if not b is Dictionary:
		errs.append("bridge is not an object")
		return errs
	var props: Variant = b.get("props", {})
	if not props is Dictionary:
		errs.append("bridge.props is not an object")
		return errs
	for id: String in props:
		if not GROUPS.has(id):
			errs.append("unknown prop group %s" % id)
			continue
		var p: Variant = props[id]
		if not p is Dictionary:
			errs.append("%s is not an object" % id)
			continue
		if p.get("remove", false):
			continue
		if not (p.get("position_m") is Array and p.position_m.size() == 2):
			errs.append("%s.position_m is not [x, y]" % id)
		if not (p.get("yaw_deg") is float or p.get("yaw_deg") is int):
			errs.append("%s.yaw_deg is not a number" % id)
		if p.has("walk_clear_m") and not (p.walk_clear_m is float or p.walk_clear_m is int):
			errs.append("%s.walk_clear_m is not a number" % id)
	var sp: Variant = b.get("spawn_captain")
	if sp != null and not (sp is Dictionary and sp.get("position_m") is Array and sp.position_m.size() == 2):
		errs.append("bridge.spawn_captain.position_m is not [x, y]")
	if d.has("test_boxes") and not allow_test_boxes:
		errs.append("test_boxes are for test fixtures only")
	return errs


## Ship metres (x, y) and yaw about +Z -> the glTF transform on the bridge deck.
static func ship_to_gltf(pos: Array, yaw_deg: float) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, deg_to_rad(yaw_deg)), Vector3(float(pos[0]), DECK_Y, -float(pos[1])))


# ------------------------------------------------------------------ applying a layout in-engine

## Move (or remove) the named groups relative to `base` (the layout the shipped GLB was built
## from), rebuild the bridge walk, and add any fixture boxes. Returns errors (empty when done).
func apply(candidate: Dictionary, base: Dictionary, allow_test_boxes := false) -> PackedStringArray:
	var errs := validate(candidate, allow_test_boxes)
	errs.append_array(validate(base))
	if not errs.is_empty():
		return errs
	layout = candidate
	var cprops: Dictionary = candidate.bridge.get("props", {})
	var bprops: Dictionary = base.bridge.get("props", {})
	for id: String in cprops:
		if not bprops.has(id):
			errs.append("%s is not in the base layout" % id)
			continue
		var g := _group(id)
		if g.is_empty():
			errs.append("%s: no such node in ship.glb" % id)
			continue
		var bp: Dictionary = bprops[id]
		var cp: Dictionary = cprops[id]
		g.old = ship_to_gltf(bp.position_m, float(bp.yaw_deg))
		if cp.get("remove", false):
			g.removed = true
			for n: Node3D in g.nodes:
				_disable(n)
		else:
			g.new = ship_to_gltf(cp.position_m, float(cp.yaw_deg))
			if g.new.is_equal_approx(g.old):
				continue
			var delta: Transform3D = g.new * g.old.affine_inverse()
			for i in g.nodes.size():
				(g.nodes[i] as Node3D).global_transform = delta * (g.orig[i] as Transform3D)
			g.clear = float(cp.get("walk_clear_m", 0.0))
			if g.clear > 0.0:
				g.keep_out = _plan_rect(g.nodes).grow(g.clear)
		_moved.append(g)
	for box: Dictionary in candidate.get("test_boxes", []):
		_add_box(box)
	if not _moved.is_empty():
		_static = static_boxes()
		demo.walk_bridge = build_walk()
		demo.walk = demo.walk_bridge
	return errs


## The plan rectangle (glTF xz) of some nodes' meshes as they stand.
static func _plan_rect(nodes: Array) -> Rect2:
	var r := Rect2()
	var first := true
	for n: Node3D in nodes:
		if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
			var a: AABB = n.global_transform * (n as MeshInstance3D).mesh.get_aabb()
			var q := Rect2(a.position.x, a.position.z, a.size.x, a.size.z)
			r = q if first else r.merge(q)
			first = false
	return r


func _group(id: String) -> Dictionary:
	if _groups.has(id):
		return _groups[id]
	var nodes := []
	var orig := []
	var box := Rect2()
	for name: String in GROUPS[id]:
		var n := demo.geometry.find_child(name, true, false) as Node3D
		if n == null:
			continue
		nodes.append(n)
		orig.append(n.global_transform)
		if n is MeshInstance3D and n.mesh != null:
			var a: AABB = n.global_transform * n.mesh.get_aabb()
			var r := Rect2(a.position.x, a.position.z, a.size.x, a.size.z)
			box = r if box.size == Vector2.ZERO else box.merge(r)
	if nodes.is_empty():
		return {}
	var g := {"id": id, "nodes": nodes, "orig": orig, "box": box.grow(HOLE_MARGIN_M), "old": Transform3D(), "new": Transform3D(), "removed": false, "clear": 0.0, "keep_out": Rect2()}
	_groups[id] = g
	return g


func _disable(n: Node) -> void:
	if n is Node3D:
		(n as Node3D).visible = false
	if n is CollisionShape3D:
		(n as CollisionShape3D).disabled = true
	for c in n.get_children():
		_disable(c)


func _add_box(spec: Dictionary) -> void:
	var c: Array = spec.center_gltf_m
	var s: Array = spec.size_m
	var body := StaticBody3D.new()
	body.name = str(spec.get("name", "fixture_box"))
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(float(s[0]), float(s[1]), float(s[2]))
	shape.shape = bs
	body.add_child(shape)
	var mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = bs.size
	mesh.mesh = bm
	mesh.name = body.name
	body.position = Vector3(float(c[0]), float(c[1]), float(c[2]))
	demo.geometry.add_child(body)
	body.add_child(mesh)
	_extra.append(body)


## The walk rule (§D2; the Blender generator implements the same rule on the same 0.125 m grid):
## a cell is covered when the shipped walk covers its centre or a point 0.4 cell from it toward
## any corner (so the shipped walk's sub-cell cracks close and its holes shrink by under a cell);
## it is walkable when covered, or in a moved group's old hole (inside the deck's disc); and never
## when its point carried back to a moved group's old pose falls in that group's old hole. A
## vacated cell never opens inside a fixed prop's footprint (static_boxes()); a removed group
## (a flat floor detail) opens nothing. A group's walk_clear_m keeps the walk that far from its
## moved meshes' plan rectangle (the chair's high back must not hide a captain standing behind it).
func covered(c: Vector3) -> bool:
	var o := WALK_CELL_M * 0.4
	for d: Vector2 in [Vector2.ZERO, Vector2(o, o), Vector2(-o, o), Vector2(o, -o), Vector2(-o, -o)]:
		if not is_nan(orig_walk.height_at(c.x + d.x, c.z + d.y)):
			return true
	return false


func walkable_cell(c: Vector3) -> bool:
	for g: Dictionary in _moved:
		if g.removed:
			continue
		if float(g.clear) > 0.0 and (g.keep_out as Rect2).has_point(Vector2(c.x, c.z)):
			return false
		var q: Vector3 = g.old * (g.new.affine_inverse() * c)
		if (g.box as Rect2).has_point(Vector2(q.x, q.z)) and not covered(q):
			return false
	var xz := Vector2(c.x, c.z)
	for r: Rect2 in _static:
		if r.has_point(xz): # beside a fixed prop the shipped hole stands exactly (no dilation)
			return not is_nan(orig_walk.height_at(c.x, c.z))
	if covered(c):
		return true
	if xz.length() > WALK_RIM_M:
		return false
	for r: Rect2 in _static:
		if r.has_point(xz):
			return false
	for g: Dictionary in _moved:
		if not g.removed and (g.box as Rect2).has_point(xz):
			return true
	return false


## The footprints (plan, + margin) of everything that keeps its walk hole: the fixed props and
## every group the layout does not move. Removed groups (flat floor details) open nothing.
func static_boxes() -> Array:
	var moved := {}
	for g: Dictionary in _moved:
		moved[g.id] = true
	var names: Array = STATIC_HOLES.duplicate()
	for id: String in GROUPS:
		if not moved.has(id) and not id.begins_with("v2_conduit_"): # floor conduits are flat: no walk hole
			names.append_array(GROUPS[id])
	var out := []
	for name: String in names:
		var n := demo.geometry.find_child(name, true, false) as MeshInstance3D
		if n == null or n.mesh == null:
			continue
		var a: AABB = n.global_transform * n.mesh.get_aabb()
		out.append(Rect2(a.position.x, a.position.z, a.size.x, a.size.z).grow(HOLE_MARGIN_M))
	return out


## The rebuilt bridge walk: the shipped triangles, clipped out of every affected rectangle (a
## moved group's old and new footprints + margin, snapped to the 0.125 m grid), plus the
## rectangles' cells by walkable_cell(). Outside the moved groups the walk is the shipped one.
func build_walk() -> WalkArea:
	var w := WalkArea.new()
	w.radius = orig_walk.radius
	var rects := affected_rects()
	var tris := PackedVector3Array()
	for t in orig_walk.triangle_count():
		var polys := [[orig_walk._tris[3 * t], orig_walk._tris[3 * t + 1], orig_walk._tris[3 * t + 2]]]
		for r: Rect2 in rects:
			var next := []
			for poly: Array in polys:
				next.append_array(clip_out(poly, r))
			polys = next
		for poly: Array in polys:
			for i in range(1, poly.size() - 1):
				tris.append_array([poly[0], poly[i], poly[i + 1]])
	var done := {}
	var cells := {} # Vector2i -> the walk height there (walkable cells only)
	for r: Rect2 in rects:
		var i0 := roundi(r.position.x / WALK_CELL_M)
		var j0 := roundi(r.position.y / WALK_CELL_M)
		for i in range(i0, roundi(r.end.x / WALK_CELL_M)):
			for j in range(j0, roundi(r.end.y / WALK_CELL_M)):
				var key := Vector2i(i, j)
				if done.has(key):
					continue
				done[key] = true
				var c := Vector3((i + 0.5) * WALK_CELL_M, DECK_Y, (j + 0.5) * WALK_CELL_M)
				if not walkable_cell(c):
					continue
				var y := orig_walk.height_at(c.x, c.z)
				if is_nan(y):
					y = DECK_Y if Vector2(c.x, c.z).length() <= WALK_RIM_M else _near_height(c)
				cells[key] = y
	# One quad per run of walkable cells along x at one height (the same plan coverage as one quad
	# per cell, a fraction of the triangles: the baked walk_bridge.glb stays small).
	var keys := cells.keys()
	keys.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
	var k := 0
	while k < keys.size():
		var a: Vector2i = keys[k]
		var y: float = cells[a]
		var e := k
		while e + 1 < keys.size() and keys[e + 1] == Vector2i((keys[e] as Vector2i).x + 1, a.y) and cells[keys[e + 1]] == y:
			e += 1
		var b: Vector2i = keys[e]
		var x0 := a.x * WALK_CELL_M
		var x1 := (b.x + 1) * WALK_CELL_M
		var z0 := a.y * WALK_CELL_M
		var z1 := z0 + WALK_CELL_M
		var p0 := Vector3(x0, y, z0)
		var p1 := Vector3(x1, y, z0)
		var p2 := Vector3(x1, y, z1)
		var p3 := Vector3(x0, y, z1)
		tris.append_array([p0, p1, p2, p0, p2, p3])
		k = e + 1
	w._tris = tris
	w._index()
	return w


## Plan rectangles (glTF xz) the layout changes: each moved group's old footprint + margin and the
## same footprint at its new pose (its bounding rectangle), snapped outward to the cell grid.
func affected_rects() -> Array:
	var out := []
	for g: Dictionary in _moved:
		if g.removed or str(g.id).begins_with("v2_conduit_"): # floor conduits are flat: no walk hole to move
			continue
		var box: Rect2 = g.box
		out.append(_snap(box))
		var m: Transform3D = g.new * g.old.affine_inverse()
		var r := Rect2()
		for k in 4:
			var corner := Vector2(box.position.x + box.size.x * float(k % 2), box.position.y + box.size.y * float(k / 2))
			var q := m * Vector3(corner.x, DECK_Y, corner.y)
			r = Rect2(Vector2(q.x, q.z), Vector2.ZERO) if k == 0 else r.expand(Vector2(q.x, q.z))
		out.append(_snap(r))
		if float(g.clear) > 0.0:
			out.append(_snap(g.keep_out))
	return out


static func _snap(r: Rect2) -> Rect2:
	var lo := Vector2(floorf(r.position.x / WALK_CELL_M), floorf(r.position.y / WALK_CELL_M)) * WALK_CELL_M
	var hi := Vector2(ceilf(r.end.x / WALK_CELL_M), ceilf(r.end.y / WALK_CELL_M)) * WALK_CELL_M
	return Rect2(lo, hi - lo)


## A plan polygon (glTF points) minus a rectangle: up to four pieces (x below, x above, then the
## middle band's z below and z above), as the lift shaft was cut from the walk.
static func clip_out(poly: Array, r: Rect2) -> Array:
	var out := []
	for piece: Array in [_half(poly, 0, r.position.x, false), _half(poly, 0, r.end.x, true)]:
		if piece.size() >= 3:
			out.append(piece)
	var mid := _half(_half(poly, 0, r.position.x, true), 0, r.end.x, false)
	for piece: Array in [_half(mid, 2, r.position.y, false), _half(mid, 2, r.end.y, true)]:
		if piece.size() >= 3:
			out.append(piece)
	return out


## The part of a polygon on one side of the plane axis = value (axis 0 x, 2 z).
static func _half(poly: Array, axis: int, value: float, greater: bool) -> Array:
	var out := []
	for i in poly.size():
		var a: Vector3 = poly[i]
		var b: Vector3 = poly[(i + 1) % poly.size()]
		var ain := a[axis] >= value if greater else a[axis] <= value
		var bin := b[axis] >= value if greater else b[axis] <= value
		if ain:
			out.append(a)
		if ain != bin:
			out.append(a + (b - a) * ((value - a[axis]) / (b[axis] - a[axis])))
	return out


func _near_height(c: Vector3) -> float:
	var o := WALK_CELL_M * 0.4
	for d: Vector2 in [Vector2(o, o), Vector2(-o, o), Vector2(o, -o), Vector2(-o, -o)]:
		var y := orig_walk.height_at(c.x + d.x, c.z + d.y)
		if not is_nan(y):
			return y
	return DECK_Y


## The captain's spawn for a layout (glTF): the layout's, else the shipped manifest's.
func spawn() -> Vector3:
	var sp: Variant = layout.get("bridge", {}).get("spawn_captain") if not layout.is_empty() else null
	if sp is Dictionary:
		return Vector3(float(sp.position_m[0]), DECK_Y, -float(sp.position_m[1]))
	return manifest_spawn(demo.manifest)[0]


## [position (glTF), yaw (rad)] from assets/ship_demo/manifest.json: spawn_captain (ship metres,
## R2-DECK-LAYOUT DL1), else the R1 walk.bridge_spawn_gltf_m with the R1 yaw.
static func manifest_spawn(m: Dictionary) -> Array:
	var sc: Variant = m.get("spawn_captain")
	if sc is Dictionary:
		return [Vector3(float(sc.position_m[0]), DECK_Y, -float(sc.position_m[1])), float(sc.get("yaw", 0.47))]
	var w: Array = m.get("walk", {}).get("bridge_spawn_gltf_m", [8, 82, -4.8])
	return [Vector3(float(w[0]), float(w[1]), float(w[2])), 0.47]


# ------------------------------------------------------------------ samples and cells

func samples(area: String) -> Array:
	var walk: WalkArea = demo.walk_lower if area == "lower" else demo.walk_bridge
	var y := LOWER_Y if area == "lower" else DECK_Y
	var out := []
	var n := int(30.0 / SAMPLE_M)
	for i in range(-n, n + 1):
		for j in range(-n, n + 1):
			var p := Vector3(i * SAMPLE_M, y, j * SAMPLE_M)
			if walk.is_walkable(p):
				var hh := walk.height_at(p.x, p.z)
				out.append(Vector3(p.x, hh if not is_nan(hh) else y, p.z))
	return out


## Every cell a standing point can be in (its own and the hysteresis neighbours), as the camera
## test sweeps them.
func cells(p: Vector3) -> Array:
	var s: Dictionary = dir.data.sectors
	var k := dir.sector_for(p, -1)
	var a := k % 8
	var angs := [a]
	for nb in [(a + 1) % 8, (a + 7) % 8]:
		if absf(wrapf(rad_to_deg(atan2(p.z, p.x)) - (nb + 0.5) * 45.0, -180.0, 180.0)) <= 22.5 + float(s.hysteresis_deg):
			angs.append(nb)
	var rings := [k / 8]
	if absf(Vector2(p.x, p.z).length() - float(s.ring_split_m)) <= float(s.ring_hysteresis_m):
		rings.append(1 - k / 8)
	var out := []
	for r: int in rings:
		for nb: int in angs:
			out.append(r * 8 + nb)
	return out


# ------------------------------------------------------------------ rays

func _space() -> PhysicsDirectSpaceState3D:
	return demo.camera.get_world_3d().direct_space_state


func ray(from: Vector3, to: Vector3) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.hit_back_faces = true
	return _space().intersect_ray(q)


## A ray through the ship's collision or the lift's boxes (they have no collision): the hit
## dictionary, {"collider_name": "lift"} for the lift, {} when clear.
func occluder(from: Vector3, to: Vector3) -> Dictionary:
	var hit := ray(from, to)
	var lift_t := INF
	for b: AABB in lift_boxes(demo):
		var at: Variant = b.intersects_segment(from, to)
		if at != null:
			lift_t = minf(lift_t, from.distance_to(at))
	if lift_t < INF and (hit.is_empty() or lift_t < from.distance_to(hit.position)):
		return {"collider_name": "lift", "normal": Vector3.ZERO, "position": from}
	return hit


func clear_line(eye: Vector3, head: Vector3) -> bool:
	return ray(eye, head + (eye - head).normalized() * 0.25).is_empty()


## The lift's visible boxes (they have no collision), as global AABBs (CameraDirector's copy left
## with the dead sky views in R2-CAMERA-FORWARD F3).
static func lift_boxes(demo_node: Node) -> Array:
	var out := []
	if demo_node == null or demo_node.lift == null:
		return out
	var stack: Array = [demo_node.lift]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D and n.is_visible_in_tree() and n.mesh != null:
			out.append((n as MeshInstance3D).global_transform * n.mesh.get_aabb())
		stack.append_array(n.get_children())
	return out


## The name of the mesh a collider belongs to (create_trimesh_collision puts the body under it).
static func collider_name(hit: Dictionary) -> String:
	if hit.has("collider_name"):
		return str(hit.collider_name)
	var c: Object = hit.get("collider")
	if c is Node:
		var n: Node = c
		if n.get_parent() is MeshInstance3D:
			return str(n.get_parent().name)
		return str(n.name)
	return ""


## The world direction through a pixel-grid point (u, v in [0, 1], v down) of a pose.
static func frame_dir(pose: Transform3D, u: float, v: float, px := PX) -> Vector3:
	var f := tan(deg_to_rad(CameraDirector.FOV_DEG) * 0.5)
	var x := (u * 2.0 - 1.0) * f * px.x / px.y
	var y := (1.0 - v * 2.0) * f
	return (pose.basis * Vector3(x, y, -1.0)).normalized()
