extends RefCounted
const CIVIC_BUNDLE_DIR:="res://ship_commons_bundle/civic/"
## D-135/D-136 civic composition: shared by the visual study and attended playable build.
## No navigation, simulation, sky or camera changes.
static func _doc(path:String)->Dictionary:
 var value:Variant=JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
 return value if value is Dictionary else {}

static func install_world(demo:Node,path:String)->Dictionary:
 var doc:=_doc(path)
 var bases:Array=[]
 var errors:Array=[]
 var main_source:=str(doc.get("source_glb",""))
 if not main_source.begins_with("res://"):main_source=path.get_base_dir().path_join(main_source)
 if doc.is_empty() or FileAccess.get_sha256(main_source)!=str(doc.get("source_sha256","")):
  return {"ok":false,"errors":["civic main source pin mismatch: "+path]}
 for base_path:String in doc.get("base_configs",[]):
  var base_doc:=_doc(base_path)
  var source:=str(base_doc.get("source_glb",""))
  if not source.begins_with("res://"):source=base_path.get_base_dir().path_join(source)
  if base_doc.is_empty() or FileAccess.get_sha256(source)!=str(base_doc.get("source_sha256","")):
   errors.append("civic base source pin mismatch: "+base_path);break
  var base:Dictionary=load("res://demos/commons_art_pilot.gd").install(demo,base_path)
  if not base.ok:errors.append_array(base.errors);break
  bases.append(base)
 var result:Dictionary=install(demo,path,false) if errors.is_empty() else {"ok":false,"errors":errors}
 if not result.ok:
  for base:Dictionary in bases:base.node.free()
  return result
 var world:=Node3D.new();world.name="CommonsCivicArt";demo.geometry.add_child(world)
 result.node.reparent(world)
 for i in bases.size():
  var base:Dictionary=bases[i];base.node.reparent(world)
  for key:String in ["colliders","plants","plant_shadows","practicals"]:result[key].append_array(base[key])
  for name:String in base.placements:result.placements["base%d_"%i+name]=base.placements[name]
  var base_doc:=_doc(str(doc.base_configs[i]))
  for id:String in base_doc.get("replace_markers",[]):
   var marker:Node3D=demo.geometry.find_child(id,true,false)
   if marker!=null:
    marker.visible=false
    if marker is CollisionObject3D:marker.collision_layer=0;marker.collision_mask=0
 result.node=world
 result.source_config=path
 return result

static func install(demo:Node,path:String,freeze_activity:bool=true)->Dictionary:
 var doc:=_doc(path)
 var result:Dictionary=load("res://demos/commons_art_pilot.gd").install(demo,path)
 if not result.ok:return result
 for extra:String in doc.get("extra_art",[]):
  var layer_doc:=_doc(extra)
  var source:=str(layer_doc.get("source_glb",""))
  if not source.begins_with("res://"):source=extra.get_base_dir().path_join(source)
  if FileAccess.get_sha256(source)!=str(layer_doc.get("source_sha256","")):
   result.errors.append("extra art source pin mismatch: "+extra);break
  var layer:Dictionary=load("res://demos/commons_art_pilot.gd").install(demo,extra)
  if not layer.ok:result.errors.append_array(layer.errors);break
  layer.node.reparent(result.node)
  for key:String in ["colliders","plants","plant_shadows","practicals"]:result[key].append_array(layer[key])
  for name:String in layer.placements:result.placements["district_"+name]=layer.placements[name]
 if result.errors.is_empty():
  var ground:=Node3D.new();ground.name="PaintedCivicGround";result.node.add_child(ground)
  var ground_doc:Dictionary=doc.get("ground",{}).duplicate(true)
  ground_doc.textures=doc.get("ground_textures",{})
  _ground(ground,ground_doc)
  _vines(demo,result,doc)
  if not doc.get("residents",[]).is_empty():
   var life:Dictionary=load("res://demos/commons_life_pilot.gd").install(demo,doc.residents,freeze_activity)
   if life.ok:life.node.reparent(result.node)
   else:result.errors.append_array(life.errors)
 if not result.errors.is_empty():
  result.node.free();result.node=null;result.ok=false
  result.placements={};result.colliders=[];result.plants=[];result.plant_shadows=[];result.practicals=[]
 return result

static func _vines(demo:Node,result:Dictionary,doc:Dictionary)->void:
 if doc.get("trailing_vines",[]).is_empty():return
 var bundled:=CIVIC_BUNDLE_DIR+"trailing-vine-v1.png.bin"
 var fallback:=bundled if FileAccess.file_exists(bundled) else "res://art/commons-grown-pilot/trailing-vine-v1.png"
 var path:=str(doc.get("vine_texture",fallback))
 if FileAccess.get_sha256(path)!=str(doc.get("vine_sha256","")):
  result.errors.append("trailing foliage source pin mismatch");return
 var painting:=Image.new()
 if painting.load_png_from_buffer(FileAccess.get_file_as_bytes(path))!=OK:result.errors.append("invalid trailing foliage painting");return
 if painting==null or painting.is_empty():result.errors.append("missing trailing foliage painting");return
 painting.generate_mipmaps();var texture:=ImageTexture.create_from_image(painting)
 for row:Dictionary in doc.trailing_vines:
  var placement:Node3D=demo.geometry.find_child(str(row.placement),true,false)
  var anchor:Node3D=placement.find_child(str(row.anchor),true,false) if placement!=null else null
  if anchor==null:result.errors.append("missing real vine soil anchor: "+str(row.name));continue
  var height:=float(row.height)*ShipDressing.CARD_MARGIN
  var builder:=ShipDressing.new();var card:=builder._card(str(row.name),texture,height);builder.free()
  result.node.add_child(card)
  card.global_transform=Transform3D(placement.global_basis.rotated(Vector3.UP,PI),anchor.global_position-Vector3.UP*height*.96)
  card.set_instance_shader_parameter("cloud_center",card.global_position+Vector3.UP*height*.55)
  card.set_instance_shader_parameter("cloud_radii",Vector3.ONE*height*.5)
  card.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  result.plants.append(card)

