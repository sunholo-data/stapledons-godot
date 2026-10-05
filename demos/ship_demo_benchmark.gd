extends RefCounted
## In-app reproducible review benchmark. Studio results are never laptop results.
const OUTPUT := "user://ship_demo_benchmark.json"
var running := false
static func summarize(values: Array) -> Dictionary:
	var sorted:=values.duplicate();sorted.sort()
	var n:=sorted.size()
	if n==0:return {"samples":0}
	var sum:=0.
	for v in sorted:sum+=v
	return {"samples":n,"mean_ms":sum/n,"p50_ms":sorted[ceili(n*.5)-1],"p95_ms":sorted[ceili(n*.95)-1],"p99_ms":sorted[ceili(n*.99)-1],"maximum_ms":sorted[-1]}
func run(demo: Node, samples:=300, warmup:=120, output_path:=OUTPUT) -> Dictionary:
	if running or demo.live_journey:return {}
	var previous_sky_only:bool=demo.sky_only
	if previous_sky_only:demo.toggle_sky_only()
	running=true;demo.auto=false;
	var buttons: Array=demo.hud.find_children("*","Button",true,false)
	for button in buttons:button.disabled=true
	demo.get_window().size=Vector2i(1920,1080)
	demo._resize()
	var model_output:=[]
	var model_status:=OS.execute("/usr/sbin/sysctl",PackedStringArray(["-n","hw.model"]),model_output) if OS.get_name()=="macOS" else -1
	var hardware:={"model":str(model_output[0]).strip_edges() if model_status==0 and not model_output.is_empty() else "unavailable","os":OS.get_name(),"cpu":OS.get_processor_name(),"gpu":RenderingServer.get_video_adapter_name(),"vendor":RenderingServer.get_video_adapter_vendor(),"renderer":RenderingServer.get_current_rendering_method(),"memory":OS.get_memory_info()}
	var report:={"version":1,"measured_hardware":hardware,"user_target":"MacBook Air M2 (2022),24GB","target_measurement_pending":true,"target_confirmation":"Confirm report came from the specified MacBook Air; GPU substring alone cannot identify the laptop","resolution":[1920,1080],"warmup_frames":warmup,"sample_frames":samples,"timer":"wall time between process frames, includes presentation/vsync; not GPU-only time","views":[],"GR":"not implemented"}
	report["sky_review"]={"state":demo.sky_state,"beta":demo.sky.beta,"gamma":demo.sky_world.ship.gamma,"heading":Array(demo.camera.heading),"snapshot_tick":demo.sky_world.tick,"sky_only":false}
	report["commons_enabled"]=not demo.commons.is_empty()
	report["sky_exposure_trial"]={"stops":demo.brightness_stops,"label":demo.brightness_label(),"bias_ev":demo.sky.exposure.bias}
	# Use the same authored standing-eye view in both baseline and enabled runs.
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(load("res://demos/ship_commons.gd").asset("manifest.json")))
	var courtyard_eye:=Vector3(23,58.725,3)
	var courtyard_target:=Vector3(26,61.2,-10)
	for view: Dictionary in manifest.get("player_views",[]):
		if view.name=="courtyard":
			var eye: Array=view.eye_ship_m;var target: Array=view.target_ship_m
			courtyard_eye=Vector3(eye[0],eye[2],-eye[1])
			courtyard_target=Vector3(target[0],target[2],-target[1])
	var views:=["bridge","overlook","mid_lift","commons_courtyard","overview"]
	if demo.solar_tour!=null:views.append("forward_dome")
	for name in views:
		demo.set_preset("reset")
		if name=="mid_lift":
			demo.lift.board();demo.lift.advance(.81);demo.lift.advance(5.5)
		elif name=="commons_courtyard":
			demo.active_level=1;demo.walk=demo.walk_lower;demo.avatar_pos=courtyard_eye-Vector3.UP*1.7
			demo.camera_mode="benchmark reference";demo.camera.position=courtyard_eye
			demo.camera.look_at(courtyard_target);demo._sync_observer()
		elif name=="forward_dome":demo.look_direction("forward")
		else:demo.set_preset(name)
		demo.caption="BENCHMARK %s · warm-up" % name
		for i in warmup:await demo.get_tree().process_frame
		var times:=[];var previous:=Time.get_ticks_usec()
		var draws:=[];var tris:=[]
		demo.caption="BENCHMARK %s · measuring %d frames" % [name,samples]
		for i in samples:
			await demo.get_tree().process_frame
			var now:=Time.get_ticks_usec();times.append((now-previous)/1000.);previous=now
			draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME));tris.append(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
		var timing:=summarize(times)
		report.views.append({"view":name,"eye_gltf_m":[demo.camera.position.x,demo.camera.position.y,demo.camera.position.z],"view_direction":[-demo.camera.basis.z.x,-demo.camera.basis.z.y,-demo.camera.basis.z.z],"frame_times":timing,"frame_times_ms":times,"draw_calls":summarize(draws),"rendered_primitives":summarize(tris),"video_memory_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED),"texture_memory_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),"p95_within_60fps_budget":timing.p95_ms<=1000./60.})
	var f:=FileAccess.open(output_path,FileAccess.WRITE)
	if f!=null:f.store_string(JSON.stringify(report,"  "));f.close()
	demo.set_preset("reset");demo.auto=true
	demo.caption="Benchmark saved: "+ProjectSettings.globalize_path(output_path) if f!=null else "Benchmark report could not be saved."
	print("ship-demo-benchmark-report: ",ProjectSettings.globalize_path(output_path) if f!=null else "WRITE FAILED")
	for button in buttons:button.disabled=false
	running=false
	if previous_sky_only:demo.toggle_sky_only()
	return report
