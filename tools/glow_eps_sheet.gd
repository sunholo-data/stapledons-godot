extends RefCounted
## The wall-efficiency comparison sheet (D-29 follow-up; make glow-eps-sheet -> renders/glow/; needs a
## GPU window). Sim-driven: for each cruise speed the galaxy map commits a real voyage (Sol <->
## alpha Cen A) and the frame is taken mid-cruise from the sim's state. For each candidate eps the
## sim's glow pole is scaled by eps / eps_sim (luminance is linear in eps; the temperature, D-30,
## does not depend on it), and two views are drawn through the real exposure (eye mode, the
## centre-weighted meter that sees the glow):
##   * the bridge interior (the bundle's panorama camera, plates composited), and
##   * the forward sky: the sky camera turned to the direction of travel, FWD_FOV wide.
## Row "off" is the glow switched off (pole 0), the reference the others are judged against.
## Measured per cell (glow_eps_sheet.json):
##   pole_dark   glow luminance at the pole / the 23.5 mag/arcsec^2 dark sky
##   ev, dev     the eye's EV in the forward view, and its rise over "off" (adaptation)
##   lim_pole, lim_ring  Crumey limiting magnitude against dark sky + glow at the pole and on the
##               starbow ring (D = 1)
##   vis, red, blue  catalogue stars visible in the forward view (seen illuminance above both the
##               Crumey threshold against the local background and the display threshold at the
##               eye's EV), and those Doppler-reddened (D < 0.8) and blued (D > 1.25)
##   cmb         the CMB disc's pole luminance / the glow's pole luminance

const DT := 1.0 / 20.0
const FINE_DTAU := 2e-7
const ALPHA_CEN_A := "CNS5:3627"
const FWD_FOV := 60.0
const EPS := [0.0, 1e-11, 3e-11, 1e-10, 3e-10]
## [label, rapidity source]: beta, or 1 - beta for the last two
const SPEEDS := [["0.99c", 0.99], ["0.995c", 0.995], ["0.999c", 0.999], ["0.9999c", -1e-4], ["cap", -1e-6]]
const CELL := Vector2i(640, 360)
const FWD := Vector2i(360, 360)

var main: Node
var it: Interior
var map: GalaxyMap
var out := ""
var cells := {} # "speed|eps" -> {interior: Image, fwd: Image, m: Dictionary}
var rows := []


