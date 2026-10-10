"""Independent evaluator oracle: midpoint quadrature in rapidity, not Simpson in x."""
import importlib.util, json, math, functools, time
from pathlib import Path

path=Path(__file__).with_name('ism_dust_ref.py')
spec=importlib.util.spec_from_file_location('ref',path)
o=importlib.util.module_from_spec(spec);spec.loader.exec_module(o)

# Independent Planck/ybar integration sampled more finely than the sim's 0.01-dex LUT.
step=0.001
lut=[o.efficacy(10**(1+i*step)) for i in range(6001)]
def efficacy(T):
    if T<=10:return 0.0
    x=(math.log10(T)-1)/step
    i=max(0,min(len(lut)-2,int(x))); f=x-i
    lo,hi=lut[i],lut[i+1]
    if lo>0 and hi>0:return math.exp(math.log(lo)+f*(math.log(hi)-math.log(lo)))
    return lo+f*(hi-lo)
o.efficacy=efficacy

phi=math.acosh(1/math.sqrt(1-0.999**2))
a=750000*9.80665/299792458*31557600
distance=20.43*o.PC_M/o.LY_M
d_burn=(math.cosh(phi)-1)/a
d_coast=distance-2*d_burn
dest=o.mul(o.unit_lb(180.97,-20.25),20.43)
segments=[(lo*distance,hi*distance,name) for lo,hi,name in o.profile((0,0,0),dest)]
distributions={name:o.dist_for(name) for _,_,name in segments}

@functools.lru_cache(None)
def density(name,p):
    if p<=0:return 0.0
    d=distributions[name]
    bg=o.glow_pole_luminance(o.n_eff_m3(name),p)+0.00004327
    threshold=o.visible_radius(d,p,1e-10,0.5,0.5,0.2,bg,1.0)
    return d.above(threshold)

def quadrature(n):
    integral=0.0
    for lo,hi,name in segments:
        coast_lo=max(lo,d_burn);coast_hi=min(hi,d_burn+d_coast)
        if coast_hi>coast_lo:integral+=(coast_hi-coast_lo)*density(name,phi)
        for burning in [True,False]:
            x0=max(lo,0 if burning else d_burn+d_coast)
            x1=min(hi,d_burn if burning else distance)
            if x1<=x0:continue
            remaining=lambda x:x if burning else distance-x
            p0=math.acosh(1+a*remaining(x0));p1=math.acosh(1+a*remaining(x1))
            p0,p1=sorted([p0,p1])
            width=(p1-p0)/n
            integral+=sum(density(name,p0+(i+0.5)*width)*math.sinh(p0+(i+0.5)*width)/a for i in range(n))*width
    return integral*math.pi*100**2*o.LY_M

results=[]
for n in [256,512,1024,2048]:
    start=time.time();value=quadrature(n)
    results.append({'midpoints_per_medium_phase':n,'bright_expected':value,'elapsed_s':time.time()-start})
    print(n,value,flush=True)
report={'method':'independent dense midpoint quadrature in rapidity; Planck/ybar oracle with 0.001-dex LUT','distance_ly':distance,'a_c_per_year':a,'phi_peak':phi,'d_burn_ly':d_burn,'d_coast_ly':d_coast,'segments':segments,'resolutions':results,'convergence_relative':abs(results[-1]['bright_expected']/results[-2]['bright_expected']-1)}
print(json.dumps(report, indent=2))
assert report['convergence_relative'] < 1e-8
assert abs(results[-1]['bright_expected'] / 1961369584.1362152 - 1) < 1e-8
