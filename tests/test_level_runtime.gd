extends SceneTree
## VF1: production camera views come from level manifests; gameplay uses the evaluator's poses.
var passed := 0
var failed := 0
func check(label: String, ok: bool) -> void:
	if ok: passed += 1
	else: failed += 1
	print("%s %s" % ["ok" if ok else "FAIL", label])
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(CameraDirector.VIEWS_PATH))
	check("global camera schema v3 owns no inline level views", raw.schema == "stapledons.camera.views/3" and not raw.has("levels"))
	var authored: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://art/levels/commons/layout.json"))
	var cooked: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/levels/commons/greybox.json"))
	var manifest: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/levels/commons/manifest.json"))
	check("exported greybox and manifest pin authoring layout",LevelGreybox.layout_sha256(authored)==LevelGreybox.layout_sha256(cooked) and manifest.layout_sha256==LevelGreybox.layout_sha256(authored))
	var d := CameraDirector.new()
	check("level manifests load and validate", d.errors.is_empty() and d.levels.get("bridge", {}).has("manifest"))
	check("bridge framing preserved", d.views.get("bow", {}).get("back_m") == 9.0 and d.views.get("bow", {}).get("rise_m") == 5.5 and d.views.get("bow", {}).get("pitch_deg") == -8.0)
	check("stage API exists", d.has_method("stage_at") and d.has_method("stage_view"))
	if d.has_method("stage_at"):
		var stage: Dictionary = d.call("stage_at", "bridge", Vector3(0,82,-13))
		check("bridge deck resolved from manifest", stage.get("id") == "deck")
		var v: Dictionary = d.call("stage_view", "bridge", Vector3(0,82,-13), "bow")
		check("stage view matches approved bridge", v.get("yaw_deg") == 270.0 and v.get("billboard") == "upright")
	check("height-aware stage pose API exists", d.has_method("stage_pose"))
	if d.has_method("stage_pose"):
		var v := {"yaw_deg":270.0,"pitch_deg":-8.0,"back_m":9.0,"rise_m":5.5}
		for height in [57.0,61.0,66.0]:
			var foot := Vector3(25,height,-5)
			var normal: Transform3D = d.call("stage_pose",v,foot,false)
			var clamped: Transform3D = d.call("stage_pose",v,foot,true)
			check("raised pose matches evaluator at %s" % height, normal.is_equal_approx(LevelMetrics.pose(v,foot)))
			check("ceiling clamp matches evaluator at %s" % height, clamped.is_equal_approx(LevelMetrics.pose(v,foot,true)))
			check("clamp yaw never turns at %s" % height, absf(wrapf(CameraDirector.yaw_pitch(normal).x-CameraDirector.yaw_pitch(clamped).x,-PI,PI))<1e-7)
	var lift: Node = load("res://demos/ship_demo_lift.gd").new()
	check("lift supports explicit skip and data-driven stops", lift.has_method("skip") and lift.has_method("load_stops"))
	if lift.has_method("load_stops"):
		check("shipped lift stops load", lift.call("load_stops", "res://assets/levels/lift.json"))
		check("lift uses approved 6 m/s and 0.8 s transfers", lift.get("speed_mps") == 6.0 and lift.get("transfer_seconds") == 0.8)
	lift.platform.free();lift.free()
	test_bad_sources(raw)
	await test_playable_stage_camera()
	print("level-runtime: %d passed, %d failures" % [passed, failed])
	quit(1 if failed else 0)

func _write_json(path: String, doc: Variant) -> void:
	FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(doc))
