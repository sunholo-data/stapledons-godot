extends SceneTree
var passed:=0
var failures:=0
func check(name:String,ok:bool)->void:
	if ok:passed+=1
	else:failures+=1
	print("  %s %s" % ["ok" if ok else "FAIL",name])
func _initialize()->void:
	var Coverage=load("res://ui/catalogue_coverage.gd")
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/starmap/stars.json"))
	check("declared count matches actual selectable stars",int(data.count)==data.stars.size())
	check("coverage displays actual metadata",Coverage.summary(data).contains(str(int(data.count))) and Coverage.summary(data).contains("25 pc of Sol"))
	check("coverage is anchored to Sol rather than current ship",Coverage.summary(data)==Coverage.summary(data.merged({"ship_position":[10,0,0]})))
	check("missing metadata is explicit",Coverage.summary({}).contains("unavailable"))
	check("planet knowledge and distant background limits disclosed",Coverage.details(data).contains("may be unknown") and Coverage.details(data).contains("50 light-years"))
	check("no sky line before a sky is loaded",Coverage.sky_line({})=="")
	check("the active sky tier is shown",Coverage.sky_line({"tier":"large","count":335189}).contains("large tier, 335189 stars drawn") and Coverage.sky_line({"tier":"medium","count":60883}).contains("50,000 nearest"))
	print("catalogue-coverage: %d passed, %d failures" %[passed,failures]);quit(1 if failures else 0)
