class_name CardInterlude
extends CruiseInterlude
## The guided voyage's cruise interlude. R2-INTERLUDE I1 (design interlude-card.md D1): the
## crossing goes in chunks, one per frame, each exactly the simulation's next stop (protocol 2.10
## `cruise.next_stop_years`: a monthly crew check-in, the 365-day cap, or the braking boundary),
## never more than the cruise left. A crew hold raised on a check-in ends its chunk, and the host
## (demos/solar_departure.gd crew_held) stops before the next one; Resume continues the crossing.
## Below 2.10 (no `cruise`) the whole cruise is one step.
## R2-INTERLUDE I3 (D2, G1): once the braking boundary is reached the crossing review
## (ui/crossing_review.gd) is the player's to read. No timer ever ends it: with a reader
## (`awaits_reader`, the live demo) it is done only when the player brakes (finish()). A host with
## no view (headless drivers, the tests) has nothing to read, so it is done at the boundary.
## The review's numbers are the sim's (cruise.digest); this class computes none.

## D-76: what the crossing is doing between chunks, by the sim's stop kind.
const CROSSING := {
	"check_in": "Crossing… the crew's monthly check-in.",
	"chunk": "Crossing… another year aboard.",
	"braking": "Crossing… to arrival braking.",
}

var awaits_reader := false
var _consumed := false
var _continued := false
var chunks := 0

## Ship years for this frame: the sim's next stop, capped at max_years (the cruise left).
func advance(max_years: float, _delta: float) -> float:
	if _consumed:
		return 0.0
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

## True once the crossing has reached the braking boundary.
func crossed() -> bool:
	return _consumed

## The player braked (the review's last page). Ignored until the crossing is over.
func finish() -> void:
	_continued = true

func done() -> bool:
	return _consumed and (_continued or not awaits_reader)

## The progress line between chunks (D-76), from the sim's stop kind.
func progress_text() -> String:
	return str(CROSSING.get(str(latest.get("cruise", {}).get("stop_kind", "")), "Crossing…"))

## The speed as the plan states it: "0.9999c" for 1 - beta = 1e-4, else six decimals. Formatting
## only: both numbers are the sim's plan fields (DisplayBinding format "speed_c").
static func speed_text(beta: float, one_minus_beta: float) -> String:
	if one_minus_beta > 0.0:
		var n := -log(one_minus_beta) / log(10.0)
		if absf(n - round(n)) < 1e-9 and n >= 1.0:
			return "0." + "9".repeat(int(round(n))) + "c"
	return "%.6fc" % beta
