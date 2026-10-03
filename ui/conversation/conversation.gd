class_name Conversation
extends Control
## The Medic conversation (AI.10a, design (c) part 1): a large portrait that
## crossfades between emotions, a subtitle revealed segment by segment, and
## the voice line. It reads only the sim's `ai_accepted` events (a text line
## with its segments, and the voice record naming it) and the cache.
##
## Timing: segment i starts at the voice descriptor's segments_ms[i] (exact
## PCM offsets, from the service); the portrait swaps there plus
## `swap_offset_ms` (0, or -150 to lead the voice), crossfading over
## `crossfade_ms` (default 120). Without a voice record the offsets come from
## the text at a reading pace. The clock is the frame clock (`advance`), so a
## movie-mode capture and a headless test see the same swaps.
## Fallbacks: a missing emotion walks AiCache.fallback_chain; a voice whose
## blob is in no layer logs `missing_blob` and the line plays as text.
##
## Run:  godot --path . res://ui/conversation/conversation.tscn -- --conversation=medic
##   --log=FILE       replay a session log (relay in replay mode, no AI process)
##   (no --log)       rehearse on the stub service (ConversationSession.rehearse)
##   --ai-live        the same through AiSession: live only if the player opted
##                    in with a key (AI.10b, attended); otherwise nothing is
##                    generated and the scene reports no line
##   --record=FILE    the rehearsal's session log (tee)
##   --library=DIR    the library layer (default user://ai_cache; the rehearsal
##                    writes there)       --core=DIR  the core layer (res://ai_core)
##   --crossfade-ms=N  --swap-offset-ms=N   the two style-frame parameters
##   --out=DIR        style frame: a PNG at each swap (when its fade is done),
##                    contact_sheet.png, line.ogg (+ line.wav), timeline.json;
##                    shows a time/segment overlay; quits at the end of the line

signal finished

const READ_MS_PER_CHAR := 60
const READ_MIN_MS := 1500
const TAIL_MS := 700

@export var crossfade_ms := 120.0
@export var swap_offset_ms := 0.0
@export var entity := "medic"
## Years aboard (age_stage lookup).
@export var years := 0
var cache := AiCache.new()
var auto_clock := true

## What happened, in order: {t_ms, event, ...}; tests and the capture read it.
var timeline: Array = []
var segments: Array = []
var offsets: Array = []
var duration_ms := 0
var t_ms := 0.0
var playing := false
var audio_path := ""

var _seg := -1
var _shown_sha := ""
## When the running crossfade began (its segment's swap time), or -1.
var _fade_from := -1.0
var _textures: Dictionary = {}
var _captures: Array = []
var _out := ""
var _voice_sha := ""
var _grab := ""

## The scene's nodes (bound on first use, so a test can drive an instance
## before it has had a frame).
var portrait_a: TextureRect
var portrait_b: TextureRect
var subtitle: Label
var name_label: Label
var audio: AudioStreamPlayer
var overlay: Label


func _bind() -> void:
	if portrait_a != null:
		return
	portrait_a = $Portrait/A
	portrait_b = $Portrait/B
	subtitle = $Subtitle/Text
	name_label = $Subtitle/Name
	audio = $Audio
	overlay = $Overlay
	overlay.visible = false


func _ready() -> void:
	_bind()
	var args := parse_args(OS.get_cmdline_user_args())
	if not args.has("conversation"):
		return # instanced by a test or another scene
	entity = args["conversation"]
	crossfade_ms = float(args.get("crossfade-ms", crossfade_ms))
	swap_offset_ms = float(args.get("swap-offset-ms", swap_offset_ms))
	cache.core_dir = args.get("core", cache.core_dir)
	cache.library_dir = args.get("library", cache.library_dir)
	cache.load_layers()
	var events := _events(args)
	if events.is_empty():
		push_error("conversation: no session events")
		get_tree().quit(2)
		return
	var p := ConversationSession.pick(events, entity)
	if p["line"].is_empty():
		push_error("conversation: no accepted line for %s" % entity)
		get_tree().quit(2)
		return
	_out = args.get("out", "")
	if _out != "":
		DirAccess.make_dir_recursive_absolute(_out)
		overlay.visible = true
		finished.connect(_write_style_frame)
	setup(p["line"], p["voice"])
	play()


static func parse_args(argv: PackedStringArray) -> Dictionary:
	var d := {}
	for a in argv:
		if a.begins_with("--"):
			var kv := a.substr(2).split("=", true, 1)
			d[kv[0]] = kv[1] if kv.size() > 1 else ""
	return d


