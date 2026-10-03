class_name SimBridge
extends RefCounted
## Runs the AILANG simulation as a child process and talks protocol v2 NDJSON
## over its stdin/stdout (design m2-journey-core §M2.1): `hello`, then
## `new_game`, then one `input` line in and one `state` line out per tick.
## The world state lives in AILANG; Godot sends intents and mirrors the state
## by applying each reply's change-set to `world`.

const SIM_FILE := "sim/ship.ail"
const PROTO_MAJOR := 2
## 2.1 (AI.3): the sim's `ai` section and AI events; AiRelay reads them (AI.7).
const PROTO_MINOR := 1

## The minor this session asks for (opt-in, set before start()). The interior (M4.2) asks
## for 2 (M4.1: ship.ism and the consequence section); everything else keeps 2.1, so the
## recorded sessions and their replay goldens are unchanged.
var want_minor := PROTO_MINOR

var _pipe: FileAccess
var _stderr: FileAccess
var _record: FileAccess
var _pid := -1
var _game := false
## Mirrored world: `tick`, `status` and every section the sim has sent
## (`clock`, `ship`, `params`, ...). A change-set replaces whole sections and
## leaves the others alone.
var world: Dictionary = {}
## The last message read from the sim, as parsed, and its raw text.
var state: Dictionary = {}
var last_line := ""
## The sim's hello reply (proto, sim, relativity, rng).
var hello_reply: Dictionary = {}
## `refused` and `events` of the last accepted input.
var last_refused: Array = []
var last_events: Array = []
var last_error := ""
var child_pid := -1
var launch_override: Dictionary = {}
## When set before start(), every line written to the sim's stdin is also
## appended here byte for byte: an NDJSON input log that replays the session.
var record_path := ""
## Optional AiRelay (AI.7): unset, nothing changes. Set, its queued intents
## (`take_intents()`) ride on every send after the caller's, and it is shown
## every accepted tick's events (`on_events`). Intents of a line the sim does
## not accept are dropped; their requests expire in the sim (ai_ttl_ticks).
var ai_relay: Object = null
var _line_bytes := PackedByteArray()


static func find_ailang() -> String:
	var env := OS.get_environment("AILANG_BIN")
	if env != "":
		return env
	for dir in OS.get_environment("PATH").split(":"):
		var p := dir.path_join("ailang")
		if FileAccess.file_exists(p):
			return p
	return ""


## Launch the sim and complete the handshake. The sim prints nothing before
## its hello reply.
func start() -> bool:
	var launch := launch_override if not launch_override.is_empty() else _launch_plan()
	if launch.is_empty():
		return false
	var started := Time.get_ticks_msec()
	# Through the descriptor scrub (as AiBridge): execute_with_pipe sets no
	# close-on-exec, so the sim would otherwise inherit every pipe Godot holds.
	var proc := OS.execute_with_pipe(AiBridge.scrub_shell(), AiBridge.scrubbed(launch), false)
	if proc.is_empty():
		push_error("failed to start %s" % launch["bin"])
		return false
	_pipe = proc["stdio"]
	_stderr = proc["stderr"]
	_pid = proc["pid"]
	child_pid = _pid
	if record_path != "":
		_record = FileAccess.open(record_path, FileAccess.WRITE)
		if _record == null:
			push_error("cannot record to %s" % record_path)
	return hello(started + 5000)


## Send `hello` and accept only an integer protocol major of 2.
func hello(deadline: int = Time.get_ticks_msec() + 5000) -> bool:
	if _pid < 0:
		return false
	_write(encode({"v": 2, "type": "hello", "want": {"major": PROTO_MAJOR, "minor": want_minor}}))
	if not _read_state(deadline, "startup_timeout"):
		return false
	var proto = state.get("proto")
	if state.get("type") != "hello" or typeof(proto) != TYPE_DICTIONARY \
			or not _is_count(proto.get("major")) or not _is_count(proto.get("minor")) or proto["major"] != PROTO_MAJOR:
		return _fail("bad_proto")
	hello_reply = state.duplicate(true)
	return true


