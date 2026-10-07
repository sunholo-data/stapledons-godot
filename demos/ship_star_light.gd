extends RefCounted
## R1-SHIP-STAR-LIGHT: the light of the real star on the ship's geometry.
## Design: design_docs/planned/r1/ship-star-light.md.
##
## One DirectionalLight3D ("StarLight") beside the ship-fixed rig of ship_lighting.gd.
##   direction  physical: the dominant finite star's apparent (aberrated) direction,
##              exactly the centre the sky renderer draws (SystemView._draw_disc, the
##              package's apparentDisc via Planets.apparent_disc64), turned from the sky
##              frame into the interior through the same ship attitude as the sky camera.
##   colour     physical hue: the renderer's blackbody lookup at T x D (Blackbody.lut_rgb),
##              D the package Doppler factor at the apparent angle (Planets.doppler_seen64,
##              sim gamma and 1 - beta). Normalised to a unit max channel.
##   brightness NOT physical: the seen illuminance (sim e_v_lux x pointFluxRatio(T, D),
##              the SkyMeter.seen_point expression, x any eclipse transmission) mapped
##              logarithmically from LUX_FLOOR (no light) to LUX_FULL (ENERGY_MAX). Real
##              sunlight is ~10^5 brighter than a ship interior lamp; a display cannot
##              show that range, so decades become equal steps.
## The ship-fixed "InternalBroadKey" fades out as the star light's share rises, so the
## moody ambient, fill and practicals stay the base and interstellar space is unchanged.
## Every change is eased (TAU_S) and the dominant star switches with hysteresis.

const LUX_FLOOR := 1.0 # lx, deep twilight: no star light at or below
const LUX_FULL := 1.0e5 # lx, direct sunlight (the Sun at 1 AU is 1.27e5 lx): full light
const ENERGY_MAX := 2.5 # Godot light energy at full (the moody key is 1.5)
const KEY_DIM := 1.0 # share of the broad key removed at full star light
const SWITCH_RATIO := 1.5 # a new star must be this much brighter to take over
const TAU_S := 0.5 # s, easing time constant of energy, colour and direction
const VISIBLE_EPS := 1e-3 # energy below which a light is switched off (invisible change)
const KEY_SHADOW_SHARE := 0.02 # the key drops its shadow map below 2% of its base energy

var light: DirectionalLight3D
var source_id := "" # the dominant star's sim id ("" = none)
var target := {} # the last solve: id, name, dir (PackedFloat64Array), lux, seen_lux, teff, doppler, transmission, colour
var dir_world := Vector3.ZERO # eased sky-frame (SkyFrame world) direction to the star
var interior_dir := Vector3.UP # the same direction in ship-interior (glTF metres) axes
var energy := 0.0 # eased light energy
var colour := Vector3.ONE # eased linear colour
var _primed := false


## Compressed brightness share in [0, 1]: log10 between LUX_FLOOR and LUX_FULL.
static func level_of(lux: float) -> float:
	if not (lux > LUX_FLOOR): return 0.0 # also NaN
	return clampf(log(lux / LUX_FLOOR) / log(LUX_FULL / LUX_FLOOR), 0.0, 1.0)


static func energy_of(lux: float) -> float:
	return ENERGY_MAX * level_of(lux)


## Linear sRGB, unit max channel: the shaders' blackbody lookup at the seen temperature.
static func colour_of(teff: float, doppler: float) -> Vector3:
	var c := Blackbody.lut_rgb(teff * doppler)
	var m := maxf(c.x, maxf(c.y, c.z))
	return c / m if m > 0.0 else Vector3.ONE


