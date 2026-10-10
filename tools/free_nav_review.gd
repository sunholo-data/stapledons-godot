extends SceneTree
## D-63: native pointer routing, playable Earth stop and discoverable map captures.
var demo:Node
var failures:=0
func check(label:String,ok:bool)->void:
	print("%s %s"%["ok" if ok else "FAIL",label])
	if not ok:failures+=1
func _initialize()->void:run.call_deferred()
func settle()->void:
	for i in 8:await process_frame
	await RenderingServer.frame_post_draw
func key(code:int,pressed:=true)->void:
	var e:=InputEventKey.new();e.physical_keycode=code;e.keycode=code;e.pressed=pressed
	Input.parse_input_event(e);await settle()
func motion()->void:
	var e:=InputEventMouseMotion.new();e.position=Vector2(root.size)*.5;e.global_position=e.position;e.relative=Vector2(8,4)
	Input.parse_input_event(e);await settle()
func shot(name:String)->void:
	await settle();root.get_texture().get_image().save_png("res://renders/free_nav/"+name+".png")
func run()->void:
	root.size=Vector2i(1280,720);root.title="Stapledon native navigation review";root.grab_focus()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://renders/free_nav"))
	demo=load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options={"live_start":true,"sky_state":"rest","auto_view":true,"size":root.size}
	root.add_child(demo);await settle();demo.journey_auto_tick=false
	print("NATIVE focus wait: pid=%d"%OS.get_process_id())
	for i in 30:
		if root.has_focus():break
		await create_timer(.1).timeout
	check("free launch applies an actual rest world",demo.sky_state=="live" and demo.sky_world.ship.beta==0.)
	print("Native pointer checks require a foreground focused window; focus=%s"%root.has_focus())
	print("POINTER state focus=%s ui=%s mode=%s"%[root.has_focus(),demo.pointer_required(),Input.mouse_mode])
	check("native default hides and captures pointer",Input.mouse_mode==Input.MOUSE_MODE_CAPTURED)
	var yaw:float=demo.camera.yaw
	await motion()
	check("native unmodified mouse reaches look handler",not is_equal_approx(yaw,demo.camera.yaw))
	await key(KEY_TAB)
	check("native Tab releases pointer to visible buttons",demo.controls.visible and Input.mouse_mode==Input.MOUSE_MODE_VISIBLE)
	yaw=demo.camera.yaw;await motion()
	check("native UI pointer motion does not turn view",is_equal_approx(yaw,demo.camera.yaw))
	await shot("details_pointer");await key(KEY_ESCAPE)
	print("POINTER afterEsc focus=%s ui=%s mode=%s"%[root.has_focus(),demo.pointer_required(),Input.mouse_mode])
	check("native Esc resumes mouse capture",not demo.controls.visible and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED)
	await key(KEY_I)
	check("native I inspection owns visible pointer",Input.mouse_mode==Input.MOUSE_MODE_VISIBLE)
	await key(KEY_I,false);demo.ship_hud.hide_card("medium_here");demo.star_identification.close_card();await settle()
	demo.consoles.go_to("navigation");check("open real navigation station",demo.consoles.use("navigation","open"));await settle()
	check("native helm releases pointer",Input.mouse_mode==Input.MOUSE_MODE_VISIBLE)
	demo.journey_map.frame_local_ism();await shot("local_ism_boundaries")
	demo.journey_map.plan_body("earth");check("real Earth plan unrefused",demo.journey_tick() and demo.journey_sim.last_refused.is_empty())
	check("real Earth commit",demo.journey_map.open_commit_dialog() and demo.journey_map.hold_commit(GalaxyMap.HOLD_S) and demo.journey_tick())
	for i in 1600:
		if not demo.live_journey:break
		if not demo.journey_tick():failures+=1;break
	demo.dismiss_arrival();demo.look_direction("forward");await shot("earth_arrived")
	check("arrived Earth rendered by actual ship",demo.journey_map.journey_state()=="arrived" and demo.sky.system_view.drawn_discs.has("earth"))
	for i in 1200:
		if not demo.journey_tick():failures+=1;break
	await shot("earth_after_60s")
	check("Earth remains in actual renderer after60s",demo.sky.system_view.drawn_discs.has("earth"))
	demo.queue_free();await process_frame
	check("native exit returns visible pointer",Input.mouse_mode==Input.MOUSE_MODE_VISIBLE)
	print("free-nav-review: %d failures"%failures);quit(1 if failures else 0)
