import BioLean.Derivation

/-!
# Context (M2): worked examples and soundness tests

Context lives on the entity (`BioLean/Context.lean`). `e.inCtx c` refines `e` by the fields of
`c` in a fixed order with fixed RO relations: a mouse hepatocyte is `hepatocyte ⊓ in_taxon Mus
musculus`. Taxon refines the subject (the agent of an effect), where is_a inheritance is sound; an
anatomical site refines whichever entity the sentence locates ("blood glucose" refines glucose).
Organism state (disease, age, diet) refines the taxon filler, not the drug. Dose, duration, strain,
system and the experiment's taxon go on `Evidence`.

Ported from the refinement prototype (`docs/m2/refinement.md`), hardened as in
`docs/m2/judgement.md` §6. CURIEs marked `-- unverified` were not checked against a local
ontology; `BLN:` marks a placeholder for a condition no ontology names.
-/

namespace BioLean.ContextExamples
open Rel Derivation Taxa

/-! ## Vocabulary -/

-- RO relations used only here
def hasParticipant : Rel := ⟨.ro, 57, false⟩
def hasQuality     : Rel := ⟨.ro, 86, false⟩
def developsFrom   : Rel := ⟨.ro, 2202, false⟩
def adjacentTo     : Rel := ⟨.ro, 2220, false⟩

-- Taxa used only here (known to `Taxa` through the imported NCBITaxon closure)
def ecoli    : Entity .taxon := ⟨"NCBITaxon:562", "Escherichia coli"⟩
def cow      : Entity .taxon := ⟨"NCBITaxon:9913", "Bos taurus"⟩
def halobact : Entity .taxon := ⟨"NCBITaxon:2242", "Halobacterium salinarum"⟩  -- unverified

-- Anatomy, cells, components
def blood      : Entity .anatomy := ⟨"UBERON:0000178", "blood"⟩
def liver      : Entity .anatomy := ⟨"UBERON:0002107", "liver"⟩
def adipose    : Entity .anatomy := ⟨"UBERON:0001013", "adipose tissue"⟩
def atrium     : Entity .anatomy := ⟨"UBERON:0002081", "cardiac atrium"⟩
def leaf       : Entity .anatomy := ⟨"PO:0025034", "leaf"⟩   -- PO, not UBERON; Kind.anatomy
def bronchus   : Entity .anatomy := ⟨"UBERON:0002185", "bronchus"⟩
def hippocampus : Entity .anatomy := ⟨"UBERON:0002421", "hippocampal formation"⟩
def respSystem : Entity .anatomy := ⟨"UBERON:0001004", "respiratory system"⟩
def pns        : Entity .anatomy := ⟨"UBERON:0000010", "peripheral nervous system"⟩
def nerve      : Entity .anatomy := ⟨"UBERON:0001021", "nerve"⟩
def sns        : Entity .anatomy := ⟨"UBERON:0000013", "sympathetic nervous system"⟩
def skMuscle   : Entity .anatomy := ⟨"UBERON:0001134", "skeletal muscle tissue"⟩
def cell       : Entity .cellType := ⟨"CL:0000000", "cell"⟩
def erythrocyte : Entity .cellType := ⟨"CL:0000232", "erythrocyte"⟩
def malignantCell : Entity .cellType := ⟨"CL:0001064", "malignant cell"⟩
def cardiomyocyte : Entity .cellType := ⟨"CL:0000746", "cardiac muscle cell"⟩
def gamete     : Entity .cellType := ⟨"CL:0000300", "gamete"⟩
def germCell   : Entity .cellType := ⟨"CL:0000586", "germ cell"⟩
def telomerase : Entity .component := ⟨"GO:0005697", "telomerase holoenzyme complex"⟩
def cytoskeleton : Entity .component := ⟨"GO:0005856", "cytoskeleton"⟩
def plantCellWall : Entity .component := ⟨"GO:0009505", "plant-type cell wall"⟩
def plasmaMembrane : Entity .component := ⟨"GO:0005886", "plasma membrane"⟩
def microvillus : Entity .component := ⟨"GO:0005902", "microvillus"⟩
def chromosome : Entity .component := ⟨"GO:0005694", "chromosome"⟩
def nucleus    : Entity .component := ⟨"GO:0005634", "nucleus"⟩
def nucleoid   : Entity .component := ⟨"GO:0009295", "nucleoid"⟩
def cleavageFurrow : Entity .component := ⟨"GO:0032154", "cleavage furrow"⟩
def lysosome   : Entity .component := ⟨"GO:0005764", "lysosome"⟩
def golgi      : Entity .component := ⟨"GO:0005794", "Golgi apparatus"⟩
def cytoplasm  : Entity .component := ⟨"GO:0005737", "cytoplasm"⟩
def membrane   : Entity .component := ⟨"GO:0016020", "membrane"⟩
def thylakoidMembrane : Entity .component := ⟨"GO:0042651", "thylakoid membrane"⟩
def mitoInnerMembrane : Entity .component := ⟨"GO:0005743", "mitochondrial inner membrane"⟩
def atpSynthase : Entity .component := ⟨"GO:0045259", "proton-transporting ATP synthase complex"⟩