func _events(args: Dictionary) -> Array:
	if args.has("log"):
		var r := ConversationSession.replay(args["log"], cache)
		return r["events"] if r["ok"] else []
	if args.has("ai-live"): # the attended line (AI.10b): the settings choose the provider
		var live := ConversationSession.session_rig(args, args.get("record", ""))
		if live.is_empty():
			return []
		add_child(live["session"]) # its indicator shows the running cost
		cache = live["relay"].cache
		var n := ConversationSession.rehearse(live["sim"], live["relay"], live["bridge"], entity, false)
		live["sim"].stop()
		live["bridge"].shutdown()
		live["session"].settings.forget_session_keys()
		return live["relay"].seen if n > 0 else []
	var rig := ConversationSession.stub_rig(args.get("record", ""), ProjectSettings.globalize_path(cache.library_dir))
	if rig.is_empty():
		return []
	var ticks := ConversationSession.rehearse(rig["sim"], rig["relay"], rig["bridge"], entity)
	rig["sim"].stop()
	rig["bridge"].shutdown()
	rig["bridge"].free()
	cache.load_layers()
	return rig["relay"].seen if ticks > 0 else []


## The line (an `ai_accepted` text event) and its voice (`ai_accepted` voice,
## or {}): segments, offsets, duration and the audio stream.
func setup(line: Dictionary, voice: Dictionary) -> void:
	_bind()
	segments = line.get("segments", [])
	var d: Dictionary = voice.get("descriptor", {})
	var segs_ms = d.get("segments_ms")
	if segs_ms is Array and segs_ms.size() == segments.size() and int(d.get("duration_ms", 0)) > 0:
		offsets = segs_ms.map(func(x): return int(x))
		duration_ms = int(d["duration_ms"])
	else:
		offsets = reading_offsets(segments)
		duration_ms = offsets[-1] + reading_ms(segments[-1]) if not segments.is_empty() else 0
	audio.stream = null
	audio_path = ""
	_voice_sha = str(voice.get("sha256", ""))
	if not voice.is_empty():
		var e := cache.find_sha(str(voice.get("sha256")))
		audio_path = cache.playback_path(e)
		if e.is_empty():
			_log("missing_blob", {"kind": "voice", "sha256": voice.get("sha256")})
		elif audio_path == "":
			_log("no_playback_copy", {"sha256": voice.get("sha256")})
		else:
			audio.stream = AudioStreamWAV.load_from_buffer(FileAccess.get_file_as_bytes(audio_path))
			if audio.stream == null:
				_log("undecodable_audio", {"path": audio_path})
	name_label.text = AiRelay.load_cast(AiRelay.CAST_DIR).get(entity, {}).get("name", entity)
	subtitle.text = ""


static func reading_ms(seg: Dictionary) -> int:
	return maxi(READ_MIN_MS, str(seg.get("text", "")).length() * READ_MS_PER_CHAR)


static func reading_offsets(segs: Array) -> Array:
	var out := []
	var t := 0
	for s in segs:
		out.append(t)
		t += reading_ms(s)
	return out


func play() -> void:
	_bind()
	t_ms = 0.0
	_seg = -1
	_shown_sha = ""
	_fade_from = -1.0
	_captures = []
	_grab = ""
	portrait_a.texture = null
	portrait_b.texture = null
	portrait_b.modulate.a = 0.0
	playing = true
	_log("start", {"duration_ms": duration_ms, "offsets": offsets, "audio": audio.stream != null})
	if audio.stream != null and audio.is_inside_tree():
		audio.play()
	advance(0.0)


## Interactive run: Enter or Space plays the line again once it has ended.
func _unhandled_input(event: InputEvent) -> void:
	if not playing and _out == "" and not segments.is_empty() and event.is_action_pressed("ui_accept"):
		play()


func _process(delta: float) -> void:
	if playing and auto_clock:
		advance(delta * 1000.0)


## Move the clock by `ms`: enter every segment whose (offset + swap offset)
## has passed, run the crossfade, finish after the line and a short tail.
func advance(ms: float) -> void:
	if not playing:
		return
	t_ms += ms
	while _seg + 1 < offsets.size() and t_ms >= float(offsets[_seg + 1]) + swap_offset_ms:
		_enter(_seg + 1)
	if _fade_from >= 0.0:
		var a := 1.0 if crossfade_ms <= 0.0 else clampf((t_ms - _fade_from) / crossfade_ms, 0.0, 1.0)
		portrait_b.modulate.a = a
		if a >= 1.0:
			portrait_a.texture = portrait_b.texture
			portrait_b.modulate.a = 0.0
			_fade_from = -1.0
			_log("faded", {"segment": _seg})
	overlay.text = "t %5d ms   segment %d   %s" % [int(t_ms), _seg, segments[_seg].get("emotion", "") if _seg >= 0 else ""]
	_capture_due()
	if t_ms >= duration_ms + TAIL_MS and _grab == "" and _captures.is_empty():
		playing = false
		audio.stop()
		_log("end", {})
		finished.emit()


