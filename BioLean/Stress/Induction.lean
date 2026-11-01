import BioLean.Derivation
import BioLean.Lib.TextbookClaimsR2.CellStructureAndFunction
import BioLean.Lib.TextbookClaimsR2.HowCellsObtainEnergy
import BioLean.Lib.TextbookClaimsR2.MolecularBiology
import BioLean.Lib.TextbookClaimsR2.Photosynthesis
import BioLean.Lib.TextbookClaimsR2.ReproductionAtTheCellularLevel
import BioLean.Lib.TextbookClaimsR2.TheBodySSystemsA
import BioLean.Lib.TextbookClaimsR2.TheBodySSystemsB
import BioLean.Lib.TextbookClaimsR2.TheCellularBasisOfInheritance
import BioLean.Lib.TextbookClaimsR3.CellStructureAndFunction
import BioLean.Lib.TextbookClaimsR3.HowCellsObtainEnergy
import BioLean.Lib.TextbookClaimsR3.MolecularBiology
import BioLean.Lib.TextbookClaimsR3.Photosynthesis
import BioLean.Lib.TextbookClaimsR3.ReproductionAtTheCellularLevel
import BioLean.Lib.TextbookClaimsR3.TheBodySSystemsA
import BioLean.Lib.TextbookClaimsR3.TheBodySSystemsB
import BioLean.Lib.TextbookClaimsR3.TheCellularBasisOfInheritance

/-!
# Stress set 10c: rule induction, against today's core

Program 10c (`docs/programs/10c-rule-induction.md`). Every case here uses the current core only
(`BioLean/*.lean`) and the built textbook libraries R2 and R3. Nothing here changes the core. The
prototype of a learned rule as a new derivation rule is `BioLean/Proto/Induction.lean`. The learners
themselves are Python (`scripts/stress/induction_mine.py`, AMIE 3.0 via `induction_amie.py`); the
task runner is `induction_tasks.py`, and `data/stress/10c/cases.tsv` is the table.

What this file pins, for each family of tasks:
- **A. Deduction suffices** (I01 to I06). The held-out sentence is a theorem of the others: the term
  the closure search found, checked by the kernel.
- **B. A class rule entered as a fact** (option A of the program: no core change). The learner's rule
  "every D has r to C" is the statement "D r C" at hypothesis weight; the is_a laws then specialise it.
  The kernel accepts the true and the false specialisations alike (it checks shape, not truth), and a
  stated negation defeats one through `clash`.
- **D. Taxon-wise** (I25, I26). The annotator's unrefined sentence plus the refinement axiom: one true,
  one false conclusion, both established. I37: the core's own induction rule, `generalize` (M4), widens a
  taxon context from instances, discounted by coverage, and gives no belief from one lineage.
- **C. Path rules** (I18 to I24). They need variables; the core's only rule table is `RO.chainOK`,
  pinned here for each learned chain.
- **F. Predicate invention** (I30). No constructor holds "abundant"; pinned by `#no_lean` and an
  exhaustive `shape`.
Pins: `#guard`, `theorem ... := by decide +kernel`. Each case prints `OBS <tab> case <tab> result`.
-/

namespace BioLean.Stress.Induction
open BioLean BioLean.Textbook Derivation

def obs (id msg : String) : IO Unit := IO.println s!"OBS\t{id}\t{msg}"
def vstr : Verdict → String
  | .established => "established" | .contested => "contested" | .refuted => "refuted"
  | .unsupported => "unsupported"
def ostr (o : Opinion) : String :=
  s!"b={o.belief.toDecimal 2} d={o.disbelief.toDecimal 2} u={o.uncertainty.toDecimal 2}"

/-- A learned class rule entered as a fact: evidence of kind `.hypothesis` (weight 0). -/
def hyp (id text : String) (c : Claim) : Statement :=
  { id := s!"learned:{id}", text, claim := c,
    evidence := [{ pmid := 0, year := 2026, kind := .hypothesis, note := "induction_mine.py class rule" }] }
/-- The same fact as if the book had said it (weight of a textbook sentence). -/
def asTextbook (s : Statement) : Statement :=
  { s with evidence := [{ pmid := 0, year := 2013, kind := .textbook, note := "counterfactual: stated" }] }
