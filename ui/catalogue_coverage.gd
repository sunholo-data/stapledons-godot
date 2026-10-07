extends RefCounted
## Destination coverage comes from the loaded catalogue, centred on Sol.
## It is not a claim that every visible star has surveyed planets.
static func summary(catalogue:Dictionary)->String:
	if not catalogue.has("radius_pc") or not catalogue.has("count"):return "Destination catalogue coverage unavailable"
	return "%d known destinations · within %.0f pc of Sol" % [int(catalogue.count),float(catalogue.radius_pc)]
## The ship's sky stack, when one is loaded (Starfield.last_loaded).
static func sky_line(loaded:Dictionary)->String:
	if loaded.is_empty():return ""
	var what:="all GCNS stars within 100 pc" if loaded.tier=="large" else ("the 50,000 nearest GCNS stars" if loaded.tier=="medium" else "the CNS5 stars")
	return "\nShip sky: %s tier, %d stars drawn (%s, plus CNS5 and bright Hipparcos stars)" % [loaded.tier,int(loaded.count),what]
static func details(catalogue:Dictionary)->String:
	return summary(catalogue)+sky_line(Starfield.last_loaded)+"\nReal catalogue stars are available outside this destination list.\nPlanet and system information may be unknown.\nThe distant sky image is an approximation beyond about 50 light-years from Sol."
