class_name DeckLayout
extends RefCounted
## R2-DECK-LAYOUT (design_docs/planned/r2/deck-layout.md §D2-§D4): the layout evaluator's
## measurements, shared by tools/deck_layout_eval.gd, tools/deck_layout_capture.gd and
## tests/test_deck_layout_eval.gd.
##
## A layout (art/deck-layout-v1/*.json, schema stapledons.deck.layout/1) places the bridge's
## movable prop groups by their pivot in ship metres (Blender +Z up; glTF is (x, z, -y)) and a
## yaw about +Z. apply() moves the named nodes of a running ship demo in-engine and rebuilds the
## bridge walk surface by the generator's rule (the old hole of a moved group is filled, its hole
## shape is cut at the new pose), so candidates are scored in seconds. The Blender export is the
## source of truth: every acceptance check runs on the exported GLB (no layout applied).
##
## Measurements (per view, 1280x720, FOV 78, the camera test's 0.5 m walk samples and cells):
##   clear line        samples whose eye-to-head ray hits geometry (camera test AC1, shared rule)
##   captain px        the captain's projected height at Z2 (min / median / max over samples)
##   boom intrusion    samples whose boom (eye to 1.5 m short of the head) passes within
##                     BOOM_CLEAR_M (0.75 m) of a movable prop's box
##   station px        Z3: each active station's projected height where it is in frame and seen
##   foreground        Z3: the largest single collider's share of frame rays that hit it nearer
##                     than the captain (floors excluded)
##   sky fraction      Sky forward: the share of a 64x36 ray grid through the frame reaching the
##                     sky, over every landing pose (72 rail bearings + the 2 m grid), and the
##                     forward pole's angular clearance from geometry
##   sky side          the side view's rail anchor: the captain and the stop's body direction clear

const SCHEMA := "stapledons.deck.layout/1"
const SAMPLE_M := 0.5
const PX := Vector2(1280, 720)
const FIGURE_M := 1.754 # the captain sprite's opaque height (tests/test_camera_director.gd)
const BOOM_CLEAR_M := 0.75 # DL0: a prop grazing the line of sight (a 1.5 m tube flagged 22 % of today's Z2 samples)
const BOOM_HEAD_M := 1.5 # the boom stops this far short of the head (the captain's own surroundings)
const DECK_Y := 82.0
const LOWER_Y := 57.0
const WALK_CELL_M := 0.125
const WALK_RIM_M := 20.3 # a vacated hole is refilled only inside the deck's walkable disc
const HOLE_MARGIN_M := 1.0 # a group's walk hole is looked for this far around its footprint
const SKY_W := 64
const SKY_H := 36
const SKY_FAR_M := 400.0
const POLE_MAX_DEG := 30
const FG_W := 96
const FG_H := 54
const SKY_GRID_M := 2.0
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
	for b: AABB in dir.lift_boxes():
		var at: Variant = b.intersects_segment(from, to)
		if at != null:
			lift_t = minf(lift_t, from.distance_to(at))
	if lift_t < INF and (hit.is_empty() or lift_t < from.distance_to(hit.position)):
		return {"collider_name": "lift", "normal": Vector3.ZERO, "position": from}
	return hit


func clear_line(eye: Vector3, head: Vector3) -> bool:
	return ray(eye, head + (eye - head).normalized() * 0.25).is_empty()


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


# ------------------------------------------------------------------ per-view measurements

## Clear line, frame, captain px and boom intrusions for a level view over an area's samples.
func level_metrics(area: String, lv: int, pts: Array = []) -> Dictionary:
	var v: Dictionary = dir.level_view(lv, area)
	if pts.is_empty():
		pts = samples(area)
	var props := _prop_boxes()
	var blocked := []
	var out_px := []
	var heights := []
	var intrusions := []
	for p: Vector3 in pts:
		var own := dir.sector_for(p, -1)
		for kk: int in cells(p):
			var pose := dir.resolve(v, p, kk)
			var head := dir.head_of(v, p)
			if not clear_line(pose.origin, head):
				blocked.append([p, kk])
			var sp := CameraDirector.screen_point(pose, head, PX)
			if is_nan(sp.x) or not Rect2(Vector2.ZERO, PX).has_point(sp):
				out_px.append([p, kk])
			if kk == own:
				heights.append(CameraDirector.figure_px(pose, p, FIGURE_M, PX.y))
				var who := boom_intrusion(pose.origin, head, props)
				if who != "":
					intrusions.append([p, who])
	heights.sort()
	var r := {"view": str(v.id), "area": area, "level": lv, "samples": pts.size(), "blocked": blocked.size(), "out_of_frame": out_px.size(), "boom_intrusions": intrusions.size()}
	if not blocked.is_empty():
		r.first_blocked = str(blocked[0])
	if not intrusions.is_empty():
		r.first_intrusion = str(intrusions[0])
		var names := {}
		for it: Array in intrusions:
			names[it[1]] = int(names.get(it[1], 0)) + 1
		r.intruders = names
	if not heights.is_empty():
		r.captain_px = {"min": snappedf(heights[0], 0.1), "median": snappedf(heights[heights.size() / 2], 0.1), "max": snappedf(heights[-1], 0.1)}
	return r


