extends SceneTree
var failures:=0
func check(label:String,ok:bool)->void:
	print("%s %s"%["ok" if ok else "FAIL",label]);if not ok:failures+=1
func _initialize()->void:_run.call_deferred()
func _run()->void:
	var demo:Node=load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options={"stars":false,"background":false};root.add_child(demo)
	demo.auto=false;demo.journey_auto_tick=false
	demo.open_navigation();await process_frame
	check("isolated normal navigation",demo.journey_map!=null and demo.journey_map.journey_state()=="planned" and demo.navigation_window.own_world_3d)
	if demo.journey_map==null:quit(1);return
	demo.journey_map.open_commit_dialog();demo.journey_map.hold_commit(GalaxyMap.HOLD_S);demo.journey_tick()
	check("commit returns aboard with boost visible",demo.live_journey and not demo.navigation_window.visible and demo.sky.beta>0.)
	check("snapshot locked during physical voyage",not demo.set_sky_state("rest"))
	check("benchmark locked during physical voyage",(await demo.benchmark.run(demo,1,0)).is_empty())
	demo.set_preset("bridge");demo.look_direction("side")
	var basis:Basis=demo.camera.basis;var heading:Dictionary=demo.journey_sim.world.ship.heading.duplicate()
	var phases:={};var stable:=true;var mirrors:=true
	for i in 1210:
		demo.journey_tick()
		phases[demo.sky_world.ship.phase]=true
		stable=stable and demo.camera.basis.is_equal_approx(basis) and demo.journey_sim.world.ship.heading==heading
		mirrors=mirrors and demo.sky.beta==demo.journey_sim.world.ship.beta and demo.sky_world.clock==demo.journey_sim.world.clock
		if not demo.live_journey:break
	check("all phases visible aboard",phases.has("boosting") and phases.has("cruising") and phases.has("braking") and phases.has("at_rest"))
	check("look attitude and heading remain stable",stable)
	check("sky and clocks mirror every AILANG state",mirrors)
	check("arrival stays rest",demo.sky.beta==0. and demo.journey_map.journey_state()=="arrived")
	check("snapshot available after physical arrival",demo.set_sky_state("rest"))
	demo.queue_free();await process_frame;quit(1 if failures else 0)
