class_name CrossingReview
extends PanelContainer
## R2-INTERLUDE I3 (design interlude-card.md D2): the crossing review, "what happened while you were
## away". It replaces the old 6 s interlude card. The player turns the pages; no timer ever turns
## or dismisses one (G1). The only dismissal is the last page's "Brake for <target>" (brake_pressed).
##   pages   crossing, home, aboard, one per moment (3-7), who changed, the medium, waiting for you;
##           a page with nothing to say is left out. While a crew hold is open the Hold page comes
##           first (who, the sim's hold words, their face, Resume with a confirming press ->
##           crew_resume on `intents`, or the Crew console); the crossing so far is behind it.
##           Between chunks (no hold, not over) it is the progress view (D-76).
##   paging  Next / Back, the arrow keys, Enter (Next; on the last page, Brake), the page dots.
## Every number is a DisplayBinding / ComposedBinding over a sim field of the view it is shown with
## (the HUD view: the sim's world, with cruise.digest, plus `review.leg`); Godot formats and never
## computes. Crew words are the sim's (templateLine, holdLine) or accepted AI words (ai_text), and
## faces follow the sim's emotion through CrewPage's fallback list.

signal brake_pressed
signal open_crew
signal intents(list: Array)

const D := "cruise.digest."
const HOME_DIR := "res://data/interlude/home" ## tier<n>.png per time.tier (Rulings §2): 1536x1024 (3:2), the left third calm for the text
const TITLES := {"hold": "Needs you", "crossing": "The crossing", "home": "Home", "aboard": "Aboard",
	"moment": "A moment from the crossing", "changed": "Who changed", "medium": "The medium", "waiting": "Waiting for you"}
## What auto-run did, by the sim's moment kind.
const KIND_WORDS := {
	"hold": "Auto-run stopped the crossing and waited for you.",
	"refusal": "They refused. Auto-run let it stand and moved on.",
	"relief": "They asked to step back. Auto-run decided for you.",
	"concern": "They raised a concern before taking the work on.",
	"accept": "They took the work on.",
	"reply": "Auto-run answered for you.",
}
const INDICATORS := ["stress", "fatigue", "morale", "trust"]
const MOVERS := 3 ## who changed: the top movers shown
const WIDTH := 640.0 ## the panel's width (canvas units) when there is room
const ASPECT := 1.5 ## width / height on every page: the home picture's 3:2, so it covers the panel uncropped; the buttons stay put
const PAD := 18 ## the panel's content margin (the home picture bleeds through it to the panel's edge)
const HOME_TEXT := 0.42 ## the home page's text column: this share of the width, over the picture's calm left side
const WARM := Color(1.0, 0.92, 0.78)
const DIM := Color(0.62, 0.68, 0.8)
const TEXT := Color(0.88, 0.91, 0.98)
const LOW := Color(0.95, 0.6, 0.4)

var ai_text: Dictionary = {} ## ai_req -> accepted AI words (the Crew page's)
var narration: ArchiveNarration = null ## I4: the Archive's telling, when live AI told one (else the sim's authored lines)
var home_dir := HOME_DIR ## where tier<n>.png are read (a test points it at a missing dir: the fallback)
var page := 0
var crossed := false
var armed := false
var _ids: Array = []
var _pages: Array = [] ## Control per id
var _spec := ""
var _view: Dictionary = {}
var _box := VBoxContainer.new()
var _title := Label.new()
var _leg := DisplayBinding.new()
var _scroll := ScrollContainer.new()
var _holder := VBoxContainer.new()
var _dots := HBoxContainer.new()
var _nav := HBoxContainer.new()
var _home_missing := false
var _backdrop := Control.new() ## the home picture, full bleed behind the page, with its scrims
var _home_art := TextureRect.new()
static var _roles: Dictionary = {}
static var _art_cache: Dictionary = {} ## path -> Texture2D (a 1536x1024 PNG is read once)