/-- An is_a edge of the imported ontology closure, as an axiom. Each use is guarded below by
`Ontology.isACurie`, so an edge that is not in `BioLean/Ontology/IsA.lean` fails the file. -/
def ax {k₁ k₂ : Kind} (a : Entity k₁) (b : Entity k₂) (h : Rel.isA.accepts k₁ k₂ = true := by decide) :
    Statement :=
  { id := s!"isa:{a.curie}<{b.curie}", text := s!"{a.label} is_a {b.label}", claim := .rel Rel.isA a b h,
    evidence := [{ pmid := 0, year := 2026, kind := .ontologyAxiom, note := "is_a closure, BioLean/Ontology/IsA.lean" }] }

/-- The shape of a claim. No wildcard on purpose: a new constructor (an abundance claim, an invented
predicate) makes this file fail to compile, which flips the INEXPRESSIBLE pins at once. -/
def shape : Claim → String
  | .effect .. => "effect" | .mediatedBy .. => "mediatedBy" | .noEffect .. => "noEffect"
  | .rel .. => "rel" | .notRel .. => "notRel" | .count .. => "count" | .atLeast .. => "atLeast"
  | .countBetween .. => "countBetween" | .cardinality .. => "cardinality" | .measure .. => "measure"
  | .atLeastMeasure .. => "atLeastMeasure" | .less .. => "less" | .produces .. => "produces"
  | .consumes .. => "consumes" | .yield .. => "yield" | .homeostasis .. => "homeostasis"
  | .quant _ c => s!"quant {shape c}"

