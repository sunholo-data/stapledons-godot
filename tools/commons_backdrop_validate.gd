extends SceneTree
## Review-only macro pilot guards. --config <json> overrides the default; --self-test checks
## transformed-vertex negative controls without the external art kit. No GPU or production hook.
const CONFIG:="res://art/commons-backdrop-pilot/placements.json"
const RADIUS_M:=95.0
var failures:Array=[]
var passed:=0
var demo:Node
var pilots:Array=[]
var floor_exclusions:Array[RID]=[]
func _initialize()->void:_run.call_deferred()
func check(label:String,ok:bool)->void:
 if ok:passed+=1
 else:failures.append(label)
 print("%s %s"%["ok" if ok else "FAIL",label])
func _run()->void:
 if OS.get_cmdline_user_args().has("--self-test"):
  await _self_test();_finish({});return
 var args:=OS.get_cmdline_user_args();var config_path:=CONFIG
 if args.has("--config") and args.find("--config")+1<args.size():config_path=args[args.find("--config")+1]
 var doc:=LevelEval.load_doc(config_path)
 check("macro config is present",not doc.is_empty())
 if doc.is_empty():_finish({});return
 var base_path:=str(doc.get("base_config","res://art/commons-lived-in-pilot/placements.json"))
 if not base_path.begins_with("res://"):base_path=config_path.get_base_dir().path_join(base_path)
 var base:=LevelEval.load_doc(base_path)
 if not _pin(base,base_path,"furniture") or not _pin(doc,config_path,"macro"):_finish({});return
 demo=load("res://demos/ship_geometry_demo.tscn").instantiate()
 demo.setup_options={"stars":false,"background":false,"sky_state":"rest","sound":false,"size":LevelMetrics.PX}
 root.size=LevelMetrics.PX;root.add_child(demo);await process_frame
 demo.auto=false;demo.journey_auto_tick=false;demo.active_level=1;demo.walk=demo.walk_lower;demo._process(0.);demo.set_process(false)
 for path:String in [base_path,config_path]:
  var installed:Dictionary=load("res://demos/commons_art_pilot.gd").install(demo,path)
  check("pilot installs atomically "+path,installed.ok)
  if not installed.ok:printerr(installed.errors);demo.queue_free();await process_frame;_finish({});return
  pilots.append(installed)
  var config:=LevelEval.load_doc(path)
  for id:String in config.get("replace_markers",[]):
   var marker:Node3D=demo.geometry.find_child(id,true,false)
   check("replacement marker exists "+id,marker!=null)
   if marker!=null:
    marker.visible=false
    if marker is CollisionObject3D:marker.collision_layer=0;marker.collision_mask=0
 await physics_frame;await physics_frame
 var envelope:Array=[]
 for i in pilots.size():
  var audit:=_mesh_envelope(pilots[i].node);envelope.append(audit)
  check("%s actual world vertices fit 95m sphere (max %.4fm, %d vertices)"%["furniture" if i==0 else "macro",audit.max_radius_m,audit.vertices],audit.vertices>0 and audit.outside==0)
  if audit.outside:print("backdrop-envelope-detail: ",audit.bad_meshes)
 var floor:Node=demo.geometry.find_child("Deck 01 top 57m",true,false)
 check("actual full Commons base floor collider exists",floor!=null)
 if floor!=null:_exclude_nonfloor(demo.geometry,floor)
 for name:String in pilots[1].placements:
  var foot:Vector3=pilots[1].placements[name].global_position
  check(name+" rests on physical existing Commons floor",floor!=null and _floor_support(foot))
 for placement:Dictionary in doc.placements:
  check(str(placement.name)+" has intentional structural collision",not placement.solid_meshes.is_empty())
 var points:Array=base.get("review_points",[]).duplicate(true)
 for point:Dictionary in doc.get("review_points",[]):
  if not points.any(func(old:Dictionary)->bool:return old.id==point.id):points.append(point)
 for point:Dictionary in points:
  var foot:=ShipFrame.gltf_from_structure(point.ship_m)
  var bridge:=str(point.get("level","commons"))=="bridge"
  demo.active_level=0 if bridge else 1;demo.walk=demo.walk_bridge if bridge else demo.walk_lower;demo._process(0.)
  check(str(point.id)+" captain capsule stays clear",_pilot_hits(foot).is_empty())
  check(str(point.id)+" retains existing WALK support",demo.walk.is_walkable_near(foot))
  for view:String in ["bow","astern"]:
   demo.avatar_pos=foot;demo.camera_mode="player";demo.director.release();demo.director.zoom_preset=false;demo.director.set_motion("reduced")
   demo.director.deck_view=view;demo.director.mapping_view=view;demo.director.has_pose=false;demo._process(0.);demo.avatar_pos=foot;demo.director.advance(0.)
   var clear:Dictionary=demo.director.clear_after_fades(demo.camera.global_transform,foot)
   check(str(point.id)+" "+view+" keeps actual captain/pole/eye clear",clear.captain and clear.pole_ray and clear.eye_free)
   if point.get("clamped",false):check(str(point.id)+" real clamp remains engaged",demo.director.ceiling_blend>=.95)
  if bridge:continue
  demo.avatar_pos=foot;demo.consoles.cancel_walk()
  var accepted:bool=demo.walk_to("navigation");var blocked:=false
  for frame in 1200:
   if demo.consoles.walking.is_empty():break
   demo.consoles._advance_walk(.05)
   if not _pilot_hits(demo.avatar_pos).is_empty():blocked=true
  check(str(point.id)+" actual return path avoids pilot solids and reaches lift",accepted and not blocked and demo.consoles.walking.is_empty() and demo.avatar_pos.distance_to(Vector3(8,57,-4.8))<.1)
 demo.active_level=1;demo.walk=demo.walk_lower;demo.avatar_pos=Vector3(26,57.025,-4);demo._process(0.)
 await physics_frame;await physics_frame
 var layout:=LevelEval.load_doc(LevelEval.doc_path("commons"))
 for route:Dictionary in layout.routes:
  if route.get("kind") not in ["stairs","ladder","hatch","exit"]:continue
  if not route.has("from_at") or not route.has("to_at"):continue
  for end:String in ["from","to"]:check(str(route.id)+" "+end+" route capsule stays clear",_pilot_hits(LevelGreybox.route_end(route,end)).is_empty())
 var metrics:=LevelMetrics.new(demo,layout,demo.walk_lower).measure()
 var errors:=LevelMetrics.failures(metrics,LevelEval.thresholds("commons"))
 for error:Variant in errors:check("unchanged layout threshold "+str(error),false)
 check("all original stage-grid head/pole/body/layout thresholds pass",errors.is_empty())
 var attribution:=_body_attribution(LevelMetrics.new(demo,layout,demo.walk_lower),layout) if not errors.is_empty() else {}
 demo.queue_free();await process_frame;_finish({"config":config_path,"config_sha256":FileAccess.get_sha256(config_path),"base_config_sha256":FileAccess.get_sha256(base_path),"source_sha256":doc.source_sha256,"envelope":envelope,"metrics":metrics,"body_attribution":attribution})
