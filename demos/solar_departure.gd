extends RefCounted
## Explicit guided demo controller. AILANG owns every position and intercept;
## this host sequences already-authorized commitments and presentation time.
## Caller starts one new solar_departure session, never resets an active voyage.
signal world_updated(world: Dictionary)
const TICK_HZ := 20.
const JULIAN_YEAR_SECONDS := 31557600.
const DWELL_SECONDS := 12.
## D-39/D-40/D-41 guided drive, one definition for the whole voyage: 3,000,000 g,
## cap 1 - beta = 5e-7 (the 0.999999c Aldebaran leg), m_eff 10 kg. The sim's
## unchanged scenarioError (brake vs ISM drag at the cap) accepts it (RT0).
## sim/solar_departure_test.ail's guided() mirrors these values.
const GUIDED_DRIVE := {"boost_g":3000000.0,"m_eff_kg":10.0,"cap_one_minus_beta":0.0000005}
const STANDOFF_AU := 1000.0
var sim: SimBridge
var stars: Dictionary = {} # star-leg catalogue id -> row (with its catalogue index)
var itinerary: Array
var leg_index := -1
var dwell_left := DWELL_SECONDS
var complete := false
var paused := false
var attitude_hold := false
var deferred_commit := false
var pending_index := -1
var pending_heading: Dictionary = {}
var pending_name := ""
var failed := ""
var pacing := preload("res://ui/journey_pacing.gd").new()
## The active cruise interlude (D-41), or null. interlude_factory makes the next
## one: the demo card today, in-ship gameplay later; the host loop is the same.
var interlude: CruiseInterlude = null
var interlude_factory: Callable = func() -> CruiseInterlude: return CardInterlude.new()
var interludes_done := 0
var last_boundary_error := -1.0

## new_game params for a guided voyage: the catalogue stand-off plus GUIDED_DRIVE.
static func guided_params() -> Dictionary:
	var p:Dictionary={"standoff_au":STANDOFF_AU};p.merge(GUIDED_DRIVE);return p

## catalogue: the star rows in catalogue order (GalaxyMap.catalogue or stars.json's
## "stars"); every star leg is resolved by exact id, failing closed if one is missing.
func attach(bridge: SimBridge, catalogue: Array) -> bool:
	if bridge.world.get("journey",{}).get("state","")=="committed":return false
	var metadata: Dictionary=bridge.world.get("solar_departure",{})
	if metadata.is_empty():return false
	var found:={}
	for spec:Dictionary in metadata.legs:
		if spec.kind!="star":continue
		for i in catalogue.size():
			if catalogue[i].get("id","")==spec.id:found[spec.id]=catalogue[i].duplicate(true);found[spec.id].index=i;break
		if not found.has(spec.id):return false
	pacing.guided_approach=true
	sim=bridge;stars=found;itinerary=metadata.legs.duplicate(true)
	return true

## Every star-leg destination renders at the position the sim navigates to
## (Starfield.pin_destination): one sky catalogue can sit thousands of AU off.
func pin_destinations(starfield: Starfield) -> void:
	if starfield==null:return
	for id:String in stars:starfield.pin_destination(stars[id])

## A body leg's plan intent; a timed leg (D-46) forwards the sim's own timing.
static func _body_intent(spec: Dictionary) -> Dictionary:
	var intent:=SimBridge.body_plan(spec.id,spec.cruise_phi,{"mode":"stop","standoff_km":spec.standoff_km})
	if spec.has("timing"):intent["timing"]=spec.timing.duplicate()
	return intent

## Skip to the next stage of the committed leg (D-46): accelerating -> cruise ->
## braking -> final approach -> arrival. The sim is stepped by exactly the time
## the sim reports to the phase boundary (consequence.phase_remaining_yr), so
## clocks and consequences stay the sim's. A long cruise skips through its
## interlude; at rest the existing Next stop applies. Labelled on the HUD.
var skips := 0
func skip_stage() -> bool:
	if sim==null or not failed.is_empty() or paused or attitude_hold or pending_index>=0:return false
	if interlude!=null:
		if interlude is CardInterlude:(interlude as CardInterlude).finish()
		return step()
	if sim.world.journey.state!="committed":return false
	if sim.world.ship.phase=="cruising" and pacing.interlude_due(sim.world):return step()
	# The consequence section is reported for the state before its tick, so refresh it
	# with a zero-length tick before reading the time to the boundary.
	if not _send([],0.):return false
	var left:float=float(sim.world.get("consequence",{}).get("phase_remaining_yr",0.0))
	if not (left>0.0):return false
	# phase_remaining_yr crosses the bridge as a ~12-digit decimal, so landing exactly on the
	# boundary can fall short; a nudge of 1e-9 of the step (60 ns on a 60 s cruise) crosses
	# it, and the sim splits the step exactly at the boundary.
	if not _send([],left+maxf(left*1e-9,maxf(absf(float(sim.world.clock.tau))*4e-15,1e-18))):return false
	skips+=1
	if sim.world.journey.state=="arrived":
		if leg_index==itinerary.size()-1:complete=true
		else:dwell_left=DWELL_SECONDS
	return true

## This leg's thrust in g: the timed leg's own drive (plan.drive), else the session's.
func leg_thrust_g() -> float:
	var plan:Dictionary=sim.world.get("journey",{}).get("plan",{}) if sim!=null else {}
	if plan.has("drive"):return float(plan.drive.boost_g)
	return float(GUIDED_DRIVE.boost_g)

