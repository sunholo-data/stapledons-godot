extends SceneTree
const Fits = preload("res://tools/observation_fits.gd")
var passed := 0
var failed := 0

func check(ok: bool, label: String) -> void:
	if ok: passed += 1; print("ok ", label)
	else: failed += 1; printerr("FAIL ", label)

func fixture(bitpix := -32, values := [-0.25, 0.0, 1.5, 11.0]) -> PackedByteArray:
	var head := ""
	for pair in [["SIMPLE", "T"], ["BITPIX", str(bitpix)], ["NAXIS", "2"], ["NAXIS1", "2"], ["NAXIS2", "2"], ["CTYPE1", "'RA---TAN'"], ["CTYPE2", "'DEC--TAN'"]]:
		head += (str(pair[0]).rpad(8) + "= " + str(pair[1]).lpad(20)).rpad(80)
	head += "END".rpad(80)
	head = head.rpad(2880)
	var stream := StreamPeerBuffer.new()
	stream.big_endian = true
	for v in values: stream.put_float(v)
	return head.to_ascii_buffer() + stream.data_array

func _init() -> void:
	var result: Dictionary = Fits.decode(fixture())
	check(result.get("ok", false), "supported uncompressed primary float image decoded")
	if result.get("ok", false):
		var image: Image = result.image
		check(image.get_width() == 2 and image.get_height() == 2, "dimensions decoded")
		check(image.get_pixel(0, 0).r == -0.25 and image.get_pixel(1, 1).r == 11.0, "big endian floats and negative calibrated flux retained")
	check(not Fits.decode(fixture(16)).get("ok", false), "unsupported integer FITS rejected")
	check(not Fits.decode(fixture(-32, [NAN, 0.0, 0.0, 0.0])).get("ok", false), "non-finite pixel rejected")
	var short := fixture()
	short.resize(2881)
	check(not Fits.decode(short).get("ok", false), "truncated pixel data rejected")
	check(not Fits.decode(PackedByteArray([1,2,3])).get("ok", false), "non-FITS input rejected")
	print("observation-fits-test: %d passed, %d failures" % [passed, failed])
	quit(1 if failed else 0)
