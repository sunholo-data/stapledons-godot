extends RefCounted
## R2-STAR-SURFACES goldens (make golden; gate 2; design star-surfaces.md AC4, AC5). main.gd loads this
## by path (tools/ is not exported). Each case draws a star straight ahead, 200 px across in a 1 deg
## view (Camera3D's minimum, so the disc is far-field), linear tonemapper on black, through SystemView
## exactly as the game does, with a protocol-2.13 `surface` record:
##   G-SS-1  a giant (Aldebaran's surface: 3,927 K, log g 1.11, cells 33 across): the integrated
##           illuminance with the map equals e_v_lux to 0.5 % (RS-24 through the GPU: the CPU
##           normaliser N matches what the shader draws).
##   G-SS-2  a spotted red dwarf (TRAPPIST-1's surface): the same, 0.5 %.
##   G-SS-3  a Sun-like star whose spots resolve but cells do not (alpha Cen A's surface): 0.5 %.
##   G-SS-4  the giant's disc (its lit pixels, unweighted) centred within 0.75 px of the camera
##           projection; the light-weighted centroid moves with the cells (reported, not limited).
##   G-SS-5  the Sun with its surface record at 10 px across (nothing resolves) renders byte-identical
##           to the Sun without one: the unresolved path is today's disc bit for bit (AC5).
## Expected values are the body's e_v_lux (the sim's) and the camera projection, never the shader.

const M5 := preload("res://tools/m5_golden.gd")


func run(main: Node) -> int:
	var failures := 0
	var sv := _setup(main)
	failures += await _flux(main, sv, "G-SS-1", _giant(), 3927.0)
	failures += await _flux(main, sv, "G-SS-2", _dwarf(), 2566.0)
	failures += await _flux(main, sv, "G-SS-3", _sunlike(), 5795.0)
	failures += await _centroid(main, sv)
	sv.queue_free()
	sv = _setup(main)
	failures += await _identical(main, sv)
	sv.queue_free()
	main.starfield.clear_point_sources()
	print("star surface golden: %d failures" % failures)
	return failures


func _setup(main: Node) -> SystemView:
	var env: Environment = main.env
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.BLACK
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.glow_enabled = false
	if main.starfield.multimesh == null:
		main.starfield.build()
	main.starfield.set_custom_stars([])
	main.starfield.set_ship_position(0.0, 0.0, 0.0)
	main.starfield.set_velocity(Vector3(0, 0, -1), 0.0, 1.0)
	main.starfield.set_floor(Vector2.ZERO)
	main.camera.look(0.0, 0.0, 0.0)
	main._configure_pixel()
	var sv := SystemView.new()
	sv.setup(main.starfield, false)
	sv.surface_norm_wait = true
	main.add_child(sv)
	return sv


## A star straight ahead (galactic +x = world -Z) at distance d, with a surface record.
static func star(id: String, radius: float, d: float, teff: float, e_v: float, surface: Dictionary) -> Dictionary:
	var b := {"id": id, "name": id, "kind": "star", "host": "", "status": "star",
		"rel_km": {"x": d, "y": 0.0, "z": 0.0}, "radius_km": radius, "flattening": 0.0,
		"pole": {"x": 0.3, "y": 0.2, "z": 0.93}, "w_deg": 0.0,
		"sun_dir": {"x": 0.0, "y": 0.0, "z": 0.0}, "r_au": 0.0, "phase_deg": 0.0,
		"e_v_lux": e_v, "p_v": 0.0, "minnaert_k": 1.0, "ring_id": "", "light_age_s": 0.0, "visitable": false,
		"source": "golden", "teff_k": teff, "limb_u": 0.0}
	if not surface.is_empty():
		b["surface"] = surface
	return b


func _giant() -> Dictionary:
	return {"teff_k": 3927.0, "logg": 1.11, "ld": {"law": "quadratic", "a": 0.955648264, "b": -0.115710464, "source": "claret2011-atlas", "teff_used": 3927.0, "logg_used": 1.11},
		"cell_km": 1848515.1967865576, "sigma_t": 0.03569838559880867, "lifetime_s": 522000.0, "facula_sigma_t": 0.0, "spots": [], "t_emit_s": 1.234e9, "salt": 4242, "corona": false}


