# M1 quality check

M1 (relational claims over RO), four checks.

## A. RO chain hand-check

8 Haiku agents built one sound and one absurd instance per chain. I reviewed every flagged row. Chain text and all 164 verdicts: `docs/ro-chain-check.md`.

| verdict | Haiku | after review |
|---|---:|---:|
| sound | 42 | 44 |
| sound_with_caveat | 72 | 76 |
| suspicious | 25 | 25 |
| wrong | 25 | 19 |

Rows 14, 16, 79 and 87-89 are faithful imports of bad RO axioms (checked in `data/ro.owl`); 87-89 contradict RO's own row 84. Worth an RO issue.

### Every flagged row

| # | Haiku | absurd instance (short) | review |
|---:|---|---|---|
| 12 | susp | A regulates B, B only maintains P in place; "A regulates transport of P" | Agree: premise is wider than conclusion. |
| 14 | wrong | wound healing "immediately preceded by" its own sub-part | Agree: c is inside a; RO bug. |
| 15 | wrong | direction reversed | Agree: obsolete relation and wrong direction. |
| 16 | wrong | cell cycle "immediately precedes" prophase | Agree: mirror of 14. |
| 18 | susp | no clean instance | Agree: OWL trick, no meaning here. |
| 30 | susp | human muscle graft in mouse | Agree; rare, keep. |
| 31 | susp | graft or symbiont boundary | Agree: microbiome crosses taxa. |
| 32 | susp | mouse neuron in human graft | Agree, rare; keep. |
| 33 | susp | pig xenograft join | Agree, rare; keep. |
| 34 | susp | pig heart in human | Agree, rare; keep. |
| 35 | susp | tapeworm hooks into host gut | Agree: parasites are common. |
| 36 | wrong | GFP gene "in Mus musculus" | Agree: transgenes are routine. |
| 37 | wrong | viral effector "in Homo sapiens" | Agree: regulation crosses organisms. |
| 38 | susp | pan-taxon class pinned to mouse | Agree. |
| 39 | wrong | mosquito "in Plasmodium" | Agree. |
| 40 | wrong | human-pig chimera | Partly: real but rare, so suspicious; still off. |
| 41 | wrong | quail-chick graft | Partly: same as 40. |
| 42 | wrong | parasitoid drives host development | Agree. |
| 44 | wrong | E. coli "in Homo sapiens" | Agree. |
| 45 | wrong | Vero cell "in SARS-CoV-2" | Agree. |
| 46 | wrong | virion "in Chlorocebus" | Agree. |
| 60 | susp | T cells "develop in bone marrow" | Agree: source place, not development place. |
| 72 | wrong | polymerase "enables" Okazaki ligation | Agree; holds only if b is a function. |
| 73 | susp | Cdk1 enables kinase activity | Disagree: instance mistyped; sound for functions. |
| 79 | wrong | heart coextensive with lung | Agree; RO bug. |
| 82 | susp | over-credits triggers | Agree; drop. |
| 87 | wrong | PTEN "negatively regulates" apoptosis | Agree: neg times neg is pos. |
| 88 | wrong | drug blocks PTEN, AKT "down" | Agree. |
| 89 | wrong | same | Agree. |
| 90 | susp | middle node must be both material and process | Agree: needs inverse(has input). |
| 95 | susp | PP2A "in positive regulation of" proliferation | Agree: true as participation, misleading as sign. |
| 97 | susp | PTEN looks like a driver | Agree, as 95. |
| 104 | susp | PKA "phosphorylates" where inactive | Agree: potential read as event. |
| 105 | wrong | PKA "directly regulates" Pol II | Agree. |
| 114 | wrong | carbon atom "starts" at cytokinesis | Agree: continuant parts predate wholes. |
| 116 | wrong | remodelling before daughter cell exists | Agree, as 114. |
| 118 | susp | if "simultaneous" only overlaps | Disagree: RO means same start and end. |
| 120 | wrong | atom outlives hepatocyte | Agree. |
| 121 | wrong | stem cell outlives daughter | Partly: fine when precursor is consumed. |
| 124 | susp | as 118 | Disagree, as 118. |
| 131 | wrong | sibling enabler | Disagree: RO means influence on d's activity. |
| 132 | susp | cAMP's many targets | Disagree: GO-CAM definition of direct. |
| 137 | susp | citrate made and acts in different compartments | Partly: as 132, plus location. |
| 138 | susp | malonyl-CoA targets | Disagree, as 132. |
| 142 | susp | retina dysfunction = "dysfunction of human" | Agree. |
| 143 | susp | ATP as a "stimulus" | Agree. |
| 144 | susp | Na pump "enables" vesicle release | Agree, as 72. |
| 150 | susp | types do not line up | Agree; no GDC sort here. |
| 158 | wrong | idle PCR machine "uses" primer | Partly: as 104. |
| 159 | wrong | NMT1 not expressed | Partly, as 158. |

Review also flags 109 (as 104) and 122 (as 120).

### 10 best edge cases among sound rules (matter for weighting)

