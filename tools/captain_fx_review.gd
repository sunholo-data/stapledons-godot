extends SceneTree
## R2-CAPTAIN-ANIMATION D-118 review set (GPU window, 1280 x 720, the figure ~67-81 px):
##   feet/<before|after>_<spot>_<facing>/fNN.png  each walk frame in game at three spots (Bow at the spawn,
##          Bow at a far spot, Astern at the spawn), before the deck settle (the crops as ingested) and after,
##          with a cyan line on the deck under the captain; feet.json: per frame the lowest captain pixel
##          against the deck line (screen px, + = below the deck)
##   fx/<effect>_<facing>/fNNN.png  2 s of walking in place at 60 fps with each between-frame effect
##          (none, echo, trail, blur), in back and profile; fx.json: the GPU frame time per effect
## Usage: godot --path . --resolution 1280x720 --script tools/captain_fx_review.gd -- --out=<dir>
const CAPTAIN := "res://assets/characters/captain"
const CROP := 240
const DT := 1.0 / 60.0
var demo: Node
var out := ""
var px := Vector2i(1280, 720)
var failures := 0
var feet_only := false
var _iso: SubViewport
var _iso_cam: Camera3D
var _iso_sprite: Sprite3D


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
		elif a.begins_with("--res="):
			var r := a.trim_prefix("--res=").split("x")
			px = Vector2i(int(r[0]), int(r[1]))
		elif a == "--feet-only":
			feet_only = true
	DirAccess.make_dir_recursive_absolute(out)
	root.size = px
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
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
	demo.process_mode = Node.PROCESS_MODE_DISABLED
	demo.captain_anim_auto = false
	demo.avatar.load_anim(CAPTAIN)
	var anim: Dictionary = demo.avatar.anim
	var walk: Dictionary = anim.clips.walk
	var settled: Dictionary = anim.get("settle_dy_cell_px", {})
	# --- Feet on the floor, before and after the settle -----------------------------------------------
	var spots := {"bow_spawn": ["bow", demo.bridge_spawn()], "bow_far": ["bow", demo.walk_bridge.closest_walkable(Vector3(-12, 82, 4), 4.0)], "astern_spawn": ["astern", demo.bridge_spawn()]}
	var feet := {}
	for mode in ["before", "after"]:
		var a2: Dictionary = anim.duplicate(true)
		if mode == "before":
			for facing: String in a2.clips.walk.stages["0"]:
				for e: Dictionary in a2.clips.walk.stages["0"][facing]:
					e.crop[1] = float(e.crop[1]) - float(settled.get(str(e.file).get_file().get_basename(), 0.0))
		for spot: String in spots:
			demo.director.walk(spots[spot][0])
			demo.avatar_pos = spots[spot][1]
			demo.avatar.anim = {}
			for k in 240:
				demo._process(DT)
			demo.avatar_shadow.visible = false
			demo.avatar.anim = a2
			for facing: String in a2.clips.walk.stages["0"]:
				var dir := out.path_join("feet/%s_%s_%s" % [mode, spot, facing])
				DirAccess.make_dir_recursive_absolute(dir)
				var n: int = a2.clips.walk.stages["0"][facing].size()
				var rows := []
				for i in n:
					demo.avatar.show_anim({"clip": "walk", "facing": facing, "flip": false, "sector": 0 if facing == "back" else 2, "phase": (i + 0.5) / n})
					demo._process(DT)
					demo.avatar.show_anim({"clip": "walk", "facing": facing, "flip": false, "sector": 0 if facing == "back" else 2, "phase": (i + 0.5) / n})
					# The sole as the game rasterises the sprite, measured on the sprite alone (_alone); the
					# floor would otherwise cut a sunk sole off, which is what "the foot sinks" looks like.
					var deck_y := float(CROP) / 2.0 + _deck_offset()
					var low := _lowest_alpha(await _alone(demo.avatar_pos))
					var seen := await _crop(demo.avatar_pos) # as the game draws it
					rows.append(snappedf(low + 1.0 - deck_y, 0.1)) # the bottom edge of the lowest captain pixel
					# The window may be larger than the geometry view (no aspect keep): scale the offset as the crop is.
					_line(seen, int(round(float(CROP) / 2.0 + _deck_offset() * float(root.get_texture().get_height()) / float(demo.geometry_view.size.y))), Color(0.2, 0.9, 1.0))
					seen.save_png(dir.path_join("f%02d.png" % i))
				feet["%s_%s_%s" % [mode, spot, facing]] = rows
				print("feet %s %s %s: below the deck (px, + = below) %s" % [mode, spot, facing, rows])
	demo.avatar.anim = anim
	demo.avatar_shadow.visible = true
	var f := FileAccess.open(out.path_join("feet.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"about": "the lowest captain pixel's bottom edge against the deck under the captain, screen px at 1280x720 (+ = below the deck), each walk frame, before and after the D-118 settle", "rows": feet}, "  "))
	f.close()
	for k: String in feet:
		if k.begins_with("after") and feet[k].any(func(v): return v > 1.0 or v < -1.5):
			failures += 1
			print("FAIL %s: a sole below the deck" % k)
	if feet_only:
		print("captain-fx-review: %d failures" % failures)
		quit(1 if failures else 0)
		return
	# --- The between-frame effects ----------------------------------------------------------------------
	demo.director.walk("bow")
	demo.avatar_pos = spots.bow_far[1]
	for k in 240:
		demo._process(DT)
	var fx := {}
	RenderingServer.viewport_set_measure_render_time(demo.geometry_view.get_viewport_rid(), true)
	for effect in CaptainAvatar.EFFECTS:
		demo.avatar.effect = effect
		for facing in ["back", "profile"]:
			var dir := out.path_join("fx/%s_%s" % [effect, facing])
			DirAccess.make_dir_recursive_absolute(dir)
			var a := CaptainAnim.new()
			a.use_gait(walk)
			a.heading = Vector3(0, 0, -1) if facing == "back" else Vector3(1, 0, 0)
			var gpu := 0.0
			for t in 120:
				var o := a.step({"velocity": a.heading * ShipConsoles.WALK_SPEED_MPS, "view_yaw": demo.director.walk_yaw()}, DT)
				demo.avatar.show_anim(o)
				demo._process(DT)
				demo.avatar.show_anim(o)
				var img := await _crop(demo.avatar_pos)
				gpu += RenderingServer.viewport_get_measured_render_time_gpu(demo.geometry_view.get_viewport_rid())
				img.save_png(dir.path_join("f%03d.png" % t))
			fx["%s_%s" % [effect, facing]] = {"frames": 120, "ms_per_frame": snappedf(1000.0 * DT, 0.01), "gpu_ms_mean": snappedf(gpu / 120.0, 0.001)}
			print("fx %s %s: gpu %.3f ms" % [effect, facing, gpu / 120.0])
	demo.avatar.effect = "none"
	f = FileAccess.open(out.path_join("fx.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"about": "2 s of walking in place at 60 fps per effect (in-game time; the painted frame changes every ~95 ms); gpu_ms_mean would be the whole frame's GPU time, but the Metal driver returns 0 for viewport GPU timers here, so it is not measured; the shader adds at most 5 texture taps per captain pixel (about 1,000 px at 720p, 4,000 at 1440p)", "options": fx}, "  "))
	f.close()
	print("captain-fx-review: %d failures" % failures)
	quit(1 if failures else 0)


## The deck point's screen y in the crop, relative to the crop centre (the crop is centred 0.88 m up).
func _deck_offset() -> float:
	var foot: Vector2 = demo.camera.unproject_position(demo.avatar_pos)
	var mid: Vector2 = demo.camera.unproject_position(demo.avatar_pos + Vector3.UP * 0.88)
	return foot.y - mid.y


func _crop(foot: Vector3) -> Image:
	for k in 2:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	var mid: Vector2 = demo.camera.unproject_position(foot + Vector3.UP * 0.88) * Vector2(img.get_size()) / Vector2(demo.geometry_view.size)
	return img.get_region(Rect2i(Vector2i(mid) - Vector2i(CROP / 2, CROP / 2), Vector2i(CROP, CROP)))


## The captain alone: the same sprite and camera in an empty, transparent world, so its pixels are its own
## (the deck's colours and the floor's depth test cannot hide or fake a sole). Returns the crop's alpha.
func _alone(foot: Vector3) -> Image:
	if _iso == null:
		_iso = SubViewport.new()
		_iso.size = px
		_iso.transparent_bg = true
		_iso.own_world_3d = true
		_iso.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(_iso)
		_iso_cam = Camera3D.new()
		_iso.add_child(_iso_cam)
		_iso_sprite = Sprite3D.new()
		_iso.add_child(_iso_sprite)
	var src: CaptainAvatar = demo.avatar
	var cam: Camera3D = demo.camera
	_iso_cam.global_transform = cam.global_transform
	_iso_cam.fov = cam.fov
	_iso_cam.near = cam.near
	_iso_cam.far = cam.far
	_iso_cam.keep_aspect = cam.keep_aspect
	_iso_sprite.texture = src.texture
	_iso_sprite.offset = src.offset
	_iso_sprite.pixel_size = src.pixel_size
	_iso_sprite.flip_h = src.flip_h
	_iso_sprite.centered = src.centered
	_iso_sprite.billboard = src.billboard
	_iso_sprite.shaded = false
	_iso_sprite.alpha_cut = src.alpha_cut
	_iso_sprite.texture_filter = src.texture_filter
	_iso_sprite.global_position = src.global_position
	for k in 2:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := _iso.get_texture().get_image()
	img.convert(Image.FORMAT_RGBA8)
	var mid: Vector2 = cam.unproject_position(foot + Vector3.UP * 0.88) * Vector2(img.get_size()) / Vector2(demo.geometry_view.size)
	return img.get_region(Rect2i(Vector2i(mid) - Vector2i(CROP / 2, CROP / 2), Vector2i(CROP, CROP)))


static func _lowest_alpha(img: Image) -> float:
	for y in range(CROP - 1, -1, -1):
		for x in CROP:
			if img.get_pixel(x, y).a > 0.5:
				return float(y)
	return -1.0


## The lowest row (in a 60 px column band at the centre) that differs from the empty deck.
static func _lowest_diff(img: Image, empty: Image) -> float:
	for y in range(CROP - 1, -1, -1):
		for x in range(CROP / 2 - 30, CROP / 2 + 30):
			var a := img.get_pixel(x, y)
			var b := empty.get_pixel(x, y)
			if absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) > 0.6: # the solid sole, not its filtered fringe (mipmaps at 67-81 px spread alpha about 1 px)
				return float(y)
	return -1.0


static func _line(img: Image, y: int, c: Color) -> void:
	if y < 0 or y >= img.get_height():
		return
	for x in range(0, img.get_width(), 2):
		img.set_pixel(x, y, c)
