extends SceneTree
## GPU source-centroid audit through the actual integrated overlay and native input.
const Camera = preload("res://demos/ship_demo_camera.gd")
const Projector = preload("res://sky/star_projection.gd")
const OUT := "res://renders/ship_identification"
var failures := 0
var rows: Array = []
var demo: Node
var overlay: Control
func _initialize() -> void:_run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:failures+=1;push_error(message)
func grab(view: Viewport) -> Image:
	for frame in 4:await process_frame
	await RenderingServer.frame_post_draw
	return view.get_texture().get_image()
func centroid(image: Image, point: Vector2) -> Vector2:
	var peak:=0.;var sum:=Vector2.ZERO;var weight:=0.
	for y in range(maxi(0,int(point.y)-10),mini(image.get_height(),int(point.y)+11)):
		for x in range(maxi(0,int(point.x)-10),mini(image.get_width(),int(point.x)+11)):
			peak=maxf(peak,image.get_pixel(x,y).get_luminance())
	for y in range(maxi(0,int(point.y)-10),mini(image.get_height(),int(point.y)+11)):
		for x in range(maxi(0,int(point.x)-10),mini(image.get_width(),int(point.x)+11)):
			var l:=image.get_pixel(x,y).get_luminance()
			if l>=peak*.5:sum+=Vector2(x+.5,y+.5)*l;weight+=l
	return sum/weight if weight>0. and peak>.02 else Vector2(-10000,-10000)
func key(pressed: bool) -> void:
	var event:=InputEventKey.new();event.physical_keycode=KEY_I;event.pressed=pressed
	Input.parse_input_event(event)
func physical_click(pixel: Vector2) -> void:
	var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=true;event.position=pixel;event.global_position=pixel
	root.push_input(event,false)
	await process_frame
	event.pressed=false;root.push_input(event,false);await process_frame
