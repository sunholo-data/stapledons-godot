class_name ChairScreenHost
extends RefCounted
## Reuses the real station controls on one physical display. No gameplay dispatcher.
const PIXELS := Vector2i(1024, 640)
var viewport := SubViewport.new()
var layer := CanvasLayer.new()
var command: Control
var _panel_parent: Node
var _layers := {}

func _init(owner: Control) -> void:
	command = owner
	viewport.name = "ChairScreen"
	viewport.size = PIXELS
	viewport.own_world_3d = true
	viewport.handle_input_locally = true
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	owner.add_child(viewport)
	layer.layer = 14
	viewport.add_child(layer)

func begin() -> void:
	var panel: Control = command.consoles.panel
	_panel_parent = panel.get_parent()
	panel.reparent(layer)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sync_layers()

func sync_layers() -> void:
	var c: Node = command.consoles
	for candidate in [c._reading_layer, c.demo._interlude_canvas, c.demo.codex.get_parent() if c.demo.codex != null else null]:
		if candidate is CanvasLayer and not _layers.has(candidate):
			_layers[candidate] = candidate.get_parent()
			candidate.reparent(viewport)

func host_navigation() -> void:
	var d: Node = command.consoles.demo
	if d.journey_map == null: return
	d.navigation_window.hide()
	if d.journey_map.get_parent() != viewport:
		d.journey_map.reparent(viewport)
	# The map owns a camera in this viewport's separate world.
	d.journey_map.visible = true
	command.consoles.panel.visible = false

func release_navigation() -> void:
	var d: Node = command.consoles.demo
	if d.journey_map != null and d.navigation_window != null and d.journey_map.get_parent() == viewport:
		d.journey_map.reparent(d.navigation_window)

func finish() -> void:
	release_navigation()
	for candidate in _layers:
		if is_instance_valid(candidate) and is_instance_valid(_layers[candidate]): candidate.reparent(_layers[candidate])
	_layers.clear()
	if is_instance_valid(_panel_parent): command.consoles.panel.reparent(_panel_parent)
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	viewport.gui_release_focus()

func send(event: InputEvent) -> void:
	viewport.push_input(event, true)
