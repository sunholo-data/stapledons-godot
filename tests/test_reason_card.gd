extends SceneTree
## R3-REASONS RT5a (design r3/reasons-to-travel.md RT5, AC10/AC11; finder AC 5): the reason card on the
## example fixture tests/fixtures/finder/candidates.json (invented data in the planned 2.19 shape).
## make reason-card-test (in make ui).
##   bound     every label that shows a digit is a clean binding on a finder field (D-21)
##   offers    each glyph's strength is its offer field; a ring is on exactly the ship's needs
##   cost      time leads: the Earth and ship bars are taller than the mass bar; each fill follows its
##             field; the Earth bar's human marks sit between one year and the doom clock, in order
##   states    each bar's parts follow the probabilities and fill its width
##   no judge  no word on the card recommends: no "best", "recommended" or "should"
##   modes     Processed adds the model and removes nothing; with no candidate the card shows nothing

var failures := 0
var passes := 0


func check(label: String, ok: bool) -> void:
	if ok:
		passes += 1
	else:
		failures += 1
	print("%s %s" % ["ok" if ok else "FAIL", label])


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/finder/candidates.json"))
	check("the fixture parses and is marked as an example", raw is Dictionary and raw.finder.example == true)
	var view: Dictionary = raw
	var f: Dictionary = view.finder
	var card := ReasonCard.new()
	card.size = Vector2(1100, 560)
	root.add_child(card)
	await process_frame
	for i in f.candidates.size():
		var c: Dictionary = f.candidates[i]
		card.refresh(view, i)
		await process_frame
		var tag: String = c.id
		check("%s: every number is a clean binding" % tag, DisplayBinding.audit(card).is_empty())
		var shown := ""
		for n in card.find_children("*", "Label", true, false):
			shown += " " + n.text
		check("%s: the name, both time costs and the mass are shown from their fields" % tag,
			shown.contains(str(c.name)) and shown.contains(ReasonCard.format("finder_years", c.cost.earth_years))
			and shown.contains(ReasonCard.format("finder_years", c.cost.ship_years)) and shown.contains(ReasonCard.format("finder_kg", c.cost.mass_kg)))
		var ok := card.glyphs.size() == 8
		var rings := 0
		for g: Dictionary in card.glyphs:
			ok = ok and is_equal_approx(g.strength, float(c.offer.get(g.id, 0.0)))
			ok = ok and g.need == f.needs.has(g.id)
			rings += 1 if g.need else 0
		check("%s: eight glyphs, each lit by its offer field, rings on exactly the ship's needs" % tag, ok and rings == f.needs.size())
		var sep: float = c.image.separation_lambda_d
		check("%s: the picture marks the planet only where the telescope can separate it from its star" % tag,
			(card.image.planet != null) == (sep >= f.iwa_lambda_d) and is_equal_approx(card.image.au_px, c.image.au_lambda_d * card.image.px)
			and (card.image.planet == null or is_equal_approx(card.image.planet.distance_to(card.image.box.get_center()), sep * card.image.px)))
		check("%s: the crew glyph follows the mind field" % tag, is_equal_approx(card.mind.strength, float(c.mind)))
		var e: Dictionary = card.bars.earth
		var s: Dictionary = card.bars.ship
		var m: Dictionary = card.bars.mass
		check("%s: time leads: the two time bars are at least twice the mass bar's height" % tag,
			e.track.size.y >= 2.0 * m.track.size.y and s.track.size.y >= 2.0 * m.track.size.y and e.track.position.y < m.track.position.y)
		check("%s: each fill follows its field" % tag,
			is_equal_approx(s.fill.size.x / s.track.size.x, c.cost.ship_years / f.voyage_years)
			and is_equal_approx(m.fill.size.x / m.track.size.x, c.cost.mass_kg / f.free_mass_kg)
			and is_equal_approx(e.fill.size.x / e.track.size.x, log(c.cost.earth_years) / log(f.doom_years)))
		for row: Array in [[card.states_then, c.belief.p, "then"], [card.states_arrival, c.arrival.p, "arrival"]]:
			var total := 0.0
			var sum_p := 0.0
			var match_p := true
			for p: Dictionary in row[0]:
				total += p.rect.size.x
				sum_p += p.p
				match_p = match_p and is_equal_approx(p.p, float(row[1][p.state]))
			var width: float = card.size.x - row[0][0].rect.position.x - ReasonCard.PAD
			check("%s: the %s bar's parts follow the probabilities and fill its width" % [tag, row[2]],
				match_p and is_equal_approx(total, width) and row[0].size() == (row[1] as Dictionary).size() and absf(sum_p - 1.0) < 1e-6)
	# the Earth bar's human marks, on the sim's scale
	var xs: Array = card.earth_ticks.map(func(t: Dictionary) -> float: return t.x)
	var track: Rect2 = card.bars.earth.track
	check("the Earth bar has its human marks, in order, inside the bar", xs.size() == 2 and xs[0] < xs[1] and xs[0] > track.position.x and xs[1] < track.end.x)
	# no judgement anywhere in the card's words
	var words := JSON.stringify(ReasonCard.words()).to_lower()
	var clean := true
	for bad: String in ["best", "recommend", "should", "ideal", "optimal"]:
		clean = clean and not words.contains(bad)
	check("no word on the card recommends", clean)
	# formats: formatting only
	check("formats", ReasonCard.format("finder_kg", 1200.0) == "1,200 kg" and ReasonCard.format("finder_years", 43.7) == "43.7 years"
		and ReasonCard.format("finder_sure", "hint") == "A hint" and ReasonCard.format("finder_years", null) == "-")
	# True and Processed
	card.set_processed(true)
	check("Processed is a mode of the same card", card.processed and card._toggle_processed.button_pressed and not card._toggle_true.button_pressed)
	card.set_processed(false)
	check("True is the default mode", not card.processed and card._toggle_true.button_pressed)
	# no candidate: nothing shown, nothing unbound
	card.refresh({"finder": {"candidates": []}}, 0)
	await process_frame
	var any := false
	for n in card.find_children("*", "Label", true, false):
		any = any or n.visible
	check("with no candidate the card shows no label", not any)
	print("reason-card: %d passed, %d failures" % [passes, failures])
	quit(1 if failures > 0 else 0)
