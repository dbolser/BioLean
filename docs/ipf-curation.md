# Curating a hypothesis-agent run for BioLean

How to turn one hypothesis-agent run into `data/ipf/runs/<run>/curated.json`, which
`scripts/ipf/render.py` checks, composes and renders as Lean. Part of the IPF side quest
(`docs/side-quest-ipf.md`). Version 2 (2026-10-30), revised after a six-run pilot.

The job is to test what a run **claims** against what it **cites**. You are a careful curator, not
a co-author. Never repair a hypothesis: a missing link, a flipped sign or a citation that says
nothing is the result, so record it.

## Files and commands

| file | what |
|---|---|
| `data/ipf/runs/<run>/run.json` | the run: question, model, hypotheses with their chains of steps |
| `data/ipf/runs/<run>/sources.json` | every accession the run cites, with the exact text the agent saw, and `cited_as`: `chain`, `supporting` or `contradicting` |
| `data/ipf/runs/<run>/curated.json` | what you write |

```bash
uv run python scripts/ipf/terms.py "endoplasmic reticulum stress" --kind process  # label table only
uv run python scripts/ipf/terms.py "abnormal spatial learning"                   # label table, then every ontology title
uv run python scripts/ipf/terms.py endosome --prefix GO                          # titles under one prefix (GO components, MP, SO, PR)
uv run python scripts/ipf/terms.py GO:0034976                                    # a CURIE: label and definition
uv run python scripts/ipf/render.py data/ipf/runs/<run> --lean                   # check, compose, elaborate in Lean
```

`render.py` lists every problem at once. Fix them and run it again until it ends `Lean: ok`.
Only write inside your own run directory (`render.py` also writes the run's Lean module; that is
expected). Do not run `lake build`.

Step ids are `<hypothesis_id>.<n>`, counting from 1 along the chain: `H1.2`, `hyp1_ADAR.3`.

## The format

```json
{
 "run_id": "20260824T223623Z-4f7d1a",
 "curated_by": "<model>, <date>",
 "entities": {
  "rs35705950": {"kind": "variant", "curie": "dbSNP:rs35705950", "label": "rs35705950 T allele (MUC5B promoter)",
                 "run_labels": ["MUC5B promoter variant rs35705950"]},
  "MUC5B": {"kind": "protein", "curie": "UniProt:Q9HC84", "run_labels": ["MUC5B mucin", "ectopic MUC5B expression"]},
  "erStress": {"kind": "process", "curie": "GO:0034976", "run_labels": ["endoplasmic reticulum stress in bronchiolar epithelium"]},
  "at2": {"kind": "cellType", "curie": "CL:0002063"},
  "cellularSenescence": {"kind": "process", "curie": "GO:0090398"},
  "at2Senescence": {"kind": "process", "refines": {"base": "cellularSenescence", "ctx": {"cellType": "at2"}}},
  "pulmonaryFibrosis": {"kind": "disease", "curie": "MONDO:0002771"},
  "ipf": {"kind": "disease", "curie": "MONDO:0800504"}
 },
 "statements": [
  {"id": "S1", "step": "H1.1", "text": "rs35705950 raises MUC5B",
   "claim": {"effect": {"subject": "rs35705950", "sign": "pos", "target": {"amount": "MUC5B"}}},
   "evidence": [{"ref": "PMID:27630174", "kind": "review", "quote": "a common gain-of-function promoter variant in MUC5B rs35705950"}],
   "excluded": [{"ref": "PMID:21506741", "category": "not_in_text", "reason": "expression in IPF lung, not by genotype"}]},
  {"id": "S2", "step": "H1.4", "text": "ER stress drives pulmonary fibrosis",
   "claim": {"effect": {"subject": "erStress", "sign": "pos", "target": {"disease": "pulmonaryFibrosis", "aspect": "risk"}}},
   "evidence": [{"ref": "PMID:41090357", "kind": "mechanistic", "taxon": "mouse",
                 "quote": "selective inhibition of RIDD with PAIR2 reduced AT2 differentiation into profibrotic transitional cells and protected mice from bleomycin-induced pulmonary fibrosis"}],
   "excluded": []},
  {"id": "S3", "step": "H3.3", "text": "the rs5743890 minor allele goes with lower IPF risk",
   "claim": {"assoc": {"subject": "rs5743890", "direction": "neg", "target": {"disease": "ipf", "aspect": "risk"}}},
   "evidence": [{"ref": "PMID:24429156", "kind": "observational", "quote": "<verbatim span>"}], "excluded": []}
 ],
 "unexpressed": [
  {"step": "H5.1", "category": "set_valued", "reason": "claims the six genes form no module: a claim about the set, not each member",
   "evidence": [], "excluded": []}
 ],
 "hypotheses": {
  "H1": {"claims": [{"subject": "rs35705950", "sign": "pos", "target": {"disease": "pulmonaryFibrosis", "aspect": "risk"}}],
         "note": "the chain ends at pulmonary fibrosis, not IPF"},
  "H5": {"no_claim_reason": "says the genes do not form a module; not a causal claim"}
 },
 "findings": [
  {"project": "hypothesis-agent", "category": "chain_not_connected", "steps": ["H1.1", "H1.2"],
   "detail": "H1.1 ends at 'MUC5B mucin', H1.2 starts at 'ectopic MUC5B expression'; same node, different labels"},
  {"project": "hypothesis-agent", "category": "confidence_unjustified", "hypothesis": "H2", "detail": "..."}
 ]
}
```

