extends SceneTree
var failures:=0
func _initialize()->void:run.call_deferred()
func run()->void:
	root.size=Vector2i(800,600)
	root.content_scale_mode=Window.CONTENT_SCALE_MODE_DISABLED
	root.content_scale_size=Vector2i.ZERO
	root.content_scale_factor=1.0
	var viewport:=SubViewport.new();viewport.size=root.size;viewport.own_world_3d=true;viewport.use_hdr_2d=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(viewport)
	var preview:=TextureRect.new();preview.size=Vector2(root.size);preview.texture=viewport.get_texture();root.add_child(preview)
	# HDR viewport pixels are linear. The ordinary LDR canvas expects encoded
	# colour, unlike a3D tonemap output; explicitly apply the existing sRGB transfer.
	var preview_shader:=Shader.new()
	preview_shader.code="shader_type canvas_item; render_mode unshaded; void fragment(){vec4 c=texture(TEXTURE,UV); vec3 encoded=mix(12.92*c.rgb,1.055*pow(max(c.rgb,vec3(0.0)),vec3(1.0/2.4))-0.055,step(vec3(0.0031308),c.rgb));COLOR=vec4(encoded,c.a);}"
	var preview_material:=ShaderMaterial.new();preview_material.shader=preview_shader;preview.material=preview_material
	var environment:=Environment.new();environment.background_mode=Environment.BG_COLOR;environment.background_color=Color.BLACK;environment.tonemap_mode=Environment.TONE_MAPPER_LINEAR
	var we:=WorldEnvironment.new();we.environment=environment;viewport.add_child(we)
	var camera:=FreeLookCamera.new();camera.fov=35.;camera.current=true;viewport.add_child(camera)
	var sf:=Starfield.new();sf.set_custom_stars([]);sf.point_overlay=true;sf.build();viewport.add_child(sf)
	var sv:=SystemView.new();sv.setup(sf,false);sv.relativistic_enabled=true;sv.lod_range=Vector2(1.5,3.5);viewport.add_child(sv)
	var pxrad:=2.*tan(deg_to_rad(17.5))/600.;sv.set_view(pxrad,600.)
	var system:Dictionary={}
	for line in FileAccess.get_file_as_string("res://tests/fixtures/system_sol.ndjson").split("\n",false):
		var record:Dictionary=JSON.parse_string(line)
		if record.type=="state":system=record.changes.system;break
	var b:Dictionary={}
	for body:Dictionary in system.bodies:
		if body.id=="moon":b=body.duplicate(true)
	var samples:=[];var previous_ratio:=1.;var max_step:=0.;var max_error:=0.
	var previous_display:=1.;var max_display_step:=0.;var max_display_error:=0.
	DirAccess.make_dir_recursive_absolute("res://renders/m5/transitions")
	for j in 86:
		var beta:float=0. if j<43 else .9;var gamma:float=1./sqrt(1.-beta*beta);var heading:=Vector3.RIGHT
		sv.set_velocity(heading,beta,gamma,1./(gamma*gamma*(1.+beta)));sf.set_velocity(heading,beta,gamma)
		var seen:=Relativity.aberrate(Vector3(0,0,-1),heading,beta);camera.look(atan2(-seen.x,-seen.z),0.,0.)
		var diameter:=1.4+(j%43)*.0525;var distance:float=b.radius_km/sin(diameter*pxrad*.5*gamma)
		b.rel_km={"x":distance,"y":0.,"z":0.};b.sun_dir={"x":-1.,"y":0.,"z":0.};b.phase_deg=0.
		b.e_v_lux=Planets.disc_illuminance(127057.41052085394,b.p_v,b.radius_km,b.r_au,distance,0.,b.minnaert_k)
		var ratio_seen:=SkyMeter.seen_point(1.,Planets.T_SUN,Vector3(0,0,-1),heading,beta)
		var k:float=.15*pxrad*pxrad/(b.e_v_lux*ratio_seen)
		sv.update({"bodies":[b]},k);sf.set_exposure(k/(TAU*.9*.9*pxrad*pxrad));sf.set_psf(.9);sf.set_floor(Vector2.ZERO)
		for frame in 3:await process_frame
		await RenderingServer.frame_post_draw
		var img:=viewport.get_texture().get_image();var display:=root.get_texture().get_image();var total:=0.;var display_total:=0.
		for y in range(288,312):
			for x in range(388,412):
				var c:=img.get_pixel(x,y);total+=(.2126729*c.r+.7151522*c.g+.0721750*c.b)*pxrad*pxrad
				var dc:=display.get_pixel(x,y).srgb_to_linear();display_total+=(.2126729*dc.r+.7151522*dc.g+.0721750*dc.b)*pxrad*pxrad
		var ratio:float=total/(b.e_v_lux*k*ratio_seen);max_error=maxf(max_error,absf(ratio-1.))
		if j%43>0:max_step=maxf(max_step,absf(ratio-previous_ratio))
		var display_ratio:float=display_total/(b.e_v_lux*k*ratio_seen);max_display_error=maxf(max_display_error,absf(display_ratio-1.))
		if j%43>0:max_display_step=maxf(max_display_step,absf(display_ratio-previous_display))
		previous_display=display_ratio
		previous_ratio=ratio;samples.append({"format":img.get_format(),"beta":beta,"diameter_px":sv._diameter_seen(Planets.world_of(b.rel_km),b.radius_km,distance),"disc_weight":sv.lod_weights.moon,"flux_ratio":ratio,"display_flux_ratio":display_ratio})
		if j%43 in [0,12,23,34,42]:display.save_png("res://renders/m5/transitions/moon_b%.1f_%02d.png"%[beta,j%43])
	var out:=FileAccess.open("res://renders/m5/transitions/metrics.json",FileAccess.WRITE)
	out.store_string(JSON.stringify({"samples":samples,"max_flux_error":max_error,"max_adjacent_flux_step":max_step,"max_display_flux_error":max_display_error,"max_display_adjacent_step":max_display_step,"note":"Actual linear floating HDR GPU output before8-bitdisplayquantization; package-backed reflected Moon illuminance, source fixture system_sol; shared authoritative optical uniforms; no textures or magnitude floor. WindowPNG anddisplaymetrics record8-bitquantization separately; physicalflux gates unchanged."},"  "))
	if max_error>.04 or max_step>.025:failures+=1
	print("planet-transition-golden: %d failures;86 samples max flux error %.5f max adjacent step %.5f"%[failures,max_error,max_step])
	sv.queue_free();sf.queue_free();camera.queue_free();await process_frame;quit(1 if failures else 0)
