import BioLean.Derivation
import BioLean.Lib.Entities
import BioLean.Lib.TextbookClaimsR2.CellStructureAndFunction
import BioLean.Lib.TextbookClaimsR2.Photosynthesis
import BioLean.Lib.TextbookClaimsR2.TheBodySSystemsA
import BioLean.Lib.TextbookClaimsR2.TheBodySSystemsB
import BioLean.Lib.TextbookClaimsR2.HowCellsObtainEnergy
import BioLean.Lib.TextbookClaimsR2.MolecularBiology
import BioLean.Lib.TextbookClaimsR2.ReproductionAtTheCellularLevel
import BioLean.Lib.TextbookClaimsR2.TheCellularBasisOfInheritance
import BioLean.Lib.TextbookClaimsR3.CellStructureAndFunction
import BioLean.Lib.TextbookClaimsR3.TheBodySSystemsA
import BioLean.Lib.TextbookClaimsR3.TheBodySSystemsB
import BioLean.Lib.TextbookClaimsR3.MolecularBiology
import BioLean.Lib.TextbookClaimsR3.ReproductionAtTheCellularLevel
import BioLean.Lib.TextbookClaimsR3.Photosynthesis
import BioLean.Lib.TextbookClaimsR3.HowCellsObtainEnergy
import BioLean.Lib.TextbookClaimsR3.TheCellularBasisOfInheritance

/-!
# Program 04: catching annotation errors (stress set, Lean half)

What the current core does with known annotation errors, pinned so a change to the core flips a case
visibly. Case ids match `data/stress/04/cases.tsv`; the doc is `docs/programs/04-annotation-errors.md`.
The Python half (every mutant through the closure and the ontology checks) is `scripts/stress/mutants_*.py`.

* §1 the real errors (R1 to R6) and the real errors this program found (R7 to R10; R11 to R16 are pinned in §5);
* §2 Lean typing on seeded errors: the 7 mutants Lean rejects, and the gaps it lets through;
* §3 `Statement.taxonConsistent`: silent on every textbook statement, right on literature-style ones;
* §4 prototype lints (NOT core: they live only in this file) using data the core already imports:
  `Ontology.retired`, `Ontology.isACurie`, `Ontology.known`, `Ontology.label?`, `RO.inverses`;
* §5 review additions (2026-11-01): pins for R7 (third statement), R8, R9, R11 to R16, the exact reason for
  each typing gap, option C as a lint outside the core (`Review.sigLint`, run over every compiled statement),
  P3 (option D2 imports a wrong ontology axiom: FAIL) and I2 (a life-stage-qualified negation: INEXPRESSIBLE).

Marks in comments: PASS (right conclusion), FAIL (wrong), SILENT (no conclusion where one is due),
INEXPRESSIBLE (cannot be stated).
-/

namespace BioLean.Stress.AnnotationErrors
open BioLean BioLean.Textbook.R2 BioLean.Textbook.R3

/-! ## Aliases for the compiled statements used here (round 2 = before the fixes, round 3 = after) -/

def r2_318 := Textbook.R2.CellStructureAndFunction.cell_structure_and_function_m45432_318
def r3_318 := Textbook.R3.CellStructureAndFunction.cell_structure_and_function_m45432_318
def r2_68 := Textbook.R2.CellStructureAndFunction.cell_structure_and_function_m45432_68
def r3_75 := Textbook.R3.CellStructureAndFunction.cell_structure_and_function_m45432_75
def r2_261 := Textbook.R2.CellStructureAndFunction.cell_structure_and_function_m45432_261
def r2_39 := Textbook.R2.TheBodySSystemsA.the_body_s_systems_m45535_39
def r3_39 := Textbook.R3.TheBodySSystemsA.the_body_s_systems_m45535_39
def r2_52 := Textbook.R2.TheBodySSystemsB.the_body_s_systems_m45537_52
def r3_53 := Textbook.R3.TheBodySSystemsB.the_body_s_systems_m45537_53
def r3_71 := Textbook.R3.MolecularBiology.molbio_m45475_71
def r2_12 := Textbook.R2.CellStructureAndFunction.cell_structure_and_function_m45428_12
def r2_218 := Textbook.R2.CellStructureAndFunction.cell_structure_and_function_m45432_218
def r2_148 := Textbook.R2.Photosynthesis.photosynthesis_m45448_148
def r2_95 := Textbook.R2.Photosynthesis.photosynthesis_m45448_95
def r2_71 := Textbook.R2.Photosynthesis.photosynthesis_m45448_71
def r3_33 := Textbook.R3.ReproductionAtTheCellularLevel.reproduction_at_the_cellular_level_m45461_33
def r2_9 := Textbook.R2.CellStructureAndFunction.cell_structure_and_function_m45429_9
def r3_9 := Textbook.R3.CellStructureAndFunction.cell_structure_and_function_m45429_9
def r2_11 := Textbook.R2.CellStructureAndFunction.cell_structure_and_function_m45429_11
def r3_11 := Textbook.R3.CellStructureAndFunction.cell_structure_and_function_m45429_11

