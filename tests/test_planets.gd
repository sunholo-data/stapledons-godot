extends SceneTree
## M5.2a planets, headless (make planets-test): SystemView fed the sim's recorded
## `system` section (tests/fixtures/system_sol.ndjson, M5.1b), the point/disc
## switch and its flux continuity, the starfield handoff, placement precision
## (gate 5), and the albedo table against the sim's data. Exits non-zero on failure.

const FIXTURE := "res://tests/fixtures/system_sol.ndjson"
const AU := 149597870.7
const E1 := 127057.41052085394 # relativity illuminanceFromV(-26.74), the sim's Sun at 1 AU (probe)
const PX_RAD := 2.0 * 0.7002075382097097 / 540.0 # centre pixel of the 70 deg, 540 px golden view: 2 tan(35 deg) / 540

var failures := 0
var passes := 0


func check(name: String, ok: bool, detail := "") -> void:
	if ok:
		passes += 1
		print("  ok    %s %s" % [name, detail])
	else:
		failures += 1
		print("  FAIL  %s %s" % [name, detail])


func _system() -> Dictionary:
	for line in FileAccess.get_file_as_string(FIXTURE).split("\n"):
		var m = JSON.parse_string(line) if line.strip_edges() != "" else null
		if typeof(m) == TYPE_DICTIONARY and m.get("type") == "state" and m["changes"].has("system"):
			return SimBridge.parse_system(m["changes"]["system"])
	return {}


func _body(sys: Dictionary, id: String) -> Dictionary:
	for b: Dictionary in sys["bodies"]:
		if b["id"] == id:
			return b
	return {}


func _view() -> Array:
	var sf := Starfield.new()
	sf.set_custom_stars([])
	sf.build()
	var sv := SystemView.new()
	sv.setup(sf, false)
	sv.set_view(PX_RAD, 540.0)
	root.add_child(sf)
	root.add_child(sv)
	return [sv, sf]


## A synthetic body seen from distance d (km) straight down world -Z (galactic +x),
## lit from behind the observer (opposition); every field the sim sends.
func _synthetic(id: String, radius: float, d: float, lux: float) -> Dictionary:
	return {"id": id, "name": id, "kind": "planet", "host": "", "status": "confirmed",
		"rel_km": {"x": d, "y": 0.0, "z": 0.0}, "radius_km": radius, "flattening": 0.0,
		"pole": {"x": 0.0, "y": 0.0, "z": 1.0}, "w_deg": 0.0, "sun_dir": {"x": -1.0, "y": 0.0, "z": 0.0},
		"r_au": 5.2, "phase_deg": 0.0, "e_v_lux": lux, "p_v": 0.538, "minnaert_k": 1.0, "ring_id": "",
		"light_age_s": 0.0, "visitable": true, "source": "test"}


func test_fixture_view() -> void:
	print("SystemView on the sim's recorded Sol section (ship at the Sun's centre, tick 0)")
	var sys := _system()
	check("fixture system section parses (21 bodies)", sys.get("bodies", []).size() == 21)
	var v := _view()
	var sv: SystemView = v[0]
	var sf: Starfield = v[1]
	sv.update(sys, 1.0)
	check("the Sun is skipped from inside it", not sv.drawn_points.has("sun") and not sv.drawn_discs.has("sun"))
	check("from the Sun every planet is a point at 70 deg / 540 px (none reaches 2 px)", sv.drawn_discs.is_empty() and sv.drawn_points.has("jupiter") and sv.drawn_points.has("neptune"), str(sv.drawn_points.size()))
	check("e1 recovered from a lit body's own row = the sim's Sun at 1 AU (1e-9)", absf(sv.e1_au / E1 - 1.0) < 1e-9, "%.6f" % sv.e1_au)
	# the point handed to the starfield gives back the sim's e_v_lux at the ship, in the sim's direction
	var j := _body(sys, "jupiter")
	var k := sv.drawn_points.find("jupiter")
	var w := Planets.world_of(j["rel_km"])
	var dist := Planets.length64(w)
	var p := k * 3
	var dx: float = sf._point_pos[p] - sf.ship[0]
	var dy: float = sf._point_pos[p + 1] - sf.ship[1]
	var dz: float = sf._point_pos[p + 2] - sf.ship[2]
	var r := sqrt(dx * dx + dy * dy + dz * dz)
	var cosang := (dx * w[0] + dy * w[1] + dz * w[2]) / (r * dist)
	check("point direction = rel_km through galactic_to_world (float64, < 1e-12 rad)", acos(minf(cosang, 1.0)) < 1e-12)
	var at_ship: float = sf._point_custom[4 * k + 1] * sf._point_custom[4 * k + 3] / (r * r)
	check("point flux at the ship = e_v_lux (float32 custom data, 1e-6)", absf(at_ship / j["e_v_lux"] - 1.0) < 1e-6, "%s lux" % String.num_scientific(at_ship))
	check("point colour = the solar T 5772 K", sf._point_custom[4 * k] == Planets.T_SUN)
	var dim := sys.duplicate(true)
	for b: Dictionary in dim["bodies"]:
		b["e_v_lux"] *= 1e-12
	sv.update(dim, 1.0)
	check("bodies 1e-12 dimmer and under 0.1 px are culled (no points)", sv.drawn_points.is_empty() and sf.point_count == 0)
	sv.update({}, 1.0)
	check("an empty section clears every point and disc", sf.point_count == 0 and sv.drawn_discs.is_empty())
	sv.queue_free()
	sf.queue_free()