func _prop_boxes() -> Array:
	var out := []
	var stack: Array = [demo.geometry]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D and n.is_visible_in_tree() and n.mesh != null:
			for pre: String in PROP_PREFIXES:
				if str(n.name).begins_with(pre):
					out.append([str(n.name), (n as MeshInstance3D).global_transform * n.mesh.get_aabb()])
					break
		if n == demo.lift or str(n.name).begins_with("Commons"):
			continue
		stack.append_array(n.get_children())
	for b: Node in _extra:
		var m := b.get_child(1) as MeshInstance3D
		out.append([str(b.name), m.global_transform * m.mesh.get_aabb()])
	return out


static func _aabb_dist(b: AABB, p: Vector3) -> float:
	var q := Vector3(clampf(p.x, b.position.x, b.end.x), clampf(p.y, b.position.y, b.end.y), clampf(p.z, b.position.z, b.end.z))
	return q.distance_to(p)


## The first prop within BOOM_CLEAR_M of the boom (the eye to 1.5 m short of the head), or "".
func boom_intrusion(eye: Vector3, head: Vector3, props: Array) -> String:
	var d := head - eye
	var length := d.length() - BOOM_HEAD_M
	if length <= 0.0:
		return ""
	var stop := eye + d.normalized() * length
	var seg := AABB(eye, Vector3.ZERO).expand(stop).grow(BOOM_CLEAR_M)
	for pb: Array in props:
		var box: AABB = pb[1]
		if not seg.intersects(box):
			continue
		var steps := maxi(2, int(length / 0.25))
		for i in steps + 1:
			if _aabb_dist(box, eye.lerp(stop, float(i) / steps)) < BOOM_CLEAR_M:
				return pb[0]
	return ""


## Representative standing points per cell: the sample nearest each cell's centroid.
func cell_points(pts: Array) -> Dictionary:
	var acc := {}
	for p: Vector3 in pts:
		var k := dir.sector_for(p, -1)
		if not acc.has(k):
			acc[k] = []
		acc[k].append(p)
	var out := {}
	for k: int in acc:
		var c := Vector3.ZERO
		for p: Vector3 in acc[k]:
			c += p
		c /= float(acc[k].size())
		var best: Vector3 = acc[k][0]
		for p: Vector3 in acc[k]:
			if p.distance_squared_to(c) < best.distance_squared_to(c):
				best = p
		out[k] = best
	return out


