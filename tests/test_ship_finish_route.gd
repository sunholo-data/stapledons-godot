extends SceneTree
const Ready := preload("res://demos/ship_review_readiness.gd")
class Launcher extends "res://main.gd":
	func _ready() -> void: pass
class FixtureSampler extends RefCounted:
	func measure_view(demo: Node, name: String, count := 3, _warmup := 120) -> Dictionary:
		# Qualify real phase wiring, never claim native frame times from Dummy/headless.
		for i in 40: demo._process(.05)
		await demo.get_tree().process_frame
		var eye: Vector3 = demo.camera.position
		return {"view":name,"fixture":true,"requested_samples":count,"eye_gltf_m":[eye.x,eye.y,eye.z],"view_direction":[0.,0.,-1.]}
var passed := 0
var failures := 0
func check(label: String, ok: bool) -> void:
	if ok: passed += 1
	else: failures += 1; printerr("FAIL ", label)
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var launcher := Launcher.new(); root.add_child(launcher)
	await launcher._start_current_ship(false, {"review_keep_launcher":true,"stars":false,"background":false,"sound":false,"ai":false,"crew":"orders","seed":424242,"sky_state":"rest","settings_dir":"res://.godot/tmp/ship-route-fixture"})
	var demo: Node = current_scene
	check("actual normal-entry production ready", (await Ready.wait(demo)).ok)
	demo.auto = false; demo.journey_auto_tick = false
	var route = load("res://tools/ship_finish_review.gd").new()
	var sampler := FixtureSampler.new()
	for phase in ["docked_bridge","commons_court","commons_terrace","commons_gantry","lift","seated"]:
		var result: Dictionary = await route._phase(demo, sampler, phase, 3)
		check("real phase prepares: " + phase, result.ok)
		if not result.ok: printerr(result.errors)
		if result.ok:
			check("fixture-labelled camera/input metadata: " + phase, result.sample.fixture and result.sample.camera.has("eye") and result.sample.has("inputs"))
			if phase.begins_with("commons_"): check("authored stage selected: " + phase, result.sample.before.stage == phase.trim_prefix("commons_"))
	check("unknown phase refused", not (await route._phase(demo, sampler, "absent", 3)).ok)
	if OS.get_cmdline_user_args().has("--live"):
		var transit: Dictionary = await route._phase(demo, sampler, "live_transit", 3)
		check("real committed transit advances", transit.ok)
	if demo.journey_sim != null: demo.journey_sim.stop()
	demo.queue_free(); launcher.queue_free(); await process_frame
	print("ship-finish-route: %d passed, %d failures (headless wiring fixture; no native timings)" % [passed,failures])
	quit(0 if failures == 0 else 1)
