extends SceneTree
## R2-CAPTAIN-ANIMATION spike (D-98; design_docs/planned/r2/captain-animation.md §Spike): four
## ways to animate the captain, seen through the real Bow view at 2560x1440 (the figure is 161 px):
##   A  today: the painted billboard (assets/characters/captain), one still per facing
##   B  a rigged low-poly captain GLB, live in Godot, with the props' ink outline as next pass
##   C  that rig pre-rendered to 8-direction sprite frames, played on the existing billboard
##   D  today's painted still with procedural motion (bob, sway, step squash; no new art)
## Input: --assets=<dir> holding captain_anim_spike_v1.glb and frames/ (from ~/dev/blender
## scripts/char_captain_anim_spike_v1.py). Out: renders/captain_anim_spike/*.png (1:1 crops and 3x
## enlargements, run strips toward the bow and to starboard) + spike.json (frame times). Spike only:
## not a gate; GPU window.
var demo: Node
var assets := ""
var out := "res://renders/captain_anim_spike"
var px := Vector2i(2560, 1440)
var rows := {}
const CROP := 220
const RUN_FRAMES := 20
const RUN_FPS := 30.0
const OUTLINE_M := 0.012


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--assets="):
			assets = a.trim_prefix("--assets=")
		elif a.begins_with("--out="):
			out = a.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	root.size = px
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_size = px
	demo = load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options = {"size": px, "sky_state": "rest"}
	root.add_child(demo)
	await process_frame
	if not demo.ready_ok:
		print("FAIL demo did not build"); quit(1); return
	demo.auto = false
	demo.journey_auto_tick = false
	demo.geometry_view.size = px
	demo.ship_hud.visible = false
	demo.director.walk("bow")
	var foot: Vector3 = demo.walk_bridge.closest_walkable(Vector3(-12, 82, 4), 4.0) # clear deck, port of the helm
	demo.avatar_pos = foot
	for k in 240:
		demo._process(1.0 / 60.0)
	var bow: Vector3 = Vector3(cos(demo.director.walk_yaw()), 0, sin(demo.director.walk_yaw()))
	var starboard := Vector3(-bow.z, 0, bow.x)
	# A: today's painted billboard, back (walking to the bow) and front.
	demo.avatar.set_motion(Vector2(0, -1))
	await _crop("A_painted_back", foot)
	demo.avatar.set_motion(Vector2(0, 1))
	await _crop("A_painted_front", foot)
	rows["A_frame_ms"] = await _frame_ms(240)
	# B: the rigged GLB, live.
	var glb := AreaBundle.load_glb(assets.path_join("captain_anim_spike_v1.glb"))
	if glb == null:
		print("FAIL no GLB in %s" % assets); quit(1); return
	demo.geometry.add_child(glb)
	_ink(glb)
	var ap := _player(glb)
	print("clips: %s" % [ap.get_animation_list()])
	var painted: Texture2D = demo.avatar.texture
	demo.avatar.texture = null # the demo re-shows the node every frame; an empty texture hides it
	demo.avatar_shadow.visible = false
	glb.global_position = foot
	for dir_name in ["bow", "starboard"]:
		var d: Vector3 = bow if dir_name == "bow" else starboard
		glb.global_basis = Basis.looking_at(-d, Vector3.UP) # glTF +Z (Blender -Y) is the face
		ap.play("run")
		var strip: Array[Image] = []
		for k in 8:
			ap.seek(float(k) * (RUN_FRAMES / RUN_FPS) / 8.0, true)
			strip.append(await _crop_img(foot))
		_save_strip("B_glb_run_%s" % dir_name, strip)
		ap.play("idle"); ap.seek(0.0, true)
		await _crop("B_glb_idle_%s" % dir_name, foot)
	ap.play("run")
	rows["B_frame_ms"] = await _frame_ms(240, ap)
	glb.visible = false
	# C: sprite frames on the billboard (d0 = back view; d2/d6 = profiles).
	var sheet := {}
	for d in [0, 2, 6]:
		for k in RUN_FRAMES:
			sheet["run_d%d_%02d" % [d, k]] = ImageTexture.create_from_image(Image.load_from_file(assets.path_join("frames/run_d%d_%02d.png" % [d, k])))
	var spike: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(assets.path_join("spike.json")))
	var sw: float = spike.sheet.px[0]
	var sh: float = spike.sheet.px[1]
	var ppm: float = sh / float(spike.sheet.ortho_scale_m) * cos(deg_to_rad(float(spike.sheet.elevation_deg)))
	demo.avatar.pixel_size = 1.0 / ppm
	demo.avatar.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var foot_px := sh * 0.5 + 0.85 * cos(deg_to_rad(float(spike.sheet.elevation_deg))) * sh / float(spike.sheet.ortho_scale_m)
	demo.avatar.offset = Vector2(-sw * 0.5, foot_px - sh)
	for pair in [["bow", 0], ["starboard", 6]]:
		var strip: Array[Image] = []
		for k in 8:
			demo.avatar.texture = sheet["run_d%d_%02d" % [pair[1], (k * RUN_FRAMES) / 8]]
			strip.append(await _crop_img(foot))
		_save_strip("C_sheet_run_%s" % pair[0], strip)
	rows["C_frame_ms"] = await _frame_ms(240)
	# D: the painted billboard itself, procedurally animated (bob, sway, step squash; no new art).
	demo.avatar.load_dir("res://assets/characters/captain")
	demo._walking = true # else the standing rule turns the captain back toward the bow
	for pair in [["bow", "back"], ["starboard", "se"]]:
		# the demo turns a standing captain to the back each frame; show the wanted facing in its place
		demo.avatar.textures["y0_back"] = demo.avatar.textures["y0_" + pair[1]]
		demo.avatar.facing = "back"
		demo.avatar._show()
		var strip: Array[Image] = []
		for k in 8:
			var ph := float(k) / 8.0 * TAU
			demo.avatar_pos = foot + Vector3.UP * 0.035 * absf(sin(ph))
			demo.avatar.scale = Vector3(1.0 + 0.03 * sin(2.0 * ph), 1.0 - 0.02 * absf(cos(ph)), 1.0)
			demo.avatar.offset.x = -demo.avatar.anchor_px.x + 18.0 * sin(ph)
			strip.append(await _crop_img(foot))
		_save_strip("D_painted_procedural_%s" % pair[0], strip)
	demo.avatar.scale = Vector3.ONE
	demo.avatar_pos = foot
	rows["figure_px"] = CameraDirector.figure_px(demo.camera.global_transform, foot, 1.754, float(px.y))
	rows["triangles_glb"] = spike.get("triangles")
	var f := FileAccess.open(out + "/spike.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(rows, "  "))
	f.close()
	print("captain-anim-spike: %s" % JSON.stringify(rows))
	quit(0)


func _player(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var p := _player(c)
		if p != null:
			return p
	return null


func _ink(n: Node) -> void:
	var ink := ShaderMaterial.new()
	ink.shader = load("res://interior/outline.gdshader")
	ink.set_shader_parameter("width", OUTLINE_M)
	var stack: Array = [n]
	while not stack.is_empty():
		var m: Node = stack.pop_back()
		if m is MeshInstance3D and m.mesh != null:
			for i in m.mesh.get_surface_count():
				var mat: Material = m.mesh.surface_get_material(i)
				if mat != null:
					var own := mat.duplicate() as Material
					own.next_pass = ink
					m.set_surface_override_material(i, own)
		stack.append_array(m.get_children())


func _crop_img(foot: Vector3) -> Image:
	for k in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	if not FileAccess.file_exists(out + "/context_bow_1440p.png"):
		img.save_png(out + "/context_bow_1440p.png") # the first shot (today's still) in context
	var mid: Vector2 = demo.camera.unproject_position(foot + Vector3.UP * 0.88) * Vector2(px) / Vector2(demo.geometry_view.size)
	mid *= Vector2(img.get_size()) / Vector2(px) # the window may be wider than px (no aspect keep)
	var r := Rect2i(Vector2i(mid) - Vector2i(CROP / 2, CROP / 2), Vector2i(CROP, CROP))
	return img.get_region(r)


func _crop(name: String, foot: Vector3) -> void:
	var c := await _crop_img(foot)
	c.save_png(out + "/" + name + ".png")
	var big := c.duplicate() as Image
	big.resize(CROP * 3, CROP * 3, Image.INTERPOLATE_NEAREST)
	big.save_png(out + "/" + name + "_3x.png")


func _save_strip(name: String, frames: Array[Image]) -> void:
	var strip := Image.create(CROP * frames.size(), CROP, false, frames[0].get_format())
	for k in frames.size():
		strip.blit_rect(frames[k], Rect2i(0, 0, CROP, CROP), Vector2i(k * CROP, 0))
	strip.save_png(out + "/" + name + ".png")
	var big := strip.duplicate() as Image
	big.resize(strip.get_width() * 3, CROP * 3, Image.INTERPOLATE_NEAREST)
	big.save_png(out + "/" + name + "_3x.png")


## Mean wall time per rendered frame (ms) over n frames, the animation advancing in real time.
func _frame_ms(n: int, ap: AnimationPlayer = null) -> float:
	await RenderingServer.frame_post_draw
	var t0 := Time.get_ticks_usec()
	for k in n:
		if ap != null:
			ap.advance(1.0 / 60.0)
		demo._process(1.0 / 60.0)
		await RenderingServer.frame_post_draw
	return float(Time.get_ticks_usec() - t0) / 1000.0 / float(n)
