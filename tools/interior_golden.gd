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
##           ForwardGlow.wall_cos; (d) E/pi x eta(T) x k x colour(T) at 0.999c and the cap
##           within 1 % of the exact CPU chain (no hand-tuned gain).
##   G-M4-5  bridge v2 plate projection at five pans within 4/255 and spectral glow within 2 %.
##   G-M4-6  blackbody colour and efficacy at 10 temperatures 800 K..30,000 K within 1 %.


const BUNDLE := "res://assets/areas/bridge"
const ALPHA_CEN_A := "CNS5:3627"
const PEAK := 5.0 # linear splat peak of a unit-flux star (as main.gd's goldens)
const TOL_PX := 0.75
const WIN := 12
## tools/glow_probe, sunholo/relativity 0.8.0 glowEmittanceAt(n, phi, 1e-10, 0.5, 1) and
## glowTemperatureAt(n, phi, 1) (eps 1e-10, HB-111).
const POLE := {"0.99c": 9.628776871706523e-06, "0.999c": 0.00010757658235978286, "cap": 0.11250843031053141}
const T_POLE := {"0.99c": 1357.5234659678836, "0.999c": 2481.898408081983, "cap": 14114.023335759706}
## (a)-(c) read the unit-gain float target, which is half precision: the eps 1e-9 poles (probe "E9",
## the same shape x 10) keep every case above half's normal range (6.1e-5).
const POLE_E9 := {"0.99c": 9.628776871706524e-05, "cap": 1.1250843031053142}
const RAMP := [800.0, 1000.0, 1357.5, 2000.0, 2482.0, 4000.0, 6600.0, 10000.0, 14114.0, 30000.0]

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
	f += await _g6()
	if it.bundle.has_play_plate():
		f += await _g5()
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
		var pole: float = POLE_E9.get(c[0], 0.0)
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
	mat.set_shader_parameter("pole", POLE_E9["cap"])
	var img := await _sky_image()
	var worst := 0.0
	for q in [[0.5, 0.05], [0.2, 0.3], [0.8, 0.3], [0.5, 0.5], [0.1, 0.9], [0.9, 0.9]]:
		var x := int(q[0] * size.x)
		var y := int(q[1] * size.y)
		var d := AreaBundle.unproject(cam_screen, x + 0.5, y + 0.5) # texture column x is screen column x (D-28: no flip)
		var want := ForwardGlow.profile(POLE_E9["cap"], ForwardGlow.wall_cos(PackedFloat64Array([p[0], p[1], p[2]]), d, 100.0))
		var got := img.get_pixel(x, y).r
		var e := absf(got - want) / maxf(want, 1e-30)
		worst = maxf(worst, e)
	var ok_c := worst <= 0.01
	print("%s  G-M4-4 glow (c) bridge camera off-centre, cap: 6 pixels vs ForwardGlow.wall_cos, worst %.4f %% (limit 1 %%)" % ["ok  " if ok_c else "FAIL", worst * 100.0])
	fails += 0 if ok_c else 1
	# (d) the photometric chain, linear tonemap: E / pi x eta(T) x k x colour(T) (blackbody, D-30)
	mat.set_shader_parameter("debug_unit", false)
	mat.set_shader_parameter("cam_ship", Vector3.ZERO)
	mat.set_shader_parameter("ship_x", Vector3(1, 0, 0))
	mat.set_shader_parameter("ship_y", Vector3(0, 1, 0))
	mat.set_shader_parameter("ship_z", Vector3(0, 0, 1))
	sky.radius_m = 100.0
	sky.camera.look(PI, 0.0, 0.0)
	for speed: String in ["0.999c", "cap"]:
		sky.glow_pole = POLE[speed]
		sky.glow_t_pole = T_POLE[speed]
		sky.update_exposure()
		var lin := await _sky_image()
		var t: float = T_POLE[speed]
		var want_g := ForwardGlow.colour(t).y * ForwardGlow.luminance(POLE[speed], t) * sky.exposure.k()
		var got_g := lin.get_pixel(size.x / 2, size.y / 2).g
		var ok_d := absf(got_g - want_g) <= 0.01 * want_g
		print("%s  G-M4-4 glow (d) photometric %s: pixel G %s = E/pi x %s lm/W (%.0f K) x k (EV %+.2f) x colour G %.4f -> %s (limit 1 %%)" % ["ok  " if ok_d else "FAIL", speed, String.num_scientific(got_g), String.num_scientific(ForwardGlow.efficacy(t)), t, sky.exposure.ev, ForwardGlow.colour(t).y, String.num_scientific(want_g)])
		fails += 0 if ok_d else 1
	sky.set_debug_unit(false)
	sky.glow_pole = -1.0
	sky.glow_t_pole = -1.0
	sky.update_exposure()
	return fails


