extends RefCounted
## make bench (M1.3, AC7 stars-only part): a scripted flight at 2560x1440 with
## vsync off. main.gd builds the scene (starfield tier, background) and calls
## run() from `--bench[=SECONDS]`.
##   1. CPU rebase: five forced rebases of the whole instance buffer, timed
##      (target < 4 ms; above it the flight uses Rebase.GPU, design plan B).
##   2. Flight: 1 g through the AILANG sim to 0.99c in ~2/3 of the run, then
##      coast; the camera sweeps a full turn in yaw (forward, starboard,
##      astern) with a slow pitch. Every frame logs wall time and the
##      viewport's GPU time; the sim state and view are recorded.
##   3. Replay: the recorded frames again with the starfield hidden. The star
##      pass is the per-frame difference (GPU time when the driver reports it;
##      Godot 4.7's Metal driver reports 0, so make bench also runs Vulkan).
##   4. AC8 (M1.5a): the V 5.0-8.5 limiting-magnitude ladder (tools/exposure_golden.gd).
##   (M3.5b, Q4) GR: a static sweep (same yaw/pitch path, ship at Sol, at rest) with GR off, then
##      on at r = 10 r_s toward the galactic centre (lensed sky, both star images on the whole
##      tier, the ring-star path): `bench: GR` lines; GR off must hold the M1.3 numbers.
## Prints one `bench:` summary line and writes the numbers to .godot/tmp/bench.json.
## -- --bench-size=WxH renders at another size (make bench BENCH_SIZE=1920x1080; starmap large tier
## sprint LT0). The report adds the tier stack's load time (a fresh load_tiers, timed) and memory.

const SIZE := Vector2i(2560, 1440)
const WARMUP := 60
const REBASE_TARGET_MS := 4.0
const STAR_PASS_TARGET_MS := 2.0
const P99_TARGET_MS := 16.7

var _rebases0 := 0


var bench_size := SIZE
var load_ms := 0.0


func run(main: Node, seconds: float) -> int:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--bench-size="):
			var wh := a.trim_prefix("--bench-size=").split("x")
			if wh.size() == 2 and wh[0].is_valid_int() and wh[1].is_valid_int(): bench_size = Vector2i(int(wh[0]), int(wh[1]))
	var tree := main.get_tree()
	var win: Window = main.get_window()
	win.size = bench_size
	# a window can be clamped by the screen (2560x1288 here), so render the
	# 3D viewport at exactly SIZE and scale it into the window
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	win.content_scale_size = bench_size
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var vp: RID = main.get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp, true)
	var sf: Starfield = main.starfield
	var t0 := Time.get_ticks_usec()
	var probe := Starfield.new()
	probe.load_tiers(sf.tiers[0].split(":")[0])
	load_ms = (Time.get_ticks_usec() - t0) / 1000.0
	probe.free()
	for i in WARMUP:
		await tree.process_frame
	main._configure_exposure({}) # the pixel solid angle at SIZE (M1.5a)
	var rebase_ms := _time_rebases(sf)
	var mode := Starfield.Rebase.CPU if rebase_ms < REBASE_TARGET_MS else Starfield.Rebase.GPU
	sf.set_rebase_mode(mode)
	_rebases0 = sf.rebases
	var frames := await _fly(main, seconds)
	if frames.is_empty():
		return 2
	var off := await _replay(main, frames)
	var rc := _report(main, frames, off, rebase_ms, mode, seconds)
	await _gr_sweeps(main, minf(seconds, 10.0))
	# AC8 (M1.5a): the limiting-magnitude ladder at this render size, after the
	# flight (it swaps in a uniform 23.5 mag/arcsec^2 sky)
	var lim: Dictionary = await load("res://tools/exposure_golden.gd").new().limiting_magnitude(main)
	var ok: bool = lim["v_lim"] >= Exposure.AC8.x and lim["v_lim"] <= Exposure.AC8.y
	print("bench: limiting magnitude %s: %s" % [lim["line"], "ok" if ok else "MISS"])
	return rc if ok else 1


func _time_rebases(sf: Starfield) -> float:
	var saved := sf.ship.duplicate()
	var ms := []
	for i in 5:
		sf.ship[0] = saved[0] + 0.02 * (i + 1)
		sf.rebase()
		ms.append(sf.last_rebase_ms)
	sf.ship = saved
	ms.sort()
	return ms[2]


