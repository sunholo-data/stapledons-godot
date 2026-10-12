class_name Codex
extends Control
## M4.7 the Archive codex (third Archive tab; design m4-first-journey.md "M4.7"): the entries the
## design repo wrote, as in-game physics lore. Locked entries show their title greyed; unlocked ones
## render a Markdown subset in a RichTextLabel; a toast announces each unlock.
## UNLOCKS COME ONLY FROM THE SIM: show_world(world) reads consequence.archive.unlocked and nothing
## else. There is no method that unlocks an entry, so a client bug cannot open one the sim did not.
## The shown body hash-equals the vendored entry (LoreBinding).

signal selected_changed(id: String)

const GREY := 0.4 # alpha of a locked row
const TOAST_S := 4.0
const PANEL_SIZE := Vector2(840, 420)
const PANEL_DROP := 50.0 # px below centre, so the toast above it never covers the panel
const TOAST_W := 700.0

var entries: Array = []
var selected := ""
var toast_log: Array = [] # ids announced, in order (tests read it)
var panel := PanelContainer.new()
var toast_box := VBoxContainer.new()
var _list := VBoxContainer.new()
var _body := RichTextLabel.new()
var _hint := Label.new()
var _rows := {} # id -> Button
var _unlocked: Array = []
var _built := false


func _ready() -> void:
	_build()


func _build() -> void:
	if _built:
		return
	_built = true
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.06, 0.09, 0.96)
	style.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = PANEL_SIZE
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.position.y += PANEL_DROP
	panel.visible = false
	add_child(panel)
	var split := HBoxContainer.new()
	split.add_theme_constant_override("separation", 16)
	panel.add_child(split)
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(300, 0)
	split.add_child(left)
	var head := Label.new()
	head.text = "ARCHIVE: CODEX   (Esc closes)"
	head.add_theme_font_size_override("font_size", 12)
	head.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	head.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(head)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(scroll)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 2)
	scroll.add_child(_list)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	split.add_child(right)
	_hint.add_theme_font_size_override("font_size", 12)
	_hint.add_theme_color_override("font_color", Color(0.65, 0.7, 0.8))
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_hint)
	_body.bbcode_enabled = true
	_body.fit_content = false
	_body.scroll_active = true
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_font_size_override("normal_font_size", 15)
	_body.add_theme_font_size_override("bold_font_size", 15)
	_body.add_theme_font_size_override("italics_font_size", 15)
	right.add_child(_body)
	# the toast stack: top centre, visible whether or not the panel is open
	toast_box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 40)
	toast_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(toast_box)
	_show_placeholder()


## Load the vendored lore. False (and nothing shown) when the manifest check refuses a file.
func load_lore(dir: String = LoreLoader.DIR) -> bool:
	_build()
	var r := LoreLoader.load_entries(dir)
	entries = r["entries"]
	for e: String in r["errors"]:
		push_error("codex: %s" % e)
	for c in _list.get_children():
		c.queue_free()
	_rows.clear()
	for e: Dictionary in entries:
		var b := Button.new()
		b.text = e["title"]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.clip_text = false
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.custom_minimum_size = Vector2(280, 0)
		b.add_theme_font_size_override("font_size", 13)
		b.tooltip_text = LoreLoader.HINT_TEXT.get(e["unlock"], "")
		b.pressed.connect(select.bind(e["id"]))
		_list.add_child(b)
		_rows[e["id"]] = b
	_refresh_rows()
	return r["errors"].is_empty() and not entries.is_empty()


## The sim's state in, the codex out. Only consequence.archive.unlocked matters.
func show_world(world: Dictionary) -> void:
	_build()
	var u: Variant = GalaxyMap.field_value(world, "consequence.archive.unlocked")
	var now: Array = u if u is Array else []
	var fresh: Array = []
	for id in now:
		if not _unlocked.has(id) and _rows.has(id):
			toast_log.append(id)
			fresh.append(_title_of(id))
	if not fresh.is_empty():
		_toast(fresh)
	_unlocked = now.duplicate()
	if selected != "" and not _unlocked.has(selected):
		selected = ""
		_show_placeholder()
	_refresh_rows()


func open() -> void:
	_build()
	panel.visible = true
	if selected == "" and not _unlocked.is_empty():
		select(_unlocked[0])


func close() -> void:
	panel.visible = false


## Open an unlocked entry. False for a locked or unknown one.
func select(id: String) -> bool:
	if not _unlocked.has(id) or not _rows.has(id):
		return false
	var e := _entry(id)
	selected = id
	_refresh_rows()
	_body.text = "[font_size=22][b]%s[/b][/font_size]\n\n%s" % [LoreLoader._inline(e["title"]), LoreLoader.to_bbcode(e["body"])]
	_hint.text = ""
	selected_changed.emit(id)
	return true


func entry_rows() -> Dictionary:
	return _rows


func body_label() -> RichTextLabel:
	return _body


## The Markdown body of the open entry, exactly as rendered ("" when none is open).
func shown_body_source() -> String:
	return _entry(selected).get("body", "") if selected != "" else ""


func binding_ok() -> bool:
	var b := LoreBinding.new()
	b.entry_id = selected
	return selected != "" and b.check(shown_body_source())


func _refresh_rows() -> void:
	for id: String in _rows:
		var b: Button = _rows[id]
		var open_row := _unlocked.has(id)
		b.disabled = not open_row
		b.modulate = Color(1, 1, 1, 1.0 if open_row else GREY)
		b.tooltip_text = LoreLoader.HINT_TEXT.get(_entry(id).get("unlock", ""), "")
		b.add_theme_color_override("font_color", Color(0.55, 0.85, 1.0) if id == selected else Color(0.88, 0.9, 0.95))
	if selected == "":
		_show_placeholder()


func _show_placeholder() -> void:
	if _body == null:
		return
	_body.text = "[color=#9aa3b5]Choose an entry. Greyed entries open as the voyage unlocks them.[/color]"
	_hint.text = "%d of %d entries open" % [_unlocked.size(), entries.size()] if not entries.is_empty() else ""


func _entry(id: String) -> Dictionary:
	for e: Dictionary in entries:
		if e["id"] == id:
			return e
	return {}


func _title_of(id: String) -> String:
	return _entry(id).get("title", id)


## One toast per batch of unlocks (a tick can open several): the titles, on at most two lines.
func _toast(titles: Array) -> void:
	var p := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.08, 0.1, 0.16, 0.95)
	st.set_content_margin_all(8)
	p.add_theme_stylebox_override("panel", st)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := Label.new()
	l.text = "Archive entry open: %s" % titles[0] if titles.size() == 1 else "Archive: %d entries open: %s" % [titles.size(), ", ".join(titles)]
	l.add_theme_font_size_override("font_size", 14)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(TOAST_W, 0)
	p.add_child(l)
	toast_box.add_child(p)
	if is_inside_tree():
		get_tree().create_timer(TOAST_S).timeout.connect(func() -> void:
			if is_instance_valid(p):
				p.queue_free())
