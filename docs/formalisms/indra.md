# INDRA Statements (indra.statements, JSON serialization)

**The formalism.** INDRA represents mechanism as typed *Statements* (`Activation`, `Inhibition`,
`IncreaseAmount`, `DecreaseAmount`, `Conversion`, `Translocation`, `Complex`, `Phosphorylation`, ...,
plus the event-based `Influence` and `Association`). One annotation unit is one Statement: a statement type
plus its Agent slots (`subj`/`obj`, `members`, `agent`, `obj_from`/`obj_to`). Each Agent carries `name` and
`db_refs` (INDRA namespaces: `CHEBI`, `UP`, `HGNC`, `FPLX`, `GO`, `MESH`, `TAXONOMY`, `UBERON`, `CL`, `HP`,
`MONDO`, `TEXT`), optionally `mods`, `activity`, `bound_conditions` and a GO-cellular-component `location`
string. A Statement holds a list of `Evidence` objects, and **all context lives on Evidence, not on the
Statement**: `pmid`, `text`, `epistemics` (`direct`, `hypothesis`, `negated`, `curated`), free-form
`annotations`, and `context` = `BioContext` with exactly six `RefContext` slots (`species`, `cell_line`,
`cell_type`, `organ`, `disease`, `location`). `belief` is a Statement-level float computed by INDRA's belief
engine from the pooled evidence (shown here as the placeholder `null`). Two statements with the same type and
agents hash to the same `matches_key`, so evidence from different papers pools onto one Statement. That
pooling is the only real mechanism INDRA has for "paper B bears on paper A's claim".

Conventions used below:
- JSON is what `Statement.to_json()` emits, trimmed of `id`/`matches_hash` and with `belief: null`.
- `source_api: "biolean_manual"` marks hand curation. `annotations.provenance: "summary"` marks papers whose
  text is a secondary-source summary.
- Every ID was checked against OLS4 (CHEBI, GO, MESH, NCBITaxon, UBERON, CL, HP, MONDO, EFO), UniProt REST
  (UP) or HGNC REST, or against FamPlex `entities.csv` (FPLX), on 2026-10-26. Anything I could not check is
  marked `?:unverified`. GO:0005753 ("mitochondrial proton-transporting ATP synthase complex") and
  GO:0005746 ("respirasome") are now obsolete, so I used FPLX:ATP_synthase / GO:0045259 and FPLX ETC
  complexes in their place.
- **Bends.** INDRA Agents are meant for molecular entities. To state chemiosmosis at all I had to make
  (i) the *proton gradient* an Agent, grounded to `MESH:D018892` "Proton-Motive Force", which is a physical
  state, not a thing that can be "activated", (ii) *ATP synthesis* either a `Conversion` (ADP + Pi -> ATP,
  catalysed by FPLX:ATP_synthase) or a process-Agent grounded to `GO:0015986`, and (iii) *electron
  transport* a process-Agent grounded to `GO:0022904`. Phenotypes in the NMN papers are also process or
  disease Agents grounded to MESH/GO/HP. INDRA's readers emit these too, but they are bends.

---

## 1. Mitchell 1961, Nature: chemiosmotic hypothesis (PMID 13771349, provenance: summary)

All units carry `epistemics.hypothesis: true`. The paper names no species, so `context.species` is left
empty. `location` is the only BioContext slot that fits.

```json
[
{"type": "IncreaseAmount",
 "subj": {"name": "respiratory electron transport chain", "db_refs": {"GO": "GO:0022904", "TEXT": "electron transfer"},
          "location": "mitochondrial inner membrane"},
 "obj":  {"name": "proton gradient", "db_refs": {"MESH": "D018892", "TEXT": "electrochemical proton gradient"}},
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "13771349",
   "text": "the respiratory chain is arranged anisotropically in the membrane so that electron transfer translocates protons across it, generating an electrochemical proton gradient",
   "epistemics": {"direct": true, "hypothesis": true, "negated": false, "curated": true},
   "annotations": {"provenance": "summary", "claim_role": "hypothesis", "hypothesis_id": "chemiosmotic"},
   "context": {"type": "bio", "location": {"name": "mitochondrial inner membrane", "db_refs": {"GO": "GO:0005743"}}}}]},

{"type": "Translocation",
 "agent": {"name": "hydron", "db_refs": {"CHEBI": "CHEBI:15378", "TEXT": "H+"}},
 "from_location": "mitochondrial matrix", "to_location": "mitochondrial intermembrane space",
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "13771349",
   "text": "electron transfer translocates protons across [the membrane]",
   "epistemics": {"direct": true, "hypothesis": true, "negated": false, "curated": true},
   "annotations": {"provenance": "summary", "claim_role": "hypothesis", "hypothesis_id": "chemiosmotic",
                   "driver": "GO:0022904 (Translocation has no subj slot; driver stored here only)"}}]},

{"type": "Activation",
 "subj": {"name": "proton gradient", "db_refs": {"MESH": "D018892"}},
 "obj":  {"name": "ATP synthase", "db_refs": {"FPLX": "ATP_synthase", "GO": "GO:0045259", "TEXT": "reversible anisotropic membrane ATPase"}},
 "obj_activity": "catalytic",
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "13771349",
   "text": "a reversible, anisotropic membrane ATPase uses that gradient to synthesise ATP",
   "epistemics": {"direct": true, "hypothesis": true, "negated": false, "curated": true},
   "annotations": {"provenance": "summary", "claim_role": "hypothesis", "hypothesis_id": "chemiosmotic"},
   "context": {"type": "bio", "location": {"name": "mitochondrial inner membrane", "db_refs": {"GO": "GO:0005743"}}}}]},

{"type": "Conversion",
 "subj": {"name": "ATP synthase", "db_refs": {"FPLX": "ATP_synthase"},
          "activity": {"activity_type": "catalytic", "is_active": true}},
 "obj_from": [{"name": "ADP(3-)", "db_refs": {"CHEBI": "CHEBI:456216"}},
              {"name": "hydrogenphosphate", "db_refs": {"CHEBI": "CHEBI:43474", "TEXT": "phosphate"}}],
 "obj_to":   [{"name": "ATP(4-)", "db_refs": {"CHEBI": "CHEBI:30616"}}],
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "13771349",
   "text": "...to synthesise ATP from ADP and phosphate",
   "epistemics": {"direct": true, "hypothesis": true, "negated": false, "curated": true},
   "annotations": {"provenance": "summary", "claim_role": "hypothesis", "hypothesis_id": "chemiosmotic"}}]},

{"type": "Activation",
 "subj": {"name": "Uncoupling Agents", "db_refs": {"MESH": "D014475", "TEXT": "uncouplers"}},
 "obj":  {"name": "proton transmembrane transport", "db_refs": {"GO": "GO:1902600", "TEXT": "proton permeability of the coupling membrane"}},
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "13771349",
   "text": "uncouplers act by making [the membrane] proton-permeable",
   "epistemics": {"direct": true, "hypothesis": true, "negated": false, "curated": true},
   "annotations": {"provenance": "summary", "claim_role": "prediction", "hypothesis_id": "chemiosmotic"}}]},

{"type": "DecreaseAmount",
 "subj": {"name": "Uncoupling Agents", "db_refs": {"MESH": "D014475"}},
 "obj":  {"name": "proton gradient", "db_refs": {"MESH": "D018892"}},
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "13771349",
   "text": "uncouplers act by making it proton-permeable",
   "epistemics": {"direct": true, "hypothesis": true, "negated": false, "curated": true},
   "annotations": {"provenance": "summary", "claim_role": "prediction", "hypothesis_id": "chemiosmotic"}}]},

{"type": "Activation",
 "subj": {"name": "respiratory electron transport chain", "db_refs": {"GO": "GO:0022904"}},
 "obj":  {"name": "C~I", "db_refs": {"TEXT": "chemical high-energy intermediate"}},
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "13771349",
   "text": "coupled to electron transfer not by a chemical high-energy intermediate",
   "epistemics": {"direct": true, "hypothesis": true, "negated": true, "curated": true},
   "annotations": {"provenance": "summary", "claim_role": "hypothesis (rejection of rival)", "hypothesis_id": "chemiosmotic",
                   "rival_of": "chemical_intermediate"}}]}
]
```

Note: the last unit has the same agents and type as Slater's main claim (section 2), so INDRA pools this
`negated: true` evidence onto Slater's Statement. That is how the rivalry shows up.

**Could not express:**
- That this is one *theory* with parts. INDRA has no "hypothesis" container; the six units are tied together only by a free-text annotation (`hypothesis_id`).
- That the membrane must be ion-impermeable (a required *property*, not a regulation). There is no Statement type for "X must have property P".
- The causal driver of the `Translocation`. It has no `subj` slot, so "electron transfer moves protons" splits into two units joined by nothing.
- Vectorial/anisotropic arrangement and the electrochemical (charge + pH) nature of the gradient.
- Photosynthetic phosphorylation as a parallel case. I would have to copy every unit with chloroplast locations.
- "Prediction" vs "hypothesis". `epistemics` has only a boolean `hypothesis`, so the difference sits in an annotation.

---

## 2. Slater 1953, Nature: chemical-intermediate hypothesis (PMID 13111237, provenance: summary)

The hypothetical intermediate `C~I` has no identifier in any ontology, and in INDRA's own terms it is an
"ungrounded" Agent (db_refs = TEXT only). INDRA's grounding filters (`filter_grounded_only`) would drop
every Slater statement. So the formalism's default pipeline would delete the losing side of the controversy.

