extends SceneTree
## Presentation geometry and input tests; no renderer, voyage, or simulation needed.
const COCKPIT := "res://interior/chair_cockpit.gd"
const IDS := ["archive", "voyage", "navigation", "crew", "comms"]
var passed := 0
var failures := 0

func check(label: String, ok: bool) -> void:
	if ok:
		passed += 1
		print("ok ", label)
	else:
		failures += 1
		print("FAIL ", label)

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	check("chair cockpit implementation exists", ResourceLoader.exists(COCKPIT))
	if not ResourceLoader.exists(COCKPIT):
		finish()
		return
	var rig = load(COCKPIT).new()
	root.add_child(rig)
	# Installed chair sample, with the deck near the bubble's rim and a real yaw.
	var seat := Vector3(-2.629906, 82.598282, -12.311909)
	var foot := Vector3(-2.725672, 82.0, -12.575023)
	var forward := Vector3(-0.342020, 0, -0.939693).normalized()
	rig.setup({"seat": seat, "foot": foot, "forward": forward})
	var overview: Transform3D = rig.overview_pose()
	var eye := seat + Vector3.UP * 0.72
	check("overview uses seated eye, not foot reference", overview.origin.distance_to(eye) < 0.001)
	check("overview faces chair forward", (-overview.basis.z).distance_to(forward) < 0.001)
	check("all five systems have physical screens", rig.display_nodes.size() == 5)
	var right := forward.cross(Vector3.UP).normalized()
	var previous_angle := -INF
	var centres: Array[Vector3] = []
	var expected_angles := [-68.0, -34.0, 0.0, 34.0, 68.0]
	for id in IDS:
		var display: MeshInstance3D = rig.display_nodes[id]
		var centre: Vector3 = display.global_position
		var normal: Vector3 = display.global_basis.z.normalized()
		var offset := centre - eye
		var angle := rad_to_deg(atan2(offset.dot(right), offset.dot(forward)))
		check(id + " has distinct screen position", not centres.has(centre))
		centres.append(centre)
		check(id + " faces inward", normal.dot((eye - centre).normalized()) > 0.999)
		check(id + " is in ordered forward arc", angle > previous_angle and absf(angle) <= 68.01 and offset.dot(forward) > 0.0)
		check(id + " uses its assigned angle", absf(angle - expected_angles[IDS.find(id)]) < 0.01)
		previous_angle = angle
		check(id + " has readable display dimensions", display.get_aabb().size.x > 1.0 and display.get_aabb().size.y > 0.65)
		var focus: Transform3D = rig.focus_pose(id)
		check(id + " focus moves from overview", focus.origin.distance_to(eye) > 1.0)
		check(id + " focus remains above deck inside bubble", focus.origin.y > foot.y + 0.8 and focus.origin.length() < 95.0)
		check(id + " focus faces its display", (-focus.basis.z).dot((centre - focus.origin).normalized()) > 0.999)
		check(id + " focus keeps a readable distance", absf(focus.origin.distance_to(centre) - 0.65) < 0.002)
		var hit: Dictionary = rig.pick_ray(eye, centre - eye)
		check(id + " centre picks correct screen", hit.get("id", "") == id)
		check(id + " centre maps to UV centre", Vector2(hit.get("uv", Vector2.INF)).distance_to(Vector2(0.5, 0.5)) < 0.001)
		var corners: Array = rig.screen_corners(id)
		var expected := [Vector2.ZERO, Vector2.RIGHT, Vector2.ONE, Vector2.DOWN]
		for i in 4:
			var corner: Vector3 = corners[i]
			var corner_hit: Dictionary = rig.pick_ray(focus.origin, corner - focus.origin)
			check(id + " corner UV " + str(i), corner_hit.get("id", "") == id and Vector2(corner_hit.get("uv", Vector2.INF)).distance_to(expected[i]) < 0.002)
		check(id + " back face is ignored", rig.pick_ray(centre - normal * 0.2, normal).is_empty())
		check(id + " outside screen bounds misses", rig.pick_ray(centre + normal * 0.2 + display.global_basis.y * 2.0, -normal).is_empty())
	check("zero ray misses safely", rig.pick_ray(eye, Vector3.ZERO).is_empty())
	check("ray behind captain misses", rig.pick_ray(eye, -forward).is_empty())
	var nav_before: Transform3D = rig.display_nodes.navigation.global_transform
	var voyage_before: Transform3D = rig.display_nodes.voyage.global_transform
	rig.display_nodes.voyage.global_transform = nav_before
	rig.display_nodes.voyage.global_position -= forward * 0.3
	check("nearest display wins for overlapping ray", rig.pick_ray(eye, forward).get("id", "") == "voyage")
	rig.display_nodes.voyage.global_transform = voyage_before
	rig.set_summaries({"navigation": "New course ready", "crew": "Crew resting"})
	check("live summary updates label", rig.display_nodes.navigation.get_node("Summary").text == "New course ready")
	rig.select("navigation")
	check("selected screen labels hide for viewport", not rig.display_nodes.navigation.get_node("Title").visible and not rig.display_nodes.navigation.get_node("Summary").visible)
	check("other screen labels remain visible", rig.display_nodes.crew.get_node("Title").visible)
	var texture := GradientTexture2D.new()
	rig.set_display_texture("navigation", texture)
	check("screen accepts reusable viewport texture", rig.display_nodes.navigation.material_override.albedo_texture == texture)
	rig.select("crew")
	check("selecting another screen restores inactive labels", rig.display_nodes.navigation.get_node("Title").visible and not rig.display_nodes.crew.get_node("Title").visible)
	rig.set_display_texture("navigation", null)
	check("screen texture clears when viewport moves", rig.display_nodes.navigation.material_override.albedo_texture == null)
	# Contact remains a world-space contract even beneath transformed geometry.
	rig.position += Vector3(3.0, 1.0, 2.0)
	rig.rotation.y = 0.4
	rig.setup({"seat": seat, "foot": foot, "forward": forward})
	check("repeated setup replaces screens", rig.display_nodes.size() == 5 and rig.get_child_count() == 5)
	check("world contact survives transformed parent", rig.overview_pose().origin.distance_to(eye) < 0.001)
	var nav: MeshInstance3D = rig.display_nodes.navigation
	check("transformed rig ray picking stays in world space", rig.pick_ray(eye, nav.global_position - eye).get("id", "") == "navigation")
	rig.free()
	finish()

func finish() -> void:
	print("chair-cockpit: %d passed, %d failures" % [passed, failures])
	quit(1 if failures else 0)
