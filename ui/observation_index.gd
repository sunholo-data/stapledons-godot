extends RefCounted
## R3-TELESCOPE: pinned catalogue facts, never a navigation target registry.
## Euclid object_id is not globally unique. Only exact release/table/tile/source
## identities and explicitly supplied unambiguous aliases resolve here.
const OBJECTS_PATH := "res://data/observations/euclid_dr1/objects.json"
const MANIFEST_PATH := "res://data/observations/euclid_dr1/manifest.json"
var objects: Dictionary = {}
var plates: Dictionary = {}
var aliases: Dictionary = {}
var manifest: Dictionary = {}
var version := ""
var last_error := ""
# Originals never alias the mutable public lookup dictionaries. A snapshot is
# reconstructed from these records, not from records a UI caller may have edited.
var _source_objects: Dictionary = {}
var _source_manifest: Dictionary = {}
var _objects_sha256 := ""
var _manifest_sha256 := ""

func _clear() -> void:
	objects.clear()
	plates.clear()
	aliases.clear()
	manifest.clear()
	version = ""
	_source_objects.clear()
	_source_manifest.clear()
	_objects_sha256 = ""
	_manifest_sha256 = ""

func _fail(reason: String) -> bool:
	_clear()
	last_error = reason
	return false

func load_files(object_path := OBJECTS_PATH, manifest_path := MANIFEST_PATH) -> bool:
	_clear()
	last_error = ""
	if not FileAccess.file_exists(object_path) or not FileAccess.file_exists(manifest_path):
		return _fail("Observation source file missing")
	# Hash the same byte buffers that are parsed, rather than reading twice and
	# risking content changing between parsing and a separate file hash call.
	var object_bytes := FileAccess.get_file_as_bytes(object_path)
	var manifest_bytes := FileAccess.get_file_as_bytes(manifest_path)
	var raw: Variant = JSON.parse_string(object_bytes.get_string_from_utf8())
	var pack: Variant = JSON.parse_string(manifest_bytes.get_string_from_utf8())
	if not raw is Dictionary or not pack is Dictionary:
		return _fail("Observation source JSON invalid")
	if not set_data(raw, pack):return false
	_objects_sha256 = _hash_bytes(object_bytes)
	_manifest_sha256 = _hash_bytes(manifest_bytes)
	return true

func set_data(data: Dictionary, pack: Dictionary) -> bool:
	_clear()
	last_error = ""
	if data.get("format_version") != 1 or pack.get("format_version") != 1:
		return _fail("Observation source version unsupported")
	if not pack.get("id") is String or pack.id.strip_edges().is_empty():
		return _fail("Observation pack identity missing or empty")
	if not data.get("objects") is Array or not pack.get("plates") is Array:
		return _fail("Observation records or plates missing")
	if not data.get("release") is String or not data.get("table") is String:
		return _fail("Observation release/table missing")
	var release: String = data.release
	var table: String = data.table
	if release.is_empty() or table.is_empty():return _fail("Observation release/table empty")
	for value: Variant in pack.plates:
		if not value is Dictionary or not value.get("id") is String:
			return _fail("Observation plate identity invalid")
		var id: String = value.id
		if id.is_empty() or plates.has(id):return _fail("Observation plate identity duplicate or empty")
		plates[id] = value.duplicate(true)
	for value: Variant in data.objects:
		if not value is Dictionary or not _valid_object(value, release, table):
			return _fail("Observation object record invalid")
		var id: String = value.id
		if objects.has(id):return _fail("Observation object identity duplicate")
		if not plates.has(value.plate_id):return _fail("Observation object plate unavailable")
		objects[id] = value.duplicate(true)
	if objects.is_empty():return _fail("Observation source has no objects")
	for value: Dictionary in objects.values():
		var declared: Variant = value.get("aliases", [])
		if not declared is Array:return _fail("Observation aliases must be explicit strings")
		for alias: Variant in declared:
			if not alias is String or not _add_alias(alias, value.id):return _fail("Observation alias ambiguous or invalid")
	var declared: Variant = pack.get("aliases", {})
	if not declared is Dictionary:return _fail("Observation manifest aliases invalid")
	for alias: Variant in declared:
		var target: Variant = declared[alias]
		if not alias is String or not target is String or not objects.has(target) or not _add_alias(alias, target):
			return _fail("Observation manifest alias ambiguous or invalid")
	manifest = pack.duplicate(true)
	version = pack.id
	_source_objects = data.duplicate(true)
	_source_manifest = pack.duplicate(true)
	# Sorted keys at every nesting level, full float64 precision, no whitespace.
	_objects_sha256 = JSON.stringify(_source_objects, "", true, true).sha256_text()
	_manifest_sha256 = JSON.stringify(_source_manifest, "", true, true).sha256_text()
	return true

static func _hash_bytes(bytes: PackedByteArray) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(bytes)
	return context.finish().hex_encode()

