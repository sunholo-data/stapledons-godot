extends SceneTree
## Positive pack plus dropped transitive manifest/greybox/lift negative controls.
const Audit = preload("res://tests/level_export_audit.gd")
var failed := 0
func _initialize() -> void:
	var docs := {
		"data/camera/views.json": {"schema":"stapledons.camera.views/3","level_manifest_index":"res://assets/levels/index.json"},
		"assets/levels/index.json": {"schema":"stapledons.level.index/1","levels":{"commons":"res://assets/levels/commons/manifest.json"}},
		"assets/levels/commons/manifest.json": {"schema":"stapledons.level/1","id":"commons","layout_asset":"res://assets/levels/commons/greybox.json"},
		"assets/levels/commons/greybox.json": {"schema":"stapledons.level/1","id":"commons"},
		"assets/levels/lift.json": {"schema":"stapledons.lift/1"}
	}
	DirAccess.make_dir_recursive_absolute("res://.godot/tmp")
	var mutations := ["", "assets/levels/commons/manifest.json", "assets/levels/commons/greybox.json", "assets/levels/lift.json"]
	for i in mutations.size():
		var path := "res://.godot/tmp/level-export-control-%d.zip" % i
		var writer := ZIPPacker.new()
		if writer.open(path) != OK: failed += 1; continue
		for name: String in docs:
			if name == mutations[i]: continue
			writer.start_file(name)
			writer.write_file(JSON.stringify(docs[name]).to_utf8_buffer())
			writer.close_file()
		writer.close()
		var reader := ZIPReader.new()
		if reader.open(path) != OK: failed += 1; continue
		var errors := Audit.audit(reader)
		reader.close()
		var ok := errors.is_empty() if i == 0 else errors.any(func(e: String) -> bool: return e.contains(mutations[i]))
		if not ok: failed += 1
		print("%s level export %s %s" % ["ok" if ok else "FAIL", "complete dependency graph" if i == 0 else "rejects dropped " + mutations[i], errors])
	print("level-export: %d passed, %d failures" % [mutations.size()-failed, failed])
	quit(1 if failed else 0)
