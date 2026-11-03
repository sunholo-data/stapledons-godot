extends SceneTree
## R3-COMMS-V2 (Mark 2026-11-03, "the ship railings around the bridge are going through the screens"): no
## part of a bridge monitor (its frame, lip and stalk from bridge_monitors.glb, and the live face quad
## BridgeMonitor places) intersects any other prop of the bridge (bridge_props.glb: the bow rail, its posts,
## lamps and fronds, the desks; ship.glb: the deck's own fittings). make monitor-rail-test (headless).
##   clear    every monitor triangle against every scene triangle near it: no edge of either crosses the
##            other (exact segment-triangle tests after a box prefilter); reported per monitor. A stalk's foot
##            standing on the deck (deck_*) is contact, not a crossing
##   control  the clocks monitor moved down and outboard into the rail (its face bottom at 0.45 m, its
##            centre 0.35 m further out) must be caught
## Geometry only: the game's own assets and placement, nothing computed that the game would show.

const SCENE_FILES := ["res://assets/ship_demo/bridge_props.glb", "res://assets/ship_demo/ship.glb"]
const MONITORS := "res://assets/ship_demo/bridge_monitors.glb"
var failures := 0
var passes := 0


func check(label: String, ok: bool) -> void:
	if ok:
		passes += 1
	else:
		failures += 1
	print("%s %s" % ["ok" if ok else "FAIL", label])


func _initialize() -> void:
	_run.call_deferred()


## Every triangle of the meshes under `root` in world space, with its owner's name: [[a, b, c, name], ...].
func tris_of(root: Node, keep: Callable) -> Array:
	var out: Array = []
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		stack.append_array(n.get_children())
		if n is MeshInstance3D and (n as MeshInstance3D).mesh != null and keep.call(n):
			var xf := (n as MeshInstance3D).global_transform
			var f := (n as MeshInstance3D).mesh.get_faces()
			for i in range(0, f.size(), 3):
				out.append([xf * f[i], xf * f[i + 1], xf * f[i + 2], String(n.name)])
	return out


func box_of(t: Array) -> AABB:
	var b := AABB(t[0], Vector3.ZERO)
	b = b.expand(t[1])
	return b.expand(t[2])


## True when the triangles cross: an edge of either passes through the other.
func cross(p: Array, q: Array) -> bool:
	for k in 3:
		if Geometry3D.segment_intersects_triangle(p[k], p[(k + 1) % 3], q[0], q[1], q[2]) != null:
			return true
		if Geometry3D.segment_intersects_triangle(q[k], q[(k + 1) % 3], p[0], p[1], p[2]) != null:
			return true
	return false


## The scene triangles that cross monitor triangles `mt`: [scene name, monitor part] pairs (unique).
func hits(mt: Array, scene: Array) -> Array:
	var mb := box_of(mt[0])
	for t in mt:
		mb = mb.merge(box_of(t))
	mb = mb.grow(0.01)
	var near: Array = []
	for t in scene:
		var b := box_of(t)
		if b.intersects(mb):
			near.append([t, b])
	var out := {}
	for m in mt:
		var b := box_of(m).grow(0.001)
		for e: Array in near:
			if str(e[0][3]).begins_with("deck_") and str(m[3]).ends_with("_stand"):
				continue # a stalk's foot stands on the deck
			if (e[1] as AABB).intersects(b) and cross(m, e[0]):
				out["%s x %s" % [e[0][3], m[3]]] = true
	return out.keys()


func load_scene(path: String) -> Node:
	var doc := GLTFDocument.new()
	var st := GLTFState.new()
	if doc.append_from_file(ProjectSettings.globalize_path(path), st) != OK:
		return null
	var n := doc.generate_scene(st)
	root.add_child(n)
	return n


func _run() -> void:
	var scene: Array = []
	for f: String in SCENE_FILES:
		var n := load_scene(f)
		check("loaded %s" % f.get_file(), n != null)
		if n != null:
			await process_frame
			scene.append_array(tris_of(n, func(_m: Node) -> bool: return true))
	var mons := load_scene(MONITORS)
	check("loaded bridge_monitors.glb", mons != null)
	await process_frame
	var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://assets/ship_demo/manifest.json"))
	var spec: Dictionary = manifest.get("monitors", {}).duplicate()
	spec.erase("about")
	var holder := Node3D.new()
	root.add_child(holder)
	var faces := BridgeMonitor.build(holder, spec)
	await process_frame
	check("four monitors in the manifest and the prop", faces.size() == 4)
	var parts := {}
	for m: BridgeMonitor in faces:
		var mine := tris_of(mons, func(n: Node) -> bool: return String(n.name) == "monitor_" + m.id or String(n.name).begins_with("monitor_%s_" % m.id))
		mine.append_array(tris_of(m.quad, func(_n: Node) -> bool: return true))
		parts[m.id] = mine
		var hit := hits(mine, scene)
		check("clear: monitor %s (%d triangles: frame, lip, stalk, face) crosses nothing of the bridge (%s)" % [m.id, mine.size(), ", ".join(hit.slice(0, 6))], mine.size() > 100 and hit.is_empty())
	# control: the clocks monitor pushed into the rail must be caught
	var c: Dictionary = spec.clocks
	var out := Vector3(float(c.screen_ship_m[0]), 0.0, -float(c.screen_ship_m[1])).normalized()
	var drop := out * 0.35 + Vector3.DOWN * (float(c.screen_ship_m[2]) - 82.0 - 1.125 - 0.45)
	var moved: Array = []
	for t: Array in parts.clocks:
		moved.append([t[0] + drop, t[1] + drop, t[2] + drop, t[3]])
	var bad := hits(moved, scene)
	check("control: the clocks monitor moved into the rail is caught (%d crossings, e.g. %s)" % [bad.size(), ", ".join(bad.slice(0, 3))], bad.any(func(h: String) -> bool: return h.begins_with("rim_rail")))
	print("monitor-rail: %d passed, %d failures" % [passes, failures])
	quit(1 if failures else 0)
