extends SceneTree
var failures:=0
var passes:=0
func check(label: String, ok: bool) -> void:
	if ok:passes+=1
	else:failures+=1
	print("%s %s" % ["ok" if ok else "FAIL",label])
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	var demo: Node=load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options={"stars":false,"background":false};root.add_child(demo);await process_frame
	demo.auto=false
	# Start zoom test away from the zero-pullback clamp; default is captain-eye.
	demo.camera.pullback=3.
	var motion:=InputEventMouseMotion.new();motion.relative=Vector2(20,10)
	var yaw: float=demo.camera.yaw
	demo._unhandled_input(motion);check("plain pointer motion looks by default",demo.camera.yaw!=yaw)
	motion.alt_pressed=true;demo._unhandled_input(motion)
	check("Option motion looks without a held click",demo.camera.yaw!=yaw and demo.camera.tilt<-18.)
	yaw=demo.camera.yaw;motion.alt_pressed=false;motion.button_mask=MOUSE_BUTTON_MASK_RIGHT;demo._unhandled_input(motion)
	check("held right mouse still looks",demo.camera.yaw!=yaw)
	var pan:=InputEventPanGesture.new();pan.delta=Vector2(0,.25)
	var distance: float=demo.camera.pullback;demo._unhandled_input(pan)
	check("fractional two-finger scroll smoothly zooms",is_equal_approx(demo.camera.pullback,distance-.5))
	distance=demo.camera.pullback;pan.delta=Vector2(2,0);demo._unhandled_input(pan)
	check("horizontal scrolling does not change zoom",demo.camera.pullback==distance)
	demo.set_preset("overview");distance=demo.camera.position.distance_to(Vector3(0,5,0))
	pan.delta=Vector2(0,.5);demo._unhandled_input(pan)
	check("whole-ship scroll stays in overview and zooms",demo.camera_mode=="external review" and demo.camera.position.distance_to(Vector3(0,5,0))<distance)
	demo.set_preset("reset");check("lift can board",demo.lift.board())
	demo._unhandled_input(pan);check("scroll cannot pull camera out of moving lift",demo.camera.pullback==0.)
	demo.set_preset("reset");demo.benchmark.running=true
	distance=demo.camera.pullback;yaw=demo.camera.yaw;motion.alt_pressed=true
	demo._unhandled_input(pan);demo._unhandled_input(motion)
	check("benchmark blocks gestures and looking",demo.camera.pullback==distance and demo.camera.yaw==yaw)
	demo.benchmark.running=false
	print("ship-demo-input: %d passed, %d failures" % [passes,failures]);quit(1 if failures else 0)
