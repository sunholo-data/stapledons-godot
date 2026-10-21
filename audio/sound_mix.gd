class_name SoundMix
extends RefCounted
## R2-SOUND §D2 (design_docs/planned/r2/sound.md): the bus layout, built in code from BUSES so one
## table is the source of truth (the tests compare AudioServer with it), and the volume settings.
##
##   Master      HardLimiter ceiling −1 dB (the safety net; headroom is measured before it)
##   ├ Voice     crew lines and the Archive
##   ├ Ship      Compressor sidechained to Voice (ducks ≥ 6 dB under a voice), Reverb (per level, S1)
##   │ ├ Ambience     room tone, the spire's hum, beds
##   │ ├ Effects      machines, the lift, the drive, footsteps
##   │ └ Instruments  the dust counter, navigation tones
##   ├ UI        Compressor sidechained to Voice (lighter)
##   └ Music     sidechained to Voice; empty (OQ4, D-101)
##
## Presentation only: nothing here reaches the sim.

## name -> {send, effects}. Effect specs are plain data so the layout test can read them back.
const BUSES := [
	{"name": "Voice", "send": "Master"},
	{"name": "Ship", "send": "Master", "duck": {"threshold": -24.0, "ratio": 3.0, "attack_us": 5000.0, "release_ms": 300.0}, "reverb": true},
	{"name": "Ambience", "send": "Ship"},
	{"name": "Effects", "send": "Ship"},
	{"name": "Instruments", "send": "Ship"},
	{"name": "UI", "send": "Master", "duck": {"threshold": -26.0, "ratio": 2.0, "attack_us": 5000.0, "release_ms": 200.0}},
	{"name": "Music", "send": "Master", "duck": {"threshold": -30.0, "ratio": 4.0, "attack_us": 5000.0, "release_ms": 400.0}},
]
## The buses a player can set (settings.cfg [audio] volume_<bus>), in the order a settings panel shows them.
const SETTABLE := ["Master", "Voice", "Effects", "Ambience", "Instruments", "UI", "Music"]
const LIMIT_CEILING_DB := -1.0
## Reduced audio (§D2): a gentle compressor at the head of Master evens out sudden cues. Off by default.
const REDUCED := {"threshold": -24.0, "ratio": 3.0, "attack_us": 2000.0, "release_ms": 250.0}


## Builds the layout once (idempotent): existing buses with the right names are reused, so a second
## call, or a scene that already built it, changes nothing.
static func ensure_layout() -> void:
	if AudioServer.get_bus_index("Music") >= 0 and is_layout_ok().is_empty():
		return
	_master_effects()
	for spec: Dictionary in BUSES:
		var i := AudioServer.get_bus_index(spec.name)
		if i < 0:
			i = AudioServer.bus_count
			AudioServer.add_bus(i)
			AudioServer.set_bus_name(i, spec.name)
		AudioServer.set_bus_send(i, spec.send)
		while AudioServer.get_bus_effect_count(i) > 0:
			AudioServer.remove_bus_effect(i, 0)
		if spec.has("duck"):
			AudioServer.add_bus_effect(i, _compressor(spec.duck, "Voice"))
		if spec.get("reverb", false):
			var r := AudioEffectReverb.new()
			r.wet = 0.0 # S1: data/audio/rooms.json sets the level's room
			r.dry = 1.0
			AudioServer.add_bus_effect(i, r)


static func _master_effects() -> void:
	while AudioServer.get_bus_effect_count(0) > 0:
		AudioServer.remove_bus_effect(0, 0)
	var reduced := _compressor(REDUCED, "")
	AudioServer.add_bus_effect(0, reduced)
	AudioServer.set_bus_effect_enabled(0, 0, false)
	var lim := AudioEffectHardLimiter.new()
	lim.ceiling_db = LIMIT_CEILING_DB
	AudioServer.add_bus_effect(0, lim)


