class_name CruiseInterlude
extends RefCounted
## The seam between a long cruise and in-ship gameplay (D-41, Mark 2026-10-06:
## in the real game the cut "will be moving to the in-ship gameplay, e.g.
## talking and relationships within as they deal with the long journeys").
##
## The host (demos/solar_departure.gd) owns the simulation. Each frame it calls
## advance(max_years, delta) and steps the sim by EXACTLY the ship years
## returned (never more than max_years, the cruise left before braking), then
## calls observe(world) with the new state. When done() is true the host checks
## the clock sits on the braking boundary and resumes real time. So whatever an
## interlude does (one card, or weeks of conversations), clocks, consequences
## and news ageing stay the simulation's.
##
## facts come only from simulation fields (plan, clock, consequence): the
## interlude never computes physics.

var facts: Dictionary = {}   # at begin: the cruise as the sim reports it
var latest: Dictionary = {}  # the same fields after the most recent step

func begin(start: Dictionary) -> void:
	facts = start.duplicate(true)
	latest = start.duplicate(true)

## Ship years to consume this frame, 0 <= result <= max_years.
func advance(_max_years: float, _delta: float) -> float:
	return 0.0

func observe(world: Dictionary, leg_name: String = "") -> void:
	latest = facts_from(world, leg_name if not leg_name.is_empty() else str(facts.get("leg", "")))

func done() -> bool:
	return true

## The interlude's inputs, read from one world snapshot (protocol fields only).
static func facts_from(world: Dictionary, leg_name: String) -> Dictionary:
	var plan: Dictionary = world.get("journey", {}).get("plan", {})
	var cq: Dictionary = world.get("consequence", {})
	var clock: Dictionary = world.get("clock", {})
	return {
		"leg": leg_name,
		"target_id": str(plan.get("target", {}).get("id", "")),
		"cruise_beta": float(plan.get("cruise_beta", 0.0)),
		"cruise_one_minus_beta": float(plan.get("cruise_one_minus_beta", 1.0)),
		"cruise_gamma": float(plan.get("cruise_gamma", 1.0)),
		"distance_ly": float(plan.get("distance", 0.0)),
		"distance_remaining_ly": float(cq.get("distance_remaining", 0.0)),
		"earth_year": float(clock.get("year", 0.0)),
		"ship_tau": float(clock.get("tau", 0.0)),
		"age": float(clock.get("age", 0.0)),
		"news_age_years": float(cq.get("news_age_years", 0.0)),
	}
