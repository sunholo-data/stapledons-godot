class_name AiIndicator
extends CanvasLayer
## The AI indicator (AI.9, design (a5)): its own CanvasLayer, top right. It
## shows whether live AI is on and the session's running cost per provider and
## in total against the ceiling; clicking it opens the AI settings panel.
## Costs are the service's own: the `usd` of every usage.ndjson line it wrote
## this session (ok and failed calls alike; a result's meta.usd is the same
## number), summed by route. A `budget` refusal becomes ai_cancel{budget}
## in the relay; the indicator says so.

const PANEL := "res://ui/settings/ai_settings.tscn"

var session: AiSession
var usd := {"gemini": 0.0, "openrouter": 0.0}
var budget_hit := false
var button := Button.new()
var panel: Control
var _usage_from := -1


func _ready() -> void:
	layer = 20
	button.flat = false
	button.focus_mode = Control.FOCUS_NONE
	button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	button.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	button.position += Vector2(-12, 12)
	button.pressed.connect(toggle_panel)
	add_child(button)
	if session != null:
		_usage_from = _usage_size()
		session.bridge.outcome.connect(on_outcome)
	refresh()


func on_outcome(o: Dictionary) -> void:
	if o.get("code") == "budget":
		budget_hit = true
	_read_usage()
	refresh()


func total() -> float:
	return usd["gemini"] + usd["openrouter"]


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
	if session != null:
		button.text = text()


func toggle_panel() -> void:
	if panel == null:
		panel = load(PANEL).instantiate()
		panel.session = session
		add_child(panel)
	else:
		panel.visible = not panel.visible
	if panel.visible:
		panel.refresh()


func _usage_path() -> String:
	return ProjectSettings.globalize_path(session.bridge.cache_dir).path_join("usage.ndjson")


func _usage_size() -> int:
	var f := FileAccess.open(_usage_path(), FileAccess.READ)
	return f.get_length() if f != null else 0


func _read_usage() -> void:
	var f := FileAccess.open(_usage_path(), FileAccess.READ)
	if f == null:
		return
	f.seek(maxi(_usage_from, 0))
	usd = {"gemini": 0.0, "openrouter": 0.0}
	for line in f.get_buffer(f.get_length()).get_string_from_utf8().split("\n", false):
		var u = JSON.parse_string(line)
		if u is Dictionary and usd.has(u.get("route")) and (u.get("usd") is float or u.get("usd") is int):
			usd[u["route"]] += float(u["usd"])
