extends RefCounted
## R1-ISM-DUST I8 review captures (make ism-capture -> renders/ism/; needs a GPU window). Sim-driven:
## protocol 2.7 (lism-1), the galaxy map plans and commits Sol -> Aldebaran (the route crosses the
## LIC, the hot gas and the Hyades cloud); the frames are taken mid-cruise from the sim's state after
## real-time ticks (0.05 ship s each, so the dust flashes are the sim's own draw). 1600 x 900.
##   flight/<speed>_<medium>_{interior,forward}.png  LIC (2 ly), Hyades cloud (7 ly), hot gas (15 ly)
##           at 0.99c, 0.999c, 0.9999c, 0.999999c; and a synthetic n_H 10 cloud (uniform medium at the
##           mass-equivalent density, cap 0.9999c: glow only, its dust comes with PR B's real clouds)
##   flash_closeup.png        the brightest live flash, forward view 8 deg wide (LIC, 0.999c)
##   afterglow_sheet.png      r_s 0.25 / 0.5 / 1 m x tau 0.1 / 0.2 / 0.4 s on the same impacts (Q2)
##   eps_sheet.png            the glow at eps 1e-11 / 1e-10 / 3e-10 in the LIC and the hot gas (0.999c)
##   sensitivity_sheet.png    a_max 5 / 10 / 20 um, hot-gas delta 0.0051 / 0.002, MRN only (Q3, F4)
##   map_local.png, map_route.png  the medium layer (D) around Sol and along the planned route
##   contact_sheet.png, capture_log.json (every frame's sim fields and its uniform/NaN check)

const ALDEBARAN := "CNS5:1142"
const RT_DTAU := 0.05 / 31557600.0 # one real-time tick of ship time, yr
const FINE_DTAU := 2e-7
const FWD_FOV := 60.0
const SPEEDS := [["0p99c", 0.01], ["0p999c", 0.001], ["0p9999c", 1e-4], ["0p999999c", 1e-6]]
const STOPS := [["LIC", 2.0], ["Hyades", 7.0], ["hot", 15.0]]
const SENS := "res://.godot/tmp/ism/sensitivity.json"

var main: Node
var it: Interior
var map: GalaxyMap
var out := ""
var tiles: Array[Image] = []
var log_rows := []


