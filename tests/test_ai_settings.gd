extends SceneTree
## Live AI settings, indicator and game wiring (sprint R1-AI-FOUNDATION AI.9,
## design ai-service-foundation (a5)). Settings and keys live in a scratch
## directory, never the player's user://; the key env vars are cleared first;
## every key is a fixture. Nothing here spends: the indicator check runs the
## stub service (`--caps IO,FS`), and the wired live path (AC14 re-run) keeps
## live_allowed false, so the service refuses at hello.
##   (default)          opt-in, keys, 0600, kinds, ceiling, text-only, panel,
##                      indicator + budget, wired path
##   --launch-default   only the ai-live-guard runtime half: the builder with
##                      AI_LIVE unset and default settings emits the stub,
##                      --caps IO,FS, and never live
## Run:  godot --headless --path . --script tests/test_ai_settings.gd

const Session := preload("res://tools/record_ai_session.gd")
const KEY_G := "st-fixture-gemini-3e81aa"
const KEY_O := "st-fixture-openrouter-77c0d2"

var failures := 0
var scratch := ProjectSettings.globalize_path("res://.godot/tmp/ai_settings")
var nodes: Array = []


func assert_bool(name: String, ok: bool) -> void:
	if not ok: failures += 1
	print("  %s  %s" % ["ok  " if ok else "FAIL", name])


func fresh(name: String) -> String:
	var d := scratch.path_join(name)
	OS.execute("/bin/rm", PackedStringArray(["-rf", d]))
	DirAccess.make_dir_recursive_absolute(d)
	return d


func settings_in(dir: String, args: Dictionary = {}) -> AiSettings:
	var s := AiSettings.new()
	s.dir = dir
	s.apply_args(args)
	s.load_settings()
	return s


func mode_of(path: String) -> int:
	return FileAccess.get_unix_permissions(path) & 511


func has_key(text: String) -> bool:
	return text.contains(KEY_G) or text.contains(KEY_O)


func session_in(dir: String, args: Dictionary = {}) -> AiSession:
	var a := AiSession.new(args, dir)
	nodes.append(a)
	root.add_child(a)
	return a


# ---------------------------------------------------------------- guard half

func test_launch_default() -> bool:
	print("AC15 runtime half: default settings, AI_LIVE unset -> stub, --caps IO,FS, never live")
	var a := session_in(fresh("default"))
	var b := a.bridge
	var plan := b.launch_plan()
	var args: PackedStringArray = plan.get("args", PackedStringArray())
	var cfg = JSON.parse_string(args[args.find("--args-json") + 1]) if args.has("--args-json") else {}
	assert_bool("off by default: live_on false, bridge.live false, live_allowed false, relay off",
		not a.settings.live_on() and not b.live and not b.live_allowed and a.relay.mode == "off" and b.key_files.is_empty())
	assert_bool("the launch builder emits the stub: --caps IO,FS, entry session, provider stub (%s)" % [plan.get("bin", "")],
		args[args.find("--caps") + 1] == "IO,FS" and args[args.find("--entry") + 1] == "session" and cfg is Dictionary and cfg.get("provider") == "stub"
		and plan.get("bin", "") != "/bin/sh" and not args.has("--ai") and " ".join(args).find("Net") < 0)
	# Keys present but no tick: still off. Tick and keys in an automation run: off.
	OS.set_environment("GOOGLE_API_KEY", KEY_G)
	OS.set_environment("OPENROUTER_API_KEY", KEY_O)
	var s := settings_in(fresh("default_keys"))
	assert_bool("both keys in the env, no tick: off", s.keys_present() == ["gemini", "openrouter"] and not s.live_on())
	s.opt_in = true
	for flag in AiSettings.AUTOMATION_FLAGS:
		var t := settings_in(s.dir, {flag: "x"})
		t.opt_in = true
		assert_bool("tick and keys, but --%s: off" % flag, not t.live_on())
	OS.unset_environment("GOOGLE_API_KEY")
	OS.unset_environment("OPENROUTER_API_KEY")
	return true


# ---------------------------------------------------------------- settings

func test_opt_in() -> bool:
	print("opt-in needs at least one key AND the tick; either or both keys")
	var d := fresh("optin")
	var s := settings_in(d)
	s.opt_in = true
	assert_bool("tick without a key: off", s.keys_present().is_empty() and not s.live_on())
	s.opt_in = false
	assert_bool("save_key openrouter", s.save_key("openrouter", "  " + KEY_O + "\n"))
	assert_bool("an OpenRouter key without the tick: off", s.keys_present() == ["openrouter"] and not s.live_on())
	s.opt_in = true
	assert_bool("OpenRouter key and the tick: on", s.live_on())
	assert_bool("save_key gemini: both keys", s.save_key("gemini", KEY_G) and s.keys_present() == ["gemini", "openrouter"])
	assert_bool("an empty paste removes the key", s.save_key("openrouter", "") and s.keys_present() == ["gemini"] and s.live_on())
	return true


