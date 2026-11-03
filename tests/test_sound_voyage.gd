extends SceneTree
## R2-SOUND S2 (design_docs/planned/r2/sound.md §D6, §D9; AC2, AC4, AC15): a real voyage's cue log. The
## scripted flight of ui/transit_harness.gd (dock, plan Alpha Cen A, commit, boost, cruise, brake, arrive)
## on the real sim at protocol 2.16, heard through ShipSound itself (on a stand-in ship, tests/fixtures/sound/
## mock_ship.gd): every accepted step's events, state edges, drawn grains and Earth's rate, with many steps
## inside one frame as in the game. The log must equal
## tests/fixtures/sound/cue_log_voyage.txt byte for byte (make sound-voyage-test also runs it in two
## separate processes and compares them).
## Run: AILANG_BIN=$(command -v ailang) godot --headless --path . --script tests/test_sound_voyage.gd
##        [-- --log-out=<file>] [-- --write]   (--write re-records the fixture; review its diff)
const FIXTURE := "res://tests/fixtures/sound/cue_log_voyage.txt"
const MockShip := preload("res://tests/fixtures/sound/mock_ship.gd")
var failed := 0
var passed := 0


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


func lines_with(log: PackedStringArray, id: String) -> Array:
	var out := []
	for i in log.size():
		if log[i].contains(" " + id + " ") or log[i].ends_with(" " + id):
			out.append(i)
	return out


func _run() -> void:
	var sim := SimBridge.new()
	sim.want_minor = SimBridge.EARTH_MINOR
	if not sim.start() or not sim.new_game(0, "sol", false, {}):
		check(false, "the sim starts at 2.16 (%s)" % sim.last_error)
		quit(1)
		return
	# The live path: ShipSound on a stand-in ship whose journey session is the real sim, exactly as the game
	# attaches it. The harness flies synchronously, so many accepted steps land inside one frame.
	var ship: Node3D = MockShip.new()
	root.add_child(ship)
	var ss := ShipSound.new().attach(ship)
	ship.add_child(ss)
	await process_frame
	await process_frame
	var d: SoundDirector = ss.sound
	d.audible = false
	check(d.errors.is_empty(), "the shipped sound tables validate")
	ship.journey_sim = sim
	await process_frame # ShipSound connects to the session's stepped signal
	var beacon: HomeBeacon = ss.beacon
	var rates := []
	sim.stepped.connect(func(_events: Array) -> void: # after ShipSound's own handler (connection order)
		if beacon.on:
			rates.append([int(sim.world.get("tick", 0)), float(sim.world.earth.rate), float(d.pitches.get(beacon.cue, -1.0))]))
	var h := TransitHarness.new()
	root.add_child(h)
	h.attach(sim)
	var res: Dictionary = h.run_session()
	sim.stop()
	check(res.ok and res.events.has("arrived"), "the scripted flight reaches Alpha Cen A (%d ticks)" % res.ticks)
	var log := d.cue_log
	var text := d.log_text()
	var seal := lines_with(log, "commit_seal")
	var plan := lines_with(log, "plan_select")
	check(plan.size() == 1 and seal.size() == 1 and plan[0] < seal[0], "AC4: one plan_select when the sim plots Alpha Cen A, then one commit_seal on its `committed`")
	var order := ["commit_seal", "drive_boost", "drive_silent", "drive_brake", "arrived"]
	var at := -1
	var ordered := true
	for id: String in order:
		var l := lines_with(log, id)
		ordered = ordered and l.size() == 1 and l[0] > at
		at = l[0] if l.size() == 1 else at
	check(ordered, "AC4: seal, boost, the drive falling silent, brake and arrival, once each and in order")
	var first_beacon := -1
	for i in log.size():
		if log[i].contains(" home_beacon"):
			first_beacon = i
			break
	check(first_beacon > lines_with(log, "drive_silent")[0] and log[first_beacon].contains("home_beacon_rx"), "AC15: the beacon starts once the ship has left home (cruise, earth.at_home false), in Earth's beam, in the Receiver setting (generated at 400 Hz): %s" % (log[first_beacon] if first_beacon >= 0 else "none"))
	var exact := not rates.is_empty()
	for r: Array in rates:
		exact = exact and r[2] == r[1] # the director's rate is the sim's earth.rate, unrounded
	check(exact, "AC15: on each of %d beacon steps its rate is the sim's earth.rate exactly (from %.6f to %.6f)" % [rates.size(), rates[0][1] if exact else 0.0, rates[-1][1] if exact else 0.0])
	var fires := 0
	for l in log:
		if l.contains(" home_beacon"):
			fires += 1 if l.contains(" v0 ") else 0
	check(fires == 1 and not text.contains(" home_beacon v0"), "AC15: braking into Alpha Cen A, D rises from 0.0709 to 1 and the Receiver beacon follows it on one generated row, with no hand-over (%d starts)" % fires)
	check(rates[-1][1] == 1.0 and text.contains(" home_beacon_rx 1.0000\n"), "AC15: at the stop Earth's rate is 1 and the beacon is at its true pitch")
	var ticks := 0
	for l in log:
		if l.contains(" dust_tick v"):
			ticks += 1
	check(ticks > 100 and lines_with(log, "dust_tick").all(func(i: int) -> bool: return i < lines_with(log, "arrived")[0]), "AC4: the counter ticks for the drawn grains in flight (%d) and none at rest" % ticks)
	var args := _args()
	if args.has("log-out"):
		var f := FileAccess.open(args["log-out"], FileAccess.WRITE)
		f.store_string(text)
		f.close()
	if args.has("write"):
		var f := FileAccess.open(FIXTURE, FileAccess.WRITE)
		f.store_string(text)
		f.close()
		print("sound-voyage: wrote %s (%d lines)" % [FIXTURE, log.size()])
	var want := FileAccess.get_file_as_string(FIXTURE)
	check(want == text, "AC2: the voyage's cue log equals %s byte for byte (%d lines)" % [FIXTURE, log.size()])
	print("sound-voyage: %d passed, %d failures" % [passed, failed])
	quit(1 if failed > 0 else 0)
