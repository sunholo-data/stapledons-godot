extends SceneTree
## Offline image/file I/O. No sky projection or scientific pixel model lives here.

static func _tile(source: Image, x: int, y: int, width: int, height: int) -> Image:
	var image := Image.create(width + 2, height + 2, false, Image.FORMAT_RGBA8)
	image.blit_rect(source, Rect2i(x, y, width, height), Vector2i.ONE)
	for tx in width + 2:
		var sx := clampi(x + tx - 1, 0, source.get_width() - 1)
		image.set_pixel(tx, 0, source.get_pixel(sx, maxi(y - 1, 0)))
		image.set_pixel(tx, height + 1, source.get_pixel(sx, mini(y + height, source.get_height() - 1)))
	for ty in range(1, height + 1):
		image.set_pixel(0, ty, source.get_pixel(maxi(x - 1, 0), y + ty - 1))
		image.set_pixel(width + 1, ty, source.get_pixel(mini(x + width, source.get_width() - 1), y + ty - 1))
	return image

static func build(source: Image, directory: String, tile_size := 512) -> Dictionary:
	if source == null or source.is_empty() or tile_size < 1 or tile_size > 512:
		return {"ok": false, "error": "invalid source image or tile size"}
	if DirAccess.make_dir_recursive_absolute(directory) != OK:
		return {"ok": false, "error": "cannot create tile directory"}
	var image: Image = source.duplicate()
	image.convert(Image.FORMAT_RGBA8)
	var result := {"ok": true, "format_version": 1, "tile_size": tile_size, "gutter": 1,
		"source_width": image.get_width(), "source_height": image.get_height(), "levels": []}
	var level := 0
	while true:
		var width := image.get_width()
		var height := image.get_height()
		var entry := {"level": level, "width": width, "height": height, "tiles": []}
		for ty in ceili(float(height) / tile_size):
			for tx in ceili(float(width) / tile_size):
				var x := tx * tile_size
				var y := ty * tile_size
				var w := mini(tile_size, width - x)
				var h := mini(tile_size, height - y)
				var tile := _tile(image, x, y, w, h)
				var path := directory.path_join("l%d_x%d_y%d.png" % [level, tx, ty])
				if tile.save_png(path) != OK:
					return {"ok": false, "error": "cannot write " + path}
				entry.tiles.append({"key": "%d/%d/%d" % [level, tx, ty], "path": path,
					"sha256": FileAccess.get_sha256(path), "width": w + 2, "height": h + 2,
					"source_rect": [x, y, w, h], "content_rect": [1, 1, w, h]})
		result.levels.append(entry)
		if width <= tile_size and height <= tile_size: break
		image.resize(maxi(1, ceili(width / 2.0)), maxi(1, ceili(height / 2.0)), Image.INTERPOLATE_LANCZOS)
		level += 1
	var manifest := FileAccess.open(directory.path_join("tiles.json"), FileAccess.WRITE)
	if manifest == null: return {"ok": false, "error": "cannot write tile index"}
	manifest.store_string(JSON.stringify(result, "\t") + "\n")
	return result

static func _source_pixel(images: Dictionary, width: int, height: int, tile_size: int, x: int, y: int) -> Color:
	x = clampi(x, 0, width - 1)
	y = clampi(y, 0, height - 1)
	var ox := floori(float(x) / tile_size) * tile_size
	var oy := floori(float(y) / tile_size) * tile_size
	var image: Image = images.get("%d:%d" % [ox, oy])
	return image.get_pixel(x - ox + 1, y - oy + 1) if image != null else Color.TRANSPARENT

