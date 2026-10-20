extends SceneTree
## R2-DECK-LAYOUT §D4, AC2 (design_docs/planned/r2/deck-layout.md, ledger D-95): make deck-layout-eval.
## Scores the bridge through the real Bow and Astern views (DeckBowMetrics) against
## art/deck-layout-v2/thresholds.json and prints "deck-layout: bridge ok", or one FAIL line per
## failed §D4 metric (led by its ID) and "deck-layout: bridge FAIL".
##   --assets <dir>     score another deck (the pinned baseline: build/ship-baseline)
##   --layout <json>    apply a candidate in-engine first (DeckLayout, search only)
##   --thresholds <json>, --json <path> (write the metrics)
var failures := PackedStringArray()


func _initialize() -> void:
	_run.call_deferred()


func _arg(args: PackedStringArray, k: String, def := "") -> String:
	var i := args.find(k)
	return args[i + 1] if i >= 0 and i + 1 < args.size() else def


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var t: Variant = JSON.parse_string(FileAccess.get_file_as_string(_arg(args, "--thresholds", "res://art/deck-layout-v2/thresholds.json")))
	var res := await DeckLayoutEval.score(root, _arg(args, "--assets"), _arg(args, "--layout"))
	if not res.errors.is_empty() or not t is Dictionary:
		print("FAIL %s" % (res.errors if t is Dictionary else "thresholds unreadable"))
		print("deck-layout: bridge FAIL")
		quit(1)
		return
	for line in DeckBowMetrics.summary(res.metrics):
		print("deck-layout: %s" % line)
	var out := _arg(args, "--json")
	if out != "":
		var f := FileAccess.open(out, FileAccess.WRITE)
		f.store_string(JSON.stringify(res.metrics, "  "))
	failures = DeckBowMetrics.failures(res.metrics, t)
	for f in failures:
		print("FAIL %s" % f)
	print("deck-layout: bridge %s" % ("ok" if failures.is_empty() else "FAIL"))
	quit(0 if failures.is_empty() else 1)
