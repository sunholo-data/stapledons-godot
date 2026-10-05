extends SceneTree
## Normal negotiated sidecar, an Earth start and successive irreversible legs.
var passed:=0
var failures:=0
const RECORD:="user://solar_departure_test.ndjson"
func check(name:String,condition:bool)->void:
	if condition:passed+=1
	else:failures+=1
	print("  %s %s" % ["ok" if condition else "FAIL",name])
func _initialize()->void:_run.call_deferred()
func _run()->void:
	var sim:=SimBridge.new();sim.want_minor=5;sim.record_path=RECORD
	if not sim.start() or not sim.new_game(42,"solar_departure",false,{"standoff_au":1000.,"boost_g":1.0,"m_eff_kg":10.,"cap_one_minus_beta":.01}):
		check("scenario starts (%s)" % sim.last_error,false);sim.stop();quit(1);return
	var earth:Dictionary={}
	for body:Dictionary in sim.world.system.bodies:
		if body.id=="earth":earth=body
	var rel:Dictionary=earth.rel_km
	var separation:=sqrt(rel.x*rel.x+rel.y*rel.y+rel.z*rel.z)
	check("new scenario is near Earth at two radii",absf(separation-2.*earth.radius_km)<20.)
	check("close-view metadata carries exact per-leg standoffs",sim.world.solar_departure.legs[0].id=="sun" and sim.world.solar_departure.legs[0].get("standoff_km",0.)==2087100. and sim.world.solar_departure.legs[1].get("standoff_km",0.)==142984. and sim.world.solar_departure.legs[3].get("standoff_km",0.)==210918.)
	check("scenario carries itinerary and EMB approximation",sim.world.has("solar_departure") and sim.world.solar_departure.approximation.contains("barycentre"))
	if not sim.world.has("solar_departure"):
		sim.stop();print("solar-departure: %d passed, %d failures" %[passed,failures]);quit(1);return
	var controller=load("res://demos/solar_departure.gd").new()
	var catalogue:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/starmap/stars.json"))
	var outbound:Dictionary={}
	for index in catalogue.stars.size():
		var star:Dictionary=catalogue.stars[index]
		if star.id=="CNS5:3627":outbound=star.duplicate();outbound.index=index
	check("controller accepts exact catalogue destination",controller.attach(sim,outbound))
	var before:Dictionary=sim.world.duplicate(true)
	check("initial dwelling advances real time without moving ship",controller.step() and sim.world.ship.pos==before.ship.pos and sim.world.clock.tau>before.clock.tau and absf(sim.world.clock.tau-before.clock.tau-0.05/31557600.)<1e-15)
	controller.deferred_commit=true
	controller.dwell_left=0.05
	check("dwell expiry prepares only until runtime attitude turn is ready",controller.step() and controller.pending_index==0 and sim.world.journey.state=="planned" and controller.leg_index==-1)
	var deferred:Dictionary=sim.world.duplicate(true)
	check("a pending prepared leg cannot be duplicated",not controller.prepare_next() and sim.world==deferred)
	controller.attitude_hold=true
	check("three wall seconds of attitude hold leave both clocks and position unchanged",_held_ticks(controller,60) and sim.world==deferred and not controller.commit_prepared())
	controller.attitude_hold=false
	var previous:Dictionary=sim.world.ship.pos.duplicate()
	var completed:=0
	for id in ["sun","jupiter","callisto","saturn","CNS5:3627","acen-a"]:
		var start:Dictionary=sim.world.duplicate(true)
		controller.attitude_hold=true
		check("attitude hold pauses clocks and rejects premature leg",controller.step() and sim.world==start and not controller.prepare_next())
		controller.attitude_hold=false
		# The first leg was genuinely prepared by dwell expiry above; later
		# legs exercise the explicit Next path, without altering controller state.
		var prepared:bool=controller.pending_index==0 if completed==0 else controller.prepare_next()
		check("prepare exposes authoritative heading without committing",prepared and sim.world.journey.state=="planned" and controller.pending_heading==sim.world.journey.plan.heading and sim.world.ship.pos==start.ship.pos and sim.world.clock==start.clock)
		var planned:Dictionary=sim.world.duplicate(true)
		check("pending presentation turn pauses simulation",controller.step() and sim.world==planned)
		# A caller accidentally advancing epoch between planning and commitment
		# still gets a fresh intercept; commit_prepared does not use a stale plan.
		sim.send([],0.05/31557600.)
		var advanced:bool=controller.commit_prepared()
		check("explicit next leg commits (%s)" %controller.failed,advanced and sim.world.journey.state=="committed" and sim.world.journey.plan.target.id==id)
		if not advanced:sim.stop();print("solar-departure: %d passed, %d failures" %[passed,failures]);quit(1);return
		check("new plan starts at actual previous endpoint",sim.world.journey.plan.departure==previous)
		var committed:Dictionary=sim.world.duplicate(true)
		check("tour cannot turn/skip committed leg",not controller.advance() and sim.world==committed)
		var heading:Dictionary=sim.world.ship.heading.duplicate()
		var monotonic:=true
		var counts:={"boosting":0,"cruising":0,"braking":0}
		var brake_first_diameter := 0.0
		var brake_last_diameter := 0.0
		for tick in 4000:
			if sim.world.journey.state=="arrived":break
			var old_tau:float=sim.world.clock.tau;var old_year:float=sim.world.clock.year
			if not controller.step():check("controller step",false);break
			monotonic=monotonic and sim.world.clock.tau>old_tau and sim.world.clock.year>old_year and sim.world.ship.heading==heading
			if counts.has(sim.world.ship.phase):counts[sim.world.ship.phase]+=1
			if id=="jupiter" and sim.world.ship.phase=="braking":
				for body:Dictionary in sim.world.system.bodies:
					if body.id=="jupiter":
						var diameter:=rad_to_deg(2.*Planets.angular_radius(body.radius_km,Planets.length64(Planets.world_of(body.rel_km))))
						if brake_first_diameter==0.:brake_first_diameter=diameter
						brake_last_diameter=diameter
		var coast:float=sim.world.journey.plan.ship_years-2.*sim.world.journey.plan.boost_minutes/(365.25*24.*60.)
		check("physical phases are visible with continuous clocks",counts.boosting>100 and counts.braking>100 and (counts.cruising>100 if coast>1e-12 else counts.cruising==0) and monotonic)
		print("    phase counts ",id," ",counts," physical coast years ",coast)
		if id=="jupiter":check("one-g braking starts while Jupiter is small and grows throughout braking",brake_first_diameter<1. and brake_last_diameter>30.)
		check("arrival rests",sim.world.journey.state=="arrived" and sim.world.ship.beta==0.)
		if id in ["sun","jupiter","callisto","saturn","acen-a"]:
			check("body arrival at exact planner endpoint",sim.world.ship.pos==sim.world.journey.plan.target.pos)
			var required:float={"sun":2087100.,"jupiter":142984.,"callisto":24103.,"saturn":210918.,"acen-a":149597870.7}[id]
			check("body stop uses exact close standoff via package planner",sim.world.journey.plan.hold.body==id and absf(sim.world.journey.plan.hold.offset_km-required)<1e-6)
			if id=="acen-a":
				var a:Dictionary={};var b:Dictionary={}
				for body:Dictionary in sim.world.system.bodies:
					if body.id=="acen-a":a=body
					if body.id=="acen-b":b=body
				# Rendered coordinates are retarded, so allow orbital light-time
				# displacement; exact simultaneous intercept is checked in AILANG.
				check("actual finite A is approximately 1 AU, B has stellar clearance",absf(Planets.length64(Planets.world_of(a.rel_km))-required)<20000. and Planets.length64(Planets.world_of(b.rel_km))>1.1*b.radius_km+.1)
		else:
			var p:Dictionary=sim.world.ship.pos;var q:Dictionary=sim.world.journey.plan.target.pos
			var gap:=sqrt(pow(p.x-q.x,2.)+pow(p.y-q.y,2.)+pow(p.z-q.z,2.))
			check("outbound stops at package stellar standoff",absf(gap-sim.world.consequence.standoff_ly)<1e-10 and gap>0.01)
		previous=sim.world.ship.pos.duplicate();completed+=1
	check("completed itinerary cannot start extra leg",completed==6 and controller.complete and not controller.advance())
	check("HUD exposes both clocks and honest approximation",controller.status_text().contains("Earth +") and controller.status_text().contains("ship +") and controller.status_text().contains("barycentre"))
	var log:=FileAccess.get_file_as_string(RECORD)
	check("one initialization only, no resets between legs",log.count('"type":"new_game"')==1)
	sim.stop()
	print("solar-departure: %d passed, %d failures" %[passed,failures]);quit(1 if failures else 0)

func _held_ticks(controller:RefCounted,count:int)->bool:
	for i in count:
		if not controller.step():return false
	return true
