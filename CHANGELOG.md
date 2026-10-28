# CHANGELOG

Findings and decisions, dated. Code history is in `git log`; this records what we learned.

## 2026-10-28 (overnight: round 3 emit, compile and closure rerun)
- Built `scripts/textbook/emit_lean_m3.py` and lean_lib `TextbookR3` (`BioLean/Lib/TextbookClaimsR3/`, 134 new
  entities). Of the 620 round-3 records, 356 were emitted and 351 compiled (98.6%). The 57 records that have a
  constructor and also a blocker were skipped, as the rule says; 56 of them would emit. All 5 Lean rejections are
  UBERON life stages ("adult") put in `Ctx.stage`, which is `Entity .process`. That is a schema gap, recorded in
  `data/textbook/r3_skip.tsv`. Lean found no emitter bug. A Lean `#eval` showed the emitter's composite curies
  match `Entity.inCtx` for all 351 statements.
- The whole textbook is now 1,909 compiled claims out of 4,695 (40.7%; round 2 was 1,591, 33.9%): relational
  1,376, causal 366, quantity 167. 33 round-3 claims replace weaker round-2 versions of the same sentence.
- Context rule, my call: a site (anatomy, cell type, component) refines the effect's target when the target is an
  amount, process or activity, and refines the subject otherwise. So "rising blood glucose stimulates insulin"
  becomes glucose raising insulin ⊓ blood. That differs from Examples/Context.lean T08, which refines the subject.
- `closure.py` now loads round 3 and uses IC as its default filter (`--hubs` for the old hub filter, `--no-m3` to
  reproduce the earlier run byte for byte). Asserted 1,248 to 1,378; derived 1,551 to 1,606; IC-kept 837 to 881;
  clashes still 2. Holes 6,735 to 7,418; after screening 2,172 to 2,611; grouped 842 to 1,016. None of the eight
  hand-found holes was rediscovered.
- Found: refined entities do not link to their base term in the closure. Loading Lean's `refineAxiom` edges
  (scratch run, not committed) gives 2,190 derived facts and 5 clashes. One clash is a real round-2 error:
  "Animal cells also have a centrosome" was annotated as true of every cell, so plant cells get centrioles.

## 2026-10-28 (overnight: round 3 annotation, quantity and context, cells, photosynthesis, energy)
- Re-annotated the 204 records of `cell-structure-and-function` (106), `photosynthesis` (28) and `how-cells-obtain-energy`
  (70) that M2 blocked as `quantity` (141) or `context_required` (63). Output `data/textbook/claims_m3/<chapter>.json`,
  each record with an `m3` field. 133 now have a constructor (65 percent: 70 of 141 quantity, 63 of 63 context); 71 stay
  `none`. By constructor: rel 63, effect 15, less 12, count 12, measure 10, produces 9, consumes 5, notRel 3, cardinality
  2, yield 2. Quantifiers: most 13, some 5. Context used: taxon 51 (Viridiplantae 20), condition 13, anatomy 11, cellType
  9, component 8, stage 1. 30 curie_changes in 30 records. Confidence: high 83, medium 109, low 12.
- 32 of the 133 keep a blocker beside the constructor: the sentence was encoded as a sound weakening and the blocker names
  what was dropped (proportion 11, compound 10, exclusivity 4, disjunction 3, precondition 2, necessity 1, other 1). The
  71 `none`: other 20, proportion 18, ungrounded entity 12, has_quality 10, precondition 5, necessity 3, exclusivity,
  sequence and unsupported ontology 1 each.
- Gaps the data found, beyond the earlier list. (1) Two contexts in one claim again: "ribosomes are smaller in
  prokaryotic cells", K+ and Na+ inside versus outside a cell. (2) Steps of a process have no GO term (Calvin reduction
  and regeneration steps, the two halves of glycolysis), so "12 ATP in the reduction step" cannot be scoped; "six turns
  make one glucose" is a ratio of runs, not an integer per run. (3) `produces` takes a process, and water splitting is
  only a GO function (GO:0010242), so that record stays `none`. (4) A superlative with no comparator named in the
  sentence ("thinnest", "most prominent") is `less` only when the neighbouring sentences name the other class.
