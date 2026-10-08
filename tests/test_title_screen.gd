extends SceneTree
## Title screen (design_docs/planned/r1/title-screen.md): a plain launch shows the
## menu; every command-line mode bypasses it; each button routes to its mode and
## Esc comes back; the settings round-trip; the credits are the repo's own.
## Run: AILANG_BIN=$(command -v ailang) godot --headless --path . --script tests/test_title_screen.gd
var failed := 0
var passed := 0
var scratch := ProjectSettings.globalize_path("res://.godot/tmp/title_screen")
const Main := preload("res://main.gd")


func check(ok: bool, message: String) -> void:
	if ok: passed += 1
	else: failed += 1
	print("%s %s" % ["ok" if ok else "FAIL", message])


func _initialize() -> void:
	_run.call_deferred()


func frames(n := 3) -> void:
	for i in n:
		await process_frame


func fresh(name: String) -> String:
	var d := scratch.path_join(name)
	OS.execute("/bin/rm", PackedStringArray(["-rf", d]))
	DirAccess.make_dir_recursive_absolute(d)
	return d


func key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = true
	return e


func _run() -> void:
	test_launch_routes()
	test_settings()
	test_credits()
	await test_menu_alone()
	await test_routes()
	print("title-screen: %d passed, %d failures" % [passed, failed])
	quit(1 if failed else 0)


## Every command-line mode keeps its entry; only the plain launch shows the menu.
func test_launch_routes() -> void:
	check(Main.launch_route({}) == "title", "plain launch (no user args) opens the title screen")
	for f in ["ship-demo", "ship-demo-smoke", "ship-identification-smoke", "solar-departure-smoke"]:
		check(Main.launch_route({f: ""}) == "ship", "--%s still opens the current ship directly" % f)
	for f in ["voyage", "interior", "interior-capture", "m4-smoke", "capture", "golden", "bench", "movie", "map", "map-capture",
			"transit", "starmap-smoke", "planet-smoke", "golden-m5", "capture-m5", "glow-eps-sheet", "record", "text-only", "ai-hello", "tier"]:
		check(Main.launch_route({f: "x"}) == "reference", "--%s bypasses the menu (reference/smoke mode unchanged)" % f)
	check(Main.current_ship_entry({}) and Main.current_ship_entry({"ship-demo": ""}), "current-ship entry contract unchanged")


func test_settings() -> void:
	var d := fresh("settings")
	var s := GameSettings.new()
	s.dir = d
	s.load_settings()
	check(not s.auto_view and not s.text_only, "defaults: Realistic view, text-only off")
	var ai := AiSettings.new() # an AI tick and ceiling saved elsewhere must survive
	ai.dir = d
	ai.opt_in = true
	ai.set_ceiling(2.5)
	ai.save_settings()
	s.auto_view = true
	s.text_only = true
	check(s.save_settings(), "settings save")
	var t := GameSettings.new()
	t.dir = d
	t.load_settings()
	check(t.auto_view and t.text_only, "settings round-trip (view Auto, text-only on)")
	var ai2 := AiSettings.new()
	ai2.dir = d
	ai2.load_settings()
	check(ai2.text_only and ai2.opt_in and is_equal_approx(ai2.ceiling_usd, 2.5), "text-only is AiSettings' own field; the AI tick and ceiling are kept")
	var f := FileAccess.open(d.path_join(GameSettings.FILE), FileAccess.WRITE)
	f.store_string("[display]\nauto_view=\"yes\"\n{{{ not a config")
	f.close()
	var u := GameSettings.new()
	u.dir = d
	u.load_settings()
	check(not u.auto_view, "a corrupt settings.cfg falls back to the defaults")
	var bad := GameSettings.new()
	bad.dir = d.path_join("missing/dir")
	bad.load_settings()
	check(not bad.save_settings() and not bad.auto_view, "an unwritable settings dir reports failure, never throws")


func test_credits() -> void:
	var txt := TitleScreen.credits_text()
	for need in ["NOIRLab", "E. Slawik", "CC BY 4.0", "Solar System Scope", "CNS5", "Gaia", "DPAC", "Hipparcos", "NASA Exoplanet Archive", "Godot", "AILANG", "Apache"]:
		check(txt.contains(need), "credits name %s" % need)
	check(txt.contains(Credits.PLANET_LINE), "planet credit line matches data/planets/CREDITS (via Credits.PLANET_LINE)")
	var papers := TitleScreen.cited_papers()
	check(papers.size() >= 25, "credits read the sim's cited papers from sim/data/*.ail (%d)" % papers.size())
	for need in ["Agol et al. 2021", "Ducrot et al. 2020", "Kervella et al. 2017", "Akeson et al. 2021", "Mallama", "Archinal et al. 2018", "Park et al. 2021", "Richichi"]:
		check(papers.any(func(p: String) -> bool: return p.begins_with(need)), "cited: %s" % need)
	check(not papers.any(func(p: String) -> bool: return p.begins_with("assumed")), "assumptions are not listed as references")


