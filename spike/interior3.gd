extends Node3D
## SPIKE v3 (2026-09-28): zoomed in, tilted back toward the horizon, with parallax.
##
## Layers, far to near, and how each moves when the camera PANS sideways:
##   1 galaxy (full sky, synthetic band, relativistic per pixel)  } at infinity: NEVER pan —
##   2 catalogue stars (M0 Starfield)                              } only speed/heading change them
##   3 interior panorama (Blender, the ship's own structure)        pans slowly  (x PANO_K)
##   4 isometric play area (Blender GLB, toon + ink)                pans 1:1 (it IS the camera)
##   5 foreground silhouettes (Blender plate)                       pans faster  (x FG_K)
## 1-3 share the Blender panorama camera, so the sky sits where the architecture says "up".
##
##   godot --path . --resolution 1600x900 res://spike/interior3.tscn -- --shot=bridge --capture=spike/out/v3

const TOON := preload("res://spike/toon.gdshader")
const OUTLINE := preload("res://spike/outline.gdshader")
const GALAXY := preload("res://spike/galaxy_sky.gdshader")
const HEADING := Vector3(0, 0, -1)
const PANO_K := 0.15
const FG_K := 1.6
const PANS := [-5.0, 0.0, 5.0] # metres along the camera's right vector
const SPEEDS := [0.0, 0.99]
const FOCUS := {"bridge": Vector3(-8.0, 1.0, 9.0), "level": Vector3(-2.0, 1.0, 5.0)}

var shot := "bridge"
var iso_cam := Camera3D.new()
var sky_view := SubViewport.new()
var starfield := Starfield.new()
var galaxy_mat := ShaderMaterial.new()
var pano_rect := TextureRect.new()
var fg_rect := TextureRect.new()
var hud := Label.new()
var screen := Vector2(1600, 900)


static func ship_to_star(v: Array) -> Vector3:
	return Vector3(v[0], -v[1], -v[2])


func _ready() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else ""
	shot = args.get("shot", "bridge")
	screen = get_viewport().get_visible_rect().size
	var cam: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://spike/v2/cam_%s.json" % shot))
	_build_sky(cam)
	pano_rect = _layer_rect(load("res://spike/v2/stapledon_pano_%s.png" % shot), -2, 1.25)
	_build_iso()
	fg_rect = _layer_rect(load("res://spike/v3/stapledon_fg_%s.png" % shot), 1, 1.3)
	_set_pan(0.0)
	if args.has("capture"):
		await _capture(args["capture"])


func _layer_rect(tex: Texture2D, layer_index: int, oversize: float) -> TextureRect:
	var layer := CanvasLayer.new()
	layer.layer = layer_index
	var rect := TextureRect.new()
	rect.texture = tex
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.size = screen * oversize
	layer.add_child(rect)
	add_child(layer)
	return rect


func _build_sky(cam: Dictionary) -> void:
	sky_view.size = Vector2i(int(cam["resolution"][0]), int(cam["resolution"][1]))
	sky_view.own_world_3d = true
	sky_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	galaxy_mat.shader = GALAXY
	galaxy_mat.set_shader_parameter("bb_lut", Blackbody.build_lut())
	galaxy_mat.set_shader_parameter("lut_log_tmin", log(Blackbody.LUT_T_MIN))
	galaxy_mat.set_shader_parameter("lut_log_tmax", log(Blackbody.LUT_T_MAX))
	var sky := Sky.new()
	sky.sky_material = galaxy_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.glow_enabled = true
	env.glow_bloom = 0.05
	var we := WorldEnvironment.new()
	we.environment = env
	sky_view.add_child(we)
	var sky_cam := Camera3D.new()
	sky_cam.fov = cam["fov_vertical_deg"]
	sky_cam.far = 1000.0
	sky_cam.look_at_from_position(Vector3.ZERO, ship_to_star(cam["forward"]), ship_to_star(cam["up"]))
	sky_view.add_child(sky_cam)
	starfield.load_catalogue("res://data/starmap/stars.json")
	starfield.build()
	starfield.set_exposure(5.0)
	sky_view.add_child(starfield)
	add_child(sky_view)
	var layer := CanvasLayer.new()
	layer.layer = -3
	var rect := TextureRect.new()
	rect.texture = sky_view.get_texture()
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(rect)
	add_child(layer)


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
	iso_cam.size = 16.0                         # room-sized: the player's surroundings, not the deck
	iso_cam.near = 0.1
	iso_cam.far = 500.0
	iso_cam.rotation_degrees = Vector3(-14, 45, 0) # tilted back toward the panorama's horizon
	iso_cam.v_offset = iso_cam.size * 0.38
	add_child(iso_cam)
	iso_cam.make_current()
	var hud_layer := CanvasLayer.new()
	hud_layer.layer = 2
	hud.position = Vector2(20, 16)
	hud.add_theme_font_size_override("font_size", 20)
	hud_layer.add_child(hud)
	add_child(hud_layer)


