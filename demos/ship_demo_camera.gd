extends Camera3D
## One observer in glTF metres. Infinite sky uses the same attitude and projection;
## camera translation only affects finite geometry and bubble wall intersections.
var yaw := .47
var tilt := -25.0
var pullback := 3.0
var external := false
var reference := false
var heading := PackedFloat64Array([0.,0.,-1.])
func _init() -> void:
	fov=78.;near=.05;far=1200.;keep_aspect=Camera3D.KEEP_HEIGHT
func follow(foot: Vector3, tilt_deg: float, yaw_rad: float, distance: float) -> void:
	tilt=tilt_deg;yaw=yaw_rad;pullback=distance
	var forward := Vector3(cos(yaw)*cos(deg_to_rad(tilt)),sin(deg_to_rad(tilt)),sin(yaw)*cos(deg_to_rad(tilt)))
	position=foot+Vector3.UP*1.7-forward*pullback
	basis=Basis.looking_at(forward,Vector3.UP)
	external=position.length()>=100.
static func ship_vector(v: Vector3) -> Array:
	return [v.x,-v.z,v.y]
static func to_sky_direction(v: Vector3, h: PackedFloat64Array) -> Vector3:
	var gal := ShipFrame.to_galactic(ShipFrame.ship_basis(h),PackedFloat64Array(ship_vector(v)))
	return SkyFrame.to_world(Vector3(gal[0],gal[1],gal[2]))
func sync_sky(sky: InteriorSky, px: Vector2i) -> void:
	sky.cam={"position_m":ship_vector(position),"forward":ship_vector(-basis.z),"up":ship_vector(basis.y)}
	sky.view_fov=fov;sky.camera.fov=fov
	if sky.size!=px: sky.resize(px)
	sky.configure_pixel()
	sky.glow_mat.set_shader_parameter("cam_ship",Vector3(position.x,-position.z,position.y))
	sky.orient(heading)
	# External inspection is not an observer inside the bubble wall.
	if position.length()>=100.: sky.set_glow_pole(0.)
