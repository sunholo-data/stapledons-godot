extends "res://tools/bridge_painted_finish_build.gd"
## Full Commons material build; original triangle geometry retained.
const COUT:="res://art/environment-painted-pilot/commons-finish"
const Civic:=preload("res://demos/commons_painted_finish.gd")
var ground_paint:ShaderMaterial
func _initialize()->void:
 for path:String in ["res://tools/commons_painted_finish_build.gd","res://demos/commons_painted_finish.gd","res://tools/commons_painted_finish_review.gd"]:
  if not FileAccess.file_exists(path+".uid"):FileAccess.open(path+".uid",FileAccess.WRITE).store_line(ResourceUID.id_to_text(ResourceUID.create_id()))
 _run.call_deferred()
func _run()->void:
 var demo:Node=load("res://demos/ship_geometry_demo.tscn").instantiate()
 demo.setup_options={"size":Vector2i(1280,720),"stars":false,"background":false,"sound":false,"sky_state":"rest","civic_art":true,"mouse_look":false,"settings_dir":"res://.godot/tmp/commons-finish"}
 root.add_child(demo);await process_frame
 demo.auto=false;demo.journey_auto_tick=false;demo.set_process(false)
 if not demo.ready_ok or not await demo.await_civic_art():printerr("Commons not ready");quit(1);return
 DirAccess.make_dir_recursive_absolute(COUT+"/compiled")
 atlas=load(OUT+"/crafted_atlas.res").get_image();atlas.clear_mipmaps()
 # Three vine repeats across a wide curved back, baked inside one guarded atlas cell.
 var vine:=Image.load_from_file("res://art/environment-painted-pilot/commons-panel-paint.png");vine.convert(Image.FORMAT_RGBA8)
 for i in 3:
  var tile:Image=vine.duplicate();tile.resize(342,512,Image.INTERPOLATE_LANCZOS)
  atlas.blit_rect(tile,Rect2i(0,0,mini(342,1024-i*342),512),Vector2i(1024+i*342,512))
 atlas.generate_mipmaps();var tex:=ImageTexture.create_from_image(atlas);tex.take_over_path(COUT+"/crafted_atlas.res");ResourceSaver.save(tex,tex.resource_path,ResourceSaver.FLAG_COMPRESS)
 paint=_material(tex);paint.take_over_path(COUT+"/crafted_paint.res");ResourceSaver.save(paint,paint.resource_path,ResourceSaver.FLAG_COMPRESS)
 ground_paint=paint.duplicate() as ShaderMaterial;ground_paint.next_pass=paint.next_pass.duplicate() as ShaderMaterial;ground_paint.next_pass.set_shader_parameter("width",0.)
 ground_paint.take_over_path(COUT+"/ground_paint.res");ResourceSaver.save(ground_paint,ground_paint.resource_path,ResourceSaver.FLAG_COMPRESS)
 var floor_image:=Image.load_from_file(COUT+"/commons-floor-albedo.png");floor_image.convert(Image.FORMAT_RGBA8);floor_image.generate_mipmaps()
 var floor_tex:=ImageTexture.create_from_image(floor_image);floor_tex.take_over_path(COUT+"/floor_atlas.res");ResourceSaver.save(floor_tex,floor_tex.resource_path,ResourceSaver.FLAG_COMPRESS)
 floor_paint=_material(floor_tex);floor_paint.next_pass=ground_paint.next_pass;floor_paint.take_over_path(COUT+"/floor_paint.res");ResourceSaver.save(floor_paint,floor_paint.resource_path,ResourceSaver.FLAG_COMPRESS)
 var rows:Array=[];var families:Dictionary={};var triangles:=0;var vertices:=0
 for node:MeshInstance3D in StapledonStyle.meshes(demo.geometry):
  if not Civic.belongs(node):continue
  var kind:=Civic.family(node)
  if kind=="painted_foliage":continue
  var mesh:=_mesh(node,kind)
  if mesh.get_faces()!=node.mesh.get_faces():printerr("geometry changed ",node.name);quit(1);return
  var file:=COUT+"/compiled/"+str(rows.size()).pad_zeros(4)+".res";ResourceSaver.save(mesh,file,ResourceSaver.FLAG_COMPRESS)
  var nv:=0
  for i in mesh.get_surface_count():nv+=mesh.surface_get_array_len(i)
  var nt:=mesh.get_faces().size()/3;vertices+=nv;triangles+=nt;families[kind]=int(families.get(kind,0))+1
  rows.append({"key":Civic.target_key(node),"name":str(node.name),"family":kind,"file":file,"sha256":FileAccess.get_sha256(file),"source_faces_sha256":Civic.faces_hash(node.mesh),"triangles":nt,"vertices":nv,"surfaces":mesh.get_surface_count()})
 var resources:Dictionary={}
 for name:String in ["crafted_atlas.res","crafted_paint.res","ground_paint.res","floor_atlas.res","floor_paint.res"]:resources[COUT+"/"+name]=FileAccess.get_sha256(COUT+"/"+name)
 var doc:={"schema":"stapledons.commons-painted-finish/1","authority":"D-165","sources":{},"resources":resources,"meshes":rows,"families":families,"triangles":triangles,"paint_vertices":vertices,"added_triangles":0,"floor_uv":"world x/48,z/24; repeatable botanical field follows existing deck and cream ribbon geometry","texture_bytes_with_mips":atlas.get_data_size()+floor_image.get_data_size(),"normal_game_installation":false}
 FileAccess.open(COUT+"/manifest.json",FileAccess.WRITE).store_string(JSON.stringify(doc,"  ")+"\n")
 print("COMMONS_PAINT_BUILD ",rows.size()," meshes; ",triangles," unchanged triangles; ",vertices," indexed vertices; ",JSON.stringify(families))
 demo.queue_free();await process_frame;quit()
