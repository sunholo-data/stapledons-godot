extends SceneTree
## The guided voyage's last stop is Sgr A* (Mark, attended 2026-10-20): make guided-finale-test.
##   F1  at the final leg's arrival the tour is complete, the tour line names the final stop, and
##       nothing jumps at once (the stop dwells like every other)
##   F2  after the dwell (SolarDeparture.DWELL_SECONDS of tour ticks) the Sgr A* visit starts by
##       itself: the guided tour hands over, the HUD says it is the guided voyage's final stop
##   F3  there the hole is ahead on the rendered sky (the sky camera the player sees through, Bow)
##   F4  Skip dwell [N] at the final stop goes to Sgr A* at once
##   F5  the navigation entry still starts Sgr A* directly (a fresh session, no tour)
## The tour is driven the honest way (tests/review_drive.gd: Begin at the Voyage console, the
## itinerary's own legs, Skip stage, holds resumed); only the earlier legs are skipped (next_leg).
## Prints `ok    <name>` / `FAIL  <name>: <why>` and `guided-finale: <n> passed, <m> failures`.

const ReviewDrive := preload("res://tests/review_drive.gd")
const SolarDeparture := preload("res://demos/solar_departure.gd")
const PX := Vector2i(1280, 720)
var failures := 0
var passes := 0


func check(label: String, ok: bool, why := "") -> void:
	if ok:
		passes += 1
		print("ok    %s" % label)
	else:
		failures += 1
		print("FAIL  %s: %s" % [label, why])


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await test_finale(false)
	await test_finale(true)
	await test_direct()
	print("guided-finale: %d passed, %d failures" % [passes, failures])
	quit(1 if failures else 0)


func new_demo() -> Node:
	var demo: Node = load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options = {"live_start": true, "sky_state": "rest", "stars": false, "background": false, "size": PX}
	root.add_child(demo)
	await process_frame
	await physics_frame
	demo.auto = false
	demo.journey_auto_tick = false
	demo.escape_exits = false
	return demo


## The hole on the sky camera the player looks through: degrees off its axis, and in frame.
func hole_on_sky(demo: Node) -> Array:
	var cam: Camera3D = demo.sky.camera
	var h := GrLens._world(demo.black_hole.gr().hole_dir)
	var p := cam.global_position + h * 1000.0
	var vp := cam.get_viewport().get_visible_rect().size
	var px := cam.unproject_position(p)
	var inside := not cam.is_position_behind(p) and px.x >= 0.0 and px.y >= 0.0 and px.x <= vp.x and px.y <= vp.y
	return [rad_to_deg((-cam.global_transform.basis.z).angle_to(h)), inside]


## Fly the final leg to its arrival; true when the tour reports complete.
func fly_last_leg(demo: Node) -> bool:
	var tour = demo.solar_tour
	if not ReviewDrive.begin(demo, tour_size(demo) - 1):
		return false
	for i in 20000:
		if demo.solar_tour == null or demo.solar_tour.complete:
			break
		var s: String = ReviewDrive.frame(demo)
		if s == "crossed":
			demo.continue_interlude()
		elif s == "failed":
			print("  drive failed: %s" % (demo.solar_tour.failed if demo.solar_tour != null else "no tour"))
			return false
	return demo.solar_tour != null and demo.solar_tour.complete and not demo.live_journey


func tour_size(demo: Node) -> int:
	var md: Dictionary = demo.journey_sim.world.get("solar_departure", {}) if demo.journey_sim != null else {}
	return (md.get("legs", []) as Array).size()


