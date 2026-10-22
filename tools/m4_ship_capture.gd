extends SceneTree
## M4.6rR3: one real console-driven voyage, captain eye, two views per state.
const SIZE := Vector2i(1600, 900)
const OUT := "res://renders/m4"
const DECK := [20.0, -2.58] # tilt deg, yaw rad: 60 deg off the bow, above the deck
const FORWARD := [-0.01, -PI * 0.5] # tilt deg, yaw rad: the travel pole (D-92: the bow, glTF -z)
const STATES := [
	{"id": "boost_b05", "phase": "boosting", "beta_min": 0.5},
	{"id": "boost_b09", "phase": "boosting", "beta_min": 0.9},
	{"id": "cruise_099", "phase": "cruising"},
	{"id": "brake_b05", "phase": "braking", "beta_max": 0.5},
]
const THUMB := Vector2i(320, 180)
const GAP := 6
var demo: Node
var failures := 0
var shots: Array[String] = []
var frames: Array[Dictionary] = []
var started := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	started = Time.get_ticks_msec()
	_check(DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT)) == OK, "create output directory")
	for name in DirAccess.get_files_at(OUT):
		if name.ends_with(".png") or name in ["manifest.json", "m4_manifest.sha256", "worlds.sha256"]:
			_check(DirAccess.remove_absolute(OUT.path_join(name)) == OK, "remove stale " + name)
	if failures:
		_finish()
		return
	root.size = SIZE
	demo = load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options = {"size": SIZE, "sky_state": "rest", "seed": 424242, "ai": false, "tier": "medium"}
	root.add_child(demo)
	await process_frame
	demo.auto = false
	demo.journey_auto_tick = false
	if not _check(demo.ready_ok, "demo not ready"):
		_finish()
		return
	_check(demo.sky.has_background, "no sky panorama: make sky-assets")
	_check(demo.sky.starfield.count >= 60000, "fewer than 60000 stars")
	_check(Starfield.last_loaded.get("tier") == "medium", "tier is not medium")
	if failures or not await _helm():
		_finish()
		return
	# Navigation creates the seed's real session; close it without committing.
	demo.open_navigation()
	demo.close_navigation()
	if not _check(demo.journey_sim != null, "navigation session unavailable"):
		_finish()
		return
	await _views(1, "docked")
	if _use("open") and _use("select", "CNS5:3627") and _use("commit"):
		await _leg(true)
		if _arrived():
			await _views(6, "arrived_acen")
			demo.dismiss_arrival()
			if await _helm():
				if _use("open") and _use("home") and _step() and _use("commit"):
					await _leg(false)
					if _arrived():
						await _views(7, "arrived_home")
	_check(shots.size() == 14, "shot count %d (want 14)" % shots.size())
	_duplicates()
	_sheet()
	_manifest()
	_finish()


func _helm() -> bool:
	if not _check(demo.consoles.walk_to("navigation"), "walk to navigation"):
		return false
	# Walking is real-time (WALK_SPEED_MPS per frame delta; 19.6 m is ~15 s at 1.3 m/s), so bound it in wall time:
	# 600 frames at a fast frame rate were too short for the walk on the rig.
	var deadline := Time.get_ticks_msec() + 30000
	while Time.get_ticks_msec() < deadline:
		if demo.consoles.walking.is_empty():
			return true
		await process_frame
	return _check(false, "walk to navigation exceeded 30 s")


func _use(action: String, arg: Variant = null) -> bool:
	return _check(demo.consoles.use("navigation", action, arg), "console navigation/" + action)


func _step() -> bool:
	var ok: bool = demo.journey_tick()
	demo._process(1.0 / GalaxyMap.TICK_HZ)
	return _check(ok, "journey tick")


func _arrived() -> bool:
	return demo.journey_sim.world.journey.state == "arrived" and not demo.live_journey


