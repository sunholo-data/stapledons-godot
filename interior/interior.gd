class_name Interior
extends Node
## M4.2 the iso interior with the live sky (design m4-first-journey.md "M4.2"; brief §2).
## Five layers, far to near, each a CanvasLayer of the main viewport:
##
##   | layer      | node                                         | pan factor           |
##   | sky        | InteriorSky (SubViewport, own World3D, HDR)  | 0 (at infinity)      |
##   | panorama   | TextureRect, pano_<area>.png                 | layers.panorama 0.15 |
##   | play       | SubViewport (own World3D, transparent), GLB  | 1                    |
##   |            | toon + ink, the captain; v2: a plate under it |                      |
##   | foreground | TextureRect, fg_<area>.png                   | layers.foreground 1.6|
##   | hud        | labels, prompt, Archive panel                | -                    |
##
## ONE tonemap: the sky SubViewport tonemaps itself (AgX + M1.5a exposure); the main viewport
## has no WorldEnvironment and no 3D of its own, so nothing re-tonemaps or glows the sky
## (G-M4-2). The play layer renders in its own SubViewport (its own AgX for the toon set, no
## glow) with a transparent background.
##
## Art is data (D-16): everything comes from the AreaBundle; a swap is a data drop.
## Plates: the camera spans the overscanned panorama plate, the screen shows its view region
## scaled to the screen height; a pan of (p, q) metres in the iso camera's plane moves a plate
## by factor x pixels-per-metre, CLAMPED at the plate's overscan so its edge never shows
## (m4-2-requirements §4; the bridge v1 overscan covers a [6, 3] m pan).
## The iso camera follows the captain. Walking (WalkArea) and the avatar are presentation
## only: their positions never go to the sim. The sim's clock runs through the galaxy map's
## tick (host rate at rest, transit rate committed; D-12, no pause).
##
## Keys: WASD / arrows walk, E use, M galaxy map, L legacy log, K codex, Esc close.

signal map_toggled(open: bool)

const LAYERS := ["sky", "panorama", "play", "foreground", "hud"]
const CANVAS := {"sky": -40, "panorama": -30, "play": -20, "foreground": -10, "hud": 10}
const PLATE_SHADER := preload("res://interior/plate.gdshader")
const TOON := preload("res://interior/toon.gdshader")
const OUTLINE := preload("res://interior/outline.gdshader")
const WALK_SPEED := 1.4 # m/s
const BACK_M := 150.0 # iso camera distance behind the focus
const TICK_HZ := 20.0
const CAPTAIN_DIR := "res://assets/characters/captain"
const KINDS := [["console_navigation", "Navigation console", "map"], ["archive_terminal", "Archive terminal", "archive"]]

var bundle: AreaBundle
var sky := InteriorSky.new()
var sky_rect := TextureRect.new()
var pano_rect := TextureRect.new()
var play_view := SubViewport.new()
var play_rect := TextureRect.new()
var play_plate_rect: TextureRect = null # bridge v2 hook
var fg_rect := TextureRect.new()
var play_env := Environment.new()
var iso_cam := Camera3D.new()
var play_scene: Node3D
var walk: WalkArea
var avatar := CaptainAvatar.new()
var avatar_pos := Vector3.ZERO
var pan := Vector2.ZERO
var reach := 1.5
var tag_label := Label.new()
var status_label := Label.new()
var prompt_label := Label.new()
var hint_label := Label.new()
var archive := PanelContainer.new()
var archive_text := Label.new()
var archive_tab := ""
var sim: SimBridge = null
var map: GalaxyMap = null
var map_open := false
var auto := true # interactive: keys walk and the sim ticks (captures and tests drive it)
var caption := "" # capture caption line on the HUD
## Review captures only: a glow pole (W/m^2) shown instead of the sim's (-1 = the sim's).
## Never set in play; the HUD then says PREVIEW.
var glow_preview := -1.0
var last_error := ""
var screen := Vector2(960, 540) # canvas units
var _layers := {}
var _iso := {}
var _focus := Vector3.ZERO
var _plates := {} # layer -> [rect, overscan Vector2, plate px Vector2]
var _view := Vector2(3840, 2160)
var _accum := 0.0
var _move := Vector2.ZERO


