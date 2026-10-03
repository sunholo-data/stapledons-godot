extends SceneTree
## The Medic conversation on the stub (sprint R1-AI-FOUNDATION AI.10a, design
## ai-service-foundation (c)), headless:
##   rehearsal  the sim, relay and stub service record one Medic line
##              (neutral, loving, grieving) and its voice; the tee equals
##              tests/replays/medic_rehearsal.ndjson byte for byte; the voice
##              descriptor's offsets are exact (strictly increasing, below
##              duration_ms) and its library line carries them; the cast entry
##              names the voice
##   swaps      the portrait swaps at each segments_ms offset (± one frame),
##              crossfades over crossfade_ms, the subtitle reveals segment by
##              segment, the WAV playback copy plays
##   offset     swap_offset_ms -150 leads every swap by 150 ms (± one frame)
##   fallback   a missing emotion walks the fallback chain; a person with no
##              portraits logs missing_portrait; no voice: reading-pace offsets
##   no_audio   a voice whose blob is in no layer logs missing_blob and the
##              line plays as text (swaps and subtitle unchanged)
##   replay     the committed log replays with no AI process and picks the
##              same line and voice; an empty library flags the voice missing
##   session_off  the AiSession path (`--ai-live`, AI.10b) with no key and no
##              tick: relay off, no service launched, no line, nothing spent
## Run:  godot --headless --path . --script tests/test_conversation.gd [-- --only=a,b]
##       ... -- --record=OUT.ndjson [--library=DIR]   re-record the rehearsal log over a fresh
##       library (make ai-rehearsal-record; make ai-style-frame uses the library)

const LOG := "res://tests/replays/medic_rehearsal.ndjson"
const SCENE := "res://ui/conversation/conversation.tscn"
const FRAME_MS := 1000.0 / 60.0
const TESTS := ["rehearsal", "swaps", "offset", "fallback", "no_audio", "replay", "session_off"]

var failures := 0
var scratch := ProjectSettings.globalize_path("res://.godot/tmp/conversation")
## The rehearsal (reused by the later tests): {line, voice, library}.
var reh: Dictionary = {}
var core := ""


func assert_bool(name: String, ok: bool) -> void:
	if not ok: failures += 1
	print("  %s  %s" % ["ok  " if ok else "FAIL", name])


func fresh(name: String) -> String:
	var d := scratch.path_join(name)
	OS.execute("/bin/rm", PackedStringArray(["-rf", d]))
	DirAccess.make_dir_recursive_absolute(d)
	return d


## A core layer from tests/ai/core_fixture (64x64 Medic stand-ins with the
## real keys: neutral, loving, grieving at 0, neutral at 50, the avatar).
func fixture_core() -> String:
	var d := fresh("core")
	var idx := FileAccess.get_file_as_string("res://tests/ai/core_fixture/expected/index.ndjson")
	for line in idx.split("\n", false):
		var e: Dictionary = JSON.parse_string(line)
		var sha: String = e["sha256"]
		var src: String = e["source"].split(":", true, 1)[1]
		DirAccess.make_dir_recursive_absolute(d.path_join("blobs/" + sha.substr(0, 2)))
		DirAccess.copy_absolute(ProjectSettings.globalize_path("res://" + src), d.path_join("blobs/%s/%s.png" % [sha.substr(0, 2), sha]))
	FileAccess.open(d.path_join("index.ndjson"), FileAccess.WRITE).store_string(idx)
	return d


## Record the rehearsal over a fresh library: {log (bytes), events, ticks, library}.
func record(log_path: String, library: String) -> Dictionary:
	var rig := ConversationSession.stub_rig(log_path, library)
	if rig.is_empty():
		return {}
	var ticks := ConversationSession.rehearse(rig["sim"], rig["relay"], rig["bridge"])
	rig["sim"].stop()
	rig["bridge"].shutdown()
	var out := {"ticks": ticks, "events": rig["relay"].seen, "log": FileAccess.get_file_as_bytes(log_path), "library": library, "relay": rig["relay"]}
	rig["bridge"].free()
	return out


func conversation(library: String, core_dir: String = core) -> Conversation:
	var c: Conversation = load(SCENE).instantiate()
	root.add_child(c)
	c.auto_clock = false
	c.cache.core_dir = core_dir
	c.cache.library_dir = library
	c.cache.load_layers()
	return c


