extends PanelContainer
## Settings → Live AI (AI.9; redrawn in R3-AI-PANEL-V2 P3, design ai-panel-v2 §V2,
## mock-up approved by Mark 2026-11-09). A view over AiSettings, visual first:
##   1. the header: the badge's ring, "Live AI", one line of state, the switch (opt-in);
##   2. a card per key: a lamp and word (No key, Saved, Checking…, Working, Key
##      rejected, Offline), four capability tiles (lines, voices, portraits,
##      pictures from home: bright live, dim off, faint never on this key), the
##      key by its last 4, and Test / Add key (Replace) / Remove;
##   3. this session's spend as a bar against the ceiling, the ceiling on a log
##      slider, the prices as chips;
##   4. the last replies as dots (arrived, or failed and the ship's line used);
##   5. Voices & pictures (text-only off), a lock whose tooltip is the warning, Close.
## Pasted keys are saved 0600 and never shown. In a running game every change
## goes through AiSession.settings_changed(). Without a session (the title
## screen's Settings, or aboard before the voyage's AI starts) it edits the
## saved AiSettings directly and keeps its own key checks.

signal closed

const WORDS := {"none": "No key", "no_key": "No key", "saved": "Saved", "checking": "Checking…", "ok": "Working",
	"rejected": "Key rejected", "offline": "Offline"}
const WORD_TYPE := {"none": "HUDHint", "no_key": "HUDHint", "saved": "HUDValue", "checking": "HUDAccent", "ok": "HUDOk",
	"rejected": "HUDWarn", "offline": "HUDWarn"}
const LAMP := {"none": StapledonTheme.DIM, "no_key": StapledonTheme.DIM, "saved": StapledonTheme.CREAM,
	"checking": StapledonTheme.TEAL_LIGHT, "ok": StapledonTheme.MINT, "rejected": StapledonTheme.CORAL, "offline": StapledonTheme.CORAL}
const TILE_NAMES := {"text": "Crew and Archive lines", "voice": "Voices", "portrait": "Portraits", "feed": "Pictures from home"}
## tile state -> [frame colour, icon colour, filled, opacity]
const TILE_LOOK := {"bright": [StapledonTheme.TEAL_LIGHT, StapledonTheme.CREAM, true, 1.0],
	"dim": [StapledonTheme.DIM, StapledonTheme.DIM, false, 1.0], "faint": [StapledonTheme.DIM, StapledonTheme.DIM, false, 0.3]}

var session: AiSession
## The settings to edit when there is no session (set by the opener).
var settings: AiSettings
var opt_in := CheckButton.new()
var text_only := Button.new()
var ceiling := HSlider.new()
var ceiling_value := Label.new()
var spent_value := Label.new()
var spent_of := Label.new()
var spent_bar := ProgressBar.new()
var headline := Label.new()
var header_ring := AiIndicator.Ring.new()
var chips: Array = []
var dots := HBoxContainer.new()
var last_reply := Label.new()
var key_rows := {}
var close_button := Button.new()
var _own_check: AiKeyCheck


class Lamp extends Control:
	var color := StapledonTheme.DIM
	var hollow := false

	func _draw() -> void:
		if hollow:
			draw_arc(size / 2.0, 5.0, 0.0, TAU, 24, color, 2.0, true)
		else:
			draw_circle(size / 2.0, 6.0, color)


func _ready() -> void:
	if theme == null:
		theme = StapledonTheme.theme() # its opener may be a CanvasLayer, which does not pass a theme down
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	add_child(box)
	box.add_child(_header())
	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 12)
	for p in AiSettings.PROVIDERS:
		cards.add_child(_card(p))
	box.add_child(cards)
	box.add_child(_spend())
	box.add_child(HSeparator.new())
	box.add_child(_footer())
	key_check().done.connect(func(_p, _st): refresh())
	refresh()


func _process(_delta: float) -> void:
	if _own_check != null:
		_own_check.poll()
	if visible and session != null and session.indicator != null and not session.indicator.recent.is_empty():
		last_reply.text = _ago(session.indicator.recent[-1]["t"])


# ------------------------------------------------------------------ build

