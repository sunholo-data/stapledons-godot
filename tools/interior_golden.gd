extends RefCounted
## M4.2 interior goldens (make golden; main.gd loads this by path, tools/ is not exported).
## The composite is built on the bridge v1 bundle and read back from the GPU:
##   G-M4-1  composite position: a star at 6 directions x beta {0, 0.5, 0.9, 0.99} x pan
##           {-5, 0, +5} m lands within 0.75 px of the CPU projection (Relativity.aberrate,
##           then cam_bridge.json x ship_basis through AreaBundle.project) in the FINAL frame
##           (plates and the play layer composited over it): pan-invariant
##   G-M4-2  one tonemap: sky-only pixels of the final frame equal the sky SubViewport's
##           within 1/255
##   G-M4-3  forward pole: a star dead ahead lands on the projection of ship +Z within
##           0.75 px in the boost, the cruise and the brake (no flip), on two headings
##   G-M4-4  glow: (a) profile at 0.99c, theta 0 / 45 / 80 deg within 1 % of glowEmittanceAt's
##           shape, 0 at rest; (b) absolute: the unit-gain linear float target reads the
##           package pole (tools/glow_probe) within 1 % at 0.99c and the cap; (c) the real
##           panorama camera (off-centre, ship frame): pixels within 1 % of
##           ForwardGlow.wall_cos; (d) the photometric chain: E/pi x lm/W x k x colour
##           within 1 % (no hand-tuned gain)

const BUNDLE := "res://assets/areas/bridge"
const ALPHA_CEN_A := "CNS5:3627"
const PEAK := 5.0 # linear splat peak of a unit-flux star (as main.gd's goldens)
const TOL_PX := 0.75
const WIN := 12
## tools/glow_probe, sunholo/relativity 0.7.0 glowEmittanceAt(n, phi, 1e-9, 0.5, 1).
const POLE := {"0.99c": 9.628776871706524e-05, "cap": 1.1250843031053142}

var main: Node
var it: Interior
var size := Vector2i.ZERO
var cam_screen := {}
var acen := PackedFloat64Array()


func run(m: Node) -> int:
	main = m
	size = main.get_window().size
	var f := 0
	f += await _build(false)
	if f > 0:
		return f
	f += await _g1()
	f += await _g3()
	f += await _g4()
	it.queue_free()
	await main.get_tree().process_frame
	f += await _build(true)
	f += await _g2()
	it.queue_free()
	await main.get_tree().process_frame
	print("interior golden: %d failures" % f)
	return f


func _build(background: bool) -> int:
	it = Interior.new()
	var ok := it.setup(AreaBundle.load_dir(BUNDLE), {"size": size, "canvas": Vector2(size), "background": background, "stars": false})
	if not ok:
		print("FAIL  interior golden: setup %s" % it.last_error)
		return 1
	it.auto = false
	main.add_child(it)
	it.layer_nodes()["hud"].visible = false
	cam_screen = it.bundle.camera.duplicate(true)
	cam_screen["fov_vertical_deg"] = it.sky.view_fov
	cam_screen["resolution"] = [size.x, size.y]
	var stars: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/starmap/stars.json"))
	for s: Dictionary in stars["stars"]:
		if s["id"] == ALPHA_CEN_A:
			var n := sqrt(s["x"] * s["x"] + s["y"] * s["y"] + s["z"] * s["z"])
			acen = PackedFloat64Array([s["x"] / n, s["y"] / n, s["z"] / n])
	return 0 if acen.size() == 3 else 1


func _grab() -> Image:
	for i in 3:
		await main.get_tree().process_frame
	await RenderingServer.frame_post_draw
	return main.get_viewport().get_texture().get_image()


func _sky_image() -> Image:
	for i in 3:
		await main.get_tree().process_frame
	await RenderingServer.frame_post_draw
	return it.sky.get_texture().get_image()


static func _w(g: PackedFloat64Array) -> Vector3:
	var w := SkyFrame.to_world64(g)
	return Vector3(w[0], w[1], w[2])


## Ship-frame unit direction -> screen pixel (centres at +0.5) through cam x the view region.
func _project_ship(d: PackedFloat64Array) -> Vector2:
	var p: Array = cam_screen["position_m"]
	var q := AreaBundle.project(cam_screen, [p[0] + d[0] * 1e6, p[1] + d[1] * 1e6, p[2] + d[2] * 1e6])
	return Vector2(q[0], q[1])