/-- The quantifier of a claim, if any. -/
def quantOf : Claim → Option Quantifier
  | .quant q _ => some q
  | _ => none

/-! ## §1 Real errors

### R1. The centrosome (cell-structure-and-function-m45432-318), context dropped. PASS (by the clash).
Round 2 says every cell has a centrosome. With "centrosomes have centrioles" (m45432-68), transitivity,
and the refinement axiom "a plant cell is a cell", Lean derives "a plant cell has a centriole", which
clashes with "plant cells lack centrioles" (m45432-75). This is how the closure found it. -/

example : r2_318.claim.subjectCurie = "CL:0000000" := by decide          -- the bug: no taxon
#guard Ctx.taxonOfCurie r3_318.claim.subjectCurie == some "NCBITaxon:33208"           -- the fix: Metazoa

def cellHasCentriole : Derivation (.rel Rel.hasPart e_CL_0000000 e_GO_0005814) :=
  .relChain (.lit r2_318) (.lit r2_68)

def plantCellHasCentriole :
    Derivation (.rel Rel.hasPart (e_CL_0000000.inCtx { taxon := e_NCBITaxon_33090 }) e_GO_0005814) :=
  .relChain (.lit (e_CL_0000000.refineAxiom Rel.inTaxon e_NCBITaxon_33090)) cellHasCentriole

/-- The clash, read as one opinion about "a plant cell has a centriole". -/
def centrosomeClash : Opinion := Derivation.clash plantCellHasCentriole (.lit r3_75)

theorem R1_centrosome_contested : centrosomeClash.verdict = .contested := by decide +kernel

/-- After the fix the animal-cell claim cannot reach plant cells: Viridiplantae is not under Metazoa, so
neither the refinement axiom nor `refineMono` links them. -/
example : Taxa.isA "NCBITaxon:33090" "NCBITaxon:33208" = false := by decide

/-! ### R2. "All mammals have teeth" (the-body-s-systems-m45535-39). Core: SILENT on the universal.
Round 2 has the universal; round 3 weakens it to `most`. Nothing in the textbook says a toothless mammal
exists, so no clash; Lean typing accepts it; UBERON's never_in_taxon (Mysticeti, Tachyglossidae,
Ornithorhynchus, Aves) would catch it but is not imported. Review note: two of those three mammal constraints are
false at some life stage (platypus juveniles have teeth, P3 in §5; baleen whale fetuses have tooth germs, I2). The exact form, "mammals except baleen whales,
anteaters, pangolins", is INEXPRESSIBLE: a context refines, it cannot subtract a clade. -/

example : quantOf r2_39.claim = none := by decide                      -- the universal, accepted
example : quantOf r3_39.claim = some .most := by decide                -- the fix
example : Rel.hasPart.accepts .taxon .anatomy = true := by decide       -- typing cannot object

/-! ### R3. Round 1's direction reversal (cell-structure-and-function-m45432-261). SILENT.
Round 1 compiled "Aerobic bacteria became mitochondria" as `mitochondrion derives_into Bacteria`. The
round-1 library is not built, so the statement is restated here verbatim from
`BioLean/Lib/TextbookClaims/CellStructureAndFunction.lean`. Round 2 has `derives_from`, the right way. -/

def r1_261 : Statement where
  id := "cell-structure-and-function-m45432-261"
  text := "Aerobic bacteria became mitochondria"
  claim := .rel ⟨.ro, 1001, false⟩ e_GO_0005739 e_NCBITaxon_2
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, note := "round 1, restated" }]

example : (⟨.ro, 1001, false⟩ : Rel).accepts .component .taxon = true := by decide  -- typing accepts it
example : r2_261.claim.subjectCurie = r1_261.claim.subjectCurie := by decide        -- same order, relation flipped
/-- RO knows the two are inverses, but no rule uses it: `relInv` was removed on purpose (class-level
claims do not invert). So the R1 and R2 forms side by side are not even a clash. -/
example : RO.inverseOK ⟨.ro, 1000, false⟩ ⟨.ro, 1001, false⟩ = true := by decide

