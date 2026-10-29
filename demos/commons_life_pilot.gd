extends Node3D
## Review-only civilian activity study; no production hook, collision, interaction or crew identity.
## install(demo, rows, reduce_motion=false). Rows: name, ship_m, activity, facing (degrees about
## ship up; 0 faces ship+Y), optional RGB tint, seat_height_m, walk_m (total span, .2..2m).
## Activities: market, dining, reading, conversation, walk. Feet/root are on the existing floor;
## seat_height_m is the furniture's actual seat surface above that floor, not a raised root.
## Deterministic local clock: advance(delta), pose_at(seconds), set_reduced_motion(bool).
## Hidden helpers pause. The demo's live camera_motion preference also stops decoration.
const ACTIVITIES:=["market","dining","reading","conversation","walk"]
const CLOTH:=[Color("537b79"),Color("b38a52"),Color("a26f65"),Color("716580"),Color("a2a18a"),Color("b8ac93")]
const SKIN:=[Color("c29a7d"),Color("9b7056"),Color("79533f"),Color("d6b397"),Color("a9876f")]
const HAIR:=[Color("423b39"),Color("655245"),Color("aca89e"),Color("463f4c")]
const TROUSERS:=Color("55545c")
static var _materials:Dictionary={}
var elapsed:=0.0
var host_demo:Node
var reduced:=false
var _people:Array=[]

static func install(demo:Node,rows:Array,reduce_motion:bool=false)->Dictionary:
 var errors:=validate(rows)
 var result:={"ok":false,"node":null,"errors":errors,"residents":{}}
 if not errors.is_empty():return result
 if demo==null or not demo.get("geometry") is Node3D or not demo.get("camera") is Camera3D:
  errors.append("demo needs geometry and a world camera");return result
 var space:PhysicsDirectSpaceState3D=demo.camera.get_world_3d().direct_space_state
 for row:Dictionary in rows:
  var foot:=ShipFrame.gltf_from_structure(row.ship_m)
  var facing:=Basis(Vector3.UP,deg_to_rad(float(row.facing)))
  var span:=float(row.get("walk_m",1.2)) if row.activity=="walk" else 0.
  for step in 13 if span>0 else 1:
   var offset:float=(float(step)/12.-.5)*span if span>0 else 0.
   var at:=foot+facing*Vector3.FORWARD*offset
   var query:=PhysicsRayQueryParameters3D.create(at+Vector3.UP*.1,at-Vector3.UP*.15);query.hit_back_faces=true
   var hit:=space.intersect_ray(query)
   if hit.is_empty() or absf((hit.position as Vector3).y-at.y)>.035 or (hit.normal as Vector3).dot(Vector3.UP)<.9:
    errors.append(str(row.name)+": vignette/stroll leaves its existing floor");break
 if not errors.is_empty():return result
 var pilot=load("res://demos/commons_life_pilot.gd").new()
 pilot.name="CommonsLifePilot";pilot.host_demo=demo;pilot.reduced=reduce_motion
 for row:Dictionary in rows:
  var person:Dictionary=pilot._civilian(row)
  pilot._people.append(person);pilot.add_child(person.node);result.residents[row.name]=person.node
 demo.geometry.add_child(pilot);pilot.pose_at(0.)
 result.ok=true;result.node=pilot;return result

static func validate(rows:Variant)->PackedStringArray:
 var errors:=PackedStringArray();var names:Array=[]
 if not rows is Array or rows.is_empty() or rows.size()>64:return PackedStringArray(["life rows must be a nonempty list of at most64 residents"])
 for row:Variant in rows:
  if not row is Dictionary:errors.append("resident must be an object");continue
  if not row.get("name") is String or str(row.name).is_empty() or names.has(row.get("name")):errors.append("resident names must be unique")
  names.append(row.get("name"))
  if not _vec(row.get("ship_m")) or not _num(row.get("facing")):errors.append("resident requires finite ship_m and facing")
  if not row.get("activity") in ACTIVITIES:errors.append("unknown resident activity")
  if row.has("tint") and (not _vec(row.tint) or (row.tint as Array).any(func(c:Variant)->bool:return float(c)<0 or float(c)>1)):errors.append("tint must be RGB in0..1")
  if row.has("seat_height_m") and (not _num(row.seat_height_m) or float(row.seat_height_m)<.35 or float(row.seat_height_m)>.65):errors.append("seat height must be .35..65m")
  if row.has("walk_m") and (not _num(row.walk_m) or float(row.walk_m)<.2 or float(row.walk_m)>2):errors.append("stroll span must be .2..2m")
 return errors
static func _num(v:Variant)->bool:return (v is int or v is float) and is_finite(float(v))
static func _vec(v:Variant)->bool:return v is Array and v.size()==3 and v.all(func(n:Variant)->bool:return _num(n))
static func _seed(name:String)->int:
 var value:=17
 for byte:int in name.to_utf8_buffer():value=(value*131+byte)%2147483647
 return value

func _process(delta:float)->void:advance(delta)
func _motion_reduced()->bool:return reduced or (is_instance_valid(host_demo) and host_demo.get("camera_motion")=="reduced")
func advance(delta:float)->void:
 if not is_visible_in_tree() or _motion_reduced() or not is_finite(delta) or delta<0:return
 pose_at(elapsed+delta)
