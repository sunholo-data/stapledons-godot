extends Node
## Isolated native-material spatial review; its optional voyage is a separate normal simulation.
const Lift := preload("res://demos/ship_demo_lift.gd")
const Camera := preload("res://demos/ship_demo_camera.gd")
const Benchmark := preload("res://demos/ship_demo_benchmark.gd")
const Commons := preload("res://demos/ship_commons.gd")
const Identification := preload("res://ui/ship_star_identification.gd")
const Lighting := preload("res://demos/ship_lighting.gd")
const StarLight := preload("res://demos/ship_star_light.gd")
const SolarDeparture := preload("res://demos/solar_departure.gd")
const Attitude:=preload("res://demos/ship_attitude.gd")
const BlackHoleVisit:=preload("res://demos/black_hole_visit.gd")
const BodyInfo:=preload("res://ui/body_info.gd")
## M3.6 (R1-M3-BLACK-HOLES): the Sgr A* demo, its own sgr_a session (null = flat space, GR off).
var black_hole:RefCounted=null
var codex:Codex # the Archive codex (M4.7), built on first use; unlocks only from the sim
var _bh_accum:=0.
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
var star_light:=StarLight.new() # R1-SHIP-STAR-LIGHT: the real star's light on the geometry
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
var label := Label.new() # retired (R1-SHIP-UI U1); never shown
var hud: Control # the status strip (ShipHud.strip)
var ship_hud: ShipHud
var dwell_on := true
var hint_dismissed := false
var confirm_button := Button.new()
## R1-SHIP-UI §C4: every irreversible decision confirms by a 1.5 s hold, or (accessibility
## setting, title Settings and Tab) by pressing twice. Neither has a deadline.
var confirm_mode := "hold"
## R1-SHIP-UI U3: the bridge consoles (demos/ship_consoles.gd); every captain decision goes
## through consoles.use(station, action).
var consoles: ShipConsoles
## Tests: Esc's last resort (main menu or quit) can be switched off.
var escape_exits := true
var _mouse := Vector2(-1, -1)
var _aim_t := 0.0
var _dwell_pose := Transform3D()
var _dwell_still := 0.0
var _dwell_done := false
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
var controls: Control # the Tab panel (ShipHud.tab_panel)
var commons: Dictionary = {}
const BRIGHTNESS_STOPS := [-24,-16,-8,0,1,2,4,6]
var brightness_stops := 2
var view_button := Button.new()
var interlude_card: InterludeCard
var journey_sim: SimBridge
var journey_map: GalaxyMap
var navigation_window: Window
var live_journey := false
## Free navigation: where the committed leg left from and the last stop reached (HUD names).
var leg_from := "Earth"
var last_stop := "Earth"
var journey_auto_tick := true
var _journey_accum := 0.
var solar_tour: RefCounted
## Launched from the title screen (main.gd): Esc and the HUD's menu button return
## there. Every command-line launch keeps Esc = quit.
var menu_return := false
var settings_dir := "user://" # where the title screen keeps settings.cfg (tests redirect it)
var menu_button := Button.new()
func _ready() -> void:
	setup(setup_options)
	if OS.get_cmdline_user_args().has("--ship-demo-smoke"):_export_smoke.call_deferred()
	if OS.get_cmdline_user_args().has("--ship-identification-smoke"):_identification_smoke.call_deferred()
	if OS.get_cmdline_user_args().has("--solar-departure-smoke"):_solar_departure_smoke.call_deferred()
	if ready_ok and setup_options.get("scenario",scenario_arg(OS.get_cmdline_user_args()))==BlackHoleVisit.SCENARIO:start_black_hole.call_deferred()
## make run-bh: --scenario=sgr_a starts the Sgr A* demo aboard (the only scenario this launch takes).
static func scenario_arg(args:PackedStringArray)->String:
	for a in args:
		if a.begins_with("--scenario="):return a.trim_prefix("--scenario=")
	return ""
func asset(file: String) -> String:
	var source := "res://assets/ship_demo/"+file
	return source if FileAccess.file_exists(source) else "res://ship_demo_bundle/"+file+".bin"
func setup(opts := {}) -> bool:
	if ready_ok:return true
	menu_return=opts.get("from_menu",false)
	settings_dir=opts.get("settings_dir",settings_dir)
	manifest=JSON.parse_string(FileAccess.get_file_as_string(asset("manifest.json")))
	var px: Vector2i=opts.get("size",get_window().size)
	var visual := AreaBundle.load_glb(asset("ship.glb"))
	if visual==null:push_error("ship demo missing GLB");return false
	geometry_view.size=px;geometry_view.own_world_3d=true;geometry_view.transparent_bg=true
	geometry_view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	add_child(geometry_view);geometry_view.add_child(geometry);geometry.add_child(visual)
	_collision(visual)
	geometry_view.add_child(camera);camera.current=true
	lighting=Lighting.install(geometry);star_light.install(lighting)
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
	confirm_mode=opts.get("confirm_mode","hold") if opts.get("confirm_mode","hold") in GameSettings.CONFIRM_MODES else "hold"
	confirm_button.text="Confirm decisions: "+("press twice" if confirm_mode=="twice" else "hold")
	consoles.set_confirm_mode(confirm_mode)
	if menu_return:
		consoles.set_glow(true);ship_hud.show_hint(ShipConsoles.HINT)
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
## R1-SHIP-UI (D-56): the HUD informs (ui/ship_hud.gd); display controls stay instant in
## the Tab panel; developer controls only on command-line launches (menu_return false).
func _hud() -> void:
	var canvas:=CanvasLayer.new();canvas.layer=10;add_child(canvas)
	ship_hud=ShipHud.new();canvas.add_child(ship_hud);ship_hud.setup(not menu_return)
	hud=ship_hud.strip
	ship_hud.view_tag_pressed.connect(toggle_auto_view)
	ship_hud.walk_to_requested.connect(walk_to)
	ship_hud.hint_dismissed.connect(func()->void:hint_dismissed=true)
	controls=ship_hud.tab_panel
	menu_button.text="Main menu [Esc]";menu_button.visible=menu_return;menu_button.focus_mode=Control.FOCUS_NONE
	menu_button.add_theme_font_size_override("font_size",12)
	menu_button.pressed.connect(return_to_menu);ship_hud.corner.add_child(menu_button)
	var display:=ship_hud.display_box
	view_button.pressed.connect(toggle_auto_view);display.add_child(view_button)
	var brightness_row:=GridContainer.new();brightness_row.columns=4;display.add_child(brightness_row)
	for stops in BRIGHTNESS_STOPS:
		var button:=Button.new();button.text="Reference sky" if stops==0 else ("Dim %d stops"%(-stops) if stops<0 else "%d× brighter"%int(pow(2.,stops)))
		button.pressed.connect(set_brightness_trial.bind(stops));brightness_row.add_child(button)
	var sky_button:=Button.new();sky_button.text="Sky only [H]";sky_button.pressed.connect(toggle_sky_only);display.add_child(sky_button)
	var dwell_button:=CheckButton.new();dwell_button.text="Name what I look at (dwell label)";dwell_button.button_pressed=true
	dwell_button.toggled.connect(func(on:bool)->void:dwell_on=on;ship_hud.set_dwell("",Vector2.ZERO));display.add_child(dwell_button)
	confirm_button.text="Confirm decisions: hold";confirm_button.pressed.connect(toggle_confirm_mode);display.add_child(confirm_button)
	var row:=HBoxContainer.new();display.add_child(row)
	for pair in [["Bridge [1]","bridge"],["Overlook [2]","overlook"],["Whole ship [3]","overview"],["Rim [4]","rim"],["Reset [R]","reset"]]:
		var button:=Button.new();button.text=pair[0];button.pressed.connect(set_preset.bind(pair[1]));row.add_child(button)
	var look_row:=HBoxContainer.new();display.add_child(look_row)
	for pair in [["Look forward [7]","forward"],["Look side [8]","side"],["Look aft [9]","aft"]]:
		var button:=Button.new();button.text=pair[0];button.pressed.connect(look_direction.bind(pair[1]));look_row.add_child(button)
	var dev:=ship_hud.dev_box
	var dev_title:=Label.new();dev_title.text="Developer (command-line launches only)";dev.add_child(dev_title)
	var benchmark_button:=Button.new();benchmark_button.text="Benchmark at 1920×1080 [B] (uploads public summary)";benchmark_button.pressed.connect(func() -> void: await benchmark.run(self));dev.add_child(benchmark_button)
	audit_local.text="Show local audit in Finder"
	audit_local.pressed.connect(func()->void:OS.shell_show_in_file_manager(ProjectSettings.globalize_path(Benchmark.OUTPUT)))
	dev.add_child(audit_local)
	var sky_row:=HBoxContainer.new();dev.add_child(sky_row)
	for pair in [["Rest sky [5]","rest"],["Mid-journey 0.99c sky [6]","cruise"]]:
		var button:=Button.new();button.text=pair[0];button.pressed.connect(set_sky_state.bind(pair[1]));sky_row.add_child(button)
	var guides_button:=Button.new();guides_button.text="Orbit guides [G]";guides_button.pressed.connect(func()->void:guides.visible=not guides.visible);dev.add_child(guides_button)
	_consoles_setup()
