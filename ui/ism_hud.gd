class_name IsmHud
extends RefCounted
## I7: formatting only. Densities, rates, dust totals and route lengths are sim fields.
## In particular expected/window_s is NOT a rate under compressed pacing.

static func supported(view: Dictionary) -> bool:
	var ism: Variant = GalaxyMap.field_value(view, "ship.ism")
	return ism is Dictionary and ism.get("model", "") == "lism-1" and not str(ism.get("medium", "")).is_empty() and ism.has("n_h_cm3")


static func medium_name(name: String) -> String:
	if name == "LIC": return "the Local Interstellar Cloud"
	if name == "hot": return "the Local Bubble’s hot gas"
	return name + " cloud"


static func density_text(n: float) -> String:
	return "%s cm⁻³ · %s H atoms/L" % [GalaxyMap.sci(n), GalaxyMap.sci(n * 1000.0)]


static func impact_text(ism: Dictionary) -> String:
	var dust: Dictionary = ism.get("dust", {})
	var rate := "—" if not dust.has("visible_rate") else GalaxyMap.sci(float(dust.visible_rate))
	return "%s/ship-s\nLargest this leg: %.2f µm · %s J" % [rate, float(dust.get("largest_um", 0.0)), GalaxyMap.sci(float(dust.get("largest_j", 0.0)))]


static func route_text(media: Array) -> String:
	return "\n".join(media.map(func(m): return "%s · %.3f ly" % [medium_name(str(m.get("name", ""))), float(m.get("length_ly", 0.0))]))


## Clip the sim's ordered route lengths to the sim's before/after travelled distances.
## This is display slicing, not a medium/position or physics calculation in Godot.
static func skipped_media(before: Dictionary, after: Dictionary) -> Array:
	var lo: float = float(before.get("distance_ly", 0.0)) - float(before.get("distance_remaining_ly", 0.0))
	var hi: float = float(after.get("distance_ly", 0.0)) - float(after.get("distance_remaining_ly", 0.0))
	var cursor := 0.0
	var rows: Array = []
	for m: Dictionary in before.get("ism_media", []):
		var end: float = cursor + float(m.get("length_ly", 0.0))
		var length := maxf(0.0, minf(end, hi) - maxf(cursor, lo))
		if length > 1e-9: rows.append({"name": m.get("name", ""), "length_ly": length})
		cursor = end
	return rows


static func interlude_text(before: Dictionary, after: Dictionary) -> String:
	if before.get("ism_model", "") != "lism-1": return ""
	var rows := skipped_media(before, after)
	if rows.is_empty(): return ""
	var grains := maxf(0.0, float(after.get("ism_grains", 0.0)) - float(before.get("ism_grains", 0.0)))
	return "Media crossed during cruise:\n%s\nGrains swept (≥ 1 µm): %s\nLargest this leg: %.2f µm · %s J" % [route_text(rows), GalaxyMap.sci(grains), float(after.get("ism_largest_um", 0.0)), GalaxyMap.sci(float(after.get("ism_largest_j", 0.0)))]
