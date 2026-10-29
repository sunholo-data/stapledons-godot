extends RefCounted
## The legacy kit is one visual mesh and material-batched collision. Split it for the S3 camera
## fades while preserving every source triangle, UV, normal and material. S4 exports authored
## modules instead; this is a presentation adapter for the existing asset, not an art generator.
static func split(kit: Dictionary) -> void:
	if kit.get("stage_chunks",false):return
	var sources: Array=[];var groups: Array=[];var stack: Array=[kit.visual]
	while not stack.is_empty():
		var node: Node=stack.pop_back()
		if node is MeshInstance3D and node.mesh!=null:sources.append(node)
		stack.append_array(node.get_children())
	for source: MeshInstance3D in sources:
		var group:=Node3D.new();group.name="CommonsStageChunks";group.transform=source.transform
		source.get_parent().add_child(group);groups.append(group)
		var builders: Dictionary={}
		for surface in source.mesh.get_surface_count():
			var arrays:=source.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
			var uvs: PackedVector2Array=arrays[Mesh.ARRAY_TEX_UV]
			var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
			var count:=indices.size() if not indices.is_empty() else vertices.size()
			for face in range(0,count,3):
				var ids: Array=[];var center:=Vector3.ZERO;var highest:=-INF
				for offset in 3:
					var i:=indices[face+offset] if not indices.is_empty() else face+offset
					ids.append(i);center+=vertices[i]/3.
					highest=maxf(highest,(source.global_transform*vertices[i]).y)
				var world:=source.global_transform*center
				var key:="floor_%d" % surface if highest<=57.10 else "%d_%d_%d" % [surface,floori(world.x/8.),floori(world.z/8.)]
				if not builders.has(key):
					var tool:=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES)
					builders[key]={"tool":tool,"material":source.mesh.surface_get_material(surface),"floor":highest<=57.10}
				var builder: SurfaceTool=builders[key].tool
				for i: int in ids:
					if normals.size()>i:builder.set_normal(normals[i])
					if uvs.size()>i:builder.set_uv(uvs[i])
					builder.add_vertex(vertices[i])
		for key: String in builders:
			var row: Dictionary=builders[key]
			var mi:=MeshInstance3D.new();mi.name="CommonsChunk_"+key;mi.mesh=row.tool.commit()
			mi.mesh.surface_set_material(0,row.material);mi.material_override=source.material_override
			group.add_child(mi);mi.create_trimesh_collision()
			if not row.floor:mi.add_to_group(CameraDirector.OCCLUDER_GROUP)
		source.visible=false
	kit.stage_chunks=true;kit.chunk_groups=groups;kit.original_visuals=sources
	set_active(kit,true)

static func set_active(kit: Dictionary, active: bool) -> void:
	if not kit.get("stage_chunks",false):return
	for source: MeshInstance3D in kit.original_visuals:source.visible=not active
	for node: Node in kit.get("stage_extra_occluders",[]):
		if active:node.add_to_group(CameraDirector.OCCLUDER_GROUP)
		else:node.remove_from_group(CameraDirector.OCCLUDER_GROUP)
	for group: Node3D in kit.chunk_groups:
		group.visible=active
		_collision_layers(group,1 if active else 0)
	_collision_layers(kit.collision,0 if active else 1)

static func _collision_layers(node: Node, layer: int) -> void:
	if node is CollisionObject3D:node.collision_layer=layer;node.collision_mask=layer
	for child: Node in node.get_children():_collision_layers(child,layer)
