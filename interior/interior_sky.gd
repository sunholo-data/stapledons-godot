class_name InteriorSky
extends SubViewport
## M4.2 layers 1-2: the M1 sky (background + catalogue stars + forward CMB) and the forward
## glow, rendered in their own World3D through the area's panorama camera and tonemapped ONCE
## here (AgX + the M1.5a photometric exposure). The parent composites the texture as is.
##
## Sky camera = cam_<area>.json x ship_basis(heading) (ShipFrame, float64, D-14: up = the
## direction of travel all journey, no flip). The galactic vectors go to Godot's sky frame
## (SkyFrame, D-28: a rotation, so the view is the camera JSON's, unmirrored) and become the FreeLookCamera's yaw, pitch and roll in
## float64, so the camera's CPU projection (FreeLookCamera.project) and the sky meter work on
## the interior view unchanged. The vertical fov is the plate's VIEW region's (the camera
## spans the overscanned plate; the screen shows the view region).
## Velocity comes from the sim only: ship.heading, beta, gamma, pos (galactic, the play
## session's frame) and ship.ism.glow_pole_w_m2 for the glow.

const GLOW_SHADER := preload("res://interior/glow_overlay.gdshader")

var env := Environment.new()
var camera := FreeLookCamera.new()
var starfield := Starfield.new()
var background := SkyBackground.new()
var exposure := Exposure.new()
var system_view := SystemView.new() # SD4: same camera/starfield/exposure as catalogue sky
var system_state := {} # authoritative protocol2.3 section, never synthesised
var resolved_bodies_supported := true # audited M5.3 inverse rays for moving resolved discs
var _debug_unit := false
var eye_meter := SkyMeter.new()
var glow := MeshInstance3D.new()
var glow_mat := ShaderMaterial.new()
var has_background := false
var cam := {} # cam_<area>.json (ship frame)
var view_fov := 78.0
var heading_gal := PackedFloat64Array([0.0, 0.0, -1.0])
var heading_world := Vector3(0.0, -1.0, 0.0)
var beta := 0.0
var glow_pole := -1.0 # the sim's W/m^2; -1 = the state carries none (glow off)
var radius_m := 100.0
var basis := PackedFloat64Array() # ship basis, galactic columns


## cam: the bundle's camera dictionary; fov_deg: the view region's vertical fov.
## opts: background (bool), stars (bool), tier (String).
func setup(cam_json: Dictionary, fov_deg: float, px: Vector2i, opts := {}) -> void:
	cam = cam_json
	view_fov = fov_deg
	size = px
	own_world_3d = true
	render_target_update_mode = SubViewport.UPDATE_ALWAYS
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.BLACK
	env.tonemap_mode = Environment.TONE_MAPPER_AGX # the one tonemap (G-M4-2)
	env.glow_enabled = true
	env.glow_bloom = 0.05
	env.glow_hdr_threshold = 1.0
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	camera.fov = view_fov
	camera.near = 0.1
	camera.far = 1000.0
	add_child(camera)
	camera.current = true
	if opts.get("stars", true):
		var tier: String = opts.get("tier", "")
		if tier == "":
			tier = "large" if FileAccess.file_exists("res://data/starmap/stars_large.bin") else "medium"
		if not starfield.load_tiers(tier):
			push_warning("interior sky: %s" % starfield.last_error)
	starfield.build() # an empty field still gets its material (goldens add custom stars)
	add_child(starfield)
	system_view.setup(starfield, opts.get("planet_textures", true))
	system_view.relativistic_enabled = opts.get("planet_relativistic", true)
	if opts.get("planet_smooth_lod",true):
		system_view.lod_range=Vector2(1.5,3.5)
		starfield.point_overlay=true
	if opts.get("planet_preload",true):system_view.preload_textures()
	add_child(system_view)
	if opts.get("background", true):
		has_background = background.attach(env, px.y, view_fov)
	var quad := QuadMesh.new()
	quad.size = Vector2(2.0, 2.0)
	glow.mesh = quad
	glow_mat.shader = GLOW_SHADER
	glow.material_override = glow_mat
	glow.extra_cull_margin = 16384.0
	glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(glow)
	var p: Array = cam["position_m"]
	glow_mat.set_shader_parameter("cam_ship", Vector3(p[0], p[1], p[2]))
	glow_mat.set_shader_parameter("colour", ForwardGlow.WHITE_RGB)
	configure_pixel()
	orient(heading_gal)


