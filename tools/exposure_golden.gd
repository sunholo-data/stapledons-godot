extends RefCounted
## M1.5a exposure goldens (make golden) and the AC8 limiting-magnitude ladder
## (make golden and make bench). main.gd loads this by path: tools/ is not
## exported. Each check renders through the real shaders and reads the frame.
##   display floor   the production chain (AgX + glow, 8-bit sRGB) shows a uniform
##                   linear Exposure.DISPLAY_FLOOR as VIS_LEVELS, and 0.85 x it below
##   star lux        a known-lux star's splat integrates to E k / Omega_px (linear
##                   tonemapper) within 1%
##   sky cd/m^2      a calibrated panorama's dark patch renders at L(DARK_SKY_MAG) k within 1%
##   AC8 ladder      V 5.0-8.5 stars on the 23.5 mag/arcsec^2 sky at the default
##                   dark-adapted EV: the faintest run of visible stars, inside Exposure.AC8

const LADDER_V0 := 5.0
const LADDER_V1 := 8.5
const LADDER_STEP := 0.1
const AC8 := Exposure.AC8


func run(main: Node) -> int:
	var failures := 0
	failures += await _display_floor(main)
	failures += await _star_lux(main)
	failures += await _sky_luminance(main)
	var r: Dictionary = await limiting_magnitude(main)
	var ok: bool = r["v_lim"] >= AC8.x and r["v_lim"] <= AC8.y
	print("%s  limiting magnitude %s" % ["ok  " if ok else "FAIL", r["line"]])
	return failures + (0 if ok else 1)


func _uniform_sky(main: Node, grey: float) -> SkyBackground:
	var photo := Image.create(64, 32, false, Image.FORMAT_RGB8)
	photo.fill(Color(grey, grey, grey))
	var model := Image.create(64, 32, false, Image.FORMAT_RGBA8)
	model.fill(Color8(SkyModel.encode_t(6500.0), 0, 0, 255))
	var sb := SkyBackground.new()
	sb.attach(main.env, main.get_viewport().get_visible_rect().size.y, main.camera.fov, photo, model)
	sb.set_velocity(Vector3(0, 0, -1), 0.0, 1.0)
	return sb


func _production(env: Environment) -> void:
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.glow_enabled = true
	env.glow_bloom = 0.05
	env.glow_hdr_threshold = 1.0


func _linear(env: Environment) -> void:
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.glow_enabled = false


func _centre_level(img: Image) -> float:
	return roundf(img.get_pixel(img.get_width() / 2, img.get_height() / 2).get_luminance() * 255.0)


func _display_floor(main: Node) -> int:
	_production(main.env)
	main.starfield.set_custom_stars([])
	var sb := _uniform_sky(main, 1.0) # white photo: linear output = exposure
	sb.set_exposure(Exposure.DISPLAY_FLOOR)
	var at := _centre_level(await main._grab())
	sb.set_exposure(0.85 * Exposure.DISPLAY_FLOOR)
	var below := _centre_level(await main._grab())
	var ok := at >= Exposure.VIS_LEVELS and below < Exposure.VIS_LEVELS
	print("%s  display floor: linear %.4f shows %d/255 (want >= %d), 0.85x shows %d/255 (want < %d), AgX + glow" % [
		"ok  " if ok else "FAIL", Exposure.DISPLAY_FLOOR, at, Exposure.VIS_LEVELS, below, Exposure.VIS_LEVELS])
	return 0 if ok else 1


func _exposure_for(main: Node) -> Exposure:
	var e := Exposure.new()
	e.configure(main.camera.fov, main.get_viewport().get_texture().get_size().y)
	return e


## A star at the view centre at the default dark-adapted EV, bright enough
## (V 1.0) that no channel clips: the 21 x 21 window sum of linear pixels is
## E_v k / Omega_px (the splat integrates to the star's illuminance).
func _star_lux(main: Node) -> int:
	_linear(main.env)
	main.env.background_mode = Environment.BG_COLOR
	main.env.background_color = Color.BLACK
	main.camera.look(0.0, 0.0, 0.0)
	var e := _exposure_for(main)
	var lux := Relativity.illuminance_from_v(1.0)
	main.starfield.set_custom_stars([{"pos": Vector3(0, 0, -1000.0), "t": 6500.0, "flux": lux}])
	main.starfield.set_ship_position(0.0, 0.0, 0.0)
	main.starfield.set_velocity(Vector3(0, 0, -1), 0.0, 1.0)
	main.starfield.set_floor(Vector2.ZERO)
	main.starfield.set_exposure(e.star_scale())
	main.starfield.set_psf(e.psf_sigma_px())
	var img: Image = await main._grab()
	var c: Vector3 = main._window_sum(img)
	var got := 0.2126729 * c.x + 0.7151522 * c.y + 0.0721750 * c.z
	var want := lux * e.k() / e.pixel_sr
	var ok := absf(got / want - 1.0) < 0.01
	print("%s  exposure golden (star): V 1.0 = %s lux at EV %+.3f, splat sum %.4f, want E k / Omega_px = %.4f (ratio %.4f, limit 1%%)" % [
		"ok  " if ok else "FAIL", String.num_scientific(lux), e.ev, got, want, got / want])
	main.starfield.set_custom_stars([])
	return 0 if ok else 1


