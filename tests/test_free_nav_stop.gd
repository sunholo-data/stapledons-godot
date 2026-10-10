extends SceneTree
## Free-navigation stop, the real flow (Mark, 2026-10-08): open navigation, pick a star,
## hold to commit, fly the AILANG leg to arrival, then the HUD says where the ship is
## and I offers the destination star with its card. Barnard's Star is keyed "Gaia DR3 n"
## in the catalogue but the bare source number in the sky tiers; before the fix I never
## offered it (nor any Gaia-identified star).
var passed := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	print("%s %s" % ["ok" if ok else "FAIL", label])
	if ok: passed += 1
	else: failures += 1
func _initialize() -> void: _run.call_deferred()
func fly(demo: Node, id: String, from_name: String) -> void:
	demo.open_navigation() # the helm (R1-SHIP-UI: outside it the map plans nothing)
	var map = demo.journey_map
	check(map.preselect(map.index_of(id)) and demo.journey_tick(), "navigation preselects " + id)
	check(map.open_commit_dialog() and map.hold_commit(GalaxyMap.HOLD_S) and demo.journey_tick() and demo.live_journey, "the hold commits the leg to " + id)
	check(demo.leg_from == from_name, "the leg leaves from %s (%s)" % [from_name, demo.leg_from])
	for i in 3000:
		if not demo.journey_tick() or not demo.live_journey: break
	check(map.journey_state() == "arrived" and demo.sky.beta == 0.0, "arrived at " + id)
func body_of(demo: Node, id: String) -> Dictionary:
	for b: Dictionary in demo.sky_world.get("system", {}).get("bodies", []):
		if b.id == id: return b
	return {"radius_km": 0.0, "rel_km": {"x": 0.0, "y": 0.0, "z": 0.0}}
func fly_body(demo: Node, id: String, from_name: String) -> void:
	demo.open_navigation() # the helm
	var map = demo.journey_map
	map.plan_body(id); demo.journey_tick()
	check(map.journey_state() == "planned" and map.target_name() != "" and map.status_text().find("refused") < 0, "plans the in-system stop at %s: %s" % [id, map.status_text()])
	check(map.open_commit_dialog() and map.hold_commit(GalaxyMap.HOLD_S) and demo.journey_tick() and demo.live_journey, "the hold commits the body plan to %s (%s)" % [id, map.status_text()])
	check(demo.leg_from == from_name, "the leg leaves from %s (%s)" % [from_name, demo.leg_from])
	for i in 4000:
		if not demo.journey_tick() or not demo.live_journey: break
	check(map.journey_state() == "arrived", "arrived at " + id)
