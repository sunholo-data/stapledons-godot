extends SceneTree
## Real bridge + map + body renderer regression for Mark's free-nav defects.
var passed := 0
var failures := 0
func check(label: String, ok: bool) -> void:
	print("%s %s" % ["ok" if ok else "FAIL", label])
	if ok: passed += 1
	else: failures += 1
func _initialize() -> void: run.call_deferred()
func earth(world: Dictionary) -> Dictionary:
	for body: Dictionary in world.system.bodies:
		if body.id == "earth": return body
	return {}
func run() -> void:
	var map: GalaxyMap = load("res://ui/galaxy_map.tscn").instantiate()
	map.auto_tick = false
	root.add_child(map)
	check("map loads visible ISM with a checked discoverable control", map.ism_layer.visible and map.ism_toggle.button_pressed and map.ism_toggle.visible and map.ism_legend.visible)
	check("cloud depth construction guides hidden by default", not map.ism_layer.show_depth_guides and not map.ism_depth_guides.button_pressed)
	map.ism_depth_guides.button_pressed=true
	check("depth construction guides explicitly optional", map.ism_layer.show_depth_guides)
	map.ism_depth_guides.button_pressed=false
	var pending: Dictionary = map._pending.duplicate(true)
	map.ism_toggle.button_pressed = false
	check("visible control synchronizes layer and legend", not map.ism_layer.visible and not map.ism_legend.visible)
	var key := InputEventKey.new(); key.keycode = KEY_D; key.pressed = true
	map._unhandled_input(key)
	check("D synchronizes the visible ISM control", map.ism_layer.visible and map.ism_toggle.button_pressed and map.ism_legend.visible)
	map.local_ism_button.pressed.emit()
	check("Local ISM frames Sol at30ly and changes no navigation intent", map.dist == 30. and map._pending == pending and map._queue.is_empty())
	var sim := SimBridge.new()
	map.sim = sim
	sim.world = {"system":{"bodies":[
		{"id":"sun","name":"Sun","kind":"star","host":"","rel_km":{"x":100.,"y":0.,"z":0.}},
		{"id":"earth","name":"Earth","kind":"planet","host":"","visitable":true,"rel_km":{"x":200.,"y":0.,"z":0.}},
		{"id":"mars","name":"Mars","kind":"planet","host":"","visitable":true,"rel_km":{"x":300.,"y":0.,"z":0.}},
		{"id":"moon","name":"Moon","kind":"moon","host":"earth","visitable":true,"rel_km":{"x":400.,"y":0.,"z":0.}}]}}
	map._refresh_system_list()
	var ids := map.system_ids.duplicate()
	var buttons: Array = map.system_box.get_child(1).get_children()
	var earth_tip: String = map._system_buttons.earth.tooltip_text
	check("fixed Solar inventory hierarchy groups Earth and Moon", ids == ["sun","earth","moon","mars"])
	sim.world.system.bodies[1].rel_km.x = 500.
	map._refresh_system_list()
	check("changing distances keeps button identities and order", map.system_ids == ids and map.system_box.get_child(1).get_children() == buttons)
	check("stable buttons still refresh current distance", map._system_buttons.earth.tooltip_text != earth_tip)
	map._system_buttons.earth.pressed.emit()
	check("retained Earth button remains bound to Earth's stable ID", map._pending.get("target",{}).get("id","") == "earth")
	map._pending = {}
	map.sim = null
	sim.want_minor = SimBridge.ISM_MINOR
	check("new explicit free navigation session", sim.start() and sim.new_game(42,"free_nav",false,{"stop_rule":54.,"standoff_au":1000.}))
	if sim.world.get("journey",{}).is_empty(): sim.stop(); quit(1); return
	map.live_pacing = true
	map.attach(sim)
	check("initial velocity is genuinely zero", sim.world.ship.beta == 0. and sim.world.ship.phase == "at_rest")
	for id: String in ["sun","earth","mars"]:
		map.plan_body(id)
		check("plans %s without hidden collision exemptions" % id, map.tick() and sim.last_refused.is_empty() and map.journey_state() == "planned")
	map.plan_body("earth"); map.tick()
	check("Earth stop commit ritual remains available", map.open_commit_dialog() and map.hold_commit(GalaxyMap.HOLD_S) and map.tick())
	for i in 1600:
		if map.journey_state() == "arrived" or not map.tick(): break
	check("Earth stop reaches arrival at rest", map.journey_state() == "arrived" and sim.world.ship.beta == 0.)
	var sv := SystemView.new(); sv.setup(null,false); sv.set_view(.001,600.); root.add_child(sv)
	var tau0: float = sim.world.clock.tau
	var first := earth(sim.world)
	var d0 := Planets.length64(Planets.world_of(first.rel_km))
	var angle0 := rad_to_deg(2. * Planets.angular_radius(first.radius_km,d0))
	var retained := true
	for i in 1200: # exactly60 wall seconds at20Hz; orbital ephemeris keeps advancing.
		retained = map.tick() and retained
		if i % 20 == 0:
			var e := earth(sim.world)
			var d := Planets.length64(Planets.world_of(e.rel_km))
			sv.update(sim.world.system,1.)
			retained = retained and d > e.radius_km * 1.1 and sv.drawn_discs.has("earth")
	check("idle display reports real-time pacing",absf(map.pacing.rate*31557600.-1.)<1e-9)
	var last := earth(sim.world)
	sv.update(sim.world.system,1.)
	var d1 := Planets.length64(Planets.world_of(last.rel_km))
	var angle1 := rad_to_deg(2. * Planets.angular_radius(last.radius_km,d1))
	check("live idle advances60 seconds instead of60 days", absf((float(sim.world.clock.tau)-tau0)*31557600.-60.) < .001)
	check("Earth remains outside surface and rendered after60s with real orbital evolution", retained and absf(angle0-30.) < .1 and absf(angle1-angle0) < 3.)
	check("applied renderer direction uses current authoritative rel_km", sv.last_system == sim.world.system)
	map.plan_body("mars")
	check("can plan another legitimate stop after arrival", map.tick() and sim.last_refused.is_empty() and map.journey_state() == "planned")
	map.paused = true
	var paused_tau: float = sim.world.clock.tau
	map.plan_body("sun")
	check("paused planning still sends intents without moving simulation time", map.tick() and sim.last_refused.is_empty() and sim.world.clock.tau == paused_tau and map.journey_state() == "planned")
	check("pause display reports zero pacing",map.pacing.rate==0.)
	check("paused commit resumes automatically", map.open_commit_dialog() and map.hold_commit(GalaxyMap.HOLD_S) and map.tick() and not map.paused and map.journey_state() == "committed")
	map.paused = true
	paused_tau = sim.world.clock.tau
	check("committed presentation pause holds time without cancelling journey", map.tick() and sim.world.clock.tau == paused_tau and map.journey_state() == "committed")
	check("committed refusal explains autopilot ownership", GalaxyMap.refusal_text("committed").contains("autopilot"))
	check("distance refusal says already inside stop or invalid speed", GalaxyMap.refusal_text("out_of_range").contains("stop"))
	sim.stop(); sv.queue_free(); map.queue_free(); await process_frame
	print("free-nav-recovery: %d passed, %d failures" % [passed,failures]); quit(1 if failures else 0)
