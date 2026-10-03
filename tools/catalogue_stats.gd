extends SceneTree
## Catalogue tier statistics (M1.2c; replaces the planned catalogue_stats.py, plan F3).
##   godot --headless --path . --script tools/catalogue_stats.gd -- [--tier quick|medium|large|bright] [--dir DIR]
## Without --tier: every tier present in DIR (default res://data/starmap; quick, medium and bright
## are committed, large is built on demand). Each tier is read through sky/star_catalogue.gd, so the
## sidecar format, count and sha256 are checked first. Per tier it prints
##   count; count_excluded (sidecar: missing-photometry rows the medium quota passed over; they
##   are not in the bin); complete rows; the M-dwarf share of complete rows; white dwarfs;
##   rows with Hipparcos photometry (flag 8, M1.2d); defaulted-photometry violations: rows where (teff == 0 and v == 99) does not equal the
##   MISSING_PHOT flag (both directions, every record); flags outside StarCatalogue.FLAG_SETS.
## Exit 0 iff every tier loads with 0 violations and 0 unknown flags (AC2's clause), and the medium
## tier's M-dwarf share is >= 60% (AC3). With --tier medium, only the medium tier is judged.

const StarCat := preload("res://sky/star_catalogue.gd")
## M dwarfs: teff below 3,900 K, the M0V boundary of Pecaut & Mamajek (2013, ApJS 208, 9; the
## Mamajek "modern mean dwarf" table, M0V = 3,850-3,900 K).
const M_DWARF_TEFF := 3900.0
const AC3_MIN_SHARE := 0.60
const TIERS := ["quick", "medium", "large", "bright"]


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var tier := ""
	var dir := "res://data/starmap"
	var i := 0
	while i < a.size():
		if a[i] == "--tier" and i + 1 < a.size() and a[i + 1] in TIERS:
			tier = a[i + 1]; i += 2
		elif a[i] == "--dir" and i + 1 < a.size():
			dir = a[i + 1]; i += 2
		else:
			printerr("usage: catalogue_stats.gd -- [--tier quick|medium|large|bright] [--dir DIR] (got %s)" % [a])
			quit(2); return
	var tiers: Array = [tier] if tier != "" else TIERS.filter(
		func(t: String) -> bool: return t != "large" or FileAccess.file_exists("%s/stars_large.bin" % dir))
	var ok := true
	for t: String in tiers:
		ok = report(t, dir) and ok
	print("catalogue-stats: %s" % ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)


func report(tier: String, dir: String) -> bool:
	var c := StarCat.load_tier(tier, dir)
	if c == null:
		print("%-6s  REFUSED: %s" % [tier, StarCat.last_error])
		return false
	var complete := 0
	var m_dwarfs := 0
	var wd := 0
	var hip := 0
	var violations := 0
	var unknown := {}
	for i in c.count:
		var f := c.flags(i)
		if not f in StarCat.FLAG_SETS:
			unknown[f] = int(unknown.get(f, 0)) + 1
		var defaulted := c.teff(i) == 0.0 and c.vmag(i) == 99.0
		if defaulted != c.missing_photometry(i):
			violations += 1
		if c.white_dwarf(i):
			wd += 1
		if c.hip_photometry(i):
			hip += 1
		if not c.missing_photometry(i):
			complete += 1
			if c.teff(i) < M_DWARF_TEFF:
				m_dwarfs += 1
	var share := float(m_dwarfs) / complete if complete > 0 else 0.0
	print("%-6s  count %d  excluded %d  complete %d  M-dwarf share %.1f%% (%d, teff < %d K)  white dwarfs %d  HIP photometry %d  defaulted-photometry violations %d  unknown flags %s" % [
		tier, c.count, int(c.sidecar.get("count_excluded", -1)), complete, 100.0 * share, m_dwarfs,
		int(M_DWARF_TEFF), wd, hip, violations, unknown if unknown.size() > 0 else "none"])
	var ok := violations == 0 and unknown.is_empty()
	if tier == "medium" and share < AC3_MIN_SHARE:
		print("medium  AC3 FAIL: M-dwarf share %.1f%% < %d%%" % [100.0 * share, int(100 * AC3_MIN_SHARE)])
		ok = false
	return ok
