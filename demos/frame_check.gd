class_name FrameCheck
extends Node
## B: a frame check of what the player is doing right now (Mark, 2026-10-14: "add that back to take
## measurements from what I'm doing in game when I push B"). It measures; it decides nothing, so it
## works in every launch (no-twitch: no game state changes). For SECONDS of real play it records:
##   - each frame's wall time, and stalls over 25 ms (when they happened);
##   - the main thread's time waiting on the sim (SimBridge.send_ms_total), per frame and per send;
##   - draw calls, primitives, video and texture memory, object and node counts;
##   - what the game was doing (scene, journey, console, crew, tour leg) and the hardware;
##   - a screenshot at the midpoint.
## The report is saved under user://frame_checks/ and uploaded with the screenshot to the public
## bucket (benchmarks/play/<id>.json and .png) by the Cloud CLI on a worker thread, like the
## benchmark (public bucket, standing approval).

signal finished(report: Dictionary)
signal status_changed(text: String)

const SECONDS := 10.0
const STALL_MS := 25.0
const BUCKET := "stapledons-voyage-assets"
const PREFIX := "benchmarks/play"
const LOCAL_DIR := "user://frame_checks"

var running := false
var seconds := SECONDS                ## tests shorten it
var upload_enabled := true            ## tests save locally only
var status := ""
var url := ""
var _demo: Node
var _sim: SimBridge
var _t := 0.0
var _frames: Array = []        ## [ms, sim_ms, sends] per frame
var _monitors: Array = []      ## sampled once a second
var _shot: Image
var _shot_tried := false
var _last_us := 0
var _sim_ms0 := 0.0
var _sends0 := 0
var _context: Dictionary = {}
var _thread: Thread


func start(demo: Node) -> bool:
	if running:
		return false
	_demo = demo
	var s = demo.get("journey_sim")
	_sim = s if s is SimBridge else null
	_frames = []
	_monitors = []
	_shot = null
	_shot_tried = false
	_last_us = Time.get_ticks_usec()
	_t = 0.0
	_sim_ms0 = _sim.send_ms_total if _sim != null else 0.0
	_sends0 = _sim.send_count if _sim != null else 0
	_context = context_of(demo)
	running = true
	status = "Frame check: measuring %d s of what you're doing…" % int(seconds)
	status_changed.emit(status)
	set_process(true)
	return true


func _process(_delta: float) -> void:
	_poll_upload()
	if not running:
		return
	var now := Time.get_ticks_usec() # wall time between frames, whatever the engine's delta says
	var delta := (now - _last_us) / 1000000.0
	_last_us = now
	var sim_ms := 0.0
	var sends := 0
	if _sim != null:
		sim_ms = _sim.send_ms_total - _sim_ms0
		sends = _sim.send_count - _sends0
		_sim_ms0 = _sim.send_ms_total
		_sends0 = _sim.send_count
	_frames.append([delta * 1000.0, sim_ms, sends])
	var second := int(_t)
	_t += delta
	if int(_t) != second or _monitors.is_empty():
		_monitors.append({
			"t_s": snappedf(_t, 0.01),
			"fps": Performance.get_monitor(Performance.TIME_FPS),
			"process_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
			"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			"primitives": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
			"objects": Performance.get_monitor(Performance.OBJECT_COUNT),
			"nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
			"video_mem_mb": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
			"texture_mem_mb": Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0,
		})
	if not _shot_tried and _t >= seconds * 0.5:
		_shot_tried = true
		var tex := get_viewport().get_texture()
		_shot = tex.get_image() if tex != null and DisplayServer.get_name() != "headless" else null
	if _t >= seconds:
		running = false
		var report := summarize(_frames, _monitors, _context)
		_save_and_upload(report)
		status_changed.emit(status)
		finished.emit(report)


## What the game is doing, in its own fields (no judgement): scene, journey, console, crew, hardware.
static func context_of(demo: Node) -> Dictionary:
	var c := {
		"build": preload("res://demos/ship_demo_benchmark.gd").build_label(),
		"window": [DisplayServer.window_get_size().x, DisplayServer.window_get_size().y],
		"vsync": DisplayServer.window_get_vsync_mode(),
		"renderer": RenderingServer.get_current_rendering_method(),
		"gpu": RenderingServer.get_video_adapter_name(),
		"cpu": OS.get_processor_name(),
		"os": OS.get_name(),
		"memory": OS.get_memory_info(),
		"model": _model(),
	}
	for key in ["sky_state", "live_journey", "camera_mode", "active_level", "menu_return"]:
		var v = demo.get(key)
		if v != null:
			c[key] = v
	var consoles = demo.get("consoles")
	if consoles != null:
		c["console"] = str(consoles.get("focused"))
	var tour = demo.get("solar_tour")
	if tour != null and tour.has_method("leg_name"):
		c["tour_leg"] = tour.leg_name()
	var map = demo.get("journey_map")
	if map != null and map.has_method("journey_state"):
		c["journey_state"] = map.journey_state()
	var sim = demo.get("journey_sim")
	if sim is SimBridge:
		c["sim_tick"] = int((sim as SimBridge).world.get("tick", 0))
		c["crew_aboard"] = not (sim as SimBridge).crew.is_empty()
		c["crew_auto"] = str((sim as SimBridge).crew.get("auto", "off"))
	return c