func toggle_controls() -> void:
	if not benchmark.running:ship_hud.toggle_tab()
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
## The player's toggle (V or the button): in a ship launched from the title screen the
## choice is saved, so the next session starts the same way (D-55).
func toggle_auto_view() -> void:
	set_auto_view(not sky.system_view.body_fader)
	if menu_return:
		var gs:=GameSettings.new();gs.dir=settings_dir;gs.load_settings();gs.auto_view=sky.system_view.body_fader;gs.save_settings()
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
	if benchmark.running or live_journey or solar_tour!=null or black_hole!=null or not sky_states.has(name):return false
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
			if audit_link.get_parent()==null:ship_hud.dev_box.add_child(audit_link)
	if not ready_ok:return
	sky.set_temporal_exposure(false)
	_update_tour_attitude(delta)
	if journey_map!=null and journey_auto_tick and not benchmark.running:
		_journey_accum=minf(_journey_accum+delta,4./GalaxyMap.TICK_HZ)
		while _journey_accum>=1./GalaxyMap.TICK_HZ:
			_journey_accum-=1./GalaxyMap.TICK_HZ
			journey_tick()
	if black_hole!=null and journey_auto_tick and not benchmark.running:
		_bh_accum=minf(_bh_accum+delta,4./BlackHoleVisit.TICK_HZ)
		while _bh_accum>=1./BlackHoleVisit.TICK_HZ and black_hole!=null:
			_bh_accum-=1./BlackHoleVisit.TICK_HZ
			bh_tick()
	if auto and (navigation_window==null or not navigation_window.visible) and camera_mode=="player" and (lift==null or not lift.travelling()):
		var move:=Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_W))-float(Input.is_physical_key_pressed(KEY_S)))
		if move!=Vector2.ZERO:consoles.cancel_walk() # WASD takes over an auto-walk
		walk_motion(move,delta)
	consoles.advance(delta)
	_aim_t+=delta
	if _aim_t>=.1 and _mouse.x>=0.:_aim_t=0.;consoles.aim(_mouse)
	if lift!=null:lift.advance(delta if auto else 0.)
	if avatar.get_parent()==geometry:avatar.position=avatar_pos
	if camera_mode=="player":camera.follow(avatar_pos,camera.tilt,camera.yaw,camera.pullback)
	avatar.visible=camera.pullback>.5 or camera.external
	avatar_shadow.global_position=avatar.global_position
	_sync_observer()
	sky.finish_exposure_frame(delta)
	star_light.update(lighting,sky,delta)
	var view_name: String="external pullback review — not captain eye" if camera.external and camera_mode=="player" else camera_mode
	var details:String="CURRENT SHIP · seven tiers · "+gr_status()+"\n%s\n%s · deck %d · eye %.2f m · view/travel %.1f° · 78° perspective\n%s%s" % [journey_label(),view_name+((" · third-person camera" if camera.pullback>0.01 else " · captain eye") if camera_mode=="player" else " · reference camera"),active_level,camera.position.y,sky.camera.view_velocity_angle(sky.heading_world),"SKY ONLY DIAGNOSTIC — opaque ship hidden; travel is UP, aft is DOWN\n" if sky_only else ("Stationary ship attitude turn; simulation time held.\n" if solar_tour!=null and solar_tour.attitude_hold else ("Stationary side view; floors remain opaque.\n" if solar_tour!=null and not live_journey else "Travel is UP; floors correctly block the aft sky.\n")),brightness_label()+" · J cycles brightness · V Realistic/Auto\n"+star_light.hud_line()+"\n"+caption]
	_update_hud(delta,details)
	_update_dwell(delta)
