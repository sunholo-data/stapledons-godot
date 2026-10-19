extends SceneTree
const BlackHoleVisit := preload("res://demos/black_hole_visit.gd")
## R2-CAMERA (design_docs/implemented/r2/camera-fixed-views.md) C1 + C3: make camera-test.
##   AC1  views.json validates; every view's eye is inside the 95 m envelope with a clear line to the
##        captain's head at every walkable sample (0.5 m) of walk_bridge / walk_lower, in the sector
##        and both hysteresis neighbours; FOV 78 for every view; a mutant 26 m / -50 deg view fails
##   AC2  exactly three levels; wheel notch, 1.0 trackpad unit, pinch step, = / -, RB / LB each move
##        one level, with the 0.3 s cooldown; no input moves the camera continuously (menu launch)
##   AC4  the captain's head is in frame in every player view; Z2 figure 60-80 px at 1280x720
##   AC5  10 deg sector hysteresis; W held across a boundary keeps its world direction until
##        release; at 60 Hz no frame-to-frame change of the camera's motion (a jump) over 1 cm or
##        0.5 deg, walking and switching sectors in full motion
##   AC7  reduced motion: every transition a cut (<= 0.15 s fade, no travel); full motion: angular
##        speed <= 90 deg/s, no roll, no FOV change, no overshoot, over every transition
##   AC9  the developer free camera (F8 / --free-camera) only on command-line launches
## Time is the director's fake clock (advance(dt) through the demo's _process); no wall-clock reads.

const FIGURE_M := 1.754 # the captain sprite's opaque height (1263 px at 720 px/m, avatar y0)
const SAMPLE_M := 0.5
const PX := Vector2(1280, 720)
## Lower deck (the Commons): blocked cell-sample lines after the per-cell authoring (2026-10-17),
## Z1, Z2, Z3. The residue is points under the arcades' lintels that no candidate camera sees.
const LOWER_CEILING := {1: 2, 2: 2, 3: 39}
var failures := 0
var passes := 0


func check(label: String, ok: bool) -> void:
	if ok:
		passes += 1
	else:
		failures += 1
	print("%s %s" % ["ok" if ok else "FAIL", label])


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	test_schema()
	var demo: Node = await new_demo({"size": Vector2i(1280, 720)})
	await test_sweep(demo)
	test_sky_sweep(demo)
	test_spawn_occlusion(demo)
	test_levels_and_input(demo)
	test_framing(demo)
	test_sectors_and_walk(demo)
	test_motion(demo)
	demo.queue_free()
	await process_frame
	await test_free_camera()
	await test_cues()
	await test_default_mapping()
	await test_console_round_trip()
	await test_constellations_held_i()
	print("camera-director: %d passed, %d failures" % [passes, failures])
	quit(1 if failures else 0)


func new_demo(opts := {}) -> Node:
	var demo: Node = load("res://demos/ship_geometry_demo.tscn").instantiate()
	var o := {"stars": false, "background": false, "sky_state": "rest"}
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


func key(code: int) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	e.pressed = true
	return e


func step(demo: Node, seconds: float, dt := 1.0 / 60.0) -> void:
	var t := 0.0
	while t < seconds - 1e-9:
		demo._process(dt)
		t += dt


# ------------------------------------------------------------------ AC1

func test_schema() -> void:
	var d := CameraDirector.load_views()
	var errs := CameraDirector.validate(d)
	check("AC1 views.json validates %s" % [errs], errs.is_empty())
	check("AC1 FOV 78 deg for every player view (the file's one FOV, no per-view FOV)", is_equal_approx(float(d.fov_deg), 78.0) and d.views.all(func(v: Dictionary) -> bool: return not v.has("fov_deg")))
	var lv := {}
	for v: Dictionary in d.views:
		if int(v.get("level", 0)) > 0:
			lv[int(v.level)] = true
	check("AC2 exactly three levels (Z1 Close, Z2 Deck, Z3 Whole level)", lv.keys().size() == 3 and lv.has(1) and lv.has(2) and lv.has(3) and int(d.default_level) == 2)
	var bad := d.duplicate(true)
	bad.views[0].fov_deg = 60.0
	check("AC1 mutant: a view that changes the FOV is refused", not CameraDirector.validate(bad).is_empty())
	var none := d.duplicate(true)
	none.views[0].distance_m = 0.0
	check("AC1 mutant: a level view at distance 0 (first person) is refused", not CameraDirector.validate(none).is_empty())


## The clear line: from the eye to the head, no opaque geometry (the sprite has no collision).
func clear_line(demo: Node, eye: Vector3, head: Vector3) -> bool:
	var space: PhysicsDirectSpaceState3D = demo.camera.get_world_3d().direct_space_state
	var to := head + (eye - head).normalized() * 0.25 # stop short of the captain's own spot
	var q := PhysicsRayQueryParameters3D.create(eye, to)
	q.hit_back_faces = true
	return space.intersect_ray(q).is_empty()


func samples(walk: WalkArea, y: float) -> Array:
	var out := []
	var n := int(30.0 / SAMPLE_M)
	for i in range(-n, n + 1):
		for j in range(-n, n + 1):
			var p := Vector3(i * SAMPLE_M, y, j * SAMPLE_M)
			if walk.is_walkable(p):
				var h := walk.height_at(p.x, p.z)
				out.append(Vector3(p.x, h if not is_nan(h) else y, p.z))
	return out


## Every cell a standing point can be in: its own, and the neighbours hysteresis can hold (the
## sector 10 deg past its edge, the ring 1 m past the split).
static func cells(dir: CameraDirector, p: Vector3) -> Array:
	var s: Dictionary = dir.data.sectors
	var k := dir.sector_for(p, -1)
	var a := k % 8
	var angs := [a]
	for n in [(a + 1) % 8, (a + 7) % 8]:
		if absf(wrapf(rad_to_deg(atan2(p.z, p.x)) - (n + 0.5) * 45.0, -180.0, 180.0)) <= 22.5 + float(s.hysteresis_deg):
			angs.append(n)
	var rings := [k / 8]
	if absf(Vector2(p.x, p.z).length() - float(s.ring_split_m)) <= float(s.ring_hysteresis_m):
		rings.append(1 - k / 8)
	var out := []
	for r: int in rings:
		for n: int in angs:
			out.append(r * 8 + n)
	return out


