extends SceneTree
## `make news-lint`: the template lint (numerals only in slots, five tiers of four, 280 characters
## filled, labels and reason phrases digit-free). Exit 1 on any problem. Optional arguments after
## `--`: a templates file and a copy file (the tests feed it a broken fixture).


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var t := NewsCopy.load_json(args[0] if args.size() > 0 else NewsCopy.TEMPLATES)
	var c := NewsCopy.load_json(args[1] if args.size() > 1 else NewsCopy.COPY)
	var bad := NewsCopy.lint(t, c) if not t.is_empty() and not c.is_empty() else ["a copy file did not parse"]
	for b: String in bad:
		print("news-lint: %s" % b)
	print("news-lint: %s" % ("FAILED, %d problems" % bad.size() if not bad.is_empty() else "ok"))
	quit(1 if not bad.is_empty() else 0)