func pin() -> Dictionary:
	if version.is_empty() or manifest.get("id") != version or _source_manifest.get("id") != version or _objects_sha256.is_empty() or _manifest_sha256.is_empty():
		return {}
	return {"id": version, "manifest_sha256": _manifest_sha256, "objects_sha256": _objects_sha256}

func snapshot() -> RefCounted:
	if pin().is_empty():return null
	var isolated: Variant = get_script().new()
	if not isolated.set_data(_source_objects.duplicate(true), _source_manifest.duplicate(true)):
		return null
	# set_data deliberately computes canonical JSON hashes. File-backed indexes
	# must instead preserve their original exact-byte identity across snapshots.
	isolated._objects_sha256 = _objects_sha256
	isolated._manifest_sha256 = _manifest_sha256
	return isolated

func _add_alias(alias: String, target: String) -> bool:
	if alias.is_empty() or alias != alias.strip_edges():return false
	if objects.has(alias):return alias == target
	if aliases.has(alias) and aliases[alias] != target:return false
	aliases[alias] = target
	return true

static func _finite_number(value: Variant) -> bool:
	return (value is float or value is int) and is_finite(float(value))

static func _integer_text(value: String, signed: bool) -> bool:
	var digits := value.substr(1) if signed and value.begins_with("-") else value
	if digits.is_empty():return false
	for i in digits.length():
		if digits.unicode_at(i) < 48 or digits.unicode_at(i) > 57:return false
	return true

static func _valid_object(row: Dictionary, release: String, table: String) -> bool:
	for key in ["id", "source_id", "tile_id", "plate_id"]:
		if not row.get(key) is String or row[key].is_empty():return false
	if row.get("namespace") != "euclid" or row.get("kind") != "survey_source":return false
	if not _integer_text(row.source_id, true) or not _integer_text(row.tile_id, false):return false
	if row.id != "%s:%s:%s:%s" % [release, table, row.tile_id, row.source_id]:return false
	if not _finite_number(row.get("ra_deg")) or not _finite_number(row.get("dec_deg")):return false
	if float(row.ra_deg) < 0.0 or float(row.ra_deg) >= 360.0 or absf(float(row.dec_deg)) > 90.0:return false
	var direction: Variant = row.get("galactic")
	if not direction is Dictionary:return false
	for key in ["x", "y", "z"]:
		if not _finite_number(direction.get(key)):return false
	var probability: Variant = row.get("point_like_probability")
	if probability != null and (not _finite_number(probability) or float(probability) < 0.0 or float(probability) > 1.0):return false
	var flags: Variant = row.get("flags")
	if not flags is Dictionary:return false
	for key in ["vis_det", "extended_flag", "spurious_flag", "det_quality_flag"]:
		if not flags.has(key):return false
		var flag: Variant = flags[key]
		if flag != null and (not _finite_number(flag) or float(flag) < 0.0 or float(flag) > 2147483647.0 or float(flag) != floor(float(flag))):return false
	if flags.vis_det != null and float(flags.vis_det) != 0.0 and float(flags.vis_det) != 1.0:return false
	return _valid_facts(row)

static func _valid_facts(row: Dictionary) -> bool:
	if not row.get("facts") is Dictionary or not row.get("source_url") is String or row.source_url.is_empty():return false
	var expected := {"ra_deg":[row.ra_deg,"deg","measured",row.source_url],"dec_deg":[row.dec_deg,"deg","measured",row.source_url],"galactic":[row.galactic,"unit_direction","derived_frame_rotation",row.source_url],"point_like_probability":[row.get("point_like_probability"),"probability","classifier_output",row.source_url],"distance_ly":[row.get("distance_ly"),"ly","unavailable",null],"redshift":[row.get("redshift"),"dimensionless","unavailable",null]}
	for key in ["vis_det","extended_flag","spurious_flag","det_quality_flag"]:
		expected[key]=[row.flags[key],"bitmask" if key=="det_quality_flag" else "flag","quality_metadata",row.source_url]
	for key in expected:
		var fact = row.facts.get(key)
		var spec: Array = expected[key]
		if not fact is Dictionary or not fact.has("value") or fact.value != spec[0] or fact.get("unit") != spec[1] or fact.get("method") != spec[2] or not fact.has("source") or fact.source != spec[3] or not fact.has("epoch"):return false
		if fact.method == "unavailable" and fact.value != null:return false
		if fact.epoch != null and (not fact.epoch is String or fact.epoch.strip_edges().is_empty()):return false
	return true

func resolve(id: String) -> String:
	if objects.has(id):return id
	return str(aliases.get(id, ""))

func object(id: String) -> Dictionary:
	return objects.get(resolve(id), {}).duplicate(true)

func plate(id: String) -> Dictionary:
	return plates.get(id, {}).duplicate(true)