-- Chemicals and proteins
def water      : Entity .chemical := ⟨"CHEBI:15377", "water"⟩
def oxygen     : Entity .chemical := ⟨"CHEBI:15379", "dioxygen"⟩
def glucose    : Entity .chemical := ⟨"CHEBI:17234", "glucose"⟩
def potassium  : Entity .chemical := ⟨"CHEBI:29103", "potassium(1+)"⟩
def sodium     : Entity .chemical := ⟨"CHEBI:29101", "sodium(1+)"⟩
def aldosterone : Entity .chemical := ⟨"CHEBI:27584", "aldosterone"⟩
def adrenaline : Entity .chemical := ⟨"CHEBI:33568", "adrenaline"⟩
def drug       : Entity .chemical := ⟨"CHEBI:23888", "drug"⟩
def carbohydrate : Entity .chemical := ⟨"CHEBI:16646", "carbohydrate"⟩
def lactose    : Entity .chemical := ⟨"CHEBI:17716", "lactose"⟩
def antidepressant : Entity .chemical := ⟨"CHEBI:35469", "antidepressant"⟩
def geneticMaterial : Entity .chemical := ⟨"SO:0001026", "genome"⟩  -- SO term as Kind.chemical
def solution   : Entity .chemical := ⟨"CHEBI:75958", "solution"⟩
def nmn        : Entity .chemical := ⟨"CHEBI:16171", "NMN"⟩       -- NMN zwitterion; CHEBI:50383 is the parent
def nad        : Entity .chemical := ⟨"CHEBI:15846", "NAD(+)"⟩
def atp        : Entity .chemical := ⟨"CHEBI:30616", "ATP(4-)"⟩
def glucagon   : Entity .protein := ⟨"PR:P01275", "glucagon"⟩
def insulin    : Entity .protein := ⟨"PR:000009054", "insulin"⟩     -- unverified
def anp        : Entity .protein := ⟨"PR:P01160", "atrial natriuretic peptide"⟩  -- unverified
def ftsZ       : Entity .protein := ⟨"PR:000022726", "FtsZ"⟩       -- unverified
def bacteriorhodopsin : Entity .protein := ⟨"UniProtKB:P02945", "bacteriorhodopsin"⟩  -- unverified

-- Processes
def importIntoCell : Entity .process := ⟨"GO:0098657", "import into cell"⟩
def lipidCatabolism : Entity .process := ⟨"GO:0016042", "lipid catabolic process"⟩
def cardiacConduction : Entity .process := ⟨"GO:0061337", "cardiac conduction"⟩
def cardiacContraction : Entity .process := ⟨"GO:0060048", "cardiac muscle contraction"⟩
def stomatalClosure : Entity .process := ⟨"GO:0090332", "stomatal closure"⟩
def intestinalAbsorption : Entity .process := ⟨"GO:0050892", "intestinal absorption"⟩
def binaryFission : Entity .process := ⟨"GO:0043093", "FtsZ-dependent cytokinesis"⟩
def cellDivision : Entity .process := ⟨"GO:0051301", "cell division"⟩
def ner        : Entity .process := ⟨"GO:0006289", "nucleotide-excision repair"⟩
def telomereMaintenance : Entity .process := ⟨"GO:0000723", "telomere maintenance"⟩
def lacticFermentation : Entity .process := ⟨"GO:0019661", "homolactic fermentation"⟩  -- obsolete in GO
def nuclearReassembly : Entity .process := ⟨"GO:0031468", "nuclear membrane reassembly"⟩
def telophaseI : Entity .process := ⟨"GO:0007134", "meiotic telophase I"⟩
def gasExchange : Entity .process := ⟨"GO:0007585", "respiratory gaseous exchange by respiratory system"⟩
def meiosis    : Entity .process := ⟨"GO:0051321", "meiotic cell cycle"⟩
def sexualReproduction : Entity .process := ⟨"GO:0019953", "sexual reproduction"⟩
def photosynthesis : Entity .process := ⟨"GO:0015979", "photosynthesis"⟩
def smRelaxation : Entity .process := ⟨"GO:0044557", "relaxation of smooth muscle"⟩
def cytokinesis : Entity .process := ⟨"GO:0000910", "cytokinesis"⟩
def chromCondensation : Entity .process := ⟨"GO:0030261", "chromosome condensation"⟩
def prophaseII : Entity .process := ⟨"GO:0007136", "meiotic prophase II"⟩
def glycolysis : Entity .process := ⟨"GO:0006096", "glycolytic process"⟩
def digestion  : Entity .process := ⟨"GO:0007586", "digestion"⟩
def lactoseCatabolism : Entity .process := ⟨"GO:0005990", "lactose catabolic process"⟩
def polysaccharideSynthesis : Entity .process := ⟨"GO:0000271", "polysaccharide biosynthetic process"⟩
def transcription : Entity .process := ⟨"GO:0006351", "DNA-templated transcription"⟩
def neurogenesis : Entity .process := ⟨"GO:0022008", "neurogenesis"⟩
def g2Checkpoint : Entity .process := ⟨"GO:0007095", "mitotic G2 DNA damage checkpoint signaling"⟩
def g2mTransition : Entity .process := ⟨"GO:0000086", "G2/M transition of mitotic cell cycle"⟩
def locomotion : Entity .process := ⟨"GO:0040011", "locomotion"⟩   -- proxy for endurance; MP has no checked term here
def pmfAtpSynthesis : Entity .process := ⟨"GO:0015986", "proton motive force-driven ATP synthesis"⟩

