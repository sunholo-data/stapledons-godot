extends SceneTree
## R2-SOUND (make sound-review): the listening page's plans and index. Reads the cue table, the
## manifest and make sound-check's measurements; writes to --out:
##   plan.json     for tools/audio/review_main.ail: one gain per sound (its in-game level plus one preview
##                 gain shared by every sound, so the loudest peak sits at −1 dBFS and the balance is
##                 the game's), the bridge ambience mix, and the spire at three degradation levels;
##   plan_v1.json  with --v1-dir (the previous recipes, cue table and manifest part): every sound whose
##                 bytes changed, rendered from its previous recipe at its previous level as <id>_v1, for A/B;
##   sounds.json   what each file is: name, when it plays, in-game level, loop or one-shot, duration,
##                 source and licence, what to listen for, and whether it changed (with its v1 file);
##   index.html    a plain page of players (<audio> with Ogg Opus and a WAV fallback).
## Run: godot --headless --path . --script tools/sound_review.gd -- --measure=<file> --out=<dir> [--v1-dir=<dir>] [--stage=<s>]

const FIRST := ["bridge_walk", "footstep_deck", "console_wake", "console_sleep", "console_key", "lift_start", "lift_run", "lift_arrive", "spire_hum", "spire_degradation_pristine", "spire_degradation_mid", "spire_degradation_bad", "room_bridge", "bridge_ambience"]
## The three Archive states Mark hears (archive_degradation = 1 − Memory Health/100).
const LEVELS := {"pristine": 0.0, "mid": 0.5, "bad": 0.9}


