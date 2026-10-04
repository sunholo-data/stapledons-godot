extends SceneTree
## Sequential staged views sampled from one normal committed AILANG voyage.
var demo:Node
var shots:=[]
const OUT:="res://renders/ship_demo/live"
func _initialize()->void:_run.call_deferred()
func _run()->void:
	root.size=Vector2i(1280,720)
	demo=load("res://demos/ship_geometry_demo.tscn").instantiate();root.add_child(demo)
	demo.auto=false;demo.journey_auto_tick=false
	await process_frame
	if not demo.ready_ok:quit(1);return
	demo.set_preset("bridge");demo.look_direction("forward");demo.set_brightness_trial(2)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	demo.open_navigation()
	if demo.journey_map==null:quit(1);return
	for i in 6:await process_frame
	await RenderingServer.frame_post_draw
	demo.navigation_window.get_texture().get_image().save_png(OUT+"/navigation.png")
	demo.journey_map.open_commit_dialog();demo.journey_map.hold_commit(GalaxyMap.HOLD_S)
	if not demo.journey_tick():quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var phase_counts:={"boosting":0,"cruising":0,"braking":0,"at_rest":0}
	for i in 1220:
		var phase:String=demo.sky_world.ship.phase
		phase_counts[phase]+=1
		if phase_counts[phase] in ([80,300] if phase in ["boosting","braking"] else [200] if phase=="cruising" else [1]):
			await shot("%s_%03d" % [phase,phase_counts[phase]])
		if not demo.live_journey:break
		if not demo.journey_tick():quit(1);return
	var manifest:={"source":"One normal AILANG voyage selected through GalaxyMap and committed with the existing hold ritual; sequential states, no interpolation.","time_compression":"Variable: 20 real seconds per positive phase at 20 Hz. Manual staged ticks pause presentation for capture.","seed":424242,"ailang":demo.journey_sim.hello_reply,"sky_only":false,"navigation_render":"navigation.png, separate native Window with own World3D; catalogue selection and existing commit control", "standing_location":"reachable bridge foot (8,82,-4.8), camera forward at captain eye height","shots":shots,"phase_samples":phase_counts}
	var f:=FileAccess.open(OUT+"/manifest.json",FileAccess.WRITE);f.store_string(SimBridge.encode(manifest)+"\n");f.close()
	print("ship-demo-live-capture: OK · %d sequential states" % shots.size());demo.queue_free();await process_frame;quit()
func shot(name:String)->void:
	for i in 6:await process_frame
	demo.sky.update_exposure();await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+"/"+name+".png")
	shots.append({"name":name,"world":demo.sky_world.duplicate(true),"captain_eye":not demo.camera.external,"eye_m":demo.camera.ship_vector(demo.camera.position),"heading":Array(demo.camera.heading),"view_travel_deg":demo.sky.camera.view_velocity_angle(demo.sky.heading_world),"geometry_visible":not demo.sky_only,"brightness_stops":demo.brightness_stops,"time_compression_ship_years_per_real_s":demo.journey_map.pacing.rate})
