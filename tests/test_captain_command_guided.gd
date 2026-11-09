extends SceneTree
## The guided crossing's review, crew route and Brake must all work without leaving the chair.
const DRIVE := preload("res://tests/review_drive.gd")
var passed := 0
var failures := 0
func check(label: String, ok: bool) -> void:
	if ok: passed += 1
	else: failures += 1
	print(("ok " if ok else "FAIL ") + label)
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var d: Node = load("res://demos/ship_geometry_demo.tscn").instantiate()
	d.setup_options = {"stars": false, "background": false, "live_start": true, "sky_state": "rest", "seed": 42}
	d.process_mode = Node.PROCESS_MODE_DISABLED
	root.add_child(d)
	await process_frame
	d.auto = false; d.journey_auto_tick = false; d.escape_exits = false
	d.avatar_pos = d.walk_bridge.closest_walkable(d.chair_seat() - d.chair_facing(), 3.)
	d.sit_chair()
	for k in 50: d._process(1. / 60.)
	var seat: Vector3 = d.avatar_pos
	check("chair opens Voyage", d.consoles.command.select_system("voyage"))
	check("chair starts the existing guided voyage", d.consoles.use("voyage", "begin") and d.solar_tour != null)
	if d.solar_tour != null:
		d.solar_tour.leg_index = 3 # same bounded Alpha Centauri slice as ReviewDrive/crew-hold tests
		var result: String = DRIVE.reach(d)
		check("real guided crossing reaches its review", result == "crossed")
		check("Voyage hosts the actual crossing review from the chair", d.crossing_review.visible and d.consoles.command.authorized())
		d._place_interlude()
		for k in 4: await process_frame
		var host: Control = d.crossing_review.get_parent()
		check("review viewport fits the chair content", d.consoles.command.content_rect().encloses(host.get_global_rect()))
		d.crossing_review.open_crew.emit()
		check("review's crew route keeps captain in the chair", d.consoles.focused == "crew" and d.avatar_pos.is_equal_approx(seat) and d.consoles.command.authorized())
		check("Crew view steps the review aside", not d.crossing_review.visible)
		d.consoles.command.select_system("voyage")
		check("Voyage restores the same review", d.crossing_review.visible and d.crossing_review.crossed)
		d.crossing_review.go(d.crossing_review.page_ids().size() - 1)
		d.crossing_review.enter()
		check("review Brake continues the same guided interlude", d.solar_tour.interlude.done())
		check("braking remains under seated command", d.journey_tick() and d.consoles.command.authorized() and d.avatar_pos.is_equal_approx(seat))
	d.queue_free()
	await process_frame
	print("captain-command-guided: %d passed, %d failures" % [passed, failures])
	quit(1 if failures else 0)