func _unhandled_input(event: InputEvent) -> void:
	if benchmark.running:return
	if UiScale.handle(get_window(),event):
		_resize();get_viewport().set_input_as_handled();return
	if navigation_window!=null and navigation_window.visible:return
	if camera_mode=="console" and (event is InputEventPanGesture or (event is InputEventMouseButton and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN])):return
	if event is InputEventMouseMotion and camera_mode!="console" and (event.alt_pressed or event.button_mask&MOUSE_BUTTON_MASK_RIGHT):
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
	if event is InputEventMouseMotion:_mouse=event.position
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT and not event.alt_pressed:
		if consoles.click(event.position):get_viewport().set_input_as_handled();return
		if ship_hud.has_card("arrival"):dismiss_arrival()
	if event is InputEventKey and event.pressed and not event.echo:
		if camera_mode=="console" and event.physical_keycode in [KEY_1,KEY_2,KEY_3,KEY_4,KEY_R,KEY_7,KEY_8,KEY_9]:return
		match event.physical_keycode:
			KEY_1:set_preset("bridge")
			KEY_2:set_preset("overlook")
			KEY_3:set_preset("overview")
			KEY_4:set_preset("rim")
			KEY_5:
				if dev_controls():set_sky_state("rest")
			KEY_6:
				if dev_controls():set_sky_state("cruise")
			KEY_7:look_direction("forward")
			KEY_8:look_direction("side")
			KEY_9:look_direction("aft")
			KEY_H:toggle_sky_only()
			KEY_V:toggle_auto_view()
			KEY_ENTER:
				if not continue_interlude():dismiss_arrival()
			KEY_K:
				if black_hole!=null:bh_finish_approach()
				else:skip_stage()
			KEY_P:toggle_tour_pause()
			KEY_N:skip_dwell()
			KEY_J:set_brightness_trial(BRIGHTNESS_STOPS[(BRIGHTNESS_STOPS.find(brightness_stops)+1)%BRIGHTNESS_STOPS.size()])
			KEY_TAB:toggle_controls()
			KEY_R:set_preset("reset")
			KEY_G:
				if dev_controls():guides.visible=not guides.visible
			KEY_B:
				if dev_controls() and not live_journey:await benchmark.run(self)
			KEY_M:open_chart()
			KEY_E:use_nearest()
			KEY_ESCAPE:escape()
## Developer review controls (B, G, 5, 6, the audit buttons): command-line launches only (AC11).
func dev_controls() -> bool:
	return not menu_return
## Esc closes the top panel or card; otherwise the main menu (menu launch) or quit.
func escape() -> void:
	if consoles.escape():return
	if codex!=null and codex.panel.visible:codex.close()
	elif ship_hud.tab_panel.visible:ship_hud.toggle_tab()
	elif star_identification!=null and star_identification.card.visible:star_identification.close_card()
	elif ship_hud.has_card("arrival"):dismiss_arrival()
	elif not escape_exits:return
	elif menu_return:return_to_menu()
	else:get_tree().quit()
## E: the console or the lift in reach and facing (the nearest wins; the prompt names it),
## or, at a console, step back.
func use_nearest() -> bool:
	return consoles.press_e()
## Back to the title screen (main.tscn on a plain launch); _exit_tree stops the voyage's sim.
func return_to_menu() -> void:
	if not menu_return or benchmark.running:return
	menu_return=false # once: the scene change is deferred
	get_tree().change_scene_to_file("res://main.tscn")
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
	if black_hole!=null:black_hole.stop()
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
	# The exported app must carry the GR lens tables (dev.23 shipped without them: Sgr A*
	# drew nothing). Load and check them from the bundle, as the lensed sky does.
	var lens_ok:=Schwarzschild.load_tables()
	ok=ok and lens_ok
	print("ship-demo-smoke-stage lens tables: ",lens_ok," ",Schwarzschild.load_error)
	if ok:
		for direction in 2:
			ok=ok and lift.board()
			lift.advance(.81);lift.advance(11.01);lift.advance(.81)
		ok=ok and lift.state=="bridge_ready" and walk==walk_bridge and avatar_pos.distance_to(Vector3(8,82,-4.8))<.01
	print("ship-demo-smoke-stage lift: ",ok)
	if ok:
		journey_auto_tick=false
		consoles.go_to("navigation")
		ok=consoles.use("navigation","open") and journey_map!=null and journey_map.mode=="helm"
		print("ship-demo-smoke-stage navigation: ",ok," ",caption)
		if ok:
			ok=consoles.use("navigation","commit") and journey_tick()
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
			if star_identification.at_point(option.point).size()==1 and not hud.get_global_rect().has_point(option.point) and not ship_hud.column.get_global_rect().has_point(option.point) and not ship_hud.corner.get_global_rect().has_point(option.point):
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

## The helm (R1-SHIP-UI §D): the full map in helm mode, the navigation station's panel.
## consoles.use("navigation", "open") calls it; tests and tools call it directly as the
## console action's target. Separate session: this demo never touches main.gd's voyage.
func open_navigation() -> void:
	if black_hole!=null:
		refuse("Navigation is for flat space: leave Sgr A* first.");return
	_create_navigation("sol")
	if navigation_window==null:return
	journey_map.set_confirm_twice(confirm_mode=="twice")
	journey_map.set_mode("helm")
	var entry:Control=navigation_window.find_child("SgrAEntry",true,false)
	if entry!=null:entry.visible=solar_tour==null
	navigation_window.borderless=true;navigation_window.title="Navigation station · E / Esc steps back"
	_place_navigation(consoles.panel_rect().grow_individual(-8.,-46.,-8.,-8.) if consoles!=null and consoles.focused=="navigation" else Rect2())
## M (anywhere, instant): the read-only star chart. It never plans, commits or pauses the
## voyage (D-57 Q2); plotting and commit are at the navigation station.
func open_chart() -> void:
	if black_hole!=null:
		note("The star chart is for flat space; at Sgr A* the stop ladder is at the navigation station.");return
	_create_navigation("sol")
	if navigation_window==null:return
	journey_map.set_mode("chart")
	var entry:Control=navigation_window.find_child("SgrAEntry",true,false)
	if entry!=null:entry.visible=false
	navigation_window.borderless=false;navigation_window.title="Star chart (read only) · M / Esc close"
	_place_navigation(Rect2())
## The map host (R1-SHIP-UI U4a): an embedded window over the console panel (helm), or
## centred (the chart, and direct calls).
func _place_navigation(rect: Rect2) -> void:
	var vis:=get_viewport().get_visible_rect().size
	if rect.size==Vector2.ZERO: # centred below the status strip (the title bar sits above the rect)
		var top:float=(ship_hud.strip_bottom() if ship_hud!=null else 0.)+40.
		var sz:=Vector2(minf(1280.,vis.x*.86),minf(800.,vis.y-top-56.))
		rect=Rect2(Vector2((vis.x-sz.x)*.5,top),sz)
	navigation_window.position=Vector2i(rect.position);navigation_window.size=Vector2i(rect.size)
	# The map's own panel needs about 700 units of height: scale its content to the host.
	navigation_window.content_scale_factor=clampf(rect.size.y/600.,.56,1.)
	navigation_window.show();navigation_window.grab_focus()
