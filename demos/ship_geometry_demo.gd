extends Node
## Isolated native-material spatial review; its optional voyage is a separate normal simulation.
const Lift := preload("res://demos/ship_demo_lift.gd")
const Camera := preload("res://demos/ship_demo_camera.gd")
const Benchmark := preload("res://demos/ship_demo_benchmark.gd")
const Commons := preload("res://demos/ship_commons.gd")
const Identification := preload("res://ui/ship_star_identification.gd")
const Lighting := preload("res://demos/ship_lighting.gd")
const SolarDeparture := preload("res://demos/solar_departure.gd")
const Attitude:=preload("res://demos/ship_attitude.gd")
var tour_attitude:=Attitude.new()
var _attitude_stop:=-99
var _attitude_pending:=-99
var _attitude_mode:=""
var _tour_view_from:=Vector2.ZERO
var _tour_view_to:=Vector2.ZERO
var _tour_view_elapsed:=0.
var _tour_view_active:=false
const WALK_SPEED_MPS := 3.5
var lighting:Dictionary={}
var star_identification: Control
var benchmark := Benchmark.new()
var audit_link:=LinkButton.new()
var audit_local:=Button.new()
var setup_options := {}
var camera: Camera3D = Camera.new()
var sky := InteriorSky.new()
var geometry_view := SubViewport.new()
var geometry := Node3D.new()
var walk_bridge: WalkArea
var walk_lower: WalkArea
var walk: WalkArea
var avatar := CaptainAvatar.new()
var avatar_shadow:Node3D
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
var sky_states: Dictionary = {}
var sky_world: Dictionary = {}
var sky_state := "rest"
var sky_only := false
var controls := VBoxContainer.new()
var commons: Dictionary = {}
const BRIGHTNESS_STOPS := [-24,-16,-8,0,1,2,4,6]
var brightness_stops := 2
var view_button := Button.new()
var interlude_card: InterludeCard
var journey_sim: SimBridge
var journey_map: GalaxyMap
var navigation_window: Window
var live_journey := false
var journey_auto_tick := true
var _journey_accum := 0.
var solar_tour: RefCounted
var solar_pause := Button.new()
var solar_next := Button.new()
var solar_skip := Button.new()
var navigation_button := Button.new()
func _ready() -> void:
	setup(setup_options)
	if OS.get_cmdline_user_args().has("--ship-demo-smoke"):_export_smoke.call_deferred()
	if OS.get_cmdline_user_args().has("--ship-identification-smoke"):_identification_smoke.call_deferred()
	if OS.get_cmdline_user_args().has("--solar-departure-smoke"):_solar_departure_smoke.call_deferred()
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
	lighting=Lighting.install(geometry)
	set_lighting(opts.get("lighting","moody"))
	for file in ["walk_bridge.glb","walk_lower.glb"]:
		var n:=AreaBundle.load_glb(asset(file));_walk_nodes.append(n)
	walk_bridge=WalkArea.from_scene(_walk_nodes[0],.35);walk_lower=WalkArea.from_scene(_walk_nodes[1],.35);walk=walk_bridge
	if opts.get("commons",true):
		commons=Commons.install(self)
		if commons.is_empty():return false
	geometry.add_child(avatar);avatar.load_dir("res://assets/characters/captain");avatar.position=avatar_pos
	avatar_shadow=avatar.install_grounded_shadow();avatar_shadow.reparent(geometry)
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
	set_brightness_trial(opts.get("brightness_stops",2))
	set_auto_view(opts.get("auto_view",false))
	var identify_canvas := CanvasLayer.new();identify_canvas.layer = 11;add_child(identify_canvas)
	var interlude_canvas := CanvasLayer.new();interlude_canvas.layer = 12;add_child(interlude_canvas)
	interlude_card = InterludeCard.new();interlude_card.visible = false;interlude_canvas.add_child(interlude_card)
	interlude_card.continue_pressed.connect(continue_interlude)
	star_identification = Identification.new();identify_canvas.add_child(star_identification)
	star_identification.setup(self);star_identification.open_map.connect(open_identified_star)
	if opts.get("live_start",false):
		sky_state="live";open_navigation();close_navigation()
		if journey_map==null:sky_state="rest"
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
	label.add_theme_font_size_override("font_size",12)
	label.add_theme_color_override("font_shadow_color",Color.BLACK);label.add_theme_constant_override("shadow_offset_x",2);label.add_theme_constant_override("shadow_offset_y",2);hud.add_child(label)
	var control_button:=Button.new();control_button.text="Controls [Tab] · 5 rest / 6 cruise · 7 forward / 8 side / 9 aft · H sky only"
	control_button.add_theme_font_size_override("font_size",12)
	control_button.pressed.connect(toggle_controls);hud.add_child(control_button)
	navigation_button.text="Navigation [M] · select destination and hold to commit"
	navigation_button.add_theme_font_size_override("font_size",12)
	navigation_button.pressed.connect(open_navigation);hud.add_child(navigation_button)
	var tour_row:=HBoxContainer.new();hud.add_child(tour_row)
	var solar_start:=Button.new();solar_start.text="New voyage · Earth → outer planets → α Cen → TRAPPIST-1 → Aldebaran (real time)"
	solar_start.tooltip_text="Earth → Sun → Jupiter → Callisto → Saturn → α Centauri → α Cen A → TRAPPIST-1 → Aldebaran"
	solar_start.add_theme_font_size_override("font_size",12)
	solar_start.pressed.connect(start_solar_departure);tour_row.add_child(solar_start)
	solar_pause.text="Pause tour";solar_pause.visible=false
	solar_pause.pressed.connect(func()->void:
		if solar_tour!=null:solar_tour.paused=not solar_tour.paused
		solar_pause.text="Resume tour" if solar_tour!=null and solar_tour.paused else "Pause tour")
	tour_row.add_child(solar_pause)
	solar_next.text="Next stop";solar_next.visible=false
	solar_next.pressed.connect(func()->void:
		if solar_tour!=null:solar_tour.prepare_next();_apply_journey_world())
	tour_row.add_child(solar_next)
	solar_skip.text="Skip stage [K]";solar_skip.visible=false
	solar_skip.tooltip_text="Jump to the next stage of this leg: accelerating → cruise → braking → final approach → arrival"
	solar_skip.pressed.connect(skip_stage)
	tour_row.add_child(solar_skip)
	hud.add_child(controls);controls.visible=false
	var row:=HBoxContainer.new();controls.add_child(row)
	for pair in [["Bridge [1]","bridge"],["Overlook [2]","overlook"],["Whole ship [3]","overview"],["Reference rim [4]","rim"],["Reset [R]","reset"]]:
		var button:=Button.new();button.text=pair[0];button.pressed.connect(set_preset.bind(pair[1]));row.add_child(button)
	var benchmark_button:=Button.new();benchmark_button.text="Benchmark at1920×1080 [B] (uploads public summary)";benchmark_button.pressed.connect(func() -> void: await benchmark.run(self));controls.add_child(benchmark_button)
	audit_local.text="Show local audit in Finder"
	audit_local.pressed.connect(func()->void:OS.shell_show_in_file_manager(ProjectSettings.globalize_path(Benchmark.OUTPUT)))
	controls.add_child(audit_local)
	var sky_row:=HBoxContainer.new();controls.add_child(sky_row)
	for pair in [["Rest [5]","rest"],["Mid-journey 0.99c [6]","cruise"]]:
		var button:=Button.new();button.text=pair[0];button.pressed.connect(set_sky_state.bind(pair[1]));sky_row.add_child(button)
	for pair in [["Look forward/up [7]","forward"],["Look side [8]","side"],["Look aft/down [9]","aft"]]:
		var button:=Button.new();button.text=pair[0];button.pressed.connect(look_direction.bind(pair[1]));sky_row.add_child(button)
	var sky_button:=Button.new();sky_button.text="Sky only diagnostic [H]";sky_button.pressed.connect(toggle_sky_only);controls.add_child(sky_button)
	view_button.pressed.connect(func():set_auto_view(not sky.system_view.body_fader));controls.add_child(view_button)
	var brightness_row:=GridContainer.new();brightness_row.columns=4;controls.add_child(brightness_row)
	for stops in BRIGHTNESS_STOPS:
		var button:=Button.new();button.text="Reference sky" if stops==0 else ("Dim %d stops"%(-stops) if stops<0 else "%d× brighter"%int(pow(2.,stops)))
		button.pressed.connect(set_brightness_trial.bind(stops));brightness_row.add_child(button)
	var hint:=Label.new();hint.text="WASD walk · Option + finger drag (or right-drag) to look · scroll to zoom · E lift · hold I + click known star · G guides · Esc close";controls.add_child(hint)
