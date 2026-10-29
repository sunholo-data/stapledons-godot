extends "res://tools/level_capture.gd"
## D-133 bounded art study: matched actual player-camera before/after, no production install.
const PILOT_CONFIG:="res://art/commons-lived-in-pilot/placements.json"
const PILOT_OUT:="res://renders/view-finish/commons-lived-in-pilot"
var pilot:Dictionary={}
var pilot_config:Dictionary={}
var replaced:Array=[]

func _run()->void:
 pilot_config=LevelEval.load_doc(PILOT_CONFIG)
 if pilot_config.is_empty():printerr("commons-pilot-review: missing config");quit(1);return
 var source:String=PILOT_CONFIG.get_base_dir().path_join(str(pilot_config.source_glb))
 if FileAccess.get_sha256(source)!=str(pilot_config.get("source_sha256","")):
  printerr("commons-pilot-review: source pin mismatch");quit(1);return
 var points:Array=pilot_config.get("review_points",[])
 if points.is_empty():printerr("commons-pilot-review: missing supported review points");quit(1);return
 root.size=PX;root.content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT
 root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_KEEP;root.content_scale_size=PX
 DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PILOT_OUT))
 demo=load("res://demos/ship_geometry_demo.tscn").instantiate()
 demo.setup_options={"size":PX,"sky_state":"rest","sound":false}
 root.add_child(demo);await process_frame
 demo.auto=false;demo.journey_auto_tick=false;demo.ship_hud.visible=false
 pilot=load("res://demos/commons_art_pilot.gd").install(demo,PILOT_CONFIG)
 if not pilot.ok:printerr("commons-pilot-review: ",pilot.errors);quit(1);return
 for id:String in pilot_config.get("replace_markers",[]):
  var marker:Node=demo.geometry.find_child(id,true,false)
  if marker==null:printerr("commons-pilot-review: missing replacement marker ",id);quit(1);return
  replaced.append(marker)
 var names:Array=[];var records:Array=[];var bad:Array=[]
 for sky:String in ["rest","cruise","stop"]:
  _pilot_active(false)
  if sky=="stop":
   if not _prepare_stop():bad.append("real guided stop not reached");continue
  elif not demo.set_sky_state(sky):bad.append("sky "+sky);continue
  for point:Dictionary in points:
   var foot:=ShipFrame.gltf_from_structure(point.ship_m)
   if not demo.walk_lower.is_walkable_near(foot) or demo.director.stage_at("commons",foot).is_empty():
    bad.append("unsupported actual player point "+str(point.id));continue
   for view:String in ["bow","astern"]:
    var before_camera:=Transform3D()
    for variant:String in ["before","after"]:
     _pilot_active(variant=="after")
     demo.consoles.cancel_walk();demo.active_level=1;demo.walk=demo.walk_lower;demo.avatar_pos=foot
     demo.camera_mode="player";demo.captain_yaw=-PI*.5
     demo.director.release();demo.director.zoom_preset=false;demo.director.set_motion("reduced")
     demo.director.deck_view=view;demo.director.mapping_view=view;demo.director.has_pose=false
     for frame in 20:demo._process(1./60.);demo.avatar_pos=foot
     demo.director.advance(0.);demo._sync_observer()
     for frame in 6:await process_frame
     await RenderingServer.frame_post_draw
     var image:=root.get_texture().get_image()
     var name:="%s_%s_%s_%s"%[point.id,view,sky,variant]
     var path:=PILOT_OUT.path_join(name+".png")
     image.save_png(path);names.append(name)
     if _variance(image)<1e-5:bad.append("blank "+name)
     if variant=="before":before_camera=demo.camera.global_transform
     elif not demo.camera.global_transform.is_equal_approx(before_camera):bad.append("mismatched player cameras "+name)
     if point.get("clamped",false) and demo.director.ceiling_blend<.95:bad.append("missing actual clamp "+name)
     records.append({"name":name,"variant":variant,"view":demo.director.view_id,"stage":demo.active_stage_id(),"foot_ship_m":point.ship_m,"eye_gltf_m":[demo.camera.position.x,demo.camera.position.y,demo.camera.position.z],"camera":str(demo.camera.global_transform),"clamp_share":demo.director.ceiling_blend,"sky":sky,"real_guided_stop":sky=="stop","brightness_stops":demo.brightness_stops,"hud":false,"pixels":[PX.x,PX.y],"image_sha256":FileAccess.get_sha256(path)})
     print("commons-pilot-shot: ",name)
 var expected:=points.size()*2*3*2
 if names.size()!=expected:bad.append("expected %d frames, got%d"%[expected,names.size()])
 FileAccess.open(PILOT_OUT.path_join("review.json"),FileAccess.WRITE).store_string(JSON.stringify({"status":"review-only art pilot; no full-level approval or propagation","source_sha256":pilot_config.source_sha256,"config_sha256":FileAccess.get_sha256(PILOT_CONFIG),"frames":records,"errors":bad},"  ")+"\n")
 var sums:=PackedStringArray()
 for row:Dictionary in records:sums.append("%s  %s.png"%[row.image_sha256,row.name])
 FileAccess.open(PILOT_OUT.path_join("frames.sha256"),FileAccess.WRITE).store_string("\n".join(sums)+"\n")
 _sheet(PILOT_OUT,names)
 for error:String in bad:printerr("commons-pilot-review: FAIL ",error)
 print("commons-pilot-review: %d frames, %d failures"%[names.size(),bad.size()])
 demo.queue_free();await process_frame;quit(0 if bad.is_empty() else 1)

func _pilot_active(active:bool)->void:
 if pilot.is_empty():return
 pilot.node.visible=active
 for body:CollisionObject3D in pilot.colliders:body.collision_layer=1 if active else 0;body.collision_mask=1 if active else 0
 for marker:Node3D in replaced:
  marker.visible=not active
  if marker is CollisionObject3D:marker.collision_layer=0 if active else 1;marker.collision_mask=0 if active else 1