func _leg(outbound: bool) -> void:
	var fired := {}
	for tick in 4000:
		if not _step():
			break
		var ship: Dictionary = demo.journey_sim.world.ship
		if outbound:
			for i in STATES.size():
				var state: Dictionary = STATES[i]
				if fired.has(state.id) or ship.phase != state.phase:
					continue
				if state.has("beta_min") and ship.beta < state.beta_min:
					continue
				if state.has("beta_max") and ship.beta > state.beta_max:
					continue
				fired[state.id] = true
				await _views(i + 2, state.id)
		if _arrived():
			break
	if outbound:
		for state: Dictionary in STATES:
			if not fired.has(state.id):
				_fail("state %s not reached" % state.id)
	_check(_arrived(), "state %s not reached" % ("arrived_acen" if outbound else "arrived_home"))


func _views(n: int, state: String) -> void:
	# A departure leaves the console through its own camera dolly.
	var deadline := Time.get_ticks_msec() + 30000
	while demo.consoles.dolly_active() and Time.get_ticks_msec() < deadline:
		await process_frame
	_check(not demo.consoles.dolly_active(), "console dolly did not finish")
	if state == "docked":
		# Settle the first pose change after the walk: the frame right after it differs from
		# later frames at the same pose, so a stuck view would escape the duplicate check (DC2).
		demo.camera.follow(demo.avatar_pos, DECK[0], DECK[1], 0.0)
		demo._sync_observer()
		for i in 60:
			await process_frame
	var world: Dictionary = demo.journey_sim.world.duplicate(true)
	var ship: Dictionary = world.ship
	var beta: float = ship.beta
	var glow: float = ship.ism.glow_pole_w_m2
	match state:
		"docked", "arrived_acen", "arrived_home":
			_check(ship.phase == "at_rest" and beta == 0.0 and glow == 0.0, state + " rest values")
			if state != "docked":
				_check(_arrived() and world.journey.plan.target.id == ("Sol" if state == "arrived_home" else "CNS5:3627"), state + " target")
		"boost_b05":
			_check(ship.phase == "boosting" and beta >= 0.5 and beta < 0.51, state + " values")
		"boost_b09":
			_check(ship.phase == "boosting" and beta >= 0.9 and beta < 0.91, state + " values")
		"cruise_099":
			# The sim's cruise beta is 0.9900000000000004 (2 ulp), so compare with a tolerance.
			_check(ship.phase == "cruising" and absf(beta - 0.99) < 1e-12 and glow > 0.0 and demo.sky_state == "live", state + " values")
		"brake_b05":
			_check(ship.phase == "braking" and beta > 0.49 and beta <= 0.5, state + " values")
	await _shot(n, state, "deck", DECK, world)
	await _shot(n, state, "forward", FORWARD, world)


func _shot(n: int, state: String, view: String, pose: Array, world: Dictionary) -> void:
	demo.camera.follow(demo.avatar_pos, pose[0], pose[1], 0.0)
	demo._sync_observer()
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var path := "%s/%02d_%s_%s.png" % [OUT, n, state, view]
	if not _check(img != null and img.save_png(path) == OK, "save " + path.get_file()):
		return
	shots.append(path)
	frames.append({"file": path.get_file(), "state": state, "view": view, "tilt": pose[0], "yaw": pose[1],
		"tick": world.tick, "eye_m": demo.camera.ship_vector(demo.camera.position), "ship": world.ship,
		"journey": world.journey, "clock": world.clock, "world_sha256": SimBridge.encode(world).sha256_text()})
	var saved := Image.load_from_file(ProjectSettings.globalize_path(path))
	if not _check(saved != null and not saved.is_empty(), "reload " + path.get_file()):
		return
	var lit := 0
	var levels := {}
	for y in 36:
		for x in 64:
			var c := saved.get_pixel(int((x + 0.5) * saved.get_width() / 64.0), int((y + 0.5) * saved.get_height() / 36.0))
			var luminance := 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
			if luminance > 8.0 / 255.0:
				lit += 1
			levels[clampi(roundi(luminance * 255.0), 0, 255)] = true
	var fraction := lit / (64.0 * 36.0)
	if fraction < 0.10 or levels.size() < 32:
		_fail("blank %s lit %.3f levels %d" % [path.get_file(), fraction, levels.size()])
	else:
		print("capture-m4: ok frame %s lit %.3f levels %d phase %s beta %s glow_pole_w_m2 %s" % [
			path.get_file(), fraction, levels.size(), world.ship.phase, str(world.ship.beta), str(world.ship.ism.glow_pole_w_m2)])


