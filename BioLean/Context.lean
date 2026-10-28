import BioLean.Claim
import BioLean.Taxa

/-!
# Context (M2)

A context is a refinement of an entity (`Entity.refine`, the class `e ⊓ ∃r.f`). `Entity.inCtx`
is the way to build one: it applies the fields of a `Ctx` in a fixed order (anatomy, cell type,
component, condition, stage, taxon) with fixed RO relations, so one context gives one curie.
Mouse and human claims differ because their subjects differ. See `docs/m2/judgement.md`.
-/

namespace BioLean

/-- A condition, placed by what it qualifies. -/
inductive Condition
  /-- A state of the organism (disease, genotype, age, diet). It refines the **taxon filler**
  with `has_modifier`: "drug in rheumatoid arthritis" is `drug ⊓ in_taxon (human ⊓ has_modifier
  RA)`, not `drug ⊓ has_modifier RA`. -/
  | organism {k : Kind} (s : Entity k) (h : Rel.hasModifier.accepts .taxon k = true := by decide)
  /-- The subject's surroundings (hypotonic solution, low oxygen). It refines the subject with
  `surrounded_by`. -/
  | environment {k : Kind} (s : Entity k)

/-- The context of a claim. Experiment protocol (dose, duration, strain, system) is not context;
it lives on `Evidence`. -/
structure Ctx where
  taxon : Option (Entity .taxon) := none
  anatomy : Option (Entity .anatomy) := none
  cellType : Option (Entity .cellType) := none
  component : Option (Entity .component) := none
  stage : Option (Entity .process) := none
  condition : Option Condition := none

namespace Ctx

/-- Where a site locates an entity: processes and functions `occurs_in`, continuants `located_in`. -/
def locRel (k : Kind) : Rel := if k.sort = .occurrent then Rel.occursIn else Rel.locatedIn

/-- A cell type: processes `occurs_in` it, continuants are `part_of` it. -/
def cellRel (k : Kind) : Rel := if k.sort = .occurrent then Rel.occursIn else Rel.partOf

/-- The taxon filler: the taxon (default: cellular organisms) refined by an organism state. -/
def taxonFiller (c : Ctx) : Option (Entity .taxon) :=
  match c.taxon, c.condition with
  | t, some (.organism s h) => some ((t.getD Taxa.cellularOrganisms).refine Rel.hasModifier s h)
  | t, _ => t

/-- The unrefined head of a curie: `NCBITaxon:10090` from `NCBITaxon:10090&RO:0002573=(BLN:aged)`. -/
def baseCurie (c : String) : String := (c.takeWhile (· != '&')).toString

/-- The base taxon of a refined entity's outermost `in_taxon` filler, read off its curie; `none`
if the outermost refinement is not `in_taxon`. For lints only: curies are not parsed by the kernel. -/
def taxonOfCurie (c : String) : Option String :=
  match c.splitOn s!"&{Rel.inTaxon.curie}=(" with
  | [] | [_] => none
  | parts =>
    let p := parts.getLast!.toList
    -- the filler's bracket must close at the very end, else this `in_taxon` is nested
    let depth := p.foldl (fun d ch => match d with
      | some (n + 1) => if ch == '(' then some (n + 2) else if ch == ')' then some n else some (n + 1)
      | _ => none) (some 1)
    if depth == some 0 then some (baseCurie (String.ofList p.dropLast)) else none

end Ctx

/-- Refine by an optional filler. -/
def Entity.refineOpt {k k' : Kind} (e : Entity k) (r : Rel) (f : Option (Entity k'))
    (h : r.accepts k k' = true) : Entity k :=
  match f with
  | some f => e.refine r f h
  | none => e

/-- `e` in context `c`. The order and relations are fixed: anatomy and component by `located_in`
(`occurs_in` for processes), cell type by `part_of` (`occurs_in`), an environment by
`surrounded_by`, stage by `happens_during`, taxon (with any organism state) by `in_taxon`,
outermost. Same `Ctx`, same curie, however the structure literal is written. -/
def Entity.inCtx {k : Kind} (e : Entity k) (c : Ctx) : Entity k :=
  let e := e.refineOpt (Ctx.locRel k) c.anatomy (by cases k <;> decide)
  let e := e.refineOpt (Ctx.cellRel k) c.cellType (by cases k <;> decide)
  let e := e.refineOpt (Ctx.locRel k) c.component (by cases k <;> decide)
  let e := match c.condition with
    | some (.environment (k := k') s) => e.refine Rel.surroundedBy s (by cases k <;> cases k' <;> decide)
    | _ => e
  let e := e.refineOpt Rel.happensDuring c.stage (by cases k <;> decide)
  e.refineOpt Rel.inTaxon c.taxonFiller (by cases k <;> decide)

end BioLean