func toggle_controls() -> void:
	if not benchmark.running:controls.visible=not controls.visible
func set_brightness_trial(stops: int) -> bool:
	if benchmark.running or not stops in BRIGHTNESS_STOPS:return false
	brightness_stops=stops
	sky.exposure.bias=-float(stops)
	# Demo display choice: fixed dark-sky reference plus explicit player aid.
	# Scene motion, bright bodies and camera pans never adjust this exposure.
	sky.set_temporal_exposure(false)
	sky.exposure.fixed=true
	sky.exposure.fixed_ev=sky.exposure.ev_dark()-float(stops)
	sky.update_exposure()
	return true
## D-38: Realistic = one physical exposure for sky and bodies (sunlit bodies
## clip at a star-friendly setting); Auto = the same manual sky exposure, with
## each resolved body faded on its own so planets and stars show together.
func set_auto_view(on: bool) -> void:
	sky.system_view.body_fader=on
	view_button.text="View: Auto, bodies faded to fit [V]" if on else "View: Realistic, one exposure [V]"
	sky.update_exposure()
func brightness_label() -> String:
	var manual:String="Manual sky exposure EV %.2f · %s"%[sky.exposure.fixed_ev,"calibrated reference" if brightness_stops==0 else ("%d stops dimmer · display aid"%(-brightness_stops) if brightness_stops<0 else "%d× display aid"%int(pow(2.,brightness_stops)))]
	if not sky.system_view.body_fader:return "REALISTIC view · "+manual
	var faded:=sky.system_view.fader_stops(sky.exposure.k())
	return "AUTO view · "+manual+(" · bodies dimmed up to %.0f stops (composite) · star colours enhanced"%faded if faded>=0.5 else " · no body needs dimming")
