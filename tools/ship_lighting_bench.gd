extends SceneTree
const Stats:=preload("res://demos/ship_demo_benchmark.gd")
func _initialize()->void:_run.call_deferred()
func _run()->void:
	root.size=Vector2i(1920,1080);UiScale.configure(root,true)
	var demo:Node=load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options={"sky_state":"rest"};root.add_child(demo);await process_frame
	demo.auto=false;demo.journey_auto_tick=false
	var report:={"resolution":[1920,1080],"warmup":120,"samples":300,"air_pending":true,"timer":"Wall frame intervals include presentation/vsync; negative paired deltas are noise.","pairs":[]}
	for pose in ["bridge_outward","bridge_inward","bridge_overlook","commons_arcade"]:
		match pose:
			"bridge_outward":demo.set_preset("bridge")
			"bridge_inward":demo.set_preset("bridge");demo.camera.follow(demo.avatar_pos,8.,3.61,0.)
			"bridge_overlook":demo.set_preset("overlook")
			"commons_arcade":demo.active_level=1;demo.avatar_pos=Vector3(46,57,-5);demo.camera.follow(demo.avatar_pos,0.,1.6,0.)
		demo.camera_mode="lighting benchmark"
		var pair:={"pose":pose,"eye_m":[demo.camera.position.x,demo.camera.position.y,demo.camera.position.z],"measurements":[]}
		for profile in ["moody_no_shadows","moody"]:
			demo.set_lighting(profile);demo._sync_observer()
			for frame in 120:await process_frame
			var times:=[];var previous:=Time.get_ticks_usec()
			for frame in 300:
				await process_frame
				var now:=Time.get_ticks_usec();times.append(float(now-previous)/1000.);previous=now
			pair.measurements.append({"profile":profile,"frame_times":Stats.summarize(times),"video_memory_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)})
		pair.incremental_shadow_p95_ms=pair.measurements[1].frame_times.p95_ms-pair.measurements[0].frame_times.p95_ms
		report.pairs.append(pair)
	DirAccess.make_dir_recursive_absolute("res://renders/ship_lighting")
	var file:=FileAccess.open("res://renders/ship_lighting/benchmark-aggregate.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	print("ship-lighting-bench: OK")
	demo.queue_free();await process_frame;quit()
