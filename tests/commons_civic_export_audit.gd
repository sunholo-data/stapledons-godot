extends RefCounted
## Independent raw-pack closure and byte pins; deliberately does not reuse the stage implementation.
const CONFIG:="res://assets/levels/commons/civic/"
const BUNDLE:="res://ship_commons_bundle/civic/"
const CONFIG_NAMES:=["placements.json","lived-in.json","backdrop.json","furniture.json"]
const ASSET_NAMES:=["commons_lived_in_kit_v1.glb","commons_backdrop_kit_v1.glb","commons_grown_kit_v1.glb","trailing-vine-v1.png","cream.png","teal.png","ochre.png"]
static func _json(zip:ZIPReader,path:String)->Dictionary:
 var name:=path.trim_prefix("res://")
 if not zip.file_exists(name):return {}
 var value:Variant=JSON.parse_string(zip.read_file(name).get_string_from_utf8())
 return value if value is Dictionary else {}
static func _sha(bytes:PackedByteArray)->String:
 var ctx:=HashingContext.new();ctx.start(HashingContext.HASH_SHA256);ctx.update(bytes);return ctx.finish().hex_encode()
static func audit(zip:ZIPReader)->Array[String]:
 var errors:Array[String]=[];var manifest:=_json(zip,CONFIG+"manifest.json")
 if manifest.get("schema")!="stapledons.commons-civic.bundle/1" or not manifest.get("files") is Dictionary:return ["missing/invalid civic manifest"]
 if manifest.files.size()!=11:errors.append("civic manifest must pin eleven files")
 var required:Array=[]
 for name:String in CONFIG_NAMES:required.append(CONFIG+name)
 for name:String in ASSET_NAMES:required.append(BUNDLE+name)
 for path:String in required:
  if not manifest.files.has(path):errors.append("missing civic pin: "+path);continue
  var name:=path.trim_prefix("res://");var pin:Dictionary=manifest.files[path]
  if not zip.file_exists(name):errors.append("missing raw civic file: "+path);continue
  var bytes:=zip.read_file(name)
  if _sha(bytes)!=str(pin.get("sha256","")) or bytes.size()!=int(pin.get("bytes",-1)):errors.append("civic byte pin mismatch: "+path)
 if manifest.get("root_config")!=CONFIG+"placements.json":errors.append("wrong civic root config")
 var queue:Array=[CONFIG+"placements.json"];var seen:Dictionary={};var assets:Dictionary={}
 while not queue.is_empty():
  var path:String=queue.pop_front()
  if seen.has(path):continue
  if not path.begins_with(CONFIG) or not CONFIG_NAMES.has(path.get_file()):errors.append("unstaged civic config dependency: "+path);continue
  seen[path]=true;var doc:=_json(zip,path)
  if doc.is_empty():errors.append("missing civic config: "+path);continue
  var glb:=str(doc.get("source_glb",""))
  if not glb.begins_with(BUNDLE) or not ASSET_NAMES.has(glb.get_file()) or not glb.ends_with(".glb"):errors.append("unstaged civic GLB dependency: "+glb)
  else:
   assets[glb]=true
   if str(doc.get("source_sha256",""))!=str(manifest.files.get(glb,{}).get("sha256","")):errors.append("config GLB hash mismatch: "+path)
  if doc.has("base_config"):queue.append(doc.base_config)
  for key:String in ["base_configs","extra_art"]:queue.append_array(doc.get(key,[]))
  if path==CONFIG+"placements.json":
   var vine:=str(doc.get("vine_texture",""))
   if vine!=BUNDLE+"trailing-vine-v1.png":errors.append("unstaged civic vine dependency")
   else:assets[vine]=true
   if str(doc.get("vine_sha256",""))!=str(manifest.files.get(vine,{}).get("sha256","")):errors.append("civic vine hash mismatch")
   for kind:String in ["cream","teal","ochre"]:
    var png:=str(doc.get("ground_textures",{}).get(kind,""))
    if png!=BUNDLE+kind+".png":errors.append("unstaged civic ground texture: "+kind)
    else:assets[png]=true
    if str(doc.get("ground_texture_sha256",{}).get(kind,""))!=str(manifest.files.get(png,{}).get("sha256","")):errors.append("civic ground texture hash mismatch: "+kind)
 if seen.size()!=4 or assets.size()!=7:errors.append("incomplete civic transitive file closure")
 return errors
