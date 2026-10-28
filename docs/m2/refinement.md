# M2 candidate B: context as entity refinement

Worktree branch `worktree-wf_d542258c-558-2`, on top of `234dbda` (M3). `lake build BioLeanLib`
passes (3155 jobs), including GLP1, Ozempic, Textbook, Quantity, Tests.RO and the new
`BioLean.Examples.Refinement`. Lean files: `docs/m2/refinement-lean/`.

## (a) The design in one paragraph

Context lives on the entity, description-logic style. `Entity.refine e r f` is the class
`e ⊓ ∃r.f`. It has the same `Kind` as `e` and a composite curie,
`CL:0000182&RO:0002162=(NCBITaxon:10090)`. The filler is in brackets so a refined filler (aged mouse)
cannot collide with a second refinement of the subject. Taxon and condition refine the *subject*
(the agent of an effect), because that is the position where is_a inheritance is sound. An
anatomical site refines whatever entity it locates ("blood glucose" is `glucose ⊓ located_in blood`).
Conditions are refinements too: a hypotonic cell is `cell ⊓ surrounded_by (solution ⊓ has_quality
decreased osmolarity)`. `Entity.refineAxiom` emits the statement "refined is_a base" as an
`.ontologyAxiom`, so the existing is_a laws in `relChain` give specialisation. Three new derivation
rules complete it:
- `refineMono`: f is_a g gives e⊓∃r.f is_a e⊓∃r.g, so mouse is_a Eukaryota lifts to the refined
  entities.
- `isaInheritEffect`: the effect half of the is_a laws, already an open item in STATUS.
- `transport`: moves an effect from taxon T₁ to a different taxon T₂. It needs an `Evidence` item of
  the new kind `.crossSpecies` (reliability 3/10) and discounts the opinion by `chain`.

Dose, duration, strain and experimental system (`ExpSystem`: in vivo, ex vivo, in vitro,
reconstituted) are new optional fields on `Evidence`, not on the claim. There is no new `Claim` or
`Target` constructor. Mouse and human claims are different because their subjects are different
entities. No rule climbs a subject's refinement, so generalisation is never free.

## (b) The Lean diff (core, without the example file)

