class_name AiIndicator
extends CanvasLayer
## The AI badge (AI.9; redrawn in R3-AI-PANEL-V2 P2, design ai-panel-v2 §V1): its
## own CanvasLayer, top right. A ring fills as the session spends toward the
## ceiling; a lamp and one word say the state: off, live, thinking, key problem
## or offline, ceiling. The exact amounts (per provider, total, ceiling) are the
## tooltip. Clicking it opens the AI settings panel.
## Costs are the service's own: the `usd` of every usage.ndjson line written
## this session (ok, failed and provisional alike; a result's meta.usd is the
## same number), summed by route by AiBridge.session_usd(), the same total the
## service's ledger starts from when it is relaunched. A `budget` refusal becomes ai_cancel{budget}
## in the relay; the badge says so.

const PANEL := "res://ui/settings/ai_settings.tscn"
## Failed replies in a row before the badge says offline (one blip is not a problem).
const FAIL_LIMIT := 3
## Reply dots the panel shows.
const RECENT := 8
## state -> [lamp colour, the label variation of its word]; colour is never the only
## carrier: every state has its word, the problem lamp is hollow and the ceiling ring full.
const LOOK := {
	"off": [StapledonTheme.DIM, "HUDHint"],
	"live": [StapledonTheme.MINT, "HUDOk"],
	"working": [StapledonTheme.TEAL_LIGHT, "HUDAccent"],
	"problem": [StapledonTheme.CORAL, "HUDWarn"],
	"ceiling": [StapledonTheme.CORAL, "HUDWarn"],
}

var session: AiSession
var usd := {"gemini": 0.0, "openrouter": 0.0}
var budget_hit := false
var fail_streak := 0
## This session's last replies, oldest first, at most RECENT: {req, kind, ok, t}
## (a reply, a refusal or a cancel; not ok means the ship's own line was used).
var recent: Array = []
var button := Button.new()
var ring := Ring.new()
var word := Label.new()
var panel: Control
var _shown := ""


## The spend ring and the lamp, drawn from theme tokens.
class Ring extends Control:
	var fraction := 0.0
	var color := StapledonTheme.DIM
	var hollow := false
	var pulse := 1.0

	func _draw() -> void:
		var c := size / 2.0
		var r := minf(size.x, size.y) / 2.0 - 3.0
		draw_arc(c, r, 0.0, TAU, 48, Color(StapledonTheme.CREAM, 0.22), 3.5, true)
		if fraction > 0.0:
			draw_arc(c, r, -PI / 2.0, -PI / 2.0 + TAU * clampf(fraction, 0.0, 1.0), 48, color, 3.5, true)
		var lamp := Color(color, pulse)
		if hollow:
			draw_arc(c, 4.5, 0.0, TAU, 24, lamp, 2.0, true)
		else:
			draw_circle(c, 5.0, lamp)


## The badge's state from what it knows, in precedence order (design §V1).
static func state_of(live_on: bool, budget: bool, fails: int, rejected_key: bool, pending: int) -> String:
	if not live_on:
		return "off"
	if budget:
		return "ceiling"
	if rejected_key or fails >= FAIL_LIMIT:
		return "problem"
	if pending > 0:
		return "working"
	return "live"


## The one or two words beside "AI".
static func word_of(st: String, rejected_key: bool) -> String:
	match st:
		"working": return "thinking"
		"problem": return "key problem" if rejected_key else "offline"
	return st


## Top right by default; top left where a screen's own panel owns the top right
## (the galaxy map's star panel).
func place_left(left: bool) -> void:
	button.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT if left else Control.PRESET_TOP_RIGHT)
	button.grow_horizontal = Control.GROW_DIRECTION_END if left else Control.GROW_DIRECTION_BEGIN
	button.position += Vector2(12, 12) if left else Vector2(-12, 12)


