extends RefCounted
## Shared read-only inspection facts. Typed references preserve producer identities;
## archive epochs and catalogue facts never become a live simulated body.
const BodyInfo = preload("res://ui/body_info.gd")
const StarInfo = preload("res://ui/star_info.gd")

static func facts(reference: Dictionary, index, star_info, world: Dictionary) -> Dictionary:
	var id := str(reference.get("id", ""))
	var kind := str(reference.get("kind", ""))
	var result := {"available":false,"id":id,"reference":reference.duplicate(true),"title":"Information unavailable","kind":kind,"primary":[],"sections":[],"sources":[],"image_available":false,"plate_id":"","live_body_id":"","provenance":"unavailable"}
	if id.is_empty():return result
	if kind == "catalogue":
		if star_info == null or not star_info.records.has(id):return result
		var clean: Dictionary = star_info.records[id].duplicate(true)
		if not _number(clean.get("dist_ly")) or float(clean.dist_ly) < 0.:clean.erase("dist_ly")
		if not _number(clean.get("teff")) or float(clean.teff) <= 0.:clean.erase("teff")
		if not _number(clean.get("vmag")):clean.erase("vmag")
		var safe = StarInfo.new()
		safe.set_records([clean])
		safe.names[id] = star_info.display_name(id)
		result.title = safe.display_name(id)
		result.available = true
		result.provenance = "catalogue"
		result.primary.append({"label":"Kind","value":"Catalogue star"})
		result.sections.append({"title":"Catalogue","text":safe.text(id)})
		_add_live(result, live_body(reference, world, star_info), star_info)
		result.sections.append({"title":"Survey image","text":"No survey image associated with this catalogue object."})
	elif kind == "body":
		var body := live_body(reference, world, star_info)
		if body.is_empty():return result
		result.available = true
		result.title = str(body.get("name", id))
		result.provenance = str(body.get("status", "simulated"))
		result.primary.append({"label":"Kind","value":BodyInfo.kind_text(body)})
		_add_live(result, body, star_info)
		result.sections.append({"title":"Survey image","text":"No survey image associated with this live body."})
	elif kind == "survey":
		if index == null:return result
		var source: Dictionary = index.object(id)
		if source.is_empty():return result
		result.available = true
		result.id = str(source.get("id",id))
		result.title = str(source.get("name",result.id))
		result.provenance = str(source.get("provenance","measured"))
		var classification := "Survey source; classification unavailable"
		if source.get("kind", "survey_source") != "survey_source":
			classification = str(source.kind).capitalize()
			if source.get("status", "") == "candidate":classification += " candidate"
		result.primary.append({"label":"Kind","value":classification})
		result.primary.append({"label":"Provenance","value":str(result.provenance)})
		var lines: Array[String] = [classification]
		if _number(source.get("ra_deg")) and _number(source.get("dec_deg")):
			lines.append("ICRS coordinates: RA %.8f°, Dec %.8f°" % [source.ra_deg,source.dec_deg])
		lines.append("Distance: %s" % (("%.3f ly" % source.distance_ly) if _number(source.get("distance_ly")) and float(source.distance_ly) >= 0. else "unavailable"))
		# Keep the absence unmistakable when read independently of the section heading.
		if not _number(source.get("distance_ly")):lines.append("Distance unavailable; no light age is assigned.")
		if _number(source.get("redshift")):lines.append("Redshift: %s (published; no distance conversion)" % str(source.redshift))
		result.sections.append({"title":"Published survey facts","text":"\n".join(lines)})
		var quality: Array[String] = []
		if _number(source.get("point_like_probability")):quality.append("Point-like probability: %s; this probability does not assign an object classification." % str(source.point_like_probability))
		var flags: Dictionary = source.get("flags",{}) if source.get("flags") is Dictionary else {}
		var flag_names := flags.keys()
		flag_names.sort()
		for key in flag_names:
			if _number(flags[key]):quality.append("%s: %s" % [key,str(flags[key])])
		if not quality.is_empty():result.sections.append({"title":"Catalogue quality","text":"\n".join(quality)})
		_add_source(result,"Catalogue",str(source.get("source_url","")))
		var plate_id := str(source.get("plate_id",""))
		var plate: Dictionary = index.plate(plate_id)
		if not plate.is_empty():
			result.plate_id = plate_id
			result.image_available = plate.get("levels",[]) is Array and not plate.get("levels",[]).is_empty()
			var observation: Array[String] = ["Band: %s" % str(plate.get("band","unavailable")),"Observation start: %s" % str(plate.get("observation_start","unavailable"))]
			if plate.has("observation_end"):observation.append("Observation end: %s" % plate.observation_end)
			observation.append("Registered celestial image" if plate.get("registered",false) else "Unregistered image; no celestial overlay")
			observation.append("Licence: %s" % str(plate.get("licence","unavailable")))
			observation.append("Credit: %s" % str(plate.get("credit","unavailable")))
			result.sections.append({"title":"Survey observation","text":"\n".join(observation)})
			_add_source(result,"Survey image",str(plate.get("source_url","")))
		if not result.image_available:result.sections.append({"title":"Survey image","text":"No survey image available for this source."})
	return result

