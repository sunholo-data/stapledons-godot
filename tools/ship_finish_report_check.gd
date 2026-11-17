extends SceneTree
func _initialize() -> void:
	var path := ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--report="): path = arg.trim_prefix("--report=")
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	var errors: Array = ["report file missing or malformed"] if not value is Dictionary else preload("res://demos/ship_finish_review.gd").report_errors(value)
	if not errors.is_empty(): printerr("ship-finish-report-check: FAIL ", errors); quit(1); return
	print("ship-finish-report-check: VALID (native evidence structure; target identity and Mark review remain pending)")
	quit()
