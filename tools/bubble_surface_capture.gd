extends SceneTree
## Native A/B of the same seeded stream, plus labelled geometry-only incidence probes.
## Run make ism-determinism before this tool; it takes the maximum-count cruise tick.
const OUT:="res://renders/bubble_surface"
var sky:InteriorSky
var world:Dictionary={}
var live:Array=[]
var rows:=[]
var failures:=0
func _initialize()->void:run.call_deferred()
func settle()->void:
	for i in 5:await process_frame
	await RenderingServer.frame_post_draw
func capture(name:String,surface:bool)->void:
	sky.dust_mat.set_shader_parameter("surface_marks",surface)
	sky.set_dust_flashes(sky._dust_input,sky.dust_mat.get_shader_parameter("flash_t"),sky._dust_count)
	await settle();var img:=sky.get_texture().get_image();img.save_png(OUT+"/"+name+".png")
	rows.append({"file":name+".png","surface":surface,"count":sky._dust_count,"fov":sky.camera.fov,"observer_m":sky.cam.position_m})
func look(dir:Vector3)->void:
	var axes:=[]
	for i in 3:axes.append(sky._vec(sky._to_world(PackedFloat64Array([sky.basis[3*i],sky.basis[3*i+1],sky.basis[3*i+2]]))))
	var d:Vector3=axes[0]*dir.x+axes[1]*dir.y+axes[2]*dir.z
	sky.camera.look(atan2(-d.x,-d.z),asin(clampf(d.y,-1.,1.)),0.)
func run()->void:
	root.size=Vector2i(1280,720);root.title="Bubble wall: same events, circle / surface"
	DirAccess.make_dir_recursive_absolute(OUT)
	var stream:=FileAccess.get_file_as_string("res://.godot/tmp/ism/det-vm1.txt");var merged:Dictionary={};var max_count:=-1
	for line:String in stream.strip_edges().split("\n"):
		var row:Dictionary=JSON.parse_string(line)
		for k:String in row.changes:merged[k]=row.changes[k]
		if merged.get("ship",{}).get("phase","")=="cruising":
			var count:int=merged.ship.ism.impacts.size()
			if count>max_count:max_count=count;world=merged.duplicate(true)
	if max_count<1:push_error("A/B requires actual seeded impacts");quit(1);return
	sky=InteriorSky.new();sky.setup({"position_m":[0.,0.,0.],"forward":[0,0,1],"up":[0,1,0]},60.,root.size,{"planet_preload":false,"tier":"large"})
	root.add_child(sky);sky.set_process(false);sky.dust_auto=false;sky.apply(world)
	live=sky.dust.live(0.05);sky.upload_dust(live)
	var rect:=TextureRect.new();rect.texture=sky.get_texture();rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.add_child(rect)
	look(Vector3(0,0,1));sky.update_exposure();sky.exposure.fixed_ev=sky.exposure.ev;sky.exposure.fixed=true
	# Use the source exposure convention; keep the exact same gain for both images.
	var ev:=sky.exposure.ev
	await capture("seeded_forward_circle",false);await capture("seeded_forward_surface",true)
	await capture("seeded_forward_surface_repeat",true)
	var repeated:=FileAccess.get_sha256(OUT+"/seeded_forward_surface.png")==FileAccess.get_sha256(OUT+"/seeded_forward_surface_repeat.png")
	if not repeated:failures+=1
	var brightest:Vector3=live[0].dir
	sky.camera.fov=3.0;sky.view_fov=3.0;sky.configure_pixel();look(brightest)
	await capture("seeded_closeup_circle",false);await capture("seeded_closeup_surface",true)
	# Near-normal/glancing probes: package emission for the same5um grain, not a flight frequency claim.
	var fl:=PackedVector4Array();fl.resize(64);var ts:=PackedFloat32Array();ts.resize(64)
	for n:Vector3 in [Vector3(0,0,1),Vector3(0.95,0,sqrt(1.0-0.95*0.95))]:
		fl[0]=Vector4(n.x,n.y,n.z,DustFlash.emittance(3318048.4379902543,1e-10,0.5,0.5,0.2,0.02));ts[0]=DustFlash.temperature(3318048.4379902543,0.5,0.2,0.02)
		sky.set_dust_flashes(fl,ts,1);look(n)
		var tag:="normal" if n.z>0.99 else "glancing"
		await capture(tag+"_circle",false);await capture(tag+"_surface",true)
	var observer:=Vector3(40,5,-10)
	sky.cam.position_m=[observer.x,observer.y,observer.z]
	sky.dust_mat.set_shader_parameter("cam_ship",observer)
	sky.glow_mat.set_shader_parameter("cam_ship",observer)
	look((100.0*Vector3(fl[0].x,fl[0].y,fl[0].z)-observer).normalized())
	await capture("offcentre_circle",false);await capture("offcentre_surface",true)
	var f:=FileAccess.open(OUT+"/capture_log.json",FileAccess.WRITE);f.store_string(JSON.stringify({"label":"Same seeded LIC events; 3deg closeups are magnified. Normal/glancing/off-centre frames are single-impact geometry probes; no lateral diffusion or particle trails.","stream_sha256":FileAccess.get_sha256("res://.godot/tmp/ism/det-vm1.txt"),"world":world,"fixed_ev":ev,"actual_impacts":max_count,"live_count":live.size(),"native_repeat_identical":repeated,"failures":failures,"frames":rows},"  "))
	print("bubble-capture: %d native frames, %d actual events, %d live sprites, repeat identical %s, %d failures"%[rows.size(),max_count,live.size(),repeated,failures]);quit(1 if failures else 0)