func _run() -> void:
	var demo: Node = load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options = {"background": false}
	root.add_child(demo); await process_frame
	demo.auto = false; demo.journey_auto_tick = false
	demo.open_navigation(); await process_frame
	check(demo.journey_map != null, "navigation opens")
	if demo.journey_map == null: quit(1); return
	var barnard := "Gaia DR3 4472832130942575872"
	fly(demo, barnard, "Earth")
	var hud: String = demo.distances_text(demo.sky_world, null, demo.star_identification.info.names, demo.leg_from)
	# D-58: Barnard's Star has no measured radius; the sim infers one from its catalogue row
	# (V, distance, Teff; sunholo/relativity 0.11.0) and stops where it looks 4.4 deg across.
	var bb := body_of(demo, "cat:" + barnard)
	var b_km := Planets.length64(Planets.world_of(bb.rel_km))
	var b_deg := rad_to_deg(2.0 * Planets.angular_radius(bb.radius_km, b_km))
	check(bb.get("status", "") == "inferred" and bb.get("catalogue_id", "") == barnard and absf(bb.radius_km / 695700.0 - 0.19) < 0.02 and absf(b_deg - 4.37) < 0.05, "Barnard's Star is a finite star with an inferred radius %.3f R_sun, %.2f deg across" % [bb.radius_km / 695700.0, b_deg])
	check(hud.begins_with("At Barnard's Star 0.02") and hud.contains(" AU · from Earth 5.9"), "HUD at the stop: " + hud)
	demo._process(0.0)
	check(demo.ship_hud.distance.text.contains("At Barnard's Star") and demo.ship_hud.where.text.contains("Barnard's Star"), "the status strip carries the stop line (R1-SHIP-UI)")
	demo.look_direction("forward"); await process_frame
	var ident = demo.star_identification
	ident.set_held(true); ident.update_candidates()
	var hit: Array = ident.candidates.filter(func(c): return c.id == "body:cat:" + barnard)
	check(hit.size() == 1 and ident.candidates.filter(func(c): return c.id == barnard).is_empty(), "I offers the destination as its finite body, not the hidden catalogue point (%d candidates)" % ident.candidates.size())
	if hit.size() == 1:
		ident.inspect(hit[0].id)
		var text: String = ident.content.get_child(0).text if ident.content.get_child_count() > 0 else ""
		check(ident.card.visible and text.contains("Barnard's Star") and text.contains("Radius inferred, not measured") and text.contains("inferred radius: R = sqrt(L)") and text.contains("Catalogue: Barnard's Star"), "its card says the radius is inferred: " + text.replace("\n", " | "))
	ident.set_held(false); ident.close_card()
	# A second leg from the stop: D-54 (Mark, 2026-10-08) stops at alpha Cen A where it looks
	# 2 atan(tan 5 deg sqrt(1.22)) = 11 deg across (0.059 AU), not 1,000 AU; the HUD names the stop it left.
	fly(demo, "CNS5:3627", "Barnard's Star")
	hud = demo.distances_text(demo.sky_world, null, demo.star_identification.info.names, demo.leg_from)
	check(hud.begins_with("At Alpha Centauri A 0.059 AU · from Barnard's Star 6.") and hud.contains("· from Earth 4.3"), "HUD at the D-54 alpha Cen A stop: " + hud)
	var a_body := body_of(demo, "acen-a")
	var a_deg := rad_to_deg(2.0 * Planets.angular_radius(a_body.radius_km, Planets.length64(Planets.world_of(a_body.rel_km))))
	check(absf(a_deg - 11.05) < 0.1, "alpha Cen A fills %.2f deg (D-54: 11.05)" % a_deg)
	demo.look_direction("forward"); await process_frame
	ident.set_held(true); ident.update_candidates()
	var a_c: Array = ident.candidates.filter(func(c): return c.id == "body:acen-a")
	check(not a_c.is_empty(), "alpha Cen A is inspectable at its stop")
	if not a_c.is_empty():
		var at: Array = ident.at_point(a_c[0].point)
		check(at.size() == 1 and at[0].id == "body:acen-a", "a click on A's centre picks A, not B (%s)" % [at.map(func(c): return c.id)])
	ident.set_held(false)
	# Part 3: the map lists this system's bodies; pick B and fly there with the body planner.
	demo.open_navigation() # the helm (R1-SHIP-UI)
	var map = demo.journey_map
	map.refresh()
	check(map.system_ids.has("acen-a") and map.system_ids.has("acen-b") and not map.system_ids.has("earth"), "the map lists alpha Cen's stars, not Sol's planets: %s" % [map.system_ids])
	# A body plan the sim refuses when it is recreated at commit is reported, never sent stale.
	map.plan_body("acen-b"); demo.journey_tick()
	var good_plan: Dictionary = map._last_plan.duplicate(true)
	map._last_plan["cruise_phi"] = 0.0 # below every bound: the recreated plan is refused
	var before_id := int(demo.journey_sim.world.journey.plan_id)
	check(map.open_commit_dialog() and map.hold_commit(GalaxyMap.HOLD_S) and demo.journey_tick(), "the refused re-plan tick runs")
	check(map.journey_state() == "planned" and not demo.live_journey and map.status_text().contains("refused: out_of_range") and not map.status_text().contains("stale_plan"), "a refused re-plan is reported, no stale commit: " + map.status_text())
	map._last_plan = good_plan
	fly_body(demo, "acen-b", "Alpha Centauri A")
	hud = demo.distances_text(demo.sky_world, null, demo.star_identification.info.names, demo.leg_from)
	check(hud.begins_with("At Alpha Centauri B 0.0") and hud.contains("from Alpha Centauri A"), "HUD at the in-system B stop: " + hud)
	# Return to Sol: the M4.4 home plan now stops beside Earth (D-54: 30 deg across).
	# Sol is clickable on the map (drawn at the origin; not a catalogue row).
	demo.open_navigation() # the helm
	map.centre_on_ship(); map.pivot = Vector3.ZERO; map.dist = 30.0; map._update_camera()
	var sol_px: Vector2 = map.camera.unproject_position(Vector3.ZERO)
	check(map.pick(sol_px) == GalaxyMap.SOL_PICK, "a click on Sol picks home (pick %d)" % map.pick(sol_px))
	for pressed in [true, false]:
		var click := InputEventMouseButton.new(); click.button_index = MOUSE_BUTTON_LEFT; click.pressed = pressed; click.position = sol_px
		map._unhandled_input(click)
	demo.journey_tick()
	check(map.target_name() == "Sol" and map.home_highlight and map.selected_index == -1, "clicking Sol plans home: " + map.title_text())
	map.plan_home(); demo.journey_tick()
	check(map.target_name() == "Sol" and map.home_highlight and not map.home_button.disabled, "Return to Sol plans home")
	check(map.open_commit_dialog() and map.hold_commit(GalaxyMap.HOLD_S) and demo.journey_tick() and demo.live_journey, "the hold commits the trip home: " + map.status_text())
	for i in 3000:
		if not demo.journey_tick() or not demo.live_journey: break
	check(map.journey_state() == "arrived", "arrived home")
	var earth := body_of(demo, "earth")
	var e_km := Planets.length64(Planets.world_of(earth.rel_km))
	check(absf(e_km - 24643.2) < 200.0, "home is Earth's D-54 stop: %.0f km (24,643)" % e_km)
	hud = demo.distances_text(demo.sky_world, null, demo.star_identification.info.names, demo.leg_from)
	check(hud.begins_with("At Earth 24,") and hud.contains("from Alpha Centauri B 4.") and not hud.contains("from Earth"), "HUD at home: " + hud)
	check(demo.journey_sim.world.consequence.get("news_age_years", -1.0) < 0.001, "news at Earth is fresh")
	var earth_card: String = load("res://ui/body_info.gd").text(earth)
	check(earth_card.contains("Synchronous orbit: 35,786 km above the surface"), "Earth's card has its geostationary orbit: " + earth_card.replace("\n", " | "))
	var moon_card: String = load("res://ui/body_info.gd").text(body_of(demo, "moon"))
	check(moon_card.contains("Synchronous orbit: none. Moon is tidally locked to Earth"), "the Moon's card says none, tidally locked")
	var venus_card: String = load("res://ui/body_info.gd").text(body_of(demo, "venus"))
	check(venus_card.contains("Synchronous orbit: none. It turns once in 243.02 days") and venus_card.contains("Hill sphere"), "Venus's card says none, too slow: " + venus_card.replace("\n", " | "))
	map.refresh()
	check(map.system_ids.has("jupiter") and map.system_ids.has("moon") and map.system_ids.has("sun") and map.system_ids.has("saturn"), "the Solar System is around the ship: %d bodies" % map.system_ids.size())
	fly_body(demo, "saturn", "Earth")
	var sat := body_of(demo, "saturn")
	var s_km := Planets.length64(Planets.world_of(sat.rel_km))
	check(absf(s_km - 1.1 * 140612.0) < 200.0 and s_km > 140612.0, "Saturn's stop clears its rings: %.0f km (F ring edge 140,612)" % s_km)
	fly_body(demo, "jupiter", "Saturn")
	var j := body_of(demo, "jupiter")
	var j_km := Planets.length64(Planets.world_of(j.rel_km))
	var j_deg := rad_to_deg(2.0 * Planets.angular_radius(j.radius_km, j_km))
	check(absf(j_deg - 83.8) < 0.3, "Jupiter fills %.1f deg from %.0f km (D-54: 84)" % [j_deg, j_km])
	hud = demo.distances_text(demo.sky_world, null, demo.star_identification.info.names, demo.leg_from)
	check(hud.begins_with("At Jupiter 10") and hud.contains("from Saturn"), "HUD at Jupiter: " + hud)
	demo.queue_free(); await process_frame
	print("free-nav-stop: %d passed, %d failures" % [passed, failures]); quit(1 if failures else 0)
