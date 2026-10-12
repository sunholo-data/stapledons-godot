extends SceneTree
func _initialize()->void:run.call_deferred()
func stats(samples:Array)->Dictionary:
	samples.sort();return {"samples":samples.size(),"median_ms":samples[samples.size()/2],"p95_ms":samples[int(samples.size()*.95)],"max_ms":samples[-1]}
func run()->void:
	var world:Dictionary={}
	for line in FileAccess.get_file_as_string("res://tests/fixtures/system_sol.ndjson").split("\n",false):
		var record:Dictionary=JSON.parse_string(line)
		if record.type=="state":world=record.changes;break
	var sky:=InteriorSky.new();root.add_child(sky)
	sky.setup({"position_m":[8,4.8,83.7],"forward":[0,0,1],"up":[0,1,0]},78.,Vector2i(1280,720),{"stars":false,"background":false})
	var rows:=[]
	for id in ["dark","earth","saturn"]:
		var state:=world.duplicate(true)
		if id!="dark":
			var bodies:=[]
			for body:Dictionary in state.system.bodies:
				if body.id==id:
					var b:=body.duplicate(true);var dist:float=b.radius_km*2. if id=="earth" else 500000.
					b.rel_km={"x":dist,"y":0.,"z":0.};b.sun_dir={"x":-1.,"y":0.,"z":0.};b.phase_deg=0.
					b.e_v_lux=Planets.disc_illuminance(127057.41052085394,b.p_v,b.radius_km,b.r_au,dist,0.,b.minnaert_k);bodies.append(b)
			state.system.bodies=bodies
		sky.apply(state);sky.camera.look(0.,0.,0.);sky.update_exposure()
		for cached in [false,true]:
			var samples:=[];var before:=sky.system_view.preparation_count
			for j in 120:
				if not cached:sky.system_view._prepared=false
				var t:=Time.get_ticks_usec();sky.update_exposure();samples.append((Time.get_ticks_usec()-t)/1000.)
			var row:=stats(samples);row["scene"]=id;row["cache"]=cached;row["preparations"]=sky.system_view.preparation_count-before;rows.append(row)
	var report:={"cpu_exposure_updates":rows,"texture_preparation":sky.system_view.presentation_stats(),"platform":OS.get_name(),"label":"Mac Studio headless CPU presentation-only benchmark; no catalogue/background, no GPU frame cost, no M2 Air claim. Forced preparation models previous redundant SystemView reconstruction; same physical rays/meters in both cases."}
	DirAccess.make_dir_recursive_absolute("res://renders/perf")
	var out:=FileAccess.open("res://renders/perf/planet_cpu.json",FileAccess.WRITE);out.store_string(JSON.stringify(report,"  "));print(JSON.stringify(report))
	sky.queue_free();await process_frame;quit()
