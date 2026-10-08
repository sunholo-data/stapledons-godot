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
## Star truth (design_docs/planned/r1/starmap-single-truth.md): pin_destination calls that found the
## destination already at its navigation position (no-ops) and those that had to pin.
var pin_noops := 0
var pin_fallbacks := 0
## load_tiers' float64 restore from stars.json: rows set to the navigation position, and rows whose
## tier position was more than NAV_RESTORE_LY away (left alone; make starmap-consistency fails on them).
var nav_restored := 0
var nav_max_shift := 0.0 # ly: the largest float32-to-float64 correction applied
var nav_refused: Array[String] = []
const NAV_RESTORE_LY := 1e-4
var _index := {}
var _index_revision := -1
static var _nav_cache := {}


func clear() -> void:
	identity_revision += 1
	pinned_ids.clear()
	_requested_replacements.clear()
	pin_noops = 0
	pin_fallbacks = 0
	nav_restored = 0
	nav_max_shift = 0.0
	nav_refused.clear()
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
	# A physical emitter replaces its catalogue row under any alias: tiers store Gaia
	# sources as the bare number ("Gaia DR3 n" -> "n").
	for id in requested:
		var bare:=id.trim_prefix("Gaia DR3 ")
		if bare!=id and not bare in replacements: replacements.append(bare)
	# A pinned destination replaced by a physical emitter is suppressed with its identity.
	# index_of is a hash lookup rebuilt only when identities change: a linear `in ids`
	# here scanned all 335,189 large-tier rows per emitter every frame (13.7 ms on an
	# M4 Max at the Aldebaran stop; the dev.20 lag on the M2 Air).
	for id in requested:
		if index_of("pin:" + id) >= 0 and not ("pin:" + id) in replacements: replacements.append("pin:" + id)
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


## The tier the ship's sky draws by default: large (every GCNS star within 100 pc,
## make starmap-assets) when present. Without it the sky falls back to medium (the
## 50,000 nearest), loudly: the warning names the missing file and the tier in use.
const LARGE_BIN := "res://data/starmap/stars_large.bin"
static func default_tier() -> String:
	if FileAccess.file_exists(LARGE_BIN): return "large"
	push_warning("starfield: %s is missing (make starmap-assets); the sky uses the medium tier (50,000 nearest GCNS stars) instead of large (all 331,311 within 100 pc)" % LARGE_BIN)
	return "medium"

## The last stack a Starfield loaded (tier, stars drawn), for the coverage info.
static var last_loaded := {}


## The identities a navigation id ("Gaia DR3 n", "CNS5:n", "HIP n") has in the
## tiers: tiers store Gaia sources as the bare number.
static func aliases_of(id: String) -> Array[String]:
	var out: Array[String] = [id]
	var bare := id.trim_prefix("Gaia DR3 ")
	if bare != id: out.append(bare)
	return out


## Row of an identity in the stack (the first one), or -1. The index is rebuilt
## when the identities change.
func index_of(id: String) -> int:
	if _index_revision != identity_revision:
		_index.clear()
		for k in count:
			if not _index.has(ids[k]): _index[ids[k]] = k
		_index_revision = identity_revision
	return _index.get(id, -1)


## A destination renders where the simulation navigates. Since the star-truth
## table (design_docs/planned/r1/starmap-single-truth.md) every tier takes the
## navigation position, so this is an assertion: when a row with the destination's
## identity already sits exactly at its stars.json position, nothing changes
## (pin_noops). Otherwise (a tier built without the table, or a custom stack) it
## warns and falls back to the RT4 pin (a destination without photometry, vmag 99,
## has nothing to draw and is never pinned): tier rows with the identity are hidden and
## one row is added at the exact position with the catalogue V and Teff.
## Idempotent; clear() drops it.
func pin_destination(row: Dictionary) -> void:
	var id := str(row.get("id", ""))
	if id.is_empty() or index_of("pin:" + id) >= 0: return
	var want := SkyFrame.to_world64(PackedFloat64Array([row.x, row.y, row.z]))
	for alias: String in aliases_of(id):
		var k := index_of(alias)
		if k >= 0 and pos[3 * k] == want[0] and pos[3 * k + 1] == want[1] and pos[3 * k + 2] == want[2]:
			pin_noops += 1
			return
	if float(row.get("vmag", 99.0)) >= 99.0:
		return # no photometry: nothing to draw, nothing to pin
	pin_fallbacks += 1
	push_warning("pin_destination: %s is not at its navigation position in the sky stack; pinning it" % id)
	for alias: String in aliases_of(id):
		if index_of(alias) >= 0 and not alias in pinned_ids: pinned_ids.append(alias)
	append_stars([{"id": "pin:" + id, "pos": SkyFrame.to_world64(PackedFloat64Array([row.x, row.y, row.z])), "t": float(row.teff), "flux": Relativity.illuminance_from_v(float(row.vmag))}])
	set_catalogue_replacements(_requested_replacements)