```diff
diff --git a/BioLean/Claim.lean b/BioLean/Claim.lean
index 2410b61..4b15cf6 100644
--- a/BioLean/Claim.lean
+++ b/BioLean/Claim.lean
@@ -90,6 +90,18 @@ instance : ToString Rel := ⟨label⟩
 
 end Rel
 
+/-- Context as refinement (M2): `e.refine r f` is the class `e ⊓ ∃r.f`, description-logic style,
+of the same kind as `e`. "Hepatocyte in mouse" is `hepatocyte.refine .inTaxon mouse`, curie
+`CL:0000182&RO:0002162=(NCBITaxon:10090)`. The filler is bracketed so that a refined filler (aged
+mouse) cannot collide with a second refinement of the subject. Taxon and condition refine the
+subject of a claim (the agent of an effect), the position where the is_a laws make specialisation
+sound; an anatomical site refines the entity it locates. Apply refinements in the order anatomy,
+cell type, condition, taxon (taxon outermost), so one context has one curie; `transport` and
+`refineMono` act on the outermost refinement. -/
+def Entity.refine {k k' : Kind} (e : Entity k) (r : Rel) (f : Entity k') : Entity k where
+  curie := s!"{e.curie}&{r.curie}=({f.curie})"
+  label := s!"{e.label} ⊓ {r} ({f.label})"
+
 /-- How many of a class a sentence is about. A bare claim is universal ("every neuron ...");
 `some` and `most` are weaker. "Some neurons have no axons" does not contradict "most neurons have
 axons"; it would contradict "every neuron has an axon". -/
diff --git a/BioLean/Derivation.lean b/BioLean/Derivation.lean
index 993d7ea..ab8960a 100644
--- a/BioLean/Derivation.lean
+++ b/BioLean/Derivation.lean
@@ -99,6 +99,28 @@ inductive Derivation : Claim → Type
       (ac : Derivation (.notRel r a c h₁)) (bc : Derivation (.rel Rel.isA b c h₂))
       (h₃ : r.accepts k₁ k₂ = true := by decide) :
       Derivation (.notRel r a b h₃)
+  -- Context as refinement (M2). Context lives on the subject entity (`Entity.refine`), so a mouse
+  -- claim and a human claim have different subjects and never fuse. Specialisation is free through
+  -- the is_a laws; generalisation (dropping or widening a context) has no rule.
+  /-- Refinement is monotone in its filler: `f is_a g` gives `(e ⊓ ∃r.f) is_a (e ⊓ ∃r.g)`. Mouse
+  is_a Eukaryota, so a mouse chromosome is a eukaryotic chromosome. Sound for any `r`. -/
+  | refineMono {k k' : Kind} {e : Entity k} {r : Rel} {f g : Entity k'}
+      {h : Rel.isA.accepts k' k' = true}
+      (fg : Derivation (.rel Rel.isA f g h)) (h' : Rel.isA.accepts k k = true := by decide) :
+      Derivation (.rel Rel.isA (e.refine r f) (e.refine r g) h')
+  /-- A subclass of the agent inherits its effect: `a is_a b`, `b →s t` give `a →s t`. The effect
+  half of the is_a laws (STATUS "isaInheritEffect"), needed so that refined agents specialise. -/
+  | isaInheritEffect {k₁ k₂ : Kind} {a : Entity k₁} {b : Entity k₂} {s : Sign} {t : Target}
+      {h : Rel.isA.accepts k₁ k₂ = true}
+      (ab : Derivation (.rel Rel.isA a b h)) (bt : Derivation (.effect b s t)) :
+      Derivation (.effect a s t)
+  /-- Transport an effect from taxon `T₁` to a different taxon `T₂` (mouse to human). Never free:
+  it needs an `Evidence` item of kind `.crossSpecies`, and the opinion is discounted by it
+  (`chain`), so with the standard weight 3/10 the conclusion carries at most 0.3 of the belief. -/
+  | transport {k : Kind} {a : Entity k} {s : Sign} {t : Target} {T₁ : Entity .taxon}
+      (T₂ : Entity .taxon) (d : Derivation (.effect (a.refine Rel.inTaxon T₁) s t)) (e : Evidence)
+      (hk : e.kind = .crossSpecies := by decide) (hne : T₁ ≠ T₂ := by decide) :
+      Derivation (.effect (a.refine Rel.inTaxon T₂) s t)
 
 namespace Derivation
 
@@ -120,6 +142,9 @@ def opinion : {c : Claim} → Derivation c → Opinion
   | _, .netYield m u .. => m.opinion.weakest u.opinion
   | _, .compareIntervals a b .. => a.opinion.weakest b.opinion
   | _, .weaken _ d => d.opinion
+  | _, .refineMono fg .. => fg.opinion
+  | _, .isaInheritEffect ab bt => ab.opinion.weakest bt.opinion
+  | _, .transport _ d e .. => d.opinion.chain e.opinion
 
 /-- The literature statements a derivation rests on, in order of first use. -/
 def axioms : {c : Claim} → Derivation c → List Statement
@@ -137,6 +162,11 @@ def axioms : {c : Claim} → Derivation c → List Statement
   | _, .netYield m u .. => m.axioms ++ u.axioms
   | _, .compareIntervals a b .. => a.axioms ++ b.axioms
   | _, .weaken _ d => d.axioms
+  | _, .refineMono fg .. => fg.axioms
+  | _, .isaInheritEffect ab bt => ab.axioms ++ bt.axioms
+  | _, .transport (a := a) (s := s) (t := t) T₂ d e .. =>
+      d.axioms ++ [{ id := s!"transport:{T₂.curie}", text := e.note,
+                     claim := .effect (a.refine Rel.inTaxon T₂) s t, evidence := [e] }]
 
 /-- Every PMID cited anywhere in the derivation, without repeats. -/
 def pmids {c : Claim} (d : Derivation c) : List Nat :=
@@ -200,6 +230,9 @@ partial def render {c : Claim} (d : Derivation c) (indent : String := "") : Stri
   | .netYield m u .. => node "made − used" [render m (indent ++ "  "), render u (indent ++ "  ")]
   | .compareIntervals a b .. => node "disjoint intervals" [render a (indent ++ "  "), render b (indent ++ "  ")]
   | .weaken q d' => node s!"weaken to {repr q}" [render d' (indent ++ "  ")]
+  | .refineMono fg .. => node "refinement monotone" [render fg (indent ++ "  ")]
+  | .isaInheritEffect ab bt => node "is_a inherits effect" [render ab (indent ++ "  "), render bt (indent ++ "  ")]
+  | .transport T₂ d' e .. => node s!"transport to {T₂.label} (PMID {e.pmid}, {repr e.kind})" [render d' (indent ++ "  ")]
 
 /-- Statements used more than once in a derivation. `fuse` assumes independence, so a
 shared axiom means the strength is over-stated. -/
diff --git a/BioLean/Evidence.lean b/BioLean/Evidence.lean
index 831e470..21e070d 100644
--- a/BioLean/Evidence.lean
+++ b/BioLean/Evidence.lean
@@ -27,15 +27,26 @@ inductive EvidenceKind
   | observational
   | inVitro
   | textMined       -- an automatically extracted relation (PubTator3, INDRA readers)
+  | crossSpecies    -- a judgment that a result transfers between taxa (ECO ISO-like); `transport`
   deriving DecidableEq, Repr
 
-/-- One citation. -/
+/-- The experimental system a result came from. Experiment-level, so it lives on `Evidence`. -/
+inductive ExpSystem
+  | inVivo | exVivo | inVitro | reconstituted
+  deriving DecidableEq, Repr
+
+/-- One citation. Dose, duration, strain and system describe the experiment, not the claim: the
+same claim is tested at many doses, so they never make two claims different. -/
 structure Evidence where
   pmid : Nat
   year : Nat
   kind : EvidenceKind
   polarity : Opinion.Polarity := .supports
   note : String := ""
+  dose : Option String := none
+  duration : Option String := none
+  strain : Option String := none
+  system : Option ExpSystem := none
   deriving Repr
 
 /-- A claim with its evidence: the axiom form of BioLean. -/
@@ -64,6 +75,7 @@ instance EvidenceModel.standard : EvidenceModel where
     | .observational => 1 / 2
     | .inVitro => 1 / 2
     | .textMined => 3 / 10
+    | .crossSpecies => 3 / 10
   nonneg := by intro k; cases k <;> norm_num
   lt_one := by intro k; cases k <;> norm_num
 
@@ -94,4 +106,13 @@ def pmids (s : Statement) : List Nat := s.evidence.map (·.pmid)
 instance : ToString Statement := ⟨fun s => s!"{s.id}: {s.claim}  ({s.evidence.length} refs)"⟩
 
 end Statement
+
+/-- The refinement axiom `e ⊓ ∃r.f ⊑ e`: dropping a context is a subsumption. True by
+definition, recorded as an ontology axiom so the existing is_a laws use it. -/
+def Entity.refineAxiom {k k' : Kind} (e : Entity k) (r : Rel) (f : Entity k')
+    (h : Rel.isA.accepts k k = true := by decide) : Statement where
+  id := s!"refine:{(e.refine r f).curie}"
+  text := s!"{(e.refine r f).label} is_a {e.label}"
+  claim := .rel Rel.isA (e.refine r f) e h
+  evidence := [{ pmid := 0, year := 0, kind := .ontologyAxiom, note := "C ⊓ ∃r.F ⊑ C" }]
 end BioLean
diff --git a/BioLean/Rel.lean b/BioLean/Rel.lean
index 008f20d..ab2e47b 100644
--- a/BioLean/Rel.lean
+++ b/BioLean/Rel.lean
@@ -42,6 +42,8 @@ def enables    : Rel := ⟨.ro, 2327, false⟩
 def involvedIn : Rel := ⟨.ro, 2331, false⟩
 def produces   : Rel := ⟨.ro, 3000, false⟩
 def overlaps   : Rel := ⟨.ro, 2131, false⟩
+def inTaxon    : Rel := ⟨.ro, 2162, false⟩
+def hasModifier : Rel := ⟨.ro, 2573, false⟩
 /-- rdfs:subClassOf, which is not an RO property but behaves as a transitive relation here. -/
 def isA        : Rel := ⟨.rdfs, 0, false⟩
 
diff --git a/lakefile.toml b/lakefile.toml
index 8308840..a362764 100644
--- a/lakefile.toml
+++ b/lakefile.toml
@@ -16,7 +16,7 @@ name = "BioLean"
 
 [[lean_lib]]
 name = "BioLeanLib"
-roots = ["BioLean.Lib.GLP1", "BioLean.Examples.Ozempic", "BioLean.Lib.Textbook", "BioLean.Examples.Textbook", "BioLean.Examples.Quantity", "BioLean.Tests.RO"]
+roots = ["BioLean.Lib.GLP1", "BioLean.Examples.Ozempic", "BioLean.Lib.Textbook", "BioLean.Examples.Textbook", "BioLean.Examples.Quantity", "BioLean.Examples.Refinement", "BioLean.Tests.RO"]
 
 [[lean_lib]]
 name = "TextbookR2"
```

