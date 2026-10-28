extends SceneTree
## SPIKE (scratch, never merged): Earth's-fate reference skies, rendered by the game's own sky
## (InteriorSky: destarred NOIRLab Milky Way + large-tier GCNS catalogue, EYE exposure, AgX) and,
## for the captured scene, the Schwarzschild lens (GrLens on the sim's protocol-2.6 gr section).
## Usage: godot --path <clone> --script res://tools/fate_tmp/fate_sky.gd -- <scenes.json> <outdir> [scene]
## Writes <outdir>/<scene>_sky.png (linear-free, display-ready sRGB as the game shows it) and
## <outdir>/<scene>_meta.json (camera, pixel positions of the hole / Sun / comets, numbers used).

const AU_LY := 1.0 / 63241.077 # 1 AU in ly (IAU: 1 ly = 63241.077 AU)
const RS_KM_PER_MSUN := 2.953250 # 2 G M_sun / c^2 in km (cross-checked against the sim's rs_m below)
const SUN_V_1AU := -26.74 # V of the Sun at 1 AU
const SUN_T := 5772.0
const SUN_R_KM := 695700.0
const AU_KM := 149597870.7
## Equatorial (ICRS) -> galactic: rows of sunholo/celestial frames.equatorialToGalactic.
const EQ_GAL := [[-0.0548755604, -0.8734370902, -0.4838350155], [0.4941094279, -0.4448296300, 0.7469822445], [-0.8676661490, -0.1980763734, 0.4559837762]]

var cfg := {}
var out_dir := ""
var sky: InteriorSky
var size := Vector2i(1536, 1024)
var lat := 0.0
var lst := 0.0
var meta := {}
var atmo := MeshInstance3D.new()
var atmo_mat := ShaderMaterial.new()


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	cfg = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	out_dir = args[1]
	var only: String = args[2]
	size = Vector2i(int(cfg.size[0]), int(cfg.size[1]))
	root.size = size
	if not Schwarzschild.load_tables():
		print("fate-sky: FAIL lens tables %s" % Schwarzschild.load_error)
		quit(1)
		return
	sky = InteriorSky.new()
	root.add_child(sky)
	var vfov := vfov_deg()
	sky.setup({"forward": [0.0, 0.0, -1.0], "up": [0.0, 1.0, 0.0], "position_m": [0.0, 0.0, 0.0]}, vfov, size,
		{"tier": "large", "planet_textures": false, "planet_preload": false, "planet_smooth_lod": false})
	var shown := TextureRect.new()
	shown.texture = sky.get_texture()
	root.add_child(shown)
	print("fate-sky: stars %d tiers %s" % [sky.starfield.count, sky.starfield.tiers])
	atmo_mat.shader = load("res://tools/fate_tmp/fate_atmo.gdshader")
	var q := QuadMesh.new()
	q.size = Vector2(2.0, 2.0)
	atmo.mesh = q
	atmo.material_override = atmo_mat
	atmo.extra_cull_margin = 16384.0
	atmo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sky.add_child(atmo)
	# one scene per process (a scene appends the Sun to the catalogue)
	await _scene(only, cfg.scenes[only])
	print("fate-sky: OK")
	quit(0)


func vfov_deg() -> float:
	var h := deg_to_rad(float(cfg.hfov_deg))
	return rad_to_deg(2.0 * atan(tan(0.5 * h) * float(size.y) / float(size.x)))


## Local horizontal (alt, az from north through east; degrees) -> equatorial unit vector.
func eq_of_altaz(alt_deg: float, az_deg: float) -> PackedFloat64Array:
	var a := deg_to_rad(alt_deg)
	var A := deg_to_rad(az_deg)
	var p := deg_to_rad(lat)
	var t := lst
	var Z := [cos(p) * cos(t), cos(p) * sin(t), sin(p)]
	var E := [-sin(t), cos(t), 0.0]
	var N := [-sin(p) * cos(t), -sin(p) * sin(t), cos(p)]
	var out := PackedFloat64Array()
	for i in 3:
		out.append(cos(a) * (cos(A) * N[i] + sin(A) * E[i]) + sin(a) * Z[i])
	return out


