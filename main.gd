extends Node3D
## Spike: AILANG ship sim (sidecar) + relativistic starfield (Godot).
##
## Interactive:  W / S thrust forward / reverse at 1 g, arrows look around,
##               1-4 look forward / starboard / astern / up, +/- time warp.
## Galaxy map:  godot --path . [-- --map[=INDEX]]   (default with no arguments; M2.6a/b; --map-capture=renders [--map-commit])
## Sky flight:  godot --path . -- --voyage   (the M0/M1 relativistic voyage; WASD thrust, 1-4 views, +/- warp)
## Headless-ish checks (need a GPU window, not --headless):
##   godot --path . -- --capture=renders   scripted voyage, PNG per speed/view
##   godot --path . -- --golden            shader vs CPU reference positions
## Any run:  -- --record=path.ndjson  tees the sim's input log (replays headless).
## Interactive runs: Cmd/Ctrl + / - / 0 change the UI size (UiScale; HiDPI aware).
##
## The sim runs a protocol v2 diag session (seed 0, scenario "sol"): the ship
## is flown with `heading` and `thrust` intents and drawn from the bridge's
## mirrored world.

const TICK_HZ := 20.0
const HEADING := Vector3(0, 0, -1) # galactic centre
const EXPOSURE := 5.0
const BG_EXPOSURE := 0.075 # hand-set ratio to the stars until M1.5 calibrates both
const SEED := 0
const ALPHA_CEN_A := 1 # stars.json index 1 (Gl 559, vmag 0.01); B is index 2 with the same id

var sim := SimBridge.new()
var starfield := Starfield.new()
var background := SkyBackground.new()
var has_background := false
var env := Environment.new()
var camera := Camera3D.new()
var hud := Label.new()
var yaw := 0.0
var pitch := 0.0
var warp := 0.2 # ship-years per real second
var _accum := 0.0
var _last_pos_update := Vector3.ZERO
var _map_mode := false
var _fixed_scale := false # captures / goldens: no HiDPI stretch, no UI zoom, no sky note
var sky_note := Label.new()
const SKY_NOTE := "sky background not bundled in this build"


func _ready() -> void:
	var args := _user_args()
	# Captures and goldens keep the 1:1 unstretched window (their PNGs and pixel
	# maths are pinned); interactive runs scale the UI for HiDPI (UiScale).
	_fixed_scale = args.has("capture") or args.has("map-capture") or args.has("golden")
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
	starfield.load_catalogue("res://data/starmap/stars.json")
	starfield.build()
	starfield.set_exposure(EXPOSURE)
	sim.record_path = args.get("record", "")
	var course := {"k": "heading", "heading": {"x": HEADING.x, "y": HEADING.y, "z": HEADING.z}}
	if not sim.start() or not sim.new_game(SEED, "sol", true) or not sim.send([course], 0.0):
		push_error("sim session failed: %s" % sim.last_error)
		get_tree().quit(2)
		return
	_apply_state()
	if args.has("capture"):
		await _run_capture(args["capture"])


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
	var heading := Vector3(h["x"], h["y"], h["z"])
	starfield.set_velocity(heading, beta, s["gamma"])
	if has_background:
		background.set_velocity(heading, beta, s["gamma"])
	var x: float = s["x"]
	var p: Dictionary = s["pos"]
	var pos := Vector3(p["x"], p["y"], p["z"])
	if pos.distance_to(_last_pos_update) > 0.01:
		starfield.set_ship_position(pos)
		_last_pos_update = pos
	hud.text = "beta  %.6f c\ngamma %.4f\nship  %.3f yr\nEarth %.3f yr\ntravelled %.3f ly\nwarp %.2f ship-yr/s" % [
		beta, s["gamma"], c["tau"], c["t"], x, warp]


func _process(delta: float) -> void:
	if _map_mode or _user_args().has("capture") or _user_args().has("golden"):
		return
	var look := Input.get_axis("ui_right", "ui_left")
	var tilt := Input.get_axis("ui_down", "ui_up")
	yaw += look * delta * 1.2
	pitch = clampf(pitch + tilt * delta * 1.2, -1.5, 1.5)
	camera.rotation = Vector3(pitch, yaw, 0)
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
		KEY_1: yaw = 0.0; pitch = 0.0
		KEY_2: yaw = -PI / 2; pitch = 0.0
		KEY_3: yaw = PI; pitch = 0.0
		KEY_4: yaw = 0.0; pitch = PI / 2 - 0.01
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
	var views := {"forward": Vector3(0, 0, 0), "starboard": Vector3(0, -PI / 2, 0), "astern": Vector3(0, PI, 0)}
	var tiles := []
	for target in targets:
		while sim.world["ship"]["beta"] < target:
			if not sim.send([{"k": "thrust", "thrust": 1.0}], 0.005):
				push_error("capture: sim stopped (%s)" % sim.last_error)
				get_tree().quit(2)
				return
		_apply_state()
		for view in views:
			camera.rotation = views[view]
			var img := await _grab()
			var name := "sky_b%s_%s.png" % [str(target).replace(".", ""), view]
			img.save_png(out.path_join(name))
			tiles.append(img)
			var ship: Dictionary = sim.world["ship"]
			print("captured %s  beta=%.6f gamma=%.4f tau=%.4f t=%.4f" % [name, ship["beta"], ship["gamma"], sim.world["clock"]["tau"], sim.world["clock"]["t"]])
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
	camera.rotation = Vector3.ZERO
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
		camera.rotation = Vector3(0, c.get("yaw", 0.0), 0)
		starfield.set_custom_stars([{"name": "test", "pos": n * 1000.0, "t": c.get("t", 5700.0), "flux": 1.0}])
		starfield.set_ship_position(Vector3.ZERO)
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
	starfield.set_custom_stars([])
	starfield.set_ship_position(Vector3.ZERO)
	failures += await _golden_background_marker()
	failures += await _golden_background_colour()
	failures += await _golden_background_tint()
	print("golden: %d failures" % failures)
	get_tree().quit(1 if failures > 0 else 0)


## AC5 (background): one bright texel of a synthetic panorama must land within
## 1 px of aberrate(texel-centre direction), at 4 speeds x 3 views.
func _golden_background_marker() -> int:
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.glow_enabled = false
	var w := 2048
	var h := 1024
	var t_code := SkyModel.encode_t(6000.0)
	var failures := 0
	for b: float in [0.0, 0.5, 0.9, 0.99]:
		for view: float in [0.0, -PI / 2, PI]:
			camera.rotation = Vector3(0, view, 0)
			# aim 10 deg right and 6 deg up of the view centre, in the ship frame
			var aim := Basis.from_euler(Vector3(deg_to_rad(6.0), view - deg_to_rad(10.0), 0)) * Vector3(0, 0, -1)
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
			var expected := camera.unproject_position(Relativity.aberrate(n, HEADING, b) * 100.0)
			var got := _centroid(img)
			var err := got.distance_to(expected)
			var ok := err < 1.0
			if not ok: failures += 1
			print("%s  background marker beta %.2f view %4.0f deg  expected (%.2f, %.2f)  rendered (%.2f, %.2f)  error %.3f px" % [
				"ok  " if ok else "FAIL", b, rad_to_deg(view), expected.x, expected.y, got.x, got.y, err])
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
		camera.rotation = Vector3(0, -theta, 0)
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
		camera.rotation = Vector3(0, -acos((1.0 - 1.0 / (d * g)) / b), 0)
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
