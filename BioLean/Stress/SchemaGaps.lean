import BioLean.Derivation
import BioLean.Examples.Quantity
import BioLean.Examples.Context
import BioLean.Lib.TextbookClaimsR2.CellStructureAndFunction
import BioLean.Lib.TextbookClaimsR2.HowCellsObtainEnergy
import BioLean.Lib.TextbookClaimsR2.MolecularBiology
import BioLean.Lib.TextbookClaimsR3.CellStructureAndFunction
import BioLean.Lib.TextbookClaimsR3.MolecularBiology
import BioLean.Lib.TextbookClaimsR3.ReproductionAtTheCellularLevel
import BioLean.Lib.TextbookClaimsR3.TheBodySSystemsA
import BioLean.Lib.TextbookClaimsR3.TheBodySSystemsB
import BioLean.Lib.TextbookClaimsR3.Photosynthesis
import BioLean.Lib.TextbookClaimsR3.TheCellularBasisOfInheritance
import BioLean.Lib.TextbookClaimsR3.HowCellsObtainEnergy
import BioLean.Lib.TextbookClaimsR2.TheBodySSystemsA
import BioLean.Lib.TextbookClaimsR2.TheBodySSystemsB
import BioLean.Lib.TextbookClaimsR2.TheCellularBasisOfInheritance
import BioLean.Lib.TextbookClaimsR2.ReproductionAtTheCellularLevel
import BioLean.Rivalry

/-!
# Stress set 08: three schema gaps, against today's core

Program 08 (`docs/programs/08-schema-gaps.md`). Disjunction (D), approximate numbers (A), and a second
context slot (C). Every case uses the current core only: `BioLean/*.lean`, the built textbook
libraries R2 and R3 (oleans of 2026-10-31 15:46), `Examples/Quantity` and `Examples/Context`. Nothing
here changes the core. The prototypes of core changes are in `BioLean/Proto/SchemaGaps.lean`. The
table is `data/stress/08/cases.tsv`, written by `scripts/stress/gaps_cases.py` from the `OBS` lines
this file prints.

Each case pins what BioLean does today with `#guard`, `example`, `theorem ... := by decide +kernel`,
`#check_failure` or `#no_lean` (no R2 or R3 statement for that sentence). If a later change to the
core or the libraries flips a behaviour, the pin breaks visibly.

Marks: PASS right conclusion; FAIL wrong conclusion; SILENT no conclusion where one is due;
INEXPRESSIBLE the core cannot state it. Statements marked SYNTHETIC are mine, not the book's.
-/

namespace BioLean.Stress.SchemaGaps
open BioLean Derivation BioLean.Textbook.R2 BioLean.Textbook.R3

/-! ## Helpers -/

/-- One line of the observed-results table: `OBS <tab> case <tab> what BioLean did`. -/
def obs (id msg : String) : IO Unit := IO.println s!"OBS\t{id}\t{msg}"

/-- A textbook item (OpenStax Concepts of Biology), as the R2 and R3 emitters write it. -/
def tb (note : String) : Evidence := { pmid := 0, year := 2013, kind := .textbook, note := note }

/-- A paper, by PMID (all checked on Europe PMC, `data/stress/08/references_checked.tsv`). -/
def paper (pmid year : Nat) (k : EvidenceKind) (note : String) : Evidence :=
  { pmid := pmid, year := year, kind := k, note := note }

/-- An ontology is_a edge as a statement (as `Examples/Context.lean` writes them). Every edge used
here is on OLS4 (`data/stress/08/curies_checked.tsv`). -/
def isaAx {k₁ k₂ : Kind} (a : Entity k₁) (b : Entity k₂) (h : Rel.isA.accepts k₁ k₂ = true := by decide) :
    Statement :=
  { id := s!"isa:{a.curie}<{b.curie}", text := s!"{a.label} is_a {b.label}", claim := .rel Rel.isA a b h,
    evidence := [{ pmid := 0, year := 2026, kind := .ontologyAxiom, note := "is_a on OLS4" }] }

/-- The shape of a claim, by constructor. The match has no wildcard on purpose: adding a constructor
to `Claim` (an `or`, an `about`) makes this file fail to compile, which flips every INEXPRESSIBLE
pin below at once. -/
def shape : Claim → String
  | .effect .. => "effect" | .mediatedBy .. => "mediatedBy" | .noEffect .. => "noEffect"
  | .rel .. => "rel" | .notRel .. => "notRel" | .count .. => "count" | .atLeast .. => "atLeast"
  | .countBetween .. => "countBetween" | .cardinality .. => "cardinality" | .measure .. => "measure"
  | .atLeastMeasure .. => "atLeastMeasure" | .less .. => "less" | .produces .. => "produces"
  | .consumes .. => "consumes" | .yield .. => "yield" | .homeostasis .. => "homeostasis"
  | .quant _ c => s!"quant {shape c}"

/-- The core has 17 claim constructors. None combines two claims (no `or`, no `and`), and none
carries a tolerance. -/
def coreShapes : List String :=
  ["effect", "mediatedBy", "noEffect", "rel", "notRel", "count", "atLeast", "countBetween",
   "cardinality", "measure", "atLeastMeasure", "less", "produces", "consumes", "yield", "homeostasis",
   "quant"]
#guard coreShapes.length = 17
#guard !coreShapes.contains "or" && !coreShapes.contains "about"

/-- Lower and upper bound of a measure claim (or of `most`/`some` over one). -/
def bounds : Claim → Option (ℚ × ℚ)
  | .measure _ _ lo hi _ => some (lo, hi)
  | .quant _ c => bounds c
  | _ => none

/-- The number in a count claim. -/
def countOf : Claim → Option Nat
  | .count _ _ n => some n
  | .atLeast _ _ n => some n
  | .quant _ c => countOf c
  | _ => none

def vstr : Verdict → String
  | .established => "established" | .contested => "contested" | .refuted => "refuted"
  | .unsupported => "unsupported"

/-- The verdict of a statement taken as an axiom. -/
def litVerdict (s : Statement) : Verdict := (Derivation.lit s).verdict

/-- The chapter modules of the textbook libraries. -/
def chapters : List Lean.Name :=
  [`CellStructureAndFunction, `HowCellsObtainEnergy, `MolecularBiology, `Photosynthesis,
   `ReproductionAtTheCellularLevel, `TheBodySSystemsA, `TheBodySSystemsB, `TheCellularBasisOfInheritance]

open Lean Elab Command in
/-- `#no_lean Chapter name`: neither R2 nor R3 has a statement `name` in any imported chapter
module. It fails if a later round emits the record (the SILENT or INEXPRESSIBLE mark then needs a
look), and it fails if `Chapter` is not imported in both rounds, so a typo cannot make it pass.
R1 (`BioLean/Lib/TextbookClaims`) is not built, so it is checked by grep, not here. -/
elab "#no_lean " m:ident n:ident : command => do
  let env ← getEnv
  for pre in [`BioLean.Textbook.R2, `BioLean.Textbook.R3] do
    unless env.isNamespace (pre ++ m.getId) do throwError "{pre ++ m.getId} is not imported"
    for c in chapters do
      if env.contains (pre ++ c ++ n.getId) then
        throwError "{pre ++ c ++ n.getId} exists: the record now has Lean"

/-! ## Entities not in the textbook libraries (CURIEs checked on OLS4) -/

