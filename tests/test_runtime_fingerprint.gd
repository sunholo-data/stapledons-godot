extends SceneTree
var failures:=0
func check(label:String,ok:bool)->void:
	print("%s %s"%["ok" if ok else "FAIL",label]);if not ok:failures+=1
func _initialize()->void:
	var a:={"core.ail":"old sim".to_utf8_buffer(),"ailang.lock":"package0.4".to_utf8_buffer(),"ailang.toml":"manifest".to_utf8_buffer()}
	var b:={"ailang.toml":a["ailang.toml"],"ailang.lock":a["ailang.lock"],"core.ail":a["core.ail"]}
	var original:=SimBridge.runtime_fingerprint("v0.52.0",a)
	check("cache stable across file enumeration order",original==SimBridge.runtime_fingerprint("v0.52.0",b))
	b["core.ail"]="new sim".to_utf8_buffer()
	check("sim source update gets distinct cache",original!=SimBridge.runtime_fingerprint("v0.52.0",b))
	b=a.duplicate();b["ailang.lock"]="package0.7".to_utf8_buffer()
	check("package pin update gets distinct cache",original!=SimBridge.runtime_fingerprint("v0.52.0",b))
	check("runtime update gets distinct cache",original!=SimBridge.runtime_fingerprint("v0.53.0",a))

	var fixture:=ProjectSettings.globalize_path("res://.godot/tmp/runtime-identity-%d" % OS.get_process_id())
	DirAccess.make_dir_recursive_absolute(fixture+"/data")
	var file:=FileAccess.open(fixture+"/data/sol.ail",FileAccess.WRITE);file.store_string("old nested planet data");file.close()
	var first:=SimBridge.runtime_inputs(fixture)
	check("collector includes nested relative source",first.has("data/sol.ail"))
	file=FileAccess.open(fixture+"/data/sol.ail",FileAccess.WRITE);file.store_string("new nested planet data");file.close()
	check("nested module edit invalidates bundled cache",SimBridge.runtime_fingerprint("v0.52.0",first)!=SimBridge.runtime_fingerprint("v0.52.0",SimBridge.runtime_inputs(fixture)))
	DirAccess.remove_absolute(fixture+"/data/sol.ail");DirAccess.remove_absolute(fixture+"/data");DirAccess.remove_absolute(fixture)
	quit(1 if failures else 0)