func set_preset(name: String) -> void:
	if name=="reset":
		if lift!=null:lift.reset()
		active_level=0;walk=walk_bridge;avatar_pos=Vector3(8,82,-4.8);name="bridge"
	if lift!=null and lift.travelling() and name!="reset":return
	camera.reference=false
	guides.visible=name=="overview"
	match name:
		"bridge":
			camera_mode="player";camera.follow(avatar_pos,-18,.47,0.)
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
	if benchmark.running or live_journey or solar_tour!=null or not sky_states.has(name):return false
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
		var temperature:float=ForwardGlow.temperature_of(sky_world)
		if sky.glow_pole!=pole or sky.glow_t_pole!=temperature:sky.set_glow(pole,temperature)
func look_direction(direction: String) -> void:
	_tour_view_active=false
	if benchmark.running:return
	var tilt:float={"forward":89.5,"side":0.,"aft":-89.5}.get(direction,0.)
	camera_mode="player";camera.reference=false
	camera.follow(avatar_pos,tilt,0.,0.);_sync_observer()
func toggle_sky_only() -> void:
	if benchmark.running:return
	sky_only=not sky_only;geometry_view.render_target_update_mode=SubViewport.UPDATE_DISABLED if sky_only else SubViewport.UPDATE_ALWAYS
	_rects[1].visible=not sky_only
func walk_motion(move: Vector2,delta: float) -> void:
	var forward: Vector3=-camera.basis.z;forward.y=0;forward=forward.normalized()
	var right: Vector3=camera.basis.x;right.y=0;right=right.normalized()
	var displacement:Vector3=(right*move.x+forward*move.y).normalized()*WALK_SPEED_MPS*maxf(delta,0.)
	# Endpoint-only stepping can tunnel across the lift opening after a stall.
	var steps:int=maxi(1,ceili(displacement.length()/maxf(.05,walk.radius*.5)))
	for step in steps:avatar_pos=walk.step(avatar_pos,displacement/steps)
func set_lighting(profile:String)->void:
	Lighting.apply(lighting,profile)
func lighting_manifest()->Dictionary:
	return Lighting.manifest(lighting)
