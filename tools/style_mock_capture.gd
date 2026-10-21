extends SceneTree
## R2-BRIDGE-STYLE (design_docs/planned/r2/bridge-styling-pass.md) review mocks: before/after frames
## of the styling pass's two engine-side levers, applied in-engine to today's bridge (DL3), so Mark
## can choose before anything is built. Review only: nothing here ships.
##   now      the bridge as it ships (broad key + spire + star, PBR shading, ink outline on props)
##   key      the broad key retired on the bridge: the spire (stronger, shadowed) keys deep space,
##            the star takes over near a star
##   toon     banded toon shading (three bands, the art bible's Shader-to-RGB look) on every bridge
##            mesh, the ink outline on all of them
##   both     key + toon
## Each in deep space and near the Sun, through the Bow view at the spawn and Astern.
## Usage: godot --path . --script tools/style_mock_capture.gd -- [--out=res://renders/style_mock]
var demo: Node
var out := "res://renders/style_mock"
var px := Vector2i(1280, 720)
var toon_shader: Shader
var ink: ShaderMaterial
var _saved := {} # MeshInstance3D -> [surface override materials]


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	root.size = px
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.content_scale_size = px
	toon_shader = Shader.new()
	toon_shader.code = TOON
	ink = ShaderMaterial.new()
	ink.shader = load("res://interior/outline.gdshader")
	ink.set_shader_parameter("width", 0.018)
	demo = load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options = {"size": px, "sky_state": "rest"}
	root.add_child(demo)
	await process_frame
	demo.auto = false
	demo.journey_auto_tick = false
	demo.ship_hud.visible = false
	var cap: GDScript = load("res://tools/deck_dl2_capture.gd") # its sky worlds (static helpers)
	var star: Dictionary = cap._with_sun(demo.sky_states.rest)
	demo.sky_states["star"] = star
	demo.sky_states["deep"] = cap._pushed(star, 2.5e8)
	for mode: String in ["now", "key", "toon", "both"]:
		_set_mode(mode)
		for st: String in ["deep", "star"]:
			demo.set_sky_state(st)
			for vid: String in ["bow", "astern"]:
				await _shot("%s_%s_%s" % [mode, st, vid], vid)
	_sheet()
	print("style-mock-capture: done")
	quit(0)


func _set_mode(mode: String) -> void:
	var rig: Dictionary = demo.lighting
	var key_off := mode in ["key", "both"]
	rig.key_base = 0.0 if key_off else 1.5
	rig.spire_base = 8.0 if key_off else 5.0
	rig.spire.shadow_enabled = key_off
	# The light sits on the mast's axis, inside the mast: the mast itself must not cast its shadow
	# (the plan's S1 makes the spire body a non-caster for the spire light).
	var mast := demo.geometry.find_child("spire_needle", true, false) as GeometryInstance3D
	if mast != null:
		mast.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if key_off else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	demo.star_light.apply_rig(rig)
	_restore()
	if mode in ["toon", "both"]:
		_toon(demo.geometry.get_child(0))
		if demo.props_visual != null:
			_toon(demo.props_visual)


func _restore() -> void:
	for mi: MeshInstance3D in _saved:
		var mats: Array = _saved[mi]
		for i in mats.size():
			mi.set_surface_override_material(i, mats[i])
	_saved.clear()


## Every surface of the bridge: its albedo (texture and colour) through the three-band toon shader,
## with the ink outline as the next pass. The lower decks keep their look.
func _toon(root_node: Node) -> void:
	var stack: Array = [root_node]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		stack.append_array(n.get_children())
		if not (n is MeshInstance3D) or (n as MeshInstance3D).mesh == null:
			continue
		var mi := n as MeshInstance3D
		if mi.global_position.y < 75.0 and mi.get_aabb().size.y < 30.0:
			continue
		var keep := []
		for i in mi.mesh.get_surface_count():
			keep.append(mi.get_surface_override_material(i))
			var src := mi.get_surface_override_material(i)
			if src == null:
				src = mi.mesh.surface_get_material(i)
			var m := ShaderMaterial.new()
			m.shader = toon_shader
			if src is BaseMaterial3D:
				var b := src as BaseMaterial3D
				m.set_shader_parameter("albedo", b.albedo_color)
				m.set_shader_parameter("albedo_tex", b.albedo_texture)
				m.set_shader_parameter("has_tex", b.albedo_texture != null)
			m.next_pass = ink
			mi.set_surface_override_material(i, m)
		_saved[mi] = keep


func _shot(name: String, vid: String) -> void:
	demo.consoles.cancel_walk()
	demo.director.release()
	demo.camera_mode = "player"
	demo.director.walk(vid)
	demo.avatar_pos = demo.bridge_spawn()
	for k in 240:
		demo._process(1.0 / 60.0)
	for k in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [out, name])
	print("shot %s key %.2f spire %.2f star %.2f" % [name, demo.lighting.key.light_energy, demo.lighting.spire.light_energy, demo.star_light.light.light_energy])


func _sheet() -> void:
	# Rows: now, key, toon, both; columns: deep Bow, star Bow, deep Astern, star Astern.
	var w := 480
	var h := 270
	var g := 16
	var modes := ["now", "key", "toon", "both"]
	var cols := ["deep_bow", "star_bow", "deep_astern", "star_astern"]
	var img := Image.create(cols.size() * (w + g) + g, modes.size() * (h + g) + g, false, Image.FORMAT_RGB8)
	img.fill(Color(0.06, 0.06, 0.08))
	for r in modes.size():
		for c in cols.size():
			var path := ProjectSettings.globalize_path("%s/%s_%s.png" % [out, modes[r], cols[c]])
			if not FileAccess.file_exists(path):
				continue
			var f := Image.load_from_file(path)
			f.convert(Image.FORMAT_RGB8)
			f.resize(w, h, Image.INTERPOLATE_LANCZOS)
			img.blit_rect(f, Rect2i(0, 0, w, h), Vector2i(g + c * (w + g), g + r * (h + g)))
	img.save_png("%s/contact_sheet.png" % out)


const TOON := """
shader_type spatial;
uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap;
uniform bool has_tex = false;
void fragment() {
	vec3 c = albedo.rgb;
	if (has_tex) { c *= texture(albedo_tex, UV).rgb; }
	ALBEDO = c;
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
void light() {
	float ndl = dot(NORMAL, LIGHT) * ATTENUATION;
	float band = ndl > 0.55 ? 1.0 : (ndl > 0.12 ? 0.55 : 0.18);
	DIFFUSE_LIGHT += band * LIGHT_COLOR * ALBEDO / PI;
}
"""
