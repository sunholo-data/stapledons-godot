extends SceneTree
var passes:=0
var failures:=0
func check(name: String, value: bool) -> void:
	if value:passes+=1
	else:failures+=1
	print("  %s %s" % ["ok" if value else "FAIL",name])
func _initialize() -> void:
	if not FileAccess.file_exists("res://assets/ship_commons/manifest.json"):
		check("measured Commons assets",false)
		print("ship-commons: 0 passed, 1 failures");quit(1);return
	_run.call_deferred()
func _run() -> void:
	var d: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/ship_commons/manifest.json"))
	var root_node:=AreaBundle.load_glb("res://assets/ship_commons/walk.glb")
	check("separate Commons WALK export",root_node!=null)
	if root_node==null:quit(1);return
	var walk:=WalkArea.from_scene(root_node,.35)
	check("same safe lift landing",walk.is_walkable(Vector3(8,57,-4.8)))
	check("lift hole remains nonwalkable",not walk.is_walkable(Vector3(8,57,-8)))
	check("spire inaccessible",not walk.is_walkable(Vector3(0,57,0)))
	var start:=Vector3(8,57,-4.8)
	var targets:=[Vector3(16,57,-4.8),Vector3(26,57,3),Vector3(26,57,-8),Vector3(6,57,-4.5),Vector3(35,57,-10),Vector3(26,57,-18)]
	if d.get("revision",1)>=2:targets.append_array([Vector3(18.75,57,3),Vector3(26,57,-12.5)])
	for target in targets:
		var route:=walk.path(start,target,40000)
		check("connected route to "+str(target),not route.is_empty())
		for point in route:
			if not walk.is_walkable(point):check("route stays in active Commons",false)
			if absf(point.y-57.)>.05:check("route at Commons height",false)
	check("courtyard camera safe",walk.is_walkable(Vector3(23,57,3)))
	check("pavilion interior camera safe",walk.is_walkable(Vector3(26,57,-10)))
	root_node.free()
	var demo: Node=load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options={"background":false,"stars":false,"commons":false,"sky_state":"rest"};root.add_child(demo)
	await process_frame
	var kit: Dictionary=load("res://demos/ship_commons.gd").install(demo)
	check("runtime connection removes one old guard",not kit.is_empty())
	check("detail/coarse share one atlas resource",load("res://demos/ship_commons.gd")._paint_material(kit.visual)==load("res://demos/ship_commons.gd")._paint_material(kit.coarse))
	check("bridge still active initially",demo.walk==demo.walk_bridge)
	await physics_frame
	var shape:=CapsuleShape3D.new();shape.radius=.35;shape.height=1.8
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape
	var space: PhysicsDirectSpaceState3D=demo.geometry.get_world_3d().direct_space_state
	for target in targets:
		var clear:=true
		for point in demo.walk_lower.path(start,target,40000):
			query.transform=Transform3D(Basis.IDENTITY,point+Vector3.UP*.95)
			if not space.intersect_shape(query,1).is_empty():clear=false;break
		check("real capsule clearance to "+str(target),clear)
	demo.queue_free();await process_frame
	print("ship-commons: %d passed, %d failures" % [passes,failures]);quit(1 if failures else 0)
