extends RefCounted
## Offline I/O for Euclid's documented small, uncompressed BITPIX=-32 primary cutout.
## Other FITS encodings/extensions are refused. Runtime uses prepared image tiles.
const MAX_DIMENSION := 2048
const MAX_PIXELS := MAX_DIMENSION * MAX_DIMENSION
const MAX_HEADER := 32 * 2880

static func _error(why: String) -> Dictionary:
	return {"ok": false, "error": why}

static func decode(bytes: PackedByteArray) -> Dictionary:
	if bytes.size() < 2880 or bytes.slice(0, 8).get_string_from_ascii() != "SIMPLE  ":
		return _error("not a FITS primary image")
	var header := {}
	var offset := 0
	var ended := false
	while offset + 80 <= mini(bytes.size(), MAX_HEADER):
		var card := bytes.slice(offset, offset + 80).get_string_from_ascii()
		offset += 80
		var key := card.substr(0, 8).strip_edges()
		if key == "END":
			ended = true
			break
		if card.substr(8, 2) != "= ": continue
		var value := card.substr(10).strip_edges()
		if value.begins_with("'"):
			value = value.substr(1).get_slice("'", 0).strip_edges()
		else:
			value = value.get_slice("/", 0).strip_edges()
		if header.has(key): return _error("duplicate header " + key)
		header[key] = value
	if not ended: return _error("missing bounded FITS END card")
	if header.get("SIMPLE") != "T" or header.get("BITPIX") != "-32" or header.get("NAXIS") != "2":
		return _error("only simple uncompressed 2D float32 cutouts supported")
	var width_text := str(header.get("NAXIS1", ""))
	var height_text := str(header.get("NAXIS2", ""))
	if not width_text.is_valid_int() or not height_text.is_valid_int(): return _error("invalid dimensions")
	var width := width_text.to_int()
	var height := height_text.to_int()
	if width <= 0 or height <= 0 or width > MAX_DIMENSION or height > MAX_DIMENSION or width * height > MAX_PIXELS:
		return _error("cutout exceeds 2048 squared pixel bound")
	if str(header.get("BSCALE", "1")).to_float() != 1.0 or str(header.get("BZERO", "0")).to_float() != 0.0:
		return _error("scaled FITS encoding not supported")
	offset = int(ceil(float(offset) / 2880.0)) * 2880
	var count := width * height
	if offset + count * 4 > bytes.size(): return _error("truncated FITS pixels")
	var input := StreamPeerBuffer.new()
	input.big_endian = true
	input.data_array = bytes.slice(offset, offset + count * 4)
	var values := PackedFloat32Array()
	values.resize(count)
	var lo := INF
	var hi := -INF
	for i in count:
		var value := input.get_float()
		if not is_finite(value): return _error("non-finite FITS pixel at %d" % i)
		values[i] = value
		lo = minf(lo, value)
		hi = maxf(hi, value)
	var image := Image.create_from_data(width, height, false, Image.FORMAT_RF, values.to_byte_array())
	return {"ok": true, "image": image, "header": header, "min": lo, "max": hi}