## Build every layer from the bundle. opts: size (Vector2i, render pixels; default the
## window), background / stars / tier (InteriorSky).
func setup(b: AreaBundle, opts := {}) -> bool:
	bundle = b
	if b == null or not b.ok():
		last_error = "bundle refused: %s" % ("null" if b == null else "; ".join(b.errors))
		return false
	var px: Vector2i = opts.get("size", Vector2i(960, 540))
	screen = opts.get("canvas", Vector2(px))
	_view = Vector2(b.view_size())
	var view_fov := 2.0 * rad_to_deg(atan(tan(deg_to_rad(float(b.camera["fov_vertical_deg"])) / 2.0) * _view.y / float(b.camera["resolution"][1])))
	sky.setup(b.camera, view_fov, px, opts)
	add_child(sky)
	sky_rect.texture = sky.get_texture()
	_full(sky_rect)
	_layer("sky").add_child(sky_rect)
	_plate("panorama", b.load_image("panorama"))
	if not _build_play(b, px):
		return false
	_plate("foreground", b.load_image("foreground"))
	_build_hud()
	set_pan(_pan_for(avatar_pos))
	return true


## Hand over the session: the sim (state) and the galaxy map (planning; it owns the tick).
func attach(bridge: SimBridge, galaxy_map: GalaxyMap) -> void:
	sim = bridge
	map = galaxy_map
	if sim != null and sim.world.has("ship"):
		apply_state(sim.world)


## Window resized: px = render pixels (the SubViewports), canvas = the main viewport's
## visible rect (stretch units).
func resize(px: Vector2i, canvas: Vector2) -> void:
	screen = canvas
	sky.resize(px)
	play_view.size = px
	_full(sky_rect)
	_full(play_rect)
	_layout()


func layer_nodes() -> Dictionary:
	return _layers


func pan_factor(layer: String) -> float:
	match layer:
		"panorama", "foreground":
			return float(bundle.manifest["layers"][layer]["parallax"])
		"play":
			return 1.0
	return 0.0


## WorldEnvironment nodes outside the sky/play SubViewports: must be none (one tonemap).
func environments_outside_subviewports() -> Array:
	var out := []
	var stack: Array[Node] = [self]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is WorldEnvironment:
			out.append(n)
		for c in n.get_children():
			if not c is SubViewport:
				stack.append(c)
	return out


## A plate's screen offset for a pan (p right, q up, metres): -p x factor x ppm across,
## +q x factor x ppm down, clamped at the plate's overscan (pixels) x screen scale.
static func plate_shift(p: Vector2, factor: float, ppm: float, overscan_px: Vector2, s: float) -> Vector2:
	var lim := overscan_px * s
	return Vector2(clampf(-p.x * factor * ppm, -lim.x, lim.x), clampf(p.y * factor * ppm, -lim.y, lim.y))


func set_pan(p: Vector2) -> void:
	pan = p
	var b := iso_cam.transform.basis
	iso_cam.position = _focus + b.x * p.x + b.y * p.y + b.z * BACK_M
	_layout()


## Sim state -> sky, avatar age, HUD. Formatting only: no arithmetic on physics values.
func apply_state(world: Dictionary) -> void:
	if not world.has("ship"):
		return
	sky.apply(world)
	if glow_preview >= 0.0:
		sky.set_glow_pole(glow_preview)
	_push_glow_tint()
	var c: Dictionary = world.get("clock", {})
	avatar.set_years(float(c.get("tau", 0.0)))
	var s: Dictionary = world["ship"]
	var glow := "glow %s W/m^2 at the pole%s" % [String.num_scientific(sky.glow_pole), " (PREVIEW)" if glow_preview >= 0.0 else ""] if sky.glow_pole >= 0.0 else "glow: no ship.ism.glow_pole_w_m2 from the sim yet"
	status_label.text = "%s%s   beta %.4f c   gamma %.3f\nship %.4f yr   Earth %.4f yr   %s\n%s" % [
		caption + "\n" if caption != "" else "", str(s.get("phase", "")), s["beta"], s["gamma"], c.get("tau", 0.0), c.get("t", 0.0), glow, sky.exposure.hud_line()]
	if archive.visible:
		_fill_archive()


