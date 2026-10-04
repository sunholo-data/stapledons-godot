extends SceneTree
var passes := 0
var failures := 0
func check(label: String, ok: bool) -> void:
	if ok:passes+=1
	else:failures+=1
	print("  %s %s" % ["ok" if ok else "FAIL",label])
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var demo:Node=load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options={"stars":false,"background":false};root.add_child(demo);demo.auto=false
	await process_frame
	check("simulation-backed midjourney controls exist",demo.has_method("set_sky_state") and demo.has_method("look_direction"))
	if not demo.has_method("set_sky_state"):_finish();return
	check("cruise state available",demo.set_sky_state("cruise"))
	check("simulation cruise speed",absf(demo.sky.beta-.99)<1e-12)
	var heading:Vector3=demo.sky.heading_world
	var beta:float=demo.sky.beta
	for direction in ["forward","side","aft"]:
		demo.look_direction(direction)
		check("%s preserves heading/velocity" % direction,demo.sky.heading_world.distance_to(heading)<1e-7 and demo.sky.beta==beta)
		check("%s remains captain eye" % direction,demo.camera.position.distance_to(demo.avatar_pos+Vector3.UP*1.7)<1e-4 and not demo.camera.external)
		var angle:float=demo.sky.camera.view_velocity_angle(heading)
		var wanted:float={"forward":.5,"side":90.,"aft":179.5}[direction]
		check("%s view relative to travel" % direction,absf(angle-wanted)<.002)
		check("%s star GPU velocity" % direction,demo.sky.starfield.material.get_shader_parameter("beta_dir").distance_to(heading)<1e-7 and absf(float(demo.sky.starfield.material.get_shader_parameter("beta_mag"))-beta)<1e-7)
		for p in [Vector2.ZERO,Vector2(root.size)*.5,Vector2(root.size)]:
			var ray:Vector3=demo.camera.to_sky_direction(demo.camera.project_ray_normal(p),demo.camera.heading)
			check("%s shared observer ray" % direction,ray.distance_to(demo.sky.camera.project_ray_normal(p))<1e-5)
	check("rest toggle",demo.set_sky_state("rest") and demo.sky.beta==0.)
	check("rest retains same journey direction",demo.sky.heading_world.distance_to(heading)<1e-7)
	check("unknown state rejected",not demo.set_sky_state("bogus") and demo.sky.beta==0.)
	demo.set_sky_state("cruise");demo.set_preset("overview")
	check("outside review disables wall glow",demo.sky.glow_pole==0.)
	demo.set_preset("bridge")
	check("inside view restores simulation glow",demo.sky.glow_pole==ForwardGlow.pole_of(demo.sky_world))
	demo.benchmark.running=true
	check("benchmark rejects sky change",not demo.set_sky_state("rest") and demo.sky.beta==beta)
	demo.benchmark.running=false;demo.toggle_sky_only()
	var observation:={"geometry_visible":true,"frames":0}
	var observe:=func() -> void:
		if demo.benchmark.running:
			observation.frames+=1
			observation.geometry_visible=observation.geometry_visible and not demo.sky_only and demo._rects[1].visible and demo.geometry_view.render_target_update_mode==SubViewport.UPDATE_ALWAYS
	process_frame.connect(observe)
	var output_path:=OS.get_temp_dir()+"/ship-demo-journey-test-%d.json" % OS.get_process_id()
	var report:Dictionary=await demo.benchmark.run(demo,1,0,output_path)
	process_frame.disconnect(observe)
	check("benchmark from diagnostic measures visible ship",observation.geometry_visible and observation.frames>=4)
	check("benchmark records sky state",report.sky_review.state=="cruise" and report.sky_review.beta==beta and not report.sky_review.sky_only)
	check("benchmark restores sky-only diagnostic",demo.sky_only and not demo._rects[1].visible)
	check("isolated benchmark report saved",FileAccess.file_exists(output_path))
	DirAccess.remove_absolute(output_path)
	demo.queue_free();await process_frame
	_finish()
func _finish() -> void:
	print("ship-demo-journey: %d passed, %d failures" % [passes,failures]);quit(1 if failures else 0)
