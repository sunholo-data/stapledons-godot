extends SceneTree
## Contact review on actual player cameras. Headless --metrics writes geometry evidence only;
## windowed mode additionally writes pose frames, chair crops and a 2-facing contact sheet.
## godot --audio-driver Dummy --path . --resolution 1280x720 --script tools/captain_chair_capture.gd -- --out=...
const CONTACT := preload("res://interior/captain_chair_contact.gd")
const DT := 1.0 / 60.0
const SIZE := Vector2i(1280, 720)
const CROP := Vector2i(320, 320)
var out := "res://renders/captain_command/chair"
var metrics := false
var demo: Node
var report := {"schema": "stapledons.chair-contact-review/1", "visual_acceptance": "pending", "frames": []}

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
		if arg == "--metrics":metrics = true
	_run.call_deferred()

func _run() -> void:
	if DisplayServer.get_name() == "headless" and not metrics:
		print("FAIL chair capture requires a renderer; --metrics produces geometry only")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	root.size = SIZE
	demo = load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options = {"size": SIZE, "stars": false, "background": false}
	root.add_child(demo)
	await process_frame
	if not demo.ready_ok:
		print("FAIL chair capture ship did not build")
		quit(1)
		return
	demo.auto = false
	demo.journey_auto_tick = false
	demo.captain_anim_auto = false
	demo.process_mode = Node.PROCESS_MODE_DISABLED
	demo.ship_hud.visible = false
	demo.geometry_view.size = SIZE
	var contact := CONTACT.measure(demo.props_visual)
	if contact.is_empty():
		print("FAIL chair/cushion geometry missing")
		quit(1)
		return
	report["geometry"] = _serialise(contact)
	report["runtime_foot"] = _vec(demo.chair_seat())
	report["baseline_foot"] = _vec(contact.chair_origin)
	report["candidate_delta_m"] = _vec(contact.foot - contact.chair_origin)
	report["note"] = "Foot/pelvis alignment derives from the CA2 rig, not a certified raster contact fit. Inspect cushion, back and arms in both facings; physical seat height differs from the guide's nominal 0.46 m. No depth test or transparency is disabled."
	if not metrics:
		await _poses(contact)
	var f := FileAccess.open(out.path_join("contact.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  ") + "\n")
	f.close()
	demo.queue_free()
	await process_frame
	print("captain-chair-capture: %d frames, 0 failures (%s)" % [report.frames.size(), "geometry only" if metrics else "inspect contact_sheet.png"])
	quit(0)

func _poses(contact: Dictionary) -> void:
	var sheet := Image.create(CROP.x * 6, CROP.y * 2, false, Image.FORMAT_RGBA8)
	var column := 0
	for view in ["bow", "astern"]:
		column = 0
		for origin in ["baseline", "candidate"]:
			demo.avatar_pos = contact.chair_origin if origin == "baseline" else contact.foot
			demo.director.walk(view, false, true)
			for k in 100:demo._process(DT)
			var a := CaptainAnim.new()
			a.heading = contact.forward
			for beat in [["sit", 1], ["seated", 50], ["stand", 1]]:
				var o: Dictionary
				if beat[0] == "sit":
					o = a.step({"chair": "sit", "view_yaw": demo.director.walk_yaw(), "face_dir": contact.forward}, DT)
				elif beat[0] == "stand":
					o = a.step({"move_request": true, "view_yaw": demo.director.walk_yaw(), "face_dir": contact.forward}, DT)
				else:
					for k in beat[1]:o = a.step({"view_yaw": demo.director.walk_yaw(), "face_dir": contact.forward}, DT)
				demo.avatar.show_anim(o)
				for k in 2:await process_frame
				await RenderingServer.frame_post_draw
				var image: Image = demo.geometry_view.get_texture().get_image()
				image.convert(Image.FORMAT_RGBA8)
				var name := "%s_%s_%s" % [view, origin, beat[0]]
				image.save_png(out.path_join(name + ".png"))
				var centre: Vector2 = demo.camera.unproject_position(contact.seat + Vector3.UP * 0.35)
				var point := Vector2i(centre) - CROP / 2
				point.x = clampi(point.x, 0, image.get_width() - CROP.x)
				point.y = clampi(point.y, 0, image.get_height() - CROP.y)
				var crop := image.get_region(Rect2i(point, CROP))
				crop.save_png(out.path_join(name + "_detail.png"))
				sheet.blit_rect(crop, Rect2i(Vector2i.ZERO, CROP), Vector2i(column * CROP.x, (0 if view == "bow" else 1) * CROP.y))
				report.frames.append({"name": name, "view_id": demo.director.view_id, "facing": o.facing, "clip": o.clip, "painted_file": demo.avatar.shown.get("file", ""), "root": _vec(demo.avatar_pos)})
				column += 1
	sheet.save_png(out.path_join("contact_sheet.png"))

static func _vec(v: Vector3) -> Array:
	return [v.x, v.y, v.z]

static func _serialise(d: Dictionary) -> Dictionary:
	var result := {}
	for key in d:
		result[key] = _vec(d[key]) if d[key] is Vector3 else d[key]
	return result
