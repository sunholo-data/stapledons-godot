class_name EarthFeed
extends Control
## R3-EARTH-LINK EL3b.3 (design r3/earth-link.md EL3b; Mark 2026-10-28, "visual first, words last"):
## Earth's feed at the comms station, the crew's window home. It shows what the sim says and never
## chooses: the picture is earth.feed's (the week of the newest light, its event, kind and pick),
## the playback speed is that frame moving with t_e (so it is the Earth rate D, times the game's
## pacing), the pacing look is the band data/ui/comms_feed.json picks by earth.rate, and out of beam the
## frame of the last beamed light (earth.last_feed) freezes under static while the ring fills by
## earth.out.progress. Every number on it is a binding. Time comes from advance(dt) only.
## R3-TRUE-PROCESSED (standing order 2026-10-30): the picture is drawn exactly as decoded, with no
## colour wash at any D. The feed is data on Earth's laser link: the Doppler shift moves its time
## rate (the bands, exact) and its carrier, never the colours Earth encoded (RS-Q5).

const FEED := "res://data/ui/comms_feed.json"
const EVENTS := "res://data/feed/events.json"
## Painted-live frames asked for in one visit to the station (design EL3b: a few per look, never a burst).
const LIVE_PER_VISIT := 3
const SOURCES := "res://data/feed/SOURCES"
const PICTURES := "res://data/feed/pictures/"

static var _copy: Dictionary = {}
static var _library: Dictionary = {} # event id -> [picture paths], variant order
static var _textures: Dictionary = {}
static var _scenes: Dictionary = {} # event id -> its scene paragraph (data/feed/events.json)

var picture := TextureRect.new()
var ghosts: Array[TextureRect] = []
var static_rect := TextureRect.new()
var ring := FeedRing.new()
## The screen: a fixed, clipping control over the whole feed, holding the picture, its ghosts, the static
## and (Processed only) the Doppler edge gradient above them; nothing animated leaves it (eval #384 B1).
## Mark, 2026-11-03: no border; the picture runs to the edge in both settings.
var screen := Control.new()
var vignette := DopplerVignette.new()
var doppler_tag := ComposedBinding.new()
var signal_tag := ComposedBinding.new()
var clock_tag := ComposedBinding.new()
var caption := ComposedBinding.new()
var history: Array[Texture2D] = []
var band: Dictionary = {}
var beam := true
var shown_key := ""
var now_s := 0.0
var _noise_frame := -1
var _rng := RandomNumberGenerator.new()
## EL3b.6: the session's AI relay (ShipConsoles sets it), or null when AI is off.
var relay: AiRelay = null
var asked := {} # week -> true: each week is asked for once per session
var visit_asks := 0
## EL3b.7, made exact by R3 audio realism AR8b (standing order 2026-10-30): what the receiver plays
## (data/ui/comms_feed.json "sound"; ShipSound follows it while the station is open, the feed itself
## holds no audio): the bed's cue; rate, the stream's speed (pitch_scale); correct, the Receiver bus's
## pitch factor (1 in True); silent, the True sound outside human hearing ("below" or "above"); the
## accent over it, with accent_seq counting every accent that is due.
var home_sound := {"cue": "", "rate": 1.0, "correct": 1.0, "silent": false, "hearing": "", "accent": "", "accent_seq": 0}
## The station's setting: true = Receiver (the frequency corrected, the default), false = True.
var receiver := true
var sound_button := Button.new()
var earth_rate := 1.0 ## earth.rate (D) of the last refresh
var _sound_since := 0.0
var _accent_due := 0.0


static func copy() -> Dictionary:
	if _copy.is_empty():
		_copy = NewsCopy.load_json(FEED)
	return _copy


