extends SceneTree
## R2-SOUND S1 (design §D4, §D5; AC3, AC10): the bridge's sound through ShipSound on a mock ship:
## the level's loops at the mast, footsteps from CA0's foot_down, console wake/sleep at the station,
## key presses, the lift's start/run/arrive riding with the platform, the bridge's room, Memory Health
## from the journey session, and the listener: a sound left on screen is left in the ears in Bow and
## right when the view turns to Astern (captured through the real mixer, headless).
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
