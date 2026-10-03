extends SceneTree
## Headless galaxy-map test (M2.6a, design AC15 part) against the real sim:
## selection by catalogue id (M1.7: stable ids, alpha Cen A and B are two
## stars), the plan payload (float64 catalogue doubles,
## slider rapidity), the slider's range and default against the sim's own
## acceptance bounds, panel labels = formatted sim fields, the clock never
## pausing, target_selected and preselect, and screen-space picking in a fixed
## 800x600 viewport.
## Run:  godot --headless --path . --script tests/test_galaxy_map.gd

## M1.7 catalogue ids: alpha Cen A is the CNS5 system row (HIP photometry, Q1),
## B the bright tier's HIP 71681 at the CNS5 system parallax (Q2 (a), D-19).
const ACEN_A_ID := "CNS5:3627"
const ACEN_B_ID := "HIP 71681"
const BARNARD_ID := "Gaia DR3 4472832130942575872"
const RECORD := "user://test_galaxy_map_input.ndjson"
## Committed golden: the M1.7 capture's alpha Cen A 0.99c panel.
const GOLDEN := "res://docs/m1.7/galaxy_map_panel.json"
## Literal texts of that panel's clock-independent rows (the clock-dependent
## arrival / age / years-left rows move with the tick). Pinned here and checked
## against the golden too, so the label test does not reuse format_row.
const ALPHA_CEN_099 := {
	"journey.plan.ship_years": "0.6157 ship-yr",
	"journey.plan.earth_years": "4.365 Earth-yr",
	"journey.plan.distance": "4.321 ly",
	"journey.plan.cruise_beta": "0.990000c",
	"journey.plan.cruise_one_minus_beta": "0.01000",
	"journey.plan.cruise_gamma": "7.0888",
	"journey.plan.boost_minutes": "1.80 min",
	"journey.plan.energy.boost_j": "2.379e17 J",
	"journey.plan.energy.brake_j": "2.379e17 J",
	"journey.plan.energy.drag_j": "1.355e17 J",
	"journey.plan.energy.total_j": "6.112e17 J",
	"journey.plan.energy.total_kg": "6.801 kg",
	"journey.plan.ism.load_w_m2": "2.220e5 W/m2",
	"journey.plan.ism.glow_w_m2": "2.407e-5 W/m2",
	"journey.plan.ism.drag_n": "23.26 N",
	"journey.plan.ism.hold_w": "6.973e9 W",
	"journey.plan.cmb_forward_k": "38.44 K",
	"journey.plan.profile": "burn_coast_burn",
}

var failures := 0
var acen_a := -1 # catalogue indices, looked up by id once the catalogue loads
var acen_b := -1

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
	sim.record_path = RECORD # every line sent to the sim, to check what the map never sends
	if not sim.start() or not sim.new_game(0, "sol", false):
		ok("sim session starts (%s)" % sim.last_error, false)
		return null
	var map: GalaxyMap = load("res://ui/galaxy_map.tscn").instantiate()
	map.auto_tick = false
	vp.add_child(map)
	map.load_catalogue("res://data/starmap/stars.json")
	map.load_names("res://data/starmap/names.json")
	map.attach(sim)
	acen_a = map.index_of(ACEN_A_ID)
	acen_b = map.index_of(ACEN_B_ID)
	return map

func plan_of(map: GalaxyMap) -> Dictionary:
	return map.sim.world.get("journey", {}).get("plan", {})

func row(map: GalaxyMap, field: String) -> Dictionary:
	for r in map.panel_rows():
		if r["field"] == field:
			return r
	return {}


