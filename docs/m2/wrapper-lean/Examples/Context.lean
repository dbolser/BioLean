import BioLean.Derivation

/-!
# Context (M2), design "wrapper": context lives on the claim

`Claim.inContext ctx c`. Three rules: `contextualise` (bare universal into any context, free),
`specialise` (narrow the context, free), `transport` (sideways to another taxon, chained with a
`.transport` warrant at 3/10). Every pre-M2 rule matches bare claims only.

Contents: the 40 textbook claims marked context_required (`data/m2/context_claims.json`,
`sample40`), six NMN statements, three chemiosmosis statements, and soundness tests S1 to S5.

CURIEs checked against the local OAK sqlite builds (GO, CL, UBERON, CHEBI, HP, PATO, MONDO,
2026-10) unless marked `-- unverified`. PR, NCBITaxon, PO, SO and NCIT are not in the local set.
-/

namespace BioLean.ContextEx
open Derivation

def tb (note : String) : Evidence := { pmid := 0, year := 2013, kind := .textbook, note := note }
/-- A textbook sentence as a statement. -/
def tbS (id text : String) (c : Claim) : Statement := ⟨id, text, c, [tb text]⟩

-- RO relations not named in `Rel.lean`
def hasParticipant : Rel := ⟨.ro, 57, false⟩
def hasQuality     : Rel := ⟨.ro, 86, false⟩
def happensDuring  : Rel := ⟨.ro, 2092, false⟩
def developsFrom   : Rel := ⟨.ro, 2202, false⟩
def adjacentTo     : Rel := ⟨.ro, 2220, false⟩

/-! ## Entities -/

-- taxa (NCBITaxon labels checked in the local CL/UBERON imports)
def human      : Entity .taxon := ⟨"NCBITaxon:9606", "Homo sapiens"⟩
def mouse      : Entity .taxon := ⟨"NCBITaxon:10090", "Mus musculus"⟩     -- unverified locally
def rat        : Entity .taxon := ⟨"NCBITaxon:10116", "Rattus norvegicus"⟩ -- unverified locally
def spinach    : Entity .taxon := ⟨"NCBITaxon:3562", "Spinacia oleracea"⟩ -- unverified locally
def mammalia   : Entity .taxon := ⟨"NCBITaxon:40674", "Mammalia"⟩
def vertebrata : Entity .taxon := ⟨"NCBITaxon:7742", "Vertebrata"⟩
def metazoa    : Entity .taxon := ⟨"NCBITaxon:33208", "Metazoa"⟩
def eukaryota  : Entity .taxon := ⟨"NCBITaxon:2759", "Eukaryota"⟩
def plants     : Entity .taxon := ⟨"NCBITaxon:33090", "Viridiplantae"⟩
def bacteria   : Entity .taxon := ⟨"NCBITaxon:2", "Bacteria"⟩
def ecoli      : Entity .taxon := ⟨"NCBITaxon:562", "Escherichia coli"⟩

