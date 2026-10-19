class_name ShipCamera
extends Camera3D
## One observer in glTF metres. Infinite sky uses the same attitude and projection;
## camera translation only affects finite geometry and bubble wall intersections.
var yaw := .47
var tilt := -25.0
var pullback := 3.0
var external := false
var reference := false
var attitude_basis:=PackedFloat64Array()
var heading := PackedFloat64Array([0.,0.,-1.])
func _init() -> void:
	fov=78.;near=.05;far=1200.;keep_aspect=Camera3D.KEEP_HEIGHT
func follow(foot: Vector3, tilt_deg: float, yaw_rad: float, distance: float) -> void:
	tilt=tilt_deg;yaw=yaw_rad;pullback=distance
	var forward := Vector3(cos(yaw)*cos(deg_to_rad(tilt)),sin(deg_to_rad(tilt)),sin(yaw)*cos(deg_to_rad(tilt)))
	position=foot+Vector3.UP*1.7-forward*pullback
	basis=Basis.looking_at(forward,Vector3.UP)
	external=position.length()>=100.
## D-92 (R2-CAMERA-FORWARD §D1): the ONE map between glTF and the kinematic frame (+Z along the
## velocity, the frame of sunholo/relativity, the sky, the glow and the dust). Travel runs along the
## deck toward the bow (glTF -Z), the mast is kinematic +Y (glTF +Y), kinematic +X is glTF -X:
## ship_vector = R . ShipFrame.structure_from_gltf (R in interior/ship_frame.gd). Every kinematic
## conversion goes through these two functions (make camera-forward-test: the AC-B1 gate).
const TRAVEL_AXIS := "bow"
const BOW := Vector3(0.0, 0.0, -1.0) # the direction of travel, glTF (Vector3.FORWARD)
static func ship_vector(v: Vector3) -> Array:
	return [-v.x,v.y,-v.z]
static func gltf_from_ship(s: Array) -> Vector3:
	return Vector3(-float(s[0]),float(s[1]),-float(s[2]))
static func to_sky_direction(v: Vector3, h: PackedFloat64Array) -> Vector3:
	var gal := ShipFrame.to_galactic(ShipFrame.ship_basis(h),PackedFloat64Array(ship_vector(v)))
	return SkyFrame.to_world(Vector3(gal[0],gal[1],gal[2]))
func sync_sky(sky: InteriorSky, px: Vector2i) -> void:
	sky.cam={"position_m":ship_vector(position),"forward":ship_vector(-basis.z),"up":ship_vector(basis.y)}
	var projection_changed:bool=sky.view_fov!=fov or sky.size!=px
	sky.view_fov=fov;sky.camera.fov=fov
	if sky.size!=px:sky.resize(px)
	elif projection_changed:sky.configure_pixel()
	if sky.has_background:
		var photo: Texture2D=sky.background.material.get_shader_parameter("photo")
		if photo!=null:
			sky.background.material.set_shader_parameter("pano_px_per_screen_px",photo.get_height()/180.0*fov/maxi(px.y,1))
	var cs:Array=ship_vector(position)
	sky.glow_mat.set_shader_parameter("cam_ship",Vector3(cs[0],cs[1],cs[2]))
	sky.dust_mat.set_shader_parameter("cam_ship",Vector3(cs[0],cs[1],cs[2]))
	if attitude_basis.is_empty():sky.orient(heading)
	else:sky.orient_basis(attitude_basis)
	if projection_changed:sky.update_exposure()
	# External inspection is not an observer inside the bubble wall.
	if position.length()>=100.: sky.set_glow_pole(0.)
