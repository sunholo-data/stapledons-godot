extends RefCounted
## Offline production-scene review. Native timings are collected only on the attended machine.
const Ready := preload("res://demos/ship_review_readiness.gd")
const Benchmark := preload("res://demos/ship_demo_benchmark.gd")
const Bridge := preload("res://demos/bridge_painted_finish.gd")
const Commons := preload("res://demos/commons_painted_finish.gd")
const PHASES := ["docked_bridge", "commons_court", "commons_terrace", "commons_gantry", "lift", "seated", "live_transit"]

func run(launcher: Node, output: String) -> Dictionary:
	if DisplayServer.get_name() == "headless": return {"ok":false,"errors":["headless performance measurement refused"]}
	if not output.is_absolute_path() or output.begins_with("res://") or output.begins_with("user://"):
		return {"ok":false,"errors":["absolute local output directory required"]}
	if DirAccess.make_dir_recursive_absolute(output) != OK: return {"ok":false,"errors":["output directory unavailable"]}
	var bench := Benchmark.new()
	var report := {"schema":"stapledons.ship-finish-review/1","evidence":"native","local_only":true,"native":true,"target_measurement_pending":true,"seed":424242,"conditions":[],"hardware":Benchmark.hardware(),"resolution":[],"identity":{}}
	var errors: Array[String] = []
	for condition in ["original", "painted"]:
		var started := Time.get_ticks_msec()
		await launcher._start_current_ship(false, {"review_keep_launcher":true,"size":Vector2i(1920,1080),"seed":424242,"ai":false,"sound":false,"sky_state":"rest","crew":"orders","record":output.path_join(condition+"-session.ndjson"),"settings_dir":output.path_join(condition+"-settings")})
		var demo: Node = launcher.get_tree().current_scene
		var ready := await Ready.wait(demo)
		if not ready.ok: errors.append_array(ready.errors); demo.queue_free(); break
		if report.identity.is_empty(): report.identity = ready.identity
		elif not Ready.matches(ready.identity, report.identity): errors.append("condition build/closure changed")
		demo.get_window().size = Vector2i(1920,1080); demo._resize()
		report.resolution = [demo.get_window().size.x, demo.get_window().size.y]
		demo.auto = false; demo.journey_auto_tick = false
		demo.set_camera_motion("full") # Disposable review session; reduced-motion appearance is a separate manual row.
		var installed: Dictionary = demo.get_meta("painted_levels_result")
		Bridge.set_enabled(installed.bridge, condition == "painted")
		Commons.set_enabled(installed.commons, condition == "painted")
		var row := {"material":condition,"identity":ready.identity,"normal_entry_ready_ms":Time.get_ticks_msec()-started,"phases":[],"restored":false}
		for phase: String in PHASES:
			var phase_result := await _phase(demo, bench, phase, 300)
			if not phase_result.ok: errors.append_array(phase_result.errors); break
			var sample: Dictionary = phase_result.sample
			sample.repeats = []
			if sample.frame_times.p99_ms > 16.7:
				for repeat_index in 2:
					var repeated := await _phase(demo, bench, phase, 1500)
					if not repeated.ok: errors.append_array(repeated.errors); break
					sample.repeats.append(repeated.sample)
			row.phases.append(sample)
			if not errors.is_empty(): break
		Bridge.set_enabled(installed.bridge, true); Commons.set_enabled(installed.commons, true)
		row.restored = Ready.inspect(demo).ok
		report.conditions.append(row)
		if demo.journey_sim != null: demo.journey_sim.stop()
		demo.queue_free(); await launcher.get_tree().process_frame
		if not errors.is_empty(): break
	var validation := report_errors(report)
	errors.append_array(validation)
	report["validity"] = {"valid":errors.is_empty(),"errors":errors}
	report["acceptance"] = "pending laptop identity confirmation and Mark's native review"
	if not bench.save_report(report, output.path_join("report.json"), true): errors.append("report write failed")
	return {"ok":errors.is_empty(),"errors":errors,"report":report}

