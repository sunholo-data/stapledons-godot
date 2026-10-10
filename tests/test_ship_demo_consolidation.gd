extends SceneTree
var failed := 0
var passed := 0
func check(ok: bool, message: String) -> void:
	if ok:passed+=1
	else:failed+=1
	print("%s %s" % ["ok" if ok else "FAIL",message])
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	var Main=load("res://main.gd")
	check(Main.current_ship_entry({}),"normal launch has one latest ship entry")
	check(Main.current_ship_entry({"ship-demo":""}),"old geometry shortcut opens same current ship")
	for mode in ["interior","interior-capture","m4-smoke","golden","capture","map","map-capture","voyage"]:
		check(not Main.current_ship_entry({mode:""}),"explicit %s remains available for reference checks" % mode)
	var demo: Node=load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options={"live_start":true,"sky_state":"rest","stars":false,"background":false}
	root.add_child(demo);await process_frame
	demo.auto=false;demo.journey_auto_tick=false
	check(demo.ready_ok and demo.journey_map!=null and not demo.navigation_window.visible,"current ship starts its own hidden normal navigation")
	check(demo.sky_state=="live" and demo.sky.beta==0. and demo.sky_world==demo.journey_sim.world,"default sky is actual live rest, not frozen cruise")
	check(demo.camera.pullback==0. and demo.camera.position.distance_to(demo.avatar_pos+Vector3.UP*1.7)<.0001,"default camera is physical captain eye")
	var eye: Array=demo.sky.cam.position_m
	check(Vector3(eye[0],eye[2],-eye[1]).distance_to(demo.camera.position)<.0001,"ship geometry and sky share measured physical observer")
	var before:float=demo.sky_world.clock.tau
	check(demo.journey_tick() and demo.sky_world.clock.tau>before,"live rest clock advances while aboard")
	var scroll:=InputEventPanGesture.new();scroll.delta=Vector2(0,-1)
	demo._unhandled_input(scroll);demo._process(0.)
	check(demo.camera.pullback>0. and demo.ship_hud.view_tag.text.contains("third-person camera"),"optional third person is explicitly labelled")
	demo.set_preset("reset");check(demo.camera.pullback==0.,"reset returns to captain eye")
	demo.open_navigation();check(demo.journey_map!=null,"one navigation is shared with current ship")
	demo.close_navigation();demo.queue_free();await process_frame
	print("ship-demo-consolidation: %d passed, %d failures" % [passed,failed]);quit(1 if failed else 0)
