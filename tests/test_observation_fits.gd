extends SceneTree
const Fits = preload("res://tools/observation_fits.gd")
var passed := 0
var failed := 0

func check(ok: bool, label: String) -> void:
	if ok: passed += 1; print("ok ", label)
	else: failed += 1; printerr("FAIL ", label)

func fixture(bitpix := -32, values := [-0.25, 0.0, 1.5, 11.0], extra: Array = [], ctype1 := "'RA---TAN'") -> PackedByteArray:
	var head := ""
	for pair in [["SIMPLE", "T"], ["BITPIX", str(bitpix)], ["NAXIS", "2"], ["NAXIS1", "2"], ["NAXIS2", "2"], ["CTYPE1", ctype1], ["CTYPE2", "'DEC--TAN'"]]:
		head += (str(pair[0]).rpad(8) + "= " + str(pair[1]).lpad(20)).rpad(80)
	for pair in extra:
		head += (str(pair[0]).rpad(8) + "= " + str(pair[1]).lpad(20)).rpad(80)
	head += "END".rpad(80)
	head = head.rpad(2880)
	var stream := StreamPeerBuffer.new()
	stream.big_endian = true
	for v in values: stream.put_float(v)
	return head.to_ascii_buffer() + stream.data_array

func _init() -> void:
	var result: Dictionary = Fits.decode(fixture())
	check(result.get("ok", false), "supported uncompressed primary float image decoded")
	if result.get("ok", false):
		var image: Image = result.image
		check(image.get_width() == 2 and image.get_height() == 2, "dimensions decoded")
		check(image.get_pixel(0, 0).r == -0.25 and image.get_pixel(1, 1).r == 11.0, "big endian floats and negative calibrated flux retained")
	check(not Fits.decode(fixture(16)).get("ok", false), "unsupported integer FITS rejected")
	check(not Fits.decode(fixture(-32, [NAN, 0.0, 0.0, 0.0])).get("ok", false), "non-finite pixel rejected")
	var short := fixture()
	short.resize(2881)
	check(not Fits.decode(short).get("ok", false), "truncated pixel data rejected")
	check(not Fits.decode(PackedByteArray([1,2,3])).get("ok", false), "non-FITS input rejected")
	var header := {"NAXIS1":"2","NAXIS2":"2","CTYPE1":"RA---TAN","CTYPE2":"DEC--TAN","RADESYS":"ICRS","CRPIX1":"1.5","CRPIX2":"1.5","CRVAL1":"52.5","CRVAL2":"-52.6","CD1_1":"-2.777777777778D-5","CD1_2":"0","CD2_1":"0","CD2_2":"2.777777777778E-5"}
	var registration := {frame="ICRS",projection="TAN",width=2,height=2,wcs={crpixX=1.5,crpixY=1.5,crvalRaDeg=52.5,crvalDecDeg=-52.6,cd11=-2.777777777778e-5,cd12=0.,cd21=0.,cd22=2.777777777778e-5}}
	check(Fits.registration_errors(header,registration).is_empty(),"complete FITS registration including D exponent has a positive control")
	for key in ["CRPIX1","CRPIX2","CRVAL1","CRVAL2","CD1_1","CD1_2","CD2_1","CD2_2"]:
		var wrong := header.duplicate(true)
		wrong[key] = "0.25"
		check(not Fits.registration_errors(wrong,registration).is_empty(),"manifest checked against actual header "+key)
	for key in ["CTYPE1","CTYPE2","RADESYS"]:
		var wrong := header.duplicate(true)
		wrong[key]="unsupported"
		check(not Fits.registration_errors(wrong,registration).is_empty(),"unsupported celestial axis/frame rejected "+key)
	var missing := header.duplicate(true)
	missing.erase("CD1_1")
	check(not Fits.registration_errors(missing,registration).is_empty(),"missing required authoritative coefficient rejected")
	for key in ["PV1_0","PV2_1","A_ORDER","B_ORDER","AP_ORDER","BP_ORDER","A_0_2","CPDIS1","D2IMDIS1"]:
		var distorted := header.duplicate(true)
		distorted[key]="1"
		check(not Fits.registration_errors(distorted,registration).is_empty(),"distorted registration rejected "+key)
		check(not Fits.decode(fixture(-32,[-0.25,0.,1.5,11.],[[key,"1"]])).get("ok",false),"distorted FITS encoding refused "+key)
	var sip := header.duplicate(true)
	sip.CTYPE1="RA---TAN-SIP"
	check(not Fits.registration_errors(sip,registration).is_empty(),"CTYPE SIP cannot masquerade as undistorted TAN")
	check(not Fits.decode(fixture(-32,[-0.25,0.,1.5,11.],[],"'RA---TAN-SIP'")).get("ok",false),"SIP primary header refused without duplicate-key confound")
	for key in ["PC1_1","CDELT1","CROTA2","LONPOLE","LATPOLE"]:
		var unsupported := header.duplicate(true)
		unsupported[key]="1"
		check(not Fits.registration_errors(unsupported,registration).is_empty(),"unsupported alternate WCS encoding refused "+key)
	check(not Fits.decode(fixture(-32,[-0.25,0.,1.5,11.],[["BZERO","garbage"]])).get("ok",false),"malformed numeric calibration cannot silently become zero")
	print("observation-fits-test: %d passed, %d failures" % [passed, failed])
	quit(1 if failed else 0)
