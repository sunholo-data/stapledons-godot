extends SceneTree
const C := preload("res://tools/content_contract.gd")
var checks := 0
var failures := 0
func check(label: String, ok: bool) -> void:
	checks += 1
	if not ok: failures += 1; printerr("FAIL ", label)
func _initialize() -> void:
	var metrics: Variant = load("res://tools/content_metrics.gd")
	if metrics == null: check("independent metrics exist", false); finish(); return
	check("exact odd mip chain", metrics.mip_bytes(3, 5) == (15 + 2 + 1) * 4)
	check("one pixel has one mip", metrics.mip_bytes(1, 1) == 4)
	var inventory: Dictionary = C.snapshot({"res://tests/fixtures/content_pipeline/extra.png": {"raw": true}})
	var measured: Dictionary = metrics.measure(inventory.records)
	check("decoded fixture has bytes and dimensions", measured.errors.is_empty() and measured.metrics.texture_bytes > 0 and measured.metrics.max_dimension > 0)
	var expected: int = Image.load_from_file("res://tests/fixtures/content_pipeline/extra.png").get_data_size()
	check("decoded texture accounting includes full chain", measured.metrics.texture_bytes >= expected)
	for key: String in measured.metrics:
		var nonzero: Dictionary = measured.metrics.duplicate(); nonzero[key] = 1
		var too_small: Dictionary = nonzero.duplicate(); too_small[key] = 0
		check("every metric has an enforced ceiling " + key, "budget_exceeded: " + key in metrics.budget_errors(nonzero, too_small))
		var ceilings: Dictionary = measured.metrics.duplicate()
		ceilings[key] = -1
		check("negative budget rejected " + key, "budget_schema: " + key in metrics.budget_errors(measured.metrics, ceilings))
		if measured.metrics[key] > 0:
			ceilings[key] = measured.metrics[key] - 1
			check("ceiling independently rejects " + key, "budget_exceeded: " + key in metrics.budget_errors(measured.metrics, ceilings))
		else: ceilings[key] = measured.metrics[key]
	check("complete baseline cap passes", metrics.budget_errors(measured.metrics, measured.metrics).is_empty())
	check("incomplete cap fails", not metrics.budget_errors(measured.metrics, {}).is_empty())
	var invalid: Dictionary = measured.metrics.duplicate(); invalid.disk_bytes = INF
	check("non-finite cap rejected", "budget_schema: disk_bytes" in metrics.budget_errors(measured.metrics, invalid))
	var broken: Array = inventory.records.duplicate(true); broken[0].path = "res://tests/fixtures/content_pipeline/absent.png"
	check("missing measured resource fails", not metrics.measure(broken).errors.is_empty())
	finish()
func finish() -> void:
	print("content-budget: %d passed, %d failures" % [checks - failures, failures]); quit(1 if failures else 0)
