extends RefCounted
## ui-theme-check negative control (R2-BRIDGE-STYLE AC7): a text colour too close to its panel.
static func build() -> Theme:
	var t := Theme.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#5B4A78")
	t.set_stylebox("panel", "HUDPanel", sb)
	t.set_color("font_color", "HUDLabel", Color("#6E5C8C"))
	return t
static func text_pairs() -> Array:
	return [{"type": "HUDLabel", "color": "font_color", "panel_type": "HUDPanel", "panel_slot": "panel"}]
