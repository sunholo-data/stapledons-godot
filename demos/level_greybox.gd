class_name LevelGreybox
extends RefCounted
## R2-LEVELS S1 (design_docs/planned/r2/levels.md §A1, §A5, §B8; ledger D-103, D-104): a level's
## layout (stapledons.level/1 with `pieces`) built in the engine as role-coloured primitives, so a
## layout can be walked, measured (LevelMetrics) and played before any Blender work. No art: the
## greybox may stay blocky (S1 is about routes), but platforms and catwalks the brief means to curve
## are `arc` pieces, since a curved route changes how the level feels (D-104).
## Pieces (ship frame: x, y = the bow, z = up; metres):
##   box   center [x, y, z], size [sx, sy, sz]
##   arc   an annular sector: center_xy [x, y], r [inner, outer], deg [from, to] (from +x toward +y),
##         top_z, thickness
##   ramp  from [x, y, z] to [x, y, z] (the top's centreline), width, thickness
## Each piece is a StaticBody3D "GB_<role>_<name>" with a collider and a role colour. A `surface`
## piece also gets a WALK_<name> mesh of its top face only, so the multi-height walk (WalkArea,
## height_at_near) stands the captain on it and never on its underside.

const COLOURS := {
	"surface": Color(0.86, 0.72, 0.5), "structure": Color(0.15, 0.45, 0.47), "route": Color(0.93, 0.5, 0.15),
	"find": Color(0.85, 0.2, 0.65), "fore": Color(0.25, 0.18, 0.35), "back": Color(0.45, 0.45, 0.5), "roof": Color(0.3, 0.32, 0.36),
}
const ARC_STEP_DEG := 5.0


## Builds the layout under `parent`. Returns {node, pieces, surfaces, walk: WalkArea, manifest}.
static func build(layout: Dictionary, parent: Node3D, agent_radius := 0.35) -> Dictionary:
	var node := Node3D.new()
	node.name = "LevelGreybox_%s" % str(layout.get("id", "level"))
	parent.add_child(node)
	var walk_root := Node3D.new()
	walk_root.name = "WalkSurfaces"
	walk_root.visible = false
	node.add_child(walk_root)
	var mats := {}
	var n := 0
	var surfaces := 0
	for pc: Dictionary in layout.get("pieces", []):
		var role := str(pc.role)
		if not mats.has(role):
			var m := StandardMaterial3D.new()
			m.albedo_color = COLOURS.get(role, Color.GRAY)
			m.roughness = 0.9
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
			mats[role] = m
		var quads := top_quads(pc)
		var body := StaticBody3D.new()
		body.name = "GB_%s_%s" % [role, str(pc.get("name", n))]
		node.add_child(body)
		var mi := MeshInstance3D.new()
		mi.material_override = mats[role]
		body.add_child(mi)
		var cs := CollisionShape3D.new()
		body.add_child(cs)
		if str(pc.shape) == "box":
			var c := ShipFrame.gltf_from_structure(pc.center)
			var sz := Vector3(float(pc.size[0]), float(pc.size[2]), float(pc.size[1]))
			body.position = c
			var bm := BoxMesh.new()
			bm.size = sz
			mi.mesh = bm
			var sh := BoxShape3D.new()
			sh.size = sz
			cs.shape = sh
		else:
			var mesh := prism(quads, float(pc.get("thickness", 0.3)))
			mi.mesh = mesh
			var cps := ConcavePolygonShape3D.new()
			cps.set_faces(mesh.get_faces())
			cps.backface_collision = true
			cs.shape = cps
		if role == "surface":
			var wm := MeshInstance3D.new()
			wm.name = "WALK_%s" % str(pc.get("name", n))
			wm.mesh = top_mesh(quads)
			walk_root.add_child(wm)
			surfaces += 1
		n += 1
	var walk := WalkArea.from_scene(walk_root, agent_radius)
	return {"node": node, "pieces": n, "surfaces": surfaces, "walk": walk, "manifest": manifest(layout)}


## The manifest a greybox build writes: the layout without its pieces, plus the layout's sha256.
static func manifest(layout: Dictionary) -> Dictionary:
	var m := layout.duplicate(true)
	m.erase("pieces")
	m["layout_sha256"] = layout_sha256(layout)
	m["source"] = "greybox"
	return m