def prokCell   : Entity .cellType := ⟨"CL:0000520", "prokaryotic cell"⟩
def eukCell    : Entity .cellType := ⟨"CL:0000255", "eukaryotic cell"⟩
def enucleateRbc : Entity .cellType := ⟨"CL:0000595", "enucleate erythrocyte"⟩
def gtp        : Entity .chemical := ⟨"CHEBI:15996", "GTP"⟩
def purineNTP  : Entity .chemical := ⟨"CHEBI:26398", "purine ribonucleoside triphosphate"⟩
def meiosisI   : Entity .process := ⟨"GO:0007127", "meiosis I"⟩
def meiosisII  : Entity .process := ⟨"GO:0007135", "meiosis II"⟩
def meioticDivision : Entity .process := ⟨"GO:0140013", "meiotic nuclear division"⟩
def premeioticRep : Entity .process := ⟨"GO:0006279", "premeiotic DNA replication"⟩
/-- No GO, HP or PATO term for nondisjunction was found on OLS4 (search 2026-10-30). -/
def nondisjunction : Entity .process := ⟨"BLN:nondisjunction", "chromosome nondisjunction"⟩
def carbohydrate : Entity .chemical := ⟨"CHEBI:16646", "carbohydrate"⟩
def glycoprotein : Entity .chemical := ⟨"CHEBI:17089", "glycoprotein"⟩
def glycolipid : Entity .chemical := ⟨"CHEBI:33563", "glycolipid"⟩
def carbDerivative : Entity .chemical := ⟨"CHEBI:63299", "carbohydrate derivative"⟩
def hypothalamus : Entity .anatomy := ⟨"UBERON:0001898", "hypothalamus"⟩
def vasodilation : Entity .process := ⟨"GO:0042311", "vasodilation"⟩
def vasoconstriction : Entity .process := ⟨"GO:0042310", "vasoconstriction"⟩
def vesselDiameter : Entity .process := ⟨"GO:0097746", "blood vessel diameter maintenance"⟩
def increasedTemp : Entity .phenotype := ⟨"PATO:0001305", "increased temperature"⟩
def organism   : Entity .anatomy := ⟨"UBERON:0000468", "multicellular organism"⟩
def hair       : Entity .anatomy := ⟨"UBERON:0001037", "strand of hair"⟩
def feather    : Entity .anatomy := ⟨"UBERON:0000022", "feather"⟩
def aves       : Entity .taxon := ⟨"NCBITaxon:8782", "Aves"⟩
def regCatalytic : Entity .process := ⟨"GO:0050790", "regulation of catalytic activity"⟩
def posRegCatalytic : Entity .process := ⟨"GO:0043085", "positive regulation of catalytic activity"⟩
def negRegCatalytic : Entity .process := ⟨"GO:0043086", "negative regulation of catalytic activity"⟩
def water      : Entity .chemical := ⟨"CHEBI:15377", "water"⟩
def droughtExp : Entity .phenotype := ⟨"PECO:0007404", "drought exposure"⟩
def underwatered : Entity .phenotype := ⟨"BLN:not_watered_adequately", "not watered adequately"⟩
def waterExport : Entity .process := ⟨"GO:0006833", "water transport"⟩
def plantCellPO : Entity .cellType := ⟨"PO:0009002", "plant cell"⟩

/-! ## D. Disjunction -/

/-! ### D01. "all are grouped into one of two broad categories: prokaryotic and eukaryotic"
(cell-structure-and-function-m45428-11, m45429-1). INEXPRESSIBLE: no constructor takes two claims
and no entity is a union of two classes; the R1 to R3 records have no Lean. What is lost is small for
named cell types: the imported CL closure already places them. -/
#guard Ontology.isACurie e_CL_0000232.curie eukCell.curie
#guard !Ontology.isACurie e_CL_0000232.curie prokCell.curie
-- A class with no CL term gets nothing: no rule makes "a cell that is not prokaryotic" eukaryotic.
#guard !Ontology.isACurie "BLN:unnamed_cell" eukCell.curie
#no_lean CellStructureAndFunction cell_structure_and_function_m45428_11
#no_lean CellStructureAndFunction cell_structure_and_function_m45429_1
#eval obs "D01" "no Lean for m45428-11 or m45429-1 (no or, no union entity); CL places named cells: erythrocyte is_a eukaryotic cell in the closure"

/-! ### D02. A cell without a nucleus must not become prokaryotic. PASS today. CL:0000595 (enucleate
erythrocyte) is not in the imported closure, and no rule turns "has no nucleus" into "is prokaryotic".
A disjunctive syllogism over D01 ("not eukaryotic, so prokaryotic") would be the risk. -/
#guard (Curie.encode enucleateRbc.curie).map Ontology.known = some false
#guard !Ontology.isACurie enucleateRbc.curie prokCell.curie
#eval obs "D02" "nothing derives enucleate erythrocyte is_a prokaryotic cell (CL:0000595 not in closure; no disjunctive syllogism)"

/-! ### D03. "one ATP molecule (or an equivalent)" per turn of the TCA cycle (how-cells-obtain-energy-m45439-16,
-28, -104). Round 3 refused the weakening (blocker `disjunction`). Round 2 still holds the stronger
disjunct, "TCA has output ATP". Lambeth 2004 (PMID 15234968): mammalian tissues express an ATP-forming
and a GTP-forming succinyl-CoA synthetase. FAIL: the library asserts ATP outright, at 0.8. -/
def d03_r2a := BioLean.Textbook.R2.HowCellsObtainEnergy.how_cells_obtain_energy_m45439_16
def d03_r2b := BioLean.Textbook.R2.HowCellsObtainEnergy.how_cells_obtain_energy_m45439_28
#guard shape d03_r2a.claim = "rel" ∧ shape d03_r2b.claim = "rel"
#guard toString d03_r2a.claim = "the next pathway in glucose catabolism [GO:0006099] has output ATP [CHEBI:15422]"
theorem d03_r2_established : litVerdict d03_r2a = .established := by decide +kernel
/-! The sound coarsening exists as data: ATP and GTP are both purine ribonucleoside triphosphates in
the imported ChEBI closure, and the is_a law derives "TCA has output a purine NTP" from the
over-strong R2 statement. Right conclusion, from a wrong premise. -/
#guard Ontology.isACurie e_CHEBI_15422.curie purineNTP.curie ∧ Ontology.isACurie gtp.curie purineNTP.curie
def d03_coarse : Derivation (.rel Rel.hasOutput e_GO_0006099 purineNTP) :=
  .relChain (r₃ := Rel.hasOutput) (.lit d03_r2a) (.lit (isaAx e_CHEBI_15422 purineNTP))
theorem d03_coarse_belief : d03_coarse.opinion.belief = 4 / 5 := by decide +kernel
#eval obs "D03" s!"R2 asserts '{d03_r2a.claim}', verdict {vstr (litVerdict d03_r2a)}; R3 refused the record (blocker disjunction); coarsening to purine NTP derivable at b={d03_coarse.opinion.belief}"

/-! ### D04. Cytokinesis "by either a cleavage furrow (in animals and some fungi), or a cell plate ...
(in plants)" (the-cellular-basis-of-inheritance-m45466-106, -107). PASS: R3 splits the "or" by taxon.
Both halves are true as split (GO:0032154 cleavage furrow; GO:0009504 cell plate, OLS4 definitions). -/
def d04a := BioLean.Textbook.R3.TheCellularBasisOfInheritance.the_cellular_basis_of_inheritance_m45466_106
def d04b := BioLean.Textbook.R3.TheCellularBasisOfInheritance.the_cellular_basis_of_inheritance_m45466_107
#guard d04a.claim.subjectCurie = "GO:0000910&RO:0002162=(NCBITaxon:33208)"
#guard d04b.claim.subjectCurie = "GO:0000910&RO:0002162=(NCBITaxon:3193)"
#guard (toString d04a.claim).endsWith "has part cleavage furrow [GO:0032154]"
#guard (toString d04b.claim).endsWith "has part cell plate [GO:0009504]"
#eval obs "D04" "R3 has two claims split by taxon: cytokinesis in Metazoa has part cleavage furrow; in plants (NCBITaxon:3193) has part cell plate"

/-! ### D05. "Nondisjunction can occur during either meiosis I or II" (the-cellular-basis-of-inheritance-m45467-34).
INEXPRESSIBLE: no term for the subject, and no `or`. The coarsening "happens during meiotic nuclear
division" is stateable today, since both disjuncts are is_a GO:0140013 in the closure. -/
#guard Ontology.isACurie meiosisI.curie meioticDivision.curie ∧ Ontology.isACurie meiosisII.curie meioticDivision.curie
def d05_coarse : Claim := .rel Rel.happensDuring nondisjunction meioticDivision
#no_lean TheCellularBasisOfInheritance the_cellular_basis_of_inheritance_m45467_34
#guard shape d05_coarse = "rel"
#eval obs "D05" "no Lean (subject ungrounded, or refused); coarsening 'happens during meiotic nuclear division' stateable as rel"

