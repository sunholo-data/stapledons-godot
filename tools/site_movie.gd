extends RefCounted
## make site-media: scripted, frame-exact flights for the showcase website
## (website/). main.gd calls run_sky() from `--movie=CLIP` (sky flight) and
## run_map() from `--map --movie=map` (galaxy map). Each frame is a PNG in
## --movie-out (default renders/movie/CLIP/); tools/site_media.sh encodes them.
## Every number on screen comes from the AILANG sim, exactly as in --capture:
## the clip only chooses how much ship time passes per frame and where the
## camera looks. Nothing here is a fudge of the physics or the exposure.
##   voyage     forward view, at rest -> 0.99c at 1 g (rapidity eased), hold
##   hero       the voyage clip without the HUD (the site's background video)
##   lookaround at 0.99c, one full turn in yaw: crowded bow, dark beam, black stern
##   cmb        forward, 20 deg lens, gamma 20 -> 707: the forward CMB disc (M1.8)
##   map        galaxy map orbit while the cruise slider sweeps 0.9c -> cap

const SIZE := Vector2i(1280, 720)
const MAP_SIZE := Vector2i(1600, 900)
const FPS := 30
const G_PER_YR := 1.0323 # 1 g in c per ship-year (dphi/dtau), only to pace frames
const MAX_DT := 0.01
const BOOST_DT := 2e-9 # ship-years per sim tick during the minutes-long boost (~0.06 s; coarser steps repeat frames at low gamma)
const PHI_099 := 2.6466524123622457 # atanh(0.99)


func _setup(main: Node, size: Vector2i = SIZE) -> void:
	var win: Window = main.get_window()
	win.size = size
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	win.content_scale_size = size


func _out(main: Node, args: Dictionary, clip: String) -> String:
	var dir: String = args.get("movie-out", "renders/movie/" + clip)
	return main._out_dir(dir)


func _frame(main: Node, out: String, i: int) -> void:
	await main.get_tree().process_frame
	await RenderingServer.frame_post_draw
	main.get_viewport().get_texture().get_image().save_png(out.path_join("f%05d.png" % i))


func _ease(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)


## Advance the sim (1 g thrust) until the ship's rapidity reaches phi.
func _thrust_to(main: Node, phi: float) -> bool:
	var sim: SimBridge = main.sim
	var now := _rapidity(sim)
	var dtau := (phi - now) / G_PER_YR
	if dtau <= 1e-9:
		return _ok(sim, sim.send([{"k": "thrust", "thrust": 0.0}], 1e-6))
	while dtau > 1e-9: # the sim takes ticks of at most MAX_DT ship-years
		var step := minf(dtau, MAX_DT)
		if not sim.send([{"k": "thrust", "thrust": 1.0}], step):
			return _ok(sim, false)
		dtau -= step
	return true


## From the sim's gamma, never from 1 - beta (gate 5).
func _rapidity(sim: SimBridge) -> float:
	var g: float = sim.world["ship"]["gamma"]
	return log(g + sqrt(g * g - 1.0))


func _ok(sim: SimBridge, ok: bool) -> bool:
	if not ok:
		push_error("movie: sim stopped (%s %s)" % [sim.last_error, sim.last_refused])
	return ok


func run_sky(main: Node, args: Dictionary) -> int:
	_setup(main)
	var clip: String = args["movie"]
	var out := _out(main, args, clip)
	for i in 30:
		await main.get_tree().process_frame
	main._configure_exposure(args)
	var n := 0
	if clip == "hero": # the voyage without the HUD, for the site's full-bleed hero
		main.hud.visible = false
	if clip == "voyage" or clip == "hero":
		var secs := 24.0
		n = int(secs * FPS)
		for i in n:
			var t := i / float(FPS)
			if not _thrust_to(main, PHI_099 * _ease((t - 2.0) / 18.0)):
				push_error("movie: sim stopped (%s)" % main.sim.last_error)
				return 2
			main.camera.look(0.0, 0.0, 0.0)
			main._apply_state()
			await _frame(main, out, i)
	elif clip == "lookaround":
		if not _thrust_to(main, PHI_099):
			return 2
		var secs := 20.0
		n = int(secs * FPS)
		for i in n:
			var u := i / float(n)
			main.camera.look(TAU * u, 0.18 * sin(TAU * u), 0.0)
			if not main.sim.send([{"k": "thrust", "thrust": 0.0}], 1e-6):
				return 2
			main._apply_state()
			await _frame(main, out, i)
	elif clip == "cmb":
		# gamma 20 -> 707 (the cruise cap), log-eased, forward through a 20 deg
		# lens, on a committed journey as in --capture (D-11: the boost takes
		# minutes of ship time, so the ship stays near Sol and its catalogue).
		# The disc is the forward CMB (M1.8): it renders only in a build that
		# has it; on a tree without M1.8 this clip shows the starfield alone.
		var sim: SimBridge = main.sim
		var phi_max: float = minf(log(707.0 + sqrt(707.0 * 707.0 - 1.0)), sim.world["params"]["cruise_phi_max"])
		var h: Vector3 = main.HEADING * 1000.0
		var target := {"index": 0, "id": "site-movie", "pos": {"x": h.x, "y": h.y, "z": h.z}}
		if not sim.new_game(main.SEED, "sol", true) or not sim.send([{"k": "plan", "target": target, "cruise_phi": phi_max}], 0.0) \
				or not sim.send([{"k": "commit", "plan_id": int(sim.world["journey"]["plan_id"])}], 0.0):
			_ok(sim, false)
			return 2
		main.camera.fov = 20.0
		main._configure_exposure(args)
		var secs := 20.0
		n = int(secs * FPS)
		var g0 := log(20.0)
		var g1 := log(707.0)
		for i in n:
			var t := i / float(FPS)
			var g := exp(lerpf(g0, g1, _ease((t - 2.0) / 15.0)))
			var phi := minf(log(g + sqrt(g * g - 1.0)), phi_max)
			while sim.world["ship"]["phase"] != "cruising" and _rapidity(sim) < phi:
				if not _ok(sim, sim.send([], BOOST_DT)):
					return 2
			main.camera.look(0.0, 0.0, 0.0)
			main._apply_state()
			await _frame(main, out, i)
	else:
		push_error("movie: unknown clip %s (voyage | hero | lookaround | cmb)" % clip)
		return 2
	print("movie: %s, %d frames at %d fps -> %s" % [clip, n, FPS, out])
	return 0


func run_map(main: Node, map: GalaxyMap, args: Dictionary) -> int:
	_setup(main, MAP_SIZE) # the map's panel layout is pinned at the --map-capture size
	var out := _out(main, args, "map")
	var target := 1 # alpha Cen A
	map.preselect(target)
	map.frame_star(target)
	var secs := 24.0
	var n := int(secs * FPS)
	for i in 30:
		await main.get_tree().process_frame
	for i in n:
		var u := i / float(n)
		map.pivot = map.world_pos(target) * 0.5 * _ease(u * 2.0)
		map.yaw = 0.6 + TAU * u
		map.pitch = -0.45 + 0.25 * sin(TAU * u)
		map.dist = lerpf(70.0, 14.0, _ease(u * 1.6))
		map._update_camera()
		map.set_cruise_phi(lerpf(map.phi_min, map.phi_max, _ease((u - 0.15) / 0.7)))
		map.tick()
		await _frame(main, out, i)
	print("movie: map, %d frames at %d fps -> %s" % [n, FPS, out])
	return 0
