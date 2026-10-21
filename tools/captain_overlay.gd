extends SceneTree
## R2-CAPTAIN-ANIMATION jog review extras (D-109), headless, from a review folder built by
## tools/captain_review.gd:
##   overlay/<clip>_<facing>/fNN.png  the painted frames (2x their cell) with the foot contacts drawn, per step: a
##                                 disc on the planted sole (red L, blue R), and a ring where that sole
##                                 should be if it stayed on the deck (the contact's first position moved
##                                 back one frame spacing per frame); the disc on the ring = no slide
##   ab/<clip>_<facing>/fNN.png    A/B at game speed on one 2 s timeline (60 fps): the previous review's
##                                 clip (--prev, --prev-clip, --prev-ms a frame) beside this one
## Usage: godot --headless --path . --script tools/captain_overlay.gd -- --out=<review dir> --prev=<review dir>
##        [--clip=walk] [--prev-clip=jog] [--prev-ms=69.3]
const DIR := "res://assets/characters/captain"
const F := preload("res://tools/captain_frames.gd") ## the check's planted-boot finders
var out := ""
var v1 := "" ## the previous review folder (--prev; --v1 still accepted)
var clip_name := "walk"
var prev_clip := "jog"
var prev_ms := 69.3


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
		elif a.begins_with("--v1=") or a.begins_with("--prev="):
			v1 = a.get_slice("=", 1)
		elif a.begins_with("--clip="):
			clip_name = a.trim_prefix("--clip=")
		elif a.begins_with("--prev-clip="):
			prev_clip = a.trim_prefix("--prev-clip=")
		elif a.begins_with("--prev-ms="):
			prev_ms = float(a.trim_prefix("--prev-ms="))
	var m: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DIR.path_join("anim_pilot.json")))
	var anim: Dictionary = m.anim
	var s: float = anim.cell_scale
	var jog: Dictionary = anim.clips[clip_name]
	var rows := {}
	for facing: String in jog.stages["0"]:
		var list: Array = jog.stages["0"][facing]
		var n := list.size()
		var mpf: float = float(jog.cycle_m) / n
		var ppm := 720.0 * s * 2.0 # 2x cells
		var dir := out.path_join("overlay/%s_%s" % [clip_name, facing])
		DirAccess.make_dir_recursive_absolute(dir)
		var anchor := Vector2(-1, -1)
		var anchor_i := -1
		var side_prev := ""
		var marks := []
		for i in n:
			var e: Dictionary = list[i]
			var cell := _cell(e, s)
			cell.resize(cell.get_width() * 2, cell.get_height() * 2, Image.INTERPOLATE_LANCZOS)
			var img := Image.create(cell.get_width(), cell.get_height(), false, Image.FORMAT_RGBA8)
			img.fill(Color(0.42, 0.44, 0.47))
			img.blend_rect(cell, Rect2i(Vector2i.ZERO, cell.get_size()), Vector2i.ZERO)
			var side := str(e.get("planted", ""))
			if side in ["L", "R"]:
				var g := Image.load_from_file(ProjectSettings.globalize_path("res://" + str(e.guide)))
				g.convert(Image.FORMAT_RGBA8)
				var hint: Vector2 = F._key_sole(g, side) * 2.0
				var p: Vector2 = F._sole_near(cell, 0.5, hint.x, 26) # the planted boot, as the check finds it
				# Per step, as the check measures it: the ring is where the previous frame's contact should be
				# now (moved back one frame spacing); the first frame of a stance has no ring.
				if side != side_prev:
					anchor = p; anchor_i = i
				var k := mini(1, i - anchor_i)
				var want := anchor + (Vector2(-k * mpf * ppm, 0) if facing == "profile" else Vector2(0, k * mpf * ppm * sin(deg_to_rad(29.0))))
				var col := Color(0.9, 0.15, 0.1) if side == "L" else Color(0.15, 0.35, 0.95)
				_ring(img, want, 9.0, col)
				_disc(img, p, 5.0, col)
				anchor = p; anchor_i = i
				marks.append({"frame": i, "side": side, "sole_px_2x": [snappedf(p.x, 0.1), snappedf(p.y, 0.1)], "on_deck_px_2x": [snappedf(want.x, 0.1), snappedf(want.y, 0.1)], "off_px_2x": snappedf(p.distance_to(want), 0.1)})
			side_prev = side
			img.save_png(dir.path_join("f%02d.png" % i))
		rows[facing] = {"frames": n, "m_per_frame": mpf, "marks": marks}
		# A/B on one timeline.
		var v1dir := v1.path_join("clips/%s_%s" % [prev_clip, facing])
		var v2dir := out.path_join("clips/%s_%s" % [clip_name, facing])
		var v1n := Array(DirAccess.get_files_at(v1dir)).filter(func(f): return f.ends_with(".png") and not f.ends_with("_3x.png")).size()
		var abdir := out.path_join("ab/%s_%s" % [clip_name, facing])
		DirAccess.make_dir_recursive_absolute(abdir)
		var v1_ms := prev_ms
		var v2_ms := 1000.0 * float(jog.cycle_m) / ShipConsoles.WALK_SPEED_MPS / n
		var cache := {}
		for t in 120:
			var ms := t * 1000.0 / 60.0
			var a := _load(cache, v1dir.path_join("f%02d.png" % (int(ms / v1_ms) % v1n)))
			var b := _load(cache, v2dir.path_join("f%02d.png" % (int(ms / v2_ms) % n)))
			var ab := Image.create(a.get_width() + b.get_width() + 8, a.get_height(), false, Image.FORMAT_RGBA8)
			ab.fill(Color(0.1, 0.1, 0.12))
			ab.blit_rect(a, Rect2i(Vector2i.ZERO, a.get_size()), Vector2i.ZERO)
			ab.blit_rect(b, Rect2i(Vector2i.ZERO, b.get_size()), Vector2i(a.get_width() + 8, 0))
			ab.resize(ab.get_width() * 2, ab.get_height() * 2, Image.INTERPOLATE_NEAREST)
			ab.save_png(abdir.path_join("f%03d.png" % t))
		rows[facing]["ab"] = {"prev_clip": prev_clip, "prev_frames": v1n, "prev_ms": snappedf(v1_ms, 0.1), "frames": n, "ms": snappedf(v2_ms, 0.1), "timeline_frames": 120, "timeline_ms": 1000.0 / 60.0}
	var f := FileAccess.open(out.path_join("overlay.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(rows, "  "))
	f.close()
	print("captain-overlay: %s" % JSON.stringify(rows.keys()))
	quit(0)


static func _load(cache: Dictionary, p: String) -> Image:
	if not cache.has(p):
		var i := Image.load_from_file(p)
		i.convert(Image.FORMAT_RGBA8)
		cache[p] = i
	return cache[p]


static func _cell(e: Dictionary, s: float) -> Image:
	var img := Image.load_from_file(ProjectSettings.globalize_path(DIR.path_join(e.file)))
	img.convert(Image.FORMAT_RGBA8)
	var cell := Image.create(int(1024 * s), int(1536 * s), false, Image.FORMAT_RGBA8)
	cell.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i(int(e.crop[0]), int(e.crop[1])))
	if bool(e.get("flip", false)):
		cell.flip_x()
	return cell


## The planted sole: the centroid of the lowest 3% of the figure's rows (x) and its bottom row (y).
static func _sole(img: Image) -> Vector2:
	var r := img.get_used_rect()
	var band := maxi(2, int(r.size.y * 0.03))
	var sx := 0.0
	var n := 0
	for y in range(r.end.y - band, r.end.y):
		for x in range(r.position.x, r.end.x):
			if img.get_pixel(x, y).a > 0.5:
				sx += x
				n += 1
	return Vector2(sx / maxf(1, n), r.end.y)


static func _disc(img: Image, c: Vector2, r: float, col: Color) -> void:
	for y in range(int(c.y - r), int(c.y + r) + 1):
		for x in range(int(c.x - r), int(c.x + r) + 1):
			if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height() and Vector2(x, y).distance_to(c) <= r:
				img.set_pixel(x, y, col)


static func _ring(img: Image, c: Vector2, r: float, col: Color) -> void:
	for k in 72:
		var a := TAU * k / 72.0
		for w in 2:
			var p := c + Vector2(cos(a), sin(a)) * (r + w)
			if p.x >= 0 and p.y >= 0 and p.x < img.get_width() and p.y < img.get_height():
				img.set_pixelv(Vector2i(p), col)