```json
[
{"type": "Activation",
 "subj": {"name": "respiratory electron transport chain", "db_refs": {"GO": "GO:0022904", "TEXT": "electron transfer in the respiratory chain"}},
 "obj":  {"name": "C~I", "db_refs": {"TEXT": "C~I"}},
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "13111237",
   "text": "energy from electron transfer in the respiratory chain is conserved in a non-phosphorylated high-energy chemical intermediate (C~I)",
   "epistemics": {"direct": true, "hypothesis": true, "negated": false, "curated": true},
   "annotations": {"provenance": "summary", "claim_role": "hypothesis", "hypothesis_id": "chemical_intermediate",
                   "rival_of": "chemiosmotic", "argument": "analogy with glycolytic substrate-level phosphorylation"},
   "context": {"type": "bio", "location": {"name": "mitochondrion", "db_refs": {"GO": "GO:0005739"}}}}]},

{"type": "Complex",
 "members": [{"name": "respiratory chain carrier", "db_refs": {"GO": "GO:0098803", "TEXT": "carrier C"}},
             {"name": "I", "db_refs": {"TEXT": "hypothetical compound I"}}],
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "13111237",
   "text": "a high-energy chemical intermediate formed between a carrier and a hypothetical compound",
   "epistemics": {"direct": true, "hypothesis": true, "negated": false, "curated": true},
   "annotations": {"provenance": "summary", "claim_role": "hypothesis", "hypothesis_id": "chemical_intermediate",
                   "bond": "high-energy (~), not representable"}}]},

{"type": "Conversion",
 "subj": {"name": "C~I", "db_refs": {"TEXT": "C~I"}},
 "obj_from": [{"name": "ADP(3-)", "db_refs": {"CHEBI": "CHEBI:456216"}},
              {"name": "hydrogenphosphate", "db_refs": {"CHEBI": "CHEBI:43474"}}],
 "obj_to":   [{"name": "ATP(4-)", "db_refs": {"CHEBI": "CHEBI:30616"}}],
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "13111237",
   "text": "[C~I] then reacts with inorganic phosphate and ADP to yield ATP",
   "epistemics": {"direct": true, "hypothesis": true, "negated": false, "curated": true},
   "annotations": {"provenance": "summary", "claim_role": "hypothesis", "hypothesis_id": "chemical_intermediate",
                   "bend": "C~I is a reactant consumed into C + I, but Conversion only allows it as catalyst-like subj"}}]},

{"type": "Activation",
 "subj": {"name": "C~I", "db_refs": {"TEXT": "C~I"}},
 "obj":  {"name": "ATP biosynthetic process", "db_refs": {"GO": "GO:0006754"}},
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "13111237",
   "text": "high-energy intermediate ... yields ATP",
   "epistemics": {"direct": true, "hypothesis": true, "negated": false, "curated": true},
   "annotations": {"provenance": "summary", "claim_role": "hypothesis", "hypothesis_id": "chemical_intermediate"}}]}
]
```

**Could not express:**
- That Slater and Mitchell are *rival* explanations of the same phenomenon (oxidative phosphorylation). INDRA has no "competes with" or "alternative to" relation. `Statement.contradicts()` only flags opposite polarity on the *same* agents (e.g. Activation vs Inhibition of A->B). Slater's chain (ETC -> C~I -> ATP) and Mitchell's chain (ETC -> gradient -> ATP synthase -> ATP) share no edge, so INDRA sees no conflict.
- The high-energy bond `~` and the mechanism where it splits. INDRA `mods` cover only protein PTMs, not small-molecule energy states.
- C~I is hypothetical and has no grounding. In INDRA, "ungrounded" means "reader failure", not "a postulated entity".
- The argument by analogy (glycolysis). It lives only in a free-text annotation.

---

## 3. Jagendorf & Uribe 1966, PNAS: acid-bath ATP synthesis (PMID 5220864, provenance: summary)

These are experimental results (`hypothesis: false`). The first unit has the *same type and agents* as
Mitchell 1961's `Activation(proton gradient -> ATP synthase)`, so its evidence pools onto that Statement.
This is support by pooling. The last unit is negated evidence against Slater.

```json
[
{"type": "Activation",
 "subj": {"name": "proton gradient", "db_refs": {"MESH": "D018892", "TEXT": "transmembrane pH gradient"}},
 "obj":  {"name": "ATP synthase", "db_refs": {"FPLX": "ATP_synthase", "GO": "GO:0045259"}},
 "obj_activity": "catalytic",
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "5220864",
   "text": "a transmembrane pH gradient alone can drive ATP formation, as predicted by the chemiosmotic hypothesis",
   "epistemics": {"direct": true, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"provenance": "summary", "claim_role": "experimental result", "supports": "chemiosmotic",
                   "assay": "in vitro, isolated thylakoids, dark", "evidence_code": "ECO:0000181",
                   "condition": {"pH_inside_initial": 4, "pH_outside_after_jump": 8, "buffer": "succinate (CHEBI:15741)", "light": "dark"}},
   "context": {"type": "bio",
     "species":  {"name": "Spinacia oleracea", "db_refs": {"TAXONOMY": "3562"}},
     "organ":    {"name": "leaf", "db_refs": {"PO": "PO:0025034"}},
     "location": {"name": "thylakoid membrane", "db_refs": {"GO": "GO:0042651"}}}}]},

{"type": "Conversion",
 "subj": {"name": "ATP synthase", "db_refs": {"FPLX": "ATP_synthase"},
          "activity": {"activity_type": "catalytic", "is_active": true}},
 "obj_from": [{"name": "ADP(3-)", "db_refs": {"CHEBI": "CHEBI:456216"}},
              {"name": "hydrogenphosphate", "db_refs": {"CHEBI": "CHEBI:43474"}}],
 "obj_to":   [{"name": "ATP(4-)", "db_refs": {"CHEBI": "CHEBI:30616"}}],
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "5220864",
   "text": "ATP was synthesised in the dark ... in the presence of ADP and inorganic phosphate",
   "epistemics": {"direct": true, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"provenance": "summary", "claim_role": "experimental result", "assay": "in vitro"},
   "context": {"type": "bio",
     "species":  {"name": "Spinacia oleracea", "db_refs": {"TAXONOMY": "3562"}},
     "location": {"name": "thylakoid membrane", "db_refs": {"GO": "GO:0042651"}}}}]},

{"type": "IncreaseAmount",
 "subj": {"name": "proton gradient", "db_refs": {"MESH": "D018892", "TEXT": "size of the pH jump"}},
 "obj":  {"name": "ATP(4-)", "db_refs": {"CHEBI": "CHEBI:30616"}},
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "5220864",
   "text": "with yield depending on the size of the pH jump and on the permeant acid used",
   "epistemics": {"direct": true, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"provenance": "summary", "claim_role": "experimental result (dose-response)",
                   "modifier": "permeant acid identity changes yield"},
   "context": {"type": "bio", "species": {"name": "Spinacia oleracea", "db_refs": {"TAXONOMY": "3562"}},
               "location": {"name": "thylakoid membrane", "db_refs": {"GO": "GO:0042651"}}}}]},

{"type": "Activation",
 "subj": {"name": "C~I", "db_refs": {"TEXT": "C~I"}},
 "obj":  {"name": "ATP biosynthetic process", "db_refs": {"GO": "GO:0006754"}},
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "5220864",
   "text": "ATP synthesised in the dark with no electron transfer: a pH gradient alone suffices",
   "epistemics": {"direct": false, "hypothesis": false, "negated": true, "curated": true},
   "annotations": {"provenance": "summary", "claim_role": "evidence against (by sufficiency)", "against": "chemical_intermediate",
                   "bend": "the result shows C~I is not REQUIRED; 'negated' over-claims that C~I does not act"}}]}
]
```

**Could not express:**
- The *experimental design* (pH jump from 4 to 8, dark, ADP + Pi added after the jump). The order of steps matters and only fits in a free-text annotation.
- A dose-response curve (ATP yield vs. size of the pH jump) as numbers. INDRA has no quantitative slot on `IncreaseAmount`.
- "Sufficiency" ("gradient *alone* drives ATP synthesis"). INDRA's polarity is only up/down, with no necessary/sufficient distinction. So "against Slater" has to be a blunt `negated`.
- In vitro vs. in vivo. BioContext has no slot; ECO goes in annotations.
- A plant organ: INDRA's `organ` normalisation expects UBERON. PO is not in INDRA's namespace list, so the grounding would be dropped or flagged.

---

## 4. Mitchell & Moyle 1967, Biochem J: respiration-driven proton translocation (PMID 16742541, provenance: abstract)

Shared context object `CTX_RLM` (written out once here; in real JSON it is repeated on each Evidence):

```json
{"type": "bio",
 "species":  {"name": "Rattus norvegicus", "db_refs": {"TAXONOMY": "10116"}},
 "organ":    {"name": "liver", "db_refs": {"UBERON": "UBERON:0002107", "MESH": "D008930"}},
 "location": {"name": "mitochondrial inner membrane", "db_refs": {"GO": "GO:0005743", "TEXT": "M phase of the cristae membrane"}}}
```

