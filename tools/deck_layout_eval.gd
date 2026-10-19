extends SceneTree
## R2-DECK-LAYOUT §D3: the layout evaluator. make deck-layout-eval (headless).
##   (no args)                  the shipped GLBs: every view against art/deck-layout-v1/thresholds.json;
##                              prints "deck-layout: bridge ok" / "deck-layout: commons ok", exits 1 on a miss
##   --layout <json>            apply a candidate in-engine (search only; never an acceptance run)
##   --base <json>              the layout the shipped GLB was built from (default layout_current.json)
##   --areas bridge,lower       which areas to measure (default both)
##   --out <json>               the report (default renders/deck_layout/eval_<layout name>.json)
##   --report-only              print and write, never fail
##   --compare <a.json> <b.json> ...  a table of reports, one column each
## See tools/deck_layout.gd for what each number means.

const THRESHOLDS := "res://art/deck-layout-v1/thresholds.json"
const BASE := "res://art/deck-layout-v1/layout_current.json"


func _initialize() -> void:
	_run.call_deferred()


func _arg(args: PackedStringArray, key: String, fallback := "") -> String:
	var i := args.find(key)
	return args[i + 1] if i >= 0 and i + 1 < args.size() else fallback


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.has("--compare"):
		compare(args.slice(args.find("--compare") + 1))
		quit(0)
		return
	var demo: Node = load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options = {"stars": false, "background": false, "sky_state": "rest", "size": Vector2i(1280, 720)}
	root.add_child(demo)
	await process_frame
	await physics_frame
	await physics_frame
	if not demo.ready_ok:
		print("deck-layout: FAIL the ship demo did not start")
		quit(1)
		return
	demo.auto = false
	demo.journey_auto_tick = false
	var dl := DeckLayout.new(demo)
	var layout_path := _arg(args, "--layout")
	if layout_path != "":
		var errs := dl.apply(DeckLayout.load_layout(layout_path), DeckLayout.load_layout(_arg(args, "--base", BASE)), args.has("--allow-test-boxes"))
		if not errs.is_empty():
			print("deck-layout: FAIL layout %s: %s" % [layout_path, errs])
			quit(1)
			return
		await physics_frame
		await physics_frame
	var areas := Array(_arg(args, "--areas", "bridge,lower").split(","))
	var t0 := Time.get_ticks_msec()
	var report := dl.evaluate(areas)
	report.seconds = (Time.get_ticks_msec() - t0) / 1000.0
	for line in DeckLayout.summary(report):
		print(line)
	var out := _arg(args, "--out", "res://renders/deck_layout/eval_%s.json" % report.layout)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out.get_base_dir()))
	var f := FileAccess.open(out, FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  "))
	f.close()
	print("deck-layout: report %s (%.0f s)" % [out, report.seconds])
	var thr: Variant = JSON.parse_string(FileAccess.get_file_as_string(_arg(args, "--thresholds", THRESHOLDS)))
	var fails := DeckLayout.failures(report, thr if thr is Dictionary else {})
	for line in fails:
		print("FAIL %s" % line)
	for area: String in areas:
		var name := "commons" if area == "lower" else area
		var mine := Array(fails).filter(func(s: String) -> bool: return s.contains("(%s)" % area))
		print("deck-layout: %s %s" % [name, "ok" if mine.is_empty() else "FAIL (%d)" % mine.size()])
	demo.queue_free()
	await process_frame
	quit(0 if fails.is_empty() or args.has("--report-only") else 1)


## A table of reports, one column each: the numbers Mark sees at the layout pause.
func compare(paths: PackedStringArray) -> void:
	var reps := []
	for p in paths:
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(p))
		if d is Dictionary:
			reps.append(d)
	var rows := {}
	var order := []
	for r: Dictionary in reps:
		for v: Dictionary in r.views:
			for row: Array in _rows(v):
				if not rows.has(row[0]):
					rows[row[0]] = {}
					order.append(row[0])
				rows[row[0]][str(r.layout)] = row[1]
	var head := "| metric |"
	var rule := "|---|"
	for r: Dictionary in reps:
		head += " %s |" % r.layout
		rule += "---|"
	print(head)
	print(rule)
	for k: String in order:
		var line := "| %s |" % k
		for r: Dictionary in reps:
			line += " %s |" % rows[k].get(str(r.layout), "")
		print(line)


func _rows(v: Dictionary) -> Array:
	var id := "%s (%s)" % [v.view, v.get("area", "bridge")]
	if v.has("blocked"):
		var out := [["%s blocked samples" % id, str(v.blocked)], ["%s boom intrusions" % id, str(v.boom_intrusions)]]
		if int(v.level) == 2 and v.has("captain_px"):
			out.append(["%s captain px (min / median / max)" % id, "%s / %s / %s" % [v.captain_px.min, v.captain_px.median, v.captain_px.max]])
		return out
	if v.get("framing", false):
		var out := [["%s Z%d worst foreground" % [id, v.level], "%.1f%% (%s)" % [100.0 * float(v.foreground_share), v.foreground_by]]]
		if v.has("station_cells"):
			out.append(["%s Z%d cells framing a station (of %d)" % [id, v.level, v.cells], str(v.station_cells)])
			out.append(["%s Z%d at the spawn: stations in frame" % [id, v.level], ", ".join(v.spawn_stations)])
			out.append(["%s Z%d at the spawn: the lift's share, the biggest things" % [id, v.level], "%.1f%%; %s" % [100.0 * float(v.spawn_frame.lift), ", ".join(v.spawn_frame.top.map(func(t: Array) -> String: return "%s %.0f%%" % [t[0], 100.0 * float(t[1])]))]])
		if int(v.level) == 3:
			for sid: String in v.get("stations", {}):
				out.append(["%s %s px (min / max, cells seen)" % [id, sid], "%s / %s (%d)" % [v.stations[sid].min_px, v.stations[sid].max_px, v.stations[sid].seen_in_cells]])
		return out
	if str(v.view) == "sky_forward":
		return [["sky_forward rail sky fraction (worst / median)", "%.3f / %.3f" % [v.sky_fraction.worst, v.sky_fraction.median]], ["sky_forward rail pole clearance", "%.0f deg" % v.pole_clearance_deg],
			["sky_forward grid sky fraction (worst / median)", "%.3f / %.3f" % [v.grid.sky_fraction.worst, v.grid.sky_fraction.median]], ["sky_forward grid pole clearance", "%.0f deg" % v.grid.pole_clearance_deg],
			["sky_forward landing points without a pose", str(v.no_pose)], ["sky_forward at the spawn: sky fraction, pole clearance", "%.3f, %.0f deg" % [v.spawn_sky_fraction, v.spawn_pole_clearance_deg]]]
	return [["sky_side clear (captain, body)", "%s, %s" % [v.get("captain_clear"), v.get("body_clear")]]]