func _create_navigation(scenario:String) -> void:
	if benchmark.running:return
	if journey_map==null:
		journey_sim=SimBridge.new();journey_sim.want_minor=SimBridge.DEPARTURE_MINOR
		# R1-SHIP-UI: the Archive terminal shows what this session has unlocked (protocol 2.2 table).
		journey_sim.archive_rows=LoreLoader.archive_rows(LoreLoader.load_entries()["entries"])
		# D-54: free navigation stops at a finite star where it shows its size, and Sol at Earth.
		var params:Dictionary={"standoff_au":1000.,"stop_rule":54.}
		if scenario=="solar_departure":params=SolarDeparture.guided_params()
		if not journey_sim.start() or not journey_sim.new_game(424242,scenario,false,params):
			refuse("Navigation unavailable: "+journey_sim.last_error)
			journey_sim.stop();journey_sim=null;return
		navigation_window=Window.new();navigation_window.hide();navigation_window.title="Ship navigation"
		navigation_window.size=Vector2i(1280,800);navigation_window.min_size=Vector2i(320,200)
		# R1-SHIP-UI U4a: embedded in the ship's window (its own 3D world and input), laid
		# over the navigation station's panel at the helm.
		navigation_window.force_native=false;navigation_window.own_world_3d=true;navigation_window.transient=true
		navigation_window.close_requested.connect(_navigation_key.bind(KEY_ESCAPE))
		navigation_window.window_input.connect(func(event:InputEvent)->void:
			if event is InputEventKey and event.pressed and not event.echo:_navigation_key(event.physical_keycode))
		add_child(navigation_window)
		journey_map=load("res://ui/galaxy_map.tscn").instantiate()
		journey_map.auto_tick=false;journey_map.live_pacing=true
		navigation_window.add_child(journey_map)
		journey_map.load_catalogue("res://data/starmap/stars.json");journey_map.load_names("res://data/starmap/names.json")
		journey_map.attach(journey_sim)
		var bh_entry:=Button.new();bh_entry.name="SgrAEntry";bh_entry.text="Sgr A* (black hole) · demo"
		bh_entry.tooltip_text="Leave the Solar System for the black hole at the Galactic Centre (a separate demo session; GR on)"
		bh_entry.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT,Control.PRESET_MODE_MINSIZE,12)
		bh_entry.grow_horizontal=Control.GROW_DIRECTION_BEGIN;bh_entry.grow_vertical=Control.GROW_DIRECTION_BEGIN
		bh_entry.pressed.connect(func()->void:consoles.use("navigation","sgr_a"),CONNECT_DEFERRED) # helm only; the window is freed by the switch
		navigation_window.add_child(bh_entry)
		var acen:=journey_map.index_of("CNS5:3627")
		if journey_map.preselect(acen):journey_map.frame_star(acen)
		if scenario=="sol":journey_tick()
		_reset_hud_session()
func start_solar_departure() -> bool:
	if benchmark.running or live_journey or (journey_sim!=null and journey_sim.world.get("journey",{}).get("state","")=="committed"):
		refuse("Finish the committed journey first.");return false
	if black_hole!=null:leave_black_hole()
	_drop_navigation()
	_create_navigation("solar_departure")
	if journey_map==null:return false
	solar_tour=SolarDeparture.new()
	solar_tour.deferred_commit=true
	_attitude_stop=-99;_attitude_pending=-99;_attitude_mode=""
	var initial_heading:Dictionary=journey_sim.world.ship.heading
	tour_attitude.reset(ShipFrame.ship_basis(PackedFloat64Array([initial_heading.x,initial_heading.y,initial_heading.z])))
	camera.attitude_basis=tour_attitude.current.duplicate()
	if not solar_tour.attach(journey_sim,journey_map.catalogue):
		refuse("The guided voyage could not attach to the new session.");solar_tour=null;return false
	solar_tour.pin_destinations(sky.starfield)
	journey_map.guided_read_only=true
	sky_state="live";note("Guided voyage: Earth to Aldebaran. P pauses, N skips a dwell, K skips a stage.")
	_apply_journey_world();look_direction("forward");close_navigation()
	return true
## The normal navigation session and its window, gone (a guided tour or the Sgr A* demo replaces them).
func _drop_navigation() -> void:
	if journey_sim!=null:journey_sim.stop()
	if navigation_window!=null:
		remove_child(navigation_window);navigation_window.queue_free()
	journey_sim=null;journey_map=null;navigation_window=null;solar_tour=null
func close_navigation() -> void:
	if navigation_window==null:return
	journey_map.close_commit_dialog();navigation_window.hide()
	# Outside the helm the map plans nothing (NT1): it rests in chart mode; any commit the
	# helm already queued still goes out on the next tick.
	if journey_map.mode=="helm":journey_map.set_mode("chart")
## Keys inside the map window: M / Esc close the chart; at the helm E / Esc step back (an
## armed press-twice confirm backs out first). V, J, H stay instant.
func _navigation_key(key: int) -> void:
	if journey_map==null:return
	if key==KEY_ESCAPE and journey_map.armed:journey_map.disarm();return
	if journey_map.mode=="chart":
		if key in [KEY_M,KEY_ESCAPE]:close_navigation()
	elif key in [KEY_E,KEY_ESCAPE]:
		if consoles.focused=="navigation":consoles.leave()
		else:close_navigation()
	if key==KEY_V:toggle_auto_view()
func open_identified_star(id: String) -> void:
	open_chart()
	if journey_map != null:
		var index := journey_map.index_of(id)
		if index >= 0 and journey_map.preselect(index):journey_map.frame_star(index)
func journey_tick() -> bool:
	if journey_map==null:return false
	var was_committed:=live_journey
	var ok:bool=solar_tour.step() if solar_tour!=null else journey_map.tick()
	if not ok:
		refuse("Navigation step failed: "+journey_sim.last_error);return false
	if solar_tour!=null:journey_map.refresh()
	_apply_journey_world()
	_show_interlude()
	if live_journey and not was_committed:
		leg_from=last_stop
		if consoles!=null and consoles.focused=="navigation":consoles.leave() # watch the departure
		else:close_navigation()
	if was_committed and not live_journey and solar_tour==null:last_stop=stop_name()
	return true
## The free-navigation stop's display name: the catalogue name of the plan's target.
func stop_name() -> String:
	var id:=""
	var plan=journey_sim.world.get("journey",{}).get("plan") if journey_sim!=null else null
	if plan is Dictionary and plan.get("target") is Dictionary:id=str(plan.target.get("id",""))
	if star_identification!=null and star_identification.info.names.has(id):return star_identification.info.display_name(id)
	if plan is Dictionary and plan.get("hold") is Dictionary:
		for b:Dictionary in journey_sim.world.get("system",{}).get("bodies",[]):
			if b.get("id","")==str(plan.hold.get("body","")):return body_name(b,star_identification.info.names if star_identification!=null else {})
	return star_identification.info.display_name(id) if star_identification!=null and not id.is_empty() else (id if not id.is_empty() else "last stop")
## D-41: the cruise interlude's card, shown over the live cruise sky while active.
func _show_interlude() -> void:
	var card:CardInterlude=solar_tour.interlude as CardInterlude if solar_tour!=null else null
	interlude_card.visible=card!=null
	if card!=null:interlude_card.show_interlude(card)