## (c) The 40 + 9 encodings, and the tests (`BioLean/Examples/Refinement.lean`, complete)

```lean
import BioLean.Derivation

/-!
# Context as entity refinement (M2, design B)

Context lives on the entity. `e.refine r f` is the description-logic class `e ⊓ ∃r.f`: a mouse
hepatocyte is `hepatocyte ⊓ in_taxon Mus musculus`, an entity of the same kind with a composite
curie. Taxon and condition refine the subject (the agent of an effect); an anatomical site refines
whichever entity the sentence locates ("blood glucose" refines glucose). Dose, duration, strain and
in vitro go on `Evidence`.

Rules used: the existing is_a laws (`relChain`), plus `refineMono` (refinement is monotone in its
filler), `isaInheritEffect` (a subclass of an agent inherits its effect) and `transport` (taxon to
taxon, needs a `.crossSpecies` evidence item, reliability 3/10).

CURIEs marked `-- unverified` were not checked against a local ontology; `BLN:` marks a placeholder
for a condition no ontology names.
-/

namespace BioLean.Refinement
open Rel Derivation

/-! ## Vocabulary -/

-- RO relations used only here
def hasParticipant : Rel := ⟨.ro, 57, false⟩
def hasQuality     : Rel := ⟨.ro, 86, false⟩
def happensDuring  : Rel := ⟨.ro, 2092, false⟩
def developsFrom   : Rel := ⟨.ro, 2202, false⟩
def surroundedBy   : Rel := ⟨.ro, 2219, false⟩
def adjacentTo     : Rel := ⟨.ro, 2220, false⟩

-- Taxa
def eukaryota  : Entity .taxon := ⟨"NCBITaxon:2759", "Eukaryota"⟩
def bacteria   : Entity .taxon := ⟨"NCBITaxon:2", "Bacteria"⟩   -- sample has NCIT:C14263 prokaryote once
def plants     : Entity .taxon := ⟨"NCBITaxon:33090", "Viridiplantae"⟩
def metazoa    : Entity .taxon := ⟨"NCBITaxon:33208", "Metazoa"⟩
def vertebrata : Entity .taxon := ⟨"NCBITaxon:7742", "Vertebrata"⟩
def mammalia   : Entity .taxon := ⟨"NCBITaxon:40674", "Mammalia"⟩
def mouse      : Entity .taxon := ⟨"NCBITaxon:10090", "Mus musculus"⟩
def human      : Entity .taxon := ⟨"NCBITaxon:9606", "Homo sapiens"⟩
def ecoli      : Entity .taxon := ⟨"NCBITaxon:562", "Escherichia coli"⟩
def cow        : Entity .taxon := ⟨"NCBITaxon:9913", "Bos taurus"⟩
def halobact   : Entity .taxon := ⟨"NCBITaxon:2242", "Halobacterium salinarum"⟩  -- unverified

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

-- Contexts built by refinement
def hypotonicSolution  := solution.refine hasQuality lowOsmolarity
def hypertonicSolution := solution.refine hasQuality highOsmolarity
def cellInHypotonic    := cell.refine surroundedBy hypotonicSolution
def cellInHypertonic   := cell.refine surroundedBy hypertonicSolution
def agedMouse : Entity .taxon := mouse.refine hasModifier aged
def agedHuman : Entity .taxon := human.refine hasModifier aged
def hfdMouse  : Entity .taxon := mouse.refine hasModifier highFatDiet
def prediabeticWoman : Entity .taxon :=
  ((human.refine hasQuality female).refine hasModifier postmenopausal).refine hasModifier prediabetes

/-- A textbook sentence (OpenStax, no PMID). -/
def tb (id text : String) (c : Claim) : Statement :=
  { id, text, claim := c, evidence := [{ pmid := 0, year := 2013, kind := .textbook, note := text }] }

/-- An ontology axiom. -/
def ax (id text : String) (c : Claim) : Statement :=
  { id, text, claim := c, evidence := [{ pmid := 0, year := 2026, kind := .ontologyAxiom, note := text }] }

/-! ## The 40 context-required textbook claims (`data/m2/context_claims.json`, sample40) -/

def T01 := tb "molbio-m45475-69" "Telomerase is present in human cells"
  (.rel locatedIn (telomerase.refine inTaxon human) cell)
def T02 := tb "the-body-s-systems-m45537-183" "Epinephrine accelerates breakdown of stored fat in adipose tissue"
  (.effect adrenaline .pos (.process (lipidCatabolism.refine occursIn adipose)))
def T03 := tb "the-body-s-systems-m45536-190" "The electrochemical signal causes the two atria to contract"
  (.effect cardiacConduction .pos (.process (cardiacContraction.refine occursIn atrium)))
def T04 := tb "cell-structure-and-function-m45434-70" "In a hypotonic solution water enters the cell"
  (.rel hasParticipant (importIntoCell.refine occursIn cellInHypotonic) water)
def T05 := tb "photosynthesis-m45448-120" "Stomatal closure raises oxygen levels inside the leaf"
  (.effect stomatalClosure .pos (.amount (oxygen.refine locatedIn leaf)))
def T06 := tb "the-body-s-systems-m45537-201" "Glucagon causes release of glucose from the liver into the blood"
  (.effect glucagon .pos (.amount (glucose.refine locatedIn blood)))
def T07 := tb "reproduction-at-the-cellular-level-m45463-67" "FtsZ is a component of the prokaryotic cytoskeleton"
  (.rel partOf (ftsZ.refine inTaxon bacteria) cytoskeleton)
def T08 := tb "the-body-s-systems-m45537-334" "Increasing blood glucose causes the pancreas to release insulin"
  (.effect (glucose.refine locatedIn blood) .pos (.amount insulin))
def T09 := tb "the-body-s-systems-m45537-156" "An increase in blood potassium stimulates aldosterone release"
  (.effect (potassium.refine locatedIn blood) .pos (.amount aldosterone))
def T10 := tb "cell-structure-and-function-m45432-219" "The plant cell wall is external to the plasma membrane"
  (.rel adjacentTo (plantCellWall.refine inTaxon plants) plasmaMembrane)
def T11 := tb "the-body-s-systems-m45537-229" "The atrial hormone reduces blood Na+ concentration"
  (.effect anp .neg (.amount (sodium.refine locatedIn blood)))
def T12 := tb "cell-structure-and-function-m45432-25" "Loss of microvilli prevents nutrient absorption in celiac patients"
  (.effect (microvillus.refine hasModifier celiac) .pos (.process intestinalAbsorption))
def T13 := tb "reproduction-at-the-cellular-level-m45463-66" "Binary fission is the process of prokaryotic cell division"
  (.rel isA (binaryFission.refine inTaxon bacteria) cellDivision)
-- "early in life" (onset) is not expressed: no slot for onset.
def T14 := tb "molbio-m45475-117" "People with defective NER genes develop skin cancers early in life"
  (.effect (ner.refine inTaxon human) .neg (.phenotype skinNeoplasm))
def T15 := tb "the-body-s-systems-m45537-53" "Insulin decreases blood-glucose levels"
  (.effect insulin .neg (.amount (glucose.refine locatedIn blood)))
def T16 := tb "molbio-m45475-67" "Telomerase is active in some cancer cells"
  (.quant .some (.rel capableOf (telomerase.refine locatedIn malignantCell) telomereMaintenance))
def T17 := tb "how-cells-obtain-energy-m45440-11" "Lactic acid fermentation occurs routinely in mammalian red blood cells"
  (.rel occursIn (lacticFermentation.refine inTaxon mammalia) erythrocyte)
-- context {} in the data; "some organisms" is a quantifier, not a refinement
def T18 := tb "the-cellular-basis-of-inheritance-m45466-103" "In some organisms nuclear envelopes form in telophase I"
  (.quant .some (.rel happensDuring nuclearReassembly telophaseI))
def T19 := tb "the-body-s-systems-m45536-175" "Animal respiratory systems facilitate gas exchange"
  (.rel capableOf (respSystem.refine inTaxon metazoa) gasExchange)
def T20 := tb "the-body-s-systems-m45536-212" "An electrical signal triggers atrial cardiac muscle cells to contract"
  (.effect cardiacConduction .pos
    (.process ((cardiacContraction.refine occursIn atrium).refine occursIn cardiomyocyte)))
-- "only" (exclusivity) is not expressed
def T21 := tb "the-cellular-basis-of-inheritance-m45466-165" "In animals, meiotic cells participate only in sexual reproduction"
  (.rel partOf (meiosis.refine inTaxon metazoa) sexualReproduction)
def T22 := tb "reproduction-at-the-cellular-level-m45455-16" "Chromosomes are located in the nucleus of eukaryotic cells"
  (.rel locatedIn (chromosome.refine inTaxon eukaryota) nucleus)
-- forced: the condition belongs to the patient, not the drug
def T23 := tb "the-body-s-systems-m45538-197" "Medications relieve pain in rheumatoid arthritis"
  (.effect (drug.refine hasModifier ra) .neg (.phenotype pain))
def T24 := tb "how-cells-obtain-energy-m45437-11" "Photosynthesizing organisms (plants) produce sugars"
  (.rel hasOutput (photosynthesis.refine inTaxon plants) carbohydrate)
def T25 := tb "the-cellular-basis-of-inheritance-m45465-68" "Gametes are produced from diploid germ cells"
  (.rel developsFrom (gamete.refine inTaxon metazoa) (germCell.refine hasQuality diploid))
def T26 := tb "the-body-s-systems-m45537-337" "Glucagon stimulates release of stored glucose from the liver into the bloodstream"
  (.effect glucagon .pos (.amount (glucose.refine locatedIn blood)))
def T27 := tb "the-body-s-systems-m45539-28" "The vertebrate PNS is made up of peripheral sensory and motor nerves"
  (.rel hasPart (pns.refine inTaxon vertebrata) nerve)
def T28 := tb "the-body-s-systems-m45536-61" "Sympathetic input causes bronchial muscle relaxation"
  (.effect sns .pos (.process (smRelaxation.refine occursIn bronchus)))
def T29 := tb "reproduction-at-the-cellular-level-m45455-9" "The nucleoid is the region of a prokaryotic cell containing the genome"
  (.rel locatedIn (geneticMaterial.refine inTaxon bacteria) nucleoid)
-- "and some fungi" would be a second statement, `.quant .some` over NCBITaxon:4751
def T30 := tb "the-cellular-basis-of-inheritance-m45466-106" "In animals cytokinesis separates cell contents by a cleavage furrow"
  (.rel hasPart (cytokinesis.refine inTaxon metazoa) cleavageFurrow)
def T31 := tb "the-cellular-basis-of-inheritance-m45466-119" "In prophase II chromosomes condense again if they decondensed in telophase I"
  (.rel happensDuring (chromCondensation.refine hasModifier decondensedTelI) prophaseII)
-- "only" (glycolysis and nothing else) is not expressed
def T32 := tb "how-cells-obtain-energy-m45438-42" "Mature mammalian red blood cells are capable only of glycolysis"
  (.rel capableOf (erythrocyte.refine inTaxon mammalia) glycolysis)
def T33 := tb "the-cellular-basis-of-inheritance-m45467-83" "Triploid animals are sterile"
  (.effect (triploid.refine inTaxon metazoa) .pos (.phenotype sterile))
def T34 := tb "cell-structure-and-function-m45432-162" "In single-celled eukaryotes, lysosomes digest ingested food"
  (.rel capableOf ((lysosome.refine hasModifier unicellular).refine inTaxon eukaryota) digestion)
def T35 := tb "molbio-m45480-30" "Lactose is a food source for E. coli"
  (.rel hasInput (lactoseCatabolism.refine inTaxon ecoli) lactose)
def T36 := tb "cell-structure-and-function-m45432-158" "In plant cells, the Golgi synthesises polysaccharides"
  (.rel capableOf (golgi.refine inTaxon plants) polysaccharideSynthesis)
-- data says cellType CL:0000520; "in prokaryotes" read as the taxon, as elsewhere
def T37 := tb "molbio-m45476-20" "In prokaryotes transcription occurs in the cytoplasm"
  (.rel occursIn (transcription.refine inTaxon bacteria) cytoplasm)
def T38 := tb "the-body-s-systems-m45539-132" "Some antidepressant medications promote neurogenesis in the hippocampus"
  (.quant .some (.effect antidepressant .pos (.process (neurogenesis.refine occursIn hippocampus))))
def T39 := tb "the-body-s-systems-m45537-336" "Decreasing blood glucose causes the pancreas to release glucagon"
  (.effect (glucose.refine locatedIn blood) .neg (.amount glucagon))
def T40 := tb "reproduction-at-the-cellular-level-m45461-141" "The G2 checkpoint blocks entry to M phase if conditions are not met"
  (.effect (g2Checkpoint.refine hasModifier unmetConditions) .neg (.process g2mTransition))

def sample40 : List Statement :=
  [T01, T02, T03, T04, T05, T06, T07, T08, T09, T10, T11, T12, T13, T14, T15, T16, T17, T18, T19, T20,
   T21, T22, T23, T24, T25, T26, T27, T28, T29, T30, T31, T32, T33, T34, T35, T36, T37, T38, T39, T40]

example : sample40.length = 40 := rfl

/-! ## NMN (case study 3) -/

def nmnInMouse     := nmn.refine inTaxon mouse
def nmnInAgedMouse := nmn.refine inTaxon agedMouse
def nmnInHfdMouse  := nmn.refine inTaxon hfdMouse
def nmnInHuman     := nmn.refine inTaxon human
def nmnInAgedHuman := nmn.refine inTaxon agedHuman

def N1 : Statement where
  id := "NMN-1"; text := "NMN raises NAD+ in mouse liver"
  claim := .effect nmnInMouse .pos (.amount (nad.refine locatedIn liver))
  evidence := [{ pmid := 21982712, year := 2011, kind := .mechanistic, system := some .inVivo,
                 dose := some "500 mg/kg i.p.", note := "Yoshino 2011" }]
def N2 : Statement where
  id := "NMN-2"; text := "NMN reduces impaired glucose tolerance in high-fat-diet mice"
  claim := .effect nmnInHfdMouse .neg (.phenotype igt)
  evidence := [{ pmid := 21982712, year := 2011, kind := .mechanistic, system := some .inVivo,
                 strain := some "C57BL/6", note := "Yoshino 2011" }]
def N3 : Statement where
  id := "NMN-3"; text := "Long-term NMN reduces age-associated decline in physical activity in mice"
  claim := .effect nmnInAgedMouse .neg (.phenotype lowActivity)
  evidence := [{ pmid := 28068222, year := 2016, kind := .mechanistic, system := some .inVivo,
                 strain := some "C57BL/6N", dose := some "100 or 300 mg/kg/day oral",
                 duration := some "12 months", note := "Mills 2016" }]
def N4 : Statement where
  id := "NMN-4"; text := "NMN increases endurance in aged mice"
  claim := .effect nmnInAgedMouse .pos (.process locomotion)
  evidence := [{ pmid := 29570999, year := 2018, kind := .mechanistic, system := some .inVivo,
                 dose := some "400 mg/kg/day in drinking water", note := "Das 2018" }]
def N5 : Statement where
  id := "NMN-5"; text := "NMN increases muscle insulin sensitivity in prediabetic postmenopausal women"
  claim := .effect (nmn.refine inTaxon prediabeticWoman) .neg
    (.phenotype (insulinResistance.refine locatedIn skMuscle))
  evidence := [{ pmid := 33888596, year := 2021, kind := .rct, system := some .inVivo,
                 dose := some "250 mg/day oral", duration := some "10 weeks", note := "Yoshino 2021" }]
/-- (6), hypothetical: no statement exists for it. -/
def N6claim : Claim := .effect nmnInHuman .pos (.process locomotion)

/-! ## Chemiosmosis (case study 2) -/

def synthIn (m : Entity .component) := atpSynthase.refine locatedIn m

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
/-- The chimera is two refinements: a bovine synthase in a membrane that has halobacterial
bacteriorhodopsin as a part. -/
def racker : Entity .component :=
  (atpSynthase.refine locatedIn (membrane.refine hasPart (bacteriorhodopsin.refine inTaxon halobact))).refine
    inTaxon cow
def C9 : Statement where
  id := "CHEMI-9"; text := "ATP synthase makes ATP from a light-driven proton gradient in reconstituted liposomes"
  claim := .rel capableOf racker pmfAtpSynthesis
  evidence := [{ pmid := 4272126, year := 1974, kind := .inVitro, system := some .reconstituted,
                 note := "Racker and Stoeckenius 1974, liposomes with bacteriorhodopsin" }]

def pmfOutput := ax "GO:0015986-output" "proton motive force-driven ATP synthesis has output ATP"
  (.rel hasOutput pmfAtpSynthesis atp)

/-! ## S1. Mouse and human evidence do not fuse by accident -/

/-- The subjects differ, so the claims differ. -/
theorem s1_subjects_differ : nmnInMouse ≠ nmnInHuman := by decide
theorem s1_aged_differ : nmnInAgedMouse ≠ nmnInAgedHuman := by decide
/-- "NMN in (aged humans)" is not "(NMN in humans) that is aged": the bracketed filler keeps them apart. -/
theorem s1_no_collision : (nmn.refine inTaxon human).refine hasModifier aged ≠ nmnInAgedHuman := by decide

/-- Hypothetical human evidence for (6), to show what an attempted fusion does. -/
def N6human : Statement where
  id := "NMN-6h"; text := "HYPOTHETICAL human trial"; claim := N6claim
  evidence := [{ pmid := 0, year := 2030, kind := .rct, note := "hypothetical" }]

-- Fusing the aged-mouse endurance result with a human endurance result is a type error: `both`
-- needs one claim, and `NMN ⊓ in_taxon aged mouse` is not `NMN ⊓ in_taxon human`.
#check_failure (Derivation.both (.lit N4) (.lit N6human) : Derivation N6claim)
-- Same for the real papers: mouse (2) and human (5) are different claims.
#check_failure (Derivation.both (.lit N2) (.lit N5) : Derivation N5.claim)
-- Nor can a context-free claim be reached from a refined one: no rule drops a refinement on the
-- subject. Context-free "NMN raises NAD+" from (1) does not type-check.
#check_failure (Derivation.lit N1 : Derivation (.effect nmn .pos (.amount (nad.refine locatedIn liver))))

/-! ## S2. Mouse to human needs an explicit, weighted transport -/

def crossSpecies : Evidence :=
  { pmid := 0, year := 2026, kind := .crossSpecies,
    note := "mouse-to-human transfer of an exercise phenotype; placeholder weight" }

/-- (4) transported to aged humans. The conclusion lists N4 and the transport item as axioms. -/
def s2_transport : Derivation (.effect nmnInAgedHuman .pos (.process locomotion)) :=
  .transport agedHuman (.lit N4) crossSpecies

theorem s2_belief : s2_transport.opinion.belief = 21 / 100 := by decide +kernel
theorem s2_not_established : s2_transport.verdict = .unsupported := by decide +kernel
theorem s2_discounted : s2_transport.opinion.belief ≤ 3 / 10 * (Derivation.lit N4).opinion.belief := by
  decide +kernel

-- Transport without a `.crossSpecies` item does not elaborate (`hk` fails).
#check_failure (Derivation.transport agedHuman (.lit N4)
  { pmid := 29570999, year := 2018, kind := .mechanistic } : Derivation (.effect nmnInAgedHuman .pos (.process locomotion)))
-- (6) itself is about humans in general. From aged humans it needs a generalisation (dropping
-- `aged`), which no rule gives: (6) is not derivable from (4) at all in M2.
#check_failure (s2_transport : Derivation N6claim)

/-! ## S3. Specialisation is free -/

def mouseIsEuk := ax "NCBITaxon:10090-lineage" "Mus musculus is_a Eukaryota" (.rel isA mouse eukaryota)

/-- From (22), chromosomes in eukaryotes are in the nucleus, to mouse chromosomes: no new evidence,
only the NCBITaxon lineage and the existing is_a law. -/
def s3_mouse_chromosome : Derivation (.rel locatedIn (chromosome.refine inTaxon mouse) nucleus) :=
  .relChain (.refineMono (.lit mouseIsEuk)) (.lit T22)

theorem s3_free : s3_mouse_chromosome.opinion.belief = (Derivation.lit T22).opinion.belief := by decide +kernel

/-- From an unrefined claim to a refined one: the refinement axiom does it. Effects too, via
`isaInheritEffect`: "insulin lowers blood glucose" holds of insulin in mice. -/
def s3_effect : Derivation (.effect (insulin.refine inTaxon mouse) .neg (.amount (glucose.refine locatedIn blood))) :=
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

/-- What is free is the object side: each refined synthase makes ATP (RO chain capable_of ∘
has_output is not in RO, so this goes only as far as the is_a laws allow). -/
def c9_chain : Derivation C9.claim := .lit C9

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

end BioLean.Refinement
```

