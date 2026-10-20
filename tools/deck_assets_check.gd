extends SceneTree
## R2-DECK-LAYOUT §D5 / AC7: make deck-assets-check. The runtime deck assets against
## art/deck-layout-v2/budgets.json:
##   pins       every pinned file's bytes and sha256
##   glb        per GLB: bytes, triangles, materials, images under their budgets, the named nodes
##              present, every material opaque, no emissive material outside the allow list (the
##              console screens and the spire: never painted space, §D7), and a clean reimport
##              (export -> import keeps the node names and the triangle count)
##   vram       with a GPU window only: texture memory after loading the bridge, against the
##              recorded baseline plus the allowed increase (skipped headless, and says so)
##   masters    with --masters: each authoring master's sha256 (fetched by make ship-masters)
## Prints "deck-assets-check: ok (...)" or FAIL lines and "deck-assets-check: FAIL".
## --budgets <json> checks another budgets file (the test's negative fixtures).

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func check(label: String, ok: bool) -> void:
	if not ok:
		failures += 1
		print("FAIL %s" % label)


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var i := args.find("--budgets")
	var path := args[i + 1] if i >= 0 and i + 1 < args.size() else "res://art/deck-layout-v2/budgets.json"
	var b: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not b is Dictionary:
		print("FAIL budgets %s is not JSON" % path)
		print("deck-assets-check: FAIL")
		quit(1)
		return
	var pins: Dictionary = b.get("pins", {})
	for f: String in pins:
		var want: Dictionary = pins[f]
		var res := "res://" + f
		if not FileAccess.file_exists(res):
			check("pin %s: missing" % f, false)
			continue
		var bytes := FileAccess.get_file_as_bytes(res)
		check("pin %s: %d bytes, want %d" % [f, bytes.size(), want.bytes], bytes.size() == int(want.bytes))
		check("pin %s: sha256 %s, want %s" % [f, FileAccess.get_sha256(res), want.sha256], FileAccess.get_sha256(res) == str(want.sha256))
	var allow: Array = b.get("emissive_allow", [])
	var glbs: Dictionary = b.get("glb", {})
	var totals := []
	for f: String in glbs:
		totals.append(_glb(f, glbs[f], allow))
	if args.has("--masters"):
		var masters: Dictionary = b.get("masters", {})
		for f: String in masters:
			var res := "res://" + f
			check("master %s: present (make ship-masters)" % f, FileAccess.file_exists(res))
			if FileAccess.file_exists(res):
				check("master %s: sha256 %s" % [f, masters[f].sha256], FileAccess.get_sha256(res) == str(masters[f].sha256))
	var vram := await _vram(b.get("vram", {}))
	if failures == 0:
		print("deck-assets-check: ok (%d pins, %s, %s)" % [pins.size(), ", ".join(totals), vram])
	else:
		print("deck-assets-check: FAIL")
	quit(1 if failures else 0)


