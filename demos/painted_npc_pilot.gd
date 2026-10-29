extends Node3D
## D-139 visual pilot only. Static painted residents, with explicit portrait-derived crew slots.
## The real game does not install this helper until the appearance review is accepted.
const CATALOG := "res://assets/characters/npcs/manifest.json"
const POSES := ["front", "back", "profile", "seated_front", "seated_back"]
var host: Node
var people: Array[Dictionary] = []
var catalog: Dictionary = {}
static func _png(path: String) -> Image:
	if not FileAccess.file_exists(path): return null
	var image := Image.new()
	return image if image.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) == OK else null

static func read_catalog(path: String = CATALOG) -> Dictionary:
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	if not value is Dictionary or value.get("schema") != "stapledons.npc.painted/1": return {}
	if value.get("canvas_px") != [192., 288.] or value.get("foot_anchor_px") != [96., 272.] or value.get("px_per_m") != 144: return {}
	if not value.get("characters") is Array or value.characters.is_empty(): return {}
	var ids := {}; var crew := {}
	for row: Variant in value.characters:
		if not row is Dictionary or not row.get("id") is String or str(row.id).is_empty() or ids.has(row.id): return {}
		if not row.get("height_m") is float or not is_finite(row.height_m) or row.height_m < 1. or row.height_m > 2.2: return {}
		if not row.get("entity_id") is String or not row.get("poses") is Dictionary: return {}
		if not str(row.entity_id).is_empty():
			if crew.has(row.entity_id) or row.entity_id != row.id or not str(row.get("portrait", "")).begins_with("res://data/crew/portraits/"): return {}
			if FileAccess.get_sha256(row.portrait) != str(row.get("portrait_sha256", "")): return {}
			crew[row.entity_id] = true
		for pose: String in POSES:
			var frame: Variant = row.poses.get(pose)
			if not frame is Dictionary or not frame.get("file") is String or str(frame.file).get_file() != frame.file: return {}
			var file := path.get_base_dir().path_join(frame.file)
			if not FileAccess.file_exists(file) or FileAccess.get_sha256(file) != str(frame.get("sha256", "")): return {}
		ids[row.id] = true
	return value

static func install(demo: Node, rows: Array, crew_entities: Array = ["medic", "engineer"], path: String = CATALOG) -> Dictionary:
	var result := {"ok": false, "node": null, "errors": [], "residents": {}, "crew": {}}
	var source := read_catalog(path)
	if source.is_empty(): result.errors.append("painted NPC catalog or identity/hash closure invalid"); return result
	var row_errors: PackedStringArray = preload("res://demos/commons_life_pilot.gd").validate(rows)
	if not row_errors.is_empty(): result.errors.append_array(row_errors); return result
	if demo == null or not demo.get("geometry") is Node3D or not demo.get("camera") is Camera3D: result.errors.append("world geometry and camera required"); return result
	var backgrounds: Array[Dictionary] = []; var named := {}; var requested := {}
	for character: Dictionary in source.characters:
		if str(character.entity_id).is_empty(): backgrounds.append(character)
		else: named[character.entity_id] = character
	if backgrounds.is_empty(): result.errors.append("civilian identities required"); return result
	for id: Variant in crew_entities:
		if not id is String or not named.has(id) or requested.has(id): result.errors.append("unknown or duplicate crew identity"); return result
		requested[id] = true
	var slots: Array[String] = []
	for preferred: String in ["court_conversation_a", "court_conversation_b"]:
		if rows.any(func(r: Dictionary) -> bool: return r.name == preferred and not r.has("seat_height_m") and r.activity == "conversation"): slots.append(preferred)
	for row: Dictionary in rows:
		if slots.size() >= crew_entities.size(): break
		if row.activity == "conversation" and not row.has("seat_height_m") and not row.name in slots: slots.append(row.name)
	if slots.size() < crew_entities.size(): result.errors.append("not enough standing conversation slots for crew"); return result
	var space: PhysicsDirectSpaceState3D = demo.camera.get_world_3d().direct_space_state
	for row: Dictionary in rows:
		var foot := ShipFrame.gltf_from_structure(row.ship_m)
		var ray := PhysicsRayQueryParameters3D.create(foot + Vector3.UP * .1, foot - Vector3.UP * .15); ray.hit_back_faces = true
		var hit := space.intersect_ray(ray)
		if hit.is_empty() or absf((hit.position as Vector3).y - foot.y) > .035 or (hit.normal as Vector3).dot(Vector3.UP) < .9: result.errors.append("resident lacks floor: " + str(row.name)); return result
	var pilot = load("res://demos/painted_npc_pilot.gd").new()
	pilot.name = "PaintedNPCPilot"; pilot.host = demo; pilot.catalog = source
	pilot.set_meta("preview_only", true)
	var textures := {}
	for character: Dictionary in source.characters:
		textures[character.id] = {}
		for pose: String in POSES:
			var image := _png(path.get_base_dir().path_join(character.poses[pose].file))
			if image == null or image.get_size() != Vector2i(192, 288):
				pilot.free(); result.errors.append("invalid painted pose image"); return result
			image.generate_mipmaps(); textures[character.id][pose] = ImageTexture.create_from_image(image)
	for row: Dictionary in rows:
		var character: Dictionary = backgrounds[_stable_seed(row.name) % backgrounds.size()]
		var slot := slots.find(row.name)
		if slot >= 0 and slot < crew_entities.size(): character = named[crew_entities[slot]]
		var sprite := Sprite3D.new(); sprite.name = row.name
		sprite.position = ShipFrame.gltf_from_structure(row.ship_m)
		sprite.centered = false; sprite.offset = Vector2(-96, -16); sprite.pixel_size = 1. / 144.
		sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y; sprite.shaded = false
		sprite.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
		sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		sprite.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		sprite.set_meta("character_id", character.id); sprite.set_meta("entity_id", character.entity_id)
		sprite.set_meta("portrait", character.portrait); sprite.set_meta("activity", row.activity)
		pilot.add_child(sprite)
		pilot.people.append({"sprite": sprite, "row": row.duplicate(true), "character": character, "textures": textures[character.id]})
		result.residents[row.name] = sprite
		if not str(character.entity_id).is_empty(): result.crew[character.entity_id] = sprite
	demo.geometry.add_child(pilot); pilot.update_view()
	result.ok = true; result.node = pilot
	return result

static func _stable_seed(value: String) -> int:
	var seed := 17
	for byte: int in value.to_utf8_buffer(): seed = (seed * 131 + byte) % 2147483647
	return seed

func _process(_delta: float) -> void: update_view()
func update_view() -> void:
	if not is_instance_valid(host): return
	for person: Dictionary in people:
		var sprite: Sprite3D = person.sprite
		var toward: Vector3 = host.camera.global_position - sprite.global_position; toward.y = 0.
		var forward := Basis(Vector3.UP, deg_to_rad(float(person.row.facing))) * Vector3.FORWARD
		var front := forward.dot(toward.normalized())
		var seated: bool = person.row.activity == "dining" or person.row.has("seat_height_m")
		var pose := ("seated_front" if front >= 0. else "seated_back") if seated else ("front" if front > .35 else ("back" if front < -.35 else "profile"))
		sprite.texture = person.textures[pose]
		var desired_x := forward.dot(host.camera.global_basis.x)
		var painted_x: int = int(person.character.front_x) if pose in ["front", "seated_front"] else (1 if pose in ["back", "seated_back"] else -1)
		sprite.flip_h = (desired_x < 0.) != (painted_x < 0.) if absf(desired_x) > .1 else false
		sprite.set_meta("pose", pose)
