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
	var launch := _launch_plan()
	if launch.is_empty():
		return false
	var proc := OS.execute_with_pipe(launch["bin"], launch["args"])
	if proc.is_empty():
		push_error("failed to start %s" % launch["bin"])
		return false
	_pipe = proc["stdio"]
	_stderr = proc["stderr"]
	_pid = proc["pid"]
	return _read_state() # the sim reports its initial state on startup


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
