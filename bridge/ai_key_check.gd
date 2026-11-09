class_name AiKeyCheck
extends RefCounted
## R3-AI-PANEL-V2 P1 (design ai-panel-v2 §V3): the panel's **Test** button.
## Runs ai/check.ail once per press, as its own short-lived process (it works
## from the title screen, with no session): one free GET to the provider,
## one line back, `ok`, `rejected`, `offline` or `no_key`. The key reaches the
## child as its 0600 file path, never on the command line; the child runs
## under `env -i` with Application Default Credentials disabled, and only the
## provider hosts are reachable. No usage line is written: the check is free
## and never counts against the session ceiling. Automation runs never check.
## Results live in memory for this run only (design OQ2): a remembered
## "working" from last week could be stale after a key is revoked.
## The owner calls `poll()` each frame; `done(provider, status)` follows.

signal done(provider: String, status: String)

const TIMEOUT_MS := 10000
const STATUSES := ["ok", "rejected", "offline", "no_key"]
const READ_CHUNK := 4096
## The child prints one short line; anything past this is noise and is dropped.
const MAX_OUT := 4096

var timeout_ms := TIMEOUT_MS
## Tests: {"bin", "args"} replaces the real plan; `base` points the real check
## at a local server (then only localhost over http is reachable).
var plan_override: Dictionary = {}
var base := ""
## provider -> status of the last finished check this run, and the fingerprint
## of the key it checked: a result only counts while that key is still the key
## (a key replaced or removed mid-check never inherits the old key's answer).
var results: Dictionary = {}
var result_keys: Dictionary = {}
var _started_keys: Dictionary = {}
## provider -> WorkerThreadPool task id while a check runs.
var running: Dictionary = {}
## provider -> the child's last stdout (one status line; never key text, which
## the check never prints). Tests read it to tell a real "offline" from a crash.
var last_out: Dictionary = {}
var _finished: Array = []
var _mutex := Mutex.new()


## The process for one check, or {} (an unknown provider, no key file).
static func plan(provider: String, key_file: String, ailang: String, root: String, home: String, base_url: String = "") -> Dictionary:
	if not provider in AiSettings.PROVIDERS or key_file == "" or ailang == "":
		return {}
	var cfg := {"provider": provider, "key_file": key_file, "base": base_url}
	var args := PackedStringArray(["-i", "PATH=" + OS.get_environment("PATH"), "HOME=" + home,
		"GOOGLE_APPLICATION_CREDENTIALS=/nonexistent", ailang, "run", "--quiet", "--bytecode",
		"--package-dir", root.path_join("ai"), "--caps", "IO,FS,Net"])
	if base_url == "":
		args.append_array(["--net-allow-domains", AiBridge.LIVE_HOSTS])
	else:
		args.append_array(["--net-allow-localhost", "--net-allow-http"])
	args.append_array(["--entry", "check", "--args-json", SimBridge.encode(cfg), root.path_join("ai/check.ail")])
	return {"bin": "/usr/bin/env", "args": args}


## The status in the child's stdout: its last JSON line, for this provider
## and a known status; anything else (no line, a crash, noise) is offline.
static func parse(provider: String, out: String) -> String:
	var lines := out.strip_edges().split("\n", false)
	if lines.is_empty():
		return "offline"
	var j = JSON.parse_string(lines[-1])
	if j is Dictionary and j.get("check") == provider and j.get("status") in STATUSES:
		return j["status"]
	return "offline"


## What the panel's lamp shows: none (no key), saved (not checked this run),
## checking, or the last result. A removed key forgets its result.
func status(provider: String, s: AiSettings) -> String:
	if s.key_source(provider) == "":
		results.erase(provider)
		return "none"
	if running.has(provider):
		return "checking"
	var r := result(provider, s)
	return r if r != "" else "saved"


## The last result for the key `s` holds now, or "" (none, or it was for another key).
func result(provider: String, s: AiSettings) -> String:
	if not results.has(provider) or result_keys.get(provider, "") != s.key_fingerprint(provider):
		return ""
	return results[provider]


## Tests and the review capture: a result for the current key, as a check would leave it.
func set_result(provider: String, st: String, s: AiSettings) -> void:
	results[provider] = st
	result_keys[provider] = s.key_fingerprint(provider)


## Start a check; false when one is running, there is no key, or this is an
## automation run.
func start(provider: String, s: AiSettings) -> bool:
	if s.automation or running.has(provider) or not provider in s.keys_present():
		return false
	var p := plan_override
	if p.is_empty():
		p = _real_plan(provider, s)
	if p.is_empty():
		return false
	_started_keys[provider] = s.key_fingerprint(provider)
	var argv := AiBridge.scrubbed(p)
	var shell := AiBridge.scrub_shell()
	var limit := timeout_ms
	running[provider] = WorkerThreadPool.add_task(func(): _run(provider, shell, argv, limit))
	return true


func _real_plan(provider: String, s: AiSettings) -> Dictionary:
	var key_file: String = s.key_files().get(provider, "")
	if not OS.has_feature("template"):
		return plan(provider, key_file, SimBridge.find_ailang(), ProjectSettings.globalize_path("res://"), OS.get_environment("HOME"), base)
	var root := SimBridge._unpack_runtime()
	if root == "" or not AiBridge._unpack_ai(root):
		return {}
	return plan(provider, key_file, root.path_join("runtime/bin/ailang"), root, root.path_join("home"), base)


## On a worker thread: run the child, read stdout until it exits or the
## deadline passes (then kill it: offline).
func _run(provider: String, shell: String, argv: PackedStringArray, limit: int) -> void:
	var proc := OS.execute_with_pipe(shell, argv, false)
	if proc.is_empty():
		_finish(provider, "offline")
		return
	var pipe: FileAccess = proc["stdio"]
	var err: FileAccess = proc["stderr"]
	var pid: int = proc["pid"]
	var out := PackedByteArray()
	var deadline := Time.get_ticks_msec() + limit
	var status := ""
	while true:
		var chunk := pipe.get_buffer(READ_CHUNK)
		if out.size() < MAX_OUT:
			out.append_array(chunk)
		err.get_buffer(READ_CHUNK) # drained and dropped: it never reaches a log
		if chunk.is_empty() and not OS.is_process_running(pid):
			if out.size() < MAX_OUT:
				out.append_array(pipe.get_buffer(READ_CHUNK))
			break
		if Time.get_ticks_msec() > deadline:
			OS.kill(pid)
			status = "offline"
			break
		if chunk.is_empty():
			OS.delay_msec(20)
	pipe.close()
	err.close()
	var text := out.get_string_from_utf8()
	_finish(provider, status if status != "" else parse(provider, text), text)


func _finish(provider: String, status: String, text: String = "") -> void:
	_mutex.lock()
	_finished.append([provider, status, text])
	_mutex.unlock()


## Main thread, each frame: collect finished checks.
func poll() -> void:
	if running.is_empty():
		return
	_mutex.lock()
	var got := _finished.duplicate()
	_finished.clear()
	_mutex.unlock()
	for f in got:
		var provider: String = f[0]
		if running.has(provider):
			WorkerThreadPool.wait_for_task_completion(running[provider])
			running.erase(provider)
		results[provider] = f[1]
		result_keys[provider] = _started_keys.get(provider, "")
		last_out[provider] = f[2]
		done.emit(provider, f[1])
