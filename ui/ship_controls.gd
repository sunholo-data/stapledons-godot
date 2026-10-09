class_name ShipControls
extends RefCounted
## R1-SHIP-UI (D-56) §F: every control of the 3D ship as data. The HUD informs, the bridge
## consoles decide. tests/test_ship_ui.gd holds this table and ship_geometry_demo.gd's
## _unhandled_input to each other in both directions (NT5): every key the demo matches is a
## row here, every "key" row is matched there, no key row has kind "console", and every
## console row names a station action that ShipConsoles.use() accepts.
##
## Kinds: display (instant display / information), pacing (instant real-time pacing that
## changes no outcome, D-57 Q3), camera, move, dev (developer launches only), console
## (a captain decision; at a bridge console only, never a key).

## Keys matched in ship_geometry_demo.gd _unhandled_input ("via": "match"), polled each
## frame ("poll", WASD) or read by another node ("identify": the I card's own handler).
const KEYS := [
	{"key": "KEY_1", "via": "match", "kind": "camera", "group": "Camera", "help": "1 bridge view"},
	{"key": "KEY_2", "via": "match", "kind": "camera", "group": "Camera", "help": "2 overlook"},
	{"key": "KEY_3", "via": "match", "kind": "camera", "group": "Camera", "help": "3 whole ship"},
	{"key": "KEY_4", "via": "match", "kind": "camera", "group": "Camera", "help": "4 reference rim"},
	{"key": "KEY_R", "via": "match", "kind": "camera", "group": "Camera", "help": "R reset to the captain's eye"},
	{"key": "KEY_7", "via": "match", "kind": "camera", "group": "Camera", "help": "7 look forward (up)"},
	{"key": "KEY_8", "via": "match", "kind": "camera", "group": "Camera", "help": "8 look to the side"},
	{"key": "KEY_9", "via": "match", "kind": "camera", "group": "Camera", "help": "9 look aft (down)"},
	{"key": "KEY_V", "via": "match", "kind": "display", "group": "Display", "help": "V Auto / Realistic view"},
	{"key": "KEY_J", "via": "match", "kind": "display", "group": "Display", "help": "J sky brightness"},
	{"key": "KEY_H", "via": "match", "kind": "display", "group": "Display", "help": "H sky only"},
	{"key": "KEY_TAB", "via": "match", "kind": "display", "group": "Display", "help": "Tab details, help and Walk to"},
	{"key": "KEY_ESCAPE", "via": "match", "kind": "display", "group": "Display", "help": "Esc close the top panel or card, else the main menu"},
	{"key": "KEY_ENTER", "via": "match", "kind": "display", "group": "Display", "help": "Enter continue an interlude or dismiss the arrival card"},
	{"key": "KEY_M", "via": "match", "kind": "display", "group": "Display", "help": "M star chart (read only; plot and commit at the navigation station)"},
	{"key": "KEY_I", "via": "identify", "kind": "display", "group": "Display", "help": "hold I and click a star or body: what it is"},
	{"key": "KEY_P", "via": "match", "kind": "pacing", "group": "Pacing", "help": "P pause or resume the guided voyage"},
	{"key": "KEY_N", "via": "match", "kind": "pacing", "group": "Pacing", "help": "N skip a guided-voyage stop's dwell"},
	{"key": "KEY_K", "via": "match", "kind": "pacing", "group": "Pacing", "help": "K skip to the next stage (at Sgr A*: finish the approach)"},
	{"key": "KEY_W", "via": "poll", "kind": "move", "group": "Move", "help": "WASD walk"},
	{"key": "KEY_A", "via": "poll", "kind": "move", "group": "Move", "help": ""},
	{"key": "KEY_S", "via": "poll", "kind": "move", "group": "Move", "help": ""},
	{"key": "KEY_D", "via": "poll", "kind": "move", "group": "Move", "help": ""},
	{"key": "KEY_E", "via": "match", "kind": "move", "group": "Move", "help": "E use the console or lift in reach (the prompt names it)"},
	{"key": "KEY_5", "via": "match", "kind": "dev", "group": "Developer", "help": "5 rest sky snapshot"},
	{"key": "KEY_6", "via": "match", "kind": "dev", "group": "Developer", "help": "6 mid-journey sky snapshot"},
	{"key": "KEY_G", "via": "match", "kind": "dev", "group": "Developer", "help": "G orbit guides"},
	{"key": "KEY_B", "via": "match", "kind": "dev", "group": "Developer", "help": "B benchmark (uploads a public summary)"},
]

## Pointer and gesture controls (instant).
const POINTER := [
	{"input": "option-drag / right-drag", "kind": "camera", "group": "Camera", "help": "Option + drag or right-drag to look"},
	{"input": "scroll / pinch", "kind": "camera", "group": "Camera", "help": "scroll or pinch to zoom"},
	{"input": "click a console", "kind": "move", "group": "Move", "help": "click a console to walk there (E or click uses it in reach)"},
	{"input": "cmd/ctrl +/-/0", "kind": "display", "group": "Display", "help": "UI size"},
]

## Every captain decision: the station that hosts it and the ShipConsoles.use() action.
## "confirm" marks the irreversible ones (hold 1.5 s, or press twice; §C4).
const CONSOLE := [
	{"decision": "plot a course (select a star, Sol, an in-system body)", "station": "navigation", "action": "select", "confirm": false},
	{"decision": "set cruise speed", "station": "navigation", "action": "speed", "confirm": false},
	{"decision": "commit the plotted course", "station": "navigation", "action": "commit", "confirm": true},
	{"decision": "cancel the plan", "station": "navigation", "action": "cancel", "confirm": false},
	{"decision": "Return to Sol", "station": "navigation", "action": "home", "confirm": false},
	{"decision": "visit Sgr A* (black hole demo)", "station": "navigation", "action": "sgr_a", "confirm": false},
	{"decision": "approach the next Sgr A* stop", "station": "navigation", "action": "approach", "confirm": true},
	{"decision": "leave Sgr A*", "station": "navigation", "action": "leave", "confirm": true},
	{"decision": "begin the guided voyage", "station": "voyage", "action": "begin", "confirm": true},
	{"decision": "open the Archive", "station": "archive", "action": "open", "confirm": false},
]

const GROUP_ORDER := ["Move", "Camera", "Display", "Pacing", "Developer"]


## The key rows the demo's _unhandled_input must match (NT5).
static func matched_keys() -> PackedStringArray:
	var out := PackedStringArray()
	for r: Dictionary in KEYS:
		if r.via == "match":
			out.append(r.key)
	return out


static func row(key: String) -> Dictionary:
	for r: Dictionary in KEYS:
		if r.key == key:
			return r
	return {}


## Help text grouped as §F (developer rows only when `dev`).
static func help_text(dev: bool) -> String:
	var lines := PackedStringArray()
	for g: String in GROUP_ORDER:
		if g == "Developer" and not dev:
			continue
		var items := PackedStringArray()
		for r: Dictionary in KEYS + POINTER:
			if r.group == g and not str(r.help).is_empty():
				items.append(r.help)
		if not items.is_empty():
			lines.append("%s: %s" % [g, " · ".join(items)])
	lines.append("Decisions: at the bridge consoles (navigation station, Voyage console, Archive terminal). Tab · Walk to.")
	return "\n".join(lines)
