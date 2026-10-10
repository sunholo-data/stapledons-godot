extends SceneTree
## AC19: time warm bytecode-service NDJSON requests, excluding bootstrap costs.
## I/O uses the shipped evaluator bridge; pure core is checked strictly separately.
## The same actual route and real-time ticks are paired with uniform physics.
const PLAN := {"k": "plan", "target": {"index": 2, "id": "CNS5:1142",
	"pos": {"x": -62.516711, "y": -1.060038, "z": -23.064639}},
	"cruise_phi": 3.8002011672502}
const REALTIME := 0.05 / 31557600.0
var failed := false
var bridges: Array[SimBridge] = []

func _initialize() -> void:
	_run.call_deferred()

func _request(s: SimBridge, intents: Array, dtau: float) -> float:
	var start := Time.get_ticks_usec()
	if not s.send(intents, dtau) or not s.last_refused.is_empty():
		push_error("ISM benchmark request failed: %s %s" % [s.last_error, s.last_refused])
		failed = true
		for bridge in bridges: bridge.stop()
		quit(1)
	return float(Time.get_ticks_usec() - start) / 1000.0

func _median(values: Array) -> float:
	var sorted := values.duplicate()
	sorted.sort()
	return float(sorted[sorted.size() / 2])

func _phase_batch(sims: Array[SimBridge], phase: String) -> Dictionary:
	for model in 2:
		var s := sims[model]
		if not s.new_game(7, "sol", false, {"ism_model": model}):
			push_error("ISM benchmark reset failed")
			failed = true
			return {}
		_request(s, [PLAN], 0.0)
		var p: Dictionary = s.world.journey.plan
		var burn: float = p.boost_minutes * 60.0 / 31557600.0
		_request(s, [{"k": "commit", "plan_id": s.world.journey.plan_id}], 0.0)
		var remaining: float = burn * 0.5 if phase == "boosting" else p.ship_years - burn * 0.5
		while remaining > 0.0:
			var step: float = minf(remaining, 1.0)
			_request(s, [], step)
			if failed: return {}
			remaining -= step
		for warmup in 40:
			_request(s, [], REALTIME)
			if failed: return {}
	var times := [[], []]
	var deltas: Array = []
	for round in 7:
		var pair := [0.0, 0.0]
		for model in ([0, 1] if round % 2 == 0 else [1, 0]):
			var s := sims[model]
			var before: float = s.world.ship.gamma
			for sample in 200:
				pair[model] += _request(s, [], REALTIME) / 200.0
				if failed: return {}
			if s.world.ship.phase != phase or (phase == "boosting" and s.world.ship.gamma <= before) or (phase == "braking" and s.world.ship.gamma >= before):
				push_error("ISM benchmark did not remain in " + phase)
				failed = true
				return {}
			times[model].append(pair[model])
		deltas.append(pair[1] - pair[0])
	return {"uniform_ms": times[0], "lism_ms": times[1], "delta_ms": deltas, "delta_median_ms": _median(deltas)}

func _run() -> void:
	var sims: Array[SimBridge] = []
	var path := ProjectSettings.globalize_path("res://sim")
	for model in [0, 1]:
		var s := SimBridge.new()
		bridges.append(s)
		s.want_minor = SimBridge.ISM_MINOR
		s.launch_override = {"bin": SimBridge.find_ailang(), "args": PackedStringArray([
			"run", "--quiet", "--bytecode", "--package-dir", path,
			"--caps", "IO", "--entry", "main", path.path_join("ship.ail")])}
		if not s.start() or not s.new_game(7, "sol", false, {"ism_model": model}):
			push_error("ISM benchmark bootstrap failed: " + s.last_error)
			for bridge in bridges: bridge.stop()
			quit(1)
			return
		sims.append(s)
	var plans := [[], []]
	var plan_delta: Array = []
	for round in 55:
		var pair := [0.0, 0.0]
		for model in ([0, 1] if round % 2 == 0 else [1, 0]):
			pair[model] = _request(sims[model], [PLAN], 0.0)
			if failed: return
		if round >= 5:
			for model in 2: plans[model].append(pair[model])
			plan_delta.append(pair[1] - pair[0])
	for s in sims:
		_request(s, [{"k": "commit", "plan_id": s.world.journey.plan_id}], 0.0)
		_request(s, [], 0.00001)
		for warmup in 40: _request(s, [], REALTIME)
		if failed: return
	var ticks := [[], []]
	var tick_delta: Array = []
	for round in 7:
		var pair := [0.0, 0.0]
		for model in ([0, 1] if round % 2 == 0 else [1, 0]):
			for sample in 200:
				pair[model] += _request(sims[model], [], REALTIME) / 200.0
				if failed: return
			ticks[model].append(pair[model])
		tick_delta.append(pair[1] - pair[0])
	var report := {"method": "Warm bytecode service as shipped (I/O interop); alternate paired order; bootstrap excluded; includes bridge/JSON overhead",
		"plan_pairs": 50, "tick_pairs": 7, "ticks_per_pair": 200,
		"plan_uniform_median_ms": _median(plans[0]), "plan_lism_median_ms": _median(plans[1]),
		"plan_delta_ms": plan_delta, "plan_delta_median_ms": _median(plan_delta),
		"tick_uniform_ms": ticks[0], "tick_lism_ms": ticks[1],
		"tick_delta_ms": tick_delta, "tick_delta_median_ms": _median(tick_delta)}
	report.boost = _phase_batch(sims, "boosting")
	print("ism-boost-bench: ", JSON.stringify(report.boost))
	if failed:
		for s in sims: s.stop()
		quit(1)
		return
	report.brake = _phase_batch(sims, "braking")
	print("ism-brake-bench: ", JSON.stringify(report.brake))
	if failed:
		for s in sims: s.stop()
		quit(1)
		return
	report.passes = report.plan_delta_median_ms <= 20.0 and report.tick_delta_median_ms <= 0.5 and report.boost.delta_median_ms <= 0.5 and report.brake.delta_median_ms <= 0.5
	DirAccess.make_dir_recursive_absolute("res://.godot/tmp/ism")
	FileAccess.open("res://.godot/tmp/ism/service-benchmark.json", FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	print("ism-service-bench: ", JSON.stringify(report))
	for s in sims: s.stop()
	quit(0 if report.passes else 1)
