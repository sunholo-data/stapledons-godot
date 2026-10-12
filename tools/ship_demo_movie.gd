extends SceneTree
## Deterministic presentation route at 24 fps; no sim time advance/velocity mutation.
var demo: Node
var frame:=0
const FPS:=24.
const OUT:="res://renders/ship_demo/movie"
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	root.size=Vector2i(1280,720)
	demo=load("res://demos/ship_geometry_demo.tscn").instantiate();root.add_child(demo);await process_frame;demo.auto=false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	demo.set_preset("reset");demo.set_preset("bridge")
	for i in 24:await _frame()
	if not demo.lift.board():quit(1);return
	for i in 310:demo.lift.advance(1./FPS);await _frame()
	if demo.lift.state!="lower_ready":quit(1);return
	for i in 24:
		demo.avatar_pos=demo.walk.step(demo.avatar_pos,Vector3(.08,0,0));await _frame()
	for i in 24:
		demo.avatar_pos=demo.walk.step(demo.avatar_pos,Vector3(-.08,0,0));await _frame()
	if not demo.lift.board():quit(1);return
	for i in 310:demo.lift.advance(1./FPS);await _frame()
	if demo.lift.state!="bridge_ready":quit(1);return
	print("ship-demo-movie: OK %d frames at24fps" % frame);quit()
func _frame() -> void:
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+"/%05d.png" % frame);frame+=1
