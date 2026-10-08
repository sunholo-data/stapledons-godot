extends SceneTree
## M3.6 render diff (Godot; plan N-3): each render against the pinned baseline of the same name.
##   godot --headless --path . --script tools/render_diff.gd -- [--baseline=DIR] [--manifest=FILE] [--max=M] PNG...
## The baseline (default renders/bh_baseline, fetched by make bh-refs) is first checked against the
## committed manifest (default data/refs/bh_manifest.sha256): a baseline file whose sha256 is not
## the pinned one fails. Then the mean absolute difference over R, G and B (0..1) of each render must
## be <= M (default 1/255). A render without a baseline, or of another size, fails.
## Prints one line per render and "render-diff: OK" / "render-diff: FAIL".

func _initialize() -> void:
	var baseline := "renders/bh_baseline"
	var manifest := "data/refs/bh_manifest.sha256"
	var limit := 1.0 / 255.0
	var paths: Array[String] = []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--baseline="): baseline = a.trim_prefix("--baseline=")
		elif a.begins_with("--manifest="): manifest = a.trim_prefix("--manifest=")
		elif a.begins_with("--max="): limit = float(a.trim_prefix("--max="))
		else: paths.append(a)
	var fail := 0
	var pins := {}
	var mf := FileAccess.get_file_as_string(manifest)
	if mf.is_empty():
		print("render-diff: FAIL no manifest %s" % manifest)
		quit(1)
		return
	for line in mf.split("\n", false):
		var parts := line.split("  ", false)
		if parts.size() == 2: pins[parts[1].strip_edges()] = parts[0].strip_edges()
	if paths.is_empty():
		print("render-diff: FAIL no renders given")
		quit(1)
		return
	var worst := 0.0
	for p in paths:
		var name := p.get_file()
		var base := baseline.path_join(name)
		if not pins.has(name):
			print("render-diff: FAIL %s is not in %s" % [name, manifest])
			fail += 1
			continue
		if FileAccess.get_sha256(base) != pins[name]:
			print("render-diff: FAIL baseline %s missing or not the pinned bytes (make bh-refs)" % base)
			fail += 1
			continue
		var a := Image.load_from_file(ProjectSettings.globalize_path("res://" + p) if not p.begins_with("/") else p)
		var b := Image.load_from_file(ProjectSettings.globalize_path("res://" + base) if not base.begins_with("/") else base)
		if a == null or b == null or a.get_size() != b.get_size():
			print("render-diff: FAIL %s unreadable or of another size than its baseline" % name)
			fail += 1
			continue
		var m := mean_abs_diff(a, b)
		worst = maxf(worst, m)
		var ok := m <= limit
		if not ok: fail += 1
		print("render-diff: %s %s mean |d| %.6f (%.3f/255, limit %.3f/255)" % ["ok  " if ok else "FAIL", name, m, m * 255.0, limit * 255.0])
	print("render-diff: %d renders, worst %.3f/255, %d failures" % [paths.size(), worst * 255.0, fail])
	print("render-diff: %s" % ("OK" if fail == 0 else "FAIL"))
	quit(1 if fail > 0 else 0)


## Mean |a - b| over the R, G, B channels of every pixel, in 0..1.
static func mean_abs_diff(a: Image, b: Image) -> float:
	a = a.duplicate()
	b = b.duplicate()
	a.convert(Image.FORMAT_RGB8)
	b.convert(Image.FORMAT_RGB8)
	var da := a.get_data()
	var db := b.get_data()
	var sum := 0
	for i in da.size():
		sum += absi(int(da[i]) - int(db[i]))
	return float(sum) / (255.0 * float(da.size()))
