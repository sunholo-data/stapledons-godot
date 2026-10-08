extends RefCounted
## M3.5 GR goldens (make golden; main.gd loads this by path, tools/ is not exported). The GPU
## lens (sky/schwarzschild.gdshaderinc through sky/background.gdshader and sky/starfield.gdshader)
## against the CPU reference physics/schwarzschild.gd, read back from an InteriorSky rendered
## sky-only (the player's sky, D-52) at 960 x 540 into a linear half-float target: linear
## tonemapper, glow off, fixed exposure. f = 270 / tan(fov / 2) px.
##   GR1-3  shadow radius sqrt(N_black / pi) within 0.5 px of f tan alpha_sh (Synge) at r = 10, 5
##          (fov 70: 98.066, 202.398 px) and 3 (fov 110: 189.056 px), hovering, on the debug grid
##   GR4    orbit at r = 5, beta_local = 0.35355 tangential: the GPU shadow mask against
##          Schwarzschild.compose per pixel at three orientations (yaw/pitch, off-axis, rolled):
##          mismatches only in the 1-px edge band, mask centroids within 0.5 px
##   GR5    a star at beta 20 / 60 / 120 deg from h at r 10 / 5 / 3: both image centroids within
##          0.75 px of Schwarzschild.star_images projected (image plane; dated note in the design)
##   GR6    a star exactly behind the hole at r = 10, 100, 1000 (the ring-star path): the
##          flux-weighted mean ring radius within 0.5 px of f tan psi_E (check46)
##   GR7    a bright sky and a star directly behind at r = 5: peak luminance inside the shadow
##          (excluding a 3-px edge band, where the PSF of the photon-ring images reaches) < 0.01
##   GR8    hovering at r = 3, a 5700 K star 90 deg from h: chromaticity within 0.01 of
##          rgb(1.22474 x 5700 K) (the LUT's colour at D_g T)
##   GR9    the weak-field hand-off at r = 9e5 (lens tables) and 2e6 (weakDeflectionFinite), a star
##          at beta 0.2 deg, fov 1 deg: both image centroids within 0.75 px of star_images
##   GR10   the lens_fwd mirror, exactly: the shader's float32 delta and psi - alpha per pixel (a
##          probe writes their bits) against Schwarzschild.deflection at that psi, on a 5-px grid,
##          toward and away from the hole at r = 2.01 (the ghost-row extrapolation), 2.05, 10, 3e5 and
##          9.9e5 (the last row interval): rules 1-3 of the M3.2 as-built note
##   GR11   the lens_inv mirror, exactly: the shader's image psi for F across [-pi, pi] (both
##          orders) against Schwarzschild.image at r = 2.01, 10, 9.9e5 and 2e6 (the weak branch)
##   GR12   sensitivity: each interpolation rule broken in turn (gr_mutant 1-3: x-linear weight,
##          repeated first row, repeated last row) makes GR10 fail where the rule acts

const SIZE := Vector2i(960, 540)
const HOLE_GAL := [1.0, 0.0, 0.0] # galactic centre: world -Z, straight ahead at yaw 0
const TOL_SHADOW := 0.5
const TOL_STAR := 0.75
const WIN := 12
const BLACK := 1e-4

var main: Node
var sky: InteriorSky
var h := Vector3(0.0, 0.0, -1.0)


func run(m: Node) -> int:
	main = m
	if not Schwarzschild.load_tables():
		print("FAIL  gr golden: %s" % Schwarzschild.load_error)
		return 1
	_build()
	var f := 0
	var only := OS.get_environment("GR_ONLY") # development: e.g. GR_ONLY=9 runs GR9 alone
	for c: Array in [["1", _gr1_3], ["4", _gr4], ["5", _gr5], ["6", _gr6], ["7", _gr7], ["8", _gr8], ["9", _gr9], ["10", _gr10], ["11", _gr11], ["12", _gr12]]:
		if only == "" or only == c[0]:
			f += await (c[1] as Callable).call()
	sky.set_gr({})
	sky.queue_free()
	await main.get_tree().process_frame
	print("gr golden: %d failures" % f)
	return f