## Start a world. Returns false (child kept, `last_error` = the sim's reason)
## if the sim refuses the request.
func new_game(seed: int, scenario: String = "sol", diag: bool = false, params: Dictionary = {}, ai_core: String = "") -> bool:
	if _pid < 0 or hello_reply.is_empty():
		last_error = "no_hello"
		return false
	var msg := {"v": 2, "type": "new_game", "seed": seed, "scenario": scenario, "diag": diag}
	if not params.is_empty():
		msg["params"] = params
	if ai_core != "":
		msg["ai_core"] = ai_core
	_write(encode(msg))
	if not _read_state(Time.get_ticks_msec() + 2000, "step_timeout"):
		return false
	if state.get("type") != "state":
		return _fail("bad_response")
	if state.get("status") != "ok":
		last_error = state.get("status", "bad_response")
		return false
	if state.get("full") != true or state.get("tick") != 0 or typeof(state.get("changes")) != TYPE_DICTIONARY:
		return _fail("bad_response")
	world = state["changes"].duplicate(true)
	world["tick"] = 0
	world["status"] = "ok"
	_game = true
	return true


## One tick: `intents` (dictionaries tagged by "k") over `dtau` ship-years.
## True when the sim accepted the line and the tick advanced; refused intents
## are then in `last_refused`. A malformed line leaves `world` unchanged and
## returns false with the sim's reason in `last_error`; the child keeps
## running. Nothing is sent before new_game has been answered.
func send(intents: Array, dtau: float) -> bool:
	if _pid < 0:
		return false
	if not _game:
		last_error = "no_game"
		return false
	var tick := int(world["tick"]) + 1
	if ai_relay != null:
		intents = intents + ai_relay.take_intents()
	_write(encode({"v": 2, "type": "input", "tick": tick, "dtau": dtau, "intents": intents}))
	if not _read_state(Time.get_ticks_msec() + 2000, "step_timeout"):
		return false
	if state.get("type") != "state" or typeof(state.get("changes")) != TYPE_DICTIONARY:
		return _fail("bad_response")
	if state.get("status") != "ok":
		last_error = state.get("status", "bad_response")
		return false
	if state.get("tick") != tick:
		return _fail("bad_response")
	var changes: Dictionary = state["changes"]
	for section in changes:
		world[section] = changes[section].duplicate(true) if changes[section] is Dictionary else changes[section]
	world["tick"] = tick
	world["status"] = "ok"
	last_refused = state.get("refused", [])
	last_events = state.get("events", [])
	if ai_relay != null:
		ai_relay.on_events(last_events)
	return true


func stop() -> void:
	if _pid < 0:
		return
	_cleanup()


## JSON text for a request. Floats use Godot's shortest round-trip digits
## (`full_precision`), except -0.0, which Godot prints as "0.0" and std/json
## needs as "-0.0" (ailang#1460). Ints stay integers. Keys keep their order.
static func encode(v: Variant) -> String:
	match typeof(v):
		TYPE_DICTIONARY:
			var parts := PackedStringArray()
			for k in v:
				parts.append(JSON.stringify(str(k)) + ":" + encode(v[k]))
			return "{" + ",".join(parts) + "}"
		TYPE_ARRAY:
			var items := PackedStringArray()
			for x in v:
				items.append(encode(x))
			return "[" + ",".join(items) + "]"
		TYPE_FLOAT:
			return number(v)
		TYPE_INT:
			return str(v)
	return JSON.stringify(v)


static func number(x: float) -> String:
	if x == 0.0:
		var b := PackedByteArray()
		b.resize(8)
		b.encode_double(0, x)
		return "-0.0" if b[7] & 0x80 else "0.0"
	return JSON.stringify(x, "", true, true)


static func _is_count(v: Variant) -> bool:
	return (typeof(v) == TYPE_FLOAT and is_finite(v) and v == floorf(v) and v >= 0.0) or (typeof(v) == TYPE_INT and v >= 0)


func _write(line: String) -> void:
	_pipe.store_line(line)
	_pipe.flush()
	if _record != null:
		_record.store_string(line + "\n")
		_record.flush()