/-! ### R4. PR:000009054 for insulin (the-body-s-systems-m45537-52, -53). SILENT in the core.
PR's label for PR:000009054 is "preproinsulin": the gene-level class of every INS product. Mature insulin
is PR:000050339 "insulin hormone" (is_a proinsulin, OLS4 2026-10-31). So the error is a term that is too
general. The core imports the PR label, so a label lint can see the mismatch with the emitted label
"insulin"; the right term is not in the import at all, because nothing uses it yet. -/

example : e_PR_000009054.label = "insulin" := by decide
example : (Curie.encode "PR:000009054").bind Ontology.label? = some "preproinsulin" := by decide
example : (Curie.encode "PR:000050339").map Ontology.known = some false := by decide   -- not imported

/-! ### R5. The area postrema digit slip (UBERON:0002163 is the inferior cerebellar peduncle). SILENT.
Fixed in `Lib/Entities.lean`. Restated as a mutant: Lean accepts any anatomy curie. The id is no longer
used anywhere, so it is outside the imported closure (`known` is false), the only trace in the core. -/

example : Lib.areaPostrema.curie = "UBERON:0002162" := by decide                  -- the fix
def areaPostremaSlip : Entity .anatomy := ⟨"UBERON:0002163", "area postrema"⟩     -- the old error
example : (Curie.encode areaPostremaSlip.curie).map Ontology.known = some false := by decide
example : (Curie.encode "UBERON:0002162").bind Ontology.label? = some "area postrema" := by decide

/-! ### R6. Obsolete CL:0002371 somatic cell (molbio-m45475-71). SILENT in the core.
The core lists the retired term (`Ontology.retired`), but no rule or lint reads that list. -/

example : (Ontology.retired.lookup (2, 2371)).isSome = true := by decide
#guard r3_71.taxonConsistent                                              -- the only statement lint: silent

/-! ### R7 to R10. Real errors this program found in the live data (by the outside checks; R11 to R16 in §5)
R7 CL:0000548 "animal cell" is obsolete, still used (m45428-12, m45432-215, m45432-218).
R8 "every thylakoid is part of a chloroplast" (photosynthesis-m45448-148): GO:0009579 includes
   cyanobacterial thylakoids; the sentence means chloroplast thylakoid (GO:0009534).
R9 "the Calvin cycle occurs in the chloroplast stroma" (m45448-95): bacteria run it too; plant context dropped.
R10 "chlorophyll is_a pigment" (m45448-71): ChEBI's "biological pigment" is a role (has_role, RO:0000087).
All four elaborate and none clashes: the core is SILENT on each. R8 and R9 need GO taxon constraints;
R10 needs a role kind or ChEBI's own is_a; R7 needs a lint over `Ontology.retired`. -/

example : (Ontology.retired.lookup (2, 548)).isSome = true := by decide                 -- R7
example : r2_12.claim.subjectCurie = "CL:0000548" := by decide
example : Ontology.isACurie "CHEBI:28966" "CHEBI:26130" = false := by decide             -- R10: not a subclass

/-! ## §2 Lean typing on seeded errors (detector: the core's `by decide` on `Rel.accepts` and kinds)

Of 274 control and mutant claims compiled (`scripts/stress/mutants_lean.py`), Lean rejects 7, all wrong
kind (E6) or direction reversed by swapping a process and a continuant (E4). Each is pinned: if a core
change lets one through, `#check_failure` reports an unexpected success. PASS for each. -/

def thylakoidMembraneOrg : Entity .process := ⟨"GO:0010027", "thylakoid membrane organization"⟩
def thyroidDevelopment : Entity .process := ⟨"GO:0030878", "thyroid gland development"⟩
def cytoplasmOrg : Entity .process := ⟨"GO:0007028", "cytoplasm organization"⟩
def nucleusOrg : Entity .process := ⟨"GO:0006997", "nucleus organization"⟩

#check_failure (Claim.rel ⟨.ro, 1025, false⟩ e_CHEBI_28966 thylakoidMembraneOrg)        -- B15-E6
#check_failure (Claim.rel ⟨.ro, 1025, false⟩ e_UBERON_0001132 thyroidDevelopment)       -- B16-E6
#check_failure (Claim.rel ⟨.bfo, 66, false⟩ e_GO_0006096 cytoplasmOrg)                  -- B17-E6
#check_failure (Claim.rel ⟨.ro, 2215, false⟩ e_GO_0015671 e_CL_0000232)                 -- B19-E4
#check_failure (Claim.rel ⟨.ro, 2215, false⟩ e_GO_0009765 e_CHEBI_28966)                -- B20-E4
#check_failure (Claim.notRel ⟨.ro, 2215, false⟩ e_GO_0140014 e_CL_0000520)              -- B35-E4
#check_failure (Claim.notRel ⟨.ro, 2215, false⟩
  (e_GO_0000723.inCtx { cellType := e_CL_0002371, lifeStage := e_UBERON_0000113 }) e_GO_0005697)  -- B43-E4

