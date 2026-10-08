extends SceneTree
## Lightspeed loading view (design_docs/planned/r1/lightspeed-loading.md), headless:
## every title route goes through LoadingJump and arrives where it did before; real
## progress is monotone and reaches 1.0 exactly when the destination is ready; the
## displayed progress never runs ahead; beta reaches 0.99999 at 100% (the mirror's
## functions); the prefetched simulation is the one the route uses; command-line
## modes and a sky-less title bypass it; the shared loads equal fresh loads.
## Run: AILANG_BIN=$(command -v ailang) godot --headless --path . --script tests/test_loading_jump.gd
var failed := 0
var passed := 0
var scratch := ProjectSettings.globalize_path("res://.godot/tmp/loading_jump")
const Main := preload("res://main.gd")
const Demo := preload("res://demos/ship_geometry_demo.gd")


func check(ok: bool, message: String) -> void:
	if ok: passed += 1
	else: failed += 1
	print("%s %s" % ["ok" if ok else "FAIL", message])


func _initialize() -> void:
	_run.call_deferred()


func frames(n := 3) -> void:
	for i in n:
		await process_frame


func key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = true
	return e


func _run() -> void:
	test_speed()
	test_text()
	test_bypass()
	test_starfield_share()
	test_background_share()
	test_avatar_offer()
	test_sim_warm()
	await test_routes()
	print("loading-jump: %d passed, %d failures" % [passed, failed])
	quit(1 if failed else 0)


## beta, gamma and 1 - beta are the sunholo/relativity mirror's at phi = p atanh(0.99999).
func test_speed() -> void:
	var phi := Relativity.rapidity_of_beta(0.99999)
	check(LoadingJump.phi_max() == phi, "phi_max = Relativity.rapidity_of_beta(0.99999) = %.15f" % phi)
	var v := LoadingJump.speed_at(1.0)
	check(absf(v[0] - 0.99999) < 1e-15 and v[0] == Relativity.beta_of_rapidity(phi), "100%%: beta = 0.99999 from beta_of_rapidity (%.17f)" % v[0])
	check(v[1] == Relativity.gamma_of_rapidity(phi) and absf(v[1] - 223.60735676957853) < 1e-9, "100%%: gamma = gamma_of_rapidity = 223.607 (package value)")
	check(v[2] == Relativity.one_minus_beta_of_rapidity(phi) and absf(v[2] / 1e-5 - 1.0) < 1e-9, "100%%: 1 - beta = one_minus_beta_of_rapidity = 1e-5 (never 1.0 - beta)")
	var r := LoadingJump.speed_at(0.0)
	check(r[0] == 0.0 and r[1] == 1.0 and r[2] == 1.0, "0%: at rest (beta 0, gamma 1, 1 - beta 1)")
	var h := LoadingJump.speed_at(0.5)
	check(h[0] == Relativity.beta_of_rapidity(0.5 * phi), "50%%: beta = beta_of_rapidity(phi_max / 2) = %.6f" % h[0])
	var mono := true
	var prev := -1.0
	for i in 201:
		var b: float = LoadingJump.speed_at(i / 200.0)[0]
		mono = mono and b > prev
		prev = b
	check(mono, "beta rises strictly with progress over 201 steps")
	check(LoadingJump.speed_at(1.7)[0] == v[0] and LoadingJump.speed_at(-0.2)[0] == 0.0, "progress outside 0..1 is clamped")


func test_text() -> void:
	check(LoadingJump.beta_text(0.0, 1.0) == "0.000", "beta text at rest: 0.000")
	check(LoadingJump.beta_text(0.995538, 0.004462) == "0.9955", "beta text at 50%: 0.9955")
	var v := LoadingJump.speed_at(1.0)
	check(LoadingJump.beta_text(v[0], v[2]) == "0.99999", "beta text at 100%%: 0.99999 (%s)" % LoadingJump.beta_text(v[0], v[2]))
	check(LoadingJump.omb_text(v[2]) == "1.0 × 10⁻⁵", "1 - beta text at 100%%: %s" % LoadingJump.omb_text(v[2]))
	check(LoadingJump.omb_text(0.0446) == "0.0446", "1 - beta text above 0.001 is plain")


