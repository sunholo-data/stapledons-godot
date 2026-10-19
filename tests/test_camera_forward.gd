extends SceneTree
## R2-CAMERA-FORWARD (design_docs/planned/r2/camera-forward.md, D-91, D-92): make camera-forward-test.
##   AC-B1  one named map per frame (the grep gate and its positive control live in the recipe)
##   AC-B2  R is a proper rotation: the structure's bow (+Y) -> kinematic +Z, the mast (+Z) -> +Y;
##          the composite maps agree with their literals
##   AC-V1  Bow and Astern hold one yaw over the 16-sample bridge walk
##   AC-V2  in Bow the pole and the 0.9c / 0.99c starbow edges are in frame (40 px margin)
##   AC-V3  after the fades the pole ray and the line to the captain are clear; the eye is free
##   AC-V4  the captain 60-80 px at 720p; at least half the frame below the horizon
##   AC-V5  W up-screen and D right in Bow and Astern
##   AC-V7  the envelope slides the eye (the angle is kept); the eye stays above its deck
##   AC-V10 the lift's arrival selects the level default (bridge Bow, the Commons legacy Z2)
##   AC-V11 the same scripted inputs give bit-identical poses
##   AC-V12 a fade changes no sky uniform and no sim input
## Prints `ok    <name>` / `FAIL  <name>: <why>` and `camera-forward: <n> passed, <m> failures`.
## Time is the director's fake clock (advance(dt) through the demo's _process); no wall-clock reads.

const PX := Vector2(1280, 720)
const ANGLES := 8
const RADII := [10.0, 17.0]
const DT := 1.0 / 60.0
## relativity-spec §2: a rest-frame 90 deg star appears at acos(beta) from the pole.
const STARBOW := {"0.9c": 25.842, "0.99c": 8.1}
const MARGIN := 40.0
var failures := 0
var passes := 0


func check(label: String, ok: bool, why := "") -> void:
	if ok:
		passes += 1
		print("ok    %s" % label)
	else:
		failures += 1
		print("FAIL  %s: %s" % [label, why])


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	test_basis()
	var demo: Node = await new_demo()
	await test_walk(demo)
	test_envelope(demo)
	test_fade_untouched(demo)
	test_keys(demo)
	test_level_default(demo)
	demo.queue_free()
	await process_frame
	await test_determinism()
	print("camera-forward: %d passed, %d failures" % [passes, failures])
	quit(1 if failures else 0)


func new_demo(opts := {}) -> Node:
	var demo: Node = load("res://demos/ship_geometry_demo.tscn").instantiate()
	var o := {"stars": false, "background": false, "sky_state": "rest", "size": Vector2i(PX)}
	o.merge(opts, true)
	demo.setup_options = o
	root.add_child(demo)
	await process_frame
	await physics_frame
	await physics_frame
	demo.auto = false
	demo.journey_auto_tick = false
	demo.escape_exits = false
	return demo


# ------------------------------------------------------------------ AC-B2

