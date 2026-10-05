extends SceneTree
## Independent GPU evidence: finite marker and aberrated infinite star share a ray.
const Camera := preload("res://demos/ship_demo_camera.gd")
var cam: Camera3D
var sky: InteriorSky
var finite: SubViewport
var marker := MeshInstance3D.new()
var blocker := MeshInstance3D.new()
var rows := []
var failures := 0
func _initialize() -> void:
	_run.call_deferred()
func _layer(texture: Texture2D, order: int) -> void:
	var layer:=CanvasLayer.new();layer.layer=order;root.add_child(layer)
	var rect:=TextureRect.new();rect.texture=texture;rect.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	layer.add_child(rect);rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
func _grab(view: Viewport) -> Image:
	for i in 4:await process_frame
	await RenderingServer.frame_post_draw
	return view.get_texture().get_image()
func _centroid(img: Image, p: Vector2) -> Vector2:
	var peak:=0.;var sum:=Vector2.ZERO;var weight:=0.
	for y in range(maxi(0,int(p.y)-12),mini(img.get_height(),int(p.y)+13)):
		for x in range(maxi(0,int(p.x)-12),mini(img.get_width(),int(p.x)+13)):
			peak=maxf(peak,img.get_pixel(x,y).get_luminance())
	for y in range(maxi(0,int(p.y)-12),mini(img.get_height(),int(p.y)+13)):
		for x in range(maxi(0,int(p.x)-12),mini(img.get_width(),int(p.x)+13)):
			var l:=img.get_pixel(x,y).get_luminance()
			if l>=peak*.5:sum+=Vector2(x+.5,y+.5)*l;weight+=l
	return sum/weight if weight>0. else Vector2(-1000,-1000)
func _run() -> void:
	root.size=Vector2i(1280,720)
	var demo: Node=load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options={"stars":false,"background":false,"size":root.size}
	root.add_child(demo);demo.set_process(false);demo.hud.visible=false
	cam=demo.camera;sky=demo.sky;finite=demo.geometry_view
	for child in demo.geometry.get_children():
		if child is Node3D:child.visible=false
	var sphere:=SphereMesh.new();sphere.radius=.09;sphere.height=.18;marker.mesh=sphere
	var white:=StandardMaterial3D.new();white.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;white.albedo_color=Color.WHITE
	marker.material_override=white;finite.add_child(marker)
	var cube:=BoxMesh.new();cube.size=Vector3(1,1,.1);blocker.mesh=cube
	var black:=StandardMaterial3D.new();black.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;black.albedo_color=Color.BLACK
	blocker.material_override=black;finite.add_child(blocker);blocker.visible=false
	var worst:=0.
	for px in [Vector2i(1280,720),Vector2i(960,720),Vector2i(720,960)]:
		root.size=px;finite.size=px
		for pose in [[-15.,.47,0.,78.],[-60.,1.2,.3,55.],[20.,-1.,-.4,95.]]:
			cam.follow(Vector3(8,82,-4.8),pose[0],pose[1],3.)
			cam.basis=cam.basis.rotated(-cam.basis.z,pose[2]);cam.fov=pose[3];cam.sync_sky(sky,px)
			for target in [Vector2(.5,.5),Vector2(.2,.2),Vector2(.8,.7)]:
				var expected: Vector2=target*Vector2(px)
				var ray:=cam.project_ray_normal(expected)
				marker.position=cam.position+ray*30.
				for beta in [0.,.9,.99]:
					var apparent:=Camera.to_sky_direction(ray,cam.heading).normalized()
					var velocity:=SkyFrame.to_world(Vector3(cam.heading[0],cam.heading[1],cam.heading[2])).normalized()
					var rest:=Relativity.deaberrate(apparent,velocity,beta)
					var d:=Relativity.doppler(rest,velocity,beta);var t:=5700./d
					var sf:=sky.starfield
					sf.set_custom_stars([{"name":"optics","pos":rest*1000.,"t":t,"flux":1./Relativity.point_flux_ratio(t,d)}])
					sf.set_ship_position(0.,0.,0.);sf.set_velocity(velocity,beta,Relativity.gamma_of(beta));sf.set_exposure(5.)
					var star:=_centroid(await _grab(sky),expected)
					var mark:=_centroid(await _grab(finite),expected)
					var error:=star.distance_to(mark);worst=maxf(worst,error)
					if error>.75:failures+=1
					rows.append({"size":[px.x,px.y],"pose":pose,"target":[target.x,target.y],"beta":beta,"star_px":[star.x,star.y],"marker_px":[mark.x,mark.y],"error_px":error})
	# The actual two-target composition must mask a depth-disabled catalogue star.
	root.size=Vector2i(1280,720);finite.size=root.size
	cam.follow(Vector3(8,82,-4.8),-30.,.47,0.);cam.fov=78.;cam.sync_sky(sky,root.size)
	var ray: Vector3=-cam.basis.z
	sky.starfield.set_custom_stars([{"name":"occlusion","pos":Camera.to_sky_direction(ray,cam.heading)*1000.,"t":5700.,"flux":1.}])
	sky.starfield.set_velocity(Vector3(0,-1,0),0.,1.);sky.starfield.set_exposure(5.)
	marker.visible=false;blocker.position=cam.position+ray*10.;blocker.basis=cam.basis
	var open:=await _grab(root)
	blocker.visible=true
	var covered:=await _grab(root)
	var centre:=root.size/2;var before:=open.get_pixelv(centre).get_luminance();var after:=covered.get_pixelv(centre).get_luminance()
	if before<.1 or after>.01:failures+=1
	# Negative control: a deliberately different sky FOV must be detected.
	blocker.visible=false;marker.visible=true;marker.position=cam.position+cam.project_ray_normal(Vector2(960,240))*30.
	sky.starfield.set_custom_stars([{"name":"negative","pos":Camera.to_sky_direction((marker.position-cam.position).normalized(),cam.heading)*1000.,"t":5700.,"flux":1.}])
	sky.camera.fov=60.
	var negative:=await _grab(sky)
	var peak:=0.;var located:=Vector2.ZERO
	for y in negative.get_height():
		for x in negative.get_width():
			var l:=negative.get_pixel(x,y).get_luminance()
			if l>peak:peak=l;located=Vector2(x,y)
	var mismatch:=_centroid(negative,located).distance_to(Vector2(960,240))
	if peak<.1 or mismatch<10.:failures+=1
	var out:="res://renders/ship_demo/optics";DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	open.save_png(out+"/uncovered.png");covered.save_png(out+"/covered.png")
	var f:=FileAccess.open(out+"/audit.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"cases":rows,"worst_px":worst,"limit_px":.75,"occlusion_before":before,"occlusion_after":after,"negative_control_error_px":mismatch,"failures":failures},"  "))
	print("ship-demo-optics: %d cases, worst %.4f px, occlusion %.4f -> %.4f, negative %.2f px, failures %d" % [rows.size(),worst,before,after,mismatch,failures])
	quit(1 if failures else 0)
