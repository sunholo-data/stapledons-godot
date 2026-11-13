extends SceneTree
## A minimal actual-PCK acceptance probe: no source tree or imported PNG resources.
const Cache = preload("res://ui/observation_tiles.gd")
const Index = preload("res://ui/observation_index.gd")
var failures := 0
func _initialize() -> void: _run.call_deferred()
func _check(ok: bool, label: String) -> void:
	if not ok: failures += 1; printerr("FAIL offline telescope: ", label)
func _run() -> void:
	var output := ""; var omit := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--build="): output = arg.trim_prefix("--build=")
		if arg.begins_with("--omit="): omit = arg.trim_prefix("--omit=")
	if not output.is_empty(): _build(output, omit); return
	var raw_manifest := "res://data/observations/euclid_dr1/manifest.json"
	_check(not FileAccess.file_exists(raw_manifest), "raw manifest excluded; pack cannot fall through to source tree")
	var manifest := _json("res://observation_bundle/manifest.json.bin")
	var objects := _json("res://observation_bundle/objects.json.bin")
	var index := Index.new()
	_check(index.set_data(objects,manifest), "bundled manifest/object index valid")
	var cache := Cache.new(); var tiles := 0
	for plate: Dictionary in manifest.get("plates", []):
		cache.activate(index.version + ":" + str(plate.id))
		var pinned: Dictionary = plate.get("tiles", {})
		var raw: String = str(pinned.get("path", ""))
		_check(not FileAccess.file_exists(raw), "raw tile index absent")
		var path: String = Cache.available_path(raw)
		if not _check_hash(path,str(pinned.get("sha256",""))): continue
		var tile_index := _json(path); var all: Array = []
		for level: Dictionary in tile_index.get("levels", []): all.append_array(level.get("tiles", []))
		_check(not all.is_empty(), "nonempty pyramid for " + str(plate.id))
		cache.set_visible(all.map(func(meta): return meta.key))
		for meta: Dictionary in all:
			_check(not FileAccess.file_exists(meta.path), "raw tile absent")
			cache.request_tile(meta); cache.pump(1)
			var entry: Dictionary = cache.get_tile(meta.key)
			_check(not entry.is_empty(), "decode pinned bundled tile " + str(meta.key))
			var was: int = cache.decodes
			cache.request_tile(meta); cache.pump(1)
			_check(cache.decodes == was, "warm tile does not decode again")
			tiles += 1
		_check(cache.cpu_bytes <= Cache.CPU_LIMIT and cache.gpu_bytes <= Cache.GPU_LIMIT, "resident cache caps")
		cache.close(); var was: int = cache.decodes; cache.pump(8)
		_check(cache.decodes == was and cache.cpu_bytes == 0 and cache.gpu_bytes == 0, "closed cache stops and releases")
	_check(tiles > 0, "actual packaged imagery exercised")
	print("telescope-offline-probe: %d tiles, %d failures" % [tiles, failures])
	quit(1 if failures else 0)
func _check_hash(path: String, expected: String) -> bool:
	var ok := FileAccess.file_exists(path) and FileAccess.get_sha256(path) == expected
	_check(ok, "pinned bundled bytes " + path)
	return ok
func _json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): _check(false,"missing " + path); return {}
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	_check(data is Dictionary,"JSON " + path)
	return data if data is Dictionary else {}
func _bundle_files(directory: String) -> Array[String]:
	var out: Array[String] = []
	for file in DirAccess.get_files_at(directory): out.append(directory.path_join(file))
	for child in DirAccess.get_directories_at(directory): out.append_array(_bundle_files(directory.path_join(child)))
	out.sort(); return out
func _build(output: String, omit: String) -> void:
	var files := _bundle_files("res://observation_bundle")
	_check(not files.is_empty(), "staged bundle exists")
	var pack := PCKPacker.new()
	_check(pack.pck_start(output) == OK, "start PCK")
	var project_path := output + ".project.godot"
	var file := FileAccess.open(project_path, FileAccess.WRITE)
	file.store_string("config_version=5\n[application]\nconfig/name=\"Telescope offline PCK smoke\"\n[rendering]\nrenderer/rendering_method=\"gl_compatibility\"\n"); file.close()
	_check(pack.add_file("res://project.godot", project_path) == OK,"pack minimal project")
	files.append_array(["res://tools/telescope_offline_probe.gd", "res://ui/observation_tiles.gd", "res://ui/observation_index.gd"])
	var count := 1
	for path: String in files:
		if path == omit: continue
		_check(pack.add_file(path, ProjectSettings.globalize_path(path)) == OK,"pack " + path); count += 1
	_check(pack.flush() == OK,"flush PCK")
	DirAccess.remove_absolute(project_path)
	print("telescope-offline-pack: %d files, %d failures" % [count,failures])
	quit(1 if failures else 0)
