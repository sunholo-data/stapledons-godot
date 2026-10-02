extends SceneTree
## Integration test: spawn the AILANG sim over the protocol v2 NDJSON bridge,
## check it against closed-form constant-acceleration kinematics, the float64
## round trip (AC9), the handshake, the mirrored world, the input recording and
## the failure paths (timeouts, cleanup).
## Run:  godot --headless --path . --script tests/test_sim_bridge.gd

const A := 1.032295275553596 # 1 g in c/yr, sunholo/relativity standardGravity()
const MAX_INT := 9007199254740991 # 2^53 - 1

var failures := 0
var scratch := ProjectSettings.globalize_path("res://.godot/tmp")

func assert_bool(name: String, ok: bool) -> void:
	if not ok: failures += 1
	print("  %s  %s" % ["ok  " if ok else "FAIL", name])

func fake(mode: String, dump: String = "") -> SimBridge:
	var s := SimBridge.new()
	var args := PackedStringArray([ProjectSettings.globalize_path("res://tests/fixtures/fake_sim.py"), mode])
	if dump != "":
		args.append(dump)
	s.launch_override = {"bin": "python3", "args": args}
	return s

func child_gone(pid: int) -> bool:
	return OS.execute("/bin/kill", PackedStringArray(["-0", str(pid)]), []) != 0

## Floats are built from their IEEE-754 bit patterns: the GDScript tokenizer
## misreads some literals (9007199254740991.0 parses as ...990, -0.0 as +0.0).
func f64(bits: int) -> float:
	var b := PackedByteArray()
	b.resize(8)
	b.encode_s64(0, bits)
	return b.decode_double(0)

func bits_of(x: Variant) -> int:
	if typeof(x) != TYPE_FLOAT:
		return 0x7ff8dead0000beef # never equal to a real pattern
	var b := PackedByteArray()
	b.resize(8)
	b.encode_double(0, x)
	return b.decode_s64(0)

func same(a: Variant, b: float) -> bool:
	return bits_of(a) == bits_of(b)

func vec(x: float, y: float, z: float) -> Dictionary:
	return {"x": x, "y": y, "z": z}

func diag_sim(record: String = "") -> SimBridge:
	var s := SimBridge.new()
	s.record_path = record
	if not s.start() or not s.new_game(7, "sol", true):
		assert_bool("diag session starts (%s)" % s.last_error, false)
	return s


func check(name: String, got: float, want: float, tol: float) -> void:
	var ok := absf(got - want) <= tol * maxf(1.0, absf(want))
	if not ok: failures += 1
	print("  %s  %-44s got %.12f want %.12f" % ["ok  " if ok else "FAIL", name, got, want])


func test_closed_form() -> bool:
	var sim := diag_sim()
	check("initial beta", sim.world["ship"]["beta"], 0.0, 0.0)
	var t0 := Time.get_ticks_usec()
	for i in 200: # 2 ship-years at 1 g
		sim.send([{"k": "thrust", "thrust": 1.0}], 0.01)
	var per_tick_us := (Time.get_ticks_usec() - t0) / 200.0
	var phi := A * 2.0
	check("beta after 2 ship-yr = tanh(2a)", sim.world["ship"]["beta"], tanh(phi), 1e-12)
	check("gamma = cosh(2a)", sim.world["ship"]["gamma"], cosh(phi), 1e-12)
	check("Earth time = sinh(2a)/a", sim.world["clock"]["t"], sinh(phi) / A, 1e-12)
	check("distance = (cosh(2a) - 1)/a", sim.world["ship"]["x"], (cosh(phi) - 1.0) / A, 1e-12)
	for i in 200: # decelerate back to rest
		sim.send([{"k": "thrust", "thrust": -1.0}], 0.01)
	check("symmetric burn returns to rest", sim.world["ship"]["beta"], 0.0, 1e-12)
	check("Earth time for 4 ship-yr round burn", sim.world["clock"]["t"], 2.0 * sinh(phi) / A, 1e-12)
	for i in 100: # coast at rest
		sim.send([], 0.01)
	check("coasting at rest: Earth time advances 1:1", sim.world["clock"]["t"], 2.0 * sinh(phi) / A + 1.0, 1e-12)
	assert_bool("world tick follows the sim", sim.world["tick"] == 500)
	print("  round trip per tick: %.0f us" % per_tick_us)
	sim.stop()
	return true