```json
[
{"type": "Translocation",
 "agent": {"name": "hydron", "db_refs": {"CHEBI": "CHEBI:15378", "TEXT": "H+ (or OH-)"}},
 "from_location": "mitochondrial matrix", "to_location": "extracellular region",
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "16742541",
   "text": "Pulses of acidity of the outer aqueous phase ... induced by pulses of respiration are due to the translocation of H(+) (or OH(-)) ions across the osmotic barrier (M phase) of the cristae membrane",
   "epistemics": {"direct": true, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"claim_role": "experimental result", "supports": "chemiosmotic", "assay": "in vitro, isolated mitochondria, oxygen-pulse",
                   "to_location_bend": "'outer aqueous phase' of a suspension; nearest GO CC is extracellular region",
                   "driver": "respiration (Translocation has no subj)"},
   "context": "CTX_RLM"}]},

{"type": "IncreaseAmount",
 "subj": {"name": "respiratory electron transport chain", "db_refs": {"GO": "GO:0022904", "TEXT": "succinate-oxidizing span"}},
 "obj":  {"name": "proton gradient", "db_refs": {"MESH": "D018892"}},
 "belief": null,
 "evidence": [
  {"source_api": "biolean_manual", "pmid": "16742541",
   "text": "protons translocated per bivalent reducing equivalent passing through the succinate-oxidizing ... span[] ... very close to 4",
   "epistemics": {"direct": true, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"claim_role": "experimental result", "substrate": "CHEBI:30031", "H_per_2e": 4,
                   "valid_range": {"pH_min": 5.5, "pH_max": 8.5}, "independent_of": "ionic composition of medium"},
   "context": "CTX_RLM"},
  {"source_api": "biolean_manual", "pmid": "16742541",
   "text": "... and beta-hydroxybutyrate-oxidizing spans ... very close to ... 6",
   "epistemics": {"direct": true, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"claim_role": "experimental result", "substrate": "CHEBI:10983", "H_per_2e": 6,
                   "valid_range": {"pH_min": 5.5, "pH_max": 8.5}},
   "context": "CTX_RLM"}]},

{"type": "Activation",
 "subj": {"name": "2,4-dinitrophenol", "db_refs": {"CHEBI": "CHEBI:42017"}},
 "obj":  {"name": "proton transmembrane transport", "db_refs": {"GO": "GO:1902600", "TEXT": "effective proton conductance of the M phase"}},
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "16742541",
   "text": "The uncoupling agents, 2,4-dinitrophenol, carbonyl cyanide p-trifluoromethoxyphenylhydrazone and gramicidin increase the effective proton conductance of the M phase",
   "epistemics": {"direct": true, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"claim_role": "experimental result", "confirms_prediction_of": "13771349",
                   "quantitative": "accounts quantitatively for their uncoupling action"},
   "context": "CTX_RLM"}]},
{"type": "Activation",
 "subj": {"name": "carbonyl cyanide p-trifluoromethoxyphenylhydrazone", "db_refs": {"CHEBI": "CHEBI:75458", "TEXT": "FCCP"}},
 "obj":  {"name": "proton transmembrane transport", "db_refs": {"GO": "GO:1902600"}},
 "belief": null, "evidence": [{"pmid": "16742541", "...": "as above"}]},
{"type": "Activation",
 "subj": {"name": "gramicidin", "db_refs": {"CHEBI": "CHEBI:749506"}},
 "obj":  {"name": "proton transmembrane transport", "db_refs": {"GO": "GO:1902600"}},
 "belief": null, "evidence": [{"pmid": "16742541", "...": "as above"}]},

{"type": "DecreaseAmount",
 "subj": {"name": "2,4-dinitrophenol", "db_refs": {"CHEBI": "CHEBI:42017"}},
 "obj":  {"name": "proton gradient", "db_refs": {"MESH": "D018892", "TEXT": "respiration-driven acid pulses"}},
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "16742541",
   "text": "...and thus increase the rate of decay of the respiration-driven acid pulses",
   "epistemics": {"direct": true, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"claim_role": "experimental result", "also_for": ["CHEBI:75458", "CHEBI:749506"], "measured": "decay rate, not amount"},
   "context": "CTX_RLM"}]},

{"type": "DecreaseAmount",
 "subj": {"name": "Uncoupling Agents", "db_refs": {"MESH": "D014475"}},
 "obj":  {"name": "H+/O quotient", "db_refs": {"TEXT": "initial -->H+/O quotient"}},
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "16742541",
   "text": "...but do not change the initial -->H(+)/O quotients",
   "epistemics": {"direct": true, "hypothesis": false, "negated": true, "curated": true},
   "annotations": {"claim_role": "negative result", "against": "chemical_intermediate"},
   "context": "CTX_RLM"}]},

{"type": "Activation",
 "subj": {"name": "respiratory electron transport chain", "db_refs": {"GO": "GO:0022904"}},
 "obj":  {"name": "C~I", "db_refs": {"TEXT": "C~I"}},
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "16742541",
   "text": "...cannot be attributed to the formation (with acid production) of a chemical intermediate ... uncoupler-sensitive chemical intermediates do not exist between the respiratory-chain system and the effective proton-translocating mechanism",
   "epistemics": {"direct": true, "hypothesis": false, "negated": true, "curated": true},
   "annotations": {"claim_role": "evidence against", "against": "chemical_intermediate"},
   "context": "CTX_RLM"}]}
]
```

**Could not express:**
- The stoichiometry (H+/2e- = 4 and 6) as part of the claim. It is only a free-form annotation. Worse, both spans pool onto one `IncreaseAmount(ETC -> gradient)` Statement, so the per-span difference survives only inside Evidence.
- The pH range (5.5 to 8.5) and the conditions under which the quotient is valid.
- Points 3 and 4 of the abstract: *apparent* changes are measurement artefacts (missing backlash, anion- and Na+-driven decay). INDRA has no way to say "this observed effect is an artefact of method M".
- The "loop 3" configuration (point 6). There is no slot for topology or a redox-loop model.
- The class link "DNP is an uncoupler". INDRA's hierarchy does not relate CHEBI:42017 to MESH:D014475, so this evidence does not pool with Mitchell 1961's uncoupler prediction.
- Measuring a *rate* of decay vs. an amount. Both become `DecreaseAmount`.

---

## 5. Hinkle & Horstman 1971, JBC: proton transport in submitochondrial particles (PMID 4330063, provenance: summary)

Shared context `CTX_SMP`:

```json
{"type": "bio",
 "species":   {"name": "Bos taurus", "db_refs": {"TAXONOMY": "9913"}},
 "organ":     {"name": "heart", "db_refs": {"UBERON": "UBERON:0000948"}},
 "cell_line": {"name": "Submitochondrial Particles", "db_refs": {"MESH": "D013367"}},
 "location":  {"name": "mitochondrial inner membrane", "db_refs": {"GO": "GO:0005743"}}}
```
(`cell_line` is a bend: it is the only slot for "what preparation was used". INDRA expects a CCLE or EFO
cell line there.)

```json
[
{"type": "Translocation",
 "agent": {"name": "hydron", "db_refs": {"CHEBI": "CHEBI:15378"}},
 "from_location": "mitochondrial matrix", "to_location": "mitochondrial intermembrane space",
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "4330063",
   "text": "Submitochondrial particles ... which are inside-out relative to intact mitochondria, take up protons during respiration ... acidifying the vesicle interior",
   "epistemics": {"direct": true, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"provenance": "summary", "claim_role": "experimental result", "supports": "chemiosmotic",
                   "topology": "inside-out vesicle: 'uptake into lumen' == matrix -> intermembrane side; observed direction is opposite to intact mitochondria",
                   "assay": "in vitro"},
   "context": "CTX_SMP"}]},

{"type": "IncreaseAmount",
 "subj": {"name": "respiratory electron transport chain", "db_refs": {"GO": "GO:0022904"}},
 "obj":  {"name": "proton gradient", "db_refs": {"MESH": "D018892"}},
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "4330063",
   "text": "take up protons during respiration (NADH or succinate oxidation)",
   "epistemics": {"direct": true, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"provenance": "summary", "claim_role": "experimental result",
                   "substrates": ["CHEBI:16908", "CHEBI:30031"]},
   "context": "CTX_SMP"}]},

{"type": "DecreaseAmount",
 "subj": {"name": "Uncoupling Agents", "db_refs": {"MESH": "D014475"}},
 "obj":  {"name": "proton gradient", "db_refs": {"MESH": "D018892"}},
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "4330063",
   "text": "the uptake is abolished by uncouplers",
   "epistemics": {"direct": true, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"provenance": "summary", "claim_role": "experimental result", "confirms_prediction_of": "13771349",
                   "magnitude": "abolished"},
   "context": "CTX_SMP"}]},

{"type": "Activation",
 "subj": {"name": "proton gradient", "db_refs": {"MESH": "D018892"}},
 "obj":  {"name": "ATP synthase", "db_refs": {"FPLX": "ATP_synthase", "GO": "GO:0045259"}},
 "obj_activity": "catalytic",
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "4330063",
   "text": "Together with later work from the same lab showing ATP synthesis driven by an artificially imposed pH gradient, this supports respiration-driven proton translocation as the energy-conserving step",
   "epistemics": {"direct": false, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"provenance": "summary", "claim_role": "interpretation; key data from a later paper, PMID not given"},
   "context": "CTX_SMP"}]}
]
```