func test_select_sends_catalogue_doubles(map: GalaxyMap) -> bool:
	var star: Dictionary = map.catalogue[acen_a]
	ok("CNS5:3627 is alpha Cen A (HIP V -0.01, flag 8)", acen_a >= 0 and star["id"] == ACEN_A_ID and same(star["vmag"], -0.01) and int(star["flags"]) == 8)
	var intent := map.plan_intent(acen_a)
	var t: Dictionary = intent["target"]
	ok("plan carries index and id", intent["k"] == "plan" and t["index"] == acen_a and typeof(t["index"]) == TYPE_INT and t["id"] == ACEN_A_ID)
	var p: Dictionary = t["pos"]
	ok("pos x, y, z are the parsed JSON doubles, bit for bit", same(p["x"], star["x"]) and same(p["y"], star["y"]) and same(p["z"], star["z"]))
	ok("pos y is not float32-rounded (-3.015404 has no exact float32)", not same(p["y"], float(Vector3(0, star["y"], 0).y)))
	ok("plan carries the slider's cruise_phi", same(intent["cruise_phi"], map.cruise_phi))
	map.select(acen_a)
	map.tick()
	var plan := plan_of(map)
	ok("sim planned alpha Cen A", map.sim.world["journey"]["state"] == "planned" and plan["target"]["index"] == acen_a)
	var echo: Dictionary = plan["target"]["pos"]
	ok("sim echoes pos bit for bit", same(echo["x"], star["x"]) and same(echo["y"], star["y"]) and same(echo["z"], star["z"]))
	# CNS5 754.81 mas (the HIP system parallax, D-19) at the CNS5 position, 1e-6 ly digits;
	# sim/core_test's checkPlanAlphaCenA pins the same doubles -> the same d.
	ok("distance is the catalogue-double distance (|(3.094521, -3.015404, -0.051608)| = 4.32103979249451)", same(plan["distance"], f64(0x401148bea7c5ea08)))
	ok("the sim's distance is stars.json dist_ly, bit for bit (the map shows the catalogue's own distance, D-17)", same(plan["distance"], star["dist_ly"]))
	return true


## alpha Cen A and B are two selectable stars with their own ids (M1.7, F2):
## B sits at the CNS5 system distance, 19 arcsec from A, never at its own
## HIP2 parallax (4.09 ly).
func test_alpha_cen_pair(map: GalaxyMap) -> bool:
	ok("alpha Cen B is its own catalogue row", acen_b >= 0 and acen_b != acen_a and map.catalogue[acen_b]["id"] == ACEN_B_ID)
	var a: Dictionary = map.catalogue[acen_a]
	var b: Dictionary = map.catalogue[acen_b]
	ok("B is at the system distance (4.3210 ly, within 1e-6 of A), not 4.09 ly", absf(float(b["dist_ly"]) - float(a["dist_ly"])) < 1.0e-6 and same(b["dist_ly"], f64(0x401148be90cd7009)))
	var sep := rad_to_deg(acos(clampf((float(a["x"]) * float(b["x"]) + float(a["y"]) * float(b["y"]) + float(a["z"]) * float(b["z"])) / (float(a["dist_ly"]) * float(b["dist_ly"])), -1.0, 1.0))) * 3600.0
	ok("B is 5-25 arcsec from A (%.1f arcsec)" % sep, sep > 5.0 and sep < 25.0)
	ok("B's V is Hipparcos 1.35 (flag 8)", same(b["vmag"], 1.35) and int(b["flags"]) == 8)
	map.select(acen_b)
	map.tick()
	var plan := plan_of(map)
	ok("selecting B plans B (id HIP 71681), at its catalogue distance", plan["target"]["id"] == ACEN_B_ID and plan["target"]["index"] == acen_b and same(plan["distance"], b["dist_ly"]))
	ok("B's title is its common name, subtitle its id and catalogue distance", map.title_text() == "Alpha Centauri B" and map.subtitle_text() == "HIP 71681  ·  4.32 ly")
	map.select(acen_a)
	map.tick()
	ok("back on A", plan_of(map)["target"]["id"] == ACEN_A_ID)
	ok("every catalogue id is unique (index_by_id covers every row)", map.index_by_id.size() == map.catalogue.size())
	return true


