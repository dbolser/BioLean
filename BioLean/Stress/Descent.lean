import BioLean.Examples.Transcription
import BioLean.Lib.TextbookClaimsR2.Photosynthesis
import BioLean.Lib.TextbookClaimsR2.TheBodySSystemsA
import BioLean.Lib.TextbookClaimsR3.Photosynthesis
import BioLean.Lib.TextbookClaimsR3.TheBodySSystemsA

/-!
# Stress set 01b: descent, against today's core

Program 01b (`docs/programs/01b-descent-sketch.md`), the measured follow-up to program 01's
decision 1 (`docs/programs/01-universals-and-descent.md`). This file runs option (c), "leave the
current measure", for real: `Derivation.generalize` with bracketing coverage over the imported
NCBITaxon hierarchy (`BioLean/Coverage.lean`), then free narrowing to the target taxon through
`refineMono` and `relChain` (the is_a laws), exactly as `Examples/Transcription.lean` and
`Examples/Context.lean` do. Nothing here changes the core. Options (b) and (b)+(k) are sketched in
Python (`scripts/stress/descent_sketch.py`), because they need a rule the core does not have.

What each row reports (one `OBS` line each, read by `descent_sketch.py table`):
* `c`: option (c) as program 01 defines it. Positive instances only: the best `generalize` to any
  imported clade above the target, narrowed to the target; a positive record on the target itself
  is a `lit` and wins if stronger. Loss records cannot enter `generalize`.
* `core`: today's core given every record of the row. A loss record is a `notRel` statement; where a
  positive derivation exists too, the reading is `Derivation.clash` of the two (fusion, not
  defeat). A clade's loss record reaches a member through `notRelSub`.

Each positive instance and record is one curated item (`curatedDb`, 4/5), the weight the Python
sketch uses. A taxon outside the imported hierarchy cannot be a sampled instance (`admissible`
refuses it), so for those targets narrowing starts at the nearest imported ancestor (the anchor,
taken from `data/stress/01b/lineages.tsv`); the is_a step is an NCBI Taxonomy statement
(`ontologyAxiom`, 9/10). `BLN:` objects are stand-ins where no ontology term exists.

