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
## Prints one `bench:` summary line and writes the numbers to .godot/tmp/bench.json.

const SIZE := Vector2i(2560, 1440)
const WARMUP := 60
const REBASE_TARGET_MS := 4.0
const STAR_PASS_TARGET_MS := 2.0
const P99_TARGET_MS := 16.7

var _rebases0 := 0


func run(main: Node, seconds: float) -> int:
	var tree := main.get_tree()
	var win: Window = main.get_window()
	win.size = SIZE
	# a window can be clamped by the screen (2560x1288 here), so render the
	# 3D viewport at exactly SIZE and scale it into the window
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	win.content_scale_size = SIZE
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var vp: RID = main.get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp, true)
	var sf: Starfield = main.starfield
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
	print("bench: CPU rebase of %d instances %.2f ms (target < %.1f) -> rebase mode %s%s; %d rebases in flight" % [
		sf.count, rebase_ms, REBASE_TARGET_MS, r["rebase_mode"], " (plan B: direction and 1/r^2 in the vertex shader)" if mode == Starfield.Rebase.GPU else "", r["rebases_in_flight"]])
	return 0
