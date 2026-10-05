extends SceneTree
## Exercise the real deferred commitments and shared observer, without changing
## ephemerides. Simulation ticks run faster for capture; attitude turns are real.
var captures:=[]
var failed:=false
var demo:Node
const OUT:="res://renders/solar_departure"
func _initialize()->void:_run.call_deferred()
func capture(name:String)->void:
	demo.sky.update_exposure()
	for frame in 12:await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+"/"+name+".png")
	var w:Dictionary=demo.journey_sim.world
	captures.append({"name":name,"phase":w.ship.phase,"beta":w.ship.beta,"gamma":w.ship.gamma,"year":w.clock.year,"tau":w.clock.tau,"ship_pos_ly":w.ship.pos.duplicate(true),"heading":w.ship.heading.duplicate(true),"epoch_jd":w.system.jd,"eye_m":[demo.camera.position.x,demo.camera.position.y,demo.camera.position.z],"fov":demo.camera.fov,"attitude":Array(demo.camera.attitude_basis),"sky_exposure_stops":demo.brightness_stops,"exposure_ev":demo.sky.exposure.ev,"resolved_body_ids":demo.sky.system_view.drawn_discs.duplicate()})
func turn_stationary()->void:
	var before:Dictionary=demo.journey_sim.world.clock.duplicate(true)
	var position:Dictionary=demo.journey_sim.world.ship.pos.duplicate(true)
	# SceneTree.process_frame fires before Node._process. Start the same host
	# transition now so the capture cannot mistake 'not started' for 'finished'.
	demo._update_tour_attitude(0.)
	await process_frame
	for frame in 1200:
		if not demo.solar_tour.attitude_hold:break
		# Held steps must not advance the authoritative clocks or position.
		if not demo.journey_tick():failed=true;return
		if demo.journey_sim.world.clock!=before or demo.journey_sim.world.ship.pos!=position:
			# A finished departure commits one simulation step; that is allowed
			# only after the hold is released.
			if demo.solar_tour.attitude_hold:print("capture-held-state-changed: ",before," -> ",demo.journey_sim.world.clock);failed=true
		await process_frame
	if demo.solar_tour.attitude_hold:print("capture-held-state-changed: ",before," -> ",demo.journey_sim.world.clock);failed=true
func _run()->void:
	root.size=Vector2i(1280,720);UiScale.configure(root,true)
	DirAccess.make_dir_recursive_absolute(OUT)
	demo=load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options={"size":root.size,"sky_state":"rest"};root.add_child(demo);await process_frame
	demo.auto=true;demo.journey_auto_tick=false
	if not demo.start_solar_departure():print("solar-departure-capture: FAIL start");quit(1);return
	await turn_stationary();await capture("earth_start")
	var itinerary:Array=demo.solar_tour.itinerary.duplicate(true)
	for spec:Dictionary in itinerary:
		var destination:String=spec.id.replace(":","_")
		if not demo.solar_tour.prepare_next():print("capture-prepare-failed: ",demo.solar_tour.failed," hold=",demo.solar_tour.attitude_hold);failed=true;break
		await turn_stationary()
		if failed or not demo.live_journey:print("capture-departure-failed: ",demo.solar_tour.failed," pending=",demo.solar_tour.pending_index," hold=",demo.solar_tour.attitude_hold," mode=",demo._attitude_mode);failed=true;break
		var seen:={};var phase_ticks:=0;var old_phase:=""
		for tick in 4000:
			if not demo.journey_tick():failed=true;break
			var phase:String=demo.sky_world.ship.phase
			if phase!=old_phase:phase_ticks=0;old_phase=phase
			phase_ticks+=1
			if phase=="braking" and phase_ticks in [600,1200,1600]:
				await capture(destination+"_approach_%ds" % int(phase_ticks/20))
			if phase_ticks==120 and not seen.has(phase):
				seen[phase]=true;await capture(destination+"_"+phase)
			if demo.journey_sim.world.journey.state=="arrived":break
			await process_frame
		if demo.journey_sim.world.journey.state!="arrived":failed=true;break
		await turn_stationary();await capture(destination+"_arrival")
		if failed:break
	var file:=FileAccess.open(OUT+"/capture-manifest.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"captures":captures,"approximation":demo.journey_sim.world.solar_departure.approximation,"itinerary":itinerary,"note":"Actual standing bridge eye, smooth stationary attitude turns, same geometry/sky observer. Fast capture ticks; normal playback uses 20 Hz. Fixed internal lighting, no external Sun illumination or GR."},"  "))
	print("solar-departure-capture-images: %d"%captures.size());print("solar-departure-capture: %s" %("FAIL" if failed else "OK"));demo.queue_free();await process_frame;quit(1 if failed else 0)