## (d) The five soundness tests

All five are in `BioLean/Examples/Refinement.lean`. Each one is either a theorem the kernel checks or
a `#check_failure`, which is a term Lean rejects.

**S1. Mouse and human evidence do not fuse: PASS.**
- `s1_subjects_differ : nmnInMouse ≠ nmnInHuman` and `s1_aged_differ` are proved by `decide`.
- `#check_failure (both (.lit N4) (.lit N6human))` and `#check_failure (both (.lit N2) (.lit N5))`
  are rejected: `both` needs the two derivations to prove one claim, and the claims differ in their
  subject curie.
- There is no way to reach the context-free claim "NMN raises NAD+": no rule drops a subject
  refinement, and `#check_failure (lit N1 : Derivation (.effect nmn ...))` is rejected.
- `s1_no_collision` shows that (NMN in humans) ⊓ aged is a different entity from NMN in (aged humans).
  An earlier unbracketed curie made these two equal. I found that bug while building this.
- Caveat: nothing stops a curator from writing a mouse paper as evidence on the bare `nmn`. The
  design prevents accidental fusion of claims that were encoded correctly; it does not prevent
  under-specified encoding.

**S2. Mouse to human needs an explicit weighted step: PASS, and stricter than asked.**
- `s2_transport = .transport agedHuman (.lit N4) crossSpecies` gives belief exactly 21/100
  (`s2_belief`: 0.7 × 0.3), and `s2_not_established` gives verdict `unsupported`.
