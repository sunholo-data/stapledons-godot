extends SceneTree
const Info = preload("res://ui/object_info.gd")
const Index = preload("res://ui/observation_index.gd")
const Stars = preload("res://ui/star_info.gd")
class FixtureIndex:
	extends RefCounted
	var objects := {}
	var plates := {}
	func object(id: String) -> Dictionary:return objects.get(id, {}).duplicate(true)
	func plate(id: String) -> Dictionary:return plates.get(id, {}).duplicate(true)
	func resolve(id: String) -> String:return id if objects.has(id) else ""
var passed := 0
var failures := 0
func check(ok: bool, description: String) -> void:
	if ok:passed += 1
	else:
		failures += 1
		print("FAIL object-info: "+description)
func _initialize() -> void:
	var index = Index.new()
	check(index.load_files(), "real observation sources available")
	var stars = Stars.new()
	stars.set_records([{id="fixture:near",dist_ly=4.32,teff=5800.0,vmag=0.01}])
	stars.names["fixture:near"] = "Fixture near star"
	var body := {id="fixture:body",catalogue_id="fixture:near",name="Fixture finite star",kind="star",radius_km=695700.0,rel_km={x=149597870.7,y=0.0,z=0.0},teff_k=5772.0,light_age_s=499.0,surface={cell_km=1000.0},source="Fixture radius measured; surface pattern modelled"}
	var world := {system={bodies=[body]}}
	var cat := {kind="catalogue",id="fixture:near"}
	var body_ref := {kind="body",id="fixture:body"}
	var a: Dictionary = Info.facts(cat, index, stars, world)
	check(a.get("available",false) and a.get("title")=="Fixture near star", "known catalogue identity and display name")
	var cat_text := Info.text(cat,index,stars,world)
	check(cat_text.contains("Catalogue") and cat_text.contains("distance from Sol"), "catalogue reference frame labelled")
	check(cat_text.contains("From the ship now") and cat_text.contains("light") and cat_text.contains("8.3 min"), "live light age stays in live section")
	check(not a.get("image_available",true) and a.get("plate_id","").is_empty(), "nearby star does not inherit Euclid coverage")
	check(a.get("live_body_id") == body.id, "exact catalogue to finite star association")
	check(Info.live_body(body_ref,world,stars).get("id")==body.id, "body reference resolves exact live snapshot")
	check(Info.live_body({kind="catalogue",id="Fixture near star"},world,stars).is_empty(), "display name cannot match a body")
	check(Info.live_body({kind="body",id="fixture:near"},world,stars).is_empty(), "catalogue identity cannot be mistaken for body identity")
	check(Info.text(body_ref,index,stars,world).contains("modelled"), "stellar model is not described as measured photosphere imagery")
	var inferred := body.duplicate(true)
	inferred.status="inferred"
	inferred.inferred={r_sun=0.1,l_sun=0.01,bc_v=-1.0,v=10.0,distance_pc=3.0}
	check(Info.text(body_ref,index,stars,{system={bodies=[inferred]}}).contains("Radius inferred, not measured"), "existing inferred-radius provenance preserved")
	var sid := "DR1_R2:dr1.mer_catalogue_wide_survey:102017310:-524917322525922548"
	var survey := {kind="survey",id=sid}
	var s: Dictionary = Info.facts(survey,index,stars,world)
	var survey_text := Info.text(survey,index,stars,world)
	check(s.get("available",false) and s.get("plate_id")=="abell3128-vis" and s.get("image_available",false), "real measured source retains archive image association")
	check(survey_text.contains("Survey observation") and survey_text.contains("2024-07-14") and survey_text.contains("VIS"), "actual observation date and band are visible")
	check(survey_text.contains("Distance unavailable") and not survey_text.contains("light you see left"), "missing galaxy distance is not converted to live light age")
	check(survey_text.contains("512") and survey_text.contains("classification"), "quality flag and unclassified/candidate status retained")
	check(Info.live_body(survey,world,stars).is_empty(), "survey source never resolves a live stellar renderer by coincidence")
	var fixture = FixtureIndex.new()
	fixture.objects["fixture:galaxy"]={id="fixture:galaxy",kind="galaxy",name="Fixture galaxy",status="candidate",plate_id="fixture:plate",ra_deg=52.5,dec_deg=-52.6,redshift=0.21,distance_ly=null,point_like_probability=0.001,flags={det_quality_flag=512},provenance="measured",source_url="https://example.test/catalogue"}
	fixture.plates["fixture:plate"]={id="fixture:plate",band="VIS",observation_start="2024-07-14",registered=false,source_url="https://example.test/plate",licence="Fixture licence",credit="Fixture credit",levels=[{path="fixture.png"}]}
	var gx := {kind="survey",id="fixture:galaxy"}
	var gt := Info.text(gx,fixture,stars,world)
	check(gt.contains("Galaxy candidate") and gt.contains("Redshift") and gt.contains("0.21"), "published candidate class and redshift retained literally")
	check(gt.contains("Unregistered") and gt.contains("Fixture licence"), "plate registration status and rights exposed")
	fixture.objects["fixture:galaxy"].plate_id = "missing"
	check(not Info.facts(gx,fixture,stars,world).get("image_available",true) and Info.text(gx,fixture,stars,world).contains("No survey image"), "missing image retains useful object inspection")
	check(not Info.facts({kind="catalogue",id="missing"},index,stars,world).get("available",true), "missing catalogue identity unavailable")
	check(not Info.facts({kind="body",id="missing"},index,stars,world).get("available",true), "missing body identity unavailable")
	check(not Info.facts({kind="survey",id="missing"},index,stars,world).get("available",true), "missing survey identity unavailable")
	var invalid = Stars.new()
	invalid.set_records([{id="fixture:bad",dist_ly=NAN,teff=INF,vmag=NAN}])
	var invalid_text := Info.text({kind="catalogue",id="fixture:bad"},index,invalid,{})
	check(not invalid_text.to_lower().contains("nan") and not invalid_text.to_lower().contains("inf k") and invalid_text.contains("unavailable"), "nonfinite catalogue values are unavailable")
	var invalid_body := body.duplicate(true)
	invalid_body.rel_km.x = NAN
	check(Info.live_body(body_ref,{system={bodies=[invalid_body]}},stars).is_empty(), "invalid live data cannot become a usable renderer target")
	check(Info.facts({kind="catalogue",id="fixture:near"},index,stars,{system={bodies=[body,body.duplicate(true)]}}).get("live_body_id","").is_empty(), "ambiguous live catalogue association is not guessed")
	var no_catalogue = Stars.new()
	check(not Info.facts(cat,index,no_catalogue,world).get("available",true) and Info.live_body(cat,world,no_catalogue).is_empty(), "live body cannot substitute for a missing catalogue record")
	var optional_bad := body.duplicate(true)
	optional_bad.teff_k = NAN
	optional_bad.light_age_s = INF
	optional_bad.inferred = {l_sun=0.0,v=10.0,distance_pc=3.0,bc_v=-1.0}
	optional_bad.sync_orbit = {rotation_days=INF,radius_km=100.0}
	var optional_text := Info.text(body_ref,index,stars,{system={bodies=[optional_bad]}}).to_lower()
	check(not optional_text.contains("nan") and not optional_text.contains("inf ") and not optional_text.contains("radius inferred"), "invalid optional live facts do not enter formatter calculations")
	var enormous := body.duplicate(true)
	enormous.rel_km.x = 1.0e308
	check(Info.live_body(body_ref,{system={bodies=[enormous]}},stars).is_empty(), "overflowed derived live distance is unavailable")
	check(Info.live_body(body_ref,{system={bodies=[body,body.duplicate(true)]}},stars).is_empty(), "duplicate body identity is ambiguous")
	var copied := Info.live_body(body_ref,world,stars)
	copied.name = "mutated"
	check(body.name == "Fixture finite star", "inspection cannot mutate simulation snapshot")
	check(not gt.contains("Star candidate") and gt.contains("classification"), "probability never replaces published candidate classification")
	check(str(s.get("provenance")).contains("methods vary") and a.get("provenance") == "catalogue", "mixed survey methods cannot be labelled uniformly measured")
	check(survey_text.contains("classifier output") and survey_text.contains("epoch unavailable") and survey_text.contains("measured"), "per-fact measured/classifier methods and unknown epochs are explicit")
	print("object-info: %d passed, %d failures" % [passed, failures])
	quit(1 if failures else 0)
