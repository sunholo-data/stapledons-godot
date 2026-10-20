extends SceneTree
## SPIKE helper (throwaway): a labelled-by-position contact sheet of the spike's crops.
## Rows: TRAPPIST-1, alpha Cen A, Aldebaran (today Auto | surface Auto | surface Realistic),
## then the two synthetic eclipses. 360 px tiles.
func _initialize() -> void:
	var dir := "res://renders/star_surfaces/"
	var rows := [["trappist1_auto_off_crop", "trappist1_auto_on_crop", "trappist1_realistic_on_crop"],
		["acen_a_auto_off_crop", "acen_a_auto_on_crop", "acen_a_realistic_on_crop"],
		["aldebaran_auto_off_crop", "aldebaran_auto_on_crop", "aldebaran_realistic_on_crop"],
		["eclipse_diamond_ring_crop", "eclipse_total_crop", ""]]
	var t := 360
	var sheet := Image.create(3 * t + 4 * 8, rows.size() * t + (rows.size() + 1) * 8, false, Image.FORMAT_RGB8)
	sheet.fill(Color(0.06, 0.06, 0.08))
	for r in rows.size():
		for c in 3:
			var name: String = rows[r][c]
			if name == "" or not FileAccess.file_exists(dir + name + ".png"): continue
			var img := Image.load_from_file(dir + name + ".png"); img.convert(Image.FORMAT_RGB8)
			img.resize(t, t, Image.INTERPOLATE_BILINEAR)
			sheet.blit_rect(img, Rect2i(0, 0, t, t), Vector2i(8 + c * (t + 8), 8 + r * (t + 8)))
	sheet.save_png(dir + "contact_sheet.png")
	print("sheet: OK"); quit()
