class_name ShipSound
extends Node
## R2-SOUND S1 (design_docs/planned/r2/sound.md §D4, §D5): the bridge's sound, attached to the ship
## demo from outside. It reads what the ship already exposes and touches none of its internals, so the
## bridge styling work can move props freely:
##   captain_event (CA0's foot_down)             -> footsteps at the captain;
##   consoles.focused (edges) and consoles.used  -> console wake / sleep at the station, key presses;
##   lift.state (edges)                          -> lift start, run (riding with the platform), arrive;
##   active_level (edges)                        -> the level's loops and its room (data/audio/rooms.json);
##   journey_sim's world (each step)             -> the Archive's Memory Health (D-113) for the spire;
##   consoles.comms_station.feed.home_sound      -> sound from home while the comms station is open
##                                                  (R3-EARTH-LINK EL3b.7: the bed, its pitch, the accents);
##   the captain and the active view's yaw       -> the listener (§D4, OQ7: left on screen is left in the ears).
## Sources resolve to world positions: "mast" (the SpireLight on the mast), "captain", "station" (the
## station in focus, or the last one), "lift" (the platform).

const ROOMS_PATH := "res://data/audio/rooms.json"
const HEAD_M := 1.6

var demo: Node
var sound: SoundDirector
var listener := AudioListener3D.new()
var rooms := {}
var _level := -1
var _focused := ""
var _last_station := ""
var _lift_moving := false
var _sim: Object = null ## the journey session (a SimBridge)
var _home := "" ## EL3b.7: the home bed playing at the comms station
var _home_accents := 0


func attach(d: Node) -> ShipSound:
	demo = d
	name = "ShipSound"
	return self


func _ready() -> void:
	sound = SoundDirector.new()
	sound.position_of = position_of
	add_child(sound)
	var errs := sound.setup()
	if not errs.is_empty():
		push_warning("ShipSound: the sound tables did not validate: %s" % "; ".join(errs))
	var r: Variant = SoundData.read_json(ROOMS_PATH)
	rooms = r.get("levels", {}) if r is Dictionary else {}
	listener.name = "SoundListener"
	add_child(listener)
	listener.make_current()
	if demo.has_signal("captain_event"):
		demo.captain_event.connect(_on_captain_event)


func _on_captain_event(e: Dictionary) -> void:
	if e.get("type", "") == "foot_down":
		sound.on_game("foot_down")


func _on_used(_station: String, _action: String) -> void:
	sound.on_ui("console_key")


func _on_stepped(_events: Array) -> void:
	if _sim != null:
		sound.on_sim_world(int(_sim.world.get("tick", 0)), _sim.world)


func _process(_delta: float) -> void:
	if demo == null or not is_instance_valid(demo):
		return
	# The listener: at the captain's head, turned with the active view (Bow or Astern).
	var cap := position_of("captain")
	listener.global_position = cap + Vector3(0, HEAD_M, 0)
	listener.global_basis = listener_basis()
	# Level: its loops and its room.
	var lv: int = int(demo.get("active_level")) if demo.get("active_level") != null else 0
	if lv != _level:
		var row: Dictionary = rooms.get(str(lv), {})
		if _level >= 0:
			sound.on_game("level_none")
		SoundMix.set_room(row)
		if row.has("game"):
			sound.on_game(str(row.game))
		_level = lv
	# Consoles: focus edges wake and sleep the station; actions are key presses.
	var consoles: Variant = demo.get("consoles")
	if consoles != null:
		if not consoles.used.is_connected(_on_used):
			consoles.used.connect(_on_used)
		var f := str(consoles.focused)
		if f != _focused:
			if f != "":
				_last_station = f
				sound.on_ui("console_wake")
			elif _focused != "":
				sound.on_ui("console_sleep")
			_focused = f
	_follow_home(consoles)
	# The lift: start, run with the platform, arrive.
	var lift: Variant = demo.get("lift")
	if lift != null:
		var moving: bool = str(lift.state) in ["descending", "ascending"]
		if moving and not _lift_moving:
			sound.on_game("lift_start")
		elif not moving and _lift_moving:
			sound.on_game("lift_arrive")
		_lift_moving = moving
	# The Archive's Memory Health from the journey session (D-113).
	var sim: Variant = demo.get("journey_sim")
	if sim != null and sim != _sim:
		_sim = sim
		if not _sim.stepped.is_connected(_on_stepped):
			_sim.stepped.connect(_on_stepped)
		_on_stepped([])


## R3-EARTH-LINK EL3b.7: while the comms station is open and its feed shows, the receiver plays the
## feed's home_sound: a new bed fades the old one out (home_none) and starts at the band's pitch, the
## pitch follows the band, and each new accent fires once. Closing the station stops it.
func _follow_home(consoles: Variant) -> void:
	var st: Variant = consoles.get("comms_station") if consoles != null and str(consoles.focused) == "comms" else null
	var hs: Dictionary = st.feed.home_sound if st is CommsStation and st.is_inside_tree() and st.feed.visible else {}
	# R3 audio realism AR8b: the stream at the feed's rate (D, or within the receiver's range), the
	# Receiver bus's correction, and nothing at all when the True sound is outside human hearing.
	var cue := "" if hs.get("silent", false) else str(hs.get("cue", ""))
	var rate := float(hs.get("rate", 1.0))
	SoundMix.set_receiver(float(hs.get("correct", 1.0)) if cue != "" else 1.0)
	if cue != _home:
		if _home != "":
			sound.on_game("home_none")
		_home = cue
		_home_accents = int(hs.get("accent_seq", 0))
		if cue != "":
			sound.set_pitch(cue, rate)
			sound.on_game(cue)
	elif cue != "":
		sound.set_pitch(cue, rate)
		if int(hs.accent_seq) != _home_accents:
			_home_accents = int(hs.accent_seq)
			sound.set_pitch(str(hs.accent), rate)
			sound.on_game(str(hs.accent))


## The listener faces where the active camera faces, flattened to the deck: what is left on screen is
## left in the ears, in Bow and in Astern (OQ7). Without a camera, the view's yaw.
func listener_basis() -> Basis:
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	if cam != null:
		var f := -cam.global_basis.z
		f.y = 0.0
		if f.length() > 0.001:
			return Basis.looking_at(f.normalized(), Vector3.UP)
	var yaw: float = demo.director.walk_yaw() if demo.get("director") != null else 0.0
	return Basis(Vector3.UP, yaw)


## A cue source's world position.
func position_of(source: String) -> Vector3:
	match source:
		"captain":
			var av: Variant = demo.get("avatar")
			return (av as Node3D).global_position if av is Node3D and (av as Node3D).is_inside_tree() else Vector3(demo.get("avatar_pos"))
		"mast":
			var spire := demo.find_child("SpireLight", true, false) as Node3D
			return spire.global_position if spire != null else Vector3.ZERO
		"station":
			var consoles: Variant = demo.get("consoles")
			var id := _focused if _focused != "" else _last_station
			if consoles != null and consoles.stations.has(id):
				var meshes: Array = consoles.stations[id].meshes
				return meshes[0].origin if not meshes.is_empty() else consoles.stations[id].use
			return position_of("captain")
		"lift":
			var lift: Variant = demo.get("lift")
			return (lift.platform as Node3D).global_position if lift != null else position_of("captain")
	return position_of("captain")
