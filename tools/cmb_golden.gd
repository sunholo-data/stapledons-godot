extends RefCounted
## M1.8 forward-CMB goldens (make golden; gate 2): the sky shader's CMB term
## against the CPU, linear tonemapper, on a black panorama so a pixel is the
## CMB alone. main.gd loads this by path (tools/ is not exported).
##   sharp     gamma 707 (1 - beta = 1e-6), PSF off, a 1 deg view: pixels at
##             theta' ~ 0, 1/gamma, 2/gamma read photopicRadiance(T0 D(theta'))
##             (the package mirror, CmbGlow.sharp) within 1%
##   PSF       the same speed through the angular PSF at 70 deg: the pixel next
##             to the pole reads the CPU profile within 1%; the view centre at
##             theta' = 45 deg and the whole frame at 90 deg read exactly 0
##   rest      beta = 0: every pixel of a frame looking ahead is exactly 0

const OMB := 1e-6


func run(main: Node) -> int:
	var failures := 0
	_linear(main.env)
	var sb := _black_sky(main)
	var beta := 1.0 - OMB
	var gamma := Relativity.gamma_of_one_minus_beta(OMB)
	var cam: FreeLookCamera = main.camera
	var fov0 := cam.fov
	# sharp disc: a 1 deg view (Camera3D minimum) resolves the 4.9' core over ~44 px
	cam.fov = 1.0
	cam.look(0.0, 0.0, 0.0)
	sb.set_psf(0.0)
	sb.set_velocity(Vector3(0, 0, -1), beta, gamma)
	var size: Vector2 = main.get_viewport().get_texture().get_size()
	var f := 0.5 * size.y / tan(deg_to_rad(cam.fov) * 0.5)
	for m in [0.0, 1.0, 2.0]:
		var px := Vector2i(int(size.x / 2 + roundf(f * tan(m / gamma))), int(size.y / 2))
		var th := _theta(px, size, f)
		var want := CmbGlow.sharp(th, OMB)
		failures += await _pixel(main, sb, px, want, Relativity.cmb_temperature_apparent(th, OMB), "sharp disc theta' = %.3f/gamma (%.2f arcmin)" % [th * gamma, rad_to_deg(th) * 60.0])
	# through the angular PSF at the production field of view
	cam.fov = fov0
	main._configure_pixel()
	var e: Exposure = main.exposure
	sb.set_psf(e.psf_sigma_rad())
	sb.set_velocity(Vector3(0, 0, -1), beta, gamma)
	size = main.get_viewport().get_texture().get_size()
	f = 0.5 * size.y / tan(deg_to_rad(cam.fov) * 0.5)
	var pole := Vector2i(int(size.x / 2), int(size.y / 2))
	var thp := _theta(pole, size, f)
	failures += await _pixel(main, sb, pole, sb.cmb.profile(thp), Relativity.cmb_temperature_apparent(0.0, OMB), "PSF disc, pixel at theta' = %.2f arcmin (sigma %.1f arcmin, %.2f px)" % [rad_to_deg(thp) * 60.0, rad_to_deg(e.psf_sigma_rad()) * 60.0, e.psf_sigma_px()])
	for deg in [45.0, 90.0]:
		cam.look(deg_to_rad(-deg), 0.0, 0.0) # the view centre theta' = deg off the direction of travel
		failures += await _zero(main, sb, beta, gamma, "theta' = %.0f deg at gamma 707" % deg, deg > 60.0)
	cam.look(0.0, 0.0, 0.0)
	failures += await _zero(main, sb, 0.0, 1.0, "beta = 0, looking ahead", true)
	sb.set_velocity(Vector3(0, 0, -1), 0.0, 1.0)
	return failures


func _linear(env: Environment) -> void:
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.glow_enabled = false


func _black_sky(main: Node) -> SkyBackground:
	var photo := Image.create(64, 32, false, Image.FORMAT_RGB8)
	photo.fill(Color.BLACK)
	var model := Image.create(64, 32, false, Image.FORMAT_RGBA8)
	model.fill(Color8(SkyModel.encode_t(6500.0), 0, 0, 255))
	var sb := SkyBackground.new()
	sb.attach(main.env, main.get_viewport().get_visible_rect().size.y, main.camera.fov, photo, model)
	main.starfield.set_custom_stars([])
	return sb


## theta' of pixel px's centre (camera looking along the direction of travel).
func _theta(px: Vector2i, size: Vector2, f: float) -> float:
	var r := Vector2(px.x + 0.5 - size.x / 2, px.y + 0.5 - size.y / 2).length()
	return atan(r / f)


## The pixel at an exposure that puts the expected radiance's brightest channel
## at linear 0.6 (an orange 770-3850 K blackbody has red > 1 at luminance 0.5,
## and 8 bits would clip it); t sets the colour the brightest channel comes from.
func _pixel(main: Node, sb: SkyBackground, px: Vector2i, want: float, t: float, label: String) -> int:
	var rgb := Blackbody.lut_rgb(t)
	var k := 0.6 / (want * maxf(rgb.x, maxf(rgb.y, rgb.z)))
	sb.set_scene_exposure(k)
	var img: Image = await main._grab()
	var c := img.get_pixel(px.x, px.y).srgb_to_linear()
	var got := (0.2126729 * c.r + 0.7151522 * c.g + 0.0721750 * c.b) / k
	var ok := want > 0.0 and absf(got / want - 1.0) < 0.01
	print("%s  CMB golden: %s renders %s cd/m^2, CPU %s (ratio %.4f, limit 1%%)" % [
		"ok  " if ok else "FAIL", label, String.num_scientific(got), String.num_scientific(want), got / want if want > 0.0 else INF])
	return 0 if ok else 1


## At a huge exposure (1e30 per cd/m^2) the whole frame (or the 9 x 9 pixels
## at the view centre) must be exactly black, as the CPU profile says.
func _zero(main: Node, sb: SkyBackground, beta: float, gamma: float, label: String, whole: bool) -> int:
	sb.set_velocity(Vector3(0, 0, -1), beta, gamma)
	sb.set_scene_exposure(1e30)
	var img: Image = await main._grab()
	var w := img.get_width()
	var h := img.get_height()
	var peak := 0.0
	for y in (range(0, h) if whole else range(h / 2 - 4, h / 2 + 5)):
		for x in (range(0, w) if whole else range(w / 2 - 4, w / 2 + 5)):
			peak = maxf(peak, img.get_pixel(x, y).get_luminance())
	var cam: FreeLookCamera = main.camera
	var cpu := sb.cmb.profile(Relativity.angle_between(cam.view_dir(), Vector3(0, 0, -1)))
	var ok := peak == 0.0 and cpu == 0.0
	print("%s  CMB golden: %s: %s peak %.4f at k = 1e30 (want exactly 0), CPU centre %s" % ["ok  " if ok else "FAIL", label, "frame" if whole else "centre 9x9", peak, String.num_scientific(cpu)])
	return 0 if ok else 1
