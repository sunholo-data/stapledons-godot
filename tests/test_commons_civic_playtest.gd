extends SceneTree
## Independent actual-scene playtest guards for the user-approved playable civic composition.
## No GPU or timing claims. Review tools opt out; normal launch opts into one async installation.
var passed:=0
var failed:=0
const SETTINGS:="res://.godot/tmp/commons_civic_playtest_settings"
func _initialize()->void:_run.call_deferred()
func check(label:String,ok:bool)->void:
 if ok:passed+=1
 else:failed+=1
 print("%s %s"%["ok" if ok else "FAIL",label])
func _scene(options:Dictionary)->Node:
 var demo:Node=load("res://demos/ship_geometry_demo.tscn").instantiate()
 demo.setup_options={"stars":false,"background":false,"sound":false,"sky_state":"rest","settings_dir":SETTINGS}
 demo.setup_options.merge(options,true);root.add_child(demo);demo.auto=false;demo.journey_auto_tick=false;return demo
func _settled(demo:Node)->void:
 for frame in 30:
  await physics_frame;await process_frame
  if demo.get("civic_art_ready")==true or not (demo.get("civic_art_errors") as Array).is_empty():return
func _dispose(demo:Node)->void:demo.queue_free();await process_frame;await physics_frame
func _run()->void:
 DirAccess.make_dir_recursive_absolute(SETTINGS)
 var demo:=_scene({"civic_art":true})
 var api:bool=demo.get("civic_art_ready")!=null and demo.get("civic_art_errors") is Array and demo.get("civic_art") is Dictionary
 check("real ship exposes async civic installation status",api)
 if not api:await _dispose(demo);_finish();return
 # Calling setup again while the two-frame install is pending must not queue another art tree.
 demo.setup(demo.setup_options)
 await _settled(demo)
 check("opt-in ship completes the approved civic installation",demo.ready_ok and demo.civic_art_ready and demo.civic_art_errors.is_empty())
 if not demo.civic_art_ready:
  print("civic-playtest-install-errors: ",demo.civic_art_errors);await _dispose(demo);_finish();return
 demo.set_process(false)
 var civic:Node3D=demo.civic_art.node
 var ground:Array=_named(demo.geometry,"PaintedCivicGround");var life_nodes:Array=_named(demo.geometry,"CommonsLifePilot")
 check("one composition and one resident clock installed",ground.size()==1 and life_nodes.size()==1 and civic.name=="CommonsCivicArt")
 if life_nodes.size()!=1:await _dispose(demo);_finish();return
 var life:Node3D=life_nodes[0];life.set_process(false)
 var marker:Node3D=demo.geometry.find_child("GB_find_notice_board",true,false)
 check("old notice marker is hidden and physically disabled",marker!=null and not marker.visible and marker is CollisionObject3D and marker.collision_layer==0 and marker.collision_mask==0)
 var solids:Array=_solids(civic)
 check("approved substantial art has active physical solids",not solids.is_empty() and solids.all(func(body:CollisionObject3D)->bool:return body.collision_layer==1 and body.collision_mask==1))
 var initial_id:=civic.get_instance_id();var initial_solids:=solids.size()
 demo.setup(demo.setup_options)
 for frame in 6:await physics_frame
 check("repeated setup cannot duplicate already-installed art",demo.civic_art.node.get_instance_id()==initial_id and _named(demo.geometry,"PaintedCivicGround").size()==1 and _named(demo.geometry,"CommonsLifePilot").size()==1 and _solids(civic).size()==initial_solids)
 demo.active_level=1;demo.walk=demo.walk_lower;demo.avatar_pos=Vector3(26,57.025,-4);demo._process(0.)
 var before:float=life.elapsed;life.advance(.25)
 check("playable resident activity is live rather than review-frozen",life.elapsed>before)
 demo.set_camera_motion("reduced");before=life.elapsed;life.advance(.25)
 check("live reduced-motion setting pauses civilian decoration",life.elapsed==before)
 demo.set_camera_motion("full");life.advance(.25)
 check("returning to full motion resumes activity",life.elapsed>before)
 # Exercise the actual walking implementation to detect raised-floor snaps and new solid crossings.
 demo.avatar_pos=Vector3(26,57.025,-4);demo.consoles.cancel_walk()
 var accepted:bool=demo.walk_to("navigation");var clear:=true;var floor_ok:=true
 for frame in 1200:
  if demo.consoles.walking.is_empty():break
  demo.consoles._advance_walk(.05)
  floor_ok=floor_ok and absf(demo.avatar_pos.y-57.)<.06
  clear=clear and _new_solid_hits(demo,demo.avatar_pos).is_empty()
 check("real court-to-lift route completes without new solid collisions or raised-floor snap",accepted and demo.consoles.walking.is_empty() and floor_ok and clear and demo.avatar_pos.distance_to(Vector3(8,57,-4.8))<.1)
 demo.set_brightness_trial(4);demo.set_camera_motion("reduced")
 check("lift boards from the actual Commons endpoint",demo.lift.board())
 demo.director.advance(0.)
 check("reduced-motion lift reaches bridge with correct WALK and Bow view",demo.active_level==0 and demo.walk==demo.walk_bridge and demo.avatar_pos.distance_to(Vector3(8,82,-4.8))<.01 and demo.director.view_id=="bow")
 check("bridge-to-Commons return boards",demo.lift.board())
 demo.director.advance(0.)
 check("lift returns to Commons without replacing civic art or settings",demo.active_level==1 and demo.walk==demo.walk_lower and demo.avatar_pos.distance_to(Vector3(8,57,-4.8))<.01 and demo.civic_art.node.get_instance_id()==initial_id and demo.camera_motion=="reduced" and demo.brightness_stops==4 and _named(demo.geometry,"CommonsLifePilot").size()==1)
 await _dispose(demo)
 var disabled:=_scene({"civic_art":false});await _settled(disabled)
 check("review opt-out installs no extra composition or residents",disabled.ready_ok and disabled.civic_art_errors.is_empty() and _named(disabled.geometry,"PaintedCivicGround").is_empty() and _named(disabled.geometry,"CommonsLifePilot").is_empty())
 await _dispose(disabled)
 var missing:=_scene({"civic_art":true,"civic_art_config":"res://.godot/tmp/missing_civic_playtest_config.json"})
 await _settled(missing)
 check("missing civic config reports a graceful failure",missing.ready_ok and not missing.civic_art_ready and not missing.civic_art_errors.is_empty())
 check("failed art load leaves no partial civic tree",_named(missing.geometry,"CommonsCivicArt").is_empty() and _named(missing.geometry,"PaintedCivicGround").is_empty() and _named(missing.geometry,"CommonsLifePilot").is_empty())
 check("missing art preserves a usable bridge and captain",missing.avatar.get_parent()==missing.geometry and missing.walk_bridge.is_walkable(missing.avatar_pos))
 await _dispose(missing);_finish()
func _named(node:Node,name:String)->Array:
 var result:Array=[]
 if str(node.name)==name:result.append(node)
 for child:Node in node.get_children():result.append_array(_named(child,name))
 return result
func _solids(node:Node)->Array:
 var result:Array=[]
 if node is CollisionObject3D and str(node.name).begins_with("PilotSolid_"):result.append(node)
 for child:Node in node.get_children():result.append_array(_solids(child))
 return result
func _new_solid_hits(demo:Node,foot:Vector3)->Array:
 var capsule:=CapsuleShape3D.new();capsule.radius=.35;capsule.height=1.8
 var query:=PhysicsShapeQueryParameters3D.new();query.shape=capsule;query.margin=0.;query.transform=Transform3D(Basis.IDENTITY,foot+Vector3.UP*.91)
 return demo.camera.get_world_3d().direct_space_state.intersect_shape(query,128).filter(func(hit:Dictionary)->bool:return str(hit.collider.name).begins_with("PilotSolid_"))
func _finish()->void:
 print("commons-civic-playtest: %d passed, %d failures"%[passed,failed]);quit(1 if failed else 0)