**Could not express:**
- Membrane *sidedness*. "Inside-out" flips the meaning of "uptake". INDRA locations are plain GO CC strings, with no orientation of a vesicle relative to its source organelle.
- "Abolished" as a magnitude (complete vs. partial). INDRA polarity has no size.
- "Supports X as the energy-conserving step". This is a claim *about* the mechanism, a meta-level relation INDRA cannot hold.
- A pointer to the later paper. Evidence holds one `pmid`, and there is no "see also" for evidence.

---

## 6. Racker & Stoeckenius 1974, JBC: bacteriorhodopsin + ATPase vesicles (PMID 4272126, provenance: summary)

Shared context `CTX_RECON`. There is **one** `species` slot, but the system is a chimera of two organisms.
I put the archaeon in `species` and the bovine source in an annotation. Either choice is wrong.

```json
{"type": "bio",
 "species":   {"name": "Halobacterium salinarum", "db_refs": {"TAXONOMY": "2242", "TEXT": "Halobacterium halobium"}},
 "cell_line": {"name": "Liposomes", "db_refs": {"MESH": "D008081", "TEXT": "reconstituted phospholipid vesicles"}},
 "location":  {"name": "membrane", "db_refs": {"GO": "GO:0016020", "TEXT": "artificial vesicle membrane"}}}
```

```json
[
{"type": "Activation",
 "subj": {"name": "Light", "db_refs": {"MESH": "D008027"}},
 "obj":  {"name": "bop", "db_refs": {"UP": "P02945", "MESH": "D001436", "TEXT": "bacteriorhodopsin"}},
 "obj_activity": "transport",
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "4272126",
   "text": "On illumination the vesicles took up protons",
   "epistemics": {"direct": true, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"provenance": "summary", "claim_role": "experimental result", "assay": "in vitro reconstitution", "evidence_code": "ECO:0000003"},
   "context": "CTX_RECON"}]},

{"type": "IncreaseAmount",
 "subj": {"name": "bop", "db_refs": {"UP": "P02945"}, "activity": {"activity_type": "transport", "is_active": true}},
 "obj":  {"name": "proton gradient", "db_refs": {"MESH": "D018892"}},
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "4272126",
   "text": "the light-driven proton pump ... vesicles took up protons",
   "epistemics": {"direct": true, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"provenance": "summary", "claim_role": "experimental result", "assay": "in vitro reconstitution"},
   "context": "CTX_RECON"}]},

{"type": "Activation",
 "subj": {"name": "proton gradient", "db_refs": {"MESH": "D018892"}},
 "obj":  {"name": "ATP synthase", "db_refs": {"FPLX": "ATP_synthase", "GO": "GO:0045259", "MESH": "D025261", "TEXT": "oligomycin-sensitive ATPase"}},
 "obj_activity": "catalytic",
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "4272126",
   "text": "a proton gradient is sufficient to drive ATP synthesis",
   "epistemics": {"direct": true, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"provenance": "summary", "claim_role": "experimental result (sufficiency)", "supports": "chemiosmotic",
                   "obj_species": {"name": "Bos taurus", "TAXONOMY": "9913", "organ": "UBERON:0000948"},
                   "assay": "in vitro reconstitution", "evidence_code": "ECO:0000003"},
   "context": "CTX_RECON"}]},

{"type": "Conversion",
 "subj": {"name": "ATP synthase", "db_refs": {"FPLX": "ATP_synthase"}, "activity": {"activity_type": "catalytic", "is_active": true}},
 "obj_from": [{"name": "ADP(3-)", "db_refs": {"CHEBI": "CHEBI:456216"}},
              {"name": "hydrogenphosphate", "db_refs": {"CHEBI": "CHEBI:43474"}}],
 "obj_to":   [{"name": "ATP(4-)", "db_refs": {"CHEBI": "CHEBI:30616"}}],
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "4272126",
   "text": "synthesised ATP from ADP and phosphate",
   "epistemics": {"direct": true, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"provenance": "summary", "claim_role": "experimental result", "required_input": "light (MESH:D008027)"},
   "context": "CTX_RECON"}]},

{"type": "Inhibition",
 "subj": {"name": "oligomycin", "db_refs": {"CHEBI": "CHEBI:25675"}},
 "obj":  {"name": "ATP synthase", "db_refs": {"FPLX": "ATP_synthase"}},
 "obj_activity": "catalytic",
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "4272126",
   "text": "ATP synthesis was abolished ... by oligomycin",
   "epistemics": {"direct": true, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"provenance": "summary", "claim_role": "control", "magnitude": "abolished"},
   "context": "CTX_RECON"}]},

{"type": "DecreaseAmount",
 "subj": {"name": "Uncoupling Agents", "db_refs": {"MESH": "D014475"}},
 "obj":  {"name": "proton gradient", "db_refs": {"MESH": "D018892"}},
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "4272126",
   "text": "ATP synthesis was abolished by uncouplers",
   "epistemics": {"direct": false, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"provenance": "summary", "claim_role": "control",
                   "bend": "observed readout was ATP synthesis, not the gradient; gradient collapse is inferred"},
   "context": "CTX_RECON"}]},

{"type": "Activation",
 "subj": {"name": "C~I", "db_refs": {"TEXT": "C~I"}},
 "obj":  {"name": "ATP biosynthetic process", "db_refs": {"GO": "GO:0006754"}},
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "4272126",
   "text": "Since the two proteins come from unrelated organisms and share no chemical intermediate, a proton gradient is sufficient",
   "epistemics": {"direct": false, "hypothesis": false, "negated": true, "curated": true},
   "annotations": {"provenance": "summary", "claim_role": "evidence against (by sufficiency + phylogenetic argument)", "against": "chemical_intermediate"},
   "context": "CTX_RECON"}]}
]
```

**Could not express:**
- Two source species in one system. `BioContext.species` holds one RefContext.
- "Reconstituted in vitro from purified parts". This is the core of the argument, and only the ECO code in annotations carries it.
- The logic "unrelated organisms, so no shared intermediate". It is an inference from phylogeny that INDRA cannot represent.
- "Abolished by X" as a *control* that validates the main result, vs. a finding in its own right. INDRA treats every Statement as a peer.
- Co-localisation of two proteins in one vesicle. A `Complex` would wrongly claim physical binding.
- That the membrane is *artificial*. GO:0016020 "membrane" is the nearest location, but it implies a natural cellular membrane.

---

## 7. Yoshino 2011, Cell Metab: NMN in diet- and age-induced diabetic mice (PMID 21982712, provenance: abstract)

Context objects. Diet and age have no BioContext slot. INDRA's `disease` slot gets T2D, and "HFD-induced"
vs. "age-induced" survives only in annotations and TEXT:

```json
{"CTX_HFD":  {"type": "bio", "species": {"name": "Mus musculus", "db_refs": {"TAXONOMY": "10090"}},
              "disease": {"name": "Diabetes Mellitus, Type 2", "db_refs": {"MESH": "D003924", "MONDO": "MONDO:0005148", "TEXT": "HFD-induced T2D"}}},
 "CTX_AGED": {"type": "bio", "species": {"name": "Mus musculus", "db_refs": {"TAXONOMY": "10090"}},
              "disease": {"name": "Diabetes Mellitus, Type 2", "db_refs": {"MESH": "D003924", "TEXT": "age-induced T2D"}}}}
```

Agents used below: `NMN` = `{"name": "NMN zwitterion", "db_refs": {"CHEBI": "CHEBI:16171", "MESH": "D009537"}}`;
`NAD+` = `{"name": "NAD(+)", "db_refs": {"CHEBI": "CHEBI:15846"}}`.

