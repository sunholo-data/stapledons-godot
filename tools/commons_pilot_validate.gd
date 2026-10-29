extends SceneTree
## Actual pilot placement guards: source pin, floor support, routes, captain and sky clearance.
const CONFIG:="res://art/commons-lived-in-pilot/placements.json"
var failures:Array=[]
var passed:=0
var demo:Node
var pilot:Dictionary
func _initialize()->void:_run.call_deferred()
func check(label:String,ok:bool)->void:
 if ok:passed+=1
 else:failures.append(label)
 print("%s %s"%["ok" if ok else "FAIL",label])
func _run()->void:
 root.size=LevelMetrics.PX;root.content_scale_mode=Window.CONTENT_SCALE_MODE_VIEWPORT
 root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_KEEP;root.content_scale_size=LevelMetrics.PX
 var doc:=LevelEval.load_doc(CONFIG)
 var source:=CONFIG.get_base_dir().path_join(str(doc.get("source_glb","")))
 check("authored source pin matches real GLB",FileAccess.get_sha256(source)==str(doc.get("source_sha256","")))
 demo=load("res://demos/ship_geometry_demo.tscn").instantiate()
 demo.setup_options={"stars":false,"background":false,"sky_state":"rest","sound":false,"size":LevelMetrics.PX}
 root.add_child(demo);await process_frame
 demo.auto=false;demo.journey_auto_tick=false;demo.active_level=1;demo.walk=demo.walk_lower
 demo._process(0.);demo.set_process(false)
 pilot=load("res://demos/commons_art_pilot.gd").install(demo,CONFIG)
 check("real authored pilot installs atomically",pilot.ok)
 if not pilot.ok:printerr(pilot.errors);quit(1);return
 for id:String in doc.get("replace_markers",[]):
  var marker:Node3D=demo.geometry.find_child(id,true,false)
  check("replacement marker exists "+id,marker!=null)
  if marker!=null:
   marker.visible=false
   if marker is CollisionObject3D:marker.collision_layer=0;marker.collision_mask=0
 await physics_frame;await physics_frame
 for name:String in pilot.placements:
  var foot:Vector3=pilot.placements[name].global_position
  var floor_y:float=demo.walk_lower.height_at_near(foot.x,foot.z,57.)
  check(name+" root is on existing lower WALK",not is_nan(floor_y) and absf(foot.y-floor_y)<.035 and demo.walk_lower.is_walkable_near(foot))
 for point:Dictionary in doc.review_points:
  var foot:=ShipFrame.gltf_from_structure(point.ship_m)
  check(str(point.id)+" actual captain capsule is clear of pilot props",pilot_hits(foot).is_empty())
  check(str(point.id)+" is on existing WALK",demo.walk_lower.is_walkable_near(foot))
  demo.avatar_pos=foot
  for view:String in ["bow","astern"]:
   demo.director.release();demo.director.zoom_preset=false;demo.director.set_motion("reduced")
   demo.director.deck_view=view;demo.director.mapping_view=view;demo.director.has_pose=false
   demo.camera_mode="player";demo._process(0.);demo.avatar_pos=foot;demo.director.advance(0.)
   var clear:Dictionary=demo.director.clear_after_fades(demo.camera.global_transform,foot)
   check(str(point.id)+" "+view+" keeps the captain and forward pole clear",clear.captain and clear.pole_ray)
   if point.get("clamped",false):check(str(point.id)+" real clamp remains engaged",demo.director.ceiling_blend>=.95)
  demo.avatar_pos=foot;demo.consoles.cancel_walk()
  var route:bool=demo.walk_to("navigation")
  var hits:Array=[]
  for frame in 1200:
   if demo.consoles.walking.is_empty():break
   demo.consoles._advance_walk(.05)
   hits.append_array(pilot_hits(demo.avatar_pos))
  if not route or not hits.is_empty() or demo.avatar_pos.distance_to(Vector3(8,57,-4.8))>=.1:
   print("pilot-route-detail ",point.id," accepted=",route," end=",demo.avatar_pos," new-solids=",hits.map(func(hit:Dictionary)->String:return str(hit.collider.name)))
  check(str(point.id)+" real auto-walk returns to lift without crossing new solids",route and demo.consoles.walking.is_empty() and hits.is_empty() and demo.avatar_pos.distance_to(Vector3(8,57,-4.8))<.1)
 var layout:=LevelEval.load_doc(LevelEval.doc_path("commons"))
 for route:Dictionary in layout.routes:
  if route.get("kind") not in ["stairs","ladder","hatch"]:continue
  for end:String in ["from","to"]:
   var foot:=LevelGreybox.route_end(route,end)
   check(str(route.id)+" "+end+" approach stays clear of new solids",pilot_hits(foot).is_empty())
 var metrics:=LevelMetrics.new(demo,layout,demo.walk_lower).measure()
 var errors:=LevelMetrics.failures(metrics,LevelEval.thresholds("commons"))
 for error:Variant in errors:check("layout threshold "+str(error),false)
 check("unchanged Commons layout thresholds pass with pilot",errors.is_empty())
 FileAccess.open("res://build/commons-pilot-validation.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"failures":failures,"metrics":metrics},"  ")+"\n")
 demo.queue_free();await process_frame
 print("commons-pilot-validate: %d passed, %d failures"%[passed,failures.size()]);quit(0 if failures.is_empty() else 1)
func pilot_hits(foot:Vector3)->Array:
 var capsule:=CapsuleShape3D.new();capsule.radius=.35;capsule.height=1.8
 var query:=PhysicsShapeQueryParameters3D.new();query.shape=capsule;query.margin=.0
 query.transform=Transform3D(Basis.IDENTITY,foot+Vector3.UP*.91)
 return demo.camera.get_world_3d().direct_space_state.intersect_shape(query,64).filter(func(hit:Dictionary)->bool:return str(hit.collider.name).begins_with("PilotSolid_"))