func test_default_and_range(map: GalaxyMap) -> bool:
	var phi099 := f64(0x40052c581997cd85) # 2.6466524123622457 = core_test phi099()
	ok("slider defaults to atanh 0.99 bit for bit", same(map.cruise_phi, phi099) and same(map.slider.value, phi099))
	var plan := plan_of(map)
	ok("sim echoes the default phi bit for bit", same(plan["cruise_phi"], phi099))
	ok("sim reads it as cruise_beta 0.99", same(plan["cruise_beta"], 0.99))
	ok("slider min = atanh 0.9 (core_test phi09())", same(map.slider.min_value, f64(0x3ff78e360604b32d)))
	ok("slider max = rapidityOfOneMinusBeta(1e-6) (core_test plPhiCap())", same(map.slider.max_value, f64(0x401d046eb8b8ab58)))
	var params: Dictionary = map.sim.world["params"]
	ok("slider ends and default are the sim's params echo (cruise_phi_min/max/default)", same(map.phi_min, params["cruise_phi_min"])
		and same(map.phi_max, params["cruise_phi_max"]) and same(map.phi_default, params["cruise_phi_default"]))
	# set_cruise_phi clamps into the slider range (M2.6a eval: clamp untested)
	map.set_cruise_phi(map.phi_max + 1.0)
	ok("set_cruise_phi clamps above the max", same(map.cruise_phi, map.phi_max) and same(map.slider.value, map.phi_max))
	map.set_cruise_phi(-3.0)
	ok("set_cruise_phi clamps below the min", same(map.cruise_phi, map.phi_min) and same(map.slider.value, map.phi_min))
	map.set_cruise_phi(phi099)
	ok("set_cruise_phi keeps an in-range value bit for bit", same(map.cruise_phi, phi099))
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
	ok("every row: raw = the sim field (bits)", all_match)
	# literal texts, not format_row: the pinned strings and the committed golden
	var golden := {}
	for p in JSON.parse_string(FileAccess.get_file_as_string(GOLDEN))["panels"]:
		if p["speed"] == "0.99c":
			for r in p["rows"]:
				golden[r["field"]] = r["text"]
	var literal := true
	for f in ALPHA_CEN_099:
		if row(map, f).get("text") != ALPHA_CEN_099[f] or golden.get(f) != ALPHA_CEN_099[f]:
			literal = false
			print("    literal mismatch %s: shown %s, pinned %s, golden %s" % [f, row(map, f).get("text"), ALPHA_CEN_099[f], golden.get(f)])
	ok("alpha Cen A 0.99c: %d rows read the pinned literal text, as in the committed golden" % ALPHA_CEN_099.size(), literal)
	ok("arrival text is the sim's arrive_year at 3 decimals", row(map, "journey.plan.arrive_year")["text"] == "Earth +%.3f yr" % plan["arrive_year"])
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
	map.plan_target({"index": acen_a, "id": ACEN_A_ID, "pos": {"x": 0.0, "y": 0.0, "z": -4.37}})
	map.tick()
	ok("check-row plan accepted", map.sim.last_refused.is_empty() and same(plan_of(map)["distance"], 4.37))
	ok("ship time reads 0.6227 ship-yr", row(map, "journey.plan.ship_years")["text"] == "0.6227 ship-yr")
	ok("Earth time reads 4.414 Earth-yr", row(map, "journey.plan.earth_years")["text"] == "4.414 Earth-yr")
	ok("boost reads 1.80 min", row(map, "journey.plan.boost_minutes")["text"] == "1.80 min")
	ok("total reads 6.818 kg", row(map, "journey.plan.energy.total_kg")["text"] == "6.818 kg")
	map.select(acen_a)
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
	var barnard := map.index_of(BARNARD_ID)
	map.select(barnard)
	ok("target_selected fires with the star id", got == [BARNARD_ID] and map.selected_index == barnard)
	map.preselect(acen_a)
	ok("preselect selects without emitting", got == [BARNARD_ID] and map.selected_index == acen_a)
	map.tick()
	ok("preselect plans the star", plan_of(map)["target"]["index"] == acen_a)
	ok("preselect out of range is ignored", not map.preselect(99999) and map.selected_index == acen_a)
	return true


func test_picking(map: GalaxyMap) -> bool:
	ok("nearest_index picks the closest within the radius", GalaxyMap.nearest_index(PackedVector2Array([Vector2(10, 10), Vector2(50, 50), Vector2(52, 49)]), Vector2(53, 49), 8.0) == 2)
	ok("nothing within the radius gives -1", GalaxyMap.nearest_index(PackedVector2Array([Vector2(10, 10)]), Vector2(100, 100), 8.0) == -1)
	map.frame_star(acen_a)
	var sp := map.screen_position(acen_a)
	ok("alpha Cen projects inside the 800x600 viewport", Rect2(0, 0, 800, 600).has_point(sp))
	var hit := map.pick(sp + Vector2(2, -1))
	ok("a click on alpha Cen picks A or B (19 arcsec apart: one pixel)", hit == acen_a or hit == acen_b)
	ok("a click on empty sky picks nothing", map.pick(Vector2(-500, -500)) == -1)
	return true


