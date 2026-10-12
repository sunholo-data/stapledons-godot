extends SceneTree
## AiRelay and AiCache end to end (sprint R1-AI-FOUNDATION AI.7, design
## ai-service-foundation (a3), (a4)): the sim, the relay and the stub service
## (`--caps IO,FS`: no network, no key). Always: AC10 (text, voice and
## portrait through the stub; a cache hit records with no launch; the tee
## writes the session log, equal to tests/replays/ai_stub_session.ndjson),
## the relay's cancels, the cache's layers and the portrait fallback mirror.
##   --news         AC18: a news request returns through the stub; the digits
##                  fixture is refused ai_numeral and the template stands
##   --key-hygiene  AC14: two fixture key files; neither key text in argv,
##                  service stdout/stderr, the session log or the library; a
##                  route whose key env var is empty refuses
##   --routes       the relay's route per kind equals the service's for each
##                  key set; the session log is identical whichever answered
##   --replay-noai  AC12 part: the log replays through Godot with the relay in
##                  replay mode against the golden; no AI process starts
##   --faults       AC11: delegates to tests/test_ai_bridge.gd -- --faults
## Run:  godot --headless --path . --script tests/test_ai_relay.gd -- --news --key-hygiene --routes

const Session := preload("res://tools/record_ai_session.gd")
const LOG := "res://tests/replays/ai_stub_session.ndjson"
const KEY_G := "kh-fixture-gemini-5d2c9e"
const KEY_O := "kh-fixture-openrouter-a8f1b7"

var failures := 0
var scratch := ProjectSettings.globalize_path("res://.godot/tmp/ai_relay")
var res := ProjectSettings.globalize_path("res://")
var bridges: Array = []
## The AC10 run (keys: both), reused by --news and --routes.
var e2e: Dictionary = {}


func assert_bool(name: String, ok: bool) -> void:
	if not ok: failures += 1
	print("  %s  %s" % ["ok  " if ok else "FAIL", name])


func fresh(name: String) -> String:
	var d := scratch.path_join(name)
	OS.execute("/bin/rm", PackedStringArray(["-rf", d]))
	DirAccess.make_dir_recursive_absolute(d)
	return d


func events_of(relay: AiRelay, k: String) -> Array:
	return relay.seen.filter(func(e): return e["k"] == k)


func by_req(es: Array) -> Dictionary:
	var d := {}
	for e in es:
		d[e["req"]] = e
	return d


## One recorded session over a fresh library; outcomes and the log kept.
func session(name: String, keys: Array) -> Dictionary:
	var lib := fresh(name)
	var log_path := lib.path_join("session.ndjson")
	var rig := Session.stub_rig(log_path, lib.path_join("library"), keys)
	if rig.is_empty():
		assert_bool("%s: sim and relay start" % name, false)
		return {}
	bridges.append(rig["bridge"])
	var outs := []
	rig["bridge"].outcome.connect(func(o): outs.append(o))
	rig["ticks"] = Session.run_session(rig["sim"], rig["relay"], rig["bridge"])
	rig["sim"].stop()
	rig["outcomes"] = outs
	rig["log"] = FileAccess.get_file_as_bytes(log_path)
	rig["library"] = lib.path_join("library")
	return rig


# ---------------------------------------------------------------- always