## Framing at a level, from each cell's representative point: each active station's projected
## height (px) where it is in frame and seen, how many cells frame at least one station, and the
## largest single collider's share of the frame nearer than the captain (floors excluded; the
## lift's boxes count as "lift"). On the bridge at Z2 the spawn's own frame is measured too.
func framing_metrics(area: String, lv: int, pts: Array = []) -> Dictionary:
	var v: Dictionary = dir.level_view(lv, area)
	if pts.is_empty():
		pts = samples(area)
	var reps := cell_points(pts)
	var station_px := {}
	var station_cells := 0
	var worst_fg := 0.0
	var worst_fg_who := ""
	var worst_fg_cell := -1
	var keys := reps.keys()
	keys.sort()
	for k: int in keys:
		var p: Vector3 = reps[k]
		var pose := dir.resolve(v, p, k)
		var head := dir.head_of(v, p)
		if area == "bridge":
			var any := false
			for sid: String in ACTIVE_STATIONS:
				var hpx := station_height(pose, sid)
				if hpx > 0.0:
					any = true
					if not station_px.has(sid):
						station_px[sid] = []
					station_px[sid].append(hpx)
			if any:
				station_cells += 1
		var fg := foreground(pose, head)
		if fg.share > worst_fg:
			worst_fg = fg.share
			worst_fg_who = fg.who
			worst_fg_cell = k
	var r := {"view": str(v.id), "area": area, "level": lv, "framing": true, "cells": keys.size(), "foreground_share": snappedf(worst_fg, 0.001), "foreground_by": worst_fg_who, "foreground_cell": worst_fg_cell}
	if area == "bridge":
		var st := {}
		for sid: String in ACTIVE_STATIONS:
			var arr: Array = station_px.get(sid, [])
			arr.sort()
			st[sid] = {"seen_in_cells": arr.size(), "min_px": snappedf(arr[0], 0.1) if not arr.is_empty() else 0.0, "max_px": snappedf(arr[-1], 0.1) if not arr.is_empty() else 0.0}
		r.stations = st
		r.station_cells = station_cells
		var sp := spawn()
		var k0 := dir.sector_for(sp, -1)
		var spose := dir.resolve(v, sp, k0)
		var sfg := foreground(spose, dir.head_of(v, sp))
		r.spawn_foreground_share = snappedf(sfg.share, 0.001)
		r.spawn_foreground_by = sfg.who
		var seen := []
		for sid: String in ACTIVE_STATIONS:
			if station_height(spose, sid) > 0.0:
				seen.append(sid)
		r.spawn_stations = seen
		r.spawn_frame = frame_shares(spose)
	return r


## What fills a frame (any distance, floors excluded): the top colliders' shares, and the lift's
## (its boxes, guards and anything seen inside its opening, the platform included).
func frame_shares(pose: Transform3D) -> Dictionary:
	var count := {}
	var lift := 0
	var shaft := Rect2(5.5, -10.5, 5.0, 5.0) # glTF xz: the 4 m opening at ship (8, 8) and its guards
	for j in FG_H:
		for i in FG_W:
			var d := frame_dir(pose, (i + 0.5) / FG_W, (j + 0.5) / FG_H)
			var hit := occluder(pose.origin, pose.origin + d * 60.0)
			if hit.is_empty():
				continue
			var who := collider_name(hit)
			var at: Vector3 = hit.position
			if who == "lift" or who.begins_with("Guardrail 82") or (shaft.has_point(Vector2(at.x, at.z)) and at.y > 75.0):
				lift += 1
			if (hit.normal as Vector3).y > 0.7:
				continue
			count[who] = int(count.get(who, 0)) + 1
	var names := count.keys()
	names.sort_custom(func(a: String, b: String) -> bool: return count[a] > count[b])
	var top := []
	for n: String in names.slice(0, 3):
		top.append([n, snappedf(float(count[n]) / float(FG_W * FG_H), 0.001)])
	return {"top": top, "lift": snappedf(float(lift) / float(FG_W * FG_H), 0.001)}


## A station's projected height in px from a pose (0 when off frame or unseen).
func station_height(pose: Transform3D, sid: String) -> float:
	var box := AABB()
	var first := true
	for mesh_name: String in ACTIVE_STATIONS[sid]:
		var n := demo.geometry.find_child(mesh_name, true, false) as MeshInstance3D
		if n == null or not n.is_visible_in_tree():
			continue
		var a: AABB = n.global_transform * n.mesh.get_aabb()
		box = a if first else box.merge(a)
		first = false
	if first:
		return 0.0
	var centre := box.get_center()
	var sc := CameraDirector.screen_point(pose, centre, PX)
	if is_nan(sc.x) or not Rect2(Vector2.ZERO, PX).has_point(sc):
		return 0.0
	var hit := occluder(pose.origin, centre)
	if not hit.is_empty() and not str(collider_name(hit)) in ACTIVE_STATIONS[sid] and (hit.position as Vector3).distance_to(centre) > box.size.length() * 0.5:
		return 0.0
	var top := INF
	var bottom := -INF
	for i in 8:
		var sp := CameraDirector.screen_point(pose, box.get_endpoint(i), PX)
		if is_nan(sp.x):
			return 0.0
		top = minf(top, sp.y)
		bottom = maxf(bottom, sp.y)
	return bottom - top