## Command-line modes never see the title, so never the jump; a title without a sky routes at once.
func test_bypass() -> void:
	check(Main.launch_route({}) == "title", "only a plain launch opens the title screen (and so can show the jump)")
	for f in ["ship-demo", "ship-demo-smoke", "ship-identification-smoke", "solar-departure-smoke"]:
		check(Main.launch_route({f: ""}) == "ship", "--%s opens the ship directly (no title, no jump)" % f)
	for f in ["voyage", "interior", "capture", "golden", "bench", "movie", "map", "map-capture", "transit", "starmap-smoke", "planet-smoke", "m4-smoke"]:
		check(Main.launch_route({f: "x"}) == "reference", "--%s bypasses the title and the jump" % f)


## A second field loading the same stack while the first lives copies it; the rows equal a fresh load.
func test_starfield_share() -> void:
	var a := Starfield.new()
	check(a.load_tiers("quick") and not a.shared_load, "first quick-tier load reads the files")
	var b := Starfield.new()
	check(b.load_tiers("quick") and b.shared_load, "second quick-tier load shares the live field's load")
	var c_pos := a.pos.duplicate()
	var c_custom := a.custom.duplicate()
	var c_ids := a.ids.duplicate()
	var c_meta := [a.count, a.tiers.duplicate(), a.skipped_missing, a.nav_restored, a.nav_max_shift, a.nav_refused.duplicate()]
	a.free()
	b.free()
	var f := Starfield.new()
	check(f.load_tiers("quick") and not f.shared_load, "with no live field the next load reads the files again")
	check(f.pos == c_pos and f.custom == c_custom and f.ids == c_ids, "shared rows = a fresh load (positions, custom data, identities: %d rows)" % f.count)
	check([f.count, f.tiers, f.skipped_missing, f.nav_restored, f.nav_max_shift, f.nav_refused] == c_meta, "shared counters = a fresh load (count, tiers, skipped, navigation restore)")
	var g := Starfield.new()
	check(g.load_tiers("bright") and not g.shared_load, "a different stack is never shared")
	g.free()
	var b2 := Starfield.new()
	var rev0 := b2.identity_revision
	f.load_tiers("quick")
	b2.load_tiers("quick")
	check(b2.shared_load and b2.identity_revision - rev0 > 0, "a shared load still advances the identity revision (index caches rebuild)")
	f.free()
	b2.free()


## A second sky attached while the first holds the panorama shares it: same textures, same calibration.
func test_background_share() -> void:
	if not SkyBackground.available():
		print("skip background share: no panorama (make sky-assets)")
		return
	var a := SkyBackground.new()
	check(a.attach(Environment.new(), 720.0, 62.0) and not a.shared_hit, "first sky decodes the panorama")
	var b := SkyBackground.new()
	check(b.attach(Environment.new(), 720.0, 62.0) and b.shared_hit, "second sky, first still alive, shares it")
	check(b.material.get_shader_parameter("photo") == a.material.get_shader_parameter("photo") and b.dark_patch_y == a.dark_patch_y and b.stretch == a.stretch \
		and b.cdm2_per_unit == a.cdm2_per_unit and b.peak_y == a.peak_y and b._y == a._y and b._t == a._t and b._logy == a._logy, "shared: the same textures and the same calibration")
	check(b.material.get_shader_parameter("pano_px_per_screen_px") == a.material.get_shader_parameter("pano_px_per_screen_px"), "shared: the same pixel scale")
	a = null
	b = null
	check(SkyBackground._live_shared(SkyBackground._shared.keys()[0] if not SkyBackground._shared.is_empty() else "").is_empty(), "once no sky holds the pair it is released (weak references)")


func test_avatar_offer() -> void:
	var dir := LoadingJump.CREW_DIR
	var paths := CaptainAvatar.sprite_paths(dir)
	check(paths.size() >= 2, "captain sprite list read from its manifest (%d)" % paths.size())
	if paths.is_empty():
		return
	CaptainAvatar.offer_texture(paths[0])
	var offered: Texture2D = CaptainAvatar._offered.get(paths[0])
	var a := CaptainAvatar.new()
	check(offered != null and a.load_dir(dir), "load_dir with one offered sprite")
	check(a.textures.values().has(offered), "load_dir uses the offered sprite (make_texture: the same code path as its own load)")
	check(CaptainAvatar._offered.is_empty(), "an offered sprite is taken once")
	a.free()


