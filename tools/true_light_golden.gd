extends SceneTree
## R3-TRUE-PROCESSED (eval B3, CLAUDE.md gate 2): the True star light on the GPU against the CPU.
## A white Lambertian deck (albedo 1, no specular, no ambient) under one DirectionalLight3D set by the
## production functions (StarLight.seen_lux, colour_of, true_light_energy), linear tonemapper, float
## target. The CPU reference is independent of the renderer: the deck's linear luminance is
## E / LUX_PER_ENERGY x the exposure gain x cos(incidence), E = e_v_lux x pointFluxRatio(T, D) from the
## package mirror (Relativity.point_flux_ratio), never the LUT expression under test.
##   G-TL-1  absolute: the Sun at rest, overhead and at 60 deg incidence, within 2%
##   G-TL-2  equal illuminance, equal light: 2566 K (TRAPPIST-1), 3927 K (Aldebaran), 11544 K, within 1%
##   G-TL-3  Doppler: the Sun at RS-3 (D = sqrt 19) and RS-4 (D = 0.22942) carries pointFluxRatio, within 1%
##   G-TL-4  the exposure gain scales the deck linearly (x = 1/795, the Sun level with the deck at 1 AU)
##   G-TL-N1 negative: the old unit-max-channel energy at 2566 K fails G-TL-2's detector
##   G-TL-N2 negative: a D^2-for-1/D^2 mutant at RS-3 fails G-TL-3's detector
## Run: make true-light-golden (needs a GPU window; in make golden).
const StarLight := preload("res://demos/ship_star_light.gd")
const OUT := "res://renders/true_light_golden"
var vp: SubViewport
var light: DirectionalLight3D
var passed := 0
var failed := 0


func _initialize() -> void:
	_run.call_deferred()


func check(name: String, ok: bool, detail: String) -> void:
	if ok: passed += 1
	else: failed += 1
	print("%s  %s  %s" % ["ok  " if ok else "FAIL", name, detail])


func setup() -> void:
	vp = SubViewport.new()
	vp.size = Vector2i(64, 64)
	vp.own_world_3d = true
	vp.use_hdr_2d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.BLACK
	env.ambient_light_source = Environment.AMBIENT_SOURCE_DISABLED
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.tonemap_exposure = 1.0
	env.glow_enabled = false
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 4.0
	cam.position = Vector3(0, 5, 0)
	cam.rotation_degrees = Vector3(-90, 0, 0)
	vp.add_child(cam)
	var deck := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(20, 20)
	deck.mesh = pm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.WHITE
	mat.roughness = 1.0
	mat.metallic = 0.0
	mat.metallic_specular = 0.0
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	mat.diffuse_mode = BaseMaterial3D.DIFFUSE_LAMBERT
	deck.material_override = mat
	vp.add_child(deck)
	light = DirectionalLight3D.new()
	light.shadow_enabled = false
	vp.add_child(light)