## Star names (D-17): keyed by catalogue id (M1.7); the panel title is the
## common name and the subtitle the catalogue id and the catalogue's own
## distance. The mappings are verified against literature positions by
## tools/check_star_names.py.
func test_names(map: GalaxyMap) -> bool:
	ok("names.json loads with every id in the catalogue", map.names.size() >= 50 and map.name_mismatches == 0)
	var want := {"Gaia DR3 5853498713190525696": "Proxima Centauri", ACEN_A_ID: "Alpha Centauri A", ACEN_B_ID: "Alpha Centauri B",
		BARNARD_ID: "Barnard's Star", "Gaia DR3 3864972938605115520": "Wolf 359", "Gaia DR3 762815470562110464": "Lalande 21185",
		"CNS5:1676": "Sirius A", "Gaia DR3 2947050466531873024": "Sirius B", "Gaia DR3 5164707970261890560": "Epsilon Eridani",
		"Gaia DR3 1872046609345556480": "61 Cygni A", "Gaia DR3 1872046574983497216": "61 Cygni B",
		"Gaia DR3 2452378776434477184": "Tau Ceti", "CNS5:1895": "Procyon"}
	var all_named := true
	for id in want:
		if map.display_name(map.index_of(id)) != want[id]:
			all_named = false
			print("    %s named %s, want %s" % [id, map.display_name(map.index_of(id)), want[id]])
	ok("catalogue ids carry the common names (alpha Cen and Sirius A/B by their own ids)", all_named)
	ok("an unnamed star shows its catalogue id", map.display_name(map.index_of("CNS5:2653")) == "CNS5:2653")
	# a row whose id the catalogue lacks, or a second name for one id, is ignored, not trusted
	var bad := ProjectSettings.globalize_path("user://names_mismatch.json")
	var f := FileAccess.open(bad, FileAccess.WRITE)
	f.store_string('{"names": [{"id": "Gl 559", "name": "Wrong"}, {"id": "%s", "name": "Barnard\'s Star"}, {"id": "%s", "name": "Twice"}]}' % [BARNARD_ID, BARNARD_ID])
	f.close()
	var n := map.load_names(bad)
	ok("an unknown id and a repeated id are ignored and counted", n == 1 and map.name_mismatches == 2 and map.display_name(map.index_of(BARNARD_ID)) == "Barnard's Star"
		and map.display_name(acen_a) == ACEN_A_ID)
	map.load_names("res://data/starmap/names.json")
	map.select(acen_a)
	map.tick()
	ok("panel title is the common name", map.title_text() == "Alpha Centauri A" and map._title.text == "Alpha Centauri A")
	ok("subtitle is the catalogue id and the catalogue distance (4.32 ly, Q2 default)", map.subtitle_text() == "CNS5:3627  ·  4.32 ly" and map._subtitle.text == map.subtitle_text())
	return true


## The last tick line the map sent ({"type":"input", "dtau", ...}), parsed.
func last_input() -> Dictionary:
	var last := {}
	for line in FileAccess.get_file_as_string(RECORD).split("\n"):
		if line.contains('"type":"input"'):
			last = JSON.parse_string(line)
	return last


func sent_lines(kind: String) -> int:
	var n := 0
	for line in FileAccess.get_file_as_string(RECORD).split("\n"):
		if line.contains(kind):
			n += 1
	return n


