extends SceneTree
## Image I/O around the AILANG sky-model fitter (sim/tools/sky_model.ail), M1.4b.
##   godot --headless --path . --script tools/sky_colours.gd -- histogram <panorama.png> <colours.csv>
##   godot --headless --path . --script tools/sky_colours.gd -- paint <panorama.png> <fits.csv> <model.png>
## histogram: one "r,g,b,count" row per distinct colour, in packed-RGB order.
## paint: the RGBA8 model texture from the fitter's "r,g,b,code,dxy,flag" rows
## (R = T_c code, G = residual code, B = line flag, A = 255; sky/sky_model.gd).
## Colours index flat 2^24 tables: GDScript Dictionaries are too slow for 50M texels.


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var ok := false
	match a[0] if a.size() > 0 else "":
		"histogram": ok = a.size() == 3 and histogram(a[1], a[2])
		"paint": ok = a.size() == 4 and paint(a[1], a[2], a[3])
	if not ok:
		printerr("usage: histogram <png> <colours.csv> | paint <png> <fits.csv> <model.png>")
	quit(0 if ok else 1)


func _rgb8(path: String) -> Image:
	var img := Image.load_from_file(path)
	if img == null:
		return null
	img.convert(Image.FORMAT_RGB8)
	return img


func histogram(png: String, out: String) -> bool:
	var img := _rgb8(png)
	if img == null:
		return false
	var data := img.get_data()
	var counts := PackedInt32Array()
	counts.resize(1 << 24)
	for i in range(0, data.size(), 3):
		counts[(data[i] << 16) | (data[i + 1] << 8) | data[i + 2]] += 1
	var f := FileAccess.open(out, FileAccess.WRITE)
	var distinct := 0
	for p in counts.size():
		if counts[p] > 0:
			f.store_line("%d,%d,%d,%d" % [p >> 16, (p >> 8) & 255, p & 255, counts[p]])
			distinct += 1
	print("histogram: %d x %d texels, %d distinct colours -> %s" % [img.get_width(), img.get_height(), distinct, out])
	return true


func paint(png: String, fits: String, out: String) -> bool:
	var img := _rgb8(png)
	if img == null:
		return false
	var table := PackedByteArray()
	table.resize(3 << 24)
	var known := PackedByteArray()
	known.resize(1 << 24)
	var f := FileAccess.open(fits, FileAccess.READ)
	while not f.eof_reached():
		var r := f.get_line().split(",")
		if r.size() != 6:
			continue
		var p := (r[0].to_int() << 16) | (r[1].to_int() << 8) | r[2].to_int()
		table[3 * p] = r[3].to_int()
		table[3 * p + 1] = r[4].to_int()
		table[3 * p + 2] = r[5].to_int()
		known[p] = 1
	var data := img.get_data()
	var model := PackedByteArray()
	model.resize(data.size() / 3 * 4)
	var missing := 0
	var j := 0
	for i in range(0, data.size(), 3):
		var p := (data[i] << 16) | (data[i + 1] << 8) | data[i + 2]
		if known[p] == 0:
			missing += 1
		model[j] = table[3 * p]
		model[j + 1] = table[3 * p + 1]
		model[j + 2] = table[3 * p + 2]
		model[j + 3] = 255
		j += 4
	if missing > 0:
		printerr("paint: %d texels have no fitted colour" % missing)
		return false
	Image.create_from_data(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8, model).save_png(out)
	print("paint: %s" % out)
	return true