/-! The gaps. `Rel.accepts` checks only the BFO sort (continuant or occurrent) declared by RO's domain and
range. part_of and has_part declare none, so a component can be part of a process (B12-E6, SILENT, and the
real m45439-53, annotated as cytochrome c oxidase part_of the electron transport chain). enables declares no
domain or range at all in `RO.lean` (RO puts them on its parent, capable_of), so it accepts any kinds, a
process included (the real m45453-23, annotated as RuBisCO enables carbon fixation). Review correction: the
reason is not that function and process share a sort; see §5. Sign, taxon and same-kind CURIE swaps are
invisible to typing by design. -/

example : Claim := .rel ⟨.bfo, 50, false⟩ e_GO_0005730 nucleusOrg                -- B12-E6 accepted
example : Rel.partOf.accepts .component .process = true := by decide
example : Rel.enables.accepts .component .process = true := by decide
example : Claim := .effect e_PR_000009054 .pos (.amount (e_CHEBI_17234.inCtx { anatomy := e_UBERON_0000178 }))  -- B36-E7
example : Claim := .rel ⟨.bfo, 51, false⟩ (e_GO_0005618.inCtx { taxon := e_NCBITaxon_2157 }) e_CHEBI_8005  -- B04-E8

/-! ## Seeded errors the clash catches in Lean too (the closure's detector, restated)

B32-E10 (negation lost): "plant cells have centrioles" clashes with the real "plant cells lack centrioles".
PASS. B49-E2 (quantifier strengthened): "no eukaryotic centrosome has centrioles", from the real "some ...",
clashes with "centrosomes have centrioles" through the refinement axiom. PASS. -/

def b32_e10 : Statement :=
  { r3_75 with id := "B32-E10", claim := .rel ⟨.bfo, 51, false⟩ (e_CL_0000000.inCtx { taxon := e_NCBITaxon_33090 }) e_GO_0005814 }

theorem B32_E10_contested :
    (Derivation.clash (.lit b32_e10) (.lit r3_75)).verdict = .contested := by decide +kernel

def b49_e2 : Statement :=
  { r3_33 with id := "B49-E2", claim := .notRel ⟨.bfo, 51, false⟩ (e_GO_0005813.inCtx { taxon := e_NCBITaxon_2759 }) e_GO_0005814 }

example : quantOf r3_33.claim = some .some := by decide       -- the real statement is a "some" claim

def eukCentrosomeHasCentriole :
    Derivation (.rel Rel.hasPart (e_GO_0005813.inCtx { taxon := e_NCBITaxon_2759 }) e_GO_0005814) :=
  .relChain (.lit (e_GO_0005813.refineAxiom Rel.inTaxon e_NCBITaxon_2759)) (.lit r2_68)

theorem B49_E2_contested :
    (Derivation.clash eukCentrosomeHasCentriole (.lit b49_e2)).verdict = .contested := by decide +kernel

/-! B46-E2 and B06-E2 (quantifier strengthened, recreating real round-2 errors): "all cells have ribosomes"
and "all cells have DNA" are in round 2 as universals and accepted; round 3 says `most`. SILENT: no
statement says some cell lacks them, so nothing clashes. 135 closure facts rested on the ribosome one. -/

example : quantOf r2_11.claim = none ∧ quantOf r3_11.claim = some .most := by decide
example : quantOf r2_9.claim = none ∧ quantOf r3_9.claim = some .most := by decide

/-! ## §3 `Statement.taxonConsistent` (the core's only statement lint)

On textbook statements it is true by construction: textbook evidence carries no taxon. So it is SILENT on
every textbook mutant, including the centrosome. On literature-style statements it does its job.
S1 to S3 are synthetic (marked so in cases.tsv). -/

#guard r2_318.taxonConsistent                               -- the centrosome error: silent
#guard r2_39.taxonConsistent                                -- all mammals have teeth: silent

def mouseEv : Evidence := { pmid := 1, year := 2020, kind := .mechanistic, taxon := some Taxa.mouse }

/-- S1, taxon swapped: a human claim with mouse evidence. PASS. -/
def s1 : Statement where
  id := "S1"
  text := "insulin lowers blood glucose in humans (mouse evidence)"
  claim := .effect (e_PR_000009054.inCtx { taxon := Taxa.human }) .neg (.amount e_CHEBI_17234)
  evidence := [mouseEv]
#guard !s1.taxonConsistent