/-! ### D06. "Ribosomes are found in the cytoplasm or are attached to the cytoplasmic side of the plasma
membrane or endoplasmic reticulum" (cell-structure-and-function-m45432-311; the narrower m45432-183 has
no Lean). R2 keeps one disjunct as the whole: "every ribosome is located in the cytoplasm". In GO this
holds for two of the three places, not the third. On OLS4 the ER's cytoplasmic side (GO:0098554) is
part of the cytoplasm, but the plasma membrane's cytoplasmic side (GO:0009898, "including any protein
... attached to ... it") is part of the plasma membrane, and GO:0005737 is "excluding the plasma
membrane". Ribosomes bound to the bacterial plasma membrane are real (Rapoport 2007, PMID 18046402).
FAIL, milder than D03 and D13. BioLean cannot see it: both sides are in the imported closure, but
the closure is is_a only, and neither side is_a cytoplasm (the ER side is part_of it). (Review
2026-10-31: this case was marked PASS as "true for all three places".) -/
def d06 := BioLean.Textbook.R2.CellStructureAndFunction.cell_structure_and_function_m45432_311
#guard toString d06.claim = "ribosomes [GO:0005840] located in cytoplasm [GO:0005737]"
theorem d06_r2_established : litVerdict d06 = .established := by decide +kernel
#guard (Curie.encode "GO:0009898").map Ontology.known = some true
#guard !Ontology.isACurie "GO:0009898" e_GO_0005737.curie ∧ !Ontology.isACurie "GO:0098554" e_GO_0005737.curie
#no_lean CellStructureAndFunction cell_structure_and_function_m45432_183
#eval obs "D06" s!"R2 asserts '{d06.claim}', verdict {vstr (litVerdict d06)}; false for ribosomes on the plasma membrane's cytoplasmic side (GO:0009898 is part of the plasma membrane on OLS4; the closure is is_a only); m45432-183 (PM or ER) has no Lean"

/-! ### D07. Membrane carbohydrates "are bound either to proteins (forming glycoproteins) or to lipids
(forming glycolipids)" (m45433-53). INEXPRESSIBLE: the exhaustive reading ("every one is in a
glycoprotein or a glycolipid") needs `or`. The distributive reading ("some are in each") is two
`some` claims. Both targets are carbohydrate derivatives in the closure. -/
def d07_someProt : Claim := .quant .some (.rel Rel.partOf carbohydrate glycoprotein)
def d07_someLipid : Claim := .quant .some (.rel Rel.partOf carbohydrate glycolipid)
#guard shape d07_someProt = "quant rel" ∧ shape d07_someLipid = "quant rel"
#no_lean CellStructureAndFunction cell_structure_and_function_m45433_53
#guard Ontology.isACurie glycoprotein.curie carbDerivative.curie ∧ Ontology.isACurie glycolipid.curie carbDerivative.curie
#eval obs "D07" "no Lean for m45433-53; two 'some part_of' claims stateable; exhaustive or not stateable"

/-! ### D08. "reflexes that cause vasodilation or vasoconstriction and shivering or sweating"
(the-body-s-systems-m45534-78, -79). INEXPRESSIBLE as written. The content splits by condition: heat
gives cutaneous vasodilation (Charkoudian 2003, PMID 12744548), cold gives vasoconstriction and
shivering (Morrison and Nakamura 2019, PMID 30256726). The split is stateable with an organism state;
the "or" alone coarsens to GO:0097746. -/
def d08_heat : Claim :=
  .effect (hypothalamus.inCtx { taxon := Taxa.human, condition := some (.organism increasedTemp) }) .pos
    (.process vasodilation)
#guard d08_heat.subjectCurie = "UBERON:0001898&RO:0002162=(NCBITaxon:9606&RO:0002573=(PATO:0001305))"
#no_lean TheBodySSystemsA the_body_s_systems_m45534_78
#no_lean TheBodySSystemsA the_body_s_systems_m45534_79
#guard Ontology.isACurie vasodilation.curie vesselDiameter.curie ∧ Ontology.isACurie vasoconstriction.curie vesselDiameter.curie
#eval obs "D08" "no Lean for -78/-79; split by condition stateable (heat: hypothalamus ->+ vasodilation); both disjuncts is_a GO:0097746"

/-! ### D09. Endotherms "have fur, fat, or feathers" (the-body-s-systems-m45534-44). INEXPRESSIBLE: the
subject, endotherms, is mammals or birds (no NCBITaxon class), and the object is a disjunction.
Split by taxon it is two true `rel` claims, each stronger than the "or". -/
def d09_mammal : Claim := .rel Rel.hasPart (organism.inCtx { taxon := Taxa.mammalia }) hair
def d09_bird : Claim := .rel Rel.hasPart (organism.inCtx { taxon := aves }) feather
#guard shape d09_mammal = "rel" ∧ shape d09_bird = "rel"
#no_lean TheBodySSystemsA the_body_s_systems_m45534_44
#eval obs "D09" "no Lean; split by taxon stateable (Mammalia has part hair, Aves has part feather)"

/-! ### D10. "it either happens or it does not" (the-body-s-systems-m45539-92). PASS: the literal "or" is
a tautology and nothing is due from it. The content (all-or-none) is a quality claim, blocked by
`has_quality`, not by disjunction. -/
#no_lean TheBodySSystemsB the_body_s_systems_m45539_92
#eval obs "D10" "no Lean; nothing derived (the or is a tautology)"

/-! ### D11. "Enzymes can also be regulated in ways that either promote or reduce enzyme activity"
(how-cells-obtain-energy-m45437-188). SILENT: GO says it (GO:0043085 and GO:0043086 are both is_a
GO:0050790 on OLS4), but GO:0043085 is not in the imported closure, so BioLean knows only the
negative half. An unsigned "regulates" is the honest coarsening; `Sign` has no unsigned value. -/
#guard !Ontology.isACurie posRegCatalytic.curie regCatalytic.curie
#guard Ontology.isACurie negRegCatalytic.curie regCatalytic.curie
#guard (Curie.encode posRegCatalytic.curie).map Ontology.known = some false
#no_lean HowCellsObtainEnergy how_cells_obtain_energy_m45437_188
#eval obs "D11" "no Lean; closure has GO:0043086 is_a GO:0050790 but not GO:0043085 (not imported)"

/-! ### D12. "If the plant cells become hypertonic, as occurs in drought or if a plant is not watered
adequately, water will leave the cell" (m45434-94). SILENT, but no schema gap: an "or" in the
condition splits exactly, (A or B) then C is (A then C) and (B then C), and both halves are stateable
today. Not in the data (round 2 refused it as ungrounded). -/
def d12_drought : Claim :=
  .rel ContextExamples.hasParticipant (waterExport.inCtx { cellType := plantCellPO.refine Rel.surroundedBy droughtExp }) water
def d12_underwatered : Claim :=
  .rel ContextExamples.hasParticipant (waterExport.inCtx { cellType := plantCellPO.refine Rel.surroundedBy underwatered }) water
#guard shape d12_drought = "rel" ∧ shape d12_underwatered = "rel"
#no_lean CellStructureAndFunction cell_structure_and_function_m45434_94
#eval obs "D12" "no Lean (round 2 ungrounded); both halves of the split stateable as rel"

/-! ### D13. "The replication of DNA occurs ... before the cell enters mitosis or meiosis" (molbio-m45475-4).
R2 picked one disjunct: "DNA replication precedes mitotic nuclear division". The is_a law then gives
"premeiotic DNA replication precedes mitotic nuclear division", established. GO:0006279 is "The
replication of DNA that precedes meiotic cell division" (OLS4), is_a DNA replication through nuclear
DNA replication (OLS4 ancestors; not in the imported closure, so stated as an axiom here). FAIL. The coarsening
"DNA replication precedes nuclear division" (GO:0000280) is also derivable, from the same bad premise. -/
def d13 := BioLean.Textbook.R2.MolecularBiology.molbio_m45475_4
#guard toString d13.claim = "DNA replication [GO:0006260] precedes mitotic nuclear division [GO:0140014]"
def d13_wrong : Derivation (.rel Rel.precedes premeioticRep e_GO_0140014) :=
  .relChain (r₃ := Rel.precedes) (.lit (isaAx premeioticRep e_GO_0006260)) (.lit d13)
theorem d13_wrong_established : d13_wrong.verdict = .established := by decide +kernel
#guard Ontology.isACurie e_GO_0140014.curie e_GO_0000280.curie
def d13_coarse : Derivation (.rel Rel.precedes e_GO_0006260 e_GO_0000280) :=
  .relChain (r₃ := Rel.precedes) (.lit d13) (.lit (isaAx e_GO_0140014 e_GO_0000280))
theorem d13_coarse_established : d13_coarse.verdict = .established := by decide +kernel
#eval obs "D13" s!"R2 asserts '{d13.claim}'; derived '{d13_wrong.claim}' verdict {vstr d13_wrong.verdict}"

