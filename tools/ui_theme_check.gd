extends SceneTree
## R2-BRIDGE-STYLE AC6/AC7 (design_docs/planned/r2/bridge-styling-pass.md §S4): the HUD's one theme.
##   1. Leftovers: no `StyleBoxFlat.new()` and no `add_theme_color_override` in ui/ or in the demo's HUD
##      code (demos/ship_geometry_demo.gd, demos/ship_consoles.gd) outside the theme builder; the crew
##      palette (D-80) and the physics overlays (OQ5) are explicit allow-lists (ui/theme/allow.json).
##      Until ST4 this is a report (counts per file); --strict makes any leftover a failure.
##   2. Assets: the two OFL typefaces, their licences and the ink panel border are present and match
##      their sha256 pins (ui/theme/pins.json).
##   3. Contrast: every theme type's text colour is at least WCAG 4.5:1 on its panel, the panel
##      composited over both the night ground and the cream deck (the brightest thing behind a panel).
## Usage: godot --headless --path . --script tools/ui_theme_check.gd -- [--strict] [--scan=<res dir or file>,...]
##        [--theme-builder=res://ui/stapledon_theme.gd] [--pins=res://ui/theme/pins.json]
const BUILDER := "res://ui/stapledon_theme.gd"
const PINS := "res://ui/theme/pins.json"
const ALLOW := "res://ui/theme/allow.json"
const SCAN := ["res://ui", "res://demos/ship_geometry_demo.gd", "res://demos/ship_consoles.gd"]
const PATTERNS := ["StyleBoxFlat.new()", "add_theme_color_override"]
const WCAG_MIN := 4.5
const NIGHT := Color("#0B0D16")
const CREAM := Color("#EFE3C8")
var fails := 0


func _initialize() -> void:
	_run.call_deferred()


func fail(msg: String) -> void:
	fails += 1
	print("FAIL " + msg)


func _run() -> void:
	var strict := false
	var scan: Array = SCAN.duplicate()
	var builder := BUILDER
	var pins := PINS
	for a in OS.get_cmdline_user_args():
		if a == "--strict": strict = true
		elif a.begins_with("--scan="): scan = Array(a.trim_prefix("--scan=").split(","))
		elif a.begins_with("--theme-builder="): builder = a.trim_prefix("--theme-builder=")
		elif a.begins_with("--pins="): pins = a.trim_prefix("--pins=")
	# 1. Leftovers.
	var allow := {}
	if FileAccess.file_exists(ALLOW):
		allow = JSON.parse_string(FileAccess.get_file_as_string(ALLOW))
	var total := 0
	var per_file := {}
	for root_path: String in scan:
		for f: String in _gd_files(root_path):
			if f == builder or f in allow.get("files", []):
				continue
			var lines := FileAccess.get_file_as_string(f).split("\n")
			for i in lines.size():
				var line: String = lines[i]
				if line.strip_edges().begins_with("#"): continue
				for p: String in PATTERNS:
					if line.contains(p) and not _allowed(allow, f, line):
						total += 1
						per_file[f] = per_file.get(f, 0) + 1
	for f in per_file:
		print("leftover %s: %d" % [f, per_file[f]])
	if strict and total > 0:
		fail("%d hard-coded panel styles or colour overrides outside the theme (--strict)" % total)
	else:
		print("ui-theme-check: leftovers %d in %d files (%s)" % [total, per_file.size(), "strict" if strict else "report until ST4"])
	# 2. Assets and pins.
	if not FileAccess.file_exists(pins):
		fail("no theme pins (%s)" % pins)
	else:
		var p: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(pins))
		for path: String in p.get("files", {}):
			var want: String = p.files[path]
			if not FileAccess.file_exists(path): fail("missing %s" % path)
			elif FileAccess.get_sha256(path) != want: fail("pin mismatch %s" % path)
		for lic: String in p.get("licences", []):
			if not FileAccess.file_exists(lic) or not FileAccess.get_file_as_string(lic).contains("SIL Open Font License"):
				fail("missing OFL licence %s" % lic)
		if p.get("files", {}).size() < 3: fail("pins must cover the two typefaces and the ink border")
	# 3. Contrast.
	if not FileAccess.file_exists(builder):
		fail("no theme builder (%s)" % builder)
	else:
		var b: GDScript = load(builder)
		var theme: Theme = b.build()
		var pairs: Array = b.text_pairs()
		if pairs.is_empty(): fail("the theme declares no text/panel pairs")
		for pr: Dictionary in pairs:
			var fg: Color = theme.get_color(pr.color, pr.type)
			var sb := theme.get_stylebox(pr.panel_slot, pr.panel_type)
			var bg: Color = _panel_colour(sb)
			for ground: Color in [NIGHT, CREAM]:
				var under := Color(bg.r * bg.a + ground.r * (1.0 - bg.a), bg.g * bg.a + ground.g * (1.0 - bg.a), bg.b * bg.a + ground.b * (1.0 - bg.a))
				var top := Color(fg.r * fg.a + under.r * (1.0 - fg.a), fg.g * fg.a + under.g * (1.0 - fg.a), fg.b * fg.a + under.b * (1.0 - fg.a))
				var cr := contrast(top, under)
				if cr < WCAG_MIN:
					fail("contrast %.2f:1 < %.1f for %s.%s on %s over %s" % [cr, WCAG_MIN, pr.type, pr.color, pr.panel_type, ground.to_html(false)])
		print("ui-theme-check: contrast checked for %d text/panel pairs over night and cream" % pairs.size())
	print("ui-theme-check: %s" % ("FAIL" if fails else "ok"))
	quit(1 if fails else 0)


static func _panel_colour(sb: StyleBox) -> Color:
	if sb is StyleBoxFlat: return (sb as StyleBoxFlat).bg_color
	if sb is StyleBoxTexture:
		var t := sb as StyleBoxTexture
		var c: Color = t.get_meta("panel_colour", Color(0, 0, 0, 0))
		return Color(c.r * t.modulate_color.r, c.g * t.modulate_color.g, c.b * t.modulate_color.b, c.a * t.modulate_color.a)
	return Color(0, 0, 0, 0)


## WCAG 2.x relative luminance contrast ratio.
static func contrast(a: Color, b: Color) -> float:
	var la := _lum(a)
	var lb := _lum(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


static func _lum(c: Color) -> float:
	var f := func(v: float) -> float: return v / 12.92 if v <= 0.03928 else pow((v + 0.055) / 1.055, 2.4)
	return 0.2126 * f.call(c.r) + 0.7152 * f.call(c.g) + 0.0722 * f.call(c.b)


func _allowed(allow: Dictionary, f: String, line: String) -> bool:
	for rule: Dictionary in allow.get("lines", []):
		if rule.file == f and line.contains(rule.contains):
			return true
	return false


func _gd_files(path: String) -> Array:
	if path.ends_with(".gd"):
		return [path] if FileAccess.file_exists(path) else []
	var out := []
	var d := DirAccess.open(path)
	if d == null: return out
	for f in d.get_files():
		if f.ends_with(".gd"): out.append(path.path_join(f))
	for sub in d.get_directories():
		out.append_array(_gd_files(path.path_join(sub)))
	return out
