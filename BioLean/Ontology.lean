import BioLean.Rel
/-!
# Ontology-grounded entities

Every thing BioLean talks about is an `Entity` carrying a CURIE from a public
ontology or database (CHEBI, UniProt, GO, HP, MONDO, UBERON, CL, ...). The `Kind`
index lets claim constructors say what kind of thing may stand in each role, so a
process cannot be mistaken for a chemical at the type level. Nothing finer than that is
enforced yet; finer typing (e.g. GO sub-hierarchies) is future work.
-/

namespace BioLean

/-- The coarse kind of an entity. This is the type-level ontology. -/
inductive Kind
  | chemical   -- CHEBI
  | protein    -- UniProt
  | gene       -- HGNC / Ensembl
  | process    -- GO biological process
  | function   -- GO molecular function
  | phenotype  -- HP / PATO / MP
  | disease    -- MONDO
  | anatomy    -- UBERON
  | cellType   -- CL
  | component  -- GO cellular component
  | taxon      -- NCBITaxon
  deriving DecidableEq, Repr

/-- The BFO sort of a kind: processes and functions are occurrents, everything else a continuant. -/
def Kind.sort : Kind → RelSort
  | .process | .function => .occurrent
  | _ => .continuant

/-- A named, grounded thing of kind `k`. -/
structure Entity (k : Kind) where
  curie : String
  label : String
  deriving DecidableEq, Repr

/-- Kinds that can act as a molecular agent (bind, activate, be degraded, ...). -/
class Molecular (k : Kind) : Prop

instance : Molecular .chemical := ⟨⟩
instance : Molecular .protein := ⟨⟩

instance {k : Kind} : ToString (Entity k) := ⟨fun e => s!"{e.label} [{e.curie}]"⟩

end BioLean
