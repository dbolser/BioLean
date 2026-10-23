# BioLean: related work

Written 2026-10-23. Built from 7 research sweeps in `docs/research/`. Status facts are as of that date.

## 1. Verdict

Most parts of BioLean already exist, but in separate places. INDRA turns papers into typed statements with evidence and a belief score. GO-CAM and SIGNOR hold curated, referenced causal edges with ontology terms. PubTator3 gives 28M abstracts of grounded relations for free. Nanopublications, SEPIO and ECO give the provenance and evidence-type layer. CertifyingDatalog and provenance-lean show that Lean can check derivations and carry semiring weights. Two things are new. First, nobody turns referenced literature statements into checked proofs of higher-level claims whose strength is computed from the evidence. EMMAA came closest, but its "proof" is a path search with no weight composition. Second, nobody handles competing hypotheses inside a formal proof system. The idea of a weighted consensus lemma was written down in 2012 as the "cardinal assertion" and never built. So BioLean should reuse data and vocabularies, not invent them. Take INDRA's statement model and belief priors, GO-CAM's edge shape, ECO as the evidence key, RO for predicates, Gilda for grounding, PubTator3 and SIGNOR as seed edges, and the Lean practice of Physlib and crnt-lean. Spend the novelty budget on weight composition and conflict.

## 2. The 25 projects that matter most

| Project | Status | What it gives BioLean | Reusable asset |
|---|---|---|---|
| INDRA | Active, v1.24.0, commits to 2026-06 | Typed statements with grounded agents and an evidence list. Belief engine. Polarity contradiction finder. Refinement order. | `statements_schema.json`, `default_belief_probs.json`, preassembler and belief modules |
| EMMAA | Dormant, frozen 2024-08-01 | The nearest "prove a claim from literature" system. Proof is bounded path search with an English witness. No weight composition. | `indra.explanation.model_checker` code, design reports |
| Gilda, Bioregistry | Active, Gilda 1.6.1 | Grounding text to CURIEs with disambiguation. Grounds semaglutide to CHEBI:167574. | PyPI `gilda`, grounding.indra.bio REST, custom term TSV format |
| PubTator3, BioREx | Active, weekly | Free grounded relations over about 36M abstracts. No direction, negation, sentence or score in the bulk file. | `relation2pubtator3.gz`, already on disk; BioCXML with offsets |
| SemMedDB, SemRep | Dead, NLM stopped 2024-12-31 | Proven shape for a referenced triple table. Precision is poor. | Final 2024 dump, needs UMLS licence |
| iKraph, MedKGent | Maintained, active | The only PubMed-scale weighted KGs. Both use noisy-OR over papers. Both pick a winner on conflict. | iKraph Zenodo dump, licence unstated; MedKGent on Hugging Face |
| OntoGPT, SPIRES | Active, v1.2.0 | Schema-driven LLM extraction that grounds every value by ontology lookup. | LinkML templates, OAK grounding |
| SIGNOR 4.0 | Active, host was down on 2026-10-23 | Curated signed causal edges with mechanism, PMID and sentence. Best seed for activates and inhibits. | causalTAB download; licence reportedly CC BY-NC, unconfirmed |
| GO-CAM | Active, monthly | The exact statement shape: activity, RO relation, activity, ECO code, PMID. | GO-CAM JSON, `gocam-py` LinkML schema |
| Open Targets | Active, 26.06 on disk | Explicit tables mapping evidence category to a number. A baseline to beat. | Evidence parquet, Europe PMC sentence snippets |
| BEL, PyBEL | Dead; PyBEL last release 2022 | Best grammar precedent: term functions, direct vs indirect, citation and verbatim sentence per statement. No semantics, no weight. | BEL 2 spec, PyBEL converters, Selventa corpora |
| Nanopublications | Active software, little biology content | Signed, hash-identified, retractable container for one statement plus provenance. | `nanopub-py`, private registry via Docker Compose |
| Cardinal assertions | Idea only, 2012 paper | The name and rules for a biolib lemma: consensus, link every source, publish the scoring method, new edition on change. | Design only |
| PROV-K | 2025 papers and data | Supporting and conflicting evidence stored side by side with per-source reliability. | PROV-K ontology, code, 197k nanopubs on Zenodo |
| SEPIO, GA4GH VA-Spec | Active in LinkML, VA-Spec 1.1.0 | Proposition separate from Statements and EvidenceLines, each with direction and strength. | `sepio-linkml`, VA-Spec schema |
| ECO | Active, release 2026-07-10 | Evidence type vocabulary, already on every GOA and UniProt record. Deliberately no weights. | `eco.owl`, GO code to ECO mapping, ECO-CollecTF corpus |
| Super-pattern | Quiet since 2023 | Claims need a context slot and a quantified qualifier, not a bare triple. | Superpattern vocabulary, Nanodash template |
| RO, Ubergraph | Active | Predicate vocabulary. 102 property-chain axioms that are Horn rules. Precomputed OBO closure. | `ro.owl` on disk, Ubergraph edge tables, SPARQL |
| CertifyingDatalog, Nemo | Active, Lean 4.35 | Datalog engine finds the derivation, a verified Lean checker certifies it. | Lean library, JSON proof DAG format |
| provenance-lean | Active, v1.2.0 | Provenance semirings formalised in Lean 4 on Mathlib. | Lean package on Reservoir, MIT |
| Subjective logic | Theory mature, libraries toy-grade | Opinion type where "no evidence" differs from "contested". BioLean already uses it. | Corrected fusion formulas, van der Heijden 2018 |
| ClinGen, ACMG points | Active, SOP v12 2026 | The only evidence scheme where biologists agreed the numbers. Additive log-odds with caps and a replication rule. | SOP point tables, curation downloads |
| Argumentation | Tweety active; Isabelle formalisation dormant | The only family that treats contradiction as first-class. | Steen and Fuenmayor Isabelle sources to port; TweetyProject |
| Physlib, crnt-lean | Active | Lean library practice: informal and semiformal lemmas with references; axiom-audit CI. | `Physlib/Meta/Informal`, `test/AxiomAudit.lean` pattern |
| Zsyntax, Pathway Logic | Dead or dormant | Direct ancestors: pathway as proof, literature reactions as rules. Both died from manual cost and no community. | Ideas; Pathway Logic models still downloadable |