/-- S2, context dropped: a context-free claim with mouse evidence. PASS. -/
def s2 : Statement := { s1 with id := "S2", claim := .effect e_PR_000009054 .neg (.amount e_CHEBI_17234) }
#guard !s2.taxonConsistent

/-- S3, control: a mouse claim with mouse evidence. PASS (no flag). -/
def s3 : Statement := { s1 with id := "S3", claim := .effect (e_PR_000009054.inCtx { taxon := Taxa.mouse }) .neg (.amount e_CHEBI_17234) }
#guard s3.taxonConsistent

/-! ## §4 Prototype lints (not core)

Each reads data the core already imports. None changes a type, a constructor or a rule; each would live
outside the kernel-checked part, like `taxonConsistent`. They are here to measure, not to adopt. -/

namespace Proto

/-- The curies inside a (possibly refined) curie: `CL:0000000&RO:0002162=(NCBITaxon:33208)` gives three. -/
def tokens (c : String) : List String :=
  let step := fun (acc : List String × List Char) (ch : Char) =>
    if ch == '&' || ch == '=' || ch == '(' || ch == ')' then
      (if acc.2.isEmpty then acc.1 else acc.1 ++ [String.ofList acc.2], [])
    else (acc.1, acc.2 ++ [ch])
  let (done, cur) := c.toList.foldl step ([], [])
  if cur.isEmpty then done else done ++ [String.ofList cur]

def Target.curie : Target → String
  | .activity p _ => p.curie | .amount m => m.curie | .process p => p.curie
  | .phenotype p => p.curie | .site a => a.curie

/-- The subject and object curies of a claim (the shapes the closure loads). -/
def curies : Claim → List String
  | .effect a _ t | .noEffect a t => [a.curie, Target.curie t]
  | .mediatedBy a _ t m => [a.curie, Target.curie t, Target.curie m]
  | .rel _ a b _ | .notRel _ a b _ => [a.curie, b.curie]
  | .quant _ c => curies c
  | c => [c.subjectCurie]

/-- Lint L1: the claim uses a term its ontology has retired (`Ontology.retired`). -/
def usesRetired (c : Claim) : Bool :=
  ((curies c).flatMap tokens).any fun t =>
    match Curie.encode t with
    | some k => (Ontology.retired.lookup k).isSome
    | none => false

/-- Lint L2: an asserted is_a between two imported terms that the ontology does not have. The import is
the full is_a ancestor closure of every used term, so for two known terms "not above" is exact. -/
def isaNotInOntology : Claim → Bool
  | .rel r a b _ =>
    r == Rel.isA &&
    (match Curie.encode (Ctx.baseCurie a.curie), Curie.encode (Ctx.baseCurie b.curie) with
     | some x, some y => Ontology.known x && Ontology.known y && !Ontology.isA x y
     | _, _ => false)
  | _ => false

/-- Lint L3: an inverse pair asserted between the same two terms (a r b and a r⁻¹ b), e.g. round 1's
`derives_into` next to round 2's `derives_from`. -/
def inversePair : Claim → Claim → Bool
  | .rel r a b _, .rel r' a' b' _ => a.curie == a'.curie && b.curie == b'.curie && r != r' && RO.inverseOK r r'
  | _, _ => false

-- L1 catches R6 and R7, and passes the controls
#guard usesRetired r3_71.claim           -- R6, through the context filler
#guard usesRetired r2_12.claim           -- R7
#guard usesRetired r2_218.claim          -- R7
#guard !(usesRetired r3_318.claim)         -- control
#guard !(usesRetired r3_53.claim)          -- control
-- L2 catches R10 (pigment is a role) and the reversed is_a mutant B25-E4; passes a true is_a
#guard isaNotInOntology r2_71.claim                                   -- R10
#guard isaNotInOntology (.rel Rel.isA e_UBERON_0002368 e_UBERON_0001132)  -- B25-E4
#guard !(isaNotInOntology (.rel Rel.isA e_UBERON_0001132 e_UBERON_0002368)) -- control (B25)
-- L3 catches R3 once both rounds are side by side; it cannot tell which one is wrong
#guard inversePair r1_261.claim r2_261.claim
#guard !(inversePair r2_318.claim r3_318.claim)

/-! ### P1. Taxon constraints as plain statements (option D2: data, no core change)
UBERON says calcareous tooth is never_in_taxon Mysticeti. Read as a negative statement, "no baleen whale
has a tooth", with the NCBITaxon edge "Mysticeti is_a Mammalia" (both `.ontologyAxiom`), the existing
is_a law and `clash` catch round 2's "all mammals have teeth": R2 goes from SILENT to PASS. Round 3's
`most` form is not a `.rel`, so it cannot enter the chain and stays clean. Review caveat: the axiom is too
strong as written. Baleen whale fetuses grow tooth germs that "reach the bell stage and are sometimes
mineralized" before they are resorbed (Thewissen et al. 2017, PMID 28070906). The true form is "adult baleen
whales have no teeth", which BioLean cannot state (I2 in §5). -/