| # | edge case | weighting lesson |
|---:|---|---|
| 56 | two paths to the same target cancel | sign holds per path, not per network |
| 162 | vitamin D does not raise clamped serum calcium | homeostasis breaks monotone composition |
| 7 | glycolysis "occurs in organism" | lifts are true but lose information per step |
| 81 | Krebs cycle "has input" oxaloacetate | cyclic internal inputs read as external |
| 99 | Rhizobium interacts with itself | filter reflexive self-links |
| 61 | glycolysis "starts at" plasma membrane | first-step location is not process location |
| 139 | plasma "produces" fibrin | place of process is not place of making |
| 140 | one kidney down, "urinary system disrupted" | redundant parts overclaim |
| 102 | mosquito labelled host | multi-partner relations mislabel roles |
| 3 | partial overlap breaks it | needs strict containment |

### Chains BioLean should NOT enable by default

| group | rows |
|---|---|
| bad in RO itself | 14, 16, 79, 87, 88, 89, 90 |
| obsolete relations | 15, 82 |
| taxon transfer across organisms | 31, 35, 36, 37, 38, 39, 40, 41, 42, 44, 45, 46 |
| continuant parts in existence-time chains | 114, 116, 120, 122 |
| capability turned into event | 104, 109, 158, 159 |
| signed or "direct" claims from unsigned premises | 95, 97, 105 |
| other overreach or type mismatch | 12, 18, 60, 142, 143, 150 |
| only when b is a molecular function | 72, 144 |

40 off, 2 typed-only. Taxon rows 30, 32-34 stay on.

## B. Re-annotation against the M1 schema

8 Haiku agents re-binned all 3 730 `missing_construct` records. Totals from `scripts/textbook/aggregate_m1.py` (bin_m1 overrides bin; not_claim excluded):

| bin | before M1 | heuristic (`rebin_m1.py`) | measured |
|---|---:|---:|---:|
| now | 411 (8.8%) | 2 937 (62.6%) | 811 (17.3%) |
| with_context | 554 (11.8%) | 554 (11.8%) | 597 (12.7%) |
| missing_construct | 3 730 (79.4%) | 1 204 (25.6%) | 3 287 (70.0%) |

M1 doubled "now" (+400). The heuristic was 3.6x too high: it counted a claim as fixed when its first blocker was RO-shaped, but most claims have a second blocker.

### RO relations used (410 new now / with_context claims)

| relation | n | relation | n |
|---|---:|---|---:|
| has part | 117 | has output | 13 |
| is_a | 67 | enables | 6 |
| produces | 32 | disease has location | 6 |
| located in | 28 | starts during | 4 |
| has input | 25 | connects, connected to, attached to | 3 each |
| capable of | 24 | 21 others | 1 to 2 each |
| happens during | 24 | | |
| part of | 21 | | |
| occurs in | 20 | | |

### Still missing (134 raw labels, grouped)

| blocker | n | example |
|---|---:|---|
| compound (and, 3+ entities, relative clause) | 696 | Muscle tissue, connective tissue and nervous tissue are tissues |
| grounding (none, wrong, wrong kind) | 669 | Epithelial cells protect the surface of the body |
| quantity or quantifier | 558 | The human body contains many kinds of cells |
| no RO relation (naming, binds, spatial) | 378 | A living thing is called an organism |
| effect, regulation, transport, function | 264 | Bone cells support and protect the body |
| necessity, conditional, modality | 190 | Components are invisible by light microscopy unless stained |
| is_a with extra predicate, definition | 180 | Cytoplasm is the jelly-like region within the cell |
| has_quality, comparison, variation | 146 | Individual cells are generally transparent |
| sequence, temporal | 114 | Chromosomes are visible only before division |
| context, scope, qualifier | 48 | Red blood cells transport oxygen through the body |
| procedure | 42 | Light microscopes can be used to view living organisms |

Caveats: Lean terms compiled in 4 of 8 files; body systems A not compiled. Blocker grouping is mine. Cheapest unlock is grounding (669, no schema change). Allowing `Claim.effect` would move about 49 regulation claims.

## C. Gilda trial

Over 2 803 distinct mention pairs, Gilda agreed with the agent on 648, disagreed on 802 and missed 1 106. 691 disagreements are namespace only: Gilda lacks UBERON, CL, NCBITaxon, SO, NCIT and MONDO. In the 80 GO/CHEBI cases Gilda picks the literal label, the agent a context-specific child. Both make rare blunders ("enzymes" to DNA helicase; "fat" to CD36). Gilda misses all paraphrases. Use Gilda as a GO/CHEBI check and hallucination catcher, not the first-pass grounder. Detail: `docs/gilda-trial.md`.

## D. Chain length

`scripts/case_studies/ro_chain_length.py` with product belief at 0.9 per step:

| ontology | longest part_of chain | example top | product belief |
|---|---:|---|---:|
| GO | 10 | ... ⊑ nervous system development | 0.35 |
| UBERON | 12 | caudate matrix ⊑ nervous system | 0.28 |
| occurs_in lifted (GO+CL+UBERON) | 8 | His bundle action potential ⊑ circulatory system | 0.39 |

Every step is a curated, unobjectionable edge, yet product belief calls the result barely believable. So depth punishes ontology granularity, not doubt. Recommendation: make steps of chains that review marked sound (transitivity, part_of lifts) lossless (min of premise beliefs), and apply one fixed discount per use of a sound_with_caveat rule, not per step.
