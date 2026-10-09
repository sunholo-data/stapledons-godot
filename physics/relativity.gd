class_name Relativity
extends RefCounted
## Reference special-relativity and colour maths (CPU, float64).
##
## This is the single source of truth for the formulas. The GPU starfield
## shader (sky/starfield.gdshader) mirrors these functions, and the test
## suite (tests/test_physics.gd) checks both against known values.
##
## Conventions:
##   n      unit vector from the observer TOWARD the source, galaxy (rest) frame
##   bh, b  observer velocity direction (unit) and speed in the galaxy frame, c = 1
##   n'     unit vector toward where the source APPEARS in the ship frame
##   D      Doppler factor, nu_observed / nu_emitted (> 1 is blueshift)


static func gamma_of(b: float) -> float:
	return 1.0 / sqrt(1.0 - b * b)


## gamma from 1 - beta (the sim's one_minus_beta), exact near c.
static func gamma_of_one_minus_beta(omb: float) -> float:
	return 1.0 / sqrt(omb * (2.0 - omb))


## Rapidity mirrors of sunholo/relativity kinematics (0.10.0): betaOf, gammaOf,
## oneMinusBeta, rapidityOfBeta, with the package's hyper.tanh / cosh / atanh
## (Kahan expm1 / log1p forms, so they agree with the package to rounding).
## 1 - beta comes from phi directly (2 e^{-2|phi|} / (1 + e^{-2|phi|})), never as
## 1.0 - beta_of_rapidity(phi): exact even where beta rounds to 1.

static func _expm1(u: float) -> float:
	var y := exp(u)
	if y == 1.0:
		return u
	if y - 1.0 == -1.0:
		return -1.0
	return (y - 1.0) * u / log(y)


static func _log1p(x: float) -> float:
	var y := 1.0 + x
	return x if y == 1.0 else log(y) * x / (y - 1.0)


## beta = tanh(phi) (kinematics.betaOf; hyper.tanh is exactly +-1 beyond |phi| = 20).
static func beta_of_rapidity(phi: float) -> float:
	var a := absf(phi)
	var t := 1.0
	if a <= 20.0:
		var e := _expm1(2.0 * a)
		t = e / (e + 2.0)
	return -t if phi < 0.0 else t


## gamma = cosh(phi) (kinematics.gammaOf).
static func gamma_of_rapidity(phi: float) -> float:
	var e := exp(absf(phi))
	return (e + 1.0 / e) / 2.0


## 1 - |beta| from phi (kinematics.oneMinusBeta).
static func one_minus_beta_of_rapidity(phi: float) -> float:
	var e := exp(-2.0 * absf(phi))
	return 2.0 * e / (1.0 + e)


## phi = atanh(beta), |beta| < 1 (kinematics.rapidityOfBeta via hyper.atanh).
static func rapidity_of_beta(b: float) -> float:
	var a := absf(b)
	var r := 0.5 * _log1p(2.0 * a / (1.0 - a))
	return -r if b < 0.0 else r


## CMB temperature, K (higgs-bubble HB-5; the package's medium.cmbTemperatureK).
const CMB_T0 := 2.725


## Temperature of the CMB arriving from galaxy-frame direction n (toward the
## source): T0 gamma (1 + beta n.bh). Mirrors optics.cmbSeenTemperature
## (0.5.0+): 1,926.9 K for n at 90 deg at 1 - beta = 1e-6.
static func cmb_seen_temperature(n: Vector3, bh: Vector3, omb: float) -> float:
	return CMB_T0 * gamma_of_one_minus_beta(omb) * (1.0 + (1.0 - omb) * n.dot(bh))


## The same from the APPARENT angle theta' between the view ray and the
## direction of travel: T0 / (gamma (1 - beta cos theta')), with
## 1 - beta cos theta' = (1 - beta) + 2 beta sin^2(theta'/2) so nothing cancels
## near c. Mirrors optics.cmbSeenTemperatureApparent (0.5.0+): 3,853.7 K on the
## pole at the cap (HB-63), half that near theta' = 1/gamma, T0/gamma at 90 deg.
static func cmb_temperature_apparent(theta_app: float, omb: float) -> float:
	var s := sin(0.5 * theta_app)
	return CMB_T0 / (gamma_of_one_minus_beta(omb) * (omb + 2.0 * (1.0 - omb) * s * s))


## Angle between unit vectors without the acos cancellation at small angles.
static func angle_between(a: Vector3, b: Vector3) -> float:
	return atan2(a.cross(b).length(), a.dot(b))


## Velocity is passed as a unit direction plus a float64 speed b, because
## Godot's Vector3 is float32 and would cost ~7 significant digits in D.

