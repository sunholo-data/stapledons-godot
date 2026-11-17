extends RefCounted
## D-165 combined painted deck review, retaining native mechanics, sky and live controls.
const Bridge:=preload("res://demos/bridge_painted_finish.gd")
const Commons:=preload("res://demos/commons_painted_finish.gd")
const ROOT:="res://assets/levels/painted/"
static func install(demo:Node,npc_catalog:String="res://assets/characters/npcs/manifest.json")->Dictionary:
 var out:={"ok":false,"errors":[],"bridge":{},"commons":{},"people":{}}
 if demo.geometry.has_meta("painted_levels_finish"):
  out.errors.append("painted levels already installed");return out
 var bridge:=Bridge.install(demo,ROOT+"bridge/manifest.json")
 if not bridge.ok:out.errors.append_array(bridge.errors);return out
 var commons:=Commons.install(demo,ROOT+"commons/manifest.json")
 if not commons.ok:Bridge.remove(bridge);out.errors.append_array(commons.errors);return out
 var doc:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(str(demo.civic_art.source_config)))
 var people:Dictionary=preload("res://demos/painted_npc_pilot.gd").install(demo,doc.residents,["medic","engineer"],npc_catalog)
 if not people.ok:
  Commons.remove(commons);Bridge.remove(bridge);out.errors.append_array(people.errors);return out
 var proxies:Node3D=demo.civic_art.node.find_child("CommonsLifePilot",true,false)
 var proxy_visibility:bool=proxies.visible if proxies!=null else false
 if proxies!=null:proxies.visible=false
 # D-139/D-141: residents use static painted poses; hiding the decorative proxy crowd pauses its walk loops.
 demo.geometry.set_meta("painted_levels_finish",true)
 out.ok=true;out.bridge=bridge;out.commons=commons;out.people=people;out.proxies=proxies;out.proxy_visibility=proxy_visibility
 print("painted-levels: ",bridge.changes.size()," bridge meshes, ",commons.changes.size()," Commons meshes, ",people.residents.size()," painted residents")
 return out
static func remove(result:Dictionary)->void:
 if not result.get("ok",false):return
 if is_instance_valid(result.people.node):result.people.node.free()
 if is_instance_valid(result.get("proxies")):result.proxies.visible=result.proxy_visibility
 Commons.remove(result.commons);Bridge.remove(result.bridge)
 result.bridge.host.remove_meta("painted_levels_finish")
