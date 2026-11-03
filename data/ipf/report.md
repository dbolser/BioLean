
### By model

| model | runs | steps | stated | citations that state their step | links by label | links after grounding | claims with a route | sign differs | mean best belief | established |
|---|---|---|---|---|---|---|---|---|---|---|
| gemini-3.1-pro | 33 | 277 | 267 (96%) | 175/553 (32%) | 132/189 | 104/189 | 93/156 | 5 | 0.08 | 3 |
| deepseek-v3.2 | 17 | 138 | 87 (63%) | 52/183 (28%) | 38/86 | 10/86 | 23/96 | 3 | 0.17 | 0 |
| gpt-5.6-sol | 9 | 106 | 96 (91%) | 86/274 (31%) | 11/73 | 28/73 | 36/59 | 3 | 0.09 | 0 |
| claude-opus-5 | 9 | 146 | 138 (95%) | 161/423 (38%) | 14/107 | 21/107 | 29/64 | 2 | 0.11 | 1 |
| claude-fable-5-1 | 1 | 15 | 14 (93%) | 6/27 (22%) | 6/12 | 4/12 | 3/3 | 3 | 0.00 | 0 |
| kimi-k2 | 1 | 4 | 4 (100%) | 1/4 (25%) | 0/2 | 0/2 | 4/7 | 3 | 0.20 | 1 |

### Citations by source: does the record state the step it is cited for?

| source | citations | kept | why excluded |
|---|---|---|---|
| paper | 461 | 208 (45%) | not_in_text 155, not_this_entity 44, undirected 28, disease_feature 13, parent_disease 5,  |
| GWAS | 257 | 55 (21%) | not_in_text 124, not_this_entity 55, association_only 12, other 8, parent_disease 2, undir |
| UniProt | 226 | 131 (58%) | not_in_text 70, undirected 13, not_this_entity 10, other 2 |
| STRING | 168 | 31 (18%) | enrichment 78, no_direction 35, not_in_text 19, not_this_entity 3, other 2 |
| AGR | 159 | 39 (25%) | not_in_text 68, no_direction 33, not_this_entity 10, other 6, undirected 2, no_text 1 |
| OT | 121 | 27 (22%) | no_direction 34, not_in_text 29, not_this_entity 22, other 9 |
| Reactome | 64 | 0 (0%) | enrichment 64 |
| HPA | 31 | 6 (19%) | no_direction 14, not_in_text 7, not_this_entity 3, other 1 |
| CHEMBL | 26 | 0 (0%) | not_in_text 25, undirected 1 |
| CXG | 26 | 1 (4%) | not_in_text 22, other 1, not_this_entity 1, association_only 1 |
| preprint | 5 | 2 (40%) | undirected 1, association_only 1, not_in_text 1 |
| GO | 3 | 3 (100%) |  |
| PMID | 2 | 1 (50%) | not_in_text 1 |
| NCT00685815 | 1 | 0 (0%) | not_in_text 1 |
| reactome | 1 | 0 (0%) | other 1 |
| NCT07697456 | 1 | 0 (0%) | not_in_text 1 |
| NCT06430801 | 1 | 0 (0%) | not_in_text 1 |

### The run's own confidence against Lean's belief (per claim)

| run said | claims | with a route | mean best belief | established |
|---|---|---|---|---|
| high | 90 | 59 | 0.06 | 0 |
| medium | 75 | 31 | 0.14 | 1 |
| low | 220 | 98 | 0.11 | 4 |

Claims: 385; with a route 188; only through another hypothesis's steps 14; only with a bridge 17; using an association 15; sign differs 19; phenotype targets 69.
Arm verdicts: {'unsupported': 212, 'established': 5, 'contested': 4, 'refuted': 2}
Best belief per routed claim: {'0.0-0.2': 153, '0.2-0.4': 11, '0.4-0.6': 13, '0.6-0.8': 8, '0.8-1.0': 5}
Statements: 735; forms {'effect': 560, 'assoc': 122, 'other': 53}; with no evidence 346; failing the taxon lint 83
Entities: 926; local BLN terms 66; refinements 53; by prefix {'UniProt': 329, 'GO': 270, 'MONDO': 78, 'BLN': 66, 'HP': 43, 'CL': 30, 'MP': 30, 'dbSNP': 30, 'CHEBI': 19, 'UBERON': 13, 'UPHENO': 5, 'PATO': 3}

Unexpressed (steps with no statement) by category:
    62  no_sign
    10  ungroundable
     5  not_causal
     4  other_construct
     1  evidence_does_not_test_step