func _build() -> void:
	var photo := Image.create(64, 32, false, Image.FORMAT_RGB8)
	photo.fill(Color(0.5, 0.5, 0.5))
	var model := Image.create(64, 32, false, Image.FORMAT_R8)
	model.fill(Color(0.5, 0.0, 0.0))
	sky = InteriorSky.new()
	main.add_child(sky)
	sky.setup({"forward": [0.0, 0.0, 1.0], "up": [0.0, 1.0, 0.0], "position_m": [0.0, 0.0, 0.0]}, 70.0, SIZE,
		{"stars": false, "photo": photo, "model": model, "planet_textures": false, "planet_preload": false, "planet_smooth_lod": false})
	sky.use_hdr_2d = true
	sky.env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	sky.env.tonemap_exposure = 1.0
	sky.env.glow_enabled = false
	sky.starfield.set_floor(Vector2.ZERO)
	sky.starfield.set_psf(1.0)
	sky.background.set_exposure(1.0)
	var w := SkyFrame.to_world64(HOLE_GAL)
	h = Vector3(w[0], w[1], w[2])


func _view(fov: float, yaw := 0.0, pitch := 0.0, roll := 0.0) -> void:
	sky.camera.fov = fov
	sky.camera.look(yaw, pitch, roll)
	sky.background.material.set_shader_parameter("screen_px_rad", deg_to_rad(fov) / SIZE.y)


func _focal(fov: float) -> float:
	return 0.5 * SIZE.y / tan(deg_to_rad(fov) * 0.5)


## gr state from the CPU reference (the game takes the sim's), stars set, then one frame.
func _gr_state(r: float, beta_local := 0.0, dir_local := PackedFloat64Array([0.0, 1.0, 0.0])) -> void:
	sky.set_gr(GrLens.reference_state(r, PackedFloat64Array(HOLE_GAL), beta_local, dir_local))
	sky.gr_lens.refresh_now()
	sky.gr_lens.set_exposure(1.0, 1.0 * deg_to_rad(sky.camera.fov) / SIZE.y)


func _stars(list: Array) -> void:
	sky.starfield.set_custom_stars(list)
	sky.starfield.set_ship_position(0.0, 0.0, 0.0)


func _grab() -> Image:
	for i in 4:
		await main.get_tree().process_frame
	await RenderingServer.frame_post_draw
	return sky.get_texture().get_image()


static func _lum(c: Color) -> float:
	return 0.2126729 * c.r + 0.7151522 * c.g + 0.0721750 * c.b


static func _yaw_pitch(d: Vector3) -> Array:
	return [atan2(-d.x, -d.z), asin(clampf(d.y, -1.0, 1.0))]


## The world ray through pixel (x + 0.5, y + 0.5) (FreeLookCamera pinhole, float64 scalars).
func _ray(x: int, y: int, f: float) -> Vector3:
	return sky.camera.to_world(Vector3((x + 0.5 - 0.5 * SIZE.x) / f, -(y + 0.5 - 0.5 * SIZE.y) / f, -1.0).normalized())


# ------------------------------------------------------------ GR1-3 shadow radius

func _gr1_3() -> int:
	var fails := 0
	sky.background.set_grid(true)
	_stars([])
	for c in [["GR1", 10.0, 70.0, 98.066], ["GR2", 5.0, 70.0, 202.398], ["GR3", 3.0, 110.0, 189.056]]:
		_view(c[2])
		_gr_state(c[1])
		var img := await _grab()
		var n := 0
		for y in SIZE.y:
			for x in SIZE.x:
				if _lum(img.get_pixel(x, y)) < BLACK:
					n += 1
		var got := sqrt(n / PI)
		var want := _focal(c[2]) * tan(Schwarzschild.shadow_angle(c[1]))
		var err := absf(got - want)
		var ok := err <= TOL_SHADOW and absf(want - c[3]) < 1e-3
		fails += 0 if ok else 1
		print("%s  %s shadow at r = %s r_s (fov %s): radius %.3f px from %d black pixels, Synge f tan alpha = %.3f px (plan %.3f), error %.3f px (limit %.1f)" % [
			"ok  " if ok else "FAIL", c[0], c[1], c[2], got, n, want, c[3], err, TOL_SHADOW])
	return fails


# ------------------------------------------------------------ GR4 orbit mask

