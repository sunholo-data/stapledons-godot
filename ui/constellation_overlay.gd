extends Control
## Chart connectors between the sky's current apparent star centres. No new physics.
const StarProjection = preload("res://sky/star_projection.gd")
const StarLight = preload("res://demos/ship_star_light.gd")
const PATH := "res://data/starmap/constellations.json"
const LINE := Color(.45,.78,.85,.30)
var figures: Array = []
var indices := {}
var missing_count := 0
var endpoints := {}
var segments: Array = []
var labels: Array = []
var identity_scans := 0
var _revision := -1
var _field: Starfield
var _signature: Array = []
var _samples := {}
var demo: Node
var identify: Control
var status := ""

func load_manifest() -> bool:
	return set_manifest(JSON.parse_string(FileAccess.get_file_as_string(PATH)))

func set_manifest(data: Variant) -> bool:
	figures.clear();indices.clear();clear_view();_revision=-1;_signature.clear();missing_count=0
	if not data is Dictionary or data.get("version")!=1 or not data.get("figures") is Array:return false
	var seen := {};var sources := {};var catalogue_sources := {}
	for f in data.figures:
		if not f is Dictionary or not f.get("id") is String or f.id.is_empty() or seen.has(f.id):return false
		if not f.get("name") is String or f.name.is_empty() or not f.get("endpoints") is Array or not f.get("segments") is Array:return false
		seen[f.id]=true
		var points := {}
		for p in f.endpoints:
			if not p is Dictionary or not p.get("id") is String or p.id.is_empty() or sources.has(p.id):return false
			if not p.get("catalogue_id") is String or p.catalogue_id.is_empty():return false
			var canonical: String=p.catalogue_id.trim_prefix("Gaia DR3 ")
			if catalogue_sources.has(canonical):return false
			catalogue_sources[canonical]=true
			points[p.id]=true;sources[p.id]=true
		for pair in f.segments:
			if not pair is Array or pair.size()!=2 or pair[0]==pair[1] or not points.has(pair[0]) or not points.has(pair[1]):return false
	# Install only after validating everything: malformed data cannot leave half a figure.
	figures=data.figures.duplicate(true)
	return not figures.is_empty()

func resolve(field: Starfield) -> void:
	indices.clear();_samples.clear();_signature.clear()
	var wanted := {};var counts := {}
	for figure in figures:
		for p in figure.endpoints:
			for alias in Starfield.aliases_of(p.catalogue_id):wanted[alias]=p.id
	for k in field.count:
		var id: String=field.ids[k]
		if not wanted.has(id) or id in field.pinned_ids:continue
		var key: String=wanted[id]
		counts[key]=counts.get(key,0)+1;indices[key]=k
	for key in counts:
		if counts[key]!=1:indices.erase(key)
	missing_count=0
	for figure in figures:missing_count+=figure.endpoints.size()
	missing_count-=indices.size()
	_field=field;_revision=field.identity_revision;identity_scans+=1

func clear_view() -> void:
	endpoints.clear();segments.clear();labels.clear()
	queue_redraw()

static func project_direction(direction: Vector3, view: Basis, focal: float, px: Vector2) -> Vector2:
	var local := view*direction
	if not local.is_finite() or local.z>=-1e-7:return Vector2(INF,INF)
	return px*.5+Vector2(-local.x/local.z,local.y/local.z)*focal

## Liang-Barsky in screen space: this is chart clipping, not a physical light path.
static func clip(a: Vector2, b: Vector2, rect: Rect2) -> PackedVector2Array:
	var delta := b-a;var lo := 0.;var hi := 1.
	for axis in 2:
		if absf(delta[axis])<1e-10:
			if a[axis]<rect.position[axis] or a[axis]>rect.end[axis]:return PackedVector2Array()
		else:
			var t0: float=(rect.position[axis]-a[axis])/delta[axis]
			var t1: float=(rect.end[axis]-a[axis])/delta[axis]
			lo=maxf(lo,minf(t0,t1));hi=minf(hi,maxf(t0,t1))
			if lo>hi:return PackedVector2Array()
	return PackedVector2Array([a+lo*delta,a+hi*delta])

