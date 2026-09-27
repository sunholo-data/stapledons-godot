extends SceneTree
## Integration test: spawn the AILANG sim over the NDJSON bridge and check it
## against closed-form constant-acceleration kinematics.
## Run:  godot --headless --path . --script tests/test_sim_bridge.gd

const A := 1.032295 # 1 g in c/yr, must match sim/ship.ail gAccel()

var failures := 0


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
	print("sim bridge: %d failures" % failures)
	quit(1 if failures > 0 else 0)
