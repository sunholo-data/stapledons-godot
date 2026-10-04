extends RefCounted
## Local Commons kit in the measured ship frame. Production assets stay untouched.
static func asset(file: String) -> String:
	var source := "res://assets/ship_commons/"+file
	return source if FileAccess.file_exists(source) else "res://ship_commons_bundle/"+file+".bin"
static func install(demo: Node) -> Dictionary:
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(asset("manifest.json")))
	var files: Dictionary=manifest.assets
	var visual:=AreaBundle.load_glb(asset(files.get("painted",files.blockout)))
	var collider:=AreaBundle.load_glb(asset(files.collision))
	var nav:=AreaBundle.load_glb(asset(files.walk))
	var coarse: Node3D=AreaBundle.load_glb(asset(files.coarse)) if files.has("coarse") else null
	if visual==null or collider==null or nav==null:
		push_error("Commons kit incomplete");return {}
	var removed:=_remove_guard(demo.geometry,manifest.remove_base_guard_names)
	if removed!=1:
		visual.free();collider.free();nav.free()
		push_error("Commons connection needs exactly one old landing guard");return {}
	visual.name="CommonsVisual";demo.geometry.add_child(visual)
	if coarse!=null:
		coarse.name="CommonsCoarse";demo.geometry.add_child(coarse);coarse.visible=false
	collider.name="CommonsCollision";demo.geometry.add_child(collider)
	demo._collision(collider);collider.visible=false
	demo.walk_lower=WalkArea.from_scene(nav,.35);demo._walk_nodes.append(nav)
	if demo.active_level==1:demo.walk=demo.walk_lower
	return {"visual":visual,"coarse":coarse,"collision":collider,"walk":nav,"manifest":manifest}
static func update_detail(kit: Dictionary, eye: Vector3) -> void:
	if kit.is_empty() or kit.get("coarse")==null:return
	var near:=eye.distance_to(Vector3(26,61,-10))<=100.
	kit.visual.visible=near;kit.coarse.visible=not near
static func _remove_guard(n: Node, names: Array) -> int:
	var count:=0
	for child in n.get_children():
		var old_guard: bool=child is MeshInstance3D and child.global_position.distance_to(Vector3(14,57.65,-8))<.02
		if String(child.name) in names or old_guard:
			n.remove_child(child);child.free();count+=1
		else:count+=_remove_guard(child,names)
	return count