Homology needs no new claim shape. RO:0002158 "shares ancestor with" (VBO's homologous_to) is in
the core's RO table, so "X in A is homologous to X in B" is a `rel` claim and a convergence record
(HOM:0000004) is a `notRel` statement (`homolRow`). The same holds for a universal negative such as
"no animal makes carotenoids" (H1). These rows are run, not marked INEXPRESSIBLE (review,
2026-11-01).

Pins: `#guard`, `theorem ... := by decide +kernel`, `#check_failure`, and exhaustive matches with
no wildcard (`shape`, `predShape`, `kindName`): a new constructor makes this file fail to compile,
which flips every INEXPRESSIBLE pin at once.
-/

namespace BioLean.Stress.Descent
open BioLean Derivation Taxa Coverage

def tx (n : Nat) (l : String) : Entity .taxon := ⟨s!"NCBITaxon:{n}", l⟩

/-- "An organism", refined by `in_taxon` to make "an organism of taxon T" (the R3 textbook form). -/
def organism : Entity .taxon := ⟨"NCBITaxon:131567", "organism"⟩

/-! ## The machinery: one trait, generalised and narrowed -/

/-- A trait: "every `subj` in taxon T `r` `obj`". -/
structure Trait (ks k : Kind) where
  key : String
  subj : Entity ks
  r : Rel
  obj : Entity k
  h : r.accepts ks k = true := by decide
  hc : RO.chainOK Rel.isA r r = true := by decide
  hr : Rel.inTaxon.accepts ks .taxon = true := by decide
  hi : Rel.isA.accepts ks ks = true := by decide

variable {ks k : Kind}

def Trait.at (x : Trait ks k) (t : Entity .taxon) : Entity ks := x.subj.inCtx { taxon := some t }
def Trait.pred (x : Trait ks k) : Predicate ks := .rel x.r x.obj x.h
def Trait.claim (x : Trait ks k) (t : Entity .taxon) : Claim := .rel x.r (x.at t) x.obj x.h

/-- A positive record in taxon `t`: one curated item. -/
def Trait.inst (x : Trait ks k) (t : Entity .taxon) : Statement where
  id := s!"{x.key}:{t.curie}"
  text := s!"{x.subj.label} in {t.label} {x.r} {x.obj.label}"
  claim := x.claim t
  evidence := [{ pmid := 0, year := 2026, kind := .curatedDb, taxon := some t,
                 note := "positive record, data/stress/01b/cases.tsv" }]

/-- A loss record: "no `subj` in `t` `r` `obj`", one curated item citing the paper. -/
def Trait.lossRec (x : Trait ks k) (t : Entity .taxon) (pmid year : Nat) : Statement where
  id := s!"{x.key}:loss:{t.curie}"
  text := s!"no {x.subj.label} in {t.label} {x.r} {x.obj.label}"
  claim := .notRel x.r (x.at t) x.obj x.h
  evidence := [{ pmid := pmid, year := year, kind := .curatedDb, taxon := some t, note := "loss record" }]

/-- `generalize` with bracketing coverage, the M4 rule, over curated instances. -/
def Trait.gen (x : Trait ks k) (T : Entity .taxon) (taxa : List (Entity .taxon))
    (h : admissible T taxa = true) : Derivation (x.claim T) :=
  .generalize x.pred {} T .bracketing taxa (fun i => .lit (x.inst taxa[i])) h

/-- An NCBI Taxonomy is_a statement. -/
def isaStmt (S T : Entity .taxon) : Statement where
  id := s!"ncbi:{S.curie}-isa-{T.curie}"
  text := s!"{S.label} is_a {T.label}"
  claim := .rel Rel.isA S T
  evidence := [{ pmid := 0, year := 2026, kind := .ontologyAxiom, note := "NCBI Taxonomy lineage" }]

/-- `subj` in S is_a `subj` in T, from S is_a T: refinement is monotone in its filler. -/
def Trait.sub (x : Trait ks k) (S T : Entity .taxon) : Derivation (.rel Rel.isA (x.at S) (x.at T) x.hi) :=
  .refineMono (e := x.subj) (r := Rel.inTaxon) (.lit (isaStmt S T)) x.hr x.hi

/-- Free narrowing: the is_a law moves the clade's claim to S (`relChain`, weakest link). -/
def Trait.narrow (x : Trait ks k) (S T : Entity .taxon) (d : Derivation (x.claim T)) : Derivation (x.claim S) :=
  .relChain (x.sub S T) d x.hc x.h

/-- A clade's loss record reaches a member: `notRelSub`, the inherited negation. -/
def Trait.lossTo (x : Trait ks k) (S C : Entity .taxon) (pmid year : Nat) :
    Derivation (.notRel x.r (x.at S) x.obj x.h) :=
  .notRelSub (x.sub S C) (.lit (x.lossRec C pmid year)) x.h

def ofCode (c : Code) : Entity .taxon := ⟨s!"NCBITaxon:{c.2}", (Ontology.label? c).getD "?"⟩

/-- A code and its imported is_a ancestors, nearest first. -/
def up : Nat → Code → List Code
  | 0, c => [c]
  | n + 1, c => c :: (Ontology.parents c).flatMap (up n)

/-- The anchor and its imported ancestors: the clades `generalize` may target. -/
def ancestors (anchor : Entity .taxon) : List (Entity .taxon) :=
  match Curie.encode anchor.curie with
  | some c => if Ontology.known c then (up Ontology.maxDepth c).map ofCode else []
  | none => []

/-- Option (c), the generalisation half: for every imported clade T above S that admits the
positive instances lying in it, generalise to T and narrow to S; keep the most believed. -/
def Trait.best (x : Trait ks k) (S anchor : Entity .taxon) (pos : List (Entity .taxon)) :
    Option (Entity .taxon × Derivation (x.claim S)) :=
  (ancestors anchor).foldl (fun acc T =>
    let taxa := pos.filter fun t => t != S && Taxa.isA t.curie T.curie
    if h : admissible T taxa = true then
      let d := x.narrow S T (x.gen T taxa h)
      match acc with
      | some (_, d') => if d'.opinion.belief < d.opinion.belief then some (T, d) else acc
      | none => some (T, d)
    else acc) none

/-- Option (c) on "S has the trait": the best narrowed generalisation, or S's own positive
record if that is stronger. Returns the clade generalised from (S itself for a record). -/
def Trait.yes (x : Trait ks k) (S anchor : Entity .taxon) (pos : List (Entity .taxon)) (ownHas : Bool) :
    Option (Entity .taxon × Derivation (x.claim S)) :=
  let b := x.best S anchor pos
  if ownHas then
    let l : Derivation (x.claim S) := .lit (x.inst S)
    match b with
    | some (T, d) => if l.opinion.belief < d.opinion.belief then some (T, d) else some (S, l)
    | none => some (S, l)
  else b

/-- Today's core with a loss record entered: `clash` of the positive derivation (if any) with the
negative one, or the negative alone. -/
def readWith {k₁ k₂ : Kind} {a : Entity k₁} {b : Entity k₂} {r : Rel} {h : r.accepts k₁ k₂ = true}
    (yes : Option (Entity .taxon × Derivation (.rel r a b h))) (no : Derivation (.notRel r a b h)) : Opinion :=
  match yes with
  | some (_, d) => Derivation.clash d no
  | none => no.opinion.negate

/-! ## Observations -/

/-- One row of the stress table, as observed. -/
structure Obs where
  id : String
  c : Option (String × Opinion)
  core : Option Opinion
  note : String := ""

def vname : Verdict → String
  | .established => "established" | .contested => "contested" | .refuted => "refuted"
  | .unsupported => "unsupported"

def vstr : Option Opinion → String
  | some o => s!"{vname o.verdict} b={o.belief.toDecimal} d={o.disbelief.toDecimal}"
  | none => "none"

def Obs.line (o : Obs) : String :=
  s!"OBS\t{o.id}\tc={vstr (o.c.map (·.2))}\tfrom={(o.c.map (·.1)).getD "-"}\tcore={vstr o.core}\t{o.note}"

def verdictOf : Option Opinion → Option Verdict := Option.map (·.verdict)

/-- A row where the case cannot be stated, with the reason. -/
def inexpressible (id why : String) : Obs := { id, c := none, core := none, note := s!"INEXPRESSIBLE: {why}" }

/-- Option (c) and today's core for "S has the trait", with an optional loss record. -/
def Trait.row (x : Trait ks k) (id : String) (S anchor : Entity .taxon) (pos : List (Entity .taxon))
    (ownHas : Bool := false) (loss : Option (Derivation (.notRel x.r (x.at S) x.obj x.h)) := none)
    (note : String := "") : Obs :=
  let y := x.yes S anchor pos ownHas
  { id, note, c := y.map fun (T, d) => (T.label, d.opinion),
    core := match loss with
      | some no => some (readWith y no)
      | none => y.map (·.2.opinion) }

/-- Option (c) for "every T has the trait": `generalize` to T itself. No rule revises it from a
member's loss record, so the core reads the same. -/
def Trait.uni (x : Trait ks k) (id : String) (T : Entity .taxon) (pos : List (Entity .taxon))
    (note : String := "") : Obs :=
  let taxa := pos.filter fun t => Taxa.isA t.curie T.curie
  let o := if h : admissible T taxa = true then some (x.gen T taxa h).opinion else none
  { id, note, c := o.map (T.label, ·), core := o }

/-! ## Taxa and traits -/

def ecoli := tx 562 "Escherichia coli"
def yeast := tx 4932 "Saccharomyces cerevisiae"
def arab := tx 3702 "Arabidopsis thaliana"
def methanogens := tx 28890 "Methanobacteriota"
def cow := tx 9913 "Bos taurus"
def chimp := tx 9598 "Pan troglodytes"
def bats := tx 9397 "Chiroptera"
def toothedWhales := tx 9722 "Odontoceti"
def aves := tx 8782 "Aves"
def boreo := tx 1437010 "Boreoeutheria"
-- targets outside the imported hierarchy, with their nearest imported ancestor (anchor)
def giardia := tx 5741 "Giardia duodenalis"
def trichomonas := tx 5722 "Trichomonas vaginalis"
def metamonada := tx 2611341 "Metamonada"
def astyanax := tx 7994 "Astyanax mexicanus"
def actinopterygii := tx 7898 "Actinopterygii"
def entamoeba := tx 5759 "Entamoeba histolytica"
def amoebozoa := tx 554915 "Amoebozoa"
def henneguya := tx 69463 "Henneguya salminicola"
def cnidaria := tx 6073 "Cnidaria"
def soybean := tx 3847 "Glycine max"
def rosids := tx 71275 "rosids"
def chicken := tx 9031 "Gallus gallus"
def neognathae := tx 8825 "Neognathae"
def icefish := tx 36190 "Chaenocephalus aceratus"
def channichthyidae := tx 30806 "Channichthyidae"
def epifagus := tx 4177 "Epifagus virginiana"
def asterids := tx 71274 "asterids"
def typhlomys := tx 687454 "Typhlomys"
def muroidea := tx 337687 "Muroidea"
def gastrotheca := tx 394453 "Gastrotheca guentheri"
def amphibia := tx 8292 "Amphibia"
def viscum := tx 3972 "Viscum album"
def mysticeti := tx 9761 "Mysticeti"
-- positive instances outside the imported hierarchy: they cannot be sampled
def platypus := tx 9258 "Ornithorhynchus anatinus"
def zebrafish := tx 7955 "Danio rerio"
def dicty := tx 44689 "Dictyostelium discoideum"
def reclinomonas := tx 48483 "Reclinomonas americana"
def andalucia := tx 505711 "Andalucia godoyi"
def strepsirrhini := tx 376911 "Strepsirrhini"
def gorilla := tx 9593 "Gorilla gorilla"
def alligator := tx 8496 "Alligator mississippiensis"
def notothenia := tx 8208 "Notothenia coriiceps"
def tobacco := tx 4097 "Nicotiana tabacum"
def candida := tx 5476 "Candida albicans"
def neurospora := tx 5141 "Neurospora crassa"
def myxobolus := tx 59785 "Myxobolus squamalis"
def axolotl := tx 8296 "Ambystoma mexicanum"

/-- Each positive instance the import lacks is refused by `admissible`, so it counts for nothing. -/
theorem outside_import :
    [platypus, zebrafish, dicty, reclinomonas, andalucia, strepsirrhini, gorilla, alligator, notothenia,
      tobacco, candida, neurospora, myxobolus, axolotl, giardia, trichomonas, entamoeba, henneguya,
      soybean, chicken, icefish, epifagus, typhlomys, gastrotheca, astyanax].all (!Taxa.known ·) := by
  decide +kernel

theorem anchors_inside :
    [metamonada, actinopterygii, amoebozoa, cnidaria, rosids, neognathae, asterids, muroidea, amphibia,
      aves, boreo].all Taxa.known := by
  decide +kernel

def cellE : Entity .cellType := ⟨"CL:0000000", "cell"⟩
def tCell : Entity .cellType := ⟨"CL:0000084", "T cell (activated: state not expressed)"⟩
def macrophage : Entity .cellType := ⟨"CL:0000235", "macrophage"⟩

def ribosome : Trait .taxon .component := { key := "ribosome", subj := organism, r := Rel.hasPart, obj := ⟨"GO:0005840", "ribosome"⟩ }
def lactation : Trait .taxon .process := { key := "lactation", subj := organism, r := Rel.capableOf, obj := ⟨"GO:0007595", "lactation"⟩ }
def mito : Trait .taxon .component := { key := "mito", subj := organism, r := Rel.hasPart, obj := ⟨"GO:0005739", "mitochondrion"⟩ }
def vitc : Trait .taxon .process := { key := "vitc", subj := organism, r := Rel.capableOf, obj := ⟨"GO:0019853", "L-ascorbic acid biosynthetic process"⟩ }
def eye : Trait .taxon .anatomy := { key := "eye", subj := organism, r := Rel.hasPart, obj := ⟨"UBERON:0000970", "eye"⟩ }
def nucleus : Trait .cellType .component := { key := "nucleus", subj := cellE, r := Rel.hasPart, obj := ⟨"GO:0005634", "nucleus"⟩ }
def haem : Trait .taxon .component := { key := "haem", subj := organism, r := Rel.hasPart, obj := ⟨"GO:0005833", "hemoglobin complex"⟩ }
def tooth : Trait .taxon .anatomy := { key := "tooth", subj := organism, r := Rel.hasPart, obj := ⟨"UBERON:0001091", "calcareous tooth"⟩ }
def actin : Trait .taxon .component := { key := "actin", subj := organism, r := Rel.hasPart, obj := ⟨"GO:0015629", "actin cytoskeleton"⟩ }
def liver : Trait .taxon .anatomy := { key := "liver", subj := organism, r := Rel.hasPart, obj := ⟨"UBERON:0002107", "liver"⟩ }
def gallbladder : Trait .taxon .anatomy := { key := "gallbladder", subj := organism, r := Rel.hasPart, obj := ⟨"UBERON:0002110", "gallbladder"⟩ }
def mhc2 : Trait .cellType .component := { key := "mhc2", subj := tCell, r := Rel.hasPart, obj := ⟨"GO:0042613", "MHC class II protein complex"⟩ }
def cd4 : Trait .cellType .protein := { key := "cd4", subj := macrophage, r := Rel.hasPart, obj := ⟨"PR:000001004", "CD4 molecule"⟩ }
def hasPhenotype : Rel := ⟨.ro, 2200, false⟩
def vomit : Trait .taxon .phenotype := { key := "vomit", subj := organism, r := hasPhenotype, obj := ⟨"HP:0002013", "vomiting"⟩ }
def sinusoid : Trait .taxon .anatomy := { key := "sinusoid", subj := organism, r := Rel.hasPart, obj := ⟨"UBERON:0003910", "splenic sinusoid"⟩ }
def mtdna : Trait .taxon .component := { key := "mtdna", subj := organism, r := Rel.hasPart, obj := ⟨"GO:0000262", "mitochondrial chromosome"⟩ }
def complex1 : Trait .taxon .component := { key := "complex1", subj := organism, r := Rel.hasPart, obj := ⟨"GO:0045271", "respiratory chain complex I"⟩ }
def mtCox2 : Trait .taxon .gene := { key := "mtcox2", subj := organism, r := Rel.hasPart, obj := ⟨"BLN:mt_cox2", "cox2 expressed from the mitochondrial chromosome"⟩ }
def cmah : Trait .taxon .function := { key := "cmah", subj := organism, r := Rel.capableOf, obj := ⟨"GO:0030338", "CMP-N-acetylneuraminate monooxygenase activity"⟩ }
def photo : Trait .taxon .process := { key := "photo", subj := organism, r := Rel.capableOf, obj := ⟨"GO:0015979", "photosynthesis"⟩ }
def echo : Trait .taxon .process := { key := "echo", subj := organism, r := Rel.capableOf, obj := ⟨"GO:0050959", "echolocation"⟩ }
def mandTooth : Trait .taxon .anatomy := { key := "mandtooth", subj := organism, r := Rel.hasPart, obj := ⟨"UBERON:0003268", "tooth of lower jaw"⟩ }
def mtRpo : Trait .taxon .gene := { key := "mtrpo", subj := organism, r := Rel.hasPart, obj := ⟨"BLN:mt_rpoB", "rpoB encoded by the mitochondrial chromosome"⟩ }
def mtCytb : Trait .taxon .gene := { key := "mtcytb", subj := organism, r := Rel.hasPart, obj := ⟨"BLN:mt_cytb", "cytochrome b encoded by the mitochondrial chromosome"⟩ }

def euk4 := [yeast, human, arab, mouse]

/-! ## What the core cannot say (INEXPRESSIBLE pins)

No wildcards: a new claim shape (an ancestor claim, a universal with exceptions), a new kind (a
genetic code, a population) or a negated predicate for `generalize` breaks these. A homology claim
is not a new shape: see `homolClaim` below. -/

def shape : Claim → String
  | .effect .. => "effect" | .mediatedBy .. => "mediatedBy" | .noEffect .. => "noEffect"
  | .rel .. => "rel" | .notRel .. => "notRel" | .count .. => "count" | .atLeast .. => "atLeast"
  | .countBetween .. => "countBetween" | .cardinality .. => "cardinality" | .measure .. => "measure"
  | .atLeastMeasure .. => "atLeastMeasure" | .less .. => "less" | .produces .. => "produces"
  | .consumes .. => "consumes" | .yield .. => "yield" | .homeostasis .. => "homeostasis"
  | .quant _ c => s!"quant {shape c}"

/-- `generalize` widens only a positive predicate: "no animal makes carotenoids" (H1) cannot be
generalised from instances. -/
def predShape {k : Kind} : Predicate k → String
  | .effect .. => "effect" | .rel .. => "rel"

/-- No kind for a genetic code or a codon assignment (N1 to N4, NT1), and no population below the
species (L6, D13): `Ctx` has no population slot either. -/
def kindName : Kind → String
  | .chemical => "chemical" | .protein => "protein" | .gene => "gene" | .process => "process"
  | .function => "function" | .phenotype => "phenotype" | .disease => "disease" | .anatomy => "anatomy"
  | .cellType => "cellType" | .component => "component" | .taxon => "taxon"

/-- The fields of a context: taxon, anatomy, cell type, component, stage, life stage, condition. No
population (cave fish, lactase-persistent herders). -/
def ctxFields (c : Ctx) : List Bool :=
  [c.taxon.isSome, c.anatomy.isSome, c.cellType.isSome, c.component.isSome, c.stage.isSome,
   c.lifeStage.isSome, c.condition.isSome]
example : ctxFields {} = [false, false, false, false, false, false, false] := rfl

/-! ## Homology and universal negatives are stateable today

RO:0002158 "shares ancestor with" is RO's descent relation ("d1 and d2 share ancestor iff some a
has d1 and d2 derived by descent from it"; VBO calls it homologous_to). It is in the core's RO
table, transitive, and the conclusion of chain 29. So a homology claim is a `rel`, and a
convergence record is a `notRel`. What the core lacks is a rule that infers homology from shared
presence: its only route to the claim is chain 29, which needs "derived by descent from" premises
that no record here supplies. -/

def sharesAncestor : Rel := ⟨.ro, 2158, false⟩
def derivedByDescentFrom : Rel := ⟨.ro, 2156, false⟩
def hasDerivedByDescendant : Rel := ⟨.ro, 2157, false⟩

#guard sharesAncestor.label == "shares ancestor with"
#guard RO.chainOK derivedByDescentFrom hasDerivedByDescendant sharesAncestor
#guard RO.transitive.contains sharesAncestor

/-- "`x` in A shares ancestor with `x` in B": historical homology as a `rel` claim. -/
def homolClaim {k : Kind} (x : Entity k) (A B : Entity .taxon) : Claim :=
  .rel sharesAncestor (x.inCtx { taxon := some A }) (x.inCtx { taxon := some B }) (by cases k <;> decide)

/-- A convergence record (HOM:0000004): "`x` in A does not share ancestor with `x` in B", one
curated item citing the paper. -/
def convRec {k : Kind} (key : String) (x : Entity k) (A B : Entity .taxon) (pmid year : Nat) : Statement where
  id := s!"{key}:convergent:{A.curie}:{B.curie}"
  text := s!"{x.label} in {A.label} and in {B.label} arose separately"
  claim := .notRel sharesAncestor (x.inCtx { taxon := some A }) (x.inCtx { taxon := some B }) (by cases k <;> decide)
  evidence := [{ pmid := pmid, year := year, kind := .curatedDb, note := "convergence record (HOM:0000004)" }]

/-- A homology row. Nothing derives the claim from the presence records, so the core speaks only
through a convergence record, read against the claim (`negate`, as `readWith` does). -/
def homolRow {k : Kind} (id : String) (x : Entity k) (A B : Entity .taxon) (conv : Option (Nat × Nat)) : Obs :=
  { id, c := none,
    core := conv.map fun (p, y) => (Derivation.lit (convRec id x A B p y)).opinion.negate,
    note := "stated with RO:0002158 shares ancestor with" ++
      (if conv.isSome then "; the convergence record (notRel) decides" else "; no rule derives it from shared presence") }

def cameraEye : Entity .anatomy := ⟨"UBERON:0000019", "camera-type eye"⟩
def forelimb : Entity .anatomy := ⟨"UBERON:0002102", "forelimb"⟩
def c4 : Entity .process := ⟨"GO:0009760", "C4 photosynthesis"⟩
def antifreeze : Entity .function := ⟨"GO:0016172", "antifreeze activity"⟩
def caffeine : Entity .function := ⟨"GO:0102741", "caffeine synthase activity"⟩
def coleoidea := tx 6606 "Coleoidea"
def zea := tx 4577 "Zea mays"
def flaveria := tx 4227 "Flaveria trinervia"
def notothenioidei := tx 8205 "Notothenioidei"
def gadidae := tx 8045 "Gadidae"
def coffea := tx 49390 "Coffea canephora"
def camellia := tx 4442 "Camellia sinensis"

/-- H1 stated: "no animal makes carotenoids" is a `notRel` claim. What is missing is a rule: nothing
widens a negation (`predShape`), and nothing lets the aphid's positive record revise it. -/
def carotenoid : Entity .process := ⟨"GO:0016117", "carotenoid biosynthetic process"⟩
def metazoa := tx 33208 "Metazoa"
def h1Claim : Claim := .notRel Rel.capableOf (organism.inCtx { taxon := some metazoa }) carotenoid
#guard toString h1Claim == "¬(organism ⊓ in taxon (Metazoa) [NCBITaxon:131567&RO:0002162=(NCBITaxon:33208)] capable of carotenoid biosynthetic process [GO:0016117])"

/-! ## The rows -/

def rowsU : List Obs := [
  -- program 01, universal (U)
  { id := "U1", c := some ("cellular organisms", TranscriptionExample.cellularE_b.opinion),
    core := some TranscriptionExample.cellularE_b.opinion, note := "Examples/Transcription.lean cellularE_b (E1)" },
  ribosome.uni "U2" cellularOrganisms [ecoli, methanogens, yeast, human, arab],
  lactation.uni "LT1" mammalia [mouse, human, cow, platypus] (note := "platypus not imported") ]

def rowsO : List Obs := [
  -- program 01, override (O); the "-" row withholds the change record
  inexpressible "N1" "no kind or term for a mitochondrial genetic code (kindName)",
  inexpressible "N1-" "no kind or term for a mitochondrial genetic code (kindName)",
  inexpressible "N2" "no term for a codon assignment (kindName)",
  inexpressible "N2-" "no term for a codon assignment (kindName)",
  inexpressible "N3" "no term for a codon assignment (kindName)",
  inexpressible "N3-" "no term for a codon assignment (kindName)",
  inexpressible "N4" "no term for a codon assignment (kindName)",
  inexpressible "N4-" "no term for a codon assignment (kindName)",
  mito.row "L1" giardia metamonada euk4 (loss := some (.lit (mito.lossRec giardia 14614504 2003))),
  mito.row "L1-" giardia metamonada euk4,
  mito.row "L2" trichomonas metamonada euk4 (loss := some (.lit (mito.lossRec trichomonas 8790385 1996))),
  mito.row "L2-" trichomonas metamonada euk4,
  inexpressible "L3" "no GO class for 'mitochondrion or a related organelle'; Giardia and Trichomonas not imported",
  inexpressible "L3-" "no GO class for 'mitochondrion or a related organelle'; Giardia and Trichomonas not imported",
  mtRpo.row "L4" human human [reclinomonas, andalucia] (loss := some (.lit (mtRpo.lossRec human 7219534 1981)))
    (note := "jakobids not imported: no generalisation; the human record alone"),
  mtRpo.row "L4-" human human [reclinomonas, andalucia] (note := "jakobids not imported: no generalisation"),
  vitc.uni "L5" mammalia [mouse, rat, strepsirrhini] (note := "loss records cannot revise a universal"),
  vitc.uni "L5-" mammalia [mouse, rat, strepsirrhini],
  eye.row "L6" astyanax actinopterygii [zebrafish, human] (ownHas := true)
    (loss := some (.lit (eye.lossRec astyanax 10915628 2000))) (note := "surface and cave records on one taxon"),
  eye.row "L6-" astyanax actinopterygii [zebrafish, human] (ownHas := true),
  nucleus.uni "L7" mammalia [mouse, human] (note := "cell in mammals has part nucleus; the enucleate erythrocyte cannot enter"),
  haem.uni "L8" vertebrata [human, mouse, notothenia],
  haem.uni "L8-" vertebrata [human, mouse, notothenia],
  tooth.uni "L9" mammalia [human, mouse, cow],
  tooth.uni "L9-" mammalia [human, mouse, cow],
  homolRow "CV1" cameraEye vertebrata coleoidea (some (15289475, 2004)),
  homolRow "CV1-" cameraEye vertebrata coleoidea none,
  homolRow "CV2" echo.obj bats toothedWhales (some (20129037, 2010)),
  homolRow "CV2-" echo.obj bats toothedWhales none,
  homolRow "CV3" c4 zea flaveria (some (21414957, 2011)),
  homolRow "CV3-" c4 zea flaveria none,
  homolRow "CV4" antifreeze notothenioidei gadidae (some (9108061, 1997)),
  homolRow "CV4-" antifreeze notothenioidei gadidae none,
  { id := "H1", c := none, core := none,
    note := "stated as notRel (h1Claim); no rule widens a negation (predShape) or lets the aphid record revise it" },
  { id := "H1-", c := none, core := none,
    note := "stated as notRel (h1Claim); no rule widens a negation (predShape)" },
  inexpressible "A1" "no ancestor claim (shape)", inexpressible "A1-" "no ancestor claim (shape)" ]

def rowsP : List Obs := [
  -- program 01, predict (P)
  inexpressible "NT1" "no term for a nuclear genetic code (kindName)",
  actin.row "LT2" giardia metamonada [yeast, human, arab],
  vitc.row "LT3" mouse mouse [rat, strepsirrhini],
  homolRow "CVT1" cameraEye human mouse none,
  homolRow "CVT2" forelimb bats mouse none,
  liver.row "RMT1" mouse mouse [rat, human],
  gallbladder.row "RM1" rat rat [mouse, human],
  mhc2.row "RM2" mouse mouse [rat, human],
  cd4.row "RM3" mouse mouse [rat, human],
  vomit.row "RM4" rat rat [human] (note := "the mouse and guinea pig absences cannot enter"),
  sinusoid.row "RM5" mouse mouse [rat, human] ]

def rowsD : List Obs := [
  -- 01b: "-" own record withheld, "+" given
  mito.row "D01-" entamoeba amoebozoa (euk4 ++ [dicty]),
  mito.row "D01+" entamoeba amoebozoa (euk4 ++ [dicty]) (loss := some (.lit (mito.lossRec entamoeba 7604025 1995))),
  mtdna.row "D02-" henneguya cnidaria [myxobolus, human],
  mtdna.row "D02+" henneguya cnidaria [myxobolus, human] (loss := some (.lit (mtdna.lossRec henneguya 32094163 2020))),
  complex1.row "D03-" yeast yeast [candida, neurospora, human, arab],
  complex1.row "D03+" yeast yeast [candida, neurospora, human, arab] (loss := some (.lit (complex1.lossRec yeast 28801230 2018))),
  mtCox2.row "D04-" soybean rosids [human, dicty],
  mtCox2.row "D04+" soybean rosids [human, dicty] (loss := some (.lit (mtCox2.lossRec soybean 1382979 1992))),
  vitc.row "D05-" chimp chimp [mouse, rat, strepsirrhini] (note := "the human, macaque, guinea pig and Tarsius losses cannot enter"),
  vitc.row "D05+" chimp chimp [mouse, rat, strepsirrhini] (loss := some (.lit (vitc.lossRec chimp 10572964 1999))),
  cmah.row "D06-" human human [chimp, gorilla, mouse],
  cmah.row "D06+" human human [chimp, gorilla, mouse] (loss := some (.lit (cmah.lossRec human 9751737 1998))),
  tooth.row "D07-" chicken neognathae [alligator, human],
  tooth.row "D07+" chicken neognathae [alligator, human] (loss := some (tooth.lossTo chicken aves 25504730 2014))
    (note := "the Aves loss record reaches Gallus through notRelSub"),
  haem.row "D08-" icefish actinopterygii [notothenia, zebrafish, human],
  haem.row "D08+" icefish actinopterygii [notothenia, zebrafish, human]
    (loss := some (haem.lossTo icefish channichthyidae 7892183 1995)) (note := "the family loss record reaches the species through notRelSub"),
  photo.row "D09-" epifagus asterids [tobacco, arab],
  photo.row "D09+" epifagus asterids [tobacco, arab] (loss := some (.lit (photo.lossRec epifagus 1332054 1992))),
  homolRow "D10-" caffeine coffea camellia none,
  homolRow "D10+" caffeine coffea camellia (some (25190796, 2014)),
  echo.row "D11-" cow cow [bats, toothedWhales],
  echo.row "D11+" cow cow [bats, toothedWhales]
    (note := "the convergence record can be stated (convRec) but no rule carries it to cattle"),
  echo.row "D12-" typhlomys muroidea [bats, toothedWhales],
  echo.row "D12+" typhlomys muroidea [bats, toothedWhales] (ownHas := true),
  inexpressible "D13-" "no population slot (ctxFields)", inexpressible "D13+" "no population slot (ctxFields)",
  mandTooth.row "D14-" gastrotheca amphibia [axolotl, human] (note := "the frog absences cannot enter"),
  mandTooth.row "D14+" gastrotheca amphibia [axolotl, human] (ownHas := true),
  mtCytb.row "D15-" mouse mouse [human, cow],
  mtCytb.row "D15+" mouse mouse [human, cow] (ownHas := true) ]

/-! ## Textbook routes (today's core, real sentences)

Free narrowing of a stated universal to a member taxon, with one NCBI is_a statement. Round 3
supersedes round 2 where it has the sentence; `most` has no narrowing rule. -/

open BioLean.Textbook.R2 in
/-- TB1. "Plants are capable of photosynthesis" (photosynthesis-m45453-100, R2; no R3 record) gives
"Epifagus is capable of photosynthesis". Wolfe 1992: its plastid lacks every photosynthesis gene. -/
def tb1 : Derivation (.rel Rel.capableOf epifagus e_GO_0015979) :=
  .relChain (.lit (isaStmt epifagus e_NCBITaxon_33090)) (.lit Photosynthesis.photosynthesis_m45453_100)

open BioLean.Textbook.R2 in
/-- TB2, R2. "Plants have chloroplasts" (photosynthesis-m45453-72) gives Epifagus a chloroplast. -/
def tb2r2 : Derivation (.rel Rel.hasPart epifagus e_GO_0009507) :=
  .relChain (.lit (isaStmt epifagus e_NCBITaxon_33090)) (.lit Photosynthesis.photosynthesis_m45453_72)

open BioLean.Textbook.R2 in
-- TB2, R3: the sentence is `most`, and no rule narrows `most`.
#check_failure (Derivation.relChain (.lit (isaStmt epifagus e_NCBITaxon_33090))
  (.lit BioLean.Textbook.R3.Photosynthesis.photosynthesis_m45453_72) :
  Derivation (.rel Rel.hasPart epifagus e_GO_0009507))

open BioLean.Textbook.R2 in
/-- TB3, R2. "All mammals have teeth" (the-body-s-systems-m45535-39) gives baleen whales teeth. -/
def tb3r2 : Derivation (.rel Rel.hasPart mysticeti e_UBERON_0001091) :=
  .relChain (.lit (isaStmt mysticeti e_NCBITaxon_40674)) (.lit TheBodySSystemsA.the_body_s_systems_m45535_39)

open BioLean.Textbook.R2 in
-- TB3, R3: `most` again; nothing narrows it.
#check_failure (Derivation.relChain (.lit (isaStmt mysticeti e_NCBITaxon_40674))
  (.lit BioLean.Textbook.R3.TheBodySSystemsA.the_body_s_systems_m45535_39) :
  Derivation (.rel Rel.hasPart mysticeti e_UBERON_0001091))

