extends SceneTree
## R3-EARTH-LINK EL5 (design r3/earth-link.md EL5, AC11): the comms station and the galaxy map at the
## design's five states, from the real sim at protocol 2.16 (free_nav, a consent crew aboard), to
## renders/earth_link/<state>_{station,map}.png and a contact sheet:
##   a_outbound  outbound to Alpha Centauri at 0.99c, in beam                         rate RS-26 0.070888
##   b_top       outbound at the top speed (beta 0.999999), Earth near still          rate RS-28 7.0711e-4
##   c_replan    at a port 40 ly out, planning a 30 ly turn at right angles: the preview's wait, 60 yr (RS-33)
##   d_stale     on that leg: out of beam, Earth still aiming at the port the ship left (a stale beam)
##   e_home      heading home at 0.99c                                               rate RS-29 14.107
## Each frame asserts its state from the sim, that it is not blank, that no two frames are alike, and
## that every number on the station and on the map's beams is a binding (DisplayBinding.audit).
## Run:  make capture-earth-link  (needs a GPU window; open every frame and the contact sheet)

const OUT := "res://renders/earth_link"
const RES := Vector2i(1280, 720)
const ALPHA := {"index": 1, "id": "CNS5:3627", "pos": {"x": 3.094521, "y": -3.015404, "z": -0.051608}}
const SOL := {"index": 0, "id": "Sol", "pos": {"x": 0.0, "y": 0.0, "z": 0.0}}
const PORT_A := {"index": 0, "id": "port A (40 ly)", "pos": {"x": 40.0, "y": 0.0, "z": 0.0}}
const PORT_B := {"index": 0, "id": "port B (a 30 ly turn)", "pos": {"x": 40.0, "y": 30.0, "z": 0.0}}
const FAR := {"index": 0, "id": "waypoint C (60 ly)", "pos": {"x": -20.0, "y": -56.0, "z": 8.0}}
const PHI_99 := 2.6466524123622457 # atanh(0.99)
const PHI_TOP := 7.2543286 # just under the sim's cap atanh(1 - 1e-6) = 7.25432862 (D-15); beta 0.999999
const STEP := 0.02 # ship years per tick

var failures := 0
var frames := 0
var sim: SimBridge
var map: GalaxyMap
var station: CommsStation
var vp_map: SubViewport
var vp_station: SubViewport
var hashes := {}
var sheet: Array = [] # [label, station image, map image]


func _initialize() -> void:
	_run.call_deferred()


func fail(why: String) -> void:
	failures += 1
	print("earth-link-capture: FAIL %s" % why)


func journey() -> Dictionary:
	return sim.world.get("journey", {}) if sim.world.get("journey") is Dictionary else {}


func earth() -> Dictionary:
	return sim.world.get("earth", {}) if sim.world.get("earth") is Dictionary else {}


func plan(t: Dictionary, phi: float) -> bool:
	return sim.send([{"k": "plan", "target": t, "cruise_phi": phi}], 0.0) and str(journey().get("state", "")) == "planned"


func commit() -> bool:
	return sim.send([{"k": "commit", "plan_id": int(journey().get("plan_id", 0))}], 0.0) and str(journey().get("state", "")) == "committed"


func until(pred: Callable, cap := 40000) -> bool:
	for i in cap:
		if pred.call():
			return true
		if not sim.send([], STEP):
			return false
	return pred.call()


func arrived() -> bool:
	return str(journey().get("state", "")) == "arrived"


func cruising() -> bool:
	return str(sim.world.get("ship", {}).get("phase", "")) == "cruising"


## Halfway through the newest leg in galaxy time (the sim's sent_t and arrive_t).
func mid_leg() -> bool:
	var ms: Array = earth().get("messages", [])
	return not ms.is_empty() and float(sim.world.clock.t) >= 0.5 * (float(ms[-1].sent_t) + float(ms[-1].arrive_t))


