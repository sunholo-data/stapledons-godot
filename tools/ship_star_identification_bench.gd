extends SceneTree
## Matched baseline/Identify frame samples. Raw hardware diagnostics stay local.
const Stats := preload("res://demos/ship_demo_benchmark.gd")
const OUT := "res://renders/ship_identification/benchmark.json"
var report := {"version":1,"resolution":[1920,1080],"samples":300,"warmup":120,"target_air_pending":true,"timer":"Wall frame intervals, includes presentation/vsync. Small negative deltas are noise, not speedup.","views":[]}
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	root.size=Vector2i(1920,1080)
	var demo: Node=load("res://demos/ship_geometry_demo.tscn").instantiate()
	root.add_child(demo);await process_frame
	if not demo.ready_ok or demo.get("star_identification")==null:
		push_error("Identification benchmark requires ready integrated demo");quit(1);return
	demo.auto=false;demo.journey_auto_tick=false
	var identify: Control=demo.star_identification
	identify.set_process(false)
	report["hardware"]={"cpu":OS.get_processor_name(),"gpu":RenderingServer.get_video_adapter_name(),"os":OS.get_name(),"renderer":RenderingServer.get_current_rendering_method()}
	for state in ["rest","cruise"]:
		for direction in ["forward","side"]:
			var pair:={"state":state,"direction":direction,"beta":0.,"measurements":[]}
			for held in [false,true]:
				demo.set_preset("bridge");demo.set_sky_state(state);demo.look_direction(direction);demo.set_brightness_trial(2)
				demo.camera_mode="identification benchmark"
				identify.suppressed=false;identify.set_held(held)
				pair.beta=demo.sky.beta
				var initial_basis: Basis=demo.camera.basis
				for frame in 120:
					identify._process(0.);await process_frame
				var times:=[];var counts:=[];var cpu:=[];var previous:=Time.get_ticks_usec()
				for frame in 300:
					# The same small pan in both conditions exercises moving apparent positions.
					demo.camera.basis=Basis(Vector3.UP,float(frame)*.0001)*initial_basis
					demo._sync_observer()
					var update_start:=Time.get_ticks_usec()
					identify._process(0.)
					cpu.append(float(Time.get_ticks_usec()-update_start)/1000.)
					await process_frame
					var now:=Time.get_ticks_usec();times.append(float(now-previous)/1000.);previous=now
					counts.append(identify.candidates.size())
				pair.measurements.append({"identify_held":held,"eye_m":[demo.camera.position.x,demo.camera.position.y,demo.camera.position.z],"pan_radians":.0299,"frame_times":Stats.summarize(times),"overlay_update_cpu_ms":Stats.summarize(cpu),"frame_times_ms":times,"candidate_count_range":[counts.min(),counts.max()],"video_memory_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)})
			pair["incremental_p95_ms"]=pair.measurements[1].frame_times.p95_ms-pair.measurements[0].frame_times.p95_ms
			pair["incremental_update_cpu_p95_ms"]=pair.measurements[1].overlay_update_cpu_ms.p95_ms-pair.measurements[0].overlay_update_cpu_ms.p95_ms
			pair["within_proposed_2ms_incremental_budget"]=pair.incremental_p95_ms<=2.
			report.views.append(pair)
	identify.set_held(false)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://renders/ship_identification"))
	var output:=FileAccess.open(OUT,FileAccess.WRITE)
	if output==null:push_error("Cannot write benchmark report");quit(1);return
	output.store_string(JSON.stringify(report,"  "));output.close()
	print("ship-star-identification-bench: OK · ",ProjectSettings.globalize_path(OUT))
	demo.queue_free();await process_frame;quit()
