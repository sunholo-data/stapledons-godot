extends SceneTree
## R2-SOUND (design_docs/planned/r2/sound.md) AC1-AC5, AC8 (rows), AC10 (later), the bus layout:
## the cue table and manifest validators with their negative controls, the sim/UI/walk clocks,
## deterministic variants, the visual-counterpart and no-judgement rules, the D-101 generated-sound
## gate, and the bus layout (§D2).
## Run: godot --headless --path . --script tests/test_sound.gd [-- --log-out=<file>]
## --log-out writes the scripted session's cue log, for the two-process determinism check (AC2).
var failed := 0
var passed := 0
var scratch := ProjectSettings.globalize_path("res://.godot/tmp/sound_test")


func check(ok: bool, message: String) -> void:
	if ok: passed += 1
	else: failed += 1
	print("%s %s" % ["ok" if ok else "FAIL", message])


func _initialize() -> void:
	_run.call_deferred()


func _args() -> Dictionary:
	var out := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		out[kv[0]] = kv[1] if kv.size() > 1 else ""
	return out


func write(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


## A tiny tone WAV under <root>/assets/audio/<kind>/<id>.wav and its manifest row.
func tone(root: String, id: String, kind := "synth", frames := 4800) -> Dictionary:
	var pcm := PackedByteArray()
	pcm.resize(frames * 2)
	for i in frames:
		pcm.encode_s16(i * 2, int(8000.0 * sin(TAU * 440.0 * i / 48000.0)))
	var rel := "assets/audio/%s/%s.wav" % [kind, id]
	var p := root.path_join(rel)
	DirAccess.make_dir_recursive_absolute(p.get_base_dir())
	var f := FileAccess.open(p, FileAccess.WRITE)
	f.store_buffer(SoundData.wav_bytes(pcm, 48000, 1))
	f.close()
	var prov := {"generator": "tools/audio/synth.ail", "generator_sha256": "0".repeat(64), "recipe": id}
	var lic := "synth-own"
	if kind == "library":
		prov = {"url": "https://kenney.nl/assets/x", "author": "Kenney", "retrieved": "2026-10-20", "download_sha256": "1".repeat(64)}
		lic = "CC0-1.0"
	elif kind == "generated":
		prov = {"tool": "x", "model": "y", "prompt_sha256": "2".repeat(64), "date": "2026-10-20", "terms_url": "https://example.org"}
		lic = "generated-licensed"
	return {"id": id, "path": rel, "bytes": FileAccess.get_file_as_bytes(p).size(), "sha256": FileAccess.get_sha256(p),
		"rate": 48000, "channels": 1, "frames": frames, "loop": null, "source_kind": kind, "licence": lic, "author": "test", "provenance": prov}


func manifest(root: String, rows: Array, allow_generated := false) -> String:
	write(root.path_join("data/audio/assets_test.json"), JSON.stringify({"schema": SoundData.PART_SCHEMA, "assets": rows}))
	var top := root.path_join("data/audio/assets.json")
	write(top, JSON.stringify({"schema": SoundData.ASSETS_SCHEMA, "allow_generated": allow_generated, "budget_bytes": 12000000, "parts": ["assets_test.json"]}))
	return top


const VIS_ARRIVED := "ui/arrival_card.gd::class_name ArrivalCard"
const VIS_PHASE := "ui/journey_hud.gd::ship.phase"


func base_cues() -> Array:
	return [
		{"id": "commit_seal", "trigger": {"kind": "sim_event", "k": "committed"}, "streams": ["a"], "bus": "Effects", "volume_db": -6.0, "visual": "ui/galaxy_map.gd::committed", "about": "the sealing chord"},
		{"id": "drive_boost", "trigger": {"kind": "sim_event", "k": "phase", "match": {"to": "boosting"}}, "streams": ["a"], "bus": "Effects", "volume_db": -8.0, "visual": VIS_PHASE, "about": "the emitter rises"},
		{"id": "drive_silent", "trigger": {"kind": "sim_event", "k": "phase", "match": {"to": "cruising"}}, "streams": ["a"], "bus": "Effects", "volume_db": -8.0, "visual": VIS_PHASE, "about": "the drive falls silent"},
		{"id": "arrived", "trigger": {"kind": "sim_event", "k": "arrived"}, "streams": ["a", "b"], "bus": "Instruments", "volume_db": -10.0, "pitch_cents_spread": 20, "visual": VIS_ARRIVED, "about": "a neutral chime"},
		{"id": "medium_change", "trigger": {"kind": "sim_state", "path": "ship.ism.medium"}, "streams": ["a"], "bus": "Instruments", "volume_db": -14.0, "visual": "ui/ism_hud.gd::medium", "about": "a cloud edge"},
		{"id": "ui_click", "trigger": {"kind": "ui_signal", "name": "click"}, "streams": ["a", "b"], "bus": "UI", "volume_db": -12.0, "cooldown": 2, "visual": "ambient: interface feedback only", "about": "a click"},
		{"id": "footstep", "trigger": {"kind": "game", "name": "step"}, "streams": ["a", "b"], "bus": "Effects", "volume_db": -14.0, "pitch_cents_spread": 30, "visual": "ambient: the walk is on screen", "about": "a step on plating"},
		{"id": "spire_hum", "trigger": {"kind": "game", "name": "level_bridge", "stop_on": "level_none"}, "streams": ["a"], "bus": "Ambience", "loop": true, "volume_db": -20.0, "visual": "ambient: the spire is always there", "about": "the hum"},
	]


func cues_file(root: String, cues: Array) -> String:
	var p := root.path_join("data/audio/cues.json")
	write(p, JSON.stringify({"schema": SoundData.CUES_SCHEMA, "cues": cues}))
	return p


func director(root: String, cues: Array, rows: Array) -> SoundDirector:
	var d := SoundDirector.new()
	d.audible = false
	d.setup(cues_file(root, cues), manifest(root, rows), "res://")
	return d


func fresh(name: String) -> String:
	var d := scratch.path_join(name)
	OS.execute("/bin/rm", PackedStringArray(["-rf", d]))
	DirAccess.make_dir_recursive_absolute(d)
	return d


## The scripted session for AC2/AC3/AC4 (S0a): sim events, a cloud edge, clicks and a walk.
func session(d: SoundDirector) -> void:
	d.on_game("level_bridge")
	d.on_sim_step(10, [{"k": "echo"}, {"k": "committed"}, {"k": "phase", "from": "at_rest", "to": "boosting"}])
	d.on_sim_world(11, {"ship": {"ism": {"medium": "LIC"}}})
	d.on_sim_world(12, {"ship": {"ism": {"medium": "LIC"}}})
	d.on_sim_world(13, {"ship": {"ism": {"medium": "LB"}}})
	d.on_sim_step(40, [{"k": "phase", "from": "boosting", "to": "cruising"}])
	for i in 3:
		d.on_ui("click")
	d.walked(3.5)
	d.walked(3.5)
	d.on_sim_step(90, [{"k": "phase", "from": "braking", "to": "at_rest"}, {"k": "arrived"}])
	d.on_sim_step(91, [{"k": "arrived"}])
	d.on_game("level_none")


func _run() -> void:
	var root := fresh("tables")
	var rows := [tone(root, "a"), tone(root, "b")]
	# The tables reference files under <root>; resolve them there.
	var d := SoundDirector.new()
	d.audible = false
	var errs := d.setup(cues_file(root, base_cues()), manifest(root, rows), "res://")
	check(errs.is_empty(), "AC1: a well-formed cue table and manifest validate (%s)" % "; ".join(errs))
	check(SoundData.check_files(SoundData.load_assets(root.path_join("data/audio/assets.json")), root).is_empty(), "AC8: the files match their manifest rows (bytes, sha256, 48 kHz 16-bit, frames)")

	# AC1 negative controls: each defect alone is rejected.
	var bad_trigger := base_cues()
	bad_trigger[0] = bad_trigger[0].duplicate(true)
	bad_trigger[0].trigger = {"kind": "sim_evnt", "k": "committed"}
	var e1 := SoundData.check_cues({"schema": SoundData.CUES_SCHEMA, "cues": bad_trigger}, d.assets)
	check(e1.size() == 1 and e1[0].contains("unknown trigger kind"), "AC1: a renamed trigger kind is rejected (%s)" % "; ".join(e1))
	var bad_stream := base_cues()
	bad_stream[1] = bad_stream[1].duplicate(true)
	bad_stream[1].streams = ["nope"]
	var e2 := SoundData.check_cues({"schema": SoundData.CUES_SCHEMA, "cues": bad_stream}, d.assets)
	check(e2.size() == 1 and e2[0].contains("not in the asset manifest"), "AC1: a missing stream is rejected (%s)" % "; ".join(e2))
	var bad_bus := base_cues()
	bad_bus[2] = bad_bus[2].duplicate(true)
	bad_bus[2].bus = "Ship"
	var e3 := SoundData.check_cues({"schema": SoundData.CUES_SCHEMA, "cues": bad_bus}, d.assets)
	check(e3.size() == 1 and e3[0].contains("not a cue bus"), "AC1: an unknown or mixing bus is rejected (%s)" % "; ".join(e3))

	# AC5: the visual counterpart and the forbidden words.
	var no_vis := base_cues()
	no_vis[3] = no_vis[3].duplicate(true)
	no_vis[3].visual = "ambient: none"
	var e4 := SoundData.check_cues({"schema": SoundData.CUES_SCHEMA, "cues": no_vis}, d.assets)
	check(e4.size() == 1 and e4[0].contains("visual counterpart"), "AC5: an informative cue without a visual counterpart in the code is rejected")
	var ghost := base_cues()
	ghost[3] = ghost[3].duplicate(true)
	ghost[3].visual = "ui/arrival_card.gd::NoSuchThing"
	check(SoundData.check_cues({"schema": SoundData.CUES_SCHEMA, "cues": ghost}, d.assets).size() == 1, "AC5: a counterpart that does not exist in the code is rejected")
	var judging := base_cues()
	judging[3] = judging[3].duplicate(true)
	judging[3].about = "a victory fanfare on arrival"
	var e5 := SoundData.check_cues({"schema": SoundData.CUES_SCHEMA, "cues": judging}, d.assets)
	check(e5.size() == 2 and e5[0].contains("judges the player"), "AC5: 'victory' and 'fanfare' are rejected (Pillar 2)")
	var window := base_cues()
	window[5] = window[5].duplicate(true)
	window[5].about = "a click when a window opens"
	check(SoundData.check_cues({"schema": SoundData.CUES_SCHEMA, "cues": window}, d.assets).is_empty(), "AC5: whole words only ('window' is not 'win')")

	# AC8 and D-101: licences, provenance, generated sound reserved and off.
	var lib := tone(root, "lib_ok", "library")
	var gen := tone(root, "gen", "generated")
	var m := SoundData.load_assets(manifest(root, [lib, gen]))
	var e6 := SoundData.check_rows(m)
	check(e6.size() == 1 and e6[0].contains("not allowed yet"), "D-101: a generated row is rejected while allow_generated is false (%s)" % "; ".join(e6))
	check(SoundData.check_rows(SoundData.load_assets(manifest(root, [lib, gen], true))).is_empty(), "D-101: the same generated row with full provenance passes once allow_generated is true (the slot is ready)")
	var ccby := lib.duplicate(true)
	ccby.licence = "CC-BY-4.0"
	check(SoundData.check_rows(SoundData.load_assets(manifest(root, [ccby]))).size() == 1, "AC8: a CC-BY library file is rejected (CC0 only)")
	var noprov := lib.duplicate(true)
	noprov.provenance.erase("url")
	check(SoundData.check_rows(SoundData.load_assets(manifest(root, [noprov]))).size() == 1, "AC8: a library file without its URL is rejected")
	var wrongsha := tone(root, "a")
	wrongsha.sha256 = "f".repeat(64)
	var e7 := SoundData.check_files(SoundData.load_assets(manifest(root, [wrongsha])), root)
	check(e7.size() == 1 and e7[0].contains("sha256"), "AC8: a wrong sha256 is rejected")
	var over := SoundData.load_assets(manifest(root, rows))
	over.budget_bytes = 100
	check(SoundData.check_files(over, root).back().contains("budget"), "AC8: the git budget is enforced")

	# AC4 and the clocks: the scripted session.
	var s := director(root, base_cues(), rows)
	session(s)
	var want := PackedStringArray([
		"g1 spire_hum", "t10.1 commit_seal", "t10.2 drive_boost", "t13.s medium_change", "t40.0 drive_silent",
		"u1 ui_click", "u3 ui_click", "w1 footstep", "w10 footstep", "t90.1 arrived", "t91.0 arrived"])
	var got := s.log_text()
	var order_ok := true
	var at := 0
	for w in want:
		var i := got.find(w, at)
		if i < 0: order_ok = false
		else: at = i
	check(order_ok, "AC4: sim events, a state edge, UI inputs and steps fire their cues in order:\n" + got)
	check(not got.contains("t10.0"), "AC4: an event with no cue (echo) fires nothing")
	check(not got.contains("u2 "), "the UI cooldown counts inputs: the second click of three is skipped")
	check(not got.contains("t12"), "a sim_state cue fires on a change, not on every tick")
	check(s.steps() == 10, "AC3: 7.0 m walked in two halves gives 10 steps (got %d)" % s.steps())
	var a := director(root, base_cues(), rows)
	a.add_walk_mm(6990)
	var b := director(root, base_cues(), rows)
	b.add_walk_mm(7000)
	check(a.steps() == 9 and b.steps() == 10, "AC3: the integer accumulator: 6,990 mm -> 9 steps, 7,000 mm -> 10")
	var c := director(root, base_cues(), rows)
	for i in 700:
		c.walked(0.01)
	check(c.steps() == 10, "AC3: 700 frames of 10 mm also give 10 steps (frame split does not matter)")
	var again := director(root, base_cues(), rows)
	session(again)
	check(again.log_text() == got, "AC2: the same input gives a byte-identical cue log in one process")
	var v1 := director(root, base_cues(), rows)
	var v2 := director(root, base_cues(), rows)
	for i in 40:
		v1.fire("arrived", "x%d" % i, i)
		v2.fire("arrived", "x%d" % i, i)
	var vt := v1.log_text()
	var cents_ok := true
	for l in v1.cue_log:
		var cts := int(l.split(" ")[3].trim_suffix("c"))
		cents_ok = cents_ok and absi(cts) <= 20
	check(vt == v2.log_text() and vt.contains(" v0 ") and vt.contains(" v1 ") and cents_ok, "deterministic variation: 40 fires use both variants, pitch within +/-20 cents, identical in two directors")
	check(s.cue_log.size() > 0 and s.errors.is_empty(), "the director logs while silent (audible = false)")

	# D-108: the spire's degradation layer follows a parameter; the sim's Memory Health drives it when present.
	var drift := {"id": "drift", "trigger": {"kind": "game", "name": "level_bridge", "stop_on": "level_none"}, "streams": ["a"], "bus": "Ambience", "loop": true,
		"volume_db": -20.0, "param": {"name": "archive_degradation", "points": [[0.0, -80.0], [0.5, -10.0], [1.0, -4.0]]}, "visual": "ambient: no information", "about": "test"}
	var pd := director(root, base_cues() + [drift], rows)
	check(pd.errors.is_empty(), "D-108: a loop with a param curve validates (%s)" % "; ".join(pd.errors))
	check(is_equal_approx(SoundDirector.curve_db(drift.param.points, 0.25), -45.0) and is_equal_approx(SoundDirector.curve_db(drift.param.points, 1.5), -4.0), "D-108: the param curve interpolates (0.25 -> -45 dB) and clamps")
	pd.on_sim_world(5, {"ship": {}})
	check(not pd.params.has("archive_degradation"), "D-108: with no Memory Health in the world the layer stays pristine (nothing is invented)")
	pd.on_sim_world(6, {"archive": {"memory_health": 50}})
	check(is_equal_approx(float(pd.params.archive_degradation), 0.5) and pd.log_text().contains("p1 archive_degradation 0.50"), "D-108: archive.memory_health 50 -> archive_degradation 0.50, logged")
	pd.on_sim_world(7, {"archive": {"memory_health": 50.4}})
	check(not pd.log_text().contains("p2 "), "D-108: a change under 0.01 is not logged again")
	pd.on_game("level_bridge")
	check(pd.log_text().contains("drift v0 +0c -30.0dB"), "D-108: the layer starts at its curve's level for the current degradation (-20 + -10 dB):\n" + pd.log_text())
	var badp := base_cues() + [drift.duplicate(true)]
	badp.back().loop = false
	check(SoundData.check_cues({"schema": SoundData.CUES_SCHEMA, "cues": badp}, pd.assets).size() == 1, "D-108: a one-shot cannot follow a param")
	var badn := base_cues() + [drift.duplicate(true)]
	badn.back().param = {"name": "mood", "points": [[0.0, 0.0], [1.0, 0.0]]}
	check(SoundData.check_cues({"schema": SoundData.CUES_SCHEMA, "cues": badn}, pd.assets).size() == 1, "D-108: an unknown param is rejected")

	# The shipped tables (S0b): they validate, and a loop loads with its manifest loop points.
	var shipped := SoundDirector.new()
	shipped.audible = false
	var se := shipped.setup()
	check(se.is_empty() and shipped.cues.size() >= 17, "the shipped cue table and manifest validate (%d cues; %s)" % [shipped.cues.size(), "; ".join(se)])
	var hum := shipped.stream("spire_hum")
	check(hum != null and hum.loop_mode == AudioStreamWAV.LOOP_FORWARD and hum.loop_end == 384000 and hum.mix_rate == 48000, "spire_hum loads as a 48 kHz loop of 384,000 frames (8 s)")
	check(SoundDirector.bundle_path("assets/audio/synth/nope.wav") == "res://audio_bundle/synth/nope.res", "the export reads the staged QOA bundle (audio_bundle/<kind>/<file>.res)")
	shipped.free()

	# The bus layout (§D2).
	SoundMix.ensure_layout()
	var lay := SoundMix.is_layout_ok()
	check(lay.is_empty(), "§D2: the bus layout matches SoundMix.BUSES (%s)" % "; ".join(lay))
	SoundMix.ensure_layout()
	check(AudioServer.bus_count == 1 + SoundMix.BUSES.size(), "§D2: ensure_layout is idempotent (%d buses)" % AudioServer.bus_count)
	check(is_equal_approx(SoundMix.percent_to_db(100), 0.0) and SoundMix.percent_to_db(0) <= -80.0 and absf(SoundMix.percent_to_db(50) + 12.04) < 0.01, "AC9: 100% = 0 dB, 50% = -12 dB, 0% mutes")

	var args := _args()
	if args.has("log-out"):
		var f := FileAccess.open(args["log-out"], FileAccess.WRITE)
		f.store_string(got)
		f.close()
	print("sound: %d passed, %d failures" % [passed, failed])
	quit(1 if failed > 0 else 0)