- `report` lists both N4 and a synthetic `transport:` statement carrying the crossSpecies item as
  axioms.
- Transport with a `.mechanistic` evidence item does not elaborate, because the default `hk := by
  decide` proves the kind is wrong.
- Mouse to human is impossible without `transport`. `isaInheritEffect` would need "human is_a
  mouse", and no such statement exists.
- Stricter than asked: (4) is about *aged* mice, so transport lands on "NMN increases endurance in
  aged humans", not on (6) "in humans". Dropping "aged" is generalisation, so (6) is not derivable
  from (4) at all (`#check_failure (s2_transport : Derivation N6claim)`).
- The reverse, specialising humans to aged humans, is free (`agedHumanIsHuman`).

**S3. Specialisation is free: PASS, with a cap.**
- `s3_mouse_chromosome` takes T22 (chromosomes are in the nucleus in Eukaryota) to mouse chromosomes
  as `relChain (refineMono (lit mouseIsEuk)) (lit T22)`. No new evidence is needed, only the NCBITaxon
  lineage axiom.
- The belief stays 0.8 (`s3_free`).
- For effects, `s3_effect` takes "insulin lowers blood glucose" to "insulin in mouse lowers blood
  glucose" through `refineAxiom` and `isaInheritEffect`, belief unchanged (`s3_effect_free`).
