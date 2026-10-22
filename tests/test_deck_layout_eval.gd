extends SceneTree
## R2-DECK-LAYOUT DL0 (design_docs/planned/r2/deck-layout.md §D4, AC1, ledger D-95):
## make deck-layout-eval-test.
##   positive control  the pinned grounded-bridge-v2 export (build/ship-baseline, make ship-baseline)
##                     reproduces the §D4 "today" numbers exactly, and fails what the plan says it
##                     fails (spawn-open, near-field, faces-bow, zoom-pole); it is pinned, so the
##                     control holds after DL1 replaces the shipped GLB
##   layout A          applied in-engine on the baseline, it passes every threshold
##   negative controls layout A plus one seeded defect fails with that metric's ID: a station
##                     turned to face the stern (faces-bow), a box on the spawn's bow line
##                     (spawn-open), a wall at eye height on the Bow pole line (pole-ray), a use point
##                     in the mast's shadow (station-body)
##   layout files      fixture boxes outside a test are refused
##   DL2 props         the dressed heroes load from bridge_props.glb, once, inked, opaque, unlit
## Fixtures: tests/fixtures/deck_layout/a_*.json.

const BASELINE := "res://build/ship-baseline"
const A := "res://art/deck-layout-v2/bow_a.json"
const FIX := "res://tests/fixtures/deck_layout/"
var failures := 0
var passes := 0
var t: Dictionary


func check(label: String, ok: bool) -> void:
	if ok:
		passes += 1
	else:
		failures += 1
	print("%s %s" % ["ok" if ok else "FAIL", label])


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	t = JSON.parse_string(FileAccess.get_file_as_string("res://art/deck-layout-v2/thresholds.json"))
	check("baseline fetched (make ship-baseline): %s/ship.glb" % BASELINE, FileAccess.file_exists(BASELINE + "/ship.glb") and FileAccess.get_sha256(BASELINE + "/ship.glb") == "9da74077d72d8132970063dbf7c27eb14bdb52286fecbd02f4ae0149fc0344fa")
	await test_positive()
	await test_a()
	await test_negative("a_faces_stern", "faces-bow")
	await test_negative("a_spawn_box", "spawn-open")
	await test_negative("a_pole_box", "pole-ray")
	await test_negative("a_station_shadow", "station-body")
	await test_props()
	check("a layout with fixture boxes is refused outside a test", not DeckLayout.validate(DeckLayout.load_layout(FIX + "a_pole_box.json")).is_empty())
	print("deck-layout-eval-test: %d passed, %d failures" % [passes, failures])
	quit(1 if failures else 0)


## DL2 (§D5, §D5a): the dressed heroes ship in bridge_props.glb (manifest assets.props), once each
## (their blockout copies left ship.glb), painted, opaque, never emissive (no light baked or painted:
## the spire and the star light them live), each surface carrying the ink outline as its next pass.
func test_props() -> void:
	var demo: Node = load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options = {"size": Vector2i(1280, 720), "sky_state": "rest"}
	root.add_child(demo)
	await process_frame
	var props: Node = demo.get("props_visual")
	check("DL2: the demo loads bridge_props.glb beside ship.glb (%s)" % demo.manifest.assets.get("props", "none"), props != null and props.get_parent() == demo.geometry)
	if props == null:
		demo.queue_free()
		return
	var heroes := ["console_navigation_0", "console_navigation_1", "console_navigation_2", "captain_chair"]
	var ship_copies := heroes.filter(func(n: String) -> bool: return demo.geometry.get_child(0).find_child(n, true, false) != null)
	var in_props := heroes.filter(func(n: String) -> bool: return props.find_child(n, true, false) != null)
	check("DL2: the heroes are in bridge_props.glb (%d of 4) and no longer in ship.glb (%s)" % [in_props.size(), ship_copies], in_props.size() == 4 and ship_copies.is_empty())
	var surfaces := 0
	var inked := 0
	var lit := 0
	var opaque := true
	var stack: Array = [props]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D and n.mesh != null and not StapledonStyle.is_card(n.material_override): # D-106: the painted frond cards carry their ink in the painting
			for i in n.mesh.get_surface_count():
				# R2-BRIDGE-STYLE S2: the override is the toon material (its next_pass the ink); the
				# painted source material (the GLB's) carries emission and transparency.
				var m: Material = n.get_surface_override_material(i)
				var src := n.mesh.surface_get_material(i) as BaseMaterial3D
				surfaces += 1
				if m != null and m.next_pass is ShaderMaterial:
					inked += 1
				if src != null and src.emission_enabled:
					lit += 1
				if src != null and src.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
					opaque = false
		stack.append_array(n.get_children())
	check("DL2: every hero surface (%d) is inked (%d), opaque, and none emits (%d)" % [surfaces, inked, lit], surfaces > 0 and inked == surfaces and lit == 0 and opaque)
	check("DL2: the stations still find their meshes (ShipConsoles: navigation %d meshes, chair present)" % demo.consoles.stations.navigation.meshes.size(), demo.consoles.stations.navigation.meshes.size() == 3)
	# DL3 (§D5, sprint DL3): the rest of the heroes join them, by texture set (one shared painted
	# atlas per set); the deck surface and the spire stay in ship.glb (the styling pass, D-97).
	var dl3 := {"desks": ["console_decision_0", "console_decision_1", "console_decision_2", "console_decision_3", "v2_desk_props_00", "v2_desk_props_03"],
		"rail": ["rim_rail_00", "rim_rail_31", "v2_rail_lamp_00", "v2_rail_lamp_15"], # the rim fronds became painted cards (D-106; dressing-test)
		"archive": ["archive_terminal", "v2_archive_detail_00", "archive_shrine_ribs", "v2_spire_vents_00"],
		"lift": ["Lift guide", "Lift guide_001", "Guardrail 82", "Guardrail 82_002"],
		"floor": ["v2_bench_detail_00", "v2_bench_detail_03", "watch_bench_0", "watch_bench_3", "v2_conduit_00", "v2_conduit_06"]}
	for set_id: String in dl3:
		var names: Array = dl3[set_id]
		var here := names.filter(func(n: String) -> bool: return props.find_child(n, true, false) != null)
		var left := names.filter(func(n: String) -> bool: return demo.geometry.get_child(0).find_child(n, true, false) != null)
		var mats := {}
		for n: String in here:
			var mi := props.find_child(n, true, false) as MeshInstance3D
			if mi != null and mi.mesh != null:
				mats[mi.mesh.surface_get_material(0).resource_name] = true
		check("DL3 %s: in bridge_props.glb (%d of %d), gone from ship.glb (%s), one painted set (%s)" % [set_id, here.size(), names.size(), left, mats.keys()], here.size() == names.size() and left.is_empty() and mats.size() == 1)
	for n: String in ["bridge_floor_top82", "spire_needle"]:
		check("DL3: %s stays in ship.glb" % n, demo.geometry.get_child(0).find_child(n, true, false) != null)
	var occ := demo.get_tree().get_nodes_in_group(CameraDirector.OCCLUDER_GROUP).filter(func(x: Node) -> bool: return props.is_ancestor_of(x))
	check("DL3: the props' foreground layer still fades (views.json occluders: %d prop meshes grouped, shrine, terminal and fronds among them)" % occ.size(), occ.any(func(x: Node) -> bool: return String(x.name).contains("shrine_ribs")) and occ.any(func(x: Node) -> bool: return String(x.name).contains("archive_terminal")) and occ.filter(func(x: Node) -> bool: return String(x.name).contains("rim_frond")).size() == 10)
	demo.queue_free()
	await process_frame


