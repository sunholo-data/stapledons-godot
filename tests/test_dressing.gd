extends SceneTree
## R2-BRIDGE-STYLE AC8 (S5, D-106): the bridge's dressing for its views.
##   - the ten rim fronds are painted cards in the shared toon shader's card mode (no second shader), each
##     with a crossed shadow-only proxy, in the occluder fade group and the style group, none left as a mesh;
##   - the below-rail silhouettes stand on the Commons deck outside every deck slab (bottom >= 57 m, top
##     below the bridge deck's underside), shown on the bridge only;
##   - every plant stands on the deck and its footprint clears the lift, its guards and its landing (the
##     lift's real triangles); negative control: a plant seeded on the lift guard;
##   - the plants vary (D-106): >= 3 painted kinds, no two neighbours alike, some mirrored.
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
	# Placement (Mark on #322: a plant stood over the lift's railing): every plant stands on the deck's walk
	# or ground and its footprint (a cylinder of PLANT_R round its root, its height) touches no lift,
	# shaft-guard or other walk-blocking triangle, and keeps clear of the lift's landing.
	var blockers := _blockers(demo)
	var bad := []
	for c: MeshInstance3D in d.fronds:
		var why := _placement(demo, c, float(c.get_meta("height_m", 1.9)), blockers)
		if why != "": bad.append("%s: %s" % [c.name, why])
	check("every plant stands on the deck and clears the lift, its guards, the rim rail and the landing (%d plants%s)" % [d.fronds.size(), (": " + str(bad)) if not bad.is_empty() else ""], bad.is_empty() and d.fronds.size() == 10)
	# Negative control: a plant seeded on the lift's guard rail is caught.
	var seeded: MeshInstance3D = d._card("rim_frond_seeded", StapledonStyle.card_texture("frond"), 1.9)
	demo.props_visual.add_child(seeded)
	seeded.global_position = Vector3(5.8, 82.0, -8.0)
	var why_seeded := _placement(demo, seeded, 1.9, blockers)
	check("negative control: a plant seeded on the lift guard is caught (%s)" % why_seeded, why_seeded != "")
	seeded.queue_free()
	# Variety (D-106): at least three painted kinds, no two neighbours alike, mirrors and tints vary.
	var kinds := d.fronds.map(func(c: MeshInstance3D) -> String: return str(c.get_meta("kind", "")))
	var neighbours_differ := true
	for k in kinds.size():
		if kinds[k] == kinds[(k + 1) % kinds.size()]: neighbours_differ = false
	var distinct := {}
	for k: String in kinds: distinct[k] = true
	var flips := d.fronds.filter(func(c: MeshInstance3D) -> bool: return (c.material_override as ShaderMaterial).get_shader_parameter("card_flip") == true).size()
	check("the rim plants vary: %d kinds %s, no two neighbours alike, %d of 10 mirrored" % [distinct.size(), distinct.keys(), flips], distinct.size() >= 3 and neighbours_differ and flips > 0 and flips < 10)
	_done()


## The card's projected bounds, clipped to the frame.
const PLANT_R := 0.45 # the footprint a plant's pot or root mass takes on the deck (m)
const LANDING := Vector3(8, 82, -4.8) # the lift's board point (ship_demo_lift.gd BOARD_POINT)


## The lift's pieces, the shaft guards and guides, and the rim rail: their world triangles.
func _blockers(demo: Node) -> Array:
	var out := []
	var stack: Array = [demo.lift, demo.props_visual]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		stack.append_array(n.get_children())
		if not (n is MeshInstance3D and (n as MeshInstance3D).mesh != null and n.is_visible_in_tree()): continue
		var nm := String(n.name)
		if not (demo.lift.is_ancestor_of(n) or nm.begins_with("Guardrail") or nm.begins_with("Lift guide") or nm.begins_with("rim_rail")): continue
		var mi := n as MeshInstance3D
		for sidx in mi.mesh.get_surface_count():
			var arr := mi.mesh.surface_get_arrays(sidx)
			var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX] != null else PackedInt32Array(range(v.size()))
			for t in range(0, idx.size(), 3):
				out.append([mi.global_transform * v[idx[t]], mi.global_transform * v[idx[t + 1]], mi.global_transform * v[idx[t + 2]]])
	return out


## "" when the plant stands on the deck and its footprint is clear; else why not.
func _placement(demo: Node, c: MeshInstance3D, h: float, blockers: Array) -> String:
	var root := c.global_position
	var w: Vector3 = demo.walk_bridge.closest_walkable(root, 3.0)
	var space: PhysicsDirectSpaceState3D = demo.geometry.get_world_3d().direct_space_state
	var ground := space.intersect_ray(PhysicsRayQueryParameters3D.create(root + Vector3.UP * 0.3, root + Vector3.DOWN * 0.3))
	if root.distance_to(w) > 0.6 and ground.is_empty(): return "not on the deck"
	if Vector2(root.x - LANDING.x, root.z - LANDING.z).length() < 2.0: return "on the lift's landing"
	for k in 12:
		var a := TAU * k / 12.0
		var off := Vector3(cos(a), 0.0, sin(a)) * PLANT_R
		for seg: Array in [[root + off + Vector3.UP * 0.05, root + off + Vector3.UP * h], [root + Vector3.UP * 0.3, root + off + Vector3.UP * 0.3]]:
			for tri: Array in blockers:
				if Geometry3D.segment_intersects_triangle(seg[0], seg[1], tri[0], tri[1], tri[2]) != null:
					return "touches the lift, its guards or the rim rail"
	return ""


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