def mysticeti : Entity .taxon := ⟨"NCBITaxon:9761", "Mysticeti"⟩

def toothNeverInMysticeti : Statement where
  id := "UBERON:0001091 never_in_taxon NCBITaxon:9761"
  text := "no baleen whale has a calcareous tooth"
  claim := .notRel Rel.hasPart mysticeti e_UBERON_0001091
  evidence := [{ pmid := 0, year := 2026, kind := .ontologyAxiom, note := "uberon.obo 2026-10-01, never_in_taxon" }]

def mysticetiIsMammal : Statement where
  id := "NCBITaxon:9761 is_a NCBITaxon:40674"
  text := "baleen whales are mammals"
  claim := .rel Rel.isA mysticeti e_NCBITaxon_40674
  evidence := [{ pmid := 0, year := 2026, kind := .ontologyAxiom, note := "NCBITaxon lineage" }]

def baleenWhaleHasTooth : Derivation (.rel Rel.hasPart mysticeti e_UBERON_0001091) :=
  .relChain (.lit mysticetiIsMammal) (.lit r2_39)

theorem P1_teeth_contested :
    (Derivation.clash baleenWhaleHasTooth (.lit toothNeverInMysticeti)).verdict = .contested := by decide +kernel

end Proto

/-! ## §5 Review additions (independent review, 2026-11-01)

The first version marked R8, R9 and R11 to R16 from Python runs but pinned none of them in Lean, and pinned only two
of the three R7 statements. Each is pinned here: the compiled statement has the erroneous shape and Lean accepts it,
so a fix to the data or a stricter core flips the pin. Then the exact reason for each typing gap, option C as a lint
outside the core, and two cases on option D2 (reading ontology never_in_taxon as negative statements). -/

namespace Review

def r2_215 := Textbook.R2.CellStructureAndFunction.cell_structure_and_function_m45432_215
def r3_215 := Textbook.R3.CellStructureAndFunction.cell_structure_and_function_m45432_215
def r2_30 := Textbook.R2.CellStructureAndFunction.cell_structure_and_function_m45429_30
def r2_ccox := Textbook.R2.HowCellsObtainEnergy.how_cells_obtain_energy_m45439_53
def r2_rubisco := Textbook.R2.Photosynthesis.photosynthesis_m45453_23
def r2_ldl := Textbook.R2.CellStructureAndFunction.cell_structure_and_function_m45435_53
def r2_zygote := Textbook.R2.ReproductionAtTheCellularLevel.reproduction_at_the_cellular_level_m45454_1
def r2_replication := Textbook.R2.MolecularBiology.molbio_m45475_4
def r2_receptors := Textbook.R2.CellStructureAndFunction.cell_structure_and_function_m45433_11
def r2_enzymes := Textbook.R2.HowCellsObtainEnergy.how_cells_obtain_energy_m45437_199

/-- The relation of a binary claim. -/
def relOf : Claim → Option Rel
  | .rel r .. | .notRel r .. => some r
  | .quant _ c => relOf c
  | _ => none

/-- The object curie of a binary claim. -/
def objOf : Claim → Option String
  | .rel _ _ b _ | .notRel _ _ b _ => some b.curie
  | .quant _ c => objOf c
  | _ => none

/-! ### R7, third statement. m45432-215 uses obsolete CL:0000548 in round 2, and round 3 still does. SILENT. -/
#guard Proto.usesRetired r2_215.claim
#guard Proto.usesRetired r3_215.claim
#guard r2_215.taxonConsistent                       -- the core's only lint: silent

/-! ### R8. Generic thylakoid part_of chloroplast, no taxon (photosynthesis-m45448-148). SILENT. -/
example : r2_148.claim.subjectCurie = "GO:0009579" ∧ objOf r2_148.claim = some "GO:0009507" := by decide
#guard Ctx.taxonOfCurie r2_148.claim.subjectCurie == none
#guard r2_148.taxonConsistent

/-! ### R9. The Calvin cycle occurs_in chloroplast stroma, no taxon (photosynthesis-m45448-95). SILENT. -/
example : r2_95.claim.subjectCurie = "GO:0019253" ∧ objOf r2_95.claim = some "GO:0009570" := by decide
#guard Ctx.taxonOfCurie r2_95.claim.subjectCurie == none