func test_keys() -> bool:
	print("keys: env var first, else a 0600 file; files reach the bridge as paths")
	var d := fresh("keys")
	var s := settings_in(d)
	s.save_key("gemini", KEY_G)
	var path := ProjectSettings.globalize_path(s.key_path("gemini"))
	assert_bool("saved key file mode 0600 (got %o)" % mode_of(path), mode_of(path) == 384)
	assert_bool("saved key file holds the trimmed key", FileAccess.get_file_as_string(path) == KEY_G and s.key_source("gemini") == "file")
	OS.set_environment("GOOGLE_API_KEY", "st-env-gemini-91")
	OS.set_environment("OPENROUTER_API_KEY", "st-env-openrouter-12")
	assert_bool("the env var wins over the file", s.key_source("gemini") == "env" and s.key_source("openrouter") == "env")
	var files := s.key_files()
	var sg: String = files.get("gemini", "")
	assert_bool("an env key reaches the service as a 0600 session file (%o), not the saved file", sg != path and mode_of(sg) == 384
		and FileAccess.get_file_as_string(sg) == "st-env-gemini-91" and FileAccess.get_file_as_string(files.get("openrouter", "")) == "st-env-openrouter-12")
	s.forget_session_keys()
	assert_bool("session key files removed at the end of the session", not FileAccess.file_exists(sg) and not FileAccess.file_exists(files["openrouter"]) and FileAccess.file_exists(path))
	OS.unset_environment("GOOGLE_API_KEY")
	OS.unset_environment("OPENROUTER_API_KEY")
	assert_bool("env cleared: back to the file; OpenRouter none", s.key_source("gemini") == "file" and s.key_source("openrouter") == "")
	s.opt_in = true
	s.save_settings()
	var cfg := FileAccess.get_file_as_string(s.cfg_path())
	assert_bool("ai_settings.cfg holds the tick, ceiling and text-only, never a key", cfg.contains("opt_in=true") and cfg.contains("ceiling_usd") and not has_key(cfg) and not cfg.contains("st-env"))
	assert_bool("the warning is plain: who is billed, unencrypted, 0600", AiSettings.WARNING.contains("YOUR key") and AiSettings.WARNING.contains("unencrypted") and AiSettings.WARNING.contains("0600"))
	return true


func test_kinds() -> bool:
	print("kinds each key enables (routing table); OpenRouter only: voice and portraits stay on the core set")
	var s := settings_in(fresh("kinds"))
	var g := s.kinds_for("gemini")
	g.sort()
	assert_bool("OpenRouter -> text", s.kinds_for("openrouter") == ["text"])
	assert_bool("Gemini -> text, portraits (and avatar), voice: %s" % [g], g == ["avatar", "portrait", "text", "voice"])
	s.save_key("openrouter", KEY_O)
	assert_bool("only an OpenRouter key: live kinds [text] (%s)" % [s.live_kinds()], s.live_kinds() == ["text"])
	s.save_key("gemini", KEY_G)
	assert_bool("both keys: every kind live", s.live_kinds().size() == 4)
	var e := s.estimates()
	assert_bool("price estimates per kind from prices.json: text %.6f, voice %.6f, portrait %.3f" % [e["text"], e["voice"], e["portrait"]],
		e["text"] > 0.0 and e["voice"] > 0.0 and is_equal_approx(e["portrait"], 0.039))
	return true


func test_ceiling() -> bool:
	print("ceiling: player-set, default 0.50, 0.05..20 (Q2), one over both providers, persisted")
	var d := fresh("ceiling")
	var s := settings_in(d)
	assert_bool("default 0.50", is_equal_approx(s.ceiling_usd, 0.5))
	s.set_ceiling(0.01)
	var lo := s.ceiling_usd
	s.set_ceiling(500.0)
	var hi := s.ceiling_usd
	s.set_ceiling(NAN)
	assert_bool("clamped to 0.05 and 20; NaN -> default (%.2f, %.2f)" % [lo, hi], is_equal_approx(lo, 0.05) and is_equal_approx(hi, 20.0) and is_equal_approx(s.ceiling_usd, 0.5))
	s.set_ceiling(2.5)
	s.text_only = true
	s.save_settings()
	var t := settings_in(d)
	assert_bool("persisted in ai_settings.cfg: 2.50, text-only", is_equal_approx(t.ceiling_usd, 2.5) and t.text_only)
	var cf := ConfigFile.new()
	cf.set_value("ai", "ceiling_usd", 99.0)
	cf.set_value("ai", "opt_in", "yes")
	cf.save(t.cfg_path())
	var u := settings_in(d)
	assert_bool("a hand-edited file is clamped and a non-bool tick is off", is_equal_approx(u.ceiling_usd, 20.0) and not u.opt_in)
	var b := AiBridge.new()
	var r := AiRelay.new(b)
	u.apply(b, r)
	assert_bool("one ceiling reaches the bridge (both providers)", is_equal_approx(b.ceiling_usd, 20.0))
	b.free()
	return true