/-! ### D17. "The genes may be less involved in critical pathways, or the differences in dosage may make
less of a difference to those pathways" (the-cellular-basis-of-inheritance-m45467-139). Added in review:
a real claim-level "or". Two hedged explanations of why trisomy 21 is survivable (the context, -135
to -138), with different subjects and predicates, so no union entity states it. The book asserts
neither alone. INEXPRESSIBLE: no claim takes two claims, round 2 refused it (blocker `disjunction`),
and the core's `Rivalry` says the opposite ("at most one is true"): evidence for one becomes
disbelief in the other. The two claims use placeholder terms (BLN). -/
def chr21Gene : Entity .gene := ⟨"BLN:chromosome_21_gene", "gene on chromosome 21"⟩
def chr18Gene : Entity .gene := ⟨"BLN:chromosome_18_gene", "gene on chromosome 18"⟩
def inCriticalPathway : Entity .phenotype := ⟨"BLN:involvement_in_critical_pathways", "involvement in critical pathways"⟩
def dosageEffect : Entity .phenotype := ⟨"BLN:dosage_effect_on_pathways", "effect of dosage on pathways"⟩
def d17_h1 : Statement := ⟨"the-cellular-basis-of-inheritance-m45467-139/a", "the genes may be less involved in critical pathways",
  .less chr21Gene chr18Gene inCriticalPathway, [tb "The genes may be less involved in critical pathways"]⟩
def d17_h2 : Statement := ⟨"the-cellular-basis-of-inheritance-m45467-139/b", "dosage differences may matter less",
  .less chr21Gene chr18Gene dosageEffect, [tb "the differences in dosage may make less of a difference"]⟩
#no_lean TheCellularBasisOfInheritance the_cellular_basis_of_inheritance_m45467_139
/-- What the core offers today: each disjunct alone at textbook weight (over-strong), or a rivalry,
which reads them as exclusive and pushes each down by the other. Neither is "at least one". -/
def d17_rivalry : Rivalry := ⟨[d17_h1, d17_h2], by decide⟩
theorem d17_alone_established : litVerdict d17_h1 = .established ∧ litVerdict d17_h2 = .established := by decide +kernel
theorem d17_rivalry_lowers : d17_rivalry.opinions.map (·.2.belief) = [4 / 9, 4 / 9] := by decide +kernel
#eval obs "D17" s!"no Lean (round 2 blocker disjunction); each disjunct alone would stand {vstr (litVerdict d17_h1)}; a Rivalry reads them as exclusive: beliefs {(d17_rivalry.opinions.map (·.2.belief.toDecimal 2))}"

/-! ### D14 to D16 (SYNTHETIC, opinions). The core has no opinion on a disjunction: no claim to carry
it. D14: evidence for A only should give "A or B" at least A's belief and no disbelief. D15: two
refuted, independent disjuncts. D16: two exclusive alternatives from one frame (one enzyme reaction
makes ATP or GTP). All INEXPRESSIBLE today; computed in the prototype. -/
#eval obs "D14" "no claim carries an opinion on A or B (INEXPRESSIBLE)"
#eval obs "D15" "no claim carries an opinion on A or B (INEXPRESSIBLE)"
#eval obs "D16" "no claim carries an opinion on A or B (INEXPRESSIBLE)"

/-! ## A. Approximate numbers -/

/-! ### A01. "a typical human red blood cell is about eight ... micrometers ... in diameter" (m45428-20).
R3: `most (measure (erythrocyte in human) diameter 8 8 µm)`: most red cells are exactly 8 µm. FAIL.
Bandaru and Killeen (PMID 32965812): "approximately 6.2 to 8.2 µm in diameter". -/
def a01 := BioLean.Textbook.R3.CellStructureAndFunction.cell_structure_and_function_m45428_20
#guard shape a01.claim = "quant measure"
#guard bounds a01.claim = some (8, 8)
#eval obs "A01" s!"R3 '{a01.claim}' (point interval [8, 8], 'about' only in the text)"

/-! ### A02. "human red blood cells ... are approximately 8 µm thick" (m45433-32). R3 stores it exact.
Bandaru and Killeen: "a maximal thickness of 2 to 2.5 µm at the periphery and 0.8 to 1 µm at the
center" (we enter 0.8 to 2.5).
FAIL: the textbook value stands established, and the conflict is not reported. `compareIntervals`
even derives "every human red cell is thinner than every human red cell" from the two. -/
def a02 := BioLean.Textbook.R3.CellStructureAndFunction.cell_structure_and_function_m45433_32
#guard bounds a02.claim = some (8, 8)
def a02_data : Statement :=
  { id := "PMID:32965812", text := "RBC thickness 0.8 to 2.5 µm (centre to periphery)",
    claim := .measure (e_CL_0000232.inCtx { taxon := e_NCBITaxon_9606 }) e_PATO_0000915 (4 / 5) (5 / 2) "µm",
    evidence := [paper 32965812 2026 .review "Bandaru and Killeen, Poikilocytosis (StatPearls)"] }
def a02_absurd := compareIntervals (.lit a02_data) (.lit a02)
#guard a02_absurd.claim.subjectCurie = a02.claim.subjectCurie
theorem a02_textbook_established : litVerdict a02 = .established := by decide +kernel
theorem a02_absurd_belief : a02_absurd.opinion.belief = 3 / 5 := by decide +kernel
#eval obs "A02" s!"R3 [8, 8] µm established; with the data, compareIntervals derives '{a02_absurd.claim}' (b={a02_absurd.opinion.belief}), no conflict flag"

/-! ### A03. "The human trachea is a cylinder, about 25 to 30 cm ... long" (the-body-s-systems-m45536-45).
Kumari 2019 (PMID 31828242): tracheal length 10.14 ± 2.04 cm (men), 9.37 ± 1.28 cm (women). FAIL:
[25, 30] stands established; with the data entered, the only reaction is an absurd `less`. -/
def a03 := BioLean.Textbook.R3.TheBodySSystemsA.the_body_s_systems_m45536_45
#guard bounds a03.claim = some (25, 30)
def a03_data : Statement :=
  { id := "PMID:31828242", text := "tracheal length 10.14 ± 2.04 cm in men (mean ± 2 SD: 6.06 to 14.22)",
    claim := .measure (e_UBERON_0003126.inCtx { taxon := e_NCBITaxon_9606 }) e_PATO_0000122 (606 / 100) (1422 / 100) "cm",
    evidence := [paper 31828242 2019 .observational "Kumari 2019, 92 adults, fibreoptic bronchoscopy"] }
def a03_absurd := compareIntervals (.lit a03_data) (.lit a03)
theorem a03_textbook_established : litVerdict a03 = .established := by decide +kernel
theorem a03_absurd_unsupported : a03_absurd.verdict = .unsupported := by decide +kernel
#eval obs "A03" s!"R3 [25, 30] cm established; with the data, only '{a03_absurd.claim}' (b={a03_absurd.opinion.belief}), no conflict flag"

/-! ### A04. "Escherichia coli, is 4.6 million base pairs" (molbio-m45473-77, m45475-94). R3: exact
count 4,600,000. Blattner 1997 (PMID 9278503): 4,639,221 bp for K-12. FAIL: two exact counts on the
same subject coexist; no rule notices they differ, and none can say they agree to two figures. -/
def a04 := BioLean.Textbook.R3.MolecularBiology.molbio_m45473_77
def a04b := BioLean.Textbook.R3.MolecularBiology.molbio_m45475_94
#guard countOf a04.claim = some 4600000 ∧ countOf a04b.claim = some 4600000
def ecoliGenome := e_SO_0001026.inCtx { taxon := e_NCBITaxon_562 }
def a04_data : Statement :=
  { id := "PMID:9278503", text := "The 4,639,221-base pair sequence of Escherichia coli K-12",
    claim := .count ecoliGenome e_SO_0000028 4639221,
    evidence := [paper 9278503 1997 .observational "Blattner 1997"] }
#guard a04_data.claim.subjectCurie = a04.claim.subjectCurie
#guard countOf a04_data.claim ≠ countOf a04.claim
theorem a04_both_established : litVerdict a04 = .established ∧ litVerdict a04_data = .unsupported := by decide +kernel
#eval obs "A04" "R3 count 4600000 established; Blattner's 4639221 on the same subject coexists, no rule relates them"

