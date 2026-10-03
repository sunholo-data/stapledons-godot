class_name Starfield
extends MultiMeshInstance3D
## Catalogue stars rendered with exact aberration, Doppler colour and
## band-limited relativistic beaming (see starfield.gdshader). M1.3: binary
## tiers (sky/star_catalogue.gd), one MultiMesh instance per star.
##
## Precision (CLAUDE.md gate 5). Star positions are held on the CPU as float64
## world ly from Sol. Each instance carries the position relative to a rebase
## origin O split into a float32 pair, hi = f32(p - O) and lo = f32(p - O - hi);
## the ship's offset from O goes to the vertex shader as the same kind of pair.
## The shader forms rel = (hi - ship_hi) + (lo - ship_lo), which keeps the
## direction to a nearby star (the destination at the 1,000 AU stand-off) to
## float32 precision of |rel|, not of |p| (tests/test_physics.gd emulates it).
##   Rebase.CPU: O follows the ship; every move > REBASE_LY rewrites the buffer.
##   Rebase.GPU: O stays at Sol and the buffer is written once (design plan B).
## make bench times the CPU rebase; it measured > 4 ms on 324k stars, so GPU is
## the default (see the M1.3 notes in the sprint JSON).
##
## Instance custom data = (T_eff K, E_v lux at Sol via illuminanceFromV,
## flags, |p|^2 ly^2); the shader rescales E_v by |p|^2 / r^2 to the ship.

const SHADER := preload("res://sky/starfield.gdshader")
const REBASE_LY := 0.01
## Faint-star cull (starfield.gdshader cull_peak); make golden proves it is invisible.
const CULL_PEAK := 1e-4
const FLOATS := 16 # per instance: 12 transform (row-major 3x4) + 4 custom
enum Rebase { GPU, CPU }

## Galactic XYZ (x toward centre, z to north pole) -> Godot world (Y up).
## Galactic centre lies along -Z, which is Godot's default forward.
static func galactic_to_world(g: Vector3) -> Vector3:
	return Vector3(g.y, g.z, -g.x)


var rebase_mode := Rebase.GPU
var count := 0
var pos := PackedFloat64Array() # 3 per star: world ly from Sol, float64
var custom := PackedFloat32Array() # 4 per star: teff, E_v at Sol (lux), flags, |p|^2
var skipped_missing := 0 # MISSING_PHOT rows (teff 0, v 99): nothing to draw
var tiers: Array[String] = []
var last_error := ""
var ship := PackedFloat64Array([0.0, 0.0, 0.0])
var origin := PackedFloat64Array([0.0, 0.0, 0.0])
var rebases := 0
var last_rebase_ms := 0.0
var material: ShaderMaterial
var _buf := PackedFloat32Array()


func clear() -> void:
	count = 0
	pos.clear()
	custom.clear()
	skipped_missing = 0
	tiers.clear()


## The active tier, then on top: for medium/large (GCNS), quick's HIP-filled
## rows (flag 8: Sirius, alpha Cen, Procyon, ... which Gaia cannot measure, so
## GCNS has no photometry for them and the bright tier excludes them as CNS5
## matches), then the bright tier (M1.2d) when stars_bright.bin exists.
## A refused tier (sidecar, size or sha256) loads nothing: false.
func load_tiers(tier: String, dir := "res://data/starmap") -> bool:
	clear()
	var stack := [[tier, 0]]
	if tier != "quick":
		stack.append(["quick", StarCatalogue.FLAG_HIP])
	stack.append(["bright", 0])
	for entry in stack:
		var t: String = entry[0]
		if t == "bright" and not FileAccess.file_exists("%s/stars_bright.bin" % dir):
			continue
		var c := StarCatalogue.load_tier(t, dir)
		if c == null:
			last_error = "tier %s: %s" % [t, StarCatalogue.last_error]
			clear()
			return false
		append_catalogue(c, entry[1])
		tiers.append(t + (":hip" if entry[1] != 0 else ""))
	return true


