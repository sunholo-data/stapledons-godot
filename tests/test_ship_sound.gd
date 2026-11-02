extends SceneTree
## R2-SOUND S1 (design §D4, §D5; AC3, AC10): the bridge's sound through ShipSound on a mock ship:
## the level's loops at the mast, footsteps from CA0's foot_down, console wake/sleep at the station,
## key presses, the lift's start/run/arrive riding with the platform, the bridge's room, Memory Health
## from the journey session, and the listener: a sound left on screen is left in the ears in Bow and
## right when the view turns to Astern (captured through the real mixer, headless). R3-EARTH-LINK EL3b.7:
## with the comms station open the feed's home bed plays at the receiver at the band's pitch, its accents fire
## once each, and closing the station fades it out.
## Run: godot --headless --path . --script tests/test_ship_sound.gd
const Mock := preload("res://tests/fixtures/sound/mock_ship.gd")
var failed := 0
var passed := 0


func check(ok: bool, message: String) -> void:
	if ok: passed += 1
	else: failed += 1
	print("%s %s" % ["ok" if ok else "FAIL", message])


func _initialize() -> void:
	_run.call_deferred()


func count(log: String, id: String) -> int:
	var n := 0
	for l in log.split("\n"):
		if l.contains(" " + id + " "):
			n += 1
	return n


func frames(n := 2) -> void:
	for i in n:
		await process_frame