Distinct effect and association claims: 528; stated in more than one run: 97
  6 runs: ('effect', 'GO:0098883', 'pos', 'disease', 'MONDO:0005090')
  6 runs: ('assoc', 'UniProt:P23468', 'none', 'disease', 'MONDO:0005391')
  6 runs: ('assoc', 'UniProt:O00470', 'none', 'disease', 'MONDO:0005391')
  5 runs: ('effect', 'UniProt:P0C0L4', 'pos', 'process', 'GO:0098883')
  5 runs: ('effect', 'UniProt:Q96PZ7', 'neg', 'process', 'GO:0006958')
  5 runs: ('assoc', 'UniProt:Q96Q07', 'none', 'disease', 'MONDO:0005391')
  4 runs: ('effect', 'GO:0001774', 'pos', 'process', 'GO:0098883')
  4 runs: ('effect', 'UniProt:Q9NZC2', 'pos', 'activity', 'UniProt:P16885')
  4 runs: ('effect', 'UniProt:Q9NZC2', 'neg', 'disease', 'MONDO:0004975')
  4 runs: ('effect', 'UniProt:Q96JQ5', 'neg', 'amount', 'UniProt:Q9NZC2')
  4 runs: ('effect', 'UniProt:Q92835', 'neg', 'activity', 'UniProt:Q13546')
  4 runs: ('effect', 'UniProt:P21399', 'pos', 'process', 'GO:0006879')
  4 runs: ('effect', 'UniProt:P23468', 'pos', 'process', 'GO:0007416')
  4 runs: ('effect', 'UniProt:P55265', 'pos', 'process', 'GO:0006382')
  4 runs: ('effect', 'UniProt:Q96JQ5', 'neg', 'activity', 'UniProt:Q9NZC2')
  3 runs: ('effect', 'GO:0006958', 'pos', 'process', 'GO:0098883')
  3 runs: ('effect', 'UniProt:P49238', 'neg', 'process', 'GO:0001774')
  3 runs: ('effect', 'UniProt:Q96Q07', 'neg', 'phenotype', 'HP:0002360')
  3 runs: ('effect', 'GO:0006382', 'neg', 'process', 'GO:0140888')
  3 runs: ('effect', 'GO:0140888', 'pos', 'disease', 'MONDO:0005083')

Findings by project and category (top 40):
   262  hypothesis-agent  citation_does_not_state_step
   143  hypothesis-agent  chain_not_connected
   143  biolean           no_form_for
   135  biolean           rule_missing
    76  biolean           missing_term
    71  hypothesis-agent  confidence_unjustified
    68  biolean           evidence_weighting
    67  hypothesis-agent  citation_at_no_step
    63  hypothesis-agent  ungrounded_label
    39  biolean           evidence_kind_missing
    37  hypothesis-agent  chain_ends_at_phenotype
    32  hypothesis-agent  contradicting_evidence_ignored
    24  biolean           kind_mismatch
    22  hypothesis-agent  no_citation
    20  hypothesis-agent  citation_states_opposite
    15  hypothesis-agent  sign_flip
    13  hypothesis-agent  genes_unexplained
    13  hypothesis-agent  no_route
    10  hypothesis-agent  no_contradicting_evidence
    10  hypothesis-agent  falsification_inconsistent
     9  hypothesis-agent  citation_at_wrong_step
     9  hypothesis-agent  mechanism_not_in_chain
     8  hypothesis-agent  aspect_mismatch
     8  hypothesis-agent  budget_not_met
     7  hypothesis-agent  compound_label
     7  hypothesis-agent  confidence_consistent
     7  hypothesis-agent  falsification_off_chain
     7  hypothesis-agent  chain_skips_mechanism
     6  hypothesis-agent  gene_not_in_chain
     6  hypothesis-agent  falsification_already_reported
     6  hypothesis-agent  abstention_unverifiable
     6  hypothesis-agent  variant_gene_attribution
     5  hypothesis-agent  wrong_disease
     5  hypothesis-agent  contradicting_citation_supports
     5  hypothesis-agent  gene_unexplained
     5  hypothesis-agent  kind_mismatch
     5  hypothesis-agent  feature_as_cause
     5  both              abstention_unverifiable
     5  hypothesis-agent  polarity_unknown
     5  biolean           term_grain

Audit changes by error:
   169  missed_finding
   155  other
    29  wrong_exclusion
    20  wrong_unexpressed
    17  wrong_grounding
    16  wrong_hypothesis_claim
    14  quote_does_not_state
    10  wrong_sign
     8  v2_upgrade
     6  wrong_evidence_kind
     5  wrong_merge
     2  missed_merge
     1  v2_category
     1  obsolete_in_v2
     1  wrong_claim
