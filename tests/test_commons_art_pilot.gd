extends SceneTree
## Review-only pilot: real GLB subtrees, shared materials, ship units, atomic validation and solids.
const Loader=preload("res://demos/commons_art_pilot.gd")
const DIR="res://.godot/tmp/commons_art_pilot"
var passed:=0
var failed:=0
class ReviewDemo extends Node:
 var geometry:=Node3D.new()
func check(label:String,ok:bool)->void:
 if ok:passed+=1
 else:failed+=1
 print("%s %s"%["ok" if ok else "FAIL",label])
func _initialize()->void:_run.call_deferred()
func _run()->void:
 DirAccess.make_dir_recursive_absolute(DIR)
 make_kit()
 var demo:=ReviewDemo.new();root.add_child(demo);demo.add_child(demo.geometry)
 var doc:=config()
 var result:Dictionary=Loader.install(demo,write_config(doc))
 check("real authored chair subtree installs",result.ok)
 if not result.ok:print("loader-errors: ",result.errors)
 if result.ok:
  var chair:Node3D=result.placements.reading_chair
  check("only chosen prop is installed, not overlapping catalog",result.placements.size()==1 and chair.find_child("UnusedCatalogProp",true,false)==null)
  check("literal ship metres map to glTF Y-up",chair.position.is_equal_approx(Vector3(20,57.025,0)))
  var detail:Node3D=chair.find_child("OffsetDetail",true,false)
  check("positive ship yaw90 maps local +X toward glTF -Z",detail.global_position.is_equal_approx(chair.global_position+Vector3(0,0,-1)))
  var solid:MeshInstance3D=chair.find_child("ChairSolid",true,false)
  var material:Material=solid.get_surface_override_material(0)
  check("opaque authored surface uses shared toon plus exact ink",StapledonStyle.is_toon(material) and StapledonStyle.is_ink(material.next_pass) and material.next_pass.next_pass==null)
  check("authored mesh shape retained",solid.mesh.get_faces().size()>100)
  check("only explicit structural mesh receives collision",result.colliders.size()==1)
  await physics_frame;await physics_frame
  check("captain capsule cannot occupy chair",capsule_hits(Vector3(20,57.9,0))>0)
  check("clear passage next to chair stays clear",capsule_hits(Vector3(25,57.9,0))==0)
  var plant:MeshInstance3D=result.plants[0]
  check("plant root follows actual GLB soil anchor",plant.position.is_equal_approx(chair.position+Vector3(0,.6,-.5)))
  check("plants use shared world card shader without outline",StapledonStyle.is_card(plant.material_override) and plant.material_override.next_pass==null and plant.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
  check("crossed foliage proxy only casts shadow",result.plant_shadows.size()==1 and result.plant_shadows[0].cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY)
  check("leaf rectangles have no physical collision",plant.get_children().is_empty() and result.plant_shadows[0].get_children().is_empty())
  check("bounded practical uses requested ship units",result.practicals.size()==1 and result.practicals[0].position.is_equal_approx(Vector3(22,59,-1)) and not result.practicals[0].shadow_enabled)
  result.node.free();await physics_frame
 for label:String in ["missing_prop","missing_solid","invalid_position","outside_bounds","duplicate_name","invalid_plant","unbounded_light","wrong_types","wrong_tint","partial_valid","missing_glb"]:
  var bad:=config()
  match label:
   "missing_prop":bad.placements[0].prop="absent"
   "missing_solid":bad.placements[0].solid_meshes=["ClothDecoration"]
   "invalid_position":bad.placements[0].ship_m=[20,"57",0]
   "outside_bounds":bad.placements[0].ship_m=[35.9,0,57.025]
   "duplicate_name":bad.placements.append(bad.placements[0].duplicate(true))
   "invalid_plant":bad.plants[0].anchor="absent"
   "unbounded_light":bad.practicals[0].energy=99
   "wrong_types":bad.placements={}
   "wrong_tint":bad.plants[0].tint=["red",1,1]
   "partial_valid":
    var second:Dictionary=bad.placements[0].duplicate(true);second.name="second_chair";second.prop="absent";bad.placements.append(second)
   "missing_glb":bad.source_glb="res://absent.glb"
  var before:=demo.geometry.get_child_count()
  var rejected:Dictionary=Loader.install(demo,write_config(bad))
  check("%s is refused atomically"%label,not rejected.ok and not rejected.errors.is_empty() and demo.geometry.get_child_count()==before)
 var decoration:=config();decoration.placements[0].solid_meshes=[]
 var decorative:Dictionary=Loader.install(demo,write_config(decoration))
 check("explicit decorative props can omit physical solids",decorative.ok and decorative.colliders.is_empty())
 if decorative.ok:decorative.node.free()
 var rooted:=config();rooted.plants[0].erase("placement");rooted.plants[0].erase("anchor");rooted.plants[0].root=[21,1,57.5]
 var planted:Dictionary=Loader.install(demo,write_config(rooted))
 check("world-space plant roots also use ship metre conversion",planted.ok and planted.plants[0].position.is_equal_approx(Vector3(21,57.5,-1)))
 if planted.ok:planted.node.free()
 check("null config is rejected",not Loader.validate(null).is_empty())
 var invalid:=config();invalid.placements[0].yaw_deg=INF
 check("nonfinite transform is rejected",not Loader.validate(invalid).is_empty())
 invalid=config();invalid.bounds.max=[36,20,NAN]
 check("nonfinite bounds are rejected",not Loader.validate(invalid).is_empty())
 demo.queue_free();await process_frame
 print("commons-art-pilot: %d passed, %d failures"%[passed,failed]);quit(1 if failed else 0)
func config()->Dictionary:
 return {"source_glb":DIR+"/kit.glb","bounds":{"min":[14,-10,57],"max":[36,20,60.5]},"placements":[{"name":"reading_chair","prop":"authored_chair","ship_m":[20,0,57.025],"yaw_deg":90,"solid_meshes":["ChairSolid"]}],"plants":[{"name":"soil_plant","kind":"frond","placement":"reading_chair","anchor":"FOLIAGE_soil","height":1.8,"tint":[.8,1,.9]}],"practicals":[{"name":"reading_lamp","ship_m":[22,1,59],"range_m":4,"energy":1.2}]}
func write_config(doc:Dictionary)->String:
 var path:=DIR+"/placements.json";FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(doc));return path