func test_cache() -> bool:
	print("AiCache: layers, stages, newest line, text from core only")
	var core := fresh("cache_core")
	var lib := fresh("cache_lib")
	var line := func(kind, emo, stage, variant, sha, extra := {}):
		var e := {"key": {"kind": kind, "entity_id": "medic", "emotion": emo, "age_stage": stage, "variant": variant}, "sha256": sha, "mime": "image/png", "bytes": 3, "ext": "png", "width": 2, "height": 2}
		e.merge(extra, true)
		return JSON.stringify(e)
	FileAccess.open(lib.path_join("index.ndjson"), FileAccess.WRITE).store_string("\n".join([
		line.call("portrait", "sad", 0, "0", "a0"), line.call("portrait", "sad", 50, "0", "a50"), line.call("portrait", "sad", 0, "0", "b0"),
		line.call("portrait", "happy", 0, "0", "lib-happy"), line.call("portrait", "angry", 0, "0", "angry0"), line.call("text", "-", 0, "-", "lib-text", {"mime": "text/plain", "ext": "txt"}),
		line.call("voice", "-", 0, "v1", "lib-voice", {"mime": "audio/ogg", "ext": "ogg"}), "not json", "{\"key\":1}"]) + "\n")
	FileAccess.open(core.path_join("index.ndjson"), FileAccess.WRITE).store_string(line.call("portrait", "happy", 0, "0", "core-happy") + "\n")
	var c := AiCache.new()
	c.core_dir = core
	c.library_dir = lib
	c.load_layers()
	var key := func(kind, emo, stage, variant := "0"): return {"kind": kind, "entity_id": "medic", "emotion": emo, "age_stage": stage, "variant": variant}
	assert_bool("greatest age_stage <= years: 30 -> stage 0, 50 -> 50, 70 -> 50", c.lookup(key.call("portrait", "sad", 30), 30).get("sha256") == "b0"
		and c.lookup(key.call("portrait", "sad", 50), 50).get("sha256") == "a50" and c.lookup(key.call("portrait", "sad", 70), 70).get("sha256") == "a50")
	assert_bool("a library line at stage 0 serves a request at 50 (the only stage <= 50)", c.lookup(key.call("portrait", "angry", 50), 50).get("sha256") == "angry0" and c.lookup(key.call("portrait", "angry", 0), 0).get("sha256") == "angry0")
	assert_bool("within the library the newest line for a key wins (b0 over a0)", c.lookup(key.call("portrait", "sad", 0), 0).get("sha256") == "b0")
	assert_bool("core wins over the library for the same key", c.lookup(key.call("portrait", "happy", 0), 0).get("sha256") == "core-happy")
	assert_bool("text resolves from core only; a library voice line without duration is a miss",
		c.lookup(key.call("text", "-", 0, "-"), 0).is_empty() and c.lookup(key.call("voice", "-", 0, "v1"), 0).is_empty())
	assert_bool("a missing emotion falls back along the chain (grieving -> sad)", c.portrait_for("medic", "grieving", 10).get("sha256") == "b0")
	assert_bool("ints: whole floats become ints, others stay", AiCache.ints({"a": 2.0, "b": [0.5, 3.0], "c": "x"}) == {"a": 2, "b": [0.5, 3], "c": "x"})
	# The fallback table mirrors sim/markers.ail fallbackChain, read from its source.
	var src := FileAccess.get_file_as_string("res://sim/markers.ail")
	var sim_table := {}
	var re := RegEx.create_from_string('if e == "([a-z]+)" then \\[([^\\]]*)\\]')
	for m in re.search_all(src):
		sim_table[m.get_string(1)] = JSON.parse_string("[" + m.get_string(2) + "]")
	var same := sim_table.size() == 4
	for e in sim_table:
		same = same and AiCache.fallback_chain(e) == sim_table[e]
	var rest_ok := src.contains('else if e == "neutral" || !isEmotion(e) then ["neutral"]') and src.contains("else [e, \"neutral\"]")
	for e in ["neutral", "angry", "fearful", "curious", "joyful", ""]:
		rest_ok = rest_ok and AiCache.fallback_chain(e) == (["neutral"] if e in ["neutral", "joyful", ""] else [e, "neutral"])
	assert_bool("portrait fallback chain == sim/markers.ail fallbackChain (%d explicit rows, the rest)" % sim_table.size(), same and rest_ok)
	return true


func test_disabled_old_sim() -> bool:
	print("relay enabled only for a sim at protocol minor >= 1")
	var old := SimBridge.new()
	old.launch_override = {"bin": "python3", "args": PackedStringArray([res.path_join("tests/fixtures/fake_sim.py"), "ok"])}
	var b := AiBridge.new()
	bridges.append(b)
	var r := AiRelay.new(b, AiCache.new())
	var ok := old.start() and old.new_game(1)
	assert_bool("a 2.0 sim: relay off, hook unset, nothing opened", ok and not r.attach(old) and old.ai_relay == null and not r.open("text", "line", "medic"))
	assert_bool("the 2.0 sim still ticks with the relay present", old.send([], 0.01) and b.launch_count == 0)
	old.stop()
	return true