## The shipped library: data/feed/SOURCES rows "<event>_v<k>.webp sha256 ...", in variant order.
static func library() -> Dictionary:
	if _library.is_empty():
		var rows: Dictionary = {}
		for line: String in FileAccess.get_file_as_string(SOURCES).split("\n"):
			var m := RegEx.create_from_string("^(\\S+)_v(\\d+)\\.webp sha256 ").search(line)
			if m != null:
				rows.get_or_add(m.get_string(1), []).append([int(m.get_string(2)), PICTURES + m.get_string(1) + "_v" + m.get_string(2) + ".webp"])
		for id: String in rows:
			var vs: Array = rows[id]
			vs.sort_custom(func(a: Array, b: Array) -> bool: return a[0] < b[0])
			_library[id] = vs.map(func(v: Array) -> String: return v[1])
	return _library


## The band for an Earth rate: the first whose min <= rate (< max when given). Chosen, never computed.
static func band_for(rate: float) -> Dictionary:
	for b: Dictionary in copy().bands:
		if rate >= float(b.get("min", -INF)) and (not b.has("max") or rate < float(b.max)):
			return b
	return {}


static func scene_of(id: String) -> String:
	if _scenes.is_empty():
		var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(EVENTS))
		for e: Dictionary in (d.get("events", []) if d is Dictionary else []):
			_scenes[str(e.get("id", ""))] = str(e.get("scene", ""))
	return str(_scenes.get(id, ""))


## The AI cache's entity for an event: its id with hyphens as underscores (the key pattern).
static func entity_of(id: String) -> String:
	return id.replace("-", "_")


## A new visit to the station: a few more weeks may be painted.
func begin_visit() -> void:
	visit_asks = 0


## EL3b.6: a painted-live week. "live:<blob>" when its painting is in the AI cache (the player's
## library); otherwise it is asked for (once per week, a few per visit, with the player's keys) and
## the library shows until it arrives.
func live_source(feed: Dictionary) -> String:
	if relay == null or relay.cache == null or str(feed.get("kind", "")) != "live":
		return ""
	var id := str(feed.get("event", {}).get("id", ""))
	var ctx: Dictionary = feed.get("context", {})
	var tier := int(ctx.get("era_tier", 0))
	var week := str(int(feed.get("frame", 0)))
	var key := {"kind": "feed", "entity_id": entity_of(id), "emotion": "-", "variant": week}
	var hit := relay.cache.lookup(key, tier)
	if not hit.is_empty() and FileAccess.file_exists(relay.cache.blob_path(hit)):
		return "live:" + relay.cache.blob_path(hit)
	if not asked.has(week) and visit_asks < LIVE_PER_VISIT and relay.enabled and relay.mode not in ["off", "replay"] and relay.route_for("feed") != "":
		var fields := {"age_stage": tier, "context": {"event": id, "scene": scene_of(id), "era": str(ctx.get("era_word", "")),
			"years": str(int(float(ctx.get("years", 0.0)))), "week": week}}
		if relay.open("feed", "feed", entity_of(id), fields):
			asked[week] = true
			visit_asks += 1
	return ""


## The event's pictures: the shipped library, then the frames painted for it in earlier weeks and
## voyages (the AI cache), so the library grows over playthroughs.
func pictures_of(id: String) -> Array:
	var out: Array = library().get(id, []).duplicate()
	if relay != null and relay.cache != null:
		for e: Dictionary in relay.cache.entries_for("feed", entity_of(id)):
			out.append("painted:" + relay.cache.blob_path(e))
	return out


## What a feed frame shows: "library:<path>" for a picture, or "sky:<frame>" for the procedural sky
## over home (the sky kind, and any week whose event has no picture yet). A painted-live week shows
## the library until EL3b.6 paints it; a snapshot week shows the library until the crew's own
## pictures exist.
static func source_of(feed: Dictionary) -> String:
	var frame := int(feed.get("frame", 0))
	if str(feed.get("kind", "")) == "sky":
		return "sky:%d" % frame
	var paths: Array = library().get(str(feed.get("event", {}).get("id", "")), [])
	if paths.is_empty():
		return "sky:%d" % frame
	return "library:" + str(paths[int(feed.get("pick", 0)) % paths.size()])


