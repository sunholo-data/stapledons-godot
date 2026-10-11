extends SceneTree
## Real Mars selection/review/commit through the Navigation station.
var demo:Node
var failures:=0
func _initialize()->void:run.call_deferred()
func settle()->void:
	for i in 8:await process_frame
	await RenderingServer.frame_post_draw
func key(code:int,pressed:bool)->void:
	var ev:=InputEventKey.new();ev.keycode=code;ev.pressed=pressed
	demo.journey_map.get_viewport().push_input(ev,true)
func shot(name:String)->void:
	await settle()
	root.get_texture().get_image().save_png("res://renders/navigation_usability/"+name+".png")
func run()->void:
	root.size=Vector2i(1440,900)
	DirAccess.make_dir_recursive_absolute("res://renders/navigation_usability")
	demo=load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options={"live_start":true,"sky_state":"rest","auto_view":true,"size":root.size}
	root.add_child(demo);await settle();demo.journey_auto_tick=false
	demo.consoles.go_to("navigation");demo.consoles.use("navigation","open");await settle()
	var map:GalaxyMap=demo.journey_map
	map._system_buttons.mars.pressed.emit()
	if not demo.journey_tick() or map.journey_state()!="planned":failures+=1
	await shot("mars_plan")
	key(KEY_ENTER,true);key(KEY_ENTER,false)
	if not map.dialog.visible:failures+=1
	await shot("mars_review")
	key(KEY_SPACE,true)
	for i in 15:map._process(.1)
	key(KEY_SPACE,false)
	if not demo.journey_tick() or map.journey_state()!="committed" or demo.journey_sim.world.journey.plan.target.id!="mars":failures+=1
	await shot("mars_committed")
	var f:=FileAccess.open("res://renders/navigation_usability/metrics.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"target":demo.journey_sim.world.journey.plan.target.id,"state":map.journey_state(),"refused":demo.journey_sim.last_refused,"failures":failures},"  "))
	print("navigation-usability-capture: %d failures"%failures)
	demo.queue_free();await process_frame;quit(1 if failures else 0)