func rig_without_service(name: String, mode: String, keys: Array, text_only := false) -> Dictionary:
	var lib := fresh(name)
	var rig := Session.stub_rig(lib.path_join("log.ndjson"), lib.path_join("library"), keys)
	bridges.append(rig["bridge"])
	rig["relay"].mode = mode
	rig["relay"].text_only = text_only
	rig["bridge"].text_only = text_only
	return rig


func test_cancels() -> bool:
	print("relay cancels: text_only, offline, no_key; no service started")
	var t := rig_without_service("text_only", "stub", ["gemini", "openrouter"], true)
	var r: AiRelay = t["relay"]
	assert_bool("text-only: the relay never opens voice or portrait", not r.open("portrait", "line", "medic", {"emotion": "sad"}) and not r.open("voice", "line", "medic", {"line_req": "1"}) and r.queued() == 0)
	t["sim"].send([{"k": "ai_open", "kind": "portrait", "purpose": "line", "entity_id": "medic", "emotion": "sad"}], 0.0) # the sim may open one itself
	t["sim"].send([], 0.0)
	assert_bool("text-only: a portrait request the sim opened is cancelled text_only", by_req(events_of(r, "ai_fallback")).get("1", {}).get("reason") == "text_only")
	t["sim"].stop()
	var o := rig_without_service("offline", "off", ["gemini", "openrouter"])
	o["relay"].open("text", "line", "medic")
	o["sim"].send([], 0.0)
	o["sim"].send([], 0.0)
	assert_bool("live AI off: ai_cancel offline", by_req(events_of(o["relay"], "ai_fallback")).get("1", {}).get("reason") == "offline")
	o["sim"].stop()
	var n := rig_without_service("no_key", "stub", [])
	n["relay"].open("text", "line", "medic")
	n["relay"].open("portrait", "line", "medic", {"emotion": "sad"})
	n["sim"].send([], 0.0)
	n["sim"].send([], 0.0)
	var fb := by_req(events_of(n["relay"], "ai_fallback"))
	assert_bool("no key for the route: ai_cancel no_key for text and portrait", fb.get("1", {}).get("reason") == "no_key" and fb.get("2", {}).get("reason") == "no_key")
	n["sim"].stop()
	assert_bool("no launch in any of the three", t["bridge"].launch_count + o["bridge"].launch_count + n["bridge"].launch_count == 0)
	return true


