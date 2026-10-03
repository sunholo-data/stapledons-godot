class_name AiBridge
extends Node
## Runs the AI service (`ai/service.ail`, protocol ai/1) as a child process
## and relays requests to it without ever blocking the frame (design
## ai-service-foundation (a3)). It never talks to the sim: AiRelay (AI.7)
## turns the sim's `ai_request` events into `request()` calls and the
## outcomes back into intents.
##
## - Lazy start: the child is launched only when a request is queued (the
##   relay calls `request()` only on a cache miss), so a replay that needs no
##   AI leaves `launch_count` at 0.
## - Non-blocking: `poll()` (called from `_process`) reads whatever the pipe
##   holds, assembles lines across partial reads and never waits on a deadline.
## - One request in flight, picked by priority text > voice > portrait.
## - Supervision: handshake within 5 s with `proto.major == 1`; per-kind
##   timeouts (text 30 s, voice 60 s, portrait 120 s) kill the child, cancel
##   the request with `timeout` and restart lazily; a crash, a bad handshake or
##   a garbled reply restarts with backoff 1 s, 4 s, 16 s and resends the open
##   request. Every one of those is a failure; 3 failures within 10 minutes
##   disable the service for the session and cancel every queued and open
##   request with `service_down`.
## - Session spend (AI.9 hardening): the service's ledger starts from what this
##   session already spent, read from usage.ndjson (the lines written since
##   the first launch, the same source as the indicator) and passed as the
##   config's `spent`, so the player's ceiling bounds the session, not one
##   service process. A live service writes its reservation (the request's
##   worst case) to inflight.json before each call; when the bridge kills it
##   mid-call (timeout) or it dies mid-call (fault), the bridge appends that
##   provisional line to usage.ndjson, so the call is never uncounted.
##
## Outcomes are emitted on `outcome` and kept in `outcomes` (see
## `take_outcomes`): the service's `result` object as parsed (`status` "ok" or
## "error"), or `{"type": "cancel", "req", "kind", "reason"}` where reason is
## `timeout` or `service_down`.

signal outcome(o: Dictionary)
signal service_down_toast(text: String)

const SERVICE_FILE := "ai/service.ail"
const PROTO_MAJOR := 1
const TOAST_TEXT := "Live voices unavailable: using the ship's archive"
## Lower runs first; avatar is an image like portrait.
const PRIORITY := {"text": 0, "voice": 1, "portrait": 2, "avatar": 2}
const TIMEOUT_MS := {"text": 30000, "voice": 60000, "portrait": 120000, "avatar": 120000}
const BACKOFF_MS := [1000, 4000, 16000]
const HANDSHAKE_MS := 5000
const FAIL_LIMIT := 3
const FAIL_WINDOW_MS := 600000
const QUIT_GRACE_MS := 1000
const READ_CHUNK := 4096
const USAGE_FILE := "usage.ndjson"
const RESERVE_FILE := "inflight.json"
const PROVIDERS := ["gemini", "openrouter"]
const MAX_CHUNKS_PER_POLL := 16
## OS.execute_with_pipe marks no descriptor close-on-exec, so a child inherits
## every pipe Godot holds: the sim's stdin among them, and the pipes of any
## process spawned at the same moment. The service is started through this
## script, which closes every inherited descriptor above 2 and execs it (same
## pid), so the AI process cannot reach the sim and keeps nobody's pipe open.
## It runs under bash (`scrub_shell`). Under a POSIX sh such as dash, which
## reads "12>&-" as a command named 12, it closes only 3-9 and still runs the
## service.
const FD_SCRUB := 'for f in /dev/fd/*; do n=${f##*/}; case $n in [3-9]) eval "exec $n>&-" 2>/dev/null;; [1-9][0-9]*) [ -n "$BASH_VERSION" ] && eval "exec $n>&-" 2>/dev/null;; esac; done; exec "$@"'

