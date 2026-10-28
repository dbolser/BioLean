/-! # Rel: RO/BFO relations as values

A relation is named by its ontology and numeric id; `inv` marks the inverse property, so
`inverse(occurs_in)` is `⟨.bfo, 66, true⟩`. Equality is decidable, so membership in the RO axiom
lists (`BioLean/RO.lean`) can be settled by `decide`. -/

namespace BioLean

inductive RelNs where
  | ro | bfo | rdfs
  deriving DecidableEq, Repr

structure Rel where
  ns : RelNs
  num : Nat
  inv : Bool := false
  deriving DecidableEq, Repr

/-- Coarse BFO sort of a relation's domain or range. -/
inductive RelSort where
  | continuant | occurrent
  deriving DecidableEq, Repr

namespace Rel

def flip (r : Rel) : Rel := { r with inv := !r.inv }

@[simp] theorem flip_flip (r : Rel) : r.flip.flip = r := by
  cases r; simp [flip]

/-! Named relations used by hand-written statements. -/
def partOf     : Rel := ⟨.bfo, 50, false⟩
def hasPart    : Rel := ⟨.bfo, 51, false⟩
def precededBy : Rel := ⟨.bfo, 62, false⟩
def precedes   : Rel := ⟨.bfo, 63, false⟩
def occursIn   : Rel := ⟨.bfo, 66, false⟩
def locatedIn  : Rel := ⟨.ro, 1025, false⟩
def capableOf  : Rel := ⟨.ro, 2215, false⟩
def hasInput   : Rel := ⟨.ro, 2233, false⟩
def hasOutput  : Rel := ⟨.ro, 2234, false⟩
def enables    : Rel := ⟨.ro, 2327, false⟩
def involvedIn : Rel := ⟨.ro, 2331, false⟩
def produces   : Rel := ⟨.ro, 3000, false⟩
def overlaps   : Rel := ⟨.ro, 2131, false⟩
def inTaxon    : Rel := ⟨.ro, 2162, false⟩
def hasModifier : Rel := ⟨.ro, 2573, false⟩
/-- rdfs:subClassOf, which is not an RO property but behaves as a transitive relation here. -/
def isA        : Rel := ⟨.rdfs, 0, false⟩

/-- Zero-pad to seven digits, as OBO ids are written. -/
def pad7 (n : Nat) : String :=
  let s := toString n
  String.ofList (List.replicate (7 - s.length) '0') ++ s

def curie (r : Rel) : String :=
  let base := match r.ns with
    | .ro => s!"RO:{pad7 r.num}"
    | .bfo => s!"BFO:{pad7 r.num}"
    | .rdfs => "rdfs:subClassOf"
  if r.inv then s!"inverse({base})" else base

end Rel
end BioLean
