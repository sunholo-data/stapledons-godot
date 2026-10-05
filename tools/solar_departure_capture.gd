extends SceneTree
## Normal UI host and authoritative itinerary; no ephemeris edits for the pictures.
var captures:=[]
var failed:=false
var demo:Node
const OUT:="res://renders/solar_departure"
func _initialize()->void:_run.call_deferred()
func capture(name:String)->void:
	demo.look_direction("forward")
	demo.sky.update_exposure()
	for frame in 12:await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+"/"+name+".png")
	var w:Dictionary=demo.journey_sim.world
	captures.append({"name":name,"phase":w.ship.phase,"beta":w.ship.beta,"gamma":w.ship.gamma,"year":w.clock.year,"tau":w.clock.tau,"ship_pos_ly":w.ship.pos,"heading":w.ship.heading,"epoch_jd":w.system.jd,"eye_m":[demo.camera.position.x,demo.camera.position.y,demo.camera.position.z],"fov":demo.camera.fov,"sky_exposure_stops":demo.brightness_stops,"exposure_ev":demo.sky.exposure.ev,"exposure_k":demo.sky.exposure.k(),"planet_highlight_cd_m2":demo.sky.system_view.highlight_luminance(demo.sky.camera,Vector2(demo.sky.size)),"resolved_body_ids":demo.sky.system_view.drawn_discs.keys()})
func _run()->void:
	root.size=Vector2i(1280,720);UiScale.configure(root,true)
	DirAccess.make_dir_recursive_absolute(OUT)
	demo=load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options={"size":root.size,"sky_state":"rest"};root.add_child(demo);await process_frame
	demo.auto=false;demo.journey_auto_tick=false
	if not demo.start_solar_departure():print("solar-departure-capture: FAIL start");quit(1);return
	await capture("earth_start")
	for destination in ["jupiter","saturn","alpha_centauri"]:
		if not demo.solar_tour.advance():failed=true;break
		var seen:={}
		var phase_ticks:=0
		var old_phase:=""
		for tick in 2000:
			if not demo.journey_tick():failed=true;break
			var phase:String=demo.sky_world.ship.phase
			if phase!=old_phase:phase_ticks=0;old_phase=phase
			phase_ticks+=1
			if phase_ticks==120 and not seen.has(phase):
				seen[phase]=true;await capture(destination+"_"+phase)
			if demo.journey_sim.world.journey.state=="arrived":break
		if demo.journey_sim.world.journey.state!="arrived":failed=true;break
		await capture(destination+"_arrival")
	var file:=FileAccess.open(OUT+"/capture-manifest.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"captures":captures,"approximation":demo.journey_sim.world.solar_departure.approximation,"itinerary":demo.journey_sim.world.solar_departure.legs,"note":"Camera at actual standing bridge eye, looking through forward dome; internal lighting study. Planet ephemerides and positions unchanged."},"  "))
	print("solar-departure-capture: %s" %("FAIL" if failed else "OK"));demo.queue_free();await process_frame;quit(1 if failed else 0)
