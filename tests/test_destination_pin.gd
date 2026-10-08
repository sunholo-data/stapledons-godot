extends SceneTree
## A destination star renders where the simulation navigates to.
## RT4 (2026-10-06): the GCNS (medium) tier placed TRAPPIST-1 0.042 ly (~2,700 AU)
## from the navigation catalogue (stars.json), so at a 1,000 AU stand-off it was out
## of view, and Starfield.pin_destination hid the tier row and added one at the
## stars.json position. Since the star-truth table (design_docs/planned/r1/
## starmap-single-truth.md) every tier takes the navigation position, so on the
## shipped stack a pin is a no-op (part A); the fallback still works on a stack that
## disagrees (part B, synthetic rows).
var failures := 0
func check(ok: bool, label: String) -> void:
	print(("ok " if ok else "FAIL ") + label)
	if not ok: failures += 1

func row_of(id: String) -> Dictionary:
	for s: Dictionary in JSON.parse_string(FileAccess.get_file_as_string("res://data/starmap/stars.json")).stars:
		if s.id == id: return s
	return {}

func flux_at(sf: Starfield, id: String) -> float:
	var total := 0.0
	for k in sf.count:
		if sf.ids[k] == id: total += sf.custom[4 * k + 1]
	return total

func pos_of(sf: Starfield, id: String) -> PackedFloat64Array:
	for k in sf.count:
		if sf.ids[k] == id: return PackedFloat64Array([sf.pos[3 * k], sf.pos[3 * k + 1], sf.pos[3 * k + 2]])
	return PackedFloat64Array()

func world(row: Dictionary) -> PackedFloat64Array:
	return SkyFrame.to_world64(PackedFloat64Array([row.x, row.y, row.z]))