## A unit star seen along `app_ship` (apparent, ship frame) at beta along the heading.
func _place(app_ship: PackedFloat64Array, heading: PackedFloat64Array, b: float) -> Vector2:
	var basis := ShipFrame.ship_basis(heading)
	var vw := _w(heading)
	var aw := _w(ShipFrame.to_galactic(basis, app_ship))
	var n := Relativity.deaberrate(aw.normalized(), vw, b)
	var d := Relativity.doppler(n, vw, b)
	var t := 5700.0 / d
	var sf := it.sky.starfield
	sf.set_custom_stars([{"name": "test", "pos": n * 1000.0, "t": t, "flux": 1.0 / Relativity.point_flux_ratio(t, d)}])
	sf.set_ship_position(0.0, 0.0, 0.0)
	sf.set_velocity(vw, b, Relativity.gamma_of(b))
	sf.set_exposure(PEAK)
	# the CPU reference: aberrate the rest direction, back to the ship frame, through the camera
	var app := Relativity.aberrate(n, vw, b)
	var g := SkyFrame.to_galactic64([app.x, app.y, app.z])
	return _project_ship(ShipFrame.to_ship(basis, g))


func _centroid(img: Image, c: Vector2) -> Array:
	var peak := 0.0
	var x0 := clampi(int(c.x) - WIN, 0, img.get_width() - 1)
	var x1 := clampi(int(c.x) + WIN, 0, img.get_width() - 1)
	var y0 := clampi(int(c.y) - WIN, 0, img.get_height() - 1)
	var y1 := clampi(int(c.y) + WIN, 0, img.get_height() - 1)
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			peak = maxf(peak, img.get_pixel(x, y).get_luminance())
	var sum := Vector2.ZERO
	var w := 0.0
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var l := img.get_pixel(x, y).get_luminance()
			if l >= peak * 0.5:
				sum += Vector2(x + 0.5, y + 0.5) * l
				w += l
	return [sum / w if w > 0.0 else Vector2(-1, -1), peak]


## The six G-M4-1 targets: screen points in the open sky above the set (top 22 %).
func _targets() -> Array:
	var out := []
	for fy in [0.09, 0.2]:
		for fx in [0.22, 0.42, 0.62]:
			out.append(AreaBundle.unproject(cam_screen, fx * size.x, fy * size.y))
	return out


func _g1() -> int:
	var fails := 0
	var worst := 0.0
	var count := 0
	it.sky.orient(acen)
	for pan: float in [-5.0, 0.0, 5.0]:
		it.set_pan(Vector2(pan, 0.0))
		it.sky.starfield.set_custom_stars([])
		var clean := await _grab()
		for t: PackedFloat64Array in _targets():
			var c := _project_ship(t)
			var bg: float = _centroid(clean, c)[1]
			if bg > 0.02:
				print("FAIL  G-M4-1 pan %+.0f target (%.0f, %.0f) is covered by the set or a plate (peak %.3f)" % [pan, c.x, c.y, bg])
				fails += 1
				continue
			for b: float in [0.0, 0.5, 0.9, 0.99]:
				var want := _place(t, acen, b)
				var got: Array = _centroid(await _grab(), want)
				var err: float = (got[0] as Vector2).distance_to(want)
				worst = maxf(worst, err)
				count += 1
				var ok := err < TOL_PX
				if not ok:
					fails += 1
				print("%s  G-M4-1 composite pan %+.0f m beta %.2f expected (%.2f, %.2f) rendered (%.2f, %.2f) error %.3f px" % ["ok  " if ok else "FAIL", pan, b, want.x, want.y, got[0].x, got[0].y, err])
	it.set_pan(Vector2.ZERO)
	print("%s  G-M4-1 composite position: %d cases (6 directions x 4 speeds x 3 pans), worst %.3f px (limit %.2f)" % ["ok  " if fails == 0 and count == 72 else "FAIL", count, worst, TOL_PX])
	return fails


