extends SceneTree
## Title screen reference renders (design_docs/planned/r1/title-screen.md): the menu over
## the real sky, the settings panel and the credits, at 1280x720. Needs a GPU window.
## Run: godot --path . --resolution 1280x720 --script tools/title_screen_capture.gd   (make title-capture)
var out := "res://renders/title_screen"


func _initialize() -> void:
	_run.call_deferred()


func _shot(name: String) -> void:
	for i in 30:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var path := ProjectSettings.globalize_path(out).path_join(name + ".png")
	img.save_png(path)
	print("title-capture: %s %dx%d" % [path, img.get_width(), img.get_height()])


func _run() -> void:
	root.size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var dir := ProjectSettings.globalize_path("res://.godot/tmp/title_capture")
	DirAccess.make_dir_recursive_absolute(dir)
	var layer := CanvasLayer.new()
	root.add_child(layer)
	var t := TitleScreen.new({"pan": false, "settings_dir": dir})
	layer.add_child(t)
	await _shot("title")
	t.buttons["settings"].pressed.emit()
	await _shot("settings")
	t.close_panels()
	t.buttons["credits"].pressed.emit()
	await _shot("credits")
	quit(0)
