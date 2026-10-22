class_name ShipDressing
extends Node3D
## R2-BRIDGE-STYLE S5 (design_docs/implemented/r2/bridge-styling-pass.md §S5, D-106): the bridge dressed for its
## fixed views, all from data, all in the shared toon material:
##   fronds      the ten rim fronds as painted cards (manifest style.foliage, from the v4 generator): each a
##               card turned toward the camera within +-25 deg of its inward facing, a crossed card as its
##               shadow proxy (a single card's shadow thins to a line when the light is edge-on), the
##               occluder fade kept (they are named rim_frond_k)
##   below_rail  silhouettes of the levels below seen past the bridge's edge (views.json
##               levels.bridge.dressing.below_rail): grown canopy domes standing on the Commons deck,
##               inside the bubble, never painted space; shown while the captain is on the bridge
## (A camera-attached foreground layer was tried and removed on Mark's review of #322: a plant fixed to the
## camera reads as standing on whatever is behind it, the lift's railing in the Bow view. The levels' view
## dressing places real props instead.)
const CARD_MARGIN := 1.12 # the paintings carry a margin round the plant
var fronds: Array[MeshInstance3D] = []
var below_rail: Array[MeshInstance3D] = []


## Build everything; `manifest` the ship manifest, `level` views.json levels.bridge, `props` the parent the
## fronds join (bridge_props.glb's root, so the occluder fade and the style group find them).
func build(manifest: Dictionary, level: Dictionary, props: Node3D) -> void:
	name = "BridgeDressing"
	for f: Dictionary in manifest.get("style", {}).get("foliage", []):
		# D-106 variety: each plant's painted kind, height, mirror and palette tint come from the manifest.
		var tex := StapledonStyle.card_texture(str(f.get("kind", "frond")))
		var root := Vector3(f.root_m[0], f.root_m[1], f.root_m[2])
		var facing := Vector3(f.facing[0], 0.0, f.facing[2]).normalized()
		var h := float(f.get("height_m", 3.2)) * CARD_MARGIN
		var basis := Basis.looking_at(-facing, Vector3.UP) # the card's +z along its facing
		var card := _card(str(f.name), tex, h)
		var t: Array = f.get("tint", [1.0, 1.0, 1.0])
		(card.material_override as ShaderMaterial).set_shader_parameter("albedo", Color(t[0], t[1], t[2]))
		(card.material_override as ShaderMaterial).set_shader_parameter("card_flip", bool(f.get("flip", false)))
		card.set_meta("kind", str(f.get("kind", "frond")))
		card.set_meta("height_m", float(f.get("height_m", 3.2)))
		props.add_child(card)
		card.global_transform = Transform3D(basis, root)
		var m := card.material_override as ShaderMaterial
		card.set_instance_shader_parameter("cloud_center", root + Vector3.UP * h * 0.55)
		card.set_instance_shader_parameter("cloud_radii", Vector3.ONE * h * 0.5)
		card.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var proxy := _card("frond_shadow_%d" % fronds.size(), tex, h) # not "rim_frond": a shadow never fades the view
		(proxy.material_override as ShaderMaterial).set_shader_parameter("card_flip", bool(f.get("flip", false)))
		props.add_child(proxy)
		proxy.global_transform = Transform3D(basis.rotated(Vector3.UP, PI * 0.5), root)
		proxy.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
		(proxy.material_override as ShaderMaterial).set_shader_parameter("clamp_deg", 0.0) # crossed, it never turns
		fronds.append(card)
		m.resource_name = "frond card"
	var d: Dictionary = level.get("dressing", {})
	for c: Dictionary in d.get("below_rail", []):
		var mi := MeshInstance3D.new()
		mi.name = "below_rail_" + str(c.get("kind", "canopy")) + "_%d" % below_rail.size()
		var sm := SphereMesh.new()
		sm.radial_segments = 24
		sm.rings = 12
		sm.is_hemisphere = true
		mi.mesh = sm
		var r := float(c.radius_m)
		mi.scale = Vector3(r, float(c.height_m), r)
		mi.position = Vector3(c.pos_m[0], c.pos_m[1], c.pos_m[2])
		var src := StandardMaterial3D.new()
		src.albedo_color = Color(str(c.get("colour", "#3F5E5A")))
		mi.set_surface_override_material(0, StapledonStyle.toon_material(src))
		mi.add_to_group(StapledonStyle.GROUP)
		add_child(mi)
		below_rail.append(mi)


func _card(n: String, tex: Texture2D, h: float) -> MeshInstance3D:
	var q := QuadMesh.new()
	q.size = Vector2(h, h)
	q.center_offset = Vector3(0, h * 0.5 - h * 0.03, 0)
	var mi := MeshInstance3D.new()
	mi.name = n
	mi.mesh = q
	StapledonStyle.add_card(mi, StapledonStyle.card_material(tex))
	return mi


## Each frame: the below-rail silhouettes show only on the bridge.
func update(_cam: Camera3D, _view_id: String, level: int) -> void:
	for mi in below_rail:
		mi.visible = level == 0


## Every dressing mesh (the evaluator measures them).
func meshes() -> Array:
	var out: Array = []
	out.append_array(fronds)
	out.append_array(below_rail)
	return out
