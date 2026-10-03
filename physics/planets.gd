class_name Planets
extends RefCounted
## Reflected-light photometry and globe placement (CPU, float64). M5.2a.
##
## Mirrors sunholo/celestial 0.1.0 `reflect` (starIlluminanceAt, lambertPhase,
## lambertRadiance, minnaertRadiance, rhoFromGeometricAlbedo, minnaertPhase,
## phaseFunction, discIlluminance) operation for operation; the package is the
## single source of the formulas (CLAUDE.md gate 3), planets/planet.gdshader
## mirrors this file, and tests/test_physics.gd (_m5_photometry) holds the
## package's probe values (sim/tools/planets_probe.ail).
##
## Units: illuminance in lux, radiance in cd/m^2, distances in km unless named
## _au, angles in radians. Directions are float64 scalars; a Vector3 (float32)
## only ever holds a unit direction or a placed, rescaled position.

const T_SUN := 5772.0 # K, the IAU 2015 nominal solar effective temperature: reflected light's colour
const DISC_PX := 2.0 # angular diameter (pixels) at which a body becomes a disc (design §M5.2)
const SUN_LIMB_U := 0.6 # linear limb-darkening coefficient of the solar disc (design §M5.2)
const PLACE := 10.0 # a resolved body is drawn PLACE units from the camera, its radius scaled by PLACE / d
## The celestial north pole in galactic coordinates: column 3 of the package's
## frames.equatorialToGalactic (ESA SP-1200 eq. 1.5.11, 10 digits).
const NCP_GAL := [-0.4838350155, 0.7469822445, 0.4559837762]


static func star_illuminance_at(e1_au: float, r_au: float) -> float:
	return e1_au / (r_au * r_au)


static func lambert_phase(alpha: float) -> float:
	var p := (sin(alpha) + (PI - alpha) * cos(alpha)) / PI
	return 0.0 if p < 0.0 else p


static func lambert_radiance(rho: float, lux: float, cos_i: float) -> float:
	return 0.0 if cos_i <= 0.0 else rho * lux * cos_i / PI


static func minnaert_radiance(rho: float, k: float, lux: float, cos_i: float, cos_e: float) -> float:
	if cos_i <= 0.0 or cos_e < 0.0:
		return 0.0
	if k == 1.0:
		return rho * lux * cos_i / PI
	if cos_e == 0.0 and k < 1.0:
		return 0.0
	return rho * lux * pow(cos_i, k) * pow(cos_e, k - 1.0) / PI


static func rho_from_geometric_albedo(p: float, k: float) -> float:
	return p * (2.0 * k + 1.0) / 2.0


## The package's lonIntegral: composite Simpson, 256 intervals, same order of operations.
static func _lon_integral(alpha: float, k: float) -> float:
	var lo := alpha - PI / 2.0
	var h := (PI / 2.0 - lo) / 256.0
	var acc := 0.0
	for i in 257:
		var w := 1.0 if i == 0 or i == 256 else (4.0 if i % 2 == 1 else 2.0)
		var l := lo + h * float(i)
		var c := cos(l - alpha) * cos(l)
		acc += w * (0.0 if c <= 0.0 else pow(c, k))
	return acc * h / 3.0


static func minnaert_phase(alpha: float, k: float) -> float:
	return 0.0 if alpha >= PI else _lon_integral(alpha, k) / _lon_integral(0.0, k)


static func phase_function(alpha: float, k: float) -> float:
	return lambert_phase(alpha) if k == 1.0 else minnaert_phase(alpha, k)


## E = e1AU p (R / d)^2 Phi(alpha) / r^2 at the observer (lux).
static func disc_illuminance(e1_au: float, p: float, radius: float, r_au: float, d: float, alpha: float, k: float) -> float:
	return e1_au * p * (radius / d) * (radius / d) * phase_function(alpha, k) / (r_au * r_au)


