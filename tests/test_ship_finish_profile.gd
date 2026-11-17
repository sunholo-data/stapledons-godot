extends SceneTree
const Benchmark := preload("res://demos/ship_demo_benchmark.gd")
class UploadSpy extends RefCounted:
	var calls := 0
	var status := "spy"
	func start(_report: Dictionary) -> void: calls += 1
var passed := 0
var failures := 0
func check(label: String, ok: bool) -> void:
	if ok: passed += 1
	else: failures += 1; printerr("FAIL ", label)
func _initialize() -> void:
	var bench = Benchmark.new()
	check("explicit report save boundary exists", bench.has_method("save_report"))
	if not bench.has_method("save_report"): finish(); return
	var spy := UploadSpy.new(); bench.upload = spy
	var path := "res://.godot/tmp/ship-profile-local.json"
	# Redirect only the default sink to scratch; execute real FileAccess writes without touching player data.
	bench.report_writer = func(report: Dictionary, destination: String) -> bool:
		return Benchmark.write_report(report, path if destination == Benchmark.OUTPUT else destination)
	check("local report writes", bench.save_report({"fixture":true}, path, true))
	check("saved actual bytes parse", JSON.parse_string(FileAccess.get_file_as_string(path)) == {"fixture":true})
	check("local path zero uploader calls", spy.calls == 0)
	check("default destination in local mode writes", bench.save_report({"fixture":true}, Benchmark.OUTPUT, true))
	check("local default destination still zero uploader calls", spy.calls == 0)
	check("existing default caller writes", bench.save_report({"fixture":true}, Benchmark.OUTPUT))
	check("existing default caller still uploads once", spy.calls == 1)
	check("nondefault existing caller does not upload", bench.save_report({"fixture":true}, path) and spy.calls == 1)
	check("unwritable path refuses and never uploads", not bench.save_report({}, "res://.godot/absent/report.json") and spy.calls == 1)
	var sample := {"frame_times_ms":[10.,12.,14.],"frame_times":Benchmark.summarize([10.,12.,14.]),"gpu_ms":null}
	check("real finite samples accepted", bench.sample_errors(sample,3).is_empty())
	var bad: Dictionary = sample.duplicate(true); bad.frame_times.samples = 999
	check("fake sample count rejected", not bench.sample_errors(bad,3).is_empty())
	bad = sample.duplicate(true); bad.frame_times.p99_ms = 0.
	check("invented percentiles rejected", not bench.sample_errors(bad,3).is_empty())
	check("insufficient native samples rejected", not bench.sample_errors(sample,300).is_empty())
	bad = sample.duplicate(true); bad.frame_times_ms[0] = NAN
	check("nonfinite samples rejected", not bench.sample_errors(bad,3).is_empty())
	finish()
func finish() -> void:
	print("ship-finish-profile: %d passed, %d failures" % [passed, failures])
	quit(0 if failures == 0 else 1)
