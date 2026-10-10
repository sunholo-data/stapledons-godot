extends SceneTree
## I7 review evidence from actual protocol-2.8 worlds, never fixtures.
## AILANG_BIN=runtime/bin/ailang godot --path . --script tools/ism_hud_capture.gd
## Screens are renders/ism_hud/*_{1280x720,2560x1440}.png; open them before P2.

var demo: Node
var failed := false
var written := 0
const OUT := "res://renders/ism_hud"


func _initialize() -> void:
	_run.call_deferred()


func settle() -> void:
	for i in 8:
		demo._process(0.05)
		await process_frame
	await RenderingServer.frame_post_draw


func shot(name: String, sz: Vector2i) -> void:
	await settle()
	var img := root.get_texture().get_image()
	var path := "%s/%s_%dx%d.png" % [OUT, name, sz.x, sz.y]
	if img.get_size() != sz or img.save_png(path) != OK:
		push_error("ISM HUD frame dimensions %s, expected %s" % [img.get_size(), sz])
		failed = true
	else:
		written += 1
	print("ISM HUD frame: ", path)


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	for sz in [Vector2i(1280, 720), Vector2i(2560, 1440)]:
		await capture_size(sz)
	print("ism-hud-capture: %s (%d frames)" % ["FAIL" if failed else "OK", written])
	quit(1 if failed else 0)


func capture_size(sz: Vector2i) -> void:
	# macOS clamps ordinary windows to the usable area; the 1440p case must include
	# the menu/dock area too. Fullscreen preserves actual pixels without resizing PNGs.
	root.mode = Window.MODE_FULLSCREEN if sz.y >= 1440 else Window.MODE_WINDOWED
	root.size = sz
	await process_frame
	demo = load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options = {"live_start": true, "sky_state": "rest", "auto_view": true, "size": sz}
	root.add_child(demo)
	await process_frame
	demo.auto = false
	demo.journey_auto_tick = false
	if not demo.ready_ok or not IsmHud.supported(demo.hud_view()):
		failed = true
		return
	demo.look_direction("forward")
	await settle()
	# At rest the forward sky has empty rays; at relativistic cruise the identified
	# sources can fill the entire forward opening. Preserve that star-pick precedence.
	demo.toggle_sky_only()
	demo.star_identification.set_held(true)
	demo.star_identification.update_candidates()
	var picked := false
	for y in [0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8]:
		for x in [0.1, 0.2, 0.3, 0.4, 0.45, 0.5, 0.55, 0.6, 0.65]:
			if not picked: picked = demo.show_medium_at(demo.ship_hud.size * Vector2(x, y))
	if picked: await shot("medium_here_sky_only", sz)
	else:
		push_error("no empty forward ray for medium I card")
		failed = true
	demo.star_identification.set_held(false)
	demo.ship_hud.hide_card("medium_here")
	demo.toggle_sky_only()
	demo._process(0.7)
	demo.open_navigation()
	if not (demo.journey_map.open_commit_dialog() and demo.journey_map.hold_commit(GalaxyMap.HOLD_S) and demo.journey_tick()):
		failed = true
		return
	demo.close_navigation()
	for i in 4000:
		if demo.sky_world.ship.phase == "cruising": break
		demo.journey_tick()
	demo._process(0.05)
	await shot("transit", sz)
	demo.ship_hud.toggle_tab()
	await shot("tab_medium", sz)
	demo.ship_hud.toggle_tab()
	var first_medium: String = demo.sky_world.ship.ism.medium
	var boundary := false
	for i in 4000:
		if demo.sky_world.ship.phase != "cruising": break
		demo.journey_tick()
		demo._process(0.05)
		if str(demo.sky_world.ship.ism.medium) != first_medium:
			boundary = true
			break
	if not boundary:
		push_error("real route did not cross a medium during cruise")
		failed = true
	await shot("medium_boundary", sz)
	var before := CruiseInterlude.facts_from(demo.journey_sim.world, demo.stop_name())
	# The real sim advances through the rest of the cruise, as the interlude host does.
	var left: float = demo.journey_sim.world.consequence.phase_remaining_yr
	if not demo.journey_sim.send([], left * (1.0 - Transit.END_SLACK)):
		failed = true
		return
	demo.journey_map.refresh()
	demo._apply_journey_world()
	demo._process(0.05)
	var card := CardInterlude.new()
	card.begin(before)
	card.observe(demo.journey_sim.world, demo.stop_name())
	card.advance(0.0, 0.0)
	card.advance(0.0, 4.0)
	demo.interlude_card.show_interlude(card)
	demo.interlude_card.visible = true
	await shot("interlude_media", sz)
	demo.queue_free()
	await process_frame
