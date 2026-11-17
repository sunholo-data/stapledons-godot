extends RefCounted
## External audit of a pack; does not run inside the shipped game or require shipped authoring inputs.
const C := preload("res://tools/content_contract.gd")
const AUTHORING := ["art/content-pipeline/", "art/environment-painted-pilot/", "art/npc-painted-v1/", "art/captain-anim-"]

static func sha(bytes: PackedByteArray) -> String:
	var hash := HashingContext.new(); hash.start(HashingContext.HASH_SHA256); hash.update(bytes); return hash.finish().hex_encode()

static func audit(zip: ZIPReader) -> PackedStringArray:
	var catalog := C.doc(C.CATALOG)
	var errors := C.catalog_errors(catalog)
	var records := {}
	for entry: Dictionary in catalog.get("bundles", []):
		var state := C.check_entry(entry, "runtime")
		errors.append_array(state.errors)
		for row: Dictionary in state.records:
			var record := row.duplicate()
			# Raw FileAccess witnesses must never be substituted with an imported texture.
			if not row.raw and row.path.get_extension() in ["png", "webp"]:
				var config := ConfigFile.new()
				if config.load(row.path + ".import") == OK and config.get_value("remap", "importer", "") != "keep":
					var imported: String = str(config.get_value("remap", "path", ""))
					if imported.begins_with("res://.godot/imported/") and FileAccess.file_exists(imported):
						record.imported_path = imported; record.imported_sha256 = FileAccess.get_sha256(imported)
			records[row.path] = record
	errors.append_array(audit_records(zip, records.values()))
	return errors

static func audit_records(zip: ZIPReader, records: Array) -> PackedStringArray:
	var errors := PackedStringArray()
	for name: String in zip.get_files():
		if AUTHORING.any(func(prefix: String) -> bool: return name.begins_with(prefix)):
			errors.append("authoring_leak: " + name)
	for row: Dictionary in records:
		var path: String = row.path
		var name := path.trim_prefix("res://")
		var metadata := name + ".import" if zip.file_exists(name + ".import") else (name + ".remap" if zip.file_exists(name + ".remap") else "")
		if bool(row.get("raw", false)) or metadata.is_empty():
			if not zip.file_exists(name): errors.append("missing_packed: " + path); continue
			var bytes: PackedByteArray = zip.read_file(name)
			if sha(bytes) != row.sha256 or bytes.size() != int(row.bytes): errors.append("packed_pin: " + path)
			continue
		var config := ConfigFile.new()
		if config.parse(zip.read_file(metadata).get_string_from_utf8()) != OK:
			errors.append("invalid_remap: " + path); continue
		if metadata.ends_with(".import") and (config.get_value("remap", "importer", "") != "texture" or config.get_value("remap", "type", "") != "CompressedTexture2D"):
			errors.append("invalid_import: " + path); continue
		var target: String = str(config.get_value("remap", "path", ""))
		if not target.begins_with("res://.godot/imported/") or target != row.get("imported_path", ""):
			errors.append("imported_path: " + path); continue
		if not zip.file_exists(target.trim_prefix("res://")):
			errors.append("missing_imported: " + path); continue
		if sha(zip.read_file(target.trim_prefix("res://"))) != row.get("imported_sha256", ""):
			errors.append("imported_pin: " + path)
	return errors