func _dwarf() -> Dictionary:
	return {"teff_k": 2566.0, "logg": 5.2387, "ld": {"law": "quadratic", "a": 1.187903, "b": -0.187009, "source": "claret2011-phoenix", "teff_used": 2566.0, "logg_used": 5.0},
		"cell_km": 20.0, "sigma_t": 0.03569838559880867, "lifetime_s": 10.0, "facula_sigma_t": 0.02,
		"spots": [{"lat_deg": 15.0, "lon_deg": 10.0, "radius_rad": 0.2, "umbra_k": 2206.8, "penumbra_k": 2386.4}, {"lat_deg": -20.0, "lon_deg": 330.0, "radius_rad": 0.12, "umbra_k": 2206.8, "penumbra_k": 2386.4}],
		"t_emit_s": 1.234e9, "salt": 77, "corona": true}


func _sunlike() -> Dictionary:
	return {"teff_k": 5795.0, "logg": 4.306, "ld": {"law": "quadratic", "a": 0.4612, "b": 0.2603, "source": "claret2011-atlas", "teff_used": 5795.0, "logg_used": 4.306},
		"cell_km": 1564.0, "sigma_t": 0.03569838559880867, "lifetime_s": 440.0, "facula_sigma_t": 0.02,
		"spots": [{"lat_deg": 12.0, "lon_deg": 5.0, "radius_rad": 0.03, "umbra_k": 4116.0, "penumbra_k": 5421.0}, {"lat_deg": -18.0, "lon_deg": 340.0, "radius_rad": 0.02, "umbra_k": 4116.0, "penumbra_k": 5421.0}],
		"t_emit_s": 1.234e9, "salt": 5, "corona": true}


func _place(main: Node, sv: SystemView, radius: float, px_across: float) -> float:
	var fov0: float = main.camera.fov
	main.camera.fov = 1.0
	main._configure_pixel()
	var size: Vector2 = main.get_viewport().get_texture().get_size()
	var px_rad: float = main.exposure.pixel_rad
	sv.set_view(px_rad, size.y)
	main.set_meta("fov0", fov0)
	return radius / sin(px_across / 2.0 * px_rad)


func _restore(main: Node) -> void:
	main.camera.fov = main.get_meta("fov0")
	main._configure_pixel()


func _flux(main: Node, sv: SystemView, label: String, surface: Dictionary, teff: float) -> int:
	var radius := 31453988.4 if label == "G-SS-1" else (82927.0 if label == "G-SS-2" else 851119.0)
	var d := _place(main, sv, radius, 200.0)
	var e_v := 1000.0
	var ang := Planets.angular_radius(radius, d)
	var mean_l := e_v / (PI * sin(ang) * sin(ang))
	var ld_a: float = surface.ld.a
	var ld_b: float = surface.ld.b
	var k := 0.5 / (mean_l / StarSurface.ld_mean(ld_a, ld_b) * 1.6) # the hottest cell well under 1 (nothing clips)
	var b := star(label.to_lower(), radius, d, teff, e_v, surface)
	sv.update(M5.section([b]), k)
	sv.update(M5.section([b]), k) # the second pass draws with the waited normaliser
	var img: Image = await main._grab()
	var got: float = M5.new()._integrated(main, img, k)
	var surf_on := false
	var mi: MeshInstance3D = sv.discs.get(b.id)
	if mi != null:
		surf_on = (mi.material_override as ShaderMaterial).get_shader_parameter("surf_on")
	_restore(main)
	var ratio := got / e_v
	var ok := surf_on and absf(ratio - 1.0) < 0.005
	print("%s  G-SS-%s %s, 200 px across, map on %s: integrated %s lux, e_v_lux %s (ratio %.5f, limit 0.5%%)" % ["ok  " if ok else "FAIL", label.substr(5), ["a giant (Aldebaran's surface)", "a spotted red dwarf (TRAPPIST-1's)", "a Sun-like star, spots resolved (alpha Cen A's)"][int(label.substr(5)) - 1], surf_on, String.num_scientific(got), String.num_scientific(e_v), ratio])
	return 0 if ok else 1


