extends SceneTree
## R2-LEVELS design mocks (design_docs/planned/r2/levels.md §L3): candidate fixed views of a lower
## level, rendered through the live sky, so Mark can choose a view model before anything is built.
## Review only: nothing here is a game view. GPU window, 1280x720.
##   commons_<view>_<sky>   the existing Commons (+57 m) through a candidate view:
##       bow       the bridge's Bow walk pose (pitch -8, 9 m back, 5.5 m up) at the court
##       stage     candidate "stage" view: lower and further back (pitch -3, 16 m back, 3 m up)
##       overlook  candidate high view (pitch -20, 14 m back, 9 m up)
##       astern    the Bow pose turned to the stern, at the court
##   garden_<view>_<sky>    the bare +7 m slab (the forest tier, nothing built) at the same poses:
##                          the scale and the rim "letterbox" of sky between floor and roof
##   garden_rim_stage_<sky>, homes_rim_stage_<sky>   the stage pose 20 m inside a roofed tier's bow
##                          rim: the recommended stage placement (a taller letterbox)
##   lift_mid_<sky>         beside the lift halfway between the bridge and the Commons, toward the bow
##   <sky> = rest | cruise (the review 0.99c snapshot)
## Writes renders/levels/mock/*.png, contact_sheet.png and poses.json.
## Usage: godot --path . --script tools/levels_mock_capture.gd -- [--out=res://renders/levels/mock]
var demo: Node
var out := "res://renders/levels/mock"
var px := Vector2i(1280, 720)
var rows := []
const COURT := Vector3(25.0, 57.0, -5.0) # glTF of ship (25, 5, 57): the middle of the Commons court
const GARDEN := Vector3(10.0, 7.0, -30.0) # glTF of ship (10, 30, 7): the bare forest tier, bow side
const GARDEN_RIM := Vector3(0.0, 7.0, -74.7) # ship (0, 74.7, 7): 20 m inside the forest tier's bow rim
const HOMES_RIM := Vector3(0.0, 32.0, -69.4) # ship (0, 69.4, 32): 20 m inside the Homes tier's bow rim
const VIEWS := {
	"bow": {"yaw": 270.0, "pitch": -8.0, "back": 9.0, "rise": 5.5},
	"stage": {"yaw": 270.0, "pitch": -3.0, "back": 16.0, "rise": 3.0},
	"overlook": {"yaw": 270.0, "pitch": -20.0, "back": 14.0, "rise": 9.0},
	"astern": {"yaw": 90.0, "pitch": -8.0, "back": 9.0, "rise": 5.5},
}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	root.size = px
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.content_scale_size = px
	demo = load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options = {"size": px, "sky_state": "rest"}
	root.add_child(demo)
	await process_frame
	if not demo.ready_ok:
		print("levels-mock-capture: FAIL demo did not build")
		quit(1)
		return
	demo.auto = false
	demo.journey_auto_tick = false
	demo.ship_hud.visible = false
	for sky: String in ["rest", "cruise"]:
		demo.set_sky_state(sky)
		for v: String in ["bow", "stage", "overlook", "astern"]:
			await _shot("commons_%s_%s" % [v, sky], COURT, VIEWS[v])
		for v: String in ["bow", "stage"]:
			await _shot("garden_%s_%s" % [v, sky], GARDEN, VIEWS[v])
		await _shot("garden_rim_stage_%s" % sky, GARDEN_RIM, VIEWS.stage)
		await _shot("homes_rim_stage_%s" % sky, HOMES_RIM, VIEWS.stage)
		await _lift("lift_mid_%s" % sky)
	_sheet()
	var f := FileAccess.open(out + "/poses.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"about": "R2-LEVELS design mocks: camera poses (glTF metres, degrees)", "frames": rows}, "  "))
	print("levels-mock-capture: %d frames" % rows.size())
	quit(0)


## A walk-style pose: yaw/pitch in ShipCamera's convention (forward = (cos, 0, sin); 270 = the bow),
## the eye `back` metres behind the captain along the view's ground direction and `rise` above the deck.
func _pose(captain: Vector3, v: Dictionary) -> Transform3D:
	var y := deg_to_rad(float(v.yaw))
	var p := deg_to_rad(float(v.pitch))
	var ground := Vector3(cos(y), 0.0, sin(y))
	var eye := captain - ground * float(v.back) + Vector3(0.0, float(v.rise), 0.0)
	var dir := ground * cos(p) + Vector3(0.0, sin(p), 0.0)
	return Transform3D(Basis.looking_at(dir, Vector3.UP), eye)


func _place(captain: Vector3) -> void:
	demo.consoles.cancel_walk()
	demo.director.override()
	demo.active_level = 1 if captain.y < 80.0 else 0
	demo.walk = demo.walk_lower if captain.y < 80.0 else demo.walk_bridge
	demo.avatar_pos = captain
	demo.captain_yaw = -PI * 0.5
	demo.camera_mode = "review"
	for k in 30:
		demo._process(1.0 / 60.0)
	demo.avatar_pos = captain


func _shot(name: String, captain: Vector3, v: Dictionary) -> void:
	_place(captain)
	demo.camera.global_transform = _pose(captain, v)
	demo._sync_observer()
	await _save(name, {"captain": [captain.x, captain.y, captain.z], "view": v})


func _lift(name: String) -> void:
	_place(Vector3(8.0, 57.0, -4.8))
	var eye := Vector3(8.0, 70.0, 6.0)
	var dir := Vector3(0.0, sin(deg_to_rad(-12.0)), -cos(deg_to_rad(-12.0)))
	demo.camera.global_transform = Transform3D(Basis.looking_at(dir, Vector3.UP), eye)
	demo._sync_observer()
	await _save(name, {"eye": [eye.x, eye.y, eye.z], "pitch": -12.0})


func _save(name: String, pose: Dictionary) -> void:
	for k in 6:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [out, name])
	pose["name"] = name
	pose["fov_deg"] = demo.camera.fov
	pose["sky"] = demo.sky_state
	rows.append(pose)
	print("shot %s" % name)


func _sheet() -> void:
	var names := ["commons_bow_rest", "commons_stage_rest", "commons_overlook_rest", "commons_astern_rest",
		"commons_bow_cruise", "commons_stage_cruise", "garden_bow_cruise", "garden_stage_cruise",
		"garden_rim_stage_rest", "garden_rim_stage_cruise", "homes_rim_stage_cruise", "lift_mid_cruise"]
	var w := 480
	var h := 270
	var g := 16
	var cols := 4
	var img := Image.create(cols * (w + g) + g, 3 * (h + g) + g, false, Image.FORMAT_RGB8)
	img.fill(Color(0.06, 0.06, 0.08))
	for i in names.size():
		var path := ProjectSettings.globalize_path("%s/%s.png" % [out, names[i]])
		if not FileAccess.file_exists(path):
			continue
		var f := Image.load_from_file(path)
		f.convert(Image.FORMAT_RGB8)
		f.resize(w, h, Image.INTERPOLATE_LANCZOS)
		img.blit_rect(f, Rect2i(0, 0, w, h), Vector2i(g + (i % cols) * (w + g), g + (i / cols) * (h + g)))
	img.save_png("%s/contact_sheet.png" % out)