-- Phenotypes, qualities, diseases, conditions
def skinNeoplasm : Entity .phenotype := ⟨"HP:0008069", "Neoplasm of the skin"⟩
def pain       : Entity .phenotype := ⟨"HP:0012531", "Pain"⟩
def triploid   : Entity .phenotype := ⟨"PATO:0001381", "triploid"⟩
def sterile    : Entity .phenotype := ⟨"PATO:0000956", "sterile"⟩
def diploid    : Entity .phenotype := ⟨"PATO:0001394", "diploid"⟩
def swollen    : Entity .phenotype := ⟨"PATO:0001851", "swollen"⟩
def shriveled  : Entity .phenotype := ⟨"PATO:0002460", "shriveled"⟩
def lowOsmolarity : Entity .phenotype := ⟨"PATO:0001656", "decreased osmolarity"⟩
def highOsmolarity : Entity .phenotype := ⟨"PATO:0001657", "increased osmolarity"⟩
def female     : Entity .phenotype := ⟨"PATO:0000383", "female"⟩
def igt        : Entity .phenotype := ⟨"HP:0040270", "Impaired glucose tolerance"⟩
def insulinResistance : Entity .phenotype := ⟨"HP:0000855", "Insulin resistance"⟩
def lowActivity : Entity .phenotype := ⟨"HP:6000023", "Lack of sufficient daily physical activity"⟩
def celiac     : Entity .disease := ⟨"MONDO:0005130", "celiac disease"⟩
def ra         : Entity .disease := ⟨"MONDO:0008383", "rheumatoid arthritis"⟩
def prediabetes : Entity .disease := ⟨"MONDO:0006920", "prediabetes syndrome"⟩
def aged       : Entity .phenotype := ⟨"BLN:aged", "aged"⟩                      -- no ontology id
def postmenopausal : Entity .phenotype := ⟨"BLN:postmenopausal", "postmenopausal"⟩
def highFatDiet : Entity .phenotype := ⟨"BLN:high_fat_diet", "high-fat diet"⟩   -- ECTO/XCO term exists, unchecked
def unmetConditions : Entity .phenotype := ⟨"BLN:checkpoint_conditions_unmet", "checkpoint conditions not met"⟩
def decondensedTelI : Entity .phenotype := ⟨"BLN:decondensed_in_telophase_I", "decondensed in telophase I"⟩
def unicellular : Entity .phenotype := ⟨"BLN:unicellular", "unicellular"⟩

-- Class expressions (not context): a solution with a quality
def hypotonicSolution  := solution.refine hasQuality lowOsmolarity
def hypertonicSolution := solution.refine hasQuality highOsmolarity
def cellInHypotonic    := cell.inCtx { condition := some (.environment hypotonicSolution) }
def cellInHypertonic   := cell.inCtx { condition := some (.environment hypertonicSolution) }