- Judgement calls. Per-turn counts were divided by hand in three records (centriole 9 triplets = 27 microtubules, 6
  carbons in six turns = 1 per turn, 6 carbons of glucose = 6 CO2): arithmetic the book implies, not states. "Prokaryotic"
  as a taxon became Bacteria (3 records): NCBITaxon:131567 would drop the restriction and make "the electron transport
  chain is in the plasma membrane" false of eukaryotes. Hypotonic and hypertonic became environments with PATO decreased
  and increased osmolarity; "hot, dry day" has no single term (`BLN:hot_dry_day`). A damaged cell is filed as an organism
  condition (PATO:0001167) because there are only two kinds.
- Traps. CL:0002371 somatic cell is obsolete and kept in 2 records, as before. GO:0019661 lactic acid fermentation is
  obsolete; GO:0019244 used. The OLS4 id search returns hits from other ontologies (CL:0002371 resolved in AEO and BCGO),
  so a CURIE check has to match the home ontology. The first OLS4 call of a session timed out; later ones were fine.

## 2026-10-28 (overnight: round 3 annotation, quantity and context, molecular biology and inheritance)
- Re-annotated the 198 records of `molecular-biology` (106) and `the-cellular-basis-of-inheritance` (92) that M2 blocked as
  `quantity` (147) or `context_required` (51). Output `data/textbook/claims_m3/<chapter>.json`, each record with an `m3`
  field. 128 now have a constructor (65 percent: 81 of 147 quantity, 47 of 51 context); 70 stay `none`. By constructor: rel 49,
  count 20, measure 15, effect 14, cardinality 7, atLeast 6, yield 6, produces 3, notRel 3, consumes 3, less 1, mediatedBy 1.
  Quantifiers: most 13, some 13. Context used: taxon 75 (Eukaryota 21, human 18, E. coli 16, Metazoa 7, Bacteria 6), stage 10,
  condition 11 (organism 8, environment 3), cellType 6, component 1, anatomy 0. 67 curie_changes in 55 records. Confidence:
  high 77, medium 107, low 14.
- Convention: a constructor with a blocker is a sound weakening and the blocker names what was dropped (25 records: compound 8,
  proportion 5, has_quality 4, exclusivity 4, other 4). The 70 `none` have a blocker too: other 24, ungrounded entity 17,
  proportion 9, precondition 7, compound 5, no current ontology term 2, definition 2, has_quality 3, exclusivity 1. A
  precondition ("only if unrepaired") is never dropped to a bare claim, since that would be stronger than the sentence.
- Checked: all 128 constructed claims elaborate in Lean, with `inCtx` for the context (generated file, not committed).
- What worked. `yield` on ploidy (PATO:0001374) says "meiosis I takes two sets to one" (-1) and "mitosis keeps the number" (0), 6
  records. "Haploid cells have one set" is `measure` of ploidy with unit "chromosome sets", so `BIOLEAN:chromosome_set` is not needed.
  `produces` fits two forks per origin (2), four haploid cells at the end of meiosis II (4, stage) and one Barr body (1).
  Lactose present or absent is an environment condition (CHEBI:17716, or a BLN placeholder for the absent case).
- Gaps. Equality ("as much A as T", one nucleotide per nucleotide read) 6 records; proportions and ratios ("half the
  chromosomes", "twice as fast", "almost entirely") 14, where at best the sign survives (meiosis reduces ploidy, sexual is
  slower than asexual); probability ("equal chance") 4; formulas (2^n); superlatives. 17 records need a part with no term:
  ring, hydrogen bond, strand, chromatin fiber, tetrad, replication mistake. 7 are conditionals (T27-style conclusions such as
  "diploid egg plus haploid sperm gives a triploid zygote" cannot stand alone).
