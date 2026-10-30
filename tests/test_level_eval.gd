extends SceneTree
## R2-LEVELS LP1a (design_docs/planned/r2/levels.md §B5, AC5; ledger D-103): make level-eval-test.
##   positive control  the R2-LEVELS mock's intricate Commons greybox (tests/fixtures/levels/
##                     commons_mock.json) gives the recorded numbers: 7 surfaces on 4 heights, none
##                     unreached; court floor 621 samples, the captain's head behind greybox at 163
##                     (59 with the ceiling clamp), the civic tower on the pole line at 81 (first hit);
##                     and it fails exactly what S2 must fix (pole-ray, head, near-field, body-both,
##                     captain-px). The mock reported 135 / 49: duplicate piece names were renamed by
##                     the engine, so some greybox hits were not recognised; the fixture names are unique.
##   roofed control    a roofed tier near its bow rim (roofed_rim.json) passes every threshold; its roof
##                     edge is measured within 0.5 deg of the slab model (32.5 deg)
##   export input      the bridge's shipped manifest is measured on the shipped walk (no greybox)
##   negative controls each seeded defect fails by its §B5 ID: a route removed (unreached), a box on
##                     the pole line (pole-ray), the roof lowered 5 m (band-top), a find walled off with
##                     no cue (find-sight)
const FIX := "res://tests/fixtures/levels/"
var failures := 0
var passes := 0


func check(label: String, ok: bool) -> void:
	if ok:
		passes += 1
	else:
		failures += 1
	print("%s %s" % ["ok" if ok else "FAIL", label])


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await test_positive()
	await test_roofed()
	await test_export()
	await test_negative_unreached()
	await test_negative_pole()
	await test_negative_band()
	await test_negative_find()
	print("level-eval-test: %d passed, %d failures" % [passes, failures])
	quit(1 if failures else 0)


func ids(fails: Array) -> Array:
	var out := []
	for f: Dictionary in fails:
		if not out.has(f.id):
			out.append(f.id)
	out.sort()
	return out


func surf(m: Dictionary, sid: String, name: String) -> Dictionary:
	for r: Dictionary in m.stages[sid].surfaces:
		if r.surface == name:
			return r
	return {}


func test_positive() -> void:
	var r := await LevelEval.score(root, LevelEval.load_doc(FIX + "commons_mock.json"))
	if not r.errors.is_empty():
		check("positive control builds: %s" % [r.errors], false)
		return
	var m: Dictionary = r.metrics
	check("positive control: 7 surfaces on heights [53, 57, 61, 66], none unreached (%d, %s, %s)" % [m.routes.surfaces, m.routes.heights, m.routes.unreached],
		m.routes.surfaces == 7 and m.routes.heights == [53.0, 57.0, 61.0, 66.0] and (m.routes.unreached as Array).is_empty())
	var fl := surf(m, "court", "floor")
	check("positive control: court floor 621 samples, head behind greybox 163, 59 with the clamp, pole first hit 81 (%d, %d, %d, %d)" % [fl.samples, fl.head_gb, fl.head_gb_clamped, fl.pole_first_hit],
		fl.samples == 621 and fl.head_gb == 163 and fl.head_gb_clamped == 59 and fl.pole_first_hit == 81)
	check("positive control: the civic tower hides the pole (%s)" % [fl.by.get("pole:GB_back_civic_tower", 0)], int(fl.by.get("pole:GB_back_civic_tower", 0)) > 50)
	var mz := surf(m, "terrace", "mezzanine")
	var cw := surf(m, "gantry", "catwalk")
	var sv := surf(m, "service", "service_gallery")
	check("positive control: terrace 105 / head 2; catwalk 31 / pole first hit 7; service 195 / head 10 (%d/%d, %d/%d, %d/%d)" % [mz.samples, mz.head_gb, cw.samples, cw.pole_first_hit, sv.samples, sv.head_gb],
		mz.samples == 105 and mz.head_gb == 2 and cw.samples == 31 and cw.pole_first_hit == 7 and sv.samples == 195 and sv.head_gb == 10)
	check("positive control: the clamp keeps the captain in band on the court (%s px)" % [fl.px], float(fl.px[1]) <= 82.5)
	var f := ids(LevelMetrics.failures(m, {}))
	check("positive control fails exactly body-both, captain-px, head, near-field, pole-ray (%s)" % [f], f == ["body-both", "captain-px", "head", "near-field", "pole-ray"])
	var no_sky:=m.duplicate(true)
	for sid: String in no_sky.stages:
		no_sky.stages[sid].journey=false
	check("enclosed non-journey stages do not require stop-body sky",not ids(LevelMetrics.failures(no_sky,{})).has("body-both"))
	var blocked:=m.duplicate(true)
	for row: Dictionary in blocked.stages.court.surfaces:row.body_both=row.samples
	check("blocked stop body still fails a journey stage",ids(LevelMetrics.failures(blocked,{})).has("body-both"))
	var reach: Dictionary = m.routes.finds
	check("finds reachable: notice board 1 hop, telescope 4 hops (%s, %s)" % [reach.notice_board.hops, reach.telescope.hops], reach.notice_board.hops == 1 and reach.telescope.hops == 4)


