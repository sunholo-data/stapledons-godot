extends SceneTree
## D-121 original desk operator placement correction: unchanged furniture/held sprites, corrected physical working points, real Bow/Astern, before/after.
## GPU window: godot --path . --script tools/bridge_operator_review.gd
var demo: Node
var out := "res://renders/view-finish/operator-placement"
var rows := []
var placement := {}
const DT := 1.0 / 60.0
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	if "--sheet-only" in OS.get_cmdline_user_args():
		_sheet()
		quit()
		return
	root.size = Vector2i(1280,720)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	root.content_scale_size = root.size
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	demo = load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options = {"size":root.size,"sky_state":"rest"}
	root.add_child(demo)
	await process_frame
	if not demo.ready_ok:
		quit(1); return
	demo.auto = false
	demo.journey_auto_tick = false
	demo.captain_anim_auto = false
	demo.ship_hud.visible = false
	demo.set_process(false) # keep real colliders active for capsule checks
	placement = JSON.parse_string(FileAccess.get_file_as_string("res://art/view-finish-v1/bridge-operator-contact.json"))
	for station in ["voyage","crew"]:
		for view in ["bow","astern"]:
			for variant in ["current","corrected"]:
				var point: Array = placement.stations[station]["original_use_ship_m" if variant=="current" else "corrected_use_ship_m"]
				demo.avatar_pos=Vector3(float(point[0]),82.,-float(point[1]))
				demo.director.walk(view)
				for k in 240:demo._process(DT)
				var a := CaptainAnim.new()
				var o := {}
				for k in 90:
					o=a.step({"station":"use_low","face_dir":Vector3(0,0,-1),"view_yaw":demo.director.walk_yaw()},DT)
				demo.avatar.show_anim(o)
				if variant=="corrected":
					var source: ShaderMaterial=demo.avatar.material_override
					var working:=ShaderMaterial.new()
					working.shader=load("res://art/view-finish-v1/captain_work_lean.gdshader")
					for parameter: Dictionary in source.shader.get_shader_uniform_list():
						working.set_shader_parameter(parameter.name,source.get_shader_parameter(parameter.name))
					working.set_shader_parameter("work_lean_deg",15.0)
					demo.avatar.material_override=working
				for k in 3:await process_frame
				await RenderingServer.frame_post_draw
				var name := "%s_%s_%s" % [station,view,variant]
				var img := root.get_texture().get_image()
				img.save_png(out.path_join(name+".png"))
				var mid: Vector2=demo.camera.unproject_position(demo.avatar_pos+Vector3.UP*.88)
				var crop:=img.get_region(Rect2i(Vector2i(mid)-Vector2i(160,160),Vector2i(320,320)))
				crop.resize(640,640,Image.INTERPOLATE_NEAREST)
				crop.save_png(out.path_join(name+"_detail.png"))
				rows.append({"name":name,"station":station,"view":view,"variant":variant,"display_aid_stops":demo.brightness_stops,"display_aid_multiplier":pow(2.,demo.brightness_stops),"world":"rest","hud":false,"foot_gltf_m":[demo.avatar_pos.x,demo.avatar_pos.y,demo.avatar_pos.z],"render_foot_gltf_m":[demo.avatar.position.x,demo.avatar.position.y,demo.avatar.position.z],"walkable":demo.walk_bridge.is_walkable(demo.avatar_pos),"shown":demo.avatar.shown,"camera":str(demo.camera.global_transform),"added_furniture":false,"work_lean_deg":15.0 if variant=="corrected" else 0.0})
	var f := FileAccess.open(out.path_join("review.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"status":"operator placement correction; original desks only; not installed in game","size":[1280,720],"frames":rows},"  "))
	print("bridge-operator-review: %d matched frames; physical operator points corrected, original desks retained" % rows.size())
	_sheet()
	demo.queue_free()
	for k in 3: await process_frame
	quit()

func _sheet() -> void:
	var sheet := Image.create(1280,640,false,Image.FORMAT_RGBA8)
	for row in 2:
		var station: String = ["voyage","crew"][row]
		for col in 4:
			var view: String = "astern" if col<2 else "bow"
			var variant: String = "current" if col%2==0 else "corrected"
			var img := Image.load_from_file(out.path_join("%s_%s_%s_detail.png" % [station,view,variant]))
			img.convert(Image.FORMAT_RGBA8)
			img.resize(320,320,Image.INTERPOLATE_LANCZOS)
			sheet.blit_rect(img,Rect2i(0,0,320,320),Vector2i(col*320,row*320))
	sheet.save_png(out.path_join("contact_sheet.png"))