static func text(reference: Dictionary, index, star_info, world: Dictionary) -> String:
	var record := facts(reference,index,star_info,world)
	if not record.available:return "Information unavailable"
	var lines: Array[String] = [record.title,record.id]
	for row in record.primary:lines.append("%s: %s" % [row.label,row.value])
	for section in record.sections:lines.append("%s\n%s" % [section.title,section.text])
	for source in record.sources:lines.append("%s: %s" % [source.label,source.url])
	return "\n\n".join(lines)

## Exact identity only: no name, proximity, probability or alias-based live matching.
static func live_body(reference: Dictionary, world: Dictionary, star_info = null) -> Dictionary:
	var id := str(reference.get("id",""))
	var kind := str(reference.get("kind",""))
	if id.is_empty() or kind not in ["body","catalogue"]:return {}
	if kind == "catalogue" and (star_info == null or not star_info.records.has(id)):return {}
	var system: Dictionary = world.get("system",{}) if world.get("system") is Dictionary else {}
	var bodies: Array = system.get("bodies",[]) if system.get("bodies") is Array else []
	var matches: Array[Dictionary] = []
	for body in bodies:
		if not body is Dictionary:continue
		if (kind == "body" and body.get("id","") == id) or (kind == "catalogue" and body.get("kind","") == "star" and body.get("catalogue_id","") == id):matches.append(body)
	if matches.size() != 1 or not _usable_body(matches[0]):return {}
	return matches[0].duplicate(true)

static func _add_live(result: Dictionary, body: Dictionary, star_info) -> void:
	if body.is_empty():return
	result.live_body_id = str(body.id)
	var safe := body.duplicate(true)
	for key in ["teff_k","light_age_s"]:
		if not _number(safe.get(key)):safe.erase(key)
	var inferred = safe.get("inferred")
	if inferred is Dictionary:
		var valid := _number(inferred.get("l_sun")) and float(inferred.get("l_sun",0.)) > 0.
		for key in ["v","distance_pc","bc_v"]:valid = valid and _number(inferred.get(key))
		if not valid:safe.erase("inferred")
	var orbit = safe.get("sync_orbit")
	if orbit is Dictionary:
		for value in orbit.values():
			if (value is float or value is int) and not _number(value):safe.erase("sync_orbit")
	var body_text := BodyInfo.text(safe,star_info)
	if body.get("kind","") == "star":body_text += "\nStellar surface appearance is modelled."
	result.sections.append({"title":"From the ship now","text":body_text})

static func _usable_body(body: Dictionary) -> bool:
	if not body.get("id") is String or body.id.is_empty():return false
	if not _number(body.get("radius_km")) or float(body.radius_km) <= 0.:return false
	var position = body.get("rel_km")
	if not position is Dictionary:return false
	for axis in ["x","y","z"]:
		if not _number(position.get(axis)):return false
	return is_finite(Planets.length64(Planets.world_of(position)))

static func _number(value) -> bool:
	return (value is float or value is int) and is_finite(float(value))

static func _add_source(result: Dictionary, label: String, url: String) -> void:
	if not url.is_empty():result.sources.append({"label":label,"url":url})
