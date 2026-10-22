extends SceneTree
## R2-BRIDGE-STYLE AC8 (S5, D-106): the bridge's dressing for its views.
##   - the ten rim fronds are painted cards in the shared toon shader's card mode (no second shader), each
##     with a crossed shadow-only proxy, in the occluder fade group and the style group, none left as a mesh;
##   - the below-rail silhouettes stand on the Commons deck outside every deck slab (bottom >= 57 m, top
##     below the bridge deck's underside), shown on the bridge only;
##   - each view's foreground cards hold <= 8 % of the frame (projected bounds), never cover the forward pole
##     or the captain's head, and show only in their own view; the drift against a slide stays bounded;
##   - negative control: a seeded oversized foreground card is caught by the same measure.
const PX := Vector2i(1280, 720)
const SHARE_MAX := 0.08
var passed := 0
var failures := 0


func check(name: String, ok: bool) -> void:
	if ok: passed += 1
	else: failures += 1
	print("  %s %s" % ["ok  " if ok else "FAIL", name])


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var demo: Node = load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options = {"size": PX, "sky_state": "rest", "planet_textures": false, "planet_preload": false}
	root.add_child(demo)
	await process_frame
	check("the ship demo builds with its dressing", demo.ready_ok and demo.dressing != null)
	if not demo.ready_ok or demo.dressing == null:
		_done()
		return
	var d: ShipDressing = demo.dressing
	# Fronds.
	var props: Node3D = demo.props_visual
	var meshes_left := props.find_children("rim_frond_*", "MeshInstance3D", true, false).filter(func(n: Node) -> bool: return not (n as MeshInstance3D).mesh is QuadMesh)
	check("the rim fronds are cards, not meshes (%d cards, %d frond meshes left)" % [d.fronds.size(), meshes_left.size()], d.fronds.size() == 10 and meshes_left.is_empty())
	var cards_ok := d.fronds.all(func(c: MeshInstance3D) -> bool: return StapledonStyle.is_card(c.material_override) and c.is_in_group(StapledonStyle.GROUP) and c.is_in_group(CameraDirector.OCCLUDER_GROUP))
	check("every frond card is the toon shader's card mode, styled and in the fade group", cards_ok)
	var shader_paths := {}
	for c: MeshInstance3D in d.fronds:
		shader_paths[(c.material_override as ShaderMaterial).shader.resource_path] = true
	check("one shader for cards and surfaces (%s)" % [shader_paths.keys()], shader_paths.keys() == [StapledonStyle.TOON_PATH])
	var proxies := props.find_children("frond_shadow_*", "MeshInstance3D", true, false)
	check("each card has a shadow-only crossed proxy (%d)" % proxies.size(), proxies.size() == 10 and proxies.all(func(p: MeshInstance3D) -> bool: return p.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY))
	check("cards turn toward the camera within +-25 deg; proxies never turn", d.fronds.all(func(c: MeshInstance3D) -> bool: return is_equal_approx(float((c.material_override as ShaderMaterial).get_shader_parameter("clamp_deg")), 25.0)) and proxies.all(func(p: MeshInstance3D) -> bool: return float((p.material_override as ShaderMaterial).get_shader_parameter("clamp_deg")) == 0.0))
	# Below the rail.
	var slab_ok := true
	for mi: MeshInstance3D in d.below_rail:
		var a: AABB = mi.global_transform * mi.get_aabb()
		if a.position.y < 57.0 - 1e-3 or a.end.y > 81.3: slab_ok = false
	check("the below-rail silhouettes (%d) stand on the Commons deck, clear of the bridge's slab" % d.below_rail.size(), d.below_rail.size() >= 6 and slab_ok)
	# The views.
	for vid: String in ["bow", "astern"]:
		demo.consoles.cancel_walk()
		demo.director.release()
		demo.camera_mode = "player"
		demo.director.walk(vid)
		var worst := 0.0
		var covers := false
		var shown_elsewhere := false
		for foot: Vector3 in [demo.bridge_spawn(), demo.consoles.stations.navigation.use, demo.walk_bridge.closest_walkable(Vector3(-12, 82, 4), 4.0)]:
			demo.avatar_pos = foot
			for k in 240:
				demo._process(1.0 / 60.0)
			var share := 0.0
			var pose: Transform3D = demo.camera.global_transform
			var v := Vector2(PX)
			var pole := CameraDirector.screen_point(pose, pose.origin + CameraDirector.pole_dir() * 1000.0, v)
			var head := CameraDirector.screen_point(pose, foot + Vector3.UP * 1.6, v)
			for pair: Array in d.foreground.get(vid, []):
				var r := _rect(demo.camera, pair[0])
				share += r.get_area() / (v.x * v.y)
				if (not is_nan(pole.x) and r.has_point(pole)) or (not is_nan(head.x) and r.has_point(head)): covers = true
			for other: String in d.foreground:
				if other != vid:
					for pair: Array in d.foreground[other]:
						if (pair[0] as MeshInstance3D).visible: shown_elsewhere = true
			worst = maxf(worst, share)
		check("%s: the foreground holds %.1f %% of the frame (<= %d %%), covers neither the pole nor the head" % [vid, worst * 100.0, roundi(SHARE_MAX * 100.0)], worst <= SHARE_MAX and worst > 0.0 and not covers)
		check("%s: other views' foreground hidden" % vid, not shown_elsewhere)
	# The drift is bounded.
	demo.director.walk("bow")
	demo.avatar_pos = demo.bridge_spawn()
	for k in 120: demo._process(1.0 / 60.0)
	demo.avatar_pos = demo.walk_bridge.closest_walkable(Vector3(-12, 82, 4), 4.0)
	for k in 240: demo._process(1.0 / 60.0)
	var pair0: Array = d.foreground.bow[0]
	var expected: Vector3 = demo.camera.global_position + demo.camera.global_basis * pair0[1]
	var drift := ((pair0[0] as MeshInstance3D).global_position - expected)
	check("the foreground's drift against a slide stays within %.1f m (%.2f m)" % [ShipDressing.DRIFT_MAX_M, drift.length()], drift.length() <= ShipDressing.DRIFT_MAX_M + 1e-3)
	# Negative control: an oversized foreground card is caught.
	var big: MeshInstance3D = d._card("foreground_seeded", StapledonStyle.card_texture("frond"), 6.0)
	d.add_child(big)
	big.global_transform = Transform3D(demo.camera.global_basis, demo.camera.global_position + demo.camera.global_basis * Vector3(0, -1.5, -4.0))
	var seeded := _rect(demo.camera, big).get_area() / float(PX.x * PX.y)
	check("negative control: a seeded oversized card measures %.0f %% and would fail" % (seeded * 100.0), seeded > SHARE_MAX)
	big.queue_free()
	_done()


## The card's projected bounds, clipped to the frame.
func _rect(cam: Camera3D, mi: MeshInstance3D) -> Rect2:
	var a: AABB = mi.global_transform * mi.get_aabb()
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for i in 8:
		var p := a.get_endpoint(i)
		if cam.is_position_behind(p): continue
		var s := cam.unproject_position(p)
		lo = Vector2(minf(lo.x, s.x), minf(lo.y, s.y))
		hi = Vector2(maxf(hi.x, s.x), maxf(hi.y, s.y))
	if lo.x == INF: return Rect2()
	var r := Rect2(lo, hi - lo)
	return r.intersection(Rect2(Vector2.ZERO, Vector2(PX)))


func _done() -> void:
	print("dressing-test: %d passed, %d failures" % [passed, failures])
	quit(1 if failures else 0)