## Play to the end in steps of one 60 Hz frame (at most 30 s).
func run(c: Conversation) -> void:
	c.play()
	var n := 0
	while c.playing and n < 1800:
		c.advance(FRAME_MS)
		n += 1


func within_frame(t: float, want: float) -> bool:
	return t >= want and t < want + FRAME_MS + 0.5


# ---------------------------------------------------------------- tests

func test_rehearsal() -> bool:
	print("rehearsal: one Medic line and its voice on the stub; the tee == %s" % LOG.get_file())
	var lib := fresh("rehearsal").path_join("library")
	var r := record(scratch.path_join("rehearsal/session.ndjson"), lib)
	if r.is_empty():
		assert_bool("sim and relay start", false)
		return true
	var p := ConversationSession.pick(r["events"], "medic")
	reh = {"line": p["line"], "voice": p["voice"], "library": lib}
	var segs: Array = p["line"].get("segments", [])
	assert_bool("five ticks; the line has three segments neutral, loving, grieving: %s" % [segs.map(func(s): return s["emotion"])],
		r["ticks"] == 5 and segs.map(func(s): return s["emotion"]) == ["neutral", "loving", "grieving"])
	var d: Dictionary = p["voice"].get("descriptor", {})
	var offs: Array = d.get("segments_ms", [])
	var inc: bool = offs.size() == 3 and offs[0] == 0
	for i in range(1, offs.size()):
		inc = inc and offs[i] > offs[i - 1] and offs[i] < d.get("duration_ms", 0)
	assert_bool("voice offsets exact: %s, strictly increasing, below duration_ms %s" % [offs, d.get("duration_ms")], inc)
	# The stub's tones are 50 ms a code point (200 ms .. 8 s) in whole periods, so offsets follow the text.
	assert_bool("offsets track the segment lengths (50 ms a code point, whole periods)",
		absi(offs[1] - segs[0]["text"].length() * 50) <= 5 and absi(offs[2] - offs[1] - segs[1]["text"].length() * 50) <= 5)
	var c := AiCache.new()
	c.core_dir = lib.path_join("no_core")
	c.library_dir = lib
	c.load_layers()
	var e := c.find_sha(p["voice"].get("sha256", ""))
	assert_bool("the library's voice line carries the same duration_ms and segments_ms", e.get("duration_ms") == d.get("duration_ms") and e.get("segments_ms") == offs)
	var wav := c.playback_path(e)
	var st := AudioStreamWAV.load_from_buffer(FileAccess.get_file_as_bytes(wav)) if wav != "" else null
	assert_bool("a WAV playback copy beside the Ogg blob, %s s long" % [st.get_length() if st else -1.0],
		st != null and absf(st.get_length() * 1000.0 - d.get("duration_ms", 0)) < 2.0)
	var cast = JSON.parse_string(FileAccess.get_file_as_string("res://data/ai/cast/medic.json"))
	assert_bool("data/ai/cast/medic.json: departure age 35, voice %s, persona, style, 4 portrait keys and the avatar" % cast.get("voice_id"),
		cast.get("departure_age") == 35.0 and cast.get("voice_id") == "Aoede" and cast.get("persona", "").length() > 100 and cast.get("style", "") != ""
		and cast.get("portraits", []).size() == 4 and cast.get("avatar", {}).get("kind") == "avatar")
	assert_bool("the relay's cast comes from medic.json, and the voice key variant names that voice",
		r["relay"].cast.get("medic", {}).get("voice") == cast["voice_id"] and d.get("key", {}).get("variant") == AiCache.voice_variant(cast["voice_id"], segs))
	var golden := FileAccess.get_file_as_bytes(LOG)
	assert_bool("the tee wrote the session log; it equals %s (%d bytes)" % [LOG.get_file(), golden.size()], golden.size() > 0 and r["log"] == golden)
	return true


