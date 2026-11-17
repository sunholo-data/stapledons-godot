extends RefCounted
## Decoded RGBA8-equivalent storage with a full mip chain, not measured VRAM/frame cost.
static func mip_bytes(width: int, height: int) -> int:
	var total := 0
	while true:
		total += width * height * 4
		if width == 1 and height == 1: return total
		width = maxi(1, width >> 1); height = maxi(1, height >> 1)
	return total

static func measure(records: Array) -> Dictionary:
	var out := {"errors": PackedStringArray(), "metrics": {"disk_bytes": 0, "texture_bytes": 0, "max_dimension": 0, "files": 0, "meshes": 0, "surfaces": 0, "triangles": 0, "vertices": 0, "materials": 0}}
	var seen := {}
	for row: Dictionary in records:
		var path: String = row.path
		if seen.has(path): continue
		seen[path] = true
		if not FileAccess.file_exists(path): out.errors.append("missing_measured_resource: " + path); continue
		out.metrics.files += 1; out.metrics.disk_bytes += FileAccess.get_file_as_bytes(path).size()
		var ext: String = path.trim_suffix(".bin").get_extension()
		var image: Image = null
		if ext in ["png", "webp"]:
			image = Image.new()
			var bytes: PackedByteArray = FileAccess.get_file_as_bytes(path)
			var rc: int = image.load_png_from_buffer(bytes) if ext == "png" else image.load_webp_from_buffer(bytes)
			if rc != OK: out.errors.append("image_decode: " + path); continue
		elif ext in ["res", "tres"]:
			var native: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
			if native == null: out.errors.append("resource_decode: " + path); continue
			if native is Texture2D: image = native.get_image()
			elif native is Mesh:
				out.metrics.meshes += 1; out.metrics.surfaces += native.get_surface_count()
				out.metrics.triangles += native.get_faces().size() / 3
				for si: int in native.get_surface_count(): out.metrics.vertices += native.surface_get_array_len(si)
			elif native is Material: out.metrics.materials += 1
		if image != null:
			if image.is_empty(): out.errors.append("image_empty: " + path); continue
			out.metrics.max_dimension = maxi(out.metrics.max_dimension, maxi(image.get_width(), image.get_height()))
			out.metrics.texture_bytes += mip_bytes(image.get_width(), image.get_height())
	return out

static func budget_errors(actual: Dictionary, limits: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	for key: String in actual:
		var limit: Variant = limits.get(key)
		if not (limit is int or limit is float) or not is_finite(float(limit)) or float(limit) < 0 or floor(float(limit)) != float(limit):
			errors.append("budget_schema: " + key)
		elif actual[key] > limit: errors.append("budget_exceeded: " + key)
	return errors

static func captain_stages(records: Array) -> Dictionary:
	var groups := {}
	for row: Dictionary in records:
		if not row.path.ends_with(".webp") and not row.path.ends_with(".png"): continue
		var relative: String = row.path.trim_prefix("res://assets/characters/captain/")
		var stage: String = relative.get_slice("/", 1) if relative.begins_with("anim/") else "stills"
		if not groups.has(stage): groups[stage] = []
		groups[stage].append(row)
	var out := {}
	for stage: String in groups: out[stage] = measure(groups[stage])
	return out