func ids(f: PackedStringArray) -> Array:
	return Array(f).map(func(x: String) -> String: return x.get_slice(":", 0))


func test_positive() -> void:
	var r := await DeckLayoutEval.score(root, BASELINE)
	if not r.errors.is_empty():
		check("positive control builds: %s" % r.errors, false)
		return
	var m: Dictionary = r.metrics
	var st: Dictionary = m.stations
	var faces := st.keys().filter(func(k: String) -> bool: return st[k].faces_bow).size()
	var zoom := st.keys().filter(func(k: String) -> bool: return st[k].get("zoom_pole_in_frame", false)).size()
	check("positive control: today's Bow fades 530 (%d), pole blocked 0 (%d), head blocked 0 / 4 (%d / %d), body blocked on both sides 8 (%d)" % [m.bow.fade, m.bow.blocked.pole_ray, m.bow.blocked.captain, m.astern.blocked.captain, m.bow.body_both],
		m.bow.fade == 530 and m.bow.blocked.pole_ray == 0 and m.bow.blocked.captain == 0 and m.astern.blocked.captain == 4 and m.bow.body_both == 8)
	check("positive control: spawn open 0 m (%.2f) into the lift guard (%s), stations facing the bow 1 of 4 (%d), pole in the console zoom 0 of 3 (%d), captain 80.6 px (%.1f)" % [m.spawn.open_ahead_m, m.spawn.first_hit, faces, zoom, m.spawn.captain_px],
		is_zero_approx(m.spawn.open_ahead_m) and str(m.spawn.first_hit).begins_with("Guardrail") and faces == 1 and zoom == 0 and is_equal_approx(m.spawn.captain_px, 80.6))
	var f := ids(DeckBowMetrics.failures(m, t))
	check("positive control fails exactly spawn-open, near-field, faces-bow, zoom-pole (%s)" % [f], f == ["spawn-open", "near-field", "faces-bow", "zoom-pole"])


func test_a() -> void:
	var r := await DeckLayoutEval.score(root, BASELINE, A)
	if not r.errors.is_empty():
		check("layout A builds: %s" % r.errors, false)
		return
	var m: Dictionary = r.metrics
	var f := DeckBowMetrics.failures(m, t)
	check("layout A in-engine passes every §D4 threshold (fades %d, head %d / %d, spawn open %.2f m then %s, near %.3f / %.3f) %s" % [m.bow.fade, m.bow.blocked.captain, m.astern.blocked.captain, m.spawn.open_ahead_m, m.spawn.first_hit, m.spawn.near_bow.share, m.spawn.near_astern.share, f], f.is_empty())


func test_negative(name: String, id: String) -> void:
	var r := await DeckLayoutEval.score(root, BASELINE, FIX + name + ".json", true)
	if not r.errors.is_empty():
		check("negative control %s builds: %s" % [name, r.errors], false)
		return
	var f := DeckBowMetrics.failures(r.metrics, t)
	check("negative control %s fails %s (%s)" % [name, id, ids(f)], ids(f).has(id))
