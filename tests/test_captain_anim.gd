extends SceneTree
## R2-CAPTAIN-ANIMATION CA0 (design_docs/planned/r2/captain-animation.md §D2, §D4; AC1, AC2): the
## CaptainAnim state on scripted inputs, and CaptainAvatar's frame and still choice. Headless:
##   godot --headless --path . --script tests/test_captain_anim.gd      (make captain-anim-test)
## The views: Bow looks toward the bow (-z, yaw -90 deg, as CameraDirector.walk_yaw returns for the
## Bow view); Astern is its mirror (+90 deg).

const BOW_YAW := -PI / 2.0
const ASTERN_YAW := PI / 2.0
const BOW := Vector3(0, 0, -1)
const CAPTAIN := "res://assets/characters/captain"
const FIXTURE := "res://tests/fixtures/captain_anim"
const DT := 1.0 / 60.0
var failures := 0
var passes := 0


func check(name: String, ok: bool, detail := "") -> void:
	if ok:
		passes += 1
		print("ok   ", name)
	else:
		failures += 1
		print("FAIL ", name, (": " + detail) if detail != "" else "")


func _initialize() -> void:
	_sectors()
	_moonwalk()
	_phase()
	_transitions()
	_stations_chair_lift()
	_reduced_and_cues()
	_determinism()
	_gait_from_clip()
	_speed()
	_feet_on_floor()
	_between_frames()
	_avatar()
	print("captain-anim: %d passed, %d failures" % [passes, failures])
	quit(1 if failures else 0)


## The screen direction on the deck for a view yaw: the view's right and forward.
static func deck(view_yaw: float, screen: Vector2) -> Vector3:
	var fwd := Vector3(cos(view_yaw), 0, sin(view_yaw))
	var right := Vector3(-sin(view_yaw), 0, cos(view_yaw))
	return right * screen.x + fwd * screen.y


func _sectors() -> void:
	check("sector: up-screen is 0 (away)", CaptainAnim.sector_of(Vector2(0, 1)) == 0)
	check("sector: right is 2, toward is 4, left is 6", CaptainAnim.sector_of(Vector2(1, 0)) == 2 and CaptainAnim.sector_of(Vector2(0, -1)) == 4 and CaptainAnim.sector_of(Vector2(-1, 0)) == 6)
	check("sector: the diagonals are 1, 3, 5, 7", CaptainAnim.sector_of(Vector2(1, 1)) == 1 and CaptainAnim.sector_of(Vector2(1, -1)) == 3 and CaptainAnim.sector_of(Vector2(-1, -1)) == 5 and CaptainAnim.sector_of(Vector2(-1, 1)) == 7)
	var at30 := Vector2(sin(deg_to_rad(30.0)), cos(deg_to_rad(30.0)))
	var at35 := Vector2(sin(deg_to_rad(35.0)), cos(deg_to_rad(35.0)))
	check("hysteresis: 30 deg keeps sector 0 (edge 22.5 + 10)", CaptainAnim.sector_of(at30, 0) == 0)
	check("hysteresis: 35 deg leaves sector 0 for 1", CaptainAnim.sector_of(at35, 0) == 1)
	check("hysteresis: 30 deg from no previous sector is 1", CaptainAnim.sector_of(at30) == 1)
	check("sector: a zero direction keeps the previous sector", CaptainAnim.sector_of(Vector2.ZERO, 5) == 5)
	var sd := CaptainAnim.screen_dir(BOW, BOW_YAW)
	check("Bow: walking to the bow is up-screen", sd.distance_to(Vector2(0, 1)) < 1e-6, str(sd))
	sd = CaptainAnim.screen_dir(BOW, ASTERN_YAW)
	check("Astern: walking to the bow is down-screen", sd.distance_to(Vector2(0, -1)) < 1e-6, str(sd))


