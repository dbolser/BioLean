"""Program 03 stress set (build stage, 2026-10-30). One spec drives three things:
  * BioLean/Stress/Rivals.lean   the current core (`Rivalry`, `Statement`) on every case;
  * BioLean/Proto/Multinomial.lean   the frame prototype (B2 per-cell, B1 hyper-opinion, H withdrawal);
  * data/stress/03/cases.tsv     the case table, via rivals_score.py.

Copied from the research-stage scratch (/tmp/biolean-03/sim/spec.py) and changed in four ways:
  1. R09 uses the compiled round-2 textbook statement cell-structure-and-function-m45428-82
     (BioLean.Lib.TextbookClaimsR2) as the biogenesis rival, instead of a hand copy of m45428-80.
  2. R03b gets frames (plain and best), so the prototype runs on it too.
  3. Every case lists its expected verdicts for every dated year (EXPY), not only the key year.
  4. The best-curation frames (FB, SB) moved here from the scorer, so the generator can emit them.

A case has one or more encodings ("variants") under the current system:
  rivalry  : a Rivalry over statements, as Chemiosmosis.lean does it
  stmt     : one Statement (a claim with +/- evidence), for P-versus-not-P pairs
and one frame encoding for the prototype (items entered once on the subset of cells they favour).
Evidence kinds are EvidenceKind names; weights are EvidenceModel.standard.
"""

# ---------- entities: name -> (kind, curie, label) ----------
ENT = {
  "dnaRep": ("process", "GO:0006261", "DNA-templated DNA replication"),
  "semiMode": ("process", "BLN:semiconservative", "semi-conservative replication (no GO term)"),
  "consMode": ("process", "BLN:conservative", "conservative replication (no GO term)"),
  "dispMode": ("process", "BLN:dispersive", "dispersive replication (no GO term)"),
  "dna": ("chemical", "CHEBI:16991", "deoxyribonucleic acid"),
  "rna": ("chemical", "CHEBI:33697", "ribonucleic acid"),
  "protein": ("chemical", "CHEBI:36080", "protein"),
  "nucleicAcid": ("chemical", "CHEBI:33696", "nucleic acid"),
  "geneticMaterial": ("chemical", "GENO:0000482", "genetic material (GENO; kind tag only)"),
  "cellular": ("taxon", "NCBITaxon:131567", "cellular organisms"),
  "tmv": ("taxon", "NCBITaxon:12242", "Tobacco mosaic virus"),
  "neuron": ("cellType", "CL:0000540", "neuron"),
  "vertebrata": ("taxon", "NCBITaxon:7742", "Vertebrata"),
  "mnemiopsis": ("taxon", "NCBITaxon:27923", "Mnemiopsis leidyi"),
  "synSig": ("process", "GO:0099536", "synaptic signaling"),
  "chemSyn": ("process", "GO:0007268", "chemical synaptic transmission"),
  "elecCoupling": ("process", "GO:0010644", "cell communication by electrical coupling"),
  "astacoidea": ("taxon", "NCBITaxon:6724", "Astacoidea (crayfish; species not checked)"),
  "hpylori": ("taxon", "NCBITaxon:210", "Helicobacter pylori"),
  "pepticUlcer": ("phenotype", "HP:0004398", "Peptic ulcer"),
  # Review 2: the R05 loser was GO:0001696 "gastric acid secretion", but acid is a co-factor of peptic
  # ulcer, not refuted (anti-secretory drugs cut ulcer prevalence; Lanas & Chan 2017, PMID 28242110).
  # What H. pylori displaced is stress-driven acid hypersecretion as the primary cause: no ontology term.
  "stressAcid": ("process", "BLN:stress-acid-hypersecretion", "stress-driven acid hypersecretion as the primary cause (no term; acid secretion itself, GO:0001696, is a co-factor)"),
  "nsaid": ("chemical", "CHEBI:35475", "non-steroidal anti-inflammatory drug"),
  "hexokinase": ("function", "GO:0004396", "hexokinase activity"),
  "lockKey": ("function", "BLN:lock-and-key", "rigid lock-and-key binding (no GO term)"),
  "inducedFit": ("function", "BLN:induced-fit", "induced-fit binding (no GO term)"),
  "confSel": ("function", "BLN:conformational-selection", "conformational-selection binding (no GO term)"),
  "antigen": ("chemical", "CHEBI:59132", "antigen"),
  "igProd": ("process", "GO:0002377", "immunoglobulin production"),
  "bcellProlif": ("process", "GO:0042100", "B cell proliferation"),
  "proteinFolding": ("process", "GO:0006457", "protein folding"),
  "igComplex": ("component", "GO:0019814", "immunoglobulin complex"),
  "confCoupling": ("process", "BLN:conformational-coupling", "conformational coupling (Boyer; no GO term)"),
  "cell": ("cellType", "CL:0000000", "cell"),
  "nonLiving": ("chemical", "BLN:non-living-organic-matter", "non-living organic matter"),
  "substitution": ("process", "BLN:molecular-substitution", "fixation of a molecular substitution"),
  "neutralFix": ("process", "BLN:neutral-fixation", "fixation by drift of a neutral variant"),
  "adaptiveFix": ("process", "BLN:adaptive-fixation", "fixation by positive selection"),
  "abeta": ("chemical", "CHEBI:64645", "amyloid-beta"),
  "alzheimer": ("phenotype", "HP:0002511", "Alzheimer disease"),
  "heredity": ("process", "BLN:heredity", "transmission of traits to offspring"),
  "particulate": ("process", "BLN:particulate-inheritance", "particulate (Mendelian) inheritance"),
  "blending": ("process", "BLN:blending-inheritance", "blending inheritance"),
  "giardiaLine": ("taxon", "NCBITaxon:2611341", "Metamonada"),
  "preMito": ("taxon", "BLN:pre-mitochondrial-eukaryote", "a eukaryote lineage that never had mitochondria"),
  "mitochondrion": ("component", "GO:0005739", "mitochondrion"),
  "mitosome": ("component", "GO:0032047", "mitosome"),
  "alphaproteo": ("taxon", "NCBITaxon:28211", "Alphaproteobacteria"),
  "endomembrane": ("component", "GO:0012505", "endomembrane system"),
  "plasmaMembrane": ("component", "GO:0005886", "plasma membrane"),
  "fluidMosaic": ("component", "BLN:fluid-mosaic", "a fluid bilayer with embedded mobile proteins"),
  "ddSandwich": ("component", "BLN:protein-lipid-protein-sandwich", "a bilayer coated by protein layers (Davson-Danielli)"),
  "neurogenesis": ("process", "GO:0022008", "neurogenesis"),
  "dentateGyrus": ("anatomy", "UBERON:0001885", "dentate gyrus of hippocampal formation"),
  "human": ("taxon", "NCBITaxon:9606", "Homo sapiens"),
  "translation": ("process", "GO:0006412", "translation"),
  "overlapCode": ("process", "BLN:overlapping-code", "reading of overlapping triplets"),
  "commaFree": ("process", "BLN:comma-free-code", "reading of a comma-free code"),
  "fixedStart": ("process", "BLN:non-overlapping-fixed-start", "reading of non-overlapping triplets from a fixed start"),
  "doubleHelix": ("chemical", "BLN:double-helix", "two antiparallel strands in a helix"),
  "tripleHelix": ("chemical", "BLN:triple-helix", "three strands, phosphates inside (Pauling-Corey)"),
  "sideBySide": ("chemical", "BLN:side-by-side", "two strands side by side, not intertwined"),
  "eukaryota": ("taxon", "NCBITaxon:2759", "Eukaryota"),
  "archaea": ("taxon", "NCBITaxon:2157", "Archaea"),
  "rsv": ("taxon", "NCBITaxon:11886", "Rous sarcoma virus"),
  "viralRep": ("process", "GO:0019079", "viral genome replication"),
  "rtActivity": ("function", "GO:0003964", "RNA-directed DNA polymerase activity"),
  "rdrpActivity": ("function", "GO:0003968", "RNA-directed RNA polymerase activity"),
  "scrapieAgent": ("chemical", "BLN:scrapie-agent", "the transmissible agent of scrapie"),
  "prp": ("protein", "PR:000001886", "major prion protein"),
  "smallNA": ("chemical", "BLN:small-nucleic-acid", "a small agent-specific nucleic acid (virino)"),
  "sexRepro": ("process", "GO:0019953", "sexual reproduction"),
  "redQueen": ("process", "BLN:parasite-coevolution", "selection by coevolving parasites (Red Queen)"),
  "mutDet": ("process", "BLN:mutation-purging", "purging of deleterious mutations (Kondrashov)"),
  "dvPattern": ("process", "GO:0009953", "dorsal/ventral pattern formation"),
  "chordata": ("taxon", "NCBITaxon:7711", "Chordata"),
  "arthropoda": ("taxon", "NCBITaxon:6656", "Arthropoda"),
  "invertedHomolog": ("process", "BLN:inverted-homologous-axis", "the arthropod D-V axis, inverted"),
  "independentAxis": ("process", "BLN:independent-axis", "a D-V axis of independent origin"),
  "sA": ("process", "BLN:A", "synthetic rival A"), "sB": ("process", "BLN:B", "synthetic rival B"),
  "sC": ("process", "BLN:C", "synthetic rival C"), "sX": ("process", "BLN:X", "synthetic subject"),
}

def E(pmid, year, kind, pol="+", note="", key=None, until=None, taxon=None):
    """One evidence item under the current system. key names pmid-0 items; until = year withdrawn
    (retraction or supersession; the current system cannot use it); taxon = the ENT name of the
    organism studied (Evidence.taxon; checked by the core lint Statement.taxonConsistent)."""
    return dict(pmid=pmid, year=year, kind=kind, pol=pol, note=note, key=key or (str(pmid) if pmid else note[:12]), until=until, taxon=taxon)

def I(pmid, year, kind, fav, note="", key=None, until=None, finding=0):
    """One evidence item for the frame prototype: entered once, on the cells it favours. `finding`
    numbers the findings of one paper (R01c): items are keyed by (pmid, finding), not by pmid."""
    k = key or ((f"{pmid}#{finding}" if finding else str(pmid)) if pmid else note[:12])
    return dict(pmid=pmid, year=year, kind=kind, fav=fav, note=note, key=k, until=until, finding=finding)

def R(rid, text, claim, ev, base=None):
    """A rival. `base` names a compiled round-2 textbook statement whose claim and evidence are reused
    (the generator emits `{ base with id, evidence := ev ++ base.evidence }`); items flagged r2=True in
    `ev` stand for that statement's own evidence in Python and are not emitted twice."""
    return dict(rid=rid, text=text, claim=claim, ev=ev, base=base)

CASES = []
def case(**kw):
    CASES.append(kw)

# ===================================================================== REAL
# R01 Meselson-Stahl: three rivals
semi_ev = [E(13063483,1953,"hypothesis",note="Watson & Crick, Nature: genetical implications; proposes template copying"),
           E(16589984,1957,"mechanistic",note="Taylor, Woods & Hughes, PNAS: label segregates semi-conservatively at chromosome level (Vicia faba)"),
           E(16590258,1958,"mechanistic",note="Meselson & Stahl, PNAS: 15N/14N density bands, generation 1 hybrid, generation 2 half hybrid half light"),
           E(14017761,1963,"mechanistic",note="Cairns, J Mol Biol: autoradiography of replicating E. coli chromosome"),
           E(0,2013,"textbook",note="molbio-m45475-121: DNA replicates by a semi-conservative method",key="m45475-121")]
case(id="R01a", kind="real", title="Meselson-Stahl: semi-conservative, conservative, dispersive",
  probe="three rivals; one experiment refutes two; double count on both losers",
  years=[1954,1957,1958,1963], key=1958,
  expect={1958: {"semi": "established", "conservative": "refuted", "dispersive": "refuted"}},
  source="Meselson & Stahl 1958 (PMID 16590258); textbook molbio-m45475-121",
  variants={
   "both": ("rivalry", [R("semi","DNA replication is semi-conservative",("isA","dnaRep","semiMode"), semi_ev[:4]),
                        R("conservative","DNA replication is conservative",("isA","dnaRep","consMode"),
                          [E(16589984,1957,"mechanistic","-"),E(16590258,1958,"mechanistic","-")]),
                        R("dispersive","DNA replication is dispersive",("isA","dnaRep","dispMode"),
                          [E(16589559,1954,"hypothesis",note="Delbruck, PNAS: proposes dispersive replication"),
                           E(16589984,1957,"mechanistic","-"),E(16590258,1958,"mechanistic","-")])]),
   "once": ("rivalry", [R("semi","DNA replication is semi-conservative",("isA","dnaRep","semiMode"), semi_ev[:4]),
                        R("conservative","DNA replication is conservative",("isA","dnaRep","consMode"), []),
                        R("dispersive","DNA replication is dispersive",("isA","dnaRep","dispMode"),
                          [E(16589559,1954,"hypothesis")])])},
  frame=dict(cells=["semi","conservative","dispersive"], open=True,
    items=[I(13063483,1953,"hypothesis",["semi"]), I(16589559,1954,"hypothesis",["dispersive"]),
           I(16589984,1957,"mechanistic",["semi"]), I(16590258,1958,"mechanistic",["semi"]),
           I(14017761,1963,"mechanistic",["semi"])]))