```json
[
{"type": "DecreaseAmount",
 "subj": {"name": "Diet, High-Fat", "db_refs": {"MESH": "D059305", "EFO": "EFO:0002757"}},
 "obj":  {"name": "Nampt", "db_refs": {"UP": "Q99KQ4"}},
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "21982712",
   "text": "NAMPT-mediated NAD(+) biosynthesis is severely compromised in metabolic organs by high-fat diet (HFD)",
   "epistemics": {"direct": false, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"claim_role": "experimental result", "assay": "in vivo", "organs": "'metabolic organs' (unspecified in abstract)", "magnitude": "severely"},
   "context": {"type": "bio", "species": {"name": "Mus musculus", "db_refs": {"TAXONOMY": "10090"}}}}]},

{"type": "DecreaseAmount",
 "subj": {"name": "Diet, High-Fat", "db_refs": {"MESH": "D059305"}},
 "obj":  {"name": "NAD(+)", "db_refs": {"CHEBI": "CHEBI:15846"}},
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "21982712",
   "text": "NAMPT-mediated NAD(+) biosynthesis is severely compromised in metabolic organs by high-fat diet",
   "epistemics": {"direct": false, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"claim_role": "experimental result", "assay": "in vivo"},
   "context": {"type": "bio", "species": {"name": "Mus musculus", "db_refs": {"TAXONOMY": "10090"}}}}]},

{"type": "IncreaseAmount",
 "subj": {"name": "NMN zwitterion", "db_refs": {"CHEBI": "CHEBI:16171"}},
 "obj":  {"name": "NAD(+)", "db_refs": {"CHEBI": "CHEBI:15846"}},
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "21982712",
   "text": "NMN ... ameliorates glucose intolerance by restoring NAD(+) levels in HFD-induced T2D mice",
   "epistemics": {"direct": false, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"claim_role": "experimental result", "assay": "in vivo", "direction_detail": "restores toward control level",
                   "dose": "not in abstract", "route": "not in abstract"},
   "context": "CTX_HFD"}]},

{"type": "Inhibition",
 "subj": {"name": "NMN zwitterion", "db_refs": {"CHEBI": "CHEBI:16171"}},
 "obj":  {"name": "Glucose Intolerance", "db_refs": {"MESH": "D018149", "HP": "HP:0001952", "MP": "MP:0005293"}},
 "belief": null,
 "evidence": [
  {"source_api": "biolean_manual", "pmid": "21982712",
   "text": "NMN ... ameliorates glucose intolerance by restoring NAD(+) levels in HFD-induced T2D mice",
   "epistemics": {"direct": false, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"claim_role": "experimental result", "mediator": "NAD(+) (CHEBI:15846)", "assay": "in vivo"},
   "context": "CTX_HFD"},
  {"source_api": "biolean_manual", "pmid": "21982712",
   "text": "NMN improves glucose intolerance and lipid profiles in age-induced T2D mice",
   "epistemics": {"direct": false, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"claim_role": "experimental result", "age": "aged (not specified)", "assay": "in vivo"},
   "context": "CTX_AGED"}]},

{"type": "Activation",
 "subj": {"name": "NMN zwitterion", "db_refs": {"CHEBI": "CHEBI:16171"}},
 "obj":  {"name": "cellular response to insulin stimulus", "db_refs": {"GO": "GO:0032869", "TEXT": "hepatic insulin sensitivity"}},
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "21982712",
   "text": "NMN also enhances hepatic insulin sensitivity",
   "epistemics": {"direct": false, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"claim_role": "experimental result", "assay": "in vivo"},
   "context": {"type": "bio", "species": {"name": "Mus musculus", "db_refs": {"TAXONOMY": "10090"}},
               "organ": {"name": "liver", "db_refs": {"UBERON": "UBERON:0002107"}},
               "disease": {"name": "Diabetes Mellitus, Type 2", "db_refs": {"MESH": "D003924", "TEXT": "HFD-induced T2D"}}}}]},

{"type": "Activation",
 "subj": {"name": "NMN zwitterion", "db_refs": {"CHEBI": "CHEBI:16171"}},
 "obj":  {"name": "Sirt1", "db_refs": {"UP": "Q923E4"}},
 "obj_activity": "catalytic",
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "21982712",
   "text": "restores gene expression related to oxidative stress, inflammatory response, and circadian rhythm, partly through SIRT1 activation",
   "epistemics": {"direct": false, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"claim_role": "experimental result", "hedge": "partly", "assay": "in vivo"},
   "context": "CTX_HFD"}]},

{"type": "Activation",
 "subj": {"name": "Sirt1", "db_refs": {"UP": "Q923E4"}, "activity": {"activity_type": "catalytic", "is_active": true}},
 "obj":  {"name": "response to oxidative stress", "db_refs": {"GO": "GO:0006979", "TEXT": "gene expression related to oxidative stress"}},
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "21982712",
   "text": "restores gene expression related to oxidative stress, inflammatory response, and circadian rhythm, partly through SIRT1 activation",
   "epistemics": {"direct": false, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"claim_role": "experimental result", "also_for": ["GO:0006954", "GO:0007623"],
                   "bend": "'restores' = moves back to normal; direction of each gene unspecified, Activation is a guess"},
   "context": "CTX_HFD"}]},

{"type": "DecreaseAmount",
 "subj": {"name": "Aging", "db_refs": {"MESH": "D000375"}},
 "obj":  {"name": "NAD(+)", "db_refs": {"CHEBI": "CHEBI:15846"}},
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "21982712",
   "text": "NAD(+) and NAMPT levels show significant decreases in multiple organs during aging",
   "epistemics": {"direct": false, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"claim_role": "experimental result (observational)", "also_for_obj": "Nampt UP:Q99KQ4",
                   "organs": "multiple (unspecified)", "significance": "significant"},
   "context": {"type": "bio", "species": {"name": "Mus musculus", "db_refs": {"TAXONOMY": "10090"}}}}]}
]
```

**Could not express:**
- Age, sex, strain, diet as *context*. BioContext has no slot for any of them. "HFD-induced" and "age-induced" T2D are both just `MESH:D003924`, told apart only by TEXT.
- Dose, route and duration of NMN (the abstract gives none; even if it did, there is no slot).
- "Restores": moving back toward a healthy baseline after a disease shift. INDRA has only up and down, with no reference state.
- Mediation ("ameliorates X *by* restoring NAD+", "*partly* through SIRT1"). Statements cannot nest, so the causal chain breaks into separate edges and "partly" is lost.
- "Improves lipid profile". This is a multi-analyte composite, with no Agent and no polarity.
- Treatment vs. untreated control comparison, effect size, p-values.
- That "Aging" is a cause. Making a time process the `subj` of `DecreaseAmount` is a bend that INDRA readers do produce, but it is not mechanistic.

---

## 8. Gomes 2013, Cell: declining NAD+ and pseudohypoxia in aging (PMID 24360282, provenance: abstract)

The abstract names no tissue and does not say *how* NAD+ was raised (the paper used NMN; the abstract
says "raising NAD(+) levels"). I keep to the abstract and record NMN only as an annotation.

```json
[
{"type": "DecreaseAmount",
 "subj": {"name": "Aging", "db_refs": {"MESH": "D000375"}},
 "obj":  {"name": "mitochondrially encoded OXPHOS subunits", "db_refs": {"MESH": "D050259", "TEXT": "mitochondrial ... encoded OXPHOS subunits"}},
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "24360282",
   "text": "during aging, there is a specific loss of mitochondrial, but not nuclear, encoded OXPHOS subunits",
   "epistemics": {"direct": false, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"claim_role": "experimental result", "assay": "in vivo",
                   "examples_not_in_abstract": ["UP:P03888 (mt-Nd1)", "UP:P00397 (mt-Co1)"]},
   "context": {"type": "bio", "species": {"name": "Mus musculus", "db_refs": {"TAXONOMY": "10090"}}}}]},

{"type": "DecreaseAmount",
 "subj": {"name": "Aging", "db_refs": {"MESH": "D000375"}},
 "obj":  {"name": "nuclear-encoded OXPHOS subunits", "db_refs": {"TEXT": "nuclear encoded OXPHOS subunits"}},
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "24360282",
   "text": "...but not nuclear, encoded OXPHOS subunits",
   "epistemics": {"direct": false, "hypothesis": false, "negated": true, "curated": true},
   "annotations": {"claim_role": "negative result"},
   "context": {"type": "bio", "species": {"name": "Mus musculus", "db_refs": {"TAXONOMY": "10090"}}}}]},

{"type": "DecreaseAmount",
 "subj": {"name": "Aging", "db_refs": {"MESH": "D000375"}},
 "obj":  {"name": "NAD(+)", "db_refs": {"CHEBI": "CHEBI:15846"}, "location": "nucleus"},
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "24360282",
   "text": "a decline in nuclear NAD(+)",
   "epistemics": {"direct": false, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"claim_role": "experimental result"},
   "context": {"type": "bio", "species": {"name": "Mus musculus", "db_refs": {"TAXONOMY": "10090"}},
               "location": {"name": "nucleus", "db_refs": {"GO": "GO:0005634"}}}}]},

{"type": "DecreaseAmount",
 "subj": {"name": "NAD(+)", "db_refs": {"CHEBI": "CHEBI:15846"}, "location": "nucleus"},
 "obj":  {"name": "Hif1a", "db_refs": {"UP": "Q61221"}},
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "24360282",
   "text": "induced by a decline in nuclear NAD(+) and the accumulation of HIF-1alpha under normoxic conditions",
   "epistemics": {"direct": false, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"claim_role": "experimental result", "oxygen": "normoxia (no slot)",
                   "bend": "paper says NAD+ decline -> HIF-1a accumulation; encoded as NAD+ DecreaseAmount HIF-1a"},
   "context": {"type": "bio", "species": {"name": "Mus musculus", "db_refs": {"TAXONOMY": "10090"}}}}]},

{"type": "DecreaseAmount",
 "subj": {"name": "Hif1a", "db_refs": {"UP": "Q61221"}},
 "obj":  {"name": "mitochondrially encoded OXPHOS subunits", "db_refs": {"MESH": "D050259"}},
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "24360282",
   "text": "an alternate PGC-1alpha/beta-independent pathway of nuclear-mitochondrial communication",
   "epistemics": {"direct": false, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"claim_role": "experimental result + interpretation", "independent_of": ["UP:O70343 (Ppargc1a)", "UP:Q8VHJ7 (Ppargc1b)"],
                   "analogy": "Warburg reprogramming"},
   "context": {"type": "bio", "species": {"name": "Mus musculus", "db_refs": {"TAXONOMY": "10090"}}}}]},

{"type": "IncreaseAmount",
 "subj": {"name": "Sirt1", "db_refs": {"UP": "Q923E4"}},
 "obj":  {"name": "mitochondrially encoded OXPHOS subunits", "db_refs": {"MESH": "D050259"}},
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "24360282",
   "text": "Deleting SIRT1 accelerates this process",
   "epistemics": {"direct": false, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"claim_role": "experimental result (loss-of-function)", "perturbation": "Sirt1 knockout",
                   "bend": "INDRA has no knockout; polarity inferred by inverting the KO phenotype"},
   "context": {"type": "bio", "species": {"name": "Mus musculus", "db_refs": {"TAXONOMY": "10090"}}}}]},

{"type": "Activation",
 "subj": {"name": "NAD(+)", "db_refs": {"CHEBI": "CHEBI:15846"}},
 "obj":  {"name": "Sirt1", "db_refs": {"UP": "Q923E4"}},
 "obj_activity": "catalytic",
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "24360282",
   "text": "raising NAD(+) levels in old mice restores mitochondrial function ... in a SIRT1-dependent manner",
   "epistemics": {"direct": false, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"claim_role": "experimental result", "age": "old (no value in abstract)", "intervention_per_note": "NMN (CHEBI:16171), not in abstract"},
   "context": {"type": "bio", "species": {"name": "Mus musculus", "db_refs": {"TAXONOMY": "10090"}}}}]},

{"type": "Activation",
 "subj": {"name": "NAD(+)", "db_refs": {"CHEBI": "CHEBI:15846"}},
 "obj":  {"name": "Mitochondria", "db_refs": {"MESH": "D008928", "TEXT": "mitochondrial function"}},
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "24360282",
   "text": "raising NAD(+) levels in old mice restores mitochondrial function to that of a young mouse",
   "epistemics": {"direct": false, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"claim_role": "experimental result", "reference_state": "young mouse", "requires": "Sirt1 (UP:Q923E4)",
                   "reversible": true},
   "context": {"type": "bio", "species": {"name": "Mus musculus", "db_refs": {"TAXONOMY": "10090"}}}}]}
]
```

