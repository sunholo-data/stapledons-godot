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
var relativistic_enabled := false # enable only after M5.3 package/GPU gates
var velocity_heading := Vector3(0,0,-1)
var velocity_beta := 0.0
var velocity_gamma := 1.0
var velocity_omb := 1.0
var bb_lut: ImageTexture
var rendered_bodies: Array = []
var meter_images := {}
var ring_systems := {} # optional protocol2.5 authority table; host -> data
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


func set_velocity(heading: Vector3, beta: float, gamma: float, omb: float) -> void:
	velocity_heading=heading; velocity_beta=beta; velocity_gamma=gamma; velocity_omb=omb


func set_view(pixel_rad: float, height_px: float) -> void:
	px_rad = pixel_rad
	view_height_px = height_px


## One `system` section -> points and discs. k: Exposure.k() (linear pixel per cd/m^2).
func update(system: Dictionary, k: float) -> void:
	rendered_bodies.clear()
	drawn_points.clear()
	drawn_discs.clear()
	if starfield != null:
		starfield.clear_point_sources()
	for d: MeshInstance3D in discs.values():
		d.visible = false
	ring_systems.clear()
	for ring: Dictionary in system.get("rings", []):
		if ring.has("host") and ring.get("bands",[]).size()<=16:ring_systems[ring.host]=ring
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
		var extent:=r
		for band: Dictionary in ring_systems.get(b.get("ring_id",""),{}).get("bands",[]):extent=maxf(extent,band.r_out_km)
		var px := _diameter_seen(w, extent, dist)
		if px >= Planets.DISC_PX:
			order.append([dist, b])
		elif b["e_v_lux"] >= floor_lux or px >= CULL_PX:
			points.append({"dir": [w[0] / dist, w[1] / dist, w[2] / dist], "lux": b["e_v_lux"], "t": Planets.T_SUN})
			drawn_points.append(b["id"])
	if starfield != null and not points.is_empty():
		starfield.add_point_sources(points)
	order.sort_custom(func(a, c): return a[0] > c[0]) # far to near: nearer discs draw over farther ones
	for i in order.size():
		var record:Dictionary=order[i][1].duplicate(true)
		record["_place"]=Planets.place(record.rel_km,record.radius_km)
		record["_basis"]=Planets.body_basis(record.pole,record.w_deg)
		var sun_array:=Planets.world_of(record.sun_dir)
		record["_sun"]=Vector3(sun_array[0],sun_array[1],sun_array[2]).normalized() if record.kind!="star" else Vector3.ZERO
		rendered_bodies.append(record)
		_draw_disc(order[i][1], k, i)


