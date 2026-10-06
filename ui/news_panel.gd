class_name NewsPanel
extends PanelContainer
## M4.4 the news beat: the Archive terminal's news tab (D-14, text only). "Transmission received",
## a header from sim fields, ONE paragraph, and the provenance the sim names in
## consequence.news.body_source (Godot never decides):
##   template  the paragraph from data/news/templates.json, no notice (the designed default, D-8)
##   ai        the accepted text and a small "generated" tag
##   fallback  the template paragraph under the fixed notice, the reason in words from the fixed
##             reason -> phrase table, and an entry in the diagnostics list
## Every number is a DisplayBinding on a sim field; every label that depends on body_source or
## fallback_reason is a CopyBinding, so the display audit covers them.

signal opened
signal diagnostics_added(code: String)

const WIDTH := 640
const REQUEST_ENTITY := "newswire"

var templates: Dictionary = NewsCopy.load_json(NewsCopy.TEMPLATES)
var copy: Dictionary = NewsCopy.load_json(NewsCopy.COPY)
var bindings: Array = [] # every DisplayBinding, for the audit
var header := ComposedBinding.new()
var body := TemplateText.new()
var ai_body := Label.new()
var tag: CopyBinding
var notice: CopyBinding
var reason: CopyBinding
var no_news := Label.new()
var diagnostics: Array = [] # shown lines, oldest first (kept across legs)
var errors: Array = [] # loud problems (an unknown reason code, a missing slot)
var _diag_box := VBoxContainer.new()
var _diag_keys := {} # one entry per news item
var _ai_text := {} # req -> accepted display text, from ai_accepted events
var _asked := {} # news key -> true: one request per item
var _built := false


## A label bound to one sim field through a fixed map (raw value -> copy). The empty string hides it.
## An unknown raw value is an error, never a blank: it shows UNKNOWN and records it.
class CopyBinding extends DisplayBinding:
	var map: Dictionary = {}
	var unknown_fmt := "unknown: %s"
	var errors: Array = []

	func update_from(view: Dictionary) -> void:
		var raw: Variant = GalaxyMap.field_value(view, field)
		_shown = ""
		if raw is String and raw != "":
			if map.has(raw):
				_shown = map[raw]
			else:
				_shown = unknown_fmt % raw
				errors.append("unknown value '%s' for %s" % [raw, field])
				push_error("news: unknown value '%s' for %s" % [raw, field])
		text = _shown
		visible = _shown != ""


## The template paragraph: a DisplayBinding whose text is the template with its slots filled from
## consequence.news.slots (sim numbers, formatted). The audit sees one binding on one field.
class TemplateText extends DisplayBinding:
	var templates: Dictionary = {}
	var failed := false
	var suppressed := false # the sim says `ai`: the accepted text is shown instead

	func update_from(view: Dictionary) -> void:
		var n: Variant = GalaxyMap.field_value(view, field)
		_shown = ""
		failed = false
		if not suppressed and n is Dictionary and n.get("slots") is Dictionary and n.get("template_id") != null:
			_shown = NewsCopy.paragraph(templates, int(n["template_id"]), n["slots"])
			failed = _shown == ""
		text = _shown
		visible = _shown != ""


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
	style.bg_color = Color(0.05, 0.06, 0.09, 0.96)
	style.set_content_margin_all(16)
	add_theme_stylebox_override("panel", style)
	var box := VBoxContainer.new()
	add_child(box)
	var labels: Dictionary = copy["labels"]
	var title := Label.new()
	title.text = labels["title"]
	title.add_theme_font_size_override("font_size", 20)
	box.add_child(title)
	header.compose([labels["header_lead"], ["consequence.news.slots.news_epoch", "+%.2f"], labels["header_mid"],
		["consequence.news.slots.news_age_years", "%.2f"], labels["header_tail"]])
	header.name = "Header"
	_wrap(header)
	box.add_child(header)
	bindings.append(header)
	body.bind("consequence.news", "%s")
	body.templates = templates
	body.name = "Body"
	_wrap(body)
	box.add_child(body)
	bindings.append(body)
	ai_body.name = "AiBody"
	_wrap(ai_body)
	box.add_child(ai_body)
	tag = _copy_label(box, "Tag", "consequence.news.body_source", {"template": "", "ai": labels["ai_tag"], "fallback": ""})
	tag.add_theme_font_size_override("font_size", 11)
	tag.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	notice = _copy_label(box, "Notice", "consequence.news.body_source", {"template": "", "ai": "", "fallback": labels["fallback_notice"]})
	notice.add_theme_color_override("font_color", Color(1.0, 0.8, 0.45))
	var phrases := {}
	for code: String in copy["reasons"]:
		phrases[code] = "%s %s" % [labels["reason_lead"], copy["reasons"][code]]
	reason = _copy_label(box, "Reason", "consequence.news.fallback_reason", phrases)
	var dt := Label.new()
	dt.text = labels["diagnostics_title"]
	dt.add_theme_font_size_override("font_size", 12)
	box.add_child(dt)
	box.add_child(_diag_box)
	_rebuild_diagnostics()
	no_news.text = labels["no_news"]
	box.add_child(no_news)