static func _material(kind:String,textures:Dictionary)->ShaderMaterial:
 var src:=StandardMaterial3D.new()
 var bundled:=CIVIC_BUNDLE_DIR+kind+".png.bin"
 var fallback:=bundled if FileAccess.file_exists(bundled) else "res://art/ship-demo-v1/painted-bridge-v1/textures/%s.png"%kind
 var path:=str(textures.get(kind,fallback))
 var image:=Image.new()
 if image.load_png_from_buffer(FileAccess.get_file_as_bytes(path))!=OK:push_error("missing civic pigment: "+path)
 if image!=null:image.generate_mipmaps();src.albedo_texture=ImageTexture.create_from_image(image)
 var paint:=StapledonStyle.toon_material(src)
 # Inlaid floor pigment has no raised silhouette: keep the ink shader at zero extrusion.
 var ink:=StapledonStyle.ink_material().duplicate() as ShaderMaterial
 ink.set_shader_parameter("width",0.);paint.next_pass=ink
 return paint

static func _ground(host:Node3D,doc:Dictionary)->void:
 var textures:Dictionary=doc.get("textures",{})
 var cream:=_material("cream",textures);var teal:=_material("teal",textures);var ochre:=_material("ochre",textures)
 _oval(host,"WarmContinuousCommons",Vector2.ZERO,Vector2(75.78,75.78),57.030,cream)
 for patch:Dictionary in doc.get("courts",[]):
  var at:=Vector2(float(patch.at[0]),float(patch.at[1]));var radius:=Vector2(float(patch.radius[0]),float(patch.radius[1]))
  _oval(host,str(patch.name)+"_ochre_coping",at,radius+Vector2.ONE*.25,57.036,ochre)
  _oval(host,str(patch.name)+"_teal_wash",at,radius,57.046,teal)
 for path:Dictionary in doc.get("paths",[]):
  var points:Array=path.points;var width:=float(path.get("width",4.))
  _ribbon(host,str(path.name)+"_cream_walk",points,width,57.068,cream)
 for patch:Dictionary in doc.get("courts",[]):
  var at:=Vector2(float(patch.at[0]),float(patch.at[1]))
  _oval(host,str(patch.name)+"_medallion_ochre",at,Vector2(1.6,1.6),57.078,ochre)
  _oval(host,str(patch.name)+"_medallion_cream",at,Vector2(1.35,1.35),57.090,cream)

static func _oval(host:Node3D,name:String,at:Vector2,radius:Vector2,z:float,material:Material)->void:
 var tool:=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES)
 for i in 96:
  var a:=TAU*i/96.;var b:=TAU*(i+1)/96.
  _vertex(tool,at,z);_vertex(tool,at+Vector2(cos(b)*radius.x,sin(b)*radius.y),z);_vertex(tool,at+Vector2(cos(a)*radius.x,sin(a)*radius.y),z)
 _mesh(host,name,tool,material)

static func _ribbon(host:Node3D,name:String,points:Array,width:float,z:float,material:Material)->void:
 var curve:=Curve3D.new();curve.bake_interval=.6
 for point:Array in points:curve.add_point(Vector3(float(point[0]),0.,float(point[1])))
 # Smooth Bezier tangents preserve the hand-drawn curved lane through its control points.
 for i in curve.point_count:
  var before:=curve.get_point_position(maxi(0,i-1));var after:=curve.get_point_position(mini(curve.point_count-1,i+1))
  var tangent:=(after-before)*.17
  curve.set_point_in(i,-tangent);curve.set_point_out(i,tangent)
 var samples:=curve.get_baked_points();var offsets:Array[Vector2]=[]
 for i in samples.size():
  var before:=samples[maxi(0,i-1)];var after:=samples[mini(samples.size()-1,i+1)]
  var tangent:=Vector2(after.x-before.x,after.z-before.z).normalized()
  offsets.append(Vector2(-tangent.y,tangent.x)*width*.5)
 var tool:=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES)
 for i in samples.size()-1:
  var a:=Vector2(samples[i].x,samples[i].z);var b:=Vector2(samples[i+1].x,samples[i+1].z)
  var left:=offsets[i];var right:=offsets[i+1]
  for p:Vector2 in [a-left,b+right,b-right,a-left,a+left,b+right]:_vertex(tool,p,z)
 _mesh(host,name,tool,material)

static func _vertex(tool:SurfaceTool,p:Vector2,z:float)->void:
 tool.set_normal(Vector3.UP);tool.set_uv(p*.12);tool.add_vertex(ShipFrame.gltf_from_structure([p.x,p.y,z]))

static func _mesh(host:Node3D,name:String,tool:SurfaceTool,material:Material)->void:
 var mesh:=MeshInstance3D.new();mesh.name=name;mesh.mesh=tool.commit();mesh.set_surface_override_material(0,material)
 mesh.add_to_group(StapledonStyle.GROUP);mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;host.add_child(mesh)
