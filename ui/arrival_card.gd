class_name ArrivalCard
extends PanelContainer
## The M4.3a arrival card (journey-system part 4): distance, ship years, Earth years and the gap,
## each a DisplayBinding. Visible only once the sim reports the journey arrived.

const ROWS := [
	["Distance", "journey.plan.distance", "%.3f ly"],
	["Ship years", "journey.plan.ship_years", "%.3f yr"],
	["Earth years", "journey.plan.earth_years", "%.3f yr"],
	["Gap", "consequence.gap_years", "%.3f yr"],
]

var bindings: Array = []


func _ready() -> void:
	build()


func build() -> void:
	if not bindings.is_empty():
		return
	visible = false
	# D1: centred in the viewport (the HUD owns the top-left), on an opaque panel so nothing bleeds through.
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.06, 0.09, 0.96)
	style.set_content_margin_all(16)
	add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	add_child(box)
	var title := Label.new()
	title.text = "Arrived"
	box.add_child(title)
	for r in ROWS:
		var line := HBoxContainer.new()
		box.add_child(line)
		var cap := Label.new()
		cap.text = r[0]
		line.add_child(cap)
		var b := DisplayBinding.new().bind(r[1], r[2])
		b.name = "B_" + String(r[1]).replace(".", "_")
		line.add_child(b)
		bindings.append(b)


func show_world(view: Dictionary) -> void:
	build()
	visible = GalaxyMap.field_value(view, "journey.state") == "arrived"
	if visible:
		for b in bindings:
			b.update_from(view)