/-- The rules. No wildcard: a rule that fires a learned rule (the prototype's `apply2`) or inverts a
relation breaks this. -/
def ruleName {c : Claim} : Derivation c → String
  | .lit .. => "lit" | .viaActivity .. => "viaActivity" | .viaAmount .. => "viaAmount" | .both .. => "both"
  | .relChain .. => "relChain" | .sequencesOver .. => "sequencesOver" | .pigeonhole .. => "pigeonhole"
  | .perSet .. => "perSet" | .fusionAdds .. => "fusionAdds" | .netYield .. => "netYield"
  | .compareIntervals .. => "compareIntervals" | .weaken .. => "weaken" | .notRelSub .. => "notRelSub"
  | .notRelObj .. => "notRelObj" | .refineMono .. => "refineMono" | .isaInheritEffect .. => "isaInheritEffect"
  | .transport .. => "transport" | .generalize .. => "generalize"

def chapters : List Lean.Name :=
  [`CellStructureAndFunction, `HowCellsObtainEnergy, `MolecularBiology, `Photosynthesis,
   `ReproductionAtTheCellularLevel, `TheBodySSystemsA, `TheBodySSystemsB, `TheCellularBasisOfInheritance]

open Lean Elab Command in
/-- `#no_lean name`: neither R2 nor R3 has a statement `name` in any chapter (all are imported). -/
elab "#no_lean " n:ident : command => do
  let env ← getEnv
  for pre in [`BioLean.Textbook.R2, `BioLean.Textbook.R3] do
    for c in chapters do
      unless env.isNamespace (pre ++ c) do throwError "{pre ++ c} is not imported"
      if env.contains (pre ++ c ++ n.getId) then
        throwError "{pre ++ c ++ n.getId} exists: the record now has Lean"

/-- Same claim, read as text (claims carry proofs, so they have no `DecidableEq`). -/
def same (c₁ c₂ : Claim) : Bool := toString c₁ == toString c₂

/-! ## A. Deduction suffices (fair cases: the core is right) -/

/-- I01 frontal lobe part_of brain (m45539-202), from m45539-395 and m45539-182 (part_of transitive). -/
def i01 := relChain (r₃ := Rel.partOf) (.lit R2.TheBodySSystemsB.the_body_s_systems_m45539_395)
  (.lit R2.TheBodySSystemsB.the_body_s_systems_m45539_182)
#guard same i01.claim R2.TheBodySSystemsB.the_body_s_systems_m45539_202.claim
theorem I01 : Established (claim i01) (4/5) := ⟨i01, by decide +kernel⟩

/-- I02 kidney has_part nephron (m45534-128, R2 reading), via the renal cortex (m45534-135, -137). -/
def i02 := relChain (r₃ := Rel.hasPart) (.lit R2.TheBodySSystemsA.the_body_s_systems_m45534_135)
  (.lit R2.TheBodySSystemsA.the_body_s_systems_m45534_137)
#guard same i02.claim R2.TheBodySSystemsA.the_body_s_systems_m45534_128.claim
theorem I02 : Established (claim i02) (4/5) := ⟨i02, by decide +kernel⟩

/-- I03 aneuploidy is lethal (m45467-119): aneuploidy is_a chromosomal disorder, which is lethal. -/
def i03 := isaInheritEffect (.lit R2.TheCellularBasisOfInheritance.the_cellular_basis_of_inheritance_m45467_2)
  (.lit R2.TheCellularBasisOfInheritance.the_cellular_basis_of_inheritance_m45467_4)
#guard same i03.claim R2.TheCellularBasisOfInheritance.the_cellular_basis_of_inheritance_m45467_119.claim
theorem I03 : Established (claim i03) (4/5) := ⟨i03, by decide +kernel⟩

/-- I04 chlorophyll absorbs light (m45448-90): chlorophyll is_a pigment (m45448-71), pigments absorb light. -/
def i04 := relChain (r₃ := Rel.capableOf) (.lit R2.Photosynthesis.photosynthesis_m45448_71)
  (.lit R2.Photosynthesis.photosynthesis_m45452_101)
#guard same i04.claim R2.Photosynthesis.photosynthesis_m45448_90.claim
theorem I04 : Established (claim i04) (4/5) := ⟨i04, by decide +kernel⟩

/-- I05 light reactions occur in the chloroplast (m45453-60): part_of photosynthesis, which occurs there. -/
def i05 := relChain (r₃ := Rel.occursIn) (.lit R2.Photosynthesis.photosynthesis_m45448_138)
  (.lit R2.CellStructureAndFunction.cell_structure_and_function_m45432_325)
#guard same i05.claim R2.Photosynthesis.photosynthesis_m45453_60.claim
theorem I05 : Established (claim i05) (4/5) := ⟨i05, by decide +kernel⟩

/-- I06 statins lower cholesterol (m45437-202): they inhibit HMG-CoA reductase, which raises it. -/
def i06 := viaActivity (.lit R2.HowCellsObtainEnergy.how_cells_obtain_energy_m45437_203)
  (.lit R2.HowCellsObtainEnergy.how_cells_obtain_energy_m45437_204)
#guard same i06.claim R2.HowCellsObtainEnergy.how_cells_obtain_energy_m45437_202.claim
theorem I06 : Established (claim i06) (16/25) := ⟨i06, by decide +kernel⟩
#guard i06.opinion.belief == 16 / 25   -- an effect chain multiplies: 4/5 × 4/5

/-! ## B. A learned class rule entered as a hypothesis fact (option A, no core change) -/

/-- I07 the learned rule "every cerebral lobe is part of the cerebral cortex" (support 4, PCA 0.8). -/
def lobeRule := hyp "I07" "cerebral lobe part_of cerebral cortex" (.rel Rel.partOf R2.e_UBERON_0016526 R2.e_UBERON_0000956)
#guard Ontology.isACurie "UBERON:0016525" "UBERON:0016526"
def i07 := relChain (r₃ := Rel.partOf) (.lit (ax R2.e_UBERON_0016525 R2.e_UBERON_0016526)) (.lit lobeRule)
#guard same i07.claim R2.TheBodySSystemsB.the_body_s_systems_m45539_395.claim
#guard i07.verdict == .unsupported     -- right shape, no belief until the rule is tested
/-- Tested: four leave-one-out confirmations (each lobe predicted from the other three), one
observational item each. Belief 8/10: established, exactly at θ. The weight is a choice. -/
def lobeRuleTested : Statement :=
  { lobeRule with evidence := List.replicate 4 { pmid := 0, year := 2026, kind := .observational, note := "LOO confirmation" } }
def i07t := relChain (r₃ := Rel.partOf) (.lit (ax R2.e_UBERON_0016525 R2.e_UBERON_0016526)) (.lit lobeRuleTested)
theorem I07_tested : Established (claim i07t) (4/5) := ⟨i07t, by decide +kernel⟩

/-- I09 aldosterone. The right class rule would be "anti-inflammatory drugs lower inflammation"
(docs/holes.md row 21). Through the book's role-as-is_a sentence "corticosteroids are
anti-inflammatory drugs" (m45538-200) and ChEBI's structural is_a (mineralocorticoid is_a
corticosteroid hormone is_a corticosteroid), aldosterone (m45537-149) becomes an anti-inflammatory
drug, and the core specialises the rule to it. Aldosterone promotes inflammation (Brown 2013). -/
def aidRule := hyp "I09" "anti-inflammatory drug lowers inflammation"
  (.effect R2.e_CHEBI_35472 .neg (.process R2.e_GO_0006954))
