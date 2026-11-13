extends RefCounted

# Rendering mirror of sunholo/celestial/projection 0.7.0. Keep expression order
# aligned with that package. Scalars/Arrays retain float64; Vector3 would round
# intermediate coordinates to float32 in the standard Godot build.
# FITS centres are one-based, CD degrees/pixel. No bounds clipping or distortion.

static func _rad(d: float) -> float:
	return d * PI / 180.0

static func _deg(r: float) -> float:
	return r * 180.0 / PI

static func _number(v: Variant) -> bool:
	return (v is float or v is int) and is_finite(float(v))

static func _bounded(v: Variant, limit: float) -> bool:
	return _number(v) and float(v) >= -limit and float(v) <= limit

static func _valid_sky(ra: float, dec: float) -> bool:
	return ra >= 0.0 and ra < 360.0 and _bounded(dec, 90.0)

static func _det(w: Dictionary) -> float:
	return w.cd11 * w.cd22 - w.cd12 * w.cd21

static func valid_wcs(w: Dictionary) -> bool:
	for key in ["crpixX", "crpixY", "crvalRaDeg", "crvalDecDeg", "cd11", "cd12", "cd21", "cd22"]:
		if not _number(w.get(key)):
			return false
	return _bounded(w.crpixX, 1e9) and _bounded(w.crpixY, 1e9) and _valid_sky(w.crvalRaDeg, w.crvalDecDeg) and _bounded(w.cd11, 360.0) and _bounded(w.cd12, 360.0) and _bounded(w.cd21, 360.0) and _bounded(w.cd22, 360.0) and absf(_det(w)) >= 1e-24

static func _unit(ra: float, dec: float) -> Array:
	return [cos(dec) * cos(ra), cos(dec) * sin(ra), sin(dec)]

static func _centre(w: Dictionary) -> Array:
	return _unit(_rad(w.crvalRaDeg), _rad(w.crvalDecDeg))

static func _east(w: Dictionary) -> Array:
	return [-sin(_rad(w.crvalRaDeg)), cos(_rad(w.crvalRaDeg)), 0.0]

static func _north(w: Dictionary) -> Array:
	return [-sin(_rad(w.crvalDecDeg)) * cos(_rad(w.crvalRaDeg)), -sin(_rad(w.crvalDecDeg)) * sin(_rad(w.crvalRaDeg)), cos(_rad(w.crvalDecDeg))]

static func _dot(a: Array, b: Array) -> float:
	return a[0] * b[0] + a[1] * b[1] + a[2] * b[2]

static func _pixel_error(error: String) -> Dictionary:
	return {"ok": false, "x": 0.0, "y": 0.0, "error": error}

static func _sky_error(error: String) -> Dictionary:
	return {"ok": false, "ra_deg": 0.0, "dec_deg": 0.0, "error": error}

static func sky_to_pixel(wcs: Dictionary, ra_deg: float, dec_deg: float) -> Dictionary:
	if not valid_wcs(wcs):
		return _pixel_error("InvalidWcs")
	if not _valid_sky(ra_deg, dec_deg):
		return _pixel_error("InvalidSky")
	var ray := _unit(_rad(ra_deg), _rad(dec_deg))
	var denominator := _dot(ray, _centre(wcs))
	if denominator <= 1e-12:
		return _pixel_error("OutsideTangentHemisphere")
	var xi := _deg(_dot(ray, _east(wcs)) / denominator)
	var eta := _deg(_dot(ray, _north(wcs)) / denominator)
	var determinant := _det(wcs)
	var x: float = wcs.crpixX + (wcs.cd22 * xi - wcs.cd12 * eta) / determinant
	var y: float = wcs.crpixY + (wcs.cd11 * eta - wcs.cd21 * xi) / determinant
	if not _bounded(x, 1e9) or not _bounded(y, 1e9):
		return _pixel_error("InvalidPixel")
	return {"ok": true, "x": x, "y": y, "error": ""}

static func pixel_to_sky(wcs: Dictionary, x: float, y: float) -> Dictionary:
	if not valid_wcs(wcs):
		return _sky_error("InvalidWcs")
	if not _bounded(x, 1e9) or not _bounded(y, 1e9):
		return _sky_error("InvalidPixel")
	var dx: float = x - wcs.crpixX
	var dy: float = y - wcs.crpixY
	var xi := _rad(wcs.cd11 * dx + wcs.cd12 * dy)
	var eta := _rad(wcs.cd21 * dx + wcs.cd22 * dy)
	var centre := _centre(wcs)
	var east := _east(wcs)
	var north := _north(wcs)
	var ray: Array = [centre[0] + (xi * east[0] + eta * north[0]), centre[1] + (xi * east[1] + eta * north[1]), centre[2] + (xi * east[2] + eta * north[2])]
	var longitude := atan2(ray[1], ray[0])
	if longitude < 0.0:
		longitude += 2.0 * PI
	var ra := _deg(longitude)
	if ra >= 360.0:
		ra = 0.0
	var dec := _deg(atan2(ray[2], sqrt(ray[0] * ray[0] + ray[1] * ray[1])))
	return {"ok": true, "ra_deg": ra, "dec_deg": dec, "error": ""}

# Metadata gate for the narrow supported registration; parse/verify FITS upstream.
static func errors(registration: Dictionary) -> PackedStringArray:
	var result := PackedStringArray()
	if registration.get("projection") != "TAN":
		result.append("Only TAN registration is supported")
	if registration.get("frame") != "ICRS":
		result.append("Only ICRS registration is supported")
	if not registration.get("wcs") is Dictionary or not valid_wcs(registration.get("wcs", {})):
		result.append("Invalid TAN WCS")
	for key in ["width", "height"]:
		var value: Variant = registration.get(key)
		if not _number(value) or float(value) < 1.0 or float(value) > 1e9 or floor(float(value)) != float(value):
			result.append("Invalid source image " + key)
	return result

# Source resolution zero-based top-down image centre. Invalid/unregistered data
# returns non-finite coordinates, which callers must omit from picking/drawing.
static func display_point(plate: Dictionary, row: Dictionary) -> Vector2:
	if plate.get("registered") != true or not plate.get("registration") is Dictionary:
		return Vector2(INF, INF)
	var registration: Dictionary = plate.registration
	if not errors(registration).is_empty() or not _number(row.get("ra_deg")) or not _number(row.get("dec_deg")):
		return Vector2(INF, INF)
	if row.has("plate_id") and row.plate_id != plate.get("id"):
		return Vector2(INF, INF)
	var pixel := sky_to_pixel(registration.wcs, row.ra_deg, row.dec_deg)
	if not pixel.ok:
		return Vector2(INF, INF)
	return Vector2(pixel.x - 1.0, float(registration.height) - pixel.y)