-- textbook entities (Sonnet groundings from the data file)
def telomerase      : Entity .component := ⟨"GO:0005697", "telomerase holoenzyme complex"⟩
def cell            : Entity .cellType  := ⟨"CL:0000000", "cell"⟩
def adrenaline      : Entity .chemical  := ⟨"CHEBI:33568", "adrenaline"⟩
def lipidCatabolism : Entity .process   := ⟨"GO:0016042", "lipid catabolic process"⟩
def adipose         : Entity .anatomy   := ⟨"UBERON:0001013", "adipose tissue"⟩
def cardiacConduction : Entity .process := ⟨"GO:0061337", "cardiac conduction"⟩
def cardiacContraction : Entity .process := ⟨"GO:0060048", "cardiac muscle contraction"⟩
def atrium          : Entity .anatomy   := ⟨"UBERON:0002081", "cardiac atrium"⟩
def importIntoCell  : Entity .process   := ⟨"GO:0098657", "import into cell"⟩
def water           : Entity .chemical  := ⟨"CHEBI:15377", "water"⟩
def stomatalClosure : Entity .process   := ⟨"GO:0090332", "stomatal closure"⟩
def oxygen          : Entity .chemical  := ⟨"CHEBI:15379", "dioxygen"⟩
def leaf            : Entity .anatomy   := ⟨"PO:0025034", "leaf"⟩                -- PO, not UBERON
def glucagon        : Entity .protein   := ⟨"PR:P01275", "glucagon"⟩              -- unverified
def glucose         : Entity .chemical  := ⟨"CHEBI:17234", "glucose"⟩
def blood           : Entity .anatomy   := ⟨"UBERON:0000178", "blood"⟩
def ftsZ            : Entity .protein   := ⟨"PR:000022726", "FtsZ"⟩               -- unverified
def cytoskeleton    : Entity .component := ⟨"GO:0005856", "cytoskeleton"⟩
def insulin         : Entity .protein   := ⟨"PR:000009054", "preproinsulin"⟩      -- PR label is preproinsulin
def potassium       : Entity .chemical  := ⟨"CHEBI:29103", "potassium(1+)"⟩
def aldosterone     : Entity .chemical  := ⟨"CHEBI:27584", "aldosterone"⟩
def plantCellWall   : Entity .component := ⟨"GO:0009505", "plant-type cell wall"⟩
def plasmaMembrane  : Entity .component := ⟨"GO:0005886", "plasma membrane"⟩
def anp             : Entity .protein   := ⟨"PR:P01160", "atrial natriuretic peptide"⟩ -- unverified
def sodium          : Entity .chemical  := ⟨"CHEBI:29101", "sodium(1+)"⟩
def microvillus     : Entity .component := ⟨"GO:0005902", "microvillus"⟩
def intestinalAbsorption : Entity .process := ⟨"GO:0050892", "intestinal absorption"⟩
def binaryFission   : Entity .process   := ⟨"GO:0043093", "FtsZ-dependent cytokinesis"⟩
def cellDivision    : Entity .process   := ⟨"GO:0051301", "cell division"⟩
def ner             : Entity .process   := ⟨"GO:0006289", "nucleotide-excision repair"⟩
def skinNeoplasm    : Entity .phenotype := ⟨"HP:0008069", "Neoplasm of the skin"⟩
def malignantCell   : Entity .cellType  := ⟨"CL:0001064", "malignant cell"⟩
def telomereMaintenance : Entity .process := ⟨"GO:0000723", "telomere maintenance"⟩
def lacticFermentation : Entity .process := ⟨"GO:0019661", "homolactic fermentation"⟩ -- OBSOLETE in GO
def erythrocyte     : Entity .cellType  := ⟨"CL:0000232", "erythrocyte"⟩
def nuclearReassembly : Entity .process := ⟨"GO:0031468", "nuclear membrane reassembly"⟩
def telophaseI      : Entity .process   := ⟨"GO:0007134", "meiotic telophase I"⟩
def respSystem      : Entity .anatomy   := ⟨"UBERON:0001004", "respiratory system"⟩
def gasExchange     : Entity .process   := ⟨"GO:0007585", "respiratory gaseous exchange by respiratory system"⟩
def cardiacMuscleCell : Entity .cellType := ⟨"CL:0000746", "cardiac muscle cell"⟩
def meiosis         : Entity .process   := ⟨"GO:0051321", "meiotic cell cycle"⟩
def sexualReproduction : Entity .process := ⟨"GO:0019953", "sexual reproduction"⟩
def chromosome      : Entity .component := ⟨"GO:0005694", "chromosome"⟩
def nucleus         : Entity .component := ⟨"GO:0005634", "nucleus"⟩
def drug            : Entity .chemical  := ⟨"CHEBI:23888", "drug"⟩
def pain            : Entity .phenotype := ⟨"HP:0012531", "Pain"⟩
def photosynthesis  : Entity .process   := ⟨"GO:0015979", "photosynthesis"⟩
def carbohydrate    : Entity .chemical  := ⟨"CHEBI:16646", "carbohydrate"⟩
def gamete          : Entity .cellType  := ⟨"CL:0000300", "gamete"⟩
def germCell        : Entity .cellType  := ⟨"CL:0000586", "germ cell"⟩
def pns             : Entity .anatomy   := ⟨"UBERON:0000010", "peripheral nervous system"⟩
def nerve           : Entity .anatomy   := ⟨"UBERON:0001021", "nerve"⟩
def sympatheticNS   : Entity .anatomy   := ⟨"UBERON:0000013", "sympathetic nervous system"⟩
def smoothMuscleRelaxation : Entity .process := ⟨"GO:0044557", "relaxation of smooth muscle"⟩
def bronchus        : Entity .anatomy   := ⟨"UBERON:0002185", "bronchus"⟩
def genome          : Entity .gene      := ⟨"SO:0001026", "genome"⟩
def nucleoid        : Entity .component := ⟨"GO:0009295", "nucleoid"⟩
def prokaryoticCell : Entity .cellType  := ⟨"CL:0000520", "prokaryotic cell"⟩
def cytokinesis     : Entity .process   := ⟨"GO:0000910", "cytokinesis"⟩
def cleavageFurrow  : Entity .component := ⟨"GO:0032154", "cleavage furrow"⟩  -- a component; GO:0036089 is the process
def chromosomeCondensation : Entity .process := ⟨"GO:0030261", "chromosome condensation"⟩
def prophaseII      : Entity .process   := ⟨"GO:0007136", "meiotic prophase II"⟩
def glycolysis      : Entity .process   := ⟨"GO:0006096", "glycolytic process"⟩
def triploid        : Entity .phenotype := ⟨"PATO:0001381", "triploid"⟩
def sterile         : Entity .phenotype := ⟨"PATO:0000956", "sterile"⟩
def lysosome        : Entity .component := ⟨"GO:0005764", "lysosome"⟩
def digestion       : Entity .process   := ⟨"GO:0007586", "digestion"⟩
def lactoseCatabolism : Entity .process := ⟨"GO:0005990", "lactose catabolic process"⟩
def lactose         : Entity .chemical  := ⟨"CHEBI:17716", "lactose"⟩
def golgi           : Entity .component := ⟨"GO:0005794", "Golgi apparatus"⟩
def polysaccharideSynthesis : Entity .process := ⟨"GO:0000271", "polysaccharide biosynthetic process"⟩
def transcription   : Entity .process   := ⟨"GO:0006351", "DNA-templated transcription"⟩
def cytoplasm       : Entity .component := ⟨"GO:0005737", "cytoplasm"⟩
def antidepressant  : Entity .chemical  := ⟨"CHEBI:35469", "antidepressant"⟩
def neurogenesis    : Entity .process   := ⟨"GO:0022008", "neurogenesis"⟩
def hippocampus     : Entity .anatomy   := ⟨"UBERON:0002421", "hippocampal formation"⟩
def g2Checkpoint    : Entity .process   := ⟨"GO:0007095", "mitotic G2 DNA damage checkpoint signaling"⟩
def g2mTransition   : Entity .process   := ⟨"GO:0000086", "G2/M transition of mitotic cell cycle"⟩

