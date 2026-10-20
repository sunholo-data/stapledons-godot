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
	failures += await _s4(built) # before any player pose: S4 aims from the captain's eye the S3 cases leave
	failures += await _cam1(built)
	if built:
		demo.sky.set_debug_unit(true) # G-CAM-2 reads the unit-gain target, as S4
	failures += await _cam2(built)
	await _free_demo()
	built = false
	if references_ok:
		built = await _build(true)
	failures += await _s2(built)
	failures += await _cam3(built)
	failures += await _tonemap(built, func() -> void: _walk_pose("bow", "spawn"), "G-CAM-3 one tonemap (Bow, 0.99c)", func() -> Dictionary: return _phase_world("cruising", Relativity.rapidity_of_beta(0.99)), 300)
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


## D-92: the captain's eye looking level along the direction of travel, the bow (glTF -z).
func _s3(built: bool) -> int:
	# A fixed observer (R2-DECK-LAYOUT: the pre-DL1 spawn; the new spawn stands behind the helm, whose
	# pods fill a 1.6 m eye's level view of the bow).
	return await _pole(built, func() -> void: demo.avatar_pos = Vector3(8, 82, -4.8); _pose(-0.01, -PI * 0.5), "G-M4-S3 forward pole (ship)", "captain eye")


## R2-CAMERA-FORWARD G-CAM-1: the forward pole through the player's Bow view (the eye 9 m behind
## the captain and 5.5 m up, pitch -8 deg, the pole above the frame centre), from three standing
## points: the bridge spawn, the helm (the navigation station's use point) and a port spot for
## Sgr A* (the ship holds its nose on the hole, so the hole is the forward pole; the harness has
## no sim, so this is the pose through flat space, not the lens), x 3 phases.
func _cam1(built: bool) -> int:
	var failures := 0
	if built:
		demo.sky.set_debug_unit(false) # S4 leaves the unit-gain glow target on
	for spot: String in ["spawn", "helm"]:
		failures += await _pole(built, func() -> void: _walk_pose("bow", spot), "G-CAM-1 forward pole (Bow, %s)" % spot, "Bow eye")
	failures += await _pole(built, func() -> void: _walk_pose("bow", "port"), "G-CAM-1 forward pole (Bow at Sgr A*, the hole on the pole)", "Bow eye")
	return failures


## A standing point on the bridge: the spawn (the manifest's), the helm (the navigation station's use point), a
## port spot clear of the spire and the bow rail (nearest the wall).
func _spot(spot: String) -> Vector3:
	match spot:
		"helm":
			return demo.consoles.stations["navigation"].use
		"port":
			return Vector3(-12, 82, 4)
		"rail":
			var r: Variant = demo.walk_bridge.closest_walkable(Vector3(0, 82, -19), 4.0)
			return r if r is Vector3 else Vector3(0, 82, -15)
	return demo.bridge_spawn() # R2-DECK-LAYOUT: the manifest's spawn (behind the helm)


## The director's walk view (Bow, Astern) settled on the captain at a spot (the render boundary;
## tools own the camera, so the slide anchor is the foot itself).
func _walk_pose(id: String, spot: String) -> void:
	var dir: CameraDirector = demo.director
	var foot := _spot(spot)
	demo.avatar_pos = foot
	demo.avatar.position = foot
	demo.camera.global_transform = dir.walk_pose(dir.views[id], foot)
	demo.avatar.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y # as the game stands the captain in walk views
	demo._sync_observer()


