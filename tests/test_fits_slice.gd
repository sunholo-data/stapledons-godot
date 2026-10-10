extends SceneTree

const Fits = preload("res://tools/fits_slice.gd")
var failures := 0
var passed := 0

func check(ok: bool, why: String) -> void:
	if ok:
		passed += 1
	else:
		failures += 1
		push_error(why)

func card(key: String, value: String) -> String:
	return (key.rpad(8) + "= " + value).rpad(80)

func header(file: FileAccess, cards: Array) -> void:
	var text := ""
	for c: String in cards:
		text += c
	text += "END".rpad(80)
	text = text.rpad(ceili(text.length() / 2880.0) * 2880)
	file.store_buffer(text.to_ascii_buffer())

func fixture(path: String, transpose: bool, ordering: String = "NEST") -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.big_endian = true
	header(f, [card("SIMPLE", "T"), card("BITPIX", "8"), card("NAXIS", "0")])
	header(f, [card("XTENSION", "'IMAGE'"), card("BITPIX", "-32"), card("NAXIS", "2"), card("NAXIS1", "3" if transpose else "12"), card("NAXIS2", "12" if transpose else "3"), card("EXTNAME", "'MEAN'"), card("NSIDE", "1"), card("ORDERING", "'%s'" % ordering), card("CTYPE1", "'radius'" if transpose else "'plane of sky'"), card("CTYPE2", "'plane of sky'" if transpose else "'radius'")])
	for i in 36:
		var pix: int = i / 3 if transpose else i % 12
		var shell: int = i % 3 if transpose else i / 12
		f.store_float(0.125 + 100.0 * shell + pix)
	while f.get_position() % 2880 != 0:
		f.store_8(0)
	for which: String in ["RADIAL PIXEL CENTERS", "RADIAL PIXEL BOUNDARIES"]:
		var values := [70.0, 120.0, 170.0] if which.ends_with("CENTERS") else [60.0, 90.0, 150.0, 190.0]
		header(f, [card("XTENSION", "'BINTABLE'"), card("BITPIX", "8"), card("NAXIS", "2"), card("NAXIS1", "4"), card("NAXIS2", str(values.size())), card("TFIELDS", "1"), card("TFORM1", "'E'"), card("EXTNAME", "'%s'" % which), card("CUNIT", "'pc'")])
		for v: float in values:
			f.store_float(v)
		while f.get_position() % 2880 != 0:
			f.store_8(0)
	f.close()

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://.godot/tmp/fits-test")
	for transpose: bool in [false, true]:
		var p := "res://.godot/tmp/fits-test/%s.fits" % transpose
		fixture(p, transpose)
		var r: Dictionary = Fits.inspect(p)
		check(r.get("error", "") == "", "valid extension FITS is accepted")
		check(r.get("ordering") == "NEST", "NEST ordering stays explicit")
		check(r.get("centres_pc") == [70.0, 120.0, 170.0], "radius table decoded big-endian")
		var out := p + ".slice"
		var result: Dictionary = Fits.slice(p, out, 160.0)
		check(result.get("shells") == 2, "160 pc crop retains two centres")
		var values := FileAccess.open(out + ".f32", FileAccess.READ)
		if values != null:
			values.big_endian = false
			for s in 2:
				for pix in 12:
					check(values.get_float() == 0.125 + 100.0 * s + pix, "little-endian shell-major output, axis order %s" % transpose)
		else:
			check(false, "crop file exists")
		var meta: Variant = JSON.parse_string(FileAccess.get_file_as_string(out + ".json"))
		check(meta is Dictionary and meta.get("ordering") == "NEST", "crop metadata preserves ordering")
	var bad := "res://.godot/tmp/fits-test/bad.fits"
	fixture(bad, false, "UNKNOWN")
	check(Fits.inspect(bad).has("error"), "unknown HEALPix ordering refused")
	var trunc := FileAccess.open(bad, FileAccess.WRITE)
	trunc.store_string("SIMPLE")
	trunc.close()
	check(Fits.inspect(bad).has("error"), "truncated header refused")
	print("fits-slice: %d passed, %d failures" % [passed, failures])
	quit(1 if failures else 0)
