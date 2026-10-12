extends SceneTree
## AC11 bright-star audit (M1.2d; Godot replaces the planned bright_star_audit.py, plan F3):
##   godot --headless --path . --script tools/bright_star_audit.gd -- renders/
## AC11: at beta = 0, at least 95% of HIP2 stars with V < 2.5 are rendered within 1 px of their
## predicted position, and the number of rendered stars brighter than V = 6.5 lies in
## [5,000, 9,100] (the Bright Star Catalogue range).
## Input contract (written by the M1.5b capture, one per frame): <frame>.png beside
## <frame>.audit.json = {"stars": [{"id": "HIP 24436", "x": px, "y": px, "v": mag}, ...]}, the
## predicted pixel position (origin top-left, pixel centres at +0.5) of every catalogue star the
## camera projects into that frame. The frames together should cover the sky once; a star seen
## in two frames counts once (by id). The render gate itself runs in M1.5b; tests/test_bright_audit.gd
## checks this auditor on synthetic renders.

const BRIGHT_V := 2.5
const COUNT_V := 6.5
const HIT_PX := 1.0
const MIN_FRACTION := 0.95
const COUNT_MIN := 5000
const COUNT_MAX := 9100
## a detection is a local luminance maximum above THRESHOLD (linear, 0..1 PNG scale)
const THRESHOLD := 0.02


## Local maxima (3x3, ties broken toward the first pixel) above `threshold`, each refined to the
## luminance-weighted centroid of its 3x3 neighbourhood, in pixel units (centres at +0.5).
static func detect(img: Image, threshold := THRESHOLD) -> Array[Vector2]:
	var w := img.get_width()
	var h := img.get_height()
	var lum := PackedFloat32Array()
	lum.resize(w * h)
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			lum[y * w + x] = 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
	var out: Array[Vector2] = []
	for y in range(1, h - 1):
		for x in range(1, w - 1):
			var l := lum[y * w + x]
			if l <= threshold or not _peak(lum, w, x, y, l):
				continue
			var s := 0.0
			var p := Vector2.ZERO
			for dy in [-1, 0, 1]:
				for dx in [-1, 0, 1]:
					var q := lum[(y + dy) * w + x + dx]
					s += q
					p += q * Vector2(x + dx + 0.5, y + dy + 0.5)
			out.append(p / s)
	return out


static func _peak(lum: PackedFloat32Array, w: int, x: int, y: int, l: float) -> bool:
	for dy in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			var q := lum[(y + dy) * w + x + dx]
			# strictly greater neighbours, or an equal one earlier in scan order, win
			if q > l or (q == l and (dy < 0 or (dy == 0 and dx < 0))):
				return false
	return true


static func _hit(stars_px: Vector2, found: Array[Vector2]) -> bool:
	for f in found:
		if f.distance_to(stars_px) <= HIT_PX:
			return true
	return false


## frames: [{"image": Image, "stars": [{"id", "x", "y", "v"}]}]. Returns the AC11 numbers and verdict.
## Stars predicted outside the frame's detectable interior (1 px border) are skipped.
static func audit(frames: Array, count_min := COUNT_MIN, count_max := COUNT_MAX) -> Dictionary:
	var bright := {}
	var bright_hit := {}
	var rendered := {}
	for fr: Dictionary in frames:
		var img: Image = fr["image"]
		var found := detect(img)
		for s: Dictionary in fr["stars"]:
			var p := Vector2(float(s["x"]), float(s["y"]))
			if p.x < 1.0 or p.y < 1.0 or p.x > img.get_width() - 1.0 or p.y > img.get_height() - 1.0:
				continue
			var v := float(s["v"])
			var hit := _hit(p, found)
			if v < BRIGHT_V:
				bright[s["id"]] = true
				if hit:
					bright_hit[s["id"]] = true
			if v < COUNT_V and hit:
				rendered[s["id"]] = true
	var frac := float(bright_hit.size()) / bright.size() if bright.size() > 0 else 0.0
	return {"bright": bright.size(), "bright_hit": bright_hit.size(), "fraction": frac,
		"rendered_v65": rendered.size(),
		"pass": bright.size() > 0 and frac >= MIN_FRACTION and rendered.size() >= count_min and rendered.size() <= count_max}


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() != 1:
		printerr("usage: bright_star_audit.gd -- RENDER_DIR"); quit(2); return
	var frames := []
	for f in DirAccess.get_files_at(a[0]):
		var meta := "%s/%s.audit.json" % [a[0], f.get_basename()]
		if f.ends_with(".png") and FileAccess.file_exists(meta):
			var j: Variant = JSON.parse_string(FileAccess.get_file_as_string(meta))
			var img := Image.load_from_file("%s/%s" % [a[0], f])
			if typeof(j) != TYPE_DICTIONARY or img == null:
				printerr("bright-star-audit: cannot read %s" % f); quit(2); return
			frames.append({"image": img, "stars": j.get("stars", [])})
	if frames.is_empty():
		printerr("bright-star-audit: no <frame>.png + <frame>.audit.json pairs in %s (written by the M1.5b capture)" % a[0])
		quit(2); return
	var r := audit(frames)
	print("bright-star-audit: %d frames; V < %.1f: %d/%d within %.0f px (%.1f%%, need %.0f%%); rendered V < %.1f: %d (need %d-%d): %s" % [
		frames.size(), BRIGHT_V, r["bright_hit"], r["bright"], HIT_PX, 100.0 * r["fraction"], 100.0 * MIN_FRACTION,
		COUNT_V, r["rendered_v65"], COUNT_MIN, COUNT_MAX, "PASS" if r["pass"] else "FAIL"])
	quit(0 if r["pass"] else 1)