func _duplicates() -> void:
	var n := shots.size()
	for i in range(n):
		for j in range(i + 1, n):
			if FileAccess.get_sha256(shots[i]) == FileAccess.get_sha256(shots[j]):
				_fail("duplicate %s = %s" % [shots[i].get_file(), shots[j].get_file()])


func _sheet() -> void:
	var sheet := Image.create(THUMB.x * 7 + GAP * 6, THUMB.y * 2 + GAP, false, Image.FORMAT_RGB8)
	for frame: Dictionary in frames:
		var img := Image.load_from_file(ProjectSettings.globalize_path(OUT.path_join(frame.file)))
		if not _check(img != null, "sheet missing " + str(frame.file)):
			continue
		img.convert(Image.FORMAT_RGB8)
		img.resize(THUMB.x, THUMB.y, Image.INTERPOLATE_LANCZOS)
		var col := str(frame.file).left(2).to_int() - 1
		var row := 0 if frame.view == "deck" else 1
		sheet.blit_rect(img, Rect2i(Vector2i.ZERO, THUMB), Vector2i(col * (THUMB.x + GAP), row * (THUMB.y + GAP)))
	_check(sheet.save_png(OUT + "/contact_sheet.png") == OK, "save contact sheet")


func _manifest() -> void:
	var pngs := PackedStringArray()
	var names := Array(DirAccess.get_files_at(OUT))
	names.sort()
	for name: String in names:
		if name.ends_with(".png"):
			pngs.append("%s  %s" % [FileAccess.get_sha256(OUT.path_join(name)), name])
	_check(pngs.size() == 15, "PNG count %d (want 15)" % pngs.size())
	var worlds := PackedStringArray()
	for frame: Dictionary in frames:
		worlds.append("%s  %s" % [frame.world_sha256, frame.file])
	_write("m4_manifest.sha256", "\n".join(pngs) + "\n")
	_write("worlds.sha256", "\n".join(worlds) + "\n")
	_write("manifest.json", SimBridge.encode({"frames": frames, "seed": 424242, "tier": Starfield.last_loaded.get("tier"),
		"size": [SIZE.x, SIZE.y], "adapter": RenderingServer.get_video_adapter_name(), "ailang": demo.journey_sim.hello_reply,
		"wall_s": (Time.get_ticks_msec() - started) / 1000.0}) + "\n")


func _write(name: String, contents: String) -> void:
	var file := FileAccess.open(OUT.path_join(name), FileAccess.WRITE)
	if _check(file != null, "write " + name):
		file.store_string(contents)
		_check(file.get_error() == OK, "store " + name)
		file.close()


func _check(ok: bool, what: String) -> bool:
	if not ok:
		_fail(what)
	return ok


func _fail(what: String) -> void:
	failures += 1
	print("capture-m4: FAIL " + what)


func _finish() -> void:
	print("capture-m4: %d renders in %.1f s to %s" % [shots.size(), (Time.get_ticks_msec() - started) / 1000.0, ProjectSettings.globalize_path(OUT)])
	print("capture-m4: %s" % ("OK" if failures == 0 else "FAIL"))
	if demo != null and demo.journey_sim != null:
		demo.journey_sim.stop()
	quit(1 if failures else 0)