func _initialize() -> void:
	# A. The shipped medium stack: one position per star, pins are no-ops.
	var sf := Starfield.new()
	check(sf.load_tiers("medium"), "medium tier stack loads")
	var trappist := row_of("Gaia DR3 2635476908753563008")
	var tier_id := "2635476908753563008"
	check(pos_of(sf, tier_id) == world(trappist), "TRAPPIST-1's GCNS row sits exactly at the navigation position (was 0.042 ly off before the truth table)")
	var n := sf.count
	var flux := flux_at(sf, tier_id)
	sf.pin_destination(trappist)
	check(sf.count == n and sf.pinned_ids.is_empty() and sf.pin_noops == 1 and sf.pin_fallbacks == 0, "pinning TRAPPIST-1 is a no-op")
	check(flux_at(sf, tier_id) == flux and flux > 0.0, "its tier row keeps its light")
	var ald := row_of("CNS5:1142")
	check(flux_at(sf, "CNS5:1142") > 0.0 and pos_of(sf, "CNS5:1142") == world(ald), "Aldebaran (quick, HIP-filled) is in the stack at the navigation position")
	sf.pin_destination(ald)
	check(sf.count == n and sf.pin_noops == 2, "pinning Aldebaran is a no-op")
	var acen := row_of("CNS5:3627")
	sf.pin_destination(acen)
	check(sf.count == n and sf.pin_noops == 3, "pinning alpha Cen is a no-op")
	sf.set_catalogue_replacements(["CNS5:3627", "HIP 71681"])
	check(flux_at(sf, "CNS5:3627") == 0.0, "a system-view replacement suppresses alpha Cen's catalogue row (no double light)")
	sf.set_catalogue_replacements([])
	check(flux_at(sf, "CNS5:3627") > 0.0, "leaving the system restores it")
	sf.set_catalogue_replacements(["Gaia DR3 2635476908753563008"])
	check(flux_at(sf, tier_id) == 0.0, "a Gaia-id emitter suppresses the bare-number tier row")
	sf.set_catalogue_replacements([])
	check(flux_at(sf, tier_id) == flux, "and restores it")

	# B. A stack that disagrees (synthetic: TRAPPIST-1 0.042 ly off): the RT4 pin still works, with a warning.
	var off := world(trappist)
	off[0] += 0.042
	var b := Starfield.new()
	b.set_custom_stars([{"id": tier_id, "pos": off, "t": 2600.0, "flux": 1e-9}, {"id": "CNS5:3627", "pos": [world(acen)[0] + 0.01, world(acen)[1], world(acen)[2]], "t": 5800.0, "flux": 1e-6}])
	var m := b.count
	b.pin_destination(trappist)
	var pin := "pin:" + str(trappist.id)
	check(b.count == m + 1 and b.pin_fallbacks == 1, "fallback: pinning adds exactly one row")
	check(flux_at(b, tier_id) == 0.0, "fallback: the row with the same identity is hidden")
	check(pos_of(b, pin) == world(trappist), "fallback: the pinned row sits exactly at the navigation position")
	var want_flux := Relativity.illuminance_from_v(float(trappist.vmag))
	check(absf(flux_at(b, pin) - want_flux) <= 1e-6 * want_flux, "fallback: pinned flux is the catalogue V through illuminance_from_v")
	b.set_catalogue_replacements(["CNS5:3627"])
	check(flux_at(b, tier_id) == 0.0 and flux_at(b, pin) > 0.0, "fallback: a system-view replacement update keeps the pin")
	b.pin_destination(trappist)
	check(b.count == m + 1, "fallback: pinning twice is idempotent")
	b.set_catalogue_replacements([])
	b.pin_destination(acen)
	check(flux_at(b, "pin:CNS5:3627") > 0.0 and flux_at(b, "CNS5:3627") == 0.0, "fallback: alpha Cen pinned while far away")
	b.set_catalogue_replacements(["CNS5:3627", "HIP 71681"])
	check(flux_at(b, "pin:CNS5:3627") == 0.0, "fallback: a system-view replacement also suppresses the pinned row")
	b.set_catalogue_replacements([])
	check(flux_at(b, "pin:CNS5:3627") > 0.0 and flux_at(b, "CNS5:3627") == 0.0, "fallback: leaving the system restores the pin, not the tier row")
	var dark := b.count
	b.pin_destination({"id": "CNS5:99999", "x": 1.0, "y": 2.0, "z": 3.0, "vmag": 99, "teff": 0})
	check(b.count == dark, "a destination without photometry is never pinned (nothing to draw)")
	b.clear()
	check(b.count == 0 and b.pinned_ids.is_empty() and b.pin_fallbacks == 0, "clear() drops pins")
	# Per-frame cost must not scale with the stack (dev.20 regression: a linear `in ids` scan
	# per emitter took 13.7 ms a frame with the 335,189-row large tier). Unchanged requests
	# against 300,000 rows must cost about what they cost against 3,000.
	var per_call := func(rows: int) -> float:
		var big := Starfield.new()
		var list := []
		for k in rows: list.append({"id": "S%d" % k, "pos": Vector3(1, 0, 0) * (10.0 + k), "t": 5000.0, "flux": 1.0})
		big.set_custom_stars(list)
		var req: Array[String] = ["CNS5:3627", "Gaia DR3 2635476908753563008", "CNS5:1142", "S7"]
		big.set_catalogue_replacements(req)
		var t0 := Time.get_ticks_usec()
		for i in 20: big.set_catalogue_replacements(req)
		var ms := (Time.get_ticks_usec() - t0) / 1000.0 / 20.0
		big.free()
		return ms
	var small_ms: float = per_call.call(3000)
	var big_ms: float = per_call.call(300000)
	print("replacement per frame: %.3f ms at 3,000 rows, %.3f ms at 300,000" % [small_ms, big_ms])
	check(big_ms < 0.5 and big_ms < small_ms * 10.0 + 0.05, "unchanged replacements cost does not scale with the star count")
	print("destination-pin: %d failures" % failures)
	quit(1 if failures else 0)