# R01b first-generation hybrid band alone: excludes conservative, silent between semi and dispersive
case(id="R01b", kind="real", title="Meselson-Stahl generation 1 only: hybrid band",
  probe="evidence compatible with two of three rivals (a subset vote)",
  years=[1958], key=1958,
  expect={1958: {"semi": "unsupported", "conservative": "refuted|unsupported", "dispersive": "unsupported"}},
  source="Meselson & Stahl 1958 (PMID 16590258): the generation-1 hybrid band rules out conservative only; generation 2 is needed to rule out dispersive",
  variants={
   "support-both": ("rivalry", [R("semi","",("isA","dnaRep","semiMode"),[E(16590258,1958,"mechanistic")]),
                                R("conservative","",("isA","dnaRep","consMode"),[E(16590258,1958,"mechanistic","-")]),
                                R("dispersive","",("isA","dnaRep","dispMode"),[E(16590258,1958,"mechanistic")])]),
   "refute-only": ("rivalry", [R("semi","",("isA","dnaRep","semiMode"),[]),
                               R("conservative","",("isA","dnaRep","consMode"),[E(16590258,1958,"mechanistic","-")]),
                               R("dispersive","",("isA","dnaRep","dispMode"),[])])},
  frame=dict(cells=["semi","conservative","dispersive"], open=True,
    items=[I(16590258,1958,"mechanistic",["semi","dispersive","other"])]))

# R01c (added in the research rerun): one paper, two findings with opposite bearing on 'dispersive'.
# Generation 1 (one hybrid band) excludes conservative only. Generation 2 (hybrid plus light, no heavy)
# excludes conservative and dispersive. The research scratch gave conservative generation 2 as support;
# that is wrong (conservative predicts heavy plus light), so here it is a refutation. It does not move a
# number: the PMID rule drops the second item anyway.
gen1 = lambda p: E(16590258,1958,"mechanistic",p,note="Meselson & Stahl 1958, generation 1: one hybrid band",key="16590258#1")
gen2 = lambda p: E(16590258,1958,"mechanistic",p,note="Meselson & Stahl 1958, generation 2: hybrid plus light, no heavy",key="16590258#2")
case(id="R01c", kind="real", title="Meselson and Stahl 1958 as two findings: one PMID with opposite bearing on 'dispersive'",
  probe="evidence identity: the PMID rule keeps the first item of a paper, whatever its polarity",
  years=[1958], key=1958,
  expect={1958: {"dispersive": "belief 0, disbelief above 0, in either order of entry", "conservative": "excluded"}},
  source="Meselson & Stahl 1958 (PMID 16590258): generation 1 rules out conservative; generation 2 rules out dispersive",
  variants={
   "gen1-first": ("stmt", [R("dispersive","DNA replication is dispersive",("isA","dnaRep","dispMode"),[gen1("+"),gen2("-")])]),
   "gen2-first": ("stmt", [R("dispersive","DNA replication is dispersive",("isA","dnaRep","dispMode"),[gen2("-"),gen1("+")])]),
   "both-findings": ("rivalry", [R("semi","",("isA","dnaRep","semiMode"),[gen1("+"),gen2("+")]),
                                 R("conservative","",("isA","dnaRep","consMode"),[gen1("-"),gen2("-")]),
                                 R("dispersive","",("isA","dnaRep","dispMode"),[gen1("+"),gen2("-")])])},
  frame=dict(cells=["semi","conservative","dispersive"], open=True,
    items=[I(16590258,1958,"mechanistic",["semi","dispersive","other"],finding=1,note="generation 1: one hybrid band"),
           I(16590258,1958,"mechanistic",["semi"],finding=2,note="generation 2: hybrid plus light")]),
  # the same two findings keyed by PMID only, in both orders (the prototype's own PMID rule)
  frames_extra=[("pmid-gen1-first", dict(cells=["semi","conservative","dispersive"], open=True,
                    items=[I(16590258,1958,"mechanistic",["semi","dispersive","other"],note="generation 1"),
                           I(16590258,1958,"mechanistic",["semi"],note="generation 2")])),
                ("pmid-gen2-first", dict(cells=["semi","conservative","dispersive"], open=True,
                    items=[I(16590258,1958,"mechanistic",["semi"],note="generation 2"),
                           I(16590258,1958,"mechanistic",["semi","dispersive","other"],note="generation 1")]))])

# R02a DNA vs protein as the genetic material, cellular organisms
case(id="R02a", kind="real", title="DNA against protein as the genetic material (Avery 1944, Hershey-Chase 1952)",
  probe="two rivals, dated evidence; consensus lagged Avery",
  years=[1943,1944,1952], key=1952,
  expect={1944: {"DNA": "unsupported", "protein": "unsupported"}, 1952: {"DNA": "established", "protein": "refuted"}},
  source="Cobb 2014 Curr Biol (PMID 24456972): Avery 1944 did not convince everyone; Hershey & Chase 1952 is the usual settling point",
  variants={
   "both": ("rivalry", [R("DNA","DNA is the genetic material",("isA","dna","geneticMaterial"),
                          [E(19871359,1944,"inVitro",note="Avery, MacLeod & McCarty, J Exp Med: transforming principle is DNA"),
                           E(15421335,1950,"observational",note="Chargaff, Experientia: base ratios vary between species"),
                           E(12981234,1952,"mechanistic",note="Hershey & Chase, J Gen Physiol: phage DNA, not protein, enters the cell")]),
                        R("protein","protein is the genetic material",("isA","protein","geneticMaterial"),
                          [E(19871359,1944,"inVitro","-"),E(12981234,1952,"mechanistic","-")])])},
  frame=dict(cells=["DNA","protein"], open=True,
    items=[I(20474956,1928,"mechanistic",["DNA","protein","other"],note="Griffith 1928, J Hyg (PMID 20474956; 20475871 is the 1966 reprint): a transforming principle exists"),
           I(19871359,1944,"inVitro",["DNA"]), I(15421335,1950,"observational",["DNA"]), I(12981234,1952,"mechanistic",["DNA"])]))

# R02b add RNA (TMV): rivals exclusive only within a context
case(id="R02b", kind="real", title="DNA, protein, RNA as genetic material: TMV RNA (1956-57) in a context-free frame",
  probe="rivals exclusive only within a context (cellular organisms against RNA viruses)",
  years=[1952,1957], key=1957,
  expect={1957: {"DNA": "established", "protein": "refuted", "RNA": "established"}},
  source="Gierer & Schramm 1956 (PMID 13321939); Fraenkel-Conrat & Singer 1957 (PMID 13436476): RNA is the genetic material of TMV; DNA of cellular organisms",
  variants={
   "naive": ("rivalry", [R("DNA","",("isA","dna","geneticMaterial"),
                           [E(19871359,1944,"inVitro"),E(15421335,1950,"observational"),E(12981234,1952,"mechanistic"),
                            E(13321939,1956,"inVitro","-",note="Gierer & Schramm, Nature: TMV RNA alone is infectious"),
                            E(13436476,1957,"inVitro","-",note="Fraenkel-Conrat & Singer: progeny follow the RNA of the reconstituted virus")]),
                         R("protein","",("isA","protein","geneticMaterial"),[E(19871359,1944,"inVitro","-"),E(12981234,1952,"mechanistic","-")]),
                         R("RNA","",("isA","rna","geneticMaterial"),[E(13321939,1956,"inVitro"),E(13436476,1957,"inVitro")])]),
   "ctx-cellular": ("rivalry", [R("DNA","",("isA@cellular","dna","geneticMaterial"),
                           [E(19871359,1944,"inVitro"),E(15421335,1950,"observational"),E(12981234,1952,"mechanistic")]),
                         R("protein","",("isA@cellular","protein","geneticMaterial"),[E(19871359,1944,"inVitro","-"),E(12981234,1952,"mechanistic","-")])]),
   "ctx-tmv": ("rivalry", [R("RNA","",("isA@tmv","rna","geneticMaterial"),[E(13321939,1956,"inVitro"),E(13436476,1957,"inVitro")]),
                         R("protein","",("isA@tmv","protein","geneticMaterial"),[E(13436476,1957,"inVitro","-")])])},
  frame=dict(cells=["DNA","protein","RNA"], open=True,
    items=[I(19871359,1944,"inVitro",["DNA"]), I(15421335,1950,"observational",["DNA"]), I(12981234,1952,"mechanistic",["DNA"]),
           I(13321939,1956,"inVitro",["RNA"]), I(13436476,1957,"inVitro",["RNA"])]))

# R03a Golgi reticular theory vs Cajal neuron doctrine, vertebrates
golgi73 = E(0,1873,"observational",note="Golgi 1873, black reaction; reads a continuous network (no DOI; UNVERIFIED)",key="golgi73")
cajal88 = lambda p: E(0,1888,"observational",p,note="Cajal 1888, bird cerebellum: free endings (no DOI; UNVERIFIED)",key="cajal88")
harr10 = lambda p: E(0,1910,"inVitro",p,note="Harrison 1910, J Exp Zool doi:10.1002/jez.1400090405: nerve fibre grows out from one cell",key="harrison10")
palay = lambda p: E(14381429,1955,"observational",p,note="Palay & Palade, J Biophys Biochem Cytol: EM of neurons, synaptic membranes separate")
derob = lambda p: E(14381427,1955,"observational",p,note="De Robertis & Bennett: EM of synapses in frog and earthworm")
case(id="R03a", kind="real", title="Golgi's reticular theory against Cajal's neuron doctrine (vertebrates)",
  probe="two exhaustive rivals; double entry makes the pair asymmetric; winner not raised",
  years=[1906,1910,1955], key=1955,
  expect={1906: {"neuron doctrine": "contested", "reticular": "contested"}, 1955: {"neuron doctrine": "established", "reticular": "refuted"}},
  source="Lopez-Munoz et al. 2006 Brain Res Bull (PMID 17027775): Nobel 1906 shared while the dispute was open; EM in the 1950s settled it",
  variants={
   "both": ("rivalry", [R("neuron doctrine","neurons are not continuous with each other",("notRel2150@vertebrata","neuron","neuron"),
                          [cajal88("+"),harr10("+"),palay("+"),derob("+")]),
                        R("reticular","neurons are continuous with each other",("rel2150@vertebrata","neuron","neuron"),
                          [golgi73,cajal88("-"),harr10("-"),palay("-"),derob("-")])]),
   "one-claim": ("stmt", [R("reticular","neurons are continuous with each other",("rel2150@vertebrata","neuron","neuron"),
                          [golgi73,cajal88("-"),harr10("-"),palay("-"),derob("-")])])},
  frame=dict(cells=["neuron doctrine","reticular"], open=False,
    items=[I(0,1873,"observational",["reticular"],key="golgi73"), I(0,1888,"observational",["neuron doctrine"],key="cajal88"),
           I(0,1910,"inVitro",["neuron doctrine"],key="harrison10"), I(14381429,1955,"observational",["neuron doctrine"]),
           I(14381427,1955,"observational",["neuron doctrine"])]))

# R03b ctenophore syncytial nerve net 2023: reticular true in another context
case(id="R03b", kind="real", title="Ctenophore syncytial nerve net (2023): reticular is right in Mnemiopsis",
  probe="new evidence true in another context must not weaken the vertebrate verdict",
  years=[2022,2023], key=2023,
  expect={2023: {"neuron doctrine": "unchanged from 2022", "reticular": "unchanged from 2022"}},
  source="Burkhardt et al. 2023 Science (PMID 37079688): the subepithelial nerve net of Mnemiopsis leidyi is a syncytium",
  variants={
   "naive": ("rivalry", [R("neuron doctrine","",("notRel2150@vertebrata","neuron","neuron"),
                          [cajal88("+"),harr10("+"),palay("+"),derob("+"),E(37079688,2023,"observational","-",note="Burkhardt et al., Science: syncytial nerve net in a ctenophore",taxon="mnemiopsis")]),
                        R("reticular","",("rel2150@vertebrata","neuron","neuron"),
                          [golgi73,cajal88("-"),harr10("-"),palay("-"),derob("-"),E(37079688,2023,"observational",taxon="mnemiopsis")])]),
   "ctx": ("rivalry", [R("neuron doctrine","",("notRel2150@vertebrata","neuron","neuron"),[cajal88("+"),harr10("+"),palay("+"),derob("+")]),
                        R("reticular","",("rel2150@vertebrata","neuron","neuron"),[golgi73,cajal88("-"),harr10("-"),palay("-"),derob("-")])])},
  frame=dict(cells=["neuron doctrine","reticular"], open=False,
    items=CASES[-1]["frame"]["items"] + [I(37079688,2023,"observational",["reticular"])]))