func _process(delta: float) -> void:
	var uploaded:Dictionary=benchmark.upload.poll()
	if not uploaded.is_empty():
		caption=uploaded.status
		if uploaded.ok:
			audit_link.text="Open public performance audit"
			audit_link.uri=uploaded.url
			if audit_link.get_parent()==null:hud.add_child(audit_link)
	if solar_tour!=null:solar_skip.disabled=not live_journey or solar_tour.paused or solar_tour.attitude_hold
	if solar_tour!=null:solar_next.disabled=live_journey or solar_tour.complete or solar_tour.attitude_hold or solar_tour.pending_index>=0 or not solar_tour.failed.is_empty()
	navigation_button.text="Navigation [M] · pauses tour for browsing" if solar_tour!=null else "Navigation [M] · select destination and hold to commit"
	if not ready_ok:return
	sky.set_temporal_exposure(false)
	_update_tour_attitude(delta)
	if journey_map!=null and journey_auto_tick and not benchmark.running:
		_journey_accum=minf(_journey_accum+delta,4./GalaxyMap.TICK_HZ)
		while _journey_accum>=1./GalaxyMap.TICK_HZ:
			_journey_accum-=1./GalaxyMap.TICK_HZ
			journey_tick()
	if auto and (navigation_window==null or not navigation_window.visible) and camera_mode=="player" and (lift==null or not lift.travelling()):
		var move:=Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_W))-float(Input.is_physical_key_pressed(KEY_S)))
		walk_motion(move,delta)
	if lift!=null:lift.advance(delta if auto else 0.)
	if avatar.get_parent()==geometry:avatar.position=avatar_pos
	if camera_mode=="player":camera.follow(avatar_pos,camera.tilt,camera.yaw,camera.pullback)
	avatar.visible=camera.pullback>.5 or camera.external
	avatar_shadow.global_position=avatar.global_position
	_sync_observer()
	sky.finish_exposure_frame(delta)
	var view_name: String="external pullback review — not captain eye" if camera.external and camera_mode=="player" else camera_mode
	var details:String="CURRENT SHIP · seven tiers · GR not implemented\n%s\n%s · deck %d · eye %.2f m · view/travel %.1f° · 78° perspective\n%s%s" % [journey_label(),view_name+((" · third-person camera" if camera.pullback>0.01 else " · captain eye") if camera_mode=="player" else " · reference camera"),active_level,camera.position.y,sky.camera.view_velocity_angle(sky.heading_world),"SKY ONLY DIAGNOSTIC — opaque ship hidden; travel is UP, aft is DOWN\n" if sky_only else ("Stationary ship attitude turn; simulation time held.\n" if solar_tour!=null and solar_tour.attitude_hold else ("Stationary side view; floors remain opaque.\n" if solar_tour!=null and not live_journey else "Travel is UP; floors correctly block the aft sky.\n")),brightness_label()+" · J cycles brightness · V Realistic/Auto\n"+caption + (" · E: descend/return at landing" if lift!=null and not lift.travelling() else " · Lift in motion" )]
	label.text=hud_text(view_name,details)
func _unhandled_input(event: InputEvent) -> void:
	if benchmark.running:return
	if UiScale.handle(get_window(),event):
		_resize();get_viewport().set_input_as_handled();return
	if navigation_window!=null and navigation_window.visible:return
	if event is InputEventMouseMotion and (event.alt_pressed or event.button_mask&MOUSE_BUTTON_MASK_RIGHT):
		_tour_view_active=false
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
			KEY_V:set_auto_view(not sky.system_view.body_fader)
			KEY_ENTER:continue_interlude()
			KEY_K:skip_stage()
			KEY_J:set_brightness_trial(BRIGHTNESS_STOPS[(BRIGHTNESS_STOPS.find(brightness_stops)+1)%BRIGHTNESS_STOPS.size()])
			KEY_TAB:toggle_controls()
			KEY_R:set_preset("reset")
			KEY_G:guides.visible=not guides.visible
			KEY_B:
				if not live_journey:await benchmark.run(self)
			KEY_M:open_navigation()
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
	if journey_sim!=null:journey_sim.stop()
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
	var manual_ev:float=sky.exposure.ev_dark()-brightness_stops
	ok=ok and sky.exposure.fixed and not sky.temporal_exposure and sky.exposure.ev==manual_ev
	print("ship-demo-smoke-stage manual exposure: ",ok," EV=",sky.exposure.ev)
	ok=ok and not commons.is_empty() and commons.visual.get_parent()==geometry
	print("ship-demo-smoke-stage assets: ",ok)
	if ok:
		for direction in 2:
			ok=ok and lift.board()
			lift.advance(.81);lift.advance(11.01);lift.advance(.81)
		ok=ok and lift.state=="bridge_ready" and walk==walk_bridge and avatar_pos.distance_to(Vector3(8,82,-4.8))<.01
	print("ship-demo-smoke-stage lift: ",ok)
	if ok:
		journey_auto_tick=false;open_navigation()
		ok=ok and journey_map!=null
		print("ship-demo-smoke-stage navigation: ",ok," ",caption)
		if ok:
			ok=journey_map.open_commit_dialog() and journey_map.hold_commit(GalaxyMap.HOLD_S) and journey_tick()
			ok=ok and live_journey and not navigation_window.visible and sky.beta>0.
			print("ship-demo-smoke-stage commit: ",ok," refused=",journey_sim.last_refused)
			for i in 1220:
				if not live_journey:break
				ok=journey_tick() and ok and sky.exposure.fixed and not sky.temporal_exposure and sky.exposure.ev==manual_ev
			ok=ok and journey_map.journey_state()=="arrived" and sky.beta==0.
			print("ship-demo-smoke-stage arrival: ",ok," phase=",sky_world.ship.phase)
	print("ship-demo-export-smoke: %s" % ("OK" if ok else "FAIL"))
	get_tree().quit(0 if ok else 1)
