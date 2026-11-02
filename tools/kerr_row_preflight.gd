extends SceneTree
## Test harness: package-generated row, F32 encoding, independent refined rays.
const K := preload("res://physics/kerr.gd")
var data: Dictionary
var values: PackedFloat32Array

func _sample(psi: float, boundary: float, encoded_coefficients := false) -> PackedFloat64Array:
	if psi <= boundary:
		return PackedFloat64Array()
	var t := (psi-boundary)/boundary
	var xmin := log(1e-8)
	var xmax := log((PI-boundary)/boundary)
	var column := clampf((log(t)-xmin)/(xmax-xmin)*(data.columns-1), 0.0, data.columns-1)
	var i := mini(int(floor(column)), int(data.columns)-2)
	var dx: float = (xmax-xmin)/(data.columns-1)
	var p0 := boundary*(1.0+exp(xmin+dx*i))
	var p1 := PI if i+1 == data.columns-1 else boundary*(1.0+exp(xmin+dx*(i+1)))
	var k0 := 1.0/tan(p0/2.0)
	var k1 := 1.0/tan(p1/2.0)
	var w := clampf((1.0/tan(psi/2.0)-k0)/(k1-k0), 0.0, 1.0)
	var ll := log(tanh(t))
	var coefficients := PackedFloat64Array([data.a_par, data.a_twist])
	if encoded_coefficients:
		coefficients = PackedFloat64Array(Array(PackedFloat32Array(Array(coefficients))))
	var bend: float = lerpf(values[2*i], values[2*(i+1)], w)-coefficients[0]*ll
	var twist: float = lerpf(values[2*i+1], values[2*(i+1)+1], w)-coefficients[1]*ll
	return K.lens_direction(data.u, data.spin, psi, data.chi, bend, twist)

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	data = JSON.parse_string(FileAccess.get_file_as_string(args[0]))
	values = PackedFloat32Array(data.values)
	var boundary32: float = PackedFloat32Array([data.boundary])[0]
	var exact_max := 0.0
	var f32_max := 0.0
	var false_captures := 0
	var worst: Dictionary = {}
	for i in range(0, data.probes.size(), 4):
		var psi: float = data.probes[i]
		var want := PackedFloat64Array([data.probes[i+1], data.probes[i+2], data.probes[i+3]])
		for mode: int in [0, 1]:
			var got := _sample(psi, data.boundary if mode == 0 else boundary32, mode == 1)
			if got.is_empty():
				false_captures += 1
				continue
			var diff := PackedFloat64Array([got[0]-want[0], got[1]-want[1], got[2]-want[2]])
			var error := 2.0*asin(minf(1.0, sqrt(K.dot64(diff,diff))/2.0))
			if mode == 0:
				if error > exact_max:
					worst = {"index": i/4, "psi": psi, "want": Array(want), "got": Array(got)}
				exact_max = maxf(exact_max,error)
			else:
				f32_max = maxf(f32_max,error)
	var passed := exact_max <= 1.2e-4 and f32_max <= 1.2e-4 and false_captures == 0
	print(JSON.stringify({"passed":passed,"budget_rad":1.2e-4,"columns":data.columns,"probes":data.probes.size()/4,"boundary":data.boundary,"boundary_f32":boundary32,
		"exact_boundary_max_rad":exact_max,"f32_boundary_max_rad":f32_max,"false_captures":false_captures,"worst_exact":worst}))
	quit(0 if passed else 1)
