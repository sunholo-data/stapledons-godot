extends SceneTree
## R2-LEVELS AC14 (design_docs/planned/r2/levels.md §A1, §A8; ledger D-103): make level-capture
## LEVEL=<id> TAG=<tag>. GPU window, 1280x720, the live sky. For every stage and surface: each of the
## stage's views from the surface's representative point (its `at`, else the stage spawn), at rest
## at 0.99c (the review cruise snapshot), and at the first sim-driven guided stop. Production
## Commons frames use the real runtime camera and its fades (the ceiling clamp applies
## under an overhang, as in the game from LP1b). Greybox pieces are laid when the document has them.
## Writes renders/levels/<id>/<tag>/: <stage>_<surface>_<view>_<sky>.png, contact_sheet.png,
## metrics.json (LevelMetrics) and frames.sha256. Exits 1 on a missing or blank frame (a frame
## with near-zero pixel variance). Opening every frame and posting per-file URLs is the stated
## manual gate.
##   --level <id> [--layout <json>] [--tag <tag>] [--out <dir>]
##   --check-stop  headless smoke: real sim stop + actual gantry/balcony camera, no image rendering

const PX := Vector2i(1280, 720)
var demo: Node


func _initialize() -> void:
	_run.call_deferred()


func _arg(args: PackedStringArray, k: String, def := "") -> String:
	var i := args.find(k)
	return args[i + 1] if i >= 0 and i + 1 < args.size() else def


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var id := _arg(args, "--level", "bridge")
	var doc := LevelEval.load_doc(_arg(args, "--layout", LevelEval.doc_path(id)))
	var out := _arg(args, "--out", "res://renders/levels/%s/%s" % [id, _arg(args, "--tag", "capture")])
	if doc.is_empty() or not LevelSchema.validate(doc).is_empty():
		print("level-capture: FAIL no valid document for %s" % id)
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	root.size = PX
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.content_scale_size = PX
	demo = load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options = {"size": PX, "sky_state": "rest", "level_greybox": id=="commons" and str(doc.get("id",""))=="commons"}
	root.add_child(demo)
	await process_frame
	if not demo.ready_ok:
		print("level-capture: FAIL demo did not build")
		quit(1)
		return
	demo.auto = false
	demo.journey_auto_tick = false
	demo.ship_hud.visible = false
	var walk: WalkArea = null
	if demo.level_runtime!=null:
		walk=demo.walk_lower
	elif not (doc.get("pieces", []) as Array).is_empty():
		if doc.get("base_walk")=="commons":ShipLevelRuntime.prepare_geometry(demo)
		walk = LevelGreybox.build(doc, demo.geometry).walk
		if doc.get("base_walk")=="commons":walk=WalkArea.merged([demo.walk_lower,walk])
	for k in 4:
		await physics_frame
	var lm := LevelMetrics.new(demo, doc, walk)
	if args.has("--check-stop"):
		var stopped:=_prepare_stop()
		var framed:=false
		if stopped:
			demo.active_level=1;demo.walk=demo.walk_lower;demo.avatar_pos=Vector3(42,66,-14)
			demo.director.release();demo.director.set_motion("reduced");demo.director.zoom_preset=false;demo.director.deck_view="bow";demo.director.has_pose=false;demo.director.advance(0.)
			framed=_stop_body_in_frame()
		print("level-stop-check: %s (sim stop %s, real balcony body framed %s)" % ["ok" if stopped and framed else "FAIL",stopped,framed])
		quit(0 if stopped and framed else 1);return
	var names := []
	var bad := []
	var poses := []
	for sky: String in ["rest", "cruise", "stop"]:
		if sky=="stop":
			if not _prepare_stop():bad.append("sim-driven stop not reached");continue
		elif not demo.set_sky_state(sky):bad.append("sky state "+sky);continue
		for s: Dictionary in doc.stages:
			for f: Dictionary in s.surfaces:
				var c := LevelMetrics.gltf(f.get("at", [float(s.spawn[0]), float(s.spawn[1]), float(f.z_m)]))
				for v: Dictionary in s.views:
					var head := c + Vector3(0, LevelMetrics.HEAD_M, 0)
					var under := str(v.get("kind", "walk")) == "walk" and not lm.hit(head, head + Vector3(0, float((v.get("ceiling_clamp", LevelMetrics.CLAMP) as Dictionary).get("probe_m", 8.0)), 0)).is_empty()
					var name := "%s_%s_%s_%s" % [s.id, f.id, v.id, sky]
					demo.consoles.cancel_walk()
					if id=="commons" and demo.level_runtime!=null:
						demo.active_level=1;demo.walk=demo.walk_lower
						demo.director.release();demo.director.zoom_preset=false;demo.director.set_motion("reduced")
						demo.director.deck_view=str(v.id);demo.director.mapping_view=str(v.id);demo.director.has_pose=false
					else:demo.director.override()
					demo.avatar_pos = c
					demo.captain_yaw = -PI * 0.5
					demo.camera_mode = "player" if id=="commons" and demo.level_runtime!=null else "review"
					for k in 20:
						demo._process(1.0 / 60.0)
					demo.avatar_pos = c
					if id=="commons" and demo.level_runtime!=null:
						demo.director.advance(0.)
					else:demo.camera.global_transform = LevelMetrics.pose(v, c, under)
					demo._sync_observer()
					for k in 6:
						await process_frame
					await RenderingServer.frame_post_draw
					var img := root.get_texture().get_image()
					var path := "%s/%s.png" % [out, name]
					img.save_png(path)
					var eye: Vector3=demo.camera.global_position
					poses.append({"name":name,"stage":s.id,"surface":f.id,"view":demo.director.view_id,"foot_gltf_m":[c.x,c.y,c.z],"eye_gltf_m":[eye.x,eye.y,eye.z],"clamp_share":demo.director.ceiling_blend,"sim_stop":sky=="stop"})
					if sky=="stop":
						var body_point: Vector3=demo.camera.global_position+_stop_body_direction()*1000.
						var body_pixel: Vector2=demo.camera.unproject_position(body_point)
						poses[-1]["stop_body_pixel"]=[body_pixel.x,body_pixel.y]
						poses[-1]["stop_body_in_frame"]=_stop_body_in_frame()
					if sky=="stop" and str(s.id)=="gantry" and str(f.id)=="balcony" and str(v.id)=="bow" and not _stop_body_in_frame():bad.append(name+" stop body outside the actual balcony frame")
					names.append(name)
					if not FileAccess.file_exists(path) or _variance(img) < 1e-5:
						bad.append("blank or missing frame "+name)
					print("shot %s%s" % [name, " (ceiling clamp)" if under else ""])
	FileAccess.open(out+"/poses.json",FileAccess.WRITE).store_string(JSON.stringify(poses,"  ")+"\n")
	var m := lm.measure()
	var mf := FileAccess.open(out + "/metrics.json", FileAccess.WRITE)
	mf.store_string(JSON.stringify(m, "  "))
	var sums := PackedStringArray()
	for n: String in names:
		sums.append("%s  %s.png" % [FileAccess.get_sha256("%s/%s.png" % [out, n]), n])
	var sf := FileAccess.open(out + "/frames.sha256", FileAccess.WRITE)
	sf.store_string("\n".join(sums) + "\n")
	_sheet(out, names)
	for b: String in bad:
		print("level-capture: FAIL %s" % b)
	print("level-capture: %s %d frames%s" % [id, names.size(), "" if bad.is_empty() else ", FAIL"])
	quit(0 if bad.is_empty() and not names.is_empty() else 1)


