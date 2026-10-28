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

## 5. Morning report

Everything below is committed and pushed; every build (core, BioLeanLib, TextbookR2, TextbookR3)
is green at HEAD. Nine agents ran across three phases; none hit a limit after the plan was written.
Read the CHANGELOG entries headed "overnight" for the per-task detail, and `docs/textbook-lean-check.md`
round 3, `docs/ic-triviality.md`, `docs/concept-drift.md`, `docs/holes.md`, and the three new Lean
example files (`Chemiosmosis`, `Transcription`, round-3 claims) for the results themselves.

### Milestones

| milestone | state this morning |
|---|---|
| M2 context, hypotheses, rivals | **done.** Entity refinement built yesterday; tonight added `hypothesis` (weight 0), `noEffect`, `opinionAt year`, `Rivalry`. The chemiosmotic history is theorems: both rivals contested in 1965; chemiosmotic established 0.806 and chemical intermediate refuted 0.818 in 1974; the one-claim reading never established in any year, proved for all years. |
| M3 quantity | built yesterday; tonight 620 quantity and context claims re-annotated with it: 425 got a constructor, 356 emitted, **351 compile**. The textbook is now **1,909 of 4,695 claims in Lean (40.7 percent)**, from 33.9. |
| M4 generalise | **built.** `generalize` over instances in sibling taxa, coverage from the real NCBITaxon hierarchy, two measures. Proved: a generalisation's belief never exceeds its coverage. Transcription in cellular organisms: five model organisms reach 0.63 under bracketing; adding Euglena, Paramecium and Halobacterium gives 0.97 and *established*. A retrovirus instance cannot enter the generalisation (compile failure, right reason). |
| M5 ontologies as biolib | **started.** The is_a ancestor closure of every CURIE biolib uses, from ten ontologies (GO, UBERON, CL, ChEBI, NCBITaxon, PATO, MONDO, HP, SO, PR): 3,548 terms, 4,857 edges, as a Lean search tree; `decide` in 60 ms. The hand-pinned taxon table is gone. |
| M8 search | the hole search exists (ILP step one); the closure reruns in one command with the IC filter as default. |

### Findings worth your attention, in order

1. **Clade fraction cannot establish a universal; bracketing can, and it points at the gaps.** With
   eight instances across all six major lineages, clade fraction reaches 0.18, because it measures
   how mammal-heavy our vocabulary is (30 of 44 known cellular leaves are animals). Bracketing went
   from 0.63 to 0.97 when the unsampled lineages (Discoba, Sar, Archaea) got one instance each.
   Your instinct was right. Two honest flaws: "known children" come from our own vocabulary, not
   from NCBI (Eukaryota has 4 here, 18 in NCBI), so bracketing is generous; and it has a cliff
   (mouse plus human give Metazoa coverage 0 because Porifera is unsampled).
2. **A rivalry decides losers, never winners.** Proved (`Rivalry.belief_le`): no rival's belief
   rises above what its own evidence gives. Chemiosmosis wins in 1974 only because the chemical-
   intermediate reports are re-read as support for a rival that the experiments then refute.
   Entering each experiment on both rivals partly double-counts; multinomial opinions are the
   principled fix (M6).
3. **Concept drift is real and measurable.** 77 percent of the textbook's GO terms existed in GO
   in 2005, 99 percent in 2020. "Cell division" did not exist in GO at the end of 2004; "mitotic
   nuclear division", which 17 statements use, was minted in 2017. A third of the 2005 terms have
   since been renamed. Nine statements rest on retired terms. Versioning policy confirmed: entities
   carry their release, statements their year.
4. **Information content beats the hub list and exposes an annotation habit.** The IC filter keeps
   881 of 1,606 derived facts at threshold 2.5. The hub list was wrong 36 percent of the time and
   nondeterministic; it is now opt-in. IC ranks specificity, not truth: ChEBI leaves dominate.
5. **The hole search did not rediscover the eight hand-found holes, and the reason is the
   finding.** Every one sits exactly where the formal vocabulary stops (proportion, precondition,
   compound sentence), or needs rule induction rather than a missing fact (organelle abundance).
   The best hypothesis it did find: one "opposes" relation between the sympathetic and
   parasympathetic systems would make six textbook sentences theorems.
6. **Round 3 found what M3 still lacks, from the data:** approximate and range counts (nine records
   lean on a PATO workaround), open-ended measures ("over 6 m"), counts with a relation (trachea to
   two bronchi), superlatives, rates of change, and comparisons between two contexts of one entity
   (K+ inside versus outside). Five Lean rejections were UBERON life stages put in `Ctx.stage`,
   which only takes GO processes: a schema gap, not an emitter bug.
7. **Loading the refinement axioms into the closure finds annotation errors.** A scratch run with
   "e ⊓ ∃r.f is_a e" edges raised derived facts to 2,190 and clashes to 5; one clash is a real
   round-2 error ("animal cells have a centrosome" annotated as true of every cell). Not yet
   committed as default.
8. **Three identifier errors found and fixed or flagged:** area postrema in the Ozempic entities was
   the inferior cerebellar peduncle (fixed); PR:000009054 labelled "insulin" is preproinsulin; CL
   "somatic cell" is obsolete with a replacement that loses its meaning (kept, flagged).

### Decisions for you (the agents' questions, with my provisional answers)

| question | provisional answer |
|---|---|
| Keep "constructor plus blocker" as a sound weakening (57 records, +56 statements)? | Yes. The blocker names what was dropped; a weakened true claim is still a claim. Emitter to include them. |
| Prokaryote as Bacteria (drops Archaea) or cellular organisms (drops the restriction)? | Bacteria, as the annotators chose. "Cellular organisms" would make "ETC in the plasma membrane" false of eukaryotes. Archaea are lost and should be said so. |
| Bracketing: count children from real NCBI, not our vocabulary? | Yes, that is the honest version; it will lower the numbers and that is correct. Soften the cliff by recursing to the deepest bracketed split. |
| Load refinement-axiom edges into the closure by default? | Yes; it found a real error. |
| `Ctx.stage` for UBERON life stages; open-ended measure; count range; count with relation; second context slot? | Yes to the first three (small, data-driven). The second context slot and "damaged state of the subject" wait for more cases. |
| Obsolete CL "somatic cell" | Replace with "diploid cell" CL:0000415 where meant; fix `Examples/Quantity.lean` to match. |
| Emitter site placement (site refines the target for amount/process/activity, else the subject) | Accept as the convention; document it. |

### What did not happen

Nothing was pushed to GitHub by agents; I pushed after verifying each phase's build. No
literature work, no weight calibration, no rule induction. The attribution trailer on agent
commits names the model that did the work (Sonnet 5.5, Opus 5.5) rather than Fable 5.1; I left
those as they are, since they are accurate.
