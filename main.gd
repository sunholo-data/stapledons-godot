extends Node3D
## Spike: AILANG ship sim (sidecar) + relativistic starfield (Godot).
##
## Interactive:  W / S thrust forward / reverse at 1 g, arrows look around,
##               Q / E roll, 1-4 look forward / starboard / astern / up (roll 0),
##               +/- time warp. The HUD shows the view-to-velocity angle.
## Galaxy map:  godot --path . [-- --map[=INDEX]]   (default with no arguments; M2.6a/b; --map-capture=renders [--map-commit])
## Sky flight:  godot --path . -- --voyage   (the M0/M1 relativistic voyage; W/S thrust, arrows + Q/E look and roll, 1-4 views, +/- warp)
## Headless-ish checks (need a GPU window, not --headless):
##   godot --path . -- --capture=renders   scripted voyage, PNG per speed/view
##   godot --path . -- --golden            shader vs CPU reference positions
##   godot --path . -- --bench[=SECONDS]   scripted flight, frame-time report (tools/bench.gd; make bench)
## Sky runs:  -- --tier=quick|medium|large  star tier (default: large if built, else medium; M1.3)
## Any run:  -- --record=path.ndjson  tees the sim's input log (replays headless).
## Interactive runs: Cmd/Ctrl + / - / 0 change the UI size (UiScale; HiDPI aware).
##
## The sim runs a protocol v2 diag session (seed 0, scenario "sol"): the ship
## is flown with `heading` and `thrust` intents and drawn from the bridge's
## mirrored world.

const TICK_HZ := 20.0
const HEADING := Vector3(0, 0, -1) # galactic centre
const EXPOSURE := 5.0 # linear splat peak of a V = 0 star (goldens use flux 1 = V 0)
const BG_EXPOSURE := 0.075 # hand-set ratio to the stars until M1.5 calibrates both
const SEED := 0
const ALPHA_CEN_A := 1 # stars.json index 1 (Gl 559, vmag 0.01); B is index 2 with the same id
const LOOK_RATE := 1.2 # rad/s for the yaw, pitch and roll keys
## Off-axis golden (M1.6b, AC5): a velocity off every axis, and three camera
## orientations ([label, yaw, pitch, roll] in degrees; null yaw/pitch = along v).
const OFF_AXIS := Vector3(0.5773502691896258, 0.5773502691896258, -0.5773502691896258) # (1,1,-1)/sqrt3
const GOLDEN_VIEWS := [["along v, rolled +30", null, null, 30.0], ["off-axis yaw 70 pitch -25", 70.0, -25.0, 0.0], ["yaw -120 pitch 40 rolled -65", -120.0, 40.0, -65.0]]

var sim := SimBridge.new()
var starfield := Starfield.new()
var background := SkyBackground.new()
var has_background := false
var env := Environment.new()
var camera := FreeLookCamera.new() # yaw, pitch, roll; client state, never sent to the sim
var hud := Label.new()
var heading := HEADING # the sim's, for the HUD's view-to-velocity angle
var warp := 0.2 # ship-years per real second
var _accum := 0.0
var _map_mode := false
var _fixed_scale := false # captures / goldens: no HiDPI stretch, no UI zoom, no sky note
var sky_note := Label.new()
const SKY_NOTE := "sky background not bundled in this build"


func _ready() -> void:
	var args := _user_args()
	# Captures and goldens keep the 1:1 unstretched window (their PNGs and pixel
	# maths are pinned); interactive runs scale the UI for HiDPI (UiScale).
	_fixed_scale = args.has("capture") or args.has("map-capture") or args.has("golden") or args.has("bench")
	UiScale.configure(get_window(), _fixed_scale)
	# Launching with no arguments (a double-clicked review build, `make run`)
	# opens the galaxy map on alpha Cen A; `--voyage` runs the M0/M1 sky flight.
	if args.is_empty():
		args["map"] = str(ALPHA_CEN_A)
	if args.has("map") or args.has("map-capture"):
		_map_mode = true # the map owns the clock; no voyage ticks
		await _run_map(args)
		return
	_build_scene()
	if args.has("golden"):
		await _run_golden()
		return
	if not load_stars(args.get("tier", "")):
		get_tree().quit(2)
		return
	sim.record_path = args.get("record", "")
	var course := {"k": "heading", "heading": {"x": HEADING.x, "y": HEADING.y, "z": HEADING.z}}
	if not sim.start() or not sim.new_game(SEED, "sol", true) or not sim.send([course], 0.0):
		push_error("sim session failed: %s" % sim.last_error)
		get_tree().quit(2)
		return
	_apply_state()
	if args.has("capture"):
		await _run_capture(args["capture"])
	elif args.has("bench"):
		var secs: float = float(args["bench"]) if args["bench"].is_valid_float() else 30.0
		# loaded by path: tools/ is excluded from exports, so main.gd must not name the class
		get_tree().quit(await load("res://tools/bench.gd").new().run(self, secs))


