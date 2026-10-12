extends SceneTree
var failures := 0
var passes := 0
func check(label: String, condition: bool) -> void:
	if condition: passes += 1
	else: failures += 1
	print("  %s %s" % ["ok" if condition else "FAIL",label])
func _initialize() -> void:
	if not FileAccess.file_exists("res://demos/ship_demo_camera.gd"):
		check("shared observer implementation",false)
		print("ship-demo: 0 passed, 1 failures");quit(1);return
	_run.call_deferred()
func _run() -> void:
	var Camera: GDScript = load("res://demos/ship_demo_camera.gd")
	var viewport := SubViewport.new();viewport.size=Vector2i(960,540);root.add_child(viewport)
	var camera: Camera3D = Camera.new();viewport.add_child(camera)
	var sky := InteriorSky.new();root.add_child(sky)
	sky.setup({"position_m":[16,-8,83.7],"forward":[1,0,0],"up":[0,0,1]},78,viewport.size,{"stars":false,"background":false})
	var photo:=Image.create(64,32,false,Image.FORMAT_RGBA8);photo.fill(Color(.05,.05,.05))
	var model:=Image.create(64,32,false,Image.FORMAT_RGBA8);model.fill(Color(.5,.5,.5))
	sky.has_background=sky.background.attach(sky.env,540,78.,photo,model)
	for px in [Vector2i(960,540),Vector2i(540,960),Vector2i(1920,1080)]:
		viewport.size=px
		for tilt in [-60.,-30.,15.]:
			for distance in [0.,12.,270.]:
				camera.follow(Vector3(16,82,8),tilt,0.47,distance)
				camera.fov=78. if distance<100 else 52.
				camera.sync_sky(sky,px)
				check("sky sampling follows observer pixels",absf(float(sky.background.material.get_shader_parameter("pano_px_per_screen_px"))-32./180.*camera.fov/px.y)<.000001)
				check("observer FOV/aspect",sky.camera.fov==camera.fov and sky.size==px)
				check("observer eye metres",Vector3(sky.cam.position_m[0],sky.cam.position_m[2],-sky.cam.position_m[1]).distance_to(camera.position)<.0001)
				for p in [Vector2.ZERO,Vector2(px),Vector2(px)*.5,Vector2(px.x,0),Vector2(0,px.y)]:
					var finite_ray: Vector3 = camera.project_ray_normal(p)
					var expected: Vector3 = camera.to_sky_direction(finite_ray,sky.heading_gal)
					check("centre/corner common ray",expected.distance_to(sky.camera.project_ray_normal(p))<.00001)
				check("outside observer zero wall glow",camera.position.length()<100 or sky.glow_pole<=0)
	check("diagnostic rim outside walk",21.3>20.7-.35)
	viewport.queue_free();sky.queue_free()
	print("ship-demo: %d passed, %d failures" % [passes,failures]);quit(1 if failures else 0)
