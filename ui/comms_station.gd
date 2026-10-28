class_name CommsStation
extends VBoxContainer
## R3-EARTH-LINK EL3b (Mark 2026-10-28, "visual first, words last"): the comms station's panel.
## Earth's feed is the centre, with the twin clocks beside it (and the crew's faces, EL3b.4). The
## words (EL3's Listen pane and Exchange log, CommsPanel) are the last layer, behind Details.

signal pane_requested(pane: String)

var feed := EarthFeed.new()
var clocks := EarthClocks.new()
var side := VBoxContainer.new()
var details := Button.new()
var words_box := VBoxContainer.new()
var words := CommsPanel.new()
var pane_buttons := {}


func _init() -> void:
	name = "CommsStation"
	add_theme_constant_override("separation", 10)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 14)
	top.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(top)
	var frame := AspectRatioContainer.new()
	frame.ratio = 16.0 / 9.0
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.size_flags_stretch_ratio = 2.2
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.add_child(feed)
	top.add_child(frame)
	side.name = "Side"
	side.add_theme_constant_override("separation", 12)
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.add_child(clocks)
	top.add_child(side)
	details.name = "CommsDetails"
	details.text = str(EarthFeed.copy().words.details)
	details.toggle_mode = true
	details.focus_mode = Control.FOCUS_NONE
	details.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	details.toggled.connect(func(on: bool) -> void: words_box.visible = on)
	add_child(details)
	words_box.name = "Words"
	words_box.visible = false
	words_box.add_theme_constant_override("separation", 8)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	for p: String in CommsPanel.PANES:
		var b := Button.new()
		b.text = CommsPanel.copy().panes[p]
		b.name = "Comms_" + p
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(func() -> void: pane_requested.emit(p))
		row.add_child(b)
		pane_buttons[p] = b
	words_box.add_child(row)
	words_box.add_child(words)
	add_child(words_box)


## The words layer, open on a pane (the console's listen and log actions).
func show_words(pane: String) -> void:
	words.show_pane(pane)
	details.set_pressed_no_signal(true)
	words_box.visible = true


func refresh(view: Dictionary) -> void:
	feed.refresh(view)
	clocks.refresh(view)
	for p: String in pane_buttons:
		(pane_buttons[p] as Button).set_pressed_no_signal(words.pane == p)
	if words_box.visible:
		words.refresh(view)


func advance(dt: float) -> void:
	feed.advance(dt)
