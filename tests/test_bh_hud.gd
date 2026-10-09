extends SceneTree
## M3.6 of R1-M3-BLACK-HOLES: the Sgr A* demo aboard the 3D ship (AC-12, AC-15 client half).
##   1. HUD sentinels: every number the black-hole HUD shows is a field of the sim's gr section,
##      formatted, never derived (a changed field changes the text; no field, no line).
##   2. The way in: the navigation menu's "Sgr A* (black hole)" entry and --scenario=sgr_a start the
##      sgr_a scenario at protocol 2.6; the HUD lines equal the formatter applied to sim.gr.
##   3. The scripted demo (approach 10^6 -> 10, hover, 5, 3, orbit) through the real sim; the three
##      black-hole Archive entries unlock in the codex; the ship key comes back with no star.
##   4. GR off elsewhere: leaving restores a flat sky; a normal navigation session has no gr.
## Run with the sim on PATH (make bh-hud-test).
const Visit := preload("res://demos/black_hole_visit.gd")
const Main := preload("res://main.gd")
const RenderDiff := preload("res://tools/render_diff.gd")
## Expected HUD text at stops 1 (hover 10) and 4 (orbit 3), from the design's check values
## (AC-11: static clock 0.948683298050514 / 0.816496580927726, blueshift 1.05409 / 1.22474,
## shadow 14.269° / 45°, orbit tide 3.162e-4 g, hover power 1.1190e13 W/kg at 10 r_s).
const LITERALS := {
	0: ["HOVERING at r = 10.00 r_s", "static clock 0.948683", "1 ship-hour = 1.0541 home hours", "shadow half-angle 14.27°", "×1.0541", "5.69×10⁻⁶ g radial", "1.12×10¹³ W per kg of m_eff", "not felt (bubble)"],
	3: ["ORBITING at r = 3.00 r_s", "β_local 0.5000", "static clock 0.816497", "1 ship-hour = 1.4142 home hours", "shadow half-angle 45.00°", "×1.2247", "3.16×10⁻⁴ g radial", "free fall: 0 W"],
}
var passed := 0
var failures := 0

func check(name: String, ok: bool) -> void:
	if ok: passed += 1
	else: failures += 1
	print("  %s %s" % ["ok  " if ok else "FAIL", name])

func _initialize() -> void: _run.call_deferred()

## A gr section with values no real state has, so a hit can only come from the field.
static func sentinel(mode := "hover") -> Dictionary:
	return {"hole_id": "Sentinel Hole", "mass_msun": 1234567.0, "rs_m": 3.6458e9, "r": 7.25, "mode": mode, "to_r": 7.25, "phase": 0.0,
		"static_clock": 0.876543, "ship_clock": 0.765432, "home_per_ship": 1.306462, "blueshift": 1.140846, "shadow": 0.31415,
		"beta_local": 0.0 if mode == "hover" else 0.4321, "gamma_local": 1.0 if mode == "hover" else 1.108766, "one_minus_beta_local": 1.0 if mode == "hover" else 0.5679,
		"dir_local": {"x": 0.0, "y": 0.0, "z": 0.0}, "hole_dir": {"x": 1.0, "y": 0.0, "z": 0.0},
		"hover_accel_g": 98765.4 if mode == "hover" else 0.0, "hover_power_w_per_kg": 4.321e13 if mode == "hover" else 0.0, "hover_power_w": 4.321e13 if mode == "hover" else 0.0,
		"tidal_radial_g": 2.468e-5, "tidal_transverse_g": 1.234e-5, "orbit_stable": true}

func _run() -> void:
	test_sentinels()
	test_scenario_arg()
	test_render_diff()
	await test_demo()
	print("bh-hud: %d passed, %d failures" % [passed, failures])
	quit(1 if failures else 0)