- The cap: the step is `weakest`, and the axiom weighs 0.9. A premise believed above 0.9, for
  example fused from many papers, loses belief on specialisation, so "free" means free of evidence,
  not exactly lossless.
- Specialisation needed one new rule for effects (`isaInheritEffect`) and one for taxa
  (`refineMono`). The existing is_a laws alone only cover the `refineAxiom` case for `.rel` claims.

**S4. Generalising thylakoid (7) and mitochondrion (8) to "a membrane" is not free: PASS.**
- `s4_isa` gives synthase ⊓ thylakoid membrane is_a synthase ⊓ membrane.
- The is_a laws push relations down, never up, so both orders of `relChain` with C7 are rejected
  (`#check_failure` twice).
- `both (lit C7) (lit C8)` is rejected because the subjects differ (`s4_subjects_differ`).
- The only route to "ATP synthase in a membrane makes ATP" is a new Statement, which would show up in
  `axioms`. This is M4's `generalize`.

**S5. Hypotonic swelling and hypertonic shrinking: PASS.**
- S5a is `cellInHypotonic has_quality swollen` (PATO:0001851).
- S5b is `cellInHypertonic has_quality shriveled` (PATO:0002460).
- The two subjects differ (`s5_subjects_differ`), and `both` is rejected.
- `clash` needs `a r b` and `¬(a r b)` with the same a, r and b, so the two claims cannot contradict.
- The nested refinement (cell ⊓ surrounded_by (solution ⊓ has_quality decreased osmolarity)) is
  correct DL, and it is reused in T04 ("in a hypotonic solution water enters the cell").