- Data traps. Polysome (GO:0005844) is obsolete with no replacement, so two polysome sentences stay `none`. GO:0000003
  reproduction is obsolete (GO:0022414 used). CL:0002371 somatic cell is obsolete; new records use diploid cell (CL:0000415)
  and it survives only where M1 already had it. `Ctx.stage` is `Entity .process` but "adult" and "early embryo" are UBERON stage
  terms (UBERON:0000113, UBERON:0000068). `cardinality nucleobase 4` (`Quantity.S_bases`) overcounts: uracil is a fifth.
- Decision for Dan: prokaryote became Bacteria (NCBITaxon:2) everywhere. The rule offered NCBITaxon:131567 for sentences naming
  both kinds, but cellular organisms includes Eukaryota, so "transcription occurs in the cytoplasm" would contradict the
  eukaryote sentence by is_a. Archaea are dropped.

## 2026-10-28 (overnight: round 3 annotation, quantity and context, body systems and reproduction)
- Re-annotated the 218 records of `the-body-s-systems-a`, `-b` and `reproduction-at-the-cellular-level` that M2 blocked
  as `quantity` (142) or `context_required` (76), against the M2 context and M3 quantity constructors. Output is
  `data/textbook/claims_m3/<chapter>.json`, each record with an `m3` field. 164 now have a constructor (75 percent:
  91 of 142 quantity, 73 of 76 context); 54 stay `none`. By constructor: effect 47, count 37, rel 31, measure 29,
  atLeast 7, less 5, cardinality 5, notRel 2, produces 1. Quantifiers: most 10, some 6. Context used: taxon 94
  (human 54, Bacteria 11), anatomy 47, cellType 11, stage 6, condition 9, component 0. 74 curie_changes in 65 records.
- The 54 that stay `none`: other 28 (superlatives, rates of change, vague amounts, comparisons with no class), ungrounded
  entity 10, proportion 5, compound 4, precondition 4, no ontology term 3. Confidence: high 43, medium 105, low 16.
