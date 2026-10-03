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