func _run() -> void:
	var ship: Node3D = Mock.new()
	root.add_child(ship)
	var spire := OmniLight3D.new()
	spire.name = "SpireLight"
	spire.position = Vector3(0, 7, -2)
	ship.add_child(spire)
	ship.add_child(ship.lift.platform)
	ship.lift.platform.position = Vector3(8, 0, -8)
	var cam := Camera3D.new()
	ship.add_child(cam)
	cam.current = true
	var ss := ShipSound.new().attach(ship)
	ship.add_child(ss)
	await frames()
	var d := ss.sound
	check(d.errors.is_empty(), "the shipped tables validate (%s)" % "; ".join(d.errors))
	var hum: Node = d.get_node_or_null("Loop_spire_hum")
	check(hum is AudioStreamPlayer3D and hum.playing and (hum as AudioStreamPlayer3D).global_position.is_equal_approx(Vector3(0, 7, -2)), "on the bridge the hum plays in 3D at the mast")
	check(d.get_node_or_null("Loop_room_bridge") is AudioStreamPlayer, "the room tone is a 2D bed")
	var rev := SoundMix._find_effect(AudioServer.get_bus_index("Ship"), "AudioEffectReverb") as AudioEffectReverb
	check(rev != null and is_equal_approx(rev.wet, db_to_linear(-14.0)) and is_equal_approx(rev.room_size, 0.8), "the bridge's room is on the Ship reverb (wet -14 dB, size 0.8)")

	for i in 3:
		ship.captain_event.emit({"type": "foot_down", "side": "L" if i % 2 == 0 else "R"})
	ship.captain_event.emit({"type": "clip", "clip": "idle"})
	check(count(d.log_text(), "footstep_deck") == 3, "AC3: three foot_down events give three footsteps; other captain events none")

	ship.consoles.focused = "navigation"
	await frames()
	ship.consoles.used.emit("navigation", "plan")
	ship.consoles.focused = ""
	await frames()
	var log := d.log_text()
	check(count(log, "console_wake") == 1 and count(log, "console_sleep") == 1 and count(log, "console_key") == 1 and log.find("console_wake") < log.find("console_key") and log.find("console_key") < log.find("console_sleep"), "a console wakes, takes a key, sleeps, in order")
	check(ss.position_of("station").is_equal_approx(Vector3(0, 1, -7)), "console sounds sit at the station")

	ship.lift.state = "descending"
	await frames()
	var run: Node = d.get_node_or_null("Loop_lift_run")
	check(count(d.log_text(), "lift_start") == 1 and run is AudioStreamPlayer3D and run.playing, "the lift starts and its motor runs in 3D")
	ship.lift.platform.position = Vector3(8, -6, -8)
	await frames()
	check((run as AudioStreamPlayer3D).global_position.is_equal_approx(Vector3(8, -6, -8)), "the motor rides with the platform")
	ship.lift.state = "lower_ready"
	ship.active_level = 1
	await frames()
	check(count(d.log_text(), "lift_arrive") == 1 and not run.playing, "on arrival the bell sounds and the motor stops")
	check(not hum.playing and is_equal_approx(rev.wet, db_to_linear(-20.0)), "leaving the bridge stops its loops and changes the room")
	ship.active_level = 0
	await frames()
	check(hum.playing, "back on the bridge the hum returns")

	var sim: Variant = Mock.MockSim.new()
	ship.journey_sim = sim
	await frames()
	check(is_equal_approx(float(d.params.get("archive_degradation", -1.0)), 0.5), "the journey session's Memory Health 50 reaches the spire's layer (degradation 0.50)")

	# R3-EARTH-LINK EL3b.7: sound from home while the comms station is open.
	var st := CommsStation.new()
	ship.add_child(st)
	var wk := {"frame": 3, "kind": "library", "event": {"id": "town-market", "category": "town", "words": "market day"}, "pick": 0, "context": {}}
	var ev := {"rate": 0.070888, "in_beam": true, "at_home": false, "light_age_years": 2.0, "newest_light_year": 0.3, "feed": wk, "last_feed": wk}
	st.refresh({"earth": ev, "clock": {"t": 1.0, "tau": 0.5}})
	ship.consoles.comms_station = st
	await frames()
	check(d.get_node_or_null("Loop_home_town") == null, "no home sound until the comms station is open")
	ship.consoles.focused = "comms"
	await frames()
	var bed: Node = d.get_node_or_null("Loop_home_town")
	var rx := AudioServer.get_bus_index("Receiver")
	var shift := SoundMix._find_effect(rx, "AudioEffectPitchShift") as AudioEffectPitchShift
	check(bed is AudioStreamPlayer3D and bed.playing and is_equal_approx(bed.pitch_scale, 0.070888) and (bed as AudioStreamPlayer3D).global_position.is_equal_approx(Vector3(5, 1, -7)), "the station open: the week's bed plays at the receiver, slowed to the Earth rate D = 0.070888 exactly")
	check(AudioServer.is_bus_effect_enabled(rx, 0) and is_equal_approx(shift.pitch_scale, 1.0 / 0.070888), "AR8b Receiver (the default): the frequency corrected by 1/D, so home is in slow motion at its true pitch")
	ev.rate = 14.107
	st.refresh({"earth": ev, "clock": {"t": 1.0, "tau": 0.5}})
	await frames()
	check(is_equal_approx(bed.pitch_scale, 14.107) and is_equal_approx(shift.pitch_scale, 1.0 / 14.107), "turning for home the bed runs 14.107x, corrected down to its true pitch")
	st.feed.advance(float(EarthFeed.copy().sound.first_s) / 0.070888 + 0.01) # due first_s / D after the bed began (D = 0.070888)
	await frames()
	check(d.log_text().count(" home_town_bells v") == 1, "the town's bells sound once when due:\n" + d.log_text())
	await frames()
	check(d.log_text().count(" home_town_bells v") == 1, "and not again until the next is due")
	st.feed.set_receiver(false)
	await frames()
	check(is_equal_approx(bed.pitch_scale, 14.107) and not AudioServer.is_bus_effect_enabled(rx, 0), "AR8b True: speed and pitch x D, uncorrected")
	ev.rate = 1414.2
	st.refresh({"earth": ev, "clock": {"t": 1.0, "tau": 0.5}})
	await frames()
	check(d.fading("home_town") or not bed.playing, "AR8b True at D = 1414: above human hearing, nothing plays")
	st.feed.set_receiver(true)
	ev.rate = 14.107
	st.refresh({"earth": ev, "clock": {"t": 1.0, "tau": 0.5}})
	await frames()
	ship.consoles.focused = ""
	await frames()
	check(d.fading("home_town") or not bed.playing, "closing the station fades the bed out")

	# R2-SOUND S2 (§D6): the voyage through the journey session and the consoles.
	var vs: Variant = Mock.MockSim.new()
	vs.world = {"tick": 20, "clock": {"tau": 0.5}, "journey": {"plan": null}, "ship": {"ism": {"impacts": []}}}
	ship.journey_sim = vs
	await frames()
	vs.world.journey = {"plan": {"target": {"id": "CNS5:3627"}, "cruise_phi": 2.6}}
	vs.world.tick = 21
	vs.stepped.emit([])
	vs.world.journey = {"plan": {"target": {"id": "CNS5:3627"}, "cruise_phi": 3.0}}
	vs.world.tick = 22
	vs.stepped.emit([])
	check(count(d.log_text(), "plan_select") == 1 and d.log_text().contains("t21.s plan_select"), "S2: the sim plotting a new destination plays plan_select once; a speed change to the same target does not")
	ship.consoles.held = 0.4
	await frames()
	var hold: Node = d.get_node_or_null("Loop_commit_hold")
	check(hold is AudioStreamPlayer and hold.playing and count(d.log_text(), "commit_hold") == 1, "S2: holding a console's confirm plays commit_hold")
	ship.consoles.held = 0.0
	await frames()
	check(d.fading("commit_hold"), "S2: releasing it early fades commit_hold out")
	var map: Variant = Mock.MockMap.new()
	ship.journey_map = map
	map.hold_s = 0.5
	await frames()
	check(count(d.log_text(), "commit_hold") == 2 and hold.playing and not d.fading("commit_hold"), "S2: the map's commit dialog hold plays it again, from the start")
	map.hold_s = 1.45
	await frames()
	map.hold_s = 0.0 # the frame that commits clears the hold
	await frames()
	check(hold.playing and not d.fading("commit_hold"), "S2: a hold that completes lets commit_hold finish into the seal (not cut)")
	vs.world.tick = 30
	vs.stepped.emit([{"k": "committed", "plan_id": 1}])
	vs.world.tick = 31
	vs.stepped.emit([{"k": "phase", "from": "at_rest", "to": "boosting"}])
	check(d.log_text().contains("t30.0 commit_seal") and d.log_text().contains("t31.0 drive_boost") and count(d.log_text(), "commit_seal") == 1, "S2 AC4: the sim's committed seals the commit and its phase starts the drive, in the sim's clock")
	vs.world.ship.ism.impacts = [{"t_s": 0.01}, {"t_s": 0.02}, {"t_s": 0.04}]
	vs.world.tick = 32
	vs.stepped.emit([])
	check(d.log_text().contains("t32.d0 dust_tick") and d.log_text().contains("t32.d1 dust_tick") and not d.log_text().contains("t32.d2"), "S2: two of three grains count (one is 10 ms after the first, in the dead time)")
	await create_timer(0.1).timeout
	var at_helm := false
	for q: Node in d.get_children():
		if q is AudioStreamPlayer3D and q.stream == d.stream("dust_tick"):
			at_helm = at_helm or (q as AudioStreamPlayer3D).global_position.is_equal_approx(Vector3(0, 1, -7))
	check(at_helm and ss.position_of("helm").is_equal_approx(Vector3(0, 1, -7)), "S2: the counter ticks at the helm (the navigation station), after each grain's t_s")

	# S2: the home beacon at the helm, at the sim's Earth rate D exactly, with the station's setting.
	vs.world.earth = {"rate": 0.070888125, "in_beam": true, "at_home": true}
	await frames()
	check(d.get_node_or_null("Loop_home_beacon_rx") == null and d.get_node_or_null("Loop_home_beacon") == null, "S2: at home (the boost out of Sol) the beacon is silent: the link is live")
	vs.world.earth.at_home = false
	await frames()
	var brx: Node = d.get_node_or_null("Loop_home_beacon_rx")
	check(brx is AudioStreamPlayer3D and brx.playing and brx.stream is AudioStreamGenerator and brx.pitch_scale == 1.0 and ss.beacon._rate == 0.070888125 and brx.bus == &"Instruments" and (brx as AudioStreamPlayer3D).global_position.is_equal_approx(Vector3(0, 1, -7)), "S2 Receiver: in Earth's beam, outbound at D = 0.070888125, the beacon plays at the helm, generated at the true 400 Hz with Earth's keying at D exactly")
	ship.consoles.focused = "comms"
	st.feed.set_receiver(true)
	ev.rate = 0.070888125
	st.refresh({"earth": ev, "clock": {"t": 1.0, "tau": 0.5}})
	await frames()
	var rx2 := AudioServer.get_bus_index("Receiver")
	var rshift := SoundMix._find_effect(rx2, "AudioEffectPitchShift") as AudioEffectPitchShift
	check(is_equal_approx(rshift.pitch_scale, 1.0 / 0.070888125) and brx.playing and brx.bus != &"Receiver", "S2: with the comms station open too, its bed is corrected on the Receiver bus (1/D) while the beacon, off that bus, needs no shift")
	await create_timer(0.2).timeout
	var pos_rx: float = ss.beacon._pos
	st.feed.set_receiver(false)
	await frames()
	var b1: Node = d.get_node_or_null("Loop_home_beacon")
	check(b1 != null and b1.playing and absf(b1.pitch_scale / 0.070888125 - 1.0) < 1e-6 and not brx.playing, "S2 True (the station's setting): the 400 Hz carrier at D, uncorrected (heard at 28.4 Hz; pitch_scale in float32 within 1e-6); the Receiver stops at once")
	check(absf(b1.get_playback_position() - pos_rx) < 0.05, "S2: True takes over at the Receiver's place in Earth's clock (%.3f s vs %.3f s into the loop)" % [b1.get_playback_position(), pos_rx])
	vs.world.earth.rate = 60.0
	await frames()
	check(d.fading("home_beacon") or not b1.playing, "S2 True at D = 60: above human hearing, the beacon falls silent")
	st.feed.set_receiver(true)
	ship.consoles.focused = ""
	vs.world.earth.rate = 14.107
	await frames()
	check(brx.playing and ss.beacon._rate == 14.107 and ss.beacon.cue == "home_beacon_rx", "S2 Receiver homebound at D = 14.107: Earth's keying at 14.107, still at 400 Hz")
	var before := d.log_text().count(" home_beacon_rx ")
	for r: float in [0.5, 0.75, 2.0]: # three accepted steps inside one frame (the game can batch journey ticks)
		vs.world.earth.rate = r
		vs.world.tick += 1
		vs.stepped.emit([])
	var tail := d.log_text()
	check(tail.count(" home_beacon_rx ") - before == 3 and tail.contains(" home_beacon_rx 0.5000\n") and tail.contains(" home_beacon_rx 0.7500\n") and tail.contains(" home_beacon_rx 2.0000\n"), "S2: the beacon follows every accepted step, not just the frame's last (D 0.5, 0.75 and 2 batched in one frame: three rate lines)")
	vs.world.earth.in_beam = false
	await frames()
	check(d.fading("home_beacon_rx"), "S2: out of Earth's beam (off-plan, or Earth silent) the beacon fades out")
	ship.journey_sim = null
	for id: String in d.cues: # silence the S2 tails (the beacon's 1.5 s fade) before the pan is measured
		d.stop(id, true)

	# AC10: left on screen is left in the ears; turned to Astern it is on the right.
	var cap := AudioEffectCapture.new()
	cap.buffer_length = 1.0
	AudioServer.add_bus_effect(0, cap, 0)
	d.on_game("level_none")
	var tone := AudioStreamPlayer3D.new()
	tone.stream = _tone()
	tone.bus = &"UI" # no reverb: the bridge's long tail would smear the pan between the two measurements
	tone.unit_size = 3.0
	ship.add_child(tone)
	var pans := []
	for yaw in [0.0, PI]:
		cam.global_basis = Basis(Vector3.UP, yaw)
		await frames(3)
		await create_timer(0.2).timeout # 3D panning is computed on physics frames
		tone.global_position = Vector3(-4, 1.6, 0) # world -x: screen left when the camera looks along -z
		tone.play()
		await frames(3)
		cap.clear_buffer()
		await create_timer(0.4).timeout
		var buf := cap.get_buffer(cap.get_frames_available())
		var l := 0.0
		var r := 0.0
		for f in buf:
			l += f.x * f.x
			r += f.y * f.y
		pans.append([l, r])
		tone.stop()
	check(pans[0][0] > 2.0 * pans[0][1], "AC10 Bow: a sound on the screen's left is louder in the left ear (L/R %.1f)" % (pans[0][0] / maxf(pans[0][1], 1e-9)))
	check(pans[1][1] > 2.0 * pans[1][0], "AC10 Astern: the same sound is now on the right (R/L %.1f)" % (pans[1][1] / maxf(pans[1][0], 1e-9)))
	print("ship-sound: %d passed, %d failures" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _tone() -> AudioStreamWAV:
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = 48000
	var n := 48000
	var b := PackedByteArray()
	b.resize(n * 2)
	for i in n:
		b.encode_s16(i * 2, int(12000.0 * sin(TAU * 500.0 * i / 48000.0)))
	s.data = b
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_end = n
	return s
