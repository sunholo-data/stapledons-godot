class_name ShipLevelRuntime
extends RefCounted
## R2-LEVELS LP2: playable greybox over the existing Commons kit. No simulation state.
var demo: Node
var layout: Dictionary
var greybox: Dictionary
var _active_state := -1

static func install(owner_demo: Node, path: String) -> ShipLevelRuntime:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	if not LevelSchema.validate(parsed).is_empty():return null
	var runtime := ShipLevelRuntime.new()
	runtime.demo=owner_demo;runtime.layout=parsed
	prepare_geometry(owner_demo)
	runtime.greybox=LevelGreybox.build(parsed,owner_demo.geometry)
	owner_demo.walk_lower=WalkArea.merged([owner_demo.walk_lower,runtime.greybox.walk])
	runtime.set_active(owner_demo.active_level==1)
	return runtime

static func prepare_geometry(owner_demo: Node) -> void:
	preload("res://demos/commons_stage_geometry.gd").split(owner_demo.commons)
	if not owner_demo.commons.has("stage_extra_occluders"):
		var nodes: Array=[];var stack: Array=[owner_demo.geometry]
		while not stack.is_empty():
			var node: Node=stack.pop_back()
			if node is MeshInstance3D and (str(node.name).to_lower().contains("lift guide") or str(node.name).to_lower().contains("lift_guide")):
				nodes.append(node)
			stack.append_array(node.get_children())
		owner_demo.commons.stage_extra_occluders=nodes
	for node: Node in owner_demo.commons.stage_extra_occluders:node.add_to_group(CameraDirector.OCCLUDER_GROUP)

func route_target() -> Dictionary:
	if demo.active_level!=1 or demo.lift==null or demo.lift.travelling() or demo.camera_mode!="player" or demo.panel_open():return {}
	var nearest := {};var distance := 1.5
	for route: Dictionary in layout.routes:
		if not str(route.kind) in ["ladder","hatch"]:continue
		for end: String in ["from","to"]:
			var point:=LevelGreybox.route_end(route,end)
			var d: float=demo.avatar_pos.distance_to(point)
			if d<distance:
				nearest={"route":route,"end":end,"distance":d};distance=d
	return nearest

func transfer() -> bool:
	var target:=route_target()
	if target.is_empty():return false
	var destination:=LevelGreybox.transfer(demo.walk_lower,target.route,demo.avatar_pos)
	if not demo.walk_lower.is_walkable_near(destination):return false
	demo.consoles.cancel_walk();demo.avatar_pos=destination;demo.avatar.position=destination
	demo.director.zoom_preset=false;demo.director.advance(0.)
	return true

func route_hint() -> String:
	var target:=route_target()
	if not target.is_empty():
		return ("Hatch" if target.route.kind=="hatch" else "Ladder")+" · E "+("down" if LevelGreybox.route_end(target.route,"to" if target.end=="from" else "from").y<demo.avatar_pos.y else "up")
	match str(demo.director.stage_at("commons",demo.avatar_pos).get("id","")):
		"terrace":return "Stairs lead back to the court"
		"gantry":return "Return via the terrace ladder"
		"service":return "Return through the hatch"
	return ""

func set_active(active: bool) -> void:
	if _active_state==int(active):return
	_active_state=int(active)
	greybox.node.visible=active
	preload("res://demos/commons_stage_geometry.gd").set_active(demo.commons,active)

func step(from: Vector3, delta: Vector3) -> Vector3:
	var target: Vector3=demo.walk_lower.step(from,delta)
	if target==from:return from
	var shape:=CapsuleShape3D.new();shape.radius=.30;shape.height=1.7
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape
	query.transform=Transform3D(Basis.IDENTITY,target+Vector3.UP*.90);query.margin=.005
	for hit: Dictionary in demo.camera.get_world_3d().direct_space_state.intersect_shape(query,16):
		var name:=str(hit.collider.name)
		if not name.begins_with("GB_surface_") and not name.begins_with("GB_route_"):return from
	return target
