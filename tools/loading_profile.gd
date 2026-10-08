extends SceneTree
## Where the title screen's routes spend their load time (design_docs/planned/r1/lightspeed-loading.md).
## Needs a GPU window (the real sky). Two modes:
##   godot --path . --resolution 1280x720 --script tools/loading_profile.gd -- --pieces
##       each step of a route timed on its own, cold, in this process
##   LOADING_ROUTE=ship|guided|map godot --path . --resolution 1280x720 --script tools/loading_profile.gd
##       (an environment variable: any user arg would make main.gd bypass the title) the whole route from main.tscn's title screen: press -> destination ready, every frame's gap
## Prints "loading-profile: ..." lines; nothing is written.

var _args := {}


func _initialize() -> void:
	if OS.get_environment("LOADING_ROUTE") != "":
		_args["route"] = OS.get_environment("LOADING_ROUTE")
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		_args[kv[0]] = kv[1] if kv.size() > 1 else ""
	_run.call_deferred()


func _ms(t0: int) -> float:
	return (Time.get_ticks_usec() - t0) / 1000.0


func _run() -> void:
	root.size = Vector2i(1280, 720)
	if _args.has("pieces"):
		await _pieces()
	else:
		await _route(_args.get("route", "ship"))
	quit(0)


func _step(name: String, f: Callable) -> Variant:
	var t0 := Time.get_ticks_usec()
	var v: Variant = f.call()
	print("loading-profile: %-34s %8.1f ms" % [name, _ms(t0)])
	return v


func _pieces() -> void:
	var demo_assets := "res://assets/ship_demo/"
	_step("ship.glb (GLTF parse + scene)", func() -> Variant: return AreaBundle.load_glb(demo_assets + "ship.glb"))
	_step("walk_bridge+walk_lower.glb", func() -> Variant:
		AreaBundle.load_glb(demo_assets + "walk_bridge.glb"); return AreaBundle.load_glb(demo_assets + "walk_lower.glb"))
	var Commons: GDScript = load("res://demos/ship_commons.gd")
	_step("commons meshes (4 GLB)", func() -> Variant:
		var m: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(Commons.asset("manifest.json")))
		for k in ["painted", "collision", "walk", "coarse"]:
			if m.assets.has(k): Commons.load_mesh(Commons.asset(m.assets[k]))
		return null)
	_step("captain sprites", func() -> Variant: var a := CaptainAvatar.new(); a.load_dir("res://assets/characters/captain"); a.free(); return null)
	_step("star tiers (large+quick+bright)", func() -> Variant: var s := Starfield.new(); s.load_tiers(Starfield.default_tier()); s.free(); return null)
	_step("sky background (2 x 10k PNG)", func() -> Variant: var b := SkyBackground.new(); return b.attach(Environment.new(), 720, 62.0))
	_step("planet texture preload", func() -> Variant: var s := Starfield.new(); var v := SystemView.new(); v.setup(s, true); v.preload_textures(); v.free(); s.free(); return null)
	var sim := SimBridge.new()
	sim.want_minor = SimBridge.DEPARTURE_MINOR
	_step("sim start (spawn + hello)", func() -> Variant: return sim.start())
	_step("sim new_game", func() -> Variant: return sim.new_game(424242, "sol", false, {"standoff_au": 1000.0}))
	sim.stop()
	var map: Node = _step("galaxy map instantiate", func() -> Variant: return load("res://ui/galaxy_map.tscn").instantiate())
	_step("map catalogue + names", func() -> Variant:
		map.load_catalogue("res://data/starmap/stars.json"); map.load_names("res://data/starmap/names.json"); return null)
	map.free()


## Press a title button with the real sky; time to "destination ready" and the frame gaps.
func _route(route: String) -> void:
	var Main: GDScript = load("res://main.gd")
	var t_boot := Time.get_ticks_usec()
	var main: Node = load("res://main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	for i in 30: await process_frame
	print("loading-profile: title shown (sky on) after %.1f ms" % _ms(t_boot))
	var gaps: Array[float] = []
	var last := Time.get_ticks_usec()
	var t0 := Time.get_ticks_usec()
	main.title.buttons[route].pressed.emit()
	var ready_ms := -1.0
	for i in 2000:
		await process_frame
		var now := Time.get_ticks_usec()
		gaps.append((now - last) / 1000.0)
		last = now
		if ready_ms < 0.0 and _arrived(route) and root.get_node_or_null("LoadingJump") == null:
			ready_ms = _ms(t0)
			for j in 10: # a few frames at the destination (first draws, shader compiles)
				await process_frame
				now = Time.get_ticks_usec(); gaps.append((now - last) / 1000.0); last = now
			break
	var g := gaps.duplicate()
	g.sort()
	print("loading-profile: route %s shown after %.1f ms (press -> destination on screen, loading view included); %d frames, longest gap %.1f ms, median %.1f ms, frames over 50 ms: %d" % [
		route, ready_ms, g.size(), g[-1], g[g.size() / 2], g.filter(func(x: float) -> bool: return x > 50.0).size()])
	print("loading-profile: gaps %s" % [gaps.map(func(x: float) -> String: return "%.0f" % x)])
	if current_scene != null and current_scene.has_method("return_to_menu"):
		current_scene.auto = false


func _arrived(route: String) -> bool:
	var s := current_scene
	if route == "map":
		var m := root.find_children("*", "GalaxyMap", true, false)
		return m.size() == 1 and m[0].sim != null
	return s != null and s.get("ready_ok") == true and (route == "ship" or s.get("solar_tour") != null)