func resize(px: Vector2i) -> void:
	size = px
	configure_pixel()


## The exposure's pixel solid angle and the CMB PSF follow the render height (as main.gd).
func configure_pixel() -> void:
	exposure.configure(view_fov, size.y)
	system_view.set_view(exposure.pixel_rad, size.y)
	if has_background:
		background.set_psf(exposure.psf_sigma_rad())


## The sky camera for a galactic heading: ship_basis(heading) x cam.forward/up.
func orient(heading: PackedFloat64Array) -> void:
	heading_gal = heading
	orient_basis(ShipFrame.ship_basis(heading))

## Attitude only: leave simulation velocity/heading and clocks untouched.
func orient_basis(attitude:PackedFloat64Array)->void:
	if attitude.size()!=9:return
	basis=attitude.duplicate()
	var transform_direction:=func(v:Array)->PackedFloat64Array:
		return PackedFloat64Array([basis[0]*v[0]+basis[3]*v[1]+basis[6]*v[2],basis[1]*v[0]+basis[4]*v[1]+basis[7]*v[2],basis[2]*v[0]+basis[5]*v[1]+basis[8]*v[2]])
	var sc:={"forward":transform_direction.call(cam.forward),"up":transform_direction.call(cam.up)}
	var f := _to_world(sc["forward"])
	var u := _to_world(sc["up"])
	var e := euler_of(f, u)
	camera.look(e[0], e[1], e[2])
	var axes := []
	for i in 3:
		axes.append(_vec(_to_world(PackedFloat64Array([basis[3 * i], basis[3 * i + 1], basis[3 * i + 2]]))))
	glow_mat.set_shader_parameter("ship_x", axes[0])
	glow_mat.set_shader_parameter("ship_y", axes[1])
	glow_mat.set_shader_parameter("ship_z", axes[2])


## FreeLookCamera angles [yaw, pitch, roll] (YXZ, camera looks -Z) for a unit forward f and up
## u (Godot frame), float64.
static func euler_of(f: PackedFloat64Array, u: PackedFloat64Array) -> Array:
	var pitch := asin(clampf(f[1], -1.0, 1.0))
	var yaw := atan2(-f[0], -f[2])
	var r0 := [cos(yaw), 0.0, -sin(yaw)]
	var u0 := [sin(yaw) * sin(pitch), cos(pitch), cos(yaw) * sin(pitch)]
	var roll := atan2(-(u[0] * r0[0] + u[1] * r0[1] + u[2] * r0[2]), u[0] * u0[0] + u[1] * u0[1] + u[2] * u0[2])
	return [yaw, pitch, roll]


## Sim state -> sky. ship.heading / pos are galactic (play session); Godot's sky frame is
## SkyFrame, converted here in float64.
func apply(world: Dictionary) -> void:
	var s: Dictionary = world["ship"]
	var h: Dictionary = s["heading"]
	orient(PackedFloat64Array([h["x"], h["y"], h["z"]]))
	heading_world = _vec(_to_world(heading_gal))
	beta = s["beta"]
	starfield.set_velocity(heading_world, beta, s["gamma"])
	if has_background:
		background.set_velocity(heading_world, beta, s["gamma"])
	var p: Dictionary = s["pos"]
	var pw := SkyFrame.to_world64([p["x"], p["y"], p["z"]])
	starfield.set_ship_position(pw[0], pw[1], pw[2])
	var params: Variant = world.get("params")
	if params is Dictionary and params.has("bubble_radius_m"):
		radius_m = params["bubble_radius_m"]
	system_state = SimBridge.parse_system(world.get("system"))
	system_view.set_velocity(heading_world, beta, s["gamma"], s.get("one_minus_beta", 1.0 / (s["gamma"] * s["gamma"] * (1.0 + beta))))
	resolved_bodies_supported = beta == 0.0 or system_view.relativistic_enabled
	set_glow_pole(ForwardGlow.pole_of(world))