## 3. Themes

### 3.1 Knowledge assembly: INDRA and kin

INDRA is the closest thing to BioLean's baseline layer. It reads papers and databases into typed statements. Each statement carries grounded agents and a list of evidence: source, PMID, sentence, and flags for negated, hypothesis and direct. A preassembler merges duplicates and builds a refinement order from ontology is_a and part_of. A belief engine scores each statement. The 2023 paper processed 567k articles into about 900k unique statements; 63% had one piece of evidence; 73% of 1,800 curated statements were correct. Single-mention precision ranged from 36% for Sparser to 80% for RLIMS-P. EMMAA used INDRA to "test" models by finding a path in a signed graph. It froze in August 2024, months after its grant ended.

- INDRA belief measures "was the sentence read right". It does not measure "is the biology true". The authors found most errors were grounding, polarity, negation and hypothesis errors.
- The belief rule is simple: per source, systematic error plus product of random errors; belief is one minus the product over sources. Readers get 0.3 random and 0.05 systematic error by default.
- Agreement between independent readers is the strongest cheap signal. 81% of relations came from one reader only.
- Evidence flows from specific statements to general ones, never back. This is a clean rule for Lean.
- INDRA only detects polarity opposites. It does not resolve them.
- Sweeps differ slightly here. One says INDRA never composes belief along paths. Another says inferred "linked" statements get the product of their parents' beliefs. Both hold: assembly has a product rule, but EMMAA path checks never use it.
- Readers are a 2015 to 2020 rule-based stack. Do not run them. The lab itself has moved to LLM judging with `indra-belief-model`.
- Self-updating pipelines die with their grant. Build BioLean as a versioned batch release, like mathlib.

### 3.2 Pre-extracted relations and knowledge graphs

Almost no source gives a calibrated per-edge probability. Confidence is absent, as in PubTator3, SemMedDB and PrimeKG. Or it is an evidence-type tier, as in ECO, BioGRID experimental system, Reactome's inferred flag and Biolink knowledge_level. Or it is an ad hoc aggregate, as in the Open Targets harmonic sum, the SIGNOR score and the DisGeNET score. Curated causal sources are small but strong: SIGNOR, GO-CAM, Reactome. Text-mined sources are big but weak. SemRep strict precision was 0.55 with recall 0.34. PubTator3's bulk relations are mostly "associate", with no direction.

- The unit worth keeping everywhere is: statement, PMID, evidence sentence, evidence type, and whether a human or a machine asserted it. GO-CAM, SIGNOR, BEL and Biolink all agree on this.
- A good seed layering: GO-CAM, SIGNOR and Reactome as the strong core. GOA and low-throughput BioGRID as the middle. PubTator3 and Europe PMC as the weak long tail.
- Count distinct PMIDs, not mentions. Text-mined edges are many weak, correlated opinions.
- BEL is the warning. It was a good statement language with citations and context. It died when its company folded in 2016. It never had formal semantics or weights.
- Sources disappear. SIGNOR was down on the check date. SemMedDB ended. Pathway Commons looks stale. Monarch pages carry US review notices. Snapshot every source with a version and date.
- Sweeps disagree on two counts. PubTator3 relation types: the paper says 12, the README says 8, the file uses short labels. GO-CAM size: one sweep says thousands of models, the 2026 GO paper says over 1,500 pathway-level models. Check the local files before relying on either.
- Licences matter for a public biolib. SIGNOR may be non-commercial. DisGeNET blocks redistribution. iKraph's data licence is unstated. SemMedDB needs UMLS.