def corticosteroidHormone : Entity .chemical := ⟨"CHEBI:36699", "corticosteroid hormone"⟩
#guard Ontology.isACurie "CHEBI:25354" "CHEBI:36699"
#guard Ontology.isACurie "CHEBI:36699" "CHEBI:50858"
def aldoIsAID := relChain (r₃ := Rel.isA)
  (relChain (r₃ := Rel.isA) (.lit R2.TheBodySSystemsB.the_body_s_systems_m45537_149)
    (relChain (r₃ := Rel.isA) (.lit (ax R2.e_CHEBI_25354 corticosteroidHormone)) (.lit (ax corticosteroidHormone R2.e_CHEBI_50858))))
  (.lit R2.TheBodySSystemsB.the_body_s_systems_m45538_200)
#guard toString aldoIsAID.claim == "aldosterone [CHEBI:27584] is_a anti-inflammatory drug [CHEBI:35472]"
def i09pos := isaInheritEffect (.lit R2.TheBodySSystemsB.the_body_s_systems_m45538_199) (.lit aidRule)
def i09neg := isaInheritEffect aldoIsAID (.lit aidRule)
#guard same i09pos.claim R2.TheBodySSystemsB.the_body_s_systems_m45538_201.claim
#guard toString i09neg.claim == "aldosterone [CHEBI:27584] →− inflammatory response [GO:0006954]"
#guard i09pos.verdict == .unsupported && i09neg.verdict == .unsupported
/-- Had the book stated the rule, the core would establish the false claim at 0.8. -/
def i09negStated := isaInheritEffect aldoIsAID (.lit (asTextbook aidRule))
theorem I09_false_established : Established (claim i09negStated) (4/5) := ⟨i09negStated, by decide +kernel⟩

/-- I10 cell walls. m45432-355 is the glossary entry "cell wall: a rigid cell covering made of cellulose in
plants, peptidoglycan in bacteria, non-peptidoglycan compounds in Archaea, and chitin in fungi". Its round-2
annotation has the plant context, but the round-2 Lean statement dropped it: "cell wall has_part cellulose",
for every cell wall. Round 3 refines it to plants, and the closure uses round 3. The R2 statement is still in
the library, and with the refinement axiom it establishes "the bacterial cell wall contains cellulose" at 0.8.
That is false: bacterial walls are peptidoglycan (m45429-21, and the same sentence). -/
def i10neg := relChain (r₃ := Rel.hasPart) (.lit (Entity.refineAxiom R2.e_GO_0005618 Rel.inTaxon R2.e_NCBITaxon_2))
  (.lit R2.CellStructureAndFunction.cell_structure_and_function_m45432_355)
#guard toString i10neg.claim == toString (Claim.rel Rel.hasPart (R2.e_GO_0005618.inCtx { taxon := R2.e_NCBITaxon_2 }) R2.e_CHEBI_18246)
theorem I10_R2_false_established : Established (claim i10neg) (4/5) := ⟨i10neg, by decide +kernel⟩
/- With round 3's reading, the same step needs a subject refined to plants; bacteria do not match. -/
#guard toString R3.CellStructureAndFunction.cell_structure_and_function_m45432_355.claim ==
  toString (Claim.rel Rel.hasPart (R2.e_GO_0005618.inCtx { taxon := R2.e_NCBITaxon_33090 }) R2.e_CHEBI_18246)

/-- I12 islet cells: the learned rule "every secretory cell is part of the islet" (support 2, PCA 1.0)
specialises to beta cells (true) and to thyroid follicular cells (false) with the same opinion. -/
def isletRule := hyp "I12" "secretory cell part_of pancreatic islet" (.rel Rel.partOf R3.e_CL_0000151 R2.e_UBERON_0000006)
#guard Ontology.isACurie "CL:0000169" "CL:0000151" && Ontology.isACurie "CL:0002258" "CL:0000151"
def i12pos := relChain (r₃ := Rel.partOf) (.lit (ax R2.e_CL_0000169 R3.e_CL_0000151)) (.lit isletRule)
def i12neg := relChain (r₃ := Rel.partOf) (.lit (ax R2.e_CL_0002258 R3.e_CL_0000151)) (.lit isletRule)
#guard same i12pos.claim R2.TheBodySSystemsB.the_body_s_systems_m45537_196.claim
#guard i12pos.opinion.belief == i12neg.opinion.belief