func new_session() -> bool:
	if sim != null:
		sim.stop()
	sim = SimBridge.new()
	sim.want_minor = SimBridge.EARTH_MINOR
	if not (sim.start() and sim.new_game(7, "free_nav", false, {}, "", "consent")):
		fail("the sim did not start: %s" % sim.last_error)
		return false
	map.attach(sim)
	return true


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	root.size = RES
	vp_map = SubViewport.new()
	vp_map.size = RES
	vp_map.own_world_3d = true
	vp_map.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp_map)
	map = GalaxyMap.new()
	map.auto_tick = false
	map.show_hint = false
	vp_map.add_child(map)
	map.load_catalogue("res://data/starmap/stars.json")
	vp_station = SubViewport.new()
	vp_station.size = RES
	vp_station.size_2d_override = Vector2i(960, 540)
	vp_station.size_2d_override_stretch = true
	vp_station.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp_station)
	var bg := ColorRect.new()
	bg.color = StapledonTheme.INK
	bg.size = Vector2(960, 540)
	vp_station.add_child(bg)
	var margin := MarginContainer.new()
	margin.size = Vector2(960, 540)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	vp_station.add_child(margin)
	station = CommsStation.new()
	margin.add_child(station)

	var ok := new_session() and plan(ALPHA, PHI_99) and commit() and until(cruising) and until(func() -> bool: return float(earth().get("light_age_years", 0.0)) > 1.0)
	if ok: await shoot("a_outbound", func() -> String: return expect_rate(0.070888, 2e-3) + expect(earth().get("in_beam") == true, "in beam"))
	ok = ok and new_session() and plan(FAR, PHI_TOP) and commit() and until(cruising) and until(mid_leg)
	if ok: await shoot("b_top", func() -> String: return expect_rate(7.0711e-4, 2e-3))
	ok = ok and new_session() and plan(PORT_A, PHI_99) and commit() and until(arrived) and plan(PORT_B, PHI_99)
	if ok: await shoot("c_replan", func() -> String:
		var p: Variant = earth().get("preview")
		return expect(p is Dictionary and absf(float(p.wait_years) - 60.0) < 1.0, "the preview's wait is about 60 yr (%s)" % [p.get("wait_years") if p is Dictionary else p]))
	ok = ok and commit() and until(mid_leg)
	if ok: await shoot("d_stale", func() -> String:
		return expect(earth().get("in_beam") == false, "out of beam") + expect(not (earth().get("stale", []) as Array).is_empty(), "a stale beam") + expect(earth().get("window") is Dictionary and float(earth().window.wait_years) > 50.0, "the wait at B"))
	ok = ok and until(arrived) and plan(SOL, PHI_99) and commit() and until(cruising) and until(mid_leg)
	if ok: await shoot("e_home", func() -> String: return expect_rate(14.107, 2e-3) + expect(not (earth().get("pending", []) as Array).is_empty() or earth().get("beam") is Dictionary, "the plan home on its way, or heard"))
	if not ok:
		fail("the voyage stopped: %s %s %s" % [sim.last_error, sim.last_refused, journey().get("state", "")])
	sim.stop()
	_contact_sheet()
	print("earth-link-capture: %d frames, %d failures" % [frames, failures])
	quit(1 if failures else 0)


func expect(cond: bool, what: String) -> String:
	return "" if cond else what + "; "


func expect_rate(want: float, rel: float) -> String:
	var r := float(earth().get("rate", 0.0))
	return "" if absf(r / want - 1.0) <= rel else "rate %s, want %s; " % [r, want]


func shoot(label: String, state_check: Callable) -> void:
	var bad := str(state_check.call())
	if not bad.is_empty():
		fail("%s: %s" % [label, bad])
	var view := sim.world.duplicate(true)
	map.refresh()
	map.fit_journey()
	var pts := PackedVector3Array([Vector3.ZERO]) # Sol in every frame: where the beams start
	pts.append_array(map.route_points())
	map._frame_points(pts)
	station.feed.begin_visit()
	station.refresh(view)
	for i in 4:
		station.advance(1.0 / 30.0)
		await process_frame
	await RenderingServer.frame_post_draw
	var imgs := []
	for pair: Array in [["station", vp_station], ["map", vp_map]]:
		var img: Image = (pair[1] as SubViewport).get_texture().get_image()
		var path := "%s/%s_%s.png" % [OUT, label, pair[0]]
		img.save_png(ProjectSettings.globalize_path(path))
		var h := str(hash(img.get_data()))
		if hashes.has(h):
			fail("%s %s duplicates %s" % [label, pair[0], hashes[h]])
		hashes[h] = "%s %s" % [label, pair[0]]
		if _spread(img) < 0.02:
			fail("%s %s is blank" % [label, pair[0]])
		imgs.append(img)
		frames += 1
	for pair: Array in [["station", station], ["map beams", map.earth_beams]]:
		var unbound := DisplayBinding.audit(pair[1])
		if not unbound.is_empty():
			fail("%s %s has unbound numbers %s" % [label, pair[0], unbound])
	sheet.append([label, imgs[0], imgs[1]])
	var e := earth()
	print("earth-link-capture: ok %s rate %s in_beam %s out %s beams %s labels %s" % [label, e.get("rate"), e.get("in_beam"),
		(e.get("out") as Dictionary).get("reason") if e.get("out") is Dictionary else "-",
		map.earth_beams.elements.map(func(el: Dictionary) -> String: return el.kind),
		map.earth_beams.get_children().filter(func(n: Node) -> bool: return n is Label and (n as Label).visible).map(func(n: Node) -> String: return (n as Label).text)])


## Every state's station and map side by side, half size, one row per state.
func _contact_sheet() -> void:
	if sheet.is_empty():
		return
	var cell := Vector2i(RES.x / 2, RES.y / 2)
	var out := Image.create(cell.x * 2, cell.y * sheet.size(), false, Image.FORMAT_RGBA8)
	for i in sheet.size():
		for j in 2:
			var img: Image = (sheet[i][1 + j] as Image).duplicate()
			img.convert(Image.FORMAT_RGBA8)
			img.resize(cell.x, cell.y, Image.INTERPOLATE_LANCZOS)
			out.blit_rect(img, Rect2i(Vector2i.ZERO, cell), Vector2i(j * cell.x, i * cell.y))
	out.save_png(ProjectSettings.globalize_path(OUT + "/contact_sheet.png"))


func _spread(img: Image) -> float:
	var lo := 1.0
	var hi := 0.0
	for y in range(0, img.get_height(), 24):
		for x in range(0, img.get_width(), 24):
			var l := img.get_pixel(x, y).get_luminance()
			lo = minf(lo, l)
			hi = maxf(hi, l)
	return hi - lo