## Returns per-frame records; empty if the sim stopped.
func _fly(main: Node, seconds: float) -> Array:
	var tree := main.get_tree()
	var sim: SimBridge = main.sim
	var rate := 2.564 / (seconds * 2.0 / 3.0) # ship-years per real second: atanh(0.99) / 1 g in ~2/3 of the run
	var frames := []
	var t0 := Time.get_ticks_usec()
	var last := t0
	var vp: RID = main.get_viewport().get_viewport_rid()
	while (last - t0) / 1e6 < seconds:
		var now_s := (last - t0) / 1e6
		var thrust := 1.0 if sim.world["ship"]["beta"] < 0.99 else 0.0
		var dt := clampf(frames.back()["frame_ms"] / 1000.0 if not frames.is_empty() else 0.016, 0.0, 0.05)
		if not sim.send([{"k": "thrust", "thrust": thrust}], rate * dt):
			push_error("bench: sim stopped (%s)" % sim.last_error)
			return []
		main._apply_state()
		var yaw := TAU * now_s / seconds
		var pitch := 0.35 * sin(TAU * now_s / (seconds * 0.5))
		main.camera.look(yaw, pitch, 0.0)
		await tree.process_frame
		var now := Time.get_ticks_usec()
		var ship: Dictionary = sim.world["ship"]
		frames.append({"frame_ms": (now - last) / 1000.0, "gpu_ms": RenderingServer.viewport_get_measured_render_time_gpu(vp),
			"cpu_ms": RenderingServer.viewport_get_measured_render_time_cpu(vp), "beta": ship["beta"], "gamma": ship["gamma"],
			"heading": ship["heading"], "pos": ship["pos"], "yaw": yaw, "pitch": pitch})
		last = now
	return frames


## The same frames with the starfield hidden: [frame_ms, gpu_ms] per frame.
func _replay(main: Node, frames: Array) -> Array:
	var tree := main.get_tree()
	var sf: Starfield = main.starfield
	var vp: RID = main.get_viewport().get_viewport_rid()
	var out := []
	sf.visible = false
	var last := Time.get_ticks_usec()
	for f: Dictionary in frames:
		var h: Dictionary = f["heading"]
		var p: Dictionary = f["pos"]
		var dir := Vector3(h["x"], h["y"], h["z"])
		sf.set_velocity(dir, f["beta"], f["gamma"])
		sf.set_ship_position(p["x"], p["y"], p["z"])
		if main.has_background:
			main.background.set_velocity(dir, f["beta"], f["gamma"])
		main.camera.look(f["yaw"], f["pitch"], 0.0)
		await tree.process_frame
		var now := Time.get_ticks_usec()
		out.append([(now - last) / 1000.0, RenderingServer.viewport_get_measured_render_time_gpu(vp)])
		last = now
	sf.visible = true
	return out


static func pct(xs: Array, q: float) -> float:
	var s := xs.duplicate()
	s.sort()
	return s[clampi(int(ceil(q * s.size())) - 1, 0, s.size() - 1)]


func _report(main: Node, frames: Array, off: Array, rebase_ms: float, mode: Starfield.Rebase, seconds: float) -> int:
	var sf: Starfield = main.starfield
	var ft := frames.map(func(f: Dictionary) -> float: return f["frame_ms"])
	var gpu := frames.map(func(f: Dictionary) -> float: return f["gpu_ms"])
	var gpu_delta := []
	var wall_delta := []
	for i in frames.size():
		gpu_delta.append(frames[i]["gpu_ms"] - off[i][1])
		wall_delta.append(frames[i]["frame_ms"] - off[i][0])
	var driver := RenderingServer.get_current_rendering_driver_name()
	var has_gpu := pct(gpu, 0.5) > 0.0
	var size := main.get_viewport().get_texture().get_size()
	var r := {
		"driver": driver, "device": RenderingServer.get_video_adapter_name(), "render_size": [size.x, size.y],
		"tiers": sf.tiers, "stars": sf.count, "background": main.has_background, "seconds": seconds, "frames": frames.size(),
		"frame_ms_p50": pct(ft, 0.5), "frame_ms_p95": pct(ft, 0.95), "frame_ms_p99": pct(ft, 0.99),
		"frames_over_budget": ft.filter(func(x: float) -> bool: return x > P99_TARGET_MS).size(), "gpu_ms_p50": pct(gpu, 0.5), "gpu_ms_p99": pct(gpu, 0.99),
		"star_pass_gpu_ms_p50": pct(gpu_delta, 0.5) if has_gpu else null, "star_pass_gpu_ms_p90": pct(gpu_delta, 0.9) if has_gpu else null,
		"star_pass_gpu_ms_p99": pct(gpu_delta, 0.99) if has_gpu else null,
		"star_pass_wall_ms_p50": pct(wall_delta, 0.5), "cpu_rebase_ms": rebase_ms, "rebase_mode": Starfield.Rebase.keys()[mode],
		"rebases_in_flight": sf.rebases - _rebases0, "beta_end": frames.back()["beta"],
		"load_tiers_ms": load_ms, "static_memory_mb": Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
		"video_memory_mb": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
		"buffer_memory_mb": Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED) / 1048576.0,
	}
	var per_frame := []
	for i in frames.size():
		per_frame.append([snappedf(frames[i]["frame_ms"], 0.001), snappedf(frames[i]["gpu_ms"], 0.001), snappedf(off[i][1], 0.001), snappedf(frames[i]["beta"], 0.0001), snappedf(frames[i]["yaw"], 0.001)])
	var ff := FileAccess.open(ProjectSettings.globalize_path("res://.godot/tmp/bench_frames_%s.json" % driver), FileAccess.WRITE)
	if ff != null:
		ff.store_string(JSON.stringify({"columns": ["frame_ms", "gpu_ms", "gpu_ms_no_stars", "beta", "yaw"], "frames": per_frame}) + "\n")
		ff.close()
	var f := FileAccess.open(ProjectSettings.globalize_path("res://.godot/tmp/bench_%s.json" % driver), FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(r, "  ") + "\n")
		f.close()
	print("bench: driver %s (%s), %dx%d, tiers %s, %d stars, background %s, %d frames in %.0f s, end beta %.4f" % [
		driver, r["device"], size.x, size.y, sf.tiers, sf.count, main.has_background, frames.size(), seconds, r["beta_end"]])
	print("bench: frame ms p50 %.3f  p95 %.3f  p99 %.3f (target p99 < %.1f: %s); %d of %d frames over %.1f ms" % [r["frame_ms_p50"], r["frame_ms_p95"], r["frame_ms_p99"],
		P99_TARGET_MS, "ok" if r["frame_ms_p99"] < P99_TARGET_MS else "MISS", r["frames_over_budget"], frames.size(), P99_TARGET_MS])
	if has_gpu:
		print("bench: viewport GPU ms p50 %.3f  p99 %.3f; star pass GPU ms (frame minus replayed frame without stars) p50 %.3f  p90 %.3f  p99 %.3f (target p50 < %.1f: %s)" % [r["gpu_ms_p50"], r["gpu_ms_p99"],
			r["star_pass_gpu_ms_p50"], r["star_pass_gpu_ms_p90"], r["star_pass_gpu_ms_p99"], STAR_PASS_TARGET_MS, "ok" if r["star_pass_gpu_ms_p50"] < STAR_PASS_TARGET_MS else "MISS"])
	else:
		print("bench: viewport GPU time not reported by the %s driver (Godot 4.7); star pass wall-time delta p50 %.3f ms (proxy)" % [driver, r["star_pass_wall_ms_p50"]])
	print("bench: load_tiers %.0f ms (fresh stack); memory static %.0f MB, video %.0f MB (buffers %.0f MB)" % [load_ms, r["static_memory_mb"], r["video_memory_mb"], r["buffer_memory_mb"]])
	print("bench: CPU rebase of %d instances %.2f ms (target < %.1f) -> rebase mode %s%s; %d rebases in flight" % [
		sf.count, rebase_ms, REBASE_TARGET_MS, r["rebase_mode"], " (plan B: direction and 1/r^2 in the vertex shader)" if mode == Starfield.Rebase.GPU else "", r["rebases_in_flight"]])
	return 0