## The apparent sky-frame direction of a body's centre, as SystemView._draw_disc draws it.
static func apparent_direction(sv: SystemView, rel_km: Dictionary, radius_km: float) -> PackedFloat64Array:
	var w := Planets.world_of(rel_km)
	var dist := Planets.length64(w)
	var rest := PackedFloat64Array([w[0] / dist, w[1] / dist, w[2] / dist])
	if not sv.relativistic_enabled or sv.velocity_beta <= 0.0: return rest
	var h := sv.velocity_heading
	var c := rest[0] * h.x + rest[1] * h.y + rest[2] * h.z
	var cap := Planets.apparent_disc64(c, Planets.angular_radius(radius_km, dist), sv.velocity_beta, sv.velocity_gamma)
	var t := PackedFloat64Array([rest[0] - c * h.x, rest[1] - c * h.y, rest[2] - c * h.z])
	var tl := Planets.length64(t)
	if tl > 1e-10: t = PackedFloat64Array([t[0] / tl, t[1] / tl, t[2] / tl])
	else:
		var f := Vector3.UP.cross(h).normalized() if absf(h.y) < 0.9 else Vector3.RIGHT.cross(h).normalized()
		t = PackedFloat64Array([f.x, f.y, f.z])
	var ca := cos(cap[0]); var sa := sin(cap[0])
	return PackedFloat64Array([h.x * ca + t[0] * sa, h.y * ca + t[1] * sa, h.z * ca + t[2] * sa])


## Sky frame -> ship frame (attitude basis, galactic columns) -> interior axes. The inverse
## of ship_demo_camera.gd: ship_vector(v) = [v.x, -v.z, v.y], then to_galactic, to_world.
static func interior_of(basis: PackedFloat64Array, world_dir: Vector3) -> Vector3:
	var g := SkyFrame.to_galactic64([world_dir.x, world_dir.y, world_dir.z])
	var s := ShipFrame.to_ship(basis, g)
	return Vector3(s[0], s[2], -s[1]).normalized()


## Every finite star the sky renderer has, with its seen illuminance at the ship.
static func emitters(sky: InteriorSky) -> Array:
	var sv := sky.system_view
	var out := []
	var hv := sv.velocity_heading
	var h := PackedFloat64Array([hv.x, hv.y, hv.z])
	for b: Dictionary in sky.system_state.get("bodies", []):
		if b.get("kind", "") != "star" or not (float(b.get("e_v_lux", 0.0)) > 0.0): continue
		var dist := Planets.length64(Planets.world_of(b.rel_km))
		if dist <= float(b.radius_km) * 1.001: continue # inside the star: the renderer draws nothing
		var dir := apparent_direction(sv, b.rel_km, b.radius_km)
		var teff: float = b.get("teff_k", Planets.T_SUN)
		var doppler := 1.0
		if sv.relativistic_enabled and sv.velocity_beta > 0.0:
			doppler = Planets.doppler_seen64(dir, h, sv.velocity_beta, sv.velocity_gamma, sv.velocity_omb)
		# pointFluxRatio(T, D), as SkyMeter.seen_point, with the sim's exact 1 - beta.
		var seen: float = b.e_v_lux * pow(10.0, Blackbody.lut_log10_y(teff * doppler) - Blackbody.lut_log10_y(teff)) / (doppler * doppler)
		# Eclipses and rings: the renderer's own occlusion along the apparent ray, the star
		# itself skipped and only bodies nearer than it counted.
		var transmission: float = sv._directional_transmission(dir, false, b.id, dist) if not sv.rendered_bodies.is_empty() else 1.0
		out.append({"id": b.id, "name": b.get("name", b.id), "dir": dir, "lux": b.e_v_lux, "seen_lux": seen * transmission, "teff": teff, "doppler": doppler, "transmission": transmission, "colour": colour_of(teff, doppler)})
	return out


func install(rig: Dictionary) -> void:
	var key: DirectionalLight3D = rig.key
	light = DirectionalLight3D.new()
	light.name = "StarLight"
	light.directional_shadow_max_distance = key.directional_shadow_max_distance
	light.shadow_bias = key.shadow_bias
	light.shadow_normal_bias = key.shadow_normal_bias
	light.light_energy = 0.0
	light.visible = false
	key.get_parent().add_child(light)
	rig["star"] = self


