extends SceneTree
var demo: Node
var out := "res://renders/ship_demo/journey"
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	root.size=Vector2i(1280,720)
	var brightness_trial:=OS.get_cmdline_user_args().has("--brightness-trial")
	if brightness_trial:out="res://renders/ship_demo/brightness"
	demo=load("res://demos/ship_geometry_demo.tscn").instantiate();root.add_child(demo);demo.auto=false
	await process_frame
	if not demo.ready_ok:quit(1);return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var shots:=[]
	for state in ["rest","cruise"]:
		demo.set_sky_state(state)
		for stops in ([0,1,2,4,6] if brightness_trial else [0]):
			demo.set_brightness_trial(stops)
			for direction in ["forward","side","aft"]:
				demo.look_direction(direction)
				var name:String=state+"_"+direction+("_b%d" % stops if brightness_trial else "")
				await shot(name,shots)
				demo.toggle_sky_only()
				await shot(name+"_sky_only",shots)
				demo.toggle_sky_only()
	var f:=FileAccess.open(out+"/manifest.json",FileAccess.WRITE)
	f.store_string(SimBridge.encode({"description":"Frozen simulation snapshots. Up is travel; camera turning does not change velocity. Sky-only frames diagnostically hide the opaque ship. Brightness variants are labelled exposure aids, not amplified physical photons.","shots":shots})+"\n")
	print("ship-demo-journey-capture: OK");quit()
func shot(name: String, shots: Array) -> void:
	for i in 6:await process_frame
	demo.sky.update_exposure()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out+"/"+name+".png")
	shots.append({"name":name,"beta":demo.sky.beta,"heading":Array(demo.camera.heading),"eye_m":Array(demo.camera.ship_vector(demo.camera.position)),"view_travel_deg":demo.sky.camera.view_velocity_angle(demo.sky.heading_world),"sky_only":demo.sky_only,"captain_eye":not demo.camera.external,"ship_state":demo.sky_world.ship,"vertical_fov":demo.camera.fov,"brightness_stops":demo.brightness_stops,"exposure_ev":demo.sky.exposure.ev,"exposure_label":demo.brightness_label()})