/-! ## The 40 textbook claims (`sample40`, in file order) -/

def T01 := tbS "molbio-m45475-69" "Telomerase is present in human cells"
  (.inContext { taxon := some human } (.rel .locatedIn telomerase cell))
def T02 := tbS "the-body-s-systems-m45537-183" "Epinephrine and norepinephrine accelerate breakdown of stored fat in adipose tissue"
  (.inContext { anatomy := some adipose } (.effect adrenaline .pos (.process lipidCatabolism)))
def T03 := tbS "the-body-s-systems-m45536-190" "The electrochemical signal causes the two atria to contract in unison"
  (.inContext { anatomy := some atrium } (.effect cardiacConduction .pos (.process cardiacContraction)))
def T04 := tbS "cell-structure-and-function-m45434-70" "In a hypotonic solution water enters the cell"
  (.inContext { condition := some "hypotonic solution" } (.rel hasParticipant importIntoCell water))
def T05 := tbS "photosynthesis-m45448-120" "stomatal closure raises oxygen levels inside the leaf"
  (.inContext { anatomy := some leaf } (.effect stomatalClosure .pos (.amount oxygen)))
def T06 := tbS "the-body-s-systems-m45537-201" "Glucagon causes release of glucose from the liver into the blood"
  (.inContext { anatomy := some blood } (.effect glucagon .pos (.amount glucose)))
