class_name SystemView
extends Node3D
## The bodies of the system the ship is in (M5.2a), fed only by the sim's
## `system` section (SimBridge.system, protocol 2.3): every number drawn is a
## sim field or a mirrored package function of sim fields (physics/planets.gd).
##
## Each body is either
##   a point  (below Planets.DISC_PX across): handed to the starfield
##            (Starfield.add_point_sources) with its e_v_lux and the solar colour
##            T_SUN, so aberration, the band-ratio Doppler and the PSF are the stars'.
##   a disc   (DISC_PX or more): an exact ray-traced sphere (planets/planet.gdshader)
##            placed PLACE units out along its float64 direction, radius PLACE R / d
##            (precision gate 5: no raw km ever enters a Vector3), Minnaert-lit by its
##            star, albedo texture normalised to the data's p_V, pre-exposed by Exposure.k.
## Bodies too faint and too small to matter (below CULL_LUX_FRACTION of the
## naked-eye threshold and under CULL_PX across) are culled here, not in the sim.
## Directions use SkyFrame (D-28), the same right-handed map as the stars,
## so a planet sits where the starfield would put a star in that direction.
## At rest only: the relativistic view of resolved bodies is M5.3.

const SHADER := preload("res://planets/planet.gdshader")
const CULL_LUX_FRACTION := 1e-4
const CULL_PX := 0.1
const TEX_DIR := "res://assets/planets"
## Exported builds: assets/planets is .gdignore'd, so `make planet-bundle` stages byte copies
## as res://planet_bundle/<file>.bin (the .bin keeps the editor from importing them).
const BUNDLE_DIR := "res://planet_bundle"
const ALBEDO_TABLE := "res://data/planets/ALBEDO"

var starfield: Starfield
var px_rad := 1.0 # angular size of the centre pixel (Exposure.pixel_rad)
var view_height_px := 540.0
## id -> {"file", "k", "mean"} from data/planets/ALBEDO, and id -> ImageTexture once loaded.
var albedo_table := {}
var textures := {}
var use_textures := true
var discs := {} # id -> MeshInstance3D (hidden when not a disc this frame)
var drawn_points: Array[String] = []
var drawn_discs: Array[String] = []
var e1_au := 0.0 # the star's illuminance at 1 AU, recovered from the sim's own star row


func setup(sf: Starfield, load_textures := true) -> void:
	starfield = sf
	use_textures = load_textures
	albedo_table = read_albedo_table(ALBEDO_TABLE)


## data/planets/ALBEDO rows "id file k mean": the texture's disc-integrated mean
## linear luminance for that body's Minnaert k (tools/planet_textures.gd writes it).
static func read_albedo_table(path: String) -> Dictionary:
	var out := {}
	if not FileAccess.file_exists(path):
		return out
	for line in FileAccess.get_file_as_string(path).split("\n"):
		var f := line.strip_edges().split(" ", false)
		if f.size() == 4 and not f[0].begins_with("#"):
			out[f[0]] = {"file": f[1], "k": float(f[2]), "mean": float(f[3])}
	return out


## [albedo, clouds or null], or [] without a texture (the file field may be "day.jpg+clouds.jpg").
func _textures(id: String) -> Array:
	if not use_textures or not albedo_table.has(id):
		return []
	if not textures.has(id):
		var out := []
		for f: String in String(albedo_table[id]["file"]).split("+"):
			var img := load_texture_image(f)
			if img == null:
				out = []
				break
			img.generate_mipmaps()
			out.append(ImageTexture.create_from_image(img))
		textures[id] = out
	return textures[id]


## A texture's image: the source checkout's assets/planets, else the export bundle; null if neither.
static func load_texture_image(file: String, tex_dir := TEX_DIR, bundle_dir := BUNDLE_DIR) -> Image:
	var path := tex_dir.path_join(file)
	if FileAccess.file_exists(path):
		return Image.load_from_file(path)
	var bundled := bundle_dir.path_join(file + ".bin")
	if not FileAccess.file_exists(bundled):
		return null
	var img := Image.new()
	var bytes := FileAccess.get_file_as_bytes(bundled)
	var err := img.load_jpg_from_buffer(bytes) if file.get_extension() == "jpg" else img.load_png_from_buffer(bytes)
	return img if err == OK else null


func set_view(pixel_rad: float, height_px: float) -> void:
	px_rad = pixel_rad
	view_height_px = height_px


## One `system` section -> points and discs. k: Exposure.k() (linear pixel per cd/m^2).
func update(system: Dictionary, k: float) -> void:
	drawn_points.clear()
	drawn_discs.clear()
	if starfield != null:
		starfield.clear_point_sources()
	for d: MeshInstance3D in discs.values():
		d.visible = false
	var bodies: Array = system.get("bodies", [])
	_find_e1(bodies)
	var points := []
	var order := []
	var floor_lux := CULL_LUX_FRACTION * Exposure.threshold_lux()
	for b: Dictionary in bodies:
		var w := Planets.world_of(b["rel_km"])
		var dist := Planets.length64(w)
		var r: float = b["radius_km"]
		if dist <= r * 1.001: # the ship is inside (or on) the body: nothing to draw from here
			continue
		var px := Planets.diameter_px(r, dist, px_rad)
		if px >= Planets.DISC_PX:
			order.append([dist, b])
		elif b["e_v_lux"] >= floor_lux or px >= CULL_PX:
			points.append({"dir": [w[0] / dist, w[1] / dist, w[2] / dist], "lux": b["e_v_lux"], "t": Planets.T_SUN})
			drawn_points.append(b["id"])
	if starfield != null and not points.is_empty():
		starfield.add_point_sources(points)
	order.sort_custom(func(a, c): return a[0] > c[0]) # far to near: nearer discs draw over farther ones
	for i in order.size():
		_draw_disc(order[i][1], k, i)