## Skip to the next stage of the leg (labelled; the sim is stepped exactly to the boundary).
func skip_stage() -> void:
	if solar_tour!=null and solar_tour.skip_stage():_apply_journey_world();_show_interlude()
func continue_interlude() -> bool:
	if solar_tour!=null and solar_tour.interlude is CardInterlude:
		(solar_tour.interlude as CardInterlude).finish();return true
	return false
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
			else:refuse("Tour departure failed: "+solar_tour.failed)
## R1-SHIP-UI (D-56) U1/U2: the HUD's view and its contextual cards. Every value the strip and
## the cards show is a DisplayBinding on this view: the sim's world, plus a "hud" section of
## lines formatted from sim fields (where, distance, speed, the gravity lines) and "client"
## (the live pacing rate, shown as the transit card's warp; there is no warp control).
const PHASE_WORDS := {"at_rest":"at rest","boosting":"ACCELERATING","cruising":"CRUISE","braking":"BRAKING","approaching":"FINAL APPROACH"}
var _hud_phase := ""
var _hud_state := ""
var _hud_session: Object = null
var _unlocked_seen: Array = []
func hud_view() -> Dictionary:
	var world: Dictionary = sky_world if sky_world is Dictionary else {}
	var view := world.duplicate(false)
	var ship: Dictionary = world.get("ship", {})
	var hud := {"where": where_text(), "speed": speed_text(ship) if float(ship.get("beta", 0.0)) > 0.0 else "", "home_caption": "home (far-away)" if black_hole != null else "Earth"}
	if black_hole != null:
		var g: Dictionary = black_hole.gr()
		hud["distance"] = "r = %s r_s" % BlackHoleVisit.r_text(float(g.get("r", 0.0)))
		var lines := BlackHoleVisit.hud_lines(g)
		var gravity := {}
		for i in lines.size(): gravity[str(i)] = lines[i]
		hud["gravity"] = gravity
	else:
		var dworld := world
		if sky_state != "live": # a review snapshot: where the ship is, not its frozen plan
			dworld = world.duplicate(false); dworld.erase("journey")
		hud["distance"] = distances_text(dworld, solar_tour, star_identification.info.names if star_identification != null else {}, leg_from)
	view["hud"] = hud
	view["client"] = {"warp": journey_map.pacing.rate if journey_map != null else 0.0}
	return view
## The strip's where / phase slot.
func where_text() -> String:
	var ship: Dictionary = sky_world.get("ship", {}) if sky_world is Dictionary else {}
	var phase := str(ship.get("phase", ""))
	var word: String = PHASE_WORDS.get(phase, phase.to_upper())
	if black_hole != null:
		var g: Dictionary = black_hole.gr()
		return "Sgr A* · " + {"hover": "hovering", "orbit": "orbiting", "approach": "approaching"}.get(str(g.get("mode", "")), str(g.get("mode", "")))
	if solar_tour != null:
		if solar_tour.interlude != null: word = "CRUISE INTERLUDE"
		if not live_journey and solar_tour.leg_index < 0: return "Earth orbit · guided voyage ready"
		return ("→ %s · %s" if live_journey else "%s · %s") % [solar_tour.leg_name(), word]
	if sky_state != "live":
		return "Review snapshot · " + ("cruise" if sky_state == "cruise" else "at rest")
	if live_journey:
		return "→ %s · %s" % [stop_name(), word]
	return ("Earth orbit" if last_stop == "Earth" else last_stop) + " · at rest"
## The view tag: one word (details in Tab), plus the camera when it is not the captain's eye.
func view_tag_text() -> String:
	var t := "AUTO" if sky.system_view.body_fader else "REALISTIC"
	if camera_mode == "player" and camera.pullback > 0.01: t += " · third-person camera"
	if active_level == 1: t += " · lower deck"
	return t
func _update_hud(delta: float, details: String) -> void:
	var view := hud_view()
	ship_hud.details.text = details
	ship_hud.set_view_tag(view_tag_text())
	_update_cards(view)
	_place_interlude()
	ship_hud.set_prompt(consoles.prompt_text())
	ship_hud.advance(delta)
	ship_hud.update(view)
## A new sim session (navigation, the guided voyage, Sgr A*): its cards start clean, and
## what it opens with (its own world's unlocks, phase, journey state) is not news.
func _reset_hud_session() -> void:
	if ship_hud == null: return
	_hud_session = black_hole if black_hole != null else journey_sim
	var w: Dictionary = black_hole.sim.world if black_hole != null else (journey_sim.world if journey_sim != null else {})
	for id in ["arrival", "refusal", "unlock"]: ship_hud.hide_card(id) # about the session that ended
	var u: Variant = GalaxyMap.field_value(w, "consequence.archive.unlocked")
	_unlocked_seen = u.duplicate() if u is Array else []
	_hud_phase = str(GalaxyMap.field_value(w, "ship.phase"))
	_hud_state = str(GalaxyMap.field_value(w, "journey.state"))
