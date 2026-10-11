extends SceneTree
## Actual manual navigation: footer bounds, focused-key input, zoom and Mars commit.
var checks:=0
var failures:=0
func check(label:String,ok:bool)->void:
	checks+=1
	if not ok:failures+=1
	print("%s %s"%["ok" if ok else "FAIL",label])
func _initialize()->void:run.call_deferred()
func frames()->void:
	for i in 4:await process_frame
func key(code:int,pressed:bool)->void:
	var ev:=InputEventKey.new();ev.keycode=code;ev.physical_keycode=code;ev.pressed=pressed
	root.push_input(ev,true)
func run()->void:
	var map:GalaxyMap=load("res://ui/galaxy_map.tscn").instantiate()
	map.auto_tick=false;map.live_pacing=true;root.add_child(map)
	var sim:=SimBridge.new();sim.want_minor=SimBridge.ISM_MINOR
	check("actual stationary manual session",sim.start() and sim.new_game(42,"free_nav",false,{"stop_rule":54.,"standoff_au":1000.}))
	map.attach(sim)
	for height in [600,450]:
		root.size=Vector2i(1280,height);await frames()
		var rect:=map.commit_button.get_global_rect()
		# canvas_items stretches the logical 540px viewport into a 450px window.
		# Both bounds must use the same coordinate space, including the horizontal edge.
		var visible:=root.get_visible_rect()
		check("journey review reachable in %d pixel window"%height,visible.encloses(rect))
		check("zoom controls reachable in %d pixel window"%height,visible.encloses(map.zoom_in_button.get_global_rect()) and visible.encloses(map.zoom_out_button.get_global_rect()))
	var dist:=map.dist
	map.zoom_in_button.pressed.emit()
	check("visible zoom in changes chart distance",map.dist<dist)
	map.zoom_out_button.pressed.emit()
	check("visible zoom out reverses it",absf(map.dist-dist)<1e-9)
	var wheel:=InputEventMouseButton.new();wheel.position=Vector2(100,100);wheel.button_index=MOUSE_BUTTON_WHEEL_UP;wheel.pressed=true
	root.push_input(wheel,true);await frames()
	check("wheel over actual chart reaches zoom handler",map.dist<dist)
	map._system_buttons.mars.pressed.emit()
	check("actual Mars selection plans successfully",map.tick() and sim.last_refused.is_empty() and map.journey_state()=="planned")
	map.zoom_in_button.grab_focus()
	key(KEY_ENTER,true);key(KEY_ENTER,false);await frames()
	check("Enter reviews the journey despite zoom-button focus",map.dialog.visible and map._queue.is_empty())
	key(KEY_SPACE,true);await frames()
	check("Space starts hold without an immediate commit",map._holding and map._queue.is_empty())
	key(KEY_SPACE,false);await frames()
	check("release cancels a short hold",not map._holding and map.hold_s==0. and map._queue.is_empty())
	key(KEY_ESCAPE,true);key(KEY_ESCAPE,false);await frames()
	check("Escape backs out without altering plan",not map.dialog.visible and map.journey_state()=="planned" and map._queue.is_empty())
	map.set_confirm_twice(true)
	key(KEY_ENTER,true);key(KEY_ENTER,false);key(KEY_SPACE,true);key(KEY_SPACE,false);await frames()
	check("first Space in twice mode arms without commitment",map.armed and map._queue.is_empty())
	key(KEY_ESCAPE,true);key(KEY_ESCAPE,false);await frames()
	check("Escape cancels twice-mode review",not map.dialog.visible and not map.armed and map._queue.is_empty())
	map.set_confirm_twice(false)
	key(KEY_ENTER,true);key(KEY_ENTER,false);key(KEY_SPACE,true)
	for i in 15:map._process(0.1)
	key(KEY_SPACE,false)
	check("held confirmation starts actual Mars journey",map.tick() and map.journey_state()=="committed" and sim.last_refused.is_empty() and sim.world.journey.plan.target.id=="mars")
	var queue:=map._queue.duplicate(true)
	key(KEY_ENTER,true);key(KEY_ENTER,false);await frames()
	check("Enter cannot recommit in flight",not map.dialog.visible and map._queue==queue)
	sim.stop();map.queue_free();await frames()
	print("navigation-usability: %d checks %d failures"%[checks,failures]);quit(1 if failures else 0)
