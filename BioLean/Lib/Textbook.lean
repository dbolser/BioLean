import BioLean.Derivation
import BioLean.Lib.TextbookEntities

/-!
# Textbook statements and the derivations they allow

Statements are OpenStax *Concepts of Biology* sentences (claim ids from
`data/textbook/claims/`) or OBO ontology axioms. The derivations are the shapes that
`docs/textbook-derivations.md` found blocked for want of relational claims.
-/

namespace BioLean.Textbook
open Rel

/-- A textbook sentence as evidence. OpenStax has no PMID; 0 marks "not a paper". -/
def tb (note : String) : Evidence := { pmid := 0, year := 2013, kind := .textbook, note := note }
/-- An OBO axiom as evidence. -/
def ax (note : String) : Evidence := { pmid := 0, year := 2026, kind := .ontologyAxiom, note := note }

/-! ### produces: `inverse(occurs_in) ∘ has_output ⊑ produces` (RO:0003000) -/

def S_steroid_in_gonad : Statement where
  id := "body:m45537-204a"; text := "steroid hormone synthesis takes place in the gonads"
  claim := .rel occursIn steroidogenesis gonad
  evidence := [tb "The gonads produce steroid hormones (OpenStax 16.4)"]

def S_steroid_output : Statement where
  id := "GO:0006694-def"; text := "steroid biosynthesis has output steroid"
  claim := .rel hasOutput steroidogenesis steroidHormone
  evidence := [ax "GO:0006694 definition: chemical reactions resulting in the formation of steroids"]

/-- The textbook sentence "the gonads produce steroid hormones", as a theorem. -/
def gonad_produces_steroid : Derivation (.rel produces gonad steroidHormone) :=
  .relChain (.relInv (.lit S_steroid_in_gonad) occursIn.flip) (.lit S_steroid_output)

/-! ### occurs_in lifts along part_of: `occurs_in ∘ part_of ⊑ occurs_in` -/

def S_glycolysis_cytosol : Statement where
  id := "energy:m45438-30"; text := "glycolysis takes place in the cytoplasm"
  claim := .rel occursIn glycolysis cytosol
  evidence := [tb "Glycolysis ... occurs in the cytoplasm (OpenStax 4.2)"]

def S_cytosol_cell : Statement where
  id := "GO:0005829-partOf"; text := "cytosol part_of cell"
  claim := .rel partOf cytosol cell
  evidence := [ax "GO:0005829 part_of GO:0005737 cytoplasm part_of cell"]

def glycolysis_in_cell : Derivation (.rel occursIn glycolysis cell) :=
  .relChain (.lit S_glycolysis_cytosol) (.lit S_cytosol_cell)

/-! ### part_of is transitive -/

def S_asc_colon : Statement where
  id := "body:m45535-266"; text := "the colon consists of ascending, transverse and descending colon"
  claim := .rel partOf ascendingColon colon
  evidence := [tb "OpenStax 15.2"]

def S_colon_li : Statement where
  id := "UBERON:0001155-partOf"; text := "colon part_of large intestine"
  claim := .rel partOf colon largeIntestine
  evidence := [ax "UBERON:0001155 part_of UBERON:0000059"]

def asc_colon_in_large_intestine : Derivation (.rel partOf ascendingColon largeIntestine) :=
  .relChain (.lit S_asc_colon) (.lit S_colon_li)

/-! ### is_a inherits relations -/

def S_euk_nucleus : Statement where
  id := "cell:m45429-57"; text := "eukaryotic cells have a membrane-bound nucleus"
  claim := .rel hasPart eukaryoticCell nucleus
  evidence := [tb "OpenStax 3.3", ax "CL:0000255 has_part GO:0005634"]

def S_hepatocyte_isa : Statement where
  id := "CL:0000182-isa"; text := "hepatocyte is_a eukaryotic cell"
  claim := .rel isA hepatocyte eukaryoticCell
  evidence := [ax "CL:0000182 subClassOf* CL:0000255"]

def hepatocyte_has_nucleus : Derivation (.rel hasPart hepatocyte nucleus) :=
  .relChain (.lit S_hepatocyte_isa) (.lit S_euk_nucleus)

/-! ### A genuine negation, inherited down is_a -/

def S_prok_no_nucleus : Statement where
  id := "cell:m45429-50"; text := "a prokaryotic cell lacks a nucleus"
  claim := .notRel hasPart prokaryoticCell nucleus
  evidence := [tb "Prokaryotic cells ... lack a nucleus (OpenStax 3.2)"]

def S_heterocyst_isa : Statement where
  id := "CL:0000724-isa"; text := "heterocyst is_a prokaryotic cell"
  claim := .rel isA heterocyst prokaryoticCell
  evidence := [ax "CL:0000724 subClassOf CL:0000520"]

def heterocyst_no_nucleus : Derivation (.notRel hasPart heterocyst nucleus) :=
  .notRelSub (.lit S_heterocyst_isa) (.lit S_prok_no_nucleus)

/-- A deliberately wrong text-mined statement, to show a clash. -/
def S_heterocyst_nucleus_mined : Statement where
  id := "mined-001"; text := "heterocysts contain a nucleus"
  claim := .rel hasPart heterocyst nucleus
  evidence := [{ pmid := 1, year := 2020, kind := .textMined, note := "misread of 'nucleoid'" }]

end BioLean.Textbook