## (e) Scorecard

| measure | result |
|---|---|
| claims expressed | **40/40 compile**. 31 are faithful; 9 are lossy, forced or ungrounded (see below) |
| NMN + chemiosmosis | 9/9 (N6 is a hypothesis, `N6claim`, with no statement) |
| S1 no accidental fusion | pass (only for correctly encoded claims) |
| S2 transport explicit, weighted 0.3 | pass (belief 0.21; (6) itself is not reachable from aged mice) |
| S3 free specialisation | pass (capped at 0.9 by `weakest` with the axiom) |
| S4 generalisation not free | pass |
| S5 conditions do not fuse or clash | pass |
| new Claim/Target constructors | 0 |
| other new constructors | 1 `EvidenceKind.crossSpecies`; new type `ExpSystem` (4); 4 optional `Evidence` fields |
| new derivation rules | 3: `refineMono`, `isaInheritEffect`, `transport` |
| new defs | `Entity.refine`, `Entity.refineAxiom`, `Rel.inTaxon`, `Rel.hasModifier` |
| Lean lines changed (core) | +69 −1 in 4 files, +1 −1 lakefile; example file 445 lines |
| free specialisation | yes (free of evidence; strength capped at 0.9) |

The 9 claims that were not fully faithful:
- Lossy:
  - T14 loses "early in life", because there is no slot for onset.
  - T21 and T32 lose "only", because exclusivity is not expressible.
  - T30 drops "and some fungi"; it would need a second `.quant .some` statement.
