extends SceneTree
## Headless galaxy-map test (M2.6a, design AC15 part) against the real sim:
## selection by catalogue index, the plan payload (float64 catalogue doubles,
## slider rapidity), the slider's range and default against the sim's own
## acceptance bounds, panel labels = formatted sim fields, the clock never
## pausing, target_selected and preselect, and screen-space picking in a fixed
## 800x600 viewport.
## Run:  godot --headless --path . --script tests/test_galaxy_map.gd

const ALPHA_CEN_A := 1 # stars.json index 1: "Gl 559", vmag 0.01 (index 2 is B, same id)

var failures := 0

func ok(name: String, cond: bool) -> void:
	if not cond: failures += 1
	print("  %s  %s" % ["ok  " if cond else "FAIL", name])

## Floats from IEEE-754 bits (the GDScript tokenizer misreads some literals).
func f64(bits: int) -> float:
	var b := PackedByteArray()
	b.resize(8)
	b.encode_s64(0, bits)
	return b.decode_double(0)

func bits_of(x: Variant) -> int:
	if typeof(x) != TYPE_FLOAT:
		return 0x7ff8dead0000beef
	var b := PackedByteArray()
	b.resize(8)
	b.encode_double(0, x)
	return b.decode_s64(0)

func same(a: Variant, b: Variant) -> bool:
	return bits_of(a) == bits_of(b)

func next_up(x: float) -> float: # x > 0
	return f64(bits_of(x) + 1)

func next_down(x: float) -> float:
	return f64(bits_of(x) - 1)

func new_map(vp: SubViewport) -> GalaxyMap:
	var sim := SimBridge.new()
	if not sim.start() or not sim.new_game(0, "sol", false):
		ok("sim session starts (%s)" % sim.last_error, false)
		return null
	var map: GalaxyMap = load("res://ui/galaxy_map.tscn").instantiate()
	map.auto_tick = false
	vp.add_child(map)
	map.load_catalogue("res://data/starmap/stars.json")
	map.attach(sim)
	return map

func plan_of(map: GalaxyMap) -> Dictionary:
	return map.sim.world.get("journey", {}).get("plan", {})

func row(map: GalaxyMap, field: String) -> Dictionary:
	for r in map.panel_rows():
		if r["field"] == field:
			return r
	return {}


func test_select_sends_catalogue_doubles(map: GalaxyMap) -> bool:
	var star: Dictionary = map.catalogue[ALPHA_CEN_A]
	ok("index 1 is alpha Cen A (Gl 559, vmag 0.01)", star["id"] == "Gl 559" and same(star["vmag"], 0.01))
	var intent := map.plan_intent(ALPHA_CEN_A)
	var t: Dictionary = intent["target"]
	ok("plan carries index and id", intent["k"] == "plan" and t["index"] == ALPHA_CEN_A and typeof(t["index"]) == TYPE_INT and t["id"] == "Gl 559")
	var p: Dictionary = t["pos"]
	ok("pos x, y, z are the parsed JSON doubles, bit for bit", same(p["x"], star["x"]) and same(p["y"], star["y"]) and same(p["z"], star["z"]))
	ok("pos y is not float32-rounded (-4.09 has no exact float32)", not same(p["y"], float(Vector3(0, star["y"], 0).y)))
	ok("plan carries the slider's cruise_phi", same(intent["cruise_phi"], map.cruise_phi))
	map.select(ALPHA_CEN_A)
	map.tick()
	var plan := plan_of(map)
	ok("sim planned alpha Cen A", map.sim.world["journey"]["state"] == "planned" and plan["target"]["index"] == ALPHA_CEN_A)
	var echo: Dictionary = plan["target"]["pos"]
	ok("sim echoes pos bit for bit", same(echo["x"], star["x"]) and same(echo["y"], star["y"]) and same(echo["z"], star["z"]))
	ok("distance is the catalogue-double distance (checkPlanGl559: 4.35667304258651)", same(plan["distance"], f64(0x40116d3bb2b51873)))
	return true