func _initialize() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else ""
	var out := str(args.get("out", ""))
	var stage := str(args.get("stage", "s0b"))
	var measure: Variant = SoundData.read_json(str(args.get("measure", "")))
	var table: Variant = SoundData.read_json(SoundData.CUES_PATH)
	var m := SoundData.load_assets()
	if out.is_empty() or not measure is Dictionary or not table is Dictionary:
		print("sound-review: FAIL need --out and a --measure file from make sound-check")
		quit(1)
		return
	var v1 := {}
	var v1_dir := str(args.get("v1-dir", ""))
	if not v1_dir.is_empty():
		var vc: Variant = SoundData.read_json(v1_dir.path_join("cues_v1.json"))
		var va: Variant = SoundData.read_json(v1_dir.path_join("assets_synth_v1.json"))
		if vc is Dictionary and va is Dictionary:
			for c: Dictionary in vc.cues:
				v1[c.id] = {"cue": c}
			for a: Dictionary in va.assets:
				if v1.has(a.id):
					v1[a.id]["sha256"] = a.sha256
	var cues := {}
	var peak_max := -120.0
	for c: Dictionary in table.cues:
		cues[c.id] = c
		peak_max = maxf(peak_max, float(measure[c.id].peak_dbfs))
	var preview := snappedf(-1.0 - peak_max, 0.1)
	var items := []
	var items_v1 := []
	var rows := []
	for id: String in cues:
		var c: Dictionary = cues[id]
		var a: Dictionary = m.assets[c.streams[0]]
		var lv: Dictionary = measure[id]
		var top := 0.0
		if c.has("param"):
			top = -80.0
			for p: Array in c.param.points:
				top = maxf(top, float(p[1]))
		items.append({"id": str(c.streams[0]), "file": id, "gain_db": float(c.volume_db) + top + preview})
		var changed := "new"
		if v1.has(id):
			changed = "changed" if v1[id].get("sha256", "") != a.sha256 or float(v1[id].cue.volume_db) != float(c.volume_db) else "unchanged"
		var row := {"id": id, "name": c.name, "when": c.when, "file_ogg": id + ".ogg", "file_wav": id + ".wav",
			"loop": c.get("loop", false), "duration_s": lv.seconds, "bus": c.bus,
			"in_game": {"rms_dbfs": lv.rms_dbfs, "peak_dbfs": lv.peak_dbfs}, "preview_gain_db": preview,
			"source": "synthesised (AILANG, tools/audio/synth.ail, recipe %s)" % a.provenance.recipe, "licence": a.licence,
			"listen_for": c.listen_for, "status": changed if not v1.is_empty() else "new"}
		if c.has("param"):
			row["in_game_note"] = "level shown is the fully degraded maximum; silent while the Archive is intact"
		if changed == "changed":
			items_v1.append({"id": str(v1[id].cue.streams[0]), "file": id + "_v1", "gain_db": float(v1[id].cue.volume_db) + preview})
			row["v1_ogg"] = id + "_v1.ogg"
			row["v1_wav"] = id + "_v1.wav"
		rows.append(row)
	var hum: Dictionary = cues["spire_hum"]
	var room: Dictionary = cues["room_bridge"]
	var mixes := [{"id": "bridge_ambience", "seconds": 24.0, "parts": [
		{"recipe": "spire_hum", "gain_db": float(hum.volume_db) + preview, "at": []},
		{"recipe": "room_bridge", "gain_db": float(room.volume_db) + preview, "at": []}]}]
	var amb := {"id": "bridge_ambience", "name": "The bridge, standing still (hum + room together)",
		"when": "Always, on the bridge: what you hear with nothing happening (the Archive intact).", "file_ogg": "bridge_ambience.ogg", "file_wav": "bridge_ambience.wav",
		"loop": true, "duration_s": 24.0, "bus": "Ambience", "in_game": {"rms_dbfs": null, "peak_dbfs": null}, "preview_gain_db": preview,
		"source": "a mix of the two synthesised loops at their in-game balance (24 s = 3 hum loops = 2 room loops)", "licence": "synth-own",
		"listen_for": "The hum should lead now and the air sit far underneath it (D-108: the room was dominant and annoying).", "status": "changed" if not v1.is_empty() else "new"}
	var mixes_v1 := []
	if v1.has("room_bridge") and v1.has("spire_hum"):
		mixes_v1.append({"id": "bridge_ambience_v1", "seconds": 24.0, "parts": [
			{"recipe": "spire_hum", "gain_db": float(v1.spire_hum.cue.volume_db) + preview, "at": []},
			{"recipe": "room_bridge", "gain_db": float(v1.room_bridge.cue.volume_db) + preview, "at": []}]})
		amb["v1_ogg"] = "bridge_ambience_v1.ogg"
		amb["v1_wav"] = "bridge_ambience_v1.wav"
	rows.append(amb)
	if cues.has("spire_drift") and cues.has("spire_drift_bad"):
		var dr: Dictionary = cues["spire_drift"]
		var bd: Dictionary = cues["spire_drift_bad"]
		var probe := SoundDirector.new()
		for lvl: String in LEVELS:
			var x: float = LEVELS[lvl]
			probe.params["archive_degradation"] = x
			var mid := "spire_degradation_" + lvl
			mixes.append({"id": mid, "seconds": 32.0, "parts": [
				{"recipe": "spire_hum", "gain_db": float(hum.volume_db) + preview, "at": []},
				{"recipe": "spire_drift", "gain_db": float(dr.volume_db) + probe.param_offset(dr) + preview, "at": []},
				{"recipe": "spire_drift_bad", "gain_db": float(bd.volume_db) + probe.param_offset(bd) + preview, "at": []}]})
			rows.append({"id": mid, "name": "The spire, Archive %s (degradation %.1f, Memory Health %d)" % [lvl, x, roundi(100.0 * (1.0 - x))],
				"when": "The bridge's hum as the Archive's Memory Health falls. The sim does not emit Memory Health yet, so in the game today the hum is always 'pristine'.",
				"file_ogg": mid + ".ogg", "file_wav": mid + ".wav", "loop": true, "duration_s": 32.0, "bus": "Ambience",
				"in_game": {"rms_dbfs": null, "peak_dbfs": null}, "preview_gain_db": preview,
				"source": "the hum plus the two degradation layers at their in-game levels for this degradation (32 s = 4 hum loops = 1 drift loop)", "licence": "synth-own",
				"listen_for": {"pristine": "The hum alone, as it is today.", "mid": "The second, slower beat under the hum: one long cycle every 32 s with a little grit. Unsettling, not broken.", "bad": "The beat roughened and wavering, a tone that does not belong. It should feel wrong without being loud."}[lvl],
				"status": "new"})
		probe.free()
	if cues.has("footstep_deck") and cues.has("lift_start"):
		# S1: a scripted minute on the bridge, flat (the dev build has the real 3D placement): a walk,
		# a console, another walk, the lift. Footsteps every 0.55 s, the six variants in turn.
		var fs: Dictionary = cues["footstep_deck"]
		var steps := []
		for k in 6:
			steps.append([])
		var t := 0.6
		var k := 0
		while t < 8.0:
			steps[k % 6].append(snappedf(t, 0.001)); t += 0.55; k += 1
		t = 14.0
		while t < 18.5:
			steps[k % 6].append(snappedf(t, 0.001)); t += 0.55; k += 1
		var walk := {"id": "bridge_walk", "seconds": 30.0, "parts": [
			{"recipe": "spire_hum", "gain_db": float(hum.volume_db) + preview, "at": []},
			{"recipe": "room_bridge", "gain_db": float(room.volume_db) + preview, "at": []},
			{"recipe": "console_wake", "gain_db": float(cues.console_wake.volume_db) + preview, "at": [9.0]},
			{"recipe": "ui_click", "gain_db": float(cues.console_key.volume_db) + preview, "at": [10.5, 11.2]},
			{"recipe": "console_sleep", "gain_db": float(cues.console_sleep.volume_db) + preview, "at": [12.6]},
			{"recipe": "lift_start", "gain_db": float(cues.lift_start.volume_db) + preview, "at": [19.5]},
			{"recipe": "lift_arrive", "gain_db": float(cues.lift_arrive.volume_db) + preview, "at": [26.0]}]}
		for i in 6:
			walk.parts.append({"recipe": fs.streams[i], "gain_db": float(fs.volume_db) + preview, "at": steps[i]})
		mixes.append(walk)
		rows.append({"id": "bridge_walk", "name": "A minute on the bridge (flat mix)", "when": "Walk to the helm, use the navigation console, walk on, take the lift down.",
			"file_ogg": "bridge_walk.ogg", "file_wav": "bridge_walk.wav", "loop": false, "duration_s": 30.0, "bus": "mix",
			"in_game": {"rms_dbfs": null, "peak_dbfs": null}, "preview_gain_db": preview,
			"source": "a scripted mix of the shipped sounds at their in-game levels; flat here, positioned around the captain in the dev build", "licence": "synth-own",
			"listen_for": "Do the steps sit under the hum without clattering? Does the console feel like a precise machine? The lift: latch, motor, one low bell.", "status": "new"})
	var ordered := []
	for id: String in FIRST:
		ordered.append_array(rows.filter(func(r: Dictionary) -> bool: return r.id == id))
	ordered.append_array(rows.filter(func(r: Dictionary) -> bool: return not r.id in FIRST))
	rows = ordered
	DirAccess.make_dir_recursive_absolute(out)
	_write(out.path_join("plan.json"), JSON.stringify({"recipes": "data/audio/recipes.json", "out": out, "items": items, "mixes": mixes}))
	if not v1.is_empty():
		_write(out.path_join("plan_v1.json"), JSON.stringify({"recipes": v1_dir.path_join("recipes_v1.json"), "out": out, "items": items_v1, "mixes": mixes_v1}))
	var changed_ids := rows.filter(func(r: Dictionary) -> bool: return r.status != "unchanged").map(func(r: Dictionary) -> String: return r.id)
	_write(out.path_join("sounds.json"), JSON.stringify({"schema": "stapledons.audio.review/1", "stage": stage,
		"about": "R2-SOUND sound board (%s). Files play %.1f dB louder than in game (one shared preview gain, so the balance between sounds is the game's). Changed sounds keep their previous version as <id>_v1 for A/B." % [stage, preview],
		"preview_gain_db": preview, "ducking_db": measure.get("_ducking_db", null), "changed_or_new": changed_ids, "sounds": rows}, " ") + "\n")
	_write(out.path_join("index.html"), _html(rows, preview, stage))
	print("sound-review: plan%s, sounds.json and index.html for %d sounds in %s (preview gain %+.1f dB, %d changed or new)" % [", plan_v1" if not v1.is_empty() else "", rows.size(), out, preview, changed_ids.size()])
	quit(0)


