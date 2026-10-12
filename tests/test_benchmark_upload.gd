extends SceneTree
const Upload=preload('res://demos/benchmark_upload.gd')
var failed:=0
func check(ok:bool,label:String)->void:
	print(('ok ' if ok else 'FAIL ')+label)
	if not ok:failed+=1
func _initialize()->void:_run.call_deferred()
func _run()->void:
	var source:Dictionary={'build':'fixture','resolution':[1920,1080],'measured_hardware':{'cpu':'Apple M2','memory':{'free':123},'path':'/Users/private'},'sky_review':{'beta':0.,'private':'/Users/private'},'views':[{'view':'bridge','frame_times':{'p95_ms':19.},'frame_times_ms':[16.,50.,229.],'private':'/Users/private'}]}
	var public:Dictionary=Upload.public_summary(source)
	check(not JSON.stringify(public).contains('/Users/private') and not public.measured_hardware.has('memory'),'public summary excludes paths and dynamic memory')
	check(not public.views[0].has('frame_times_ms') and public.views[0].stalls_over_25ms==[{'sample':1,'ms':50.},{'sample':2,'ms':229.}],'retain indexed stalls without full frame arrays')
	check(public.views[0].frame_times.p95_ms==19. and public.measured_hardware.cpu=='Apple M2','timings and target hardware preserved')
	var path:=ProjectSettings.globalize_path('user://mock-gcloud-upload.sh')
	for code in [0,7]:
		var f:=FileAccess.open(path,FileAccess.WRITE);f.store_string('#!/bin/sh\n/bin/sleep 1\nexit %d\n'%code);f.close()
		OS.execute('/bin/chmod',PackedStringArray(['+x',path]))
		var upload:=Upload.new();var before:=Time.get_ticks_msec()
		check(upload.start(source,path),'asynchronous upload starts')
		check(upload.poll().is_empty(),'child upload remains pending while main thread continues')
		var result:Dictionary={}
		while result.is_empty():
			await create_timer(.02).timeout;result=upload.poll()
		check(result.ok==(code==0) and (not result.url.is_empty())==(code==0),'link only appears after confirmed upload success')
		check(upload.poll().is_empty(),'completion delivered once')
		if code!=0:check(result.status.contains('local report retained'),'failed upload retains local fallback')
	print('benchmark-upload: %d failures'%failed);quit(1 if failed else 0)
