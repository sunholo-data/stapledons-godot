extends SceneTree
## Real AILANG Sol -> A -> B -> C, without resetting or opening new sessions.
var passed := 0
var failures := 0
const RECORD := "user://test_map_origin.ndjson"
func check(label: String, condition: bool) -> void:
	if condition: passed += 1
	else: failures += 1
	print("  %s %s" % ["ok" if condition else "FAIL", label])
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var sim := SimBridge.new();sim.record_path=RECORD;sim.want_minor=5
	if not sim.start() or not sim.new_game(42,"sol",false):
		check("real sim starts",false);quit(1);return
	var vp:=SubViewport.new();vp.size=Vector2i(1280,800);root.add_child(vp)
	var map:=GalaxyMap.new();map.auto_tick=false;vp.add_child(map)
	map.load_catalogue("res://data/starmap/stars.json");map.attach(sim)
	check("protocol 2.5 negotiated",sim.hello_reply.proto.minor==5)
	check("ship-origin route API exists",map.has_method("route_points") and map.has_method("fit_journey") and map.has_method("centre_on_ship"))
	if not map.has_method("route_points"):
		sim.stop();vp.queue_free();await process_frame;quit(1);return
	var at:=Vector3.ZERO
	var galactic_at:={"x":0.,"y":0.,"z":0.}
	check("initial system label is Sol",map.ship_location_text()=="Ship · Sol")
	for target in [{"x":2.123456789012,"y":-1.987654321098,"z":.512345678912},{"x":5.123456789012,"y":4.987654321098,"z":-2.512345678912},{"x":-3.123456789012,"y":6.987654321098,"z":1.512345678912}]:
		check("at-rest marker matches current ship",map.ship_marker_visible() and map.ship_world_pos().distance_to(at)<1e-5)
		map.plan_target({"index":0,"id":"test waypoint","pos":target});map.tick()
		if map.journey_state()!="planned":
			check("waypoint accepted (%s)" % sim.last_refused,false);sim.stop();vp.queue_free();await process_frame;quit(1);return
		var dest:=Starfield.galactic_to_world(Vector3(target.x,target.y,target.z))
		var points:PackedVector3Array=map.route_points()
		check("preview starts at current ship, not Sol",points.size()==2 and points[0].distance_to(at)<1e-5 and points[1].distance_to(dest)<1e-5)
		map.fit_journey();await process_frame
		var viewport_size:=Vector2(vp.size)
		var view:=Rect2(Vector2(24,24),viewport_size-Vector2(GalaxyMap.PANEL_WIDTH+48,48))
		check("fit includes both endpoints clear of panel",view.has_point(map.camera.unproject_position(at)) and view.has_point(map.camera.unproject_position(dest)))
		var tau:float=sim.world.clock.tau;var year:float=sim.world.clock.year;var tick:int=sim.world.tick
		var distance:float=map.dist
		map.pivot=Vector3(19,7,-11);map._update_camera();map.refresh()
		check("refresh preserves manual camera",map.pivot==Vector3(19,7,-11) and map.dist==distance)
		var old_pivot:Vector3=map.pivot;var old_yaw:float=map.yaw
		var pan:=InputEventMouseMotion.new();pan.button_mask=MOUSE_BUTTON_MASK_LEFT;pan.shift_pressed=true;pan.relative=Vector2(35,-19)
		map._unhandled_input(pan)
		var manual_pivot:Vector3=map.pivot;map.tick()
		check("Shift-drag pans and subsequent tick preserves it",manual_pivot.distance_to(old_pivot)>0.1 and map.pivot==manual_pivot and map.yaw==old_yaw)
		tau=sim.world.clock.tau;year=sim.world.clock.year;tick=sim.world.tick
		map.centre_on_ship()
		check("centre places ship in unobscured map",view.has_point(map.camera.unproject_position(at)))
		map.fit_journey()
		check("framing leaves clocks/tick unchanged",sim.world.clock.tau==tau and sim.world.clock.year==year and sim.world.tick==tick)
		map.open_commit_dialog();map.hold_commit(GalaxyMap.HOLD_S);map.tick()
		check("real journey commits",map.journey_state()=="committed")
		var route:PackedVector3Array=map.route_points()
		check("committed route retains recorded departure",route.size()==2 and route[0].distance_to(at)<1e-5 and route[1].distance_to(dest)<1e-5)
		var plan:Dictionary=sim.world.journey.plan
		check("sim plan preserves exact float64 departure",plan.get("departure",{})==galactic_at)
		sim.send([],plan.ship_years*.3);map.refresh()
		check("transit marker advances independently of route",map.ship_marker_visible() and map.ship_world_pos().distance_to(at)>1e-3 and map.route_points()[0].distance_to(at)<1e-5)
		# A fresh map must recover the route directly from the same sim state.
		var reopened:=GalaxyMap.new();reopened.auto_tick=false;vp.add_child(reopened);reopened.attach(sim)
		check("reopening committed map retains departure",reopened.route_points().size()==2 and reopened.route_points()[0].distance_to(at)<1e-5)
		reopened.queue_free()
		for i in 10:
			if map.journey_state()=="arrived":break
			sim.send([],plan.ship_years*.3);map.refresh()
		check("arrival marker and preserved full route",map.journey_state()=="arrived" and map.ship_marker_visible() and map.ship_world_pos().distance_to(dest)<1e-5 and map.route_points()[0].distance_to(at)<1e-5)
		check("both clocks advance across each journey",sim.world.clock.tau>tau and sim.world.clock.year>year)
		at=dest
		galactic_at=target.duplicate()
	# Exact-ID handoff frames the current ship and this selected catalogue row.
	var id:="CNS5:3627";var index:=map.index_of(id)
	map.preselect(index);map.frame_star(index);map.tick()
	check("exact ID handoff plans same row from latest ship",sim.world.journey.plan.target.id==id and map.route_points()[0].distance_to(at)<1e-5)
	var handoff_view:=Rect2(Vector2(24,24),Vector2(vp.size)-Vector2(GalaxyMap.PANEL_WIDTH+48,48))
	check("handoff frames ship and selected star clear of panel",handoff_view.has_point(map.camera.unproject_position(at)) and handoff_view.has_point(map.screen_position(index)))
	check("real framing controls installed",map.centre_button.text=="Centre on ship" and map.fit_button.text=="Fit journey" and map.centre_button.is_inside_tree())
	for size in [Vector2i(1280,800),Vector2i(900,600),Vector2i(960,540)]:
		vp.size=size;await process_frame;await process_frame
		var bounds:=Rect2(Vector2.ZERO,Vector2(size))
		check("fixed actions reachable at %s" % size,bounds.encloses(map.commit_button.get_global_rect()) and bounds.encloses(map.cancel_button.get_global_rect()) and bounds.encloses(map.centre_button.get_global_rect()) and bounds.encloses(map.fit_button.get_global_rect()))
	map.centre_button.pressed.emit();map.fit_button.pressed.emit()
	map.guided_read_only=true;map.refresh()
	var guided_id:int=sim.world.journey.plan_id;var guided_target:String=sim.world.journey.plan.target.id
	map.preselect(map.index_of("HIP 71681"));map.set_cruise_phi(map.phi_min);map.press_cancel()
	check("guided browsing cannot commit or cancel",not map.open_commit_dialog() and not map.hold_commit(10.) and map.commit_button.disabled and map.cancel_button.disabled)
	map.tick()
	check("guided browsing leaves itinerary plan intact",sim.world.journey.plan_id==guided_id and sim.world.journey.plan.target.id==guided_target)
	var log:=FileAccess.get_file_as_string(RECORD)
	check("no hidden new_game on any framing/reopen",log.count('"type":"new_game"')==1)
	for minor in [1,4]:
		var legacy:=SimBridge.new();legacy.want_minor=minor
		check("legacy negotiated session starts",legacy.start() and legacy.new_game(42,"sol",false))
		legacy.send([map.plan_intent(index)],0.)
		check("legacy plan bytes omit new departure field",not legacy.world.journey.plan.has("departure") and legacy.hello_reply.proto.minor==minor)
		legacy.stop()
	sim.stop();vp.queue_free();await process_frame
	print("map-origin: %d passed, %d failures" % [passed,failures]);quit(1 if failures else 0)
