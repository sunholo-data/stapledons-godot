extends RefCounted
## Read-only known catalogue facts, keyed by exact producer ID.
var records := {}
var names := {}
func load_files(path := "res://data/starmap/stars.json", name_path := "res://data/starmap/names.json") -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	set_records(data.get("stars", []))
	var labels: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(name_path))
	for row in labels.get("names", []):
		if records.has(row.get("id", "")) and not names.has(row.id):names[row.id] = row.name
func set_records(rows: Array) -> void:
	records.clear(); names.clear()
	var duplicates := {}
	for row in rows:
		var id: String = row.get("id", "")
		if records.has(id):duplicates[id] = true
		elif not id.is_empty():records[id] = row.duplicate(true)
	for id in duplicates:records.erase(id)
func display_name(id: String) -> String:
	return names.get(id, id)
static func catalogue_subtitle(row: Dictionary) -> String:
	return "%s  ·  %.2f ly" % [row.id,float(row.dist_ly)] if row.has("dist_ly") else "%s · distance unavailable" % row.id
func text(id: String) -> String:
	if not records.has(id):return "Catalogue information unavailable"
	var row: Dictionary = records[id]
	var title := display_name(id)+"\n"+id if display_name(id)!=id else id
	return "%s\nCatalogue distance from Sol: %s\nCatalogue temperature: %s\nCatalogue V magnitude: %s" % [title,
		("%.3f ly" % row.dist_ly) if row.has("dist_ly") else "unavailable",
		("%.0f K" % row.teff) if row.get("teff", 0.) > 0. else "unavailable",
		("%.2f" % row.vmag) if row.has("vmag") and row.vmag < 99. else "unavailable"]
