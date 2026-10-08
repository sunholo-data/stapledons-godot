extends RefCounted
## M3.6 of R1-M3-BLACK-HOLES (design m3-black-holes.md §M3.6, D-52, D-53): the Sgr A* demo
## aboard the unified 3D ship. Its own simulation session (scenario sgr_a, protocol 2.6), apart
## from the ship's normal navigation session, which it replaces while it runs.
##
## The journey: hover at 10^6 r_s (1.34 ly from Sgr A*), then the stops in STOPS, one per
## "next stop" (N): approach to 10 r_s at local beta 0.1, hover; on to 5 and 3 r_s; orbit at 3 r_s;
## hover again. Every number on the HUD is a field of the sim's gr section (hud_lines formats,
## it never derives). Pacing is the only client choice: how much ship time one tick asks for.
##
## Pacing (never shown, so it may be approximate): during an approach each tick asks for a
## fraction of the remaining ship time, estimated as distance / (beta_local c) in flat space;
## the sim lands on the target exactly and hovers for whatever is left of the tick (sim/gr.ail
## advanceS). So a long approach reads as a steady fall in log r. Hovering and orbiting run at
## WARP ship-seconds per real second.

const SCENARIO := "sgr_a"
const SEED := 424242
const TICK_HZ := 20.0 # GalaxyMap.TICK_HZ: the ship demo's live tick rate
const WARP := 30.0 # ship-seconds per real second while hovering or orbiting (one orbit at 3 r_s ~ 46 s)
const APPROACH_FRACTION := 0.05 # of the remaining (estimated) approach time per tick
const APPROACH_FLOOR_RS := 0.05 # the smallest approach step, in r_s of travel
const FINISH_FACTOR := 3.0 # K: ask for 3x the flat estimate; the sim lands exactly and hovers the rest
const C_MS := 299792458.0
const YEAR_S := 31557600.0
const BETA := 0.1
const MAX_DTAU := 1.0 # ship-years: the protocol's largest tick (sim/protocol.ail, bad_step above)
## The scripted stops after the start (hover at 10^6 r_s). Plan M3.6: approach 10^6 -> 10 at
## beta 0.1, hover, then 5 -> 3, then orbit.
const STOPS := [
	{"label": "Approach to 10 r_s (β 0.1)", "intents": [{"k": "gr_approach", "to_r": 10.0, "beta_local": BETA}]},
	{"label": "Approach to 5 r_s (β 0.1)", "intents": [{"k": "gr_approach", "to_r": 5.0, "beta_local": BETA}]},
	{"label": "Approach to 3 r_s (β 0.1)", "intents": [{"k": "gr_approach", "to_r": 3.0, "beta_local": BETA}]},
	{"label": "Orbit at 3 r_s", "intents": [{"k": "gr_orbit"}]},
	{"label": "Hover at 3 r_s", "intents": [{"k": "gr_hover"}]},
]
const SKY_CAPTION := "Sky: the Milky Way and stars as seen from Sol, lensed by the hole (the true Galactic-Centre sky is later work)"

var sim: SimBridge
var stops_taken := 0
var ring_pending := false
var ring_reported := false
var last_error := ""
## The sim's Archive events this session, in order (bh_enter, bh_hover, bh_ring; design §M3.4).
var archive_events: Array = []


## A new sgr_a session. archive_rows: the codex table (LoreLoader.archive_rows), so the sim can
## unlock the black-hole entries. params: optional bh_mass_msun / bh_r (scenario parameters).
func start(archive_rows: Array, params := {}) -> bool:
	sim = SimBridge.new()
	sim.want_minor = SimBridge.GR_MINOR
	sim.archive_rows = archive_rows
	if not sim.start() or not sim.new_game(SEED, SCENARIO, false, params):
		last_error = sim.last_error
		sim.stop()
		return false
	if sim.gr.is_empty():
		last_error = "no gr section"
		sim.stop()
		return false
	_take_events(sim.state.get("events", []))
	return true


func _take_events(events: Array) -> void:
	for e in events:
		if e is Dictionary and e.get("k", "") == "archive":
			archive_events.append(str(e.get("event", "")))


func stop() -> void:
	if sim != null:
		sim.stop()


func gr() -> Dictionary:
	return sim.gr if sim != null else {}


func approaching() -> bool:
	return gr().get("mode", "") == "approach"


func next_label() -> String:
	return STOPS[stops_taken].label if stops_taken < STOPS.size() else ""


## N: the next stop's intents, at once (dtau 0). False past the last stop, during an approach,
## or when the sim refuses (last_error = its reason; the state is unchanged).
func next_stop() -> bool:
	if sim == null or stops_taken >= STOPS.size() or approaching():
		return false
	if not sim.send(STOPS[stops_taken].intents.duplicate(true), 0.0):
		last_error = sim.last_error
		return false
	_take_events(sim.last_events)
	if not sim.last_refused.is_empty():
		last_error = str(sim.last_refused[0].get("reason", "refused"))
		return false
	stops_taken += 1
	return true


## Intents at once (dtau 0), outside the scripted stops (captures: an orbit at 10 or 5 r_s).
func send_now(intents: Array) -> bool:
	if sim == null or not sim.send(intents, 0.0):
		return false
	_take_events(sim.last_events)
	return sim.last_refused.is_empty()


## One live tick (TICK_HZ): pace_years of ship time, with the first ring star if one is pending.
func step() -> bool:
	return _send(pace_years(gr()))


