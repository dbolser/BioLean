# BioLean: an architectural explainer

*Written 2026-10-23 for a spoken overview. It explains what BioLean is, why it is built the way it is, what it borrows from earlier work, what the first demo shows, and what is still unsolved. Repository: https://github.com/dbolser/BioLean*

---

## 1. The ambition, and the problem with it

Biology is written down in prose. Roughly twenty-eight million PubMed abstracts and a few million full papers hold most of what we know, and almost none of it is in a form a machine can check. A statement like "semaglutide reduces appetite" sits in hundreds of papers, with hundreds of different wordings, hedges, species, doses and contexts. To ask whether it is *established*, a human reads a review and trusts the reviewer.

BioLean starts from a simple observation. Many biological claims have the shape of a chain. A drug activates a receptor. The receptor's activity changes a process. The process changes a phenotype. If each link is a typed, referenced statement, the chain is an argument, and an argument has a shape that can be checked. Mathematics went through exactly this transition: Mathlib, the Lean 4 mathematics library, holds hundreds of thousands of theorems whose proofs a small kernel checks, and new proofs reuse old ones as lemmas. BioLean asks what the biological analogue looks like. We call that library *biolib*.

The problem is that biology is not mathematics. A mathematical axiom is true by fiat. A biological "axiom" is a paper, and papers are sometimes wrong, often context-bound, and regularly in disagreement. Any formal system for biology has to carry *how well established* each statement is, and has to say something sensible when the literature disagrees with itself. That is the design problem BioLean addresses, and the single most important design decision follows from it.

## 2. The central split: Lean checks the shape, an algebra computes the strength

Every derivation in BioLean has two separable properties.

The first is **shape**. Does the object of one statement match the subject of the next? Do the signs compose correctly, so that "inhibits an inhibitor" comes out as activation? Does a claim about a protein's activity really attach to a protein, and a claim about a process to a GO process? These are type-level questions, and Lean 4's dependent type system answers them once and for all. A `Derivation c` is a term of an inductive type indexed by the claim `c` it proves. If the term type-checks, the argument is well-formed. There is no way to write a chain whose links do not join.

The second is **strength**. How much should we believe the conclusion, given the evidence behind each link? This is not a type-level question. It is arithmetic over the evidence, and it changes when a new paper arrives. So BioLean computes it as a function over the derivation, `Derivation.opinion`, rather than baking it into the type.

This split is what makes a reusable library possible. A named derivation in biolib is a plain Lean definition. Another proof can use it as a step, exactly as a Mathlib proof uses a lemma, and the strength of the new proof is computed from the strengths of its parts. The literature behind the whole thing is recovered by `Derivation.axioms`, which walks the term and lists every statement it rests on. This is the biological version of Lean's `#print axioms`, and it is the most useful single feature for a sceptical reader: here are the seventeen PMIDs this verdict depends on, and nothing else.

