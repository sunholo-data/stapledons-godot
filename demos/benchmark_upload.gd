extends RefCounted
## Explicitly authorized public audit summaries. No embedded credentials;
## use the same authenticated Cloud CLI as the review installer, off the UI thread.
const BUCKET:="stapledons-voyage-assets"
const PREFIX:="benchmarks/ship"
var _thread:Thread
var _url:=""
var _file:=""
var status:=""
static func public_summary(report:Dictionary)->Dictionary:
	var out:Dictionary={"version":2,"build":report.get("build","unknown"),"resolution":report.get("resolution",[]),"warmup_frames":report.get("warmup_frames",0),"sample_frames":report.get("sample_frames",0),"timer":report.get("timer",""),"GR":report.get("GR",""),"sky_review":{},"sky_exposure_trial":{},"views":[],"measured_hardware":{}}
	for key in ["state","beta","gamma","heading","snapshot_tick","sky_only"]:
		if report.get("sky_review",{}).has(key):out.sky_review[key]=report.sky_review[key]
	for key in ["stops","label","bias_ev"]:
		if report.get("sky_exposure_trial",{}).has(key):out.sky_exposure_trial[key]=report.sky_exposure_trial[key]
	for key in ["model","cpu","gpu","os","renderer","vendor"]:
		out.measured_hardware[key]=report.get("measured_hardware",{}).get(key,"unavailable")
	for view:Dictionary in report.get("views",[]):
		var v:Dictionary={}
		for key in ["view","eye_gltf_m","view_direction","frame_times","draw_calls","rendered_primitives","video_memory_bytes","texture_memory_bytes","p95_within_60fps_budget"]:
			if view.has(key):v[key]=view[key]
		v["stalls_over_25ms"]=[]
		var frames:Array=view.get("frame_times_ms",[])
		for i in frames.size():
			if float(frames[i])>25.:v.stalls_over_25ms.append({"sample":i,"ms":frames[i]})
		out.views.append(v)
	return out
static func cli_path()->String:
	for path in ["/opt/homebrew/bin/gcloud","/usr/local/bin/gcloud","/opt/homebrew/share/google-cloud-sdk/bin/gcloud","/usr/local/share/google-cloud-sdk/bin/gcloud"]:
		if FileAccess.file_exists(path):return path
	var output:=[]
	if OS.execute("/usr/bin/which",PackedStringArray(["gcloud"]),output)==0 and not output.is_empty():return str(output[0]).strip_edges()
	return ""
func start(report:Dictionary,cli_override:="")->bool:
	if _thread!=null and _thread.is_alive():return false
	var cli:String=cli_override if not cli_override.is_empty() else cli_path()
	if cli.is_empty():status="Upload unavailable: Google Cloud CLI not found; local report retained.";return false
	var id:=Time.get_datetime_string_from_system(true).replace(":","").replace("-","")+"-"+Crypto.new().generate_random_bytes(6).hex_encode()
	var relative:=PREFIX+"/"+id+".json"
	_url="https://storage.googleapis.com/"+BUCKET+"/"+relative
	var directory:=ProjectSettings.globalize_path("user://benchmark-public")
	if DirAccess.make_dir_recursive_absolute(directory)!=OK:status="Cannot stage public report; local report retained.";return false
	_file=directory.path_join(id+".json")
	var f:=FileAccess.open(_file,FileAccess.WRITE)
	if f==null:status="Cannot stage public report; local report retained.";return false
	f.store_string(JSON.stringify(public_summary(report),"  "));f.close()
	_thread=Thread.new();status="Uploading public timing summary…"
	var code:=_thread.start(_upload.bind(cli,_file,"gs://"+BUCKET+"/"+relative))
	if code!=OK:_thread=null;status="Could not start upload; local report retained.";return false
	return true
static func _upload(cli:String,file:String,destination:String)->Dictionary:
	var output:=[]
	var path:="/opt/homebrew/bin:/usr/local/bin:"+OS.get_environment("PATH")
	# macOS ships Perl. Its alarm survives exec, bounding a stalled network
	# upload without credentials, shell interpolation or a frozen render thread.
	var rc:=OS.execute("/usr/bin/perl",PackedStringArray(["-e","alarm 60; exec @ARGV; exit 127;","/usr/bin/env","PATH="+path,cli,"storage","cp","--quiet","--content-type=application/json",file,destination]),output,true)
	return {"ok":rc==0,"code":rc}
func poll()->Dictionary:
	if _thread==null or _thread.is_alive():return {}
	var result:Dictionary=_thread.wait_to_finish();_thread=null
	status="Public audit uploaded" if result.ok else "Upload failed (Cloud CLI exit %s); local report retained."%result.code
	return {"ok":result.ok,"url":_url if result.ok else "","status":status}

func _notification(what:int)->void:
	if what==NOTIFICATION_PREDELETE and _thread!=null:
		_thread.wait_to_finish();_thread=null