### 3.3 Nanopublications and provenance

A nanopublication bundles one assertion with its provenance and publication info, signs it and gives it a content-hash ID. The software is alive in 2026. Adoption for biology claims is not. The legacy network holds 10.9M nanopubs, but about 95% are bulk database dumps such as DisGeNET and neXtProt. The new signed registry holds 95,503, almost none about biology. The useful parts are the ideas around it. Cardinal assertions, 2012, describe a biolib lemma exactly. PROV-K, 2025, stores supporting and conflicting evidence together. SEPIO splits the possible fact from the claims about it. ECO types evidence but refuses to weigh it. CIO tried to standardise confidence in 2015 and was not adopted. Micropublications, Domeo, Knowlets and Open PHACTS are dead.

- Keep the Proposition apart from the Statements about it. Competing hypotheses become opposite-direction statements on one proposition.
- A biolib lemma is a cardinal assertion. Link every source statement. Publish the scoring method as its own citable object. Issue a new edition when evidence changes.
- Registry trust is about who may publish. It says nothing about whether a claim is true. Do not use it as a weight.
- Evidence type is solved by ECO. Evidence weight is not, and no standard will appear. Publish BioLean's own table.
- Real claims need context and a qualifier. Super-pattern uses CONTEXT, SUBJECT, QUALIFIER, RELATION, OBJECT, where "generally" means at least 90% of cases.
- Anchor each statement to the exact sentence with a W3C Web Annotation quote selector.
- Identifier equivalence is a choice made per query, not a fact. Open PHACTS called these "scientific lenses". A proof should record which equivalences it assumed, for example semaglutide versus its salts.
- Platforms die. Plain files in standard shapes survive.

### 3.4 Formal methods in biology

Formal biology so far has meant proving properties of models, not of the literature. Pathway Logic curated hundreds of referenced signalling rules into Maude, then stopped around 2017. Zsyntax made "a pathway is a proof" literal, and was formalised in HOL in 2017, then nobody followed. Coq and Rocq work on neurons and gene networks stayed at "relatively simple examples". BIOCHAM, Kappa and BioNetGen are alive but model dynamics, with no citations on rules. A 2023 review found over 30 model checkers in biology and no theorem provers in use. Inside Lean, the useful prior art is engineering practice. Physlib makes informal and semiformal lemmas first-class. crnt-lean pins `#print axioms` in CI. FormalScience, ACL 2026, showed autoformalisation is cheap but drifts: Lean accepts statements that quietly lost the science. K-Lean and VeriBiota prove formula and algorithm properties and are not related.

- Prove relational and structural claims. Leave kinetics to BioNetGen and Kappa.
- Because Lean's Prop is proof-irrelevant, scores cannot sit on proofs. Model derivations as data, or compute scores over the axiom graph.
- Use Physlib's ladder: informal statement with references, then a stated type, then a proof. Most of biolib will be informal for years.
- Add an axiom-audit test that fails the build on `sorryAx` or unexpected axioms. Treat `native_decide` as a lower trust tier.
- Type-checking proves consistency, not fidelity. The ontology rendering of a sentence needs its own check: IDs resolve, the predicate is valid RO, back-translation matches.
- Do not load 6M OBO terms as Lean axioms. Compute the closure outside and import what is used.
- Single-lab formal systems on niche engines die. Pathway Logic, Zsyntax and BIOCHAM's tiny user base all show this.

### 3.5 Uncertainty and conflict frameworks

Every working fusion rule makes the same move: assume sources are independent, and saturate within a source. INDRA's belief, ProbLog's noisy-OR, subjective-logic cumulative fusion and ACMG's summed log-odds points all do this. They differ in how they treat conflict. Probability hides it: Dempster's rule renormalises it away, ProbLog cannot state it, Bayesian networks just lower a posterior, PSL smears it into soft values. Subjective logic keeps it visible as high belief and high disbelief together. Argumentation makes it first-class. ClinGen is the one place biologists agreed numbers, and its conflict rule is a human verdict: "Disputed". OpenCog PLN tried uncertain logic over GO for about 15 years and left nothing reusable.

