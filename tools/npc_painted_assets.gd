extends SceneTree
## D-139 image I/O only: slice, uniformly downscale and foot-anchor the preserved RGBA sources.
## --ingest writes the pilot assets. Default checks actual decoded files and their provenance.
const ART := "res://art/npc-painted-v1"
const DEST := "res://assets/characters/npcs"
const POSES := ["front", "back", "profile", "seated_front", "seated_back"]
const CELL := Vector2i(192, 288)
const ANCHOR := Vector2i(96, 272)
const PPM := 144.0
var errors: Array[String] = []
func _initialize() -> void:
	if "--ingest" in OS.get_cmdline_user_args(): _ingest()
	_check()
	for message: String in errors: printerr("FAIL ", message)
	print("painted-npc-assets: 5 identities, 25 poses, %d failures" % errors.size())
	quit(1 if not errors.is_empty() else 0)
func _doc(path: String) -> Dictionary:
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	return value if value is Dictionary else {}
func _png(path: String) -> Image:
	if not FileAccess.file_exists(path): return null
	var image := Image.new()
	return image if image.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) == OK else null
func _matte(image: Image) -> void:
	image.convert(Image.FORMAT_RGBA8)
	for y in image.get_height():
		for x in image.get_width():
			var c := image.get_pixel(x, y)
			# Mechanical alpha cleanup only. RGB behind zero alpha is discarded, never keyed.
			if c.a <= 0.04: image.set_pixel(x, y, Color.TRANSPARENT)
func _ingest() -> void:
	var source := _doc(ART.path_join("roster.json"))
	if source.is_empty(): errors.append("source roster missing"); return
	var rear := _png(ART.path_join("sources/seated_back.png"))
	if rear == null: errors.append("seated back atlas missing"); return
	var catalog := {"schema": "stapledons.npc.painted/1", "status": "visual pilot; not approved for production", "canvas_px": [CELL.x, CELL.y], "foot_anchor_px": [ANCHOR.x, ANCHOR.y], "px_per_m": PPM, "characters": []}
	DirAccess.make_dir_recursive_absolute(DEST)
	for i in source.characters.size():
		var entry: Dictionary = source.characters[i].duplicate(true)
		var path := ART.path_join("sources/%s.png" % entry.id)
		var sheet := _png(path)
		if sheet == null: errors.append("missing source " + path); continue
		entry.poses = {}
		entry.source = path; entry.source_sha256 = FileAccess.get_sha256(path)
		entry.style_sha256 = FileAccess.get_sha256(source.style_reference)
		if not str(entry.portrait).is_empty(): entry.portrait_sha256 = FileAccess.get_sha256(entry.portrait)
		for pose_index in POSES.size():
			var pose: String = POSES[pose_index]
			var origin: Image = sheet if pose_index < 4 else rear
			var size := origin.get_size() / (Vector2i(2, 2) if pose_index < 4 else Vector2i(3, 2))
			var index: int = pose_index if pose_index < 4 else i
			var columns := 2 if pose_index < 4 else 3
			var frame := origin.get_region(Rect2i(Vector2i(index % columns, index / columns) * size, size))
			_matte(frame)
			var box := frame.get_used_rect()
			if box.size.x < 30 or box.size.y < 100: errors.append("empty source pose " + entry.id + "/" + pose); continue
			var crop := frame.get_region(box)
			var height := roundi(float(entry.height_m) * PPM * (0.75 if pose.begins_with("seated") else 1.0))
			var scale := float(height) / box.size.y
			if scale > 1.: errors.append("source would need upscaling " + entry.id + "/" + pose); continue
			var width := roundi(box.size.x * scale)
			if width > CELL.x - 16: errors.append("pose wider than canvas " + entry.id + "/" + pose); continue
			crop.resize(width, height, Image.INTERPOLATE_LANCZOS)
			_matte(crop)
			var feet := _feet(crop)
			var offset := ANCHOR - feet
			if offset.x < 4 or offset.y < 4 or offset.x + width > CELL.x - 4: errors.append("pose clipped " + entry.id + "/" + pose); continue
			var canvas := Image.create_empty(CELL.x, CELL.y, false, Image.FORMAT_RGBA8)
			canvas.blit_rect(crop, Rect2i(Vector2i.ZERO, crop.get_size()), offset)
			var file := "%s_%s.png" % [entry.id, pose]
			if canvas.save_png(DEST.path_join(file)) != OK: errors.append("save failed " + file); continue
			entry.poses[pose] = {"file": file, "sha256": FileAccess.get_sha256(DEST.path_join(file)), "source_crop": [box.position.x, box.position.y, box.size.x, box.size.y], "source_grid": [columns, 2], "source_cell": index, "source_file": path if pose_index < 4 else ART.path_join("sources/seated_back.png"), "source_sha256": FileAccess.get_sha256(path if pose_index < 4 else ART.path_join("sources/seated_back.png")), "height_px": height}
		catalog.characters.append(entry)
	if errors.is_empty(): FileAccess.open(DEST.path_join("manifest.json"), FileAccess.WRITE).store_string(JSON.stringify(catalog, "  ") + "\n")
