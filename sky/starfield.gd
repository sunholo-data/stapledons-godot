class_name Starfield
extends MultiMeshInstance3D
## Catalogue stars rendered with exact aberration, Doppler colour and
## band-limited relativistic beaming (see starfield.gdshader).

const SHADER := preload("res://sky/starfield.gdshader")

## Galactic XYZ (x toward centre, z to north pole) -> Godot world (Y up).
## Galactic centre lies along -Z, which is Godot's default forward.
static func galactic_to_world(g: Vector3) -> Vector3:
	return Vector3(g.y, g.z, -g.x)

var stars: Array = [] # [{name, pos: Vector3 world ly, t: float, flux: float (as seen from Sol)}]
var ship_position := Vector3.ZERO
var material: ShaderMaterial


func load_catalogue(path: String) -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	stars.clear()
	for s in data["stars"]:
		stars.append({
			"name": s["name"],
			"pos": galactic_to_world(Vector3(s["x"], s["y"], s["z"])),
			"t": Relativity.temperature_for_class(s["spectral"]),
			"flux": Relativity.flux_from_mag(s["vmag"]),
		})


func set_custom_stars(list: Array) -> void:
	stars = list


func build() -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(2, 2)
	material = ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter("bb_lut", Blackbody.build_lut())
	material.set_shader_parameter("lut_log_tmin", log(Blackbody.LUT_T_MIN))
	material.set_shader_parameter("lut_log_tmax", log(Blackbody.LUT_T_MAX))
	quad.material = material
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = quad
	multimesh = mm
	extra_cull_margin = 16384.0
	_update_instances()


## Directions depend on the ship's position; recompute when it moves.
func _update_instances() -> void:
	var mm := multimesh
	mm.instance_count = stars.size()
	for i in stars.size():
		var s: Dictionary = stars[i]
		var rel: Vector3 = s["pos"] - ship_position
		var r := rel.length()
		# Catalogue magnitudes are as seen from Sol; rescale by inverse square.
		var r_sol: float = (s["pos"] as Vector3).length()
		var flux: float = s["flux"] * (r_sol * r_sol) / maxf(r * r, 1e-6)
		mm.set_instance_transform(i, Transform3D(Basis(), rel / r))
		mm.set_instance_custom_data(i, Color(s["t"], flux, 0.0, 0.0))


func set_ship_position(p: Vector3) -> void:
	ship_position = p
	_update_instances()


## direction: unit heading in the galaxy frame. beta and gamma come from the
## sim in float64; 1 - beta is formed here so it survives float32 upload.
func set_velocity(direction: Vector3, beta: float, gamma: float) -> void:
	material.set_shader_parameter("beta_dir", direction.normalized())
	material.set_shader_parameter("beta_mag", beta)
	material.set_shader_parameter("gamma_f", gamma)
	material.set_shader_parameter("one_minus_beta", 1.0 / (gamma * gamma * (1.0 + beta)))


func set_exposure(e: float) -> void:
	material.set_shader_parameter("exposure", e)
