extends PanelContainer
## Settings → "Live AI (uses your own key)" (AI.9, design (a5)). A view over
## AiSettings: the opt-in tick, one key field per provider (pasted keys are
## saved 0600; an env key is shown as such and never displayed), the kinds
## each key enables, the per-kind price estimate, the one session ceiling and
## text-only. In a running game every change goes through
## AiSession.settings_changed(). Without a session (the title screen's
## Settings, or aboard before the voyage's AI starts) it edits the saved
## AiSettings directly, and the next session starts from them.

signal closed

var session: AiSession
## The settings to edit when there is no session (set by the opener).
var settings: AiSettings
var opt_in := CheckBox.new()
var text_only := CheckBox.new()
var ceiling := SpinBox.new()
var info := Label.new()
var key_rows := {}
var close_button := Button.new()


func _ready() -> void:
	var box := VBoxContainer.new()
	add_child(box)
	var title := Label.new()
	title.text = "Live AI (uses your own Google AI and/or OpenRouter key)"
	box.add_child(title)
	var warn := Label.new()
	warn.text = AiSettings.WARNING
	warn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(warn)
	for p in AiSettings.PROVIDERS:
		var row := HBoxContainer.new()
		var edit := LineEdit.new()
		edit.secret = true
		edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var save := Button.new()
		save.text = "Save key"
		save.pressed.connect(func(): _save_key(p, edit))
		var status := Label.new()
		edit.custom_minimum_size.x = 300
		box.add_child(status) # the provider and where its key comes from, then the field: the field gets the width
		row.add_child(edit)
		row.add_child(save)
		box.add_child(row)
		key_rows[p] = {"edit": edit, "status": status, "save": save}
	opt_in.text = "Use live AI (needs a key)"
	opt_in.toggled.connect(_on_opt_in)
	box.add_child(opt_in)
	text_only.text = "Text only (no voices, new portraits or pictures from home)"
	text_only.toggled.connect(_on_text_only)
	box.add_child(text_only)
	var crow := HBoxContainer.new()
	var clabel := Label.new()
	clabel.text = "Session ceiling, both providers (US$)"
	ceiling.min_value = AiSettings.CEILING_MIN
	ceiling.max_value = AiSettings.CEILING_MAX
	ceiling.step = 0.05
	ceiling.value_changed.connect(_on_ceiling)
	crow.add_child(clabel)
	crow.add_child(ceiling)
	box.add_child(crow)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(info)
	close_button.name = "Close"
	close_button.text = "Close"
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	close_button.pressed.connect(close)
	box.add_child(close_button)
	refresh()


## The settings this panel edits: the session's when there is one, else the opener's.
func current() -> AiSettings:
	return session.settings if session != null else settings


func close() -> void:
	visible = false
	closed.emit()


func refresh() -> void:
	var s := current()
	if s == null or not is_node_ready():
		return
	opt_in.set_pressed_no_signal(s.opt_in)
	opt_in.disabled = s.keys_present().is_empty()
	text_only.set_pressed_no_signal(s.effective_text_only())
	text_only.disabled = s.text_only_flag
	ceiling.set_value_no_signal(s.ceiling_usd)
	for p in AiSettings.PROVIDERS:
		var src := s.key_source(p)
		key_rows[p]["status"].text = "%s: %s" % [AiSettings.LABEL[p],
			{"env": "key from %s" % AiSettings.KEY_ENV[p], "file": "key saved", "": "no key"}[src]]
		key_rows[p]["edit"].placeholder_text = "paste a key to save it (enables %s)" % ", ".join(s.kinds_for(p))
	var est := s.estimates()
	info.text = "About $%.4f a text line, $%.4f a voice line, $%.3f a portrait, $%.3f a picture from home.\n%s" % [est["text"], est["voice"], est["portrait"], est["feed"],
		("Live now: %s; the rest use the ship's archive." % ", ".join(s.live_kinds())) if s.live_on() else "Live AI is off: lines use templates, portraits the ship's archive."]


func _save_key(p: String, edit: LineEdit) -> void:
	current().save_key(p, edit.text)
	edit.text = ""
	_changed()


func _changed() -> void:
	if session != null:
		session.settings_changed()
		if session.indicator != null:
			session.indicator.refresh()
	elif settings != null:
		settings.save_settings()
	refresh()


func _on_opt_in(on: bool) -> void:
	current().opt_in = on
	_changed()


func _on_text_only(on: bool) -> void:
	current().text_only = on
	_changed()


func _on_ceiling(v: float) -> void:
	current().set_ceiling(v)
	_changed()