func _phase(demo: Node, bench: RefCounted, phase: String, count: int) -> Dictionary:
	if not phase in PHASES: return _failed("unknown review phase")
	if demo.seated():
		demo.stand_chair()
		if not await _until(demo, func() -> bool: return not demo.seated(), 5000): return _failed("chair stand timed out")
	if demo.journey_sim != null: demo._drop_navigation()
	demo.live_journey = false; demo.journey_auto_tick = false; demo.set_preset("reset")
	demo.auto = phase == "lift" # The normal controller advances lift motion only while presentation auto is enabled.
	var inputs := []
	if phase.begins_with("commons_"):
		var stage_id := phase.trim_prefix("commons_")
		for stage: Dictionary in demo.level_runtime.layout.stages:
			if stage.id == stage_id:
				var p: Array = stage.spawn
				demo.active_level = 1; demo.walk = demo.walk_lower
				demo.avatar_pos = Vector3(p[0],p[2],-p[1]); demo.director.default_view()
		inputs.append({"authored_stage":stage_id,"spawn":[demo.avatar_pos.x,demo.avatar_pos.y,demo.avatar_pos.z]})
	elif phase == "lift":
		demo.avatar_pos = Vector3(8,82,-4.8)
		if not demo.lift.board(): return _failed("lift did not board")
		inputs.append({"board_lift":true})
	elif phase == "seated":
		if not demo.sit_chair(): return _failed("chair did not sit")
		if not await _until(demo, func() -> bool: return demo.consoles.command.visible, 5000): return _failed("chair command did not open")
		if not demo.consoles.command.select_system("overview"): return _failed("seated console selection failed")
		inputs.append({"sit":true,"select_system":"overview"})
	elif phase == "live_transit":
		if not demo.consoles.walk_to("navigation"): return _failed("navigation route refused")
		if not await _until(demo, func() -> bool: return demo.consoles.walking.is_empty(), 30000): return _failed("navigation walk timed out")
		for action in [["open",null],["select","CNS5:3627"],["commit",null]]:
			if not demo.consoles.use("navigation", action[0], action[1]): return _failed("navigation action refused: " + action[0])
			inputs.append({"console":"navigation","action":action[0],"value":action[1]})
		if not demo.journey_tick() or not demo.live_journey: return _failed("real departure not committed")
		demo.journey_auto_tick = true
	var warmup := 0 if phase == "lift" else 120
	var before := snapshot(demo, phase)
	var sample: Dictionary = await bench.measure_view(demo, phase, count, warmup)
	sample.before = before; sample.after = snapshot(demo, phase)
	sample.camera = {"eye":sample.eye_gltf_m,"direction":sample.view_direction}
	sample.inputs = inputs; sample.warmup_frames = warmup
	if phase == "live_transit" and (not demo.live_journey or sample.after.tick <= before.tick): return _failed("transit did not advance while committed")
	if phase == "lift" and sample.after.lift_y == before.lift_y: return _failed("lift did not move")
	return {"ok":true,"errors":[],"sample":sample}

static func snapshot(demo: Node, phase: String) -> Dictionary:
	return {"phase":phase,"stage":demo.active_stage_id(),"tick":demo.journey_sim.world.tick if demo.journey_sim != null else demo.sky_world.tick,"ship_phase":str(demo.sky_world.ship.phase),"clock":demo.sky_world.get("clock",{}).duplicate(true),"lift_state":demo.lift.state,"lift_y":demo.lift.platform.position.y,"seated":demo.seated()}

static func _until(demo: Node, predicate: Callable, milliseconds: int) -> bool:
	var deadline := Time.get_ticks_msec() + milliseconds
	while not predicate.call():
		if Time.get_ticks_msec() >= deadline: return false
		await demo.get_tree().process_frame
	return true

static func _failed(reason: String) -> Dictionary:
	return {"ok":false,"errors":[reason]}

