class_name Observe
extends RefCounted
## R3-EARTH-LINK EL5 (design r3/earth-link.md EL1, EL5; gate 2): the GDScript mirror of the
## sunholo/observe 0.1.0 light-cone functions (pkg sunholo/observe/lightcone), which are the single
## source; this copy exists so tests/test_physics.gd can assert the spec's RS-26..RS-37 check values in
## the second language. c = 1, light-years and years, galaxy frame, Sol at the origin. Positions are
## float64 triples [x, y, z] (Godot's Vector3 is float32, CLAUDE.md gate 5). 1 - beta is never computed
## here: catch_up takes it from Relativity.one_minus_beta_of_rapidity.

const AT_SOL_LY := 1e-12 # lightcone.atSolLy: below this a position is Sol itself


static func norm(a: Array) -> float:
	return sqrt(float(a[0]) * a[0] + float(a[1]) * a[1] + float(a[2]) * a[2])


static func dot(a: Array, b: Array) -> float:
	return float(a[0]) * b[0] + float(a[1]) * b[1] + float(a[2]) * b[2]


static func sub(a: Array, b: Array) -> Array:
	return [float(a[0]) - b[0], float(a[1]) - b[1], float(a[2]) - b[2]]


static func cross(a: Array, b: Array) -> Array:
	return [float(a[1]) * b[2] - float(a[2]) * b[1], float(a[2]) * b[0] - float(a[0]) * b[2], float(a[0]) * b[1] - float(a[1]) * b[0]]


## seenAt: the emission time of a static source's light reaching obs at galaxy time t.
static func seen_at(t: float, obs: Array, src: Array) -> float:
	return t - norm(sub(obs, src))


## catchUp: a signal sent delta after a straight outbound departure reaches the ship delta / (1 - beta).
static func catch_up(delta: float, one_minus_beta: float) -> float:
	return delta / one_minus_beta


## triangleExcess: |a| + |b| - |b - a|, clamped at 0.
static func triangle_excess(a: Array, b: Array) -> float:
	return maxf(norm(a) + norm(b) - norm(sub(b, a)), 0.0)


## onBeamLine: p on the ray from Sol through port, within ang_tol radians (atan2 form).
static func on_beam_line(port: Array, p: Array, ang_tol: float) -> bool:
	var d := dot(p, port)
	return d > 0.0 and atan2(norm(cross(p, port)), d) <= ang_tol


## linkWindow: the wait at b for Sol's light aimed at a plan sent from a; 0 when covered.
static func link_window(a: Array, b: Array, leg_t: float, covered: bool) -> float:
	return 0.0 if covered else maxf(norm(a) + norm(b) - leg_t, 0.0)


## optics.gammaOnePlusBetaCos: gamma (1 + beta c) without cancellation near c = -1.
static func gamma_one_plus_beta_cos(phi: float, c: float) -> float:
	return exp(-phi) + sinh(phi) * (1.0 + c) if c < 0.0 else cosh(phi) + sinh(phi) * c


## earthRate: Sol-seconds received per ship-second for Sol's direction -pos/|pos|; at Sol, Sol is astern.
static func earth_rate(pos: Array, heading: Array, phi: float) -> float:
	var r := norm(pos)
	var c := (-1.0 if norm(heading) > 0.0 else 0.0) if r < AT_SOL_LY else -dot(pos, heading) / r
	return gamma_one_plus_beta_cos(phi, clampf(c, -1.0, 1.0))