func test_default_and_range(map: GalaxyMap) -> bool:
	var phi099 := f64(0x40052c581997cd85) # 2.6466524123622457 = core_test phi099()
	ok("slider defaults to atanh 0.99 bit for bit", same(map.cruise_phi, phi099) and same(map.slider.value, phi099))
	var plan := plan_of(map)
	ok("sim echoes the default phi bit for bit", same(plan["cruise_phi"], phi099))
	ok("sim reads it as cruise_beta 0.99", same(plan["cruise_beta"], 0.99))
	ok("slider min = atanh 0.9 (core_test phi09())", same(map.slider.min_value, f64(0x3ff78e360604b32d)))
	ok("slider max = rapidityOfOneMinusBeta(1e-6) (core_test plPhiCap())", same(map.slider.max_value, f64(0x401d046eb8b8ab58)))
	# the endpoints are exactly the sim's acceptance bounds: accepted at, refused one ulp past
	for c in [[map.phi_min, "min"], [map.phi_max, "max"]]:
		map.set_cruise_phi(c[0])
		map.tick()
		ok("sim accepts the slider %s" % c[1], map.sim.last_refused.is_empty() and same(plan_of(map)["cruise_phi"], c[0]))
	map.set_cruise_phi(next_up(map.phi_max), false)
	map.tick()
	ok("one ulp above the slider max is refused out_of_range", map.sim.last_refused.size() == 1 and map.sim.last_refused[0]["reason"] == "out_of_range")
	ok("panel shows the sim's refusal", map.status_text().contains("out_of_range"))
	map.set_cruise_phi(next_down(map.phi_min), false)
	map.tick()
	ok("one ulp below the slider min is refused out_of_range", map.sim.last_refused.size() == 1 and map.sim.last_refused[0]["reason"] == "out_of_range")
	ok("slider value is clamped to its range", same(map.slider.value, map.phi_min))
	map.set_cruise_phi(phi099)
	map.tick()
	ok("back to 0.99c", same(plan_of(map)["cruise_phi"], phi099) and map.sim.last_refused.is_empty())
	ok("slider label is the sim's cruise_beta/cruise_gamma", map.speed_text() == GalaxyMap.speed_label(plan_of(map)))
	return true


func test_labels_are_sim_values(map: GalaxyMap) -> bool:
	var plan := plan_of(map)
	var rows := map.panel_rows()
	ok("panel has rows", rows.size() >= 16)
	var all_match := true
	for r in rows:
		var raw = GalaxyMap.field_value(map.sim.world, r["field"])
		if not same(r["raw"], raw) and r["raw"] != raw:
			all_match = false
			print("    raw mismatch %s" % r["field"])
		if r["text"] != GalaxyMap.format_row(r["field"], raw):
			all_match = false
			print("    text mismatch %s: %s" % [r["field"], r["text"]])
	ok("every row: raw = the sim field (bits), text = its formatting", all_match)
	ok("both clocks come first", rows[0]["field"] == "journey.plan.ship_years" and rows[1]["field"] == "journey.plan.earth_years")
	ok("then arrival, age on arrival, years left", rows[2]["field"] == "journey.plan.arrive_year" and rows[3]["field"] == "journey.plan.age_on_arrival" and rows[4]["field"] == "journey.plan.years_left")
	ok("crew-age lines read placeholder", rows[3]["label"].contains("placeholder") and rows[4]["label"].contains("placeholder"))
	ok("arrival reads 'Earth +x yr'", rows[2]["text"].begins_with("Earth +") and rows[2]["text"].ends_with(" yr"))
	for f in ["energy.boost_j", "energy.brake_j", "energy.drag_j", "energy.total_j", "energy.total_kg", "ism.load_w_m2", "ism.glow_w_m2", "ism.drag_n", "ism.hold_w", "cmb_forward_k", "boost_minutes"]:
		ok("panel shows %s" % f, not row(map, "journey.plan." + f).is_empty())
	print("    alpha Cen A (catalogue, d %.6f ly) 0.99c: %s | %s | %s | %s" % [plan["distance"], row(map, "journey.plan.ship_years")["text"],
		row(map, "journey.plan.earth_years")["text"], row(map, "journey.plan.boost_minutes")["text"], row(map, "journey.plan.energy.total_kg")["text"]])
	return true


