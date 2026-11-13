extends SceneTree

const Index = preload("res://ui/observation_index.gd")
var passed := 0
var failed := 0

func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else:
		failed += 1
		printerr("FAIL ", label)

func reversed_keys(value: Variant) -> Variant:
	if value is Dictionary:
		var result := {}
		var keys: Array = value.keys()
		keys.reverse()
		for key in keys: result[key] = reversed_keys(value[key])
		return result
	if value is Array:
		var result: Array = []
		for child in value: result.append(reversed_keys(child))
		return result
	return value

func _init() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Index.OBJECTS_PATH))
	var pack: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Index.MANIFEST_PATH))
	var index: Variant = Index.new()
	check(index.set_data(data, pack), "actual source objects and manifest validate")
	for bad_id in ["", "   ", 123, null]:
		var invalid: Dictionary = pack.duplicate(true)
		invalid.id = bad_id
		check(not index.set_data(data, invalid), "empty/non-string pack identity rejected")
	check(index.has_method("pin") and index.has_method("snapshot"), "content pin and isolated snapshot APIs exist")
	if not index.has_method("pin") or not index.has_method("snapshot"):
		finish()
		return
	check(index.set_data(data, pack), "reload valid fixture")
	var original_pin: Dictionary = index.pin()
	var hex := RegEx.new()
	hex.compile("^[0-9a-f]{64}$")
	check(original_pin.get("id") == pack.id and hex.search(original_pin.get("manifest_sha256", "")) != null and hex.search(original_pin.get("objects_sha256", "")) != null, "pin includes ID and two SHA256 digests")
	var same: Variant = Index.new()
	check(same.set_data(reversed_keys(data), reversed_keys(pack)) and same.pin() == original_pin, "canonical hashing independent of nested dictionary key order")
	var changed_pack: Dictionary = pack.duplicate(true)
	changed_pack["pin_test_note"] = "same ID, changed source manifest"
	check(same.set_data(data, changed_pack) and same.pin().id == original_pin.id and same.pin().manifest_sha256 != original_pin.manifest_sha256 and same.pin().objects_sha256 == original_pin.objects_sha256, "same ID different manifest has different content pin")
	var changed_data: Dictionary = data.duplicate(true)
	changed_data.objects[0].name += " changed"
	check(same.set_data(changed_data, pack) and same.pin().objects_sha256 != original_pin.objects_sha256 and same.pin().manifest_sha256 == original_pin.manifest_sha256, "same ID different object bytes have different content pin")
	changed_data["pin_precision"] = 1.0000000000000002
	check(same.set_data(changed_data, pack), "first precise input accepted")
	var precise_pin: Dictionary = same.pin()
	changed_data.pin_precision = 1.0000000000000004
	check(same.set_data(changed_data, pack) and same.pin().objects_sha256 != precise_pin.objects_sha256, "hash retains full float64 precision")
	var id: String = data.objects[0].id
	var original_name: String = data.objects[0].name
	var input_data: Dictionary = data.duplicate(true)
	var input_pack: Dictionary = pack.duplicate(true)
	check(index.set_data(input_data, input_pack), "independent input fixture loaded")
	input_data.objects[0].name = "mutated caller input"
	input_pack.plates[0].name = "mutated caller input"
	check(index.object(id).name == original_name and index.pin() == original_pin, "caller input mutation cannot change loaded records or pin")
	index.objects[id].name = "mutated public index"
	index.objects[id].facts.ra_deg.value = -100.0
	index.manifest.plates[0].name = "mutated public manifest"
	index.plates[index.manifest.plates[0].id].name = "mutated public plates"
	var snapshot: Variant = index.snapshot()
	check(snapshot != null and snapshot.pin() == original_pin, "snapshot preserves original content pin")
	if snapshot != null:
		check(snapshot.object(id).name == original_name and snapshot.object(id).facts.ra_deg.value == data.objects[0].ra_deg and snapshot.manifest.plates[0].name == pack.plates[0].name, "snapshot rebuilds private originals, not externally mutable public data")
		snapshot.objects[id].name = "mutated first snapshot"
		snapshot.manifest.plates[0].name = "mutated first snapshot"
		var second: Variant = index.snapshot()
		check(second.object(id).name == original_name and second.manifest.plates[0].name == pack.plates[0].name and index.objects[id].name == "mutated public index", "snapshots and original share no nested record dictionaries")
	index.version = "tampered"
	check(index.pin().is_empty() and index.snapshot() == null, "manual version tampering invalidates pin and snapshot")
	check(index.load_files(), "actual source files load")
	var actual_pin: Dictionary = index.pin()
	check(actual_pin.manifest_sha256 == FileAccess.get_sha256(Index.MANIFEST_PATH) and actual_pin.objects_sha256 == FileAccess.get_sha256(Index.OBJECTS_PATH), "file pins use exact actual file bytes")
	var actual_snapshot: Variant = index.snapshot()
	check(actual_snapshot != null and actual_snapshot.pin() == actual_pin, "file snapshot retains byte hashes rather than reserialized hashes")
	var prefix := "/tmp/observation-pin-%d" % OS.get_process_id()
	var object_file := FileAccess.open(prefix + "-objects.json", FileAccess.WRITE)
	object_file.store_string("\n" + JSON.stringify(reversed_keys(data), "  ", false, true) + "\n")
	object_file.close()
	var manifest_file := FileAccess.open(prefix + "-manifest.json", FileAccess.WRITE)
	manifest_file.store_string("\n" + JSON.stringify(reversed_keys(pack), "  ", false, true) + "\n")
	manifest_file.close()
	check(index.load_files(prefix + "-objects.json", prefix + "-manifest.json"), "noncanonical whitespace/key-order files load")
	check(index.pin().objects_sha256 == FileAccess.get_sha256(prefix + "-objects.json") and index.pin().objects_sha256 != original_pin.objects_sha256, "file byte identity differs from canonical set_data identity")
	check(index.snapshot().pin() == index.pin(), "noncanonical file byte pin survives snapshot")
	DirAccess.remove_absolute(prefix + "-objects.json")
	DirAccess.remove_absolute(prefix + "-manifest.json")
	var inconsistent: Dictionary = data.duplicate(true)
	inconsistent.objects[0].distance_ly = 123.0
	check(not index.set_data(inconsistent, pack), "unavailable distance cannot conflict with flat source field")
	check(index.pin().is_empty(), "failed load clears previous pin")
	finish()

func finish() -> void:
	print("observation-pin-test: %d passed, %d failures" % [passed, failed])
	quit(1 if failed else 0)