func altaz_of_eq(v: PackedFloat64Array) -> PackedFloat64Array:
	var p := deg_to_rad(lat)
	var t := lst
	var Z := [cos(p) * cos(t), cos(p) * sin(t), sin(p)]
	var E := [-sin(t), cos(t), 0.0]
	var N := [-sin(p) * cos(t), -sin(p) * sin(t), cos(p)]
	var z: float = v[0] * Z[0] + v[1] * Z[1] + v[2] * Z[2]
	var e: float = v[0] * E[0] + v[1] * E[1] + v[2] * E[2]
	var n: float = v[0] * N[0] + v[1] * N[1] + v[2] * N[2]
	return PackedFloat64Array([rad_to_deg(asin(clampf(z, -1.0, 1.0))), fposmod(rad_to_deg(atan2(e, n)), 360.0)])


func gal_of_eq(v: PackedFloat64Array) -> PackedFloat64Array:
	var out := PackedFloat64Array()
	for r in 3:
		out.append(EQ_GAL[r][0] * v[0] + EQ_GAL[r][1] * v[1] + EQ_GAL[r][2] * v[2])
	return out


func eq_of_gal(g: PackedFloat64Array) -> PackedFloat64Array:
	var out := PackedFloat64Array()
	for c in 3:
		out.append(EQ_GAL[0][c] * g[0] + EQ_GAL[1][c] * g[1] + EQ_GAL[2][c] * g[2])
	return out


func world_of_altaz(alt: float, az: float) -> PackedFloat64Array:
	return SkyFrame.to_world64(gal_of_eq(eq_of_altaz(alt, az)))


func gal_of_altaz(alt: float, az: float) -> PackedFloat64Array:
	return gal_of_eq(eq_of_altaz(alt, az))


func altaz_of_world(w: PackedFloat64Array) -> PackedFloat64Array:
	return altaz_of_eq(eq_of_gal(SkyFrame.to_galactic64(w)))


static func v3(a: PackedFloat64Array) -> Vector3:
	return Vector3(a[0], a[1], a[2])


## Pitch (deg, + up) that puts altitude 0 on the painting's horizon row (pinhole, vertical fov).
func pitch_for_row(row: float) -> float:
	var f := 0.5 * float(size.y) / tan(deg_to_rad(vfov_deg()) * 0.5)
	return rad_to_deg(atan((row - 0.5 * float(size.y)) / f))


func px_of_world(w: PackedFloat64Array) -> Array:
	var n := v3(w).normalized()
	if sky.camera.is_behind(n):
		return []
	var p := sky.camera.project(n, Vector2(size))
	return [p.x, p.y]