func foreground(pose: Transform3D, head: Vector3) -> Dictionary:
	var near := pose.origin.distance_to(head) * 0.9
	var count := {}
	for j in FG_H:
		for i in FG_W:
			var d := frame_dir(pose, (i + 0.5) / FG_W, (j + 0.5) / FG_H)
			var hit := occluder(pose.origin, pose.origin + d * near)
			if hit.is_empty() or (hit.normal as Vector3).y > 0.7:
				continue
			var who := collider_name(hit)
			count[who] = int(count.get(who, 0)) + 1
	var best := ""
	var most := 0
	for who: String in count:
		if count[who] > most:
			most = count[who]
			best = who
	return {"share": float(most) / float(FG_W * FG_H), "who": best}


## Sky forward over every landing pose. "rail": the 72 walk_to bearings (15 m), the poses the
## design's floors apply to (§D4); "grid": the 2 m grid of bridge samples, the pose the game takes
## there (in place when its pole ray is clear, else after walking to the rail), reported.
func sky_metrics() -> Dictionary:
	var fwd: Dictionary = dir.views["sky_forward"]
	var rail := []
	var grid := []
	var none := 0
	for deg in range(0, 360, 5):
		var at: Variant = dir.anchor_of(fwd, Vector3(cos(deg_to_rad(deg)), 0.0, sin(deg_to_rad(deg))) * 10.0 + Vector3(0, DECK_Y, 0))
		var pose: Variant = _landing(fwd, at, false)
		if pose == null:
			none += 1
		else:
			rail.append(pose)
	for p: Vector3 in samples("bridge"):
		if absf(fposmod(p.x, SKY_GRID_M)) > 1e-3 or absf(fposmod(p.z, SKY_GRID_M)) > 1e-3:
			continue
		var pose: Variant = _landing(fwd, p, true)
		if pose == null:
			none += 1
		else:
			grid.append(pose)
	var spawn_pose: Variant = _landing(fwd, spawn(), true)
	var r := _sky_set(rail)
	r.merge({"view": "sky_forward", "rail_poses": rail.size(), "no_pose": none, "grid": _sky_set(grid), "grid_poses": grid.size(),
		"spawn_sky_fraction": snappedf(sky_fraction(spawn_pose), 0.001) if spawn_pose != null else 0.0,
		"spawn_pole_clearance_deg": pole_clearance(spawn_pose.origin) if spawn_pose != null else 0.0})
	return r


func _sky_set(poses: Array) -> Dictionary:
	var fr := []
	var worst_clear := float(POLE_MAX_DEG)
	for pose: Transform3D in poses:
		fr.append(sky_fraction(pose))
		worst_clear = minf(worst_clear, pole_clearance(pose.origin))
	fr.sort()
	return {"sky_fraction": {"worst": snappedf(fr[0], 0.001) if not fr.is_empty() else 0.0, "median": snappedf(fr[fr.size() / 2], 0.001) if not fr.is_empty() else 0.0}, "pole_clearance_deg": worst_clear}


func _landing(fwd: Dictionary, at: Variant, walk: bool) -> Variant:
	if at == null:
		return null
	var p: Vector3 = at
	var off: Variant = dir.choose_offset(fwd, p)
	if off == null and walk:
		var a: Variant = dir.anchor_of(fwd, p)
		if a == null:
			return null
		p = a
		off = dir.choose_offset(fwd, p)
	if off == null:
		return null
	return dir._sky(fwd, p, dir.sector_for(p, -1), off)


func sky_fraction(pose: Transform3D) -> float:
	var sky := 0
	for j in SKY_H:
		for i in SKY_W:
			var d := frame_dir(pose, (i + 0.5) / SKY_W, (j + 0.5) / SKY_H)
			if occluder(pose.origin, pose.origin + d * SKY_FAR_M).is_empty():
				sky += 1
	return float(sky) / float(SKY_W * SKY_H)


## The forward pole's clearance: the smallest tilt from +y (1 deg steps, 24 azimuths) at which a
## ray from the eye meets geometry within SKY_FAR_M; POLE_MAX_DEG when none does.
func pole_clearance(eye: Vector3) -> float:
	for tilt in range(0, POLE_MAX_DEG):
		for a in 24:
			var az := TAU * a / 24.0
			var d := Vector3.UP.rotated(Vector3(cos(az), 0, sin(az)), deg_to_rad(tilt))
			if not occluder(eye, eye + d * SKY_FAR_M).is_empty():
				return float(tilt)
	return float(POLE_MAX_DEG)