# R04 soup vs sparks; electrical synapses exist (crayfish 1959)
loewi = E(0,1921,"inVitro",note="Loewi 1921, Pfluegers Arch doi:10.1007/BF01738910: vagusstoff from frog heart",key="loewi21")
dale = E(16994763,1936,"mechanistic",note="Dale, Feldberg & Vogt, J Physiol: ACh released at motor nerve endings")
fatt = lambda p: E(14898516,1951,"mechanistic",p,note="Fatt & Katz, J Physiol: end-plate potential, intracellular")
brock = lambda p: E(12991232,1952,"mechanistic",p,note="Brock, Coombs & Eccles, J Physiol: IPSP in motoneurones, against electrical theory")
fursh = lambda p: E(13642302,1959,"mechanistic",p,note="Furshpan & Potter, J Physiol: electrical transmission at crayfish giant motor synapse")
case(id="R04", kind="real", title="Soup against sparks: chemical against electrical synaptic transmission",
  probe="rivals exclusive only within a context (vertebrate NMJ against crayfish giant synapse)",
  years=[1936,1952,1959], key=1959,
  expect={1952: {"chemical": "established", "electrical": "refuted"}, 1959: {"chemical": "established", "electrical": "established in crayfish"}},
  source="Pereda 2014 Nat Rev Neurosci (PMID 24619342): electrical and chemical synapses coexist; Furshpan & Potter 1959 (PMID 13642302)",
  variants={
   "naive": ("rivalry", [R("chemical","synaptic signalling is chemical",("isA","synSig","chemSyn"),[loewi,dale,fatt("+"),brock("+"),fursh("-")]),
                         R("electrical","synaptic signalling is electrical",("isA","synSig","elecCoupling"),[fatt("-"),brock("-"),fursh("+")])]),
   "ctx-vertebrate": ("rivalry", [R("chemical","",("isA@vertebrata","synSig","chemSyn"),[loewi,dale,fatt("+"),brock("+")]),
                         R("electrical","",("isA@vertebrata","synSig","elecCoupling"),[fatt("-"),brock("-")])]),
   "ctx-crayfish": ("stmt", [R("electrical","",("isA@astacoidea","synSig","elecCoupling"),[fursh("+")])])},
  frame=dict(cells=["chemical","electrical"], open=True,
    items=[I(0,1921,"inVitro",["chemical"],key="loewi21"), I(16994763,1936,"mechanistic",["chemical"]), I(14898516,1951,"mechanistic",["chemical"]),
           I(12991232,1952,"mechanistic",["chemical"]), I(13642302,1959,"mechanistic",["electrical"])]))

# R05 peptic ulcer: H. pylori vs stress-driven acid, and NSAIDs (co-cause)
case(id="R05", kind="real", title="Peptic ulcer: Helicobacter against stress-driven acid, with NSAIDs",
  probe="co-causes entered as rivals (not exclusive)",
  years=[1984,1994,2002], key=2002,
  expect={1994: {"H. pylori": "established", "acid/stress": "refuted"}, 2002: {"H. pylori": "established", "acid/stress": "refuted", "NSAID": "established"}},
  source="NIH Consensus 1994 (PMID 8007082); Huang et al. 2002 Lancet (PMID 11809181): H. pylori and NSAIDs are independent, synergistic causes; Lanas & Chan 2017 Lancet (PMID 28242110): anti-secretory drugs cut ulcer prevalence, so acid itself is a co-factor and the refuted rival is stress-driven acid hypersecretion as the primary cause",
  variants={
   "naive": ("rivalry", [R("H. pylori","H. pylori causes peptic ulcer",("effect+","hpylori","pepticUlcer"),
                           [E(6145023,1984,"observational",note="Marshall & Warren, Lancet: curved bacilli in gastritis and ulcer"),
                            E(1558340,1992,"rct",note="Graham et al., Ann Intern Med: eradication prevents recurrence"),
                            E(8007082,1994,"review",note="NIH consensus: treat ulcer patients with H. pylori by eradication"),
                            E(11809181,2002,"metaAnalysis",note="Huang et al., Lancet: H. pylori and NSAIDs independent and synergistic")]),
                         R("acid/stress","stress-driven acid hypersecretion is the primary cause of peptic ulcer",("effect+","stressAcid","pepticUlcer"),[E(1558340,1992,"rct","-")]),
                         R("NSAID","NSAIDs cause peptic ulcer",("effect+","nsaid","pepticUlcer"),[E(11809181,2002,"metaAnalysis")])]),
   "co-causes": ("rivalry", [R("H. pylori","",("effect+","hpylori","pepticUlcer"),
                           [E(6145023,1984,"observational"),E(1558340,1992,"rct"),E(8007082,1994,"review"),E(11809181,2002,"metaAnalysis")]),
                         R("acid/stress","",("effect+","stressAcid","pepticUlcer"),[E(1558340,1992,"rct","-")])])},
  frame=dict(cells=["H. pylori","acid/stress","NSAID"], open=True,
    items=[I(6145023,1984,"observational",["H. pylori"]), I(1558340,1992,"rct",["H. pylori"]), I(8007082,1994,"review",["H. pylori"]),
           I(11809181,2002,"metaAnalysis",["H. pylori","NSAID"])]))

# R06 lock-and-key vs induced fit vs conformational selection (textbook sentences m45437-163/165/166)
case(id="R06", kind="real", title="Lock-and-key against induced fit (and conformational selection)",
  probe="a nested rival (induced fit 'expands on' lock-and-key) and two coexisting mechanisms",
  years=[1958,1978,2009,2013], key=2013,
  expect={1978: {"lock-and-key": "refuted", "induced fit": "unsupported", "conformational selection": "unsupported"},
          2013: {"lock-and-key": "refuted", "induced fit": "established", "conformational selection": "unsupported|established (coexists)"}},
  source="Bennett & Steitz 1978 PNAS (PMID 283394); Boehr, Nussinov & Wright 2009 Nat Chem Biol (PMID 19841628): both mechanisms operate; textbook how-cells-obtain-energy-m45437-165",
  variants={
   "naive": ("rivalry", [R("lock-and-key","",("isA","hexokinase","lockKey"),[E(0,1894,"hypothesis",note="Fischer 1894, Ber Dtsch Chem Ges doi:10.1002/cber.18940270364",key="fischer94"),E(283394,1978,"inVitro","-")]),
                         R("induced fit","",("isA","hexokinase","inducedFit"),[E(16590179,1958,"hypothesis",note="Koshland, PNAS: induced-fit theory"),
                            E(283394,1978,"inVitro",note="Bennett & Steitz, PNAS: glucose closes yeast hexokinase"),
                            E(0,2013,"textbook",note="how-cells-obtain-energy-m45437-165: current research supports induced fit",key="m45437-165")]),
                         R("conformational selection","",("isA","hexokinase","confSel"),[E(19841628,2009,"review",note="Boehr et al.: conformational ensembles; selection and induced fit both")])])},
  frame=dict(cells=["lock-and-key","induced fit","conformational selection"], open=True,
    items=[I(0,1894,"hypothesis",["lock-and-key"],key="fischer94"), I(16590179,1958,"hypothesis",["induced fit"]),
           I(283394,1978,"inVitro",["induced fit"]), I(19841628,2009,"review",["induced fit","conformational selection"]),
           I(0,2013,"textbook",["induced fit"],key="m45437-165")]))

# R07 antibody formation: instructive vs Jerne natural selection vs clonal selection
case(id="R07", kind="real", title="Antibody formation: instructive against selective (Jerne, Burnet) theories",
  probe="three rivals, two of them selective; the winner is not raised",
  years=[1957,1958,1964,1976], key=1976,
  expect={1976: {"instructive": "refuted", "natural selection (Jerne)": "refuted|unsupported", "clonal selection": "established"}},
  source="Silverstein 2002 Nat Immunol (PMID 12205463): clonal selection displaced instructive theories by the mid 1960s",
  variants={
   "both": ("rivalry", [R("instructive","antigen instructs antibody folding",("medBy","antigen","igProd","proteinFolding"),
                          [E(0,1940,"hypothesis",note="Pauling 1940, JACS doi:10.1021/ja01867a018",key="pauling40"),
                           E(13552693,1958,"inVitro","-",note="Nossal & Lederberg, Nature: one cell, one antibody"),
                           E(14224389,1964,"inVitro","-",note="Haber, PNAS: reduced, unfolded Fab refolds with its specificity, no antigen")]),
                        R("natural selection (Jerne)","antigen selects circulating natural antibodies",("medBy","antigen","igProd","igComplex"),
                          [E(16589759,1955,"hypothesis",note="Jerne, PNAS: natural-selection theory")]),
                        R("clonal selection","antigen selects and expands B cell clones",("medBy","antigen","igProd","bcellProlif"),
                          [E(816431,1957,"hypothesis",note="Burnet 1957 Aust J Sci; PMID is the 1976 reprint"),
                           E(13552693,1958,"inVitro"), E(824647,1976,"inVitro",note="Hozumi & Tonegawa, PNAS: somatic rearrangement of Ig genes")])])},
  frame=dict(cells=["instructive","natural selection (Jerne)","clonal selection"], open=True,
    items=[I(0,1940,"hypothesis",["instructive"],key="pauling40"), I(16589759,1955,"hypothesis",["natural selection (Jerne)"]),
           I(816431,1957,"hypothesis",["clonal selection"]), I(13552693,1958,"inVitro",["clonal selection"]),
           I(14224389,1964,"inVitro",["natural selection (Jerne)","clonal selection","other"]), I(824647,1976,"inVitro",["clonal selection"])]))

# R08 chemiosmosis: the worked example, as in BioLean/Examples/Chemiosmosis.lean (variants use its defs)
case(id="R08a", kind="real", title="Chemiosmosis against Slater's intermediate: the repo's worked example",
  probe="the M2 exit test; how much rests on double counting",
  years=[1961,1965,1974], key=1974,
  expect={1965: {"chemiosmotic": "contested", "chemical intermediate": "contested"}, 1974: {"chemiosmotic": "established", "chemical intermediate": "refuted"}},
  source="Repo theorems contested_1965, settled_1974 (BioLean/Examples/Chemiosmosis.lean); Boyer et al. 1977 Annu Rev Biochem (PMID 18361775)",
  variants={"repo": ("repo", "coupling"), "repo-real": ("repo", "realCoupling"), "once": ("repo", "onceCoupling"), "once-real": ("repo", "onceRealCoupling")},
  frame=dict(cells=["chemiosmotic","chemical intermediate"], open=False,
    items=[I(13771349,1961,"hypothesis",["chemiosmotic"]), I(0,1965,"inVitro",["chemiosmotic"],key="protons65"),
           I(13111237,1953,"hypothesis",["chemical intermediate"]), I(0,1963,"hypothesis",["chemical intermediate"],key="reviews63"),
           I(0,1965,"inVitro",["chemical intermediate"],key="intermediate65",until=1967)] +
          [I(p,y,"inVitro",["chemiosmotic"]) for p,y in [(5220864,1966),(16742541,1967),(4330063,1971),(4272126,1974)]]))

chemR = [E(13771349,1961,"hypothesis"), E(4222981,1965,"inVitro",note="Mitchell & Moyle, Nature: stoichiometry of proton translocation"),
         E(5220864,1966,"inVitro"), E(16742541,1967,"inVitro"), E(4330063,1971,"inVitro"), E(4272126,1974,"inVitro")]
ciR = [E(13111237,1953,"hypothesis"), E(14014715,1962,"inVitro",note="Boyer et al., JBC: phosphohistidine from a probable intermediate of oxidative phosphorylation"),
       E(5871845,1964,"inVitro","-",note="Mitchell, Butler & Boyer, BBRC: the bound phosphohistidine is succinate thiokinase"),
       E(5220864,1966,"inVitro","-"), E(16742541,1967,"inVitro","-"), E(4330063,1971,"inVitro","-"), E(4272126,1974,"inVitro","-")]