func test_sentinels() -> void:
	var g := sentinel()
	var text := "\n".join(Visit.hud_lines(g))
	check("hole name, mass and r_s from the section", text.contains("Sentinel Hole") and text.contains("1.235×10⁶ M☉") and text.contains("3.65×10⁹ m"))
	check("hover at r from the section", text.contains("HOVERING at r = 7.25 r_s"))
	check("static clock and home hours per ship hour", text.contains("static clock 0.876543") and text.contains("1 ship-hour = 1.3065 home hours"))
	check("shadow half-angle (deg of the sim's radians) and blueshift", text.contains("shadow half-angle 18.00°") and text.contains("×1.1408"))
	check("tide across the bubble", text.contains("2.47×10⁻⁵ g") and text.contains("1.23×10⁻⁵ g"))
	check("hover: not felt (bubble), with power per kg of m_eff", text.contains("hover 9.88×10⁴ g · not felt (bubble)") and text.contains("4.32×10¹³ W per kg of m_eff"))
	check("the Sol-sky caption (design OQ5, D-53)", text.contains("as seen from Sol"))
	var changed := false
	for k: String in ["static_clock", "home_per_ship", "blueshift", "shadow", "tidal_radial_g", "tidal_transverse_g", "hover_accel_g", "hover_power_w_per_kg", "r", "mass_msun", "rs_m"]:
		var h := g.duplicate(true)
		h[k] = float(h[k]) * 1.37
		changed = "\n".join(Visit.hud_lines(h)) != text
		if not changed:
			print("    field %s does not reach the HUD" % k)
			break
	check("every shown number moves with its field (no derived copy)", changed)
	var o := "\n".join(Visit.hud_lines(sentinel("orbit")))
	check("orbit: free fall, 0 W, local beta from the section", o.contains("ORBITING at r = 7.25 r_s") and o.contains("free fall: 0 W") and o.contains("β_local 0.4321") and not o.contains("not felt"))
	var a := sentinel("approach")
	a["to_r"] = 3.5
	var at := "\n".join(Visit.hud_lines(a))
	check("approach shows the target and the local speed", at.contains("APPROACHING r = 7.25 r_s → 3.50 r_s") and at.contains("β_local 0.4321"))
	check("no section, no lines", Visit.hud_lines({}).is_empty())
	check("near-unity ratios keep their digits (1e6 r_s)", Visit.ratio_text(1.0000005000003749).begins_with("1.0000005"))

## tools/render_diff.gd's measure (AC-13): identical = 0; +1 level on one channel everywhere =
## 1/3 of 1/255 (passes); +4 everywhere = 4/255 (fails the 1/255 limit).
func test_render_diff() -> void:
	var a := Image.create(64, 32, false, Image.FORMAT_RGB8)
	a.fill(Color8(100, 120, 140))
	var b := a.duplicate()
	check("render diff: identical images differ by 0", RenderDiff.mean_abs_diff(a, b) == 0.0)
	b.fill(Color8(101, 120, 140))
	check("render diff: +1 level on one channel = 1/3 of 1/255", absf(RenderDiff.mean_abs_diff(a, b) - 1.0 / 765.0) < 1e-12)
	b.fill(Color8(104, 124, 144))
	check("render diff: +4 levels = 4/255 > the 1/255 limit", absf(RenderDiff.mean_abs_diff(a, b) - 4.0 / 255.0) < 1e-12)

func test_scenario_arg() -> void:
	var Demo: GDScript = load("res://demos/ship_geometry_demo.gd")
	check("--scenario=sgr_a parsed", Demo.scenario_arg(PackedStringArray(["--ship-demo", "--scenario=sgr_a"])) == "sgr_a")
	check("no --scenario, no black hole", Demo.scenario_arg(PackedStringArray(["--ship-demo"])) == "")
	check("main keeps --ship-demo --scenario on the current ship", Main.launch_route({"ship-demo": "", "scenario": "sgr_a"}) == "ship")

