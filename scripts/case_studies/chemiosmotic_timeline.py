"""Replay the chemiosmotic controversy through BioLean's fuse algebra, cutting evidence off by year.
Mirrors Opinion.fuse / ofReliability in BioLean/Belief.lean; evidence items are illustrative."""
from fractions import Fraction as F
R = dict(mechanistic=F(7,10), review=F(3,5), observational=F(1,2), inVitro=F(1,2), rct=F(17,20))
def op(kind, pol):
    r = R[kind]; return (r,0,1-r) if pol=='+' else (0,r,1-r)
def fuse(x,y):
    bx,dx,ux=x; by,dy,uy=y; k=ux+uy-ux*uy
    return ((bx*uy+by*ux)/k,(dx*uy+dy*ux)/k,ux*uy/k)
def verdict(o,th=F(4,5),tau=F(1,4)):
    b,d,u=o
    if b>=th: return 'established'
    if d>=th: return 'refuted'
    if b>=tau and d>=tau: return 'contested'
    return 'unsupported'
# Claim: "proton gradient across the inner membrane drives ATP synthesis"
ev = [ # year, kind, polarity, note
 (1961,'mechanistic','+','Mitchell, Nature: chemiosmotic hypothesis (theory, no data)'),
 (1963,'review','-','Slater/Lehninger reviews: chemical-intermediate coupling assumed'),
 (1965,'inVitro','-','Reports of high-energy intermediate X~I (later artefacts)'),
 (1966,'inVitro','+','Jagendorf & Uribe: acid-bath drives ATP synthesis in chloroplasts'),
 (1967,'inVitro','-','Chance: failure to measure predicted pH change'),
 (1969,'inVitro','+','Mitchell & Moyle: proton translocation stoichiometry'),
 (1971,'inVitro','+','Hinkle: ATP synthesis from artificial pH gradient in mitochondria'),
 (1974,'inVitro','+','Racker & Stoeckenius: bacteriorhodopsin + F1Fo liposomes make ATP'),
 (1977,'review','+','Boyer, Chance, Ernster, Mitchell, Racker, Slater joint review (Annu Rev Biochem)'),
 (1978,'review','+','Nobel citation'),
 (1994,'inVitro','+','Abrahams/Walker: F1 structure; Boyer rotary mechanism'),
]
def at(year):
    o=None
    for y,k,p,_ in ev:
        if y<=year:
            e=op(k,p); o=e if o is None else fuse(o,e)
    return o
print(f"{'year':>4} {'b':>6} {'d':>6} {'u':>6}  verdict")
for y in [1961,1963,1965,1966,1967,1971,1974,1977,1994]:
    b,d,u=at(y); print(f"{y:>4} {float(b):6.3f} {float(d):6.3f} {float(u):6.3f}  {verdict((b,d,u))}")

print("\n-- with supersession: the 1963/1965/1967 items are retracted by the 1974 result --")
def at2(year):
    o=None
    for y,k,p,_ in ev:
        if y<=year and not (p=='-' and year>=1974):
            e=op(k,p); o=e if o is None else fuse(o,e)
    return o
for y in [1971,1974,1977,1994]:
    b,d,u=at2(y); print(f"{y:>4} {float(b):6.3f} {float(d):6.3f} {float(u):6.3f}  {verdict((b,d,u))}")