case(id="R08c", kind="real", title="Chemiosmosis, real papers plus Boyer's phosphohistidine (1962) and its retraction by identification (1964)",
  probe="late evidence that removes a support (undercut), not adds a refutation",
  years=[1962,1964,1965,1974], key=1964,
  expect={1964: {"chemiosmotic": "unsupported", "chemical intermediate": "unsupported (the 1962 support withdrawn)"}, 1974: {"chemiosmotic": "established", "chemical intermediate": "refuted"}},
  source="Boyer et al. 1962 (PMID 14014715); Mitchell, Butler & Boyer 1964 (PMID 5871845); Boyer 1997 Annu Rev Biochem (PMID 9242922)",
  variants={"both": ("rivalry", [R("chemiosmotic","",("chemio","cm"),chemR), R("chemical intermediate","",("chemio","ci"),ciR)])},
  frame=dict(cells=["chemiosmotic","chemical intermediate"], open=False,
    items=[I(13771349,1961,"hypothesis",["chemiosmotic"]), I(4222981,1965,"inVitro",["chemiosmotic"]),
           I(13111237,1953,"hypothesis",["chemical intermediate"]), I(14014715,1962,"inVitro",["chemical intermediate"],until=1964)] +
          [I(p,y,"inVitro",["chemiosmotic"]) for p,y in [(5220864,1966),(16742541,1967),(4330063,1971),(4272126,1974)]]))

case(id="R08d", kind="real", title="Chemiosmosis with Boyer's conformational coupling as a third rival (binding change, rotation)",
  probe="a rival that is a refinement of the winner (nested), not an alternative",
  years=[1974,1977,1997], key=1997,
  expect={1997: {"chemiosmotic": "established", "chemical intermediate": "refuted", "conformational coupling": "established (inside chemiosmosis)"}},
  source="Boyer 1997 Annu Rev Biochem (PMID 9242922): the binding-change mechanism is how ATP synthase uses the proton gradient",
  variants={"naive": ("rivalry", [R("chemiosmotic","",("chemio","cm"),chemR + [E(18361775,1977,"review",note="Boyer, Chance, Ernster, Mitchell, Racker & Slater, Annu Rev Biochem")]),
                                   R("chemical intermediate","",("chemio","ci"),ciR),
                                   R("conformational coupling","",("chemio","cc"),[E(4517936,1973,"inVitro",note="Boyer et al., PNAS: binding-change concept"),
                                      E(8065448,1994,"inVitro",note="Abrahams et al., Nature: F1 structure, three catalytic states"),
                                      E(9069291,1997,"inVitro",note="Noji et al., Nature: F1 rotates")])])},
  frame=dict(cells=["chemiosmotic","chemical intermediate","conformational coupling"], open=True,
    items=[I(13771349,1961,"hypothesis",["chemiosmotic"]), I(4222981,1965,"inVitro",["chemiosmotic"]),
           I(13111237,1953,"hypothesis",["chemical intermediate"]), I(14014715,1962,"inVitro",["chemical intermediate"],until=1964),
           I(18361775,1977,"review",["chemiosmotic"])] +
          [I(p,y,"inVitro",["chemiosmotic"]) for p,y in [(5220864,1966),(16742541,1967),(4330063,1971),(4272126,1974)]] +
          [I(p,y,"inVitro",["chemiosmotic","conformational coupling"]) for p,y in [(4517936,1973),(8065448,1994),(9069291,1997)]]))

# R09 spontaneous generation vs biogenesis
needham = lambda: E(0,1748,"inVitro",note="Needham 1748, Phil Trans doi:10.1098/rstl.1748.0072: boiled broths teem",key="needham48",until=1877)
pasteur = lambda p: E(0,1861,"inVitro",p,note="Pasteur 1861, Ann Sci Nat (no DOI; UNVERIFIED): swan-neck flasks",key="pasteur61")
tyndall = lambda p: E(0,1877,"inVitro",p,note="Tyndall 1877, Proc R Soc doi:10.1098/rspl.1876.0090: intermittent heating kills heat-resistant forms",key="tyndall77")
case(id="R09", kind="real", title="Spontaneous generation against biogenesis",
  probe="superseded evidence keeps voting (Needham's broths)",
  years=[1748,1861,1877,2013], key=1877,
  expect={1877: {"biogenesis": "established", "spontaneous generation": "refuted"}},
  source="Roll-Hansen 2018 Hist Philos Life Sci (PMID 30386943); textbook cell-structure-and-function-m45428-82 (compiled in BioLean/Lib/TextbookClaimsR2)",
  variants={"both": ("rivalry", [R("biogenesis","every cell derives from a cell",("rel1000","cell","cell"),
                        [E(0,1855,"hypothesis",note="Virchow 1855, Arch Pathol Anat doi:10.1007/BF01935312",key="virchow55"),pasteur("+"),tyndall("+"),
                         dict(E(0,2013,"textbook",note="cell-structure-and-function-m45428-82 (R2 Lean): new cells arise from existing cells",key="m45428-82"), r2=True)],
                        base="cell_structure_and_function_m45428_82"),
                       R("spontaneous generation","cells derive from non-living matter",("rel1000","cell","nonLiving"),[needham(),pasteur("-"),tyndall("-")])])},
  frame=dict(cells=["biogenesis","spontaneous generation"], open=False,
    items=[I(0,1748,"inVitro",["spontaneous generation"],key="needham48",until=1877), I(0,1855,"hypothesis",["biogenesis"],key="virchow55"),
           I(0,1861,"inVitro",["biogenesis"],key="pasteur61"), I(0,1877,"inVitro",["biogenesis"],key="tyndall77"),
           dict(I(0,2013,"textbook",["biogenesis"],note="cell-structure-and-function-m45428-82 (R2 Lean)",key="m45428-82"), r2="cell_structure_and_function_m45428_82")]))

# R10 neutral vs selection: still contested
case(id="R10", kind="real", title="Neutral theory against selection (still contested)",
  probe="a live dispute must stay contested",
  years=[1969,1991,2019], key=2019,
  expect={2019: {"neutral": "contested", "selection": "contested"}},
  source="Kern & Hahn 2018 Mol Biol Evol (PMID 29722831) and the reply by Jensen et al. 2019 Evolution (PMID 30460993)",
  variants={"both": ("rivalry", [R("neutral","most substitutions are fixed by drift",("isA","substitution","neutralFix"),
                        [E(5637732,1968,"observational",note="Kimura, Nature: evolutionary rate at the molecular level"),
                         E(5767777,1969,"observational",note="King & Jukes, Science: non-Darwinian evolution"),
                         E(1904993,1991,"observational","-",note="McDonald & Kreitman, Nature: adaptive evolution at Adh"),
                         E(29722831,2018,"review","-",note="Kern & Hahn: neutral theory in light of selection"),
                         E(30460993,2019,"review",note="Jensen et al.: reply")]),
                      R("selection","most substitutions are fixed by positive selection",("isA","substitution","adaptiveFix"),
                        [E(5637732,1968,"observational","-"),E(5767777,1969,"observational","-"),E(1904993,1991,"observational"),
                         E(29722831,2018,"review"),E(30460993,2019,"review","-")])])},
  frame=dict(cells=["neutral","selection"], open=True,
    items=[I(5637732,1968,"observational",["neutral"]), I(5767777,1969,"observational",["neutral"]), I(4585855,1973,"hypothesis",["other"]),
           I(1904993,1991,"observational",["selection"]), I(29722831,2018,"review",["selection"]), I(30460993,2019,"review",["neutral"])]))

# R11 amyloid hypothesis (one claim, contested) and the Lesne retraction
amy = [E(1671712,1991,"observational",note="Goate et al., Nature: APP missense mutation segregates with familial AD"),
       E(1566067,1992,"hypothesis",note="Hardy & Higgins, Science: the amyloid cascade hypothesis"),
       E(16541076,2006,"mechanistic",note="Lesne et al., Nature: Abeta*56 impairs memory. RETRACTED 2024 (doi:10.1038/s41586-024-07691-8)",until=2024),
       E(22801501,2012,"observational",note="Jonsson et al., Nature: protective APP A673T"),
       E(23883379,2013,"rct","-",note="Doody et al., NEJM: semagacestat fails, worsens"),
       E(26007212,2015,"review","-",note="Herrup, Nat Neurosci: the case for rejecting the amyloid cascade"),
       E(36449413,2023,"rct",note="van Dyck et al., NEJM: lecanemab slows decline modestly")]
case(id="R11a", kind="real", title="The amyloid hypothesis of Alzheimer disease (contested)",
  probe="a live dispute must stay contested",
  years=[1992,2006,2013,2023], key=2023,
  expect={2023: {"amyloid causes AD": "contested"}},
  source="Karran & De Strooper 2022 Nat Rev Drug Discov (PMID 35177833); Herrup 2015 (PMID 26007212)",
  variants={"one-claim": ("stmt", [R("amyloid causes AD","amyloid-beta causes Alzheimer disease",("effect+","abeta","alzheimer"), amy)])},
  frame=dict(cells=["amyloid causes AD","not causal"], open=False,
    items=[I(1671712,1991,"observational",["amyloid causes AD"]), I(1566067,1992,"hypothesis",["amyloid causes AD"]),
           I(16541076,2006,"mechanistic",["amyloid causes AD"],until=2024), I(22801501,2012,"observational",["amyloid causes AD"]),
           I(23883379,2013,"rct",["not causal"]), I(26007212,2015,"review",["not causal"]), I(36449413,2023,"rct",["amyloid causes AD"])]))
case(id="R11b", kind="real", title="Lesne et al. 2006 retracted in 2024: does it stop counting?",
  probe="retraction: an item withdrawn at a date",
  years=[2023,2025], key=2025,
  expect={2025: {"amyloid causes AD": "contested, without Lesne 2006"}},
  source="Retraction Note, Nature 2024 (doi:10.1038/s41586-024-07691-8); Europe PMC marks PMID 16541076 as Retracted Publication",
  variants={"one-claim": ("stmt", [R("amyloid causes AD","",("effect+","abeta","alzheimer"), amy)]),
            "removed-by-hand": ("stmt", [R("amyloid causes AD","",("effect+","abeta","alzheimer"), [e for e in amy if e["pmid"] != 16541076])])},
  frame=CASES[-1]["frame"])

# R12 Mendel: data paper ignored until 1900; hypothesis kind versus data kind
def mendel(kind):
    m66 = E(0,1866,kind,note="Mendel 1866, Verh Naturf Ver Bruenn doi:10.5962/bhl.title.61004: pea crosses, 3:1",key="mendel66")
    dv = lambda p: E(0,1900,"mechanistic",p,note="de Vries 1900 doi:10.1111/j.1438-8677.1900.tb04884.x",key="devries00")
    co = lambda p: E(0,1900,"mechanistic",p,note="Correns 1900 doi:10.1111/j.1438-8677.1900.tb04893.x",key="correns00")
    ts = lambda p: E(0,1900,"mechanistic",p,note="Tschermak 1900 doi:10.1111/j.1438-8677.1900.tb04903.x",key="tschermak00")
    return [R("particulate","inheritance is particulate",("isA","heredity","particulate"),[m66,dv("+"),co("+"),ts("+")]),
            R("blending","inheritance is blending",("isA","heredity","blending"),[dv("-"),co("-"),ts("-")])]
case(id="R12", kind="real", title="Mendel 1866, ignored until 1900",
  probe="a proposal that carries data, entered as hypothesis (weight 0) or as data",
  years=[1866,1899,1900], key=1899,
  expect={1899: {"particulate": "unsupported, belief > 0 (one data paper)", "blending": "unsupported"}, 1900: {"particulate": "established", "blending": "refuted"}},
  source="Mendel 1866 (doi:10.5962/bhl.title.61004) reports counts from crosses; Fisher 1936 Ann Sci (doi:10.1080/00033793600200111) re-analysed them",
  variants={"hypothesis": ("rivalry", mendel("hypothesis")), "data": ("rivalry", mendel("mechanistic"))},
  frame=dict(cells=["particulate","blending"], open=True,
    items=[I(0,1866,"mechanistic",["particulate"],key="mendel66"), I(0,1900,"mechanistic",["particulate"],key="devries00"),
           I(0,1900,"mechanistic",["particulate"],key="correns00"), I(0,1900,"mechanistic",["particulate"],key="tschermak00")]))

