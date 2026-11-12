class_name CaptainChairContact
extends RefCounted
## The seat and the captain's FOOT reference are different points.
## CA2's pose rig moves the seated pelvis 0.28 m stern of its foot reference:
## art/captain-anim-v4/char_captain_pose_guides_v4.py.txt:53-58.
## Measure the installed cushion instead of treating the chair's furniture origin as feet.
## The cushion's height is exposed for visual review, never added blindly to the feet.
const PELVIS_STERN_M := 0.28
const TOLERANCE_M := 0.01

static func measure(geometry: Node3D) -> Dictionary:
	if geometry == null:
		return {}
	var chair := geometry.find_child("captain_chair", true, false) as MeshInstance3D
	var cushion := geometry.find_child("v2_chair_detail_00", true, false) as MeshInstance3D
	if chair == null or chair.mesh == null or cushion == null or cushion.mesh == null:
		return {}
	var box := cushion.get_aabb()
	var centre := cushion.global_transform * box.get_center()
	var top := -INF
	for k in 8:
		top = maxf(top, (cushion.global_transform * box.get_endpoint(k)).y)
	var forward := -chair.global_basis.z
	forward.y = 0.0
	if not centre.is_finite() or not is_finite(top) or forward.length_squared() < 0.1:
		return {}
	forward = forward.normalized()
	var seat := Vector3(centre.x, top, centre.z)
	var foot := Vector3(centre.x, chair.global_position.y, centre.z) + forward * PELVIS_STERN_M
	return {"seat": seat, "foot": foot, "forward": forward, "chair_origin": chair.global_position,
		"cushion_size": box.size, "pelvis_stern_m": PELVIS_STERN_M}

static func matches(record: Dictionary, foot: Vector3, forward: Vector3) -> bool:
	if record.is_empty() or not foot.is_finite() or not forward.is_finite() or forward.length_squared() < 0.1:
		return false
	return foot.distance_to(record.foot) <= TOLERANCE_M and forward.normalized().distance_to(record.forward) <= TOLERANCE_M
