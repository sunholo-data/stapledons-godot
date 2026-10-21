extends SceneTree
## R2-SOUND AC8 (make sound-assets-check): the shipped audio manifest's rows (source kinds, licences,
## provenance, generated sound off: D-101) and files (bytes, sha256, 48 kHz 16-bit, frames, loops,
## the git budget). The negative controls live in tests/test_sound.gd.


func _initialize() -> void:
	var m := SoundData.load_assets()
	var bad: Array[String] = []
	bad.append_array(m.errors)
	bad.append_array(SoundData.check_rows(m))
	bad.append_array(SoundData.check_files(m))
	for b in bad:
		print("FAIL ", b)
	var total := 0
	for id: String in m.assets:
		total += int(m.assets[id].get("bytes", 0))
	print("sound-assets-check: %d files, %d bytes of %d, generated %s, %d failures" % [m.assets.size(), total, m.budget_bytes, "allowed" if m.allow_generated else "off", bad.size()])
	quit(1 if bad.size() > 0 else 0)