func test_bad_sources(raw: Dictionary) -> void:
	var dir := "user://vf_level_runtime"
	DirAccess.make_dir_recursive_absolute(dir)
	var file := dir+"/camera.json";var index := dir+"/index.json"
	var data:=raw.duplicate(true);data.level_manifest_index=index
	_write_json(file,data)
	for value in [null,{"schema":"stapledons.level.index/1","levels":[]},{"schema":"stapledons.level.index/1","levels":{"bridge":"user://missing_level_manifest.json"}}]:
		_write_json(index,value)
		var camera:=CameraDirector.new(null,file)
		check("malformed/missing manifest index rejected (%s)" % [value],not camera.errors.is_empty())
	var bad: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/levels/bridge/manifest.json"))
	for invalid in ["invalid",[]]:
		var malformed:=bad.duplicate(true);malformed.camera=invalid
		check("nested camera metadata rejected (%s)" % [invalid],not LevelSchema.validate(malformed).is_empty())
	var empty_clamp:=bad.duplicate(true);empty_clamp.stages[0].views[0].ceiling_clamp={}
	check("empty ceiling clamp rejected",not LevelSchema.validate(empty_clamp).is_empty())
	bad.routes[0].from="deck/missing_surface"
	_write_json(dir+"/bad.json",bad)
	_write_json(index,{"schema":"stapledons.level.index/1","levels":{"bridge":dir+"/bad.json"}})
	check("manifest route referencing a missing surface rejected",not CameraDirector.new(null,file).errors.is_empty())