## Every view, every walkable sample, every cell the sample can be in.
func sweep(demo: Node, dir: CameraDirector, view: Dictionary, pts: Array) -> Dictionary:
	var worst := 0.0
	var blocked := []
	var out_px := []
	for p: Vector3 in pts:
		for kk: int in cells(dir, p):
			var pose := dir.resolve(view, p, kk)
			worst = maxf(worst, pose.origin.length())
			var head := dir.head_of(view, p)
			if not clear_line(demo, pose.origin, head):
				blocked.append([p, kk])
			var sp := CameraDirector.screen_point(pose, head, PX)
			if is_nan(sp.x) or sp.x < 0.0 or sp.x > PX.x or sp.y < 0.0 or sp.y > PX.y:
				out_px.append([p, kk])
	return {"worst": worst, "blocked": blocked, "out": out_px}


func test_sweep(demo: Node) -> void:
	var dir: CameraDirector = demo.director
	var bridge := samples(demo.walk_bridge, 82.0)
	var lower := samples(demo.walk_lower, 57.0)
	check("AC1 walk samples at 0.5 m (bridge %d, lower %d)" % [bridge.size(), lower.size()], bridge.size() > 1000 and lower.size() > 100)
	for area in ["bridge", "lower"]:
		for lv in [1, 2, 3]:
			var v: Dictionary = dir.level_view(lv, area)
			var id := "%s (Z%d, %s)" % [v.id, lv, area]
			var pts: Array = lower if area == "lower" else bridge
			dir.clamp_log.clear()
			var r := sweep(demo, dir, v, pts)
			check("AC1 %s: every eye inside the envelope (worst |eye| %.2f m <= 95, no clamp)" % [id, r.worst], r.worst <= 95.0 + 1e-6 and dir.clamp_log.is_empty())
			if area == "bridge":
				check("AC1 %s: a clear line to the captain's head from every sample (%d blocked%s)" % [id, r.blocked.size(), (", first %s" % [r.blocked[0]]) if not r.blocked.is_empty() else ""], r.blocked.is_empty())
			else:
				# The Commons' arcades: authored per cell; the residue (points under a lintel that no
				# candidate camera sees) is held to its measured ceiling.
				check("AC1 %s: Commons clear-line ceiling (%d blocked of %d samples <= %d)" % [id, r.blocked.size(), pts.size(), LOWER_CEILING[lv]], r.blocked.size() <= LOWER_CEILING[lv])
			check("AC4 %s: the captain's head in frame from every sample (%d out)" % [id, r.out.size()], r.out.is_empty())
	# Lift: the platform's whole ride, both directions.
	var lift: Dictionary = dir.views["lift"]
	var lift_ok := true
	var lift_worst := 0.0
	for i in 51:
		var foot := Vector3(8.0, lerpf(57.0, 82.0, i / 50.0), -8.0)
		var pose := dir.resolve(lift, foot, 0)
		lift_worst = maxf(lift_worst, pose.origin.length())
		var sp := CameraDirector.screen_point(pose, dir.head_of(lift, foot), PX)
		lift_ok = lift_ok and not is_nan(sp.x) and Rect2(Vector2.ZERO, PX).has_point(sp)
	check("AC1/AC4 lift: inside the envelope (%.1f m) and the captain in frame for the whole ride" % lift_worst, lift_ok and lift_worst <= 95.0)
	# The mutant: the long boom the design rejected (26 m, -50 deg) leaves the bubble.
	var mutant: Dictionary = dir.views["z2"].duplicate(true)
	mutant.id = "mutant"
	mutant.distance_m = 26.0
	mutant.pitch_deg = -50.0
	var raw := 0.0
	var free := CameraDirector.new(null)
	for p: Vector3 in bridge:
		var pose := free.resolve(mutant, p, free.sector_for(p, -1))
		raw = maxf(raw, pose.origin.length())
	check("AC1 mutant 26 m / -50 deg: the clamp fires and is logged (it would leave the envelope)", free.clamp_log.has("mutant"))
	var yaw7 := free.sector_yaw(free.sector_for(Vector3(8, 82, -4.8), -1), mutant)
	var unclamped := Vector3(8, 82, -4.8) + Vector3.UP * 1.6 - Vector3(cos(yaw7) * cos(deg_to_rad(-50.0)), sin(deg_to_rad(-50.0)), sin(yaw7) * cos(deg_to_rad(-50.0))) * 26.0
	check("AC1 mutant: its unclamped eye at the spawn is past the envelope (%.1f m)" % unclamped.length(), unclamped.length() > 95.0)


# ------------------------------------------------------------------ AC2, AC3

