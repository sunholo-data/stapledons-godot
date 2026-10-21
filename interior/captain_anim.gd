class_name CaptainAnim
extends RefCounted
## R2-CAPTAIN-ANIMATION §D2: what the captain's billboard shows, as a pure function of the inputs
## and this small state (no nodes, no clocks), so it is testable headless and deterministic.
##
##   facing  : the motion's direction ON SCREEN (relative to the fixed view's yaw), in 8 sectors of
##             45 deg with 10 deg of hysteresis, from the heading on the deck: at rest the captain keeps
##             the last heading (so a view switch turns the drawing, not the captain); at a station or
##             in the chair the heading is the bow (the back in Bow, the front in Astern). Sector 0 is
##             away (up the screen), clockwise: 2 is right, 4 toward, 6 left. Five painted facings;
##             the three left-moving ones are mirrors (the identity is mirror-safe, 2026-10-03).
##   phase   : the gait cycle advances with DISTANCE (|v| dt / cycle_m), never with time, so a planted
##             foot cannot skate: no distance, no advance.
##   clips   : idle, start, jog, stop, use_low/mid/high, sit/seated/stand, lift, look_up.
##   events  : foot_down (L or R) when the phase crosses a contact (the sound hook, §D5).
##   reduced : reduced motion keeps the stride and the poses; drops the bob, the lean and look-ups.
## Presentation only: nothing here goes to the sim.

const IDLE_SPEED_MPS := 0.2
const HYSTERESIS_DEG := 10.0
const START_S := 0.25
const STOP_S := 0.3
const SIT_S := 0.6
const STAND_S := 0.5
const LOOK_UP_S := 2.0
const BOB_M := 0.025
const LEAN_DEG := 4.0
const DEFAULT_CYCLE_M := 2.3333 # the pose-guide rig's jog: 20 frames at 30 fps at 3.5 m/s
const STATION_CLIPS := ["use_low", "use_mid", "use_high"]
## The use height per station (DL1 heights: the Voyage and Crew desks 0.95 m, the Archive terminal and
## the navigation pods 1.1 m); unknown stations use the middle height.
const STATION_CLIP := {"voyage": "use_low", "crew": "use_low", "archive": "use_mid", "navigation": "use_mid"}
## sector -> [painted facing, mirrored]
const PAINTED := [["back", false], ["back_34", false], ["profile", false], ["front_34", false],
	["front", false], ["front_34", true], ["profile", true], ["back_34", true]]

var sector := 0
var heading := Vector3.ZERO # the facing on the deck (ship frame); the sector is its screen direction
var clip := "idle"
var phase := 0.0 # gait cycle position, [0, 1)
var clip_t := 0.0 # seconds in the current timed clip
var chair := "" # "", "sit", "seated", "stand"
var look_up_t := 0.0
var cycle_m := DEFAULT_CYCLE_M
var contacts: Array = [[0.0, "L"], [0.5, "R"]] # cycle fractions where a sole plants
var _moving := false


## The ground velocity's direction on screen for a view of this yaw: x right, y away (up-screen).
## The view's forward on the deck is (cos yaw, 0, sin yaw) and its right is (-sin yaw, 0, cos yaw),
## as `CameraDirector.walk_yaw` and the demo's WASD mapping use them.
static func screen_dir(v: Vector3, view_yaw: float) -> Vector2:
	var fwd := Vector3(cos(view_yaw), 0.0, sin(view_yaw))
	var right := Vector3(-sin(view_yaw), 0.0, cos(view_yaw))
	return Vector2(v.dot(right), v.dot(fwd))


## The sector (0..7) of a screen direction; a direction within the hysteresis of the previous
## sector's edges keeps it. A zero direction keeps `prev`.
static func sector_of(dir: Vector2, prev: int = -1) -> int:
	if dir.length() < 1e-9:
		return maxi(prev, 0)
	var a := fposmod(rad_to_deg(atan2(dir.x, dir.y)), 360.0) # 0 = away, clockwise
	if prev >= 0:
		var off := absf(fposmod(a - prev * 45.0 + 180.0, 360.0) - 180.0)
		if off <= 22.5 + HYSTERESIS_DEG:
			return prev
	return int(floor(fposmod(a + 22.5, 360.0) / 45.0)) % 8