func _identification_smoke() -> void:
	auto=false;journey_auto_tick=false
	set_sky_state("rest");look_direction("forward")
	var key := InputEventKey.new();key.physical_keycode=KEY_I;key.pressed=true
	Input.parse_input_event(key)
	for frame in 3:await get_tree().process_frame
	var ok: bool = ready_ok and star_identification.held and not star_identification.candidates.is_empty()
	print("ship-identification-smoke-stage candidates: ",ok," count=",star_identification.candidates.size())
	if ok:
		var candidate: Dictionary = star_identification.candidates[0]
		for option in star_identification.candidates:
			if star_identification.at_point(option.point).size()==1 and not hud.get_global_rect().has_point(option.point):
				candidate=option;break
		var click := InputEventMouseButton.new();click.button_index=MOUSE_BUTTON_LEFT;click.pressed=true;click.position=candidate.pixel;click.global_position=candidate.pixel
		print("identify-smoke-pixel: ",candidate.pixel," UI=",candidate.point," transform=",get_viewport().get_stretch_transform()," window=",get_window().position)
		get_viewport().push_input(click,false)
		await get_tree().process_frame
		click.pressed=false;get_viewport().push_input(click,false)
		await get_tree().process_frame
		if star_identification.card.visible and star_identification.selected_id.is_empty():
			# A real catalogue blend opens its choice list, exactly as normal play.
			var list: VBoxContainer=star_identification.content.get_child(1).get_child(0)
			for button in list.get_children():
				if button.text.ends_with(candidate.id):
					var point: Vector2=get_viewport().get_stretch_transform()*button.get_global_rect().get_center()
					for pressed in [true,false]:
						var choice:=InputEventMouseButton.new();choice.button_index=MOUSE_BUTTON_LEFT;choice.pressed=pressed;choice.position=point;choice.global_position=point
						get_viewport().push_input(choice,false);await get_tree().process_frame
					break
		ok=star_identification.selected_id==candidate.id and star_identification.card.visible and journey_map==null
		print("ship-identification-smoke-stage card: ",ok," picked=",star_identification.selected_id," want=",candidate.id)
		key.pressed=false;Input.parse_input_event(key);await get_tree().process_frame
		ok=ok and not star_identification.held and star_identification.card.visible
		print("ship-identification-smoke-stage release: ",ok)
		star_identification.open_map.emit(candidate.id)
		ok=ok and journey_map!=null and journey_map.catalogue[journey_map.selected_index].id==candidate.id and not live_journey
		print("ship-identification-smoke-stage map: ",ok)
	print("ship-star-identification-export-smoke: %s" % ("OK" if ok else "FAIL"))
	var tree := get_tree()
	# A coroutine owned by this Node is cancelled when queue_free completes.
	# Connect the surviving SceneTree itself for shutdown after cleanup instead.
	tree.create_timer(.1).timeout.connect(tree.quit.bind(0 if ok else 1),CONNECT_ONE_SHOT)
	queue_free()

## Separate session: this demo never touches main.gd's active voyage.
func open_navigation() -> void:
	if solar_tour!=null:
		solar_tour.paused=true;solar_pause.text="Resume tour"
	_create_navigation("sol")
	if DisplayServer.get_name()!="headless" and navigation_window!=null:navigation_window.popup_centered()
func _create_navigation(scenario:String) -> void:
	if benchmark.running:return
	if journey_map==null:
		journey_sim=SimBridge.new();journey_sim.want_minor=SimBridge.DEPARTURE_MINOR
		var params:Dictionary={"standoff_au":1000.}
		if scenario=="solar_departure":params=SolarDeparture.guided_params()
		if not journey_sim.start() or not journey_sim.new_game(424242,scenario,false,params):
			caption="Navigation unavailable: "+journey_sim.last_error
			journey_sim.stop();journey_sim=null;return
		navigation_window=Window.new();navigation_window.hide();navigation_window.title="Ship navigation · M / Esc return aboard"
		navigation_window.size=Vector2i(1280,800);navigation_window.min_size=Vector2i(900,600)
		navigation_window.force_native=true;navigation_window.own_world_3d=true
		navigation_window.close_requested.connect(close_navigation)
		navigation_window.window_input.connect(func(event:InputEvent)->void:
			if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_M,KEY_ESCAPE]:close_navigation())
		add_child(navigation_window)
		journey_map=load("res://ui/galaxy_map.tscn").instantiate()
		journey_map.auto_tick=false;journey_map.live_pacing=true
		navigation_window.add_child(journey_map)
		journey_map.load_catalogue("res://data/starmap/stars.json");journey_map.load_names("res://data/starmap/names.json")
		journey_map.attach(journey_sim)
		var acen:=journey_map.index_of("CNS5:3627")
		if journey_map.preselect(acen):journey_map.frame_star(acen)
		if scenario=="sol":journey_tick()