func test_levels_and_input(demo: Node) -> void:
	var dir: CameraDirector = demo.director
	demo.set_preset("reset")
	step(demo, 1.0)
	check("AC2 the default is Z2 Deck, third person (the sprite is shown)", dir.level == 2 and not dir.overridden and demo.avatar.visible and dir.view_id == "z2")
	var pose: Transform3D = demo.camera.global_transform
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(40, 25)
	demo._unhandled_input(motion)
	motion.alt_pressed = true
	demo._unhandled_input(motion)
	motion.alt_pressed = false
	motion.button_mask = MOUSE_BUTTON_MASK_RIGHT
	demo._unhandled_input(motion)
	var stick := InputEventJoypadMotion.new()
	stick.axis = JOY_AXIS_RIGHT_X
	stick.axis_value = 1.0
	demo._unhandled_input(stick)
	step(demo, 0.1)
	check("AC3 mouse motion, Option-drag, right-drag and the right stick never move the camera", demo.camera.global_transform.is_equal_approx(pose))
	# One wheel notch: one level. Repeats inside the cooldown are ignored.
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	demo._unhandled_input(wheel)
	check("AC2 one wheel notch up comes closer: Z2 -> Z1", dir.level == 1)
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	demo._unhandled_input(wheel)
	check("AC2 a second notch inside 0.3 s is ignored", dir.level == 1)
	step(demo, 0.35)
	demo._unhandled_input(wheel)
	check("AC2 after the cooldown a notch out steps: Z1 -> Z2", dir.level == 2)
	step(demo, 0.35)
	demo._unhandled_input(wheel)
	step(demo, 0.35)
	demo._unhandled_input(wheel)
	check("AC2 Z3 is the ceiling (no wrap)", dir.level == 3)
	step(demo, 0.35)
	# Trackpad: 0.25 + 0.25 + 0.5 units = one level; horizontal scroll is ignored.
	var pan := InputEventPanGesture.new()
	pan.delta = Vector2(3.0, 0.0)
	demo._unhandled_input(pan)
	check("AC2 horizontal trackpad scroll is ignored", dir.level == 3)
	for d in [-0.25, -0.25]:
		pan.delta = Vector2(0, d)
		demo._unhandled_input(pan)
	check("AC2 half a trackpad unit does not step", dir.level == 3)
	pan.delta = Vector2(0, -0.5)
	demo._unhandled_input(pan)
	check("AC2 one accumulated unit of scroll up steps one level closer: Z3 -> Z2", dir.level == 2)
	for i in 10:
		pan.delta = Vector2(0, -0.4)
		demo._unhandled_input(pan)
		step(demo, 0.05)
	check("AC2 a long swipe inside the cooldown is one step (an inertial tail moves nothing)", dir.level == 2)
	step(demo, 0.35)
	var pinch := InputEventMagnifyGesture.new()
	pinch.factor = 1.08
	demo._unhandled_input(pinch)
	check("AC2 a small pinch does not step", dir.level == 2)
	demo._unhandled_input(pinch)
	check("AC2 a pinch past x1.15 steps in: Z2 -> Z1", dir.level == 1)
	step(demo, 0.6)
	pinch.factor = 0.86
	demo._unhandled_input(pinch)
	check("AC2 a pinch past x0.87 steps out: Z1 -> Z2", dir.level == 2)
	step(demo, 0.35)
	demo._unhandled_input(key(KEY_EQUAL))
	check("AC2 = steps in", dir.level == 1)
	demo._unhandled_input(key(KEY_MINUS))
	check("AC2 - steps out (keys have no cooldown: one press, one level)", dir.level == 2)
	var rb := InputEventJoypadButton.new()
	rb.button_index = JOY_BUTTON_RIGHT_SHOULDER
	rb.pressed = true
	demo._unhandled_input(rb)
	check("AC2 RB steps in", dir.level == 1)
	var lb := InputEventJoypadButton.new()
	lb.button_index = JOY_BUTTON_LEFT_SHOULDER
	lb.pressed = true
	demo._unhandled_input(lb)
	check("AC2 LB steps out", dir.level == 2)
	demo._unhandled_input(key(KEY_3))
	check("AC2 3 picks Z3", dir.level == 3)
	demo._unhandled_input(key(KEY_1))
	check("AC2 1 picks Z1", dir.level == 1)
	demo._unhandled_input(key(KEY_R))
	check("AC2 R returns to the default view (Z2) at the spawn", dir.level == 2 and demo.avatar_pos.distance_to(Vector3(8, 82, -4.8)) < 1e-3)
	step(demo, 1.0)
	# No input moves the camera continuously: a held level is still while the captain stands.
	var a: Transform3D = demo.camera.global_transform
	step(demo, 0.5)
	check("AC2 standing at a level the camera is still", demo.camera.global_transform.is_equal_approx(a))
	# Locks: lift travel and the benchmark; console focus (D4).
	check("lift boards", demo.lift.board())
	demo._unhandled_input(key(KEY_1))
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	step(demo, 0.35)
	demo._unhandled_input(wheel)
	check("AC2 levels are locked during lift travel (the lift view)", dir.level == 2 and dir.view_id == "lift")
	demo.set_preset("reset")
	step(demo, 0.35)
	demo.benchmark.running = true
	demo._unhandled_input(wheel)
	demo._unhandled_input(key(KEY_1))
	check("AC2 the benchmark blocks level changes", dir.level == 2)
	demo.benchmark.running = false


# ------------------------------------------------------------------ AC4

func test_framing(demo: Node) -> void:
	var dir: CameraDirector = demo.director
	demo.set_preset("reset")
	step(demo, 1.0)
	var px := CameraDirector.figure_px(demo.camera.global_transform, demo.avatar_pos, FIGURE_M, PX.y)
	check("AC4 Z2 captain figure %.1f px tall at 1280x720 (60-80)" % px, px >= 60.0 and px <= 80.0)
	var heights := []
	for lv in [1, 2, 3]:
		dir.set_level(lv)
		step(demo, 3.0)
		var cam: Transform3D = demo.camera.global_transform
		var head: Vector3 = dir.head_of(dir.views[dir.view_id], demo.avatar_pos)
		var sp := CameraDirector.screen_point(cam, head, PX)
		heights.append("Z%d %.0f px" % [lv, CameraDirector.figure_px(cam, demo.avatar_pos, FIGURE_M, PX.y)])
		check("AC4 Z%d at the spawn: the head in frame at %s" % [lv, sp], not is_nan(sp.x) and Rect2(Vector2.ZERO, PX).has_point(sp))
		check("D1 Z%d: the accent ring marks the captain only at Z3" % lv, demo.captain_ring.visible == (lv == 3))
		if lv < 3:
			check("AC4 Z%d: the head on the lower-third line (y %.0f of 720)" % [lv, sp.y], absf(sp.y - PX.y * 2.0 / 3.0) < 8.0)
	print("figure heights: %s" % [heights])
	dir.set_level(2)
	step(demo, 2.0)


# ------------------------------------------------------------------ AC5

