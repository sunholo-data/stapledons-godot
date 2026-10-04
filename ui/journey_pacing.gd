extends RefCounted
## Presentation clock only: all motion is integrated by AILANG. Durations are
## plan fields; each nonzero phase gets 20 wall seconds at the 20 Hz host tick.
const PHASE_SECONDS:=20.
const MINUTES_PER_YEAR:=365.25*24.*60.
var plan_id:=-1
var start_tau:=0.
var rate:=0.
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
	rate=duration/PHASE_SECONDS
	var remaining:=boundary-elapsed
	# Float64 clock addition can land one ulp below a boundary. A tiny positive
	# nudge crosses that ulp, never skipping a visually significant sample.
	return maxf(minf(rate/tick_hz,remaining),maxf(absf(float(world.clock.tau))*2e-15,1e-18))