func test_roofed() -> void:
	var r := await LevelEval.score(root, LevelEval.load_doc(FIX + "roofed_rim.json"))
	if not r.errors.is_empty():
		check("roofed control builds: %s" % [r.errors], false)
		return
	var b: Dictionary = r.metrics.stages.rim.band_top
	check("roofed control: roof edge %s deg measured vs %s deg model" % [b.measured_deg, b.model_deg], absf(float(b.measured_deg) - 32.54) < 0.1 and absf(float(b.model_deg) - 32.54) < 0.05)
	var f := LevelMetrics.failures(r.metrics, {})
	check("roofed control passes every threshold (%s)" % [ids(f)], f.is_empty())


func test_export() -> void:
	var r := await LevelEval.score(root, LevelEval.load_doc("res://assets/levels/bridge/manifest.json"))
	if not r.errors.is_empty():
		check("bridge manifest builds: %s" % [r.errors], false)
		return
	var d := surf(r.metrics, "deck", "deck")
	check("export input: the bridge deck is sampled on the shipped walk (%d samples, px %s)" % [d.samples, d.px], d.samples > 3000 and float(d.px[0]) > 60.0)


func _negative(path: String, mutate: Callable, id: String) -> void:
	var doc := LevelEval.load_doc(FIX + path)
	mutate.call(doc)
	var r := await LevelEval.score(root, doc)
	if not r.errors.is_empty():
		check("negative %s builds: %s" % [id, r.errors], false)
		return
	var f := ids(LevelMetrics.failures(r.metrics, {}))
	check("negative control fails %s (%s)" % [id, f], f.has(id))


func test_negative_unreached() -> void:
	await _negative("commons_mock.json", func(d: Dictionary) -> void:
		d.routes = (d.routes as Array).filter(func(rt: Dictionary) -> bool: return rt.id != "ladder_gantry"), "unreached")


func test_negative_pole() -> void:
	await _negative("roofed_rim.json", func(d: Dictionary) -> void:
		d.pieces.append({"name": "pole_box", "role": "structure", "shape": "box", "center": [0, 22, 305.5], "size": [4, 1, 4]}), "pole-ray")


func test_negative_band() -> void:
	await _negative("roofed_rim.json", func(d: Dictionary) -> void:
		for p: Dictionary in d.pieces:
			if p.name == "roof":
				p.top_z = float(p.top_z) - 5.0, "band-top")


func test_negative_find() -> void:
	await _negative("commons_mock.json", func(d: Dictionary) -> void:
		d.pieces.append({"name": "wall", "role": "structure", "shape": "box", "center": [20.5, 2.5, 60.5], "size": [3, 3, 3]}), "find-sight")
