extends SceneTree
## A destination star renders where the simulation navigates to (RT4 finding,
## 2026-10-06): the ship sky's GCNS (medium) tier places TRAPPIST-1 0.043 ly
## (~2,700 AU) from the navigation catalogue's (stars.json) position, so at a
## 1,000 AU stand-off the rendered star was thousands of AU off and out of view.
## Starfield.pin_destination hides the tier row(s) with that identity and adds
## one row at the stars.json position with its catalogue V and Teff.
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

func _initialize() -> void:
	var sf := Starfield.new()
	check(sf.load_tiers("medium"), "medium tier stack loads")
	var trappist := row_of("Gaia DR3 2635476908753563008")
	var tier_id := "2635476908753563008"
	var before := pos_of(sf, tier_id)
	var want := SkyFrame.to_world64(PackedFloat64Array([trappist.x, trappist.y, trappist.z]))
	var gap := Vector3(before[0] - want[0], before[1] - want[1], before[2] - want[2]).length()
	check(gap > 0.04, "precondition: the GCNS row is %.4f ly from the navigation position" % gap)
	var n := sf.count
	sf.pin_destination(trappist)
	var pin := "pin:" + str(trappist.id)
	check(sf.count == n + 1, "pinning adds exactly one row")
	check(flux_at(sf, tier_id) == 0.0, "the tier row with the same identity is hidden")
	var at := pos_of(sf, pin)
	check(at == want, "the pinned row sits exactly at the navigation catalogue position")
	var want_flux := Relativity.illuminance_from_v(float(trappist.vmag))
	check(absf(flux_at(sf, pin) - want_flux) <= 1e-6 * want_flux, "pinned flux is the catalogue V through illuminance_from_v (float32 storage)")
	sf.set_catalogue_replacements(["CNS5:3627"])
	check(flux_at(sf, tier_id) == 0.0 and flux_at(sf, pin) > 0.0, "a system-view replacement update keeps the pin")
	sf.set_catalogue_replacements([])
	check(flux_at(sf, tier_id) == 0.0, "an empty replacement update keeps the hidden row hidden")
	sf.pin_destination(trappist)
	check(sf.count == n + 1, "pinning twice is idempotent")
	# A destination already at the navigation position (Aldebaran, quick HIP-filled row): no double flux.
	var ald := row_of("CNS5:1142")
	var ald_flux := flux_at(sf, "CNS5:1142")
	check(ald_flux > 0.0, "precondition: Aldebaran is in the sky stack")
	sf.pin_destination(ald)
	check(flux_at(sf, "CNS5:1142") == 0.0 and absf(flux_at(sf, "pin:CNS5:1142") - Relativity.illuminance_from_v(float(ald.vmag))) <= 1e-6 * ald_flux, "Aldebaran is replaced, not doubled")
	# A pinned destination later rendered as a physical emitter (alpha Cen A near the system)
	# must be suppressed with its identity, or its light is counted twice.
	var acen := row_of("CNS5:3627")
	sf.pin_destination(acen)
	check(flux_at(sf, "pin:CNS5:3627") > 0.0, "alpha Cen pinned while far away")
	sf.set_catalogue_replacements(["CNS5:3627", "HIP 71681"])
	check(flux_at(sf, "pin:CNS5:3627") == 0.0 and flux_at(sf, "CNS5:3627") == 0.0, "a system-view replacement also suppresses the pinned row (no double light)")
	sf.set_catalogue_replacements([])
	check(flux_at(sf, "pin:CNS5:3627") > 0.0 and flux_at(sf, "CNS5:3627") == 0.0, "leaving the system restores the pin, not the tier row")
	# Without a pin, a physical emitter named "Gaia DR3 n" still replaces the tier row "n".
	var plain := Starfield.new(); plain.load_tiers("medium")
	var bare_flux := flux_at(plain, tier_id)
	plain.set_catalogue_replacements(["Gaia DR3 2635476908753563008"])
	check(bare_flux > 0.0 and flux_at(plain, tier_id) == 0.0, "a Gaia-id emitter suppresses the bare-number tier row (no double light without a pin)")
	sf.clear()
	check(sf.count == 0 and sf.pinned_ids.is_empty(), "clear() drops pins")
	print("destination-pin: %d failures" % failures)
	quit(1 if failures else 0)
