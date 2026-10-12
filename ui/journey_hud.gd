class_name JourneyHud
extends PanelContainer
## The M4.3a transit HUD. Every number is a DisplayBinding on a sim field (or the client's warp
## level); the captions and the brake notice are plain labels with no digits. The two clocks sit
## side by side at the same size (D-12: neither is the real one).

const CLOCK_SIZE := 28
const BRAKE_NOTICE := "Braking. Up is still the way we are travelling."
## [caption, field, format]: the clocks first (one row), then the readouts, one per line.
const CLOCKS := [["Ship", "clock.tau", "%.4f yr"], ["Earth", "clock.t", "%.4f yr"]]
const ROWS := [
	["Gap", "consequence.gap_years", "%.4f yr"],
	["Phase", "ship.phase", "%s"],
	["Speed", "ship.beta", "%.4f c"],
	["Gamma", "ship.gamma", "%.3f"],
	["Distance left", "consequence.distance_remaining", "%.3f ly"],
	["Arrives in", "consequence.earth_years_remaining", "%.3f Earth-yr"],
	["ISM load", "ship.ism.load_w_m2", "sci W/m2"],
	["ISM load", "consequence.load_suns", "%.1f suns"],
	["Drag energy", "ship.ism.drag_energy_j", "sci J"],
	["Drag energy", "consequence.drag_energy_kg", "%.3f kg"],
	["Glow", "ship.ism.glow_w_m2", "onoff"],
	["Warp", "client.warp", "%.3f ship-yr/s"],
]

var bindings: Array = [] # DisplayBinding, clocks first
var tau: DisplayBinding
var earth: DisplayBinding
var notice := Label.new()


func _ready() -> void:
	build()


## Idempotent: a scene built before the first frame (headless tests) calls it by hand.
func build() -> void:
	if not bindings.is_empty():
		return
	var box := VBoxContainer.new()
	add_child(box)
	var clocks := HBoxContainer.new()
	box.add_child(clocks)
	for c in CLOCKS:
		var b := _row(clocks, c, CLOCK_SIZE)
		if c[1] == "clock.tau":
			tau = b
		else:
			earth = b
	for r in ROWS:
		var line := HBoxContainer.new()
		box.add_child(line)
		_row(line, r, 0)
	notice.name = "Notice"
	box.add_child(notice)


func _row(parent: Container, spec: Array, size: int) -> DisplayBinding:
	var cap := Label.new()
	cap.text = spec[0]
	parent.add_child(cap)
	var b := DisplayBinding.new().bind(spec[1], spec[2])
	b.name = "B_" + String(spec[1]).replace(".", "_")
	if size > 0:
		cap.add_theme_font_size_override("font_size", size)
		b.add_theme_font_size_override("font_size", size)
	parent.add_child(b)
	bindings.append(b)
	return b


## Show a view (the sim's world plus {"client": {"warp": level}}).
func show_world(view: Dictionary) -> void:
	build()
	for b in bindings:
		b.update_from(view)
	notice.text = BRAKE_NOTICE if GalaxyMap.field_value(view, "ship.phase") == "braking" else ""
