class_name SimBridge
extends RefCounted
## Runs the AILANG simulation as a child process and talks NDJSON over its
## stdin/stdout: one request line in, one state line out per tick.
## The world state lives in AILANG; Godot only sends inputs and reads state.

const SIM_FILE := "sim/ship.ail"

var _pipe: FileAccess
var _stderr: FileAccess
var _pid := -1
var state: Dictionary = {}
var last_error := ""
var child_pid := -1
var launch_override: Dictionary = {}
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


func start() -> bool:
	var launch := launch_override if not launch_override.is_empty() else _launch_plan()
	if launch.is_empty():
		return false
	var started := Time.get_ticks_msec()
	var proc := OS.execute_with_pipe(launch["bin"], launch["args"], false)
	if proc.is_empty():
		push_error("failed to start %s" % launch["bin"])
		return false
	_pipe = proc["stdio"]
	_stderr = proc["stderr"]
	_pid = proc["pid"]
	child_pid = _pid
	if not _read_state(started + 5000, "startup_timeout"):
		return false
	_pipe.store_line('{"cmd":"hello"}')
	_pipe.flush()
	if not _read_state(started + 5000, "startup_timeout"):
		return false
	if str(state.get("proto", "")).to_float() < 1.1:
		return _fail("bad_proto")
	return true


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


func step(thrust: float, dtau: float, heading: Dictionary = {}) -> bool:
	if _pid < 0:
		return false
	var before := state.duplicate(true)
	var request := {"cmd": "step", "thrust": thrust, "dtau": dtau}
	if not heading.is_empty():
		request["heading"] = heading
	_pipe.store_line(JSON.stringify(request))
	_pipe.flush()
	if not _read_state(Time.get_ticks_msec() + 2000, "step_timeout"):
		return false
	if state.get("status") == "ok" and state.get("tick") != before.get("tick", -1) + 1:
		state = before
		return _fail("bad_response")
	return true


func stop() -> void:
	if _pid < 0:
		return
	_cleanup()


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
		return true
	return _fail(timeout_code)

func _fail(code: String) -> bool:
	last_error = code
	if not state.is_empty():
		state["status"] = code
	_cleanup()
	return false

func _cleanup() -> void:
	if _pid < 0:
		return
	if _pipe != null and _pipe.is_open():
		_pipe.store_line('{"cmd":"quit"}')
		_pipe.flush()
		_pipe.close()
	var deadline := Time.get_ticks_msec() + 1000
	while OS.is_process_running(_pid) and Time.get_ticks_msec() < deadline:
		OS.delay_msec(5)
	if OS.is_process_running(_pid):
		OS.kill(_pid)
	_pid = -1