def T07 := tbS "reproduction-at-the-cellular-level-m45463-67" "FtsZ is a tubulin-like protein component of the prokaryotic cytoskeleton."
  (.inContext { taxon := some bacteria } (.rel .partOf ftsZ cytoskeleton))
def T08 := tbS "the-body-s-systems-m45537-334" "Increasing blood glucose causes the pancreas to release insulin"
  (.inContext { anatomy := some blood } (.effect glucose .pos (.amount insulin)))
def T09 := tbS "the-body-s-systems-m45537-156" "An increase in blood potassium stimulates aldosterone release"
  (.inContext { anatomy := some blood } (.effect potassium .pos (.amount aldosterone)))
def T10 := tbS "cell-structure-and-function-m45432-219" "The plant cell wall is external to the plasma membrane"
  (.inContext { taxon := some plants } (.rel adjacentTo plantCellWall plasmaMembrane))
def T11 := tbS "the-body-s-systems-m45537-229" "The atrial hormone reduces blood Na+ concentration"
  (.inContext { anatomy := some blood } (.effect anp .neg (.amount sodium)))
def T12 := tbS "cell-structure-and-function-m45432-25" "Loss of microvilli prevents nutrient absorption in celiac patients"
  (.inContext { condition := some "celiac disease (MONDO:0005130)" } (.effect microvillus .pos (.process intestinalAbsorption)))
def T13 := tbS "reproduction-at-the-cellular-level-m45463-66" "Binary fission is the process of prokaryotic cell division."
  (.inContext { taxon := some bacteria } (.rel .isA binaryFission cellDivision))
/-- Forced: the condition is the perturbation (loss of NER), not a context the claim holds in. -/
def T14 := tbS "molbio-m45475-117" "People with defective nucleotide excision repair genes develop skin cancers early in life"
  (.inContext { taxon := some human, condition := some "defective NER genes; early onset" }
    (.effect ner .neg (.phenotype skinNeoplasm)))
def T15 := tbS "the-body-s-systems-m45537-53" "Insulin decreases blood-glucose levels"
  (.inContext { anatomy := some blood } (.effect insulin .neg (.amount glucose)))
/-- "some cancer cells" is a quantifier, not a condition: `quant .some` inside the context. -/
def T16 := tbS "molbio-m45475-67" "Telomerase is active in some cancer cells"
  (.inContext { cellType := some malignantCell } (.quant .some (.rel .capableOf telomerase telomereMaintenance)))
def T17 := tbS "how-cells-obtain-energy-m45440-11" "Lactic acid fermentation occurs routinely in mammalian red blood cells"
  (.inContext { taxon := some mammalia, cellType := some erythrocyte } (.rel .occursIn lacticFermentation erythrocyte))
/-- Sonnet gave an empty context. "In some organisms" quantifies over unnamed taxa; the nearest
fit is `some` over the subject, which is weaker than the sentence and not the same claim. -/
def T18 := tbS "the-cellular-basis-of-inheritance-m45466-103" "In some organisms nuclear envelopes form around the chromatids in telophase I"
  (.quant .some (.rel happensDuring nuclearReassembly telophaseI))
def T19 := tbS "the-body-s-systems-m45536-175" "Animal respiratory systems facilitate gas exchange"
  (.inContext { taxon := some metazoa } (.rel .capableOf respSystem gasExchange))
def T20 := tbS "the-body-s-systems-m45536-212" "An electrical signal triggers atrial cardiac muscle cells to contract"
  (.inContext { anatomy := some atrium, cellType := some cardiacMuscleCell }
    (.effect cardiacConduction .pos (.process cardiacContraction)))
/-- "only" is lost. -/
def T21 := tbS "the-cellular-basis-of-inheritance-m45466-165" "In a diploid-dominant organism such as an animal, meiotic cells participate only in sexual reproduction"
  (.inContext { taxon := some metazoa } (.rel .partOf meiosis sexualReproduction))
def T22 := tbS "reproduction-at-the-cellular-level-m45455-16" "Chromosomes are located in the nucleus of eukaryotic cells."
  (.inContext { taxon := some eukaryota } (.rel .locatedIn chromosome nucleus))
def T23 := tbS "the-body-s-systems-m45538-197" "Medications relieve pain in rheumatoid arthritis"
  (.inContext { condition := some "rheumatoid arthritis (MONDO:0008383)" } (.effect drug .neg (.phenotype pain)))
