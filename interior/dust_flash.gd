class_name DustFlash
extends RefCounted
## R1-ISM-DUST I5: dust-grain flashes on the forward wall (design ism-structure-and-dust.md
## section 6; stapledons-design higgs-bubble.md section 6b). CPU reference for
## interior/dust_flash.gdshader and the runtime list of live flashes, float64.
##
## Physics. Each bright grain the sim reports (ship.ism.impacts, protocol 2.7) hits the wall at
## a point of the forward hemisphere's projected unit disc (x, y), so the wall normal there is
## n = (x, y, sqrt(1 - x^2 - y^2)) in the ship frame (+Z = travel): uniform on the disc is
## cos-theta-weighted on the wall. Its afterglow is the wall afterglow G-AG, a LABELLED GAME
## APPROXIMATION (D-60, D-61): the eps fraction of the grain's kinetic energy is released from a
## disc of radius r_s on the wall, decaying as e^(-t/tau), each instant a greybody of emissivity
## eps (so eps cancels in its temperature, as in the glow, D-30):
##     T(t) = (KE / (sigma pi r_s^2 tau))^(1/4) e^(-t/4 tau)
##     E(t) = eps f_in KE e^(-t/tau) / (pi r_s^2 tau)                     (W/m^2, inward)
## = sunholo/relativity 0.12.0 dust.afterglowTemperature / afterglowEmittance, mirrored here (the
## package is the source; tests/test_dust_flash.gd checks the mirror against its values). The
## total light is eps f_in KE whatever r_s and tau are. Luminance = E / pi x eta(T) through
## ForwardGlow.efficacy, and the pixel goes through the sky's one exposure (Exposure.k()), the
## same chain as the glow: a flash is exactly as visible as its light is against the glow.
##
## Glitter. The faint flashes (5 % <= contrast < 1) are too many to send; the sim sends their rate
## per ship second, their radius range, the tail slope q and a per-tick seed (ship.ism.glitter).
## glitter_events() draws them with a mirror of the sim's stateless splitmix64 stream, the
## package's Poisson draw (celestial.ism.poissonDraw) and the tail's inverse CDF
## (celestial.ism.grainRadiusAt above a_lo, truncated at a_hi). The same seed gives the same
## picture. They share the 64 sprites with the bright flashes (brightest kept): a display limit.

const SIGMA := 5.670374419e-8 # blackbody.stefanBoltzmannSI
const C := 299792458.0
const R_SPOT := 0.5 # m, G-AG default (HB-119; picked from the comparison sheet, D-61)
const TAU := 0.2 # s (HB-138)
const GRAIN_RHO := 3300.0 # kg/m^3 (HB-113)
const MAX_SPRITES := 64
const LIFE_TAUS := 6.0 # a flash is dropped after 6 tau (e^-6: 0.25 % of its peak emittance)


## One small projected quad per possible flash; the vertex shader bounds its wall
## spot conservatively. VERTEX.z is the exact sprite index, not a physical position.
static func sprite_mesh() -> ArrayMesh:
	var vertices := PackedVector3Array()
	var corners := [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(1, 1)]
	for i in MAX_SPRITES:
		for corner: Vector2 in corners:
			vertices.append(Vector3(corner.x, corner.y, float(i)))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## Two 32-bit masks per spot. Only spots whose enclosing balls intersect can
## contribute to the same pixel (triangle inequality); this is geometry only.
static func overlap_masks(flashes: PackedVector4Array, count: int, radius: float, r_spot: float) -> Array:
	var lo := PackedInt32Array()
	var hi := PackedInt32Array()
	lo.resize(MAX_SPRITES)
	hi.resize(MAX_SPRITES)
	var extent := 2.0 * r_spot + absf(radius) * 1e-6 # conservative float32 projection guard
	var limit2 := extent * extent
	for i in count:
		var a := Vector3(flashes[i].x, flashes[i].y, flashes[i].z) * radius
		for j in count:
			var b := Vector3(flashes[j].x, flashes[j].y, flashes[j].z) * radius
			if a.distance_squared_to(b) <= limit2:
				if j < 32: lo[i] = lo[i] | (1 << j)
				else: hi[i] = hi[i] | (1 << (j - 32))
	return [lo, hi]