## Aberration of a source direction for an observer moving with speed b along bh.
## n' = (n + ((gamma - 1)(n.bh) + gamma*b) bh) / (gamma (1 + b n.bh))
## Sources crowd toward the direction of motion: a source at 90 degrees
## appears at cos(theta') = b.
static func aberrate(n: Vector3, bh: Vector3, b: float) -> Vector3:
	if b <= 0.0:
		return n
	var g := gamma_of(b)
	var c: float = n.dot(bh)
	var k: float = ((g - 1.0) * c + g * b) / (g * (1.0 + b * c))
	var s: float = 1.0 / (g * (1.0 + b * c))
	return Vector3(n.x * s + bh.x * k, n.y * s + bh.y * k, n.z * s + bh.z * k).normalized()


## Inverse aberration: given where a ray LOOKS in the ship frame, return the
## galaxy-frame direction it came from (for sampling sky textures).
static func deaberrate(n_ship: Vector3, bh: Vector3, b: float) -> Vector3:
	return aberrate(n_ship, -bh, b)


## Doppler factor from the galaxy-frame source direction: D = gamma (1 + b cos theta).
static func doppler(n: Vector3, bh: Vector3, b: float) -> float:
	return gamma_of(b) * (1.0 + b * n.dot(bh))


## Doppler factor from the apparent (ship-frame) direction: D = 1 / (gamma (1 - b cos theta')).
static func doppler_apparent(n_ship: Vector3, bh: Vector3, b: float) -> float:
	return 1.0 / (gamma_of(b) * (1.0 - b * n_ship.dot(bh)))


## Observed/rest ratio of a point source's flux in the visual (CIE Y) band.
## I_nu / nu^3 is invariant, so a blackbody at T is seen as a blackbody at D*T
## whose solid angle shrinks by 1/D^2:
##   F'_Y / F_Y = (Y(D T) / Y(T)) / D^2
## Bolometrically this reduces to D^2, the correct point-source result.
static func point_flux_ratio(t_kelvin: float, d: float) -> float:
	return Blackbody.luminance(t_kelvin * d) / Blackbody.luminance(t_kelvin) / (d * d)


## Seen/rest radiance ratio of a thermal EXTENDED source (sky background,
## nebulae) in the visual band: the blackbody at D*T, Y(D T) / Y(T), with no
## solid-angle factor. Bolometrically D^4. Mirrors the package's surfaceBrightnessRatio.
static func surface_brightness_ratio(t_kelvin: float, d: float) -> float:
	return Blackbody.luminance(t_kelvin * d) / Blackbody.luminance(t_kelvin)


## Visual illuminance in lux of a V magnitude. Mirrors the package's
## photometry.illuminanceFromV (sunholo/relativity 0.4.0+): the standard
## visual zero point, V = -13.98 at 1 lux, so V = 0 gives 2.5586e-6 lux.
static func illuminance_from_v(v: float) -> float:
	return pow(10.0, -0.4 * (v + 13.98))


## Johnson V of an illuminance in lux (inverse of illuminance_from_v).
## Mirrors photometry.vFromIlluminance (sunholo/relativity 0.5.0+).
static func v_from_illuminance(lux: float) -> float:
	return -13.98 - 2.5 * log(lux) / log(10.0)


## Luminance in cd/m^2 of a surface brightness mu in V mag/arcsec^2: the
## package zero point spread over one arcsec^2. Mirrors
## photometry.luminanceFromSurfaceMag (0.5.0+): mu = 22 gives 1.7252e-4 cd/m^2.
static func luminance_from_surface_mag(mu: float) -> float:
	var arcsec := PI / 648000.0
	return pow(10.0, -0.4 * (mu + 13.98)) / (arcsec * arcsec)


## Naked-eye threshold illuminance (lux) of a point source against background
## luminance lb (cd/m^2), field factor 1: Crumey (2014, MNRAS 442, 2600) fitted
## to Blackwell (1946). Mirrors photometry.pointThresholdIlluminance (0.5.0+),
## including its ordering: NaN, negative and below-1e-5 backgrounds clamp to
## 1e-5 cd/m^2 before the branch.
static func point_threshold_illuminance(lb: float) -> float:
	var b := lb if (lb == lb and lb > 0.00001) else 0.00001
	var q := sqrt(sqrt(b))
	var h := sqrt(b)
	var s := 0.0006505 * q - 0.0008461 * h if b <= 0.0708 else 0.0001772 * q + 0.00007167 * h
	return s * s


## Faintest V visible against lb at field factor f (photometry.limitingMagnitude).
static func limiting_magnitude(lb: float, f: float) -> float:
	return v_from_illuminance(f * point_threshold_illuminance(lb))


## Relative flux from an apparent magnitude.
static func flux_from_mag(mag: float) -> float:
	return pow(10.0, -0.4 * mag)


## Effective temperature by spectral class (main-sequence midpoints).
## Spike-level: the catalogue only carries a class letter today.
static func temperature_for_class(spectral: String) -> float:
	match spectral.substr(0, 1):
		"O": return 35000.0
		"B": return 15000.0
		"A": return 8500.0
		"F": return 6700.0
		"G": return 5700.0
		"K": return 4500.0
		"M": return 3300.0
		"L": return 2000.0
		"T": return 1200.0
	return 5700.0
