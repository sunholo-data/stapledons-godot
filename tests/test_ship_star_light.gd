extends SceneTree
## R1-SHIP-STAR-LIGHT: the ship's star light follows the star the player sees.
## Inputs are recorded sim state (tests/fixtures/system_sol.ndjson) with bodies moved
## in controlled ways; the renderer under test is the real InteriorSky/SystemView.
const StarLight := preload("res://demos/ship_star_light.gd")
const Lighting := preload("res://demos/ship_lighting.gd")
const Camera := preload("res://demos/ship_demo_camera.gd")
const Attitude := preload("res://demos/ship_attitude.gd")
const FIXTURE := "res://tests/fixtures/system_sol.ndjson"
const PX := Vector2i(1280, 720)
var passed := 0
var failures := 0

func check(name: String, ok: bool) -> void:
	if ok: passed += 1
	else: failures += 1
	print("  %s %s" % ["ok  " if ok else "FAIL", name])

func _initialize() -> void: _run.call_deferred()

func fixture_world() -> Dictionary:
	var lines := FileAccess.get_file_as_string(FIXTURE).strip_edges().split("\n")
	var world: Dictionary = JSON.parse_string(lines[1]).changes
	world.system = SimBridge.parse_system(world.system)
	# The recorded epoch has the ship at the Sun's centre. Move the observer to Earth
	# (every rel_km minus Earth's), Earth itself two radii into the night side, and the
	# Sun's illuminance to the sim's 1.27e5 lx x (1 AU / d)^2 (checkSysSunLux).
	var e: Dictionary = body(world, "earth").rel_km.duplicate()
	for b: Dictionary in world.system.bodies:
		b.rel_km = {"x": b.rel_km.x - e.x, "y": b.rel_km.y - e.y, "z": b.rel_km.z - e.z}
	var sun := body(world, "sun")
	var d := sqrt(sun.rel_km.x * sun.rel_km.x + sun.rel_km.y * sun.rel_km.y + sun.rel_km.z * sun.rel_km.z)
	sun.e_v_lux = 1.27e5 * pow(SystemView.AU_KM / d, 2.0)
	var earth := body(world, "earth")
	var r: float = 2.0 * earth.radius_km / d
	earth.rel_km = {"x": -sun.rel_km.x * r, "y": -sun.rel_km.y * r, "z": -sun.rel_km.z * r}
	return world

func body(world: Dictionary, id: String) -> Dictionary:
	for b: Dictionary in world.system.bodies:
		if b.id == id: return b
	return {}

func vec_of(a: PackedFloat64Array) -> Vector3: return Vector3(a[0], a[1], a[2])

## Galactic rel_km for a world (SkyFrame) direction at distance d.
func rel_at(world_dir: Vector3, d_km: float) -> Dictionary:
	var g := SkyFrame.to_galactic64([world_dir.x, world_dir.y, world_dir.z])
	return {"x": g[0] * d_km, "y": g[1] * d_km, "z": g[2] * d_km}

func angle_deg(a: Vector3, b: Vector3) -> float:
	return rad_to_deg(atan2(a.normalized().cross(b.normalized()).length(), a.normalized().dot(b.normalized())))