**Could not express:**
- "Specific loss of X *but not* Y". The contrast is the finding, but it splits into a positive and a `negated` Statement with no link between them.
- "PGC-1alpha/beta-*independent*". INDRA can say A regulates B, never "A does B without C".
- "SIRT1-dependent" (necessity/conditionality). One Statement cannot be conditional on another, so "dependent" goes in an annotation.
- Knockout as a perturbation. INDRA `mutations` are point mutations, and there is no deletion/KO, so polarity had to be inverted by hand.
- "Pseudohypoxia" as a state (HIF accumulation under *normoxia*). Oxygen level is not a context slot.
- "Restores to that of a young mouse": an age comparison with a reference state.
- Subcellular location of NAD+ (nuclear) works via `Agent.location`, one of the few context items that fits natively.

---

## 9. Mills 2016, Cell Metab: 12-month NMN in normally aging mice (PMID 28068222, provenance: abstract)

Shared context `CTX_MILLS`. Strain, diet, genotype, route and duration all go in annotations
(`ANN_MILLS`), because BioContext has no slot for any of them:

```json
{"CTX_MILLS": {"type": "bio", "species": {"name": "Mus musculus", "db_refs": {"TAXONOMY": "10090"}}},
 "ANN_MILLS": {"strain": {"name": "C57BL/6N", "MESH": "D008810 (Mice, Inbred C57BL; substrain-level)", "EFO": "?:unverified"},
               "genotype": "wild-type", "diet": "regular chow", "route": "oral (MESH:D000284)",
               "duration": "12 months", "dose": "not in abstract", "age_window": "normal aging (start age not in abstract)",
               "assay": "in vivo", "evidence_code": "ECO:0000178"}}
```

```json
[
{"type": "IncreaseAmount",
 "subj": {"name": "NMN zwitterion", "db_refs": {"CHEBI": "CHEBI:16171", "MESH": "D009537"}},
 "obj":  {"name": "NAD(+)", "db_refs": {"CHEBI": "CHEBI:15846"}},
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "28068222",
   "text": "Orally administered NMN was quickly utilized to synthesize NAD+ in tissues",
   "epistemics": {"direct": true, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"ANN_MILLS": "...", "kinetics": "quickly"}, "context": "CTX_MILLS"}]},

{"type": "Inhibition",
 "subj": {"name": "NMN zwitterion", "db_refs": {"CHEBI": "CHEBI:16171"}},
 "obj":  {"name": "Weight Gain", "db_refs": {"MESH": "D015430", "TEXT": "age-associated body weight gain"}},
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "28068222",
   "text": "NMN suppressed age-associated body weight gain",
   "epistemics": {"direct": false, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"ANN_MILLS": "..."}, "context": "CTX_MILLS"}]},

{"type": "Activation",
 "subj": {"name": "NMN zwitterion", "db_refs": {"CHEBI": "CHEBI:16171"}},
 "obj":  {"name": "Energy Metabolism", "db_refs": {"MESH": "D004734"}},
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "28068222",
   "text": "enhanced energy metabolism",
   "epistemics": {"direct": false, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"ANN_MILLS": "..."}, "context": "CTX_MILLS"}]},

{"type": "Activation",
 "subj": {"name": "NMN zwitterion", "db_refs": {"CHEBI": "CHEBI:16171"}},
 "obj":  {"name": "Motor Activity", "db_refs": {"MESH": "D009043", "TEXT": "physical activity"}},
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "28068222",
   "text": "promoted physical activity",
   "epistemics": {"direct": false, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"ANN_MILLS": "..."}, "context": "CTX_MILLS"}]},

{"type": "Inhibition",
 "subj": {"name": "NMN zwitterion", "db_refs": {"CHEBI": "CHEBI:16171"}},
 "obj":  {"name": "Insulin Resistance", "db_refs": {"MESH": "D007333", "HP": "HP:0000855", "MP": "MP:0005331"}},
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "28068222",
   "text": "improved insulin sensitivity and plasma lipid profile",
   "epistemics": {"direct": false, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"ANN_MILLS": "...", "also": "plasma lipid profile improved (no Agent; UBERON:0001969 blood plasma)"}, "context": "CTX_MILLS"}]},

{"type": "Activation",
 "subj": {"name": "NMN zwitterion", "db_refs": {"CHEBI": "CHEBI:16171"}},
 "obj":  {"name": "Vision, Ocular", "db_refs": {"MESH": "D014785", "TEXT": "eye function"}},
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "28068222",
   "text": "ameliorated eye function and other pathophysiologies",
   "epistemics": {"direct": false, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"ANN_MILLS": "..."},
   "context": {"type": "bio", "species": {"name": "Mus musculus", "db_refs": {"TAXONOMY": "10090"}},
               "organ": {"name": "eye", "db_refs": {"UBERON": "UBERON:0000970"}}}}]},

{"type": "Activation",
 "subj": {"name": "NMN zwitterion", "db_refs": {"CHEBI": "CHEBI:16171"}},
 "obj":  {"name": "oxidative phosphorylation", "db_refs": {"GO": "GO:0006119", "TEXT": "mitochondrial oxidative metabolism"}},
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "28068222",
   "text": "enhanced mitochondrial oxidative metabolism and mitonuclear protein imbalance in skeletal muscle",
   "epistemics": {"direct": false, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"ANN_MILLS": "...", "also": "mitonuclear protein imbalance (no Agent)"},
   "context": {"type": "bio", "species": {"name": "Mus musculus", "db_refs": {"TAXONOMY": "10090"}},
               "organ": {"name": "skeletal muscle tissue", "db_refs": {"UBERON": "UBERON:0001134"}}}}]},

{"type": "Activation",
 "subj": {"name": "NMN zwitterion", "db_refs": {"CHEBI": "CHEBI:16171"}},
 "obj":  {"name": "Drug-Related Side Effects and Adverse Reactions", "db_refs": {"MESH": "D064420", "TEXT": "toxicity or deleterious effects"}},
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "28068222",
   "text": "Without any obvious toxicity or deleterious effects",
   "epistemics": {"direct": false, "hypothesis": false, "negated": true, "curated": true},
   "annotations": {"ANN_MILLS": "...", "claim_role": "negative result (safety)", "hedge": "obvious"}, "context": "CTX_MILLS"}]},

{"type": "Inhibition",
 "subj": {"name": "NMN zwitterion", "db_refs": {"CHEBI": "CHEBI:16171"}},
 "obj":  {"name": "Aging", "db_refs": {"MESH": "D000375", "TEXT": "age-associated physiological decline"}},
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "28068222",
   "text": "NMN effectively mitigates age-associated physiological decline in mice ... highlight the preventive and therapeutic potential ... in humans",
   "epistemics": {"direct": false, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"ANN_MILLS": "...", "claim_role": "summary result",
                   "extrapolation": {"to_species": "TAXONOMY:9606", "status": "speculation (epistemics.hypothesis would apply to this part only)"}},
   "context": "CTX_MILLS"}]}
]
```

**Could not express:**
- Duration (12 months), route (oral), diet (chow), strain (C57BL/6N) and genotype (WT) as *context*. All of it is free-form annotation that INDRA's assembly, filtering and belief tools ignore. I found no EFO term for the C57BL/6N substrain.
- "Age-associated" decline *prevented* (a counterfactual: treated mice do not show the change seen in controls). The polarity only says "less weight gain".
- Composite phenotypes ("plasma lipid profile", "mitonuclear protein imbalance", "other pathophysiologies"), which have no Agent.
- The mouse-to-human extrapolation as a separate hypothesis. `hypothesis` is per Evidence, and the text mixes result and speculation in one sentence.
- "Prevented age-associated gene expression changes in key metabolic organs". There is no Agent for a transcriptome-wide change, and the organs are unnamed.
- "Without obvious toxicity": a negated `Activation` toward a MESH "adverse reactions" class is very loose, and "obvious" is lost.

---

## 10. Das 2018, Cell: endothelial NAD+-H2S network in vascular aging (PMID 29570999, provenance: abstract)

