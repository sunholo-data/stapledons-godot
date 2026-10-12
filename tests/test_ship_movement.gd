extends SceneTree
var failures:=0
var passes:=0
func check(label:String,ok:bool)->void:
	if ok:passes+=1
	else:failures+=1
	print("%s %s" % ["ok" if ok else "FAIL",label])
func _initialize()->void:_run.call_deferred()
func _run()->void:
	var demo:Node=load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options={"stars":false,"background":false};root.add_child(demo);await process_frame
	demo.auto=false
	if not demo.has_method("walk_motion"):
		check("faster measured traversal is available",false)
	else:
		var start:Vector3=demo.avatar_pos
		demo.walk_motion(Vector2(1,0),1.)
		var distance:float=demo.avatar_pos.distance_to(start)
		check("one second traverses a brisk 3.5 metres",distance>3.4 and distance<3.6)
		demo.avatar_pos=start
		for step in 60:demo.walk_motion(Vector2(1,0),1./60.)
		check("distance is stable across frame rates",absf(demo.avatar_pos.distance_to(start)-distance)<.02)
		demo.avatar_pos=start;demo.walk_motion(Vector2(1,1),1.)
		check("diagonal motion has same speed",absf(demo.avatar_pos.distance_to(start)-distance)<.05)
		for step in 360:demo.walk_motion(Vector2(1,0),1./30.)
		check("fast traversal stays on authored walk surface",demo.walk.is_walkable(demo.avatar_pos))
		check("bridge edge cannot be crossed",Vector2(demo.avatar_pos.x,demo.avatar_pos.z).length()<=22.1)
		demo.avatar_pos=start;demo.camera.follow(start,-18.,0.,0.)
		demo.walk_motion(Vector2(-1,0),2.)
		var stalled:Vector3=demo.avatar_pos
		demo.avatar_pos=start
		for frame in 120:demo.walk_motion(Vector2(-1,0),1./60.)
		check("stalled frame cannot jump guarded lift opening",stalled.distance_to(demo.avatar_pos)<.2)
	print("ship-movement: %d passed, %d failures" % [passes,failures])
	demo.queue_free();await process_frame;quit(1 if failures else 0)
