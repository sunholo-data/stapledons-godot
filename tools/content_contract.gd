extends RefCounted
## Offline evidence only. Existing type loaders remain the runtime authority.
const CATALOG := "res://art/content-pipeline/catalog.json"
const KINDS := ["captain", "npc", "painted_deck"]
const BUNDLE_IDS := ["captain", "painted-npcs", "painted-bridge", "painted-commons"]
const RUNTIME_ROOTS := ["assets/", "data/", "shaders/", "interior/", "ship_demo_bundle/", "ship_commons_bundle/"]

static func doc(path: String) -> Dictionary:
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	return value if value is Dictionary else {}

static func safe(path: String, fixture: bool = false) -> bool:
	if not path.begins_with("res://") or "\\" in path or ".." in path or path != path.simplify_path(): return false
	var relative := path.trim_prefix("res://")
	if fixture and relative.begins_with("tests/fixtures/content_pipeline/"): return true
	return RUNTIME_ROOTS.any(func(prefix: String) -> bool: return relative.begins_with(prefix))

static func catalog_errors(catalog: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	if catalog.get("schema") != "stapledons.content.catalog/1" or not catalog.get("bundles") is Array:
		return PackedStringArray(["catalog_schema"])
	var ids := {}
	for entry: Variant in catalog.bundles:
		if not entry is Dictionary or not entry.get("id") is String or entry.id.is_empty(): errors.append("invalid_id"); continue
		if ids.has(entry.id): errors.append("duplicate_id")
		ids[entry.id] = true
	if ids.size() != BUNDLE_IDS.size() or not BUNDLE_IDS.all(func(id: String) -> bool: return ids.has(id)): errors.append("catalog_inventory")
	return errors

static func input_errors(inputs: Array) -> PackedStringArray:
	var errors := PackedStringArray()
	for row: Variant in inputs:
		if not row is Dictionary or not row.get("path") is String: errors.append("source_schema"); continue
		var path: String = row.path
		if not path.begins_with("res://") or ".." in path or "\\" in path or path != path.simplify_path(): errors.append("source_path"); continue
		if not FileAccess.file_exists(path): errors.append("missing_source"); continue
		if FileAccess.get_sha256(path) != row.get("sha256") or FileAccess.get_file_as_bytes(path).size() != row.get("bytes"): errors.append("source_pin")
	return errors

static func enumerate(kind: String, manifest: Dictionary, path: String, fixture: bool = false) -> Dictionary:
	var out := {"errors": PackedStringArray(), "files": {}}
	if not kind in KINDS: out.errors.append("unknown_kind"); return out
	if kind == "captain":
		if not manifest.get("files") is Array or not manifest.get("anim") is Dictionary:
			out.errors.append("manifest_schema"); return out
		for row: Variant in manifest.files:
			if not row is Dictionary: out.errors.append("manifest_schema"); continue
			if row.get("kind") == "avatar": _add(out, path, str(row.get("file", "")), str(row.get("sha256", "")), false, fixture)
		var clips: Variant = manifest.anim.get("clips")
		if not clips is Dictionary: out.errors.append("manifest_schema"); return out
		var frames := {} # Mirrored/reused frames are intentional references to the same file.
		for clip: Variant in clips.values():
			if not clip is Dictionary or not clip.get("stages") is Dictionary: out.errors.append("manifest_schema"); continue
			for stage: Variant in clip.stages.values():
				if not stage is Dictionary: out.errors.append("manifest_schema"); continue
				for facing: Variant in stage.values():
					if not facing is Array: out.errors.append("manifest_schema"); continue
					for frame: Variant in facing:
						if not frame is Dictionary or not frame.get("file") is String: out.errors.append("manifest_schema"); continue
						frames[frame.file] = true
		for file: String in frames: _add(out, path, file, "", false, fixture)
	elif kind == "npc":
		if manifest.get("schema") != "stapledons.npc.painted/1" or not manifest.get("characters") is Array:
			out.errors.append("manifest_schema"); return out
		for row: Variant in manifest.characters:
			if not row is Dictionary or not row.get("poses") is Dictionary: out.errors.append("manifest_schema"); continue
			for pose: Variant in row.poses.values():
				if not pose is Dictionary: out.errors.append("manifest_schema"); continue
				_add(out, path, str(pose.get("file", "")) + ".bin", str(pose.get("sha256", "")), true, fixture)
			if not str(row.get("entity_id", "")).is_empty():
				_add(out, path, str(row.get("portrait", "")) + ".bin", str(row.get("portrait_sha256", "")), true, fixture)
	else:
		if not manifest.get("schema") in ["stapledons.bridge-painted-finish/1", "stapledons.commons-painted-finish/1"] or not manifest.get("resources") is Dictionary or not manifest.get("meshes") is Array:
			out.errors.append("manifest_schema"); return out
		for file: String in manifest.resources: _add(out, path, file, str(manifest.resources[file]), false, fixture)
		for row: Variant in manifest.meshes:
			if not row is Dictionary: out.errors.append("manifest_schema"); continue
			_add(out, path, str(row.get("file", "")), str(row.get("sha256", "")), false, fixture)
		# The installed loader rechecks these source geometry witnesses, including raw export fallbacks.
		for file: String in manifest.get("sources", {}):
			var raw: String = "res://ship_demo_bundle/" + file.get_file() + ".bin" if file.begins_with("res://assets/ship_demo/") else "res://ship_commons_bundle/" + file.get_file() + ".bin"
			_add(out, path, raw, str(manifest.sources[file]), true, fixture)
	_dependencies(out, fixture)
	return out

static func _add(out: Dictionary, manifest: String, file: String, pin: String, raw: bool, fixture: bool) -> void:
	var path: String = file if file.begins_with("res://") else manifest.get_base_dir().path_join(file)
	if file.is_empty() or not safe(path, fixture): out.errors.append("unsafe_path: " + path); return
	if out.files.has(path): out.errors.append("duplicate_destination: " + path); return
	out.files[path] = {"sha256": pin, "raw": raw}

static func _dependencies(out: Dictionary, fixture: bool) -> void:
	var pending: Array = out.files.keys()
	var seen := {}
	while not pending.is_empty():
		var path: String = pending.pop_back()
		if seen.has(path): continue
		seen[path] = true
		if not path.get_extension() in ["res", "tres", "gdshader"] or not FileAccess.file_exists(path): continue
		for ref: String in ResourceLoader.get_dependencies(path):
			var dependency: String = ref.get_slice("::", ref.get_slice_count("::") - 1)
			if dependency.begins_with("uid://"):
				var id: int = ResourceUID.text_to_id(dependency)
				dependency = ResourceUID.get_id_path(id) if ResourceUID.has_id(id) else ""
			if not safe(dependency, fixture): out.errors.append("unsafe_path: " + dependency); continue
			if not out.files.has(dependency): out.files[dependency] = {"sha256": "", "raw": false}
			pending.append(dependency)

static func snapshot(files: Dictionary) -> Dictionary:
	var out := {"errors": PackedStringArray(), "records": [], "digest": ""}
	var paths: Array = files.keys(); paths.sort()
	var canonical := ""
	for path: String in paths:
		if not FileAccess.file_exists(path): out.errors.append("missing_runtime: " + path); continue
		var bytes: int = FileAccess.get_file_as_bytes(path).size()
		var sha: String = FileAccess.get_sha256(path)
		var pin: String = str(files[path].get("sha256", ""))
		if not pin.is_empty() and pin != sha: out.errors.append("output_pin: " + path)
		out.records.append({"path": path, "sha256": sha, "bytes": bytes, "raw": bool(files[path].get("raw", false))})
		canonical += "%s\t%d\t%s\n" % [path, bytes, sha]
	out.digest = canonical.sha256_text()
	return out

static func check_entry(entry: Dictionary, mode: String = "runtime", fixture: bool = false) -> Dictionary:
	var out := {"errors": PackedStringArray(), "files": {}, "records": [], "digest": ""}
	if not mode in ["runtime", "authoring"]: out.errors.append("unknown_mode"); return out
	var path: String = str(entry.get("runtime_manifest", ""))
	if not safe(path, fixture): out.errors.append("unsafe_path: " + path); return out
	var manifest: Dictionary = doc(path)
	if manifest.is_empty(): out.errors.append("missing_manifest"); return out
	if FileAccess.get_sha256(path) != entry.get("runtime_manifest_sha256"): out.errors.append("manifest_pin")
	var provenance: Variant = entry.get("provenance")
	var review: Variant = entry.get("review")
	if not provenance is Dictionary or not ["tool", "model", "seed", "processing"].all(func(k: String) -> bool: return provenance.get(k) is String and not provenance[k].is_empty()): out.errors.append("provenance_schema")
	if not review is Dictionary or not ["appearance", "production"].all(func(k: String) -> bool: return review.get(k) is String and not review[k].is_empty()): out.errors.append("review_schema")
	if mode == "authoring":
		if not entry.get("inputs") is Array or entry.inputs.is_empty(): out.errors.append("source_schema")
		else: out.errors.append_array(input_errors(entry.inputs))
	var inventory: Dictionary = enumerate(str(entry.get("kind", "")), manifest, path, fixture)
	out.errors.append_array(inventory.errors); out.files = inventory.files
	out.files[path] = {"sha256": str(entry.get("runtime_manifest_sha256", "")), "raw": true}
	var state: Dictionary = snapshot(out.files)
	out.errors.append_array(state.errors); out.records = state.records; out.digest = state.digest
	if out.digest != entry.get("closure_sha256"): out.errors.append("closure_pin")
	return out