func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	root.size=Vector2i(1920,1080)
	demo=load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options={stars=false,background=false,sky_state="rest"}
	root.add_child(demo);await process_frame
	check(demo.ready_ok,"integrated demo ready")
	demo.auto=false;demo.journey_auto_tick=false;demo.set_process(false)
	overlay=demo.star_identification;overlay.set_process(false)
	overlay.info.set_records([{id="audit",teff=5700.,dist_ly=1000.,vmag=0.}])
	var saved_visibility := {}
	for child in demo.geometry.get_children():
		if child is Node3D:saved_visibility[child]=child.visible;child.visible=false
	demo.sky.env.glow_enabled=false
	var field: Starfield=demo.sky.starfield
	var worst:=0.
	for px in [Vector2i(1920,1080),Vector2i(1280,800),Vector2i(900,600)]:
		root.size=px;demo.geometry_view.size=px;await process_frame
		for pose in [[18.,.4,0.,78.],[-22.,1.2,.3,55.]]:
			demo.camera.follow(Vector3(8,82,-4.8),pose[0],pose[1],0.)
			demo.camera.basis=demo.camera.basis.rotated(-demo.camera.basis.z,pose[2]);demo.camera.fov=pose[3];demo._sync_observer()
			for target in [Vector2(.5,.5),Vector2(.22,.26),Vector2(.78,.72)]:
				var ray: Vector3=demo.camera.project_ray_normal(target*Vector2(px))
				var apparent:=Camera.to_sky_direction(ray,demo.camera.heading).normalized()
				for boost in [[0.,Vector3.UP],[.99,apparent],[.99,demo.sky.camera.screen_right()],[.99,-apparent],[.9999,demo.sky.camera.screen_right()]]:
					var beta: float=boost[0];var velocity: Vector3=boost[1]
					var rest:=Relativity.deaberrate(apparent,velocity,beta)
					var doppler:=Relativity.doppler(rest,velocity,beta)
					for rebasing in ["far","near_gpu","near_cpu"]:
						var near: bool=rebasing!="far"
						var eye:=PackedFloat64Array([100000.,-90000.,80000.]) if near else PackedFloat64Array([0.,0.,0.])
						var distance:=.001 if near else 1000.
						var pos:=PackedFloat64Array([eye[0]+rest.x*distance,eye[1]+rest.y*distance,eye[2]+rest.z*distance])
						var p2:=pos[0]*pos[0]+pos[1]*pos[1]+pos[2]*pos[2]
						var t:=5700./doppler
						var flux:=distance*distance/p2/Relativity.point_flux_ratio(t,doppler)
						field.set_custom_stars([{id="audit",pos=pos,t=t,flux=flux}]);field.set_ship_position(eye[0],eye[1],eye[2])
						field.set_rebase_mode(Starfield.Rebase.CPU if rebasing=="near_cpu" else Starfield.Rebase.GPU)
						field.set_velocity(velocity,beta,Relativity.gamma_of(beta));field.set_exposure(1.);field.set_floor(Vector2.ZERO)
						overlay.set_held(true);overlay.update_candidates()
						check(overlay.candidates.size()==1,"resolvable GPU audit source eligible")
						if overlay.candidates.is_empty():continue
						var candidate: Dictionary=overlay.candidates[0]
						var star:=centroid(await grab(demo.sky),candidate.pixel)
						var error:=star.distance_to(candidate.pixel);worst=maxf(worst,error)
						var transform:=overlay.get_viewport().get_stretch_transform()*overlay.get_global_transform_with_canvas()
						var draw_error: float=(transform*candidate.point).distance_to(candidate.pixel)
						check(error<=1. and draw_error<.01,"actual GPU source and native ring centre <=1pixel")
						rows.append({size=[px.x,px.y],pose=pose,target=[target.x,target.y],beta=beta,near_rebase=near,rebase_mode=field.rebase_mode,star_px=[star.x,star.y],ring_px=[candidate.pixel.x,candidate.pixel.y],error_px=error,draw_error_px=draw_error})
	# Physical native viewport input, not direct overlay handler calls.
	root.size=Vector2i(900,600);demo.geometry_view.size=root.size;demo.camera.fov=78.
	demo.camera.follow(Vector3(8,82,-4.8),20.,.4,0.);demo._sync_observer();await process_frame
	var ray: Vector3=-demo.camera.basis.z
	field.set_custom_stars([{id="audit",pos=Camera.to_sky_direction(ray,demo.camera.heading)*1000.,t=5700.,flux=1.}]);field.set_ship_position(0,0,0);field.set_rebase_mode(Starfield.Rebase.GPU);field.set_velocity(Vector3.UP,0.,1.);field.set_exposure(1.)
	key(true);await process_frame;overlay.update_candidates()
	var centre:=Vector2(root.size)*.5
	var source:=centroid(await grab(demo.sky),centre)
	var negative:=source.distance_to(centre+Vector2(4,0));check(negative>1.,"intentional 4pixel offset is detected")
	await physical_click(centre)
	check(overlay.selected_id=="audit" and overlay.card.visible,"native900x600 heldI leftclick opens exact card")
	key(false);await process_frame;check(not overlay.held and overlay.card.visible,"native release keeps card")
	(await grab(root)).save_png(OUT+"/native_900_card.png")
	overlay.close_card();key(true);await process_frame
	var blocker:=MeshInstance3D.new();var box:=BoxMesh.new();box.size=Vector3(3,3,.2);blocker.mesh=box
	var black:=StandardMaterial3D.new();black.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;black.albedo_color=Color.BLACK;blocker.material_override=black
	demo.geometry.add_child(blocker);blocker.position=demo.camera.position+ray*10.;blocker.basis=demo.camera.basis
	overlay.occlusion.build(demo.geometry);overlay.update_candidates()
	check(overlay.candidates.is_empty(),"noncollision opaque visual hides ring")
	var covered:=await grab(root);check(covered.get_pixelv(Vector2i(centre)).get_luminance()<.01,"actual composite opaque patch hides GPU source")
	await physical_click(centre);check(not overlay.card.visible,"covered star cannot be clicked")
	covered.save_png(OUT+"/opaque_mesh.png");blocker.queue_free();await process_frame
	# Actual captain billboard: opaque torso occludes; texture padding does not.
	demo.camera.follow(demo.avatar_pos,-18.,.47,3.);demo._sync_observer()
	demo.avatar.visible=true
	var avatar: Sprite3D=demo.avatar
	var avatar_image:=avatar.texture.get_image()
	var opaque:=Vector2(avatar_image.get_width()*.5,avatar_image.get_height()*.6)
	var nearest:=INF
	for y in range(0,avatar_image.get_height(),8):
		for x in range(0,avatar_image.get_width(),8):
			if avatar_image.get_pixel(x,y).a>.999:
				var distance:=Vector2(x,y).distance_to(Vector2(avatar_image.get_width()*.5,avatar_image.get_height()*.6))
				if distance<nearest:nearest=distance;opaque=Vector2(x,y)
	check(nearest<100.,"actual captain has an opaque torso texture sample")
	for sample in [{pixel=opaque,opaque=true},{pixel=Vector2(8,8),opaque=false}]:
		var rectangle:=avatar.get_item_rect()
		var local:=Vector3(rectangle.position.x+sample.pixel.x,rectangle.position.y+rectangle.size.y-sample.pixel.y,0.)*avatar.pixel_size
		var point: Vector3=avatar.global_position+demo.camera.global_basis*local
		var direction: Vector3=(point-demo.camera.global_position).normalized()
		var world_direction:=Camera.to_sky_direction(direction,demo.camera.heading)
		field.set_custom_stars([{id="audit",pos=world_direction*1000.,t=5700.,flux=1.}]);field.set_velocity(Vector3.UP,0.,1.);field.set_exposure(1.)
		overlay.occlusion.build(demo.geometry);overlay.update_candidates()
		var screen: Vector2=demo.camera.unproject_position(point)
		var finite:=await grab(demo.geometry_view)
		var alpha:=finite.get_pixelv(Vector2i(screen)).a
		check((alpha>.95 if sample.opaque else alpha<.01),"actual GPU captain mask matches authored body/padding")
		check(overlay.candidates.is_empty() if sample.opaque else overlay.candidates.size()==1,"captain GPU mask and identification eligibility agree")
		await physical_click(screen)
		check(not overlay.card.visible if sample.opaque else overlay.card.visible,"native captain body/padding click behavior")
		if overlay.card.visible:overlay.close_card()
		(await grab(root)).save_png(OUT+("/captain_body.png" if sample.opaque else "/captain_padding.png"))
		rows.append({captain_mask="body" if sample.opaque else "transparent_padding",gpu_alpha=alpha,ring_count=overlay.candidates.size(),screen_px=[screen.x,screen.y]})
	demo.avatar.visible=false
	# A real binary row rendered in isolation, preserving its exact ID and packed data.
	field.load_tiers("medium");field.build();field.set_ship_position(0.,0.,0.);field.set_velocity(Vector3.UP,0.,1.);field.set_exposure(1e10)
	overlay.info.load_files()
	var real_index:=field.ids.find("CNS5:1676")
	check(real_index>=0,"real Sirius A row in active filtered stack")
	if real_index>=0:
		var real_pos:=PackedFloat64Array([field.pos[real_index*3],field.pos[real_index*3+1],field.pos[real_index*3+2]])
		var real_t:=field.custom[real_index*4];var real_flux:=field.custom[real_index*4+1];var real_flags:=field.custom[real_index*4+2]
		field.set_custom_stars([{id="CNS5:1676",pos=real_pos,t=real_t,flux=real_flux,flags=real_flags}])
		var gal:=SkyFrame.to_galactic64(real_pos)
		var ship:=ShipFrame.to_ship(ShipFrame.ship_basis(demo.camera.heading),gal)
		var direction:=Vector3(ship[0],ship[2],-ship[1]).normalized()
		demo.camera.basis=Basis.looking_at(direction,Vector3.UP);demo._sync_observer();overlay.update_candidates()
		check(overlay.candidates.size()==1,"exact real row eligible")
		if overlay.candidates.size()==1:
			var candidate: Dictionary=overlay.candidates[0];var pixel:=centroid(await grab(demo.sky),candidate.pixel)
			var error:=pixel.distance_to(candidate.pixel);worst=maxf(worst,error);check(error<=1.,"real binary Sirius GPU centroid alignment")
			rows.append({real_id=candidate.id,error_px=error,star_px=[pixel.x,pixel.y]})
	# Physical ship review screenshots: current catalogue and opaque ship intact.
	for child in saved_visibility:child.visible=saved_visibility[child]
	overlay.occlusion.build(demo.geometry);field.load_tiers("medium");field.build()
	for state in ["rest","cruise"]:
		root.size=Vector2i(1280,800);demo.geometry_view.size=root.size;demo.set_preset("bridge");demo.set_sky_state(state);demo.look_direction("forward");demo.set_brightness_trial(2);await process_frame
		overlay.close_card();key(true);overlay.update_candidates()
		check(not overlay.candidates.is_empty(),"real ship view contains eligible unobstructed sources")
		(await grab(root)).save_png(OUT+"/"+state+"_identify.png")
		if state=="rest" and not overlay.candidates.is_empty():
			var pick: Dictionary=overlay.candidates[0]
			for candidate in overlay.candidates:
				if candidate.id=="CNS5:3627":pick=candidate;break
				if overlay.at_point(candidate.point).size()==1:
					pick=candidate
					if overlay.info.names.has(candidate.id):break
			await physical_click(pick.pixel)
			if overlay.selected_id.is_empty():
				# Dense native hits deliberately open a list; choose its exact-ID row.
				var list: VBoxContainer=overlay.content.get_child(1).get_child(0)
				for button in list.get_children():
					if button.text.ends_with(pick.id):
						var transform:=overlay.get_viewport().get_stretch_transform()
						await physical_click(transform*button.get_global_rect().get_center());break
			check(overlay.card.visible,"real ship physical click opens catalogue card")
			(await grab(root)).save_png(OUT+"/bridge_identify.png")
			if overlay.card.visible:
				var id: String=overlay.selected_id;overlay.open_map.emit(id)
				check(demo.journey_map!=null and demo.journey_map.catalogue[demo.journey_map.selected_index].id==id,"exact ID opens existing map without commitment")
				check(not demo.live_journey,"map handoff does not commit")
				demo.close_navigation()
	# One real committed voyage: inspect while clocks progress through all legs.
	demo.open_navigation()
	if demo.journey_map != null:
		demo.journey_map.preselect(demo.journey_map.index_of("CNS5:3627"));demo.journey_tick()
		check(demo.journey_map.open_commit_dialog() and demo.journey_map.hold_commit(GalaxyMap.HOLD_S) and demo.journey_tick(),"existing explicit map hold commits the audit voyage")
		var seen := {}
		var counts := {}
		for tick in 1220:
			var phase: String=demo.sky_world.ship.phase
			counts[phase]=counts.get(phase,0)+1
			if phase in ["boosting","cruising","braking"] and counts[phase]==80:
				demo.look_direction("forward");demo.sky.update_exposure();overlay.set_held(true);overlay.update_candidates()
				var before: Dictionary=demo.sky_world.duplicate(true)
				check(not overlay.candidates.is_empty(),"live phase has visible known candidates")
				if not overlay.candidates.is_empty():
					var candidate: Dictionary=overlay.candidates[0];var k: int=candidate.index
					overlay.inspect(candidate.id)
					(await grab(root)).save_png(OUT+"/live_"+phase+".png")
					check(demo.sky_world==before,"card inspection leaves actual live state unchanged")
					var position:=PackedFloat64Array([field.pos[k*3],field.pos[k*3+1],field.pos[k*3+2]])
					var t:=field.custom[k*4];var flux:=field.custom[k*4+1]
					field.set_custom_stars([{id=candidate.id,pos=position,t=t,flux=flux}])
					field.set_exposure(1e10) # labelled centroid-only diagnostic to resolve the actual catalogue row
					for child in saved_visibility:child.visible=false
					overlay.update_candidates()
					if overlay.candidates.size()==1:
						var isolated: Dictionary=overlay.candidates[0]
						var star:=centroid(await grab(demo.sky),isolated.pixel)
						var error:=star.distance_to(isolated.pixel);worst=maxf(worst,error);check(error<=1.,"actual simulation "+phase+" GPU centroid aligned")
						rows.append({live_phase=phase,world=before,exact_id=candidate.id,error_px=error,alignment_diagnostic="Isolated real row, exposure increased only for centroid measurement"});seen[phase]=true
					for child in saved_visibility:child.visible=saved_visibility[child]
					field.load_tiers("medium");field.build();demo.sky.apply(demo.sky_world);demo._sync_observer();demo.sky.update_exposure()
			if not demo.live_journey:break
			var previous_tau: float=demo.sky_world.clock.tau
			check(demo.journey_tick(),"actual live simulation tick")
			check(demo.sky_world.clock.tau>=previous_tau,"inspection does not pause voyage clocks")
		check(seen.size()==3,"actual boosting/cruising/braking states all audited")
		demo.close_navigation()
	key(false)
	var output:=FileAccess.open(OUT+"/capture-manifest.json",FileAccess.WRITE)
	output.store_string(JSON.stringify({cases=rows,worst_px=worst,limit_px=1.,negative_offset_px=negative,failures=failures,scope="Actual GPU starfield centroids; native physical viewport input; noncollider opaque composite; real binary Sirius row; production plate integration deferred"},"  "));output.close()
	print("ship-star-identification-capture: %d cases, worst %.4f px, %d failures" % [rows.size(),worst,failures])
	demo.queue_free();await process_frame;quit(1 if failures else 0)
