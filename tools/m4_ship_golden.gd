extends RefCounted
## M4.6gR3: the actual ship composite, captain camera and sim-sourced glow.
## Loaded last by main.gd; tools/ is excluded from exports.
const PROBE := "res://.godot/tmp/m4-physics-probe.txt"
const REVIEW := "res://assets/ship_demo/sky_review.json"
const SCENE := "res://demos/ship_geometry_demo.tscn"
const WIN := 12

var main: Node
var demo: Node
var size := Vector2i.ZERO
var states := {}
var poles := {}
var cap := {}


func run(m: Node) -> int:
	main = m
	size = main.get_window().size
	var references_ok := _load_references()
	var built := false
	if references_ok:
		built = await _build(false)
	var failures := await _s3(built)
	failures += await _s4(built)
	await _free_demo()
	built = false
	if references_ok:
		built = await _build(true)
	failures += await _s2(built)
	await _free_demo()
	print("m4 ship golden: %d failures" % failures)
	return failures


## Strictly parse the two stop rows, not the older `glow cap` (1e-6) row.
## No default value can turn absent, duplicate, malformed or invalid data into a pass.
func _parse_probe(source: String) -> Dictionary:
	var rows := {}
	var labels := ["phi", "load", "drag", "glow", "pole", "T", "lum"]
	for line in source.split("\n"):
		var words := line.strip_edges().replace("\t", " ").split(" ", false)
		if words.size() < 2 or words[0] != "stop" or words[1] not in ["sun", "guided-cap-2e-9"]:
			continue
		if rows.has(words[1]) or words.size() != 16:
			return {}
		var row := {}
		for i in labels.size():
			var token: String = words[3 + 2 * i]
			if words[2 + 2 * i] != labels[i] or not token.is_valid_float():
				return {}
			var value := token.to_float()
			if not is_finite(value) or value <= 0.0:
				return {}
			row[labels[i]] = value
		rows[words[1]] = row
	return rows if rows.size() == 2 else {}


func _positive(value: Variant) -> bool:
	return (value is float or value is int) and is_finite(float(value)) and float(value) > 0.0


func _valid_world(world: Variant) -> bool:
	if not world is Dictionary or not world.get("ship") is Dictionary or not world.get("params") is Dictionary:
		return false
	var ship: Dictionary = world.ship
	for field in ["heading", "pos", "ism"]:
		if not ship.get(field) is Dictionary:
			return false
	for field in ["heading", "pos"]:
		for axis in ["x", "y", "z"]:
			var value: Variant = ship[field].get(axis)
			if not (value is float or value is int) or not is_finite(float(value)):
				return false
	var h: Dictionary = ship.heading
	if not _positive(float(h.x) * float(h.x) + float(h.y) * float(h.y) + float(h.z) * float(h.z)):
		return false
	for field in ["beta", "gamma", "one_minus_beta"]:
		var value: Variant = ship.get(field)
		if not (value is float or value is int) or not is_finite(float(value)):
			return false
	for field in ["glow_pole_w_m2", "glow_pole_k"]:
		var value: Variant = ship.ism.get(field)
		if not (value is float or value is int) or not is_finite(float(value)) or float(value) < 0.0:
			return false
	return _positive(world.params.get("bubble_radius_m")) and ship.beta >= 0.0 and ship.beta < 1.0 and ship.gamma >= 1.0 and ship.one_minus_beta > 0.0


func _load_references() -> bool:
	var path := ProjectSettings.globalize_path(PROBE)
	if not FileAccess.file_exists(path) or not FileAccess.file_exists(REVIEW):
		push_warning("m4 ship golden: missing probe or sky_review.json")
		return false
	poles = _parse_probe(FileAccess.get_file_as_string(path))
	var review: Variant = JSON.parse_string(FileAccess.get_file_as_string(REVIEW))
	if poles.is_empty() or not review is Dictionary or not review.get("states") is Dictionary:
		push_warning("m4 ship golden: invalid/missing/duplicate probe rows or review states")
		return false
	states = review.states
	if not _valid_world(states.get("cruise")) or not _valid_world(states.get("rest")):
		return false
	var recorded: Variant = states.cruise.ship.ism.get("glow_pole_w_m2")
	if not _positive(recorded) or absf(float(recorded) - float(poles.sun.pole)) > 1e-9 * float(poles.sun.pole):
		push_warning("m4 ship golden: probe 0.99c pole disagrees with recorded sim world")
		return false
	if not _positive(states.cruise.ship.ism.get("glow_pole_k")) or states.cruise.ship.beta != 0.99 or states.rest.ship.beta != 0.0:
		return false
	if states.rest.ship.ism.glow_pole_w_m2 != 0.0 or states.rest.ship.ism.glow_pole_k != 0.0:
		return false
	# Check the probe labels' speeds through the existing float64 mirrors, too.
	if absf(Relativity.beta_of_rapidity(poles.sun.phi) - 0.99) > 1e-12 or absf(Relativity.one_minus_beta_of_rapidity(poles["guided-cap-2e-9"].phi) / 2e-9 - 1.0) > 1e-9:
		return false
	cap = _phase_world("cruising", poles["guided-cap-2e-9"].phi)
	cap.ship.ism.glow_pole_w_m2 = poles["guided-cap-2e-9"].pole
	cap.ship.ism.glow_pole_k = poles["guided-cap-2e-9"].T
	return true