open BioLean.Textbook.R2 in
/-- TB4. "Plants have mitochondria" (photosynthesis-m45453-71, R2; no R3 record) gives mistletoe
mitochondria: right. Viscum album lost complex I, not the organelle (Senkler 2018). -/
def tb4 : Derivation (.rel Rel.hasPart viscum e_GO_0005739) :=
  .relChain (.lit (isaStmt viscum e_NCBITaxon_33090)) (.lit Photosynthesis.photosynthesis_m45453_71)

def textbookRows : List Obs := [
  { id := "TB1", c := none, core := some tb1.opinion, note := "R2 photosynthesis-m45453-100 narrowed to Epifagus" },
  { id := "TB2", c := none, core := none, note := s!"R3 photosynthesis-m45453-72 is `most`: no narrowing (R2 would give {vstr (some tb2r2.opinion)})" },
  { id := "TB3", c := none, core := none, note := s!"R3 the-body-s-systems-m45535-39 is `most`: no narrowing (R2 would give {vstr (some tb3r2.opinion)})" },
  { id := "TB4", c := none, core := some tb4.opinion, note := "R2 photosynthesis-m45453-71 narrowed to Viscum album" } ]

def rows : List Obs := rowsU ++ rowsO ++ rowsP ++ rowsD

#eval IO.println ((rows ++ textbookRows).map Obs.line |> String.intercalate "\n")

