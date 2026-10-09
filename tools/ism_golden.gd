extends RefCounted
## R1-ISM-DUST I5 goldens (make golden; main.gd loads this by path, tools/ is not exported).
## The flash shader interior/dust_flash.gdshader against its CPU reference interior/dust_flash.gd,
## read back from the sky SubViewport (linear, before the one tonemap):
##   G-ISM-1  peak and decay: a 5 um grain's flash at 0.999c straight ahead, unit-gain target, at
##            t = 0, tau, 3 tau: the pixel equals DustFlash.emittance within 1 %; outside the
##            spot (3 r_s) it is 0; a flash at 45 deg lands on its own wall point.
##   G-ISM-2  colour ramp: debug_colour at 8 temperatures 1,000 K .. 40,000 K: rgb(T) x eta(T) x
##            (1 / eta_exact(T)) equals ForwardGlow.colour(T) within 1 % of its largest channel.
##   G-ISM-3  glitter count: a fixed glitter descriptor's sprites (DustFlash.glitter_events, seed
##            fixed) all light their own wall point, and the number lit equals the CPU count.

const BUNDLE := "res://assets/areas/bridge"
const KE5 := 3318048.4379902543 # J: 5 um at 3,300 kg/m^3, 0.999c (HB-139..141 oracle)
const RAMP := [1000.0, 2000.0, 3000.0, 4393.0, 6600.0, 10000.0, 20000.0, 40000.0]

var main: Node
var it: Interior
var size := Vector2i.ZERO


func run(m: Node) -> int:
	main = m
	size = main.get_window().size
	it = Interior.new()
	if not it.setup(AreaBundle.load_dir(BUNDLE), {"size": size, "canvas": Vector2(size), "background": false, "stars": false}):
		print("FAIL  ism golden: setup %s" % it.last_error)
		return 1
	it.auto = false
	main.add_child(it)
	it.layer_nodes()["hud"].visible = false
	var f := 0
	f += await _g1()
	f += await _g2()
	f += await _g3()
	it.queue_free()
	await main.get_tree().process_frame
	print("ism golden: %d failures" % f)
	return f


func _sky_image() -> Image:
	for i in 3:
		await main.get_tree().process_frame
	await RenderingServer.frame_post_draw
	return it.sky.get_texture().get_image()


func _mat() -> ShaderMaterial:
	it.sky.dust_auto = false
	var mat: ShaderMaterial = it.sky.dust_mat
	mat.set_shader_parameter("ship_x", Vector3(1, 0, 0))
	mat.set_shader_parameter("ship_y", Vector3(0, 1, 0))
	mat.set_shader_parameter("ship_z", Vector3(0, 0, 1))
	mat.set_shader_parameter("cam_ship", Vector3.ZERO)
	mat.set_shader_parameter("radius", 100.0)
	mat.set_shader_parameter("r_spot", DustFlash.R_SPOT)
	return mat


func _one(mat: ShaderMaterial, dir: Vector3, e: float, t: float) -> void:
	var fl := PackedVector4Array()
	fl.resize(64)
	var ts := PackedFloat32Array()
	ts.resize(64)
	fl[0] = Vector4(dir.x, dir.y, dir.z, e)
	ts[0] = t
	mat.set_shader_parameter("flash", fl)
	mat.set_shader_parameter("flash_t", ts)
	mat.set_shader_parameter("count", 1)


## Look along ship-frame unit d (the sky frame = the ship frame here).
func _look(d: Vector3) -> void:
	it.sky.camera.look(atan2(-d.x, -d.z), asin(clampf(d.y, -1.0, 1.0)), 0.0)