func _init() -> void:
	name = "CrossingReview"
	add_theme_stylebox_override("panel", _style())
	custom_minimum_size = Vector2(600, 0)
	_build_backdrop()
	_box.add_theme_constant_override("separation", 6)
	add_child(_box)
	var head := HBoxContainer.new()
	_title.name = "PageTitle"
	_title.add_theme_font_size_override("font_size", 13)
	_title.add_theme_color_override("font_color", Color(0.6, 0.7, 0.9))
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_title)
	_leg.name = "Leg"
	_leg.bind("review.leg", "text")
	_leg.add_theme_font_size_override("font_size", 13)
	_leg.add_theme_color_override("font_color", Color(0.6, 0.7, 0.9))
	head.add_child(_leg)
	_box.add_child(head)
	_box.add_child(HSeparator.new())
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_holder)
	_box.add_child(_scroll)
	_dots.name = "Dots"
	_dots.alignment = BoxContainer.ALIGNMENT_CENTER
	_box.add_child(_dots)
	_nav.name = "Nav"
	_nav.add_theme_constant_override("separation", 10)
	_box.add_child(_nav)
	if _roles.is_empty():
		_roles = CrewPage.load_roles(CrewPage.CAST_DIR)


## The Home page's picture fills the whole panel (a 3:2 cover behind the title, the page and the
## buttons). Scrims keep the words readable: a dark gradient over the calm left side (where the text
## sits), and soft bands under the title row and the page buttons. Hidden on every other page.
func _build_backdrop() -> void:
	_backdrop.name = "HomeBackdrop"
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_backdrop.visible = false
	add_child(_backdrop)
	_home_art.name = "HomeImage"
	_home_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_home_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bleed(_home_art)
	_backdrop.add_child(_home_art)
	# [name, from, to, stops (offset, alpha)]: left to right over the text column; top and bottom bands.
	for sc: Array in [["ScrimLeft", Vector2(0, 0), Vector2(1, 0), [[0.0, 0.86], [HOME_TEXT, 0.72], [HOME_TEXT + 0.2, 0.0]]],
			["ScrimTop", Vector2(0, 0), Vector2(0, 1), [[0.0, 0.8], [0.1, 0.6], [0.2, 0.0]]],
			["ScrimBottom", Vector2(0, 1), Vector2(0, 0), [[0.0, 0.8], [0.12, 0.55], [0.24, 0.0]]]]:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array(sc[3].map(func(st): return st[0]))
		g.colors = PackedColorArray(sc[3].map(func(st): return Color(0.01, 0.015, 0.035, st[1])))
		var gt := GradientTexture2D.new()
		gt.gradient = g
		gt.fill_from = sc[1]
		gt.fill_to = sc[2]
		gt.width = 256
		gt.height = 256
		var r := TextureRect.new()
		r.name = sc[0]
		r.texture = gt
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.stretch_mode = TextureRect.STRETCH_SCALE
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_bleed(r)
		_backdrop.add_child(r)


## Fill the backdrop and the panel's content margin around it (the panel's edge).
func _bleed(c: Control) -> void:
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.offset_left = -PAD
	c.offset_top = -PAD
	c.offset_right = PAD
	c.offset_bottom = PAD


## The tier's home picture, or null when the file is missing (the page falls back to words only).
static func home_texture(path: String) -> Texture2D:
	if not _art_cache.has(path):
		_art_cache[path] = CaptainAvatar.make_texture(path) if FileAccess.file_exists(path) or ResourceLoader.exists(path) else null
	return _art_cache[path]


static func _style() -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.02, 0.03, 0.06, 0.86)
	st.border_color = Color(0.55, 0.65, 0.85, 0.5)
	st.set_border_width_all(1)
	st.set_corner_radius_all(6)
	st.set_content_margin_all(PAD)
	return st


