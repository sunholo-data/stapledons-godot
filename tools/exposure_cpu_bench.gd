extends SceneTree
## CPU-only presentation meter benchmark on this host; no GPU/Air inference.
func _initialize()->void:run.call_deferred()
func run()->void:
	var sky:=InteriorSky.new();root.add_child(sky)
	sky.setup({"position_m":[0,0,0],"forward":[0,0,1],"up":[0,1,0]},78.,Vector2i(1280,720))
	var sim:=SimBridge.new();sim.want_minor=5
	if not sim.start() or not sim.new_game(19):print("exposure-cpu-bench: FAIL ",sim.last_error);quit(1);return
	var world:=sim.world.duplicate(true);var earth:Dictionary={}
	for b:Dictionary in world.system.bodies:
		if b.id=="earth":earth=b.duplicate(true)
	var distance:float=earth.radius_km*8.
	earth.rel_km={"x":distance,"y":0.,"z":0.};earth.sun_dir={"x":-1.,"y":0.,"z":0.};earth.phase_deg=0.
	earth.e_v_lux=Planets.disc_illuminance(127057.41052085394,earth.p_v,earth.radius_km,earth.r_au,distance,0.,earth.minnaert_k)
	world.system.bodies=[earth];world.ship.heading={"x":1.,"y":0.,"z":0.}
	sky.apply(world);sky.camera.look(0.,0.,0.);sky.update_exposure();sky.set_temporal_exposure(true)
	var results:=[];var frame:=1
	for profile:String in ["steady","walking_look"]:
		var before:=sky.exposure_stats();var durations:=PackedFloat64Array()
		for j in 240:
			var started:=Time.get_ticks_usec()
			if j%3==0:sky.apply(world)
			if profile=="walking_look":sky.cam.position_m=[j*.02,0.,0.]
			sky.camera.look(deg_to_rad(j*.5 if profile=="walking_look" else 0.),0.,0.)
			frame+=1;sky.finish_exposure_frame(1./60.,frame)
			durations.append(Time.get_ticks_usec()-started)
		var sum:=0.;for value in durations:sum+=value
		durations.sort();var after:=sky.exposure_stats()
		var record:={"profile":profile,"frames":240,"samples":after.samples-before.samples,"meter_cpu_usec":after.sample_cpu_usec-before.sample_cpu_usec,"mean_frame_cpu_usec":sum/240.,"median_frame_cpu_usec":durations[120],"p95_frame_cpu_usec":durations[228],"catalogue_stars":sky.starfield.count,"background":sky.has_background,"loaded_texture_families":sky.system_view.textures.keys(),"scope":"CPU host updates and physical metering; controlled package Earth placement; excludes GPU/cold preloading/native frame overhead"}
		results.append(record);print(record)
	DirAccess.make_dir_recursive_absolute("res://renders/perf")
	var file:=FileAccess.open("res://renders/perf/exposure_cpu.json",FileAccess.WRITE);file.store_string(JSON.stringify(results,"  "))
	sim.stop();sky.queue_free();await process_frame
	print("exposure-cpu-bench: OK");quit(0)
