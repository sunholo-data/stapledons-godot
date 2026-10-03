extends RefCounted
## M4.2 S1 review captures (make capture-m4 -> renders/m4/; needs a GPU window). Sim-driven:
## the play session main.gd started (protocol 2.2, 1,000 AU stand-off); the galaxy map plans
## and commits; the interior is drawn from the sim's state. 1600 x 900.
##   01-04  docked at Sol: the captain at the spawn, walking (back, front), at a nav console
##   05     the navigation console opens the galaxy map (alpha Cen A selected)
##   06-09  committed to alpha Cen A at 0.99c: the boost, the cruise with the captain walking,
##          pans -5 / +5 m (sky fixed, plates at 0.15 / 1.6), a pan past the overscan (clamped)
##   10     glow preview at 0.99c: the pole value is the package probe's (tools/glow_probe),
##          because the sim does not emit ship.ism.glow_pole_w_m2 yet (M4.1 step 2)
##   11     arrived at alpha Cen A
##   12-13  home at the cap (cruise_phi_max): the cruise, and its glow preview
##   14     the four life stages side by side (years forced: a debug view, labelled)
## plus contact_sheet.png and capture_log.json (every frame's sim fields).

const DT := 1.0 / 20.0
const ALPHA_CEN_A := "CNS5:3627"
## tools/glow_probe (sunholo/relativity 0.7.0): glowEmittanceAt(n, phi, 1e-9, 0.5, 1) at 0.99c and the cap.
const PROBE_POLE := {"0.99c": 9.628776871706524e-05, "cap": 1.1250843031053142}

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
	var sim: SimBridge = main.sim
	await _shot("01_rest_spawn", "Docked at Sol. The captain at the spawn (y0, front).")
	var far := it.walk.closest_walkable(it.avatar_pos + Vector3(-4.0, 0.0, -6.0))
	for i in 40:
		it.walk_toward(far, DT)
		it.tick()
	await _shot("02_rest_walk_back", "Docked. Walking up the screen: the back sprite; the plates pan (0.15 / 1.6).")
	var near := it.walk.closest_walkable(it.avatar_pos + Vector3(5.0, 0.0, 5.0))
	for i in 30:
		it.walk_toward(near, DT)
		it.tick()
	await _shot("03_rest_walk_front", "Docked. Walking down the screen: the front sprite.")
	var nav := it.walk.closest_walkable(it.walk.interactables["console_navigation_1"].get_center())
	for i in 600:
		if it.nearest_interactable().begins_with("console_navigation"):
			break
		it.walk_toward(nav, DT)
		it.tick()
	await _shot("04_rest_nav_console", "At the navigation console: the prompt (E).")
	if it.interact() != "map":
		push_error("capture: the console did not open the map")
		return 2
	map.preselect(map.index_of(ALPHA_CEN_A))
	map.frame_star(map.selected_index)
	map.set_cruise_phi(map.phi_default)
	it.tick()
	await _shot("05_map_from_console", "The navigation console opened the galaxy map (alpha Cen A, 0.99c).")
	if not _commit():
		return 2
	it.close_map()
	while sim.world["ship"]["phase"] == "boosting" and sim.world["ship"]["beta"] < 0.9:
		it.tick()
	await _shot("06_b099_boost", "Committed to alpha Cen A: the boost (up = the direction of travel).")
	var distance: float = sim.world["journey"]["plan"]["distance"]
	while map.journey_state() == "committed" and not (sim.world["ship"]["phase"] == "cruising" and sim.world["ship"]["flown"] > 0.4 * distance):
		it.tick()
	var stroll := it.walk.closest_walkable(it.avatar_pos + Vector3(3.0, 0.0, 4.0))
	for i in 25:
		it.walk_toward(stroll, DT)
	await _shot("07_b099_cruise_walk", "Cruise at 0.99c: the captain walks; the sky is the live relativistic sky.")
	var base := it.pan
	for p in [-5.0, 5.0]:
		it.set_pan(base + Vector2(p, 0.0))
		await _shot("08_b099_pan%+d" % int(p), "0.99c, camera pan %+d m: the sky is fixed (at infinity)." % int(p))
	it.set_pan(base + Vector2(12.0, 5.0))
	await _shot("09_b099_pan_clamped", "0.99c, pan (+12, +5) m, beyond the [6, 3] m overscan: the plates clamp, no edge shows.")
	it.set_pan(base)
	await _glow_preview("10_b099_glow_preview", "0.99c")
	while map.journey_state() == "committed":
		it.tick()
	await _shot("11_arrived_acen", "Arrived at alpha Cen A (1,000 AU stand-off).")
	it.open_map()
	map.plan_target({"index": 0, "id": "Sol", "pos": {"x": 0.0, "y": 0.0, "z": 0.0}})
	map.set_cruise_phi(map.phi_max)
	map.plan_target({"index": 0, "id": "Sol", "pos": {"x": 0.0, "y": 0.0, "z": 0.0}})
	it.tick()
	if not _commit():
		return 2
	it.close_map()
	distance = sim.world["journey"]["plan"]["distance"]
	while map.journey_state() == "committed" and not (sim.world["ship"]["phase"] == "cruising" and sim.world["ship"]["flown"] > 0.3 * distance):
		it.tick()
	await _shot("12_cap_cruise", "Home at the cap (1 - beta = 1e-6, gamma 707): the cruise.")
	await _glow_preview("13_cap_glow_preview", "cap")
	var stages := []
	for y in [0.0, 20.0, 40.0, 60.0]:
		it.avatar.set_years(y)
		stages.append(await _grab())
	it.avatar.set_years(float(sim.world["clock"]["tau"]))
	_stage_strip(stages)
	_sheet(tiles, 3, out.path_join("contact_sheet.png"))
	var f := FileAccess.open(out.path_join("capture_log.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"bundle": it.bundle.dir, "version": it.bundle.manifest.get("version", ""), "frames": log_rows}, "  ") + "\n")
	f.close()
	sim.stop()
	return 0


func _commit() -> bool:
	var sim: SimBridge = main.sim
	if not map.open_commit_dialog():
		push_error("capture: no plan to commit (%s %s)" % [sim.last_refused, sim.last_error])
		return false
	map.hold_commit(GalaxyMap.HOLD_S + 0.05)
	it.tick()
	if map.journey_state() != "committed":
		push_error("capture: commit refused (%s)" % sim.last_refused)
		return false
	return true


func _glow_preview(name: String, speed: String) -> void:
	it.glow_preview = PROBE_POLE[speed]
	it.caption = "GLOW PREVIEW %s: pole %s W/m^2 from the package probe (sim field pending, M4.1 step 2)" % [speed, String.num_scientific(PROBE_POLE[speed])]
	await _frame(name)
	it.glow_preview = -1.0


func _shot(name: String, caption: String) -> void:
	it.caption = caption
	await _frame(name)


func _frame(name: String) -> void:
	var sim: SimBridge = main.sim
	it.apply_state(sim.world)
	var img := await _grab()
	img.save_png(out.path_join(name + ".png"))
	tiles.append(img)
	var s: Dictionary = sim.world["ship"]
	var row := {"frame": name, "caption": it.caption, "phase": s["phase"], "beta": s["beta"], "gamma": s["gamma"], "one_minus_beta": s.get("one_minus_beta"),
		"tau": sim.world["clock"]["tau"], "t": sim.world["clock"]["t"], "heading": s["heading"], "glow_pole_w_m2": it.sky.glow_pole, "ev": it.sky.exposure.ev,
		"captain": {"stage": it.avatar.stage, "facing": it.avatar.facing, "pos_play_m": [it.avatar_pos.x, it.avatar_pos.y, it.avatar_pos.z]}, "pan_m": [it.pan.x, it.pan.y],
		"prompt": it.prompt_label.text, "map_open": it.map_open}
	log_rows.append(row)
	print("captured %s  %s beta=%.9f gamma=%.3f tau=%.4f t=%.4f EV %+.2f glow %s captain y%d %s" % [name, s["phase"], s["beta"], s["gamma"], row["tau"], row["t"], it.sky.exposure.ev, it.sky.glow_pole, it.avatar.stage, it.avatar.facing])


func _grab() -> Image:
	for i in 4:
		await main.get_tree().process_frame
	await RenderingServer.frame_post_draw
	return main.get_viewport().get_texture().get_image()


## The captain at the four life stages, cropped around the avatar, side by side.
func _stage_strip(imgs: Array) -> void:
	var cam := it.iso_cam
	var c := cam.unproject_position(it.avatar_pos + Vector3(0, 0.9, 0)) * (Vector2(imgs[0].get_size()) / it.screen)
	var w := 360
	var h := 420
	var strip := Image.create(w * imgs.size(), h, false, Image.FORMAT_RGBA8)
	for i in imgs.size():
		var im: Image = imgs[i]
		im.convert(Image.FORMAT_RGBA8)
		strip.blit_rect(im, Rect2i(int(c.x) - w / 2, int(c.y) - h / 2, w, h), Vector2i(i * w, 0))
	strip.save_png(out.path_join("14_captain_stages_debug.png"))
	tiles.append(strip)


func _sheet(list: Array[Image], cols: int, path: String) -> void:
	var w := 800
	var h := 450
	var rows := int(ceil(list.size() / float(cols)))
	var sheet := Image.create(w * cols, h * rows, false, Image.FORMAT_RGBA8)
	for i in list.size():
		var t: Image = list[i].duplicate()
		t.convert(Image.FORMAT_RGBA8)
		var s := minf(float(w) / t.get_width(), float(h) / t.get_height())
		t.resize(int(t.get_width() * s), int(t.get_height() * s), Image.INTERPOLATE_LANCZOS)
		sheet.blit_rect(t, Rect2i(Vector2i.ZERO, t.get_size()), Vector2i((i % cols) * w, (i / cols) * h))
	sheet.save_png(path)