## The glow's pole emittance (W/m^2; < 0 = off) and the shared exposure.
func set_glow_pole(w: float) -> void:
	glow_pole = w
	update_exposure()


func update_exposure() -> void:
	system_view.set_view(exposure.pixel_rad,size.y)
	system_view.update(system_state,exposure.k())
	system_view.visible=resolved_bodies_supported and not _debug_unit
	var l_avg := background.meter(camera, heading_world, beta) if has_background else Exposure.dark_sky_luminance()
	exposure.update(l_avg, _meter_eye(), system_view.highlight_luminance(camera,Vector2(size)))
	starfield.set_exposure(exposure.star_scale())
	starfield.set_psf(exposure.psf_sigma_px())
	starfield.set_floor(exposure.floor_params())
	if has_background:
		background.set_scene_exposure(exposure.k())
	system_view.set_exposure(exposure.k())
	# Unresolved points share the relativistic starfield. Resolved discs use the
	# audited M5.3 inverse rays, or are hidden if the caller explicitly opts out.
	system_view.visible = resolved_bodies_supported and not _debug_unit
	glow_mat.set_shader_parameter("radius", radius_m)
	glow_mat.set_shader_parameter("pole", maxf(glow_pole, 0.0))
	glow_mat.set_shader_parameter("scale", exposure.k() * ForwardGlow.LM_PER_W / PI)


## The glow's luminance (cd/m^2) seen along a world (sky-frame) direction.
func glow_luminance(n: Vector3) -> float:
	if glow_pole <= 0.0 or basis.is_empty():
		return 0.0
	var g := SkyFrame.to_galactic64([n.x, n.y, n.z])
	var d := ShipFrame.to_ship(basis, g)
	var p: Array = cam["position_m"]
	var c := ForwardGlow.wall_cos(PackedFloat64Array([p[0], p[1], p[2]]), d, radius_m)
	return ForwardGlow.luminance(ForwardGlow.profile(glow_pole, c)) if not is_nan(c) else 0.0


## The eye's centre-weighted meter (M1.8) sees the stars, the CMB and, here, the glow.
func _meter_eye() -> float:
	if starfield.count > 0 and eye_meter.needs_build(starfield):
		eye_meter.build(starfield)
	var sky := func(n: Vector3) -> float:
		return (background.seen_luminance(n, heading_world, beta) if has_background else Exposure.dark_sky_luminance()) + glow_luminance(n) + system_view.eye_luminance(n)
	return eye_meter.centre_weighted(camera, Vector2(size), heading_world, beta, sky, starfield, background.cmb if beta > 0.0 and has_background else null, system_view.compact_meter_sources())


## Unit-gain debug render for G-M4-4 (W/m^2 in a linear float target, no exposure/tonemap).
func set_debug_unit(on: bool) -> void:
	_debug_unit = on
	system_view.visible = resolved_bodies_supported and not on
	glow_mat.set_shader_parameter("debug_unit", on)
	use_hdr_2d = on
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR if on else Environment.TONE_MAPPER_AGX
	env.tonemap_exposure = 1.0
	env.glow_enabled = not on
	starfield.visible = not on
	if has_background:
		env.background_mode = Environment.BG_COLOR if on else Environment.BG_SKY


static func _to_world(g: PackedFloat64Array) -> PackedFloat64Array:
	return SkyFrame.to_world64(g)


static func _vec(a: PackedFloat64Array) -> Vector3:
	return Vector3(a[0], a[1], a[2])