## Walk the captain by a screen direction (x right, y down) for dt seconds.
func walk_screen(dir: Vector2, dt: float) -> void:
	var b := iso_cam.transform.basis
	var right := Vector3(b.x.x, 0.0, b.x.z).normalized()
	var fwd := Vector3(-b.z.x, 0.0, -b.z.z).normalized()
	var v := dir.limit_length(1.0)
	avatar_pos = walk.step(avatar_pos, (right * v.x - fwd * v.y) * WALK_SPEED * dt)
	avatar.position = avatar_pos
	avatar.set_motion(v)
	set_pan(_pan_for(avatar_pos))
	_update_prompt()


## Walk toward a play-frame point at walking speed for dt (scripted runs and captures).
func walk_toward(target: Vector3, dt: float) -> bool:
	var d := Vector3(target.x - avatar_pos.x, 0.0, target.z - avatar_pos.z)
	if d.length() < 0.05:
		return true
	var b := iso_cam.transform.basis
	var right := Vector3(b.x.x, 0.0, b.x.z).normalized()
	var fwd := Vector3(-b.z.x, 0.0, -b.z.z).normalized()
	var dir := Vector2(d.dot(right), -d.dot(fwd)).normalized() * minf(1.0, d.length() / (WALK_SPEED * dt))
	walk_screen(dir, dt)
	return false


func place_avatar(p: Vector3) -> void:
	avatar_pos = walk.closest_walkable(p)
	avatar.position = avatar_pos
	set_pan(_pan_for(avatar_pos))
	_update_prompt()


func nearest_interactable() -> String:
	return walk.nearest_interactable(avatar_pos, reach)


## Use the interactable in reach: the navigation console opens the galaxy map, the Archive
## terminal the Archive. Returns the action ("map", "archive", "" for nothing).
func interact() -> String:
	var name := nearest_interactable()
	var k := kind_of(name)
	if k[2] == "map":
		open_map()
	elif k[2] == "archive":
		open_archive("news")
	return k[2]


static func kind_of(name: String) -> Array:
	for k: Array in KINDS:
		if name.begins_with(k[0]):
			return k
	return [name, name.capitalize(), ""]


func open_map() -> void:
	if map == null or map_open:
		return
	map_open = true
	_set_layers_visible(false)
	if map.get_parent() == null:
		add_child(map)
	map.camera.current = true
	map.auto_tick = true
	map.refresh()
	map_toggled.emit(true)


func close_map() -> void:
	if map == null or not map_open:
		return
	map_open = false
	if map.get_parent() == self:
		remove_child(map)
	_set_layers_visible(true)
	map_toggled.emit(false)


func open_archive(tab: String) -> void:
	archive_tab = tab
	archive.visible = true
	_fill_archive()


func close_archive() -> void:
	archive.visible = false


## One sim tick through the map (the map's own clock rules; its pending plan rides along).
func tick() -> bool:
	if map == null or sim == null:
		return false
	var ok := map.tick()
	if ok:
		apply_state(sim.world)
	return ok


func _process(delta: float) -> void:
	if not auto:
		return
	if map_open:
		if sim != null and sim.world.has("ship"):
			apply_state(sim.world)
		return
	var v := Vector2(Input.get_axis("ui_left", "ui_right"), Input.get_axis("ui_up", "ui_down"))
	v += Vector2((1.0 if Input.is_key_pressed(KEY_D) else 0.0) - (1.0 if Input.is_key_pressed(KEY_A) else 0.0),
		(1.0 if Input.is_key_pressed(KEY_S) else 0.0) - (1.0 if Input.is_key_pressed(KEY_W) else 0.0))
	if v != Vector2.ZERO or _move != Vector2.ZERO:
		walk_screen(v, delta)
	_move = v
	_accum = minf(_accum + delta, 4.0 / TICK_HZ)
	while _accum >= 1.0 / TICK_HZ:
		_accum -= 1.0 / TICK_HZ
		tick()


func _unhandled_key_input(event: InputEvent) -> void:
	if not auto or not event.pressed or event.is_echo():
		return
	var k := (event as InputEventKey).keycode
	if map_open:
		if k == KEY_M or k == KEY_ESCAPE:
			close_map()
			get_viewport().set_input_as_handled()
		return
	match k:
		KEY_E: interact()
		KEY_M: open_map()
		KEY_L: open_archive("log")
		KEY_K: open_archive("codex")
		KEY_ESCAPE: close_archive()
		_: return
	get_viewport().set_input_as_handled()


