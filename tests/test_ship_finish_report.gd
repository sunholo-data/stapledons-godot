extends SceneTree
const Benchmark := preload("res://demos/ship_demo_benchmark.gd")
var passed := 0
var failures := 0
func check(label: String, ok: bool) -> void:
	if ok: passed += 1
	else: failures += 1; printerr("FAIL ", label)
func _initialize() -> void:
	var path := "res://demos/ship_finish_review.gd"
	check("native route and validator exist", FileAccess.file_exists(path))
	if not FileAccess.file_exists(path): finish(); return
	var review = load(path)
	var identity := {"build":"fixture-g12345678","packed":true,"counts":{"bridge":141,"commons":1000,"residents":42},"manifest_hashes":{}}
	for file: String in preload("res://demos/ship_review_readiness.gd").MANIFESTS: identity.manifest_hashes[file] = FileAccess.get_sha256(file)
	var report := {"schema":"stapledons.ship-finish-review/1","local_only":true,"native":true,"target_measurement_pending":true,"evidence":"fixture","identity":identity,"hardware":{"model":"fixture","gpu":"fixture","driver":"metal","vsync":1},"resolution":[1920,1080],"seed":424242,"conditions":[]}
	var presentation := {"window_size_api_px":[1920,1080],"viewport_visible_rect_units":[1920,1080],"root_render_target_px":[3840,2160],"ship_render_target_px":[1920,1080],"sky_render_target_px":[1920,1080],"screen_scale_api":2.,"window_content_scale_factor":1.,"screen_dpi_api":144,"screen_index":0}
	for condition in ["original", "painted"]:
		var row := {"material":condition,"identity":identity.duplicate(true),"restored":true,"presentation":presentation.duplicate(true),"phases":[]}
		for name: String in review.PHASES:
			var times := []; times.resize(300); times.fill(10.)
			var sample := {"view":name,"frame_times_ms":times,"frame_times":Benchmark.summarize(times),"camera":{"eye":[1.,2.,3.]},"presentation":presentation.duplicate(true),"inputs":[],"before":{"phase":name,"tick":0,"lift_y":1.,"seated":true},"after":{"phase":name,"tick":1,"lift_y":2.},"gpu_ms":null,"warmup_frames":120,"repeats":[]}
			row.phases.append(sample)
		report.conditions.append(row)
	check("complete fixture accepted only by fixture mode", review.report_errors(report, true, true).is_empty())
	var roundtrip: Array = review.report_errors(JSON.parse_string(JSON.stringify(report)), true, true)
	check("JSON roundtrip remains valid", roundtrip.is_empty())
	if not roundtrip.is_empty(): printerr(roundtrip)
	check("fixture cannot count as native evidence", not review.report_errors(report).is_empty())
	var bad: Dictionary = report.duplicate(true); bad.conditions.pop_back()
	check("missing material condition refused", not review.report_errors(bad,true,true).is_empty())
	bad = report.duplicate(true); bad.conditions[0].phases.pop_back()
	check("missing phase refused", not review.report_errors(bad,true,true).is_empty())
	bad = report.duplicate(true); bad.identity.manifest_hashes[preload("res://demos/ship_review_readiness.gd").MANIFESTS[0]] = "stale"
	check("stale resource pins refused", not review.report_errors(bad,true,true).is_empty())
	bad = report.duplicate(true); bad.conditions[0].identity.build = "another-build"
	check("mixed archives refused", not review.report_errors(bad,true,true).is_empty())
	bad = report.duplicate(true); bad.target_measurement_pending = false
	check("fabricated target confirmation refused", not review.report_errors(bad,true,true).is_empty())
	bad = report.duplicate(true); bad.native = false
	check("headless cannot claim native timings", not review.report_errors(bad,true,true).is_empty())
	bad = report.duplicate(true); bad.conditions[0].phases[0].frame_times.samples = 999
	check("invented sample total refused", not review.report_errors(bad,true,true).is_empty())
	bad = report.duplicate(true); bad.conditions[0].restored = false
	check("failed material restoration refused", not review.report_errors(bad,true,true).is_empty())
	bad = report.duplicate(true)
	var times := []; times.resize(300); times.fill(30.)
	bad.conditions[0].phases[0].frame_times_ms = times; bad.conditions[0].phases[0].frame_times = Benchmark.summarize(times)
	check("miss needs two longer repeats", not review.report_errors(bad,true,true).is_empty())
	check("normal launch route recognizes explicit review", load("res://main.gd").launch_route({"ship-finish-review":"/tmp/review"}) == "ship")
	bad = report.duplicate(true); bad.conditions[0].erase("presentation")
	check("absent presentation dimensions refused", not review.report_errors(bad,true,true).is_empty())
	bad = report.duplicate(true); bad.conditions[0].presentation.root_render_target_px = [0,2160]
	check("zero render target refused", not review.report_errors(bad,true,true).is_empty())
	bad = report.duplicate(true); bad.conditions[0].presentation.window_size_api_px = [1280,720]
	check("window metadata must match requested report size", not review.report_errors(bad,true,true).is_empty())
	bad = report.duplicate(true); bad.conditions[0].presentation.erase("screen_scale_api")
	check("absent display scale refused", not review.report_errors(bad,true,true).is_empty())
	bad = report.duplicate(true); bad.conditions[0].presentation.screen_scale_api = 0.
	check("zero display scale refused", not review.report_errors(bad,true,true).is_empty())
	bad = report.duplicate(true); bad.conditions[1].phases[0].presentation.ship_render_target_px = [960,540]
	check("phase target mismatch refused", not review.report_errors(bad,true,true).is_empty())
	finish()
func finish() -> void:
	print("ship-finish-report: %d passed, %d failures" % [passed, failures])
	quit(0 if failures == 0 else 1)
