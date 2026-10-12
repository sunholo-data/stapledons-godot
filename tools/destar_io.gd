extends SceneTree
## Image I/O around the AILANG star remover (sim/tools/destar.ail), M1.4a / D-10.
##   godot --headless --path . --script tools/destar_io.gd -- dump  <panorama.png> <out.rgb>
##   godot --headless --path . --script tools/destar_io.gd -- apply <panorama.png> <patches.bin> <out.png>
## dump: the panorama as raw RGB8, row-major, no header (destar.ail is told w and h).
## apply: paint destar.ail's 7-byte records (x u16 LE, y u16 LE, r, g, b) over the panorama.


func _init() -> void:
	var a := OS.get_cmdline_user_args()
	var ok := false
	match a[0] if a.size() > 0 else "":
		"dump": ok = a.size() == 3 and dump(a[1], a[2])
		"apply": ok = a.size() == 4 and apply(a[1], a[2], a[3])
	if not ok:
		printerr("usage: dump <png> <out.rgb> | apply <png> <patches.bin> <out.png>")
	quit(0 if ok else 1)


func _rgb8(path: String) -> Image:
	var img := Image.load_from_file(path)
	if img != null:
		img.convert(Image.FORMAT_RGB8)
	return img


func dump(png: String, out: String) -> bool:
	var img := _rgb8(png)
	if img == null:
		return false
	var f := FileAccess.open(out, FileAccess.WRITE)
	f.store_buffer(img.get_data())
	print("dump: %d x %d -> %s" % [img.get_width(), img.get_height(), out])
	return true


func apply(png: String, patches: String, out: String) -> bool:
	var img := _rgb8(png)
	if img == null:
		return false
	var w := img.get_width()
	var data := img.get_data()
	var rec := FileAccess.get_file_as_bytes(patches)
	if rec.size() % 7 != 0:
		printerr("apply: %s is not a whole number of 7-byte records" % patches)
		return false
	for i in range(0, rec.size(), 7):
		var p := ((rec[i + 2] | (rec[i + 3] << 8)) * w + (rec[i] | (rec[i + 1] << 8))) * 3
		data[p] = rec[i + 4]
		data[p + 1] = rec[i + 5]
		data[p + 2] = rec[i + 6]
	Image.create_from_data(w, img.get_height(), false, Image.FORMAT_RGB8, data).save_png(out)
	print("apply: %d patched pixels -> %s" % [rec.size() / 7, out])
	return true