## AC2: a walk to the ship's starboard shows a side facing, never the back, in both views.
func _moonwalk() -> void:
	for view in [["Bow", BOW_YAW], ["Astern", ASTERN_YAW]]:
		var a := CaptainAnim.new()
		a.heading = BOW
		var starboard := deck(BOW_YAW, Vector2(1, 0)) # the ship's starboard, fixed in the ship
		var side := 0
		var back := 0
		var n := 90
		for k in n:
			var o := a.step({"velocity": starboard * 3.5, "view_yaw": view[1]}, DT)
			if o.facing == "profile":
				side += 1
			if o.facing == "back":
				back += 1
		check("%s: a starboard walk shows the profile in >= 95%% of frames (AC2)" % view[0], side >= int(0.95 * n), "%d/%d" % [side, n])
		check("%s: a starboard walk never shows the back" % view[0], back == 0, str(back))
	var a := CaptainAnim.new()
	var o := a.step({"velocity": deck(BOW_YAW, Vector2(1, 0)) * 3.5, "view_yaw": BOW_YAW}, DT)
	var o2 := a.step({"velocity": deck(ASTERN_YAW, Vector2(1, 0)) * 3.5, "view_yaw": ASTERN_YAW}, DT)
	check("screen right is the painted profile, screen left its mirror", o.facing == "profile" and not o.flip and o2.facing == "profile" and not o2.flip)
	o = a.step({"velocity": deck(BOW_YAW, Vector2(-1, 0)) * 3.5, "view_yaw": BOW_YAW}, DT)
	check("walking left on screen mirrors the profile", o.facing == "profile" and o.flip, str(o.sector))
	o = a.step({"velocity": deck(BOW_YAW, Vector2(-1, 1).normalized()) * 3.5, "view_yaw": BOW_YAW}, DT)
	check("away-left mirrors back_34", o.facing == "back_34" and o.flip, str(o.sector))
	var r := CaptainAnim.new()
	r.step({"velocity": BOW * 3.5, "view_yaw": BOW_YAW}, DT)
	o = r.step({"velocity": Vector3.ZERO, "view_yaw": ASTERN_YAW}, DT)
	check("at rest a view switch turns the drawing, not the captain (bow-facing shows the front in Astern)", o.facing == "front", o.facing)


func _phase() -> void:
	var a := CaptainAnim.new()
	for k in 120:
		a.step({"velocity": Vector3.ZERO, "view_yaw": BOW_YAW}, DT)
	check("no distance, no advance", a.phase == 0.0, str(a.phase))
	a.step({"velocity": BOW * 0.15, "view_yaw": BOW_YAW}, 1.0)
	check("below 0.2 m/s the captain stands (no phase)", a.phase == 0.0 and a.clip == "idle", "%s %s" % [a.phase, a.clip])
	var b := CaptainAnim.new()
	var c := CaptainAnim.new()
	for k in 60:
		b.step({"velocity": BOW * 3.5, "view_yaw": BOW_YAW}, DT)
	for k in 120:
		c.step({"velocity": BOW * 3.5, "view_yaw": BOW_YAW}, DT / 2.0)
	var want := fposmod(3.5 * 1.0 / CaptainAnim.DEFAULT_CYCLE_M, 1.0)
	check("phase = distance / cycle (1 s at 3.5 m/s)", absf(b.phase - want) < 1e-6, "%f vs %f" % [b.phase, want])
	check("the phase does not depend on the frame rate", absf(b.phase - c.phase) < 1e-6, "%f vs %f" % [b.phase, c.phase])
	var e := CaptainAnim.new()
	var sides: Array = []
	var steps := int(ceil(CaptainAnim.DEFAULT_CYCLE_M / 3.5 / DT))
	for k in steps:
		for ev: Dictionary in e.step({"velocity": BOW * 3.5, "view_yaw": BOW_YAW}, DT).events:
			if ev.type == "foot_down":
				sides.append(ev.side)
	check("one cycle plants each foot once, alternating", sides == ["R", "L"] or sides == ["L", "R"], str(sides))


func _transitions() -> void:
	var a := CaptainAnim.new()
	var clips: Array = []
	for k in 30:
		clips.append(a.step({"velocity": BOW * 3.5, "view_yaw": BOW_YAW}, DT).clip)
	check("starting: start for 0.25 s, then walk", clips[0] == "start" and clips[14] == "start" and clips[16] == "walk" and clips[29] == "walk", str(clips))
	clips.clear()
	for k in 30:
		clips.append(a.step({"velocity": Vector3.ZERO, "view_yaw": BOW_YAW}, DT).clip)
	check("stopping: stop for 0.3 s, then idle", clips[0] == "stop" and clips[17] == "stop" and clips[19] == "idle", str(clips))
	var o := a.step({"velocity": Vector3.ZERO, "view_yaw": BOW_YAW}, DT)
	check("a clip change is an event only once", o.events.is_empty(), str(o.events))