func test_v2_hello() -> bool:
	var s := SimBridge.new()
	var ok := s.start()
	var p: Dictionary = s.hello_reply.get("proto", {})
	assert_bool("v2 hello: proto 2.1 (AI.3), rng splitmix64-1", ok and p.get("major") == 2 and p.get("minor") == 1 and s.hello_reply.get("rng") == "splitmix64-1")
	s.stop()
	return true


## AC1 (AI.3): the bridge accepts any minor of major 2 (a 2.1 sim) and still
## refuses every other major, a 3.1 included.
func test_minor_accepted() -> bool:
	var s := fake("proto_21")
	var ok := s.start()
	var p: Dictionary = s.hello_reply.get("proto", {})
	assert_bool("accept proto 2.1 from a fake sim", ok and p.get("major") == 2 and p.get("minor") == 1)
	s.stop()
	return true


func test_major_refused() -> bool:
	for mode in ["proto_v1", "proto_v3", "proto_v31", "proto_frac", "proto_string", "v11"]:
		var s := fake(mode)
		assert_bool("refuse %s (bad_proto)" % mode, not s.start() and s.last_error == "bad_proto")
		assert_bool("refused %s child cleaned" % mode, child_gone(s.child_pid))
	return true


## AC9: every float the bridge sends comes back bit for bit. The diag `echo`
## hook returns a plan payload (target.pos, cruise_phi) until M2.3a's planner.
func test_float_echo() -> bool:
	var neg_zero := f64(-9223372036854775808)
	var almost_one := f64(0x3feffffffffffffe)
	var e308 := f64(0x7fe1ccf385ebc8a0)
	var phi_cap := f64(0x401d046eb8b8ab58)
	var cases := [
		["1e308, -0.0, 1-2^-52, phi cap", vec(e308, neg_zero, almost_one), phi_cap],
		["0.1, -4.09, 0.1+0.2, phi 0.1", vec(f64(0x3fb999999999999a), f64(-4607081087808401572), f64(0x3fd3333333333334)), f64(0x3fb999999999999a)],
		["-1e308, max double, 1, phi -0.0", vec(-e308, f64(0x7fefffffffffffff), 1.0), neg_zero],
	]
	var s := diag_sim()
	for c in cases:
		var pos: Dictionary = c[1]
		var ok := s.send([{"k": "echo", "target": {"index": MAX_INT, "id": "Gl 559", "pos": pos}, "cruise_phi": c[2]}], 0.0)
		var ev: Dictionary = s.last_events[0] if ok and s.last_events.size() == 1 else {}
		var t: Dictionary = ev.get("target", {})
		var p: Dictionary = t.get("pos", {})
		assert_bool("echo bit-exact: %s" % c[0], ev.get("k") == "echo" and same(p.get("x"), pos["x"]) and same(p.get("y"), pos["y"])
			and same(p.get("z"), pos["z"]) and same(ev.get("cruise_phi"), c[2]))
		assert_bool("echo index 2^53-1 exact, id intact: %s" % c[0], int(t.get("index", 0)) == MAX_INT and t.get("id") == "Gl 559")
	# Known divergence (Godot 4.7.2): String::to_float, used by JSON.parse_string,
	# returns 0.0 for |x| <= DBL_MIN, so subnormals and DBL_MIN cannot come back.
	# The sim received them exactly: its reply prints their shortest digits.
	var tiny := f64(1)
	var dbl_min := f64(0x0010000000000000)
	var ok := s.send([{"k": "echo", "target": {"index": 0, "id": "tiny", "pos": vec(tiny, dbl_min, 0.0)}, "cruise_phi": 0.1}], 0.0)
	assert_bool("sim receives 5e-324 and DBL_MIN exactly (reply text)", ok and s.last_line.contains('"x":5e-324') and s.last_line.contains('"y":2.2250738585072014e-308'))
	var got: Dictionary = s.last_events[0]["target"]["pos"] if ok else {}
	var godot_ok := same(got.get("x"), tiny) and same(got.get("y"), dbl_min)
	print("  info  Godot JSON parse of 5e-324 / DBL_MIN: %s" % ("exact (Godot fixed: drop the known-divergence note)" if godot_ok else "flushed to 0.0 (known-divergent, Godot bug)"))
	assert_bool("subnormal echo is exact or the documented Godot flush", godot_ok or (same(got.get("x"), 0.0) and same(got.get("y"), 0.0)))
	s.stop()
	var play := SimBridge.new()
	ok = play.start() and play.new_game(7, "sol", false)
	ok = ok and play.send([{"k": "echo", "target": {"index": 0, "id": "x", "pos": vec(0.0, 0.0, 0.0)}, "cruise_phi": 0.1}], 0.0)
	assert_bool("echo outside diag refused diag_only, tick proceeds", ok and play.world["tick"] == 1 and play.last_events.is_empty()
		and play.last_refused.size() == 1 and play.last_refused[0]["reason"] == "diag_only")
	play.stop()
	return true


