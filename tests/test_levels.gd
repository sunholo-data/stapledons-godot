extends SceneTree
## R2-LEVELS LP0/LP1a (design_docs/planned/r2/levels.md §A4, §B2, AC2, AC3; ledger D-103): make level-test.
##   schema     stapledons.level/1: the shipped manifests validate; a turning stage view, an exit to an
##              unknown stage, a route missing an end and a captain band outside 30-90 px are rejected
##   greybox    LevelGreybox builds box and arc pieces (D-104) with colliders; surfaces are WALK_
##              meshes the walk can stand on; the manifest it writes validates
##   walk       the multi-height rule: under an upper floor the captain stays on the lower one; a ramp
##              joins two floors; walking off a raised edge is refused; on the shipped bridge every
##              step is what the single-height rule gave
##   transfers  ladders and hatches move the captain between their ends; each end stands on walk
##              ground, including a hatch at an overhang's edge
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
	await test_greybox()
	await test_walk()
	await test_transfers()
	test_bridge_walk_unchanged()
	print("level-test: %d passed, %d failures" % [passes, failures])
	quit(1 if failures else 0)


func _load(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func _rejects(m: Dictionary, fragment: String) -> bool:
	for e: String in LevelSchema.validate(m):
		if e.contains(fragment):
			return true
	return false


func test_schema() -> void:
	for path: String in ["res://assets/levels/bridge/manifest.json", "res://tests/fixtures/levels/two_floor.json"]:
		var m := _load(path)
		var errs := LevelSchema.validate(m)
		check("%s validates (%s)" % [path, errs], errs.is_empty())
	var base := _load("res://tests/fixtures/levels/two_floor.json")
	var turning: Dictionary = base.duplicate(true)
	turning.stages[0].views[0]["yaw_rule"] = "sector"
	check("a stage view with a yaw rule (a turning view) is rejected", _rejects(turning, "turns"))
	var exit: Dictionary = base.duplicate(true)
	exit.stages[0].exits = [{"to": "nowhere", "at": [0, 0], "width_m": 2}]
	check("an exit to an unknown stage is rejected", _rejects(exit, "unknown stage"))
	var route: Dictionary = base.duplicate(true)
	route.routes[0].erase("to")
	check("a route missing an end is rejected", _rejects(route, "route"))
	var band: Dictionary = base.duplicate(true)
	band.stages[0].views[0]["captain_px"] = [20, 120]
	check("a captain band outside 30-90 px is rejected", _rejects(band, "captain_px"))
	var schema: Dictionary = base.duplicate(true)
	schema.schema = "stapledons.level/0"
	check("a wrong schema id is rejected", _rejects(schema, "schema"))
	var fol: Dictionary = base.duplicate(true)
	fol["layers"] = {"foliage": [{"card": "frond_curl_v1", "at": [1, 2, 3], "scale": 1.2, "layer": "stage", "sway": 0.3}]}
	check("a painted foliage card (card, at, scale, layer, sway; D-106) validates", LevelSchema.validate(fol).is_empty())
	fol.layers.foliage[0].layer = "sky"
	check("a foliage card on an unknown layer is rejected", _rejects(fol, "foliage"))
	fol.layers.foliage = [{"card": "frond_curl_v1", "at": [1, 2, 3], "scale": 0.0, "layer": "fore", "sway": 0.3}]
	check("a foliage card with no scale is rejected", _rejects(fol, "foliage"))
	fol.layers.foliage = "plants"
	check("a foliage hook that is not a list is rejected", _rejects(fol, "foliage"))


## A greybox level under the window's 3D world, colliders flushed.
func _build(path: String) -> Dictionary:
	var holder := Node3D.new()
	root.add_child(holder)
	var layout := _load(path)
	var gb := LevelGreybox.build(layout, holder)
	for k in 3:
		await physics_frame
	return {"holder": holder, "gb": gb, "layout": layout}


func _ray(from: Vector3, to: Vector3) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(from, to)
	return root.world_3d.direct_space_state.intersect_ray(q)


func test_greybox() -> void:
	var b := await _build("res://tests/fixtures/levels/two_floor.json")
	var gb: Dictionary = b.gb
	check("greybox built %d pieces, %d walk surfaces" % [gb.pieces, gb.surfaces], gb.pieces == 7 and gb.surfaces == 5)
	var down := _ray(Vector3(0, 20, -6), Vector3(0, -5, -6))
	check("an upper-floor box has a collider (ray hit y %.2f)" % (float(down.position.y) if not down.is_empty() else NAN), not down.is_empty() and absf(down.position.y - 4.0) < 0.05)
	var arc := _ray(Vector3(10 * cos(deg_to_rad(-60.0)), 20, 10 * sin(deg_to_rad(-60.0))), Vector3(10 * cos(deg_to_rad(-60.0)), -5, 10 * sin(deg_to_rad(-60.0))))
	check("an arc catwalk has a collider along its curve (D-104)", not arc.is_empty() and absf(arc.position.y - 8.0) < 0.05)
	var walk: WalkArea = gb.walk
	check("the arc catwalk is walk ground at its mid-radius", not is_nan(walk.height_at_near(10 * cos(deg_to_rad(-60.0)), 10 * sin(deg_to_rad(-60.0)), 8.0)))
	var man: Dictionary = gb.manifest
	check("the greybox writes a manifest that validates (%s)" % [LevelSchema.validate(man)], LevelSchema.validate(man).is_empty())
	check("the greybox records its layout sha256", str(man.get("layout_sha256", "")).length() == 64)
	b.holder.queue_free()


func test_walk() -> void:
	var b := await _build("res://tests/fixtures/levels/two_floor.json")
	var walk: WalkArea = b.gb.walk
	# the lower floor at y 0 spans z -12..0; the upper floor at y 4 covers z -12..-4 at x -3..3
	var under := Vector3(0, 0, -2)
	var p := under
	for i in 12:
		p = walk.step(p, Vector3(0, 0, -0.5))
	check("walking under the upper floor keeps the captain on the lower one (y %.2f at z %.1f)" % [p.y, p.z], absf(p.y) < 0.01 and p.z < -6.0)
	check("the old highest-hit rule would have put the captain on top (%.2f)" % walk.height_at(0, -6), absf(walk.height_at(0, -6) - 4.0) < 0.01)
	var r := Vector3(6, 0, -1)
	for i in 30:
		r = walk.step(r, Vector3(0, 0, -0.4))
	check("the ramp joins the two floors (climbed to y %.2f)" % r.y, absf(r.y - 4.0) < 0.05)
	var top := Vector3(0, 4, -8)
	var off := walk.step(top, Vector3(0, 0, 4.5))
	check("walking off the raised edge is refused (stays at z %.2f)" % off.z, absf(off.z - top.z) < 0.6 and absf(off.y - 4.0) < 0.01)
	b.holder.queue_free()


func test_transfers() -> void:
	var b := await _build("res://tests/fixtures/levels/two_floor.json")
	var walk: WalkArea = b.gb.walk
	var routes: Array = b.layout.routes
	var n := 0
	for rt: Dictionary in routes:
		if not str(rt.kind) in ["ladder", "hatch"]:
			continue
		var a := LevelGreybox.route_end(rt, "from")
		var z := LevelGreybox.route_end(rt, "to")
		var ok_a := walk.is_walkable_near(a)
		var ok_z := walk.is_walkable_near(z)
		var moved := LevelGreybox.transfer(walk, rt, a)
		check("%s %s: both ends stand on walk ground (%s, %s) and the transfer lands on the far end (%s)" % [rt.kind, rt.id, ok_a, ok_z, moved], ok_a and ok_z and moved.distance_to(z) < 0.05)
		n += 1
	check("the fixture has a ladder and a hatch at an overhang's edge (%d transfers)" % n, n == 2)
	b.holder.queue_free()


## The shipped bridge walk: every 0.5 m sample, four 0.5 m moves each, gives the same result with
## the multi-height rule as with the single-height rule (one surface, so they must agree).
func test_bridge_walk_unchanged() -> void:
	var scene: Node3D = AreaBundle.load_glb("res://assets/ship_demo/walk_bridge.glb")
	var walk := WalkArea.from_scene(scene, 0.35)
	var n := 0
	var diff := 0
	var x := -22.0
	while x <= 22.0:
		var z := -22.0
		while z <= 22.0:
			var y := walk.height_at(x, z)
			if not is_nan(y) and walk.is_walkable(Vector3(x, y, z)):
				var p := Vector3(x, y, z)
				for d: Vector3 in [Vector3(0.5, 0, 0), Vector3(-0.5, 0, 0), Vector3(0, 0, 0.5), Vector3(0, 0, -0.5)]:
					n += 1
					if not walk.step(p, d).is_equal_approx(_step_highest(walk, p, d)):
						diff += 1
			z += 0.5
		x += 0.5
	check("bridge walk: %d moves, %d differ from the single-height rule" % [n, diff], n > 10000 and diff == 0)
	scene.free()


## The pre-LP1a step (highest hit), kept here as the reference.
func _step_highest(w: WalkArea, from: Vector3, delta: Vector3) -> Vector3:
	for d in [Vector3(delta.x, 0.0, delta.z), Vector3(delta.x, 0.0, 0.0), Vector3(0.0, 0.0, delta.z)]:
		var p: Vector3 = from + d
		if d != Vector3.ZERO and w.is_walkable(p):
			return Vector3(p.x, w.height_at(p.x, p.z), p.z)
	return from