func _stations_chair_lift() -> void:
	var a := CaptainAnim.new()
	a.step({"velocity": deck(BOW_YAW, Vector2(1, 0)) * 3.5, "view_yaw": BOW_YAW}, DT)
	var o := a.step({"velocity": Vector3.ZERO, "view_yaw": BOW_YAW, "station": "use_low", "face_dir": BOW}, DT)
	check("at a station: the use clip, facing the bow (the back in Bow)", o.clip == "use_low" and o.facing == "back", "%s %s" % [o.clip, o.facing])
	o = a.step({"velocity": Vector3.ZERO, "view_yaw": ASTERN_YAW, "station": "use_low", "face_dir": BOW}, DT)
	check("at a station in Astern: the front", o.facing == "front", o.facing)
	var c := CaptainAnim.new()
	o = c.step({"view_yaw": BOW_YAW, "chair": "sit", "face_dir": BOW}, DT)
	check("sit, holding movement", o.clip == "sit" and o.hold_move, o.clip)
	for k in 40:
		o = c.step({"view_yaw": BOW_YAW, "face_dir": BOW}, DT)
	check("seated after 0.6 s", o.clip == "seated", o.clip)
	o = c.step({"view_yaw": BOW_YAW, "face_dir": BOW, "move_request": true, "velocity": BOW * 3.5}, DT)
	check("a move key stands first (no walking while standing)", o.clip == "stand" and o.hold_move and c.phase == 0.0, "%s %s" % [o.clip, c.phase])
	for k in 32:
		o = c.step({"view_yaw": BOW_YAW}, DT)
	check("free after 0.5 s", o.clip == "idle" and not o.hold_move, o.clip)
	o = CaptainAnim.new().step({"view_yaw": BOW_YAW, "lift": true}, DT)
	check("riding the lift: the lift clip", o.clip == "lift", o.clip)


func _reduced_and_cues() -> void:
	var a := CaptainAnim.new()
	var bob := 0.0
	for k in 40:
		bob = maxf(bob, a.step({"velocity": BOW * 3.5, "view_yaw": BOW_YAW}, DT).bob_m)
	check("walking bobs the stills about 1 cm", bob > 0.006 and bob <= CaptainAnim.BOB_M + 1e-9, str(bob))
	var r := CaptainAnim.new()
	var rbob := 0.0
	var lean := 0.0
	for k in 40:
		var o := r.step({"velocity": BOW * 3.5, "view_yaw": BOW_YAW, "reduced": true}, DT)
		rbob = maxf(rbob, o.bob_m)
		lean = maxf(lean, absf(o.lean_deg))
	check("reduced motion: no bob, no lean", rbob == 0.0 and lean == 0.0)
	check("reduced motion keeps the stride", r.phase > 0.0 and r.clip == "walk")
	var c := CaptainAnim.new()
	var o := c.step({"view_yaw": BOW_YAW, "cue": "look_up"}, DT)
	check("a look-up cue at rest", o.clip == "look_up", o.clip)
	for k in 125:
		o = c.step({"view_yaw": BOW_YAW}, DT)
	check("the look-up ends after 2 s", o.clip == "idle", o.clip)
	o = CaptainAnim.new().step({"view_yaw": BOW_YAW, "cue": "look_up", "reduced": true}, DT)
	check("reduced motion: no look-up", o.clip == "idle", o.clip)


func _determinism() -> void:
	var outs: Array = []
	for run in 2:
		var a := CaptainAnim.new()
		var log := []
		for k in 600:
			var t := k * DT
			var v := deck(BOW_YAW, Vector2(sin(t * 0.7), cos(t * 0.3))) * (3.5 if int(t * 2.0) % 5 != 0 else 0.0)
			var o := a.step({"velocity": v, "view_yaw": BOW_YAW if k < 300 else ASTERN_YAW, "cue": "look_up" if k == 450 else "",
				"station": "use_mid" if k > 520 else "", "face_dir": BOW}, DT)
			log.append([o.clip, snappedf(o.phase, 1e-9), o.sector, o.flip, snappedf(o.bob_m, 1e-9), o.events])
		outs.append(JSON.stringify(log))
	check("the same inputs give the same outputs (600 frames)", outs[0] == outs[1])


