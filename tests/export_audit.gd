extends RefCounted
## L6a static export audit (design export-completeness.md; plan R1-L6-EXPORT-COMPLETENESS).
## Every res:// literal the shipped code reads must survive export_presets.cfg. Pure functions
## over the filters and the scoped .gd files; read-only. Plain script (no class_name): tests/ is
## excluded export scope. Consumed by tests/test_export_audit.gd and tests/test_export_pack.gd.

const PRESET := "res://export_presets.cfg"

## R: extensions the exporter packs with no include entry (V9, V21). The value is the packed
## extension for a script or scene (<base>.gdc, <base>.scn, each with a <path>.remap), or "" for raw.
const AUTO_EXT := {"gd": "gdc", "tscn": "scn", "gdshader": "", "gdshaderinc": "", "json": ""}

## D: concatenated or directory reads. Each row names the include entry that ships the bytes,
## the witnesses the game needs (project-relative, never all AUTO_EXT), and why.
const DYNAMIC := [
	{"prefix": "res://ai", "filter": "ai/*.ail", "witnesses": ["ai/adapters.ail", "ai/ailang.toml"],
		"reason": "bridge/ai_bridge.gd:380 copies res://ai into the user cache (_unpack_ai); ai/*.ail and ai/ailang.toml ship"},
	{"prefix": "res://ai_core", "filter": "ai_core/*", "witnesses": ["ai_core/index.ndjson"],
		"reason": "bridge/ai_cache.gd:17 core_dir; ai_core/* ships the index and the blobs (AI.8)"},
	{"prefix": "res://areas_bundle", "filter": "areas_bundle/*", "witnesses": ["areas_bundle/bridge/cam_bridge.json.bin"],
		"reason": "interior/area_bundle.gd:53 STAGED_DIR; staged by areas-stage (Makefile:124)"},
	{"prefix": "res://assets/areas", "filter": "areas_bundle/*", "witnesses": ["areas_bundle/bridge/cam_bridge.json.bin"],
		"reason": "interior/area_bundle.gd:52 SOURCE_DIR is .gdignore'd; exported builds read the staged .bin copy"},
	{"prefix": "res://assets/characters/captain", "filter": "", "witnesses": ["assets/characters/captain/manifest.json"],
		"reason": "demos/ship_geometry_demo.gd:134 avatar load_dir; manifest.json is AUTO_EXT so needs no filter. The PNGs are unverified (design blind spot)"},
	{"prefix": "res://assets/planets", "filter": "planet_bundle/*", "witnesses": ["planet_bundle/2k_jupiter.jpg.bin"],
		"reason": "planets/system_view.gd:24 TEX_DIR is .gdignore'd; exported builds read the staged planet_bundle copy"},
	{"prefix": "res://assets/ship_commons/", "filter": "ship_commons_bundle/*", "witnesses": ["ship_commons_bundle/commons_coarse.glb.bin"],
		"reason": "demos/ship_commons.gd:4-5 dev source with the bundled .bin fallback"},
	{"prefix": "res://assets/ship_demo/", "filter": "ship_demo_bundle/*", "witnesses": ["ship_demo_bundle/ship.glb.bin"],
		"reason": "demos/ship_geometry_demo.gd:111-112 dev source with the bundled .bin fallback"},
	{"prefix": "res://data/ai", "filter": "data/ai/*", "witnesses": ["data/ai/core/index.ndjson"],
		"reason": "bridge/ai_bridge.gd:380 copies data/ai into the user cache; the ndjson index is not AUTO_EXT"},
	{"prefix": "res://data/ai/cast", "filter": "", "witnesses": ["data/ai/cast/medic.json"],
		"reason": "bridge/ai_relay.gd:29 CAST_DIR; read only through json, which is AUTO_EXT"},
	{"prefix": "res://data/crew/portraits", "filter": "data/crew/portraits/*", "witnesses": ["data/crew/portraits/medic_neutral.png"],
		"reason": "ui/crew_page.gd:15 PORTRAIT_DIR; raw PNGs read by CaptainAvatar.make_texture (.import is gitignored)"},
	{"prefix": "res://data/interlude/home", "filter": "data/interlude/*", "witnesses": ["data/interlude/home/SOURCES"],
		"reason": "ui/crossing_review.gd:22 HOME_DIR; tier<n>.webp per time.tier (attended art, ruling 2), raw WebP read by CaptainAvatar.make_texture"},
	{"prefix": "res://data/lens", "filter": "data/lens/*", "witnesses": ["data/lens/lens_fwd.bin", "data/lens/lens_inv.bin"],
		"reason": "physics/schwarzschild.gd:22, 216-224: load_tables reads lens_<t>.json headers and lens_<t>.bin tables; dev.23. The .bin tables are the witnesses"},
	{"prefix": "res://data/lore", "filter": "data/lore/*", "witnesses": ["data/lore/archive/bubble.md"],
		"reason": "interior/lore_loader.gd:9, 31-32 lists archive/*.md"},
	{"prefix": "res://data/planets/ALBEDO", "filter": "data/planets/*", "witnesses": ["data/planets/ALBEDO"],
		"reason": "planets/system_view.gd:28 ALBEDO_TABLE, an extensionless file"},
	{"prefix": "res://data/planets/TEXTURES", "filter": "data/planets/*", "witnesses": ["data/planets/TEXTURES"],
		"reason": "planets/system_view.gd:104 texture declarations, an extensionless file"},
	{"prefix": "res://data/starmap", "filter": "data/starmap/*", "witnesses": ["data/starmap/stars_bright.bin"],
		"reason": "sky/star_catalogue.gd:111 default tier dir; sky/starfield.gd:139 reads stars_large.bin from the same entry"},
	{"prefix": "res://planet_bundle", "filter": "planet_bundle/*", "witnesses": ["planet_bundle/2k_jupiter.jpg.bin"],
		"reason": "planets/planet_smoke.gd:13 exported-build fallback for assets/planets"},
	{"prefix": "res://runtime", "filter": "runtime/*", "witnesses": ["runtime/bin/ailang"],
		"reason": "bridge/sim_bridge.gd:395 _unpack_runtime copies res://runtime"},
	{"prefix": "res://runtime/VERSION", "filter": "runtime/*", "witnesses": ["runtime/VERSION"],
		"reason": "bridge/sim_bridge.gd:386 reads the bundled runtime version"},
	{"prefix": "res://runtime/cache", "filter": "runtime/*", "witnesses": ["runtime/cache/registry/sunholo/relativity/0.12.0/_smoke.ail"],
		"reason": "bridge/ai_bridge.gd:368 default cache_src, the bundled package cache; 0.12.0 is the sim/ailang.toml pin (Makefile:275 reads it)"},
	{"prefix": "res://ship_commons_bundle/", "filter": "ship_commons_bundle/*", "witnesses": ["ship_commons_bundle/commons_coarse.glb.bin"],
		"reason": "demos/ship_commons.gd:5 bundled fallback"},
	{"prefix": "res://ship_demo_bundle/", "filter": "ship_demo_bundle/*", "witnesses": ["ship_demo_bundle/ship.glb.bin"],
		"reason": "demos/ship_geometry_demo.gd:112 bundled fallback"},
	{"prefix": "res://sim", "filter": "sim/*.ail", "witnesses": ["sim/ailang.toml"],
		"reason": "bridge/sim_bridge.gd:390 runtime_inputs copies the sim tree"},
]

