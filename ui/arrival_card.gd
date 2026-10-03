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