func test_point_disc_switch() -> void:
	print("Point / disc switch at Planets.DISC_PX and its flux continuity (G-M5-6, CPU half)")
	var v := _view()
	var sv: SystemView = v[0]
	var sf: Starfield = v[1]
	var r := 71492.0
	var lux_at := func(d: float) -> float: return Planets.disc_illuminance(E1, 0.538, r, 5.2, d, 0.0, 1.0)
	for px: float in [1.9, 2.1]:
		var d := r / sin(px * PX_RAD / 2.0)
		var b := _synthetic("jupiter", r, d, lux_at.call(d))
		sv.update({"jd": 0.0, "ephemeris": "jpl-approx", "frame": "galactic", "bodies": [b]}, 1.0)
		var as_disc := px >= 2.0
		check("%.1f px across is a %s" % [px, "disc" if as_disc else "point"], sv.drawn_discs.has("jupiter") == as_disc and sv.drawn_points.has("jupiter") != as_disc)
		# the disc's radiance integrates to the same e_v_lux the point would carry
		var rho := Planets.rho_from_geometric_albedo(0.538, 1.0)
		var integral := Planets.integrate_disc(rho, 1.0, Planets.star_illuminance_at(E1, 5.2), 0.0, Planets.angular_radius(r, d), 400)
		check("%.1f px: disc integral of the drawn radiance / e_v_lux (0.2%%)" % px, absf(integral / lux_at.call(d) - 1.0) < 0.002, "%.5f" % (integral / lux_at.call(d)))
	var d21 := r / sin(2.1 * PX_RAD / 2.0)
	var mi: MeshInstance3D = sv.discs["jupiter"]
	var m: ShaderMaterial = mi.material_override
	check("disc shader lux = starIlluminanceAt(e1, r_au) (e1 from the body's own row)", absf(m.get_shader_parameter("lux") / Planets.star_illuminance_at(E1, 5.2) - 1.0) < 1e-6)
	check("disc shader rho = rhoFromGeometricAlbedo(p_V, k)", is_equal_approx(m.get_shader_parameter("rho"), 0.807))
	check("small disc supersampled 8 x 8 per pixel", m.get_shader_parameter("ss") == 8)
	check("disc drawn after the stars (render_priority >= 1)", m.render_priority >= 1)
	var sd: Vector3 = m.get_shader_parameter("sun_dir_w")
	check("sun_dir galactic -x -> world +Z (galactic_to_world)", sd.distance_to(Vector3(0, 0, 1)) < 1e-6)
	sv.queue_free()
	sf.queue_free()
	return


func test_placement_precision() -> void:
	print("Placement (gate 5): float64 direction and asin(R / d), the group scaled by PLACE / d")
	for c: Array in [[71492.0, 4.2 * AU], [1737.4, 384400.0], [60268.0, 1.2e6], [2440.0, 1.38 * AU]]:
		var rel := {"x": c[1] * 0.6, "y": -c[1] * 0.48, "z": c[1] * 0.64}
		var pl := Planets.place(rel, c[0])
		var centre: Vector3 = pl[1]
		var got := asin(pl[2] / centre.length())
		var want := asin(c[0] / Planets.length64(Planets.world_of(rel)))
		check("R %.0f km at %s km: angular radius from the float32 placement / float64 (1e-6)" % [c[0], String.num_scientific(c[1])], absf(got / want - 1.0) < 1e-6, String.num_scientific(want) + " rad")
		check("  centre is PLACE units out (no raw km in a Vector3)", absf(centre.length() - Planets.PLACE) < 1e-5)
	var bas := Planets.body_basis({"x": 0.0, "y": 0.0, "z": 1.0}, 90.0)
	check("body basis is orthonormal (pole -> world z column)", absf(bas.x.dot(bas.y)) < 1e-6 and absf(bas.z.distance_to(Starfield.galactic_to_world(Vector3(0, 0, 1)))) < 1e-6)


func test_albedo_table() -> void:
	print("Albedo table (data/planets/ALBEDO) against the sim's data and the pins")
	var t := SystemView.read_albedo_table(SystemView.ALBEDO_TABLE)
	var sys := _system()
	var sums := FileAccess.get_file_as_string("res://data/planets/SHA256SUMS")
	check("nine textured bodies", t.size() == 9, str(t.keys()))
	for id: String in t:
		var b := _body(sys, id)
		var row: Dictionary = t[id]
		var pinned := true
		for f: String in String(row["file"]).split("+"):
			pinned = pinned and sums.contains(" texture assets/planets/%s\n" % f)
		check("%s: k = the sim's minnaert_k, files pinned, mean in (0, 1]" % id, not b.is_empty() and is_equal_approx(row["k"], b["minnaert_k"]) and pinned and row["mean"] > 0.0 and row["mean"] <= 1.0)
	var credits := FileAccess.get_file_as_string("res://data/planets/CREDITS")
	check("CREDITS carries the CC BY 4.0 attribution and the licence URL", credits.contains("CC BY 4.0") and credits.contains("https://creativecommons.org/licenses/by/4.0/") and credits.contains("Solar System Scope"))


func _initialize() -> void:
	test_fixture_view()
	test_point_disc_switch()
	test_placement_precision()
	test_albedo_table()
	await process_frame
	print("\n%d passed, %d failed" % [passes, failures])
	quit(1 if failures > 0 else 0)