func test_basis() -> void:
	var cols := [ShipFrame.r_from_structure([1.0, 0.0, 0.0]), ShipFrame.r_from_structure([0.0, 1.0, 0.0]), ShipFrame.r_from_structure([0.0, 0.0, 1.0])]
	var b := PackedFloat64Array()
	for c: Array in cols:
		b.append_array(PackedFloat64Array(c))
	var ortho := true
	for i in 3:
		for j in 3:
			var d: float = cols[i][0] * cols[j][0] + cols[i][1] * cols[j][1] + cols[i][2] * cols[j][2]
			ortho = ortho and absf(d - (1.0 if i == j else 0.0)) < 1e-15
	var bow: Array = ShipFrame.r_from_structure([0.0, 1.0, 0.0])
	var mast: Array = ShipFrame.r_from_structure([0.0, 0.0, 1.0])
	# composite: ship_vector(g) == R(structure_from_gltf(g)), and its inverse, at a few probes
	var composite := true
	for g: Vector3 in [Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1), Vector3(0.3, -2.0, 5.5)]:
		var k: Array = ShipCamera.ship_vector(g)
		var r: Array = ShipFrame.r_from_structure(ShipFrame.structure_from_gltf(g))
		composite = composite and absf(k[0] - r[0]) + absf(k[1] - r[1]) + absf(k[2] - r[2]) < 1e-12
		composite = composite and ShipCamera.gltf_from_ship(k).distance_to(g) < 1e-6
		composite = composite and ShipFrame.gltf_from_structure(ShipFrame.structure_from_gltf(g)).distance_to(g) < 1e-6
	# literals: the bow is glTF -Z, kinematic +Z; the mast glTF +Y, kinematic +Y
	var lit: bool = ShipCamera.ship_vector(Vector3.FORWARD) == [0.0, 0.0, 1.0] and ShipCamera.ship_vector(Vector3.UP) == [0.0, 1.0, 0.0] and ShipCamera.BOW == Vector3.FORWARD
	check("basis R proper bow->+Z mast->+Y", ortho and is_equal_approx(ShipFrame.det(b), 1.0) and bow == [0.0, 0.0, 1.0] and mast == [0.0, 1.0, 0.0] and composite and lit,
		"ortho %s det %s bow %s mast %s composite %s literals %s" % [ortho, ShipFrame.det(b), bow, mast, composite, lit])


# ------------------------------------------------------------------ the walk

## The 16 bridge walk samples (8 angles x radii 10 m and 17 m), snapped to the walk surface.
func samples(demo: Node) -> Array:
	var out := []
	for r: float in RADII:
		for i in ANGLES:
			var a := TAU * float(i) / ANGLES
			var foot: Variant = demo.walk_bridge.closest_walkable(Vector3(r * cos(a), 82.0, r * sin(a)), 4.0)
			if foot is Vector3:
				out.append(foot)
	return out


## Teleport the captain and let the camera settle (the follow, the fades: 0.5 s of play).
func settle(demo: Node, foot: Vector3) -> Transform3D:
	demo.consoles.cancel_walk()
	demo.avatar_pos = foot
	for k in 30:
		demo._process(DT)
	return demo.camera.global_transform


## Let a view switch's ease finish (a 180 deg switch eases for 3 s at <= 90 deg/s).
func ease_out(demo: Node) -> void:
	var guard := 0
	while demo.director.blending() and guard < 600:
		demo._process(DT)
		guard += 1


func in_frame(p: Vector2) -> bool:
	return not is_nan(p.x) and Rect2(Vector2(MARGIN, MARGIN), PX - Vector2(2.0 * MARGIN, 2.0 * MARGIN)).has_point(p)