func test_encode() -> bool:
	assert_bool("encode -0.0 keeps its sign", SimBridge.number(f64(-9223372036854775808)) == "-0.0" and SimBridge.number(0.0) == "0.0")
	assert_bool("encode shortest round trip", SimBridge.number(f64(0x3feffffffffffffe)) == "0.9999999999999998" and SimBridge.number(f64(0x3fb999999999999a)) == "0.1")
	assert_bool("encode keeps ints and key order", SimBridge.encode({"v": 2, "b": [1, 2.5, true, "x"], "a": null}) == '{"v":2,"b":[1,2.5,true,"x"],"a":null}')
	return true


func test_heading_round_trip() -> bool:
	var s := diag_sim()
	var heading := vec(f64(0x3fe3333333333333), f64(0x3fe999999999999a), 0.0) # 0.6, 0.8, 0
	assert_bool("turn accepted", s.send([{"k": "heading", "heading": heading}], 0.0) and s.last_refused.is_empty())
	var h: Dictionary = s.world["ship"]["heading"]
	assert_bool("heading float64 round trip", same(h["x"], heading["x"]) and same(h["y"], heading["y"]) and same(h["z"], 0.0))
	assert_bool("echo heading with thrust on next tick", s.send([{"k": "heading", "heading": h}, {"k": "thrust", "thrust": 1.0}], 0.01))
	assert_bool("off-axis position", s.world["ship"]["pos"]["x"] > 0.0 and s.world["ship"]["pos"]["y"] > 0.0)
	s.stop()
	return true


## A change-set replaces the sections it carries and keeps the rest.
func test_mirror_merges() -> bool:
	var s := diag_sim()
	var full := s.world.duplicate(true)
	var ok: bool = full.has("clock") and full.has("ship") and full.has("params") and s.state["full"] == true
	ok = ok and s.send([{"k": "heading", "heading": vec(1.0, 0.0, 0.0)}], 0.0)
	var partial: Dictionary = s.state["changes"]
	assert_bool("turn sends only the ship section", ok and partial.has("ship") and not partial.has("clock") and not partial.has("params"))
	assert_bool("mirror keeps clock and params, takes the new ship", JSON.stringify(s.world.get("clock")) == JSON.stringify(full["clock"])
		and JSON.stringify(s.world.get("params")) == JSON.stringify(full["params"]) and s.world["ship"]["heading"]["x"] == 1.0 and s.world["tick"] == 1)
	assert_bool("params echo the sol defaults", s.world.get("params", {}).get("boost_g") == 750000.0 and s.world.get("params", {}).get("cap_one_minus_beta") == 0.000001)
	s.stop()
	return true


