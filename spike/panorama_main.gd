extends "res://main.gd"
## M1.4a PREVIEW (D-10): main.gd's 1 g voyage, with the destarred NOIRLab panorama
## as a relativistic sky and the stars removed from it (HIP V<7.5) put back as
## relativistic point sources next to CNS5.
##   godot --path . --resolution 1920x1080 res://spike/panorama.tscn -- --capture=<abs dir>
## Needs data/raw/background/noirlab_10k_destarred.png (tools/m14a_destar.py) and
## data/raw/hip_v7.tsv. Spike only: B-V -> T uses Ballesteros (2012) here, ahead of
## teffFromBV in sunholo/relativity 0.4.0 (M1.2d); nothing merges from this file.

const PANORAMA := "res://data/raw/background/noirlab_10k_destarred.png"
const HIP := "res://data/raw/hip_v7.tsv"
const BG_EXPOSURE := 0.6
const STAR_EXPOSURE := 40.0 # preview balance only; M1.5 calibrates both

var sky_mat := ShaderMaterial.new()


func _ready() -> void:
	_build_scene()
	starfield.load_catalogue("res://data/starmap/stars.json")
	starfield.stars.append_array(_hip_stars())
	starfield.build()
	starfield.set_exposure(STAR_EXPOSURE)
	starfield.material.set_shader_parameter("psf_sigma_px", 1.2)
	if not sim.start():
		get_tree().quit(2)
		return
	_apply_state()
	var args := _user_args()
	if args.has("capture"):
		await _run_capture(args["capture"])


func _build_scene() -> void:
	super()
	var img := Image.load_from_file(ProjectSettings.globalize_path(PANORAMA))
	img.generate_mipmaps()
	sky_mat.shader = preload("res://spike/panorama_sky.gdshader")
	sky_mat.set_shader_parameter("panorama", ImageTexture.create_from_image(img))
	sky_mat.set_shader_parameter("bb_lut", Blackbody.build_lut())
	sky_mat.set_shader_parameter("lut_log_tmin", log(Blackbody.LUT_T_MIN))
	sky_mat.set_shader_parameter("lut_log_tmax", log(Blackbody.LUT_T_MAX))
	sky_mat.set_shader_parameter("exposure", BG_EXPOSURE)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	sky.radiance_size = Sky.RADIANCE_SIZE_32
	for c in get_children():
		if c is WorldEnvironment:
			var env: Environment = c.environment
			env.background_mode = Environment.BG_SKY
			env.sky = sky
			env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
			env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	# panorama pixels per screen pixel at rest (camera fov is vertical)
	var vh := float(get_viewport().get_visible_rect().size.y)
	sky_mat.set_shader_parameter("pano_px_per_screen_px", img.get_height() / 180.0 * camera.fov / vh)


func _apply_state() -> void:
	super()
	var s := sim.state
	var h: Dictionary = s["heading"]
	var beta: float = s["beta"]
	var gamma: float = s["gamma"]
	sky_mat.set_shader_parameter("beta_dir", Vector3(h["x"], h["y"], h["z"]).normalized())
	sky_mat.set_shader_parameter("beta_mag", beta)
	sky_mat.set_shader_parameter("gamma_f", gamma)
	sky_mat.set_shader_parameter("one_minus_beta", 1.0 / (gamma * gamma * (1.0 + beta)))


## Hipparcos V<7.5 beyond CNS5's 25 pc (CNS5 already carries the nearer ones).
func _hip_stars() -> Array:
	var out := []
	var f := FileAccess.open(HIP, FileAccess.READ)
	while not f.eof_reached():
		var p := f.get_line().split("\t")
		if p.size() < 6 or not p[0].strip_edges().is_valid_int() or p[2].strip_edges() == "":
			continue
		var plx := p[5].to_float()
		if plx > 40.0:
			continue
		var d_ly := 3261.56 / plx if plx > 0.3 else 3261.56 / 0.3
		var l := deg_to_rad(p[2].to_float())
		var b := deg_to_rad(p[3].to_float())
		var g := Vector3(cos(b) * cos(l), cos(b) * sin(l), sin(b)) * d_ly
		var bv := p[4].to_float() if p[4].strip_edges() != "" else 0.65
		var t := 4600.0 * (1.0 / (0.92 * bv + 1.7) + 1.0 / (0.92 * bv + 0.62))
		out.append({"name": "HIP " + p[0].strip_edges(), "pos": Starfield.galactic_to_world(g),
			"t": t, "flux": Relativity.flux_from_mag(p[1].to_float())})
	return out
