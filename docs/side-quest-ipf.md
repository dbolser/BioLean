# Side quest: BioLean checks hypothesis-agent runs (IPF and the rest)

Started 2026-10-28, on branch `side-quest/ipf-bridge` (worktree `../BioLean-ipf`). Not part of the
ROADMAP milestones. It tests whether BioLean is useful to the IUK-IPF grant
(`/home/danbolser/Work/IUK-IPF`).

Round 1 (2026-10-28, below) did one run by hand. Round 2 (2026-10-30 to 11-03, after it) did
every run, with agents.

## Why

The grant assesses drug targets on five dimensions. BioLean fits one of them: **causality /
disease mechanism**. In IUK-IPF, `hypothesis-agent` proposes mechanisms as chains of signed steps
with citations and an LLM-chosen confidence (low, medium, high). BioLean could check those chains
and compute their strength instead.

The question: take one real run, translate it, and see what type-checks, where it breaks and what
the computed strength says.

## The run

`hypothesis-agent/store/runs/20260824T223623Z-4f7d1a`: idiopathic pulmonary fibrosis, genes MUC5B,
TERT, SFTPC, TOLLIP, DSP, FAM13A, Claude Opus 5, live data. It gave 5 hypotheses with 17 steps and
23 cited PMIDs. (The `.indra` file in the hypothesis-agent root is a schizophrenia run, not IPF.)

## What was done

1. `scripts/ipf/01_sources.py` copies the run and the text of everything it cites into `data/ipf/`.
   Abstracts come from the run's own Europe PMC responses, so we read what the agent read.
2. Every cited abstract was read against the step it was cited for. The result is
   `data/ipf/curated.json`: each step becomes a statement, or is listed as not expressible with a
   reason. Each citation is kept with a verbatim quote, or dropped with a reason.
3. `scripts/ipf/02_render_lean.py` checks the curation and writes `BioLean/Lib/IPF.lean`. It
   checks that every quote is in its source, every CURIE is in the local corpus, and every run
   step is accounted for exactly once.
4. `BioLean/Examples/IPF.lean` composes the statements into one derivation per hypothesis arm and
   certifies the verdicts with `decide +kernel`.

Small core changes, all needed by disease mechanisms:

