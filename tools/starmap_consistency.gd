extends SceneTree
## Star-truth consistency gate (design_docs/planned/r1/starmap-single-truth.md, T4/AC3):
## the navigation catalogue (data/starmap/stars.json) against the ship's sky stack
## (Starfield.load_tiers, default medium = GCNS + quick HIP rows + bright).
##   - every destination with photometry is in the sky under one of its aliases
##     ("Gaia DR3 n" or the bare n), exactly once, at the navigation position
##     within MAX_OFFSET_LY (float64 round-off);
##   - no identity is rendered twice;
##   - pin_destination is a no-op for every destination.
## Destinations without photometry (vmag 99: nothing to draw) are counted, not failed.
##   godot --headless --path . --script tools/starmap_consistency.gd -- [--tier medium] [--report]
const MAX_OFFSET_LY := 1e-9
## The tier binaries hold float32 copies of the truth positions: the float64 restore may move a row
## by at most half a float32 ulp per axis below 128 ly (3.8e-6 ly), sqrt(3) x that in 3D (6.6e-6 ly);
## anything larger is a different position.
const MAX_RESTORE_LY := 6.7e-6

var tier := "medium"
var report := false
var expect_rows := -1 # the active tier's own row count (sidecar), checked when given


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	for i in args.size():
		if args[i] == "--tier" and i + 1 < args.size(): tier = args[i + 1]
		if args[i] == "--report": report = true
		if args[i] == "--expect-rows" and i + 1 < args.size(): expect_rows = int(args[i + 1])
	quit(run())


func run() -> int:
	var nav: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/starmap/stars.json"))
	var bin := "res://data/starmap/stars_%s.bin" % tier
	if not FileAccess.file_exists(bin):
		print("starmap-consistency: FAIL %s is missing (make starmap-assets); no fallback in the gate" % bin)
		return 1
	if expect_rows >= 0:
		var c := StarCatalogue.load_tier(tier)
		var n := c.count if c != null else -1
		print("starmap-consistency: %s tier rows %d (want %d)" % [tier, n, expect_rows])
		if n != expect_rows: return 1
	var sf := Starfield.new()
	if not sf.load_tiers(tier):
		print("starmap-consistency: FAIL tier stack %s did not load: %s" % [tier, sf.last_error])
		return 1
	var rows_of := {}
	for k in sf.count:
		var id: String = sf.ids[k]
		if id.is_empty(): continue
		if not rows_of.has(id): rows_of[id] = []
		rows_of[id].append(k)
	var dup: Array[String] = []
	for id: String in rows_of:
		if rows_of[id].size() > 1: dup.append(id)
	var missing: Array[String] = []
	var unphotometric := 0
	var two_alias: Array[String] = []
	var worst := 0.0
	var worst_id := ""
	var over: Array = []
	var present := 0
	for s: Dictionary in nav.stars:
		var id := str(s.id)
		var found: Array = []
		for alias: String in Starfield.aliases_of(id):
			if rows_of.has(alias): found.append_array(rows_of[alias])
		if found.is_empty():
			if float(s.vmag) >= 99.0: unphotometric += 1
			else: missing.append(id)
			continue
		present += 1
		if found.size() > 1: two_alias.append(id)
		var want := SkyFrame.to_world64(PackedFloat64Array([s.x, s.y, s.z]))
		for k: int in found:
			var d := sqrt((sf.pos[3 * k] - want[0]) ** 2 + (sf.pos[3 * k + 1] - want[1]) ** 2 + (sf.pos[3 * k + 2] - want[2]) ** 2)
			if d > worst:
				worst = d
				worst_id = id
			if d > MAX_OFFSET_LY: over.append([d, id])
	over.sort_custom(func(a, b): return a[0] > b[0])
	# pin_destination must leave the stack unchanged for every destination.
	var n := sf.count
	if not OS.has_environment("NO_PINS"):
		for s: Dictionary in nav.stars: sf.pin_destination(s)
	var pin_rows := sf.count - n
	var pin_hidden := sf.pinned_ids.size()
	var fails := 0
	print("starmap-consistency (%s stack: %s, %d rows): %d destinations, %d in the sky, %d without photometry (not drawn)"
		% [tier, ",".join(sf.tiers), n, nav.stars.size(), present, unphotometric])
	print("  max navigation-vs-sky offset %s ly (%s); %d over %s ly; float64 restored %d, refused %d" % [String.num_scientific(worst), worst_id, over.size(), String.num_scientific(MAX_OFFSET_LY), sf.nav_restored, sf.nav_refused.size()])
	for o in over.slice(0, 10 if not report else over.size()):
		print("    %.6f ly  %.0f AU  %s" % [o[0], o[0] * 63241.077, o[1]])
	if not over.is_empty(): fails += 1
	print("  tier float32 vs navigation float64 before the restore: max %s ly (limit %s), refused %s" % [String.num_scientific(sf.nav_max_shift), String.num_scientific(MAX_RESTORE_LY), " ".join(sf.nav_refused.slice(0, 20))])
	if sf.nav_max_shift > MAX_RESTORE_LY or not sf.nav_refused.is_empty(): fails += 1
	print("  missing from the sky (have photometry): %d %s" % [missing.size(), " ".join(missing.slice(0, 20))])
	if not missing.is_empty(): fails += 1
	print("  identities rendered twice: %d %s" % [dup.size(), " ".join(dup.slice(0, 20))])
	if not dup.is_empty(): fails += 1
	print("  destinations under two aliases: %d %s" % [two_alias.size(), " ".join(two_alias.slice(0, 20))])
	if not two_alias.is_empty(): fails += 1
	print("  pin_destination over all destinations: %d rows added, %d tier rows hidden (no-op = 0, 0)" % [pin_rows, pin_hidden])
	if pin_rows != 0 or pin_hidden != 0: fails += 1
	print("starmap-consistency: %s" % ("PASS" if fails == 0 else "FAIL (%d checks)" % fails))
	return 0 if fails == 0 else 1
