extends SceneTree
## Harness for the package-generated 96x64 boundary grid, before any pin/bake.
const S := preload("res://physics/schwarzschild.gd")
var data: Dictionary

func row_value(j: int, chi: float) -> float:
	var c := fposmod(chi, TAU) / TAU * 96.0
	var k := int(floor(c)) % 96
	return lerpf(data.angles[j * 96 + k], data.angles[j * 96 + (k + 1) % 96], c - floor(c))

func interpolate(r: float, chi: float, cubic: bool) -> float:
	var y := log(r - 1.0) / log(999999.0) * 63.0
	var j := mini(int(floor(y)), 62)
	var t := y - j
	var p1 := row_value(j, chi)
	var p2 := row_value(j + 1, chi)
	if not cubic:
		return lerpf(p1, p2, t)
	var p0 := row_value(j - 1, chi) if j > 0 else 2.0 * p1 - p2
	var p3 := row_value(j + 2, chi) if j < 62 else 2.0 * p2 - p1
	return S.catmull_rom(p0, p1, p2, p3, t)

func _initialize() -> void:
	data = JSON.parse_string(FileAccess.get_file_as_string("res://.ailang/state/evidence/R2-KERR/boundary-mesh.json"))
	var linear_max := 0.0
	var cubic_max := 0.0
	var worst: Dictionary = {}
	for i in range(0, data.probes.size(), 3):
		var r: float = data.probes[i]
		var chi: float = data.probes[i + 1]
		var exact: float = data.probes[i + 2]
		linear_max = maxf(linear_max, absf(interpolate(r, chi, false) - exact))
		var err := absf(interpolate(r, chi, true) - exact)
		if err > cubic_max:
			cubic_max = err
			worst = {"r": r, "chi": chi, "exact": exact, "interpolated": interpolate(r, chi, true)}
	var result := {"probes": data.probes.size() / 3, "linear_max_rad": linear_max, "cubic_max_rad": cubic_max, "worst": worst}
	var goldens: Array = []
	for r: float in [3.0, 5.0, 10.0]:
		var lm := 0.0
		var cm := 0.0
		for i in range(0, data.golden_probes.size(), 3):
			if data.golden_probes[i] != r:
				continue
			var chi: float = data.golden_probes[i + 1]
			var exact: float = data.golden_probes[i + 2]
			lm = maxf(lm, absf(interpolate(r, chi, false) - exact))
			cm = maxf(cm, absf(interpolate(r, chi, true) - exact))
		goldens.append({"r": r, "linear_max_rad": lm, "cubic_max_rad": cm})
	result["golden_radii"] = goldens
	print(JSON.stringify(result))
	quit(0)