func _header() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	header_ring.custom_minimum_size = Vector2(44, 44)
	header_ring.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(header_ring)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title := Label.new()
	title.text = "Live AI"
	title.theme_type_variation = "HUDTitle"
	headline.theme_type_variation = "HUDHint"
	words.add_child(title)
	words.add_child(headline)
	row.add_child(words)
	opt_in.name = "LiveSwitch"
	opt_in.tooltip_text = "Live AI on or off (needs a key)"
	opt_in.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	opt_in.toggled.connect(_on_opt_in)
	row.add_child(opt_in)
	return row


func _card(p: String) -> Control:
	var card := PanelContainer.new()
	card.theme_type_variation = "HUDCard"
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size.x = 300
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	card.add_child(v)
	var top := HBoxContainer.new()
	var lamp := Lamp.new()
	lamp.custom_minimum_size = Vector2(16, 24)
	var name_label := Label.new()
	name_label.text = AiSettings.LABEL[p].replace("Google AI (Gemini)", "Google Gemini")
	name_label.theme_type_variation = "HUDCardTitle"
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var status := Label.new()
	for c in [lamp, name_label, status]:
		top.add_child(c)
	v.add_child(top)
	var tiles := HBoxContainer.new()
	tiles.add_theme_constant_override("separation", 8)
	var tile_nodes := []
	for kind in AiSettings.TILE_KINDS:
		var g := AiIcons.Glyph.new(kind, Vector2(44, 44))
		g.frame = "tile"
		tiles.add_child(g)
		tile_nodes.append(g)
	v.add_child(tiles)
	var keyrow := HBoxContainer.new()
	keyrow.add_theme_constant_override("separation", 6)
	var masked := Label.new()
	masked.theme_type_variation = "HUDValue"
	masked.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var test := Button.new()
	test.text = "Test"
	test.tooltip_text = "A free check with %s that this key works" % AiSettings.LABEL[p]
	test.pressed.connect(func(): _test(p))
	var add := Button.new()
	add.pressed.connect(func(): _show_edit(p, true))
	var remove := Button.new()
	remove.text = "Remove"
	remove.theme_type_variation = "HUDFlat"
	remove.pressed.connect(func(): _remove(p))
	for c in [masked, test, add, remove]:
		keyrow.add_child(c)
	v.add_child(keyrow)
	var edit_row := HBoxContainer.new()
	var edit := LineEdit.new()
	edit.secret = true
	edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	edit.text_submitted.connect(func(_t): _save_key(p, edit))
	var save := Button.new()
	save.text = "Save"
	save.pressed.connect(func(): _save_key(p, edit))
	var cancel := Button.new()
	cancel.text = "Cancel"
	cancel.theme_type_variation = "HUDFlat"
	cancel.pressed.connect(func(): _show_edit(p, false))
	for c in [edit, save, cancel]:
		edit_row.add_child(c)
	edit_row.visible = false
	v.add_child(edit_row)
	key_rows[p] = {"card": card, "lamp": lamp, "status": status, "tiles": tile_nodes, "masked": masked, "test": test,
		"add": add, "remove": remove, "edit_row": edit_row, "edit": edit, "save": save}
	return card


func _spend() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	var cap := Label.new()
	cap.text = "This session"
	cap.theme_type_variation = "HUDCaption"
	spent_value.theme_type_variation = "HUDCardTitle"
	spent_of.theme_type_variation = "HUDHint"
	for c in [cap, spent_value, spent_of]:
		c.size_flags_vertical = Control.SIZE_SHRINK_END
		top.add_child(c)
	v.add_child(top)
	spent_bar.min_value = 0.0
	spent_bar.max_value = 1.0
	spent_bar.step = 0.0
	spent_bar.show_percentage = false
	spent_bar.custom_minimum_size.y = 12
	v.add_child(spent_bar)
	var crow := HBoxContainer.new()
	crow.add_theme_constant_override("separation", 10)
	var clabel := Label.new()
	clabel.text = "Ceiling"
	clabel.theme_type_variation = "HUDHint"
	ceiling.min_value = 0.0
	ceiling.max_value = 1.0
	ceiling.step = 0.0
	ceiling.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ceiling.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ceiling.tooltip_text = "The most this session may spend over both keys (US$0.05 to $20)"
	ceiling.value_changed.connect(_on_slider)
	ceiling_value.theme_type_variation = "HUDValue"
	ceiling_value.custom_minimum_size.x = 56
	ceiling_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	for c in [clabel, ceiling, ceiling_value]:
		crow.add_child(c)
	v.add_child(crow)
	var chip_row := HFlowContainer.new()
	chip_row.add_theme_constant_override("h_separation", 14)
	for i in 4:
		var c := Label.new()
		c.theme_type_variation = "HUDHint"
		chip_row.add_child(c)
		chips.append(c)
	v.add_child(chip_row)
	return v