```json
[
{"type": "Activation",
 "subj": {"name": "NAD precursors", "db_refs": {"TEXT": "NAD precursors"}},
 "obj":  {"name": "Sirtuins", "db_refs": {"MESH": "D037761", "TEXT": "sirtuin deacylases (SIRT1-SIRT7)"}},
 "obj_activity": "catalytic",
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "29570999",
   "text": "NAD precursors reverse aspects of aging, in part, by activating sirtuin deacylases (SIRT1-SIRT7)",
   "epistemics": {"direct": false, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"claim_role": "background (prior literature, cited in introduction)", "hedge": "in part"}}]},

{"type": "Activation",
 "subj": {"name": "pro-angiogenic signals secreted from myocytes", "db_refs": {"MESH": "D043925", "TEXT": "pro-angiogenic signals secreted from myocytes"}},
 "obj":  {"name": "Sirt1", "db_refs": {"UP": "Q923E4"}},
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "29570999",
   "text": "SIRT1 in endothelial cells is a key mediator of pro-angiogenic signals secreted from myocytes",
   "epistemics": {"direct": false, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"claim_role": "experimental result", "subj_cell_type": "CL:0000187 muscle cell (source)",
                   "bend": "'mediator of' is not 'activated by'; subj and obj are in different cell types but BioContext has one cell_type"},
   "context": {"type": "bio", "species": {"name": "Mus musculus", "db_refs": {"TAXONOMY": "10090"}},
               "cell_type": {"name": "endothelial cell", "db_refs": {"CL": "CL:0000115"}}}}]},

{"type": "Activation",
 "subj": {"name": "Sirt1", "db_refs": {"UP": "Q923E4"}},
 "obj":  {"name": "angiogenesis", "db_refs": {"GO": "GO:0001525", "MESH": "D018919", "TEXT": "capillary density"}},
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "29570999",
   "text": "promoting SIRT1-dependent increases in capillary density",
   "epistemics": {"direct": false, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"claim_role": "experimental result"},
   "context": {"type": "bio", "species": {"name": "Mus musculus", "db_refs": {"TAXONOMY": "10090"}},
               "cell_type": {"name": "endothelial cell", "db_refs": {"CL": "CL:0000115"}},
               "organ": {"name": "skeletal muscle tissue", "db_refs": {"UBERON": "UBERON:0001134"}}}}]},

{"type": "Activation",
 "subj": {"name": "NMN zwitterion", "db_refs": {"CHEBI": "CHEBI:16171", "MESH": "D009537"}},
 "obj":  {"name": "angiogenesis", "db_refs": {"GO": "GO:0001525", "MESH": "D018919"}},
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "29570999",
   "text": "Treatment of mice with ... NMN improves blood flow and increases endurance in elderly mice by promoting SIRT1-dependent increases in capillary density",
   "epistemics": {"direct": false, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"claim_role": "experimental result", "age": "elderly (MESH:D000368 'Aged' is human-only)", "requires": "Sirt1 (UP:Q923E4)",
                   "dose": "not in abstract", "duration": "not in abstract", "assay": "in vivo"},
   "context": {"type": "bio", "species": {"name": "Mus musculus", "db_refs": {"TAXONOMY": "10090"}},
               "organ": {"name": "capillary", "db_refs": {"UBERON": "UBERON:0001982"}}}}]},

{"type": "Activation",
 "subj": {"name": "NMN zwitterion", "db_refs": {"CHEBI": "CHEBI:16171"}},
 "obj":  {"name": "Regional Blood Flow", "db_refs": {"MESH": "D012039", "TEXT": "blood flow"}},
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "29570999",
   "text": "NMN improves blood flow ... in elderly mice",
   "epistemics": {"direct": false, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"claim_role": "experimental result", "age": "elderly", "mediator": "angiogenesis (GO:0001525)"},
   "context": {"type": "bio", "species": {"name": "Mus musculus", "db_refs": {"TAXONOMY": "10090"}}}}]},

{"type": "Activation",
 "subj": {"name": "NMN zwitterion", "db_refs": {"CHEBI": "CHEBI:16171"}},
 "obj":  {"name": "Physical Endurance", "db_refs": {"MESH": "D010807", "MP": "MP:0012107"}},
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "29570999",
   "text": "NMN ... increases endurance in elderly mice",
   "epistemics": {"direct": false, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"claim_role": "experimental result", "age": "elderly", "synergy": "augmented by exercise (MESH:D015444) or H2S (CHEBI:16136)"},
   "context": {"type": "bio", "species": {"name": "Mus musculus", "db_refs": {"TAXONOMY": "10090"}}}}]},

{"type": "IncreaseAmount",
 "subj": {"name": "hydrogen sulfide", "db_refs": {"CHEBI": "CHEBI:16136", "MESH": "D006862", "TEXT": "H2S"}},
 "obj":  {"name": "NAD(+)", "db_refs": {"CHEBI": "CHEBI:15846"}},
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "29570999",
   "text": "hydrogen sulfide (H2S), a DR mimetic and regulator of endothelial NAD+ levels",
   "epistemics": {"direct": false, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"claim_role": "experimental result", "bend": "abstract says 'regulator', polarity not stated; IncreaseAmount is an assumption",
                   "class": "dietary restriction mimetic (MESH:D031204 Caloric Restriction)"},
   "context": {"type": "bio", "species": {"name": "Mus musculus", "db_refs": {"TAXONOMY": "10090"}},
               "cell_type": {"name": "endothelial cell", "db_refs": {"CL": "CL:0000115"}}}}]},

{"type": "Activation",
 "subj": {"name": "Exercise", "db_refs": {"MESH": "D015444"}},
 "obj":  {"name": "angiogenesis", "db_refs": {"GO": "GO:0001525"}},
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "29570999",
   "text": "an effect augmented by exercise or increasing the levels of hydrogen sulfide",
   "epistemics": {"direct": false, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"claim_role": "experimental result", "bend": "the claim is that exercise AUGMENTS NMN's effect (interaction), not that exercise alone activates angiogenesis"},
   "context": {"type": "bio", "species": {"name": "Mus musculus", "db_refs": {"TAXONOMY": "10090"}}}}]}
]
```

**Could not express:**
- Cell-to-cell signalling (myocyte -> endothelial cell). A Statement's Evidence has one `cell_type`, so the subject's and object's cells cannot both be stated.
- Interaction effects ("augmented by exercise or H2S"). INDRA has no way to say "A and B together > A alone". This is the key result of the paper, and it is lost.
- "SIRT1-dependent" (needs the endothelial Sirt1 knockout as a conditional). Again only an annotation.
- The "virtuous cycle" loop and the claim that the defect is a *reversible cause* of vascular aging.
- Age as context ("elderly" mice). There is no slot, and MESH "Aged" is defined for humans.
- Implications for human performance (extrapolation). Not captured.

---

## 11. Yoshino 2021, Science: NMN in prediabetic women, RCT (PMID 33888596, provenance: abstract)

Shared context `CTX_RCT` and annotations `ANN_RCT`. There is **one** `disease` slot, so prediabetes goes in
and overweight/obesity goes out:

```json
{"CTX_RCT": {"type": "bio",
   "species": {"name": "Homo sapiens", "db_refs": {"TAXONOMY": "9606"}},
   "organ":   {"name": "skeletal muscle tissue", "db_refs": {"UBERON": "UBERON:0001134", "MESH": "D018482"}},
   "disease": {"name": "Prediabetic State", "db_refs": {"MESH": "D011236", "MONDO": "MONDO:0006920"}}},
 "ANN_RCT": {"design": ["MESH:D016449 Randomized Controlled Trial", "MESH:D004311 Double-Blind Method", "placebo-controlled (MESH:D010919)"],
             "evidence_code": "ECO:0000180", "trial_id": "NCT03151239", "duration": "10 weeks",
             "sex": "female (PATO:0000383)", "life_stage": "postmenopausal (EFO:0002721, MESH:D017698)",
             "comorbidity": ["Overweight MESH:D050177 / HP:0025502", "Obesity MESH:D009765 / HP:0001513"],
             "dose": "not in abstract", "n": "not in abstract"}}
```

