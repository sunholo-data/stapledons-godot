extends SceneTree
## Ledger D-113 + R2-SOUND D-108, end to end: the real sim at protocol 2.15 reports the Archive's
## Memory Health and the spire's degradation layer follows it through the sound director.
## Run: AILANG_BIN=$(command -v ailang) godot --headless --path . --script tests/test_sound_archive.gd
var failed := 0
var passed := 0


func check(ok: bool, message: String) -> void:
	if ok: passed += 1
	else: failed += 1
	print("%s %s" % ["ok" if ok else "FAIL", message])


func _initialize() -> void:
	_run.call_deferred()


func session(scenario: String) -> SimBridge:
	var s := SimBridge.new()
	s.want_minor = SimBridge.ARCHIVE_MINOR
	if not s.start() or not s.new_game(7, scenario):
		print("FAIL cannot start a %s session: %s" % [scenario, s.last_error])
		return null
	return s


func drift_db(d: SoundDirector, id: String) -> float:
	var p: AudioStreamPlayer = d.get_node_or_null("Loop_" + id)
	return p.volume_db if p != null else -999.0


func _run() -> void:
	root.add_child(Camera3D.new())
	var d := SoundDirector.new()
	root.add_child(d)
	check(d.setup().is_empty(), "the shipped sound tables validate")
	var drift: Dictionary = d.cues["spire_drift"]
	var bad: Dictionary = d.cues["spire_drift_bad"]

	var sol := session("sol")
	if sol != null:
		check(sol.hello_reply.proto.minor == 15 and int(sol.world.archive.memory_health) == 100, "a 2.15 Sol game: the Archive is whole (memory_health 100)")
		d.on_game("level_bridge")
		d.on_sim_world(sol.world.tick, sol.world)
		check(is_equal_approx(float(d.params.archive_degradation), 0.0) and drift_db(d, "spire_drift") <= float(drift.volume_db) - 79.0, "whole: the degradation layer is silent")
		sol.stop()

	var bh := session("sgr_a")
	if bh != null:
		var h := int(bh.world.archive.memory_health)
		d.on_sim_world(bh.world.tick, bh.world)
		var want := float(drift.volume_db) + SoundDirector.curve_db(drift.param.points, 0.1)
		check(h == 90 and is_equal_approx(float(d.params.archive_degradation), 0.1), "a 2.15 Sgr A* game: memory_health 90 (bh_enter) -> archive_degradation 0.10")
		check(absf(drift_db(d, "spire_drift") - want) < 0.01, "the layer's volume follows it: %.2f dB (curve %.2f dB)" % [drift_db(d, "spire_drift"), want])
		check(drift_db(d, "spire_drift_bad") <= float(bad.volume_db) - 79.0, "the bad layer stays silent at 0.10")
		bh.stop()

	# Deeper degradation, as the sim would report it after decades and more zones.
	var last := -999.0
	var rising := true
	for health in [80, 60, 40, 20, 0]:
		d.on_sim_world(0, {"archive": {"memory_health": health}})
		var v := drift_db(d, "spire_drift")
		rising = rising and v > last
		last = v
	check(rising and drift_db(d, "spire_drift_bad") > float(bad.volume_db) - 10.0, "as Memory Health falls 80 -> 0 the layer rises step by step and the bad layer comes in (%.1f dB, bad %.1f dB)" % [last, drift_db(d, "spire_drift_bad")])
	print("sound-archive: %d passed, %d failures" % [passed, failed])
	quit(1 if failed > 0 else 0)
