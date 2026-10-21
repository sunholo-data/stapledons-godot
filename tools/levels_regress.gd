extends SceneTree
## R2-LEVELS §A7, AC10 (design_docs/planned/r2/levels.md; ledger D-103): make levels-regress.
## Every landed level has art/levels/<id>/baseline.json: its evaluator numbers (LevelMetrics, the
## fingerprint below) and the sha256 of the document they came from. This re-measures each one:
##   - a level whose numbers moved fails (shared code changed another level, or its own layout moved
##     without re-pinning)
##   - a level whose document's sha256 differs from its baseline fails ("layout changed without
##     re-pinning"), and a baseline whose sha256 is not in its level doc's change log fails, so every
##     re-pin is a deliberate, logged change
##   --pin <id>          write that level's baseline from today's numbers (a deliberate re-pin)
##   --seed-box <id>     negative control: measure <id> with a box on its spawn's bow line (must fail)
##   --fake-sha <id>     negative control: treat <id>'s document as changed (must fail)
## Prints "levels-regress: ok (N levels)" or one FAIL line per difference and "levels-regress: FAIL".

const FIELDS := ["samples", "head", "head_gb", "head_gb_clamped", "pole", "pole_first_hit", "body_both", "px"]


func _initialize() -> void:
	_run.call_deferred()


func _arg(args: PackedStringArray, k: String) -> String:
	var i := args.find(k)
	return args[i + 1] if i >= 0 and i + 1 < args.size() else ""


static func fingerprint(m: Dictionary) -> Dictionary:
	var fp := {"routes": {"surfaces": m.routes.surfaces, "heights": m.routes.heights, "unreached": m.routes.unreached}, "stages": {}, "finds_seen": {}}
	for sid: String in m.stages:
		var st: Dictionary = m.stages[sid]
		var s := {"near_bow": st.get("near_bow", -1.0), "near_astern": st.get("near_astern", -1.0), "band_top": st.get("band_top", {}), "surfaces": {}}
		for r: Dictionary in st.surfaces:
			var e := {}
			for k: String in FIELDS:
				e[k] = r[k]
			s.surfaces[r.surface] = e
		fp.stages[sid] = s
	for fid: String in m.finds:
		fp.finds_seen[fid] = m.finds[fid].seen
	return fp


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var pin := _arg(args, "--pin")
	var seed_box := _arg(args, "--seed-box")
	var fake_sha := _arg(args, "--fake-sha")
	var ids := []
	for d in DirAccess.get_directories_at("res://art/levels"):
		if pin == d or FileAccess.file_exists("res://art/levels/%s/baseline.json" % d):
			ids.append(d)
	ids.sort()
	var bad := []
	for id: String in ids:
		var path := LevelEval.doc_path(id)
		var doc := LevelEval.load_doc(path)
		if id == seed_box:
			var sp: Array = doc.stages[0].spawn
			if not doc.has("pieces"):
				doc["pieces"] = []
			doc.pieces.append({"name": "regress_seed", "role": "structure", "shape": "box", "center": [float(sp[0]), float(sp[1]) + 2.0, float(sp[2]) + 1.0], "size": [1.2, 0.6, 2.0]})
		var res := await LevelEval.score(root, doc)
		if not res.errors.is_empty():
			bad.append("%s: %s" % [id, res.errors])
			continue
		var sha := LevelGreybox.layout_sha256(LevelEval.load_doc(path))
		if id == fake_sha:
			sha = "0".repeat(64)
		var fp := fingerprint(res.metrics)
		var bpath := "res://art/levels/%s/baseline.json" % id
		if id == pin:
			var f := FileAccess.open(bpath, FileAccess.WRITE)
			f.store_string(JSON.stringify({"schema": "stapledons.level.baseline/1", "level": id, "document": path, "document_sha256": sha,
				"change_log": "design_docs/levels/%s.md" % id, "fingerprint": fp}, "  ", true) + "\n")
			print("levels-regress: pinned %s (%s, sha256 %s)" % [id, path, sha.left(8)])
			continue
		var base := LevelEval.load_doc(bpath)
		if str(base.get("document_sha256", "")) != sha:
			bad.append("%s: its document %s changed (sha256 %s, baseline %s) without re-pinning (make levels-regress-pin LEVEL=%s, and a change-log row)" % [id, path, sha.left(8), str(base.get("document_sha256", "")).left(8), id])
		var log_path := "res://" + str(base.get("change_log", "design_docs/levels/%s.md" % id))
		if not FileAccess.file_exists(log_path) or not FileAccess.get_file_as_string(log_path).contains(str(base.get("document_sha256", "")).left(8)):
			bad.append("%s: baseline sha256 %s is not in its change log %s" % [id, str(base.get("document_sha256", "")).left(8), log_path])
		var want := JSON.stringify(base.get("fingerprint", {}), "", true)
		var got := JSON.stringify(JSON.parse_string(JSON.stringify(fp)), "", true)
		if want != got:
			bad.append("%s: numbers moved from the baseline: %s" % [id, _diff(base.get("fingerprint", {}), JSON.parse_string(JSON.stringify(fp)))])
	for b: String in bad:
		print("FAIL %s" % b)
	if pin == "":
		print("levels-regress: %s" % ("ok (%d levels: %s)" % [ids.size(), ", ".join(ids)] if bad.is_empty() else "FAIL"))
	quit(0 if bad.is_empty() else 1)


func _diff(a: Variant, b: Variant, path := "") -> String:
	if a is Dictionary and b is Dictionary:
		for k in (a as Dictionary).keys() + (b as Dictionary).keys():
			var d := _diff((a as Dictionary).get(k), (b as Dictionary).get(k), path + "/" + str(k))
			if d != "":
				return d
		return ""
	return "" if JSON.stringify(a) == JSON.stringify(b) else "%s: %s -> %s" % [path, JSON.stringify(a), JSON.stringify(b)]