/-- I13 ploidy: "every reproductive process lowers ploidy" specialises to fertilisation (false;
m45465-58 says it restores diploidy). -/
def ploidyRule := hyp "I13" "reproductive process lowers ploidy" (.effect (⟨"GO:0022414", "reproductive process"⟩ : Entity .process) .neg (.phenotype R2.e_PATO_0001374))
#guard Ontology.isACurie "GO:0009566" "GO:0022414" && Ontology.isACurie "GO:0007127" "GO:0022414"
def i13neg := isaInheritEffect (.lit (ax R2.e_GO_0009566 (⟨"GO:0022414", "reproductive process"⟩ : Entity .process))) (.lit ploidyRule)
#guard toString i13neg.claim == "fertilization [GO:0009566] →− ploidy [PATO:0001374]"

/-- I17 and I35 nucleus: a learned "every cell has a nucleus" reaches prokaryotes through CL's is_a,
and the book's negation (m45429-15) defeats it: `clash` gives refuted. For mature mammalian red cells
the library states no negation, so nothing defeats the same step. -/
def nucleusRule := hyp "I35" "cell has_part nucleus" (.rel Rel.hasPart R2.e_CL_0000000 R2.e_GO_0005634)
#guard Ontology.isACurie "CL:0000520" "CL:0000000" && Ontology.isACurie "CL:0000232" "CL:0000000"
def i35 := relChain (r₃ := Rel.hasPart) (.lit (ax R2.e_CL_0000520 R2.e_CL_0000000)) (.lit nucleusRule)
#guard same i35.claim (Claim.rel Rel.hasPart R2.e_CL_0000520 R2.e_GO_0005634)
#guard (clash i35 (.lit R2.CellStructureAndFunction.cell_structure_and_function_m45429_15)).verdict == .refuted
/- Even at textbook weight the negation wins only to contested: the clash is visible. -/
#guard (clash (relChain (r₃ := Rel.hasPart) (.lit (ax R2.e_CL_0000520 R2.e_CL_0000000)) (.lit (asTextbook nucleusRule)))
  (.lit R2.CellStructureAndFunction.cell_structure_and_function_m45429_15)).verdict == .contested
def mammalRBC := R2.e_CL_0000232.inCtx { taxon := R2.e_NCBITaxon_40674 }
def i17rbc := relChain (r₃ := Rel.hasPart)
  (relChain (r₃ := Rel.isA) (.lit (Entity.refineAxiom R2.e_CL_0000232 Rel.inTaxon R2.e_NCBITaxon_40674)) (.lit (ax R2.e_CL_0000232 R2.e_CL_0000000)))
  (.lit nucleusRule)
#guard same i17rbc.claim (Claim.rel Rel.hasPart mammalRBC R2.e_GO_0005634)

/-! ## C. Path rules: the core's rule table is RO, and the learned chains are not in it -/

def derivesFrom : Rel := ⟨.ro, 1000, false⟩
#guard RO.chainOK Rel.hasOutput derivesFrom Rel.hasInput == false        -- I18 (true biology)
#guard RO.chainOK derivesFrom Rel.capableOf Rel.capableOf == false       -- I19 (false: descent as analogy)
#guard RO.chainOK Rel.hasPart Rel.capableOf Rel.capableOf == false       -- I22 (over-strong)
#guard RO.chainOK Rel.hasPart Rel.capableOf ⟨.ro, 2584, false⟩ == true   -- I22: RO's sound form
#guard RO.chainOK Rel.partOf Rel.capableOf Rel.involvedIn == false       -- I23 (over-strong)
#guard RO.chainOK Rel.partOf Rel.capableOf ⟨.ro, 2329, false⟩ == true    -- I23: RO's sound form
#guard RO.inverseOK Rel.hasPart Rel.partOf                               -- I20: RO knows the inverse ...
-- ... and no rule uses it: `ruleName` above lists every rule, and none inverts.

