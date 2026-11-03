class_name HomeBeacon
extends RefCounted
## R2-SOUND S2 (design_docs/planned/r2/sound.md §D6, amended 2026-10-27 and 2026-11-02): Earth's carrier at
## the helm, made exact by the standing order of 2026-10-30 (stapledons-design vision/design-decisions.md:
## no compromises on the physics; an exact True setting and labelled Processed settings).
##
## It plays while the ship is inside a beam Earth aimed at its plan (earth.in_beam) and away from home
## (earth.at_home false: at home the link is live and needs no beacon). Its time rate is the sim's Earth
## rate D (earth.rate, unrounded), through the comms station's own plan: EarthFeed.receiver_plan(D,
## receiver) reads data/ui/comms_feed.json sound.receiver, and the setting is the station's
## (EarthFeed.receiver: Receiver, the default, or True).
##   True:     home_beacon, a 400 Hz carrier keyed once per Earth second, at speed and pitch x D (Godot
##             resamples it: heard at 400 D Hz, its pips D times a ship second), uncorrected; outside
##             receiver.audible nothing reaches the ear and nothing plays.
##   Receiver: what a heterodyne receiver hands the crew: Earth's keying at D (unrounded, at every D: the
##             station's real-time range is for its recorded feed, not a live carrier) on the carrier's true
##             frequency, e(D t) x sin(2 pi 400 t),
##             generated sample by sample (home_beacon_rx, a generator row) from the envelope table
##             home_beacon_env (the same keying, rendered by sunholo/audio on a 12 kHz carrier locked to
##             the sample grid, so sample 4k+1 is the envelope). No FFT pitch shift: Godot's smears pips
##             shorter than its window and mis-tunes large corrections (measured: 314 Hz for 400 Hz
##             corrected 14x up; 8 to 16 of 21 pips survive at D = 14.1 whatever its FFT size).
## The envelope's position (Earth seconds into the 2 s loop) is kept here, so a change of setting picks
## up where the other left off and Earth's pips keep their time.
## Presentation only: nothing here reaches the sim, and no number is shown (the station shows D).

const CUE := "home_beacon"
const RX := "home_beacon_rx"
const OFF := "home_beacon_off"
const ENV := "home_beacon_env"
## The carrier's frequency in its own frame (data/audio/recipes.json home_beacon).
const CARRIER_HZ := 400.0
const LOOP_S := 2.0
const ENV_RATE := 12000.0 ## envelope samples per second (sample 4k+1 of the 48 kHz table)

var on := false
var cue := "" ## the row playing: CUE (True) or RX (Receiver)
var plan := {}
var env := PackedFloat32Array() ## the keying envelope, 0..1 of full scale, ENV_RATE samples a second
var _sound: SoundDirector = null
var _pos := 0.0 ## Earth seconds into the loop (Receiver)
var _phase := 0.0 ## the carrier's phase, radians (Receiver)
var _rate := 1.0 ## the envelope's rate (Receiver)
var pushed := 0 ## frames pushed to the Receiver's generator since it last started
var start_pos := 0.0 ## the envelope position (Earth s) when the Receiver last started
var handover_pos := -1.0 ## where the last change of setting took over (Earth s into the loop)


## What the helm's receiver does for this world: {on, d, rate, correct, silent, hearing} (receiver_plan's).
static func plan_for(world: Dictionary, receiver: bool) -> Dictionary:
	var e: Variant = world.get("earth")
	if not e is Dictionary or e.get("in_beam") != true or e.get("at_home") == true or not (e.get("rate") is float or e.get("rate") is int) or float(e.rate) <= 0.0:
		return {"on": false, "d": null, "rate": 1.0, "correct": 1.0, "silent": false, "hearing": ""}
	var d := float(e.rate)
	var p := EarthFeed.receiver_plan(d, receiver)
	p["d"] = d
	p["on"] = not p.silent
	return p


## The envelope table from home_beacon_env (16-bit PCM: in the export it is staged uncompressed).
static func envelope_of(s: AudioStreamWAV) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	if s == null or s.format != AudioStreamWAV.FORMAT_16_BITS:
		return out
	var b := s.data
	out.resize(b.size() / 8)
	for k in out.size():
		out[k] = absf(b.decode_s16((4 * k + 1) * 2) / 32768.0)
	return out


## The envelope at t Earth seconds (wrapped to the loop), linear between table samples.
func envelope_at(t: float) -> float:
	if env.is_empty():
		return 0.0
	var x := fposmod(t, LOOP_S) * ENV_RATE
	var k := int(x)
	return lerpf(env[k % env.size()], env[(k + 1) % env.size()], x - k)


## Fills the Receiver's generator: the envelope at the rate, on the 400 Hz carrier.
func _fill(pb: Object, frames: int) -> void: # an AudioStreamGeneratorPlayback (or anything with push_buffer)
	var buf := PackedVector2Array()
	buf.resize(frames)
	var dt := 1.0 / SoundDirector.GEN_RATE
	var w := TAU * CARRIER_HZ * dt
	var n := env.size()
	if n == 0:
		pushed += frames
		pb.push_buffer(buf)
		return
	var step := _rate * dt * ENV_RATE # table samples per output sample
	var x := fposmod(_pos, LOOP_S) * ENV_RATE
	var span := float(n)
	for i in frames:
		var k := int(x)
		var e := env[k] + (env[(k + 1) % n] - env[k]) * (x - k)
		var v := e * sin(_phase)
		buf[i] = Vector2(v, v)
		_phase += w
		if _phase >= TAU:
			_phase -= TAU
		x += step
		if x >= span:
			x -= span
	_pos = x / ENV_RATE
	pushed += frames
	pb.push_buffer(buf)


func _attach(sound: SoundDirector) -> void:
	if _sound == sound:
		return
	_sound = sound
	env = envelope_of(sound.stream(ENV))
	sound.generators[RX] = _fill


## Follows a world: starts the setting's row (its rate set before it starts), moves its rate, hands over
## between True and Receiver at the same loop position, or stops (home_beacon_off fades it out). Neither
## setting uses a bus pitch shift.
func follow(sound: SoundDirector, world: Dictionary, receiver: bool) -> void:
	_attach(sound)
	plan = plan_for(world, receiver)
	if not plan.on:
		if on:
			sound.on_game(OFF)
		on = false
		cue = ""
		return
	var want := RX if receiver else CUE
	# Earth's clock is exact in both settings at every D: the beacon keys at the sim's D unrounded. The
	# receiver plan's real-time range (min_rate..max_rate) limits the station's playback of a recorded feed;
	# a live carrier has no backlog to hold, so the Receiver corrects only the frequency.
	var rate := float(plan.d)
	sound.set_pitch(want, rate)
	_rate = rate
	if want != cue:
		var pos := -1.0
		if cue == CUE:
			pos = sound.loop_position(CUE)
		elif cue == RX: # the audible place in Earth's clock: the write cursor less what is still buffered
			pos = fposmod(_pos - sound.generator_lag_s(RX) * _rate, LOOP_S)
		if cue != "":
			sound.stop(cue, true)
		if pos >= 0.0:
			_pos = pos
		handover_pos = pos
		if want == RX:
			pushed = 0
			start_pos = _pos
		sound.on_game(want)
		if want == CUE and pos >= 0.0:
			sound.seek(CUE, pos)
		cue = want
	on = true
