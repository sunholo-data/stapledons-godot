extends SceneTree
## Lightspeed loading view reference renders (design_docs/planned/r1/lightspeed-loading.md):
## the title's real sky taken over by LoadingJump.preview at displayed progress 0, 50, 90,
## 99 and 100 %, then the white-out (transition effect) and its fade, at 1280x720.
## Needs a GPU window.
## Run: godot --path . --resolution 1280x720 --script tools/loading_jump_capture.gd   (make loading-jump-capture)
var out := "res://renders/loading_jump"
const SHOTS := [["p000", 0.0], ["p050", 0.5], ["p090", 0.9], ["p099", 0.99], ["p100", 1.0], ["whiteout", 1.3], ["fade", 1.95]]


func _initialize() -> void:
	_run.call_deferred()


func _shot(name: String) -> void:
	for i in 12:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	var path := ProjectSettings.globalize_path(out).path_join(name + ".png")
	img.save_png(path)
	print("loading-jump-capture: %s %dx%d" % [path, img.get_width(), img.get_height()])


func _run() -> void:
	root.size = Vector2i(1280, 720)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var dir := ProjectSettings.globalize_path("res://.godot/tmp/loading_jump_capture")
	DirAccess.make_dir_recursive_absolute(dir)
	var layer := CanvasLayer.new()
	root.add_child(layer)
	var t := TitleScreen.new({"pan": false, "settings_dir": dir})
	layer.add_child(t)
	for i in 20:
		await process_frame
	# the destination under the fade: a plain dark backdrop stands in for the ship here
	var under := ColorRect.new()
	under.color = Color(0.05, 0.06, 0.09)
	under.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var ul := CanvasLayer.new()
	ul.layer = 50
	ul.add_child(under)
	root.add_child(ul)
	var jump := LoadingJump.new()
	root.add_child(jump)
	var sky := t.sky
	t.sky = null
	for s in SHOTS:
		jump.preview(sky, "ship", s[1])
		var v := LoadingJump.speed_at(minf(s[1], 1.0))
		print("loading-jump-capture: %s shown %.2f beta %.6f gamma %.2f 1-beta %s" % [s[0], s[1], v[0], v[1], LoadingJump.omb_text(v[2])])
		await _shot(s[0])
	quit(0)