func _gr4() -> int:
	var fails := 0
	var r := 5.0
	var b := 0.35355339059327373 # circularOrbitSpeed(5) (check49)
	var dl_gal := PackedFloat64Array([0.0, -1.0, 0.0]) # world +X: tangential, to starboard
	var w := SkyFrame.to_world64(dl_gal)
	var bh := Vector3(w[0], w[1], w[2])
	var a := Schwarzschild.shadow_angle(r)
	var f := _focal(70.0)
	sky.background.set_grid(true)
	_stars([])
	for o in [["yaw/pitch", -0.3, 0.0, 0.0], ["off-axis", -0.45, 0.2, 0.0], ["rolled", -0.3, -0.15, 0.7]]:
		_view(70.0, o[1], o[2], o[3])
		_gr_state(r, b, dl_gal)
		var img := await _grab()
		var cpu := PackedByteArray()
		cpu.resize(SIZE.x * SIZE.y)
		for y in SIZE.y:
			for x in SIZE.x:
				var ns := Relativity.deaberrate(_ray(x, y, f), bh, b)
				cpu[y * SIZE.x + x] = 1 if Schwarzschild.angle(ns, h) <= a else 0
		var band := 0
		var outside := 0
		var gs := Vector2.ZERO
		var cs := Vector2.ZERO
		var gn := 0
		var cn := 0
		for y in SIZE.y:
			for x in SIZE.x:
				var k := y * SIZE.x + x
				var g := 1 if _lum(img.get_pixel(x, y)) < BLACK else 0
				if g == 1:
					gs += Vector2(x + 0.5, y + 0.5)
					gn += 1
				if cpu[k] == 1:
					cs += Vector2(x + 0.5, y + 0.5)
					cn += 1
				if g != cpu[k]:
					if _edge(cpu, x, y):
						band += 1
					else:
						outside += 1
		var dc := (gs / maxi(gn, 1)).distance_to(cs / maxi(cn, 1))
		var ok := outside == 0 and dc <= TOL_SHADOW and cn > 1000
		fails += 0 if ok else 1
		print("%s  GR4 orbit mask r = 5, beta_local %.5f (%s): %d GPU / %d CPU shadow pixels, %d mismatches in the 1-px edge band, %d outside it (must be 0), centroid offset %.3f px (limit %.1f)" % [
			"ok  " if ok else "FAIL", b, o[0], gn, cn, band, outside, dc, TOL_SHADOW])
	return fails


## True when a CPU-mask pixel has a neighbour of the other class (the 1-px edge band).
func _edge(m: PackedByteArray, x: int, y: int) -> bool:
	var v := m[y * SIZE.x + x]
	for dy in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			var xx: int = clampi(x + dx, 0, SIZE.x - 1)
			var yy: int = clampi(y + dy, 0, SIZE.y - 1)
			if m[yy * SIZE.x + xx] != v:
				return true
	return false


# ------------------------------------------------------------ star centroids

## Intensity-weighted centroid of the pixels at >= half the window's peak around c.
func _centroid(img: Image, c: Vector2) -> Vector2:
	var peak := 0.0
	var x0 := clampi(int(c.x) - WIN, 0, SIZE.x - 1)
	var x1 := clampi(int(c.x) + WIN, 0, SIZE.x - 1)
	var y0 := clampi(int(c.y) - WIN, 0, SIZE.y - 1)
	var y1 := clampi(int(c.y) + WIN, 0, SIZE.y - 1)
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			peak = maxf(peak, _lum(img.get_pixel(x, y)))
	var s := Vector2.ZERO
	var ws := 0.0
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			var l := _lum(img.get_pixel(x, y))
			if peak > 0.0 and l >= 0.5 * peak:
				s += Vector2(x + 0.5, y + 0.5) * l
				ws += l
	return s / ws if ws > 0.0 else Vector2(-1e6, -1e6)


## A source at beta from h, in the plane of h and world +X.
func _source(beta: float) -> Vector3:
	return (h * cos(beta) + Vector3.RIGHT * sin(beta)).normalized()