/-! ### A05. Per-fork share. The book: one origin, replication "in both directions" (m45475-98), so two
forks (SYNTHETIC statement from that text). `perSet` gives exactly 2,300,000 bp per fork from the
rounded number: spurious exactness. From the measured 4,639,221 it gives nothing: the count is odd.
FAIL. -/
def fork : Entity .component := ⟨"GO:0005657", "replication fork"⟩
def a05_forks : Statement :=
  { id := "SYNTHETIC:two-forks", text := "a replicating E. coli genome has two forks (from m45475-98)",
    claim := .count ecoliGenome fork 2, evidence := [tb "proceeding around the chromosome in both directions"] }
def a05_half : Derivation (.count fork e_SO_0000028 2300000) := perSet (.lit a04) (.lit a05_forks)
theorem a05_half_established : a05_half.verdict = .established := by decide +kernel
/-- No natural number is half of 4,639,221, so `perSet` cannot fire on the measured genome. -/
theorem a05_odd : ∀ m : ℕ, 2 * m ≠ 4639221 := by omega
#eval obs "A05" s!"perSet derives exactly '{a05_half.claim}' ({vstr a05_half.verdict}); refuses the measured 4639221 (odd)"

/-! ### A06. "approximately 1000 nucleotides are added per second" (m45475-100), from 4.6 Mbp, two forks
and "approximately 42 minutes" (m45475-97). SILENT: no rule turns a count and a duration into a rate.
The book's own arithmetic gives 2,300,000 / 2,520 s = 912.7 per fork, so "approximately 1000" is
consistent only as an approximation. -/
def a06_rate := BioLean.Textbook.R3.MolecularBiology.molbio_m45475_100
def a06_time := BioLean.Textbook.R3.MolecularBiology.molbio_m45475_97
#guard bounds a06_rate.claim = some (1000, 1000) ∧ bounds a06_time.claim = some (42, 42)
example : (2300000 : ℚ) / (42 * 60) = 57500 / 63 := by norm_num
#guard (57500 / 63 : ℚ) ≠ 1000
#eval obs "A06" "R3 rate [1000, 1000] and time [42, 42] min stored; no rule links count, time and rate"

/-! ### A07. "breathe approximately 15 times per minute" (m45536-16); "about 900 breaths an hour or 21,600
breaths per day" (m45536-17). SILENT: no unit rule links 15 per minute to 900 per hour, though
15 × 60 = 900 and 900 × 24 = 21,600. -/
def a07_min := BioLean.Textbook.R3.TheBodySSystemsA.the_body_s_systems_m45536_16
def a07_hour := BioLean.Textbook.R3.TheBodySSystemsA.the_body_s_systems_m45536_17
#guard bounds a07_min.claim = some (15, 15) ∧ bounds a07_hour.claim = some (900, 900)
#guard a07_min.claim.subjectCurie = a07_hour.claim.subjectCurie
#eval obs "A07" "R3 [15, 15] breaths/min and [900, 900] breaths/h on one subject; no unit rule"

/-! ### A08. Drosophila nervous system "contains around 100,000 neurons, the same number as a lobster"
(m45539-36, -37). R3 stores both as exact 100,000, so "the same number" holds exactly. FAIL.
Dorkenwald 2024 (PMID 39358518): 139,255 neurons in the adult female fly brain alone. -/
def a08_fly := BioLean.Textbook.R3.TheBodySSystemsB.the_body_s_systems_m45539_36
def a08_lobster := BioLean.Textbook.R3.TheBodySSystemsB.the_body_s_systems_m45539_37
theorem a08_same_exactly : countOf a08_fly.claim = countOf a08_lobster.claim := by decide
#guard countOf a08_fly.claim = some 100000
#guard (139255 : ℕ) ≠ 100000
#eval obs "A08" "R3 fly and lobster both exact count 100000 (equal); a 139255 brain count would coexist unflagged"

/-! ### A09. "A human brain contains around 86 billion neurons" (m45539-40). R3: exact 86,000,000,000.
Azevedo 2009 (PMID 19226510): 86.1 ± 8.1 billion. FAIL: the exact claim is false as stated; no rule
compares it with the paper's spread. -/
def a09 := BioLean.Textbook.R3.TheBodySSystemsB.the_body_s_systems_m45539_40
#guard countOf a09.claim = some 86000000000
#eval obs "A09" "R3 exact count 86000000000 established; no spread"

/-! ### A10. Human brain against fly nervous system (86 billion against about 100,000). SILENT: the only
comparison rule, `compareIntervals`, takes `measure` claims; counts have none. -/
#check_failure (compareIntervals (.lit a08_fly) (.lit a09))
#eval obs "A10" "compareIntervals refuses count claims (check_failure); no 'fewer' conclusion"

/-! ### A11. "lengths ranging from approximately 50 amino acids to more than 1,000" (molbio-m45479-7). R3:
`atLeast polypeptide amino-acid 50`. ChEBI CHEBI:15841 "polypeptide": "A peptide containing ten or
more amino acid residues". FAIL: a 20-residue polypeptide is one by ChEBI and refutes the bound. -/
def a11 := BioLean.Textbook.R3.MolecularBiology.molbio_m45479_7
#guard shape a11.claim = "atLeast" ∧ countOf a11.claim = some 50
theorem a11_established : litVerdict a11 = .established := by decide +kernel
#eval obs "A11" s!"R3 '{a11.claim}' established (every polypeptide has >= 50)"

/-! ### A12. "about 1,000 new neurons develop in the hippocampus ... each day", for mammals (m45539-127).
Cameron and McKay 2001 (PMID 11406822): about 9,000 new cells a day in the young adult rat dentate
gyrus; Spalding 2013 (PMID 23746839): 700 new neurons per hippocampus per day in adult humans;
Sorrells 2018 (PMID 29513649): undetectable in adult humans. FAIL: the Mammalia claim stands at 0.8,
and no rule takes a measure from a clade to a member, so the data never meet it. -/
def a12 := BioLean.Textbook.R3.TheBodySSystemsB.the_body_s_systems_m45539_127
#guard bounds a12.claim = some (1000, 1000)
theorem a12_established : litVerdict a12 = .established := by decide +kernel
#guard Ontology.isACurie Taxa.rat.curie Taxa.mammalia.curie
#eval obs "A12" "R3 Mammalia [1000, 1000] neurons/day established; no rule from clade measure to rat or human"

/-! ### A13. "approximately 250 red blood cells could fit on the head of a pin" (m45428-22), from "about
eight millionths of a meter or eight micrometers" and "about two thousandths of a meter" (m45428-20, -21). SILENT: -21 and -22 have
no Lean, and no rule divides two measures. 2 mm / 8 µm = 250 exactly: that is the number of cells
across the pin head. "Fit on" read as covering the head is about π/4 × 250² ≈ 49,000 cells, so the
book's wording is loose; the case tests the ratio, not the area. -/
example : (2000 : ℚ) / 8 = 250 := by norm_num
#no_lean CellStructureAndFunction cell_structure_and_function_m45428_21
#no_lean CellStructureAndFunction cell_structure_and_function_m45428_22
#eval obs "A13" "m45428-21, -22 not in Lean; no rule divides measures"

/-! ### A14. Control: exact counts stay exact. Codon degeneracy by pigeonhole (61 sense codons, 20 amino
acids). PASS. -/
theorem a14_degeneracy : BioLean.Quantity.degeneracy.verdict = .established := by decide +kernel
#eval obs "A14" s!"pigeonhole gives '{BioLean.Quantity.degeneracy.claim}' ({vstr BioLean.Quantity.degeneracy.verdict})"

/-! ### A15. Control: 46 chromosomes in 2 sets gives 23 per set (`perSet`). PASS; exact by nature. -/
theorem a15_perSet : BioLean.Quantity.perSet23.verdict = .established := by decide +kernel
#eval obs "A15" s!"perSet gives '{BioLean.Quantity.perSet23.claim}' ({vstr BioLean.Quantity.perSet23.verdict})"

/-! ### A16. SYNTHETIC. Net yield of two rounded numbers: "about 100 made, about 90 used". `netYield`
gives exactly 10. With 10 percent either way the net lies in [-9, 29]: even the sign is unknown. FAIL. -/
def proc : Entity .process := ⟨"BLN:synthetic_process", "a synthetic process"⟩
def a16_made : Statement := ⟨"SYNTHETIC:made-100", "about 100 made", .produces proc e_CHEBI_15422 100, [tb "synthetic"]⟩
def a16_used : Statement := ⟨"SYNTHETIC:used-90", "about 90 used", .consumes proc e_CHEBI_15422 90, [tb "synthetic"]⟩
def a16_net : Derivation (.yield proc e_CHEBI_15422 10) := netYield (.lit a16_made) (.lit a16_used)
theorem a16_net_established : a16_net.verdict = .established := by decide +kernel
#eval obs "A16" s!"netYield derives exactly '{a16_net.claim}' ({vstr a16_net.verdict})"