## Show the crossing as the view has it. `over`: the braking boundary is reached (the last page can
## brake). Pages are rebuilt only when what they say changes; the numbers refresh every call.
func show_review(view: Dictionary, over: bool) -> void:
	_view = view
	var was_held := _ids.has("hold")
	crossed = over
	var spec := JSON.stringify([page_spec(view, over), _words_spec(view)])
	if spec != _spec:
		var current_id := current()
		_spec = spec
		_build(view)
		if _ids.has("hold") and not was_held:
			page = 0
		elif _ids.has(current_id):
			page = _ids.find(current_id)
		page = clampi(page, 0, _ids.size() - 1)
		_show_page()
	refresh(view)


## Update every number from a view (the same view the HUD shows this frame).
func refresh(view: Dictionary) -> void:
	_view = view
	for b in find_children("*", "DisplayBinding", true, false):
		(b as DisplayBinding).update_from(view)


## The pages this view has, in order (the design's D2 table; empty pages omitted).
static func page_spec(view: Dictionary, over: bool) -> Array:
	var d: Variant = GalaxyMap.field_value(view, "cruise.digest")
	var holds: Array = GalaxyMap.field_value(view, "crew.holds") if GalaxyMap.field_value(view, "crew.holds") is Array else []
	var held := not holds.is_empty()
	if not d is Dictionary or (not over and not held):
		return ["crossing"]
	var ids: Array = ["hold"] if held else []
	ids.append_array(["crossing", "home"])
	var crew: Variant = d.get("crew")
	if crew is Dictionary:
		ids.append("aboard")
		for i in (crew.get("moments", []) as Array).size():
			ids.append("moment_%d" % i)
		if (crew.get("movement", []) as Array).any(func(m): return float(m.get("moved", 0.0)) > 0.0):
			ids.append("changed")
	var medium: Variant = d.get("medium")
	if medium is Dictionary and medium.get("model") == "lism-1" and not (medium.get("media", []) as Array).is_empty():
		ids.append("medium")
	if crew is Dictionary and not (crew.get("waiting", []) as Array).is_empty():
		ids.append("waiting")
	return ids


## The words and faces the pages show (a change rebuilds them; numbers only refresh).
func _words_spec(view: Dictionary) -> Array:
	var crew: Variant = GalaxyMap.field_value(view, "cruise.digest.crew")
	var out: Array = [crossed, GalaxyMap.field_value(view, "crew.holds"), GalaxyMap.field_value(view, "consequence.news.template_id"), ai_text.size(),
		GalaxyMap.field_value(view, "cruise.stop_kind"), GalaxyMap.field_value(view, "cruise.digest.time.tier"), _archive_crossing(view),
		GalaxyMap.field_value(view, "cruise.digest.narration.aboard")]
	if crew is Dictionary:
		out.append((crew.get("moments", []) as Array).map(func(m): return [m.get("actor"), m.get("emotion"), m.get("kind"), m.get("text"), m.get("ai_req")]))
		out.append((crew.get("movement", []) as Array).map(func(m): return [m.get("id"), m.get("emotion0"), m.get("emotion1"), INDICATORS.filter(func(k): return float(m.get("d_" + k, 0.0)) != 0.0)]))
		out.append((crew.get("waiting", []) as Array).map(func(w): return [w.get("kind"), w.get("actor")]))
		var c: Dictionary = crew.get("counts", {})
		out.append(c.keys().filter(func(k): return float(c[k]) > 0.0))
	return out


func page_ids() -> Array:
	return _ids.duplicate()


func current() -> String:
	return str(_ids[page]) if page >= 0 and page < _ids.size() else ""


## True when the Home page's tier picture is missing (words only; the capture fails on it).
func home_art_missing() -> bool:
	return _home_missing


## True when the Home page is shown over its picture.
func home_art_shown() -> bool:
	return _backdrop.visible


func go(i: int) -> void:
	page = clampi(i, 0, maxi(0, _ids.size() - 1))
	_show_page()


func next() -> void:
	go(page + 1)


func back() -> void:
	go(page - 1)


func last_page() -> bool:
	return page >= _ids.size() - 1