/-- A textbook sentence (OpenStax, no PMID). -/
def tb (id text : String) (c : Claim) : Statement :=
  { id, text, claim := c, evidence := [{ pmid := 0, year := 2013, kind := .textbook, note := text }] }

/-- An ontology axiom. -/
def ax (id text : String) (c : Claim) : Statement :=
  { id, text, claim := c, evidence := [{ pmid := 0, year := 2026, kind := .ontologyAxiom, note := text }] }

/-! ## Textbook claims that need context (`data/m2/context_claims.json`, sample40)

38 of the 40 port. T31 and T40 are preconditions (a conditional claim, later milestone); the
prototype forced them onto a process with `has_modifier`, which the domain check now rejects
(see the end of this section). -/

def T01 := tb "molbio-m45475-69" "Telomerase is present in human cells"
  (.rel locatedIn (telomerase.inCtx { taxon := human }) cell)
def T02 := tb "the-body-s-systems-m45537-183" "Epinephrine accelerates breakdown of stored fat in adipose tissue"
  (.effect adrenaline .pos (.process (lipidCatabolism.inCtx { anatomy := adipose })))
def T03 := tb "the-body-s-systems-m45536-190" "The electrochemical signal causes the two atria to contract"
  (.effect cardiacConduction .pos (.process (cardiacContraction.inCtx { anatomy := atrium })))
def T04 := tb "cell-structure-and-function-m45434-70" "In a hypotonic solution water enters the cell"
  (.rel hasParticipant (importIntoCell.inCtx { cellType := cellInHypotonic }) water)
def T05 := tb "photosynthesis-m45448-120" "Stomatal closure raises oxygen levels inside the leaf"
  (.effect stomatalClosure .pos (.amount (oxygen.inCtx { anatomy := leaf })))
def T06 := tb "the-body-s-systems-m45537-201" "Glucagon causes release of glucose from the liver into the blood"
  (.effect glucagon .pos (.amount (glucose.inCtx { anatomy := blood })))
def T07 := tb "reproduction-at-the-cellular-level-m45463-67" "FtsZ is a component of the prokaryotic cytoskeleton"
  (.rel partOf (ftsZ.inCtx { taxon := bacteria }) cytoskeleton)
def T08 := tb "the-body-s-systems-m45537-334" "Increasing blood glucose causes the pancreas to release insulin"
  (.effect (glucose.inCtx { anatomy := blood }) .pos (.amount insulin))
def T09 := tb "the-body-s-systems-m45537-156" "An increase in blood potassium stimulates aldosterone release"
  (.effect (potassium.inCtx { anatomy := blood }) .pos (.amount aldosterone))
def T10 := tb "cell-structure-and-function-m45432-219" "The plant cell wall is external to the plasma membrane"
  (.rel adjacentTo (plantCellWall.inCtx { taxon := viridiplantae }) plasmaMembrane)
def T11 := tb "the-body-s-systems-m45537-229" "The atrial hormone reduces blood Na+ concentration"
  (.effect anp .neg (.amount (sodium.inCtx { anatomy := blood })))
-- the judge's way: celiac disease is a state of the patient, so it refines the taxon filler
def T12 := tb "cell-structure-and-function-m45432-25" "Loss of microvilli prevents nutrient absorption in celiac patients"
  (.effect (microvillus.inCtx { taxon := human, condition := some (.organism celiac) }) .pos
    (.process intestinalAbsorption))
def T13 := tb "reproduction-at-the-cellular-level-m45463-66" "Binary fission is the process of prokaryotic cell division"
  (.rel isA (binaryFission.inCtx { taxon := bacteria }) cellDivision)
-- "early in life" (onset) is not expressed: no slot for onset.
def T14 := tb "molbio-m45475-117" "People with defective NER genes develop skin cancers early in life"
  (.effect (ner.inCtx { taxon := human }) .neg (.phenotype skinNeoplasm))
def T15 := tb "the-body-s-systems-m45537-53" "Insulin decreases blood-glucose levels"
  (.effect insulin .neg (.amount (glucose.inCtx { anatomy := blood })))
def T16 := tb "molbio-m45475-67" "Telomerase is active in some cancer cells"
  (.quant .some (.rel capableOf (telomerase.inCtx { cellType := malignantCell }) telomereMaintenance))
def T17 := tb "how-cells-obtain-energy-m45440-11" "Lactic acid fermentation occurs routinely in mammalian red blood cells"
  (.rel occursIn (lacticFermentation.inCtx { taxon := mammalia }) erythrocyte)
