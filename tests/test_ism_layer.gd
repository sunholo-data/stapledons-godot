extends SceneTree
## R1-ISM-DUST I6 (AC16): the galaxy map's medium layer (ui/ism_layer.gd). Headless:
##   godot --headless --path . --script tests/test_ism_layer.gd      (make map-ism-test)
## Every medium in data/ism/ism.json is drawn; the LIC mirror matches the package's surface
## (oracle values); the route is cut into the plan's media pieces; the layer key is a display
## control (the map sends no intent for it).

## tools/ism_dust_ref.py: the refit LIC radius (ly) about its centre along 5 directions.
const RADII := [[1.0, 0.0, 0.0, 6.3207963920158114], [0.0, 1.0, 0.0, 4.245406215078469], [0.0, 0.0, 1.0, 4.3229181413380315],
	[-0.6, 0.48, 0.64, 5.61577715636754], [0.3, -0.4, -0.866, 4.989272269477462]]

var failures := 0
var passes := 0


func check(name: String, ok: bool, detail := "") -> void:
	if ok:
		passes += 1
		print("  ok    %s" % name)
	else:
		failures += 1
		print("  FAIL  %s %s" % [name, detail])


func _init() -> void:
	var layer := IsmLayer.new()
	check("data/ism/ism.json loads (model lism-1)", layer.load_model() and layer.model.get("model") == "lism-1")
	var clouds: Array = layer.model.get("clouds", [])
	check("14 Redfield & Linsky clouds and the LIC in the model", clouds.size() == 14 and layer.model.lic.coeffs_ly.size() == 9)
	var worst := 0.0
	for r: Array in RADII:
		worst = maxf(worst, absf(IsmLayer.surface_radius64(layer.model.lic.coeffs_ly, r[0], r[1], r[2]) - r[3]) / r[3])
	check("LIC mirror = celestial.ism.starSurfaceRadius (oracle, 5 directions, worst %s)" % String.num_scientific(worst), worst < 1e-12)
	var finite := true
	for line: PackedVector3Array in layer.lic_lines():
		for p: Vector3 in line:
			finite = finite and p.is_finite() and p.length() < 50.0
	check("LIC mesh: 17 finite lines within 50 ly", layer.lic_lines().size() == 17 and finite)
	var all_ok := true
	for cl: Dictionary in clouds:
		var lines := IsmLayer.cloud_lines(cl)
		all_ok = all_ok and lines.size() >= 7
	check("every cloud has an angular outline and radial generators", all_ok)
	var traced := {"r_in_ly": 1.0, "r_out_ly": 2.0, "outline": [
		[[1, -0.1, -0.1], [1, 0.1, -0.1], [1, 0.1, 0.1]],
		[[1, -0.1, -0.1], [1, 0.1, 0.1], [1, -0.1, 0.1]]]}
	var boundary := IsmLayer.cloud_lines(traced)
	check("triangulated source outline: four boundary edges, no internal diagonal", boundary.size() == 12)
	var radial_ok := true
	for line: PackedVector3Array in boundary:
		if line.size() == 17:
			var radius := line[0].length()
			for v: Vector3 in line:
				radial_ok = radial_ok and v.is_finite() and absf(v.length() - radius) < 0.000001
	check("outline arcs follow the shell radius", radial_ok)
	check("one log colour scale: hot gas, warm clouds and a dense cloud differ",
		IsmLayer.colour_for(0.0039) != IsmLayer.colour_for(0.2474) and IsmLayer.colour_for(0.2474) != IsmLayer.colour_for(3000.0))
	var media := [{"name": "LIC", "n_h_cm3": 0.2474, "length_ly": 2.0}, {"name": "hot", "n_h_cm3": 0.0039, "length_ly": 6.0}]
	var pieces := IsmLayer.route_pieces(Vector3.ZERO, Vector3(8, 0, 0), media)
	check("the route is cut into the plan's media pieces", pieces.size() == 2 and pieces[0].b.is_equal_approx(Vector3(2, 0, 0)) and pieces[1].b.is_equal_approx(Vector3(8, 0, 0)))
	check("labels: LIC, hot gas, a named cloud", IsmLayer.label_of("LIC") == "Local Interstellar Cloud" and IsmLayer.label_of("hot") == "Local Bubble hot gas" and IsmLayer.label_of("Hyades") == "Hyades cloud")
	check("legend names the hot gas and the sources", layer.legend().contains("Snowden 2014") and layer.legend().contains("Redfield & Linsky 2008"))
	# drawing: a camera looking at Sol from 40 ly, the overlay in a viewport
	var vp := SubViewport.new()
	vp.size = Vector2i(1280, 800)
	root.add_child(vp)
	var cam := Camera3D.new()
	vp.add_child(cam)
	cam.look_at_from_position(Vector3(0, 0, 40), Vector3.ZERO)
	var ov := Control.new()
	ov.size = Vector2(1280, 800)
	vp.add_child(ov)
	check("hidden by default: draw() draws nothing", layer.draw(ov, cam, func(v: Vector3) -> Vector3: return v) == 0)
	check("D toggles the layer on (a display flag: no sim, no intent)", layer.toggle() and layer.visible)
	ov.draw.connect(func() -> void: layer.draw(ov, cam, func(v: Vector3) -> Vector3: return v, pieces))
	ov.queue_redraw()
	await process_frame
	await process_frame
	var drawn := layer.last_drawn
	var every := drawn.has("LIC")
	for cl: Dictionary in clouds:
		every = every and drawn.has(cl.name)
	check("AC16: every medium in ism.json is drawn (%d)" % drawn.size(), every and drawn.size() == 15)
	print("ism-layer: %d passed, %d failures" % [passes, failures])
	quit(1 if failures > 0 else 0)