func _phase_world(phase: String, phi: float) -> Dictionary:
	var world: Dictionary = states.cruise.duplicate(true)
	world.ship.phase = phase
	world.ship.beta = Relativity.beta_of_rapidity(phi)
	world.ship.gamma = Relativity.gamma_of_rapidity(phi)
	world.ship.one_minus_beta = Relativity.one_minus_beta_of_rapidity(phi)
	return world


func _hide_hud(node: Node) -> void:
	if node is CanvasLayer and node.layer >= 0:
		node.visible = false
	for child in node.get_children():
		_hide_hud(child)


func _build(background: bool) -> bool:
	var scene: PackedScene = load(SCENE)
	if scene == null or not scene.can_instantiate():
		return false
	demo = scene.instantiate()
	if demo == null:
		return false
	demo.setup_options = {"size": size, "stars": background, "background": background, "sky_state": "cruise"}
	main.add_child(demo)
	await main.get_tree().process_frame
	demo.auto = false
	demo.journey_auto_tick = false
	demo.set_process(false) # exposure and observer uploads are driven only by these cases
	_hide_hud(demo)
	if not demo.ready_ok or demo.sky == null or demo.camera == null:
		return false
	demo.sky.dust_auto = false
	demo.sky.upload_dust([])
	return true


func _free_demo() -> void:
	if is_instance_valid(demo):
		demo.queue_free()
		await main.get_tree().process_frame
	demo = null


func _world(world: Dictionary) -> bool:
	demo.sky_states["golden"] = world
	return demo.set_sky_state("golden")


func _pose(tilt: float, yaw: float) -> void:
	demo.camera.follow(demo.avatar_pos, tilt, yaw, 0.0)
	demo._sync_observer()


func _cam() -> Dictionary:
	var cam: Dictionary = demo.sky.cam.duplicate(true)
	cam["fov_vertical_deg"] = demo.sky.view_fov
	cam["resolution"] = [size.x, size.y]
	return cam


func _settle() -> void:
	for i in 3:
		await main.get_tree().process_frame
	await RenderingServer.frame_post_draw


func _read(viewport: Viewport) -> Image:
	var texture := viewport.get_texture()
	return texture.get_image() if texture != null else null


func _image_ok(img: Image) -> bool:
	return img != null and not img.is_empty() and img.get_size() == size


func _window_ok(c: Vector2) -> bool:
	return is_finite(c.x) and is_finite(c.y) and c.x >= WIN and c.y >= WIN and c.x + WIN < size.x and c.y + WIN < size.y


## Half-peak, luminance-weighted centroid; keep sums in float64, not Vector2.
func _centroid(img: Image, c: Vector2) -> Array:
	if not _image_ok(img) or not _window_ok(c):
		return [Vector2(-1, -1), NAN, 0.0]
	var peak := 0.0
	for y in range(int(c.y) - WIN, int(c.y) + WIN + 1):
		for x in range(int(c.x) - WIN, int(c.x) + WIN + 1):
			var l := img.get_pixel(x, y).get_luminance()
			if not is_finite(l):
				return [Vector2(-1, -1), NAN, 0.0]
			peak = maxf(peak, l)
	var sx := 0.0
	var sy := 0.0
	var weight := 0.0
	for y in range(int(c.y) - WIN, int(c.y) + WIN + 1):
		for x in range(int(c.x) - WIN, int(c.x) + WIN + 1):
			var l := img.get_pixel(x, y).get_luminance()
			if l >= peak * 0.5:
				sx += (x + 0.5) * l
				sy += (y + 0.5) * l
				weight += l
	return [Vector2(sx / weight, sy / weight) if weight > 0.0 else Vector2(-1, -1), peak, weight]