-- context {} in the data; "some organisms" is a quantifier, not context
def T18 := tb "the-cellular-basis-of-inheritance-m45466-103" "In some organisms nuclear envelopes form in telophase I"
  (.quant .some (.rel happensDuring nuclearReassembly telophaseI))
def T19 := tb "the-body-s-systems-m45536-175" "Animal respiratory systems facilitate gas exchange"
  (.rel capableOf (respSystem.inCtx { taxon := metazoa }) gasExchange)
def T20 := tb "the-body-s-systems-m45536-212" "An electrical signal triggers atrial cardiac muscle cells to contract"
  (.effect cardiacConduction .pos
    (.process (cardiacContraction.inCtx { anatomy := atrium, cellType := cardiomyocyte })))
-- "only" (exclusivity) is not expressed
def T21 := tb "the-cellular-basis-of-inheritance-m45466-165" "In animals, meiotic cells participate only in sexual reproduction"
  (.rel partOf (meiosis.inCtx { taxon := metazoa }) sexualReproduction)
def T22 := tb "reproduction-at-the-cellular-level-m45455-16" "Chromosomes are located in the nucleus of eukaryotic cells"
  (.rel locatedIn (chromosome.inCtx { taxon := eukaryota }) nucleus)
-- the judge's way: the condition belongs to the patient, not the drug
def T23 := tb "the-body-s-systems-m45538-197" "Medications relieve pain in rheumatoid arthritis"
  (.effect (drug.inCtx { taxon := human, condition := some (.organism ra) }) .neg (.phenotype pain))
def T24 := tb "how-cells-obtain-energy-m45437-11" "Photosynthesizing organisms (plants) produce sugars"
  (.rel hasOutput (photosynthesis.inCtx { taxon := viridiplantae }) carbohydrate)
def T25 := tb "the-cellular-basis-of-inheritance-m45465-68" "Gametes are produced from diploid germ cells"
  (.rel developsFrom (gamete.inCtx { taxon := metazoa }) (germCell.refine hasQuality diploid))
def T26 := tb "the-body-s-systems-m45537-337" "Glucagon stimulates release of stored glucose from the liver into the bloodstream"
  (.effect glucagon .pos (.amount (glucose.inCtx { anatomy := blood })))
def T27 := tb "the-body-s-systems-m45539-28" "The vertebrate PNS is made up of peripheral sensory and motor nerves"
  (.rel hasPart (pns.inCtx { taxon := vertebrata }) nerve)
def T28 := tb "the-body-s-systems-m45536-61" "Sympathetic input causes bronchial muscle relaxation"
  (.effect sns .pos (.process (smRelaxation.inCtx { anatomy := bronchus })))
def T29 := tb "reproduction-at-the-cellular-level-m45455-9" "The nucleoid is the region of a prokaryotic cell containing the genome"
  (.rel locatedIn (geneticMaterial.inCtx { taxon := bacteria }) nucleoid)
-- "and some fungi" would be a second statement, `.quant .some` over Fungi
def T30 := tb "the-cellular-basis-of-inheritance-m45466-106" "In animals cytokinesis separates cell contents by a cleavage furrow"
  (.rel hasPart (cytokinesis.inCtx { taxon := metazoa }) cleavageFurrow)
-- "only" (glycolysis and nothing else) is not expressed
def T32 := tb "how-cells-obtain-energy-m45438-42" "Mature mammalian red blood cells are capable only of glycolysis"
  (.rel capableOf (erythrocyte.inCtx { taxon := mammalia }) glycolysis)
def T33 := tb "the-cellular-basis-of-inheritance-m45467-83" "Triploid animals are sterile"
  (.effect (triploid.inCtx { taxon := metazoa }) .pos (.phenotype sterile))
-- "single-celled" is a state of the organism: it refines the taxon filler
def T34 := tb "cell-structure-and-function-m45432-162" "In single-celled eukaryotes, lysosomes digest ingested food"
  (.rel capableOf (lysosome.inCtx { taxon := eukaryota, condition := some (.organism unicellular) }) digestion)
def T35 := tb "molbio-m45480-30" "Lactose is a food source for E. coli"
  (.rel hasInput (lactoseCatabolism.inCtx { taxon := ecoli }) lactose)
def T36 := tb "cell-structure-and-function-m45432-158" "In plant cells, the Golgi synthesises polysaccharides"
  (.rel capableOf (golgi.inCtx { taxon := viridiplantae }) polysaccharideSynthesis)
-- data says cellType CL:0000520; "in prokaryotes" read as the taxon, as elsewhere
def T37 := tb "molbio-m45476-20" "In prokaryotes transcription occurs in the cytoplasm"
  (.rel occursIn (transcription.inCtx { taxon := bacteria }) cytoplasm)