- Subjective logic is the right edge type if "unknown" must differ from "contested". Implement from the corrected operators in van der Heijden et al. 2018. Some multi-source operators are not associative.
- Copy ClinGen's shape for auditability: evidence type to points, a cap per type, a sum to a class, and "Definitive" only with independent replication over years.
- Provenance semirings give a clean pattern: one operator along a chain, another across alternative derivations, with the algebra as a parameter.
- Compute outside, certify inside. A verified weighted model counter already exists in Lean 4: the CPOG checker.
- Reject global joint inference such as MLN and PSL as the core. No proof objects, and one new axiom moves every value.
- PLN failed from forward-chaining explosion, weights not tied to citations, and no reusable lemmas. BioLean's design is the opposite on all three.
- GRADE-style judgement does not automate well: 63% agreement with humans in one attempt. Use it as a label only.

### 3.6 LLM extraction

Fine-tuned models still beat prompted LLMs on strict relation schemas. PubTator3's model reports 82.0 F1 on BioRED. Frontier LLMs with few-shot prompts reached at most 0.31 F1 in a 2026 study. These numbers are not measured the same way, so treat the gap as large but not exact. A second "critic" pass raises precision a lot, from 33% to 74% for one model, but recall stays low. LLMs must never emit identifiers: SPIRES got 97 to 98 of 100 IDs right by lookup, against 1 to 3 when the LLM wrote them. The hard labels are direction, relation type and novelty, at about 0.4 to 0.6 F1 each. Hedging can be extracted: BioRelFact reached 65 F1 on 5 levels of commitment. Claim verification in the SciFact style is a separate, useful primitive, but drops 15 F1 or more on an open corpus.

- Use PubTator3 as the high-recall backbone. Use LLMs only to add what it lacks: direction, negation, hedging, RO predicate.
- Ground with a lexical index plus an LLM picking among candidates. Do the same for predicates against RO or Biolink.
- Store assertion strength as its own field. Three levels, asserted, hedged, negated, is likely more reliable than five.
- LLM-judged "validity", as in MedKGent's 86 to 90%, is not F1. Do not compare them.
- Expect to hand-check direction for canonical statements. The Ozempic chain needs "inhibits", not "associated with".
- No benchmark covers grounded subject, RO predicate, direction, hedging and sentence together. BioLean's canonical papers should double as the gold set.

### 3.7 Logic programming

Biology moved from Prolog knowledge bases and full OWL DL to small, polynomial reasoners. Blipkit, Thea, HermiT and Pellet are dead. ELK, Whelk, relation-graph and Nemo are alive. The most important find is CertifyingDatalog: Nemo exports a derivation trace, and a verified Lean 4 checker certifies it. It checked 1,000 ontology conclusions in about 0.3 seconds. It covers positive Datalog only and carries no weights. ASP tools such as caspo and iggy show what to do with competing hypotheses: list every world the evidence allows, and find the smallest set of facts that must be wrong. ProbLog's first application, in 2007, was weighted link discovery in a biology graph, so weighted logic over bio KGs is an old idea. The new part is checking it.

- Stay inside Horn and EL expressivity. It keeps reasoning polynomial and Lean checks cheap.
- RO's 102 chain axioms are the natural first biolib lemmas, for example enables then causally upstream of gives acts upstream of.
- Treat the OBO layer as precomputed facts with weight 1. Weight only empirical edges.
- Use ASP to enumerate competing worlds. Non-monotonic conclusions have no proof tree, so certify only the monotone part in Lean.
- Independent-probability semantics overcount literature. One experiment cited by 50 papers is not 50 supports.
- The Nemo to checker scripts target Nemo 0.7.1. Nemo is at 0.10.1. Retest before relying on them.

## 4. Design implications

Each item names its source and says whether the current BioLean design follows it. "Current design" means the Lean files in `BioLean/` and the pipeline in `biolean/` as of today.

1. **Separate extraction reliability from scientific consensus.** Source: INDRA, Bachman et al. 2023. Current design: **No.** `EvidenceKind` mixes the two. `textMined` at 0.3 is a reading reliability. `metaAnalysis` at 0.9 is a consensus strength. An edge needs both numbers, or a text-mined item should be discounted before it counts as biology.

2. **Key evidence weight on ECO and publish the table as a versioned, citable object.** Source: ECO; Gibson et al. 2012; ClinGen SOP v12; Open Targets score tables. Current design: **Partly.** `EvidenceModel` is a swappable typeclass, which is right. But its keys are a home-made study-design list, not ECO, and the weights are not calibrated. GOA already carries ECO codes on 1.28M PMID links.

3. **Count independent findings, not citations.** Source: ProbLog and Biomine overcounting; INDRA saturation within a source; sweep 6 lessons. Current design: **No.** `Statement.opinion` fuses every evidence item cumulatively, so the same PMID listed twice counts twice. `Derivation.both` fuses two derivations even if they share axioms, so reused statements are counted again. Dedup by PMID, and require disjoint axioms for `both` or use averaging fusion when they overlap.