## Both images of a star at beta, each rendered with the camera on its CPU direction.
func _images(label: String, r: float, beta: float, fov: float) -> int:
	var fails := 0
	var src := _source(beta)
	var ims := Schwarzschild.star_images(src, h, r)
	var mu_min := minf(ims[0]["mu"], ims[1]["mu"])
	_stars([{"pos": src * 1000.0, "t": 5700.0, "flux": 0.2 / mu_min}])
	var parts := []
	for im: Dictionary in ims:
		var d: Vector3 = im["dir_static"]
		var yp := _yaw_pitch(d)
		_view(fov, yp[0] + 0.0003 * fov * (1 - 2 * im["order"]), yp[1] + 0.00015 * fov)
		_gr_state(r)
		var img := await _grab()
		var want := sky.camera.project(d, Vector2(SIZE))
		var got := _centroid(img, want)
		var err := got.distance_to(want)
		var ok := err <= TOL_STAR
		fails += 0 if ok else 1
		parts.append("order %d psi %.4f deg mu %s: CPU (%.2f, %.2f) GPU (%.2f, %.2f) error %.3f px%s" % [
			im["order"], rad_to_deg(Schwarzschild.angle(d, h)), String.num_scientific(snappedf(im["mu"], 1e-6 * absf(im["mu"]))), want.x, want.y, got.x, got.y, err, "" if ok else " FAIL"])
	print("%s  %s %s; limit %.2f px" % ["ok  " if fails == 0 else "FAIL", label, "; ".join(parts), TOL_STAR])
	return fails


func _gr5() -> int:
	var fails := 0
	sky.background.set_grid(false)
	sky.background.set_exposure(0.0)
	for c in [[10.0, 20.0], [5.0, 60.0], [3.0, 120.0]]:
		fails += await _images("GR5 two images at r = %s, beta %s deg:" % c, c[0], deg_to_rad(c[1]), 70.0)
	return fails


func _gr9() -> int:
	var fails := 0
	sky.background.set_grid(false)
	sky.background.set_exposure(0.0)
	for r in [9e5, 2e6]:
		fails += await _images("GR9 weak-field hand-off at r = %s (%s), beta 0.2 deg, fov 1 deg:" % [r, "lens tables" if r <= Schwarzschild.R_WEAK else "weakDeflectionFinite"], r, deg_to_rad(0.2), 1.0)
	return fails


# ------------------------------------------------------------ GR6 Einstein ring

func _gr6() -> int:
	var fails := 0
	sky.background.set_grid(false)
	sky.background.set_exposure(0.0)
	_view(70.0)
	var f := _focal(70.0)
	for c in [[10.0, 221.088], [100.0, 57.769], [1000.0, 17.539]]:
		_stars([{"pos": h * 1000.0, "t": 5700.0, "flux": 1.0}])
		_gr_state(c[0])
		var ringed := sky.gr_lens.ring.size()
		var img := await _grab()
		var want := f * tan(Schwarzschild.einstein_angle(c[0]))
		var s := 0.0
		var ws := 0.0
		var lo := maxf(want - 15.0, 3.0)
		var hi := want + 15.0
		var bins := PackedFloat64Array()
		bins.resize(36)
		for y in range(int(270.0 - hi) - 1, int(270.0 + hi) + 2):
			for x in range(int(480.0 - hi) - 1, int(480.0 + hi) + 2):
				var v := Vector2(x + 0.5 - 480.0, y + 0.5 - 270.0)
				var rr := v.length()
				if rr >= lo and rr <= hi:
					var l := _lum(img.get_pixel(x, y))
					s += rr * l
					ws += l
					bins[int(fposmod(v.angle(), TAU) / TAU * 36.0) % 36] += l
		var got := s / ws if ws > 0.0 else -1.0
		var err := absf(got - want)
		# a true ring is uniform in azimuth; a splat drawn as well (the ring flag lost) puts its
		# mu-capped images in two bins (measured 8x a bin before the identity-revision fix)
		var mean := ws / 36.0
		var lumpy := (bins[bins.find(_max(bins))] / mean) if mean > 0.0 else INF
		var ok := err <= TOL_SHADOW and ringed == 1 and absf(want - c[1]) < 1e-3 and lumpy < 1.5
		fails += 0 if ok else 1
		print("%s  GR6 Einstein ring at r = %s r_s: flux-weighted radius %.3f px (annulus +-15 px), f tan psi_E = %.3f px (plan %.3f), error %.3f px (limit %.1f); ring-star path %s, brightest of 36 azimuth bins %.3f x the mean (limit 1.5)" % [
			"ok  " if ok else "FAIL", c[0], got, want, c[1], err, TOL_SHADOW, "taken" if ringed == 1 else "NOT taken", lumpy])
	return fails


