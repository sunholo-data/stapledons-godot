extends SceneTree
## R2-DECK-LAYOUT DL2 review captures (design_docs/planned/r2/deck-layout.md §D5, §D5a; D-96): the
## dressed navigation arc and chair under the bridge's two keys. GPU window, 1280x720:
##   deep_*       interstellar at rest (the review "rest" world with its system pushed ~1.7 ly away):
##                no star close, the spire lights the bridge
##   star_*       near the Sun (the review "rest" world): the star is the key, the spire at its floor
##   cruise_*     0.99c in interstellar space: the spire light under the starbow
##   *_bow        the player's Bow view at the spawn;  *_style  a close three-quarter view of the arc
##                and the chair (review only, not a game view);  *_nav  the game's navigation zoom
##   handover_N   the style view as the Sun's light at the ship rises from 0.1 lx to 1e5 lx: the spire
##                hands the key to the star
## Writes renders/deck_layout/<tag>/*.png, contact_sheet.png and dl2.json (the lights' energies).
## Usage: godot --path . --script tools/deck_dl2_capture.gd -- [--out=res://renders/deck_layout/dl2]
var demo: Node
var out := "res://renders/deck_layout/dl2"
var px := Vector2i(1280, 720)
var rows := []
const STYLE_EYE := Vector3(-4.3, 84.1, -9.6) # glTF: stern-port of the chair, above the deck
const STYLE_AIM := Vector3(0.6, 83.1, -16.6) # the middle pod's screen, the chair in the foreground
const HANDOVER_LUX := [0.1, 10.0, 300.0, 1.0e4, 1.0e5]


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
		print("deck-dl2-capture: FAIL demo did not build")
		quit(1)
		return
	demo.auto = false
	demo.journey_auto_tick = false
	demo.ship_hud.visible = false
	var rest: Dictionary = _with_sun(demo.sky_states.rest)
	demo.sky_states["star"] = rest
	demo.sky_states["deep"] = _pushed(rest, 2.5e8)
	for st: String in ["deep", "star", "cruise"]:
		var tag: String = {"deep": "deep", "star": "star", "cruise": "cruise"}[st]
		demo.set_sky_state(st)
		await _bow(tag)
		await _style(tag)
		await _nav(tag)
	demo.set_sky_state("star")
	for i in HANDOVER_LUX.size():
		var w: Dictionary = rest.duplicate(true)
		for b: Dictionary in w.system.bodies:
			if b.get("id", "") == "sun":
				b.e_v_lux = HANDOVER_LUX[i]
		demo.sky_states["handover"] = w
		demo.set_sky_state("handover")
		await _style("handover_%d" % i, "%s lx" % str(HANDOVER_LUX[i]))
	_sheet()
	var f := FileAccess.open(out + "/dl2.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"about": "R2-DECK-LAYOUT DL2 captures: the lights per frame", "frames": rows}, "  "))
	print("deck-dl2-capture: %d frames" % rows.size())
	quit(0)


## The review "rest" world (no system section) with the Sun's system from the star-light test's
## recording (tests/fixtures/system_sol.ndjson): the observer near Earth, 1 AU from the Sun, the
## Sun's illuminance the sim's 1.27e5 lx at 1 AU; Earth itself removed so it does not fill the frame.
func _with_sun(world: Dictionary) -> Dictionary:
	var w := world.duplicate(true)
	var lines := FileAccess.get_file_as_string("res://tests/fixtures/system_sol.ndjson").strip_edges().split("\n")
	var sys: Dictionary = SimBridge.parse_system(JSON.parse_string(lines[1]).changes.system)
	var earth := {}
	for b: Dictionary in sys.bodies:
		if b.id == "earth":
			earth = b.rel_km.duplicate()
	var keep := []
	for b: Dictionary in sys.bodies:
		if b.id == "earth":
			continue
		b.rel_km = {"x": b.rel_km.x - earth.x, "y": b.rel_km.y - earth.y, "z": b.rel_km.z - earth.z}
		if b.id == "sun":
			var d := sqrt(b.rel_km.x * b.rel_km.x + b.rel_km.y * b.rel_km.y + b.rel_km.z * b.rel_km.z)
			b.e_v_lux = 1.27e5 * pow(SystemView.AU_KM / d, 2.0)
		keep.append(b)
	sys.bodies = keep
	w.system = sys
	return w


## The review world with every body moved `s` times further and dimmed by s^2 (no star close).
func _pushed(world: Dictionary, s: float) -> Dictionary:
	var w := world.duplicate(true)
	for b: Dictionary in w.system.bodies:
		var r: Dictionary = b.rel_km
		b.rel_km = {"x": r.x * s, "y": r.y * s, "z": r.z * s}
		if b.has("e_v_lux"):
			b.e_v_lux = float(b.e_v_lux) / (s * s)
	return w


func _settle(frames := 240) -> void:
	for k in frames:
		demo._process(1.0 / 60.0)


func _save(name: String, note := "") -> void:
	for k in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s/%s.png" % [out, name])
	var rig: Dictionary = demo.lighting
	var r := {"name": name, "note": note, "star": demo.star_light.target.get("name", ""), "star_energy": demo.star_light.light.light_energy,
		"key_energy": rig.key.light_energy, "spire_energy": rig.spire.light_energy, "spire_lamp": (rig.spire_lamp.material_override as StandardMaterial3D).emission_energy_multiplier}
	rows.append(r)
	print("shot %s star %s %.2f key %.2f spire %.2f %s" % [name, r.star, r.star_energy, r.key_energy, r.spire_energy, note])


func _bow(tag: String) -> void:
	demo.consoles.cancel_walk()
	demo.director.release()
	demo.camera_mode = "player"
	demo.director.walk("bow")
	demo.avatar_pos = demo.bridge_spawn()
	_settle()
	await _save(tag + "_bow")


func _style(tag: String, note := "") -> void:
	demo.director.override()
	demo.camera_mode = "player"
	demo.avatar_pos = demo.consoles.stations.navigation.use
	_settle(30)
	demo.camera_mode = "review" # not "player": the overridden camera then holds this pose (no follow)
	demo.camera.global_transform = Transform3D(Basis.looking_at(STYLE_AIM - STYLE_EYE, Vector3.UP), STYLE_EYE)
	demo._sync_observer()
	await _save(tag + ("" if tag.begins_with("handover") else "_style"), note)
	demo.camera_mode = "player"
	demo.director.release()


## The game's navigation zoom pose (ShipConsoles.focus_pose: 1.25 m out on the operator's side,
## 0.55 m above the screen), held without opening the station (its chart would cover the frame).
func _nav(tag: String) -> void:
	var c: ShipConsoles = demo.consoles
	demo.director.override()
	demo.avatar_pos = c.stations.navigation.use
	demo.camera_mode = "review"
	demo.avatar.visible = false
	demo.camera.global_transform = c.focus_pose("console_navigation_1")
	demo._sync_observer()
	await _save(tag + "_nav")
	demo.camera_mode = "player"
	demo.director.release()


func _sheet() -> void:
	var names := ["deep_bow", "star_bow", "cruise_bow", "deep_nav", "deep_style", "star_style", "cruise_style", "star_nav", "handover_0", "handover_1", "handover_3", "handover_4"]
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
