class_name CommsStation
extends VBoxContainer
## R3-EARTH-LINK EL3b (Mark 2026-10-28, "visual first, words last"): the comms station's panel.
## Earth's feed is the centre, with the twin clocks and the crew's faces (EL3b.4) beside it, and the
## exchange as light (EL3b.5, EarthStrip) under them. The words (EL3's Listen pane and Exchange
## log, CommsPanel) are the last layer, behind Details.

signal pane_requested(pane: String)
## R3-COMMS-V2 D1.3: a stack's weeks wanted (Earth feed frames from..to); the console asks the sim
## (the read-only `earth_weeks` intent) and the answer arrives in the view as earth_weeks.
signal weeks_requested(from: int, to: int)

var feed := EarthFeed.new()
var clocks := EarthClocks.new()
var crew := CrewFaces.new()
var strip := EarthStrip.new()
var history := EarthHistory.new() ## R3-COMMS-V2 CV2: every week received, along ship time
var waterfall := CommsWaterfall.new() ## R3-COMMS-V2 CV3: the signal from home, True, with the Receiver's line
var stack := StackWeeks.new() ## R3-COMMS-V2 D1.3: the weeks inside a selected stack, each selectable
var side := VBoxContainer.new()
var details := Button.new()
var words_box := VBoxContainer.new()
var words := CommsPanel.new()
var pane_buttons := {}


func _init() -> void:
	name = "CommsStation"
	add_theme_constant_override("separation", 8)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 14)
	top.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(top)
	var frame := AspectRatioContainer.new()
	frame.ratio = 16.0 / 9.0
	frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	frame.size_flags_stretch_ratio = 1.6 # R3-COMMS-V2: room for the waterfall beside, the wall below
	frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	frame.add_child(feed)
	top.add_child(frame)
	side.name = "Side"
	side.add_theme_constant_override("separation", 6)
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clocks.ship_dial.custom_minimum_size = Vector2(64, 64) # R3-COMMS-V2 layout: smaller dials, the faces in a row
	clocks.earth_dial.custom_minimum_size = Vector2(64, 64)
	crew.columns = 5
	crew.face_px = 42.0
	strip.custom_minimum_size = Vector2(0, 84)
	side.add_child(clocks)
	side.add_child(waterfall)
	side.add_child(crew)
	top.add_child(side)
	history.feed = feed
	history.week_selected.connect(_on_week)
	add_child(history)
	stack.feed = feed
	stack.week_picked.connect(_on_stack_week)
	add_child(stack)
	add_child(strip)
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
	waterfall.refresh(view, feed.receiver, str(feed.home_sound.get("cue", "")))
	crew.refresh(view)
	if strip.frame >= 0:
		crew.visible = false # a week's light-cone diagram takes the faces' row while it is open
	history.refresh(view)
	stack.refresh(view)
	strip.refresh(view)
	for p: String in pane_buttons:
		(pane_buttons[p] as Button).set_pressed_no_signal(words.pane == p)
	if words_box.visible:
		words.refresh(view)


func advance(dt: float) -> void:
	feed.advance(dt)


## R3-COMMS-V2 CV2: a week selected on the history wall: the feed shows it, and the light strip turns
## to its light-cone diagram (frame mode); -1 returns both to the live feed and the strip.
func _on_week(i: int) -> void:
	feed.pinned = i
	feed.pinned_week = -1
	strip.set_frame(i)
	var rec: Dictionary = history.records[i] if i >= 0 and i < history.records.size() else {}
	var a := int(rec.get("from_frame", 0))
	var b := int(rec.get("to_frame", 0))
	if i >= 0 and b > a: # a stack: ask the sim for its newest weeks (at most 52, D1.3)
		stack.open(i, rec)
		weeks_requested.emit(maxi(a, b - (StackWeeks.CAP - 1)), b)
	else:
		stack.close()
	if i >= 0:
		crew.visible = false
	if i < 0:
		feed.shown_key = "" # the live week again on the next refresh


## D1.3: a week inside the stack chosen: the feed shows it with its own Earth date, the diagram labels it.
func _on_stack_week(j: int) -> void:
	feed.pinned_week = j
	feed.shown_key = ""
	strip.week = j
	strip._place_tags()
	strip.queue_redraw()