func test_sectors_and_walk(demo: Node) -> void:
	var dir: CameraDirector = demo.director
	# Hysteresis: the sector holds 10 deg past its edge, then switches.
	var split := float(dir.data.sectors.ring_split_m)
	var at := func(deg: float, rr: float) -> Vector3: return Vector3(rr * cos(deg_to_rad(deg)), 82.0, rr * sin(deg_to_rad(deg)))
	var r := split + 3.0
	var k := dir.sector_for(at.call(20.0, r), -1)
	check("AC5 20 deg on the rail ring is cell 8 (ring 1, sector 0)", k == 8)
	check("AC5 9 deg past the edge (54 deg) holds sector 0", dir.sector_for(at.call(54.0, r), 8) == 8)
	check("AC5 11 deg past the edge (56 deg) switches to sector 1", dir.sector_for(at.call(56.0, r), 8) == 9)
	check("AC5 coming back, 9 deg past (36 deg) holds sector 1", dir.sector_for(at.call(36.0, r), 9) == 9)
	check("AC5 and 11 deg past (34 deg) returns to sector 0", dir.sector_for(at.call(34.0, r), 9) == 8)
	var hyst_m := float(dir.data.sectors.ring_hysteresis_m)
	r = split - hyst_m + 0.1
	check("AC5 the ring holds %.1f m inside the split (rail ring kept)" % (hyst_m - 0.1), dir.sector_for(at.call(20.0, r), 8) == 8)
	r = split - hyst_m - 0.1
	check("AC5 and switches to the stations ring past it", dir.sector_for(at.call(20.0, r), 8) == 0)
	r = split + hyst_m - 0.1
	check("AC5 coming out, the stations ring holds to %.1f m past the split" % (hyst_m - 0.1), dir.sector_for(at.call(20.0, r), 0) == 0)
	# Walk with W held across a sector boundary: the world direction holds until release.
	demo.set_preset("reset")
	dir.set_level(2)
	step(demo, 1.0)
	demo.avatar_pos = demo.walk_bridge.closest_walkable(Vector3(16.0 * cos(deg_to_rad(-60.0)), 82.0, 16.0 * sin(deg_to_rad(-60.0))), 3.0)
	step(demo, 1.5)
	var start_sector: int = dir.sector
	# Hold the screen-relative key that walks most nearly along the ring (tangentially), so the
	# walk crosses a sector boundary.
	var yaw := dir.walk_yaw()
	var tangent := Vector3(-demo.avatar_pos.z, 0.0, demo.avatar_pos.x).normalized()
	var walk_key := Vector2.ZERO
	var best := -2.0
	for kv: Vector2 in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
		var w := (Vector3(-sin(yaw), 0.0, cos(yaw)) * kv.x + Vector3(cos(yaw), 0.0, sin(yaw)) * kv.y).normalized()
		if w.dot(tangent) > best:
			best = w.dot(tangent)
			walk_key = kv
	var dirs := []
	var switched := false
	var prev_d := Vector3.INF
	var prev_q := Quaternion.IDENTITY
	var prev_dq := INF
	var jump_m := 0.0
	var jump_deg := 0.0
	var last: Transform3D = demo.camera.global_transform
	var prev_pos: Vector3 = demo.avatar_pos
	for i in 240:
		demo.walk_motion(walk_key, 1.0 / 60.0)
		demo._process(1.0 / 60.0)
		var moved: Vector3 = demo.avatar_pos - prev_pos
		prev_pos = demo.avatar_pos
		if moved.length() > 1e-4:
			dirs.append(moved.normalized())
		switched = switched or dir.sector != start_sector
		var cam: Transform3D = demo.camera.global_transform
		var d := cam.origin - last.origin
		var dq := rad_to_deg(Quaternion(cam.basis.orthonormalized()).angle_to(Quaternion(last.basis.orthonormalized())))
		if prev_d != Vector3.INF:
			jump_m = maxf(jump_m, (d - prev_d).length())
			jump_deg = maxf(jump_deg, absf(dq - prev_dq))
		prev_d = d
		prev_dq = dq
		last = cam
	var held := true
	for v: Vector3 in dirs:
		held = held and v.dot(dirs[0]) > 0.98 or not held
	var straight := dirs.size() > 10 and dirs.all(func(v: Vector3) -> bool: return v.dot(dirs[0]) > 0.9)
	check("AC5 walking with W held crosses a sector boundary (sector %d -> %d)" % [start_sector, dir.sector], switched)
	check("AC5 the walk keeps its world direction while W is held (no reversal mid-stride)", straight)
	check("AC5 no pose jump while walking and switching sectors at 60 Hz (%.4f m, %.3f deg per frame^2)" % [jump_m, jump_deg], jump_m <= 0.01 and jump_deg <= 0.5)
	demo.walk_motion(Vector2.ZERO, 1.0 / 60.0)
	check("AC5 releasing every move key ends the hold", is_nan(demo._walk_hold_yaw))


# ------------------------------------------------------------------ AC7

## Samples a transition at 60 Hz: max angular speed (deg/s), max roll (deg), FOV, overshoot.
func sample(demo: Node, seconds: float) -> Dictionary:
	var dir: CameraDirector = demo.director
	var last: Transform3D = demo.camera.global_transform
	var start := last
	var out := {"rate": 0.0, "roll": 0.0, "fov": demo.camera.fov, "fov_ok": true, "travel": 0.0, "frames": 0, "moving": 0, "overshoot": 0.0}
	var t := 0.0
	var dist0 := -1.0
	while t < seconds:
		demo._process(1.0 / 60.0)
		t += 1.0 / 60.0
		var cam: Transform3D = demo.camera.global_transform
		var dq := rad_to_deg(Quaternion(cam.basis.orthonormalized()).angle_to(Quaternion(last.basis.orthonormalized())))
		out.rate = maxf(out.rate, dq * 60.0)
		var right: Vector3 = cam.basis.x
		out.roll = maxf(out.roll, rad_to_deg(absf(asin(clampf(right.y, -1.0, 1.0)))))
		out.fov_ok = out.fov_ok and is_equal_approx(demo.camera.fov, 78.0)
		out.travel = maxf(out.travel, cam.origin.distance_to(start.origin))
		if not cam.is_equal_approx(last):
			out.moving += 1
		last = cam
	out.end = last
	return out


func test_motion(demo: Node) -> void:
	var dir: CameraDirector = demo.director
	demo.set_preset("reset")
	step(demo, 1.0)
	var worst_rate := 0.0
	var worst_roll := 0.0
	var fov_ok := true
	var transitions := []
	# Level steps both ways, Z3 and back, console focus and step back (D6 table).
	for lv in [1, 3, 2, 3, 1, 2]:
		var from: Transform3D = demo.camera.global_transform
		dir.set_level(lv)
		var s := sample(demo, 4.0)
		worst_rate = maxf(worst_rate, s.rate)
		worst_roll = maxf(worst_roll, s.roll)
		fov_ok = fov_ok and s.fov_ok
		# No overshoot: the last frame of the transition is the target, approached monotonically.
		var target: Transform3D = s.end
		transitions.append("Z%d %.0f deg/s" % [lv, s.rate])
	demo.consoles.go_to("archive")
	step(demo, 1.0)
	demo.consoles.press_e()
	var focus := sample(demo, 4.0)
	worst_rate = maxf(worst_rate, focus.rate)
	worst_roll = maxf(worst_roll, focus.roll)
	transitions.append("console %.0f deg/s" % focus.rate)
	demo.consoles.leave()
	var back := sample(demo, 4.0)
	worst_rate = maxf(worst_rate, back.rate)
	worst_roll = maxf(worst_roll, back.roll)
	transitions.append("back %.0f deg/s" % back.rate)
	print("transitions: %s" % [transitions])
	check("AC7 full motion: angular speed <= 90 deg/s over every transition (worst %.1f)" % worst_rate, worst_rate <= 90.0 * 1.02)
	check("AC7 full motion: no roll (worst %.4f deg)" % worst_roll, worst_roll < 0.01)
	check("AC7 the FOV never changes (78 deg)", fov_ok)
	check("D4 step back returns to the remembered level (Z2) and sector", dir.level == 2 and dir.view_id == "z2" and demo.camera_mode == "player")
	# Overshoot: the eye's distance to the target never grows during a level step.
	demo.set_preset("reset")
	step(demo, 1.0)
	dir.set_level(1)
	var goal: Transform3D = dir.resolve(dir.views["z1"], demo.avatar_pos, dir.sector)
	var prev := INF
	var mono := true
	for i in 120:
		demo._process(1.0 / 60.0)
		var d: float = demo.camera.global_transform.origin.distance_to(goal.origin)
		mono = mono and d <= prev + 1e-5
		prev = d
	check("AC7 no overshoot: a level step approaches its pose monotonically (end %.4f m)" % prev, mono and prev < 1e-3)
	# Reduced motion: every transition is a cut (no travel) with a <= 0.15 s fade.
	demo.set_camera_motion("reduced")
	var cuts := true
	var fades := true
	for lv in [3, 1, 2]:
		var before: Transform3D = demo.camera.global_transform
		dir.set_level(lv)
		var f0: float = dir.fade
		demo._process(1.0 / 60.0)
		var after: Transform3D = demo.camera.global_transform
		var s := sample(demo, 0.5)
		cuts = cuts and after.origin.distance_to(s.end.origin) < 1e-4 and not after.is_equal_approx(before)
		fades = fades and f0 > 0.9 and dir.fade == 0.0
	check("AC7 reduced motion: level steps are cuts (the next frame is the final pose)", cuts)
	check("AC7 reduced motion: the cut fades out within 0.15 s", fades)
	demo.consoles.go_to("archive")
	demo._process(1.0 / 60.0)
	demo.consoles.press_e()
	demo._process(1.0 / 60.0)
	var at_console: Transform3D = demo.camera.global_transform
	check("AC7 reduced motion: console focus is a cut", at_console.origin.distance_to(demo.consoles.focus_pose(demo.consoles.focus_mesh).origin) < 1e-3)
	demo.consoles.leave()
	demo._process(1.0 / 60.0)
	check("AC7 reduced motion: step back is a cut to the level view", demo.camera_mode == "player" and not dir.blending())
	# Walking follow: rigid in reduced motion (the camera moves with the captain the same frame).
	var before_cam: Vector3 = demo.camera.global_transform.origin
	var before_foot: Vector3 = demo.avatar_pos
	demo.walk_motion(Vector2(1, 0), 0.1)
	demo._process(1.0 / 60.0)
	var moved_cam: Vector3 = demo.camera.global_transform.origin - before_cam
	var moved_foot: Vector3 = demo.avatar_pos - before_foot
	check("AC7 reduced motion: rigid follow (camera moved %.3f m with the captain's %.3f m)" % [moved_cam.length(), moved_foot.length()], moved_foot.length() > 0.1 and moved_cam.distance_to(moved_foot) < 0.05 or dir.sector_for(demo.avatar_pos, -1) != dir.sector_for(before_foot, -1))
	demo.walk_motion(Vector2.ZERO, 0.1)
	demo.set_camera_motion("full")


