class_name GameSettings
extends RefCounted
## Title-screen settings (design_docs/planned/r1/title-screen.md): the ship's
## view (D-38 Realistic / Auto) and text-only AI (D-8).
##
## - The view lives in `<dir>/settings.cfg` ([display] auto_view). Default
##   Realistic (false), the ship's own default.
## - Text-only is NOT duplicated: it is AiSettings' `text_only` in
##   `<dir>/ai_settings.cfg`, the file the AI session already reads, so the
##   opt-in tick and ceiling saved there are kept on every save.
## - A missing, unreadable or wrongly typed file gives the defaults; a failed
##   save returns false and never throws.

const FILE := "settings.cfg"

var dir := "user://"
var auto_view := false
var text_only := false


func cfg_path() -> String:
	return dir.path_join(FILE)


func _ai() -> AiSettings:
	var ai := AiSettings.new()
	ai.dir = dir
	ai.load_settings()
	return ai


func load_settings() -> void:
	auto_view = false
	var cf := ConfigFile.new()
	if cf.load(cfg_path()) == OK:
		var v: Variant = cf.get_value("display", "auto_view", false)
		auto_view = v is bool and v
	text_only = _ai().text_only


func save_settings() -> bool:
	var cf := ConfigFile.new()
	cf.load(cfg_path()) # keep any other section a later feature adds; a missing file is fine
	cf.set_value("display", "auto_view", auto_view)
	var ok := cf.save(cfg_path()) == OK
	var ai := _ai()
	ai.text_only = text_only
	return ai.save_settings() and ok


func view_label() -> String:
	return "Auto (bodies faded to fit)" if auto_view else "Realistic (one exposure)"
