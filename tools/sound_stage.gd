extends SceneTree
## R2-SOUND (D-112): stage the export's audio. Every manifest row becomes Godot's own QOA-compressed
## AudioStreamWAV resource (load_from_buffer with the importer's compress/mode 2), loop points set from
## the manifest, saved as <out>/<kind>/<file>.res. --check also reloads each, compares it with its
## source (QOA format, length to the frame, loop points) and holds the bundle to its export budget.
## Run: godot --headless --path . --script tools/sound_stage.gd -- --out=<dir> [--check] [--budget=<bytes>]


func _initialize() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else ""
	var out := str(args.get("out", "res://audio_bundle"))
	var budget := int(args.get("budget", "6000000"))
	var m := SoundData.load_assets()
	var bad: Array[String] = []
	var total := 0
	for id: String in m.assets:
		var r: Dictionary = m.assets[id]
		var rel := str(r.path)
		var dst := out.path_join(rel.trim_prefix("assets/audio/").get_basename() + ".res")
		DirAccess.make_dir_recursive_absolute(dst.get_base_dir())
		var s := AudioStreamWAV.load_from_buffer(FileAccess.get_file_as_bytes("res://" + rel), {"compress/mode": 2})
		if r.get("loop", null) is Dictionary:
			s.loop_mode = AudioStreamWAV.LOOP_FORWARD
			s.loop_begin = int(r.loop.begin)
			s.loop_end = int(r.loop.end)
		if ResourceSaver.save(s, dst) != OK:
			bad.append("%s: cannot save %s" % [id, dst])
			continue
		var n := FileAccess.get_file_as_bytes(dst).size()
		total += n
		if args.has("check"):
			var back: AudioStreamWAV = ResourceLoader.load(dst, "", ResourceLoader.CACHE_MODE_IGNORE)
			var want_len := float(r.frames) / 48000.0
			if back == null or back.format != AudioStreamWAV.FORMAT_QOA:
				bad.append("%s: the staged resource is not QOA" % id)
			elif absf(back.get_length() - want_len) > 1.0 / 48000.0:
				bad.append("%s: staged length %.6f s, source %.6f s" % [id, back.get_length(), want_len])
			elif r.get("loop", null) is Dictionary and (back.loop_mode != AudioStreamWAV.LOOP_FORWARD or back.loop_end != int(r.loop.end)):
				bad.append("%s: staged loop points lost" % id)
	for b in bad:
		print("FAIL ", b)
	if total > budget:
		bad.append("over budget")
		print("FAIL the staged audio is %d bytes, over the %d export budget" % [total, budget])
	print("sound-stage: %d sounds, %d bytes QOA (of %d source bytes; export budget %d), %d failures" % [m.assets.size(), total, _source_bytes(m), budget, bad.size()])
	quit(1 if bad.size() > 0 else 0)


func _source_bytes(m: Dictionary) -> int:
	var t := 0
	for id: String in m.assets:
		t += int(m.assets[id].bytes)
	return t
