class_name ShipFrame
## M4.0 frame contract (design m4-first-journey.md "M4.0", brief §5.2, D-14), float64 throughout.
##
##   ship frame : +Z = direction of travel, origin = bubble centre, metres (the frame every
##                cam_<area>.json and the Blender scenes use: "+Z = direction of travel (up)").
##   up         : the direction of travel for the WHOLE journey. There is no flip at turnover
##                (D-14): braking is a thrust reversal, not a ship rotation, so the dome's
##                forward pole always faces the heading. ship_basis therefore takes no phase.
##   roll       : ship +Y = the north galactic pole projected onto the plane normal to the
##                heading; within 1e-6 (the projection's length, i.e. sin of the angle) of
##                either galactic pole it falls back to galactic +X projected the same way.
##
## Vectors are galactic Cartesian (x toward the galactic centre, z to the north galactic pole),
## the frame of stars.json and the sim. A basis is a PackedFloat64Array of 9: the ship X, Y and
## Z axes as galactic column vectors [Xx, Xy, Xz, Yx, Yy, Yz, Zx, Zy, Zz]. Godot's Basis and
## Vector3 are float32, so they never hold these; convert at the render edge only.

const NGP := [0.0, 0.0, 1.0]
const POLE_FALLBACK := [1.0, 0.0, 0.0]
const POLE_EPS := 1e-6


## The ship basis for a heading (any length > 0; normalised here in float64). An empty array
## for a zero, non-finite or not-3-long heading: the caller must not orient the ship on garbage.
static func ship_basis(heading: PackedFloat64Array) -> PackedFloat64Array:
	if heading.size() != 3:
		return PackedFloat64Array()
	var n := sqrt(heading[0] * heading[0] + heading[1] * heading[1] + heading[2] * heading[2])
	if not (n > 0.0) or is_inf(n):
		return PackedFloat64Array()
	var z := [heading[0] / n, heading[1] / n, heading[2] / n]
	var y := _reject(NGP, z)
	if _len(y) < POLE_EPS:
		y = _reject(POLE_FALLBACK, z)
	# Just outside the fallback the projection is ~1e-6 long and plain Gram-Schmidt leaves
	# |Y . Z| ~1e-10; re-deriving X and Y by cross products keeps the basis orthonormal to
	# float64 rounding (tests/test_physics.gd checks both at 1.0-1.3e-6 rad from each pole).
	var x := _unit(_cross(_unit(y), z))
	y = _cross(z, x)
	return PackedFloat64Array([x[0], x[1], x[2], y[0], y[1], y[2], z[0], z[1], z[2]])


## ship-frame vector -> galactic: B v
static func to_galactic(b: PackedFloat64Array, v: PackedFloat64Array) -> PackedFloat64Array:
	var out := PackedFloat64Array([0.0, 0.0, 0.0])
	for k in 3:
		out[k] = b[k] * v[0] + b[3 + k] * v[1] + b[6 + k] * v[2]
	return out


## galactic vector -> ship frame: B^T v (B is orthonormal)
static func to_ship(b: PackedFloat64Array, v: PackedFloat64Array) -> PackedFloat64Array:
	var out := PackedFloat64Array([0.0, 0.0, 0.0])
	for i in 3:
		out[i] = b[3 * i] * v[0] + b[3 * i + 1] * v[1] + b[3 * i + 2] * v[2]
	return out


static func det(b: PackedFloat64Array) -> float:
	return (b[0] * (b[4] * b[8] - b[5] * b[7]) - b[3] * (b[1] * b[8] - b[2] * b[7])
		+ b[6] * (b[1] * b[5] - b[2] * b[4]))


## The sky camera: ship_basis(heading) x cam.forward / cam.up, as galactic float64 vectors
## {"forward", "up"}. `cam` is a cam_<area>.json dictionary (ship frame).
static func sky_camera(heading: PackedFloat64Array, cam: Dictionary) -> Dictionary:
	var b := ship_basis(heading)
	if b.is_empty():
		return {}
	return {
		"forward": to_galactic(b, PackedFloat64Array(cam["forward"])),
		"up": to_galactic(b, PackedFloat64Array(cam["up"])),
	}


static func _reject(v: Array, z: Array) -> Array:
	var d: float = v[0] * z[0] + v[1] * z[1] + v[2] * z[2]
	return [v[0] - d * z[0], v[1] - d * z[1], v[2] - d * z[2]]


static func _cross(a: Array, b: Array) -> Array:
	return [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]


static func _len(a: Array) -> float:
	return sqrt(a[0] * a[0] + a[1] * a[1] + a[2] * a[2])


static func _unit(a: Array) -> Array:
	var n := _len(a)
	return [a[0] / n, a[1] / n, a[2] / n]