func start_solar_departure() -> bool:
	if benchmark.running or live_journey or (journey_sim!=null and journey_sim.world.get("journey",{}).get("state","")=="committed"):
		caption="Finish the committed journey before starting a new Solar demo.";return false
	if journey_sim!=null:journey_sim.stop()
	if navigation_window!=null:
		remove_child(navigation_window);navigation_window.queue_free()
	journey_sim=null;journey_map=null;navigation_window=null;solar_tour=null
	_create_navigation("solar_departure")
	if journey_map==null:return false
	solar_tour=SolarDeparture.new()
	solar_tour.deferred_commit=true
	_attitude_stop=-99;_attitude_pending=-99;_attitude_mode=""
	var initial_heading:Dictionary=journey_sim.world.ship.heading
	tour_attitude.reset(ShipFrame.ship_basis(PackedFloat64Array([initial_heading.x,initial_heading.y,initial_heading.z])))
	camera.attitude_basis=tour_attitude.current.duplicate()
	if not solar_tour.attach(journey_sim,journey_map.catalogue):
		caption="Solar departure could not attach to the new session.";solar_tour=null;return false
	solar_tour.pin_destinations(sky.starfield)
	journey_map.guided_read_only=true
	solar_pause.visible=true;solar_next.visible=true;solar_skip.visible=true;solar_pause.text="Pause tour"
	sky_state="live";caption="Guided tour: 12-second stops; Next stop skips a dwell. M pauses for navigation."
	_apply_journey_world();look_direction("forward");close_navigation()
	return true
func close_navigation() -> void:
	if navigation_window==null:return
	journey_map.close_commit_dialog();navigation_window.hide()
func open_identified_star(id: String) -> void:
	open_navigation()
	if journey_map != null:
		var index := journey_map.index_of(id)
		if index >= 0 and journey_map.preselect(index):journey_map.frame_star(index)
func journey_tick() -> bool:
	if journey_map==null:return false
	var was_committed:=live_journey
	var ok:bool=solar_tour.step() if solar_tour!=null else journey_map.tick()
	if not ok:
		caption="Navigation step failed: "+journey_sim.last_error;return false
	if solar_tour!=null:journey_map.refresh()
	_apply_journey_world()
	_show_interlude()
	if live_journey and not was_committed:close_navigation()
	return true
## D-41: the cruise interlude's card, shown over the live cruise sky while active.
func _show_interlude() -> void:
	var card:CardInterlude=solar_tour.interlude as CardInterlude if solar_tour!=null else null
	interlude_card.visible=card!=null
	if card!=null:interlude_card.show_interlude(card)
## Skip to the next stage of the leg (labelled; the sim is stepped exactly to the boundary).
func skip_stage() -> void:
	if solar_tour!=null and solar_tour.skip_stage():_apply_journey_world();_show_interlude()
func continue_interlude() -> void:
	if solar_tour!=null and solar_tour.interlude is CardInterlude:(solar_tour.interlude as CardInterlude).finish()
func _apply_journey_world()->void:
	var was_committed:=live_journey
	live_journey=journey_map.journey_state()=="committed"
	if live_journey or was_committed or sky_state=="live":
		sky_state="live";sky_world=journey_sim.world.duplicate(true)
		var h:Dictionary=sky_world.ship.heading
		camera.heading=PackedFloat64Array([h.x,h.y,h.z])
		if solar_tour!=null and live_journey:
			tour_attitude.reset(ShipFrame.ship_basis(camera.heading))
			camera.attitude_basis=tour_attitude.current.duplicate()
		sky.apply(sky_world);_sync_observer()
func _begin_tour_turn(target:PackedFloat64Array,tilt:float,mode:String)->void:
	tour_attitude.turn_to(target,3.)
	_attitude_mode=mode
	solar_tour.attitude_hold=true
	_tour_view_from=Vector2(camera.tilt,camera.yaw)
	_tour_view_to=Vector2(tilt,0.)
	_tour_view_elapsed=0.;_tour_view_active=true