func test_swaps() -> bool:
	print("swaps at each segments_ms offset (± one frame), crossfade, subtitle, audio")
	if reh.is_empty():
		return true
	var c := conversation(reh["library"])
	c.setup(reh["line"], reh["voice"])
	var offs: Array = reh["voice"]["descriptor"]["segments_ms"]
	assert_bool("crossfade 120 ms and swap offset 0 by default; the WAV stream is loaded", c.crossfade_ms == 120.0 and c.swap_offset_ms == 0.0 and c.audio.stream is AudioStreamWAV)
	run(c)
	var sw := c.events_named("swap")
	assert_bool("three portraits shown: %s" % [sw.map(func(x): return x["shown"])], sw.map(func(x): return x["shown"]) == ["neutral", "loving", "grieving"])
	var ok := sw.size() == 3
	for i in sw.size():
		ok = ok and sw[i]["segment"] == i and within_frame(sw[i]["t_ms"], offs[i])
	assert_bool("each swap within one frame after its offset: %s vs %s" % [sw.map(func(x): return x["t_ms"]), offs], ok)
	var fd := c.events_named("faded")
	assert_bool("each crossfade completes crossfade_ms after its swap (± one frame): %s" % [fd.map(func(x): return x["t_ms"])],
		fd.size() == 2 and within_frame(fd[0]["t_ms"], offs[1] + 120.0) and within_frame(fd[1]["t_ms"], offs[2] + 120.0))
	assert_bool("the subtitle ends as the accepted text", c.subtitle.text == reh["line"]["text"])
	assert_bool("the line ends after duration_ms plus the tail", c.events_named("end").size() == 1 and c.events_named("end")[0]["t_ms"] >= reh["voice"]["descriptor"]["duration_ms"] + Conversation.TAIL_MS)
	# Mid-fade: halfway through the crossfade the incoming portrait is half opaque; the subtitle shows two segments.
	c.play()
	while c.t_ms < offs[1]:
		c.advance(FRAME_MS)
	var into: float = c.t_ms - offs[1]
	c.advance(60.0 - into)
	var segs: Array = reh["line"]["segments"]
	assert_bool("halfway through the fade B is %.2f opaque; subtitle reveals two segments" % c.portrait_b.modulate.a,
		absf(c.portrait_b.modulate.a - 0.5) < 0.01 and c.subtitle.text == segs[0]["text"] + " " + segs[1]["text"])
	c.queue_free()
	return true


func test_offset() -> bool:
	print("swap offset -150 ms leads each swap (± one frame)")
	if reh.is_empty():
		return true
	var c := conversation(reh["library"])
	c.swap_offset_ms = -150.0
	c.setup(reh["line"], reh["voice"])
	run(c)
	var offs: Array = reh["voice"]["descriptor"]["segments_ms"]
	var sw := c.events_named("swap")
	assert_bool("swaps at %s for offsets %s" % [sw.map(func(x): return x["t_ms"]), offs],
		sw.size() == 3 and sw[0]["t_ms"] == 0 and within_frame(sw[1]["t_ms"], offs[1] - 150.0) and within_frame(sw[2]["t_ms"], offs[2] - 150.0))
	c.queue_free()
	return true


func test_fallback() -> bool:
	print("fallback chain for a missing emotion; no portraits; no voice: reading pace")
	var lib := fresh("fallback")
	var c := conversation(lib)
	var line := {"req": "1", "text": "a b c", "segments": [{"emotion": "happy", "text": "Bright."}, {"emotion": "angry", "text": "No."}, {"emotion": "sad", "text": "Gone now."}]}
	c.setup(line, {})
	assert_bool("no voice: offsets at a reading pace %s" % [c.offsets], c.offsets == [0, 1500, 3000] and c.audio.stream == null)
	run(c)
	var seg := c.events_named("segment")
	assert_bool("happy -> loving, angry -> neutral, sad -> grieving: %s" % [seg.map(func(x): return x["shown"])], seg.map(func(x): return x["shown"]) == ["loving", "neutral", "grieving"])
	c.entity = "nobody"
	c.setup(line, {})
	run(c)
	assert_bool("a person with no portraits: missing_portrait for each segment, the text still shown",
		c.events_named("missing_portrait").size() == 3 and c.subtitle.text == "Bright. No. Gone now." and c.portrait_a.texture == null)
	c.queue_free()
	return true