## only_flags != 0: append only the rows carrying those flag bits.
func append_catalogue(c: StarCatalogue, only_flags := 0) -> void:
	var k := count
	pos.resize(3 * (count + c.count))
	custom.resize(4 * (count + c.count))
	var d := c.data
	for i in c.count:
		if only_flags != 0 and c.flags(i) & only_flags == 0:
			continue
		if c.missing_photometry(i):
			skipped_missing += 1
			continue
		var j := 6 * i
		# galactic (x, y, z) -> world (y, z, -x), widened to float64 before any arithmetic
		var x: float = d[j + 1]
		var y: float = d[j + 2]
		var z: float = -d[j]
		_put(k, x, y, z, d[j + 3], Relativity.illuminance_from_v(d[j + 4]), d[j + 5])
		k += 1
	count = k
	pos.resize(3 * count)
	custom.resize(4 * count)


func _put(k: int, x: float, y: float, z: float, teff: float, ev: float, flags: float) -> void:
	pos[3 * k] = x
	pos[3 * k + 1] = y
	pos[3 * k + 2] = z
	custom[4 * k] = teff
	custom[4 * k + 1] = ev
	custom[4 * k + 2] = flags
	custom[4 * k + 3] = x * x + y * y + z * z


## Synthetic stars (goldens, spikes): [{pos: Vector3 or [x, y, z] float64 world
## ly, t: kelvin, flux: illuminance at Sol in the caller's units}].
func set_custom_stars(list: Array) -> void:
	clear()
	append_stars(list)


func append_stars(list: Array) -> void:
	pos.resize(3 * (count + list.size()))
	custom.resize(4 * (count + list.size()))
	for s: Dictionary in list:
		var p = s["pos"]
		_put(count, p[0], p[1], p[2], s["t"], s["flux"], s.get("flags", 0.0))
		count += 1
	if multimesh != null:
		_fill()


func build() -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(2, 2)
	material = ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter("bb_lut", Blackbody.build_lut())
	material.set_shader_parameter("lut_log_tmin", log(Blackbody.LUT_T_MIN))
	material.set_shader_parameter("lut_log_tmax", log(Blackbody.LUT_T_MAX))
	material.set_shader_parameter("cull_peak", CULL_PEAK)
	quad.material = material
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = quad
	multimesh = mm
	# instances are drawn at their apparent direction, not their transform
	custom_aabb = AABB(Vector3(-1e9, -1e9, -1e9), Vector3(2e9, 2e9, 2e9))
	_fill()


## Writes every instance relative to the current origin, then the ship offset.
func _fill() -> void:
	var mm := multimesh
	mm.instance_count = count
	_buf.resize(FLOATS * count)
	var ox := origin[0]
	var oy := origin[1]
	var oz := origin[2]
	for k in count:
		var b := FLOATS * k
		var rx := pos[3 * k] - ox
		var ry := pos[3 * k + 1] - oy
		var rz := pos[3 * k + 2] - oz
		# origin (row ends 3, 7, 11) = hi; writing to a float32 array rounds, reading back gives f32(r)
		_buf[b + 3] = rx
		_buf[b + 7] = ry
		_buf[b + 11] = rz
		# basis column x (0, 4, 8) = lo, the rounding error of hi
		_buf[b] = rx - _buf[b + 3]
		_buf[b + 4] = ry - _buf[b + 7]
		_buf[b + 8] = rz - _buf[b + 11]
		var c := 4 * k
		_buf[b + 12] = custom[c]
		_buf[b + 13] = custom[c + 1]
		_buf[b + 14] = custom[c + 2]
		_buf[b + 15] = custom[c + 3]
	if count > 0:
		mm.buffer = _buf
	_upload_ship()


## x, y, z: the sim's float64 world position in ly (never through a Vector3).
func set_ship_position(x: float, y: float, z: float) -> void:
	ship[0] = x
	ship[1] = y
	ship[2] = z
	if rebase_mode == Rebase.CPU and _dist(ship, origin) > REBASE_LY:
		rebase()
	else:
		_upload_ship()


