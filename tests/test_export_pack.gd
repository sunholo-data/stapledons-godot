extends SceneTree
## L6b rig-only pack oracle (make export-pack-check; design export-completeness.md, L6b).
## Lists a real --export-pack zip with ZIPReader and checks the assumptions the L6a audit makes:
## the measured pack form of every shipped literal that exists on disk (AUTO_EXT, V21), the
## DYNAMIC witnesses, no DEV_ONLY or excluded-scope entry, and an entry-count floor (V8: 443).
## Usage: godot --headless --path . --script tests/test_export_pack.gd -- <game.zip>
## STRICT=1 makes an absent witness a FAIL; otherwise it is a counted SKIP. Exits non-zero on FAIL.

const ExportAudit = preload("res://tests/export_audit.gd")
const FLOOR_ENTRIES := 400

var failures := 0
var checked := 0
var skips := 0


func fail(msg: String) -> void:
	failures += 1
	print("FAIL %s" % msg)


## The pack entries for one shipped path (V21): AUTO_EXT with a compiled extension ships as the
## compiled file plus <path>.remap; everything else ships raw under its own path. Scenes compile
## to a hashed .godot/exported entry (V21: export-<hash>-<name>.scn), so that form is a glob.
func forms(path: String) -> Array:
	var packed: String = ExportAudit.AUTO_EXT.get(path.get_extension(), "")
	if packed == "":
		return [path]
	var stem := path.get_basename()
	var compiled := ".godot/exported/*/export-*-%s.scn" % stem.get_file() if packed == "scn" else "%s.%s" % [stem, packed]
	return [compiled, path + ".remap"]


## An exact entry, or the first entry that matches a glob form.
func in_pack(entries: PackedStringArray, form: String) -> bool:
	if not form.contains("*"):
		return entries.has(form)
	for e in entries:
		if e.matchn(form):
			return true
	return false


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var zip := ZIPReader.new()
	if args.is_empty() or zip.open(args[0]) != OK:
		print("FAIL cannot open the pack zip (%s)" % (args[0] if not args.is_empty() else "no path given"))
		quit(1)
		return
	var entries := zip.get_files()
	for problem: String in preload("res://tests/level_export_audit.gd").audit(zip):
		fail(problem)
	for problem: String in preload("res://tests/commons_civic_export_audit.gd").audit(zip):
		fail(problem)
	zip.close()
	var strict := OS.get_environment("STRICT") == "1"
	var f: Dictionary = ExportAudit.read_filters()
	var c: Dictionary = ExportAudit.classify(f["include"], f["exclude"])

	# 1. Every shipped R or F literal that exists on disk, in its measured form.
	for L in c["literals"]:
		if L["cls"] != "R" and L["cls"] != "F":
			continue
		var rel: String = L["key"]
		if not FileAccess.file_exists("res://" + rel):
			continue
		for form in forms(rel):
			checked += 1
			if not in_pack(entries, form):
				fail("%s not in the pack (form of %s, %s)" % [form, L["lit"], L["where"]])

	# 2. Every DYNAMIC witness: present on disk means it must be in the pack; absent is a FAIL when strict.
	for r in c["dynamic"]:
		for w in r["witnesses"]:
			if not FileAccess.file_exists("res://" + w):
				if strict:
					fail("absent witness %s (%s)" % [w, r["prefix"]])
				else:
					skips += 1
					print("SKIP absent witness %s" % w)
				continue
			for form in forms(w):
				checked += 1
				if not in_pack(entries, form):
					fail("%s not in the pack (witness of %s)" % [form, r["prefix"]])

	# 3. No DEV_ONLY path and no excluded-scope file in the pack.
	for r in c["dev_only"]:
		if r["exact"]:
			continue
		checked += 1
		for e in entries:
			if e.begins_with(r["path"].trim_prefix("res://")):
				fail("dev-only %s in the pack (%s)" % [r["path"], e])
	for e in entries:
		checked += 1
		if ExportAudit._excluded(e, f["exclude"]):
			fail("excluded-scope entry in the pack: %s" % e)

	# 4. Anti-vacuity: a real pack is never this small.
	if entries.size() < FLOOR_ENTRIES:
		fail("pack entries %d < %d" % [entries.size(), FLOOR_ENTRIES])

	print("export-pack-check: %d checked, %d skips, %d failures" % [checked, skips, failures])
	quit(1 if failures > 0 else 0)
