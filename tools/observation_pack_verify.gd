extends SceneTree

const Pack = preload("res://tools/observation_pack.gd")

func _init() -> void:
	var path := "res://data/observations/euclid_dr1/manifest.json"
	var args := OS.get_cmdline_user_args()
	if args.size() == 2 and args[0] == "--pack": path = args[1]
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	if not parsed is Dictionary:
		printerr("observation-pack-verify: missing or invalid manifest ", path)
		quit(1)
		return
	var errors: Array[String] = Pack.errors(parsed)
	for error in errors: printerr("FAIL ", error)
	print("observation-pack-verify: %d plates, %d objects, %d failures" % [parsed.get("plates", []).size(), parsed.get("objects", []).size(), errors.size()])
	quit(1 if not errors.is_empty() else 0)
