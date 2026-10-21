extends SceneTree
## The guided voyage's end and the Sgr A* visit as the player meets them (Mark, attended
## 2026-10-20): make bh-ahead-capture (GPU window) -> renders/bh_ahead/<tag>/*.png + manifest.json.
## The final leg is flown the honest way (tests/review_drive.gd); then Sgr A* starts the way this
## build offers: the tour's own handover (Skip dwell at the final stop) when the demo has it, else the
## navigation station's entry (the only path before). Every frame is the Bow view with the HUD.
## Each Sgr A* stop records the hole on the sky camera the player sees through: degrees off its axis
## and whether it projects into the frame. `-- --tag=<name>` names the output folder (default now).

const ReviewDrive := preload("res://tests/review_drive.gd")
var demo: Node
var px := Vector2i(1280, 720)
var out := ""
var shots := []
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var tag := "now"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--tag="):
			tag = a.substr(6)
	out = ProjectSettings.globalize_path("res://renders/bh_ahead/" + tag)
	DirAccess.make_dir_recursive_absolute(out)
	demo = load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options = {"live_start": true, "sky_state": "rest", "size": px}
	root.add_child(demo)
	await process_frame
	if not demo.ready_ok:
		print("FAIL demo did not build")
		quit(1)
		return
	demo.auto = false
	demo.journey_auto_tick = false
	demo.escape_exits = false
	var c: ShipConsoles = demo.consoles
	c.go_to("voyage"); c.use("voyage", "open"); c.use("voyage", "begin"); c.leave()
	var legs: int = (demo.journey_sim.world.get("solar_departure", {}).get("legs", []) as Array).size()
	var arrived := ReviewDrive.begin(demo, legs - 1)
	for i in 20000:
		if not arrived or demo.solar_tour == null or demo.solar_tour.complete:
			break
		var s: String = ReviewDrive.frame(demo)
		if s == "crossed":
			demo.continue_interlude()
		elif s == "failed":
			arrived = false
	arrived = arrived and demo.solar_tour != null and demo.solar_tour.complete
	if not arrived:
		print("FAIL the final leg did not arrive")
		quit(1)
		return
	for i in 600:
		demo._process(1.0 / 60.0)
		if demo.solar_tour.attitude_hold:
			demo.journey_tick()
	await _shot("tour_final_stop_aldebaran", false)
	var finale: bool = demo.has_method("start_guided_finale")
	var started: bool = demo.skip_dwell() if finale else false
	if not finale:
		c.go_to("navigation"); c.use("navigation", "open")
		started = c.use("navigation", "sgr_a")
		c.leave()
	if not started or demo.black_hole == null:
		print("FAIL Sgr A* did not start (%s)" % ("the tour's handover" if finale else "the navigation entry"))
		quit(1)
		return
	var BlackHoleVisit := load("res://demos/black_hole_visit.gd")
	for stop in BlackHoleVisit.STOPS.size() + 1:
		if stop > 0:
			if not demo.bh_next_stop():
				print("FAIL Sgr A* stop %d refused" % stop)
				failures += 1
				break
			if demo.black_hole.approaching():
				demo.bh_finish_approach()
		for i in 300:
			demo._process(1.0 / 60.0)
		demo.sky.update_exposure()
		var g: Dictionary = demo.black_hole.gr()
		var r := float(g.r)
		await _shot("sgr_a_stop%d_%s_r%s" % [stop, str(g.get("mode", "")), ("%.0f" % r) if r < 100.0 else "1e6"], true)
	var f := FileAccess.open(out + "/manifest.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"about": "The guided voyage's final stop and every Sgr A* stop, Bow view with the HUD, after flying the tour's last leg; Sgr A* started by %s." % ("the tour's handover (Skip dwell)" if finale else "the navigation entry"), "tag": tag, "shots": shots}, "  "))
	f.close()
	print("bh-ahead-capture: %d frames, %d failures (%s)" % [shots.size(), failures, tag])
	quit(1 if failures else 0)


func _shot(name: String, hole: bool) -> void:
	demo.geometry_view.size = px
	demo._sync_observer()
	for i in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	image.save_png(out + "/" + name + ".png")
	var rec := {"name": name, "view": demo.director.view_id, "hud": demo.journey_label()}
	if hole:
		var cam: Camera3D = demo.sky.camera
		var h := GrLens._world(demo.black_hole.gr().hole_dir)
		var p := cam.global_position + h * 1000.0
		var vp := cam.get_viewport().get_visible_rect().size
		var q := cam.unproject_position(p)
		var inside := not cam.is_position_behind(p) and Rect2(Vector2.ZERO, vp).has_point(q)
		rec.hole_off_axis_deg = rad_to_deg((-cam.global_transform.basis.z).angle_to(h))
		rec.hole_in_frame = inside
	shots.append(rec)
	print("%s view %s %s" % [name, rec.view, ("hole %.2f deg off axis, in frame %s" % [rec.hole_off_axis_deg, str(rec.hole_in_frame)]) if hole else ""])
