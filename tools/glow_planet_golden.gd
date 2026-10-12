extends SceneTree
## Native composition: actual AILANG body fields, controlled night-side placement.
var failures:=0
func _initialize()->void:run.call_deferred()
func check(label:String,ok:bool)->void:
	print("ok " if ok else "FAIL ",label)
	if not ok:failures+=1
func grab(sky:InteriorSky)->Image:
	for frame in 3:await process_frame
	await RenderingServer.frame_post_draw
	return sky.get_texture().get_image()
func run()->void:
	root.size=Vector2i(640,480)
	var sky:=InteriorSky.new();root.add_child(sky)
	sky.setup({"position_m":[0,0,0],"forward":[0,0,1],"up":[0,1,0]},60.,root.size,{"stars":false,"background":false,"planet_textures":false,"planet_preload":false})
	sky.env.tonemap_mode=Environment.TONE_MAPPER_LINEAR;sky.env.glow_enabled=false
	sky.camera.look(0.,0.,0.)
	sky.glow_mat.set_shader_parameter("ship_x",Vector3.RIGHT);sky.glow_mat.set_shader_parameter("ship_y",Vector3.UP);sky.glow_mat.set_shader_parameter("ship_z",Vector3(0,0,-1))
	sky.glow_mat.set_shader_parameter("pole",0.11250843031053141);sky.glow_mat.set_shader_parameter("t_pole",14114.023335759706);sky.glow_mat.set_shader_parameter("scale",.1/PI)
	var wall:=await grab(sky)
	var sim:=SimBridge.new();sim.want_minor=5
	if not sim.start() or not sim.new_game(7):check("normal body producer",false);quit(1);return
	var jupiter:Dictionary={}
	for b:Dictionary in sim.world.system.bodies:
		if b.id=="jupiter":jupiter=b.duplicate(true)
	jupiter.rel_km={"x":300000.,"y":0.,"z":0.};jupiter.sun_dir={"x":1.,"y":0.,"z":0.};jupiter.phase_deg=180.
	var world_before:=sim.world.duplicate(true)
	sky.starfield.set_custom_stars([{"name":"behind-night-globe","pos":Vector3(0,0,-1000),"t":6600.,"flux":1.}]);sky.starfield.set_exposure(.1)
	var unobstructed:=await grab(sky)
	sky.system_view.update({"bodies":[jupiter]},.1)
	var composite:=await grab(sky)
	var c:=Vector2i(320,240);var reference:=wall.get_pixelv(c);var observed:=composite.get_pixelv(c)
	var err:=maxf(absf(reference.r-observed.r),maxf(absf(reference.g-observed.g),absf(reference.b-observed.b)))
	check("night globe retains foreground spectral wall (1% or 0.001)",reference.get_luminance()>.01 and err<maxf(.001,reference.get_luminance()*.01))
	check("background star contributes without globe",unobstructed.get_pixelv(c).get_luminance()>reference.get_luminance()+.01)
	sky.glow_mat.render_priority=0
	var old_order:=await grab(sky)
	check("negative control old ordering erases wall on night globe",old_order.get_pixelv(c).get_luminance()<.001)
	sky.glow_mat.render_priority=126
	check("physical globe occludes observed star direction",sky.system_view.occludes_direction(PackedFloat64Array([0,0,-1])))
	sky.glow_mat.set_shader_parameter("pole",0.)
	var black:=await grab(sky)
	check("opaque night globe still hides star when wall off",black.get_pixelv(c).get_luminance()<.001)
	check("ordering finite body < wall < planet PSF",sky.system_view.discs.jupiter.material_override.render_priority<sky.glow_mat.render_priority and sky.glow_mat.render_priority<127)
	check("render does not mutate authoritative world",sim.world==world_before)
	DirAccess.make_dir_recursive_absolute("res://renders/m4/composition")
	composite.save_png("res://renders/m4/composition/night_globe_wall.png");black.save_png("res://renders/m4/composition/night_globe_no_wall.png");wall.save_png("res://renders/m4/composition/wall_reference.png")
	sim.stop();sky.queue_free();await process_frame
	print("glow-planet-golden: %d failures"%failures);quit(1 if failures else 0)