func test_no_audio() -> bool:
	print("missing audio degrades to text, missing_blob logged")
	if reh.is_empty():
		return true
	var c := conversation(fresh("no_audio"))
	c.setup(reh["line"], reh["voice"])
	assert_bool("the voice blob is in no layer: missing_blob logged, no stream", c.events_named("missing_blob").size() == 1 and c.events_named("missing_blob")[0]["kind"] == "voice" and c.audio.stream == null)
	run(c)
	var offs: Array = reh["voice"]["descriptor"]["segments_ms"]
	var sw := c.events_named("swap")
	assert_bool("the line still plays as text at the voice offsets: %s" % [sw.map(func(x): return x["t_ms"])],
		sw.size() == 3 and within_frame(sw[2]["t_ms"], offs[2]) and c.subtitle.text == reh["line"]["text"])
	# The Ogg blob without its playback copy (an older library): logged, text only.
	var lib := fresh("no_wav")
	OS.execute("/bin/cp", PackedStringArray(["-R", reh["library"] + "/.", lib]))
	for f in DirAccess.get_files_at(lib.path_join("blobs/" + reh["voice"]["sha256"].substr(0, 2))):
		if f.ends_with(".wav"):
			DirAccess.remove_absolute(lib.path_join("blobs/%s/%s" % [reh["voice"]["sha256"].substr(0, 2), f]))
	var c2 := conversation(lib)
	c2.setup(reh["line"], reh["voice"])
	assert_bool("an Ogg blob without its WAV copy: no_playback_copy logged, no stream", c2.events_named("no_playback_copy").size() == 1 and c2.audio.stream == null)
	c.queue_free()
	c2.queue_free()
	return true


func test_replay() -> bool:
	print("the committed log replays (no AI process) and picks the same line and voice")
	if reh.is_empty():
		return true
	var c := AiCache.new()
	c.core_dir = core
	c.library_dir = reh["library"]
	c.load_layers()
	var r := ConversationSession.replay(ProjectSettings.globalize_path(LOG), c)
	var p := ConversationSession.pick(r["events"], "medic")
	assert_bool("replayed with no AI process; the same line and voice", r["ok"] and r["launches"] == 0 and p["line"] == reh["line"] and p["voice"] == reh["voice"])
	assert_bool("with the library: nothing missing", r["relay"].missing_blobs == 0)
	var empty := AiCache.new()
	empty.core_dir = core
	empty.library_dir = fresh("replay_empty")
	empty.load_layers()
	var r2 := ConversationSession.replay(ProjectSettings.globalize_path(LOG), empty)
	assert_bool("an empty library: the voice flagged missing_blob (%d), the line still picked" % r2["relay"].missing_blobs,
		r2["relay"].missing_blobs == 1 and ConversationSession.pick(r2["events"], "medic")["line"] == reh["line"])
	return true


func test_session_off() -> bool:
	print("the AiSession path with live AI off (no key, no tick): nothing generated, no service")
	var dir := fresh("session_off")
	var rig := ConversationSession.session_rig({}, dir.path_join("log.ndjson"), dir)
	if rig.is_empty():
		assert_bool("sim and AiSession start", false)
		return true
	var n := ConversationSession.rehearse(rig["sim"], rig["relay"], rig["bridge"], "medic", false)
	rig["sim"].stop()
	var fb: Array = rig["relay"].seen.filter(func(e): return e["k"] == "ai_fallback")
	assert_bool("relay off; the line falls back offline; no line, no launch (ticks %d, fallbacks %s)" % [n, fb.map(func(e): return e.get("reason"))],
		rig["relay"].mode == "off" and n == -1 and fb.size() == 1 and fb[0].get("reason") == "offline" and rig["bridge"].launch_count == 0)
	rig["session"].free()
	return true


func _initialize() -> void:
	var args := Conversation.parse_args(OS.get_cmdline_user_args())
	if args.has("record"):
		var lib: String = args.get("library", "")
		if lib == "":
			lib = fresh("record").path_join("library")
		else:
			OS.execute("/bin/rm", PackedStringArray(["-rf", lib]))
		var r := record(args["record"], lib)
		print("recorded %s: %d ticks; library %s" % [args["record"], r.get("ticks", -1), lib])
		quit(0 if r.get("ticks", -1) == 5 else 1)
		return
	core = fixture_core()
	var tests: Array = TESTS
	if args.get("only", "") != "":
		tests = ["rehearsal"] + Array(args["only"].split(",")).filter(func(t): return t != "rehearsal")
	for t in tests:
		if call("test_" + t) != true: # a script error aborts a test silently
			assert_bool("test_%s ran to its end" % t, false)
	print("conversation: %s (%s)" % ["FAIL" if failures > 0 else "ok", ", ".join(tests)])
	quit(1 if failures > 0 else 0)