func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func _player(ogg: String, wav: String, loop: bool) -> String:
	return "<audio controls preload=none%s><source src='%s' type='audio/ogg; codecs=opus'><source src='%s' type='audio/wav'></audio>" % [" loop" if loop else "", ogg, wav]


func _html(rows: Array, preview: float, stage: String) -> String:
	var h := PackedStringArray()
	h.append("<!doctype html><meta charset=utf-8><meta name=viewport content='width=device-width,initial-scale=1'><title>Ship Sound Board</title>")
	h.append("<style>body{background:#0b0d12;color:#e6e9ef;font:16px/1.5 Georgia,serif;margin:0;padding:24px max(16px,env(safe-area-inset-left))}main{max-width:760px;margin:auto}h1{font-weight:600}section{border-top:1px solid #2a2f3a;padding:14px 0}h2{font-size:1.05rem;margin:0}p{margin:4px 0;color:#aab1bf}.lf{color:#e6e9ef}audio{width:100%;margin-top:6px}small{color:#7d8597}.tag{font:600 .7rem sans-serif;letter-spacing:.06em;text-transform:uppercase;color:#d9a24a;margin-left:8px}</style><main>")
	h.append("<h1>The ship, heard from inside</h1><p>R2-SOUND sound board (%s). Every sound is synthesised; nothing is heard from space. Files play %.1f dB louder than in the game, all by the same amount, so their balance is the game's. Changed sounds have their previous version underneath for A/B.</p>" % [stage, preview])
	for r: Dictionary in rows:
		var lvl := "in game: RMS %s dBFS, peak %s dBFS" % [r.in_game.rms_dbfs, r.in_game.peak_dbfs] if r.in_game.rms_dbfs != null else "in game: the loops at their own levels"
		var tag := "" if r.status == "unchanged" else "<span class=tag>%s</span>" % r.status
		var v1 := ""
		if r.has("v1_ogg"):
			v1 = "<p>Previous version (v1):</p>" + _player(r.v1_ogg, r.v1_wav, r.loop)
		h.append("<section><h2>%s%s</h2><p>%s</p><p class=lf>Listen for: %s</p>%s%s<small>%s · %s · %.2f s · %s · %s</small></section>" % [
			r.name, tag, r.when, r.listen_for, _player(r.file_ogg, r.file_wav, r.loop), v1, "loop" if r.loop else "one-shot", r.bus, r.duration_s, lvl, r.licence])
	h.append("</main>")
	return "\n".join(h) + "\n"
