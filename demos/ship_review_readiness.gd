class_name ShipReviewReadiness
extends RefCounted
## Shared bounded observer of main's normal-entry civic/physics/paint installation.
## Presentation evidence only. It neither starts a sim nor substitutes a test installer.
const MANIFESTS := ["res://assets/levels/painted/bridge/manifest.json", "res://assets/levels/painted/commons/manifest.json", "res://assets/characters/npcs/manifest.json", "res://assets/characters/captain/manifest.json"]

static func wait(demo: Node, timeout_ms := 30000) -> Dictionary:
	var deadline := Time.get_ticks_msec() + maxi(0, timeout_ms)
	while is_instance_valid(demo) and demo.has_meta("painted_levels_pending") and demo.get_meta("painted_levels_pending"):
		if Time.get_ticks_msec() >= deadline: return _failure("painted installation timed out")
		if not demo.is_inside_tree(): return _failure("ship left the tree")
		await demo.get_tree().process_frame
	return inspect(demo)

static func inspect(demo: Node) -> Dictionary:
	if not is_instance_valid(demo) or not demo.has_meta("painted_levels_pending"):
		return _failure("normal-entry install marker missing")
	if demo.get_meta("painted_levels_pending"): return _failure("painted installation pending")
	var result: Dictionary = demo.get_meta("painted_levels_result", {})
	if not result.get("ok", false): return _failure("painted installation failed: " + str(result.get("errors", [])))
	for key in ["bridge", "commons", "people"]:
		if not result.get(key) is Dictionary: return _failure("missing production closure: " + key)
	var counts := {"bridge":result.bridge.get("changes", []).size(), "commons":result.commons.get("changes", []).size(), "residents":result.people.get("residents", []).size()}
	if counts != {"bridge":141,"commons":1000,"residents":42} or result.people.get("crew", []).size() != 2:
		return _failure("production counts differ")
	if demo.get("geometry") == null or not demo.geometry.has_meta("painted_levels_finish"):
		return _failure("production geometry marker missing")
	for deck in [result.bridge, result.commons]:
		for row: Dictionary in deck.changes:
			if not is_instance_valid(row.get("node")) or row.node.mesh != row.get("painted_mesh"):
				return _failure("painted resource is not installed")
	var hashes := {}
	for path: String in MANIFESTS:
		if not FileAccess.file_exists(path): return _failure("missing manifest: " + path)
		hashes[path] = FileAccess.get_sha256(path)
	var packed := not OS.has_feature("editor")
	var build := FileAccess.get_file_as_string("res://runtime/build_version.txt").strip_edges() if FileAccess.file_exists("res://runtime/build_version.txt") else "unexported (source checkout)"
	if packed and build.begins_with("unexported"): return _failure("packed build identity missing")
	return {"ok":true, "errors":[], "identity":{"build":build,"packed":packed,"counts":counts,"manifest_hashes":hashes,"captain_stage":demo.avatar.stage,"residents":"static painted poses; no crowd simulation"}}

static func matches(actual: Dictionary, expected: Dictionary) -> bool:
	for key in expected:
		if not actual.has(key): return false
		if expected[key] is Dictionary:
			if not actual[key] is Dictionary or not matches(actual[key], expected[key]): return false
		elif actual[key] != expected[key]: return false
	return true

static func _failure(reason: String) -> Dictionary:
	return {"ok":false,"errors":[reason],"identity":{}}
