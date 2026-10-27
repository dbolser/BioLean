# Six formalisms, eleven papers

Written 2026-10-26. Six annotators each annotated the same eleven papers, in one formalism each,
without seeing each other's work. Shared brief: [BRIEF.md](BRIEF.md). Input:
[`data/formalisms/abstracts.json`](../../data/formalisms/abstracts.json). Five of the six
chemiosmotic papers have no abstract on record (scanned 1950s to 70s journals), so they were
annotated from labelled secondary-source summaries.

| formalism | file | size | IDs checked |
|---|---|---|---|
| GO-CAM / GAF extensions | [gocam.md](gocam.md) | 11 models | OLS4 + UniProt |
| INDRA Statements + BioContext | [indra.md](indra.md) | ~60 statements | OLS4, UniProt, HGNC, FamPlex |
| Biolink / Translator KGX | [biolink.md](biolink.md) | ~75 edges | biolink-model v4.4.6 + OLS4 |
| BEL 2.x | [bel.md](bel.md) | ~80 statements | OLS4 + UniProt (syntax unparsed) |
| Nanopublications + SEPIO | [nanopub.md](nanopub.md) | 49 nanopubs | OLS4; parses with rdflib |
| BioLean current schema | [biolean.md](biolean.md) | ~45 statements | OLS4; compiles with `lake env lean` |

## Fit, aspect by aspect

y = native slot, p = partial or by convention, n = free text only.

| aspect | GO-CAM | INDRA | Biolink | BEL | nanopub | BioLean |
|---|:-:|:-:|:-:|:-:|:-:|:-:|
| direction of effect | p | y | p | y | y | p |
| quantitative result | n | n | p | n | p | n |
| species / strain | p | p | p | p | p | p |
| age / stage | n | n | n | p | p | p |
| tissue / cell | y | y | y | y | y | p |
| disease model | n | p | p | p | p | n |
| dose / duration | n | n | n | p | p | n |
| hypothesis vs result | p | p | y | p | **y** | n |
| rival hypotheses | n | n | n | n | **y** | p |
| evidence type (ECO) | y | p | y | p | y | p |
| cross-species transfer | n | n | n | n | p | n |
| negative results | p | p | p | p | p | p |

Three things hold across every column.

1. **Nobody has dose, duration, age or strain.** Every formalism puts them in free text. These are
   the fields that decide whether an NMN result means anything, and no biology KG schema carries
   them. Biolink's `stage_qualifier` exists but only on gene-expression edges. There is no
   OLS-resolvable ID for C57BL/6N.
2. **Nobody has cross-species transfer.** Four of six silently merge mouse and human evidence for
   the same triple (INDRA pooling, Biolink "same edge more PMIDs", BEL, BioLean). The one formalism
   that can state it (nanopub, a species-free proposition with mouse and human evidence lines under
   it) has no term for *why* the transfer is discounted.
3. **The papers' key words have no terms.** "Sufficient", "alone", "no chemical intermediate",
   "restores to young", "partly via SIRT1", "augmented by exercise", "unchanged". Every annotator
   minted local terms for them. The decisive result of the whole controversy, Mitchell & Moyle's
   *uncouplers leave H+/O unchanged*, is a true null that only BEL (`causesNoChange`) writes natively.

## Which fits what

**Chemiosmotic papers.** These are about an argument, not a wiring diagram: two rival
hypotheses, experiments that support one and kill the other, a hypothetical molecule that never
existed. Only nanopub+SEPIO represents that structure natively (hypothesis vs finding typed in the
provenance graph, evidence lines marked supporting or disputing with ECO codes, `contradicts`
between assertions, and `supersedes` for "the state of play in 1971 vs 1974"). GO-CAM fits the
*accepted* mechanism very well and the *history* not at all: Slater's model is not just wrong, it
fails validation, because C~I has no identifier. INDRA, Biolink and BEL can all draw the arrows and
none can say two arrows are rivals. BioLean's `mediatedBy` with rival mediators plus
supports/refutes evidence gets the right verdicts out, but has no exclusivity link and no
`hypothesis` evidence kind, so Slater's own data-free paper keeps 0.23 belief in a refuted idea.

**NMN mouse papers.** These are context all the way down: which strain, how old, what diet model,
how much for how long, which tissue, and then mouse vs human. BEL and Biolink fit the *shape*
("intervention changes readout in tissue of species") best because they were built for pharma
curation, and Biolink's qualifiers plus `negated` in a knockout population is a neat way to say
"SIRT1-dependent". But both lose dose, age, duration and strain to free text. GO-CAM is the worst
fit here by design: GO excludes phenotypes, disease, diet and age. BioLean currently has no context
slot at all, so the 2011 HFD mouse result, the 2016 ageing mouse result and the 2021 human RCT fuse
into one opinion.

**Physics.** A proton gradient is a difference across a membrane. No formalism has a class for it.
INDRA fakes it as a MeSH Agent, BEL as a local abundance, nanopub as a local class, BioLean as
"amount of hydron" with no compartment. Membrane sidedness (inside-out submitochondrial particles)
is invisible everywhere.

## What this means for BioLean

The ranking by fit is: nanopub+SEPIO for argument structure, Biolink qualifiers for context slots,
BEL for direction and nulls, GO-CAM for mechanism wiring and ECO. None is sufficient; BioLean
should borrow one thing from each.

| borrow | from | into BioLean |
|---|---|---|
| hypothesis / finding / inference as a type on the assertion | SEPIO | `EvidenceKind.hypothesis` with weight 0; `Statement.predictedBy` |
| contradicts between assertions; supersedes | SEPIO, nanopub | `Statement.rivals`; mutual exclusion transfers belief to disbelief |
| species, anatomical, disease, stage qualifiers | Biolink | `Context` inside the claim (`Claim.inContext`), so mouse ≠ human |
| `causesNoChange` | BEL | `Claim.noEffect`, a true null |
| ECO on every evidence line | GO-CAM, SEPIO | replace the 8-kind enum with ECO codes mapped to reliabilities |
| population node for models (HFD, aged, KO) | Biolink | `Context.exposure`, `Context.stage` |
| explicit transport edge | none has it; Bareinboim & Pearl | new `Derivation.transport` rule with its own low reliability |

The BioLean annotator's section 5 proposes exactly this as a minimal extension (one new
`Context.lean`, ~30 lines elsewhere, no existing constructor changed) and reports that the GLP-1
library and Ozempic example still build against it. Rewritten in it, Mitchell scores belief 0.84
and Slater disbelief 0.84. Dose, strain and age still have nowhere to go in any formalism, including
that one; they need a measured-value slot (`Evidence.quantity`) and a strain ID source that does not
exist yet.