def T24 := tbS "how-cells-obtain-energy-m45437-11" "Photosynthesizing organisms (plants) produce sugars"
  (.inContext { taxon := some plants } (.rel .hasOutput photosynthesis carbohydrate))
def T25 := tbS "the-cellular-basis-of-inheritance-m45465-68" "Gametes are produced from diploid germ cells"
  (.inContext { taxon := some metazoa } (.rel developsFrom gamete germCell))
def T26 := tbS "the-body-s-systems-m45537-337" "Glucagon stimulates release of stored glucose from the liver into the bloodstream"
  (.inContext { anatomy := some blood } (.effect glucagon .pos (.amount glucose)))
def T27 := tbS "the-body-s-systems-m45539-28" "The vertebrate PNS is made up of peripheral sensory and motor nerves"
  (.inContext { taxon := some vertebrata } (.rel .hasPart pns nerve))
def T28 := tbS "the-body-s-systems-m45536-61" "Sympathetic input causes bronchial muscle relaxation"
  (.inContext { anatomy := some bronchus } (.effect sympatheticNS .pos (.process smoothMuscleRelaxation)))
/-- Sonnet's taxon was NCIT:C14263 "prokaryote": no NCBITaxon node exists (paraphyletic), so the
context uses the CL cell type instead. -/
def T29 := tbS "reproduction-at-the-cellular-level-m45455-9" "The nucleoid is the region of a prokaryotic cell containing the genome."
  (.inContext { cellType := some prokaryoticCell } (.rel .locatedIn genome nucleoid))
/-- "and some fungi" is lost; GO:0032154 is the furrow (a component), as Sonnet grounded it. -/
def T30 := tbS "the-cellular-basis-of-inheritance-m45466-106" "In animals and some fungi cytokinesis separates cell contents by a cleavage furrow"
  (.inContext { taxon := some metazoa } (.rel .hasPart cytokinesis cleavageFurrow))
def T31 := tbS "the-cellular-basis-of-inheritance-m45466-119" "In prophase II chromosomes condense again if they decondensed in telophase I"
  (.inContext { condition := some "chromosomes decondensed in telophase I" } (.rel happensDuring chromosomeCondensation prophaseII))
/-- "mature" goes in `stage`; "only" is lost. -/
def T32 := tbS "how-cells-obtain-energy-m45438-42" "Mature mammalian red blood cells are capable only of glycolysis"
  (.inContext { taxon := some mammalia, stage := some "mature" } (.rel .capableOf erythrocyte glycolysis))
def T33 := tbS "the-cellular-basis-of-inheritance-m45467-83" "Triploid animals are sterile"
  (.inContext { taxon := some metazoa } (.effect triploid .pos (.phenotype sterile)))
/-- No NCBITaxon node for "single-celled eukaryotes" (protists are paraphyletic). -/
def T34 := tbS "cell-structure-and-function-m45432-162" "In single-celled eukaryotes, lysosomes digest ingested food"
  (.inContext { taxon := some eukaryota, condition := some "unicellular" } (.rel .capableOf lysosome digestion))
def T35 := tbS "molbio-m45480-30" "Lactose is a food source for E. coli"
  (.inContext { taxon := some ecoli } (.rel .hasInput lactoseCatabolism lactose))
def T36 := tbS "cell-structure-and-function-m45432-158" "In plant cells, the Golgi synthesises polysaccharides"
  (.inContext { taxon := some plants } (.rel .capableOf golgi polysaccharideSynthesis))
def T37 := tbS "molbio-m45476-20" "In prokaryotes transcription occurs in the cytoplasm"
  (.inContext { cellType := some prokaryoticCell } (.rel .occursIn transcription cytoplasm))
def T38 := tbS "the-body-s-systems-m45539-132" "Some antidepressant medications promote neurogenesis in the hippocampus"
  (.inContext { anatomy := some hippocampus } (.quant .some (.effect antidepressant .pos (.process neurogenesis))))
def T39 := tbS "the-body-s-systems-m45537-336" "Decreasing blood glucose causes the pancreas to release glucagon"
  (.inContext { anatomy := some blood } (.effect glucose .neg (.amount glucagon)))
