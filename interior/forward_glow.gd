class_name ForwardGlow
extends RefCounted
## M4.2 forward glow (design m4-first-journey.md "M4.2", higgs-bubble.md §6). CPU reference
## for interior/glow_overlay.gdshader, float64.
##
## Physics. A fraction eps of the ISM kinetic flux K becomes light at the bubble wall, and
## f_in of it shines inward. The wall element whose outward normal is at angle theta from the
## direction of travel (ship frame, +Z) shines
##     E(theta) = eps f_in K max(0, cos theta)       (W/m^2, inward emittance)
## which is sunholo/relativity medium.glowEmittanceAt (0.8.0). The sim emits the pole value
## ship.ism.glow_pole_w_m2 = glowEmittanceAt(..., 1.0); Godot only mirrors the shape:
##     profile(pole, cos theta) = pole x clamp(cos theta, 0, 1)      (NaN stays NaN)
## so the brightness comes from the sim, never from GDScript physics.
##
## The wall is a Lambertian emitter (M4.6a eval N3): radiance L = E / pi (W m^-2 sr^-1),
## medium.glowRadianceAt.
##
## SPECTRUM (ledger D-30; higgs-bubble.md section 6, HB-95..HB-111): a blackbody. The wall is a
## greybody of emissivity eps, so eps cancels in its energy balance and the temperature is
##     T(theta) = (K max(0, cos theta) / sigma)^(1/4) = T_pole x cos^(1/4) theta
## (medium.glowTemperatureAt; the sim emits T_pole = ship.ism.glow_pole_k, Godot mirrors only
## the cos^(1/4) shape). The luminance is L x eta(T) with the blackbody luminous efficacy
##     eta(T) = pi Km int B_lambda(T) ybar dlambda / (sigma T^4)      (lm/W)
## = blackbody.luminousEfficacy, mirrored here through Blackbody.photopic_radiance (exact) and
## through Blackbody's colour lookup (log10 Y, the path the shader samples). The colour is
## Blackbody.rgb_unit_luminance(T) (Y = 1). Luminance (cd/m^2) goes through the sky camera's
## photometric exposure (M1.5a, Exposure.k()), the one the stars and the background use. No gain.
##
## The ray from the panorama camera (inside the bubble, not at its centre) leaves the sphere
## of radius R at the wall point P; cos theta = P.z / R. wall_cos() solves that in float64.

## blackbody.stefanBoltzmannSI (sunholo/relativity 0.8.0), W m^-2 K^-4.
const SIGMA := 5.670374419e-8
## pi x Km x 2hc^2 / sigma: eta(T) = EFF_K x Y(T) / T^4 with Y = Blackbody.luminance (the shader's constant).
const EFF_K := PI * Blackbody.PHOTOPIC_K / SIGMA
## The sim's fields (M4.1 step 2). Absent: the glow is off.
const POLE_FIELD := "glow_pole_w_m2"
const TEMP_FIELD := "glow_pole_k"


## The angular profile: glowEmittanceAt's shape, given the sim's pole value (W/m^2).
## cos_theta is clamped to [0, 1] like the package (a dot product rounding past 1 is the
## pole, the aft hemisphere is 0); NaN propagates (ailang#1419 parity).
static func profile(pole_w_m2: float, cos_theta: float) -> float:
	if is_nan(cos_theta):
		return cos_theta
	return pole_w_m2 * clampf(cos_theta, 0.0, 1.0)


## Lambertian wall: emittance (W/m^2) -> radiance (W m^-2 sr^-1) (medium.glowRadianceAt).
static func radiance(emittance_w_m2: float) -> float:
	return emittance_w_m2 / PI


## The wall element's temperature (K) from the sim's pole temperature: T_pole x cos^(1/4) theta
## by two square roots (medium.glowTemperatureAt's shape). cos is clamped to [0, 1]; NaN stays NaN.
static func temperature(t_pole: float, cos_theta: float) -> float:
	if is_nan(cos_theta) or is_nan(t_pole):
		return NAN
	var c := clampf(cos_theta, 0.0, 1.0)
	return t_pole * sqrt(sqrt(c)) if c > 0.0 and t_pole > 0.0 else 0.0