func _body_attribution(meter:LevelMetrics,layout:Dictionary)->Dictionary:
 var result:Dictionary={}
 for stage:Dictionary in layout.stages:
  if not bool(stage.get("journey",false)):continue
  for surface:Dictionary in stage.surfaces:
   for view:Dictionary in stage.views:
    var pairs:Dictionary={}
    var clamp_spec:Dictionary=view.get("ceiling_clamp",LevelCamera.CLAMP)
    for foot:Vector3 in meter.samples(stage,surface,float(layout.get("grid_m",.5))):
     var head:=foot+Vector3.UP*LevelMetrics.HEAD_M
     var under:=not meter.hit(head,head+Vector3.UP*float(clamp_spec.probe_m)).is_empty()
     var pose:=LevelMetrics.pose(view,foot,under)
     var hits:Array=[]
     for sign:float in [-1.,1.]:
      var direction:=ShipCamera.BOW.rotated(Vector3.UP,-sign*deg_to_rad(LevelMetrics.BODY_OFF_DEG))
      hits.append(meter.hit(pose.origin,pose.origin+direction*120.))
     if hits[0].is_empty() or hits[1].is_empty():continue
     var pair:=_hit_label(hits[0])+" | "+_hit_label(hits[1])
     pairs[pair]=int(pairs.get(pair,0))+1
    var ranked:Array=pairs.keys();ranked.sort_custom(func(a:String,b:String)->bool:return int(pairs[a])>int(pairs[b]))
    var id:="%s/%s@%s"%[stage.id,surface.id,view.id];var rows:Array=[]
    for pair:String in ranked.slice(0,5):rows.append({"pair":pair,"samples":pairs[pair]})
    if not rows.is_empty():print("backdrop-body-pairs: ",id," ",rows)
    result[id]=rows
 return result
func _hit_label(hit:Dictionary)->String:
 var collider:Node=hit.collider
 for i in pilots.size():
  for name:String in pilots[i].placements:
   var placement:Node=pilots[i].placements[name]
   if placement==collider or placement.is_ancestor_of(collider):return ("furniture:" if i==0 else "macro:")+name
 return "existing:"+str(collider.name)
func _pin(config:Dictionary,path:String,label:String)->bool:
 var source:=str(config.get("source_glb",""))
 if not source.begins_with("res://"):source=path.get_base_dir().path_join(source)
 var ok:=not config.is_empty() and FileAccess.file_exists(source) and FileAccess.get_sha256(source)==str(config.get("source_sha256",""))
 check(label+" authored source pin matches GLB",ok);return ok
func _exclude_nonfloor(node:Node,floor:Node)->void:
 if node is CollisionObject3D and not floor.is_ancestor_of(node):floor_exclusions.append(node.get_rid())
 for child:Node in node.get_children():_exclude_nonfloor(child,floor)
