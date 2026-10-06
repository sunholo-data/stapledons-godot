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

## Galactic XYZ (x toward centre, z to north pole) -> Godot world (Y up): SkyFrame.to_world,
## the one right-handed map (D-28; galactic centre along -Z, Godot's forward; l 270 along +X).
## Kept as the public name other code (galaxy map, planets) already calls.
static func galactic_to_world(g: Vector3) -> Vector3:
	return SkyFrame.to_world(g)


## Inverse of galactic_to_world: SkyFrame.to_galactic.
static func world_to_galactic(w: Vector3) -> Vector3:
	return SkyFrame.to_galactic(w)


var rebase_mode := Rebase.GPU
var count := 0
var pos := PackedFloat64Array() # 3 per star: world ly from Sol, float64
var custom := PackedFloat32Array() # 4 per star: teff, E_v at Sol (lux), flags, |p|^2
var ids: Array[String] = [] # same filtered, stacked order as pos/custom
var identity_revision := 0
var _replacement_revision := -1
var _replacement_ids: Array[String] = []
var _replaced_flux := {}
var catalogue_replacement_sources := {}
var replacement_revision := 0
var skipped_missing := 0 # MISSING_PHOT rows (teff 0, v 99): nothing to draw
var tiers: Array[String] = []
var last_error := ""
var ship := PackedFloat64Array([0.0, 0.0, 0.0])
var origin := PackedFloat64Array([0.0, 0.0, 0.0])
var rebases := 0
var last_rebase_ms := 0.0
var material: ShaderMaterial
var _buf := PackedFloat32Array()


## Tier identities hidden in favour of a pinned destination row (pin_destination).
var pinned_ids: Array[String] = []
var _requested_replacements: Array[String] = []


func clear() -> void:
	identity_revision += 1
	pinned_ids.clear()
	_requested_replacements.clear()
	_replaced_flux.clear()
	catalogue_replacement_sources.clear()
	_replacement_revision = -1
	count = 0
	pos.clear()
	custom.clear()
	ids.clear()
	skipped_missing = 0
	tiers.clear()


## Exact catalogue rows replaced by physical emitters. Reversible and cached:
## scanning the catalogue happens only when IDs or the catalogue change.
func set_catalogue_replacements(requested: Array[String]) -> void:
	_requested_replacements = requested.duplicate()
	var replacements: Array[String] = requested.duplicate()
	# A pinned destination replaced by a physical emitter is suppressed with its identity.
	for id in requested:
		if ("pin:" + id) in ids and not ("pin:" + id) in replacements: replacements.append("pin:" + id)
	for id in pinned_ids:
		if not id in replacements: replacements.append(id)
	if replacements == _replacement_ids and _replacement_revision == identity_revision:
		return
	_replacement_ids = replacements.duplicate()
	_replacement_revision = identity_revision
	var changed := false
	for row in count:
		if ids[row] in replacements:
			if not _replaced_flux.has(row): _replaced_flux[row] = custom[4 * row + 1]
			if custom[4 * row + 1] != 0.0: changed = true
			custom[4 * row + 1] = 0.0
		elif _replaced_flux.has(row):
			custom[4 * row + 1] = _replaced_flux[row]
			_replaced_flux.erase(row)
			changed = true
	if changed and multimesh != null: _fill()


## A destination renders where the simulation navigates (RT4 finding,
## 2026-10-06): the GCNS tier can place a star thousands of AU from the
## navigation catalogue (stars.json), which matters at a 1,000 AU stand-off.
## row is the stars.json entry; tier rows with its identity (the full id, or the
## bare Gaia number) are hidden and one row is added at its exact position with
## its catalogue V and Teff. Idempotent; clear() drops it.
func pin_destination(row: Dictionary) -> void:
	var id := str(row.get("id", ""))
	if id.is_empty() or ("pin:" + id) in ids: return
	for alias: String in [id, id.trim_prefix("Gaia DR3 ")]:
		if alias in ids and not alias in pinned_ids: pinned_ids.append(alias)
	append_stars([{"id": "pin:" + id, "pos": SkyFrame.to_world64(PackedFloat64Array([row.x, row.y, row.z])), "t": float(row.teff), "flux": Relativity.illuminance_from_v(float(row.vmag))}])
	set_catalogue_replacements(_requested_replacements)


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
	identity_revision += 1
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
		# galactic -> world (SkyFrame, D-28), widened to float64 before any arithmetic
		var w := SkyFrame.to_world64([d[j], d[j + 1], d[j + 2]])
		_put(k, w[0], w[1], w[2], d[j + 3], Relativity.illuminance_from_v(d[j + 4]), d[j + 5])
		ids.append(c.ids[i] if c.ids.size() == c.count else "")
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
	identity_revision += 1
	pos.resize(3 * (count + list.size()))
	custom.resize(4 * (count + list.size()))
	for s: Dictionary in list:
		var p = s["pos"]
		_put(count, p[0], p[1], p[2], s["t"], s["flux"], s.get("flags", 0.0))
		ids.append(s.get("id", ""))
		count += 1
	if multimesh != null:
		_fill()


func build() -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(2, 2)
	material = ShaderMaterial.new()
	material.shader = SHADER
	_parameter("bb_lut", Blackbody.build_lut())
	_parameter("lut_log_tmin", log(Blackbody.LUT_T_MIN))
	_parameter("lut_log_tmax", log(Blackbody.LUT_T_MAX))
	_parameter("cull_peak", CULL_PEAK)
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
	_buf = _fill_into(multimesh, _buf, pos, custom, count)
	_fill_points()
	_upload_ship()