func test_text_only() -> bool:
	print("text-only: the toggle and --text-only; no voice or portrait routes")
	var d := fresh("textonly")
	var s := settings_in(d, {"text-only": ""})
	s.save_key("gemini", KEY_G)
	s.opt_in = true
	var b := AiBridge.new()
	var r := AiRelay.new(b)
	s.apply(b, r)
	assert_bool("--text-only: bridge and relay text-only; voice and portrait unrouted, text routed",
		b.text_only and r.text_only and r.route_for("voice") == "" and r.route_for("portrait") == "" and r.route_for("text") == "gemini")
	assert_bool("text-only still live for text; the saved toggle stays off", s.live_on() and not s.text_only and s.live_kinds() == ["text"])
	assert_bool("relay refuses to open voice in text-only", not r.open("voice", "line", "medic"))
	b.free()
	return true


func test_panel() -> bool:
	print("settings panel and indicator build; the indicator opens the panel")
	var d := fresh("panel")
	settings_in(d).save_key("openrouter", KEY_O)
	var a := session_in(d)
	var ind := a.indicator
	assert_bool("indicator on its own CanvasLayer: '%s'" % ind.button.text, ind is CanvasLayer and ind.button.text.begins_with("AI: off"))
	ind.toggle_panel()
	var p = ind.panel
	assert_bool("clicking it opens Settings", p != null and p.visible and p.is_inside_tree())
	assert_bool("panel: key rows, OpenRouter enables text, estimates", p.key_rows["openrouter"]["status"].text.contains("key saved")
		and p.key_rows["openrouter"]["edit"].placeholder_text.contains("text") and p.info.text.contains("text line"))
	p._on_opt_in(true)
	a.bridge.live_allowed = false # automation never lets AI_LIVE through
	assert_bool("ticking it turns live on (OpenRouter text) and saves; no key in the indicator: '%s'" % ind.button.text,
		a.settings.live_on() and a.bridge.live and a.relay.mode == "live" and ind.button.text.begins_with("AI live") and settings_in(d).opt_in and not has_key(ind.button.text))
	p._on_ceiling(1.0)
	a.bridge.live_allowed = false
	assert_bool("the ceiling field reaches the bridge", is_equal_approx(a.bridge.ceiling_usd, 1.0))
	return true


func test_indicator_budget() -> bool:
	print("indicator: running cost per provider and total (stub prices as routed); budget -> ai_cancel{budget}")
	var d := fresh("budget")
	var lib := d.path_join("library")
	var a := session_in(d)
	var b := a.bridge
	b.cache_dir = lib
	b.ceiling_usd = 0.05
	a.relay.mode = "stub"
	a.relay.keys = ["gemini", "openrouter"]
	a.cache.core_dir = lib.path_join("no_core")
	a.cache.library_dir = lib
	a.cache.load_layers()
	a.indicator._usage_from = 0
	var sim := SimBridge.new()
	sim.record_path = d.path_join("session.ndjson")
	assert_bool("sim starts with ai_core %s..." % AiSession.ai_core().left(12), sim.start() and sim.new_game(Session.SEED, "sol", false, {}, AiSession.ai_core()) and a.attach(sim))
	a.relay.open("text", "line", "medic", {"emotions": ["neutral"]})
	a.relay.open("portrait", "line", "medic", {"emotion": "grieving", "age_stage": 0})
	a.relay.open("portrait", "line", "medic", {"emotion": "loving", "age_stage": 0})
	sim.send([], 0.0)
	Session.idle(b, 30000)
	sim.send([], 0.0)
	sim.stop()
	var ind := a.indicator
	var cancels: Array = a.relay.seen.filter(func(e): return e["k"] == "ai_fallback" and e.get("reason") == "budget")
	assert_bool("the second portrait passes the 0.05 ceiling: ai_cancel{budget} -> ai_fallback budget (%d)" % cancels.size(), cancels.size() == 1 and ind.budget_hit)
	assert_bool("per provider: OpenRouter %.6f > 0 (text), Gemini 0.039 (one portrait); total %.6f" % [ind.usd["openrouter"], ind.total()],
		ind.usd["openrouter"] > 0.0 and is_equal_approx(ind.usd["gemini"], 0.039) and is_equal_approx(ind.total(), ind.usd["openrouter"] + 0.039))
	a.settings.opt_in = true
	a.settings.save_key("gemini", KEY_G)
	assert_bool("indicator text names both providers, the total, the ceiling and the stop: '%s'" % ind.text(),
		ind.text().contains("Google $0.0390") and ind.text().contains("OpenRouter $0.0000") and ind.text().contains("of $") and ind.text().contains("ceiling reached"))
	var log_text := FileAccess.get_file_as_string(sim.record_path)
	assert_bool("ai_core reaches new_game in the session log", log_text.contains('"ai_core":"%s"' % AiSession.ai_core()))
	return true


