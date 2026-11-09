extends SceneTree
## R3-AI-PANEL-V2 P4 (AC13): review renders of the Live AI panel and the badge
## in fixed states, from fixture settings in a scratch directory (never the
## player's user://; the keys are fixtures and no check or call leaves the
## machine: key-check results and replies are set directly).
##   no_key       the title screen's panel, no keys, no voyage
##   gemini_ok    a voyage: Gemini key Working, spend under way, reply dots
##   rejected     the Gemini key rejected: the card and the badge say so
##   offline      three failed replies: the badge says offline
##   text_only    Voices & pictures off: three tiles dim
##   ceiling      the session ceiling reached
## Writes renders/ai_panel/<state>.png at 1920x1080 (the 960x540 UI at 2x) and
## renders/ai_panel/capture.json (the panel's size against the UI space).
## Run: make ai-panel-capture (a window; a 2D capture, no 3D scene)

const OUT := "res://renders/ai_panel"
const KEY_G := "st-fixture-gemini-3e81aa"
const KEY_O := "st-fixture-openrouter-77c0d2"
const STATES := ["no_key", "gemini_ok", "rejected", "offline", "text_only", "ceiling"]

var failures := 0
var report := {}


func _initialize() -> void:
	run.call_deferred()


func settle() -> void:
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw


func scratch(name: String) -> String:
	var d := ProjectSettings.globalize_path("res://.godot/tmp/ai_panel_capture").path_join(name)
	OS.execute("/bin/rm", PackedStringArray(["-rf", d]))
	DirAccess.make_dir_recursive_absolute(d)
	return d


func backdrop() -> Control:
	var c := Control.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.theme = StapledonTheme.theme()
	var sky := ColorRect.new()
	sky.color = StapledonTheme.NIGHT
	sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.add_child(sky)
	return c


func run() -> void:
	root.size = Vector2i(1920, 1080)
	root.title = "Live AI panel review"
	for v in ["GOOGLE_API_KEY", "OPENROUTER_API_KEY", "AI_LIVE"]:
		OS.unset_environment(v)
	DirAccess.make_dir_recursive_absolute(OUT)
	for st in STATES:
		await shoot(st)
	var f := FileAccess.open(OUT + "/capture.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"states": report, "ui_space": [960, 540], "failures": failures}, "  "))
	print("ai-panel-capture: %d frames, %d failures" % [report.size(), failures])
	quit(1 if failures else 0)


func shoot(st: String) -> void:
	var d := scratch(st)
	var s := AiSettings.new()
	s.dir = d
	if st != "no_key":
		s.save_key("gemini", KEY_G)
		s.opt_in = true
		s.text_only = st == "text_only"
		s.set_ceiling(0.5)
		s.save_settings()
	var stage := backdrop()
	root.add_child(stage)
	var panel: Control
	var session: AiSession
	if st == "no_key":
		panel = load(AiIndicator.PANEL).instantiate()
		panel.settings = s
		panel.theme_type_variation = "HUDSheet"
		stage.add_child(panel)
	else:
		session = AiSession.new({}, d)
		session.bridge.live_allowed = false
		stage.add_child(session)
		await settle()
		var ind := session.indicator
		session.key_check.results["gemini"] = {"rejected": "rejected", "offline": "offline"}.get(st, "ok")
		var outcomes := ["ok", "ok", "ok", "error", "ok", "ok", "ok", "ok"]
		if st == "offline":
			outcomes = ["ok", "ok", "ok", "ok", "ok", "error", "error", "error"]
		var kinds := ["text", "text", "voice", "text", "portrait", "text", "feed", "text"]
		for i in outcomes.size():
			ind.on_outcome({"req": str(i), "kind": kinds[i], "status": outcomes[i], "code": "provider_error" if outcomes[i] == "error" else ""})
		ind.usd = {"gemini": 0.5 if st == "ceiling" else 0.034, "openrouter": 0.0}
		ind.budget_hit = st == "ceiling"
		ind.refresh()
		ind.toggle_panel()
		panel = ind.panel
	await settle()
	panel.refresh()
	await settle()
	var r: Rect2 = panel.get_global_rect()
	var fits: bool = r.position.x >= 0 and r.position.y >= 0 and r.end.x <= 960 and r.end.y <= 540
	if not fits:
		failures += 1
		print("FAIL %s: the panel %s does not fit the 960x540 UI space" % [st, r])
	report[st] = {"panel": [r.position.x, r.position.y, r.size.x, r.size.y], "fits": fits,
		"badge": session.indicator.label_text() if session != null else ""}
	root.get_texture().get_image().save_png(OUT + "/" + st + ".png")
	print("shot %s: panel %dx%d at %d,%d%s" % [st, r.size.x, r.size.y, r.position.x, r.position.y, "" if session == null else ", badge '%s'" % session.indicator.label_text()])
	if session != null:
		session.key_check.results.clear()
	stage.queue_free()
	await settle()