## source_of over this session's pictures (shipped and painted): what a library week shows.
func picked_source(feed: Dictionary) -> String:
	var frame := int(feed.get("frame", 0))
	if str(feed.get("kind", "")) == "sky":
		return "sky:%d" % frame
	var paths := pictures_of(str(feed.get("event", {}).get("id", "")))
	if paths.is_empty():
		return "sky:%d" % frame
	var p: String = paths[int(feed.get("pick", 0)) % paths.size()]
	return p if p.begins_with("painted:") else "library:" + p


func _init() -> void:
	name = "EarthFeed"
	clip_contents = true
	custom_minimum_size = Vector2(320, 180)
	screen.name = "Screen"
	screen.clip_contents = true
	screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(screen)
	for r: TextureRect in [picture, static_rect]:
		_fill(r)
	screen.add_child(picture)
	for i in 2:
		var g := TextureRect.new()
		_fill(g)
		g.visible = false
		ghosts.append(g)
		screen.add_child(g)
	static_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	static_rect.modulate = Color(1, 1, 1, 0.6) # the last week shows through, dimmed
	screen.add_child(static_rect)
	# R3-TRUE-PROCESSED-b: the Doppler edge overlay, above the picture and its ghosts (Processed only).
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen.add_child(vignette)
	ring.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	add_child(ring)
	for t: Array in [[signal_tag, Control.PRESET_TOP_LEFT], [clock_tag, Control.PRESET_TOP_RIGHT], [caption, Control.PRESET_BOTTOM_LEFT]]:
		var tag: ComposedBinding = t[0]
		tag.theme = StapledonTheme.theme() # the feed can also be hosted in its own viewport
		tag.theme_type_variation = "HUDEarthFeed"
		tag.add_theme_font_size_override("font_size", 14)
		tag.set_anchors_and_offsets_preset(t[1], Control.PRESET_MODE_MINSIZE, 10)
		tag.grow_horizontal = Control.GROW_DIRECTION_BEGIN if t[1] == Control.PRESET_TOP_RIGHT else Control.GROW_DIRECTION_END
		tag.grow_vertical = Control.GROW_DIRECTION_BEGIN if t[1] == Control.PRESET_BOTTOM_LEFT else Control.GROW_DIRECTION_END
		add_child(tag)
	caption.add_theme_font_size_override("font_size", 16)
	# R3-TRUE-PROCESSED-b: the indicator's label, top centre, its number bound to earth.rate.
	doppler_tag.name = "DopplerTag"
	doppler_tag.theme = StapledonTheme.theme()
	doppler_tag.theme_type_variation = "HUDEarthFeed"
	doppler_tag.add_theme_font_size_override("font_size", 13)
	doppler_tag.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 10)
	doppler_tag.grow_horizontal = Control.GROW_DIRECTION_BOTH
	doppler_tag.visible = false
	add_child(doppler_tag)
	# AR8b: the receiver's setting, both its indicator and its switch (True / Receiver).
	sound_button.name = "SoundSetting"
	sound_button.theme_type_variation = "HUDFlat"
	sound_button.focus_mode = Control.FOCUS_NONE
	sound_button.add_theme_font_size_override("font_size", 13)
	sound_button.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 8)
	sound_button.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	sound_button.grow_vertical = Control.GROW_DIRECTION_BEGIN
	sound_button.pressed.connect(func() -> void: set_receiver(not receiver))
	add_child(sound_button)
	_sound_words()


## AR8b: the station's setting (Receiver, the default, or True). The next refresh plays it.
## R3-TRUE-PROCESSED-b: it also shows (Receiver) or hides (True) the Doppler indicator at once.
func set_receiver(on: bool) -> void:
	receiver = on
	if not str(home_sound.cue).is_empty():
		_apply_rates(str(home_sound.cue))
	_sound_words()
	_doppler_show()


## A picture layer filling the clipping screen.
func _fill(r: TextureRect) -> void:
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE




