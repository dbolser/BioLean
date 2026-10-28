# ROADMAP

Milestones, each with an exit test that already exists in the repo. Order is by what unlocks the
most; dates are deliberately absent. Status lives in [STATUS.md](STATUS.md).

## M1. Structural core (built and checked 2026-10-27)
Add relational claims and the rules that move them.
- `Claim.rel` over RO relations (is_a, part_of, has_part, located_in, occurs_in, capable_of,
  has_input, has_output, precedes), typed by RO domain and range.
- Import RO property chains and transitivity from `ro.owl` as derivation rules; hand-check each.
- Bridges from structure to effect (`has_input m P ⊢ m →+ P`, `has_output P m ⊢ P →+ amount m`).
- **Exit:** the 24 structure-blocked derivations in `docs/textbook-derivations.md` type-check;
  the textbook "now" bin rises from 8.8 percent to above 50 percent by re-binning.
- **Status:** five representative derivations type-check (`BioLean/Examples/Textbook.lean`). 164 RO
  chains hand-checked, 38 blocked (`docs/m1-checks.md`). Measured re-annotation: 8.8 to 17.3 percent
  now, 30 percent with Context (`scripts/textbook/aggregate_m1.py`); the 62.6 heuristic was wrong.
  Logical steps are weakest-link. Lean-checked the book twice: round 2 (Sonnet, structured) emits 1,594 claims and 1,591 compile;
  34 percent of the book is now Lean (`docs/textbook-lean-check.md`). `Target.activity` takes GO
  functions. RO pinning tests in place. Remaining: entities for
  the other 19 structural derivations; structure-to-effect bridges; `Target.activity` on functions;
  `Kind.sequenceFeature`; compound-sentence splitting and grounding are the top blockers.

## M2. Context, hypotheses, rivals
Merge the drafted Context extension and the argument layer.
- `Context` inside the claim; `specialise` free; `transport` as a weighted rule.
- `EvidenceKind.hypothesis` at weight 0; `Statement.rivals` with mutual exclusion moving a
  rival's belief into disbelief; `Claim.noEffect`.
- **Exit:** chemiosmotic timeline reaches *established* by 1974 and Slater is *refuted*, computed in
  Lean not Python; NMN human claim is low belief with the mouse papers as axioms.

## M3. Quantity (next: confirmed by the closure's only clash, "most neurons" vs "some neurons")
`Claim.quantity` with units and an arithmetic side goal discharged by `norm_num`/`decide`.
- **Exit:** the 13 counting derivations (codon pigeonhole, 2^23 gametes, TCA carbons) type-check.

## M4. Generalisation and canon
`generalize` with a coverage function over NCBITaxon/UBERON/CL; `canonical` evidence kind;
promotion threshold for biolib.
- **Exit:** "DNA is transcribed to RNA in cellular organisms" established from five instances;
  the retroviral exception stops at the context boundary.

## M5. Ontologies as biolib
Import GO, UBERON, CL axioms as zero-PMID statements with provenance "ontology axiom"; compute
over them.
- Consistency checks: partonomy plus developmental processes (the "grow a plant" test on PO);
  find definitions that contradict axioms.
- **Exit:** at least one reported inconsistency confirmed by a curator, and the textbook axiom
  rate (15 percent) recomputed from imported axioms rather than OLS calls.

## M6. Evidence weights
ECO codes replacing the 8-way enum; per-claim base rates; averaging fusion for dependent sources;
discounting for extraction reliability separate from study strength.
- **Exit:** Ozempic verdicts unchanged in sign; the pseudo-count of every evidence kind documented.

## M7. Second textbook
A molecular cell biology text. Open candidates: OpenStax *Biology 2e* (same licence, larger);
*Cell Biology by the Numbers* (Milo and Phillips, CC BY-NC-SA, quantitative, the right test for M3).
Alberts is not open.
- **Exit:** the milestone measurement rerun; "now" above 70 percent.

## M8. Literature at scale
The search half exists: `scripts/search/closure.py` forward-chains and `emit_closure_lean.py` hands
derivations to the kernel (60/60 certified on the textbook). Remaining here is the literature as
statements, and holes fed to an ILP-style search.
Curated sources first (GO-CAM, SIGNOR, Reactome, GOA), text-mined relations second, LLM
extraction targeted at gaps. Datalog search over statements with Lean checking (CertifyingDatalog
pattern). Holes in derivations fed to an ILP-style search over the ontology lattice.
- **Exit:** a question not hand-curated (e.g. "does metformin extend lifespan in humans?")
  answered end to end with a verdict and an axiom list.
