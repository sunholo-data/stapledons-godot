extends SceneTree
## Independent mesh check, including negative-control malformed manifests.
const EXPECTED := [82,57,32,7,-18,-43,-68]
var failures := 0
func check(label: String, ok: bool) -> void:
	print("  %s %s" % ["ok" if ok else "FAIL", label])
	if not ok: failures += 1
func _initialize() -> void:
	var file := "res://assets/ship_demo/manifest.json"
	if not OS.get_cmdline_user_args().is_empty(): file = OS.get_cmdline_user_args()[0]
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(file))
	if not d is Dictionary:
		check("manifest schema", false); quit(1); return
	check("seven tiers", d.get("deck_heights_ship_m", []).size() == 7)
	for i in mini(7,d.get("deck_heights_ship_m", []).size()):
		check("tier height %d" % i, float(d["deck_heights_ship_m"][i]) == EXPECTED[i])
	check("five metre envelope", float(d.get("lower_inner_envelope_m",0)) == 95.0)
	var scene := AreaBundle.load_glb("res://assets/ship_demo/ship.glb")
	check("real mesh export", scene != null)
	if scene == null: quit(1); return
	var faces := PackedVector3Array()
	_scan(scene,Transform3D.IDENTITY,faces)
	check("opaque shaft opening", _shaft_clear(faces))
	var bridge := AreaBundle.load_glb("res://assets/ship_demo/walk_bridge.glb")
	var lower := AreaBundle.load_glb("res://assets/ship_demo/walk_lower.glb")
	var wb := WalkArea.from_scene(bridge,.35)
	var wl := WalkArea.from_scene(lower,.35)
	check("bridge landing safe", wb.is_walkable(Vector3(8,82,-4.8)))
	check("lower landing safe", wl.is_walkable(Vector3(8,57,-4.8)))
	check("bridge hole nonwalkable", not wb.is_walkable(Vector3(8,82,-8)))
	check("lower hole nonwalkable", not wl.is_walkable(Vector3(8,57,-8)))
	check("separate lower height", absf(wl.height_at(8,-4.8)-57) < .001)
	scene.free();bridge.free();lower.free()
	print("validate-ship-demo: %s" % ("OK" if failures==0 else "FAIL"));quit(1 if failures else 0)
func _scan(n: Node, xf: Transform3D, faces: PackedVector3Array) -> void:
	if n is Node3D: xf = xf * n.transform
	if n is MeshInstance3D and n.mesh != null:
		var lower := String(n.name).begins_with("Deck")
		for v in n.mesh.get_faces():
			var w: Vector3 = xf*v
			faces.append(w)
			if w.length()>100.001: check("physical vertex inside bubble",false)
			if lower and w.length()>95.001: check("lower floor envelope",false)
	for child in n.get_children(): _scan(child,xf,faces)
func _shaft_clear(faces: PackedVector3Array) -> bool:
	for x in [6.2,8.,9.8]:
		for z in [-6.2,-8.,-9.8]:
			for i in range(0,faces.size(),3):
				if Geometry3D.segment_intersects_triangle(Vector3(x,83.4,z),Vector3(x,55.5,z),faces[i],faces[i+1],faces[i+2]) != null: return false
	return true