static func verify_index(index: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	if index.get("format_version") != 1 or index.get("gutter") != 1 or not index.get("levels") is Array:
		return ["unsupported tile index"]
	var tile_size := int(index.get("tile_size", 0))
	if tile_size < 1 or tile_size > 512: return ["invalid tile size"]
	for level: Dictionary in index.levels:
		var images := {}
		var records := {}
		var width := int(level.get("width", 0))
		var height := int(level.get("height", 0))
		if width <= 0 or height <= 0: errors.append("invalid level dimensions"); continue
		for meta: Dictionary in level.get("tiles", []):
			if FileAccess.get_sha256(str(meta.get("path", ""))) != meta.get("sha256", ""):
				errors.append("missing/changed tile " + str(meta.get("key", "")))
				continue
			var image := Image.new()
			if image.load_png_from_buffer(FileAccess.get_file_as_bytes(meta.path)) != OK:
				errors.append("corrupt tile " + meta.key)
				continue
			var r: Array = meta.get("source_rect", [])
			var content: Array = meta.get("content_rect", [])
			var integral := func(n): return (n is int or n is float) and is_finite(float(n)) and float(n) == floor(float(n))
			if r.size() != 4 or content.size() != 4 or not r.all(integral) or not content.all(integral):
				errors.append("invalid crop/gutter " + meta.key)
				continue
			r = r.map(func(n): return int(n))
			content = content.map(func(n): return int(n))
			if content != [1, 1, int(r[2]), int(r[3])] or image.get_width() != int(r[2]) + 2 or image.get_height() != int(r[3]) + 2 or int(meta.get("width", 0)) != image.get_width() or int(meta.get("height", 0)) != image.get_height():
				errors.append("invalid crop/gutter " + meta.key)
				continue
			var x := int(r[0]); var y := int(r[1]); var w := int(r[2]); var h := int(r[3])
			if x < 0 or y < 0 or w <= 0 or h <= 0 or x >= width or y >= height or x % tile_size != 0 or y % tile_size != 0 or w != mini(tile_size, width - x) or h != mini(tile_size, height - y):
				errors.append("invalid tile placement " + meta.key)
				continue
			var key := "%d:%d" % [x, y]
			if images.has(key): errors.append("duplicate tile " + key)
			images[key] = image
			records[key] = r
		if images.size() != ceili(float(width) / tile_size) * ceili(float(height) / tile_size): errors.append("missing level coverage")
		for key: String in images:
			var image: Image = images[key]
			var r: Array = records[key]
			var x := int(r[0]); var y := int(r[1]); var w := int(r[2]); var h := int(r[3])
			for px in w + 2:
				if image.get_pixel(px, 0) != _source_pixel(images, width, height, tile_size, x + px - 1, y - 1) or image.get_pixel(px, h + 1) != _source_pixel(images, width, height, tile_size, x + px - 1, y + h):
					errors.append("vertical/corner gutter " + key); break
			for py in range(1, h + 1):
				if image.get_pixel(0, py) != _source_pixel(images, width, height, tile_size, x - 1, y + py - 1) or image.get_pixel(w + 1, py) != _source_pixel(images, width, height, tile_size, x + w, y + py - 1):
					errors.append("horizontal gutter " + key); break
	return errors

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() == 2 and args[0] == "--verify":
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(args[1]))
		if not parsed is Dictionary:
			printerr("observation-tiles-verify: invalid index")
			quit(1)
			return
		var errors := verify_index(parsed)
		var count := 0
		for level: Dictionary in parsed.get("levels", []): count += level.get("tiles", []).size()
		for error in errors: printerr("FAIL ", error)
		print("observation-tiles-verify: %d tiles, %d failures" % [count, errors.size()])
		quit(0 if errors.is_empty() else 1)
		return
	if args.size() != 2:
		printerr("usage: observation_tiles.gd -- input.png output-directory")
		quit(2)
		return
	var image := Image.new()
	var bytes := FileAccess.get_file_as_bytes(args[0])
	var png := bytes.size() >= 8 and bytes.slice(0, 8) == PackedByteArray([137, 80, 78, 71, 13, 10, 26, 10])
	var decoded := image.load_png_from_buffer(bytes) if png else image.load_jpg_from_buffer(bytes)
	if decoded != OK:
		printerr("observation-tiles: cannot decode source")
		quit(1)
		return
	var result := build(image, args[1])
	if not result.ok:
		printerr(result.error)
		quit(1)
		return
	print("observation-tiles: %d levels, 0 failures" % result.levels.size())
	quit()