## Live launch (design (a2) as amended by AI.5 and AI.9): the keys travel as
## key-file paths, never as text. The wrapper (run as `/bin/sh -c LIVE_WRAP
## <ailang> <gemini key file|""> <openrouter key file|""> <0|1> <home> run ...`)
## execs `env -i` with only PATH, HOME, GOOGLE_APPLICATION_CREDENTIALS=/nonexistent
## and, when allowed, AI_LIVE=1: nothing else of Godot's environment (other
## *_API_KEY variables, an inherited AI_LIVE or key) reaches the service. An
## inner sh reads each key file into its env var and execs ailang (same pid
## throughout), so `ps` shows only paths. AI_LIVE=1 passes only when
## `live_allowed` (the player's tick, AiSettings; never in automation).
const LIVE_WRAP := """g=$1; o=$2; a=$3; h=$4; shift 4; l=; [ "$a" = 1 ] && l=AI_LIVE=1; exec /usr/bin/env -i PATH="$PATH" HOME="$h" GOOGLE_APPLICATION_CREDENTIALS=/nonexistent $l /bin/sh -c 'if [ -n "$1" ]; then GOOGLE_API_KEY=$(cat "$1"); export GOOGLE_API_KEY; fi; if [ -n "$2" ]; then OPENROUTER_API_KEY=$(cat "$2"); export OPENROUTER_API_KEY; fi; shift 2; exec "$@"' sh "$g" "$o" "$0" "$@" """
const LIVE_HOSTS := "generativelanguage.googleapis.com,openrouter.ai"

enum Phase { IDLE, LAUNCHING, HANDSHAKE, READY, BUSY }

## Overridable (tests shorten them); the defaults are the design's.
var timeout_ms: Dictionary = TIMEOUT_MS.duplicate()
var backoff_ms: Array = BACKOFF_MS.duplicate()
var handshake_ms := HANDSHAKE_MS
## {"bin", "args"} replaces the stub launch (tests run the fake service).
var launch_override: Dictionary = {}
## Stub-mode service configuration (design (a2)): the cache directory and the
## key set the stub pretends to have. Live mode is `live` below.
var cache_dir := "user://ai_cache"
var stub_keys: Array = ["gemini", "openrouter"]
var text_only := false
## Live mode: {"gemini": path, "openrouter": path} (either may be absent).
## The service refuses unless a routed provider's key is non-empty and
## AI_LIVE=1, which reaches it only when `live_allowed` (never in automation).
var live := false
var key_files: Dictionary = {}
var live_allowed := false
## The player's session ceiling in US$ (0.05..20, D-20), stub and live alike.
var ceiling_usd := 0.5
## Byte offset of usage.ndjson where this session's lines begin: taken at the
## first launch (nothing of this session's is written before it); -1 before.
var usage_from := -1
## Tests: keep every stdout line the service printed (key hygiene).
var keep_lines := false
var lines_read: Array = []
## Added to the clock; tests move time forward to age the failure window.
var clock_offset_ms := 0

var launch_count := 0
var service_down := false
var hello_reply: Dictionary = {}
var last_error := ""
var outcomes: Array = []
## Request lines written to the current child, and to all children.
var sent_count := 0
var sent_total := 0
var child_pid := -1
## Tick (msec, offset clock) of each launch and each failure.
var launch_times: Array = []
var failure_times: Array = []
## Slowest poll() so far, in microseconds.
var max_poll_usec := 0

var _phase := Phase.IDLE
var _pipe: FileAccess
var _stderr: FileAccess
var _pid := -1
var _line_bytes := PackedByteArray()
var _queues: Array = [[], [], []]
var _in_flight: Dictionary = {}
var _deadline := 0
var _next_launch_at := 0
var _consecutive := 0
## Spawning and killing run on the worker pool: fork/exec and the reaping
## waitpid inside OS.kill each cost a millisecond or more on the main thread.
var _spawn_task := -1
var _spawned: Dictionary = {}
var _kill_tasks: Array = []
var stderr_tail := ""


func _process(_delta: float) -> void:
	poll()


