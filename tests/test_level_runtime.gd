extends SceneTree
## VF1: production camera views come from level manifests; gameplay uses the evaluator's poses.
var passed := 0
var failed := 0
func check(label: String, ok: bool) -> void:
	if ok: passed += 1
	else: failed += 1
	print("%s %s" % ["ok" if ok else "FAIL", label])
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CameraDirector.VIEWS_PATH))
	check("global camera schema v3 owns no inline level views", raw.schema == "stapledons.camera.views/3" and not raw.has("levels"))
	var d := CameraDirector.new()
	check("level manifests load and validate", d.errors.is_empty() and d.levels.get("bridge", {}).has("manifest"))
	check("bridge framing preserved", d.views.get("bow", {}).get("back_m") == 9.0 and d.views.get("bow", {}).get("rise_m") == 5.5 and d.views.get("bow", {}).get("pitch_deg") == -8.0)
	check("stage API exists", d.has_method("stage_at") and d.has_method("stage_view"))
	if d.has_method("stage_at"):
		var stage: Dictionary = d.call("stage_at", "bridge", Vector3(0,82,-13))
		check("bridge deck resolved from manifest", stage.get("id") == "deck")
		var v: Dictionary = d.call("stage_view", "bridge", Vector3(0,82,-13), "bow")
		check("stage view matches approved bridge", v.get("yaw_deg") == 270.0 and v.get("billboard") == "upright")
	check("height-aware stage pose API exists", d.has_method("stage_pose"))
	if d.has_method("stage_pose"):
		var v := {"yaw_deg":270.0,"pitch_deg":-8.0,"back_m":9.0,"rise_m":5.5}
		for height in [57.0,61.0,66.0]:
			var foot := Vector3(25,height,-5)
			var normal: Transform3D = d.call("stage_pose",v,foot,false)
			var clamped: Transform3D = d.call("stage_pose",v,foot,true)
			check("raised pose matches evaluator at %s" % height, normal.is_equal_approx(LevelMetrics.pose(v,foot)))
			check("ceiling clamp matches evaluator at %s" % height, clamped.is_equal_approx(LevelMetrics.pose(v,foot,true)))
			check("clamp yaw never turns at %s" % height, absf(wrapf(CameraDirector.yaw_pitch(normal).x-CameraDirector.yaw_pitch(clamped).x,-PI,PI))<1e-7)
	print("level-runtime: %d passed, %d failures" % [passed, failed])
	quit(1 if failed else 0)
