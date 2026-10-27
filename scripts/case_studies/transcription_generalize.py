"""Sketch of the proposed `generalize` rule: instances of 'DNA is transcribed to RNA' in a few taxa,
fused, then discounted by taxonomic coverage of the target context (cellular organisms).
Mirrors Opinion.fuse in BioLean/Belief.lean; the coverage discount is Josang's trust discount."""
from fractions import Fraction as F
R = dict(mechanistic=F(7,10), curatedDb=F(4,5), inVitro=F(1,2))
def op(kind, pol='+'):
    r = R[kind]; return (r,0,1-r) if pol=='+' else (0,r,1-r)
def fuse(x,y):
    bx,dx,ux=x; by,dy,uy=y; k=ux+uy-ux*uy
    return ((bx*uy+by*ux)/k,(dx*uy+dy*ux)/k,ux*uy/k)
def discount(trust_b, x):           # trust discount with a dogmatic trust opinion (trust_b, 0, 1-trust_b)
    b,d,u=x; return (trust_b*b, trust_b*d, 1-trust_b*b-trust_b*d)
def verdict(o,th=F(4,5),tau=F(1,4)):
    b,d,u=o
    return 'established' if b>=th else 'refuted' if d>=th else 'contested' if b>=tau and d>=tau else 'unsupported'

# instances: (taxon, major clade, evidence kinds). Clades are the coarse split of NCBITaxon:131567.
CLADES = ['Bacteria','Archaea','Fungi','Metazoa','Viridiplantae','other eukaryotes']
instances = [
 ('Escherichia coli',      'Bacteria',      ['mechanistic','mechanistic','curatedDb']),
 ('Saccharomyces cerevisiae','Fungi',       ['mechanistic','curatedDb']),
 ('Mus musculus',          'Metazoa',       ['mechanistic','curatedDb']),
 ('Homo sapiens',          'Metazoa',       ['mechanistic','mechanistic','curatedDb']),
 ('Arabidopsis thaliana',  'Viridiplantae', ['curatedDb']),
]
def run(insts):
    fused=None
    for _,_,kinds in insts:
        for k in kinds:
            fused = op(k) if fused is None else fuse(fused, op(k))
    covered = {c for _,c,_ in insts}
    coverage = F(len(covered), len(CLADES))
    gen = discount(coverage, fused)
    return fused, coverage, gen

for label, insts in [("E. coli only", instances[:1]), ("E. coli + yeast + mouse + human", instances[:4]), ("all five", instances)]:
    fused, cov, gen = run(insts)
    print(f"{label:34s} fused b={float(fused[0]):.3f}  coverage={cov} -> universal b={float(gen[0]):.3f} u={float(gen[2]):.3f}  {verdict(gen)}")

print("\nSame instances, target = Metazoa (clades: 2 of 2 phyla sampled would be the measure; here mouse+human only):")
fused,_,_ = run([i for i in instances if i[1]=='Metazoa'])
print(f"  Metazoa universal b={float(fused[0]):.3f} (coverage 1 at this grain)  {verdict(fused)}")

print("\nException outside the context: retroviral reverse transcription refutes 'info flows only DNA->RNA', not this claim.")