func pose_at(seconds:float)->void:
 if not is_finite(seconds) or seconds<0:return
 elapsed=seconds
 for person:Dictionary in _people:_pose(person,0. if _motion_reduced() else seconds,_motion_reduced())
func set_reduced_motion(value:bool)->void:reduced=value

func _civilian(row:Dictionary)->Dictionary:
 var seed:=_seed(row.name);var stature:=.94+float(seed%13)*.009
 var coat:Color=CLOTH[seed%CLOTH.size()]
 if row.has("tint"):coat=Color(row.tint[0],row.tint[1],row.tint[2])
 var skin:Color=SKIN[(seed/7)%SKIN.size()];var hair:Color=HAIR[(seed/17)%HAIR.size()]
 var root:=Node3D.new();root.name=row.name;root.position=ShipFrame.gltf_from_structure(row.ship_m);root.scale=Vector3.ONE*stature
 root.set_meta("source","native civilian study v1");root.set_meta("identity","review resident; not a simulated crew member")
 root.set_meta("activity",row.activity);root.set_meta("variant",{"seed":seed,"stature":stature,"cloth":coat.to_html(),"hair":hair.to_html()})
 var body:=Node3D.new();body.name="Body";root.add_child(body)
 _tube(body,"Tunic",Vector3(0,1.14,0),.185,.16,.48,coat,.72)
 _tube(body,"Hips",Vector3(0,.89,0),.16,.15,.16,TROUSERS,.72)
 _tube(body,"Hem",Vector3(0,.94,0),.168,.18,.085,coat.darkened(.08),.73)
 _sphere(body,"Neck",Vector3(0,1.425,0),.052,.065,.05,skin)
 var head:=Node3D.new();head.name="Head";head.position=Vector3(0,1.55,0);body.add_child(head)
 _sphere(head,"Face",Vector3.ZERO,.101,.117,.09,skin)
 _sphere(head,"Hair",Vector3(0,.06,.018),.105,.072,.087,hair)
 if seed%3==0:_sphere(head,"HairBack",Vector3(0,-.015,.066),.101,.092,.062,hair)
 if seed%3==1:_sphere(head,"TiedHair",Vector3(0,.035,.11),.045,.06,.052,hair)
 _sphere(head,"Nose",Vector3(0,0,-.094),.02,.028,.025,skin)
 if seed%2==0:_box(body,"Apron",Vector3(0,1.025,-.13),Vector3(.21,.29,.018),Color("bcaa8a"))
 else:_box(body,"Scarf",Vector3(.07,1.32,-.128),Vector3(.075,.20,.025),coat.lightened(.2))
 var legs:Array=[];var arms:Array=[]
 for side:float in [-1.,1.]:
  var leg:=Node3D.new();leg.name="Hip_L" if side<0 else "Hip_R";leg.position=Vector3(side*.09,.89,0);body.add_child(leg)
  _tube(leg,"TrouserUpper",Vector3(0,-.215,0),.06,.051,.43,TROUSERS,.88)
  var knee:=Node3D.new();knee.position.y=-.43;leg.add_child(knee)
  _tube(knee,"TrouserLower",Vector3(0,-.215,0),.05,.036,.43,TROUSERS,.92)
  var foot:=Node3D.new();foot.name="Foot_L" if side<0 else "Foot_R";foot.position.y=-.43;knee.add_child(foot)
  _sphere(foot,"Shoe",Vector3(0,0,-.035),.055,.035,.09,Color("48454c"))
  legs.append({"hip":leg,"knee":knee,"foot":foot})
  var shoulder:=Node3D.new();shoulder.position=Vector3(side*.215,1.34,0);body.add_child(shoulder)
  _tube(shoulder,"Sleeve",Vector3(0,-.135,0),.057,.046,.27,coat)
  var elbow:=Node3D.new();elbow.position.y=-.27;shoulder.add_child(elbow)
  _tube(elbow,"Forearm",Vector3(0,-.125,0),.04,.029,.25,skin)
  var hand:=Node3D.new();hand.position.y=-.255;elbow.add_child(hand);_sphere(hand,"Hand",Vector3.ZERO,.032,.046,.027,skin)
  arms.append({"shoulder":shoulder,"elbow":elbow,"hand":hand,"side":side})
 if row.activity=="reading":
  _box(body,"BookCover",Vector3(0,1.115,-.30),Vector3(.27,.026,.18),Color("6c6577"))
  _box(body,"BookPages",Vector3(0,1.132,-.30),Vector3(.24,.018,.16),Color("c7bda4"))
 if row.activity=="market":
  _tube(arms[0].hand,"MarketBag",Vector3(0,-.10,0),.085,.10,.20,Color("a28b65"),.7)
 if row.activity=="dining":
  _tube(arms[1].hand,"Cup",Vector3(0,.035,-.025),.033,.027,.07,Color("c3b495"))
 return {"node":root,"row":row.duplicate(true),"body":body,"head":head,"legs":legs,"arms":arms,"stature":stature,"phase":float(seed%97)/97.*12.,"origin":root.position}

