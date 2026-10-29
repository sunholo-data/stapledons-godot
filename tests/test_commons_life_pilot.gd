extends SceneTree
const Life=preload("res://demos/commons_life_pilot.gd")
var passed:=0
var failed:=0
class ReviewDemo extends Node:
 var geometry:=Node3D.new()
 var camera:=Camera3D.new()
 var camera_motion:="full"
func check(label:String,ok:bool)->void:
 if ok:passed+=1
 else:failed+=1
 print("%s %s"%["ok" if ok else "FAIL",label])
func _initialize()->void:_run.call_deferred()
func _run()->void:
 var demo:=ReviewDemo.new();root.add_child(demo);demo.add_child(demo.geometry);demo.geometry.add_child(demo.camera)
 var ground:=MeshInstance3D.new();var floor_mesh:=BoxMesh.new();floor_mesh.size=Vector3(150,.1,150);ground.mesh=floor_mesh;ground.position.y=56.95;demo.geometry.add_child(ground);ground.create_trimesh_collision()
 await physics_frame;await physics_frame
 var rows:Array=[{"name":"reader","ship_m":[20,4,57.025],"activity":"reading","facing":90},{"name":"diner","ship_m":[23,5,57.025],"activity":"dining","facing":0,"seat_height_m":.48},{"name":"stroller","ship_m":[65,0,57.025],"activity":"walk","facing":0,"walk_m":1.4}]
 var result:Dictionary=Life.install(demo,rows)
 check("grounded civilian vignettes install",result.ok)
 if not result.ok:print(result.errors)
 if result.ok:
  var pilot:Node3D=result.node;pilot.set_process(false)
  var reader:Node3D=result.residents.reader;var diner:Node3D=result.residents.diner;var walker:Node3D=result.residents.stroller
  check("ship metres and literal facing preserve physical placement",reader.position.is_equal_approx(Vector3(20,57.025,-4)) and (reader.basis*Vector3.FORWARD).normalized().is_equal_approx(Vector3.LEFT))
  check("reading and dining are different intentional poses",reader.get_meta("activity")=="reading" and diner.get_meta("activity")=="dining" and diner.find_child("Body",true,false).position.y<-.2)
  check("ordinary native figures use no Captain texture or identity",reader.get_meta("source")=="native civilian study v1" and not str(reader.get_meta("identity")).contains("Captain"))
  check("civilian opaque surfaces use shared toon and ink",StapledonStyle.meshes(reader).all(func(mesh:MeshInstance3D)->bool:return StapledonStyle.is_toon(mesh.material_override) and StapledonStyle.is_ink(mesh.material_override.next_pass)))
  check("visual residents add no gameplay colliders",find_collisions(pilot)==0)
  pilot.pose_at(2.0);var first:=walker.transform
  pilot.pose_at(9.);pilot.pose_at(2.)
  check("pose time reproduces the same stroll exactly",walker.transform.is_equal_approx(first))
  var within:=true;var feet_grounded:=true;var low:=INF;var high:=-INF
  for second in 48:
   pilot.pose_at(float(second)*.25)
   within=within and absf(walker.position.z)<=.7001
   for foot:Node3D in walker.find_children("Foot_*","Node3D",true,false):
    var y:float=foot.global_position.y-walker.global_position.y
    low=minf(low,y);high=maxf(high,y)
    feet_grounded=feet_grounded and y>=.032 and y<=.11
  check("short stroll stays inside declared span",within)
  check("walking feet stay grounded or in a small swing",feet_grounded)
  if not feet_grounded:print("foot-range: ",low,"..",high)
  pilot.pose_at(2.);var before:Transform3D=walker.transform;var clock:float=pilot.elapsed
  pilot.visible=false;pilot.advance(1.)
  check("hidden vignettes pause clock and pose",pilot.elapsed==clock and walker.transform.is_equal_approx(before))
  pilot.visible=true;pilot.set_reduced_motion(true);pilot.advance(1.)
  check("explicit reduced motion stops decorative movement",pilot.elapsed==clock and walker.transform.is_equal_approx(before))
  pilot.set_reduced_motion(false);demo.camera_motion="reduced";pilot.advance(1.)
  check("live demo reduced-motion preference is obeyed",pilot.elapsed==clock and walker.transform.is_equal_approx(before))
  demo.camera_motion="full";pilot.advance(.2)
  check("full motion resumes a paused local clock",is_equal_approx(pilot.elapsed,clock+.2))
  var other:Dictionary=Life.install(demo,rows,true)
  check("seeded appearance does not depend on global RNG or instance order",other.ok and other.residents.reader.get_meta("variant")==reader.get_meta("variant"))
  if other.ok:other.node.free()
  pilot.free()
 for label:String in ["duplicate","nonfinite","bad_activity","floating","missing_floor","too_far_walk"]:
  var bad:Array=rows.duplicate(true)
  match label:
   "duplicate":bad.append(bad[0].duplicate(true))
   "nonfinite":bad[0].ship_m=[INF,4,57]
   "bad_activity":bad[0].activity="crew_simulation"
   "floating":bad[0].ship_m=[20,4,58]
   "missing_floor":bad[0].ship_m=[90,4,57.025]
   "too_far_walk":bad[2].walk_m=20
  var before:=demo.geometry.get_child_count();var refused:Dictionary=Life.install(demo,bad)
  check(label+" refuses atomically",not refused.ok and not refused.errors.is_empty() and demo.geometry.get_child_count()==before)
 demo.queue_free();await process_frame
 print("commons-life-pilot: %d passed, %d failures"%[passed,failed]);quit(1 if failed else 0)
func find_collisions(node:Node)->int:
 var n:=int(node is CollisionObject3D)
 for child:Node in node.get_children():n+=find_collisions(child)
 return n
