extends SceneTree
## Read-only contact diagnosis: authored use vs actual WALK/capsule constraints.
var demo: Node
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	demo=load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options={"stars":false,"background":false,"sky_state":"rest","sound":false}
	root.add_child(demo)
	await process_frame
	await physics_frame
	await physics_frame
	demo.auto=false;demo.journey_auto_tick=false;demo.set_process(false)
	var rows:=[]
	for station in ["voyage","crew"]:
		var old: Vector3=demo.consoles.stations[station].use
		var pathpos:=old
		var samples:=[]
		for i in 61:
			var p:=old+Vector3.FORWARD*(float(i)*.025)
			if i>0:pathpos=demo.walk_bridge.step(pathpos,Vector3.FORWARD*.025)
			var shape:=CapsuleShape3D.new();shape.radius=.35;shape.height=1.8
			var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape
			query.transform=Transform3D(Basis.IDENTITY,p+Vector3.UP*.91)
			var hits: Array=demo.camera.get_world_3d().direct_space_state.intersect_shape(query)
			samples.append({"advance_m":float(i)*.025,"gltf_m":[p.x,p.y,p.z],"walkable":demo.walk_bridge.is_walkable(p),"step_reached":pathpos.distance_to(p)<.01,"capsule_hits":hits.map(func(h:Dictionary)->String:return String(h.collider.get_parent().name))})
		rows.append({"station":station,"authored_gltf_m":[old.x,old.y,old.z],"mesh_box":str(demo.consoles._mesh(ShipConsoles.STATIONS[station].walk).box),"samples":samples})
	var f:=FileAccess.open("res://build/bridge-operator-probe.json",FileAccess.WRITE);f.store_string(JSON.stringify(rows,"  "));f.close()
	print("bridge-operator-probe: recorded ",rows.size()," original desks; no furniture extensions loaded")
	demo.queue_free();await process_frame;quit()
