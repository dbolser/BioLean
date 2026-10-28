import BioLean.Belief
import BioLean.Claim

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
  | transport       -- a warrant that a result carries from one taxon to another (ECO ISO-like)
  deriving DecidableEq, Repr

/-- One citation. -/
structure Evidence where
  pmid : Nat
  year : Nat
  kind : EvidenceKind
  polarity : Opinion.Polarity := .supports
  note : String := ""
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
    | .transport => 3 / 10
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

end Statement
end BioLean