func _floor_support(foot:Vector3)->bool:
 var query:=PhysicsRayQueryParameters3D.create(foot+Vector3.UP*.1,foot-Vector3.UP*.15)
 query.exclude=floor_exclusions;query.hit_back_faces=true
 var hit:Dictionary=demo.camera.get_world_3d().direct_space_state.intersect_ray(query)
 return not hit.is_empty() and absf((hit.position as Vector3).y-foot.y)<=.035 and (hit.normal as Vector3).dot(Vector3.UP)>.95
func _pilot_hits(foot:Vector3)->Array:
 var shape:=CapsuleShape3D.new();shape.radius=.35;shape.height=1.8
 var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.margin=0.;query.transform=Transform3D(Basis.IDENTITY,foot+Vector3.UP*.91)
 return demo.camera.get_world_3d().direct_space_state.intersect_shape(query,128).filter(func(hit:Dictionary)->bool:return str(hit.collider.name).begins_with("PilotSolid_"))
func _mesh_envelope(node:Node3D)->Dictionary:
 var result:={"vertices":0,"max_radius_m":0.,"outside":0,"bad_meshes":[]}
 for mesh:MeshInstance3D in StapledonStyle.meshes(node):
  var bad:=false
  for surface in mesh.mesh.get_surface_count():
   var arrays:=mesh.mesh.surface_get_arrays(surface)
   for vertex:Vector3 in arrays[Mesh.ARRAY_VERTEX]:
    var radius:=_vertex_radius(mesh,vertex)
    result.vertices+=1
    result.max_radius_m=maxf(result.max_radius_m,radius)
    if not is_finite(radius) or radius>RADIUS_M:result.outside+=1;bad=true
  if bad and result.bad_meshes.size()<20:result.bad_meshes.append(str(mesh.get_path()))
 return result
func _vertex_radius(mesh:MeshInstance3D,vertex:Vector3)->float:
 var transform:=mesh.global_transform
 var radius:float=(transform*vertex).length()
 var material:=StapledonStyle._surface(mesh,0)
 if not StapledonStyle.is_card(material):return radius
 # Painted cards turn about their local Y by up to clamp_deg in the shared shader. Include
 # the analytic radial extrema of that arc; shadows have clamp=0. Cards have rigid unit bases.
 var angle:=deg_to_rad(float((material as ShaderMaterial).get_shader_parameter("clamp_deg")))
 var center:=transform.origin+transform.basis*Vector3(0,vertex.y,0)
 var along:=transform.basis*Vector3(vertex.x,0,vertex.z)
 var crosswise:=transform.basis*Vector3(vertex.z,0,-vertex.x)
 var peak:=atan2(center.dot(crosswise),center.dot(along))
 for turn:float in [-angle,angle,clampf(peak,-angle,angle)]:
  radius=maxf(radius,(center+along*cos(turn)+crosswise*sin(turn)).length())
 return radius
func _self_test()->void:
 var group:=Node3D.new();root.add_child(group)
 var mesh:=MeshInstance3D.new();mesh.mesh=BoxMesh.new();group.add_child(mesh)
 group.position=Vector3(80,0,0);mesh.position=Vector3(3,0,0);mesh.scale=Vector3.ONE*2
 check("transformed interior vertices pass",_mesh_envelope(group).outside==0)
 group.position=Vector3(92,0,0)
 check("outside transformed vertex fails despite inside node origin",_mesh_envelope(group).outside>0)
 group.position=Vector3.ZERO;mesh.position=Vector3(94.1,0,0);mesh.scale=Vector3.ONE;mesh.rotation.y=PI*.25
 var quad:=QuadMesh.new();quad.size=Vector2(2,2);mesh.mesh=quad
 check("unturned painted corner is inside",_mesh_envelope(group).outside==0)
 mesh.material_override=StapledonStyle.card_material(null)
 check("shader-turned foliage corner outside sphere is caught",_mesh_envelope(group).outside>0)
 group.free()
 demo=load("res://demos/ship_geometry_demo.tscn").instantiate();demo.setup_options={"stars":false,"background":false,"sky_state":"rest","sound":false}
 root.add_child(demo);await process_frame;demo.set_process(false)
 await physics_frame;await physics_frame
 var floor:Node=demo.geometry.find_child("Deck 01 top 57m",true,false)
 _exclude_nonfloor(demo.geometry,floor)
 var remote:=Vector3(70,57.025,0)
 check("remote physical floor supports art outside existing WALK",not demo.walk_lower.is_walkable_near(remote) and _floor_support(remote))
 check("floating root fails physical support",not _floor_support(remote+Vector3.UP*.1))
 check("root beyond physical floor fails support",not _floor_support(Vector3(80,57.025,0)))
 demo.queue_free();await process_frame
func _finish(extra:Dictionary)->void:
 var report:={"passed":passed,"failures":failures};report.merge(extra)
 DirAccess.make_dir_recursive_absolute("res://build")
 var file:="commons-backdrop-validator-self-test.json" if OS.get_cmdline_user_args().has("--self-test") else "commons-backdrop-validation.json"
 FileAccess.open("res://build/"+file,FileAccess.WRITE).store_string(JSON.stringify(report,"  ")+"\n")
 print("commons-backdrop-validate: %d passed, %d failures"%[passed,failures.size()]);quit(0 if failures.is_empty() else 1)
