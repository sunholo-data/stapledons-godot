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

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2:
		printerr("usage: observation_tiles.gd -- input.png output-directory")
		quit(2)
		return
	var image := Image.new()
	if image.load_png_from_buffer(FileAccess.get_file_as_bytes(args[0])) != OK:
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