func test_sim_warm() -> void:
	var w := SimBridge.warm(SimBridge.DEPARTURE_MINOR)
	check(w != null and not w.hello_reply.is_empty(), "a warm sim completes the hello handshake")
	if w == null:
		return
	var pid := w.child_pid
	SimBridge.offer_warm(w)
	var other := SimBridge.new() # a different protocol minor never takes it
	other.want_minor = SimBridge.PROTO_MINOR
	other.launch_override = {"bin": "/bin/false", "args": []}
	other.start()
	check(SimBridge.has_warm(), "a start() with a launch override or another minor leaves the warm sim")
	var b := SimBridge.new()
	b.want_minor = SimBridge.DEPARTURE_MINOR
	check(b.start() and b.child_pid == pid and not SimBridge.has_warm(), "the next default start() takes the warm sim (same child)")
	check(b.new_game(424242, "sol", false, {"standoff_au": 1000.0}) and b.world.get("tick") == 0, "the taken sim plays: new_game accepted")
	b.stop()
	var x := SimBridge.warm(SimBridge.DEPARTURE_MINOR)
	SimBridge.offer_warm(x)
	var xp := x.child_pid if x != null else -1
	SimBridge.discard_warm()
	check(not SimBridge.has_warm() and (xp < 0 or not OS.is_process_running(xp)), "an unused warm sim is stopped")


func current_main() -> Node:
	return current_scene if current_scene != null and current_scene.get_script() == Main else null


## Press a route on a title with the jump forced on (headless: no sky behind it).
## Returns {jump, arrived_at_one, mono, never_ahead, frames, warm_pid}.
func press(main: Node, route: String) -> Dictionary:
	main.title.buttons[route].pressed.emit()
	var jump: LoadingJump = root.get_node_or_null("LoadingJump")
	var out := {"jump": jump != null, "mono": true, "never_ahead": true, "ready_at_one": false, "early": false, "warm_pid": -1, "beta_end": -1.0, "white": false}
	if jump == null:
		return out
	out["title_frozen"] = main.title.process_mode == Node.PROCESS_MODE_DISABLED and main.title.sky == null
	var last_p := -1.0
	var last_s := -1.0
	var saw_one := false
	for i in 900:
		await process_frame
		if not is_instance_valid(jump):
			break
		if jump.warm_pid > 0:
			out["warm_pid"] = jump.warm_pid
		out["mono"] = out["mono"] and jump.progress >= last_p and jump.shown >= last_s
		out["never_ahead"] = out["never_ahead"] and jump.shown <= jump.progress
		last_p = jump.progress
		last_s = jump.shown
		if jump.progress >= 1.0 and not saw_one:
			saw_one = true
			out["ready_at_one"] = jump.arrived and _destination(route) != null
		if jump.progress < 1.0 and jump.arrived:
			out["early"] = true
		if jump._phase == "white":
			out["white"] = true
			out["beta_end"] = LoadingJump.speed_at(jump.shown)[0]
			out["shown_end"] = jump.shown
	out["finished"] = not is_instance_valid(jump) or jump.done
	out["sim_untaken"] = SimBridge.has_warm()
	return out


func _destination(route: String) -> Node:
	if route == "map":
		var m := root.find_children("*", "GalaxyMap", true, false)
		return m[0] if m.size() == 1 else null
	var d := current_scene
	return d if d != null and d.get_script() == Demo and d.ready_ok and (route == "ship" or d.solar_tour != null) else null


func report(route: String, r: Dictionary) -> void:
	check(r["jump"] and r.get("title_frozen", false), "%s: the press opens the loading jump (title sky taken, title input off)" % route)
	check(r["mono"] and r["never_ahead"], "%s: progress and displayed progress are monotone; displayed never ahead of real" % route)
	check(r["ready_at_one"] and not r["early"], "%s: progress reaches 1.0 exactly when the destination is ready (not before, not after)" % route)
	check(r["white"] and r.get("shown_end", 0.0) == 1.0 and absf(r["beta_end"] - 0.99999) < 1e-15, "%s: the white-out starts at 100%% with beta = 0.99999" % route)
	check(r.get("finished", false) and root.get_node_or_null("LoadingJump") == null, "%s: the jump fades out and frees itself" % route)
	check(not r["sim_untaken"], "%s: no warm simulation left over" % route)


