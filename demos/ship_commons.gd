extends RefCounted
## Local Commons kit in the measured ship frame. Production assets stay untouched.
static func asset(file: String) -> String:
	var source := "res://assets/ship_commons/"+file
	return source if FileAccess.file_exists(source) else "res://ship_commons_bundle/"+file+".bin"
static func load_mesh(file: String) -> Node3D:
	var document:=GLTFDocument.new();var state:=GLTFState.new()
	# Per-mesh AABB compression quantizes detail/coarse differently. Preserve
	# authored metre positions for this measured review kit only.
	var error:=document.append_from_buffer(FileAccess.get_file_as_bytes(file),"",state,GLTFDocument.IMPORT_FLAG_FORCE_DISABLE_MESH_COMPRESSION)
	return document.generate_scene(state) as Node3D if error==OK else null
static func install(demo: Node) -> Dictionary:
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(asset("manifest.json")))
	var files: Dictionary=manifest.assets
	var visual:=load_mesh(asset(files.get("painted",files.blockout)))
	var collider:=load_mesh(asset(files.collision))
	var nav:=load_mesh(asset(files.walk))
	var coarse: Node3D=load_mesh(asset(files.coarse)) if files.has("coarse") else null
	if visual==null or collider==null or nav==null:
		push_error("Commons kit incomplete");return {}
	var removed:=_remove_guard(demo.geometry,manifest.remove_base_guard_names)
	if removed!=1:
		visual.free();collider.free();nav.free()
		push_error("Commons connection needs exactly one old landing guard");return {}
	visual.name="CommonsVisual";demo.geometry.add_child(visual)
	if coarse!=null:
		_share_material(coarse,_paint_material(visual))
		coarse.name="CommonsCoarse";demo.geometry.add_child(coarse);coarse.visible=false
	collider.name="CommonsCollision";demo.geometry.add_child(collider)
	demo._collision(collider);collider.visible=false
	demo.walk_lower=WalkArea.from_scene(nav,.35);demo._walk_nodes.append(nav)
	if demo.active_level==1:demo.walk=demo.walk_lower
	return {"visual":visual,"coarse":coarse,"collision":collider,"walk":nav,"manifest":manifest}
static func update_detail(kit: Dictionary, eye: Vector3) -> void:
	if kit.is_empty() or kit.get("coarse")==null:return
	var center: Array=kit.manifest.get("lod_center_ship_m",[26,10,61]) if kit.has("manifest") else [26,10,61]
	var near:=eye.distance_to(Vector3(center[0],center[2],-center[1]))<=100.
	kit.visual.visible=near;kit.coarse.visible=not near
static func _paint_material(n: Node) -> Material:
	if n is MeshInstance3D and n.mesh!=null:return n.mesh.surface_get_material(0)
	for child in n.get_children():
		var material:=_paint_material(child)
		if material!=null:return material
	return null
static func _share_material(n: Node, material: Material) -> void:
	if material==null:return
	if n is MeshInstance3D and n.mesh is ArrayMesh:
		for surface in n.mesh.get_surface_count():n.mesh.surface_set_material(surface,material)
	for child in n.get_children():_share_material(child,material)
static func _remove_guard(n: Node, names: Array) -> int:
	var count:=0
	for child in n.get_children():
		var old_guard: bool=child is MeshInstance3D and child.global_position.distance_to(Vector3(14,57.65,-8))<.02
		if String(child.name) in names or old_guard:
			n.remove_child(child);child.free();count+=1
		else:count+=_remove_guard(child,names)
	return count
