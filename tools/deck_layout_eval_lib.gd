class_name DeckLayoutEval
extends RefCounted
## Builds the demo (optionally from another asset dir, optionally with an in-engine layout) and
## measures it (DeckBowMetrics). Shared by tools/deck_layout_eval.gd and tests/test_deck_layout_eval.gd.

const BASE := "res://art/deck-layout-v1/layout_current.json"


## {metrics, errors, demo}: the caller frees nothing; the demo is freed here once measured.
static func score(root: Window, asset_dir := "", layout_path := "", allow_test_boxes := false) -> Dictionary:
	var demo: Node = load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options = {"size": Vector2i(DeckBowMetrics.PX), "sky_state": "rest", "asset_dir": asset_dir}
	root.add_child(demo)
	await root.get_tree().process_frame
	if not demo.ready_ok:
		demo.queue_free()
		return {"metrics": {}, "errors": ["demo did not build (assets %s)" % asset_dir]}
	demo.auto = false
	demo.journey_auto_tick = false
	var dl := DeckLayout.new(demo)
	if layout_path != "":
		var errs := dl.apply(DeckLayout.load_layout(layout_path), DeckLayout.load_layout(BASE), allow_test_boxes)
		if not errs.is_empty():
			demo.queue_free()
			return {"metrics": {}, "errors": errs}
	# Moved props' colliders reach the physics space only after the transform notifications flush.
	for k in 3:
		await root.get_tree().process_frame
		await root.get_tree().physics_frame
	var m := DeckBowMetrics.new(demo, dl).metrics()
	demo.queue_free()
	await root.get_tree().process_frame
	return {"metrics": m, "errors": []}