- `Target.disease`: an effect on a disease's risk. It was an open item in STATUS.
- `Kind.variant`: dbSNP and ClinVar variants. Genetic risk starts at a variant.
- `Derivation.viaProcess` and `viaPhenotype`: chains through a process or a phenotype, alongside
  `viaAmount` and `viaActivity`. Disease mechanisms mostly run through processes ("ER stress drives
  fibrosis"). The textbook never needed this.

`lake build BioLean BioLeanLib` passes and `pytest` passes. The generated textbook libraries were
not rebuilt.

## Results

### The run's chains are not chains

In all 5 hypotheses, no step's object is the next step's subject. Each "chain" is a list of
separate edges. For example, H1 goes "variant → MUC5B mucin", then "ectopic MUC5B expression → ER
stress". To compose them, someone has to decide that the two MUC5B nodes are the same thing. Lean
refuses to compose them until that is done.

**Across all runs (checked 2026-10-28).** This is not specific to the run above, nor to the
`.indra` export. The count comes from each run's `result.json`. A link is counted when a step's
object label equals the next step's subject label (case-insensitive). 75 runs in the store have
chains.

| model | runs | steps | possible links | actual links |
|---|---|---|---|---|
| gemini-3.1-pro-preview | 33 | 277 | 189 | 132 (70%) |
| deepseek-v3.2 | 17 | 138 | 86 | 38 (44%) |
| claude-opus-5 (direct and OpenRouter) | 10 | 160 | 118 | 21 (18%) |
| gpt-5.6-sol (direct and OpenRouter) | 9 | 106 | 73 | 11 (15%) |
| claude-fable-5-1 | 1 | 15 | 12 | 6 |

The problem is current: the newest run (2026-10-06, Opus 5 via OpenRouter, ALS) links 1 of 13.
It is also model-dependent. Opus and GPT write richer but disconnected steps ("FYTTD1 required
for mRNA export", then "loss of mRNA export adapter function → degeneration"). Gemini links more,
but its links are not always right. In the IPF study run `...gemini-3.1-pro-preview-multi_agent-r2`,
H1 states "MUC5B inhibits mucociliary clearance" and "mucociliary clearance leads_to (+) IPF".
Composed, that makes MUC5B protective, the opposite of the hypothesis title. The sign algebra
catches this.

### Grounding

The run gave identifiers to 4 of its 29 distinct entity labels. After hand-grounding, 17 of the
18 entities used here have a public CURIE, all checked against the local corpus. The exception is
the class "SFTPC BRICHOS-domain mutation", which has no public identifier. The run's compound
labels ("AT2 senescence / failed alveolar regeneration") became refinements, as in M2:
`cellularSenescence.inCtx { cellType := at2 }`.

Correction to a guess: IPF is `MONDO:0800504` in the local MONDO, not the `MONDO:0008345` I
assumed. The render script's CURIE check exists for this reason.

### Steps

| | count |
|---|---|
| run steps | 17 |
| became statements | 11 (H1.4 split in two, so 12 statements) |
| not expressible | 6 |
| bridge statements added (not in the run) | 1 |
| citations on the 11 expressible steps | 23: 13 state the step, 9 do not, 1 has no text to check |

Why the 6 are not expressible:

- **H3.3, H4.2, H4.3, H5.1 are unsigned associations.** A GWAS hit says "variant associated with
  IPF". BioLean needs a sign. For TOLLIP the sign depends on the allele, and the cited GWAS says so:
  "the protective TOLLIP minor allele of rs5743890 carried an increased mortality risk".
- **H3.4: the cited trial does not test the step.** PANTHER (PMID 22607134) reports the
  three-drug arm. The step is about NAC alone.
- **H5.2: both ends are compound phrases with no term.**

Why citations were dropped: the abstract does not state the step. The clearest case is
**H2.3, "mutant pro-SFTPC causes ER stress"**. All three of its citations fail. The Reactome
pathway is about surfactant disease, the UniProt entry does not mention ER stress, and the paper is
about ER stress in IPF without mentioning SFTPC. The step may well be true. It is not supported by
what the run cited.

### Derivations

| arm | conclusion (sign computed by Lean) | belief | verdict | run said |
|---|---|---|---|---|
| H1, MUC5B | rs35705950 →+ pulmonary fibrosis | 0.25 | unsupported | medium |
| H1, DSP | DSP →− pulmonary fibrosis | 0.49 | unsupported | medium |
| H2, TERT | TERT →− IPF (needs the bridge) | 0.43 | unsupported | medium |
| H2, SFTPC | SFTPC mutation →+ pulmonary fibrosis | 0.00 | unsupported | medium |
| H2, AT2 senescence | single step →+ IPF | 0.78 | unsupported | medium |
| H3, H4 | no route from the gene to the disease in the run | n/a | n/a | low |

What this shows:

- **Signs are predictions.** DSP comes out protective, so the IPF risk allele must lower DSP. The
  run never says so. That is a step to check in the literature or the data.
- **Hidden gaps show up.** The TERT arm composes only after adding "telomere maintenance prevents
  short telomeres" (I7). It is obvious, but the run never stated it. H3 and H4 never reach the
  disease at all: TOLLIP inhibits IRAK1 and FAM13A inhibits RHOA, and then nothing.
- **Statements are reused across hypotheses.** The SFTPC arm (H2) borrows "ER stress drives
  pulmonary fibrosis" from H1. This is the biolib idea working on disease data.
- **The wrong disease.** The H1 arms end at *pulmonary fibrosis*, not IPF, because the mechanistic
  evidence is the bleomycin mouse model. IPF is_a pulmonary fibrosis, so nothing transfers down
  to IPF.
- **Mouse evidence is flagged.** I4's only evidence is a mouse study. The taxon lint catches it
  (`#guard !I4.taxonConsistent`). The proper fix is M2's `transport`, not done here.
- **One paper carries the DSP arm.** Both of its steps rest on PMID 42120512. The chain treats the
  two steps as independent, and `sharedAxioms` does not catch this because the statement ids
  differ.
- **The MUC5B arm is the weakest**, even though MUC5B is the strongest known genetic risk for IPF.
  The genetics (OR about 9, PMID 21506741) does not enter, because the run cited it for a step it
  does not state (variant → expression). The direct genetic claim, variant →+ IPF, would be strong.
  But the run's chains never contain it.

## Round 2: every run (2026-10-30 to 11-03)

Can BioLean be used in anger on IUK-IPF? Round 2 translated every hypothesis-agent run with
chains, 72 of them across 12 diseases and 6 models, and changed BioLean wherever it broke.

### How

1. `scripts/ipf/sources.py` copies each run and resolves every citation through the run's own
   evidence ledger (bundle → artifact → JSON pointer), so the text is exactly what the agent saw.
2. A curator agent per run writes `data/ipf/runs/<run>/curated.json` by the rules in
   `docs/ipf-curation.md`: ground every node, decide which run labels are the same node, keep a
   citation only with a verbatim quote that states the step, record what cannot be said and why.
3. `scripts/ipf/render.py` checks it (quotes are substrings, CURIEs are in the corpus with the
   right kind, every step is accounted for), then **composes the arms itself**: every route of
   statements from a hypothesis's gene to its disease. It writes one Lean module per run. Lean
   type-checks each arm and computes its sign, belief and verdict.
4. An independent auditor per run re-reads everything, fixes errors and logs each fix.
5. `scripts/ipf/report.py` totals it.

**Calibration.** A blind agent re-curation of the round-1 run matched the hand curation on 16 of
17 steps. On evidence it was stricter than me, and right twice ("a RhoGAP domain" is not evidence
that FAM13A inhibits RhoA).

**Audit.** 3,570 items checked, 119 substantive fixes (about 3 percent): 27 exclusions, 20
unexpressed calls, 17 groundings, 15 hypothesis claims, 14 quotes that did not state the step, 10
signs. One error I know survived: a null GWAS for common LMNA variants refutes "rare pathogenic
LMNA variants cause DCM", a different claim.

**Coverage.** 70 of 72 runs are curated, audited and build as one Lean library (`lake build
IPFRuns`, 71 modules with the calibration copy). Two runs were not curated: a safety classifier
stopped the agent mid-write (`mgmt-als-opus-5`; `20260915T170634Z-3289a0`, which cites a
SARS-CoV-2 reverse-genetics paper). They were left alone.

### What changed in BioLean because of real use

| change | why |
|---|---|
| `Claim.assoc x (dir : Option Sign) t`, and `Derivation.fromAssoc` (signed association read as an effect, discounted by `assocWeight`: ½ for a variant, ⅕ otherwise) | 28 percent of all steps are associations or unsigned; GWAS hits had nowhere to go |
| `DiseaseAspect` on `Target.disease`: risk, severity, progression | a TOLLIP allele lowers IPF risk and raises mortality |
| `Evidence.ref`, and deduplication by record as well as PMID | half the citations are not papers; the same UniProt entry cited twice counted twice |
| phenotype refinements use `characteristic_of` (RO:0000052), not `part_of` | "abnormal physiology part of AT2 cell" is wrong for a quality; two curators hit it |
| taxa: zebrafish, fly, worm, yeast | fly and fish experiments had no taxon |
| tools: MP, SO, PR and GO function/component terms; local `BLN:` terms; claims that end at a phenotype; condition contexts ("in C9orf72 carriers") | grounding and chains that end before the disease |
| tool bug: markup stripping deleted text from "P<0.001" to the next tag | hypothesis-agent's own quote checker (`checks._plain`) has the same regex |

`lake build BioLean BioLeanLib IPFRuns` passes; the textbook libraries were not rebuilt.

### Results

Full tables: `data/ipf/report.md`. By model, over 70 runs:

| model | runs | steps | expressible | citations that state their step | step links by label | after grounding | claims with a route | mean best belief |
|---|---|---|---|---|---|---|---|---|
| gemini-3.1-pro | 33 | 277 | 96% | 32% | 132/189 | 104/189 | 93/156 | 0.08 |
| deepseek-v3.2 | 17 | 138 | 63% | 28% | 38/86 | 10/86 | 23/96 | 0.17 |
| gpt-5.6-sol | 9 | 106 | 91% | 31% | 11/73 | 28/73 | 36/59 | 0.09 |
| claude-opus-5 | 9 | 146 | 95% | 38% | 14/107 | 21/107 | 29/64 | 0.11 |

- **Two thirds of citations do not state the step they are cited for**: 481 of 1,464
  citation-step pairs do (33 percent). By source (counting entries): UniProt 58 percent, papers 45, AGR 25, Open Targets 22, GWAS rows 21, STRING 18,
  Reactome 0 (every Reactome citation is a gene-set enrichment), ChEMBL 0.
- **The run's confidence label carries no information.** Claims the runs rated "high" have a mean
  best belief of 0.06, "medium" 0.14, "low" 0.11.
- **No hypothesis is established.** Of 385 claims, 188 have a route; the best arm is under 0.2
  for 154 of them. The 5 "established" arms are single database facts about a gene and a phenotype
  or process, 4 of them mouse knockout annotations; none reaches a disease.
- **Grounding does not rescue the chains.** Consecutive steps that share a node: 201 of 469 by
  label, 167 after grounding. Gemini's label links drop (some were compound or vague labels), GPT's
  rise. The chains are disconnected in substance, not only in naming.
- **Signs.** 19 claims have an arm whose computed sign differs from the hypothesis.
- **DeepSeek leaves 46 percent of its steps unsigned and 36 percent uncited** (GPT: 18 and 1).
  Two DeepSeek runs have nothing expressible at all.
- **The shared library finds contradictions between runs.** 97 claims are stated in more than one
  run; 8 have opposite signs:

| claim | + | − | the evidence |
|---|---|---|---|
| INPP5D → PI3K/AKT signalling | DeepSeek | Opus, GPT (0.8 each, UniProt) | −; DeepSeek's own UniProt citation refutes it |
| MS4A4A → TREM2 amount | GPT (0.23) | Opus (0.79), Gemini ×3 (0.7) | − |
| mucociliary clearance → IPF risk | Gemini IPF r2 | Gemini IPF r3 (0.5) | −; one model, two replicates, both signs |
| TREM2 → AD severity | one GPT run | the same run | both signs in one run |

### What it means for hypothesis-agent

Findings by theme (1,488 findings about hypothesis-agent, including 43 that bear on both projects).
Agents grouped them: five coders each took a batch and named themes from the detail text, then one
agent per project merged the themes. Every finding is in exactly one theme (checked in code). Raw
groups in `data/ipf/findings/`. "Most from" counts findings, and Gemini has the most runs (33).

| theme | findings | runs | most from | example | fix |
|---|---|---|---|---|---|
| Chain does not reach the disease | 249 | 67 | DeepSeek 77, Gemini 70 | IPF run: H1.1 ends at ER stress, H1.2 restarts at TOLLIP and H1.3 starts at 'proteotoxic stress', so TOLLIP has no route to IPF. | Validate that each step's object is the next step's subject, that the last node is the disease CURIE, and that the last step is not one of the disease's own defining features; reject chains that fail. |
| Good evidence sits at no step | 146 | 52 | Gemini 51, Opus 46 | IgA nephropathy run: rs6677604 and the Cfh-mutant glomerulonephritis annotation bear on CFH to disease, a link no step makes, so they support nothing. | Reject supporting citations that are not attached to a step, and when a source states a link between two run entities, offer that link as a step. |
| Database records cited as causal steps | 145 | 55 | Gemini 81, Opus 24 | IgA nephropathy run: a Reactome 'Complement cascade' over-representation (2 of 163 entities) is cited as evidence that CFH inhibits complement. | Tag every source with a record type and allow each type only on the step kinds it can state (for example gene-level records only on gene-to-disease steps, enrichment and expression never on causal steps). |
| Cited text does not state the step | 144 | 57 | Gemini 66, Opus 29 | Crohn run: PMID:36076306 is about stem cells primed with KYNA and IFN-gamma acting through IDO-1, not a kynurenic acid-GPR35 axis. | Require a verbatim quote span per step and check automatically that the quote is in the source and names both the subject and the object. |
| Node grounding and typing errors | 116 | 63 | Gemini 44, DeepSeek 35 | Alzheimer's run: every node has an empty CURIE except the disease, written as the malformed 'EFO:MONDO_0004975'. | Ground every node through an ontology lookup that sets the CURIE and kind, and reject empty, malformed or compound nodes. |
| Counter-evidence missing or misfiled | 104 | 56 | Gemini 40, Opus 28 | Schizophrenia run: GWAS:C1QA:no-association is listed as supporting and also as contradicting H1. | Run a counter-evidence search per step in the tool, check every contradicting accession resolves in sources.json, and reject a citation listed as both support and contradiction. |
| Gene coverage, budget and abstentions unchecked | 91 | 50 | DeepSeek 40, Gemini 38 | Alzheimer's run: H3 cites 'GWAS:LPIN2:no-association' and H2 'AGR:MGI:1913860:no-phenotypes', neither in sources.json, so neither can be checked. | At the end of a run, check every input gene is in a step or a valid abstention, check abstention accessions resolve in sources.json, and fail runs below budget. |
| Steps left unsigned | 82 | 47 | Gemini 38, DeepSeek 32 | Schizophrenia run: 'Sensorimotor gating deficit associated with schizophrenia' has polarity 'unknown' though the label implies one, so H5 has no route. | Make polarity a required field, allow 'unknown' only with a stated reason, and reject 'associated_with' inside causal chains. |
| Confidence labels overstated | 82 | 50 | Gemini 27, DeepSeek 20 | Schizophrenia run: almost every entity has an empty CURIE, yet every hypothesis says support 'grounded'. | Compute confidence and support from chain connectivity and the share of steps with a checked quote, instead of taking the model's label. |
| GWAS variant and allele handling | 75 | 37 | Gemini 40, GPT 17 | Schizophrenia run: a C4/MHC risk variant carries an OR, but nothing states whether the allele raises or lowers C4A, so the gene-level sign is assumed. | Add a required variant-to-gene step type with risk allele, mapped-gene method (eQTL, coding, position) and effect direction, and allow GWAS rows only on that step and variant-to-disease. |
| Mechanism prose beyond the sources | 62 | 37 | Gemini 24, Opus 17 | Mechanism prose gives IL23R signalling straight through TYK2, skipping IL12RB1, which no cited record supports. | Generate the mechanism text from the chain steps, or require each prose sentence to point to a step and its quote. |
| Signs unsupported or contradictory | 54 | 28 | Opus 20, Gemini 13 | Knockout phenotypes encoded as the gene's own effect, so a loss-of-function step on a bare gene subject composes to the opposite of the mechanism. | Compute the composed chain sign in the tool and reject hypotheses whose stated direction differs; require the sign to come from the step's quote. |
| Falsification tests misdesigned or not new | 53 | 39 | DeepSeek 24, Gemini 23 | A hypothesis and its falsification test restate a retrieved paper's title and its already-reported experiment. | Make the falsification test point to a chain step id with an expected direction taken from that step's sign, and check it against retrieved paper titles for novelty. |
| Evidence from the wrong context | 45 | 32 | Gemini 26, Opus 8 | Schizophrenia run: H2.2's object is first-episode psychosis, broader than schizophrenia (66 of 113 later diagnosed). | Add required species, tissue, disease and aspect fields per step and compare them with the source's metadata, flagging mismatches. |
| One-offs and non-defects | 40 | 27 | Gemini 21, DeepSeek 17 | Curator note that a low-confidence label matched weak evidence, or that abstention on decoy genes was honest. | Normalise source ids at fetch time, and keep positive curator notes out of the defect findings by giving them their own category. |

Every theme appears in runs from more than one model. The first four all go away with the same
structural change in the termination check: node ids, a path from gene to disease, a sign product,
and citations on steps with a quote that names both ends.

### What it means for BioLean

Findings by theme (585 findings), grouped the same way:

| theme | findings | runs | most from | example | fix |
|---|---|---|---|---|---|
| Missing terms and approximate grounding | 80 | 44 | DeepSeek 31, Gemini 21 | 'Tissue damage' has NCIT:C50773 and MPATH:1 in the corpus, but render.py accepts neither prefix, so the node is left ungroundable. | Give render.py kinds for NCIT, PW, MPATH and ECOCORE terms, split the SO mapping by term type, fix the bad corpus entries, and add a grounding field (exact, broader, BLN) on each node. |
| Taxon, species and study design on evidence | 55 | 36 | Gemini 23, Opus 15 | One mouse C4 result supports both human C4A and C4B statements, and the taxon flag cannot say the mouse gene is the ortholog of both, so the same quote counts twice. | Make taxon a structured field (source species, ortholog or paralogue mapping, unknown or inferred), allow a list of designs per span, and add a phenotype-species rule enforced by the checker. |
| Context, hierarchy and node grain | 49 | 38 | Gemini 25, Opus 9 | H1's only composed arm (INPP5D to Abeta clearance to AD) depends on merging 'plaque clearance' and 'microglial amyloid-beta clearance' as GO:0097242, borrowing H5.3. | Let composition follow refinement-to-base and is_a or part_of links with a discount, and record each split or merge as an explicit node mapping the report shows. |
| Variants and the variant-to-gene link | 48 | 32 | Gemini 20, GPT 11 | The APOE e4 allele is a two-SNP haplotype with no dbSNP ID, so it is recorded as one BLN variant and loses that it is a pair. | Add a variant node type (allele, haplotype, class, copy number) with a gene field and a declared effect (gain, loss, risk allele), plus a member-of or acts-through link that composes into gene-level routes. |
| Sign rules from wording and sources | 48 | 34 | DeepSeek 20, GPT 13 | 'LIPC leads_to lipid metabolism dysregulation (unknown)' matches both the unknown-polarity no_sign rule and the 'dysregulates X gives effect pos on abnormal-X' rule. | Encode the sign rules as one ordered table in the checker, with an explicit precedence and full loss-of-function word list, and require an allele-type field on model-organism evidence. |
| Relation and target kinds | 48 | 33 | Gemini 22, DeepSeek 13 | An associated_with step whose object is a cellular component has no assoc target, so it becomes a rel RO:0001025 (located in), which the relation table does not list. | Widen the allowed subject and target kinds per relation and add the missing relations (translocates, located-in) to the relation table in code. |
| Claim-level evidence and bridges | 42 | 31 | Gemini 14, DeepSeek 11 | PMID:42601455 (PLCG2 loss-of-function variants raise AD risk tenfold) has nowhere to go because no step states it and a bridge equal to the whole claim is not a bridge. | Add an evidence slot on claims (supports or refutes) and let definitions be a 'definitional' evidence kind on steps, separate from bridges. |
| Evidence-kind table gaps | 38 | 29 | Gemini 19, DeepSeek 9 | Open Targets association scores have no row; recorded as curatedDb on a first pass, one OT score alone made 'FAM13A goes with IPF' established. | Add those rows to the kind table in code, with a hedged or proxy modifier that lowers weight, and have the checker reject sources whose type has no row. |
| Abstentions and missing curated.json fields | 37 | 29 | Gemini 28, DeepSeek 7 | The run abstains on RBM27 and SMIM32 citing six accessions (GWAS no-association, HPA, AGR) that are not in sources.json, so the abstention cannot be checked. | Add an abstention block (genes, reason, cited accessions) and the missing exclusion fields to the curated.json schema, and make sources.py fetch every accession the run cites anywhere. |
| Kind weights ignore strength | 33 | 28 | Gemini 14, Opus 11 | STRING C3-ARMS2 counts as curatedDb because its experimental channel (0.24) clears 0.15, though text-mining (0.62) supplies most of the 0.70 score, and it reaches belief 0.8. | Weight evidence by strength (sample size, p-value, STRING channel that drives the score), cap a single database record below the established threshold, and apply the taxon discount in the fusion. |
| Unsigned, null and per-gene claims and verdicts | 30 | 22 | Opus 9, DeepSeek 8 | An MGI 'no abnormal phenotype detected' record (MP:0002169) is a null with no named phenotype and cannot refute a specific phenotype step. | Allow unsigned and null claims and statements, weigh null records separately, allow per-gene no-claim reasons, and add verdict labels (partial, refuted, unsigned, disconnected) to the report. |
| Binding, complexes and interactions | 24 | 17 | Gemini 11, Opus 5 | IL12B acts through the IL-23 heterodimer binding IL12RB1 and IL23R; with no complex node it was recorded as IL12B interacting with IL23R. | Add a complex node with member genes, let binds compose when a cited text gives a direction, and add a modifier or conditional-effect statement form. |
| Claim construction and disease aspect | 22 | 21 | Gemini 9, DeepSeek 8 | 'Exacerbating IgA glomerulonephritis' fits both severity and progression in the aspect table; the curator chose severity and the audit chose progression. | Derive claim subject, sign and aspect from the chain in code with a checked override field, and add an aspect field to evidence so routes compose only across matching aspects. |
| Pipeline tool gaps | 16 | 13 | Gemini 6, Opus 5 | sources.json gives OT:NXPH3 only the 'chain' role though run.json also lists it in H3's contradicting_evidence. | Let sources.py store a list of cited_as roles and parse contradicting_evidence, check every evidence ref against the run's citations, render notes, search synonyms in terms.py, and drop unsigned_association. |
| Double counting of shared sources | 15 | 14 | Opus 5, DeepSeek 4 | distinctEvidence keeps one item per PMID regardless of polarity, so S5's refuting Q8IV20 span is dropped and S5 fuses to b=4/5, d=0. | Add a provenance or source-group key to evidence, fuse within a group once, and make distinctEvidence key on (source, polarity) rather than source alone. |

My notes on these:

- **Weights are your call** (program 10a on main). curatedDb (0.8) equals the establishment
  threshold, so one UniProt sentence or one mouse knockout establishes a claim. Mouse evidence fails
  the taxon lint but still counts toward the verdict. Human co-segregation (lod 11) is only
  "observational" (0.5).
- **One theme found a bug, now fixed.** `distinctEvidence` kept one item per paper or record
  whatever its polarity, so a record that both supports and refutes lost its refutation. It now
  keeps one per (record, polarity). Main has the same rule for PMIDs. Two statements changed:
  LACC1 → cytokine production went from established (0.8) to contested (0.44 / 0.44).
- **Null results** are now an open decision in `STATUS.md` on main (branch `todo/null-results`).
- Several themes are about my tools (`render.py`, `sources.py`, the guide), not the Lean core:
  missing prefixes, abstentions, sign-rule precedence, pipeline gaps.

### Cost

One curator or auditor agent used about 73k output tokens, so about 150k per run, and 10M for the
whole set. Fine for a study, too dear to run on every hypothesis-agent result. A production check
would keep the automatic part (sources, quote check, composition, Lean) and replace the agent with
a cheaper model plus the checks above in hypothesis-agent itself.

### Caveats

Curation is by agents, calibrated on one run and audited once. Themes were grouped by agents,
once, and not checked by a second pass. The 1,282 notes on the curation guide itself are not yet
folded into a version 3.

## Next, if this continues

- Fix the hypothesis-agent side first: node ids, the path and sign check, and citations on steps,
  all in the termination check. Every theme above shrinks with them.
- Decide the weights (curatedDb against the threshold; mouse evidence on human claims) with
  program 10a.
- Add claim-level evidence and nulls (`noEffect`) to the format and composer.
- Merge with main: main added `Claim.homeostasis`; this branch adds `Claim.assoc` and
  `DiseaseAspect`, so `Claim.lean` needs a hand merge.

## Rerun

```bash
uv run python scripts/ipf/sources.py --all                     # needs the IUK-IPF store and corpus
uv run python scripts/ipf/render.py --all --lean               # check, compose, elaborate every curated run
uv run python scripts/ipf/report.py > data/ipf/report.md
lake build IPFRuns BioLean.Examples.IPF                        # the whole set as one library
```