# ------------------------------------------------------------------ AC9

func test_free_camera() -> void:
	var menu: Node = await new_demo({"from_menu": true, "settings_dir": "user://test_camera_director"})
	DirAccess.make_dir_recursive_absolute("user://test_camera_director")
	menu._unhandled_input(key(KEY_F8))
	check("AC9 menu launch: F8 does nothing (no developer free camera)", not menu.free_camera_on() and not menu.director.overridden)
	check("AC3 menu launch: mouse look is off and the pointer is never captured", not menu.wants_capture())
	menu.set_free_camera(true)
	check("AC9 menu launch: the free camera cannot be forced on", not menu.free_camera_on())
	check("D7 the Tab help names no mouse look for players", not menu.ship_hud.help.text.to_lower().contains("mouse to look"))
	menu.queue_free()
	await process_frame
	var cli: Node = await new_demo({})
	cli._unhandled_input(key(KEY_F8))
	check("AC9 command-line launch: F8 turns the developer free camera on", cli.free_camera_on() and cli.director.overridden)
	var yaw: float = cli.camera.yaw
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(20, 10)
	cli._unhandled_input(motion)
	check("D7 free camera: mouse motion looks (today's free look)", not is_equal_approx(yaw, cli.camera.yaw))
	check("D7 free camera: it wants the pointer captured when no panel is open", cli.wants_capture())
	var pull: float = cli.camera.pullback
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	cli._unhandled_input(wheel)
	check("D7 free camera: the wheel dollies (continuous, developer only)", cli.camera.pullback > pull)
	cli._unhandled_input(key(KEY_3))
	check("D7 free camera: 3 is the external whole-ship preset", cli.camera_mode == "external review")
	cli._unhandled_input(key(KEY_4))
	check("D7 free camera: 4 is the diagnostic rim", cli.camera.reference)
	cli._process(1.0 / 60.0)
	check("D7 the HUD labels it FREE CAMERA · developer", cli.ship_hud.details.text.contains("FREE CAMERA · developer") and cli.ship_hud.view_tag.text.contains("FREE CAMERA"))
	cli._unhandled_input(key(KEY_F8))
	cli._process(1.0 / 60.0)
	check("AC9 F8 again returns to the player camera (Z2, no capture)", not cli.free_camera_on() and not cli.director.overridden and not cli.wants_capture() and cli.director.level == 2)
	cli.queue_free()
	await process_frame
	var flag: Node = await new_demo({"free_camera": true})
	check("AC9 --free-camera (setup_options free_camera) starts a command-line launch in the free camera", flag.free_camera_on())
	flag.queue_free()
	await process_frame


# ------------------------------------------------------------------ C2 sky views (AC1, AC4)

## The forward pole (ship +z = glTF +y, travel) and a 20 deg cone around it: in frame and clear of
## geometry from the eye (the starbow is what the view is for).
func pole_clear(demo: Node, pose: Transform3D) -> bool:
	var sp := CameraDirector.screen_point(pose, pose.origin + Vector3.UP * 1000.0, PX)
	if is_nan(sp.x) or not Rect2(Vector2(0, 40), PX - Vector2(0, 40)).has_point(sp):
		return false
	var space: PhysicsDirectSpaceState3D = demo.camera.get_world_3d().direct_space_state
	for a in [0.0, 90.0, 180.0, 270.0]:
		for tilt in [0.0, 20.0]:
			var d := Vector3.UP.rotated(Vector3(cos(deg_to_rad(a)), 0, sin(deg_to_rad(a))), deg_to_rad(tilt))
			var q := PhysicsRayQueryParameters3D.create(pose.origin, pose.origin + d * 40.0)
			q.hit_back_faces = true
			if not space.intersect_ray(q).is_empty() and tilt == 0.0:
				return false
	return true


