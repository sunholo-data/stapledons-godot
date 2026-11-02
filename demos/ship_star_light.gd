extends RefCounted
## R1-SHIP-STAR-LIGHT: the light of the real star on the ship's geometry.
## Design: design_docs/implemented/r1/ship-star-light.md.
##
## One DirectionalLight3D ("StarLight") beside the ship-fixed rig of ship_lighting.gd.
##   direction  physical: the dominant finite star's apparent (aberrated) direction,
##              exactly the centre the sky renderer draws (SystemView._draw_disc, the
##              package's apparentDisc via Planets.apparent_disc64), turned from the sky
##              frame into the interior through the same ship attitude as the sky camera.
##   colour     physical hue: the renderer's blackbody lookup at T x D (Blackbody.lut_rgb),
##              D the package Doppler factor at the apparent angle (Planets.doppler_seen64,
##              sim gamma and 1 - beta). Normalised to a unit max channel.
##   brightness two settings (R3-TRUE-PROCESSED, design_docs/planned/r3/true-processed-fixes.md;
##              stapledons-design standing order 2026-10-30, after D-38/D-55). E is the seen
##              illuminance (sim e_v_lux x pointFluxRatio(T, D), the SkyMeter.seen_point
##              expression, x any eclipse transmission).
##     True       (the Realistic view). Physical: the light's photometric output is E / LUX_PER_ENERGY
##                at any colour (energy x Y(colour) = E / 10, eval B1), linear; the ship's lamps keep
##                their own illuminance (the spire 80 lx, Mark 2026-11-02), so star : lamps = E / E_ship.
##                Presentation, not a physical claim (eval B4): the exposure, an eye model on the deck
##                (meter f(y), adaptation E_ship / (E_ship + E f(y)), Exposure's EYE rule), applied as
##                one gain on all scene radiance this rig drives (star, lamps, the spire lamp's glow,
##                fill, practical, ambient). Display-referred in every setting, so Processed in True
##                (eval B2): the captain's painted figure (unlit art), the console screens and the
##                markers keep their display level. The star's bounce is a labelled ambient (no GI).
##     Processed  (the Auto view) the ship's light controller: its lamps follow the star's
##                direction and colour at a level compressed to fit, log10 between LUX_FLOOR
##                (no light) and LUX_FULL (ENERGY_MAX), and keep the ship's own lamps at a
##                readable floor. Real sunlight is ~10^5 brighter than a ship lamp; decades
##                become equal steps. Today's numbers exactly (R1-SHIP-STAR-LIGHT).
## Processed: the ship-fixed "InternalBroadKey" dims as the star light's share rises, down to a 25%
## readability floor (KEY_FLOOR_SHARE), and hands its shadows to the star; the moody
## ambient, fill and practicals stay the base and interstellar space is unchanged. The spire light
## (SpireLight, R2-DECK-LAYOUT §D5a, D-96) shares the key's dimming: the bridge's own light when no
## star is close.
## Every change is eased (TAU_S) and the dominant star switches with hysteresis.

const LUX_FLOOR := 1.0 # lx, deep twilight: no star light at or below
const LUX_FULL := 1.0e5 # lx, direct sunlight (the Sun at 1 AU is 1.27e5 lx): full light
const ENERGY_MAX := 2.5 # Godot light energy at full (the moody key is 1.5)
## Readability floor: the ship-fixed broad key never drops below this share of its moody
## energy, so the deck stays readable when the star is up but below the deck (Earth, Jupiter
## stops). It is ship light, not physical, and the residual casts no shadows.
const KEY_FLOOR_SHARE := 0.25
## Shadow ownership: exactly one directional light holds a shadow map at any time. As the
## star's level rises the key's shadow fades out (0 to HANDOVER), then the star's fades in
## (HANDOVER to 2 x HANDOVER); the swap happens where both opacities are zero (no pop).
const SHADOW_HANDOVER := 0.2
const SWITCH_RATIO := 1.5 # a new star must be this much brighter to take over
const TAU_S := 0.5 # s, easing time constant of energy, colour and direction
const VISIBLE_EPS := 1e-3 # energy below which a light is switched off (invisible change)
## True (R3-TRUE-PROCESSED D2.2): the ship's lamps in physical units. One unit of Godot light energy
## at normal incidence is LUX_PER_ENERGY lx, so the spire at its base (8, D-100) lights the bridge
## deck at 80 lx, a dim evening room, and the lower decks' broad key (1.5) at 15 lx.
const LUX_PER_ENERGY := 10.0
## True (D2.3): the star's light off the deck fills the shadows, as an ambient term (no global
## illumination here): BOUNCE x E f(y), a deck of albedo ~0.3 seen over half the sky. Labelled.
const BOUNCE := 0.1
## True (D2.3): the eye's meter cuts the star off as it sinks this far (in ŝ.up) below the deck plane.
const BELOW_DECK_CUT := 0.2
const MODES := ["true", "processed"]

