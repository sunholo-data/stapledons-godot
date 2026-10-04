extends Node
## Isolated native-material spatial review. No simulation mutations or fake GR.
const Camera := preload("res://demos/ship_demo_camera.gd")
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
func _ready() -> void:
	setup()
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
	geometry.add_child(avatar);avatar.load_dir("res://assets/characters/captain");avatar.position=avatar_pos
	sky.setup({"position_m":[8,4.8,83.7],"forward":[1,0,0],"up":[0,0,1]},78.,px,opts)
	add_child(sky)
	_draw_layer(sky.get_texture(),-40);_draw_layer(geometry_view.get_texture(),-20)
	_guides();_hud();get_viewport().size_changed.connect(_resize)
	set_preset("bridge");sky.starfield.set_velocity(Vector3(0,-1,0),0.,1.)
	if sky.has_background:sky.background.set_velocity(Vector3(0,-1,0),0.,1.)
	sky.set_glow_pole(0.);ready_ok=true
	print("ship-demo-ready: OK")
	return true
func _draw_layer(texture: Texture2D, layer: int) -> void:
	var canvas:=CanvasLayer.new();canvas.layer=layer;add_child(canvas)
	var rect:=TextureRect.new();rect.texture=texture;rect.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);rect.mouse_filter=Control.MOUSE_FILTER_IGNORE
	canvas.add_child(rect);_rects.append(rect)
func _resize() -> void:
	var px:=get_window().size
	geometry_view.size=px;camera.sync_sky(sky,px)
	for rect in _rects:rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
func _hud() -> void:
	var canvas:=CanvasLayer.new();canvas.layer=10;add_child(canvas)
	hud.position=Vector2(18,14);canvas.add_child(hud)
	label.add_theme_color_override("font_shadow_color",Color.BLACK);label.add_theme_constant_override("shadow_offset_x",2);label.add_theme_constant_override("shadow_offset_y",2);hud.add_child(label)
	var row:=HBoxContainer.new();hud.add_child(row)
	for pair in [["Bridge [1]","bridge"],["Overlook [2]","overlook"],["Whole ship [3]","overview"],["Reference rim [4]","rim"],["Reset [R]","reset"]]:
		var button:=Button.new();button.text=pair[0];button.pressed.connect(set_preset.bind(pair[1]));row.add_child(button)
	var hint:=Label.new();hint.text="WASD walk · drag right mouse to look · wheel pulls back · E lift · G sphere guides · Esc return";hud.add_child(hint)
func set_preset(name: String) -> void:
	if name=="reset":
		if lift!=null:lift.reset()
		active_level=0;walk=walk_bridge;avatar_pos=Vector3(8,82,-4.8);name="bridge"
	camera.reference=false
	match name:
		"bridge":
			camera_mode="player";camera.follow(avatar_pos,-18,.47,3.)
		"overlook":
			if active_level==0:avatar_pos=walk.closest_walkable(Vector3(18,82,9),3.)
			camera_mode="player";camera.follow(avatar_pos,-30,.47,0.)
		"overview":
			camera_mode="external review";camera.position=Vector3(225,125,225);camera.look_at(Vector3(0,5,0));camera.external=true
		"rim":
			camera_mode="diagnostic rim — not reachable";camera.reference=true
			camera.follow(Vector3(19.0513,82,9.52565),-30,.463648,0.)
	camera.sync_sky(sky,geometry_view.size)
func reference_view(radius: float, tilt: float) -> void:
	camera_mode="diagnostic reference — not a standing location";camera.reference=true
	camera.follow(Vector3(radius*2/sqrt(5.),82,radius/sqrt(5.)),-tilt,.463648,0.)
	camera.sync_sky(sky,geometry_view.size)
func _process(delta: float) -> void:
	if not ready_ok:return
	if auto and camera_mode=="player" and (lift==null or not lift.travelling()):
		var move:=Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_W))-float(Input.is_physical_key_pressed(KEY_S)))
		var forward: Vector3=-camera.basis.z;forward.y=0;forward=forward.normalized()
		var right: Vector3=camera.basis.x;right.y=0;right=right.normalized()
		avatar_pos=walk.step(avatar_pos,(right*move.x+forward*move.y).normalized()*2.2*delta)
	if lift!=null:lift.advance(delta if auto else 0.)
	avatar.position=avatar_pos
	if camera_mode=="player":camera.follow(avatar_pos,camera.tilt,camera.yaw,camera.pullback)
	avatar.visible=camera.pullback>.5 or camera_mode!="player"
	camera.sync_sky(sky,geometry_view.size)
	if Time.get_ticks_msec()-_last_exposure_ms>250:
		sky.update_exposure();_last_exposure_ms=Time.get_ticks_msec()
	var view_name: String="external pullback review — not captain eye" if camera.external and camera_mode=="player" else camera_mode
	label.text="SEVEN-TIER GEOMETRY DEMO · at rest · native materials · GR not implemented\n%s · deck %d · eye %.2f m · 78° perspective\n%s" % [view_name,active_level,camera.position.y,caption]
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.button_mask&MOUSE_BUTTON_MASK_RIGHT:
		if camera_mode=="external review":
			var offset:=camera.position-Vector3(0,5,0)
			offset=offset.rotated(Vector3.UP,-event.relative.x*.004).rotated(camera.basis.x,-event.relative.y*.004)
			camera.position=Vector3(0,5,0)+offset;camera.look_at(Vector3(0,5,0));return
		camera.yaw-=event.relative.x*.004;camera.tilt=clampf(camera.tilt-event.relative.y*.22,-80,75)
		if camera_mode!="player":
			var eye:=camera.position;camera.follow(eye-Vector3.UP*1.7,camera.tilt,camera.yaw,0.)
	if event is InputEventMouseButton and event.pressed:
		if event.button_index==MOUSE_BUTTON_WHEEL_UP:camera.pullback=clampf(camera.pullback+2.,0.,300.);camera_mode="player"
		if event.button_index==MOUSE_BUTTON_WHEEL_DOWN:camera.pullback=clampf(camera.pullback-2.,0.,300.);camera_mode="player"
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_1:set_preset("bridge")
			KEY_2:set_preset("overlook")
			KEY_3:set_preset("overview")
			KEY_4:set_preset("rim")
			KEY_R:set_preset("reset")
			KEY_G:guides.visible=not guides.visible
			KEY_E:
				if lift!=null:lift.board()
			KEY_ESCAPE:get_tree().change_scene_to_file("res://main.tscn")
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