## M3.5b (Q4): the same camera sweep at rest with GR off and on (r = 10, hole toward the
## galactic centre), each `seconds` long; prints one `bench: GR` line per state.
func _gr_sweeps(main: Node, seconds: float) -> void:
	var sf: Starfield = main.starfield
	sf.set_ship_position(0.0, 0.0, 0.0)
	sf.set_velocity(Vector3(0, 0, -1), 0.0, 1.0)
	if main.has_background:
		main.background.set_velocity(Vector3(0, 0, -1), 0.0, 1.0)
	var gr := GrLens.new(sf, main.background if main.has_background else null)
	for on in [false, true]:
		if on:
			gr.set_gr(GrLens.reference_state(10.0, PackedFloat64Array([1.0, 0.0, 0.0])))
			var t0 := Time.get_ticks_usec()
			gr.refresh_now()
			var ms := (Time.get_ticks_usec() - t0) / 1000.0
			print("bench: GR ring-star sweep of %d stars %.1f ms at once (in play %d-star slices, ~%.2f ms per frame); %s" % [sf.count, ms, GrLens.CHUNK, ms * GrLens.CHUNK / maxf(sf.count, 1.0), gr.debug_line()])
			gr.set_exposure(sf.material.get_shader_parameter("exposure"), 0.0005) # the flight's star exposure; ring PSF ~1 px at 2560x1440
		var ft := []
		var gpu := []
		var vp: RID = main.get_viewport().get_viewport_rid()
		var t_start := Time.get_ticks_usec()
		var last := t_start
		for i in WARMUP:
			await main.get_tree().process_frame
		last = Time.get_ticks_usec()
		t_start = last
		while (last - t_start) / 1e6 < seconds:
			var now_s := (last - t_start) / 1e6
			main.camera.look(TAU * now_s / seconds, 0.35 * sin(TAU * now_s / (seconds * 0.5)), 0.0)
			await main.get_tree().process_frame
			var now := Time.get_ticks_usec()
			ft.append((now - last) / 1000.0)
			gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(vp))
			last = now
		print("bench: GR %s (%d stars, static sweep at rest): %d frames, frame ms p50 %.3f  p95 %.3f  p99 %.3f; %d over %.1f ms; viewport GPU ms p50 %.3f  p99 %.3f" % [
			"on  (r = 10 r_s, both images + ring path)" if on else "off", sf.count, ft.size(), pct(ft, 0.5), pct(ft, 0.95), pct(ft, 0.99),
			ft.filter(func(x: float) -> bool: return x > P99_TARGET_MS).size(), P99_TARGET_MS, pct(gpu, 0.5), pct(gpu, 0.99)])
	gr.clear()