## Enter: the next page; on the last page of a finished crossing, Brake.
func enter() -> void:
	if not last_page():
		next()
	elif crossed:
		brake_pressed.emit()


## A key while the review is shown: arrows page, Enter enters. True when it was the review's.
func key(code: int) -> bool:
	match code:
		KEY_RIGHT:
			next(); return true
		KEY_LEFT:
			back(); return true
		KEY_ENTER, KEY_KP_ENTER:
			enter(); return true
	return false


## Resume on the Hold page: the first press arms it, the second queues crew_resume (no twitch, NT1).
func press_resume() -> Array:
	var holds: Variant = GalaxyMap.field_value(_view, "crew.holds")
	if not holds is Array or holds.is_empty():
		return []
	if not armed:
		armed = true
		_resume_text()
		return []
	armed = false
	_resume_text()
	var list := [SimBridge.crew_intent("crew_resume", {"command": "resume", "hold": str(holds[0].get("id", ""))})]
	intents.emit(list)
	return list


func _resume_text() -> void:
	var b: Button = find_child("Resume", true, false)
	if b != null:
		b.text = "Confirm: resume the crossing" if armed else "Resume the crossing"


# ---------------------------------------------------------------- building

func _build(view: Dictionary) -> void:
	for c in _holder.get_children():
		_holder.remove_child(c)
		c.queue_free()
	_ids = page_spec(view, crossed)
	_pages = []
	armed = false
	for id: String in _ids:
		var p := _page(id, view)
		p.name = "Page_" + id
		p.visible = false
		_holder.add_child(p)
		_pages.append(p)


func _show_page() -> void:
	for i in _pages.size():
		(_pages[i] as Control).visible = i == page
	var id := current()
	_backdrop.visible = id == "home" and _home_art.texture != null
	_title.text = str(TITLES.get(id.get_slice("_", 0) if id.begins_with("moment") else id, ""))
	for c in _dots.get_children():
		_dots.remove_child(c)
		c.queue_free()
	if _ids.size() > 1:
		for i in _ids.size():
			var dot := Button.new()
			dot.name = "Dot_%d" % i
			dot.flat = true
			dot.focus_mode = Control.FOCUS_NONE
			dot.text = "●" if i == page else "○"
			dot.tooltip_text = str(TITLES.get(str(_ids[i]).get_slice("_", 0) if str(_ids[i]).begins_with("moment") else _ids[i], ""))
			dot.add_theme_font_size_override("font_size", 11)
			dot.pressed.connect(go.bind(i))
			_dots.add_child(dot)
	for c in _nav.get_children():
		_nav.remove_child(c)
		c.queue_free()
	if _ids.size() > 1:
		var back_b := _button("Back", "Back", back)
		back_b.disabled = page == 0
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_nav.add_child(spacer)
	if not last_page():
		_button("Next", "Next", next)
	elif crossed:
		_button("Brake", "Brake for %s" % str(GalaxyMap.field_value(_view, "review.target")), func() -> void: brake_pressed.emit())
	_scroll.scroll_vertical = 0


func _button(node_name: String, text: String, action: Callable, parent: Node = null) -> Button:
	var b := Button.new()
	b.name = node_name
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 14)
	b.pressed.connect(action)
	(parent if parent != null else _nav).add_child(b)
	return b


func _page(id: String, view: Dictionary) -> Control:
	if id.begins_with("moment_"):
		return _moment(int(id.trim_prefix("moment_")), view)
	match id:
		"hold": return _hold(view)
		"crossing": return _crossing()
		"home": return _home(view)
		"aboard": return _aboard(view)
		"changed": return _changed(view)
		"medium": return _medium(view)
		"waiting": return _waiting(view)
	return VBoxContainer.new()