func _update_tour_attitude(delta:float)->void:
	if solar_tour==null or benchmark.running:return
	if solar_tour.paused:return
	if solar_tour.pending_index>=0:
		if _attitude_pending!=solar_tour.pending_index:
			_attitude_pending=solar_tour.pending_index
			var h:Dictionary=solar_tour.pending_heading
			_begin_tour_turn(ShipFrame.ship_basis(PackedFloat64Array([h.x,h.y,h.z])),89.5,"departure")
	elif not live_journey and _attitude_stop!=solar_tour.leg_index:
		_attitude_stop=solar_tour.leg_index
		var id:String="earth" if solar_tour.leg_index<0 else solar_tour.itinerary[solar_tour.leg_index].id
		for body:Dictionary in sky_world.get("system",{}).get("bodies",[]):
			if body.id==id:
				var v:Dictionary=body.rel_km
				_begin_tour_turn(Attitude.side_basis(PackedFloat64Array([v.x,v.y,v.z])),15.,"stop")
				break
	tour_attitude.advance(delta)
	camera.attitude_basis=tour_attitude.current.duplicate()
	if _tour_view_active:
		_tour_view_elapsed=minf(3.,_tour_view_elapsed+maxf(delta,0.))
		var t:float=_tour_view_elapsed/3.;t=t*t*(3.-2.*t)
		camera.tilt=lerpf(_tour_view_from.x,_tour_view_to.x,t)
		camera.yaw=lerp_angle(_tour_view_from.y,_tour_view_to.y,t)
		if _tour_view_elapsed>=3.:_tour_view_active=false
	if not tour_attitude.turning() and not _attitude_mode.is_empty():
		var finished:=_attitude_mode;_attitude_mode=""
		solar_tour.attitude_hold=false
		if finished=="departure":
			if solar_tour.commit_prepared():_apply_journey_world()
			else:caption="Tour departure failed: "+solar_tour.failed
## Compact HUD (Mark, 2026-10-06): where, how fast and both clocks, read from the sim;
## the review/debug block shows with the controls panel (Tab).
const PHASE_WORDS := {"at_rest":"STOPPED","boosting":"ACCELERATING","cruising":"CRUISING","braking":"BRAKING","approaching":"FINAL APPROACH"}
func hud_text(view_name: String, details: String) -> String:
	var ship: Dictionary = sky_world.get("ship", {}) if sky_world is Dictionary else {}
	var clock: Dictionary = sky_world.get("clock", {}) if sky_world is Dictionary else {}
	var where := "Ship · %s" % view_name
	if solar_tour != null:
		var state: String = "CRUISE INTERLUDE" if solar_tour.interlude != null else PHASE_WORDS.get(str(ship.get("phase", "")), str(ship.get("phase", "")).to_upper())
		where = "→ %s · %s" % [solar_tour.leg_name() if solar_tour.leg_index >= 0 else "Earth", state]
	var speed := speed_text(ship)
	if solar_tour != null and sky_world is Dictionary and sky_world.get("journey", {}).get("state", "") == "committed":
		speed += " · %.2f M g this leg" % (solar_tour.leg_thrust_g() / 1.0e6)
	var lines := [where, speed]
	var dist := distances_text(sky_world if sky_world is Dictionary else {}, solar_tour)
	if not dist.is_empty(): lines.append(dist)
	if not clock.is_empty():
		lines.append("Ship +%s · Earth +%s since departure" % [duration_text(float(clock.get("tau", 0.0))), duration_text(float(clock.get("year", 0.0)))])
	var view := ("AUTO" if sky.system_view.body_fader else "REALISTIC") + " view · V view · J brightness · K skip stage · Tab details"
	if solar_tour != null and solar_tour.skips > 0: view += " · skipped %d stage%s" % [solar_tour.skips, "" if solar_tour.skips == 1 else "s"]
	if camera_mode == "player" and camera.pullback > 0.01: view += " · third-person camera"
	lines.append(view)
	if not caption.is_empty(): lines.append(caption)
	return "\n".join(lines) + ("\n\n" + details if controls.visible else "")

## Speed from the sim's exact fields: beta with as many nines as 1 - beta needs, gamma, km/s.
static func speed_text(ship: Dictionary) -> String:
	var beta: float = float(ship.get("beta", 0.0))
	if beta <= 0.0: return "At rest"
	var omb: float = float(ship.get("one_minus_beta", 1.0 - beta))
	var n := -log(maxf(omb, 1e-15)) / log(10.0)
	var digits := clampi(int(round(n)) if absf(n - round(n)) < 1e-9 else int(ceil(n)), 4, 9)
	var km_s := String.num_int64(int(round(beta * 299792.458)))
	var grouped := ""
	for i in km_s.length():
		if i > 0 and (km_s.length() - i) % 3 == 0: grouped += ","
		grouped += km_s[i]
	return ("%." + str(digits) + "fc · γ %s · %s km/s") % [1.0 - omb, ("%.2f" % float(ship.get("gamma", 1.0))) if float(ship.get("gamma", 1.0)) < 1000.0 else "%.0f" % float(ship.get("gamma", 1.0)), grouped]