func run(m: Node, interior: Interior, galaxy_map: GalaxyMap, dir: String) -> int:
	main = m
	it = interior
	map = galaxy_map
	out = dir
	DirAccess.make_dir_recursive_absolute(out.path_join("flight"))
	var sim: SimBridge = main.sim
	printerr("ism capture: start, sim minor %d" % sim.want_minor)
	for sp: Array in SPEEDS:
		if not await _voyage(sp[0], sp[1], {"standoff_au": 1000.0}, STOPS):
			return 2
	for sp: Array in [["0p99c", 0.01], ["0p999c", 0.001], ["0p9999c", 1e-4]]:
		if not await _voyage("cloud10_" + sp[0], sp[1], {"standoff_au": 1000.0, "ism_model": 0, "ism_n_cm3": 14.1, "cap_one_minus_beta": 1e-4}, [["synthetic n_H 10 cloud", 2.0]]):
			return 2
	# the flash close-up, the afterglow and eps sheets: hot gas and LIC at 0.999c
	if not await _voyage("closeup", 0.001, {"standoff_au": 1000.0}, [["LIC", 2.0]], false):
		return 2
	await _closeup()
	await _afterglow_sheet()
	await _eps_sheet()
	await _sensitivity_sheet()
	await _maps()
	_contact()
	var f := FileAccess.open(out.path_join("capture_log.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"frames": log_rows}, "  ") + "\n")
	f.close()
	sim.stop()
	var bad := log_rows.filter(func(r: Dictionary) -> bool: return not r.get("ok", false))
	printerr("ism capture: %d frames, %d uniform or NaN" % [log_rows.size(), bad.size()])
	return 1 if not bad.is_empty() else 0


func _phi(omb: float) -> float:
	return 0.5 * (log(2.0 - omb) - log(omb))


## A fresh game, the plan to Aldebaran at 1 - beta = omb, the commit, then for each stop: fly to
## `flown` ly, real-time ticks, two frames. Returns false when the plan or a stop fails.
func _voyage(tag: String, omb: float, params: Dictionary, stops: Array, frames := true) -> bool:
	var sim: SimBridge = main.sim
	printerr("ism capture: %s new game %s" % [tag, params])
	if not sim.new_game(7, "sol", false, params):
		push_error("ism capture: new_game %s" % sim.last_error)
		return false
	printerr("ism capture: %s game ok" % tag)
	map.refresh()
	it.open_map()
	map.preselect(map.index_of(ALDEBARAN))
	map.set_cruise_phi(_phi(omb))
	it.tick()
	if not map.open_commit_dialog():
		push_error("ism capture: no plan at %s (%s)" % [tag, sim.last_refused])
		return false
	var id := map.dialog_plan_id
	printerr("ism capture: %s planned (plan %d), committing" % [tag, id])
	map.close_commit_dialog()
	sim.send([{"k": "commit", "plan_id": id}], FINE_DTAU)
	map.refresh()
	it.close_map()
	while sim.world["ship"]["phase"] != "cruising" and sim.send([], FINE_DTAU):
		pass
	for st: Array in stops:
		var s: Dictionary = sim.world["ship"]
		var gb: float = float(s["gamma"]) * float(s["beta"])
		var left: float = float(st[1]) - float(s["flown"])
		printerr("ism capture: %s -> %s at %.1f ly (flown %.3f, gamma beta %.3f)" % [tag, st[0], st[1], float(s["flown"]), gb])
		var dt_left := left / gb # ship-yr; one tick takes at most 1 yr (the sim's bad_step)
		while dt_left > 0.0:
			var step := minf(dt_left, 0.9)
			if not sim.send([], step):
				break
			dt_left -= step
		for k in 8: # real-time ticks: the sim draws this tick's dust
			sim.send([], RT_DTAU)
			it.apply_state(sim.world)
			await main.get_tree().process_frame
		if frames:
			await _frames("%s_%s" % [tag, str(st[0]).replace(" ", "_")])
	return true


func _ism() -> Dictionary:
	return (main.sim as SimBridge).world.get("ship", {}).get("ism", {})


func _frames(stem: String) -> void:
	var sim: SimBridge = main.sim
	var ism := _ism()
	var s: Dictionary = sim.world["ship"]
	it.caption = "%s  medium %s  n_H %s cm-3  beta %.9f  glow pole %.0f K  impacts %d this tick  glitter %s /s" % [
		stem, IsmLayer.label_of(str(ism.get("medium", "?"))), GalaxyMap.sci(float(ism.get("n_h_cm3", 0.0))), float(s["beta"]),
		float(ism.get("glow_pole_k", 0.0)), (ism.get("impacts", []) as Array).size(), GalaxyMap.sci(float(ism.get("glitter", {}).get("rate", 0.0)))]
	var interior := await _grab()
	_save(interior, "flight/%s_interior.png" % stem, stem + " interior")
	var fwd := await _forward(FWD_FOV)
	_save(fwd, "flight/%s_forward.png" % stem, stem + " forward")


## The sky camera along the direction of travel, fov wide, square crop.
func _forward(fov: float, dir := Vector3.ZERO) -> Image:
	var sky := it.sky
	var fov0 := sky.view_fov
	var d := sky.heading_world if dir == Vector3.ZERO else dir
	var up := Vector3(0, 1, 0) if absf(d.y) < 0.9 else Vector3(1, 0, 0)
	var e3 := InteriorSky.euler_of(PackedFloat64Array([d.x, d.y, d.z]), PackedFloat64Array([up.x, up.y, up.z]))
	sky.view_fov = fov
	sky.camera.fov = fov
	sky.configure_pixel()
	sky.camera.look(e3[0], e3[1], e3[2])
	sky.update_exposure()
	for i in 4:
		await main.get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := sky.get_texture().get_image()
	var side := mini(img.get_width(), img.get_height())
	img = img.get_region(Rect2i((img.get_width() - side) / 2, (img.get_height() - side) / 2, side, side))
	sky.view_fov = fov0
	sky.camera.fov = fov0
	sky.configure_pixel()
	it.apply_state((main.sim as SimBridge).world)
	return img


func _grab() -> Image:
	for i in 4:
		await main.get_tree().process_frame
	await RenderingServer.frame_post_draw
	return main.get_viewport().get_texture().get_image()


## Save, log the sim's ISM fields and check the frame is neither uniform nor NaN.
func _save(img: Image, rel: String, label: String) -> void:
	img.save_png(out.path_join(rel))
	var lo := INF
	var hi := -INF
	var nan := false
	for y in range(0, img.get_height(), 7):
		for x in range(0, img.get_width(), 7):
			var c := img.get_pixel(x, y)
			if is_nan(c.r) or is_nan(c.g) or is_nan(c.b):
				nan = true
			lo = minf(lo, c.get_luminance())
			hi = maxf(hi, c.get_luminance())
	var ism := _ism()
	log_rows.append({"file": rel, "label": label, "ok": not nan and hi - lo > 0.01, "lum_range": [lo, hi], "medium": ism.get("medium"), "n_h_cm3": ism.get("n_h_cm3"),
		"glow_pole_k": ism.get("glow_pole_k"), "glow_pole_w_m2": ism.get("glow_pole_w_m2"), "impacts": (ism.get("impacts", []) as Array).size(), "dust": ism.get("dust"), "glitter": ism.get("glitter"),
		"beta": (main.sim as SimBridge).world["ship"]["beta"]})
	var t := img.duplicate() as Image
	t.resize(320, int(320.0 * img.get_height() / img.get_width()), Image.INTERPOLATE_BILINEAR)
	tiles.append(t)


## The sky's world direction from the panorama camera to the wall point R n (n: ship frame, unit).
func _aim(n: Vector3) -> Vector3:
	var sky := it.sky
	var c: Array = sky.cam["position_m"]
	var d := Vector3(n.x * sky.radius_m - c[0], n.y * sky.radius_m - c[1], n.z * sky.radius_m - c[2]).normalized()
	if sky.basis.size() != 9:
		return sky.heading_world
	var w := SkyFrame.to_world64(ShipFrame.to_galactic(sky.basis, PackedFloat64Array([d.x, d.y, d.z])))
	return Vector3(w[0], w[1], w[2]).normalized()


func _closeup() -> void:
	var sky := it.sky
	var live := sky.dust.live(sky.dust_clock)
	printerr("ism capture: close-up: %d live flashes" % live.size())
	var dir := sky.heading_world if live.is_empty() else _aim(live[0].dir)
	it.caption = "flash close-up: the brightest live flash, LIC, 0.999c (8 deg view)"
	_save(await _forward(8.0, dir), "flash_closeup.png", "flash close-up")


## The same impacts re-drawn with r_s x tau candidates (G-AG, a labelled game approximation; Q2).
func _afterglow_sheet() -> void:
	var sky := it.sky
	var world := (main.sim as SimBridge).world
	var cells: Array[Image] = []
	sky.dust_auto = false
	var r0 := sky.dust.r_spot
	for rs: float in [0.25, 0.5, 1.0]:
		for tau: float in [0.1, 0.2, 0.4]:
			var df := DustFlash.new()
			df.r_spot = rs
			df.tau = tau
			df.ingest(world, 0.0)
			sky.dust.r_spot = rs # _upload_exposure sends sky.dust.r_spot
			var live := df.live(0.08)
			sky.upload_dust(live)
			var dir := sky.heading_world if live.is_empty() else _aim(live[0].dir)
			cells.append(await _forward(6.0, dir))
			sky.upload_dust(live) # _forward re-applies the state; keep this cell's flashes for the record
	sky.dust.r_spot = r0
	sky.dust_auto = true
	_save(_grid(cells, 3), "afterglow_sheet.png", "afterglow sheet (G-AG, a game approximation): rows r_s 0.25/0.5/1 m, columns tau 0.1/0.2/0.4 s; the brightest flash at t = 0.08 s, 6 deg view")


func _eps_sheet() -> void:
	var cells: Array[Image] = []
	for med: Array in [["LIC", 2.0], ["hot", 15.0]]:
		await _voyage("eps", 0.001, {"standoff_au": 1000.0}, [med], false)
		for e: float in [1e-11, 1e-10, 3e-10]:
			it.glow_eps_scale = e / 1e-10
			it.apply_state((main.sim as SimBridge).world)
			cells.append(await _forward(FWD_FOV))
	it.glow_eps_scale = 1.0
	_save(_grid(cells, 3), "eps_sheet.png", "eps sheet: rows LIC, hot gas (0.999c); columns eps 1e-11, 1e-10 (canon), 3e-10")


func _sensitivity_sheet() -> void:
	var rows: Variant = JSON.parse_string(FileAccess.get_file_as_string(SENS))
	if not rows is Array:
		push_error("ism capture: %s missing (make ism-capture writes it)" % SENS)
		return
	var vp := SubViewport.new()
	vp.size = Vector2i(1500, 60 + 26 * ((rows as Array).size() + 1))
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.035, 0.05)
	bg.size = Vector2(vp.size)
	vp.add_child(bg)
	var lines := ["Sensitivity (labelled assumptions; sim/tools/ism_sensitivity.ail): smallest visible (>= 5 %) and bright (>= 1x background) grain, flashes per ship second over the wall",
		"%-44s %-7s %-10s %10s %10s %12s %12s" % ["variant", "medium", "speed", "a_vis um", "a_bright um", "visible /s", "bright /s"]]
	for r: Dictionary in rows:
		lines.append("%-44s %-7s %-10s %10.3f %10.3f %12s %12s" % [r.variant, r.medium, r.speed, float(r.a_visible_um), float(r.a_bright_um), GalaxyMap.sci(float(r.rate_visible)), GalaxyMap.sci(float(r.rate_bright))])
	var lab := Label.new()
	lab.text = "\n".join(lines)
	lab.position = Vector2(16, 12)
	lab.add_theme_font_override("font", SystemFont.new())
	(lab.get_theme_font("font") as SystemFont).font_names = PackedStringArray(["Menlo", "Courier New", "monospace"])
	lab.add_theme_font_size_override("font_size", 15)
	lab.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
	vp.add_child(lab)
	main.add_child(vp)
	for i in 3:
		await main.get_tree().process_frame
	await RenderingServer.frame_post_draw
	_save(vp.get_texture().get_image(), "sensitivity_sheet.png", "sensitivity sheet")
	vp.queue_free()


func _maps() -> void:
	var sim: SimBridge = main.sim
	sim.new_game(7, "sol", false, {"standoff_au": 1000.0})
	map.refresh()
	it.open_map()
	map.preselect(map.index_of(ALDEBARAN))
	map.set_cruise_phi(_phi(0.001))
	it.tick()
	map.ism_layer.visible = true
	map.pivot = Vector3.ZERO
	map.dist = 30.0
	map.call("_update_camera")
	map.refresh()
	map.get("_overlay").queue_redraw()
	_save(await _grab(), "map_local.png", "map: the medium layer around Sol (LIC, 14 cloud shells; D)")
	map.dist = 120.0
	map.call("_update_camera")
	map.fit_journey()
	map.get("_overlay").queue_redraw()
	_save(await _grab(), "map_route.png", "map: Sol -> Aldebaran coloured by medium, plan rows")
	map.ism_layer.visible = false
	it.close_map()


func _grid(cells: Array[Image], cols: int) -> Image:
	var w := cells[0].get_width()
	var h := cells[0].get_height()
	var rows := int(ceil(cells.size() / float(cols)))
	var img := Image.create(cols * w + (cols - 1) * 6, rows * h + (rows - 1) * 6, false, cells[0].get_format())
	img.fill(Color(0.1, 0.1, 0.12))
	for i in cells.size():
		var c := cells[i]
		if c.get_format() != img.get_format():
			c.convert(img.get_format())
		img.blit_rect(c, Rect2i(0, 0, w, h), Vector2i((i % cols) * (w + 6), (i / cols) * (h + 6)))
	return img


func _contact() -> void:
	if tiles.is_empty():
		return
	var cols := 6
	var w := 320
	var h := 0
	for t in tiles:
		h = maxi(h, t.get_height())
	var rows := int(ceil(tiles.size() / float(cols)))
	var img := Image.create(cols * w, rows * h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.05, 0.05, 0.06))
	for i in tiles.size():
		var t := tiles[i]
		t.convert(Image.FORMAT_RGBA8)
		img.blit_rect(t, Rect2i(0, 0, t.get_width(), t.get_height()), Vector2i((i % cols) * w, (i / cols) * h))
	img.save_png(out.path_join("contact_sheet.png"))