## X: dev-only paths. They must not ship, and a fallback must ship. exact: the literal must equal
## the path; otherwise the path is a prefix. The root row is the bare "res://" (never read as a file).
const DEV_ONLY := [
	{"path": "res://tools/", "exact": false, "fallback": "",
		"reason": "main.gd dev routes (--golden, --bench, --*-capture, site movie); tools/* is excluded on purpose (V13)"},
	{"path": "res://data/raw/background/", "exact": false, "fallback": "res://sky_bundle/",
		"reason": "dev source of the sky photos; data/raw is gitignored and .gdignore'd; exported builds read sky_bundle"},
	{"path": "res://", "exact": true, "fallback": "",
		"reason": "root, never read as a file"},
]

## Anti-vacuity floors (fail before any rule is evaluated). Each sits just below the measured value.
const FLOOR_INCLUDE := 20
const FLOOR_EXCLUDE := 6
const FLOOR_FILES := 60
const FLOOR_LITERALS := 70
const FLOOR_DYNAMIC := 15


## Filters from preset.0. Empty entries are dropped.
static func read_filters() -> Dictionary:
	var cfg := ConfigFile.new()
	cfg.load(PRESET)
	return {
		"include": _split(cfg.get_value("preset.0", "include_filter", "")),
		"exclude": _split(cfg.get_value("preset.0", "exclude_filter", "")),
	}