## The deck's linear luminance under the production True light for (e_v, T, D) at gain x and incidence.
func deck_y(e_v: float, teff: float, d: float, x: float, incidence_deg: float, energy_override := -1.0) -> float:
	var c: Vector3 = StarLight.colour_of(teff, d)
	var lux: float = StarLight.seen_lux(e_v, teff, d)
	light.light_color = Color(c.x, c.y, c.z).linear_to_srgb()
	light.light_energy = (StarLight.true_light_energy(lux, c) * x) if energy_override < 0.0 else energy_override
	light.rotation_degrees = Vector3(-90.0 + incidence_deg, 0, 0)
	for f in 3: await process_frame
	await RenderingServer.frame_post_draw
	var p := vp.get_texture().get_image().get_pixel(32, 32)
	return StarLight.luminance(Vector3(p.r, p.g, p.b))


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	setup()
	var lpe: float = StarLight.LUX_PER_ENERGY
	var e_v := 1.27e5
	var x := 0.5 * lpe / e_v # the Sun at rest lands the deck at linear 0.5
	# G-TL-1: absolute, overhead and at 60 deg incidence.
	for inc: float in [0.0, 60.0]:
		var got: float = await deck_y(e_v, Planets.T_SUN, 1.0, x, inc)
		var want := e_v / lpe * x * cos(deg_to_rad(inc))
		check("G-TL-1 absolute: the Sun at %d deg incidence" % int(inc), absf(got / want - 1.0) < 0.02, "GPU Y %.5f, CPU %.5f (ratio %.4f, limit 2%%)" % [got, want, got / want])
	# G-TL-2: equal illuminance at any temperature, equal light.
	var y_sun: float = await deck_y(e_v, Planets.T_SUN, 1.0, x, 0.0)
	for tk: float in [2566.0, 3927.0, 11544.0]:
		var y: float = await deck_y(e_v, tk, 1.0, x, 0.0)
		check("G-TL-2 equal light: %.0f K at the Sun's illuminance" % tk, absf(y / y_sun - 1.0) < 0.01, "Y ratio %.4f (limit 1%%)" % (y / y_sun))
	# G-TL-N1: the old unit-max-channel energy (no 1/Y) at 2566 K.
	var c_old: Vector3 = StarLight.colour_of(2566.0, 1.0)
	var y_old: float = await deck_y(e_v, 2566.0, 1.0, x, 0.0, StarLight.true_energy(e_v) * x)
	check("G-TL-N1 negative: unit-max energy at 2566 K fails the equal-light detector", absf(y_old / y_sun - 1.0) >= 0.01, "Y ratio %.4f (must be off by >= 1%%; colour Y %.3f)" % [y_old / y_sun, StarLight.luminance(c_old)])
	# G-TL-3: Doppler at RS-3 and RS-4, against the package's pointFluxRatio.
	for row: Array in [["RS-3", sqrt(19.0)], ["RS-4", 0.22942]]:
		var d: float = row[1]
		var r := Relativity.point_flux_ratio(Planets.T_SUN, d)
		var xd := x / r # keep the pixel near 0.5
		var y: float = await deck_y(e_v, Planets.T_SUN, d, xd, 0.0)
		var want := e_v * r / lpe * xd
		check("G-TL-3 Doppler %s: the deck carries pointFluxRatio(5772 K, %.5f) = %s" % [row[0], d, String.num_scientific(r)], absf(y / want - 1.0) < 0.01, "GPU Y %.5f, CPU %.5f (ratio %.4f, limit 1%%)" % [y, want, y / want])
	# G-TL-N2: a D^2 mutant at RS-3 (the received flux multiplied, not divided, by D^2).
	var d3 := sqrt(19.0)
	var r3 := Relativity.point_flux_ratio(Planets.T_SUN, d3)
	var c3: Vector3 = StarLight.colour_of(Planets.T_SUN, d3)
	var mutant_lux := StarLight.seen_lux(e_v, Planets.T_SUN, d3) * d3 * d3 * d3 * d3
	var y_mut: float = await deck_y(e_v, Planets.T_SUN, d3, x / r3, 0.0, StarLight.true_light_energy(mutant_lux, c3) * x / r3)
	check("G-TL-N2 negative: a D^2 mutant at RS-3 fails the Doppler detector", absf(y_mut / (e_v * r3 / lpe * x / r3) - 1.0) >= 0.01, "Y ratio %.1f (must be off by >= 1%%)" % (y_mut / (e_v * r3 / lpe * x / r3)))
	# G-TL-4: the exposure gain is linear (the Sun level with the deck at 1 AU: 1/795).
	var g := StarLight.deck_exposure(80.0, e_v, 0.0)
	var y_raw: float = await deck_y(e_v, Planets.T_SUN, 1.0, g, 0.0)
	check("G-TL-4 the exposure gain scales the deck linearly (gain 1/%.1f)" % (1.0 / g), absf(y_raw / (e_v / lpe * g) - 1.0) < 0.02, "GPU Y %.4f vs CPU %.4f" % [y_raw, e_v / lpe * g])
	vp.get_texture().get_image().save_png(OUT + "/last.png")
	print("true-light-golden: %d passed, %d failures" % [passed, failed])
	quit(1 if failed else 0)
