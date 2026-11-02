extends SceneTree
const K := preload("res://physics/kerr.gd")

static func _value(row: Dictionary) -> float:
	var s := float(row.spin)
	var rs := 10.0 * 2953.2500761002495 # package rsPerSolarMassMetres, IAU2015
	match row.quantity:
		"outer": return 2.0 * K.horizon_r(s)
		"inner": return 2.0 * K.horizon_inner_r(s)
		"static-limit": return 2.0 * K.static_limit_r(s, 0.0)
		"photon-pro": return 2.0 * K.photon_r(s, 1.0)
		"photon-retro": return 2.0 * K.photon_r(s, -1.0)
		"isco-pro": return 2.0 * K.isco_r(s, 1.0)
		"isco-retro": return 2.0 * K.isco_r(s, -1.0)
		"clock-pro": return K.orbit_clock_rate(2.0 * K.isco_r(s, 1.0), s, 1.0)
		"clock-retro": return K.orbit_clock_rate(2.0 * K.isco_r(s, -1.0), s, -1.0)
		"horizon-omega": return K.horizon_omega(s)
		"frame-drag-static-limit": return K.frame_drag_omega(2.0, 0.0, s)
		"lapse-static-limit": return K.zamo_clock_rate(2.0, 0.0, s)
		"zamo-speed-isco-pro": return K.orbit_local_speed(2.0 * K.isco_r(s, 1.0), s, 1.0)
		"static-clock-static-limit": return 0.0 if is_nan(K.static_clock_rate(2.0, 0.0, s)) else NAN # limit, no timelike static observer
		"rs-km", "static-limit-km": return rs / 1000.0
		"horizon-km": return rs * K.horizon_r(s) / 1000.0
		"isco-pro-km": return rs * K.isco_r(s, 1.0) / 1000.0
		"period-ms": return TAU * rs / (2.0 * 299792458.0 * K.orbit_omega(2.0 * K.isco_r(s, 1.0), s, 1.0)) * 1000.0
		"omega-h-rad-s": return K.horizon_omega(s) * (2.0 * 299792458.0 / rs)
		"shadow": return 3.0 * sqrt(3.0) # package shadowCircle zero-spin member
		"frame-drag": return K.frame_drag_omega(6.0, 0.0, s)
	return NAN

static func spec_checks() -> Dictionary:
	var result := {"passes": 0, "failures": 0}
	var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/kerr/rk.json"))
	for row: Dictionary in fixture.records:
		var got := _value(row)
		var want := float(row.precise)
		if is_finite(got) and absf(got - want) <= maxf(absf(want) * 1e-12, 1e-15):
			result.passes += 1
		else:
			result.failures += 1
			print("FAIL %s/%s s%s got %s want %s" % [row.id, row.quantity, row.spin, got, want])
	for spin: float in [NAN, INF, -0.1, 1.0, 1.1]:
		if is_nan(K.horizon_r(spin)) and is_nan(K.isco_r(spin, 1.0)):
			result.passes += 1
		else:
			result.failures += 1
	# Independent V33 literals also pinned by the package's kerr_frame_test.
	var n := PackedFloat64Array([0.8, 0.0, 0.6])
	var frame := K.metric_frame(4.0, 0.9)
	var c := K.source_constants(4.0, 0.9, n)
	var v := K.radial_velocity(4.0, 0.9, -0.5)
	var g := K.gamma_velocity(v)
	var source := PackedFloat64Array([0.6, 0.0, 0.8])
	var nz := K.boost_source(source, PackedFloat64Array([-v[0], 0.0, -v[2]]), g)
	var back := K.boost_source(nz, v, g)
	for pair: Array in [[frame.lapse, 0.71537612301921329], [frame.omega, 0.026139994191112402], [frame.h, 4.1490962871449489],
		[c.lambda, -3.8281581133503123], [c.eta, 0.0],
		[K.frequency_ratio(4.0, 0.9, n, K.static_velocity(4.0, 0.9)), 1.4142135623730950],
		[K.frequency_ratio(4.0, 0.9, n, K.circular_velocity(4.0, 0.9, 1.0)), 2.3084941047201764],
		[K.frequency_ratio(4.0, 0.9, n, K.circular_velocity(4.0, 0.9, -1.0)), 2.5866181264388675],
		[g, 1.1682043170450399], [nz[0], 0.78930098917940921], [nz[2], 0.61400647266979697], [back[0], source[0]], [back[2], source[2]]]:
		if is_finite(pair[0]) and absf(pair[0]-pair[1]) < 1e-12:
			result.passes += 1
		else:
			print("FAIL V33 got %s want %s" % pair)
			result.failures += 1
	return result

func _initialize() -> void:
	var r := spec_checks()
	print("kerr-physics: %d passed, %d failures" % [r.passes, r.failures])
	quit(1 if r.failures else 0)
