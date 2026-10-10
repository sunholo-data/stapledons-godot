extends SceneTree
## I3b file I/O: sample the AILANG-requested crop indices, returning raw values.
## Requests are grid-id,float32-index CSV. Output is little-endian F64 [id,value].
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 3:
		printerr("usage: ism_fits_sample.gd -- crop.f32 requests.csv output.f64")
		quit(2)
		return
	var src := FileAccess.open(args[0],FileAccess.READ)
	var req := FileAccess.open(args[1],FileAccess.READ)
	var out := FileAccess.open(args[2],FileAccess.WRITE)
	if src == null or req == null or out == null:
		printerr("ism-fits-sample: cannot open input/output")
		quit(1)
		return
	src.big_endian = false
	out.big_endian = false
	var count := 0
	while not req.eof_reached():
		var line := req.get_line()
		if line == "":
			continue
		var fields := line.split(",")
		if fields.size() != 2 or not fields[0].is_valid_int() or not fields[1].is_valid_int():
			printerr("ism-fits-sample: malformed request")
			quit(1)
			return
		var offset := fields[1].to_int() * 4
		if offset < 0 or offset + 4 > src.get_length():
			printerr("ism-fits-sample: index outside crop")
			quit(1)
			return
		src.seek(offset)
		out.store_double(float(fields[0].to_int()))
		out.store_double(src.get_float())
		count += 1
	out.close()
	print("ism-fits-sample: %d raw grid values" % count)
	quit(0)