func _exit_tree() -> void:
	shutdown()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		shutdown()


func now_msec() -> int:
	return Time.get_ticks_msec() + clock_offset_ms


## Queue one request: the sim's `ai_request` fields (`req`, `kind`, ...) plus
## whatever the relay adds (cast, segments). False if it is malformed. When
## the service is down the request is cancelled at once.
func request(r: Dictionary) -> bool:
	var req = r.get("req")
	var kind = r.get("kind")
	if typeof(req) != TYPE_STRING or req == "" or typeof(kind) != TYPE_STRING or not PRIORITY.has(kind):
		push_error("AiBridge: malformed request %s" % [r])
		return false
	if service_down:
		_cancel(r, "service_down")
		return true
	_queues[PRIORITY[kind]].append(r)
	return true


func pending() -> int:
	return _queues[0].size() + _queues[1].size() + _queues[2].size() + (0 if _in_flight.is_empty() else 1)


func in_flight() -> Dictionary:
	return _in_flight


func take_outcomes() -> Array:
	var out := outcomes
	outcomes = []
	return out


## One non-blocking step: read what the child has written, enforce deadlines,
## launch if there is work and the backoff has passed, send the next request.
func poll() -> void:
	var t0 := Time.get_ticks_usec()
	_reap()
	if _phase == Phase.LAUNCHING and WorkerThreadPool.is_task_completed(_spawn_task):
		WorkerThreadPool.wait_for_task_completion(_spawn_task)
		_spawn_task = -1
		_on_spawned(_spawned)
	if _pid >= 0:
		_drain_stderr()
		var got := _read_stdout()
		if _pid >= 0 and not got and not _alive(_pid):
			_read_stdout() # whatever it wrote just before exiting
			if _pid >= 0:
				_fault("child_eof")
		if _pid >= 0 and now_msec() >= _deadline:
			if _phase == Phase.HANDSHAKE:
				_fault("startup_timeout")
			elif _phase == Phase.BUSY:
				_timeout()
	if not service_down and _pid < 0 and _phase == Phase.IDLE and _has_queued() and now_msec() >= _next_launch_at:
		_launch()
	if _phase == Phase.READY and _has_queued():
		_send_next()
	max_poll_usec = maxi(max_poll_usec, Time.get_ticks_usec() - t0)


## `quit`, then up to 1 s grace, then kill (as SimBridge does). Blocks for at
## most the grace period; only for scene exit.
func shutdown() -> void:
	if _spawn_task >= 0:
		WorkerThreadPool.wait_for_task_completion(_spawn_task)
		_spawn_task = -1
		_on_spawned(_spawned)
	if _pid >= 0:
		if _pipe != null and _pipe.is_open():
			_write(SimBridge.encode({"v": 1, "type": "quit"}))
		var pid := _pid
		_close_pipes()
		var deadline := Time.get_ticks_msec() + QUIT_GRACE_MS
		while _alive(pid) and Time.get_ticks_msec() < deadline:
			OS.delay_msec(5)
		if _alive(pid):
			OS.kill(pid)
	for t in _kill_tasks:
		WorkerThreadPool.wait_for_task_completion(t)
	_kill_tasks.clear()


## Backoff before the launch that follows the n-th consecutive failure (n >= 1).
func backoff_delay(n: int) -> int:
	return backoff_ms[clampi(n - 1, 0, backoff_ms.size() - 1)]


## Lines completed by `chunk`, in order; a partial tail waits for the next call.
func assemble(chunk: PackedByteArray) -> PackedStringArray:
	_line_bytes.append_array(chunk)
	var lines := PackedStringArray()
	var end := _line_bytes.find(10)
	while end >= 0:
		lines.append(_line_bytes.slice(0, end).get_string_from_utf8().strip_edges())
		_line_bytes = _line_bytes.slice(end + 1)
		end = _line_bytes.find(10)
	return lines


# ------------------------------------------------------------------ launch