static func _max(a: PackedFloat64Array) -> float:
	var m := -INF
	for v in a:
		m = maxf(m, v)
	return m


# ------------------------------------------------------------ GR7 black inside, GR8 colour

func _gr7() -> int:
	var r := 5.0
	sky.background.set_grid(false)
	sky.background.set_exposure(20.0) # a bright uniform sky
	_view(70.0)
	_stars([{"pos": h * 1000.0, "t": 5700.0, "flux": 50.0}, {"pos": -h * 1000.0, "t": 5700.0, "flux": 50.0}])
	_gr_state(r)
	var img := await _grab()
	var rin := _focal(70.0) * tan(Schwarzschild.shadow_angle(r)) - 3.0
	var peak := 0.0
	var outside := 0.0
	for y in SIZE.y:
		for x in SIZE.x:
			var rr := Vector2(x + 0.5 - 480.0, y + 0.5 - 270.0).length()
			var l := _lum(img.get_pixel(x, y))
			if rr < rin:
				peak = maxf(peak, l)
			else:
				outside = maxf(outside, l)
	var ok := peak < 0.01 and outside > 1.0
	print("%s  GR7 inside the shadow at r = 5 (bright sky x20, stars behind and astern): peak luminance %.5f (limit 0.01; sky outside peaks at %.2f)" % ["ok  " if ok else "FAIL", peak, outside])
	return 0 if ok else 1


func _gr8() -> int:
	var r := 3.0
	sky.background.set_grid(false)
	sky.background.set_exposure(0.0)
	var src := _source(PI * 0.5)
	var im: Dictionary = Schwarzschild.star_images(src, h, r)[0]
	var d: Vector3 = im["dir_static"]
	var yp := _yaw_pitch(d)
	_view(70.0, yp[0], yp[1])
	_stars([{"pos": src * 1000.0, "t": 5700.0, "flux": 0.3}])
	_gr_state(r)
	var img := await _grab()
	var c := sky.camera.project(d, Vector2(SIZE))
	var s := Vector3.ZERO
	for y in range(int(c.y) - 4, int(c.y) + 5):
		for x in range(int(c.x) - 4, int(c.x) + 5):
			var p := img.get_pixel(x, y)
			s += Vector3(p.r, p.g, p.b)
	var got := s / (s.x + s.y + s.z)
	var e := Blackbody.lut_rgb(5700.0 * Schwarzschild.static_blueshift(r))
	var want := e / (e.x + e.y + e.z)
	var e0 := Blackbody.lut_rgb(5700.0)
	var rest := e0 / (e0.x + e0.y + e0.z)
	var err := maxf(maxf(absf(got.x - want.x), absf(got.y - want.y)), absf(got.z - want.z))
	var ok := err <= 0.01
	print("%s  GR8 colour at r = 3 (D_g = %.5f): rgb chromaticity (%.4f, %.4f, %.4f) vs rgb(%.0f K) (%.4f, %.4f, %.4f), worst %.4f (limit 0.01; unshifted 5700 K would be %.4f off)" % [
		"ok  " if ok else "FAIL", Schwarzschild.static_blueshift(r), got.x, got.y, got.z, 5700.0 * Schwarzschild.static_blueshift(r), want.x, want.y, want.z, err,
		maxf(maxf(absf(got.x - rest.x), absf(got.y - rest.y)), absf(got.z - rest.z))])
	return 0 if ok else 1


# ------------------------------------------------------------ GR10/11 the table mirror

const MIRROR_REL := 2e-5 # the float32 shader against float64, relative to |value| + MIRROR_ABS
const MIRROR_ABS := 1e-8 # rad

static func _bits(c: Color) -> float:
	var u := int(c.r) | (int(c.g) << 11) | (int(c.b) << 22)
	var b := PackedByteArray()
	b.resize(4)
	b.encode_u32(0, u)
	return b.decode_float(0)


func _probe(mode: int) -> Image:
	sky.background.material.set_shader_parameter("gr_probe", mode)
	var img := await _grab()
	sky.background.material.set_shader_parameter("gr_probe", 0)
	return img