## A standalone menu: buttons, focus, keyboard, panels, route signals.
func test_menu_alone() -> void:
	var d := fresh("menu")
	var t := TitleScreen.new({"sky": false, "settings_dir": d})
	root.add_child(t)
	await frames()
	check(t.buttons.keys() == ["ship", "guided", "map", "settings", "credits", "quit"], "six buttons in order")
	check(t.buttons["ship"].text == "Board the ship" and t.buttons["guided"].text == "Guided voyage", "button labels")
	check(t.buttons["ship"].has_focus(), "Board the ship has keyboard focus at start")
	check(t.version_label.text.begins_with("dev build · "), "build label shown: %s" % t.version_label.text)
	var ship_path: NodePath = t.buttons["ship"].get_path()
	check(t.buttons["quit"].get_node(t.buttons["quit"].focus_neighbor_bottom) == t.buttons["ship"] and t.buttons["ship"].get_node(t.buttons["ship"].focus_neighbor_top) == t.buttons["quit"], "Up / Down wrap round the list")
	var down := InputEventAction.new()
	down.action = "ui_down"
	down.pressed = true
	root.push_input(down)
	await frames()
	check(t.buttons["guided"].has_focus(), "Down moves focus to Guided voyage (keyboard navigable)")
	check(t.hint.text == TitleScreen.ENTRIES[1][2], "the hint describes the focused button")
	var got := []
	t.chosen.connect(func(r: String) -> void: got.append(r))
	for r in ["ship", "guided", "map", "settings", "credits", "quit"]:
		t.buttons[r].pressed.emit()
		if t.panel_open():
			t.close_panels()
	check(got == ["ship", "guided", "map", "quit"], "buttons emit their routes; settings/credits stay on the menu (%s)" % [got])
	t.buttons["credits"].pressed.emit()
	await frames()
	check(t.credits_panel.visible and not t.menu.visible and t.credits_body.text.contains("NOIRLab"), "Credits opens the credits panel")
	t.credits_scroll.size = Vector2(400, 200) # headless: give the scroll a real viewport
	await frames()
	root.push_input(key(KEY_PAGEDOWN))
	await frames()
	check(t.credits_scroll.scroll_vertical > 0, "PageDown scrolls the credits (keyboard)")
	root.push_input(key(KEY_ESCAPE))
	await frames()
	check(not t.credits_panel.visible and t.menu.visible and t.buttons["credits"].has_focus(), "Esc closes credits and refocuses its button")
	t.buttons["settings"].pressed.emit()
	await frames()
	check(t.settings_panel.visible and t.view_option.has_focus(), "Settings opens with the view option focused")
	t.view_option.select(1)
	t.view_option.item_selected.emit(1)
	t.text_only_box.button_pressed = true
	var s := GameSettings.new()
	s.dir = d
	s.load_settings()
	check(s.auto_view and s.text_only and t.settings_status.text.begins_with("Saved"), "settings panel saves on change")
	t.queue_free()
	await frames()
	var t2 := TitleScreen.new({"sky": false, "settings_dir": d})
	root.add_child(t2)
	await frames()
	check(t2.view_option.selected == 1 and t2.text_only_box.button_pressed, "a new title screen shows the saved settings")
	t2.queue_free()
	await frames()


func current_main() -> Node:
	return current_scene if current_scene != null and current_scene.get_script() == Main else null


## Through main.tscn: plain launch -> each route -> Esc back to the menu.
func test_routes() -> void:
	var d := fresh("routes")
	Main.title_overrides = {"sky": false, "settings_dir": d}
	Main.demo_overrides = {"stars": false, "background": false}
	var s := GameSettings.new()
	s.dir = d
	s.auto_view = true
	s.save_settings()
	var main: Node = load("res://main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await frames()
	check(main.title != null and main.title.is_inside_tree(), "plain launch of main.tscn shows the title screen")
	# Board the ship
	main.title.buttons["ship"].pressed.emit()
	await frames(4)
	var demo: Node = current_scene
	check(demo != null and demo.get_script() == preload("res://demos/ship_geometry_demo.gd"), "Board the ship opens the current 3D ship")
	if demo != null and demo.has_method("return_to_menu"):
		demo.auto = false
		demo.journey_auto_tick = false
		check(demo.ready_ok and demo.sky_state == "live" and demo.sky.beta == 0. and demo.camera.pullback == 0., "it is today's default: live rest, captain eye")
		check(demo.menu_return and demo.menu_button.visible, "launched from the menu: a Main menu button in the HUD")
		check(demo.sky.system_view.body_fader, "the saved view (Auto) reaches the ship")
		demo._unhandled_input(key(KEY_ESCAPE))
		await frames(4)
	var m2 := current_main()
	check(m2 != null and m2.title != null and m2.title.is_inside_tree(), "Esc aboard returns to the title screen")
	# Guided voyage
	if m2 != null:
		m2.title.buttons["guided"].pressed.emit()
		await frames(4)
	demo = current_scene
	if demo != null and demo.has_method("return_to_menu"):
		demo.auto = false
		demo.journey_auto_tick = false
		check(demo.ready_ok and demo.solar_tour != null and demo.journey_map != null and demo.journey_map.guided_read_only, "Guided voyage starts the solar-departure tour aboard")
		demo.menu_button.pressed.emit()
		await frames(4)
	else:
		check(false, "Guided voyage opens the ship")
	var m3 := current_main()
	check(m3 != null and m3.title != null, "the HUD's Main menu button returns to the title screen")
	# Galaxy map
	if m3 != null:
		m3.title.buttons["map"].pressed.emit()
		await frames(6)
	var maps := m3.find_children("*", "GalaxyMap", true, false) if m3 != null else []
	check(m3 != null and maps.size() == 1 and m3._map_mode and m3.title == null, "Galaxy map opens the standalone map")
	if m3 != null:
		m3._unhandled_key_input(key(KEY_ESCAPE))
		await frames(4)
	var m4 := current_main()
	check(m4 != null and m4 != m3 and m4.title != null, "Esc on the map (opened from the menu) returns to the title screen")
	Main.title_overrides = {}
	Main.demo_overrides = {}
	if current_scene != null:
		current_scene.queue_free()
	await frames()
