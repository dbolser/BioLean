import BioLean.Belief
import BioLean.Context

/-!
# Evidence and statements

A `Statement` is a claim plus the literature evidence for or against it. It is the
unit that is extracted from papers and the *axiom* of a BioLean derivation. Its
opinion is the cumulative fusion of the opinions contributed by each piece of
evidence. How much one paper is worth depends on its `EvidenceKind`; the mapping lives
in an `EvidenceModel` instance so it can be swapped without touching any proof.
-/

namespace BioLean

/-- Study design of a piece of evidence. Ordered roughly by how much weight one item
carries. Mirrors common evidence hierarchies (GRADE, Oxford CEBM) and INDRA's
per-source reliabilities. -/
inductive EvidenceKind
  | metaAnalysis
  | rct
  | curatedDb       -- a curated database assertion (UniProt, ChEBI role, GO annotation)
  | textbook        -- a canonical textbook statement (consensus, not a primary result)
  | ontologyAxiom   -- a logical axiom in an OBO ontology
  | mechanistic     -- in vivo / ex vivo mechanistic study
  | review
  | observational
  | inVitro
  | textMined       -- an automatically extracted relation (PubTator3, INDRA readers)
  | crossSpecies    -- a judgment that a result transfers between taxa (ECO ISO-like); `transport`
  | definitional    -- true by definition: a refinement is a subclass of what it refines
  deriving DecidableEq, Repr

/-- The experimental system a result came from. Experiment-level, so it lives on `Evidence`. -/
inductive ExpSystem
  | inVivo | exVivo | inVitro | reconstituted
  deriving DecidableEq, Repr

/-- One citation. Dose, duration, strain, system and taxon describe the experiment, not the
claim: the same claim is tested at many doses, so they never make two claims different. `taxon`
is checked against the claim by `Statement.taxonConsistent`. -/
structure Evidence where
  pmid : Nat
  year : Nat
  kind : EvidenceKind
  polarity : Opinion.Polarity := .supports
  note : String := ""
  dose : Option String := none
  duration : Option String := none
  strain : Option String := none
  system : Option ExpSystem := none
  taxon : Option (Entity .taxon) := none
  deriving Repr

/-- A claim with its evidence: the axiom form of BioLean. -/
structure Statement where
  id : String
  text : String
  claim : Claim
  evidence : List Evidence

/-- How much one item of each evidence kind is worth. Values must lie in `[0, 1)`. -/
class EvidenceModel where
  reliability : EvidenceKind → ℚ
  nonneg : ∀ k, 0 ≤ reliability k
  lt_one : ∀ k, reliability k < 1

/-- The default weights. They are a starting point, not a calibration. -/
instance EvidenceModel.standard : EvidenceModel where
  reliability
    | .metaAnalysis => 9 / 10
    | .rct => 17 / 20
    | .curatedDb => 4 / 5
    | .textbook => 4 / 5
    | .ontologyAxiom => 9 / 10
    | .mechanistic => 7 / 10
    | .review => 3 / 5
    | .observational => 1 / 2
    | .inVitro => 1 / 2
    | .textMined => 3 / 10
    | .crossSpecies => 3 / 10
    -- Weight 1 would be exact but is ruled out by `lt_one` (an opinion keeps `0 < u`). At 999/1000
    -- the refinement axiom is the weakest premise only above belief 0.999, so S3 is exact in
    -- practice: `weakest` returns the other premise.
    | .definitional => 999 / 1000
  nonneg := by intro k; cases k <;> norm_num
  lt_one := by intro k; cases k <;> norm_num


namespace Evidence

/-- The opinion contributed by one citation. -/
def opinion [m : EvidenceModel] (e : Evidence) : Opinion :=
  Opinion.ofReliability (m.reliability e.kind) (m.nonneg e.kind) (m.lt_one e.kind) e.polarity

end Evidence

namespace Statement

/-- The evidence with repeated PMIDs removed: one paper is one piece of evidence. PMID 0 marks
non-paper evidence (textbooks, ontology axioms) and is never deduplicated. -/
def distinctEvidence (s : Statement) : List Evidence :=
  (s.evidence.foldl (fun acc e => if e.pmid != 0 && acc.any (·.pmid == e.pmid) then acc else acc ++ [e]) [])

/-- Fuse the evidence for a statement into one opinion. Fusion assumes the items are
independent, so repeated PMIDs are dropped first. Shared findings cited by several
papers are still over-counted; see `docs/design.md`. -/
def opinion [EvidenceModel] (s : Statement) : Opinion :=
  s.distinctEvidence.foldl (fun acc e => acc.fuse e.opinion) Opinion.vacuous

def pmids (s : Statement) : List Nat := s.evidence.map (·.pmid)

instance : ToString Statement := ⟨fun s => s!"{s.id}: {s.claim}  ({s.evidence.length} refs)"⟩

/-- Lint (decidable, not kernel-enforced): if any evidence item sets `taxon`, the claim's subject
must carry an `in_taxon` filler that the evidence taxon is_a (`Taxa.isA`; organism states on
either side are ignored). Catches mouse evidence put on a context-free or a human claim. -/
def taxonConsistent (s : Statement) : Bool :=
  match s.evidence.filterMap (·.taxon), Ctx.taxonOfCurie s.claim.subjectCurie with
  | [], _ => true
  | _, none => false
  | ts, some f => ts.all fun t => Taxa.isA (Ctx.baseCurie t.curie) f

end Statement

/-- The refinement axiom `e ⊓ ∃r.f ⊑ e`: dropping a context is a subsumption. True by definition,
so its evidence is `.definitional` and the existing is_a laws use it almost losslessly. -/
def Entity.refineAxiom {k k' : Kind} (e : Entity k) (r : Rel) (f : Entity k')
    (hr : r.accepts k k' = true := by decide) (h : Rel.isA.accepts k k = true := by decide) :
    Statement where
  id := s!"refine:{(e.refine r f hr).curie}"
  text := s!"{(e.refine r f hr).label} is_a {e.label}"
  claim := .rel Rel.isA (e.refine r f hr) e h
  evidence := [{ pmid := 0, year := 0, kind := .definitional, note := "C ⊓ ∃r.F ⊑ C" }]
end BioLean
