extends SceneTree
## R2-SOUND S2 listening review (make sound-voyage-review): the voyage's new cues and the home beacon,
## rendered through the real buses (headless mixer, captured after the Master limiter) and measured.
## Writes to --out:
##   cue_<id>.wav                 each new or rewired cue alone at its in-game level;
##   beacon_<setting>_D<d>.wav    the home beacon alone at the sim's Earth rates (outbound and homebound at
##                                0.99c, 0.5, 2, at rest), in True and in Receiver;
##   voyage_montage.wav           ~70 s: the real sim's scripted flight to Alpha Cen A (ui/transit_harness.gd,
##                                protocol 2.16) replayed at its own 20 Hz tick rate under the bridge's beds:
##                                plan, the 1.5 s commit hold, the seal, boost, the dust counter on the sim's
##                                drawn grains, cruise, brake and arrival, with the beacon following earth.rate,
##                                first in Receiver then in True; then turning for home at D = 14.107 (1 / the
##                                outbound D), Receiver then True;
##   measure.json                 per file: seconds, sample peak and RMS (dBFS), clipped samples, and for the
##                                beacon the carrier's frequency (zero crossings) and the pips' mean gap;
##   timeline.json                the montage's sections and their start times.
## The montage's sources play in 2D (no ship scene): the mix and the levels are the game's.
## Run: AILANG_BIN=$(command -v ailang) godot --display-driver headless --audio-driver CoreAudio --path . \
##        --script tools/sound_voyage_review.gd -- --out=<dir>   (macOS; the device output is kept at -80 dB)

var out := ""
var rate := 44100.0
var cap: AudioEffectCapture
var d: SoundDirector
var beacon := HomeBeacon.new()
var measure := {}
var timeline := []
var _buf := PackedVector2Array()
var _t0 := 0


func _initialize() -> void:
	_run.call_deferred()


func _args() -> Dictionary:
	var a := {}
	for s in OS.get_cmdline_user_args():
		var kv := s.trim_prefix("--").split("=", true, 1)
		a[kv[0]] = kv[1] if kv.size() > 1 else ""
	return a


## Keeps pulling the capture for `seconds` of mixer time (frames counted, not wall time).
func pump(seconds: float) -> void:
	await pump_to(now_s() + seconds)


## Pulls the capture up to an absolute buffer time, so a run of short steps does not drift.
func pump_to(t: float) -> void:
	var want := int(t * rate)
	while _buf.size() < want:
		await process_frame
		var n := cap.get_frames_available()
		if n > 0:
			_buf.append_array(cap.get_buffer(n))


func begin() -> void:
	await process_frame
	cap.clear_buffer()
	_buf = PackedVector2Array()


func now_s() -> float:
	return _buf.size() / rate


func finish(name: String, extra := {}) -> Dictionary:
	var pcm := PackedByteArray()
	pcm.resize(_buf.size() * 4)
	var peak := 0.0
	var sum := 0.0
	var clipped := 0
	for i in _buf.size():
		var f := _buf[i]
		for c in 2:
			var x: float = f.x if c == 0 else f.y
			peak = maxf(peak, absf(x))
			sum += x * x
			if absf(x) >= 0.999:
				clipped += 1
			pcm.encode_s16(i * 4 + c * 2, clampi(roundi(x * 32767.0), -32768, 32767))
	var path := out.path_join(name + ".wav")
	var fa := FileAccess.open(path, FileAccess.WRITE)
	fa.store_buffer(SoundData.wav_bytes(pcm, int(rate), 2))
	fa.close()
	var row := {"seconds": snappedf(now_s(), 0.001), "peak_dbfs": snappedf(linear_to_db(maxf(peak, 1e-9)), 0.01),
		"rms_dbfs": snappedf(linear_to_db(maxf(sqrt(sum / maxf(2.0 * _buf.size(), 1.0)), 1e-9)), 0.01), "clipped": clipped}
	row.merge(extra)
	measure[name] = row
	print("sound-voyage-review: %s %s" % [name, JSON.stringify(row)])
	return row


## Carrier frequency from zero crossings over [a, b) seconds of the buffer, left channel.
func freq(a := 0.0, b := INF) -> float:
	var i0 := int(a * rate)
	var i1 := mini(_buf.size(), int(b * rate) if b != INF else _buf.size())
	var c := 0
	for i in range(i0 + 1, i1):
		if (_buf[i - 1].x < 0.0) != (_buf[i].x < 0.0):
			c += 1
	return c * 0.5 * rate / maxf(i1 - i0, 1.0)


