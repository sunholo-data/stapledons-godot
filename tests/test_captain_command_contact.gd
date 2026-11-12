extends SceneTree
## Chair's installed anchor is measured against the actual cushion, not a nominal furniture origin.
const CONTACT := "res://interior/captain_chair_contact.gd"
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
	check("a chair contact implementation exists", ResourceLoader.exists(CONTACT))
	if not ResourceLoader.exists(CONTACT):
		finish()
		return
	var contact = load(CONTACT)
	var demo: Node = load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options = {"stars": false, "background": false}
	root.add_child(demo)
	await process_frame
	demo.auto = false
	demo.journey_auto_tick = false
	var record: Dictionary = contact.measure(demo.props_visual)
	check("real chair and cushion are measured", not record.is_empty())
	if not record.is_empty():
		var chair: MeshInstance3D = demo.props_visual.find_child("captain_chair", true, false)
		var cushion: MeshInstance3D = demo.props_visual.find_child("v2_chair_detail_00", true, false)
		var centre: Vector3 = cushion.global_transform * cushion.get_aabb().get_center()
		var seat: Vector3 = record.seat
		var foot: Vector3 = record.foot
		check("seat reference is centred on the installed cushion", Vector2(seat.x, seat.z).distance_to(Vector2(centre.x, centre.z)) < 0.001)
		check("cushion top is 59.8 cm above this chair's base", absf(seat.y - chair.global_position.y - 0.598284) < 0.002)
		check("foot root stays at the deck, not on the cushion", absf(foot.y - chair.global_position.y) < 0.001)
		var guide_pelvis: Vector3 = foot - Vector3(record.forward) * 0.28
		check("guide pelvis lands at the cushion centre in plan", Vector2(guide_pelvis.x, guide_pelvis.z).distance_to(Vector2(centre.x, centre.z)) < 0.001)
		check("chair facing comes from its installed 20 degree rotation", Vector3(record.forward).distance_to(Vector3(-0.342020, 0, -0.939693)) < 0.001)
		check("installed runtime uses measured foot root", Vector3(demo.chair_seat()).distance_to(foot) < 0.001)
		var props_before: Vector3 = demo.props_visual.global_position
		demo.props_visual.global_position += Vector3.RIGHT * 0.05
		check("moving installed furniture moves its runtime contact instead of keeping a stale point", Vector3(demo.chair_seat()).distance_to(foot + Vector3.RIGHT * 0.05) < 0.001)
		demo.props_visual.global_position = props_before
		check("contact accepts its measured root and facing", contact.matches(record, foot, record.forward))
		for direction in [Vector3.RIGHT, Vector3.UP, Vector3.BACK]:
			check("5 cm displaced root is rejected " + str(direction), not contact.matches(record, foot + direction * 0.05, record.forward))
		check("opposite-facing pose is rejected", not contact.matches(record, foot, -Vector3(record.forward)))
		var empty := Node3D.new()
		check("contact helper fails closed without chair geometry", contact.measure(empty).is_empty())
		empty.free()
	demo.queue_free()
	await process_frame
	finish()

func finish() -> void:
	print("captain-command-contact: %d passed, %d failures" % [passed, failures])
	quit(1 if failures else 0)
