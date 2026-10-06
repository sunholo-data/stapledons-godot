class_name InterludeCard
extends PanelContainer
## The view of a CardInterlude (D-40/D-41): a moment of scale, not a loading
## screen. It shows only what CardInterlude.lines() reads from the simulation,
## and animates the ship and Earth clocks from their values at the cut to their
## values at braking. The cruise sky stays visible around it.

signal continue_pressed

var _title := Label.new()
var _speed := Label.new()
var _distance := Label.new()
var _clocks := Label.new()
var _lived := Label.new()
var _news := Label.new()
var _tier := Label.new()
var _cut := Label.new()
var _button := Button.new()

func _ready() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.03, 0.06, 0.82)
	style.border_color = Color(0.55, 0.65, 0.85, 0.5)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(28)
	add_theme_stylebox_override("panel", style)
	set_anchors_preset(Control.PRESET_CENTER)
	custom_minimum_size = Vector2(620, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	add_child(box)
	for l: Label in [_title, _speed, _distance, _clocks, _lived, _news, _tier, _cut]:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(l)
	_title.add_theme_font_size_override("font_size", 15)
	_title.add_theme_color_override("font_color", Color(0.6, 0.7, 0.9))
	_speed.add_theme_font_size_override("font_size", 30)
	_clocks.add_theme_font_size_override("font_size", 20)
	_tier.add_theme_font_size_override("font_size", 22)
	_tier.add_theme_color_override("font_color", Color(1.0, 0.92, 0.78))
	_cut.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
	_button.text = "Continue"
	_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_button.pressed.connect(func() -> void: continue_pressed.emit())
	box.add_child(_button)

## Refresh from the interlude; t in [0, 1] animates the clocks from the cut to braking.
func show_interlude(card: CardInterlude) -> void:
	var l: Dictionary = card.lines()
	var t := clampf(card.shown() / (CardInterlude.CARD_S * 0.6), 0.0, 1.0)
	t = t * t * (3.0 - 2.0 * t)
	var before: Dictionary = card.facts
	var after: Dictionary = card.latest
	var year := lerpf(float(before.earth_year), float(after.earth_year), t)
	var days := lerpf(0.0, (float(after.ship_tau) - float(before.ship_tau)) * 365.25, t)
	_title.text = l.title
	_speed.text = l.speed
	_distance.text = l.distance
	_clocks.text = "Ship +%.0f days    ·    Earth %.1f years since you left" % [days, year]
	_lived.text = l.lived
	_news.text = l.news
	_tier.text = l.tier
	_tier.modulate.a = t
	_cut.text = l.cut
	position = (get_viewport_rect().size - size) * 0.5