- Gaps in the M3 vocabulary the data found. (1) A count range ("20 to 30 alveoli", "one or two axons", "approximately
  100,000 neurons") has no constructor; 9 records use `measure` with PATO:0001555 "has number of". (2) `count` has no
  relation slot: "the trachea divides into two bronchi" and "the CNS is covered by three meninges" carry the RO label in
  `relation`, which the Lean cannot say. (3) `measure` needs an open end ("over 6 m", hi = null). (4) Superlatives
  ("the femur is the longest bone") are not `less`: the class on the left contains the subject. (5) A gradient between two
  contexts of one entity (K+ inside versus outside the neuron) needs two contexts in one claim. (6) A claim with context
  on two entities (blood glucose, alpha cell) has to share one Ctx.
- Data traps. CL:0002371 somatic cell is obsolete (replaced_by CL:0000000, which loses the meaning); it is kept in 4
  records and in `Examples/Quantity.lean`. Prokaryote was NCIT:C14263; it became Bacteria (NCBITaxon:2) in 11 records and
  Archaea are dropped. "Chromosome set" has no term; `BIOLEAN:chromosome_set` was not used, "two sets" became ploidy
  (PATO:0001374). GO:0070997 neuron death is obsolete, cell death used. PR:000009054 is preproinsulin and PR:P01275
  pro-glucagon; kept from M2.

## 2026-10-28 (overnight: ontology is_a import)
- Built `scripts/ontology/collect_entities.py` and `import_isa.py`, emitting `BioLean/Ontology/IsA.lean`.
  Biolib uses 1,493 CURIEs (1,004 in Lean, 1,453 in the M2 claims); 1,158 are in the five imported
  ontologies (GO 562, UBERON 297, ChEBI 182, NCBITaxon 61, CL 56). Their is_a ancestor closure is 2,911
  terms and 4,060 direct edges (longest chain 39), well under the 8,000 cap, so nothing was trimmed. Every
  used term was found. NCBITaxon came from OLS4 (283 calls, cached, release 2026-07-12). PATO, MONDO, NCIT,
  HP, SO, PR and others (335 CURIEs) are not imported.
- 9 used terms are retired: 6 GO and 2 CL obsolete, 1 GO alt_id. Six have `replaced_by`; polysome
  (GO:0005844) and mRNA polyadenylation (GO:0006378) only say `consider`; aging (GO:0007568) says nothing.
  They are in `Ontology.retired` and are not `known`.
- Speed decided the shape. A flat edge list cost 10 s in the kernel for mouse is_a Mammalia, and
  elaborator `decide` on ten such queries did not finish in ten minutes. The terms now sit in a
  balanced search tree keyed on (ontology, id): 60 ms for that query, 0.4 s for a false query from AMP
  (417 paths to the ChEBI root), under 0.5 s for `Taxa.siblings` on curie strings with plain `decide`. Trap:
  `isA` written as `a == b || match fuel with ...` hung elaborator `decide` on a code from `Curie.encode`;
  matching on fuel first fixed it. Nothing needs `native_decide`.
- `Taxa` keeps its API over the import and the hand table is gone; Context tests pass unchanged. E. coli,
  cow and Halobacterium are now known taxa (the last was marked unverified; its CURIE checks out).
- Seen in passing: `areaPostrema` in `Lib/Entities.lean` is UBERON:0002163, the inferior cerebellar
  peduncle; area postrema is UBERON:0002162. A label lint would be noisy: 479 of 1,017 literals differ
  from the ontology label, nearly all textbook surface forms.

## 2026-10-28 (overnight: hole search)
- Built `scripts/search/holes.py`, the first step of hypothesis generation by inverse entailment. For each
  of the 1,223 textbook statements that follow from nothing else, every closure rule is run backwards with
  one premise known; the other premise is then fully determined, and is a hole. 6,735 holes; 2,172 after
  screening (RO sorts, `is_a` across kinds, GO/UBERON/CL/ChEBI refutation, obsolete terms, relation
  patterns never seen in the book); 842 hypotheses once alternatives are grouped. Output
  `data/search/holes.json` and `docs/holes.md` (top 40 judged by hand, with notes).
- The tool did not rediscover G1 or G6, nor any of the eight holes found by hand. Six sit in sentences
  blocked by a missing constructor (quantity, necessity, context, compound, ontology), G3 half, and G6 was
  grounded as "glucose raises insulin" so the drink never appears. G1 needs a rule, not a fact. With the
  drink grounded as sucrose the search does propose "sucrose raises the amount of glucose". The hand-found
  holes live exactly where the formal vocabulary stops, which makes phase 2 the way to reach them.
- Top 40 judged: 13 true but unstated (95 holes in all are confirmed by an ontology), 5 plausible biology,
  20 artefacts of a rule (chain rules have no direction, arbitrary intermediates, class-level overshoot),
  2 of grounding. Best finds: sympathetic and parasympathetic antagonism (the schema needs a symmetric
  "opposes"), LDL receptors lower cholesterol, cyclooxygenase raises fever, "anti-inflammatory drug lowers
  inflammation" as a real induction, p53 acting through checkpoint signalling.
- Side finding: four obsolete ontology terms in the grounding (CL animal cell, GO reproduction, DNA primase
  activity, homolactic fermentation), and thylakoid grounded to two terms. Sentences completed rewards
  coincidence; only the ontology check is a plausibility signal.

## 2026-10-28 (overnight: information content and concept drift)
- Information content as the triviality filter (`docs/ic-triviality.md`, `scripts/ontology/ic.py`,
  `closure.py --ic`): IC = -log(subtree/N) from GO, UBERON, CL and ChEBI (ChEBI fetched in 6 s), over
  is_a plus part_of (is_a alone scores "multicellular organism" 5.96). Score of a fact = min IC of its
  two ends. Threshold 2.5 keeps 837 of 1,551 derived facts, 603 trivial, 111 unjudged (NCBITaxon, PR,
  MONDO, ... not loaded). Of the hub list's 1,175 survivors 423 are IC-trivial, and it removes 183
  facts IC calls non-trivial. The hub list is also nondeterministic (1,159 to 1,187 survivors by hash seed).
- IC finds specific facts, not true ones. The top of the list is ChEBI chemistry (leaf IC saturates at
  12.3) and effect chains through loosely linked entities; 5 of the 23 kept facts in a 42-fact hand
  sample were wrong or dubious. `isaInherit` hands "blood vessel connected to IVC" to the superior vena cava: the
  existential-read-as-universal flaw again. Min IC over the whole derivation did better on the same
  42 labels but 42 labels is too few to choose.
- Concept drift (`docs/concept-drift.md`, `scripts/ontology/concept_drift.py`): the textbook uses 559 GO
  CURIEs (not ~1,000). Live in GO of Dec 2004 / Dec 2009 / Dec 2014 / Jan 2020: 77% / 92% / 97% / 99%
  (statements fully expressible: 906 / 1,080 / 1,136 / 1,168 of 1,171). 33% of the 2005 terms have a
  different name today; of those with the same name 63% have different definition text. 7 retired terms
  are still in use (6 obsolete, 1 merged), all live in 2020. `creation_date` is back-filled for older
  terms (16 of 59 contradict the snapshots), so it is not a mint date. Lipid raft GO:0045121 kept its
  id and changed name, parent (4 times) and definition between 2004 and 2008.

## 2026-10-28 (overnight: argument layer)
- Built: `EvidenceKind.hypothesis` (weight 0), `Claim.noEffect` (a measured null), `opinionAt year`
  on Statement and Derivation (one recursion, `opinionWith`, behind both), and `Rivalry`: belief in
  one rival is fused as disbelief into the others. `Statement.forall_opinionAt` proves a property
  for every year by checking only the evidence years.
- M2 exit test met (`BioLean/Examples/Chemiosmosis.lean`): in 1965 both rivals are contested
  (b = d = 1/3); by 1974 chemiosmotic is established (b = 0.806) and the chemical intermediate refuted
  (d = 0.818). Read as one claim with refutations, chemiosmotic is never established in any year
  (top b = 0.714), as the Python sketch found.
- Finding, proved (`Rivalry.belief_le`): a rivalry decides losers, not winners. It never raises a
  rival above its own evidence. Chemiosmosis wins because the chemical-intermediate reports become
  support for a rival that the experiments then refute, not refutations of chemiosmosis.
- With the items as the script had them, the theorems are false: 1965 chemiosmotic b = 0 (hypothesis
  weighs 0, nothing else before 1966), 1974 b = 0.727. Changed illustrative items only: the 1963
  review is now `.hypothesis` (it restates, no data); one 1965 pro-chemiosmotic item added (stands for
  Mitchell & Moyle 1965, PMID unchecked). The six real papers alone give the 1974 result
  (b = 0.800 exactly, d = 0.889) but not 1965.
- Limit: each experiment is entered on both rivals (as `docs/formalisms/biolean.md` did), so the
  rivalry partly counts it twice. Without those direct refutations both 1974 numbers are 0.714.
  Multinomial opinions would fix this.

## 2026-10-28 (M2 built)
- Context implemented as entity refinement: `Entity.refine e r f` (the class e ⊓ ∃r.f, RO domain
  checked, bracketed composite curie), `Ctx` and `Entity.inCtx` applying fields in a fixed order so
  one context gives one identifier. Organism state refines the taxon filler; environment refines the
  subject. Rules `refineMono`, `isaInheritEffect`, `transport` (sibling taxa only, needs a
  `crossSpecies` evidence item at 3/10, listed in axioms). Evidence gains dose, duration, strain,
  system, taxon; `Statement.taxonConsistent` lint. Pinned taxon table `BioLean/Taxa.lean`.
- S1 to S5 pass as theorems and `#check_failure`s; 38 of the 40 bake-off claims port (the two left
  are preconditions, now rejected by the domain check). NMN in aged humans from aged mice: belief
  0.21, unsupported, with the transport item as an axiom. (`BioLean/Examples/Context.lean`)
- Known limits: one organism state per `Ctx`; the refinement axiom is 999/1000 not 1 (`lt_one`);
  the lint reads curie strings so it is `#guard`, not kernel `decide`; lineage steps through
  ordinary ontology axioms are still capped at 0.9.

## 2026-10-28 (M2 bake-off)
- Three context designs built in isolated worktrees against the same 40 textbook claims plus NMN
  and chemiosmosis, then judged on soundness first (`docs/m2/`). Wrapper-on-the-claim and
  refinement-on-the-entity both enforce "mouse and human evidence cannot fuse" at the type level;
  evidence-level context passes only by discipline and already failed on real data ("in some
  organisms" became universal). Verdict: refinement, hardened.
- The hybrid hypothesis held with one correction: textbook "conditions" are claim-level 23 of 37
  times, misfiled quantifiers 7, preconditions 7, experiment protocol 0. Conditions are refinable
  entities; Evidence carries only protocol (dose, duration, strain, system). Organism state
  (disease, genotype, age) refines the taxon filler. ~93 percent of the 190 context claims covered.
- All three builders found transport costs exactly 0.7 × 0.3 = 0.21 with a proved ceiling. The
  refinement builder found and fixed a composite-identifier collision ("(NMN in human) aged" vs
  "NMN in (aged human)").

## 2026-10-28 (M3: quantity)
- Claims: `count`, `atLeast`, `cardinality`, `measure` (interval with unit), `less`, `produces`,
  `consumes`, `yield`, and a `quant` wrapper for `some` / `most`. Rules with arithmetic side goals
  discharged at construction: `sequencesOver` (4^3 = 64 codons), `pigeonhole` (61 sense codons onto
  20 amino acids gives SOME amino acid two codons), `perSet` (46 / 2 = 23), `fusionAdds` (haploid +
  haploid = diploid; diploid egg + haploid sperm = triploid), `netYield` (4 − 2 = 2 ATP),
  `compareIntervals` (5 µm < 10 µm), `weaken`. Seven textbook counting sentences are theorems
  (`BioLean/Examples/Quantity.lean`); `cardinality codon 65` fails to build.
- The closure's only clash dissolves: "most neurons have axons" and "some neurons have none" are
  different claims under `quant`; no rule connects them. A universal would still clash.
- Decision (Dan): triviality of conclusions and the caveated-chain discount should come from the
  information content of the ontology term, not a hub list or a flat factor. Not implemented.

## 2026-10-28 (closure search)
- First forward-chaining closure over the compiled textbook: 1,248 statements give 1,551 derived
  facts at depth 4; 60 sampled derivations emitted as Lean and **all 60 certified** by the kernel.
  (`docs/closure-search.md`, `BioLean/Examples/Closure.lean`)
- Found two unsound rules of ours: `relInv` (inverting a class-level existential) and the is_a laws
  applied to is_a itself. Both removed/tightened; tests pin them. The first run had produced "DNA is_a
  messenger RNA" and "salivary glands overlap ganglia".
- Finding: sign chains through a feedback inhibitor (ATP inhibits sugar catabolism) are formally
  correct and biologically misleading; 56 of 73 effect conclusions pass through it. Needs a loop
  construct or a report flag.
- The only clash is a quantifier ("most neurons have axons" vs "some have none"): M3 confirmed next.
- Missing Lean rule found: is_a inherits an effect (56 uses in the closure).
- Cancer-to-energy-metabolism path query: connected only through "cells"; nothing provable here.

## 2026-10-27 (RO issues posted)
- Four issues opened on oborel/obo-relations from Dan's account: #897 (immediately preceded by /
  precedes chains), #898 (spatially coextensive chain), #899 (indirectly negatively regulates sign
  chains and transitivity), #900 (provides input for missing inverse). `docs/ro-issues.md`