static func _run_args(ailang: String, ai_dir: String, config: Dictionary) -> PackedStringArray:
	# The stub needs IO and FS only: it cannot read env, reach the network or
	# call a model. Configuration is the entry argument, never argv flags;
	# `session` is the stub entry with the player's ceiling (ceiling_usd).
	return PackedStringArray([ailang, "run", "--quiet", "--bytecode", "--package-dir", ai_dir,
		"--caps", "IO,FS", "--entry", "session", "--args-json", SimBridge.encode(config),
		ai_dir.path_join(SERVICE_FILE.get_file())])


## The live launch: the wrapper, then the service with IO,FS,Env,Net,AI and the
## two hosts. std/ai is bound to the Gemini image model (AI.5 transport
## finding) only with a Gemini key, and then always with `--ai-key-file` and
## `--ai-no-adc` (AI.9): on v0.51+ gcloud Application Default Credentials in
## HOME win over GOOGLE_API_KEY, so env precedence would bill a gcloud
## project instead of the key. `--ai-no-adc` is passed in every live launch.
## `home` is HOME for ailang (its package cache): the bundled runtime's in an
## exported build, else Godot's own.
func live_plan(ailang: String, root: String, home: String = "") -> Dictionary:
	var ai_dir := root.path_join("ai")
	var models = JSON.parse_string(FileAccess.get_file_as_string(root.path_join("data/ai/models.json")))
	var image: String = models["models"]["gemini"]["image"] if models is Dictionary else "gemini-2.5-flash-image"
	var cfg := stub_config(root)
	cfg["provider"] = "live"
	cfg["keys_present"] = []
	var args := PackedStringArray(["-c", LIVE_WRAP, ailang, key_files.get("gemini", ""), key_files.get("openrouter", ""), "1" if live_allowed else "0",
		home if home != "" else OS.get_environment("HOME"), "run", "--quiet", "--bytecode", "--package-dir", ai_dir, "--caps", "IO,FS,Env,Net,AI", "--ai-no-adc"])
	if key_files.has("gemini"):
		args.append_array(["--ai", image, "--ai-key-file", key_files["gemini"]])
	args.append_array(["--net-allow-domains", LIVE_HOSTS, "--entry", "live", "--args-json", SimBridge.encode(cfg), ai_dir.path_join(SERVICE_FILE.get_file())])
	return {"bin": "/bin/sh", "args": args}


func stub_config(root: String) -> Dictionary:
	return {"provider": "stub", "keys_present": stub_keys, "text_only": text_only,
		"cache_dir": ProjectSettings.globalize_path(cache_dir),
		"routing": root.path_join("data/ai/routing.json"), "fixtures": root.path_join("ai/fixtures"), "ceiling_usd": ceiling_usd,
		"spent": spent_list()}


func usage_path() -> String:
	return ProjectSettings.globalize_path(cache_dir).path_join(USAGE_FILE)


func reserve_path() -> String:
	return ProjectSettings.globalize_path(cache_dir).path_join(RESERVE_FILE)


## This session's spend per route in nano-USD: the `usd` of every usage.ndjson
## line written since the first launch (ok, failed and provisional alike).
## Before the first launch the session has spent nothing.
func session_nusd() -> Dictionary:
	var out := {"gemini": 0, "openrouter": 0}
	var f := FileAccess.open(usage_path(), FileAccess.READ) if usage_from >= 0 else null
	if f == null:
		return out
	f.seek(usage_from)
	for line in f.get_buffer(f.get_length()).get_string_from_utf8().split("\n", false):
		var u = JSON.parse_string(line)
		if u is Dictionary and out.has(u.get("route")) and (u.get("usd") is float or u.get("usd") is int) and float(u["usd"]) >= 0.0:
			out[u["route"]] += roundi(float(u["usd"]) * 1.0e9)
	return out


func session_usd() -> Dictionary:
	var n := session_nusd()
	return {"gemini": n["gemini"] / 1.0e9, "openrouter": n["openrouter"] / 1.0e9}


