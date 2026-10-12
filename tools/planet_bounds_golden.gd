extends SceneTree
var failures:=0
func _initialize()->void:run.call_deferred()
func run()->void:
	root.size=Vector2i(800,600)
	var viewport:=SubViewport.new();viewport.size=root.size;viewport.own_world_3d=true;viewport.use_hdr_2d=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
	var env:=Environment.new();env.background_mode=Environment.BG_COLOR;env.background_color=Color.WHITE;env.tonemap_mode=Environment.TONE_MAPPER_LINEAR
	var we:=WorldEnvironment.new();we.environment=env;viewport.add_child(we)
	var camera:=FreeLookCamera.new();camera.fov=35.;camera.current=true;viewport.add_child(camera)
	var sf:=Starfield.new();sf.set_custom_stars([]);sf.build();viewport.add_child(sf)
	var sv:=SystemView.new();sv.setup(sf,false);sv.relativistic_enabled=true;sv.set_view(2.*tan(deg_to_rad(17.5))/600.,600.);viewport.add_child(sv)
	var sim:=SimBridge.new();sim.want_minor=5
	if not sim.start() or not sim.new_game(3):print("planet-bounds-golden: FAIL simulation ",sim.last_error);quit(1);return
	var bodies:Array=sim.world.system.bodies;var rings:Array=sim.world.system.rings
	var cases:=[["sun",.5,90.,5.,22.,0.],["sun",.9,150.,5.,-22.,.4],["sun",.99,180.,80.,0.,0.],["sun",.9,90.,30.,10.,.7],["saturn",.9,150.,5.,22.,.2],["saturn",.99,90.,30.,-22.,.5]]
	var results:=[]
	for c:Array in cases:
		var b:Dictionary={}
		for body:Dictionary in bodies:
			if body.id==c[0]:b=body.duplicate(true)
		var beta:float=c[1];var gamma:=1./sqrt(1.-beta*beta);var theta:=deg_to_rad(c[2]);var alpha:=deg_to_rad(c[3]);var distance:float=b.radius_km/sin(alpha)
		var direction:=Vector3(sin(theta),0,-cos(theta));var gal:=SkyFrame.to_galactic64([direction.x,direction.y,direction.z])
		b.rel_km={"x":gal[0]*distance,"y":gal[1]*distance,"z":gal[2]*distance}
		if b.kind=="star":b.e_v_lux=Planets.star_illuminance_at(127057.41052085394,distance/SystemView.AU_KM)
		else:
			b.sun_dir={"x":-gal[0],"y":-gal[1],"z":-gal[2]};b.phase_deg=0.
			b.e_v_lux=Planets.disc_illuminance(127057.41052085394,b.p_v,b.radius_km,b.r_au,distance,0.,b.minnaert_k)
		var cap:=Planets.apparent_disc64(cos(theta),alpha,beta,gamma)
		camera.look(-cap[0]+deg_to_rad(c[4]),0.,c[5]);sv.set_velocity(Vector3(0,0,-1),beta,gamma,1./(gamma*gamma*(1.+beta)));sv.update({"bodies":[b],"rings":rings},1e-8)
		var material:ShaderMaterial=sv.discs[b.id].material_override
		var bounded:bool=material.get_shader_parameter("bounded_draw")
		for frame in 3:await process_frame
		await RenderingServer.frame_post_draw
		var bounded_img:=viewport.get_texture().get_image()
		material.set_shader_parameter("bounded_draw",false)
		for frame in 3:await process_frame
		await RenderingServer.frame_post_draw
		var reference:=viewport.get_texture().get_image();var max_error:=0.;var energy:=0.
		for y in 600:
			for x in 800:
				var a:=bounded_img.get_pixel(x,y);var r:=reference.get_pixel(x,y)
				max_error=maxf(max_error,maxf(absf(a.r-r.r),maxf(absf(a.g-r.g),absf(a.b-r.b))));energy+=absf(r.r-1.)+absf(r.g-1.)+absf(r.b-1.)
		var ok:=energy>1e-4 and max_error<.0001
		if not ok:failures+=1
		print("ok " if ok else "FAIL ",c," bounded",bounded," maxerror",max_error," energy",energy)
		results.append({"case":c,"bounded":bounded,"max_channel_error":max_error,"reference_energy":energy})
	DirAccess.make_dir_recursive_absolute("res://renders/m5/transitions")
	var file:=FileAccess.open("res://renders/m5/transitions/bounds.json",FileAccess.WRITE);file.store_string(JSON.stringify(results,"  "))
	sim.stop();viewport.queue_free();await process_frame
	print("planet-bounds-golden: %d failures"%failures);quit(1 if failures else 0)