# R13 Archezoa vs secondary loss (the model example of program 01)
sl = [(7604025,1995,"observational","Clark & Roger, PNAS: Entamoeba has mitochondrial genes"),
      (8962101,1996,"observational","Germot et al., PNAS: Trichomonas mitochondrial-type hsp70"),
      (9419358,1998,"observational","Roger et al., PNAS: Giardia cpn60"),
      (9892676,1999,"observational","Hirt et al., PNAS: microsporidia are fungi"),
      (10361303,1999,"observational","Tovar et al., Mol Microbiol: Entamoeba mitosome"),
      (12192407,2002,"observational","Williams et al., Nature: microsporidian mitochondrial remnant"),
      (14614504,2003,"mechanistic","Tovar et al., Nature: Giardia mitosomes make Fe-S proteins"),
      (16572163,2006,"review","Embley & Martin, Nature: eukaryotic evolution, changes and challenges"),
      (27185558,2016,"observational","Karnkowska et al., Curr Biol: Monocercomonoides lost the organelle entirely")]
case(id="R13", kind="real", title="Archezoa against secondary loss of mitochondria",
  probe="many weak items; double entry makes the verdict arrive earlier",
  years=[1990,1995,1999,2003], key=2003,
  expect={1990: {"Archezoa": "unsupported", "secondary loss": "unsupported"}, 2003: {"Archezoa": "refuted", "secondary loss": "established"}},
  source="Embley & Martin 2006 Nature (PMID 16572163); Tovar et al. 2003 (PMID 14614504)",
  variants={"both": ("rivalry", [R("Archezoa","the metamonad lineage never had mitochondria",("isA","giardiaLine","preMito"),
                        [E(3561476,1987,"hypothesis",note="Cavalier-Smith, Nature: eukaryotes with no mitochondria"),
                         E(2911720,1989,"observational",note="Sogin et al., Science: Giardia rRNA branches early")] + [E(p,y,k,"-") for p,y,k,_ in sl]),
                      R("secondary loss","the mitosome derives from a mitochondrion",("rel1000","mitosome","mitochondrion"),[E(p,y,k,note=n) for p,y,k,n in sl])]),
            "once": ("rivalry", [R("Archezoa","",("isA","giardiaLine","preMito"),[E(3561476,1987,"hypothesis"),E(2911720,1989,"observational")]),
                      R("secondary loss","",("rel1000","mitosome","mitochondrion"),[E(p,y,k) for p,y,k,_ in sl])])},
  frame=dict(cells=["Archezoa","secondary loss"], open=False,
    items=[I(3561476,1987,"hypothesis",["Archezoa"]), I(2911720,1989,"observational",["Archezoa"])] + [I(p,y,k,["secondary loss"]) for p,y,k,_ in sl]))

# R14 endosymbiosis vs autogenous origin of mitochondria
case(id="R14", kind="real", title="Endosymbiotic against autogenous origin of mitochondria",
  probe="winner reaches 'established' only when a textbook item arrives",
  years=[1972,1978,1999,2013], key=1999,
  expect={1999: {"endosymbiotic": "established", "autogenous": "refuted"}},
  source="Gray, Burger & Lang 1999 Science (PMID 10066161); textbook cell-structure-and-function-m45432-247 and -259 (not in Lean)",
  variants={"both": ("rivalry", [R("endosymbiotic","mitochondria derive from alphaproteobacteria",("rel1000","mitochondrion","alphaproteo"),
                        [E(11541392,1967,"hypothesis",note="Sagan, J Theor Biol: on the origin of mitosing cells"),
                         E(202030,1978,"observational",note="Schwartz & Dayhoff, Science: sequence trees"),
                         E(10066161,1999,"review",note="Gray, Burger & Lang, Science: mitochondrial evolution"),
                         E(0,2013,"textbook",note="cell-structure-and-function-m45432-247: strong evidence points to endosymbiosis",key="m45432-247")]),
                      R("autogenous","mitochondria derive from the host's own membranes",("rel1000","mitochondrion","endomembrane"),
                        [E(4340327,1972,"hypothesis",note="Raff & Mahler, Science: non-symbiotic origin"),E(202030,1978,"observational","-"),E(10066161,1999,"review","-")])])},
  frame=dict(cells=["endosymbiotic","autogenous"], open=True,
    items=[I(11541392,1967,"hypothesis",["endosymbiotic"]), I(4340327,1972,"hypothesis",["autogenous"]), I(202030,1978,"observational",["endosymbiotic"]),
           I(10066161,1999,"review",["endosymbiotic"]), I(0,2013,"textbook",["endosymbiotic"],key="m45432-247")]))

# R15 fluid mosaic vs Davson-Danielli
case(id="R15", kind="real", title="Fluid mosaic against Davson-Danielli",
  probe="evidence for the whole frame (a bilayer) cannot be entered; winner not raised",
  years=[1959,1972,2013], key=1972,
  expect={1972: {"fluid mosaic": "established", "Davson-Danielli": "refuted"}},
  source="Singer & Nicolson 1972 Science (PMID 4333397); textbook cell-structure-and-function-m45433-70",
  variants={"both": ("rivalry", [R("fluid mosaic","the plasma membrane is a fluid mosaic",("isA","plasmaMembrane","fluidMosaic"),
                        [E(5334198,1966,"observational",note="Branton, PNAS: freeze-fracture faces"),
                         E(4098863,1970,"inVitro",note="Frye & Edidin, J Cell Sci: surface antigens intermix"),
                         E(4333397,1972,"review",note="Singer & Nicolson, Science"),
                         E(0,2013,"textbook",note="cell-structure-and-function-m45433-70: modern understanding is the fluid mosaic model",key="m45433-70")]),
                      R("Davson-Danielli","the plasma membrane is a protein-lipid-protein sandwich",("isA","plasmaMembrane","ddSandwich"),
                        [E(0,1935,"hypothesis",note="Danielli & Davson 1935, J Cell Comp Physiol doi:10.1002/jcp.1030050409",key="danielli35"),
                         E(13651159,1959,"observational",note="Robertson: unit membrane"),
                         E(5334198,1966,"observational","-"),E(4098863,1970,"inVitro","-")])])},
  frame=dict(cells=["fluid mosaic","Davson-Danielli"], open=True,
    items=[I(19868999,1925,"inVitro",["fluid mosaic","Davson-Danielli","other"],note="Gorter & Grendel: a bilayer"),
           I(0,1935,"hypothesis",["Davson-Danielli"],key="danielli35"), I(13651159,1959,"observational",["Davson-Danielli"]),
           I(5334198,1966,"observational",["fluid mosaic"]), I(4098863,1970,"inVitro",["fluid mosaic"]), I(4333397,1972,"review",["fluid mosaic"]),
           I(0,2013,"textbook",["fluid mosaic"],key="m45433-70")]))

# R16 adult human hippocampal neurogenesis: P vs not-P
pro = [(9809557,1998,"Eriksson et al., Nat Med: BrdU-labelled new neurons in adult DG"),(23746839,2013,"Spalding et al., Cell: 14C dating"),
       (29625071,2018,"Boldrini et al., Cell Stem Cell: persists through ageing"),(30911133,2019,"Moreno-Jimenez et al., Nat Med: abundant, drops in AD"),
       (35794479,2022,"Zhou et al., Nature: immature neurons across lifespan")]
con = [(29513649,2018,"Sorrells et al., Nature: drops to undetectable in adults"),(34798047,2022,"Franjic et al., Neuron: few or no neurogenic cells")]
case(id="R16", kind="real", title="Adult human hippocampal neurogenesis (contested)",
  probe="P against not-P: one claim is the right tool; a Rivalry double counts",
  years=[1998,2013,2018,2022], key=2022,
  expect={2022: {"adult neurogenesis": "contested"}},
  source="Sorrells 2018 (PMID 29513649) against Boldrini 2018 (PMID 29625071) and Moreno-Jimenez 2019 (PMID 30911133); Franjic 2022 (PMID 34798047) against Zhou 2022 (PMID 35794479)",
  variants={"one-claim": ("stmt", [R("adult neurogenesis","neurogenesis occurs in the adult human dentate gyrus",("occursIn@human","neurogenesis","dentateGyrus"),
                          [E(p,y,"observational",note=n) for p,y,n in pro] + [E(p,y,"observational","-",note=n) for p,y,n in con])]),
            "both": ("rivalry", [R("adult neurogenesis","",("occursIn@human","neurogenesis","dentateGyrus"),
                          [E(p,y,"observational") for p,y,n in pro] + [E(p,y,"observational","-") for p,y,n in con]),
                        R("none in adults","",("notOccursIn@human","neurogenesis","dentateGyrus"),
                          [E(p,y,"observational") for p,y,n in con] + [E(p,y,"observational","-") for p,y,n in pro])])},
  frame=dict(cells=["adult neurogenesis","none in adults"], open=False,
    items=[I(p,y,"observational",["adult neurogenesis"]) for p,y,n in pro] + [I(p,y,"observational",["none in adults"]) for p,y,n in con]))

# R16b (added in the research rerun): an OpenStax sentence on the live dispute of R16
ngRows = [E(p,y,"observational",note=n) for p,y,n in pro] + [E(p,y,"observational","-",note=n) for p,y,n in con]
tbNg = lambda k: E(0,2013,k,note="the-body-s-systems-m45539-123: research indicates that neurogenesis continues into adulthood (no taxon)",key="m45539-123")
case(id="R16b", kind="real", title="A textbook sentence on a live dispute: adult neurogenesis",
  probe="a consensus source votes in a live dispute; the 'contested' rule is fragile",
  years=[2013,2022], key=2022,
  expect={2022: {"adult neurogenesis": "contested"}},
  source="as R16; OpenStax Concepts of Biology the-body-s-systems-m45539-123 (no taxon named)",
  variants={"textbook": ("stmt", [R("adult neurogenesis","",("occursIn@human","neurogenesis","dentateGyrus"), ngRows + [tbNg("textbook")])]),
            "transport": ("stmt", [R("adult neurogenesis","",("occursIn@human","neurogenesis","dentateGyrus"), ngRows + [tbNg("crossSpecies")])]),
            "without": ("stmt", [R("adult neurogenesis","",("occursIn@human","neurogenesis","dentateGyrus"), ngRows)])},
  frame=dict(cells=["adult neurogenesis","none in adults"], open=False,
    items=[I(p,y,"observational",["adult neurogenesis"]) for p,y,n in pro] + [I(p,y,"observational",["none in adults"]) for p,y,n in con] +
          [I(0,2013,"textbook",["adult neurogenesis"],key="m45539-123",note="the-body-s-systems-m45539-123")]))

# R17 genetic code: overlapping, comma-free, non-overlapping from a fixed start
case(id="R17", kind="real", title="The genetic code: overlapping, comma-free, or read from a fixed start",
  probe="evidence that excludes one rival of three; winner not raised",
  years=[1954,1957,1961], key=1961,
  expect={1961: {"overlapping": "refuted", "comma-free": "refuted", "non-overlapping, fixed start": "established"}},
  source="Brenner 1957 PNAS (PMID 16590069); Nirenberg & Matthaei 1961 PNAS (PMID 14479932); Crick, Barnett, Brenner & Watts-Tobin 1961 Nature (PMID 13882203)",
  variants={"both": ("rivalry", [R("overlapping","",("isA","translation","overlapCode"),
                        [E(0,1954,"hypothesis",note="Gamow 1954, Nature doi:10.1038/173318a0",key="gamow54"),
                         E(16590069,1957,"observational","-",note="Brenner: impossibility of all overlapping triplet codes"),
                         E(13882203,1961,"mechanistic","-",note="Crick et al.: frameshift suppression, triplets from a fixed start")]),
                      R("comma-free","",("isA","translation","commaFree"),
                        [E(16590032,1957,"hypothesis",note="Crick, Griffith & Orgel: codes without commas"),
                         E(14479932,1961,"inVitro","-",note="Nirenberg & Matthaei: poly-U makes polyphenylalanine, so UUU is a codon")]),
                      R("non-overlapping, fixed start","",("isA","translation","fixedStart"),[E(13882203,1961,"mechanistic")])])},
  frame=dict(cells=["overlapping","comma-free","non-overlapping, fixed start"], open=True,
    items=[I(0,1954,"hypothesis",["overlapping"],key="gamow54"), I(16590069,1957,"observational",["comma-free","non-overlapping, fixed start","other"]),
           I(16590032,1957,"hypothesis",["comma-free"]), I(13882203,1961,"mechanistic",["non-overlapping, fixed start"]),
           I(14479932,1961,"inVitro",["overlapping","non-overlapping, fixed start","other"])]))

