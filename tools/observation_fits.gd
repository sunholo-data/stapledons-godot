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
	var unsupported := _unsupported_header(header)
	if not unsupported.is_empty():return _error(unsupported)
	if header.get("SIMPLE") != "T" or header.get("BITPIX") != "-32" or header.get("NAXIS") != "2":
		return _error("only simple uncompressed 2D float32 cutouts supported")
	var width_text := str(header.get("NAXIS1", ""))
	var height_text := str(header.get("NAXIS2", ""))
	if not width_text.is_valid_int() or not height_text.is_valid_int(): return _error("invalid dimensions")
	var width := width_text.to_int()
	var height := height_text.to_int()
	if width <= 0 or height <= 0 or width > MAX_DIMENSION or height > MAX_DIMENSION or width * height > MAX_PIXELS:
		return _error("cutout exceeds 2048 squared pixel bound")
	var scale := _header_number(header.get("BSCALE","1"))
	var zero := _header_number(header.get("BZERO","0"))
	if not scale.ok or not zero.ok or scale.value != 1.0 or zero.value != 0.0:
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

# Only the undistorted CD-matrix ICRS TAN subset mirrored by celestial is trusted.
# Image bytes and registration metadata are checked separately: a matching hash
# alone cannot prove the manifest copied the authoritative WCS correctly.
static func _unsupported_header(header: Dictionary) -> String:
	for key: String in header:
		if key.begins_with("PV1_") or key.begins_with("PV2_") or key.begins_with("PS1_") or key.begins_with("PS2_") or key.begins_with("A_") or key.begins_with("B_") or key.begins_with("AP_") or key.begins_with("BP_") or key.begins_with("CPDIS") or key.begins_with("CQDIS") or key.begins_with("D2IM") or key.begins_with("DP1") or key.begins_with("DP2"):
			return "unsupported FITS distortion keyword " + key
	for key: String in header:
		if key.begins_with("PC1_") or key.begins_with("PC2_") or key in ["CDELT1","CDELT2","CROTA1","CROTA2","LONPOLE","LATPOLE"]:return "unsupported FITS WCS encoding " + key
	for key in ["CTYPE1","CTYPE2"]:
		if header.has(key) and str(header[key]).contains("-SIP"):return "unsupported SIP celestial projection"
	return ""

static func _header_number(value) -> Dictionary:
	var text := str(value).replace("D","E").replace("d","e")
	if not text.is_valid_float():return {"ok":false}
	var number := text.to_float()
	return {"ok":is_finite(number),"value":number}

static func registration_errors(header: Dictionary, registration: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	var unsupported := _unsupported_header(header)
	if not unsupported.is_empty():errors.append(unsupported)
	if registration.get("projection") != "TAN" or registration.get("frame") != "ICRS":errors.append("manifest requires unsupported celestial frame/projection")
	if header.get("CTYPE1") != "RA---TAN" or header.get("CTYPE2") != "DEC--TAN":errors.append("FITS CTYPE must be RA---TAN/DEC--TAN")
	if header.get("RADESYS") != "ICRS":errors.append("FITS RADESYS must explicitly identify ICRS")
	for key in ["CUNIT1","CUNIT2"]:
		if header.has(key) and str(header[key]).to_lower() != "deg":errors.append("FITS celestial units must be degrees")
	if header.has("EQUINOX"):
		var equinox := _header_number(header.EQUINOX)
		if not equinox.ok or equinox.value != 2000.:errors.append("unsupported FITS equinox")
	var wcs = registration.get("wcs")
	if not wcs is Dictionary:errors.append("missing manifest WCS");return errors
	var mapping := {"NAXIS1":"width","NAXIS2":"height","CRPIX1":"crpixX","CRPIX2":"crpixY","CRVAL1":"crvalRaDeg","CRVAL2":"crvalDecDeg","CD1_1":"cd11","CD1_2":"cd12","CD2_1":"cd21","CD2_2":"cd22"}
	for key: String in mapping:
		var observed := _header_number(header.get(key,""))
		var expected = registration.get(mapping[key]) if key.begins_with("NAXIS") else wcs.get(mapping[key])
		if not observed.ok or not (expected is float or expected is int) or not is_finite(float(expected)):
			errors.append("missing/nonfinite FITS or manifest coefficient " + key)
		elif absf(observed.value-float(expected)) > maxf(absf(float(expected)),1e-10)*1e-12:
			errors.append("manifest disagrees with authoritative FITS " + key)
	return errors