## The commit dialog (D-12): both clocks and years left from the sim; nothing
## is sent before 1.5 s of continuous hold (fake clock); then commit {plan_id}.
func test_commit_hold(map: GalaxyMap) -> bool:
	map.select(acen_a)
	map.set_cruise_phi(map.phi_default)
	map.tick()
	ok("planned alpha Cen A at 0.99c; Commit enabled", map.journey_state() == "planned" and not map.commit_button.disabled)
	ok("hold time is 1.5 s (D-12)", GalaxyMap.HOLD_S == 1.5)
	ok("dialog opens on the sim's plan", map.open_commit_dialog() and map.dialog.visible and map.dialog_plan_id == map.sim.world["journey"]["plan_id"])
	var drows := map.dialog_rows()
	var fields := drows.map(func(r): return r["field"])
	ok("dialog shows both clocks and the years left", fields == ["journey.plan.ship_years", "journey.plan.earth_years", "journey.plan.arrive_year", "journey.plan.years_left"])
	var raw_ok := true
	for r in drows:
		raw_ok = raw_ok and same(r["raw"], GalaxyMap.field_value(map.sim.world, r["field"]))
	ok("dialog numbers are the sim's fields (bits)", raw_ok)
	ok("dialog reads 0.6157 ship-yr / 4.365 Earth-yr (pinned)", drows[0]["text"] == "0.6157 ship-yr" and drows[1]["text"] == "4.365 Earth-yr")
	ok("dialog labels on screen show those texts", (map.dialog_grid.get_child(1) as Label).text == "0.6157 ship-yr" and (map.dialog_grid.get_child(3) as Label).text == "4.365 Earth-yr")
	ok("dialog years left = the sim's years_left at 2 decimals", drows[3]["text"] == "%.2f yr" % map.sim.world["journey"]["plan"]["years_left"])
	# Back sends nothing
	map.close_commit_dialog()
	map.tick()
	ok("Back closes the dialog and sends nothing", not map.dialog.visible and map.journey_state() == "planned" and sent_lines('"commit"') == 0)
	# just short of 1.5 s, then released: nothing
	map.open_commit_dialog()
	ok("1.4990234375 s of hold does not commit", not map.hold_commit(1.0) and not map.hold_commit(0.4990234375))
	map.release_commit()
	ok("release resets the hold", map.hold_s == 0.0 and map.dialog.visible)
	# A frame stall must not commit in one frame: _process clamps the hold delta.
	ok("hold frame delta is clamped to 0.1 s", GalaxyMap.MAX_HOLD_DT == 0.1)
	map.hold_button.button_down.emit()
	map._process(2.0) # a 2 s frame stall while the button is down
	ok("a 2 s frame stall adds only 0.1 s of hold and commits nothing", map.hold_s == 0.1 and map.dialog.visible and map.journey_state() == "planned")
	map._process(2.0)
	map._process(2.0)
	ok("three stalled frames add 0.3 s, still short", absf(map.hold_s - 0.3) < 1e-12 and map.dialog.visible)
	map.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	ok("window focus loss releases the hold", not map._holding and map.hold_s == 0.0 and map.dialog.visible)
	map._process(2.0)
	ok("after focus loss frames add no hold", map.hold_s == 0.0)
	map.tick()
	ok("nothing sent across the stall and focus loss", map.journey_state() == "planned" and sent_lines('"commit"') == 0)
	ok("after release, 1.25 s more is still short", not map.hold_commit(1.25))
	map.tick()
	ok("no commit sent before 1.5 s", map.journey_state() == "planned" and sent_lines('"commit"') == 0)
	var id: int = map.sim.world["journey"]["plan_id"]
	ok("the hold reaching 1.5 s queues the commit and closes the dialog", map.hold_commit(0.25) and not map.dialog.visible)
	map.tick()
	ok("sim committed the plan shown (commit {plan_id})", map.journey_state() == "committed" and map.sim.world["journey"]["plan_id"] == id
		and map.sim.last_events.any(func(e): return e["k"] == "committed") and sent_lines('{"k":"commit","plan_id":%d}' % id) == 1)
	return true


## After the commit Cancel stays visible and enabled; pressing it sends
## `cancel`, the sim refuses `committed`, the panel shows it, and the journey
## is unchanged. Selecting another star is refused the same way. The map never
## sends new_game (no escape from a commit).
func test_post_commit_cancel(map: GalaxyMap) -> bool:
	ok("Cancel is visible and enabled after the commit", map.cancel_button.visible and not map.cancel_button.disabled and map.cancel_button.is_visible_in_tree())
	ok("Commit is disabled while committed", map.commit_button.disabled and not map.open_commit_dialog())
	var before: Dictionary = map.sim.world["journey"].duplicate(true)
	map.cancel_button.pressed.emit()
	map.tick()
	ok("the sim refused the cancel: committed", map.sim.last_refused.size() == 1 and map.sim.last_refused[0]["reason"] == "committed")
	ok("the panel shows the sim's refusal", map.status_text().contains("refused: committed") and map._status.text.contains("refused: committed"))
	ok("journey unchanged by Cancel", map.sim.world["journey"] == before)
	map.tick()
	ok("the refusal stays on the panel until the next player action", map._status.text.contains("refused: committed"))
	map.select(map.index_of(BARNARD_ID))
	map.tick()
	ok("selecting another star is refused committed, journey unchanged", map.sim.last_refused.size() == 1 and map.sim.last_refused[0]["reason"] == "committed" and map.sim.world["journey"] == before)
	ok("the map never sent new_game after the session start", sent_lines('"new_game"') == 1)
	map.selected_index = acen_a
	return true


