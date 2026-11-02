class_name HomeBeacon
extends RefCounted
## R2-SOUND S2 (design_docs/planned/r2/sound.md §D6, amended 2026-10-27 and 2026-11-02): Earth's carrier at
## the helm, made exact by the standing order of 2026-10-30 (stapledons-design vision/design-decisions.md:
## no compromises on the physics; an exact True setting and labelled Processed settings).
##
## It plays while the ship is inside a beam Earth aimed at its plan (earth.in_beam) and away from home
## (earth.at_home false: at home the link is live and needs no beacon). Its time rate is the sim's Earth
## rate D (earth.rate, unrounded), through the comms station's own machinery: EarthFeed.receiver_plan(D,
## receiver) reads data/ui/comms_feed.json sound.receiver, and the setting is the station's
## (EarthFeed.receiver: Receiver, the default, or True).
##   True:     the 400 Hz carrier (home_beacon) at speed and pitch x D, uncorrected: heard at 400 D Hz, its
##             pips D times a ship second; outside receiver.audible nothing reaches the ear and nothing plays.
##   Receiver: the stream at the plan's rate (D within the receiver's real-time range), its frequency
##             corrected back to 400 Hz on the Beacon bus. Godot's FFT pitch shift is exact only within
##             about a factor of 2 (measured: a 14x upward shift of a 28 Hz tone gives 314 Hz, not 400), so
##             the correction is split: a bank row whose carrier is 400 s Hz with the same keying (s in
##             BANKS, nearest 1/rate) is played at the rate, and the bus corrects the rest, 1/(s rate),
##             which stays within [1/2, 2]. A bank change takes over at the same loop position, so Earth's
##             pips keep their time.
## Presentation only: nothing here reaches the sim, and no number is shown (the station shows D).

const CUE := "home_beacon"
const OFF := "home_beacon_off"
const BUS := "Beacon"
## The carrier's frequency in its own frame (data/audio/recipes.json home_beacon).
const CARRIER_HZ := 400.0
## Receiver banks: carrier factor s -> cue (data/audio/recipes.json: the same keying on a 400 s Hz carrier).
const BANKS := {0.0625: "home_beacon_c25", 0.25: "home_beacon_c100", 1.0: "home_beacon", 4.0: "home_beacon_c1600", 16.0: "home_beacon_c6400"}
## A bank changes only when another is nearer by this factor (no chatter while D hovers at an edge).
const HYSTERESIS := 1.1

var on := false
var cue := "" ## the bank row playing
var plan := {}


## What the helm's receiver does for this world: {on, d, rate, correct, silent, hearing} (receiver_plan's
## fields, correct being the whole correction 1/rate in Receiver).
static func plan_for(world: Dictionary, receiver: bool) -> Dictionary:
	var e: Variant = world.get("earth")
	if not e is Dictionary or e.get("in_beam") != true or e.get("at_home") == true or not (e.get("rate") is float or e.get("rate") is int) or float(e.rate) <= 0.0:
		return {"on": false, "d": null, "rate": 1.0, "correct": 1.0, "silent": false, "hearing": ""}
	var d := float(e.rate)
	var p := EarthFeed.receiver_plan(d, receiver)
	p["d"] = d
	p["on"] = not p.silent
	return p


## The bank for a playback rate in a setting: True always plays the 400 Hz carrier; Receiver the s nearest
## 1/rate (ties to the lower s), keeping `current` unless another is nearer by HYSTERESIS.
static func bank_for(rate: float, receiver: bool, current := -1.0) -> float:
	if not receiver:
		return 1.0
	var best := -1.0
	for s: float in BANKS:
		if best < 0.0 or absf(log(s * rate)) < absf(log(best * rate)) - 1e-12:
			best = s
	if current > 0.0 and BANKS.has(current) and absf(log(current * rate)) <= absf(log(best * rate)) + log(HYSTERESIS):
		return current
	return best


static func bank_of(id: String) -> float:
	for s: float in BANKS:
		if BANKS[s] == id:
			return s
	return -1.0


## Follows a world: starts the carrier (its rate set before it starts), moves its rate, hands over to
## another bank at the same position, or stops (home_beacon_off fades it out). Returns the Beacon bus's
## correction (1 while off, and in True).
func follow(sound: SoundDirector, world: Dictionary, receiver: bool) -> float:
	plan = plan_for(world, receiver)
	if not plan.on:
		if on:
			sound.on_game(OFF)
		on = false
		cue = ""
		return 1.0
	var rate := float(plan.rate)
	var s := bank_for(rate, receiver, bank_of(cue))
	var want: String = BANKS[s]
	sound.set_pitch(want, rate)
	if want != cue:
		var pos := sound.loop_position(cue) if cue != "" else -1.0
		if cue != "":
			sound.stop(cue, true)
		sound.on_game(want)
		if pos >= 0.0:
			sound.seek(want, pos)
		cue = want
	on = true
	return float(plan.correct) / s