## The side view at its rail anchor: the captain clear and the stop's body direction (+x, 15 deg
## up) clear from the eye.
func side_metrics() -> Dictionary:
	var side: Dictionary = dir.views["sky_side"]
	var a: Variant = dir.anchor_of(side, spawn())
	if a == null:
		return {"view": "sky_side", "ok": false, "why": "no anchor"}
	var pose := dir.resolve(side, a, dir.sector_for(a, -1))
	var head := dir.head_of(side, a)
	var body := Vector3(cos(deg_to_rad(15.0)), sin(deg_to_rad(15.0)), 0)
	var captain_ok := clear_line(pose.origin, head)
	var body_hit := ray(pose.origin, pose.origin + body * SKY_FAR_M)
	return {"view": "sky_side", "anchor": [snappedf(a.x, 0.01), snappedf(a.z, 0.01)], "captain_clear": captain_ok, "body_clear": body_hit.is_empty(), "body_hit": collider_name(body_hit) if not body_hit.is_empty() else "", "ok": captain_ok and body_hit.is_empty()}


# ------------------------------------------------------------------ the report and thresholds

func evaluate(areas := ["bridge", "lower"]) -> Dictionary:
	var r := {"schema": "stapledons.deck.eval/1", "layout": str(layout.get("name", "shipped")), "views": []}
	for area: String in areas:
		var pts := samples(area)
		for lv in [1, 2, 3]:
			r.views.append(level_metrics(area, lv, pts))
		for lv in [2, 3]:
			r.views.append(framing_metrics(area, lv, pts))
	if "bridge" in areas:
		r.views.append(sky_metrics())
		r.views.append(side_metrics())
	return r


