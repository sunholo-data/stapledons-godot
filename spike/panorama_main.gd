extends "res://main.gd"
## Review scene until M1.2d ships the HIP2 bright tier: main.gd's voyage and
## production sky background (sky/background.gdshader, M1.4c), plus the stars
## removed from the panorama (HIP V<7.5 beyond CNS5's 25 pc) as relativistic points.
##   godot --path . --resolution 1920x1080 res://spike/panorama.tscn -- --capture=<abs dir>
## Needs `make sky-model` outputs and data/raw/hip_v7.tsv. Spike only: B-V -> T uses
## Ballesteros (2012) here, ahead of teffFromBV in sunholo/relativity 0.4.0 (M1.2d).

const HIP := "res://data/raw/hip_v7.tsv"
const STAR_EXPOSURE := 40.0 # review balance with BG_PREVIEW; M1.5 calibrates both
const BG_PREVIEW := 0.6


func _ready() -> void:
	_build_scene()
	background.set_exposure(BG_PREVIEW)
	# M1.3: quick tier (CNS5) from the binary loader; HIP fluxes are V-relative, so
	# the tier's lux E_v are rescaled to the same units by the exposure split.
	starfield.load_tiers("quick")
	var hip := _hip_stars()
	for h in hip:
		h["flux"] *= Relativity.illuminance_from_v(0.0)
	starfield.append_stars(hip)
	starfield.build()
	starfield.set_exposure(STAR_EXPOSURE / Relativity.illuminance_from_v(0.0))
	starfield.material.set_shader_parameter("psf_sigma_px", 1.2)
	if not sim.start():
		get_tree().quit(2)
		return
	_apply_state()
	var args := _user_args()
	if args.has("capture"):
		await _run_capture(args["capture"])


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
