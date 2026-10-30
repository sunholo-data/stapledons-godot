extends RefCounted
## Internal light study, separate from the physically calibrated external sky.
## The broad key approximates fixed ship lighting; it is not the Sun. The star's own
## light is ship_star_light.gd ("StarLight"), which dims this key as it takes over.
const SPIRE_LAMP_Y:=89. # m (glTF y): 7 m above the 82 m bridge deck, on the mast axis
const SPIRE_LAMP_R:=1.92 # m: the mast's radius at the lamp band (its cone runs 3.3 m at the deck to 0 at 98 m)
const SPIRE_RANGE_M:=31. # m: lights the whole bridge to the rim's walk (R2-BRIDGE-STYLE S1: was 27, the rim fell outside the toon bands), ends 1 m above the Commons' 57 m deck
const SPIRE_COLOUR:=Color(1.,.80,.58)
const SPIRE_BASE:=8. # R2-BRIDGE-STYLE S1: the bridge's key in deep space now the broad key is retired there (was 5)
const BRIDGE_AMBIENT_GAIN:=1.45 # R2-BRIDGE-STYLE S1: the bridge's readability floor with the broad key retired (the lower decks keep theirs)
const SPIRE_SHADOW_BLUR:=2.5 # soft radial shadows (R2-BRIDGE-STYLE S1)
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
	# R2-DECK-LAYOUT §D5a (D-96): the spire is the bridge's own light, a warm lamp on the mast
	# that keys the deck when no star is close; it shares the broad key's dimming (ship_star_light).
	var spire:=OmniLight3D.new();spire.name="SpireLight"
	spire.position=Vector3(0,SPIRE_LAMP_Y,0);spire.omni_range=SPIRE_RANGE_M;spire.omni_attenuation=0. # R2-BRIDGE-STYLE ST5: no distance falloff inside the range window, so the dark ash rim far from the mast still reads
	spire.light_color=SPIRE_COLOUR;spire.shadow_enabled=false;host.add_child(spire)
	# R2-BRIDGE-STYLE S1: on the bridge the spire holds the shadow in deep space (cube map, soft for
	# the comic look); ship_star_light.apply_rig hands it to the star as the star rises.
	spire.omni_shadow_mode=OmniLight3D.SHADOW_CUBE;spire.shadow_blur=SPIRE_SHADOW_BLUR
	spire.shadow_bias=.06;spire.shadow_normal_bias=1.
	var lamp:=MeshInstance3D.new();lamp.name="SpireLamp"
	var band:=CylinderMesh.new();band.top_radius=SPIRE_LAMP_R;band.bottom_radius=SPIRE_LAMP_R+.06;band.height=.35;band.radial_segments=48;band.cap_top=false;band.cap_bottom=false
	lamp.mesh=band;lamp.position=spire.position;lamp.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var glow:=StandardMaterial3D.new();glow.albedo_color=SPIRE_COLOUR;glow.emission_enabled=true;glow.emission=SPIRE_COLOUR
	lamp.material_override=glow;host.add_child(lamp)
	var rig:={"environment":env,"key":key,"fill":fill,"practical":practical,"spire":spire,"spire_lamp":lamp,"profile":"","bridge":true,"mast":[]}
	apply(rig,"moody")
	return rig
static func apply(rig:Dictionary,profile:String)->void:
	var env:Environment=rig.environment
	var key:DirectionalLight3D=rig.key
	var fill:DirectionalLight3D=rig.fill
	var baseline:=profile=="baseline"
	env.ambient_light_color=Color(.65,.70,.78) if baseline else Color(.31,.37,.51)
	rig.ambient_base=.65 if baseline else .22
	key.light_color=Color.WHITE if baseline else Color(1.,.82,.65)
	key.light_energy=1.3 if baseline else 1.5
	key.shadow_enabled=profile=="moody"
	rig.key_base=key.light_energy;rig.shadows=profile=="moody"
	rig.spire_base=0. if baseline else SPIRE_BASE;rig.spire_lamp_base=0. if baseline else 2.5
	rig.spire.light_energy=rig.spire_base;rig.spire.visible=rig.spire_base>0.
	(rig.spire_lamp.material_override as StandardMaterial3D).emission_energy_multiplier=rig.spire_lamp_base
	fill.light_color=Color.WHITE if baseline else Color(.45,.59,.82)
	fill.light_energy=.65 if baseline else .14
	fill.shadow_enabled=false
	rig.practical.visible=not baseline
	rig.profile=profile
	_ambient(rig)
	if rig.has("star"):rig.star.apply_rig(rig)
## R2-BRIDGE-STYLE S1: the active level. On the bridge (0) the broad key is retired and the spire
## keys the deck; every other level keeps the broad key as before (their own passes follow).
static func set_level(rig:Dictionary,level:int)->void:
	rig.bridge=level==0
	rig["active_level"]=level
	for id: int in rig.get("level_lights",{}):
		for lamp: OmniLight3D in rig.level_lights[id]:lamp.visible=id==level and rig.profile!="baseline"
	_ambient(rig)
	if rig.has("star"):rig.star.apply_rig(rig)
