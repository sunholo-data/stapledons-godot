extends SceneTree
## I3b: FITS I/O only. MEAN float32 image + authoritative radial tables -> shell-major
## little-endian float32, preserving HEALPix NEST/RING ordering and source units.
## No assumed primary-HDU layout, axis order, logarithmic radii or gas conversion.

static func _value(card: String) -> String:
	var s := card.substr(10).strip_edges()
	if s.begins_with("'"):
		var end := s.find("'", 1)
		return s.substr(1, end - 1).strip_edges() if end >= 0 else ""
	return s.split("/", true, 1)[0].strip_edges()

static func _hdus(f: FileAccess) -> Dictionary:
	var out: Array = []
	while f.get_position() < f.get_length():
		var start := f.get_position()
		var h: Dictionary = {}
		var ended := false
		for _i in 10000:
			if f.get_position() + 80 > f.get_length():
				return {"error": "truncated FITS header"}
			var c := f.get_buffer(80).get_string_from_ascii()
			var key := c.substr(0, 8).strip_edges()
			if key == "END":
				ended = true
				break
			if c.substr(8, 1) == "=":
				h[key] = _value(c)
		if not ended:
			return {"error": "FITS header lacks END"}
		var header_bytes := ceili((f.get_position() - start) / 2880.0) * 2880
		var size := absi(int(h.get("BITPIX", 0))) / 8 if int(h.get("NAXIS", 0)) > 0 else 0
		for i in range(1, int(h.get("NAXIS", 0)) + 1):
			size *= int(h.get("NAXIS%d" % i, 0))
		size = (size + int(h.get("PCOUNT", 0))) * int(h.get("GCOUNT", 1))
		h["offset"] = start + header_bytes
		h["bytes"] = size
		if size < 0 or h.offset + size > f.get_length():
			return {"error": "truncated FITS data"}
		out.append(h)
		f.seek(h.offset + ceili(size / 2880.0) * 2880)
	return {"hdus": out}

static func _radii(f: FileAccess, h: Dictionary) -> Array:
	if h.get("XTENSION") != "BINTABLE" or int(h.get("TFIELDS", 0)) != 1 or h.get("TFORM1") != "E" or int(h.get("NAXIS1", 0)) != 4 or h.get("CUNIT") != "pc":
		return []
	f.seek(h.offset)
	var out: Array = []
	for _i in int(h.NAXIS2):
		out.append(f.get_float())
	return out

static func inspect(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {"error": "cannot open FITS: " + path}
	f.big_endian = true
	var parsed := _hdus(f)
	if parsed.has("error"):
		return parsed
	var mean: Dictionary = {}
	var centres: Array = []
	var bounds: Array = []
	for h: Dictionary in parsed.hdus:
		match h.get("EXTNAME", ""):
			"MEAN": mean = h
			"RADIAL PIXEL CENTERS": centres = _radii(f, h)
			"RADIAL PIXEL BOUNDARIES": bounds = _radii(f, h)
	if int(mean.get("BITPIX", 0)) != -32 or int(mean.get("NAXIS", 0)) != 2:
		return {"error": "MEAN must be a float32 image with two axes"}
	var nside := int(mean.get("NSIDE", 0))
	var pixels := 12 * nside * nside
	var ordering := str(mean.get("ORDERING", ""))
	if nside <= 0 or ordering not in ["NEST", "NESTED", "RING"]:
		return {"error": "invalid NSIDE or unsupported HEALPix ordering"}
	var sky_axis := 1 if mean.get("CTYPE1") == "plane of sky" else 2
	var radial_axis := 3 - sky_axis
	if mean.get("CTYPE%d" % radial_axis) != "radius" or int(mean.get("NAXIS%d" % sky_axis, 0)) != pixels or int(mean.get("NAXIS%d" % radial_axis, 0)) != centres.size() or bounds.size() != centres.size() + 1:
		return {"error": "axes or radial tables do not match MEAN"}
	for i in centres.size():
		if not is_finite(float(centres[i])) or not (float(bounds[i]) < float(centres[i]) and float(centres[i]) < float(bounds[i + 1])):
			return {"error": "invalid radial centre/boundary ordering"}
	return {"nside": nside, "pixels": pixels, "ordering": ordering, "sky_axis": sky_axis, "centres_pc": centres, "boundaries_pc": bounds, "mean": mean, "units": mean.get("CUNIT", "")}

static func slice(path: String, prefix: String, max_pc: float = 160.0) -> Dictionary:
	var meta := inspect(path)
	if meta.has("error"):
		return meta
	var shells := 0
	for r: float in meta.centres_pc:
		if r < max_pc:
			shells += 1
	if shells == 0:
		return {"error": "empty radial crop"}
	var src := FileAccess.open(path, FileAccess.READ)
	var out := FileAccess.open(prefix + ".f32", FileAccess.WRITE)
	if out == null:
		return {"error": "cannot create crop"}
	src.big_endian = true
	out.big_endian = false
	var mean: Dictionary = meta.mean
	var scale := float(mean.get("BSCALE", 1.0))
	var zero := float(mean.get("BZERO", 0.0))
	for shell in shells:
		if meta.sky_axis == 1:
			src.seek(int(mean.offset) + shell * int(meta.pixels) * 4)
		for pix in int(meta.pixels):
			if meta.sky_axis == 2:
				src.seek(int(mean.offset) + (pix * meta.centres_pc.size() + shell) * 4)
			var v := src.get_float() * scale + zero
			if not is_finite(v):
				return {"error": "non-finite MEAN pixel"}
			out.store_float(v)
	out.close()
	meta.erase("mean")
	meta["source"] = path
	meta["shells"] = shells
	meta["centres_pc"] = meta.centres_pc.slice(0, shells)
	meta["boundaries_pc"] = meta.boundaries_pc.slice(0, shells + 1)
	meta["format"] = "float32 little-endian, index=shell*pixels+pixel; source HEALPix ordering preserved"
	meta["max_pc"] = max_pc
	var sidecar := FileAccess.open(prefix + ".json", FileAccess.WRITE)
	if sidecar == null:
		return {"error": "cannot create crop metadata"}
	sidecar.store_string(JSON.stringify(meta, "\t") + "\n")
	return meta

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2:
		printerr("usage: godot --headless --script tools/fits_slice.gd -- source.fits output-prefix")
		quit(2)
		return
	var result := slice(args[0], args[1])
	if result.has("error"):
		printerr("fits-slice: " + result.error)
		quit(1)
	else:
		print("fits-slice: %d shells, NSIDE %d %s -> %s" % [result.shells, result.nside, result.ordering, args[1]])
		quit(0)