## 2026-10-27 (RO fixes tested)
- Fixing the seven RO chain axioms in a copy changes nothing under ELK or JFact: RO defines no class
  with these properties, so the chains only fire on data. On test instances the wrong conclusions
  vanish and the missing `provides_input_for` appears. UBERON carries 67 false "spatially coextensive"
  entailments from row 79 under a full DL reasoner, and copies three of the bad chains itself.
- The regulation fix needs care: RO_0002409 is also transitive (neg ∘ neg = neg again); the working
  fix moves the three chains to RO_0002407 and drops transitivity, mirroring RO issue #182 (2017).
  No open RO issue covers any of the seven; #818/#821 (2025) introduced the has_output ∘ has_input
  chain and lost the inverse. Drafts in `docs/ro-issues.md`; regression in `docs/ro-fix-regression.md`.
- Test correction: starts_with is RO_0002224 and ends_with RO_0002230; the pinning test now checks
  the real blocked chain.

- All 4,695 textbook claims re-annotated by Sonnet into structured subject/relation/object fields
  with a fixed blocker list; 1,906 judged expressible, 1,594 emitted, **1,591 compile (99.8%)**.
  Round 1's 132 rejections were mostly my parser guessing entity order from Haiku's Lean strings.
- Schema: `Target.activity` now accepts a protein or a GO molecular function (20 of the 22
  remaining rejections); `viaActivity` generalised. Remaining real rejections: no disease target;
  GO functions used as located things (Lean is right).