func _pole(built: bool, pose: Callable, label: String, eye_label: String) -> int:
	var failures := 0
	for phase: String in ["boosting", "cruising", "braking"]:
		var phi := Relativity.rapidity_of_beta(0.99 if phase == "cruising" else 0.5)
		var b := Relativity.beta_of_rapidity(phi)
		var want := Vector2(-1, -1)
		var got := Vector2(-1, -1)
		var error := INF
		var ok := false
		if built and _world(_phase_world(phase, phi)):
			pose.call()
			demo.sky.starfield.set_custom_stars([])
			# Independent of the rendered sky camera (D1 perturbs that camera).
			want = demo.camera.unproject_position(demo.camera.global_position + CameraDirector.pole_dir() * 1000.0)
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
				# FOV-sensitive: the design's 78 deg constant (CameraDirector.FOV_DEG), not the camera's
				# own fov, projects the pole on the CPU; the rendered pole must land there too.
				var want78 := CameraDirector.screen_point(demo.camera.global_transform, demo.camera.global_position + CameraDirector.pole_dir() * 1000.0, Vector2(size))
				error = maxf(error, got.distance_to(want78))
				ok = is_finite(centroid[2]) and centroid[2] > 0.0 and is_finite(error) and error <= 0.75
			elif not clear:
				push_warning("m4 ship golden: %s forward pole covered (geometry or clean peak)" % phase)
		failures += _report(ok, "%s %s beta %.2f: %s pole (%.2f, %.2f) rendered (%.2f, %.2f) error %.3f px (limit 0.75)" % [label, phase, b, eye_label, want.x, want.y, got.x, got.y, error])
	return failures


func _s2(built: bool) -> int:
	# D-92: the captain's eye 60 deg off the direction of travel, 20 deg above the deck's horizon
	# (the pre-D-92 pose looked 30 deg up, 60 deg from the pole straight overhead).
	return await _tonemap(built, func() -> void: _pose(20.0, deg_to_rad(212.1)), "G-M4-S2 one tonemap (ship)", func() -> Dictionary: return _phase_world("cruising", Relativity.rapidity_of_beta(0.99)), 500)


## R2-CAMERA-FORWARD G-CAM-3: the one-tonemap check through the player's walk views: Astern here, at
## rest (at 0.99c the aft sky is redshifted to black, so the cruise world would leave no lit sky
## pixel to compare; the tonemap path is the same in every state), and Bow at 0.99c (run()).
func _cam3(built: bool) -> int:
	return await _tonemap(built, func() -> void: _walk_pose("astern", "spawn"), "G-CAM-3 one tonemap (Astern, rest)", func() -> Dictionary: return states.rest, 300)


func _tonemap(built: bool, pose: Callable, label: String, world: Callable, min_sky: int) -> int:
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
		if sky.has_background and _world(world.call()):
			pose.call()
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
	var ok := n >= min_sky and lit >= 50 and ship >= 20 and is_finite(worst) and worst <= 1.0 / 255.0 + 1e-6
	return _report(ok, label + ": %d sky-only pixels (%d lit, %d ship), worst |final - sky SubViewport| %.4f (limit 1/255 = 0.0039)" % [n, lit, ship, worst])


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
	var g := ShipCamera.gltf_from_ship([dx, dy, dz]) # D-92: kinematic -> glTF through the one map
	_pose(rad_to_deg(atan2(g.y, sqrt(g.x * g.x + g.z * g.z))), atan2(g.z, g.x))
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


