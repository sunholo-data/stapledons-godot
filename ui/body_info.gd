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

static func _grouped(x: float) -> String:
	var s := "%d" % int(round(x))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length()-3) + out
		s = s.substr(0, s.length()-3)
	return s + out