## Malformed lines change nothing (child kept); refused intents proceed.
func test_malformed_and_refused() -> bool:
	var s := diag_sim()
	s.send([{"k": "thrust", "thrust": 1.0}], 0.5)
	for item in [[[{"k": "warp"}], 0.1, "bad_intent"], [[], 1.5, "bad_step"], [[{"k": "thrust", "thrust": 2.0}], 0.1, "bad_step"],
			[[{"k": "heading", "heading": {"x": 1.0, "y": 0.0}}], 0.1, "bad_heading"]]:
		var before := JSON.stringify(s.world)
		var ok := s.send(item[0], item[1])
		assert_bool("malformed %s: false, world unchanged, child alive" % item[2], not ok and s.last_error == item[2]
			and JSON.stringify(s.world) == before and OS.is_process_running(s.child_pid))
	var ok := s.send([{"k": "heading", "heading": vec(1.0, 0.0, 0.0)}], 0.1)
	assert_bool("refused moving: tick proceeds", ok and s.world["tick"] == 2 and s.last_refused.size() == 1 and s.last_refused[0]["reason"] == "moving")
	s.stop()
	var play := SimBridge.new()
	ok = play.start() and play.new_game(7, "sol", false)
	ok = ok and play.send([{"k": "thrust", "thrust": 1.0}], 0.5)
	assert_bool("thrust outside diag refused diag_only", ok and play.last_refused[0]["reason"] == "diag_only" and play.world["ship"]["beta"] == 0.0)
	assert_bool("bad scenario refused bad_game", not play.new_game(1, "andromeda") and play.last_error == "bad_game")
	play.stop()
	return true


## The bridge never sends an input before new_game (the sim would answer tick 0).
func test_no_input_before_new_game() -> bool:
	var rec := scratch.path_join("bridge_no_game.ndjson")
	var s := SimBridge.new()
	s.record_path = rec
	var started := s.start()
	var sent := s.send([], 0.1)
	s.stop()
	var lines := FileAccess.get_file_as_string(rec).split("\n", false)
	assert_bool("send before new_game: false, no_game, nothing written", started and not sent and s.last_error == "no_game"
		and lines.size() == 2 and lines[0].contains('"type":"hello"') and lines[1] == '{"v":2,"type":"quit"}')
	return true


## record_path tees every stdin line byte for byte (cmp against what the child read).
## The comparison happens while the child is alive and has answered every
## line: the fake flushes its dump before it replies, so the dump is complete
## with no race. (Comparing after stop() raced the child's read of `quit`
## against the bridge's 1 s kill under load; M2.5.) The quit line is then
## checked on the tee alone: whether the child read it is not a tee property.
func test_record_tee() -> bool:
	var rec := scratch.path_join("bridge_tee.ndjson")
	var dump := scratch.path_join("bridge_tee_child.ndjson")
	var s := fake("ok", dump)
	s.record_path = rec
	var ok := s.start() and s.new_game(MAX_INT, "sol", true, {"epoch": f64(-9223372036854775808)})
	ok = ok and s.send([{"k": "thrust", "thrust": 1.0}], 0.1) and s.send([{"k": "echo", "target": {"index": 1, "id": "Proxima \"Cen\" ☉", "pos": vec(0.1, -0.0, 1e300)}, "cruise_phi": 2.6}], 0.0)
	var a := FileAccess.get_file_as_bytes(rec)
	var b := FileAccess.get_file_as_bytes(dump)
	assert_bool("tee == bytes the child read (%d bytes, 4 answered lines)" % a.size(), ok and a.size() > 0 and a == b and a.get_string_from_utf8().split("\n", false).size() == 4)
	s.stop()
	var after := FileAccess.get_file_as_bytes(rec)
	var quit_line := '{"v":2,"type":"quit"}\n'.to_utf8_buffer()
	assert_bool("tee ends with the quit line after stop", after.size() == a.size() + quit_line.size() and after.slice(a.size()) == quit_line)
	return true


