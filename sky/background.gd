class_name SkyBackground
extends RefCounted
## Builds the relativistic sky background (sky/background.gdshader) for an
## Environment. The textures come from `make sky-assets` (gitignored, data/raw/);
## without them the sky stays black and the starfield still renders.
##
## Exported builds: data/raw/ carries a .gdignore, and Godot's export skips
## .gdignore'd directories, so `make export-macos` stages byte copies into
## res://sky_bundle/ as *.png.bin. The .bin suffix keeps the editor from importing
## (VRAM-compressing) them, so they reach the .pck untouched; they are decoded
## here from the PNG bytes.

const SHADER := preload("res://sky/background.gdshader")
const PHOTO := "res://data/raw/background/noirlab_10k_destarred.png"
const MODEL := "res://data/raw/background/noirlab_10k_skymodel.png"
const BUNDLED_PHOTO := "res://sky_bundle/noirlab_10k_destarred.png.bin"
const BUNDLED_MODEL := "res://sky_bundle/noirlab_10k_skymodel.png.bin"

## M1.5a scene units: the shader's linear output times cdm2_per_unit is cd/m^2.
## attach() sets it so the panorama's dark-sky patch (median of the galactic
## caps |b| >= DARK_CAP_DEG) reads Exposure.DARK_SKY_MAG: a robust statistic of
## the sky, not of particular texture bytes, so a regenerated panorama recalibrates.
##
## The NOIRLab panorama is a tone-stretched photograph, not a radiometric map:
## its PEAK_QUANTILE luminance is ~290x its dark patch (6.2 mag), where the real
## Milky Way's brightest integrated light is ~2.7 mag above the 23.5 mag/arcsec^2
## deep-space dark sky. So the photo's luminance is un-stretched with one power
## law that keeps chromaticity, anchored at two points (D-25): the dark patch ->
## Exposure.DARK_SKY_MAG and the PEAK_QUANTILE -> MILKY_WAY_MAG:
##   L = L(dark) x (Y / Y_dark)^stretch,
##   stretch = min(1, 0.4 (23.5 - 20.8) ln 10 / ln(Y_peak / Y_dark))   (0.43 on the NOIRLab photo)
## A photo with less contrast than that (synthetic goldens) keeps stretch = 1.
const DARK_CAP_DEG := 70.0
## V mag/arcsec^2 of the brightest Milky Way (D-25): integrated starlight from
## stars fainter than 6.5 mag peaks at a few hundred S10(V) toward Sgr/Sct/Car
## (Leinert et al. 1998, A&AS 127, 1, Table 16); Duriscoe 2013 (PASP 125, 1370)
## models the same natural-sky Milky Way component.
const MILKY_WAY_MAG := 20.8
const PEAK_QUANTILE := 0.999
const METER_GRID := Vector2i(16, 9)
const METER_MIP := 4 # the CPU copy for calibration and metering: 1/16 of the panorama (at most)

var material := ShaderMaterial.new()
var cmb := CmbGlow.new() # M1.8: the forward CMB disc, drawn in the same exposure
var psf_sigma := 0.0 # rad, the angular PSF the CMB profile is blurred with (Exposure.psf_sigma_rad)
var cdm2_per_unit := 1.0
var dark_patch_y := 1.0 # linear luminance of the photo's dark-sky patch
var peak_y := 1.0 # linear luminance at PEAK_QUANTILE (equal-area)
var stretch := 1.0 # luminance exponent (see above)
var _w := 0
var _h := 0
var _y := PackedFloat32Array() # linear photo luminance per CPU texel
var _t := PackedFloat32Array() # T_c per CPU texel
var _logy := PackedFloat32Array() # log10 Y on the shader's LUT grid


static func available() -> bool:
	return not _paths().is_empty()


## [photo, model] of the first complete pair: the source checkout's data/raw,
## then the export bundle. Empty when neither is there.
static func _paths() -> Array:
	for pair in [[PHOTO, MODEL], [BUNDLED_PHOTO, BUNDLED_MODEL]]:
		if FileAccess.file_exists(pair[0]) and FileAccess.file_exists(pair[1]):
			return pair
	return []


static func _load_png(path: String) -> Image:
	var img := Image.new()
	return img if img.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) == OK else null


