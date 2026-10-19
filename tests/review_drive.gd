extends RefCounted
## R2-INTERLUDE I3: drive the live demo (demos/ship_geometry_demo.gd) along the guided voyage to the
## crossing review, the honest way: the Voyage console's Begin, the itinerary's own legs (Skip
## dwell brings the next forward), Skip stage [K] through each stage, and every crew hold answered
## with the review's own confirmed Resume (two presses). Shared by tests/test_no_twitch.gd,
## tests/m4_playthrough_ship.gd and tools/crossing_review_capture.gd.

const RESUME := "resume"


## Begin the guided voyage at the Voyage console; `next_leg` (the itinerary index of the leg to
## fly next, e.g. 4 for Alpha Centauri) skips the earlier legs, as tests/test_crew_hold.gd does.
static func begin(demo: Node, next_leg := -1) -> bool:
	var c: ShipConsoles = demo.consoles
	c.go_to("voyage")
	c.use("voyage", "open")
	c.use("voyage", "begin")
	c.leave()
	if demo.solar_tour == null:
		return false
	if next_leg >= 0:
		demo.solar_tour.leg_index = next_leg - 1
	return true


## One host frame toward the review. Returns "crossed" when the review's crossing is over, "held"
## when a hold is open mid-crossing (answered first when resume_holds), "failed", or "".
static func frame(demo: Node, resume_holds := true, dt := 0.05) -> String:
	var tour = demo.solar_tour
	if tour == null or not tour.failed.is_empty():
		return "failed"
	var card: CardInterlude = tour.interlude as CardInterlude
	if tour.crew_held():
		if card != null and not resume_holds:
			demo._show_interlude()
			return "held"
		if card != null and demo.crossing_review.visible and demo.crossing_review.current() == "hold":
			demo.crossing_review.press_resume()
			demo.crossing_review.press_resume()
		else:
			for h: Dictionary in demo.journey_sim.crew.get("holds", []):
				demo.journey_sim.queue([SimBridge.crew_intent("crew_resume", {"command": "resume", "hold": str(h.id)})])
	elif card != null and card.crossed() and not card.done():
		demo._show_interlude()
		return "crossed"
	elif not demo.live_journey and tour.pending_index < 0 and not tour.attitude_hold:
		demo.skip_dwell()
	elif card != null or (demo.live_journey and str(demo.journey_sim.world.ship.phase) in ["boosting", "braking", "approaching"]):
		# Skip the boost (and, after a review, braking and the approach); the cruise plays its
		# real-time hold (pacing) until the interlude is due, then Skip stage crosses it chunk by
		# chunk (stopping at a hold or at the braking boundary).
		demo.skip_stage()
	if not demo.journey_tick():
		return "failed"
	demo._process(dt)
	return ""


## Frames until the review's crossing is over (or a hold, when stop_on_hold).
static func reach(demo: Node, stop_on_hold := false, max_frames := 6000) -> String:
	for i in max_frames:
		var s := frame(demo, not stop_on_hold)
		if s != "":
			return s
	return "failed"
