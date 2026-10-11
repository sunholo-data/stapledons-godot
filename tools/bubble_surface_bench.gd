extends SceneTree

const SIZE := Vector2i(2560,1440)
const WARMUP := 120
const SAMPLES := 300
var sky: InteriorSky

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps=0
	root.size=SIZE
	sky=InteriorSky.new()
	sky.setup({"position_m":[0.0,0.0,0.0],"forward":[0.0,0.0,1.0],"up":[0.0,1.0,0.0]},78.0,SIZE,{"background":false,"stars":false,"planet_preload":false,"planet_textures":false})
	root.add_child(sky)
	sky.dust_auto=false
	sky.glow.visible=false
	sky.starfield.visible=false
	sky.system_view.visible=false
	var live:Array=[]
	for i in 64:
		var radius:=sqrt((float(i)+0.5)/64.0)
		var angle:=float(i)*2.399963229728653
		live.append({"dir":DustFlash.wall_dir(radius*cos(angle),radius*sin(angle)),"e":0.1,"t":5000.0})
	sky.upload_dust(live)
	sky.dust_mat.set_shader_parameter("scale",1.0)
	if sky.dust_mat.get_shader_parameter("count") != 64:
		push_error("benchmark did not upload64physicalsprites")
		quit(1)
		return
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	var axes := [sky.dust_mat.get_shader_parameter("ship_x"), sky.dust_mat.get_shader_parameter("ship_y"), sky.dust_mat.get_shader_parameter("ship_z")]
	var normal: Vector3 = live[0].dir
	var centre: Vector3 = 100.0 * (axes[0] * normal.x + axes[1] * normal.y + axes[2] * normal.z)
	var pixel := Vector2i(sky.camera.unproject_position(centre))
	var image := sky.get_texture().get_image()
	if image.get_pixelv(pixel).r <= 0.01:
		push_error("benchmark firstflashpixelisnotlit")
		quit(1)
		return
	RenderingServer.viewport_set_measure_render_time(sky.get_viewport_rid(),true)
	var batches:Array=[]
	# Paired off/default-surface runs use unchanged64 live events.
	sky.dust_mat.set_shader_parameter("surface_marks",true)
	for enabled in [false,true,false,true,false,true]:
		sky.dust_mesh.visible=enabled
		for i in WARMUP:await process_frame
		var samples:Array=[]
		for i in SAMPLES:
			await process_frame
			samples.append(RenderingServer.viewport_get_measured_render_time_gpu(sky.get_viewport_rid()))
		samples.sort()
		batches.append({"dust_enabled":enabled,"gpu_p50_ms":samples[150],"gpu_p99_ms":samples[296],"gpu_samples_ms":samples})
	var pairs:Array=[]
	for i in 3:pairs.append(float(batches[i*2+1].gpu_p50_ms)-float(batches[i*2].gpu_p50_ms))
	var sorted_pairs:=pairs.duplicate();sorted_pairs.sort()
	var measured:bool=float(batches[1].gpu_p50_ms)>0.0
	var report:={"hardware":{"gpu":RenderingServer.get_video_adapter_name(),"os":OS.get_name(),"renderer":RenderingServer.get_current_rendering_method()},"resolution":[SIZE.x,SIZE.y],"sprites":64,"warmup_frames":WARMUP,"samples_per_batch":SAMPLES,"paired_increment_ms":pairs,"median_increment_ms":sorted_pairs[1],"target_ms":0.3,"gpu_time_available":measured,"passes":measured and float(sorted_pairs[1])<0.3,"batches":batches}
	var output:=FileAccess.open("res://renders/bubble_surface/gpu_benchmark.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(report,"  "))
	print("dust GPU: ",JSON.stringify({"hardware":report.hardware,"pairs_ms":pairs,"median_ms":sorted_pairs[1],"target_ms":0.3,"measured":measured,"passes":report.passes}))
	quit(0 if report.passes else 1)
