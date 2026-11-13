extends SceneTree
## Authoring only: compile painted albedo/UVs on unchanged bridge triangle geometry.
const OUT:="res://art/environment-painted-pilot/bridge-finish"
const Source:=preload("res://demos/bridge_painted_finish.gd")
var texture_images:Dictionary={}
var atlas:Image
var paint:ShaderMaterial
var floor_paint:ShaderMaterial
func _initialize()->void:
 for path:String in ["res://tools/bridge_painted_finish_build.gd","res://demos/bridge_painted_finish.gd","res://tools/bridge_painted_finish_review.gd"]:
  if not FileAccess.file_exists(path+".uid"):FileAccess.open(path+".uid",FileAccess.WRITE).store_line(ResourceUID.id_to_text(ResourceUID.create_id()))
 _run.call_deferred()
func _run()->void:
 var demo:Node=load("res://demos/ship_geometry_demo.tscn").instantiate()
 demo.setup_options={"size":Vector2i(1280,720),"stars":false,"background":false,"sound":false,"sky_state":"rest","civic_art":false,"mouse_look":false,"settings_dir":"res://.godot/tmp/bridge-finish"}
 root.add_child(demo);await process_frame
 demo.auto=false;demo.journey_auto_tick=false;demo.set_process(false)
 if not demo.ready_ok:printerr("ship not ready");quit(1);return
 DirAccess.make_dir_recursive_absolute(OUT+"/compiled")
 _build_atlas()
 var tex:=ImageTexture.create_from_image(atlas)
 tex.take_over_path(OUT+"/crafted_atlas.res");ResourceSaver.save(tex,OUT+"/crafted_atlas.res",ResourceSaver.FLAG_COMPRESS)
 paint=_material(tex);paint.take_over_path(OUT+"/crafted_paint.res");ResourceSaver.save(paint,OUT+"/crafted_paint.res",ResourceSaver.FLAG_COMPRESS)
 var floor_image:=Image.load_from_file(OUT+"/bridge-floor-albedo.png");floor_image.convert(Image.FORMAT_RGBA8);floor_image.generate_mipmaps()
 var floor_tex:=ImageTexture.create_from_image(floor_image)
 floor_tex.take_over_path(OUT+"/floor_atlas.res");ResourceSaver.save(floor_tex,OUT+"/floor_atlas.res",ResourceSaver.FLAG_COMPRESS)
 floor_paint=_material(floor_tex);floor_paint.take_over_path(OUT+"/floor_paint.res");ResourceSaver.save(floor_paint,OUT+"/floor_paint.res",ResourceSaver.FLAG_COMPRESS)
 var rows:Array=[];var triangles:=0;var vertices:=0;var families:Dictionary={}
 for node:MeshInstance3D in StapledonStyle.meshes(demo.geometry):
  if not Source.belongs(node):continue
  var family:=Source.family(node)
  if family=="painted_foliage":continue
  var before:Mesh=node.mesh
  var built:=_mesh(node,family)
  if built.get_faces()!=before.get_faces():printerr("triangle geometry changed: ",node.name);quit(1);return
  var file:=OUT+"/compiled/"+str(rows.size()).pad_zeros(3)+".res"
  ResourceSaver.save(built,file,ResourceSaver.FLAG_COMPRESS)
  var ntri:=before.get_faces().size()/3
  triangles+=ntri
  var nv:=0
  for i in built.get_surface_count():nv+=built.surface_get_array_len(i)
  vertices+=nv;families[family]=int(families.get(family,0))+1
  rows.append({"key":Source.target_key(node),"name":str(node.name),"family":family,"file":file,"sha256":FileAccess.get_sha256(file),"source_faces_sha256":Source.faces_hash(before),"triangles":ntri,"vertices":nv,"surfaces":built.get_surface_count()})
 var pins:Dictionary={}
 for path:String in ["res://assets/ship_demo/ship.glb","res://assets/ship_demo/bridge_props.glb","res://assets/ship_demo/bridge_monitors.glb"]:pins[path]=FileAccess.get_sha256(path)
 var resources:Dictionary={}
 for f:String in ["crafted_atlas.res","floor_atlas.res","crafted_paint.res","floor_paint.res"]:resources[OUT+"/"+f]=FileAccess.get_sha256(OUT+"/"+f)
 var doc:={"resources":resources,"schema":"stapledons.bridge-painted-finish/1","authority":"D-164","sources":pins,"meshes":rows,"families":families,"triangles":triangles,"paint_vertices":vertices,"added_triangles":0,"floor_uv":"world x/z: (p+22)/44, same map across every existing deck mesh","texture_bytes_with_mips":atlas.get_data_size()+floor_image.get_data_size(),"normal_shader":"existing stapledon_toon; normal maps disabled, original vertex normals retained","new_lights":0,"new_bodies":0,"normal_game_installation":false}
 FileAccess.open(OUT+"/manifest.json",FileAccess.WRITE).store_string(JSON.stringify(doc,"  ")+"\n")
 print("BRIDGE_PAINT_BUILD ",rows.size()," meshes; ",triangles," unchanged triangles; ",vertices," UV vertices; ",JSON.stringify(families))
 demo.queue_free();await process_frame;quit()
