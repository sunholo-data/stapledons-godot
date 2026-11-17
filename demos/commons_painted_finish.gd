extends RefCounted
## Whole-bridge finish on authoritative meshes. Authoring/review entry only (D-164).
const ROOT:="res://art/environment-painted-pilot/commons-finish"
const MANIFEST:=ROOT+"/manifest.json"
static func belongs(node:MeshInstance3D)->bool:
 if node.cast_shadow==GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY:return false
 var path:=str(node.get_path())
 if "Collision" in path or "CommonsLifePilot" in path or "GroundedShadow" in path or "WalkSurfaces" in path:return false
 var box:AABB=node.global_transform*node.get_aabb()
 if box.end.y>80 or box.end.y<56 or box.size.y>25:return false
 var n:=str(node.name)
 return node.is_in_group(StapledonStyle.GROUP) or "CommonsVisual" in path or "CommonsCoarse" in path or "LevelGreybox_commons" in path or n.begins_with("Landing perimeter") or n.begins_with("Guardrail 57") or n.begins_with("Deck 01")
static func family(node:MeshInstance3D)->String:
 var path:=str(node.get_path()).to_lower();var n:=str(node.name).to_lower()
 if n.begins_with("deck 01 top"):return "floor"
 if n=="deck 01 edge" or "landing perimeter" in n or "guardrail 57" in n:return "rail"
 if StapledonStyle.is_card(StapledonStyle._surface(node,0)):return "painted_foliage"
 if "paintedcivicground" in path:
  if "warmcontinuous" in n or "teal_wash" in n:return "floor"
  return "ground_trim"
 if "bench" in n or "sofa" in path or "seating" in path:return "bench"
 if "planter" in path or "planted_island" in path or "garden" in path and "plant_" not in n:return "planter"
 if "rail" in path or "gate" in n:return "rail"
 if "plant_" in n or "growth" in n or "frond" in n:return "foliage_mesh"
 if "table" in path or "cup" in path or "pot" in path or "ceramic" in path or "book" in path:return "furniture"
 return "architecture"
static func target_key(node:MeshInstance3D)->String:
 var path:=str(node.get_path())
 for root:String in ["CommonsCivicArt","CommonsVisual","CommonsCoarse","BridgeDressing","LevelGreybox_commons"]:
  var offset:=path.find("/"+root+"/")
  if offset>=0:
   var pieces:Array[String]=[]
   for part:String in path.substr(offset+1).split("/"):
    if not part.begins_with("@"):pieces.append(part)
   return "/".join(pieces)+"|"+str(node.global_transform)
 return str(node.name)+"|"+str(node.global_transform)
static func faces_hash(mesh:Mesh)->String:
 var hash:=HashingContext.new();hash.start(HashingContext.HASH_SHA256);hash.update(mesh.get_faces().to_byte_array());return hash.finish().hex_encode()
static func install(demo:Node,path:String=MANIFEST)->Dictionary:
 var result:={"ok":false,"errors":[],"changes":[],"families":{},"added_triangles":0,"added_nodes":0}
 var host:Node3D=demo.get("geometry")
 if host==null or host.has_meta("whole_commons_paint"):
  result.errors.append("ready geometry required; duplicate install refused");return result
 var doc:Variant=JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
 if not doc is Dictionary or doc.get("schema")!="stapledons.commons-painted-finish/1" or not doc.get("meshes") is Array:
  result.errors.append("valid compiled finish manifest required");return result
 for source:String in doc.get("sources",{}):
  if FileAccess.get_sha256(_source_file(source))!=doc.sources[source]:result.errors.append("native source changed: "+source);return result
 for resource:String in doc.get("resources",{}):
  if FileAccess.get_sha256(resource)!=doc.resources[resource]:result.errors.append("paint resource changed: "+resource);return result
 var targets:Dictionary={}
 for node:MeshInstance3D in StapledonStyle.meshes(host):
  if belongs(node) and family(node)!="painted_foliage":
   if targets.has(target_key(node)):result.errors.append("ambiguous target name");return result
   targets[target_key(node)]=node
 if targets.size()!=doc.meshes.size():result.errors.append("whole bridge coverage changed; rebuild required");return result
 for row:Dictionary in doc.meshes:
  if not targets.has(str(row.key)) or not str(row.file).begins_with(path.get_base_dir()+"/compiled/") or FileAccess.get_sha256(row.file)!=row.sha256:
   result.errors.append("missing or changed compiled target: "+str(row.name));return result
  var node:MeshInstance3D=targets[row.key]
  if faces_hash(node.mesh)!=row.source_faces_sha256:result.errors.append("source triangle geometry changed");return result
  var mesh:=load(str(row.file)) as ArrayMesh
  if mesh==null or faces_hash(mesh)!=row.source_faces_sha256 or mesh.get_surface_count()!=node.mesh.get_surface_count():result.errors.append("compiled triangle geometry differs");return result
  var overrides:Array=[]
  for i in node.mesh.get_surface_count():overrides.append(node.get_surface_override_material(i))
  result.changes.append({"node":node,"original_mesh":node.mesh,"original_override":node.material_override,"original_surfaces":overrides,"painted_mesh":mesh,"family":row.family})
 result.families=doc.families;result.triangles=doc.triangles;result.paint_vertices=doc.paint_vertices;result.texture_bytes_with_mips=doc.texture_bytes_with_mips
 result.ok=true;host.set_meta("whole_commons_paint",true);result.host=host
 set_enabled(result,true)
 return result
static func set_enabled(result:Dictionary,enabled:bool)->void:
 if not result.get("ok",false):return
 for row:Dictionary in result.changes:
  var node:MeshInstance3D=row.node
  node.mesh=row.painted_mesh if enabled else row.original_mesh
  node.material_override=null if enabled else row.original_override
  for i in row.original_surfaces.size():node.set_surface_override_material(i,null if enabled else row.original_surfaces[i])
 result.enabled=enabled
static func remove(result:Dictionary)->void:
 if not result.get("ok",false):return
 set_enabled(result,false);result.host.remove_meta("whole_commons_paint")

static func _source_file(path:String)->String:
 if FileAccess.file_exists(path):return path
 if path.begins_with("res://assets/ship_demo/"):return "res://ship_demo_bundle/"+path.get_file()+".bin"
 if path.begins_with("res://assets/ship_commons/"):return "res://ship_commons_bundle/"+path.get_file()+".bin"
 return path
