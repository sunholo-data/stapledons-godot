"""Independent Kerr curvature oracle: metric -> exact jet derivatives -> R_abcd.
Signature -+++; R^a_bcd = d_c Gamma^a_db - d_d Gamma^a_cb + ...
Sources: BPT72 ApJ178 347, metric and ZAMO tetrad; no Psi2 in oracle.
Coordinates t,u,theta,phi; units M=G=c=1. Pure-boost ship tetrad.
"""
import json
from decimal import Decimal as D, getcontext
getcontext().prec=60
Z,O=D(0),D(1)
class Math:
    sqrt = staticmethod(lambda x: D(x).sqrt())
math=Math()

class J:
    def __init__(self,v,d=(Z,Z),h=((Z,Z),(Z,Z))): self.v,self.d,self.h=D(v),d,h
    def __add__(self,b):
        b=b if isinstance(b,J) else J(b)
        return J(self.v+b.v,tuple(self.d[i]+b.d[i] for i in range(2)),tuple(tuple(self.h[i][j]+b.h[i][j] for j in range(2)) for i in range(2)))
    __radd__=__add__
    def __neg__(self): return self*(-O)
    def __sub__(self,b): return self+-b
    def __rsub__(self,b): return -self+b
    def __mul__(self,b):
        b=b if isinstance(b,J) else J(b)
        return J(self.v*b.v,tuple(self.d[i]*b.v+self.v*b.d[i] for i in range(2)),tuple(tuple(self.h[i][j]*b.v+self.d[i]*b.d[j]+self.d[j]*b.d[i]+self.v*b.h[i][j] for j in range(2)) for i in range(2)))
    __rmul__=__mul__
    def inv(self):
        v=self.v
        return J(1/v,tuple(-x/v**2 for x in self.d),tuple(tuple(2*self.d[i]*self.d[j]/v**3-self.h[i][j]/v**2 for j in range(2)) for i in range(2)))
    def __truediv__(self,b): return self*(b.inv() if isinstance(b,J) else 1/b)
    def __rtruediv__(self,b): return self.inv()*b
    def __pow__(self,n):
        z=J(O)
        for _ in range(n): z=z*self
        return z
    def cos(self):
        c,s=Z,O  # exact equatorial cos(theta), sin(theta); derivatives remain nonzero
        return J(c,tuple(-s*x for x in self.d),tuple(tuple(-c*self.d[i]*self.d[j]-s*self.h[i][j] for j in range(2)) for i in range(2)))

def metric(u,theta,a):
    u,theta,a=D(u),D(theta),D(a)
    assert theta==0, "equatorial oracle: theta=0 is the chart offset from pi/2"
    r=J(u,(O,Z)); th=J(theta,(Z,O)); co=th.cos(); sn2=1-co*co
    sg=r*r+a*a*co*co; de=r*r-2*r+a*a
    g=[[J(Z) for j in range(4)] for i in range(4)]
    g[0][0]=-1+2*r/sg; g[0][3]=g[3][0]=-2*a*r*sn2/sg
    g[1][1]=sg/de; g[2][2]=sg; g[3][3]=(r*r+a*a+2*a*a*r*sn2/sg)*sn2
    return g

def geometry(u,theta,a):
    jets=metric(u,theta,a); g=[[x.v for x in row] for row in jets]
    def d(i,j,k): return jets[i][j].d[k-1] if k in (1,2) else Z
    def dd(i,j,k,l): return jets[i][j].h[k-1][l-1] if k in (1,2) and l in (1,2) else Z
    gi=[[Z]*4 for _ in range(4)]; det=g[0][0]*g[3][3]-g[0][3]**2
    gi[0][0]=g[3][3]/det; gi[3][3]=g[0][0]/det; gi[0][3]=gi[3][0]=-g[0][3]/det
    gi[1][1]=1/g[1][1]; gi[2][2]=1/g[2][2]
    ga=[[[sum(gi[i][l]*(d(l,k,j)+d(l,j,k)-d(j,k,l))/2 for l in range(4)) for k in range(4)] for j in range(4)] for i in range(4)]
    r={}
    for i in range(4):
      for j in range(4):
       for k in range(4):
        for l in range(4):
          r[i,j,k,l]=(dd(i,l,j,k)+dd(j,k,i,l)-dd(i,k,j,l)-dd(j,l,i,k))/2+sum(g[p][q]*(ga[p][j][k]*ga[q][i][l]-ga[p][j][l]*ga[q][i][k]) for p in range(4) for q in range(4))
    ric=[[sum(gi[i][k]*r[i,j,k,l] for i in range(4) for k in range(4)) for l in range(4)] for j in range(4)]
    lapse=1/math.sqrt(-gi[0][0]); omega=-g[0][3]/g[3][3]
    z=[[1/lapse,Z,Z,omega/lapse],[Z,math.sqrt(gi[1][1]),Z,Z],[Z,Z,math.sqrt(gi[2][2]),Z],[Z,Z,Z,1/math.sqrt(g[3][3])]]
    ric_z=[[sum(ric[i][j]*z[p][i]*z[q][j] for i in range(4) for j in range(4)) for q in range(4)] for p in range(4)]
    return g,r,z,lapse,omega,max(abs(x) for row in ric_z for x in row)