func test_playable_stage_camera() -> void:
	var demo: Node=load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options={"stars":false,"background":false,"sound":false,"sky_state":"rest"}
	root.add_child(demo);await process_frame;await physics_frame;await physics_frame
	demo.auto=false;demo.journey_auto_tick=false
	check("production Commons installed in real scene",demo.ready_ok and demo.level_runtime!=null)
	var original: Array=demo.commons.original_visuals
	check("bridge keeps original Commons batching",original.all(func(n: MeshInstance3D)->bool:return n.visible) and (demo.commons.chunk_groups as Array).all(func(n:Node3D)->bool:return not n.visible))
	var old_faces:=0;var new_faces:=0;var chunks:=0;var materials_ok:=true;var floor_opaque:=true;var uv_complete:=true
	for source: MeshInstance3D in original:old_faces+=source.mesh.get_faces().size()/3
	for group: Node3D in demo.commons.chunk_groups:
		for mesh: MeshInstance3D in group.get_children():
			chunks+=1;new_faces+=mesh.mesh.get_faces().size()/3
			materials_ok=materials_ok and mesh.mesh.surface_get_material(0)==original[0].mesh.surface_get_material(0)
			var arrays:=mesh.mesh.surface_get_arrays(0)
			uv_complete=uv_complete and arrays[Mesh.ARRAY_TEX_UV].size()==arrays[Mesh.ARRAY_VERTEX].size()
			if str(mesh.name).contains("floor_"):floor_opaque=floor_opaque and not mesh.is_in_group(CameraDirector.OCCLUDER_GROUP)
	check("temporary adapter preserves source triangles",old_faces==new_faces and old_faces>20000)
	check("temporary adapter preserves atlas and UV coverage",materials_ok and uv_complete)
	check("floors remain opaque and chunks bounded",floor_opaque and chunks>1 and chunks<64)
	var director: CameraDirector=demo.director
	demo.active_level=1;demo.walk=demo.walk_lower;demo.avatar_pos=Vector3(24,57,-3)
	director.zoom_preset=false;director.has_pose=false;director.set_motion("reduced")
	var ceiling:=StaticBody3D.new();var shape:=CollisionShape3D.new();var box:=BoxShape3D.new()
	box.size=Vector3(2,.4,2);shape.shape=box;ceiling.add_child(shape);ceiling.position=Vector3(24,61,-3);demo.geometry.add_child(ceiling)
	await physics_frame;await physics_frame
	director.advance(0.016)
	check("actual overhead collider selects clamp",director.ceiling_blend==1.)
	check("runtime clamp eye has independent authored offset",director.pose.origin.distance_to(Vector3(24,59.2,6.5))<.001)
	check("runtime clamp preserves Bow yaw",absf(wrapf(CameraDirector.yaw_pitch(director.pose).x-deg_to_rad(270.),-PI,PI))<.00001)
	ceiling.queue_free();await physics_frame;await physics_frame
	director.advance(.016)
	check("leaving actual overhang restores normal camera",director.ceiling_blend==0. and director.pose.origin.distance_to(Vector3(24,62.5,6))<.001)
	director.set_motion("full");ceiling=StaticBody3D.new();shape=CollisionShape3D.new();shape.shape=box;ceiling.add_child(shape);ceiling.position=Vector3(24,61,-3);demo.geometry.add_child(ceiling)
	await physics_frame;await physics_frame
	director.advance(.05)
	check("full motion eases into clamp",director.ceiling_blend>0. and director.ceiling_blend<1.)
	for i in 10:director.advance(.05)
	check("full motion settles at authored clamp",director.ceiling_blend==1.)
	for stage: Dictionary in director.levels.commons.manifest.stages:
		demo.avatar_pos=ShipFrame.gltf_from_structure(stage.spawn);director.has_pose=false;director.advance(.016)
		check("real stage %s spawn stays on its floor" % stage.id,demo.walk_lower.is_walkable_near(demo.avatar_pos))
		check("real stage %s selects fixed player view" % stage.id,demo.active_stage_id()==stage.id and director.view_id in ["bow","astern"])
	for route: Dictionary in demo.level_runtime.layout.routes:
		if not route.kind in ["ladder","hatch"]:continue
		demo.avatar_pos=LevelGreybox.route_end(route,"from");director.advance(0.)
		check("%s E transfer arrives on walk" % route.id,demo.use_nearest() and demo.walk_lower.is_walkable_near(demo.avatar_pos) and demo.avatar_pos.distance_to(LevelGreybox.route_end(route,"to"))<.1)
		check("%s return transfer arrives on walk" % route.id,demo.use_nearest() and demo.walk_lower.is_walkable_near(demo.avatar_pos) and demo.avatar_pos.distance_to(LevelGreybox.route_end(route,"from"))<.1)
	demo.avatar_pos=Vector3(34,57,-6)
	check("court auto-walk uses the caller's floor",demo.walk_to("navigation") and Array(demo.consoles.walking).all(func(p: Vector3)->bool:return absf(p.y-57.)<.1))
	demo.consoles.cancel_walk();demo.avatar_pos=Vector3(34,61,-6)
	check("raised auto-walk requires the authored route first",not demo.walk_to("navigation"))
	# Both golden samples are actual supported stage poses; clamp has a real overhead surface.
	demo.avatar_pos=Vector3(34,57,-6);director.set_motion("reduced");director.has_pose=false;director.deck_view="bow";director.advance(.016)
	check("golden clamp specimen is supported and overhead-triggered",demo.walk_lower.is_walkable_near(demo.avatar_pos) and director.ceiling_blend==1.)
	var space: PhysicsDirectSpaceState3D=demo.camera.get_world_3d().direct_space_state
	var pole:=PhysicsRayQueryParameters3D.create(director.pose.origin,director.pose.origin+Vector3(0,0,-120));pole.hit_back_faces=true
	check("golden clamp specimen has a physically open pole",space.intersect_ray(pole).is_empty())
	demo.avatar_pos=Vector3(26,66,-12);director.has_pose=false;director.advance(.016)
	check("golden raised specimen stands on gantry",demo.walk_lower.is_walkable_near(demo.avatar_pos) and demo.active_stage_id()=="gantry" and director.ceiling_blend==0.)
	demo.set_camera_motion("full");demo.lift.reset();demo.active_level=0;demo.walk=demo.walk_bridge;demo.avatar_pos=Vector3(8,82,-4.8)
	var aft_key:=InputEventKey.new();aft_key.keycode=KEY_9;aft_key.physical_keycode=KEY_9;aft_key.pressed=true
	demo._unhandled_input(aft_key);director.advance(1.)
	check("real key selects Astern before reduced ride",director.deck_view=="astern")
	demo.set_camera_motion("reduced")
	check("reduced ride selects Commons Bow default",demo.lift.board() and demo.active_level==1 and director.deck_view=="bow" and director.view_id=="bow")
	demo.set_camera_motion("full");check("mid-ride reduced motion boards",demo.lift.board())
	demo.lift.advance(1.0);demo.set_camera_motion("reduced")
	check("enabling reduced motion completes current lift ride",not demo.lift.travelling() and demo.active_level==0 and director.view_id=="bow")
	demo.queue_free();await process_frame
