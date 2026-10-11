extends SceneTree
## D65 native reference views. Advance only the authoritative simulation along
## one seven-leg journey; sample its final braking seconds, then exact arrival.
## These phase samples are reference frames, not a real-time video recording.
const Tour := preload("res://demos/solar_departure.gd")
const OUT := "res://renders/guided_highlights"
var sky: InteriorSky
var frame := 0
var failures := 0
var records := []
func _initialize() -> void: run.call_deferred()
func run() -> void:
	root.size = Vector2i(1280,720)
	DirAccess.make_dir_recursive_absolute(OUT)
	sky = InteriorSky.new(); root.add_child(sky)
	sky.setup({"position_m":[0,0,0],"forward":[0,0,1],"up":[0,1,0]},78.,root.size,{"stars":true,"background":true,"planet_textures":true})
	var rect := TextureRect.new(); rect.texture=sky.get_texture()
	rect.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;rect.stretch_mode=TextureRect.STRETCH_SCALE
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.add_child(rect)
	sky.exposure.fixed=true;sky.exposure.fixed_ev=sky.exposure.ev_dark()-2.;sky.set_temporal_exposure(false)
	var sim := SimBridge.new();sim.want_minor=SimBridge.ISM_MINOR
	if not sim.start() or not sim.new_game(424242,"solar_departure",false,Tour.guided_params()):
		print("guided-highlights-capture: start FAIL ",sim.last_error);quit(1);return
	var catalogue:Array=JSON.parse_string(FileAccess.get_file_as_string("res://data/starmap/stars.json")).stars
	var tour=Tour.new()
	if not tour.attach(sim,catalogue) or tour.itinerary.size()!=7:
		print("guided-highlights-capture: itinerary FAIL");sim.stop();quit(1);return
	tour.pin_destinations(sky.starfield)
	for leg in 7:
		if not tour.advance(): failures+=1;break
		if leg<4:
			for phase in 4: tour.skip_stage()
			if sim.world.journey.state!="arrived":failures+=1;break
			continue
		var spec:Dictionary=tour.itinerary[leg]
		var committed:Dictionary=sim.world.duplicate(true)
		var total:float=committed.journey.plan.ship_years
		for left:float in [2.,1.,0.5,0.25,0.1,0.]:
			var desired:float=total-left/31557600.
			var current:float=sim.world.clock.tau-committed.clock.tau
			var before_tau:float=sim.world.clock.tau
			var before_year:float=sim.world.clock.year
			if not sim.send([],maxf(0.,desired-current)) or sim.world.clock.tau<before_tau or sim.world.clock.year<before_year:
				failures+=1;break
			await shot(spec.name.to_lower().replace(" ","_")+"_remaining_"+str(left),sim,left)
		if sim.world.journey.state!="arrived" or sim.world.ship.beta!=0. or sim.world.ship.pos!=sim.world.journey.plan.target.pos: failures+=1
		# Controller observes the same authoritative arrived state as its normal tick.
		tour.step()
	var f:=FileAccess.open(OUT.path_join("metrics.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"sampling":"authoritative final braking seconds; no position or clock edits","records":records,"failures":failures},"  ")+"\n");f.close()
	print("guided-highlights-capture: %d frames, %d failures" %[records.size(),failures])
	sim.stop();quit(1 if failures else 0)
func shot(name:String,sim:SimBridge,left:float)->void:
	var body:Dictionary={}
	var id:String=sim.world.journey.plan.hold.body
	for b:Dictionary in sim.world.system.bodies:
		if b.id==id:body=b;break
	if body.is_empty():failures+=1;return
	var v:=Planets.world_of(body.rel_km)
	var n:=Vector3(v[0],v[1],v[2]).normalized()
	sky.system_view.body_fader=true;sky.apply(sim.world)
	for i in 6:
		sky.camera.look(atan2(-n.x,-n.z),asin(clampf(n.y,-1.,1.)),0.)
		frame+=1;sky.finish_exposure_frame(1./60.,frame);await process_frame
	await RenderingServer.frame_post_draw
	var img:=root.get_texture().get_image();img.save_png(OUT.path_join(name+".png"))
	var centre:=img.get_pixel(640,360)
	var diameter:float=rad_to_deg(2.*Planets.angular_radius(body.radius_km,Planets.length64(v)))
	var finite:bool=is_finite(centre.r) and is_finite(centre.g) and is_finite(centre.b)
	if not finite or centre.r+centre.g+centre.b<0.05:failures+=1
	records.append({"name":name,"body":id,"remaining_ship_seconds":left,"phase":sim.world.ship.phase,"beta":sim.world.ship.beta,"earth_year":sim.world.clock.year,"ship_year":sim.world.clock.tau,"distance_km":Planets.length64(v),"diameter_deg":diameter,"centre":[centre.r,centre.g,centre.b],"finite":finite})
	print("guided-highlight ",name," deg=",diameter," centre=",centre," Earth+",sim.world.clock.year)