func _report(ok: bool, message: String) -> int:
	print("%s  %s" % ["ok  " if ok else "FAIL", message])
	return 0 if ok else 1


func _s3(built: bool) -> int:
	var failures := 0
	for phase: String in ["boosting", "cruising", "braking"]:
		var phi := Relativity.rapidity_of_beta(0.99 if phase == "cruising" else 0.5)
		var b := Relativity.beta_of_rapidity(phi)
		var want := Vector2(-1, -1)
		var got := Vector2(-1, -1)
		var error := INF
		var ok := false
		if built and _world(_phase_world(phase, phi)):
			_pose(89.99, 0.0)
			demo.sky.starfield.set_custom_stars([])
			# Independent of the rendered sky camera (D1 perturbs that camera).
			want = demo.camera.unproject_position(demo.camera.global_position + Vector3.UP * 1000.0)
			var cam := _cam()
			var p: Array = cam.position_m
			var projected := AreaBundle.project(cam, [p[0], p[1], float(p[2]) + 1000.0])
			var cross_error := sqrt(pow(projected[0] - want.x, 2.0) + pow(projected[1] - want.y, 2.0))
			await _settle()
			var clean := _centroid(_read(main.get_viewport()), want)
			var geometry := _read(demo.geometry_view)
			var clear: bool = _window_ok(want) and _image_ok(geometry) and is_finite(clean[1]) and clean[1] < 0.02
			if clear:
				clear = geometry.get_pixel(int(want.x), int(want.y)).a == 0.0
			if clear and is_finite(cross_error) and cross_error <= 0.001:
				var h: Dictionary = demo.sky_world.ship.heading
				var heading := SkyFrame.to_world64([h.x, h.y, h.z])
				var vw := Vector3(heading[0], heading[1], heading[2]).normalized()
				var n := Relativity.deaberrate(vw, vw, b)
				var d := Relativity.doppler(n, vw, b)
				var t := 5700.0 / d
				var sf: Starfield = demo.sky.starfield
				sf.set_custom_stars([{"name": "test", "pos": n * 1000.0, "t": t, "flux": 1.0 / Relativity.point_flux_ratio(t, d)}])
				sf.set_ship_position(0.0, 0.0, 0.0)
				sf.set_velocity(vw, demo.sky_world.ship.beta, demo.sky_world.ship.gamma)
				sf.set_exposure(5.0)
				await _settle()
				var centroid := _centroid(_read(main.get_viewport()), want)
				got = centroid[0]
				error = got.distance_to(want)
				ok = is_finite(centroid[2]) and centroid[2] > 0.0 and is_finite(error) and error <= 0.75
			elif not clear:
				push_warning("m4 ship golden: %s forward pole covered (geometry or clean peak)" % phase)
		failures += _report(ok, "G-M4-S3 forward pole (ship) %s beta %.2f: captain eye pole (%.2f, %.2f) rendered (%.2f, %.2f) error %.3f px (limit 0.75)" % [phase, b, want.x, want.y, got.x, got.y, error])
	return failures


func _s2(built: bool) -> int:
	var n := 0
	var lit := 0
	var ship := 0
	var worst := INF
	if built:
		var sky: InteriorSky = demo.sky
		if not sky.has_background:
			var photo := Image.create(256, 128, false, Image.FORMAT_RGB8)
			for y in 128:
				for x in 256:
					photo.set_pixel(x, y, Color(x / 255.0, y / 127.0, 0.5))
			var model := Image.create(256, 128, false, Image.FORMAT_RGBA8)
			model.fill(Color8(SkyModel.encode_t(6000.0), 0, 0, 255))
			sky.has_background = sky.background.attach(sky.env, size.y, sky.view_fov, photo, model)
		if sky.has_background and _world(_phase_world("cruising", Relativity.rapidity_of_beta(0.99))):
			_pose(30.0, 0.47)
			await _settle()
			var frame := _read(main.get_viewport())
			var sub := _read(sky)
			var geometry := _read(demo.geometry_view)
			if _image_ok(frame) and _image_ok(sub) and _image_ok(geometry):
				frame.convert(Image.FORMAT_RGBA8)
				sub.convert(Image.FORMAT_RGBA8)
				worst = 0.0
				for j in 24:
					for i in 40:
						var x := int((i + 0.5) * size.x / 40.0)
						var y := int((j + 0.5) * size.y / 24.0)
						var alpha := geometry.get_pixel(x, y).a
						if not is_finite(alpha) or alpha < 0.0:
							worst = INF
							continue
						if alpha > 0.0:
							ship += 1
							continue
						var a := frame.get_pixel(x, y)
						var s := sub.get_pixel(x, y)
						worst = maxf(worst, maxf(absf(a.r - s.r), maxf(absf(a.g - s.g), absf(a.b - s.b))))
						n += 1
						if s.get_luminance() > 2.0 / 255.0:
							lit += 1
	var ok := n >= 500 and lit >= 50 and ship >= 20 and is_finite(worst) and worst <= 1.0 / 255.0 + 1e-6
	return _report(ok, "G-M4-S2 one tonemap (ship): %d sky-only pixels (%d lit, %d ship), worst |final - sky SubViewport| %.4f (limit 1/255 = 0.0039)" % [n, lit, ship, worst])