4. **Keep conflict visible through a chain.** Source: subjective logic, Jøsang 2016; argumentation, Hunter and Williams 2012. Current design: **Partly.** `fuse` keeps belief and disbelief apart, and `Verdict.contested` exists. But `chain` sets disbelief to zero. A chain built on a contested link reports only "uncertain", so a derived claim can never come out contested or refuted. At minimum, the report should list contested axioms the proof rests on.

5. **Keep the Proposition apart from the Statements about it.** Source: SEPIO and GA4GH VA-Spec; PROV-K. Current design: **Partly.** `Claim` is the proposition and `Statement` holds evidence with polarity, which matches PROV-K's "supporting and conflicting together". But two `Statement`s with the same `Claim` are not merged, and there is no direction or strength per contributing source.

6. **Add a context slot and a qualifier to every claim.** Source: super-pattern, Bucur et al. 2021; BEL annotations; Pathway Logic typed state. Current design: **No.** `Claim` has no species, tissue, cell type or condition, and no "generally" or "sometimes". Most apparent contradictions in the literature are context differences, and mouse-to-human steps need an explicit orthology rule.

7. **Anchor each evidence item to its sentence and its asserting agent.** Source: W3C Web Annotation; GO-CAM; SIGNOR; BEL; Biolink agent_type. Current design: **No.** `Evidence` holds PMID, year, kind, polarity and a free note. Add the quote, and whether a human or a machine made the assertion.

8. **Take predicates from RO and let evidence flow up the ontology.** Source: RO; GO-CAM; INDRA refinement. Current design: **Partly.** The signed-effect vocabulary is INDRA-like and sound. But claims do not record an RO or Biolink predicate, and `Derivation` has no step for "specific claim supports general claim" via is_a. That step is how INDRA got 38% of its statements to support others.

9. **Make claims data, not Prop, so scores can live on derivations.** Source: Lean proof irrelevance, sweep 5; provenance-lean; the 2026 patent-analysis Lean pipeline. Current design: **Yes.** `Derivation` is a `Type`, `opinion` is a function over it, and `axioms` gives the evidence trail like `#print axioms`. Proved lemmas such as "a chain is never stronger than its links" are the right kind of guarantee.

10. **Make the evidence algebra a parameter.** Source: Scallop; provenance semirings, Green et al. 2007; provenance-lean. Current design: **Partly.** Weights are swappable, but the operators are fixed to subjective logic. My reading: SL fusion and this `chain` probably do not form a semiring, so provenance-lean cannot be dropped in as is. Check which laws hold before choosing.

11. **Data format first, Lean library second.** Source: Blipkit and BEL deaths; Open PHACTS; EMMAA. Current design: **Partly yes.** `biolean/emit_lean.py` generates Lean from JSON in `data/demo/`, which is the right direction. Make the JSON or LinkML schema the documented source of truth, with content-hash IDs and source snapshot dates.

12. **Let a Datalog engine find derivations and Lean check them, once the library grows.** Source: CertifyingDatalog and Nemo, Tantow et al. 2025. Current design: **No, not yet needed.** Hand-built derivations work for the GLP-1 demo. At thousands of statements, search should move outside Lean, with weights recomputed by a Lean function over the certified tree.

## 5. Prior art for the hard problem: competing hypotheses

How conflict is handled today:

| Approach | Who does it | What happens to the conflict | Weakness |
|---|---|---|---|
| Pick a winner | MedKGent, LLM decides; iKraph keeps the top relation type per pair | Lost | The loser vanishes. The opposite of what BioLean wants. |
| Detect only | INDRA `find_contradicts` | Flagged as a polarity pair | No resolution, no weight. Misses non-polarity conflicts. |
| Average it away | Dempster's rule, PSL, Bayesian networks, plain probability | Becomes a middling number | "Contested" and "unknown" both look like 0.5. Dempster can give certainty neither source supports. |
| Cannot express | ProbLog | Error | A fact and its negation cannot both carry weight. |
| Keep both, explicit | SEPIO opposite-direction statements; PROV-K; micropublications supports and challenges; CIO congruent vs conflicting; subjective logic | Visible as a state | Storage and labels only. No inference over it, except SL fusion. |
| Human verdict | ClinGen Disputed and Refuted; GRADE inconsistency downgrade | Decided by an expert panel | Not formal. But it is what curators actually trust. |
| Enumerate worlds | ASP: caspo found 11,700 models fitting one dataset; iggy finds minimal inconsistent cores | Each world is consistent; repairs say what must be wrong | Non-monotonic, so no proof tree for Lean to check. |
| Argue | Dung frameworks, ASPIC+, Hunter and Williams 2012 meta-arguments against weaker evidence, epistemic probabilities | Attacks between arguments; preferences decide | No agreed way to mix numeric weights with attacks. No Lean or Coq formalisation; one in Isabelle. |