## The ambient: the readability floor. On the bridge, with the broad key retired, it is raised so the
## rim and the stern stay readable when the star is below the deck and the spire at its floor.
static func _ambient(rig:Dictionary)->void:
	var env:Environment=rig.environment
	env.ambient_light_energy=float(rig.get("ambient_base",.22))*(BRIDGE_AMBIENT_GAIN if rig.get("bridge",false) and rig.profile!="baseline" else 1.)
## The mast's meshes (manifest style.spire_nodes): the spire light sits on its axis, inside it, so
## the mast must not cast the spire's shadow; it casts the star's as before.
static func set_mast(rig:Dictionary,nodes:Array)->void:
	rig.mast=nodes
	if rig.has("star"):rig.star.apply_rig(rig)
static func manifest(rig:Dictionary)->Dictionary:
	var practical:SpotLight3D=rig.practical
	var position:Vector3=practical.position
	var rotation:Vector3=rig.key.rotation_degrees
	var tint:Color=practical.light_color
	var star:Dictionary=rig.star.manifest() if rig.has("star") else {}
	return {"profile":rig.profile,"source":"ship-fixed internal lighting (ambient, cool fill, broad key, practical); the simulation star light is star_light","star_light":star,"key_base_energy":rig.get("key_base",rig.key.light_energy),"ambient_energy":rig.environment.ambient_light_energy,"key_energy":rig.key.light_energy,"fill_energy":rig.fill.light_energy,"key_shadows":rig.key.shadow_enabled,"key_rotation_deg":[rotation.x,rotation.y,rotation.z],"shadow_distance_m":rig.key.directional_shadow_max_distance,"shadow_bias":rig.key.shadow_bias,"shadow_normal_bias":rig.key.shadow_normal_bias,"recipe_sha256":FileAccess.get_sha256("res://demos/ship_lighting.gd"),"spire":{"position_m":[rig.spire.position.x,rig.spire.position.y,rig.spire.position.z],"range_m":rig.spire.omni_range,"base_energy":rig.get("spire_base",0.),"energy":rig.spire.light_energy,"colour":[SPIRE_COLOUR.r,SPIRE_COLOUR.g,SPIRE_COLOUR.b],"shadow_enabled":rig.spire.shadow_enabled,"shadow_opacity":rig.spire.shadow_opacity,"source":"R2-DECK-LAYOUT D-96: the bridge's own light on the mast; shares the broad key's dimming. R2-BRIDGE-STYLE S1: on the bridge it is the key (the broad key retired there) and holds the shadow until the star takes it"},"bridge":rig.get("bridge",false),"broad_key":"retired on the bridge (energy 0; R2-BRIDGE-STYLE S1, D-100); the lower decks keep it","practical":{"position_m":[position.x,position.y,position.z],"colour":[tint.r,tint.g,tint.b],"range_m":practical.spot_range,"angle_deg":practical.spot_angle,"energy":practical.light_energy,"visible":practical.visible,"shadow_enabled":practical.shadow_enabled}}

## Commons S1 practicals and a ceiling-bounded spire segment, driven only on their active level.
static func install_level(rig: Dictionary, level: int, doc: Dictionary, host: Node3D) -> void:
	var nodes := []
	var lights: Dictionary=doc.get("lights",{})
	var spec: Dictionary=lights.get("spire",{})
	if spec.has("height_m"):
		var spire:=OmniLight3D.new();spire.name="CommonsSpireSegment"
		spire.position=Vector3(0,float(spec.height_m),0)
		spire.omni_range=minf(float(spec.get("range_m",12)),float(spec.get("ceiling_m",81))-spire.position.y)
		spire.light_color=SPIRE_COLOUR;spire.light_energy=float(spec.get("energy",3));spire.shadow_enabled=false
		spire.set_meta("base_energy",spire.light_energy);host.add_child(spire);nodes.append(spire)
	for specp: Dictionary in lights.get("practicals",[]):
		var lamp:=OmniLight3D.new();lamp.name="CommonsPractical_"+str(specp.id)
		lamp.position=ShipFrame.gltf_from_structure(specp.at);lamp.omni_range=float(specp.get("range_m",5))
		lamp.light_color=SPIRE_COLOUR;lamp.light_energy=float(specp.get("energy",1));lamp.shadow_enabled=false
		lamp.set_meta("base_energy",lamp.light_energy);host.add_child(lamp);nodes.append(lamp)
	if not rig.has("level_lights"):rig["level_lights"]={}
	rig.level_lights[level]=nodes
	for lamp: OmniLight3D in nodes:lamp.visible=false
