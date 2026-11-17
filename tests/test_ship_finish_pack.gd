extends SceneTree
## Required native runtime closure, independent of the developer tools exclusion.
const Audit := preload("res://tests/export_audit.gd")
var passed := 0
var failures := 0
func check(label: String, ok: bool) -> void:
	if ok: passed += 1
	else: failures += 1; printerr("FAIL ", label)
func _initialize() -> void:
	var expected := PackedStringArray(["demos/ship_finish_review.gdc", "demos/ship_finish_review.gd.remap"])
	check("compiled runtime and remap accepted", Audit.packed_runtime_errors(expected).is_empty())
	check("missing compiled runtime rejected", not Audit.packed_runtime_errors(PackedStringArray([expected[1]])).is_empty())
	check("missing script remap rejected", not Audit.packed_runtime_errors(PackedStringArray([expected[0]])).is_empty())
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		var zip := ZIPReader.new()
		if zip.open(args[0]) != OK: check("actual export ZIP opens", false)
		else:
			var problems := Audit.packed_runtime_errors(zip.get_files())
			check("actual export ZIP contains runtime review closure", problems.is_empty())
			for problem: String in problems: printerr(problem)
			check("developer tools exclusion retained", not zip.get_files().has("tools/ship_finish_review.gdc"))
			zip.close()
	print("ship-finish-pack: %d passed, %d failures" % [passed,failures])
	quit(0 if failures == 0 else 1)
