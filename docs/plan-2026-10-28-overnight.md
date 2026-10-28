# Reflection and overnight plan, 2026-10-28

Written at the start of an unattended eight-hour stretch. Part 1 is where we stand, said plainly.
Part 2 is what the night's work is and why. Part 3 is the decisions I am making provisionally so
work can proceed, with the options explored for you to overrule. A morning report is appended at
the end when the work is done.

## 1. Where we are

**What is solid.** The split that started the project holds up: Lean checks the shape of an
argument, subjective logic computes its strength, and the two never confuse each other. Five
days in, the type checker has caught real errors at every layer we pointed it at: seven
mistaken axioms in the Relation Ontology (now issues #897 to #900), a nineteen-in-twenty
mis-annotation rate in machine-read textbook claims, and two unsound inference rules of our own
that a thousand-fact closure exposed within seconds. A third of an introductory textbook is now
Lean, 1,591 statements that compile, and the first forward-chaining search over them produced
1,551 derived facts of which every sampled one the kernel certified. RO's 164 property chains are
imported data, hand-checked, with 38 blocked. Context, quantity and relational claims each went
from a gap in a measurement to a built, tested constructor inside a day, because every milestone
had a concrete exit test taken from the data.

**What is weak, and should not be dressed up.**
1. *The weights are made up.* Every reliability (textbook 0.8, RCT 0.85, cross-species 0.3) is a
   placeholder with a pseudo-count interpretation and no calibration. Every verdict in the repo
   inherits that. Nothing we have derived depends on the exact numbers, which is the only reason
   it is tolerable.
2. *Nothing surprising has been derived.* The closure's true conclusions are things a student
   knows (prometaphase is part of the cell cycle). The formal apparatus has found errors in
   knowledge sources, not new biology. That is the honest state of the art for the method and it
   should be said that way.
3. *Everything rests on one textbook and one drug demo.* No literature at scale. The
   "contested" machinery, which is the point of the belief layer, has been exercised on exactly
   two cases (sitagliptin, nausea) plus a Python sketch of the chemiosmotic history.
4. *Curation is the bottleneck and it is LLM curation.* Sonnet annotates at 99.8 percent
   compile rate but the biology in those annotations has been spot-checked, not audited. The
   closure found over-general subjects ("cells have cell walls") that no type check can see.
5. *The is_a backbone is hand-pinned.* Twelve taxa in a table; specialisation and transport
   decide against it. Until the ontologies' own hierarchies are imported, "free specialisation"
   is a demonstration, not a capability.
6. *Independence of evidence is unsolved* and the same fact written two ways double-counts.

**On the two worries you raised.** First, biology's concepts change: lipid rafts, epigenetics,
senolytics appear, shift, sometimes go. A system that pretends otherwise will rot. The pieces
that make this tolerable are already in the design and need to be made explicit: every Statement
is dated, every Entity is a CURIE from a *released* ontology, GO retires terms with
`replaced_by`, and `Established` can be indexed by year. Biolib should be versioned like an
ontology, not like Mathlib: a lemma can become contested or refuted, and a concept can be
minted or retired, without the library being "wrong". Tonight includes an experiment that
measures how much of the textbook's vocabulary even existed in GO fifteen years ago. Second,
"trust A-level biology" as the floor is right and it has a cost you named: the floor is the
weakest point. The textbook statements carry 0.8 and no provenance below themselves. Where a
literature statement later contradicts a textbook one, the system must be able to say so and
let the textbook lose. The rivalry machinery being built tonight is what makes that possible.

**On where the vision gets fuzzy.** Rat versus mouse, homology, hypotheses about what drives a
difference: the shape is already in the core. Transport between sibling taxa is a weighted step
that can fail; a claim established in mouse and refuted in rat is a *clash across a transport
edge*, and the question "which premise differs" is a derivation with a hole. The hole search
being built tonight is the first, deliberately small, version of that: it asks, for every
textbook sentence that is not yet a theorem, which single missing premise would make it one.
That is ILP's inverse-entailment step done by enumeration. Analogy is the same move with a
different lattice. None of this is proven out yet; the night's job is to make the first rung
concrete.

## 2. The night's work, in order

Each phase is one workflow of at most four agents, writes to disk incrementally, and is
committed when it lands, so a rate limit loses at most one phase. Heavy judgement goes to Opus,
mechanical annotation to Sonnet.

| phase | work | exit test | why now |
|---|---|---|---|
| 1a | **Argument layer** (finishes M2): `hypothesis` evidence kind, `noEffect` claim, `Rivalry` with mutual exclusion, `opinionAt year`, the chemiosmotic history in Lean | Mitchell *established* and Slater *refuted* by 1974, *contested* in 1965, as theorems | closes a milestone; makes textbook-versus-literature disagreement representable |
| 1b | **Ontology is_a import**: ancestor closure of every entity biolib uses, from GO, UBERON, CL, ChEBI and NCBITaxon, as Lean data; replaces the pinned taxon table | existing Context tests pass against real hierarchies; specialisation works for any used term | removes the hand table; prerequisite for generalise |
| 1c | **Information-content triviality** (your suggestion) and **concept drift**: IC from descendant counts to rank closure conclusions; GO 2010/2015 versus today over the textbook's GO terms | a ranked list of non-trivial derived facts; a table of how many textbook concepts existed when | grounds the "trivial" threshold; grounds the concept-change worry in numbers |
| 1d | **Hole search** (ILP step one): for each textbook sentence not yet a theorem, the single missing premise that would make it one, ranked by how many sentences it would explain | a list of candidate premises, with the organelle-abundance case rediscovered automatically | first concrete rung of hypothesis generation |
| 2 | **Re-annotation** of the 430 quantity and 190 context claims against the M2/M3 constructors (Sonnet, structured), emit, compile, rerun the closure | expressibility measured again (was 34 percent); closure growth | grounds M2 and M3 in the data they were built for |
| 3 | **Generalise** (M4) with coverage from real taxonomy, bracketing as default and clade fraction as the alternative; the transcription case study in Lean | "DNA is transcribed to RNA in cellular organisms" established from instances; retroviral exception stops at the context boundary | depends on 1b |
| 4 | **Morning report**: numbers, what broke, decisions for you | appended below | |

What is deliberately *not* tonight: literature at scale, weight calibration, the pipeline.
Those need your judgement on scope and cost, and the floor needs to be firmer first.

## 3. Provisional decisions, with options explored

| decision | provisional choice | alternatives kept open |
|---|---|---|
| coverage measure for generalise | phylogenetic bracketing (your stated preference): sampled taxa on both sides of the deepest split in the target clade count as covering it, discounted per unsampled major lineage | clade fraction (implemented, shown side by side); IC-weighted coverage |
| triviality of a conclusion | information content of the less specific of subject and object, from descendant counts in its ontology; threshold reported, not hard-coded | annotation-frequency IC (needs GOA); the hub list (dropped) |
| ontology import scope | ancestor closure of used entities only, per ontology, encoded as numeric pairs for fast `decide` | full ontologies (GO alone is 48k terms; too slow for kernel decide); OLS at check time (network) |
| concept lifecycle | Entities keep their release; Statements keep years; `Established` indexed by year; a `retired` marker read from `replaced_by` | ontology-version pinning per Statement (heavier; revisit when literature arrives) |
| rivalry semantics | a `Rivalry` groups mutually exclusive claims; belief in one is fused as disbelief into the others | multinomial opinions (cleaner, more machinery; later) |
| what "hypothesis" weighs | reliability 0: recorded, contributes no belief | small positive prior (needs base rates; M6) |

Every one of these is reversible in an hour; none is load-bearing for the data.

## 4. Phase 1 results and the decisions it raised (provisional answers)

All four phase-1 tasks completed, built green together, and were committed (92dc177, 2dd5943,
7053144, 7efae08). Headlines:

- **Argument layer (M2 complete).** `hypothesis` kind at weight 0, `noEffect`, `opinionAt year`,
  `Rivalry`. The chemiosmotic history is now Lean theorems: both rivals contested in 1965;
  chemiosmotic *established* (0.806) and chemical intermediate *refuted* (0.818) in 1974; the
  single-claim reading *never* reaches established in any year, proved for all years by
  `Statement.forall_opinionAt`. Proved: a rivalry decides losers, never raises a winner above its
  own evidence (`Rivalry.belief_le`). With the six real papers alone the 1974 result holds at
  exactly 0.800; the 1965 "contested" needs one illustrative pro-chemiosmotic item (Mitchell and
  Moyle 1965), because two weightless hypothesis papers give 0.
- **Ontology is_a import (replaces the hand table).** 1,493 CURIEs in use; 1,158 in GO, UBERON,
  CL, ChEBI, NCBITaxon; ancestor closure of 2,911 terms and 4,060 edges as a Lean search tree.
  A flat list made `decide` take 10 s per query; the tree takes 60 ms. Nine used terms are
  retired (two CL, six GO obsolete, one merged). Context tests pass unchanged against the real
  hierarchy. Found: area postrema in the Ozempic entities has the wrong UBERON id (fix queued).
- **Information content.** Threshold 2.5 keeps 837 of 1,551 derived facts. The hub list it
  replaces was wrong 36 percent of the time and nondeterministic. IC ranks specificity, not
  truth: ChEBI leaves dominate the top. One wrong derived fact surfaced ("superior vena cava
  connected to inferior vena cava"), traced to an over-general textbook premise, not to the rule.
- **Concept drift.** Of the textbook's 559 GO terms, 77 / 92 / 97 / 99 percent existed in
  2005 / 2010 / 2015 / 2020. "Cell division" and "interphase" did not exist in GO at the end of
  2004; "mitotic nuclear division" (17 statements) was minted in 2017. A third of the terms alive
  in 2005 have since been renamed. Seven are retired today and nine statements rest on them.
- **Hole search.** 6,735 candidate missing premises, 842 after grouping; the eight hand-found
  holes were NOT rediscovered, and the reason is informative: every one sits where the formal
  vocabulary stopped (quantity, context, compound sentences), which phase 2 addresses, or needs
  rule induction rather than a missing fact (the organelle-abundance case). Best hypothesis
  found: one "opposes" relation between the sympathetic and parasympathetic systems would make
  six textbook sentences theorems.

| question raised | provisional answer | reversible? |
|---|---|---|
| Accept the two illustrative chemiosmotic items (1963 review at 0; a 1965 pro item)? | Yes, both labelled illustrative in the Lean. The honest alternative, "1965 unsupported", is also true of the real record and is stated in the file. | yes, delete two items |
| Experiments entered on both rivals double-count | Keep for now; multinomial opinions over alternatives are the principled fix and are on the roadmap (M6). | yes |
| Hypothesis weighs 0 | Keep. A proposal with no data is recorded and contributes nothing; a positive prior needs base rates (M6). | yes |
| Retire the hub list for IC | Yes: IC default, hubs behind a flag (phase 2b). | yes |
| IC threshold 2.5 on 42 LLM-rated facts | Accept provisionally; a 100-fact human-rated set is the proper check and is a task for Dan or a curator. | yes |
| `isaInherit` on over-general premises ("blood vessels connect to the IVC") | The rule is sound; the premise is a universal the book did not mean. Fix is quantifiers in annotation (phase 2 asks Sonnet to mark `some`/`most`). | n/a |
| Versioning: Entity carries release, Statement carries year | Confirmed as default; per-statement ontology pinning deferred. | yes |
| Hole exit test missed | Accepted; rerun after phase 2 re-annotation; rule induction for the abundance case is its own future task. | n/a |
| Add an `opposes` relation? | Not yet. RO has none; opposite-sign effects on a shared target already express antagonism per effector. Revisit if phase 2 shows many "opposes" sentences. | yes |
| Guards on effect rules (parthood is not causation; shared cause; feedback loop) | Agreed as the three guards to add before more effect search; queued after phase 3. | n/a |
| IsA data as a tree, retired terms unknown, import PATO/MONDO/HP/SO/PR | Tree yes; retired terms stay unknown (three have no replacement); import the five more (phase 3). | yes |