func _crossing() -> Control:
	var box := _column()
	box.add_child(_composed([["journey.plan", "speed_c"], " · γ ", ["journey.plan.cruise_gamma", "%.1f"]], 26, WARM))
	box.add_child(_composed([["journey.plan.distance", "%.1f"], " light-years"], 15, DIM))
	box.add_child(_composed(["You lived ", [D + "time.ship_days", "days"], ". ", [D + "time.earth_years", "%.2f"], " years passed on Earth."], 19))
	box.add_child(_composed(["Ship clock ", [D + "time.tau0", "%.4f"], " → ", [D + "time.tau", "%.4f"], " yr  ·  Earth ", [D + "time.year0", "%.2f"], " → ", [D + "time.year", "%.2f"], " yr"], 12, DIM))
	if not crossed and not _ids.has("hold"):
		var card := CardInterlude.new()
		card.latest = {"cruise": GalaxyMap.field_value(_view, "cruise") if GalaxyMap.field_value(_view, "cruise") is Dictionary else {}}
		box.add_child(_label(card.progress_text(), 15, WARM))
	elif crossed:
		_archive_says(box, _archive_crossing(_view))
		box.add_child(_label("The crossing is over. Arrival braking waits until you are ready.", 13, DIM))
	return box


## I4: page 1's Archive line: the accepted telling, else the sim's authored crossing line.
func _archive_crossing(view: Dictionary) -> String:
	if narration != null:
		return narration.crossing_text(view)
	var a: Variant = GalaxyMap.field_value(view, D + "narration.crossing")
	return "" if a == null else str(a)


## The Archive speaking on a page (in-world words, no digits: D-21, D-67).
func _archive_says(box: Container, words: String) -> void:
	if words.is_empty():
		return
	var said := _label("The Archive: “%s”" % words, 15, WARM)
	said.name = "Narration"
	said.set_meta("archive_text", true) # no digits; the authored lines fit 280, a telling the Archive's 600
	box.add_child(said)


func _home(view: Dictionary) -> Control:
	var row := _row()
	var tier := int(float(GalaxyMap.field_value(view, D + "time.tier") if GalaxyMap.field_value(view, D + "time.tier") != null else 0.0))
	# The tier's picture fills the panel behind the page (_backdrop); the words sit in a column over
	# its calm left side. A missing picture leaves the words alone across the page.
	_home_art.texture = home_texture(home_dir.path_join("tier%d.png" % tier))
	_home_missing = _home_art.texture == null
	var box := _column()
	box.name = "HomeText"
	row.add_child(box)
	if not _home_missing:
		box.size_flags_stretch_ratio = HOME_TEXT
		var rest := Control.new()
		rest.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rest.size_flags_stretch_ratio = 1.0 - HOME_TEXT
		rest.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(rest)
	var line := DisplayBinding.new().bind(D + "time", "tier_line")
	_style_label(line, 18, WARM)
	line.name = "TierLine"
	box.add_child(line)
	# The tier line carries the whole years at home; the exact Earth clocks are on the crossing page.
	box.add_child(_composed(["News from home is ", [D + "time.news_age_years", "%.1f"], " years old when it reaches you."], 14))
	var news: Variant = GalaxyMap.field_value(view, "consequence.news")
	if news is Dictionary and news.get("template_id") != null and news.get("slots") is Dictionary:
		box.add_child(_label("The last word from home, at your last stop:", 11, DIM))
		var body := NewsPanel.TemplateText.new()
		body.templates = NewsCopy.load_json(NewsCopy.TEMPLATES)
		body.no_age_text = str(NewsCopy.load_json(NewsCopy.COPY).get("labels", {}).get("body_no_age", ""))
		body.no_age = NewsCopy.is_no_age(news.slots)
		body.bind("consequence.news", "%s")
		_style_label(body, 13, TEXT)
		box.add_child(body)
	else:
		box.add_child(_label("No word from home has reached the ship since you left.", 13, DIM))
	return row