/-! ### A17. SYNTHETIC. Pigeonhole on rounded numbers: "about 22 items, about 20 holes". `pigeonhole`
fires (20 < 22). With 10 percent either way there may be 19.8 items and 22 holes: nothing is due. FAIL. -/
def item : Entity .gene := ⟨"BLN:item", "item"⟩
def hole : Entity .chemical := ⟨"BLN:hole", "hole"⟩
def a17 : Derivation (.quant .some (.atLeast hole item 2)) :=
  pigeonhole (.lit ⟨"SYNTHETIC:22", "about 22 items", .cardinality item 22, [tb "synthetic"]⟩)
    (.lit ⟨"SYNTHETIC:20", "about 20 holes", .cardinality hole 20, [tb "synthetic"]⟩)
    (.lit ⟨"SYNTHETIC:one-each", "each item has one hole", .count item hole 1, [tb "synthetic"]⟩)
theorem a17_established : a17.verdict = .established := by decide +kernel
#eval obs "A17" s!"pigeonhole fires on 22 vs 20: '{a17.claim}' ({vstr a17.verdict})"

/-! ### A18. "approximately 8 µm thick, or approximately 1,000 times thicker than a plasma membrane"
(m45433-33). R3 keeps only `less` (plasma membrane thinner than a red cell). PASS: the weakening is
true, and it drops a ratio that is wrong (a red cell is at most 2 to 2.5 µm thick, Bandaru and Killeen). -/
def a18 := BioLean.Textbook.R3.CellStructureAndFunction.cell_structure_and_function_m45433_33
#guard shape a18.claim = "less"
#guard toString a18.claim = "plasma membrane [GO:0005886] < red blood cells [CL:0000232] in thickness [PATO:0000915]"
#eval obs "A18" s!"R3 keeps only '{a18.claim}'; the 1000x ratio is dropped"

/-! ## A-a. The same cases with the tolerance written as data (no core change)

Option A-a: the emitter writes "about n" as an interval (± 10 percent here), using the core's own
`measure` and `countBetween`. Observed, not predicted. -/

/-- A lint outside the core: two measures of one quality of one subject whose intervals are
disjoint cannot both hold. -/
def disjointSameSubject (a b : Claim) : Bool :=
  match a, b with
  | .measure x q lo₁ hi₁ u, .measure y r lo₂ hi₂ v =>
      x.curie == y.curie && q.curie == r.curie && u == v && (decide (hi₁ < lo₂) || decide (hi₂ < lo₁))
  | .quant _ a, b => disjointSameSubject a b
  | _, _ => false

def humanRbc := e_CL_0000232.inCtx { taxon := e_NCBITaxon_9606 }
-- A01a: about 8 µm as [7.2, 8.8]. It overlaps the data (6.2 to 8.2), so compareIntervals refuses.
def a01a : Statement := ⟨"cell-structure-and-function-m45428-20/Aa", "about 8 µm, ±10 percent",
  .quant .most (.measure humanRbc e_PATO_0001334 (36/5) (44/5) "µm"), [tb "about eight micrometers"]⟩
def a01a_data : Statement := ⟨"PMID:32965812/d", "6.2 to 8.2 µm", .measure humanRbc e_PATO_0001334 (31/5) (41/5) "µm",
  [paper 32965812 2026 .review "Bandaru and Killeen"]⟩
#guard !disjointSameSubject a01a.claim a01a_data.claim
def a01a_plain : Statement := { a01a with claim := .measure humanRbc e_PATO_0001334 (36/5) (44/5) "µm" }
#check_failure (compareIntervals (.lit a01a_data) (.lit a01a_plain))
-- A02a: [7.2, 8.8] against 0.8 to 2.5: the core still derives the absurd `less`; only the lint flags it.
def a02a : Statement := ⟨"cell-structure-and-function-m45433-32/Aa", "about 8 µm thick, ±10 percent",
  .measure humanRbc e_PATO_0000915 (36/5) (44/5) "µm", [tb "approximately 8 µm thick"]⟩
def a02a_absurd := compareIntervals (.lit a02_data) (.lit a02a)
theorem a02a_absurd_belief : a02a_absurd.opinion.belief = 3 / 5 := by decide +kernel
#guard disjointSameSubject a02a.claim a02_data.claim
-- A03a: the stated range [25, 30] against Kumari's 6.06 to 14.22: the lint flags it too (observed).
#guard disjointSameSubject a03.claim a03_data.claim
-- A04a: 4.6 million as countBetween 4,550,000 to 4,650,000 (last stated digit). Blattner's value lies inside.
def a04a : Claim := .countBetween ecoliGenome e_SO_0000028 4550000 4650000
#guard shape a04a = "countBetween" ∧ 4550000 ≤ 4639221 ∧ 4639221 ≤ 4650000
-- A05a: perSet does not take a countBetween, so the spurious exact half is not derived.
def a04a_stmt : Statement := ⟨"molbio-m45473-77/Aa", "4.6 million bp", a04a, [tb "4.6 million base pairs"]⟩
#check_failure (perSet (.lit a04a_stmt) (.lit a05_forks))
-- A09a: "around 86 billion" as countBetween ±10 percent holds Azevedo's mean of 86.1 billion; the
-- exact R3 count does not.
def humanBrain := e_UBERON_0000955.inCtx { taxon := e_NCBITaxon_9606 }
def a09a : Claim := .countBetween humanBrain e_CL_0000540 77400000000 94600000000
#guard a09a.subjectCurie = a09.claim.subjectCurie
#guard 77400000000 ≤ 86100000000 ∧ 86100000000 ≤ 94600000000 ∧ countOf a09.claim ≠ some 86100000000
-- A16a, A17a: produces, consumes and cardinality have no interval form in the core, so "about 100
-- made" and "about 22 items" stay exact and the FAILs stay. Pinned by `coreShapes` above.
#eval obs "Aa" "A01: [7.2, 8.8] overlaps the data, no absurd less. A02: absurd less still derived (b=3/5), lint flags it. A03: lint flags [25, 30] against 6.06 to 14.22. A04: countBetween holds Blattner's value. A05: perSet refuses countBetween. A09: countBetween [77.4, 94.6] billion holds Azevedo's 86.1 billion. A16, A17: no interval form for produces, consumes, cardinality"

/-! ## C. A second context slot -/

/-! ### C01. "When the cells lining a blood vessel are damaged, they display ... tissue factor"
(m45432-280). R3 puts "damaged" on the organism: endothelial cell in a blood vessel of a damaged
cellular organism. FAIL (wrong bearer). Mackman 2007 (PMID 17556654): tissue factor is expressed by
endothelial cells under pathological conditions. Nesting the state on the subject by hand states it
right, today. -/
def c01 := BioLean.Textbook.R3.CellStructureAndFunction.cell_structure_and_function_m45432_280
#guard c01.claim.subjectCurie =
  "CL:0000115&RO:0001025=(UBERON:0001981)&RO:0002162=(NCBITaxon:131567&RO:0002573=(PATO:0001167))"
def c01_nested := (e_CL_0000115.refine Rel.hasModifier e_PATO_0001167).inCtx { anatomy := e_UBERON_0001981 }
#guard c01_nested.curie = "CL:0000115&RO:0002573=(PATO:0001167)&RO:0001025=(UBERON:0001981)"
#eval obs "C01" s!"R3 subject '{c01.claim.subjectCurie}' (damaged organism, not damaged cells)"