## Attach to env using the given panorama pair (defaults: the NOIRLab model).
func attach(env: Environment, viewport_height: float, fov_deg: float, photo: Image = null, model: Image = null) -> bool:
	if photo == null:
		var paths := _paths()
		if paths.is_empty():
			return false
		# res:// paths read through FileAccess, so the same code reads the .pck
		photo = _load_png(paths[0])
		model = _load_png(paths[1])
		if photo == null or model == null:
			push_error("sky background: failed to decode %s / %s" % paths)
			return false
	photo.generate_mipmaps()
	model.generate_mipmaps()
	var lut := Blackbody.build_lut()
	_cpu_copy(photo, model, lut.get_image())
	material.shader = SHADER
	material.set_shader_parameter("photo", ImageTexture.create_from_image(photo))
	material.set_shader_parameter("model", ImageTexture.create_from_image(model))
	material.set_shader_parameter("t_lo", SkyModel.T_LO)
	material.set_shader_parameter("t_hi", SkyModel.T_HI)
	material.set_shader_parameter("bb_lut", lut)
	material.set_shader_parameter("y_dark", dark_patch_y)
	material.set_shader_parameter("stretch", stretch)
	material.set_shader_parameter("lut_log_tmin", log(Blackbody.LUT_T_MIN))
	material.set_shader_parameter("lut_log_tmax", log(Blackbody.LUT_T_MAX))
	material.set_shader_parameter("pano_px_per_screen_px", photo.get_height() / 180.0 * fov_deg / viewport_height)
	material.set_shader_parameter("cmb_size", CmbGlow.PROFILE_SIZE)
	material.set_shader_parameter("screen_px_rad", deg_to_rad(fov_deg) / viewport_height)
	var sky := Sky.new()
	sky.sky_material = material
	sky.radiance_size = Sky.RADIANCE_SIZE_32
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	return true


## Same contract as Starfield.set_velocity: beta, gamma in float64 from the sim.
## The CMB profile is rebuilt when gamma has moved by more than 0.5%.
func set_velocity(direction: Vector3, beta: float, gamma: float) -> void:
	var omb := 1.0 / (gamma * gamma * (1.0 + beta))
	material.set_shader_parameter("beta_dir", direction.normalized())
	material.set_shader_parameter("beta_mag", beta)
	material.set_shader_parameter("gamma_f", gamma)
	material.set_shader_parameter("one_minus_beta", omb)
	if cmb.needs_build(omb, psf_sigma):
		cmb.build(omb, psf_sigma)
		material.set_shader_parameter("cmb_profile", cmb.texture)
		material.set_shader_parameter("cmb_theta_max", cmb.theta_max)


## M3.5a: the sim's gr section (sky/gr_lens.gd) -> the lensed sky; empty switches GR off.
## Under GR the SR uniforms carry the motion relative to the local static observer
## (gr.dir_local, beta_local, gamma_local, one_minus_beta_local), all from the sim, and the
## forward CMB is not drawn (the shader skips it under gr_on).
func set_gr(gr: Dictionary) -> void:
	if gr.is_empty() or not gr.has("r") or GrLens.textures().is_empty():
		material.set_shader_parameter("gr_on", false)
		return
	var u := GrLens.uniforms(gr)
	for k: String in u:
		material.set_shader_parameter(k, u[k])
	set_local_motion(gr)


## The SR uniforms under GR: the motion relative to the local static observer (the sim's).
func set_local_motion(gr: Dictionary) -> void:
	material.set_shader_parameter("beta_dir", GrLens._world(gr["dir_local"]))
	material.set_shader_parameter("beta_mag", gr["beta_local"])
	material.set_shader_parameter("gamma_f", gr["gamma_local"])
	material.set_shader_parameter("one_minus_beta", gr["one_minus_beta_local"])


## The debug grid in place of the panorama (golden background, design M3.5 step 4).
func set_grid(on: bool) -> void:
	material.set_shader_parameter("grid_on", on)


## The angular PSF (rad) the CMB disc is drawn through; 0 draws it sharp.
func set_psf(sigma_rad: float) -> void:
	psf_sigma = sigma_rad


## Raw multiplier on the photo's linear values (goldens).
func set_exposure(e: float) -> void:
	material.set_shader_parameter("exposure", e)


## Photometric exposure: k is linear pixel per cd/m^2 (Exposure.k()).
func set_scene_exposure(k: float) -> void:
	set_exposure(k * cdm2_per_unit)
	material.set_shader_parameter("cmb_k", k)


static func _mip(img: Image, level: int) -> Image:
	var lv := mini(level, img.get_mipmap_count())
	var w := maxi(img.get_width() >> lv, 1)
	var h := maxi(img.get_height() >> lv, 1)
	var a := img.get_mipmap_offset(lv)
	var b := img.get_mipmap_offset(lv + 1) if lv < img.get_mipmap_count() else img.get_data().size()
	return Image.create_from_data(w, h, false, img.get_format(), img.get_data().slice(a, b))


