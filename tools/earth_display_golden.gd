extends SceneTree
## Gate2 for shipped comms feed/strip and map beams; not the complete EL5 voyage/report.
## Real CanvasItem GPU readback vs independent CPU pixel/colour references; make golden prereq.
const Observe := preload("res://physics/observe.gd")
const Strip := preload("res://ui/earth_strip.gd")
const BeamLayer := preload("res://ui/earth_beams.gd")
const FIXTURE := "res://tests/fixtures/earth_link/strip.json"
const BEAMS := "res://tests/fixtures/earth_link/beams.json"
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
func centroid(image: Image, expected: Vector2, target := StapledonTheme.TEAL_LIGHT) -> Vector2:
	var sum := Vector2.ZERO; var weight := 0.
	var box := Rect2i(Vector2i(expected)-Vector2i(8,8),Vector2i(17,17)).intersection(Rect2i(Vector2i.ZERO,image.get_size()))
	for y in range(box.position.y,box.end.y):
		for x in range(box.position.x,box.end.x):
			var c := image.get_pixel(x,y)
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
## Independent reference: D-28 world=(-gy,gz,-gx); camera at world(0,30,0),
## looking down -Y with -Z up, 60-degree vertical FOV, 800x600. No production
## project(), unproject_position(), to_world() or element data enters this oracle.
func xyz(p: Dictionary) -> Array: return [float(p.x),float(p.y),float(p.z)]
func times(p: Array, k: float) -> Array: return [p[0]*k,p[1]*k,p[2]*k]
func cpu_pixel(p: Array) -> Vector2:
	var focal := 300./tan(PI/6.); var depth := 30.-float(p[2])
	return Vector2(400.-float(p[1])*focal/depth,300.-float(p[0])*focal/depth)
func beam_reference(v: Dictionary) -> Array:
	var e: Dictionary=v.earth; var rows: Array=[]; var zero: Array=[0.,0.,0.]
	if v.journey.state=="planned":
		if e.preview is Dictionary:
			rows.append({"kind":"preview","a":zero,"b":xyz(e.preview.port),"front":null})
			if e.preview.would_stale is Dictionary: rows.append({"kind":"stale","a":zero,"b":times(xyz(e.preview.would_stale.port),1.6),"front":null})
		return rows
	if e.beam is Dictionary:
		var port:=xyz(e.beam.port); var d:=Observe.norm(port); var radius:=maxf(0.,v.clock.t-e.beam.heard_t)
		rows.append({"kind":"beam","a":zero,"b":times(port,1.6),"front":times(port,radius/d) if radius<=d*1.6 else null})
	for pending: Dictionary in e.pending:
		var front: Variant=null
		for msg: Dictionary in e.messages:
			if msg.sent_t==pending.sent_t and msg.port_id==pending.port_id:
				var from:=xyz(msg.from); var d:=Observe.norm(from)
				if d>0.: front=times(from,clampf(pending.heard_t-v.clock.t,0.,d)/d)
		rows.append({"kind":"pending","a":zero,"b":xyz(pending.port),"front":front})
	for stale: Dictionary in e.stale: rows.append({"kind":"stale","a":zero,"b":times(xyz(stale.port),1.6),"front":null})
	if e.window is Dictionary: rows.append({"kind":"window","a":xyz(e.window.port),"b":xyz(e.window.port),"front":null})
	if not e.in_beam and e.last_beam_t!=null: rows.append({"kind":"silence","a":zero,"b":zero,"front":null})
	return rows
func ring_error(image: Image, centre: Vector2, radius: float) -> float:
	var total:=0.; var sum:=Vector2.ZERO; var r2:=0.
	for y in image.get_height():
		for x in image.get_width():
			var w:=image.get_pixel(x,y).get_luminance()
			if w<.01: continue
			var p:=Vector2(x+.5,y+.5); total+=w; sum+=p*w; r2+=p.distance_squared_to(centre)*w
	return maxf((sum/total).distance_to(centre),absf(sqrt(r2/total)-radius)) if total>1. else INF