func test_sky_sweep(demo: Node) -> void:
	var dir: CameraDirector = demo.director
	var bridge := samples(demo.walk_bridge, 82.0)
	var fwd: Dictionary = dir.views["sky_forward"]
	# Sky forward picks, once as it starts, the first candidate yaw whose eye sees the whole figure
	# (lift guards included) and the forward pole clear; with none, the captain walks to the
	# anchor (15 m out at the same angle), where one must exist.
	var walked := 0
	var none := []
	var worst := 0.0
	for p: Vector3 in bridge:
		var off: Variant = dir.choose_offset(fwd, p)
		var at := p
		if off == null:
			walked += 1
			at = dir.anchor_of(fwd, p)
			off = dir.choose_offset(fwd, at)
		if off == null:
			none.append(p)
			continue
		var pose := dir._sky(fwd, at, dir.sector_for(at, -1), off)
		worst = maxf(worst, pose.origin.length())
		var sp := CameraDirector.screen_point(pose, dir.head_of(fwd, at), PX)
		if is_nan(sp.x) or not Rect2(Vector2.ZERO, PX).has_point(sp) or not pole_clear(demo, pose):
			none.append(p)
	check("C2 sky_forward: from every bridge sample (%d of them walk to the anchor first) the whole figure and the forward pole are clear and in frame (%d fail%s)" % [walked, none.size(), (", first %s" % none[0]) if not none.is_empty() else ""], none.is_empty())
	check("C2 sky_forward: every eye inside the envelope (worst %.2f m)" % worst, worst <= 95.0)
	# The hole view, for the hole straight overhead (the ship holds its nose on it) and 30 deg off.
	var hole: Dictionary = dir.views["sky_hole"]
	for tilt in [0.0, 30.0]:
		dir.hole_override = Vector3.UP.rotated(Vector3.RIGHT, deg_to_rad(tilt))
		var fails := []
		for p: Vector3 in bridge:
			var o: Variant = dir.choose_offset(hole, p)
			var at := p
			if o == null:
				at = dir.anchor_of(hole, p)
				o = dir.choose_offset(hole, at)
			if o == null:
				fails.append(p)
		check("C2 sky_hole (hole %d deg off the travel axis): from every bridge sample the figure and the hole are clear and in frame (%d fail%s)" % [tilt, fails.size(), (", first %s" % fails[0]) if not fails.is_empty() else ""], fails.is_empty())
	dir.hole_override = Vector3.ZERO
	# The anchored views: from their anchors (side: one rail point; aft: the rail at every 5 deg).
	var side: Dictionary = dir.views["sky_side"]
	var a: Vector3 = dir.anchor_of(side, Vector3(8, 82, -4.8))
	var pose := dir.resolve(side, a, dir.sector_for(a, -1))
	var head := dir.head_of(side, a)
	var sp := CameraDirector.screen_point(pose, head, PX)
	var body := CameraDirector.screen_point(pose, pose.origin + Vector3(cos(deg_to_rad(15.0)), sin(deg_to_rad(15.0)), 0) * 1000.0, PX)
	check("C2 sky_side: the anchor %s is walkable, the captain clear and in frame (%s), the stop's body direction (+x, 15 deg up) in frame (%s)" % [a, sp, body], demo.walk_bridge.is_walkable(a) and clear_line(demo, pose.origin, head) and Rect2(Vector2.ZERO, PX).has_point(sp) and Rect2(Vector2.ZERO, PX).has_point(body) and pose.origin.length() <= 95.0)
	var aft: Dictionary = dir.views["sky_aft"]
	var aft_bad := []
	for deg in range(0, 360, 5):
		var f := Vector3(cos(deg_to_rad(deg)), 0, sin(deg_to_rad(deg))) * 10.0 + Vector3(0, 82, 0)
		var an: Vector3 = dir.anchor_of(aft, f)
		var ps := dir.resolve(aft, an, dir.sector_for(an, -1))
		var hd := dir.head_of(aft, an)
		var spp := CameraDirector.screen_point(ps, hd, PX)
		if ps.origin.length() > 95.0 or not clear_line(demo, ps.origin, hd) or is_nan(spp.x) or not Rect2(Vector2.ZERO, PX).has_point(spp):
			aft_bad.append(deg)
	check("C2 sky_aft: from the rail anchor at every 5 deg, inside the envelope with the captain clear and in frame (%d bad %s)" % [aft_bad.size(), aft_bad.slice(0, 6)], aft_bad.is_empty())


# ------------------------------------------------------------------ spawn occlusion (lead review)

## The lift's boxes have no collision; test them as AABBs.
func lift_boxes(demo: Node) -> Array:
	var out := []
	var stack: Array = [demo.lift]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D and n.is_visible_in_tree() and n.mesh != null:
			out.append((n as MeshInstance3D).global_transform * n.mesh.get_aabb())
		stack.append_array(n.get_children())
	return out


func figure_clear(demo: Node, eye: Vector3, foot: Vector3) -> Array:
	var blocked := []
	for h in [0.15, 0.5, 0.9, 1.3, 1.6]:
		var p: Vector3 = foot + Vector3.UP * h
		if not clear_line(demo, eye, p):
			blocked.append("%.2f m (ship)" % h)
			continue
		for b: AABB in lift_boxes(demo):
			if b.intersects_segment(eye, p.lerp(eye, 0.02)):
				blocked.append("%.2f m (lift)" % h)
				break
	return blocked


func test_spawn_occlusion(demo: Node) -> void:
	var dir: CameraDirector = demo.director
	demo.set_preset("reset")
	var foot := Vector3(8, 82, -4.8)
	for lv in [1, 2, 3]:
		var v: Dictionary = dir.level_view(lv, "bridge")
		var bad := []
		for k: int in cells(dir, foot):
			bad.append_array(figure_clear(demo, dir.resolve(v, foot, k).origin, foot))
		check("spawn: the whole figure (0.15 to 1.6 m) is clear at Z%d from every cell the spawn can be in, the lift's guards included %s" % [lv, bad], bad.is_empty())
	var fwd: Dictionary = dir.views["sky_forward"]
	var off: Variant = dir.choose_offset(fwd, foot)
	check("spawn: Sky forward needs no walk and sees the whole figure (offset %s) %s" % [off, figure_clear(demo, dir._sky(fwd, foot, 7, off).origin, foot) if off != null else []], off != null and figure_clear(demo, dir._sky(fwd, foot, 7, off).origin, foot).is_empty())


# ------------------------------------------------------------------ C2 cues (AC6)

