class_name TelescopeView
extends PanelContainer
## R2-STAR-SURFACES D-111 A1: the helm's telescope. At the navigation console close-up, T shows the
## current stop's star through the ship's telescope, magnified N times (true angular magnification:
## the disc's angular radius in the panel over its true one), labelled "telescope ×N". Two levels:
## whole disc, and close (a convection cell 2.5 px across where N allows). The disc is drawn at N times
## its angular radius in a fixed 14 deg field (Camera3D stops at 1 deg).
## The Bow view stays true-size. Self-contained: its own SubViewport and world; the star's disc is
## drawn with the sky's own material, copied each frame (every physical uniform: flux, exposure,
## Doppler, the surface record), and only the gate's pixel scale and the normaliser are the
## telescope's, so granules, spots and faculae resolve wherever the magnified disc allows.

const PANEL_PX := 520
const FOV_DEG := 14.0 # the telescope camera's field; magnification scales the disc, not the field (Camera3D stops at 1 deg)
const FILL := 0.7 # "whole disc": the disc's diameter as a fraction of the panel
const CELL_PX := 2.5 # "close": the magnification at which a convection cell is 2.5 px across
const MAX_HALF_RAD := 1.0 # the magnified disc's largest angular radius (rad): the camera stays outside the sphere
const N_MIN := 1.0
const N_MAX := 5000.0

var sv: SystemView
var view_fov_deg := 78.0
var star_id := ""
var magnification := 1.0
## 1 "whole disc" (the disc fills FILL of the panel), 2 "close" (cells CELL_PX across, or as close as
## N_MAX and MAX_HALF_RAD allow; the panel then shows the disc's centre).
var level := 1
var _vp: SubViewport
var _cam: Camera3D
var _disc: MeshInstance3D
var _mat: ShaderMaterial
var _label: Label


func _init() -> void:
	name = "Telescope"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := VBoxContainer.new()
	add_child(box)
	_label = Label.new()
	_label.add_theme_font_size_override("font_size", 18)
	box.add_child(_label)
	var tex := TextureRect.new()
	tex.custom_minimum_size = Vector2(PANEL_PX, PANEL_PX)
	box.add_child(tex)
	var hint := Label.new()
	hint.text = "true magnification · the Bow view is true size · T: whole disc, close, off"
	hint.add_theme_font_size_override("font_size", 13)
	box.add_child(hint)
	_vp = SubViewport.new()
	_vp.size = Vector2i(PANEL_PX, PANEL_PX)
	_vp.own_world_3d = true
	_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_vp)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.BLACK
	env.tonemap_mode = Environment.TONE_MAPPER_AGX # the sky's one tonemap (InteriorSky)
	var we := WorldEnvironment.new()
	we.environment = env
	_vp.add_child(we)
	_cam = Camera3D.new()
	_cam.keep_aspect = Camera3D.KEEP_HEIGHT
	_cam.near = 0.05
	_cam.far = 4000.0
	_vp.add_child(_cam)
	_cam.current = true
	_disc = MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(2, 2)
	_disc.mesh = q
	_disc.extra_cull_margin = 16384.0
	_mat = ShaderMaterial.new()
	_mat.shader = SystemView.SHADER
	_disc.material_override = _mat
	_vp.add_child(_disc)
	tex.texture = _vp.get_texture()


## The star to show: the stop body when it is a star, else the brightest drawn star disc.
func pick_star(world: Dictionary) -> String:
	var best := ""
	var best_ang := 0.0
	for b: Dictionary in world.get("system", {}).get("bodies", []):
		if b.get("kind", "") != "star" or not sv.discs.has(b.id) or not (sv.discs[b.id] as MeshInstance3D).visible:
			continue
		var d := Planets.length64(Planets.world_of(b.rel_km))
		var a := Planets.angular_radius(b.radius_km, d)
		if a > best_ang:
			best_ang = a
			best = b.id
	return best


## Draw the star: copy the sky's material, aim the camera, set the magnification and the gate.
## Returns false when there is no star disc to show.
func refresh(world: Dictionary) -> bool:
	if sv == null:
		return false
	star_id = pick_star(world)
	if star_id.is_empty():
		_label.text = "telescope · no star in view"
		_disc.visible = false
		return false
	var b: Dictionary = {}
	for x: Dictionary in world.system.bodies:
		if x.id == star_id:
			b = x
	var src: ShaderMaterial = (sv.discs[star_id] as MeshInstance3D).material_override
	for u: Dictionary in src.shader.get_shader_uniform_list():
		_mat.set_shader_parameter(u.name, src.get_shader_parameter(u.name))
	var centre: Vector3 = src.get_shader_parameter("centre_w")
	var d := Planets.length64(Planets.world_of(b.rel_km))
	var ang := Planets.angular_radius(b.radius_km, d)
	var px_rad := deg_to_rad(FOV_DEG) / float(_vp.size.y)
	var want_half := FILL * 0.5 * deg_to_rad(FOV_DEG) # whole disc
	var surface0: Dictionary = b.get("surface", {})
	if level == 2 and not surface0.is_empty():
		var cells := 2.0 * float(b.radius_km) / float(surface0.cell_km)
		want_half = CELL_PX * cells * 0.5 * px_rad # the disc radius at which a cell is CELL_PX across
	magnification = clampf(want_half / ang, N_MIN, N_MAX)
	var half := minf(ang * magnification, MAX_HALF_RAD)
	magnification = half / ang
	# Magnify by drawing the same star at N times its angular radius (the sky's material; surface
	# brightness, colour and Doppler are unchanged, as through a real telescope)
	_mat.set_shader_parameter("radius", centre.length() * sin(half))
	_mat.set_shader_parameter("bounded_draw", false)
	_mat.set_shader_parameter("beta_mag", 0.0)
	_cam.fov = FOV_DEG
	_cam.look_at_from_position(Vector3.ZERO, centre, Vector3.UP if absf(centre.normalized().y) < 0.95 else Vector3.RIGHT)
	var px_r := half / px_rad
	_mat.set_shader_parameter("ss", 3)
	var surface: Dictionary = b.get("surface", {})
	if not surface.is_empty():
		var basis := StarSurface.basis_of(b["pole"])
		var u := StarSurface.uniforms(surface, star_id, b.radius_km, px_r, basis, -centre.normalized())
		_mat.set_shader_parameter("px_per_radius", px_r)
		_mat.set_shader_parameter("surf_on", u.surf_on and sv.surfaces_enabled)
		if u.surf_on and sv.surfaces_enabled:
			for k: String in ["cells_across", "sigma_t", "facula_sigma_t", "salt0", "salt1", "spot_count", "spots", "spot_temps"]:
				_mat.set_shader_parameter(k, u[k])
			_mat.set_shader_parameter("fade_w", u.fade_w)
			_mat.set_shader_parameter("body_basis", basis)
			_mat.set_shader_parameter("bb_lut", sv.bb_lut if sv.bb_lut != null else Blackbody.build_lut())
			_mat.set_shader_parameter("lut_log_tmin", log(Blackbody.LUT_T_MIN))
			_mat.set_shader_parameter("lut_log_tmax", log(Blackbody.LUT_T_MAX))
			_mat.set_shader_parameter("surf_norm", sv.surface_norm(star_id + "@telescope", u.params, u.view_star, sv.surface_norm_wait).n)
	_disc.visible = true
	_label.text = "telescope ×%s %s · %s" % [_fmt(magnification), "whole disc" if level == 1 else "close", str(b.get("name", star_id))]
	return true


static func _fmt(n: float) -> String:
	return "%d" % roundi(n) if n >= 10.0 else "%.1f" % n
