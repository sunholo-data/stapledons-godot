"""Independent test-only finite-observer Kerr null-ray oracle (G=M=c=1).
Carter68/BPT72 model; second-order Hamiltonian Mino ODE, adaptive DOP853.
Regular angular sphere chart handles lambda=0 axis crossing without cot(theta).
Future incoming p=e0-n^i ei; integrate toward source with past Mino parameter.
Time/azimuth retained at a finite far sphere; sky extrapolated to infinity.
Requires scipy/numpy; no production use, no package calls.
"""
import math,json,sys
import numpy as np
from scipy.integrate import solve_ivp
from scipy.optimize import brentq

def constants(u,s,n):
    nr,nt,np_=n
    assert 0<=s<=.998 and u>=4 and abs(sum(x*x for x in n)-1)<1e-12
    de=(u-1-math.sqrt((1-s)*(1+s)))*(u-1+math.sqrt((1-s)*(1+s)))
    aa=(u*u+s*s)**2-de*s*s; lapse=math.sqrt(de*u*u/aa); omega=2*s*u/aa; h=math.sqrt(aa)/u
    en=lapse-omega*h*np_; lam=-h*np_/en; eta=(u*nt/en)**2
    return en,lam,eta,-nr*math.sqrt(de)/(u*en),u*nt/en

def capture(u,s,lam,eta,nr):
    # Independent polynomial allowed-interval classification, not a solver timeout.
    aa=s*s-lam*lam-eta; bb=(lam-s)**2+eta; cc=-s*s*eta
    f=lambda x: x**4+aa*x*x+2*bb*x+cc
    hp=1+math.sqrt((1-s)*(1+s)); top=1+max(abs(aa),2*abs(bb),abs(cc))
    stationary=sorted(x.real for x in np.roots([2.,0.,aa,bb]) if abs(x.imag)<1e-10 and hp<x.real<top)
    cuts=[hp]+stationary+[max(top,u+1)]; roots=[]; critical=[]
    for x in stationary:
        if abs(f(x))<1e-11*max(1,x**4): critical.append(x)
    for l,r in zip(cuts,cuts[1:]):
        if f(l)*f(r)<0: roots.append(brentq(f,l,r,xtol=1e-13,rtol=1e-14))
    roots.extend(critical)
    lo=max([hp]+[r for r in roots if r<u-1e-9]); hi=min([math.inf]+[r for r in roots if r>u+1e-9])
    if nr==0:
        nr=2*u**3+aa*u+bb # past radial acceleration decides simple tangent
    reachable=lo if nr<0 else hi
    if any(abs(x-reachable)<1e-7 for x in critical): return 'critical'
    if nr<0 and lo==hp: return 'captured'
    if nr>=0 and math.isinf(hi): return 'escaped'
    if nr<0 and math.isinf(hi): return 'escaped' # simple outer turning root
    if nr>=0 and lo==hp: return 'captured' # outward ray returns inward
    return 'trapped_or_critical'

def trace(u,s,n,rtol=2e-12,far=1e5):
    en,lam,eta,wv,tv=constants(u,s,n); status=capture(u,s,lam,eta,n[0])
    if status!='escaped': return dict(status=status,lambda_=lam,eta=eta)
    aa=s*s-lam*lam-eta; bb=(lam-s)**2+eta; kk=lam*lam+eta
    # w=1/u, w', m[3], m'[3], drag angle, BL t. m lies on a regular sphere.
    y0=[1/u,wv,1.,0.,0.,0.,-lam,-tv,0.,0.]
    def rhs(z,y):
        w,dw=y[:2]; m=y[2:5]; dm=y[5:8]; q=m[2]; de=1-2*w+s*s*w*w
        acc=s*s*q*np.array([0.,0.,1.])-(kk+2*s*s*q*q)*m
        drag=-s*(2*w-s*lam*w*w)/de
        time=-((1+s*s*w*w)*(1+(s*s-s*lam)*w*w)/(w*w*de)+s*(lam-s*(1-q*q)))
        return [dw,aa*w+3*bb*w*w-2*s*s*eta*w**3,*dm,*acc,drag,time]
    def escape(z,y): return y[0]-1/far
    escape.terminal=True; escape.direction=-1
    sol=solve_ivp(rhs,(0,20),y0,method='DOP853',rtol=rtol,atol=rtol*.01,events=escape,max_step=.03/max(1,math.sqrt(kk)))
    if not sol.success or len(sol.t_events[0])!=1: raise RuntimeError('escape integration failed; never reclassify as captured')
    y=sol.y[:,-1];w=y[0];m=y[2:5];dm=y[5:8];q=m[2]
    # Remaining Mino duration w+O(w^3); second-order angular tail, drag tail -s*w^2.
    acc=s*s*q*np.array([0.,0.,1.])-(kk+2*s*s*q*q)*m
    mf=m+dm*w+acc*w*w/2; mf/=np.linalg.norm(mf); drag=y[8]-s*w*w
    cs,sn=math.cos(drag),math.sin(drag); sky=np.array([cs*mf[0]-sn*mf[1],sn*mf[0]+cs*mf[1],mf[2]])
    w_all=sol.y[0];q_all=sol.y[4]; W=1+aa*w_all*w_all+2*bb*w_all**3-s*s*eta*w_all**4
    radial=float(np.max(abs(sol.y[1]**2-W)/(1+abs(W))))
    angular=float(np.max(abs(np.sum(sol.y[5:8]**2,axis=0)-(kk+s*s*q_all*q_all))/(1+kk)))
    sphere=float(np.max(abs(np.sum(sol.y[2:5]**2,axis=0)-1)))
    null=[]
    for zz,yy in zip(sol.t,sol.y.T):
        ww=yy[0]; uu=1/ww; mm=yy[2:5]; ddm=yy[5:8]; sn2=mm[0]**2+mm[1]**2; co=mm[2]
        sg=uu*uu+s*s*co*co; de=uu*uu-2*uu+s*s
        dv=rhs(zz,yy); du=-yy[1]/(ww*ww); dt=dv[9]
        dtheta=-ddm[2]/math.sqrt(sn2); dphi=dv[8]+(mm[0]*ddm[1]-mm[1]*ddm[0])/sn2
        gtt=-1+2*uu/sg; gtp=-2*s*uu*sn2/sg; gpp=(uu*uu+s*s+2*s*s*uu*sn2/sg)*sn2
        terms=[gtt*dt*dt,2*gtp*dt*dphi,gpp*dphi*dphi,sg/de*du*du,sg*dtheta*dtheta]
        null.append(abs(sum(terms))/sum(abs(x) for x in terms))
    phi=np.unwrap(np.arctan2(sol.y[3],sol.y[2]))+sol.y[8]
    return dict(status=status,lambda_=lam,eta=eta,sky=sky.tolist(),theta=math.acos(max(-1,min(1,y[4]))),phi=float(phi[-1]),t=float(y[9]),far=far,steps=len(sol.t),radial=radial,angular=angular,sphere=sphere,null=max(null))