A statement's `step` may be a list when hypotheses repeat the same step (`["H1.1", "H4.2"]`).
Statement ids are yours: `S1`, `S2`, ... is fine.

## Entities: grounding, and deciding what is the same node

Every entity needs a CURIE that `terms.py` finds. Never guess one.

| thing | prefix | kind |
|---|---|---|
| gene or protein | `UniProt:` (search the gene symbol) | `protein` |
| biological process, pathway | `GO:` biological process | `process` |
| molecular function / cellular component | `GO:` (`terms.py <words> --prefix GO`) | `function` / `component` |
| phenotype, measurement, trait | `HP:`; `MP:` for a mouse phenotype; `PATO:` for a quality | `phenotype` |
| disease | `MONDO:` | `disease` |
| cell type | `CL:` | `cellType` |
| tissue, organ, life stage | `UBERON:` | `anatomy` |
| drug, metabolite | `CHEBI:` | `chemical` |
| a variant type | `SO:` | `variant` |
| one variant | `dbSNP:rs…` with a `label` naming the allele the claim is about | `variant` |
| a class of variants with no ID | `BLN:<Gene>-<description>` with a `label` | `variant` |
| a Reactome pathway with no fitting GO process | `Reactome:R-HSA-…` with a `label` | `process` |
| anything else no ontology has | `BLN:<CamelCaseSlug>` with a `label` and `why_no_term` | any |

Labels come from the corpus, so give a `label` only for the unchecked prefixes (`dbSNP`, `BLN`,
`Reactome`, `ClinVar`, `HGNC`). Record the run's own labels in `run_labels`.

**Local `BLN:` terms.** When a node matters to a chain and no term exists (R-loops, nuclear
mechanical integrity, tRNA fragments), make a `BLN:` term rather than drop the step. Put what you
searched in `why_no_term`, and add a `missing_term` finding that names it. A `BLN:` term is a node
only within its run, so use one only when nothing in any ontology fits.

**Variants and alleles.** A `dbSNP:` entity stands for one allele. Name it in the `label`
("rs35705950 T allele"), and give every claim about it the direction of that allele. If a source
names a different allele, convert the direction to the allele in your label.

**Same node or not.** The run names things in free text, and its chains link only where one step's
object is the next step's subject. Your main judgment is which labels denote the same entity. Merge
them when they are the same thing at BioLean's grain:

