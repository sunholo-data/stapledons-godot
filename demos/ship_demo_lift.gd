extends Node3D
## Presentation-only 25m guarded lift. The world simulation/clock is untouched.
const RIDE_SECONDS := 11.0
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
func setup(owner_demo: Node) -> void:
	demo=owner_demo;add_child(platform);platform.position=Vector3(8,82,-8)
	var material:=StandardMaterial3D.new();material.albedo_color=Color(.25,.20,.35);material.roughness=.8
	_box(platform,Vector3(0,-.08,0),Vector3(3.6,.16,3.6),material)
	for pair in [[Vector3(-1.7,.65,0),Vector3(.12,1.3,3.6)],[Vector3(1.7,.65,0),Vector3(.12,1.3,3.6)],[Vector3(0,.65,-1.7),Vector3(3.6,1.3,.12)]]:
		_rail(platform,pair[0],pair[1],material)
	cabin_gate=_rail(platform,Vector3(0,.65,1.7),Vector3(3.6,1.3,.12),material)
	for y in [82.,57.]:gates.append(_rail(self,Vector3(8,y+.65,-5.8),Vector3(4.4,1.3,.12),material))
func _box(parent: Node3D, position_m: Vector3, size_m: Vector3, material: Material) -> MeshInstance3D:
	var n:=MeshInstance3D.new();var mesh:=BoxMesh.new();mesh.size=size_m;n.mesh=mesh;n.material_override=material;n.position=position_m;parent.add_child(n);return n
func travelling() -> bool:
	return state!="bridge_ready" and state!="lower_ready"
func board() -> bool:
	if travelling():return false
	var point:=BOARD_POINT;point.y=82. if demo.active_level==0 else 57.
	if demo.avatar_pos.distance_to(point)>1.5:return false
	_from_level=demo.active_level;_to_level=1-_from_level
	state="boarding";_phase="boarding";_time=0.;_start=demo.avatar_pos
	gates[_from_level].visible=false;cabin_gate.visible=false
	demo.camera_mode="player";demo.camera.pullback=0.
	return true
func advance(delta: float) -> void:
	if not travelling() or delta<=0:return
	_time+=delta
	if _phase=="boarding":
		var t:=minf(_time/TRANSFER_SECONDS,1.)
		demo.avatar_pos=_start.lerp(platform.position,t)
		demo.avatar.position=demo.avatar_pos
		if t>=1.:
			demo.avatar.reparent(platform,true);demo.avatar.position=Vector3.ZERO
			gates[_from_level].visible=true;cabin_gate.visible=true
			state="descending" if _to_level==1 else "ascending";_phase="riding";_time=0.
	elif _phase=="riding":
		var t:=minf(_time/RIDE_SECONDS,1.);var eased:=t*t*(3.-2.*t)
		var y0:=82. if _from_level==0 else 57.;var y1:=82. if _to_level==0 else 57.
		platform.position.y=lerpf(y0,y1,eased);demo.avatar_pos=platform.position
		demo.avatar.position=Vector3.ZERO
		if t>=1.:
			platform.position.y=y1;demo.active_level=_to_level
			demo.walk=demo.walk_bridge if _to_level==0 else demo.walk_lower
			demo.avatar.reparent(demo.geometry,true)
			gates[_to_level].visible=false;cabin_gate.visible=false
			_phase="disembarking";state="boarding";_time=0.
	elif _phase=="disembarking":
		var endpoint:=BOARD_POINT;endpoint.y=platform.position.y
		var t:=minf(_time/TRANSFER_SECONDS,1.)
		demo.avatar_pos=platform.position.lerp(endpoint,t);demo.avatar.position=demo.avatar_pos
		if t>=1.:
			state="bridge_ready" if _to_level==0 else "lower_ready";_phase="";_time=0.
			gates[_to_level].visible=true;cabin_gate.visible=true
func reset() -> void:
	if demo.avatar.get_parent()!=demo.geometry:demo.avatar.reparent(demo.geometry,true)
	platform.position=Vector3(8,82,-8);state="bridge_ready";_phase="";_time=0.
	for gate in gates:gate.visible=true
	cabin_gate.visible=true

func _rail(parent: Node3D, position_m: Vector3, size_m: Vector3, material: Material) -> Node3D:
	var group:=Node3D.new();group.position=position_m;parent.add_child(group)
	var along_x:=size_m.x>size_m.z
	for y in [-.1,.55]:
		_box(group,Vector3(0,y,0),Vector3(size_m.x,.12,size_m.z),material)
	for side in [-1.,1.]:
		var point:=Vector3(side*(size_m.x/2.-.08),0,0) if along_x else Vector3(0,0,side*(size_m.z/2.-.08))
		_box(group,point,Vector3(.12,1.3,.12),material)
	return group
