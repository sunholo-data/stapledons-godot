extends SceneTree
## R3-COMMS-V2 review captures (design r3/comms-station-v2.md AC12; GPU window): the bridge with the
## consoles under the screens and the monitor wall, on the live sim at 2.18 (the ship demo's own session:
## seed, crew and Earth link as in play), so every monitor shows real fields.
##   at_rest_*    at Sol before departure: Bow from the spawn, from the chair, from the comms desk
##   cruise_*     under way at 0.99c to Alpha Cen A (Earth's rate about 0.07): Bow from the spawn, the
##                chair, the comms desk, the crew console; Astern from the spawn
##   zoom_*       the comms and crew console zooms (the game's focus pose), the screen above the desk
##   station_*    the comms station's detail view (feed, waterfall, history wall, light strip) under way
##   plan         top down, bow up
##   rail_*       close-ups of the bow rail at the signal and course monitors (Mark 2026-11-03: the rail
##                must never pass through a screen): from the rim walk beside each, eye height, looking
##                along the rail under the screen to its stalk
## Writes renders/comms_v2/<tag>/*.png. Run: make capture-comms-v2 (open every frame).

const PX := Vector2i(1280, 720)
const TARGET := "Gaia DR3 4472832130942575872"
var demo: Node
var out := "res://renders/comms_v2/mid"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	root.size = PX
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.content_scale_size = PX
	demo = load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options = {"size": PX, "live_start": true, "sky_state": "rest"}
	root.add_child(demo)
	await process_frame
	if not demo.ready_ok:
		print("comms-v2-capture: FAIL demo did not build")
		quit(1)
		return
	demo.auto = false
	demo.journey_auto_tick = false
	demo.escape_exits = false
	demo.ship_hud.visible = false
	step(1.0)
	await shot_at("at_rest_bow_spawn", "bow", demo.bridge_spawn())
	await shot_at("at_rest_bow_chair", "bow", chair())
	await shot_at("at_rest_bow_comms", "bow", demo.consoles.stations.comms.use)
	await plan()
	await rail_closeup("rail_signal", -30.0, -1.0)
	await rail_closeup("rail_course", 24.0, 1.0)
	# commit at the helm, then fly into the cruise
	var c: ShipConsoles = demo.consoles
	c.go_to("navigation")
	c.use("navigation", "open")
	c.use("navigation", "select", TARGET)
	demo.journey_tick()
	var ok: bool = c.use("navigation", "commit") and demo.journey_tick()
	c.escape()
	var guard := 0
	while ok and guard < 4000 and str(demo.journey_sim.world.get("ship", {}).get("phase", "")) != "cruising":
		ok = demo.journey_tick()
		guard += 1
	for i in 30:
		ok = ok and demo.journey_tick()
	print("comms-v2-capture: under way %s phase %s rate %s in_beam %s" % [ok, demo.journey_sim.world.get("ship", {}).get("phase"), demo.journey_sim.world.get("earth", {}).get("rate"), demo.journey_sim.world.get("earth", {}).get("in_beam")])
	demo.ship_hud.visible = false
	step(1.0)
	await shot_at("cruise_bow_spawn", "bow", demo.bridge_spawn())
	await shot_at("cruise_bow_chair", "bow", chair())
	await shot_at("cruise_bow_comms", "bow", c.stations.comms.use)
	await shot_at("cruise_bow_crew", "bow", c.stations.crew.use)
	await shot_at("cruise_astern_spawn", "astern", demo.bridge_spawn())
	await zoom("comms")
	await zoom("crew")
	await station()
	print("comms-v2-capture: done -> %s" % out)
	quit(0)


func step(seconds: float) -> void:
	var t := 0.0
	while t < seconds:
		demo._process(1.0 / 30.0)
		t += 1.0 / 30.0


func chair() -> Vector3:
	var seat: Array = demo.manifest.captain_chair.position_m
	return demo.walk_bridge.closest_walkable(Vector3(float(seat[0]), 82.0, -float(seat[1]) + 2.0), 2.0)


func save(name: String) -> void:
	# real time, so the receiver's taps mix and the waterfalls fill (audio runs on the wall clock)
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 3000:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("%s/%s.png" % [out, name]))
	print("shot %s" % name)


func shot_at(name: String, view: String, foot: Vector3) -> void:
	demo.consoles.cancel_walk()
	demo.director.walk(view)
	demo.avatar_pos = foot
	step(6.0)
	await save(name)


func zoom(id: String) -> void:
	var c: ShipConsoles = demo.consoles
	c.go_to(id)
	step(1.0)
	c.use(id, "open")
	step(8.0)
	c.panel.visible = false
	await save("zoom_" + id)
	c.escape()
	step(8.0)


func station() -> void:
	var c: ShipConsoles = demo.consoles
	c.go_to("comms")
	step(1.0)
	c.use("comms", "open")
	step(3.0)
	await save("station_comms")
	var h: EarthHistory = c.comms_station.history
	if h.records.size() > 1:
		h.select(1)
		step(0.5)
		await save("station_comms_week_selected")
		h.select(1)
	c.escape()
	step(6.0)


## A close-up of the rail under monitor `bearing` (degrees, + starboard): the eye on the rim walk 7 deg to
## one side (`side` -1 port, +1 starboard) at 1.5 m, looking at the rail's top under the screen's centre.
func rail_closeup(name: String, bearing: float, side: float) -> void:
	var at := func(b: float, r: float, h: float) -> Vector3: return Vector3(r * sin(deg_to_rad(b)), 82.0 + h, -r * cos(deg_to_rad(b)))
	var cam := Camera3D.new()
	demo.camera.get_parent().add_child(cam)
	cam.fov = 60.0
	var eye: Vector3 = at.call(bearing + side * 7.0, 20.2, 1.5)
	var look: Vector3 = at.call(bearing, 21.2, 1.25)
	cam.global_transform = Transform3D(Basis.looking_at(look - eye, Vector3.UP), eye)
	cam.current = true
	await save(name)
	cam.current = false
	demo.camera.current = true
	cam.queue_free()


func plan() -> void:
	var cam := Camera3D.new()
	demo.camera.get_parent().add_child(cam)
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 46.0
	cam.far = 400.0
	cam.global_transform = Transform3D(Basis.looking_at(Vector3.DOWN, ShipCamera.BOW), Vector3(0, 142.0, 0))
	cam.current = true
	await save("plan")
	cam.current = false
	demo.camera.current = true
	cam.queue_free()
