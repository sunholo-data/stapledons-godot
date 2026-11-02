extends SceneTree
## W2.4 review artefacts only; no runtime scene, UI, or protocol mutation.
## Public-data emitter: tools/worlds_dev.sh run --strict-bytecode --caps IO
##   --entry main sim/tools/worlds_mock_data.ail > .godot/worlds_mock/public-data.json
## Capture: godot --path . --rendering-method gl_compatibility --script tools/worlds_mockup.gd
const PX := Vector2i(1600, 1000)
var out := "res://renders/worlds_v1"
var sheet: MockSheet


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
	var raw := FileAccess.get_file_as_string("res://.godot/worlds_mock/public-data.json")
	var payload: Variant = JSON.parse_string(raw)
	if not (payload is Dictionary) or int(payload.get("known_host_count", 0)) != 241:
		push_error("worlds-mock: missing/invalid public data or changed host count")
		quit(1)
		return
	if not FileAccess.file_exists("res://tools/worlds_mockup.gd.uid"):
		var uid := FileAccess.open("res://tools/worlds_mockup.gd.uid", FileAccess.WRITE)
		uid.store_string(ResourceUID.id_to_text(ResourceUID.create_id()) + "\n")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	root.size = PX
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.content_scale_size = PX
	root.title = "Worlds · review mock-up"
	sheet = MockSheet.new()
	sheet.public_data = payload
	sheet.catalogue = JSON.parse_string(FileAccess.get_file_as_string("res://data/starmap/stars.json"))
	var name_data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/starmap/names.json"))
	for n: Dictionary in name_data.names:
		sheet.names[str(n.id)] = str(n.name)
	root.add_child(sheet)
	for capture: Array in [["map_25ly", 25.0], ["map_81ly", 81.0], ["trappist1_strip", 0.0], ["alpha_cen_a_strip", 0.0]]:
		sheet.mode = capture[0]
		sheet.range_ly = capture[1]
		sheet.queue_redraw()
		for frame in 3:
			await process_frame
		await RenderingServer.frame_post_draw
		var image := root.get_texture().get_image()
		if image.get_size() != PX or image.save_png(out.path_join(str(capture[0]) + ".png")) != OK:
			push_error("worlds-mock: failed capture " + str(capture[0]))
			quit(1)
			return
		print("worlds-mock: %s %dx%d" % [capture[0], image.get_width(), image.get_height()])
	print("worlds-mock: 4 public-data review frames; awaiting Mark")
	quit(0)