/-! ## Pins: every row's verdicts, (c) then core

Each entry is (row, verdict of option (c), verdict of today's core); `none` where nothing is derived
or the case cannot be stated. Written from the observed output; a change to the core breaks the
group's line. One `#guard` per group, so each group is evaluated once. -/

def verdicts (os : List Obs) : List (String × Option Verdict × Option Verdict) :=
  os.map fun o => (o.id, verdictOf (o.c.map (·.2)), verdictOf o.core)

#guard verdicts rowsU == [
  ("U1", some .established, some .established),
  ("U2", some .established, some .established),
  ("LT1", some .unsupported, some .unsupported)]

#guard verdicts rowsO == [
  ("N1", none, none),
  ("N1-", none, none),
  ("N2", none, none),
  ("N2-", none, none),
  ("N3", none, none),
  ("N3-", none, none),
  ("N4", none, none),
  ("N4-", none, none),
  ("L1", some .unsupported, some .unsupported),
  ("L1-", some .unsupported, some .unsupported),
  ("L2", some .unsupported, some .unsupported),
  ("L2-", some .unsupported, some .unsupported),
  ("L3", none, none),
  ("L3-", none, none),
  ("L4", none, some .refuted),
  ("L4-", none, none),
  ("L5", some .unsupported, some .unsupported),
  ("L5-", some .unsupported, some .unsupported),
  ("L6", some .established, some .contested),
  ("L6-", some .established, some .established),
  ("L7", some .unsupported, some .unsupported),
  ("L8", some .unsupported, some .unsupported),
  ("L8-", some .unsupported, some .unsupported),
  ("L9", some .unsupported, some .unsupported),
  ("L9-", some .unsupported, some .unsupported),
  ("CV1", none, some .refuted),
  ("CV1-", none, none),
  ("CV2", none, some .refuted),
  ("CV2-", none, none),
  ("CV3", none, some .refuted),
  ("CV3-", none, none),
  ("CV4", none, some .refuted),
  ("CV4-", none, none),
  ("H1", none, none),
  ("H1-", none, none),
  ("A1", none, none),
  ("A1-", none, none)]