## R3-COMMS-V2 D1.3: the weeks of a selected stack, a row of small pictures from the sim's earth_weeks
## answer (each row's own feed and Earth date); selecting one emits week_picked(j). The selected one
## carries its Earth date stamp (a binding). Nothing here is computed: the sim chose and dated the weeks.
class StackWeeks extends Control:
	signal week_picked(j: int)
	const CAP := 52
	const THUMB := Vector2(38, 22)
	var feed: EarthFeed = null
	var record := -1
	var rec: Dictionary = {}
	var rows: Array = []
	var picked := -1
	var view: Dictionary = {}
	var stamp: ComposedBinding = null

	func _init() -> void:
		name = "StackWeeks"
		visible = false
		custom_minimum_size = Vector2(0, 40)
		mouse_filter = Control.MOUSE_FILTER_STOP

	func open(i: int, r: Dictionary) -> void:
		record = i
		rec = r
		picked = -1
		rows = []
		visible = true
		queue_redraw()

	func close() -> void:
		record = -1
		rec = {}
		rows = []
		picked = -1
		visible = false

	func refresh(v: Dictionary) -> void:
		view = v
		rows = []
		if record < 0:
			return
		var ew: Variant = v.get("earth_weeks")
		if ew is Dictionary and int(ew.get("to", -1)) == int(rec.get("to_frame", -2)) and ew.get("weeks") is Array:
			rows = ew.weeks
		if picked >= rows.size():
			picked = -1
		_place_stamp()
		queue_redraw()

	func _cell(j: int) -> Rect2:
		var step := minf(THUMB.x + 3.0, (size.x - 8.0) / maxf(rows.size(), 1.0))
		return Rect2(Vector2(4.0 + j * step, 2.0), Vector2(minf(THUMB.x, step - 1.0), THUMB.y))

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.035, 0.03, 0.06))
		for j in rows.size():
			var c := _cell(j)
			var r: Dictionary = rows[j]
			var t: Texture2D = feed.texture_of(feed.picked_source(r)) if feed != null else EarthFeed.sky_texture(int(r.get("frame", 0)))
			if t != null:
				draw_texture_rect(t, c, false)
			draw_rect(c, StapledonTheme.CORAL if j == picked else Color(StapledonTheme.CREAM, 0.4), false, 2.0 if j == picked else 1.0)

	func _place_stamp() -> void:
		if picked < 0:
			if stamp != null:
				stamp.visible = false
			return
		if stamp == null: # made on first use: never a binding without a field
			stamp = ComposedBinding.new()
			stamp.theme = StapledonTheme.theme()
			stamp.theme_type_variation = "HUDCaption"
			stamp.add_theme_font_size_override("font_size", 10)
			stamp.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(stamp)
		stamp.compose([["earth_weeks.weeks.%d.earth_year" % picked, "comms_clock"]])
		stamp.update_from(view)
		stamp.size = stamp.get_minimum_size()
		var c := _cell(picked)
		stamp.position = Vector2(clampf(c.get_center().x - stamp.size.x * 0.5, 0.0, maxf(size.x - stamp.size.x, 0.0)), c.end.y + 1.0)
		stamp.visible = true

	func pick(j: int) -> void:
		picked = j if j >= 0 and j < rows.size() else -1
		_place_stamp()
		queue_redraw()
		week_picked.emit(picked)

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			for j in rows.size():
				if _cell(j).grow(1.0).has_point(e.position):
					pick(j)
					accept_event()
					return


## EL3b.4: the crew around the console, each at their home feeling (earth.crew: the sim's
## homeFeeling, work strain first), with their name and the feeling in a word. All bindings.
class CrewFaces extends GridContainer:
	const FACE := 64.0
	var face_px := FACE ## the station's compact row (R3-COMMS-V2) sets it smaller

	func _init() -> void:
		name = "CrewFaces"
		columns = 3
		add_theme_constant_override("h_separation", 10)
		add_theme_constant_override("v_separation", 10)

	func refresh(view: Dictionary) -> void:
		var e: Variant = view.get("earth")
		var members: Array = e.get("crew", []) if e is Dictionary and e.get("crew") is Array else []
		visible = not members.is_empty()
		while get_child_count() < members.size():
			var box := VBoxContainer.new()
			box.alignment = BoxContainer.ALIGNMENT_CENTER
			var face := TextureRect.new()
			face.name = "Face"
			face.custom_minimum_size = Vector2(face_px, face_px)
			face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			box.add_child(face)
			for n: String in ["Feeling", "Who"]:
				var b := ComposedBinding.new()
				b.name = n
				b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				b.theme_type_variation = "HUDLabel" if n == "Feeling" else "HUDCaption"
				b.add_theme_font_size_override("font_size", 13 if n == "Feeling" else 11)
				box.add_child(b)
			add_child(box)
		while get_child_count() > members.size():
			var last := get_child(get_child_count() - 1)
			remove_child(last)
			last.free()
		for i in members.size():
			var m: Dictionary = members[i]
			var box := get_child(i)
			(box.get_node("Face") as TextureRect).texture = CrewPage.face(str(m.get("id", "")), str(m.get("feeling", "neutral")))
			var feel := box.get_node("Feeling") as ComposedBinding
			feel.compose([["earth.crew.%d.feeling" % i, "crew_emotion"]])
			feel.update_from(view)
			var who := box.get_node("Who") as ComposedBinding
			who.compose([["earth.crew.%d.name" % i, "text"]])
			who.update_from(view)