func _pose(person:Dictionary,time:float,still:bool)->void:
 var row:Dictionary=person.row;var root:Node3D=person.node;var body:Node3D=person.body
 var phase:float=person.phase;var facing:=deg_to_rad(float(row.facing));var moving:=false;var distance:=0.
 root.position=person.origin;root.rotation=Vector3(0,facing,0);body.rotation=Vector3.ZERO;body.position=Vector3.ZERO
 var seated:bool=row.activity=="dining" or row.has("seat_height_m")
 if seated:body.position.y=(float(row.get("seat_height_m",.48))+.1)/float(person.stature)-.89
 if row.activity=="walk" and not still:
  var cycle:=fposmod(time+phase,12.);var span:=float(row.get("walk_m",1.2));var along:float
  if cycle<4:along=-span*.5+span*cycle/4.;moving=true;distance=span*cycle/4.
  elif cycle<6:along=span*.5;root.rotation.y=facing+PI*smoothstep(4.,6.,cycle)
  elif cycle<10:along=span*.5-span*(cycle-6.)/4.;moving=true;distance=span*(cycle-6.)/4.;root.rotation.y=facing+PI
  else:along=-span*.5;root.rotation.y=facing+PI+PI*smoothstep(10.,12.,cycle)
  root.position+=Basis(Vector3.UP,facing)*Vector3.FORWARD*along
  if moving:body.position.y=-.04
 var hip_y:float=.89+body.position.y
 for index in person.legs.size():
  var forward:=.43 if seated else 0.;var lift:=0.
  if moving:
   var gait:=fposmod(distance/.5+float(index)*.5,1.)
   if gait<.6:forward=.15-.5*gait
   else:
    var u:float=(gait-.6)/.4;forward=lerpf(-.15,.15,smoothstep(0.,1.,u));lift=.055*sin(PI*u)
  _leg_pose(person.legs[index],hip_y-(.035+lift)/float(person.stature),forward)
 var sway:=0. if still else sin((time+phase)*1.1)*.012
 body.rotation.z=sway
 person.head.rotation.x=.13 if row.activity=="reading" else (sway*.6)
 person.head.rotation.y=0. if still else sin((time+phase)*.55)*.035
 for arm:Dictionary in person.arms:
  arm.shoulder.rotation=Vector3(.04,0,float(arm.side)*.10);arm.elbow.rotation=Vector3(.12,0,0)
  if row.activity in ["reading","dining"]:
   arm.shoulder.rotation.x=.25;arm.elbow.rotation=Vector3(1.25,0,-float(arm.side)*.35)
  elif row.activity=="conversation" and arm.side>0:arm.shoulder.rotation.x=.25;arm.elbow.rotation.x=.9+sway*3.
  elif row.activity=="market" and arm.side>0:arm.shoulder.rotation.x=.25;arm.elbow.rotation.x=.7
  elif moving:arm.shoulder.rotation.x=sin(distance/.5*TAU)*.18*float(arm.side)
  arm.hand.rotation.x=-arm.shoulder.rotation.x-arm.elbow.rotation.x
func _leg_pose(leg:Dictionary,down:float,forward:float)->void:
 var length:=clampf(Vector2(down,forward).length(),.01,.85999)
 var hip:=atan2(forward,down)+acos(clampf(length/.86,-1.,1.))
 var knee:=-acos(clampf((length*length-2.*.43*.43)/(2.*.43*.43),-1.,1.))
 leg.hip.rotation.x=hip;leg.knee.rotation.x=knee;leg.foot.rotation.x=-hip-knee

func _material(color:Color)->ShaderMaterial:
 var key:=color.to_html()
 if not _materials.has(key):
  var source:=StandardMaterial3D.new();source.albedo_color=color;_materials[key]=StapledonStyle.toon_material(source)
 return _materials[key]
func _mesh(parent:Node,name:String,at:Vector3,geometry:Mesh,color:Color)->MeshInstance3D:
 var mesh:=MeshInstance3D.new();mesh.name=name;mesh.mesh=geometry;mesh.position=at;mesh.material_override=_material(color);mesh.add_to_group(StapledonStyle.GROUP);parent.add_child(mesh);return mesh
func _tube(parent:Node,name:String,at:Vector3,top:float,bottom:float,height:float,color:Color,depth:=1.)->void:
 var mesh:=CylinderMesh.new();mesh.top_radius=top;mesh.bottom_radius=bottom;mesh.height=height;mesh.radial_segments=8;mesh.rings=1
 _mesh(parent,name,at,mesh,color).scale.z=depth
func _sphere(parent:Node,name:String,at:Vector3,x:float,y:float,z:float,color:Color)->void:
 var mesh:=SphereMesh.new();mesh.radius=x;mesh.height=y*2.;mesh.radial_segments=10;mesh.rings=5
 _mesh(parent,name,at,mesh,color).scale.z=z/x
func _box(parent:Node,name:String,at:Vector3,size:Vector3,color:Color)->void:
 var mesh:=BoxMesh.new();mesh.size=size;_mesh(parent,name,at,mesh,color)
