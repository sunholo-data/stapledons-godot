extends SceneTree
## Actual normal body records and independent stationary attitude reproduce the
## old transient-view meter; adaptation is explicitly a display policy.
var checks:=0
var failures:=0
func check(label:String,ok:bool)->void:
	checks+=1;if not ok:failures+=1;print("FAIL ",label)
func _initialize()->void:run.call_deferred()
func run()->void:
	var sky:=InteriorSky.new();root.add_child(sky)
	sky.setup({"position_m":[0,0,0],"forward":[0,0,1],"up":[0,1,0]},78.,Vector2i(800,600),{"stars":false,"background":false,"planet_textures":false,"planet_preload":false})
	var sim:=SimBridge.new();sim.want_minor=5
	check("normal authoritative fixtures",sim.start() and sim.new_game(19))
	if sim.world.is_empty():print("fixture sim error ",sim.last_error);quit(1);return
	var source:=sim.world.duplicate(true);var baseline:=sky.exposure.ev_dark();var worlds:=[]
	for id:String in ["earth","jupiter"]:
		var body:Dictionary={}
		for b:Dictionary in source.system.bodies:
			if b.id==id:body=b.duplicate(true)
		var distance:float=body.radius_km*8.
		body.rel_km={"x":distance,"y":0.,"z":0.};body.sun_dir={"x":-1.,"y":0.,"z":0.};body.phase_deg=0.
		body.e_v_lux=Planets.disc_illuminance(127057.41052085394,body.p_v,body.radius_km,body.r_au,distance,0.,body.minnaert_k)
		var world:=source.duplicate(true);world.system.bodies=[body];world.ship.heading={"x":1.,"y":0.,"z":0.}
		worlds.append(world)
		sky.apply(world);var transient:=sky.exposure.ev
		sky.orient_basis(ShipFrame.ship_basis(PackedFloat64Array([-1,0,0])));sky.update_exposure()
		var final_view:=sky.exposure.ev
		print("transient-view ",id," EV ",transient," final-view ",final_view)
		check(id+" old transient heading produces large EV discontinuity",transient-final_view>8. and absf(final_view-baseline)<1e-8)
	check("frame exposure API exists",sky.has_method("finish_exposure_frame"))
	if not sky.has_method("finish_exposure_frame"):
		sim.stop();sky.queue_free();await process_frame
		print("exposure-frames: %d checks %d failures"%[checks,failures]);quit(1);return
	var sun:Dictionary={}
	for b:Dictionary in source.system.bodies:
		if b.id=="sun":sun=b.duplicate(true)
	sun.rel_km={"x":149597870.7,"y":0.,"z":0.};sun.e_v_lux=127057.41052085394
	var solar:=source.duplicate(true);solar.system.bodies=[sun];solar.ship.heading={"x":1.,"y":0.,"z":0.};worlds.append(solar)
	var frame:=1000
	for world:Dictionary in worlds:
		var id:String=world.system.bodies[0].id
		sky.set_temporal_exposure(false);sky.exposure.bias=-2.
		sky.orient_basis(ShipFrame.ship_basis(PackedFloat64Array([-1,0,0])));sky.update_exposure()
		var dark:=sky.exposure.ev
		sky.set_temporal_exposure(true)
		for j in 20:
			for call_index in 4:sky.apply(world);sky.update_exposure()
			check(id+" intermediate apply never changes displayed EV "+str(j),absf(sky.exposure.ev-dark)<1e-10)
			sky.orient_basis(ShipFrame.ship_basis(PackedFloat64Array([-1,0,0])))
			frame+=1;sky.finish_exposure_frame(1./60.,frame)
			check(id+" final away view is stable despite repeated20Hz-style applies "+str(j),absf(sky.exposure.ev-dark)<1e-10)
		sky.orient_basis(ShipFrame.ship_basis(PackedFloat64Array([1,0,0])))
		frame+=1;sky.finish_exposure_frame(1./60.,frame)
		var bright:=sky.exposure.ev
		check(id+" entering bright final view protects immediately",bright-dark>10. if id=="sun" else bright-dark>8.)
		var p99:=sky.system_view.highlight_luminance(sky.camera,Vector2(sky.size))
		check(id+" finalview physical highlights protected with4x bias",p99==0. or p99*sky.exposure.k()<=1.01)
		sky.orient_basis(ShipFrame.ship_basis(PackedFloat64Array([-1,0,0])))
		frame+=1;sky.finish_exposure_frame(1./60.,frame)
		var first:=sky.exposure.ev
		check(id+" leaving bright body fades instead of snapping",first<bright and bright-first<=Exposure.DISPLAY_EV_RATE/60.+1e-9 and first>dark+1.)
		for repeated in 8:sky.update_exposure();sky.finish_exposure_frame(1./60.,frame)
		check(id+" multiple calls same frame cannot accelerate fade",sky.exposure.ev==first)
		var previous:=first;var max_step:=0.
		for j in 400:
			frame+=1;sky.finish_exposure_frame(1./60.,frame)
			max_step=maxf(max_step,absf(previous-sky.exposure.ev))
			check(id+" fade monotonic "+str(j),sky.exposure.ev<=previous+1e-10 and sky.exposure.ev>=dark-1e-10)
			previous=sky.exposure.ev
		check(id+" fade rate bounded and converges to biased dark reference",max_step<=Exposure.DISPLAY_EV_RATE/60.+1e-9 and absf(previous-dark)<1e-8)
		print("display-policy ",id," brightEV=",bright," darkEV=",dark," maxFrameStep=",max_step)
		sky.exposure.fixed=true;sky.exposure.fixed_ev=7.;frame+=1;sky.finish_exposure_frame(.01,frame)
		check(id+" fixed reference bypasses temporal policy",sky.exposure.ev==7.)
		sky.exposure.fixed=false
		sky.set_debug_unit(true);sky.apply(world);sky.update_exposure()
		var expected:=sky.exposure.mode_ev(sky._meter_samples[0],sky._meter_samples[1])+sky.exposure.bias
		check(id+" debug reference remains instantaneous",absf(sky.exposure.ev-clampf(expected,sky.exposure.clamp_ev.x,sky.exposure.clamp_ev.y))<1e-9)
		sky.set_debug_unit(false)
	for world:Dictionary in worlds:
		var id:String=world.system.bodies[0].id
		sky.set_temporal_exposure(false);sky.exposure.bias=-2.;sky.apply(world)
		sky.camera.look(deg_to_rad(110.),0.,0.);sky.update_exposure()
		sky.set_temporal_exposure(true)
		var previous:=sky.exposure.ev;var max_rise:=0.;var max_fall:=0.
		var before_stats:=sky.exposure_stats();var started:=Time.get_ticks_usec()
		for j in 221:
			if j%3==0:sky.apply(world) # repeated normal20Hz host-state refresh
			sky.camera.look(deg_to_rad(110.-j*.5),0.,0.) # 30 deg/s continuous look
			frame+=1;sky.finish_exposure_frame(1./60.,frame)
			max_rise=maxf(max_rise,sky.exposure.ev-previous);max_fall=maxf(max_fall,previous-sky.exposure.ev)
			previous=sky.exposure.ev
		var pan_usec:=Time.get_ticks_usec()-started;var stats:=sky.exposure_stats()
		check(id+" ordinary30deg/s pan has no exposure snap",max_rise<=Exposure.DISPLAY_EV_RISE_RATE/60.+1e-8 and max_fall<=Exposure.DISPLAY_EV_RATE/60.+1e-8)
		check(id+" walking/look meter samples at most20Hz",stats.samples-before_stats.samples<=76)
		var settled:=sky.exposure.ev;var settled_samples:=sky.meter_sample_count
		for j in 120:
			if j%3==0:sky.apply(world)
			sky.camera.look(0.,0.,0.);frame+=1;sky.finish_exposure_frame(1./60.,frame)
		check(id+" unchanged20Hz world refresh avoids all repeated meters",sky.meter_sample_count-settled_samples<=1)
		check(id+" in-FOV finalcamera20Hz updates never pulse",absf(sky.exposure.ev-settled)<1e-8)
		print("continuous-pan ",id," maxRise=",max_rise," maxFall=",max_fall," samples=",stats.samples-before_stats.samples," CPUwall_us=",pan_usec," stats=",stats)
	for original:Dictionary in worlds.slice(0,2):
		for offset:float in [0.,25.,45.]:
			var world:=original.duplicate(true);var body:Dictionary=world.system.bodies[0]
			var direction:=Vector3(sin(deg_to_rad(offset)),0.,-cos(deg_to_rad(offset)))
			var gal:=SkyFrame.to_galactic64([direction.x,direction.y,direction.z])
			var maximum_step:=0.;var last:=0.;var initialized:=false
			for j in range(-30,121):
				var diameter:=1.+maxi(j,0)*.025
				var distance:float=body.radius_km/sin(deg_to_rad(diameter)*.5)
				body.rel_km={"x":gal[0]*distance,"y":gal[1]*distance,"z":gal[2]*distance}
				body.sun_dir={"x":-gal[0],"y":-gal[1],"z":-gal[2]}
				body.e_v_lux=Planets.disc_illuminance(127057.41052085394,body.p_v,body.radius_km,body.r_au,distance,0.,body.minnaert_k)
				sky.apply(world);sky.camera.look(0.,0.,0.);frame+=1;sky.finish_exposure_frame(.05,frame)
				if j>=0:
					if initialized:maximum_step=maxf(maximum_step,absf(sky.exposure.ev-last))
					initialized=true;last=sky.exposure.ev
			check(body.id+" compact2deg boundary is stable atoffset"+str(offset),maximum_step<.05)
			print("compact-boundary ",body.id," offset=",offset," maxEVstep=",maximum_step)
	check("no authority state changes",sim.world==source)
	sim.stop();sky.queue_free();await process_frame
	print("exposure-frames: %d checks %d failures"%[checks,failures]);quit(1 if failures else 0)