func _wrap(l: Label) -> void:
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size = Vector2(WIDTH - 32, 0)


func _copy_label(parent: Container, name: String, field: String, map: Dictionary) -> CopyBinding:
	var b := CopyBinding.new()
	b.bind(field, "%s")
	b.map = map
	b.name = name
	_wrap(b)
	parent.add_child(b)
	bindings.append(b)
	return b


func open() -> void:
	build()
	visible = true
	opened.emit()


func close() -> void:
	visible = false


## Forget everything of the last voyage ("Begin again" starts a new one).
func reset() -> void:
	diagnostics = []
	errors = []
	_diag_keys = {}
	_ai_text = {}
	_asked = {}
	if _built:
		_rebuild_diagnostics()


func has_news(view: Dictionary) -> bool:
	return GalaxyMap.field_value(view, "consequence.news") is Dictionary


## Show the sim's world: the header, the paragraph, and the labels the sim's body_source names.
func show_world(view: Dictionary) -> void:
	build()
	var n: Variant = GalaxyMap.field_value(view, "consequence.news")
	var src := ""
	if n is Dictionary:
		src = str(n.get("body_source", ""))
	body.suppressed = src == "ai"
	for b in bindings:
		b.update_from(view)
	# the accepted text replaces the paragraph only when the sim says `ai` (never on the client's say-so)
	ai_body.text = ""
	if src == "ai":
		var t: String = _ai_text.get(str(n.get("ai_request_id", "")), "")
		if t == "":
			errors.append("body_source is ai but no accepted text was seen")
			push_error("news: body_source is ai but no accepted text was seen")
		else:
			ai_body.text = t
	ai_body.visible = ai_body.text != ""
	if src == "fallback":
		_note_fallback(n, view)
	no_news.visible = not (n is Dictionary)
	header.visible = n is Dictionary
	for b in bindings:
		if b is CopyBinding:
			for e in b.errors:
				if not errors.has(e):
					errors.append(e)
			b.errors = []
	if body.failed:
		errors.append("template paragraph failed to fill")


func _note_fallback(n: Dictionary, view: Dictionary) -> void:
	var key := "%s/%s" % [str(n.get("star_id", "")), str(n.get("ai_request_id", ""))]
	if _diag_keys.has(key):
		return
	_diag_keys[key] = true
	var code := str(GalaxyMap.field_value(view, "consequence.news.fallback_reason"))
	var phrase := NewsCopy.reason_phrase(copy, code)
	if phrase == "":
		errors.append("unknown fallback reason code '%s'" % code)
		phrase = "unknown reason"
	diagnostics.append("%s %s (%s)" % [copy["labels"]["diagnostics_entry"], code, phrase])
	_rebuild_diagnostics()
	diagnostics_added.emit(code)


func _rebuild_diagnostics() -> void:
	for c in _diag_box.get_children():
		c.queue_free()
	var lines: Array = diagnostics if not diagnostics.is_empty() else [copy["labels"]["diagnostics_empty"]]
	for t: String in lines:
		var l := Label.new()
		l.text = t
		l.add_theme_font_size_override("font_size", 12)
		_wrap(l)
		_diag_box.add_child(l)


## The sim's events for one tick (SimBridge.last_events): remember accepted text.
func on_events(events: Array) -> void:
	for e in events:
		if e is Dictionary and e.get("k") == "ai_accepted" and e.get("kind") == "text":
			_ai_text[str(e.get("req"))] = str(e.get("text", ""))


## Ask the relay for AI news text once per item, only when the player has AI on and a key for text
## (D-8: with no key nothing is asked and the template stands, no notice). False when nothing was queued.
func request_ai(relay: AiRelay, view: Dictionary) -> bool:
	var n: Variant = GalaxyMap.field_value(view, "consequence.news")
	if relay == null or not n is Dictionary or n.get("ai_request_id") != null or n.get("body_source") != "template":
		return false
	var key := "%s/%s" % [str(n.get("star_id", "")), str(GalaxyMap.field_value(view, "consequence.news_epoch"))]
	if _asked.has(key) or not relay.enabled or relay.mode in ["off", "replay"] or relay.route_for("text") == "":
		return false
	_asked[key] = true
	return relay.open("text", "news", REQUEST_ENTITY)


## What is on screen, as plain strings: the three renderings are snapshot-tested through this.
func snapshot() -> Dictionary:
	return {
		"title": copy["labels"]["title"],
		"header": header.text,
		"body": ai_body.text if ai_body.visible else body.text,
		"tag": tag.text,
		"notice": notice.text,
		"reason": reason.text,
		"diagnostics": diagnostics.duplicate(),
	}
