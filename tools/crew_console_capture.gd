extends SceneTree
## R2-CREW-CONSOLE-V2 V3 review frames (AC15): the Crew console in the ship's console panel, laid
## out at the project's logical 960 x 540 (canvas_items, expand) and captured at 1280 x 720 and
## 2560 x 1440, from crews recorded from the real sim (tests/crew/console_v2/*.json, protocol 2.11):
##   board       the idle roster: whose move first, chips, quick actions, the header strip, legend
##   offer       a call to the counselor: Ask or Order inline, the Offer armed (its confirm)
##   sending     the offer confirmed, the ship not yet ticked: Sent, waiting for the ship
##   concern     the pilot's concern: four answers (Insist last), Start disabled with its reason
##   working     the analyst at work, day k of n, and whose move it is across the others
##   hold        auto-run held for the medic: the hold's words and Resume in the call
##   declined    the medic's decline: open to talk, the answers, Make it an order
##   standdown   crew_core 0.6: a stand-down handed to the captain (Let them rest / Ask them to carry on)
##   resting     the medic resting after it was granted
##   board_working  the board while work runs, the legend open and the keyboard focus on a row
## Each frame asserts no label under 12 logical, a call portrait of at least 240 logical, nothing
## outside the console panel, and reports the portrait's upscale over its 256 px source.
## Run:  make crew-console-capture  (needs a GPU window; open every frame)

const OUT := "res://renders/crew_console"
const LOGICAL := Vector2i(960, 540)
const SOURCE_PX := 256.0

var failures := 0
var frames := 0


func _initialize() -> void:
	_run.call_deferred()


func fixture(name: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://tests/crew/console_v2/%s.json" % name))


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	root.content_scale_size = LOGICAL
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
	for res in [Vector2i(1280, 720), Vector2i(2560, 1440)]:
		DisplayServer.window_set_size(res)
		root.size = res
		for i in 4:
			await process_frame
		await _frames(res)
	print("crew-console-capture: %d frames in renders/crew_console, %d failures" % [frames, failures])
	quit(1 if failures else 0)


## The ship console's panel as ShipConsoles lays out the Crew console: full width under the HUD
## strip, the title row above the console.
func _stage() -> Array:
	for c in root.get_children():
		root.remove_child(c)
		c.queue_free()
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.025, 0.04)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)
	var panel := PanelContainer.new()
	panel.name = "ConsolePanel"
	panel.theme = StapledonTheme.theme(); panel.theme_type_variation = "HUDSheet"
	var r := ShipConsoles.crew_panel_rect(Vector2(root.get_visible_rect().size), 42.0)
	panel.position = r.position
	panel.custom_minimum_size = r.size
	panel.size = r.size
	root.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	var title := Label.new()
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.95, 0.82, 0.5))
	box.add_child(title)
	var c := CrewConsole.new()
	c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	c.title_changed.connect(func(t: String) -> void: title.text = t)
	box.add_child(c)
	return [c, panel, title, r]


func _frames(res: Vector2i) -> void:
	var tag := "%dx%d" % [res.x, res.y]
	var s := _stage()
	var c: CrewConsole = s[0]
	c.show_crew(fixture("board"))
	await _shot("board", tag, s)

	s = _stage(); c = s[0]
	c.show_crew(fixture("board"))
	c.press("quick:counselor:offer:counselor")
	await _shot("offer", tag, s)

	s = _stage(); c = s[0]
	c.show_crew(fixture("board"))
	c.press("call:counselor")
	c.press("offer:counselor")
	c.press("offer:counselor")
	await _shot("sending", tag, s)

	s = _stage(); c = s[0]
	c.show_crew(fixture("board"))
	c.show_crew(fixture("mixed")) # the medic's decline comes in first and opens her call; the pilot's pulses
	c.press("call:pilot")
	await _shot("concern", tag, s)

	s = _stage(); c = s[0]
	c.show_crew(fixture("working"))
	c.press("call:analyst")
	await _shot("working", tag, s)

	s = _stage(); c = s[0]
	c.show_crew(fixture("board"))
	c.show_crew(fixture("hold"))
	await _shot("hold", tag, s)

	s = _stage(); c = s[0]
	c.show_crew(fixture("mixed"))
	c.press("call:medic")
	await _shot("declined", tag, s)

	s = _stage(); c = s[0]
	c.show_crew(fixture("board"))
	c.show_crew(fixture("standdown")) # crew_core 0.6: auto-run hands the stand-down to the captain
	await _shot("standdown", tag, s)

	s = _stage(); c = s[0]
	c.show_crew(fixture("resting"))
	c.press("call:medic")
	await _shot("resting", tag, s)

	s = _stage(); c = s[0]
	c.show_crew(fixture("working")) # the board while work runs, with the legend open (?)
	c.press("help:legend")
	var down := InputEventKey.new()
	down.pressed = true
	down.physical_keycode = KEY_DOWN
	c.key(down) # V6: the focus ring on the first row
	await _shot("board_working", tag, s)


func _shot(name: String, tag: String, s: Array) -> void:
	for i in 4:
		await process_frame
	var c: CrewConsole = s[0]
	var panel: Control = s[1]
	var small := []
	for l in c.find_children("*", "Label", true, false):
		var px := (l as Label).get_theme_font_size("font_size")
		if l.is_visible_in_tree() and px < 12:
			small.append("%s %d" % [l.name, px])
	var portrait: Control = c.find_child("CallPortrait", true, false)
	var pr := portrait.get_global_rect() if portrait != null else Rect2()
	var clipped := []
	var pr_panel: Rect2 = (s[3] as Rect2).grow(1.5)
	if not pr_panel.encloses(panel.get_global_rect()):
		clipped.append("ConsolePanel grew to %s" % [panel.get_global_rect().size])
	for n in c.find_children("*", "Control", true, false):
		var ctl := n as Control
		if ctl.is_visible_in_tree() and ctl.size.x > 0.0 and not pr_panel.encloses(ctl.get_global_rect()):
			clipped.append(str(ctl.name))
	var words := 0
	for n in c.find_children("*", "", true, false):
		if (n is Label or n is Button) and (n as Control).is_visible_in_tree():
			words += (n.text as String).split(" ", false).size()
	var img := root.get_texture().get_image()
	var file := "%s_%s.png" % [name, tag]
	img.save_png(ProjectSettings.globalize_path(OUT.path_join(file)))
	frames += 1
	var scale := float(img.get_width()) / float(LOGICAL.x)
	var up := pr.size.x * scale / SOURCE_PX
	var ok := small.is_empty() and clipped.is_empty() and (portrait == null or pr.size.x >= 240.0)
	if not ok:
		failures += 1
	print("frame %s %dx%d %s words %d%s%s%s" % [file, img.get_width(), img.get_height(), "ok" if ok else "FAIL", words,
		(" portrait %.0f logical, %.2fx its source%s" % [pr.size.x, up, " (soft: above 2.6x, OQ7)" if up > 2.6 else ""]) if portrait != null else "",
		(" small labels %s" % [small]) if not small.is_empty() else "", (" outside the panel %s" % [clipped.slice(0, 6)]) if not clipped.is_empty() else ""])