/-! ### R11. "Some prokaryotes have pili" stored with no quantifier, so as "every" (m45429-30). SILENT. -/
example : quantOf r2_30.claim = none ∧ objOf r2_30.claim = some "GO:0009289" := by decide

/-! ### R12. A complex part_of a process (how-cells-obtain-energy-m45439-53). SILENT.
`RO.lean` declares no domain or range for part_of, so `Rel.accepts` has nothing to check. -/
example : relOf r2_ccox.claim = some Rel.partOf ∧ r2_ccox.claim.subjectCurie = "GO:0045277" := by decide
example : RO.domains.lookup Rel.partOf = none ∧ RO.ranges.lookup Rel.partOf = none := by decide

/-! ### R13. RuBisCO enables carbon fixation, a process (photosynthesis-m45453-23). SILENT.
The exact reason: enables has no domain or range of its own in `RO.lean`; RO declares them on its parent capable_of
(continuant to process). So enables accepts any kinds, even a chemical enabling an organ. -/
example : relOf r2_rubisco.claim = some Rel.enables := by decide
example : RO.domains.lookup Rel.enables = none ∧ RO.ranges.lookup Rel.enables = none := by decide
example : RO.ranges.lookup Rel.capableOf = some .occurrent := by decide
example : Rel.enables.accepts .chemical .anatomy = true := by decide

/-! ### R14. LDL is_a cholesterol (cell-structure-and-function-m45435-53). SILENT in the core.
The sentence itself says "LDL (low-density lipoprotein) is a form of cholesterol": the annotation is faithful to a
loose sentence. is_a has no kind check; L2 (an is_a the ontologies do not have) catches it. -/
example : relOf r2_ldl.claim = some Rel.isA ∧ Rel.isA.accepts .component .chemical = true := by decide
#guard Proto.isaNotInOntology r2_ldl.claim

/-! ### R15. "A sexually reproducing organism develops from a zygote": the condition is dropped (m45454-1). SILENT. -/
example : r2_zygote.claim.subjectCurie = "UBERON:0000468" ∧ objOf r2_zygote.claim = some "CL:0010017" := by decide

/-! ### R16. "DNA replication occurs before mitosis or meiosis": one disjunct kept (molbio-m45475-4).
INEXPRESSIBLE: `Claim` has no disjunction, so the right form cannot be written; the pin shows the one disjunct. -/
example : relOf r2_replication.claim = some Rel.precedes ∧ objOf r2_replication.claim = some "GO:0140014" := by decide

/-! ### Option C0 (missing from the first version): inherit RO's domain and range down sub-properties.
In OWL a sub-property inherits its parent's domain and range; `RO.lean` keeps only each relation's own. So
has_output (parent has_participant: occurrent to continuant), involved_in (parent participates_in: continuant to
occurrent) and has_function (BFO function range, unmapped) check little or nothing. Today these all pass: -/
example : Rel.hasOutput.accepts .chemical .chemical = true := by decide
example : Rel.involvedIn.accepts .function .process = true := by decide
example : (⟨.ro, 85, false⟩ : Rel).accepts .component .function = true := by decide
-- two of the five live statements that inheritance would reject ("The plasma membrane carries receptors",
-- "Enzymes are key components of metabolic pathways"): both compile today
example : relOf r2_receptors.claim = some ⟨.ro, 85, false⟩ := by decide
example : relOf r2_enzymes.claim = some Rel.involvedIn := by decide

/-! ### Option C as a lint, outside the core
`sigLint` makes option C's checks without a new `Kind` constructor and without touching `Rel.accepts`: a ChEBI role is
read off the is_a closure the core already imports (`Ontology.isACurie _ "CHEBI:50906"`). So C's catches do not need
a core change; the core change (C proper) only adds enforcement: such statements would stop compiling. -/

def chebiRole : String := "CHEBI:50906"
def isRole (c : String) : Bool :=
  c.startsWith "CHEBI:" && (Ctx.baseCurie c == chebiRole || Ontology.isACurie (Ctx.baseCurie c) chebiRole)

/-- Option C's signature checks as a Bool: is_a within one kind (roles apart from chemicals); part_of, has_part,
overlaps within one BFO sort; enables needs a function. -/
def sigLint : Claim → Bool
  | @Claim.rel k₁ k₂ r a b _ | @Claim.notRel k₁ k₂ r a b _ =>
    (r == Rel.isA && (k₁ != k₂ || isRole a.curie != isRole b.curie)) ||
    ((r == Rel.partOf || r == Rel.hasPart || r == Rel.overlaps) && k₁.sort != k₂.sort) ||
    (r == Rel.enables && k₂ != .function)
  | .quant _ c => sigLint c
  | _ => false

