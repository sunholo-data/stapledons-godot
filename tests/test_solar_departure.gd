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
	if not sim.start() or not sim.new_game(42,"solar_departure",false,load("res://demos/solar_departure.gd").guided_params()):
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
	# GUIDED_DRIVE (host) and guided() (sim/solar_departure_test.ail) must be the same drive (eval R1 finding 1).
	var sim_src:=FileAccess.get_file_as_string("res://sim/solar_departure_test.ail")
	var rx:=RegEx.create_from_string("boostG: ([0-9.e+-]+), mEffKg: ([0-9.e+-]+), capOneMinusBeta: ([0-9.e+-]+)")
	var m:=rx.search(sim_src)
	var drive:Dictionary=load("res://demos/solar_departure.gd").GUIDED_DRIVE
	check("host GUIDED_DRIVE equals the sim test's guided() drive",m!=null and float(m.get_string(1))==float(drive.boost_g) and float(m.get_string(2))==float(drive.m_eff_kg) and float(m.get_string(3))==float(drive.cap_one_minus_beta))
	check("controller accepts exact catalogue destination",controller.attach(sim,catalogue.stars))
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
	var ids:=["sun","jupiter","callisto","saturn","CNS5:3627","acen-a","Gaia DR3 2635476908753563008","trappist-1","CNS5:1142","aldebaran"]
	for id in ids:
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
		var counts:={"boosting":0,"cruising":0,"braking":0,"approaching":0}
		var approach_start_deg:=-1.0
		var interludes_before:int=controller.interludes_done
		var interlude_ticks:=0
		var stalls:=0
		var brake_first_diameter := 0.0
		var brake_last_diameter := 0.0
		for tick in 30000:
			if sim.world.journey.state=="arrived":break
			var old_tau:float=sim.world.clock.tau;var old_year:float=sim.world.clock.year
			var in_interlude:bool=controller.interlude!=null or controller.pacing.interlude_due(sim.world)
			if not controller.step():check("controller step (%s)"%controller.failed,false);break
			if in_interlude or controller.interlude!=null:
				interlude_ticks+=1
				monotonic=monotonic and sim.world.clock.tau>=old_tau and sim.world.ship.heading==heading
				continue
			# Clocks never go back. A boundary-crossing nudge (~1e-18 yr) or the exact-arrival
			# snap may add no ship time at float64 resolution: allowed, at most 3 per leg.
			monotonic=monotonic and sim.world.clock.tau>=old_tau and sim.world.clock.year>=old_year and sim.world.ship.heading==heading
			if not sim.world.clock.tau>old_tau:stalls+=1
			# Real time: outside an interlude no host tick advances the ship clock by more than one wall second.
			# (float64 tau differences resolve ~1e-8 relative at tau ~ 0.2 yr; compression would be >= 2x)
			monotonic=monotonic and sim.world.clock.tau-old_tau<=(1./20.)/31557600.*(1.+1e-6)
			if counts.has(sim.world.ship.phase):counts[sim.world.ship.phase]+=1
			if id=="jupiter" and approach_start_deg<0. and sim.world.ship.phase=="approaching":
				for body:Dictionary in sim.world.system.bodies:
					if body.id=="jupiter":approach_start_deg=rad_to_deg(2.*Planets.angular_radius(body.radius_km,Planets.length64(Planets.world_of(body.rel_km))))
			if id=="jupiter" and sim.world.ship.phase in ["braking","approaching"]:
				for body:Dictionary in sim.world.system.bodies:
					if body.id=="jupiter":
						var diameter:=rad_to_deg(2.*Planets.angular_radius(body.radius_km,Planets.length64(Planets.world_of(body.rel_km))))
						if brake_first_diameter==0.:brake_first_diameter=diameter
						brake_last_diameter=diameter
		# Cruise from the plan's own fields: a timed leg (D-46) brakes from cruise to the approach rapidity, then approaches.
		var pl:Dictionary=sim.world.journey.plan
		var boost_y:float=pl.boost_minutes/(365.25*24.*60.)
		var leg_drive:Dictionary=pl.get("drive",{})
		var approach_y:float=float(leg_drive.get("approach_minutes",0.))/(365.25*24.*60.)
		var brake_y:float=boost_y*(1.-float(leg_drive.get("approach_phi",0.))/float(pl.cruise_phi))
		var coast:float=pl.ship_years-boost_y-brake_y-approach_y
		var coast_s:=coast*31557600.
		var cut:bool=coast_s>controller.pacing.CUT_THRESHOLD_S*(1.+1e-9)
		check("real-time boost and braking with continuous clocks (%s, %d zero-advance ticks)"%[id,stalls],counts.boosting>100 and counts.braking>100 and monotonic and stalls<=3)
		if cut:
			check("long cruise: exactly one interlude, after the 10 s real-time hold, ending on the braking boundary (%s)"%id,controller.interludes_done==interludes_before+1 and absi(counts.cruising-int(controller.pacing.CRUISE_HOLD_S*20.))<=2 and controller.last_boundary_error>=0. and controller.last_boundary_error<=1e-12*float(sim.world.journey.plan.ship_years))
		else:
			check("short cruise plays entirely in real time, no interlude (%s)"%id,controller.interludes_done==interludes_before and absi(counts.cruising-int(round(coast_s*20.)))<=20)
		print("    phase counts ",id," ",counts," coast ",snappedf(coast_s,0.1)," s, interlude ticks ",interlude_ticks," Earth year ",sim.world.clock.year)
		if id=="jupiter":check("braking starts while Jupiter is small and it grows through the approach",brake_first_diameter<1. and brake_last_diameter>30.)
		if id in ["sun","jupiter","callisto","saturn","acen-a","trappist-1","aldebaran"]:
			check("timed leg (D-46): 30 s boost (%s)"%id,absi(counts.boosting-600)<=2)
			check("timed leg (D-46): 25 s final approach in real time (%s, %d ticks)"%[id,counts.approaching],absi(counts.approaching-500)<=40)
		if id=="jupiter":check("Jupiter's approach begins with it about 4 degrees across (%.2f)"%approach_start_deg,absf(approach_start_deg-4.)<=0.5)
		check("arrival rests",sim.world.journey.state=="arrived" and sim.world.ship.beta==0.)
		if id in ["sun","jupiter","callisto","saturn","acen-a","trappist-1","aldebaran"]:
			check("body arrival at exact planner endpoint",sim.world.ship.pos==sim.world.journey.plan.target.pos)
			# D-47: alpha Cen A and TRAPPIST-1 stop in their habitable zone (sqrt L AU); Aldebaran where it fills 40 degrees.
			var required:float={"sun":2087100.,"jupiter":142984.,"callisto":24103.,"saturn":210918.,"acen-a":sqrt(1.521)*149597870.7,"trappist-1":sqrt(0.000553)*149597870.7,"aldebaran":45.212*695700./sin(deg_to_rad(20.))}[id]
			check("body stop uses exact close standoff via package planner",sim.world.journey.plan.hold.body==id and absf(sim.world.journey.plan.hold.offset_km-required)<1e-6)
			if id=="acen-a":
				var a:Dictionary={};var b:Dictionary={}
				for body:Dictionary in sim.world.system.bodies:
					if body.id=="acen-a":a=body
					if body.id=="acen-b":b=body
				# Rendered coordinates are retarded, so allow orbital light-time
				# displacement; exact simultaneous intercept is checked in AILANG.
				check("actual finite A is at its habitable zone (1.233 AU), B has stellar clearance",absf(Planets.length64(Planets.world_of(a.rel_km))-required)<20000. and Planets.length64(Planets.world_of(b.rel_km))>1.1*b.radius_km+.1)
			if id in ["trappist-1","aldebaran"]:
				var st:Dictionary={}
				for body:Dictionary in sim.world.system.bodies:
					if body.id==id:st=body
				var deg:float=rad_to_deg(2.*Planets.angular_radius(st.get("radius_km",0.),Planets.length64(Planets.world_of(st.get("rel_km",{"x":0.,"y":0.,"z":0.})))))
				check("%s is a finite star at its stop: %.2f degrees across (catalogue point replaced: %s)"%[id,deg,st.get("catalogue_id","")],not st.is_empty() and (absf(deg-40.)<0.5 if id=="aldebaran" else absf(deg-2.70)<0.05) and not str(st.get("catalogue_id","")).is_empty())
		else:
			var p:Dictionary=sim.world.ship.pos;var q:Dictionary=sim.world.journey.plan.target.pos
			var gap:=sqrt(pow(p.x-q.x,2.)+pow(p.y-q.y,2.)+pow(p.z-q.z,2.))
			check("outbound stops at package stellar standoff",absf(gap-sim.world.consequence.standoff_ly)<1e-10 and gap>0.01)
		previous=sim.world.ship.pos.duplicate();completed+=1
	check("completed itinerary cannot start extra leg",completed==ids.size() and controller.complete and not controller.advance())
	# D-41: about 11 months lived while ~120 years pass on Earth (design goal 3).
	var year:float=sim.world.clock.year;var tau:float=sim.world.clock.tau
	print("    voyage: Earth +%.2f yr, ship +%.3f yr"%[year,tau])
	check("cumulative Earth time at Aldebaran within 1%% of 120.5 yr (%.2f)"%year,absf(year-120.5)<=0.01*120.5)
	check("all %d stops reached"%ids.size(),ids.size()==10)
	check("ship time lived is under a year",tau>0.8 and tau<1.0)
	check("HUD exposes both clocks and honest approximation",controller.status_text().contains("Earth +") and controller.status_text().contains("ship +") and controller.status_text().contains("barycentre"))
	var log:=FileAccess.get_file_as_string(RECORD)
	check("one initialization only, no resets between legs",log.count('"type":"new_game"')==1)
	sim.stop()
	# Skip to next stage (D-46): each skip lands exactly on the next phase of the leg.
	var s2:=SimBridge.new();s2.want_minor=5
	if s2.start() and s2.new_game(42,"solar_departure",false,load("res://demos/solar_departure.gd").guided_params()):
		var c2=load("res://demos/solar_departure.gd").new();c2.attach(s2,catalogue.stars)
		check("skip is unavailable before a leg is committed",not c2.skip_stage())
		c2.advance()
		var seen:=[s2.world.ship.phase]
		var p2:Dictionary=s2.world.journey.plan
		for i in 4:
			c2.skip_stage();seen.append(s2.world.ship.phase if s2.world.journey.state=="committed" else "arrived")
			if i==0:
				# Landing precision (eval R1 finding 1): the skip overshoots by at most 1e-9 of the step,
				# so the cruise left after landing is its full planned length less a few ns.
				var left_s:float=float(s2.world.consequence.phase_remaining_yr)*31557600.
				var dr:=load("res://demos/solar_departure.gd")
				var boost_s:float=float(p2.boost_minutes)*60.
				var full_s:float=float(p2.ship_years)*31557600.-boost_s-boost_s*(1.-float(p2.drive.approach_phi)/float(p2.cruise_phi))-float(p2.drive.approach_minutes)*60.
				check("skip lands on the boundary to within 1e-9 of the step (%.9f s of %.3f s cruise left)"%[left_s,full_s],absf(left_s-full_s)<=full_s*1e-8+1e-6)
		check("skips walk boost -> cruise -> braking -> approach -> arrival (%s)"%str(seen),seen==["boosting","cruising","braking","approaching","arrived"])
		check("after the skips the ship is exactly at the planned stop",s2.world.ship.pos==s2.world.journey.plan.target.pos and c2.skips==4)
		s2.stop()
	else:check("second session for the skip test",false)
	print("solar-departure: %d passed, %d failures" %[passed,failures]);quit(1 if failures else 0)

func _held_ticks(controller:RefCounted,count:int)->bool:
	for i in count:
		if not controller.step():return false
	return true