## AC14 re-run through the wired game path: both keys saved through the
## settings, the tick, AiSession builds the live launch; live_allowed is forced
## false (automation), so the service refuses at hello: service_down, the
## request falls back, and no key text reaches stdout, stderr, the log or the library.
func test_wired() -> bool:
	print("AC14 re-run, wired path: settings -> AiSession -> live launch with key files, refused at hello")
	var d := fresh("wired")
	var s := settings_in(d)
	s.save_key("gemini", KEY_G)
	s.save_key("openrouter", KEY_O)
	s.opt_in = true
	s.save_settings()
	var a := session_in(d)
	var b := a.bridge
	b.live_allowed = false # automation never lets AI_LIVE through
	b.cache_dir = d.path_join("library")
	b.keep_lines = true
	b.backoff_ms = [50, 50, 50]
	var plan := b.launch_plan()
	var argv := " ".join(plan.get("args", PackedStringArray()))
	assert_bool("wired: live plan with both key files as paths, --ai-key-file, --ai-no-adc, permission 0",
		b.live and plan.get("bin") == "/bin/sh" and argv.contains(ProjectSettings.globalize_path(s.key_path("gemini"))) and argv.contains("--ai-key-file")
		and argv.contains("--ai-no-adc") and plan["args"][5] == "0" and not has_key(argv))
	var sim := SimBridge.new()
	sim.record_path = d.path_join("session.ndjson")
	sim.start()
	sim.new_game(Session.SEED, "sol", false, {}, AiSession.ai_core())
	a.attach(sim)
	a.relay.open("text", "line", "medic")
	sim.send([], 0.0)
	Session.idle(b, 20000)
	sim.send([], 0.0)
	sim.stop()
	var fb: Array = a.relay.seen.filter(func(e): return e["k"] == "ai_fallback")
	var said := "\n".join(b.lines_read)
	assert_bool("refused three times (AI_LIVE not passed) -> service_down -> fallback (%d launches)" % b.launch_count,
		b.service_down and b.launch_count == 3 and fb.size() == 1 and fb[0].get("reason") == "service_down" and said.contains("AI_LIVE=1 is not set"))
	var leaked := has_key(said) or has_key(b.stderr_tail) or has_key(FileAccess.get_file_as_string(sim.record_path))
	assert_bool("no key text in the service's stdout, stderr or the session log", not leaked)
	return true


## Runs from the first frame, not _initialize: only then is the root in the
## tree, so the indicator and panel get _ready like in the game.
var _ran := false
func _process(_delta: float) -> bool:
	if _ran:
		return false
	_ran = true
	run_all()
	return false


func run_all() -> void:
	DirAccess.make_dir_recursive_absolute(scratch)
	for v in ["GOOGLE_API_KEY", "OPENROUTER_API_KEY", "AI_LIVE"]:
		OS.unset_environment(v)
	if SimBridge.find_ailang() == "":
		print("FAIL  ailang not found (AILANG_BIN or PATH)")
		quit(2)
		return
	var tests := ["launch_default"]
	if not "--launch-default" in OS.get_cmdline_user_args():
		tests.append_array(["opt_in", "keys", "kinds", "ceiling", "text_only", "panel", "indicator_budget", "wired"])
	for t in tests:
		if call("test_" + t) != true:
			assert_bool("test_%s ran to its end" % t, false)
	for n in nodes:
		n.bridge.shutdown()
		n.queue_free()
	print("ai settings: %s (%s)" % ["FAIL" if failures > 0 else "ok", ", ".join(tests)])
	quit(1 if failures > 0 else 0)