var light: DirectionalLight3D
var source_id := "" # the dominant star's sim id ("" = none)
var target := {} # the last solve: id, name, dir (PackedFloat64Array), lux, seen_lux, teff, doppler, transmission, colour
var dir_world := Vector3.ZERO # eased sky-frame (SkyFrame world) direction to the star
var interior_dir := Vector3.UP # the same direction in ship-interior (glTF metres) axes
var energy := 0.0 # eased light energy
var colour := Vector3.ONE # eased linear colour
var _primed := false
## R3-TRUE-PROCESSED: "processed" (today's compressed balance, the default of a bare StarLight) or
## "true" (physical). The ship demo sets it from the view: Realistic -> true, Auto -> processed.
var mode := "processed"
var exposure := 1.0 # True: the eye's adaptation to the deck, a gain on the interior's lights (1 in Processed)
var ship_lux_last := 80.0 # True: E_ship of the last apply (lx), for the HUD


## Compressed brightness share in [0, 1]: log10 between LUX_FLOOR and LUX_FULL.
static func level_of(lux: float) -> float:
	if not (lux > LUX_FLOOR): return 0.0 # also NaN
	return clampf(log(lux / LUX_FLOOR) / log(LUX_FULL / LUX_FLOOR), 0.0, 1.0)


static func energy_of(lux: float) -> float:
	return ENERGY_MAX * level_of(lux)


## True: the light energy of a seen illuminance, linear (0 for none, negative or NaN).
static func true_energy(lux: float) -> float:
	return lux / LUX_PER_ENERGY if lux > 0.0 else 0.0


## True: the eye meter's weight of a star at y = ŝ.up (interior axes): the mean illuminance on the
## surfaces facing the upper hemisphere, the deck and the walls (1 overhead, 1/2 level with the deck),
## cut off as the star sinks BELOW_DECK_CUT below the deck plane and the deck blocks it.
static func meter_weight(y: float) -> float:
	y = clampf(y, -1.0, 1.0)
	var w := 0.5 * (1.0 + y)
	return w if y >= 0.0 else w * maxf(0.0, 1.0 + y / BELOW_DECK_CUT)


## True: the deck's own lamp illuminance (lx): the spire's base on the bridge, the broad key's below
## (or the ambient floor where a profile has no lamp, so the meter never divides by zero).
static func ship_lux(rig: Dictionary) -> float:
	var bridge: bool = rig.get("bridge", false) and rig.has("spire")
	var lamp := float(rig.get("spire_base", 0.0)) if bridge else float(rig.get("key_base", 0.0))
	return LUX_PER_ENERGY * maxf(lamp, float(rig.get("ambient_energy", rig.get("ambient_base", 0.22))))


## True: the eye adapted to the deck, Exposure's EYE rule (adapt only toward less sensitivity than
## the lamp-lit deck): E_ship / (E_ship + E f(y)), 1 with no star.
static func deck_exposure(e_ship: float, lux: float, y: float) -> float:
	return e_ship / (e_ship + maxf(lux, 0.0) * meter_weight(y))


## True: the star's share of the direct light at normal incidence (it decides the shadow owner).
static func share_of(e_ship: float, lux: float) -> float:
	return maxf(lux, 0.0) / (maxf(lux, 0.0) + e_ship)


func set_mode(m: String) -> void:
	assert(m in MODES)
	if m == mode: return
	mode = m
	# The eased energy is in the other setting's units: snap to the new setting's goal.
	energy = goal_energy(target.get("seen_lux", 0.0)) if not target.is_empty() else 0.0


func goal_energy(lux: float) -> float:
	return true_energy(lux) if mode == "true" else energy_of(lux)