## G-M4-6: the blackbody colour ramp. Pole straight ahead (cos 1, so T = t_pole), debug_colour with
## scale = 1 / eta_exact(T): the pixel is rgb_lut(T) x eta_lut(T) / eta_exact(T), which must equal
## the exact unit-luminance colour (per channel, 1 % of the largest channel) with the same Y (1 %).
func _g6() -> int:
	var sky := it.sky
	var mat := sky.glow_mat
	var fails := 0
	sky.set_debug_unit(true)
	mat.set_shader_parameter("debug_unit", false)
	mat.set_shader_parameter("debug_colour", true)
	mat.set_shader_parameter("ship_x", Vector3(1, 0, 0))
	mat.set_shader_parameter("ship_y", Vector3(0, 1, 0))
	mat.set_shader_parameter("ship_z", Vector3(0, 0, 1))
	mat.set_shader_parameter("cam_ship", Vector3.ZERO)
	mat.set_shader_parameter("radius", 100.0)
	mat.set_shader_parameter("pole", 1.0)
	sky.camera.look(PI, 0.0, 0.0) # along +Z: the pole
	for t: float in RAMP:
		var eta := ForwardGlow.efficacy(t)
		mat.set_shader_parameter("t_pole", t)
		mat.set_shader_parameter("scale", 1.0 / eta)
		var img := await _sky_image()
		var px := img.get_pixel(size.x / 2, size.y / 2)
		var got := Vector3(px.r, px.g, px.b)
		var want := ForwardGlow.colour(t)
		var m := maxf(want.x, maxf(want.y, want.z))
		var err := maxf(absf(got.x - want.x), maxf(absf(got.y - want.y), absf(got.z - want.z))) / m
		var y_got := 0.2126729 * got.x + 0.7151522 * got.y + 0.0721750 * got.z # = eta_lut / eta_exact
		var ok := err <= 0.01 and absf(y_got - 1.0) <= 0.01
		fails += 0 if ok else 1
		print("%s  G-M4-6 colour %6.0f K: shader rgb (%.4f, %.4f, %.4f) vs CPU (%.4f, %.4f, %.4f), worst %.3f %% of max; efficacy shader/CPU %.4f (%s lm/W) (limit 1 %%)" % [
			"ok  " if ok else "FAIL", t, got.x, got.y, got.z, want.x, want.y, want.z, err * 100.0, y_got, String.num_scientific(eta)])
	mat.set_shader_parameter("debug_colour", false)
	mat.set_shader_parameter("pole", 0.0)
	sky.set_debug_unit(false)
	sky.update_exposure()
	return fails


func _play_image() -> Image:
	for i in 3:
		await main.get_tree().process_frame
	await RenderingServer.frame_post_draw
	return it.play_view.get_texture().get_image()


## Open, up-facing deck points the iso camera sees: candidates on the WALK_ deck, kept when a
## ray from the camera hits them first (trimesh colliders built here, test-only) on a surface
## facing +Y, then the flattest (lowest plate variance over the screen footprint) first.
func _deck_points(plate: Image, pc: Dictionary, size_m: float, aspect: float, foot: float) -> Array:
	var bodies := []
	var stack: Array[Node] = [it.play_scene]
	var walk_faces := PackedVector3Array()
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
			var mi := n as MeshInstance3D
			var body := StaticBody3D.new()
			var cs := CollisionShape3D.new()
			cs.shape = mi.mesh.create_trimesh_shape()
			body.add_child(cs)
			mi.add_child(body)
			bodies.append(body)
			if String(mi.name).begins_with("WALK_"):
				var f := mi.mesh.get_faces()
				for k in range(0, f.size(), 3):
					walk_faces.append(mi.global_transform * ((f[k] + f[k + 1] + f[k + 2]) / 3.0))
		for c in n.get_children():
			stack.append(c)
	await main.get_tree().physics_frame
	await main.get_tree().physics_frame
	var space := it.play_view.find_world_3d().direct_space_state
	var back: Vector3 = (pc["right"] as Vector3).cross(pc["up"]).normalized() # toward the camera
	var cands := []
	var step := maxi(1, walk_faces.size() / 400)
	for k in range(0, walk_faces.size(), step):
		var p: Vector3 = walk_faces[k]
		var q := PhysicsRayQueryParameters3D.create(p + back * 300.0, p - back * 0.05)
		var hit := space.intersect_ray(q)
		if hit.is_empty() or (hit["position"] as Vector3).distance_to(p) > 0.02 or (hit["normal"] as Vector3).y < 0.99:
			continue
		var uv := Interior.plate_uv(p, pc, size_m, aspect) * Vector2(plate.get_size())
		cands.append([_spread(plate, uv, foot * 3.0), p])
	for bd in bodies:
		bd.queue_free()
	cands.sort_custom(func(a, b): return a[0] < b[0])
	return cands.map(func(c): return c[1])