- "MUC5B mucin", "ectopic MUC5B expression" and "MUC5B over-expression" are all `MUC5B`. The
  "amount" or "activity" part goes in the target (`amount`, `activity`), not in the entity.
- "EMT via Hippo/YAP" is `emt`. A mechanism named in passing is not a separate node.
- A gene and its own product are one node (UniProt). "MUC5B gene increases MUC5B protein" restates
  expression: `unexpressed`, `not_causal`.
- A qualifier ("in bronchiolar epithelium") is dropped unless it is the point of the step, or the
  step's `context` or `note` limits the result to it ("muscle and heart only"). Then use a
  refinement. A refinement is a different node from its base, so chains connect through it only
  where both steps use it.
- Do not merge different things to make a chain connect. "Telomere maintenance" and "short telomere
  length" are different nodes.

**Refinements.** `{"kind": ..., "refines": {"base": <entity>, "ctx": {...}}}`, with ctx fields:
`cellType`, `anatomy`, `component`, `stage` (a GO process), `lifeStage` (UBERON), `taxon`
(`human`, `mouse`, `rat`, `zebrafish`, `fly`, `worm`, `yeast`), and `condition`: an entity for a
genotype or disease background ("in C9orf72 repeat carriers", "in systemic sclerosis"). A claim that
holds only in carriers is a claim about the refined subject.

**Compound and set-valued labels.**

- A compound subject or object ("EMT and ER stress", "cytokine secretion and bacterial clearance")
  is two steps in one. Split it into one statement per part, with the same `step`. If one part
  cannot be expressed, the step gets both a statement and an `unexpressed` entry. That is fine.
- A short list of genes that each do the thing ("C1QA and C4A/C4B activate complement") reads
  distributively. Split it into one statement per gene.
