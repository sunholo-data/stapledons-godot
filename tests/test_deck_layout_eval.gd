extends SceneTree
## R2-DECK-LAYOUT DL0 (design_docs/planned/r2/deck-layout.md §D3, AC1): make deck-layout-eval-test.
##   positive control  on the shipped GLBs the evaluator's clear-line counts equal the camera
##                     test's (bridge 0 at every level; the Commons its LOWER_CEILING)
##   layout files      layout_current.json validates; unknown groups, bad positions and fixture
##                     boxes outside a test are refused; applying the base to itself changes nothing
##   walk rule         a moved console's old spot becomes walkable, its new spot is not
##   negative controls a console moved onto the Z2 boom fails boom-intrusion; a 6 m prop at a Sky
##                     forward landing pose fails sky-fraction; a block before a Z3 eye fails
##                     frame-dominance
##   sky fraction      an analytic frame (a wall filling exactly the lower half) measures 0.5
##                     within 2 % (the rendered-mask control runs in make deck-layout-capture)
## Fixtures: tests/fixtures/deck_layout/*.json.

const BASE := "res://art/deck-layout-v1/layout_current.json"
const FIX := "res://tests/fixtures/deck_layout/"
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
	test_files()
	var demo := await new_demo()
	var dl := DeckLayout.new(demo)
	test_positive(dl)
	await test_sky_analytic(dl)
	demo.queue_free()
	await process_frame
	await test_identity()
	await test_walk_rule()
	await test_boom()
	await test_sky_prop()
	await test_dominance()
	print("deck-layout-eval-test: %d passed, %d failures" % [passes, failures])
	quit(1 if failures else 0)


func new_demo() -> Node:
	var demo: Node = load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options = {"stars": false, "background": false, "sky_state": "rest", "size": Vector2i(1280, 720)}
	root.add_child(demo)
	await process_frame
	await physics_frame
	await physics_frame
	demo.auto = false
	demo.journey_auto_tick = false
	return demo


func applied(path: String, allow := false) -> Array:
	var demo := await new_demo()
	var dl := DeckLayout.new(demo)
	var errs := dl.apply(DeckLayout.load_layout(path), DeckLayout.load_layout(BASE), allow)
	await physics_frame
	await physics_frame
	return [demo, dl, errs]


func test_files() -> void:
	var base := DeckLayout.load_layout(BASE)
	check("layout_current.json validates %s" % [DeckLayout.validate(base)], DeckLayout.validate(base).is_empty())
	var bad := base.duplicate(true)
	bad.bridge.props["no_such_prop"] = {"position_m": [0, 0], "yaw_deg": 0}
	check("an unknown prop group is refused", not DeckLayout.validate(bad).is_empty())
	var bad2 := base.duplicate(true)
	bad2.bridge.props.captain_chair.position_m = [1.0]
	check("a position that is not [x, y] is refused", not DeckLayout.validate(bad2).is_empty())
	var boxed := DeckLayout.load_layout(FIX + "sky_prop.json")
	check("fixture boxes are refused outside a test", not DeckLayout.validate(boxed).is_empty() and DeckLayout.validate(boxed, true).is_empty())
	var t: Transform3D = DeckLayout.ship_to_gltf([2.0, 3.0], 90.0)
	check("ship (2, 3), yaw 90 -> glTF (2, 82, -3), ship +x turns to ship +y (glTF -z) %s" % [t], t.origin.is_equal_approx(Vector3(2, 82, -3)) and (t.basis * Vector3.RIGHT).is_equal_approx(Vector3(0, 0, -1)))


func test_positive(dl: DeckLayout) -> void:
	var ceiling: Dictionary = load("res://tests/test_camera_director.gd").get_script_constant_map().LOWER_CEILING
	var bridge := dl.samples("bridge")
	var lower := dl.samples("lower")
	for lv in [1, 2, 3]:
		var b := dl.level_metrics("bridge", lv, bridge)
		check("positive control: bridge Z%d blocked %d == the camera test's 0 (%d samples)" % [lv, b.blocked, b.samples], int(b.blocked) == 0 and int(b.samples) > 1000)
		var l := dl.level_metrics("lower", lv, lower)
		check("positive control: Commons Z%d blocked %d == the camera test's ceiling %d" % [lv, l.blocked, ceiling[lv]], int(l.blocked) == int(ceiling[lv]))


func test_sky_analytic(dl: DeckLayout) -> void:
	var box := {"name": "fixture_half_wall", "center_gltf_m": [200.0, 150.0, 0.0], "size_m": [100.0, 300.0, 2000.0]}
	dl._add_box(box)
	var pose := Transform3D(Basis.looking_at(Vector3.RIGHT, Vector3.UP), Vector3(0, 300, 0))
	await physics_frame
	var f := dl.sky_fraction(pose)
	check("sky fraction: a wall filling exactly the lower half of the frame measures %.3f (0.5 within 2 %%)" % f, absf(f - 0.5) <= 0.02)
	var clear := Transform3D(Basis.looking_at(Vector3.UP + Vector3(0.01, 0, 0), Vector3.FORWARD), Vector3(0, 900, 0))
	check("sky fraction: open sky measures 1.0 (%.3f)" % dl.sky_fraction(clear), is_equal_approx(dl.sky_fraction(clear), 1.0))


func test_identity() -> void:
	var a := await applied(BASE)
	var dl: DeckLayout = a[1]
	check("the base applied to itself is accepted %s" % [a[2]], (a[2] as PackedStringArray).is_empty())
	check("the base applied to itself moves nothing (walk unchanged)", dl._moved.size() == dl.layout.bridge.props.size() and (a[0] as Node).walk_bridge == dl.orig_walk or dl._moved.is_empty())
	(a[0] as Node).queue_free()
	await process_frame