func _cpu_copy(photo: Image, model: Image, lut: Image) -> void:
	# at least 64 rows, so small (synthetic) panoramas still have cap rows
	var lv := clampi(int(floor(log(photo.get_height() / 64.0) / log(2.0))), 0, METER_MIP)
	var p := _mip(photo, lv)
	var m := _mip(model, mini(lv, model.get_mipmap_count()))
	_w = p.get_width()
	_h = p.get_height()
	_y.resize(_w * _h)
	_t.resize(_w * _h)
	var cap := []
	var sky := []
	for j in _h:
		var b := absf(90.0 - 180.0 * (j + 0.5) / _h)
		var step := maxi(1, roundi(1.0 / maxf(cos(deg_to_rad(b)), 1e-3))) # ~equal-area sampling
		for i in _w:
			var c := p.get_pixel(i, j).srgb_to_linear()
			var y := 0.2126729 * c.r + 0.7151522 * c.g + 0.0721750 * c.b
			_y[j * _w + i] = y
			_t[j * _w + i] = SkyModel.decode_t(roundi(m.get_pixel(mini(i * m.get_width() / _w, m.get_width() - 1), mini(j * m.get_height() / _h, m.get_height() - 1)).r * 255.0))
			if i % step == 0:
				sky.append(y)
				if b >= DARK_CAP_DEG:
					cap.append(y)
	cap.sort()
	sky.sort()
	dark_patch_y = maxf(cap[cap.size() / 2] if not cap.is_empty() else 1.0, 1e-6)
	peak_y = maxf(sky[int(PEAK_QUANTILE * (sky.size() - 1))] if not sky.is_empty() else dark_patch_y, dark_patch_y)
	var want := 0.4 * (Exposure.DARK_SKY_MAG - MILKY_WAY_MAG) * log(10.0)
	stretch = minf(1.0, want / log(peak_y / dark_patch_y)) if peak_y > dark_patch_y else 1.0
	cdm2_per_unit = Exposure.dark_sky_luminance() / dark_patch_y
	_logy.resize(lut.get_width())
	for i in lut.get_width():
		_logy[i] = lut.get_pixel(i, 0).a


func _log10_y(t: float) -> float:
	var x := clampf(Blackbody.lut_u(t) * _logy.size() - 0.5, 0.0, _logy.size() - 1.0)
	var i := mini(int(x), _logy.size() - 2)
	return lerpf(_logy[i], _logy[i + 1], x - i)


## Seen luminance (cd/m^2) of the sky in apparent direction n_ship: the CPU
## mirror of the shader's luminance, nearest CPU texel.
func seen_luminance(n_ship: Vector3, dir: Vector3, beta: float) -> float:
	var n := Relativity.deaberrate(n_ship, dir, beta)
	var d := Relativity.doppler_apparent(n_ship, dir, beta) if beta > 0.0 else 1.0
	var uv := SkyModel.equirect_uv(n)
	var k := clampi(int(uv.y * _h), 0, _h - 1) * _w + clampi(int(uv.x * _w), 0, _w - 1)
	var t: float = _t[k]
	return unstretched(_y[k]) * cdm2_per_unit * pow(10.0, _log10_y(t * d) - _log10_y(t))


## The photo luminance y after the un-stretch, in photo units (y_dark fixed).
func unstretched(y: float) -> float:
	return dark_patch_y * pow(maxf(y, 0.0) / dark_patch_y, stretch)


## Log-average seen luminance over a METER_GRID of the camera's view (the
## camera mode's meter): exp(mean ln(L + 1e-9 cd/m^2)). The eye meters with
## sky/sky_meter.gd, which also sees the stars and the CMB.
func meter(cam: FreeLookCamera, dir: Vector3, beta: float) -> float:
	var half_v := tan(deg_to_rad(cam.fov) * 0.5)
	var vp := cam.get_viewport().get_visible_rect().size if cam.is_inside_tree() else Vector2(16, 9)
	var half_h := half_v * vp.x / vp.y
	var acc := 0.0
	for j in METER_GRID.y:
		for i in METER_GRID.x:
			var x := (2.0 * (i + 0.5) / METER_GRID.x - 1.0) * half_h
			var y := (1.0 - 2.0 * (j + 0.5) / METER_GRID.y) * half_v
			acc += log(seen_luminance(cam.to_world(Vector3(x, y, -1.0).normalized()), dir, beta) + 1e-9)
	return exp(acc / (METER_GRID.x * METER_GRID.y))