## dust.afterglowTemperature: 0 before the impact (t < 0) and for KE <= 0; NaN stays NaN.
static func temperature(ke: float, r_spot: float, tau: float, t: float) -> float:
	if is_nan(ke) or is_nan(t):
		return NAN
	var x := ke / (SIGMA * PI * r_spot * r_spot * tau)
	if t < 0.0 or not (x > 0.0):
		return 0.0
	return sqrt(sqrt(x)) * exp(-t / (4.0 * tau))


## dust.afterglowEmittance (W/m^2): 0 before the impact; NaN stays NaN.
static func emittance(ke: float, eps: float, f_in: float, r_spot: float, tau: float, t: float) -> float:
	if is_nan(t):
		return NAN
	if t < 0.0:
		return 0.0
	return eps * f_in * ke * exp(-t / tau) / (PI * r_spot * r_spot * tau)


## dust.afterglowLuminance (cd/m^2): E / pi x the blackbody efficacy at T.
static func luminance(ke: float, eps: float, f_in: float, r_spot: float, tau: float, t: float) -> float:
	return emittance(ke, eps, f_in, r_spot, tau, t) / PI * ForwardGlow.efficacy(temperature(ke, r_spot, tau, t))


## The wall normal (ship frame, unit) under a point (x, y) of the forward hemisphere's projected disc.
static func wall_dir(x: float, y: float) -> Vector3:
	var r2 := x * x + y * y
	return Vector3(x, y, sqrt(maxf(0.0, 1.0 - r2)))


## Kinetic energy of a grain of radius a (m) at Lorentz factor gamma: (gamma - 1) m c^2
## (the sim sends ke_j for bright grains; glitter grains take the ship's gamma, >= 7 whenever
## they exist, so gamma - 1 loses nothing).
static func kinetic(a: float, gamma: float) -> float:
	return (gamma - 1.0) * 4.0 / 3.0 * PI * a * a * a * GRAIN_RHO * C * C


# ---------------------------------------------------------------- the dust stream mirror

## sim/rng.ail mix64 (SplitMix64 finaliser), 64-bit wrapping integer arithmetic.
static func mix64(z0: int) -> int:
	var z := z0
	z = (z ^ _shr(z, 30)) * -4658895280553007687 # 0xbf58476d1ce4e5b9
	z = (z ^ _shr(z, 27)) * -7723592293110705685 # 0x94d049bb133111eb
	return z ^ _shr(z, 31)


static func _shr(x: int, k: int) -> int:
	return (x >> k) & ((1 << (64 - k)) - 1)


## sim/rng.ail splitmix64(state, n) = mix64(state + (n + 1) * golden).
static func splitmix64(state: int, n: int) -> int:
	return mix64(state + (n + 1) * -7046029254386353131) # 0x9e3779b97f4a7c15


## Uniform [0, 1) from the top 53 bits.
static func u53(v: int) -> float:
	return float(_shr(v, 11)) / 9007199254740992.0


## celestial.ism.poissonDraw: inversion below 30, a rounded Box-Muller normal from 30.
static func poisson(mean: float, u: float, v: float) -> int:
	if not (mean > 0.0):
		return 0
	if mean < 30.0:
		var k := 0
		var p := exp(-mean)
		var f := p
		while u > f and k < 200:
			p *= mean / float(k + 1)
			f += p
			k += 1
		return k
	var uc := clampf(u, 0.0, 1.0 - 1.1102230246251565e-16) # 1 - 2^-53 (Godot parses long plain decimals inexactly)
	var x := floorf(mean + sqrt(mean) * sqrt(-2.0 * log(1.0 - uc)) * cos(2.0 * PI * v) + 0.5)
	return int(x) if x > 0.0 else 0