static func _split(s: String) -> PackedStringArray:
	var out := PackedStringArray()
	for part in s.split(","):
		var t := part.strip_edges()
		if t != "":
			out.append(t)
	return out


## Project-relative *.gd paths that no exclude entry matches. Hidden directories are skipped.
## Sorted, so the walk order and the report are deterministic.
static func scoped_files(exclude: PackedStringArray) -> Array[String]:
	var all: Array[String] = []
	_walk("res://", "", all)
	all.sort()
	var out: Array[String] = []
	for f in all:
		if not _excluded(f, exclude):
			out.append(f)
	return out


static func _walk(dir: String, rel: String, out: Array[String]) -> void:
	for name in DirAccess.get_files_at(dir):
		if name.ends_with(".gd"):
			out.append(rel + name)
	for name in DirAccess.get_directories_at(dir):
		if not name.begins_with("."):
			_walk(dir.path_join(name), rel + name + "/", out)


## Distinct res:// literals (both quote styles) with their first file:line. replace_literals
## and extra_literals are mutation inputs; the real run passes neither.
static func extract(files: Array[String], mutations: Dictionary = {}) -> Array:
	var out: Array = []
	var seen := {}
	if mutations.has("replace_literals"):
		for lit in mutations["replace_literals"]:
			seen[lit] = true
			out.append({"lit": lit, "where": "mutant"})
	else:
		var rxs := [RegEx.create_from_string("\"(res://[^\"]*)\""), RegEx.create_from_string("'(res://[^']*)'")]
		for f in files:
			var text := FileAccess.get_file_as_string("res://" + f)
			for rx in rxs:
				for m in rx.search_all(text):
					var lit: String = m.get_string(1)
					if seen.has(lit):
						continue
					seen[lit] = true
					out.append({"lit": lit, "where": "%s:%d" % [f, text.substr(0, m.get_start()).count("\n") + 1]})
	for lit in mutations.get("extra_literals", []):
		out.append({"lit": lit, "where": "mutant"})
	return out


## Scope, extraction and classification, with no rule evaluation (audit() does that).
## Each literal gets exactly one cls: R, F, D, X, or "?" (unclassified). The shared seam for
## tests/test_export_pack.gd.
static func classify(include: PackedStringArray, exclude: PackedStringArray, mutations: Dictionary = {}) -> Dictionary:
	var auto_ext: Dictionary = mutations.get("auto_ext", AUTO_EXT)
	var dynamic: Array = mutations.get("dynamic_rows", DYNAMIC)
	var dev_only: Array = mutations.get("dev_only_rows", DEV_ONLY)
	var files := scoped_files(exclude)
	var lits := extract(files, mutations)
	var dyn_hits := {}
	var dev_hits := {}
	for L in lits:
		var lit: String = L["lit"]
		var key := lit.trim_prefix("res://")
		L["key"] = key
		L["cls"] = "?"
		L["row"] = {}
		for r in dev_only:
			if _dev_match(r, lit):
				L["cls"] = "X"
				L["row"] = r
				dev_hits[r["path"]] = true
				break
		if L["cls"] == "X":
			continue
		var ext := key.get_extension()
		if key.ends_with("/") or ext == "":
			L["cls"] = "D"
			for r in dynamic:
				if _norm(r["prefix"]) == _norm(key):
					L["row"] = r
					dyn_hits[_norm(r["prefix"])] = true
					break
			if L["row"].is_empty():
				L["cls"] = "?"
		elif auto_ext.has(ext):
			L["cls"] = "R"
		else:
			L["cls"] = "F"
	return {
		"files": files, "literals": lits, "dynamic": dynamic, "dev_only": dev_only,
		"dyn_hits": dyn_hits, "dev_hits": dev_hits, "auto_ext": auto_ext,
	}


## Per-class counts over classify()'s literals. Keys R, F, D, X, "?".
static func tally(c: Dictionary) -> Dictionary:
	var t := {"R": 0, "F": 0, "D": 0, "X": 0, "?": 0}
	for L in c["literals"]:
		t[L["cls"]] += 1
	return t


