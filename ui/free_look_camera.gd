class_name FreeLookCamera
extends Camera3D
## Free-look camera (M1.6b): yaw, pitch and roll, independent of the ship's
## velocity. The orientation is client state; it never goes to the sim.
##
## Orientation is Godot's YXZ Euler order, R = Ry(yaw) Rx(pitch) Rz(roll):
## yaw turns about the galaxy +Y (positive = left), pitch tilts the view up,
## roll turns about the view axis (positive = counter-clockwise, so the sky
## turns clockwise on screen). The float32 node transform drives the GPU;
## view_dir(), project() and the HUD angle use the same angles in float64
## scalars, an independent CPU path the physics tests and the golden check the
## GPU against (pinhole, vertical fov, Godot's default KEEP_HEIGHT).

const PITCH_LIMIT := 1.5 # rad; keeps the Euler pitch off the poles (gimbal)

var yaw := 0.0
var pitch := 0.0
var roll := 0.0


## Set the orientation (radians) and apply it to the node.
func look(y: float, p: float, r: float) -> void:
	yaw = y
	pitch = p
	roll = r
	transform.basis = Basis.from_euler(Vector3(pitch, yaw, roll))


## Interactive input: rates times delta, pitch clamped, roll wrapped to (-pi, pi].
func turn_by(dyaw: float, dpitch: float, droll: float) -> void:
	look(yaw + dyaw, clampf(pitch + dpitch, -PITCH_LIMIT, PITCH_LIMIT), wrapf(roll + droll, -PI, PI))


## R v in float64 scalars, as [x, y, z].
func _rotate(x: float, y: float, z: float) -> Array:
	var cr := cos(roll)
	var sr := sin(roll)
	var cp := cos(pitch)
	var sp := sin(pitch)
	var cy := cos(yaw)
	var sy := sin(yaw)
	var x1 := cr * x - sr * y # Rz(roll)
	var y1 := sr * x + cr * y
	var y2 := cp * y1 - sp * z # Rx(pitch)
	var z2 := sp * y1 + cp * z
	return [cy * x1 + sy * z2, y2, -sy * x1 + cy * z2] # Ry(yaw)


## R^T v in float64 scalars: galaxy frame -> camera frame, as [x, y, z].
func _to_camera(x: float, y: float, z: float) -> Array:
	var cr := cos(roll)
	var sr := sin(roll)
	var cp := cos(pitch)
	var sp := sin(pitch)
	var cy := cos(yaw)
	var sy := sin(yaw)
	var x1 := cy * x - sy * z # Ry(yaw)^T
	var z1 := sy * x + cy * z
	var y2 := cp * y + sp * z1 # Rx(pitch)^T
	var z2 := -sp * y + cp * z1
	return [cr * x1 + sr * y2, -sr * x1 + cr * y2, z2] # Rz(roll)^T


func _vec(a: Array) -> Vector3:
	return Vector3(a[0], a[1], a[2])


## A camera-frame direction (x right, y up, -z ahead) in the galaxy frame.
func to_world(v: Vector3) -> Vector3:
	return _vec(_rotate(v.x, v.y, v.z))


## Where the camera looks (its -Z), galaxy frame.
func view_dir() -> Vector3:
	return _vec(_rotate(0.0, 0.0, -1.0))


## The screen's right (+X) and up (+Y) directions, galaxy frame.
func screen_right() -> Vector3:
	return _vec(_rotate(1.0, 0.0, 0.0))


func screen_up() -> Vector3:
	return _vec(_rotate(0.0, 1.0, 0.0))


## True when an apparent direction lies in or behind the camera plane (the
## starfield shader culls these before projection, spec §2).
func is_behind(n: Vector3) -> bool:
	return float(_to_camera(n.x, n.y, n.z)[2]) >= 0.0


## Pixel position of an apparent (ship-frame) direction on a viewport of the
## given size: pinhole, vertical fov, y down, (0, 0) the top-left corner.
func project(n: Vector3, size: Vector2) -> Vector2:
	var c := _to_camera(n.x, n.y, n.z)
	var f: float = 0.5 * size.y / tan(deg_to_rad(fov) * 0.5)
	var depth: float = -c[2]
	return Vector2(0.5 * size.x + f * float(c[0]) / depth, 0.5 * size.y - f * float(c[1]) / depth)


## Angle between the view and the velocity direction, degrees. The boost
## axis is the same in the ship and galaxy frames; atan2(|v x h|, v . h)
## stays exact near 0 and 180, where acos loses digits.
func view_velocity_angle(heading: Vector3) -> float:
	var v := _rotate(0.0, 0.0, -1.0)
	var hx := heading.x
	var hy := heading.y
	var hz := heading.z
	var cx: float = v[1] * hz - v[2] * hy
	var cy: float = v[2] * hx - v[0] * hz
	var cz: float = v[0] * hy - v[1] * hx
	var dot: float = v[0] * hx + v[1] * hy + v[2] * hz
	return rad_to_deg(atan2(sqrt(cx * cx + cy * cy + cz * cz), dot))


## The HUD line: view-to-velocity angle and roll.
func hud_line(heading: Vector3) -> String:
	return "view/v %5.1f deg  roll %+6.1f deg" % [view_velocity_angle(heading), rad_to_deg(roll)]
