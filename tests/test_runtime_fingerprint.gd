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
	# R2-CREW: a vendored package the sim depends on by path is part of the bundle's identity.
	var vend:=fixture+"-vendor"
	DirAccess.make_dir_recursive_absolute(vend+"/crew-core")
	file=FileAccess.open(vend+"/crew-core/session.ail",FileAccess.WRITE);file.store_string("crew_core 0.2.0");file.close()
	var withVendor:=SimBridge.bundle_inputs(fixture,vend)
	check("bundle includes vendored packages",withVendor.has("../vendor/crew-core/session.ail") and withVendor.has("data/sol.ail"))
	file=FileAccess.open(vend+"/crew-core/session.ail",FileAccess.WRITE);file.store_string("crew_core 0.3.0");file.close()
	check("re-vendored package invalidates bundled cache",SimBridge.runtime_fingerprint("v0.52.0",withVendor)!=SimBridge.runtime_fingerprint("v0.52.0",SimBridge.bundle_inputs(fixture,vend)))
	DirAccess.remove_absolute(vend+"/crew-core/session.ail");DirAccess.remove_absolute(vend+"/crew-core");DirAccess.remove_absolute(vend)
	DirAccess.remove_absolute(fixture+"/data/sol.ail");DirAccess.remove_absolute(fixture+"/data");DirAccess.remove_absolute(fixture)
	quit(1 if failures else 0)
