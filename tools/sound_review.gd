extends SceneTree
## R2-SOUND S0b (make sound-review): the listening page's plan and index. Reads the cue table, the
## manifest and make sound-check's measurements; writes to --out:
##   plan.json   for tools/audio/review_main.ail (one gain per sound: its in-game level plus one
##               preview gain shared by every sound, so the loudest peak sits at −1 dBFS and the
##               balance between sounds is the game's), and the bridge ambience mix;
##   sounds.json what each file is: name, when it plays, in-game level, loop or one-shot, duration,
##               source and licence, what to listen for;
##   index.html  a plain page of players (<audio> with Ogg Opus and a WAV fallback).
## Run: godot --headless --path . --script tools/sound_review.gd -- --measure=<file> --out=<dir>
## Order on the page: the spire's hum first (Mark's first listen), the room, the two together, then the rest.

const FIRST := ["spire_hum", "room_bridge", "bridge_ambience"]


func _initialize() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else ""
	var out := str(args.get("out", ""))
	var measure: Variant = SoundData.read_json(str(args.get("measure", "")))
	var table: Variant = SoundData.read_json(SoundData.CUES_PATH)
	var m := SoundData.load_assets()
	if out.is_empty() or not measure is Dictionary or not table is Dictionary:
		print("sound-review: FAIL need --out and a --measure file from make sound-check")
		quit(1)
		return
	var cues := {}
	var peak_max := -120.0
	for c: Dictionary in table.cues:
		cues[c.id] = c
		peak_max = maxf(peak_max, float(measure[c.id].peak_dbfs))
	var preview := snappedf(-1.0 - peak_max, 0.1)
	var items := []
	var rows := []
	for id: String in cues:
		var c: Dictionary = cues[id]
		var a: Dictionary = m.assets[c.streams[0]]
		var lv: Dictionary = measure[id]
		items.append({"id": id, "gain_db": float(c.volume_db) + preview})
		rows.append({"id": id, "name": c.name, "when": c.when, "file_ogg": id + ".ogg", "file_wav": id + ".wav",
			"loop": c.get("loop", false), "duration_s": lv.seconds, "bus": c.bus,
			"in_game": {"rms_dbfs": lv.rms_dbfs, "peak_dbfs": lv.peak_dbfs}, "preview_gain_db": preview,
			"source": "synthesised (AILANG, tools/audio/synth.ail, recipe %s)" % a.provenance.recipe, "licence": a.licence,
			"listen_for": c.listen_for})
	var hum: Dictionary = cues["spire_hum"]
	var room: Dictionary = cues["room_bridge"]
	var mix := {"id": "bridge_ambience", "seconds": 24.0, "parts": [
		{"recipe": "spire_hum", "gain_db": float(hum.volume_db) + preview},
		{"recipe": "room_bridge", "gain_db": float(room.volume_db) + preview}]}
	rows.append({"id": "bridge_ambience", "name": "The bridge, standing still (hum + room together)",
		"when": "Always, on the bridge: what you hear with nothing happening.", "file_ogg": "bridge_ambience.ogg", "file_wav": "bridge_ambience.wav",
		"loop": true, "duration_s": 24.0, "bus": "Ambience", "in_game": {"rms_dbfs": null, "peak_dbfs": null}, "preview_gain_db": preview,
		"source": "a mix of the two synthesised loops at their in-game balance (24 s = 3 hum loops = 2 room loops)", "licence": "synth-own",
		"listen_for": "The bed under everything. Is the hum the right amount above the air? This is the sound of an ordinary minute aboard."})
	var ordered := []
	for id: String in FIRST:
		ordered.append_array(rows.filter(func(r: Dictionary) -> bool: return r.id == id))
	ordered.append_array(rows.filter(func(r: Dictionary) -> bool: return not r.id in FIRST))
	rows = ordered
	DirAccess.make_dir_recursive_absolute(out)
	_write(out.path_join("plan.json"), JSON.stringify({"recipes": "data/audio/recipes.json", "out": out, "items": items, "mixes": [mix]}))
	_write(out.path_join("sounds.json"), JSON.stringify({"schema": "stapledons.audio.review/1", "stage": "s0b",
		"about": "R2-SOUND S0b sound board: every synthesised sound. Files play %.1f dB louder than in game (one shared preview gain, so the balance between sounds is the game's)." % preview,
		"preview_gain_db": preview, "ducking_db": measure.get("_ducking_db", null), "sounds": rows}, " ") + "\n")
	_write(out.path_join("index.html"), _html(rows, preview))
	print("sound-review: plan, sounds.json and index.html for %d sounds in %s (preview gain %+.1f dB)" % [rows.size(), out, preview])
	quit(0)


func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func _html(rows: Array, preview: float) -> String:
	var h := PackedStringArray()
	h.append("<!doctype html><meta charset=utf-8><meta name=viewport content='width=device-width,initial-scale=1'><title>Ship Sound Board</title>")
	h.append("<style>body{background:#0b0d12;color:#e6e9ef;font:16px/1.5 Georgia,serif;margin:0;padding:24px max(16px,env(safe-area-inset-left))}main{max-width:760px;margin:auto}h1{font-weight:600}section{border-top:1px solid #2a2f3a;padding:14px 0}h2{font-size:1.05rem;margin:0}p{margin:4px 0;color:#aab1bf}.lf{color:#e6e9ef}audio{width:100%;margin-top:6px}small{color:#7d8597}</style><main>")
	h.append("<h1>The ship, heard from inside</h1><p>R2-SOUND, first listen (S0b). Every sound is synthesised; nothing is heard from space. Files play %.1f dB louder than in the game, all by the same amount, so their balance is the game's. Start with the spire's hum.</p>" % preview)
	for r: Dictionary in rows:
		var lvl := "in game: RMS %s dBFS, peak %s dBFS" % [r.in_game.rms_dbfs, r.in_game.peak_dbfs] if r.in_game.rms_dbfs != null else "in game: the two loops at their own levels"
		h.append("<section><h2>%s</h2><p>%s</p><p class=lf>Listen for: %s</p><audio controls preload=none%s><source src='%s' type='audio/ogg; codecs=opus'><source src='%s' type='audio/wav'></audio><small>%s · %s · %.2f s · %s · %s</small></section>" % [
			r.name, r.when, r.listen_for, " loop" if r.loop else "", r.file_ogg, r.file_wav, "loop" if r.loop else "one-shot", r.bus, r.duration_s, lvl, r.licence])
	h.append("</main>")
	return "\n".join(h) + "\n"