func _avatar() -> void:
	var av := CaptainAvatar.new()
	check("the stills load", av.load_dir(CAPTAIN), av.last_error)
	av.load_anim(FIXTURE)
	av.stage = 20 # no painted frames at this stage: the stills
	var cases := [[0, "back", false], [1, "ne", false], [2, "se", false], [4, "front", false], [6, "se", true], [7, "ne", true]]
	for c in cases:
		var a := CaptainAnim.new()
		av.show_anim({"clip": "idle", "sector": c[0], "facing": CaptainAnim.PAINTED[c[0]][0], "flip": CaptainAnim.PAINTED[c[0]][1]})
		var want: String = c[1]
		check("sector %d without painted frames shows the still %s%s" % [c[0], want, " mirrored" if c[2] else ""], av.shown.source == "still" and av.facing == want and av.flip_h == c[2], str(av.shown))
		var r := av.get_item_rect()
		var anchor_x := (r.position.x + (av.canvas_px.x - av.anchor_px.x if av.flip_h else av.anchor_px.x)) * av.pixel_size
		check("sector %d: the foot anchor stays on the walk point" % c[0], absf(anchor_x) < 1e-6 and absf((r.position.y + av.canvas_px.y - av.anchor_px.y) * av.pixel_size) < 1e-6)
	av.stage = 0
	# The fixture paints walk in back (4 frames + 4 mirrored) and profile.
	var o := {"clip": "walk", "sector": 0, "facing": "back", "flip": false, "phase": 0.6}
	av.show_anim(o)
	check("a painted facing shows its frame by phase (0.6 of 8 -> 4)", av.shown.source == "frame" and av.shown.frame == 4, str(av.shown))
	check("frame 4 is frame 0 mirrored (the half cycle)", av.shown.file == "jog_back_00.png" and av.shown.flip, str(av.shown))
	var s: float = av.anim.cell_scale
	var crop: Array = av.anim.clips.walk.stages["0"].back[4].crop
	var r := av.get_item_rect()
	var ax := av.anchor_px.x * s
	check("a mirrored cell keeps the anchor on the walk point", absf(r.position.x - (ax - crop[0] - crop[2])) < 1e-6, "%s" % r)
	av.show_anim({"clip": "start", "sector": 2, "facing": "profile", "flip": false, "phase": 0.0})
	check("start falls back to the painted walk", av.shown.source == "frame" and av.shown.clip == "walk", str(av.shown))
	av.show_anim({"clip": "walk", "sector": 3, "facing": "front_34", "flip": false, "phase": 0.0})
	check("an unpainted facing falls back to the still", av.shown.source == "still" and av.facing == "se", str(av.shown))
	av.show_anim({"clip": "idle", "sector": 2, "facing": "profile", "flip": false, "clip_t": 0.0, "bob_m": 0.02})
	check("a painted frame ignores the procedural bob (it carries its own)", av.shown.source == "frame" and absf((av.get_item_rect().position.y - (s * av.anchor_px.y - (crop_of(av, "idle", "profile")[1] + crop_of(av, "idle", "profile")[3]))) * av.pixel_size) < 1e-6, str(av.get_item_rect()))
	av.stage = 20
	av.show_anim({"clip": "idle", "sector": 0, "facing": "back", "flip": false, "bob_m": 0.01})
	check("a still lifts by the bob (0.01 m)", av.shown.source == "still" and absf((av.get_item_rect().position.y - (av.anchor_px.y - av.canvas_px.y)) * av.pixel_size - 0.01) < 1e-6, str(av.get_item_rect()))
	av.stage = 0
	av.free()


static func crop_of(av: CaptainAvatar, clip: String, f: String) -> Array:
	return av.anim.clips[clip].stages["0"][f][0].crop


func _gait_from_clip() -> void:
	var a := CaptainAnim.new()
	a.use_gait({"cycle_m": 2.5455, "contacts": [[0.0, "L"], [0.5, "R"]]})
	for k in 60:
		a.step({"velocity": BOW * 3.5, "view_yaw": BOW_YAW}, DT)
	check("use_gait: the phase follows the clip's cycle (1 s at 3.5 m/s over 2.5455 m)", absf(a.phase - fposmod(3.5 / 2.5455, 1.0)) < 1e-6, str(a.phase))
	var b := CaptainAnim.new()
	b.use_gait({})
	check("use_gait: an empty clip keeps the default cycle", b.cycle_m == CaptainAnim.DEFAULT_CYCLE_M)


## D-115: one calm walking speed for WASD and walk-to.
func _speed() -> void:
	check("the captain walks calmly: 1.3 m/s (D-115)", is_equal_approx(ShipConsoles.WALK_SPEED_MPS, 1.3))
	check("the default cycle is the painted walk's (1.4857 m)", is_equal_approx(CaptainAnim.DEFAULT_CYCLE_M, 1.4857))


