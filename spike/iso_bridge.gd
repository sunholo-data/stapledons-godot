extends Node3D
## SPIKE (2026-09-28): the isometric three-layer bridge, to answer "is it feasible?"
##
##   back   : live relativistic starfield (the M0 Starfield, physically exact), rendered in its
##            own SubViewport by a PERSPECTIVE camera looking along the direction of travel —
##            the view up through the observation dome.
##   middle : Blender-rendered panorama of the ship's levels below (transparent where space is).
##   front  : Blender GLB bridge set, orthographic isometric camera, toon shading + ink outline.
##
##   godot --path . --resolution 1600x900 res://spike/iso_bridge.tscn -- --capture=spike/out

const HEADING := Vector3(0, 0, -1) # travel direction in the starfield's world frame
const SPEEDS := [0.0, 0.9, 0.99]
const TOON := preload("res://spike/toon.gdshader")
const OUTLINE := preload("res://spike/outline.gdshader")
const DOME := preload("res://spike/dome.gdshader")

var iso_cam := Camera3D.new()
var sky_view := SubViewport.new()
var sky_rect := TextureRect.new()
var pano_rect := TextureRect.new()
var starfield := Starfield.new()
var hud := Label.new()


func _ready() -> void:
	_build_sky_layer()
	_build_panorama_layer()
	_build_iso_layer()
	await get_tree().process_frame
	_place_layers()
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else ""
	if args.has("capture"):
		await _capture(args["capture"])


# ---------- back layer: the physics ----------
func _build_sky_layer() -> void:
	sky_view.size = Vector2i(1920, 1080)
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
	var cam := Camera3D.new()
	cam.fov = 100.0 # wide: the dome is overhead
	cam.far = 1000.0
	cam.look_at_from_position(Vector3.ZERO, HEADING, Vector3.UP)
	sky_view.add_child(cam)
	starfield.load_catalogue("res://data/starmap/stars.json")
	starfield.build()
	starfield.set_exposure(5.0)
	sky_view.add_child(starfield)
	add_child(sky_view)
	var layer := CanvasLayer.new()
	layer.layer = -3
	sky_rect.texture = sky_view.get_texture()
	sky_rect.stretch_mode = TextureRect.STRETCH_SCALE
	layer.add_child(sky_rect)
	add_child(layer)


# ---------- middle layer: Blender panorama ----------
func _build_panorama_layer() -> void:
	var layer := CanvasLayer.new()
	layer.layer = -2
	pano_rect.texture = load("res://spike/assets/panorama.png")
	pano_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pano_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	layer.add_child(pano_rect)
	add_child(layer)


# ---------- front layer: isometric set ----------
func _build_iso_layer() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_CANVAS # layers below 0 show through
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
	var bridge: Node3D = (load("res://spike/assets/bridge_spike.glb") as PackedScene).instantiate()
	add_child(bridge)
	_toonify(bridge)
	var dome := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 12.0
	sphere.height = 24.0
	sphere.is_hemisphere = true
	sphere.radial_segments = 96
	sphere.rings = 48
	dome.mesh = sphere
	var dm := ShaderMaterial.new()
	dm.shader = DOME
	dome.material_override = dm
	add_child(dome)
	iso_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	iso_cam.size = 36.0
	iso_cam.near = 0.1
	iso_cam.far = 400.0
	iso_cam.rotation_degrees = Vector3(-30, 45, 0)
	iso_cam.position = Vector3(0, 4, 0) + iso_cam.transform.basis.z * 120.0
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


## Centre the sky on the dome apex (forward = up = the direction of travel) and sit the
## panorama of the lower levels below the deck.
func _place_layers() -> void:
	var screen := get_viewport().get_visible_rect().size
	var apex := iso_cam.unproject_position(Vector3(0, 12, 0))
	var sky_size := screen * 1.8
	sky_rect.size = sky_size
	sky_rect.position = apex - sky_size * 0.5
	var deck := iso_cam.unproject_position(Vector3(0, -2, 0))
	var pano_size := Vector2(screen.x * 1.25, screen.y * 1.25)
	pano_rect.size = pano_size
	pano_rect.position = Vector2(deck.x - pano_size.x * 0.5, deck.y - pano_size.y * 0.12)


func _set_speed(b: float) -> void:
	var g := 1.0 / sqrt(1.0 - b * b)
	starfield.set_velocity(HEADING, b, g)
	hud.text = "OBSERVATION BRIDGE  ·  β = %.2f c  ·  γ = %.2f  ·  view: dome, looking forward (up)" % [b, g]


func _capture(dir: String) -> void:
	var out := dir if dir.is_absolute_path() else ProjectSettings.globalize_path("res://").path_join(dir)
	DirAccess.make_dir_recursive_absolute(out)
	for b in SPEEDS:
		_set_speed(b)
		for i in 4:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var name := "iso_bridge_b%s.png" % str(b).replace(".", "")
		get_viewport().get_texture().get_image().save_png(out.path_join(name))
		print("captured ", name)
	get_tree().quit(0)