- Measured expressibility after M1 is 34 percent emitted and compiled, 41 percent with the
  context and unsupported-ontology claims. (`docs/textbook-lean-check.md`)

## 2026-10-27 (OLS tagger)
- OLS text tagger (`POST /ols4/api/v2/tag_text`) tested with ASCII-normalised input: 1,102 hits vs
  OAK's 1,485; 85 percent agreement with agents where it hits; 96 percent agreement with OAK where
  both hit. Labels only, no synonyms, no plurals. Bug confirmed and written up: offsets are UTF-8 byte
  offsets, not character offsets, so each curly quote shifts later matches by two. Keep OAK first.
  (`docs/ols-tagger-trial.md`)

## 2026-10-27 (OAK trial)
- Ontology Access Kit (oaklib) as local grounder, same 2,803 pairs as Gilda: 1,485 hits, agrees with
  the agents on 80 percent where both answer (Gilda 45). Cross-namespace disagreements fall from 691
  to 147. Still misses the ~1,100 paraphrases and plurals. Decision: OAK as the cheap first pass and
  slip-catcher, agents for the rest. (`docs/oak-trial.md`)

## 2026-10-27 (Lean-checking the book)
- Every "now" textbook claim emitted as a Lean `Statement` and compiled: 811 binned, 702 emitted,
  **570 compile**. Lean rejected 132: 115 target-shape errors, 19 RO domain/range violations
  (14 are `capable_of` with a chemical object where `produces` was meant). `docs/textbook-lean-check.md`