## The active tier, then on top: for medium/large (GCNS), every quick (CNS5)
## row whose identity the tier lacks: the HIP-filled rows (flag 8: Sirius, alpha
## Cen, Procyon, ... which Gaia cannot measure, so GCNS has no photometry for them
## and the bright tier excludes them as CNS5 matches) and the CNS5 stars GCNS does
## not list; then the bright tier (M1.2d) when stars_bright.bin exists. The tiers
## share one position per star (the star-truth table), so no star is drawn twice
## and none sits elsewhere. Finally the float64 navigation positions of stars.json
## replace their float32 tier copies (restore_navigation_positions).
## A refused tier (sidecar, size or sha256) loads nothing: false.
func load_tiers(tier: String, dir := "res://data/starmap") -> bool:
	clear()
	var stack := [[tier, false]]
	if tier != "quick":
		stack.append(["quick", true])
	stack.append(["bright", false])
	for entry in stack:
		var t: String = entry[0]
		if t == "bright" and not FileAccess.file_exists("%s/stars_bright.bin" % dir):
			continue
		var c := StarCatalogue.load_tier(t, dir)
		if c == null:
			last_error = "tier %s: %s" % [t, StarCatalogue.last_error]
			clear()
			return false
		append_catalogue(c, 0, entry[1])
		tiers.append(t + (":rest" if entry[1] else ""))
	restore_navigation_positions("%s/stars.json" % dir)
	last_loaded = {"tier": tier, "count": count, "tiers": tiers.duplicate()}
	return true


## stars.json (the navigation catalogue, float64) sets the position of every
## stack row with a destination's identity, replacing the float32 tier copy of the
## same truth position, so the sky and the simulation agree to float64 round-off.
## A row more than NAV_RESTORE_LY away is a different position, not a rounding: it
## is left alone and listed in nav_refused.
func restore_navigation_positions(path: String) -> void:
	if not FileAccess.file_exists(path): return
	if not _nav_cache.has(path):
		var j: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		var rows: Array = []
		if typeof(j) == TYPE_DICTIONARY and typeof(j.get("stars")) == TYPE_ARRAY:
			for s: Dictionary in j.stars:
				rows.append([str(s.id), SkyFrame.to_world64(PackedFloat64Array([s.x, s.y, s.z]))])
		_nav_cache[path] = rows
	for r: Array in _nav_cache[path]:
		var want: PackedFloat64Array = r[1]
		for alias: String in aliases_of(r[0]):
			var k := index_of(alias)
			if k < 0: continue
			var d := sqrt((pos[3 * k] - want[0]) ** 2 + (pos[3 * k + 1] - want[1]) ** 2 + (pos[3 * k + 2] - want[2]) ** 2)
			if d > NAV_RESTORE_LY:
				nav_refused.append(r[0])
				continue
			nav_max_shift = maxf(nav_max_shift, d)
			pos[3 * k] = want[0]
			pos[3 * k + 1] = want[1]
			pos[3 * k + 2] = want[2]
			custom[4 * k + 3] = want[0] * want[0] + want[1] * want[1] + want[2] * want[2]
			nav_restored += 1
	if multimesh != null: _fill()


## only_flags != 0: append only the rows carrying those flag bits.
## absent_only: append only rows whose identity the stack does not have yet.
func append_catalogue(c: StarCatalogue, only_flags := 0, absent_only := false) -> void:
	var have := {}
	if absent_only:
		for k in count: have[ids[k]] = true
	identity_revision += 1
	var k := count
	pos.resize(3 * (count + c.count))
	custom.resize(4 * (count + c.count))
	var d := c.data
	var with_ids := c.ids.size() == c.count
	for i in c.count:
		if only_flags != 0 and c.flags(i) & only_flags == 0:
			continue
		if absent_only and with_ids and have.has(c.ids[i]):
			continue
		if c.missing_photometry(i):
			skipped_missing += 1
			continue
		var j := 6 * i
		# galactic -> world (SkyFrame, D-28), widened to float64 before any arithmetic
		var w := SkyFrame.to_world64([d[j], d[j + 1], d[j + 2]])
		_put(k, w[0], w[1], w[2], d[j + 3], Relativity.illuminance_from_v(d[j + 4]), d[j + 5])
		ids.append(c.ids[i] if with_ids else "")
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
## Further materials on this uniform set (M3.5b: GrLens's order-1 image instance).
var extra_materials: Array[ShaderMaterial] = []

func _parameter(name:StringName,value:Variant)->void:
	material.set_shader_parameter(name,value)
	if point_material!=null:point_material.set_shader_parameter(name,value)
	for m in extra_materials: m.set_shader_parameter(name,value)

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