What is missing:

- No formal system in biology represents competing hypotheses. The formal-methods sweep found none.
- No system combines evidence weights with argumentation in a way people agree on.
- Lean is monotonic, but evidence is not. A new paper can defeat an old proof. Nobody has said how a theorem should depend on a corpus version.
- Nobody has a model of evidence dependence: same lab, same assay, reviews citing one experiment. Every fusion rule assumes independence.
- Conflicts are often context differences. Nobody decides whether context belongs in the claim, the weight, or the attack relation.
- Competing mechanisms are harder than opposite signs. Two different paths to "reduces hunger" are rival explanations, not contradictions. Nothing surveyed handles this.
- There is no benchmark of contested biological claims to test against.

Where BioLean stands: subjective-logic opinions with a `contested` verdict put it in the "keep both, explicit" family at the statement level. That is a better start than any KG surveyed. The gap is item 4 above: chaining drops disbelief. The sweeps suggest one path forward. Map onto ASPIC+: ontology axioms are strict rules, literature statements are defeasible rules, opinions are preferences. Compute the grounded extension with Mathlib's least fixed point. State each theorem relative to a named corpus snapshot. Porting the Steen and Fuenmayor Isabelle formalisation of Dung frameworks to Lean is a small, well-scoped first step.

## 6. References

Knowledge assembly
- Bachman, Gyori, Sorger. Automated assembly of molecular mechanisms at scale from text mining and curated databases. Mol Syst Biol 2023. https://doi.org/10.15252/msb.202211325
- Gyori et al. From word models to executable models of signaling networks using automated assembly. Mol Syst Biol 2017. https://doi.org/10.15252/msb.20177651
- INDRA. https://github.com/gyorilab/indra ; docs https://indra.readthedocs.io
- INDRA DB. https://github.com/gyorilab/indra_db ; https://db.indra.bio
- INDRA CoGEx. https://github.com/gyorilab/indra_cogex
- EMMAA. https://github.com/gyorilab/emmaa ; https://emmaa.readthedocs.io
- indra-belief-model. https://github.com/gyorilab/indra-belief-model
- MIRA. https://github.com/gyorilab/mira
- Gyori, Hoyt, Steppi. Gilda. Bioinformatics Advances 2022. https://doi.org/10.1093/bioadv/vbac034
- Hoyt et al. Bioregistry. Sci Data 2022. https://doi.org/10.1038/s41597-022-01807-3
- Hoyt, Karis, Gyori. SeMRA. Bioinformatics 2025. https://doi.org/10.1093/bioinformatics/btaf542
- Valenzuela-Escarcega et al. REACH at scale. Database 2018. https://doi.org/10.1093/database/bay098

Relations and knowledge graphs
- Wei et al. PubTator 3.0. NAR 2024. https://arxiv.org/abs/2401.11048 ; https://ftp.ncbi.nlm.nih.gov/pub/lu/PubTator3/
- Lai et al. BioREx. J Biomed Inform 2023. https://github.com/ncbi/BioREx
- BioRED track at BioCreative VIII. Database 2024. https://doi.org/10.1093/database/baae069
- Lai et al. Enhancing biomedical relation extraction with directionality. 2025. https://arxiv.org/abs/2501.14079
- Kilicoglu et al. Broad-coverage biomedical relation extraction with SemRep. BMC Bioinformatics 2020. https://pmc.ncbi.nlm.nih.gov/articles/PMC7222583/
- SemMedDB end-of-maintenance notice. https://lhncbc.nlm.nih.gov/ii/tools/SemRep_SemMedDB_SKR/SemMedDB_download.html
- Zhang et al. iKraph. Nature Machine Intelligence 2025. https://doi.org/10.1038/s42256-025-01014-w
- MedKGent. 2025, v3 2026. https://arxiv.org/abs/2508.12393
- Open Targets evidence and scoring. https://platform-docs.opentargets.org/evidence
- SIGNOR. https://signor.uniroma2.it/ ; SIGNOR 4.0, NAR 2026, https://pmc.ncbi.nlm.nih.gov/articles/PMC12807704/
- Oughtred et al. BioGRID. Protein Sci 2021. https://pmc.ncbi.nlm.nih.gov/articles/PMC7737760/
- Reactome. https://reactome.org/download-data
- Thomas et al. GO-CAM. Nature Genetics 2019. https://doi.org/10.1038/s41588-019-0500-1
- GO Consortium. Gene Ontology knowledgebase 2026. NAR. https://doi.org/10.1093/nar/gkaf1292
- Biolink Model. https://biolink.github.io/biolink-model/ ; Unni et al. Clin Transl Sci 2022. https://doi.org/10.1111/cts.13302
- Putman et al. Monarch Initiative in 2024. NAR 2024. https://pmc.ncbi.nlm.nih.gov/articles/PMC10767791/
- Hoyt et al. PyBEL. Bioinformatics 2018. https://doi.org/10.1093/bioinformatics/btx660
- Himmelstein et al. Hetionet. eLife 2017. https://doi.org/10.7554/eLife.26726
- Chandak et al. PrimeKG. Sci Data 2023. https://doi.org/10.1038/s41597-023-01960-3

