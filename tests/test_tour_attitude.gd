extends SceneTree
var failures:=0
func check(ok:bool,label:String)->void:
	print(('ok ' if ok else 'FAIL ')+label)
	if not ok:failures+=1
func _initialize()->void:_run.call_deferred()
func _run()->void:
	var demo:Node=load('res://demos/ship_geometry_demo.tscn').instantiate()
	demo.setup_options={'stars':false,'background':false};root.add_child(demo)
	await process_frame
	demo.auto=false;demo.journey_auto_tick=false;demo.set_process(false)
	check(demo.start_solar_departure(),'new authoritative tour starts')
	if demo.solar_tour==null:quit(1);return
	var clock:Dictionary=demo.journey_sim.world.clock.duplicate(true)
	var position:Dictionary=demo.journey_sim.world.ship.pos.duplicate(true)
	var initial_observer:Basis=demo.sky.camera.global_basis
	demo._process(0.)
	check(initial_observer.is_equal_approx(demo.sky.camera.global_basis),'first tour frame preserves the initial observer, without an old-heading jump')
	demo._update_tour_attitude(0.)
	check(demo.solar_tour.attitude_hold,'initial side-view turn holds simulation')
	demo.solar_tour.paused=true
	var basis:PackedFloat64Array=demo.tour_attitude.current.duplicate()
	demo._update_tour_attitude(1.)
	check(demo.tour_attitude.current==basis,'pause also pauses attitude')
	demo.solar_tour.paused=false
	for frame in 180:
		demo._update_tour_attitude(1./60.)
		if demo.solar_tour.attitude_hold:demo.journey_tick()
	check(demo.journey_sim.world.clock==clock and demo.journey_sim.world.ship.pos==position,'stationary turn preserves position and both clocks')
	check(not demo.solar_tour.attitude_hold and absf(demo.camera.tilt-15.)<1e-5,'body beside bridge after bounded turn')
	demo.camera.follow(demo.avatar_pos,demo.camera.tilt,demo.camera.yaw,0.);demo._sync_observer()
	check(demo.sky.basis==demo.camera.attitude_basis,'sky receives same ship attitude as geometry observer')
	demo._process(0.)
	check(not demo.avatar.visible and demo.avatar_shadow.is_visible_in_tree() and demo.avatar_shadow.global_position==demo.avatar.global_position,'captain still casts grounded shadow in first person')
	check(demo.solar_tour.prepare_next(),'next stop prepares heading without moving')
	demo._update_tour_attitude(0.)
	check(demo.solar_tour.attitude_hold and not demo.live_journey,'departure turns before committing')
	for frame in 179:
		demo._process(1./60.);demo.journey_tick()
	check(demo.journey_sim.world.clock==clock and demo.journey_sim.world.ship.pos==position,'prepared turn cannot advance or teleport ship')
	var earth_before:=observer_ray(demo,"earth")
	demo._process(1./60.)
	check(demo.live_journey and demo.solar_tour.pending_index<0,'commit follows complete turn')
	var first_physical_seconds:float=(demo.journey_sim.world.clock.tau-clock.tau)*31557600.
	check(absf(first_physical_seconds-.05)<1e-6,'actual commitment advances one real-time display tick, not 102 compressed seconds')
	var first_angle:=rad_to_deg(earth_before.angle_to(observer_ray(demo,"earth")))
	check(first_angle<.2,'actual near-Earth departure commitment has no compressed first-frame jump')
	var max_earth_step:=first_angle
	for tick in 60:
		var previous_ray:=observer_ray(demo,"earth")
		demo.journey_tick();demo._process(0.)
		max_earth_step=maxf(max_earth_step,rad_to_deg(previous_ray.angle_to(observer_ray(demo,"earth"))))
	print('actual departure max Earth angular step ',max_earth_step,' deg; firstcommit ',first_angle)
	check(max_earth_step<3.,'first three departure seconds bound actual near-Earth angular steps below three degrees')
	var expected:=ShipFrame.ship_basis(demo.camera.heading)
	check(demo.camera.attitude_basis==expected,'travel returns exact forward-pole frame without turnover flip')
	demo.queue_free();await process_frame
	print('tour-attitude: %d failures'%failures);quit(1 if failures else 0)

func observer_ray(demo:Node,id:String)->Vector3:
	for body:Dictionary in demo.sky_world.system.bodies:
		if body.id==id:
			var v:=Planets.world_of(body.rel_km)
			var ray:=Relativity.aberrate(Vector3(v[0],v[1],v[2]).normalized(),demo.sky.heading_world,demo.sky.beta)
			return demo.sky.camera.global_basis.transposed()*ray
	return Vector3.ZERO
