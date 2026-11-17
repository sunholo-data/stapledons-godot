extends SceneTree
class Launcher extends "res://main.gd":
	func _ready() -> void: pass
var passed := 0
var failures := 0
func check(label: String, ok: bool) -> void:
	if ok: passed += 1
	else: failures += 1; printerr("FAIL ", label)
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var path := "res://demos/ship_review_readiness.gd"
	check("shared readiness helper exists", FileAccess.file_exists(path))
	if not FileAccess.file_exists(path): _finish(); return
	var ready = load(path)
	var missing := Node.new(); root.add_child(missing)
	check("missing install state refused", not (await ready.wait(missing, 5)).ok)
	missing.set_meta("painted_levels_pending", true)
	check("stalled install times out", not (await ready.wait(missing, 5)).ok)
	missing.set_meta("painted_levels_pending", false)
	missing.set_meta("painted_levels_result", {"ok":false,"errors":["failed install"]})
	check("installer failure refused", not (await ready.wait(missing, 5)).ok)
	missing.set_meta("painted_levels_result", {"ok":true})
	check("incomplete closure refused", not (await ready.wait(missing, 5)).ok)
	missing.free()
	var main := Launcher.new()
	# Invoke the real startup coroutine without main's _ready developer routing.
	main.set_process(false)
	root.add_child(main)
	main._start_current_ship(false, {"size":Vector2i(1280,720),"stars":false,"background":false,"sound":false,"sky_state":"rest","settings_dir":"res://.godot/tmp/ship-finish-ready"})
	var demo: Node = current_scene
	var result: Dictionary = await ready.wait(demo, 30000)
	check("actual normal entry ready", result.ok)
	if result.ok:
		check("installed production counts", result.identity.counts == {"bridge":141,"commons":1000,"residents":42})
		check("captain stage and manifest pinned", result.identity.captain_stage == demo.avatar.stage and result.identity.manifest_hashes.has("res://assets/characters/captain/manifest.json"))
		check("wrong expected hash refused", not ready.matches(result.identity, {"manifest_hashes":{"res://assets/characters/captain/manifest.json":"wrong"}}))
		check("same receipt matches", ready.matches(result.identity, result.identity))
		check("source is not a packed archive", not result.identity.packed)
		check("copied runtime stamp cannot identify source build", result.identity.build == "unexported (source checkout)")
		demo.set_meta("painted_levels_pending", true)
		check("pending marker overrides old result", not (await ready.wait(demo, 5)).ok)
		demo.set_meta("painted_levels_pending", false)
		demo.get_meta("painted_levels_result").bridge.changes[0].node.mesh = demo.get_meta("painted_levels_result").bridge.changes[0].original_mesh
		check("restored source cannot claim painted readiness", not (await ready.wait(demo, 5)).ok)
	demo.queue_free(); await process_frame
	_finish()
func _finish() -> void:
	print("ship-review-readiness: %d passed, %d failures" % [passed, failures])
	quit(0 if failures == 0 else 1)