## R3-TRUE-PROCESSED-b: the Processed Doppler indicator for Earth rate d (data/ui/comms_feed.json
## "doppler"). A reference line at lambda_ref_nm is seen at lambda_ref_nm / d; the edge gradient
## shows the spectral colour of that wavelength, clamped to visible_nm (the indicator's limits,
## 400 and 650 nm; not the ends of human vision) once the line leaves them; strength |ln d| / ln(d_max). Returns lambda_nm, shown_nm, strength and colour (sRGB, unit max).
static func doppler_indicator(d: float) -> Dictionary:
	var c: Dictionary = copy().get("doppler", {})
	var vis: Array = c.get("visible_nm", [400.0, 650.0])
	var lam := float(c.get("lambda_ref_nm", 555.0)) / maxf(d, 1e-300)
	var shown := clampf(lam, float(vis[0]), float(vis[1]))
	var strength := clampf(absf(log(maxf(d, 1e-300))) / log(float(c.get("d_max", 1414.2))), 0.0, 1.0)
	return {"lambda_nm": lam, "shown_nm": shown, "strength": strength, "colour": spectral_colour(shown)}


## The colour of a monochromatic line (CIE 1931 2-degree observer, Blackbody.cmf) in sRGB. Every pure
## spectral colour lies outside the sRGB gamut; for an indicator the hue matters, so the negative channels
## are clipped to zero (desaturating toward white turned 700 nm orange), then a unit max channel.
static func spectral_colour(lambda_nm: float) -> Color:
	var xyz := Blackbody.cmf(lambda_nm)
	if xyz.y <= 0.0 and xyz.x <= 0.0 and xyz.z <= 0.0:
		return Color(0, 0, 0)
	var rgb := Blackbody.xyz_to_linear_srgb(xyz.x, xyz.y, xyz.z)
	rgb = Vector3(maxf(rgb.x, 0.0), maxf(rgb.y, 0.0), maxf(rgb.z, 0.0))
	var top := maxf(rgb.x, maxf(rgb.y, rgb.z))
	if top <= 0.0:
		return Color(0, 0, 0)
	return Color(rgb.x / top, rgb.y / top, rgb.z / top).linear_to_srgb()


## Show the indicator in Receiver (Processed) and in beam, from the last refresh's earth.rate.
func _doppler_show() -> void:
	var ind := doppler_indicator(earth_rate)
	vignette.shown = receiver and beam
	vignette.colour = ind.colour
	vignette.strength = float(ind.strength) if vignette.shown else 0.0
	vignette.queue_redraw()
	doppler_tag.visible = vignette.shown


## AR8b: how the receiver plays home at Earth rate d (data/ui/comms_feed.json sound.receiver). The time
## rate is d in every setting. Receiver: the stream at speed d within the real-time range, its frequency
## corrected by 1/speed. True: speed and pitch x d, nothing heard outside receiver.audible.
static func receiver_plan(d: float, on: bool) -> Dictionary:
	var r: Dictionary = copy().get("sound", {}).get("receiver", {})
	if on:
		var rate := clampf(d, float(r.get("min_rate", 0.0625)), float(r.get("max_rate", 16.0)))
		return {"rate": rate, "correct": 1.0 / rate, "silent": false, "hearing": ""}
	var aud: Array = r.get("audible", [0.02, 50.0])
	var hearing := "below" if d < float(aud[0]) else "above" if d > float(aud[1]) else ""
	return {"rate": d, "correct": 1.0, "silent": not hearing.is_empty(), "hearing": hearing}


func _apply_rates(cue: String) -> void:
	var d := 1.0 if cue == str(copy().get("sound", {}).get("beds", {}).get("static", "")) else earth_rate # the receiver's own hiss has no Doppler
	home_sound.merge(receiver_plan(d, receiver), true)


func _sound_words() -> void:
	var w: Dictionary = copy().words
	var h := str(home_sound.get("hearing", ""))
	sound_button.text = "♪ " + str(w.receiver if receiver else w.true_sound) + (str(w.below_hearing) if h == "below" else str(w.above_hearing) if h == "above" else "")


