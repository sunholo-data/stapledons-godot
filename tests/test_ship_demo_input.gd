extends SceneTree
## R2-CAMERA (camera-fixed-views.md AC2, AC3): players get fixed zoom levels and no look. A menu
## launch: mouse motion (plain, Option, right-drag) never turns the view; one wheel notch is one
## level; 0.25 + 0.25 + 0.5 trackpad units are one level, then a 0.3 s cooldown; a pinch steps;
## horizontal scroll is ignored; lift travel and the benchmark block. The developer free camera
## (F8, command-line launches only) keeps today's look and dolly, and its asserts run there.
var failures:=0
var passes:=0
func check(label: String, ok: bool) -> void:
	if ok:passes+=1
	else:failures+=1
	print("%s %s" % ["ok" if ok else "FAIL",label])
func _initialize() -> void:_run.call_deferred()
func new_demo(opts:Dictionary) -> Node:
	var demo: Node=load("res://demos/ship_geometry_demo.tscn").instantiate()
	var o:={"stars":false,"background":false};o.merge(opts,true)
	demo.setup_options=o;root.add_child(demo);await process_frame
	demo.auto=false;demo.escape_exits=false
	return demo
func advance(demo:Node,seconds:float)->void:
	var t:=0.
	while t<seconds:demo._process(1./60.);t+=1./60.