## Transit readout: phase, both clocks advancing, progress, all sim fields;
## at arrival the readout and the ship marker use the plan distance and
## ship.pos (ship.flown is 0 again once the line is rebased at the target).
func test_transit(map: GalaxyMap) -> bool:
	var plan: Dictionary = map.sim.world["journey"]["plan"]
	var tau0: float = map.sim.world["clock"]["tau"]
	var year0: float = map.sim.world["clock"]["year"]
	var rows := map.panel_rows()
	ok("transit readout replaces the plan panel", rows.size() == GalaxyMap.TRANSIT_ROWS.size() and rows[0]["field"] == "ship.phase")
	ok("title reads En route to Alpha Centauri A", map.title_text() == "En route to Alpha Centauri A")
	ok("transit rate is 0.1 ship-yr per real second", GalaxyMap.TRANSIT_RATE == 0.1)
	var tau_c: float = map.sim.world["clock"]["tau"]
	map.tick()
	var wire := last_input()
	ok("a committed tick sends dtau = 0.1 / 20 ship-yr on the wire (bits)", same(wire.get("dtau"), 0.1 / 20.0))
	ok("the ship clock advanced by exactly that dtau", absf(map.sim.world["clock"]["tau"] - tau_c - 0.1 / 20.0) < 1e-15)
	var mid := false
	var phases := {}
	var all_sim := true
	var advancing := true
	for i in 400:
		var t0: float = map.sim.world["clock"]["tau"]
		var y0: float = map.sim.world["clock"]["year"]
		map.tick()
		if map.journey_state() != "committed":
			break
		advancing = advancing and map.sim.world["clock"]["tau"] > t0 and map.sim.world["clock"]["year"] > y0
		phases[map.sim.world["ship"]["phase"]] = true
		for r in map.panel_rows():
			if not same(r["raw"], GalaxyMap.field_value(map.sim.world, r["field"])) and r["raw"] != GalaxyMap.field_value(map.sim.world, r["field"]):
				all_sim = false
		if not mid and map.sim.world["ship"]["phase"] == "cruising" and map.sim.world["ship"]["flown"] > 0.5 * plan["distance"]:
			mid = true
			var pv := map.progress_values()
			ok("mid-cruise: progress bar = sim ship.flown of plan distance", same(pv[0], map.sim.world["ship"]["flown"]) and same(pv[1], plan["distance"])
				and same(map.progress_bar.value, pv[0]) and map.progress_bar.visible)
			ok("mid-cruise: phase row shows the sim's phase", map.panel_rows()[0]["text"] == "cruising")
			ok("mid-cruise: speed row is the sim's beta (0.990000c)", map.panel_rows()[6]["text"] == "0.990000c" and same(map.panel_rows()[6]["raw"], map.sim.world["ship"]["beta"]))
			var fr: Dictionary = map.panel_rows()[4]
			ok("mid-cruise: 'Flown since commit' row is ship.flown at 4 decimals in ly", fr["label"] == "Flown since commit" and fr["field"] == "ship.flown"
				and fr["text"] == "%.4f ly" % map.sim.world["ship"]["flown"] and RegEx.create_from_string("^\\d+\\.\\d{4} ly$").search(fr["text"]) != null)
			ok("mid-cruise: ship clock text is clock.tau at 4 decimals", map.panel_rows()[1]["text"] == "ship +%.4f yr" % map.sim.world["clock"]["tau"])
	ok("every transit row is a sim field (bits), every tick", all_sim)
	ok("both clocks advance every transit tick", advancing and map.sim.world["clock"]["tau"] > tau0 and map.sim.world["clock"]["year"] > year0)
	ok("a mid-cruise frame was reached", mid and phases.has("cruising"))
	ok("the sim arrived", map.journey_state() == "arrived" and map.title_text() == "Arrived at Alpha Centauri A")
	ok("arrival supersedes the earlier refusal note", not map._status.text.contains("refused") and map._status.text.contains("journey: arrived"))
	var arows := map.panel_rows()
	ok("arrived readout: flown is the plan distance, not the rebased ship.flown", arows[4]["field"] == "journey.plan.distance" and arows[4]["text"] == "4.321 ly"
		and map.sim.world["ship"]["flown"] == 0.0)
	ok("arrived progress bar is full", same(map.progress_values()[0], plan["distance"]) and same(map.progress_bar.value, map.progress_bar.max_value))
	var sp: Dictionary = map.sim.world["ship"]["pos"]
	var tp: Dictionary = plan["target"]["pos"]
	ok("ship marker from ship.pos, which the sim snapped onto the target", same(sp["x"], tp["x"]) and same(sp["y"], tp["y"]) and same(sp["z"], tp["z"])
		and map.ship_world_pos() == Starfield.galactic_to_world(Vector3(sp["x"], sp["y"], sp["z"])))
	var tau_a: float = map.sim.world["clock"]["tau"]
	ok("after arrival the clock runs at the host rate again", map.tick() and absf(map.sim.world["clock"]["tau"] - tau_a - GalaxyMap.HOST_DTAU) < 1e-15)
	return true