func _g3() -> int:
	var fails := 0
	var pole := _project_ship(PackedFloat64Array([0.0, 0.0, 1.0]))
	for heading: PackedFloat64Array in [acen, PackedFloat64Array([1.0, 0.0, 0.0])]:
		for ph: Array in [["boosting", 0.5], ["cruising", 0.99], ["braking", 0.5]]:
			var b: float = ph[1]
			var g := Relativity.gamma_of(b)
			it.sky.apply({"ship": {"phase": ph[0], "beta": b, "gamma": g, "heading": {"x": heading[0], "y": heading[1], "z": heading[2]}, "pos": {"x": 0.0, "y": 0.0, "z": 0.0}}})
			var want := _place(PackedFloat64Array([0.0, 0.0, 1.0]), heading, b)
			var got: Array = _centroid(await _grab(), want)
			var err: float = (got[0] as Vector2).distance_to(pole)
			var ok := err < TOL_PX and want.distance_to(pole) < 1e-6
			if not ok:
				fails += 1
			print("%s  G-M4-3 forward pole heading (%.3f, %.3f, %.3f) %s beta %.2f: pole (%.2f, %.2f) rendered (%.2f, %.2f) error %.3f px" % ["ok  " if ok else "FAIL", heading[0], heading[1], heading[2], ph[0], b, pole.x, pole.y, got[0].x, got[0].y, err])
	it.sky.starfield.set_custom_stars([])
	return fails


func _g2() -> int:
	var sky := it.sky
	if not sky.has_background: # no NOIRLab panorama: a synthetic gradient sky
		var photo := Image.create(256, 128, false, Image.FORMAT_RGB8)
		for y in 128:
			for x in 256:
				photo.set_pixel(x, y, Color(x / 255.0, y / 127.0, 0.5))
		var model := Image.create(256, 128, false, Image.FORMAT_RGBA8)
		model.fill(Color8(SkyModel.encode_t(6000.0), 0, 0, 255))
		sky.has_background = sky.background.attach(sky.env, size.y, sky.view_fov, photo, model)
	sky.apply({"ship": {"phase": "cruising", "beta": 0.9, "gamma": Relativity.gamma_of(0.9), "heading": {"x": acen[0], "y": acen[1], "z": acen[2]}, "pos": {"x": 0.0, "y": 0.0, "z": 0.0}}})
	var frame := await _grab()
	var sub := await _sky_image()
	var play := it.play_view.get_texture().get_image()
	frame.convert(Image.FORMAT_RGBA8)
	sub.convert(Image.FORMAT_RGBA8)
	var pano := it.bundle.load_image("panorama")
	var fg := it.bundle.load_image("foreground")
	var worst := 0.0
	var n := 0
	var lit := 0
	for j in 24:
		for i in 40:
			var x := int((i + 0.5) * size.x / 40.0)
			var y := int((j + 0.5) * size.y / 24.0)
			if play.get_pixel(x, y).a > 0.0 or _plate_alpha(pano, "panorama", x, y) > 0.0 or _plate_alpha(fg, "foreground", x, y) > 0.0:
				continue
			var a := frame.get_pixel(x, y)
			var s := sub.get_pixel(x, y)
			worst = maxf(worst, maxf(absf(a.r - s.r), maxf(absf(a.g - s.g), absf(a.b - s.b))))
			n += 1
			if s.get_luminance() > 2.0 / 255.0:
				lit += 1
	var ok := n >= 100 and lit >= 50 and worst <= 1.0 / 255.0 + 1e-6
	print("%s  G-M4-2 one tonemap: %d sky-only pixels (%d lit), worst |final - SubViewport| %.4f (limit 1/255 = %.4f)" % ["ok  " if ok else "FAIL", n, lit, worst, 1.0 / 255.0])
	return 0 if ok else 1


## The plate's alpha under a screen pixel (pan 0, the layout Interior uses).
func _plate_alpha(img: Image, layer: String, x: int, y: int) -> float:
	var r: TextureRect = it.pano_rect if layer == "panorama" else it.fg_rect
	var u := (Vector2(x + 0.5, y + 0.5) - r.position) / r.size * Vector2(img.get_size())
	if u.x < 0 or u.y < 0 or u.x >= img.get_width() or u.y >= img.get_height():
		return 0.0
	var a := 0.0
	for dy in [-2, 0, 2]: # the plate is downsampled on screen: any alpha nearby counts
		for dx in [-2, 0, 2]:
			a = maxf(a, img.get_pixelv(Vector2i(clampi(int(u.x) + dx, 0, img.get_width() - 1), clampi(int(u.y) + dy, 0, img.get_height() - 1))).a)
	return a


