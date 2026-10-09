extends RefCounted
## The I-key card for a finite body the sky renderer draws (Sun, planets, moons, finite
## stars, exoplanets). Everything comes from the sim's body record; the source line says
## where the numbers come from and which are assumed.
const AU_KM := 149597870.7
const LY_KM := 9460730472580.8
const R_SUN_KM := 695700.0
const R_EARTH_KM := 6371.0
const R_JUPITER_KM := 69911.0

static func distance_text(km: float) -> String:
	if km < 1.0e6:return "%s km" % _grouped(km)
	if km < 0.01*LY_KM:return "%.3f AU" % (km/AU_KM) if km < 10.*AU_KM else "%.1f AU" % (km/AU_KM)
	return "%.2f ly" % (km/LY_KM)

static func size_text(b: Dictionary) -> String:
	var r: float = b.get("radius_km", 0.)
	if b.get("kind","") == "star":
		var rs := r/R_SUN_KM
		return "%s km radius (%s R☉)" % [_grouped(r), ("%.1f" % rs) if rs >= 10. else (("%.2f" % rs) if rs >= 1. else "%.3f" % rs)]
	if r >= 0.5*R_JUPITER_KM:return "%s km radius (%.2f R♃)" % [_grouped(r), r/R_JUPITER_KM]
	return "%s km radius (%.2f R⊕)" % [_grouped(r), r/R_EARTH_KM]

static func apparent_text(radius_km: float, distance_km: float) -> String:
	var deg := rad_to_deg(2.*Planets.angular_radius(radius_km, distance_km))
	if deg >= 0.1:return "%.2f° across" % deg
	if deg*60. >= 0.1:return "%.1f′ across" % (deg*60.)
	return "%.1f″ across" % (deg*3600.)

static func light_age_text(s: float) -> String:
	if s <= 0.:return ""
	if s < 10.:return "%.2f s" % s
	if s < 120.:return "%.0f s" % s
	if s < 7200.:return "%.1f min" % (s/60.)
	if s < 2.*86400.:return "%.1f h" % (s/3600.)
	if s < 2.*365.25*86400.:return "%.1f days" % (s/86400.)
	return "%.1f years" % (s/(365.25*86400.))

static func kind_text(b: Dictionary) -> String:
	var kind := str(b.get("kind",""))
	var host := str(b.get("host",""))
	if kind == "star":return "Star"
	if not host.is_empty():return "%s of %s" % [kind.capitalize() if not kind.is_empty() else "Body", host]
	return kind.capitalize() if not kind.is_empty() else "Body"

static func text(b: Dictionary, catalogue = null) -> String:
	var dist := Planets.length64(Planets.world_of(b.rel_km))
	var lines := [str(b.get("name", b.id)), kind_text(b)]
	lines.append("Distance from the ship: %s" % distance_text(dist))
	lines.append("Size: %s · %s" % [size_text(b), apparent_text(b.radius_km, dist)])
	if b.get("kind","") == "star" and b.get("teff_k",0.) > 0.:
		lines.append("Surface temperature: %.0f K" % b.teff_k)
	var inferred: Dictionary = b.get("inferred", {}) if b.get("inferred") is Dictionary else {}
	if not inferred.is_empty():
		lines.append(inferred_text(b, inferred))
	var sync := sync_orbit_text(b)
	if not sync.is_empty():lines.append(sync)
	var age := light_age_text(b.get("light_age_s", 0.))
	if not age.is_empty():lines.append("The light you see left it %s ago" % age)
	var cat := str(b.get("catalogue_id",""))
	if not cat.is_empty():
		var shown := cat
		if catalogue != null and catalogue.records.has(cat) and catalogue.display_name(cat) != cat:shown = "%s (%s)" % [catalogue.display_name(cat), cat]
		lines.append("Catalogue: %s" % shown)
	var source := str(b.get("source",""))
	if not source.is_empty():lines.append("Source: %s" % source)
	return "\n".join(lines)

## D-58: a star made finite with an inferred radius (no measurement): the sim's inputs and
## its luminosity, from sunholo/relativity 0.11.0 (the card only formats them).
static func inferred_text(b: Dictionary, inf: Dictionary) -> String:
	return "Radius inferred, not measured: L = %s L☉ from V %.2f at %.2f pc with BC_V %.2f (Teff %.0f K)" % [
		_sig(float(inf.get("l_sun", 0.))), float(inf.get("v", 0.)), float(inf.get("distance_pc", 0.)), float(inf.get("bc_v", 0.)), float(b.get("teff_k", 0.))]

## D-58: the synchronous (stationary) orbit from the sim's sync_orbit record (Kepler's third
## law, sunholo/celestial 0.3.0); "none" with the reason for locked or slow rotators.
static func sync_orbit_text(b: Dictionary) -> String:
	var so = b.get("sync_orbit")
	if not (so is Dictionary):return ""
	var turn := duration_days_text(float(so.get("rotation_days", 0.)))
	match str(so.get("none", "")):
		"locked":
			var host := str(b.get("host", ""))
			return "Synchronous orbit: none. %s is tidally locked%s (it turns once per orbit), so a stationary orbit would lie beyond its Hill sphere" % [str(b.get("name", b.id)), (" to " + host.capitalize()) if not host.is_empty() else ""]
		"slow":
			return "Synchronous orbit: none. It turns once in %s, so a stationary orbit would be %s from its centre, beyond its Hill sphere (%s)" % [turn, distance_text(float(so.get("radius_km", 0.))), distance_text(float(so.get("hill_km", 0.)))]
	return "Synchronous orbit: %s above the surface (%s from the centre; one turn in %s)" % [distance_text(float(so.get("altitude_km", 0.))), distance_text(float(so.get("radius_km", 0.))), turn]

static func duration_days_text(days: float) -> String:
	if days <= 0.:return "unknown"
	if days < 2.:return "%.2f h" % (days * 24.)
	return "%.2f days" % days

static func _sig(x: float) -> String:
	if x >= 100.:return "%.0f" % x
	if x >= 1.:return "%.2f" % x
	var digits := clampi(int(ceil(-log(x) / log(10.))) + 2, 2, 12)
	return ("%." + str(digits) + "f") % x

static func _grouped(x: float) -> String:
	var s := "%d" % int(round(x))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length()-3) + out
		s = s.substr(0, s.length()-3)
	return s + out
