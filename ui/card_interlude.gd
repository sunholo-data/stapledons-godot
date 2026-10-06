class_name CardInterlude
extends CruiseInterlude
## The demo's cruise interlude: one card. It hands the whole remaining cruise to
## the simulation in its first frame, then holds for CARD_S seconds (or until
## Continue) while the card shows the before and after clocks. Every number is
## a simulation field (CruiseInterlude.facts_from); the text tier is chosen from
## the simulation's cumulative Earth time since departure.

const CARD_S := 6.0
## Draft wording (design open question 2, for Mark to edit). %s is the whole
## number of Earth years since departure, read from clock.year.
const TIERS := [
	[10.0, "%s years have passed at home. The news you left with is history."],
	[80.0, "%s years at home. Your parents' generation is gone; the friends you left are old."],
	[INF, "%s years. Everyone you knew is gone. No one alive on Earth was born when you left."],
]

var _consumed := false
var _shown := 0.0
var _continued := false

func advance(max_years: float, delta: float) -> float:
	if not _consumed:
		_consumed = true
		return maxf(0.0, max_years)
	_shown += maxf(0.0, delta)
	return 0.0

func finish() -> void:
	_continued = true

func done() -> bool:
	return _consumed and (_continued or _shown >= CARD_S)

## Seconds the card has been shown, for the clock animation (0..CARD_S).
func shown() -> float:
	return _shown

static func tier_text(earth_years: float) -> String:
	var n := "%d" % int(round(earth_years))
	for t: Array in TIERS:
		if earth_years < float(t[0]):
			return String(t[1]) % n
	return ""

## The speed as the plan states it: "0.9999c" for 1 - beta = 1e-4, else six decimals.
static func speed_text(beta: float, one_minus_beta: float) -> String:
	if one_minus_beta > 0.0:
		var n := -log(one_minus_beta) / log(10.0)
		if absf(n - round(n)) < 1e-9 and n >= 1.0:
			return "0." + "9".repeat(int(round(n))) + "c"
	return "%.6fc" % beta

## Lines for the card view; before = facts at begin, after = latest.
func lines() -> Dictionary:
	var before := facts
	var after := latest
	var lived_days := (float(after.ship_tau) - float(before.ship_tau)) * 365.25
	var earth_years := float(after.earth_year) - float(before.earth_year)
	return {
		"title": "CRUISE · %s" % str(before.leg),
		"speed": "%s · γ %.1f" % [speed_text(float(before.cruise_beta), float(before.cruise_one_minus_beta)), float(before.cruise_gamma)],
		"distance": "%.1f light-years" % float(before.distance_ly),
		"lived": "You live %.0f days. %.2f years pass on Earth." % [lived_days, earth_years],
		"news": "News from home is %.1f years old when it reaches you." % float(after.news_age_years),
		"tier": tier_text(float(after.earth_year)),
		"cut": "Cutting to arrival braking.",
	}