#guard verdicts rowsP == [
  ("NT1", none, none),
  ("LT2", some .unsupported, some .unsupported),
  ("LT3", some .unsupported, some .unsupported),
  ("CVT1", none, none),
  ("CVT2", none, none),
  ("RMT1", some .established, some .established),
  ("RM1", some .established, some .established),
  ("RM2", some .established, some .established),
  ("RM3", some .established, some .established),
  ("RM4", some .unsupported, some .unsupported),
  ("RM5", some .established, some .established)]

#guard verdicts rowsD == [
  ("D01-", some .unsupported, some .unsupported),
  ("D01+", some .unsupported, some .unsupported),
  ("D02-", some .unsupported, some .unsupported),
  ("D02+", some .unsupported, some .refuted),
  ("D03-", some .unsupported, some .unsupported),
  ("D03+", some .unsupported, some .unsupported),
  ("D04-", some .unsupported, some .unsupported),
  ("D04+", some .unsupported, some .refuted),
  ("D05-", some .unsupported, some .unsupported),
  ("D05+", some .unsupported, some .unsupported),
  ("D06-", some .established, some .established),
  ("D06+", some .established, some .contested),
  ("D07-", some .unsupported, some .unsupported),
  ("D07+", some .unsupported, some .refuted),
  ("D08-", some .unsupported, some .unsupported),
  ("D08+", some .unsupported, some .refuted),
  ("D09-", some .unsupported, some .unsupported),
  ("D09+", some .unsupported, some .refuted),
  ("D10-", none, none),
  ("D10+", none, some .refuted),
  ("D11-", some .unsupported, some .unsupported),
  ("D11+", some .unsupported, some .unsupported),
  ("D12-", some .unsupported, some .unsupported),
  ("D12+", some .established, some .established),
  ("D13-", none, none),
  ("D13+", none, none),
  ("D14-", some .unsupported, some .unsupported),
  ("D14+", some .established, some .established),
  ("D15-", some .established, some .established),
  ("D15+", some .established, some .established)]

