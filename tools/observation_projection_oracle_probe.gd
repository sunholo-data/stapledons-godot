extends SceneTree

const Fits = preload("res://tools/observation_fits.gd")
const ProjectionMath = preload("res://physics/observation_projection.gd")

# Test-only transport. All reference maths and FITS decoding live in the
# independent Python oracle, never in this Godot adapter.
func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		printerr("Expected one oracle request JSON path")
		quit(1)
		return
	var request: Variant = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	if not request is Dictionary or not request.get("cases") is Array:
		printerr("Invalid oracle request")
		quit(1)
		return
	var results: Array = []
	for row: Dictionary in request.cases:
		var result: Dictionary
		if row.op == "sky":
			result = ProjectionMath.sky_to_pixel(row.wcs, row.a, row.b)
			if request.get("probe_fault") == "half-pixel" and result.ok:
				result.x += 0.5
		else:
			result = ProjectionMath.pixel_to_sky(row.wcs, row.a, row.b)
			result.oracle_sky_inverse = ProjectionMath.sky_to_pixel(row.wcs, row.oracle_ra, row.oracle_dec)
		results.append(result)
	var wcs := {"crpixX": 1.0, "crpixY": 1.0, "crvalRaDeg": 0.0, "crvalDecDeg": 0.0, "cd11": 1.0, "cd12": 0.0, "cd21": 0.0, "cd22": 1.0}
	var singular := wcs.duplicate()
	singular.cd11 = 0.0
	var rejected := [
		ProjectionMath.sky_to_pixel(wcs, NAN, 0.0).error == "InvalidSky",
		ProjectionMath.pixel_to_sky(wcs, INF, 0.0).error == "InvalidPixel",
		ProjectionMath.sky_to_pixel(singular, 0.0, 0.0).error == "InvalidWcs",
		ProjectionMath.sky_to_pixel(wcs, 180.0, 0.0).error == "OutsideTangentHemisphere"
	]
	var header_accepted: Array = []
	for row: Dictionary in request.get("header_cases",[]):
		header_accepted.append(Fits.registration_errors(row.header,row.registration).is_empty())
	print("OBSERVATION_ORACLE_JSON:", JSON.stringify({"results": results, "rejected": rejected, "header_accepted": header_accepted}, "", true, true))
	quit()
