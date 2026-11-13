extends SceneTree
## Headless actual-world integration and source-resource restoration.
const Finish:=preload("res://demos/painted_levels_finish.gd")
var failures:Array=[]
func _initialize()->void:_run.call_deferred()
func require_true(label:String,ok:bool)->void:
 if not ok:failures.append(label);printerr("FAIL ",label)
func _run()->void:
 var demo:Node=load("res://demos/ship_geometry_demo.tscn").instantiate()
 demo.setup_options={"size":Vector2i(1280,720),"stars":false,"background":false,"sound":false,"sky_state":"rest","civic_art":true,"mouse_look":false,"settings_dir":"res://.godot/tmp/painted-levels-test"}
 root.add_child(demo);await process_frame
 demo.auto=false;demo.journey_auto_tick=false;demo.set_process(false)
 require_true("ship ready",demo.ready_ok);require_true("civic ready",await demo.await_civic_art())
 await physics_frame;await physics_frame
 var bodies:=root.find_children("*","CollisionObject3D",true,false).size()
 var camera:Transform3D=demo.camera.global_transform
 var bridge_walk:Variant=demo.walk_bridge;var commons_walk:Variant=demo.walk_lower
 var initial:Array=[]
 for node:Node in demo.geometry.find_children("*","MeshInstance3D",true,false):initial.append([node,node.mesh,node.material_override])
 var refused:=Finish.install(demo,"res://absent-npc-catalog.json")
 require_true("NPC failure rolls back both decks",not refused.ok and not demo.geometry.has_meta("whole_bridge_paint") and not demo.geometry.has_meta("whole_commons_paint"))
 require_true("late failure preserves all source meshes",initial.all(func(row:Array)->bool:return row[0].mesh==row[1] and row[0].material_override==row[2]))
 var result:=Finish.install(demo)
 require_true("both painted decks install",result.ok)
 if result.ok:
  require_true("141 bridge meshes",result.bridge.changes.size()==141)
  require_true("full Commons",result.commons.changes.size()==JSON.parse_string(FileAccess.get_file_as_string("res://assets/levels/painted/commons/manifest.json")).meshes.size())
  var bridge_nodes:Array=result.bridge.changes.map(func(row:Dictionary)->Node:return row.node)
  require_true("deck surfaces have one owner",result.commons.changes.all(func(row:Dictionary)->bool:return not row.node in bridge_nodes))
  require_true("42 painted residents",result.people.residents.size()==42)
  require_true("two portrait-bound crew",result.people.crew.size()==2)
  require_true("old visible proxy crowd hidden",not result.proxies.visible)
  require_true("body count unchanged",root.find_children("*","CollisionObject3D",true,false).size()==bodies)
  require_true("camera and WALK unchanged",demo.camera.global_transform==camera and demo.walk_bridge==bridge_walk and demo.walk_lower==commons_walk)
  require_true("duplicate refused",not Finish.install(demo).ok)
  for p:Vector3 in [Vector3(-6.2,82.025,-7.3),Vector3(-6.2,82.025,7.3)]:require_true("bridge WALK retained",demo.walk_bridge.is_walkable_near(p))
  for p:Vector3 in [Vector3(25,57.025,-11),Vector3(28,57.025,-19)]:require_true("Commons WALK retained",demo.walk_lower.is_walkable_near(p))
  demo.avatar_pos=Vector3(8,82,-4.8);demo.avatar.position=demo.avatar_pos
  require_true("painted lift boards",demo.lift.board())
  demo.lift.advance(.81);demo.lift.advance(5.);demo.lift.advance(.81)
  require_true("painted Commons reached",demo.active_level==1 and demo.lift.state=="lower_ready")
  require_true("Commons materials survive deck switch",result.commons.changes.all(func(row:Dictionary)->bool:return row.node.mesh==row.painted_mesh))
  require_true("return lift boards",demo.lift.board())
  demo.lift.advance(.81);demo.lift.advance(5.);demo.lift.advance(.81)
  require_true("painted bridge reached",demo.active_level==0 and demo.lift.state=="bridge_ready")
  require_true("bridge materials survive return",result.bridge.changes.all(func(row:Dictionary)->bool:return row.node.mesh==row.painted_mesh))
  Finish.remove(result)
  require_true("whole-level marker removed",not demo.geometry.has_meta("painted_levels_finish"))
  require_true("both finish markers removed",not demo.geometry.has_meta("whole_bridge_paint") and not demo.geometry.has_meta("whole_commons_paint"))
  require_true("proxy visibility restored",result.proxies.visible)
  for row:Dictionary in result.bridge.changes+result.commons.changes:require_true("original mesh restored",row.node.mesh==row.original_mesh)
 var report:={"failures":failures,"gpu_used":false,"packed":OS.has_feature("standalone"),"painted_bridge":141,"painted_commons":result.get("commons",{}).get("changes",[]).size(),"residents":42}
 print("painted-levels-test: ",JSON.stringify(report))
 demo.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