## The config's `spent`: [{provider, nusd}] for the service's ledger.
func spent_list() -> Array:
	var n := session_nusd()
	return PROVIDERS.map(func(p): return {"provider": p, "nusd": n[p]})


## Source checkout: ailang from AILANG_BIN or PATH, the service from the repo.
## Exported build: the sim's bundled runtime with its own HOME, plus ai/ and
## data/ai/ unpacked beside it (the export preset includes them, AI.9).
func launch_plan() -> Dictionary:
	if not OS.has_feature("template"):
		var bin := SimBridge.find_ailang()
		if bin == "":
			push_error("ailang not found; set AILANG_BIN or add it to PATH")
			return {}
		var res := ProjectSettings.globalize_path("res://")
		if live:
			return live_plan(bin, res)
		var dev := _run_args(bin, res.path_join("ai"), stub_config(res))
		return {"bin": dev[0], "args": dev.slice(1)}
	var root := SimBridge._unpack_runtime()
	if root == "" or not _unpack_ai(root):
		return {}
	if live:
		return live_plan(root.path_join("runtime/bin/ailang"), root, root.path_join("home"))
	var args := PackedStringArray(["HOME=" + root.path_join("home")])
	args.append_array(_run_args(root.path_join("runtime/bin/ailang"), root.path_join("ai"), stub_config(root)))
	return {"bin": "/usr/bin/env", "args": args}


static func _unpack_ai(root: String) -> bool:
	if not FileAccess.file_exists("res://" + SERVICE_FILE):
		push_error("exported build has no AI service (res://%s missing)" % SERVICE_FILE)
		return false
	# The marker holds a digest of every file unpacked from ai/ and data/ai/
	# (AI.9 hardening: every module, not only service.ail), so a rebuilt export
	# with the same AILANG version never runs stale modules; the runtime's
	# package cache is re-copied for ai/'s packages (keyed by ai/ailang.lock).
	var marker := root.path_join(".ai-unpacked")
	var digest := unpack_digest()
	if FileAccess.get_file_as_string(marker) == digest:
		return true
	for pair in [["res://ai", root.path_join("ai")], ["res://data/ai", root.path_join("data/ai")], ["res://runtime/cache", root.path_join("home/.ailang/cache")]]:
		if not SimBridge._copy_tree(pair[0], pair[1]):
			push_error("failed to unpack %s" % pair[0])
			return false
	FileAccess.open(marker, FileAccess.WRITE).store_string(digest)
	return true


## Every file _unpack_ai copies from ai/ and data/ai/ (as SimBridge._copy_tree
## walks them), sorted: the input of the unpack digest.
static func unpack_files() -> PackedStringArray:
	var out := PackedStringArray()
	for d in ["res://ai", "res://data/ai"]:
		_list_tree(d, out)
	out.sort()
	return out


static func _list_tree(dir: String, out: PackedStringArray) -> void:
	var da := DirAccess.open(dir)
	if da == null:
		return
	for f in da.get_files():
		out.append(dir.path_join(f))
	for d in da.get_directories():
		_list_tree(dir.path_join(d), out)


static func unpack_digest() -> String:
	var h := HashingContext.new()
	h.start(HashingContext.HASH_SHA256)
	for f in unpack_files():
		h.update((f + "\n").to_utf8_buffer())
		h.update(FileAccess.get_file_as_bytes(f))
	return h.finish().hex_encode()


func _launch() -> void:
	if usage_from < 0:
		var f := FileAccess.open(usage_path(), FileAccess.READ)
		usage_from = f.get_length() if f != null else 0
	var plan := launch_override if not launch_override.is_empty() else launch_plan()
	launch_count += 1
	launch_times.append(now_msec())
	if plan.is_empty():
		_failure("no_launch")
		return
	_phase = Phase.LAUNCHING
	_spawned = {}
	var argv := scrubbed(plan)
	var shell := scrub_shell()
	_spawn_task = WorkerThreadPool.add_task(func(): _spawned = OS.execute_with_pipe(shell, argv, false))