## The star's 1 AU illuminance, from the sim's own rows: the star's e_v_lux =
## e1 / d^2 when the ship is outside it, else inverted from a lit body's
## discIlluminance (e1 = E r^2 / (p (R/d)^2 Phi)); the protocol carries no e1.
func _find_e1(bodies: Array) -> void:
	for b: Dictionary in bodies:
		var d := Planets.length64(Planets.world_of(b["rel_km"]))
		if b["kind"] == "star" and d > b["radius_km"] and b["e_v_lux"] > 0.0:
			e1_au = b["e_v_lux"] * (d / AU_KM) * (d / AU_KM)
			return
	for b: Dictionary in bodies:
		var d := Planets.length64(Planets.world_of(b["rel_km"]))
		if b["kind"] == "star" or b["p_v"] <= 0.0 or b["r_au"] <= 0.0 or d <= b["radius_km"]:
			continue
		var unit := Planets.disc_illuminance(1.0, b["p_v"], b["radius_km"], b["r_au"], d, deg_to_rad(b["phase_deg"]), b["minnaert_k"])
		if unit > 0.0 and Planets.phase_function(deg_to_rad(b["phase_deg"]), b["minnaert_k"]) > 0.1:
			e1_au = b["e_v_lux"] / unit
			return

const AU_KM := 149597870.7 # IAU 2012 B2 (the package's auKm)


func _draw_disc(b: Dictionary, k: float, rank: int) -> void:
	var id: String = b["id"]
	var mi: MeshInstance3D = discs.get(id)
	if mi == null:
		mi = MeshInstance3D.new()
		var quad := QuadMesh.new()
		quad.size = Vector2(2, 2)
		mi.mesh = quad
		mi.material_override = ShaderMaterial.new()
		mi.material_override.shader = SHADER
		mi.extra_cull_margin = 16384.0 # the vertex shader places the quad; never frustum-cull it
		add_child(mi)
		discs[id] = mi
	var m: ShaderMaterial = mi.material_override
	m.render_priority = clampi(1 + rank, 1, 127) # after the stars (priority 0), far to near
	var pl := Planets.place(b["rel_km"], b["radius_km"])
	m.set_shader_parameter("centre_w", pl[1])
	m.set_shader_parameter("radius", pl[2])
	m.set_shader_parameter("exposure", k)
	var diam := Planets.diameter_px(b["radius_km"], pl[3], px_rad)
	m.set_shader_parameter("ss", 8 if diam < 32.0 else 3)
	var star: bool = b["kind"] == "star"
	m.set_shader_parameter("star", star)
	m.set_shader_parameter("tint", Blackbody.rgb_unit_luminance(Planets.T_SUN))
	if star:
		var ang := Planets.angular_radius(b["radius_km"], pl[3])
		m.set_shader_parameter("star_mean", b["e_v_lux"] / (PI * sin(ang) * sin(ang)))
		m.set_shader_parameter("limb_u", Planets.SUN_LIMB_U)
	else:
		var kk: float = b["minnaert_k"]
		var sd := Planets.world_of(b["sun_dir"])
		m.set_shader_parameter("sun_dir_w", Vector3(sd[0], sd[1], sd[2]).normalized())
		m.set_shader_parameter("rho", Planets.rho_from_geometric_albedo(b["p_v"], kk))
		m.set_shader_parameter("minnaert_k", kk)
		m.set_shader_parameter("lux", Planets.star_illuminance_at(e1_au, b["r_au"]) if b["r_au"] > 0.0 else 0.0)
		m.set_shader_parameter("body_basis", Planets.body_basis(b["pole"], b["w_deg"]))
		var tex := _textures(id)
		var row: Dictionary = albedo_table.get(id, {})
		# the table's mean was computed for this body's k; a different k in the data means re-run the tool
		var ok := not tex.is_empty() and is_equal_approx(float(row.get("k", -1.0)), kk)
		m.set_shader_parameter("textured", ok)
		if ok:
			m.set_shader_parameter("albedo_tex", tex[0])
			m.set_shader_parameter("clouds", tex.size() > 1)
			if tex.size() > 1:
				m.set_shader_parameter("cloud_tex", tex[1])
			m.set_shader_parameter("albedo_mean", row["mean"])
			m.set_shader_parameter("tex_lod", maxf(0.0, log(tex[0].get_width() / (PI * diam)) / log(2.0)))
	mi.visible = true
	drawn_discs.append(id)
