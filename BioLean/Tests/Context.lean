import BioLean.Derivation

/-!
# Tests for context (M2)

`Entity.inCtx` is deterministic, `Entity.refine` checks RO domain and range, and `transport`
moves only between sibling taxa.
-/

namespace BioLean.Context.Tests
open Rel Taxa

def hepatocyte : Entity .cellType := ⟨"CL:0000182", "hepatocyte"⟩
def liver : Entity .anatomy := ⟨"UBERON:0002107", "liver"⟩
def glycolysis : Entity .process := ⟨"GO:0006096", "glycolytic process"⟩
def glucose : Entity .chemical := ⟨"CHEBI:17234", "glucose"⟩
def aged : Entity .phenotype := ⟨"BLN:aged", "aged"⟩

-- inCtx determinism: one context, one curie, whatever order the literal is written in
example : glucose.inCtx { taxon := mouse, anatomy := liver, cellType := hepatocyte } =
    glucose.inCtx { cellType := hepatocyte, anatomy := liver, taxon := mouse } := rfl
example : (glucose.inCtx { taxon := mouse, anatomy := liver }).curie =
    "CHEBI:17234&RO:0001025=(UBERON:0002107)&RO:0002162=(NCBITaxon:10090)" := by decide
-- the empty context is the bare entity
example : glucose.inCtx {} = glucose := rfl
-- processes occur in a site, continuants are located in it
example : (glycolysis.inCtx { anatomy := liver }).curie = "GO:0006096&BFO:0000066=(UBERON:0002107)" := by decide
-- an organism state goes on the taxon filler, not on the subject
example : glucose.inCtx { taxon := mouse, condition := some (.organism aged) } =
    glucose.refine inTaxon (mouse.refine hasModifier aged) := rfl
example : glucose.inCtx { taxon := mouse, condition := some (.organism aged) } ≠
    (glucose.inCtx { taxon := mouse }).refine hasModifier aged := by decide

-- domain check: a process cannot be located_in (domain continuant), nor has_modifier
#check_failure glycolysis.refine locatedIn liver
#check_failure glycolysis.refine hasModifier aged
-- range check: in_taxon needs a continuant filler
#check_failure glucose.refine inTaxon glycolysis

-- the taxon table
example : siblings mouse human = true := by decide
example : siblings bacteria archaea = true := by decide
example : siblings mouse mammalia = false := by decide        -- generalisation, not transport
example : siblings mammalia mouse = false := by decide        -- specialisation is free, not transport
example : siblings mouse mouse = false := by decide
example : siblings (mouse.refine hasModifier aged) human = false := by decide  -- refined: unknown
example : isA human.curie eukaryota.curie = true := by decide

-- transport refuses non-sibling taxa
def s : Statement :=
  { id := "t", text := "", claim := .effect (glucose.inCtx { taxon := mouse }) .pos (.process glycolysis),
    evidence := [{ pmid := 1, year := 2026, kind := .mechanistic, taxon := some mouse }] }
def x : Evidence := { pmid := 0, year := 2026, kind := .crossSpecies }

example : Derivation (.effect (glucose.inCtx { taxon := human }) .pos (.process glycolysis)) :=
  .transport {} human (.lit s) x
#check_failure (Derivation.transport {} mammalia (.lit s) x)
#check_failure (Derivation.transport {} eukaryota (.lit s) x)
#check_failure (Derivation.transport {} mouse (.lit s) x)

-- the taxon lint
#guard s.taxonConsistent
#guard Statement.taxonConsistent { s with claim := .effect (glucose.inCtx { taxon := mammalia }) .pos (.process glycolysis) }
#guard !Statement.taxonConsistent { s with claim := .effect glucose .pos (.process glycolysis) }
#guard !Statement.taxonConsistent { s with claim := .effect (glucose.inCtx { taxon := human }) .pos (.process glycolysis) }
-- an `in_taxon` nested inside another filler is not the subject's taxon
#guard !Statement.taxonConsistent { s with claim := .effect (glucose.inCtx { cellType := hepatocyte.inCtx { taxon := mouse } }) .pos (.process glycolysis) }

end BioLean.Context.Tests