## Linear sRGB, unit max channel: the shaders' blackbody lookup at the seen temperature.
## The illuminance a star delivers at the ship (lx): the sim's rest-frame e_v_lux times the spec's
## point-source ratio (Y(D T) / Y(T)) / D^2 (relativity-spec §2, the package's pointFluxRatio, via the
## shaders' blackbody LUT as SkyMeter.seen_point). The renderer's eclipse transmission multiplies it.
static func seen_lux(e_v: float, teff: float, doppler: float) -> float:
	return e_v * pow(10.0, Blackbody.lut_log10_y(teff * doppler) - Blackbody.lut_log10_y(teff)) / (doppler * doppler)


## CIE Y of a linear-sRGB colour (Rec. 709 weights): the light's photometric share per unit energy.
static func luminance(c: Vector3) -> float:
	return 0.2126729 * c.x + 0.7151522 * c.y + 0.0721750 * c.z


## True (R3-TRUE-PROCESSED, eval B1): the light for an illuminance and colour, so that the light's
## photometric output is exactly E / LUX_PER_ENERGY whatever the colour: the colour keeps a unit max
## channel (Processed's), and the energy carries 1 / Y(colour).
static func true_light_energy(lux: float, colour: Vector3) -> float:
	var y := luminance(colour)
	return true_energy(lux) / y if y > 0.0 else 0.0


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
## of ship_demo_camera.gd's ship_vector, then to_galactic, to_world (D-92: gltf_from_ship).
static func interior_of(basis: PackedFloat64Array, world_dir: Vector3) -> Vector3:
	var g := SkyFrame.to_galactic64([world_dir.x, world_dir.y, world_dir.z])
	var s := ShipFrame.to_ship(basis, g)
	return ShipCamera.gltf_from_ship(s).normalized()


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
		var seen := seen_lux(b.e_v_lux, teff, doppler)
		# Eclipses and rings: the renderer's own occlusion along the apparent ray, the star
		# itself skipped and only bodies nearer than it counted.
		var transmission: float = sv.transmission_toward(dir, b.id, dist) if not sv.rendered_bodies.is_empty() else 1.0
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
	var goal := goal_energy(pick.seen_lux) if not pick.is_empty() else 0.0
	if not pick.is_empty(): source_id = pick.id
	elif snap or energy < VISIBLE_EPS: source_id = ""
	var k := 1.0 if snap or not _primed else 1.0 - exp(-maxf(delta, 0.0) / TAU_S)
	energy = lerpf(energy, goal, k)
	if snap and goal == 0.0: energy = 0.0
	if not pick.is_empty():
		var goal_dir := Vector3(pick.dir[0], pick.dir[1], pick.dir[2]).normalized()
		if dir_world.length_squared() < 0.5 or k >= 1.0 or energy < VISIBLE_EPS: dir_world = goal_dir
		else: dir_world = dir_world.slerp(goal_dir, k).normalized()
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
	var bal := _balance(rig, on)
	var level: float = bal.level
	var lamps: float = bal.lamps
	var gain: float = bal.gain
	light.light_energy = energy * gain * float(bal.per_y) if on else 0.0
	light.visible = on
	var env: Environment = rig.get("environment")
	if env != null:
		env.ambient_light_energy = float(bal.amb_e) * gain
		env.ambient_light_color = bal.amb_c
	var fill: DirectionalLight3D = rig.get("fill")
	if fill != null: fill.light_energy = float(rig.get("fill_base", fill.light_energy)) * gain
	var practical: Light3D = rig.get("practical")
	if practical != null: practical.light_energy = float(rig.get("practical_base", practical.light_energy)) * gain
	var star_owns := on and level >= SHADOW_HANDOVER
	light.shadow_enabled = shadows and star_owns
	light.shadow_opacity = clampf((level - SHADOW_HANDOVER) / SHADOW_HANDOVER, 0.0, 1.0)
	light.light_color = Color(colour.x, colour.y, colour.z).linear_to_srgb()
	var up := Vector3.UP if absf(interior_dir.y) < 0.99 else Vector3.RIGHT
	var b := Basis.looking_at(-interior_dir, up) # the light shines along -Z: from the star
	if light.is_inside_tree(): light.global_basis = b
	else: light.basis = b
	_apply_lamps(rig, lamps, level, star_owns, shadows)


