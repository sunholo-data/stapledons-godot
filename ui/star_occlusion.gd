extends RefCounted
## Physicsless BVHs of visible opaque surfaces. Geometry lacking collision
## still occludes; current node transforms/LOD visibility are read every update.
var meshes: Array = []
var active: Array = []
func build(root: Node) -> void:
	meshes.clear()
	_collect(root)
func _collect(node: Node) -> void:
	if node is MeshInstance3D and node.mesh != null:
		var faces := PackedVector3Array()
		for s in node.mesh.get_surface_count():
			if node.mesh is ImmediateMesh:continue # diagnostic line guides
			if node.mesh is ArrayMesh and node.mesh.surface_get_primitive_type(s) != Mesh.PRIMITIVE_TRIANGLES:continue
			var material: Material = node.get_active_material(s)
			# Alpha-cutout sprites and unknown custom shaders aren't solid masks.
			if material is BaseMaterial3D and material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:continue
			# Only explicitly tagged cutout shaders may omit their rectangle;
			# unknown/opaque custom surfaces conservatively block identification.
			if material is ShaderMaterial and material.get_meta("identification_cutout",false):continue
			var arrays: Array = node.mesh.surface_get_arrays(s)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var indices = arrays[Mesh.ARRAY_INDEX]
			if indices != null and indices.size() > 0:
				for i in indices:faces.append(vertices[i])
			else:faces.append_array(vertices)
		if not faces.is_empty():
			var tree := TriangleMesh.new()
			if tree.create_from_faces(faces):meshes.append({node=node, tree=tree, bounds=node.mesh.get_aabb()})
	for child in node.get_children():_collect(child)
func refresh(camera: Camera3D) -> void:
	active.clear()
	for mesh in meshes:
		if not is_instance_valid(mesh.node):continue
		var node: MeshInstance3D = mesh.node
		if is_instance_valid(node) and node.is_visible_in_tree() and node.layers & camera.cull_mask:
			active.append({tree=mesh.tree,bounds=mesh.bounds,inverse=node.global_transform.affine_inverse()})
func blocked(eye: Vector3, direction: Vector3) -> bool:
	for mesh in active:
		var inverse: Transform3D = mesh.inverse
		var local_eye := inverse*eye
		var local_dir := inverse.basis*direction
		if mesh.bounds.intersects_ray(local_eye,local_dir) == null:continue
		if not mesh.tree.intersect_ray(local_eye,local_dir).is_empty():return true
	return false
