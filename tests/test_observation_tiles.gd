extends SceneTree

const Tiler = preload("res://tools/observation_tiles.gd")
const Cache = preload("res://ui/observation_tiles.gd")
var passed := 0
var failed := 0
var scratch := "/tmp/observation-tiles-%d" % OS.get_process_id()

func check(ok: bool, label: String) -> void:
	if ok: passed += 1; print("ok ", label)
	else: failed += 1; printerr("FAIL ", label)

func grid() -> Image:
	var image := Image.create(10, 7, false, Image.FORMAT_RGBA8)
	for y in 7:
		for x in 10: image.set_pixel(x, y, Color(float(x) / 9.0, float(y) / 6.0, float(x + y) / 15.0, 1.0))
	return image

func read_image(path: String) -> Image:
	var image := Image.new()
	image.load_png_from_buffer(FileAccess.get_file_as_bytes(path))
	return image

func _init() -> void:
	DirAccess.make_dir_recursive_absolute(scratch)
	var source := grid()
	var built: Dictionary = Tiler.build(source, scratch.path_join("a"), 4)
	check(built.get("ok", false), "coordinate-grid pyramid generated")
	if not built.get("ok", false):
		finish()
		return
	check(built.source_width == 10 and built.source_height == 7 and built.levels.size() == 3, "odd dimensions retained and overview reaches one tile")
	check(built.levels[0].tiles.size() == 6, "rectangular level has exact edge tiles")
	var left: Dictionary = built.levels[0].tiles[0]
	var right: Dictionary = built.levels[0].tiles[1]
	var last: Dictionary = built.levels[0].tiles[-1]
	var li := read_image(left.path)
	var ri := read_image(right.path)
	var edge := read_image(last.path)
	check(li.get_pixel(5, 2) == source.get_pixel(4, 1) and ri.get_pixel(0, 2) == source.get_pixel(3, 1), "neighbour gutters sample across tile seam")
	check(ri.get_pixel(1, 2) == source.get_pixel(4, 1), "interior source crop stays exact")
	check(edge.get_pixel(edge.get_width() - 1, edge.get_height() - 1) == source.get_pixel(9, 6), "outer gutters clamp without black seams")
	check(last.source_rect == [8, 4, 2, 3] and last.content_rect == [1, 1, 2, 3], "edge crop metadata excludes gutter")
	var again: Dictionary = Tiler.build(source, scratch.path_join("b"), 4)
	var hashes_a: Array = built.levels[0].tiles.map(func(t): return t.sha256)
	var hashes_b: Array = again.levels[0].tiles.map(func(t): return t.sha256)
	check(hashes_a == hashes_b, "tile PNG bytes deterministic across output locations")
	check(not Tiler.build(Image.new(), scratch.path_join("empty"), 4).get("ok", false), "empty image rejected")

	var cache = Cache.new()
	cache.activate("pack-v1")
	cache.set_visible([left.key])
	check(cache.request_tile(left).is_empty() and cache.decodes == 0, "visible tile queues without frame-path decode")
	cache.pump()
	var loaded: Dictionary = cache.get_tile(left.key)
	check(not loaded.is_empty() and loaded.image.get_pixel(1, 1) == source.get_pixel(0, 0), "pump loads pinned actual tile")
	check(cache.cpu_bytes == 6 * 6 * 4 and cache.gpu_bytes == 6 * 6 * 4, "resident bytes include every gutter pixel with no runtime mip duplication")
	cache.request_tile(left)
	cache.pump()
	check(cache.decodes == 1, "cached requests do not decode again")
	check(cache.request_tile(left, "wrong-pack").is_empty() and cache.decodes == 1, "wrong pack cannot reuse even a cached key")

	cache.set_visible([right.key])
	cache.request_tile(right)
	cache.set_visible([])
	cache.pump()
	check(cache.decodes == 1 and cache.get_tile(right.key).is_empty(), "leaving visible set discards queued work")
	cache.set_visible([right.key])
	cache.request_tile(right)
	cache.close()
	cache.pump()
	check(cache.decodes == 1 and cache.cpu_bytes == 0 and cache.gpu_bytes == 0, "close cancels queue and releases resident image resources")
	cache.activate("pack-v2")
	cache.set_visible([left.key])
	check(cache.get_tile(left.key).is_empty(), "new pack never inherits an old key")
	cache.request_tile(left)
	cache.activate("pack-v3")
	cache.set_visible([left.key])
	cache.pump()
	check(cache.decodes == 1, "pack activation discards stale queued load")

	var bin: Dictionary = left.duplicate(true)
	bin.key = "bin"
	bin.path = scratch.path_join("tile.png.bin")
	var bf := FileAccess.open(bin.path, FileAccess.WRITE)
	bf.store_buffer(FileAccess.get_file_as_bytes(left.path))
	bf.close()
	cache.set_visible([bin.key])
	cache.request_tile(bin)
	cache.pump()
	check(not cache.get_tile(bin.key).is_empty(), "export png.bin decodes by bytes")
	var bundle_dir := "res://observation_bundle/cache-fixture-%d" % OS.get_process_id()
	DirAccess.make_dir_recursive_absolute(bundle_dir)
	var bundled_path := bundle_dir.path_join("tile.png.bin")
	var staged: Dictionary = left.duplicate(true)
	staged.key = "staged"
	staged.path = "res://data/raw/observations/tiles/cache-fixture-%d/tile.png" % OS.get_process_id()
	var sf := FileAccess.open(bundled_path, FileAccess.WRITE)
	sf.store_buffer(FileAccess.get_file_as_bytes(left.path))
	sf.close()
	cache.set_visible([staged.key])
	cache.request_tile(staged)
	cache.pump()
	check(not cache.get_tile(staged.key).is_empty() and Cache.available_path(staged.path) == bundled_path, "missing source tile resolves to exact bundled byte copy")
	DirAccess.remove_absolute(bundled_path)
	DirAccess.remove_absolute(bundle_dir)
	var missing: Dictionary = left.duplicate(true)
	missing.key = "missing"
	missing.path = scratch.path_join("missing.png")
	cache.set_visible([missing.key])
	cache.request_tile(missing)
	cache.pump()
	check(cache.state(missing.key) == "missing", "missing tile has named state")
	var corrupt: Dictionary = left.duplicate(true)
	corrupt.key = "corrupt"
	corrupt.sha256 = "0".repeat(64)
	cache.set_visible([corrupt.key])
	cache.request_tile(corrupt)
	cache.pump()
	check(cache.state(corrupt.key) == "corrupt", "changed tile hash refused")
	var wrong_size: Dictionary = left.duplicate(true)
	wrong_size.key = "wrong-size"
	wrong_size.width = 5
	cache.set_visible([wrong_size.key])
	var prior: int = cache.decodes
	cache.request_tile(wrong_size)
	cache.pump()
	check(cache.state(wrong_size.key) == "invalid" and cache.decodes == prior, "PNG header dimensions checked before decoder allocation")
	var damaged: Dictionary = left.duplicate(true)
	damaged.key = "damaged"
	damaged.path = scratch.path_join("damaged.png")
	var df := FileAccess.open(damaged.path, FileAccess.WRITE)
	df.store_string("broken fixture, not PNG")
	df.close()
	damaged.sha256 = FileAccess.get_sha256(damaged.path)
	cache.set_visible([damaged.key])
	cache.request_tile(damaged)
	cache.pump()
	check(cache.state(damaged.key) == "corrupt" and cache.decodes == prior, "invalid PNG refused even when bytes match pinned hash")
	var too_small = Cache.new(100, 100)
	too_small.activate("tiny-budget")
	too_small.set_visible([left.key])
	too_small.request_tile(left)
	too_small.pump()
	check(too_small.state(left.key) == "over_budget" and too_small.decodes == 0, "valid-sized tile larger than budget refused before decode")

	var limited = Cache.new(160, 160)
	limited.activate("budget")
	limited.set_visible([left.key, right.key])
	limited.request_tile(left)
	limited.pump()
	limited.request_tile(right)
	limited.pump()
	check(limited.cpu_bytes <= 160 and limited.gpu_bytes <= 160 and limited.get_tile(left.key).is_empty() and not limited.get_tile(right.key).is_empty(), "LRU evicts old tile before either resident budget is exceeded")
	var oversized: Dictionary = left.duplicate(true)
	oversized.key = "oversized"
	oversized.width = 100000
	limited.set_visible([oversized.key])
	var before: int = limited.decodes
	limited.request_tile(oversized)
	limited.pump()
	check(limited.decodes == before and limited.state(oversized.key) == "invalid", "oversized metadata refused before image decode or texture creation")
	for caps in [[160, 1000], [1000, 160]]:
		var one_limit = Cache.new(caps[0], caps[1])
		one_limit.activate("one-budget")
		one_limit.set_visible([left.key, right.key])
		one_limit.request_tile(left)
		one_limit.request_tile(right)
		one_limit.pump()
		check(one_limit.decodes == 1 and one_limit.state(right.key) == "queued", "pump honours one-decode frame budget")
		one_limit.pump()
		check(one_limit.cpu_bytes <= caps[0] and one_limit.gpu_bytes <= caps[1] and one_limit.state(left.key) == "evicted", "CPU and GPU budgets independently enforce eviction")
		one_limit.close()
	var overview: Dictionary = built.levels[-1].tiles[0]
	cache.activate("fallback")
	cache.set_visible([overview.key, left.key])
	cache.request_tile(overview)
	cache.pump()
	cache.request_tile(left)
	check(not cache.get_tile(overview.key).is_empty() and cache.get_tile(left.key).is_empty(), "low resolution remains ready while requested detail is pending")
	check(Tiler.verify_index(built).is_empty(), "independent index verifier checks actual PNG hashes, coverage and gutters")
	var json_index: Dictionary = JSON.parse_string(JSON.stringify(built))
	check(Tiler.verify_index(json_index).is_empty(), "JSON-decoded integral float coordinates retain valid crop metadata")
	var broken: Dictionary = Tiler.build(source, scratch.path_join("bad-seam"), 4)
	var bad_tile: Dictionary = broken.levels[0].tiles[0]
	var bad_image := read_image(bad_tile.path)
	bad_image.set_pixel(5, 2, Color.MAGENTA)
	bad_image.save_png(bad_tile.path)
	bad_tile.sha256 = FileAccess.get_sha256(bad_tile.path)
	check(not Tiler.verify_index(broken).is_empty(), "wrong gutter fails even with an updated valid tile hash")
	bad_image.set_pixel(5, 2, source.get_pixel(4, 1))
	bad_image.set_pixel(0, 0, Color.MAGENTA)
	bad_image.save_png(bad_tile.path)
	bad_tile.sha256 = FileAccess.get_sha256(bad_tile.path)
	check(not Tiler.verify_index(broken).is_empty(), "corner gutter is verified as well as horizontal and vertical strips")
	cache.close()
	limited.close()
	too_small.close()
	finish()

func finish() -> void:
	print("telescope-cache-test: %d passed, %d failures" % [passed, failed])
	quit(1 if failed else 0)
