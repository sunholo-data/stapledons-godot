extends SceneTree
var passes:=0
var failures:=0
func check(label: String, value: bool) -> void:
	if value:passes+=1
	else:failures+=1
	print("  %s %s" % ["ok" if value else "FAIL",label])
func _initialize() -> void:
	if not FileAccess.file_exists("res://demos/ship_demo_lift.gd"):
		check("lift controller exists",false);print("ship-demo-lift: 0 passed, 1 failures");quit(1);return
	_run.call_deferred()
func _run() -> void:
	var demo: Node=load("res://demos/ship_geometry_demo.tscn").instantiate();root.add_child(demo)
	await process_frame
	demo.auto=false
	check("real scene initialized",demo.ready_ok)
	var lift: Node3D=demo.lift
	demo.avatar_pos=Vector3(8,82,-4.8)
	check("can board bridge",lift.board())
	check("boarding blocks reentry",not lift.board())
	lift.advance(.81)
	check("attached while descending",demo.avatar.get_parent()==lift.platform)
	check("bridge gate closes after departure",lift.gates[0].visible)
	var shape:=CapsuleShape3D.new();shape.radius=.35;shape.height=1.8
	var clear:=true
	for i in 110:
		lift.advance(.1)
		var q:=PhysicsShapeQueryParameters3D.new();q.shape=shape;q.transform=Transform3D(Basis.IDENTITY,Vector3(8,lift.platform.position.y+.95,-8))
		if not demo.camera.get_world_3d().direct_space_state.intersect_shape(q).is_empty():clear=false
	check("swept capsule clears authored static geometry",clear)
	for i in 10:lift.advance(.1)
	check("lower ready",lift.state=="lower_ready")
	check("exact 25m route",absf(lift.platform.position.y-57)<.01)
	check("active lower WALK",demo.walk==demo.walk_lower and absf(demo.walk.height_at(8,-4.8)-57)<.001)
	check("safe detached lower spawn",demo.avatar.get_parent()==demo.geometry and demo.walk.is_walkable(demo.avatar_pos))
	check("lower opening protected when platform departs",lift.gates[0].visible)
	check("can return",lift.board())
	for i in 130:lift.advance(.1)
	check("bridge ready after return",lift.state=="bridge_ready")
	check("roundtrip endpoint centimetre",demo.avatar_pos.distance_to(Vector3(8,82,-4.8))<.01)
	check("one captain",demo.avatar.get_parent()==demo.geometry)
	demo.avatar_pos=Vector3(18,82,9)
	check("cannot board remotely",not lift.board())
	demo.queue_free();await process_frame
	print("ship-demo-lift: %d passed, %d failures" % [passes,failures]);quit(1 if failures else 0)