## Cards by their §A2 triggers. Every card here only shows; none changes game state.
func _update_cards(view: Dictionary) -> void:
	if (black_hole if black_hole != null else journey_sim) != _hud_session: _reset_hud_session()
	var phase := str(GalaxyMap.field_value(view, "ship.phase"))
	var state := str(GalaxyMap.field_value(view, "journey.state"))
	# Transit (M4.3b's readouts in the 3D ship): committed, until arrival.
	if live_journey and black_hole == null:
		if not ship_hud.has_card("transit"):
			ship_hud.show_card("transit", "Transit")
			for r in JourneyHud.ROWS:
				if r[1] in ShipHud.TRANSIT_COMPACT:
					# The 3D ship's warp is the live pacing rate (shown only; no warp control, D-57 Q3).
					ship_hud.card_line("transit", r[0], r[1], "sci ship-yr/real-s" if r[1] == "client.warp" else r[2])
	else:
		ship_hud.hide_card("transit")
	# Brake and final-approach notices (D-46, D-49).
	if phase != _hud_phase:
		if phase == "braking":
			ship_hud.show_card("notice", "Braking", 8.0)
			_notice_text(JourneyHud.BRAKE_NOTICE)
		elif phase == "approaching":
			ship_hud.show_card("notice", "Final approach", 8.0)
			_notice_text("Final approach to %s" % (solar_tour.leg_name() if solar_tour != null else stop_name()))
	# Arrival: the M4.3a arrival card; dismissed (Enter, Esc, click) or by the next commit.
	if state == "arrived" and _hud_state == "committed":
		ship_hud.hide_card("arrival")
		ship_hud.show_card("arrival", "Arrived")
		var body := ship_hud.card_body("arrival")
		if body.get_child_count() == 0:
			for r in ArrivalCard.ROWS: ship_hud.card_line("arrival", r[0], r[1], r[2])
			ship_hud.card_button("arrival", "Dismiss [Enter]", dismiss_arrival)
	elif state == "committed":
		ship_hud.hide_card("arrival")
	_hud_phase = phase
	_hud_state = state
	# Gravity (mockup C): the Sgr A* session's sim lines.
	if black_hole != null:
		if not ship_hud.has_card("gravity"):
			ship_hud.show_card("gravity", "Gravity · Sgr A*")
			for i in BlackHoleVisit.hud_lines(black_hole.gr()).size():
				var b := DisplayBinding.new().bind("hud.gravity.%d" % i, "text")
				b.add_theme_font_size_override("font_size", 12);b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				b.custom_minimum_size.x = ship_hud.card_width() - 20.0
				ship_hud.card_body("gravity").add_child(b)
			ship_hud._bindings_dirty = true
	else:
		ship_hud.hide_card("gravity")
	# Tour: leg, stage, dwell left, PAUSED, and the instant pacing buttons (D-57 Q3).
	if solar_tour != null:
		if not ship_hud.has_card("tour"):
			ship_hud.show_card("tour", "Guided voyage")
			ship_hud.card_text("tour", "tour", "")
			ship_hud.card_button("tour", "Pause [P]", toggle_tour_pause).name = "Pause"
			ship_hud.card_button("tour", "Skip dwell", skip_dwell).name = "SkipDwell"
			ship_hud.card_button("tour", "Skip stage [K]", skip_stage).name = "SkipStage"
		ship_hud.set_card_value("tour", tour_line())
		var row: Node = ship_hud.card_body("tour").get_node_or_null("Buttons")
		if row != null:
			(row.get_node("Pause") as Button).text = "Resume [P]" if solar_tour.paused else "Pause [P]"
			(row.get_node("SkipDwell") as Button).disabled = live_journey or solar_tour.complete or solar_tour.attitude_hold or solar_tour.pending_index >= 0
			(row.get_node("SkipStage") as Button).disabled = not live_journey or solar_tour.paused or solar_tour.attitude_hold
	else:
		ship_hud.hide_card("tour")
	if interlude_card != null and interlude_card.visible:
		if not ship_hud.has_card("interlude"):
			ship_hud.show_card("interlude", "Cruise interlude")
			ship_hud.card_button("interlude", "Continue [Enter]", continue_interlude)
	else:
		ship_hud.hide_card("interlude")
	# Archive unlocks (the codex's toast, moved into the stack).
	var u: Variant = GalaxyMap.field_value(view, "consequence.archive.unlocked")
	if u is Array and u.size() > _unlocked_seen.size():
		var titles := PackedStringArray()
		_ensure_codex()
		for id in u:
			if not _unlocked_seen.has(id): titles.append(codex._title_of(id))
		_unlocked_seen = u.duplicate()
		ship_hud.show_card("unlock", "New in the Archive", 10.0)
		if ship_hud.card_body("unlock").get_child_count() == 0: ship_hud.card_text("unlock", "unlock", "")
		ship_hud.set_card_value("unlock", "%s, at the Archive terminal" % ", ".join(titles))
## The D-41 interlude card keeps its content; it sits in the space left of the card column
## so the stack (tour, transit) stays readable beside it.
func _place_interlude() -> void:
	if interlude_card == null or not interlude_card.visible: return
	var left: float = ship_hud.column.position.x - ShipHud.MARGIN
	interlude_card.custom_minimum_size.x = minf(620.0, left - 2.0 * ShipHud.MARGIN)
	interlude_card.reset_size()
	interlude_card.position = Vector2(maxf(ShipHud.MARGIN, (left - interlude_card.size.x) * 0.5), maxf(ship_hud.strip_bottom() + 8.0, (ship_hud.size.y - interlude_card.size.y) * 0.5))
func _notice_text(text: String) -> void:
	if ship_hud.card_body("notice").get_child_count() == 0: ship_hud.card_text("notice", "notice", "")
	ship_hud.set_card_value("notice", text)
## The tour card's line: leg, stage, dwell left, PAUSED.
func tour_line() -> String:
	var ship: Dictionary = sky_world.get("ship", {}) if sky_world is Dictionary else {}
	var stage: String = "cruise interlude" if solar_tour.interlude != null else str(PHASE_WORDS.get(str(ship.get("phase", "")), "")).to_lower()
	var parts := PackedStringArray()
	if solar_tour.pending_index >= 0 or solar_tour.attitude_hold: parts.append("turning to " + solar_tour.pending_name if solar_tour.pending_index >= 0 else "attitude turn")
	elif live_journey: parts.append("→ %s · %s" % [solar_tour.leg_name(), stage])
	elif solar_tour.complete: parts.append("At %s · voyage complete" % solar_tour.leg_name())
	else: parts.append("At %s · next stop in %.0f s" % [solar_tour.leg_name(), solar_tour.dwell_left])
	if solar_tour.leg_index >= 0: parts.append("Leg %d of %d" % [solar_tour.leg_index + 1, solar_tour.itinerary.size()])
	if solar_tour.skips > 0: parts.append("skipped %d stage%s" % [solar_tour.skips, "" if solar_tour.skips == 1 else "s"])
	if solar_tour.paused: parts.append("PAUSED")
	return " · ".join(parts)
func refuse(text: String) -> void:
	caption = text
	if ship_hud == null: return
	ship_hud.show_card("refusal", "Not now", 8.0)
	if ship_hud.card_body("refusal").get_child_count() == 0: ship_hud.card_text("refusal", "refusal", "")
	ship_hud.set_card_value("refusal", text)
func note(text: String) -> void:
	caption = text
	if ship_hud == null: return
	ship_hud.show_card("notice", "Ship's log", 8.0)
	_notice_text(text)
func dismiss_arrival() -> void:
	ship_hud.hide_card("arrival")
## P and the tour card: pause or resume the guided voyage (pacing; D-57 Q3).
func toggle_tour_pause() -> void:
	if solar_tour != null: solar_tour.paused = not solar_tour.paused
## The tour card's Skip dwell: the itinerary's own next leg comes forward (pacing).
func skip_dwell() -> bool:
	if solar_tour == null or live_journey or not solar_tour.prepare_next(): return false
	_apply_journey_world()
	return true
func toggle_confirm_mode() -> void:
	confirm_mode = "twice" if confirm_mode == "hold" else "hold"
	confirm_button.text = "Confirm decisions: " + ("press twice" if confirm_mode == "twice" else "hold")
	if menu_return:
		var gs := GameSettings.new(); gs.dir = settings_dir; gs.load_settings(); gs.confirm_mode = confirm_mode; gs.save_settings()
## Tab "Walk to": walk to a station along the walk mesh (3.5 m/s; WASD takes over).
func walk_to(station: String) -> bool:
	return consoles.walk_to(station)
