extends RefCounted
## Render attitude only. Float64 unit rotations; never edits motion, velocity or
## position. Stationary turns precede commitment; moving legs retain D-14.
var current:=PackedFloat64Array()
var _from:=PackedFloat64Array()
var _target:=PackedFloat64Array()
var _elapsed:=0.
var _duration:=0.
func reset(b:PackedFloat64Array)->void:
	current=b.duplicate();_target=b.duplicate();_duration=0.
func turning()->bool:return _duration>0. and _elapsed<_duration
func turn_to(b:PackedFloat64Array,seconds:float)->void:
	if current.is_empty():reset(b);return
	_from=current.duplicate();_target=b.duplicate();_elapsed=0.;_duration=maxf(seconds,0.)
	if _duration==0.:current=_target.duplicate()
func advance(delta:float)->void:
	if not turning():return
	_elapsed=minf(_duration,_elapsed+maxf(delta,0.))
	if _duration-_elapsed<1e-10:_elapsed=_duration
	if not turning():current=_target.duplicate();return
	var t:float=_elapsed/_duration;t=t*t*(3.-2.*t)
	var a:=_quat(_from);var b:=_quat(_target)
	var dot:=0.
	for i in 4:dot+=a[i]*b[i]
	if dot<0.:
		for i in 4:b[i]=-b[i]
		dot=-dot
	var p:=1.-t;var q:=t
	if dot<.9995:
		var angle:=acos(clampf(dot,-1.,1.));var den:=sin(angle)
		p=sin((1.-t)*angle)/den;q=sin(t*angle)/den
	var v:=PackedFloat64Array([0.,0.,0.,0.]);var length:=0.
	for i in 4:v[i]=a[i]*p+b[i]*q;length+=v[i]*v[i]
	for i in 4:v[i]/=sqrt(length)
	current=_basis(v)
static func side_basis(body:PackedFloat64Array)->PackedFloat64Array:
	var n:=ShipFrame._unit([body[0],body[1],body[2]])
	var tangent:=ShipFrame._reject(ShipFrame.NGP,n)
	if ShipFrame._len(tangent)<ShipFrame.POLE_EPS:tangent=ShipFrame._reject(ShipFrame.POLE_FALLBACK,n)
	tangent=ShipFrame._unit(tangent)
	var angle:=deg_to_rad(15.)
	var up:=PackedFloat64Array([cos(angle)*tangent[0]+sin(angle)*n[0],cos(angle)*tangent[1]+sin(angle)*n[1],cos(angle)*tangent[2]+sin(angle)*n[2]])
	var x:=ShipFrame._unit(ShipFrame._reject(n,up))
	var y:=ShipFrame._cross(up,x)
	return PackedFloat64Array([x[0],x[1],x[2],y[0],y[1],y[2],up[0],up[1],up[2]])
static func _quat(b:PackedFloat64Array)->PackedFloat64Array:
	var q:=PackedFloat64Array([0.,0.,0.,0.]);var trace:=b[0]+b[4]+b[8]
	if trace>0.:
		var s:=2.*sqrt(trace+1.)
		q=PackedFloat64Array([(b[5]-b[7])/s,(b[6]-b[2])/s,(b[1]-b[3])/s,s*.25])
	else:
		var i:=0
		if b[4]>b[0]:i=1
		if b[8]>b[3*i+i]:i=2
		var j:=(i+1)%3;var k:=(i+2)%3
		var s:=2.*sqrt(1.+b[3*i+i]-b[3*j+j]-b[3*k+k])
		q[i]=s*.25;q[j]=(b[3*i+j]+b[3*j+i])/s;q[k]=(b[3*i+k]+b[3*k+i])/s;q[3]=(b[3*j+k]-b[3*k+j])/s
	return q
static func _basis(q:PackedFloat64Array)->PackedFloat64Array:
	var x:=q[0];var y:=q[1];var z:=q[2];var w:=q[3]
	return PackedFloat64Array([1.-2.*(y*y+z*z),2.*(x*y+w*z),2.*(x*z-w*y),2.*(x*y-w*z),1.-2.*(x*x+z*z),2.*(y*z+w*x),2.*(x*z+w*y),2.*(y*z-w*x),1.-2.*(x*x+y*y)])