func run(m: Node, interior: Interior, galaxy_map: GalaxyMap, dir: String) -> int:
	main = m
	it = interior
	map = galaxy_map
	out = dir
	var sim: SimBridge = main.sim
	var home := true
	for sp: Array in SPEEDS:
		var src: float = sp[1]
		var phi := atanh(src) if src > 0.0 else 0.5 * (log(2.0 + src) - log(-src))
		it.open_map()
		if home:
			map.preselect(map.index_of(ALPHA_CEN_A))
		else:
			map.plan_target({"index": 0, "id": "Sol", "pos": {"x": 0.0, "y": 0.0, "z": 0.0}})
		map.set_cruise_phi(phi)
		if home:
			map.preselect(map.index_of(ALPHA_CEN_A))
		else:
			map.plan_target({"index": 0, "id": "Sol", "pos": {"x": 0.0, "y": 0.0, "z": 0.0}})
		it.tick()
		if not map.open_commit_dialog():
			push_error("eps sheet: no plan at %s (%s)" % [sp[0], sim.last_refused])
			return 2
		var id := map.dialog_plan_id
		map.close_commit_dialog()
		sim.send([{"k": "commit", "plan_id": id}], FINE_DTAU)
		map.refresh()
		it.close_map()
		var distance: float = sim.world["journey"]["plan"]["distance"]
		while sim.world["ship"]["phase"] != "cruising" and sim.send([], FINE_DTAU):
			pass
		while map.journey_state() == "committed" and float(sim.world["ship"]["flown"]) < 0.4 * distance:
			it.tick()
		print("eps sheet: %s cruising beta %.9f gamma %.3f pole %s W/m^2 at %.1f K (sim eps %s)" % [sp[0], sim.world["ship"]["beta"], sim.world["ship"]["gamma"],
			String.num_scientific(ForwardGlow.pole_of(sim.world)), ForwardGlow.temperature_of(sim.world), sim.world["params"]["glow_eps"]])
		for e: float in EPS:
			await _cell(sp[0], e)
		while map.journey_state() == "committed":
			it.tick()
		home = not home
	it.glow_eps_scale = 1.0
	await _sheet()
	var f := FileAccess.open(out.path_join("glow_eps_sheet.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"eps": EPS, "speeds": SPEEDS.map(func(s: Array) -> String: return s[0]), "cells": rows}, "  ") + "\n")
	f.close()
	sim.stop()
	return 0


func _cell(speed: String, eps: float) -> void:
	var sim: SimBridge = main.sim
	var eps_sim: float = sim.world["params"]["glow_eps"]
	it.glow_eps_scale = eps / eps_sim if eps > 0.0 else 0.0
	var label := "eps %s" % (String.num_scientific(eps) if eps > 0.0 else "off")
	it.caption = "%s  %s (PREVIEW: sim pole x eps/eps_sim)" % [speed, label]
	it.apply_state(sim.world)
	var interior := await _grab()
	# forward view: the sky camera along the direction of travel, the eye meter re-run on it
	var sky := it.sky
	var fov0 := sky.view_fov
	var dirw := sky.heading_world
	var up := Vector3(0, 1, 0) if absf(dirw.y) < 0.9 else Vector3(1, 0, 0)
	var e3 := InteriorSky.euler_of(PackedFloat64Array([dirw.x, dirw.y, dirw.z]), PackedFloat64Array([up.x, up.y, up.z]))
	sky.view_fov = FWD_FOV
	sky.camera.fov = FWD_FOV
	sky.configure_pixel()
	sky.camera.look(e3[0], e3[1], e3[2])
	sky.update_exposure()
	var fwd := await _sky_grab()
	var side := mini(fwd.get_width(), fwd.get_height())
	fwd = fwd.get_region(Rect2i((fwd.get_width() - side) / 2, (fwd.get_height() - side) / 2, side, side))
	var m := _measure(speed, eps)
	sky.view_fov = fov0
	sky.camera.fov = fov0
	sky.configure_pixel()
	it.apply_state(sim.world)
	cells["%s|%s" % [speed, eps]] = {"interior": interior, "fwd": fwd, "m": m}
	var stem := "%s_eps_%s" % [speed.replace(".", "p"), String.num_scientific(eps) if eps > 0.0 else "off"]
	DirAccess.make_dir_recursive_absolute(out.path_join("cells"))
	interior.save_png(out.path_join("cells/%s_interior.png" % stem))
	fwd.save_png(out.path_join("cells/%s_forward.png" % stem))
	rows.append(m)
	print("eps sheet cell %s" % JSON.stringify(m))


func _measure(speed: String, eps: float) -> Dictionary:
	var sky := it.sky
	var sim: SimBridge = main.sim
	var s: Dictionary = sim.world["ship"]
	var b: float = s["beta"]
	var dirw := sky.heading_world
	var l_dark := Exposure.dark_sky_luminance()
	var pole_l := sky.glow_luminance(dirw)
	# the starbow ring: D = 1 at cos theta' = (1 - 1/gamma) / beta (apparent angle from the pole)
	var g: float = s["gamma"]
	var ct_ring := clampf((1.0 - 1.0 / g) / b, -1.0, 1.0)
	var perp := dirw.cross(Vector3(0, 1, 0) if absf(dirw.y) < 0.9 else Vector3(1, 0, 0)).normalized()
	var ring_dir := (dirw * ct_ring + perp * sqrt(maxf(0.0, 1.0 - ct_ring * ct_ring))).normalized()
	var ring_l := sky.glow_luminance(ring_dir)
	var ev := sky.exposure.ev
	var disp_thr := Exposure.threshold_lux() * pow(2.0, ev - sky.exposure.ev_dark())
	var sf := sky.starfield
	var vis := 0
	var red := 0
	var blue := 0
	var brightest := INF
	var cos_half := cos(deg_to_rad(FWD_FOV * 0.5))
	for k in sf.count:
		var n := Vector3(sf.pos[3 * k] - sf.ship[0], sf.pos[3 * k + 1] - sf.ship[1], sf.pos[3 * k + 2] - sf.ship[2]).normalized()
		var na := Relativity.aberrate(n, dirw, b)
		if na.dot(dirw) < cos_half:
			continue
		var t: float = sf.custom[4 * k]
		var e_seen := SkyMeter.seen_point(sf.flux_at_ship(k), t, n, dirw, b)
		var thr := maxf(Exposure.FIELD_FACTOR * Relativity.point_threshold_illuminance(l_dark + sky.glow_luminance(na)), disp_thr)
		if e_seen < thr:
			continue
		vis += 1
		brightest = minf(brightest, Relativity.v_from_illuminance(e_seen))
		var d := Relativity.doppler(n, dirw, b)
		if d < 0.8:
			red += 1
		elif d > 1.25:
			blue += 1
	var omb: float = s.get("one_minus_beta", 1.0 - b)
	var cmb_l := Blackbody.photopic_radiance(Relativity.cmb_temperature_apparent(0.0, omb))
	return {"speed": speed, "eps": eps, "beta": b, "gamma": g, "pole_k": sky.glow_t_pole, "pole_w_m2": sky.glow_pole,
		"pole_cd_m2": pole_l, "pole_dark": pole_l / l_dark, "ring_deg": rad_to_deg(acos(ct_ring)), "ring_dark": ring_l / l_dark,
		"ev": ev, "ev_dark": sky.exposure.ev_dark(),
		"lim_pole": Relativity.limiting_magnitude(l_dark + pole_l, Exposure.FIELD_FACTOR),
		"lim_ring": Relativity.limiting_magnitude(l_dark + ring_l, Exposure.FIELD_FACTOR),
		"vis": vis, "red": red, "blue": blue, "brightest_v": brightest if vis > 0 else null,
		"cmb_cd_m2": cmb_l, "cmb_over_glow": cmb_l / pole_l if pole_l > 0.0 else null}


func _grab() -> Image:
	for i in 4:
		await main.get_tree().process_frame
	await RenderingServer.frame_post_draw
	return main.get_viewport().get_texture().get_image()


func _sky_grab() -> Image:
	for i in 4:
		await main.get_tree().process_frame
	await RenderingServer.frame_post_draw
	return it.sky.get_texture().get_image()


## The sheet: one row per eps, one column per speed; each cell the interior and the forward view
## with its numbers, drawn through Godot's own UI (labels) in an offscreen viewport.
func _sheet() -> void:
	var cols := SPEEDS.size()
	var cw := CELL.x + FWD.x + 8
	var ch := CELL.y + 70
	var head := 60
	var vp := SubViewport.new()
	vp.size = Vector2i(140 + cols * cw, head + EPS.size() * ch)
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.08, 0.09)
	bg.size = Vector2(vp.size)
	vp.add_child(bg)
	var title := _label("Forward glow vs wall efficiency eps (D-29 follow-up). Blackbody spectrum (D-30), sunholo/relativity 0.8.0. Real sim cruise state; eye exposure (centre-weighted meter sees the glow). Left: bridge interior. Right: forward sky, %d deg, centred on the direction of travel." % int(FWD_FOV), 18)
	title.position = Vector2(12, 8)
	vp.add_child(title)
	for j in cols:
		var l := _label(SPEEDS[j][0], 22)
		l.position = Vector2(140 + j * cw + 8, 32)
		vp.add_child(l)
	for i in EPS.size():
		var e: float = EPS[i]
		var rl := _label("eps\n%s" % (String.num_scientific(e) if e > 0.0 else "off"), 22)
		rl.position = Vector2(12, head + i * ch + CELL.y / 2 - 20)
		vp.add_child(rl)
		for j in cols:
			var c: Dictionary = cells.get("%s|%s" % [SPEEDS[j][0], e], {})
			if c.is_empty():
				continue
			var x := 140 + j * cw
			var y := head + i * ch
			_tex(vp, c["interior"], Vector2(x, y), Vector2(CELL))
			_tex(vp, c["fwd"], Vector2(x + CELL.x + 4, y), Vector2(FWD))
			var m: Dictionary = c["m"]
			var off: Dictionary = cells.get("%s|%s" % [SPEEDS[j][0], 0.0], c)["m"]
			var txt := "T_pole %.0f K   glow pole %s x dark sky   EV %+.2f (%+.2f vs off)\nlim mag pole %.2f, ring (%.0f deg) %.2f   stars %d = %.0f%% of off (blue %d, red %d)%s" % [
				m["pole_k"], _sig(m["pole_dark"]) if e > 0.0 else "0", m["ev"], m["ev"] - off["ev"], m["lim_pole"], m["ring_deg"], m["lim_ring"],
				m["vis"], 100.0 * m["vis"] / maxf(off["vis"], 1.0), m["blue"], m["red"], ("   CMB disc / glow %s" % _sig(m["cmb_over_glow"])) if m["cmb_over_glow"] != null and m["cmb_cd_m2"] > 1.0 else ""]
			var tl := _label(txt, 14)
			tl.position = Vector2(x, y + CELL.y + 4)
			vp.add_child(tl)
	main.add_child(vp)
	for k in 4:
		await main.get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := vp.get_texture().get_image()
	img.save_png(out.path_join("eps_compare.png"))
	img.save_jpg(out.path_join("eps_compare.jpg"), 0.88)
	vp.queue_free()


## 3 significant figures, plain or scientific.
static func _sig(x: float) -> String:
	if x == 0.0:
		return "0"
	var p := floori(log(absf(x)) / log(10.0))
	if p >= -2 and p < 5:
		return ("%." + str(maxi(0, 2 - p)) + "f") % x
	return "%.2fe%d" % [x / pow(10.0, p), p]


func _label(t: String, size: int) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color(0.92, 0.92, 0.9))
	return l


func _tex(vp: SubViewport, img: Image, pos: Vector2, sz: Vector2) -> void:
	var r := TextureRect.new()
	var im := img.duplicate()
	im.convert(Image.FORMAT_RGBA8)
	im.resize(int(sz.x), int(sz.y), Image.INTERPOLATE_LANCZOS)
	r.texture = ImageTexture.create_from_image(im)
	r.position = pos
	r.size = sz
	vp.add_child(r)