## Aim from the off-centre eye at R(sin theta cos alpha, sin theta sin alpha, cos theta).
## All wall/reference maths stays scalar float64 until camera.follow's render boundary.
func _unit_sample(world: Dictionary, theta: float) -> Dictionary:
	var result := {"valid": false, "got": NAN, "cos": NAN}
	if not _world(world):
		return result
	var p: Array = demo.sky.cam.position_m
	var alpha := atan2(float(p[1]), float(p[0]))
	var radius: float = demo.sky.radius_m
	var th := deg_to_rad(theta)
	var dx := radius * sin(th) * cos(alpha) - float(p[0])
	var dy := radius * sin(th) * sin(alpha) - float(p[1])
	var dz := radius * cos(th) - float(p[2])
	_pose(rad_to_deg(atan2(dz, sqrt(dx * dx + dy * dy))), atan2(-dy, dx))
	var cam := _cam()
	var position := PackedFloat64Array(cam.position_m)
	var x := size.x / 2
	var y := size.y / 2
	result.cos = ForwardGlow.wall_cos(position, AreaBundle.unproject(cam, x + 0.5, y + 0.5), radius)
	await _settle()
	var img := _read(demo.sky)
	if not _image_ok(img):
		return result
	if img.get_format() != 14: # FORMAT_RGBAH is required, including for the exact-zero rest.
		push_warning("m4 ship golden: unit target format %d, expected 14" % img.get_format())
		return result
	result.got = img.get_pixel(x, y).r
	result.valid = is_finite(result.got) and is_finite(result.cos)
	return result


func _s4(built: bool) -> int:
	var failures := 0
	if built:
		demo.sky.starfield.set_custom_stars([])
		demo.sky.set_debug_unit(true)
	for theta: float in [0.0, 45.0, 80.0]:
		var sample := {"valid": false, "got": NAN, "cos": NAN}
		var want := NAN
		if built:
			sample = await _unit_sample(cap, theta)
			want = ForwardGlow.profile(poles["guided-cap-2e-9"].pole, sample.cos)
		var ok: bool = sample.valid and _positive(want) and absf(sample.got - want) <= 0.01 * want and absf(sample.cos - cos(deg_to_rad(theta))) <= 0.005
		failures += _report(ok, "G-M4-S4 glow profile (ship) cap theta %2.0f deg: wall cos %.4f, unit-gain target %s W/m^2, CPU profile %s (limit 1 %%; format 14)" % [theta, sample.cos, String.num_scientific(sample.got), String.num_scientific(want)])
	for label: String in ["0.99c", "cap 1-beta 2e-9"]:
		var sample := {"valid": false, "got": NAN, "cos": NAN}
		var pole := NAN
		if built:
			var at_cap := label != "0.99c"
			pole = poles["guided-cap-2e-9" if at_cap else "sun"].pole
			sample = await _unit_sample(cap if at_cap else _phase_world("cruising", poles.sun.phi), 0.0)
		var ok: bool = sample.valid and _positive(pole) and sample.cos >= 0.9999 and absf(sample.got - pole) <= 0.01 * pole
		failures += _report(ok, "G-M4-S4 glow absolute (ship) %s: unit-gain pole %s W/m^2, sim ship.ism.glow_pole_w_m2 %s (limit 1 %%)" % [label, String.num_scientific(sample.got), String.num_scientific(pole)])
	var rest := {"valid": false, "got": NAN, "cos": NAN}
	if built:
		rest = await _unit_sample(states.rest, 0.0)
	failures += _report(rest.valid and rest.got == 0.0, "G-M4-S4 glow rest (ship): unit-gain target %s W/m^2 (exactly 0)" % String.num_scientific(rest.got))
	return failures
