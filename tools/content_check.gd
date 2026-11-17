extends SceneTree
## Read-only checks: no staging, download, image generation, auto-pin or installation.
const C := preload("res://tools/content_contract.gd")
const Metrics := preload("res://tools/content_metrics.gd")
func _initialize() -> void:
	var mode := "runtime"
	var output := ""
	var args := OS.get_cmdline_user_args()
	for i: int in range(0, args.size(), 2):
		if i + 1 >= args.size() or not args[i] in ["--mode", "--json"]: printerr("FAIL content arguments"); quit(1); return
		if args[i] == "--mode": mode = args[i + 1]
		else: output = args[i + 1]
	if not output.is_empty() and not output.begins_with("res://.godot/tmp/"): printerr("FAIL report must be inside res://.godot/tmp/"); quit(1); return
	var catalog := C.doc(C.CATALOG)
	var errors := C.catalog_errors(catalog)
	var report := {"mode": mode, "bundles": {}, "aggregate": {}, "errors": []}
	var all := {}
	for entry: Dictionary in catalog.get("bundles", []):
		var state := C.check_entry(entry, mode)
		var measured := Metrics.measure(state.records)
		var problems: PackedStringArray = state.errors
		problems.append_array(measured.errors)
		problems.append_array(Metrics.budget_errors(measured.metrics, entry.get("budgets", {})))
		var stages := {}
		if entry.kind == "captain":
			stages = Metrics.captain_stages(state.records)
			for stage: String in stages:
				problems.append_array(stages[stage].errors)
				problems.append_array(Metrics.budget_errors(stages[stage].metrics, entry.get("stage_budgets", {}).get(stage, {})))
				if stage != "stills" and (stages[stage].metrics.disk_bytes > 3 * 1024 * 1024 or stages[stage].metrics.texture_bytes > 32 * 1024 * 1024): problems.append("captain_stage_cap: " + stage)
		for problem: String in problems: errors.append(str(entry.id) + ": " + problem)
		report.bundles[entry.id] = {"metrics": measured.metrics, "stages": stages, "digest": state.digest, "errors": problems}
		for row: Dictionary in state.records: all[row.path] = row
	report.aggregate = Metrics.measure(all.values()); errors.append_array(report.aggregate.errors)
	report.errors = errors
	if not output.is_empty():
		DirAccess.make_dir_recursive_absolute(output.get_base_dir())
		var file := FileAccess.open(output, FileAccess.WRITE)
		if file == null: errors.append("report_write")
		else: file.store_string(JSON.stringify(report, "  ", true) + "\n")
	for problem: String in errors: printerr("FAIL content ", problem)
	print("content-check: %d bundles, %d failures" % [report.bundles.size(), errors.size()]); quit(1 if not errors.is_empty() else 0)
