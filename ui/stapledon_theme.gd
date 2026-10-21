class_name StapledonTheme
extends RefCounted
## R2-BRIDGE-STYLE S4 (design_docs/planned/r2/bridge-styling-pass.md, D-100): the HUD's one theme, so
## the HUD reads as part of the comic world rather than a debugging overlay. The palette comes from the
## captain sheet and DL2's pigments; the typefaces are Josefin Sans (display) and Nunito (text), both
## SIL OFL, bundled in assets/fonts/ (OQ3); the panel is the hand-drawn ink 9-slice from
## tools/theme_assets.gd (OQ4). Physics overlays keep their functional colours (OQ5).
## ST2 applies it to the status strip and the arrival card; ST4 to every panel (and the project theme).
## Theme types (variations): HUDPanel, HUDCard, HUDSheet (PanelContainer); the LABELS meanings (Label);
## HUDButton, HUDSelected, HUDFlat (Button). Plain Labels, Buttons, PanelContainers and HSliders take it too.

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
const SHEET_ALPHA := 0.96
const TEAL_LIGHT := Color("#8FD3D6") # the selected or active item
const CORAL := Color("#F2967E") # a warning
const MINT := Color("#A8DDB0") # a confirmation
const DIM := Color("#B9AF98") # hints, secondary lines, disabled
## The text meanings (Label variations) and their colours.
const LABELS := [["HUDLabel", CREAM], ["HUDValue", CREAM], ["HUDClock", CREAM], ["HUDTitle", CREAM],
	["HUDCaption", OCHRE_LIGHT], ["HUDCardTitle", OCHRE_LIGHT], ["HUDHint", DIM], ["HUDAccent", TEAL_LIGHT],
	["HUDWarn", CORAL], ["HUDOk", MINT], ["HUDDisabled", DIM]]
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
	# Panels: every PanelContainer is an ink panel; HUDCard a little denser; HUDSheet (full-screen pages:
	# the codex, credits, news, the crossing review, the legacy screen) nearly opaque.
	t.set_stylebox("panel", "PanelContainer", _panel(PANEL_ALPHA))
	t.set_stylebox("panel", "Panel", _panel(PANEL_ALPHA))
	for v: Array in [["HUDPanel", PANEL_ALPHA], ["HUDCard", CARD_ALPHA], ["HUDSheet", SHEET_ALPHA], ["HUDDialog", 0.97]]:
		t.set_stylebox("panel", v[0], _panel(v[1]))
		t.set_type_variation(v[0], "PanelContainer")
	# The crossing review: its home picture bleeds to the panel's edge through an 18 px margin (PAD).
	t.set_stylebox("panel", "HUDReview", _panel(PANEL_ALPHA, 18))
	t.set_type_variation("HUDReview", "PanelContainer")
	# Progress bars: a track and an ochre fill (the commitment hold); HUDProgress fills coral (the journey).
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(CREAM, 0.22)
	bar_bg.set_corner_radius_all(3)
	t.set_stylebox("background", "ProgressBar", bar_bg)
	var bar_fill := bar_bg.duplicate() as StyleBoxFlat
	bar_fill.bg_color = OCHRE_LIGHT
	t.set_stylebox("fill", "ProgressBar", bar_fill)
	t.set_type_variation("HUDProgress", "ProgressBar")
	var bar_coral := bar_bg.duplicate() as StyleBoxFlat
	bar_coral.bg_color = CORAL
	t.set_stylebox("fill", "HUDProgress", bar_coral)
	# Text: one colour per meaning, never per call site.
	for v: Array in LABELS:
		t.set_type_variation(v[0], "Label")
		t.set_color("font_color", v[0], v[1])
	t.set_color("font_color", "Label", CREAM)
	for ty: String in ["HUDCaption", "HUDCardTitle", "HUDTitle"]:
		t.set_font("font", ty, display)
	t.set_font("font", "HUDClock", _font(TEXT_FONT, 700))
	t.set_font_size("font_size", "HUDTitle", 22)
	# Text straight over the world (no panel): cream with a soft ink outline.
	t.set_type_variation("HUDOverlay", "Label")
	t.set_color("font_color", "HUDOverlay", Color("#FBEFD8"))
	t.set_color("font_outline_color", "HUDOverlay", Color(INK, 0.85))
	t.set_constant("outline_size", "HUDOverlay", 6)
	for ty: String in ["Label"] + LABELS.map(func(v: Array) -> String: return v[0]):
		t.set_color("font_shadow_color", ty, Color(INK, 0.9))
		t.set_constant("shadow_offset_x", ty, 1)
		t.set_constant("shadow_offset_y", ty, 1)
	# Buttons: ink panels (denser on hover and press), an ochre focus ring at least as visible as the old one.
	for ty: String in ["Button", "HUDButton", "HUDSelected"]:
		if ty != "Button": t.set_type_variation(ty, "Button")
		t.set_stylebox("normal", ty, _panel(0.70))
		t.set_stylebox("hover", ty, _panel(0.88))
		t.set_stylebox("pressed", ty, _panel(0.96))
		t.set_stylebox("disabled", ty, _panel(0.55))
		t.set_stylebox("focus", ty, _focus_ring())
		t.set_color("font_color", ty, CREAM if ty != "HUDSelected" else TEAL_LIGHT)
		t.set_color("font_hover_color", ty, OCHRE_LIGHT)
		t.set_color("font_focus_color", ty, CREAM if ty != "HUDSelected" else TEAL_LIGHT)
		t.set_color("font_pressed_color", ty, OCHRE_LIGHT)
		t.set_color("font_disabled_color", ty, DIM)
	# The title menu: a faint panel, the chosen entry a dense one with the focus ring.
	t.set_type_variation("HUDMenu", "Button")
	t.set_stylebox("normal", "HUDMenu", _panel(0.5))
	for slot: String in ["hover", "pressed"]:
		t.set_stylebox(slot, "HUDMenu", _panel(0.92))
	t.set_stylebox("focus", "HUDMenu", _focus_ring())
	t.set_color("font_color", "HUDMenu", CREAM)
	t.set_color("font_hover_color", "HUDMenu", OCHRE_LIGHT)
	t.set_color("font_focus_color", "HUDMenu", OCHRE_LIGHT)
	# A flat button (the view tag, list rows): text only, the focus ring kept.
	t.set_type_variation("HUDFlat", "Button")
	for slot: String in ["normal", "hover", "pressed", "disabled"]:
		t.set_stylebox(slot, "HUDFlat", StyleBoxEmpty.new())
	t.set_stylebox("focus", "HUDFlat", _focus_ring())
	t.set_color("font_color", "HUDFlat", CREAM)
	t.set_color("font_hover_color", "HUDFlat", OCHRE_LIGHT)
	# Sliders: a visible track (the M2.6a eval: the default was too faint) in the palette.
	var track := StyleBoxFlat.new()
	track.bg_color = Color(CREAM, 0.35)
	track.set_corner_radius_all(3)
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	t.set_stylebox("slider", "HSlider", track)
	var fill := track.duplicate() as StyleBoxFlat
	fill.bg_color = OCHRE
	t.set_stylebox("grabber_area", "HSlider", fill)
	t.set_stylebox("grabber_area_highlight", "HSlider", fill)
	return t


