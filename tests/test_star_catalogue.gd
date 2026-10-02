extends SceneTree
## Binary tier loader (sky/star_catalogue.gd, M1.2c). Run:
##   godot --headless --path . --script tests/test_star_catalogue.gd
## A 2-record tier is built here byte by byte with encode_float (always little-endian), so stride
## (24 B), field order and endianness are checked against bytes the loader did not write. Every
## refusal path is then exercised on a corrupted copy. Exits non-zero on any failure.

const StarCat := preload("res://sky/star_catalogue.gd")
const DIR := "user://test_star_catalogue"

var failures := 0
var passes := 0

## two records, deliberately different in every field (flags 21 and 2 are real flag values)
const ROWS := [
	[1.5, -2.25, 3.0e3, 3150.0, 9.75, 21.0],
	[-4.0e5, 0.125, -7.5, 0.0, 99.0, 2.0],
]


func check(name: String, ok: bool, detail := "") -> void:
	if ok:
		passes += 1
		print("  ok    %s" % name)
	else:
		failures += 1
		print("  FAIL  %s %s" % [name, detail])


func le_bytes(rows: Array) -> PackedByteArray:
	var b := PackedByteArray()
	b.resize(rows.size() * 24)
	for r in rows.size():
		for f in 6:
			b.encode_float(24 * r + 4 * f, rows[r][f])
	return b


func sha(b: PackedByteArray) -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	if b.size() > 0:
		ctx.update(b)
	return ctx.finish().hex_encode()


func sidecar(n: int, bin_sha: String) -> Dictionary:
	return {"tier": "test", "count": n, "count_excluded": 0, "format_version": 1, "record_bytes": 24,
		"fields": ["x", "y", "z", "teff", "v", "flags"], "sha256": {"raw": "", "csv": "", "bin": bin_sha}}


func write(name: String, b: PackedByteArray, meta: Dictionary) -> void:
	var f := FileAccess.open("%s/%s.bin" % [DIR, name], FileAccess.WRITE)
	f.store_buffer(b)
	f.close()
	f = FileAccess.open("%s/%s.json" % [DIR, name], FileAccess.WRITE)
	f.store_string(JSON.stringify(meta))
	f.close()


func open(name: String) -> StarCatalogue:
	return StarCat.from_files("%s/%s.bin" % [DIR, name], "%s/%s.json" % [DIR, name])


func refuses(name: String, b: PackedByteArray, meta: Dictionary, needle: String) -> void:
	write(name, b, meta)
	var c := open(name)
	check("refuses %s" % name, c == null and StarCat.last_error.contains(needle),
		"(got %s, error '%s')" % [c, StarCat.last_error])


## tools/catalogue_stats.gd on synthetic tiers: it must fail each AC2/AC3 breach, not only pass real data.
func stats(rows: Array, tier: String) -> Array:
	var sub := "%s/stats_%s_%d" % [DIR, tier, rows.hash()]
	DirAccess.make_dir_recursive_absolute(sub)
	var b := le_bytes(rows)
	var f := FileAccess.open("%s/stars_%s.bin" % [sub, tier], FileAccess.WRITE); f.store_buffer(b); f.close()
	f = FileAccess.open("%s/stars_%s.json" % [sub, tier], FileAccess.WRITE)
	f.store_string(JSON.stringify(sidecar(rows.size(), sha(b)))); f.close()
	var out := []
	var rc := OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"),
		"--script", "res://tools/catalogue_stats.gd", "--", "--tier", tier, "--dir", ProjectSettings.globalize_path(sub)], out, true)
	return [rc, "".join(out)]


