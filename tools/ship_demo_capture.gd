extends SceneTree
var demo: Node
var out := "res://renders/ship_demo"
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	root.size=Vector2i(1280,720)
	demo=load("res://demos/ship_geometry_demo.tscn").instantiate();root.add_child(demo)
	await process_frame
	if not demo.ready_ok:quit(1);return
	demo.auto=false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var shots:=[]
	for name in ["bridge","overlook","overview"]:
		demo.set_preset(name)
		await _shot(name,shots)
	for radius in [sqrt(320.),21.3]:
		for tilt in [15.,30.,45.,60.]:
			demo.reference_view(radius,tilt)
			await _shot("reference_%s_%d" % ["interior" if radius<20 else "rim",int(tilt)],shots)
	demo.set_preset("reset");demo.avatar_pos=Vector3(8,82,-4.8);demo.set_preset("bridge")
	if not demo.lift.board():quit(1);return
	demo.lift.advance(.81)
	await _shot("lift_departure",shots)
	demo.lift.advance(5.5)
	await _shot("lift_midway",shots)
	demo.lift.advance(5.51);demo.lift.advance(.81)
	await _shot("lower_landing",shots)
	for i in 30:demo.avatar_pos=demo.walk.step(demo.avatar_pos,Vector3(.1,0,0))
	await _shot("lower_walk",shots)
	demo.avatar_pos=Vector3(8,57,-4.8)
	if not demo.lift.board():quit(1);return
	demo.lift.advance(.81);demo.lift.advance(11.01);demo.lift.advance(.81)
	await _shot("bridge_return",shots)
	if demo.lift.state!="bridge_ready":quit(1);return
	var f:=FileAccess.open(out+"/manifest.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"status":"native-material geometry review; lower architecture absent","projection":"one perspective observer, separate sky render target composited behind opaque finite geometry","GR":"not implemented","shots":shots},"  "))
	print("ship-demo-capture: OK");quit()
func _shot(name: String, shots: Array) -> void:
	for i in 5:await process_frame
	await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	image.save_png(out+"/"+name+".png")
	var hit: Dictionary=demo.centre_hit()
	shots.append({"name":name,"eye_gltf_m":[demo.camera.position.x,demo.camera.position.y,demo.camera.position.z],"vertical_fov":demo.camera.fov,"resolution":[root.size.x,root.size.y],"level":demo.active_level,"lift_state":demo.lift.state,"platform_y_m":demo.lift.platform.position.y,"diagnostic":demo.camera.reference or demo.camera.external,"centre_hit":str(hit.get("collider","none")),"centre_hit_m":str(hit.get("position",null))})
	print("ship-demo captured ",name)