## The star's 1 AU illuminance, from the sim's own rows: the star's e_v_lux =
## e1 / d^2 when the ship is outside it, else inverted from a lit body's
## discIlluminance (e1 = E r^2 / (p (R/d)^2 Phi)); the protocol carries no e1.
func _diameter_seen(w: PackedFloat64Array, r: float, dist: float) -> float:
	if not relativistic_enabled or velocity_beta<=0.0:return Planets.diameter_px(r,dist,px_rad)
	var c := (w[0]*velocity_heading.x+w[1]*velocity_heading.y+w[2]*velocity_heading.z)/dist
	return 2.0*Planets.apparent_disc64(c,Planets.angular_radius(r,dist),velocity_beta,velocity_gamma)[1]/px_rad


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
	var moving := relativistic_enabled and velocity_beta > 0.0
	m.set_shader_parameter("beta_dir", velocity_heading)
	m.set_shader_parameter("beta_mag", velocity_beta if moving else 0.0)
	m.set_shader_parameter("gamma_f", velocity_gamma)
	m.set_shader_parameter("one_minus_beta", velocity_omb)
	if moving:
		if bb_lut == null: bb_lut=Blackbody.build_lut()
		m.set_shader_parameter("bb_lut",bb_lut)
		m.set_shader_parameter("lut_log_tmin",log(Blackbody.LUT_T_MIN))
		m.set_shader_parameter("lut_log_tmax",log(Blackbody.LUT_T_MAX))
	m.set_shader_parameter("radius", pl[2])
	m.set_shader_parameter("exposure", k)
	var diam := _diameter_seen(Planets.world_of(b["rel_km"]),b["radius_km"],pl[3])
	m.set_shader_parameter("ss", 8 if diam < 32.0 else 3)
	var star: bool = b["kind"] == "star"
	m.set_shader_parameter("star", star)
	m.set_shader_parameter("tint", Blackbody.rgb_unit_luminance(Planets.T_SUN))
	if star:
		m.set_shader_parameter("ring_count",0)
		m.set_shader_parameter("ring_outer",1.0)
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
		var ring:Dictionary=ring_systems.get(b.get("ring_id",""),{})
		var bands:=PackedVector4Array()
		var outer:=1.0
		for band:Dictionary in ring.get("bands",[]):
			bands.append(Vector4(band.r_in_km/b["radius_km"],band.r_out_km/b["radius_km"],band.tau,band.w0))
			outer=maxf(outer,band.r_out_km/b["radius_km"])
		var ring_count:=bands.size();while bands.size()<16:bands.append(Vector4.ZERO)
		m.set_shader_parameter("ring_count",ring_count)
		m.set_shader_parameter("ring_bands",bands)
		m.set_shader_parameter("ring_outer",outer)
		var rt:Dictionary=ring.get("tint",{"r":1.0,"g":1.0,"b":1.0})
		m.set_shader_parameter("ring_tint",Vector3(rt.r,rt.g,rt.b))
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


## Physical ray radiance before exposure: CPU mirror of the exact resolved
## sphere/ring sampling. Used by the eye/highlight meter and independent GPU
## goldens. No ephemeris or illumination is invented here.
func ray_colour(direction: PackedFloat64Array, skip_compact_meter := false) -> Vector3:
	var rest:=direction
	var doppler:=1.0
	if relativistic_enabled and velocity_beta>0.0:
		var h:=PackedFloat64Array([velocity_heading.x,velocity_heading.y,velocity_heading.z])
		rest=Planets.inverse_ray64(direction,h,velocity_beta,velocity_gamma,velocity_omb)
		doppler=Planets.doppler_seen64(direction,h,velocity_beta,velocity_gamma,velocity_omb)
	var ray:=Vector3(rest[0],rest[1],rest[2])
	var colour:=Vector3.ZERO
	for b:Dictionary in rendered_bodies:
		if skip_compact_meter and _compact_meter_body(b):continue
		var pl:Array=b._place
		var centre:Vector3=pl[1];var radius:float=pl[2]
		var along:=ray.dot(centre);var perpendicular:=centre-along*ray
		var h2:=radius*radius-perpendicular.length_squared()
		var distance:=1e30;var value:=Vector3.ZERO;var alpha:=0.0
		var star:bool=b.kind=="star"
		var sun:=Vector3.ZERO
		var basis:Basis=b._basis
		var ring:Dictionary=ring_systems.get(b.get("ring_id",""),{}) if not star else {}
		if not star:
			sun=b._sun
		if along>0.0 and h2>=0.0:
			distance=along-sqrt(h2)
			var n:Vector3=(ray*distance-centre)/radius
			var ce:=n.dot(-ray)
			if star:
				var angle:=Planets.angular_radius(b.radius_km,pl[3])
				value=Blackbody.rgb_unit_luminance(Planets.T_SUN)*Planets.limb_darkened(b.e_v_lux/(PI*sin(angle)*sin(angle)),ce)
			else:
				var ci:=n.dot(sun)
				if ci>0.0 and ce>=0.0:
					var radiance:=Planets.minnaert_radiance(Planets.rho_from_geometric_albedo(b.p_v,b.minnaert_k),b.minnaert_k,Planets.star_illuminance_at(e1_au,b.r_au),ci,ce)
					if not ring.is_empty():
						radiance*=Planets.ring_shadow_transmission(ring.bands,PackedFloat64Array([n.x*b.radius_km,n.y*b.radius_km,n.z*b.radius_km]),PackedFloat64Array([sun.x,sun.y,sun.z]),PackedFloat64Array([basis.z.x,basis.z.y,basis.z.z]))
					value=_surface_colour(b,n,basis)*radiance
			alpha=1.0
		if not ring.is_empty():
			var hit:=Planets.ring_plane_hit(PackedFloat64Array([-centre.x,-centre.y,-centre.z]),rest,PackedFloat64Array([basis.z.x,basis.z.y,basis.z.z]))
			if hit.hits and hit.distance<distance:
				var band:=Planets.ring_band(ring.bands,hit.radius*b.radius_km/radius)
				if band.tau>0.0:
					var p:Vector3=ray*hit.distance-centre
					var mu0:=absf(sun.dot(basis.z));var lit:=(-ray).dot(basis.z)*sun.dot(basis.z)>0.0
					var along_sun:=p.dot(sun);var perp_sun:=p-along_sun*sun
					var shadow:=along_sun<0.0 and perp_sun.length_squared()<radius*radius
					var light:=0.0 if shadow else (Planets.ring_lit_radiance(band.w0,1.0,band.tau,mu0,hit.mu,Planets.star_illuminance_at(e1_au,b.r_au)) if lit else Planets.ring_unlit_radiance(band.w0,1.0,band.tau,mu0,hit.mu,Planets.star_illuminance_at(e1_au,b.r_au)))
					var trans:=Planets.ring_transmission(band.tau,hit.mu)
					value=Vector3(ring.tint.r,ring.tint.g,ring.tint.b)*light+trans*value
					alpha=1.0-trans+trans*alpha
		colour=value+(1.0-alpha)*colour
	if doppler!=1.0:
		var rgb_rest:=Blackbody.lut_rgb(Planets.T_SUN);var rgb_seen:=Blackbody.lut_rgb(Planets.T_SUN*doppler)
		colour=colour*rgb_seen/rgb_rest*pow(10.0,Blackbody.lut_log10_y(Planets.T_SUN*doppler)-Blackbody.lut_log10_y(Planets.T_SUN))
	return colour


