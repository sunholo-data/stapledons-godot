extends Node
## Isolated native-material spatial review. No simulation mutations or fake GR.
const Lift := preload("res://demos/ship_demo_lift.gd")
const Camera := preload("res://demos/ship_demo_camera.gd")
const Benchmark := preload("res://demos/ship_demo_benchmark.gd")
const Commons := preload("res://demos/ship_commons.gd")
var benchmark := Benchmark.new()
var setup_options := {}
var camera: Camera3D = Camera.new()
var sky := InteriorSky.new()
var geometry_view := SubViewport.new()
var geometry := Node3D.new()
var walk_bridge: WalkArea
var walk_lower: WalkArea
var walk: WalkArea
var avatar := CaptainAvatar.new()
var avatar_pos := Vector3(8,82,-4.8)
var active_level := 0
var label := Label.new()
var hud := VBoxContainer.new()
var auto := true
var ready_ok := false
var caption := ""
var camera_mode := "player"
var _rects: Array[TextureRect] = []
var _walk_nodes: Array[Node3D] = []
var lift: Node3D = null
var guides := MeshInstance3D.new()
var manifest: Dictionary = {}
var _last_exposure_ms := 0
var sky_states: Dictionary = {}
var sky_world: Dictionary = {}
var sky_state := "rest"
var sky_only := false
var controls := VBoxContainer.new()
var commons: Dictionary = {}
const BRIGHTNESS_STOPS := [0,1,2,4,6]
var brightness_stops := 1
func _ready() -> void:
	setup(setup_options)
	if OS.get_cmdline_user_args().has("--ship-demo-smoke"):_export_smoke.call_deferred()
func asset(file: String) -> String:
	var source := "res://assets/ship_demo/"+file
	return source if FileAccess.file_exists(source) else "res://ship_demo_bundle/"+file+".bin"
func setup(opts := {}) -> bool:
	if ready_ok:return true
	manifest=JSON.parse_string(FileAccess.get_file_as_string(asset("manifest.json")))
	var px: Vector2i=opts.get("size",get_window().size)
	var visual := AreaBundle.load_glb(asset("ship.glb"))
	if visual==null:push_error("ship demo missing GLB");return false
	geometry_view.size=px;geometry_view.own_world_3d=true;geometry_view.transparent_bg=true
	geometry_view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	add_child(geometry_view);geometry_view.add_child(geometry);geometry.add_child(visual)
	_collision(visual)
	geometry_view.add_child(camera);camera.current=true
	var env:=Environment.new();env.background_mode=Environment.BG_CLEAR_COLOR
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color(.65,.70,.78);env.ambient_light_energy=.65
	env.tonemap_mode=Environment.TONE_MAPPER_AGX
	var we:=WorldEnvironment.new();we.environment=env;geometry.add_child(we)
	var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-45,-25,0);light.light_energy=1.3;geometry.add_child(light)
	var fill:=DirectionalLight3D.new();fill.rotation_degrees=Vector3(-20,155,0);fill.light_energy=.65;geometry.add_child(fill)
	for file in ["walk_bridge.glb","walk_lower.glb"]:
		var n:=AreaBundle.load_glb(asset(file));_walk_nodes.append(n)
	walk_bridge=WalkArea.from_scene(_walk_nodes[0],.35);walk_lower=WalkArea.from_scene(_walk_nodes[1],.35);walk=walk_bridge
	if opts.get("commons",true):
		commons=Commons.install(self)
		if commons.is_empty():return false
	geometry.add_child(avatar);avatar.load_dir("res://assets/characters/captain");avatar.position=avatar_pos
	sky.setup({"position_m":[8,4.8,83.7],"forward":[1,0,0],"up":[0,0,1]},78.,px,opts)
	add_child(sky)
	_draw_layer(sky.get_texture(),-40);_draw_layer(geometry_view.get_texture(),-20)
	lift=Lift.new();geometry.add_child(lift);lift.setup(self)
	_guides();_hud();get_viewport().size_changed.connect(_resize)
	set_preset("bridge")
	var review_path:=asset("sky_review.json")
	if FileAccess.file_exists(review_path):sky_states=JSON.parse_string(FileAccess.get_file_as_string(review_path)).get("states",{})
	if not set_sky_state(opts.get("sky_state","cruise")):
		push_error("ship demo missing simulation sky review states");return false
	ready_ok=true
	set_brightness_trial(opts.get("brightness_stops",1))
	print("ship-demo-ready: OK")
	return true