/-- The condition "certain conditions not met" carries no information; kept as Sonnet gave it. -/
def T40 := tbS "reproduction-at-the-cellular-level-m45461-141" "The G2 checkpoint blocks entry to the mitotic phase if certain conditions are not met."
  (.inContext { condition := some "certain conditions not met" } (.effect g2Checkpoint .neg (.process g2mTransition)))

def sample40 : List Statement :=
  [T01, T02, T03, T04, T05, T06, T07, T08, T09, T10, T11, T12, T13, T14, T15, T16, T17, T18, T19, T20,
   T21, T22, T23, T24, T25, T26, T27, T28, T29, T30, T31, T32, T33, T34, T35, T36, T37, T38, T39, T40]

example : sample40.length = 40 := rfl

/-! ## NMN -/

def NMN  : Entity .chemical := ⟨"CHEBI:16171", "NMN zwitterion"⟩
def NADp : Entity .chemical := ⟨"CHEBI:15846", "NAD(+)"⟩
def liver : Entity .anatomy := ⟨"UBERON:0002107", "liver"⟩
def skeletalMuscle : Entity .anatomy := ⟨"UBERON:0001134", "skeletal muscle tissue"⟩
def impairedGlucoseTolerance : Entity .phenotype := ⟨"HP:0040270", "Impaired glucose tolerance"⟩ -- MP:0005293 in mouse
def insulinResistance : Entity .phenotype := ⟨"HP:0000855", "Insulin resistance"⟩
def locomotion : Entity .process := ⟨"GO:0040011", "locomotion"⟩  -- proxy for "physical activity"
/-- "Increases endurance" as "decreases exercise intolerance": HP has no endurance term, and an
HP term lets the mouse and the human claim share one phenotype (uPheno-style). -/
def exerciseIntolerance : Entity .phenotype := ⟨"HP:0003546", "Exercise intolerance"⟩

def animal (pmid year : Nat) (note : String) : Evidence :=
  { pmid := pmid, year := year, kind := .mechanistic, note := note }

/-- The inner claims, context-free. -/
def raisesNAD : Claim := .effect NMN .pos (.amount NADp)
def lowersIGT : Claim := .effect NMN .neg (.phenotype impairedGlucoseTolerance)
def raisesActivity : Claim := .effect NMN .pos (.process locomotion)
def raisesEndurance : Claim := .effect NMN .neg (.phenotype exerciseIntolerance)
def raisesInsulinSensitivity : Claim := .effect NMN .neg (.phenotype insulinResistance)

def N1 : Statement := ⟨"Y11_NAD", "NMN raises NAD+ in mouse liver",
  .inContext { taxon := some mouse, anatomy := some liver } raisesNAD,
  [animal 21982712 2011 "Yoshino 2011"]⟩
def N2 : Statement := ⟨"Y11_IGT", "NMN reduces impaired glucose tolerance in high-fat-diet mice",
  .inContext { taxon := some mouse, condition := some "high-fat diet" } lowersIGT,
  [animal 21982712 2011 "Yoshino 2011"]⟩
def N3 : Statement := ⟨"Mi16", "long-term oral NMN reduces age-associated decline in physical activity in mice",
  .inContext { taxon := some mouse, stage := some "aged", condition := some "oral NMN, 12 months" } raisesActivity,
  [animal 28068222 2016 "Mills 2016"]⟩
def N4 : Statement := ⟨"Das18", "NMN increases endurance in aged mice",
  .inContext { taxon := some mouse, stage := some "aged" } raisesEndurance,
  [animal 29570999 2018 "Das 2018"]⟩
def N5 : Statement := ⟨"Y21", "NMN increases muscle insulin sensitivity in prediabetic postmenopausal women",
  .inContext { taxon := some human, anatomy := some skeletalMuscle, stage := some "postmenopausal",
               condition := some "prediabetic, female, 10 weeks" } raisesInsulinSensitivity,
  [{ pmid := 33888596, year := 2021, kind := .rct, note := "Yoshino 2021 RCT" }]⟩
/-- (6) The hypothesis to test. A claim, not a statement: nobody asserts it. -/
def H6 : Claim := .inContext { taxon := some human } raisesEndurance

/-! ## Chemiosmosis -/