/-- I22. The task asks for "the chloroplast is capable of photosynthesis" (m45432-229, held out); no
compiled sentence gives the chloroplast a part capable of it, so there is no chloroplast instance of RO's
sound form. The nearest real instance: the core concludes "the brain has a part that is capable of memory"
(RO:0002584) from m45539-175 and m45539-242. It does not conclude "the brain is capable of memory". -/
def i22ro := relChain (r₃ := ⟨.ro, 2584, false⟩) (.lit R2.TheBodySSystemsB.the_body_s_systems_m45539_175)
  (.lit R2.TheBodySSystemsB.the_body_s_systems_m45539_242)
theorem I22_sound_form : Established (claim i22ro) (4/5) := ⟨i22ro, by decide +kernel⟩

/-! ## F. Predicate invention: the G1 hole -/

#no_lean cell_structure_and_function_m45432_203   -- muscle cells, many mitochondria
#no_lean cell_structure_and_function_m45432_189   -- immature red cells, many ribosomes
#no_lean cell_structure_and_function_m45432_155   -- secretory cells, abundant Golgi
#no_lean cell_structure_and_function_m45432_353   -- secretory tissues, abundant Golgi
#guard (shape (.atLeast R2.e_CL_0000187 R2.e_GO_0005739 2)) == "atLeast"   -- the nearest form needs a number

/-! ## D. Taxon-wise rules: an annotator's class rule, specialised by the refinement axiom -/

/-- The (relation, subject, object) curies of a `rel` claim: compares claims whose labels differ. -/
def relKey : Claim → String
  | .rel r a b _ => s!"{r.curie} {a.curie} {b.curie}"
  | .notRel r a b _ => s!"not {r.curie} {a.curie} {b.curie}"
  | c => toString c

/-- I25 (FAIL). "A chromosome is a structure within the nucleus that is made up of DNA, the hereditary material,
and proteins" (m45432-100) is annotated as "chromosome located_in nucleus", for every chromosome. With the
refinement axiom (chromosome ⊓ in taxon Bacteria is_a chromosome) the core establishes, at 0.8, that the
bacterial chromosome is located in a nucleus. Bacteria have no nucleus (m45429-15); their chromosome sits in
the nucleoid (m45473-76). The closure search derives the same fact (`induction_tasks.py`, I25). -/
def i25neg := relChain (r₃ := Rel.locatedIn) (.lit (Entity.refineAxiom R2.e_GO_0005694 Rel.inTaxon R2.e_NCBITaxon_2))
  (.lit R2.CellStructureAndFunction.cell_structure_and_function_m45432_100)
#guard relKey i25neg.claim == "RO:0001025 GO:0005694&RO:0002162=(NCBITaxon:2) GO:0005634"
theorem I25_false_established : Established (claim i25neg) (4/5) := ⟨i25neg, by decide +kernel⟩
/- No clash is possible: the book's negation is `¬ (prokaryotic cell has_part nucleus)`, a different claim,
and `clash` needs the same claim on both sides. Nothing links located_in on a part to has_part on the whole. -/
#guard shape R2.CellStructureAndFunction.cell_structure_and_function_m45429_15.claim == "notRel"
#guard relKey R2.CellStructureAndFunction.cell_structure_and_function_m45429_15.claim == "not BFO:0000051 CL:0000520 GO:0005634"

/-- I26 (PASS). The same step, for eukaryotes, re-derives the held-out m45455-16. -/
def i26pos := relChain (r₃ := Rel.locatedIn) (.lit (Entity.refineAxiom R2.e_GO_0005694 Rel.inTaxon R2.e_NCBITaxon_2759))
  (.lit R2.CellStructureAndFunction.cell_structure_and_function_m45432_100)
#guard relKey i26pos.claim == relKey R3.ReproductionAtTheCellularLevel.reproduction_at_the_cellular_level_m45455_16.claim
theorem I26 : Established (claim i26pos) (4/5) := ⟨i26pos, by decide +kernel⟩

/-! ## D, continued. The core already has one induction rule: `generalize` (M4) -/

