extends SceneTree
## Reproducible, pinned review-art -> playable bundle staging. No import/render or source mutation.
const CONFIG_DIR:="res://assets/levels/commons/civic"
const BUNDLE_DIR:="res://ship_commons_bundle/civic"
const PINS:="res://data/commons_civic/source-pins.json"
const CONFIGS:={
 "res://art/commons-grown-pilot/placements.json":"placements.json",
 "res://art/commons-lived-in-pilot/placements.json":"lived-in.json",
 "res://art/commons-backdrop-pilot/placements.json":"backdrop.json",
 "res://art/commons-grown-pilot/furniture.json":"furniture.json"}
const ASSETS:={
 "res://art/commons-lived-in-pilot/commons_lived_in_kit_v1.glb":"commons_lived_in_kit_v1.glb",
 "res://art/commons-backdrop-pilot/commons_backdrop_kit_v1.glb":"commons_backdrop_kit_v1.glb",
 "res://art/commons-grown-pilot/commons_grown_kit_v1.glb":"commons_grown_kit_v1.glb",
 "res://art/commons-grown-pilot/trailing-vine-v1.png":"trailing-vine-v1.png",
 "res://art/ship-demo-v1/painted-bridge-v1/textures/cream.png":"cream.png",
 "res://art/ship-demo-v1/painted-bridge-v1/textures/teal.png":"teal.png",
 "res://art/ship-demo-v1/painted-bridge-v1/textures/ochre.png":"ochre.png"}

func _initialize()->void:
 var errors:=stage()
 for error:String in errors:print("FAIL commons-civic-stage "+error)
 print("commons-civic-stage: 4 configs, 3 raw GLBs, 4 raw PNGs, %d failures"%errors.size())
 quit(1 if not errors.is_empty() else 0)

static func _doc(path:String)->Dictionary:
 var value:Variant=JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
 return value if value is Dictionary else {}

static func _json(value:Dictionary)->PackedByteArray:
 return (JSON.stringify(value,"  ",true)+"\n").to_utf8_buffer()

static func _sha(bytes:PackedByteArray)->String:
 var ctx:=HashingContext.new();ctx.start(HashingContext.HASH_SHA256);ctx.update(bytes);return ctx.finish().hex_encode()

static func stage(config_dir:String=CONFIG_DIR,bundle_dir:String=BUNDLE_DIR,pins_path:String=PINS)->PackedStringArray:
 var errors:=PackedStringArray();var pins:=_doc(pins_path)
 if pins.get("schema")!="stapledons.commons-civic.sources/1" or not pins.get("files") is Dictionary:return PackedStringArray(["invalid source pins"])
 var all:Array=CONFIGS.keys();all.append_array(ASSETS.keys())
 if pins.files.size()!=all.size():errors.append("source pin inventory must cover exactly eleven files")
 for source:String in all:
  if not FileAccess.file_exists(source) or FileAccess.get_sha256(source)!=str(pins.files.get(source,"")):errors.append("source pin mismatch: "+source)
 if not errors.is_empty():return errors
 var output:Dictionary={};var manifest:={"schema":"stapledons.commons-civic.bundle/1","root_config":config_dir.path_join("placements.json"),"files":{}}
 for source:String in ASSETS:
  var dest:=bundle_dir.path_join(ASSETS[source]);var bytes:=FileAccess.get_file_as_bytes(source)
  output[dest]=bytes;manifest.files[dest]={"sha256":pins.files[source],"bytes":bytes.size(),"source":source,"source_sha256":pins.files[source]}
 for source:String in CONFIGS:
  var doc:=_doc(source)
  var glb:=str(doc.get("source_glb",""))
  if not glb.begins_with("res://"):glb=source.get_base_dir().path_join(glb).simplify_path()
  if not ASSETS.has(glb) or str(doc.get("source_sha256",""))!=str(pins.files.get(glb,"")):
   errors.append("config GLB pin mismatch: "+source);continue
  doc.source_glb=bundle_dir.path_join(ASSETS[glb])
  if doc.has("base_config"):
   if CONFIGS.has(doc.base_config):doc.base_config=config_dir.path_join(CONFIGS[doc.base_config])
   else:errors.append("unknown base_config: "+source)
  for key:String in ["base_configs","extra_art"]:
   if not doc.has(key):continue
   var refs:Array=[]
   for ref:String in doc[key]:
    if CONFIGS.has(ref):refs.append(config_dir.path_join(CONFIGS[ref]))
    else:errors.append("unknown "+key+": "+ref)
   doc[key]=refs
  if bool(doc.get("grown_civic",false)):
   var vine:="res://art/commons-grown-pilot/trailing-vine-v1.png"
   if str(doc.get("vine_sha256",""))!=str(pins.files[vine]):errors.append("vine source pin mismatch")
   doc.vine_texture=bundle_dir.path_join("trailing-vine-v1.png");doc.ground_textures={};doc.ground_texture_sha256={}
   for kind:String in ["cream","teal","ochre"]:
    doc.ground_textures[kind]=bundle_dir.path_join(kind+".png")
    doc.ground_texture_sha256[kind]=pins.files["res://art/ship-demo-v1/painted-bridge-v1/textures/"+kind+".png"]
  var dest:=config_dir.path_join(CONFIGS[source]);var bytes:=_json(doc)
  output[dest]=bytes;manifest.files[dest]={"sha256":_sha(bytes),"bytes":bytes.size(),"source":source,"source_sha256":pins.files[source]}
 if not errors.is_empty():return errors
 for directory:String in [config_dir,bundle_dir]:
  if DirAccess.make_dir_recursive_absolute(directory)!=OK:return PackedStringArray(["cannot create "+directory])
  var ignored:=FileAccess.open(directory.path_join(".gdignore"),FileAccess.WRITE)
  if ignored==null:return PackedStringArray(["cannot mark raw staging directory "+directory])
  ignored.close()
 for dest:String in output:
  var file:=FileAccess.open(dest,FileAccess.WRITE)
  if file==null:return PackedStringArray(["cannot write "+dest])
  file.store_buffer(output[dest]);file.close()
 var file:=FileAccess.open(config_dir.path_join("manifest.json"),FileAccess.WRITE)
 if file==null:return PackedStringArray(["cannot write civic manifest"])
 file.store_buffer(_json(manifest));file.close()
 return errors