## Through main.tscn, as tests/test_title_screen.gd test_routes, with the jump forced on.
func test_routes() -> void:
	var d := scratch.path_join("routes")
	OS.execute("/bin/rm", PackedStringArray(["-rf", d]))
	DirAccess.make_dir_recursive_absolute(d)
	Main.title_overrides = {"sky": false, "settings_dir": d}
	Main.demo_overrides = {"stars": false, "background": false}
	var main: Node = load("res://main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await frames()
	# a title without a sky and no override: no jump (the existing behaviour, tests/test_title_screen.gd)
	check(main.title != null and main.title.sky == null, "headless title has no sky")
	Main.loading_overrides = {"enabled": true}
	# Board the ship
	var r := await press(main, "ship")
	report("ship", r)
	var demo: Node = current_scene
	check(demo != null and demo.get_script() == Demo and demo.ready_ok and demo.sky_state == "live" and demo.sky.beta == 0.0 and demo.camera.pullback == 0.0,
		"ship: the same destination (current ship, live rest, captain eye)")
	if demo != null and demo.get_script() == Demo:
		demo.auto = false
		demo.journey_auto_tick = false
		check(demo.journey_sim != null and demo.journey_sim.child_pid == r["warm_pid"] and r["warm_pid"] > 0, "ship: navigation runs on the prefetched simulation (pid %d)" % r["warm_pid"])
		check(demo.menu_return and demo.menu_button.visible, "ship: launched from the menu (Main menu button)")
		demo._unhandled_input(key(KEY_ESCAPE))
		await frames(4)
	var m2 := current_main()
	check(m2 != null and m2.title != null and m2.title.is_inside_tree() and m2.loading_jump == null, "Esc aboard returns to a fresh title screen")
	# Guided voyage
	if m2 == null:
		return
	r = await press(m2, "guided")
	report("guided", r)
	demo = current_scene
	if demo != null and demo.get_script() == Demo:
		demo.auto = false
		demo.journey_auto_tick = false
		check(demo.ready_ok and demo.solar_tour != null and demo.journey_map != null and demo.journey_map.guided_read_only, "guided: the same destination (solar-departure tour aboard)")
		check(demo.journey_sim != null and demo.journey_sim.child_pid == r["warm_pid"] and r["warm_pid"] > 0, "guided: the tour runs on the prefetched simulation")
		demo.menu_button.pressed.emit()
		await frames(4)
	else:
		check(false, "guided: opens the ship")
	var m3 := current_main()
	if m3 == null:
		check(false, "the HUD's Main menu button returns to the title screen")
		return
	# Galaxy map
	r = await press(m3, "map")
	report("map", r)
	var maps := m3.find_children("*", "GalaxyMap", true, false)
	check(maps.size() == 1 and m3._map_mode and m3.title == null, "map: the same destination (the standalone map)")
	check(m3.sim.child_pid == r["warm_pid"] and r["warm_pid"] > 0, "map: the map's simulation is the prefetched one")
	check(maps.size() == 1 and maps[0].display_name(maps[0].index_of("CNS5:3627")) != "", "map: catalogue loaded (alpha Cen A named)")
	m3._unhandled_key_input(key(KEY_ESCAPE))
	await frames(4)
	var m4 := current_main()
	check(m4 != null and m4 != m3 and m4.title != null, "Esc on the map returns to the title screen")
	# no prefetch: the same routes still arrive (the prefetch only saves time)
	Main.loading_overrides = {"enabled": true, "prefetch": false}
	if m4 != null:
		r = await press(m4, "map")
		check(r["jump"] and r["ready_at_one"] and r["mono"] and r.get("finished", false), "map without the prefetch: the jump still arrives, progress real and monotone")
		check(m4.find_children("*", "GalaxyMap", true, false).size() == 1, "map without the prefetch: the same destination")
	Main.title_overrides = {}
	Main.demo_overrides = {}
	Main.loading_overrides = {}
	if current_scene != null:
		current_scene.queue_free()
	await frames()