/-- I37 (PASS). Widen a taxon rule from instances. "Ribosomes are located in the cytoplasm in prokaryotes and in
the cytoplasm and endoplasmic reticulum of eukaryotes" (m45479-20, -21; round 3 maps "prokaryotes" to Bacteria).
`generalize` fuses the two instances (8/9) and discounts by bracketing coverage of cellular organisms: 2 of its 3
NCBI children (Archaea unsampled), so belief 16/27, unsupported. True biology, and the core concludes it with no
new rule. Its neg: "every chromosome of a cellular organism is in a nucleus", from the eukaryote instance
(m45455-16) alone. One lineage brackets nothing, so the same step gives belief 0. Compare I25, where the unrefined
m45432-100 plus the refinement axiom gives the false bacterial case at 0.8: specialisation is free, widening is not. -/
def inCytoplasm : Predicate .component := .rel Rel.locatedIn R2.e_GO_0005737
def i37pos := generalize inCytoplasm {} Taxa.cellularOrganisms .bracketing [R2.e_NCBITaxon_2, R2.e_NCBITaxon_2759]
  (fun | ⟨0, _⟩ => .lit R3.MolecularBiology.molbio_m45479_20 | ⟨1, _⟩ => .lit R3.MolecularBiology.molbio_m45479_21)
#guard relKey i37pos.claim == "RO:0001025 GO:0005840&RO:0002162=(NCBITaxon:131567) GO:0005737"
theorem I37_value : i37pos.opinion.belief = 16 / 27 := by decide +kernel
theorem I37_unsupported : i37pos.verdict = .unsupported := by decide +kernel
def inNucleus : Predicate .component := .rel Rel.locatedIn R2.e_GO_0005634
def i37neg := generalize inNucleus {} Taxa.cellularOrganisms .bracketing [R2.e_NCBITaxon_2759]
  (fun | ⟨0, _⟩ => .lit R3.ReproductionAtTheCellularLevel.reproduction_at_the_cellular_level_m45455_16)
#guard relKey i37neg.claim == "RO:0001025 GO:0005694&RO:0002162=(NCBITaxon:131567) GO:0005634"
theorem I37_one_lineage_no_belief : i37neg.opinion.belief = 0 := by decide +kernel

/-! ## B, continued. Two more learned class rules, entered as hypothesis facts -/

/-- I11. The learner's rule "every cell cycle phase is part of mitotic nuclear division" (LATTICE: GO's
least general class over the four phases is 'cell cycle phase'). It specialises to metaphase (true, the
held-out m45461-202) and to S phase (false: S phase is part of interphase, m45461-211) alike. -/
def cellCyclePhase : Entity .process := ⟨"GO:0022403", "cell cycle phase"⟩
def phaseRule := hyp "I11" "cell cycle phase part_of mitotic nuclear division" (.rel Rel.partOf cellCyclePhase R2.e_GO_0140014)
#guard Ontology.isACurie "GO:0000089" "GO:0022403" && Ontology.isACurie "GO:0051320" "GO:0022403"
def i11pos := relChain (r₃ := Rel.partOf) (.lit (ax R2.e_GO_0000089 cellCyclePhase)) (.lit phaseRule)
def i11neg := relChain (r₃ := Rel.partOf) (.lit (ax R2.e_GO_0051320 cellCyclePhase)) (.lit phaseRule)
#guard relKey i11pos.claim == relKey R2.ReproductionAtTheCellularLevel.reproduction_at_the_cellular_level_m45461_202.claim
#guard relKey i11neg.claim == "BFO:0000050 GO:0051320 GO:0140014"
#guard i11pos.opinion.belief == i11neg.opinion.belief && i11neg.verdict == .unsupported

/-- I15. "Every metabolic process raises ATP" (LATTICE) specialises to glycolysis (true, the held-out
m45440-75) and to gluconeogenesis and glycogen synthesis (false: both spend ATP; Reactome R-HSA-70263). -/
def atpRule := hyp "I15" "metabolic process raises ATP" (.effect R2.e_GO_0008152 .pos (.amount R2.e_CHEBI_15422))
#guard Ontology.isACurie "GO:0006096" "GO:0008152" && Ontology.isACurie "GO:0006094" "GO:0008152" &&
  Ontology.isACurie "GO:0005978" "GO:0008152"
def i15pos := isaInheritEffect (.lit (ax R2.e_GO_0006096 R2.e_GO_0008152)) (.lit atpRule)
def i15neg := isaInheritEffect (.lit (ax R2.e_GO_0006094 R2.e_GO_0008152)) (.lit atpRule)
def i15neg2 := isaInheritEffect (.lit (ax R2.e_GO_0005978 R2.e_GO_0008152)) (.lit atpRule)
#guard same i15pos.claim R2.HowCellsObtainEnergy.how_cells_obtain_energy_m45440_75.claim
#guard i15pos.opinion.belief == i15neg.opinion.belief && i15neg.opinion.belief == i15neg2.opinion.belief

