extends SceneTree
## Offline file/image I/O only. The archival display stretch is labelled processing,
## never a spectral/radiometric model and never transformed by the ship's Doppler.
const Fits = preload("res://tools/observation_fits.gd")

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2:
		printerr("usage: observation_prepare.gd -- input.fits output-directory")
		quit(2)
		return
	var decoded: Dictionary = Fits.decode(FileAccess.get_file_as_bytes(args[0]))
	if not decoded.ok:
		printerr(decoded.error)
		quit(1)
		return
	var raw: Image = decoded.image
	var image := Image.create(raw.get_width(), raw.get_height(), false, Image.FORMAT_RGB8)
	var upper: float = log(1.0 + maxf(decoded.max, 0.0) * 100.0)
	for y in image.get_height():
		for x in image.get_width():
			var v: float = maxf(raw.get_pixel(x, y).r, 0.0)
			var tone: float = log(1.0 + v * 100.0) / upper if upper > 0.0 else 0.0
			image.set_pixel(x, image.get_height() - 1 - y, Color(tone, tone, tone))
	var path := args[1]
	DirAccess.make_dir_recursive_absolute(path)
	var rc := image.save_png(path.path_join("detail.png"))
	var w := image.get_width()
	var h := image.get_height()
	image.resize(maxi(1, w / 2), maxi(1, h / 2), Image.INTERPOLATE_LANCZOS)
	rc = maxi(rc, image.save_png(path.path_join("overview.png")))
	var info := {"source_sha256": FileAccess.get_sha256(args[0]), "source_width": w, "source_height": h,
		"header": decoded.header, "min": decoded.min, "max": decoded.max,
		"processing": "VIS monochrome; log(1+100*max(flux,0))/log(1+100*source_max); y flipped from FITS bottom-left; overview Lanczos half-size"}
	var f := FileAccess.open(path.path_join("preparation.json"), FileAccess.WRITE)
	if f == null:
		quit(1)
		return
	f.store_string(JSON.stringify(info, "\t") + "\n")
	print("observation-prepare: 2 images, %d failures" % (0 if rc == OK else 1))
	quit(0 if rc == OK else 1)
