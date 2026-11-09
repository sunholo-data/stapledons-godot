class_name CaptainCommand
extends Control
## D-149: the chair is a physical command origin for the existing station controls.
## This shell owns layout/selection only. ShipConsoles remains the decision dispatcher.
const SYSTEMS := {"navigation": "Navigation", "voyage": "Voyage", "crew": "Crew", "comms": "Comms", "archive": "Archive"}
const ORDER := ["overview", "navigation", "voyage", "crew", "comms", "archive"]
var consoles: Node
var selected := "overview"
var system_buttons := {}
var frame := PanelContainer.new()
var overview := VBoxContainer.new()
var attention := VBoxContainer.new()
var overview_button: Button
var close_button: Button
var stand_button: Button
var _content := Rect2()
var _bindings: Array[DisplayBinding] = []
var _waiting_for_seat := false
var _attention_key := ""
var _last_size := Vector2.ZERO
var _last_strip := -1.

func _init(host: Node) -> void:
	consoles = host
	name = "CaptainCommand"
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = StapledonTheme.theme()
	frame.theme_type_variation = "HUDSheet"
	add_child(frame)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	frame.add_child(box)
	var head := HBoxContainer.new()
	box.add_child(head)
	var title := Label.new()
	title.text = "Captain's chair"
	title.theme_type_variation = "HUDCardTitle"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	close_button = _button("Close [Esc]", close)
	head.add_child(close_button)
	stand_button = _button("Stand up", stand)
	head.add_child(stand_button)
	var tabs := HBoxContainer.new()
	box.add_child(tabs)
	overview_button = _button("Overview", select_system.bind("overview"))
	tabs.add_child(overview_button)
	for id: String in SYSTEMS:
		var b := _button(SYSTEMS[id], select_system.bind(id))
		b.name = id.capitalize() + "Tab"
		system_buttons[id] = b
		tabs.add_child(b)
	var summary := HBoxContainer.new()
	summary.add_theme_constant_override("separation", 16)
	box.add_child(summary)
	for row in [["journey", "command_course"], ["crew", "command_crew"], ["earth", "command_earth"]]:
		var line := DisplayBinding.new().bind(row[0], row[1])
		line.record_context = true
		line.clip_text = true
		line.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.theme_type_variation = "HUDHint"
		line.add_theme_font_size_override("font_size", 12)
		_bindings.append(line)
		summary.add_child(line)
	var body := Control.new()
	body.name = "SystemRoom"
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(body)
	# The actual system panel and embedded helm use the same global content rect.
	frame.resized.connect(_place_content)
	for text in ["Command the ship", "Plot a course, check on the crew, listen to Earth or open the Archive."]:
		var label := Label.new()
		label.text = text
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.theme_type_variation = "HUDCardTitle" if text == "Command the ship" else "HUDHint"
		overview.add_child(label)
	var actions := HFlowContainer.new()
	overview.add_child(actions)
	for row in [["Plot a course", "navigation"], ["Talk to the crew", "crew"], ["Listen to Earth", "comms"], ["Read the Archive", "archive"]]:
		actions.add_child(_button(row[0], select_system.bind(row[1])))
	var heading := Label.new()
	heading.text = "Needs your attention"
	heading.theme_type_variation = "HUDCardTitle"
	overview.add_child(heading)
	overview.add_child(attention)
	add_child(overview)

func _button(text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 14)
	b.pressed.connect(action)
	return b

func authorized() -> bool:
	var d: Node = consoles.demo
	# Seated avatar placement is presentation-only and frozen; no simulation/physics step
	# drifts it. Five centimetres allows float32 rounding while rejecting a stale seat.
	return d.active_level == 0 and d.captain_anim.chair == "seated" and not d._chair_stand and d.avatar_pos.distance_to(d.chair_seat()) < .05

func begin_sit() -> void:
	_waiting_for_seat = true

func open() -> bool:
	if not authorized(): return false
	consoles.cancel_walk()
	visible = true
	consoles.demo.camera_mode = "console"
	selected = "overview"
	consoles.interaction_origin = "chair"
	layout_for(consoles.demo.ship_hud.size, consoles.demo.ship_hud.strip_bottom())
	select_system("overview")
	refresh()
	overview_button.grab_focus()
	return true

func close() -> void:
	_waiting_for_seat = false
	consoles.close_chair_system()
	visible = false
	consoles.interaction_origin = "station"
	consoles.demo.camera_mode = "player"
	consoles.demo._show_interlude()
	if is_inside_tree() and get_viewport().gui_get_focus_owner() != null:
		get_viewport().gui_release_focus()

func stand() -> void:
	close()
	consoles.demo.stand_chair()

