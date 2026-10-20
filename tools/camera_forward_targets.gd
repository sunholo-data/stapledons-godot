extends SceneTree
## R2-CAMERA-FORWARD AC-V6 fixture: the live targets the Bow view must frame, recorded from the sim.
## make camera-forward-targets -> tests/fixtures/camera_forward/targets.json (headless; re-run when the
## guided itinerary, the stop turn or the Sgr A* visit changes, and commit the diff).
##   stop:  the guided voyage's first stop, once the stop turn is done: the body's id and rel_km (the
##          vector Attitude.side_basis turns to) and the attitude the sky is then oriented with
##   sgr_a: every stop of the Sgr A* visit (hovers, approaches, the orbit): the sim's gr.hole_dir and
##          the attitude hole_direction() reads (attitude_basis, else ship_basis(heading))
## test_camera_forward.gd rebuilds the attitude from the body with the real side_basis and checks it
## against the recorded one, so a stale fixture fails there rather than passing quietly.
var demo: Node
var failures := 0
const OUT := "res://tests/fixtures/camera_forward/targets.json"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var rec := {"about": "R2-CAMERA-FORWARD AC-V6 targets, recorded from the live sim by tools/camera_forward_targets.gd (make camera-forward-targets). Directions in the sim's galactic frame; attitudes are row-major 3x3 (rows: kinematic x, y, z in galactic).", "stop": {}, "sgr_a": []}
	if await _new_demo() and demo.start_solar_departure():
		var guard := 0
		while guard < 2400 and (demo.solar_tour.attitude_hold or demo.under_way() or demo._attitude_stop < -1 or not demo._attitude_mode.is_empty() or demo.tour_attitude.turning()):
			demo._process(1.0 / 60.0)
			if demo.solar_tour.attitude_hold:
				demo.journey_tick()
			guard += 1
		var id: String = "earth" if demo.solar_tour.leg_index < 0 else str(demo.solar_tour.itinerary[demo.solar_tour.leg_index].id)
		var held: String = str(demo.sky_world.get("journey", {}).get("plan", {}).get("hold", {}).get("body", ""))
		for body: Dictionary in demo.sky_world.get("system", {}).get("bodies", []):
			if body.id == id or body.id == held or str(body.get("catalogue_id", "")) == id:
				rec.stop = {"leg": id, "body": body.id, "rel_km": [float(body.rel_km.x), float(body.rel_km.y), float(body.rel_km.z)], "attitude": Array(demo.camera.attitude_basis), "frames": guard}
				break
		if rec.stop.is_empty():
			print("FAIL no first-stop body (leg %s, %d frames)" % [id, guard])
			failures += 1
	else:
		print("FAIL the guided voyage did not start")
		failures += 1
	await _free()
	if await _new_demo() and demo.start_black_hole():
		var BlackHoleVisit := load("res://demos/black_hole_visit.gd")
		for stop in BlackHoleVisit.STOPS.size() + 1:
			if stop > 0:
				if not demo.bh_next_stop():
					print("FAIL Sgr A* stop %d refused" % stop)
					failures += 1
					break
				if demo.black_hole.approaching():
					demo.bh_finish_approach()
				else:
					demo._arrived()
			for i in 60:
				demo._process(1.0 / 60.0)
			var g: Dictionary = demo.black_hole.gr()
			var b: PackedFloat64Array = demo.camera.attitude_basis if not demo.camera.attitude_basis.is_empty() else ShipFrame.ship_basis(demo.camera.heading)
			rec.sgr_a.append({"stop": stop, "mode": str(g.get("mode", "")), "r_rs": float(g.r), "hole_dir": [float(g.hole_dir.x), float(g.hole_dir.y), float(g.hole_dir.z)], "attitude": Array(b)})
	else:
		print("FAIL Sgr A* did not start")
		failures += 1
	await _free()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT.get_base_dir()))
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(JSON.stringify(rec, "  ") + "\n")
	f.close()
	print("camera-forward-targets: stop %s, %d Sgr A* stops, %d failures" % [rec.stop.get("body", "-"), rec.sgr_a.size(), failures])
	quit(1 if failures else 0)


func _new_demo() -> bool:
	demo = load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options = {"live_start": true, "sky_state": "rest", "size": Vector2i(1280, 720)}
	root.add_child(demo)
	await process_frame
	if not demo.ready_ok:
		print("FAIL demo did not build")
		failures += 1
		return false
	demo.auto = false
	demo.journey_auto_tick = false
	return true


func _free() -> void:
	if is_instance_valid(demo):
		if demo.black_hole != null:
			demo.leave_black_hole()
		demo.queue_free()
		await process_frame
	demo = null