def T38 := tb "the-body-s-systems-m45539-132" "Some antidepressant medications promote neurogenesis in the hippocampus"
  (.quant .some (.effect antidepressant .pos (.process (neurogenesis.inCtx { anatomy := hippocampus }))))
def T39 := tb "the-body-s-systems-m45537-336" "Decreasing blood glucose causes the pancreas to release glucagon"
  (.effect (glucose.inCtx { anatomy := blood }) .neg (.amount glucagon))

def sample40 : List Statement :=
  [T01, T02, T03, T04, T05, T06, T07, T08, T09, T10, T11, T12, T13, T14, T15, T16, T17, T18, T19, T20,
   T21, T22, T23, T24, T25, T26, T27, T28, T29, T30, T32, T33, T34, T35, T36, T37, T38, T39]

example : sample40.length = 38 := rfl

-- T31 and T40, as the prototype forced them: `has_modifier` has domain continuant, so a process
-- cannot carry it. These are preconditions, not context.
#check_failure chromCondensation.refine hasModifier decondensedTelI
#check_failure g2Checkpoint.refine hasModifier unmetConditions

/-! ## NMN (case study 3) -/

def nmnInMouse     := nmn.inCtx { taxon := mouse }
def nmnInAgedMouse := nmn.inCtx { taxon := mouse, condition := some (.organism aged) }
def nmnInHfdMouse  := nmn.inCtx { taxon := mouse, condition := some (.organism highFatDiet) }
def nmnInHuman     := nmn.inCtx { taxon := human }
def nmnInAgedHuman := nmn.inCtx { taxon := human, condition := some (.organism aged) }
/-- One `Ctx` holds one organism state; the further states of "prediabetic postmenopausal women"
pre-refine the taxon filler. Such a refined taxon is not in `Taxa`, so it cannot be transported. -/
def prediabeticWoman : Ctx :=
  { taxon := (human.refine hasQuality female).refine hasModifier postmenopausal,
    condition := some (.organism prediabetes) }

def N1 : Statement where
  id := "NMN-1"; text := "NMN raises NAD+ in mouse liver"
  claim := .effect nmnInMouse .pos (.amount (nad.inCtx { anatomy := liver }))
  evidence := [{ pmid := 21982712, year := 2011, kind := .mechanistic, system := some .inVivo,
                 taxon := some mouse, dose := some "500 mg/kg i.p.", note := "Yoshino 2011" }]
def N2 : Statement where
  id := "NMN-2"; text := "NMN reduces impaired glucose tolerance in high-fat-diet mice"
  claim := .effect nmnInHfdMouse .neg (.phenotype igt)
  evidence := [{ pmid := 21982712, year := 2011, kind := .mechanistic, system := some .inVivo,
                 taxon := some mouse, strain := some "C57BL/6", note := "Yoshino 2011" }]
def N3 : Statement where
  id := "NMN-3"; text := "Long-term NMN reduces age-associated decline in physical activity in mice"
  claim := .effect nmnInAgedMouse .neg (.phenotype lowActivity)
  evidence := [{ pmid := 28068222, year := 2016, kind := .mechanistic, system := some .inVivo,
                 taxon := some mouse, strain := some "C57BL/6N", dose := some "100 or 300 mg/kg/day oral",
                 duration := some "12 months", note := "Mills 2016" }]
def N4 : Statement where
  id := "NMN-4"; text := "NMN increases endurance in aged mice"
  claim := .effect nmnInAgedMouse .pos (.process locomotion)
  evidence := [{ pmid := 29570999, year := 2018, kind := .mechanistic, system := some .inVivo,
                 taxon := some mouse, dose := some "400 mg/kg/day in drinking water", note := "Das 2018" }]
def N5 : Statement where
  id := "NMN-5"; text := "NMN increases muscle insulin sensitivity in prediabetic postmenopausal women"
  claim := .effect (nmn.inCtx prediabeticWoman) .neg
    (.phenotype (insulinResistance.inCtx { anatomy := skMuscle }))
  evidence := [{ pmid := 33888596, year := 2021, kind := .rct, system := some .inVivo,
                 taxon := some human, dose := some "250 mg/day oral", duration := some "10 weeks",
                 note := "Yoshino 2021" }]
/-- (6), hypothetical: no statement exists for it. -/
def N6claim : Claim := .effect nmnInHuman .pos (.process locomotion)

def nmn5 : List Statement := [N1, N2, N3, N4, N5]
-- every NMN statement passes the taxon lint
#guard nmn5.all Statement.taxonConsistent