func test_finale(skip: bool) -> void:
	var tag := "N" if skip else "dwell"
	var demo: Node = await new_demo()
	# The Voyage console's Begin creates the tour session; its itinerary sizes the skip.
	var c: ShipConsoles = demo.consoles
	c.go_to("voyage"); c.use("voyage", "open"); c.use("voyage", "begin"); c.leave()
	var n := tour_size(demo)
	var last_name := ""
	if demo.solar_tour != null and n > 0:
		last_name = str(demo.solar_tour.itinerary[n - 1].get("name", demo.solar_tour.itinerary[n - 1].id))
	var arrived := n > 0 and await fly_last_leg(demo)
	check("[%s] F1 the final leg arrives and the tour is complete (%s)" % [tag, last_name], arrived,
		"tour %s, %d legs" % ["missing" if demo.solar_tour == null else ("complete" if demo.solar_tour.complete else "not complete"), n])
	if not arrived:
		demo.queue_free(); await process_frame; return
	# The stop turn first (the body framed, as at every stop); time waits during it.
	for i in 600:
		if not demo.solar_tour.attitude_hold and not demo.tour_attitude.turning():
			break
		demo._process(1.0 / 60.0)
		if demo.solar_tour.attitude_hold:
			demo.journey_tick()
	check("[%s] F1 the stop turn completes and no jump happens during it" % tag, not demo.solar_tour.attitude_hold and demo.black_hole == null)
	demo._process(1.0 / 60.0) # the HUD cards refresh
	var row: Node = demo.ship_hud.card_body("tour").get_node_or_null("Buttons") if demo.ship_hud.has_card("tour") else null
	var skip_btn: Button = row.get_node_or_null("SkipDwell") if row != null else null
	check("[%s] F4 the tour card's Skip dwell is offered at the final stop" % tag, skip_btn != null and not skip_btn.disabled, "button %s" % ("missing" if skip_btn == null else "disabled"))
	var line: String = demo.tour_line()
	check("[%s] F1 the tour line names the final stop" % tag, line.contains("Sgr A*") and line.contains("final stop"), line)
	var ticks := 0
	if skip:
		for i in 10:
			demo.journey_tick(); ticks += 1
		check("[%s] F1 no jump in the first ticks" % tag, demo.black_hole == null and demo.solar_tour != null, "black_hole %s" % str(demo.black_hole))
		check("[%s] F4 Skip dwell goes to Sgr A* at once" % tag, demo.skip_dwell() and demo.black_hole != null, "black_hole %s" % str(demo.black_hole))
	else:
		var limit := int(round(SolarDeparture.DWELL_SECONDS * SolarDeparture.TICK_HZ))
		while demo.black_hole == null and ticks < limit + 40:
			demo.journey_tick(); ticks += 1
		check("[%s] F2 Sgr A* starts by itself after the stop's dwell (%d ticks, dwell %d)" % [tag, ticks, limit],
			demo.black_hole != null and absi(ticks - limit) <= 2, "black_hole %s after %d ticks" % [str(demo.black_hole), ticks])
	if demo.black_hole == null:
		demo.queue_free(); await process_frame; return
	check("[%s] F2 the guided tour handed over" % tag, demo.solar_tour == null and demo.guided_finale, "tour %s, guided_finale %s" % [str(demo.solar_tour), str(demo.guided_finale)])
	var label: String = demo.journey_label()
	check("[%s] F2 the HUD names the guided voyage's final stop" % tag, label.to_lower().contains("final stop"), label)
	for i in 30:
		demo._process(1.0 / 60.0)
	await process_frame
	var r: Array = hole_on_sky(demo)
	check("[%s] F3 the hole is ahead on the rendered sky" % tag, r[1] and r[0] < 15.0, "%.2f deg off the sky camera's axis, in frame %s" % [r[0], str(r[1])])
	demo.leave_black_hole()
	check("[%s] leaving ends the finale" % tag, demo.black_hole == null and not demo.guided_finale)
	demo.queue_free()
	await process_frame


func test_direct() -> void:
	var demo: Node = await new_demo()
	var c: ShipConsoles = demo.consoles
	c.go_to("navigation")
	c.use("navigation", "open")
	var ok: bool = c.use("navigation", "sgr_a")
	c.leave()
	check("F5 the navigation entry starts Sgr A* directly", ok and demo.black_hole != null and not demo.guided_finale)
	if demo.black_hole != null:
		for i in 30:
			demo._process(1.0 / 60.0)
		await process_frame
		var r: Array = hole_on_sky(demo)
		check("F5 the hole is ahead there too", r[1] and r[0] < 15.0, "%.2f deg off axis" % r[0])
		demo.leave_black_hole()
	demo.queue_free()
	await process_frame