func _draw_layer(texture: Texture2D, layer: int) -> void:
	var canvas:=CanvasLayer.new();canvas.layer=layer;add_child(canvas)
	var rect:=TextureRect.new();rect.texture=texture;rect.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);rect.mouse_filter=Control.MOUSE_FILTER_IGNORE
	canvas.add_child(rect);_rects.append(rect)
func _resize() -> void:
	var px:=get_window().size
	geometry_view.size=px;_sync_observer()
	for rect in _rects:rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
func _hud() -> void:
	var canvas:=CanvasLayer.new();canvas.layer=10;add_child(canvas)
	hud.position=Vector2(18,14);canvas.add_child(hud)
	label.add_theme_color_override("font_shadow_color",Color.BLACK);label.add_theme_constant_override("shadow_offset_x",2);label.add_theme_constant_override("shadow_offset_y",2);hud.add_child(label)
	var control_button:=Button.new();control_button.text="Controls [Tab] · 5 rest / 6 cruise · 7 forward / 8 side / 9 aft · H sky only"
	control_button.pressed.connect(toggle_controls);hud.add_child(control_button)
	hud.add_child(controls);controls.visible=false
	var row:=HBoxContainer.new();controls.add_child(row)
	for pair in [["Bridge [1]","bridge"],["Overlook [2]","overlook"],["Whole ship [3]","overview"],["Reference rim [4]","rim"],["Reset [R]","reset"]]:
		var button:=Button.new();button.text=pair[0];button.pressed.connect(set_preset.bind(pair[1]));row.add_child(button)
	var benchmark_button:=Button.new();benchmark_button.text="Benchmark at1920×1080 [B] (saves report)";benchmark_button.pressed.connect(func() -> void: await benchmark.run(self));controls.add_child(benchmark_button)
	var sky_row:=HBoxContainer.new();controls.add_child(sky_row)
	for pair in [["Rest [5]","rest"],["Mid-journey 0.99c [6]","cruise"]]:
		var button:=Button.new();button.text=pair[0];button.pressed.connect(set_sky_state.bind(pair[1]));sky_row.add_child(button)
	for pair in [["Look forward/up [7]","forward"],["Look side [8]","side"],["Look aft/down [9]","aft"]]:
		var button:=Button.new();button.text=pair[0];button.pressed.connect(look_direction.bind(pair[1]));sky_row.add_child(button)
	var sky_button:=Button.new();sky_button.text="Sky only diagnostic [H]";sky_button.pressed.connect(toggle_sky_only);controls.add_child(sky_button)
	var brightness_row:=HBoxContainer.new();controls.add_child(brightness_row)
	for stops in BRIGHTNESS_STOPS:
		var button:=Button.new();button.text="Calibrated baseline" if stops==0 else "Exposure trial %d×" % int(pow(2.,stops))
		button.pressed.connect(set_brightness_trial.bind(stops));brightness_row.add_child(button)
	var hint:=Label.new();hint.text="WASD walk · Option + finger drag (or right-drag) to look · two-finger scroll / wheel to zoom · E lift · G guides · Esc close";controls.add_child(hint)
func toggle_controls() -> void:
	if not benchmark.running:controls.visible=not controls.visible
func set_brightness_trial(stops: int) -> bool:
	if benchmark.running or not stops in BRIGHTNESS_STOPS:return false
	brightness_stops=stops
	sky.exposure.bias=-float(stops)
	sky.update_exposure()
	return true
func brightness_label() -> String:
	return "Calibrated sky" if brightness_stops==0 else "Sky exposure trial %d× — display aid" % int(pow(2.,brightness_stops))
