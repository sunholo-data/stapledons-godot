extends SceneTree
## Native production optical renderer; normal package body rows at controlled
## placements. Repeated20Hz identical-world applies use interactive exposure.
var failures:=0
func _initialize()->void:run.call_deferred()
func run()->void:
	root.size=Vector2i(800,600)
	var sky:=InteriorSky.new();root.add_child(sky)
	sky.setup({"position_m":[0,0,0],"forward":[0,0,1],"up":[0,1,0]},78.,root.size,{"stars":false,"background":true,"planet_textures":true})
	var rect:=TextureRect.new();rect.texture=sky.get_texture();rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.add_child(rect)
	var label:=Label.new();label.position=Vector2(12,12);label.add_theme_color_override("font_shadow_color",Color.BLACK);label.add_theme_constant_override("shadow_offset_x",2);label.add_theme_constant_override("shadow_offset_y",2);root.add_child(label)
	var sim:=SimBridge.new();sim.want_minor=5
	if not sim.start() or not sim.new_game(19):print("exposure-frame-capture: FAIL ",sim.last_error);quit(1);return
	var authority:=sim.world.duplicate(true);var output:="res://renders/ship_demo/exposure_frames";DirAccess.make_dir_recursive_absolute(output)
	var records:=[]
	for id:String in ["earth","jupiter","sun"]:
		var body:Dictionary={}
		for row:Dictionary in authority.system.bodies:
			if row.id==id:body=row.duplicate(true)
		var distance:float=149597870.7 if id=="sun" else body.radius_km*8.
		body.rel_km={"x":distance,"y":0.,"z":0.}
		if id=="sun":body.e_v_lux=127057.41052085394
		else:
			body.sun_dir={"x":-1.,"y":0.,"z":0.};body.phase_deg=0.
			body.e_v_lux=Planets.disc_illuminance(127057.41052085394,body.p_v,body.radius_km,body.r_au,distance,0.,body.minnaert_k)
		var world:=authority.duplicate(true);world.system.bodies=[body];world.ship.heading={"x":1.,"y":0.,"z":0.}
		sky.set_temporal_exposure(false);sky.exposure.bias=-2.;sky.apply(world);sky.camera.look(0.,0.,0.);sky.update_exposure();sky.set_temporal_exposure(true)
		var reference:Image;var ev_min:=INF;var ev_max:=-INF;var max_pixel:=0.
		for frame in 90:
			if frame%3==0:sky.apply(world)
			# Same final observer sync after every apply; no artificial activeworld cancellation.
			sky.camera.look(0.,0.,0.);sky.finish_exposure_frame(1./60.)
			label.text="%s · interactive display anticipation/fade · calibrated4× aid\nPackage-body fixture; controlled placement; same camera/world20Hz\nEV %.6f · physical rays unchanged"%[id,sky.exposure.ev]
			await process_frame
			if frame>=60:
				ev_min=minf(ev_min,sky.exposure.ev);ev_max=maxf(ev_max,sky.exposure.ev)
			if frame in [60,69,78,87]:
				await RenderingServer.frame_post_draw
				var img:=sky.get_texture().get_image()
				if reference==null:reference=img
				else:
					for y in img.get_height():
						for x in img.get_width():
							var a:=img.get_pixel(x,y);var b:=reference.get_pixel(x,y)
							max_pixel=maxf(max_pixel,maxf(absf(a.r-b.r),maxf(absf(a.g-b.g),absf(a.b-b.b))))
				root.get_texture().get_image().save_png(output.path_join("%s_%d.png"%[id,frame]))
		var ok:=ev_max-ev_min<1e-9 and max_pixel<=1./255.
		if not ok:failures+=1
		print("ok " if ok else "FAIL ",id," interactive steadyEVrange=",ev_max-ev_min," maxChannelStep=",max_pixel," stats=",sky.exposure_stats())
		records.append({"id":id,"ev_min":ev_min,"ev_max":ev_max,"max_channel_step":max_pixel,"cadence_hz":20,"display_policy":"30deg peripheral anticipation; up32/down4EV/s; actual-FOV safety fallback","world_source":"normal protocol2.5 body records; controlled placement","physical_body":body,"stats":sky.exposure_stats()})
	check_authority(sim.world==authority)
	var file:=FileAccess.open(output.path_join("metrics.json"),FileAccess.WRITE);file.store_string(JSON.stringify(records,"  "))
	sim.stop();rect.queue_free();label.queue_free();sky.queue_free();await process_frame
	print("exposure-frame-capture: %d failures"%failures);quit(1 if failures else 0)
func check_authority(ok:bool)->void:
	if not ok:failures+=1;print("FAIL authoritative state mutated")