static func _compressor(spec: Dictionary, sidechain: String) -> AudioEffectCompressor:
	var c := AudioEffectCompressor.new()
	c.threshold = spec.threshold
	c.ratio = spec.ratio
	c.attack_us = spec.attack_us
	c.release_ms = spec.release_ms
	c.gain = 0.0
	if not sidechain.is_empty():
		c.sidechain = sidechain
	return c


## Empty when AudioServer matches BUSES; otherwise one line per difference (the layout test prints them).
static func is_layout_ok() -> Array[String]:
	var bad: Array[String] = []
	var lim := _find_effect(0, "AudioEffectHardLimiter")
	if lim == null or not is_equal_approx((lim as AudioEffectHardLimiter).ceiling_db, LIMIT_CEILING_DB):
		bad.append("Master has no HardLimiter at %.1f dB" % LIMIT_CEILING_DB)
	for spec: Dictionary in BUSES:
		var i := AudioServer.get_bus_index(spec.name)
		if i < 0:
			bad.append("no bus %s" % spec.name)
			continue
		if AudioServer.get_bus_send(i) != StringName(spec.send):
			bad.append("%s sends to %s, not %s" % [spec.name, AudioServer.get_bus_send(i), spec.send])
		var comp := _find_effect(i, "AudioEffectCompressor")
		if spec.has("duck") and (comp == null or (comp as AudioEffectCompressor).sidechain != &"Voice"):
			bad.append("%s is not ducked by Voice" % spec.name)
		if not spec.has("duck") and comp != null:
			bad.append("%s has an unexpected compressor" % spec.name)
		if spec.get("reverb", false) and _find_effect(i, "AudioEffectReverb") == null:
			bad.append("%s has no reverb" % spec.name)
	return bad


static func _find_effect(bus: int, cls: String) -> AudioEffect:
	for j in AudioServer.get_bus_effect_count(bus):
		var e := AudioServer.get_bus_effect(bus, j)
		if e.get_class() == cls:
			return e
	return null


## A settings percentage (0..100) as a bus volume: 0 mutes; otherwise an amplitude of (p/100)², so
## 50% is about −12 dB, 80% about −3.9 dB and 10% −40 dB (a perceptual taper, not a linear one).
static func percent_to_db(p: int) -> float:
	if p <= 0:
		return -80.0
	var a := clampf(p / 100.0, 0.0, 1.0)
	return 20.0 * log(a * a) / log(10.0)


## Applies a GameSettings' audio section to the buses (volumes, mutes, reduced audio).
static func apply(s: GameSettings) -> void:
	ensure_layout()
	for bus: String in SETTABLE:
		var i := AudioServer.get_bus_index(bus)
		var p: int = s.volume(bus)
		AudioServer.set_bus_volume_db(i, percent_to_db(p))
		AudioServer.set_bus_mute(i, p <= 0)
	AudioServer.set_bus_effect_enabled(0, 0, s.reduced_audio)


## Window focus (main.gd): with Mute when unfocused on, Master mutes while the window is in the
## background and returns to the player's setting when it comes back.
static func focus_changed(focused: bool, s: GameSettings) -> void:
	AudioServer.set_bus_mute(0, (not focused and s.mute_unfocused) or s.volume("Master") <= 0)


## S1 (§D5): a level's room on the Ship bus reverb (data/audio/rooms.json): room_size, damping, wet (dB).
static func set_room(room: Dictionary) -> void:
	var ship := AudioServer.get_bus_index("Ship")
	var r := _find_effect(ship, "AudioEffectReverb") as AudioEffectReverb
	if r == null:
		return
	r.room_size = clampf(float(room.get("room_size", 0.0)), 0.0, 1.0)
	r.damping = clampf(float(room.get("damping", 0.5)), 0.0, 1.0)
	r.wet = clampf(db_to_linear(float(room.get("wet_db", -80.0))), 0.0, 1.0)
	r.dry = 1.0
