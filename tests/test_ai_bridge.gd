extends SceneTree
## AiBridge (sprint R1-AI-FOUNDATION AI.6, design ai-service-foundation (a3)):
## lazy launch, non-blocking relay, priority, supervision. The happy path runs
## the real stub service (`--caps IO,FS`: no network, no key); `--faults`
## adds the fake service (ai/tools/fake_service.ail) hanging, crashing,
## printing garbage or half lines, answering late or with the wrong major.
## Timeouts and backoffs are shortened here; their defaults are asserted.
## Run:  godot --headless --path . --script tests/test_ai_bridge.gd -- --faults

const FRAME_BUDGET_USEC := 2000

var failures := 0
var scratch := ProjectSettings.globalize_path("res://.godot/tmp/ai_bridge")
var poll_usecs: Array = []
## The same timing around a control step that shares no code with AiBridge
## but makes the same kind of system calls as a poll (a non-blocking read, a
## process probe of a live child, a stat), in the same loop: the machine's
## own jitter, the baseline for a busy machine.
var ctrl_usecs: Array = []
var ctrl_box := {}
var ctrl_file: FileAccess
var ctrl_pid := -1
var bridges: Array = []


func assert_bool(name: String, ok: bool) -> void:
	if not ok: failures += 1
	print("  %s  %s" % ["ok  " if ok else "FAIL", name])


func child_gone(pid: int) -> bool:
	return pid > 0 and OS.execute("/bin/kill", PackedStringArray(["-0", str(pid)]), []) != 0


func stub_bridge() -> AiBridge:
	var b := AiBridge.new()
	b.cache_dir = scratch.path_join("cache")
	bridges.append(b)
	return b


func fake(mode: String, n: int = 0) -> AiBridge:
	var b := AiBridge.new()
	var res := ProjectSettings.globalize_path("res://")
	b.launch_override = {"bin": SimBridge.find_ailang(), "args": PackedStringArray(["run", "--quiet", "--bytecode",
		"--package-dir", res.path_join("ai"), "--caps", "IO", "--entry", "main",
		"--args-json", JSON.stringify({"mode": mode, "n": n}), res.path_join("ai/tools/fake_service.ail")])}
	b.timeout_ms = {"text": 300, "voice": 600, "portrait": 1200, "avatar": 1200}
	b.backoff_ms = [150, 600, 2400]
	bridges.append(b)
	return b


func req(id: String, kind: String) -> Dictionary:
	return {"req": id, "kind": kind}


## Poll as frames would, until `cond` holds or `ms` pass. Every poll is timed.
func pump(b: AiBridge, ms: int, cond: Callable = func(): return false) -> bool:
	var end := Time.get_ticks_msec() + ms
	while Time.get_ticks_msec() < end:
		var t0 := Time.get_ticks_usec()
		b.poll()
		poll_usecs.append(Time.get_ticks_usec() - t0)
		t0 = Time.get_ticks_usec()
		ctrl_box["r"] = ctrl_file.get_buffer(4096)
		ctrl_box["p"] = OS.is_process_running(ctrl_pid)
		ctrl_box["x"] = FileAccess.file_exists(scratch)
		ctrl_usecs.append(Time.get_ticks_usec() - t0)
		if cond.call():
			return true
		OS.delay_msec(1)
	return cond.call()


## 1-minute load average per core, read outside any timed poll.
func load_per_core() -> float:
	var out := []
	if OS.get_name() == "macOS":
		OS.execute("/usr/sbin/sysctl", PackedStringArray(["-n", "vm.loadavg"]), out)
		var parts := str(out[0]).replace("{", "").strip_edges().split(" ", false)
		return float(parts[0]) / OS.get_processor_count()
	return float(FileAccess.get_file_as_string("/proc/loadavg").split(" ")[0]) / OS.get_processor_count()