func _centroid(main: Node, sv: SystemView) -> int:
	var radius := 31453988.4
	var d := _place(main, sv, radius, 200.0)
	var e_v := 1000.0
	var ang := Planets.angular_radius(radius, d)
	var k := 0.5 / (e_v / (PI * sin(ang) * sin(ang)) / StarSurface.ld_mean(0.955648264, -0.115710464) * 1.6)
	var b := star("g-ss-4", radius, d, 3927.0, e_v, _giant())
	sv.update(M5.section([b]), k)
	sv.update(M5.section([b]), k)
	var img: Image = await main._grab()
	var size: Vector2 = main.get_viewport().get_texture().get_size()
	var expected: Vector2 = main.camera.project(Vector3(0, 0, -1), size)
	var win := Rect2i(Vector2i(expected) - Vector2i(150, 150), Vector2i(300, 300)) # the disc's neighbourhood: not the main scene's credits label
	var got := _mask_centroid(img.get_region(win)) + Vector2(win.position)
	var bb := _lit_box(img.get_region(win))
	var light: Vector2 = main._centroid(img.get_region(win)) + Vector2(win.position)
	_restore(main)
	var err := got.distance_to(expected)
	var ok := err < 0.75
	print("%s  G-SS-4 giant's disc centred at (%.2f, %.2f), expected (%.2f, %.2f), error %.3f px (limit 0.75); light-weighted centroid off by %.2f px (the cells); lit box %s" % ["ok  " if ok else "FAIL", got.x, got.y, expected.x, expected.y, err, light.distance_to(expected), bb])
	return 0 if ok else 1


## The centroid of the lit pixels, each weighted by its coverage (alpha-like edge fraction is in the
## brightness, so the edge uses the pixel's share of the frame's mean disc brightness, clamped at 1).
func _mask_centroid(img: Image) -> Vector2:
	var sum := Vector2.ZERO
	var w := 0.0
	var mean := 0.0
	var n := 0
	var top := 0.0
	for y in img.get_height():
		for x in img.get_width():
			top = maxf(top, img.get_pixel(x, y).srgb_to_linear().get_luminance())
	var floor_l := 0.01 * top # the disc, not the faint background a 1 deg view can carry
	for y in img.get_height():
		for x in img.get_width():
			var l := img.get_pixel(x, y).srgb_to_linear().get_luminance()
			if l > floor_l:
				mean += l
				n += 1
	mean = mean / maxf(1.0, n)
	for y in img.get_height():
		for x in img.get_width():
			var l := img.get_pixel(x, y).srgb_to_linear().get_luminance()
			if l > floor_l:
				var c := minf(1.0, l / (0.25 * mean)) # interior pixels count 1; only the antialiased rim is fractional
				sum += c * Vector2(x + 0.5, y + 0.5)
				w += c
	return sum / maxf(w, 1e-9)


func _lit_box(img: Image) -> Rect2i:
	var lo := Vector2i(100000, 100000)
	var hi := Vector2i(-1, -1)
	var top := 0.0
	for y in img.get_height():
		for x in img.get_width():
			top = maxf(top, img.get_pixel(x, y).srgb_to_linear().get_luminance())
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).srgb_to_linear().get_luminance() > 0.01 * top:
				lo = Vector2i(mini(lo.x, x), mini(lo.y, y))
				hi = Vector2i(maxi(hi.x, x), maxi(hi.y, y))
	return Rect2i(lo, hi - lo + Vector2i.ONE)


func _identical(main: Node, sv: SystemView) -> int:
	var radius := 695700.0
	var d := _place(main, sv, radius, 10.0)
	var e_v := 1000.0
	var ang := Planets.angular_radius(radius, d)
	var k := 0.5 / (e_v / (PI * sin(ang) * sin(ang)) / 0.8)
	var sun_surface := {"teff_k": 5772.0, "logg": 4.438067627303133, "ld": {"law": "quadratic", "a": 0.4650, "b": 0.2565, "source": "claret2011-atlas", "teff_used": 5772.0, "logg_used": 4.438},
		"cell_km": 1276.5, "sigma_t": 0.03569838559880867, "lifetime_s": 360.0, "facula_sigma_t": 0.02,
		"spots": [{"lat_deg": 14.0, "lon_deg": 20.0, "radius_rad": 0.028, "umbra_k": 4100.0, "penumbra_k": 5400.0}], "t_emit_s": 1.234e9, "salt": 9, "corona": true}
	var plain := star("sun", radius, d, 5772.0, e_v, {})
	plain["limb_u"] = 0.6
	sv.update(M5.section([plain]), k)
	var a: Image = await main._grab()
	var with_s := star("sun", radius, d, 5772.0, e_v, sun_surface)
	with_s["limb_u"] = 0.6
	sv.update(M5.section([with_s]), k)
	var b: Image = await main._grab()
	_restore(main)
	var same := a.get_data() == b.get_data()
	var lit := 0
	for y in a.get_height():
		for x in a.get_width():
			if a.get_pixel(x, y).r > 0.0:
				lit += 1
	var ok := same and lit > 20
	print("%s  G-SS-5 the Sun 10 px across with and without its surface record: %s (%d lit px)" % ["ok  " if ok else "FAIL", "byte-identical" if same else "DIFFERENT", lit])
	return 0 if ok else 1