func _layer(name: String) -> CanvasLayer:
	if not _layers.has(name):
		var l := CanvasLayer.new()
		l.layer = CANVAS[name]
		l.name = "layer_" + name
		add_child(l)
		_layers[name] = l
	return _layers[name]


func _full(r: TextureRect) -> void:
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.position = Vector2.ZERO
	r.size = screen


func _plate(layer: String, img: Image) -> void:
	var r := pano_rect if layer == "panorama" else fg_rect
	r.texture = ImageTexture.create_from_image(img)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = PLATE_SHADER
	r.material = m
	_layer(layer).add_child(r)
	_plates[layer] = [r, Vector2(bundle.overscan(layer)), Vector2(img.get_size())]


func _layout() -> void:
	var s := screen.y / _view.y
	var ppm := screen.y / float(_iso["size_m"])
	for layer: String in _plates:
		var r: TextureRect = _plates[layer][0]
		var os: Vector2 = _plates[layer][1]
		var plate_px: Vector2 = _plates[layer][2]
		r.size = plate_px * s
		var factor := pan_factor(layer) if layer != "play_plate" else 1.0
		r.position = (screen - _view * s) * 0.5 - os * s + plate_shift(pan, factor, ppm, os, s)


func _build_play(b: AreaBundle, px: Vector2i) -> bool:
	play_view.size = px
	play_view.own_world_3d = true
	play_view.transparent_bg = true
	play_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(play_view)
	play_env.background_mode = Environment.BG_CLEAR_COLOR
	play_env.tonemap_mode = Environment.TONE_MAPPER_AGX
	play_env.glow_enabled = false
	play_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	play_env.ambient_light_color = Color(0.55, 0.5, 0.7)
	play_env.ambient_light_energy = 0.6
	var we := WorldEnvironment.new()
	we.environment = play_env
	play_view.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 30, 0)
	sun.light_energy = 1.4
	play_view.add_child(sun)
	play_scene = b.instantiate_play()
	if play_scene == null:
		last_error = "play GLB did not load: %s" % b.path("play")
		return false
	play_view.add_child(play_scene)
	_toonify(play_scene, b.has_play_plate())
	var rules: Variant = b.manifest.get("walk_rules")
	var radius: float = rules.get("agent_radius_m", 0.35) if rules is Dictionary else 0.35
	reach = rules.get("reach_m", 1.5) if rules is Dictionary else 1.5
	walk = WalkArea.from_scene(play_scene, radius)
	_iso = b.iso_camera()
	var f: Array = _iso["focus_m"]
	_focus = Vector3(f[0], f[1], f[2])
	iso_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	iso_cam.size = float(_iso["size_m"])
	iso_cam.near = 0.1
	iso_cam.far = 500.0
	iso_cam.rotation_degrees = Vector3(float(_iso["pitch_deg"]), float(_iso["yaw_deg"]), 0.0)
	iso_cam.v_offset = float(_iso["v_offset_m"])
	play_view.add_child(iso_cam)
	iso_cam.current = true
	if not avatar.load_dir(CAPTAIN_DIR):
		last_error = avatar.last_error
		return false
	play_view.add_child(avatar)
	avatar_pos = walk.spawn_point()
	avatar.position = avatar_pos
	if b.has_play_plate(): # bridge v2: the projected illustrated plate under the GLB layer
		play_plate_rect = TextureRect.new()
		_plates["play_plate"] = [play_plate_rect, Vector2.ZERO, Vector2.ZERO]
		var img := AreaBundle.load_png(b.play_plate_path())
		if img != null:
			play_plate_rect.texture = ImageTexture.create_from_image(img)
			_plates["play_plate"][2] = Vector2(img.get_size())
		play_plate_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		play_plate_rect.stretch_mode = TextureRect.STRETCH_SCALE
		_layer("play").add_child(play_plate_rect)
	play_rect.texture = play_view.get_texture()
	_full(play_rect)
	_layer("play").add_child(play_rect)
	return true


## Toon + ink on every mesh; WALK_ surfaces are navigation data, not drawn. With a v2 play
## plate the set is drawn by the plate, so the GLB meshes only carry walking and interaction.
func _toonify(node: Node, hide_all: bool) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		if String(mi.name).begins_with("WALK_") or (mi.get_parent() != null and String(mi.get_parent().name).begins_with("WALK_")) or hide_all:
			mi.visible = false
		elif mi.mesh != null:
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
		_toonify(c, hide_all)


