// Mirrors pinned sunholo/celestial0.1.0 rings. Bands are protocol2.5 authority.
uniform int ring_count = 0;
uniform vec4 ring_bands[16]; // inner/outer in globe radii, normal tau, w0
uniform vec3 ring_tint = vec3(1.0);
uniform float ring_outer = 1.0;
float expm1_over_x(float x) {
	if (abs(x)<0.001) return 1.0+x/2.0*(1.0+x/3.0*(1.0+x/4.0*(1.0+x/5.0)));
	return (exp(x)-1.0)/x;
}
vec4 band_at(float r) {
	for (int i=0;i<ring_count;i++) if (r>=ring_bands[i].x && r<ring_bands[i].y) return ring_bands[i];
	return vec4(0.0);
}
float ring_trans(float tau,float mu) {
	if (tau<=0.0) return 1.0;
	if (mu==0.0) return 0.0;
	return exp(-tau/abs(mu));
}
float ring_radiance(float w0,float tau,float mu0,float mu,bool lit) {
	if (mu0<=0.0 || mu<=0.0 || tau<=0.0) return 0.0;
	float value=0.0;
	if (lit) {
		float x=tau*(1.0/mu+1.0/mu0);
		float a=x<0.001?x*expm1_over_x(-x):1.0-exp(-x);
		value=w0*mu0/(4.0*(mu+mu0))*a;
	} else {
		float x=tau*(mu-mu0)/(mu*mu0);
		if (abs(x)<0.001) value=w0*mu0/4.0*exp(-tau/mu0)*tau/(mu*mu0)*expm1_over_x(x);
		else value=w0*mu0/(4.0*(mu-mu0))*(exp(-tau/mu)-exp(-tau/mu0));
	}
	// Phase P=1 is the documented single-scattering isotropic model.
	return value*lux/PI;
}
float ring_shadow(vec3 p,vec3 sun,vec3 pole) {
	float dn=dot(sun,pole);
	if (dn==0.0) return 1.0;
	float s=-dot(p,pole)/dn;
	if (s<=0.0) return 1.0;
	vec4 band=band_at(length(p+s*sun)/radius);
	return ring_trans(band.z,abs(dn));
}
bool globe_shadows_ring(vec3 p,vec3 sun) {
	float along=dot(p,sun);
	if (along>=0.0) return false;
	vec3 perpendicular=p-along*sun;
	return dot(perpendicular,perpendicular)<radius*radius;
}
