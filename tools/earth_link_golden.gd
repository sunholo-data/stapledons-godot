extends SceneTree
## Gate2 for the SHIPPED comms feed/strip only; no EL4 map and no complete-EL5 claim.
## Real CanvasItem GPU readback vs independent CPU pixel/colour references; make golden prereq.
const Observe := preload("res://physics/observe.gd")
const Strip := preload("res://ui/earth_strip.gd")
const FIXTURE := "res://tests/fixtures/earth_link/strip.json"
const OUT := "res://renders/earth_link_golden"
var passed := 0
var failed := 0
var evidence: Array = []
func _initialize() -> void: _run.call_deferred()
func check(label: String, ok: bool, details: Dictionary = {}) -> void:
	if ok: passed += 1
	else: failed += 1
	print("%s    %s" % ["ok" if ok else "FAIL", label])
	evidence.append({"label":label,"ok":ok,"details":details})
func viewport(size: Vector2i) -> SubViewport:
	var vp := SubViewport.new(); vp.size = size
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var bg := ColorRect.new(); bg.color = Color.BLACK; bg.size = size; vp.add_child(bg)
	return vp
func grab(vp: SubViewport) -> Image:
	for frame in 3: await process_frame
	await RenderingServer.frame_post_draw
	return vp.get_texture().get_image()
func point(values: Array) -> Vector2: return Vector2(float(values[0]),float(values[1]))
func centroid(image: Image, expected: Vector2) -> Vector2:
	var sum := Vector2.ZERO; var weight := 0.
	var box := Rect2i(Vector2i(expected)-Vector2i(8,8),Vector2i(17,17)).intersection(Rect2i(Vector2i.ZERO,image.get_size()))
	for y in range(box.position.y,box.end.y):
		for x in range(box.position.x,box.end.x):
			var c := image.get_pixel(x,y); var target := StapledonTheme.TEAL_LIGHT
			if maxf(absf(c.r-target.r),maxf(absf(c.g-target.g),absf(c.b-target.b))) < 2./255.:
				sum += Vector2(x+.5,y+.5); weight += 1.
	return sum/weight if weight>0. else Vector2(-1000,-1000)
func _strip_cases() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	var vp := viewport(Vector2i(600,116)); var strip := Strip.new(); strip.size = vp.size; vp.add_child(strip)
	for row: Dictionary in data.states:
		var view := {"clock":{"t":row.t},"earth":{"messages":[data.message],"light_age_years":row.distance,"newest_light_t":row.light_t}}
		strip.refresh(view)
		var worst := 0.
		for pair: Array in [[Vector2(100,40),"sent_px"],[Vector2(140,0),"heard_px"],[Vector2(190,50),"reply_px"],[Vector2(row.t,row.distance),"now_px"]]:
			worst = maxf(worst,strip.at(pair[0]).distance_to(point(row[pair[1]])))
		var image := await grab(vp)
		image.save_png(OUT.path_join("strip_%s.png"%row.id))
		# Keep the production reply strokes and marker; remove same-colour ship paths so
		# they cannot bias the measured marker centroid. No fake test marker is drawn.
		strip.elements = strip.elements.filter(func(e: Dictionary) -> bool: return e.kind=="reply")
		strip.queue_redraw(); image = await grab(vp)
		var expected := point(row.now_px); var measured := centroid(image,expected)
		var error := measured.distance_to(expected)
		check("G-EL-1 strip %s CPU endpoints and GPU ship marker <=0.5px"%row.id,worst<=.0001 and error<=.5,{"cpu_max_px":worst,"gpu_error_px":error,"expected":[expected.x,expected.y],"measured":[measured.x,measured.y]})
	# Prove the readback guard discriminates a displaced production control, not just math.
	strip.position.y = 3.; strip.queue_redraw()
	var shifted := centroid(await grab(vp),point(data.states[-1].now_px))
	check("G-EL-N1 three-pixel displaced production strip is rejected",shifted.distance_to(point(data.states[-1].now_px))>.5)
	vp.queue_free(); await process_frame
func _feed_cases() -> void:
	var vp := viewport(Vector2i(320,180)); var feed := EarthFeed.new(); feed.size=vp.size; vp.add_child(feed)
	var neutral := Image.create_empty(320,180,false,Image.FORMAT_RGBA8); neutral.fill(Color(64./255.,64./255.,64./255.))
	var neutral_texture := ImageTexture.create_from_image(neutral)
	# Independent documented wash constants. These intentionally do not read tint.color,
	# band.tint or band.tint_alpha, so a styling mutation cannot bless its own output.
	var cases := [["RS26",.01,1.,"F2967E",.14],["RS27",.001,1.,"F2967E",.14],["RS28",.000001,1.,"F2967E",.24],["rest",1.,1.,"F2967E",0.],["RS29",.01,-1.,"7F9CFF",.14],["RS30",.000001,-1.,"7F9CFF",.24]]
	var expected := Color.BLACK
	for row: Array in cases:
		var omb: float=row[1]; var phi:=.5*log((2.-omb)/omb)
		var rate: float=Observe.earth_rate([40.,0.,0.],[row[2],0.,0.],phi)
		var record := {"frame":0,"kind":"sky","event":{"id":"","category":"sky","words":""},"pick":0}
		feed.refresh({"earth":{"rate":rate,"in_beam":true,"at_home":false,"newest_light_year":0.,"light_age_years":40.,"feed":record}})
		feed.picture.texture=neutral_texture; feed.history.clear()
		for ghost: TextureRect in feed.ghosts: ghost.hide()
		for label: Control in [feed.signal_tag,feed.clock_tag,feed.caption]: label.hide()
		var tint := Color(str(row[3])); var alpha: float=row[4]
		expected=Color(64./255.,64./255.,64./255.).lerp(tint,alpha)
		var image:=await grab(vp); var got:=image.get_pixel(160,90)
		var error:=maxf(absf(got.r-expected.r),maxf(absf(got.g-expected.g),absf(got.b-expected.b)))
		check("G-EL-2 feed %s GPU indicator wash matches CPU composite"%row[0],error<=2./255.,{"rate":rate,"error":error,"expected":[expected.r,expected.g,expected.b],"got":[got.r,got.g,got.b]})
		image.save_png(OUT.path_join("feed_%s.png"%str(row[0]).to_lower()))
	feed.tint.hide()
	var missing: Color=(await grab(vp)).get_pixel(160,90)
	check("G-EL-N2 missing production tint is rejected",maxf(absf(missing.r-expected.r),maxf(absf(missing.g-expected.g),absf(missing.b-expected.b)))>2./255.)
	vp.queue_free(); await process_frame
func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	await _strip_cases(); await _feed_cases()
	FileAccess.open(OUT.path_join("evidence.json"),FileAccess.WRITE).store_string(JSON.stringify({"fixture_sha256":FileAccess.get_sha256(FIXTURE),"scope":"shipped strip/feed only; analytic fixture, not sim replay; map remains unfinished","cases":evidence,"passed":passed,"failed":failed},"  ")+"\n")
	print("earth-link-golden: %d passed, %d failures"%[passed,failed]); quit(1 if failed else 0)