func _feet(image: Image) -> Vector2i:
	var y := image.get_height() - 1
	while y > 0:
		var left := image.get_width(); var right := -1
		for x in image.get_width():
			if image.get_pixel(x, y).a >= 0.5: left = mini(left, x); right = maxi(right, x)
		if right >= left:
			# Include both soles in the bottom 12 px rather than anchoring to a single curved toe.
			for row in range(maxi(0, y - 12), y + 1):
				for x in image.get_width():
					if image.get_pixel(x, row).a >= 0.5: left = mini(left, x); right = maxi(right, x)
			return Vector2i(roundi((left + right) * 0.5), y)
		y -= 1
	return Vector2i.ZERO
func _check() -> void:
	var catalog := _doc(DEST.path_join("manifest.json"))
	if catalog.get("schema") != "stapledons.npc.painted/1" or catalog.get("characters", []).size() != 5: errors.append("catalog missing or malformed"); return
	var ids: Array[String] = []
	var style: String = str(_doc(ART.path_join("roster.json")).get("style_reference", ""))
	for character: Dictionary in catalog.characters:
		if character.id in ids: errors.append("duplicate identity " + character.id)
		ids.append(character.id)
		if FileAccess.get_sha256(character.source) != character.source_sha256: errors.append("source hash mismatch " + character.id)
		if style.is_empty() or FileAccess.get_sha256(style) != character.style_sha256: errors.append("captain style reference changed " + character.id)
		if not str(character.portrait).is_empty() and FileAccess.get_sha256(character.portrait) != character.portrait_sha256: errors.append("portrait identity source changed " + character.id)
		for pose: String in POSES:
			if not character.poses.has(pose): errors.append("missing pose " + character.id + "/" + pose); continue
			var data: Dictionary = character.poses[pose]
			var path := DEST.path_join(data.file)
			var image := _png(path)
			if image == null: errors.append("missing PNG " + path); continue
			if image.get_size() != CELL or not image.detect_alpha(): errors.append("canvas or alpha invalid " + path)
			if FileAccess.get_sha256(path) != data.sha256 or FileAccess.get_sha256(data.source_file) != data.source_sha256: errors.append("pose/source hash mismatch " + path)
			var box := image.get_used_rect()
			if box.position.x < 4 or box.position.y < 4 or box.end.x > CELL.x - 4 or box.end.y > CELL.y - 4: errors.append("nontransparent border " + path)
			if absi(_feet(image).y - ANCHOR.y) > 1 or absi(_feet(image).x - ANCHOR.x) > 1: errors.append("foot anchor drift " + path)
			if not pose.begins_with("seated") and absi(box.size.y - roundi(float(character.height_m) * PPM)) > 3: errors.append("height drift " + path)