#guard isRole "CHEBI:26130" && !isRole "CHEBI:28966"      -- biological pigment is a role; chlorophyll is not
#guard sigLint r2_71.claim                                -- R10 chlorophyll is_a pigment
#guard sigLint r2_ccox.claim                              -- R12
#guard sigLint r2_rubisco.claim                           -- R13
#guard sigLint r2_ldl.claim                               -- R14
#guard !(sigLint r2_68.claim) && !(sigLint r2_261.claim) && !(sigLint r2_148.claim) && !(sigLint r3_318.claim)  -- controls

/-- Run `sigLint` over every compiled `Statement` under a namespace (the round-2 or round-3 library). -/
unsafe def scanSig (pre : Lean.Name) : Lean.Elab.Command.CommandElabM (List String × Nat) := do
  let env ← Lean.getEnv
  let mut hits : List String := []
  let mut n := 0
  for (nm, ci) in env.constants.toList do
    if pre.isPrefixOf nm && ci.type == Lean.mkConst ``BioLean.Statement then
      n := n + 1
      match env.evalConst Statement {} nm with
      | .ok s => if sigLint s.claim then hits := s.id :: hits
      | .error _ => pure ()
  return (hits.eraseDups.mergeSort, n)

/-- info: R2: 1591 statements, 21 flagged. R3: 480 statements, 4 flagged. Distinct statement ids flagged: 25 -/
#guard_msgs in
#eval show Lean.Elab.Command.CommandElabM Unit from do
  let (h2, n2) ← unsafe scanSig `BioLean.Textbook.R2
  let (h3, n3) ← unsafe scanSig `BioLean.Textbook.R3
  Lean.logInfo m!"R2: {n2} statements, {h2.length} flagged. R3: {n3} statements, {h3.length} flagged. Distinct statement ids flagged: {(h2 ++ h3).eraseDups.length}"

/-! ### P3. Option D2 on a taxon where the ontology is wrong. FAIL.
uberon.obo (2026-10-01) says calcareous tooth never_in_taxon Ornithorhynchus (source PMID:10210685, a paper on
electroreception). But living platypuses have teeth while young: Lester and Boyde 1986 (PMID 3706773) imaged
"unerupted developing teeth and air-dried erupted teeth of the platypus (Ornithorhynchus anatinus)", with enamel and
dentine. Read as a negative statement at `.ontologyAxiom` weight (9/10), the wrong axiom outvotes the paper: the true
claim comes out refuted (paper as `.observational`) or unsupported (as `.mechanistic`). A correct system would flag the
axiom. This is a concrete M5 inconsistency for a curator. -/

def platypus : Entity .taxon := ⟨"NCBITaxon:9257", "Ornithorhynchus"⟩

def toothNeverInPlatypus : Statement where
  id := "UBERON:0001091 never_in_taxon NCBITaxon:9257"
  text := "no platypus has a calcareous tooth"
  claim := .notRel Rel.hasPart platypus e_UBERON_0001091
  evidence := [{ pmid := 0, year := 2026, kind := .ontologyAxiom, note := "uberon.obo 2026-10-01 never_in_taxon; source PMID:10210685" }]

def platypusHasTooth (k : EvidenceKind) : Statement where
  id := "PMID:3706773"
  text := "unerupted developing teeth and air-dried erupted teeth of the platypus (Ornithorhynchus anatinus)"
  claim := .rel Rel.hasPart platypus e_UBERON_0001091
  evidence := [{ pmid := 3706773, year := 1986, kind := k, note := "Lester KS, Boyde A. Anat Embryol 1986" }]

theorem P3_platypus_refuted :
    (Derivation.clash (.lit (platypusHasTooth .observational)) (.lit toothNeverInPlatypus)).verdict = .refuted := by
  decide +kernel

theorem P3_platypus_unsupported_as_mechanistic :
    (Derivation.clash (.lit (platypusHasTooth .mechanistic)) (.lit toothNeverInPlatypus)).verdict = .unsupported := by
  decide +kernel

/-! ### I2. "Adult baleen whales have no teeth" (fetuses grow tooth germs, sometimes mineralised). INEXPRESSIBLE.
Source: Thewissen et al. 2017, PMID 28070906. A life stage refines the organism (`existence_overlaps` adult), not the
time of the parthood. So "has no tooth as an adult" and "never has a tooth" get the same claim; the first is true,
the second false. -/
#guard (Proto.mysticeti.inCtx { lifeStage := e_UBERON_0000113 }).curie == "NCBITaxon:9761&RO:0002490=(UBERON:0000113)"

end Review

end BioLean.Stress.AnnotationErrors
