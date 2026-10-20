class_name LevelEval
extends RefCounted
## R2-LEVELS S2 (design_docs/planned/r2/levels.md §A5, §B5): builds the ship demo, lays a level's
## greybox pieces (LevelGreybox) over it when the document has them, and measures the level
## (LevelMetrics). Shared by tools/level_eval.gd, tools/levels_regress.gd and tests/test_level_eval.gd.
## A level document is a layout (art/levels/<id>/layout.json, with pieces) or a shipped manifest
## (assets/levels/<id>/manifest.json, measured as exported).


static func load_doc(path: String) -> Dictionary:
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	return d if d is Dictionary else {}


## The level's document: its layout when one exists, else its shipped manifest.
static func doc_path(id: String) -> String:
	for p: String in ["res://art/levels/%s/layout.json" % id, "res://assets/levels/%s/manifest.json" % id]:
		if FileAccess.file_exists(p):
			return p
	return ""


static func thresholds(id: String) -> Dictionary:
	return load_doc("res://art/levels/%s/thresholds.json" % id)


## {metrics, errors}. The demo is freed once measured.
static func score(root: Window, doc: Dictionary, grid_override := 0.0) -> Dictionary:
	var errs := LevelSchema.validate(doc)
	if not errs.is_empty():
		return {"metrics": {}, "errors": errs}
	var demo: Node = load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options = {"size": Vector2i(LevelMetrics.PX), "sky_state": "rest"}
	root.add_child(demo)
	await root.get_tree().process_frame
	if not demo.ready_ok:
		demo.queue_free()
		return {"metrics": {}, "errors": ["demo did not build"]}
	demo.auto = false
	demo.journey_auto_tick = false
	var walk: WalkArea = null
	if not (doc.get("pieces", []) as Array).is_empty():
		walk = LevelGreybox.build(doc, demo.geometry).walk
	for k in 3:
		await root.get_tree().process_frame
		await root.get_tree().physics_frame
	var lm := LevelMetrics.new(demo, doc, walk)
	var m := lm.measure(grid_override)
	m["layout_sha256"] = LevelGreybox.layout_sha256(doc)
	demo.queue_free()
	await root.get_tree().process_frame
	return {"metrics": m, "errors": []}
