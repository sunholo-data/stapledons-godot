class_name StapledonStyle
extends RefCounted
## R2-BRIDGE-STYLE S2 (design_docs/planned/r2/bridge-styling-pass.md, D-100): the bridge's shading.
## Every mesh of the bridge level takes one shared toon material (shaders/stapledon_toon.gdshader)
## with exactly the ink outline (interior/outline.gdshader) as its next_pass. Membership is the node
## group GROUP, never a position test: every bridge_props.glb mesh and the ship.glb nodes the manifest
## lists in style.bridge_nodes. Exclusions keep their own materials: emissive or transparent surfaces,
## the game's screen quads (IdleScreen_*) and sprites or billboards. The sky renders in its own
## viewport and is never touched.
const GROUP := "bridge_style"
const TOON_PATH := "res://shaders/stapledon_toon.gdshader"
const INK_PATH := "res://interior/outline.gdshader"
const INK_WIDTH_M := 0.018 # the DL2 props' outline width (ship_geometry_demo PROP_OUTLINE_M)

static var _toon: Shader
static var _ink: ShaderMaterial


static func toon_shader() -> Shader:
	if _toon == null: _toon = load(TOON_PATH)
	return _toon


static func ink_material() -> ShaderMaterial:
	if _ink == null:
		_ink = ShaderMaterial.new()
		_ink.shader = load(INK_PATH)
		_ink.set_shader_parameter("width", INK_WIDTH_M)
	return _ink


## The toon material for a source material: its albedo colour and texture, its normal map and UV
## transform; the ink as next_pass.
static func toon_material(src: Material) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = toon_shader()
	if src is BaseMaterial3D:
		var b := src as BaseMaterial3D
		m.set_shader_parameter("albedo", b.albedo_color)
		m.set_shader_parameter("albedo_tex", b.albedo_texture)
		m.set_shader_parameter("has_tex", b.albedo_texture != null)
		if b.normal_enabled and b.normal_texture != null:
			m.set_shader_parameter("normal_tex", b.normal_texture)
			m.set_shader_parameter("has_normal", true)
			m.set_shader_parameter("normal_scale", b.normal_scale)
		m.set_shader_parameter("uv_scale", b.uv1_scale)
		m.set_shader_parameter("uv_offset", b.uv1_offset)
	m.next_pass = ink_material()
	return m


static func is_toon(m: Material) -> bool:
	return m is ShaderMaterial and (m as ShaderMaterial).shader != null and (m as ShaderMaterial).shader.resource_path == TOON_PATH


static func is_ink(m: Material) -> bool:
	return m is ShaderMaterial and (m as ShaderMaterial).shader != null and (m as ShaderMaterial).shader.resource_path == INK_PATH


## A surface that keeps its own material: emissive or transparent, a screen quad, or any sprite or
## billboard.
static func excluded(mi: GeometryInstance3D, m: Material) -> bool:
	if mi is SpriteBase3D or String(mi.name).begins_with("IdleScreen_"): return true
	if m is BaseMaterial3D:
		var b := m as BaseMaterial3D
		return b.emission_enabled or b.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or b.billboard_mode != BaseMaterial3D.BILLBOARD_DISABLED
	return false


## Put the meshes under `roots` (whole subtrees) into the group with the toon material.
static func apply(roots: Array) -> int:
	var n := 0
	for r: Node in roots:
		for mi: MeshInstance3D in meshes(r):
			mi.add_to_group(GROUP)
			for i in mi.mesh.get_surface_count():
				var src: Material = mi.get_surface_override_material(i)
				if src == null: src = mi.mesh.surface_get_material(i)
				if excluded(mi, src): continue
				mi.set_surface_override_material(i, toon_material(src))
				n += 1
	return n


static func meshes(r: Node) -> Array:
	var out := []
	var stack: Array = [r]
	while not stack.is_empty():
		var x: Node = stack.pop_back()
		stack.append_array(x.get_children())
		if x is MeshInstance3D and (x as MeshInstance3D).mesh != null and not String(x.name).begins_with("IdleScreen_"):
			out.append(x)
	return out


static func _surface(mi: MeshInstance3D, i: int) -> Material:
	var m: Material = mi.get_surface_override_material(i)
	return m if m != null else mi.mesh.surface_get_material(i)


## AC3: every styled surface not excluded is the toon material with exactly the ink as next_pass.
static func audit(tree: SceneTree) -> Array:
	var problems := []
	for n: Node in tree.get_nodes_in_group(GROUP):
		var mi := n as MeshInstance3D
		if mi == null or mi.mesh == null:
			problems.append("%s: not a mesh" % n.name)
			continue
		for i in mi.mesh.get_surface_count():
			var m := _surface(mi, i)
			if excluded(mi, m): continue
			if not is_toon(m): problems.append("%s[%d]: %s, not the toon material" % [mi.name, i, m.get_class() if m else "null"])
			elif not is_ink((m as ShaderMaterial).next_pass) or (m as ShaderMaterial).next_pass.next_pass != null: problems.append("%s[%d]: next_pass is not exactly the ink" % [mi.name, i])
	return problems


static func excluded_surfaces(tree: SceneTree) -> Array:
	var out := []
	for n: Node in tree.get_nodes_in_group(GROUP):
		var mi := n as MeshInstance3D
		if mi == null or mi.mesh == null: continue
		for i in mi.mesh.get_surface_count():
			var m := _surface(mi, i)
			if excluded(mi, m): out.append({"node": mi, "surface": i, "material": m})
	return out


## Every use of the toon shader under `r` (material overrides, surface overrides, mesh surfaces).
static func toon_in(r: Node) -> Array:
	var out := []
	var stack: Array = [r]
	while not stack.is_empty():
		var x: Node = stack.pop_back()
		stack.append_array(x.get_children())
		if not x is GeometryInstance3D: continue
		var g := x as GeometryInstance3D
		if is_toon(g.material_override): out.append(g)
		if g is MeshInstance3D and (g as MeshInstance3D).mesh != null:
			var mi := g as MeshInstance3D
			for i in mi.mesh.get_surface_count():
				if is_toon(mi.get_surface_override_material(i)) or is_toon(mi.mesh.surface_get_material(i)): out.append(mi)
	return out
