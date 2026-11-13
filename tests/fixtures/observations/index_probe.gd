extends SceneTree
const Index = preload("res://ui/observation_index.gd")
var failures := 0
var checks := 0
func check(ok: bool, what: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL observation-index: " + what)
func _initialize() -> void:
	var index = Index.new()
	check(index.load_files(), "real index and pack load")
	check(index.objects.size() == 40, "forty actual source rows")
	var id := "DR1_R2:dr1.mer_catalogue_wide_survey:102017310:-524917322525922548"
	check(index.resolve(id) == id, "exact composite identity")
	check(index.resolve("-524917322525922548").is_empty(), "raw nonunique ID is not an alias")
	var row: Dictionary = index.object(id)
	check(row.get("source_id") == "-524917322525922548" and row.get("distance_ly") == null, "long source string and missing distance retained")
	check(not index.plate("abell3128-vis").is_empty(), "source plate linked exactly")
	var facts: Dictionary = row.get("facts",{})
	check(facts.get("ra_deg",{}).get("method")=="measured" and facts.get("point_like_probability",{}).get("method")=="classifier_output", "measured astrometry and classifier probability remain different fact methods")
	check(facts.get("ra_deg",{}).get("epoch")==null and facts.get("distance_ly",{}).get("value")==null, "unknown observation epoch and distance remain null")
	row["name"] = "changed outside index"
	check(index.object(id).get("name", "") != row.name, "returned records are detached")
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/observations/euclid_dr1/objects.json"))
	var pack: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/observations/euclid_dr1/manifest.json"))
	var duplicate := raw.duplicate(true)
	duplicate.objects.append(duplicate.objects[0].duplicate(true))
	check(not index.set_data(duplicate, pack) and index.objects.is_empty(), "duplicate identity fails whole index")
	var explicit := raw.duplicate(true)
	explicit.objects[0].aliases = ["reviewed:source-alias"]
	check(index.set_data(explicit, pack) and index.resolve("reviewed:source-alias") == explicit.objects[0].id, "only explicit alias accepted")
	explicit.objects[1].aliases = ["reviewed:source-alias"]
	check(not index.set_data(explicit, pack), "ambiguous explicit alias refused")
	var malformed := raw.duplicate(true)
	malformed.objects[0].source_id = 524917322525922548.0
	check(not index.set_data(malformed, pack), "numeric source ID rejected")
	malformed = raw.duplicate(true)
	malformed.objects[0].ra_deg = NAN
	check(not index.set_data(malformed, pack), "nonfinite coordinates refused")
	malformed = raw.duplicate(true)
	malformed.objects[0].plate_id = "invented"
	check(not index.set_data(malformed, pack), "missing plate association refused")
	var huge := raw.duplicate(true)
	huge.objects[0].source_id = "-999999999999999999999999999999"
	huge.objects[0].id = "%s:%s:%s:%s" % [huge.release, huge.table, huge.objects[0].tile_id, huge.objects[0].source_id]
	check(index.set_data(huge, pack) and index.resolve(huge.objects[0].id) == huge.objects[0].id, "identifier text is never parsed into a bounded numeric type")
	malformed = raw.duplicate(true)
	malformed.objects[0].flags.vis_det = 7
	check(not index.set_data(malformed, pack), "invalid detection flag refused")
	malformed = raw.duplicate(true)
	malformed.objects[0].point_like_probability = INF
	check(not index.set_data(malformed, pack), "nonfinite optional probability refused")
	var duplicate_plate := pack.duplicate(true)
	duplicate_plate.plates.append(duplicate_plate.plates[0].duplicate(true))
	check(not index.set_data(raw, duplicate_plate), "duplicate source plate refused")
	var missing_facts := raw.duplicate(true)
	missing_facts.objects[0].erase("facts")
	check(not index.set_data(missing_facts,pack),"missing per-fact provenance cannot inherit a row-level measured claim")
	var bad_method := raw.duplicate(true)
	bad_method.objects[0].facts.point_like_probability.method="measured"
	check(not index.set_data(bad_method,pack),"classifier output cannot become a measured fact")
	var wrong_fact_value := raw.duplicate(true)
	wrong_fact_value.objects[0].facts.ra_deg.value += 1.0
	check(not index.set_data(wrong_fact_value,pack),"per-fact value must agree with retained flat astrometry")
	var unsupported := raw.duplicate(true)
	unsupported.format_version = 99
	check(not index.set_data(unsupported, pack), "unsupported index format refused")
	print("observation-index: %d passed, %d failures" % [checks-failures, failures])
	quit(1 if failures else 0)
