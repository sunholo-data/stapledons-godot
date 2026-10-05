extends RefCounted
## Destination coverage comes from the loaded catalogue, centred on Sol.
## It is not a claim that every visible star has surveyed planets.
static func summary(catalogue:Dictionary)->String:
	if not catalogue.has("radius_pc") or not catalogue.has("count"):return "Destination catalogue coverage unavailable"
	return "%d known destinations · within %.0f pc of Sol" % [int(catalogue.count),float(catalogue.radius_pc)]
static func details(catalogue:Dictionary)->String:
	return summary(catalogue)+"\nReal catalogue stars are available outside this destination list.\nPlanet and system information may be unknown.\nThe distant sky image is an approximation beyond about 50 light-years from Sol."
