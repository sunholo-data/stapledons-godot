class_name ForwardGlow
extends RefCounted
## M4.2 forward glow (design m4-first-journey.md "M4.2", higgs-bubble.md §6). CPU reference
## for interior/glow_overlay.gdshader, float64.
##
## Physics. A fraction eps of the ISM kinetic flux K becomes light at the bubble wall, and
## f_in of it shines inward. The wall element whose outward normal is at angle theta from the
## direction of travel (ship frame, +Z) shines
##     E(theta) = eps f_in K max(0, cos theta)       (W/m^2, inward emittance)
## which is sunholo/relativity medium.glowEmittanceAt (0.7.0). The sim emits the pole value
## ship.ism.glow_pole_w_m2 = glowEmittanceAt(..., 1.0); Godot only mirrors the shape:
##     profile(pole, cos theta) = pole x clamp(cos theta, 0, 1)      (NaN stays NaN)
## so the brightness comes from the sim, never from GDScript physics.
##
## The wall is a Lambertian emitter (M4.6a eval N3): radiance L = E / pi (W m^-2 sr^-1).
## Luminance (cd/m^2) = L x LM_PER_W, and the sky camera's photometric exposure (M1.5a,
## Exposure.k(), the one the stars and the background use) turns it into a pixel. No gain.
##
## The ray from the panorama camera (inside the bubble, not at its centre) leaves the sphere
## of radius R at the wall point P; cos theta = P.z / R. wall_cos() solves that in float64.
##
## SPECTRUM: higgs-bubble.md §6 does not give the glow's spectrum. Until Mark rules, the glow
## is taken as equal-energy white over 380-780 nm (CIE illuminant E): efficacy
## 683 lm/W x mean ybar over the band, from the package's CIE fit (tools/glow_probe), and the
## colour of illuminant E in linear sRGB (Y = 1). Both are named here so a ruling is a
## one-line change.

## 683 x (sum of blackbody.cmf(l).y, 380..780 nm at 1 nm, trapezoid) / 400 (tools/glow_probe).
const LM_PER_W := 182.5654375783963
## CIE illuminant E (X = Y = Z) in linear sRGB (IEC 61966-2-1 matrix): luminance Y = 1.
const WHITE_RGB := Vector3(1.2047843, 0.9483008, 0.9088427)
## The sim's field (M4.1 step 2 / M4.6a). Absent until that lands: the glow is then off.
const POLE_FIELD := "glow_pole_w_m2"


## The angular profile: glowEmittanceAt's shape, given the sim's pole value (W/m^2).
## cos_theta is clamped to [0, 1] like the package (a dot product rounding past 1 is the
## pole, the aft hemisphere is 0); NaN propagates (ailang#1419 parity).
static func profile(pole_w_m2: float, cos_theta: float) -> float:
	if is_nan(cos_theta):
		return cos_theta
	return pole_w_m2 * clampf(cos_theta, 0.0, 1.0)


## Lambertian wall: emittance (W/m^2) -> radiance (W m^-2 sr^-1).
static func radiance(emittance_w_m2: float) -> float:
	return emittance_w_m2 / PI


## Emittance (W/m^2) -> luminance seen on the wall (cd/m^2).
static func luminance(emittance_w_m2: float) -> float:
	return radiance(emittance_w_m2) * LM_PER_W


## cos(theta) of the wall point a ray from `cam` (ship frame, metres) along unit `dir` (ship
## frame) leaves the bubble of radius r through. NaN when the camera is not inside the bubble.
static func wall_cos(cam: PackedFloat64Array, dir: PackedFloat64Array, r: float) -> float:
	var c2 := cam[0] * cam[0] + cam[1] * cam[1] + cam[2] * cam[2]
	if not (r > 0.0) or c2 >= r * r:
		return NAN
	var b := cam[0] * dir[0] + cam[1] * dir[1] + cam[2] * dir[2]
	var t := -b + sqrt(b * b + (r * r - c2)) # the positive root: the exit point ahead
	return (cam[2] + t * dir[2]) / r


## The sim's pole emittance, or -1.0 when the state carries none (the glow is off and the HUD
## says so). Never derived here from glow_w_m2: the sim owns that number.
static func pole_of(world: Dictionary) -> float:
	var ship: Variant = world.get("ship")
	if not ship is Dictionary or not ship.get("ism") is Dictionary:
		return -1.0
	var v: Variant = ship["ism"].get(POLE_FIELD)
	return float(v) if (typeof(v) == TYPE_FLOAT or typeof(v) == TYPE_INT) and is_finite(float(v)) and float(v) >= 0.0 else -1.0