func _scene(name: String, s: Dictionary) -> void:
	lat = float(s.get("lat_deg", cfg.lat_deg))
	lst = deg_to_rad(float(s.get("lst_h", 18.0)) * 15.0)
	if s.has("sun") and s.sun.has("ra_h"):
		var ra := deg_to_rad(float(s.sun.ra_h) * 15.0)
		var de := deg_to_rad(float(s.sun.dec_deg))
		var aa0 := altaz_of_eq(PackedFloat64Array([cos(de) * cos(ra), cos(de) * sin(ra), sin(de)]))
		s.sun["alt"] = aa0[0]
		s.sun["az"] = aa0[1]
	var row := float(s.get("horizon_row", 512.0)) + float(cfg.get("dip_px", 0.0))
	var pitch := pitch_for_row(row)
	var az := float(s.get("view_az", cfg.view_az))
	var f := world_of_altaz(pitch, az)
	var u := world_of_altaz(pitch + 90.0, az) if pitch <= 0.0 else world_of_altaz(90.0 - pitch, az + 180.0)
	var e := InteriorSky.euler_of(f, u)
	sky.camera.fov = vfov_deg()
	sky.view_fov = vfov_deg()
	sky.configure_pixel()
	sky.background.material.set_shader_parameter("screen_px_rad", deg_to_rad(vfov_deg()) / size.y)
	sky.camera.look(e[0], e[1], e[2])
	sky.eye_meter = SkyMeter.new()
	sky.exposure.bias = float(s.get("bias_ev", 0.0))
	sky.exposure.fixed = false
	meta = {"scene": name, "size": [size.x, size.y], "hfov_deg": cfg.hfov_deg, "vfov_deg": vfov_deg(),
		"pitch_deg": pitch, "view_az_deg": az, "lat_deg": lat, "lst_h": float(s.get("lst_h", 18.0)), "horizon_row": row}
	meta["horizon_check_px"] = px_of_world(world_of_altaz(0.0, az))
	meta["top_alt_deg"] = pitch + 0.5 * vfov_deg()
	# the observer's position relative to the Sun (world ly) and the Sun as a catalogue point
	var ship := PackedFloat64Array([0.0, 0.0, 0.0])
	if s.has("sun") and float(s.sun.get("dist_au", 1.0)) > 2.0:
		var sd := world_of_altaz(float(s.sun.alt), float(s.sun.az))
		var d_au := float(s.sun.dist_au)
		for i in 3:
			ship[i] = -sd[i] * d_au * AU_LY
		var v := SUN_V_1AU + 5.0 * log(d_au) / log(10.0)
		var lux := Relativity.illuminance_from_v(v)
		# far along the Sun's direction, flux given at the origin = at the ship to 1e-5
		var p := PackedFloat64Array()
		for i in 3:
			p.append(ship[i] + sd[i] * 1000.0)
		var scale := (1000.0 * 1000.0) / (p[0] * p[0] + p[1] * p[1] + p[2] * p[2]) # flux at ship = lux
		sky.starfield.append_stars([{"pos": [p[0], p[1], p[2]], "t": SUN_T, "flux": lux / scale, "id": "Sun"}])
		meta["sun"] = {"alt": s.sun.alt, "az": s.sun.az, "dist_au": d_au, "V": v, "lux": lux, "px": px_of_world(sd)}
	sky.starfield.set_ship_position(ship[0], ship[1], ship[2])
	meta["observer_from_sun_ly"] = [ship[0], ship[1], ship[2]]
	# black hole
	var gr := {}
	if s.has("gr"):
		var g: Dictionary = s.gr
		var hole_gal := gal_of_altaz(float(g.alt), float(g.az)) if g.has("alt") else gal_of_lb(float(g.l), float(g.b))
		var hw := SkyFrame.to_world64(hole_gal)
		var aa := altaz_of_world(hw)
		var mass := float(g.mass_msun)
		var rs_km := RS_KM_PER_MSUN * mass
		var r := float(g.r_km) / rs_km
		if g.src == "sim":
			gr = _sim_gr(mass, r, g.get("orbit", true))
			if gr.is_empty():
				print("fate-sky: FAIL sim gr")
				quit(1)
				return
			meta["sim_gr"] = gr.duplicate(true)
			# orientation is a scene choice: the hole where the scene puts it, the orbital motion
			# perpendicular to it (the sim's scalars r, shadow, blueshift, beta/gamma are kept)
			var perp := _perp_gal(hole_gal)
			gr["hole_dir"] = {"x": hole_gal[0], "y": hole_gal[1], "z": hole_gal[2]}
			gr["dir_local"] = {"x": perp[0], "y": perp[1], "z": perp[2]}
		else:
			gr = GrLens.reference_state(r, hole_gal)
		sky.set_gr(gr)
		sky.gr_lens.refresh_now()
		var a: float = gr["shadow"]
		meta["hole"] = {"mass_msun": mass, "rs_km": rs_km, "r_km": float(g.r_km), "r_rs": r, "alt": aa[0], "az": aa[1],
			"lb": SkyFrame.lb_of_world(hw), "px": px_of_world(hw), "shadow_half_angle_rad": a,
			"shadow_diam_arcsec": rad_to_deg(2.0 * a) * 3600.0, "weak": r > Schwarzschild.R_WEAK,
			"einstein_ring_diam_deg_weakfield": rad_to_deg(2.0 * sqrt(2.0 / r)), "ring_line": sky.gr_lens.debug_line(),
			"ring_cones_rad": [sky.gr_lens.cones[0], sky.gr_lens.cones[1]]}
		meta["hole"]["ring_px_diam"] = rad_to_deg(2.0 * sqrt(2.0 / r)) / float(cfg.hfov_deg) * size.x
	else:
		sky.set_gr({})
	# background (Milky Way) on or off, stars on or off
	sky.background.material.set_shader_parameter("exposure", 1.0)
	sky.starfield.visible = bool(s.get("stars", true))
	sky.update_exposure()
	# Exposure: the game's EYE rule (EV_dark: the threshold star on the display floor) evaluated
	# against the scene's own sky background bg_l (cd/m^2) instead of deep space; or metered (day).
	var bg_l := float(s.get("bg_l", Exposure.dark_sky_luminance()))
	var ev_fix := 0.0
	if s.get("ev_rule", "eye") == "metered":
		ev_fix = Exposure.metered_ev(bg_l)
	else:
		var thr := Exposure.FIELD_FACTOR * Relativity.point_threshold_illuminance(bg_l)
		ev_fix = log(Exposure.peak_luminance(thr, Exposure.psf_sigma_angle()) / Exposure.DISPLAY_FLOOR / Exposure.SAT) / log(2.0)
		meta["lim_mag_scene"] = Relativity.limiting_magnitude(bg_l, Exposure.FIELD_FACTOR)
	ev_fix += float(s.get("bias_ev", 0.0))
	sky.exposure.fixed = true
	sky.exposure.fixed_ev = ev_fix
	sky.update_exposure()
	meta["bg_l_cdm2"] = bg_l
	# the atmosphere overlay (approximate models, fate_atmo.gdshader)
	var am := int(s.get("atmo_mode", 0))
	atmo.visible = am > 0
	atmo_mat.set_shader_parameter("mode", am)
	atmo_mat.set_shader_parameter("zenith", v3(world_of_altaz(90.0, 0.0)))
	atmo_mat.set_shader_parameter("k", sky.exposure.k())
	atmo_mat.set_shader_parameter("l0", float(s.get("atmo_l0", 0.0)))
	if s.has("sun"):
		atmo_mat.set_shader_parameter("sun", v3(world_of_altaz(float(s.sun.alt), float(s.sun.az))))
		var d_km := float(s.sun.dist_au) * AU_KM
		var ar := asin(SUN_R_KM / d_km)
		atmo_mat.set_shader_parameter("sun_r", ar)
		atmo_mat.set_shader_parameter("sun_l", float(s.get("sun_disc_l", 0.0)))
		meta["sun_disc"] = {"angular_diam_deg": rad_to_deg(2.0 * ar), "px_diam": rad_to_deg(2.0 * ar) / float(cfg.hfov_deg) * size.x,
			"px": _px_any(world_of_altaz(float(s.sun.alt), float(s.sun.az))), "V": SUN_V_1AU + 5.0 * log(float(s.sun.dist_au)) / log(10.0)}
	meta["atmo_mode"] = am
	if s.has("sun"):
		meta["sun_altaz"] = [float(s.sun.alt), float(s.sun.az)]
	meta["atmo_l0"] = float(s.get("atmo_l0", 0.0))
	if not bool(s.get("milky_way", true)):
		sky.background.set_exposure(0.0)
	if sky.gr_lens.active:
		sky.gr_lens.set_exposure(sky.exposure.star_scale(), sky.exposure.psf_sigma_rad())
	meta["ev"] = sky.exposure.ev
	meta["ev_dark"] = sky.exposure.ev_dark()
	meta["exposure_line"] = sky.exposure.hud_line()
	meta["lim_mag_dark"] = Relativity.limiting_magnitude(Exposure.dark_sky_luminance(), Exposure.FIELD_FACTOR)
	await _grab("%s/%s_sky.png" % [out_dir, name])
	# optional detail render centred on the hole, narrow fov; a labelled magnified view:
	# EV bias, atmosphere off and a sharper PSF (psf_arcmin) are detail-only choices
	if s.has("detail") and s.has("gr"):
		var dfov := float(s.detail.vfov_deg)
		var hw2 := SkyFrame.to_world64(gal_of_lb(float(meta.hole.lb[0]), float(meta.hole.lb[1])))
		var up := world_of_altaz(90.0, 0.0)
		var e2 := InteriorSky.euler_of(hw2, up)
		sky.camera.fov = dfov
		sky.view_fov = dfov
		sky.configure_pixel()
		sky.background.material.set_shader_parameter("screen_px_rad", deg_to_rad(dfov) / size.y)
		sky.camera.look(e2[0], e2[1], e2[2])
		atmo.visible = not bool(s.detail.get("atmo_off", false))
		for pass_i in 2:
			if pass_i == 1:
				if not s.detail.has("off"):
					break
				sky.set_gr({})
			sky.exposure.fixed = true
			sky.exposure.fixed_ev = float(meta.ev) + float(s.detail.get("bias_ev", 0.0))
			sky.update_exposure()
			var sig := sky.exposure.psf_sigma_rad()
			if s.detail.has("psf_arcmin"):
				sig = deg_to_rad(float(s.detail.psf_arcmin) / 60.0)
				sky.starfield.set_psf(sig / sky.exposure.pixel_rad)
				sky.starfield.set_exposure(sky.exposure.k() / (TAU * sig * sig))
			if sky.gr_lens.active:
				sky.gr_lens.set_exposure(sky.exposure.k() / (TAU * sig * sig), sig)
			atmo_mat.set_shader_parameter("k", sky.exposure.k())
			if pass_i == 0:
				meta["detail"] = {"vfov_deg": dfov, "ev": sky.exposure.ev, "bias_ev": float(s.detail.get("bias_ev", 0.0)),
					"psf_sigma_arcmin": rad_to_deg(sig) * 60.0, "atmo": atmo.visible,
					"ring_px_diam": rad_to_deg(2.0 * sqrt(2.0 / float(meta.hole.r_rs))) / dfov * size.y,
					"shadow_px_diam": float(meta.hole.shadow_diam_arcsec) / 3600.0 / dfov * size.y, "ring_line": sky.gr_lens.debug_line()}
				await _grab("%s/%s_detail_sky.png" % [out_dir, name])
			else:
				await _grab("%s/%s_detail_nolens_sky.png" % [out_dir, name])
	# extra projected points for the compositor: comets with their tail ends (tail_deg along the
	# great circle toward the anti-Sun point), and any other named direction
	var pts := {}
	var anti := PackedFloat64Array()
	if s.has("antisun"):
		anti = world_of_altaz(float(s.antisun.alt), float(s.antisun.az))
	for k: String in s.get("points", {}):
		var pt: Dictionary = s.points[k]
		var w := world_of_altaz(float(pt.alt), float(pt.az))
		pts[k] = {"alt": pt.alt, "az": pt.az, "px": _px_any(w)}
		if pt.has("tail_deg") and anti.size() == 3:
			var a := v3(w)
			var b := v3(anti)
			var ax := a.cross(b).normalized()
			var ends := []
			for frac in [0.25, 0.5, 0.75, 1.0]:
				var t := a.rotated(ax, deg_to_rad(float(pt.tail_deg) * frac))
				ends.append(_px_any(PackedFloat64Array([t.x, t.y, t.z])))
			pts[k]["tail_px"] = ends
	meta["points"] = pts
	meta["cam"] = {"f_px": 0.5 * float(size.y) / tan(deg_to_rad(vfov_deg()) * 0.5), "dip_px": float(cfg.get("dip_px", 0.0))}
	var fw := FileAccess.open("%s/%s_meta.json" % [out_dir, name], FileAccess.WRITE)
	fw.store_string(JSON.stringify(meta, "  "))
	fw.close()
	print("fate-sky: %s pitch %.3f deg ev %.2f %s" % [name, pitch, sky.exposure.ev, sky.gr_lens.debug_line()])