def atpSynthase : Entity .component := ⟨"GO:0045259", "proton-transporting ATP synthase complex"⟩
def pmfATP : Entity .process := ⟨"GO:0015986", "proton motive force-driven ATP synthesis"⟩
def thylakoidMembrane : Entity .component := ⟨"GO:0042651", "thylakoid membrane"⟩
def mitoInnerMembrane : Entity .component := ⟨"GO:0005743", "mitochondrial inner membrane"⟩
def membrane : Entity .component := ⟨"GO:0016020", "membrane"⟩

def makesATP : Claim := .rel .capableOf atpSynthase pmfATP

def C7 : Statement := ⟨"Jag66", "ATP synthase makes ATP from a proton gradient in thylakoid membranes",
  .inContext { taxon := some spinach, component := some thylakoidMembrane,
               condition := some "in vitro, acid-base transition in the dark" } makesATP,
  [{ pmid := 5220864, year := 1966, kind := .inVitro, note := "Jagendorf & Uribe 1966" }]⟩
def C8 : Statement := ⟨"MM67", "ATP synthase makes ATP from a proton gradient in the mitochondrial inner membrane",
  .inContext { taxon := some rat, component := some mitoInnerMembrane, condition := some "in vitro" } makesATP,
  [{ pmid := 16742541, year := 1967, kind := .inVitro, note := "Mitchell & Moyle 1967" }]⟩
/-- Chimeric: one `taxon` slot cannot hold H. salinarum and Bos taurus, so the system goes in
`condition` and the taxon is left open. -/
def C9 : Statement := ⟨"Rac74", "ATP synthase makes ATP from a light-driven proton gradient in reconstituted liposomes",
  .inContext { condition := some "in vitro, reconstituted liposome: H. salinarum bacteriorhodopsin (NCBITaxon:2242) + bovine F1Fo (NCBITaxon:9913), light" } makesATP,
  [{ pmid := 4272126, year := 1974, kind := .inVitro, note := "Racker & Stoeckenius 1974" }]⟩

/-! ## Soundness tests -/

/-! ### S1. Mouse and human evidence never fuse by accident -/

-- Mouse (4) and human (5) are different claims: `both` does not type-check.
#check_failure (both (.lit N4) (.lit N5))
-- Nor does a mouse statement prove the context-free claim: there is no rule out of a context.
#check_failure ((.lit N4 : Derivation raisesEndurance))
-- The mouse claim and the human hypothesis differ only in context, and still differ.
example : N4.claim ≠ H6 := by simp [N4, H6]
-- Same claim in the same context does fuse: the two glucagon sentences (T06, T26).
def glucagonInBlood : Derivation T06.claim := both (.lit T06) (.lit T26)
#eval glucagonInBlood.opinion

/-! ### S2. Mouse to human costs an explicit, weighted transport step -/

def mouseToHuman : Evidence :=
  { pmid := 0, year := 2026, kind := .transport,
    note := "mouse-to-human transfer of a metabolic phenotype (placeholder warrant, 3/10)" }

/-- (4) carried to humans. Context keeps "aged": the result is about aged humans. -/
def enduranceAgedHumans :
    Derivation (.inContext { taxon := some human, stage := some "aged" } raisesEndurance) :=
  transport human (.lit N4) mouseToHuman

-- 7/10 (mouse in vivo) × 3/10 (transport) = 21/100.
example : enduranceAgedHumans.opinion.belief = 21 / 100 := by decide +kernel
theorem endurance_aged_humans_not_established :
    ¬ (4/5 ≤ enduranceAgedHumans.opinion.belief) := by decide +kernel
-- The warrant is listed as an axiom alongside Das 2018.
example : enduranceAgedHumans.pmids = [29570999, 0] := by decide +kernel
-- (6) itself, "in humans" without "aged", is wider than what transport gives: dropping "aged" is
-- generalisation, so H6 is not reachable from (4) at all.
#check_failure (specialise { taxon := some human } enduranceAgedHumans : Derivation H6)
-- Transport without a `.transport` warrant is refused.
#check_failure (transport human (.lit N4) { pmid := 33888596, year := 2021, kind := .rct })
-- Transport upward (mouse to Mammalia) is generalisation, refused.
#check_failure (transport mammalia (.lit N4) mouseToHuman)
-- Specialising mouse to human is refused: human is not is_a mouse.
#check_failure (specialise { taxon := some human, stage := some "aged" } (.lit N4))