func test_e2e() -> bool:
	print("AC10: ai_open -> ai_request -> service -> record -> ai_accepted (text, voice, portrait)")
	e2e = session("e2e", ["gemini", "openrouter"])
	if e2e.is_empty():
		return true
	var relay: AiRelay = e2e["relay"]
	var acc := by_req(events_of(relay, "ai_accepted"))
	var kinds := []
	for q in acc:
		kinds.append(acc[q]["kind"])
	kinds.sort()
	assert_bool("five ticks; accepted text x2, voice, portrait x2: %s" % [kinds], e2e["ticks"] == 5 and kinds == ["portrait", "portrait", "text", "text", "voice"])
	assert_bool("the accepted text is the text the sim parsed", acc.get("1", {}).get("text") == "Stub line one for medic.")
	var v: Dictionary = acc.get("5", {}).get("descriptor", {})
	assert_bool("the voice record's key variant == AiCache.voice_variant(the line)", v.get("key", {}).get("variant") == AiCache.voice_variant("Aoede", acc["1"]["segments"]) and v.get("mime") == "audio/ogg")
	assert_bool("one launch; five requests forwarded, one library hit (the second portrait)", e2e["bridge"].launch_count == 1 and relay.forwarded == 5 and relay.hits == 1 and e2e["bridge"].sent_total == 5)
	var hit: Dictionary = acc.get("6", {})
	assert_bool("the hit records the library blob (same sha256 as the generated portrait)", hit.get("sha256") == acc.get("3", {}).get("sha256") and hit.get("kind") == "portrait")
	var golden := FileAccess.get_file_as_bytes(LOG)
	assert_bool("the tee wrote the session log; it equals %s (%d bytes)" % [LOG.get_file(), golden.size()], golden.size() > 0 and e2e["log"] == golden)
	# A new session over the same library: the portrait is a hit, no service at all.
	var lib: String = e2e["library"]
	var rig := Session.stub_rig(fresh("hit").path_join("log.ndjson"), lib)
	bridges.append(rig["bridge"])
	rig["relay"].open("portrait", "line", "medic", {"emotion": "grieving", "age_stage": 0})
	rig["sim"].send([], 0.0)
	rig["sim"].send([], 0.0)
	var a2 := by_req(events_of(rig["relay"], "ai_accepted"))
	assert_bool("cache hit: recorded and accepted with launch_count == 0", a2.get("1", {}).get("kind") == "portrait" and rig["bridge"].launch_count == 0 and rig["relay"].hits == 1)
	rig["sim"].stop()
	# AI.10a task 1: the service's voice index line carries duration_ms and segments_ms, so the same
	# session again over the same library voices the line from the library (no service call for it).
	var again := Session.stub_rig(fresh("voice_hit").path_join("log.ndjson"), lib)
	bridges.append(again["bridge"])
	var t2 := Session.run_session(again["sim"], again["relay"], again["bridge"])
	again["sim"].stop()
	var a4 := by_req(events_of(again["relay"], "ai_accepted"))
	var voice_line := {}
	for l in FileAccess.get_file_as_string(lib.path_join("index.ndjson")).split("\n", false):
		if l.contains("\"kind\":\"voice\""):
			voice_line = AiCache.ints(JSON.parse_string(l))
	assert_bool("the service's voice index line carries duration_ms %s and segments_ms %s" % [voice_line.get("duration_ms"), voice_line.get("segments_ms")],
		voice_line.get("duration_ms", 0) > 0 and voice_line.get("segments_ms") == [0])
	assert_bool("the same session again: the voice is a library hit (hits %d: portrait x2 + voice; forwarded %d: the texts)" % [again["relay"].hits, again["relay"].forwarded],
		t2 == 5 and a4.get("5", {}).get("kind") == "voice" and a4["5"].get("sha256") == acc.get("5", {}).get("sha256") and again["relay"].hits == 3 and again["relay"].forwarded == 3)
	# A cached asset needs neither live AI nor a key: mode off, no keys, still a hit.
	var off := Session.stub_rig(fresh("hit_off").path_join("log.ndjson"), lib, [])
	bridges.append(off["bridge"])
	off["relay"].mode = "off"
	off["relay"].open("portrait", "line", "medic", {"emotion": "grieving", "age_stage": 0})
	off["relay"].open("text", "line", "medic")
	off["sim"].send([], 0.0)
	off["sim"].send([], 0.0)
	var a3 := by_req(events_of(off["relay"], "ai_accepted"))
	var f3 := by_req(events_of(off["relay"], "ai_fallback"))
	assert_bool("mode off, no keys: the cached portrait still records (the uncached text falls back offline)",
		a3.get("1", {}).get("kind") == "portrait" and f3.get("2", {}).get("reason") == "offline" and off["bridge"].launch_count == 0)
	off["sim"].stop()
	# A service error result end to end: at the US$0.05 ceiling the second portrait is refused budget.
	var bl := fresh("budget")
	var bud := Session.stub_rig(bl.path_join("log.ndjson"), bl.path_join("library"))
	bridges.append(bud["bridge"])
	bud["bridge"].ceiling_usd = 0.05
	bud["relay"].open("portrait", "line", "medic", {"emotion": "grieving", "age_stage": 0})
	bud["relay"].open("portrait", "line", "medic", {"emotion": "sad", "age_stage": 0})
	bud["sim"].send([], 0.0)
	Session.idle(bud["bridge"], 20000)
	bud["sim"].send([], 0.0)
	var fb := by_req(events_of(bud["relay"], "ai_fallback"))
	assert_bool("ceiling 0.05: the first portrait accepted, the second refused budget -> ai_fallback budget",
		by_req(events_of(bud["relay"], "ai_accepted")).get("1", {}).get("kind") == "portrait" and fb.get("2", {}).get("reason") == "budget")
	bud["sim"].stop()
	return true


