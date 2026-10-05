extends SceneTree
const Stats:=preload("res://demos/ship_demo_benchmark.gd")
func _initialize()->void:_run.call_deferred()
func _run()->void:
	root.size=Vector2i(1920,1080);UiScale.configure(root,true)
	var demo:Node=load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options={"sky_state":"rest"};root.add_child(demo);await process_frame
	demo.auto=false;demo.journey_auto_tick=false
	if not demo.start_solar_departure():print("solar-departure-bench: FAIL start");quit(1);return
	var worlds:=[demo.journey_sim.world.duplicate(true)]
	for leg in 2:
		if not demo.solar_tour.advance():print("solar-departure-bench: FAIL commit");quit(1);return
		for tick in 2000:
			if not demo.journey_tick():print("solar-departure-bench: FAIL tick");quit(1);return
			if demo.journey_sim.world.journey.state=="arrived":break
		worlds.append(demo.journey_sim.world.duplicate(true))
	var report:={"resolution":[1920,1080],"warmup":120,"samples":300,"air_pending":true,"pairs":[],"method":"Frozen actual tour stops; same observer and fixed EV in each pair. Compare planets+meter enabled versus disabled. Wall intervals include presentation/vsync; negative deltas are noise."}
	for index in worlds.size():
		var world:Dictionary=worlds[index]
		demo.sky.exposure.fixed=false;demo.sky_world=world;demo.sky.apply(world)
		var h:Dictionary=world.ship.heading;demo.camera.heading=PackedFloat64Array([h.x,h.y,h.z])
		demo.look_direction("forward");demo.sky.update_exposure()
		demo.sky.exposure.fixed_ev=demo.sky.exposure.ev;demo.sky.exposure.fixed=true
		var pair:={"stop":["Earth","Jupiter","Saturn"][index],"exposure_ev":demo.sky.exposure.ev,"resolved_bodies":demo.sky.system_view.drawn_discs.keys(),"measurements":[]}
		for enabled in [false,true]:
			demo.sky.system_state=world.system if enabled else {}
			demo.sky.update_exposure()
			for frame in 120:await process_frame
			var times:=[];var previous:=Time.get_ticks_usec()
			for frame in 300:
				await process_frame
				var now:=Time.get_ticks_usec();times.append(float(now-previous)/1000.);previous=now
			pair.measurements.append({"planets_and_meter":enabled,"frame_times":Stats.summarize(times),"video_memory_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)})
		pair.incremental_planet_p95_ms=pair.measurements[1].frame_times.p95_ms-pair.measurements[0].frame_times.p95_ms
		report.pairs.append(pair)
	DirAccess.make_dir_recursive_absolute("res://renders/solar_departure")
	var file:=FileAccess.open("res://renders/solar_departure/benchmark-aggregate.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "))
	print("solar-departure-bench: OK");demo.queue_free();await process_frame;quit()