## The panorama calibration end to end: a uniform panorama is its own dark
## patch, so it must read L(DARK_SKY_MAG); with k = 0.5 / L the pixel is 0.5.
func _sky_luminance(main: Node) -> int:
	_linear(main.env)
	main.camera.look(0.0, 0.0, 0.0)
	var sb := _uniform_sky(main, 0.37)
	var l_dark := Exposure.dark_sky_luminance()
	sb.set_scene_exposure(0.5 / l_dark)
	var img: Image = await main._grab()
	var c := img.get_pixel(img.get_width() / 2, img.get_height() / 2).srgb_to_linear()
	var got := (0.2126729 * c.r + 0.7151522 * c.g + 0.0721750 * c.b) / 0.5 * l_dark
	var ok := absf(got / l_dark - 1.0) < 0.01
	print("%s  exposure golden (sky): calibrated dark patch renders %s cd/m^2, want L(%.1f mag/arcsec^2) = %s (ratio %.4f, limit 1%%)" % [
		"ok  " if ok else "FAIL", String.num_scientific(got), Exposure.DARK_SKY_MAG, String.num_scientific(l_dark), got / l_dark])
	return 0 if ok else 1


## AC8: the ladder on a uniform DARK_SKY_MAG sky, production tonemapper, the
## default eye mode at the dark-adapted EV. Stars sit on pixel centres in a
## compact block at the view centre (cos^3 < 0.5%). A star is visible when its
## peak 8-bit luminance stands VIS_LEVELS above the frame's background level.
func limiting_magnitude(main: Node) -> Dictionary:
	_production(main.env)
	var cam: FreeLookCamera = main.camera
	cam.look(0.0, 0.0, 0.0)
	var size: Vector2 = main.get_viewport().get_texture().get_size()
	var e := _exposure_for(main)
	e.update(Exposure.dark_sky_luminance())
	var sb := _uniform_sky(main, 0.37)
	sb.set_scene_exposure(e.k())
	var f := 0.5 * size.y / tan(deg_to_rad(cam.fov) * 0.5)
	var stars := []
	var spots := []
	var n := int(round((LADDER_V1 - LADDER_V0) / LADDER_STEP)) + 1
	for i in n:
		var px := Vector2i(int(size.x / 2) + (i % 6 - 3) * 24, int(size.y / 2) + (i / 6 - 2) * 24)
		var dir := cam.to_world(Vector3((px.x + 0.5 - size.x / 2) / f, -(px.y + 0.5 - size.y / 2) / f, -1.0).normalized())
		stars.append({"pos": dir * 1000.0, "t": 5800.0, "flux": Relativity.illuminance_from_v(LADDER_V0 + i * LADDER_STEP)})
		spots.append(px)
	main.starfield.set_custom_stars(stars)
	main.starfield.set_ship_position(0.0, 0.0, 0.0)
	main.starfield.set_velocity(Vector3(0, 0, -1), 0.0, 1.0)
	main.starfield.set_floor(Vector2.ZERO)
	main.starfield.set_exposure(e.star_scale())
	main.starfield.set_psf(e.psf_sigma_px())
	var img: Image = await main._grab()
	var bgs := []
	for k in 200: # background: a ring of pixels well outside the block
		var a := TAU * k / 200.0
		bgs.append(roundf(img.get_pixel(int(size.x / 2 + 200 * cos(a)), int(size.y / 2 + 150 * sin(a))).get_luminance() * 255.0))
	bgs.sort()
	var bg: float = bgs[100]
	var v_lim := LADDER_V0 - LADDER_STEP
	var levels := []
	var run := true
	for i in n:
		var peak := 0.0
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				peak = maxf(peak, roundf(img.get_pixel(spots[i].x + dx, spots[i].y + dy).get_luminance() * 255.0))
		levels.append(int(peak - bg))
		if run and peak - bg >= Exposure.VIS_LEVELS:
			v_lim = LADDER_V0 + i * LADDER_STEP
		else:
			run = false
	main.starfield.set_custom_stars([])
	var model := Relativity.limiting_magnitude(Exposure.dark_sky_luminance(), Exposure.FIELD_FACTOR)
	var line := "V_lim %.1f measured in the rendered frame (%dx%d, EV %+.2f dark-adapted, PSF %.1f arcmin = %.2f px, sky %d/255 = linear %s; ladder V %.1f-%.1f step %.1f, visible = peak >= %d levels above sky; levels above sky %s); Crumey model F = %.0f: %.3f; AC8 %.1f <= V_lim <= %.1f" % [
		v_lim, size.x, size.y, e.ev, rad_to_deg(e.psf_sigma_rad()) * 60.0, e.psf_sigma_px(), bg, String.num_scientific(Exposure.dark_sky_luminance() * e.k()), LADDER_V0, LADDER_V1, LADDER_STEP, Exposure.VIS_LEVELS, str(levels), Exposure.FIELD_FACTOR, model, AC8.x, AC8.y]
	return {"v_lim": v_lim, "model": model, "ev": e.ev, "line": line}