/-! ### C02. "In rapidly dividing human cells with a 24-hour cell cycle, the G1 phase lasts approximately
11 hours" (reproduction-at-the-cellular-level-m45461-123). R3 makes the cells' state a state of the
human. FAIL (wrong bearer). A state cannot sit on the process (has_modifier's domain refuses it), but
it can sit on the cell-type filler, today, by nesting. -/
def c02 := BioLean.Textbook.R3.ReproductionAtTheCellularLevel.reproduction_at_the_cellular_level_m45461_123
#guard c02.claim.subjectCurie =
  "GO:0051318&RO:0002162=(NCBITaxon:9606&RO:0002573=(BLN:rapidly_dividing_24h_cell_cycle))"
#guard !Rel.hasModifier.accepts .process .phenotype
#guard Rel.hasModifier.accepts .cellType .phenotype
def rapid : Entity .phenotype := ⟨"BLN:rapidly_dividing", "rapidly dividing"⟩
def c02_nested := e_GO_0051318.inCtx { taxon := Taxa.human, cellType := e_CL_0000000.refine Rel.hasModifier rapid }
#guard c02_nested.curie = "GO:0051318&BFO:0000066=(CL:0000000&RO:0002573=(BLN:rapidly_dividing))&RO:0002162=(NCBITaxon:9606)"
#eval obs "C02" s!"R3 subject '{c02.claim.subjectCurie}' (a rapidly dividing human)"

/-! ### C03. "When fast-dividing mammalian cells are grown in culture ..., the length of the cycle is
approximately 24 hours" (m45461-122). Two conditions on the cells: a state and a culture. SILENT:
not emitted (OBI was not a supported prefix), and `Ctx` has one condition. Stateable by nesting both
on the cell-type filler. -/
def inCulture : Entity .phenotype := ⟨"BLN:grown_in_culture", "grown in culture"⟩
def cellCycle : Entity .process := ⟨"GO:0007049", "cell cycle"⟩
def c03_nested := cellCycle.inCtx
  { taxon := Taxa.mammalia, cellType := (e_CL_0000000.refine Rel.hasModifier rapid).refine Rel.hasModifier inCulture }
#no_lean ReproductionAtTheCellularLevel reproduction_at_the_cellular_level_m45461_122
#guard c03_nested.curie = "GO:0007049&BFO:0000066=(CL:0000000&RO:0002573=(BLN:rapidly_dividing)&RO:0002573=(BLN:grown_in_culture))&RO:0002162=(NCBITaxon:40674)"
#eval obs "C03" "no Lean; stateable only by nesting two has_modifier on the cell-type filler"

/-! ### C04. Telomerase reactivation "in aged telomerase-deficient mice" (Jaskelioff 2011, PMID 21113150;
book molbio-m45475-83). R3 keeps one state (telomerase-deficient) and drops "aged". Two organism
states fit only if one pre-refines the taxon; such a taxon is not known, so `transport` refuses it.
SILENT: the one-state version transports to rat; the two-state one cannot. -/
def c04 := BioLean.Textbook.R3.MolecularBiology.molbio_m45475_83
#guard c04.claim.subjectCurie = "GO:0003720&RO:0002162=(NCBITaxon:10090&RO:0002573=(BLN:telomerase_deficient))"
def aged : Entity .phenotype := ⟨"PATO:0001764", "increased age"⟩
def agedMouse := e_NCBITaxon_10090.refine Rel.hasModifier aged
#guard !Taxa.known agedMouse
#guard !Taxa.siblings agedMouse Taxa.rat
#guard Taxa.siblings e_NCBITaxon_10090 Taxa.rat
def c04_two : Statement :=
  { id := "PMID:21113150", text := "telomerase reactivation reverses neurodegeneration in aged telomerase-deficient mice",
    claim := .effect (e_GO_0003720.inCtx { taxon := agedMouse, condition := some (.organism e_BLN_telomerase_deficient) })
      .neg (.phenotype e_HP_0002180),
    evidence := [paper 21113150 2011 .mechanistic "Jaskelioff 2011"] }
def xs : Evidence := { pmid := 0, year := 2026, kind := .crossSpecies, note := "placeholder mouse-to-rat item" }
/-- One state: transport from mouse to rat works (the R3 statement as it is). -/
def c04_one : Derivation (.effect (e_GO_0003720.inCtx { taxon := Taxa.rat, condition := some (.organism e_BLN_telomerase_deficient) })
    .neg (.phenotype e_HP_0002180)) :=
  .transport { condition := some (.organism e_BLN_telomerase_deficient) } (T₁ := e_NCBITaxon_10090) Taxa.rat (.lit c04) xs
theorem c04_one_belief : c04_one.opinion.belief = 6 / 25 := by decide +kernel
-- Two states: it does not (`hs`: an aged mouse is not a known taxon).
#check_failure (Derivation.transport (T₁ := agedMouse) { condition := some (.organism e_BLN_telomerase_deficient) } Taxa.rat (.lit c04_two) xs)
#eval obs "C04" s!"R3 drops 'aged'; one-state transport to rat gives b={c04_one.opinion.belief}; two-state transport refused (aged mouse not a known taxon)"

/-! ### C05. The same two states, nested in two orders, are two classes. FAIL (identity): evidence on one
never fuses with evidence on the other, and no rule says they are equal. The same holds for two
environments (lactose and glucose), nested by hand. -/
def c05_ab := (e_NCBITaxon_10090.refine Rel.hasModifier aged).refine Rel.hasModifier e_BLN_telomerase_deficient
def c05_ba := (e_NCBITaxon_10090.refine Rel.hasModifier e_BLN_telomerase_deficient).refine Rel.hasModifier aged
theorem c05_two_curies : c05_ab ≠ c05_ba := by decide
theorem c05_env_two_curies :
    (e_NCBITaxon_562.refine Rel.surroundedBy e_CHEBI_17716).refine Rel.surroundedBy e_CHEBI_17234 ≠
    (e_NCBITaxon_562.refine Rel.surroundedBy e_CHEBI_17234).refine Rel.surroundedBy e_CHEBI_17716 := by decide
#eval obs "C05" s!"two nesting orders give two curies: {c05_ab.curie} vs {c05_ba.curie}"

/-! ### C06. Control. Celiac disease as one organism state (m45432-24). PASS. -/
def c06 := BioLean.Textbook.R3.CellStructureAndFunction.cell_structure_and_function_m45432_24
#guard c06.claim.subjectCurie = "GO:0006955&RO:0002162=(NCBITaxon:9606&RO:0002573=(MONDO:0005130))"
#eval obs "C06" s!"R3 subject '{c06.claim.subjectCurie}'"

/-! ### C07. Control. X inactivation in female mammalian embryos (the-cellular-basis-of-inheritance-m45467-58):
taxon, life stage and one state, each in its own slot. PASS. Lyon 1961 (PMID 13764598). -/
def c07 := BioLean.Textbook.R3.TheCellularBasisOfInheritance.the_cellular_basis_of_inheritance_m45467_58
#guard c07.claim.subjectCurie =
  "GO:0009048&RO:0002092=(UBERON:0000068)&RO:0002162=(NCBITaxon:40674&RO:0002573=(PATO:0000383))"
#eval obs "C07" s!"R3 subject '{c07.claim.subjectCurie}'"

/-! ### C08. "In a hypotonic solution ... water enters the cell" (m45434-70). R3 puts the solution around
the process (import into cell ⊓ surrounded_by hypotonic), not around the cell. FAIL (wrong bearer).
`Examples/Context.lean` already nests it on the cell-type filler, which is right. -/
def c08 := BioLean.Textbook.R3.CellStructureAndFunction.cell_structure_and_function_m45434_70
#guard c08.claim.subjectCurie = "GO:0098657&BFO:0000066=(CL:0000000)&RO:0002219=(PATO:0001656)"
#guard (BioLean.ContextExamples.importIntoCell.inCtx { cellType := BioLean.ContextExamples.cellInHypotonic }).curie.startsWith
  "GO:0098657&BFO:0000066=(CL:0000000&RO:0002219=("
#eval obs "C08" s!"R3 subject '{c08.claim.subjectCurie}' (solution around the process)"

/-! ### C09. "On a hot, dry day, plants close their stomata to conserve water" (photosynthesis-m45448-84).
Two conditions fused into one BLN term. PASS on the main question: nothing derives "plants close
their stomata when hot", which Urban 2017 (PMID 28338959) contradicts ("Increases in leaf temperature
caused stomatal opening"). -/
def c09 := BioLean.Textbook.R3.Photosynthesis.photosynthesis_m45448_84
#guard c09.claim.subjectCurie = "NCBITaxon:33090&RO:0002219=(BLN:hot_dry_day)"
-- dropping a refinement from the subject has no rule (as in `Examples/Context.lean`)
#check_failure (Derivation.lit c09 : Derivation (.rel Rel.capableOf e_NCBITaxon_33090 e_GO_0090332))
#eval obs "C09" s!"R3 subject '{c09.claim.subjectCurie}'; no rule drops the condition"