## Threshold failures as "<reason> <view>: <detail>" (reasons: clear-line, out-of-frame,
## captain-px, boom-intrusion, station-legibility, frame-dominance, sky-fraction, pole-clearance,
## no-sky-pose, sky-side). `t` is art/deck-layout-v1/thresholds.json.
static func failures(report: Dictionary, t: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	for v: Dictionary in report.views:
		var area := str(v.get("area", "bridge"))
		var tt: Dictionary = t.get(area, {})
		var id := "%s (%s)" % [v.view, area]
		if v.has("blocked"):
			var ceiling := int((tt.get("blocked_ceiling", {}) as Dictionary).get(str(v.level), 0))
			if int(v.blocked) > ceiling:
				out.append("clear-line %s: %d blocked > %d" % [id, v.blocked, ceiling])
			if int(v.out_of_frame) > 0:
				out.append("out-of-frame %s: %d" % [id, v.out_of_frame])
			if int(v.boom_intrusions) > int((tt.get("boom_intrusions_max", {}) as Dictionary).get(str(v.level), 0)):
				out.append("boom-intrusion %s: %d (%s)" % [id, v.boom_intrusions, v.get("intruders", {})])
			if int(v.level) == 2 and v.has("captain_px"):
				var lo := float(tt.get("z2_captain_px_min", 0.0))
				var hi := float(tt.get("z2_captain_px_max", 1e9))
				if float(v.captain_px.min) < lo or float(v.captain_px.max) > hi:
					out.append("captain-px %s: %.1f..%.1f outside %.0f..%.0f" % [id, v.captain_px.min, v.captain_px.max, lo, hi])
		if v.get("framing", false):
			var lvs := str(v.level)
			var fmax := float((tt.get("foreground_share_max", {}) as Dictionary).get(lvs, 1.0))
			if float(v.foreground_share) > fmax:
				out.append("frame-dominance %s Z%s: %s fills %.1f%% of the frame (cell %d) > %.0f%%" % [id, lvs, v.foreground_by, 100.0 * float(v.foreground_share), v.foreground_cell, 100.0 * fmax])
			if v.has("spawn_foreground_share") and float(v.spawn_foreground_share) > float((tt.get("spawn_foreground_share_max", {}) as Dictionary).get(lvs, 1.0)):
				out.append("frame-dominance %s Z%s at the spawn: %s fills %.1f%%" % [id, lvs, v.spawn_foreground_by, 100.0 * float(v.spawn_foreground_share)])
			if v.has("spawn_frame") and float(v.spawn_frame.lift) > float((tt.get("spawn_lift_share_max", {}) as Dictionary).get(lvs, 1.0)):
				out.append("lift-in-frame %s Z%s at the spawn: the lift fills %.1f%%" % [id, lvs, 100.0 * float(v.spawn_frame.lift)])
			if v.has("station_cells") and int(v.station_cells) < int((tt.get("station_cells_min", {}) as Dictionary).get(lvs, 0)):
				out.append("station-spread %s Z%s: %d cells frame a station < %d" % [id, lvs, v.station_cells, tt.station_cells_min[lvs]])
			if v.has("stations") and int(v.level) == 3:
				for sid: String in v.stations:
					var s: Dictionary = v.stations[sid]
					if int(s.seen_in_cells) < 1 or float(s.min_px) < float(tt.get("z3_station_px_min", 0.0)):
						out.append("station-legibility %s: %s %.1f px (seen in %d cells) < %.0f" % [id, sid, s.min_px, s.seen_in_cells, tt.z3_station_px_min])
		if str(v.view) == "sky_forward":
			if int(v.no_pose) > 0:
				out.append("no-sky-pose sky_forward: %d landing points have no clear pose" % v.no_pose)
			if float(v.sky_fraction.worst) < float(tt.get("sky_fraction_worst_min", 0.0)) or float(v.sky_fraction.median) < float(tt.get("sky_fraction_median_min", 0.0)):
				out.append("sky-fraction sky_forward: worst %.3f median %.3f < %.2f / %.2f" % [v.sky_fraction.worst, v.sky_fraction.median, tt.get("sky_fraction_worst_min", 0.0), tt.get("sky_fraction_median_min", 0.0)])
			if float(v.pole_clearance_deg) < float(tt.get("pole_clearance_deg_min", 0.0)):
				out.append("pole-clearance sky_forward: %.0f deg < %.0f" % [v.pole_clearance_deg, tt.pole_clearance_deg_min])
			if float(v.spawn_sky_fraction) < float(tt.get("spawn_sky_fraction_min", 0.0)):
				out.append("sky-fraction sky_forward at the spawn: %.3f < %.3f" % [v.spawn_sky_fraction, tt.spawn_sky_fraction_min])
			if float(v.spawn_pole_clearance_deg) < float(tt.get("spawn_pole_clearance_deg_min", 0.0)):
				out.append("pole-clearance sky_forward at the spawn: %.0f deg < %.0f" % [v.spawn_pole_clearance_deg, tt.spawn_pole_clearance_deg_min])
		if str(v.view) == "sky_side" and not v.ok:
			out.append("sky-side sky_side: captain clear %s, body clear %s %s" % [v.get("captain_clear"), v.get("body_clear"), v.get("body_hit", "")])
	return out


## One line per view.
static func summary(report: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	for v: Dictionary in report.views:
		var id := "%s (%s)" % [v.view, v.get("area", "bridge")]
		if v.has("blocked"):
			out.append("deck-layout %s: %d samples, %d blocked, %d out of frame, %d boom intrusions, captain px %s" % [id, v.samples, v.blocked, v.out_of_frame, v.boom_intrusions, v.get("captain_px", {})])
		elif v.get("framing", false):
			out.append("deck-layout %s framing Z%d: foreground %.1f%% (%s, cell %d)%s" % [id, v.level, 100.0 * float(v.foreground_share), v.foreground_by, v.foreground_cell, (", %d cells frame a station, spawn foreground %.1f%% (%s) frame %s stations %s, stations %s" % [v.station_cells, 100.0 * float(v.spawn_foreground_share), v.spawn_foreground_by, JSON.stringify(v.spawn_frame), v.spawn_stations, JSON.stringify(v.stations)]) if v.has("stations") else ""])
		elif str(v.view) == "sky_forward":
			out.append("deck-layout sky_forward: rail %d poses, sky fraction worst %.3f median %.3f, pole clearance %.0f deg; grid %d poses, worst %.3f median %.3f, clearance %.0f deg; %d without a pose; spawn %.3f, clearance %.0f deg" % [v.rail_poses, v.sky_fraction.worst, v.sky_fraction.median, v.pole_clearance_deg, v.grid_poses, v.grid.sky_fraction.worst, v.grid.sky_fraction.median, v.grid.pole_clearance_deg, v.no_pose, v.spawn_sky_fraction, v.spawn_pole_clearance_deg])
		else:
			out.append("deck-layout sky_side: anchor %s, captain clear %s, body clear %s %s" % [v.get("anchor"), v.get("captain_clear"), v.get("body_clear"), v.get("body_hit", "")])
	return out