static func _model() -> String:
	if OS.get_name() != "macOS":
		return "unavailable"
	var out := []
	return str(out[0]).strip_edges() if OS.execute("/usr/sbin/sysctl", PackedStringArray(["-n", "hw.model"]), out) == 0 and not out.is_empty() else "unavailable"


## The report: frame-time percentiles, stalls (with when, and how much of each was the sim), the
## sim's share of the main thread, the monitors once a second, and the context.
static func summarize(frames: Array, monitors: Array, context: Dictionary) -> Dictionary:
	var ms: Array = frames.map(func(f): return float(f[0]))
	var sorted := ms.duplicate()
	sorted.sort()
	var pct := func(p: float) -> float: return 0.0 if sorted.is_empty() else float(sorted[mini(sorted.size() - 1, int(p * sorted.size()))])
	var total := 0.0
	var sim_total := 0.0
	var sends := 0
	var stalls := []
	var at := 0.0
	for f in frames:
		total += float(f[0])
		sim_total += float(f[1])
		sends += int(f[2])
		if float(f[0]) > STALL_MS:
			stalls.append({"at_s": snappedf(at / 1000.0, 0.01), "ms": snappedf(float(f[0]), 0.1), "sim_ms": snappedf(float(f[1]), 0.1)})
		at += float(f[0])
	return {
		"version": 1, "kind": "frame_check", "seconds": snappedf(total / 1000.0, 0.01), "frames": frames.size(),
		"fps_mean": snappedf(frames.size() / maxf(total / 1000.0, 0.001), 0.1),
		"frame_ms": {"p50": snappedf(pct.call(0.5), 0.01), "p95": snappedf(pct.call(0.95), 0.01), "p99": snappedf(pct.call(0.99), 0.01), "max": snappedf(pct.call(1.0), 0.01)},
		"sim": {"sends": sends, "ms_total": snappedf(sim_total, 0.1), "share_of_frame_time": snappedf(sim_total / maxf(total, 0.001), 0.001), "ms_per_send": snappedf(sim_total / maxf(sends, 1), 0.01)},
		"stalls_over_25ms": stalls, "stall_count": stalls.size(),
		"monitors": monitors, "context": context,
	}


func _save_and_upload(report: Dictionary) -> void:
	var id := Time.get_datetime_string_from_system(true).replace(":", "").replace("-", "") + "-" + Crypto.new().generate_random_bytes(4).hex_encode()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(LOCAL_DIR))
	var json_path := ProjectSettings.globalize_path(LOCAL_DIR.path_join(id + ".json"))
	var png_path := ProjectSettings.globalize_path(LOCAL_DIR.path_join(id + ".png"))
	report["id"] = id
	var f := FileAccess.open(json_path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(report, "  "))
		f.close()
	var files := [[json_path, "application/json"]]
	if _shot != null and _shot.save_png(png_path) == OK:
		files.append([png_path, "image/png"])
	var cli: String = preload("res://demos/benchmark_upload.gd").cli_path() if upload_enabled else ""
	var line := "Frame check: %.0f fps mean, p95 %.1f ms, %d stalls, sim %.0f%% of frame time." % [report.fps_mean, report.frame_ms.p95, report.stall_count, report.sim.share_of_frame_time * 100.0]
	report["local"] = json_path
	if cli.is_empty():
		status = line + " Saved locally: " + json_path
		return
	url = "https://storage.googleapis.com/%s/%s/%s.json" % [BUCKET, PREFIX, id]
	status = line + " Uploading…"
	_thread = Thread.new()
	_thread.start(_upload.bind(cli, files, "gs://%s/%s/" % [BUCKET, PREFIX], line))


static func _upload(cli: String, files: Array, dest: String, line: String) -> Dictionary:
	var path := "/opt/homebrew/bin:/usr/local/bin:" + OS.get_environment("PATH")
	for pair in files:
		var out := []
		var rc := OS.execute("/usr/bin/perl", PackedStringArray(["-e", "alarm 60; exec @ARGV; exit 127;", "/usr/bin/env", "PATH=" + path, cli, "storage", "cp", "--quiet", "--content-type=" + str(pair[1]), str(pair[0]), dest + str(pair[0]).get_file()]), out, true)
		if rc != 0:
			return {"ok": false, "code": rc, "line": line}
	return {"ok": true, "line": line}


func _poll_upload() -> void:
	if _thread == null or _thread.is_alive():
		return
	var r: Dictionary = _thread.wait_to_finish()
	_thread = null
	status = (str(r.line) + " Uploaded: " + url) if r.ok else (str(r.line) + " Upload failed (Cloud CLI exit %s); saved locally." % r.code)
	print("frame-check: ", status)
	status_changed.emit(status)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and _thread != null:
		_thread.wait_to_finish()
		_thread = null