func _surface_colour(b:Dictionary,n:Vector3,basis:Basis)->Vector3:
	var tex:=_textures(b.id);var row:Dictionary=albedo_table.get(b.id,{})
	if tex.is_empty() or not is_equal_approx(float(row.get("k",-1.0)),b.minnaert_k):return Blackbody.rgb_unit_luminance(Planets.T_SUN)
	if not meter_images.has(b.id):
		var imgs:=[];for texture:ImageTexture in tex:imgs.append(texture.get_image())
		meter_images[b.id]=imgs
	var bn:=basis.transposed()*n;var uv:=Vector2(.5+atan2(bn.y,bn.x)/TAU,.5-asin(clampf(bn.z,-1.0,1.0))/PI)
	var images:Array=meter_images[b.id];var color:=_image_colour(images[0],uv)
	if images.size()>1:color=color.lerp(Vector3.ONE,_image_colour(images[1],uv).x)
	return color/row.mean

static func _image_colour(img:Image,uv:Vector2)->Vector3:
	var px:=Vector2(fposmod(uv.x,1.0)*img.get_width()-.5,clampf(uv.y,0,1)*img.get_height()-.5)
	var x:=int(floor(px.x));var y:=int(floor(px.y));var fx:=px.x-x;var fy:=px.y-y
	var colours:=[]
	for yy in [y,y+1]:
		var a:=img.get_pixel(posmod(x,img.get_width()),clampi(yy,0,img.get_height()-1)).srgb_to_linear()
		var c:=img.get_pixel(posmod(x+1,img.get_width()),clampi(yy,0,img.get_height()-1)).srgb_to_linear()
		colours.append(a.lerp(c,fx))
	var out:Color=colours[0].lerp(colours[1],fy)
	return Vector3(out.r,out.g,out.b)


func set_exposure(k:float)->void:
	for id:String in drawn_discs:
		(discs[id].material_override as ShaderMaterial).set_shader_parameter("exposure",k)

func seen_luminance(n:Vector3)->float:
	if not visible:return 0.0
	var colour:=ray_colour(PackedFloat64Array([n.x,n.y,n.z]))
	return .2126729*colour.x+.7151522*colour.y+.0721750*colour.z