- Forced:
  - T12 has the condition on the microvillus: microvillus ⊓ has_modifier celiac disease.
  - T23 has it on the drug: drug ⊓ has_modifier rheumatoid arthritis.
  - In both, the condition belongs to the patient, and the DL class is nonsense if read literally.
- Ungrounded: T31, T34 and T40 refine by a `BLN:` placeholder condition ("decondensed in telophase
  I", "unicellular", "checkpoint conditions not met").
- Judgment calls:
  - T18 has an empty context in the data; I used `.quant .some`.
  - T37's data gives cellType CL:0000520, but I read "in prokaryotes" as a taxon.
  - T02 drops the second agent, norepinephrine.

## (f) Verdict

Refinement passes all five tests with no new Claim constructor. The real work is done by three
small rules, and the curie bracketing bug shows that entity identity is the soundness boundary of
this design. The forced part is placement: taxon on the subject is principled, but every anatomical
or disease context needed a choice of entity ("blood glucose" vs "glucagon in blood"; "drug ⊓
has_modifier RA" is wrong if read literally). That choice changes which inferences are free, and
nothing checks it. Identity is by string, so the same context applied in a different order gives a
different entity, and refinement does not check RO domains (has_modifier on a process). Both fail
safe (they stop fusion rather than cause it), but they are silent. Transport only works on the
outermost `in_taxon` of an effect's agent, so the NMN hypothesis (6) cannot be reached from aged
mice at all; that is arguably correct but will surprise users. The design composes cleanly with the
existing RO chains and is_a laws. I would take it if a canonical refinement order and an RO domain
check were enforced in `Entity.refine`, but it is a curation discipline more than a type guarantee.
