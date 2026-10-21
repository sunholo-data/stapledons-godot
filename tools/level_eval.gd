extends SceneTree
## R2-LEVELS S2, AC8 (design_docs/planned/r2/levels.md §B5, ledger D-103): make level-eval LEVEL=<id>.
## Measures a level (LevelMetrics) against its thresholds (LevelMetrics.DEFAULTS overridden by
## art/levels/<id>/thresholds.json) and prints "level-eval: <id> ok", or one FAIL line per failed
## metric (led by its §B5 ID) and "level-eval: <id> FAIL".
##   --level <id>          the level (its layout, else its shipped manifest)
##   --layout <json>       score a candidate document instead (search only)
##   --thresholds <json>, --json <path> (write the metrics)


func _initialize() -> void:
	_run.call_deferred()


func _arg(args: PackedStringArray, k: String, def := "") -> String:
	var i := args.find(k)
	return args[i + 1] if i >= 0 and i + 1 < args.size() else def


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var id := _arg(args, "--level", "bridge")
	var path := _arg(args, "--layout", LevelEval.doc_path(id))
	var doc := LevelEval.load_doc(path)
	var th := LevelEval.load_doc(_arg(args, "--thresholds", "res://art/levels/%s/thresholds.json" % id))
	if doc.is_empty():
		print("FAIL no level document for %s (%s)" % [id, path])
		print("level-eval: %s FAIL" % id)
		quit(1)
		return
	var res := await LevelEval.score(root, doc)
	if not res.errors.is_empty():
		print("FAIL %s" % [res.errors])
		print("level-eval: %s FAIL" % id)
		quit(1)
		return
	var m: Dictionary = res.metrics
	for sid: String in m.stages:
		for r: Dictionary in m.stages[sid].surfaces:
			print("level-eval: %s/%s (%s) samples %d, head %d (greybox %d, clamped %d), pole %d (first hit %d), body-both %d, px %s %s" % [sid, r.surface, r.view, r.samples, r.head, r.head_gb, r.head_gb_clamped, r.pole, r.pole_first_hit, r.body_both, r.px, r.by])
	print("level-eval: routes %d surfaces, heights %s, unreached %s" % [m.routes.surfaces, m.routes.heights, m.routes.unreached])
	var out := _arg(args, "--json")
	if out != "":
		var f := FileAccess.open(out, FileAccess.WRITE)
		f.store_string(JSON.stringify(m, "  "))
	var fails := LevelMetrics.failures(m, th)
	for f: Dictionary in fails:
		print("FAIL %s: %s" % [f.id, f.detail])
	print("level-eval: %s %s" % [doc.get("id", id), "ok" if fails.is_empty() else "FAIL"])
	quit(0 if fails.is_empty() else 1)