static func layout_sha256(layout: Dictionary) -> String:
	return JSON.stringify(layout, "", true).sha256_text()


## The top face of a piece as glTF quads [a, b, c, d] (counter-clockwise seen from above).
static func top_quads(pc: Dictionary) -> Array:
	var out := []
	match str(pc.shape):
		"box":
			var c: Array = pc.center
			var s: Array = pc.size
			var z := float(c[2]) + float(s[2]) * 0.5
			var x0 := float(c[0]) - float(s[0]) * 0.5
			var x1 := float(c[0]) + float(s[0]) * 0.5
			var y0 := float(c[1]) - float(s[1]) * 0.5
			var y1 := float(c[1]) + float(s[1]) * 0.5
			out.append(_q([x0, y0, z], [x1, y0, z], [x1, y1, z], [x0, y1, z]))
		"arc":
			var cx := float(pc.center_xy[0])
			var cy := float(pc.center_xy[1])
			var r0 := float(pc.r[0])
			var r1 := float(pc.r[1])
			var a0 := float(pc.deg[0])
			var a1 := float(pc.deg[1])
			var z := float(pc.top_z)
			var steps := maxi(1, ceili(absf(a1 - a0) / ARC_STEP_DEG))
			for i in steps:
				var ta := deg_to_rad(lerpf(a0, a1, float(i) / steps))
				var tb := deg_to_rad(lerpf(a0, a1, float(i + 1) / steps))
				out.append(_q([cx + r0 * cos(ta), cy + r0 * sin(ta), z], [cx + r1 * cos(ta), cy + r1 * sin(ta), z],
					[cx + r1 * cos(tb), cy + r1 * sin(tb), z], [cx + r0 * cos(tb), cy + r0 * sin(tb), z]))
		"ramp":
			var f := Vector3(float(pc.from[0]), float(pc.from[1]), float(pc.from[2]))
			var t := Vector3(float(pc.to[0]), float(pc.to[1]), float(pc.to[2]))
			var along := Vector2(t.x - f.x, t.y - f.y).normalized()
			var side := Vector2(-along.y, along.x) * float(pc.width) * 0.5
			out.append(_q([f.x - side.x, f.y - side.y, f.z], [f.x + side.x, f.y + side.y, f.z],
				[t.x + side.x, t.y + side.y, t.z], [t.x - side.x, t.y - side.y, t.z]))
	return out


static func _q(a: Array, b: Array, c: Array, d: Array) -> Array:
	return [ShipFrame.gltf_from_structure(a), ShipFrame.gltf_from_structure(b), ShipFrame.gltf_from_structure(c), ShipFrame.gltf_from_structure(d)]


## Top faces only (the walk surface).
static func top_mesh(quads: Array) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for q: Array in quads:
		for v: Vector3 in [q[0], q[2], q[1], q[0], q[3], q[2]]:
			st.add_vertex(v)
	st.generate_normals()
	return st.commit()


## A closed slab under the top quads: top, bottom and the four sides of every quad.
static func prism(quads: Array, thickness: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var dn := Vector3.DOWN * thickness
	for q: Array in quads:
		var t: Array = q
		var b := [t[0] + dn, t[1] + dn, t[2] + dn, t[3] + dn]
		for v: Vector3 in [t[0], t[2], t[1], t[0], t[3], t[2], b[0], b[1], b[2], b[0], b[2], b[3]]:
			st.add_vertex(v)
		for i in 4:
			var j := (i + 1) % 4
			for v: Vector3 in [t[i], t[j], b[j], t[i], b[j], b[i]]:
				st.add_vertex(v)
	st.generate_normals()
	return st.commit()


## A route's end in glTF metres (from_at / to_at are ship frame).
static func route_end(rt: Dictionary, which: String) -> Vector3:
	return ShipFrame.gltf_from_structure(rt[which + "_at"])


## Ladders and hatches are use-point transfers (§B2, OQ5) until climb clips exist: from one end the
## captain moves to the other, stood on the walk surface there.
static func transfer(walk: WalkArea, rt: Dictionary, at: Vector3) -> Vector3:
	var a := route_end(rt, "from")
	var b := route_end(rt, "to")
	var dest := b if at.distance_to(a) <= at.distance_to(b) else a
	var y := walk.height_at_near(dest.x, dest.z, dest.y)
	return Vector3(dest.x, dest.y if is_nan(y) else y, dest.z)
