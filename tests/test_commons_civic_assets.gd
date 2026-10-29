extends SceneTree
## Real staged raw loads plus independent pack missing-file/hash/path negative controls.
const Stage=preload("res://tools/commons_civic_stage.gd")
const Audit=preload("res://tests/commons_civic_export_audit.gd")
const TMP:="res://.godot/tmp/commons-civic-assets"
var passed:=0
var failed:=0
func check(label:String,ok:bool)->void:
 if ok:passed+=1
 else:failed+=1
 print("%s %s"%["ok" if ok else "FAIL",label])
func _initialize()->void:_run.call_deferred()
func _json(path:String)->Dictionary:
 var value:Variant=JSON.parse_string(FileAccess.get_file_as_string(path));return value if value is Dictionary else {}
func _write(path:String,bytes:PackedByteArray)->void:
 var file:=FileAccess.open(path,FileAccess.WRITE);file.store_buffer(bytes);file.close()
func _audit(files:Dictionary,name:String)->Array[String]:
 var writer:=ZIPPacker.new();var path:=TMP.path_join(name+".zip")
 if writer.open(path)!=OK:return ["cannot open fixture ZIP"]
 for key:String in files:
  writer.start_file(key.trim_prefix("res://"));writer.write_file(files[key]);writer.close_file()
 writer.close();var reader:=ZIPReader.new()
 if reader.open(path)!=OK:return ["cannot read fixture ZIP"]
 var errors:=Audit.audit(reader);reader.close();return errors
func _run()->void:
 DirAccess.make_dir_recursive_absolute(TMP)
 var manifest_path:=Stage.CONFIG_DIR.path_join("manifest.json");var manifest:=_json(manifest_path)
 var files:Dictionary={manifest_path:FileAccess.get_file_as_bytes(manifest_path)}
 for path:String in manifest.files:files[path]=FileAccess.get_file_as_bytes(path)
 check("complete staged raw pack closes transitive configs/assets and all byte pins",_audit(files,"complete").is_empty())
 var roots:={"commons_lived_in_kit_v1.glb":["civic_bench","communal_table","notice_read_station"],"commons_backdrop_kit_v1.glb":["civic_arcade","curved_garden_parapet"],"commons_grown_kit_v1.glb":["tendril_arch","planted_island","rib_shade_canopy"]}
 for name:String in roots:
  var scene:=AreaBundle.load_glb(Stage.BUNDLE_DIR.path_join(name));var ok:=scene!=null
  if scene!=null:
   for prop:String in roots[name]:ok=ok and scene.find_child(prop,true,false)!=null
   scene.free()
  check("raw GLTF loader reads ignored staged "+name,ok)
 for name:String in ["trailing-vine-v1.png","cream.png","teal.png","ochre.png"]:
  var image:=Image.load_from_file(Stage.BUNDLE_DIR.path_join(name))
  check("raw Image loader reads ignored staged "+name,image!=null and not image.is_empty() and image.get_width()>100)
 for source:String in Stage.CONFIGS:
  var original:=_json(source);var staged:=_json(Stage.CONFIG_DIR.path_join(Stage.CONFIGS[source]));var ok:=true
  for key:String in ["placements","plants","practicals","residents","ground","trailing_vines"]:ok=ok and original.get(key)==staged.get(key)
  check("staging preserves world art/activity data "+Stage.CONFIGS[source],ok)
 for path:String in [Stage.CONFIG_DIR.path_join("backdrop.json"),Stage.BUNDLE_DIR.path_join("commons_grown_kit_v1.glb"),Stage.BUNDLE_DIR.path_join("trailing-vine-v1.png"),Stage.BUNDLE_DIR.path_join("cream.png")]:
  var dropped:=files.duplicate();dropped.erase(path)
  check("pack rejects dropped transitive "+path.get_file(),not _audit(dropped,"drop_"+path.get_file()).is_empty())
 var corrupt:=files.duplicate();var glb:=Stage.BUNDLE_DIR.path_join("commons_grown_kit_v1.glb");var bytes:PackedByteArray=corrupt[glb].duplicate();bytes[100]=bytes[100]^1;corrupt[glb]=bytes
 check("pack rejects changed raw GLB bytes",_audit(corrupt,"corrupt").any(func(e:String)->bool:return e.contains("byte pin mismatch")))
 var leaked:=files.duplicate();var root_path:=Stage.CONFIG_DIR.path_join("placements.json");var doc:=_json(root_path);doc.base_configs[0]="res://art/commons-lived-in-pilot/placements.json"
 var root_bytes:PackedByteArray=(JSON.stringify(doc,"  ",true)+"\n").to_utf8_buffer();leaked[root_path]=root_bytes
 var altered:=manifest.duplicate(true);var hash:=HashingContext.new();hash.start(HashingContext.HASH_SHA256);hash.update(root_bytes)
 altered.files[root_path].sha256=hash.finish().hex_encode();altered.files[root_path].bytes=root_bytes.size();leaked[manifest_path]=(JSON.stringify(altered,"  ",true)+"\n").to_utf8_buffer()
 check("closure rejects authoring path even with internally consistent hash",_audit(leaked,"leak").any(func(e:String)->bool:return e.contains("unstaged civic config")))
 var pins:=_json(Stage.PINS);pins.files["res://art/commons-grown-pilot/commons_grown_kit_v1.glb"]="0".repeat(64);var bad_pins:=TMP.path_join("bad-pins.json");_write(bad_pins,JSON.stringify(pins).to_utf8_buffer())
 var errors:=Stage.stage(TMP.path_join("bad-config"),TMP.path_join("bad-assets"),bad_pins)
 check("prebuild refuses mismatched reviewed source pin",Array(errors).any(func(e:String)->bool:return e.contains("source pin mismatch")))
 print("commons-civic-assets: %d passed, %d failures"%[passed,failed]);quit(1 if failed else 0)