/-! ## Chemiosmosis (case study 2) -/

def synthIn (m : Entity .component) := atpSynthase.inCtx { component := m }

def C7 : Statement where
  id := "CHEMI-7"; text := "ATP synthase makes ATP from a proton gradient in thylakoid membranes"
  claim := .rel capableOf (synthIn thylakoidMembrane) pmfAtpSynthesis
  evidence := [{ pmid := 5220864, year := 1966, kind := .inVitro, system := some .inVitro,
                 note := "Jagendorf and Uribe 1966, acid-bath chloroplasts" }]
def C8 : Statement where
  id := "CHEMI-8"; text := "ATP synthase makes ATP from a proton gradient in the mitochondrial inner membrane"
  claim := .rel capableOf (synthIn mitoInnerMembrane) pmfAtpSynthesis
  evidence := [{ pmid := 16742541, year := 1967, kind := .inVitro, system := some .inVitro,
                 note := "Mitchell and Moyle 1967" }]
/-- The chimera: a bovine synthase in a membrane that has halobacterial bacteriorhodopsin as a
part. The membrane is a class expression (`has_part`), the rest is context. -/
def racker : Entity .component :=
  atpSynthase.inCtx
    { taxon := cow, component := membrane.refine hasPart (bacteriorhodopsin.inCtx { taxon := halobact }) }
def C9 : Statement where
  id := "CHEMI-9"; text := "ATP synthase makes ATP from a light-driven proton gradient in reconstituted liposomes"
  claim := .rel capableOf racker pmfAtpSynthesis
  evidence := [{ pmid := 4272126, year := 1974, kind := .inVitro, system := some .reconstituted,
                 note := "Racker and Stoeckenius 1974, liposomes with bacteriorhodopsin" }]

/-! ## S1. Mouse and human evidence do not fuse by accident -/

/-- The subjects differ, so the claims differ. -/
theorem s1_subjects_differ : nmnInMouse ≠ nmnInHuman := by decide
theorem s1_aged_differ : nmnInAgedMouse ≠ nmnInAgedHuman := by decide
/-- "NMN in (aged humans)" is not "(NMN in humans) that is aged": the bracketed filler keeps them apart. -/
theorem s1_no_collision : (nmn.inCtx { taxon := human }).refine hasModifier aged ≠ nmnInAgedHuman := by
  decide

/-- Hypothetical human evidence for (6), to show what an attempted fusion does. -/
def N6human : Statement where
  id := "NMN-6h"; text := "HYPOTHETICAL human trial"; claim := N6claim
  evidence := [{ pmid := 0, year := 2030, kind := .rct, taxon := some human, note := "hypothetical" }]

-- Fusing the aged-mouse endurance result with a human endurance result is a type error.
#check_failure (Derivation.both (.lit N4) (.lit N6human) : Derivation N6claim)
-- Same for the real papers: mouse (2) and human (5) are different claims.
#check_failure (Derivation.both (.lit N2) (.lit N5) : Derivation N5.claim)
-- No rule drops a refinement on the subject: context-free "NMN raises NAD+" from (1) does not type-check.
#check_failure (Derivation.lit N1 : Derivation (.effect nmn .pos (.amount (nad.inCtx { anatomy := liver }))))
-- The shared hole, narrowed by the lint: mouse evidence on a context-free or a human claim.
#guard !(Statement.taxonConsistent { N1 with claim := .effect nmn .pos (.amount nad) })
#guard !(Statement.taxonConsistent { N1 with claim := .effect nmnInHuman .pos (.amount nad) })

/-! ## S2. Mouse to human needs an explicit, weighted transport -/

def crossSpecies : Evidence :=
  { pmid := 0, year := 2026, kind := .crossSpecies,
    note := "mouse-to-human transfer of an exercise phenotype; placeholder weight" }

/-- (4) transported to aged humans: the organism state stays, the taxon moves to a sibling. The
conclusion lists N4 and the transport item as axioms. -/
def s2_transport : Derivation (.effect nmnInAgedHuman .pos (.process locomotion)) :=
  .transport { condition := some (.organism aged) } human (.lit N4) crossSpecies

theorem s2_belief : s2_transport.opinion.belief = 21 / 100 := by decide +kernel
theorem s2_not_established : s2_transport.verdict = .unsupported := by decide +kernel
theorem s2_discounted : s2_transport.opinion.belief ≤ 3 / 10 * (Derivation.lit N4).opinion.belief := by
  decide +kernel
