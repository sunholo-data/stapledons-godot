extends SceneTree
## Live AI settings, indicator and game wiring (sprint R1-AI-FOUNDATION AI.9,
## design ai-service-foundation (a5)). Settings and keys live in a scratch
## directory, never the player's user://; the key env vars are cleared first;
## every key is a fixture. Nothing here spends: the indicator check runs the
## stub service (`--caps IO,FS`), and the wired live path (AC14 re-run) keeps
## live_allowed false, so the service refuses at hello.
##   (default)          opt-in, keys, key edges, 0600, kinds, ceiling, text-only,
##                      panel, indicator + budget, wired path
##   --only=a,b         just those tests (the mutation check)
##   --launch-default   only the ai-live-guard runtime half: the builder with
##                      AI_LIVE unset and default settings emits the stub,
##                      --caps IO,FS, and never live
## Run:  godot --headless --path . --script tests/test_ai_settings.gd

const Session := preload("res://tools/record_ai_session.gd")
const KEY_G := "st-fixture-gemini-3e81aa"
const KEY_O := "st-fixture-openrouter-77c0d2"

var failures := 0
var passes := 0
var scratch := ProjectSettings.globalize_path("res://.godot/tmp/ai_settings")
var nodes: Array = []


func assert_bool(name: String, ok: bool) -> void:
	if ok: passes += 1
	else: failures += 1
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


## AI.9 hardening: an empty or blank key file is no key; a session key file a
## crash left behind is removed when the next session starts; an automation
## run gets no indicator.
func test_key_edges() -> bool:
	print("key edges: empty key file, stale session key files, automation without indicator")
	var d := fresh("key_edges")
	var s := settings_in(d)
	for text in ["", "  \n"]:
		FileAccess.open(ProjectSettings.globalize_path(s.key_path("gemini")), FileAccess.WRITE).store_string(text)
		assert_bool("a key file holding %s is no key" % ("nothing" if text == "" else "blanks"), s.key_source("gemini") == "" and s.keys_present().is_empty())
	var stale := []
	for p in AiSettings.PROVIDERS:
		var f := ProjectSettings.globalize_path(s.session_key_path(p))
		AiSettings._write_private(f, "st-stale-" + p)
		stale.append(f)
	var a := session_in(d)
	assert_bool("stale session key files removed at startup", stale.all(func(f): return not FileAccess.file_exists(f)))
	var c := session_in(fresh("key_edges_capture"), {"map-capture": "x"})
	assert_bool("automation run (--map-capture): no indicator, live off", c.indicator == null and not c.settings.live_on() and a.indicator != null)
	return true


func test_kinds() -> bool:
	print("kinds each key enables (routing table); OpenRouter only: voice and portraits stay on the core set")
	var s := settings_in(fresh("kinds"))
	var g := s.kinds_for("gemini")
	g.sort()
	assert_bool("OpenRouter -> text", s.kinds_for("openrouter") == ["text"])
	assert_bool("Gemini -> text, portraits (and avatar), voice, pictures from home: %s" % [g], g == ["avatar", "feed", "portrait", "text", "voice"])
	s.save_key("openrouter", KEY_O)
	assert_bool("only an OpenRouter key: live kinds [text] (%s)" % [s.live_kinds()], s.live_kinds() == ["text"])
	s.save_key("gemini", KEY_G)
	assert_bool("both keys: every kind live", s.live_kinds().size() == 5)
	var e := s.estimates()
	assert_bool("price estimates per kind from prices.json: text %.6f, voice %.6f, portrait %.3f" % [e["text"], e["voice"], e["portrait"]],
		e["text"] > 0.0 and e["voice"] > 0.0 and is_equal_approx(e["portrait"], 0.039) and is_equal_approx(e["feed"], 0.039))
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
	assert_bool("indicator on its own CanvasLayer, off: '%s'" % ind.button.tooltip_text, ind is CanvasLayer and ind.state() == "off" and ind.button.tooltip_text.begins_with("AI: off"))
	ind.toggle_panel()
	var p = ind.panel
	assert_bool("clicking it opens Settings", p != null and p.visible and p.is_inside_tree())
	assert_bool("panel: OpenRouter card says Saved, Gemini card No key; four price chips, the first a line ('%s', '%s', '%s')"
		% [p.key_rows["openrouter"]["status"].text, p.key_rows["gemini"]["status"].text, p.chips[0].text],
		p.key_rows["openrouter"]["status"].text == "Saved" and p.key_rows["gemini"]["status"].text == "No key"
		and p.chips.size() == 4 and p.chips[0].text.begins_with("line"))
	assert_bool("the switch is enabled with a key, and the header says off", not p.opt_in.disabled and not p.opt_in.button_pressed and p.headline.text.begins_with("Off"))
	p._on_opt_in(true)
	a.bridge.live_allowed = false # automation never lets AI_LIVE through
	assert_bool("ticking it turns live on (OpenRouter text) and saves; no key in the indicator: '%s'" % ind.button.tooltip_text,
		a.settings.live_on() and a.bridge.live and a.relay.mode == "live" and ind.state() == "live" and ind.button.tooltip_text.begins_with("AI live")
		and settings_in(d).opt_in and not has_key(ind.button.tooltip_text) and not has_key(ind.label_text()))
	p._on_ceiling(1.0)
	a.bridge.live_allowed = false
	assert_bool("the ceiling reaches the bridge and the slider ('%s')" % p.ceiling_value.text,
		is_equal_approx(a.bridge.ceiling_usd, 1.0) and is_equal_approx(p.ceiling.value, AiSettings.ceiling_to_slider(1.0)) and p.ceiling_value.text == "$1.00")
	p._on_slider(AiSettings.ceiling_to_slider(2.5))
	a.bridge.live_allowed = false
	assert_bool("moving the slider sets the ceiling on the 0.01 grid (%.2f)" % a.settings.ceiling_usd, is_equal_approx(a.settings.ceiling_usd, 2.5) and settings_in(d).ceiling_usd == 2.5)
	return true


