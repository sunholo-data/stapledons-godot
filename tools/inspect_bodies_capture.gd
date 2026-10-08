extends SceneTree
## I-key inspection of the bodies at each guided-tour stop: hold I (rings on the Sun,
## planets, moons, finite stars and exoplanets in view), then the card of the stop's body.
## Output: renders/inspect_bodies/*.png (open them).
const OUT := "res://renders/inspect_bodies"
var demo: Node
func _initialize() -> void: _run.call_deferred()
func settle() -> void:
	for frame in 12: await process_frame
	await RenderingServer.frame_post_draw
func capture(stem: String, target: String) -> bool:
	var identify: Control = demo.star_identification
	identify.close_card(); identify.set_held(true); await settle(); identify.update_candidates(); await settle()
	var names := []
	for c in identify.candidates:
		if c.has("body"): names.append("%s %.0fpx" % [c.body.id, c.radius_px])
	root.get_texture().get_image().save_png(OUT + "/" + stem + "_held.png")
	var ok: bool = identify.inspect_body(target)
	identify.set_held(false); await settle()
	root.get_texture().get_image().save_png(OUT + "/" + stem + "_card.png")
	var text: String = identify.content.get_child(0).text if identify.content.get_child_count() > 0 else ""
	print("INSPECT ", stem, " bodies in view: ", names, " card(", target, "): ", text.replace("\n", " | "))
	return ok
## Let the tour's attitude turn finish (it holds the next leg until the ship faces it).
func turn() -> bool:
	demo._update_tour_attitude(0.)
	await process_frame
	for frame in 1200:
		if not demo.solar_tour.attitude_hold: return true
		if not demo.journey_tick(): return false
		await process_frame
	return not demo.solar_tour.attitude_hold
func _run() -> void:
	root.size = Vector2i(1280, 720); UiScale.configure(root, true)
	DirAccess.make_dir_recursive_absolute(OUT)
	demo = load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options = {"size": root.size, "sky_state": "rest"}; root.add_child(demo); await process_frame
	demo.auto = true; demo.journey_auto_tick = false
	if not demo.start_solar_departure(): print("inspect-bodies-capture: FAIL start"); quit(1); return
	var failed := not await turn()
	failed = not await capture("00_earth", "sun") or failed
	var stops := {"jupiter": "jupiter", "trappist-1": "trappist-1", "aldebaran": "aldebaran"}
	for spec: Dictionary in demo.solar_tour.itinerary.duplicate(true):
		if failed: break
		if not demo.solar_tour.prepare_next(): print("prepare failed ", demo.solar_tour.failed); failed = true; break
		if not await turn(): print("turn failed ", spec.id); failed = true; break
		for i in 200:
			if demo.journey_sim.world.journey.state == "arrived": break
			demo.solar_tour.skip_stage()
			for t in 3:
				if not demo.journey_tick(): failed = true
			await process_frame
		if demo.journey_sim.world.journey.state != "arrived": print("arrival failed ", spec.id); failed = true; break
		if not await turn(): failed = true; break
		if stops.has(spec.id): failed = not await capture("%s" % spec.id, stops[spec.id]) or failed
	print("inspect-bodies-capture: %s" % ("FAIL" if failed else "OK"))
	demo.queue_free(); await process_frame; quit(1 if failed else 0)