func _g4() -> int:
	var sky := it.sky
	var mat := sky.glow_mat
	var fails := 0
	sky.set_debug_unit(true)
	# (a), (b): the ship frame = the sky frame, the camera at the bubble centre
	mat.set_shader_parameter("ship_x", Vector3(1, 0, 0))
	mat.set_shader_parameter("ship_y", Vector3(0, 1, 0))
	mat.set_shader_parameter("ship_z", Vector3(0, 0, 1))
	mat.set_shader_parameter("cam_ship", Vector3.ZERO)
	mat.set_shader_parameter("radius", 100.0)
	var cases := [["0.99c", 0.0], ["0.99c", 45.0], ["0.99c", 80.0], ["cap", 0.0], ["rest", 0.0]]
	for c: Array in cases:
		var pole: float = POLE.get(c[0], 0.0)
		var th := deg_to_rad(c[1])
		mat.set_shader_parameter("pole", pole)
		sky.camera.look(atan2(-sin(th), -cos(th)), 0.0, 0.0) # look along (sin th, 0, cos th)
		var img := await _sky_image()
		var got := img.get_pixel(size.x / 2, size.y / 2).r
		var want := ForwardGlow.profile(pole, cos(th))
		var ok := absf(got - want) <= 0.01 * want if want > 0.0 else got == 0.0
		if not ok:
			fails += 1
		print("%s  G-M4-4 glow %s theta %2.0f deg: unit-gain target %s W/m^2, CPU profile %s (limit 1 %%; format %d)" % ["ok  " if ok else "FAIL", c[0], c[1], String.num_scientific(got), String.num_scientific(want), img.get_format()])
	# (c) the real camera: bridge cam position, alpha Cen heading, pixels over the frame
	sky.orient(acen)
	var p: Array = sky.cam["position_m"]
	mat.set_shader_parameter("cam_ship", Vector3(p[0], p[1], p[2]))
	mat.set_shader_parameter("pole", POLE["cap"])
	var img := await _sky_image()
	var worst := 0.0
	for q in [[0.5, 0.05], [0.2, 0.3], [0.8, 0.3], [0.5, 0.5], [0.1, 0.9], [0.9, 0.9]]:
		var x := int(q[0] * size.x)
		var y := int(q[1] * size.y)
		var d := AreaBundle.unproject(cam_screen, x + 0.5, y + 0.5) # texture column x is screen column x (D-28: no flip)
		var want := ForwardGlow.profile(POLE["cap"], ForwardGlow.wall_cos(PackedFloat64Array([p[0], p[1], p[2]]), d, 100.0))
		var got := img.get_pixel(x, y).r
		var e := absf(got - want) / maxf(want, 1e-30)
		worst = maxf(worst, e)
	var ok_c := worst <= 0.01
	print("%s  G-M4-4 glow (c) bridge camera off-centre, cap: 6 pixels vs ForwardGlow.wall_cos, worst %.4f %% (limit 1 %%)" % ["ok  " if ok_c else "FAIL", worst * 100.0])
	fails += 0 if ok_c else 1
	# (d) the photometric chain, linear tonemap: E / pi x lm/W x k x colour
	mat.set_shader_parameter("debug_unit", false)
	sky.radius_m = 100.0
	sky.glow_pole = POLE["0.99c"]
	sky.update_exposure()
	mat.set_shader_parameter("cam_ship", Vector3.ZERO)
	mat.set_shader_parameter("ship_x", Vector3(1, 0, 0))
	mat.set_shader_parameter("ship_y", Vector3(0, 1, 0))
	mat.set_shader_parameter("ship_z", Vector3(0, 0, 1))
	sky.camera.look(PI, 0.0, 0.0)
	var lin := await _sky_image()
	var want_g := ForwardGlow.luminance(POLE["0.99c"]) * sky.exposure.k() * ForwardGlow.WHITE_RGB.y
	var got_g := lin.get_pixel(size.x / 2, size.y / 2).g
	var ok_d := absf(got_g - want_g) <= 0.01 * want_g
	print("%s  G-M4-4 glow (d) photometric: pixel G %s = E/pi x %.2f lm/W x k (EV %+.2f) x colour %s (limit 1 %%)" % ["ok  " if ok_d else "FAIL", String.num_scientific(got_g), ForwardGlow.LM_PER_W, sky.exposure.ev, String.num_scientific(want_g)])
	fails += 0 if ok_d else 1
	sky.set_debug_unit(false)
	sky.glow_pole = -1.0
	sky.update_exposure()
	return fails
