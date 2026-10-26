extends SceneTree
## R2-CAPTAIN-ANIMATION CA2 review composites (headless), from tools/captain_ca2_review.gd's frames and
## the manifest:
##   seq/<beat>_3x/fNNN.png      the captain's 140 x 180 px around the feet and body of each sequence, at 3x
##   painted/<clip>_<facing>/fNN.png  the painted frames of each CA2 clip at 2x their cell on grey, played
##                               forward then (for a clip with a reverse_of twin) backward: the reach then
##                               the step back, the sit then the stand
##   ca2_cells.png               every CA2 painted cell, in rows by clip
## Usage: godot --headless --path . --script tools/captain_ca2_sheet.gd -- --out=<review dir>
const DIR := "res://assets/characters/captain"
const CROP := 240
const CA2 := ["use_low", "use_mid", "sit", "seated", "lift", "look_up"]
var out := ""


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
	# 3x of every sequence (the figure's neighbourhood).
	for d in DirAccess.get_directories_at(out.path_join("seq")):
		if d.ends_with("_3x"):
			continue
		var src := out.path_join("seq/" + d)
		var dst := out.path_join("seq/%s_3x" % d)
		DirAccess.make_dir_recursive_absolute(dst)
		for f in DirAccess.get_files_at(src):
			if not f.ends_with(".png"):
				continue
			var img := Image.load_from_file(src.path_join(f))
			var c := img.get_region(Rect2i(CROP / 2 - 70, CROP / 2 - 90, 140, 180))
			c.resize(420, 540, Image.INTERPOLATE_NEAREST)
			c.save_png(dst.path_join(f))
	# The painted clips, forward and (where a twin plays them backward) backward.
	var m: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DIR.path_join("manifest.json")))
	var anim: Dictionary = m.anim
	var s: float = anim.cell_scale
	var w := int(1024 * s)
	var h := int(1536 * s)
	var reversed_by := {}
	for clip: String in anim.clips:
		if anim.clips[clip].has("reverse_of"):
			reversed_by[str(anim.clips[clip].reverse_of)] = clip
	var sheet_rows: Array = []
	for clip: String in CA2:
		if not anim.clips.has(clip):
			continue
		for facing: String in anim.clips[clip].stages["0"]:
			var frames: Array = anim.clips[clip].stages["0"][facing]
			var cells: Array[Image] = []
			for e: Dictionary in frames:
				var cell := Image.load_from_file(ProjectSettings.globalize_path(DIR.path_join(e.file)))
				cell.convert(Image.FORMAT_RGBA8)
				var canvas := Image.create(w, h, false, Image.FORMAT_RGBA8)
				canvas.fill(Color(0.42, 0.44, 0.47))
				canvas.blend_rect(cell, Rect2i(Vector2i.ZERO, cell.get_size()), Vector2i(int(e.crop[0]), int(e.crop[1])))
				for x in range(0, w, 3):
					canvas.set_pixel(x, int(1440 * s), Color(0.2, 0.9, 1.0)) # the deck line (the foot anchor)
				cells.append(canvas)
			sheet_rows.append(cells)
			var seq: Array[Image] = cells.duplicate()
			if reversed_by.has(clip):
				var back := cells.duplicate()
				back.reverse()
				seq.append_array(back)
			var dir := out.path_join("painted/%s_%s" % [clip, facing])
			DirAccess.make_dir_recursive_absolute(dir)
			for i in seq.size():
				var big := seq[i].duplicate() as Image
				big.resize(w * 2, h * 2, Image.INTERPOLATE_LANCZOS)
				big.save_png(dir.path_join("f%02d.png" % i))
	var cols := 0
	for r: Array in sheet_rows:
		cols = maxi(cols, r.size())
	var sheet := Image.create(maxi(1, cols) * w, maxi(1, sheet_rows.size()) * h, false, Image.FORMAT_RGBA8)
	for j in sheet_rows.size():
		for i in sheet_rows[j].size():
			sheet.blit_rect(sheet_rows[j][i], Rect2i(0, 0, w, h), Vector2i(i * w, j * h))
	sheet.save_png(out.path_join("ca2_cells.png"))
	print("captain-ca2-sheet: ok, %d painted rows" % sheet_rows.size())
	quit(0)
