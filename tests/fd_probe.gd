class_name FdProbe
extends RefCounted
## Test helper: what a child process holds open beyond stdin, stdout and
## stderr. Godot's OS.execute_with_pipe marks no descriptor close-on-exec, so
## AiBridge and SimBridge start their children through AiBridge.FD_SCRUB; the
## bridge tests use this to prove no inherited pipe survives.


## "type name" of each descriptor above 2 a process holds (lsof on macOS,
## `ls -l /proc/<pid>/fd` on Linux).
static func extra_fds(pid: int) -> Array:
	var out := []
	var fds := []
	if DirAccess.dir_exists_absolute("/proc/%d/fd" % pid):
		OS.execute("/bin/ls", PackedStringArray(["-l", "/proc/%d/fd" % pid]), out)
		for line in str(out[0]).split("\n"):
			var parts := line.split(" -> ")
			if parts.size() == 2 and int(parts[0].get_slice(" ", parts[0].get_slice_count(" ") - 1)) > 2:
				fds.append(("PIPE " if parts[1].begins_with("pipe:") else "") + parts[1])
		return fds
	OS.execute("/usr/sbin/lsof", PackedStringArray(["-n", "-P", "-a", "-p", str(pid), "-F", "ftn"]), out)
	var fd := -1
	var type := ""
	for line in str(out[0]).split("\n"):
		if line.begins_with("f"):
			fd = int(line.substr(1)) if line.substr(1).is_valid_int() else -1
		elif line.begins_with("t"):
			type = line.substr(1)
		elif line.begins_with("n") and fd > 2:
			fds.append(type + " " + line.substr(1))
	return fds
