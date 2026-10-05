extends SceneTree
const StarProjection = preload("res://sky/star_projection.gd")

var checks:=0
var failures:=0
func check(label:String,ok:bool)->void:
 checks+=1
 if not ok:failures+=1;print("FAIL ",label)
func _initialize()->void:run.call_deferred()
func run()->void:
 var fixtures:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/alpha_centauri_physical.json"))
 var sf:=Starfield.new();root.add_child(sf)
 sf.set_custom_stars([{id="CNS5:3627",pos=[1.,0.,0.],t=5550.,flux=.02},{id="HIP 71681",pos=[1.,.1,0.],t=5200.,flux=.005},{id="other",pos=[0.,1.,0.],t=5772.,flux=.01}]);sf.build()
 var original:=sf.custom.duplicate()
 var sv:=SystemView.new();root.add_child(sv);sv.setup(sf,false);sv.set_view(.001,600.)
 sv.update(fixtures.sol,.00001)
 check("exact catalogue IDs suppressed, unrelated row preserved",sf.custom[1]==0. and sf.custom[5]==0. and sf.custom[9]==original[9])
 check("two real physical stars supplied from Sol",sf.point_count==2 and sv.drawn_points.has("acen-a") and sv.drawn_points.has("acen-b"))
 check("measured temperatures reach point shader",sf._point_custom[0]==5795. and sf._point_custom[4]==5231.)
 var sample:=StarProjection.sample(sf,0)
 var expected:Vector3=sf.catalogue_replacement_sources["CNS5:3627"].dir
 check("identification direction uses finite source, not old catalogue",sample.direction.dot(expected)>.999999 and sample.direction.dot(Vector3.RIGHT)<.99)
 check("identification flux uses physical source",sample.replacement.lux>0.)
 sf.set_velocity(Vector3.RIGHT,.9,1./sqrt(1.-.81))
 var boosted:=StarProjection.sample(sf,0)
 var context:=StarProjection.context(sf)
 var d:float=boosted.doppler
 var expected_peak:Vector3=Blackbody.lut_rgb(5795.*d)*sample.replacement.lux*pow(10.,Blackbody.lut_log10_y(5795.*d)-Blackbody.lut_log10_y(5795.))/(d*d)*context.exposure
 check("boosted identification eligibility uses measured emitter temperature",boosted.visible==(maxf(expected_peak.x,maxf(expected_peak.y,expected_peak.z))>=context.cull_peak))
 var e1:=sv.e1_au
 sv.update(fixtures.arrival_1000au,.00001)
 check("Alpha emitters do not replace solar illumination authority",sv.e1_au==e1)
 var a:Dictionary=fixtures.arrival_1000au.bodies[0]
 var distance:=Planets.length64(Planets.world_of(a.rel_km))
 var diameter:=rad_to_deg(2.*Planets.angular_radius(a.radius_km,distance))*3600.
 check("1000 AU A physical diameter is arcseconds",diameter>2.2 and diameter<2.5)
 sv.update(fixtures.diagnostic_3ra,.000000001)
 check("diagnostic physical A is resolved without inflation",sv.drawn_discs.has("acen-a"))
 var mat:ShaderMaterial=sv.discs["acen-a"].material_override
 check("measured disc temperature and explicit uniform photosphere",mat.get_shader_parameter("emitter_temp_k")==5795. and mat.get_shader_parameter("limb_u")==0.)
 sv.update({bodies=[]},.00001)
 check("removing physical source restores exact catalogue flux",sf.custom==original)
 sf.set_custom_stars([{id="HIP 71681",pos=[1.,0.,0.],t=5200.,flux=.04},{id="CNS5:3627",pos=[1.,0.,0.],t=5550.,flux=.03}])
 sv.update(fixtures.sol,.00001)
 check("catalogue reorder/reload suppresses exact identities again",sf.custom[1]==0. and sf.custom[5]==0.)
 sv.update({bodies=[]},.00001)
 check("reloaded originals restore without stale row cache",absf(sf.custom[1]-.04)<1e-8 and absf(sf.custom[5]-.03)<1e-8)
 sv.queue_free();sf.queue_free();await process_frame
 print("alpha-centauri: %d passed, %d failures"%[checks-failures,failures]);quit(1 if failures else 0)
