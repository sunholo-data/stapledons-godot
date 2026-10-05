extends SceneTree
## SD4: reuse normal AILANG system state in the physical ship observer.
var failures := 0
var passes := 0
func check(name: String, ok: bool) -> void:
	if ok: passes += 1; print("  ok    ", name)
	else: failures += 1; print("  FAIL  ", name)
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var sim := SimBridge.new(); sim.want_minor = SimBridge.NAV_MINOR
	check("normal protocol2.4 handshake", sim.start())
	check("normal game provides system", sim.new_game(17) and sim.system.get("bodies", []).size() == 21)
	var sky := InteriorSky.new(); root.add_child(sky)
	sky.setup({"position_m":[8,4.8,83.7],"forward":[1,0,0],"up":[0,0,1]},78.,Vector2i(1280,720),{"stars":false,"background":false,"planet_textures":false})
	sky.apply(sim.world)
	var sv = sky.get("system_view")
	check("ship viewport contains existing SystemView", sv is SystemView and sv.get_parent() == sky)
	if sv is SystemView:
		check("same starfield and angular pixel calibration", sv.starfield == sky.starfield and is_equal_approx(sv.px_rad,sky.exposure.pixel_rad))
		check("actual Sol Jupiter and Saturn are points", sv.drawn_points.has("jupiter") and sv.drawn_points.has("saturn"))
		check("Sun centre is not invented near-Earth scene", not sv.drawn_discs.has("sun"))
		var before := sim.world.duplicate(true)
		var resolved := sim.world.duplicate(true)
		# A controlled renderer case from actual AILANG Earth fields, not an itinerary.
		for b: Dictionary in resolved.system.bodies:
			if b.id == "earth": b.rel_km={"x":50000.0,"y":0.0,"z":0.0}
		sky.apply(resolved)
		check("Earth disc uses the existing measured-radius renderer", sv.drawn_discs.has("earth"))
		var mat: ShaderMaterial = sv.discs.earth.material_override
		check("disc exposure equals the shared sky exposure", is_equal_approx(mat.get_shader_parameter("exposure"),sky.exposure.k()))
		var center: Vector3 = mat.get_shader_parameter("centre_w")
		check("body direction matches catalogue SkyFrame", center.normalized().distance_to(Vector3(0,0,-1)) < 1e-6)
		sky.cam.forward=[0,1,0]; sky.orient(sky.heading_gal); sky.update_exposure()
		check("look-around preserves physical heading and body position", sky.heading_gal == PackedFloat64Array([before.ship.heading.x,before.ship.heading.y,before.ship.heading.z]) and center == mat.get_shader_parameter("centre_w"))
		sky.resize(Vector2i(900,600)); sky.update_exposure()
		check("resize refreshes system angular resolution", sv.view_height_px == 600.0 and is_equal_approx(sv.px_rad,sky.exposure.pixel_rad))
		resolved.ship.beta=0.01;resolved.ship.gamma=1.00005000375;sky.apply(resolved)
		check("unsupported moving resolved discs hidden", not sv.visible and not sky.get("resolved_bodies_supported"))
		check("moving unresolved points retain shared SR starfield", sky.starfield.point_count > 0 and sv.drawn_points.has("saturn"))
		resolved.ship.beta=0.0;resolved.ship.gamma=1.0;sky.apply(resolved)
		check("rest restores resolved discs", sv.visible and sky.get("resolved_bodies_supported"))
		sky.set_debug_unit(true);check("unit glow debug excludes planets", not sv.visible)
		sky.set_debug_unit(false);check("debug exit restores supported planets", sv.visible)
		check("observer rendering does not mutate authoritative world", sim.world == before)
		check("normal tick refreshes epoch and system", sim.send([], 0.000001) and sim.world.system.jd > before.system.jd)
		sky.apply(sim.world)
		check("normal tick replaces synthetic body state", not sv.drawn_discs.has("earth"))
		var legacy := sim.world.duplicate(true); legacy.erase("system"); sky.apply(legacy)
		check("minor2/snapshots clear stale planet points and discs", sky.starfield.point_count == 0 and sv.drawn_discs.is_empty())
	sim.stop(); sky.queue_free(); await process_frame
	print("ship-planets: %d passed, %d failed" % [passes,failures]);quit(1 if failures else 0)