## Frame never blocked: every poll since the last check returned within 2 ms.
## A poll that waited on the child would sit for a whole timeout (300 ms or
## more here); the child's spawn and reaping run on the worker pool. On a
## busy machine (1-minute load above 0.25 per core) preemption alone breaks
## 2 ms now and then (on the Studio at 3.6 per core a bare
## OS.is_process_running took 4.8 ms), so there the polls are compared with
## control steps timed in the same loop (the same syscall mix: read, process
## probe, stat): no more polls may reach 5 ms than control samples did, plus
## max(4, n/100), and none may reach 50 ms. Intermittent blocking (10 ms in
## 1 poll of 25, 30 ms in 1 of 40) fails that; test_static also proves no
## blocking call is reachable.
const SLOW_USEC := 5000
func frame_check(label: String) -> void:
	var xs := poll_usecs.duplicate()
	var cs := ctrl_usecs.duplicate()
	poll_usecs = []
	ctrl_usecs = []
	xs.sort()
	var n := xs.size()
	var worst: int = xs[n - 1] if n > 0 else 0
	var p99: int = xs[int(0.99 * (n - 1))] if n > 0 else 0
	var over := xs.filter(func(x): return x >= FRAME_BUDGET_USEC).size()
	var slow := xs.filter(func(x): return x >= SLOW_USEC).size()
	var ctrl_slow := cs.filter(func(x): return x >= SLOW_USEC).size()
	var allowed := ctrl_slow + maxi(4, n / 100)
	var lpc := load_per_core()
	var detail := "%d polls, worst %d us, p99 %d us, %d over 2 ms, %d over 5 ms vs control %d, load %.1f/core" % [n, worst, p99, over, slow, ctrl_slow, lpc]
	if lpc <= 0.25:
		assert_bool("%s: frame never blocked, every poll < 2 ms (%s)" % [label, detail], n > 0 and worst < FRAME_BUDGET_USEC)
	else:
		assert_bool("%s: frame never blocked, busy machine: over 5 ms <= control + %d, none >= 50 ms (%s)" % [label, allowed - ctrl_slow, detail], n > 0 and slow <= allowed and worst < 50000)


## Source lines of each function in bridge/ai_bridge.gd, by name.
func functions_of(src: String) -> Dictionary:
	var out := {}
	var name := ""
	for line in src.split("\n"):
		if line.begins_with("func ") or line.begins_with("static func "):
			name = line.get_slice("func ", 1).get_slice("(", 0)
			out[name] = []
		elif not line.begins_with("\t") and line.strip_edges() != "" and not line.begins_with("#"):
			name = ""
		elif name != "":
			out[name].append(line)
	return out


func reasons(b: AiBridge) -> Array:
	var out := []
	for o in b.outcomes:
		out.append("%s:%s" % [o["req"], o.get("reason", o.get("status"))])
	return out


func stub_requests() -> Dictionary:
	var by_req := {}
	for line in FileAccess.get_file_as_string("res://tests/ai/requests.ndjson").split("\n"):
		var m = JSON.parse_string(line) if line.begins_with("{") else null
		if m is Dictionary and m.get("type") == "request":
			m.erase("v")
			m.erase("type")
			by_req[m["req"]] = m
	return by_req


# ---------------------------------------------------------------- always