func line_error(image: Image, a: Vector2, b: Vector2) -> float:
	var delta:=b-a; var length:=delta.length(); var normal:=Vector2(-delta.y,delta.x)/length
	var sum:=0.; var total:=0.
	for y in image.get_height():
		for x in image.get_width():
			var p:=Vector2(x+.5,y+.5)-a; var t:=p.dot(delta)/delta.length_squared(); var off:=p.dot(normal)
			if t<.25 or t>.75 or absf(off)>4.: continue
			var w:=image.get_pixel(x,y).get_luminance(); sum+=off*w; total+=w
	return absf(sum/total) if total>1. else INF
func _beam_cases() -> void:
	var fixture: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(BEAMS))
	var math_ok:=true
	for state: Dictionary in fixture.states:
		for msg: Dictionary in state.view.earth.messages:
			# At Sol heard_t=sent_t is the protocol's explicit at-home convention.
			if msg.sent_t>0.: math_ok=math_ok and absf(msg.heard_t-msg.sent_t-Observe.norm(xyz(msg.from)))<1e-10
			math_ok=math_ok and absf(msg.reply_t-msg.heard_t-Observe.norm(xyz(msg.port)))<1e-10
			math_ok=math_ok and msg.arrive_t-msg.sent_t>=Observe.norm(Observe.sub(xyz(msg.port),xyz(msg.from)))
	check("G-EL-3 real-sim fixture light times and finite legs validated",math_ok)
	var vp:=viewport(Vector2i(800,600)); var camera:=Camera3D.new(); vp.add_child(camera)
	camera.position=Vector3(0,30,0); camera.rotation_degrees=Vector3(-90,0,0); camera.fov=60.; camera.current=true
	var layer:=BeamLayer.new(); vp.add_child(layer)
	var overlay:=Control.new(); overlay.size=vp.size; vp.add_child(overlay)
	overlay.draw.connect(func()->void: layer.draw_on(overlay,camera,func(p: Vector3)->Vector3: return Starfield.galactic_to_world(p)))
	await process_frame
	for state: Dictionary in fixture.states:
		layer.refresh(state.view); overlay.queue_redraw()
		for label: Node in layer.get_children(): (label as Control).hide()
		var image:=await grab(vp); image.save_png(OUT.path_join("beams_%s.png"%state.id))
		var expected:=beam_reference(state.view); var projected:=layer.project(camera,Starfield.galactic_to_world)
		var worst:=0. if projected.size()==expected.size() else INF
		for i in mini(projected.size(),expected.size()):
			var row: Dictionary=expected[i]; var got: Dictionary=projected[i]
			if got.kind!=row.kind: worst=INF
			for key: String in ["a","b","front"]:
				if row[key]==null:
					if got[key]!=null: worst=INF
				elif got[key]==null: worst=INF
				else: worst=maxf(worst,(got[key] as Vector2).distance_to(cpu_pixel(row[key])))
		check("G-EL-3 map %s independent CPU endpoints/fronts <=0.5px"%state.id,worst<=.5,{"max_px":worst})
		var original: Array=layer.elements.duplicate(true); var errors: Dictionary={}
		for i in expected.size():
			var row: Dictionary=expected[i]; var el: Dictionary=original[i]
			# Isolate real production primitives; all drawing still goes through draw_on.
			layer.elements=[el]; overlay.queue_redraw(); image=await grab(vp)
			var error:=0.; var a:=cpu_pixel(row.a); var b:=cpu_pixel(row.b)
			if row.front!=null:
				var color:=Color("E0B066" if row.kind=="beam" else "8FD3D0")
				if row.kind=="beam" and el.get("left",false): color=Color("A99FBD")
				error=centroid(image,cpu_pixel(row.front),color).distance_to(cpu_pixel(row.front))
			if row.kind=="window": error=maxf(error,ring_error(image,a,15.))
			elif row.kind=="silence": error=maxf(error,ring_error(image,cpu_pixel([0.,0.,0.]),(state.view.clock.t-state.view.earth.last_beam_t)*300./tan(PI/6.)/30.))
			elif row.kind!="stale" or el.get("line",true): error=maxf(error,line_error(image,a,b))
			errors[row.kind]=error
		var gpu_worst:=0.
		for error: float in errors.values(): gpu_worst=maxf(gpu_worst,error)
		check("G-EL-3 map %s actual GPU fronts/line centres/rings <=0.5px"%state.id,gpu_worst<=.5,errors)
		if state.id=="preview":
			layer.elements=original; overlay.queue_redraw(); var clean:=await grab(vp)
			var poisoned: Dictionary=state.view.duplicate(true)
			for key: String in poisoned.earth:
				if key!="preview": poisoned.earth[key]=null
			layer.refresh(poisoned)
			for label: Node in layer.get_children(): (label as Control).hide()
			overlay.queue_redraw(); var isolated:=await grab(vp)
			check("G-EL-3 preview reads only preview and GPU ignores all live-link fields",layer.read==["preview"] and clean.get_data()==isolated.get_data())
		if state.id=="offray":
			# A real overlay displacement must fail the very same ring detector.
			layer.elements=[original.filter(func(el: Dictionary)->bool:return el.kind=="window")[0]]
			overlay.position.x=3.; overlay.queue_redraw()
			check("G-EL-N3 displaced production map fails independent geometry guard",ring_error(await grab(vp),cpu_pixel(xyz(state.view.earth.window.port)),15.)>.5)
	vp.queue_free(); await process_frame