func select_system(id: String) -> bool:
	if not visible or not authorized() or not ORDER.has(id): return false
	consoles.close_chair_system()
	selected = id
	overview.visible = id == "overview"
	for system: String in system_buttons:
		(system_buttons[system] as Button).theme_type_variation = "HUDSelected" if system == id else ""
	if id != "overview": consoles.open_chair_system(id)
	consoles.demo._show_interlude()
	return true

func content_rect() -> Rect2:
	return _content

func layout_for(view: Vector2, strip_bottom: float) -> void:
	_last_size = view
	_last_strip = strip_bottom
	position = Vector2.ZERO
	size = view
	frame.position = Vector2(ShipHud.MARGIN, strip_bottom + 8.)
	frame.size = Vector2(maxf(320., view.x - ShipHud.MARGIN * 2.), maxf(160., view.y - frame.position.y - 40.))
	_place_content()

func _place_content() -> void:
	var room := frame.find_child("SystemRoom", true, false) as Control
	if room == null: return
	# Initial layout is also valid before the Container's deferred sort.
	var top := maxf(frame.position.y + 116., room.global_position.y)
	_content = Rect2(Vector2(frame.position.x, top), Vector2(frame.size.x, maxf(100., frame.position.y + frame.size.y - top - 8.)))
	overview.position = _content.position + Vector2(12., 12.)
	overview.size = _content.size - Vector2(24., 24.)
	if visible and consoles.focused != "":
		consoles._layout_panel()
		if consoles.focused == "navigation" and consoles.demo.navigation_window != null:
			consoles.demo._place_navigation(_content.grow(-8.))

func advance() -> void:
	if _waiting_for_seat and authorized():
		_waiting_for_seat = false
		open()
	if not visible: return
	if not authorized():
		close()
		return
	var hud: ShipHud = consoles.demo.ship_hud
	if hud.size != _last_size or hud.strip_bottom() != _last_strip:
		layout_for(hud.size, hud.strip_bottom())
	refresh()

func refresh() -> void:
	var view: Dictionary = consoles.demo.hud_view()
	for b in _bindings:
		b.update_from(view)
		b.tooltip_text = b.text
	var section: Variant = view.get("crew")
	var crew: Dictionary = section if section is Dictionary else {}
	var needed: Array = crew.get("members", []).filter(func(m): return CrewConsoleModel.needs_you(str(m.get("work_state", "free"))))
	var key := JSON.stringify(needed.map(func(m): return [m.get("id", ""), m.get("work_state", "")]))
	if key == _attention_key and attention.get_child_count() > 0: return
	_attention_key = key
	for c in attention.get_children():
		attention.remove_child(c); c.queue_free()
	if needed.is_empty():
		var calm := Label.new(); calm.text = "No crew decisions waiting."
		attention.add_child(calm)
	for m: Dictionary in needed:
		var b := _button(str(m.get("name", m.id)) + " · " + CrewPalette.STATES.get(str(m.get("work_state", "")), {}).get("word", "Needs you"), _open_concern.bind(str(m.id)))
		attention.add_child(b)

func _open_concern(actor: String) -> void:
	if select_system("crew") and consoles.crew_console != null:
		consoles.crew_console.press("call:" + actor)

func key(event: InputEvent) -> bool:
	if not visible: return false
	var direction := 0
	if event is InputEventKey and event.pressed and not event.echo:
		var code: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if code == KEY_TAB and event.ctrl_pressed: direction = -1 if event.shift_pressed else 1
		elif code in [KEY_E, KEY_ESCAPE]:
			consoles.escape()
			return true
	elif event is InputEventJoypadButton and event.pressed:
		if event.button_index == JOY_BUTTON_LEFT_SHOULDER: direction = -1
		elif event.button_index == JOY_BUTTON_RIGHT_SHOULDER: direction = 1
		elif event.button_index == JOY_BUTTON_B:
			consoles.escape()
			return true
	if direction != 0:
		select_system(ORDER[posmod(ORDER.find(selected) + direction, ORDER.size())])
		return true
	return false

static func format(kind: String, raw: Variant) -> String:
	if not raw is Dictionary:
		return {"command_course": "No active course", "command_crew": "No crew aboard", "command_earth": "No Earth link data"}.get(kind, "")
	match kind:
		"command_course":
			var state := str(raw.get("state", "idle"))
			var target := str(raw.get("plan", {}).get("target", {}).get("id", ""))
			return state.capitalize() + (" · " + CommsPanel.port_name(target) if target != "" else "")
		"command_crew":
			var members: Array = raw.get("members", [])
			var working := members.filter(func(m): return str(m.get("work_state", "")) == "working").size()
			return "%s aboard · %s working" % [CrewPage.words(members.size()).capitalize(), CrewPage.words(working)]
		"command_earth":
			return "Receiving Earth" if raw.get("in_beam", false) else "Waiting for Earth's signal"
	return ""
