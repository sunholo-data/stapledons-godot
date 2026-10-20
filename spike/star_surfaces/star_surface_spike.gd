extends SceneTree
## SPIKE for the R2-STAR-SURFACES design (throwaway; not wired into make, not shipped: spike/ is
## outside the export filter). Free navigation through the real sim to a red dwarf (TRAPPIST-1),
## a giant (Aldebaran), a Sun-like star (alpha Cen A) and home (Earth, the Sun at 1 AU), as
## tools/stops_capture.gd does. At each stop the star discs' material is switched to the spike
## shader (spike/star_surfaces/star_surface_spike.gdshader: the game's disc shader plus a surface
## modulation, a resolution fade, a Baumbach corona and prominences) and the sky is shot with
## the surface off and on, in Realistic and Auto, with a nearest-neighbour crop of the disc.
## Then a synthetic eclipse: the same shader, the Sun just behind a dark limb.
## Run: godot --path . --script spike/star_surfaces/star_surface_spike.gd (GPU window).
var demo: Node
var OUT := "res://renders/star_surfaces"
var rows: Array = []
const SPIKE := preload("res://spike/star_surfaces/star_surface_spike.gdshader")
const W := 2560
const H := 1440
var img_w := W
var img_h := H

func _initialize() -> void: _run.call_deferred()

