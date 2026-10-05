extends RefCounted
## Explicit guided demo controller. AILANG owns every position and intercept;
## this host sequences already-authorized commitments and presentation time.
## Caller starts one new solar_departure session, never resets an active voyage.
signal world_updated(world: Dictionary)
const TICK_HZ := 20.
const JULIAN_YEAR_SECONDS := 31557600.
const DWELL_SECONDS := 12.
var sim: SimBridge
var outbound: Dictionary
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

func attach(bridge: SimBridge, destination: Dictionary) -> bool:
	if bridge.world.get("journey",{}).get("state","")=="committed":return false
	var metadata: Dictionary=bridge.world.get("solar_departure",{})
	if metadata.is_empty() or destination.get("id","")!="CNS5:3627" or int(destination.get("index",-1))<0:return false
	sim=bridge;outbound=destination.duplicate(true);itinerary=metadata.legs.duplicate(true)
	return true

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
	if spec.kind=="body":intent=SimBridge.body_plan(spec.id,spec.cruise_phi,{"mode":"stop","standoff_km":spec.standoff_km})
	else:
		if spec.id!=outbound.id:failed="outbound catalogue identity mismatch";return false
		intent={"k":"plan","target":{"index":int(outbound.index),"id":outbound.id,"pos":{"x":outbound.x,"y":outbound.y,"z":outbound.z}},"cruise_phi":spec.cruise_phi}
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
	if spec.kind=="body":intent=SimBridge.body_plan(spec.id,spec.cruise_phi,{"mode":"stop","standoff_km":spec.standoff_km})
	else:intent={"k":"plan","target":{"index":int(outbound.index),"id":outbound.id,"pos":{"x":outbound.x,"y":outbound.y,"z":outbound.z}},"cruise_phi":spec.cruise_phi}
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

func status_text() -> String:
	if sim==null:return "Solar departure unavailable"
	var label:String="Earth standoff" if leg_index<0 else itinerary[leg_index].get("name",itinerary[leg_index].id)
	var motion:String="PAUSED FOR ATTITUDE TURN · next "+pending_name if pending_index>=0 or attitude_hold else ("1 second/second at stops" if sim.world.journey.state!="committed" else "variable compression; each phase 20 seconds")
	return "GUIDED SOLAR DEPARTURE · %s · %s\nEarth +%.8f yr / ship +%.8f yr · %s\n%s" % [label,sim.world.ship.phase,sim.world.clock.year,sim.world.clock.tau,motion,sim.world.solar_departure.approximation]