def boost(z,v):
    v=[D(str(x)) for x in v]
    v2=sum(x*x for x in v); gam=1/math.sqrt(1-v2); fac=gam*gam/(gam+1)
    b=[[gam]+[gam*x for x in v]]
    for i in range(3): b.append([gam*v[i]]+[(O if i==j else Z)+fac*v[i]*v[j] for j in range(3)])
    return [[sum(b[i][j]*z[j][k] for j in range(4)) for k in range(4)] for i in range(4)]

def eigen3(e):
    # Equatorial single boosts in (r,phi) leave the theta direction an eigenvector.
    assert abs(e[0][1])+abs(e[1][0])+abs(e[1][2])+abs(e[2][1])<D('1e-48')
    a,b,d=e[0][0],e[0][2],e[2][2]; dis=math.sqrt((a-d)**2+4*b*b)
    return sorted([(a+d-dis)/2,e[1][1],(a+d+dis)/2])

def tides(u,a,mode,theta=0):
    u,a,theta=D(str(u)),D(str(a)),D(theta)
    if not (u.is_finite() and a.is_finite() and 0 <= a < 1 and u > 1+(1-a*a).sqrt()):
        raise ValueError('finite exterior radius and 0 <= spin < 1 required')
    if mode not in ('zamo','hover','radial','pro','retro'): raise ValueError('unknown frame')
    g,r,z,n,w,ric=geometry(u,theta,a); h=math.sqrt(g[3][3]); vs=-w*h/n
    if mode in ['hover','radial'] and abs(vs)>=1: return None
    if mode=='zamo': v=[Z,Z,Z]
    elif mode=='hover': v=[Z,Z,vs]
    elif mode=='radial': v=[-O/2*math.sqrt(1-vs*vs),Z,vs]
    else:
        k=1 if mode=='pro' else -1; om=k/(u*math.sqrt(u)+k*a)
        v=[Z,Z,(om-w)*h/n]
        if sum(x*x for x in v)>=1: return None
    if sum(x*x for x in v)>=1: return None
    ship=boost(z,v)
    e=[[sum(r[p,q,k,l]*ship[i+1][p]*ship[0][q]*ship[j+1][k]*ship[0][l] for p in range(4) for q in range(4) for k in range(4) for l in range(4)) for j in range(3)] for i in range(3)]
    orth=max(abs(sum(g[p][q]*ship[i][p]*ship[j][q] for p in range(4) for q in range(4))-(Z if i!=j else (-O if i==0 else O))) for i in range(4) for j in range(4))
    ev=eigen3(e)
    return dict(s=a,u=u,mode=mode,v=v,E=e,eigen=ev,stretch=-min(ev),squeeze=max(ev),trace=sum(e[i][i] for i in range(3)),ricci=ric,orth=orth)

if __name__=='__main__':
    out=[]
    for a in map(D,['0','.5','.9','.998']):
      for u in map(D,['4','6','20','2000000']):
       for mode in ['zamo','hover','pro','retro','radial']:
        row=tides(u,a,mode)
        if row is not None:
            assert abs(row['trace'])<D('1e-48') and row['ricci']<D('1e-48') and row['orth']<D('1e-48'),row
            out.append(row)
    print("[\n"+",\n".join(json.dumps(row,default=str) for row in out)+"\n]")