func _footer() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var recent := VBoxContainer.new()
	recent.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	last_reply.theme_type_variation = "HUDHint"
	dots.add_theme_constant_override("separation", 6)
	dots.custom_minimum_size.y = 26
	recent.add_child(last_reply)
	recent.add_child(dots)
	row.add_child(recent)
	text_only.toggle_mode = true
	text_only.text = "Voices & pictures"
	text_only.tooltip_text = "Off: text only (no voices, new portraits or pictures from home)"
	text_only.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text_only.toggled.connect(func(on): _on_text_only(not on))
	row.add_child(text_only)
	var lock := Button.new()
	lock.tooltip_text = AiSettings.WARNING
	lock.custom_minimum_size = Vector2(44, 44)
	lock.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var glyph := AiIcons.Glyph.new("lock", Vector2(44, 44))
	glyph.color = StapledonTheme.DIM
	glyph.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glyph.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lock.add_child(glyph)
	row.add_child(lock)
	close_button.name = "Close"
	close_button.text = "Close"
	close_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	close_button.pressed.connect(close)
	row.add_child(close_button)
	return row


# ------------------------------------------------------------------ state

## The settings this panel edits: the session's when there is one, else the opener's.
func current() -> AiSettings:
	return session.settings if session != null else settings


## The session's key checks, or this panel's own (the title screen).
func key_check() -> AiKeyCheck:
	if session != null:
		return session.key_check
	if _own_check == null:
		_own_check = AiKeyCheck.new()
	return _own_check


func card_status(p: String) -> String:
	return key_check().status(p, current())


## Where keyboard focus starts: the switch when it can be used, else the first Add key.
func first_focus() -> Control:
	if not opt_in.disabled:
		return opt_in
	for p in AiSettings.PROVIDERS:
		if key_rows[p]["add"].visible:
			return key_rows[p]["add"]
	return close_button


func close() -> void:
	visible = false
	closed.emit()


func refresh() -> void:
	var s := current()
	if s == null or not is_node_ready():
		return
	var live := s.live_on()
	opt_in.set_pressed_no_signal(s.opt_in)
	opt_in.disabled = s.keys_present().is_empty()
	if live:
		headline.text = "On: the crew, the Archive and home write live with your key"
	elif s.keys_present().is_empty():
		headline.text = "Off: the ship uses its own lines and pictures. Add a key to turn it on"
	else:
		headline.text = "Off: the ship uses its own lines and pictures"
	var st := "live" if live else "off"
	if session != null and session.indicator != null:
		st = session.indicator.state()
	header_ring.color = AiIndicator.LOOK[st][0]
	header_ring.hollow = st in ["problem", "ceiling"]
	header_ring.fraction = session.indicator.fraction() if st != "off" and session != null and session.indicator != null else 0.0
	header_ring.queue_redraw()
	var rich := not s.effective_text_only()
	text_only.set_pressed_no_signal(rich)
	text_only.disabled = s.text_only_flag
	text_only.text = "Voices & pictures on" if rich else "Text only"
	text_only.theme_type_variation = "HUDSelected" if rich else "HUDButton"
	ceiling.set_value_no_signal(AiSettings.ceiling_to_slider(s.ceiling_usd))
	ceiling_value.text = "$%.2f" % s.ceiling_usd
	for p in AiSettings.PROVIDERS:
		_refresh_card(p, s)
	_refresh_spend(s)
	_refresh_dots()