## The balance of the star and the ship's own light. level: the star's share (it hands the shadow
## over); lamps: the ship lamps' scale; gain: the exposure on all scene radiance the rig drives; per_y:
## the star light's 1 / Y(colour). Processed: the compressed share, the controller's dimming to its floor,
## gain 1. True (R3-TRUE-PROCESSED D2.3): the physical share of the direct light, the lamps at their own
## level, the eye model's exposure as the gain (star, lamps, the spire lamp's glow, fill, practical,
## ambient), the star's bounce in the ambient; the painted captain, screens and markers stay
## display-referred (labelled Processed).
func _balance(rig: Dictionary, on: bool) -> Dictionary:
	var env: Environment = rig.get("environment")
	var out := {"level": energy / ENERGY_MAX, "lamps": maxf(KEY_FLOOR_SHARE, 1.0 - energy / ENERGY_MAX), "gain": 1.0, "per_y": 1.0,
		"amb_e": float(rig.get("ambient_energy", env.ambient_light_energy if env != null else 0.0)),
		"amb_c": rig.get("ambient_colour", env.ambient_light_color if env != null else Color.WHITE)}
	exposure = 1.0
	if mode != "true": return out
	var e_ship := ship_lux(rig)
	ship_lux_last = e_ship
	var lux := energy * LUX_PER_ENERGY if on else 0.0
	exposure = deck_exposure(e_ship, lux, interior_dir.y)
	var y := luminance(colour)
	out.level = share_of(e_ship, lux)
	out.lamps = exposure
	out.gain = exposure
	out.per_y = 1.0 / y if y > 0.0 else 1.0 # B1: lux -> photometric light exactly
	var bounce := BOUNCE * lux * meter_weight(interior_dir.y) / LUX_PER_ENERGY
	if bounce > 0.0:
		# The bounce in the star's colour at unit luminance (B1), mixed with the ship's own ambient.
		var c: Color = out.amb_c
		var mix := Vector3(c.r, c.g, c.b) * float(out.amb_e) + (colour / y if y > 0.0 else Vector3.ONE) * bounce
		var peak := maxf(mix.x, maxf(mix.y, mix.z))
		out.amb_c = Color(mix.x / peak, mix.y / peak, mix.z / peak)
		out.amb_e = peak
	return out


## The ship's lamps at their scale, and the shadow handover between the star, the key and the spire.
func _apply_lamps(rig: Dictionary, lamps: float, level: float, star_owns: bool, shadows: bool) -> void:
	var key: DirectionalLight3D = rig.key
	var base: float = rig.get("key_base", key.light_energy)
	# R2-BRIDGE-STYLE S1 (D-100): on the bridge the broad key is retired and the spire is the key.
	var bridge: bool = rig.get("bridge", false) and rig.has("spire")
	var owner_opacity := clampf(1.0 - level / SHADOW_HANDOVER, 0.0, 1.0)
	key.light_energy = 0.0 if bridge else base * lamps
	key.visible = key.light_energy >= VISIBLE_EPS
	key.shadow_enabled = shadows and not star_owns and not bridge
	key.shadow_opacity = owner_opacity
	for id: int in rig.get("level_lights",{}):
		for lamp: OmniLight3D in rig.level_lights[id]:
			lamp.light_energy=float(lamp.get_meta("base_energy",0.0))*lamps
			lamp.visible=id==int(rig.get("active_level",0)) and rig.profile!="baseline"
	# R2-DECK-LAYOUT §D5a (D-96): the spire, the bridge's own light, shares the key's dimming.
	if not rig.has("spire"): return
	var spire: OmniLight3D = rig.spire
	spire.light_energy = float(rig.get("spire_base", 0.0)) * lamps
	spire.visible = spire.light_energy >= VISIBLE_EPS
	# The spire holds the shadow on the bridge until the star takes it (the key's ramp): exactly
	# one of spire and star has a shadow map; the mast, which holds the light, never casts its shadow.
	spire.shadow_enabled = bridge and shadows and not star_owns and spire.visible
	spire.shadow_opacity = owner_opacity
	var mast_cast := GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if bridge and not star_owns else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	for m: GeometryInstance3D in rig.get("mast", []):
		if is_instance_valid(m): m.cast_shadow = mast_cast
	var lamp: MeshInstance3D = rig.get("spire_lamp")
	if lamp != null:
		# True: the lamp's glow is scene radiance, under the same exposure gain as everything lit (eval B2).
		(lamp.material_override as StandardMaterial3D).emission_energy_multiplier = float(rig.get("spire_lamp_base", 0.0)) * lamps