## R2-CAMERA-FORWARD G-CAM-2: the wall glow seen from the player's walk-view eyes (Bow at the
## spawn, at the bow rail nearest the wall and at the helm; Astern at the spawn), not the captain's
## eye. From each eye the camera looks at a wall ray chosen where this eye and the captain's differ;
## the wall point it sees and its polar cos come from ForwardGlow.wall_cos on the CPU (checked
## against the closed-form ray-sphere hit), and the rendered unit-gain glow must equal
## ForwardGlow.profile(sim pole, cos) within 1 %, at 0.99c and at the cap (1 - beta 2e-9).
func _cam2(built: bool) -> int:
	var failures := 0
	for id: String in ["bow@spawn", "bow@rail", "astern@spawn", "bow@helm"]:
		for label: String in ["0.99c", "cap 1-beta 2e-9"]:
			var at_cap := label != "0.99c"
			var pole := NAN
			var got := NAN
			var c := NAN
			var closed := NAN
			var eye_r := NAN
			var margin := NAN
			if built:
				pole = poles["guided-cap-2e-9" if at_cap else "sun"].pole
				if _world(cap if at_cap else _phase_world("cruising", poles.sun.phi)):
					var dir: CameraDirector = demo.director
					var parts := id.split("@")
					var foot := _spot(parts[1])
					var eye: Vector3 = dir.walk_pose(dir.views[parts[0]], foot).origin
					# Aim where the glow tells this eye from the captain's: of rays 20-65 deg off the
					# pole toward / away from the eye's azimuth, the one whose CPU profile from this eye
					# and from the captain's eye differ most (>= 5 %, so a shader that used the
					# captain's eye fails the 1 % limit).
					# (Kinematic frame throughout, +z the travel; glTF through ShipCamera's one map, D-92.)
					var best := [-1.0, CameraDirector.pole_dir()]
					var eye_k: Array = ShipCamera.ship_vector(eye)
					var az := atan2(float(eye_k[1]), float(eye_k[0]))
					var cap_eye: Array = ShipCamera.ship_vector(foot + Vector3.UP * 1.7)
					for th: float in [20.0, 40.0, 60.0, 80.0, 100.0, 120.0, 140.0, 160.0]:
						for k in 8:
							var a := az + k * PI / 4.0
							var ds := PackedFloat64Array([sin(deg_to_rad(th)) * cos(a), sin(deg_to_rad(th)) * sin(a), cos(deg_to_rad(th))])
							var d := ShipCamera.gltf_from_ship(ds)
							var w1 := ForwardGlow.profile(pole, ForwardGlow.wall_cos(PackedFloat64Array(eye_k), ds, demo.sky.radius_m))
							var w0 := ForwardGlow.profile(pole, ForwardGlow.wall_cos(PackedFloat64Array(cap_eye), ds, demo.sky.radius_m))
							# keep to glow the half-float target resolves (>= 1 % of the pole's)
							if _positive(w1) and w1 >= 0.01 * pole and absf(w1 - w0) / w1 > float(best[0]):
								best = [absf(w1 - w0) / w1, d]
					margin = float(best[0])
					var aim: Vector3 = best[1]
					demo.camera.global_transform = Transform3D(Basis.looking_at(aim, Vector3.FORWARD if absf(aim.y) > 0.99 else Vector3.UP), eye)
					demo._sync_observer()
					var cam := _cam()
					var position := PackedFloat64Array(cam.position_m)
					var radius: float = demo.sky.radius_m
					var ray := AreaBundle.unproject(cam, size.x / 2 + 0.5, size.y / 2 + 0.5)
					c = ForwardGlow.wall_cos(position, ray, radius)
					# Closed form: |p + t d| = R, t > 0; cos = (p + t d) . d / R (float64 scalars).
					var px := float(position[0]); var py := float(position[1]); var pz := float(position[2])
					var dx := float(ray[0]); var dy := float(ray[1]); var dz := float(ray[2])
					var dn := sqrt(dx * dx + dy * dy + dz * dz)
					dx /= dn; dy /= dn; dz /= dn
					var b := px * dx + py * dy + pz * dz
					var t := -b + sqrt(b * b - (px * px + py * py + pz * pz - radius * radius))
					closed = (pz + t * dz) / radius # the wall point's polar cos (ship +z is travel)
					eye_r = sqrt(px * px + py * py + pz * pz)
					await _settle()
					var img := _read(demo.sky)
					if _image_ok(img) and img.get_format() == 14:
						got = img.get_pixel(size.x / 2, size.y / 2).r
			var want := ForwardGlow.profile(pole, c) if is_finite(c) and _positive(pole) else NAN
			# The limit: 1 %, or 1.5 half-float subnormal steps (2^-24) where the 0.99c glow is below
			# the half-float normal range; the eye must matter 3x more than that limit.
			var tol: float = maxf(0.01 * want, 1.5 * pow(2.0, -24.0)) if is_finite(want) else NAN
			var ok: bool = is_finite(got) and _positive(want) and absf(got - want) <= tol and absf(c - closed) <= 1e-6 and eye_r <= 95.0 and c < 0.9999 and margin >= 0.05 and margin * want >= 3.0 * tol
			failures += _report(ok, "G-CAM-2 glow (%s eye, |eye| %.2f m) %s: wall cos %.5f (closed form %.5f), unit-gain %s W/m^2, CPU profile %s (limit %.2f %%; this eye vs the captain's eye differ %.1f %% there, >= 5 %% and 3x the limit)" % [id, eye_r, label, c, closed, String.num_scientific(got), String.num_scientific(want), 100.0 * tol / want if _positive(want) else NAN, margin * 100.0])
	return failures
