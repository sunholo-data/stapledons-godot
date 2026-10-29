class_name LevelCamera
extends RefCounted
## Shared fixed stage pose: runtime and independent layout measurement use one authored rule.
const CLAMP := {"pitch_deg": -3.0, "back_m": 9.5, "rise_m": 2.2, "probe_m": 8.0}

static func pose(v: Dictionary, captain: Vector3, clamp := false) -> Transform3D:
	var yaw := deg_to_rad(float(v.get("yaw_deg", 270.0)))
	var c: Dictionary = v.get("ceiling_clamp", CLAMP)
	var pitch := deg_to_rad(float(c.pitch_deg if clamp else v.get("pitch_deg", -8.0)))
	var back := float(c.back_m if clamp else v.get("back_m", 9.0))
	var rise := float(c.rise_m if clamp else v.get("rise_m", 5.5))
	var ground := Vector3(cos(yaw), 0.0, sin(yaw))
	var eye := captain - ground * back + Vector3(0.0, rise, 0.0)
	var dir := ground * cos(pitch) + Vector3(0.0, sin(pitch), 0.0)
	return Transform3D(Basis.looking_at(dir, Vector3.UP), eye)