## The bridge consoles (R1-SHIP-UI U3): stations from ship.glb, use points, prompt, panels.
func _consoles_setup() -> void:
	consoles = ShipConsoles.new(); add_child(consoles); consoles.setup(self)
	consoles.used.connect(func(_s:String,_a:String)->void:ship_hud.hint.visible=false)
## The dwell label (§A3): when the view rests 0.5 s, name the star or body at the screen
## centre (the I card's own pick, read only) with its distance and "I · details".
func _update_dwell(delta: float) -> void:
	# Not at Sgr A*: its stars are the Sol sky lensed (design OQ5), so a name and distance mislead.
	if not dwell_on or black_hole!=null or camera_mode!="player" or star_identification==null or star_identification.held or star_identification.suppressed or sky_only or star_identification.card.visible or (interlude_card!=null and interlude_card.visible):
		_dwell_done=false;ship_hud.set_dwell("",Vector2.ZERO);return
	var pose:Transform3D=camera.global_transform
	if not pose.is_equal_approx(_dwell_pose):
		_dwell_pose=pose;_dwell_still=0.;_dwell_done=false;ship_hud.set_dwell("",Vector2.ZERO);return
	_dwell_still+=delta
	if _dwell_still>=.5 and not _dwell_done:
		_dwell_done=true
		var centre:=ship_hud.size*.5
		ship_hud.set_dwell(dwell_text_at(centre),centre)
func dwell_text_at(point: Vector2) -> String:
	# Named stars and resolved bodies only: an unnamed catalogue row is the I card's job.
	var hits:Array=star_identification.probe(point).filter(func(h:Dictionary)->bool:return h.has("body") or star_identification.info.names.has(h.id))
	if hits.is_empty():return ""
	var c:Dictionary=hits[0]
	if c.has("body"):return "%s · %s · I details" % [str(c.body.get("name",c.body.get("id",""))),BodyInfo.distance_text(float(c.distance_km))]
	var row:Dictionary=star_identification.info.records.get(c.id,{})
	var pos:Dictionary=sky_world.get("ship",{}).get("pos",{}) if sky_world is Dictionary else {}
	var d:=""
	if row.has("x") and not pos.is_empty():
		d=" · "+distance_text(sqrt(pow(float(row.x)-float(pos.x),2.)+pow(float(row.y)-float(pos.y),2.)+pow(float(row.z)-float(pos.z),2.)))
	return star_identification.info.display_name(c.id)+d+" · I details"

## Speed from the sim's exact fields: beta with as many nines as 1 - beta needs, gamma, km/s.
static func speed_text(ship: Dictionary) -> String:
	var beta: float = float(ship.get("beta", 0.0))
	if beta <= 0.0: return "At rest"
	# The sim emits one_minus_beta in every phase (R1-SHIP-UI AC2); never computed here.
	if not ship.has("one_minus_beta"): return "β %s c" % str(beta)
	var omb: float = float(ship.one_minus_beta)
	var n := -log(maxf(omb, 1e-15)) / log(10.0)
	var digits := clampi(int(round(n)) if absf(n - round(n)) < 1e-9 else int(ceil(n)), 4, 15)
	var km_s := String.num_int64(int(round(beta * 299792.458)))
	var grouped := ""
	for i in km_s.length():
		if i > 0 and (km_s.length() - i) % 3 == 0: grouped += ","
		grouped += km_s[i]
	return ("%." + str(digits) + "fc · γ %s · %s km/s") % [beta, ("%.2f" % float(ship.get("gamma", 1.0))) if float(ship.get("gamma", 1.0)) < 1000.0 else "%.0f" % float(ship.get("gamma", 1.0)), grouped]

## Distances (Mark, 2026-10-06): to the destination (the sim's distance_remaining), from
## the last stop where the leg was committed (plan.departure), and from Earth (the
## system section's Earth, else Sol). Only vector lengths of sim positions, in float64.
## Stopped after a leg (Mark, 2026-10-08: free navigation showed only "from Earth"): at
## the plan's target (the system body standing for it, else its catalogue position), from
## the stop the leg left (when that is not Earth) and from Earth. `names` maps catalogue
## ids to display names; `from_name` names the free-navigation departure ("" = last stop).
static func distances_text(world: Dictionary, tour, names: Dictionary = {}, from_name: String = "") -> String:
	var parts := PackedStringArray()
	var journey: Dictionary = world.get("journey", {})
	var ship: Dictionary = world.get("ship", {})
	var plan: Dictionary = journey.get("plan", {}) if journey.get("plan") is Dictionary else {}
	var state: String = journey.get("state", "")
	var target: Dictionary = plan.get("target", {}) if plan.get("target") is Dictionary else {}
	var target_id: String = str(target.get("id", "destination"))
	var target_name: String = tour.leg_name() if tour != null and tour.leg_index >= 0 else str(names.get(target_id, target_id))
	var pos: Dictionary = ship.get("pos", {})
	var dep: Dictionary = plan.get("departure", {}) if plan.get("departure") is Dictionary else {}
	var dep_name: String = from_name if not from_name.is_empty() else "last stop"
	if tour != null: dep_name = "Earth" if tour.leg_index <= 0 else str(tour.itinerary[tour.leg_index - 1].get("name", "last stop"))
	var from_dep := -1.0
	if not dep.is_empty() and not pos.is_empty():
		from_dep = sqrt(pow(float(pos.x) - float(dep.x), 2.0) + pow(float(pos.y) - float(dep.y), 2.0) + pow(float(pos.z) - float(dep.z), 2.0))
	if state == "committed":
		parts.append("To %s %s" % [target_name, distance_text(float(world.get("consequence", {}).get("distance_remaining", 0.0)))])
		if from_dep >= 0.0: parts.append("from %s %s" % [dep_name, distance_text(from_dep)])
	elif state == "arrived" and not target.is_empty():
		var at_ly := -1.0
		# A body plan (D-54 stop at a finite star, Earth for Sol, an in-system body) names
		# the body it holds beside (plan.hold.body).
		var hold_id: String = str(plan.get("hold", {}).get("body", "")) if plan.get("hold") is Dictionary else ""
		for b: Dictionary in world.get("system", {}).get("bodies", []):
			if (not hold_id.is_empty() and b.get("id", "") == hold_id) or (hold_id.is_empty() and (b.get("id", "") == target_id or (not str(b.get("catalogue_id", "")).is_empty() and str(b.get("catalogue_id", "")) == target_id))):
				at_ly = Planets.length64(Planets.world_of(b.rel_km)) / 9460730472580.8
				if tour == null and not names.has(target_id): target_name = body_name(b, names)
				break
		var tp = target.get("pos")
		if at_ly < 0.0 and tp is Dictionary and not pos.is_empty():
			at_ly = sqrt(pow(float(pos.x) - float(tp.x), 2.0) + pow(float(pos.y) - float(tp.y), 2.0) + pow(float(pos.z) - float(tp.z), 2.0))
		parts.append("At %s %s" % [target_name, distance_text(at_ly)] if at_ly >= 0.0 else "At %s" % target_name)
		if from_dep >= 0.0 and dep_name != "Earth": parts.append("from %s %s" % [dep_name, distance_text(from_dep)])
	var earth_ly := -1.0
	for b: Dictionary in world.get("system", {}).get("bodies", []):
		if b.get("id", "") == "earth": earth_ly = Planets.length64(Planets.world_of(b.rel_km)) / 9460730472580.8
	if earth_ly < 0.0 and not pos.is_empty(): earth_ly = sqrt(pow(float(pos.x), 2.0) + pow(float(pos.y), 2.0) + pow(float(pos.z), 2.0))
	var at_earth: bool = state == "arrived" and plan.get("hold") is Dictionary and str(plan.hold.get("body", "")) == "earth"
	var from_earth_shown: bool = state == "committed" and from_dep >= 0.0 and dep_name == "Earth"
	if earth_ly >= 0.0 and not at_earth and not from_earth_shown: parts.append("from Earth %s" % distance_text(earth_ly))
	return " · ".join(parts)