func _build_atlas()->void:
 # Eight guarded cells: four quiet pigments, two enamel fields, screen surround, spare plum.
 atlas=Image.create(4096,1024,false,Image.FORMAT_RGBA8)
 var source:=Image.load_from_file(OUT+"/crafted-pigment-atlas.png")
 var half:=source.get_size()/2
 var cells:Array=[]
 for xy:Vector2i in [Vector2i(0,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,1)]:cells.append(source.get_region(Rect2i(xy*half,half)))
 cells.append(Image.load_from_file(OUT+"/ivory-botanical-enamel.png"))
 cells.append(Image.load_from_file("res://art/environment-painted-pilot/commons-panel-paint.png"))
 var frame:Image=cells[3].duplicate();frame.resize(1024,512,Image.INTERPOLATE_LANCZOS)
 var gold:Image=cells[2].duplicate();gold.resize(1024,512,Image.INTERPOLATE_LANCZOS)
 for rect:Rect2i in [Rect2i(0,0,1024,32),Rect2i(0,480,1024,32),Rect2i(0,0,40,512),Rect2i(984,0,40,512)]:frame.blit_rect(gold,rect,rect.position)
 cells.append(frame);cells.append(cells[3])
 for i in cells.size():
  var cell:Image=cells[i];cell.convert(Image.FORMAT_RGBA8);cell.resize(1024,512,Image.INTERPOLATE_LANCZOS)
  atlas.blit_rect(cell,Rect2i(0,0,1024,512),Vector2i(i%4*1024,i/4*512))
 atlas.save_png(OUT+"/crafted-atlas.png");atlas.generate_mipmaps()
func _material(tex:Texture2D)->ShaderMaterial:
 var m:=ShaderMaterial.new();m.shader=StapledonStyle.toon_shader();m.next_pass=StapledonStyle.ink_material()
 m.set_shader_parameter("albedo",Color.WHITE);m.set_shader_parameter("has_tex",true);m.set_shader_parameter("albedo_tex",tex);m.set_shader_parameter("has_normal",false)
 return m