func _star_intent(spec: Dictionary) -> Dictionary:
	var row:Dictionary=stars.get(spec.id,{})
	if row.is_empty():return {}
	return {"k":"plan","target":{"index":int(row.index),"id":row.id,"pos":{"x":row.x,"y":row.y,"z":row.z}},"cruise_phi":spec.cruise_phi}

func _send(intents: Array, dtau: float) -> bool:
	if not sim.send(intents,dtau):failed=sim.last_error;return false
	if not sim.last_refused.is_empty():failed=str(sim.last_refused);return false
	world_updated.emit(sim.world)
	return true

## An explicit Next stop skips a stationary dwell only; it cannot turn in flight.
func advance() -> bool:
	return prepare_next() and commit_prepared()

func prepare_next() -> bool:
	if sim==null or complete or attitude_hold or pending_index>=0 or not failed.is_empty() or sim.world.journey.state=="committed":return false
	var next:=leg_index+1
	if next>=itinerary.size():complete=true;return false
	var spec:Dictionary=itinerary[next]
	var intent:Dictionary
	if spec.kind=="body":intent=_body_intent(spec)
	else:
		intent=_star_intent(spec)
		if intent.is_empty():failed="star leg catalogue identity missing";return false
	# Body plans are epoch-sensitive: zero elapsed time between plan and commit.
	if not _send([intent],0.):return false
	pending_index=next;pending_heading=sim.world.journey.plan.heading.duplicate();pending_name=spec.get("name",spec.id)
	return true

func commit_prepared() -> bool:
	if sim==null or pending_index<0 or attitude_hold or sim.world.journey.state=="committed" or not failed.is_empty():return false
	# Recreate the epoch-sensitive plan from the SAME present ship position.
	# If a caller advanced time during a stationary turn, no stale commit occurs.
	var next:=pending_index
	var spec:Dictionary=itinerary[next]
	var intent:Dictionary
	if spec.kind=="body":intent=_body_intent(spec)
	else:intent=_star_intent(spec)
	if intent.is_empty():failed="star leg catalogue identity missing";return false
	if not _send([intent],0.):return false
	var commit:={"k":"commit","plan_id":sim.world.journey.plan_id}
	var dtau:float=pacing.step(sim.world,true,0.,TICK_HZ)
	if not _send([commit],dtau):return false
	leg_index=next;dwell_left=DWELL_SECONDS
	pending_index=-1;pending_heading={};pending_name=""
	return true

## Called at 20 Hz by the existing host. At a stop 1 real second = 1 ship
## second, so the moving planet does not sweep away at the ordinary day/s rate.
func step() -> bool:
	if sim==null or not failed.is_empty():return false
	if paused or attitude_hold or pending_index>=0:return true
	if sim.world.journey.state=="committed":
		if interlude!=null:return _step_interlude()
		if pacing.interlude_due(sim.world):
			interlude=interlude_factory.call()
			interlude.begin(CruiseInterlude.facts_from(sim.world,leg_name()))
			return true
		if not _send([],pacing.step(sim.world,false,0.,TICK_HZ)):return false
		if sim.world.journey.state=="arrived":
			if leg_index==itinerary.size()-1:complete=true
			else:dwell_left=DWELL_SECONDS
		return true
	if not _send([],1./(TICK_HZ*JULIAN_YEAR_SECONDS)):return false
	if not complete:
		dwell_left=maxf(0.,dwell_left-1./TICK_HZ)
		if dwell_left==0.:return prepare_next() if deferred_commit else advance()
	return true

## One host frame of the active interlude: step the sim by exactly what it
## consumes (never past the braking boundary), then check the boundary at the end.
func _step_interlude() -> bool:
	var left:float=pacing.cruise_remaining(sim.world)
	var dt:float=clampf(interlude.advance(left,1./TICK_HZ),0.,left)
	if dt>0.:
		if not _send([],dt):return false
		interlude.observe(sim.world,leg_name())
	if interlude.done():
		last_boundary_error=pacing.cruise_remaining(sim.world)
		if last_boundary_error>1e-12*float(sim.world.journey.plan.ship_years):
			failed="cruise interlude ended off the braking boundary";return false
		interlude=null;interludes_done+=1
	return true

func leg_name() -> String:
	return "Earth standoff" if leg_index<0 or leg_index>=itinerary.size() else str(itinerary[leg_index].get("name",itinerary[leg_index].id))

func status_text() -> String:
	if sim==null:return "Solar departure unavailable"
	var label:String="Earth standoff" if leg_index<0 else itinerary[leg_index].get("name",itinerary[leg_index].id)
	var motion:String="PAUSED FOR ATTITUDE TURN · next "+pending_name if pending_index>=0 or attitude_hold else ("1 second/second at stops" if sim.world.journey.state!="committed" else ("CRUISE INTERLUDE · time passes aboard" if interlude!=null else "REAL TIME · 1 ship second per second · %.2f M g this leg" % (leg_thrust_g()/1.0e6)))
	return "GUIDED SOLAR DEPARTURE · %s · %s\nEarth +%.8f yr / ship +%.8f yr · %s\n%s" % [label,sim.world.ship.phase,sim.world.clock.year,sim.world.clock.tau,motion,sim.world.solar_departure.approximation]
