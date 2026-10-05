extends SceneTree
var failures:=0
func _initialize()->void:_run.call_deferred()
func _run()->void:
	root.size=Vector2i(1280,720);UiScale.configure(root,true)
	var demo:Node=load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options={"size":Vector2i(1280,720),"sky_state":"rest"};root.add_child(demo);await process_frame
	demo.auto=false;demo.journey_auto_tick=false
	if not demo.has_method("set_lighting"):
		print("ship-lighting-capture: FAIL missing lighting profile");quit(1);return
	var out:="res://renders/ship_lighting"
	DirAccess.make_dir_recursive_absolute(out)
	var captures:=[]
	for pose in ["bridge_outward","bridge_inward","bridge_overlook","commons_arcade"]:
		match pose:
			"bridge_outward":demo.set_preset("bridge")
			"bridge_inward":demo.set_preset("bridge");demo.camera.follow(demo.avatar_pos,8.,3.61,0.)
			"bridge_overlook":demo.set_preset("overlook")
			"commons_arcade":
				demo.active_level=1;demo.walk=demo.walk_lower;demo.avatar_pos=Vector3(46,57,-5);demo.camera_mode="player";demo.camera.follow(demo.avatar_pos,0.,1.6,0.)
		var profile_images:={}
		for profile in ["baseline","moody","moody_no_shadows"]:
			demo.set_lighting(profile);demo._sync_observer()
			for frame in 20:await process_frame
			await RenderingServer.frame_post_draw
			var picture:Image=demo.geometry_view.get_texture().get_image()
			profile_images[profile]=picture
			root.get_texture().get_image().save_png(out+"/"+pose+"_"+profile+".png")
			var eye:Vector3=demo.camera.position
			captures.append({"name":pose+"_"+profile,"eye_m":[eye.x,eye.y,eye.z],"fov":demo.camera.fov,"sky_state":demo.sky_state,"sky_brightness_stops":demo.brightness_stops,"lighting":demo.lighting_manifest()})
		var shadow:Image=profile_images.moody
		var no_shadow:Image=profile_images.moody_no_shadows
		var changed:=0
		for y in range(0,shadow.get_height(),3):
			for x in range(0,shadow.get_width(),3):
				var a:=shadow.get_pixel(x,y);var b:=no_shadow.get_pixel(x,y)
				if maxf(absf(a.r-b.r),maxf(absf(a.g-b.g),absf(a.b-b.b)))>.025:changed+=1
		print("ship-lighting-shadow: ",pose," changed_sample_pixels=",changed)
		if changed<10:failures+=1
	var pins:={}
	for model in ["assets/ship_demo/ship.glb","assets/ship_commons/commons_painted.glb"]:
		if FileAccess.file_exists("res://"+model):pins[model]=FileAccess.get_sha256("res://"+model)
	var file:=FileAccess.open(out+"/manifest.json",FileAccess.WRITE);file.store_string(JSON.stringify({"captures":captures,"model_and_embedded_material_sha256":pins,"shadow_failures":failures,"note":"Fixed internal lighting study; external simulation Sun illumination is a separate later integration. Sky remains4x."},"  "))
	print("ship-lighting-capture: %s" % ("OK" if failures==0 else "FAIL"))
	demo.queue_free();await process_frame;quit(1 if failures else 0)