/-! ### S3. Specialisation is free -/

/-- Chromosomes in nuclei, eukaryotes (T22), gives mouse with no new evidence. -/
def chromosomeNucleusMouse :
    Derivation (.inContext { taxon := some mouse } (.rel .locatedIn chromosome nucleus)) :=
  specialise _ (.lit T22)

example : chromosomeNucleusMouse.opinion = (Derivation.lit T22).opinion := rfl
theorem chromosome_nucleus_mouse :
    Established (.inContext { taxon := some mouse } (.rel .locatedIn chromosome nucleus)) (4/5) :=
  ⟨chromosomeNucleusMouse, by decide +kernel⟩
-- Several fields at once: mouse, liver.
example : Derivation (.inContext { taxon := some mouse, anatomy := some liver } (.rel .locatedIn chromosome nucleus)) :=
  specialise _ (.lit T22)
-- A `some` claim does not specialise: "telomerase is active in some cancer cells" (T16).
#check_failure (specialise { cellType := some malignantCell, anatomy := some liver } (.lit T16))
-- A bare universal enters any context free: textbook "NAD+ ..." style claims can meet mouse data.
example : Derivation (.inContext { taxon := some mouse, anatomy := some liver } makesATP) :=
  contextualise _ (.lit (tbS "x" "ATP synthase makes ATP" makesATP))
-- Bare-claim rules never see context claims: (1) cannot enter viaAmount.
#check_failure (viaAmount (.lit N1) (.lit (tbS "y" "NAD+ raises sirtuin activity" (.effect NADp .pos (.process locomotion)))))

/-! ### S4. Thylakoid + mitochondrion to "a membrane" is not free -/

def acrossMembrane : Claim := .inContext { component := some membrane } makesATP

-- Widening the component (thylakoid membrane to membrane) is not specialisation.
#check_failure (specialise { component := some membrane } (.lit C7) : Derivation acrossMembrane)
#check_failure (specialise { component := some membrane } (.lit C8) : Derivation acrossMembrane)
-- Even keeping taxon and condition, widening only the component is refused.
def c7Wide : Context :=
  { taxon := some spinach, component := some membrane, condition := some "in vitro, acid-base transition in the dark" }
#check_failure (specialise c7Wide (.lit C7))
-- The two do not fuse into one opinion either.
#check_failure (both (.lit C7) (.lit C8))
-- Transport moves the taxon only: spinach to rat keeps "thylakoid membrane".
def c7Rat : Context :=
  { taxon := some rat, component := some thylakoidMembrane, condition := some "in vitro, acid-base transition in the dark" }
example : Derivation (.inContext c7Rat makesATP) :=
  transport rat (.lit C7) { mouseToHuman with note := "plant to mammal, placeholder" }

/-! ### S5. Hypotonic swelling and hypertonic shrinking neither fuse nor clash -/

def increasedVolume : Entity .phenotype := ⟨"PATO:0000595", "increased volume"⟩
def decreasedVolume : Entity .phenotype := ⟨"PATO:0000596", "decreased volume"⟩

def Swell : Statement := tbS "osmosis-swell" "cells in a hypotonic solution swell"
  (.inContext { cellType := some cell, condition := some "hypotonic solution" } (.rel hasQuality cell increasedVolume))
def Shrink : Statement := tbS "osmosis-shrink" "cells in a hypertonic solution shrink"
  (.inContext { cellType := some cell, condition := some "hypertonic solution" } (.rel hasQuality cell decreasedVolume))

#check_failure (both (.lit Swell) (.lit Shrink))
-- Neither condition specialises to the other.
#check_failure (specialise { cellType := some cell, condition := some "hypertonic solution" } (.lit Swell))
-- `clash` takes bare `rel` / `notRel` claims, so contextual claims cannot be set against each other.
#check_failure (clash (.lit Swell) (.lit Shrink))

-- Reports
#eval IO.println enduranceAgedHumans.report
#eval IO.println chromosomeNucleusMouse.report

end BioLean.ContextEx