func _ready() -> void:
	layer = 20
	button.theme = StapledonTheme.theme() # a CanvasLayer does not pass the window's theme down
	button.flat = false
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(176, 44)
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 6
	row.offset_right = -12
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.custom_minimum_size = Vector2(34, 34)
	ring.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ai := Label.new()
	ai.text = "AI"
	ai.theme_type_variation = "HUDCardTitle"
	ai.mouse_filter = Control.MOUSE_FILTER_IGNORE
	word.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c in [ring, ai, word]:
		c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(c)
	button.add_child(row)
	place_left(false)
	button.pressed.connect(toggle_panel)
	add_child(button)
	if session != null:
		session.bridge.outcome.connect(on_outcome)
	refresh()


## The lamp pulses while a reply is on its way; a state change redraws.
func _process(_delta: float) -> void:
	if session == null:
		return
	var st := state()
	if st != _shown:
		refresh()
	var p := 1.0 if st != "working" else 0.55 + 0.45 * absf(sin(Time.get_ticks_msec() / 1000.0 * PI))
	if p != ring.pulse:
		ring.pulse = p
		ring.queue_redraw()


func on_outcome(o: Dictionary) -> void:
	recent.append({"req": str(o.get("req", "")), "kind": str(o.get("kind", "")), "ok": o.get("status") == "ok", "t": Time.get_ticks_msec()})
	if recent.size() > RECENT:
		recent = recent.slice(recent.size() - RECENT)
	var budget: bool = o.get("code") == "budget" or o.get("reason") == "budget"
	if budget:
		budget_hit = true
	if o.get("status") == "ok":
		fail_streak = 0
	elif not budget and (o.get("status") == "error" or o.get("type") == "cancel"):
		fail_streak += 1 # a refusal, a timeout or the service down: the ship's own line was used
	_read_usage()
	refresh()


func total() -> float:
	return usd["gemini"] + usd["openrouter"]


## Spent over the ceiling, 0..1: the ring.
func fraction() -> float:
	var c: float = session.settings.ceiling_usd if session != null else AiSettings.CEILING_DEFAULT
	return clampf(total() / c, 0.0, 1.0) if c > 0.0 else 0.0


## A present key whose check this run said rejected.
func rejected() -> bool:
	if session == null or session.key_check == null:
		return false
	return session.settings.keys_present().any(func(p): return session.key_check.result(p, session.settings) == "rejected")


func state() -> String:
	if session == null:
		return "off"
	return state_of(session.settings.live_on(), budget_hit, fail_streak, rejected(), session.bridge.pending())


## What the badge shows beside its ring: "AI" and the state's word.
func label_text() -> String:
	return "AI " + word_of(state(), rejected())


## The tooltip: the exact amounts (what the badge used to print).
func text() -> String:
	var s := session.settings
	if not s.live_on():
		return "AI: off (templates and the ship's archive)"
	var parts := []
	for p in AiSettings.PROVIDERS:
		if p in s.keys_present() or usd[p] > 0.0:
			parts.append("%s $%.4f" % [AiSettings.LABEL[p].get_slice(" ", 0), usd[p]])
	return "AI live%s · %s · $%.4f of $%.2f%s" % [" (text only)" if s.effective_text_only() else "", " · ".join(parts),
		total(), s.ceiling_usd, " · ceiling reached" if budget_hit else ""]


func refresh() -> void:
	if session == null:
		return
	var st := state()
	_shown = st
	word.text = word_of(st, rejected())
	word.theme_type_variation = LOOK[st][1]
	ring.color = LOOK[st][0]
	ring.hollow = st == "problem"
	ring.fraction = 1.0 if st == "ceiling" else (fraction() if st != "off" else 0.0)
	ring.queue_redraw()
	button.tooltip_text = text() + "\nClick for AI settings"
	if panel != null and panel.visible:
		panel.refresh() # an open panel follows the replies, the spend and the state


func toggle_panel() -> void:
	if panel == null:
		panel = load(PANEL).instantiate()
		panel.session = session
		add_child(panel)
	else:
		panel.visible = not panel.visible
	if panel.visible:
		panel.refresh()


func _read_usage() -> void:
	usd = session.bridge.session_usd()