- Schema gap found by the compiler: `Target.activity` should also accept a GO molecular function
  ("enzymes" grounds to GO:0003824). 67 claims blocked only by missing `Kind`s (SO, NCIT, EFO, OBA).
- `BioLean/Tests/RO.lean` pins the RO chains, inverses, blocked chains and domain sorts we rely on.
- Glossary: premise, conclusion, rule, instance.

## 2026-10-27 (M1 checks)
- Chain-length experiment over GO and UBERON: longest part_of chains are depth 10 and 12 and
  biologically correct; product belief falls to 0.35 and 0.28. Decision: RO-chain steps are logical
  and use `Opinion.weakest` (min belief, zero disbelief). Textbook derivations now score 0.80.
- 164 RO chains hand-checked by 8 Haiku agents and reviewed by Opus: 44 / 76 / 25 / 19 sound /
  caveat / suspicious / wrong. Seven chains are faithful imports of RO axioms that look wrong
  (rows 14, 16, 79, 87, 88, 89, 90 in `docs/ro-chains.md`); verified against ro.owl. 38 chains
  blocked by default via `scripts/ro/blocked_chains.tsv`; the importer asserts they still match.
- Measured re-annotation against the M1 schema (8 Haiku agents, 3,730 records): now 17.3 percent,
  with context 30 percent. The construct-name heuristic (62.6) over-counted 3.6x. Top remaining
  blockers: compound sentences, ungrounded entities, quantities. Relations used most: has_part 117,
  is_a 67, produces 32, located_in 28, has_input 25.