/-! ### C10. The same sentence against drought. SILENT: "hot, dry day" is one opaque term, so a
drought claim ("plants in drought close stomata", Liu 2022, PMID 36499153: "Stomatal closure is an
efficient way for plants to reduce water loss ... under drought conditions") cannot specialise to it. -/
#guard !Ontology.isACurie "BLN:hot_dry_day" droughtExp.curie
def c10_drought : Statement :=
  { id := "PMID:36499153", text := "stomatal closure under drought",
    claim := .rel Rel.capableOf (e_NCBITaxon_33090.inCtx { condition := some (.environment droughtExp) }) e_GO_0090332,
    evidence := [paper 36499153 2022 .review "Liu 2022"] }
#check_failure (Derivation.lit c10_drought : Derivation c09.claim)
#eval obs "C10" "a drought claim does not reach the hot-dry-day subject (opaque BLN term, no is_a)"

/-! ### C11. Specialising across a second condition. R3 (molbio-m45480-33): "When lactose is present, the
genes are transcribed and the bacterium is able to use the lactose as a food source", as lactose in
E. coli →+ lactose catabolism. Add a second condition, E. coli surrounded by glucose: the is_a laws
derive the same effect, established at 0.8. Inada 1996 (PMID 9133663): glucose represses
beta-galactosidase in glucose-lactose medium, by inducer exclusion. FAIL. No option in this program
fixes it: refinement is monotone, biology is not.
The glucose medium surrounds the bacterium, so it refines the taxon filler with `surrounded_by`. The
core `Ctx` cannot write that: an environment refines the subject (here lactose), and an organism
state uses `has_modifier`, which is for qualities. So it is nested by hand. (Review 2026-10-31: the
first version wrote glucose as `has_modifier`, a quality of E. coli; the result is the same.) -/
def c11 := BioLean.Textbook.R3.MolecularBiology.molbio_m45480_33
#guard c11.claim.subjectCurie = "CHEBI:17716&RO:0002162=(NCBITaxon:562)"
def ecoliOnGlucose := e_NCBITaxon_562.refine Rel.surroundedBy e_CHEBI_17234
def c11_onGlucose : Derivation (.effect (e_CHEBI_17716.refine Rel.inTaxon ecoliOnGlucose) .pos (.process e_GO_0005990)) :=
  .isaInheritEffect (.refineMono (e := e_CHEBI_17716) (r := Rel.inTaxon)
    (.lit (Entity.refineAxiom e_NCBITaxon_562 Rel.surroundedBy e_CHEBI_17234))) (.lit c11)
#guard c11_onGlucose.claim.subjectCurie = "CHEBI:17716&RO:0002162=(NCBITaxon:562&RO:0002219=(CHEBI:17234))"
theorem c11_established : c11_onGlucose.verdict = .established := by decide +kernel
#eval obs "C11" s!"derived '{c11_onGlucose.claim}' ({vstr c11_onGlucose.verdict})"

/-! ### C12. The same move where it is right. R3 (molbio-m45480-41): allolactose (lactose present)
inhibits the lac repressor. On glucose too: Inada 1996 shows glucose acts by keeping the inducer out,
and that inactivating the repressor (lacI disruption or IPTG) abolishes glucose repression. PASS
for the conclusion. But the result has two environments on two bearers (lactose around allolactose,
as R3 writes it; glucose around the bacterium), which `Ctx` cannot hold together: the subject exists
only as a hand-nested entity. -/
def c12 := BioLean.Textbook.R3.MolecularBiology.molbio_m45480_41
#guard c12.claim.subjectCurie = "CHEBI:36229&RO:0002219=(CHEBI:17716)&RO:0002162=(NCBITaxon:562)"
def c12_onGlucose :=
  Derivation.isaInheritEffect (.refineMono (e := e_CHEBI_36229.refine Rel.surroundedBy e_CHEBI_17716) (r := Rel.inTaxon)
    (.lit (Entity.refineAxiom e_NCBITaxon_562 Rel.surroundedBy e_CHEBI_17234))) (.lit c12)
#guard c12_onGlucose.claim.subjectCurie = "CHEBI:36229&RO:0002219=(CHEBI:17716)&RO:0002162=(NCBITaxon:562&RO:0002219=(CHEBI:17234))"
theorem c12_established : c12_onGlucose.verdict = .established := by decide +kernel
#eval obs "C12" s!"derived '{c12_onGlucose.claim.subjectCurie}' ({vstr c12_onGlucose.verdict}); not an inCtx form (two conditions)"

/-! ### C13. Male tortoiseshell cats (Centerwall and Benirschke 1973, PMID 4798734). Book: X inactivation
in tortoiseshell cats gives coat-colour variegation (m45467-63). With two organism states, the result
depends on nesting order: (cat ⊓ tortoiseshell) ⊓ male inherits it; (cat ⊓ male) ⊓ tortoiseshell
does not, since no rule says refinement is monotone in its base. SILENT in one order. -/
def c13 := BioLean.Textbook.R3.TheCellularBasisOfInheritance.the_cellular_basis_of_inheritance_m45467_63
def male : Entity .phenotype := ⟨"PATO:0000384", "male"⟩
#guard c13.claim.subjectCurie = "GO:0009048&RO:0002162=(NCBITaxon:9685&RO:0002573=(BLN:tortoiseshell))"
def c13_handOrder :=
  Derivation.isaInheritEffect (.refineMono (e := e_GO_0009048) (r := Rel.inTaxon)
    (.lit (Entity.refineAxiom (e_NCBITaxon_9685.refine Rel.hasModifier e_BLN_tortoiseshell) Rel.hasModifier male))) (.lit c13)
#guard c13_handOrder.claim.subjectCurie = "GO:0009048&RO:0002162=(NCBITaxon:9685&RO:0002573=(BLN:tortoiseshell)&RO:0002573=(PATO:0000384))"
theorem c13_hand_established : c13_handOrder.verdict = .established := by decide +kernel
-- the other order: the refinement axiom drops only the outer state, so it reaches (cat ⊓ male)
def c13_otherOrder := e_GO_0009048.refine Rel.inTaxon ((e_NCBITaxon_9685.refine Rel.hasModifier male).refine Rel.hasModifier e_BLN_tortoiseshell)
#guard c13_otherOrder.curie ≠ c13_handOrder.claim.subjectCurie
#check_failure (c13_handOrder : Derivation (.effect c13_otherOrder .pos (.phenotype e_PATO_0001533)))
#eval obs "C13" "derivable for (cat & tortoiseshell) & male; not for (cat & male) & tortoiseshell: two curies, no rule between them"

/-! ### C14. "Alpha cells release glucagon as blood-glucose levels decline" (the-body-s-systems-m45537-199).
R3: glucose →− amount of (glucagon located in blood ⊓ part of alpha cell). One molecule cannot be
both in the blood and part of the cell: the source (secreted by) is squeezed into a location slot.
FAIL (wrong reading). CL:0000171 pancreatic A cell is defined on OLS4 as secreting glucagon. The
right reading, glucose →− glucagon secretion (GO:0070091) in alpha cells, is stateable today. -/
def c14 := BioLean.Textbook.R3.TheBodySSystemsB.the_body_s_systems_m45537_199
#guard toString c14.claim = "glucose [CHEBI:17234] →− amount of glucagon ⊓ located in (blood) ⊓ part of (pancreatic alpha cell) [PR:P01275&RO:0001025=(UBERON:0000178)&BFO:0000050=(CL:0000171)]"
def glucagonSecretion : Entity .process := ⟨"GO:0070091", "glucagon secretion"⟩
def c14_right : Claim := .effect e_CHEBI_17234 .neg (.process (glucagonSecretion.inCtx { cellType := e_CL_0000171 }))
#guard c14_right.toString.endsWith "[GO:0070091&BFO:0000066=(CL:0000171)]"
#eval obs "C14" "R3 target glucagon located in blood and part of alpha cell; secretion form stateable"

/-! ### C15. Control. "Telomerase is not active in adult somatic cells" (molbio-m45475-71): a cell type and
a life stage, two conditions in two existing slots. PASS on the slots. Kim 1994 (PMID 7605428): "none
of 50 normal somatic tissues were positive". Note: CL:0002371 "somatic cell" is obsolete on OLS4. -/
def c15 := BioLean.Textbook.R3.MolecularBiology.molbio_m45475_71
#guard shape c15.claim = "notRel"
#guard c15.claim.subjectCurie = "GO:0005697&BFO:0000050=(CL:0002371)&RO:0002490=(UBERON:0000113)"
#eval obs "C15" s!"R3 subject '{c15.claim.subjectCurie}' (cell type and life stage in two slots)"

end BioLean.Stress.SchemaGaps