func _mesh(node:MeshInstance3D,family:String)->ArrayMesh:
 var out:=ArrayMesh.new();var box:=node.get_aabb()
 for si in node.mesh.get_surface_count():
  var arr:=node.mesh.surface_get_arrays(si)
  var points:PackedVector3Array=arr[Mesh.ARRAY_VERTEX]
  var normals:PackedVector3Array=arr[Mesh.ARRAY_NORMAL]
  var uvs:PackedVector2Array=arr[Mesh.ARRAY_TEX_UV] if arr[Mesh.ARRAY_TEX_UV]!=null else PackedVector2Array()
  var indices:PackedInt32Array=arr[Mesh.ARRAY_INDEX] if arr[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
  if indices.is_empty():
   indices.resize(points.size())
   for j in points.size():indices[j]=j
  var src:=StapledonStyle._surface(node,si)
  var image:Image=null;var tint:=Color.WHITE
  if src is ShaderMaterial:
   var c:Variant=src.get_shader_parameter("albedo");if c is Color:tint=c
   var tex:Variant=src.get_shader_parameter("albedo_tex")
   if tex is Texture2D:
    var key:int=tex.get_instance_id()
    if not texture_images.has(key):texture_images[key]=tex.get_image()
    image=texture_images[key]
  elif src is BaseMaterial3D:
   tint=src.albedo_color
   if src.albedo_texture!=null:
    var key:int=src.albedo_texture.get_instance_id()
    if not texture_images.has(key):texture_images[key]=src.albedo_texture.get_image()
    image=texture_images[key]
  var vs:=PackedVector3Array();var ns:=PackedVector3Array();var uv:=PackedVector2Array()
  for k in range(0,indices.size(),3):
   var a:=indices[k];var b:=indices[k+1];var c:=indices[k+2]
   var centre:Vector3=(points[a]+points[b]+points[c])/3.0
   var n:Vector3=(normals[a]+normals[b]+normals[c]).normalized()
   var col:=tint
   if image!=null and not uvs.is_empty():
    var sample:Vector2=(uvs[a]+uvs[b]+uvs[c])/3.0
    col*=image.get_pixel(clampi(int(fposmod(sample.x,1)*image.get_width()),0,image.get_width()-1),clampi(int(fposmod(sample.y,1)*image.get_height()),0,image.get_height()-1))
   var cell:=_cell(node,family,col,centre,n,box)
   for idx:int in [a,b,c]:
    var p:=points[idx];vs.append(p);ns.append(normals[idx])
    if family=="floor":
     var world:=node.global_transform*p;uv.append(_floor_uv(world))
    else:
     var coord:=_projection(p,n,box)
     coord=_special_uv(node,family,p,cell,box,coord)
     # Guard interpolation inside each pigment field; cells cannot bleed together.
     uv.append((Vector2(cell%4,cell/4)+Vector2(.025,.035)+coord*Vector2(.95,.93))/Vector2(4,2))
  var aa:Array=[];aa.resize(Mesh.ARRAY_MAX);aa[Mesh.ARRAY_VERTEX]=vs;aa[Mesh.ARRAY_NORMAL]=ns;aa[Mesh.ARRAY_TEX_UV]=uv
  out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,aa)
  out.surface_set_material(si,floor_paint if family=="floor" else paint)
 return out
func _floor_uv(world:Vector3)->Vector2:return Vector2((world.x+22.0)/44.0,(world.z+22.0)/44.0)
func _special_uv(node:MeshInstance3D,family:String,p:Vector3,cell:int,box:AABB,coord:Vector2)->Vector2:
 if family=="console" and str(node.name).begins_with("console_navigation") and cell==4:
  var relative:=p-box.get_center()
  return Vector2(atan2(relative.x,relative.z)/TAU+.5,1.0-(p.y-box.position.y)/box.size.y)
 return coord
func _cell(node:MeshInstance3D,family:String,c:Color,p:Vector3,n:Vector3,box:AABB)->int:
 var color:=0
 if c.b>c.r*1.05 and c.b>c.g*1.12:color=3
 elif c.g>c.r*1.08 or c.b>c.r*1.12:color=1
 elif c.r>c.b*1.28 and c.g>c.b*1.15:color=2
 if family=="floor_trim":return 2 if color!=3 else 1
 if family=="monitor":return 1 if "stand" in str(node.name) else 2 if "lip" in str(node.name) else 6
 if family=="rail":return 2 if color==2 else 1
 if family=="console" and str(node.name).begins_with("console_navigation") and color in [0,1]:return 4
 if family=="console" and color==1:return 1
 if family=="chair" and color==2:return 4 if p.y>box.position.y+box.size.y*.48 and absf(n.y)<.7 else 2
 if family in ["bench","furniture"] and color==1:return 5 if absf(n.y)<.65 else 1
 return color
func _projection(p:Vector3,n:Vector3,box:AABB)->Vector2:
 var q:=(p-box.position)/box.size.max(Vector3(.001,.001,.001))
 if absf(n.y)>.7:return Vector2(q.x,q.z).clamp(Vector2.ZERO,Vector2.ONE)
 if absf(n.x)>absf(n.z):return Vector2(q.z,1-q.y).clamp(Vector2.ZERO,Vector2.ONE)
 return Vector2(q.x,1-q.y).clamp(Vector2.ZERO,Vector2.ONE)
