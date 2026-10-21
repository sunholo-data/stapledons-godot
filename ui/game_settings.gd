class_name GameSettings
extends RefCounted
## Title-screen settings (design_docs/implemented/r1/title-screen.md): the ship's
## view (D-38 Realistic / Auto) and text-only AI (D-8).
##
## - The view lives in `<dir>/settings.cfg` ([display] auto_view). Default Auto
##   (Mark, attended 2026-10-08, D-55: "I always turn it on"); Realistic stays one
##   key (V) away, and the ship remembers the last choice.
## - Text-only is NOT duplicated: it is AiSettings' `text_only` in
##   `<dir>/ai_settings.cfg`, the file the AI session already reads, so the
##   opt-in tick and ceiling saved there are kept on every save.
## - A missing, unreadable or wrongly typed file gives the defaults; a failed
##   save returns false and never throws.

const FILE := "settings.cfg"

var dir := "user://"
const DEFAULT_AUTO_VIEW := true
var auto_view := DEFAULT_AUTO_VIEW
var text_only := false
## R1-SHIP-UI §C4 accessibility (D-57 Q6): "hold" (1.5 s, the default) or "twice" (press,
## then press again). [controls] confirm_mode in settings.cfg; anything else reads "hold".
const CONFIRM_MODES := ["hold", "twice"]
var confirm_mode := "hold"
## R2-CAMERA D6 (motion sensitivity): "full" eases the camera between views; "reduced" cuts with a
## short fade, follows rigidly and turns situation cues into prompts. [display] camera_motion;
## anything else reads "full". Presentation only: no sim input.
const CAMERA_MOTIONS := ["full", "reduced"]
var camera_motion := "full"
## R2-SOUND §D2 (D-101): per-bus volumes 0..100 ([audio] volume_<bus>; SoundMix.SETTABLE), Mute when
## the window is unfocused (on) and Reduced audio (off). Anything out of range or mistyped reads the
## default. Presentation only: no sim input.
const DEFAULT_VOLUME := 100
var volumes := {}
var mute_unfocused := true
var reduced_audio := false


func cfg_path() -> String:
	return dir.path_join(FILE)


func _ai() -> AiSettings:
	var ai := AiSettings.new()
	ai.dir = dir
	ai.load_settings()
	return ai


func load_settings() -> void:
	auto_view = DEFAULT_AUTO_VIEW
	confirm_mode = "hold"
	camera_motion = "full"
	volumes = {}
	mute_unfocused = true
	reduced_audio = false
	var cf := ConfigFile.new()
	if cf.load(cfg_path()) == OK:
		for bus: String in SoundMix.SETTABLE:
			var v: Variant = cf.get_value("audio", "volume_" + bus.to_lower(), DEFAULT_VOLUME)
			if v is int and v >= 0 and v <= 100:
				volumes[bus] = v
		var mu: Variant = cf.get_value("audio", "mute_unfocused", true)
		mute_unfocused = mu if mu is bool else true
		var ra: Variant = cf.get_value("audio", "reduced_audio", false)
		reduced_audio = ra if ra is bool else false
		var v: Variant = cf.get_value("display", "auto_view", DEFAULT_AUTO_VIEW)
		auto_view = v if v is bool else DEFAULT_AUTO_VIEW
		var c: Variant = cf.get_value("controls", "confirm_mode", "hold")
		confirm_mode = c if c is String and c in CONFIRM_MODES else "hold"
		var m: Variant = cf.get_value("display", "camera_motion", "full")
		camera_motion = m if m is String and m in CAMERA_MOTIONS else "full"
	text_only = _ai().text_only


func save_settings() -> bool:
	var cf := ConfigFile.new()
	cf.load(cfg_path()) # keep any other section a later feature adds; a missing file is fine
	cf.set_value("display", "auto_view", auto_view)
	cf.set_value("display", "camera_motion", camera_motion if camera_motion in CAMERA_MOTIONS else "full")
	cf.set_value("controls", "confirm_mode", confirm_mode if confirm_mode in CONFIRM_MODES else "hold")
	for bus: String in SoundMix.SETTABLE:
		cf.set_value("audio", "volume_" + bus.to_lower(), volume(bus))
	cf.set_value("audio", "mute_unfocused", mute_unfocused)
	cf.set_value("audio", "reduced_audio", reduced_audio)
	var ok := cf.save(cfg_path()) == OK
	var ai := _ai()
	ai.text_only = text_only
	return ai.save_settings() and ok


## A bus's volume 0..100 (the default when unset or out of range).
func volume(bus: String) -> int:
	var v: Variant = volumes.get(bus, DEFAULT_VOLUME)
	return v if v is int and v >= 0 and v <= 100 else DEFAULT_VOLUME


func set_volume(bus: String, p: int) -> void:
	if bus in SoundMix.SETTABLE:
		volumes[bus] = clampi(p, 0, 100)


func view_label() -> String:
	return "Auto (bodies faded to fit)" if auto_view else "Realistic (one exposure)"


func confirm_label() -> String:
	return "Press twice" if confirm_mode == "twice" else "Hold (1.5 s)"


func motion_label() -> String:
	return "Reduced (cuts, no camera travel)" if camera_motion == "reduced" else "Full (eased)"