## D-118: on the billboard as the game draws it (show_anim's offset and pixel size), every painted frame's
## lowest sole rests on the walk point: never below the deck, at most the settle lift (15 mm) above it.
func _feet_on_floor() -> void:
	var av := CaptainAvatar.new()
	av.load_dir(CAPTAIN)
	av.load_anim(CAPTAIN, "anim_pilot.json")
	var worst_below := -INF
	var worst_above := INF
	var n := 0
	for clip: String in av.anim.get("clips", {}):
		var c: Dictionary = av.anim.clips[clip]
		for facing: String in c.stages["0"]:
			var frames: Array = c.stages["0"][facing]
			for i in frames.size():
				var o := {"clip": clip, "facing": facing, "flip": false, "sector": 0, "phase": (i + 0.5) / frames.size(), "clip_t": float(i) / float(c.get("fps", 2.0))}
				av.show_anim(o)
				var img: Image = av.texture.get_image()
				if img.is_compressed():
					img.decompress()
				var low := -1
				for y in range(img.get_height() - 1, -1, -1):
					for x in img.get_width():
						if img.get_pixel(x, y).a > 0.5:
							low = y
							break
					if low >= 0:
						break
				# Sprite3D local pixels, y up: the rect's bottom edge is offset.y.
				var sole_m := (av.get_item_rect().position.y + (img.get_height() - (low + 1))) * av.pixel_size
				worst_below = maxf(worst_below, -sole_m)
				worst_above = minf(worst_above, -sole_m)
				n += 1
	check("feet on the floor: %d painted frames, no sole below the deck (worst %.4f m)" % [n, maxf(0.0, worst_below)], n > 0 and worst_below <= 1e-6)
	check("feet on the floor: no sole more than the settle lift (2 cell px, 15 mm; about 1 px at 1440p) above the deck (%.4f m)" % maxf(0.0, -worst_above), -worst_above <= 0.0155)
	av.free()


## D-118: the between-frame effect: on a walking painted clip only, off under reduced motion, `t` from the
## walk phase (1 at a frame change, 0 after EFFECT_MS), deterministic, and the canvas keeps the feet down.
func _between_frames() -> void:
	var av := CaptainAvatar.new()
	av.load_dir(CAPTAIN)
	av.load_anim(CAPTAIN, "anim_pilot.json")
	var walk: Dictionary = av.anim.get("clips", {}).get("walk", {})
	if walk.is_empty():
		check("between frames: the pilot has a walk clip", false)
		av.free()
		return
	var n: int = walk.stages["0"].back.size()
	var frame_ms := 1000.0 * float(walk.cycle_m) / n / 1.3
	for fx: String in ["echo", "trail", "blur"]:
		av.effect = fx
		var o := {"clip": "walk", "facing": "profile", "flip": false, "sector": 2, "phase": 3.0 / n + 1e-6, "speed": 1.3, "screen_dir": Vector2(1, 0)}
		av.show_anim(o)
		check("%s: drawn through the effect shader on the walk" % fx, av.material_override != null and av.shown.get("effect", "") == fx)
		check("%s: t is 1 at a frame change" % fx, absf(float(av.shown.effect_t) - 1.0) < 1e-3, str(av.shown.effect_t))
		o.phase = 3.0 / n + (30.0 / frame_ms) / n
		av.show_anim(o)
		check("%s: t is 0.5 after 30 ms of walking" % fx, absf(float(av.shown.effect_t) - 0.5) < 1e-3, str(av.shown.effect_t))
		o.reduced = true
		av.show_anim(o)
		check("%s: off under reduced motion" % fx, av.material_override == null)
	av.effect = "echo"
	av.show_anim({"clip": "idle", "facing": "back", "flip": false, "sector": 0, "clip_t": 0.0})
	check("the effect is off on the idle clip", av.material_override == null)
	# On the canvas the sole still rests on the walk point (the canvas carries the settled crop).
	av.show_anim({"clip": "walk", "facing": "back", "flip": true, "sector": 0, "phase": 0.5, "speed": 1.3, "screen_dir": Vector2(0, 1)})
	var img: Image = av.texture.get_image()
	var low := -1
	for y in range(img.get_height() - 1, -1, -1):
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.5:
				low = y
				break
		if low >= 0:
			break
	var sole_m := (av.get_item_rect().position.y + (img.get_height() - (low + 1))) * av.pixel_size
	check("on the effect's canvas the sole still rests on the walk point (%.4f m, the 15 mm lift)" % sole_m, sole_m >= 0.0 and sole_m <= 0.0155)
	av.free()