func _enter(i: int) -> void:
	_seg = i
	var emotion: String = segments[i].get("emotion", "neutral")
	subtitle.text = " ".join(segments.slice(0, i + 1).map(func(s): return str(s.get("text", ""))))
	var e := cache.portrait_for(entity, emotion, years)
	var shown: String = e.get("key", {}).get("emotion", "")
	_log("segment", {"segment": i, "emotion": emotion, "shown": shown, "sha256": e.get("sha256", ""), "offset_ms": offsets[i]})
	if e.is_empty():
		_log("missing_portrait", {"emotion": emotion})
		return
	if e["sha256"] == _shown_sha:
		return
	var tex := _texture(e)
	if tex == null:
		_log("missing_blob", {"kind": "portrait", "sha256": e["sha256"]})
		return
	_shown_sha = e["sha256"]
	if portrait_a.texture == null:
		portrait_a.texture = tex # the opening portrait: no fade
	else:
		if _fade_from >= 0.0: # a swap during a fade: the fade's target is shown at once
			portrait_a.texture = portrait_b.texture
		portrait_b.texture = tex
		portrait_b.modulate.a = 0.0
		_fade_from = float(offsets[i]) + swap_offset_ms
	_log("swap", {"segment": i, "shown": shown, "sha256": e["sha256"]})
	if _out != "":
		_captures.append({"due": float(offsets[i]) + swap_offset_ms + crossfade_ms, "name": "swap_%d_%s.png" % [i, shown]})


func _texture(e: Dictionary) -> Texture2D:
	if _textures.has(e["sha256"]):
		return _textures[e["sha256"]]
	var path := cache.blob_path(e)
	var img := Image.new()
	if not FileAccess.file_exists(path) or img.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) != OK:
		return null
	var tex := ImageTexture.create_from_image(img)
	_textures[e["sha256"]] = tex
	return tex


func _log(event: String, fields: Dictionary) -> void:
	var x := {"t_ms": int(round(t_ms)), "event": event}
	x.merge(fields)
	timeline.append(x)


func events_named(event: String) -> Array:
	return timeline.filter(func(x): return x["event"] == event)


# ---------------------------------------------------------------- style frame

## A capture falls due on the frame its fade completes; the viewport's image
## is the last frame drawn, so it is taken on the next frame.
func _capture_due() -> void:
	if _grab != "":
		get_viewport().get_texture().get_image().save_png(_out.path_join(_grab))
		_log("capture", {"file": _grab})
		_grab = ""
	if not _captures.is_empty() and t_ms >= _captures[0]["due"]:
		_grab = _captures.pop_front()["name"]


func _write_style_frame() -> void:
	var shots := []
	for x in events_named("capture"):
		var img := Image.load_from_file(_out.path_join(x["file"]))
		if img != null:
			shots.append(img)
	if not shots.is_empty():
		contact_sheet(shots, 2).save_png(_out.path_join("contact_sheet.png"))
	var v := events_named("start")
	var voice := cache.find_sha(_voice_sha) if _voice_sha != "" else {}
	if not voice.is_empty():
		DirAccess.copy_absolute(ProjectSettings.globalize_path(cache.blob_path(voice)), _out.path_join("line.ogg"))
		if audio_path != "": # the playback copy too: macOS players do not open Ogg Opus
			DirAccess.copy_absolute(ProjectSettings.globalize_path(audio_path), _out.path_join("line.wav"))
	var f := FileAccess.open(_out.path_join("timeline.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify({"crossfade_ms": crossfade_ms, "swap_offset_ms": swap_offset_ms, "segments": segments, "duration_ms": duration_ms,
		"start": v[0] if not v.is_empty() else {}, "log": timeline}, "  ") + "\n")
	f.close()
	get_tree().quit(0)



## Captures side by side, `cols` per row, each scaled to half size.
static func contact_sheet(shots: Array, cols: int) -> Image:
	var w: int = shots[0].get_width() / 2
	var h: int = shots[0].get_height() / 2
	var rows := (shots.size() + cols - 1) / cols
	var sheet := Image.create_empty(w * cols, h * rows, false, Image.FORMAT_RGBA8)
	sheet.fill(Color.BLACK)
	for i in shots.size():
		var s: Image = shots[i].duplicate()
		s.convert(Image.FORMAT_RGBA8)
		s.resize(w, h, Image.INTERPOLATE_BILINEAR)
		sheet.blit_rect(s, Rect2i(0, 0, w, h), Vector2i((i % cols) * w, (i / cols) * h))
	return sheet
