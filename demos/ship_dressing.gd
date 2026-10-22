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
##   foreground  per-view near-field cards (views.json levels.bridge.dressing.foreground.<view>): placed in
##               the camera's frame, drifting against a slide by PARALLAX (bounded), shown only in their view
const PARALLAX := 0.6 # the art bible's foreground layer moves 1.6x: 0.6 against the camera
const DRIFT_MAX_M := 0.8
const CARD_MARGIN := 1.12 # the paintings carry a margin round the plant
var fronds: Array[MeshInstance3D] = []
var below_rail: Array[MeshInstance3D] = []
var foreground := {} # view id -> Array of [MeshInstance3D, offset Vector3]
var _anchor := Vector3.INF
var _view := ""


## Build everything; `manifest` the ship manifest, `level` views.json levels.bridge, `props` the parent the
## fronds join (bridge_props.glb's root, so the occluder fade and the style group find them).
func build(manifest: Dictionary, level: Dictionary, props: Node3D) -> void:
	name = "BridgeDressing"
	var tex := StapledonStyle.card_texture("frond")
	for f: Dictionary in manifest.get("style", {}).get("foliage", []):
		var root := Vector3(f.root_m[0], f.root_m[1], f.root_m[2])
		var facing := Vector3(f.facing[0], 0.0, f.facing[2]).normalized()
		var h := float(f.get("height_m", 3.2)) * CARD_MARGIN
		var basis := Basis.looking_at(-facing, Vector3.UP) # the card's +z along its facing
		var card := _card(str(f.name), tex, h)
		props.add_child(card)
		card.global_transform = Transform3D(basis, root)
		var m := card.material_override as ShaderMaterial
		card.set_instance_shader_parameter("cloud_center", root + Vector3.UP * h * 0.55)
		card.set_instance_shader_parameter("cloud_radii", Vector3.ONE * h * 0.5)
		card.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var proxy := _card("frond_shadow_%d" % fronds.size(), tex, h) # not "rim_frond": a shadow never fades the view
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
	for vid: String in d.get("foreground", {}):
		var list := []
		for c: Dictionary in d.foreground[vid]:
			var h := float(c.height_m)
			var card := _card("foreground_%s_%d" % [vid, list.size()], StapledonStyle.card_texture(str(c.get("kind", "frond"))), h)
			(card.material_override as ShaderMaterial).set_shader_parameter("clamp_deg", 0.0)
			card.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			(card.material_override as ShaderMaterial).set_shader_parameter("card_flip", bool(c.get("flip", false)))
			card.visible = false
			add_child(card)
			list.append([card, Vector3(c.offset[0], c.offset[1], c.offset[2]), bool(c.get("flip", false))])
		foreground[vid] = list


func _card(n: String, tex: Texture2D, h: float) -> MeshInstance3D:
	var q := QuadMesh.new()
	q.size = Vector2(h, h)
	q.center_offset = Vector3(0, h * 0.5 - h * 0.03, 0)
	var mi := MeshInstance3D.new()
	mi.name = n
	mi.mesh = q
	StapledonStyle.add_card(mi, StapledonStyle.card_material(tex))
	return mi


## Each frame: the foreground follows the current view's camera with a bounded parallax drift; the
## below-rail silhouettes show only on the bridge.
func update(cam: Camera3D, view_id: String, level: int) -> void:
	for mi in below_rail:
		mi.visible = level == 0
	if view_id != _view:
		_view = view_id
		_anchor = cam.global_position
	var drift := -(cam.global_position - _anchor) * PARALLAX
	drift.y = 0.0
	if drift.length() > DRIFT_MAX_M: drift = drift.normalized() * DRIFT_MAX_M
	for vid: String in foreground:
		for pair: Array in foreground[vid]:
			var card: MeshInstance3D = pair[0]
			card.visible = level == 0 and vid == view_id
			if card.visible:
				# Upright, facing the camera (its yaw only); a flipped card mirrors its painting (card_flip).
				var b := Basis.from_euler(Vector3(0.0, cam.global_rotation.y, 0.0))
				card.global_transform = Transform3D(b, cam.global_position + cam.global_basis * pair[1] + drift)


## Every dressing mesh (the evaluator measures them).
func meshes() -> Array:
	var out: Array = []
	out.append_array(below_rail)
	for vid: String in foreground:
		for pair: Array in foreground[vid]:
			out.append(pair[0])
	return out
