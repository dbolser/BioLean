# RO chain hand-check

Copy of `docs/ro-chains.md` with the M1 hand-check added. Haiku = verdict of 8 Haiku agents (one sound and one absurd instance per row). review = senior reviewer verdict where it differs. Discussion: `docs/m1-checks.md`.

Generated from http://purl.obolibrary.org/obo/ro/releases/2026-09-04/ro.owl (sha256 9a3190d49564) by `scripts/ro/import_ro.py`. 164 chains.

| # | r₁ | r₂ | ⊑ r₃ | r₃ id | Haiku | review | note |
|---:|---|---|---|---|---|---|---|
| 1 | part of | preceded by | **preceded by** | BFO_0000062 | sound | agree | whole-to-whole precedence passes to every part |
| 2 | starts during | preceded by | **preceded by** | BFO_0000062 | sound | agree | start lies inside b, which is after c |
| 3 | happens during | preceded by | **preceded by** | BFO_0000062 | sound_with_caveat | agree | needs happens during = full containment |
| 4 | part of | precedes | **precedes** | BFO_0000063 | sound | agree | whole before c implies every part before c |
| 5 | happens during | precedes | **precedes** | BFO_0000063 | sound_with_caveat | agree | same containment caveat as row 3 |
| 6 | part of | occurs in | **occurs in** | BFO_0000066 | sound_with_caveat | agree | valid; broad locations get vague |
| 7 | occurs in | part of | **occurs in** | BFO_0000066 | sound_with_caveat | agree | valid lift; repeated lifting loses precision |
| 8 | has part ∘ realizes ∘ characteristic of | (3-chain) | **has participant** | RO_0000057 | sound_with_caveat | agree | credits whole for a part's realized role |
| 9 | has part | has participant | **has participant** | RO_0000057 | sound_with_caveat | agree | over-credits the whole as participant |
| 10 | located in | part of | **located in** | RO_0001025 | sound | agree | location lifts cleanly through part of |
| 11 | innervated by | branching part of | **innervated by** | RO_0002005 | sound_with_caveat | agree | credits whole nerve for a branch's territory |
| 12 | regulates | transports or maintains localization of | **regulates transport of** | RO_0002011 | suspicious | agree | maintains localization is not transport |
| 13 | ends during | preceded by | **ends after** | RO_0002086 | sound | agree | true but weak |
| 14 | starts with | ends with | **immediately preceded by** | RO_0002087 | wrong | agree | c is a part of a, cannot precede it (faithful to RO; RO bug) |
| 15 | starts during | obsolete preceded by | **starts before** | RO_0002089 | wrong | agree | obsolete premise; direction reversed |
| 16 | ends with | starts with | **immediately precedes** | RO_0002090 | wrong | agree | mirror of 14 |
| 17 | has soma location | part of | **has soma location** | RO_0002100 | sound | agree | valid lift |
| 18 | is neuron ∘ part of ∘ is anatomical entity | (3-chain) | **has soma location** | RO_0002100 | suspicious | agree | OWL self-restriction trick; no meaning in BioLean |
| 19 | axon synapses in | part of | **axon synapses in** | RO_0002102 | sound | agree | valid lift |
| 20 | has postsynaptic terminal in | part of | **has postsynaptic terminal in** | RO_0002110 | sound | agree | valid lift |
| 21 | has presynaptic terminal in | part of | **has presynaptic terminal in** | RO_0002113 | sound | agree | valid lift |
| 22 | dendrite synapsed in | part of | **dendrite synapsed in** | RO_0002121 | sound | agree | valid lift |
| 23 | has synaptic terminal in | part of | **has synaptic terminal in** | RO_0002130 | sound | agree | valid lift |
| 24 | part of | part of | **overlaps** | RO_0002131 | sound_with_caveat | agree | true; overlaps adds nothing beyond parthood |
| 25 | has part | part of | **overlaps** | RO_0002131 | sound_with_caveat | agree | true; trivial once a part is shared |
| 26 | has part | overlaps | **overlaps** | RO_0002131 | sound | agree | holds |
| 27 | overlaps | part of | **overlaps** | RO_0002131 | sound | agree | holds |
| 28 | innervates | part of | **innervates** | RO_0002134 | sound_with_caveat | agree | can imply whole-organ supply |
| 29 | derived by descent from | has derived by descendant | **shares ancestor with** | RO_0002158 | sound_with_caveat | agree | near-empty for remote ancestors |
| 30 | innervated by | in taxon | **in taxon** | RO_0002162 | suspicious | agree | breaks only at grafts; keep, low risk |
| 31 | overlaps | in taxon | **in taxon** | RO_0002162 | suspicious | agree | symbionts and grafts cross taxa |
| 32 | innervates | in taxon | **in taxon** | RO_0002162 | suspicious | agree | breaks only at grafts; keep, low risk |
| 33 | continuous with | in taxon | **in taxon** | RO_0002162 | suspicious | agree | breaks at xenograft joins; keep, low risk |
| 34 | connected to | in taxon | **in taxon** | RO_0002162 | suspicious | agree | breaks at xenotransplant; keep, low risk |
| 35 | connects | in taxon | **in taxon** | RO_0002162 | suspicious | agree | parasite attachment crosses taxa |
| 36 | expressed in | in taxon | **in taxon** | RO_0002162 | wrong | agree | transgenes (GFP in mouse) |
| 37 | regulates | in taxon | **in taxon** | RO_0002162 | wrong | agree | pathogen effectors, drugs, toxins |
| 38 | has prototype | in taxon | **in taxon** | RO_0002162 | suspicious | agree | narrows a class to one exemplar's taxon |
| 39 | capable of | in taxon | **in taxon** | RO_0002162 | wrong | agree | vectors capable of a parasite's process |
| 40 | has developmental contribution from | in taxon | **in taxon** | RO_0002162 | wrong | suspicious | real but rare (chimeras); still off |
| 41 | developmentally induced by | in taxon | **in taxon** | RO_0002162 | wrong | suspicious | real but rare (quail-chick grafts); still off |
| 42 | results in developmental progression of | in taxon | **in taxon** | RO_0002162 | wrong | agree | parasitoids and hormones cross taxa |
| 43 | has potential to develop into | in taxon | **in taxon** | RO_0002162 | sound_with_caveat | agree | fails for interspecies chimeras |
| 44 | existence overlaps | in taxon | **in taxon** | RO_0002162 | wrong | agree | time overlap cannot carry taxon |
| 45 | produces | in taxon | **in taxon** | RO_0002162 | wrong | agree | product taxon is not producer taxon |
| 46 | produced by | in taxon | **in taxon** | RO_0002162 | wrong | agree | host-made virions take host taxon |
| 47 | inverse(connects) | connects | **connected to** | RO_0002170 | sound_with_caveat | agree | connection via a common connector |
| 48 | attached to | part of | **attached to part of** | RO_0002177 | sound | agree | true, often weak |
| 49 | ribosomal translation of | transcribed from | **gene product of** | RO_0002204 | sound_with_caveat | agree | fusion transcripts give partial credit |
| 50 | transcribed to | ribosomally translates to | **has gene product** | RO_0002205 | sound | agree | gene has all its products |
| 51 | expressed in | part of | **expressed in** | RO_0002206 | sound_with_caveat | agree | lift to organism loses tissue detail |
| 52 | regulates | has effector activity | **regulates** | RO_0002211 | sound_with_caveat | agree | not every effector activity is regulated |
| 53 | ends with | regulates | **regulates** | RO_0002211 | sound_with_caveat | agree | end step's effect credited to whole process |
| 54 | directly regulates | directly regulates | **regulates** | RO_0002211 | sound_with_caveat | agree | sign lost |
| 55 | ends with | negatively regulates | **negatively regulates** | RO_0002212 | sound_with_caveat | agree | as 53, with sign |
| 56 | negatively regulates | negatively regulates | **positively regulates** | RO_0002213 | sound_with_caveat | agree | one path only; parallel paths can cancel |
| 57 | ends with | positively regulates | **positively regulates** | RO_0002213 | sound_with_caveat | agree | as 53, positive sign |
| 58 | capable of | part of | **capable of part of** | RO_0002216 | sound | agree | true, weak |
| 59 | directly develops from | part of | **develops from part of** | RO_0002225 | sound | agree | holds |
| 60 | directly develops from | located in | **develops in** | RO_0002226 | suspicious | agree | location of source, not of development |
| 61 | starts with | occurs in | **has start location** | RO_0002231 | sound_with_caveat | agree | first sub-step's location may mislead |
| 62 | ends with | occurs in | **has end location** | RO_0002232 | sound_with_caveat | agree | last sub-step's location may mislead |
| 63 | starts with | has input | **has input** | RO_0002233 | sound | agree | first step inputs are process inputs |
| 64 | ends with | has output | **has output** | RO_0002234 | sound_with_caveat | agree | last step output may be waste |
| 65 | has part | has developmental contribution from | **has developmental contribution from** | RO_0002254 | sound_with_caveat | agree | vacuous at high levels |
| 66 | develops into | part of | **developmentally contributes to** | RO_0002255 | sound | agree | conclusion weaker than premises |
| 67 | enables | causally upstream of | **acts upstream of** | RO_0002263 | sound | agree | composes cleanly |
| 68 | enables | causally upstream of or within | **acts upstream of or within** | RO_0002264 | sound_with_caveat | agree | or within weakens the claim |
| 69 | part of | directly develops into | **part of developmental precursor of** | RO_0002287 | sound_with_caveat | agree | precursor = lineage, not material |
| 70 | characteristic of | part of | **characteristic of part of** | RO_0002314 | sound | agree | existential, correct |
| 71 | characteristic of part of | part of | **characteristic of part of** | RO_0002314 | sound | agree | nested existentials hold |
| 72 | enables | has part | **enables** | RO_0002327 | wrong | agree | enabling a process does not pass to its parts; holds only when b is a molecular function |
| 73 | enables | has component activity | **enables** | RO_0002327 | suspicious | sound_with_caveat | sound when b is a molecular function; agent instance mistyped |
| 74 | part of | capable of | **part of structure that is capable of** | RO_0002329 | sound_with_caveat | agree | over-credits small parts |
| 75 | enables | part of | **involved in** | RO_0002331 | sound_with_caveat | agree | involved in is broad |
| 76 | involved in | part of | **involved in** | RO_0002331 | sound_with_caveat | agree | ceiling effect on involved in |
| 77 | has target start location | part of | **has target start location** | RO_0002338 | sound_with_caveat | agree | coarsens location |
| 78 | has target end location | part of | **has target end location** | RO_0002339 | sound_with_caveat | agree | coarsens location |
| 79 | located in | inverse(located in) | **spatially coextensive with** | RO_0002379 | wrong | agree | shared container is not coextension (faithful to RO; RO bug) |
| 80 | distributary of | main stem of | **branching part of** | RO_0002380 | sound | agree | holds |
| 81 | starts with | has direct input | **has direct input** | RO_0002400 | sound_with_caveat | agree | cyclic internal inputs counted as external |
| 82 | causally upstream of | obsolete has direct output | **obsolete has indirect output** | RO_0002403 | suspicious | agree | obsolete relations; drop |
| 83 | indirectly positively regulates | directly positively regulates | **indirectly positively regulates** | RO_0002407 | sound | agree | pos then pos is pos |
| 84 | indirectly negatively regulates | indirectly negatively regulates | **indirectly positively regulates** | RO_0002407 | sound_with_caveat | agree | sign right, no magnitude |
| 85 | directly positively regulates | indirectly positively regulates | **indirectly positively regulates** | RO_0002407 | sound | agree | lossy on step count |
| 86 | directly positively regulates | directly positively regulates | **indirectly positively regulates** | RO_0002407 | sound | agree | correct |
| 87 | indirectly negatively regulates | directly negatively regulates | **indirectly negatively regulates** | RO_0002409 | wrong | agree | neg then neg must be pos; contradicts rows 56, 84 (RO-internal) |
| 88 | directly negatively regulates | indirectly negatively regulates | **indirectly negatively regulates** | RO_0002409 | wrong | agree | same sign error |
| 89 | directly negatively regulates | directly negatively regulates | **indirectly negatively regulates** | RO_0002409 | wrong | agree | same sign error |
| 90 | has output | has input | **provides input for** | RO_0002413 | suspicious | agree | needs inverse(has input); vacuous as written in RO |
| 91 | causally upstream of or within | part of | **causally upstream of or within** | RO_0002418 | sound_with_caveat | agree | or within trivial for big wholes |
| 92 | enables | regulates | **involved in regulation of** | RO_0002428 | sound | agree | holds |
| 93 | involved in | regulates | **involved in regulation of** | RO_0002428 | sound_with_caveat | agree | no direction or size |
| 94 | enables | positively regulates | **involved in positive regulation of** | RO_0002429 | sound | agree | sign passes through enabling |
| 95 | involved in | positively regulates | **involved in positive regulation of** | RO_0002429 | suspicious | agree | involvement unsigned; brake looks like driver |
| 96 | enables | negatively regulates | **involved in negative regulation of** | RO_0002430 | sound | agree | holds |
| 97 | involved in | negatively regulates | **involved in negative regulation of** | RO_0002430 | suspicious | agree | as 95 |
| 98 | enables | occurs in | **is active in** | RO_0002432 | sound_with_caveat | agree | empty at big containers |
| 99 | partner in ∘ is symbiosis ∘ inverse(partner in) | (3-chain) | **symbiotically interacts with** | RO_0002440 | sound_with_caveat | agree | reflexive self-links |
| 100 | partner in ∘ is commensalism ∘ inverse(partner in) | (3-chain) | **commensually interacts with** | RO_0002441 | sound_with_caveat | agree | reflexive self-links; label contested |
| 101 | partner in ∘ is mutualism ∘ inverse(partner in) | (3-chain) | **mutualistically interacts with** | RO_0002442 | sound_with_caveat | agree | mutualism is context-dependent |
| 102 | partner in ∘ is parasitism ∘ inverse(partner in) | (3-chain) | **interacts with via parasite-host interaction** | RO_0002443 | sound_with_caveat | agree | vectors labelled hosts |
| 103 | subject participant in ∘ is parasitism ∘ inverse(target participant in) | (3-chain) | **parasite of** | RO_0002444 | sound_with_caveat | agree | direction depends on role annotation |
| 104 | capable of ∘ is kinase activity ∘ has direct input | (3-chain) | **phosphorylates** | RO_0002447 | suspicious | agree | capable of (potential) to actual event |
| 105 | enables ∘ regulates ∘ enabled by | (3-chain) | **directly regulates activity of** | RO_0002448 | wrong | agree | plain regulates cannot yield directly |
| 106 | enables ∘ directly negatively regulates ∘ enabled by | (3-chain) | **directly negatively regulates activity of** | RO_0002449 | sound_with_caveat | agree | weakest-link on directly |
| 107 | enables ∘ directly positively regulates ∘ enabled by | (3-chain) | **directly positively regulates activity of** | RO_0002450 | sound_with_caveat | agree | as 106 |
| 108 | has part | occurs in | **has part that occurs in** | RO_0002479 | sound_with_caveat | agree | existential, weak |
| 109 | capable of ∘ is ubiquitination ∘ has direct input | (3-chain) | **ubiquitinates** | RO_0002480 | sound_with_caveat | suspicious | same modal shift as 104 (E2 enzymes) |
| 110 | existence starts during | part of | **existence starts during** | RO_0002488 | sound_with_caveat | agree | occurrents only |
| 111 | existence starts at end of | part of | **existence starts during** | RO_0002488 | sound_with_caveat | agree | boundary convention |
| 112 | existence ends during | part of | **existence ends during** | RO_0002492 | sound | agree | occurrent parts end inside the whole |
| 113 | existence ends at start of | part of | **existence ends during** | RO_0002492 | sound_with_caveat | agree | boundary convention |
| 114 | part of | existence starts during or after | **existence starts during or after** | RO_0002496 | wrong | agree | continuant parts can predate the whole |
| 115 | developmentally preceded by | existence starts during or after | **existence starts during or after** | RO_0002496 | sound | agree | successor starts after precursor |
| 116 | existence starts during or after | part of | **existence starts during or after** | RO_0002496 | wrong | agree | as 114 |
| 117 | existence starts during or after | preceded by | **existence starts during or after** | RO_0002496 | sound | agree | order preserved |
| 118 | existence starts during or after | simultaneous with | **existence starts during or after** | RO_0002496 | suspicious | sound | RO simultaneous with means same extent |
| 119 | existence starts at end of ∘ preceded by ∘ inverse(existence starts at end of) | (3-chain) | **existence starts during or after** | RO_0002496 | sound | agree | order preserved |
| 120 | part of | existence ends during or before | **existence ends during or before** | RO_0002497 | wrong | agree | continuant parts can outlive the whole |
| 121 | developmentally succeeded by | existence ends during or before | **existence ends during or before** | RO_0002497 | wrong | sound_with_caveat | holds when the precursor is consumed (cell division); a self-renewing precursor population breaks it |
| 122 | existence ends during or before | part of | **existence ends during or before** | RO_0002497 | sound_with_caveat | suspicious | same continuant-part failure as 120 |
| 123 | existence ends during or before | precedes | **existence ends during or before** | RO_0002497 | sound | agree | holds |
| 124 | existence ends during or before | simultaneous with | **existence ends during or before** | RO_0002497 | suspicious | sound | as 118 |
| 125 | existence ends at start of ∘ precedes ∘ inverse(existence ends at start of) | (3-chain) | **existence ends during or before** | RO_0002497 | sound | agree | holds |
| 126 | determined by | part of | **determined by part of** | RO_0002509 | sound_with_caveat | agree | near-vacuous for large wholes |
| 127 | has subsequence | is subsequence of | **overlaps sequence of** | RO_0002526 | sound_with_caveat | agree | shared sequence, not shared position |
| 128 | parasite of | parasite of | **hyperparasite of** | RO_0002553 | sound_with_caveat | agree | label suggests direct attack on grand-host |
| 129 | parasitized by | parasitized by | **hyperparasitized by** | RO_0002554 | sound_with_caveat | agree | as 128 |
| 130 | enables ∘ causally upstream of ∘ has input | (3-chain) | **causally influences** | RO_0002566 | sound_with_caveat | agree | weak for generic inputs |
| 131 | enables ∘ causally upstream of ∘ enabled by | (3-chain) | **causally influences** | RO_0002566 | wrong | sound_with_caveat | RO defines influence via d's activity, which a's activity is upstream of |
| 132 | has output | is small molecule regulator of | **directly regulates** | RO_0002578 | suspicious | sound_with_caveat | this is RO/GO-CAM direct small-molecule regulation by definition |
| 133 | has part | capable of | **has part structure that is capable of** | RO_0002584 | sound | agree | true, weak |
| 134 | capable of | regulates | **capable of regulating** | RO_0002596 | sound_with_caveat | agree | context-bound capability |
| 135 | capable of | negatively regulates | **capable of negatively regulating** | RO_0002597 | sound_with_caveat | agree | sign is context-bound |
| 136 | capable of | positively regulates | **capable of positively regulating** | RO_0002598 | sound_with_caveat | agree | sign is direction, not benefit |
| 137 | has output | is small molecule activator of | **directly positively regulates** | RO_0002629 | suspicious | sound_with_caveat | as 132; site of action may differ |
| 138 | has output | is small molecule inhibitor of | **directly negatively regulates** | RO_0002630 | suspicious | sound_with_caveat | as 132 |
| 139 | inverse(occurs in) | has output | **produces** | RO_0003000 | sound_with_caveat | agree | place of process is not place of making |
| 140 | disease causes disruption of | part of | **disease causes disruption of** | RO_0004024 | sound_with_caveat | agree | redundant parts overclaim |
| 141 | disease causes dysfunction of | capable of | **disease causes disruption of** | RO_0004024 | sound_with_caveat | agree | read as partial |
| 142 | disease causes dysfunction of | part of | **disease causes dysfunction of** | RO_0004025 | suspicious | agree | parthood does not carry dysfunction |
| 143 | realized in response to | has input | **realized in response to stimulus** | RO_0004028 | suspicious | agree | input is not stimulus |
| 144 | enables | has part | **enables subfunction** | RO_0004031 | suspicious | agree | as 72; holds only for molecular functions |
| 145 | enables | causally upstream of or within, positive effect | **acts upstream of or within, positive effect** | RO_0004032 | sound_with_caveat | agree | enabler is permissive; sign from b |
| 146 | enables | causally upstream of or within, negative effect | **acts upstream of or within, negative effect** | RO_0004033 | sound_with_caveat | agree | as 145 |
| 147 | enables | causally upstream of, positive effect | **acts upstream of, positive effect** | RO_0004034 | sound_with_caveat | agree | as 145 |
| 148 | enables | causally upstream of, negative effect | **acts upstream of, negative effect** | RO_0004035 | sound_with_caveat | agree | as 145 |
| 149 | realized in | causally downstream of | **realized in response to** | RO_0009501 | sound_with_caveat | agree | any upstream cause read as stimulus |
| 150 | characteristic of | is concretized as | **generically depends on** | RO_0010001 | suspicious | agree | type mismatch; GDC machinery not in BioLean |
| 151 | concretizes | has characteristic | **is carrier of** | RO_0010002 | sound_with_caveat | agree | characteristic is typical, not necessary |
| 152 | has synaptic IO in region | part of | **has synaptic IO in region** | RO_0013001 | sound | agree | valid lift |
| 153 | receives synaptic input in region | part of | **receives synaptic input in region** | RO_0013002 | sound | agree | valid lift |
| 154 | sends synaptic output to region | part of | **sends synaptic output to region** | RO_0013003 | sound | agree | valid lift; not exclusive |
| 155 | has sensory dendrite in | part of | **has sensory dendrite in** | RO_0013007 | sound | agree | valid lift |
| 156 | synapses restricted to region | part of | **synapses restricted to region** | RO_0013010 | sound | agree | valid; not exclusive |
| 157 | has exemplar data | subcluster of | **has exemplar data** | RO_0015001 | sound_with_caveat | agree | subset exemplar is not superset exemplar |
| 158 | capable of | has input | **device utilizes material** | RO_0017001 | wrong | suspicious | same modal shift as 104; true as class-level potential |
| 159 | capable of ∘ is myristoyltransferase activity ∘ has direct input | (3-chain) | **myristoylates** | RO_0018002 | wrong | suspicious | as 158 |
| 160 | has gene product | enables | **has gene product that enables** | RO_0018042 | sound | agree | existential reading |
| 161 | regulates | regulates characteristic | **regulates characteristic** | RO_0019000 | sound_with_caveat | agree | unsigned; direction lost |
| 162 | positively regulates | positively regulates characteristic | **positively regulates characteristic** | RO_0019001 | sound_with_caveat | agree | fails under homeostatic clamping |
| 163 | negatively regulates | positively regulates characteristic | **negatively regulates characteristic** | RO_0019002 | sound_with_caveat | agree | needs monotone, unclamped link |
| 164 | positively regulates | negatively regulates characteristic | **negatively regulates characteristic** | RO_0019002 | sound_with_caveat | agree | as 163 |

## Transitive

part of, has part, preceded by, precedes, location of, located in, aligned with, simultaneous with, before, encompasses, ends after, starts before, happens during, derived by descent from, has derived by descendant, shares ancestor with, serially homologous to, develops from, develops into, regulates, positively regulates, starts with, ends with, regulated by, indirectly positively regulates, indirectly negatively regulates, causally upstream of, transitively provides input for, causally upstream of or within, causally downstream of or within, transformation of, has start sequence, is start sequence of, has end sequence, is end sequence of, bounds sequence of, is bound by sequence of, has subsequence, is subsequence of, is upstream of sequence of, is downstream of sequence of, has branching part, subcluster of, is deprotonated form of, is protonated form of