def direction(psi,chi): return (-math.cos(psi),math.sin(psi)*math.sin(chi),math.sin(psi)*math.cos(chi))
def angle(a,b):return float(np.linalg.norm(np.array(a)-np.array(b)))

def nearcritical():
    rows=[]
    for s in [.9,.998]:
      lo=2*(1+math.cos(2/3*math.acos(-s))); hi=2*(1+math.cos(2/3*math.acos(s)))
      for orbit in [lo,3.,hi]:
        lam=-(orbit**3-3*orbit**2+s*s*orbit+s*s)/(s*(orbit-1)); de=orbit*orbit-2*orbit+s*s
        eta=4*orbit*orbit*de/(orbit-1)**2-(lam-s)**2
        if abs(eta)<1e-10: eta=0. # endpoint roundoff only, with explicit budget
        u=6.; d=u*u-2*u+s*s; aa=(u*u+s*s)**2-d*s*s
        N=math.sqrt(d*u*u/aa); om=2*s*u/aa; h=math.sqrt(aa)/u
        E=N/(1-om*lam); np_=-lam*E/h; nt=math.sqrt(eta)*E/u
        for eps in [1e-5,1e-8]:
            f=1+eps; n=(-math.sqrt(1-(nt*nt+np_*np_)*f*f),nt*f,np_*f)
            a=trace(u,s,n,rtol=2e-12); b=trace(u,s,n,rtol=2e-13,far=1e6)
            assert a['status']==b['status']=='escaped'
            error=angle(a['sky'],b['sky']); assert error<1.2e-4
            rows.append(dict(s=s,u=u,critical_u=orbit,epsilon=eps,n=n,sky=b['sky'],refinement=error))
    return rows

def nearaxis():
    """Near-pole accuracy probes; both hemispheres and azimuth senses."""
    rows=[]
    for s in [0.,.1,.25,.5,.75,.9,.998]:
     for u in [4.,6.,2e6]:
      for nr in [-.6,.6]:
       for hemisphere in [-1,1]:
        for sense in [-1,1]:
         for ep in [1e-14,1e-6]:
            n=(nr,hemisphere*math.sqrt(.64-ep*ep),sense*ep)
            a=trace(u,s,n,rtol=2e-12,far=max(1e5,u*1000))
            if a['status']=='escaped':
                b=trace(u,s,n,rtol=2e-13,far=max(1e6,u*10000))
                a['refinement']=angle(a['sky'],b['sky'])
                assert a['refinement']<1e-8,a
                assert max(a[k] for k in ['radial','angular','sphere','null'])<1e-8,a
                a['sky']=b['sky']
            a.update(s=s,u=u,n=n);rows.append(a)
    return rows

if __name__=='__main__':
    if len(sys.argv)>1 and sys.argv[1]=="--nearaxis":
        print(json.dumps(nearaxis(),indent=2)); sys.exit(0)
    if len(sys.argv)>1 and sys.argv[1]=="--nearcritical":
        print(json.dumps(nearcritical(),indent=2)); sys.exit(0)
    rows=[]
    for s in [0.,.9,.998]:
      for u in [4.,6.,20.]:
       for psi,chi in [(0.,0.),(.4,0.),(.9,0.),(.9,math.pi),(1.2,.7),(1.2,math.pi/2),(1.8,2.4),(2.7,5.2)]:
        row=trace(u,s,direction(psi,chi));row.update(s=s,u=u,psi=psi,chi=chi)
        if row['status']=='escaped':
            fine=trace(u,s,direction(psi,chi),rtol=2e-13,far=1e6)
            row['refinement']=angle(row['sky'],fine['sky'])
            assert row['refinement']<1e-8,row
            assert max(row[k] for k in ['radial','angular','sphere'])<1e-8,row
        rows.append(row)
    print("[\n"+",\n".join(json.dumps(row) for row in rows)+"\n]")