## The frame's HUD view (ShipConsoles.refresh_view): the picture, the band, static and the tags.
func refresh(view: Dictionary) -> void:
	var e: Variant = view.get("earth")
	if not e is Dictionary:
		visible = false
		home_sound.cue = ""
		return
	visible = true
	var w: Dictionary = copy().words
	beam = e.get("in_beam") == true
	earth_rate = float(e.get("rate", 1.0))
	band = band_for(earth_rate)
	var feed: Dictionary = e.get("feed", {}) if beam else e.get("last_feed", {})
	var key := live_source(feed) if beam else ""
	if key.is_empty():
		key = picked_source(feed)
	if key != shown_key:
		shown_key = key
		var tex := texture_of(key)
		if beam and picture.texture != null:
			history.push_front(picture.texture)
			history.resize(mini(history.size(), ghosts.size()))
		picture.texture = tex
	picture.self_modulate = Color(1, 1, 1) if beam else Color(0.45, 0.45, 0.5)
	static_rect.visible = not beam
	var wd: Dictionary = copy().words
	doppler_tag.compose([str(wd.get("doppler", "Doppler ×")), ["earth.rate", "sci"], str(wd.get("doppler_shown", " · shown"))])
	doppler_tag.update_from(view)
	_doppler_show()
	var out: Variant = e.get("out")
	ring.visible = not beam and out is Dictionary and str(out.get("reason", "")) == "not_heard"
	ring.fill = float(out.get("progress", 0.0)) if out is Dictionary else 0.0
	ring.label.compose([["earth.out.due_in_years", "comms_years"], "\n" + str(w.until_voice)])
	ring.label.update_from(view)
	ring.queue_redraw()
	var home: bool = e.get("at_home") == true
	signal_tag.compose([["earth.at_home", "feed_live"]] if beam and home else [["earth.in_beam", "feed_signal"]])
	signal_tag.update_from(view)
	clock_tag.visible = beam and not home
	clock_tag.compose([str(w.earth) + " ", ["earth.newest_light_year", "comms_clock"], " · ", ["earth.light_age_years", "comms_years"], " old"])
	clock_tag.update_from(view)
	if not beam:
		caption.compose([["earth.last_feed.event.words", "text"], str(w.last_week)])
	elif str(feed.get("kind", "")) == "sky":
		caption.compose([["earth.feed.kind", "feed_kind"]])
	else:
		caption.compose([["earth.feed.event.words", "text"]])
	caption.update_from(view)
	caption.add_theme_font_size_override("font_size", 20 if beam and str(feed.get("kind", "")) == "card" else 16)
	_choose_sound(feed)
	_place_ghosts()


## EL3b.7: the bed for this frame (the week's category, the sky's, babble or static), held for hold_s
## of the station's clock before a new week's replaces it. AR8b: its rates from earth.rate exactly
## (receiver_plan); the first accent comes first_s / D after it starts. Chosen, never computed.
func _choose_sound(feed: Dictionary) -> void:
	var s: Dictionary = copy().get("sound", {})
	var beds: Dictionary = s.get("beds", {})
	var still := str(beds.get("static", ""))
	var want := still
	if beam:
		var k := "babble" if str(band.get("sound", "")) == "babble" else "sky" if str(feed.get("kind", "")) == "sky" else str(feed.get("event", {}).get("category", ""))
		want = str(beds.get(k, ""))
	var cur := str(home_sound.cue)
	if want != cur and (cur == "" or (cur == still) != (want == still) or now_s - _sound_since >= float(s.get("hold_s", 0.0))):
		home_sound.cue = want
		home_sound.accent = str(s.get("accents", {}).get(want, {}).get("cue", ""))
		_sound_since = now_s
		_accent_due = now_s + float(s.get("first_s", 0.0)) / maxf(earth_rate, 1e-12)
	_apply_rates(str(home_sound.cue))
	_sound_words()


