extends SceneTree
var checks := 0
var failures := 0
var index := 0
func check(label: String, ok: bool) -> void:
	checks += 1
	if not ok: failures += 1; printerr("FAIL ", label)
func _initialize() -> void:
	var audit: Variant = load("res://tests/content_export_audit.gd")
	if audit == null: check("pack auditor exists", false); finish(); return
	var contents := {}
	var records := []
	for path: String in ["assets/characters/npcs/reader_front.png.bin", "data/crew/portraits/medic_neutral.png.bin", "assets/levels/painted/bridge/floor_atlas.res", "assets/levels/painted/bridge/paint.res", "assets/levels/painted/bridge/compiled/000.res", "assets/levels/painted/bridge/manifest.json"]:
		var bytes := ("independent fixture: " + path).to_utf8_buffer()
		contents[path] = bytes
		records.append({"path": "res://" + path, "sha256": sha(bytes), "bytes": bytes.size(), "raw": true})
	check("complete raw pack passes", run_case(audit, contents, records).is_empty())
	for path: String in contents:
		var missing := contents.duplicate(); missing.erase(path)
		check("missing closure member " + path, run_case(audit, missing, records).has("missing_packed: res://" + path))
	var wrong := contents.duplicate(); wrong[contents.keys()[0]] = "corrupt".to_utf8_buffer()
	check("corrupt raw bytes rejected", run_case(audit, wrong, records).has("packed_pin: res://" + contents.keys()[0]))
	for path: String in ["art/content-pipeline/catalog.json", "art/environment-painted-pilot/source.res", "art/npc-painted-v1/sources/person.png", "art/captain-anim-v4/guide.json"]:
		var leaked := contents.duplicate(); leaked[path] = "leaked".to_utf8_buffer()
		check("authoring leak rejected " + path, run_case(audit, leaked, records).has("authoring_leak: " + path))
	var remapped := {"assets/characters/captain/avatar.png.remap": '[remap]\npath="res://.godot/imported/avatar.ctex"\n'.to_utf8_buffer(), ".godot/imported/avatar.ctex": "imported fixture".to_utf8_buffer()}
	var imported := [{"path": "res://assets/characters/captain/avatar.png", "sha256": "original-source", "bytes": 0, "raw": false, "imported_path": "res://.godot/imported/avatar.ctex", "imported_sha256": sha(remapped[".godot/imported/avatar.ctex"])}]
	check("known imported representation passes", run_case(audit, remapped, imported).is_empty())
	# Captured Godot 4.7.2 texture-export structure: .import, not a script/scene .remap.
	# Godot's packed metadata ends in a NUL byte; preserve that observed detail.
	var metadata := '[remap]\n\nimporter="texture"\ntype="CompressedTexture2D"\nuid="uid://c6g5q7tx7tfx4"\npath="res://.godot/imported/avatar.ctex"\nmetadata={\n"vram_texture": false\n}\n'.to_utf8_buffer()
	metadata.append(0)
	var texture_import := {"assets/characters/captain/avatar.png.import": metadata, ".godot/imported/avatar.ctex": remapped[".godot/imported/avatar.ctex"]}
	check("observed Godot texture .import representation passes", run_case(audit, texture_import, imported).is_empty())
	var import_missing := texture_import.duplicate(); import_missing.erase(".godot/imported/avatar.ctex")
	check("observed .import still requires texture bytes", run_case(audit, import_missing, imported).has("missing_imported: res://assets/characters/captain/avatar.png"))
	var import_wrong := texture_import.duplicate(); import_wrong[".godot/imported/avatar.ctex"] = "wrong imported bytes".to_utf8_buffer()
	check("observed .import rejects corrupt texture bytes", run_case(audit, import_wrong, imported).has("imported_pin: res://assets/characters/captain/avatar.png"))
	var wrong_importer := texture_import.duplicate()
	wrong_importer["assets/characters/captain/avatar.png.import"] = metadata.get_string_from_utf8().replace('importer="texture"', 'importer="keep"').to_utf8_buffer()
	check("observed .import requires the real texture importer", run_case(audit, wrong_importer, imported).has("invalid_import: res://assets/characters/captain/avatar.png"))
	var shadowed := import_wrong.duplicate()
	var source_bytes := "valid raw source must not hide invalid imported texture".to_utf8_buffer()
	shadowed["assets/characters/captain/avatar.png"] = source_bytes
	var shadow_records := imported.duplicate(true); shadow_records[0].sha256 = sha(source_bytes); shadow_records[0].bytes = source_bytes.size()
	check("raw source cannot hide changed active import", run_case(audit, shadowed, shadow_records).has("imported_pin: res://assets/characters/captain/avatar.png"))
	var broken := remapped.duplicate(); broken.erase(".godot/imported/avatar.ctex")
	check("missing imported texture fails", run_case(audit, broken, imported).has("missing_imported: res://assets/characters/captain/avatar.png"))
	broken = remapped.duplicate(); broken[".godot/imported/avatar.ctex"] = "changed".to_utf8_buffer()
	check("changed imported texture fails", run_case(audit, broken, imported).has("imported_pin: res://assets/characters/captain/avatar.png"))
	broken = remapped.duplicate(); broken["assets/characters/captain/avatar.png.remap"] = '[remap]\npath="res://art/wrong.ctex"\n'.to_utf8_buffer()
	check("wrong remap target fails", run_case(audit, broken, imported).has("imported_path: res://assets/characters/captain/avatar.png"))
	var missing_witness := imported.duplicate(true); missing_witness[0].erase("imported_sha256")
	check("missing import witness fails closed", not run_case(audit, remapped, missing_witness).is_empty())
	var export_rules := preload("res://tests/export_audit.gd")
	var filters: Dictionary = export_rules.read_filters()
	check("painted dynamic roots classified", export_rules.audit(filters.include, filters.exclude).is_empty())
	var missing_filter: PackedStringArray = filters.include.duplicate()
	missing_filter.remove_at(missing_filter.find("assets/levels/*"))
	var problems: Array[String] = export_rules.audit(missing_filter, filters.exclude)
	check("missing native include fails painted witness", problems.any(func(e: String) -> bool: return "assets/levels/painted/bridge/floor_atlas.res" in e))
	finish()
func sha(bytes: PackedByteArray) -> String:
	var hash := HashingContext.new(); hash.start(HashingContext.HASH_SHA256); hash.update(bytes); return hash.finish().hex_encode()
func run_case(audit: Variant, contents: Dictionary, records: Array) -> PackedStringArray:
	index += 1
	var path := "res://.godot/tmp/content-pack-%d.zip" % index
	var writer := ZIPPacker.new(); writer.open(path)
	for file: String in contents: writer.start_file(file); writer.write_file(contents[file]); writer.close_file()
	writer.close()
	var reader := ZIPReader.new(); reader.open(path)
	var errors: PackedStringArray = audit.audit_records(reader, records)
	reader.close(); return errors
func finish() -> void:
	print("content-pack: %d passed, %d failures" % [checks - failures, failures]); quit(1 if failures else 0)