#guard verdicts textbookRows == [
  ("TB1", none, some .established),
  ("TB2", none, none),
  ("TB3", none, none),
  ("TB4", none, some .established)]

/-! ## Kernel-checked pins on the key rows -/

def euarch := tx 314146 "Euarchontoglires"

/-- RM1. Mouse and human "establish" Euarchontoglires: biolib knows two children there, Glires and
Primates, and both are covered. Narrowing then gives the rat a gallbladder (it has none). -/
theorem rm1_rat_gallbladder :
    (gallbladder.narrow rat euarch (gallbladder.gen euarch [mouse, human] (by decide +kernel))).opinion.belief
      = 8 / 9 := by decide +kernel

/-- D06-. The same mechanism gives humans CMP-Neu5Ac hydroxylase, lost after the Homo-Pan split. -/
theorem d06_human_cmah :
    (cmah.narrow human euarch (cmah.gen euarch [chimp, mouse] (by decide +kernel))).verdict = .established := by
  decide +kernel

/-- D15-. And, rightly, gives the mouse a mitochondrial cytochrome b, from human and cow. -/
theorem d15_mouse_cytb :
    (mtCytb.narrow mouse boreo (mtCytb.gen boreo [human, cow] (by decide +kernel))).verdict = .established := by
  decide +kernel