static func report_errors(report: Dictionary, require_packed := true, allow_fixture := false) -> Array[String]:
	var errors: Array[String] = []
	if report.get("schema") != "stapledons.ship-finish-review/1" or report.get("local_only") != true or report.get("native") != true:
		errors.append("native local report schema required")
	if report.get("evidence") != "native" and not allow_fixture: errors.append("fixtures are not native evidence")
	if report.get("target_measurement_pending") != true: errors.append("target confirmation is a separate attended review")
	if not report.get("identity", {}) is Dictionary: return errors + ["identity must be an object"]
	var identity: Dictionary = report.get("identity", {})
	if require_packed and identity.get("packed") != true: errors.append("packed archive identity required")
	if str(identity.get("build", "")).is_empty() or str(identity.get("build", "")).begins_with("unexported"): errors.append("archive build pin missing")
	for file: String in Ready.MANIFESTS:
		if identity.get("manifest_hashes", {}).get(file) != FileAccess.get_sha256(file): errors.append("stale manifest: " + file)
	if not identity.get("counts") is Dictionary or not Ready.matches(identity.counts, {"bridge":141,"commons":1000,"residents":42}): errors.append("production counts differ")
	if not report.get("hardware", {}) is Dictionary: return errors + ["hardware must be an object"]
	var hardware: Dictionary = report.get("hardware", {})
	for key in ["model", "gpu", "driver", "vsync"]:
		if not hardware.has(key): errors.append("missing hardware: " + key)
	for key in ["model", "gpu"]:
		if str(hardware.get(key, "")) in ["", "unavailable"]: errors.append("unidentified hardware: " + key)
	if hardware.get("driver", "") in ["", "dummy"]: errors.append("native renderer required")
	var resolution: Variant = report.get("resolution")
	if not resolution is Array or resolution.size() != 2: errors.append("review size missing")
	elif float(resolution[0]) != 1920. or float(resolution[1]) != 1080.: errors.append("review size differs")
	if float(report.get("seed", -1)) != 424242.: errors.append("review seed differs")
	var conditions: Variant = report.get("conditions")
	if not conditions is Array or conditions.size() != 2: return errors + ["both material conditions required"]
	var seen := []
	for condition_value: Variant in conditions:
		if not condition_value is Dictionary: errors.append("condition must be an object"); continue
		var condition: Dictionary = condition_value
		seen.append(condition.get("material"))
		if not condition.get("identity", {}) is Dictionary or not Ready.matches(condition.get("identity", {}), identity): errors.append("mixed condition identity")
		if condition.get("restored") != true: errors.append("materials not restored")
		var phases: Variant = condition.get("phases")
		if not phases is Array: errors.append("missing phases"); continue
		var names := []
		for sample_value: Variant in phases:
			if not sample_value is Dictionary: errors.append("sample must be an object"); continue
			var sample: Dictionary = sample_value
			var name: String = sample.get("view", "")
			names.append(name); errors.append_array(_phase_errors(sample, name, 300))
			if float(sample.get("frame_times", {}).get("p99_ms", 0.)) > 16.7:
				if not sample.get("repeats", []) is Array: errors.append("repeats must be an array"); continue
				var repeats: Array = sample.get("repeats", [])
				if repeats.size() != 2: errors.append("miss requires two longer repeats")
				for repeated: Variant in repeats:
					if not repeated is Dictionary: errors.append("repeat must be an object")
					else: errors.append_array(_phase_errors(repeated, name, 1500))
		if names != PHASES: errors.append("required phase sequence differs")
	if seen != ["original", "painted"]: errors.append("material condition sequence differs")
	return errors

static func _phase_errors(sample: Dictionary, name: String, minimum: int) -> Array[String]:
	var errors := Benchmark.sample_errors(sample, minimum)
	if sample.get("view") != name or not sample.get("camera") is Dictionary or not sample.get("inputs") is Array:
		errors.append("phase/camera/input metadata missing")
	if not sample.get("before", {}) is Dictionary or not sample.get("after", {}) is Dictionary: return errors + ["phase snapshots must be objects"]
	var before: Dictionary = sample.get("before", {}); var after: Dictionary = sample.get("after", {})
	if before.get("phase") != name or after.get("phase") != name: errors.append("phase snapshot differs")
	if name == "live_transit" and int(after.get("tick", -1)) <= int(before.get("tick", -1)): errors.append("no real transit advance")
	if name == "lift" and after.get("lift_y") == before.get("lift_y"): errors.append("no lift movement evidence")
	if name == "seated" and before.get("seated") != true: errors.append("chair was not seated")
	if name != "lift" and int(sample.get("warmup_frames", 0)) < 120: errors.append("static warmup missing")
	return errors
