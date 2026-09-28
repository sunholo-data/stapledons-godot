extends Node3D
## SPIKE v2 (2026-09-28): the view from INSIDE the bubble ship.
##
##   back   : live relativistic sky, rendered through EXACTLY the Blender panorama camera
##            (spike/v2/cam_<shot>.json, ship frame: +Z = direction of travel = up)
##   middle : Blender panorama of the ship's interior from that same camera
##   front  : isometric play slice (Blender GLB), toon + ink
##
##   godot --path . --resolution 1600x900 res://spike/interior.tscn -- --shot=bridge --capture=spike/out/v2

const TOON := preload("res://spike/toon.gdshader")
const OUTLINE := preload("res://spike/outline.gdshader")
const HEADING := Vector3(0, 0, -1) # the starfield world's direction of travel
const SPEEDS := [0.0, 0.9, 0.99]

var shot := "bridge"
var iso_cam := Camera3D.new()
var sky_view := SubViewport.new()
var starfield := Starfield.new()
var hud := Label.new()


## Ship frame (+Z = travel) -> starfield world (travel = -Z): a proper rotation.
static func ship_to_star(v: Array) -> Vector3:
	return Vector3(v[0], -v[1], -v[2])


func _ready() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else ""
	shot = args.get("shot", "bridge")
	var cam: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://spike/v2/cam_%s.json" % shot))
	_build_sky(cam)
	_build_panorama()
	_build_iso()
	if args.has("capture"):
		await _capture(args["capture"])


func _full_rect(tex: Texture2D, layer_index: int) -> void:
	var layer := CanvasLayer.new()
	layer.layer = layer_index
	var rect := TextureRect.new()
	rect.texture = tex
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(rect)
	add_child(layer)


func _build_sky(cam: Dictionary) -> void:
	sky_view.size = Vector2i(int(cam["resolution"][0]), int(cam["resolution"][1]))
	sky_view.own_world_3d = true
	sky_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.BLACK
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.glow_enabled = true
	env.glow_bloom = 0.05
	var we := WorldEnvironment.new()
	we.environment = env
	sky_view.add_child(we)
	var sky_cam := Camera3D.new()
	sky_cam.fov = cam["fov_vertical_deg"] # same vertical FOV and aspect as the Blender render
	sky_cam.far = 1000.0
	sky_cam.look_at_from_position(Vector3.ZERO, ship_to_star(cam["forward"]), ship_to_star(cam["up"]))
	sky_view.add_child(sky_cam)
	starfield.load_catalogue("res://data/starmap/stars.json")
	starfield.build()
	starfield.set_exposure(5.0)
	sky_view.add_child(starfield)
	add_child(sky_view)
	_full_rect(sky_view.get_texture(), -3)


func _build_panorama() -> void:
	_full_rect(load("res://spike/v2/stapledon_pano_%s.png" % shot), -2)


func _build_iso() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_CANVAS
	env.background_canvas_max_layer = -1
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.glow_enabled = true
	env.glow_hdr_threshold = 1.2
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.5, 0.7)
	env.ambient_light_energy = 0.6
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 30, 0)
	sun.light_energy = 1.4
	add_child(sun)
	var slice: Node3D = (load("res://spike/v2/%s_slice.glb" % shot) as PackedScene).instantiate()
	add_child(slice)
	_toonify(slice)
	iso_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	iso_cam.size = 46.0 if shot == "bridge" else 40.0
	iso_cam.near = 0.1
	iso_cam.far = 500.0
	iso_cam.rotation_degrees = Vector3(-30, 45, 0)
	iso_cam.position = iso_cam.transform.basis.z * 150.0
	iso_cam.v_offset = iso_cam.size * 0.2 # push the play slice to the lower part of the screen
	add_child(iso_cam)
	iso_cam.make_current()
	var hud_layer := CanvasLayer.new()
	hud.position = Vector2(20, 16)
	hud.add_theme_font_size_override("font_size", 22)
	hud_layer.add_child(hud)
	add_child(hud_layer)


func _toonify(node: Node) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		for i in mi.mesh.get_surface_count():
			var src := mi.mesh.surface_get_material(i) as BaseMaterial3D
			var toon := ShaderMaterial.new()
			toon.shader = TOON
			if src:
				toon.set_shader_parameter("albedo", src.albedo_color)
				if src.emission_enabled:
					toon.set_shader_parameter("emission", src.emission)
					toon.set_shader_parameter("emission_energy", src.emission_energy_multiplier * 2.0)
			var ink := ShaderMaterial.new()
			ink.shader = OUTLINE
			toon.next_pass = ink
			mi.set_surface_override_material(i, toon)
	for c in node.get_children():
		_toonify(c)


func _capture(dir: String) -> void:
	var out := dir if dir.is_absolute_path() else ProjectSettings.globalize_path("res://").path_join(dir)
	DirAccess.make_dir_recursive_absolute(out)
	var labels: Dictionary = {"bridge": "BRIDGE (top of the spire, under the bubble's forward pole)",
		"level": "MID-SHIP LEVEL (looking across the interior)"}
	var label: String = labels[shot]
	for b in SPEEDS:
		var g := 1.0 / sqrt(1.0 - b * b)
		starfield.set_velocity(HEADING, b, g)
		hud.text = "%s  ·  β = %.2f c  ·  γ = %.2f  ·  up = direction of travel" % [label, b, g]
		for i in 4:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var name := "%s_b%s.png" % [shot, str(b).replace(".", "")]
		get_viewport().get_texture().get_image().save_png(out.path_join(name))
		print("captured ", name)
	get_tree().quit(0)
