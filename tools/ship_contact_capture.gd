extends SceneTree
func _initialize()->void:_run.call_deferred()
func _run()->void:
	root.size=Vector2i(1280,720);UiScale.configure(root,true)
	var demo:Node=load('res://demos/ship_geometry_demo.tscn').instantiate()
	demo.setup_options={'size':Vector2i(1280,720),'sky_state':'rest'};root.add_child(demo);await process_frame
	demo.auto=false;demo.journey_auto_tick=false
	demo.set_preset('bridge');demo.camera.follow(demo.avatar_pos,-18.,.47,3.);demo._sync_observer()
	DirAccess.make_dir_recursive_absolute('res://renders/ship_contact')
	var original:=Vector2(demo.lighting.key.shadow_bias,demo.lighting.key.shadow_normal_bias)
	for mode in ['original','low_bias']:
		demo.lighting.key.shadow_bias=original.x if mode=='original' else .015
		demo.lighting.key.shadow_normal_bias=original.y if mode=='original' else .08
		for frame in 20:await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png('res://renders/ship_contact/'+mode+'.png')
	var query:=PhysicsRayQueryParameters3D.create(demo.avatar_pos+Vector3.UP*10.,demo.avatar_pos-Vector3.UP*20.)
	query.hit_back_faces=true
	await physics_frame
	var hit:Dictionary=demo.geometry.get_world_3d().direct_space_state.intersect_ray(query)
	print('captain-contact: foot=',demo.avatar_pos,' visual-floor-hit=',hit.get('position','none'),' sprite-anchor=',demo.avatar.anchor_local())
	_support(demo.geometry,demo.avatar_pos)
	demo.queue_free();await process_frame;print('ship-contact-capture: OK');quit()
func _support(node:Node,foot:Vector3)->void:
	if node is MeshInstance3D and node.mesh!=null:
		for surface in node.mesh.get_surface_count():
			var arrays:Array=node.mesh.surface_get_arrays(surface)
			var points:PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var indices:PackedInt32Array=arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
			if indices.is_empty():
				indices.resize(points.size())
				for i in points.size():indices[i]=i
			var best:=-INF
			for k in range(0,indices.size()-2,3):
				var a:Vector3=node.global_transform*points[indices[k]];var b:Vector3=node.global_transform*points[indices[k+1]];var c:Vector3=node.global_transform*points[indices[k+2]]
				var hit:Variant=Geometry3D.ray_intersects_triangle(foot+Vector3.UP*2.,Vector3.DOWN,a,b,c)
				if hit==null:hit=Geometry3D.ray_intersects_triangle(foot+Vector3.UP*2.,Vector3.DOWN,a,c,b)
				if hit!=null and hit.y>=foot.y-3.:best=maxf(best,hit.y)
			if node.name=='deck_body_01':print('deck-bounds: ',node.get_aabb(),' transform=',node.global_transform)
			if is_finite(best):print('visual-support: ',node.name,' y=',best,' feet-gap=',foot.y-best)
	for child in node.get_children():_support(child,foot)