func _run() -> void:
	DirAccess.make_dir_recursive_absolute("user://test_ship_demo_input")
	var demo:Node=await new_demo({"from_menu":true,"settings_dir":"user://test_ship_demo_input"})
	var dir:CameraDirector=demo.director
	advance(demo,.5)
	check("menu launch: Z2 Deck by default, mouse look off, pointer not captured",dir.level==2 and not demo.wants_capture() and Input.mouse_mode!=Input.MOUSE_MODE_CAPTURED)
	var pose:Transform3D=demo.camera.global_transform
	var motion:=InputEventMouseMotion.new();motion.relative=Vector2(20,10)
	demo._unhandled_input(motion)
	motion.alt_pressed=true;demo._unhandled_input(motion)
	motion.alt_pressed=false;motion.button_mask=MOUSE_BUTTON_MASK_RIGHT;demo._unhandled_input(motion)
	advance(demo,.1)
	check("plain, Option and right-drag motion never turn the view",demo.camera.global_transform.is_equal_approx(pose))
	# One convention (zoom in = closer): the wheel rolled up, a scroll up (pan delta.y < 0, the
	# direction Godot reports as wheel up) and a pinch open all come closer.
	var wheel:=InputEventMouseButton.new();wheel.button_index=MOUSE_BUTTON_WHEEL_UP;wheel.pressed=true;wheel.factor=1.
	demo._unhandled_input(wheel)
	check("one wheel notch up is one level closer (Z2 -> Z1)",dir.level==1)
	advance(demo,.6)
	var pan:=InputEventPanGesture.new()
	for d in [.25,.25]:
		pan.delta=Vector2(0,d);demo._unhandled_input(pan)
	check("0.5 trackpad units do not step",dir.level==1)
	pan.delta=Vector2(0,.5);demo._unhandled_input(pan)
	check("0.25 + 0.25 + 0.5 units of scroll down are one level farther (Z1 -> Z2)",dir.level==2)
	pan.delta=Vector2(0,1.5);demo._unhandled_input(pan)
	check("the rest of the same gesture is ignored",dir.level==2)
	advance(demo,.6)
	# The accumulator decays: a partial swipe, a long pause, a partial swipe is no step.
	pan.delta=Vector2(0,.6);demo._unhandled_input(pan)
	advance(demo,10.)
	pan.delta=Vector2(0,.5);demo._unhandled_input(pan)
	check("0.6 units, 10 s idle, 0.5 units: no step (the accumulator resets after 0.5 s idle)",dir.level==2)
	advance(demo,.6)
	# One gesture's inertial tail, with a 0.35 s gap inside it, is one gesture: one step.
	var start0:int=dir.level
	for i in 20:
		pan.delta=Vector2(0.,-0.6*exp(-i/6.)-0.02);demo._unhandled_input(pan);advance(demo,1./60.)
	advance(demo,.35)
	for i in 20:
		pan.delta=Vector2(0.,-0.05);demo._unhandled_input(pan);advance(demo,1./60.)
	check("an inertial tail with a 0.35 s gap inside it is one gesture: one level (%d -> %d)" % [start0,dir.level],dir.level==start0-1)
	advance(demo,.6)
	pan.delta=Vector2(2,0);demo._unhandled_input(pan)
	check("horizontal scrolling does not change the level",dir.level==1)
	var pinch:=InputEventMagnifyGesture.new();pinch.factor=0.8;demo._unhandled_input(pinch)
	check("a pinch close steps one level out (Z1 -> Z2)",dir.level==2)
	advance(demo,.6)
	# A MacBook two-finger swipe: ~40 pan events over 0.65 s, a burst then an inertial tail
	# (deltas 0.6 falling to 0.02), events every 1/60 s. One deliberate swipe is one level.
	advance(demo,.4)
	var start:int=dir.level
	for i in 40:
		pan.delta=Vector2(0.,0.6*exp(-i/8.)+0.02);demo._unhandled_input(pan);advance(demo,1./60.)
	check("MacBook swipe out (scroll down, burst + inertial tail, %d events): exactly one level (%d -> %d)" % [40,start,dir.level],dir.level==start+1)
	advance(demo,.6)
	start=dir.level
	for i in 40:
		pan.delta=Vector2(0.,-0.6*exp(-i/8.)-0.02);demo._unhandled_input(pan);advance(demo,1./60.)
	check("MacBook swipe in (scroll up): exactly one level (%d -> %d)" % [start,dir.level],dir.level==start-1)
	advance(demo,.6)
	# A trackpad pinch: magnify events of x1.02 each over 0.5 s (x1.81 in all): one level.
	start=dir.level
	for i in 30:
		pinch.factor=0.98;demo._unhandled_input(pinch);advance(demo,1./60.)
	check("MacBook pinch close (30 x0.98 magnify events): exactly one level out (%d -> %d)" % [start,dir.level],dir.level==start+1)
	advance(demo,.6)
	start=dir.level
	for i in 30:
		pinch.factor=1.02;demo._unhandled_input(pinch);advance(demo,1./60.)
	check("MacBook pinch open (30 x1.02): exactly one level in (%d -> %d)" % [start,dir.level],dir.level==start-1)
	advance(demo,.4)
	demo.set_preset("reset");advance(demo,.1)
	check("lift can board",demo.lift.board())
	pan.delta=Vector2(0,1.);demo._unhandled_input(pan);demo._unhandled_input(wheel)
	advance(demo,.1)
	check("scroll and wheel cannot change the level in the moving lift",dir.level==2 and dir.view_id=="lift")
	demo.set_preset("reset");advance(demo,.35);demo.benchmark.running=true
	demo._unhandled_input(pan);demo._unhandled_input(wheel);demo._unhandled_input(motion)
	check("benchmark blocks gestures",dir.level==2)
	demo.benchmark.running=false
	var f8:=InputEventKey.new();f8.physical_keycode=KEY_F8;f8.pressed=true
	demo._unhandled_input(f8)
	check("menu launch: F8 does not open the developer free camera",not demo.free_camera_on())
	demo.queue_free();await process_frame
	# The developer free camera: today's look and dolly, command-line launches only.
	demo=await new_demo({})
	demo._unhandled_input(f8)
	check("command-line launch: F8 opens the developer free camera",demo.free_camera_on())
	demo.camera.pullback=3.
	motion=InputEventMouseMotion.new();motion.relative=Vector2(20,10)
	var yaw: float=demo.camera.yaw
	demo._unhandled_input(motion);check("free camera: plain pointer motion looks",demo.camera.yaw!=yaw)
	yaw=demo.camera.yaw
	motion.alt_pressed=true;demo._unhandled_input(motion)
	check("free camera: Option motion looks without a held click",demo.camera.yaw!=yaw and demo.camera.tilt<-18.)
	yaw=demo.camera.yaw;motion.alt_pressed=false;motion.button_mask=MOUSE_BUTTON_MASK_RIGHT;demo._unhandled_input(motion)
	check("free camera: held right mouse still looks",demo.camera.yaw!=yaw)
	pan.delta=Vector2(0,.25)
	var distance: float=demo.camera.pullback;demo._unhandled_input(pan)
	check("free camera: fractional two-finger scroll smoothly dollies",is_equal_approx(demo.camera.pullback,distance-.5))
	distance=demo.camera.pullback;pan.delta=Vector2(2,0);demo._unhandled_input(pan)
	check("free camera: horizontal scrolling does not dolly",demo.camera.pullback==distance)
	demo.set_preset("overview");distance=demo.camera.position.distance_to(Vector3(0,5,0))
	pan.delta=Vector2(0,.5);demo._unhandled_input(pan)
	check("free camera: whole-ship scroll stays in overview and zooms",demo.camera_mode=="external review" and demo.camera.position.distance_to(Vector3(0,5,0))<distance)
	demo._unhandled_input(f8)
	check("F8 again: back to the player camera",not demo.free_camera_on() and not demo.director.overridden)
	print("ship-demo-input: %d passed, %d failures" % [passes,failures]);quit(1 if failures else 0)
