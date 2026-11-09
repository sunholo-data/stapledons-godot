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
var attention := HBoxContainer.new()
var overview_button: Button
var close_button: Button
var stand_button: Button
var _content := Rect2()
var _waiting_for_seat := false
var _attention_key := ""
var _last_size := Vector2.ZERO
var _last_strip := -1.
var cockpit: ChairCockpit
var screen_host: ChairScreenHost
var _saved_fov := 78.
var _screen_pointer := Vector2.ZERO
var _dragging := false

func _init(host: Node) -> void:
	consoles = host
	name = "CaptainCommand"
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = StapledonTheme.theme()
	frame.theme_type_variation = "HUDSheet"
	add_child(frame)
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	frame.add_child(box)
	# A small navigation rail leaves the ship visible; controls live on physical screens.
	close_button = _button("Look up [Esc]", select_system.bind("overview"))
	box.add_child(close_button)
	overview_button = close_button
	for id: String in ChairCockpit.IDS:
		var b := _button(SYSTEMS[id], select_system.bind(id))
		b.name = id.capitalize() + "Tab"
		system_buttons[id] = b
		box.add_child(b)
	stand_button = _button("Stand up", stand)
	box.add_child(stand_button)
	add_child(attention)
	screen_host = ChairScreenHost.new(self)

func _button(text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE # keyboard/pad selection is routed by the cockpit
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
	if visible: return true
	consoles.cancel_walk()
	var d: Node = consoles.demo
	if cockpit == null:
		cockpit = ChairCockpit.new()
		d.geometry.add_child(cockpit)
		cockpit.setup(CaptainChairContact.measure(d.props_visual))
	cockpit.visible = true
	_saved_fov = d.camera.fov
	visible = true
	screen_host.begin()
	consoles.demo.camera_mode = "console"
	selected = "overview"
	consoles.interaction_origin = "chair"
	layout_for(consoles.demo.ship_hud.size, consoles.demo.ship_hud.strip_bottom())
	select_system("overview")
	refresh()
	get_viewport().gui_release_focus()
	return true

func close() -> void:
	_waiting_for_seat = false
	if not visible: return
	consoles.close_chair_system()
	screen_host.finish()
	cockpit.set_display_texture(selected, null)
	cockpit.visible = false
	visible = false
	consoles.interaction_origin = "station"
	consoles.demo.camera_mode = "player"
	consoles.demo.camera.fov = _saved_fov
	consoles.demo.director.restore()
	consoles.demo._show_interlude()
	if is_inside_tree() and get_viewport().gui_get_focus_owner() != null:
		get_viewport().gui_release_focus()

func stand() -> void:
	close()
	consoles.demo.stand_chair()

func select_system(id: String) -> bool:
	if not visible or not authorized() or not ORDER.has(id): return false
	consoles.close_chair_system()
	screen_host.release_navigation()
	cockpit.set_display_texture(selected, null)
	selected = id
	cockpit.select(id)
	for system: String in system_buttons:
		(system_buttons[system] as Button).theme_type_variation = "HUDSelected" if system == id else ""
	if id != "overview": consoles.open_chair_system(id)
	screen_host.sync_layers()
	if id != "overview": cockpit.set_display_texture(id, screen_host.viewport.get_texture())
	var d: Node = consoles.demo
	d.camera.fov = 92. if id == "overview" else 68.
	d.director.focus_console(cockpit.overview_pose() if id == "overview" else cockpit.focus_pose(id))
	consoles.demo._show_interlude()
	return true

func content_rect() -> Rect2:
	return _content

func layout_for(view: Vector2, strip_bottom: float) -> void:
	_last_size = view
	_last_strip = strip_bottom
	position = Vector2.ZERO
	size = view
	frame.custom_minimum_size = Vector2.ZERO
	frame.reset_size()
	frame.position = Vector2(maxf(8., (view.x - frame.size.x) * .5), view.y - frame.size.y - 12.)
	attention.position = Vector2(ShipHud.MARGIN, strip_bottom + 8.)
	_place_content()

func _place_content() -> void:
	_content = Rect2(Vector2(8., 8.), Vector2(ChairScreenHost.PIXELS) - Vector2(16., 16.))
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
	screen_host.sync_layers()

func refresh() -> void:
	var view: Dictionary = consoles.demo.hud_view()
	if cockpit != null:
		cockpit.set_summaries({"navigation": format("command_course", view.get("journey")), "voyage": format("command_course", view.get("journey")), "crew": format("command_crew", view.get("crew")), "comms": format("command_earth", view.get("earth"))})
	var section: Variant = view.get("crew")
	var crew: Dictionary = section if section is Dictionary else {}
	var needed: Array = crew.get("members", []).filter(func(m): return CrewConsoleModel.needs_you(str(m.get("work_state", "free"))))
	if cockpit != null and not needed.is_empty(): cockpit.set_summaries({"crew": "%d need you" % needed.size()})
	var key := JSON.stringify(needed.map(func(m): return [m.get("id", ""), m.get("work_state", "")]))
	if key == _attention_key and attention.get_child_count() > 0: return
	_attention_key = key
	for c in attention.get_children():
		attention.remove_child(c); c.queue_free()
	if not needed.is_empty():
		var m: Dictionary = needed[0]
		var b := _button("Crew needs you · " + str(m.get("name", m.id)), _open_concern.bind(str(m.id)))
		b.tooltip_text = "%d crew decisions waiting" % needed.size()
		attention.add_child(b)

func _open_concern(actor: String) -> void:
	if select_system("crew") and consoles.crew_console != null:
		consoles.crew_console.press("call:" + actor)

func key(event: InputEvent) -> bool:
	if not visible: return false
	if event is InputEventMouse: return _mouse_input(event)
	if event is InputEventPanGesture or event is InputEventMagnifyGesture:
		screen_host.send(event)
		return true
	var direction := 0
	var typing := screen_host.viewport.gui_get_focus_owner() is LineEdit or screen_host.viewport.gui_get_focus_owner() is TextEdit
	if event is InputEventKey and event.pressed and not event.echo:
		var code: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if code == KEY_TAB and event.ctrl_pressed: direction = -1 if event.shift_pressed else 1
		elif code == KEY_ESCAPE or (code == KEY_E and not typing):
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
	if not typing and consoles.focused == "crew" and consoles.crew_console != null and consoles.crew_console.key(event): return true
	if event is InputEventKey and event.pressed and not event.echo and consoles.demo.crossing_review != null and consoles.demo.crossing_review.visible:
		if consoles.demo.crossing_review.key(event.physical_keycode): return true
	if event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion:
		screen_host.send(event)
		return true
	return false

func _mouse_input(event: InputEventMouse) -> bool:
	var d: Node = consoles.demo
	var px: Vector2 = d.get_viewport().get_stretch_transform() * event.position
	var hit := cockpit.pick_ray(d.camera.project_ray_origin(px), d.camera.project_ray_normal(px))
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and not hit.is_empty() and hit.id != selected:
		select_system(hit.id)
		return true
	if d.director.blending(): return true
	var active: bool = not hit.is_empty() and hit.id == selected
	if not active and not _dragging: return true
	var point: Vector2 = hit.uv * Vector2(screen_host.viewport.size) if active else _screen_pointer
	var local: InputEventMouse = event.duplicate()
	local.position = point
	local.global_position = point
	if local is InputEventMouseMotion: local.relative = point - _screen_pointer
	_screen_pointer = point
	if local is InputEventMouseButton and local.button_index == MOUSE_BUTTON_LEFT: _dragging = local.pressed
	screen_host.send(local)
	return true

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
