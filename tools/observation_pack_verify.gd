extends SceneTree
const Pack = preload("res://tools/observation_pack.gd")
const Fits = preload("res://tools/observation_fits.gd")
const ProjectionMath = preload("res://physics/observation_projection.gd")

static func header_errors(pack: Dictionary) -> Array[String]:
	var errors: Array[String] = []
	for plate in pack.get("plates",[]):
		if not plate is Dictionary or not plate.get("registered") is bool:
			errors.append("invalid plate registration status")
			continue
		if not plate.registered:continue
		var id := str(plate.get("id",""))
		if RegEx.create_from_string("^[A-Za-z0-9_-]+$").search(id) == null:
			errors.append("invalid science plate identity")
			continue
		var source := "res://data/raw/observations/%s/source.fits" % id
		if not FileAccess.file_exists(source) or FileAccess.get_sha256(source) != plate.get("source_sha256",""):
			errors.append(id+": missing/changed pinned science FITS")
			continue
		var decoded := Fits.decode(FileAccess.get_file_as_bytes(source))
		if not decoded.get("ok",false):
			errors.append(id+": unsupported science FITS: "+str(decoded.get("error","unavailable")))
			continue
		if not plate.get("registration") is Dictionary:
			errors.append(id+": missing registration")
			continue
		for error in Fits.registration_errors(decoded.header,plate.registration):errors.append(id+": "+error)
	return errors

static func scientific_errors(pack: Dictionary, object_data: Dictionary) -> Array[String]:
	var errors := header_errors(pack)
	var plates := {}
	for plate in pack.get("plates",[]):
		if plate is Dictionary and plate.get("registered",false):plates[plate.get("id","")]=plate
	if object_data.get("format_version") != 1 or not object_data.get("objects") is Array or object_data.get("objects",[]).is_empty():
		errors.append("missing full object index for registered-footprint verification")
		return errors
	var seen := {}
	for row in object_data.objects:
		if not row is Dictionary or not row.get("id") is String or row.id.is_empty() or seen.has(row.id):
			errors.append("invalid/duplicate source identity in full object index")
			continue
		seen[row.id]=true
		var context: String = row.id
		if not plates.has(row.get("plate_id","")):
			errors.append(context+": source must explicitly reference a registered field")
			continue
		if not _number(row.get("ra_deg")) or not _number(row.get("dec_deg")):
			errors.append(context+": nonfinite source coordinates")
			continue
		var registration = plates[row.plate_id].get("registration")
		if not registration is Dictionary or not registration.get("wcs") is Dictionary:
			errors.append(context+": missing supported field registration")
			continue
		var pixel := ProjectionMath.sky_to_pixel(registration.wcs,float(row.ra_deg),float(row.dec_deg))
		var width = registration.get("width")
		var height = registration.get("height")
		if not pixel.ok or not _number(width) or not _number(height):
			errors.append(context+": source cannot project into registered field")
		elif pixel.x < 0.5-1e-6 or pixel.x > float(width)+0.5+1e-6 or pixel.y < 0.5-1e-6 or pixel.y > float(height)+0.5+1e-6:
			errors.append(context+": source outside registered FITS image footprint")
	return errors

static func _number(value) -> bool:
	return (value is float or value is int) and is_finite(float(value))

func _init() -> void:
	var path := "res://data/observations/euclid_dr1/manifest.json"
	var headers_only := false
	var args := OS.get_cmdline_user_args()
	var i := 0
	while i < args.size():
		if args[i] == "--headers-only":headers_only=true
		elif args[i] == "--pack" and i+1 < args.size():i+=1;path=args[i]
		else:printerr("observation-pack-verify: unsupported argument");quit(1);return
		i+=1
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	if not parsed is Dictionary:
		printerr("observation-pack-verify: missing or invalid manifest")
		quit(1)
		return
	var errors: Array[String]
	var object_count := 0
	if headers_only:errors=header_errors(parsed)
	else:
		errors=Pack.errors(parsed)
		var object_ref = parsed.get("objects_index")
		var object_data = JSON.parse_string(FileAccess.get_file_as_string(object_ref)) if object_ref is String and FileAccess.file_exists(object_ref) else null
		if not object_data is Dictionary:errors.append("missing full object index")
		else:
			errors.append_array(scientific_errors(parsed,object_data))
			object_count=object_data.get("objects",[]).size()
	for error in errors:printerr("FAIL ",error)
	if headers_only:print("observation-source-verify: %d plates, %d failures" % [parsed.get("plates",[]).size(),errors.size()])
	else:print("observation-pack-verify: %d plates, %d objects, %d failures" % [parsed.get("plates",[]).size(),object_count,errors.size()])
	quit(1 if not errors.is_empty() else 0)
