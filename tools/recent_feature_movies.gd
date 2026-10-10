extends SceneTree
## Frame-exact showcase clips through the real ship demo and AILANG sidecar.
## Presentation controls choose camera and elapsed ship time only. No world,
## velocity, ephemeris, GR, dust or shader-physics fields are synthesized.
## godot --path . --script tools/recent_feature_movies.gd -- --clip=black_hole_orbit
##   [--out=renders/site/frames/CLIP] [--preview]
## --preview advances the identical route, saving six representative frames.

const SIZE := Vector2i(1280, 720)
const FPS := 30
const YEAR_S := 31557600.0
const LENGTHS := {"black_hole_orbit": 20, "saturn_arrival": 22, "ism_transit": 24}
const BH_WARP := 90.0
const ALDEBARAN := "CNS5:1142"

var demo: Node
var movie_view: SubViewport
var caption: Label
var clip := ""
var out := ""
var preview := false
var rows: Array = []
var phase_total := 0.0
var phase_previous := 0.0
var first_clock: Dictionary = {}
var arrival_frame := -1
var media_seen: Array[String] = []
var media_cuts: Array = []
var planned_media: Array = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--clip="): clip = arg.trim_prefix("--clip=")
		elif arg.begins_with("--out="): out = arg.trim_prefix("--out=")
		elif arg == "--preview": preview = true
	if not LENGTHS.has(clip):
		_fail("choose --clip=black_hole_orbit|saturn_arrival|ism_transit")
		return
	if out.is_empty(): out = "res://renders/site/frames/" + clip
	out = ProjectSettings.globalize_path(out)
	DirAccess.make_dir_recursive_absolute(out)
	root.size = SIZE
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	# Capture this viewport, never a physical/HiDPI window framebuffer.
	movie_view = SubViewport.new()
	movie_view.size = SIZE
	movie_view.own_world_3d = true
	movie_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(movie_view)
	demo = load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options = {"size": SIZE, "sky_state": "rest", "auto_view": true}
	movie_view.add_child(demo)
	await process_frame
	if not demo.ready_ok or not demo.sky.has_background:
		_fail("ship geometry or pinned Milky Way assets missing")
		return
	demo.auto = false
	demo.journey_auto_tick = false
	demo.set_process(false)
	demo.sky.set_process(false)
	demo.ship_hud.hint.visible = false
	demo.controls.visible = false
	demo.dwell_on = false
	var canvas := CanvasLayer.new()
	canvas.layer = 30
	movie_view.add_child(canvas)
	caption = Label.new()
	caption.position = Vector2(24, 637)
	caption.size = Vector2(1232, 68)
	caption.add_theme_font_size_override("font_size", 16)
	caption.add_theme_color_override("font_shadow_color", Color.BLACK)
	caption.add_theme_constant_override("shadow_outline_size", 5)
	canvas.add_child(caption)
	var ok := false
	match clip:
		"black_hole_orbit": ok = await _black_hole()
		"saturn_arrival": ok = await _saturn()
		"ism_transit": ok = await _ism()
	if not ok:
		_fail("trajectory/capture failed")
		return
	var count: int = int(LENGTHS[clip]) * FPS
	var manifest := {"clip": clip, "width": SIZE.x, "height": SIZE.y, "fps": FPS,
		"seconds": LENGTHS[clip], "source_frames": count, "saved_frames": rows.size(),
		"preview": preview, "seed": 424242 if clip != "ism_transit" else 7,
		"clock_start": first_clock, "clock_end": _world().clock,
		"arrival_frame": arrival_frame, "media_seen": media_seen,
		"planned_media": planned_media, "media_cuts": media_cuts,
		"physics": "AILANG real simulation; presentation time compression explicitly labelled",
		"frames": rows}
	var file := FileAccess.open(out.path_join("manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest, "  ") + "\n")
	print("recent-feature-movies: %s %d/%d frames, %dx%d at %d Hz, %ds; terminal %s" %
		[clip, rows.size(), count, SIZE.x, SIZE.y, FPS, LENGTHS[clip], _world().ship.phase])
	if demo.black_hole != null: demo.black_hole.stop()
	if demo.journey_sim != null: demo.journey_sim.stop()
	quit(0)


func _world() -> Dictionary:
	return demo.black_hole.sim.world if demo.black_hole != null else demo.journey_sim.world


func _fail(message: String) -> void:
	push_error("recent-feature-movies: " + message)
	if demo != null:
		if demo.black_hole != null: demo.black_hole.stop()
		if demo.journey_sim != null: demo.journey_sim.stop()
	quit(1)


func _check_numbers(value: Variant) -> bool:
	if value is float: return is_finite(value)
	if value is Dictionary:
		for child in value.values():
			if not _check_numbers(child): return false
	if value is Array:
		for child in value:
			if not _check_numbers(child): return false
	return true


func _frame(i: int) -> bool:
	var world := _world()
	if not _check_numbers(world):
		push_error("recent-feature-movies: nonfinite simulation field at %d" % i)
		return false
	demo.sky._process(1.0 / FPS)
	demo._process(1.0 / FPS)
	demo.ship_hud.set_prompt("") # presentation diagnostic has no interaction prompts
	if clip == "black_hole_orbit": _aim_shadow()
	var total: int = int(LENGTHS[clip]) * FPS
	if preview and i not in [0, total / 5, total * 2 / 5, total * 3 / 5, total * 4 / 5, total - 1]:
		return true
	for settle in 2:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := movie_view.get_texture().get_image()
	if image == null or image.get_size() != SIZE:
		push_error("recent-feature-movies: viewport dimensions differ")
		return false
	var name := "f%05d.png" % i
	if image.save_png(out.path_join(name)) != OK: return false
	var ship: Dictionary = world.ship
	var row := {"frame": i, "file": name, "sha256": FileAccess.get_sha256(out.path_join(name)),
		"clock": world.clock.duplicate(true), "phase": ship.phase, "beta": ship.beta,
		"gamma": ship.gamma, "position_ly": ship.pos.duplicate(true), "fov": demo.camera.fov,
		"sky_only": demo.sky_only, "caption": caption.text,
		"drawn_discs": demo.sky.system_view.drawn_discs.duplicate(),
		"ring_hosts": demo.sky.system_view.ring_systems.keys()}
	if world.has("gr"):
		row["gr"] = world.gr.duplicate(true)
		row["orbits_from_sim_phase"] = phase_total / TAU
	if ship.has("ism"): row["ism"] = ship.ism.duplicate(true)
	rows.append(row)
	if i % FPS == 0 or preview:
		print("movie-frame: %s %d/%d %s beta%s" % [clip, i, total, ship.phase, ship.beta])
	return true


func _aim_shadow() -> void:
	# Point the presentation lens at the apparent shadow cap centre. The SR cap
	# transform is the renderer's existing audited helper; it changes no sim field.
	var gr: Dictionary = demo.black_hole.gr()
	var rest := SkyFrame.to_world64([gr.hole_dir.x, gr.hole_dir.y, gr.hole_dir.z])
	var motion := SkyFrame.to_world64([gr.dir_local.x, gr.dir_local.y, gr.dir_local.z])
	var r := Vector3(rest[0], rest[1], rest[2]).normalized()
	var h := Vector3(motion[0], motion[1], motion[2]).normalized()
	var cosine := r.dot(h)
	var cap := Planets.apparent_disc64(cosine, float(gr.shadow), float(gr.beta_local), float(gr.gamma_local))
	var transverse := (r - cosine * h).normalized()
	var direction := h * cos(cap[0]) + transverse * sin(cap[0])
	var up := Vector3.UP if absf(direction.y) < 0.95 else Vector3.RIGHT
	var angles := InteriorSky.euler_of(PackedFloat64Array([direction.x, direction.y, direction.z]), PackedFloat64Array([up.x, up.y, up.z]))
	demo.sky.camera.look(angles[0], angles[1], angles[2])
	demo.sky.update_exposure()


func _black_hole() -> bool:
	if not demo.start_black_hole(): return false
	for radius in [10.0, 5.0, 3.0]:
		if not demo.bh_next_stop() or not demo.bh_finish_approach(): return false
		if float(demo.black_hole.gr().r) != radius: return false
	if not demo.bh_next_stop(): return false # scripted free-fall orbit at 3r_s
	if demo.black_hole.gr().mode != "orbit" or not demo.black_hole.gr().orbit_stable: return false
	first_clock = _world().clock.duplicate(true)
	phase_previous = float(demo.black_hole.gr().phase)
	demo.look_direction("forward")
	demo.toggle_sky_only()
	demo.camera.fov = 100.0 # the 45deg shadow half-angle fits inside this lens
	for i in int(LENGTHS[clip]) * FPS:
		if not demo.black_hole._send(BH_WARP / (FPS * YEAR_S)): return false
		demo._apply_bh_world()
		var g: Dictionary = demo.black_hole.gr()
		phase_total += fposmod(float(g.phase) - phase_previous, TAU)
		phase_previous = float(g.phase)
		caption.text = "Sgr A* · stable orbit at 3r_s · %.2f orbits (simulation phase)\n90× ship-time pacing · diagnostic sky view · Sol sky lensed; Galactic-Centre sky is future work" % (phase_total / TAU)
		if not await _frame(i): return false
	return phase_total > TAU and demo.black_hole.gr().mode == "orbit"


func _saturn() -> bool:
	if not demo.start_solar_departure(): return false
	var tour = demo.solar_tour
	# Execute preceding physical legs without rendering them. The sidecar owns
	# each exact phase boundary; this is the player's existing Skip stage control.
	for target in ["sun", "jupiter", "callisto", "saturn"]:
		if not tour.advance() or tour.itinerary[tour.leg_index].id != target: return false
		var reached := false
		for boundary in 12:
			if target == "saturn" and _world().ship.phase == "approaching": reached = true; break
			if _world().journey.state == "arrived": reached = true; break
			if not tour.skip_stage(): return false
		if not reached: return false
	if _world().ship.phase != "approaching": return false
	demo._apply_journey_world()
	demo.look_direction("forward")
	demo.toggle_sky_only()
	first_clock = _world().clock.duplicate(true)
	# Hold only presentation attitude while direct sidecar ticks advance the leg.
	tour.paused = true
	var approach_frames := 16 * FPS
	for i in int(LENGTHS[clip]) * FPS:
		if _world().journey.state != "arrived":
			if not tour._send([], 0.0): return false
			var remaining: float = float(_world().consequence.phase_remaining_yr)
			var frames_left := maxi(1, approach_frames - i)
			var step := remaining / frames_left
			if not tour._send([], step + maxf(step * 1e-9, 1e-18)): return false
		else:
			if arrival_frame < 0: arrival_frame = i
			if not tour._send([], 1.0 / (FPS * YEAR_S)): return false
		demo._apply_journey_world()
		# Widen late in the physical approach so the actual ring system remains
		# wholly framed at this close stop; changing a lens never changes a body.
		demo.camera.fov = lerpf(55.0, 110.0, smoothstep(0.65, 1.0, i / float(approach_frames)))
		caption.text = "Saturn · %s · real intercept, moons and rings\nFinal approach compressed to 16 screen seconds; earlier guided stops omitted · diagnostic sky view" % ("ARRIVED · at rest" if _world().journey.state == "arrived" else "FINAL APPROACH")
		if not await _frame(i): return false
	return arrival_frame >= 0 and _world().journey.state == "arrived" and _world().ship.beta == 0.0 and demo.sky.system_view.drawn_discs.has("saturn")


func _jump_to(flown: float) -> bool:
	var s: Dictionary = _world().ship
	var left := flown - float(s.flown)
	if left <= 0.0: return true
	var dt := left / (float(s.gamma) * float(s.beta))
	while dt > 0.0:
		var step := minf(dt, 0.9)
		if not demo.journey_sim.send([], step): return false
		dt -= step
	return true


func _ism() -> bool:
	demo.open_navigation()
	demo.close_navigation()
	var sim: SimBridge = demo.journey_sim
	if not sim.new_game(7, "sol", false, {"standoff_au": 1000.0}): return false
	var map = demo.journey_map
	map.refresh()
	var target_index: int = map.index_of(ALDEBARAN)
	if target_index < 0: return false
	map.set_cruise_phi(0.5 * (log(1.999) - log(0.001)))
	if not sim.send([map.plan_intent(target_index)], 0.0) or not sim.last_refused.is_empty():
		push_error("ISM movie plan: %s %s" % [sim.last_error, sim.last_refused])
		return false
	var plan_id: int = sim.world.journey.plan_id
	if not sim.send([{"k": "commit", "plan_id": plan_id}], 2e-7): return false
	for j in 500:
		if sim.world.ship.phase == "cruising": break
		if not sim.send([], 2e-7): return false
	if sim.world.ship.phase != "cruising": return false
	# Protocol 2.8 retains the ordered profile intervals, including repeated hot
	# pieces. Choose actual interval midpoints rather than fixed guessed distances.
	planned_media = sim.world.journey.plan.media.duplicate(true)
	var start := 0.0
	for medium in planned_media:
		var length := float(medium.length_ly)
		if length > 0.01:
			media_cuts.append({"name": str(medium.name), "start_ly": start,
				"end_ly": start + length, "midpoint_ly": start + length / 2.0})
		start += length
	# The final, long hot segment need only show its near edge, before braking.
	if media_cuts.is_empty() or media_cuts.size() > 8: return false
	var last: Dictionary = media_cuts.back()
	if last.name == "hot": last.midpoint_ly = minf(float(last.midpoint_ly), float(last.start_ly) + 1.0)
	if not _jump_to(float(media_cuts[0].midpoint_ly)): return false
	map.pacing.rate = 1.0 / YEAR_S
	demo._apply_journey_world()
	demo.look_direction("forward")
	first_clock = _world().clock.duplicate(true)
	for i in int(LENGTHS[clip]) * FPS:
		var total: int = int(LENGTHS[clip]) * FPS
		var cut_index := mini(media_cuts.size() - 1, i * media_cuts.size() / total)
		var cut: Dictionary = media_cuts[cut_index]
		if not _jump_to(float(cut.midpoint_ly)): return false
		if not sim.send([], 1.0 / (FPS * YEAR_S)): return false
		demo._apply_journey_world()
		var ism: Dictionary = sim.world.ship.ism
		var medium := str(ism.medium)
		if medium != str(cut.name):
			push_error("ISM midpoint differs from planned interval: %s vs %s" % [medium, cut.name])
			return false
		if medium not in media_seen:
			media_seen.append(medium)
			print("movie-medium: frame %d %s at %s ly" % [i, medium, sim.world.ship.flown])
		if i >= 18 * FPS:
			if not demo.sky_only: demo.toggle_sky_only()
			demo.camera.follow(demo.avatar_pos, 89.5 - 65.0 * smoothstep(0.0, 1.0, (i - 18.0 * FPS) / (6.0 * FPS)), 0.0, 0.0)
		caption.text = "Aldebaran route · 0.999c · %s · n_H %s cm⁻³ · glitter %s/s\nCompressed cuts follow actual cloud intervals; each displayed dust tick is 1/30 ship second · real AILANG draws" % [IsmLayer.label_of(medium), GalaxyMap.sci(float(ism.n_h_cm3)), GalaxyMap.sci(float(ism.glitter.rate))]
		if not await _frame(i): return false
	print("movie-media-seen: ", media_seen)
	return media_seen.has("LIC") and media_seen.has("hot") and media_seen.has("Hyades")
