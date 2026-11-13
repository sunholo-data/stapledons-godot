extends SceneTree
## Rebind verified authoring resources into the small native production asset closure.
const SOURCE:="res://art/environment-painted-pilot/"
const DEST:="res://assets/levels/painted/"
func _initialize()->void:
 for path:String in ["res://tools/painted_levels_stage.gd","res://demos/painted_levels_finish.gd","res://tests/test_painted_levels.gd"]:
  if not FileAccess.file_exists(path+".uid"):FileAccess.open(path+".uid",FileAccess.WRITE).store_line(ResourceUID.id_to_text(ResourceUID.create_id()))
 for deck:String in ["bridge","commons"]:
  if not _stage(deck):quit(1);return
 print("PAINTED_LEVELS_STAGE two native material/mesh closures, no authoring paths");quit()
func _stage(deck:String)->bool:
 var src:=SOURCE+deck+"-finish/";var dest:=DEST+deck+"/"
 DirAccess.make_dir_recursive_absolute(dest+"compiled")
 var doc:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(src+"manifest.json"))
 var textures:Dictionary={};var materials:Dictionary={};var resources:Dictionary={}
 for path:String in doc.resources:
  if FileAccess.get_sha256(path)!=doc.resources[path]:printerr("stage source resource changed ",path);return false
  var original:=load(path)
  if not original is ImageTexture:continue
  var texture:=ImageTexture.create_from_image(original.get_image())
  texture.take_over_path(dest+path.get_file());ResourceSaver.save(texture,texture.resource_path,ResourceSaver.FLAG_COMPRESS)
  textures[path]=texture;resources[texture.resource_path]=FileAccess.get_sha256(texture.resource_path)
 for path:String in doc.resources:
  var original:=load(path)
  if not original is ShaderMaterial:continue
  var material:ShaderMaterial=original.duplicate(false)
  var source_texture:Texture2D=original.get_shader_parameter("albedo_tex")
  if not textures.has(source_texture.resource_path):printerr("unknown stage texture");return false
  material.set_shader_parameter("albedo_tex",textures[source_texture.resource_path])
  material.take_over_path(dest+path.get_file());ResourceSaver.save(material,material.resource_path,ResourceSaver.FLAG_COMPRESS)
  materials[path]=material;resources[material.resource_path]=FileAccess.get_sha256(material.resource_path)
 var vertices:=0
 for row:Dictionary in doc.meshes:
  if FileAccess.get_sha256(row.file)!=row.sha256:printerr("stage mesh source changed");return false
  var original:Mesh=load(row.file);var mesh:=ArrayMesh.new()
  for si in original.get_surface_count():
   var tool:=SurfaceTool.new();tool.create_from(original,si);tool.index();tool.commit(mesh)
   var source_material:=original.surface_get_material(si)
   if not materials.has(source_material.resource_path):printerr("unknown stage material");return false
   mesh.surface_set_material(si,materials[source_material.resource_path])
  if mesh.get_faces()!=original.get_faces():printerr("staging changed geometry");return false
  var file:=dest+"compiled/"+str(row.file).get_file()
  ResourceSaver.save(mesh,file,ResourceSaver.FLAG_COMPRESS)
  row.file=file;row.sha256=FileAccess.get_sha256(file);row.vertices=0
  for si in mesh.get_surface_count():row.vertices+=mesh.surface_get_array_len(si)
  vertices+=int(row.vertices)
 doc.resources=resources;doc.paint_vertices=vertices;doc.normal_game_installation=true;doc.production_indexed=true
 FileAccess.open(dest+"manifest.json",FileAccess.WRITE).store_string(JSON.stringify(doc,"  ")+"\n")
 print("PAINTED_LEVELS_STAGE ",deck," ",doc.meshes.size()," meshes; ",vertices," indexed vertices")
 return true