func test_static() -> bool:
	print("launch arguments and isolation")
	var args := AiBridge._run_args("/x/ailang", "/repo/ai", stub_bridge().stub_config("/repo"))
	var s := " ".join(args)
	assert_bool("stub runs --caps IO,FS only", args[args.find("--caps") + 1] == "IO,FS")
	assert_bool("runs ai/service.ail from --package-dir ai", args[-1] == "/repo/ai/service.ail" and args[args.find("--package-dir") + 1] == "/repo/ai")
	assert_bool("config is the entry argument, provider stub", JSON.parse_string(args[args.find("--args-json") + 1]).get("provider") == "stub")
	assert_bool("launch argv never names the sim", s.find("sim/") < 0 and s.find("ship.ail") < 0)
	var src := FileAccess.get_file_as_string("res://bridge/ai_bridge.gd")
	assert_bool("AiBridge never creates or drives a SimBridge", src.find("SimBridge.new") < 0 and src.find(".send(") < 0 and src.find("new_game") < 0)
	var b := stub_bridge()
	assert_bool("design defaults: text 30 s, voice 60 s, portrait 120 s", b.timeout_ms["text"] == 30000 and b.timeout_ms["voice"] == 60000 and b.timeout_ms["portrait"] == 120000)
	assert_bool("design defaults: handshake 5 s, 3 failures in 10 min, 1 s grace", b.handshake_ms == 5000 and AiBridge.FAIL_LIMIT == 3 and AiBridge.FAIL_WINDOW_MS == 600000 and AiBridge.QUIT_GRACE_MS == 1000)
	assert_bool("backoff 1 s, 4 s, 16 s, then 16 s", [b.backoff_delay(1), b.backoff_delay(2), b.backoff_delay(3), b.backoff_delay(4)] == [1000, 4000, 16000, 16000])
	assert_bool("malformed requests refused", not b.request({"req": "", "kind": "text"}) and not b.request({"req": "1", "kind": "song"}) and not b.request({"kind": "text"}))
	# Structural half of "frame never blocked": outside shutdown() (scene exit)
	# no function may sleep or run a process synchronously; spawning and killing
	# happen only inside a worker-pool task; a task is waited on only once
	# is_task_completed said it is done.
	var bad := []
	var fns := functions_of(src)
	for fname in fns:
		if fname == "shutdown":
			continue
		var body: Array = fns[fname]
		for i in body.size():
			var l: String = body[i]
			if l.strip_edges().begins_with("#"):
				continue
			for tok in ["delay_msec", "delay_usec", "OS.execute(", "OS.call(", "await "]:
				if l.find(tok) >= 0:
					bad.append("%s: %s" % [fname, l.strip_edges()])
			if (l.find("OS.kill(") >= 0 or l.find("execute_with_pipe(") >= 0) and l.find("add_task(") < 0:
				bad.append("%s: %s" % [fname, l.strip_edges()])
			if l.find("wait_for_task_completion") >= 0 and not ((i > 0 and body[i - 1].find("is_task_completed") >= 0) or (i > 1 and body[i - 2].find("is_task_completed") >= 0)):
				bad.append("%s: %s" % [fname, l.strip_edges()])
	assert_bool("no blocking call reachable outside shutdown(): %s" % [bad], bad.is_empty() and fns.has("poll") and fns.has("_launch"))
	test_scrub()
	return true


## FD_SCRUB under the shell AiBridge picks, and under dash (Ubuntu's /bin/sh)
## when present: the target still runs with stdin/stdout/stderr, and the
## inherited descriptors 5, 12 and 13 are closed (dash can close only 3-9; it
## must still run the target, never misparse "12>&-").
func test_scrub() -> void:
	var shells := [AiBridge.scrub_shell()]
	if FileAccess.file_exists("/bin/dash") and AiBridge.scrub_shell() != "/bin/dash":
		shells.append("/bin/dash")
	# OS.execute with output goes through a shell command line, so the scripts
	# travel as files and only plain paths are arguments.
	var script := scratch.path_join("fd_scrub.txt")
	var driver := scratch.path_join("fd_scrub_driver.sh")
	FileAccess.open(script, FileAccess.WRITE).store_string(AiBridge.FD_SCRUB)
	FileAccess.open(driver, FileAccess.WRITE).store_string('exec 5</dev/null 12</dev/null 13</dev/null; exec "$1" -c "$(cat "$2")" sh /bin/ls /dev/fd\n')
	for sh in shells:
		var out := []
		var rc := OS.execute("/bin/bash", PackedStringArray([driver, sh, script]), out, true)
		var fds := []
		for x in str(out[0]).split("\n", false):
			if x.strip_edges().is_valid_int():
				fds.append(int(x))
		var closed: Array = [5, 12, 13] if sh == AiBridge.scrub_shell() else [5]
		assert_bool("FD_SCRUB under %s: target ran (rc %d) with 0-2 open, %s closed: %s" % [sh, rc, closed, fds],
			rc == 0 and fds.has(0) and fds.has(1) and fds.has(2) and closed.all(func(fd): return not fds.has(fd)))