```json
[
{"type": "Activation",
 "subj": {"name": "NMN zwitterion", "db_refs": {"CHEBI": "CHEBI:16171", "MESH": "D009537"}},
 "obj":  {"name": "cellular response to insulin stimulus", "db_refs": {"GO": "GO:0032869", "TEXT": "insulin-stimulated glucose disposal"}},
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "33888596",
   "text": "Insulin-stimulated glucose disposal, assessed by using the hyperinsulinemic-euglycemic clamp ... increased after NMN supplementation but did not change after placebo treatment",
   "epistemics": {"direct": false, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"ANN_RCT": "...", "method": "MESH:D015309 Glucose Clamp Technique", "claim_role": "primary experimental result"},
   "context": "CTX_RCT"}]},

{"type": "IncreaseAmount",
 "subj": {"name": "NMN zwitterion", "db_refs": {"CHEBI": "CHEBI:16171"}},
 "obj":  {"name": "AKT1", "db_refs": {"HGNC": "391", "UP": "P31749", "TEXT": "protein kinase AKT"},
          "mods": [{"mod_type": "phosphorylation", "is_modified": true}]},
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "33888596",
   "text": "skeletal muscle insulin signaling [phosphorylation of protein kinase AKT and mechanistic target of rapamycin (mTOR)] increased after NMN supplementation",
   "epistemics": {"direct": false, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"ANN_RCT": "...", "grounding_note": "abstract says 'AKT' (family FPLX:AKT); AKT1 chosen as the canonical isoform",
                   "condition": "insulin-stimulated"},
   "context": "CTX_RCT"}]},

{"type": "IncreaseAmount",
 "subj": {"name": "NMN zwitterion", "db_refs": {"CHEBI": "CHEBI:16171"}},
 "obj":  {"name": "MTOR", "db_refs": {"HGNC": "3942", "UP": "P42345"},
          "mods": [{"mod_type": "phosphorylation", "is_modified": true}]},
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "33888596",
   "text": "...phosphorylation of ... mechanistic target of rapamycin (mTOR) ... increased after NMN supplementation",
   "epistemics": {"direct": false, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"ANN_RCT": "..."}, "context": "CTX_RCT"}]},

{"type": "IncreaseAmount",
 "subj": {"name": "Placebos", "db_refs": {"MESH": "D010919"}},
 "obj":  {"name": "cellular response to insulin stimulus", "db_refs": {"GO": "GO:0032869"}},
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "33888596",
   "text": "...but did not change after placebo treatment",
   "epistemics": {"direct": false, "hypothesis": false, "negated": true, "curated": true},
   "annotations": {"ANN_RCT": "...", "claim_role": "negative control result",
                   "bend": "the placebo arm is the comparator that MAKES the NMN result; INDRA stores it as an unrelated negated Statement"},
   "context": "CTX_RCT"}]},

{"type": "IncreaseAmount",
 "subj": {"name": "NMN zwitterion", "db_refs": {"CHEBI": "CHEBI:16171"}},
 "obj":  {"name": "PDGFRB", "db_refs": {"HGNC": "8804", "UP": "P09619"}},
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "33888596",
   "text": "NMN supplementation up-regulated the expression of platelet-derived growth factor receptor beta and other genes related to muscle remodeling",
   "epistemics": {"direct": false, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"ANN_RCT": "...", "level": "mRNA expression"}, "context": "CTX_RCT"}]},

{"type": "Activation",
 "subj": {"name": "NMN zwitterion", "db_refs": {"CHEBI": "CHEBI:16171"}},
 "obj":  {"name": "Muscle Development", "db_refs": {"MESH": "D024510", "GO": "GO:0060537", "TEXT": "muscle remodeling"}},
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "33888596",
   "text": "NMN increases muscle insulin sensitivity, insulin signaling, and remodeling in women with prediabetes who are overweight or obese",
   "epistemics": {"direct": false, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"ANN_RCT": "...", "bend": "'remodeling' inferred from a gene-expression set; nearest terms are development terms"},
   "context": "CTX_RCT"}]},

{"type": "DecreaseAmount",
 "subj": {"name": "Obesity", "db_refs": {"MESH": "D009765"}},
 "obj":  {"name": "NAD(+)", "db_refs": {"CHEBI": "CHEBI:15846"}},
 "belief": null,
 "evidence": [{"source_api": "biolean_manual", "pmid": "33888596",
   "text": "In rodents, obesity and aging impair nicotinamide adenine dinucleotide (NAD+) biosynthesis",
   "epistemics": {"direct": false, "hypothesis": false, "negated": false, "curated": true},
   "annotations": {"claim_role": "background (prior rodent literature)", "also_subj": "Aging MESH:D000375"},
   "context": {"type": "bio", "species": {"name": "Rodentia", "db_refs": {"TAXONOMY": "9989"}}}}]}
]
```

Note on pooling: unit 1 has the same type and agents as Yoshino 2011's mouse-liver
`Activation(NMN -> GO:0032869)`. INDRA preassembly therefore merges the human RCT evidence and the mouse
evidence onto one Statement, and the belief score rises. The species difference is visible only if you
look inside each Evidence's context. Nothing marks the human evidence as a test of the mouse claim.

**Could not express:**
- The *comparison* (NMN arm vs. placebo arm, pre vs. post). The core logic of an RCT has no structure; the placebo arm becomes a detached negated Statement.
- Effect size, CI, p-value, sample size.
- Two diseases at once (prediabetes + overweight/obese). One `disease` slot.
- Sex, menopausal status, duration, dose and trial ID. All are annotations only.
- RCT vs. mouse experiment vs. 1960s biochemistry as an *evidence strength* for belief. INDRA's belief engine weights by `source_api` (reader error rates), not by study design.
- "Women who are overweight or obese" as the population the result is limited to. Generalisation scope is not representable.
- That this paper *tests in humans* the claims made in mice (cross-species transfer). It is only implicit via pooling.

---

## Fit table

| Aspect | Expressible? | How |
|---|---|---|
| Direction of effect | yes | The Statement type carries polarity (`Activation`/`Inhibition`, `IncreaseAmount`/`DecreaseAmount`). There is no "restores to baseline", no "abolished vs. reduced", and no interaction ("augments"). |
| Quantitative result | no | No slot on bio Statements. H+/O = 4 and 6, pH ranges and effect sizes went into free-form `annotations`, which INDRA tools ignore. (`QuantitativeState` exists only on `Influence` deltas for the World Modelers use case.) |
| Species/strain | partial | `BioContext.species` (TAXONOMY) holds one species per Evidence. There is no strain slot (C57BL/6N went in annotations), and chimeric systems (Racker) do not fit. |
| Age/stage | no | No slot. "Aging" was bent into a `subj` Agent (MESH:D000375); "elderly", "old" and "postmenopausal" became annotations. |
| Tissue/cell | yes (one each) | `organ` (UBERON) and `cell_type` (CL), plus `location` (GO CC) and `Agent.location`. Only one of each per Evidence, so myocyte -> endothelium signalling cannot be placed. `cell_line` was bent for "submitochondrial particles" and "liposomes". |
| Disease model | partial | `BioContext.disease` (MESH/MONDO) holds one disease. "HFD-induced" vs. "age-induced" T2D collapse to the same ID. There is no "model" vs. "patient" distinction and no comorbidity. |
| Dose/duration | no | No slot on BioContext. Duration and route went into annotations. (`WorldContext.time` exists but belongs to the WM `Influence`/`Event` branch, not bio Statements.) |
| Hypothesis vs. result | partial | `epistemics.hypothesis` is a boolean per Evidence. Hypothesis, prediction and background claim cannot be told apart, and one Evidence sentence that mixes result and speculation (Mills) cannot be split. |
| Rival hypotheses | no | No "alternative to" relation. `Statement.contradicts()` fires only on opposite polarity over the same agents. Slater's and Mitchell's chains share no edge, so INDRA sees no conflict. A rival's postulated entity (C~I) is "ungrounded", and `filter_grounded_only` deletes it. |
| Evidence type | partial | `Evidence.source_api` + `epistemics.direct` + `epistemics.curated` exist. In vitro vs. in vivo vs. RCT has no native slot (ECO went in annotations), and belief weighting ignores study design. |
| Cross-species transfer | no (implicit only) | Same-agent Statements from mouse and human pool silently during preassembly (Yoshino 2011 + 2021). Transfer is never stated or tested. INDRA's grounding habit of mapping proteins to human HGNC actively hides species. |
| Negative results | partial | `epistemics.negated: true` exists and pools onto the claim it negates (Jagendorf/Mitchell-Moyle/Racker -> Slater). But as far as I know INDRA's default belief scorers do not read `negated`, so negating evidence *raises* the belief of the negated claim unless you filter it yourself. |

## Verdict

(a) **Chemiosmotic papers.** INDRA can draw the *parts* of the mechanism (`Translocation` of H+,
`Conversion` of ADP + Pi to ATP, uncouplers raising proton conductance), but its core idea is the
proton-motive force: a membrane *state* that INDRA can only fake as an Agent grounded to a MESH term. The
controversy, which is the scientific point of these six papers, is almost invisible. Rival hypotheses have no
relation between them, `contradicts()` cannot see a conflict between two different causal chains, and
Slater's C~I is an "ungrounded" Agent that INDRA's standard filters throw away. The one smart thing INDRA does
here is pooling: the evidence from Jagendorf, Hinkle and Racker lands on Mitchell's exact Statement, and
negated evidence lands on Slater's; but the belief engine does not treat negated evidence as evidence
against, so the "verdict" of the controversy cannot be computed. Stoichiometries, pH jumps, membrane
sidedness and the logic of sufficiency (reconstitution from two unrelated organisms) all end up as free-text
annotations.

(b) **NMN mouse papers.** These fit better on the surface: "NMN increases NAD+", "NMN inhibits glucose
intolerance", "Sirt1 activates angiogenesis" look like what INDRA's readers already extract from PubMed. But
almost everything that makes such a result *usable* (age, sex, strain, diet, dose, route, duration, treated
vs. control, effect size) has no BioContext slot. So "HFD-induced T2D mouse" and "prediabetic postmenopausal
woman" differ only by a taxonomy ID in one field. Phenotypes ("lipid profile", "eye function", "physical
activity") have to become pseudo-Agents grounded to MESH concepts with polarity applied to them, and the
dependence claims that are the papers' mechanistic payload ("SIRT1-dependent", "PGC-1-independent",
"augmented by exercise") cannot be expressed. Worst for BioLean: preassembly silently merges mouse and human
evidence for the same edge and raises belief, which is exactly the cross-species transfer step that should be
explicit and weighted.