func test_demo() -> void:
	var demo: Node = load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options = {"stars": false, "background": false}
	root.add_child(demo)
	demo.auto = false
	demo.journey_auto_tick = false
	await process_frame
	check("ready, flat sky, GR off", demo.ready_ok and not demo.sky.gr_lens.active)
	check("the HUD says GR is off, not 'not implemented'", not demo.label.text.contains("not implemented"))
	# the navigation menu entry
	demo.open_navigation()
	var entry: Button = demo.navigation_window.find_child("SgrAEntry", true, false) if demo.navigation_window != null else null
	check("navigation menu has 'Sgr A* (black hole)'", entry != null and entry.text.begins_with("Sgr A* (black hole)"))
	check("a normal navigation session has no gr (protocol 2.7, D-58)", demo.journey_sim != null and demo.journey_sim.want_minor == SimBridge.STOPS_MINOR and not demo.journey_sim.world.has("gr"))
	if entry == null:
		return
	entry.pressed.emit()
	for i in 3: await process_frame
	var v = demo.black_hole
	check("the entry starts sgr_a at protocol 2.6", v != null and v.sim.want_minor == SimBridge.GR_MINOR and v.sim.gr.get("hole_id", "") == "Sgr A*" and float(v.sim.gr.mass_msun) == 4297000.0)
	if v == null:
		return
	check("the normal session and its window are gone", demo.journey_sim == null and demo.navigation_window == null)
	check("starts hovering at 10^6 r_s", v.sim.gr.mode == "hover" and float(v.sim.gr.r) == 1.0e6)
	check("the sky takes the sim's gr section", demo.sky.gr_lens.active and demo.sky.gr_lens.state == v.sim.gr)
	check("stars drawn from Sol (OQ5)", demo.sky.starfield.ship == PackedFloat64Array([0.0, 0.0, 0.0]))
	check("nose on the hole", demo.camera.heading == PackedFloat64Array([v.sim.gr.hole_dir.x, v.sim.gr.hole_dir.y, v.sim.gr.hole_dir.z]))
	check("snapshot states locked during the visit", not demo.set_sky_state("rest"))
	check("HUD shows the sim's gr lines", hud_has(demo, v.sim.gr))
	var first: Array = GalaxyMap.field_value(v.sim.world, "consequence.archive.unlocked")
	check("at bh_enter the codex shows what the sim unlocked, no black-hole entry yet", demo.codex.toast_log == first and not first.has("archive.tides") and not first.has("archive.shadow-ring"))
	check("bh_enter recorded on arrival", v.archive_events == ["bh_enter"])
	# star light: no star at Sgr A*, the moody key returns
	demo.star_light.energy = 2.0
	demo.star_light.update(demo.lighting, demo.sky, 0.0, true)
	var key: DirectionalLight3D = demo.lighting.key
	check("no star: star light off, ship key at its moody base", demo.star_light.source_id == "" and demo.star_light.light.light_energy == 0.0 and absf(key.light_energy - float(demo.lighting.key_base)) < 1e-9 and key.shadow_enabled)
	check("star-light HUD line says ship lights only", demo.star_light.hud_line().contains("ship lights only"))
	# the scripted stops
	var stops := [[10.0, "hover"], [5.0, "hover"], [3.0, "hover"], [3.0, "orbit"], [3.0, "hover"]]
	var ticks_to_10 := 0
	for s in stops.size():
		check("next stop %d accepted" % (s + 1), demo.bh_next_stop())
		var n := 0
		while v.sim.gr.mode == "approach" and n < 2000:
			demo.bh_tick()
			n += 1
		if s == 0: ticks_to_10 = n
		for i in 3: demo.bh_tick()
		check("stop %d: %s at r = %s" % [s + 1, stops[s][1], stops[s][0]], float(v.sim.gr.r) == stops[s][0] and v.sim.gr.mode == stops[s][1])
		check("stop %d: HUD equals the sim's gr" % (s + 1), hud_has(demo, v.sim.gr) and demo.sky.gr_lens.state == v.sim.gr)
		# literal readings from the real sim (design AC-11 values), not the formatter's own output
		var lit: Array = LITERALS.get(s, [])
		var missing := lit.filter(func(x: String) -> bool: return not demo.label.text.contains(x))
		if not lit.is_empty():
			check("stop %d: the HUD reads %s" % [s + 1, lit], missing.is_empty())
	check("approach 10^6 -> 10 r_s paced in 200..800 ticks at 20 Hz (%d)" % ticks_to_10, ticks_to_10 >= 200 and ticks_to_10 <= 800)
	check("past the last stop, next stop is refused", not demo.bh_next_stop())
	var unlocked: Array = GalaxyMap.field_value(v.sim.world, "consequence.archive.unlocked")
	check("the black-hole Archive entries (first_black_hole: tides, shadow-ring) unlocked by the sim", unlocked == first + ["archive.tides", "archive.shadow-ring"])
	check("codex toasts them after the arrival entries", demo.codex.toast_log == first + ["archive.tides", "archive.shadow-ring"])
	# the ring path: the sky flags a ring star -> the client reports it once -> the sim echoes bh_ring
	demo.sky.gr_lens.ring = PackedInt32Array([0])
	demo.bh_tick()
	demo.bh_tick()
	demo.sky.gr_lens.ring = PackedInt32Array()
	check("the three black-hole Archive events in order: bh_enter, bh_hover, bh_ring (%s)" % [v.archive_events], v.archive_events == ["bh_enter", "bh_hover", "bh_ring"])
	check("codex rows open", not demo.codex.entry_rows()["archive.tides"].disabled and not demo.codex.entry_rows()["archive.shadow-ring"].disabled)
	demo.toggle_codex()
	check("C opens the codex on an entry", demo.codex.panel.visible and demo.codex.select("archive.shadow-ring") and demo.codex.binding_ok())
	demo.toggle_codex()
	# leaving: GR off
	var sim_ref: SimBridge = v.sim
	demo.leave_black_hole()
	check("leaving stops the sim, GR off, flat rest sky", demo.black_hole == null and sim_ref._pid < 0 and not demo.sky.gr_lens.active and demo.sky_state == "rest" and not demo.sky_world.has("gr"))
	demo._process(0.0)
	check("the HUD drops the black-hole lines, GR off", not demo.label.text.contains("Sgr A*") and not demo.label.text.contains("HOVERING"))
	demo.open_navigation()
	check("navigation after the visit is a normal 2.7 session without gr", demo.journey_sim != null and demo.journey_sim.want_minor == SimBridge.STOPS_MINOR and not demo.journey_sim.world.has("gr") and not demo.sky.gr_lens.active)
	demo.close_navigation()
	# --scenario through setup options (make run-bh)
	demo.queue_free()
	await process_frame
	var d2: Node = load("res://demos/ship_geometry_demo.tscn").instantiate()
	d2.setup_options = {"stars": false, "background": false, "scenario": "sgr_a"}
	root.add_child(d2)
	d2.auto = false
	d2.journey_auto_tick = false
	for i in 3: await process_frame
	check("scenario sgr_a from the launch starts the visit", d2.black_hole != null and d2.black_hole.sim.gr.get("hole_id", "") == "Sgr A*" and d2.journey_sim == null)
	d2._process(0.016)
	check("HUD at launch: GR on, the sim's lines", d2.label.text.contains("Sgr A*") and hud_has(d2, d2.black_hole.sim.gr))
	var tick0: int = d2.black_hole.sim.world.tick
	check("K: an approach finishes in one tick (lands exactly, hovers the rest)", d2.bh_next_stop() and d2.bh_finish_approach() and d2.black_hole.sim.world.tick > tick0 + 1 and d2.black_hole.sim.world.tick <= tick0 + 16 and float(d2.black_hole.sim.gr.r) == 10.0 and d2.black_hole.sim.gr.mode == "hover")
	d2.queue_free()
	await process_frame

func hud_has(demo: Node, gr: Dictionary) -> bool:
	demo._process(0.0)
	var text: String = demo.label.text
	for line: String in Visit.hud_lines(gr):
		if not text.contains(line):
			print("    HUD lacks: %s" % line)
			return false
	return true