func test_assemble() -> bool:
	print("line assembly across partial reads")
	var b := stub_bridge()
	var got := PackedStringArray()
	for piece in ['{"a":', '1}\n{"b"', ':"caf', 'é"}\r\n', '{"c":3}\n{"d"']:
		got.append_array(b.assemble(piece.to_utf8_buffer()))
	assert_bool("three lines from five chunks; tail kept", got == PackedStringArray(['{"a":1}', '{"b":"café"}', '{"c":3}']))
	var e := "é".to_utf8_buffer() # split a code point across two reads
	got = b.assemble(PackedByteArray([0x3a, 0x22, e[0]]))
	got.append_array(b.assemble(PackedByteArray([e[1], 0x22, 0x7d, 10])))
	assert_bool("a code point split across reads survives", got == PackedStringArray(['{"d":"é"}']))
	return true


func test_stub_session() -> bool:
	print("stub service: lazy launch, handshake, priority, one in flight")
	var b := stub_bridge()
	pump(b, 100)
	assert_bool("nothing queued: no launch", b.launch_count == 0 and b.child_pid == -1)
	var rs := stub_requests()
	# The sim runs beside it, as in the game: Godot holds the sim's pipes, and a
	# child that kept inherited descriptors would hold them too (and could write
	# to the sim's stdin).
	var sim := SimBridge.new()
	assert_bool("the sim is running beside the service", sim.start())
	var t0 := Time.get_ticks_msec()
	for id in ["9", "12", "1"]: # portrait, voice, text: queued before the child exists
		b.request(rs[id])
	assert_bool("handshake within 5 s, proto.major 1", pump(b, 5000, func(): return not b.hello_reply.is_empty()) and b.hello_reply["proto"]["major"] == 1)
	print("    handshake %d ms" % (Time.get_ticks_msec() - t0))
	var fds := FdProbe.extra_fds(b.child_pid)
	assert_bool("the service inherits no pipe of Godot's (the sim's included): %s" % [fds], fds.all(func(f): return not f.begins_with("PIPE")))
	sim.stop()
	var max_open := [0]
	pump(b, 10000, func():
		max_open[0] = maxi(max_open[0], b.sent_count - b.outcomes.size())
		return b.outcomes.size() == 3)
	var order := []
	for o in b.outcomes:
		order.append(rs[o["req"]]["kind"])
	assert_bool("three results, text > voice > portrait: %s %s" % [order, reasons(b)], order == ["text", "voice", "portrait"])
	assert_bool("every outcome is the service's own result for its req", b.outcomes.all(func(o): return o["type"] == "result" and o["status"] in ["ok", "error"]))
	assert_bool("one request in flight at a time", max_open[0] == 1)
	assert_bool("one launch for the session", b.launch_count == 1)
	var pid := b.child_pid
	var t := Time.get_ticks_msec()
	b.shutdown()
	var dt := Time.get_ticks_msec() - t
	pump(b, 500, func(): return child_gone(pid))
	assert_bool("shutdown: quit honoured inside the grace (%d ms), child gone" % dt, dt < AiBridge.QUIT_GRACE_MS and child_gone(pid))
	return true


# ---------------------------------------------------------------- --faults

func test_partial() -> bool:
	print("fake partial: every reply in three flushed pieces")
	var b := fake("partial")
	b.request(req("1", "text"))
	b.request(req("2", "voice"))
	pump(b, 5000, func(): return b.outcomes.size() == 2)
	assert_bool("both results assembled: %s" % [reasons(b)], reasons(b) == ["1:ok", "2:ok"] and b.launch_count == 1)
	b.shutdown()
	return true


## A hung service that cannot exit by itself: answers hello, then sleeps with
## its stdin unread (end of input does not stop it). Only a kill ends it.
func deaf_hang() -> AiBridge:
	var b := fake("hang")
	var hello := '{"v":1,"type":"hello","proto":{"major":1,"minor":0},"service":"deaf","provider":"stub","live":false,"cache_dir":"-","routes":{}}'
	b.launch_override = {"bin": "/bin/sh", "args": PackedStringArray(["-c", 'read l; printf "%s\\n" "$1"; exec sleep 600', "sh", hello])}
	return b


