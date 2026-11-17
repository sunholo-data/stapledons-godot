extends SceneTree
const C := preload("res://tools/content_contract.gd")
const ROOT := "res://.godot/tmp/content-stage/"
var failures := 0
var checks := 0
func check(label: String, ok: bool) -> void:
	checks += 1
	if not ok: failures += 1; printerr("FAIL ", label)
func _initialize() -> void:
	var source := ROOT + "source/bridge-finish/"
	var target := ROOT + "output/"
	DirAccess.make_dir_recursive_absolute(source + "compiled")
	var image := Image.create_empty(8, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color.TEAL); image.generate_mipmaps()
	var texture := ImageTexture.create_from_image(image)
	texture.take_over_path(source + "paint.res")
	ResourceSaver.save(texture, texture.resource_path, ResourceSaver.FLAG_COMPRESS)
	var material := ShaderMaterial.new()
	material.shader = load("res://shaders/stapledon_toon.gdshader")
	material.set_shader_parameter("albedo_tex", texture)
	material.take_over_path(source + "material.res")
	ResourceSaver.save(material, material.resource_path, ResourceSaver.FLAG_COMPRESS)
	var builder := SurfaceTool.new(); builder.begin(Mesh.PRIMITIVE_TRIANGLES)
	builder.set_material(material)
	for p: Vector3 in [Vector3.ZERO, Vector3.RIGHT, Vector3.FORWARD]: builder.add_vertex(p)
	var mesh := builder.commit()
	var mesh_path := source + "compiled/000.res"
	ResourceSaver.save(mesh, mesh_path, ResourceSaver.FLAG_COMPRESS)
	var doc := {"schema": "stapledons.bridge-painted-finish/1", "resources": {texture.resource_path: FileAccess.get_sha256(texture.resource_path), material.resource_path: FileAccess.get_sha256(material.resource_path)}, "meshes": [{"file": mesh_path, "sha256": FileAccess.get_sha256(mesh_path), "triangles": 1}]}
	FileAccess.open(source + "manifest.json", FileAccess.WRITE).store_string(JSON.stringify(doc))
	var source_pin := FileAccess.get_sha256(source + "manifest.json")
	var outputs := []
	for pass_index: int in 2:
		var output := []
		var rc := OS.execute(OS.get_executable_path(), ["--headless", "--path", ProjectSettings.globalize_path("res://"), "--log-file", ProjectSettings.globalize_path(ROOT + "stage-%d-engine.log" % pass_index), "--script", "res://tools/painted_levels_stage.gd", "--", "--source", ROOT + "source/", "--dest", target, "--deck", "bridge"], output, true)
		var text := "\n".join(output)
		check("existing stage succeeds in scratch " + str(pass_index) + ": " + text, rc == 0 and "SCRIPT ERROR" not in text and "PAINTED_LEVELS_STAGE bridge" in text)
		var staged := C.doc(target + "bridge/manifest.json")
		if staged.is_empty(): check("scratch manifest exists", false); finish(); return
		var files: Dictionary = staged.resources.duplicate()
		for row: Dictionary in staged.meshes: files[row.file] = row.sha256
		var pins := {}
		for path: String in files: pins[path] = FileAccess.get_sha256(path)
		pins[target + "bridge/manifest.json"] = FileAccess.get_sha256(target + "bridge/manifest.json")
		outputs.append(pins)
		var cooked: Mesh = ResourceLoader.load(str(staged.meshes[0].file), "", ResourceLoader.CACHE_MODE_IGNORE)
		check("stage preserves exact source faces", cooked.get_faces() == mesh.get_faces())
	check("two same-input stages are byte-identical", outputs[0] == outputs[1])
	check("authoring manifest unchanged", source_pin == FileAccess.get_sha256(source + "manifest.json"))
	check("source resource pins unchanged", doc.resources.keys().all(func(path: String) -> bool: return FileAccess.get_sha256(path) == doc.resources[path]) and FileAccess.get_sha256(mesh_path) == doc.meshes[0].sha256)
	finish()
func finish() -> void:
	print("content-stage: %d passed, %d failures" % [checks - failures, failures]); quit(1 if failures else 0)
