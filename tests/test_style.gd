extends SceneTree
## R2-BRIDGE-STYLE AC3 (design_docs/planned/r2/bridge-styling-pass.md §S2): every bridge_style mesh
## uses the toon material with exactly the ink outline as next_pass (the stated exclusions keep their
## own); every manifest style.bridge_nodes entry exists; the lower decks are not styled; the named sky
## layers exist, render in their own viewport and none uses the toon shader. Negative controls: a
## seeded PBR material on a bridge mesh and a seeded toon material on a sky layer are both caught.
const STYLE := "res://interior/stapledon_style.gd"
const PX := Vector2i(640, 360)
var passed := 0
var failures := 0


func check(name: String, ok: bool) -> void:
	if ok: passed += 1
	else: failures += 1
	print("  %s %s" % ["ok  " if ok else "FAIL", name])


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var have := FileAccess.file_exists(STYLE)
	check("the style module exists (%s)" % STYLE, have)
	var demo: Node = load("res://demos/ship_geometry_demo.tscn").instantiate()
	demo.setup_options = {"size": PX, "sky_state": "rest", "planet_textures": false, "planet_preload": false}
	root.add_child(demo)
	await process_frame
	check("the ship demo builds", demo.ready_ok)
	if not have or not demo.ready_ok:
		_done()
		return
	var Style: GDScript = load(STYLE)
	var listed: Array = demo.manifest.get("style", {}).get("bridge_nodes", [])
	check("the manifest lists the ship.glb bridge nodes (style.bridge_nodes, %d)" % listed.size(), listed.size() >= 5)
	var missing: Array = listed.filter(func(n: String) -> bool: return demo.geometry.find_child(n, true, false) == null)
	check("every style.bridge_nodes entry exists in the loaded ship (missing %s)" % [missing], missing.is_empty() and not listed.is_empty())
	var members: Array = demo.get_tree().get_nodes_in_group(Style.GROUP)
	check("the bridge_style group holds the bridge meshes (%d)" % members.size(), members.size() >= 20)
	var props: int = members.filter(func(n: Node) -> bool: return demo.props_visual != null and demo.props_visual.is_ancestor_of(n)).size()
	check("every bridge_props.glb mesh is in the group (%d)" % props, demo.props_visual != null and props == Style.meshes(demo.props_visual).size())
	var lower := ["Deck 01 top 57m", "Deck 02 top 32m", "Spire below bridge"]
	check("the lower decks are not styled (%s)" % [lower], lower.all(func(n: String) -> bool:
		var x: Node = demo.geometry.find_child(n, true, false)
		return x != null and not x.is_in_group(Style.GROUP)))
	var problems: Array = Style.audit(demo.get_tree())
	check("every styled surface is the toon material with exactly the ink next_pass (%d problems%s)" % [problems.size(), (": " + str(problems.slice(0, 3))) if not problems.is_empty() else ""], problems.is_empty())
	var excluded: Array = Style.excluded_surfaces(demo.get_tree())
	check("the exclusions keep their own materials (%d excluded surfaces, none toon)" % excluded.size(), excluded.all(func(s: Dictionary) -> bool: return not Style.is_toon(s.material)))
	# The exclusions, seeded (the shipped GLBs carry none): an emissive and a transparent surface and a
	# screen quad put through apply() keep their own materials, and the audit accepts them.
	var seeds := []
	for k in 3:
		var q := MeshInstance3D.new()
		q.mesh = QuadMesh.new()
		var sm := StandardMaterial3D.new()
		if k == 0: sm.emission_enabled = true
		if k == 1: sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		q.name = "IdleScreen_seed" if k == 2 else "seed_%d" % k
		q.set_surface_override_material(0, sm)
		demo.geometry.add_child(q)
		seeds.append(q)
	Style.apply(seeds)
	var kept: bool = seeds.all(func(q: MeshInstance3D) -> bool: return q.get_surface_override_material(0) is StandardMaterial3D)
	check("seeded exclusions (emissive, transparent, IdleScreen_*) keep their own materials and pass the audit", kept and Style.audit(demo.get_tree()).is_empty())
	for q: MeshInstance3D in seeds: q.queue_free()
	var lamp: MeshInstance3D = demo.lighting.spire_lamp
	check("the emissive spire lamp keeps its own material", lamp != null and not Style.is_toon(lamp.material_override))
	# The sky: its named layers exist, live in their own viewport, and none uses the toon shader.
	var sky: InteriorSky = demo.sky
	var layers := {"InteriorSky": sky, "SystemView": sky.system_view, "Starfield": sky.starfield, "SkyBackground": sky.background, "ForwardGlow": sky.glow, "DustFlash": sky.dust_mesh}
	check("the named sky layers exist (%s)" % [layers.keys()], layers.values().all(func(n: Variant) -> bool: return n != null and is_instance_valid(n)))
	check("the sky renders in its own viewport, apart from the ship's geometry_view", sky.get_viewport() != demo.geometry_view and not demo.geometry_view.is_ancestor_of(sky))
	var sky_toon: Array = Style.toon_in(sky)
	check("no sky layer uses the toon shader (%d)" % sky_toon.size(), sky_toon.is_empty())
	# D-104 (S7, AC12): the shape language. Every prop the manifest lists in style.shaped has a
	# straight-edge share <= 0.10; a box (the blockout's primitive) scores far above and fails.
	var shaped: Array = demo.manifest.get("style", {}).get("shaped", [])
	var worst := 0.0
	var worst_name := ""
	var missing_shaped := []
	for n: String in shaped:
		var mi := demo.props_visual.find_child(n, true, false) as MeshInstance3D if demo.props_visual != null else null
		if mi == null:
			missing_shaped.append(n)
			continue
		var share: float = Style.straight_share(mi.mesh)
		if share > worst:
			worst = share
			worst_name = n
	check("D-104: the manifest lists the grown props (style.shaped, %d; missing %s)" % [shaped.size(), missing_shaped], shaped.size() >= 27 and missing_shaped.is_empty())
	check("D-104: every grown prop's straight-edge share <= 0.10 (worst %.3f, %s)" % [worst, worst_name], worst <= 0.10 and not shaped.is_empty())
	# ST3: the authored lift head is grown and on the toon too; the painted deck's quadrants are styled.
	var lift_parts: Array = Style.meshes(demo.lift).filter(func(m: MeshInstance3D) -> bool: return String(m.name).begins_with("lift_"))
	var lift_names: Array = demo.manifest.get("style", {}).get("lift_shaped", [])
	var lift_worst := 0.0
	for m: MeshInstance3D in lift_parts:
		lift_worst = maxf(lift_worst, Style.straight_share(m.mesh))
	check("ST3: the lift head's pieces (%d: %s) are toon-styled and grown (worst share %.3f)" % [lift_parts.size(), lift_names, lift_worst], lift_parts.size() >= 6 and lift_parts.all(func(m: MeshInstance3D) -> bool: return m.is_in_group(Style.GROUP)) and lift_worst <= 0.10 and lift_names.size() == 3)
	var deck: Node = demo.geometry.find_child("bridge_floor_top82", true, false)
	var quads: Array = Style.meshes(deck) if deck != null else []
	check("ST3: the deck top is four painted quadrants in the group (%d)" % quads.size(), quads.size() == 4 and quads.all(func(m: MeshInstance3D) -> bool: return m.is_in_group(Style.GROUP) and String(m.name).begins_with("bridge_floor_top82_q")))
	var box_share: float = Style.straight_share(BoxMesh.new())
	check("D-104 negative control: a box scores %.3f > 0.4 and would fail" % box_share, box_share > 0.4)
	# Negative control 1: a PBR material seeded on a styled bridge mesh is caught.
	var victim: MeshInstance3D = members[0]
	var saved: Material = victim.get_surface_override_material(0)
	victim.set_surface_override_material(0, StandardMaterial3D.new())
	var caught: Array = Style.audit(demo.get_tree())
	victim.set_surface_override_material(0, saved)
	check("negative control: a seeded PBR bridge surface fails the audit (%d)" % caught.size(), caught.size() == 1)
	# Negative control 2: the toon material seeded on a sky layer is caught.
	var glow: MeshInstance3D = sky.glow
	var glow_saved: Material = glow.material_override
	glow.material_override = Style.toon_material(null)
	var caught_sky: Array = Style.toon_in(sky)
	glow.material_override = glow_saved
	check("negative control: a seeded toon sky layer is caught (%d)" % caught_sky.size(), caught_sky.size() == 1)
	_done()


func _meshes(n: Node) -> Array:
	var out := []
	var stack: Array = [n]
	while not stack.is_empty():
		var x: Node = stack.pop_back()
		stack.append_array(x.get_children())
		if x is MeshInstance3D and (x as MeshInstance3D).mesh != null:
			out.append(x)
	return out


func _done() -> void:
	print("style-test: %d passed, %d failures" % [passed, failures])
	quit(1 if failures else 0)