func test_timeouts() -> bool:
	for kind in ["text", "voice", "portrait"]:
		print("hung service: %s timeout" % kind)
		var b := deaf_hang()
		var limit: int = b.timeout_ms[kind]
		poll_usecs = []
		b.request(req("1", kind))
		pump(b, 5000, func(): return b.in_flight().size() > 0)
		var pid := b.child_pid
		# The deadline starts when the request is written, inside the pump above, so t0
		# can trail it by a frame; allow that slack below the limit.
		var t0 := Time.get_ticks_msec()
		pump(b, limit + 2000, func(): return b.outcomes.size() == 1)
		var dt := Time.get_ticks_msec() - t0
		assert_bool("%s cancelled timeout after %d ms (limit %d)" % [kind, dt, limit], reasons(b) == ["1:timeout"] and dt >= limit - 50 and dt < limit + 300)
		pump(b, 500, func(): return child_gone(pid))
		assert_bool("hung child (cannot exit by itself) killed within 500 ms of the timeout", pid > 0 and child_gone(pid))
		pump(b, 300)
		assert_bool("restart is lazy: no relaunch while idle", b.launch_count == 1)
		b.request(req("2", kind))
		pump(b, 3000, func(): return b.in_flight().size() > 0)
		assert_bool("next request relaunches at once", b.launch_count == 2)
		frame_check("hang %s" % kind)
		b.shutdown()
	print("fake hang: one in flight")
	var h := fake("hang")
	h.request(req("1", "portrait"))
	h.request(req("2", "text"))
	h.request(req("3", "text"))
	pump(h, 5000, func(): return h.in_flight().size() > 0)
	pump(h, 150)
	assert_bool("a hung service is sent exactly one request, the first text", h.sent_count == 1 and h.in_flight()["req"] == "2")
	h.shutdown()
	return true


func test_crash_loop() -> bool:
	print("fake crash_after_n 0: crash loop -> backoff -> service_down")
	var b := fake("crash_after_n", 0)
	var toasts := []
	b.service_down_toast.connect(func(t): toasts.append(t))
	poll_usecs = []
	b.request(req("1", "portrait"))
	b.request(req("2", "text"))
	b.request(req("3", "voice"))
	pump(b, 20000, func(): return b.service_down)
	assert_bool("three launches, three failures, then down", b.launch_count == 3 and b.failure_times.size() == 3 and b.service_down)
	var gap1: int = b.launch_times[1] - b.failure_times[0]
	var gap2: int = b.launch_times[2] - b.failure_times[1]
	assert_bool("backoff %d ms then %d ms (150, 600)" % [gap1, gap2], gap1 >= 150 and gap1 < 300 and gap2 >= 600 and gap2 < 750)
	assert_bool("the crashing request was resent each time (3 sends)", b.sent_total == 3)
	assert_bool("every open and queued request service_down: %s" % [reasons(b)], reasons(b) == ["2:service_down", "3:service_down", "1:service_down"])
	assert_bool("toast once: '%s'" % [toasts], toasts == [AiBridge.TOAST_TEXT])
	b.request(req("4", "text"))
	pump(b, 300)
	assert_bool("disabled for the session: new request cancelled at once, no launch", reasons(b).back() == "4:service_down" and b.launch_count == 3)
	frame_check("crash loop")

	print("fake crash_after_n 1: crash, resend, recover")
	var r := fake("crash_after_n", 1)
	r.request(req("1", "text"))
	r.request(req("2", "text"))
	pump(r, 8000, func(): return r.outcomes.size() == 2)
	assert_bool("both answered after one restart: %s" % [reasons(r)], reasons(r) == ["1:ok", "2:ok"] and r.launch_count == 2 and r.last_error == "child_eof" and not r.service_down)
	r.shutdown()

	print("failure window: failures older than 10 min drop out")
	var w := fake("crash_after_n", 0)
	w.request(req("1", "text"))
	pump(w, 5000, func(): return w.failure_times.size() == 2)
	w.clock_offset_ms += AiBridge.FAIL_WINDOW_MS + 1000
	pump(w, 5000, func(): return w.failure_times.size() == 3)
	assert_bool("third failure 11 min later: still up, backoff now %d ms" % (w._next_launch_at - w.failure_times[2]), not w.service_down and w._next_launch_at - w.failure_times[2] == 2400)
	w.backoff_ms = [50, 50, 50]
	w._next_launch_at = w.now_msec()
	pump(w, 8000, func(): return w.service_down)
	assert_bool("two more inside the window: down after 5 failures", w.service_down and w.failure_times.size() == 5)
	return true