func _g1() -> int:
	var sky := it.sky
	var mat := _mat()
	var fails := 0
	sky.set_debug_unit(true)
	mat.set_shader_parameter("debug_unit", true)
	mat.set_shader_parameter("debug_colour", false)
	# (a) peak and decay straight ahead; x 1e3 keeps the unit-gain half-float target well inside its range
	_look(Vector3(0, 0, 1))
	for k: float in [0.0, 1.0, 3.0]:
		var t := k * DustFlash.TAU
		var want := DustFlash.emittance(KE5, 1e-7, 0.5, DustFlash.R_SPOT, DustFlash.TAU, t)
		_one(mat, Vector3(0, 0, 1), want, DustFlash.temperature(KE5, DustFlash.R_SPOT, DustFlash.TAU, t))
		var img := await _sky_image()
		var got := img.get_pixel(size.x / 2, size.y / 2).r
		var ok := absf(got - want) <= 0.01 * want
		fails += 0 if ok else 1
		print("%s  G-ISM-1 flash peak/decay t = %.1f tau: unit-gain pixel %s, CPU E(t) %s W/m^2 (limit 1 %%)" % ["ok  " if ok else "FAIL", k, String.num_scientific(got), String.num_scientific(want)])
	# (b) outside the spot: 3 r_s off-centre along +X on the wall (a pixel here is ~0.4 r_s)
	var off := Vector3(3.0 * DustFlash.R_SPOT / 100.0, 0, 1).normalized()
	_look(off)
	var img_b := await _sky_image()
	var got_b := img_b.get_pixel(size.x / 2, size.y / 2).r
	var ok_b := got_b == 0.0
	fails += 0 if ok_b else 1
	print("%s  G-ISM-1 outside the spot (3 r_s): pixel %s (want 0)" % ["ok  " if ok_b else "FAIL", got_b])
	# (c) a flash at 45 deg: its own wall point is lit, the pole is not
	var d45 := DustFlash.wall_dir(sin(PI / 4.0), 0.0)
	_one(mat, d45, 1.0, 5000.0)
	_look(d45)
	var img_c := await _sky_image()
	var lit45 := absf(img_c.get_pixel(size.x / 2, size.y / 2).r - 1.0) <= 0.01
	_look(Vector3(0, 0, 1))
	var img_d := await _sky_image()
	var dark_pole := img_d.get_pixel(size.x / 2, size.y / 2).r == 0.0
	fails += 0 if lit45 and dark_pole else 1
	print("%s  G-ISM-1 a flash at 45 deg lights its own wall point (%s) and not the pole (%s)" % ["ok  " if lit45 and dark_pole else "FAIL", lit45, dark_pole])
	mat.set_shader_parameter("count", 0)
	mat.set_shader_parameter("debug_unit", false)
	sky.set_debug_unit(false)
	return fails


func _g2() -> int:
	var sky := it.sky
	var mat := _mat()
	var fails := 0
	sky.set_debug_unit(true)
	mat.set_shader_parameter("debug_unit", false)
	mat.set_shader_parameter("debug_colour", true)
	_look(Vector3(0, 0, 1))
	for t: float in RAMP:
		_one(mat, Vector3(0, 0, 1), 1.0, t)
		mat.set_shader_parameter("scale", 1.0 / ForwardGlow.efficacy(t))
		var img := await _sky_image()
		var px := img.get_pixel(size.x / 2, size.y / 2)
		var got := Vector3(px.r, px.g, px.b)
		var want := ForwardGlow.colour(t)
		var m := maxf(want.x, maxf(want.y, want.z))
		var err := maxf(absf(got.x - want.x), maxf(absf(got.y - want.y), absf(got.z - want.z))) / m
		var ok := err <= 0.01
		fails += 0 if ok else 1
		print("%s  G-ISM-2 colour %6.0f K: shader (%.4f, %.4f, %.4f) vs CPU (%.4f, %.4f, %.4f), worst %.3f %% (limit 1 %%)" % ["ok  " if ok else "FAIL", t, got.x, got.y, got.z, want.x, want.y, want.z, err * 100.0])
	mat.set_shader_parameter("debug_colour", false)
	mat.set_shader_parameter("count", 0)
	sky.set_debug_unit(false)
	sky.update_exposure()
	return fails


func _g3() -> int:
	var sky := it.sky
	var mat := _mat()
	sky.set_debug_unit(true)
	mat.set_shader_parameter("debug_unit", true)
	mat.set_shader_parameter("debug_colour", false)
	var g := {"rate": 600.0, "a_lo_um": 1.3, "a_hi_um": 2.8, "q": 3.1, "seed": 424242}
	var evs := DustFlash.glitter_events(g, 0.05, 707.1, DustFlash.MAX_SPRITES)
	var fl := PackedVector4Array()
	fl.resize(64)
	var ts := PackedFloat32Array()
	ts.resize(64)
	for i in evs.size():
		var d := DustFlash.wall_dir(evs[i].x, evs[i].y)
		fl[i] = Vector4(d.x, d.y, d.z, 1.0)
		ts[i] = 5000.0
	mat.set_shader_parameter("flash", fl)
	mat.set_shader_parameter("flash_t", ts)
	mat.set_shader_parameter("count", evs.size())
	var lit := 0
	for e: Dictionary in evs:
		_look(DustFlash.wall_dir(e.x, e.y))
		var img := await _sky_image()
		if img.get_pixel(size.x / 2, size.y / 2).r >= 0.99:
			lit += 1
	var ok := lit == evs.size() and evs.size() > 10
	print("%s  G-ISM-3 glitter count: %d of %d CPU glitter sprites lit their wall points (seed 424242, rate 600 /s, 0.05 s)" % ["ok  " if ok else "FAIL", lit, evs.size()])
	mat.set_shader_parameter("count", 0)
	mat.set_shader_parameter("debug_unit", false)
	sky.set_debug_unit(false)
	return 0 if ok else 1