## Pip onsets (s): RMS windows of 5 ms (or two periods of the heard carrier, if longer) rising through half
## the loudest window, at least min_gap apart.
func onsets(heard_hz: float, min_gap: float) -> Array:
	var w := int(rate * maxf(0.005, 2.0 / maxf(heard_hz, 1.0)))
	var env := []
	var top := 0.0
	for i in range(0, _buf.size() - w, w):
		var s := 0.0
		for j in w:
			s += _buf[i + j].x * _buf[i + j].x
		env.append(sqrt(s / w))
		top = maxf(top, env.back())
	var o := []
	for i in range(1, env.size()):
		var t := float(i * w) / rate
		if env[i] >= 0.5 * top and env[i - 1] < 0.5 * top and (o.is_empty() or t - o.back() > min_gap):
			o.append(t)
	return o


func mean_gap(o: Array) -> Variant:
	if o.size() < 2:
		return null
	return snappedf((float(o.back()) - float(o[0])) / (o.size() - 1), 0.0001)


## The real sim's scripted flight, recorded tick by tick: [{tick, events, world}] (deep copies).
func record() -> Array:
	var sim := SimBridge.new()
	sim.want_minor = SimBridge.EARTH_MINOR
	if not sim.start() or not sim.new_game(0, "sol", false, {}):
		print("sound-voyage-review: FAIL the sim does not start (%s)" % sim.last_error)
		return []
	var ticks := [{"tick": int(sim.world.get("tick", 0)), "events": [], "world": sim.world.duplicate(true)}]
	sim.stepped.connect(func(ev: Array) -> void: ticks.append({"tick": int(sim.world.get("tick", 0)), "events": ev.duplicate(true), "world": sim.world.duplicate(true)}))
	var h := TransitHarness.new()
	root.add_child(h)
	h.attach(sim)
	h.run_session()
	sim.stop()
	h.queue_free()
	return ticks


func step(t: Dictionary, receiver: bool) -> void:
	d.on_sim_step(t.tick, t.events)
	d.on_sim_world(t.tick, t.world)
	d.on_dust(t.tick, t.world)
	SoundMix.set_shift(HomeBeacon.BUS, beacon.follow(d, t.world, receiver))


func mark(label: String) -> void:
	timeline.append({"t": snappedf(now_s(), 0.01), "what": label})


func voyage(ticks: Array, receiver: bool, label: String) -> void:
	mark("%s: the bridge; the navigation console plots Alpha Cen A" % label)
	var next := now_s()
	for t: Dictionary in ticks:
		var ev: Array = t.events
		if ev.any(func(e: Dictionary) -> bool: return e.get("k", "") == "committed"):
			mark("%s: the commit held for 1.5 s" % label)
			d.on_game("commit_hold")
			next += GalaxyMap.HOLD_S
			await pump_to(next)
			mark("%s: the sim accepts it (commit_seal); boost" % label)
		if ev.any(func(e: Dictionary) -> bool: return e.get("k", "") == "phase" and e.get("to", "") == "cruising"):
			mark("%s: cruise at 0.99c, Earth's rate D = 0.0709: the beacon %s" % [label, "corrected to 400 Hz, a pip every 14 s" if receiver else "uncorrected at 28 Hz, a pip every 14 s"])
		if ev.any(func(e: Dictionary) -> bool: return e.get("k", "") == "phase" and e.get("to", "") == "braking"):
			mark("%s: brake; D rises to 1" % label)
		if ev.any(func(e: Dictionary) -> bool: return e.get("k", "") == "arrived"):
			mark("%s: arrival at Alpha Cen A, at rest (D = 1: the beacon at its true pitch)" % label)
		step(t, receiver)
		next += TransitHarness.TICK_DT # the harness's own tick rate, 20 Hz
		await pump_to(next)
	await pump(4.0)
	step({"tick": 0, "events": [], "world": {}}, receiver) # the beacon off between parts
	await pump(1.5)


