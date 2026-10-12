extends RefCounted
## Mirror of the active shader's uploaded float32 rebase and explicit boost.
static func uniform(mat: ShaderMaterial, name: String, fallback: Variant) -> Variant:
	var value = mat.get_shader_parameter(name)
	return fallback if value == null else value
static func context(field: Starfield) -> Dictionary:
	var mat := field.material
	return {ship=field.ship_pair(),b=Starfield.f32(uniform(mat,"beta_mag",0.)),g=Starfield.f32(uniform(mat,"gamma_f",1.)),bh=uniform(mat,"beta_dir",Vector3(0,0,-1)),om=Starfield.f32(uniform(mat,"one_minus_beta",1.)),exposure=uniform(mat,"exposure",5.),floor_flux=uniform(mat,"floor_flux",0.),floor_peak=uniform(mat,"floor_peak",0.),min_r2=uniform(mat,"min_r2",1e-6),cull_peak=uniform(mat,"cull_peak",Starfield.CULL_PEAK)}
static func direction(field: Starfield, k: int, ctx: Dictionary) -> Dictionary:
	var offset := Starfield.FLOATS*k
	var buf := field._buf
	var hi := Vector3(buf[offset+3],buf[offset+7],buf[offset+11])
	var lo := Vector3(buf[offset],buf[offset+4],buf[offset+8])
	var rel: Vector3 = (hi-ctx.ship[0])+(lo-ctx.ship[1])
	var replacement: Dictionary = field.catalogue_replacement_sources.get(field.ids[k],{})
	if not replacement.is_empty(): rel = replacement.dir * Starfield.POINT_LY
	if rel.length_squared() == 0.:return {}
	var n := rel.normalized()
	var b: float = ctx.b
	var g: float = ctx.g
	var bh: Vector3 = ctx.bh
	var d := 1.
	if b > 0.:
		var c := Starfield.f32(n.dot(bh))
		var bc := Starfield.f32(1. + Starfield.f32(b*c))
		if c < 0.:bc = Starfield.f32(ctx.om + Starfield.f32(b*Starfield.f32(1.+c)))
		d = Starfield.f32(g*bc)
		var parallel := Starfield.f32(Starfield.f32(Starfield.f32(g-1.)*c) + Starfield.f32(g*b))
		n = ((n + bh*parallel)/d).normalized()
	var result := {direction=n,doppler=d,r2=rel.length_squared()}
	if not replacement.is_empty(): result.replacement = replacement
	return result
static func visible(field: Starfield, k: int, sample: Dictionary, ctx: Dictionary) -> bool:
	var t := field.custom[k*4]
	var d: float = sample.doppler
	var flux: float = field.custom[k*4+1]*field.custom[k*4+3]/maxf(sample.r2,ctx.min_r2)
	if sample.has("replacement"):
		t = sample.replacement.t
		flux = sample.replacement.lux
	var ratio := pow(10., Blackbody.lut_log10_y(t*d)-Blackbody.lut_log10_y(t))/(d*d)
	var color: Vector3 = Blackbody.lut_rgb(t*d)*flux*ratio*float(ctx.exposure)
	var peak := maxf(color.x,maxf(color.y,color.z))
	if ctx.floor_flux > 0. and flux*ratio >= ctx.floor_flux and peak > 0.:peak = maxf(peak,ctx.floor_peak)
	return is_finite(peak) and peak >= ctx.cull_peak
static func sample(field: Starfield, k: int) -> Dictionary:
	var ctx := context(field)
	var result := direction(field,k,ctx)
	if not result.is_empty():result.visible = visible(field,k,result,ctx)
	return result