## Distances (Mark, 2026-10-06): to the destination (the sim's distance_remaining), from
## the last stop where the leg was committed (plan.departure), and from Earth (the
## system section's Earth, else Sol). Only vector lengths of sim positions, in float64.
static func distances_text(world: Dictionary, tour) -> String:
	var parts := PackedStringArray()
	var journey: Dictionary = world.get("journey", {})
	var ship: Dictionary = world.get("ship", {})
	var committed: bool = journey.get("state", "") == "committed"
	if committed:
		var name: String = tour.leg_name() if tour != null else str(journey.get("plan", {}).get("target", {}).get("id", "destination"))
		parts.append("To %s %s" % [name, distance_text(float(world.get("consequence", {}).get("distance_remaining", 0.0)))])
		var dep: Dictionary = journey.get("plan", {}).get("departure", {})
		var pos: Dictionary = ship.get("pos", {})
		if not dep.is_empty() and not pos.is_empty():
			var from_name: String = "last stop"
			if tour != null: from_name = "Earth" if tour.leg_index <= 0 else str(tour.itinerary[tour.leg_index - 1].get("name", "last stop"))
			parts.append("from %s %s" % [from_name, distance_text(sqrt(pow(float(pos.x) - float(dep.x), 2.0) + pow(float(pos.y) - float(dep.y), 2.0) + pow(float(pos.z) - float(dep.z), 2.0)))])
	var earth_ly := -1.0
	for b: Dictionary in world.get("system", {}).get("bodies", []):
		if b.get("id", "") == "earth": earth_ly = Planets.length64(Planets.world_of(b.rel_km)) / 9460730472580.8
	var pos2: Dictionary = ship.get("pos", {})
	if earth_ly < 0.0 and not pos2.is_empty(): earth_ly = sqrt(pow(float(pos2.x), 2.0) + pow(float(pos2.y), 2.0) + pow(float(pos2.z), 2.0))
	if earth_ly >= 0.0: parts.append("from Earth %s" % distance_text(earth_ly))
	return " · ".join(parts)

## A distance in light-years, shown in km, AU or ly as it reads best.
static func distance_text(ly: float) -> String:
	var km := ly * 9460730472580.8
	if km < 1.0e6: return "%s km" % _grouped(int(round(km)))
	var au := km / 149597870.7
	if ly < 0.1: return ("%.3f AU" if au < 10.0 else "%.1f AU" if au < 1000.0 else "%.0f AU") % au
	return ("%.2f ly" if ly < 100.0 else "%.1f ly") % ly

static func _grouped(n: int) -> String:
	var t := String.num_int64(n);var out := ""
	for i in t.length():
		if i > 0 and (t.length() - i) % 3 == 0: out += ","
		out += t[i]
	return out

## Years as a readable duration: seconds through years.
static func duration_text(years: float) -> String:
	var s := years * 31557600.0
	if s < 120.0: return "%.0f s" % s
	if s < 7200.0: return "%.1f min" % (s / 60.0)
	if s < 172800.0: return "%.1f h" % (s / 3600.0)
	if years < 2.0: return "%.1f days" % (s / 86400.0)
	return "%.2f yr" % years

func journey_label() -> String:
	if solar_tour!=null:return solar_tour.status_text()+ (" · PAUSED" if solar_tour.paused else "")
	if sky_state!="live":return "FROZEN MID-JOURNEY SNAPSHOT %.4fc" % sky.beta if sky_state=="cruise" else "AT REST SNAPSHOT"
	return "LIVE %s · %.6fc\nEarth +%.8f yr / ship +%.8f yr · Variable time compression · %s ship-yr/real-s \nM navigation · 7 look forward" % [sky_world.ship.phase,sky.beta,sky_world.clock.year,sky_world.clock.tau,GalaxyMap.sci(journey_map.pacing.rate)]

func _solar_departure_smoke()->void:
	auto=false;journey_auto_tick=false
	var ok:=start_solar_departure()
	if ok:
		ok=solar_tour.advance() and journey_tick() and live_journey
		var before:Dictionary=journey_sim.world.duplicate(true)
		ok=not start_solar_departure() and journey_sim.world==before and ok
		open_navigation()
		ok=solar_tour.paused and journey_map.guided_read_only and not journey_map.open_commit_dialog() and ok
		close_navigation();solar_tour.paused=false
		for tick in 20:ok=journey_tick() and ok
		ok=sky.system_view.drawn_points.has("saturn") and sky_world.ship.phase=="boosting" and sky_world.clock.tau>before.clock.tau and ok
		for frame in 12:await get_tree().process_frame
	print("solar-departure-smoke: %s" %("OK" if ok else "FAIL"))
	var tree:=get_tree()
	solar_tour=null
	tree.create_timer(.1).timeout.connect(tree.quit.bind(0 if ok else 1),CONNECT_ONE_SHOT)
	queue_free()