# R18 DNA structure
case(id="R18", kind="real", title="DNA structure: double helix, triple helix, side-by-side",
  probe="three rivals; evidence that excludes one; a late rival with no data",
  years=[1953,1976,1980], key=1980,
  expect={1953: {"double helix": "unsupported", "triple helix": "refuted", "side-by-side": "unsupported"}, 1980: {"double helix": "established", "triple helix": "refuted", "side-by-side": "refuted"}},
  source="Franklin & Gosling 1953 Nature (PMID 13054694); Wing et al. 1980 Nature (PMID 7432492); textbook molbio-m45473-157",
  variants={"both": ("rivalry", [R("double helix","",("isA","dna","doubleHelix"),
                        [E(13054692,1953,"hypothesis",note="Watson & Crick, Nature"),E(13054694,1953,"inVitro",note="Franklin & Gosling, Nature: helical B form"),
                         E(7432492,1980,"inVitro",note="Wing et al., Nature: crystal structure of a full turn of B-DNA")]),
                      R("triple helix","",("isA","dna","tripleHelix"),[E(16578429,1953,"hypothesis",note="Pauling & Corey, PNAS"),E(13054694,1953,"inVitro","-")]),
                      R("side-by-side","",("isA","dna","sideBySide"),[E(1067594,1976,"hypothesis",note="Rodley et al., PNAS"),E(7432492,1980,"inVitro","-")])])},
  frame=dict(cells=["double helix","triple helix","side-by-side"], open=True,
    items=[I(13054692,1953,"hypothesis",["double helix"]), I(16578429,1953,"hypothesis",["triple helix"]),
           I(13054694,1953,"inVitro",["double helix","side-by-side","other"]), I(1067594,1976,"hypothesis",["side-by-side"]),
           I(7432492,1980,"inVitro",["double helix"])]))

# R19 three domains vs two domains (eukaryotes inside archaea): P vs not-P
two = [(6587394,1984,"Lake et al., PNAS: eocytes"),(24336283,2013,"Williams et al., Nature: two primary domains"),
       (25945739,2015,"Spang et al., Nature: Lokiarchaeota"),(31819234,2020,"Williams et al., Nat Ecol Evol: two-domains tree"),
       (37316666,2023,"Eme et al., Nature: heimdallarchaeial ancestry")]
case(id="R19", kind="real", title="Three domains against two (eukaryotes inside Archaea)",
  probe="a minority view that becomes the majority; P against not-P",
  years=[1990,2013,2023], key=2023,
  expect={1990: {"two domains": "contested"}, 2023: {"two domains": "unsupported (favoured) or established"}},
  source="Eme et al. 2023 Nature (PMID 37316666); Williams et al. 2020 (PMID 31819234); Woese et al. 1990 PNAS (PMID 2112744)",
  variants={"one-claim": ("stmt", [R("two domains","Eukaryota is nested in Archaea",("isA","eukaryota","archaea"),
                          [E(270744,1977,"observational","-",note="Woese & Fox, PNAS: archaea as a primary kingdom"),
                           E(2112744,1990,"observational","-",note="Woese, Kandler & Wheelis: three domains")] + [E(p,y,"observational",note=n) for p,y,n in two])]),
            "both": ("rivalry", [R("three domains","",("notIsA","eukaryota","archaea"),[E(270744,1977,"observational"),E(2112744,1990,"observational")] + [E(p,y,"observational","-") for p,y,n in two if y >= 2013]),
                                 R("two domains","",("isA","eukaryota","archaea"),[E(p,y,"observational") for p,y,n in two])])},
  frame=dict(cells=["two domains","three domains"], open=False,
    items=[I(270744,1977,"observational",["three domains"]), I(2112744,1990,"observational",["three domains"])] + [I(p,y,"observational",["two domains"]) for p,y,n in two]))

# R20 Temin's provirus
case(id="R20", kind="real", title="Temin's DNA provirus (1964) against RNA-only replication",
  probe="evidence ahead of consensus; settled by a decisive pair of papers",
  years=[1964,1969,1970], key=1970,
  expect={1970: {"DNA provirus": "established", "RNA only": "refuted"}},
  source="Temin & Mizutani 1970 Nature (PMID 4316301); Baltimore 1970 Nature (PMID 4316300)",
  variants={"both": ("rivalry", [R("DNA provirus","RSV replicates through a DNA copy",("medByAct","rsv","viralRep","rtActivity"),
                        [E(14204701,1964,"inVitro",note="Temin, Virology: DNA participates in RSV production"),
                         E(14206598,1964,"inVitro",note="Temin, PNAS: RSV RNA hybridises with infected-cell DNA"),
                         E(4316301,1970,"inVitro",note="Temin & Mizutani, Nature: RNA-dependent DNA polymerase in RSV virions"),
                         E(4316300,1970,"inVitro",note="Baltimore, Nature: RNA-dependent DNA polymerase in RNA tumour viruses")]),
                      R("RNA only","RSV replicates RNA to RNA",("medByAct","rsv","viralRep","rdrpActivity"),[E(4316301,1970,"inVitro","-"),E(4316300,1970,"inVitro","-")])])},
  frame=dict(cells=["DNA provirus","RNA only"], open=True,
    items=[I(p,y,"inVitro",["DNA provirus"]) for p,y in [(14204701,1964),(14206598,1964),(4316301,1970),(4316300,1970)]]))

# R21 prions: protein only vs virus vs virino
case(id="R21", kind="real", title="Scrapie agent: protein only, virus, or virino",
  probe="evidence compatible with two rivals entered as support for one; a rival with no evidence refuted",
  years=[1967,1982,1993,2010], key=1993,
  expect={1993: {"protein only": "unsupported (favoured)", "virus": "refuted|unsupported", "virino": "unsupported"},
          2010: {"protein only": "established", "virus": "refuted", "virino": "refuted|unsupported"}},
  source="Bueler et al. 1993 Cell (PMID 8100741): PrP is required (compatible with protein-only and virino); Wang et al. 2010 Science (PMID 20110469): recombinant PrP alone makes prions",
  variants={"both": ("rivalry", [R("protein only","the scrapie agent is PrP",("isA","scrapieAgent","prp"),
                        [E(4964084,1967,"hypothesis",note="Griffith, Nature: self-replication and scrapie"),
                         E(4963878,1967,"inVitro",note="Alper et al., Nature: agent survives UV that destroys nucleic acid"),
                         E(6801762,1982,"inVitro",note="Prusiner, Science: proteinaceous infectious particles"),
                         E(8100741,1993,"mechanistic",note="Bueler et al., Cell: PrP-null mice resist scrapie"),
                         E(15286374,2004,"mechanistic",note="Legname et al., Science: synthetic mammalian prions"),
                         E(20110469,2010,"mechanistic",note="Wang et al., Science: prion from recombinant PrP")]),
                      R("virus","the scrapie agent is a virus",("hasPart","scrapieAgent","nucleicAcid"),
                        [E(4963878,1967,"inVitro","-"),E(17044041,2007,"observational",note="Manuelidis, J Cell Biochem: 25 nm virion"),E(20110469,2010,"mechanistic","-")]),
                      R("virino","the scrapie agent is a small nucleic acid in a host-protein coat",("hasPart","scrapieAgent","smallNA"),[])]),
            "refute-only": ("rivalry", [R("protein only","",("isA","scrapieAgent","prp"),
                        [E(4964084,1967,"hypothesis"),E(15286374,2004,"mechanistic"),E(20110469,2010,"mechanistic")]),
                      R("virus","",("hasPart","scrapieAgent","nucleicAcid"),
                        [E(4963878,1967,"inVitro","-"),E(6801762,1982,"inVitro","-"),E(8100741,1993,"mechanistic","-"),E(17044041,2007,"observational")]),
                      R("virino","",("hasPart","scrapieAgent","smallNA"),[])])},
  frame=dict(cells=["protein only","virus","virino"], open=True,
    items=[I(4964084,1967,"hypothesis",["protein only"]), I(4963878,1967,"inVitro",["protein only","virino","other"]),
           I(6801762,1982,"inVitro",["protein only","virino"]), I(8100741,1993,"mechanistic",["protein only","virino"]),
           I(15286374,2004,"mechanistic",["protein only"]), I(17044041,2007,"observational",["virus"]), I(20110469,2010,"mechanistic",["protein only"])]))

# R22 Red Queen vs mutational deterministic: pluralist, not exclusive
case(id="R22", kind="real", title="Why sex: Red Queen against mutation purging (pluralist)",
  probe="rivals that can both be true (pluralism) forced into exclusion",
  years=[1988,1999,2011], key=2011,
  expect={2011: {"Red Queen": "unsupported (supported in some systems)", "mutational deterministic": "unsupported"}},
  source="West, Lively & Read 1999 J Evol Biol (doi:10.1046/j.1420-9101.1999.00119.x): a pluralist approach; Morran et al. 2011 Science (PMID 21737739)",
  variants={"naive": ("rivalry", [R("Red Queen","",("medBy","sexRepro","sexRepro","redQueen"),
                        [E(0,1980,"hypothesis",note="Hamilton 1980, Oikos doi:10.2307/3544435",key="hamilton80"),
                         E(0,1987,"observational",note="Lively 1987, Nature doi:10.1038/328519a0: NZ snails",key="lively87"),
                         E(0,1999,"review",note="West, Lively & Read 1999: pluralist",key="west99"),
                         E(21737739,2011,"mechanistic",note="Morran et al., Science: coevolving parasites select for sex in C. elegans")]),
                      R("mutational deterministic","",("medBy","sexRepro","sexRepro","mutDet"),
                        [E(3057385,1988,"hypothesis",note="Kondrashov, Nature: deleterious mutations"),E(0,1999,"review",key="west99")])]),
            "not-rivals": ("stmt", [R("Red Queen","",("medBy","sexRepro","sexRepro","redQueen"),
                        [E(0,1980,"hypothesis",key="hamilton80"),E(0,1987,"observational",key="lively87"),E(0,1999,"review",key="west99"),E(21737739,2011,"mechanistic")])])},
  frame=dict(cells=["Red Queen","mutational deterministic"], open=True,
    items=[I(0,1980,"hypothesis",["Red Queen"],key="hamilton80"), I(0,1987,"observational",["Red Queen"],key="lively87"),
           I(3057385,1988,"hypothesis",["mutational deterministic"]), I(0,1999,"review",["Red Queen","mutational deterministic"],key="west99"),
           I(21737739,2011,"mechanistic",["Red Queen"])]))

# R23 GLP-1: repo statements S9c (central, BBB) and S9d (circumventricular, vagal)
case(id="R23", kind="real", title="Semaglutide acts centrally (S9c) or via circumventricular organs and vagus (S9d): repo statements",
  probe="same agent, same target, different mediator: shape says rivals, biology says both",
  years=[2026], key=2026,
  expect={2026: {"S9c": "contested", "S9d": "established"}},
  source="Gabery et al. 2020 JCI Insight (PMID 32213703): distributed neural pathways; repo verdicts in docs/design.md section 4",
  variants={"repo-separate": ("glp1", "separate"), "as-rivalry": ("glp1", "rivalry")},
  frame=None)

# R24 Geoffroy's dorsoventral inversion, revived 1994-96
case(id="R24", kind="real", title="Dorsoventral inversion (Geoffroy 1822) revived by sog/chordin (1995-96)",
  probe="an old proposal with weight 0 that later evidence confirms",
  years=[1993,1996,2006], key=1996,
  expect={1993: {"inversion": "unsupported", "independent origin": "unsupported"}, 1996: {"inversion": "established|unsupported (favoured)", "independent origin": "refuted|unsupported"}},
  source="De Robertis & Sasai 1996 Nature (PMID 8598900); Holley et al. 1995 Nature (PMID 7617035)",
  variants={"both": ("rivalry", [R("inversion","the chordate D-V axis is the arthropod axis inverted",("isA@chordata","dvPattern","invertedHomolog"),
                        [E(0,1822,"hypothesis",note="Geoffroy Saint-Hilaire 1822 (no DOI; UNVERIFIED)",key="geoffroy22"),
                         E(8072524,1994,"review",note="Arendt & Nubler-Jung, Nature: inversion of dorsoventral axis?"),
                         E(7617035,1995,"mechanistic",note="Holley et al., Nature: sog and chordin conserved and interchangeable"),
                         E(8598900,1996,"review",note="De Robertis & Sasai, Nature: a common plan"),
                         E(16933975,2006,"observational",note="Lowe et al., PLoS Biol: hemichordate D-V patterning")]),
                      R("independent origin","",("isA@chordata","dvPattern","independentAxis"),[E(7617035,1995,"mechanistic","-")])])},
  frame=dict(cells=["inversion","independent origin"], open=True,
    items=[I(0,1822,"hypothesis",["inversion"],key="geoffroy22"), I(8072524,1994,"review",["inversion"]), I(7617035,1995,"mechanistic",["inversion"]),
           I(8598900,1996,"review",["inversion"]), I(16933975,2006,"observational",["inversion"])]))