func _floor_uv(world:Vector3)->Vector2:return Vector2(world.x/48.,world.z/24.)
func _mesh(node:MeshInstance3D,kind:String)->ArrayMesh:
 var raw:=super._mesh(node,kind);var indexed:=ArrayMesh.new()
 for si in raw.get_surface_count():
  var tool:=SurfaceTool.new();tool.create_from(raw,si);tool.index();tool.commit(indexed)
  indexed.surface_set_material(si,ground_paint if kind=="ground_trim" else raw.surface_get_material(si))
 return indexed
func _cell(node:MeshInstance3D,kind:String,c:Color,p:Vector3,n:Vector3,box:AABB)->int:
 var path:=str(node.get_path()).to_lower()
 if "levelgreybox_commons" in path:
  if "find_telescope" in path:return 4
  if "roof" in path or "surface" in path:return 1 if absf(n.y)>.8 else 2
  if "structure" in path:return 4 if absf(n.y)<.5 else 0
 var color:=0
 if c.b>c.r*1.05 and c.b>c.g*1.12:color=3
 elif c.g>c.r*1.08 or c.b>c.r*1.12:color=1
 elif c.r>c.b*1.28 and c.g>c.b*1.15:color=2
 if kind=="ground_trim":return 2 if "ochre" in str(node.name) else 0
 if kind=="rail":return 2 if color in [0,2] else 1
 if kind=="bench" and "grown_back" in str(node.name):return 5
 if kind=="bench":return 3 if color==3 else color
 if kind=="planter":return 5 if color==1 else color
 if kind=="foliage_mesh":return 1 if color!=2 else 2
 if kind=="architecture" and "structure" in str(node.name):return 4 if color in [0,2] else color
 return color
func _special_uv(node:MeshInstance3D,kind:String,p:Vector3,cell:int,box:AABB,coord:Vector2)->Vector2:
 if kind=="ground_trim":
  var world:=node.global_transform*p
  return Vector2((world.x+80)/160.,(world.z+80)/160.).clamp(Vector2.ZERO,Vector2.ONE)
 if kind=="bench" and "grown_back" in str(node.name):
  var angle:=atan2(p.x,p.z+1.0125)
  return Vector2(clampf((angle+1.25)/2.5,0,1),1-(p.y-box.position.y)/box.size.y)
 return coord