## The fake-clock seam (ShipConsoles.advance): the drift of a near-still frame and the static.
func advance(dt: float) -> void:
	now_s += maxf(dt, 0.0)
	if band.get("drift", false) and beam:
		var s := 1.0 + 0.03 * (0.5 + 0.5 * sin(now_s * TAU / 40.0))
		picture.scale = Vector2(s, s)
		picture.pivot_offset = picture.size * 0.5 # inside the clipping screen: the drift never leaves it
	else:
		picture.scale = Vector2.ONE
	var nf := int(now_s * 14.0)
	if not beam and nf != _noise_frame:
		_noise_frame = nf
		static_rect.texture = noise_texture(nf)
	# EL3b.7 / AR8b: an accent over the bed when it is due, every every_s / D (home's own time at D).
	var acc: Dictionary = copy().get("sound", {}).get("accents", {}).get(str(home_sound.cue), {})
	if not acc.is_empty() and now_s >= _accent_due:
		home_sound.accent_seq = int(home_sound.accent_seq) + 1
		_accent_due = now_s + float(acc.get("every_s", 0.0)) / maxf(earth_rate, 1e-12)
	_place_ghosts()


func _place_ghosts() -> void:
	var j := float(band.get("jumble", 0.0)) if beam else 0.0
	_rng.seed = hash([shown_key, int(now_s * 10.0)])
	for i in ghosts.size():
		var g := ghosts[i]
		g.visible = j > 0.0 and i < history.size()
		if g.visible:
			g.texture = history[i]
			g.modulate = Color(1, 1, 1, j * (0.45 - 0.15 * i))
			g.position = Vector2(_rng.randf_range(-40.0, 40.0) * j, _rng.randf_range(-6.0, 6.0) * j)


func texture_of(key: String) -> Texture2D:
	if _textures.has(key):
		return _textures[key]
	var tex: Texture2D = null
	if key.begins_with("library:"):
		tex = CaptainAvatar.make_texture(key.trim_prefix("library:"))
	elif key.begins_with("live:") or key.begins_with("painted:"):
		var img := Image.load_from_file(key.substr(key.find(":") + 1)) # after the first ":" (the path keeps its own user://)
		tex = ImageTexture.create_from_image(img) if img != null and not img.is_empty() else null
	if tex == null:
		tex = sky_texture(int(key.get_slice(":", 1)) if key.begins_with("sky:") else 0)
	_textures[key] = tex
	return tex


## The sky over home: a dusk-to-night gradient, stars and the Moon, the same for a given week.
static func sky_texture(frame: int) -> Texture2D:
	var img := Image.create(320, 180, false, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(["sky", frame])
	var top := Color("#0B0D16")
	var low := Color("#5B4A78").lerp(Color("#C98E3A"), rng.randf_range(0.0, 0.6))
	for y in 180:
		var c := top.lerp(low, pow(float(y) / 179.0, 1.6))
		for x in 320:
			img.set_pixel(x, y, c)
	for i in 140:
		var p := Vector2i(rng.randi_range(0, 319), rng.randi_range(0, 120))
		img.set_pixelv(p, Color("#EFE3C8").darkened(rng.randf_range(0.0, 0.6)))
	var m := Vector2i(rng.randi_range(40, 280), rng.randi_range(20, 70))
	for dy in range(-9, 10):
		for dx in range(-9, 10):
			if dx * dx + dy * dy <= 81 and m.x + dx >= 0 and m.x + dx < 320 and m.y + dy >= 0:
				img.set_pixel(m.x + dx, m.y + dy, Color("#F3E7C9"))
	for x in 320: # the hills of home
		var h := 150 + int(10.0 * sin(float(x) / 37.0 + frame) + 6.0 * sin(float(x) / 13.0))
		for y in range(h, 180):
			img.set_pixel(x, y, Color("#151126"))
	return ImageTexture.create_from_image(img)


func noise_texture(n: int) -> Texture2D:
	var img := Image.create(160, 90, false, Image.FORMAT_L8)
	var rng := RandomNumberGenerator.new()
	rng.seed = n
	for y in 90:
		for x in 160:
			img.set_pixel(x, y, Color.from_hsv(0.0, 0.0, rng.randf()))
	return ImageTexture.create_from_image(img)


## The feed's formats (DisplayBinding.format_field): words for sim booleans and kinds, nothing more.
static func format(fmt: String, raw: Variant) -> String:
	if raw == null:
		return "-"
	var w: Dictionary = copy().words
	match fmt:
		"feed_live": return "● " + str(w.live) if raw == true else "● " + str(w.earth)
		"feed_signal": return "● " + str(w.earth) if raw == true else str(w.no_signal)
		"feed_kind": return str(w.sky) if str(raw) == "sky" else str(raw)
	return str(raw)


## The ring out of beam: it fills from the moment the ship left Earth's beam to when it is due.
class FeedRing extends Control:
	var fill := 0.0
	var label := ComposedBinding.new()

	func _init() -> void:
		custom_minimum_size = Vector2(150, 150)
		size = custom_minimum_size
		position = -custom_minimum_size * 0.5
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 14)
		label.theme_type_variation = "HUDOverlay"
		add_child(label)

	func _draw() -> void:
		var c := size * 0.5
		draw_circle(c, 72.0, Color(StapledonTheme.INK, 0.78))
		draw_arc(c, 62.0, 0.0, TAU, 96, Color(0.94, 0.89, 0.78, 0.3), 9.0, true)
		if fill > 0.0:
			draw_arc(c, 62.0, -PI * 0.5, -PI * 0.5 + TAU * clampf(fill, 0.0, 1.0), 96, StapledonTheme.CORAL, 9.0, true)


