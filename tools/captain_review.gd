extends SceneTree
## R2-CAPTAIN-ANIMATION review set (§D4 make captain-anim-capture; the CA1 pilot pause): the captain
## through the real Bow view at 1280 x 720 (the figure ~81 px), as Mark reviews it on a web page.
##   clips/<clip>_<facing>/fNN.png      each frame in game, a 240 x 240 crop around the captain
##   clips/<clip>_<facing>/fNN_3x.png   the same, 3x (nearest)
##   cells/<file>.png                   the painted cells themselves (from the manifest)
##   moonwalk/<mode>/fNN.png            a 2 s walk to starboard: today's rule (before), CA0 with the
##                                      stills (facing by motion), CA0 with the pilot's painted frames
##   contact_sheet.png                  every clip's frames in rows
##   review.json                        clips, facings, frame counts, timing, the frame checks
## The animated WebPs are assembled from these by tools/captain_review.sh (img2webp).
## Machine half (AC6): fails on a missing, blank (no captain pixels) or frozen gait strip.
## GPU window: make captain-anim-capture OUT=<dir>.
var demo: Node
var out := ""
var px := Vector2i(1280, 720)
const CROP := 240
const DT := 1.0 / 60.0
var failures := 0
var bg: Image
var review := {"clips": [], "moonwalk": [], "view": "Bow", "resolution": [1280, 720]}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
	if out == "":
		out = ProjectSettings.globalize_path("res://build/captain_review")
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
	demo.process_mode = Node.PROCESS_MODE_DISABLED # this tool steps the demo itself
	demo.director.walk("bow")
	var foot: Vector3 = demo.walk_bridge.closest_walkable(Vector3(-12, 82, 4), 4.0) # clear deck, port of the helm
	demo.avatar_pos = foot
	for k in 240:
		demo._process(DT)
	demo.avatar.load_anim("res://assets/characters/captain", "anim_pilot.json") # the CA1 pilot (not in the game yet)
	var anim: Dictionary = demo.avatar.anim
	demo.captain_anim_auto = false
	# The deck without the captain: a frame that differs from it by too few pixels is blank.
	var tex: Texture2D = demo.avatar.texture
	demo.avatar.texture = null
	demo._process(DT)
	bg = await _crop(foot)
	demo.avatar.texture = tex
	# The clips, frame by frame, in place.
	demo.captain_anim_auto = false
	var sheet_rows: Array = []
	for clip: String in anim.get("clips", {}):
		var c: Dictionary = anim.clips[clip]
		for facing: String in c.stages["0"]:
			var frames: Array = c.stages["0"][facing]
			var dir: String = "clips/%s_%s" % [clip, facing]
			DirAccess.make_dir_recursive_absolute(out.path_join(dir))
			var imgs: Array[Image] = []
			var sector := CaptainAnim.PAINTED.map(func(p): return p[0]).find(facing)
			for i in frames.size():
				var phase := (float(i) + 0.5) / frames.size()
				var o := {"clip": clip, "facing": facing, "flip": false, "sector": sector, "phase": phase, "clip_t": float(i) / float(c.get("fps", 2.0)),
					"bob_m": CaptainAnim.BOB_M * absf(sin(TAU * phase)) if str(c.get("kind", "")) == "gait" else 0.0}
				demo.avatar.show_anim(o)
				demo._process(DT)
				var img := await _crop(foot)
				img.save_png(out.path_join(dir + "/f%02d.png" % i))
				var big := img.duplicate() as Image
				big.resize(CROP * 3, CROP * 3, Image.INTERPOLATE_NEAREST)
				big.save_png(out.path_join(dir + "/f%02d_3x.png" % i))
				imgs.append(img)
			var gait := str(c.get("kind", "")) == "gait"
			var ms := (1000.0 * float(c.get("cycle_m", CaptainAnim.DEFAULT_CYCLE_M)) / ShipConsoles.WALK_SPEED_MPS / frames.size()) if gait else 1000.0 / float(c.get("fps", 2.0))
			var row := {"clip": clip, "facing": facing, "frames": frames.size(), "kind": c.get("kind", "time"),
				"ms_per_frame_at_game_speed": snappedf(ms, 0.1), "m_per_frame": snappedf(float(c.get("cycle_m", 0.0)) / frames.size(), 0.0001) if gait else null,
				"fps": c.get("fps", null), "dir": dir, "files": frames.map(func(e): return {"file": e.file, "flip": e.flip}),
				"blank_frames": imgs.filter(func(m): return _blank(m, bg)).size(), "frozen": gait and _frozen(imgs)}
			if row.blank_frames > 0 or row.frozen:
				failures += 1
				print("FAIL %s %s: %d blank frames, frozen %s" % [clip, facing, row.blank_frames, row.frozen])
			review.clips.append(row)
			sheet_rows.append(imgs)
			print("clip %s %s: %d frames, %.1f ms a frame" % [clip, facing, frames.size(), ms])
	_sheet(sheet_rows).save_png(out.path_join("contact_sheet.png"))
	# The painted frames themselves at 2x their cell (the art, not the game's 81 px), on a neutral grey.
	var s: float = anim.get("cell_scale", 0.1875)
	var cw := int(1024 * s)
	var ch := int(1536 * s)
	for clip: String in anim.get("clips", {}):
		for facing: String in anim.clips[clip].stages["0"]:
			var dir: String = "painted/%s_%s" % [clip, facing]
			DirAccess.make_dir_recursive_absolute(out.path_join(dir))
			var i := 0
			for e: Dictionary in anim.clips[clip].stages["0"][facing]:
				var cell := Image.load_from_file(ProjectSettings.globalize_path("res://assets/characters/captain".path_join(e.file)))
				cell.convert(Image.FORMAT_RGBA8)
				var canvas := Image.create(cw, ch, false, Image.FORMAT_RGBA8)
				canvas.fill(Color(0.42, 0.44, 0.47))
				var x: int = int(e.crop[0])
				if bool(e.flip):
					cell.flip_x()
					x = cw - int(e.crop[0]) - int(e.crop[2])
				canvas.blend_rect(cell, Rect2i(Vector2i.ZERO, cell.get_size()), Vector2i(x, int(e.crop[1])))
				canvas.resize(cw * 2, ch * 2, Image.INTERPOLATE_LANCZOS)
				canvas.save_png(out.path_join(dir + "/f%02d.png" % i))
				i += 1
	# Side by side at real size: every clip's frame i (time-based clips hold their frame).
	DirAccess.make_dir_recursive_absolute(out.path_join("side_by_side"))
	var longest := 0
	for r: Array in sheet_rows:
		longest = maxi(longest, r.size())
	for i in longest:
		var row: Array = []
		for r: Array in sheet_rows:
			row.append(r[i % r.size()])
		_sheet([row]).save_png(out.path_join("side_by_side/f%02d.png" % i))
	review["side_by_side"] = {"order": review.clips.map(func(c): return "%s_%s" % [c.clip, c.facing]), "frames": longest}
	# The moonwalk: a 2 s walk to starboard at the walk speed, before and after.
	var starboard := Vector3(1, 0, 0) # the Bow view's screen right (-sin(-pi/2), 0, cos(-pi/2))
	for mode in ["warmup", "before_today", "after_ca0_stills", "after_ca0_pilot"]: # warmup: the camera's slide state matches for all three
		var dir: String = "moonwalk/" + mode
		if mode != "warmup":
			DirAccess.make_dir_recursive_absolute(out.path_join(dir))
		demo.avatar_pos = demo.walk_bridge.closest_walkable(Vector3(-16, 82, 6), 4.0)
		for k in 360:
			demo._process(DT)
		var start: Vector3 = demo.avatar_pos
		var a := CaptainAnim.new()
		a.heading = Vector3(0, 0, -1)
		var saved: Dictionary = demo.avatar.anim
		if mode != "after_ca0_pilot":
			demo.avatar.anim = {}
		var n := 0
		for k in 120:
			demo.avatar_pos = demo.walk.step(demo.avatar_pos, starboard * ShipConsoles.WALK_SPEED_MPS * DT)
			demo._process(DT)
			if mode == "before_today":
				demo.avatar.facing = "back" # today's rule: a sideways walk keeps the back (D3)
				demo.avatar._show()
				demo.avatar.pixel_size = 1.0 / 720.0
				demo.avatar.flip_h = false
				demo.avatar.offset = Vector2(-demo.avatar.anchor_px.x, demo.avatar.anchor_px.y - demo.avatar.canvas_px.y)
			else:
				var o := a.step({"velocity": starboard * ShipConsoles.WALK_SPEED_MPS, "view_yaw": demo.director.walk_yaw()}, DT)
				demo.avatar.show_anim(o)
			if k % 5 == 0 and mode != "warmup": # 12 frames a second
				var img := await _crop(demo.avatar_pos)
				img.save_png(out.path_join(dir + "/f%02d.png" % n))
				n += 1
		demo.avatar.anim = saved
		if mode == "warmup":
			continue
		review.moonwalk.append({"mode": mode, "frames": n, "ms_per_frame": 1000.0 / 12.0, "walked_m": snappedf(start.distance_to(demo.avatar_pos), 0.01), "dir": dir})
		print("moonwalk %s: %d frames, walked %.2f m" % [mode, n, start.distance_to(demo.avatar_pos)])
	review["figure_px_720p"] = CameraDirector.figure_px(demo.camera.global_transform, foot, 1.754, float(px.y))
	var f := FileAccess.open(out.path_join("review_capture.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(review, "  "))
	f.close()
	print("captain-review: %d clips, %d failures" % [review.clips.size(), failures])
	quit(1 if failures else 0)


func _crop(foot: Vector3) -> Image:
	for k in 2:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var mid: Vector2 = demo.camera.unproject_position(foot + Vector3.UP * 0.88) * Vector2(img.get_size()) / Vector2(demo.geometry_view.size)
	var r := Rect2i(Vector2i(mid) - Vector2i(CROP / 2, CROP / 2), Vector2i(CROP, CROP))
	return img.get_region(r)


## A frame with no captain: fewer than 300 pixels differ from the empty deck (the figure is ~80 x 30 px).
static func _blank(img: Image, empty: Image) -> bool:
	var n := 0
	for y in CROP:
		for x in CROP:
			var a := img.get_pixel(x, y)
			var b := empty.get_pixel(x, y)
			if absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) > 0.15:
				n += 1
	return n < 300


static func _frozen(imgs: Array[Image]) -> bool:
	for i in range(1, imgs.size()):
		if imgs[i].get_data() != imgs[0].get_data():
			return false
	return true


static func _sheet(rows: Array) -> Image:
	var w := 0
	for r: Array in rows:
		w = maxi(w, r.size())
	var img := Image.create(maxi(1, w) * CROP, maxi(1, rows.size()) * CROP, false, Image.FORMAT_RGBA8)
	for j in rows.size():
		for i in rows[j].size():
			var m: Image = rows[j][i]
			m.convert(Image.FORMAT_RGBA8)
			img.blit_rect(m, Rect2i(0, 0, CROP, CROP), Vector2i(i * CROP, j * CROP))
	return img