## Trackpad and keyboard zoom (review-build polish): pinch and two-finger
## scroll zoom like the wheel, stay clamped, and never orbit; Cmd/Ctrl keys are
## the UI zoom, not the camera. Events go through the viewport's input path.
func key(code: Key, cmd := false) -> InputEventKey:
	var k := InputEventKey.new()
	k.keycode = code
	k.pressed = true
	k.ctrl_pressed = cmd
	k.meta_pressed = cmd
	return k

func magnify(f: float) -> InputEventMagnifyGesture:
	var g := InputEventMagnifyGesture.new()
	g.factor = f
	g.position = Vector2(100, 100) # over the map, left of the panel
	return g

func pan(dy: float, dx := 0.0) -> InputEventPanGesture:
	var g := InputEventPanGesture.new()
	g.delta = Vector2(dx, dy)
	g.position = Vector2(100, 100)
	return g

func wheel(up: bool) -> InputEventMouseButton:
	var m := InputEventMouseButton.new()
	m.button_index = MOUSE_BUTTON_WHEEL_UP if up else MOUSE_BUTTON_WHEEL_DOWN
	m.pressed = true
	m.position = Vector2(100, 100)
	return m

func dist_after(map: GalaxyMap, vp: SubViewport, start: float, events: Array) -> float:
	map.dist = start
	for e in events:
		vp.push_input(e)
	return map.dist

func test_trackpad_zoom(map: GalaxyMap, vp: SubViewport) -> bool:
	var wheel_in := dist_after(map, vp, 18.0, [wheel(true)])
	var wheel_out := dist_after(map, vp, 18.0, [wheel(false)])
	ok("wheel still zooms (in %.4f, out %.4f from 18)" % [wheel_in, wheel_out], absf(wheel_in - 18.0 * 0.9) < 1e-12 and absf(wheel_out - 18.0 / 0.9) < 1e-12)
	ok("pinch out (factor 1.5) zooms in to 12", absf(dist_after(map, vp, 18.0, [magnify(1.5)]) - 12.0) < 1e-9)
	ok("pinch in (factor 0.5) zooms out to 36", absf(dist_after(map, vp, 18.0, [magnify(0.5)]) - 36.0) < 1e-9)
	ok("two-finger scroll up (delta.y -1) = one wheel-up notch", absf(dist_after(map, vp, 18.0, [pan(-1.0)]) - wheel_in) < 1e-9)
	ok("two-finger scroll down (delta.y +1) = one wheel-down notch", absf(dist_after(map, vp, 18.0, [pan(1.0)]) - wheel_out) < 1e-9)
	ok("half a scroll unit is half a notch (geometric)", absf(dist_after(map, vp, 18.0, [pan(-0.5), pan(-0.5)]) - wheel_in) < 1e-9)
	ok("pinch clamps at the near limit", dist_after(map, vp, 18.0, [magnify(10.0), magnify(10.0), magnify(10.0)]) == GalaxyMap.DIST_MIN)
	ok("pinch clamps at the far limit", dist_after(map, vp, 18.0, [magnify(0.01), magnify(0.01)]) == GalaxyMap.DIST_MAX)
	ok("scroll clamps at both limits", dist_after(map, vp, 18.0, [pan(-500.0)]) == GalaxyMap.DIST_MIN and dist_after(map, vp, 18.0, [pan(500.0)]) == GalaxyMap.DIST_MAX)
	ok("a zero or bad pinch factor leaves the distance alone", dist_after(map, vp, 18.0, [magnify(0.0), magnify(-2.0)]) == 18.0)
	var key_in := dist_after(map, vp, 18.0, [key(KEY_EQUAL)])
	ok("= zooms in one notch", absf(key_in - wheel_in) < 1e-12)
	ok("+ and keypad + zoom in one notch each", absf(dist_after(map, vp, 18.0, [key(KEY_PLUS), key(KEY_KP_ADD)]) - 18.0 * 0.81) < 1e-9)
	ok("- and keypad - zoom out one notch each", absf(dist_after(map, vp, 18.0, [key(KEY_MINUS), key(KEY_KP_SUBTRACT)]) - 18.0 / 0.81) < 1e-9)
	var many_in := []
	var many_out := []
	for i in 80:
		many_in.append(key(KEY_EQUAL))
		many_out.append(key(KEY_MINUS))
	ok("keys clamp at both limits", dist_after(map, vp, 18.0, many_in) == GalaxyMap.DIST_MIN and dist_after(map, vp, 18.0, many_out) == GalaxyMap.DIST_MAX)
	ok("Cmd/Ctrl + / - / 0 leave the camera alone (UI zoom)", dist_after(map, vp, 18.0, [key(KEY_EQUAL, true), key(KEY_MINUS, true), key(KEY_0, true)]) == 18.0)
	map.dist = 18.0
	map.pivot = Vector3.ZERO
	map.zoom_by(0.5)
	ok("the camera moves with the distance", absf(map.camera.global_position.distance_to(map.pivot) - 9.0) < 1e-3)
	var yaw0 := map.yaw
	var pitch0 := map.pitch
	vp.push_input(pan(3.0, 7.0))
	vp.push_input(pan(-3.0, -7.0))
	ok("two-finger scroll never orbits", map.yaw == yaw0 and map.pitch == pitch0)
	var drag := InputEventMouseMotion.new()
	drag.button_mask = MOUSE_BUTTON_MASK_LEFT
	drag.position = Vector2(140, 100)
	drag.relative = Vector2(40, 0)
	vp.push_input(drag)
	ok("left drag still orbits", map.yaw != yaw0)
	ok("the footer hint is shown by default", map.show_hint and map.hint.visible and map.hint.text.begins_with("Pinch or scroll to zoom"))
	return true