# ---------------------------------------------------------------- --news

func test_news() -> bool:
	print("AC18: purpose news through the stub; digits refused ai_numeral, template stands")
	if e2e.is_empty():
		return true
	var relay: AiRelay = e2e["relay"]
	var rq := by_req(events_of(relay, "ai_request"))
	var c: Dictionary = rq.get("2", {}).get("constraints", {})
	assert_bool("news request: purpose news, no_numerals, max_chars 280", rq.get("2", {}).get("purpose") == "news" and c.get("no_numerals") == true and c.get("max_chars") == 280)
	assert_bool("news accepted: '%s'" % by_req(events_of(relay, "ai_accepted")).get("2", {}).get("text"), by_req(events_of(relay, "ai_accepted")).get("2", {}).get("text") == "Stub news two for medic.")
	var digits: Dictionary = by_req(e2e["outcomes"].filter(func(o): return o.get("type") == "result")).get("4", {})
	assert_bool("the stub answered the digits case with a digit: '%s'" % digits.get("body"), digits.get("status") == "ok" and str(digits.get("body")).contains("42"))
	assert_bool("refused ai_numeral; no ai_accepted for it (the template stands)",
		by_req(events_of(relay, "ai_fallback")).get("4", {}).get("reason") == "ai_numeral" and not by_req(events_of(relay, "ai_accepted")).has("4"))
	return true


# ---------------------------------------------------------------- --key-hygiene

func key_files(which: Array) -> Dictionary:
	var d := fresh("keys_" + "_".join(which))
	var out := {}
	if "gemini" in which:
		out["gemini"] = d.path_join("gemini.key")
		FileAccess.open(out["gemini"], FileAccess.WRITE).store_string(KEY_G + "\n")
	if "openrouter" in which:
		out["openrouter"] = d.path_join("openrouter.key")
		FileAccess.open(out["openrouter"], FileAccess.WRITE).store_string(KEY_O)
	for f in out.values():
		OS.execute("/bin/chmod", PackedStringArray(["600", f]))
	return out


## Diagnostics never print a key: any key text is replaced before printing.
func redact(text: String) -> String:
	return text.replace(KEY_G, "<GEMINI KEY>").replace(KEY_O, "<OPENROUTER KEY>").replace("\n", " | ")


func has_key(text: String) -> bool:
	return text.contains(KEY_G) or text.contains(KEY_O)


## The same over a file's raw bytes (blobs are binary), compared as hex.
func file_has_key(path: String) -> bool:
	var hex := FileAccess.get_file_as_bytes(path).hex_encode()
	return hex.contains(KEY_G.to_utf8_buffer().hex_encode()) or hex.contains(KEY_O.to_utf8_buffer().hex_encode())


