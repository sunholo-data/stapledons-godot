extends RefCounted
## Inspect the actual pack's JSON dependency graph, which the .gd literal scanner cannot follow.
static func audit(zip: ZIPReader) -> Array[String]:
	var errors: Array[String] = []
	var views := _json(zip, "data/camera/views.json", errors)
	if views.get("schema") != "stapledons.camera.views/3":
		if views.get("schema") != "stapledons.camera.views/2": errors.append("invalid packed camera schema")
		return errors
	var index := _json(zip, str(views.get("level_manifest_index", "")), errors)
	if index.get("schema") != "stapledons.level.index/1" or not index.get("levels") is Dictionary:
		errors.append("invalid packed level index")
		return errors
	for id: String in index.levels:
		var source: Variant = index.levels[id]
		if source is Dictionary and source.get("legacy", false): continue
		if not source is String:
			errors.append("invalid packed manifest reference: " + id)
			continue
		var manifest := _json(zip, source, errors)
		if manifest.get("schema") != "stapledons.level/1" or manifest.get("id") != id:
			errors.append("invalid packed level manifest: " + id)
		if manifest.has("layout_asset"):
			var layout := _json(zip, str(manifest.layout_asset), errors)
			if layout.get("schema") != "stapledons.level/1" or layout.get("id") != id:
				errors.append("invalid packed greybox: " + id)
	var lift := _json(zip, "assets/levels/lift.json", errors)
	if lift.get("schema") != "stapledons.lift/1": errors.append("invalid packed lift stops")
	return errors

static func _json(zip: ZIPReader, path: String, errors: Array[String]) -> Dictionary:
	var name := path.trim_prefix("res://")
	if name.is_empty() or name.begins_with("/") or name.contains("..") or not name.ends_with(".json") or not zip.file_exists(name):
		errors.append("missing or unsafe packed level document: " + path)
		return {}
	var value: Variant = JSON.parse_string(zip.read_file(name).get_string_from_utf8())
	if not value is Dictionary:
		errors.append("invalid JSON object in pack: " + path)
		return {}
	return value
