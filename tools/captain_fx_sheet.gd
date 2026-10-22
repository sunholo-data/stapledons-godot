extends SceneTree
## R2-CAPTAIN-ANIMATION D-118 review composites (headless) from tools/captain_fx_review.gd's frames:
##   fx_side/<facing>/fNNN.png     the four effect options side by side, left to right: none, echo, trail, blur
##   fx/<effect>_<facing>_3x/...   each option alone at 3x
##   feet_side/<facing>/fNN.png    the walk before and after the deck settle (Bow at the spawn), side by side
## Usage: godot --headless --path . --script tools/captain_fx_sheet.gd -- --out=<review dir>
const CROP := 240
var out := ""


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
	for facing in ["back", "profile"]:
		var dir := out.path_join("fx_side/" + facing)
		DirAccess.make_dir_recursive_absolute(dir)
		for e in CaptainAvatar.EFFECTS:
			DirAccess.make_dir_recursive_absolute(out.path_join("fx/%s_%s_3x" % [e, facing]))
		for t in 120:
			var row := Image.create(CROP * 4 + 12, CROP, false, Image.FORMAT_RGBA8)
			row.fill(Color(0.08, 0.08, 0.1))
			for k in CaptainAvatar.EFFECTS.size():
				var e: String = CaptainAvatar.EFFECTS[k]
				var img := Image.load_from_file(out.path_join("fx/%s_%s/f%03d.png" % [e, facing, t]))
				img.convert(Image.FORMAT_RGBA8)
				row.blit_rect(img, Rect2i(0, 0, CROP, CROP), Vector2i(k * (CROP + 4), 0))
				var big := img.duplicate() as Image
				big.resize(CROP * 3, CROP * 3, Image.INTERPOLATE_NEAREST)
				big.save_png(out.path_join("fx/%s_%s_3x/f%03d.png" % [e, facing, t]))
			row.save_png(dir.path_join("f%03d.png" % t))
		# Feet before | after (Bow, the spawn).
		var fdir := out.path_join("feet_side/" + facing)
		DirAccess.make_dir_recursive_absolute(fdir)
		for i in 12:
			var row := Image.create(CROP * 2 + 4, CROP, false, Image.FORMAT_RGBA8)
			row.fill(Color(0.08, 0.08, 0.1))
			for k in 2:
				var mode: String = ["before", "after"][k]
				var img := Image.load_from_file(out.path_join("feet/%s_bow_spawn_%s/f%02d.png" % [mode, facing, i]))
				img.convert(Image.FORMAT_RGBA8)
				row.blit_rect(img, Rect2i(0, 0, CROP, CROP), Vector2i(k * (CROP + 4), 0))
			row.resize(row.get_width() * 2, row.get_height() * 2, Image.INTERPOLATE_NEAREST)
			row.save_png(fdir.path_join("f%02d.png" % i))
	print("captain-fx-sheet: ok")
	quit(0)