func capsule_hits(at:Vector3)->int:
 var shape:=CapsuleShape3D.new();shape.radius=.3;shape.height=1.7
 var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.transform=Transform3D(Basis.IDENTITY,at)
 return root.get_world_3d().direct_space_state.intersect_shape(query).size()
func make_kit()->void:
 # A test catalog built from an actual authored GLB chair; the loader never substitutes a primitive.
 var source:=AreaBundle.load_glb("res://assets/ship_demo/bridge_props.glb")
 var authored:=source.find_child("captain_chair",true,false) as MeshInstance3D
 var catalog:=Node3D.new();catalog.name="Catalog"
 var prop:=Node3D.new();prop.name="authored_chair";catalog.add_child(prop)
 for name:String in ["ChairSolid","OffsetDetail","ClothDecoration"]:
  var mesh:=authored.duplicate() as MeshInstance3D;mesh.name=name;mesh.transform=Transform3D.IDENTITY
  if name=="OffsetDetail":mesh.position=Vector3.RIGHT;mesh.scale=Vector3.ONE*.1
  if name=="ClothDecoration":
   mesh.position=Vector3(0,.5,0);mesh.scale=Vector3.ONE*.1
   var cloth:=StandardMaterial3D.new();cloth.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;cloth.albedo_color=Color(1,1,1,.4);mesh.material_override=cloth
  prop.add_child(mesh)
 var soil:=Node3D.new();soil.name="FOLIAGE_soil";soil.position=Vector3(.5,.6,0);prop.add_child(soil)
 var unused:=authored.duplicate() as MeshInstance3D;unused.name="UnusedCatalogProp";catalog.add_child(unused)
 own(catalog,catalog)
 var document:=GLTFDocument.new();var state:=GLTFState.new()
 check("real authored fixture exports",document.append_from_scene(catalog,state)==OK and document.write_to_filesystem(state,ProjectSettings.globalize_path(DIR+"/kit.glb"))==OK)
 catalog.free();source.free()
func own(node:Node,owner_node:Node)->void:
 for child:Node in node.get_children():child.owner=owner_node;own(child,owner_node)
