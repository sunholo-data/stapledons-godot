extends SceneTree
## Existing independent CPU/pixel pole checks with actual review props installed.
func _initialize()->void:_run.call_deferred()
func _run()->void:
 root.size=Vector2i(960,540)
 var helper=load("res://tools/m4_ship_golden.gd").new()
 helper.main=root;helper.size=root.size
 if not helper._load_references():quit(2);return
 var built:bool=await helper._build(false)
 var installed:=false
 if built:
  var pilot:Dictionary=load("res://demos/commons_art_pilot.gd").install(helper.demo,"res://art/commons-lived-in-pilot/placements.json")
  installed=pilot.ok
  if not installed:printerr("commons-pilot-golden: ",pilot.errors)
  else:
   var marker:CollisionObject3D=helper.demo.geometry.find_child("GB_find_notice_board",true,false)
   marker.visible=false;marker.collision_layer=0;marker.collision_mask=0
   await physics_frame;await physics_frame
 var failures:int=await helper._level_poses(built and installed)
 await helper._free_demo()
 print("commons-pilot-golden: %d failures"%failures)
 quit(1 if failures else 0)