## R3-TRUE-PROCESSED-b (Mark 2026-11-03: "perhaps it can bleed in from the edge?", then "it should be a
## gradient all the way to the edge"): the Doppler indicator as one continuous instrument overlay, Processed
## only. Opacity strength x (1 - smoothstep(t)), t the depth from the screen's edge over vignette_frac of the
## short side: the full strength at the very edge, zero (with zero slope) at the inner end, no band or line.
## Drawn as BANDS concentric rings with per-vertex alpha (piecewise linear between the profile's samples),
## above the picture and its ghosts, inside the clipping screen; True draws nothing.
class DopplerVignette extends Control:
	const BANDS := 8
	var shown := false
	var colour := Color(1, 1, 1)
	var strength := 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func width() -> float:
		return float(EarthFeed.copy().get("doppler", {}).get("vignette_frac", 0.10)) * minf(size.x, size.y)

	## The profile at depth t in [0, 1] of the gradient: 1 - smoothstep(t).
	static func profile(t: float) -> float:
		var u := clampf(t, 0.0, 1.0)
		return 1.0 - u * u * (3.0 - 2.0 * u)

	## The opacity the overlay draws at depth px from the edge (what the GPU interpolates).
	func opacity_at(px: float) -> float:
		var w := width()
		if not shown or w <= 0.0 or px >= w: return 0.0
		var x := clampf(px / w, 0.0, 1.0) * BANDS
		var k := mini(int(x), BANDS - 1)
		return strength * lerpf(profile(float(k) / BANDS), profile(float(k + 1) / BANDS), x - k)

	func _draw() -> void:
		if not shown or strength <= 0.0:
			return
		var w := width()
		for k in BANDS:
			var d0 := w * k / BANDS
			var d1 := w * (k + 1) / BANDS
			var a0 := Color(colour, strength * profile(float(k) / BANDS))
			var a1 := Color(colour, strength * profile(float(k + 1) / BANDS))
			var o := [Vector2(d0, d0), Vector2(size.x - d0, d0), Vector2(size.x - d0, size.y - d0), Vector2(d0, size.y - d0)]
			var n := [Vector2(d1, d1), Vector2(size.x - d1, d1), Vector2(size.x - d1, size.y - d1), Vector2(d1, size.y - d1)]
			for e in 4:
				var e2 := (e + 1) % 4
				draw_polygon(PackedVector2Array([o[e], o[e2], n[e2], n[e]]), PackedColorArray([a0, a0, a1, a1]))