## Failure lines (each starts with "FAIL " or "UNCLASSIFIED "). Empty means the export keeps every read.
static func audit(include: PackedStringArray, exclude: PackedStringArray, mutations: Dictionary = {}) -> Array[String]:
	var c := classify(include, exclude, mutations)
	var fails: Array[String] = []
	var floors := [
		["include_filter entries", include.size(), FLOOR_INCLUDE],
		["exclude_filter entries", exclude.size(), FLOOR_EXCLUDE],
		["scoped files", c["files"].size(), FLOOR_FILES],
		["distinct literals", c["literals"].size(), FLOOR_LITERALS],
		["DYNAMIC rows", c["dynamic"].size(), FLOOR_DYNAMIC],
	]
	for fl in floors:
		if fl[1] < fl[2]:
			fails.append("FAIL %s %d < %d" % [fl[0], fl[1], fl[2]])
	if not fails.is_empty():
		return fails
	var auto_ext: Dictionary = c["auto_ext"]

	for L in c["literals"]:
		var lit: String = L["lit"]
		var key: String = L["key"]
		match L["cls"]:
			"?":
				fails.append("UNCLASSIFIED %s (%s)" % [lit, L["where"]])
			"R", "F":
				var why := _pack_reason(key, auto_ext, include, exclude)
				if why != "":
					fails.append("FAIL %s %s %s (%s)" % [L["cls"], lit, why, L["where"]])
			"X":
				if _pack_reason(key, auto_ext, include, exclude) == "":
					fails.append("FAIL stale row %s is exported, so it is not dev-only (%s)" % [lit, L["where"]])

	for r in c["dev_only"]:
		if not c["dev_hits"].has(r["path"]):
			fails.append("FAIL stale row %s (no literal reads it)" % r["path"])
		if r["fallback"] == "":
			continue
		var found := false
		for L in c["literals"]:
			if L["lit"].begins_with(r["fallback"]):
				found = true
				var why := _pack_reason(L["key"], auto_ext, include, exclude)
				if why != "":
					fails.append("FAIL X %s fallback %s fails F (%s)" % [r["path"], L["lit"], why])
		if not found:
			fails.append("FAIL X %s fallback %s has no literal" % [r["path"], r["fallback"]])

	for r in c["dynamic"]:
		var prefix: String = r["prefix"]
		var filt: String = r["filter"]
		var witnesses: Array = r["witnesses"]
		if not c["dyn_hits"].has(_norm(prefix)):
			fails.append("FAIL stale row %s (no literal reads it)" % prefix)
		if witnesses.is_empty():
			fails.append("FAIL D row %s has no witnesses" % prefix)
		if filt != "" and not include.has(filt):
			fails.append("FAIL D row %s filter %s not in include_filter" % [prefix, filt])
		var non_resource := false
		for w in witnesses:
			var is_res: bool = auto_ext.has(String(w).get_extension())
			non_resource = non_resource or not is_res
			if filt == "" and not is_res:
				fails.append("FAIL D row %s witness %s is not an AUTO_EXT resource" % [prefix, w])
			if _excluded(w, exclude):
				fails.append("FAIL D row %s witness %s excluded" % [prefix, w])
			var why := _pack_reason(w, auto_ext, include, exclude)
			if why != "":
				fails.append("FAIL %s %s %s (witness of %s)" % ["R" if is_res else "F", w, why, prefix])
		if filt != "" and not non_resource:
			fails.append("FAIL D row %s has no non-resource witness" % prefix)
	return fails


## "" when the path is packed: not excluded, and either an AUTO_EXT resource or matched by an include.
## Otherwise "excluded", "not covered", or "not covered; unmeasured extension tres".
static func _pack_reason(path: String, auto_ext: Dictionary, include: PackedStringArray, exclude: PackedStringArray) -> String:
	if _excluded(path, exclude):
		return "excluded"
	if auto_ext.has(path.get_extension()):
		return ""
	if _included(path, include):
		return ""
	if path.get_extension() == "tres":
		return "not covered; unmeasured extension tres"
	return "not covered"


static func _included(path: String, include: PackedStringArray) -> bool:
	for e in include:
		if path.matchn(e):
			return true
	return false


static func _excluded(path: String, exclude: PackedStringArray) -> bool:
	for e in exclude:
		if path.matchn(e):
			return true
	return false


## Dynamic rows match on the path with res:// and any trailing slash removed.
static func _norm(s: String) -> String:
	return s.trim_prefix("res://").rstrip("/")


static func _dev_match(r: Dictionary, lit: String) -> bool:
	return lit == r["path"] if r["exact"] else lit.begins_with(r["path"])