- Use `set_valued` only when the claim is about the set as a whole ("the six genes form no
  module"), or the members' parts cannot be separated.

**Loss-of-function wording.** "Loss of X", "reduced X", "impaired X", "X deficiency" → the entity
is X and the sign is inverted: "loss of TREX function leads to R-loops (+)" becomes
`TREX →− R-loops`. Write a `sign_note` ("inverted: the run's subject is loss of X"). That is not a
sign change, so it is not a finding.

## Statements: one per expressible step

```json
{"effect": {"subject": "<entity>", "sign": "pos|neg", "target": {"<kind>": "<entity>"}}}
{"assoc":  {"subject": "<entity>", "direction": "pos|neg|none", "target": {"<kind>": "<entity>"}}}
{"rel":    {"relation": "RO:0002436", "a": "<entity>", "b": "<entity>"}}
```

Target kinds: `amount` (protein, chemical), `activity` (protein, function), `process`,
`phenotype`, `site` (anatomy), and `disease` with `aspect`:

| aspect | the step or claim is about | words |
|---|---|---|
| `risk` | getting the disease | risk, susceptibility, predisposes, causes, onset, incidence |
| `severity` | how bad it is once you have it | severity, extent, aggravates, worsens a feature |
| `progression` | how fast it gets worse, or the outcome | progression, decline, exacerbation, mortality, survival, modifier of course |

| run relation | statement |
|---|---|
| `increases_amount` / `decreases_amount` | effect, `pos` / `neg`, target `amount` |
| `activates` / `inhibits` | effect, `pos` / `neg`; target `activity` for a protein, otherwise the object's kind |
| `leads_to` | effect with the step's polarity; target by the object's kind |
| `required_for` | effect, `pos` (losing the subject lowers the object); say so in `text` |
| `binds` | `rel` RO:0002436 (molecularly interacts with) |
| "X expressed in cell type / tissue" | `rel` RO:0002206 (expressed in) |
| `associated_with` | `assoc`, see below |
| `leads_to` with `unknown` polarity | effect only if a cited text gives the direction (`sign_note`), else `unexpressed`, `no_sign` |

**The sign is the run's.** Write the sign the step states (after the loss-of-function inversion).
Never change a sign to make an arm agree with its hypothesis. A flipped arm is a result.

**Associations.** An `associated_with` step is an `assoc` statement. Its `direction` is the step's
polarity if it has one. Otherwise, if a text the run cited for the step gives the direction for the
step's subject, use it and add a `sign_note`. Otherwise it is `none`. An unsigned association is
still a statement: it keeps its evidence, it just cannot compose. A GWAS row that names an allele and
an odds ratio or beta gives the direction for that allele. Quote the row's lines. A signed
association composes into an arm through `fromAssoc`, discounted: by half for a variant, by four
fifths for anything else, because association is not causation.

**Undirected change.** "Leads to abnormal X" or "dysregulates X" has no sign on X. If an
"abnormal X" phenotype term exists (`HP:`, `MP:`), the step is an effect, `pos`, on that phenotype.
Otherwise it is `unexpressed`, `no_sign`.

## Evidence: does the cited text state the step?

For each accession a step cites, read its `text` in `sources.json`. Keep it only if the text states
the step: both ends (synonyms are fine) and, for an effect, the direction. Quote the shortest
verbatim span that does. The checker ignores case, whitespace and markup, nothing else.

- A citation may support more than one step: list it under each, and add `"moved_from": "<step>"`
  to any copy that is not under the step that cited it.
- A citation may move to any step of the run whose claim it states better (`moved_from`).
- If the text states the **opposite** direction, keep it with `"polarity": "refutes"`.
- The run's `contradicting` citations (see `cited_as`): read them. Attach each to the statement it
  bears on, with `"polarity": "refutes"` where it states the opposite, or reports a null result for
  that subject and target ("no association"). Otherwise exclude it.
- `supporting` citations no step cites: attach them where they state a step, otherwise add a
  finding (`citation_at_no_step`).
- Unexpressed steps take `evidence` and `excluded` too. Judge their citations the same way, so the
  counts include them.

Exclusions, each with a `category` and a one-line `reason`:

| category | when |
|---|---|
| `not_in_text` | the text does not state the step |
| `not_this_entity` | it states the step for a different gene, variant, cell or disease |
| `parent_disease` | it states the step for a broader disease (pulmonary fibrosis, for an IPF step) |
| `undirected` | it names both ends but gives no direction, for a signed step |
| `no_direction` | the record type cannot carry a sign (STRING edge, OT score, expression level, an MGI 'abnormal X' annotation) |
| `association_only` | it reports an association, and the step claims an effect |
| `disease_feature` | it says the object is a feature or hallmark of the disease, not that it causes it |
| `enrichment` | a gene-set or pathway over-representation result |
| `no_text` | the source has no text to check |
| `other` | say why |

**Evidence kind** is the design behind the **quoted span**, not the paper type:

| the quoted span | kind |
|---|---|
| summarises other work: a review, or a background or introduction sentence | `review` |
| an in vivo perturbation (knockout, drug, transgenic) | `mechanistic`, with `taxon` if not human |
| cells or tissue in a dish, organoids, iPSCs | `inVitro` (with `taxon` if not human) |
| an association, GWAS, expression difference, cohort, family co-segregation | `observational` |
| a randomised trial | `rct` |
| a meta-analysis of trials or experiments (pooled observational studies stay `observational`) | `metaAnalysis` |
| a paper proposing the step without testing it | `hypothesis` (recorded, no weight) |
| UniProt function text, Reactome pathway membership, ChEMBL mechanism | `curatedDb` |
| UniProt text marked "By similarity", or inferred from another species | `crossSpecies` |
| AGR / MGI curated annotation of a model organism | `curatedDb`, with `taxon` |
| STRING edge, for a `binds` statement only, with experiments or database channel ≥ 0.15 | `curatedDb` |
| STRING edge with only text-mining | `textMined` |
| a GO, HP or MONDO definition from the corpus (bridges only) | `textbook` |

`taxon` goes on evidence from another organism than the claim's. The lint then flags the mismatch.
That is intended: it is the gap `transport` exists for.

## Steps BioLean cannot express

Every step is at least one statement or one `unexpressed` entry. Categories:

| category | when |
|---|---|
| `no_sign` | a causal step with no direction anywhere |
| `set_valued` | about a set as a whole |
| `compound_entity` | a part that cannot be split out |
| `ungroundable` | no term, and a `BLN:` term would not help (the node is vague, not missing) |
| `evidence_does_not_test_step` | the step is a claim about a trial or test the cited record does not report |
| `not_causal` | a definition, a restatement, a gene and its own product |
| `other_construct` | the claim needs a form BioLean lacks; say which in `reason` |

An expressible step whose every citation is excluded is still a **statement**, with
`"evidence": []`. A claim with no support is a result, not a gap in BioLean.

## Hypotheses: what each one claims

`claims` lists the effects the hypothesis asserts, one per gene it is about:

- **Subject**: the gene or variant the hypothesis is about, as the node its chain starts from. If
  the chain starts at the variant, use the variant; if it starts at the protein, the protein (and a
  note if the title names variants). If the chain starts at another gene's insult (C9orf72), use
  the hypothesis's own gene.
- **Sign**: of the gene's overall effect, as the title or mechanism states it. "Loss of X causes
  the disease" is `neg`. With no direction stated, give `no_claim_reason`.
- **Target**: `{"disease": ..., "aspect": ...}` for the disease the chain concludes. If it differs
  from the run's question (pulmonary fibrosis rather than IPF), add a `note` and a `wrong_disease`
  finding. If the chain never reaches the disease and ends at a phenotype or process ("motor neuron
  degeneration"), add a second claim targeting that end node, and a `chain_ends_at_phenotype` finding.

`render.py` composes every route of statements from each claim's subject to its target, across the
whole run: statements are a shared library, so a hypothesis may borrow another's step (the report
counts these). It flags a route whose sign differs from the claim, and reports `no route`. Both are
findings. Do not repair them.

Lean then computes each arm's belief and a verdict: `established` needs belief ≥ 0.8.

## Bridges

A bridge is a statement the run never made, which an arm needs to compose: `"step": "bridge"`,
`"for": ["<hypothesis_id>"]`. Add one only when:

- a GO, HP or MONDO definition states the link itself, in the direction needed (quote it, kind
  `textbook`; `terms.py <CURIE>` prints it), or
- a text the run cited states it.

Never add a bridge from your own knowledge. A "characterized by" definition (ALS is characterized
by motor neuron degeneration) is a feature, not a cause: no bridge. The phenotype claim above covers
that case. If the link has no source, leave the claim without a route.

## Findings

Record problems for either project as you meet them: `project` (`hypothesis-agent`, `biolean`, or
`both`), a short `category` slug, `steps` or `hypothesis`, and a one-sentence `detail`. Gaps in the
format or tools are findings too (project `biolean`). Typical categories:

- **hypothesis-agent:** `chain_not_connected`, `sign_flip`, `citation_does_not_state_step`,
  `citation_states_opposite`, `wrong_disease`, `chain_ends_at_phenotype`, `ungrounded_label`,
  `no_citation`, `citation_at_no_step`, `confidence_unjustified`, `contradicting_evidence_ignored`.
- **biolean:** `missing_term`, `no_form_for` (say what), `rule_missing`, `kind_mismatch`,
  `evidence_kind_missing`, `evidence_weighting`.

Anything that surprised you, or that the format could not hold, is a finding.

## Upgrading a version-1 curation

Pilot runs were curated under version 1. To upgrade: turn `unsigned_association` entries into
`assoc` statements; rename `set_valued_subject` to `set_valued`; replace `excluded` categories with
the table above (`parent_disease`, `undirected`, `disease_feature`, `enrichment` are new); judge
the newly fetched `contradicting` citations; make `BLN:` terms for `ungroundable` nodes that are
missing rather than vague; add phenotype claims for chains that end at a phenotype; move
`unexpressed` citation judgements from free text into `evidence` / `excluded`. Keep everything
else.
