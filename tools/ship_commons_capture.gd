extends SceneTree
var demo: Node
var out:="res://renders/ship_commons/painted"
var shots:=[]
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	root.size=Vector2i(1280,720)
	demo=load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options={"commons":false,"sky_state":"cruise"};root.add_child(demo)
	await process_frame
	var kit: Dictionary=load("res://demos/ship_commons.gd").install(demo)
	if kit.is_empty():quit(1);return
	demo.commons=kit
	demo.auto=false
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var bridge_eye:=Vector3(19,83.7,-7)
	if not demo.walk_bridge.is_walkable(bridge_eye-Vector3.UP*1.7):
		push_error("Commons bridge observer not reachable");quit(1);return
	demo.avatar_pos=bridge_eye-Vector3.UP*1.7;demo.camera_mode="Commons bridge standing eye"
	demo.camera.pullback=0.;demo.camera.position=bridge_eye;demo.camera.look_at(Vector3(33,65,-16));demo._sync_observer()
	await _shot("bridge_overlook",false)
	demo.avatar_pos=Vector3(8,82,-4.8);demo.set_preset("bridge")
	if not demo.lift.board():quit(1);return
	demo.lift.advance(.81);demo.lift.advance(5.5);await _shot("mid_lift",false)
	demo.lift.advance(5.51);demo.lift.advance(.81)
	var views: Array=kit.manifest.player_views.duplicate()
	views.append({"name":"pavilion_side","eye_ship_m":[35,10,58.725],"target_ship_m":[26,10,61.2]})
	views.append({"name":"pavilion_back","eye_ship_m":[26,18,58.725],"target_ship_m":[26,10,61.2]})
	for view in views:
		var eye:=_vec(view.eye_ship_m);var target:=_vec(view.target_ship_m)
		demo.avatar_pos=eye-Vector3.UP*1.7
		demo.camera_mode="Commons standing eye";demo.camera.pullback=0.;demo.camera.reference=false
		demo.camera.position=eye;demo.camera.look_at(target);demo._sync_observer()
		await _shot(view.name,false)
	demo.set_preset("overview");await _shot("external_diagnostic",true)
	var f:=FileAccess.open(out+"/manifest.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"stage":kit.manifest.stage,"observer":"inside physical eye except explicitly external diagnostic","sky":"frozen simulation-derived cruise; shared observer","GR":"not implemented","shots":shots},"  "))
	print("ship-commons-capture: OK");quit()
func _vec(v: Array) -> Vector3:return Vector3(v[0],v[2],-v[1])
func _shot(name: String, diagnostic: bool) -> void:
	for i in 5:await process_frame
	demo.sky.update_exposure()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out+"/"+name+".png")
	shots.append({"name":name,"diagnostic":diagnostic,"eye_gltf_m":[demo.camera.position.x,demo.camera.position.y,demo.camera.position.z],"fov":demo.camera.fov,"inside_bubble":demo.camera.position.length()<100.,"walkable":demo.walk.is_walkable(demo.avatar_pos),"lift_state":demo.lift.state})
	print("Commons captured ",name)
