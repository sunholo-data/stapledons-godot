class_name LegacyScreen
extends PanelContainer
## M4.4 the legacy screen, shown when the ship is home again (arrived at Sol): the legacy log the
## sim kept, a closing line, and "Begin again". EVERY number is a sim field. The closing line is
## `clock.tau` (ship years) and `clock.t` (Earth years since departure), each formatted and nothing
## more: Godot subtracts nothing. "Begin again" is a NEW voyage with a new seed: new_game on the
## running sim, no reload of anything.

signal begun(seed: int)

const WIDTH := 640
const FMT := "%.2f"

var copy: Dictionary = NewsCopy.load_json(NewsCopy.COPY)
var closing := ComposedBinding.new()
var begin_button := Button.new()
var entries: Array = [] # the legacy log so far, as the sim appended it
var rows: Array = [] # per entry: its DisplayBindings
var seed_used := -1
## The next seed (a host decision, not the sim's); tests inject one.
var next_seed: Callable = func() -> int: return int(Time.get_unix_time_from_system() * 1000.0) % 2147483647
var _sim: SimBridge = null
var _list := VBoxContainer.new()
var _built := false
var _count := 0


func _ready() -> void:
	build()


func build() -> void:
	if _built:
		return
	_built = true
	visible = false
	custom_minimum_size = Vector2(WIDTH, 0)
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.06, 0.09, 0.97)
	style.set_content_margin_all(16)
	add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	add_child(box)
	var labels: Dictionary = copy["labels"]
	var title := Label.new()
	title.text = labels["legacy_title"]
	title.add_theme_font_size_override("font_size", 22)
	box.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(WIDTH - 32, 220)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	scroll.add_child(_list)
	closing.compose([labels["legacy_away"], ["clock.tau", FMT], labels["legacy_older"], ["clock.t", FMT], labels["legacy_tail"]])
	closing.name = "Closing"
	closing.add_theme_font_size_override("font_size", 18)
	box.add_child(closing)
	begin_button.text = labels["begin_again"]
	begin_button.name = "BeginAgain"
	begin_button.pressed.connect(func() -> void: begin_again(_sim))
	box.add_child(begin_button)


func attach(sim: SimBridge) -> void:
	_sim = sim


## Home again: arrived, and the news item is the one at Sol (the sim's star_id, not a client guess).
static func is_home(view: Dictionary) -> bool:
	return GalaxyMap.field_value(view, "journey.state") == "arrived" and GalaxyMap.field_value(view, "consequence.news.star_id") == "Sol"


## Take the sim's world: fold the entries appended since last time, show the screen when home.
func show_world(view: Dictionary, hold_back := false) -> void:
	build()
	var lg: Variant = GalaxyMap.field_value(view, "consequence.legacy")
	if lg is Dictionary and lg.get("appended") is Array and int(lg.get("count", 0)) > _count:
		# the section carries the entries since the last section; the running count says how many are new
		var fresh: Array = lg["appended"]
		var take := int(lg["count"]) - _count
		for e in fresh.slice(maxi(0, fresh.size() - take)):
			_add(e)
		_count = int(lg["count"])
	visible = is_home(view) and not hold_back # hold_back: the news panel is open over it
	if visible:
		closing.update_from(view)


func _add(e: Dictionary) -> void:
	entries.append(e)
	var view := {"entry": e}
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 12)
	var row: Array = []
	for spec in [["entry.kind", "%s"], ["entry.star_id", "%s"], ["entry.t", "Earth +" + FMT + " yr"], ["entry.tau", "ship +" + FMT + " yr"]]:
		var b := DisplayBinding.new().bind(spec[0], spec[1])
		b.update_from(view)
		line.add_child(b)
		row.append(b)
	_list.add_child(line)
	rows.append(row)


## "Begin again": a new voyage on the running sim, a new seed. Everything of the old one is forgotten.
func begin_again(sim: SimBridge) -> bool:
	if sim == null:
		return false
	var s: int = next_seed.call()
	if s == sim.last_seed or s == seed_used:
		s += 1
	if not sim.new_game(s, "sol", false, Transit.new_game_params()):
		return false
	seed_used = s
	entries = []
	rows = []
	_count = 0
	for c in _list.get_children():
		c.queue_free()
	visible = false
	begun.emit(s)
	return true