## Mean radiance of the limb-darkened solar disc L(mu) = L0 (1 - u (1 - mu)):
## L0 = mean / (1 - u / 3), so the disc integral is the star's illuminance.
static func limb_darkened(mean: float, mu: float, u := SUN_LIMB_U) -> float:
	return mean / (1.0 - u / 3.0) * (1.0 - u * (1.0 - mu))


## Angular radius asin(R / d), float64 (d > R).
static func angular_radius(radius_km: float, d_km: float) -> float:
	return asin(minf(radius_km / d_km, 1.0))


## Angular diameter in pixels of the centre pixel's angle px_rad.
static func diameter_px(radius_km: float, d_km: float, px_rad: float) -> float:
	return 2.0 * angular_radius(radius_km, d_km) / px_rad


## A sim vector {x, y, z} (galactic, float64) -> [world x, y, z] float64 scalars,
## through Starfield.galactic_to_world's axis map (y, z, -x) written out so no
## raw km value passes through a float32 Vector3.
static func world_of(v: Dictionary) -> PackedFloat64Array:
	return PackedFloat64Array([v["y"], v["z"], -v["x"]])


static func length64(a: PackedFloat64Array) -> float:
	return sqrt(a[0] * a[0] + a[1] * a[1] + a[2] * a[2])


## Placement of a resolved body: [unit direction (Vector3), centre (Vector3) PLACE
## units out, radius PLACE R / d]. The direction and the ratio are float64; only the
## O(PLACE) results become float32, so the angular radius asin(R / d) survives.
static func place(rel_km: Dictionary, radius_km: float) -> Array:
	var w := world_of(rel_km)
	var d := length64(w)
	var dir := Vector3(w[0] / d, w[1] / d, w[2] / d)
	return [dir, dir * PLACE, PLACE * radius_km / d, d]


## The body-fixed frame (world): z the pole, x the prime meridian at W. The
## node Q = NCP x pole (IAU: W is measured from the ascending node of the body's
## equator on the ICRF equator), x = cos W Q + sin W (pole x Q).
static func body_basis(pole_gal: Dictionary, w_deg: float) -> Basis:
	var p := Vector3(pole_gal["x"], pole_gal["y"], pole_gal["z"]).normalized()
	var ncp := Vector3(NCP_GAL[0], NCP_GAL[1], NCP_GAL[2])
	var q := ncp.cross(p)
	q = Vector3(1, 0, 0).cross(p) if q.length() < 1e-9 else q
	q = q.normalized()
	var w := deg_to_rad(w_deg)
	var x := q * cos(w) + p.cross(q) * sin(w)
	var gw := func(g: Vector3) -> Vector3: return Starfield.galactic_to_world(g)
	return Basis(gw.call(x), gw.call(p.cross(x)), gw.call(p))


## Point or disc: true when the body is drawn as a disc (>= DISC_PX across).
static func is_disc(radius_km: float, d_km: float, px_rad: float) -> bool:
	return diameter_px(radius_km, d_km, px_rad) >= DISC_PX


## Disc integral of the Minnaert sphere's radiance (lux) by a midpoint grid of
## n x n over the projected disc, observer on +z far away, sun at phase alpha:
## the CPU check that what the shader draws integrates to discIlluminance.
static func integrate_disc(rho: float, k: float, lux: float, alpha: float, ang_r: float, n: int) -> float:
	var s := Vector3(sin(alpha), 0.0, cos(alpha))
	var sum := 0.0
	var cell := 2.0 / n
	for j in n:
		for i in n:
			var x := -1.0 + (i + 0.5) * cell
			var y := -1.0 + (j + 0.5) * cell
			var r2 := x * x + y * y
			if r2 >= 1.0:
				continue
			var nrm := Vector3(x, y, sqrt(1.0 - r2))
			sum += minnaert_radiance(rho, k, lux, nrm.dot(s), maxf(nrm.z, 1e-3) if k < 1.0 else nrm.z)
	return sum * cell * cell * ang_r * ang_r
