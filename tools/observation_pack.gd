extends RefCounted
## TS0: check pinned observation bytes and independently recorded registration evidence.
## No coordinate formula lives here. The actual projection is package-owned (TS1).

static func _text(row: Dictionary, key: String) -> bool:
	return row.get(key) is String and not row[key].strip_edges().is_empty()

static func _number(x: Variant) -> bool:
	return (x is float or x is int) and is_finite(float(x))

static func _pin(row: Dictionary, out: Array[String], context: String) -> bool:
	if not _text(row, "path") or not _text(row, "sha256"):
		out.append(context + ": missing file/hash")
		return false
	var path: String = row.path
	if not FileAccess.file_exists(path) or FileAccess.get_sha256(path) != row.sha256:
		out.append(context + ": missing or changed file " + path)
		return false
	return true

static func _registration(plate: Dictionary, out: Array[String]) -> bool:
	var context: String = str(plate.get("id", "plate"))
	var r: Variant = plate.get("registration")
	if not r is Dictionary or r.get("projection") != "TAN":
		out.append(context + ": no supported TAN registration")
		return false
	var before := out.size()
	for key in ["reference_url", "oracle", "observed_at"]:
		if not _text(r, key): out.append(context + ": missing registration " + key)
	if not r.get("reference") is Dictionary or not _pin(r.reference, out, context + " reference"):
		out.append(context + ": no pinned independent reference")
	var anchors: Variant = r.get("anchors")
	if not anchors is Array or anchors.size() < 5:
		out.append(context + ": at least five independent anchors required")
	else:
		var seen := {}
		for anchor: Variant in anchors:
			if not anchor is Dictionary:
				out.append(context + ": invalid anchor")
				continue
			var id: Variant = anchor.get("source_id")
			if not id is String or id.is_empty() or seen.has(id):
				out.append(context + ": missing/duplicate anchor identity")
			seen[id] = true
			for key in ["source_x", "source_y", "reference_x", "reference_y", "residual_px"]:
				if not _number(anchor.get(key)): out.append(context + ": non-finite anchor " + key)
			if _number(anchor.get("residual_px")) and (anchor.residual_px < 0.0 or anchor.residual_px > 1.0):
				out.append(context + ": registration exceeds one source pixel")
			if ["source_x", "source_y", "reference_x", "reference_y", "residual_px"].all(func(key): return _number(anchor.get(key))):
				var dx: float = float(anchor.source_x) - float(anchor.reference_x)
				var dy: float = float(anchor.source_y) - float(anchor.reference_y)
				if absf(sqrt(dx * dx + dy * dy) - float(anchor.residual_px)) > 0.000001:
					out.append(context + ": reported residual disagrees with measured coordinates")
	var levels: Array = plate.get("levels", [])
	if levels.size() < 2: out.append(context + ": two verified zoom levels required")
	var sizes := {}
	for level: Variant in levels:
		if level is Dictionary: sizes[str(level.get("width", 0)) + "x" + str(level.get("height", 0))] = true
	if sizes.size() < 2: out.append(context + ": zoom levels need distinct sampled resolutions")
	return before == out.size()

static func errors(pack: Dictionary, require_registered := true) -> Array[String]:
	var out: Array[String] = []
	if pack.get("format_version") != 1: out.append("unsupported observation pack version")
	for key in ["id", "release", "doi", "retrieved"]:
		if not _text(pack, key): out.append("missing pack " + key)
	var plates: Variant = pack.get("plates")
	if not plates is Array or plates.is_empty():
		out.append("no observation plates")
		return out
	var ids := {}
	var registered := 0
	for value: Variant in plates:
		if not value is Dictionary:
			out.append("invalid plate record")
			continue
		var plate: Dictionary = value
		for key in ["id", "source_url", "licence", "credit"]:
			if not _text(plate, key): out.append("missing plate " + key)
		var id: String = str(plate.get("id", ""))
		if ids.has(id): out.append("duplicate plate " + id)
		ids[id] = true
		if not plate.get("registered") is bool: out.append(id + ": registered must be explicit")
		if plate.get("registered", false) and _registration(plate, out): registered += 1
		var levels: Variant = plate.get("levels")
		if not levels is Array or levels.is_empty():
			out.append(id + ": no image levels")
			continue
		for level: Variant in levels:
			if not level is Dictionary:
				out.append(id + ": invalid image level")
				continue
			if not _pin(level, out, id): continue
			var image := Image.new()
			if image.load(level.path) != OK:
				out.append(id + ": image decode failed")
			elif image.get_width() != level.get("width", 0) or image.get_height() != level.get("height", 0):
				out.append(id + ": decoded image dimensions disagree")
	if require_registered and registered == 0: out.append("starter has no verified registered field")
	var objects: Variant = pack.get("objects", [])
	if not objects is Array:
		out.append("invalid object list")
		return out
	var object_ids := {}
	for row: Variant in objects:
		if not row is Dictionary:
			out.append("invalid object record")
			continue
		if not _text(row, "id") or object_ids.has(row.get("id")):
			out.append("missing/duplicate/string-required object identity")
		object_ids[row.get("id")] = true
		if not ids.has(row.get("plate_id", "")): out.append("unknown object plate")
		if not _number(row.get("ra_deg")) or not _number(row.get("dec_deg")):
			out.append("non-finite object coordinates")
		elif row.ra_deg < 0 or row.ra_deg >= 360 or absf(row.dec_deg) > 90:
			out.append("out-of-range object coordinates")
	return out