## The theme on a whole window: every Control in it takes the palette, the faces and the ink panels
## (R2-BRIDGE-STYLE ST4: the project-wide HUD theme; set by main, the ship demo and the title screen).
static func install(w: Window) -> void:
	if w != null: w.theme = theme()


## The ochre focus ring (2 px, no fill).
static func _focus_ring() -> StyleBoxFlat:
	var f := StyleBoxFlat.new()
	f.draw_center = false
	f.border_color = OCHRE_LIGHT
	f.set_border_width_all(2)
	f.set_corner_radius_all(6)
	return f


## The text/panel pairs the contrast check (tools/ui_theme_check.gd, AC7) measures.
static func text_pairs() -> Array:
	var out := []
	for panel: String in ["HUDPanel", "HUDCard", "HUDSheet"]:
		for v: Array in LABELS:
			out.append({"type": v[0], "color": "font_color", "panel_type": panel, "panel_slot": "panel"})
		for ty: String in ["HUDButton", "HUDSelected", "HUDFlat", "HUDMenu"]:
			for c: String in ["font_color", "font_hover_color"]:
				out.append({"type": ty, "color": c, "panel_type": panel, "panel_slot": "panel"})
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
static func _panel(alpha: float, margin := -1) -> StyleBoxTexture:
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
	sb.content_margin_left = 12 if margin < 0 else margin
	sb.content_margin_right = 12 if margin < 0 else margin
	sb.content_margin_top = 9 if margin < 0 else margin
	sb.content_margin_bottom = 9 if margin < 0 else margin
	sb.set_meta("panel_colour", Color(NIGHT, alpha)) # the fill behind text (the contrast check)
	return sb


static func _over(under: Color, top: Color) -> Color:
	var a := top.a + under.a * (1.0 - top.a)
	if a <= 0.0: return Color(0, 0, 0, 0)
	var rgb := (Vector3(top.r, top.g, top.b) * top.a + Vector3(under.r, under.g, under.b) * under.a * (1.0 - top.a)) / a
	return Color(rgb.x, rgb.y, rgb.z, a)