func _aboard(view: Dictionary) -> Control:
	var box := _column()
	var c := D + "crew.counts."
	var counts: Dictionary = GalaxyMap.field_value(view, D + "crew.counts") if GalaxyMap.field_value(view, D + "crew.counts") is Dictionary else {}
	box.add_child(_composed(["Your crew lived ", [c + "days", "days"], " of the crossing aboard."], 17))
	var aboard: Variant = GalaxyMap.field_value(view, D + "narration.aboard")
	_archive_says(box, "" if aboard == null else str(aboard))
	var lines := [
		["work_done", ["Work finished: ", [c + "work_done", "words"], "."]],
		["refusals", ["Times they refused work: ", [c + "refusals", "words"], "."]],
		["concerns", ["Concerns raised: ", [c + "concerns", "words"], "."]],
		["concerns_auto_answered", ["Concerns auto-run answered for you: ", [c + "concerns_auto_answered", "words"], "."]],
		["reliefs_asked", ["Times they asked to step back: ", [c + "reliefs_asked", "words"], " (granted: ", [c + "reliefs_granted", "words"], "; denied: ", [c + "reliefs_denied", "words"], ")."]],
		["holds", ["Times auto-run stopped for you: ", [c + "holds", "words"], "."]],
	]
	for l: Array in lines:
		if float(counts.get(l[0], 0.0)) > 0.0:
			box.add_child(_composed(l[1], 15))
	var faces := HFlowContainer.new()
	faces.add_theme_constant_override("h_separation", 10)
	var members: Array = GalaxyMap.field_value(view, D + "crew.movement") if GalaxyMap.field_value(view, D + "crew.movement") is Array else []
	for m: Dictionary in members:
		var cell := VBoxContainer.new()
		cell.add_child(_face("Face_" + str(m.id), str(m.id), str(m.get("emotion1", "neutral")), 60))
		var n := _label(str(m.get("name", m.id)), 11, DIM)
		n.custom_minimum_size = Vector2(104, 0)
		n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cell.add_child(n)
		faces.add_child(cell)
	box.add_child(faces)
	return box


func _moment(i: int, view: Dictionary) -> Control:
	var m: Dictionary = GalaxyMap.field_value(view, D + "crew.moments.%d" % i)
	var p := D + "crew.moments.%d." % i
	var row := _row()
	row.add_child(_face("Face", str(m.get("actor", "")), str(m.get("emotion", "neutral")), 150))
	var box := _column()
	row.add_child(box)
	box.add_child(_composed([[p + "day", "days_into"]], 12, DIM))
	box.add_child(_label("%s · %s" % [str(m.get("name", "")), str(_roles.get(str(m.get("actor", "")), ""))], 16))
	var said: Label
	if str(m.get("kind", "")) == "hold":
		said = _label("%s %s" % [str(m.get("name", "")), str(m.get("text", ""))], 18, LOW)
	else:
		said = _label("“%s”" % str(ai_text.get(str(m.get("ai_req", "")), m.get("text", ""))), 18)
	said.set_meta("crew_text", true)
	box.add_child(said)
	box.add_child(_label(str(KIND_WORDS.get(str(m.get("kind", "")), "")), 13, DIM))
	return row


func _changed(view: Dictionary) -> Control:
	var box := _column()
	# The sim ranks the members by how far they moved (|Δ|); the page shows the top MOVERS who moved.
	var members: Array = GalaxyMap.field_value(view, D + "crew.movement")
	var shown := 0
	for i in members.size():
		var m: Dictionary = members[i]
		if float(m.get("moved", 0.0)) <= 0.0 or shown >= MOVERS:
			continue
		shown += 1
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		row.add_child(_face("Before_" + str(m.id), str(m.id), str(m.get("emotion0", "neutral")), 52))
		var arrow := _label("→", 16, DIM)
		arrow.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		arrow.custom_minimum_size = Vector2.ZERO
		row.add_child(arrow)
		row.add_child(_face("After_" + str(m.id), str(m.id), str(m.get("emotion1", "neutral")), 52))
		var col := _column()
		col.add_theme_constant_override("separation", 2)
		col.add_child(_label("%s · %s" % [str(m.get("name", "")), str(_roles.get(str(m.id), ""))], 15))
		var p := D + "crew.movement.%d." % i
		var parts: Array = []
		for k: String in INDICATORS:
			if float(m.get("d_" + k, 0.0)) != 0.0:
				parts.append_array([(" · " if not parts.is_empty() else "") + k.capitalize() + " ", [p + k + "0", "%d"], " → ", [p + k + "1", "%d"]])
		col.add_child(_composed(parts, 13, DIM))
		row.add_child(col)
		box.add_child(row)
	return box


