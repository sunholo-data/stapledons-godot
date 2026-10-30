extends SceneTree
## D-139 opt-in art review. Does not change normal game setup or the published dev channel.
const OUT := "res://renders/npc-painted-v1"
const DATA := "res://assets/characters/npcs"
var errors: Array[String] = []
var frames: Array[Dictionary] = []
func _initialize() -> void: _run.call_deferred()
func _image(path: String) -> Texture2D:
	var image := Image.new()
	image.load_png_from_buffer(FileAccess.get_file_as_bytes(path))
	return ImageTexture.create_from_image(image)
func _label(parent: Node, value: String, at: Vector2, size: int = 19) -> void:
	var label := Label.new(); label.text = value; label.position = at
	label.add_theme_font_size_override("font_size", size); label.add_theme_color_override("font_color", Color("e9dfcb")); parent.add_child(label)
func _picture(parent: Node, path: String, at: Vector2, scale: Vector2) -> void:
	var sprite := Sprite2D.new(); sprite.texture = _image(path); sprite.centered = false; sprite.position = at; sprite.scale = scale; parent.add_child(sprite)
func _save(name: String) -> void:
	await process_frame; await process_frame; await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := OUT.path_join(name + ".png")
	if image == null or image.is_empty() or image.save_png(path) != OK: errors.append("capture failed " + name); return
	frames.append({"file": path, "sha256": FileAccess.get_sha256(path), "pixels": [image.get_width(), image.get_height()]})
	print("npc-capture: ", path)
func _backdrop(size: Vector2i) -> Control:
	root.size = size; root.content_scale_size = size
	var board := Control.new(); root.add_child(board)
	var bg := ColorRect.new(); bg.color = Color("282a32"); bg.size = size; board.add_child(bg)
	return board
func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	var painter = load("res://demos/painted_npc_pilot.gd")
	var catalog: Dictionary = painter.read_catalog()
	if catalog.is_empty(): _finish("invalid catalog"); return
	var board := _backdrop(Vector2i(1440, 1050))
	_label(board, "Painted NPC pilot · three residents and two crew", Vector2(32, 14), 25)
	var poses: Array = painter.POSES
	for col in poses.size(): _label(board, str(poses[col]).replace("_", " "), Vector2(210 + col * 242, 60), 17)
	for row in catalog.characters.size():
		var person: Dictionary = catalog.characters[row]
		_label(board, person.name, Vector2(24, 150 + row * 180), 18)
		for col in poses.size(): _picture(board, DATA.path_join(person.poses[poses[col]].file), Vector2(215 + col * 242, 88 + row * 180), Vector2.ONE * .6)
	await _save("poses")
	board.free()
	board = _backdrop(Vector2i(1440, 520))
	_label(board, "Captain and Commons cast · matching human scale", Vector2(32, 15), 25)
	_picture(board, "res://assets/characters/captain/avatar_captain_y0_front.png", Vector2(20, 49), Vector2.ONE * .26)
	_label(board, "Captain · reference", Vector2(55, 466), 17)
	for i in catalog.characters.size():
		var person: Dictionary = catalog.characters[i]
		_picture(board, DATA.path_join(person.poses.front.file), Vector2(280 + i * 225, 70), Vector2.ONE * 1.3)
		_label(board, person.name, Vector2(305 + i * 225, 466), 17)
	await _save("lineup")
	board.free()
	root.size = Vector2i(1280, 720); root.content_scale_size = root.size
	var demo: Node = load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options = {"size": root.size, "stars": false, "background": false, "sound": false, "sky_state": "rest", "civic_art": true, "settings_dir": "res://.godot/tmp/npc-review-settings"}
	root.add_child(demo); await process_frame
	demo.auto = false; demo.journey_auto_tick = false
	if not await demo.await_civic_art(): demo.queue_free(); _finish("civic installation failed"); return
	var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://art/commons-grown-pilot/placements.json"))
	var result: Dictionary = painter.install(demo, doc.residents)
	if not result.ok: demo.queue_free(); _finish(str(result.errors)); return
	var old: Node = demo.civic_art.node.find_child("CommonsLifePilot", true, false)
	if old == null: demo.queue_free(); _finish("mesh proxy root missing"); return
	old.set_process(false); old.visible = false
	demo.active_level = 1; demo.walk = demo.walk_lower; demo.camera_mode = "player"; demo.ship_hud.visible = false
	demo.set_process(false); demo.director.set_motion("reduced"); demo.camera_motion = "reduced"
	var overlay := CanvasLayer.new(); root.add_child(overlay)
	var caption := Control.new(); overlay.add_child(caption)
	for foot: Vector3 in [Vector3(26, 57.025, -4), Vector3(24, 57.025, -8), Vector3(24, 57.025, -12)]:
		if not demo.walk_lower.is_walkable_near(foot): errors.append("unsupported review pose " + str(foot)); continue
		for view: String in ["bow", "astern"]:
			demo.avatar_pos = foot; demo.avatar.position = foot; demo.captain_yaw = -PI * .5
			demo.director.release(); demo.director.zoom_preset = false; demo.director.deck_view = view; demo.director.mapping_view = view; demo.director.has_pose = false; demo.director._blend = {}
			demo._process(0.); result.node.update_view()
			for child: Node in caption.get_children(): child.free()
			_label(caption, "PAINTED NPC PILOT · " + view.capitalize() + " · Medic and Engineer among residents", Vector2(22, 18), 18)
			await _save("court_%s_%d" % [view, int(foot.z)])
	FileAccess.open(OUT.path_join("review.json"), FileAccess.WRITE).store_string(JSON.stringify({"status": "appearance review pending; opt-in only", "catalog_sha256": FileAccess.get_sha256(DATA.path_join("manifest.json")), "resident_count": result.residents.size(), "crew_ids": result.crew.keys(), "animation": "static poses; no sliding", "camera": "actual fixed player Bow/Astern, unchanged; stationary sky disabled for character inspection", "frames": frames, "errors": errors}, "  ") + "\n")
	overlay.free(); demo.queue_free(); await process_frame
	_finish()
func _finish(message: String = "") -> void:
	if not message.is_empty(): errors.append(message)
	for error: String in errors: printerr("FAIL ", error)
	print("painted-npc-capture: %d frames, %d failures" % [frames.size(), errors.size()])
	quit(1 if not errors.is_empty() else 0)