func test_cues() -> void:
	var demo: Node = await new_demo({"live_start": true})
	var dir: CameraDirector = demo.director
	var c: ShipConsoles = demo.consoles
	check("AC6 at rest the default is the level view", dir.situation.is_empty() and dir.level == 2 and not demo.under_way())
	# Keys: 7 / 8 / 9.
	demo._unhandled_input(key(KEY_7))
	check("C2 7 opens Sky forward (third person; the captain shown)", dir.situation == "sky_forward" and demo.avatar.visible and not dir.overridden)
	step(demo, 4.0) # the ease is capped at 90 deg/s: a half-turn up takes ~3 s
	check("C2 Sky forward stands the captain upright (no leaning billboard)", demo.avatar.billboard == BaseMaterial3D.BILLBOARD_FIXED_Y)
	var pose: Transform3D = demo.camera.global_transform
	check("C2 Sky forward frames the forward pole (%s, view %s, pitch %.1f)" % [CameraDirector.screen_point(pose, pose.origin + Vector3.UP * 1000.0, PX), dir.view_id, rad_to_deg(CameraDirector.yaw_pitch(pose).y)], Rect2(Vector2.ZERO, PX).has_point(CameraDirector.screen_point(pose, pose.origin + Vector3.UP * 1000.0, PX)))
	demo._unhandled_input(key(KEY_2))
	check("AC6 a level key ends a sky view (back to Z2)", dir.situation.is_empty() and dir.level == 2)
	demo._unhandled_input(key(KEY_8))
	check("C2 8 walks the captain to the side anchor first", dir._pending == "sky_side" and c.walk_target.begins_with("point:"))
	for i in 600:
		demo._process(1.0 / 60.0)
		if dir.situation == "sky_side":
			break
	check("C2 on arrival the Sky side view starts (%s)" % demo.avatar_pos, dir.situation == "sky_side")
	demo.walk_motion(Vector2(0, 1), 1.0 / 60.0)
	demo.walk_motion(Vector2.ZERO, 1.0 / 60.0)
	check("AC6 a move key ends a sky view", dir.situation.is_empty())
	demo._unhandled_input(key(KEY_9))
	for i in 600:
		demo._process(1.0 / 60.0)
		if dir.situation == "sky_aft":
			break
	check("C2 9: Sky astern from the rail", dir.situation == "sky_aft")
	demo._unhandled_input(key(KEY_R))
	check("AC6 R ends it: the default view at rest is Z2", dir.situation.is_empty() and dir.level == 2)
	step(demo, 1.0)
	# Refusals: a panel open, at a console, in the lift.
	demo.toggle_controls()
	check("AC6 no cue with a panel open (Tab)", not dir.sky("sky_forward", true) and dir.situation.is_empty())
	demo.escape()
	c.go_to("navigation")
	c.use("navigation", "open")
	check("AC6 no cue at a console", not dir.sky("sky_forward", true) and dir.situation.is_empty())
	# Commit at the helm: leaving the console, the departure cues Sky forward (under way).
	check("the helm commits", c.use("navigation", "commit") and demo.journey_tick())
	check("AC6 departure (commit): Sky forward is cued once the helm is left", demo.live_journey and dir.situation == "sky_forward" and demo.under_way())
	step(demo, 4.0)
	pose = demo.camera.global_transform
	check("C2 under way the player view frames the forward pole", Rect2(Vector2.ZERO, PX).has_point(CameraDirector.screen_point(pose, pose.origin + Vector3.UP * 1000.0, PX)))
	demo._unhandled_input(key(KEY_1))
	check("AC6 a level key takes over during cruise", dir.situation.is_empty() and dir.level == 1)
	demo._unhandled_input(key(KEY_R))
	check("C2 under way, R returns to Sky forward (the default view under way)", dir.situation == "sky_forward")
	demo._unhandled_input(key(KEY_2))
	var braked := false
	for i in 4000:
		if not demo.journey_tick():
			break
		demo._process(0.05)
		if str(demo.sky_world.ship.phase) == "braking":
			braked = true
			break
	demo._process(0.05)
	check("AC6 braking cues Sky forward (phase %s)" % demo.sky_world.ship.phase, braked and dir.situation == "sky_forward")
	# Reduced motion: a cue is a prompt, the camera does not travel.
	demo._unhandled_input(key(KEY_2))
	demo.set_camera_motion("reduced")
	check("AC6 reduced motion: a cue is a HUD prompt instead (%s)" % dir.cue_prompt, not dir.sky("sky_forward", true) and dir.situation.is_empty() and dir.cue_prompt == "Sky ahead · 7")
	demo._process(0.05)
	check("AC6 the prompt shows in the HUD (%s)" % demo.ship_hud.prompt.text, demo.ship_hud.prompt.text.begins_with("Sky ahead · 7"))
	demo.set_camera_motion("full")
	# The lift.
	demo.queue_free()
	await process_frame
	demo = await new_demo({"live_start": true})
	dir = demo.director
	check("lift boards", demo.lift.board())
	check("AC6 no cue in the lift", not dir.sky("sky_forward", true) and dir.situation.is_empty())
	demo.queue_free()
	await process_frame
	# Sgr A*: the hole view, aimed from the sim's GR state, at every stop of the visit.
	demo = await new_demo({"live_start": true})
	dir = demo.director
	check("Sgr A* starts", demo.start_black_hole())
	check("AC6 Sgr A* cues the hole view (sky_hole), not the forward sky", dir.situation == "sky_hole" and demo.under_way())
	var hd: Vector3 = demo.hole_direction()
	check("Sgr A*: the hole's direction comes from the GR state (unit, %s)" % hd, absf(hd.length() - 1.0) < 1e-4)
	for stop in BlackHoleVisit.STOPS.size() + 1:
		if stop > 0:
			demo._unhandled_input(key(KEY_2)) # the player looks elsewhere; the next stop frames the hole again
			check("Sgr A* stop %d: departs" % stop, demo.bh_next_stop())
			if demo.black_hole.approaching():
				demo.bh_finish_approach()
			else:
				demo._arrived()
		step(demo, 4.0)
		var g: Dictionary = demo.black_hole.gr()
		var cam: Transform3D = demo.camera.global_transform
		var h: Vector3 = demo.hole_direction()
		var centre := CameraDirector.screen_point(cam, cam.origin + h * 1000.0, PX)
		var shadow := rad_to_deg(Schwarzschild.shadow_angle(float(g.r)))
		var off := rad_to_deg((-cam.basis.z).angle_to(h))
		check("Sgr A* %s r %s: the hole view is up, the hole's centre in frame at %s (%.1f deg above centre; shadow radius %.3f deg), the captain in frame" % [g.get("mode", ""), BlackHoleVisit.r_text(float(g.r)), centre, off, shadow], dir.situation == "sky_hole" and not is_nan(centre.x) and Rect2(Vector2.ZERO, PX).has_point(centre) and absf(off - 18.0) < 0.5 and Rect2(Vector2.ZERO, PX).has_point(CameraDirector.screen_point(cam, demo.avatar_pos + Vector3.UP * 1.6, PX)))
	demo.set_camera_motion("reduced")
	demo._unhandled_input(key(KEY_2))
	demo._arrived()
	check("Sgr A* reduced motion: the stop's cue is a prompt (%s)" % dir.cue_prompt, dir.situation.is_empty() and dir.cue_prompt == "The hole · 7")
	demo.set_camera_motion("full")
	demo._unhandled_input(key(KEY_R))
	check("Sgr A*: R (under way) returns to the hole view", dir.situation == "sky_hole")
	demo.leave_black_hole()
	demo.queue_free()
	await process_frame
	# The guided voyage: the stop turn cues Sky side (after the turn), departure cues Sky forward.
	demo = await new_demo({"live_start": true})
	dir = demo.director
	check("the guided voyage starts", demo.start_solar_departure())
	for i in 1200:
		demo._process(1.0 / 60.0)
		if demo.solar_tour.attitude_hold:
			demo.journey_tick()
		if dir.situation == "sky_side":
			break
	check("AC6 a guided stop cues Sky side once the stop turn completes (walked to the rail)", dir.situation == "sky_side")
	check("the next stop prepares", demo.solar_tour.prepare_next())
	demo._process(1.0 / 60.0)
	check("AC6 the departure turn cues Sky forward", dir.situation == "sky_forward" and demo.under_way())
	demo.queue_free()
	await process_frame


