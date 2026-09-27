extends Node3D
## Spike: AILANG ship sim (sidecar) + relativistic starfield (Godot).
##
## Interactive:  W / S thrust forward / reverse at 1 g, arrows look around,
##               1-4 look forward / starboard / astern / up, +/- time warp.
## Headless-ish checks (need a GPU window, not --headless):
##   godot --path . -- --capture=renders   scripted voyage, PNG per speed/view
##   godot --path . -- --golden            shader vs CPU reference positions

const TICK_HZ := 20.0
const HEADING := Vector3(0, 0, -1) # galactic centre
const EXPOSURE := 5.0

var sim := SimBridge.new()
var starfield := Starfield.new()
var camera := Camera3D.new()
var hud := Label.new()
var yaw := 0.0
var pitch := 0.0
var warp := 0.2 # ship-years per real second
var _accum := 0.0
var _last_pos_update := 0.0


func _ready() -> void:
	_build_scene()
	var args := _user_args()
	if args.has("golden"):
		await _run_golden()
		return
	starfield.load_catalogue("res://data/stars.json")
	starfield.build()
	starfield.set_exposure(EXPOSURE)
	if not sim.start():
		get_tree().quit(2)
		return
	_apply_state()
	if args.has("capture"):
		await _run_capture(args["capture"])


func _user_args() -> Dictionary:
	var out := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		out[kv[0]] = kv[1] if kv.size() > 1 else ""
	return out


func _build_scene() -> void:
	var env := Environment.new()
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
	var layer := CanvasLayer.new()
	hud.position = Vector2(16, 12)
	hud.add_theme_font_size_override("font_size", 16)
	layer.add_child(hud)
	add_child(layer)


func _apply_state() -> void:
	var s := sim.state
	var beta: float = s["beta"]
	starfield.set_velocity(HEADING, beta, s["gamma"])
	var x: float = s["x"]
	if absf(x - _last_pos_update) > 0.01:
		starfield.set_ship_position(HEADING * x)
		_last_pos_update = x
	hud.text = "beta  %.6f c\ngamma %.4f\nship  %.3f yr\nEarth %.3f yr\ntravelled %.3f ly\nwarp %.2f ship-yr/s" % [
		beta, s["gamma"], s["tau"], s["t"], x, warp]


func _process(delta: float) -> void:
	if _user_args().has("capture") or _user_args().has("golden"):
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
		if sim.step(thrust, warp * dt):
			_apply_state()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event.pressed:
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
	var out := ProjectSettings.globalize_path("res://").path_join(dir if dir != "" else "renders")
	DirAccess.make_dir_recursive_absolute(out)
	var targets := [0.0, 0.5, 0.9, 0.99]
	var views := {"forward": Vector3(0, 0, 0), "starboard": Vector3(0, -PI / 2, 0), "astern": Vector3(0, PI, 0)}
	var tiles := []
	for target in targets:
		while sim.state["beta"] < target:
			sim.step(1.0, 0.005)
		_apply_state()
		for view in views:
			camera.rotation = views[view]
			var img := await _grab()
			var name := "sky_b%s_%s.png" % [str(target).replace(".", ""), view]
			img.save_png(out.path_join(name))
			tiles.append(img)
			print("captured %s  beta=%.6f gamma=%.4f tau=%.4f t=%.4f" % [name, sim.state["beta"], sim.state["gamma"], sim.state["tau"], sim.state["t"]])
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
	print("golden: %d failures" % failures)
	get_tree().quit(1 if failures > 0 else 0)


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