## Pick the dominant star (with hysteresis) and ease toward it. snap: no easing.
func update(rig: Dictionary, sky: InteriorSky, delta: float, snap := false) -> void:
	var stars := emitters(sky) if not sky.basis.is_empty() else []
	var best := {}
	var current := {}
	for s: Dictionary in stars:
		if best.is_empty() or s.seen_lux > best.seen_lux: best = s
		if s.id == source_id: current = s
	var pick := best
	if not current.is_empty() and not best.is_empty() and best.seen_lux < current.seen_lux * SWITCH_RATIO: pick = current
	target = pick
	var goal_energy := energy_of(pick.seen_lux) if not pick.is_empty() else 0.0
	if not pick.is_empty(): source_id = pick.id
	elif snap or energy < VISIBLE_EPS: source_id = ""
	var k := 1.0 if snap or not _primed else 1.0 - exp(-maxf(delta, 0.0) / TAU_S)
	energy = lerpf(energy, goal_energy, k)
	if snap and goal_energy == 0.0: energy = 0.0
	if not pick.is_empty():
		var goal := Vector3(pick.dir[0], pick.dir[1], pick.dir[2]).normalized()
		if dir_world.length_squared() < 0.5 or k >= 1.0 or energy < VISIBLE_EPS: dir_world = goal
		else: dir_world = dir_world.slerp(goal, k).normalized()
		colour = colour.lerp(pick.colour, k) if _primed and not snap else pick.colour
	_primed = true
	if not sky.basis.is_empty() and dir_world.length_squared() > 0.5:
		interior_dir = interior_of(sky.basis, dir_world)
	apply_rig(rig)


## Write the eased state into the lights (also re-run by ship_lighting.apply).
func apply_rig(rig: Dictionary) -> void:
	if light == null: return
	var shadows: bool = rig.get("shadows", true)
	var on := energy >= VISIBLE_EPS
	light.light_energy = energy if on else 0.0
	light.visible = on
	light.shadow_enabled = shadows and on
	light.light_color = Color(colour.x, colour.y, colour.z).linear_to_srgb()
	var up := Vector3.UP if absf(interior_dir.y) < 0.99 else Vector3.RIGHT
	var b := Basis.looking_at(-interior_dir, up) # the light shines along -Z: from the star
	if light.is_inside_tree(): light.global_basis = b
	else: light.basis = b
	var key: DirectionalLight3D = rig.key
	var base: float = rig.get("key_base", key.light_energy)
	key.light_energy = base * (1.0 - KEY_DIM * energy / ENERGY_MAX)
	key.visible = key.light_energy >= VISIBLE_EPS
	key.shadow_enabled = shadows and key.light_energy >= KEY_SHADOW_SHARE * base


func manifest() -> Dictionary:
	var d := interior_dir
	return {"source": source_id, "name": target.get("name", ""), "rest_frame_lux": target.get("lux", 0.0), "seen_lux": target.get("seen_lux", 0.0), "doppler": target.get("doppler", 1.0), "transmission": target.get("transmission", 1.0), "teff_k": target.get("teff", 0.0),
		"energy": light.light_energy if light != null else 0.0, "shadows": light.shadow_enabled if light != null else false, "interior_direction": [d.x, d.y, d.z], "colour_linear": [colour.x, colour.y, colour.z],
		"direction": "physical: the star's aberrated apparent direction, the sky renderer's disc centre, in ship axes",
		"colour": "physical hue: blackbody at Teff x Doppler factor (the renderer's lookup), unit max channel",
		"brightness": "log-compressed, not physical: energy = %.1f x log10(E / %s lx) / log10(%s / %s), E = seen illuminance at the ship (sim e_v_lux x Doppler flux ratio x eclipse transmission)" % [ENERGY_MAX, LUX_FLOOR, LUX_FULL, LUX_FLOOR],
		"broad_key": "ship-fixed key dimmed by the star light's share; ambient, fill and practicals unchanged",
		"easing_s": TAU_S, "switch_ratio": SWITCH_RATIO}


func hud_line() -> String:
	if source_id == "" or energy < VISIBLE_EPS:
		return "Starlight on ship: none above %s lx · ship lights only" % _sci(LUX_FLOOR)
	var lux: float = target.get("seen_lux", 0.0)
	return "Starlight on ship: %s · %s lx at the ship → %d%% light (brightness log-compressed, %s–%s lx; direction and colour physical)" % [target.get("name", source_id), _sci(lux), roundi(100.0 * energy / ENERGY_MAX), _sci(LUX_FLOOR), _sci(LUX_FULL)]


static func _sci(x: float) -> String:
	if x <= 0.0: return "0"
	var e := floori(log(x) / log(10.0))
	if e >= -2 and e <= 4: return ("%.0f" if x >= 1.0 else "%.2f") % x
	return "%.1f×10^%d" % [x / pow(10.0, e), e]
