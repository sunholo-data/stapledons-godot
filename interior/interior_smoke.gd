class_name InteriorSmoke
extends RefCounted
## M4.2 AC14 smoke half: the slice runs on a bundle (make m4-smoke BUNDLE=dir; headless; also
## run from the exported .app by make export-smoke, so it lives in interior/, which exports).
## The captain walks to a navigation console on the bundle's WALK_ surface while the sim
## ticks, the console opens the galaxy map, alpha Cen A is committed through the hold, the map
## closes and the interior's sky follows the sim (heading, beta, cam x ship_basis) through the
## cruise to the arrival; the Archive opens. The recorded input log (--record) must show the
## walking phase sent no intents: the avatar never enters the sim.

const DT := 1.0 / 20.0
const ALPHA_CEN_A := "CNS5:3627"

var fails := PackedStringArray()


func need(ok: bool, what: String) -> void:
	if not ok:
		fails.append(what)
		print("m4-smoke: FAIL %s" % what)


func run(main: Node, it: Interior, map: GalaxyMap, sim: SimBridge) -> int:
	var b := it.bundle
	print("m4-smoke: bundle %s, placeholder %s, %d walk triangles, %d spawns, %d interactables" % [b.dir, b.placeholder, it.walk.triangle_count(), it.walk.spawns.size(), it.walk.interactables.size()])
	need(it.environments_outside_subviewports().is_empty(), "one tonemap: no WorldEnvironment outside the SubViewports")
	need(it.tag_label.visible == b.placeholder, "placeholder tag follows the bundle")
	var nav := ""
	for n: String in it.walk.interactables:
		if n.begins_with("console_navigation") and (nav == "" or n < nav):
			nav = n
	need(nav != "", "a navigation console in INTERACT_")
	if nav == "":
		return _done(sim)
	# walk there while the clock runs; the walking phase must send no intents (one tick first
	# sends the map's preselected alpha Cen plan, which is not the avatar's)
	it.tick()
	var lines0 := _record_lines(sim)
	var route := it.walk.path(it.avatar_pos, it.walk.interactables[nav].get_center())
	need(route.size() > 1, "a walkable route to %s" % nav)
	var steps := 0
	var i := 0
	while it.nearest_interactable() != nav and steps < 4000 and i < route.size():
		if Vector2(route[i].x - it.avatar_pos.x, route[i].z - it.avatar_pos.z).length() < 0.08:
			i += 1
			continue
		it.walk_toward(route[i], DT)
		it.tick()
		steps += 1
	var lines1 := _record_lines(sim)
	need(it.nearest_interactable() == nav, "the captain reaches %s (%d steps)" % [nav, steps])
	need(it.walk.is_walkable(it.avatar_pos), "the captain ends on WALK_")
	var walk_intents := _intents_between(sim, lines0, lines1)
	need(sim.record_path == "" or walk_intents == 0, "walking sent no intents to the sim (%d)" % walk_intents)
	print("m4-smoke: walked to %s in %d steps (%.1f s), captain at %s, %d input lines, %d intents while walking" % [nav, steps, steps * DT, it.avatar_pos, lines1 - lines0, walk_intents])
	# the console opens the map; commit alpha Cen A
	need(it.interact() == "map" and it.map_open and map.is_inside_tree(), "the navigation console opens the galaxy map")
	map.select(map.index_of(ALPHA_CEN_A))
	it.tick()
	need(map.open_commit_dialog(), "a plan to commit (%s)" % sim.last_refused)
	map.hold_commit(GalaxyMap.HOLD_S + 0.05)
	it.tick()
	need(map.journey_state() == "committed", "commit accepted (%s)" % map.journey_state())
	it.close_map()
	need(not it.map_open and not map.is_inside_tree() and it.layer_nodes()["sky"].visible, "the map closes back to the interior")
	var cruise := false
	var n := 0
	while map.journey_state() == "committed" and n < 20000:
		it.tick()
		n += 1
		if not cruise and sim.world["ship"]["phase"] == "cruising":
			cruise = true
			_check_sky(it, sim)
	need(cruise, "the ship reached cruise")
	need(map.journey_state() == "arrived", "arrived at alpha Cen A after %d ticks (%s)" % [n, map.journey_state()])
	_check_sky(it, sim)
	it.open_archive("log")
	need(it.archive.visible and it.archive_text.text.contains("Legacy log"), "the Archive opens on the legacy log")
	it.open_archive("codex") # The real flight also unlocks the ISM Archive entry.
	var open_rows: int = it.codex.entry_rows().values().filter(func(b: Button) -> bool: return not b.disabled).size()
	need(it.codex.panel.visible and not it.archive.visible and it.codex.entry_rows().size() == 11 and open_rows == 8, "the codex tab shows eleven entries, %d open from the sim's archive.unlocked" % open_rows)
	return _done(sim)


## The interior's sky follows the sim: heading, beta and the camera = cam x ship_basis.
func _check_sky(it: Interior, sim: SimBridge) -> void:
	var s: Dictionary = sim.world["ship"]
	var h := PackedFloat64Array([s["heading"]["x"], s["heading"]["y"], s["heading"]["z"]])
	need(it.sky.heading_gal == h, "sky heading = the sim's")
	need(it.sky.beta == s["beta"], "sky beta = the sim's")
	var want := ShipFrame.sky_camera(h, it.bundle.camera)
	var f: PackedFloat64Array = want["forward"]
	var got := it.sky.camera.view_dir()
	var fw := SkyFrame.to_world64(f)
	var err := Vector3(fw[0], fw[1], fw[2]).distance_to(got)
	need(err < 1e-6, "sky camera forward = cam x ship_basis (error %s)" % err)
	print("m4-smoke: %s beta %.6f, sky camera forward error %s, glow pole %s" % [s["phase"], s["beta"], String.num_scientific(err), it.sky.glow_pole])


func _record_lines(sim: SimBridge) -> int:
	if sim.record_path == "":
		return 0
	return FileAccess.get_file_as_string(sim.record_path).count("\n")


func _intents_between(sim: SimBridge, a: int, b: int) -> int:
	if sim.record_path == "":
		return 0
	var lines := FileAccess.get_file_as_string(sim.record_path).split("\n")
	var count := 0
	for i in range(a, mini(b, lines.size())):
		var m: Variant = JSON.parse_string(lines[i])
		if m is Dictionary and m.get("intents") is Array:
			count += (m["intents"] as Array).size()
	return count


func _done(sim: SimBridge) -> int:
	sim.stop()
	if fails.is_empty():
		print("m4-smoke: OK")
		return 0
	print("m4-smoke: FAILED (%d): %s" % [fails.size(), "; ".join(fails)])
	return 1