func set_preset(name: String) -> void:
	if name=="reset":
		if lift!=null:lift.reset()
		active_level=0;walk=walk_bridge;avatar_pos=Vector3(8,82,-4.8);name="bridge"
	if lift!=null and lift.travelling() and name!="reset":return
	camera.reference=false
	guides.visible=name=="overview"
	match name:
		"bridge":
			camera_mode="player";camera.follow(avatar_pos,-18,.47,3.)
		"overlook":
			if active_level==0:avatar_pos=walk.closest_walkable(Vector3(18,82,9),3.)
			camera_mode="player";camera.follow(avatar_pos,-30,.47,0.)
		"overview":
			camera_mode="external review";camera.position=Vector3(145,90,145);camera.look_at(Vector3(0,5,0));camera.external=true
		"rim":
			camera_mode="diagnostic rim — not reachable";camera.reference=true
			camera.follow(Vector3(19.0513,82,9.52565),-30,.463648,0.)
	_sync_observer()
func reference_view(radius: float, tilt: float) -> void:
	camera_mode="diagnostic reference — not a standing location";camera.reference=true
	camera.follow(Vector3(radius*2/sqrt(5.),82,radius/sqrt(5.)),-tilt,.463648,0.)
	_sync_observer()
func set_sky_state(name: String) -> bool:
	if benchmark.running or not sky_states.has(name):return false
	sky_state=name;sky_world=sky_states[name].duplicate(true)
	var h:Dictionary=sky_world.ship.heading
	camera.heading=PackedFloat64Array([h.x,h.y,h.z])
	sky.apply(sky_world);_sync_observer()
	return true
func _sync_observer() -> void:
	camera.sync_sky(sky,geometry_view.size)
	if not commons.is_empty():Commons.update_detail(commons,camera.position)
	if not sky_world.is_empty():
		var pole:float=0. if camera.position.length()>=100. else ForwardGlow.pole_of(sky_world)
		if sky.glow_pole!=pole:sky.set_glow_pole(pole)
func look_direction(direction: String) -> void:
	if benchmark.running:return
	var tilt:float={"forward":89.5,"side":0.,"aft":-89.5}.get(direction,0.)
	camera_mode="player";camera.reference=false
	camera.follow(avatar_pos,tilt,0.,0.);_sync_observer()
func toggle_sky_only() -> void:
	if benchmark.running:return
	sky_only=not sky_only;geometry_view.render_target_update_mode=SubViewport.UPDATE_DISABLED if sky_only else SubViewport.UPDATE_ALWAYS
	_rects[1].visible=not sky_only
func _process(delta: float) -> void:
	if not ready_ok:return
	if auto and camera_mode=="player" and (lift==null or not lift.travelling()):
		var move:=Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_W))-float(Input.is_physical_key_pressed(KEY_S)))
		var forward: Vector3=-camera.basis.z;forward.y=0;forward=forward.normalized()
		var right: Vector3=camera.basis.x;right.y=0;right=right.normalized()
		avatar_pos=walk.step(avatar_pos,(right*move.x+forward*move.y).normalized()*2.2*delta)
	if lift!=null:lift.advance(delta if auto else 0.)
	if avatar.get_parent()==geometry:avatar.position=avatar_pos
	if camera_mode=="player":camera.follow(avatar_pos,camera.tilt,camera.yaw,camera.pullback)
	avatar.visible=camera.pullback>.5 or camera.external
	_sync_observer()
	if Time.get_ticks_msec()-_last_exposure_ms>250:
		sky.update_exposure();_last_exposure_ms=Time.get_ticks_msec()
	var view_name: String="external pullback review — not captain eye" if camera.external and camera_mode=="player" else camera_mode
	label.text="SEVEN-TIER SHIP DEMO · %s · native materials · GR not implemented\n%s · deck %d · eye %.2f m · view/travel %.1f° · 78° perspective\n%s%s" % ["FROZEN MID-JOURNEY SNAPSHOT %.4fc" % sky.beta if sky_state=="cruise" else "AT REST SNAPSHOT",view_name,active_level,camera.position.y,sky.camera.view_velocity_angle(sky.heading_world),"SKY ONLY DIAGNOSTIC — opaque ship hidden; travel is UP, aft is DOWN\n" if sky_only else "Travel is UP; floors correctly block the aft sky.\n",brightness_label()+" · J cycles brightness\n"+caption + (" · E: descend/return at landing" if lift!=null and not lift.travelling() else " · Lift in motion" )]
