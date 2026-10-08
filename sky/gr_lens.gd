class_name GrLens
extends RefCounted
## M3.5 of R1-M3-BLACK-HOLES: the sim's `gr` state on the GPU (relativity spec §3).
##
## set_gr(gr) takes the sim's gr section (protocol 2.6: r, shadow, blueshift, hole_dir,
## dir_local, beta_local, gamma_local, one_minus_beta_local; vectors galactic) and uploads only
## those values, through float64 scalars, to the sky background (sky/background.gdshader) and
## the starfield (sky/starfield.gdshader), both of which include sky/schwarzschild.gdshaderinc.
## No physics is computed here: the per-r scalars of the table lookup (fractional row, last
## column) are the CPU mirror's (physics/schwarzschild.gd), and the shadow angle goes up as a
## float32 hi/lo pair of the sim's float64 value.
##
## Stars (M3.5b): the order-1 images are a second MultiMeshInstance3D on the starfield's
## multimesh with image_order = 1; it exists only while GR is on. Ring stars: a star whose image
## is stretched over Schwarzschild.RING_STRETCH (inside Schwarzschild.ring_cones) leaves the
## splat path; the brightest RING_MAX of them are flagged (flags bit RING_FLAG, no splat) and
## drawn by the sky pass as source-plane Gaussians; the rest stay splats with mu capped at 8, and
## ring_overflow counts them (debug_line(); never silent).
##
## Candidates for the ring path lie within CONE of h or of -h. Finding them visits every star
## once; tick() does it in CHUNK-star slices per frame whenever h has moved by more than
## REFRESH_RAD or the ship or the catalogue changed, and refresh_now() does it at once (goldens).

const RING_MAX := 64
const RING_FLAG := 64 # starfield flags bit (catalogue bits are 1..16)
const CONE := 0.1425 # rad: asin(1/8) = 0.1253 (any stretch > 8) plus a REFRESH margin
const REFRESH_RAD := 0.0087 # 0.5 deg
const CHUNK := 10000

static var _tex: Array = []

var starfield: Starfield
var background: SkyBackground # null: no sky pass, so no ring stars (all stay splats)
var active := false
var state := {}
var h := Vector3(0.0, 0.0, -1.0) # world, toward the hole
var order1: MultiMeshInstance3D
var order1_material: ShaderMaterial
var ring := PackedInt32Array() # flagged star indices, brightest first
var ring_overflow := 0
var star_exposure := 0.0
var cones := PackedFloat64Array([0.0, 0.0])
var _cand := PackedInt32Array()
var _scan := PackedInt32Array()
var _scan_pos := -1 # >= 0 while a chunked sweep runs
var _scan_h := Vector3.ZERO
var _cand_key := []
var _cand_h := Vector3.ZERO
var _cones_r := -1.0
var _flag_rev := -1 # starfield.identity_revision the ring flags were written for


func _init(sf: Starfield, bg: SkyBackground = null) -> void:
	starfield = sf
	background = bg


## lens_fwd and lens_inv as RGF float textures (the mirror's float32 texels, unfiltered).
static func textures() -> Array:
	if _tex.is_empty():
		if Schwarzschild.fwd_table().is_empty() and not Schwarzschild.load_tables():
			push_error("gr lens: %s" % Schwarzschild.load_error)
			return []
		for tab: PackedFloat32Array in [Schwarzschild.fwd_table(), Schwarzschild.inv_table()]:
			var img := Image.create_from_data(Schwarzschild.N_COLS, Schwarzschild.N_ROWS, false, Image.FORMAT_RGF, tab.to_byte_array())
			_tex.append(ImageTexture.create_from_image(img))
	return _tex


