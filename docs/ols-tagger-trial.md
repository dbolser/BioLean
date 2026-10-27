# OLS text tagger trial

Date: 2026-10-27. Script: `scripts/textbook/ols_compare.py`. Output: `data/textbook/ols_compare.tsv`.

## The service

- EBI OLS4 "Ontologiser" page: https://www.ebi.ac.uk/ols4/ontologiser
- Public REST API (found in the page's JS bundle): `POST https://www.ebi.ac.uk/ols4/api/v2/tag_text`
  with JSON `{"text": "..."}`. Query params: `ontologyId` (repeatable), `source`, `delimiters`,
  `minLength` (UI default 6), `includeSubstrings` (UI default true).
- Returns `entities[]` with `start`, `end`, `term_label`, `term_iri`, `ontology_id`, `string_type`.
- No auth needed. Default (all ontologies) returns 50 to 80 hits per word, so I limited it to the
  same 7 ontologies OAK used (go, uberon, cl, pato, hp, mondo, chebi) with `minLength=3`,
  `includeSubstrings=false`. The UI defaults (substrings on) are why Dan's file has junk like
  `ergy-c` matching "energy".

## Bug report (paste into EBI issue)

`POST /ols4/api/v2/tag_text` returns `start`/`end` as UTF-8 byte offsets, not character offsets, so
any text with multi-byte characters drifts. Input: `The cell’s plasma membrane controls transport.`
(U+2019 right single quote, 3 bytes in UTF-8) with `ontologyId=go&minLength=3&includeSubstrings=false`.
Returned `plasma membrane` at start=13, end=28; in the string it is at characters 11 to 26, so
`text[13:28]` gives `asma membrane c`. The same sentence with an ASCII apostrophe returns start=11,
end=26, which is correct. The offset error grows by 2 for each curly quote or apostrophe (3 bytes
each, 1 character), and by 1 or more for other non-ASCII characters (e.g. en/em dash, Greek letters),
so later matches in a document are shifted further and further. Expected: offsets in characters
(Unicode code points, or UTF-16 units if documented), matching the `text` field echoed in the response;
or document that offsets are bytes.

## Numbers

2803 distinct (text, agent CURIE) pairs from 2656 distinct ASCII-normalised texts. A hit needs the
match to cover at least 90 percent of the text; ranking: longest, then label before synonym, then
ontology order (as in `oak_compare.py`).

| | OLS tagger | OAK |
|---|---|---|
| hit | 1102 | 1485 |
| agree with agent | 917 | 1158 |
| disagree with agent | 164 | 290 |
| tool-only (agent had no CURIE) | 21 | 37 |
| agent-only (tool found nothing) | 1475 | 1108 |
| neither | 226 | 210 |
| agreement when it hits and agent has a CURIE | 84.8% (917/1081) | 80.0% (1158/1448) |

By agent ontology (agree / disagree):

| agent prefix | pairs | OLS | OAK |
|---|---|---|---|
| GO | 1026 | 387 / 47 | 443 / 91 |
| UBERON | 492 | 266 / 36 | 301 / 60 |
| CHEBI | 375 | 135 / 22 | 184 / 38 |
| CL | 126 | 39 / 2 | 54 / 11 |
| PATO | 90 | 40 / 7 | 45 / 8 |
| MONDO | 63 | 22 / 27 | 33 / 19 |
| HP | 45 | 28 / 4 | 27 / 6 |

OLS-only hits by ontology: PATO 7, GO 5, UBERON 4, CHEBI 4, MONDO 1.

OLS vs OAK: both hit on 1096 mentions; same CURIE on 1050 (95.8%). OAK hit and OLS missed: 389
(190 of them end in "s"). OLS hit and OAK missed: 6.

Why OLS misses more:
- Labels only. Synonyms are not matched ("thrombocyte" for platelet gives nothing; "ion channel
  activity" only matches the tail "channel activity" because the GO label is
  "monoatomic ion channel activity"). All 1050 top picks were labels; the other 52 were curation entries.
- No plural or stem handling ("chloroplasts", "mammals", "spindle poles" miss).
- Some terms are simply absent from its index (CHEBI "cellulose", "chemiosmosis" under GO).
- The tagger does lower OLS's disagreement count, but mostly because it returns fewer answers.

## 10 disagreements with the agent

Format: text | agent | OLS | OAK.

1. skin | UBERON:0002097 skin of body | UBERON:0000014 zone of skin | UBERON:0000014
2. skeletal muscle | UBERON:0014892 skeletal muscle organ, vertebrate | UBERON:0001134 skeletal muscle tissue | UBERON:0014895
3. detoxification | GO:1990748 cellular detoxification | GO:0098754 detoxification | GO:0098754
4. muscle | UBERON:0002385 muscle tissue | UBERON:0001630 muscle organ | UBERON:0005090
5. proteins | GO:0005215 transporter activity | CHEBI:36080 protein | CHEBI:36080
6. jejunum | UBERON:0002115 jejunum | UBERON:0000320 duodenal mucosa (bad) | UBERON:0002115
7. celiac disease | MONDO:0005130 celiac disease | HP:0002608 Celiac disease | HP:0002608
8. methionine | CHEBI:16811 methionine | CHEBI:16643 L-methionine | CHEBI:16811
9. phosphate group | CHEBI:26020 phosphate | CHEBI:32958 phosphate group | CHEBI:32958
10. acidic | PATO:0001842 acidity | PATO:0001429 acidic | PATO:0001429

Pattern: most are the agent choosing a looser or different-but-related term; in 3, 5, 9, 10 the
tools' exact-label match looks better than the agent. Item 6 shows an OLS error (wrong term, probably a
synonym on a different term); item 8 shows OLS picking a child (L-methionine).

## Recommendation

Keep OAK as the first-pass grounder: it hits about 35 percent more mentions (1485 vs 1102), handles
synonyms and plurals, and runs offline. Use the OLS tagger only as a cross-check or for ontologies
OAK lacks (it agrees with OAK 96 percent where both hit), and keep the agents for everything neither
tool finds (1100 to 1500 mentions, mostly NCBITaxon, SO, NCIT, PR, PO).