func test_garbage() -> bool:
	print("fake garbage: stray lines ignored, broken JSON is a failure")
	var b := fake("garbage")
	poll_usecs = []
	b.request(req("1", "text"))
	pump(b, 15000, func(): return b.service_down)
	assert_bool("bad_response x3 -> service_down: %s" % [reasons(b)], b.last_error == "bad_response" and b.failure_times.size() == 3 and reasons(b) == ["1:service_down"])
	frame_check("garbage")
	return true


func test_handshake_faults() -> bool:
	print("fake slow_hello / wrong_major: handshake refused")
	var s := fake("slow_hello")
	s.handshake_ms = 400
	s.request(req("1", "text"))
	pump(s, 3000, func(): return s.failure_times.size() == 1)
	var dt: int = s.failure_times[0] - s.launch_times[0]
	assert_bool("no hello in time: startup_timeout after %d ms, request kept, nothing sent" % dt, s.last_error == "startup_timeout" and dt >= 400 and dt < 600 and s.sent_total == 0 and s.pending() == 1)
	s.shutdown()
	var m := fake("wrong_major")
	m.request(req("1", "text"))
	pump(m, 5000, func(): return m.failure_times.size() == 1)
	assert_bool("proto.major 2 refused: bad_proto, nothing sent", m.last_error == "bad_proto" and m.sent_total == 0 and m.hello_reply.is_empty())
	m.shutdown()
	return true


func test_shutdown_grace() -> bool:
	print("shutdown: quit, 1 s grace, then kill")
	var b := AiBridge.new()
	bridges.append(b)
	b.launch_override = {"bin": "/bin/sleep", "args": PackedStringArray(["30"])} # ignores quit
	b.request(req("1", "text"))
	pump(b, 500, func(): return b.child_pid > 0)
	var pid := b.child_pid
	var t0 := Time.get_ticks_msec()
	b.shutdown()
	var dt := Time.get_ticks_msec() - t0
	assert_bool("deaf child killed after the grace (%d ms)" % dt, dt >= AiBridge.QUIT_GRACE_MS and dt < AiBridge.QUIT_GRACE_MS + 300)
	pump(b, 1000, func(): return child_gone(pid))
	assert_bool("deaf child gone", child_gone(pid))
	return true


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(scratch)
	# The control's read and probe target: an idle child's empty stdout pipe
	# (the read a poll makes when the service has nothing to say) and its pid.
	var ctrl := OS.execute_with_pipe("/bin/sleep", PackedStringArray(["600"]), false)
	ctrl_file = ctrl["stdio"]
	ctrl_pid = ctrl["pid"]
	var faults := "--faults" in OS.get_cmdline_user_args()
	if SimBridge.find_ailang() == "":
		print("FAIL  ailang not found (AILANG_BIN or PATH)")
		quit(2)
		return
	# --only=name,name runs a subset (the mutation check uses it to stay short).
	var only := []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.substr(7).split(",")
	var tests := ["static", "assemble", "stub_session"]
	if faults:
		tests.append_array(["partial", "timeouts", "crash_loop", "garbage", "handshake_faults", "shutdown_grace"])
	for t in tests:
		if only.is_empty() or t in only:
			if call("test_" + t) != true: # a script error aborts a test silently
				assert_bool("test_%s ran to its end" % t, false)
	var pids := []
	for b in bridges:
		b.shutdown()
		pids.append(b.child_pid)
	OS.delay_msec(50)
	for b in bridges:
		b.poll() # reap
	assert_bool("no child left running", pids.all(func(p): return p < 0 or child_gone(p)))
	for b in bridges:
		b.free()
	OS.kill(ctrl_pid)
	print("ai bridge: %s (%s)" % ["FAIL" if failures > 0 else "ok", "with faults" if faults else "happy path only"])
	quit(1 if failures > 0 else 0)