## Blackbody luminous efficacy (lm/W), exact: blackbody.luminousEfficacy. 0 at T <= 0, NaN and
## when the visible integral underflows (below ~25 K); falls as 1/T^3 at very high T.
static func efficacy(t: float) -> float:
	var p := Blackbody.photopic_radiance(t)
	if not (p > 0.0):
		return 0.0
	var t2 := t * t
	return PI * p / (SIGMA * t2 * t2)


## The same through Blackbody's colour lookup (log10 Y linear in log T over [LUT_T_MIN, LUT_T_MAX],
## the texture the shader samples). Below LUT_T_MIN (300 K, eta < 1e-24 lm/W) it is 0; above
## LUT_T_MAX (1e7 K, far past any glow) the lookup clamps. Finite over its whole range (tested).
static func efficacy_lut(t: float) -> float:
	if not (t >= Blackbody.LUT_T_MIN):
		return 0.0
	var tt := minf(t, Blackbody.LUT_T_MAX)
	return EFF_K * pow(10.0, Blackbody.lut_log10_y(tt) - 4.0 * log(tt) / log(10.0))


## Emittance (W/m^2) at temperature t (K) -> luminance seen on the wall (cd/m^2):
## medium.glowLuminanceAt = glowRadianceAt x glowEfficacyAt.
static func luminance(emittance_w_m2: float, t: float) -> float:
	return radiance(emittance_w_m2) * efficacy(t)


## The glow's colour at temperature t: linear sRGB with luminance Y = 1 (blackbody.rgbUnitLuminance).
## Black where the efficacy is 0 (the colour of no light; avoids the 0/0 below ~25 K).
static func colour(t: float) -> Vector3:
	if not (t >= Blackbody.LUT_T_MIN):
		return Vector3.ZERO
	return Blackbody.rgb_unit_luminance(t)


## The luminance-weighted colour the shader draws per W m^-2 sr^-1: colour x efficacy (lookup path).
static func colour_lut(t: float) -> Vector3:
	if not (t >= Blackbody.LUT_T_MIN):
		return Vector3.ZERO
	return Blackbody.lut_rgb(minf(t, Blackbody.LUT_T_MAX)) * efficacy_lut(t)


## cos(theta) of the wall point a ray from `cam` (ship frame, metres) along unit `dir` (ship
## frame) leaves the bubble of radius r through. NaN when the camera is not inside the bubble.
static func wall_cos(cam: PackedFloat64Array, dir: PackedFloat64Array, r: float) -> float:
	var c2 := cam[0] * cam[0] + cam[1] * cam[1] + cam[2] * cam[2]
	if not (r > 0.0) or c2 >= r * r:
		return NAN
	var b := cam[0] * dir[0] + cam[1] * dir[1] + cam[2] * dir[2]
	var t := -b + sqrt(b * b + (r * r - c2)) # the positive root: the exit point ahead
	return (cam[2] + t * dir[2]) / r


## The sim's pole emittance (W/m^2), or -1.0 when the state carries none (the glow is off and the HUD
## says so). Never derived here from glow_w_m2: the sim owns that number.
static func pole_of(world: Dictionary) -> float:
	return _field(world, POLE_FIELD)


## The sim's pole temperature (K), or -1.0 when absent.
static func temperature_of(world: Dictionary) -> float:
	return _field(world, TEMP_FIELD)


static func _field(world: Dictionary, name: String) -> float:
	var ship: Variant = world.get("ship")
	if not ship is Dictionary or not ship.get("ism") is Dictionary:
		return -1.0
	var v: Variant = ship["ism"].get(name)
	return float(v) if (typeof(v) == TYPE_FLOAT or typeof(v) == TYPE_INT) and is_finite(float(v)) and float(v) >= 0.0 else -1.0