## inp: velocity (Vector3, m/s, ship frame), view_yaw (rad), station ("" or a STATION_CLIPS id),
## face_dir (Vector3, the bow), chair ("sit" asks to sit), move_request (a move key while seated),
## lift (bool, riding), cue ("look_up"), reduced (bool). dt in seconds.
func step(inp: Dictionary, dt: float) -> Dictionary:
	var v: Vector3 = inp.get("velocity", Vector3.ZERO)
	v.y = 0.0
	var speed := v.length()
	var yaw: float = inp.get("view_yaw", 0.0)
	var reduced: bool = inp.get("reduced", false)
	var station: String = str(inp.get("station", ""))
	var events: Array = []
	# The chair: sit, seated, then a move key stands first.
	if str(inp.get("chair", "")) == "sit" and chair == "":
		_set_chair("sit")
	elif chair == "sit" and clip_t >= SIT_S:
		_set_chair("seated")
	elif chair in ["sit", "seated"] and bool(inp.get("move_request", false)):
		_set_chair("stand")
	elif chair == "stand" and clip_t >= STAND_S:
		_set_chair("")
	var seated := chair != ""
	var moving := speed > IDLE_SPEED_MPS and not seated
	# Facing.
	var face: Vector3 = inp.get("face_dir", Vector3.ZERO)
	if (seated or (station != "" and not moving)) and face.length() > 1e-9:
		heading = face.normalized()
	elif moving:
		heading = v / speed
	if heading.length() > 1e-9:
		sector = sector_of(screen_dir(heading, yaw), sector)
	# The gait phase, by distance.
	if moving:
		var before := phase
		phase = fposmod(phase + speed * dt / cycle_m, 1.0)
		for c in contacts:
			var at: float = c[0]
			var crossed := (before < at and at <= phase) if phase >= before else (at > before or at <= phase)
			if crossed:
				events.append({"type": "foot_down", "side": c[1]})
	# Look-up on a cue.
	if str(inp.get("cue", "")) == "look_up" and not reduced:
		look_up_t = LOOK_UP_S
	look_up_t = maxf(0.0, look_up_t - dt)
	# The clip.
	var next := clip
	if seated:
		next = chair
	elif bool(inp.get("lift", false)):
		next = "lift"
	elif station in STATION_CLIPS and not moving:
		next = station
	elif moving:
		next = "start" if not _moving or (clip == "start" and clip_t + dt < START_S) else "jog"
	else:
		if _moving or (clip == "stop" and clip_t + dt < STOP_S):
			next = "stop"
		elif look_up_t > 0.0:
			next = "look_up"
		else:
			next = "idle"
	if next != clip:
		clip = next
		clip_t = 0.0
		events.append({"type": "clip", "clip": clip})
	else:
		clip_t += dt
	_moving = moving
	var bob := 0.0
	var lean := 0.0
	if not reduced:
		if clip in ["jog", "start"]:
			bob = BOB_M * absf(sin(TAU * phase))
		if clip == "start":
			lean = LEAN_DEG
		elif clip == "stop":
			lean = -LEAN_DEG * 0.75
	var p: Array = PAINTED[sector]
	return {"clip": clip, "phase": phase, "clip_t": clip_t, "sector": sector, "facing": p[0], "flip": p[1],
		"bob_m": bob, "lean_deg": lean, "events": events, "hold_move": seated}


func _set_chair(state: String) -> void:
	chair = state
	clip_t = 0.0


## Take the gait from a painted clip (manifest anim.clips.jog): its cycle length and contacts, so the
## phase advances one painted frame per (cycle_m / frames) of ground and the feet stay planted.
func use_gait(clip: Dictionary) -> void:
	if float(clip.get("cycle_m", 0.0)) > 0.0:
		cycle_m = float(clip.cycle_m)
	if clip.get("contacts", []) is Array and not clip.get("contacts", []).is_empty():
		contacts = clip.contacts
