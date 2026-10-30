extends SceneTree
## Review-only moving evidence: actual fixed court Astern/rest camera, deterministic civilian clock.
## godot --path . --script tools/commons_civic_motion.gd [-- --config <json> --out <dir>]
## 64 frames /8fps =8seconds. Run on the coordinated GPU slot; no encoding or publication.
const CONFIG:="res://art/commons-grown-pilot/placements.json"
const OUT:="res://renders/view-finish/commons-grown-motion"
const PX:=Vector2i(960,540)
var demo:Node
func _initialize()->void:_run.call_deferred()
func _arg(key:String,fallback:String)->String:
 var args:=OS.get_cmdline_user_args();var i:=args.find(key)
 return args[i+1] if i>=0 and i+1<args.size() else fallback
func _run()->void:
 var config:=_arg("--config",CONFIG);var out:=_arg("--out",OUT);var doc:=LevelEval.load_doc(config)
 if doc.is_empty():_fail("missing grown config");return
 var configs:Array=[config];configs.append_array(doc.get("base_configs",[]));configs.append_array(doc.get("extra_art",[]))
 var inputs:Array=[]
 for path:String in configs:
  var data:=LevelEval.load_doc(path);var source:=str(data.get("source_glb",""))
  if not source.begins_with("res://"):source=path.get_base_dir().path_join(source)
  if data.is_empty() or not FileAccess.file_exists(source) or FileAccess.get_sha256(source)!=str(data.get("source_sha256","")):_fail("source pin mismatch: "+path);return
  inputs.append({"config":path,"config_sha256":FileAccess.get_sha256(path),"source":source,"source_sha256":FileAccess.get_sha256(source)})
 root.size=PX;root.content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT
 root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_KEEP;root.content_scale_size=PX
 demo=load("res://demos/ship_geometry_demo.tscn").instantiate();demo.setup_options={"size":PX,"sky_state":"rest","sound":false}
 root.add_child(demo);await process_frame
 if not demo.ready_ok:_fail("ship did not build");return
 demo.auto=false;demo.journey_auto_tick=false;demo.ship_hud.visible=false
 for path:String in doc.get("base_configs",[]):
  var base:Dictionary=load("res://demos/commons_art_pilot.gd").install(demo,path)
  if not base.ok:_fail("base install: "+str(base.errors));return
  for id:String in LevelEval.load_doc(path).get("replace_markers",[]):
   var marker:Node3D=demo.geometry.find_child(id,true,false)
   if marker==null:_fail("missing replacement marker: "+id);return
   marker.visible=false
   if marker is CollisionObject3D:marker.collision_layer=0;marker.collision_mask=0
 var pilot:Dictionary=load("res://demos/commons_civic_pilot.gd").install(demo,config)
 if not pilot.ok:_fail("civic install: "+str(pilot.errors));return
 var life:Node=pilot.node.find_child("CommonsLifePilot",true,false)
 if life==null or not life.has_method("pose_at"):_fail("missing resident clock");return
 var foot:=ShipFrame.gltf_from_structure([26,4,57.025])
 if not demo.walk_lower.is_walkable_near(foot):_fail("court camera point lacks existing WALK support");return
 demo.active_level=1;demo.walk=demo.walk_lower;demo.avatar_pos=foot;demo.camera_mode="player";demo.captain_yaw=-PI*.5
 demo.camera_motion="normal";demo.director.release();demo.director.zoom_preset=false;demo.director.set_motion("reduced")
 demo.director.deck_view="astern";demo.director.mapping_view="astern";demo.director.has_pose=false
 for frame in 20:demo._process(1./60.);demo.avatar_pos=foot
 demo.director.advance(0.);demo._sync_observer();demo.set_process(false)
 life.set_reduced_motion(false);life.set_process(false);life.pose_at(0.)
 var camera:Transform3D=demo.camera.global_transform;var eye:Vector3=camera.origin
 if demo.active_stage_id()!="court" or demo.director.view_id!="astern":_fail("actual court Astern camera not selected");return
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
 FileAccess.open(out.path_join("motion.json"),FileAccess.WRITE).store_string(JSON.stringify({"status":"capturing","frames":[]}))
 var frames:Array=[];var sums:=PackedStringArray()
 for frame in 64:
  var time:=float(frame)/8.;life.pose_at(time)
  await process_frame;await RenderingServer.frame_post_draw
  if not demo.camera.global_transform.is_equal_approx(camera):_fail("camera moved at frame%d"%frame);return
  var image:=root.get_texture().get_image();var file:="frame_%03d.png"%frame;var path:=out.path_join(file)
  if image==null or image.is_empty() or image.save_png(path)!=OK:_fail("missing frame "+file);return
  var hash:=FileAccess.get_sha256(path)
  frames.append({"source":path,"file":file,"frame":frame,"time":time,"sha256":hash});sums.append(hash+"  "+file)
 if frames.all(func(row:Dictionary)->bool:return row.sha256==frames[0].sha256):_fail("all64 rendered frames are identical");return
 for input:Dictionary in inputs:
  if FileAccess.get_sha256(input.config)!=input.config_sha256 or FileAccess.get_sha256(input.source)!=input.source_sha256:_fail("capture inputs changed during rendering");return
 var manifest:={"status":"review-only resident motion; actual fixed player camera","fps":8,"duration_seconds":8,"pixels":[PX.x,PX.y],"sky":"rest","reduced_motion":false,"local_clock":"pose_at(frame/8)","stage":"court","view":"astern","foot_ship_m":[26,4,57.025],"eye_gltf_m":[eye.x,eye.y,eye.z],"camera":str(camera),"inputs":inputs,"life_helper_sha256":FileAccess.get_sha256("res://demos/commons_life_pilot.gd"),"civic_helper_sha256":FileAccess.get_sha256("res://demos/commons_civic_pilot.gd"),"frames":frames}
 FileAccess.open(out.path_join("motion.json"),FileAccess.WRITE).store_string(JSON.stringify(manifest,"  ")+"\n")
 FileAccess.open(out.path_join("frames.sha256"),FileAccess.WRITE).store_string("\n".join(sums)+"\n")
 print("commons-civic-motion: 64 frames, fixed actual court Astern camera,8fps/8seconds")
 demo.queue_free();await process_frame;quit()
func _fail(message:String)->void:
 printerr("commons-civic-motion: FAIL "+message);quit(1)