func test_walk(demo: Node) -> void:
	var pts := samples(demo)
	check("walk samples 16", pts.size() == 16, "%d" % pts.size())
	var dir: CameraDirector = demo.director
	var counts := {"pole": 0, "starbow_0.9c": 0, "starbow_0.99c": 0, "pole_ray": 0, "captain": 0, "eye_free": 0}
	var figs := []
	var horizon := []
	var above := 0
	var why := []
	for id: String in ["bow", "astern"]:
		dir.walk(id)
		ease_out(demo)
		var yaws := []
		for foot: Vector3 in pts:
			var pose := settle(demo, foot)
			var yp := CameraDirector.yaw_pitch(pose)
			yaws.append(rad_to_deg(yp.x))
			if pose.origin.y >= foot.y + CameraDirector.DECK_CLEAR_M - 1e-6:
				above += 1
			if id != "bow":
				continue
			var eye := pose.origin
			var pole := CameraDirector.screen_point(pose, eye + CameraDirector.pole_dir() * 1000.0, PX)
			counts["pole"] += int(in_frame(pole))
			for k: String in STARBOW:
				var a := deg_to_rad(float(STARBOW[k]))
				var edge := CameraDirector.screen_point(pose, eye + Vector3(0.0, sin(a), -cos(a)) * 1000.0, PX)
				counts["starbow_" + k] += int(in_frame(edge))
			var clear: Dictionary = dir.clear_after_fades(pose, foot)
			for k: String in clear:
				counts[k] += int(clear[k])
				if not clear[k]:
					why.append("%s blocked at %s (fading %s)" % [k, foot, dir.occ_fading.map(func(n): return str(n.name))])
			figs.append(CameraDirector.figure_px(pose, foot, 1.6, PX.y))
			horizon.append(pole.y)
		var spread := 0.0
		for a: float in yaws:
			for b: float in yaws:
				spread = maxf(spread, absf(wrapf(a - b, -180.0, 180.0)))
		check("yaw constant %s spread=%.4f deg over %d" % [id, spread, yaws.size()], spread <= 0.1 and yaws.size() == 16, "spread %.3f" % spread)
	for k: String in ["pole", "starbow_0.9c", "starbow_0.99c"]:
		check("in frame bow %s %d/16" % [k, counts[k]], counts[k] == 16, "%d of 16" % counts[k])
	for k: String in ["pole_ray", "captain", "eye_free"]:
		check("clear after fades bow %s %d/16" % [k, counts[k]], counts[k] == 16, "; ".join(why.filter(func(s): return s.begins_with(k))))
	var lo: float = figs.min() if not figs.is_empty() else 0.0
	var hi: float = figs.max() if not figs.is_empty() else 0.0
	check("captain px bow %.0f..%.0f" % [lo, hi], lo >= 60.0 and hi <= 80.0, "%.1f..%.1f" % [lo, hi])
	var deck: float = (PX.y - float(horizon.max())) / PX.y if not horizon.is_empty() else 0.0
	check("deck fraction bow %.2f" % deck, deck >= 0.5, "%.3f" % deck)
	check("eye above deck at %d samples" % above, above == 32, "%d of 32" % above)
	dir.walk("bow")


# ------------------------------------------------------------------ AC-V7

func test_envelope(demo: Node) -> void:
	var dir: CameraDirector = demo.director
	var v: Dictionary = dir.views["bow"]
	var far := Vector3(0.0, 82.0, -60.0) # the eye would sit 101 m out
	var pose := dir.walk_pose(v, far)
	var yp := CameraDirector.yaw_pitch(pose)
	var want := Vector2(deg_to_rad(float(v.yaw_deg)), deg_to_rad(float(v.pitch_deg)))
	var angle_kept := absf(wrapf(yp.x - want.x, -PI, PI)) < 1e-6 and absf(yp.y - want.y) < 1e-6
	check("envelope keeps the angle", pose.origin.length() <= 95.0 + 1e-4 and angle_kept and absf(pose.origin.y - (far.y + float(v.rise_m))) < 1e-4,
		"|eye| %.3f angle kept %s eye y %.3f" % [pose.origin.length(), angle_kept, pose.origin.y])


# ------------------------------------------------------------------ AC-V12

func _sky_snapshot(demo: Node) -> String:
	var sky: InteriorSky = demo.sky
	var out := [var_to_str(sky.cam), var_to_str(sky.basis), var_to_str(sky.heading_gal), var_to_str(demo.sky_world)]
	for p: String in ["cam_ship", "ship_x", "ship_y", "ship_z"]:
		out.append(var_to_str(sky.glow_mat.get_shader_parameter(p)))
		out.append(var_to_str(sky.dust_mat.get_shader_parameter(p)))
	return "|".join(out)


func test_fade_untouched(demo: Node) -> void:
	var dir: CameraDirector = demo.director
	# Stand where the spire crosses the journey (sternward of it): the needle must fade.
	var foot: Variant = demo.walk_bridge.closest_walkable(Vector3(0.0, 82.0, 10.0), 4.0)
	var before := ""
	var faded := false
	var sky_same := false
	if foot is Vector3:
		settle(demo, foot)
		before = _sky_snapshot(demo)
		var cam: Transform3D = demo.camera.global_transform
		# re-run the occluder pass alone (same pose): only transparency may change
		dir._update_occluders(true, foot, 1.0)
		faded = not dir.occ_fading.is_empty() and dir.occ_fading.all(func(n): return is_equal_approx((n as GeometryInstance3D).transparency, 1.0 - CameraDirector.OCC_ALPHA))
		sky_same = _sky_snapshot(demo) == before and demo.camera.global_transform == cam
	check("fade leaves sky and sim untouched", faded and sky_same, "faded %s sky/sim/pose same %s" % [faded, sky_same])