## Start the live launch by hand: sample its argv with ps while it starts,
## then send hello and read everything it prints.
func live_run(files: Dictionary, provider: String) -> Dictionary:
	var b := AiBridge.new()
	bridges.append(b)
	b.live = true
	b.key_files = files
	b.cache_dir = fresh("live_" + provider).path_join("library")
	var plan := b.live_plan(SimBridge.find_ailang(), res)
	var args: PackedStringArray = plan["args"]
	var i := args.find("--args-json") + 1
	var cfg = JSON.parse_string(args[i])
	cfg["provider"] = provider
	args[i] = SimBridge.encode(AiCache.ints(cfg))
	# Defence in depth: these runs only say hello, so no provider call can be
	# made even if the wrapper failed; the allowlist is narrowed to a host that
	# cannot resolve as well.
	args[args.find("--net-allow-domains") + 1] = "invalid.invalid"
	plan["args"] = args
	var t0 := Time.get_ticks_msec()
	# AI_LIVE=1 in Godot's own environment for the spawn only: the wrapper must
	# clear it (live_allowed is false), so the refusal still names AI_LIVE.
	OS.set_environment("AI_LIVE", "1")
	var proc := OS.execute_with_pipe(AiBridge.scrub_shell(), AiBridge.scrubbed(plan), false)
	OS.unset_environment("AI_LIVE")
	var pid: int = proc["pid"]
	var samples := []
	for n in 300:
		var out := []
		OS.execute("/bin/ps", PackedStringArray(["-o", "args=", "-p", str(pid)]), out)
		var a := str(out[0]).strip_edges()
		if a != "":
			samples.append(a)
		if a.contains("--entry live"):
			break
		OS.delay_msec(5)
	proc["stdio"].store_string('{"v":1,"type":"hello","want":{"major":1}}\n')
	proc["stdio"].flush()
	var got := PackedByteArray()
	var end := Time.get_ticks_msec() + 60000 # a cold first start on CI can take seconds; a refusal exits at once
	while Time.get_ticks_msec() < end:
		var chunk: PackedByteArray = proc["stdio"].get_buffer(4096)
		got.append_array(chunk)
		if chunk.is_empty():
			if not OS.is_process_running(pid):
				got.append_array(proc["stdio"].get_buffer(65536))
				break
			OS.delay_msec(5)
	var err: PackedByteArray = proc["stderr"].get_buffer(65536)
	if OS.is_process_running(pid):
		OS.kill(pid)
	return {"argv": samples, "stdout": got.get_string_from_utf8().strip_edges(), "stderr": err.get_string_from_utf8(), "lib": b.cache_dir, "ms": Time.get_ticks_msec() - t0}


func fatal(detail: String) -> String:
	return '{"v":1,"type":"fatal","code":"config","detail":"config: %s"}' % detail