Nanopublications and provenance
- Groth, Gibson, Velterop. The anatomy of a nanopublication. Inf Serv Use 2010. https://doi.org/10.3233/ISU-2010-0613
- Kuhn et al. Decentralized provenance-aware publishing with nanopublications. PeerJ CS 2016. https://doi.org/10.7717/peerj-cs.78
- Nanopub registry. https://github.com/knowledgepixels/nanopub-registry ; https://nanopub.net/
- Gibson, van Dam, Schultes, Roos, Mons. Cardinal assertions. SWAT4LS 2012. https://ceur-ws.org/Vol-952/paper_26.pdf
- Mons et al. WikiProteins. Genome Biology 2008. https://doi.org/10.1186/gb-2008-9-5-r89
- Bucur, Kuhn, Ceolin, van Ossenbruggen. Expressing high-level scientific claims with formal semantics. K-CAP 2021. https://doi.org/10.1145/3460210.3493561
- Bucur et al. Formalization papers field study. PeerJ CS 2023. https://doi.org/10.7717/peerj-cs.1159
- Menotti et al. Provenance-driven nanopublications. Int J Digit Libr 2025. https://doi.org/10.1007/s00799-025-00431-x
- Brush, Shefchek, Haendel. SEPIO. ICBO 2016. https://github.com/sepio-framework/sepio-linkml
- GA4GH VA-Spec. https://va-spec.ga4gh.org/
- Giglio et al. ECO. NAR 2019. https://doi.org/10.1093/nar/gky1036
- Hobbs et al. ECO-CollecTF. Front Res Metr Anal 2021. https://doi.org/10.3389/frma.2021.674205
- Bastian et al. Confidence Information Ontology. Database 2015. https://doi.org/10.1093/database/bav043
- Clark, Ciccarese, Goble. Micropublications. J Biomed Semantics 2014. https://doi.org/10.1186/2041-1480-5-28
- W3C Web Annotation Data Model. 2017. https://www.w3.org/TR/annotation-model/
- Batchelor et al. Scientific lenses. ISWC 2014. https://doi.org/10.1007/978-3-319-11964-9_7

Formal methods
- Eker et al. Pathway Logic. WRLA 2002. https://pl.csl.sri.com/
- Boniolo, D'Agostino, Di Fiore. Zsyntax. PLoS One 2010. https://doi.org/10.1371/journal.pone.0009511
- Rashid, Hasan, Siddique, Tahar. Formal reasoning about systems biology using theorem proving. PLoS One 2017. https://doi.org/10.1371/journal.pone.0180179
- Calzone, Fages, Soliman. BIOCHAM. Bioinformatics 2006. https://doi.org/10.1093/bioinformatics/btl172
- Boutillier et al. Kappa platform. Bioinformatics 2018. https://doi.org/10.1093/bioinformatics/bty272
- Harris et al. BioNetGen 2.2. Bioinformatics 2016. https://doi.org/10.1093/bioinformatics/btw469
- Konur, Gheorghe, Krasnogor. Verifiable biology. J R Soc Interface 2023. https://doi.org/10.1098/rsif.2023.0019
- Bahrami et al. Neuronal archetypes in Rocq. 2025. https://arxiv.org/abs/2505.05362
- Tooby-Smith. HepLean. 2024. https://arxiv.org/abs/2405.08863 ; https://github.com/HEPLean/PhysLean
- crnt-lean. https://github.com/marpaia/crnt-lean
- Bobbin et al. Formalizing chemical physics using Lean. Digital Discovery 2024. https://doi.org/10.1039/D3DD00077J
- Meadows, Zhang, Freitas. FormalScience. ACL 2026. https://arxiv.org/abs/2604.23002
- Ileri et al. VEL. 2024. https://arxiv.org/abs/2412.08739
- provenance-lean. https://github.com/PierreSenellart/provenance-lean
- gonzalgo. https://pypi.org/project/gonzalgo/

