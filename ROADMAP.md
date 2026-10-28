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

## M2. Context, hypotheses, rivals (built 2026-10-28)
Context by entity refinement (bake-off winner, `docs/m2/judgement.md`), then the argument layer.
- `Entity.refine` / `Entity.inCtx`: context as a subclass of the subject; specialisation via the
  existing is_a laws; `transport` between sibling taxa as a weighted rule; protocol on Evidence.
- `EvidenceKind.hypothesis` at weight 0; `Statement.rivals` with mutual exclusion moving a
  rival's belief into disbelief; `Claim.noEffect`.
- **Exit:** chemiosmotic timeline reaches *established* by 1974 and Slater is *refuted*, computed in
  Lean not Python; NMN human claim is low belief with the mouse papers as axioms.
- **Status:** done. NMN in aged humans is 0.21 from aged mice with the transport item as an axiom;
  mouse and human cannot fuse (type-level). Rivals are a `Rivalry` over statements, not an id list.
  Chemiosmosis is contested in 1965 and established (Slater refuted) by 1974 as theorems, after two
  changes to illustrative items (`BioLean/Examples/Chemiosmosis.lean`, CHANGELOG).

## M3. Quantity (built 2026-10-28)
Counts, class sizes, intervals with units, yields, and `some`/`most` quantifiers; rules carry
arithmetic side goals discharged by `decide`/`norm_num` when the term is built.
- **Exit:** the 13 counting derivations (codon pigeonhole, 2^23 gametes, TCA carbons) type-check.
- **Status:** 7 of 13 are theorems (T21, T25, T26, T27, T31, T32, T34). Remaining: T22 proportion,
  T23 carbon conservation, T24 input/output duality, T28 parity plus necessity, T29 2^23 (needs a
  tetrad entity), T30, T33 bijection. The 430 textbook claims binned `quantity` have not been
  re-annotated against the new constructors yet.

## M4. Generalisation and canon (generalize built 2026-10-28; canonical kind and promotion remain)
`generalize` with a coverage function over NCBITaxon/UBERON/CL; `canonical` evidence kind;
promotion threshold for biolib.
- **Exit:** "DNA is transcribed to RNA in cellular organisms" established from five instances;
  the retroviral exception stops at the context boundary.

## M5. Ontologies as biolib (is_a closure imported 2026-10-28; axioms and consistency checks remain)
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
