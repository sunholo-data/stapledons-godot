extends SceneTree
## make star-surface-capture (R2-STAR-SURFACES AC12; GPU window): free navigation through the real sim
## at protocol 2.13 to a red dwarf (TRAPPIST-1), a giant (Aldebaran), a Sun-like star (alpha Cen A),
## an inferred red dwarf (Barnard's Star) and home (the Sun from Earth). At each stop: the Bow view as
## the player sees it (Auto), the sky alone in Auto with the surface map and without it ("today"),
## and in Realistic; a 720 px nearest-neighbour crop around each resolved star; a contact sheet; and
## capture.json with each star's apparent size, cells and spots on screen, N and the map's state.
## Out: renders/star_surfaces/ss2/ (or --out=DIR). Open the frames.
var demo: Node
var out := "res://renders/star_surfaces/ss2"
var rows: Array = []
var crops: Array = []
var frame_w := 2560
var frame_h := 1440


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
	root.size = Vector2i(2560, 1440)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	demo = load("res://demos/ship_geometry_demo.tscn").instantiate()
	root.add_child(demo)
	demo.auto = false
	await process_frame
	if not demo.ready_ok:
		quit(1)
		return
	demo.journey_auto_tick = false
	demo.sky.system_view.surface_norm_wait = true
	var probe := root.get_texture().get_image()
	frame_w = probe.get_width()
	frame_h = probe.get_height()
	var only: Array[String] = []
	for a in OS.get_cmdline_user_args():
		if not a.begins_with("--"):
			only.append(a)
	var list := [["trappist1", "Gaia DR3 2635476908753563008"], ["aldebaran", "CNS5:1142"], ["acen_a", "CNS5:3627"], ["barnard", "Gaia DR3 4472832130942575872"], ["earth", "Sol"]]
	var n := 0
	for stop: Array in list:
		if not only.is_empty() and not only.has(stop[0]):
			continue
		demo.open_navigation()
		if stop[1] == "Sol":
			demo.journey_map.plan_home()
		else:
			demo.journey_map.preselect(demo.journey_map.index_of(stop[1]))
		if not await _leg():
			print("star-surface-capture: FAIL no arrival at %s (%s)" % [stop[0], demo.journey_map.status_text()])
			continue
		n += await _shots(stop[0])
	_sheet()
	var f := FileAccess.open(out + "/capture.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(rows, "  ") + "\n")
	print("star-surface-capture: OK %d frames" % n)
	quit()


func _leg() -> bool:
	var map = demo.journey_map
	demo.journey_tick()
	if not (map.open_commit_dialog() and map.hold_commit(GalaxyMap.HOLD_S) and demo.journey_tick() and demo.live_journey):
		return false
	for i in 6000:
		if not demo.journey_tick() or not demo.live_journey:
			break
	await process_frame
	return map.journey_state() == "arrived"


func _shot(name: String, auto: bool, surfaces: bool) -> Image:
	demo.set_auto_view(auto)
	demo.sky.system_view.surfaces_enabled = surfaces
	for i in 8:
		await process_frame
	demo.sky.update_exposure()
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(out + "/" + name + ".png")
	return img


func _shots(name: String) -> int:
	var sv: SystemView = demo.sky.system_view
	var frames := 0
	await _shot(name + "_bow_auto", true, true)
	frames += 1
	demo.look_direction("forward")
	if not demo.sky_only:
		demo.toggle_sky_only()
	for i in 6:
		await process_frame
	var fov_rad := deg_to_rad(demo.sky.camera.fov)
	for b: Dictionary in demo.sky_world.get("system", {}).get("bodies", []):
		if b.kind != "star" or not sv.discs.has(b.id) or not (sv.discs[b.id] as MeshInstance3D).visible:
			continue
		var d := Planets.length64(Planets.world_of(b.rel_km))
		var ang := Planets.angular_radius(b.radius_km, d)
		var px_r := ang / (fov_rad / float(demo.sky.size.y)) * float(frame_h) / float(demo.sky.size.y)
		var m: ShaderMaterial = sv.discs[b.id].material_override
		var surface: Dictionary = b.get("surface", {})
		var row := {"stop": name, "star": b.id, "apparent_diameter_deg": rad_to_deg(2.0 * ang), "disc_px_across": 2.0 * px_r, "frame": "%dx%d" % [frame_w, frame_h], "has_surface": not surface.is_empty()}
		if not surface.is_empty():
			row["cell_px_at_centre"] = 2.0 * px_r * float(surface.cell_km) / (2.0 * b.radius_km)
			row["spots"] = surface.spots.size()
			var basis := StarSurface.basis_of(b["pole"])
			var c: Vector3 = m.get_shader_parameter("centre_w")
			var view_star := basis.transposed() * (-c.normalized())
			var facing := 0
			for sp: Dictionary in StarSurface.spots_of(surface):
				if (sp.dir as Vector3).dot(view_star) > 0.2:
					facing += 1
			row["spots_facing"] = facing
			row["ld"] = surface.ld
			row["prov"] = surface.prov
		var on := await _shot(name + "_sky_auto", true, true)
		row["surf_on"] = bool(m.get_shader_parameter("surf_on"))
		var sn: Variant = m.get_shader_parameter("surf_norm")
		row["surf_norm"] = float(sn) if sn != null else 1.0
		var off := await _shot(name + "_sky_auto_today", true, false)
		var real := await _shot(name + "_sky_realistic", false, true)
		frames += 3
		rows.append(row)
		print("star-surface-capture ", JSON.stringify(row))
		var at := _disc_px(m)
		var in_frame: bool = Rect2i(0, 0, frame_w, frame_h).has_point(at) and not demo.sky.camera.is_position_behind(m.get_shader_parameter("centre_w"))
		row["in_frame"] = in_frame
		if px_r >= 4.0 and in_frame:
			_crop(on, name + "_crop_auto", px_r, at)
			_crop(off, name + "_crop_auto_today", px_r, at)
			_crop(real, name + "_crop_realistic", px_r, at)
			crops.append(name)
			frames += 3
	if demo.sky_only:
		demo.toggle_sky_only()
	demo.set_auto_view(false)
	sv.surfaces_enabled = true
	return frames


func _disc_px(m: ShaderMaterial) -> Vector2i:
	var c: Vector3 = m.get_shader_parameter("centre_w")
	var p: Vector2 = demo.sky.camera.unproject_position(c)
	return Vector2i(int(p.x * float(frame_w) / float(demo.sky.size.x)), int(p.y * float(frame_h) / float(demo.sky.size.y)))


func _crop(img: Image, name: String, px_r: float, at: Vector2i) -> void:
	var half := int(clampf(px_r * 1.25, 12.0, 640.0))
	var r := Rect2i(at - Vector2i(half, half), Vector2i(2 * half, 2 * half)).intersection(Rect2i(0, 0, img.get_width(), img.get_height()))
	var c := img.get_region(r)
	c.resize(720, 720, Image.INTERPOLATE_NEAREST)
	c.save_png(out + "/" + name + ".png")


## Rows: each resolved stop; columns: today (Auto), the map (Auto), the map (Realistic). 360 px tiles.
func _sheet() -> void:
	var t := 360
	if crops.is_empty():
		return
	var sheet := Image.create(3 * t + 4 * 8, crops.size() * t + (crops.size() + 1) * 8, false, Image.FORMAT_RGB8)
	sheet.fill(Color(0.06, 0.06, 0.08))
	for r in crops.size():
		var names := [crops[r] + "_crop_auto_today", crops[r] + "_crop_auto", crops[r] + "_crop_realistic"]
		for c in 3:
			var img := Image.load_from_file(out + "/" + names[c] + ".png")
			img.convert(Image.FORMAT_RGB8)
			img.resize(t, t, Image.INTERPOLATE_BILINEAR)
			sheet.blit_rect(img, Rect2i(0, 0, t, t), Vector2i(8 + c * (t + 8), 8 + r * (t + 8)))
	sheet.save_png(out + "/contact_sheet.png")
