extends RefCounted
## Exported-build check that the planet textures are bundled and drawn (make export-smoke):
## `--planet-smoke=PNG` loads every ALBEDO texture through SystemView (the source checkout's
## assets/planets or the export's res://planet_bundle), then draws a textured Jupiter at
## opposition, 8 radii out, filling the view, and writes the frame to PNG. Prints
## "planet-smoke: N/9 textured bodies (<source>)" and exits 1 unless all nine load.
## Lives in planets/ (exported), not tools/ (excluded from exports).

const R_JUP := 71492.0


func run(main: Node, out_png: String) -> int:
	var sv: SystemView = main.system_view
	var loaded := 0
	for id: String in sv.albedo_table:
		loaded += 1 if not sv._textures(id).is_empty() else 0
	var source := "assets/planets" if FileAccess.file_exists(SystemView.TEX_DIR.path_join("2k_jupiter.jpg")) else "res://planet_bundle"
	print("planet-smoke: %d/%d textured bodies (%s)" % [loaded, sv.albedo_table.size(), source])
	var d := R_JUP * 8.0
	var lux := 0.538 * (R_JUP / d) * (R_JUP / d) * 127057.41052085394 / (5.2 * 5.2)
	var b := {"id": "jupiter", "name": "Jupiter", "kind": "planet", "host": "", "status": "confirmed",
		"rel_km": {"x": d, "y": 0.0, "z": 0.0}, "radius_km": R_JUP, "flattening": 0.0,
		"pole": {"x": 0.0, "y": 0.0, "z": 1.0}, "w_deg": 0.0, "sun_dir": {"x": -1.0, "y": 0.0, "z": 0.0},
		"r_au": 5.2, "phase_deg": 0.0, "e_v_lux": lux, "p_v": 0.538, "minnaert_k": 1.0, "ring_id": "",
		"light_age_s": 0.0, "visitable": true, "source": "smoke"}
	main.camera.look(0.0, 0.0, 0.0)
	sv.set_view(main.exposure.pixel_rad, main.get_viewport().get_texture().get_size().y)
	var peak := 0.807 * 127057.41052085394 / (5.2 * 5.2) / PI
	sv.update({"jd": 2460251.5, "ephemeris": "jpl-approx", "frame": "galactic", "bodies": [b]}, 0.25 / peak)
	var mat: ShaderMaterial = sv.discs["jupiter"].material_override
	var textured: bool = mat.get_shader_parameter("textured")
	print("planet-smoke: Jupiter disc %s" % ("textured" if textured else "UNTEXTURED"))
	if out_png != "":
		var img: Image = await main._grab()
		img.save_png(out_png)
		print("planet-smoke: wrote %s" % out_png)
	return 0 if loaded == sv.albedo_table.size() and loaded == 9 and textured else 1