## Presentation histogram; luminance comes exclusively from the package-backed
## physical renderer. The regular grid/percentile is a metering policy, not physics.
func highlight_luminance(cam:FreeLookCamera,size_px:Vector2)->float:
	if not visible or rendered_bodies.is_empty():return 0.0
	var samples:=PackedFloat64Array();var half_v:=tan(deg_to_rad(cam.fov)*.5);var half_h:=half_v*size_px.x/size_px.y
	for j in 18:
		for i in 32:
			var n:=cam.to_world(Vector3((2.*(i+.5)/32.-1.)*half_h,(1.-2.*(j+.5)/18.)*half_v,-1.).normalized())
			samples.append(seen_luminance(n))
	samples.sort();return samples[int(floor(.995*(samples.size()-1)))]

## Identification masking: solid globes (including night faces and the Sun)
## cover a star. Finite ring optical depths transmit; they are not solid walls.
func occludes_direction(observed_ray:PackedFloat64Array)->bool:
	var opacity:=_f32(1.0-_directional_transmission(observed_ray,true))
	return opacity>=1.0

func directional_transmission(observed_ray:PackedFloat64Array)->float:
	return _directional_transmission(observed_ray,false)

static func _f32(value:float)->float:
	return PackedFloat32Array([value])[0]

func _directional_transmission(observed_ray:PackedFloat64Array,renderer_precision:bool)->float:
	if not visible:return 1.0
	var rest:=observed_ray
	if relativistic_enabled and velocity_beta>0.0:
		rest=Planets.inverse_ray64(observed_ray,PackedFloat64Array([velocity_heading.x,velocity_heading.y,velocity_heading.z]),velocity_beta,velocity_gamma,velocity_omb)
	var ray:=Vector3(rest[0],rest[1],rest[2]);var transmission:=1.0
	for b:Dictionary in rendered_bodies:
		var pl:Array=b._place;var centre:Vector3=pl[1];var radius:float=pl[2]
		var along:=ray.dot(centre);var perpendicular:=centre-along*ray
		if along>0.0 and perpendicular.length_squared()<=radius*radius:return 0.0
		var ring:Dictionary=ring_systems.get(b.get("ring_id",""),{})
		if not ring.is_empty():
			var basis:Basis=b._basis
			var hit:=Planets.ring_plane_hit(PackedFloat64Array([-centre.x,-centre.y,-centre.z]),rest,PackedFloat64Array([basis.z.x,basis.z.y,basis.z.z]))
			if hit.hits:
				var layer:=Planets.ring_transmission(Planets.ring_band(ring.bands,hit.radius*b.radius_km/radius).tau,hit.mu)
				if renderer_precision:
					# GLSL computes float alpha=1-trans, then ordered alpha blending.
					var alpha:=_f32(1.0-_f32(layer))
					transmission=_f32(transmission*_f32(1.0-alpha))
				else:transmission*=layer
	return transmission


## Meter policy only: sub-degree discs are integrated using their authoritative
## illuminance, via SkyMeter's existing point limit. This prevents a sparse
## field grid missing the Sun or a small bright moon. Extended discs retain
## ray sampling; this does not alter rendered geometry/radiance.
func _compact_meter_body(b:Dictionary)->bool:
	var pl:Array=b._place
	return _diameter_seen(Planets.world_of(b.rel_km),b.radius_km,pl[3])*px_rad<deg_to_rad(2.0)

func compact_meter_sources()->Array:
	var points:=[]
	if not visible:return points
	for b:Dictionary in rendered_bodies:
		if _compact_meter_body(b):
			var pl:Array=b._place
			points.append({"dir":pl[0],"lux":b.e_v_lux,"t":Planets.T_SUN})
	return points

func eye_luminance(n:Vector3)->float:
	if not visible:return 0.0
	var colour:=ray_colour(PackedFloat64Array([n.x,n.y,n.z]),true)
	return .2126729*colour.x+.7151522*colour.y+.0721750*colour.z