## bash where it exists (macOS and Ubuntu both ship /bin/bash), else /bin/sh.
static func scrub_shell() -> String:
	return "/bin/bash" if FileAccess.file_exists("/bin/bash") else "/bin/sh"


## The arguments for the scrub shell that run `plan` with only stdin, stdout, stderr.
static func scrubbed(plan: Dictionary) -> PackedStringArray:
	var argv := PackedStringArray(["-c", FD_SCRUB, "sh", plan["bin"]])
	argv.append_array(plan["args"])
	return argv


func _on_spawned(proc: Dictionary) -> void:
	_phase = Phase.IDLE
	if proc.is_empty():
		_failure("no_launch")
		return
	_pipe = proc["stdio"]
	_stderr = proc["stderr"]
	_pid = proc["pid"]
	child_pid = _pid
	_line_bytes = PackedByteArray()
	sent_count = 0
	hello_reply = {}
	_phase = Phase.HANDSHAKE
	_deadline = now_msec() + handshake_ms
	_write(SimBridge.encode({"v": 1, "type": "hello", "want": {"major": PROTO_MAJOR}}))


# ------------------------------------------------------------------ relay

func _has_queued() -> bool:
	return not (_queues[0].is_empty() and _queues[1].is_empty() and _queues[2].is_empty())


func _send_next() -> void:
	for q in _queues:
		if not q.is_empty():
			_in_flight = q.pop_front()
			break
	var msg := {"v": 1, "type": "request"}
	for k in _in_flight:
		if k != "v" and k != "type":
			msg[k] = _in_flight[k]
	_phase = Phase.BUSY
	_deadline = now_msec() + int(timeout_ms[_in_flight["kind"]])
	DirAccess.remove_absolute(reserve_path()) # a reservation now is this request's
	sent_count += 1
	sent_total += 1
	_write(SimBridge.encode(msg))


## The service treats a blank line as end of input, so none is ever sent.
func _write(line: String) -> void:
	if line.strip_edges() == "" or line.find("\n") >= 0:
		push_error("AiBridge: refusing to send a blank or multi-line message")
		return
	if _pipe == null or not _pipe.is_open():
		return
	_pipe.store_string(line + "\n")
	_pipe.flush()


func _read_stdout() -> bool:
	var got := false
	for i in MAX_CHUNKS_PER_POLL:
		if _pid < 0:
			break
		var chunk := _pipe.get_buffer(READ_CHUNK)
		if chunk.is_empty():
			break
		got = true
		for line in assemble(chunk):
			if _pid < 0:
				break
			if keep_lines:
				lines_read.append(line)
			_on_line(line)
	return got


func _drain_stderr() -> void:
	for i in MAX_CHUNKS_PER_POLL:
		var chunk := _stderr.get_buffer(READ_CHUNK)
		if chunk.is_empty():
			return
		stderr_tail = (stderr_tail + chunk.get_string_from_utf8()).right(2048)


func _on_line(line: String) -> void:
	if not line.begins_with("{"):
		return # stray output; the service's messages are JSON objects
	var json := JSON.new()
	var msg = json.data if json.parse(line) == OK else null
	if typeof(msg) != TYPE_DICTIONARY:
		_fault("bad_response")
		return
	match _phase:
		Phase.HANDSHAKE:
			var proto = msg.get("proto")
			if msg.get("type") == "hello" and typeof(proto) == TYPE_DICTIONARY \
					and SimBridge._is_count(proto.get("major")) and int(proto["major"]) == PROTO_MAJOR:
				hello_reply = msg
				_phase = Phase.READY
			else:
				_fault("fatal" if msg.get("type") == "fatal" else "bad_proto")
		Phase.BUSY:
			if msg.get("type") == "result" and msg.get("req") == _in_flight["req"] \
					and (msg.get("status") == "ok" or msg.get("status") == "error"):
				_in_flight = {}
				_phase = Phase.READY
				_consecutive = 0
				_emit(msg)
			else:
				_fault("bad_response")
		_:
			_fault("bad_response") # nothing was asked