func _feed_cases() -> void:
	var vp := viewport(Vector2i(320,180)); var feed := EarthFeed.new(); feed.size=vp.size; vp.add_child(feed)
	var neutral := Image.create_empty(320,180,false,Image.FORMAT_RGBA8); neutral.fill(Color(64./255.,64./255.,64./255.))
	var neutral_texture := ImageTexture.create_from_image(neutral)
	# R3-TRUE-PROCESSED (RS-Q5, standing order 2026-10-30): the decoded picture keeps its colours at
	# every D, so the GPU must show the neutral frame unchanged at each RS rate (no wash, no modulation).
	var cases := [["RS26",.01,1.],["RS27",.001,1.],["RS28",.000001,1.],["rest",1.,1.],["RS29",.01,-1.],["RS30",.000001,-1.]]
	var expected := Color(64./255.,64./255.,64./255.)
	for row: Array in cases:
		var omb: float=row[1]; var phi:=.5*log((2.-omb)/omb)
		var rate: float=Observe.earth_rate([40.,0.,0.],[row[2],0.,0.],phi)
		var record := {"frame":0,"kind":"sky","event":{"id":"","category":"sky","words":""},"pick":0}
		feed.refresh({"earth":{"rate":rate,"in_beam":true,"at_home":false,"newest_light_year":0.,"light_age_years":40.,"feed":record}})
		feed.picture.texture=neutral_texture; feed.history.clear()
		for ghost: TextureRect in feed.ghosts: ghost.hide()
		for label: Control in [feed.signal_tag,feed.clock_tag,feed.caption]: label.hide()
		var image:=await grab(vp); var got:=image.get_pixel(160,90)
		var error:=maxf(absf(got.r-expected.r),maxf(absf(got.g-expected.g),absf(got.b-expected.b)))
		check("G-EL-2 feed %s GPU shows the decoded frame unchanged (no wash)"%row[0],error<=2./255.,{"rate":rate,"error":error,"expected":[expected.r,expected.g,expected.b],"got":[got.r,got.g,got.b]})
		image.save_png(OUT.path_join("feed_%s.png"%str(row[0]).to_lower()))
	# R3-TRUE-PROCESSED-b: the Processed Doppler indicator, the bezel (pixel 2,90) and the edge overlay
	# bleeding in from it (pixel 7,90, 1.5 px into the screen), against an expected colour computed here,
	# independently of EarthFeed's helpers: lambda = 555 / D clamped to [400, 650] nm, the CIE fit to linear
	# sRGB (own matrix), negative channels clipped, unit max, sRGB-encoded; strength |ln D| / ln 1414.2;
	# the 2D canvas blends in sRGB. Receiver at RS-26 and RS-29, then each advanced (the drift, the jumbled
	# ghosts) so nothing animated reaches the bezel or covers the overlay; True: plain ink, no overlay.
	var ink:=Color(StapledonTheme.INK,1.)
	var neutral_c:=Color(64./255.,64./255.,64./255.)
	for row: Array in [["RS26",.01,1.,true,0.0],["RS29",.01,-1.,true,0.0],["RS29 True",.01,-1.,false,0.0],["RS26 advanced",.01,1.,true,10.0],["RS29 advanced",.01,-1.,true,0.3]]:
		var omb2: float=row[1]; var phi2:=.5*log((2.-omb2)/omb2)
		var rate2: float=Observe.earth_rate([40.,0.,0.],[row[2],0.,0.],phi2)
		var receiver: bool=row[3]
		feed.set_receiver(receiver)
		var rec2 := {"frame":0,"kind":"sky","event":{"id":"","category":"sky","words":""},"pick":0}
		feed.refresh({"earth":{"rate":rate2,"in_beam":true,"at_home":false,"newest_light_year":0.,"light_age_years":40.,"feed":rec2}})
		feed.picture.texture=neutral_texture
		feed.history.clear()
		if float(row[4])>0.0: feed.history.append_array([neutral_texture,neutral_texture])
		if float(row[4])>0.0: feed.advance(float(row[4]))
		else:
			for ghost: TextureRect in feed.ghosts: ghost.hide()
		for label: Control in [feed.signal_tag,feed.clock_tag,feed.caption,feed.doppler_tag]: label.hide()
		var lam:=clampf(555./rate2,400.,650.)
		var cm:=Blackbody.cmf(lam)
		var lin:=Vector3(maxf(3.2404542*cm.x-1.5371385*cm.y-0.4985314*cm.z,0.),maxf(-0.9692660*cm.x+1.8760108*cm.y+0.0415560*cm.z,0.),maxf(0.0556434*cm.x-0.2040259*cm.y+1.0572252*cm.z,0.))
		lin/=maxf(lin.x,maxf(lin.y,lin.z))
		var enc:=func(v: float) -> float: return v*12.92 if v<=0.0031308 else 1.055*pow(v,1./2.4)-0.055
		var col:=Color(enc.call(lin.x),enc.call(lin.y),enc.call(lin.z))
		var strength:=clampf(absf(log(rate2))/log(1414.2),0.,1.)
		var want_b: Color=ink.lerp(col,strength) if receiver else ink
		var w_px:=0.10*minf(vp.size.x-12.,vp.size.y-12.)
		var want_v: Color=neutral_c.lerp(col,strength*(1.-1.5/w_px)) if receiver else neutral_c
		var img2:=await grab(vp); var b2:=img2.get_pixel(2,90); var v2:=img2.get_pixel(7,90); var c2:=img2.get_pixel(160,90)
		var err:=func(p: Color, q: Color) -> float: return maxf(absf(p.r-q.r),maxf(absf(p.g-q.g),absf(p.b-q.b)))
		var be: float=err.call(b2,want_b); var ve: float=err.call(v2,want_v); var ce: float=err.call(c2,neutral_c)
		check("G-EL-2b feed %s: bezel %s, edge overlay %s, picture centre as decoded"%[row[0],"indicator" if receiver else "ink","fading in" if receiver else "absent"],be<=2./255. and ve<=3./255. and ce<=2./255.,{"rate":rate2,"bezel_error":be,"overlay_error":ve,"picture_error":ce,"want_bezel":[want_b.r,want_b.g,want_b.b],"got_bezel":[b2.r,b2.g,b2.b],"want_overlay":[want_v.r,want_v.g,want_v.b],"got_overlay":[v2.r,v2.g,v2.b]})
		img2.save_png(OUT.path_join("feed_bezel_%s.png"%str(row[0]).to_lower().replace(" ","_")))
	feed.set_receiver(true)
	# Negative control: the old stylised wash (#7F9CFF at 0.24) seeded over the picture must fail the same detector.
	var seeded := ColorRect.new(); seeded.color=Color(Color("7F9CFF"),.24); seeded.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); feed.add_child(seeded)
	var washed: Color=(await grab(vp)).get_pixel(160,90)
	check("G-EL-N2 a seeded colour wash is rejected",maxf(absf(washed.r-expected.r),maxf(absf(washed.g-expected.g),absf(washed.b-expected.b)))>2./255.)
	seeded.queue_free()
	vp.queue_free(); await process_frame
func _run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	await _strip_cases(); await _feed_cases(); await _beam_cases()
	FileAccess.open(OUT.path_join("evidence.json"),FileAccess.WRITE).store_string(JSON.stringify({"fixture_sha256":FileAccess.get_sha256(FIXTURE),"beams_fixture_sha256":FileAccess.get_sha256(BEAMS),"scope":"shipped strip/feed and map beams; strip analytic, map real-sim snapshots; complete EL5 voyage/report not claimed","cases":evidence,"passed":passed,"failed":failed},"  ")+"\n")
	print("earth-link-golden: %d passed, %d failures"%[passed,failed]); quit(1 if failed else 0)
