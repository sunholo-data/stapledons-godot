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
	var bin := find_ailang()
	if bin == "":
		push_error("ailang not found; set AILANG_BIN or add it to PATH")
		return false
	var sim := ProjectSettings.globalize_path("res://" + SIM_FILE)
	var pkg := sim.get_base_dir() # holds ailang.toml; lets module paths resolve from any cwd
	var args := PackedStringArray(["run", "--quiet", "--bytecode", "--package-dir", pkg, "--caps", "IO", "--entry", "main", sim])
	var proc := OS.execute_with_pipe(bin, args)
	if proc.is_empty():
		push_error("failed to start %s" % bin)
		return false
	_pipe = proc["stdio"]
	_stderr = proc["stderr"]
	_pid = proc["pid"]
	return _read_state() # the sim reports its initial state on startup


func step(thrust: float, dtau: float) -> bool:
	_pipe.store_line(JSON.stringify({"cmd": "step", "thrust": thrust, "dtau": dtau}))
	_pipe.flush()
	return _read_state()


func stop() -> void:
	if _pid < 0:
		return
	_pipe.store_line(JSON.stringify({"cmd": "quit"}))
	_pipe.flush()
	_pipe.close()
	_pid = -1


func _read_state() -> bool:
	# Protocol lines are JSON objects; skip anything else the toolchain prints.
	var line := _pipe.get_line()
	var guard := 0
	while not line.begins_with("{") and guard < 100 and _pipe.is_open():
		line = _pipe.get_line()
		guard += 1
	var parsed = JSON.parse_string(line)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("sim returned %s; stderr: %s" % [line, _stderr.get_as_text()])
		return false
	state = parsed
	return true
