# RO property chains

Generated from http://purl.obolibrary.org/obo/ro/releases/2026-09-04/ro.owl (sha256 9a3190d49564) by `scripts/ro/import_ro.py`. 164 chains.
Reading: if `a r₁ b` and `b r₂ c` then `a r₃ c`. The `check` column is filled by the hand-check in `docs/ro-chain-check.md`.

| # | r₁ | r₂ | ⊑ r₃ | r₃ id |
|---:|---|---|---|---|
| 1 | part of | preceded by | **preceded by** | BFO_0000062 |
| 2 | starts during | preceded by | **preceded by** | BFO_0000062 |
| 3 | happens during | preceded by | **preceded by** | BFO_0000062 |
| 4 | part of | precedes | **precedes** | BFO_0000063 |
| 5 | happens during | precedes | **precedes** | BFO_0000063 |
| 6 | part of | occurs in | **occurs in** | BFO_0000066 |
| 7 | occurs in | part of | **occurs in** | BFO_0000066 |
| 8 | has part ∘ realizes ∘ characteristic of | (3-chain) | **has participant** | RO_0000057 |
| 9 | has part | has participant | **has participant** | RO_0000057 |
| 10 | located in | part of | **located in** | RO_0001025 |
| 11 | innervated by | branching part of | **innervated by** | RO_0002005 |
| 12 | regulates | transports or maintains localization of | **regulates transport of** | RO_0002011 |
| 13 | ends during | preceded by | **ends after** | RO_0002086 |
| 14 | starts with | ends with | **immediately preceded by** | RO_0002087 |
| 15 | starts during | obsolete preceded by | **starts before** | RO_0002089 |
| 16 | ends with | starts with | **immediately precedes** | RO_0002090 |
| 17 | has soma location | part of | **has soma location** | RO_0002100 |
| 18 | is neuron ∘ part of ∘ is anatomical entity | (3-chain) | **has soma location** | RO_0002100 |
| 19 | axon synapses in | part of | **axon synapses in** | RO_0002102 |
| 20 | has postsynaptic terminal in | part of | **has postsynaptic terminal in** | RO_0002110 |
| 21 | has presynaptic terminal in | part of | **has presynaptic terminal in** | RO_0002113 |
| 22 | dendrite synapsed in | part of | **dendrite synapsed in** | RO_0002121 |
| 23 | has synaptic terminal in | part of | **has synaptic terminal in** | RO_0002130 |
| 24 | part of | part of | **overlaps** | RO_0002131 |
| 25 | has part | part of | **overlaps** | RO_0002131 |
| 26 | has part | overlaps | **overlaps** | RO_0002131 |
| 27 | overlaps | part of | **overlaps** | RO_0002131 |
| 28 | innervates | part of | **innervates** | RO_0002134 |
| 29 | derived by descent from | has derived by descendant | **shares ancestor with** | RO_0002158 |
| 30 | innervated by | in taxon | **in taxon** | RO_0002162 |
| 31 | overlaps | in taxon | **in taxon** | RO_0002162 |
| 32 | innervates | in taxon | **in taxon** | RO_0002162 |
| 33 | continuous with | in taxon | **in taxon** | RO_0002162 |
| 34 | connected to | in taxon | **in taxon** | RO_0002162 |
| 35 | connects | in taxon | **in taxon** | RO_0002162 |
| 36 | expressed in | in taxon | **in taxon** | RO_0002162 |
| 37 | regulates | in taxon | **in taxon** | RO_0002162 |
| 38 | has prototype | in taxon | **in taxon** | RO_0002162 |
| 39 | capable of | in taxon | **in taxon** | RO_0002162 |
| 40 | has developmental contribution from | in taxon | **in taxon** | RO_0002162 |
| 41 | developmentally induced by | in taxon | **in taxon** | RO_0002162 |
| 42 | results in developmental progression of | in taxon | **in taxon** | RO_0002162 |
| 43 | has potential to develop into | in taxon | **in taxon** | RO_0002162 |
| 44 | existence overlaps | in taxon | **in taxon** | RO_0002162 |
| 45 | produces | in taxon | **in taxon** | RO_0002162 |
| 46 | produced by | in taxon | **in taxon** | RO_0002162 |
| 47 | inverse(connects) | connects | **connected to** | RO_0002170 |
| 48 | attached to | part of | **attached to part of** | RO_0002177 |
| 49 | ribosomal translation of | transcribed from | **gene product of** | RO_0002204 |
| 50 | transcribed to | ribosomally translates to | **has gene product** | RO_0002205 |
| 51 | expressed in | part of | **expressed in** | RO_0002206 |
| 52 | regulates | has effector activity | **regulates** | RO_0002211 |
| 53 | ends with | regulates | **regulates** | RO_0002211 |
| 54 | directly regulates | directly regulates | **regulates** | RO_0002211 |
| 55 | ends with | negatively regulates | **negatively regulates** | RO_0002212 |
| 56 | negatively regulates | negatively regulates | **positively regulates** | RO_0002213 |
| 57 | ends with | positively regulates | **positively regulates** | RO_0002213 |
| 58 | capable of | part of | **capable of part of** | RO_0002216 |
| 59 | directly develops from | part of | **develops from part of** | RO_0002225 |
| 60 | directly develops from | located in | **develops in** | RO_0002226 |
| 61 | starts with | occurs in | **has start location** | RO_0002231 |
| 62 | ends with | occurs in | **has end location** | RO_0002232 |
| 63 | starts with | has input | **has input** | RO_0002233 |
| 64 | ends with | has output | **has output** | RO_0002234 |
| 65 | has part | has developmental contribution from | **has developmental contribution from** | RO_0002254 |
| 66 | develops into | part of | **developmentally contributes to** | RO_0002255 |
| 67 | enables | causally upstream of | **acts upstream of** | RO_0002263 |
| 68 | enables | causally upstream of or within | **acts upstream of or within** | RO_0002264 |
| 69 | part of | directly develops into | **part of developmental precursor of** | RO_0002287 |
| 70 | characteristic of | part of | **characteristic of part of** | RO_0002314 |
| 71 | characteristic of part of | part of | **characteristic of part of** | RO_0002314 |
| 72 | enables | has part | **enables** | RO_0002327 |
| 73 | enables | has component activity | **enables** | RO_0002327 |
| 74 | part of | capable of | **part of structure that is capable of** | RO_0002329 |
| 75 | enables | part of | **involved in** | RO_0002331 |
| 76 | involved in | part of | **involved in** | RO_0002331 |
| 77 | has target start location | part of | **has target start location** | RO_0002338 |
| 78 | has target end location | part of | **has target end location** | RO_0002339 |
| 79 | located in | inverse(located in) | **spatially coextensive with** | RO_0002379 |
| 80 | distributary of | main stem of | **branching part of** | RO_0002380 |
| 81 | starts with | has direct input | **has direct input** | RO_0002400 |
| 82 | causally upstream of | obsolete has direct output | **obsolete has indirect output** | RO_0002403 |
| 83 | indirectly positively regulates | directly positively regulates | **indirectly positively regulates** | RO_0002407 |
| 84 | indirectly negatively regulates | indirectly negatively regulates | **indirectly positively regulates** | RO_0002407 |
| 85 | directly positively regulates | indirectly positively regulates | **indirectly positively regulates** | RO_0002407 |
| 86 | directly positively regulates | directly positively regulates | **indirectly positively regulates** | RO_0002407 |
| 87 | indirectly negatively regulates | directly negatively regulates | **indirectly negatively regulates** | RO_0002409 |
| 88 | directly negatively regulates | indirectly negatively regulates | **indirectly negatively regulates** | RO_0002409 |
| 89 | directly negatively regulates | directly negatively regulates | **indirectly negatively regulates** | RO_0002409 |
| 90 | has output | has input | **provides input for** | RO_0002413 |
| 91 | causally upstream of or within | part of | **causally upstream of or within** | RO_0002418 |
| 92 | enables | regulates | **involved in regulation of** | RO_0002428 |
| 93 | involved in | regulates | **involved in regulation of** | RO_0002428 |
| 94 | enables | positively regulates | **involved in positive regulation of** | RO_0002429 |
| 95 | involved in | positively regulates | **involved in positive regulation of** | RO_0002429 |
| 96 | enables | negatively regulates | **involved in negative regulation of** | RO_0002430 |
| 97 | involved in | negatively regulates | **involved in negative regulation of** | RO_0002430 |
| 98 | enables | occurs in | **is active in** | RO_0002432 |
| 99 | partner in ∘ is symbiosis ∘ inverse(partner in) | (3-chain) | **symbiotically interacts with** | RO_0002440 |
| 100 | partner in ∘ is commensalism ∘ inverse(partner in) | (3-chain) | **commensually interacts with** | RO_0002441 |
| 101 | partner in ∘ is mutualism ∘ inverse(partner in) | (3-chain) | **mutualistically interacts with** | RO_0002442 |
| 102 | partner in ∘ is parasitism ∘ inverse(partner in) | (3-chain) | **interacts with via parasite-host interaction** | RO_0002443 |
| 103 | subject participant in ∘ is parasitism ∘ inverse(target participant in) | (3-chain) | **parasite of** | RO_0002444 |
| 104 | capable of ∘ is kinase activity ∘ has direct input | (3-chain) | **phosphorylates** | RO_0002447 |
| 105 | enables ∘ regulates ∘ enabled by | (3-chain) | **directly regulates activity of** | RO_0002448 |
| 106 | enables ∘ directly negatively regulates ∘ enabled by | (3-chain) | **directly negatively regulates activity of** | RO_0002449 |
| 107 | enables ∘ directly positively regulates ∘ enabled by | (3-chain) | **directly positively regulates activity of** | RO_0002450 |
| 108 | has part | occurs in | **has part that occurs in** | RO_0002479 |
| 109 | capable of ∘ is ubiquitination ∘ has direct input | (3-chain) | **ubiquitinates** | RO_0002480 |
| 110 | existence starts during | part of | **existence starts during** | RO_0002488 |
| 111 | existence starts at end of | part of | **existence starts during** | RO_0002488 |
| 112 | existence ends during | part of | **existence ends during** | RO_0002492 |
| 113 | existence ends at start of | part of | **existence ends during** | RO_0002492 |
| 114 | part of | existence starts during or after | **existence starts during or after** | RO_0002496 |
| 115 | developmentally preceded by | existence starts during or after | **existence starts during or after** | RO_0002496 |
| 116 | existence starts during or after | part of | **existence starts during or after** | RO_0002496 |
| 117 | existence starts during or after | preceded by | **existence starts during or after** | RO_0002496 |
| 118 | existence starts during or after | simultaneous with | **existence starts during or after** | RO_0002496 |
| 119 | existence starts at end of ∘ preceded by ∘ inverse(existence starts at end of) | (3-chain) | **existence starts during or after** | RO_0002496 |
| 120 | part of | existence ends during or before | **existence ends during or before** | RO_0002497 |
| 121 | developmentally succeeded by | existence ends during or before | **existence ends during or before** | RO_0002497 |
| 122 | existence ends during or before | part of | **existence ends during or before** | RO_0002497 |
| 123 | existence ends during or before | precedes | **existence ends during or before** | RO_0002497 |
| 124 | existence ends during or before | simultaneous with | **existence ends during or before** | RO_0002497 |
| 125 | existence ends at start of ∘ precedes ∘ inverse(existence ends at start of) | (3-chain) | **existence ends during or before** | RO_0002497 |
| 126 | determined by | part of | **determined by part of** | RO_0002509 |
| 127 | has subsequence | is subsequence of | **overlaps sequence of** | RO_0002526 |
| 128 | parasite of | parasite of | **hyperparasite of** | RO_0002553 |
| 129 | parasitized by | parasitized by | **hyperparasitized by** | RO_0002554 |
| 130 | enables ∘ causally upstream of ∘ has input | (3-chain) | **causally influences** | RO_0002566 |
| 131 | enables ∘ causally upstream of ∘ enabled by | (3-chain) | **causally influences** | RO_0002566 |
| 132 | has output | is small molecule regulator of | **directly regulates** | RO_0002578 |
| 133 | has part | capable of | **has part structure that is capable of** | RO_0002584 |
| 134 | capable of | regulates | **capable of regulating** | RO_0002596 |
| 135 | capable of | negatively regulates | **capable of negatively regulating** | RO_0002597 |
| 136 | capable of | positively regulates | **capable of positively regulating** | RO_0002598 |
| 137 | has output | is small molecule activator of | **directly positively regulates** | RO_0002629 |
| 138 | has output | is small molecule inhibitor of | **directly negatively regulates** | RO_0002630 |
| 139 | inverse(occurs in) | has output | **produces** | RO_0003000 |
| 140 | disease causes disruption of | part of | **disease causes disruption of** | RO_0004024 |
| 141 | disease causes dysfunction of | capable of | **disease causes disruption of** | RO_0004024 |
| 142 | disease causes dysfunction of | part of | **disease causes dysfunction of** | RO_0004025 |
| 143 | realized in response to | has input | **realized in response to stimulus** | RO_0004028 |
| 144 | enables | has part | **enables subfunction** | RO_0004031 |
| 145 | enables | causally upstream of or within, positive effect | **acts upstream of or within, positive effect** | RO_0004032 |
| 146 | enables | causally upstream of or within, negative effect | **acts upstream of or within, negative effect** | RO_0004033 |
| 147 | enables | causally upstream of, positive effect | **acts upstream of, positive effect** | RO_0004034 |
| 148 | enables | causally upstream of, negative effect | **acts upstream of, negative effect** | RO_0004035 |
| 149 | realized in | causally downstream of | **realized in response to** | RO_0009501 |
| 150 | characteristic of | is concretized as | **generically depends on** | RO_0010001 |
| 151 | concretizes | has characteristic | **is carrier of** | RO_0010002 |
| 152 | has synaptic IO in region | part of | **has synaptic IO in region** | RO_0013001 |
| 153 | receives synaptic input in region | part of | **receives synaptic input in region** | RO_0013002 |
| 154 | sends synaptic output to region | part of | **sends synaptic output to region** | RO_0013003 |
| 155 | has sensory dendrite in | part of | **has sensory dendrite in** | RO_0013007 |
| 156 | synapses restricted to region | part of | **synapses restricted to region** | RO_0013010 |
| 157 | has exemplar data | subcluster of | **has exemplar data** | RO_0015001 |
| 158 | capable of | has input | **device utilizes material** | RO_0017001 |
| 159 | capable of ∘ is myristoyltransferase activity ∘ has direct input | (3-chain) | **myristoylates** | RO_0018002 |
| 160 | has gene product | enables | **has gene product that enables** | RO_0018042 |
| 161 | regulates | regulates characteristic | **regulates characteristic** | RO_0019000 |
| 162 | positively regulates | positively regulates characteristic | **positively regulates characteristic** | RO_0019001 |
| 163 | negatively regulates | positively regulates characteristic | **negatively regulates characteristic** | RO_0019002 |
| 164 | positively regulates | negatively regulates characteristic | **negatively regulates characteristic** | RO_0019002 |

## Transitive

part of, has part, preceded by, precedes, location of, located in, aligned with, simultaneous with, before, encompasses, ends after, starts before, happens during, derived by descent from, has derived by descendant, shares ancestor with, serially homologous to, develops from, develops into, regulates, positively regulates, starts with, ends with, regulated by, indirectly positively regulates, indirectly negatively regulates, causally upstream of, transitively provides input for, causally upstream of or within, causally downstream of or within, transformation of, has start sequence, is start sequence of, has end sequence, is end sequence of, bounds sequence of, is bound by sequence of, has subsequence, is subsequence of, is upstream of sequence of, is downstream of sequence of, has branching part, subcluster of, is deprotonated form of, is protonated form of
