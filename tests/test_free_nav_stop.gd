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
	var map = demo.journey_map
	check(map.preselect(map.index_of(id)) and demo.journey_tick(), "navigation preselects " + id)
	check(map.open_commit_dialog() and map.hold_commit(GalaxyMap.HOLD_S) and demo.journey_tick() and demo.live_journey, "the hold commits the leg to " + id)
	check(demo.leg_from == from_name, "the leg leaves from %s (%s)" % [from_name, demo.leg_from])
	for i in 3000:
		if not demo.journey_tick() or not demo.live_journey: break
	check(map.journey_state() == "arrived" and demo.sky.beta == 0.0, "arrived at " + id)
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
	check(hud.begins_with("At Barnard's Star 1000") and hud.contains(" AU · from Earth 5.9"), "HUD at the stop: " + hud)
	check(demo.hud_text("bridge", "").contains("At Barnard's Star"), "the live HUD carries the stop line")
	demo.look_direction("forward"); await process_frame
	var ident = demo.star_identification
	ident.set_held(true); ident.update_candidates()
	var hit: Array = ident.candidates.filter(func(c): return c.id == barnard)
	check(hit.size() == 1, "I offers the destination star by its catalogue id (%d candidates)" % ident.candidates.size())
	if hit.size() == 1:
		var click := InputEventMouseButton.new(); click.button_index = MOUSE_BUTTON_LEFT; click.pressed = true; click.position = hit[0].point
		var picked: Array = ident.at_point(hit[0].point)
		if picked.size() > 1: ident.inspect(barnard)
		else: ident.handle_input(click)
		var text: String = ident.content.get_child(0).text if ident.content.get_child_count() > 0 else ""
		check(ident.selected_id == barnard and ident.card.visible and text.contains("Barnard's Star") and text.contains("5.96"), "its card opens: " + text.replace("\n", " | "))
	ident.set_held(false); ident.close_card()
	# A second leg from the stop: the HUD names the stop it left.
	fly(demo, "CNS5:3627", "Barnard's Star")
	hud = demo.distances_text(demo.sky_world, null, demo.star_identification.info.names, demo.leg_from)
	check(hud.begins_with("At Alpha Centauri A 1000 AU · from Barnard's Star 6.") and hud.contains("· from Earth 4.3"), "HUD at the second stop: " + hud)
	demo.look_direction("forward"); await process_frame
	ident.set_held(true); ident.update_candidates()
	check(not ident.candidates.filter(func(c): return c.id == "body:acen-a" or c.id == "CNS5:3627").is_empty(), "alpha Cen A is inspectable at its stop")
	var a: Array = ident.candidates.filter(func(c): return c.id == "body:acen-a")
	if not a.is_empty():
		var at: Array = ident.at_point(a[0].point)
		check(at.size() >= 1 and at[0].id == "body:acen-a", "a click on A's centre picks A, not the nearer B beside it (%s)" % [at.map(func(c): return c.id)])
	demo.queue_free(); await process_frame
	print("free-nav-stop: %d passed, %d failures" % [passed, failures]); quit(1 if failures else 0)