## psi_i - alpha of the 2048 lens_fwd columns at shadow angle a (float64, then float32): column i
## sits at x = x_min + (x_max - x_min) i / 2047, x = ln((psi - alpha)/alpha); the last is pi - alpha.
static func column_offsets(a: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(Schwarzschild.N_COLS)
	var x0 := Schwarzschild.x_min()
	var dx := (log((PI - a) / a) - x0) / float(Schwarzschild.N_COLS - 1)
	for i in Schwarzschild.N_COLS - 1:
		out[i] = a * exp(x0 + dx * float(i))
	out[Schwarzschild.N_COLS - 1] = PI - a
	return out


static var _cols_tex: ImageTexture
static var _cols_a := -1.0


## The column texture for shadow angle a (one hole at a time: rebuilt when a changes).
static func column_image(a: float) -> ImageTexture:
	if a != _cols_a or _cols_tex == null:
		var img := Image.create_from_data(Schwarzschild.N_COLS, 1, false, Image.FORMAT_RF, column_offsets(a).to_byte_array())
		if _cols_tex == null:
			_cols_tex = ImageTexture.create_from_image(img)
		else:
			_cols_tex.update(img)
		_cols_a = a
	return _cols_tex


static func _vec_of(v: Variant) -> PackedFloat64Array:
	if v is Dictionary:
		return PackedFloat64Array([v["x"], v["y"], v["z"]])
	return PackedFloat64Array([v[0], v[1], v[2]])


static func _world(v: Variant) -> Vector3:
	var w := SkyFrame.to_world64(_vec_of(v))
	return Vector3(w[0], w[1], w[2]).normalized()


## The shader uniforms for a gr state (float64 in, float32 out only at upload).
static func uniforms(gr: Dictionary) -> Dictionary:
	var r: float = gr["r"]
	var a: float = gr["shadow"]
	var pair := Schwarzschild.hi_lo(a)
	var tex := textures()
	return {
		"gr_on": true, "gr_fwd": tex[0], "gr_inv": tex[1], "gr_h": _world(gr["hole_dir"]),
		"gr_alpha_hi": pair[0], "gr_alpha_lo": pair[1], "gr_cols": column_image(a),
		"gr_row": Schwarzschild.row_coordinate(minf(r, Schwarzschild.R_WEAK)),
		"gr_x_min": Schwarzschild.x_min(), "gr_x_max": log((PI - a) / a),
		"gr_weak": r > Schwarzschild.R_WEAK, "gr_weak_k": sqrt(1.0 - 1.0 / r) / r,
		"gr_dg": gr["blueshift"],
	}


## A gr state from the CPU reference, in the sim's field names, for goldens and captures only
## (the game takes the sim's): a static observer at r looking at hole_dir (galactic), moving at
## beta_local along dir_local (galactic) relative to it.
static func reference_state(r: float, hole_dir: PackedFloat64Array, beta_local := 0.0, dir_local := PackedFloat64Array([1.0, 0.0, 0.0])) -> Dictionary:
	var g := Relativity.gamma_of(beta_local) # beta_local <= 0.5 here (orbit speed at r >= 2)
	return {"r": r, "shadow": Schwarzschild.shadow_angle(r), "blueshift": Schwarzschild.static_blueshift(r),
		"hole_dir": hole_dir, "dir_local": dir_local, "beta_local": beta_local, "gamma_local": g,
		"one_minus_beta_local": 1.0 / (g * g * (1.0 + beta_local))}


## Sim gr section -> GPU. Empty (or a state without r) switches GR off.
func set_gr(gr: Dictionary) -> void:
	if gr.is_empty() or not gr.has("r") or textures().is_empty():
		clear()
		return
	state = gr
	active = true
	h = _world(gr["hole_dir"])
	var u := uniforms(gr)
	for k: String in u:
		starfield._parameter(k, u[k])
	starfield.set_velocity(_world(gr["dir_local"]), gr["beta_local"], gr["gamma_local"])
	if background != null:
		background.set_gr(gr)
	_ensure_order1()
	var r: float = gr["r"]
	if absf(r - _cones_r) > 1e-4 * r:
		cones = Schwarzschild.ring_cones(r)
		_cones_r = r
	if _cand_key.is_empty() or acos(clampf(h.dot(_cand_h), -1.0, 1.0)) > REFRESH_RAD or _cand_key != _key():
		if _scan_pos < 0:
			_scan_pos = 0
			_scan = PackedInt32Array()
			_scan_h = h
	_select()


## GR off: SR uniforms go back to the caller's next set_velocity; the order-1 instance is freed.
func clear() -> void:
	active = false
	state = {}
	starfield._parameter("gr_on", false)
	if background != null:
		background.set_gr({})
		background.material.set_shader_parameter("gr_ring_count", 0)
	if _flag_rev == starfield.identity_revision:
		_unflag(ring)
	ring = PackedInt32Array()
	ring_overflow = 0
	if order1 != null:
		starfield.extra_materials.erase(order1_material)
		order1.queue_free()
		order1 = null
	_scan_pos = -1
	_cand_key = []


func _ensure_order1() -> void:
	if order1 == null:
		order1_material = starfield.material.duplicate()
		order1_material.set_shader_parameter("image_order", 1)
		starfield.extra_materials.append(order1_material)
		order1 = MultiMeshInstance3D.new()
		order1.material_override = order1_material
		order1.custom_aabb = starfield.custom_aabb
		starfield.add_child(order1)
	if order1.multimesh != starfield.multimesh:
		order1.multimesh = starfield.multimesh


func _key() -> Array:
	return [starfield.identity_revision, starfield.count, snappedf(starfield.ship[0], 0.01), snappedf(starfield.ship[1], 0.01), snappedf(starfield.ship[2], 0.01)]


## One CHUNK of the candidate sweep; call once per frame.
func tick() -> void:
	if not active or _scan_pos < 0:
		return
	_sweep(_scan_pos, mini(_scan_pos + CHUNK, starfield.count))
	_scan_pos += CHUNK
	if _scan_pos >= starfield.count:
		_finish_sweep()


## The whole sweep now (goldens, captures, the first frame of a new state).
func refresh_now() -> void:
	if not active:
		return
	_scan = PackedInt32Array()
	_scan_h = h
	_sweep(0, starfield.count)
	_finish_sweep()


## |cos(angle to h)| > cos CONE  <=>  (rel . h)^2 > cos^2 CONE |rel|^2: no sqrt, no allocation.
func _sweep(from: int, to: int) -> void:
	var c2 := cos(CONE) * cos(CONE)
	var p := starfield.pos
	var sx := starfield.ship[0]
	var sy := starfield.ship[1]
	var sz := starfield.ship[2]
	var hx := _scan_h.x
	var hy := _scan_h.y
	var hz := _scan_h.z
	for k in range(from, to):
		var rx := p[3 * k] - sx
		var ry := p[3 * k + 1] - sy
		var rz := p[3 * k + 2] - sz
		var d := rx * hx + ry * hy + rz * hz
		if d * d > c2 * (rx * rx + ry * ry + rz * rz):
			_scan.append(k)


func _finish_sweep() -> void:
	_cand = _scan
	_cand_h = _scan_h
	_cand_key = _key()
	_scan_pos = -1
	_select()


## The ring set: candidates inside the cones, brightest (flux at the ship) first, at most RING_MAX.
func _select() -> void:
	var inside := []
	for k in _cand:
		if k >= starfield.count:
			continue
		var d := starfield.direction_to(k)
		var beta := Schwarzschild.angle(Vector3(d[0], d[1], d[2]), h)
		if beta < cones[0] or beta > PI - cones[1]:
			inside.append([starfield.flux_at_ship(k), k])
	inside.sort_custom(func(x: Array, y: Array) -> bool: return x[0] > y[0] or (x[0] == y[0] and x[1] < y[1]))
	var next := PackedInt32Array()
	if background != null:
		for i in mini(inside.size(), RING_MAX):
			next.append(inside[i][1])
	ring_overflow = inside.size() - next.size()
	if next != ring or _flag_rev != starfield.identity_revision:
		if _flag_rev == starfield.identity_revision:
			_unflag(ring)
		ring = next
		for k in ring:
			_set_flag(k, true)
		_flag_rev = starfield.identity_revision
	_upload_ring()


func _set_flag(k: int, on: bool) -> void:
	var f := int(starfield.custom[4 * k + 2])
	f = (f | RING_FLAG) if on else (f & ~RING_FLAG)
	starfield.custom[4 * k + 2] = f
	if starfield.multimesh != null and k < starfield.multimesh.instance_count:
		starfield.multimesh.set_instance_custom_data(k, Color(starfield.custom[4 * k], starfield.custom[4 * k + 1], f, starfield.custom[4 * k + 3]))


func _unflag(list: PackedInt32Array) -> void:
	for k in list:
		if k < starfield.count:
			_set_flag(k, false)


## Linear splat peak per lux (Exposure.star_scale) and the PSF sigma (rad) of the ring Gaussians.
func set_exposure(e: float, sigma_rad: float) -> void:
	star_exposure = e
	if background != null:
		background.material.set_shader_parameter("gr_ring_sigma", sigma_rad)
	_upload_ring()


func _upload_ring() -> void:
	if background == null:
		return
	var dirs := []
	var peaks := PackedFloat32Array()
	for k in ring:
		var d := starfield.direction_to(k)
		dirs.append(Vector4(d[0], d[1], d[2], starfield.custom[4 * k]))
		peaks.append(starfield.flux_at_ship(k) * star_exposure)
	while dirs.size() < RING_MAX:
		dirs.append(Vector4.ZERO)
		peaks.append(0.0)
	background.material.set_shader_parameter("gr_ring", dirs)
	background.material.set_shader_parameter("gr_ring_peak", peaks)
	background.material.set_shader_parameter("gr_ring_count", ring.size())


## The HUD's debug line (M3.6 shows it).
func debug_line() -> String:
	if not active:
		return "GR off"
	return "GR r %s r_s; ring stars %d (overflow %d as splats, mu capped at 8)" % [state["r"], ring.size(), ring_overflow]