func _glb(f: String, want: Dictionary, allow: Array) -> String:
	var res := "res://" + f
	var doc := GLTFDocument.new()
	var st := GLTFState.new()
	var bytes := FileAccess.get_file_as_bytes(res)
	if bytes.is_empty() or (doc.append_from_buffer(bytes, res.get_base_dir(), st) if not f.ends_with(".gltf") else doc.append_from_file(res, st)) != OK:
		check("glb %s: loads" % f, false)
		return "%s unreadable" % f.get_file()
	var scene := doc.generate_scene(st) as Node3D
	var tris := _triangles(scene)
	var names := _names(scene)
	var mats := st.get_materials()
	var images := st.get_images().size()
	if want.has("max_bytes"):
		check("glb %s: %d bytes <= %d" % [f, bytes.size(), want.max_bytes], bytes.size() <= int(want.max_bytes))
	if want.has("max_triangles"):
		check("glb %s: %d triangles <= %d" % [f, tris, want.max_triangles], tris <= int(want.max_triangles))
	if want.has("max_materials"):
		check("glb %s: %d materials <= %d" % [f, mats.size(), want.max_materials], mats.size() <= int(want.max_materials))
	if want.has("max_images"):
		check("glb %s: %d images <= %d" % [f, images, want.max_images], images <= int(want.max_images))
	if want.has("images"): # the WebP route (EXT_texture_webp): every image decodes
		var decoded := st.get_images().filter(func(t: Texture2D) -> bool: return t != null and t.get_width() > 0).size()
		check("glb %s: %d images decoded, want %d" % [f, decoded, want.images], images == int(want.images) and decoded == images)
	for n: String in want.get("nodes", []):
		check("glb %s: node %s present" % [f, n], names.has(n))
	for m: Material in mats:
		if m is BaseMaterial3D:
			var bm := m as BaseMaterial3D
			check("glb %s: material %s opaque" % [f, bm.resource_name], bm.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED)
			var lit := bm.emission_enabled and bm.emission != Color.BLACK and bm.emission_energy_multiplier > 0.0
			check("glb %s: material %s emissive outside the allow list (no painted space)" % [f, bm.resource_name], not lit or bm.resource_name in allow)
	# A clean reimport: export the generated scene and import it again.
	_own(scene, scene)
	var doc2 := GLTFDocument.new()
	var st2 := GLTFState.new()
	var ok := doc2.append_from_scene(scene, st2) == OK
	var buf := doc2.generate_buffer(st2) if ok else PackedByteArray()
	var st3 := GLTFState.new()
	var back: Node3D = null
	var doc3 := GLTFDocument.new()
	if not buf.is_empty() and doc3.append_from_buffer(buf, "", st3) == OK:
		back = doc3.generate_scene(st3) as Node3D
	var back_tris := _triangles(back) if back != null else -1
	var back_names := _names(back) if back != null else []
	check("glb %s: clean reimport keeps %d triangles (%d) and the %d node names (%d%s)" % [f, tris, back_tris, names.size(), back_names.size(), (", first differing %s / %s" % [names.filter(func(x: String) -> bool: return not x in back_names).slice(0, 2), back_names.filter(func(x: String) -> bool: return not x in names).slice(0, 2)]) if back_names != names else ""], back != null and back_tris == tris and back_names == names)
	if back != null:
		back.free()
	scene.free()
	return "%s %d tris %d mats %d imgs %.1f MB" % [f.get_file(), tris, mats.size(), images, bytes.size() / 1e6]


func _own(n: Node, owner_node: Node) -> void:
	for c in n.get_children():
		c.owner = owner_node
		_own(c, owner_node)


func _triangles(n: Node) -> int:
	var t := 0
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		var m: Mesh = (n as MeshInstance3D).mesh
		for s in m.get_surface_count():
			var arr := m.surface_get_arrays(s)
			var idx: Variant = arr[Mesh.ARRAY_INDEX]
			t += (idx.size() if idx != null else (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
	for c in n.get_children():
		t += _triangles(c)
	return t


func _names(n: Node) -> Array:
	var out := []
	var stack: Array = [n]
	while not stack.is_empty():
		var c: Node = stack.pop_back()
		if c is MeshInstance3D:
			out.append(str(c.name))
		stack.append_array(c.get_children())
	out.sort()
	return out


func _vram(want: Dictionary) -> String:
	if DisplayServer.get_name() == "headless":
		return "vram skipped (headless)"
	var demo: Node = load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options = {"stars": false, "background": false, "sky_state": "rest", "size": Vector2i(1280, 720)}
	root.add_child(demo)
	for k in 6:
		await process_frame
	var mb := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED) / 1048576.0
	demo.queue_free()
	await process_frame
	if want.has("baseline_mb"):
		var limit := float(want.baseline_mb) + float(want.get("max_increase_mb", 32.0))
		check("vram %.1f MB <= %.1f (baseline %.1f + %.0f)" % [mb, limit, want.baseline_mb, want.get("max_increase_mb", 32.0)], mb <= limit)
	return "vram %.1f MB" % mb
