class_name StapledonTheme
extends RefCounted
## R2-BRIDGE-STYLE S4 (design_docs/planned/r2/bridge-styling-pass.md, D-100): the HUD's one theme, so
## the HUD reads as part of the comic world rather than a debugging overlay. The palette comes from the
## captain sheet and DL2's pigments; the typefaces are Josefin Sans (display) and Nunito (text), both
## SIL OFL, bundled in assets/fonts/ (OQ3); the panel is the hand-drawn ink 9-slice from
## tools/theme_assets.gd (OQ4). Physics overlays keep their functional colours (OQ5).
## ST2 applies it to the status strip and the arrival card; ST4 to every panel (and the project theme).
## Theme types (variations): HUDPanel, HUDCard (PanelContainer); HUDLabel, HUDValue, HUDClock,
## HUDCaption, HUDCardTitle (Label); HUDButton (Button).

# Palette tokens.
const CREAM := Color("#EFE3C8")
const OCHRE := Color("#C98E3A")
const OCHRE_LIGHT := Color("#E3B26B") # captions and titles on the night panel (WCAG 4.5:1)
const VIOLET := Color("#5B4A78")
const TEAL := Color("#3F7F86")
const INK := Color("#211A33")
const NIGHT := Color("#0B0D16")

const DISPLAY_FONT := "res://assets/fonts/JosefinSans-wght.ttf"
const TEXT_FONT := "res://assets/fonts/Nunito-wght.ttf"
const INK_PANEL := "res://ui/theme/ink_panel.png"
const PANEL_ALPHA := 0.86
const CARD_ALPHA := 0.92
const MARGIN := 24 # the 9-slice margins (tools/theme_assets.gd)

static var _theme: Theme


## The shared theme (built once).
static func theme() -> Theme:
	if _theme == null: _theme = build()
	return _theme


static func build() -> Theme:
	var t := Theme.new()
	var text := _font(TEXT_FONT, 500)
	var display := _font(DISPLAY_FONT, 600)
	t.default_font = text
	t.default_font_size = 13
	t.set_stylebox("panel", "HUDPanel", _panel(PANEL_ALPHA))
	t.set_type_variation("HUDPanel", "PanelContainer")
	t.set_stylebox("panel", "HUDCard", _panel(CARD_ALPHA))
	t.set_type_variation("HUDCard", "PanelContainer")
	for ty: String in ["HUDLabel", "HUDValue", "HUDClock", "HUDCaption", "HUDCardTitle"]:
		t.set_type_variation(ty, "Label")
	t.set_color("font_color", "Label", CREAM)
	t.set_color("font_color", "HUDLabel", CREAM)
	t.set_color("font_color", "HUDValue", CREAM)
	t.set_color("font_color", "HUDClock", CREAM)
	t.set_font("font", "HUDClock", _font(TEXT_FONT, 700))
	t.set_color("font_color", "HUDCaption", OCHRE_LIGHT)
	t.set_font("font", "HUDCaption", display)
	t.set_color("font_color", "HUDCardTitle", OCHRE_LIGHT)
	t.set_font("font", "HUDCardTitle", display)
	for ty: String in ["Label", "HUDLabel", "HUDValue", "HUDClock", "HUDCaption", "HUDCardTitle"]:
		t.set_color("font_shadow_color", ty, Color(INK, 0.9))
		t.set_constant("shadow_offset_x", ty, 1)
		t.set_constant("shadow_offset_y", ty, 1)
	t.set_type_variation("HUDButton", "Button")
	t.set_color("font_color", "HUDButton", CREAM)
	t.set_color("font_hover_color", "HUDButton", OCHRE_LIGHT)
	t.set_color("font_color", "Button", CREAM)
	t.set_color("font_hover_color", "Button", OCHRE_LIGHT)
	return t


## The text/panel pairs the contrast check (tools/ui_theme_check.gd, AC7) measures.
static func text_pairs() -> Array:
	var out := []
	for panel: String in ["HUDPanel", "HUDCard"]:
		for ty: String in ["HUDLabel", "HUDValue", "HUDClock", "HUDCaption", "HUDCardTitle", "HUDButton"]:
			out.append({"type": ty, "color": "font_color", "panel_type": panel, "panel_slot": "panel"})
		out.append({"type": "HUDButton", "color": "font_hover_color", "panel_type": panel, "panel_slot": "panel"})
	return out


static var _files := {}


## The bundled TTFs load as dynamic fonts (the project's convention for bundled faces, as the title
## screen's Montserrat; the export filter carries assets/fonts/*).
static func _font(path: String, weight: int) -> Font:
	if not _files.has(path):
		var f := FontFile.new()
		f.load_dynamic_font(path)
		_files[path] = f
	var v := FontVariation.new()
	v.base_font = _files[path]
	v.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): weight}
	return v


## The ink 9-slice in the palette: night fill at `alpha`, the ink outline, the warm inner rule.
static func _panel(alpha: float) -> StyleBoxTexture:
	var src := Image.load_from_file(INK_PANEL) # not imported (the bundled-asset convention): read from the pack
	src.convert(Image.FORMAT_RGBA8)
	var img := Image.create(src.get_width(), src.get_height(), false, Image.FORMAT_RGBA8)
	for y in src.get_height():
		for x in src.get_width():
			var c := src.get_pixel(x, y) # R fill, G ink, B rule
			var col := Color(NIGHT, c.r * alpha)
			col = _over(col, Color(OCHRE, c.b * 0.85))
			col = _over(col, Color(INK, c.g))
			img.set_pixel(x, y, col)
	var sb := StyleBoxTexture.new()
	sb.texture = ImageTexture.create_from_image(img)
	sb.texture_margin_left = MARGIN
	sb.texture_margin_right = MARGIN
	sb.texture_margin_top = MARGIN
	sb.texture_margin_bottom = MARGIN
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 9
	sb.content_margin_bottom = 9
	sb.set_meta("panel_colour", Color(NIGHT, alpha)) # the fill behind text (the contrast check)
	return sb


static func _over(under: Color, top: Color) -> Color:
	var a := top.a + under.a * (1.0 - top.a)
	if a <= 0.0: return Color(0, 0, 0, 0)
	var rgb := (Vector3(top.r, top.g, top.b) * top.a + Vector3(under.r, under.g, under.b) * under.a * (1.0 - top.a)) / a
	return Color(rgb.x, rgb.y, rgb.z, a)