# ===================================================================== SYNTHETIC
case(id="S01", kind="synthetic", title="One experiment entered on both rivals against once",
  probe="double counting in isolation", years=[2000], key=2000,
  expect={2000: {"A": "unsupported", "B": "unsupported"}},
  source="synthetic: one mechanistic item (0.7) cannot give 0.82",
  variants={"both": ("rivalry", [R("A","",("isA","sX","sA"),[E(1,2000,"mechanistic")]), R("B","",("isA","sX","sB"),[E(1,2000,"mechanistic","-")])]),
            "once": ("rivalry", [R("A","",("isA","sX","sA"),[E(1,2000,"mechanistic")]), R("B","",("isA","sX","sB"),[])])},
  frame=dict(cells=["A","B"], open=False, items=[I(1,2000,"mechanistic",["A"])]))
case(id="S03", kind="synthetic", title="One experiment rules out C only; A and B both survive",
  probe="subset vote: support entered on two rivals manufactures a dispute", years=[2000], key=2000,
  expect={2000: {"A": "unsupported", "B": "unsupported", "C": "unsupported (d = 0.7)"}},
  source="synthetic",
  variants={"support-both": ("rivalry", [R("A","",("isA","sX","sA"),[E(1,2000,"mechanistic")]), R("B","",("isA","sX","sB"),[E(1,2000,"mechanistic")]),
                                         R("C","",("isA","sX","sC"),[E(1,2000,"mechanistic","-")])]),
            "refute-only": ("rivalry", [R("A","",("isA","sX","sA"),[]), R("B","",("isA","sX","sB"),[]), R("C","",("isA","sX","sC"),[E(1,2000,"mechanistic","-")])])},
  frame=dict(cells=["A","B","C"], open=True, items=[I(1,2000,"mechanistic",["A","B","other"])]))
case(id="S04", kind="synthetic", title="All named rivals false (non-exhaustive frame)",
  probe="two trials each refute one rival; the truth is 'neither'", years=[2000], key=2000,
  expect={2000: {"A": "refuted", "B": "refuted"}},
  source="synthetic",
  variants={"both": ("rivalry", [R("A","",("isA","sX","sA"),[E(1,2000,"rct","-")]), R("B","",("isA","sX","sB"),[E(2,2000,"rct","-")])])},
  frame=dict(cells=["A","B"], open=True, items=[I(1,2000,"rct",["B","other"]), I(2,2000,"rct",["A","other"])]),
  frame_closed=dict(cells=["A","B"], open=False, items=[I(1,2000,"rct",["B"]), I(2,2000,"rct",["A"])]))
case(id="S05", kind="synthetic", title="One rival split into two variants that share one paper",
  probe="rival splitting: the same evidence counted once per variant", years=[2000], key=2000,
  expect={2000: {"A": "unchanged by the split"}},
  source="synthetic",
  variants={"unsplit": ("rivalry", [R("A","",("isA","sX","sA"),[E(1,2000,"rct")]), R("B","",("isA","sX","sB"),[E(2,2000,"mechanistic")])]),
            "split": ("rivalry", [R("A","",("isA","sX","sA"),[E(1,2000,"rct")]), R("B1","",("isA","sX","sB"),[E(2,2000,"mechanistic")]),
                                  R("B2","",("isA","sX","sC"),[E(2,2000,"mechanistic")])])},
  frame=dict(cells=["A","B1","B2"], open=True, items=[I(1,2000,"rct",["A"]), I(2,2000,"mechanistic",["B1","B2"])]))
case(id="S06", kind="synthetic", title="Late evidence reverses a verdict; the early support was an artefact",
  probe="supersession: the 1960 item should stop counting", years=[1965,1970], key=1970,
  expect={1965: {"A": "unsupported", "B": "unsupported"}, 1970: {"A": "refuted", "B": "established"}},
  source="synthetic",
  variants={"both": ("rivalry", [R("A","",("isA","sX","sA"),[E(1,1960,"inVitro",until=1970),E(2,1970,"mechanistic","-"),E(3,1970,"mechanistic","-")]),
                                 R("B","",("isA","sX","sB"),[E(2,1970,"mechanistic"),E(3,1970,"mechanistic")])])},
  frame=dict(cells=["A","B"], open=False, items=[I(1,1960,"inVitro",["A"],until=1970), I(2,1970,"mechanistic",["B"]), I(3,1970,"mechanistic",["B"])]))
case(id="S07", kind="synthetic", title="Three proposals, no data",
  probe="hypotheses weigh 0; base rates per rival do not sum to 1", years=[2000], key=2000,
  expect={2000: {"A": "unsupported, P = 1/3", "B": "unsupported, P = 1/3", "C": "unsupported, P = 1/3"}},
  source="synthetic",
  variants={"both": ("rivalry", [R("A","",("isA","sX","sA"),[E(1,2000,"hypothesis")]), R("B","",("isA","sX","sB"),[E(2,2000,"hypothesis")]),
                                 R("C","",("isA","sX","sC"),[E(3,2000,"hypothesis")])])},
  frame=dict(cells=["A","B","C"], open=False, items=[I(1,2000,"hypothesis",["A"]), I(2,2000,"hypothesis",["B"]), I(3,2000,"hypothesis",["C"])]))
case(id="S09", kind="synthetic", title="The same statement listed twice in one rivalry",
  probe="no guard against duplicate rivals", years=[2000], key=2000,
  expect={2000: {"A": "established", "B": "refuted"}},
  source="synthetic",
  variants={"dup": ("rivalry", [R("A","",("isA","sX","sA"),[E(1,2000,"rct"),E(4,2000,"rct")]), R("A","",("isA","sX","sA"),[E(1,2000,"rct"),E(4,2000,"rct")]),
                                R("B","",("isA","sX","sB"),[])])},
  frame=dict(cells=["A","B"], open=False, items=[I(1,2000,"rct",["A"]), I(4,2000,"rct",["A"])]))
case(id="S10", kind="synthetic", title="Exhaustive pair: refuting B should support A",
  probe="exhaustiveness cannot be stated; the rivalry decides losers only", years=[2000], key=2000,
  expect={2000: {"A": "established", "B": "refuted"}},
  source="synthetic (A and B are stated to be the only possibilities)",
  variants={"both": ("rivalry", [R("A","",("isA","sX","sA"),[]), R("B","",("isA","sX","sB"),[E(1,2000,"rct","-")])])},
  frame=dict(cells=["A","B"], open=False, items=[I(1,2000,"rct",["A"])]))
case(id="S11", kind="synthetic", title="Two partial exclusions single out the survivor of a closed frame",
  probe="combining partial exclusions (the gap in B2)", years=[2000], key=2000,
  expect={2000: {"A": "belief above 0 (the only survivor)", "B": "refuted", "C": "refuted"}},
  source="synthetic (closed frame {A, B, C}; trial 1 excludes B, trial 2 excludes C)",
  variants={"refute-only": ("rivalry", [R("A","",("isA","sX","sA"),[]), R("B","",("isA","sX","sB"),[E(1,2000,"rct","-")]),
                                        R("C","",("isA","sX","sC"),[E(2,2000,"rct","-")])])},
  frame=dict(cells=["A","B","C"], open=False, items=[I(1,2000,"rct",["A","C"]), I(2,2000,"rct",["A","B"])]))

# ===================================================================== BUILD STAGE ADDITIONS
C = {c["id"]: c for c in CASES}

# R08a: B2's 1974 verdicts rest on withdrawing the illustrative 1965 intermediate report in 1967.
# The same frame with no withdrawal shows how much (pinned in Proto/Multinomial.lean).
C["R08a"]["frames_extra"] = [("no-withdrawal", dict(C["R08a"]["frame"],
    items=[dict(i, until=None) for i in C["R08a"]["frame"]["items"]]))]

# S05: the unsplit frame, to test that splitting B leaves A unchanged
C["S05"]["frame_unsplit"] = dict(cells=["A","B"], open=True, items=[I(1,2000,"rct",["A"]), I(2,2000,"mechanistic",["B"])])

# Best curation (the same rules for the current system and the prototype): context split, co-causes,
# coexisting mechanisms and refinements kept out of the frame. A list of frames per case; a missing
# entry means "the plain frame is already the best". `variant` names the encoding whose claims
# (with their contexts) label the translated statements.
FB = {
 "R02b": [dict(cells=["DNA","protein"], open=True, variant="ctx-cellular",
               items=[I(19871359,1944,"inVitro",["DNA"]), I(15421335,1950,"observational",["DNA"]), I(12981234,1952,"mechanistic",["DNA"])]),
          dict(cells=["RNA","protein"], open=True, variant="ctx-tmv",
               items=[I(13321939,1956,"inVitro",["RNA"]), I(13436476,1957,"inVitro",["RNA"])])],
 "R03b": [dict(C["R03a"]["frame"], variant="ctx")],
 "R04": [dict(cells=["chemical","electrical"], open=True, variant="ctx-vertebrate",
              items=[I(0,1921,"inVitro",["chemical"],key="loewi21"), I(16994763,1936,"mechanistic",["chemical"]),
                     I(14898516,1951,"mechanistic",["chemical"]), I(12991232,1952,"mechanistic",["chemical"])])],
 "R05": [dict(cells=["H. pylori","acid/stress"], open=True, variant="co-causes",
              items=[I(6145023,1984,"observational",["H. pylori"]), I(1558340,1992,"rct",["H. pylori"]),
                     I(8007082,1994,"review",["H. pylori"]), I(11809181,2002,"metaAnalysis",["H. pylori"])])],
 "R06": [dict(cells=["lock-and-key","induced fit"], open=True,
              items=[I(0,1894,"hypothesis",["lock-and-key"],key="fischer94"), I(16590179,1958,"hypothesis",["induced fit"]),
                     I(283394,1978,"inVitro",["induced fit"]), I(19841628,2009,"review",["induced fit"]),
                     I(0,2013,"textbook",["induced fit"],key="m45437-165")])],
 "R08d": [dict(cells=["chemiosmotic","chemical intermediate"], open=False,
               items=[i for i in C["R08d"]["frame"]["items"] if i["fav"] != ["chemiosmotic","conformational coupling"]] +
                     [I(p,y,"inVitro",["chemiosmotic"]) for p,y in [(4517936,1973),(8065448,1994),(9069291,1997)]])],
 "R22": [],
}
# Statements best curation keeps outside any frame: (rid, items, variant for the claim). Each is a
# closed two-cell frame {rid, "not"}, which is a plain Statement.
SB = {
 "R04": [("electrical (crayfish)", [I(13642302,1959,"mechanistic",["electrical (crayfish)"])], None)],
 "R05": [("NSAID", [I(11809181,2002,"metaAnalysis",["NSAID"])], None)],
 "R06": [("conformational selection", [I(19841628,2009,"review",["conformational selection"])], None)],
 "R08d": [("conformational coupling", [I(p,y,"inVitro",["conformational coupling"]) for p,y in [(4517936,1973),(8065448,1994),(9069291,1997)]], None)],
 "R22": [("Red Queen", [I(0,1980,"hypothesis",["Red Queen"],key="hamilton80"), I(0,1987,"observational",["Red Queen"],key="lively87"),
                        I(0,1999,"review",["Red Queen"],key="west99"), I(21737739,2011,"mechanistic",["Red Queen"])], "not-rivals")],
}
# Cases with no frame: best curation under the current system is a hand-written variant.
A2HAND = {"R23": ["repo-separate"]}

# P against not-P: the frame is a closed pair whose second cell is the negation of the first. Best
# curation today is one Statement with +/- evidence (rule 4), so `translate` emits one statement.
PAIR = {"R11a", "R11b", "R16", "R16b", "R19"}
for _cid in PAIR:
    C[_cid]["frame"]["pair"] = True

# A1 is "as the worked example enters evidence": each item on every rival it bears on, naive frame.
# For most cases that is the first variant; these cases list a better encoding first.
A1V = {c["id"]: list(c["variants"])[0] for c in CASES}
A1V.update({"R16": "both", "R19": "both", "R23": "as-rivalry", "R16b": "textbook"})

# Claims for frame cells that no Lean variant of the case names.
CLAIM_EXTRA = {("R04", "electrical (crayfish)"): (("isA@astacoidea", "synSig", "elecCoupling"), None),
               ("R08a", "chemiosmotic"): (("chemio", "cm"), None),
               ("R08a", "chemical intermediate"): (("chemio", "ci"), None)}

# Python copies of evidence that the Lean side takes from repo modules (for the mirror and the lint).
# R08a: BioLean/Examples/Chemiosmosis.lean (pmid 0 = illustrative). R23: BioLean/Lib/GLP1Statements.lean.
_cm = [E(13771349,1961,"hypothesis"), E(0,1965,"inVitro",key="protons65"), E(5220864,1966,"inVitro"),
       E(16742541,1967,"inVitro"), E(4330063,1971,"inVitro"), E(4272126,1974,"inVitro")]
