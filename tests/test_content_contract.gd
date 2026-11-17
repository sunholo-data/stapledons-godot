extends SceneTree
const ROOT := "res://tests/fixtures/content_pipeline/"
var failures := 0
var checks := 0
func check(label: String, ok: bool) -> void:
	checks += 1
	if not ok: failures += 1; printerr("FAIL ", label)
func _initialize() -> void:
	var contract: Variant = load("res://tools/content_contract.gd")
	if contract == null:
		check("shared content contract exists", false); finish(); return
	var manifest := {"files": [{"kind": "avatar", "file": "extra.png", "sha256": FileAccess.get_sha256(ROOT + "extra.png")}], "anim": {"clips": {}}}
	var result: Dictionary = contract.enumerate("captain", manifest, ROOT + "manifest.json", true)
	check("one additional asset enumerated", result.errors.is_empty() and result.files.has(ROOT + "extra.png"))
	var extra := manifest.duplicate(true)
	extra.files.append({"kind": "avatar", "file": "../escape.png"})
	check("traversal fails by name", has_error(contract.enumerate("captain", extra, ROOT + "manifest.json", true), "unsafe_path"))
	extra = manifest.duplicate(true); extra.files.append(extra.files[0])
	check("duplicate destination fails", has_error(contract.enumerate("captain", extra, ROOT + "manifest.json", true), "duplicate_destination"))
	check("unknown kind fails", has_error(contract.enumerate("unknown", manifest, ROOT + "manifest.json", true), "unknown_kind"))
	check("bad NPC schema fails", has_error(contract.enumerate("npc", {}, ROOT + "manifest.json", true), "manifest_schema"))
	extra = manifest.duplicate(true); extra.files[0].file = "res://art/private.png"
	check("runtime authoring dependency fails", has_error(contract.enumerate("captain", extra, ROOT + "manifest.json", true), "unsafe_path"))
	var snapshot: Dictionary = contract.snapshot(result.files)
	check("snapshot hashes fixture", snapshot.errors.is_empty() and snapshot.records.size() == 1)
	var before: String = snapshot.digest
	var paths: Dictionary = result.files.duplicate(true)
	paths[ROOT + "provenance.txt"] = {"sha256": "", "raw": true}
	check("additional asset changes digest", contract.snapshot(paths).digest != before)
	paths[ROOT + "extra.png"].sha256 = "0".repeat(64)
	check("corrupt output pin fails", has_error(contract.snapshot(paths), "output_pin"))
	paths = {ROOT + "absent.png": {"sha256": "", "raw": true}}
	check("missing asset fails", has_error(contract.snapshot(paths), "missing_runtime"))
	var catalog := {"schema": "stapledons.content.catalog/1", "bundles": [{"id": "same"}, {"id": "same"}]}
	check("duplicate catalog identity fails", "duplicate_id" in contract.catalog_errors(catalog))
	catalog.schema = "wrong"
	check("unknown catalog schema fails", "catalog_schema" in contract.catalog_errors(catalog))
	check("empty catalog fails closed", "catalog_inventory" in contract.catalog_errors({"schema": "stapledons.content.catalog/1", "bundles": []}))
	var refs := [{"path": ROOT + "provenance.txt", "sha256": FileAccess.get_sha256(ROOT + "provenance.txt"), "bytes": FileAccess.get_file_as_bytes(ROOT + "provenance.txt").size()}]
	check("authoring source pin passes", contract.input_errors(refs).is_empty())
	refs[0].sha256 = "0".repeat(64)
	check("bad source pin fails", "source_pin" in contract.input_errors(refs))
	refs[0].path = ROOT + "absent.txt"
	check("missing source fails", "missing_source" in contract.input_errors(refs))
	# Provenance strings are not consumed runtime paths.
	extra = manifest.duplicate(true); extra.files[0].source = "res://art/retained-master.png"
	check("textual provenance is not loaded", contract.enumerate("captain", extra, ROOT + "manifest.json", true).errors.is_empty())
	var deck := {"schema": "stapledons.bridge-painted-finish/1", "resources": {ROOT + "unsafe.tres": FileAccess.get_sha256(ROOT + "unsafe.tres")}, "meshes": []}
	check("transitive authoring dependency fails", has_error(contract.enumerate("painted_deck", deck, ROOT + "manifest.json", true), "unsafe_path"))
	# Source availability is mode-specific, not inferred from provenance text.
	# Use the fixture directory for path policy; write only an ignored test-owned JSON.
	var manifest_path := ROOT + "temporary.json"
	FileAccess.open(manifest_path, FileAccess.WRITE).store_string(JSON.stringify(manifest))
	var entry := {"kind": "captain", "runtime_manifest": manifest_path, "runtime_manifest_sha256": FileAccess.get_sha256(manifest_path), "provenance": {"tool": "fixture", "model": "not_exposed", "seed": "not_exposed", "processing": "copy fixture"}, "review": {"appearance": "fixture", "production": "fixture"}, "inputs": [{"path": ROOT + "absent-source.png", "sha256": "0".repeat(64), "bytes": 0}]}
	var actual: Dictionary = contract.enumerate("captain", manifest, manifest_path, true)
	actual.files[manifest_path] = {"sha256": entry.runtime_manifest_sha256, "raw": true}
	entry.closure_sha256 = contract.snapshot(actual.files).digest
	check("runtime mode needs no authoring inputs", contract.check_entry(entry, "runtime", true).errors.is_empty())
	check("authoring mode requires sources", has_error(contract.check_entry(entry, "authoring", true), "missing_source"))
	entry.runtime_manifest_sha256 = "0".repeat(64)
	check("manifest corruption fails", has_error(contract.check_entry(entry, "runtime", true), "manifest_pin"))
	DirAccess.remove_absolute(manifest_path)
	var production: Dictionary = contract.doc(contract.CATALOG)
	check("four-record production catalog", contract.catalog_errors(production).is_empty() and production.bundles.size() == 4)
	# Explicit corpus check needs the existing raw ship witnesses staged first; fixtures have no such prerequisite.
	if "--current" in OS.get_cmdline_user_args():
		for bundle: Dictionary in production.bundles:
			var checked: Dictionary = contract.check_entry(bundle, "authoring")
			check("current bundle " + bundle.id + ": " + str(checked.errors), checked.errors.is_empty())
	finish()
func has_error(result: Dictionary, code: String) -> bool:
	return Array(result.errors).any(func(e: String) -> bool: return e.begins_with(code))
func finish() -> void:
	print("content-contract: %d passed, %d failures" % [checks - failures, failures]); quit(1 if failures else 0)