Uncertainty and conflict
- Jøsang. Subjective Logic. Springer 2016. https://doi.org/10.1007/978-3-319-42337-1
- van der Heijden, Kopp, Kargl. Multi-source fusion operations in subjective logic. 2018. https://arxiv.org/abs/1805.01388
- Tavtigian et al. ACMG/AMP as a Bayesian framework. Genet Med 2018. https://doi.org/10.1038/gim.2017.210
- Tavtigian et al. A naturally scaled point system for ACMG/AMP. Hum Mutat 2020. https://doi.org/10.1002/humu.24088
- Strande et al. ClinGen gene-disease validity. AJHG 2017. https://doi.org/10.1016/j.ajhg.2017.04.015
- ClinGen SOP documents. https://clinicalgenome.org/curation-activities/gene-disease-validity/documents/
- Green, Karvounarakis, Tannen. Provenance semirings. PODS 2007. https://doi.org/10.1145/1265530.1265535
- Li, Huang, Naik. Scallop. PLDI 2023. https://doi.org/10.1145/3591280
- De Raedt, Kimmig, Toivonen. ProbLog. IJCAI 2007. https://github.com/ML-KULeuven/problog
- Bryant, Nawrocki, Avigad, Heule. Certified knowledge compilation, CPOG. 2025. https://arxiv.org/abs/2501.12906
- Bach et al. Hinge-loss MRFs and PSL. JMLR 2017. https://jmlr.org/papers/v18/15-631.html
- Dung. On the acceptability of arguments. Artif Intell 1995. https://doi.org/10.1016/0004-3702(94)00041-X
- Modgil, Prakken. ASPIC+ tutorial. Argument and Computation 2014. https://doi.org/10.1080/19462166.2013.869766
- Hunter, Thimm. Probabilistic abstract argumentation. JAIR 2017. https://doi.org/10.1613/jair.5393
- Hunter, Williams. Aggregating evidence about the effects of treatments. Artif Intell Med 2012. https://doi.org/10.1016/j.artmed.2012.09.004
- Steen, Fuenmayor. Abstract argumentation in higher-order logic. 2021. https://arxiv.org/abs/2110.09174
- TweetyProject. https://tweetyproject.org/
- Škunca, Altenhoff, Dessimoz. Quality of computationally inferred GO annotations. PLoS Comput Biol 2012. https://doi.org/10.1371/journal.pcbi.1002533
- Goertzel et al. Bio-AtomSpace and PLN. 2020. https://arxiv.org/abs/2005.12535

LLM extraction
- Caufield et al. SPIRES. Bioinformatics 2024. https://doi.org/10.1093/bioinformatics/btae104 ; https://github.com/monarch-initiative/ontogpt
- Assi et al. Reasoning vs critic-based verification for biomedical RE. PromptEng 2026. https://ceur-ws.org/Vol-4258/paper1.pdf
- Ye, Mitchell. LLM as entity disambiguator. ACL 2025. https://aclanthology.org/2025.acl-short.25/
- Olasunkanmi et al. RELATE. 2025. https://arxiv.org/abs/2509.19057
- Keese et al. BioRelFact. LREC 2026. https://aclanthology.org/2026.lrec-1.602/
- Wadden et al. SciFact. EMNLP 2020. https://arxiv.org/abs/2004.14974
- SciFact-Open. 2022. https://arxiv.org/abs/2210.13777
- SciClaims. 2025. https://arxiv.org/abs/2503.18526
- James et al. textToKnowledgeGraph. bioRxiv 2025. https://doi.org/10.1101/2025.07.17.664328

Logic programming
- Tantow, Gerlach, Mennicke, Krötzsch. Verifying Datalog reasoning with Lean. ITP 2025. https://doi.org/10.4230/LIPIcs.ITP.2025.36 ; https://github.com/knowsys/CertifyingDatalog
- Nemo. https://github.com/knowsys/nemo
- Balhoff et al. Ubergraph. ICBO 2022. https://doi.org/10.5281/zenodo.7249759
- Balhoff et al. Whelk. TGDK 2024. https://doi.org/10.4230/TGDK.2.2.7
- Smith et al. Relations in biomedical ontologies. Genome Biology 2005. https://doi.org/10.1186/gb-2005-6-5-r46 ; https://github.com/oborel/obo-relations
- Balhoff et al. Arachne. ICBO 2018. https://ceur-ws.org/Vol-2180/paper-05.pdf
- Videla et al. caspo. Bioinformatics 2017. https://doi.org/10.1093/bioinformatics/btw951
- Hahn et al. plingo. TPLP 2024. https://doi.org/10.1017/S1471068424000449
- Su et al. KGARevion. ICLR 2025. https://arxiv.org/abs/2410.04660
- Mungall. Experiences using logic programming in bioinformatics. ICLP 2009. https://doi.org/10.1007/978-3-642-02846-5_1