func _run() -> void:
	out = str(_args().get("out", ""))
	if out.is_empty():
		print("sound-voyage-review: FAIL need --out")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(out)
	SoundMix.ensure_layout()
	rate = AudioServer.get_mix_rate()
	cap = AudioEffectCapture.new()
	cap.buffer_length = 2.0
	AudioServer.add_bus_effect(0, cap, AudioServer.get_bus_effect_count(0)) # after the limiter: what is heard
	# Rendered on the real CoreAudio driver (512-frame mix blocks, as in the game): the headless Dummy driver
	# mixes in 4,096-frame blocks, and every sound asked for within one block starts at its start, so dust
	# ticks 25 ms apart stack (+6 dB, measured). The device is kept silent after the capture.
	var quiet := AudioEffectAmplify.new()
	quiet.volume_db = -80.0
	AudioServer.add_bus_effect(0, quiet, AudioServer.get_bus_effect_count(0))
	print("sound-voyage-review: driver mix rate %.0f Hz" % AudioServer.get_mix_rate())
	d = SoundDirector.new()
	root.add_child(d)
	var errs := d.setup()
	if not errs.is_empty():
		print("sound-voyage-review: FAIL tables: %s" % "; ".join(errs))
		quit(1)
		return
	var rooms: Variant = SoundData.read_json(ShipSound.ROOMS_PATH)
	SoundMix.set_room(rooms.levels["0"])

	# Each new or rewired cue alone.
	for id: String in ["plan_select", "commit_hold", "commit_seal", "dust_tick"]:
		await begin()
		d.fire(id, "review", 0)
		await pump(float(d.assets[d.cues[id].streams[0]].frames) / 48000.0 + 1.5)
		finish("cue_" + id)

	# The beacon alone at the sim's rates, in both settings.
	for dd: float in [0.070888, 0.5, 1.0, 2.0, 14.107]:
		for receiver: bool in [true, false]:
			await begin()
			SoundMix.set_shift(HomeBeacon.BUS, beacon.follow(d, {"earth": {"rate": dd, "in_beam": true, "at_home": false}}, receiver))
			var bank := beacon.cue
			await pump(0.4) # the shifter fills
			await begin()
			await pump(30.0 if dd < 0.2 else 6.0) # outbound the pips are 14.1 s apart: two in 30 s
			var hz := freq()
			var want := HomeBeacon.CARRIER_HZ * (1.0 if receiver else dd)
			var o := onsets(want, 0.5 / dd)
			finish("beacon_%s_D%s" % ["receiver" if receiver else "true", str(dd)], {"d": dd, "setting": "Receiver" if receiver else "True", "bank": bank,
				"carrier_hz": snappedf(hz, 0.1), "want_hz": snappedf(want, 0.1), "carrier_error_pct": snappedf(100.0 * (hz / want - 1.0), 0.01),
				"pips": o.size(), "pip_gap_s": mean_gap(o), "want_gap_s": snappedf(1.0 / dd, 0.0001)})
			SoundMix.set_shift(HomeBeacon.BUS, beacon.follow(d, {}, receiver))
			d.stop(bank, true)
	# True outside hearing: nothing plays (after a second for the last tails to die away).
	await pump(1.0)
	await begin()
	SoundMix.set_shift(HomeBeacon.BUS, beacon.follow(d, {"earth": {"rate": 60.0, "in_beam": true, "at_home": false}}, false))
	await pump(2.0)
	finish("beacon_true_D60_silent", {"d": 60.0, "setting": "True", "on": beacon.on, "hearing": beacon.plan.get("hearing", "")})

	# The montage.
	var ticks := record()
	if ticks.is_empty():
		quit(1)
		return
	await begin()
	d.on_game("level_bridge")
	mark("the bridge's beds (the spire's hum, the room)")
	await pump(2.0)
	await voyage(ticks, true, "Receiver")
	await voyage(ticks, false, "True")
	var home := {"earth": {"rate": 14.107, "in_beam": true, "at_home": false}}
	mark("turning for home at 0.99c, D = 14.107, Receiver: 400 Hz, 14 pips a second")
	SoundMix.set_shift(HomeBeacon.BUS, beacon.follow(d, home, true))
	await pump(6.0)
	mark("the same in True: the carrier at 5.6 kHz")
	SoundMix.set_shift(HomeBeacon.BUS, beacon.follow(d, home, false))
	await pump(6.0)
	SoundMix.set_shift(HomeBeacon.BUS, beacon.follow(d, {}, false))
	d.on_game("level_none")
	await pump(2.0)
	finish("voyage_montage", {"cue_lines": d.cue_log.size()})
	var f := FileAccess.open(out.path_join("measure.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(measure, " "))
	f.close()
	f = FileAccess.open(out.path_join("timeline.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(timeline, " "))
	f.close()
	f = FileAccess.open(out.path_join("cue_log.txt"), FileAccess.WRITE)
	f.store_string(d.log_text())
	f.close()
	var bad := measure.keys().filter(func(k: String) -> bool: return int(measure[k].clipped) > 0)
	print("sound-voyage-review: %d files, %d clipped%s" % [measure.size(), bad.size(), (" (" + ", ".join(bad) + ")") if not bad.is_empty() else ""])
	quit(0)
