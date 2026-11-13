extends SceneTree
## D-132 on the R3-COMMS-V2 desks (7ae): actual Walk-to/feet correction along each desk's own facing,
## capsule/route guards, no graphic extensions. The facing comes from the desk node's basis in the loaded
## scene (the asset), never from the manifest's use_m or this test's JSON, so each source checks the others.
var passed:=0
var failed:=0
func _initialize() -> void:_run.call_deferred()
func _run() -> void:
	var installed := "--source-study" not in OS.get_cmdline_user_args()
	var doc: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://art/view-finish-v1/bridge-operator-contact.json"))
	if not check("contact record is schema 2 (R3-COMMS-V2 desks)",doc.get("schema","")=="stapledons.bridge-operator-contact/2"):
		print("bridge-operator-contact: %d passed, %d failures" % [passed,failed]);quit(1);return
	var demo: Node=load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options={"stars":false,"background":false,"sky_state":"rest","sound":false}
	root.add_child(demo)
	await process_frame;await physics_frame;await physics_frame
	demo.auto=false;demo.journey_auto_tick=false;demo.set_process(false)
	check("real colliders stay enabled",demo.process_mode!=Node.PROCESS_MODE_DISABLED)
	# 7ae: the runtime reads use_m from the manifest, the deck evaluator and the Blender generators from the layout; keep them one point.
	var layout_path: String="res://"+str(demo.manifest.get("deck_layout",{}).get("layout",""))
	var props: Dictionary=(JSON.parse_string(FileAccess.get_file_as_string(layout_path)) if FileAccess.file_exists(layout_path) else {}).get("bridge",{}).get("props",{})
	var same:=[]
	for sid: String in ShipConsoles.STATIONS:
		var mu: Variant=demo.manifest.get("stations",{}).get(sid,{}).get("use_m")
		var lu: Variant=props.get(ShipConsoles.STATIONS[sid].walk,{}).get("use_m")
		if mu is Array or lu is Array:same.append(sid if mu is Array and lu is Array and Vector2(float(mu[0]),float(mu[1])).distance_to(Vector2(float(lu[0]),float(lu[1])))<1e-6 else "DRIFT:"+sid)
	check("manifest use_m equals the deck layout's use_m at every authored station %s" % [same],"voyage" in same and "crew" in same and not str(same).contains("DRIFT"))
	var offset: Array=doc.avatar_render_offset_m
	check("render offset stays zero",Vector3(float(offset[0]),float(offset[1]),float(offset[2])).is_zero_approx())
	check("approved working lean bounded at15 degrees",float(doc.work_lean_deg)>0. and float(doc.work_lean_deg)<=15.)
	var direction: Array=doc.work_direction_gltf
	var lean_dir:=Vector3(float(direction[0]),float(direction[1]),float(direction[2]))
	check("recorded work lean is the world bow (desks turned since R3-COMMS-V2; 7ae OQ-2)",lean_dir.distance_to(Vector3.FORWARD)<.001)
	check("head reach remains below46cm",1.754*sin(deg_to_rad(float(doc.work_lean_deg)))<.46)
	var advance:=float(doc.advance_m)
	for id: String in doc.stations:
		var s: Dictionary=doc.stations[id]
		var a: Array=s.original_use_ship_m;var b: Array=s.corrected_use_ship_m
		var old:=Vector3(float(a[0]),82.,-float(a[1]));var target:=Vector3(float(b[0]),82.,-float(b[1]))
		var expected: Vector3=target if installed else old
		check(id+(" installed working point matches physical target" if installed else " review source matches original operator point"),demo.consoles.stations[id].use.distance_to(expected)<.001)
		var desk: Node3D=demo.geometry.find_child(str(s.desk),true,false) as Node3D
		var facing:=Vector3.ZERO
		if desk!=null and str(s.desk)==ShipConsoles.STATIONS[id].walk:
			facing=-desk.global_transform.basis.x;facing.y=0.;facing=facing.normalized()
		check(id+" desk found and its facing derived from the scene",facing.length()>.99)
		var to_desk:=Vector3(desk.global_position.x-old.x,0.,desk.global_position.z-old.z) if desk!=null else Vector3.ZERO
		check(id+" original point stands the D-132 two metres from the desk, on its facing",absf(to_desk.length()-float(doc.original_from_desk_m))<.005 and to_desk.normalized().dot(facing)>cos(deg_to_rad(.5)))
		check(id+" advances real feet by measured working distance along the desk's facing",absf(old.distance_to(target)-advance)<.001 and (target-old).normalized().dot(facing)>cos(deg_to_rad(.1)))
		check(id+" corrected point supported by actual WALK/capsule radius",demo.walk_bridge.is_walkable(target))
		var position:=old
		for k in roundi(advance/.025):position=demo.walk_bridge.step(position,facing*.025)
		check(id+" actual walking reaches corrected feet",position.distance_to(target)<.001)
		var route: PackedVector3Array=demo.walk_bridge.path(demo.bridge_spawn(),target)
		check(id+" Walk-to route ends at actual corrected foot point",not route.is_empty() and route[-1].distance_to(target)<.001)
		check(id+" full 1.8m capsule clear at corrected point",capsule_clear(demo,target))
		check(id+" negative control rejects 5cm deeper body intersection",not capsule_clear(demo,target+facing*.05))
		demo.avatar_pos=target;demo._process(1./60.)
		check(id+" rendered feet equal physical feet",demo.avatar.position.distance_to(demo.avatar_pos)<.001)
		if installed:
			demo.consoles.face(id)
			check(id+" captain at the working point faces the desk",Vector3(cos(demo.captain_yaw),0.,sin(demo.captain_yaw)).dot(facing)>cos(deg_to_rad(.5)))
			var anchor: Variant=demo.manifest.stations[id].get("screen_ship_m")
			var rec: Array=s.screen_ship_m
			check(id+" screen stays in its authored housing (manifest = record = scene)",anchor is Array and Vector3(float(anchor[0]),float(anchor[1]),float(anchor[2])).distance_to(Vector3(float(rec[0]),float(rec[1]),float(rec[2])))<.001 and demo.consoles.screens[id].quad.global_position.distance_to(ShipFrame.gltf_from_structure(anchor))<.001)
			demo.consoles.focused=id
			demo.captain_anim=demo._new_captain_anim();demo._anim_pos=target
			for k in 3:demo._animate_captain(.5)
			check(id+" held work pose applies the bounded 15-degree lean",demo.avatar.shown.get("work_lean_deg",0.0)==15.0)
			var mat:=demo.avatar.material_override as ShaderMaterial
			var shipped: Variant=mat.get_shader_parameter("work_direction") if mat!=null else null
			check(id+" shipped work lean direction equals the recorded one",shipped is Vector3 and (shipped as Vector3).distance_to(lean_dir)<.001)
			check(id+" recorded lean is the measured angle off this desk (7ae OQ-2)",absf(rad_to_deg(lean_dir.angle_to(facing))-float(s.lean_off_desk_deg))<.1)
			demo.set_camera_motion("reduced")
			demo._animate_captain(.5)
			check(id+" reduced motion retains static working posture",demo.avatar.shown.get("work_lean_deg",0.0)==15.0 and demo.avatar.shown.get("effect","")=="none")
			demo.consoles.focused=""
			for k in 3:demo._animate_captain(.5)
			check(id+" leaving resets work posture",demo.avatar.shown.get("work_lean_deg",-1.0)==0.0)
			demo.set_camera_motion("full")
			# Actual E/open entry from the former in-reach position must approach before use.
			demo.avatar_pos=old;demo.consoles.face(id)
			check(id+" E starts a calm physical approach",demo.consoles.press_e() and demo.consoles.focused.is_empty() and not demo.consoles.walking.is_empty() and demo.avatar_pos.distance_to(old)<.001)
			demo.consoles.advance(.1)
			check(id+" approach moves at ordinary walking speed",demo.avatar_pos.distance_to(old)>0. and demo.avatar_pos.distance_to(old)<=ShipConsoles.WALK_SPEED_MPS*.1+.001 and demo.consoles.focused.is_empty())
			demo.consoles.cancel_walk();demo.consoles.advance(2.)
			check(id+" taking over movement cancels pending console open",demo.consoles.focused.is_empty())
			check(id+" approach accepts escape cancellation",demo.consoles.use(id,"open") and demo.consoles.escape() and demo.consoles.walking.is_empty())
			demo.consoles.advance(2.)
			check(id+" escape prevents deferred console open",demo.consoles.focused.is_empty())
			check(id+" open resumes real approach",demo.consoles.use(id,"open"))
			for k in 120:demo.consoles.advance(1./60.)
			check(id+" panel and contact pose wait for real working point",demo.consoles.focused==id and demo.avatar_pos.distance_to(target)<.001)
			demo.consoles.leave()
	check("no custom contact extension loaded",demo.geometry.find_children("VF_*_contact_*","",true,false).is_empty())
	demo.queue_free();await process_frame
	print("bridge-operator-contact: %d passed, %d failures" % [passed,failed])
	quit(1 if failed else 0)
func capsule_clear(demo: Node,p: Vector3) -> bool:
	var shape:=CapsuleShape3D.new();shape.radius=.35;shape.height=1.8
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape
	query.transform=Transform3D(Basis.IDENTITY,p+Vector3.UP*.91)
	return demo.camera.get_world_3d().direct_space_state.intersect_shape(query).is_empty()
func check(label: String,ok: bool) -> bool:
	if ok:passed+=1
	else:failed+=1
	print("%s %s" % ["ok" if ok else "FAIL",label])
	return ok
