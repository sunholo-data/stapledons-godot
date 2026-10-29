extends SceneTree
## D-139: actual asset alpha/scale/anchors and identity-preserving crowd substitution.
var passed := 0
var failed := 0
class ReviewDemo extends Node:
	var geometry := Node3D.new()
	var camera := Camera3D.new()
func _initialize() -> void: _run.call_deferred()
func check(label: String, ok: bool) -> void:
	if ok: passed += 1
	else: failed += 1
	print("%s %s" % ["ok" if ok else "FAIL", label])
func _run() -> void:
	check("painted NPC catalog exists", FileAccess.file_exists("res://assets/characters/npcs/manifest.json"))
	check("painted crowd pilot exists", FileAccess.file_exists("res://demos/painted_npc_pilot.gd"))
	if failed: _finish(); return
	var painter = load("res://demos/painted_npc_pilot.gd")
	if painter == null: check("pilot script loads", false); _finish(); return
	var catalog: Dictionary = painter.read_catalog()
	check("complete catalog and original crew portrait hashes validate", not catalog.is_empty())
	if catalog.is_empty(): _finish(); return
	var fixture := "res://.godot/tmp/painted_npc_test"
	DirAccess.make_dir_recursive_absolute(fixture)
	for character: Dictionary in catalog.characters:
		for pose: String in character.poses:
			var file: String = character.poses[pose].file
			DirAccess.copy_absolute("res://assets/characters/npcs/" + file, fixture.path_join(file))
	var file := fixture.path_join("manifest.json")
	_write(file, catalog)
	check("catalog fixture is a positive control", not painter.read_catalog(file).is_empty())
	for fault: String in ["pose_hash", "missing_pose", "duplicate_identity", "portrait_identity", "path_escape"]:
		var bad := catalog.duplicate(true)
		match fault:
			"pose_hash": bad.characters[0].poses.front.sha256 = "wrong"
			"missing_pose": bad.characters[0].poses.erase("back")
			"duplicate_identity": bad.characters.append(bad.characters[0].duplicate(true))
			"portrait_identity": bad.characters[3].portrait = bad.characters[4].portrait
			"path_escape": bad.characters[0].poses.front.file = "../grove_front.png"
		_write(file, bad)
		check(fault + " catalog is refused", painter.read_catalog(file).is_empty())
	var demo := ReviewDemo.new(); root.add_child(demo); demo.add_child(demo.geometry); demo.geometry.add_child(demo.camera)
	var floor_mesh := MeshInstance3D.new(); var box := BoxMesh.new(); box.size = Vector3(150, .1, 150)
	floor_mesh.mesh = box; floor_mesh.position.y = 56.95; demo.geometry.add_child(floor_mesh); floor_mesh.create_trimesh_collision()
	await physics_frame; await physics_frame
	var rows: Array = [
		{"name": "court_conversation_a", "ship_m": [20, 4, 57.025], "activity": "conversation", "facing": 90},
		{"name": "court_conversation_b", "ship_m": [22, 4, 57.025], "activity": "conversation", "facing": 270},
		{"name": "reader", "ship_m": [24, 4, 57.025], "activity": "reading", "facing": 90},
		{"name": "diner", "ship_m": [26, 4, 57.025], "activity": "dining", "facing": 90, "seat_height_m": .48}
	]
	demo.camera.position = Vector3(-20, 60, -4)
	var result: Dictionary = painter.install(demo, rows)
	check("painted residents install over real floor", result.ok)
	if result.ok:
		var pilot: Node3D = result.node; pilot.set_process(false)
		check("crowd count is preserved and both crew appear exactly once", result.residents.size() == rows.size() and result.crew.size() == 2 and result.crew.has("medic") and result.crew.has("engineer"))
		check("crew figures keep console portrait identity", result.crew.medic.get_meta("portrait") == "res://data/crew/portraits/medic_neutral.png" and result.crew.engineer.get_meta("entity_id") == "engineer")
		check("ordinary resident never gets a crew identity", result.residents.reader.get_meta("entity_id") == "" and result.residents.diner.get_meta("entity_id") == "")
		check("all characters are painted sprites with no new colliders or 3D model parts", pilot.get_children().all(func(n: Node) -> bool: return n is Sprite3D and n.get_child_count() == 0))
		check("standing and seated figures choose appropriate front poses", result.crew.medic.get_meta("pose") == "front" and result.residents.diner.get_meta("pose") == "seated_front")
		demo.camera.position.x = 100.; pilot.update_view()
		check("opposite camera selects painted backs including seated rear", result.crew.medic.get_meta("pose") == "back" and result.residents.diner.get_meta("pose") == "seated_back")
		var foot: Vector3 = result.crew.medic.position
		pilot._process(100.)
		check("unanimated figures never slide and retain existing floor anchors", result.crew.medic.position == foot and foot.is_equal_approx(Vector3(20, 57.025, -4)))
		check("preview status is explicit", pilot.get_meta("preview_only") == true)
		var other: Dictionary = painter.install(demo, rows)
		check("civilian identity assignment is reproducible", other.ok and other.residents.reader.get_meta("character_id") == result.residents.reader.get_meta("character_id"))
		if other.ok: other.node.free()
		pilot.free()
	for fault: String in ["unknown_crew", "duplicate_crew", "floating", "no_crew_slots"]:
		var invalid: Array = rows.duplicate(true); var crew: Array = ["medic", "engineer"]
		match fault:
			"unknown_crew": crew = ["not-a-person"]
			"duplicate_crew": crew = ["medic", "medic"]
			"floating": invalid[0].ship_m[2] = 60.
			"no_crew_slots": invalid = [invalid[2]]
		var before := demo.geometry.get_child_count()
		var refused: Dictionary = painter.install(demo, invalid, crew)
		check(fault + " installation refuses atomically", not refused.ok and demo.geometry.get_child_count() == before)
	demo.queue_free(); await process_frame
	_finish()
func _write(path: String, value: Dictionary) -> void:
	FileAccess.open(path, FileAccess.WRITE).store_string(JSON.stringify(value))
func _finish() -> void:
	print("painted-npc-pilot: %d passed, %d failures" % [passed, failed])
	quit(1 if failed else 0)
