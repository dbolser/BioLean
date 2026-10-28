import BioLean.Ontology

/-!
# Context

Where a claim holds: "in mouse liver", "in prokaryotic cells", "in a hypotonic solution". A
`Context` is attached to a claim by `Claim.inContext`, so a mouse claim and a human claim are
different claims and cannot fuse by accident. Every field is optional; an absent field means "no
restriction stated".

Reading: `inContext ctx c` says `c` holds for everything in `ctx` (a universal over the context).
Under that reading narrowing the context is sound (`Derivation.specialise`) and widening it is
induction (`generalize`, M4, not here). Moving sideways to another taxon is a weighted analogy
(`Derivation.transport`).

Narrowness is decided by field subsumption: a field `none` is wider than anything; `some x` is
wider than `some y` when `y is_a x` by the pinned table `isAParents`. Free-text fields (stage,
condition) only narrow from `none`, or match exactly.
-/

namespace BioLean

structure Context where
  taxon     : Option (Entity .taxon) := none
  anatomy   : Option (Entity .anatomy) := none
  cellType  : Option (Entity .cellType) := none
  /-- GO cellular component: a membrane, an organelle. Needed for "in thylakoid membranes". -/
  component : Option (Entity .component) := none
  /-- Life stage or age, free text: "aged", "postmenopausal", "mature". -/
  stage     : Option String := none
  /-- Exposure, disease, diet, dose, in vitro system, free text: "hypotonic solution". -/
  condition : Option String := none
  deriving DecidableEq, Repr

namespace Context

/-- Direct or skip-rank is_a edges (child, ancestor) for the CURIEs the examples use. A pinned
slice of NCBITaxon, GO, CL and UBERON, hand-checked; extend as data, like `RO.lean`. Skipping
intermediate ranks is sound because is_a is transitive. -/
def isAParents : List (String × String) := [
  -- NCBITaxon
  ("NCBITaxon:10090", "NCBITaxon:40674"),   -- Mus musculus ⊑ Mammalia
  ("NCBITaxon:10116", "NCBITaxon:40674"),   -- Rattus norvegicus ⊑ Mammalia
  ("NCBITaxon:9606",  "NCBITaxon:40674"),   -- Homo sapiens ⊑ Mammalia
  ("NCBITaxon:9913",  "NCBITaxon:40674"),   -- Bos taurus ⊑ Mammalia
  ("NCBITaxon:40674", "NCBITaxon:7742"),    -- Mammalia ⊑ Vertebrata
  ("NCBITaxon:7742",  "NCBITaxon:33208"),   -- Vertebrata ⊑ Metazoa
  ("NCBITaxon:33208", "NCBITaxon:2759"),    -- Metazoa ⊑ Eukaryota
  ("NCBITaxon:3562",  "NCBITaxon:33090"),   -- Spinacia oleracea ⊑ Viridiplantae
  ("NCBITaxon:33090", "NCBITaxon:2759"),    -- Viridiplantae ⊑ Eukaryota
  ("NCBITaxon:2759",  "NCBITaxon:131567"),  -- Eukaryota ⊑ cellular organisms
  ("NCBITaxon:562",   "NCBITaxon:2"),       -- Escherichia coli ⊑ Bacteria
  ("NCBITaxon:2",     "NCBITaxon:131567"),  -- Bacteria ⊑ cellular organisms
  ("NCBITaxon:2242",  "NCBITaxon:2157"),    -- Halobacterium salinarum ⊑ Archaea
  ("NCBITaxon:2157",  "NCBITaxon:131567"),  -- Archaea ⊑ cellular organisms
  -- GO cellular component
  ("GO:0042651", "GO:0016020"),             -- thylakoid membrane ⊑ membrane
  ("GO:0005743", "GO:0016020"),             -- mitochondrial inner membrane ⊑ membrane
  -- CL
  ("CL:0000232", "CL:0000000"),             -- erythrocyte ⊑ cell
  ("CL:0000746", "CL:0000000"),             -- cardiac muscle cell ⊑ cell
  ("CL:0000520", "CL:0000000")]             -- prokaryotic cell ⊑ cell

/-- `x is_a y` (reflexive, transitive) by the table, searching at most `fuel` edges deep. -/
def isAUpTo : Nat → String → String → Bool
  | 0, x, y => x == y
  | n + 1, x, y => x == y || isAParents.any (fun (c, p) => c == x && isAUpTo n p y)

def isA (x y : String) : Bool := isAUpTo 16 x y

/-- Field subsumption for ontology terms: `none` is wider than anything. -/
def fieldLE {k : Kind} : Option (Entity k) → Option (Entity k) → Bool
  | _, none => true
  | some n, some w => isA n.curie w.curie
  | none, some _ => false

/-- Field subsumption for free text: narrows only from `none`, or matches exactly. -/
def textLE : Option String → Option String → Bool
  | _, none => true
  | some n, some w => n == w
  | none, some _ => false

/-- `narrow ≤ wide`: every field of `narrow` is at least as specific as the same field of `wide`. -/
def le (narrow wide : Context) : Bool :=
  fieldLE narrow.taxon wide.taxon && fieldLE narrow.anatomy wide.anatomy &&
  fieldLE narrow.cellType wide.cellType && fieldLE narrow.component wide.component &&
  textLE narrow.stage wide.stage && textLE narrow.condition wide.condition

/-- Transport is sideways: the source context names a taxon, and the target taxon neither
subsumes it (that would be generalisation) nor is subsumed by it (that is free specialisation). -/
def transportOK (src : Option (Entity .taxon)) (t' : Entity .taxon) : Bool :=
  match src with
  | some t => !isA t.curie t'.curie && !isA t'.curie t.curie
  | none => false

instance : ToString Context where
  toString x :=
    let parts : List String :=
      (x.taxon.toList.map toString) ++ (x.anatomy.toList.map toString) ++
      (x.cellType.toList.map toString) ++ (x.component.toList.map toString) ++
      x.stage.toList ++ x.condition.toList
    ", ".intercalate parts

end Context
end BioLean