func test_key_hygiene() -> bool:
	print("AC14: key files, never key text: argv, stdout, stderr, session log, library (AI_LIVE=1 in Godot's env is cleared)")
	var both := key_files(["gemini", "openrouter"])
	var cases := [
		[both, "live", fatal("live provider refused: AI_LIVE=1 is not set (attended sessions only)"), "both keys read (the refusal is AI_LIVE, not a key)"],
		[both, "openrouter", fatal("live provider refused: AI_LIVE=1 is not set (attended sessions only)"), "OPENROUTER_API_KEY read from its file"],
		[key_files(["gemini"]), "gemini", fatal("live provider refused: AI_LIVE=1 is not set (attended sessions only)"), "gemini only: GOOGLE_API_KEY read from its file"],
		[key_files(["gemini"]), "openrouter", fatal("provider openrouter refused: OPENROUTER_API_KEY is empty"), "an OpenRouter route with its key env var empty refuses"],
		[key_files(["openrouter"]), "gemini", fatal("provider gemini refused: GOOGLE_API_KEY is empty"), "a Gemini route with its key env var empty refuses"],
	]
	for c in cases:
		var r := live_run(c[0], c[1])
		var argv: Array = r["argv"]
		var final_argv: String = argv.back() if not argv.is_empty() else ""
		assert_bool("%s: live argv sampled %d times (last: ...%s), never a key" % [c[3], argv.size(), final_argv.right(60)],
			final_argv.contains("--entry live") and final_argv.contains("--caps IO,FS,Env,Net,AI") and not argv.any(func(a): return has_key(a)))
		var ok_out: bool = r["stdout"] == c[2] and not has_key(r["stdout"]) and not has_key(r["stderr"])
		assert_bool("%s: stdout is the refusal, no key in stdout or stderr%s" % [c[3], "" if ok_out else " -- stdout [%s] stderr tail [%s] (%d ms)" % [redact(r["stdout"]), redact(str(r["stderr"]).right(400)), r["ms"]]], ok_out)
		assert_bool("%s: refused before the cache was made" % c[3], not DirAccess.dir_exists_absolute(r["lib"]))
		# std/ai is bound (--ai) only with a Gemini key file: without one, ailang
		# falls back to Application Default Credentials at startup (a gcloud
		# identity where one exists; on CI, no ADC: it exits before the service
		# runs, Ubuntu run 37104445321).
		var has_g: bool = c[0].has("gemini")
		assert_bool("%s: --ai %s" % [c[3], "bound to the image model" if has_g else "not passed (no Gemini key, so no ADC fallback)"],
			final_argv.contains("--ai gemini-2.5-flash-image") == has_g and (has_g or final_argv.find(" --ai ") < 0))
		# AI.9: gcloud ADC in HOME wins over GOOGLE_API_KEY on v0.51+, so Gemini
		# is bound to the key file's path, and ADC is off in every live launch.
		assert_bool("%s: --ai-no-adc%s" % [c[3], ", --ai-key-file <the Gemini key file>" if has_g else ""],
			final_argv.contains(" --ai-no-adc") and (final_argv.contains("--ai-key-file " + c[0].get("gemini", "")) if has_g else final_argv.find("--ai-key-file") < 0))
	# Through the relay and the bridge: the live service refuses at hello (no
	# AI_LIVE), three failures, service_down; the request falls back.
	var lib := fresh("live_relay")
	var rig := Session.stub_rig(lib.path_join("session.ndjson"), lib.path_join("library"))
	var b: AiBridge = rig["bridge"]
	bridges.append(b)
	b.live = true
	b.key_files = both
	b.keep_lines = true
	b.backoff_ms = [50, 50, 50]
	rig["relay"].mode = "live"
	rig["relay"].open("text", "line", "medic")
	rig["sim"].send([], 0.0)
	Session.idle(b, 20000)
	rig["sim"].send([], 0.0)
	rig["sim"].stop()
	var fb := by_req(events_of(rig["relay"], "ai_fallback"))
	assert_bool("live refused three times -> service_down -> ai_fallback service_down (%d launches)" % b.launch_count, b.service_down and b.launch_count == 3 and fb.get("1", {}).get("reason") == "service_down")
	var said := "\n".join(b.lines_read)
	assert_bool("the bridge read the refusals (%d lines), no key in them or in stderr" % b.lines_read.size(), b.lines_read.size() == 3 and said.contains("AI_LIVE=1 is not set") and not has_key(said) and not has_key(b.stderr_tail))
	var leaked := []
	var log_text := FileAccess.get_file_as_string(lib.path_join("session.ndjson"))
	if has_key(log_text): leaked.append("session log")
	for f in files_under(lib):
		if file_has_key(f): leaked.append(f)
	assert_bool("no key text in the session log or any file under the library (usage.ndjson included): %s" % [leaked], leaked.is_empty() and log_text.contains('"ai_open"'))
	# The stub session's library and usage.ndjson (AC10 run): no key either (the stub never sees one).
	if not e2e.is_empty():
		var lf: Array = files_under(e2e["library"])
		assert_bool("stub library (%d files, usage.ndjson among them) has no key text" % lf.size(), lf.any(func(f): return f.ends_with("usage.ndjson")) and not lf.any(func(f): return file_has_key(f)))
	return true


func files_under(dir: String) -> Array:
	var out := []
	var d := DirAccess.open(dir)
	if d == null:
		return out
	for f in d.get_files():
		out.append(dir.path_join(f))
	for s in d.get_directories():
		out.append_array(files_under(dir.path_join(s)))
	return out


# ---------------------------------------------------------------- --routes

func test_routes() -> bool:
	print("routes: the relay's route == the service's for the keys present; the log is route-blind")
	if e2e.is_empty():
		return true
	var g := session("routes_gemini", ["gemini"])
	if g.is_empty():
		return true
	for run in [[e2e, "openrouter"], [g, "gemini"]]:
		var r: Dictionary = run[0]
		var routes: Dictionary = r["bridge"].hello_reply.get("routes", {})
		var same := routes.size() == 4
		for kind in ["text", "voice", "portrait", "avatar"]:
			var want: String = routes.get(kind, {}).get("route", "?")
			same = same and r["relay"].route_for(kind) == ("" if want == "none" else want)
		var text_routes := []
		for o in r["outcomes"]:
			if o.get("kind") == "text" and o.get("status") == "ok":
				text_routes.append(o["meta"]["route"])
		assert_bool("keys %s: route_for == hello routes %s; text answered via %s" % [r["relay"].keys, routes.keys(), text_routes],
			same and not text_routes.is_empty() and text_routes.all(func(x): return x == run[1]))
	assert_bool("the session log is byte-identical whichever route answered (%d bytes)" % g["log"].size(), g["log"] == e2e["log"])
	var n := rig_without_service("routes_none", "stub", [])
	assert_bool("no keys: no route for any kind", ["text", "voice", "portrait", "avatar"].all(func(k): return n["relay"].route_for(k) == ""))
	n["sim"].stop()
	return true