class MockSheet extends Node2D:
	const T := preload("res://ui/stapledon_theme.gd")
	var public_data: Dictionary
	var catalogue: Dictionary
	var names: Dictionary = {}
	var mode := "map_25ly"
	var range_ly := 25.0
	var display: Font
	var text: Font
	var bold: Font
	var map_centre := Vector2(580, 545)
	var map_radius := 350.0

	func _ready() -> void:
		display = T._font(T.DISPLAY_FONT, 600)
		text = T._font(T.TEXT_FONT, 500)
		bold = T._font(T.TEXT_FONT, 750)

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, Vector2(PX)), T.NIGHT)
		# A restrained echo of the HUD's hand-inked panel, not a new skin.
		draw_style_box(T.theme().get_stylebox("panel", "HUDSheet"), Rect2(28, 24, 1544, 952))
		if mode.begins_with("map"):
			_map()
		else:
			_strip("Gaia DR3 2635476908753563008" if mode == "trappist1_strip" else "CNS5:3627")
		_line(Vector2(60, 960), "R3 Worlds · review mock-up · awaiting Mark", 15, T.DIM)

	func _line(p: Vector2, s: String, size := 20, colour := T.CREAM, heading := false, weight := false) -> void:
		draw_string(display if heading else (bold if weight else text), p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, colour)

	func _centre(p: Vector2, s: String, size := 20, colour := T.CREAM, heading := false) -> void:
		var font: Font = display if heading else text
		var width := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		draw_string(font, p - Vector2(width / 2.0, 0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, colour)

	func _rule(y: float, x0 := 60.0, x1 := 1540.0) -> void:
		draw_line(Vector2(x0, y), Vector2(x1, y), Color(T.CREAM, 0.17), 1.0, true)

	func _dash(c: Vector2, r: float, colour: Color, width := 1.4) -> void:
		for k in 16:
			var a := TAU * float(k) / 16.0
			draw_arc(c, r, a, a + TAU / 28.0, 5, colour, width, true)

	func _planet_ring(c: Vector2, r: float, planet: Dictionary, faint := false) -> void:
		var colour: Color = T.MINT if str(planet.hab) != "not_habitable" else T.OCHRE_LIGHT
		if faint:
			colour.a = 0.75
		if str(planet.prov) == "candidate":
			_dash(c, r, colour)
		else:
			draw_arc(c, r, 0, TAU, 48, colour, 1.2, true)

	func _project(x: float, y: float) -> Vector2:
		return map_centre + Vector2(x, -y) * (map_radius / range_ly)

	func _host_name(h: Dictionary) -> String:
		return str(names.get(str(h.id), h.name))

	func _host(id: String) -> Dictionary:
		for h: Dictionary in public_data.hosts:
			if str(h.id) == id:
				return h
		return {}

	func _map() -> void:
		_line(Vector2(60, 84), "Known worlds", 46, T.CREAM, true)
		_line(Vector2(62, 123), "Earth's catalogue · Galactic XY projection · %d light-year sphere" % int(range_ly), 22, T.OCHRE_LIGHT)
		draw_circle(Vector2(1405, 79), 5, T.MINT)
		_line(Vector2(1420, 86), "Worlds on", 20, T.MINT)
		_rule(151)
		# This is a true 3D catalogue-distance cut, projected onto Galactic XY.
		for fraction: float in [0.25, 0.5, 0.75, 1.0]:
			draw_arc(map_centre, map_radius * fraction, 0, TAU, 120, Color(T.TEAL_LIGHT, 0.11), 1.0, true)
		draw_line(map_centre - Vector2(map_radius + 32, 0), map_centre + Vector2(map_radius + 32, 0), Color(T.TEAL_LIGHT, 0.2), 1, true)
		draw_line(map_centre - Vector2(0, map_radius + 5), map_centre + Vector2(0, map_radius + 5), Color(T.TEAL_LIGHT, 0.2), 1, true)
		_line(map_centre + Vector2(map_radius + 14, -8), "+X", 16, T.DIM)
		_line(map_centre - Vector2(12, map_radius + 18), "+Y", 16, T.DIM)
		var stars_visible := 0
		for star: Dictionary in catalogue.stars:
			var distance := sqrt(float(star.x) * float(star.x) + float(star.y) * float(star.y) + float(star.z) * float(star.z))
			if distance > range_ly:
				continue
			stars_visible += 1
			var p := _project(float(star.x), float(star.y))
			var light := clampf((15.0 - float(star.vmag)) / 18.0, 0.1, 1.0)
			draw_circle(p, 0.7 + 1.3 * light, Color(T.CREAM, 0.16 + light * 0.33))
		var visible: Array[Dictionary] = []
		var planet_count := 0
		for h: Dictionary in public_data.hosts:
			if float(h.distance_ly) > range_ly:
				continue
			visible.append(h)
			planet_count += h.planets.size()
			var p := _project(float(h.x), float(h.y))
			for k in h.planets.size():
				_planet_ring(p, 5.0 + 2.7 * k, h.planets[k], true)
			draw_circle(p, 2.3, T.CREAM)
			if _debated(h):
				_line(p + Vector2(10 + h.planets.size() * 2.4, -5), "?", 18, T.MINT, false, true)
		# Sol marks the reference origin. No invented worlds or planet layers.
		draw_circle(map_centre, 4, T.CREAM)
		draw_arc(map_centre, 9, 0, TAU, 32, T.CREAM, 1.2, true)
		_line(map_centre + Vector2(-24, 34), "Sol", 22, T.CREAM, true)
		_callout("Gaia DR3 5853498713190525696", Vector2(86, 54), "α Cen A / Proxima")
		if range_ly > 40:
			_callout("Gaia DR3 2635476908753563008", Vector2(48, 40), "TRAPPIST-1")
			_callout("Gaia DR3 2452378776434477184", Vector2(-126, -35), "τ Ceti")
		else:
			_callout("Gaia DR3 4472832130942575872", Vector2(50, -30), "Barnard's Star")
		# Scale is in the projected plane; exact 3D distances remain catalogue facts.
		var scale_ly := 5.0 if range_ly < 30 else 20.0
		var bar := scale_ly * map_radius / range_ly
		draw_line(Vector2(110, 864), Vector2(110 + bar, 864), T.CREAM, 2, true)
		for xx: float in [110.0, 110.0 + bar]:
			draw_line(Vector2(xx, 858), Vector2(xx, 870), T.CREAM, 2, true)
		_line(Vector2(110, 893), "%d ly" % int(scale_ly), 17, T.DIM)
		_map_legend(visible.size(), planet_count, stars_visible)
		_rule(913)
		_line(Vector2(60, 940), "Catalogue positions; known planets. Green: rocky HZ match. HZ clamps outside 2600–7200 K; ? = M-dwarf debate. No life claim.", 16, T.DIM)

	func _debated(h: Dictionary) -> bool:
		for p: Dictionary in h.planets:
			if str(p.hab) == "habitability_debated":
				return true
		return false

	func _callout(id: String, offset: Vector2, title: String) -> void:
		var h := _host(id)
		if h.is_empty() or float(h.distance_ly) > range_ly:
			return
		var p := _project(float(h.x), float(h.y))
		var end := p + offset
		draw_line(p + offset.normalized() * 21, end, Color(T.CREAM, 0.5), 1, true)
		draw_string_outline(display, end + Vector2(4, 0), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, 5, T.NIGHT)
		_line(end + Vector2(4, 0), title, 20, T.CREAM, true)

	func _map_legend(hosts: int, planets: int, stars: int) -> void:
		var x := 1120.0
		draw_line(Vector2(x - 35, 197), Vector2(x - 35, 863), Color(T.CREAM, 0.15), 1, true)
		_line(Vector2(x, 215), "What we know", 29, T.CREAM, true)
		_line(Vector2(x, 252), "%d host systems in view" % hosts, 21, T.OCHRE_LIGHT)
		_line(Vector2(x, 283), "%d known planets / %d stars" % [planets, stars], 18, T.DIM)
		_planet_ring(Vector2(x + 11, 334), 10, {"hab": "not_habitable", "prov": "measured"})
		_line(Vector2(x + 37, 342), "Measured planet", 20)
		_planet_ring(Vector2(x + 11, 382), 10, {"hab": "not_habitable", "prov": "candidate"})
		_line(Vector2(x + 37, 390), "Candidate", 20)
		_planet_ring(Vector2(x + 11, 430), 10, {"hab": "habitable", "prov": "measured"})
		_line(Vector2(x + 37, 438), "Rocky, conservative zone", 19, T.MINT)
		_line(Vector2(x + 2, 486), "?", 24, T.MINT, false, true)
		_line(Vector2(x + 37, 484), "Habitability debated", 19, T.MINT)
		_rule(523, x, 1525)
		_line(Vector2(x, 561), "241 known hosts", 27, T.CREAM, true)
		_line(Vector2(x, 593), "in the current 25 pc registry", 19, T.DIM)
		_line(Vector2(x, 649), "A ring for each known planet.", 18)
		_line(Vector2(x, 680), "No ring means no catalogue claim.", 17, T.DIM)
		_line(Vector2(x, 739), "NASA PS · 2 November 2026", 18, T.OCHRE_LIGHT)
		_line(Vector2(x, 770), "Curated α Cen and TRAPPIST-1", 17, T.DIM)
		_line(Vector2(x, 798), "values are retained.", 17, T.DIM)
		_line(Vector2(x, 855), "XY flattens height above the plane.", 17, T.DIM)

	func _axis_x(value: float, lo: float, hi: float) -> float:
		return 190.0 + log(value / lo) / log(hi / lo) * 1250.0

	func _temperature(p: Dictionary) -> Color:
		if p.teq_k == null:
			return T.DIM
		var v := clampf((float(p.teq_k) - 170.0) / 260.0, 0.0, 1.0)
		return T.TEAL_LIGHT.lerp(T.MINT, v * 2.0) if v < 0.5 else T.MINT.lerp(T.CORAL, (v - 0.5) * 2.0)

	func _strip(id: String) -> void:
		var h := _host(id)
		var trappist := id.begins_with("Gaia")
		var title := "TRAPPIST-1" if trappist else "α Centauri A"
		var zone: Dictionary = h.offline_inferred_zone
		_line(Vector2(60, 84), title, 48, T.CREAM, true)
		_line(Vector2(62, 125), "%s · %.2f ly · %s" % [(str(h.spectral_type) if not str(h.spectral_type).is_empty() else "Teff %.0f K" % float(zone.teff_actual)), h.distance_ly, "7 measured planets" if trappist else "1 candidate planet"], 23, T.OCHRE_LIGHT)
		_line(Vector2(1230, 80), "System strip", 26, T.CREAM, true)
		_line(Vector2(1230, 116), "Catalogue + inferred zone", 18, T.DIM)
		_rule(152)
		_line(Vector2(60, 205), "Orbits and irradiation", 28, T.CREAM, true)
		_line(Vector2(60, 240), "Measured or fitted orbits; the green band is an irradiation model.", 21, T.DIM)
		var lo := 0.008 if trappist else 0.2
		var hi := 0.085 if trappist else 4.0
		var y := 440.0
		var inner := _axis_x(float(zone.inner_au), lo, hi)
		var outer := _axis_x(float(zone.outer_au), lo, hi)
		draw_rect(Rect2(inner, y - 77, outer - inner, 154), Color(T.MINT, 0.14))
		draw_line(Vector2(inner, y - 77), Vector2(inner, y + 77), Color(T.MINT, 0.65), 1.5, true)
		draw_line(Vector2(outer, y - 77), Vector2(outer, y + 77), Color(T.MINT, 0.65), 1.5, true)
		_centre(Vector2((inner + outer) / 2.0, 300), "Inferred conservative zone", 23, T.MINT, true)
		_centre(Vector2((inner + outer) / 2.0, 328), "%.5f–%.5f AU" % [zone.inner_au, zone.outer_au] if trappist else "%.2f–%.2f AU" % [zone.inner_au, zone.outer_au], 18, T.MINT)
		draw_line(Vector2(130, y), Vector2(1460, y), Color(T.CREAM, 0.27), 1.5, true)
		draw_circle(Vector2(115, y), 45, Color(T.OCHRE_LIGHT, 0.12))
		draw_arc(Vector2(115, y), 34, 0, TAU, 80, T.CREAM, 2, true)
		for angle in 12:
			var v := Vector2.from_angle(TAU * angle / 12.0)
			draw_line(Vector2(115, y) + v * 42, Vector2(115, y) + v * 50, Color(T.CREAM, 0.7), 1.5, true)
		_centre(Vector2(115, y + 94), "star", 18, T.DIM)
		for p: Dictionary in h.planets:
			_draw_planet(p, trappist, y, lo, hi)
		var ticks: Array = [0.01, 0.02, 0.04, 0.08] if trappist else [0.25, 0.5, 1.0, 2.0, 4.0]
		for tick: float in ticks:
			var xx := _axis_x(tick, lo, hi)
			draw_line(Vector2(xx, 693), Vector2(xx, 704), Color(T.CREAM, 0.5), 1, true)
			_centre(Vector2(xx, 730), str(tick), 18, T.DIM)
		_line(Vector2(60, 730), "AU (log)", 18, T.DIM)
		_rule(762)
		if trappist:
			_line(Vector2(60, 803), "e, f, g: rocky planets in the zone · habitability debated around this M dwarf.", 23, T.MINT)
			_line(Vector2(60, 841), "HZ model clamped: stellar Teff %.0f K, model edge %.0f K. Atmospheres are not established." % [zone.teff_actual, zone.teff_used], 19, T.CORAL)
			_line(Vector2(60, 881), "Radii measured (Agol et al. 2021). Teq and colour inferred; Bond albedo 0.3 assumed.", 18, T.DIM)
		else:
			_line(Vector2(60, 803), "α Cen A b remains a candidate. The displayed orbit and radius are model-dependent fits.", 23, T.OCHRE_LIGHT)
			_line(Vector2(60, 841), "1.66 AU is one orbit family; 11.77 R⊕ is inferred from photometry and atmosphere models.", 19, T.DIM)
			_line(Vector2(60, 881), "Beichman et al. 2025; curated catalogue. Teq and colour inferred; Bond albedo 0.3 assumed. No life claim.", 18, T.DIM)
		_line(Vector2(60, 920), "Kopparapu et al. 2014 conservative zone. Planet sizes are relative within this strip; star symbol is off scale.", 16, T.DIM)

	func _draw_planet(p: Dictionary, trappist: bool, y: float, lo: float, hi: float) -> void:
		if p.a_au == null:
			return
		var x := _axis_x(float(p.a_au), lo, hi)
		var radius := (26.0 if trappist else 8.0) * float(p.radius_earth) if p.radius_earth != null else 12.0
		draw_circle(Vector2(x, y), radius, _temperature(p))
		if str(p.prov) == "candidate":
			_dash(Vector2(x, y), radius + 7, T.OCHRE_LIGHT, 2.3)
		else:
			draw_arc(Vector2(x, y), radius + 5, 0, TAU, 70, T.MINT if str(p.hab) != "not_habitable" else Color(T.CREAM, 0.65), 1.5, true)
		if str(p.hab) == "habitability_debated":
			_line(Vector2(x + radius + 10, y - 12), "?", 26, T.MINT, false, true)
		var base := 524.0 if trappist else 578.0
		var name := str(p.name).trim_prefix("TRAPPIST-1 ") if trappist else "α Cen A b"
		_centre(Vector2(x, base), name, 27 if trappist else 30, T.CREAM, true)
		_centre(Vector2(x, base + 32), "%.3f R⊕" % float(p.radius_earth) if p.radius_earth != null else "radius unknown", 19, T.CREAM)
		_centre(Vector2(x, base + 61), "%.5f AU" % float(p.a_au) if trappist else "%.2f AU · fitted" % float(p.a_au), 17, T.DIM)
		_centre(Vector2(x, base + 89), "%.0f K" % float(p.teq_k) if p.teq_k != null else "Teq unknown", 16, T.DIM)
		_centre(Vector2(x, base + 117), "measured" if trappist else "candidate · inferred radius", 16, T.MINT if trappist else T.OCHRE_LIGHT)
