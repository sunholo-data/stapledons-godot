extends Node3D
## Presentation-only 25m guarded lift. The world simulation/clock is untouched.
const RIDE_SECONDS := 25.0 / 6.0 # compatibility name; each leg uses its measured distance
const TRANSFER_SECONDS := .8
const BOARD_POINT := Vector3(8,0,-4.8)
var state := "bridge_ready"
var platform := Node3D.new()
var gates: Array[Node3D] = []
var cabin_gate: Node3D
var demo: Node
var _phase := ""
var _time := 0.
var _from_level := 0
var _to_level := 1
var _start := Vector3.ZERO
var stops: Array = []
var speed_mps := 6.0
var transfer_seconds := 0.8
var stops_path := "res://assets/levels/lift.json"
## R2-BRIDGE-STYLE S3: the authored lift head (manifest assets.lift, lift_head.glb: a grown pad, rails and
## gates painted on the DL2 recipe, toon and ink like the bridge); the white blockout boxes only without it.
var pieces: Node3D
func setup(owner_demo: Node) -> void:
	demo=owner_demo
	if not load_stops(stops_path):push_error("lift stops invalid");return
	add_child(platform);platform.position=Vector3(8,float(stops[0].z_m),-8)
	var file:String=str(demo.manifest.get("assets",{}).get("lift","")) if demo.get("manifest") is Dictionary else ""
	if file!="":pieces=AreaBundle.load_glb(demo.asset(file))
	var material:=StandardMaterial3D.new();material.albedo_color=Color(.25,.20,.35);material.roughness=.8
	if pieces!=null:_piece(platform,"lift_pad",Vector3.ZERO,true)
	else:_box(platform,Vector3(0,-.08,0),Vector3(3.6,.16,3.6),material)
	for pair in [[Vector3(-1.7,.65,0),Vector3(.12,1.3,3.6)],[Vector3(1.7,.65,0),Vector3(.12,1.3,3.6)],[Vector3(0,.65,-1.7),Vector3(3.6,1.3,.12)]]:
		_rail(platform,pair[0],pair[1],material)
	cabin_gate=_rail(platform,Vector3(0,.65,1.7),Vector3(3.6,1.3,.12),material)
	for stop: Dictionary in stops:gates.append(_rail(self,Vector3(8,float(stop.z_m)+.65,-5.8),Vector3(4.4,1.3,.12),material))
	if pieces!=null:StapledonStyle.apply([platform]+gates)
## One authored piece (a copy of the GLB's mesh), placed and turned as the box it replaces.
func _piece(parent: Node3D, kind: String, position_m: Vector3, along_x: bool) -> Node3D:
	var src:=pieces.find_child(kind,true,false) as MeshInstance3D
	var group:=Node3D.new();group.position=position_m;parent.add_child(group)
	var mi:=MeshInstance3D.new();mi.name=kind;mi.mesh=src.mesh;group.add_child(mi)
	if not along_x:group.rotation.y=PI*.5
	return group
func _box(parent: Node3D, position_m: Vector3, size_m: Vector3, material: Material) -> MeshInstance3D:
	var n:=MeshInstance3D.new();var mesh:=BoxMesh.new();mesh.size=size_m;n.mesh=mesh;n.material_override=material;n.position=position_m;parent.add_child(n);return n
## Parse before mutating the controller: invalid stops cannot partially replace a valid route.
func load_stops(path: String) -> bool:
	var cfg: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	if not cfg is Dictionary or cfg.get("schema") != "stapledons.lift/1":return false
	var rows: Variant = cfg.get("stops")
	if not rows is Array or rows.size()<2:return false
	for field: String in ["speed_mps","transfer_seconds"]:
		var value: Variant=cfg.get(field)
		if not (value is float or value is int) or not is_finite(float(value)) or float(value)<=0.:return false
	var ids := {};var heights := {}
	for i in rows.size():
		var stop: Variant = rows[i]
		if not stop is Dictionary or str(stop.get("id","")).is_empty() or ids.has(stop.id) or int(stop.get("level",-1))!=i:return false
		if not (stop.get("z_m") is float or stop.get("z_m") is int) or not is_finite(float(stop.z_m)) or heights.has(float(stop.z_m)):return false
		if Vector3(8,float(stop.z_m)+5.5,-8).length()>95.:return false
		ids[stop.id]=true;heights[float(stop.z_m)]=true
	stops=rows;speed_mps=float(cfg.speed_mps);transfer_seconds=float(cfg.transfer_seconds)
	return true