func _set_pan(p: float) -> void:
	var right := iso_cam.transform.basis.x
	iso_cam.position = FOCUS[shot] + right * p + iso_cam.transform.basis.z * 150.0
	var ppm := screen.y / iso_cam.size             # screen pixels per metre in the iso layer
	var shift := -p * ppm
	pano_rect.position = (screen - pano_rect.size) * 0.5 + Vector2(shift * PANO_K, 0)
	fg_rect.position = (screen - fg_rect.size) * Vector2(0.5, 1.0) + Vector2(shift * FG_K, 0)


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
			ink.set_shader_parameter("width", 0.03)
			toon.next_pass = ink
			mi.set_surface_override_material(i, toon)
	for c in node.get_children():
		_toonify(c)


func _set_speed(b: float) -> void:
	var g := 1.0 / sqrt(1.0 - b * b)
	starfield.set_velocity(HEADING, b, g)
	galaxy_mat.set_shader_parameter("beta_dir", HEADING)
	galaxy_mat.set_shader_parameter("beta_mag", b)
	galaxy_mat.set_shader_parameter("gamma_f", g)
	galaxy_mat.set_shader_parameter("one_minus_beta", 1.0 / (g * g * (1.0 + b)))


func _capture(dir: String) -> void:
	var out := dir if dir.is_absolute_path() else ProjectSettings.globalize_path("res://").path_join(dir)
	DirAccess.make_dir_recursive_absolute(out)
	var labels: Dictionary = {"bridge": "BRIDGE", "level": "MID-SHIP LEVEL"}
	var tiles: Array = []
	for b in SPEEDS:
		_set_speed(b)
		for p in PANS:
			_set_pan(p)
			hud.text = "%s  ·  β = %.2f c  ·  camera pan %+.0f m  (sky fixed: at infinity)" % [labels[shot], b, p]
			for i in 5:
				await get_tree().process_frame
			await RenderingServer.frame_post_draw
			var img := get_viewport().get_texture().get_image()
			var name := "%s_b%s_pan%+d.png" % [shot, str(b).replace(".", ""), int(p)]
			img.save_png(out.path_join(name))
			tiles.append(img)
			print("captured ", name)
	var w := int(screen.x / 2)
	var h := int(screen.y / 2)
	var sheet := Image.create(w * PANS.size(), h * SPEEDS.size(), false, Image.FORMAT_RGBA8)
	for i in tiles.size():
		var t: Image = tiles[i]
		t.convert(Image.FORMAT_RGBA8)
		t.resize(w, h, Image.INTERPOLATE_LANCZOS)
		sheet.blit_rect(t, Rect2i(0, 0, w, h), Vector2i((i % PANS.size()) * w, (i / PANS.size()) * h))
	sheet.save_png(out.path_join("%s_parallax_sheet.png" % shot))
	get_tree().quit(0)