func _run() -> void:
	root.size = Vector2i(W, H)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	demo = load("res://demos/ship_geometry_demo.tscn").instantiate(); root.add_child(demo); demo.auto = false
	await process_frame
	if not demo.ready_ok: quit(1); return
	var probe := root.get_texture().get_image(); img_w = probe.get_width(); img_h = probe.get_height()
	print("spike: frame ", img_w, "x", img_h, " sky ", demo.sky.size)
	demo.journey_auto_tick = false
	var only := OS.get_cmdline_user_args()
	var list: Array = [["trappist1", "Gaia DR3 2635476908753563008"], ["aldebaran", "CNS5:1142"], ["acen_a", "CNS5:3627"], ["earth", "Sol"]]
	var k_earth := 1.0
	for stop in list:
		if only.size() > 0 and not only.has(stop[0]): continue
		demo.open_navigation()
		if stop[1] == "Sol": demo.journey_map.plan_home()
		else: demo.journey_map.preselect(demo.journey_map.index_of(stop[1]))
		if not await leg():
			print("spike: no arrival at ", stop[0], " (", demo.journey_map.status_text(), ")"); continue
		await shots(stop[0])
		if stop[0] == "earth": k_earth = demo.sky.exposure.k()
	if only.is_empty() or only.has("eclipse"):
		await eclipse(k_earth)
	var f := FileAccess.open(OUT + "/spike.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(rows, "  ") + "\n")
	print("star-surface-spike: OK ", rows.size()); quit()

func leg() -> bool:
	var map = demo.journey_map
	demo.journey_tick()
	if not (map.open_commit_dialog() and map.hold_commit(GalaxyMap.HOLD_S) and demo.journey_tick() and demo.live_journey):
		printerr("spike: commit failed: ", map.status_text()); return false
	for i in 6000:
		if not demo.journey_tick() or not demo.live_journey: break
	await process_frame
	return map.journey_state() == "arrived"

## Per star type: cells across the diameter, contrast, spots (lat deg, lon deg, radius rad), umbra.
## Sun: granules ~1.3 Mm on a 1.39 Gm diameter (~1,000 across), rms contrast ~0.13-0.15 at 500 nm;
## spots 10-20 Mm penumbral radius (0.015-0.03 rad), umbra ~0.25, penumbra ~0.8.
## Giant (Aldebaran, log g 1.1): cell size ~10 pressure scale heights, ~1,500x the Sun's -> ~30 across.
## M dwarf (TRAPPIST-1): granules unresolvable at any stop; large cool spots and bright faculae inferred.
func params_for(id: String, teff: float, radius_km: float) -> Dictionary:
	if id.contains("trappist") or teff < 3200.0:
		return {"cells": 4000.0, "contrast": 0.05, "umbra": 0.55, "pen": 0.85, "facula": 0.10,
			"spots": [[18, 30, 0.22], [-25, 160, 0.16], [40, 250, 0.12], [-8, 300, 0.09]], "limb_u": 0.75}
	if radius_km > 5.0e6:
		return {"cells": 33.0, "contrast": 0.20, "umbra": 1.0, "pen": 1.0, "facula": 0.0, "spots": [], "limb_u": 0.8}
	return {"cells": 1000.0 * radius_km / 695700.0, "contrast": 0.14, "umbra": 0.25, "pen": 0.8, "facula": 0.08,
		"spots": [[14, 20, 0.028], [12, 32, 0.016], [-22, 140, 0.022], [9, 250, 0.012], [-17, 330, 0.018]], "limb_u": 0.62}

func apply(m: ShaderMaterial, p: Dictionary, px_r: float, on: bool, seed: float) -> void:
	m.shader = SPIKE
	m.set_shader_parameter("surf_on", on)
	m.set_shader_parameter("px_per_radius", px_r)
	m.set_shader_parameter("cells_across", p.cells)
	m.set_shader_parameter("gran_contrast", p.contrast)
	m.set_shader_parameter("gran_seed", seed)
	m.set_shader_parameter("umbra_i", p.umbra)
	m.set_shader_parameter("penumbra_i", p.pen)
	m.set_shader_parameter("facula_c", p.facula)
	if on: m.set_shader_parameter("limb_u", p.limb_u)
	var arr := PackedVector4Array()
	for s: Array in p.spots:
		var lat := deg_to_rad(float(s[0])); var lon := deg_to_rad(float(s[1]))
		arr.append(Vector4(cos(lat) * cos(lon), sin(lat), cos(lat) * sin(lon), float(s[2])))
	m.set_shader_parameter("spot_count", arr.size())
	while arr.size() < 12: arr.append(Vector4.ZERO)
	m.set_shader_parameter("spots", arr)

func shots(name: String) -> void:
	var sv = demo.sky.system_view
	demo.look_direction("forward")
	if not demo.sky_only: demo.toggle_sky_only()
	for i in 6: await process_frame
	var fov_rad := deg_to_rad(demo.sky.camera.fov)
	var found := false
	for b: Dictionary in demo.sky_world.get("system", {}).get("bodies", []):
		if b.kind != "star" or not sv.discs.has(b.id): continue
		var d := Planets.length64(Planets.world_of(b.rel_km))
		var ang := Planets.angular_radius(b.radius_km, d)
		var px_r := ang / (fov_rad / float(demo.sky.size.y)) * float(img_h) / float(demo.sky.size.y)
		var p := params_for(b.id, float(b.get("teff_k", Planets.T_SUN)), b.radius_km)
		var m: ShaderMaterial = sv.discs[b.id].material_override
		apply(m, p, px_r, false, float(b.id.hash() % 1000))
		var row := {"stop": name, "star": b.id, "radius_km": b.radius_km, "distance_km": d,
			"apparent_diameter_deg": rad_to_deg(2.0 * ang), "disc_px_across": 2.0 * px_r, "frame": "%dx%d" % [img_w, img_h],
			"cell_px_at_centre": 2.0 * px_r / p.cells, "teff_k": b.get("teff_k", Planets.T_SUN)}
		rows.append(row); print("spike ", JSON.stringify(row))
		if px_r < 1.0: continue
		found = true
		await shot(name + "_auto_off", true)
		row["frame_ms_off"] = await frame_ms()
		apply(m, p, px_r, true, float(b.id.hash() % 1000))
		var img: Image = await shot(name + "_auto_on", true)
		row["frame_ms_on"] = await frame_ms()
		row["frame_ms_off_again"] = await frame_ms_off_again(m, p, px_r, b.id)
		print("spike frame-ms ", name, " off ", row.frame_ms_off, " on ", row.frame_ms_on, " off again ", row.frame_ms_off_again)
		apply(m, p, px_r, true, float(b.id.hash() % 1000))
		var at := disc_px(m)
		crop(img, name + "_auto_on_crop", px_r, at)
		var img_off: Image = await reshoot_off(m, p, px_r, b.id, name)
		crop(img_off, name + "_auto_off_crop", px_r, at)
		apply(m, p, px_r, true, float(b.id.hash() % 1000))
		var real: Image = await shot(name + "_realistic_on", false)
		crop(real, name + "_realistic_on_crop", px_r, at)
	if not found: print("spike: no resolved star disc at ", name)
	if demo.sky_only: demo.toggle_sky_only()
	demo.set_auto_view(false)

## Mean frame time (ms) with vsync off over 240 frames: the whole frame, CPU and GPU.
func frame_ms() -> float:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	for i in 30: await process_frame
	var t0 := Time.get_ticks_usec()
	for i in 240: await RenderingServer.frame_post_draw
	var ms := float(Time.get_ticks_usec() - t0) / 240.0 / 1000.0
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	return ms

## Mean GPU time of the sky SubViewport over 60 frames (ms).
func gpu_ms() -> float:
	var rid: RID = root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)
	RenderingServer.viewport_set_measure_render_time(demo.sky.get_viewport_rid(), true)
	for i in 10: await process_frame
	var t := 0.0
	for i in 60:
		await RenderingServer.frame_post_draw
		t += RenderingServer.viewport_get_measured_render_time_gpu(rid) + RenderingServer.viewport_get_measured_render_time_gpu(demo.sky.get_viewport_rid())
	return t / 60.0