func _unhandled_input(event: InputEvent) -> void:
	if benchmark.running:return
	if event is InputEventMouseMotion and (event.alt_pressed or event.button_mask&MOUSE_BUTTON_MASK_RIGHT):
		if camera_mode=="external review":
			var offset:=camera.position-Vector3(0,5,0)
			offset=offset.rotated(Vector3.UP,-event.relative.x*.004).rotated(camera.basis.x,-event.relative.y*.004)
			camera.position=Vector3(0,5,0)+offset;camera.look_at(Vector3(0,5,0));return
		camera.yaw-=event.relative.x*.004;camera.tilt=clampf(camera.tilt-event.relative.y*.22,-89.5,89.5)
		if camera_mode!="player":
			var eye:=camera.position;camera.follow(eye-Vector3.UP*1.7,camera.tilt,camera.yaw,0.)
	if event is InputEventPanGesture:
		_zoom(-event.delta.y*2.)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP:_zoom(2.*event.factor)
		if event.button_index==MOUSE_BUTTON_WHEEL_DOWN:_zoom(-2.*event.factor)
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_1:set_preset("bridge")
			KEY_2:set_preset("overlook")
			KEY_3:set_preset("overview")
			KEY_4:set_preset("rim")
			KEY_5:set_sky_state("rest")
			KEY_6:set_sky_state("cruise")
			KEY_7:look_direction("forward")
			KEY_8:look_direction("side")
			KEY_9:look_direction("aft")
			KEY_H:toggle_sky_only()
			KEY_J:set_brightness_trial(BRIGHTNESS_STOPS[(BRIGHTNESS_STOPS.find(brightness_stops)+1)%BRIGHTNESS_STOPS.size()])
			KEY_TAB:toggle_controls()
			KEY_R:set_preset("reset")
			KEY_G:guides.visible=not guides.visible
			KEY_B:await benchmark.run(self)
			KEY_E:
				if lift!=null:lift.board()
			KEY_ESCAPE:get_tree().quit()
func _zoom(amount: float) -> void:
	if amount==0. or benchmark.running or (lift!=null and lift.travelling()):return
	if camera_mode=="external review":
		var target:=Vector3(0,5,0)
		var offset:=camera.position-target
		camera.position=target+offset.normalized()*clampf(offset.length()+amount,60.,650.)
		camera.look_at(target)
	else:
		camera.pullback=clampf(camera.pullback+amount,0.,300.);camera_mode="player"
func centre_hit() -> Dictionary:
	var forward: Vector3=-camera.basis.z
	var query:=PhysicsRayQueryParameters3D.create(camera.position,camera.position+forward*500.)
	return camera.get_world_3d().direct_space_state.intersect_ray(query)
func _collision(n: Node) -> void:
	if n is MeshInstance3D and n.mesh!=null:n.create_trimesh_collision()
	for child in n.get_children():
		if not child is StaticBody3D:_collision(child)
func _exit_tree() -> void:
	for n in _walk_nodes:if is_instance_valid(n):n.free()

func _guides() -> void:
	var mesh:=ImmediateMesh.new();mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for axis in 3:
		for i in 128:
			for a in [TAU*i/128.,TAU*(i+1)/128.]:
				var v:=Vector3(100*cos(a),100*sin(a),0)
				if axis==1:v=Vector3(v.x,0,v.y)
				if axis==2:v=Vector3(0,v.x,v.y)
				mesh.surface_add_vertex(v)
	mesh.surface_end();guides.mesh=mesh
	var material:=StandardMaterial3D.new();material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;material.albedo_color=Color(.18,.55,.62)
	guides.material_override=material;guides.visible=false;geometry.add_child(guides)

func _export_smoke() -> void:
	auto=false
	await get_tree().process_frame
	var ok:=ready_ok and not avatar.stages.is_empty()
	ok=ok and not commons.is_empty() and commons.visual.get_parent()==geometry
	if ok:
		for direction in 2:
			ok=ok and lift.board()
			lift.advance(.81);lift.advance(11.01);lift.advance(.81)
		ok=ok and lift.state=="bridge_ready" and walk==walk_bridge and avatar_pos.distance_to(Vector3(8,82,-4.8))<.01
	print("ship-demo-export-smoke: %s" % ("OK" if ok else "FAIL"))
	get_tree().quit(0 if ok else 1)
