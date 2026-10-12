class_name Transit
extends RefCounted
## The M4.3a transit clock: which `dtau` and which intents Godot sends each tick.
##
## Scheduling only. Every physics value (phase, the ship years left in a phase) is read from the
## sim's state; nothing here computes a velocity, a time dilation or a distance (CLAUDE.md gate 4).
##   * docked, planning, arrived: the fixed host rate, no pause (D-12).
##   * boost and brake: each phase plays over BURN_REAL_S of real time, whatever its length in
##     ship time, by sending `dtau` = (the phase's length, latched when it starts) * real_dt / 3 s.
##   * cruise: the warp level in ship-years per real second times real_dt.
##   * no tick overshoots the end of the phase (consequence.phase_remaining_yr), so the brake is
##     always seen as a phase of its own, however fast the warp.
## The warp level is a recorded intent {"k":"warp","level"}: the sim accepts it only while committed
## (otherwise "not_committed"), and the input log, with the dtau of every tick, replays the run.

const WARP_LEVELS := [0.002, 0.01, 0.05] # ship-years per real second
const WARP_DEFAULT := 0.01
const BURN_REAL_S := 3.0
## D-14: journeys stop 1,000 AU short of the target star. The sim's own default is 0, so every
## M4 client sends this in `new_game` params.
const STANDOFF_AU := 1000.0
const END_SLACK := 1e-10 # relative overshoot of the closing tick
const END_SNAP := 1e-6 # a tick within this of closing the phase closes it
const WARP_NOT_COMMITTED := "not_committed"

var warp := WARP_DEFAULT
var _announced := false # the default level has been sent for this commitment
var _burn_phase := ""
var _burn_years := 0.0
var _pending := -1.0 # a requested warp level not yet accepted by the sim
var _pending_at := -1 # its index in the last tick's intents


static func new_game_params() -> Dictionary:
	return {"standoff_au": STANDOFF_AU}


static func is_committed(world: Dictionary) -> bool:
	return GalaxyMap.field_value(world, "journey.state") == "committed"


## Ask for a warp level. False (nothing queued) unless the level is one of the three and a
## journey is committed; the sim refuses it too if this gate is bypassed.
func request_warp(level: float, world: Dictionary) -> bool:
	if not WARP_LEVELS.has(level) or not is_committed(world):
		return false
	_pending = level
	return true


## The next tick: {"dtau", "intents"} for `world` (the bridge's mirrored state) over `real_dt`.
## `queued` are the caller's own intents for this tick: a commit is sent with dtau 0, so the
## sim flies nothing (a host-rate tick would swallow the whole boost) until the next tick.
func step(world: Dictionary, real_dt: float, queued: Array = []) -> Dictionary:
	var intents: Array = []
	var cq: Variant = world.get("consequence")
	if not is_committed(world) or typeof(cq) != TYPE_DICTIONARY:
		_announced = false
		_burn_phase = ""
		_pending_at = -1
		var committing := queued.any(func(i): return i["k"] == "commit")
		return {"dtau": 0.0 if committing else GalaxyMap.HOST_RATE * real_dt, "intents": intents}
	if not _announced: # the level in force goes into the log as soon as the journey is committed
		_announced = true
		_pending = warp
	_pending_at = -1
	if _pending > 0.0:
		_pending_at = intents.size()
		intents.append({"k": "warp", "level": _pending})
	var phase: String = world["ship"]["phase"]
	if phase == "at_rest": # committed, nothing flown yet: the boost is about to start
		phase = "boosting"
	var left: float = cq["phase_remaining_yr"]
	var dtau: float
	if phase == "cruising":
		_burn_phase = ""
		dtau = warp * real_dt
	else:
		if phase != _burn_phase: # a burn phase starts: latch its length
			_burn_phase = phase
			_burn_years = left
		dtau = _burn_years * real_dt / BURN_REAL_S
	return {"dtau": _to_phase_end(dtau, left), "intents": intents}


## The tick that reaches the end of the phase carries a hair more than what is left (END_SLACK, END_SNAP),
## so the sim crosses into the next phase on that tick: floating-point sums can fall one ulp short
## of the boundary, which would cost a tick of nothing but the crossing.
func _to_phase_end(dtau: float, left: float) -> float:
	return left * (1.0 + END_SLACK) if dtau * (1.0 + END_SNAP) >= left else dtau


## After the sim answered a tick whose intents began at `offset` in the list it was sent: an
## accepted warp request becomes the level in force; a refused one is dropped.
func settle(refused: Array, offset: int) -> void:
	if _pending_at < 0:
		return
	var turned_down := false
	for r in refused:
		if int(r["i"]) == offset + _pending_at:
			turned_down = true
	if not turned_down:
		warp = _pending
	_pending = -1.0
	_pending_at = -1