_ci = [E(13111237,1953,"hypothesis"), E(0,1963,"hypothesis",key="reviews63"), E(0,1965,"inVitro",key="intermediate65"),
       E(5220864,1966,"inVitro","-"), E(16742541,1967,"inVitro","-"), E(4330063,1971,"inVitro","-"), E(4272126,1974,"inVitro","-")]
_real = lambda ev: [e for e in ev if e["pmid"] != 0]
_once = lambda ev: [e for e in ev if e["pol"] == "+"]
_s9c = [E(36035518,2022,"review"), E(29329976,2018,"review"), E(36419409,2022,"mechanistic"),
        E(32755557,2020,"mechanistic","-"), E(38381398,2024,"review","-")]
_s9d = [E(40896289,2025,"review"), E(25833771,2015,"review"), E(29317623,2018,"mechanistic"),
        E(34168616,2021,"mechanistic"), E(40622911,2025,"mechanistic")]
PYEV = {
 ("R08a", "repo"): [R("chemiosmotic","",("chemio","cm"),_cm), R("chemical intermediate","",("chemio","ci"),_ci)],
 ("R08a", "repo-real"): [R("chemiosmotic","",("chemio","cm"),_real(_cm)), R("chemical intermediate","",("chemio","ci"),_real(_ci))],
 ("R08a", "once"): [R("chemiosmotic","",("chemio","cm"),_cm), R("chemical intermediate","",("chemio","ci"),_once(_ci))],
 ("R08a", "once-real"): [R("chemiosmotic","",("chemio","cm"),_real(_cm)), R("chemical intermediate","",("chemio","ci"),_real(_once(_ci)))],
 ("R23", "as-rivalry"): [R("S9c","",("glp1","c"),_s9c), R("S9d","",("glp1","d"),_s9d)],
 ("R23", "repo-separate:S9c"): [R("S9c","",("glp1","c"),_s9c)],
 ("R23", "repo-separate:S9d"): [R("S9d","",("glp1","d"),_s9d)],
}

def best_frames(cid):
    """The best-curation frames of a case: FB (or the plain frame), then the SB solos as closed pairs."""
    c = C[cid]
    frames = FB[cid] if cid in FB else ([c["frame"]] if c.get("frame") else [])
    out = [dict(f) for f in frames]
    for rid, items, variant in SB.get(cid, []):
        out.append(dict(cells=[rid, "not"], open=False, items=items, variant=variant, solo=True))
    return out

def claim_of(cid, rid, variant=None):
    """The claim of rival `rid`, from the named variant first, then from any variant of the case."""
    vs = C[cid]["variants"]
    order = ([variant] if variant else []) + list(vs)
    for v in order:
        spec = vs.get(v)
        if spec and spec[0] in ("rivalry", "stmt"):
            for r in spec[1]:
                if r["rid"] == rid: return r["claim"], r.get("base")
    if (cid, rid) in CLAIM_EXTRA: return CLAIM_EXTRA[(cid, rid)]
    if cid == "R16b": return claim_of("R16", rid)
    raise KeyError((cid, rid))

def translate(cid, fr):
    """Today's best curation of a frame, as rivals for the current core: each item entered once, as
    support for the single named rival it singles out, otherwise as a refutation of every named rival
    it excludes. Items favouring the whole frame are dropped. A withdrawal year cannot be stated in the
    core, so withdrawn items stay in (A2). Their `until` is carried along, unused by A2, for option A2H
    (review stage), which drops them from that year on outside the core. Returns [R(...)] for the named
    cells (a solo frame gives one Statement)."""
    cells = list(fr["cells"]) + (["other"] if fr["open"] else [])
    named = [x for x in fr["cells"] if x != "not"] if fr.get("solo") else list(fr["cells"])
    if fr.get("pair"):
        # P against not-P: one Statement for P; items favouring not-P are its refutations (rule 4)
        p, notp = fr["cells"]
        ev = [E(it["pmid"], it["year"], it["kind"], "+" if it["fav"] == [p] else "-", note=it["note"] or it["key"], key=it["key"],
                until=it.get("until"))
              for it in fr["items"] if it["fav"] in ([p], [notp])]
        claim, base = claim_of(cid, p, fr.get("variant"))
        return [R(p, "", claim, ev, base=base)]
    out = []
    for x in named:
        ev = []
        for it in fr["items"]:
            fav = list(it["fav"])
            if set(fav) == set(cells): continue
            pol = None
            if fav == [x]: pol = "+"
            elif x in fav: pol = None
            elif len(fav) == 1 and fav[0] in named: pol = None      # the rivalry carries it to x
            else: pol = "-"
            if pol:
                e = E(it["pmid"], it["year"], it["kind"], pol, note=it["note"] or it["key"], key=it["key"], until=it.get("until"))
                if it.get("r2"): e["r2"] = True
                ev.append(e)
        claim, base = claim_of(cid, x, fr.get("variant"))
        out.append(R(x, "", claim, ev, base=base))
    return out

# Expected verdicts at every dated year (from the research `expect` dicts; sources in each case).
# A set means any of these is right. Cases scored by a special rule are marked in SPECIAL.
U, Es, Co, Rf = "unsupported", "established", "contested", "refuted"
EXPY = {
 "R01a": {1958: {"semi": {Es}, "conservative": {Rf}, "dispersive": {Rf}}},
 "R01b": {1958: {"semi": {U}, "conservative": {Rf, U}, "dispersive": {U}}},
 "R02a": {1944: {"DNA": {U}, "protein": {U}}, 1952: {"DNA": {Es}, "protein": {Rf}}},
 "R02b": {1957: {"DNA": {Es}, "protein": {Rf}, "RNA": {Es}}},
 "R03a": {1906: {"neuron doctrine": {Co}, "reticular": {Co}}, 1955: {"neuron doctrine": {Es}, "reticular": {Rf}}},
 # R04: the 1959 crayfish result is about another context; scored on its own rival. Vertebrate (or
 # context-free) "electrical" may read refuted or unsupported in 1959 (vertebrate electrical synapses
 # were described later; Pereda 2014).
 "R04":  {1952: {"chemical": {Es}, "electrical": {Rf}}, 1959: {"chemical": {Es}, "electrical": {Rf, U}, "electrical (crayfish)": {Es}}},
 "R05":  {1994: {"H. pylori": {Es}, "acid/stress": {Rf}}, 2002: {"H. pylori": {Es}, "acid/stress": {Rf}, "NSAID": {Es}}},
 "R06":  {1978: {"lock-and-key": {Rf}, "induced fit": {U}, "conformational selection": {U}},
          2013: {"lock-and-key": {Rf}, "induced fit": {Es}, "conformational selection": {U, Es}}},
 "R07":  {1976: {"instructive": {Rf}, "natural selection (Jerne)": {Rf, U}, "clonal selection": {Es}}},
 "R08a": {1965: {"chemiosmotic": {Co}, "chemical intermediate": {Co}}, 1974: {"chemiosmotic": {Es}, "chemical intermediate": {Rf}}},
 "R08c": {1964: {"chemiosmotic": {U}, "chemical intermediate": {U}}, 1974: {"chemiosmotic": {Es}, "chemical intermediate": {Rf}}},
 "R08d": {1997: {"chemiosmotic": {Es}, "chemical intermediate": {Rf}, "conformational coupling": {Es}}},
 "R09":  {1877: {"biogenesis": {Es}, "spontaneous generation": {Rf}}},
 "R10":  {2019: {"neutral": {Co}, "selection": {Co}}},
 "R11a": {2023: {"amyloid causes AD": {Co}}},
 "R12":  {1900: {"particulate": {Es}, "blending": {Rf}}},
 "R13":  {1990: {"Archezoa": {U}, "secondary loss": {U}}, 2003: {"Archezoa": {Rf}, "secondary loss": {Es}}},
 "R14":  {1999: {"endosymbiotic": {Es}, "autogenous": {Rf}}},
 "R15":  {1972: {"fluid mosaic": {Es}, "Davson-Danielli": {Rf}}},
 "R16":  {2022: {"adult neurogenesis": {Co}, "none in adults": {Co}}},
 "R17":  {1961: {"overlapping": {Rf}, "comma-free": {Rf}, "non-overlapping, fixed start": {Es}}},
 "R18":  {1953: {"double helix": {U}, "triple helix": {Rf}, "side-by-side": {U}}, 1980: {"double helix": {Es}, "triple helix": {Rf}, "side-by-side": {Rf}}},
 "R19":  {1990: {"two domains": {Co}, "three domains": {Co}}, 2023: {"two domains": {Co, U, Es}, "three domains": {Co, U}}},
 "R20":  {1970: {"DNA provirus": {Es}, "RNA only": {Rf}}},
 "R21":  {1993: {"protein only": {U}, "virus": {Rf, U}, "virino": {U}}, 2010: {"protein only": {Es}, "virus": {Rf}, "virino": {Rf, U}}},
 "R22":  {2011: {"Red Queen": {U, Es}, "mutational deterministic": {U}}},
 "R23":  {2026: {"S9c": {Co}, "S9d": {Es}}},
 "R24":  {1993: {"inversion": {U}, "independent origin": {U}}, 1996: {"inversion": {Es, U}, "independent origin": {Rf, U}}},
 "S01":  {2000: {"A": {U}, "B": {U}}},
 "S03":  {2000: {"A": {U}, "B": {U}, "C": {U}}},
 "S04":  {2000: {"A": {Rf}, "B": {Rf}}},
 "S06":  {1965: {"A": {U}, "B": {U}}, 1970: {"A": {Rf}, "B": {Es}}},
 "S07":  {2000: {"A": {U}, "B": {U}, "C": {U}}},
 "S09":  {2000: {"A": {Es}, "B": {Rf}}},
 "S10":  {2000: {"A": {Es}, "B": {Rf}}},
 # added in the build stage (cases from the research rerun)
 "R01c": {1958: {"conservative": {Rf, U}}},
 "R16b": {2022: {"adult neurogenesis": {Co}}},
 "S11":  {2000: {"B": {Rf}, "C": {Rf}}},
}
# Extra rules (scorer): R03b unchanged 2022->2023; R11b Lesne stops counting from 2024; R12 belief > 0
# in 1899 while unsupported; R22 mutation purging gets no disbelief above 1/4 from Red Queen support;
# S05 A unchanged by the split; S07 projected probabilities sum to 1.
# R01c dispersive has belief 0 and disbelief above 0 in every order of entry. S11 A has belief above 0.
# Review stage: R23 gets the same pluralism test as R22 (both mechanisms act, Gabery 2020), so a
# Rivalry that moves a rival's numbers is caught even when the verdict happens to survive.
SPECIAL = {"R03b", "R11b", "R12", "R22", "S05", "S07", "R01c", "S11", "R23"}
# Rules that are not verdicts, in words (for the table and the doc).
RULE = {
 "R03b": "the vertebrate verdict numbers in 2023 equal those of 2022",
 "R11b": "in 2025 still contested, and Lesne 2006 no longer counts (2025 differs from 2023)",
 "R12": "1899: particulate has belief above 0 and is unsupported (one data paper, not established)",
 "R22": "mutation purging gets no disbelief above 1/4 from Red Queen support",
 "S05": "A's opinion is the same before and after B is split",
 "S07": "projected probabilities over the closed frame sum to 1 (1/3 each)",
 "R01c": "dispersive has belief 0 and disbelief above 0, whatever the order of entry",
 "S11": "A has belief above 0 (the only survivor of a closed frame)",
 "R23": "neither statement's disbelief rises by more than 1/4 because of the other (both mechanisms act)",
}
# Cases the current core cannot state at all: the premise that makes the right answer right.
# Review stage: S10 removed. A closed pair is P against not-P, which rule 4 states as one Statement
# today, and A2 gets the right verdicts (pinned S10_A2_0_2000_num). A1 enters nothing on A: SILENT.
INEXPR = {"S07": "a base rate shared over a frame (each rival gets 1/2 on its own)",
          "S11": "that A, B and C are the only possibilities (a closed frame)",
          "R11b": "that an item stops counting from a year (a retraction date)"}


# Review stage: option A2H is A2 plus a withdrawal year (option H) emulated outside the core, on
# today's Statement and Rivalry. An item stops counting from its `until` year.
def withdrawals(cid):
    """(pmid, note as emitted in Lean, year withdrawn) for every withdrawn item of a case's best frames."""
    out = []
    for fr in best_frames(cid):
        for it in fr["items"]:
            if it.get("until") is not None and not it.get("r2"):
                t = (it["pmid"], it["note"] or it["key"], it["until"])
                if t not in out: out.append(t)
    return out