# ------------------------------------------------------------------ supervision

## Per-kind timeout: kill, cancel the request, restart when the next one comes.
func _timeout() -> void:
	var r := _in_flight
	_in_flight = {}
	_kill()
	_charge_interrupted(r)
	_cancel(r, "timeout")
	_failure("timeout", false)


## Crash, bad handshake or garbled reply: kill, keep the open request (it is
## resent first after the restart), restart after the backoff.
func _fault(code: String) -> void:
	var r := _in_flight
	if not _in_flight.is_empty():
		_queues[PRIORITY[_in_flight["kind"]]].push_front(_in_flight)
		_in_flight = {}
	_kill()
	_charge_interrupted(r)
	_failure(code)


## A request killed (or lost with its process) mid-call may have been billed:
## if the service reserved it (inflight.json names this request), append that
## provisional line, its worst case, to usage.ndjson.
func _charge_interrupted(r: Dictionary) -> void:
	if r.is_empty() or not FileAccess.file_exists(reserve_path()):
		return
	var line := FileAccess.get_file_as_string(reserve_path()).strip_edges()
	DirAccess.remove_absolute(reserve_path())
	var u = JSON.parse_string(line) if line.begins_with("{") and line.find("\n") < 0 else null
	if not (u is Dictionary and u.get("req") == r.get("req") and u.get("provisional") == true):
		return
	var f := FileAccess.open(usage_path(), FileAccess.READ_WRITE if FileAccess.file_exists(usage_path()) else FileAccess.WRITE)
	if f != null:
		f.seek_end()
		f.store_string(line + "\n")


func _failure(code: String, backoff: bool = true) -> void:
	last_error = code
	var now := now_msec()
	failure_times.append(now)
	var recent := 0
	for t in failure_times:
		if now - t < FAIL_WINDOW_MS:
			recent += 1
	_consecutive += 1
	if recent >= FAIL_LIMIT:
		_go_down()
	else:
		_next_launch_at = now + (backoff_delay(_consecutive) if backoff else 0)


func _go_down() -> void:
	service_down = true
	_kill()
	if not _in_flight.is_empty():
		_cancel(_in_flight, "service_down")
		_in_flight = {}
	for q in _queues:
		for r in q:
			_cancel(r, "service_down")
		q.clear()
	service_down_toast.emit(TOAST_TEXT)


func _cancel(r: Dictionary, reason: String) -> void:
	_emit({"type": "cancel", "req": r["req"], "kind": r["kind"], "reason": reason})


func _emit(o: Dictionary) -> void:
	outcomes.append(o)
	outcome.emit(o)


## Kill without waiting: OS.kill reaps (a blocking waitpid), so it runs on
## the worker pool.
func _kill() -> void:
	if _pid < 0:
		return
	var pid := _pid
	_close_pipes()
	if _alive(pid):
		_kill_tasks.append(WorkerThreadPool.add_task(func(): OS.kill(pid)))


func _close_pipes() -> void:
	if _pipe != null and _pipe.is_open():
		_pipe.close()
	if _stderr != null and _stderr.is_open():
		_stderr.close()
	_pipe = null
	_stderr = null
	_pid = -1
	_phase = Phase.IDLE


func _reap() -> void:
	var busy: Array = []
	for t in _kill_tasks:
		if WorkerThreadPool.is_task_completed(t):
			WorkerThreadPool.wait_for_task_completion(t)
		else:
			busy.append(t)
	_kill_tasks = busy


## OS.is_process_running reaps an exited child, and asking again about a
## reaped pid is an error, so the answer "gone" is remembered.
var _gone: Dictionary = {}
func _alive(pid: int) -> bool:
	if _gone.has(pid):
		return false
	if OS.is_process_running(pid):
		return true
	_gone[pid] = true
	return false