## Galaxy map (M2.6a) on a play session (not diag): `--map` interactive,
## `--map=INDEX` with a preselected star, `--map-capture=DIR` writes
## galaxy_map.png (alpha Cen A at the 0.99c default), one PNG per speed and
## galaxy_map_panel.json (every label with its sim field and raw value).
## `--map-commit` (M2.6b, R2) then commits alpha Cen A at 0.99c through the
## 1.5 s hold and captures galaxy_map_commit.png (dialog mid-hold),
## galaxy_map_transit.png (mid-cruise, after a refused Cancel) and
## galaxy_map_arrived.png, adding their readouts to the panel dump.
func _run_map(args: Dictionary) -> void:
	var capture: bool = args.has("map-capture")
	if capture:
		get_window().size = Vector2i(1600, 900)
	sim.record_path = args.get("record", "")
	if not sim.start() or not sim.new_game(SEED, "sol", false):
		push_error("sim session failed: %s" % sim.last_error)
		get_tree().quit(2)
		return
	var map: GalaxyMap = load("res://ui/galaxy_map.tscn").instantiate()
	map.auto_tick = not capture
	map.show_hint = not capture # the committed capture PNGs predate the hint
	add_child(map)
	map.load_catalogue("res://data/starmap/stars.json")
	map.load_names("res://data/starmap/names.json")
	map.attach(sim)
	if not capture:
		if args.get("map", "").is_valid_int():
			map.preselect(int(args["map"]))
			map.frame_star(map.selected_index)
		return
	var out := _out_dir(args["map-capture"])
	var dump := {"sim": sim.hello_reply, "params": sim.world["params"], "check_row_4_37ly": {}, "panels": []}
	# design check row 2 (alpha Cen at 4.37 ly on an axis), for comparison with the catalogue star
	map.plan_target({"index": ALPHA_CEN_A, "id": "Gl 559", "pos": {"x": 0.0, "y": 0.0, "z": -4.37}})
	map.tick()
	dump["check_row_4_37ly"] = _panel_dump(map, "0.99c")
	map.preselect(ALPHA_CEN_A)
	map.frame_star(ALPHA_CEN_A)
	for speed in [["0.9c", map.phi_min, "galaxy_map_b09.png"], ["cap", map.phi_max, "galaxy_map_cap.png"], ["0.99c", map.phi_default, "galaxy_map.png"]]:
		map.set_cruise_phi(speed[1])
		map.tick()
		if not sim.last_refused.is_empty() or sim.world["status"] != "ok":
			push_error("map capture: plan at %s not accepted (%s %s)" % [speed[0], sim.last_refused, sim.last_error])
			get_tree().quit(2)
			return
		dump["panels"].append(_panel_dump(map, speed[0]))
		var img := await _grab()
		img.save_png(out.path_join(speed[2]))
		print("captured %s  %s" % [speed[2], map.speed_text()])
	if args.has("map-commit") and not await _capture_commit(map, out, dump):
		get_tree().quit(2)
		return
	var f := FileAccess.open(out.path_join("galaxy_map_panel.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(dump, "  ", false, true) + "\n")
	f.close()
	sim.stop()
	get_tree().quit(0)


## Commit ritual and transit for R2: dialog mid-hold, commit at 1.5 s (fake
## clock), a mid-cruise frame after a refused Cancel, the arrival.
func _capture_commit(map: GalaxyMap, out: String, dump: Dictionary) -> bool:
	if not map.open_commit_dialog():
		push_error("map capture: no plan to commit")
		return false
	map.hold_commit(0.9) # the hold bar part-filled in the frame
	dump["commit_dialog"] = {"plan_id": map.dialog_plan_id, "title": map.dialog_title.text, "rows": map.dialog_rows()}
	(await _grab()).save_png(out.path_join("galaxy_map_commit.png"))
	print("captured galaxy_map_commit.png  %s" % map.dialog_title.text)
	map.hold_commit(GalaxyMap.HOLD_S - 0.9)
	map.tick()
	if map.journey_state() != "committed":
		push_error("map capture: commit not accepted (%s)" % sim.last_refused)
		return false
	var distance: float = sim.world["journey"]["plan"]["distance"]
	while map.journey_state() == "committed" and not (sim.world["ship"]["phase"] == "cruising" and sim.world["ship"]["flown"] > 0.5 * distance):
		map.tick()
	map.press_cancel() # the sim refuses it; the frame shows "refused: committed"
	map.tick()
	dump["transit"] = _panel_dump(map, "transit")
	dump["transit"]["status"] = map.status_text()
	(await _grab()).save_png(out.path_join("galaxy_map_transit.png"))
	print("captured galaxy_map_transit.png  %s" % map.status_text())
	while map.journey_state() == "committed":
		map.tick()
	dump["arrived"] = _panel_dump(map, "arrived")
	dump["arrived"]["events"] = sim.last_events
	(await _grab()).save_png(out.path_join("galaxy_map_arrived.png"))
	print("captured galaxy_map_arrived.png  %s" % map.title_text())
	return map.journey_state() == "arrived"


func _panel_dump(map: GalaxyMap, speed: String) -> Dictionary:
	var rows := map.panel_rows()
	for r in rows:
		print("  %-6s %-30s %-22s %s = %s" % [speed, r["label"], r["text"], r["field"], SimBridge.encode(r["raw"])])
	return {"speed": speed, "tick": sim.world["tick"], "clock": sim.world["clock"], "title": map.title_text(), "subtitle": map.subtitle_text(), "target": sim.world["journey"]["plan"]["target"],
		"cruise_phi": sim.world["journey"]["plan"]["cruise_phi"], "speed_label": map.speed_text(), "rows": rows}


## M1.3: binary tier (+ bright on top when built) -> starfield. Catalogue E_v
## is in lux, so the exposure is per lux: a V = 0 star peaks at EXPOSURE as
## before (M1.5a replaces this with photometric exposure).
func load_stars(tier: String) -> bool:
	if tier == "":
		tier = "large" if FileAccess.file_exists("res://data/starmap/stars_large.bin") else "medium"
	if not starfield.load_tiers(tier):
		push_error("starfield: %s" % starfield.last_error)
		return false
	starfield.build()
	starfield.set_exposure(EXPOSURE / Relativity.illuminance_from_v(0.0))
	print("starfield: tiers %s, %d stars drawn, %d without photometry skipped, rebase %s" % [
		starfield.tiers, starfield.count, starfield.skipped_missing, Starfield.Rebase.keys()[starfield.rebase_mode]])
	return true


func _out_dir(dir: String) -> String:
	# Absolute paths are used as-is; relative ones go under the project (editor)
	# or the user data dir (exported builds, where res:// is read-only).
	var base := ProjectSettings.globalize_path("user://" if OS.has_feature("template") else "res://")
	var out := dir if dir.is_absolute_path() else base.path_join(dir if dir != "" else "renders")
	DirAccess.make_dir_recursive_absolute(out)
	return out


func _user_args() -> Dictionary:
	var out := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		out[kv[0]] = kv[1] if kv.size() > 1 else ""
	return out


func _build_scene() -> void:
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.BLACK
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.glow_enabled = true
	env.glow_bloom = 0.05
	env.glow_hdr_threshold = 1.0
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	camera.fov = 70.0
	camera.near = 0.1
	camera.far = 1000.0
	add_child(camera)
	add_child(starfield)
	if not _user_args().has("golden"):
		has_background = background.attach(env, get_viewport().get_visible_rect().size.y, camera.fov)
		background.set_exposure(BG_EXPOSURE)
		if not has_background:
			# The M1.4 panorama is not in the repo (data/raw is ignored), so a
			# build without it flies over black. Say so instead of failing silently.
			push_warning("%s: %s and %s are missing; the sky flight renders stars over black" % [SKY_NOTE, SkyBackground.PHOTO, SkyBackground.MODEL])
	var layer := CanvasLayer.new()
	hud.position = Vector2(16, 12)
	hud.add_theme_font_size_override("font_size", 16)
	layer.add_child(hud)
	# On screen only in interactive runs, so --capture PNGs are unchanged.
	sky_note.text = SKY_NOTE
	sky_note.visible = not has_background and not _fixed_scale
	sky_note.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_KEEP_SIZE, 16)
	sky_note.grow_vertical = Control.GROW_DIRECTION_BEGIN
	sky_note.add_theme_font_size_override("font_size", 13)
	sky_note.add_theme_color_override("font_color", Color(1.0, 0.7, 0.4, 0.85))
	layer.add_child(sky_note)
	add_child(layer)


func _apply_state() -> void:
	var s: Dictionary = sim.world["ship"]
	var c: Dictionary = sim.world["clock"]
	var beta: float = s["beta"]
	var h: Dictionary = s["heading"]
	heading = Vector3(h["x"], h["y"], h["z"])
	starfield.set_velocity(heading, beta, s["gamma"])
	if has_background:
		background.set_velocity(heading, beta, s["gamma"])
	var x: float = s["x"]
	var p: Dictionary = s["pos"]
	starfield.set_ship_position(p["x"], p["y"], p["z"]) # float64; the starfield rebases (M1.3)
	hud.text = "beta  %.6f c\ngamma %.4f\nship  %.3f yr\nEarth %.3f yr\ntravelled %.3f ly\nwarp %.2f ship-yr/s\n%s" % [
		beta, s["gamma"], c["tau"], c["t"], x, warp, camera.hud_line(heading)]


func _process(delta: float) -> void:
	if _map_mode or _user_args().has("capture") or _user_args().has("golden") or _user_args().has("bench"):
		return
	var look := Input.get_axis("ui_right", "ui_left")
	var tilt := Input.get_axis("ui_down", "ui_up")
	var spin := (1.0 if Input.is_key_pressed(KEY_Q) else 0.0) - (1.0 if Input.is_key_pressed(KEY_E) else 0.0)
	camera.turn_by(look * delta * LOOK_RATE, tilt * delta * LOOK_RATE, spin * delta * LOOK_RATE)
	_accum += delta
	var dt := 1.0 / TICK_HZ
	while _accum >= dt:
		_accum -= dt
		var thrust := 0.0
		if Input.is_key_pressed(KEY_W): thrust += 1.0
		if Input.is_key_pressed(KEY_S): thrust -= 1.0
		if sim.send([{"k": "thrust", "thrust": thrust}], warp * dt):
			_apply_state()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event.pressed:
		return
	if UiScale.is_zoom_event(event): # Cmd/Ctrl + / - / 0: UI size, never warp
		if not _fixed_scale:
			UiScale.handle(get_window(), event)
		get_viewport().set_input_as_handled()
		return
	if _map_mode:
		return
	match event.keycode:
		KEY_1: camera.look(0.0, 0.0, 0.0)
		KEY_2: camera.look(-PI / 2, 0.0, 0.0)
		KEY_3: camera.look(PI, 0.0, 0.0)
		KEY_4: camera.look(0.0, FreeLookCamera.PITCH_LIMIT, 0.0)
		KEY_EQUAL: warp *= 2.0
		KEY_MINUS: warp /= 2.0


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		sim.stop()


func _grab() -> Image:
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()


## Accelerate at 1 g through the AILANG sim and photograph the sky at set speeds.
func _run_capture(dir: String) -> void:
	var out := _out_dir(dir)
	var targets := [0.0, 0.5, 0.9, 0.99]
	# [yaw, pitch, roll]; M1.6b adds an off-axis view and a rolled one (R-a); M1.3 adds port
	# (galactic l = 270: Canopus, alpha Cen, Sirius, the LMC once the bright tier is on)
	var views := {"forward": [0.0, 0.0, 0.0], "starboard": [-PI / 2, 0.0, 0.0], "port": [PI / 2, 0.0, 0.0], "astern": [PI, 0.0, 0.0],
		"offaxis": [deg_to_rad(50.0), deg_to_rad(25.0), 0.0], "rolled": [deg_to_rad(-30.0), deg_to_rad(10.0), deg_to_rad(35.0)]}
	var tiles := []
	for target in targets:
		while sim.world["ship"]["beta"] < target:
			if not sim.send([{"k": "thrust", "thrust": 1.0}], 0.005):
				push_error("capture: sim stopped (%s)" % sim.last_error)
				get_tree().quit(2)
				return
		_apply_state()
		for view in views:
			camera.look(views[view][0], views[view][1], views[view][2])
			_apply_state() # the HUD's view/v line follows the view
			var img := await _grab()
			var name := "sky_b%s_%s.png" % [str(target).replace(".", ""), view]
			img.save_png(out.path_join(name))
			tiles.append(img)
			var ship: Dictionary = sim.world["ship"]
			print("captured %s  beta=%.6f gamma=%.4f tau=%.4f t=%.4f  %s" % [name, ship["beta"], ship["gamma"], sim.world["clock"]["tau"], sim.world["clock"]["t"], camera.hud_line(heading)])
	_save_sheet(tiles, views.size(), out.path_join("contact_sheet.png"))
	sim.stop()
	get_tree().quit(0)


func _save_sheet(tiles: Array, cols: int, path: String) -> void:
	var w: int = tiles[0].get_width() / 2
	var h: int = tiles[0].get_height() / 2
	var rows := int(ceil(tiles.size() / float(cols)))
	var sheet := Image.create(w * cols, h * rows, false, Image.FORMAT_RGBA8)
	for i in tiles.size():
		var t: Image = tiles[i].duplicate()
		t.convert(Image.FORMAT_RGBA8)
		t.resize(w, h, Image.INTERPOLATE_LANCZOS)
		sheet.blit_rect(t, Rect2i(0, 0, w, h), Vector2i((i % cols) * w, (i / cols) * h))
	sheet.save_png(path)


## Render single synthetic stars and check the GPU puts them where the CPU
## reference (Relativity.aberrate + camera projection) says they should be.
func _run_golden() -> void:
	starfield.set_custom_stars([])
	starfield.build()
	starfield.set_exposure(EXPOSURE)
	camera.look(0.0, 0.0, 0.0)
	var cases := [
		{"label": "at rest, 20 deg starboard", "theta": 20.0, "beta": 0.0},
		{"label": "90 deg starboard at 0.9c -> 25.84 deg", "theta": 90.0, "beta": 0.9},
		{"label": "60 deg starboard at 0.9c -> 15.09 deg", "theta": 60.0, "beta": 0.9},
		{"label": "120 deg starboard at 0.99c", "theta": 120.0, "beta": 0.99},
		{"label": "150 deg starboard at 0.999c", "theta": 150.0, "beta": 0.999},
		{"label": "behind camera at rest must not render", "theta": 180.0, "beta": 0.0, "hidden": true},
		{"label": "astern at 0.5c stays astern, not drawn", "theta": 170.0, "beta": 0.5, "hidden": true},
		{"label": "looking astern at 0.99c: K star 178.5 deg is redshifted to ~330 K, invisible", "theta": 178.5, "beta": 0.99, "hidden": true, "yaw": PI, "t": 4500.0},
		{"label": "looking astern at 0.99c: 50,000 K star at 178.5 deg is dim red", "theta": 178.5, "beta": 0.99, "yaw": PI, "t": 50000.0},
	]
	var failures := 0
	for c in cases:
		var th := deg_to_rad(c["theta"])
		var n := Vector3(sin(th), 0.0, -cos(th)) # galaxy frame, starboard = +X
		camera.look(c.get("yaw", 0.0), 0.0, 0.0)
		starfield.set_custom_stars([{"name": "test", "pos": n * 1000.0, "t": c.get("t", 5700.0), "flux": 1.0}])
		starfield.set_ship_position(0.0, 0.0, 0.0)
		var b: float = c["beta"]
		starfield.set_velocity(HEADING, b, 1.0 / sqrt(1.0 - b * b))
		var img := await _grab()
		if c.get("hidden", false):
			var peak := _peak(img)
			var hidden_ok := peak < 0.01
			if not hidden_ok: failures += 1
			print("%s  %-40s peak luminance %.4f (must be ~0)" % ["ok  " if hidden_ok else "FAIL", c["label"], peak])
			continue
		var expected_dir := Relativity.aberrate(n, HEADING, b)
		var expected := camera.unproject_position(expected_dir * 100.0)
		var got := _centroid(img)
		var err := got.distance_to(expected)
		var ok := err < 0.75
		if not ok: failures += 1
		print("%s  %-40s expected (%.2f, %.2f)  rendered (%.2f, %.2f)  error %.3f px  apparent angle %.3f deg" % [
			"ok  " if ok else "FAIL", c["label"], expected.x, expected.y, got.x, got.y, err,
			rad_to_deg(acos(expected_dir.dot(HEADING)))])
	failures += await _golden_offaxis()
	failures += await _golden_standoff(1000.0, 300.0)
	failures += await _golden_standoff(0.3, 0.2)
	failures += await _golden_cull()
	starfield.set_custom_stars([])
	starfield.set_ship_position(0.0, 0.0, 0.0)
	failures += await _golden_background_marker()
	failures += await _golden_background_colour()
	failures += await _golden_background_tint()
	failures += await _golden_hot_white_dwarf()
	print("golden: %d failures" % failures)
	get_tree().quit(1 if failures > 0 else 0)


## AC5 (stars, M1.6b): 12 star directions x 4 speeds x 3 camera orientations
## (one rolled, two off-axis), velocity along (1,1,-1)/sqrt3. Each star is
## placed so it APPEARS on a 4 x 3 grid of the view (deaberrated from the
## grid point), rendered alone, and its GPU centroid must land within 0.75 px
## of the CPU reference: Relativity.aberrate, then the camera's float64
## pinhole projection (FreeLookCamera.project, from the same yaw/pitch/roll
## the GPU view matrix comes from). The rest temperature is set so the star is
## seen at 5700 K and its flux so it renders at unit brightness at every
## speed (positions only; colour and beaming are AC6 and the physics tests).
func _golden_offaxis() -> int:
	var size := get_viewport().get_visible_rect().size
	var failures := 0
	var worst := 0.0
	var count := 0
	for view in GOLDEN_VIEWS:
		var yaw: float = atan2(-OFF_AXIS.x, -OFF_AXIS.z) if view[1] == null else deg_to_rad(view[1])
		var pitch: float = asin(OFF_AXIS.y) if view[2] == null else deg_to_rad(view[2])
		camera.look(yaw, pitch, deg_to_rad(view[3]))
		for b: float in [0.0, 0.5, 0.9, 0.99]:
			for ay: float in [-20.0, 0.0, 20.0]:
				for ax: float in [-36.0, -12.0, 12.0, 36.0]:
					var aim := camera.to_world(Vector3(tan(deg_to_rad(ax)), tan(deg_to_rad(ay)), -1.0).normalized())
					var n := Relativity.deaberrate(aim, OFF_AXIS, b)
					var d := Relativity.doppler(n, OFF_AXIS, b)
					var t := 5700.0 / d
					starfield.set_custom_stars([{"name": "test", "pos": n * 1000.0, "t": t, "flux": 1.0 / Relativity.point_flux_ratio(t, d)}])
					starfield.set_ship_position(0.0, 0.0, 0.0)
					starfield.set_velocity(OFF_AXIS, b, Relativity.gamma_of(b))
					var img := await _grab()
					var expected := camera.project(Relativity.aberrate(n, OFF_AXIS, b), size)
					var got := _centroid(img)
					var err := got.distance_to(expected)
					worst = maxf(worst, err)
					count += 1
					var ok := err < 0.75
					if not ok: failures += 1
					print("%s  off-axis %-28s beta %.2f aim (%+3.0f, %+3.0f) deg  D %7.4f  expected (%.2f, %.2f)  rendered (%.2f, %.2f)  error %.3f px" % [
						"ok  " if ok else "FAIL", view[0], b, ax, ay, d, expected.x, expected.y, got.x, got.y, err])
	print("off-axis golden: %d cases (12 directions x 4 speeds x %d orientations), worst error %.3f px (limit 0.75), %d failures" % [count, GOLDEN_VIEWS.size(), worst, failures])
	return failures


## M1.3 rebasing on the GPU: alpha Cen A (SIMBAD l 315.734, b -0.680, 4.37 ly)
## from the 1,000 AU stand-off (300 AU off the Sol line), in both rebase modes,
## at rest and 0.9c. The centroid must land within 0.75 px of the float64 CPU
## direction (Starfield.direction_to, aberrated) through the camera projection;
## the camera looks 8 deg to the side of the star so it is off the centre.
## At 1,000 AU this checks the projection, not the hi/lo pair (float32 from Sol
## is only ~1e-3 px off there), so a second geometry at ~0.36 AU makes the shader's
## lo terms matter: there float32 positions from Sol alone land >= 1.5 px off (2x the tolerance)
## (computed here per case and required, so the case keeps its power), and the
## GPU must still be within 0.75 px.
func _golden_standoff(along_au: float, side_au: float) -> int:
	var size := get_viewport().get_visible_rect().size
	var l := deg_to_rad(315.734)
	var b_gal := deg_to_rad(-0.680)
	var g := [4.37 * cos(b_gal) * cos(l), 4.37 * cos(b_gal) * sin(l), 4.37 * sin(b_gal)]
	var star := [g[1], g[2], -g[0]]
	var au := 1.0 / 63241.07708426628
	var u := [star[0] / 4.37, star[1] / 4.37, star[2] / 4.37]
	var sn := sqrt(u[2] * u[2] + u[0] * u[0])
	var ship := [star[0] - u[0] * along_au * au + u[2] / sn * side_au * au, star[1] - u[1] * along_au * au, star[2] - u[2] * along_au * au - u[0] / sn * side_au * au]
	var r2 := 0.0
	for a in 3:
		r2 += (star[a] - ship[a]) ** 2
	var failures := 0
	for mode in [Starfield.Rebase.GPU, Starfield.Rebase.CPU]:
		for b: float in [0.0, 0.9]:
			starfield.set_rebase_mode(mode)
			starfield.set_custom_stars([{"pos": star, "t": 5790.0, "flux": 1.0}])
			starfield.set_ship_position(ship[0], ship[1], ship[2])
			var d64 := starfield.direction_to(0)
			var n := Vector3(d64[0], d64[1], d64[2])
			var d := Relativity.doppler(n, HEADING, b)
			# unit brightness at the ship: undo |p|^2 / r^2 and the beaming
			var p2: float = star[0] * star[0] + star[1] * star[1] + star[2] * star[2]
			starfield.set_custom_stars([{"pos": star, "t": 5790.0, "flux": maxf(r2, 1e-6) / p2 / Relativity.point_flux_ratio(5790.0, d)}])
			starfield.set_ship_position(ship[0], ship[1], ship[2])
			starfield.set_velocity(HEADING, b, Relativity.gamma_of(b))
			var app := Relativity.aberrate(n, HEADING, b)
			camera.look(atan2(-app.x, -app.z) + deg_to_rad(8.0), asin(app.y), 0.0)
			var img := await _grab()
			var expected := camera.project(app, size)
			var got := _centroid(img)
			var err := got.distance_to(expected)
			# the same frame with float32 positions from Sol and no lo terms (what a shader dropping lo computes)
			var naive := Vector3(Starfield.f32(Starfield.f32(star[0]) - Starfield.f32(ship[0])), Starfield.f32(Starfield.f32(star[1]) - Starfield.f32(ship[1])), Starfield.f32(Starfield.f32(star[2]) - Starfield.f32(ship[2])))
			var naive_err := camera.project(Relativity.aberrate(naive.normalized(), HEADING, b), size).distance_to(expected)
			var ok := err < 0.75 and (along_au > 100.0 or naive_err >= 1.5)
			if not ok: failures += 1
			print("%s  stand-off alpha Cen A %s beta %.1f (%.1f AU, origin %.4f ly from ship)  expected (%.2f, %.2f)  rendered (%.2f, %.2f)  error %.3f px  (float32 from Sol, no lo: %.2f px off)" % [
				"ok  " if ok else "FAIL", Starfield.Rebase.keys()[mode], b, sqrt(r2) / au, Starfield._dist(starfield.origin, starfield.ship), expected.x, expected.y, got.x, got.y, err, naive_err])
	starfield.set_rebase_mode(Starfield.Rebase.GPU)
	starfield.set_velocity(HEADING, 0.0, 1.0)
	return failures


## M1.3 faint-star cull: with the production tonemapper (AgX + glow) a star
## whose linear splat peak is 2x the shader's cull_peak, drawn with the cull
## off, must still render as pure black (every 8-bit channel 0), so culling
## below cull_peak loses nothing on screen.
func _golden_cull() -> int:
	var cull: float = Starfield.CULL_PEAK
	starfield.material.set_shader_parameter("cull_peak", 0.0)
	camera.look(0.0, 0.0, 0.0)
	starfield.set_velocity(HEADING, 0.0, 1.0)
	starfield.set_custom_stars([{"pos": Vector3(0.1, 0.05, -1.0).normalized() * 1000.0, "t": 5700.0, "flux": 2.0 * cull / EXPOSURE}])
	starfield.set_ship_position(0.0, 0.0, 0.0)
	var img := await _grab()
	var top := 0.0
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			top = maxf(top, maxf(c.r, maxf(c.g, c.b)))
	# and a star 40x brighter (peak 8e-3) must show, so the frame is live
	starfield.set_custom_stars([{"pos": Vector3(0.1, 0.05, -1.0).normalized() * 1000.0, "t": 5700.0, "flux": 80.0 * cull / EXPOSURE}])
	var live := _peak(await _grab())
	starfield.material.set_shader_parameter("cull_peak", cull)
	var ok := top * 255.0 < 0.5 and live > 0.0
	print("%s  faint-star cull: peak 2 x cull_peak (%s) renders max channel %.1f/255 (must be 0); 80 x renders %.4f (must be > 0)" % [
		"ok  " if ok else "FAIL", str(cull), top * 255.0, live])
	return 0 if ok else 1


## M1.3 (O-1): a 60 kK white dwarf dead ahead at 0.999c (D = 44.71, seen at
## 2.68 MK, beyond the old 1e6 K LUT end) with flux 1/pointFluxRatio(T, D) must
## render with the same integrated luminance as a unit star at rest (6000 K),
## within 2%, and with the CPU chromaticity of rgb(T D) within 0.01. Linear
## tonemapper, no glow; both splats sit on the same pixel.
func _golden_hot_white_dwarf() -> int:
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.glow_enabled = false
	env.background_mode = Environment.BG_COLOR # drop the previous goldens' synthetic sky
	env.background_color = Color.BLACK
	camera.look(0.0, 0.0, 0.0)
	var n := HEADING
	var k := 0.04 # splat peak ~0.2: no channel clips
	starfield.set_custom_stars([{"pos": n * 1000.0, "t": 6000.0, "flux": k}])
	starfield.set_ship_position(0.0, 0.0, 0.0)
	starfield.set_velocity(HEADING, 0.0, 1.0)
	var ref := _window_sum(await _grab())
	var b := 0.999
	var d := Relativity.doppler(n, HEADING, b)
	var t := 60000.0
	starfield.set_custom_stars([{"pos": n * 1000.0, "t": t, "flux": k / Relativity.point_flux_ratio(t, d)}])
	starfield.set_velocity(HEADING, b, Relativity.gamma_of(b))
	var hot := _window_sum(await _grab())
	starfield.set_velocity(HEADING, 0.0, 1.0)
	var y_ref := 0.2126729 * ref.x + 0.7151522 * ref.y + 0.0721750 * ref.z
	var y_hot := 0.2126729 * hot.x + 0.7151522 * hot.y + 0.0721750 * hot.z
	var want := _xy(Blackbody.rgb_unit_luminance(t * d))
	var dxy := _xy(hot).distance_to(want)
	# the unit star integrates to ~peak 0.2 x 2 pi sigma^2 (5.1 px^2) = 1.0
	var ok := y_ref > 0.5 and absf(y_hot / y_ref - 1.0) < 0.02 and dxy < 0.01
	print("%s  hot white dwarf 60 kK at D %.2f (seen %.0f K): unit star sum %.3f, luminance / unit star %.4f (want 1 +- 0.02)  xy (%.4f, %.4f) want (%.4f, %.4f) dxy %.4f" % [
		"ok  " if ok else "FAIL", d, t * d, y_ref, y_hot / y_ref, _xy(hot).x, _xy(hot).y, want.x, want.y, dxy])
	return 0 if ok else 1


## Linear RGB summed over a 21 x 21 window at the frame centre.
func _window_sum(img: Image) -> Vector3:
	var c := Vector3.ZERO
	var cx := img.get_width() / 2
	var cy := img.get_height() / 2
	for yy in range(cy - 10, cy + 11):
		for xx in range(cx - 10, cx + 11):
			var p := img.get_pixel(xx, yy).srgb_to_linear()
			c += Vector3(p.r, p.g, p.b)
	return c


## AC5 (background): one bright texel of a synthetic panorama must land within
## 1 px of aberrate(texel-centre direction), at 4 speeds x 4 views (forward,
## starboard, astern and, since M1.6b, a pitched and rolled view).
func _golden_background_marker() -> int:
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.glow_enabled = false
	var w := 2048
	var h := 1024
	var t_code := SkyModel.encode_t(6000.0)
	var failures := 0
	for b: float in [0.0, 0.5, 0.9, 0.99]:
		for view: Array in [[0.0, 0.0, 0.0], [-PI / 2, 0.0, 0.0], [PI, 0.0, 0.0], [deg_to_rad(-40.0), deg_to_rad(20.0), deg_to_rad(50.0)]]:
			camera.look(view[0], view[1], view[2])
			# aim 10 deg right and 6 deg up of the view centre, in the camera frame
			var aim := camera.to_world(Basis.from_euler(Vector3(deg_to_rad(6.0), deg_to_rad(-10.0), 0)) * Vector3(0, 0, -1))
			var uv := SkyModel.equirect_uv(Relativity.deaberrate(aim, HEADING, b))
			var tx := clampi(int(uv.x * w), 0, w - 1)
			var ty := clampi(int(uv.y * h), 0, h - 1)
			var n := SkyModel.equirect_dir(Vector2((tx + 0.5) / w, (ty + 0.5) / h))
			var photo := Image.create(w, h, false, Image.FORMAT_RGB8)
			photo.set_pixel(tx, ty, Color.WHITE)
			var model := Image.create(w, h, false, Image.FORMAT_RGBA8)
			model.fill(Color8(t_code, 0, 0, 255))
			var sb := SkyBackground.new()
			sb.attach(env, get_viewport().get_visible_rect().size.y, camera.fov, photo, model)
			var g := Relativity.gamma_of(b)
			sb.set_velocity(HEADING, b, g)
			var d := Relativity.doppler(n, HEADING, b)
			# a mip-averaged texel is dimmer by about (2^lod)^2; normalise so the peak lands near 1
			sb.set_exposure(4.0 * pow(maxf(d, 1.0), 2.0) / Relativity.surface_brightness_ratio(SkyModel.decode_t(t_code), d))
			var img := await _grab()
			var expected := camera.project(Relativity.aberrate(n, HEADING, b), get_viewport().get_visible_rect().size)
			var got := _centroid(img)
			var err := got.distance_to(expected)
			var ok := err < 1.0
			if not ok: failures += 1
			print("%s  background marker beta %.2f view %4.0f deg pitch %3.0f roll %3.0f  expected (%.2f, %.2f)  rendered (%.2f, %.2f)  error %.3f px" % [
				"ok  " if ok else "FAIL", b, rad_to_deg(view[0]), rad_to_deg(view[1]), rad_to_deg(view[2]), expected.x, expected.y, got.x, got.y, err])
	return failures


## AC6: a uniform Planck-coloured sky at T renders with the chromaticity of
## rgb(D T) (linear tonemapper) within 0.01, at D = 0.3, 1 and 3 (beta 0.9).
func _golden_background_colour() -> int:
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.glow_enabled = false
	var b := 0.9
	var g := Relativity.gamma_of(b)
	var t_code := SkyModel.encode_t(5000.0)
	var t := SkyModel.decode_t(t_code)
	var rgb := Blackbody.rgb_unit_luminance(t) * 0.2
	var photo := Image.create(64, 32, false, Image.FORMAT_RGB8)
	photo.fill(Color(rgb.x, rgb.y, rgb.z).linear_to_srgb())
	var model := Image.create(64, 32, false, Image.FORMAT_RGBA8)
	model.fill(Color8(t_code, 0, 0, 255))
	var sb := SkyBackground.new()
	sb.attach(env, get_viewport().get_visible_rect().size.y, camera.fov, photo, model)
	sb.set_velocity(HEADING, b, g)
	var failures := 0
	for d: float in [0.3, 1.0, 3.0]:
		var theta := acos((1.0 - 1.0 / (d * g)) / b) # apparent angle where dopplerApparent = d
		camera.look(-theta, 0.0, 0.0)
		var want := Blackbody.rgb_unit_luminance(t * d)
		var y_seen := 0.2 * Relativity.surface_brightness_ratio(t, d)
		sb.set_exposure(0.6 / (y_seen * maxf(want.x, maxf(want.y, want.z))))
		var img := await _grab()
		var c := Vector3.ZERO
		var cx := img.get_width() / 2
		var cy := img.get_height() / 2
		for yy in range(cy - 4, cy + 5):
			for xx in range(cx - 4, cx + 5):
				var p := img.get_pixel(xx, yy).srgb_to_linear()
				c += Vector3(p.r, p.g, p.b) / 81.0
		var err := _xy(c).distance_to(_xy(want))
		var ok := err < 0.01
		if not ok: failures += 1
		print("%s  background colour D %.1f (T %.0f K -> %.0f K)  xy rendered (%.4f, %.4f) want (%.4f, %.4f)  dxy %.4f" % [
			"ok  " if ok else "FAIL", d, t, t * d, _xy(c).x, _xy(c).y, _xy(want).x, _xy(want).y, err])
	return failures


## Tint carry: an off-locus (emission-pink) texel must render with the
## chromaticity SkyModel.radiance predicts, at D = 1 (= the photo) and D = 3.
func _golden_background_tint() -> int:
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.glow_enabled = false
	var b := 0.9
	var g := Relativity.gamma_of(b)
	var t_code := SkyModel.encode_t(4000.0)
	var t := SkyModel.decode_t(t_code)
	var pink := Color8(200, 60, 110) # off the Planck locus, like an H II region
	var lin := Vector3(pink.srgb_to_linear().r, pink.srgb_to_linear().g, pink.srgb_to_linear().b)
	var photo := Image.create(64, 32, false, Image.FORMAT_RGB8)
	photo.fill(pink)
	var model := Image.create(64, 32, false, Image.FORMAT_RGBA8)
	model.fill(Color8(t_code, 0, 0, 255))
	var sb := SkyBackground.new()
	sb.attach(env, get_viewport().get_visible_rect().size.y, camera.fov, photo, model)
	sb.set_velocity(HEADING, b, g)
	var failures := 0
	for d: float in [1.0, 3.0]:
		camera.look(-acos((1.0 - 1.0 / (d * g)) / b), 0.0, 0.0)
		var want := SkyModel.radiance(lin, t, d)
		sb.set_exposure(0.6 / maxf(want.x, maxf(want.y, want.z)))
		var img := await _grab()
		var c := Vector3.ZERO
		var cx := img.get_width() / 2
		var cy := img.get_height() / 2
		for yy in range(cy - 4, cy + 5):
			for xx in range(cx - 4, cx + 5):
				var p := img.get_pixel(xx, yy).srgb_to_linear()
				c += Vector3(p.r, p.g, p.b) / 81.0
		var err := _xy(c).distance_to(_xy(want))
		var ok := err < 0.01
		if not ok: failures += 1
		print("%s  background tint (off-locus texel) D %.1f  xy rendered (%.4f, %.4f) want (%.4f, %.4f)  dxy %.4f" % [
			"ok  " if ok else "FAIL", d, _xy(c).x, _xy(c).y, _xy(want).x, _xy(want).y, err])
	return failures


## CIE xy of a linear sRGB colour (IEC 61966-2-1).
func _xy(c: Vector3) -> Vector2:
	var x := 0.4124564 * c.x + 0.3575761 * c.y + 0.1804375 * c.z
	var y := 0.2126729 * c.x + 0.7151522 * c.y + 0.0721750 * c.z
	var z := 0.0193339 * c.x + 0.1191920 * c.y + 0.9503041 * c.z
	return Vector2(x, y) / (x + y + z)


func _peak(img: Image) -> float:
	var peak := 0.0
	for y in img.get_height():
		for x in img.get_width():
			peak = maxf(peak, img.get_pixel(x, y).get_luminance())
	return peak


## Intensity-weighted centroid of pixels above half the peak (sub-pixel).
func _centroid(img: Image) -> Vector2:
	var peak := _peak(img)
	var sum := Vector2.ZERO
	var wsum := 0.0
	for y in img.get_height():
		for x in img.get_width():
			var l := img.get_pixel(x, y).get_luminance()
			if l >= peak * 0.5:
				sum += Vector2(x + 0.5, y + 0.5) * l
				wsum += l
	return sum / wsum if wsum > 0.0 else Vector2(-1, -1)