## Conservative screen boxes enclosing the same apparent globe caps as the renderer.
## A cone is tangent to a sphere centred on its unit direction, radius sin(cap).
## Interval division bounds the projected sphere, including tilted/off-axis views.
static func body_boxes(sv: SystemView, view: Basis, focal: float, px: Vector2) -> Array:
	var boxes: Array=[]
	if sv==null or not sv.visible:return boxes
	for b: Dictionary in sv.rendered_bodies:
		var w := Planets.world_of(b.rel_km);var dist := Planets.length64(w)
		if dist<=b.radius_km or not is_finite(dist):continue
		var angle := Planets.angular_radius(b.radius_km,dist)
		if sv.relativistic_enabled and sv.velocity_beta>0.:
			var h := sv.velocity_heading
			angle=Planets.apparent_disc64((w[0]*h.x+w[1]*h.y+w[2]*h.z)/dist,angle,sv.velocity_beta,sv.velocity_gamma)[1]
		var n := StarLight.apparent_direction(sv,b.rel_km,b.radius_km)
		var local := view*Vector3(n[0],n[1],n[2]);var r := sin(angle);var depth := -local.z
		if depth+r<=0.:continue
		if depth-r<=0.:boxes.append(Rect2(Vector2.ZERO,px));continue
		var bounds := []
		for coord in [local.x,-local.y]:
			var values := [(coord-r)/(depth-r),(coord-r)/(depth+r),(coord+r)/(depth-r),(coord+r)/(depth+r)]
			bounds.append(Vector2(values.min(),values.max())*focal)
		boxes.append(Rect2(px*.5+Vector2(bounds[0].x,bounds[1].x),Vector2(bounds[0].y-bounds[0].x,bounds[1].y-bounds[1].x)).grow(2.))
	return boxes

func refresh(field: Starfield, camera: Camera3D, px: Vector2, sv: SystemView=null, gr := false) -> void:
	clear_view()
	if gr or px.x<=0. or px.y<=0.:return
	if field!=_field or _revision!=field.identity_revision:resolve(field)
	var ctx := StarProjection.context(field)
	var signature: Array=[field.identity_revision,field.replacement_revision,field.rebases,field.origin,ctx]
	if signature!=_signature:_samples.clear();_signature=signature
	var view := camera.global_basis.transposed()
	var focal := .5*px.y/tan(deg_to_rad(camera.fov)*.5)
	var boxes := body_boxes(sv,view,focal,px)
	for key in indices:
		var k: int=indices[key]
		# Finite replacements draw on a separate renderer path; omit rather than attach
		# a guide to a culled point copy or to a resolved sphere's rest direction.
		if field.ids[k] in field.pinned_ids or field.catalogue_replacement_sources.has(field.ids[k]):continue
		if not _samples.has(key):
			_samples[key]=StarProjection.direction(field,k,ctx)
		var sample: Dictionary=_samples[key]
		if sample.is_empty() or not StarProjection.visible(field,k,sample,ctx):continue
		var point := project_direction(sample.direction,view,focal,px)
		if point.is_finite():endpoints[key]=point
	for figure in figures:
		var anchor := Vector2(INF,INF)
		for pair in figure.segments:
			if not endpoints.has(pair[0]) or not endpoints.has(pair[1]):continue
			var a: Vector2=endpoints[pair[0]];var b: Vector2=endpoints[pair[1]]
			var line := clip(a,b,Rect2(Vector2.ZERO,px))
			if line.is_empty() or line[0].distance_squared_to(line[1])<1e-6:continue
			var blocked := false
			for box: Rect2 in boxes:
				if not clip(line[0],line[1],box).is_empty():blocked=true;break
			if blocked:continue
			segments.append({a=line[0],b=line[1],from=pair[0],to=pair[1],figure=figure.id})
			if not anchor.is_finite():
				for p in [a,b]:
					if Rect2(Vector2.ZERO,px).has_point(p):anchor=p;break
		if anchor.is_finite():labels.append({text=figure.name,point=anchor})

func setup(host: Node, inspector: Control) -> void:
	demo=host;identify=inspector;mouse_filter=Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	load_manifest();hide()

func update_view() -> void:
	if demo==null:return
	if not identify.held or identify.suppressed:
		if visible:clear_view();hide()
		return
	show()
	var sky: InteriorSky=demo.sky
	var gr: bool=sky.gr_lens!=null and sky.gr_lens.active
	status="Constellation guides unavailable during gravitational lensing" if gr else "Earth constellation guides · partial where stars are unavailable"
	refresh(sky.starfield,sky.camera,Vector2(demo.geometry_view.size),sky.system_view,gr)
	queue_redraw()

func _draw() -> void:
	if demo==null or identify==null or not identify.held or identify.suppressed:return
	var to_canvas := (get_viewport().get_stretch_transform()*get_global_transform_with_canvas()).affine_inverse()
	for line in segments:draw_line(to_canvas*line.a,to_canvas*line.b,LINE,1.,true)
	var occupied: Array=[]
	if identify.card.visible:occupied.append(identify.card.get_global_rect().grow(8.))
	for label in labels:
		var text_size := ThemeDB.fallback_font.get_string_size(label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,12)
		var p: Vector2=to_canvas*label.point+Vector2(10,-10)
		p=p.clamp(Vector2(8,24),size-Vector2(text_size.x+8,24))
		var box := Rect2(p-Vector2(0,12),text_size+Vector2(4,4))
		var collision := false
		for used: Rect2 in occupied:
			if used.intersects(box):collision=true;break
		if collision:continue
		occupied.append(box.grow(8.))
		draw_string(ThemeDB.fallback_font,p,label.text,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color(.58,.80,.85,.65))
