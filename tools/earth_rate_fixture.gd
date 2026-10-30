extends SceneTree
## R3-EARTH-LINK EL5 (gate 2): records the real sim's earth.rate at two cruising moments into
## tests/fixtures/earth/earth_rates.json, which tests/test_physics.gd asserts against the spec:
##   astern   leaving Earth for Alpha Centauri at 0.99c, Sol straight astern     RS-26 0.070888
##   ahead    flying home from Alpha Centauri at 0.99c, Sol straight ahead       RS-29 14.107
## Each row keeps the sim's own fields (rate, rate_inverse, cruise phi, ship.pos, the phase), so the
## test checks the sim, not this tool. Regenerate: make earth-rate-fixture (review the diff).

const OUT := "res://tests/fixtures/earth/earth_rates.json"
const ALPHA := {"index": 1, "id": "CNS5:3627", "pos": {"x": 3.094521, "y": -3.015404, "z": -0.051608}}
const SOL := {"index": 0, "id": "Sol", "pos": {"x": 0.0, "y": 0.0, "z": 0.0}}
const PHI := 2.6466524123622457 # atanh(0.99)

var sim: SimBridge


func _initialize() -> void:
	_run.call_deferred()


func journey() -> Dictionary:
	return sim.world.get("journey", {})


func fly(t: Dictionary) -> bool:
	return sim.send([{"k": "plan", "target": t, "cruise_phi": PHI}], 0.0) and sim.send([{"k": "commit", "plan_id": int(journey().plan_id)}], 0.0)


func until(pred: Callable) -> bool:
	for i in 20000:
		if pred.call():
			return true
		if not sim.send([], 0.02):
			return false
	return pred.call()


func row(label: String) -> Dictionary:
	var e: Dictionary = sim.world.earth
	return {"label": label, "tick": sim.world.tick, "t": sim.world.clock.t, "phase": sim.world.ship.phase, "pos": sim.world.ship.pos,
		"cruise_phi": PHI, "cruise_beta": journey().plan.get("cruise_beta"), "rate": e.rate, "rate_inverse": e.rate_inverse, "in_beam": e.in_beam}


func _run() -> void:
	sim = SimBridge.new()
	sim.want_minor = SimBridge.EARTH_MINOR
	var ok := sim.start() and sim.new_game(7, "free_nav", false)
	var rows := []
	ok = ok and fly(ALPHA) and until(func() -> bool: return sim.world.ship.phase == "cruising")
	if ok: rows.append(row("astern"))
	ok = ok and until(func() -> bool: return str(journey().get("state")) == "arrived") and fly(SOL) and until(func() -> bool: return sim.world.ship.phase == "cruising")
	if ok: rows.append(row("ahead"))
	sim.stop()
	if not ok or rows.size() != 2:
		print("earth-rate-fixture: FAIL %s %s" % [sim.last_error, sim.last_refused])
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.get_base_dir()))
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(JSON.stringify({"about": "R3-EARTH-LINK EL5: the real sim's earth.rate at 0.99c, Sol astern and ahead (seed 7, free_nav, protocol 2.16); written by tools/earth_rate_fixture.gd", "rows": rows}, " ", false) + "\n")
	f.close()
	print("earth-rate-fixture: %d rows -> %s" % [rows.size(), OUT])
	quit(0)