## UI zoom (Cmd/Ctrl + / - / 0) steps the window's content scale within
## [UiScale.MIN, UiScale.MAX]; the HiDPI window fits the screen.
func test_ui_scale() -> bool:
	ok("Cmd + grows the UI by a step", UiScale.step(1.0, KEY_EQUAL) == 1.25 and UiScale.step(1.0, KEY_KP_ADD) == 1.25)
	ok("Cmd - shrinks it by a step", UiScale.step(1.0, KEY_MINUS) == 0.75)
	ok("Cmd 0 resets it", UiScale.step(2.5, KEY_0) == 1.0)
	ok("UI zoom clamps at %.2f and %.2f" % [UiScale.MIN, UiScale.MAX], UiScale.step(UiScale.MAX, KEY_EQUAL) == UiScale.MAX and UiScale.step(UiScale.MIN, KEY_MINUS) == UiScale.MIN and UiScale.step(9.0, KEY_PLUS) == UiScale.MAX)
	ok("only Cmd/Ctrl keys are UI zoom", UiScale.is_zoom_event(key(KEY_EQUAL, true)) and not UiScale.is_zoom_event(key(KEY_EQUAL)) and not UiScale.is_zoom_event(key(KEY_W, true)))
	var w := Window.new()
	w.content_scale_factor = 1.0
	var steps := [KEY_EQUAL, KEY_EQUAL, KEY_EQUAL, KEY_EQUAL, KEY_EQUAL, KEY_EQUAL, KEY_EQUAL, KEY_EQUAL, KEY_EQUAL, KEY_EQUAL]
	for code in steps:
		UiScale.handle(w, key(code, true))
	ok("ten Cmd + presses stop at the cap", w.content_scale_factor == UiScale.MAX)
	ok("a plain key does not touch the UI scale", not UiScale.handle(w, key(KEY_EQUAL)) and w.content_scale_factor == UiScale.MAX)
	w.free()
	ok("HiDPI window is base x scale when it fits", UiScale.fitted_size(Vector2i(960, 540), 2.0, Vector2i(3024, 1890)) == Vector2i(1920, 1080))
	ok("HiDPI window shrinks to 90% of a small screen, aspect kept", UiScale.fitted_size(Vector2i(960, 540), 2.0, Vector2i(1440, 900)) == Vector2i(1296, 729))
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
		test_alpha_cen_pair.bind(map),
		test_default_and_range.bind(map),
		test_labels_are_sim_values.bind(map),
		test_check_row_digits.bind(map),
		test_clock_never_pauses.bind(map),
		test_signal_and_preselect.bind(map),
		test_picking.bind(map),
		test_names.bind(map),
		test_commit_hold.bind(map), # irreversible from here on
		test_post_commit_cancel.bind(map),
		test_transit.bind(map),
		test_trackpad_zoom.bind(map, vp),
		test_ui_scale,
	]
	for t in tests:
		if t.call() != true:
			ok("%s ran to completion" % t.get_method(), false)
	map.sim.stop()
	print("galaxy map: %d failures" % failures)
	quit(1 if failures > 0 else 0)
