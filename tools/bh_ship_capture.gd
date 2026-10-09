extends SceneTree
## make capture-bh (M3.6 of R1-M3-BLACK-HOLES): the Sgr A* demo aboard the 3D ship, driven by the
## real sim (scenario sgr_a, protocol 2.6) through the demo's own controls. A person opens them.
##   bh_r{10,5,3}_{toward,side,away}_{hover,orbit}.png   sky only (H), HUD hidden: the Milky Way
##                                     as seen from Sol (design OQ5) and the large-tier catalogue,
##                                     lensed; look forward / side / aft (7 / 8 / 9) with the
##                                     ship's nose on the hole
##   bh_grid_r{...}.png                the same views on the debug grid
##   bh_bridge_r10_hover.png, bh_bridge_r3_orbit.png   in the ship, with the HUD (the sim's gr lines)
##   bh_sheet_milkyway.png, bh_sheet_grid.png          contact sheets (rows r x mode, columns toward/side/away)
##   bh_manifest.sha256                sha256 of every PNG above (the baseline pin, see make bh-refs)
## Orbits at 10 and 5 r_s are capture-only (send_now gr_orbit); the player's script orbits at 3 r_s.

const SIZE := Vector2i(1280, 720)
const OUT := "res://renders"
const LOOK := {"toward": "forward", "side": "side", "away": "aft"}
const THUMB := Vector2i(320, 180)
const GAP := 6 # px of black between thumbnails

var demo: Node
var failures := 0
var shots: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	root.size = SIZE
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	demo = load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options = {"sky_state": "rest", "size": SIZE}
	root.add_child(demo)
	await process_frame
	demo.auto = false
	demo.journey_auto_tick = false
	if not demo.ready_ok or not demo.start_black_hole():
		print("capture-bh: FAIL the demo did not start Sgr A* (%s)" % demo.caption)
		quit(1)
		return
	var t0 := Time.get_ticks_msec()
	var v = demo.black_hole
	for r in [10.0, 5.0, 3.0]:
		if not (demo.bh_next_stop() and demo.bh_finish_approach()):
			_fail("approach to %s r_s (%s)" % [r, v.last_error])
			break
		_check(float(v.gr().r) == r and v.gr().mode == "hover", "hovering at %s r_s" % r)
		await _views("r%d" % int(r), "hover")
		if r == 10.0:
			await _bridge("bh_bridge_r10_hover", 55.0)
		_check(v.send_now([{"k": "gr_orbit"}]), "orbit at %s r_s" % r)
		for i in 40: # 2 s of play: the orbit moves the hole across the sky; the ship keeps its nose on it
			demo.bh_tick()
		_check(v.gr().mode == "orbit", "orbiting at %s r_s" % r)
		await _views("r%d" % int(r), "orbit")
		if r == 3.0:
			await _bridge("bh_bridge_r3_orbit", 55.0)
		_check(v.send_now([{"k": "gr_hover"}]), "hover again at %s r_s" % r)
		demo.bh_tick()
	print("capture-bh: archive events %s; codex %s" % [v.archive_events, demo.codex.toast_log])
	_check(v.archive_events.slice(0, 2) == ["bh_enter", "bh_hover"], "archive events bh_enter, bh_hover in order")
	_sheet("bh_sheet_milkyway", "bh_")
	_sheet("bh_sheet_grid", "bh_grid_")
	_manifest()
	print("capture-bh: %d renders in %.1f s to %s" % [shots.size(), (Time.get_ticks_msec() - t0) / 1000.0, ProjectSettings.globalize_path(OUT)])
	print("capture-bh: %s" % ("OK" if failures == 0 else "FAIL"))
	demo.leave_black_hole()
	quit(1 if failures > 0 else 0)


func _check(ok: bool, what: String) -> void:
	if not ok:
		_fail(what)


func _fail(what: String) -> void:
	failures += 1
	print("capture-bh: FAIL %s" % what)


## Sky only, HUD hidden: toward / side / away, on the Milky Way and on the debug grid.
func _views(rtag: String, mode: String) -> void:
	if not demo.sky_only:
		demo.toggle_sky_only()
	demo.hud.get_parent().visible = false
	demo.codex.get_parent().visible = false # the diagnostic shows the sky alone, no toasts
	for grid in [false, true]:
		if demo.sky.has_background:
			demo.sky.background.set_grid(grid)
		for dir: String in ["toward", "side", "away"]:
			demo.look_direction(LOOK[dir])
			await _shot("bh_%s%s_%s_%s" % ["grid_" if grid else "", rtag, dir, mode])
	if demo.sky.has_background:
		demo.sky.background.set_grid(false)
	demo.toggle_sky_only()
	demo.hud.get_parent().visible = true
	demo.codex.get_parent().visible = true


## In the ship from the bridge (captain eye), the HUD showing the sim's gr lines.
func _bridge(name: String, tilt: float) -> void:
	await create_timer(Codex.TOAST_S + 0.5).timeout # arrival toasts (4 s) gone, as a player sees it a moment later
	demo.set_preset("bridge")
	demo.camera.follow(demo.avatar_pos, tilt, 0.0, 0.0)
	demo._sync_observer()
	demo._process(0.0)
	await _shot(name)


func _shot(name: String) -> void:
	demo.sky.gr_lens.refresh_now() # the ring set now, not after the ~0.6 s in-play sweep
	for i in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var path := "%s/%s.png" % [OUT, name]
	if img == null or img.save_png(path) != OK:
		_fail("save %s" % path)
		return
	shots.append(name)
	print("capture-bh: %s  r %s %s  %s" % [path, demo.black_hole.gr().r, demo.black_hole.gr().mode, demo.sky.gr_lens.debug_line()])


func _sheet(name: String, prefix: String) -> void:
	var sheet := Image.create(THUMB.x * 3 + GAP * 2, THUMB.y * 6 + GAP * 5, false, Image.FORMAT_RGB8)
	var row := 0
	for r in ["r10", "r5", "r3"]:
		for mode in ["hover", "orbit"]:
			for col in 3:
				var img := Image.load_from_file(ProjectSettings.globalize_path("%s/%s%s_%s_%s.png" % [OUT, prefix, r, ["toward", "side", "away"][col], mode]))
				if img == null:
					_fail("sheet %s missing %s %s" % [name, r, mode])
					continue
				img.convert(Image.FORMAT_RGB8)
				img.resize(THUMB.x, THUMB.y, Image.INTERPOLATE_LANCZOS)
				sheet.blit_rect(img, Rect2i(Vector2i.ZERO, THUMB), Vector2i(col * (THUMB.x + GAP), row * (THUMB.y + GAP)))
			row += 1
	if sheet.save_png("%s/%s.png" % [OUT, name]) != OK:
		_fail("save %s" % name)
	else:
		shots.append(name)


func _manifest() -> void:
	var lines := PackedStringArray()
	var names := shots.duplicate()
	names.sort()
	for n in names:
		lines.append("%s  %s.png" % [FileAccess.get_sha256("%s/%s.png" % [OUT, n]), n])
	var f := FileAccess.open(OUT + "/bh_manifest.sha256", FileAccess.WRITE)
	f.store_string("\n".join(lines) + "\n")
	f.close()