- Gilda trial on 2,803 (text, CURIE) pairs: 1,510 hits, 648 agree, 802 disagree of which 691 are
  namespace-only. Verdict: use as a GO/ChEBI checker. (`docs/gilda-trial.md`)
- Glossary written (`docs/glossary.md`). RO release pinned in the generated file (2026-09-04).

## 2026-10-27 (M1)
- Built relational claims: `Claim.rel` / `Claim.notRel` over RO relations, with RO's rdfs:domain
  and range checked by `decide`. RO imported from ro.owl as Lean data (642 relations, 164 chains,
  124 inverses, 45 transitive). Rules: `relChain` (chains, transitivity, is_a inheritance both
  ways), `relInv`, `notRelSub`, `notRelObj`, and `clash` for a positive vs a negated derivation.
- "The gonads produce steroid hormones" is a theorem: `inverse(occurs_in) ∘ has_output ⊑ produces`
  (RO:0003000) applied to "steroidogenesis occurs in gonad" and GO's has_output. Glycolysis in the
  cell, ascending colon in the large intestine, hepatocytes have nuclei, heterocysts lack nuclei
  all check; a text-mined "heterocyst has a nucleus" clashes with the inherited negation and
  loses (d = 0.64).
- Correction: RO has 164 property-chain axioms, not 336 (the earlier count doubled open/close tags).
- Finding: a two-step chain of a textbook sentence (0.8) and an ontology axiom (0.9) scores 0.72,
  below θ. Logical steps dilute like evidential ones. Open decision for M6.
- Re-bin estimate: expressible-now rises from 8.8 to 62.6 percent of textbook claims once RO
  relations are claims (by construct name, not re-annotation).
- Added evidence kinds `textbook` (0.8) and `ontologyAxiom` (0.9); PMID 0 marks non-paper evidence
  and is not deduplicated. Added kinds `component` (GO CC) and `taxon`.

## 2026-10-27
- Textbook milestone run: 4,695 claims from 7 OpenStax chapters. Entities ground at 93 percent;
  8.8 percent of claims fit the signed-effect schema, 21 percent with Context, 79 percent need
  structural constructors. 52 sentences derivable; 4 type-check today. 15 percent of structural
  claims are already ontology axioms. (`docs/textbook-milestone.md`)
- Decision: next core change is relational claims over RO, not more effect machinery.
- Finding: RO ships 336 property-chain axioms and 45 transitive properties; they are the
  structural derivation rules. Its CLIF annotations are sparse and unchecked.
- Notes written on subjective logic as pseudo-counts, canon bubbling up via `generalize`, ILP as the
  inverse of a Derivation, formal systems for conditioning. (`docs/notes-2026-10-27.md`)
- Case studies collected with decisions/gaps/limits per example. (`docs/case-studies.md`)
- Finding: linear clade-fraction coverage leaves transcription "unsupported" as a universal;
  bracketing preferred.

## 2026-10-26
- Chemiosmotic replay: cumulative fusion never reaches *established* because old refutations keep
  voting; supersession or rivals needed.
- Formalism survey: 11 papers in GO-CAM, INDRA, Biolink, BEL, nanopub, BioLean. Only nanopub+SEPIO
  holds argument structure; no formalism has dose, duration, age or strain; four of six merge mouse
  and human evidence silently. (`docs/formalisms/`)
- Context extension drafted (Context.lean, inContext, noEffect, gradient, hypothesis kind); builds
  in a scratch copy. (`docs/formalisms/biolean.md` §5)
- Explainer written for NotebookLM. (`docs/explainer.md`)

## 2026-10-23
- Project started. Related-work sweep (25 projects), framework choice (Lean 4 + subjective logic),
  core built, Ozempic demo: semaglutide reduces feeding established at b = 0.968; sitagliptin and
  nausea-mediation contested. (`docs/related-work.md`, `docs/design.md`)
- Decision: `decide +kernel` on ℚ for strength theorems; statements rendered from curated JSON,
  never hand-edited.
- Pipeline run on 22 abstracts: 5 refused by the safety classifier, 2 JSON failures, 18 Lean
  statements emitted.