static func _run_args(ailang: String, sim_dir: String) -> PackedStringArray:
	# --package-dir holds ailang.toml, so module paths resolve from any cwd.
	return PackedStringArray([ailang, "run", "--quiet", "--bytecode", "--package-dir", sim_dir,
		"--caps", "IO", "--entry", "main", sim_dir.path_join(SIM_FILE.get_file())])


## Editor / source checkout: ailang from AILANG_BIN or PATH, sim from the repo.
## Exported build: the bundled runtime (pinned ailang + package cache + sim),
## unpacked once per version into user://, run with its own HOME because
## ailang's package cache is fixed at $HOME/.ailang/cache/registry.
func _launch_plan() -> Dictionary:
	if not OS.has_feature("template"):
		var bin := find_ailang()
		if bin == "":
			push_error("ailang not found; set AILANG_BIN or add it to PATH")
			return {}
		var dev_args := _run_args(bin, ProjectSettings.globalize_path("res://" + SIM_FILE.get_base_dir()))
		return {"bin": dev_args[0], "args": dev_args.slice(1)}
	var root := _unpack_runtime()
	if root == "":
		return {}
	var args := PackedStringArray(["HOME=" + root.path_join("home")])
	args.append_array(_run_args(root.path_join("runtime/bin/ailang"), root.path_join("sim")))
	return {"bin": "/usr/bin/env", "args": args}


static func _unpack_runtime() -> String:
	var version := FileAccess.get_file_as_string("res://runtime/VERSION").strip_edges()
	if version == "":
		push_error("exported build has no bundled runtime (res://runtime/VERSION missing)")
		return ""
	var root := ProjectSettings.globalize_path("user://runtime-%s" % version)
	var marker := root.path_join(".unpacked")
	if not FileAccess.file_exists(marker):
		for pair in [["res://runtime", root.path_join("runtime")], ["res://sim", root.path_join("sim")],
				["res://runtime/cache", root.path_join("home/.ailang/cache")]]:
			if not _copy_tree(pair[0], pair[1]):
				push_error("failed to unpack %s" % pair[0])
				return ""
		OS.execute("/bin/chmod", ["+x", root.path_join("runtime/bin/ailang")])
		FileAccess.open(marker, FileAccess.WRITE).store_string(version)
	return root


static func _copy_tree(src: String, dst: String) -> bool:
	DirAccess.make_dir_recursive_absolute(dst)
	var dir := DirAccess.open(src)
	if dir == null:
		return false
	for f in dir.get_files():
		var out := FileAccess.open(dst.path_join(f), FileAccess.WRITE)
		if out == null:
			return false
		out.store_buffer(FileAccess.get_file_as_bytes(src.path_join(f)))
	for d in dir.get_directories():
		if not _copy_tree(src.path_join(d), dst.path_join(d)):
			return false
	return true


func _read_state(deadline: int, timeout_code: String) -> bool:
	while Time.get_ticks_msec() < deadline:
		var end := _line_bytes.find(10)
		if end < 0:
			var chunk := _pipe.get_buffer(4096)
			if chunk.is_empty():
				if not OS.is_process_running(_pid):
					return _fail("child_eof")
				OS.delay_msec(2)
				continue
			_line_bytes.append_array(chunk)
			continue
		var line := _line_bytes.slice(0, end).get_string_from_utf8().strip_edges()
		_line_bytes = _line_bytes.slice(end + 1)
		if not line.begins_with("{"):
			continue
		var parsed = JSON.parse_string(line)
		if typeof(parsed) != TYPE_DICTIONARY:
			return _fail("bad_response")
		state = parsed
		last_line = line
		return true
	return _fail(timeout_code)

func _fail(code: String) -> bool:
	last_error = code
	if not world.is_empty():
		world["status"] = code
	_cleanup()
	return false

func _cleanup() -> void:
	if _pid < 0:
		return
	if _pipe != null and _pipe.is_open():
		_write(encode({"v": 2, "type": "quit"}))
		_pipe.close()
	if _record != null:
		_record.close()
		_record = null
	var deadline := Time.get_ticks_msec() + 1000
	while OS.is_process_running(_pid) and Time.get_ticks_msec() < deadline:
		OS.delay_msec(5)
	if OS.is_process_running(_pid):
		OS.kill(_pid)
	_pid = -1
	_game = false