func travelling() -> bool:
	return not state.ends_with("_ready")
func board(destination := "") -> bool:
	if travelling() or stops.is_empty():return false
	_from_level=demo.active_level
	if _from_level<0 or _from_level>=stops.size():return false
	var point:=BOARD_POINT;point.y=float(stops[_from_level].z_m)
	if demo.avatar_pos.distance_to(point)>1.5:return false
	_to_level=(_from_level+1)%stops.size()
	if not destination.is_empty():
		_to_level=-1
		for i in stops.size():
			if str(stops[i].id)==destination:_to_level=i
		if _to_level<0 or _to_level==_from_level:return false
	if not demo.has_method("walk_for_level") or demo.walk_for_level(str(stops[_to_level].id))==null:return false
	state="boarding";_phase="boarding";_time=0.;_start=demo.avatar_pos
	gates[_from_level].visible=false;cabin_gate.visible=false
	demo.camera_mode="player";demo.camera.pullback=0.
	if demo.camera_motion=="reduced":skip()
	return true
func ride_seconds() -> float:
	return absf(float(stops[_from_level].z_m)-float(stops[_to_level].z_m))/speed_mps
func advance(delta: float) -> void:
	if not travelling() or delta<=0:return
	# Consume the whole presentation delta so slow frames and skip arrive at the same endpoint.
	var remaining:=delta
	while remaining>0. and travelling():
		var duration:=ride_seconds() if _phase=="riding" else transfer_seconds
		var used:=minf(remaining,maxf(0.,duration-_time))
		_time+=used;remaining-=used
		var t:=minf(_time/duration,1.)
		if _phase=="boarding":
			demo.avatar_pos=_start.lerp(platform.position,t);demo.avatar.position=demo.avatar_pos
			if t>=1.:
				demo.avatar.reparent(platform,true);demo.avatar.position=Vector3.ZERO
				gates[_from_level].visible=true;cabin_gate.visible=true
				state="descending" if float(stops[_to_level].z_m)<float(stops[_from_level].z_m) else "ascending"
				_phase="riding";_time=0.
		elif _phase=="riding":
			platform.position.y=lerpf(float(stops[_from_level].z_m),float(stops[_to_level].z_m),t)
			demo.avatar_pos=platform.position;demo.avatar.position=Vector3.ZERO
			if t>=1.:
				demo.active_level=_to_level
				demo.walk=demo.walk_for_level(str(stops[_to_level].id))
				demo.avatar.reparent(demo.geometry,true)
				gates[_to_level].visible=false;cabin_gate.visible=false
				_phase="disembarking";state="boarding";_time=0.
		elif _phase=="disembarking":
			var endpoint:=BOARD_POINT;endpoint.y=float(stops[_to_level].z_m)
			demo.avatar_pos=platform.position.lerp(endpoint,t);demo.avatar.position=demo.avatar_pos
			if t>=1.:
				state="bridge_ready" if _to_level==0 else ("lower_ready" if _to_level==1 else str(stops[_to_level].id)+"_ready")
				_phase="";_time=0.;gates[_to_level].visible=true;cabin_gate.visible=true
func skip() -> bool:
	if not travelling():return false
	advance(transfer_seconds*2.+ride_seconds()+.001)
	demo.director._arrive();demo.director.has_pose=false;demo.director.advance(0.)
	return not travelling()
func reset() -> void:
	if demo.avatar.get_parent()!=demo.geometry:demo.avatar.reparent(demo.geometry,true)
	platform.position=Vector3(8,float(stops[0].z_m),-8);state="bridge_ready";_phase="";_time=0.
	for gate in gates:gate.visible=true
	cabin_gate.visible=true

func _rail(parent: Node3D, position_m: Vector3, size_m: Vector3, material: Material) -> Node3D:
	var along_x:=size_m.x>size_m.z
	if pieces!=null:return _piece(parent,"lift_gate_4_4" if maxf(size_m.x,size_m.z)>4. else "lift_rail_3_6",position_m,along_x)
	var group:=Node3D.new();group.position=position_m;parent.add_child(group)
	for y in [-.1,.55]:
		_box(group,Vector3(0,y,0),Vector3(size_m.x,.12,size_m.z),material)
	for side in [-1.,1.]:
		var point:=Vector3(side*(size_m.x/2.-.08),0,0) if along_x else Vector3(0,0,side*(size_m.z/2.-.08))
		_box(group,point,Vector3(.12,1.3,.12),material)
	return group