## Design check row 2 (alpha Cen at 4.37 ly, 0.99c): the same formatting of
## the sim's reply reads 0.6227 ship-yr, 4.414 Earth-yr, 1.80 boost-min, 6.818 kg.
func test_check_row_digits(map: GalaxyMap) -> bool:
	map.plan_target({"index": ALPHA_CEN_A, "id": "Gl 559", "pos": {"x": 0.0, "y": 0.0, "z": -4.37}})
	map.tick()
	ok("check-row plan accepted", map.sim.last_refused.is_empty() and same(plan_of(map)["distance"], 4.37))
	ok("ship time reads 0.6227 ship-yr", row(map, "journey.plan.ship_years")["text"] == "0.6227 ship-yr")
	ok("Earth time reads 4.414 Earth-yr", row(map, "journey.plan.earth_years")["text"] == "4.414 Earth-yr")
	ok("boost reads 1.80 min", row(map, "journey.plan.boost_minutes")["text"] == "1.80 min")
	ok("total reads 6.818 kg", row(map, "journey.plan.energy.total_kg")["text"] == "6.818 kg")
	map.select(ALPHA_CEN_A)
	map.tick()
	return true


func test_clock_never_pauses(map: GalaxyMap) -> bool:
	var tick0: int = map.sim.world["tick"]
	var tau0: float = map.sim.world["clock"]["tau"]
	var arrive0: float = plan_of(map)["arrive_year"]
	for i in 5:
		map.tick()
	ok("tick advances while the panel is open", map.sim.world["tick"] == tick0 + 5)
	ok("ship clock advances at the fixed host rate", absf(map.sim.world["clock"]["tau"] - tau0 - 5.0 * GalaxyMap.HOST_DTAU) < 1e-15)
	ok("'if you commit now' arrival moves with the clock", plan_of(map)["arrive_year"] > arrive0 and row(map, "journey.plan.arrive_year")["raw"] == plan_of(map)["arrive_year"])
	ok("the map never sends a pause or zero-dtau tick", GalaxyMap.HOST_DTAU > 0.0)
	return true


func test_signal_and_preselect(map: GalaxyMap) -> bool:
	var got := []
	map.target_selected.connect(func(id: String) -> void: got.append(id))
	map.select(3)
	ok("target_selected fires with the star id", got == ["Gl 699"] and map.selected_index == 3)
	map.preselect(ALPHA_CEN_A)
	ok("preselect selects without emitting", got == ["Gl 699"] and map.selected_index == ALPHA_CEN_A)
	map.tick()
	ok("preselect plans the star", plan_of(map)["target"]["index"] == ALPHA_CEN_A)
	ok("preselect out of range is ignored", not map.preselect(99999) and map.selected_index == ALPHA_CEN_A)
	return true


func test_picking(map: GalaxyMap) -> bool:
	ok("nearest_index picks the closest within the radius", GalaxyMap.nearest_index(PackedVector2Array([Vector2(10, 10), Vector2(50, 50), Vector2(52, 49)]), Vector2(53, 49), 8.0) == 2)
	ok("nothing within the radius gives -1", GalaxyMap.nearest_index(PackedVector2Array([Vector2(10, 10)]), Vector2(100, 100), 8.0) == -1)
	map.frame_star(ALPHA_CEN_A)
	var sp := map.screen_position(ALPHA_CEN_A)
	ok("alpha Cen projects inside the 800x600 viewport", Rect2(0, 0, 800, 600).has_point(sp))
	var hit := map.pick(sp + Vector2(2, -1))
	ok("a click on alpha Cen picks a Gl 559 star (A and B share a position)", hit >= 0 and map.catalogue[hit]["id"] == "Gl 559")
	ok("a click on empty sky picks nothing", map.pick(Vector2(-500, -500)) == -1)
	return true


func _initialize() -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(800, 600)
	root.add_child(vp)
	await process_frame # nodes enter the tree once the main loop runs
	var map := new_map(vp)
	if map == null:
		quit(2)
		return
	var tests: Array[Callable] = [
		test_select_sends_catalogue_doubles.bind(map),
		test_default_and_range.bind(map),
		test_labels_are_sim_values.bind(map),
		test_check_row_digits.bind(map),
		test_clock_never_pauses.bind(map),
		test_signal_and_preselect.bind(map),
		test_picking.bind(map),
	]
	for t in tests:
		if t.call() != true:
			ok("%s ran to completion" % t.get_method(), false)
	map.sim.stop()
	print("galaxy map: %d failures" % failures)
	quit(1 if failures > 0 else 0)