example : s2_transport.axioms.map (·.id) = ["NMN-4", s!"transport:{human.curie}"] := rfl

-- Transport without a `.crossSpecies` item does not elaborate (`hk` fails).
#check_failure (Derivation.transport { condition := some (.organism aged) } human (.lit N4)
  { pmid := 29570999, year := 2018, kind := .mechanistic } : Derivation (.effect nmnInAgedHuman .pos (.process locomotion)))
-- Mouse to Mammalia is a generalisation, not a transport (`hs` fails: mouse is_a Mammalia).
#check_failure (Derivation.transport {} mammalia (.lit N1) crossSpecies)
-- (6) is about humans in general. From aged humans it needs a generalisation (dropping `aged`),
-- which no rule gives: (6) is not derivable from (4) at all in M2.
#check_failure (s2_transport : Derivation N6claim)

/-! ## S3. Specialisation is free -/

def mouseIsEuk := ax "NCBITaxon:10090-lineage" "Mus musculus is_a Eukaryota" (.rel isA mouse eukaryota)

/-- From (22), chromosomes in eukaryotes are in the nucleus, to mouse chromosomes: no new evidence,
only the NCBITaxon lineage and the existing is_a law. -/
def s3_mouse_chromosome : Derivation (.rel locatedIn (chromosome.inCtx { taxon := mouse }) nucleus) :=
  .relChain (.refineMono (.lit mouseIsEuk)) (.lit T22)

theorem s3_free : s3_mouse_chromosome.opinion.belief = (Derivation.lit T22).opinion.belief := by
  decide +kernel

/-- From an unrefined claim to a refined one: the refinement axiom does it. Effects too, via
`isaInheritEffect`: "insulin lowers blood glucose" holds of insulin in mice. Exact, because the
`.definitional` axiom (999/1000) is never the weakest premise here. -/
def s3_effect : Derivation (.effect (insulin.inCtx { taxon := mouse }) .neg (.amount (glucose.inCtx { anatomy := blood }))) :=
  .isaInheritEffect (.lit (insulin.refineAxiom inTaxon mouse)) (.lit T15)

theorem s3_effect_free : s3_effect.opinion.belief = (Derivation.lit T15).opinion.belief := by decide +kernel

/-- Aged humans from humans, the direction opposite to S2's gap. -/
def agedHumanIsHuman : Derivation (.rel isA nmnInAgedHuman nmnInHuman) :=
  .refineMono (.lit (human.refineAxiom hasModifier aged))

/-! ## S4. Generalising thylakoid and mitochondrion to "a membrane" is not free -/

def thylakoidIsMembrane := ax "GO:0042651-isa" "thylakoid membrane is_a membrane" (.rel isA thylakoidMembrane membrane)

/-- The refined thylakoid synthase is a membrane synthase... -/
def s4_isa : Derivation (.rel isA (synthIn thylakoidMembrane) (synthIn membrane)) :=
  .refineMono (.lit thylakoidIsMembrane)

-- ...but the is_a laws push relations down to subclasses, never up. Neither order composes into
-- the general claim, and (7) and (8) cannot be fused because their subjects differ.
#check_failure (Derivation.relChain s4_isa (.lit C7) : Derivation (.rel capableOf (synthIn membrane) pmfAtpSynthesis))
#check_failure (Derivation.relChain (.lit C7) s4_isa : Derivation (.rel capableOf (synthIn membrane) pmfAtpSynthesis))
#check_failure (Derivation.both (.lit C7) (.lit C8))
theorem s4_subjects_differ : synthIn thylakoidMembrane ≠ synthIn mitoInnerMembrane := by decide

/-! ## S5. Conditions: hypotonic swelling and hypertonic shrinking -/

def S5a := tb "cell-structure-and-function-osmosis-a" "Cells in a hypotonic solution swell"
  (.rel hasQuality cellInHypotonic swollen)
def S5b := tb "cell-structure-and-function-osmosis-b" "Cells in a hypertonic solution shrink"
  (.rel hasQuality cellInHypertonic shriveled)

theorem s5_subjects_differ : cellInHypotonic ≠ cellInHypertonic := by decide
-- No fusion, and no clash: `clash` needs `a r b` and `¬(a r b)` with the same a, r, b.
#check_failure (Derivation.both (.lit S5a) (.lit S5b))

-- Reports
#eval IO.println s2_transport.report
#eval IO.println s3_mouse_chromosome.report
#eval IO.println (sample40.map (fun s => s!"{s.id}: {s.claim}") |> String.intercalate "\n")

end BioLean.ContextExamples