func test_walk_rule() -> void:
	var cand := DeckLayout.load_layout(BASE)
	cand.name = "walk-rule"
	cand.bridge.props = {"console_decision_3": {"position_m": [12.0, -9.5], "yaw_deg": 0.0}}
	# ship (12, -9.5) is open deck east of the spire: glTF (12, 82, 9.5)
	var demo := await new_demo()
	var dl := DeckLayout.new(demo)
	var errs := dl.apply(cand, DeckLayout.load_layout(BASE))
	await physics_frame
	var old := Vector3(-12.0, 82.0, 9.5)
	var new := Vector3(12.0, 82.0, 9.5)
	check("walk rule: applied %s" % [errs], errs.is_empty())
	check("walk rule: the console's old spot was not walkable and now is", not dl.orig_walk.is_walkable(old) and demo.walk_bridge.is_walkable(old))
	check("walk rule: the console's new spot was walkable and now is not", dl.orig_walk.is_walkable(new) and not demo.walk_bridge.is_walkable(new))
	var before := dl.orig_walk.triangle_count()
	check("walk rule: the spawn stays walkable; the rebuilt walk has %d cells (was %d triangles)" % [demo.walk_bridge.triangle_count() / 2, before], demo.walk_bridge.is_walkable(Vector3(8, 82, -4.8)) and demo.walk_bridge.triangle_count() > 0)
	demo.queue_free()
	await process_frame


func test_boom() -> void:
	var a := await applied(FIX + "boom_console.json")
	var dl: DeckLayout = a[1]
	var dir: CameraDirector = (a[0] as Node).director
	var sp := Vector3(8, 82, -4.8)
	var r := dl.level_metrics("bridge", 2, [sp])
	var who: Array = (r.get("intruders", {}) as Dictionary).keys()
	check("negative control: the moved navigation console (its group %s) is a boom intrusion at the spawn (%s)" % [DeckLayout.GROUPS.console_navigation_1, who], int(r.boom_intrusions) == 1 and who.size() == 1 and who[0] in DeckLayout.GROUPS.console_navigation_1)
	var fails := DeckLayout.failures({"views": [r]}, {"bridge": {"boom_intrusions_max": {"2": 0}}})
	check("negative control: the evaluator fails it with boom-intrusion %s" % [fails], Array(fails).any(func(s: String) -> bool: return s.begins_with("boom-intrusion z2")))
	var clean := DeckLayout.new(await new_demo())
	check("the same spawn on the shipped deck has no Z2 boom intrusion", int(clean.level_metrics("bridge", 2, [sp]).boom_intrusions) == 0)
	(a[0] as Node).queue_free()
	clean.demo.queue_free()
	await process_frame


func test_sky_prop() -> void:
	var demo := await new_demo()
	var dl := DeckLayout.new(demo)
	var dir: CameraDirector = demo.director
	var fwd: Dictionary = dir.views["sky_forward"]
	var pose: Transform3D = dl._landing(fwd, dir.anchor_of(fwd, Vector3(10, 82, 0)), false)
	var before := dl.sky_fraction(pose)
	var errs := dl.apply(DeckLayout.load_layout(FIX + "sky_prop.json"), DeckLayout.load_layout(BASE), true)
	await physics_frame
	await physics_frame
	var after := dl.sky_fraction(pose)
	var v := {"view": "sky_forward", "no_pose": 0, "sky_fraction": {"worst": after, "median": after}, "pole_clearance_deg": 30.0, "spawn_sky_fraction": 1.0, "spawn_pole_clearance_deg": 30.0}
	var fails := DeckLayout.failures({"views": [v]}, JSON.parse_string(FileAccess.get_file_as_string("res://art/deck-layout-v1/thresholds.json")))
	check("negative control: the 6 m prop drops the rail-0 sky fraction %.3f -> %.3f %s" % [before, after, errs], errs.is_empty() and before >= 0.45 and after < 0.45)
	check("negative control: the evaluator fails it with sky-fraction %s" % [fails], Array(fails).any(func(s: String) -> bool: return s.begins_with("sky-fraction")))
	demo.queue_free()
	await process_frame


func test_dominance() -> void:
	var demo := await new_demo()
	var dl := DeckLayout.new(demo)
	var dir: CameraDirector = demo.director
	var sp := Vector3(8, 82, -4.8)
	var z3: Dictionary = dir.level_view(3, "bridge")
	var pose := dir.resolve(z3, sp, dir.sector_for(sp, -1))
	var head := dir.head_of(z3, sp)
	var before: Dictionary = dl.foreground(pose, head)
	var errs := dl.apply(DeckLayout.load_layout(FIX + "dominant.json"), DeckLayout.load_layout(BASE), true)
	await physics_frame
	await physics_frame
	var after: Dictionary = dl.foreground(pose, head)
	check("negative control: the block before the Z3 eye fills %.1f%% (was %.1f%%) %s" % [100.0 * after.share, 100.0 * before.share, errs], errs.is_empty() and after.share > 0.15 and after.who == "fixture_dominant" and before.share <= 0.15)
	var v := {"view": "z3_bridge", "area": "bridge", "level": 3, "framing": true, "foreground_share": after.share, "foreground_by": after.who, "foreground_cell": 7}
	var fails := DeckLayout.failures({"views": [v]}, JSON.parse_string(FileAccess.get_file_as_string("res://art/deck-layout-v1/thresholds.json")))
	check("negative control: the evaluator fails it with frame-dominance %s" % [fails], Array(fails).any(func(s: String) -> bool: return s.begins_with("frame-dominance")))
	demo.queue_free()
	await process_frame