## R3-AI-PANEL-V2 P3 (AC3-AC6): the helpers, the cards, the tiles, the slider, the dots.
func test_panel_v2() -> bool:
	print("P3 panel: masked keys, the log ceiling slider, capability tiles, cards with Test/Add/Remove, reply dots")
	var d := fresh("panel_v2")
	var s := settings_in(d)
	assert_bool("masked key: empty without a key", s.masked_key("gemini") == "")
	s.save_key("gemini", KEY_G)
	assert_bool("masked key: the last 4 only ('%s')" % s.masked_key("gemini"), s.masked_key("gemini") == "•••• " + KEY_G.right(4) and not has_key(s.masked_key("gemini")))
	# AC5: every 0.01 step in 0.05..20 round-trips; the map is monotonic and hits both ends.
	var bad := 0
	var v0 := -1.0
	for i in range(0, 1996):
		s.set_ceiling(0.05 + i * 0.01)
		var v := s.ceiling_usd
		if AiSettings.slider_to_ceiling(AiSettings.ceiling_to_slider(v)) != v or v <= v0:
			bad += 1
		v0 = v
	var mono := true
	var prev := 0.0
	for k in range(0, 1001):
		var c := AiSettings.slider_to_ceiling(k / 1000.0)
		mono = mono and c >= prev
		prev = c
	assert_bool("ceiling slider: 1,996 steps round-trip exactly (%d bad), monotonic, ends 0.05 and 20" % bad,
		bad == 0 and mono and AiSettings.slider_to_ceiling(0.0) == 0.05 and AiSettings.slider_to_ceiling(1.0) == 20.0
		and AiSettings.ceiling_to_slider(0.05) == 0.0 and AiSettings.ceiling_to_slider(20.0) == 1.0)
	# AC4: tiles per key [text, voice, portrait, feed].
	s.opt_in = true
	assert_bool("Gemini key, live: 4 bright (%s)" % [s.tile_states("gemini")], s.tile_states("gemini") == ["bright", "bright", "bright", "bright"])
	s.text_only = true
	assert_bool("text-only: text bright, 3 dim (%s)" % [s.tile_states("gemini")], s.tile_states("gemini") == ["bright", "dim", "dim", "dim"])
	s.text_only = false
	s.opt_in = false
	assert_bool("switch off: all dim (%s)" % [s.tile_states("gemini")], s.tile_states("gemini") == ["dim", "dim", "dim", "dim"])
	s.save_key("gemini", "")
	s.save_key("openrouter", KEY_O)
	s.opt_in = true
	assert_bool("OpenRouter only: text bright, 3 faint (%s)" % [s.tile_states("openrouter")], s.tile_states("openrouter") == ["bright", "faint", "faint", "faint"])
	assert_bool("no Gemini key: its tiles dim where it could serve (%s)" % [s.tile_states("gemini")], s.tile_states("gemini") == ["dim", "dim", "dim", "dim"])
	s.save_key("openrouter", "")
	s.opt_in = false
	s.save_settings()
	# AC3: the cards, through a session panel.
	var a := session_in(d)
	a.bridge.live_allowed = false
	a.indicator.toggle_panel()
	var p = a.indicator.panel
	var g: Dictionary = p.key_rows["gemini"]
	assert_bool("no key: lamp none, word No key, Add key shown, Test and Remove hidden, the switch disabled",
		p.card_status("gemini") == "none" and g.status.text == "No key" and g.add.visible and not g.test.visible and not g.remove.visible and p.opt_in.disabled)
	g.add.pressed.emit()
	assert_bool("Add key reveals the secret field", g.edit_row.visible and (g.edit as LineEdit).secret)
	(g.edit as LineEdit).text = KEY_G
	g.save.pressed.emit()
	var kp := ProjectSettings.globalize_path(a.settings.key_path("gemini"))
	assert_bool("Save: 0600 file, field cleared and hidden, card Saved, masked '%s', Test and Replace shown" % g.masked.text,
		mode_of(kp) == 384 and (g.edit as LineEdit).text == "" and not g.edit_row.visible and g.status.text == "Saved"
		and g.masked.text.ends_with(KEY_G.right(4)) and not has_key(g.masked.text) and g.test.visible and g.add.text == "Replace")
	a.key_check.plan_override = {"bin": "/bin/echo", "args": PackedStringArray(['{"check":"gemini","status":"rejected"}'])}
	g.test.pressed.emit()
	assert_bool("Test: the card reads Checking at once", g.status.text.begins_with("Checking"))
	wait_checks(a.key_check, 5000)
	p.refresh()
	assert_bool("Test result: Key rejected on the card, and the badge says key problem once live", g.status.text == "Key rejected" and p.card_status("gemini") == "rejected")
	g.remove.pressed.emit()
	assert_bool("Remove deletes the key file; the card is back to No key", not FileAccess.file_exists(kp) and g.status.text == "No key" and a.settings.keys_present().is_empty())
	# AC6: dots from this session's replies, newest last, at most 8.
	var ind := a.indicator
	for i in 10:
		ind.on_outcome({"req": str(i), "kind": "text", "status": "error" if i == 9 else "ok"})
	p.refresh()
	assert_bool("reply dots: the 8 newest of 10, the last one the failure (%s)" % [ind.recent.map(func(r): return r.ok)],
		ind.recent.size() == 8 and ind.recent[0].req == "2" and not ind.recent[-1].ok and p.dots.get_child_count() == 8)
	var t := session_in(fresh("panel_v2_text_only"), {"text-only": ""})
	t.indicator.toggle_panel()
	assert_bool("--text-only locks the Voices & pictures button off", t.indicator.panel.text_only.disabled and not t.indicator.panel.text_only.button_pressed)
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
	# A line from an earlier session is already in usage.ndjson: it must not
	# count toward this session's indicator or ceiling (the session starts at
	# the first launch).
	DirAccess.make_dir_recursive_absolute(lib)
	FileAccess.open(lib.path_join("usage.ndjson"), FileAccess.WRITE).store_string('{"req":"4","provider":"gemini","route":"gemini","model":"m","kind":"portrait","usd":5.0}\n')
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
	assert_bool("per provider: OpenRouter %.6f > 0 (text), Gemini 0.039 (one portrait, the earlier session's 5.0 not counted); total %.6f" % [ind.usd["openrouter"], ind.total()],
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


## R3-AI-PANEL-V2 P2 (AC1, AC2): the badge's state, its words and its ring.
func test_badge() -> bool:
	print("P2 badge: five states in precedence, at most two words beside AI, amounts in the tooltip")
	# state_of(live_on, budget_hit, fail_streak, rejected, pending)
	var cases := [
		[[false, true, 3, true, 1], "off", "off wins over everything"],
		[[false, false, 0, false, 1], "off", "off while a request is pending"],
		[[true, true, 0, false, 0], "ceiling", "budget hit"],
		[[true, true, 3, true, 1], "ceiling", "ceiling over problem and working"],
		[[true, false, 3, false, 0], "problem", "three failures in a row"],
		[[true, false, 0, true, 0], "problem", "a rejected key"],
		[[true, false, 3, false, 2], "problem", "problem over working"],
		[[true, false, 0, false, 1], "working", "a request in flight"],
		[[true, false, 2, false, 0], "live", "two failures are not a problem yet"],
		[[true, false, 0, false, 0], "live", "live and idle"],
	]
	for c in cases:
		var v: Array = c[0]
		var got := AiIndicator.state_of(v[0], v[1], v[2], v[3], v[4])
		assert_bool("state_of %s -> %s (%s): %s" % [c[0], c[1], c[2], got], got == c[1])
	assert_bool("words: problem says key problem for a rejected key and offline otherwise; every word is at most 2 words",
		AiIndicator.word_of("problem", true) == "key problem" and AiIndicator.word_of("problem", false) == "offline"
		and ["off", "live", "working", "ceiling"].all(func(st): return AiIndicator.word_of(st, false).split(" ").size() <= 2))
	var d := fresh("badge")
	var s := settings_in(d)
	s.save_key("openrouter", KEY_O)
	s.opt_in = true
	s.save_settings()
	var a := session_in(d)
	a.bridge.live_allowed = false
	var ind := a.indicator
	ind.refresh()
	var words := ind.label_text().split(" ", false)
	assert_bool("visible label: AI and at most 2 words ('%s'); the amounts and the ceiling in the tooltip ('%s')" % [ind.label_text(), ind.button.tooltip_text],
		words[0] == "AI" and words.size() <= 3 and not ind.label_text().contains("$") and ind.button.tooltip_text.contains("of $0.50"))
	for i in 3:
		ind.on_outcome({"req": str(i), "status": "error", "code": "provider_error"})
	assert_bool("three failed replies -> problem, word offline ('%s')" % ind.label_text(), ind.state() == "problem" and ind.label_text() == "AI offline")
	ind.on_outcome({"req": "4", "status": "ok"})
	assert_bool("one ok reply clears it -> live", ind.state() == "live" and ind.label_text() == "AI live")
	a.key_check.results["openrouter"] = "rejected"
	ind.refresh()
	assert_bool("a rejected key check -> problem, word key problem ('%s')" % ind.label_text(), ind.state() == "problem" and ind.label_text() == "AI key problem")
	a.key_check.results["openrouter"] = "ok"
	ind.usd = {"gemini": 0.0, "openrouter": 0.125}
	var quarter := ind.fraction()
	ind.usd["openrouter"] = 9.0
	assert_bool("the ring is spent over the ceiling: 0.125 of 0.50 -> 0.25 (%.3f); clamped at 1 (%.3f)" % [quarter, ind.fraction()],
		is_equal_approx(quarter, 0.25) and is_equal_approx(ind.fraction(), 1.0))
	return true


## R3-AI-PANEL-V2 P1 (AC9 and the Godot half of AC7): the key check's plan,
## its guards, the parse, the async run and the timeout. The provider GETs
## themselves are `make ai-key-check`; here a real run goes to a closed port.
func wait_checks(kc: AiKeyCheck, ms: int) -> bool:
	var end := Time.get_ticks_msec() + ms
	while Time.get_ticks_msec() < end:
		kc.poll()
		if kc.running.is_empty():
			return true
		OS.delay_msec(10)
	return false


func test_key_check() -> bool:
	print("P1 key check: plan, guards, parse, async run, timeout, a real run to a closed port")
	var d := fresh("key_check")
	var s := settings_in(d)
	var kc := AiKeyCheck.new()
	assert_bool("no key file: no plan, start refused", AiKeyCheck.plan("gemini", "", "ailang", "/r", "/h").is_empty() and not kc.start("gemini", s))
	s.save_key("gemini", KEY_G)
	var kf := ProjectSettings.globalize_path(s.key_path("gemini"))
	var plan := AiKeyCheck.plan("gemini", kf, "/x/ailang", "/r", "/h")
	var args: PackedStringArray = plan.get("args", PackedStringArray())
	var cfg = JSON.parse_string(args[args.find("--args-json") + 1]) if args.has("--args-json") else {}
	assert_bool("plan: env -i, no ADC, ailang check entry, IO,FS,Net only, the provider hosts only, the key as a file path",
		plan.get("bin") == "/usr/bin/env" and args[0] == "-i" and args.has("GOOGLE_APPLICATION_CREDENTIALS=/nonexistent") and args.has("HOME=/h")
		and args.has("/x/ailang") and args[args.find("--entry") + 1] == "check" and args[args.find("--caps") + 1] == "IO,FS,Net"
		and args[args.find("--net-allow-domains") + 1] == AiBridge.LIVE_HOSTS and not args.has("--net-allow-localhost") and args[-1] == "/r/ai/check.ail"
		and cfg is Dictionary and cfg.get("provider") == "gemini" and cfg.get("key_file") == kf and cfg.get("base") == "" and not has_key(" ".join(args)))
	var local := AiKeyCheck.plan("gemini", kf, "/x/ailang", "/r", "/h", "http://127.0.0.1:1")
	assert_bool("a test base allows only localhost over http, never the provider hosts",
		local["args"].has("--net-allow-localhost") and local["args"].has("--net-allow-http") and not local["args"].has("--net-allow-domains"))
	assert_bool("an unknown provider gets no plan", AiKeyCheck.plan("other", kf, "/x/ailang", "/r", "/h").is_empty())
	var auto := settings_in(d, {"capture": true})
	assert_bool("automation never runs a check", not kc.start("gemini", auto) and kc.running.is_empty())
	assert_bool("parse: the one line, its provider, a known status; anything else is offline",
		AiKeyCheck.parse("gemini", '{"check":"gemini","status":"ok"}\n') == "ok"
		and AiKeyCheck.parse("openrouter", 'noise\n{"check":"openrouter","status":"rejected"}\n') == "rejected"
		and AiKeyCheck.parse("gemini", '{"check":"openrouter","status":"ok"}') == "offline"
		and AiKeyCheck.parse("gemini", '{"check":"gemini","status":"great"}') == "offline"
		and AiKeyCheck.parse("gemini", "") == "offline" and AiKeyCheck.parse("gemini", '{"check":"gemini","status":"no_key"}') == "no_key")
	var got := []
	kc.done.connect(func(p, st): got.append([p, st]))
	kc.plan_override = {"bin": "/bin/echo", "args": PackedStringArray(['{"check":"gemini","status":"ok"}'])}
	var started := kc.start("gemini", s)
	assert_bool("a second start while one runs is refused", started and not kc.start("gemini", s) and kc.status("gemini", s) == "checking")
	var ran := wait_checks(kc, 5000)
	assert_bool("async run: done(gemini, ok), the result kept for this run (%s)" % [got], ran and got == [["gemini", "ok"]] and kc.status("gemini", s) == "ok")
	kc.plan_override = {"bin": "/bin/sleep", "args": PackedStringArray(["5"])}
	kc.timeout_ms = 300
	var t0 := Time.get_ticks_msec()
	kc.start("gemini", s)
	ran = wait_checks(kc, 3000)
	var took := Time.get_ticks_msec() - t0
	assert_bool("a hung check is killed at the timeout and reads offline (%d ms)" % took, ran and kc.status("gemini", s) == "offline" and took < 2500)
	kc.plan_override = {}
	kc.timeout_ms = AiKeyCheck.TIMEOUT_MS
	kc.base = "http://127.0.0.1:1"
	kc.start("gemini", s)
	ran = wait_checks(kc, 20000)
	assert_bool("a real check through ailang to a closed port prints its offline line: %s" % kc.last_out.get("gemini", "").strip_edges(),
		ran and kc.status("gemini", s) == "offline" and kc.last_out.get("gemini", "") == '{"check":"gemini","status":"offline"}\n')
	assert_bool("status without a check: 'saved' with a key, 'none' without", kc.status("openrouter", s) == "none"
		and AiKeyCheck.new().status("gemini", s) == "saved")
	s.save_key("gemini", "")
	assert_bool("removing the key forgets its result", kc.status("gemini", s) == "none")
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
		tests.append_array(["opt_in", "keys", "key_edges", "kinds", "ceiling", "text_only", "panel", "indicator_budget", "wired", "key_check", "badge", "panel_v2"])
	# --only=name,name runs a subset (tests/ai_settings_mutants.sh uses it).
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			tests = Array(a.substr(7).split(","))
	for t in tests:
		if call("test_" + t) != true:
			assert_bool("test_%s ran to its end" % t, false)
	for n in nodes:
		n.bridge.shutdown()
		n.queue_free()
	print("ai settings: %s (%d passed, %d failures; %s)" % ["FAIL" if failures > 0 else "ok", passes, failures, ", ".join(tests)])
	quit(1 if failures > 0 else 0)