## Moves the origin to the ship and rewrites the buffer (timed).
func rebase() -> void:
	var t0 := Time.get_ticks_usec()
	origin[0] = ship[0]
	origin[1] = ship[1]
	origin[2] = ship[2]
	if multimesh != null:
		_fill()
	last_rebase_ms = (Time.get_ticks_usec() - t0) / 1000.0
	rebases += 1


func set_rebase_mode(mode: Rebase) -> void:
	rebase_mode = mode
	if mode == Rebase.GPU:
		origin = PackedFloat64Array([0.0, 0.0, 0.0])
		if multimesh != null:
			_fill()
	else:
		rebase()


func _upload_ship() -> void:
	if material == null:
		return
	var s := ship_pair()
	material.set_shader_parameter("ship_hi", s[0])
	material.set_shader_parameter("ship_lo", s[1])


## [hi, lo] float32 pair of the ship's offset from the origin.
func ship_pair() -> Array[Vector3]:
	var d := Vector3(ship[0] - origin[0], ship[1] - origin[1], ship[2] - origin[2])
	var lo := Vector3(ship[0] - origin[0] - d.x, ship[1] - origin[1] - d.y, ship[2] - origin[2] - d.z)
	return [d, lo]


static func _dist(a: PackedFloat64Array, b: PackedFloat64Array) -> float:
	return sqrt((a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2 + (a[2] - b[2]) ** 2)


## float64 CPU reference: unit direction ship -> star k, through the rebased
## coordinates, (p - O) - (ship - O).
func direction_to(k: int) -> PackedFloat64Array:
	var rx := (pos[3 * k] - origin[0]) - (ship[0] - origin[0])
	var ry := (pos[3 * k + 1] - origin[1]) - (ship[1] - origin[1])
	var rz := (pos[3 * k + 2] - origin[2]) - (ship[2] - origin[2])
	var r := sqrt(rx * rx + ry * ry + rz * rz)
	return PackedFloat64Array([rx / r, ry / r, rz / r])


static func f32(v: float) -> float:
	return PackedFloat32Array([v])[0]


## The vertex shader's rel vector for instance k, emulated in float32 (each
## operation rounded) from the uploaded buffer and ship uniforms. Unnormalised.
func shader_rel(k: int) -> PackedFloat64Array:
	var s := ship_pair()
	var b := FLOATS * k
	var out := PackedFloat64Array([0.0, 0.0, 0.0])
	for a in 3:
		var hi := _buf[b + 3 + 4 * a]
		var lo := _buf[b + 4 * a]
		out[a] = f32(f32(hi - s[0][a]) + f32(lo - s[1][a]))
	return out


## Visual-band flux of star k at the ship before beaming: E_v |p|^2 / r^2.
func flux_at_ship(k: int) -> float:
	var rx := pos[3 * k] - ship[0]
	var ry := pos[3 * k + 1] - ship[1]
	var rz := pos[3 * k + 2] - ship[2]
	return custom[4 * k + 1] * custom[4 * k + 3] / maxf(rx * rx + ry * ry + rz * rz, 1e-6)


## Splat energy (CPU mirror of the shader): flux x pointFluxRatio(T, D).
static func splat_energy(flux: float, t_kelvin: float, d: float) -> float:
	return flux * Relativity.point_flux_ratio(t_kelvin, d)


## direction: unit heading in the galaxy frame. beta and gamma come from the
## sim in float64; 1 - beta is formed here so it survives float32 upload.
func set_velocity(direction: Vector3, beta: float, gamma: float) -> void:
	material.set_shader_parameter("beta_dir", direction.normalized())
	material.set_shader_parameter("beta_mag", beta)
	material.set_shader_parameter("gamma_f", gamma)
	material.set_shader_parameter("one_minus_beta", 1.0 / (gamma * gamma * (1.0 + beta)))


## Linear radiance of the splat peak per unit of the flux in custom data.
func set_exposure(e: float) -> void:
	material.set_shader_parameter("exposure", e)
