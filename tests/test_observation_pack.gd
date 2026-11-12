extends SceneTree

const Verify = preload("res://tools/observation_pack.gd")
var passed := 0
var failed := 0

func check(ok: bool, label: String) -> void:
	if ok:
		passed += 1
		print("ok ", label)
	else:
		failed += 1
		printerr("FAIL ", label)

func _init() -> void:
	var path := "/tmp/telescope-pack-test-%d.png" % OS.get_process_id()
	var detail_path := "/tmp/telescope-pack-detail-%d.png" % OS.get_process_id()
	var img := Image.create(2, 2, false, Image.FORMAT_RGB8)
	img.fill(Color(0.25, 0.5, 0.75))
	img.save_png(path)
	img.resize(4, 4)
	img.save_png(detail_path)
	var valid := {
		"format_version": 1, "id": "fixture-only", "release": "synthetic-test",
		"doi": "fixture", "retrieved": "2026-11-12", "objects": [],
		"plates": [{"id": "plate", "source_url": "https://example.invalid/fixture",
			"licence": "fixture", "credit": "synthetic test", "registered": false,
			"levels": [{"path": path, "sha256": FileAccess.get_sha256(path), "width": 2, "height": 2}]}]
	}
	check(Verify.errors(valid, false).is_empty(), "explicit unregistered fixture has valid source metadata")
	var changed: Dictionary = valid.duplicate(true)
	changed.plates[0].levels[0].sha256 = "0".repeat(64)
	check(not Verify.errors(changed, false).is_empty(), "changed bytes rejected")
	changed = valid.duplicate(true)
	changed.plates[0].licence = ""
	check(not Verify.errors(changed, false).is_empty(), "absent rights rejected")
	changed = valid.duplicate(true)
	changed.plates[0].registered = true
	check(not Verify.errors(changed, false).is_empty(), "claim of registration without evidence rejected")
	check(not Verify.errors(valid, true).is_empty(), "starter requires actual registered field")
	changed = valid.duplicate(true)
	changed.plates.append(changed.plates[0].duplicate(true))
	check(not Verify.errors(changed, false).is_empty(), "duplicate plate identity rejected")
	changed = valid.duplicate(true)
	changed.plates[0].levels[0].width = 3
	check(not Verify.errors(changed, false).is_empty(), "declared image dimensions checked against real decoded bytes")
	changed = valid.duplicate(true)
	changed.objects = [{"id": "1234567890123456789", "plate_id": "plate", "ra_deg": NAN, "dec_deg": 0.0}]
	check(not Verify.errors(changed, false).is_empty(), "non-finite astrometry refused")
	changed = valid.duplicate(true)
	changed.objects = [{"id": 1234567890123456789, "plate_id": "plate", "ra_deg": 0.0, "dec_deg": 0.0}]
	check(not Verify.errors(changed, false).is_empty(), "long identity cannot pass as number")
	changed = valid.duplicate(true)
	changed.plates[0].registered = true
	changed.plates[0].levels.append({"path": detail_path, "sha256": FileAccess.get_sha256(detail_path), "width": 4, "height": 4})
	var anchors: Array = []
	for i in 5:
		anchors.append({"source_id": str(i), "source_x": float(i), "source_y": 0.0, "reference_x": float(i), "reference_y": 0.0, "residual_px": 0.0})
	changed.plates[0].registration = {"projection": "TAN", "reference_url": "https://example.invalid/reference", "oracle": "explicit synthetic fixture", "observed_at": "test-only", "reference": {"path": path, "sha256": FileAccess.get_sha256(path)}, "anchors": anchors}
	check(Verify.errors(changed, false).is_empty(), "complete registration evidence has a positive control")
	changed.plates[0].registration.anchors[0].source_x = 2.0
	check(not Verify.errors(changed, false).is_empty(), "reported residual checked against independent measured coordinates")
	changed.plates[0].registration.anchors[0].source_x = 0.0
	changed.plates[0].registration.anchors[0].residual_px = 2.0
	check(not Verify.errors(changed, false).is_empty(), "bad registration anchor rejected")
	changed.plates[0].registration.anchors[0].residual_px = 0.0
	changed.plates[0].registration.projection = "unsupported"
	check(not Verify.errors(changed, false).is_empty(), "unsupported projection rejected")
	changed.plates[0].registration.projection = "TAN"
	changed.plates[0].levels[1] = changed.plates[0].levels[0].duplicate(true)
	check(not Verify.errors(changed, false).is_empty(), "duplicate image dimensions are not two zoom levels")
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(detail_path)
	print("observation-pack-test: %d passed, %d failures" % [passed, failed])
	quit(1 if failed else 0)
