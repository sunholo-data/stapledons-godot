extends SceneTree
## R2-HOME-TIERS (design home-tiers.md H4): the website's concept-art thumbnails, made from the
## full-size masters (D-18: the masters live in the public bucket, not in git). Image I/O is Godot
## (CLAUDE.md, Python): Lanczos down to 800 px wide, JPEG quality 0.85.
## Run:  godot --headless --path . --script tools/concept_thumbs.gd -- <master.png> <out.jpg> [<master.png> <out.jpg> ...]

const WIDTH := 800
const QUALITY := 0.85


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var failures := 0
	if args.size() == 0 or args.size() % 2 != 0:
		print("concept-thumbs: FAIL give <master.png> <out.jpg> pairs"); quit(1); return
	for i in range(0, args.size(), 2):
		var img := Image.load_from_file(args[i])
		if img == null or img.is_empty():
			failures += 1; print("FAIL %s: not an image" % args[i]); continue
		var h := int(round(float(img.get_height()) * WIDTH / img.get_width()))
		img.resize(WIDTH, h, Image.INTERPOLATE_LANCZOS)
		var err := img.save_jpg(args[i + 1], QUALITY)
		if err != OK:
			failures += 1; print("FAIL %s: save %d" % [args[i + 1], err]); continue
		print("thumb %s %dx%d" % [args[i + 1].get_file(), WIDTH, h])
	print("concept-thumbs: %d failures" % failures)
	quit(1 if failures else 0)
