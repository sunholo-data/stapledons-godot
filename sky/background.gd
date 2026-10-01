class_name SkyBackground
extends RefCounted
## Builds the relativistic sky background (sky/background.gdshader) for an
## Environment. The textures come from `make sky-model` (gitignored, data/raw/);
## without them the sky stays black and the starfield still renders.

const SHADER := preload("res://sky/background.gdshader")
const PHOTO := "res://data/raw/background/noirlab_10k_destarred.png"
const MODEL := "res://data/raw/background/noirlab_10k_skymodel.png"

var material := ShaderMaterial.new()


static func available() -> bool:
	return FileAccess.file_exists(PHOTO) and FileAccess.file_exists(MODEL)


## Attach to env using the given panorama pair (defaults: the NOIRLab model).
func attach(env: Environment, viewport_height: float, fov_deg: float, photo: Image = null, model: Image = null) -> bool:
	if photo == null:
		if not available():
			return false
		photo = Image.load_from_file(ProjectSettings.globalize_path(PHOTO))
		model = Image.load_from_file(ProjectSettings.globalize_path(MODEL))
	photo.generate_mipmaps()
	model.generate_mipmaps()
	material.shader = SHADER
	material.set_shader_parameter("photo", ImageTexture.create_from_image(photo))
	material.set_shader_parameter("model", ImageTexture.create_from_image(model))
	material.set_shader_parameter("t_lo", SkyModel.T_LO)
	material.set_shader_parameter("t_hi", SkyModel.T_HI)
	material.set_shader_parameter("bb_lut", Blackbody.build_lut())
	material.set_shader_parameter("lut_log_tmin", log(Blackbody.LUT_T_MIN))
	material.set_shader_parameter("lut_log_tmax", log(Blackbody.LUT_T_MAX))
	material.set_shader_parameter("pano_px_per_screen_px", photo.get_height() / 180.0 * fov_deg / viewport_height)
	var sky := Sky.new()
	sky.sky_material = material
	sky.radiance_size = Sky.RADIANCE_SIZE_32
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	return true


## Same contract as Starfield.set_velocity: beta, gamma in float64 from the sim.
func set_velocity(direction: Vector3, beta: float, gamma: float) -> void:
	material.set_shader_parameter("beta_dir", direction.normalized())
	material.set_shader_parameter("beta_mag", beta)
	material.set_shader_parameter("gamma_f", gamma)
	material.set_shader_parameter("one_minus_beta", 1.0 / (gamma * gamma * (1.0 + beta)))


func set_exposure(e: float) -> void:
	material.set_shader_parameter("exposure", e)
