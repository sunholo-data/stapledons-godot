extends SceneTree
## S1 export staging: authoring layout -> identical shipped greybox + pinned level manifest.
## godot --headless --path . --script tools/level_stage.gd -- --level commons
func _initialize() -> void:
	var args:=OS.get_cmdline_user_args();var at:=args.find("--level")
	var id:=args[at+1] if at>=0 and at+1<args.size() else ""
	if id.is_empty() or not id.is_valid_identifier():
		push_error("level-stage: --level <id> required");quit(1);return
	var path:="res://art/levels/%s/layout.json" % id
	var layout: Variant=JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	var errors:=LevelSchema.validate(layout)
	if not errors.is_empty() or layout.id!=id:
		push_error("level-stage: invalid layout: %s" % [errors]);quit(1);return
	var directory:="res://assets/levels/%s" % id
	DirAccess.make_dir_recursive_absolute(directory)
	var manifest:=LevelGreybox.manifest(layout)
	manifest["layout_asset"]=directory+"/greybox.json"
	FileAccess.open(manifest.layout_asset,FileAccess.WRITE).store_string(JSON.stringify(layout,"  ",true)+"\n")
	FileAccess.open(directory+"/manifest.json",FileAccess.WRITE).store_string(JSON.stringify(manifest,"  ",true)+"\n")
	print("level-stage: %s %s" % [id,manifest.layout_sha256]);quit()