/-! ## F, continued. The nearest form of the G1 conclusion -/

/-- I30. `Claim.less a b q` ("every a is below every b in quality q") is the nearest constructor. With an
EQ-style quality built by refinement (PATO:0001555 'has number of', towards mitochondrion; RO:0002503) the
claim typechecks. But the only comparison class CL offers is 'cell', and muscle cell is_a cell, so this says
every muscle cell has fewer mitochondria than itself: false as written. No CL term means "other cells", and
the only rule that concludes `less` is `compareIntervals`, from two measured intervals. So the conclusion has
no faithful form, and the rule (demand, so abundance) has none at all. -/
def towards : Rel := ⟨.ro, 2503, false⟩
def hasNumberOf : Entity .phenotype := ⟨"PATO:0001555", "has number of"⟩
def nMito : Entity .phenotype := hasNumberOf.refine towards R2.e_GO_0005739
def g1Nearest : Claim := .less R2.e_CL_0000000 R2.e_CL_0000187 nMito
#guard nMito.curie == "PATO:0001555&RO:0002503=(GO:0005739)"
#guard shape g1Nearest == "less" && Ontology.isACurie "CL:0000187" "CL:0000000"

#eval do
  obs "I01" s!"closure term relTrans(m45539-395, m45539-182): {i01.claim} {ostr i01.opinion} {vstr i01.verdict}"
  obs "I02" s!"closure term relTrans(m45534-135, m45534-137): {ostr i02.opinion} {vstr i02.verdict}"
  obs "I03" s!"closure term isaInheritEffect(m45467-2, m45467-4): {ostr i03.opinion} {vstr i03.verdict}"
  obs "I04" s!"closure term isaInherit(m45448-71, m45452-101): {ostr i04.opinion} {vstr i04.verdict}"
  obs "I05" s!"closure term relChain(m45448-138, m45432-325): {ostr i05.opinion} {vstr i05.verdict}"
  obs "I06" s!"closure term viaActivity(m45437-203, m45437-204): {ostr i06.opinion} {vstr i06.verdict}"
  obs "I07" s!"class rule as hypothesis fact: {i07.claim} {ostr i07.opinion} {vstr i07.verdict}; with 4 LOO tests {ostr i07t.opinion} {vstr i07t.verdict}"
  obs "I09" s!"pos {i09pos.claim} {vstr i09pos.verdict}; neg {i09neg.claim} {vstr i09neg.verdict}; neg if stated: {vstr (isaInheritEffect aldoIsAID (.lit (asTextbook aidRule))).verdict}"
  obs "I10" s!"R2 m45432-355 + refinement axiom: {i10neg.claim} {ostr i10neg.opinion} {vstr i10neg.verdict}"
  obs "I12" s!"pos {i12pos.claim} and neg {i12neg.claim}, same opinion {ostr i12neg.opinion}"
  obs "I13" s!"neg {i13neg.claim} {vstr i13neg.verdict}"
  obs "I35" s!"{i35.claim} clashes with m45429-15: {vstr (clash i35 (.lit R2.CellStructureAndFunction.cell_structure_and_function_m45429_15)).verdict}"
  obs "I17" s!"{i17rbc.claim}: no negation in the library, {vstr i17rbc.verdict} (no clash possible)"
  obs "I22" s!"RO:0002584 sound form: {i22ro.claim} {vstr i22ro.verdict}"
  obs "I25" s!"refineAxiom + m45432-100: {i25neg.claim} {ostr i25neg.opinion} {vstr i25neg.verdict}"
  obs "I26" s!"same step for Eukaryota re-derives m45455-16: {vstr i26pos.verdict}"
  obs "I37" s!"generalize from Bacteria and Eukaryota: {i37pos.claim} {ostr i37pos.opinion} {vstr i37pos.verdict}; from Eukaryota alone: {i37neg.claim} {ostr i37neg.opinion}"
  obs "I11" s!"pos {i11pos.claim} and neg {i11neg.claim}: same opinion {ostr i11neg.opinion}"
  obs "I15" s!"pos {i15pos.claim}; neg {i15neg.claim}; neg {i15neg2.claim}: same opinion {ostr i15neg.opinion}"
  obs "I30" s!"nearest form typechecks but is false as written: {g1Nearest}"
  obs "I30" "no R2 or R3 statement for m45432-203, -189, -155, -353; no abundance constructor"

end BioLean.Stress.Induction