## K: the rest of an approach now, in as few ticks as the protocol allows (dtau <= 1 ship-year
## per tick): from 10^6 r_s that is ~14 ticks; from 10 r_s, one.
func finish_approach() -> bool:
	if not approaching():
		return false
	for i in 64:
		if not approaching():
			return true
		if not _send(minf(MAX_DTAU, FINISH_FACTOR * approach_rest_years(gr()) + APPROACH_FLOOR_RS * approach_unit_years(gr()))):
			return false
	return not approaching()


## The client saw its first ring star (the sky's ring-star path fired); the sim echoes bh_ring.
func report_ring() -> void:
	if not ring_reported:
		ring_pending = true


func _send(dtau: float) -> bool:
	if sim == null:
		return false
	var intents := [{"k": "gr_ring"}] if ring_pending else []
	if not sim.send(intents, dtau):
		last_error = sim.last_error
		return false
	_take_events(sim.last_events)
	if ring_pending:
		ring_pending = false
		ring_reported = true
	return true


## Ship-years per r_s of travel at the commanded local speed, flat estimate (pacing only).
static func approach_unit_years(g: Dictionary) -> float:
	return float(g.get("rs_m", 0.0)) / (maxf(float(g.get("beta_local", BETA)), 1e-6) * C_MS) / YEAR_S


static func approach_rest_years(g: Dictionary) -> float:
	return absf(float(g.get("r", 0.0)) - float(g.get("to_r", 0.0))) * approach_unit_years(g)


## Ship-years one live tick asks for.
static func pace_years(g: Dictionary) -> float:
	if g.get("mode", "") == "approach":
		return minf(MAX_DTAU, maxf(APPROACH_FRACTION * approach_rest_years(g), APPROACH_FLOOR_RS * approach_unit_years(g)))
	return WARP / TICK_HZ / YEAR_S


# ------------------------------------------------------------ HUD (formats only)
## The black-hole HUD: each number is one gr field, formatted (unit changes only: radians to
## degrees or arcseconds). Empty for an empty section.
static func hud_lines(g: Dictionary) -> PackedStringArray:
	var out := PackedStringArray()
	if g.is_empty():
		return out
	out.append("%s · %s M☉ · r_s %s m" % [g.hole_id, sci(float(g.mass_msun), 3), sci(float(g.rs_m), 2)])
	var r := r_text(float(g.r))
	var motion := "β_local %.4f (γ %.4f)" % [float(g.beta_local), float(g.gamma_local)]
	match str(g.mode):
		"approach": out.append("APPROACHING r = %s r_s → %s r_s · %s" % [r, r_text(float(g.to_r)), motion])
		"orbit": out.append("ORBITING at r = %s r_s · %s · %s" % [r, motion, "stable (r ≥ 3, the ISCO)" if g.orbit_stable else "UNSTABLE (inside the ISCO)"])
		_: out.append("HOVERING at r = %s r_s" % r)
	out.append("static clock %s · 1 ship-hour = %s home hours" % [ratio_text(float(g.static_clock), 6), ratio_text(float(g.home_per_ship), 4)])
	out.append("shadow half-angle %s · incoming light ×%s (blueshift)" % [angle_text(float(g.shadow)), ratio_text(float(g.blueshift), 4)])
	out.append("tide across the bubble %s g radial · %s g squeeze" % [sci(float(g.tidal_radial_g), 2), sci(float(g.tidal_transverse_g), 2)])
	match str(g.mode):
		"hover": out.append("hover %s g · not felt (bubble) · %s W per kg of m_eff" % [sci(float(g.hover_accel_g), 2), sci(float(g.hover_power_w_per_kg), 2)])
		"orbit": out.append("free fall: 0 W (in orbit nothing holds the ship up)")
		_: out.append("drive: kinematic approach (no hover load)")
	out.append(SKY_CAPTION)
	return out


const _SUP := {"0": "⁰", "1": "¹", "2": "²", "3": "³", "4": "⁴", "5": "⁵", "6": "⁶", "7": "⁷", "8": "⁸", "9": "⁹", "-": "⁻"}

static func _sup(n: int) -> String:
	var s := ""
	for ch in str(n):
		s += _SUP[ch]
	return s


## x in scientific form (d decimals) outside [0.01, 1000), plain otherwise.
static func sci(x: float, d := 2) -> String:
	if x == 0.0 or not is_finite(x):
		return "0" if x == 0.0 else str(x)
	var ax := absf(x)
	if ax >= 0.01 and ax < 1000.0:
		return ("%." + str(d) + "f") % x
	var e := floori(log(ax) / log(10.0))
	var m := x / pow(10.0, e)
	var ms := ("%." + str(d) + "f") % m
	if absf(float(ms)) >= 10.0: # rounding carried into the next decade
		e += 1
		ms = ("%." + str(d) + "f") % (x / pow(10.0, e))
	return "%s×10%s" % [ms, _sup(e)]


## A ratio near 1 with enough decimals to show its departure from 1 (at least min_d).
static func ratio_text(x: float, min_d := 4) -> String:
	var off := absf(x - 1.0)
	var d := min_d
	if off > 0.0:
		d = clampi(maxi(min_d, ceili(-log(off) / log(10.0)) + 2), min_d, 12)
	return ("%." + str(d) + "f") % x


static func r_text(r: float) -> String:
	return "%.2f" % r if r < 1000.0 else sci(r, 2)


static func angle_text(rad: float) -> String:
	var deg := rad_to_deg(rad)
	return "%.2f°" % deg if deg >= 0.01 else "%.3f″" % (deg * 3600.0)
