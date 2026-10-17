extends RefCounted
## Uses the real ship/compositor; synthetic golden stars never alter catalogue assets.
const Guide = preload("res://ui/constellation_overlay.gd")
const Camera = preload("res://demos/ship_demo_camera.gd")
const OUT := "res://renders/constellations"
var host: Node
var tree: SceneTree
var demo: Node
var guide: Control
var failures := 0
var rows: Array=[]
var output_view: Viewport
var capture_view: SubViewport

func check(ok: bool, message: String) -> void:
	if not ok:failures+=1;push_error("constellation: "+message)
func grab(view: Viewport) -> Image:
	for frame in 3:await tree.process_frame
	await RenderingServer.frame_post_draw
	return view.get_texture().get_image()
func run(owner: Node, mode := "golden") -> int:
	host=owner;tree=host.get_tree()
	output_view=tree.root
	var old_size := tree.root.size
	tree.root.size=Vector2i(960,540) if mode=="golden" else Vector2i(1920,1080)
	demo=load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options={stars=mode!="golden",background=mode!="golden",sky_state="rest",size=tree.root.size}
	if mode in ["capture","golden"]:
		# Native macOS windows clamp tall sizes. Render exact review resolutions in
		# a viewport so sky/compositor/annotation pixels share one unscaled target.
		capture_view=SubViewport.new();capture_view.size=Vector2i(1280,720) if mode=="capture" else Vector2i(960,540)
		capture_view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
		host.add_child(capture_view);output_view=capture_view
		demo.setup_options.size=capture_view.size;capture_view.add_child(demo)
	else:host.add_child(demo)
	await tree.process_frame
	if not demo.ready_ok:check(false,"demo not ready");demo.queue_free();return 1
	demo.auto=false;demo.journey_auto_tick=false;demo.set_process(false)
	demo.star_identification.set_process(false)
	guide=demo.star_identification.constellations
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	if mode=="golden":await golden()
	elif mode=="capture":await capture()
	elif mode=="bench":await bench()
	else:check(false,"unknown mode "+mode)
	var file := FileAccess.open(OUT+"/"+mode+"-manifest.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({mode=mode,cases=rows,failures=failures},"  "));file.close()
	demo.queue_free();await tree.process_frame
	if capture_view!=null:capture_view.queue_free();await tree.process_frame
	tree.root.size=old_size
	return failures

func hide_hud() -> void:
	for child in demo.get_children():
		if child is CanvasLayer and child.layer>=0:child.hide()
func aim(world_dir: Vector3) -> void:
	var gal := SkyFrame.to_galactic64([world_dir.x,world_dir.y,world_dir.z])
	var ship := ShipFrame.to_ship(ShipFrame.ship_basis(demo.camera.heading),gal)
	var local := Vector3(ship[0],ship[2],-ship[1]).normalized()
	demo.camera.basis=Basis.looking_at(local,Vector3.UP if absf(local.y)<.99 else Vector3.RIGHT)
	demo._sync_observer()

func centroid(img: Image, point: Vector2) -> Vector2:
	var peak := 0.;var total := 0.;var sum := Vector2.ZERO
	var rect := Rect2i(Vector2i(point)-Vector2i(8,8),Vector2i(17,17)).intersection(Rect2i(Vector2i.ZERO,img.get_size()))
	for y in range(rect.position.y,rect.end.y):
		for x in range(rect.position.x,rect.end.x):peak=maxf(peak,img.get_pixel(x,y).get_luminance())
	for y in range(rect.position.y,rect.end.y):
		for x in range(rect.position.x,rect.end.x):
			var light := img.get_pixel(x,y).get_luminance()
			if light>=peak*.5:sum+=Vector2(x+.5,y+.5)*light;total+=light
	return sum/total if total>0. and peak>.02 else Vector2(-10000,-10000)

func golden() -> void:
	hide_hud();demo.geometry.hide();demo.sky.system_view.hide()
	demo.sky.env.glow_enabled=false;demo.sky.dust_auto=false;demo.sky.upload_dust([])
	demo.sky_only=true
	guide.set_manifest({version=1,figures=[{id="test",name="Test",endpoints=[{id="a",catalogue_id="a"},{id="b",catalogue_id="b"}],segments=[["a","b"]]}]})
	demo.star_identification.held=true
	var field: Starfield=demo.sky.starfield
	var px := Vector2(capture_view.size)
	var case_count := 0
	for pose in [[18.,.4,0.,78.],[-22.,1.2,.3,55.]]:
		demo.camera.follow(Vector3(8,82,-4.8),pose[0],pose[1],0.)
		demo.camera.basis=demo.camera.basis.rotated(-demo.camera.basis.z,pose[2]);demo.camera.fov=pose[3];demo._sync_observer()
		for speed in [0.,.5,.9,.99,.999]:
			var heading := Vector3(.2,.7,-.4).normalized()
			var phi := Relativity.rapidity_of_beta(speed)
			for rebase in ["origin","far-gpu","far-cpu"]:
				var eye := PackedFloat64Array([0.,0.,0.]) if rebase=="origin" else PackedFloat64Array([100000.,-90000.,80000.])
				var distance := 100. if rebase=="origin" else .0003
				var stars: Array=[];var references := {}
				for j in 2:
					var pixel := px*Vector2(.36+.28*j,.44+.12*j)
					var apparent := Camera.to_sky_direction(demo.camera.project_ray_normal(pixel),demo.camera.heading).normalized()
					var rest := Relativity.deaberrate(apparent,heading,speed)
					var d := Relativity.doppler(rest,heading,speed);var t := 5700./d
					var pos := PackedFloat64Array([eye[0]+rest.x*distance,eye[1]+rest.y*distance,eye[2]+rest.z*distance])
					var flux := .1/Relativity.point_flux_ratio(t,d)
					var id := "a" if j==0 else "b"
					stars.append({id=id,pos=pos,t=t,flux=flux})
					# Independent CPU direction starts from float64 catalogue displacement.
					var n := Vector3(pos[0]-eye[0],pos[1]-eye[1],pos[2]-eye[2]).normalized()
					var ray := Relativity.aberrate(n,heading,speed)
					references[id]=demo.sky.camera.unproject_position(ray*100.)
				field.set_custom_stars(stars)
				field.set_rebase_mode(Starfield.Rebase.CPU if rebase=="far-cpu" else Starfield.Rebase.GPU)
				field.set_ship_position(eye[0],eye[1],eye[2]);field.set_velocity(heading,speed,Relativity.gamma_of_rapidity(phi));field.set_exposure(5.)
				guide.refresh(field,demo.sky.camera,px);guide.show()
				var star_image := await grab(demo.sky)
				var worst := 0.;var cpu_worst := 0.
				check(guide.segments.size()==1,"synthetic connector present")
				for id in ["a","b"]:
					var p: Vector2=guide.endpoints.get(id,Vector2(-10000,-10000))
					worst=maxf(worst,centroid(star_image,references[id]).distance_to(p))
					cpu_worst=maxf(cpu_worst,p.distance_to(references[id]))
				var on := await grab(output_view)
				guide.hide();var off := await grab(output_view);guide.show()
				var middle: Vector2=(references.a+references.b)*.5
				var raster := difference(on,off,middle)
				var ok := worst<=.75 and cpu_worst<=.75 and raster>.015
				check(ok,"GPU endpoint/composited connector")
				print("%s    G-CONST endpoint %02d beta %.3f %s GPU %.4f CPU %.4f raster %.4f" % ["ok" if ok else "FAIL",case_count,speed,rebase,worst,cpu_worst,raster])
				rows.append({beta=speed,rebase=rebase,pose=pose,gpu_error_px=worst,cpu_error_px=cpu_worst,line_raster_difference=raster})
				case_count+=1
	for resolution in [Vector2i(1280,720),Vector2i(2560,1440)]:
		capture_view.size=resolution;await tree.process_frame
		demo.geometry_view.size=resolution;demo._sync_observer()
		guide.refresh(field,demo.sky.camera,Vector2(resolution));guide.show()
		var img := await grab(demo.sky)
		var worst := 0.;var cpu_worst := 0.
		for id in ["a","b"]:
			var pixel: Vector2=guide.endpoints[id]
			var n := field.direction_to(field.ids.find(id))
			var ctx := Guide.StarProjection.context(field)
			var ray := Relativity.aberrate(Vector3(n[0],n[1],n[2]),ctx.bh,.999)
			var reference: Vector2=demo.sky.camera.unproject_position(ray*100.)
			worst=maxf(worst,centroid(img,reference).distance_to(pixel))
			cpu_worst=maxf(cpu_worst,reference.distance_to(pixel))
		var ok := worst<=.75 and cpu_worst<=.75
		check(ok,"resized GPU and independent CPU endpoints align")
		print("%s    G-CONST resize %dx%d GPU %.4f CPU %.4f" % ["ok" if ok else "FAIL",resolution.x,resolution.y,worst,cpu_worst])
		rows.append({resolution=[resolution.x,resolution.y],gpu_error_px=worst,cpu_error_px=cpu_worst})
		case_count+=1
	# Exercise the actual geometry canvas ordering with an opaque and transparent pixel.
	var line: Dictionary=guide.segments[0] if not guide.segments.is_empty() else {a=Vector2.ZERO,b=Vector2.ZERO}
	var mid: Vector2=(line.a+line.b)*.5
	var mask := ColorRect.new();mask.color=Color.BLACK;mask.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var inv := output_view.get_stretch_transform().affine_inverse()
	mask.position=inv*(mid-Vector2(10,10));mask.size=inv.basis_xform(Vector2(20,20))
	demo._rects[1].get_parent().add_child(mask)
	guide.show();var on := await grab(output_view)
	guide.hide();var off := await grab(output_view)
	var masked := difference(on,off,mid)
	var open_pixel := difference(on,off,line.a.lerp(line.b,.25))
	var masked_ok := masked<.001 and open_pixel>.015
	check(masked_ok,"ship compositor masks opaque pixels and preserves open sky")
	print("%s    G-CONST hull mask hidden %.4f open %.4f" % ["ok" if masked_ok else "FAIL",masked,open_pixel])
	case_count+=1
	rows.append({hull_mask_difference=masked,open_sky_difference=open_pixel})
	mask.queue_free()
	print("constellation golden: %d cases, %d failures" % [case_count,failures])

func difference(a: Image, b: Image, point: Vector2) -> float:
	var result := 0.
	for y in range(maxi(0,int(point.y)-2),mini(a.get_height(),int(point.y)+3)):
		for x in range(maxi(0,int(point.x)-2),mini(a.get_width(),int(point.x)+3)):
			result=maxf(result,absf(a.get_pixel(x,y).get_luminance()-b.get_pixel(x,y).get_luminance()))
	return result

func capture() -> void:
	guide.load_manifest();hide_hud()
	demo.sky.dust_auto=false;demo.sky.upload_dust([])
	demo.sky.system_view.hide()
	demo.star_identification.held=true
	for resolution in [Vector2i(1280,720),Vector2i(2560,1440)]:
		capture_view.size=resolution;await tree.process_frame
		demo.geometry_view.size=resolution;demo._sync_observer();await tree.process_frame
		for figure: Dictionary in guide.figures:
			for state in ["rest","moving","travelled"]:
				demo.set_sky_state("rest");demo.sky.system_view.hide();demo.geometry.hide()
				var field: Starfield=demo.sky.starfield
				guide.resolve(field)
				var centre := Vector3.ZERO
				for p in figure.endpoints:
					if guide.indices.has(p.id):
						var k: int=guide.indices[p.id];centre+=Vector3(field.pos[3*k],field.pos[3*k+1],field.pos[3*k+2]).normalized()
				centre=centre.normalized()
				demo.camera.fov=55.;aim(centre)
				var heading: Vector3= (centre+demo.sky.camera.global_basis.x*.5).normalized()
				if state=="moving":
					var phi := Relativity.rapidity_of_beta(.5)
					field.set_velocity(heading,.5,Relativity.gamma_of_rapidity(phi))
					demo.sky.background.set_velocity(heading,.5,Relativity.gamma_of_rapidity(phi))
				elif state=="travelled":field.set_ship_position(20.,0.,0.)
				guide.update_view()
				var name: String="%s_%s_%d.png" % [figure.id,state,resolution.x]
				(await grab(output_view)).save_png(OUT+"/"+name)
				var count: int=guide.segments.filter(func(s):return s.figure==figure.id).size()
				check(count>0,"capture contains guide: "+name)
				rows.append({file=name,figure=figure.id,state=state,resolution=[resolution.x,resolution.y],segments=count,observer_ly=Array(field.ship),note="Frozen renderer review; moving beta .5; travelled observer +20 ly in world X; no simulated history is claimed"})
		await capture_limits(resolution)
	print("constellation capture: %d images, %d failures" % [rows.size(),failures])

func save_case(name: String, resolution: Vector2i, note: String) -> void:
	guide.update_view()
	demo.star_identification.queue_redraw()
	var image := await grab(output_view)
	check(image.get_size()==resolution,"capture has requested pixel dimensions")
	image.save_png(OUT+"/"+name+"_%d.png" % resolution.x)
	rows.append({file=name+"_%d.png" % resolution.x,note=note,resolution=[resolution.x,resolution.y],segments=guide.segments.size()})

func capture_limits(resolution: Vector2i) -> void:
	demo.set_sky_state("rest");demo.geometry.hide();demo.sky.system_view.hide()
	demo.star_identification.get_parent().show();demo.star_identification.show()
	var field: Starfield=demo.sky.starfield
	guide.resolve(field)
	var k: int=guide.indices["HIP 27989"]
	var centre := Vector3(field.pos[3*k],field.pos[3*k+1],field.pos[3*k+2]).normalized()
	aim(centre)
	# Actual finite-body renderer and the same opaque-disc annotation mask.
	var rel := SkyFrame.to_galactic(centre*100000.)
	var body := {id="review-globe",kind="planet",name="Review globe",radius_km=5000.,rel_km={x=rel.x,y=rel.y,z=rel.z},p_v=.3,minnaert_k=1.,r_au=1.,phase_deg=0.,e_v_lux=1.,e1_au_lux=100000.,pole={x=0.,y=0.,z=1.},w_deg=0.,sun_dir={x=-rel.x,y=-rel.y,z=-rel.z}}
	demo.sky.system_view.show();demo.sky.system_view.update({bodies=[body]},demo.sky.exposure.k())
	await save_case("body_occlusion",resolution,"Synthetic 5,000 km opaque review globe 100,000 km away, actual body renderer")
	demo.sky.system_view.hide()
	var phi := Relativity.rapidity_of_beta(.999)
	field.set_velocity(centre,.999,Relativity.gamma_of_rapidity(phi));demo.sky.background.set_velocity(centre,.999,Relativity.gamma_of_rapidity(phi))
	await save_case("high_speed_partial",resolution,"Frozen beta .999 renderer review; same exposure/culling as stars")
	demo.set_sky_state("rest");demo.sky.system_view.hide()
	demo.sky.set_gr(GrLens.reference_state(5.,PackedFloat64Array([1.,0.,0.])))
	aim(SkyFrame.to_world(Vector3.RIGHT))
	await save_case("gr_unavailable",resolution,"Actual GR lens at 5 r_s, guides suppressed and status shown")
	check(guide.segments.is_empty() and guide.status.contains("unavailable"),"GR capture suppresses guides")
	demo.sky.set_gr({});demo.set_sky_state("rest");demo.sky.system_view.hide();demo.geometry.show()
	demo.camera.follow(demo.avatar_pos,20.,.4,0.)
	# Choose a familiar figure above the physical deck, from the standing eye.
	guide.resolve(field)
	var up := Camera.to_sky_direction(Vector3.UP,demo.camera.heading)
	var best := -INF
	for figure in guide.figures:
		var n := Vector3.ZERO
		for p in figure.endpoints:
			var row: int=guide.indices[p.id];n+=Vector3(field.pos[3*row],field.pos[3*row+1],field.pos[3*row+2]).normalized()
		n=n.normalized()
		if n.dot(up)>best:centre=n;best=n.dot(up)
	aim(centre)
	await save_case("ship_windows",resolution,"Real hull and standing eye; a figure above the deck is visible through the ship")
	demo.star_identification.get_parent().hide()

func bench() -> void:
	guide.load_manifest();hide_hud();demo.sky.system_view.hide()
	guide.resolve(demo.sky.starfield)
	var centre := Vector3.ZERO
	for p in guide.figures[0].endpoints:
		var k: int=guide.indices[p.id];var field: Starfield=demo.sky.starfield
		centre+=Vector3(field.pos[3*k],field.pos[3*k+1],field.pos[3*k+2]).normalized()
	aim(centre.normalized())
	demo.star_identification.suppressed=false
	for held in [false,true]:
		demo.star_identification.set_held(held)
		for frame in 60:guide.update_view();await tree.process_frame
		var scans: int=guide.identity_scans
		var times: Array=[];var frame_times: Array=[];var previous := Time.get_ticks_usec()
		for frame in 300:
			demo.camera.basis=Basis(Vector3.UP,.0001)*demo.camera.basis;demo._sync_observer()
			var begin := Time.get_ticks_usec();guide.update_view()
			times.append((Time.get_ticks_usec()-begin)/1000.)
			await tree.process_frame
			var now := Time.get_ticks_usec();frame_times.append((now-previous)/1000.);previous=now
		times.sort();frame_times.sort()
		var p95: float=times[284]
		check(p95<=2.,"overlay CPU p95 <=2 ms")
		check(scans==guide.identity_scans,"no warm full-catalogue rescans")
		check(held or not guide.visible,"released overlay idle")
		check(not held or not guide.segments.is_empty(),"held benchmark contains visible guides")
		rows.append({held=held,samples=300,segments=guide.segments.size(),cpu_p95_ms=p95,frame_p95_ms=frame_times[284],identity_rescans=guide.identity_scans-scans,cpu=OS.get_processor_name(),gpu=RenderingServer.get_video_adapter_name(),resolution=[1920,1080]})
	print("constellation bench: %d pairs, %d failures" % [rows.size(),failures])