## [worst ratio, pixels, where] of the lens_fwd mirror at r, toward and away from the hole.
func _fwd_worst(r: float) -> Array:
	var worst := 0.0
	var at := ""
	var n := 0
	for yaw in [0.0, PI]:
		_view(110.0, yaw, 0.0)
		_gr_state(r)
		var dimg := await _probe(1)
		var pimg := await _probe(2)
		var a := Schwarzschild.shadow_angle(r)
		for y in range(2, SIZE.y, 5):
			for x in range(2, SIZE.x, 5):
				var pc := pimg.get_pixel(x, y)
				if pc.r == 0.0 and pc.g == 0.0 and pc.b == 0.0:
					continue # captured
				var dpsi := _bits(pc)
				var dg := _bits(dimg.get_pixel(x, y))
				var dc := Schwarzschild.deflection(r, a + dpsi)
				var e := absf(dg - dc) / (MIRROR_REL * (MIRROR_ABS + absf(dc)))
				if e > worst:
					worst = e
					at = "psi - alpha %s, delta GPU %s CPU %s" % [dpsi, dg, dc]
				n += 1
	return [worst, n, at]


func _gr10() -> int:
	var fails := 0
	_stars([])
	for r in [2.01, 2.05, 10.0, 3e5, 9.9e5]:
		var w: Array = await _fwd_worst(r)
		var ok: bool = w[0] <= 1.0 and w[1] > 10000
		fails += 0 if ok else 1
		print("%s  GR10 lens_fwd mirror at r = %s: %d pixels toward and away, worst |delta_GPU - delta_CPU| / (%s (|delta| + %s rad)) = %.3f (limit 1) at %s" % ["ok  " if ok else "FAIL", r, w[1], MIRROR_REL, MIRROR_ABS, w[0], w[2]])
	return fails


## GR12: each interpolation rule broken in turn (gr_mutant) must fail the mirror at the radius
## where that rule acts: the table goldens can tell a faithful mirror from a near one.
func _gr12() -> int:
	var fails := 0
	_stars([])
	for c in [[1, "x-linear column weight (rule 2)", 10.0], [2, "repeated first row, no linear ghost (rule 3)", 2.01], [3, "repeated last row, no linear ghost (rule 3)", 9.9e5]]:
		sky.background.material.set_shader_parameter("gr_mutant", c[0])
		var w: Array = await _fwd_worst(c[2])
		sky.background.material.set_shader_parameter("gr_mutant", 0)
		var ok: bool = w[0] > 1.0
		fails += 0 if ok else 1
		print("%s  GR12 mutant %d, %s: GR10 at r = %s reads %.3f of its limit (must exceed 1)" % ["ok  " if ok else "FAIL", c[0], c[1], c[2], w[0]])
	return fails


func _gr11() -> int:
	var fails := 0
	_stars([])
	_view(70.0)
	for r in [2.01, 10.0, 9.9e5, 2e6]:
		_gr_state(r)
		var fimg := await _probe(4)
		var simg := await _probe(3)
		var worst := 0.0
		var at := ""
		var n := 0
		for x in range(0, SIZE.x):
			var f := _bits(fimg.get_pixel(x, SIZE.y / 2))
			if absf(f) < 1e-6 or absf(f) > PI - 1e-6:
				continue
			var psi_g := _bits(simg.get_pixel(x, SIZE.y / 2))
			var psi_c: float = Schwarzschild.image(r, absf(f), 0 if f > 0.0 else 1)["psi"]
			var e := absf(psi_g - psi_c) / (MIRROR_REL * (MIRROR_ABS + psi_c))
			if e > worst:
				worst = e
				at = "F %s, psi GPU %s CPU %s" % [f, psi_g, psi_c]
			n += 1
		var ok := worst <= 1.0 and n > 900
		fails += 0 if ok else 1
		print("%s  GR11 lens_inv mirror at r = %s (%s): %d values of F in (-pi, pi), worst |psi_GPU - psi_CPU| / (%s (psi + %s rad)) = %.3f (limit 1) at %s" % ["ok  " if ok else "FAIL", r, "weak branch" if r > Schwarzschild.R_WEAK else "lens_inv", n, MIRROR_REL, MIRROR_ABS, worst, at])
	return fails
