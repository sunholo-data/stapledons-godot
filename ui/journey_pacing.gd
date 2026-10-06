extends RefCounted
## Presentation clock only: all motion is integrated by AILANG. Durations are
## plan fields; each nonzero phase gets 20 wall seconds at the 20 Hz host tick.
const PHASE_SECONDS:=20.
const MINUTES_PER_YEAR:=365.25*24.*60.
## Guided voyages (D-39/D-40/D-41) run in REAL TIME: one ship second per wall
## second through every boost, braking and short cruise, never compressed. A
## cruise longer than CUT_THRESHOLD_S is shown for CRUISE_HOLD_S of real time,
## then interlude_due() asks the host to hand the rest of the cruise to a
## cruise interlude (ui/cruise_interlude.gd), which consumes exactly
## cruise_remaining() of ship time. Ordinary map journeys keep their pacing.
var guided_approach:=false
var plan_id:=-1
var start_tau:=0.
var rate:=0.
const SECONDS_PER_YEAR:=31557600.0
const CUT_THRESHOLD_S:=600.
const CRUISE_HOLD_S:=10.
func step(world:Dictionary, committing:bool, host_dt:float, tick_hz:float)->float:
	var journey:Dictionary=world.journey
	if journey.state!="committed" and not committing:
		rate=host_dt*tick_hz
		return host_dt
	var plan:Dictionary=journey.plan
	if committing or plan_id!=int(journey.plan_id):
		plan_id=int(journey.plan_id)
		# The commit tick begins at this exact AILANG clock; every leg rebases.
		start_tau=float(world.clock.tau) if committing else float(plan.age_on_arrival)-float(world.params.start_age)-float(plan.ship_years)
	var burn:float=plan.boost_minutes/MINUTES_PER_YEAR
	var total:float=plan.ship_years
	var elapsed:float=maxf(0.,float(world.clock.tau)-start_tau)
	var phase:String=world.ship.phase
	var duration:=burn
	var boundary:=burn
	if not committing and phase=="cruising":
		duration=maxf(0.,total-2.*burn);boundary=total-burn
	elif not committing and phase=="braking":boundary=total
	var seconds:=PHASE_SECONDS
	var increment:=duration/(seconds*tick_hz)
	if guided_approach:
		# Real time never clamps at phase boundaries: the sim integrates a tick that
		# spans boost/cruise/brake exactly, and a plan-field boundary (rounded via
		# boost_minutes) can sit an ulp short of the sim's, which made clamped
		# steps stall in ~1e-18 yr nudges for up to a second of frames. The one
		# boundary that matters, cruise -> braking, is met exactly by the interlude.
		rate=1.
		return 1./(tick_hz*SECONDS_PER_YEAR)
	rate=increment*tick_hz
	var remaining:=boundary-elapsed
	# Float64 clock addition can land one ulp below a boundary. A tiny positive
	# nudge crosses that ulp, never skipping a visually significant sample.
	return maxf(minf(increment,remaining),maxf(absf(float(world.clock.tau))*2e-15,1e-18))

func _leg(world:Dictionary)->Dictionary:
	var plan:Dictionary=world.journey.plan
	var burn:float=plan.boost_minutes/MINUTES_PER_YEAR
	var total:float=plan.ship_years
	return {"burn":burn,"total":total,"cruise":maxf(0.,total-2.*burn),"elapsed":maxf(0.,float(world.clock.tau)-start_tau)}

## Ship seconds already spent cruising on this leg.
func cruise_elapsed_s(world:Dictionary)->float:
	var l:=_leg(world)
	return maxf(0.,l.elapsed-l.burn)*SECONDS_PER_YEAR

## True when a guided leg's cruise is long enough to cut and has been held for CRUISE_HOLD_S.
func interlude_due(world:Dictionary)->bool:
	if not guided_approach or world.get("journey",{}).get("state","")!="committed" or world.get("ship",{}).get("phase","")!="cruising":return false
	if int(world.journey.plan_id)!=plan_id:return false
	var l:=_leg(world)
	# Relative tolerance: plan fields round-trip through minutes, so a 600 s cruise
	# may read 600.0000001 s; it is still "not longer than" the threshold.
	# Less than one wall second of cruise left plays in real time (never a
	# zero-length interlude, which would otherwise repeat forever).
	var left:float=((l.total-l.burn)-l.elapsed)*SECONDS_PER_YEAR
	return l.cruise*SECONDS_PER_YEAR>CUT_THRESHOLD_S*(1.+1e-9) and cruise_elapsed_s(world)>=CRUISE_HOLD_S and left>=1.

## Ship years from now to the braking boundary: what an interlude must consume.
func cruise_remaining(world:Dictionary)->float:
	var l:=_leg(world)
	return maxf(0.,(l.total-l.burn)-l.elapsed)