/-- U2. Option (c) is incoherent on ribosomes as on transcription: "all cellular organisms have
ribosomes" is believed more than the narrower "all eukaryotes have ribosomes" it implies. -/
theorem u2_cellular_above_eukaryota :
    (ribosome.gen eukaryota [yeast, human, arab] (by decide +kernel)).opinion.belief <
      (ribosome.gen cellularOrganisms [ecoli, methanogens, yeast, human, arab] (by decide +kernel)).opinion.belief := by
  decide +kernel

/-- TB1. The textbook makes Epifagus photosynthetic. -/
theorem tb1_epifagus : tb1.verdict = .established := by decide +kernel

/-- TB4. The textbook gives mistletoe mitochondria: right. -/
theorem tb4_viscum : tb4.verdict = .established := by decide +kernel

/-- D06+. With the human CMAH loss entered, `clash` fuses it with the narrowed generalisation:
contested, not refuted. Fusion, not defeat. -/
theorem d06_clash_contested :
    (Derivation.clash (cmah.narrow human euarch (cmah.gen euarch [chimp, mouse] (by decide +kernel)))
      (.lit (cmah.lossRec human 9751737 1998))).verdict = .contested := by decide +kernel

/-- D07+. A clade's loss record reaches its members through `notRelSub`: the Aves record refutes
teeth in the chicken, with nothing on the other side. -/
theorem d07_inherited_loss :
    (tooth.lossTo chicken aves 25504730 2014).opinion.belief = 4 / 5 := by decide +kernel