func _px_any(w: PackedFloat64Array) -> Array:
	# projection even when off-screen (for directions in front of the camera)
	return px_of_world(w)


func gal_of_lb(l: float, b: float) -> PackedFloat64Array:
	var L := deg_to_rad(l)
	var B := deg_to_rad(b)
	return PackedFloat64Array([cos(B) * cos(L), cos(B) * sin(L), sin(B)])


func _perp_gal(g: PackedFloat64Array) -> PackedFloat64Array:
	var a := Vector3(0, 0, 1) if absf(g[2]) < 0.9 else Vector3(1, 0, 0)
	var p := v3(g).cross(a).normalized()
	return PackedFloat64Array([p.x, p.y, p.z])


## The sim's gr section for a rogue hole (protocol 2.6 scenario sgr_a with bh_mass_msun, bh_r).
func _sim_gr(mass: float, r: float, orbit: bool) -> Dictionary:
	var sim := SimBridge.new()
	sim.want_minor = SimBridge.GR_MINOR
	if not sim.start() or not sim.new_game(424242, "sgr_a", false, {"bh_mass_msun": mass, "bh_r": r}):
		print("fate-sky: sim refused: %s" % sim.last_error)
		sim.stop()
		return {}
	if orbit:
		if not sim.send([{"k": "gr_orbit"}], 0.0) or not sim.last_refused.is_empty():
			print("fate-sky: gr_orbit refused %s" % [sim.last_refused])
	var g: Dictionary = sim.gr.duplicate(true)
	sim.stop()
	return g


func _grab(path: String) -> void:
	for i in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := sky.get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	if img.save_png(path) != OK:
		print("fate-sky: FAIL save %s" % path)
	else:
		print("fate-sky: wrote %s" % path)