func _refresh_card(p: String, s: AiSettings) -> void:
	var row: Dictionary = key_rows[p]
	var st := card_status(p)
	var has := s.key_source(p) != ""
	row.status.text = WORDS[st]
	row.status.theme_type_variation = WORD_TYPE[st]
	row.lamp.color = LAMP[st]
	row.lamp.hollow = st in ["rejected", "offline"]
	row.lamp.queue_redraw()
	row.masked.text = s.masked_key(p) if has else "no key"
	row.masked.theme_type_variation = "HUDValue" if has else "HUDHint"
	row.test.visible = has and not s.automation
	row.test.disabled = st == "checking"
	row.add.text = "Replace" if has else "Add key"
	row.remove.visible = has and s.key_source(p) == "file"
	row.edit.placeholder_text = "paste a %s key" % AiSettings.LABEL[p].get_slice(" (", 0)
	var tiles := s.tile_states(p)
	for i in AiSettings.TILE_KINDS.size():
		var g: AiIcons.Glyph = row.tiles[i]
		var look: Array = TILE_LOOK[tiles[i]]
		g.frame_color = look[0]
		g.color = look[1]
		g.filled = look[2]
		g.modulate.a = look[3]
		var kind: String = AiSettings.TILE_KINDS[i]
		g.tooltip_text = "%s: %s" % [TILE_NAMES[kind], {"bright": "live now", "dim": "off", "faint": "not with this key"}[tiles[i]]]
		g.queue_redraw()


func _refresh_spend(s: AiSettings) -> void:
	var est := s.estimates()
	var names := {"text": "line", "voice": "voice", "portrait": "portrait", "feed": "picture from home"}
	var i := 0
	for kind in ["text", "voice", "portrait", "feed"]:
		chips[i].text = "%s ≈ %s" % [names[kind], money(est[kind])]
		i += 1
	if session == null or session.indicator == null:
		spent_value.text = ""
		spent_of.text = "No voyage yet: spend shows here during a voyage"
		spent_bar.value = 0.0
		return
	var ind := session.indicator
	spent_value.text = "$%.3f" % ind.total()
	spent_of.text = "of $%.2f ceiling%s" % [s.ceiling_usd, ", reached" if ind.budget_hit else ""]
	spent_bar.value = ind.fraction()
	spent_bar.theme_type_variation = "HUDProgress" if ind.budget_hit else "" # coral at the ceiling, else ochre


func _refresh_dots() -> void:
	for c in dots.get_children():
		dots.remove_child(c)
		c.queue_free()
	var recent: Array = session.indicator.recent if session != null and session.indicator != null else []
	if recent.is_empty():
		last_reply.text = "Replies show here as they arrive" if session != null else ""
		return
	for r in recent:
		var g := AiIcons.Glyph.new("ok" if r["ok"] else "fail", Vector2(26, 26))
		g.frame = "disc"
		g.filled = true
		g.frame_color = StapledonTheme.MINT if r["ok"] else StapledonTheme.CORAL
		g.color = g.frame_color
		g.tooltip_text = "%s: %s" % [TILE_NAMES.get(r["kind"], r["kind"]), "arrived" if r["ok"] else "failed, the ship's own line was used"]
		dots.add_child(g)
	last_reply.text = _ago(recent[-1]["t"])


## A price with enough places to be non-zero when it is (a text line is a
## fraction of a cent): $0.039, $0.0030, $0.00002; free when it is free.
static func money(v: float) -> String:
	if v <= 0.0:
		return "free"
	if v >= 0.01:
		return "$%.3f" % v
	var places := clampi(ceili(-log(v) / log(10.0)) + 1, 4, 8)
	return ("$%." + str(places) + "f") % v


static func _ago(t: int) -> String:
	var s := (Time.get_ticks_msec() - t) / 1000
	var when := "just now" if s < 2 else ("%d s ago" % s if s < 120 else "%d min ago" % (s / 60))
	return "Recent replies · last " + when


# ------------------------------------------------------------------ actions

func _show_edit(p: String, on: bool) -> void:
	var row: Dictionary = key_rows[p]
	row.edit_row.visible = on
	row.edit.text = ""
	if on and row.edit.is_inside_tree():
		row.edit.grab_focus.call_deferred()


func _save_key(p: String, edit: LineEdit) -> void:
	current().save_key(p, edit.text)
	edit.text = ""
	key_rows[p]["edit_row"].visible = false
	key_check().results.erase(p)
	_changed()


func _remove(p: String) -> void:
	current().save_key(p, "")
	key_check().results.erase(p)
	_changed()


func _test(p: String) -> void:
	key_check().start(p, current())
	refresh()


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


## The ceiling in US$ (tests; the slider goes through _on_slider).
func _on_ceiling(v: float) -> void:
	current().set_ceiling(v)
	_changed()


func _on_slider(t: float) -> void:
	_on_ceiling(AiSettings.slider_to_ceiling(t))
