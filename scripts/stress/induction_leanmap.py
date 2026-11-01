"""Program 10c: map textbook statement ids to their Lean names (R3 wins over R2, as in closure.py). Prints
`id <tab> Lean name <tab> claim`. Read-only helper for writing BioLean/Stress/Induction.lean."""
import re, glob, sys, pathlib
REPO = pathlib.Path(__file__).resolve().parents[2]
CH = {'CellStructureAndFunction': 'cell-structure-and-function', 'HowCellsObtainEnergy': 'how-cells-obtain-energy',
      'MolecularBiology': 'molbio', 'Photosynthesis': 'photosynthesis', 'ReproductionAtTheCellularLevel': 'reproduction-at-the-cellular-level',
      'TheBodySSystemsA': 'the-body-s-systems', 'TheBodySSystemsB': 'the-body-s-systems', 'TheCellularBasisOfInheritance': 'the-cellular-basis-of-inheritance'}
out, both = {}, {}
for rnd in ('R2', 'R3'):
    for p in sorted(glob.glob(str(REPO / f'BioLean/Lib/TextbookClaims{rnd}/*.lean'))):
        mod = pathlib.Path(p).stem
        if mod == 'Entities': continue
        for m in re.finditer(r'def (\w+) : Statement where\n  id := "([^"]+)"\n  text := "((?:[^"\\]|\\.)*)"\n  claim := (.*)\n', open(p).read()):
            out[m.group(2)] = (f'{rnd}.{mod}.{m.group(1)}', m.group(4), m.group(3))
            both.setdefault(m.group(2), []).append((f'{rnd}.{mod}.{m.group(1)}', m.group(4)))
for i in sys.argv[1:]:
    for name, claim in both.get(i, [('MISSING', '')]): print(i, name, claim, sep='\t')
