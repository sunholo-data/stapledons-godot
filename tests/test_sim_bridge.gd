extends SceneTree
## Integration test: spawn the AILANG sim over the NDJSON bridge and check it
## against closed-form constant-acceleration kinematics.
## Run:  godot --headless --path . --script tests/test_sim_bridge.gd

const A := 1.032295275553596 # 1 g in c/yr, sunholo/relativity standardGravity()

var failures := 0

func assert_bool(name: String, ok: bool) -> void:
	if not ok: failures += 1
	print("  %s  %s" % ["ok  " if ok else "FAIL", name])

func fake(mode: String) -> SimBridge:
	var s := SimBridge.new()
	s.launch_override = {"bin": "python3", "args": PackedStringArray([ProjectSettings.globalize_path("res://tests/fixtures/fake_sim.py"), mode])}
	return s

func state_without_status(s: Dictionary) -> String:
	var copy := s.duplicate(true)
	copy.erase("status")
	copy.erase("proto")
	return JSON.stringify(copy)

func child_gone(pid: int) -> bool:
	return OS.execute("/bin/kill", PackedStringArray(["-0", str(pid)]), []) != 0

func test_v11_hello_and_round_trip() -> void:
	var s := SimBridge.new()
	assert_bool("v1.1 hello", s.start() and s.state.get("proto") == "1.1")
	var heading := {"x": 0.6, "y": 0.8, "z": 0.0}
	assert_bool("turn and echo heading", s.step(0.0, 0.0, heading))
	assert_bool("heading float64 round trip", s.state["heading"]["x"] == 0.6 and s.state["heading"]["y"] == 0.8)
	assert_bool("echo heading on next step", s.step(1.0, 0.01, s.state["heading"]))
	assert_bool("off-axis position", s.state["pos"]["x"] > 0.0 and s.state["pos"]["y"] > 0.0)
	s.stop()

func raw_reply(s: SimBridge, line: String) -> bool:
	s._pipe.store_line(line)
	s._pipe.flush()
	return s._read_state(Time.get_ticks_msec() + 2000, "step_timeout")

func test_reason_codes_and_state_identity() -> void:
	var s := SimBridge.new()
	assert_bool("reason-code sim starts", s.start())
	var cases := [
		["{broken", "bad_json"],
		['{"cmd":"step","thrust":NaN}', "bad_json"],
		['{"cmd":"warp"}', "bad_cmd"],
		['{"cmd":"step","dtau":-1,"heading":{"x":1}}', "bad_step"],
		['{"cmd":"step","heading":{"x":1,"y":0}}', "bad_heading"],
		['{"cmd":"step","heading":{"x":1.00000001,"y":0,"z":0}}', "bad_heading"],
		['{"cmd":"step","heading":{"x":1e400,"y":0,"z":0}}', "bad_heading"],
	]
	for item in cases:
		var before := state_without_status(s.state)
		var ok := raw_reply(s, item[0])
		assert_bool("reject %s exact state" % item[1], ok and s.state.get("status") == item[1] and state_without_status(s.state) == before)
	assert_bool("malformed line does not end loop", s.step(1.0, 1.0))
	var before := state_without_status(s.state)
	var ok := raw_reply(s, '{"cmd":"step","heading":{"x":1,"y":0,"z":0}}')
	assert_bool("moving exact state", ok and s.state.get("status") == "moving" and state_without_status(s.state) == before)
	s.stop()

func test_startup_timeout() -> void:
	var s := fake("silent_start")
	var t := Time.get_ticks_msec()
	var ok := s.start()
	assert_bool("startup_timeout code and bound", not ok and s.last_error == "startup_timeout" and Time.get_ticks_msec() - t < 6500)
	assert_bool("startup timeout has no substitute state", s.state.is_empty())
	assert_bool("startup child cleaned", child_gone(s.child_pid))

func test_step_timeout(mode: String = "silent_step") -> void:
	var s := fake(mode)
	assert_bool("fake child starts", s.start())
	var before := state_without_status(s.state)
	var t := Time.get_ticks_msec()
	var ok := s.step(0.0, 0.01)
	assert_bool("step_timeout code and bound " + mode, not ok and s.last_error == "step_timeout" and Time.get_ticks_msec() - t < 3500)
	assert_bool("timeout preserves state " + mode, state_without_status(s.state) == before and s.state.get("status") == "step_timeout")
	assert_bool("child cleaned " + mode, child_gone(s.child_pid))

func test_truncated_line_timeout() -> void:
	test_step_timeout("truncated")

func test_forced_child_cleanup() -> void:
	test_step_timeout("ignore_quit")

func test_old_proto_rejected() -> void:
	var s := fake("old_proto")
	assert_bool("old protocol refused", not s.start() and s.last_error == "bad_proto")
	assert_bool("old protocol child cleaned", child_gone(s.child_pid))


func check(name: String, got: float, want: float, tol: float) -> void:
	var ok := absf(got - want) <= tol * maxf(1.0, absf(want))
	if not ok: failures += 1
	print("  %s  %-44s got %.12f want %.12f" % ["ok  " if ok else "FAIL", name, got, want])


func _init() -> void:
	var sim := SimBridge.new()
	if not sim.start():
		quit(2)
		return
	check("initial beta", sim.state["beta"], 0.0, 0.0)
	var t0 := Time.get_ticks_usec()
	for i in 200: # 2 ship-years at 1 g
		sim.step(1.0, 0.01)
	var per_tick_us := (Time.get_ticks_usec() - t0) / 200.0
	var phi := A * 2.0
	check("beta after 2 ship-yr = tanh(2a)", sim.state["beta"], tanh(phi), 1e-12)
	check("gamma = cosh(2a)", sim.state["gamma"], cosh(phi), 1e-12)
	check("Earth time = sinh(2a)/a", sim.state["t"], sinh(phi) / A, 1e-12)
	check("distance = (cosh(2a) - 1)/a", sim.state["x"], (cosh(phi) - 1.0) / A, 1e-12)
	for i in 200: # decelerate back to rest
		sim.step(-1.0, 0.01)
	check("symmetric burn returns to rest", sim.state["beta"], 0.0, 1e-12)
	check("Earth time for 4 ship-yr round burn", sim.state["t"], 2.0 * sinh(phi) / A, 1e-12)
	for i in 100: # coast at rest
		sim.step(0.0, 0.01)
	check("coasting at rest: Earth time advances 1:1", sim.state["t"], 2.0 * sinh(phi) / A + 1.0, 1e-12)
	print("  round trip per tick: %.0f us" % per_tick_us)
	sim.stop()
	test_v11_hello_and_round_trip()
	test_reason_codes_and_state_identity()
	test_old_proto_rejected()
	test_startup_timeout()
	test_step_timeout()
	test_truncated_line_timeout()
	test_forced_child_cleanup()
	print("sim bridge: %d failures" % failures)
	quit(1 if failures > 0 else 0)