func frame_ms_off_again(m: ShaderMaterial, p: Dictionary, px_r: float, id: String) -> float:
	apply(m, p, px_r, false, float(id.hash() % 1000))
	return await frame_ms()

func reshoot_off(m: ShaderMaterial, p: Dictionary, px_r: float, id: String, name: String) -> Image:
	apply(m, p, px_r, false, float(id.hash() % 1000))
	return await shot(name + "_auto_off", true)

func shot(name: String, auto: bool) -> Image:
	demo.set_auto_view(auto)
	for i in 8: await process_frame
	demo.sky.update_exposure()
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img_w = img.get_width(); img_h = img.get_height()
	img.save_png(OUT + "/" + name + ".png")
	return img

## The disc centre in image pixels: the sky camera's projection of the disc's placed centre.
func disc_px(m: ShaderMaterial) -> Vector2i:
	var c: Vector3 = m.get_shader_parameter("centre_w")
	var cam: Camera3D = demo.sky.camera
	var p := cam.unproject_position(c)
	return Vector2i(int(p.x * float(img_w) / float(demo.sky.size.x)), int(p.y * float(img_h) / float(demo.sky.size.y)))

## Nearest-neighbour crop around the disc centre, to 720x720.
func crop(img: Image, name: String, px_r: float, at: Vector2i) -> void:
	var half := int(clampf(px_r * 1.25, 12.0, 640.0))
	var r := Rect2i(at - Vector2i(half, half), Vector2i(2 * half, 2 * half)).intersection(Rect2i(0, 0, img.get_width(), img.get_height()))
	var c := img.get_region(r); c.resize(720, 720, Image.INTERPOLATE_NEAREST)
	c.save_png(OUT + "/" + name + ".png")

