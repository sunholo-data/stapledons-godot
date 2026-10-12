class_name SkyMeter
extends RefCounted
## The eye's light meter (M1.8 follow-up to M1.5a): a centre-weighted mean of
## the seen luminance over the view that includes the stars and the forward
## CMB, not just the panorama. The eye light-adapts to the light reaching it,
## so this is an arithmetic mean (a log-average cannot see a point source):
##   L_eye = (sum_cells w L Omega + sum_points w E') / sum_cells w Omega
## with w = exp(-theta^2 / 2 CENTRE_SIGMA^2), theta the angle from the view
## centre, Omega the pinhole cell's solid angle and E' a point's seen
## illuminance: a star E pointFluxRatio(T, D), the CMB disc its integrated
## photopicRadiance (sky/cmb.gd). Stars beyond NEAR_LY are pre-summed into
## direction x temperature bins (rebuilt when the ship moves REBUILD_LY);
## nearer ones are taken one by one, so the destination star stays exact.

const GRID := Vector2i(16, 9)
const CENTRE_SIGMA_DEG := 12.0
const BINS := Vector2i(16, 8) # longitude x latitude of the galaxy-frame direction
const T_EDGES := [4000.0, 7000.0] # three temperature classes per direction bin
const NEAR_LY := 20.0
const REBUILD_LY := 5.0

var bin_dir := PackedVector3Array() # flux-weighted mean galaxy-frame direction (from the build position)
var bin_e := PackedFloat64Array() # summed illuminance at the build position, lux
var bin_t := PackedFloat64Array() # flux-weighted log-mean temperature, K
var near := PackedInt32Array() # starfield indices within NEAR_LY of the build position
var _built_at := PackedFloat64Array([INF, INF, INF])


func needs_build(sf: Starfield) -> bool:
	return Starfield._dist(sf.ship, _built_at) > REBUILD_LY


func build(sf: Starfield) -> void:
	var n_bins := BINS.x * BINS.y * (T_EDGES.size() + 1)
	var e := PackedFloat64Array()
	var lt := PackedFloat64Array()
	var dv := PackedVector3Array()
	e.resize(n_bins)
	lt.resize(n_bins)
	dv.resize(n_bins)
	e.fill(0.0)
	lt.fill(0.0)
	near.clear()
	var sx := sf.ship[0]
	var sy := sf.ship[1]
	var sz := sf.ship[2]
	for k in sf.count:
		var rx := sf.pos[3 * k] - sx
		var ry := sf.pos[3 * k + 1] - sy
		var rz := sf.pos[3 * k + 2] - sz
		var r2 := rx * rx + ry * ry + rz * rz
		if r2 < NEAR_LY * NEAR_LY:
			near.append(k)
			continue
		var r := sqrt(r2)
		var flux := sf.custom[4 * k + 1] * sf.custom[4 * k + 3] / r2
		var t := sf.custom[4 * k]
		var i := clampi(int((atan2(rx, -rz) / TAU + 0.5) * BINS.x), 0, BINS.x - 1)
		var j := clampi(int((asin(clampf(ry / r, -1.0, 1.0)) / PI + 0.5) * BINS.y), 0, BINS.y - 1)
		var c := 0 if t < T_EDGES[0] else (1 if t < T_EDGES[1] else 2)
		var b := (c * BINS.y + j) * BINS.x + i
		e[b] += flux
		lt[b] += flux * log(t)
		dv[b] += Vector3(rx / r, ry / r, rz / r) * flux
	bin_dir.clear()
	bin_e.clear()
	bin_t.clear()
	for b in n_bins:
		if e[b] > 0.0:
			bin_dir.append(dv[b].normalized())
			bin_e.append(e[b])
			bin_t.append(exp(lt[b] / e[b]))
	_built_at = sf.ship.duplicate()


## Seen illuminance of a point of illuminance e at temperature t, galaxy-frame
## direction n: e x pointFluxRatio(t, D) through the shaders' lookup table.
static func seen_point(e: float, t: float, n: Vector3, dir: Vector3, b: float) -> float:
	if b <= 0.0:
		return e
	var d := Relativity.doppler(n, dir, b)
	return e * pow(10.0, Blackbody.lut_log10_y(t * d) - Blackbody.lut_log10_y(t)) / (d * d)


## Centre weight of an apparent direction, or 0 outside the frame.
static func _weight(cam: FreeLookCamera, n_app: Vector3, size: Vector2) -> float:
	if cam.is_behind(n_app):
		return 0.0
	var p := cam.project(n_app, size)
	if p.x < 0.0 or p.y < 0.0 or p.x > size.x or p.y > size.y:
		return 0.0
	var th := Relativity.angle_between(n_app, cam.view_dir())
	return exp(-th * th / (2.0 * pow(deg_to_rad(CENTRE_SIGMA_DEG), 2.0)))


## sky: Callable(n_ship: Vector3) -> cd/m^2 of the extended sky (panorama or
## the flat dark sky); sf may be null (no stars); cmb may be null.
func centre_weighted(cam: FreeLookCamera, size: Vector2, dir: Vector3, b: float, sky: Callable, sf: Starfield, cmb: CmbGlow, resolved_points: Array = []) -> float:
	var half_v := tan(deg_to_rad(cam.fov) * 0.5)
	var half_h := half_v * size.x / size.y
	var cell := (2.0 * half_h / GRID.x) * (2.0 * half_v / GRID.y)
	var sigma := deg_to_rad(CENTRE_SIGMA_DEG)
	var num := 0.0
	var den := 0.0
	for j in GRID.y:
		for i in GRID.x:
			var x := (2.0 * (i + 0.5) / GRID.x - 1.0) * half_h
			var y := (1.0 - 2.0 * (j + 0.5) / GRID.y) * half_v
			var q := 1.0 + x * x + y * y
			var om := cell / (q * sqrt(q)) # pinhole cell solid angle: cos^3 / f^2
			var th := acos(1.0 / sqrt(q))
			var w := exp(-th * th / (2.0 * sigma * sigma)) * om
			num += w * sky.call(cam.to_world(Vector3(x, y, -1.0).normalized()))
			den += w
	if sf != null and sf.count > 0:
		for k in bin_e.size():
			num += _weight(cam, Relativity.aberrate(bin_dir[k], dir, b), size) * seen_point(bin_e[k], bin_t[k], bin_dir[k], dir, b)
		for k in near:
			var n := Vector3(sf.pos[3 * k] - sf.ship[0], sf.pos[3 * k + 1] - sf.ship[1], sf.pos[3 * k + 2] - sf.ship[2]).normalized()
			num += _weight(cam, Relativity.aberrate(n, dir, b), size) * seen_point(sf.flux_at_ship(k), sf.custom[4 * k], n, dir, b)
	for p:Dictionary in resolved_points:
		num += _weight(cam, Relativity.aberrate(p.dir, dir, b), size) * seen_point(p.lux,p.t,p.dir,dir,b)
	if cmb != null and cmb.illuminance > 0.0:
		num += _weight(cam, dir, size) * cmb.illuminance
	return num / den
