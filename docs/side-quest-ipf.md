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
  for 153 of them. The 5 "established" arms are single database facts about a gene and a phenotype
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

Findings by theme (1,446 findings; counts are approximate, clustered by category):

| theme | findings | runs | fix (structural, in the harness) |
|---|---|---|---|
| citation does not state its step | 312 | 65 of 70, every model | run `checks.py` direction check on every result; reject a step whose citations are only association scores, enrichments or expression |
| chain does not connect, or never reaches the disease | 260 | 66 | node ids in `CausalStep`; the termination check rejects a chain whose object ≠ next subject, or that never reaches the disease (`ModelRetry` gives the reason) |
| labels: ungrounded, wrong kind or disease, a feature cited as a cause | 136 | 65 | run `formalise` on every result; no free-text compound nodes |
| citation on no step, or the wrong step | 113 | 44 | the termination check: every supporting citation must sit on a step |
| signs flipped, unknown, or only implied | 111 | 60 | sign-product check against the hypothesis's stated direction; require a sign when a cited text gives one |
| contradicting evidence ignored | 110 | 55 | contradicting evidence as accessions, not prose; a citation listed as support that states the opposite fails |
| confidence label not justified | 89 | 57 | compute confidence from the evidence, or drop the label |
| genes left unexplained, budget not met | 72 | 46 | |
| falsification inconsistent with the chain | 42 | 32 | the perturbation's action must match the falsification text |
| variant-to-gene attribution | 21 | 15 | |

All are current and none is specific to one model, though rates differ (DeepSeek for unsigned and
uncited steps, Gemini for flipped signs through linked chains).

### What it means for BioLean

Findings by theme (627 findings, keyword-clustered, approximate). What I would do about each:

| theme | findings | what to do |
|---|---|---|
| evidence weighting | 87 | **Dan's call; see program 10a on main.** curatedDb (0.8) equals the establishment threshold, so one UniProt sentence or one mouse knockout establishes a claim. Mouse evidence fails the taxon lint but still counts toward the verdict. Human co-segregation (lod 11) is only "observational" (0.5), below a mouse paper's background sentence |
| missing ontology terms | 76 | 66 local `BLN:` terms: R-loops, nuclear mechanical integrity, telomere damage, tRNA fragments. An ontology gap, not BioLean's |
| evidence kinds | 56 | a mixed-design abstract has one kind; no kind for an Open Targets score, "By similarity", or an unstated system. Fits the open ECO decision |
| null results and claim-level evidence | 55 | a null GWAS or "no abnormal phenotype" has no statement to refute when no step reaches the disease. `Claim.noEffect` exists; the curation format and composer need it, and evidence attached to a hypothesis claim |
| undirected change ("abnormal X", "required for normal Y") | 52 | an unsigned effect, or "abnormal X" phenotype terms (MP has them, HP mostly not) |
| conditions and context | 50 | partly done (`condition`); still no cargo, target-gene or transcript slot ("TTN splicing") |
| variants and alleles | 47 | allele dosage (two copies), haplotypes, protein-change vs nucleotide naming |
| sets, families, complexes | 39 | split distributive lists (done); a complex as a target has no form |
| a feature or definition cited as a cause | 23 | MONDO "characterized by" is has_phenotype, not an effect: correct to refuse, but worth a `Claim.rel` |
| subsumption | 15 | no is_a step for disease or process targets (IPF ⊂ pulmonary fibrosis) |
| loops, modifiers, second hits | 12 | `Claim.homeostasis` on main covers negative loops; second hits and modifiers need a two-cause claim |

### Cost

One curator or auditor agent used about 73k output tokens, so about 150k per run, and 10M for the
whole set. Fine for a study, too dear to run on every hypothesis-agent result. A production check
would keep the automatic part (sources, quote check, composition, Lean) and replace the agent with
a cheaper model plus the checks above in hypothesis-agent itself.

### Caveats

Curation is by agents, calibrated on one run and audited once. Theme counts are clustered by
category keywords and are approximate. The 1,282 notes on the curation guide itself are not yet
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
