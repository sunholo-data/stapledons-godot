class_name CardInterlude
extends CruiseInterlude
## The demo's cruise interlude: one card. R2-INTERLUDE I1 (design interlude-card.md D1): the
## crossing goes in chunks, one per frame, each exactly the simulation's next stop
## (protocol 2.10 `cruise.next_stop_years`: a monthly crew check-in, the 365-day cap, or the
## braking boundary), never more than the cruise left. A crew hold raised on a check-in ends its
## chunk, and the host (demos/solar_departure.gd crew_held) stops before the next one; Resume
## continues the crossing. Once the braking boundary is reached the card holds for CARD_S
## seconds (or until Continue); I3 replaces the card with the crossing review. Every number is a
## simulation field (CruiseInterlude.facts_from); the text tier is chosen from the simulation's
## cumulative Earth time since departure. Below 2.10 (no `cruise`) the whole cruise is one step.

const CARD_S := 6.0
## Draft wording (design open question 2, for Mark to edit). %s is the whole
## number of Earth years since departure, read from clock.year.
const TIERS := [
	[10.0, "%s years have passed at home. The news you left with is history."],
	[80.0, "%s years at home. Your parents' generation is gone; the friends you left are old."],
	[INF, "%s years. Everyone you knew is gone. No one alive on Earth was born when you left."],
]

## D-76: what the crossing is doing between chunks, by the sim's stop kind.
const CROSSING := {
	"check_in": "Crossing… the crew's monthly check-in.",
	"chunk": "Crossing… another year aboard.",
	"braking": "Crossing… to arrival braking.",
}

var _consumed := false
var _shown := 0.0
var _continued := false
var chunks := 0

## Ship years for this frame: the sim's next stop, capped at max_years (the cruise left).
func advance(max_years: float, delta: float) -> float:
	if not _consumed:
		var left := maxf(0.0, max_years)
		var stop: Dictionary = latest.get("cruise", {})
		if not stop.has("next_stop_years"):
			_consumed = true
			return left
		var step := minf(left, maxf(0.0, float(stop.next_stop_years)))
		if str(stop.get("stop_kind", "")) == "braking" or step >= left:
			_consumed = true
		chunks += 1
		return step
	_shown += maxf(0.0, delta)
	return 0.0

## True once the crossing has reached the braking boundary.
func crossed() -> bool:
	return _consumed

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
		"cut": "Cutting to arrival braking." if _consumed else str(CROSSING.get(str(after.get("cruise", {}).get("stop_kind", "")), "Crossing…")),
		"ism": IsmHud.interlude_text(before, after),
	}