## The recorded log replays the session headless: same reply lines, byte for byte.
func test_record_replays() -> bool:
	var rec := scratch.path_join("bridge_replay.ndjson")
	var s := diag_sim(rec)
	var replies := PackedStringArray(["", s.last_line]) # [0]: the hello reply, checked by prefix below
	s.send([{"k": "heading", "heading": vec(0.0, 1.0, 0.0)}], 0.0)
	replies.append(s.last_line)
	for i in 5:
		s.send([{"k": "thrust", "thrust": 1.0}], 0.1)
		replies.append(s.last_line)
	s.send([{"k": "warp"}], 0.1)
	replies.append(s.last_line)
	s.stop()
	var out := []
	var cmd := "'%s' run --quiet --bytecode --package-dir '%s' --caps IO --entry main '%s' < '%s'" % [SimBridge.find_ailang(),
		ProjectSettings.globalize_path("res://sim"), ProjectSettings.globalize_path("res://sim/ship.ail"), rec]
	OS.execute("/bin/sh", PackedStringArray(["-c", cmd]), out)
	var lines: PackedStringArray = (out[0] as String).strip_edges().split("\n")
	var ok := lines.size() == replies.size() and lines[0].begins_with('{"v":2,"type":"hello"')
	for i in range(1, mini(lines.size(), replies.size())):
		ok = ok and lines[i] == replies[i]
	assert_bool("recorded input log replays to identical state lines (%d lines)" % lines.size(), ok)
	return true


func test_startup_timeout() -> bool:
	var s := fake("silent_start")
	var t := Time.get_ticks_msec()
	var ok := s.start()
	assert_bool("startup_timeout code and bound", not ok and s.last_error == "startup_timeout" and Time.get_ticks_msec() - t < 6500)
	assert_bool("startup timeout has no substitute state", s.world.is_empty())
	assert_bool("startup child cleaned", child_gone(s.child_pid))
	return true

func test_step_timeout(mode: String = "silent_step") -> bool:
	var s := fake(mode)
	assert_bool("fake child starts " + mode, s.start() and s.new_game(1))
	var before := s.world.duplicate(true)
	var t := Time.get_ticks_msec()
	var ok := s.send([], 0.01)
	assert_bool("step_timeout code and bound " + mode, not ok and s.last_error == "step_timeout" and Time.get_ticks_msec() - t < 3500)
	var after := s.world.duplicate(true)
	after.erase("status")
	before.erase("status")
	assert_bool("timeout preserves world " + mode, JSON.stringify(after) == JSON.stringify(before) and s.world.get("status") == "step_timeout")
	assert_bool("child cleaned " + mode, child_gone(s.child_pid))
	return true

func test_truncated_line_timeout() -> bool:
	return test_step_timeout("truncated")

func test_forced_child_cleanup() -> bool:
	return test_step_timeout("ignore_quit")

func test_wrong_tick_reply() -> bool:
	var s := fake("skip_tick")
	var ok := s.start() and s.new_game(1)
	assert_bool("reply with wrong tick: bad_response, world kept", ok and not s.send([], 0.01) and s.last_error == "bad_response" and s.world["tick"] == 0)
	assert_bool("wrong tick child cleaned", child_gone(s.child_pid))
	return true


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(scratch)
	var probe := SimBridge.new()
	if not probe.start():
		print("sim does not start")
		quit(2)
		return
	probe.stop()
	var tests: Array[Callable] = [
		test_closed_form,
		test_v2_hello,
		test_minor_accepted,
		test_major_refused,
		test_encode,
		test_float_echo,
		test_heading_round_trip,
		test_mirror_merges,
		test_malformed_and_refused,
		test_no_input_before_new_game,
		test_record_tee,
		test_record_replays,
		test_startup_timeout,
		test_step_timeout,
		test_truncated_line_timeout,
		test_forced_child_cleanup,
		test_wrong_tick_reply,
	]
	for t in tests:
		# a GDScript runtime error aborts the function and returns null: count it
		if t.call() != true:
			assert_bool("%s ran to completion" % t.get_method(), false)
	print("sim bridge: %d failures" % failures)
	quit(1 if failures > 0 else 0)
