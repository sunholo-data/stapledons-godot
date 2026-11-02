#!/usr/bin/env python3
"""Independent R2-KERR scalar/frame/full-curvature/null-ray digest test oracle.
Requires the optional kerr-oracle-requirements.txt; never production tooling.
"""
from decimal import Decimal as D
from pathlib import Path
import math,runpy,sys
base=Path(__file__).parent
ref=runpy.run_path(str(base/'kerr_ref.py'))
curv=runpy.run_path(str(base/'kerr_curvature_ref.py'))
null=runpy.run_path(str(base/'kerr_null_ref.py'))

def row(i):
    s=D(['0','0.9','0.998'][i%3]);u=D(6)+D(i)/4
    de=u*u-2*u+s*s;aa=(u*u+s*s)**2-de*s*s
    N=(de*u*u/aa).sqrt();w=2*s*u/aa;h=(aa/u/u).sqrt()
    static=(1-2/u).sqrt();energy=N-w*h*D('.8');lam=-h*D('.8')/energy
    def orbit(k):
        om=k/(u*u.sqrt()+k*s)
        clock=u**D('.75')*(u**D('1.5')-3*u.sqrt()+2*k*s).sqrt()/(u**D('1.5')+k*s)
        return om,clock,(om-w)*h/N
    op,cp,vp=orbit(1);orr,cr,vr=orbit(-1)
    freqp=(1+w*0)/N*(1-w*lam)*(1+vp*D('.8'))/(1-vp*vp).sqrt()
    eigen=curv['tides'](str(u),str(s),'pro')['eigen']
    ray=null['trace'](float(u),float(s),(.6,0.,.8),rtol=2e-13,far=1e6)['sky']
    pro,ret=ref['photon_orbits'](str(s));ip,ir=ref['isco_radii'](str(s))
    hp,hm=ref['horizons'](str(s))
    numbers=[hp/2,hm/2,D(1),pro/2,ret/2,ip/2,ir/2,
             s/(2*hp),w,N,static,op,orr,cp,cr,vp,vr,-2*s,D(27),
             1/static,freqp,lam,D(0),-4*eigen[0],4*eigen[1],4*eigen[2]]
    return sum(float(x) for x in numbers)+.001*(ray[0]+2*ray[1]+3*ray[2])

def digest(n):
    if not 0<n<=64: raise ValueError('n must be 1..64')
    return sum(row(i) for i in range(n))
if __name__=='__main__': print(format(digest(int(sys.argv[1]) if len(sys.argv)>1 else 16),'.17g'))