func _build_hud() -> void:
	var hud := _layer("hud")
	tag_label.text = bundle.hud_tag()
	tag_label.visible = bundle.placeholder
	tag_label.add_theme_color_override("font_color", Color(1.0, 0.75, 0.4))
	tag_label.add_theme_font_size_override("font_size", 14)
	tag_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_KEEP_SIZE, 12)
	tag_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	hud.add_child(tag_label)
	status_label.position = Vector2(16, 12)
	status_label.add_theme_font_size_override("font_size", 15)
	status_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	status_label.add_theme_constant_override("outline_size", 4)
	hud.add_child(status_label)
	prompt_label.add_theme_font_size_override("font_size", 18)
	prompt_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	prompt_label.add_theme_constant_override("outline_size", 5)
	prompt_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_KEEP_SIZE, 48)
	prompt_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	prompt_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hud.add_child(prompt_label)
	hint_label.text = "WASD walk   E use   M map   L log   K codex"
	hint_label.add_theme_font_size_override("font_size", 13)
	hint_label.add_theme_color_override("font_color", Color(0.85, 0.85, 0.95, 0.8))
	hint_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_KEEP_SIZE, 12)
	hint_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hud.add_child(hint_label)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.06, 0.09, 0.92)
	style.set_content_margin_all(16)
	archive.add_theme_stylebox_override("panel", style)
	archive.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	archive.custom_minimum_size = Vector2(520, 300)
	archive.visible = false
	archive_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	archive_text.custom_minimum_size = Vector2(488, 0)
	archive.add_child(archive_text)
	hud.add_child(archive)


## The Archive (M4.2 stub; M4.4 news, M4.7 codex fill it): sim fields, formatted only.
func _fill_archive() -> void:
	var cq: Variant = sim.world.get("consequence") if sim != null else null
	var lines := PackedStringArray(["ARCHIVE  [%s]   (Esc closes; L log, K codex)" % archive_tab.to_upper(), ""])
	match archive_tab:
		"news":
			if cq is Dictionary and cq.get("news") is Dictionary:
				var n: Dictionary = cq["news"]
				lines.append("News from home: tier %s (%s), template %s, source %s" % [str(n.get("tier", "")), str(n.get("tier_name", "")), str(n.get("template_id", "")), str(n.get("body_source", ""))])
				lines.append("News epoch Earth %s yr, %s yr old" % [str(cq.get("news_epoch", "")), str(cq.get("news_age_years", ""))])
			else:
				lines.append("No news from home yet. (News arrives on arrival; M4.4 writes it.)")
		"log":
			var lg: Variant = cq.get("legacy") if cq is Dictionary else null
			lines.append("Legacy log: %s entries" % (str(lg.get("count", 0)) if lg is Dictionary else "0"))
			if lg is Dictionary and lg.get("appended") is Array:
				for e in lg["appended"]:
					lines.append("  " + JSON.stringify(e))
		_:
			lines.append("Codex: the Archive's physics entries land with M4.7.")
	archive_text.text = "\n".join(lines)


func _update_prompt() -> void:
	var name := nearest_interactable()
	if name == "":
		prompt_label.text = ""
		return
	var k := kind_of(name)
	prompt_label.text = "E  %s%s" % [k[1], "" if k[2] != "" else "  (nothing here yet)"]


func _pan_for(p: Vector3) -> Vector2:
	var b := iso_cam.transform.basis
	var d := p - _focus
	return Vector2(d.dot(b.x), d.dot(b.y))


func _set_layers_visible(on: bool) -> void:
	for name: String in _layers:
		_layers[name].visible = on
	sky.render_target_update_mode = SubViewport.UPDATE_ALWAYS if on else SubViewport.UPDATE_DISABLED
	play_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS if on else SubViewport.UPDATE_DISABLED


## Bridge v2 hook: the glow's exposed pole pixel goes to every plate's material (no effect
## while rim_strength is 0, which v1 never changes).
func _push_glow_tint() -> void:
	var rgb := ForwardGlow.WHITE_RGB * (ForwardGlow.luminance(maxf(sky.glow_pole, 0.0)) * sky.exposure.k())
	for layer: String in _plates:
		var r: TextureRect = _plates[layer][0]
		if r.material is ShaderMaterial:
			(r.material as ShaderMaterial).set_shader_parameter("glow_rgb", rgb)