func manifest() -> Dictionary:
	var d := interior_dir
	return {"source": source_id, "name": target.get("name", ""), "rest_frame_lux": target.get("lux", 0.0), "seen_lux": target.get("seen_lux", 0.0), "doppler": target.get("doppler", 1.0), "transmission": target.get("transmission", 1.0), "teff_k": target.get("teff", 0.0),
		"energy": light.light_energy if light != null else 0.0, "shadows": light.shadow_enabled if light != null else false, "interior_direction": [d.x, d.y, d.z], "colour_linear": [colour.x, colour.y, colour.z],
		"direction": "physical: the star's aberrated apparent direction, the sky renderer's disc centre, in ship axes",
		"colour": "physical hue: blackbody at Teff x Doppler factor (the renderer's lookup), unit max channel",
		"mode": mode, "exposure": exposure,
		"exposure_model": "presentation, not a physical claim: an eye model on the deck, gain = E_ship / (E_ship + E f(y)), f(y) = (1 + y) / 2 above the deck plane, cut off %s below it; one gain on all scene radiance the rig drives (star, lamps, the spire lamp's glow, fill, practical, ambient); the star's bounce an ambient term, %s x E f(y) (no GI)" % [BELOW_DECK_CUT, BOUNCE] if mode == "true" else "none (exposure 1)",
		"display_referred": "Processed in every setting: the captain's painted figure (unlit art), the console screens and the markers keep their display level; they are not re-exposed",
		"brightness": ("True: physical illuminance: energy x Y(colour) = E / %s lx (linear, any colour), E = seen illuminance at the ship (sim e_v_lux x Doppler flux ratio x eclipse transmission); the ship's lamps at their own level (%s lx per unit of energy), so star : lamps = E / E_ship" % [LUX_PER_ENERGY, LUX_PER_ENERGY]) if mode == "true"
			else ("Processed, the ship's light controller: log-compressed, not physical: energy = %.1f x log10(E / %s lx) / log10(%s / %s), E = seen illuminance at the ship (sim e_v_lux x Doppler flux ratio x eclipse transmission)" % [ENERGY_MAX, LUX_FLOOR, LUX_FULL, LUX_FLOOR]),
		"broad_key": ("the ship's lamps keep their own illuminance in True (no dimming, no floor); the broad key retired on the bridge, where the spire keys the deck" if mode == "true"
			else "ship-fixed key dimmed by the star light's share down to a %d%% readability floor (Processed: the ship's light controller; no shadows while the star owns them); ambient, fill and practicals unchanged; retired on the bridge, where the spire takes this rule and the shadow (R2-BRIDGE-STYLE S1)" % roundi(100.0 * KEY_FLOOR_SHARE)),
		"easing_s": TAU_S, "switch_ratio": SWITCH_RATIO}


func hud_line() -> String:
	if source_id == "" or energy < VISIBLE_EPS:
		return "Starlight on ship: none above %s lx · ship lights only" % _sci(LUX_FLOOR if mode == "processed" else VISIBLE_EPS * LUX_PER_ENERGY)
	var lux: float = target.get("seen_lux", 0.0)
	if mode == "true":
		return "Starlight on ship: %s · %s lx at the ship · True: brightness, direction and colour physical; exposure an eye model on the deck; the captain, screens and markers display-referred (Processed)" % [target.get("name", source_id), _sci(lux)]
	return "Starlight on ship: %s · %s lx at the ship → %d%% light (Processed: the ship's lamps follow the star, brightness log-compressed %s–%s lx; direction and colour physical)" % [target.get("name", source_id), _sci(lux), roundi(100.0 * energy / ENERGY_MAX), _sci(LUX_FLOOR), _sci(LUX_FULL)]


static func _sci(x: float) -> String:
	if x <= 0.0: return "0"
	var e := floori(log(x) / log(10.0))
	if e >= -2 and e <= 4: return ("%.0f" if x >= 1.0 else "%.2f") % x
	return "%.1f×10^%d" % [x / pow(10.0, e), e]
