class_name LegacyScreen
extends PanelContainer
## M4.4 the Voyage log (D-68; class name kept): the log the sim kept of THIS voyage only (no
## memory survives the crossing), and, once the ship is home, a closing line. Starting over is
## not here: it is the title screen's New game (D-68), out of world. EVERY number is a sim field.
## The closing line is `clock.tau` (ship years) and `clock.t` (Earth years since departure), each
## formatted and nothing more: Godot subtracts nothing.

signal begun(seed: int)

const WIDTH := 640
const FMT := "%.2f"

var copy: Dictionary = NewsCopy.load_json(NewsCopy.COPY)
var closing := ComposedBinding.new()
var entries: Array = [] # the legacy log so far, as the sim appended it
var rows: Array = [] # per entry: its DisplayBindings
var seed_used := -1
## The next seed (a host decision, not the sim's); tests inject one.
var next_seed: Callable = func() -> int: return int(Time.get_unix_time_from_system() * 1000.0) % 2147483647
var _sim: SimBridge = null
var _list := VBoxContainer.new()
var scroll: ScrollContainer = null # the entries; a host fitting the log into less room shortens it
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
	scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(WIDTH - 32, 220)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)
	scroll.add_child(_list)
	closing.compose([labels["legacy_away"], ["clock.tau", FMT], labels["legacy_older"], ["clock.t", FMT], labels["legacy_tail"]])
	closing.name = "Closing"
	closing.add_theme_font_size_override("font_size", 18)
	box.add_child(closing)


func attach(sim: SimBridge) -> void:
	_sim = sim


## Home again: arrived, and the news item is the one at Sol (the sim's star_id, not a client guess).
static func is_home(view: Dictionary) -> bool:
	return GalaxyMap.field_value(view, "journey.state") == "arrived" and GalaxyMap.field_value(view, "consequence.news.star_id") == "Sol"


## Take the sim's world: fold the entries appended since last time, show the screen when home.
func show_world(view: Dictionary, hold_back := false) -> void:
	fold(view)
	closing.visible = is_home(view) # "You were away ..." only once the ship is home
	visible = is_home(view) and not hold_back # hold_back: the news panel is open over it
	if visible:
		closing.update_from(view)


## Fold the entries the sim appended since the last fold; visibility is untouched. The section
## carries only the entries since the previous section, so a host that shows the log later (the
## ship's Archive terminal) feeds every step's world here. A count below ours is a new voyage's log.
func fold(view: Dictionary) -> void:
	build()
	var lg: Variant = GalaxyMap.field_value(view, "consequence.legacy")
	if not lg is Dictionary:
		return
	var n := int(lg.get("count", 0))
	if n < _count:
		_forget()
	if lg.get("appended") is Array and n > _count:
		# the running count says how many of the appended entries are new
		var fresh: Array = lg["appended"]
		for e in fresh.slice(maxi(0, fresh.size() - (n - _count))):
			_add(e)
		_count = n


func _forget() -> void:
	entries = []
	rows = []
	_count = 0
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()


## An entry as the captain reads it (D-67): the kind in words (copy.json log_kinds), an Archive
## entry by its title; the times stay the sim's own fields.
func readable(e: Dictionary) -> Dictionary:
	var out := e.duplicate()
	var kinds: Dictionary = copy.get("log_kinds", {})
	var k := str(e.get("kind", ""))
	out["kind"] = kinds.get(k, k.replace("_", " ").capitalize())
	var place := str(e.get("star_id", ""))
	if place.begins_with("archive."):
		out["star_id"] = str(_lore_titles().get(place, place.trim_prefix("archive.").replace("-", " ").capitalize()))
	return out


static var _titles: Dictionary = {}


static func _lore_titles() -> Dictionary:
	if _titles.is_empty():
		for en: Dictionary in LoreLoader.load_entries().get("entries", []):
			_titles[str(en.get("id", ""))] = str(en.get("title", ""))
	return _titles


func _add(e: Dictionary) -> void:
	entries.append(e)
	var view := {"entry": readable(e)}
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


## A new voyage on the running sim, a new seed; the log forgets the old one. Host-side only
## (out of world, D-68): no in-world control calls it.
func begin_again(sim: SimBridge) -> bool:
	if sim == null:
		return false
	var s: int = next_seed.call()
	if s == sim.last_seed or s == seed_used:
		s += 1
	if not sim.new_game(s, "sol", false, Transit.new_game_params()):
		return false
	seed_used = s
	_forget()
	visible = false
	begun.emit(s)
	return true
