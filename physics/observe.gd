class_name EarthObserve
extends RefCounted
## Float64 CPU mirror of pinned sunholo/observe 0.1.0/lightcone and relativity optics.
## Coordinates are scalar arrays (ly); no float32 Vector3 round-trip. Times are years, c=1.
const AT_SOL_LY := 1e-12
static func norm(p: Array) -> float:
	return sqrt(float(p[0])*float(p[0]) + float(p[1])*float(p[1]) + float(p[2])*float(p[2]))
static func dot(a: Array, b: Array) -> float:
	return float(a[0])*float(b[0]) + float(a[1])*float(b[1]) + float(a[2])*float(b[2])
static func sub(a: Array, b: Array) -> Array:
	return [float(a[0])-float(b[0]), float(a[1])-float(b[1]), float(a[2])-float(b[2])]
static func seen_at(t: float, observer: Array, source: Array) -> float:
	return t - norm(sub(observer, source))
static func catch_up(delta: float, one_minus_beta: float) -> float:
	return delta / one_minus_beta
static func triangle_excess(a: Array, b: Array) -> float:
	return maxf(0., norm(a) + norm(b) - norm(sub(b, a)))
static func on_beam_line(port: Array, point: Array, angular_tolerance: float) -> bool:
	var d := dot(point, port)
	var cross := [float(point[1])*float(port[2])-float(point[2])*float(port[1]), float(point[2])*float(port[0])-float(point[0])*float(port[2]), float(point[0])*float(port[1])-float(point[1])*float(port[0])]
	return d > 0. and atan2(norm(cross), d) <= angular_tolerance
static func link_window(a: Array, b: Array, leg_t: float, covered: bool) -> float:
	return 0. if covered else maxf(0., norm(a) + norm(b) - leg_t)
static func earth_rate(position: Array, heading: Array, phi: float) -> float:
	var r := norm(position)
	var c := (-1. if norm(heading) > 0. else 0.) if r < AT_SOL_LY else -dot(position, heading) / r
	c = clampf(c, -1., 1.)
	var ep := exp(phi); var em := exp(-phi)
	var sh := .5 * (ep - em)
	# optics.gammaOnePlusBetaCos: exp(-phi) avoids cancellation straight astern.
	return em + sh * (1. + c) if c < 0. else .5 * (ep + em) + sh * c