# ---------------------------------------------------------------- --replay-noai

func test_replay_noai() -> bool:
	print("AC12 part: ai_stub_session replays through Godot, relay in replay mode, no AI process")
	var arch := "arm64" if OS.has_feature("arm64") else "x86_64"
	var golden := FileAccess.get_file_as_string("res://tests/replays/ai_stub_session.state.%s.ndjson" % arch).split("\n", false)
	var lines := FileAccess.get_file_as_string(LOG).split("\n", false)
	var sim := SimBridge.new()
	var ok := sim.start() and sim.last_line == golden[0]
	var ng = JSON.parse_string(lines[1])
	ok = ok and sim.new_game(int(ng["seed"]), ng["scenario"], ng["diag"]) and sim.last_line == golden[1]
	var b := AiBridge.new()
	bridges.append(b)
	var cache := AiCache.new()
	cache.core_dir = fresh("replay").path_join("core")
	cache.library_dir = scratch.path_join("replay/library")
	var relay := AiRelay.new(b, cache)
	relay.mode = "replay"
	ok = ok and relay.attach(sim)
	var n := 2
	var queued := 0
	for i in range(2, lines.size()):
		var m = JSON.parse_string(lines[i])
		if m.get("type") != "input":
			continue
		ok = ok and sim.send(AiCache.ints(m["intents"]), float(m["dtau"])) and sim.last_line == golden[n]
		queued += relay.queued()
		b.poll()
		n += 1
	sim.stop()
	assert_bool("%d state lines == tests/replays/ai_stub_session.state.%s.ndjson" % [n, arch], ok and n == golden.size())
	assert_bool("replay mode queued nothing and started no AI process (launch_count %d)" % b.launch_count, queued == 0 and b.launch_count == 0 and b.child_pid == -1)
	assert_bool("an empty library: the 3 accepted media flagged missing_blob, the text still shown (%d)" % relay.missing_blobs,
		relay.missing_blobs == 3 and events_of(relay, "ai_accepted").filter(func(e): return e["kind"] == "text").size() == 2)
	return true


# ---------------------------------------------------------------- --faults

func test_faults() -> bool:
	print("AC11: delegated to tests/test_ai_bridge.gd -- --faults")
	var out := []
	var rc := OS.execute(OS.get_executable_path(), PackedStringArray(["--headless", "--path", res, "--script", "tests/test_ai_bridge.gd", "--", "--faults"]), out, true)
	var tail := str(out[0]).strip_edges().split("\n")
	assert_bool("test_ai_bridge.gd --faults: rc %d, '%s'" % [rc, tail[tail.size() - 1]], rc == 0)
	return true


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(scratch)
	if SimBridge.find_ailang() == "":
		print("FAIL  ailang not found (AILANG_BIN or PATH)")
		quit(2)
		return
	var flags := OS.get_cmdline_user_args()
	var tests := ["cache", "disabled_old_sim", "cancels", "e2e"]
	for f in ["news", "key-hygiene", "routes", "replay-noai", "faults"]:
		if "--" + f in flags:
			tests.append(f.replace("-", "_"))
	if "--replay-noai" in flags and flags.size() == 1:
		tests = ["replay_noai"]
	for t in tests:
		if call("test_" + t) != true: # a script error aborts a test silently
			assert_bool("test_%s ran to its end" % t, false)
	for b in bridges:
		b.shutdown()
	for b in bridges:
		b.free()
	print("ai relay: %s (%s)" % ["FAIL" if failures > 0 else "ok", ", ".join(tests)])
	quit(1 if failures > 0 else 0)
