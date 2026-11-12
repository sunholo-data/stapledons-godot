extends SceneTree
var passed := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	if ok: passed += 1
	else: failures += 1; printerr("FAIL ", label)
func _initialize() -> void: _run.call_deferred()
func _run() -> void:
	var source := load("res://tools/telescope_verification.gd")
	check(source != null, "verification driver exists")
	if source == null:
		print("telescope-verification-test: %d passed, %d failures" % [passed, failures]); quit(1); return
	var report: Dictionary = await source.exercise(self)
	check(report.get("failures", -1) == 0, "real archive interaction invariants")
	check(report.get("samples", []).size() >= 24, "repeated zoom/pan evidence covers multiple fields")
	check(report.get("decodes", 0) > 0, "actual visible archive tiles decode")
	check(report.get("peak_cpu_bytes", 0) > 0 and report.get("peak_cpu_bytes", 0) <= 64 * 1024 * 1024, "CPU payload is measured within budget")
	check(report.get("peak_gpu_bytes", 0) > 0 and report.get("peak_gpu_bytes", 0) <= 128 * 1024 * 1024, "texture payload estimate is within budget")
	check(report.get("max_decodes_per_pump", 100) == 1, "one decode per frame pump")
	check(report.get("closed_decodes", -1) == 0 and report.get("closed_bytes", -1) == 0, "close releases cache and prevents decode")
	check(report.get("missing_unavailable", false), "missing archive pack fails visibly")
	print("telescope-verification-test: %d passed, %d failures" % [passed, failures])
	quit(1 if failures else 0)
