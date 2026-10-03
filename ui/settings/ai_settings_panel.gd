extends PanelContainer
## Settings → "Live AI (uses your own key)" (AI.9, design (a5)). A view over
## AiSettings: the opt-in tick, one key field per provider (pasted keys are
## saved 0600; an env key is shown as such and never displayed), the kinds
## each key enables, the per-kind price estimate, the one session ceiling and
## text-only. Every change goes through AiSession.settings_changed().

var session: AiSession
var opt_in := CheckBox.new()
var text_only := CheckBox.new()
var ceiling := SpinBox.new()
var info := Label.new()
var key_rows := {}


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
		row.add_child(status)
		row.add_child(edit)
		row.add_child(save)
		box.add_child(row)
		key_rows[p] = {"edit": edit, "status": status}
	opt_in.text = "Use live AI (needs a key)"
	opt_in.toggled.connect(_on_opt_in)
	box.add_child(opt_in)
	text_only.text = "Text only (no voices or new portraits)"
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
	refresh()


func refresh() -> void:
	if session == null or not is_node_ready():
		return
	var s := session.settings
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
	info.text = "About $%.4f a text line, $%.4f a voice line, $%.3f a portrait.\n%s" % [est["text"], est["voice"], est["portrait"],
		("Live now: %s; the rest use the ship's archive." % ", ".join(s.live_kinds())) if s.live_on() else "Live AI is off: lines use templates, portraits the ship's archive."]


func _save_key(p: String, edit: LineEdit) -> void:
	session.settings.save_key(p, edit.text)
	edit.text = ""
	_changed()


func _changed() -> void:
	session.settings_changed()
	if session.indicator != null:
		session.indicator.refresh()
	refresh()


func _on_opt_in(on: bool) -> void:
	session.settings.opt_in = on
	_changed()


func _on_text_only(on: bool) -> void:
	session.settings.text_only = on
	_changed()


func _on_ceiling(v: float) -> void:
	session.settings.set_ceiling(v)
	_changed()