## A finite body's display name: the catalogue name of the star it is ("Alpha Centauri B"),
## else the sim's name.
static func body_name(b: Dictionary, names: Dictionary) -> String:
	return str(names.get(str(b.get("catalogue_id", "")), b.get("name", b.get("id", ""))))

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
	return ShipHud.duration_text(years)

func journey_label() -> String:
	if black_hole!=null:return "SGR A* DEMO · stop %d of %d · %s" % [black_hole.stops_taken,BlackHoleVisit.STOPS.size(),"next: "+black_hole.next_label() if not black_hole.next_label().is_empty() else "last stop"]
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
		open_chart()
		ok=not solar_tour.paused and journey_map.mode=="chart" and journey_map.guided_read_only and not journey_map.open_commit_dialog() and ok
		close_navigation()
		for tick in 20:ok=journey_tick() and ok
		ok=sky.system_view.drawn_points.has("saturn") and sky_world.ship.phase=="boosting" and sky_world.clock.tau>before.clock.tau and ok
		for frame in 12:await get_tree().process_frame
	print("solar-departure-smoke: %s" %("OK" if ok else "FAIL"))
	var tree:=get_tree()
	solar_tour=null
	tree.create_timer(.1).timeout.connect(tree.quit.bind(0 if ok else 1),CONNECT_ONE_SHOT)
	queue_free()

# ------------------------------------------------------------ M3.6: Sgr A* aboard the ship
## "GR on" with the sim's radius, or "GR off": the details line and the benchmark report.
func gr_status() -> String:
	if black_hole != null and sky.gr_lens != null and sky.gr_lens.active:
		return "GR on: Schwarzschild sky from the sim's gr section (r = %s r_s) · exposure fixed (manual; an auto meter would not see the shadow)" % BlackHoleVisit.r_text(float(sky.gr_lens.state.r))
	return "GR off (flat space; GR in the Sgr A* demo)"
## The navigation entry, the HUD button and --scenario=sgr_a: a new sgr_a session replaces the
## normal navigation session (refused while a committed journey is under way).
func start_black_hole() -> bool:
	if benchmark.running:return false
	if black_hole != null:return true
	if live_journey or (journey_sim!=null and journey_sim.world.get("journey",{}).get("state","")=="committed"):
		refuse("Finish the committed journey before visiting Sgr A*.");return false
	_drop_navigation()
	var v:=BlackHoleVisit.new()
	if not v.start(LoreLoader.archive_rows(LoreLoader.load_entries()["entries"])):
		refuse("Sgr A* unavailable: "+v.last_error);return false
	black_hole=v;_bh_accum=0.
	_ensure_codex()
	sky_state="black_hole"
	_apply_bh_world();look_direction("forward")
	_reset_hud_session()
	note("Sgr A*, 10⁶ r_s out (1.34 ly). The next stop is an approach to 10 r_s at β 0.1.")
	return true
## The sim's world on the sky. The ship holds its nose on the hole (client attitude, like the
## guided tour's turns), so look forward / side / aft are toward, across and away from it.
func _apply_bh_world() -> void:
	var g:Dictionary=black_hole.gr()
	sky_world=black_hole.sim.world.duplicate(true)
	var h:Dictionary=g.hole_dir
	sky_world.ship.heading={"x":h.x,"y":h.y,"z":h.z}
	camera.heading=PackedFloat64Array([h.x,h.y,h.z])
	sky.apply(sky_world);_sync_observer()
	if codex!=null:codex.show_world(sky_world)
## One live tick of the visit; the first ring star (the sky's ring path) is reported to the sim.
func bh_tick() -> bool:
	if black_hole==null:return false
	if sky.gr_lens!=null and sky.gr_lens.active and not sky.gr_lens.ring.is_empty():black_hole.report_ring()
	var was:bool=black_hole.approaching()
	if not black_hole.step():
		refuse("Sgr A* step failed: "+black_hole.last_error);return false
	if was and not black_hole.approaching():_arrived()
	_apply_bh_world()
	return true
func bh_next_stop() -> bool:
	if black_hole==null:return false
	var label:String=black_hole.next_label()
	if not black_hole.next_stop():
		refuse("Approach under way (K finishes it)." if black_hole.approaching() else ("Last stop reached; leave Sgr A* when ready." if label.is_empty() else "Refused by the sim: "+black_hole.last_error))
		return false
	note(label+".")
	_apply_bh_world()
	return true
func bh_finish_approach() -> bool:
	if black_hole==null or not black_hole.finish_approach():return false
	_arrived()
	_apply_bh_world()
	return true
func _arrived() -> void:
	note("Arrived: hovering at r = %s r_s. Next: %s." % [BlackHoleVisit.r_text(float(black_hole.gr().r)),black_hole.next_label() if not black_hole.next_label().is_empty() else "last stop reached"])
## Back to Sol at rest: the sgr_a session ends and the sky is flat again (GR off).
func leave_black_hole() -> void:
	if black_hole==null:return
	black_hole.stop();black_hole=null
	if codex!=null:codex.close()
	sky_state="rest";set_sky_state("rest")
	note("Back at Sol (rest snapshot).")
func _ensure_codex() -> void:
	if codex!=null:return
	var layer:=CanvasLayer.new();layer.layer=13;add_child(layer)
	codex=load("res://ui/archive/codex.tscn").instantiate();layer.add_child(codex)
	codex.load_lore()
	codex.toast_box.visible=false # R1-SHIP-UI: unlocks are announced in the HUD's card stack
## C: the Archive codex (what the sim has unlocked this session).
func toggle_codex() -> void:
	_ensure_codex()
	if codex.panel.visible:codex.close()
	else:codex.open()