## Synthetic eclipse (not a sim state): a Sun-like star 3.5 deg across (TRAPPIST-1's size at its stop;
## the Sun from 0.15 AU) behind a dark occulter 4% larger, as a moon at totality; eye-adapted exposure
## (the corona at 2 R -> 0.3 pre-tonemap). The game's disc shader (spike) for both bodies.
func eclipse(k: float) -> void:
	if demo != null: demo.queue_free(); await process_frame
	var vp := SubViewport.new(); vp.size = Vector2i(W, H); vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS; vp.use_hdr_2d = true
	root.add_child(vp)
	var env := Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color.BLACK
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	var we := WorldEnvironment.new(); we.environment = env; vp.add_child(we)
	var cam := Camera3D.new(); cam.fov = 78.0; cam.keep_aspect = Camera3D.KEEP_HEIGHT; cam.far = 4000.0; vp.add_child(cam); cam.current = true
	var sun_ang := deg_to_rad(3.5 / 2.0)
	var px_r := sun_ang / (deg_to_rad(78.0) / float(H))
	for variant in [["eclipse_diamond_ring", 0.10], ["eclipse_total", 0.0]]:
		for n in vp.get_children():
			if n is MeshInstance3D: n.queue_free()
		await process_frame
		var sun := disc_mesh(vp, Vector3(0, 0, -100), 100.0 * tan(sun_ang), 0)
		var sm: ShaderMaterial = sun.material_override
		sm.set_shader_parameter("star", true)
		var e_v := 1.27e5 # lx at 1 AU
		sm.set_shader_parameter("star_mean", e_v / (PI * sin(sun_ang) * sin(sun_ang)))
		sm.set_shader_parameter("limb_u", 0.6)
		sm.set_shader_parameter("tint", Blackbody.rgb_unit_luminance(Planets.T_SUN))
		var centre := e_v / (PI * sin(sun_ang) * sin(sun_ang)) / (1.0 - 0.6 / 3.0)
		var k_ecl := 0.3 / (centre * 1.0e-6 * (0.0532 * pow(2.0, -2.5) + 1.425 * pow(2.0, -7.0) + 2.565 * pow(2.0, -17.0)))
		sm.set_shader_parameter("exposure", k_ecl)
		sm.set_shader_parameter("corona_outer", 6.0)
		var proms := PackedVector4Array([Vector4(0.7, 0.71, 0, 0.06), Vector4(-0.6, 0.8, 0, 0.04), Vector4(0.95, -0.31, 0, 0.08), Vector4(-0.99, 0.14, 0, 0.03)])
		for i in proms.size():
			var v := Vector3(proms[i].x, proms[i].y, proms[i].z).normalized()
			proms[i] = Vector4(v.x, v.y, v.z, proms[i].w)
		while proms.size() < 6: proms.append(Vector4.ZERO)
		sm.set_shader_parameter("prom_count", 4); sm.set_shader_parameter("proms", proms)
		apply(sm, params_for("sun", Planets.T_SUN, 695700.0), px_r, true, 7.0)
		sm.set_shader_parameter("corona_outer", 6.0)
		# the occulter: 1.04x the star's angular radius at 50 units, its centre variant[1] stellar radii off
		var off_ang: float = float(variant[1]) * sun_ang
		var dir := Vector3(-0.5 * sin(off_ang), -0.866 * sin(off_ang), -cos(off_ang))
		var moon := disc_mesh(vp, dir * 50.0, 50.0 * tan(1.04 * sun_ang), 1)
		var mm: ShaderMaterial = moon.material_override
		mm.set_shader_parameter("star", false); mm.set_shader_parameter("rho", 0.0); mm.set_shader_parameter("lux", 0.0)
		mm.set_shader_parameter("exposure", k_ecl)
		for i in 10: await process_frame
		await RenderingServer.frame_post_draw
		var img := vp.get_texture().get_image()
		img.save_png(OUT + "/" + variant[0] + ".png")
		var c := img.get_region(Rect2i(W / 2 - 240, H / 2 - 240, 480, 480)); c.resize(960, 960, Image.INTERPOLATE_BILINEAR)
		c.save_png(OUT + "/" + variant[0] + "_crop.png")
		rows.append({"stop": variant[0], "synthetic": true, "sun_px_across": 2.0 * px_r, "exposure_k_star_friendly": k, "exposure_k_eye_adapted": k_ecl})

func disc_mesh(vp: Node, centre: Vector3, radius: float, prio: int) -> MeshInstance3D:
	var mi := MeshInstance3D.new(); var q := QuadMesh.new(); q.size = Vector2(2, 2); mi.mesh = q
	var m := ShaderMaterial.new(); m.shader = SPIKE; m.render_priority = prio; mi.material_override = m
	mi.extra_cull_margin = 16384.0; vp.add_child(mi)
	m.set_shader_parameter("centre_w", centre); m.set_shader_parameter("radius", radius); m.set_shader_parameter("ss", 4)
	return mi
