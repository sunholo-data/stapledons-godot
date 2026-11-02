"""Independent test-only Cartesian Kerr-Schild Hamiltonian oracle.
Authored by Claude Sonnet5.5 for the cross-family package evaluation (2026-11-02).
No Carter separation or regular-sphere ODE is used. Pure stdlib RK4 with
finite-difference Hamiltonian gradients; reference accuracy is measured for
escaping rays only. Near-horizon/step-limit exits are explicitly unresolved,
never capture classifications. Do not use as a game data pipeline.
CLI: python3 -I tools/kerr_ks_ref.py rays.json output.json
"""
import math,sys,json
def Hfun(X,a,p):
    x,y,z=X
    R2=x*x+y*y+z*z; A=R2-a*a
    r2=0.5*(A+math.sqrt(A*A+4*a*a*z*z)); r=math.sqrt(r2)
    H=r**3/(r**4+a*a*z*z)
    lx=(r*x+a*y)/(r2+a*a); ly=(r*y-a*x)/(r2+a*a); lz=z/r
    return H,(lx,ly,lz)
def Ham(X,p,a,E):
    # p spatial covector, p_t=-E ; g^{mn}=eta-2H l^m l^n, l^mu=(-1,l)
    H,l=Hfun(X,a,p)
    pp=p[0]**2+p[1]**2+p[2]**2
    lp=-(-E)+l[0]*p[0]+l[1]*p[1]+l[2]*p[2]   # l^mu p_mu = (-1)(-E)+l.p
    return 0.5*(-E*E+pp-2*H*lp*lp)
def rhs(X,p,a,E,sign):
    h=1e-6*max(1.0,math.sqrt(X[0]**2+X[1]**2+X[2]**2))
    dX=[0,0,0];dp=[0,0,0]
    for i in range(3):
        d=1e-5*max(1.0,abs(X[i]))
        Xp=list(X);Xm=list(X);Xp[i]+=d;Xm[i]-=d
        dp[i]=-(Ham(Xp,p,a,E)-Ham(Xm,p,a,E))/(2*d)
        q1=list(p);q2=list(p);dd=1e-6*max(1.0,abs(p[i]));q1[i]+=dd;q2[i]-=dd
        dX[i]=(Ham(X,q1,a,E)-Ham(X,q2,a,E))/(2*dd)
    return [sign*v for v in dX],[sign*v for v in dp]
def rk4(X,p,a,E,sign,h):
    k1=rhs(X,p,a,E,sign)
    X2=[X[i]+h/2*k1[0][i] for i in range(3)];p2=[p[i]+h/2*k1[1][i] for i in range(3)]
    k2=rhs(X2,p2,a,E,sign)
    X3=[X[i]+h/2*k2[0][i] for i in range(3)];p3=[p[i]+h/2*k2[1][i] for i in range(3)]
    k3=rhs(X3,p3,a,E,sign)
    X4=[X[i]+h*k3[0][i] for i in range(3)];p4=[p[i]+h*k3[1][i] for i in range(3)]
    k4=rhs(X4,p4,a,E,sign)
    Xn=[X[i]+h/6*(k1[0][i]+2*k2[0][i]+2*k3[0][i]+k4[0][i]) for i in range(3)]
    pn=[p[i]+h/6*(k1[1][i]+2*k2[1][i]+2*k3[1][i]+k4[1][i]) for i in range(3)]
    return Xn,pn
def trace(u,s,n,far=None,hf=0.004):
    nr,nt,nph=n
    sq=math.sqrt((1-s)*(1+s)); rp=1+sq; rm=1-sq
    de=u*u-2*u+s*s; aa=(u*u+s*s)**2-de*s*s
    N=math.sqrt(de*u*u/aa); om=2*s*u/aa; h=math.sqrt(aa)/u
    En=N-om*h*nph  # E_Z=1
    L=-h*nph; Eq=En
    # BL covector (unnormalised E_Z=1): p_t=-En ; p_phi=L ; p_theta=-u*nt ; p_r=-nr*sqrt(u^2/de)
    pr_bl=-nr*u/math.sqrt(de); pth=-u*nt
    # scale so E=1
    pr_bl/=En; pth/=En; L/=En
    # KS: p_r_bl = pr_ks + (2r/D) p_t + (a/D) p_phi ; p_t=-1
    prk=pr_bl-(2*u/de)*(-1.0)-(s/de)*L
    if s==0: phik=0.0
    else: phik=s/(rp-rm)*math.log((u-rp)/(u-rm))  # F(u)
    # position
    ph=phik; st=1.0; ct=0.0
    X=[st*(u*math.cos(ph)-s*math.sin(ph)),st*(u*math.sin(ph)+s*math.cos(ph)),u*ct]
    # Jacobian d(x,y,z)/d(r,th,ph)
    r=u
    J=[[st*math.cos(ph), r*0+ (ct)*(r*math.cos(ph)-s*math.sin(ph)), st*(-r*math.sin(ph)-s*math.cos(ph))],
       [st*math.sin(ph), ct*(r*math.sin(ph)+s*math.cos(ph)), st*(r*math.cos(ph)-s*math.sin(ph))],
       [ct, -r*st, 0.0]]
    # p_sph = J^T p_cart  => solve J^T p_cart = p_sph
    ps=[prk,pth,L]
    M=[[J[j][i] for j in range(3)] for i in range(3)]
    # solve M pc = ps (3x3 Cramer)
    def det(m):return (m[0][0]*(m[1][1]*m[2][2]-m[1][2]*m[2][1])-m[0][1]*(m[1][0]*m[2][2]-m[1][2]*m[2][0])+m[0][2]*(m[1][0]*m[2][1]-m[1][1]*m[2][0]))
    D=det(M);pc=[]
    for k in range(3):
        mk=[row[:] for row in M]
        for i in range(3):mk[i][k]=ps[i]
        pc.append(det(mk)/D)
    E=1.0
    far=far or max(1e7,50*u)
    p=pc;steps=0
    # sanity: Hamiltonian ~ 0
    h0=Ham(X,p,s,E)
    while True:
        R=math.sqrt(sum(c*c for c in X))
        rr=math.sqrt(0.5*((R*R-s*s)+math.sqrt((R*R-s*s)**2+4*s*s*X[2]**2)))
        if steps>400000: return dict(status='solver_steps',h0=h0)
        if rr<rp*1.01: return dict(status='near_horizon_unresolved',h0=h0)
        if rr>far: break
        step=hf*min(rr,rr*rr/ max(1,0)) if False else hf*rr
        X,p=rk4(X,p,s,E,-1.0,step);steps+=1
    v,_=rhs(X,p,s,E,-1.0)
    # asymptotic direction: past trace position direction ~ velocity direction
    nv=math.sqrt(sum(c*c for c in v)); sky=[c/nv for c in v]
    # correct for residual finite-r: position direction vs velocity differ O(b/r); use velocity
    return dict(status='escaped',sky=sky,h0=h0,steps=steps)
if __name__=="__main__":
    rays=json.load(open(sys.argv[1]))
    out=[]
    for u,s,n in rays:
        out.append(trace(u,s,n))
    json.dump(out,open(sys.argv[2],'w'))
