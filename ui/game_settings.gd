class_name GameSettings
extends RefCounted
## Title-screen settings (design_docs/planned/r1/title-screen.md): the ship's
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
	var cf := ConfigFile.new()
	if cf.load(cfg_path()) == OK:
		var v: Variant = cf.get_value("display", "auto_view", DEFAULT_AUTO_VIEW)
		auto_view = v if v is bool else DEFAULT_AUTO_VIEW
		var c: Variant = cf.get_value("controls", "confirm_mode", "hold")
		confirm_mode = c if c is String and c in CONFIRM_MODES else "hold"
	text_only = _ai().text_only


func save_settings() -> bool:
	var cf := ConfigFile.new()
	cf.load(cfg_path()) # keep any other section a later feature adds; a missing file is fine
	cf.set_value("display", "auto_view", auto_view)
	cf.set_value("controls", "confirm_mode", confirm_mode if confirm_mode in CONFIRM_MODES else "hold")
	var ok := cf.save(cfg_path()) == OK
	var ai := _ai()
	ai.text_only = text_only
	return ai.save_settings() and ok


func view_label() -> String:
	return "Auto (bodies faded to fit)" if auto_view else "Realistic (one exposure)"


func confirm_label() -> String:
	return "Press twice" if confirm_mode == "twice" else "Hold (1.5 s)"