func _g5() -> int:
	var fails := 0
	var plate := AreaBundle.load_png(it.bundle.play_plate_path())
	var pc := it.plate_camera()
	var size_m := float(it.bundle.play_plate()["size_m"])
	var aspect := float(plate.get_width()) / float(plate.get_height())
	var foot := 270.0 * float(it.bundle.iso_camera()["size_m"]) / float(it.play_view.size.y) # plate px per screen px
	it.sky.glow_pole = -1.0
	it._push_glow_tint()
	var pts := await _deck_points(plate, pc, size_m, aspect, foot)
	for pan in [Vector2.ZERO, Vector2(6, 0), Vector2(-6, 0), Vector2(0, 3), Vector2(0, -3)]:
		it.set_pan(pan)
		var img := await _play_image()
		var worst := 0.0
		var n := 0
		for p: Vector3 in pts:
			if n >= 8:
				break
			var sp := it.iso_cam.unproject_position(p)
			if sp.x < 4 or sp.y < 4 or sp.x > img.get_width() - 5 or sp.y > img.get_height() - 5:
				continue
			var uv := Interior.plate_uv(p, pc, size_m, aspect)
			var want := _box(plate, uv * Vector2(plate.get_size()), foot)
			var got := img.get_pixel(int(sp.x), int(sp.y))
			worst = maxf(worst, maxf(absf(got.r - want.r), maxf(absf(got.g - want.g), absf(got.b - want.b))))
			n += 1
		var ok := n >= 3 and worst <= 4.0 / 255.0
		print("%s  G-M4-5 plate projection pan (%+.0f, %+.0f) m: %d open deck points, worst %.2f/255 (limit 4/255)" % ["ok  " if ok else "FAIL", pan.x, pan.y, n, worst * 255.0])
		fails += 0 if ok else 1
	# (b) the live glow term on an up-facing open deck pixel, linear light
	it.set_pan(Vector2.ZERO)
	var img0 := await _play_image()
	var sp0 := Vector2(-1, -1)
	for p: Vector3 in pts: # the flattest open deck point on screen at pan 0, not near black
		var sp := it.iso_cam.unproject_position(p)
		if sp.x >= 4 and sp.y >= 4 and sp.x <= img0.get_width() - 5 and sp.y <= img0.get_height() - 5 and img0.get_pixel(int(sp.x), int(sp.y)).get_luminance() > 0.1:
			sp0 = sp
			break
	var base := img0.get_pixel(int(sp0.x), int(sp0.y)).srgb_to_linear()
	var fct := Interior.plate_glow_factor(Vector3.UP, pc)
	it.sky.glow_t_pole = T_POLE["cap"]
	it.sky.glow_pole = 1.0
	it._push_glow_tint()
	var unit: Vector3 = (it._plate_mats[0] as ShaderMaterial).get_shader_parameter("glow_rgb")
	var pole := 0.25 / maxf(unit.y * fct, 1e-30) # a pole that lifts green by 25 % (stays below white)
	it.sky.glow_pole = pole
	it._push_glow_tint()
	var g: Vector3 = (it._plate_mats[0] as ShaderMaterial).get_shader_parameter("glow_rgb")
	var lit := (await _play_image()).get_pixel(int(sp0.x), int(sp0.y)).srgb_to_linear()
	var want := Vector3(base.r * (1.0 + g.x * fct), base.g * (1.0 + g.y * fct), base.b * (1.0 + g.z * fct))
	var err := maxf(absf(lit.r - want.x) / want.x, maxf(absf(lit.g - want.y) / want.y, absf(lit.b - want.z) / want.z))
	var ok_b := err <= 0.02
	print("%s  G-M4-5 plate glow: deck pixel %s -> %s, CPU base x (1 + glow_rgb x %.3f) = (%.4f, %.4f, %.4f), worst %.2f %% (limit 2 %%)" % ["ok  " if ok_b else "FAIL", base, lit, fct, want.x, want.y, want.z, err * 100.0])
	fails += 0 if ok_b else 1
	it.sky.glow_pole = -1.0
	it._push_glow_tint()
	return fails


## Standard deviation of the plate's luminance over a k x k box (flat regions compare cleanly
## under the GPU's mipmap filtering).
static func _spread(img: Image, c: Vector2, k: float) -> float:
	var r := int(ceil(k * 0.5))
	var s := 0.0
	var s2 := 0.0
	var n := 0
	for y in range(int(c.y) - r, int(c.y) + r + 1, 2):
		for x in range(int(c.x) - r, int(c.x) + r + 1, 2):
			var l := img.get_pixel(clampi(x, 0, img.get_width() - 1), clampi(y, 0, img.get_height() - 1)).get_luminance()
			s += l
			s2 += l * l
			n += 1
	var m := s / n
	return sqrt(maxf(s2 / n - m * m, 0.0))


## Mean colour of a k x k plate-pixel box centred on c (the screen pixel's footprint).
static func _box(img: Image, c: Vector2, k: float) -> Color:
	var r := int(ceil(k * 0.5))
	var acc := Color(0, 0, 0, 0)
	var n := 0
	for y in range(int(c.y) - r, int(c.y) + r + 1):
		for x in range(int(c.x) - r, int(c.x) + r + 1):
			acc += img.get_pixel(clampi(x, 0, img.get_width() - 1), clampi(y, 0, img.get_height() - 1))
			n += 1
	return acc / float(n)