/-! ## Review pins (2026-11-01) -/

-- L1. A loss record alone is exactly at θ (4/5)...
#guard (Derivation.lit (mito.lossRec giardia 14614504 2003)).opinion.belief == 4 / 5
-- ...and fused through `clash` with the weak narrowed generalisation from Eukaryota (belief about
-- 0.10), it drops below θ: unsupported, not refuted.
#guard (mito.row "L1" giardia metamonada euk4 (loss := some (.lit (mito.lossRec giardia 14614504 2003)))).core.map
  (fun o => decide (o.disbelief < 4 / 5) && decide (0 < o.belief)) == some true

/-- The 68 case taxa (`data/stress/01b/lineages.tsv`): 46 are outside the imported hierarchy. -/
def caseTaxa : List Nat := [562, 1423, 2095, 2759, 3702, 3847, 4097, 4177, 4227, 4442, 4577, 4932, 5141,
  5476, 5722, 5741, 5759, 5888, 6029, 6606, 7029, 7742, 7955, 7994, 8045, 8205, 8208, 8296, 8364, 8420,
  8459, 8496, 8782, 9031, 9258, 9397, 9443, 9476, 9544, 9593, 9598, 9606, 9722, 9761, 9913, 9971, 10090,
  10116, 10141, 28890, 30806, 33208, 36190, 40674, 44689, 48483, 49390, 59785, 69463, 131567, 314146,
  330779, 376911, 376913, 394453, 505711, 687454, 2049356]
#guard caseTaxa.length == 68
#guard ((caseTaxa.map fun n => tx n "").filter (!Taxa.known ·)).length == 46

end BioLean.Stress.Descent