func _medium(view: Dictionary) -> Control:
	var box := _column()
	var md := D + "medium."
	box.add_child(_label("Media crossed, in order:", 13, DIM))
	var media: Array = GalaxyMap.field_value(view, md + "media")
	for i in media.size():
		box.add_child(_composed([[md + "media.%d.name" % i, "ism_medium"], " · ", [md + "media.%d.n_h_cm3" % i, "ism_density"]], 14))
	box.add_child(_composed(["Grains swept (≥ 1 µm): ", [md + "grains_swept", "sci"]], 14))
	box.add_child(_composed(["Largest displayed impact this leg: ", [md + "largest_um", "%.2f"], " µm · ", [md + "largest_j", "sci J"]], 14))
	return box


func _waiting(view: Dictionary) -> Control:
	var box := _column()
	for w: Dictionary in GalaxyMap.field_value(view, D + "crew.waiting"):
		var row := _row()
		row.add_child(_face("Face_" + str(w.actor), str(w.actor), "neutral", 56))
		var said := _label("%s %s" % [str(w.get("name", "")), "asks to step back from their work." if str(w.get("kind", "")) == "relief" else "is waiting for your answer on the work you offered."], 15)
		said.set_meta("crew_text", true)
		row.add_child(said)
		box.add_child(row)
	box.add_child(_label("Answer them at the Crew console.", 13, DIM))
	return box


func _hold(view: Dictionary) -> Control:
	var h: Dictionary = (GalaxyMap.field_value(view, "crew.holds") as Array)[0]
	var row := _row()
	row.add_child(_face("Face", str(h.get("actor", "")), "sad", 150))
	var box := _column()
	row.add_child(box)
	var who := str(h.get("name", "")) if str(h.get("name", "")) != "" else "The crew"
	var said := _label(CrewPage.hold_text(who, h), 19, LOW)
	said.set_meta("crew_text", true)
	box.add_child(said)
	box.add_child(_label("Auto-run stopped the crossing for you. Ship time waits until you resume it.", 13, DIM))
	box.add_child(_composed(["So far: ", [D + "time.ship_days", "days"], " of the crossing."], 14))
	var acts := HBoxContainer.new()
	acts.add_theme_constant_override("separation", 10)
	_button("CrewConsole", "Answer at the Crew console", func() -> void: open_crew.emit(), acts)
	_button("Resume", "Resume the crossing", func() -> void: press_resume(), acts)
	box.add_child(acts)
	return row


# ---------------------------------------------------------------- parts

func _row() -> HBoxContainer:
	var r := HBoxContainer.new()
	r.add_theme_constant_override("separation", 14)
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return r


func _column() -> VBoxContainer:
	var b := VBoxContainer.new()
	b.add_theme_constant_override("separation", 8)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return b


func _style_label(l: Label, size: int, color: Color) -> void:
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.custom_minimum_size = Vector2(160, 0)


func _label(text: String, size := 15, color := TEXT) -> Label:
	var l := Label.new()
	l.text = text
	_style_label(l, size, color)
	return l


func _composed(parts: Array, size := 15, color := TEXT) -> ComposedBinding:
	var c := ComposedBinding.new().compose(parts)
	_style_label(c, size, color)
	return c


func _face(node_name: String, id: String, emotion: String, px: int) -> TextureRect:
	var t := TextureRect.new()
	t.name = node_name
	t.texture = CrewPage.face(id, emotion)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(px, px)
	t.tooltip_text = emotion
	return t
