extends SceneTree
## RT4 evidence (D-39/D-40/D-41): one real guided voyage, Earth -> Aldebaran,
## driven through demos/solar_departure.gd exactly as the demo drives it (real
## time, cruise interludes), rendering the frames the design lists. Open every
## PNG in renders/real_time_tour/ before merge; metrics.json records each frame.
##   godot --path . --script tools/real_time_tour_capture.gd   (GPU window)
const SolarDeparture := preload("res://demos/solar_departure.gd")
const OUT := "res://renders/real_time_tour"
var sky: InteriorSky
var card_view: InterludeCard
var tour
var records := []
var frame := 0
var failures := 0

func _initialize() -> void: run.call_deferred()

func run() -> void:
	root.size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(OUT)
	sky = InteriorSky.new(); root.add_child(sky)
	sky.setup({"position_m": [0, 0, 0], "forward": [0, 0, 1], "up": [0, 1, 0]}, 78., root.size, {"stars": true, "background": true, "planet_textures": true})
	var rect := TextureRect.new(); rect.texture = sky.get_texture(); rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.add_child(rect)
	var layer := CanvasLayer.new(); layer.layer = 12; root.add_child(layer)
	card_view = InterludeCard.new(); card_view.visible = false; layer.add_child(card_view)
	sky.exposure.fixed = true; sky.exposure.fixed_ev = sky.exposure.ev_dark() - 2.; sky.set_temporal_exposure(false)
	var sim := SimBridge.new(); sim.want_minor = 5
	if not sim.start() or not sim.new_game(424242, "solar_departure", false, SolarDeparture.guided_params()):
		print("real-time-tour-capture: start FAIL ", sim.last_error); quit(1); return
	var catalogue: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/starmap/stars.json")).get("stars", [])
	tour = SolarDeparture.new()
	if not tour.attach(sim, catalogue): print("real-time-tour-capture: attach FAIL"); quit(1); return
	for leg in tour.itinerary.size():
		if not tour.advance(): print("leg ", leg, " FAIL ", tour.failed); failures += 1; break
		await fly_leg(leg, sim)
	var f := FileAccess.open(OUT.path_join("metrics.json"), FileAccess.WRITE); f.store_string(JSON.stringify(records, "  ")); f.close()
	print("real-time-tour: Earth +%.2f yr, ship +%.3f yr, %d frames" % [sim.world.clock.year, sim.world.clock.tau, records.size()])
	sim.stop()
	print("real-time-tour-capture: %d failures" % failures); quit(1 if failures else 0)

func fly_leg(leg: int, sim: SimBridge) -> void:
	var spec: Dictionary = tour.itinerary[leg]
	var slug := str(spec.get("name", spec.id)).to_lower().replace(" ", "_").replace("—", "").replace("__", "_")
	var long_leg: bool = spec.kind == "star" or spec.id == "acen-a"
	var marks := [0.5, 0.9, 0.99] if spec.kind == "body" else [0.9, 0.99, 0.999, 0.9999, 0.999999]
	var taken := {}
	var card_taken := false
	var braking_taken := false
	for i in 40000:
		if sim.world.journey.state == "arrived": break
		if not tour.step(): print("step FAIL ", tour.failed); failures += 1; return
		var beta: float = float(sim.world.ship.get("beta", 0.0))
		var phase: String = sim.world.ship.phase
		if phase == "boosting":
			for m: float in marks:
				if beta >= m and not taken.has(m) and beta <= float(sim.world.journey.plan.cruise_beta) + 1e-12:
					taken[m] = true
					await shot("%d_%s_boost_b%s_forward" % [leg, slug, str(m)], sim, "forward", false)
					if long_leg and m >= 0.99: await shot("%d_%s_boost_b%s_side" % [leg, slug, str(m)], sim, "side", false)
		if tour.interlude != null and not card_taken and (tour.interlude as CardInterlude).shown() >= 4.0:
			card_taken = true
			await shot("%d_%s_card" % [leg, slug], sim, "forward", true)
		if phase == "cruising" and not taken.has("cruise"):
			taken["cruise"] = true
			await shot("%d_%s_cruise_peak_forward" % [leg, slug], sim, "forward", false)
			if long_leg: await shot("%d_%s_cruise_peak_side" % [leg, slug], sim, "side", false)
		if phase == "braking" and not braking_taken and float(sim.world.ship.get("beta", 0.0)) < 0.5 * float(sim.world.journey.plan.cruise_beta):
			braking_taken = true
			await shot("%d_%s_braking" % [leg, slug], sim, "forward", false, spec.id == "jupiter")
	await shot("%d_%s_arrived" % [leg, slug], sim, "target", false, spec.kind == "body" and spec.id != "acen-a")

func shot(name: String, sim: SimBridge, look: String, with_card: bool, auto_view := false) -> void:
	sky.system_view.body_fader = auto_view
	sky.apply(sim.world)
	var n: Vector3 = sky.heading_world
	if look == "target": n = target_dir(sim.world)
	if look == "side": n = n.cross(Vector3.UP if absf(n.y) < 0.9 else Vector3.RIGHT).normalized()
	var card: CardInterlude = tour.interlude as CardInterlude if with_card else null
	card_view.visible = card != null
	for i in 6:
		sky.camera.look(atan2(-n.x, -n.z), asin(clampf(n.y, -1., 1.)), 0.)
		frame += 1; sky.finish_exposure_frame(1. / 60., frame)
		if card != null: card_view.show_interlude(card)
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(OUT.path_join(name + ".png"))
	var nan := false
	for y in range(0, img.get_height(), 8):
		for x in range(0, img.get_width(), 8):
			var c := img.get_pixel(x, y); nan = nan or not (is_finite(c.r) and is_finite(c.g) and is_finite(c.b))
	if nan: failures += 1
	records.append({"name": name, "phase": sim.world.ship.phase, "beta": sim.world.ship.get("beta", 0.0), "gamma": sim.world.ship.get("gamma", 1.0),
		"earth_year": sim.world.clock.year, "ship_tau": sim.world.clock.tau, "look": look, "card": card != null, "auto_view": auto_view, "finite": not nan})
	print("SHOT ", name, " beta=", sim.world.ship.get("beta", 0.0), " Earth+", snappedf(sim.world.clock.year, 0.001))
	card_view.visible = false

## World-frame direction from the ship to the leg's target: the body's rendered
## position, or the catalogue star's position relative to the ship (galactic -> SkyFrame).
func target_dir(world: Dictionary) -> Vector3:
	var target: Dictionary = world.journey.plan.target
	for b: Dictionary in world.get("system", {}).get("bodies", []):
		if b.id == target.get("id", ""):
			var w := Planets.world_of(b.rel_km); return Vector3(w[0], w[1], w[2]).normalized()
	var p: Dictionary = world.ship.pos
	var tp: Dictionary = world.journey.plan.get("target", {}).get("pos", p)
	var g := SkyFrame.to_world64(PackedFloat64Array([tp.x - p.x, tp.y - p.y, tp.z - p.z]))
	return Vector3(g[0], g[1], g[2]).normalized()