## Inverse CDF of dn/da ~ a^-q on [a_lo, a_hi] (the tail of celestial.ism.GrainDist above a_lo,
## truncated where the glitter ends and the bright flashes begin): u = 0 gives a_lo.
static func radius_at(a_lo: float, a_hi: float, q: float, u: float) -> float:
	if not (a_hi > a_lo):
		return a_lo
	var e := 1.0 - q
	var lo := pow(a_lo, e)
	var hi := pow(a_hi, e)
	return pow(lo + u * (hi - lo), 1.0 / e)


## The glitter flashes of one tick from the sim's descriptor (rate per ship second over the wall,
## a_lo_um, a_hi_um, q, seed) over window_s ship seconds at Lorentz factor gamma: [{x, y, t, a, ke}].
## Slots: (seed, 0..1) the count, (seed, 2 + 4 i .. 5 + 4 i) flash i, at most n_max flashes.
static func glitter_events(g: Dictionary, window_s: float, gamma: float, n_max: int) -> Array:
	var out: Array = []
	var rate := float(g.get("rate", 0.0))
	if not (rate > 0.0) or not (window_s > 0.0):
		return out
	var seed := int(g.get("seed", 0))
	var n := mini(poisson(rate * window_s, u53(splitmix64(seed, 0)), u53(splitmix64(seed, 1))), n_max)
	var a_lo := float(g.get("a_lo_um", 0.0)) * 1e-6
	var a_hi := float(g.get("a_hi_um", 0.0)) * 1e-6
	var q := float(g.get("q", 3.1))
	for i in n:
		var a := radius_at(a_lo, a_hi, q, u53(splitmix64(seed, 2 + 4 * i)))
		var r := sqrt(u53(splitmix64(seed, 3 + 4 * i)))
		var psi := 2.0 * PI * u53(splitmix64(seed, 4 + 4 * i))
		out.append({"x": r * cos(psi), "y": r * sin(psi), "t": u53(splitmix64(seed, 5 + 4 * i)) * window_s, "a": a, "ke": kinetic(a, gamma)})
	return out


# ---------------------------------------------------------------- the live flashes

var eps := 1e-10 # HB-111 (the sim's params.glow_eps when known)
var f_in := 0.5
var r_spot := R_SPOT
var tau := TAU
## Live flashes: {dir: Vector3 (ship frame), ke, born (s on this clock), glitter}
var flashes: Array = []


## Take one sim state: its bright impacts and its glitter, born at now_s + t_s (ship seconds of
## real-time flight; under compression the window is still one real-time tick's). Returns the
## number added.
func ingest(world: Dictionary, now_s: float) -> int:
	var ship: Variant = world.get("ship")
	if not ship is Dictionary or not ship.get("ism") is Dictionary:
		return 0
	var ism: Dictionary = ship["ism"]
	var n := 0
	for e: Variant in ism.get("impacts", []):
		if e is Dictionary:
			flashes.append({"dir": wall_dir(float(e.x), float(e.y)), "ke": float(e.ke_j), "born": now_s + float(e.t_s), "glitter": false})
			n += 1
	var g: Variant = ism.get("glitter")
	var w := float(ism.get("dust", {}).get("window_s", 0.0))
	if g is Dictionary and w > 0.0:
		for e: Dictionary in glitter_events(g, w, float(ship.get("gamma", 1.0)), MAX_SPRITES):
			flashes.append({"dir": wall_dir(e.x, e.y), "ke": e.ke, "born": now_s + e.t, "glitter": true})
			n += 1
	return n


## The flashes alive at now_s, brightest (largest emittance) first, at most MAX_SPRITES:
## [{dir, e (W/m^2), t (K)}]. Dead ones (older than LIFE_TAUS tau) are dropped from the list.
func live(now_s: float) -> Array:
	var keep: Array = []
	var out: Array = []
	for f: Dictionary in flashes:
		var age: float = now_s - f.born
		if age > LIFE_TAUS * tau:
			continue
		keep.append(f)
		if age >= 0.0:
			out.append({"dir": f.dir, "e": emittance(f.ke, eps, f_in, r_spot, tau, age), "t": temperature(f.ke, r_spot, tau, age)})
	flashes = keep
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.e > b.e)
	return out.slice(0, MAX_SPRITES)