func stats_cases() -> void:
	var m := [0.0, 0.0, 1.0, 3100.0, 11.0, 0.0]   # complete M dwarf
	var g := [0.0, 1.0, 0.0, 5800.0, 4.8, 0.0]    # complete G dwarf
	var missing := [1.0, 0.0, 0.0, 0.0, 99.0, 2.0]
	var r := stats([m, m, g, missing], "quick")
	check("stats passes a clean tier", r[0] == 0 and r[1].contains("M-dwarf share 66.7%"), str(r))
	r = stats([m, [1.0, 0.0, 0.0, 0.0, 99.0, 0.0]], "quick")
	check("stats fails defaulted photometry without MISSING_PHOT", r[0] == 1 and r[1].contains("violations 1"), str(r))
	r = stats([m, [1.0, 0.0, 0.0, 3000.0, 12.0, 2.0]], "quick")
	check("stats fails MISSING_PHOT without defaulted photometry", r[0] == 1 and r[1].contains("violations 1"), str(r))
	r = stats([m, [1.0, 0.0, 0.0, 9000.0, 11.0, 1.0]], "quick")
	check("stats fails a flags value convert() never writes (whiteDwarf guard)", r[0] == 1 and r[1].contains("unknown flags { 1: 1 }"), str(r))
	r = stats([m, g, g], "medium")
	check("stats fails medium below the AC3 60% M-dwarf share", r[0] == 1 and r[1].contains("AC3 FAIL"), str(r))
	r = stats([m, m, m, g, g], "medium")
	check("stats passes medium at 60% M dwarfs", r[0] == 0 and r[1].contains("M-dwarf share 60.0%"), str(r))


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	check("host little-endian (the tier format's byte order)", StarCat.little_endian_host())
	var b := le_bytes(ROWS)
	check("fixture is 2 x 24 B", b.size() == 48)
	# byte 0..3 of record 0 is x = 1.5 = 0x3fc00000 LE
	check("fixture x0 bytes are LE", b.slice(0, 4) == PackedByteArray([0, 0, 0xc0, 0x3f]))
	write("good", b, sidecar(2, sha(b)))
	var c := open("good")
	check("loads a valid 2-record tier", c != null, StarCat.last_error)
	if c != null:
		check("count 2", c.count == 2 and c.data.size() == 12)
		check("record 0 position (stride 0)", c.position(0) == Vector3(1.5, -2.25, 3.0e3), str(c.position(0)))
		check("record 1 position (stride 24 B)", c.position(1) == Vector3(-4.0e5, 0.125, -7.5), str(c.position(1)))
		check("teff/v/flags field order", c.teff(0) == 3150.0 and c.vmag(0) == 9.75 and c.flags(0) == 21
			and c.teff(1) == 0.0 and c.vmag(1) == 99.0 and c.flags(1) == 2)
		check("flag helpers", c.white_dwarf(0) and not c.missing_photometry(0)
			and c.missing_photometry(1) and not c.white_dwarf(1))
	write("empty", PackedByteArray(), sidecar(0, sha(PackedByteArray())))
	var e := open("empty")
	check("loads an empty tier", e != null and e.count == 0, StarCat.last_error)

	var good := sidecar(2, sha(b))
	var m := good.duplicate(true); m["format_version"] = 2
	refuses("format_version", b, m, "format_version")
	m = good.duplicate(true); m["record_bytes"] = 28
	refuses("record_bytes", b, m, "record_bytes")
	m = good.duplicate(true); m["fields"] = ["x", "y", "z", "v", "teff", "flags"]
	refuses("fields", b, m, "fields")
	m = good.duplicate(true); m["count"] = 3
	refuses("count", b, m, "sidecar count 3")
	refuses("truncated", b.slice(0, 40), good, "is 40 B")
	var flipped := b.duplicate(); flipped[30] ^= 1
	refuses("sha256", flipped, good, "sha256(bin)")
	m = good.duplicate(true); m.erase("sha256")
	refuses("no_sha", b, m, "sha256.bin")
	var f := FileAccess.open("%s/notjson.json" % DIR, FileAccess.WRITE); f.store_string("[1,2]"); f.close()
	f = FileAccess.open("%s/notjson.bin" % DIR, FileAccess.WRITE); f.store_buffer(b); f.close()
	check("refuses a non-object sidecar", open("notjson") == null and StarCat.last_error.contains("not a JSON object"))
	check("refuses a missing pair", open("absent") == null and StarCat.last_error.contains("cannot read sidecar"))

	stats_cases()
	# the committed tiers (M1.2c, D-3) load and agree with their sidecars
	for tier in ["quick", "medium"]:
		var t := StarCat.load_tier(tier)
		check("committed %s tier loads" % tier, t != null, StarCat.last_error)
		if t != null:
			check("committed %s count = sidecar = bytes / 24" % tier,
				t.count == int(t.sidecar["count"]) and t.data.size() == 6 * t.count and t.count > 0)
	print("test_star_catalogue: %d passed, %d failed" % [passes, failures])
	quit(0 if failures == 0 else 1)
