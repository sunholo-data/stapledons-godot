class_name Credits
extends Control
## In-game attribution (M5.2a, L-tex: Mark 2026-10-03, "the credit must be DISPLAYED").
## A one-line corner hint, "C  credits", and a small panel that C toggles, listing the
## third-party assets the game draws with their licences. Shown on the galaxy map and in
## the sky flight. CC BY 4.0 asks for attribution reasonable to the medium: the panel is
## always one key away, and the planet line is the one data/planets/CREDITS gives
## (tests/test_planets.gd checks they match, so the two never drift apart).

const PLANET_LINE := "Planet textures: Solar System Scope (solarsystemscope.com), CC BY 4.0"
const LINES := [
	PLANET_LINE,
	"Milky Way panorama: NOIRLab noirlab2430b (E. Slawik / NOIRLab / NSF / AURA), CC BY 4.0",
	"Stars: CNS5 (VizieR), Gaia GCNS (ESA/Gaia/DPAC), Hipparcos (ESA)",
	"Godot Engine (MIT) · AILANG and sunholo/relativity, sunholo/celestial (Sunholo)",
	"CC BY 4.0: https://creativecommons.org/licenses/by/4.0/",
]

var hint := Label.new()
var panel := PanelContainer.new()
var body := Label.new()


func _init() -> void: # built at construction, so the text exists before the node enters a tree
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint.text = "C  credits"
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75, 0.7))
	hint.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_KEEP_SIZE, 12)
	hint.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	add_child(hint)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.06, 0.09, 0.88)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", style)
	body.text = "Credits\n\n" + "\n".join(LINES)
	body.add_theme_font_size_override("font_size", 13)
	body.add_theme_color_override("font_color", Color(0.8, 0.84, 0.92))
	panel.add_child(body)
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_KEEP_SIZE, 32)
	panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel.visible = false
	add_child(panel)


func toggle() -> void:
	panel.visible = not panel.visible


## C (no modifiers) toggles the panel; Escape closes it.
func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo or k.is_command_or_control_pressed() or k.alt_pressed:
		return
	if k.keycode == KEY_C or (k.keycode == KEY_ESCAPE and panel.visible):
		if k.keycode == KEY_C:
			toggle()
		else:
			panel.visible = false
		if is_inside_tree():
			get_viewport().set_input_as_handled()
