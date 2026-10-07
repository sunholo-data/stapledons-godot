extends RefCounted
## Internal light study, separate from the physically calibrated external sky.
## The broad key approximates fixed ship lighting; it is not the Sun. The star's own
## light is ship_star_light.gd ("StarLight"), which dims this key as it takes over.
static func install(host:Node3D)->Dictionary:
	var env:=Environment.new();env.background_mode=Environment.BG_CLEAR_COLOR
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.tonemap_mode=Environment.TONE_MAPPER_AGX
	var world:=WorldEnvironment.new();world.environment=env;host.add_child(world)
	var key:=DirectionalLight3D.new();key.name="InternalBroadKey"
	key.rotation_degrees=Vector3(-45,-25,0)
	key.directional_shadow_max_distance=100.
	key.shadow_bias=.04;key.shadow_normal_bias=.3
	host.add_child(key)
	var fill:=DirectionalLight3D.new();fill.name="InternalCoolFill"
	fill.rotation_degrees=Vector3(-20,155,0);host.add_child(fill)
	var practical:=SpotLight3D.new();practical.name="CommonsReadingLight"
	practical.position=Vector3(46,61.5,-5);practical.rotation_degrees=Vector3(-90,0,0)
	practical.light_color=Color(1.,.76,.48);practical.spot_range=10.;practical.spot_angle=70.
	practical.light_energy=2.;practical.shadow_enabled=false;host.add_child(practical)
	var rig:={"environment":env,"key":key,"fill":fill,"practical":practical,"profile":""}
	apply(rig,"moody")
	return rig
static func apply(rig:Dictionary,profile:String)->void:
	var env:Environment=rig.environment
	var key:DirectionalLight3D=rig.key
	var fill:DirectionalLight3D=rig.fill
	var baseline:=profile=="baseline"
	env.ambient_light_color=Color(.65,.70,.78) if baseline else Color(.31,.37,.51)
	env.ambient_light_energy=.65 if baseline else .22
	key.light_color=Color.WHITE if baseline else Color(1.,.82,.65)
	key.light_energy=1.3 if baseline else 1.5
	key.shadow_enabled=profile=="moody"
	rig.key_base=key.light_energy;rig.shadows=profile=="moody"
	fill.light_color=Color.WHITE if baseline else Color(.45,.59,.82)
	fill.light_energy=.65 if baseline else .14
	fill.shadow_enabled=false
	rig.practical.visible=not baseline
	rig.profile=profile
	if rig.has("star"):rig.star.apply_rig(rig)
static func manifest(rig:Dictionary)->Dictionary:
	var practical:SpotLight3D=rig.practical
	var position:Vector3=practical.position
	var rotation:Vector3=rig.key.rotation_degrees
	var tint:Color=practical.light_color
	var star:Dictionary=rig.star.manifest() if rig.has("star") else {}
	return {"profile":rig.profile,"source":"ship-fixed internal lighting (ambient, cool fill, broad key, practical); the simulation star light is star_light","star_light":star,"key_base_energy":rig.get("key_base",rig.key.light_energy),"ambient_energy":rig.environment.ambient_light_energy,"key_energy":rig.key.light_energy,"fill_energy":rig.fill.light_energy,"key_shadows":rig.key.shadow_enabled,"key_rotation_deg":[rotation.x,rotation.y,rotation.z],"shadow_distance_m":rig.key.directional_shadow_max_distance,"shadow_bias":rig.key.shadow_bias,"shadow_normal_bias":rig.key.shadow_normal_bias,"recipe_sha256":FileAccess.get_sha256("res://demos/ship_lighting.gd"),"practical":{"position_m":[position.x,position.y,position.z],"colour":[tint.r,tint.g,tint.b],"range_m":practical.spot_range,"angle_deg":practical.spot_angle,"energy":practical.light_energy,"visible":practical.visible,"shadow_enabled":practical.shadow_enabled}}