## The same first-stop bootstrap used by style_capture/camera_views_capture: simulation and the
## attended stop-turn rule supply the body and attitude. No invented review planet or sky.
func _prepare_stop() -> bool:
	demo.active_level=0;demo.walk=demo.walk_bridge;demo.avatar_pos=demo.bridge_spawn()
	demo.camera_mode="player";demo.director.release();demo.director.zoom_preset=false
	if not demo.start_solar_departure():return false
	for step in 2400:
		demo._process(1./60.)
		if demo.solar_tour==null:return false
		if demo.solar_tour.attitude_hold:demo.journey_tick()
		if step>10 and not demo.solar_tour.attitude_hold and not demo.under_way() and demo._attitude_stop>=-1 and demo._attitude_mode.is_empty() and not demo.tour_attitude.turning():
			demo.solar_tour.paused=true
			return true
	return false

func _stop_body_direction() -> Vector3:
	if demo.solar_tour==null:return Vector3.ZERO
	var id: String="earth" if demo.solar_tour.leg_index<0 else str(demo.solar_tour.itinerary[demo.solar_tour.leg_index].id)
	for body: Dictionary in demo.sky_world.get("system",{}).get("bodies",[]):
		if body.id==id or str(body.get("catalogue_id",""))==id:
			var direction:=ShipFrame.to_ship(demo.camera.attitude_basis,PackedFloat64Array(ShipFrame._unit([float(body.rel_km.x),float(body.rel_km.y),float(body.rel_km.z)])))
			return ShipCamera.gltf_from_ship([direction[0],direction[1],direction[2]]).normalized()
	return Vector3.ZERO

func _stop_body_in_frame() -> bool:
	var direction:=_stop_body_direction()
	if direction.length()<.9:return false
	var point: Vector3=demo.camera.global_position+direction*1000.
	return not demo.camera.is_position_behind(point) and Rect2(Vector2.ZERO,Vector2(PX)).has_point(demo.camera.unproject_position(point))


func _variance(img: Image) -> float:
	var s := img.duplicate() as Image
	s.resize(64, 36, Image.INTERPOLATE_BILINEAR)
	var n := 0
	var mean := 0.0
	var sq := 0.0
	for y in 36:
		for x in 64:
			var l := s.get_pixel(x, y).get_luminance()
			mean += l
			sq += l * l
			n += 1
	mean /= n
	return sq / n - mean * mean


func _sheet(out: String, names: Array) -> void:
	var w := 320
	var h := 180
	var g := 8
	var cols := 4
	var rows := ceili(names.size() / float(cols))
	var img := Image.create(cols * (w + g) + g, rows * (h + g) + g, false, Image.FORMAT_RGB8)
	img.fill(Color(0.06, 0.06, 0.08))
	for i in names.size():
		var f := Image.load_from_file(ProjectSettings.globalize_path("%s/%s.png" % [out, names[i]]))
		if f == null:
			continue
		f.convert(Image.FORMAT_RGB8)
		f.resize(w, h, Image.INTERPOLATE_LANCZOS)
		img.blit_rect(f, Rect2i(0, 0, w, h), Vector2i(g + (i % cols) * (w + g), g + (i / cols) * (h + g)))
	img.save_png("%s/contact_sheet.png" % out)
