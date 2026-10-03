class_name SkyFrame
## THE galactic <-> Godot world map (D-28, 2026-10-03). It is defined here and nowhere else in
## GDScript; shaders #include "res://sky/sky_frame.gdshaderinc", which carries the same matrix
## (tests/test_physics.gd test_sky_frame checks the two agree and that no hand copy is left).
##
##   galactic (IAU, stars.json, the sim): x toward the galactic centre (l 0, b 0), y toward
##            l 90, z to the north galactic pole (NGP). Right-handed.
##   world (Godot): Y up, cameras look down -Z, screen right = forward x up = +X. Right-handed.
##
##   world = R g,  R = [[0, -1, 0], [0, 0, 1], [-1, 0, 0]]   (x, y, z) -> (-y, z, -x)
##   galactic = R^T w                                         (x, y, z) -> (-z, -x, y)
##   det R = +1: a rotation, so the rendered sky is the real sky, not its mirror image.
##
## Facing the galactic centre (world -Z) with the NGP up (world +Y), the right hand (+X,
## starboard) points at l 270 and the left (-X, port) at l 90, as on the real sky: Antares
## (l 352) and alpha Cen (l 316) sit right of the centre, Vega (l 67) and the Scutum cloud
## (l 27) left of it; galactic longitude grows to the LEFT.
## Before D-28 the map was (x, y, z) -> (y, z, -x), det -1: every M1 view (stars, panorama,
## sky model, CMB, galaxy map) was a mirror image, and M4.2 undid it locally (SKY_FLIP_H).

## Rows of R (world = R g), float64.
const R := [[0.0, -1.0, 0.0], [0.0, 0.0, 1.0], [-1.0, 0.0, 0.0]]


## galactic -> world (float32 Vector3; exact, it only permutes and negates components).
static func to_world(g: Vector3) -> Vector3:
	return Vector3(-g.y, g.z, -g.x)


## world -> galactic (float32 Vector3).
static func to_galactic(w: Vector3) -> Vector3:
	return Vector3(-w.z, -w.x, w.y)


## galactic -> world in float64 scalars (gate 5): g is any indexable [x, y, z].
static func to_world64(g) -> PackedFloat64Array:
	return PackedFloat64Array([-float(g[1]), float(g[2]), -float(g[0])])


## world -> galactic in float64 scalars: w is any indexable [x, y, z].
static func to_galactic64(w) -> PackedFloat64Array:
	return PackedFloat64Array([-float(w[2]), -float(w[0]), float(w[1])])


## The world direction of galactic longitude l and latitude b (degrees), float64.
static func world_dir_lb(l_deg: float, b_deg: float) -> PackedFloat64Array:
	var l := deg_to_rad(l_deg)
	var b := deg_to_rad(b_deg)
	return to_world64([cos(b) * cos(l), cos(b) * sin(l), sin(b)])


## Galactic [l, b] in degrees (l in [0, 360)) of a world direction, float64.
static func lb_of_world(w) -> PackedFloat64Array:
	var g := to_galactic64(w)
	var n := sqrt(g[0] * g[0] + g[1] * g[1] + g[2] * g[2])
	return PackedFloat64Array([fposmod(rad_to_deg(atan2(g[1], g[0])), 360.0), rad_to_deg(asin(clampf(g[2] / n, -1.0, 1.0)))])
