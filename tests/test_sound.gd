extends SceneTree
## R2-SOUND (design_docs/planned/r2/sound.md) AC1-AC5, AC8 (rows), AC10 (later), the bus layout:
## the cue table and manifest validators with their negative controls, the sim/UI/walk clocks,
## deterministic variants, the visual-counterpart and no-judgement rules, the D-101 generated-sound
## gate, and the bus layout (§D2).
## Run: godot --headless --path . --script tests/test_sound.gd [-- --log-out=<file>]
## --log-out writes the scripted session's cue log, for the two-process determinism check (AC2).
var failed := 0
var passed := 0
var scratch := ProjectSettings.globalize_path("res://.godot/tmp/sound_test")


func check(ok: bool, message: String) -> void:
	if ok: passed += 1
	else: failed += 1
	print("%s %s" % ["ok" if ok else "FAIL", message])


func _initialize() -> void:
	_run.call_deferred()


func _args() -> Dictionary:
	var out := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		out[kv[0]] = kv[1] if kv.size() > 1 else ""
	return out


func write(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


## A tiny tone WAV under <root>/assets/audio/<kind>/<id>.wav and its manifest row.
func tone(root: String, id: String, kind := "synth", frames := 4800) -> Dictionary:
	var pcm := PackedByteArray()
	pcm.resize(frames * 2)
	for i in frames:
		pcm.encode_s16(i * 2, int(8000.0 * sin(TAU * 440.0 * i / 48000.0)))
	var rel := "assets/audio/%s/%s.wav" % [kind, id]
	var p := root.path_join(rel)
	DirAccess.make_dir_recursive_absolute(p.get_base_dir())
	var f := FileAccess.open(p, FileAccess.WRITE)
	f.store_buffer(SoundData.wav_bytes(pcm, 48000, 1))
	f.close()
	var prov := {"generator": "sunholo/audio@0.5.0", "generator_sha256": "0".repeat(64), "recipe": id}
	var lic := "synth-own"
	if kind == "library":
		prov = {"url": "https://kenney.nl/assets/x", "author": "Kenney", "retrieved": "2026-10-20", "download_sha256": "1".repeat(64)}
		lic = "CC0-1.0"
	elif kind == "generated":
		prov = {"tool": "x", "model": "y", "prompt_sha256": "2".repeat(64), "date": "2026-10-20", "terms_url": "https://example.org"}
		lic = "generated-licensed"
	return {"id": id, "path": rel, "bytes": FileAccess.get_file_as_bytes(p).size(), "sha256": FileAccess.get_sha256(p),
		"rate": 48000, "channels": 1, "frames": frames, "loop": null, "source_kind": kind, "licence": lic, "author": "test", "provenance": prov}


func manifest(root: String, rows: Array, allow_generated := false) -> String:
	write(root.path_join("data/audio/assets_test.json"), JSON.stringify({"schema": SoundData.PART_SCHEMA, "assets": rows}))
	var top := root.path_join("data/audio/assets.json")
	write(top, JSON.stringify({"schema": SoundData.ASSETS_SCHEMA, "allow_generated": allow_generated, "budget_bytes": 12000000, "parts": ["assets_test.json"]}))
	return top


const VIS_ARRIVED := "ui/arrival_card.gd::class_name ArrivalCard"
const VIS_PHASE := "ui/journey_hud.gd::ship.phase"


func base_cues() -> Array:
	return [
		{"id": "commit_seal", "trigger": {"kind": "sim_event", "k": "committed"}, "streams": ["a"], "bus": "Effects", "volume_db": -6.0, "visual": "ui/galaxy_map.gd::committed", "about": "the sealing chord"},
		{"id": "drive_boost", "trigger": {"kind": "sim_event", "k": "phase", "match": {"to": "boosting"}}, "streams": ["a"], "bus": "Effects", "volume_db": -8.0, "visual": VIS_PHASE, "about": "the emitter rises"},
		{"id": "drive_silent", "trigger": {"kind": "sim_event", "k": "phase", "match": {"to": "cruising"}}, "streams": ["a"], "bus": "Effects", "volume_db": -8.0, "visual": VIS_PHASE, "about": "the drive falls silent"},
		{"id": "arrived", "trigger": {"kind": "sim_event", "k": "arrived"}, "streams": ["a", "b"], "bus": "Instruments", "volume_db": -10.0, "pitch_cents_spread": 20, "visual": VIS_ARRIVED, "about": "a neutral chime"},
		{"id": "medium_change", "trigger": {"kind": "sim_state", "path": "ship.ism.medium"}, "streams": ["a"], "bus": "Instruments", "volume_db": -14.0, "visual": "ui/ism_hud.gd::medium", "about": "a cloud edge"},
		{"id": "ui_click", "trigger": {"kind": "ui_signal", "name": "click"}, "streams": ["a", "b"], "bus": "UI", "volume_db": -12.0, "cooldown": 2, "visual": "ambient: interface feedback only", "about": "a click"},
		{"id": "footstep", "trigger": {"kind": "game", "name": "step"}, "streams": ["a", "b"], "bus": "Effects", "volume_db": -14.0, "pitch_cents_spread": 30, "visual": "ambient: the walk is on screen", "about": "a step on plating"},
		{"id": "spire_hum", "trigger": {"kind": "game", "name": "level_bridge", "stop_on": "level_none"}, "streams": ["a"], "bus": "Ambience", "loop": true, "volume_db": -20.0, "visual": "ambient: the spire is always there", "about": "the hum"},
	]


func cues_file(root: String, cues: Array) -> String:
	var p := root.path_join("data/audio/cues.json")
	write(p, JSON.stringify({"schema": SoundData.CUES_SCHEMA, "cues": cues}))
	return p


func director(root: String, cues: Array, rows: Array) -> SoundDirector:
	var d := SoundDirector.new()
	d.audible = false
	d.setup(cues_file(root, cues), manifest(root, rows), "res://")
	return d


func fresh(name: String) -> String:
	var d := scratch.path_join(name)
	OS.execute("/bin/rm", PackedStringArray(["-rf", d]))
	DirAccess.make_dir_recursive_absolute(d)
	return d


## The scripted session for AC2/AC3/AC4 (S0a): sim events, a cloud edge, clicks and a walk.
func session(d: SoundDirector) -> void:
	d.on_game("level_bridge")
	d.on_sim_step(10, [{"k": "echo"}, {"k": "committed"}, {"k": "phase", "from": "at_rest", "to": "boosting"}])
	d.on_sim_world(11, {"ship": {"ism": {"medium": "LIC"}}})
	d.on_sim_world(12, {"ship": {"ism": {"medium": "LIC"}}})
	d.on_sim_world(13, {"ship": {"ism": {"medium": "LB"}}})
	d.on_sim_step(40, [{"k": "phase", "from": "boosting", "to": "cruising"}])
	for i in 3:
		d.on_ui("click")
	d.walked(3.5)
	d.walked(3.5)
	d.on_sim_step(90, [{"k": "phase", "from": "braking", "to": "at_rest"}, {"k": "arrived"}])
	d.on_sim_step(91, [{"k": "arrived"}])
	d.on_game("level_none")


## R3-EARTH-LINK EL3b.7: the shipped home beds through an audible director: a bed starts at the pitch
## set before it, set_pitch moves the playing loop and is logged once per change, every bed fades out
## on home_none rather than cutting, and a bed fired again while fading starts over at its level.
## R3 audio realism AR8b, measured (evaluation round 1, finding 4): a 1 kHz tone through the real
## Receiver bus, captured from the mixer (headless) and its frequency read by zero crossings. The stream
## plays at speed D (pitch_scale); Receiver corrects by 1/D on the bus and hands back 1 kHz; True leaves
## it at D x 1 kHz. At D = 0.5, 2 and 16 (the receiver's 16x edge), within 3 %.
func test_receiver_measured() -> void:
	SoundMix.ensure_layout()
	var n := 48000
	var tone := AudioStreamWAV.new()
	tone.format = AudioStreamWAV.FORMAT_16_BITS
	tone.mix_rate = 48000
	var b := PackedByteArray()
	b.resize(n * 2)
	for i in n:
		b.encode_s16(i * 2, int(12000.0 * sin(TAU * 1000.0 * i / 48000.0)))
	tone.data = b
	tone.loop_mode = AudioStreamWAV.LOOP_FORWARD
	tone.loop_end = n
	var cap := AudioEffectCapture.new()
	cap.buffer_length = 1.0
	AudioServer.add_bus_effect(0, cap, 0)
	var p := AudioStreamPlayer.new()
	p.stream = tone
	p.bus = &"Receiver"
	get_root().add_child(p)
	var rate := AudioServer.get_mix_rate()
	var ok := true
	var seen := []
	for d: float in [0.5, 2.0, 16.0]:
		for receiver: bool in [true, false]:
			p.pitch_scale = d
			SoundMix.set_receiver(1.0 / d if receiver else 1.0)
			p.play()
			await create_timer(0.35).timeout # the shifter's FFT fills
			cap.clear_buffer()
			await create_timer(0.4).timeout
			var buf := cap.get_buffer(cap.get_frames_available())
			p.stop()
			var crossings := 0
			for i in range(1, buf.size()):
				if (buf[i - 1].x < 0.0) != (buf[i].x < 0.0):
					crossings += 1
			var hz := crossings * 0.5 * rate / maxf(buf.size(), 1.0)
			var want := 1000.0 if receiver else 1000.0 * d
			seen.append("D %s %s %.0f Hz (want %.0f)" % [d, "receiver" if receiver else "true", hz, want])
			ok = ok and buf.size() > 0 and absf(hz / want - 1.0) <= 0.03
	SoundMix.set_receiver(1.0)
	p.queue_free()
	AudioServer.remove_bus_effect(0, 0)
	check(ok, "AR8b measured through the mixer: Receiver hands back 1 kHz at D = 0.5, 2 and 16; True plays D x 1 kHz (%s)" % ", ".join(seen))


## R2-SOUND S2 (§D1, §D6): the dust counter on a real director. Grains at their own ship time
## (clock.tau years + t_s), in t_s order whatever order the sim lists them; a grain within 25 ms of the
## last counted one is in the dead time; the dead time carries across ticks in ship time; at most 8 counts
## sound per tick and the rest are logged as one count line.
func test_dust() -> void:
	var d := SoundDirector.new()
	d.audible = false
	d.setup()
	var w := {"clock": {"tau": 1.0}, "ship": {"ism": {"impacts": [{"t_s": 0.03}, {"t_s": 0.0}, {"t_s": 0.01}, {"t_s": 0.054}, {"t_s": 0.056}]}}}
	var n := d.on_dust(7, w)
	var log := d.log_text()
	check(n == 3 and log.count(" dust_tick v") == 3 and log.contains("t7.d0 dust_tick") and log.contains("t7.d2 dust_tick") and not log.contains("t7.d3"), "S2 AC4: grains at 0, 10, 30, 54, 56 ms count at 0, 30 and 56 ms (10 ms and 54 ms fall in the 25 ms dead time; listed out of order, counted in time order):\n" + log)
	var tau_s := 1.0 + 0.06 / SoundDirector.YEAR_S # the next tick starts 60 ms of ship time later: 4 ms after the last count
	n = d.on_dust(8, {"clock": {"tau": tau_s}, "ship": {"ism": {"impacts": [{"t_s": 0.0}, {"t_s": 0.03}]}}})
	check(n == 1 and d.log_text().contains("t8.d0 dust_tick") and not d.log_text().contains("t8.d1"), "S2: the dead time runs on in ship time across ticks (a grain 4 ms after the last count is dead; the next, 34 ms after, counts)")
	var many: Array = []
	for i in 12:
		many.append({"t_s": 0.03 * i})
	n = d.on_dust(9, {"clock": {"tau": 2.0}, "ship": {"ism": {"impacts": many}}})
	check(n == 12 and d.log_text().count(" dust_tick v") == 3 + 1 + 8 and d.log_text().contains("t9.dx dust_tick ×4"), "S2: twelve counts in one tick: eight sound, four are logged as a count (t9.dx dust_tick ×4)")
	check(d.on_dust(10, {"ship": {}}) == 0 and d.on_dust(11, {}) == 0, "S2: a world without impacts counts nothing")
	n = d.on_dust(1, {"clock": {"tau": 0.001}, "ship": {"ism": {"impacts": [{"t_s": 0.0}]}}})
	check(n == 1, "S2: a new game (the ship's clock back near 0) counts again: the dead time is not carried into it")
	d.free()


## S2: commit_hold has its own player (own_player), so a release can stop it: it fades out, and a new hold
## starts it over from the beginning; its tone lasts exactly the 1.5 s hold, so its pitch is the progress.
func test_commit_hold() -> void:
	var d := SoundDirector.new()
	get_root().add_child(d)
	d.setup()
	var row: Dictionary = d.cues.commit_hold
	check(row.trigger.kind == "game" and row.trigger.name == "commit_hold" and row.trigger.stop_on == "commit_release" and row.get("own_player", false), "S2: commit_hold starts on the hold and stops on commit_release, on its own player")
	check(int(d.assets.commit_hold.frames) == int(GalaxyMap.HOLD_S * 48000.0) and is_equal_approx(ShipConsoles.HOLD_S, GalaxyMap.HOLD_S), "S2: the tone lasts exactly the hold (%d frames = %.1f s, the map's and the consoles' HOLD_S)" % [int(d.assets.commit_hold.frames), GalaxyMap.HOLD_S])
	d.on_game("commit_hold")
	var p: Node = d.get_node_or_null("Loop_commit_hold")
	check(p is AudioStreamPlayer and p.playing, "S2: holding plays commit_hold")
	await create_timer(0.3).timeout
	d.on_game("commit_release")
	await process_frame
	check(d.fading("commit_hold"), "S2: a release fades it out (no click)")
	await create_timer(0.2).timeout
	check(not p.playing, "S2: and it has stopped after the 80 ms fade")
	d.on_game("commit_hold")
	check(p.playing and p.get_playback_position() < 0.1, "S2: a new hold starts it over from the beginning")
	d.fire("drive_boost", "t1.0", 1)
	var boost: Node = d.get_node_or_null("Loop_drive_boost")
	d.fire("drive_silent", "t2.0", 2)
	await process_frame
	check(boost != null and d.fading("drive_boost"), "S2: the phase turning to cruising fades the boost out under drive_silent (stops), so the drive never boosts and coasts at once")
	var bad_stop := [{"id": "x", "trigger": {"kind": "game", "name": "x"}, "streams": ["ui_click"], "bus": "UI", "visual": "ambient: test", "about": "test", "stops": ["ui_click"]}, {"id": "ui_click", "trigger": {"kind": "game", "name": "y"}, "streams": ["ui_click"], "bus": "UI", "visual": "ambient: test", "about": "test"}]
	check(SoundData.check_cues({"schema": SoundData.CUES_SCHEMA, "cues": bad_stop}, d.assets).size() == 1, "S2: a cue may stop only a loop or an own_player cue (negative control)")
	d.queue_free()


## S2 (§D6, standing order 2026-10-30): the beacon's plan is the comms station's receiver plan at the sim's
## Earth rate, unrounded: in beam and away from home only; Receiver clamps the stream's rate to the
## receiver's real-time range and corrects by 1/rate; True plays at D and is off outside the audible band.
func test_beacon_plan() -> void:
	var rx: Dictionary = EarthFeed.copy().sound.receiver
	var e := func(rate: float, in_beam := true, at_home := false) -> Dictionary: return {"earth": {"rate": rate, "in_beam": in_beam, "at_home": at_home}}
	var p: Dictionary = HomeBeacon.plan_for(e.call(0.070888125), true)
	check(p.on and p.d == 0.070888125 and p.rate == 0.070888125 and is_equal_approx(p.correct, 1.0 / 0.070888125), "S2 Receiver at D = 0.070888125 (outbound at 0.99c): the stream at D exactly, corrected by 1/D")
	p = HomeBeacon.plan_for(e.call(0.070888125), false)
	check(p.on and p.rate == 0.070888125 and p.correct == 1.0, "S2 True at D = 0.070888125: speed and pitch x D, uncorrected (the 400 Hz carrier at 28.4 Hz)")
	p = HomeBeacon.plan_for(e.call(0.03), true)
	check(p.on and p.d == 0.03 and p.rate == float(rx.min_rate), "S2: the station's plan holds a recorded feed at min_rate %s below its real-time range; the beacon's plan keeps D (0.03) for its live carrier" % rx.min_rate)
	p = HomeBeacon.plan_for(e.call(30.0), true)
	check(p.on and p.d == 30.0 and p.rate == float(rx.max_rate), "S2: above it the station's plan holds max_rate %s; the beacon's plan keeps D (30)" % rx.max_rate)
	var kb := HomeBeacon.new()
	var kd := SoundDirector.new()
	kd.audible = false
	kd.setup()
	kb.follow(kd, e.call(0.03), true)
	var k1 := kb._rate
	kb.follow(kd, e.call(30.0), true)
	check(k1 == 0.03 and kb._rate == 30.0 and float(kd.pitches.home_beacon_rx) == 30.0, "S2 Receiver keys at D unrounded beyond the station's range (0.03 and 30), correcting only the frequency")
	kd.free()
	var aud: Array = rx.audible
	check(HomeBeacon.plan_for(e.call(float(aud[0])), false).on and not HomeBeacon.plan_for(e.call(float(aud[0]) * 0.999), false).on and HomeBeacon.plan_for(e.call(float(aud[1])), false).on and not HomeBeacon.plan_for(e.call(float(aud[1]) * 1.001), false).on, "S2 True: on inside receiver.audible [%s, %s], silent just outside it" % [aud[0], aud[1]])
	check(HomeBeacon.plan_for(e.call(float(aud[0]) * 0.5), false).hearing == "below" and HomeBeacon.plan_for(e.call(float(aud[1]) * 2.0), false).hearing == "above", "S2 True: below and above hearing are named (the station's words)")
	check(float(aud[0]) * HomeBeacon.CARRIER_HZ <= 20.0 and float(aud[1]) * HomeBeacon.CARRIER_HZ >= 20000.0 and float(aud[1]) * HomeBeacon.CARRIER_HZ < 0.5 * 44100.0, "S2: the 400 Hz carrier spans human hearing (20 Hz..20 kHz) inside the audible band and stays below the mixer's Nyquist at its top (%.0f Hz)" % (float(aud[1]) * HomeBeacon.CARRIER_HZ))
	check(not HomeBeacon.plan_for(e.call(0.5, false), true).on and not HomeBeacon.plan_for(e.call(1.0, true, true), true).on and not HomeBeacon.plan_for({}, true).on and not HomeBeacon.plan_for({"earth": {"in_beam": true}}, true).on, "S2: out of Earth's beam, at home, or with no Earth link, the beacon is off")
	var d := SoundDirector.new()
	d.audible = false
	d.setup()
	var b := HomeBeacon.new()
	b.follow(d, e.call(0.070888125), true)
	check(b.cue == "home_beacon_rx" and b._rate == 0.070888125 and d.cues.home_beacon_rx.get("generator", false), "S2 Receiver at D = 0.070888125: the generated row, its envelope at D exactly (no bus shift)")
	check(b.env.size() == 24000 and absf(Array(b.env).max() - db_to_linear(-3.0)) < 2e-4, "S2: the envelope table is 2 s at 12 kHz and peaks at the carrier's -3 dBFS (%d samples)" % b.env.size())
	b.follow(d, e.call(0.0708881), true)
	b.follow(d, e.call(14.107), false)
	check(b.cue == "home_beacon", "S2 True at D = 14.107: the 400 Hz carrier itself at D")
	b.follow(d, e.call(60.0), false)
	b.follow(d, e.call(14.107), false)
	var want := "r1 home_beacon_rx 0.0709\ng1 home_beacon_rx v0 +0c -18.0dB\nr2 home_beacon 14.1070\ng2 home_beacon v0 +0c -18.0dB\ng4 home_beacon v0 +0c -18.0dB\n"
	check(d.log_text() == want, "S2: the beacon starts at its rate (set before it plays), changes row with the setting, stops above hearing (g3) and starts again inside it:\n" + d.log_text())
	check(float(d.pitches.home_beacon) == 14.107 and float(d.pitches.home_beacon_rx) == 0.0708881, "S2: the beacon plays at the latest Earth rate unrounded (0.0708881, a change of 3.5e-7 that the log does not show; 14.107)")
	d.free()


## S2, measured (as test_receiver_measured): the shipped beacon through the real Instruments bus, captured
## from the mixer. The carrier's frequency from zero crossings is 400 Hz in Receiver and 400 D Hz in True,
## within 1 %, at D = 0.070888 (outbound at 0.99c, True: 28.4 Hz), 0.5, 2, 5 and 14.107 (homebound). Earth's
## pips are counted with the same detector in both settings and their mean gap must be 1/D within 1 %:
## Receiver's are generated at the true carrier, so they stay as sharp as True's (an FFT shifter merged
## them: 8 to 16 of 21 survived at D = 14.1). At D = 0.070888 the pips are 14.1 s apart; that point is
## asserted on the generator's own clock (two pips in 30 s of samples) rather than 30 s of mixer time.
func test_beacon_measured() -> void:
	SoundMix.ensure_layout()
	var d := SoundDirector.new()
	get_root().add_child(d)
	d.setup()
	var cap := AudioEffectCapture.new()
	cap.buffer_length = 7.0
	AudioServer.add_bus_effect(0, cap, 0)
	var rate := AudioServer.get_mix_rate()
	var b := HomeBeacon.new()
	var ok := true
	var seen := []
	var pip_ok := true
	var pips := []
	var counts := {}
	for dd: float in [0.070888, 0.5, 2.0, 5.0, 14.107, 30.0]: # 30: beyond the station's 16x real-time range
		for receiver: bool in [true, false]:
			b.follow(d, {"earth": {"rate": dd, "in_beam": true, "at_home": false}}, receiver)
			var p: Node = d.get_node_or_null("Loop_" + b.cue)
			await create_timer(0.2).timeout
			cap.clear_buffer()
			var span := 6.2 if dd == 0.5 else 2.2 if dd == 2.0 else 1.2 # three or more pips at D >= 0.5
			await create_timer(span).timeout
			var buf := cap.get_buffer(cap.get_frames_available())
			var crossings := 0
			for i in range(1, buf.size()):
				if (buf[i - 1].x < 0.0) != (buf[i].x < 0.0):
					crossings += 1
			var hz := crossings * 0.5 * rate / maxf(buf.size(), 1.0)
			var want := HomeBeacon.CARRIER_HZ * (1.0 if receiver else dd)
			seen.append("D %s %s %.1f Hz (want %.1f)" % [dd, "receiver" if receiver else "true", hz, want])
			ok = ok and p != null and p.playing and buf.size() > 0 and absf(hz / want - 1.0) <= 0.01
			if dd >= 0.5:
				var g := _pip_gap(buf, rate, want)
				pips.append("%s D %s: %d pips of %d due, gap %.4f s (want %.4f)" % ["receiver" if receiver else "true", dd, g[0], int(floor(buf.size() / rate * dd)), g[1], 1.0 / dd])
				pip_ok = pip_ok and g[0] >= 3 and absf(g[1] * dd - 1.0) <= 0.01
				var due := int(floor(buf.size() / rate * dd)) # Earth seconds in this capture (its length varies with load)
				counts[[dd, receiver]] = [g[0], due]
			var was := b.cue
			b.follow(d, {}, receiver) # off between settings, so each starts afresh
			d.stop(was, true)
			await process_frame
	for k: Array in counts: # no pip lost in either setting: every Earth second in the capture has its pip (one may straddle an edge)
		pip_ok = pip_ok and int(counts[k][0]) >= int(counts[k][1]) - 1
	AudioServer.remove_bus_effect(0, 0)
	check(ok, "S2 measured through the mixer: the beacon's carrier is 400 Hz in Receiver and 400 D Hz in True, within 1 %% (%s)" % ", ".join(seen))
	check(pip_ok, "S2 measured: the time rate is D in both settings at every D, beyond the receiver's real-time range too: Earth's pips every 1/D s within 1 %%, none lost (%s)" % "; ".join(pips))
	# Below the real-time range and outbound at 0.99c, on the Receiver's own sample clock (no mixer wait):
	# D = 0.03 (pips 33.3 s apart, where the station's clamp would give 16 s) and D = 0.070888 (14.1 s).
	var slow := HomeBeacon.new()
	var slow_ok := true
	var slow_seen := []
	for dd: float in [0.03, 0.070888]:
		slow.follow(d, {"earth": {"rate": dd, "in_beam": true, "at_home": false}}, true)
		var pb := _Collect.new()
		slow._pos = 0.0
		slow._fill(pb, int((2.1 / dd + 0.5) * SoundDirector.GEN_RATE))
		var g2 := _pip_gap(pb.frames, SoundDirector.GEN_RATE, 400.0)
		slow_seen.append("D %s: %d pips %.3f s apart (want %.3f)" % [dd, g2[0], g2[1], 1.0 / dd])
		slow_ok = slow_ok and slow._rate == dd and g2[0] >= 2 and absf(g2[1] * dd - 1.0) <= 0.01
	check(slow_ok, "S2 Receiver keys at D below the station's real-time range too (%s)" % ", ".join(slow_seen))
	# Negative control: the same generator keyed at 2.01 x D must not pass as D (the detector does not know
	# the expected gap), while keyed at D it does.
	var neg_ok := true
	var neg_seen := []
	for dd: float in [0.5, 2.0]:
		for factor: float in [1.0, 2.01]:
			var gb := HomeBeacon.new()
			gb.follow(d, {"earth": {"rate": dd, "in_beam": true, "at_home": false}}, true)
			gb._rate = dd * factor
			gb._pos = 0.0
			var pc := _Collect.new()
			gb._fill(pc, int(6.0 / dd * SoundDirector.GEN_RATE))
			var g3 := _pip_gap(pc.frames, SoundDirector.GEN_RATE, 400.0)
			var passes: bool = g3[0] >= 3 and absf(g3[1] * dd - 1.0) <= 0.01
			neg_seen.append("D %s keyed x%s: gap %.4f s, %s" % [dd, factor, g3[1], "passes" if passes else "fails"])
			neg_ok = neg_ok and passes == (factor == 1.0)
			gb.follow(d, {}, true)
	d.stop("home_beacon_rx", true)
	check(neg_ok, "S2 negative control: keying at 2.01 x D fails the pip check, keying at D passes (%s)" % "; ".join(neg_seen))
	slow.follow(d, {}, true)
	d.stop("home_beacon_rx", true)
	d.queue_free()


## Stands in for an AudioStreamGeneratorPlayback: keeps what HomeBeacon pushes.
class _Collect:
	extends RefCounted
	var frames := PackedVector2Array()

	func push_buffer(b: PackedVector2Array) -> bool:
		frames.append_array(b)
		return true


## [pip count, mean gap s], blind to the expected gap: RMS windows of two carrier periods (or 2 ms); the
## floor is the quietest tenth of the windows; a pip starts where the level rises through 30 % of the way
## from the floor to the loudest window (a short pip at high D reaches about 40 % in these windows), and the
## detector re-arms only after the level falls below 15 %.
## The mean spans an even number of gaps (the beacon alternates a long and a short pip).
func _pip_gap(buf: PackedVector2Array, rate: float, heard_hz: float) -> Array:
	var w := int(rate * maxf(0.002, 2.0 / maxf(heard_hz, 1.0)))
	var env := []
	for i in range(0, buf.size() - w, w):
		var s := 0.0
		for j in w:
			s += buf[i + j].x * buf[i + j].x
		env.append(sqrt(s / w))
	if env.size() < 10:
		return [0, 0.0]
	var sorted := env.duplicate()
	sorted.sort()
	var floor_v: float = sorted[sorted.size() / 10]
	var top: float = sorted.back()
	var hi := floor_v + 0.3 * (top - floor_v)
	var lo := floor_v + 0.15 * (top - floor_v)
	var o := []
	var armed := false
	for i in env.size():
		if armed and env[i] >= hi:
			o.append(float(i * w) / rate)
			armed = false
		elif env[i] < lo:
			armed = true
	if o.size() < 2:
		return [o.size(), 0.0]
	var last := o.size() - 1 if (o.size() - 1) % 2 == 0 or o.size() == 2 else o.size() - 2
	return [o.size(), (o[last] - o[0]) / last]


func test_home_pitch() -> void:
	var d := SoundDirector.new()
	get_root().add_child(d)
	d.setup()
	SoundMix.ensure_layout()
	d.set_pitch("home_town", 0.070888)
	d.on_game("home_town")
	var p: Node = d.get_node_or_null("Loop_home_town")
	check(p is AudioStreamPlayer and p.playing and is_equal_approx(p.pitch_scale, 0.070888) and p.bus == &"Receiver", "AR8b: a home bed starts at the Earth rate, unrounded (0.070888), on the Receiver bus")
	d.set_pitch("home_town", 14.107)
	d.set_pitch("home_town", 14.107)
	check(is_equal_approx(p.pitch_scale, 14.107) and d.log_text().contains("r1 home_town 0.0709") and d.log_text().contains("r2 home_town 14.1070") and not d.log_text().contains("r3 "), "EL3b.7/AR8b: set_pitch moves the playing loop and logs each change once:\n" + d.log_text())
	var rx := AudioServer.get_bus_index("Receiver")
	var shift := SoundMix._find_effect(rx, "AudioEffectPitchShift") as AudioEffectPitchShift
	check(rx >= 0 and AudioServer.get_bus_send(rx) == &"Instruments" and shift != null and not AudioServer.is_bus_effect_enabled(rx, 0), "AR8b: the Receiver bus feeds Instruments, its pitch shift off until the receiver corrects")
	SoundMix.set_receiver(1.0 / 0.070888)
	check(AudioServer.is_bus_effect_enabled(rx, 0) and is_equal_approx(shift.pitch_scale, 1.0 / 0.070888), "AR8b: correcting a stream slowed to D = 0.070888 raises its pitch by 1/D (14.107)")
	SoundMix.set_receiver(1.0)
	check(not AudioServer.is_bus_effect_enabled(rx, 0) and is_equal_approx(shift.pitch_scale, 1.0), "AR8b: no correction (the True setting, or at rest) leaves the shift off")
	var beds := ["home_family", "home_home", "home_town", "home_world", "home_science", "home_sky", "home_babble", "home_static"]
	check(beds.all(func(b: String) -> bool: return d.cues.has(b) and d.cues[b].get("loop", false) and d.cues[b].trigger.get("stop_on", "") == "home_none" and float(d.cues[b].get("fade_out_ms", 0.0)) > 0.0), "EL3b.7: every home bed is a loop that fades out on home_none")
	d.on_game("home_none")
	await process_frame
	check(p.playing and d.fading("home_town"), "EL3b.7: home_none fades the bed out instead of cutting it")
	d.on_game("home_town")
	check(p.playing and not d.fading("home_town") and is_equal_approx(p.volume_db, float(d.cues.home_town.volume_db)), "EL3b.7: fired again while fading, it starts over at its level")
	d.on_game("home_none")
	await create_timer(float(d.cues.home_town.fade_out_ms) / 1000.0 + 0.2).timeout
	check(not p.playing and not d.fading("home_town"), "EL3b.7: after the fade it has stopped")
	d.queue_free()


func _run() -> void:
	var root := fresh("tables")
	var rows := [tone(root, "a"), tone(root, "b")]
	# The tables reference files under <root>; resolve them there.
	var d := SoundDirector.new()
	d.audible = false
	var errs := d.setup(cues_file(root, base_cues()), manifest(root, rows), "res://")
	check(errs.is_empty(), "AC1: a well-formed cue table and manifest validate (%s)" % "; ".join(errs))
	check(SoundData.check_files(SoundData.load_assets(root.path_join("data/audio/assets.json")), root).is_empty(), "AC8: the files match their manifest rows (bytes, sha256, 48 kHz 16-bit, frames)")

	# AC1 negative controls: each defect alone is rejected.
	var bad_trigger := base_cues()
	bad_trigger[0] = bad_trigger[0].duplicate(true)
	bad_trigger[0].trigger = {"kind": "sim_evnt", "k": "committed"}
	var e1 := SoundData.check_cues({"schema": SoundData.CUES_SCHEMA, "cues": bad_trigger}, d.assets)
	check(e1.size() == 1 and e1[0].contains("unknown trigger kind"), "AC1: a renamed trigger kind is rejected (%s)" % "; ".join(e1))
	var bad_stream := base_cues()
	bad_stream[1] = bad_stream[1].duplicate(true)
	bad_stream[1].streams = ["nope"]
	var e2 := SoundData.check_cues({"schema": SoundData.CUES_SCHEMA, "cues": bad_stream}, d.assets)
	check(e2.size() == 1 and e2[0].contains("not in the asset manifest"), "AC1: a missing stream is rejected (%s)" % "; ".join(e2))
	var bad_bus := base_cues()
	bad_bus[2] = bad_bus[2].duplicate(true)
	bad_bus[2].bus = "Ship"
	var e3 := SoundData.check_cues({"schema": SoundData.CUES_SCHEMA, "cues": bad_bus}, d.assets)
	check(e3.size() == 1 and e3[0].contains("not a cue bus"), "AC1: an unknown or mixing bus is rejected (%s)" % "; ".join(e3))

	# AC5: the visual counterpart and the forbidden words.
	var no_vis := base_cues()
	no_vis[3] = no_vis[3].duplicate(true)
	no_vis[3].visual = "ambient: none"
	var e4 := SoundData.check_cues({"schema": SoundData.CUES_SCHEMA, "cues": no_vis}, d.assets)
	check(e4.size() == 1 and e4[0].contains("visual counterpart"), "AC5: an informative cue without a visual counterpart in the code is rejected")
	var ghost := base_cues()
	ghost[3] = ghost[3].duplicate(true)
	ghost[3].visual = "ui/arrival_card.gd::NoSuchThing"
	check(SoundData.check_cues({"schema": SoundData.CUES_SCHEMA, "cues": ghost}, d.assets).size() == 1, "AC5: a counterpart that does not exist in the code is rejected")
	var judging := base_cues()
	judging[3] = judging[3].duplicate(true)
	judging[3].about = "a victory fanfare on arrival"
	var e5 := SoundData.check_cues({"schema": SoundData.CUES_SCHEMA, "cues": judging}, d.assets)
	check(e5.size() == 2 and e5[0].contains("judges the player"), "AC5: 'victory' and 'fanfare' are rejected (Pillar 2)")
	var window := base_cues()
	window[5] = window[5].duplicate(true)
	window[5].about = "a click when a window opens"
	check(SoundData.check_cues({"schema": SoundData.CUES_SCHEMA, "cues": window}, d.assets).is_empty(), "AC5: whole words only ('window' is not 'win')")

	# AC8 and D-101: licences, provenance, generated sound reserved and off.
	var lib := tone(root, "lib_ok", "library")
	var gen := tone(root, "gen", "generated")
	var m := SoundData.load_assets(manifest(root, [lib, gen]))
	var e6 := SoundData.check_rows(m)
	check(e6.size() == 1 and e6[0].contains("not allowed yet"), "D-101: a generated row is rejected while allow_generated is false (%s)" % "; ".join(e6))
	check(SoundData.check_rows(SoundData.load_assets(manifest(root, [lib, gen], true))).is_empty(), "D-101: the same generated row with full provenance passes once allow_generated is true (the slot is ready)")
	var ccby := lib.duplicate(true)
	ccby.licence = "CC-BY-4.0"
	check(SoundData.check_rows(SoundData.load_assets(manifest(root, [ccby]))).size() == 1, "AC8: a CC-BY library file is rejected (CC0 only)")
	var noprov := lib.duplicate(true)
	noprov.provenance.erase("url")
	check(SoundData.check_rows(SoundData.load_assets(manifest(root, [noprov]))).size() == 1, "AC8: a library file without its URL is rejected")
	var wrongsha := tone(root, "a")
	wrongsha.sha256 = "f".repeat(64)
	var e7 := SoundData.check_files(SoundData.load_assets(manifest(root, [wrongsha])), root)
	check(e7.size() == 1 and e7[0].contains("sha256"), "AC8: a wrong sha256 is rejected")
	var over := SoundData.load_assets(manifest(root, rows))
	over.budget_bytes = 100
	check(SoundData.check_files(over, root).back().contains("budget"), "AC8: the git budget is enforced")

	# AC4 and the clocks: the scripted session.
	var s := director(root, base_cues(), rows)
	session(s)
	var want := PackedStringArray([
		"g1 spire_hum", "t10.1 commit_seal", "t10.2 drive_boost", "t13.s medium_change", "t40.0 drive_silent",
		"u1 ui_click", "u3 ui_click", "w1 footstep", "w10 footstep", "t90.1 arrived", "t91.0 arrived"])
	var got := s.log_text()
	var order_ok := true
	var at := 0
	for w in want:
		var i := got.find(w, at)
		if i < 0: order_ok = false
		else: at = i
	check(order_ok, "AC4: sim events, a state edge, UI inputs and steps fire their cues in order:\n" + got)
	check(not got.contains("t10.0"), "AC4: an event with no cue (echo) fires nothing")
	check(not got.contains("u2 "), "the UI cooldown counts inputs: the second click of three is skipped")
	check(not got.contains("t12"), "a sim_state cue fires on a change, not on every tick")
	check(s.steps() == 10, "AC3: 7.0 m walked in two halves gives 10 steps (got %d)" % s.steps())
	var a := director(root, base_cues(), rows)
	a.add_walk_mm(6990)
	var b := director(root, base_cues(), rows)
	b.add_walk_mm(7000)
	check(a.steps() == 9 and b.steps() == 10, "AC3: the integer accumulator: 6,990 mm -> 9 steps, 7,000 mm -> 10")
	var c := director(root, base_cues(), rows)
	for i in 700:
		c.walked(0.01)
	check(c.steps() == 10, "AC3: 700 frames of 10 mm also give 10 steps (frame split does not matter)")
	var again := director(root, base_cues(), rows)
	session(again)
	check(again.log_text() == got, "AC2: the same input gives a byte-identical cue log in one process")
	var v1 := director(root, base_cues(), rows)
	var v2 := director(root, base_cues(), rows)
	for i in 40:
		v1.fire("arrived", "x%d" % i, i)
		v2.fire("arrived", "x%d" % i, i)
	var vt := v1.log_text()
	var cents_ok := true
	for l in v1.cue_log:
		var cts := int(l.split(" ")[3].trim_suffix("c"))
		cents_ok = cents_ok and absi(cts) <= 20
	check(vt == v2.log_text() and vt.contains(" v0 ") and vt.contains(" v1 ") and cents_ok, "deterministic variation: 40 fires use both variants, pitch within +/-20 cents, identical in two directors")
	# D-123: a cue's level jitter stays within +/- volume_jitter_db and every other fire is alternate_db softer.
	var jc := base_cues()
	for cr: Dictionary in jc:
		if cr.id == "footstep":
			cr["volume_jitter_db"] = 1.5
			cr["alternate_db"] = -2.0
	var vj := director(root, jc, rows)
	for i in 40:
		vj.fire("footstep", "s%d" % i, i)
	var jit_ok := true
	var levels := {}
	var pitches := {}
	for i in vj.cue_log.size():
		pitches[vj.cue_log[i].split(" ")[3]] = true
		var db := float(vj.cue_log[i].split(" ")[4].trim_suffix("dB"))
		var base := -14.0 + (-2.0 if i % 2 == 1 else 0.0)
		jit_ok = jit_ok and absf(db - base) <= 1.5 + 0.051
		levels[db] = true
	check(jit_ok and levels.size() >= 15 and pitches.size() >= 15, "D-123: footstep level jitter within +/-1.5 dB, odd steps 2 dB softer; %d distinct levels and %d distinct pitches in 40 steps (no metronome)" % [levels.size(), pitches.size()])
	check(s.cue_log.size() > 0 and s.errors.is_empty(), "the director logs while silent (audible = false)")

	# D-108: the spire's degradation layer follows a parameter; the sim's Memory Health drives it when present.
	var drift := {"id": "drift", "trigger": {"kind": "game", "name": "level_bridge", "stop_on": "level_none"}, "streams": ["a"], "bus": "Ambience", "loop": true,
		"volume_db": -20.0, "param": {"name": "archive_degradation", "points": [[0.0, -80.0], [0.5, -10.0], [1.0, -4.0]]}, "visual": "ambient: no information", "about": "test"}
	var pd := director(root, base_cues() + [drift], rows)
	check(pd.errors.is_empty(), "D-108: a loop with a param curve validates (%s)" % "; ".join(pd.errors))
	check(is_equal_approx(SoundDirector.curve_db(drift.param.points, 0.25), -45.0) and is_equal_approx(SoundDirector.curve_db(drift.param.points, 1.5), -4.0), "D-108: the param curve interpolates (0.25 -> -45 dB) and clamps")
	pd.on_sim_world(5, {"ship": {}})
	check(not pd.params.has("archive_degradation"), "D-108: with no Memory Health in the world the layer stays pristine (nothing is invented)")
	pd.on_sim_world(6, {"archive": {"memory_health": 50}})
	check(is_equal_approx(float(pd.params.archive_degradation), 0.5) and pd.log_text().contains("p1 archive_degradation 0.50"), "D-108: archive.memory_health 50 -> archive_degradation 0.50, logged")
	pd.on_sim_world(7, {"archive": {"memory_health": 50.4}})
	check(not pd.log_text().contains("p2 "), "D-108: a change under 0.01 is not logged again")
	pd.on_game("level_bridge")
	check(pd.log_text().contains("drift v0 +0c -30.0dB"), "D-108: the layer starts at its curve's level for the current degradation (-20 + -10 dB):\n" + pd.log_text())
	var badp := base_cues() + [drift.duplicate(true)]
	badp.back().loop = false
	check(SoundData.check_cues({"schema": SoundData.CUES_SCHEMA, "cues": badp}, pd.assets).size() == 1, "D-108: a one-shot cannot follow a param")
	var badn := base_cues() + [drift.duplicate(true)]
	badn.back().param = {"name": "mood", "points": [[0.0, 0.0], [1.0, 0.0]]}
	check(SoundData.check_cues({"schema": SoundData.CUES_SCHEMA, "cues": badn}, pd.assets).size() == 1, "D-108: an unknown param is rejected")

	# The shipped tables (S0b): they validate, and a loop loads with its manifest loop points.
	var shipped := SoundDirector.new()
	shipped.audible = false
	var se := shipped.setup()
	check(se.is_empty() and shipped.cues.size() >= 17, "the shipped cue table and manifest validate (%d cues; %s)" % [shipped.cues.size(), "; ".join(se)])
	var hum := shipped.stream("spire_hum")
	check(hum != null and hum.loop_mode == AudioStreamWAV.LOOP_FORWARD and hum.loop_end == 384000 and hum.mix_rate == 48000, "spire_hum loads as a 48 kHz loop of 384,000 frames (8 s)")
	check(SoundDirector.bundle_path("assets/audio/synth/nope.wav") == "res://audio_bundle/synth/nope.res", "the export reads the staged QOA bundle (audio_bundle/<kind>/<file>.res)")
	shipped.free()
	await test_home_pitch()
	await test_receiver_measured()
	test_dust()
	await test_commit_hold()
	test_beacon_plan()
	await test_beacon_measured()

	# The bus layout (§D2).
	SoundMix.ensure_layout()
	var lay := SoundMix.is_layout_ok()
	check(lay.is_empty(), "§D2: the bus layout matches SoundMix.BUSES (%s)" % "; ".join(lay))
	SoundMix.ensure_layout()
	check(AudioServer.bus_count == 1 + SoundMix.BUSES.size(), "§D2: ensure_layout is idempotent (%d buses)" % AudioServer.bus_count)
	check(is_equal_approx(SoundMix.percent_to_db(100), 0.0) and SoundMix.percent_to_db(0) <= -80.0 and absf(SoundMix.percent_to_db(50) + 12.04) < 0.01, "AC9: 100% = 0 dB, 50% = -12 dB, 0% mutes")

	var args := _args()
	if args.has("log-out"):
		var f := FileAccess.open(args["log-out"], FileAccess.WRITE)
		f.store_string(got)
		f.close()
	for n in get_root().get_children(): # finish deferred frees (the beacon's generator playback) before quitting
		n.queue_free()
	for i in 3:
		await process_frame
	print("sound: %d passed, %d failures" % [passed, failed])
	quit(1 if failed > 0 else 0)