## One instance per star into mm: hi/lo pairs relative to the origin, then custom.
## Returns the buffer (packed arrays are values in GDScript: the caller keeps it).
func _fill_into(mm: MultiMesh, buf: PackedFloat32Array, p: PackedFloat64Array, cu: PackedFloat32Array, n: int) -> PackedFloat32Array:
	mm.instance_count = n
	buf.resize(FLOATS * n)
	var ox := origin[0]
	var oy := origin[1]
	var oz := origin[2]
	for k in n:
		var b := FLOATS * k
		var rx := p[3 * k] - ox
		var ry := p[3 * k + 1] - oy
		var rz := p[3 * k + 2] - oz
		# origin (row ends 3, 7, 11) = hi; writing to a float32 array rounds, reading back gives f32(r)
		buf[b + 3] = rx
		buf[b + 7] = ry
		buf[b + 11] = rz
		# basis column x (0, 4, 8) = lo, the rounding error of hi
		buf[b] = rx - buf[b + 3]
		buf[b + 4] = ry - buf[b + 7]
		buf[b + 8] = rz - buf[b + 11]
		var c := 4 * k
		buf[b + 12] = cu[c]
		buf[b + 13] = cu[c + 1]
		buf[b + 14] = cu[c + 2]
		buf[b + 15] = cu[c + 3]
	if n > 0:
		mm.buffer = buf
	return buf


# ------------------------------------------------------------ M5.2a point sources
## Bodies below Planets.DISC_PX (planets/system_view.gd) are drawn as stars:
## a second MultiMesh sharing this one's quad, so its material (velocity,
## exposure, PSF, floor, ship pair) is the same uniform set, and the band-ratio
## Doppler applies unchanged. A point is placed POINT_LY out along its float64
## direction from the ship with its flux scaled so the shader's |p|^2 / r^2
## rescale gives back its illuminance at the ship.
const POINT_LY := 1000.0
var points: MultiMeshInstance3D
var point_count := 0
var _point_pos := PackedFloat64Array()
var _point_custom := PackedFloat32Array()
var _point_buf := PackedFloat32Array()
var point_overlay := false # only planet point flux; catalogue stars stay below opaque bodies
var point_material:ShaderMaterial

func _parameter(name:StringName,value:Variant)->void:
	material.set_shader_parameter(name,value)
	if point_material!=null:point_material.set_shader_parameter(name,value)

func replace_point_sources(list:Array)->void:
	point_count=0;_point_pos.clear();_point_custom.clear()
	add_point_sources(list) # one upload, including replacement with an empty list


func set_catalogue_replacement_sources(sources: Dictionary) -> void:
	if sources == catalogue_replacement_sources: return
	catalogue_replacement_sources = sources.duplicate(true)
	replacement_revision += 1


func clear_point_sources() -> void:
	point_count = 0
	_point_pos.clear()
	_point_custom.clear()
	_fill_points()


## list: [{dir: [x, y, z] float64 unit world direction from the ship, lux: E_v at the ship, t: kelvin}].
func add_point_sources(list: Array) -> void:
	_point_pos.resize(3 * (point_count + list.size()))
	_point_custom.resize(4 * (point_count + list.size()))
	for s: Dictionary in list:
		var d = s["dir"]
		var k := point_count
		var x: float = ship[0] + d[0] * POINT_LY
		var y: float = ship[1] + d[1] * POINT_LY
		var z: float = ship[2] + d[2] * POINT_LY
		var p2 := x * x + y * y + z * z
		_point_pos[3 * k] = x
		_point_pos[3 * k + 1] = y
		_point_pos[3 * k + 2] = z
		_point_custom[4 * k] = s["t"]
		_point_custom[4 * k + 1] = s["lux"] * POINT_LY * POINT_LY / p2
		_point_custom[4 * k + 2] = 0.0
		_point_custom[4 * k + 3] = p2
		point_count += 1
	_fill_points()


func _fill_points() -> void:
	if multimesh == null:
		return
	if points == null:
		points = MultiMeshInstance3D.new()
		points.multimesh = MultiMesh.new()
		points.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		points.multimesh.use_custom_data = true
		points.multimesh.mesh = multimesh.mesh
		points.custom_aabb = custom_aabb
		add_child(points)
	if point_overlay and point_material==null:
		point_material=material.duplicate()
		point_material.render_priority=127
		points.material_override=point_material
	_point_buf = _fill_into(points.multimesh, _point_buf, _point_pos, _point_custom, point_count)


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
	_parameter("ship_hi", s[0])
	_parameter("ship_lo", s[1])


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
	_parameter("beta_dir", direction.normalized())
	_parameter("beta_mag", beta)
	_parameter("gamma_f", gamma)
	_parameter("one_minus_beta", 1.0 / (gamma * gamma * (1.0 + beta)))


## Linear radiance of the splat peak per unit of the flux in custom data
## (lux; Exposure.star_scale), at the centre pixel.
func set_exposure(e: float) -> void:
	_parameter("exposure", e)


## The point-spread sigma in pixels (Exposure.psf_sigma_px: fixed in angle, M1.8).
func set_psf(sigma_px: float) -> void:
	_parameter("psf_sigma_px", sigma_px)


## Magnitude-floor aid: Vector2(floor lux, floor peak); zeros switch it off.
func set_floor(p: Vector2) -> void:
	_parameter("floor_flux", p.x)
	_parameter("floor_peak", p.y)
