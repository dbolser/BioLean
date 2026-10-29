# Side quest: BioLean checks a hypothesis-agent run (IPF)

Started 2026-10-28, on branch `side-quest/ipf-bridge` (worktree `../BioLean-ipf`). Not part of the
ROADMAP milestones. It tests whether BioLean is useful to the IUK-IPF grant
(`/home/danbolser/Work/IUK-IPF`).

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

## What this means for IUK-IPF

1. Using BioLean as a checker is feasible. One run took one session, including the core changes.
2. The largest error it finds is citation fit: 9 of 23 citations do not state the step they are
   cited for. Two of the 13 that do are also moved to another step of the same hypothesis that
   they state better. hypothesis-agent's `verify` checks that a citation resolves and names the entity, not
   that it states the edge.
3. hypothesis-agent should emit connected chains (shared node ids). BioLean could reject a set
   that doesn't. That is a cheap structural check before any scoring.
4. BioLean needs a signed **genetic association** claim (variant, allele, effect size) before it is
   useful for target assessment. Most target evidence is genetic, and today it all falls into
   "not expressible".
5. "Type-checks, with belief b" could be a KARL reward that is not an LLM judge. Not tried.

## Next, if this continues

- Add an association claim (allele-specific, signed by OR, with mortality as a separate target)
  and re-express H3.3, H4.2, H4.3. Then genetics can fuse with mechanism. The relations already
  exist in the imported RO (`BioLean/RO.lean`), so nothing needs hand-crafting:
  RO:0003308 *correlated with condition* (unsigned), RO:0019501 *confers susceptibility to
  condition* (risk), RO:0003307 *ameliorates condition* (protective), RO:0003305 *contributes to
  severity of condition* (the TOLLIP mortality case). SO supplies the variant types (SO:0001060
  sequence_variant, SO:0001023 allele) but not associations. What is new is a Lean constructor
  that carries the numbers RO cannot: allele, odds ratio, CI. Plus a discounted bridge rule from a
  signed association to `v →± disease`, because association is not causation (linkage
  disequilibrium, reverse causation).
- Use `transport` for the mouse evidence (I4) instead of only flagging it.
- Make the step-to-statement translation automatic: a hypothesis-agent result → candidate
  `curated.json`, with a human or agent doing only the quote check. Run it over the IPF study runs
  in the store (about 20) and compare models by computed belief, not by their own confidence labels.
- Ask Georgina or Elena whether the dropped citations and the DSP sign prediction match expert
  reading.

## Rerun

```bash
uv run python scripts/ipf/01_sources.py      # needs the IUK-IPF store and corpus
uv run python scripts/ipf/02_render_lean.py  # checks, then writes BioLean/Lib/IPF.lean
lake build BioLean.Examples.IPF              # theorems; prints the reports
```