The design implication, which the related-work review (Lean proof irrelevance; Senellart's provenance-lean; see §6) also reached independently, is that **claims must be data, not propositions**. If a derivation were a Lean `Prop`, proof irrelevance would erase the difference between a proof resting on one weak paper and a proof resting on fifty trials. Making `Derivation` a `Type` keeps the structure available for scoring.

## 3. The algebra of belief: subjective logic over the rationals

For strength, BioLean uses Audun Jøsang's **subjective logic** (Jøsang 2016). An *opinion* about a claim is three non-negative numbers that sum to one: belief, disbelief and uncertainty. A single supporting paper of reliability *r* contributes belief *r* and uncertainty 1 − *r*. A refuting paper contributes disbelief *r* instead. Nothing ever contributes a dogmatic opinion with zero uncertainty, which keeps every operator total.

Two operators do all the work.

**Cumulative fusion** combines independent opinions about the same claim. Agreeing evidence drives belief towards one as more papers arrive. Disagreeing evidence leaves both belief and disbelief large. That configuration is what BioLean reports as *contested*, and it is the honest answer when the literature is split. INDRA's belief engine (Bachman, Gyori and Sorger 2023), which treats each source as an independent noisy witness and combines them with a noisy-OR, is a special case of this fusion restricted to supporting evidence.

**Serial composition**, which BioLean calls `chain`, carries belief through a mechanistic step. The belief of a chain is the product of the beliefs of its links. Its disbelief is zero. This is a deliberate modelling choice: a mechanistic chain only ever argues *for* its conclusion. If one link is doubtful, that makes the conclusion *uncertain*, not *false*, because some other mechanism might still produce it. Disbelief in the conclusion must come from direct evidence against the conclusion, and it arrives through fusion.

The numbers are exact rationals, not floating point. This matters for a reason that is easy to miss. A theorem such as "the claim that semaglutide reduces feeding is established at level 0.95" is a real Lean proposition: there exists a derivation whose computed belief is at least 95/100. The proof is `decide +kernel`, which asks the Lean kernel to evaluate the rational arithmetic and confirm the inequality. It is checked, not printed. Plain `decide` does not reduce on rationals in Lean 4.35, but the kernel variant does.

Three laws of the algebra are proved in `Belief.lean`, for every opinion anyone will ever construct: a chain is never stronger than its weakest link; adding supporting evidence never lowers belief; fusion never raises uncertainty. These are the kind of guarantees a reader of a biolib proof should be able to rely on without recomputing anything.

## 4. The vocabulary: entities, claims, statements, evidence

**Entities** are grounded things with a kind and a CURIE from a public ontology. Chemicals come from ChEBI, proteins from UniProt, processes from the Gene Ontology, phenotypes from the Human Phenotype Ontology and PATO, anatomy from UBERON. The kind is a type index, so a constructor that wants a protein cannot be handed a process.

**Claims** are deliberately few. The core form is: an agent has a signed effect on a target. Targets are a protein's activity, a molecule's amount, a biological process, a phenotype, or an anatomical site. Signs compose. A second form records a *mechanistic* claim: the effect of an agent on a target runs via some mediator. Competing hypotheses are almost always competing mechanistic claims, so this is where disagreement tends to live. The vocabulary is intentionally close to INDRA's statement types and to the Biolink Model's qualified predicates, so that existing resources can be imported rather than re-extracted.

**Statements** are the axioms. A statement is a claim plus a list of evidence items, each with a PMID, a year, an evidence kind, a polarity (supports or refutes) and a verbatim quote. Repeated PMIDs are collapsed before fusion: one paper is one witness.

**Evidence kinds** map to reliabilities through a swappable `EvidenceModel` typeclass. The default table puts meta-analyses highest, then randomised trials, curated database assertions, mechanistic studies, reviews, observational studies, in-vitro work, and text-mined relations lowest. The table is uncalibrated and is marked as such. It exists so that every proof is parametric in the evidence model, and so that a calibrated model, for example one keyed on ECO evidence codes, can be dropped in later without touching any derivation.

## 5. The first demo: does Ozempic reduce hunger?

The question is formalised as: semaglutide (CHEBI:167574) has a negative effect on feeding behavior (GO:0007631).

Twelve statements were curated from the local corpus of 28.5 million PubMed abstracts. An automatic pass produced about fifteen candidate papers per statement; a curation pass kept three to six per statement whose abstracts literally assert the claim, and every one of the sixty-six quotes was verified as a substring of the cited abstract. The statements cover: semaglutide activates GLP1R; GLP1R activity reduces food intake via arcuate POMC neurons; endogenous GLP-1 activates GLP1R; DPP4 degrades GLP-1; sitagliptin inhibits DPP4; GLP1R activity delays gastric emptying; the direct trial evidence that semaglutide reduces intake and weight; the clinical observation that DPP-4 inhibitors are weight-neutral; and four mechanism disputes.

Five results follow, all checked by the kernel.

**First, the main claim is established.** Two independent routes are fused: the direct clinical trials, and the mechanistic chain through GLP1R. Belief 0.968, disbelief zero. The derivation rests on three statements and seventeen PMIDs, all listed by `axioms` and `pmids`.

**Second, the sign algebra does real work.** Sitagliptin inhibits DPP4; DPP4 degrades GLP-1. Two negatives compose to a positive: sitagliptin raises GLP-1 levels. Lean checks the composition in the type; no arithmetic is involved.

**Third, mechanism is not magnitude.** The four-step chain from sitagliptin to feeding predicts that DPP-4 inhibitors should reduce intake, with belief 0.73. But the clinical literature says they are weight-neutral, and that enters as refuting evidence on the conclusion. Fused, the verdict is *contested*: belief 0.365, disbelief 0.585. This is the characteristic failure of sign-only causal reasoning, and BioLean makes it visible instead of hiding it. Any system that reasons over signed edges alone, which includes most biomedical knowledge graphs, would have declared the DPP-4 route a success.

**Fourth, competing hypotheses are represented without leaving the formal system.** "Nausea mediates the anorectic effect" has five papers for it and six against. Fused: belief 0.388, disbelief 0.577, contested. Yet the top-level claim is unaffected, because the dispute is about the mechanism, not the outcome, and the clinical route does not pass through it. Similarly, "acts centrally by crossing the blood-brain barrier into the hypothalamus" is contested (0.524 against 0.377), while "acts via the area postrema and vagal afferents" is established (0.909).

**Fifth, the evidence trail is complete.** Every verdict prints the statements and papers it rests on, and warns if a derivation uses the same statement twice, since fusion assumes independence.

## 6. What BioLean borrows, and from whom

The related-work review covered about sixty-three projects across seven angles. Its verdict was that most of BioLean's parts already exist, in separate places, and that the two genuinely new things are checked proofs whose strength is computed from evidence, and competing hypotheses handled inside a proof system. The novelty budget should go there; everything else should be reused.

**INDRA** (Gyori et al. 2017; Bachman, Gyori and Sorger 2023) is the closest ancestor. It reads papers with several machine readers, grounds entities with Gilda, assembles typed statements with per-source evidence, and attaches a belief score. INDRA's statement schema, its grounding tools and its belief priors are directly reusable. What INDRA does not do is compose beliefs along derivations or check the shape of an argument; EMMAA, its self-updating model layer, "explains" an observation by path search without weight composition. The sibling hypothesis-agent project on this machine already exports INDRA JSON, so the interchange path exists.

**GO-CAM** (Thomas et al. 2019) is the most important curated seed. Each causal activity model is a set of edges of the form activity, relation, activity, with an ECO evidence code and a PMID on every edge. That is almost exactly a BioLean statement. The **Evidence and Conclusion Ontology** (Giglio et al. 2019) is the natural key for calibrated weights, and the 1.28 million GOA annotation-to-PMID links already on this machine carry ECO codes.

**SIGNOR** holds signed causal edges with mechanism, evidence sentence and PMID, and **Reactome** holds stoichiometric reactions. Both are candidate biolib seeds. **PubTator3** (Wei et al. 2024), already on disk as bulk files, gives grounded relations over all of PubMed, but with no score, no sentence and mostly undirected "associate" edges; it is a low-weight long tail, not a core.

**Nanopublications** (Groth, Gibson and Velterop 2010; Kuhn et al. 2016) and the Concept Web Alliance's **Knowlets** (Mons et al. 2008) are the provenance ancestors Dan half-remembered. The idea survives: a minimal assertion with its provenance and publication info as one citable object. The 2012 **cardinal assertion** (Gibson et al.) is, almost word for word, the weighted consensus lemma BioLean wants biolib to contain; it was described and never built. The nanopub ecosystem is alive but small, maintained by Knowledge Pixels. **SEPIO** and the GA4GH **VA-Spec** supply the proposition-versus-statement distinction that BioLean's claim-versus-statement split mirrors. **BEL**, the Biological Expression Language, is the closest prior art for a statement language with citations and context annotations, and a warning: it had no weights and no formal semantics, and died with its company.

**Formal methods in biology** have a real history: Pathway Logic in Maude (Eker et al. 2002), BIOCHAM, Kappa and BioNetGen for rule-based modelling, Isabelle and Rocq for reaction networks and neuronal archetypes. None of them treats the literature as axioms. The Lean practice BioLean actually copies comes from **PhysLean** (Tooby-Smith 2024), **crnt-lean** for chemical reaction networks, and **provenance-lean** (Senellart), which carries semiring provenance through derivations. Tantow et al.'s **CertifyingDatalog** (ITP 2025) shows the pattern for later scale: a fast engine finds derivations, Lean checks them.

**Reasoning under uncertainty.** Subjective logic was chosen over the alternatives for specific reasons. Probabilistic logic programming (ProbLog; Scallop, Li et al. 2023) collapses conflict into one probability, so a contested claim looks like a coin flip. Markov logic and Probabilistic Soft Logic run a global optimisation that is hard to audit per proof. Bayesian networks need a joint model the literature does not supply. Dung's argumentation frameworks (1995) and ASPIC+ handle attack and defeat elegantly but have no strength algebra of their own; they are a natural *layer on top* for the competing-hypotheses problem, and Hunter and Williams (2012) applied exactly that to aggregating treatment evidence. Clinical grading schemes, GRADE, Oxford CEBM, ClinGen's gene validity scoring and the ACMG framework as a Bayesian system (Tavtigian et al. 2018), are the evidence hierarchies the default weight table imitates.

**LLM extraction.** OntoGPT's SPIRES (Caufield et al. 2024) is the closest template for schema-driven extraction with grounding. The claim-verification literature, SciFact (Wadden et al. 2020) and successors, is directly relevant because it labels evidence as supporting or refuting a claim, which is exactly BioLean's polarity.

## 7. The pipeline from text to Lean

The Python side, managed with uv, has four file-in, file-out stages so each can be run and inspected alone.

**Corpus.** DuckDB over the local parquet of 28.5 million abstracts. A full scan takes about a minute on this machine; sub-corpora are built once and queried many times.

**Extract.** The official Anthropic SDK calls Claude with structured outputs. The schema is the contract with the Lean side: a verbatim quote, a subject and object mention with kinds, one of eight signed relations, polarity, evidence kind, species, and a hedged flag. The long instructions sit in a cached system prompt. One abstract that is refused or truncated is logged and skipped rather than sinking the batch; this was learned the hard way.

**Ground.** A lookup table of about 574,000 labels and synonyms from ChEBI, GO, HP, MONDO, UBERON, CL, PATO and human UniProt is built once from the corpus. Grounding is exact, case-insensitive, restricted to the mention's kind, and never guesses; ambiguous matches are flagged and dropped.

**Emit.** Grounded statements are grouped by (subject, relation, object) into Lean `Statement` definitions, one `Evidence` per PMID, with kind mismatches refused at emit time because Lean would refuse them at compile time anyway. The emitted file type-checks against the real library.

The first live run over 22 curated abstracts extracted 113 statements from 15 abstracts, grounded 57 percent of mentions and 23 percent of statements, and emitted 18 Lean statements. Three findings from that run shape the next steps. Claude's safety classifier refused five of the twenty-two abstracts, all ordinary GLP-1 pharmacology, which at corpus scale is a real constraint and argues for the API's server-side fallback routing. The grounder mapped "GLP-1" to ZGLP1, a zinc-finger protein, through a UniProt synonym; kind-restricted exact matching is not enough. And everyday phenotype words, food intake, body weight, hunger, do not hit clinical HP labels at all.

## 8. What is known to be wrong or missing

These are ordered by how much they threaten the verdicts.

**Independence.** Every fusion rule in use, BioLean's included, assumes independent witnesses. Papers cite each other, reviews restate trials, and one experiment can be the real source behind fifty citations. Duplicate PMIDs are now dropped within a statement, and reports warn when a derivation uses the same statement twice, but nothing discounts a review that repeats a trial already counted. INDRA hit the same wall and handled it by saturating belief within a source. A principled answer probably needs citation-graph awareness.

**Reading reliability versus scientific strength.** One number per evidence kind conflates "how likely is it that the extraction is right" with "how strong is the study". INDRA keeps these apart. BioLean should too: a text-mined item should be discounted for extraction error *before* it counts as biology.

**Chains hide conflict.** Because `chain` sets disbelief to zero, a derived claim can never come out contested through its mechanism alone. The report should at least list contested axioms a proof rests on; a fuller fix needs a serial operator that propagates some disbelief, which subjective logic's deduction operator does at the cost of a base rate.

**No context.** Claims carry no species, tissue, dose or condition. Most apparent contradictions in the literature are context differences. The super-pattern of Bucur et al. (2021) and BEL's annotation model show what a context slot looks like.

**No ontology inference.** "Specific claim supports general claim" via `is_a` is absent. INDRA found that this refinement step let 38 percent of its statements support others.

**Uncalibrated weights.** The default table is a starting point. GOA's ECO codes and GO-CAM edges give a calibration set.

**Grounding.** Exact match, broken synonyms in the corpus export, and the ZGLP1 failure. Gilda or a fuzzy layer is the next step.

## 9. Scope: what it would take to grow

The data already on this machine covers the plan: 28.5 million abstracts with 8.4 million embedded, 6 million ontology terms, 71 thousand UniProt entries, GOA for nine species, PubTator3 bulk relations and Open Targets 26.06.

The right order is curated sources first, text-mined relations second, LLM extraction aimed at the gaps. GO-CAM's roughly 1,500 models, SIGNOR and Reactome become the first non-demo biolib modules through importers that map their edge formats onto `Statement`. PubTator3 and Open Targets' 26 million text-mined sentences come in as low-weight evidence. LLM extraction over the whole of PubMed with a Haiku-class model costs on the order of fourteen thousand dollars; with an Opus-class model it costs about half a million, so Opus is for targeted disease areas, where it costs roughly nine thousand dollars per half-million abstracts. At thousands of statements, derivation search moves out of Lean into a Datalog engine with Lean checking the certified tree, the CertifyingDatalog pattern. Competing hypotheses eventually get an argumentation layer over derivations; there is no Lean formalisation of abstract argumentation yet, and that is a research project in its own right.

## 10. Why this might matter

The pitch is not that Lean will discover biology. It is that a verdict about a biological claim can be an object you can hand to someone: a typed argument the kernel has checked, a strength computed by a stated algebra from a listed set of papers, and an explicit flag when the literature disagrees. Reviews do this informally. Knowledge graphs do the first half without the arithmetic or the shape check. INDRA does the arithmetic without the shape. BioLean's bet is that putting the three together, and making the result a reusable lemma, is the step that turns the literature into something cumulative.

---

## References

Knowledge assembly
- Bachman, Gyori, Sorger. Automated assembly of molecular mechanisms at scale from text mining and curated databases. Mol Syst Biol 2023. https://doi.org/10.15252/msb.202211325
- Gyori et al. From word models to executable models of signaling networks using automated assembly. Mol Syst Biol 2017. https://doi.org/10.15252/msb.20177651
- INDRA https://github.com/gyorilab/indra ; EMMAA https://github.com/gyorilab/emmaa ; indra-belief-model https://github.com/gyorilab/indra-belief-model
- Gyori, Hoyt, Steppi. Gilda. Bioinformatics Advances 2022. https://doi.org/10.1093/bioadv/vbac034

Relations and knowledge graphs
- Wei et al. PubTator 3.0. NAR 2024. https://arxiv.org/abs/2401.11048 ; https://ftp.ncbi.nlm.nih.gov/pub/lu/PubTator3/
- Thomas et al. GO-CAM. Nature Genetics 2019. https://doi.org/10.1038/s41588-019-0500-1
- Giglio et al. ECO. NAR 2019. https://doi.org/10.1093/nar/gky1036
- SIGNOR 4.0, NAR 2026. https://pmc.ncbi.nlm.nih.gov/articles/PMC12807704/
- Reactome. https://reactome.org/download-data
- Open Targets evidence and scoring. https://platform-docs.opentargets.org/evidence
- Biolink Model. Unni et al. Clin Transl Sci 2022. https://doi.org/10.1111/cts.13302
- Hoyt et al. PyBEL. Bioinformatics 2018. https://doi.org/10.1093/bioinformatics/btx660
- Kilicoglu et al. SemRep. BMC Bioinformatics 2020. https://pmc.ncbi.nlm.nih.gov/articles/PMC7222583/

Nanopublications and provenance
- Groth, Gibson, Velterop. The anatomy of a nanopublication. Inf Serv Use 2010. https://doi.org/10.3233/ISU-2010-0613
- Kuhn et al. Decentralized provenance-aware publishing with nanopublications. PeerJ CS 2016. https://doi.org/10.7717/peerj-cs.78
- Gibson, van Dam, Schultes, Roos, Mons. Cardinal assertions. SWAT4LS 2012. https://ceur-ws.org/Vol-952/paper_26.pdf
- Mons et al. WikiProteins. Genome Biology 2008. https://doi.org/10.1186/gb-2008-9-5-r89
- Bucur, Kuhn, Ceolin, van Ossenbruggen. Expressing high-level scientific claims with formal semantics. K-CAP 2021. https://doi.org/10.1145/3460210.3493561
- Brush, Shefchek, Haendel. SEPIO. ICBO 2016. https://github.com/sepio-framework/sepio-linkml
- GA4GH VA-Spec. https://va-spec.ga4gh.org/
- Clark, Ciccarese, Goble. Micropublications. J Biomed Semantics 2014. https://doi.org/10.1186/2041-1480-5-28

Formal methods
- Eker et al. Pathway Logic. WRLA 2002. https://pl.csl.sri.com/
- Calzone, Fages, Soliman. BIOCHAM. Bioinformatics 2006. https://doi.org/10.1093/bioinformatics/btl172
- Boutillier et al. Kappa platform. Bioinformatics 2018. https://doi.org/10.1093/bioinformatics/bty272
- Rashid, Hasan, Siddique, Tahar. Formal reasoning about systems biology using theorem proving. PLoS One 2017. https://doi.org/10.1371/journal.pone.0180179
- Tooby-Smith. HepLean / PhysLean. 2024. https://arxiv.org/abs/2405.08863
- crnt-lean. https://github.com/marpaia/crnt-lean
- provenance-lean. https://github.com/PierreSenellart/provenance-lean
- Tantow, Gerlach, Mennicke, Krötzsch. Verifying Datalog reasoning with Lean. ITP 2025. https://doi.org/10.4230/LIPIcs.ITP.2025.36

Uncertainty and conflict
- Jøsang. Subjective Logic. Springer 2016. https://doi.org/10.1007/978-3-319-42337-1
- van der Heijden, Kopp, Kargl. Multi-source fusion operations in subjective logic. 2018. https://arxiv.org/abs/1805.01388
- Tavtigian et al. ACMG/AMP as a Bayesian framework. Genet Med 2018. https://doi.org/10.1038/gim.2017.210
- Strande et al. ClinGen gene-disease validity. AJHG 2017. https://doi.org/10.1016/j.ajhg.2017.04.015
- Green, Karvounarakis, Tannen. Provenance semirings. PODS 2007. https://doi.org/10.1145/1265530.1265535
- Li, Huang, Naik. Scallop. PLDI 2023. https://doi.org/10.1145/3591280
- De Raedt, Kimmig, Toivonen. ProbLog. IJCAI 2007. https://github.com/ML-KULeuven/problog
- Dung. On the acceptability of arguments. Artif Intell 1995. https://doi.org/10.1016/0004-3702(94)00041-X
- Modgil, Prakken. ASPIC+ tutorial. Argument and Computation 2014. https://doi.org/10.1080/19462166.2013.869766
- Hunter, Williams. Aggregating evidence about the effects of treatments. Artif Intell Med 2012. https://doi.org/10.1016/j.artmed.2012.09.004

LLM extraction and claim verification
- Caufield et al. SPIRES / OntoGPT. Bioinformatics 2024. https://doi.org/10.1093/bioinformatics/btae104
- Wadden et al. SciFact. EMNLP 2020. https://arxiv.org/abs/2004.14974

Lean
- Lean 4 and Mathlib. https://lean-lang.org/ ; https://github.com/leanprover-community/mathlib4
