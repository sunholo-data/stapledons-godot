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
  var args:=OS.get_cmdline_user_args()
  var at:=args.find("--config")
  var path:=args[at+1] if at>=0 and at+1<args.size() else "res://art/commons-lived-in-pilot/placements.json"
  var config:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
  var configs:Array=config.get("base_configs",[str(config.base_config)] if config.has("base_config") else []).duplicate()
  configs.append(path)
  installed=true
  for source:String in configs:
   var doc:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(source))
   var loader:=load("res://demos/commons_civic_pilot.gd") if doc.get("grown_civic",false) else load("res://demos/commons_art_pilot.gd")
   var pilot:Dictionary=loader.install(helper.demo,source)
   installed=installed and pilot.ok
   if not pilot.ok:printerr("commons-pilot-golden: ",pilot.errors)
   for id:String in doc.get("replace_markers",[]):
    var marker:CollisionObject3D=helper.demo.geometry.find_child(id,true,false)
    marker.visible=false;marker.collision_layer=0;marker.collision_mask=0
  await physics_frame;await physics_frame
 var failures:int=await helper._level_poses(built and installed)
 await helper._free_demo()
 print("commons-pilot-golden: %d failures"%failures)
 quit(1 if failures else 0)