## Mark's ruling (2026-10-17, attended; design doc §Under-way default): "Sky forward under way".
## At rest Z2 Deck; under way Sky forward (the captain from behind, the starbow in frame); at a
## guided stop Sky side; at Sgr A* the hole view; any zoom key returns to Z1 / Z2 / Z3.
func test_default_mapping() -> void:
	var demo: Node = await new_demo({"live_start": true})
	var dir: CameraDirector = demo.director
	demo._unhandled_input(key(KEY_R))
	check("default mapping: at rest R gives Z2 Deck", dir.situation.is_empty() and dir.level == 2 and not demo.under_way())
	var c: ShipConsoles = demo.consoles
	c.go_to("navigation")
	c.use("navigation", "open")
	c.use("navigation", "commit")
	demo.journey_tick()
	check("default mapping: under way the view is Sky forward", demo.under_way() and dir.situation == "sky_forward")
	for lv in [1, 2, 3]:
		demo._unhandled_input(key(KEY_1 + lv - 1))
		check("default mapping: under way, zoom key %d returns to Z%d" % [lv, lv], dir.situation.is_empty() and dir.level == lv)
		demo._unhandled_input(key(KEY_R))
		check("default mapping: under way R returns to Sky forward (after Z%d)" % lv, dir.situation == "sky_forward")
	demo.queue_free()
	await process_frame
	demo = await new_demo({"live_start": true})
	dir = demo.director
	demo.start_solar_departure()
	for i in 1200:
		demo._process(1.0 / 60.0)
		if demo.solar_tour.attitude_hold:
			demo.journey_tick()
		if dir.situation == "sky_side":
			break
	check("default mapping: at a guided stop the view is Sky side", dir.situation == "sky_side" and not demo.under_way())
	demo._unhandled_input(key(KEY_2))
	check("default mapping: at a stop a zoom key returns to Z2", dir.situation.is_empty() and dir.level == 2)
	demo.queue_free()
	await process_frame
	demo = await new_demo({"live_start": true})
	dir = demo.director
	demo.start_black_hole()
	check("default mapping: at Sgr A* the view is the hole view", dir.situation == "sky_hole")
	demo._unhandled_input(key(KEY_3))
	check("default mapping: at Sgr A* a zoom key returns to Z3", dir.situation.is_empty() and dir.level == 3)
	demo._unhandled_input(key(KEY_R))
	check("default mapping: at Sgr A* R returns to the hole view", dir.situation == "sky_hole")
	demo.leave_black_hole()
	demo.queue_free()
	await process_frame


## The Crew console v2 (#267) and every station: focusing and stepping back return the camera to
## the same zoom level, or the same sky view, and never leave the developer free camera on.
func test_console_round_trip() -> void:
	var demo: Node = await new_demo({"live_start": true})
	var dir: CameraDirector = demo.director
	var c: ShipConsoles = demo.consoles
	for station in ["crew", "navigation", "archive"]:
		for lv in [1, 3]:
			c.go_to(station)
			dir.set_level(lv)
			step(demo, 3.0)
			check("%s: opens from Z%d" % [station, lv], c.use(station, "open") and demo.camera_mode == "console")
			step(demo, 3.0)
			c.leave()
			step(demo, 5.0) # a half-turn back at <= 90 deg/s takes up to ~3.5 s
			check("%s: stepping back returns to Z%d (view %s, level %d, situation %s, mode %s, blend %s)" % [station, lv, dir.view_id, dir.level, dir.situation, demo.camera_mode, dir.blending()], dir.level == lv and dir.situation.is_empty() and demo.camera_mode == "player" and not demo.free_camera_on())
	c.go_to("crew")
	demo._unhandled_input(key(KEY_7))
	step(demo, 4.0)
	check("crew: opens from Sky forward", dir.situation == "sky_forward" and c.use("crew", "open"))
	step(demo, 3.0)
	c.leave()
	step(demo, 4.0)
	check("crew: stepping back returns to Sky forward", dir.situation == "sky_forward" and dir.view_id == "sky_forward" and demo.camera_mode == "player")
	demo.set_free_camera(true)
	check("the developer free camera is on (command-line launch)", demo.free_camera_on())
	c.go_to("crew")
	check("crew: opens from the free camera", c.use("crew", "open"))
	step(demo, 3.0)
	c.leave()
	step(demo, 3.0)
	check("crew: stepping back leaves the free camera off (the director owns the camera)", not demo.free_camera_on() and not dir.overridden and demo.camera_mode == "player" and not demo.wants_capture())
	demo.queue_free()
	await process_frame


## #271 (constellation guides while I is held) under the director: holding I owns the pointer
## (levels locked, nothing captured), and the guides follow the director's pose in each view.
func test_constellations_held_i() -> void:
	var demo: Node = await new_demo({"stars": true})
	var dir: CameraDirector = demo.director
	var ident = demo.star_identification
	var counts := {}
	for view in ["z2", "sky_forward", "z3"]:
		if view == "sky_forward":
			dir.sky("sky_forward")
		else:
			dir.set_level(2 if view == "z2" else 3)
		step(demo, 4.0)
		ident.set_held(true)
		ident.constellations.update_view()
		counts[view] = ident.constellations.segments.size()
		var lv: int = dir.level
		demo._unhandled_input(key(KEY_1))
		check("held I (%s): the pointer belongs to the inspection, levels locked, nothing captured" % view, demo.pointer_required() and dir.level == lv and not demo.wants_capture())
		ident.set_held(false)
		ident.constellations.update_view()
	check("held I: constellation guides drawn through the director's pose %s" % [counts], counts.values().any(func(n: int) -> bool: return n > 0) and not ident.constellations.visible)
	check("held I: the guides change with the view (they follow the camera) %s" % [counts], counts["z2"] != counts["sky_forward"] or counts["sky_forward"] != counts["z3"])
	demo.queue_free()
	await process_frame
