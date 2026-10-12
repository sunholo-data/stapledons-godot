extends SceneTree
## L6a export audit, headless (make export-filter-audit; design export-completeness.md).
## The real run first, then 16 in-process mutants on in-memory copies of the inputs.
## Each mutant must be killed by its named failure string(s). Exits non-zero on failure.

const ExportAudit = preload("res://tests/export_audit.gd")

var failures := 0
var passes := 0


func check(name: String, ok: bool) -> void:
	if ok:
		passes += 1
		print("  ok    %s" % name)
	else:
		failures += 1
		print("  FAIL  %s" % name)


## One mutant: every wanted substring must appear in some failure. The "ok   mutant" line is what AC3 counts.
func kill(id: String, fails: Array, wants: Array) -> void:
	var missing := []
	for w in wants:
		if not _has(fails, w):
			missing.append(w)
	if missing.is_empty():
		passes += 1
		print("ok   mutant %s killed (%s)" % [id, ", ".join(PackedStringArray(wants))])
	else:
		failures += 1
		print("FAIL mutant %s survived: missing %s" % [id, ", ".join(PackedStringArray(missing))])


func _has(fails: Array, want: String) -> bool:
	for f in fails:
		if String(f).contains(want):
			return true
	return false


func _without(arr: PackedStringArray, item: String) -> PackedStringArray:
	var out := PackedStringArray()
	for a in arr:
		if a != item:
			out.append(a)
	return out


func _with(arr: PackedStringArray, item: String) -> PackedStringArray:
	var out := arr.duplicate()
	out.append(item)
	return out


func _replace(arr: PackedStringArray, old: String, new: String) -> PackedStringArray:
	var out := PackedStringArray()
	for a in arr:
		out.append(new if a == old else a)
	return out


func _rows_without(prefix: String) -> Array:
	return ExportAudit.DYNAMIC.filter(func(r): return r["prefix"] != prefix)


func _lens_json_only() -> Array:
	var rows := []
	for r in ExportAudit.DYNAMIC:
		var copy: Dictionary = r.duplicate()
		if copy["prefix"] == "res://data/lens":
			copy["witnesses"] = ["data/lens/lens_fwd.json", "data/lens/lens_inv.json"]
		rows.append(copy)
	return rows


func _auto_without(ext: String) -> Dictionary:
	var out: Dictionary = ExportAudit.AUTO_EXT.duplicate()
	out.erase(ext)
	return out


func _initialize() -> void:
	var f: Dictionary = ExportAudit.read_filters()
	var inc: PackedStringArray = f["include"]
	var exc: PackedStringArray = f["exclude"]

	# Real arm: the shipped inputs must audit clean. The floor and summary lines are what the Makefile greps.
	var c: Dictionary = ExportAudit.classify(inc, exc)
	var real: Array = ExportAudit.audit(inc, exc)
	var t: Dictionary = ExportAudit.tally(c)
	print("scoped files %d" % c["files"].size())
	print("distinct literals %d" % c["literals"].size())
	print("filters %d/%d" % [inc.size(), exc.size()])
	for line in real:
		print(line)
	print("export-filter-audit: %d literals, %dR %dF %dD %dX, %d failures" % [c["literals"].size(), t["R"], t["F"], t["D"], t["X"], real.size()])
	check("real arm: shipped filters audit clean", real.is_empty())

	# M1 (dev.23): data/lens/* dropped from include. Both the D row and the .bin witnesses must fail.
	kill("M1", ExportAudit.audit(_without(inc, "data/lens/*"), exc), [
		"D row res://data/lens filter data/lens/* not in include_filter",
		"F data/lens/lens_fwd.bin not covered",
		"F data/lens/lens_inv.bin not covered"])
	# M2: narrowed to the JSON headers, which can never be the only witnesses.
	kill("M2", ExportAudit.audit(_replace(inc, "data/lens/*", "data/lens/*.json"), exc), [
		"D row res://data/lens filter data/lens/* not in include_filter",
		"F data/lens/lens_fwd.bin not covered"])
	# M3: data/lens/* also excluded.
	kill("M3", ExportAudit.audit(inc, _with(exc, "data/lens/*")), [
		"witness data/lens/lens_fwd.bin excluded",
		"F data/lens/lens_fwd.bin excluded"])
	kill("M4", ExportAudit.audit(_without(inc, "data/starmap/*"), exc), [
		"F res://data/starmap/stars_large.bin not covered"])
	kill("M5", ExportAudit.audit(_without(inc, "sky_bundle/*"), exc), [
		"fallback res://sky_bundle/noirlab_10k_destarred.png.bin fails F"])
	kill("M6", ExportAudit.audit(inc, exc, {"extra_literals": ["res://data/news/extra.bin"]}), [
		"F res://data/news/extra.bin not covered"])
	kill("M7", ExportAudit.audit(inc, exc, {"extra_literals": ["res://data/brand_new"]}), [
		"UNCLASSIFIED res://data/brand_new"])
	kill("M8", ExportAudit.audit(inc, exc, {"dynamic_rows": _rows_without("res://ai_core")}), [
		"UNCLASSIFIED res://ai_core"])
	var ghost := {"prefix": "res://data/never_referenced", "filter": "data/never_referenced/*",
		"witnesses": ["data/never_referenced/x.bin"], "reason": "mutant: no code reads this"}
	kill("M9", ExportAudit.audit(inc, exc, {"dynamic_rows": ExportAudit.DYNAMIC + [ghost]}), [
		"stale row res://data/never_referenced"])
	kill("M10", ExportAudit.audit(PackedStringArray(), exc), [
		"include_filter entries 0 < 20"])
	kill("M11", ExportAudit.audit(inc, exc, {"replace_literals": []}), [
		"distinct literals 0 < 70"])
	kill("M12", ExportAudit.audit(inc, exc, {"auto_ext": _auto_without("json")}), [
		"F res://data/news/copy.json not covered"])
	kill("M13", ExportAudit.audit(inc, _without(exc, "spike/*")), [
		"F res://data/raw/hip_v7.tsv not covered"])
	kill("M14", ExportAudit.audit(inc, exc, {"dynamic_rows": _lens_json_only()}), [
		"res://data/lens has no non-resource witness"])
	kill("M15", ExportAudit.audit(inc, exc, {"auto_ext": _auto_without("gd")}), [
		"F res://ui/star_info.gd not covered"])
	kill("M16", ExportAudit.audit(inc, exc, {"extra_literals": ["res://ui/theme.tres"]}), [
		"F res://ui/theme.tres not covered",
		"unmeasured extension tres"])

	print("\n%d passed, %d failed" % [passes, failures])
	quit(1 if failures > 0 else 0)