# ------------------------------------------------------------------ AC-V5 (Bow, Astern)

func test_keys(demo: Node) -> void:
	var dir: CameraDirector = demo.director
	var start: Variant = demo.walk_bridge.closest_walkable(Vector3(8.0, 82.0, 8.0), 4.0)
	for id: String in ["bow", "astern"]:
		dir.walk(id)
		ease_out(demo)
		for key: String in ["W", "D"]:
			demo.walk_motion(Vector2.ZERO, DT) # the keys released: a held key keeps its world direction (D2)
			var pose := settle(demo, start)
			var move := Vector2(0, 1) if key == "W" else Vector2(1, 0)
			var a := CameraDirector.screen_point(pose, demo.avatar_pos, PX)
			for k in 30:
				demo.walk_motion(move, DT)
			var b := CameraDirector.screen_point(pose, demo.avatar_pos, PX)
			var d := b - a
			var ok := (d.y < -20.0 and absf(d.x) < 0.3 * absf(d.y)) if key == "W" else (d.x > 20.0 and absf(d.y) < 0.3 * absf(d.x))
			check("%s %s %s" % [key, "up-screen" if key == "W" else "right", id], ok, "screen motion %s from %s (%s -> %s, eye %s)" % [d, a, start, demo.avatar_pos, pose.origin])
	dir.walk("bow")


# ------------------------------------------------------------------ AC-V10

func test_level_default(demo: Node) -> void:
	var dir: CameraDirector = demo.director
	dir.walk("astern")
	settle(demo, Vector3(8, 82, -4.8))
	# ride the lift down and back: each arrival selects the level's default
	demo.avatar_pos = Vector3(8, 82, -4.8)
	var boarded: bool = demo.lift.board()
	var guard := 0
	while demo.lift.travelling() and guard < 2000:
		demo.lift.advance(DT)
		demo._process(DT)
		guard += 1
	demo._process(DT)
	check("level default commons", boarded and demo.active_level == 1 and dir.view_id == "z2_lower", "boarded %s level %d view %s" % [boarded, demo.active_level, dir.view_id])
	boarded = demo.lift.board()
	guard = 0
	while demo.lift.travelling() and guard < 2000:
		demo.lift.advance(DT)
		demo._process(DT)
		guard += 1
	demo._process(DT)
	check("level default bridge", boarded and demo.active_level == 0 and dir.view_id == "bow" and dir.deck_view == "bow", "boarded %s level %d view %s" % [boarded, demo.active_level, dir.view_id])


# ------------------------------------------------------------------ AC-V11

func _script(demo: Node) -> PackedStringArray:
	var out := PackedStringArray()
	var dir: CameraDirector = demo.director
	demo.avatar_pos = Vector3(8, 82, -4.8)
	for i in 600:
		var move := Vector2.ZERO
		if i < 150:
			move = Vector2(0, 1)
		elif i < 260:
			move = Vector2(1, 0.5)
		elif i < 300:
			move = Vector2.ZERO
		elif i < 420:
			move = Vector2(-1, -1)
		if i == 300:
			dir.walk("astern")
		if i == 450:
			dir.walk("bow")
		demo.walk_motion(move, DT)
		demo._process(DT)
		out.append(var_to_str(demo.camera.global_transform))
	return out


func test_determinism() -> void:
	var a: Node = await new_demo()
	var ra := _script(a)
	a.queue_free()
	await process_frame
	var b: Node = await new_demo()
	var rb := _script(b)
	b.queue_free()
	await process_frame
	check("deterministic poses 600 steps", ra.size() == 600 and ra == rb, "%d vs %d poses, first differing at %d" % [ra.size(), rb.size(), _first_diff(ra, rb)])


func _first_diff(a: PackedStringArray, b: PackedStringArray) -> int:
	for i in mini(a.size(), b.size()):
		if a[i] != b[i]:
			return i
	return -1