func _run() -> void:
	var world := fixture_world()
	var sun := body(world, "sun")
	check("fixture carries the Sun as a finite star with e_v_lux near 1.3e5 lx", sun.kind == "star" and sun.e_v_lux > 1.0e5 and sun.e_v_lux < 1.6e5)

	# --- 1. Compressed energy: zero below the floor, monotonic, bounded.
	check("no light at or below the floor, at zero or NaN", StarLight.energy_of(0.0) == 0.0 and StarLight.energy_of(StarLight.LUX_FLOOR) == 0.0 and StarLight.energy_of(1e-6) == 0.0 and StarLight.energy_of(NAN) == 0.0 and StarLight.energy_of(-5.0) == 0.0)
	var monotonic := true
	var bounded := true
	var last := -1.0
	for i in 121:
		var lux := pow(10.0, -2.0 + i * 0.1)
		var e := StarLight.energy_of(lux)
		if e < last: monotonic = false
		if e < 0.0 or e > StarLight.ENERGY_MAX: bounded = false
		last = e
	check("energy is monotonic in illuminance from 1e-2 to 1e10 lx", monotonic)
	check("energy is bounded by ENERGY_MAX", bounded and StarLight.energy_of(1e12) == StarLight.ENERGY_MAX and StarLight.energy_of(StarLight.LUX_FULL) == StarLight.ENERGY_MAX)
	check("energy is logarithmic: one decade below full loses one decade's share", is_equal_approx(StarLight.energy_of(StarLight.LUX_FULL / 10.0), StarLight.ENERGY_MAX * (1.0 - 1.0 / log(StarLight.LUX_FULL / StarLight.LUX_FLOOR) * log(10.0))))
	check("Jupiter-distance sunlight (~4.7e3 lx) is between half and full", StarLight.energy_of(4.7e3) > 0.5 * StarLight.ENERGY_MAX and StarLight.energy_of(4.7e3) < StarLight.ENERGY_MAX)

	# --- 2. Colour by temperature (the renderer's blackbody lookup).
	var trappist := StarLight.colour_of(2566.0, 1.0)
	var aldebaran := StarLight.colour_of(3927.0, 1.0)
	var sol := StarLight.colour_of(Planets.T_SUN, 1.0)
	check("colour is normalised to a unit max channel", is_equal_approx(maxf(sol.x, maxf(sol.y, sol.z)), 1.0) and is_equal_approx(maxf(trappist.x, maxf(trappist.y, trappist.z)), 1.0))
	check("blue/red rises with Teff: TRAPPIST-1 < Aldebaran < Sun", trappist.z / trappist.x < aldebaran.z / aldebaran.x and aldebaran.z / aldebaran.x < sol.z / sol.x)
	check("TRAPPIST-1 light is redder than sunlight", trappist.x >= trappist.z * 2.0 and sol.z / sol.x > 0.6)
	check("Doppler D > 1 blueshifts the light colour (T x D)", StarLight.colour_of(Planets.T_SUN, 1.5).z / StarLight.colour_of(Planets.T_SUN, 1.5).x > sol.z / sol.x)

	# --- 3. Direction = rendered disc direction (rest and moving).
	var host := Node3D.new(); root.add_child(host)
	var rig := Lighting.install(host)
	var star := StarLight.new(); star.install(rig)
	var sky := InteriorSky.new(); root.add_child(sky)
	sky.setup({"position_m": [8, 4.8, 83.7], "forward": [1, 0, 0], "up": [0, 0, 1]}, 78.0, PX, {"stars": false, "background": false, "planet_textures": false, "planet_relativistic": true, "planet_preload": false})
	var near := world.duplicate(true)
	var sun_dir_w := Vector3(0.3, 0.5, -0.81).normalized()
	body(near, "sun").rel_km = rel_at(sun_dir_w, 0.05 * SystemView.AU_KM) # a resolved disc
	sky.apply(near)
	star.update(rig, sky, 0.0, true)
	var sv: SystemView = sky.system_view
	check("the close Sun is a resolved disc", sv.drawn_discs.has("sun"))
	var rest_centre: Vector3 = sv.discs.sun.material_override.get_shader_parameter("centre_w") if sv.discs.has("sun") else Vector3.ZERO
	check("at rest the light's sky direction is the disc centre (< 0.01 deg)", star.source_id == "sun" and angle_deg(star.dir_world, rest_centre) < 0.01)
	var moving := near.duplicate(true)
	moving.ship.beta = 0.6; moving.ship.gamma = 1.25; moving.ship.one_minus_beta = 0.4
	sky.apply(moving); star.update(rig, sky, 0.0, true)
	var app_centre: Vector3 = sv.discs.sun.material_override.get_shader_parameter("apparent_centre_w")
	check("at 0.6c the light follows the aberrated disc centre (< 0.01 deg)", angle_deg(star.dir_world, app_centre) < 0.01)
	# Textbook check on the 1 AU Sun (0.27 deg: the cap centre is the aberrated centre).
	var far := world.duplicate(true)
	body(far, "sun").rel_km = rel_at(sun_dir_w, SystemView.AU_KM)
	far.ship.beta = 0.6; far.ship.gamma = 1.25; far.ship.one_minus_beta = 0.4
	sky.apply(far); star.update(rig, sky, 0.0, true)
	var h := sky.heading_world
	var cos_rest := sun_dir_w.dot(h)
	var cos_app := (cos_rest + 0.6) / (1.0 + 0.6 * cos_rest) # textbook aberration, independent of the package mirror
	var app_deg := rad_to_deg(acos(clampf(star.dir_world.normalized().dot(h), -1.0, 1.0)))
	check("aberration matches cos' = (cos + b)/(1 + b cos) (%.4f vs %.4f deg)" % [app_deg, rad_to_deg(acos(cos_app))], absf(app_deg - rad_to_deg(acos(cos_app))) < 0.02)
	check("the light moved toward the heading under aberration", star.dir_world.normalized().dot(h) > cos_rest + 0.1)
	var d_seen := 1.0 / (1.25 * (1.0 - 0.6 * cos_app))
	check("light Doppler is D = 1/(g(1 - b cos')) at the apparent angle (%.6f vs %.6f)" % [star.target.doppler, d_seen], absf(star.target.doppler - d_seen) < 1e-4)
	# Independent colour check: the shaders' lookup at a hand-computed T x D (textbook D above).
	var lut_hand := Blackbody.lut_rgb(Planets.T_SUN * d_seen)
	lut_hand /= maxf(lut_hand.x, maxf(lut_hand.y, lut_hand.z))
	check("light colour is the blackbody at 5772 K x D(textbook) = %.0f K" % (Planets.T_SUN * d_seen), star.target.colour.distance_to(lut_hand) < 1e-3)

	# Spec check values, stapledons-design physics/relativity-spec.md §2 (Aberration, Doppler)
	# and §7 RS-1: a source at 90 deg (rest frame) seen from 0.9c appears at 25.842 deg;
	# its Doppler factor is D = gamma (1 + b cos 90) = gamma = 2.29416.
	var rs := world.duplicate(true)
	var h0 := sky.heading_world.normalized()
	var side := h0.cross(Vector3.UP if absf(h0.y) < 0.9 else Vector3.RIGHT).normalized()
	body(rs, "sun").rel_km = rel_at(side, SystemView.AU_KM)
	var g09 := 1.0 / sqrt(1.0 - 0.81)
	rs.ship.beta = 0.9; rs.ship.gamma = g09; rs.ship.one_minus_beta = 0.1
	sky.apply(rs); star.update(rig, sky, 0.0, true)
	check("RS-1: the 90 deg Sun at 0.9c lights the ship from 25.842 deg off the heading (%.4f)" % angle_deg(star.dir_world, sky.heading_world), absf(angle_deg(star.dir_world, sky.heading_world) - 25.842) < 0.002)
	check("spec Doppler: D = gamma = 2.29416 for the 90 deg source at 0.9c (%.5f)" % star.target.doppler, absf(star.target.doppler - 2.29416) < 1e-4)
	var rs_rgb := Blackbody.lut_rgb(5772.0 * 2.29416)
	rs_rgb /= maxf(rs_rgb.x, maxf(rs_rgb.y, rs_rgb.z))
	check("spec colour: the light is the blackbody at 5772 x 2.29416 = 13242 K", star.target.colour.distance_to(rs_rgb) < 1e-3)

	# Point-source stars: the renderer draws them in the starfield, whose aberration is
	# Relativity.aberrate (CPU mirror of the shader, `make golden` off-axis cases).
	# The light's apparent_direction must agree, at rest and at 0.9999c.
	for beta in [0.0, 0.9999]:
		var far_stars := world.duplicate(true)
		var sun_row: Dictionary = body(far_stars, "sun")
		body(far_stars, "earth").rel_km = rel_at(Vector3.UP, 1.0e9) # keep the night-side Earth out of these sight lines
		var dirs := {"trappist-1": Vector3(0.2, -0.7, 0.68).normalized(), "aldebaran": Vector3(-0.8, 0.3, -0.52).normalized()}
		for id: String in dirs:
			var row: Dictionary = sun_row.duplicate(true)
			row.id = id; row.name = id
			row["teff_k"] = 2566.0 if id == "trappist-1" else 3927.0
			row.radius_km = 82800.0 if id == "trappist-1" else 3.13e7
			row.rel_km = rel_at(dirs[id], 1000.0 * SystemView.AU_KM)
			row.e_v_lux = 1.0
			far_stars.system.bodies.append(row)
		var g := 1.0 / sqrt((1.0 - beta) * (1.0 + beta)) if beta > 0.0 else 1.0
		far_stars.ship.beta = beta; far_stars.ship.gamma = g; far_stars.ship.one_minus_beta = 1.0 - beta
		sky.apply(far_stars)
		for id: String in dirs:
			var row := body(far_stars, id)
			var mine := vec_of(StarLight.apparent_direction(sv, row.rel_km, row.radius_km))
			var drawn := Relativity.aberrate(dirs[id], sky.heading_world.normalized(), beta)
			check("%s at %.4fc is a point and the light matches the starfield's aberration (%.5f deg)" % [id, beta, angle_deg(mine, drawn)], sv.drawn_points.has(id) and angle_deg(mine, drawn) < 0.01)
	# The resolved Sun near c too.
	var near_fast := near.duplicate(true)
	near_fast.ship.beta = 0.9999; near_fast.ship.gamma = 1.0 / sqrt(0.0001 * 1.9999); near_fast.ship.one_minus_beta = 0.0001
	sky.apply(near_fast); star.update(rig, sky, 0.0, true)
	var fast_centre: Vector3 = sv.discs.sun.material_override.get_shader_parameter("apparent_centre_w") if sv.drawn_discs.has("sun") else Vector3.ZERO
	check("at 0.9999c the light follows the resolved Sun's drawn centre (%.4f deg)" % angle_deg(star.dir_world, fast_centre), sv.drawn_discs.has("sun") and angle_deg(star.dir_world, fast_centre) < 0.01)

	# --- 4. Frame: the light comes from where the Sun is drawn through the bubble.
	var vp := SubViewport.new(); vp.size = PX; vp.own_world_3d = true; root.add_child(vp)
	var cam: Camera3D = Camera.new(); vp.add_child(cam); cam.current = true
	var at_rest := world.duplicate(true)
	var bases := []
	for heading in [[0.0, 0.0, -1.0], [0.6, -0.3, 0.74], [-0.2, 0.95, 0.1]]:
		bases.append(ShipFrame.ship_basis(PackedFloat64Array(heading)))
	var sun_gal := PackedFloat64Array([sun.rel_km.x, sun.rel_km.y, sun.rel_km.z])
	bases.append(Attitude.side_basis(sun_gal)) # the tour's stop attitude toward the Sun
	var e_rel: Dictionary = body(world, "earth").rel_km
	bases.append(Attitude.side_basis(PackedFloat64Array([e_rel.x, e_rel.y, e_rel.z])))
	var worst_px := 0.0
	var mirrored_px := 0.0
	var worst_axis := 0.0
	var all_front := true
	for i in bases.size():
		cam.attitude_basis = bases[i]
		sky.apply(at_rest)
		cam.follow(Vector3(8, 82, -4.8), 0.0, 0.0, 0.0); cam.sync_sky(sky, PX)
		star.update(rig, sky, 0.0, true)
		var d: Vector3 = star.interior_dir
		# Point the eye 12 degrees off the Sun, in two different offsets.
		for off in [Vector2(12, 0), Vector2(-5, 9)]:
			var yaw := atan2(d.z, d.x) + deg_to_rad(off.x)
			var tilt := clampf(rad_to_deg(asin(clampf(d.y, -1, 1))) + off.y, -80.0, 80.0)
			cam.follow(Vector3(8, 82, -4.8), tilt, yaw, 0.0); cam.sync_sky(sky, PX)
			star.update(rig, sky, 0.0, true)
			var sky_px := sky.camera.project(star.dir_world, Vector2(PX))
			var p := cam.global_position + star.interior_dir * 50.0
			if cam.is_position_behind(p) or sky.camera.is_behind(star.dir_world): all_front = false; continue
			var ship_px := cam.unproject_position(p)
			worst_px = maxf(worst_px, sky_px.distance_to(ship_px))
			# Negative control: a mirrored ship axis (the D-28 class of bug) must be caught.
			var bad := cam.global_position + Vector3(star.interior_dir.x, star.interior_dir.y, -star.interior_dir.z) * 50.0
			if not cam.is_position_behind(bad): mirrored_px = maxf(mirrored_px, sky_px.distance_to(cam.unproject_position(bad)))
		var light: DirectionalLight3D = star.light
		worst_axis = maxf(worst_axis, angle_deg(light.global_transform.basis.z, star.interior_dir))
	check("Sun in front of both cameras for every pose", all_front)
	check("ship camera and sky camera put the Sun on the same pixel in 5 attitudes x 2 views (worst %.4f px < 0.5)" % worst_px, worst_px < 0.5)
	check("negative control: a mirrored interior axis is caught: it misses by > 20 px in some pose (max %.1f px)" % mirrored_px, mirrored_px > 20.0)
	check("the DirectionalLight3D shines from the Sun (its +Z is the Sun direction, worst %.4f deg)" % worst_axis, worst_axis < 0.01)
	cam.attitude_basis = bases[0]; cam.follow(Vector3(8, 82, -4.8), 0.0, 0.0, 0.0); cam.sync_sky(sky, PX)

	# --- 5. Energy at Earth, at the ship's key, and the dark cruise.
	sky.apply(at_rest); star.update(rig, sky, 0.0, true)
	var key: DirectionalLight3D = rig.key
	check("at Earth the Sun light is full and shadowed (moody)", is_equal_approx(star.light.light_energy, StarLight.ENERGY_MAX) and star.light.visible and star.light.shadow_enabled)
	check("at Earth the broad key sits at its 25%% readability floor and casts no shadow", is_equal_approx(key.light_energy, StarLight.KEY_FLOOR_SHARE * rig.key_base) and not key.shadow_enabled and StarLight.KEY_FLOOR_SHARE == 0.25)
	# Shadow ownership across the whole range: exactly one shadowed directional light.
	var one_owner := true
	var key_floor_ok := true
	var key_monotonic := true
	var key_prev := INF
	var opacity_jump := 0.0
	var op_prev := [1.0, 0.0]
	var levels := at_rest.duplicate(true)
	var lux_earth: float = body(at_rest, "sun").e_v_lux
	for i in 81:
		body(levels, "sun").e_v_lux = pow(10.0, -0.5 + i * 0.08)
		sky.apply(levels); star.update(rig, sky, 0.0, true)
		var casters := int(star.light.shadow_enabled) + int(key.shadow_enabled) + int(rig.fill.shadow_enabled)
		if casters != 1: one_owner = false
		if key.light_energy < StarLight.KEY_FLOOR_SHARE * rig.key_base - 1e-6: key_floor_ok = false
		if key.light_energy > key_prev + 1e-6: key_monotonic = false
		key_prev = key.light_energy
		var key_op: float = key.shadow_opacity if key.shadow_enabled else 0.0
		var star_op: float = star.light.shadow_opacity if star.light.shadow_enabled else 0.0
		opacity_jump = maxf(opacity_jump, maxf(absf(key_op - op_prev[0]), absf(star_op - op_prev[1])))
		op_prev = [key_op, star_op]
	check("exactly one shadow-casting directional light from 0.3 lx to 1e6 lx (moody)", one_owner)
	check("the broad key never drops below its 25% floor and dims monotonically", key_floor_ok and key_monotonic)
	check("the shadow handover is continuous (max opacity step %.3f per 0.08 decade < 0.2)" % opacity_jump, opacity_jump < 0.2)
	body(levels, "sun").e_v_lux = lux_earth
	check("the shadow bias is the tuned ship key's", star.light.shadow_bias == key.shadow_bias and star.light.shadow_normal_bias == key.shadow_normal_bias)
	var dark := world.duplicate(true)
	for b: Dictionary in dark.system.bodies:
		var r: Dictionary = b.rel_km
		var s := 2.5e8 # interstellar: the system ~1.7 light-years away
		b.rel_km = {"x": r.x * s, "y": r.y * s, "z": r.z * s}
		b.e_v_lux = b.e_v_lux / (s * s)
	sky.apply(dark); star.update(rig, sky, 0.0, true)
	check("interstellar cruise: no star light (below the floor)", star.light.light_energy == 0.0 and not star.light.visible and not star.light.shadow_enabled)
	check("interstellar cruise: the moody broad key is fully restored", is_equal_approx(key.light_energy, rig.key_base) and key.shadow_enabled)
	var empty := world.duplicate(true); empty.erase("system")
	sky.apply(empty); star.update(rig, sky, 0.0, true)
	check("a world without a system section gives no star light", star.light.light_energy == 0.0 and star.source_id == "")

	# --- 6. Smooth transitions: energy, colour and direction never pop.
	sky.apply(at_rest); star.update(rig, sky, 0.0, true)
	sky.apply(dark)
	var max_step := 0.0
	var e_prev: float = star.light.light_energy
	for f in 240:
		star.update(rig, sky, 1.0 / 60.0)
		max_step = maxf(max_step, absf(star.light.light_energy - e_prev)); e_prev = star.light.light_energy
	check("leaving the Sun fades out over frames (max %.3f per 60 Hz frame < 4%% of max)" % max_step, max_step < 0.04 * StarLight.ENERGY_MAX and max_step > 0.0)
	check("after 4 s the fade has settled to the dark cruise", star.light.light_energy < 0.01 * StarLight.ENERGY_MAX)
	sky.apply(at_rest); star.update(rig, sky, 0.0, true)
	var jumped := at_rest.duplicate(true)
	var cur := vec_of(Planets.world_of(sun.rel_km)).normalized()
	var rotated := cur.rotated(Vector3.UP.cross(cur).normalized(), deg_to_rad(40.0))
	body(jumped, "sun").rel_km = rel_at(rotated, Planets.length64(Planets.world_of(sun.rel_km)))
	sky.apply(jumped)
	var max_turn := 0.0
	var d_prev := star.dir_world
	for f in 240:
		star.update(rig, sky, 1.0 / 60.0)
		max_turn = maxf(max_turn, angle_deg(d_prev, star.dir_world)); d_prev = star.dir_world
	check("a 40 deg jump (skip stage) turns the light smoothly (max %.2f deg/frame < 2)" % max_turn, max_turn < 2.0 and max_turn > 0.0)
	check("and it converges on the new Sun direction", angle_deg(star.dir_world, rotated) < 0.1)

	# --- 7. No flicker when two stars are nearly equal (alpha Cen-like pair).
	var pair := at_rest.duplicate(true)
	var twin: Dictionary = body(pair, "sun").duplicate(true)
	twin.id = "twin"; twin.name = "Twin"; twin["teff_k"] = 5231.0
	twin.rel_km = rel_at(rotated, Planets.length64(Planets.world_of(sun.rel_km)))
	pair.system.bodies.append(twin)
	sky.apply(pair); star.update(rig, sky, 0.0, true)
	var first: String = star.source_id
	var switches := 0
	for f in 120:
		var wobble := 1.0 + (0.08 if f % 2 == 0 else -0.08)
		body(pair, "twin").e_v_lux = body(pair, "sun").e_v_lux * wobble
		sky.apply(pair); star.update(rig, sky, 1.0 / 60.0)
		if star.source_id != first: switches += 1; first = star.source_id
	check("a near-equal pair (+-8%% alternating) never switches the dominant star (%d switches)" % switches, switches == 0)
	body(pair, "twin").e_v_lux = body(pair, "sun").e_v_lux * 4.0
	sky.apply(pair); star.update(rig, sky, 1.0 / 60.0)
	check("a clearly brighter star takes over", star.source_id == "twin")

	# --- 8. Eclipse: a body on the line of sight blocks the light.
	var eclipse := at_rest.duplicate(true)
	body(eclipse, "earth").rel_km = rel_at(cur, 50000.0)
	sky.apply(eclipse); star.update(rig, sky, 0.0, true)
	check("Earth in front of the Sun: the transmitted illuminance is zero, no light", star.target.transmission == 0.0 and star.light.light_energy == 0.0)

	# --- 9. Labels: what is physical and what is not.
	sky.apply(at_rest); star.update(rig, sky, 0.0, true)
	var m: Dictionary = Lighting.manifest(rig)
	check("manifest names the source star and its seen illuminance", m.star_light.source == "sun" and m.star_light.seen_lux > 1.0e5)
	check("manifest says the brightness is log-compressed and not physical", str(m.star_light.brightness).contains("log") and str(m.star_light.brightness).contains("not physical"))
	check("manifest says direction and colour are physical", str(m.star_light.direction).contains("aberrated") and str(m.star_light.colour).contains("Doppler"))
	check("HUD line labels the compression", star.hud_line().contains("compressed") and star.hud_line().contains("Sun"))
	Lighting.apply(rig, "moody_no_shadows"); star.update(rig, sky, 0.0, true)
	check("the shadow-disabled profile also disables star shadows", not star.light.shadow_enabled and star.light.visible)
	Lighting.apply(rig, "moody"); star.update(rig, sky, 0.0, true)

	# --- 10. Integration: the playable demo carries the star light.
	if FileAccess.file_exists("res://assets/ship_demo/ship.glb") or FileAccess.file_exists("res://ship_demo_bundle/ship.glb.bin"):
		var demo: Node = load("res://demos/ship_geometry_demo.tscn").instantiate()
		demo.setup_options = {"size": PX, "sky_state": "rest", "stars": false, "background": false, "planet_textures": false, "planet_preload": false}
		root.add_child(demo); await process_frame
		var rig2: Dictionary = demo.lighting
		check("demo installs a StarLight next to the internal lights", rig2.has("star") and rig2.star.light.get_parent() == rig2.key.get_parent() and rig2.star.light.name == "StarLight")
		demo.sky_world = at_rest.duplicate(true); demo.sky.apply(demo.sky_world)
		for f in 90: await process_frame
		check("demo frames converge the light on the Sun's rendered direction", rig2.star.source_id == "sun" and angle_deg(rig2.star.dir_world, vec_of(StarLight.apparent_direction(demo.sky.system_view, sun.rel_km, sun.radius_km))) < 0.5 and rig2.star.light.light_energy > 0.9 * StarLight.ENERGY_MAX)
		check("demo lighting manifest carries the star light", demo.lighting_manifest().has("star_light"))
		demo.queue_free(); await process_frame
	else:
		check("ship demo assets present (make ship-demo-assets)", false)

	sky.queue_free(); host.queue_free(); vp.queue_free(); await process_frame
	print("ship-star-light: %d passed, %d failures" % [passed, failures])
	quit(1 if failures else 0)
