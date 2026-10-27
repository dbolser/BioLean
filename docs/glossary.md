# Glossary

The words we use, what each one concretely is in BioLean, and the nearest everyday meaning.
Maths and Lean words first, then our own.

## Logic and Lean words

| word | what it concretely is here | plain reading |
|---|---|---|
| **proposition** | a sentence that is either true or false, e.g. "7/10 ≤ belief of d" | a yes/no question |
| **premise** | a claim an argument starts from. In a `Derivation`, the sub-derivations fed to a rule; at the leaves, Statements | the "because" part |
| **conclusion** | the claim a rule produces from its premises; the index `c` in `Derivation c` | the "therefore" part |
| **rule** | a Derivation constructor: how premises of given shapes yield a conclusion of a given shape (`viaAmount`, `relChain`, ...) | one allowed move |
| **instance (of a rule)** | the rule with concrete entities filled in, e.g. row 139 with gonad and steroid hormone | an example |
| **proof** | a term whose type is the proposition; Lean's kernel checks it | a certificate that the question's answer is yes |
| **theorem** | a named proposition with a proof, e.g. `semaglutide_reduces_hunger` | a checked fact |
| **lemma** | a theorem whose job is to help prove other theorems | a stepping stone |
| **axiom** | something taken as true without proof. In Lean, a declared `axiom`; in BioLean, a `Statement` (a paper's or textbook's claim with its evidence). `Derivation.axioms` lists them | the starting assumptions |
| **definition** | a name for a term or a type, e.g. `def fuse`, `def gonad` | a label |
| **type** | a classification of terms; `Entity .process`, `Derivation c`, `ℚ` | what sort of thing it is |
| **inductive type** | a type defined by listing its constructors, e.g. `Claim` has `effect`, `mediatedBy`, `rel`, `notRel` | a menu of allowed shapes |
| **constructor** | one way to build a value of an inductive type, e.g. `Derivation.relChain` | one item on the menu |
| **dependent type / indexed family** | a type that mentions a value: `Derivation c` is the type of derivations *of claim c*. You cannot put a derivation of one claim where another is expected | the label carries the content |
| **kernel** | Lean's small trusted checker. `decide +kernel` makes it evaluate a decidable proposition to true | the referee |
| **decide / decidable** | a proposition the computer can settle by computation (comparing rationals, list membership) | look it up, don't argue |
| **autoParam** (`:= by decide`) | an argument Lean fills in by running a tactic when you omit it, e.g. the domain/range check on `Claim.rel` | checked automatically |
| **implicit argument** `{k : Kind}` | an argument Lean infers from the others | filled in from context |
| **currying** | a function of two arguments is a function of one argument returning a function of the next; `fuse x y` is `(fuse x) y`. Purely a notation fact | one at a time |
| **term** | any well-typed expression: a number, a derivation, a proof | a thing |
| **tactic** | a program that builds a proof term for you (`decide`, `linarith`, `norm_num`) | a proof helper |
| **sound** | a rule that never derives a false conclusion from true premises | trustworthy |
| **existential** `∃` | "there is some x such that ..." | at least one |
| **universal** `∀` | "for every x ..." | all of them |

## Ontology words

| word | what it concretely is | plain reading |
|---|---|---|
| **ontology** | a controlled vocabulary with identifiers, definitions and logical relations between terms (GO, UBERON, CL, ChEBI) | an agreed dictionary with a family tree |
| **CURIE** | a compact identifier, `GO:0005634` | the dictionary entry number |
| **is_a** (rdfs:subClassOf) | every X is a Y. `hepatocyte is_a eukaryotic cell` | kind of |
| **relation / object property** | a named link between two classes: part_of, occurs_in, has_output | a verb |
| **RO** | the Relation Ontology, the shared list of relations and their logic | the verb list |
| **BFO** | Basic Formal Ontology, the top-level split into things (continuants) and happenings (occurrents) | the grammar |
| **domain / range** | what kinds of thing may stand on the left and right of a relation | who may do the verb to whom |
| **property chain** | an axiom `r₁ ∘ r₂ ⊑ r₃`: if a r₁ b and b r₂ c then a r₃ c. RO has 164 | two verbs that add up to a third |
| **transitive** | `part_of ∘ part_of ⊑ part_of` | passes through |
| **inverse** | `has_part` is the inverse of `part_of` | the same link read backwards |
| **OWL 2 EL** | the logic fragment most OBO ontologies use so reasoners run fast; no negation, no counting | the cheap dialect |
| **CLIF** | Common Logic Interchange Format, first-order logic as text; BFO 2020 is fully written in it, RO barely | the full-strength dialect |
| **existential restriction** | "X has_part some nucleus" says every X has at least one nucleus part | at least one of |

## BioLean words

| word | what it concretely is | plain reading |
|---|---|---|
| **Entity** | a thing with a CURIE and a label, typed by **Kind** (chemical, protein, process, anatomy, ...) | a noun |
| **Claim** | one formal sentence: a signed effect, a mediated effect, an RO relation, or a negated relation | a sentence |
| **Statement** | a Claim plus its evidence (PMIDs, years, kinds, polarity). The axiom unit | a cited sentence |
| **Evidence** | one citation with an **EvidenceKind** (RCT, review, textbook, ontologyAxiom, ...) | one reference |
| **reliability** | the weight of one evidence item, in [0, 1). Equivalent to a pseudo-count of observations | how much one reference counts |
| **Opinion** | (belief, disbelief, uncertainty), summing to 1, over exact rationals | how sure, how against, how unknown |
| **fuse** | combine two independent opinions about the same claim | pool the evidence |
| **chain** | carry belief through a step: belief multiplies, nothing becomes disbelief | weakest-link reasoning |
| **negate** | swap belief and disbelief | the opinion about "not" |
| **Derivation c** | a tree of rules ending in claim c. Lean checks its shape; `opinion` computes its strength | an argument |
| **lit** | the leaf rule: a Statement used as an axiom | "because this paper says so" |
| **viaActivity / viaAmount** | chain two effects through a protein's activity or a molecule's amount | A affects B, B affects C, so A affects C |
| **both** | fuse two derivations of the same claim | two independent arguments |
| **relChain** | compose two RO relations by an RO axiom | the ontology's own logic |
| **clash** | a derivation against its negation, read as one opinion | the two sides weighed |
| **Verdict** | established / contested / refuted / unsupported, from an opinion by thresholds θ and τ | the one-word summary |
| **Established c θ** | the proposition "some derivation of c has belief ≥ θ". Proving it is the BioLean theorem | shown to this standard |
| **axioms (of a derivation)** | the Statements it rests on, like `#print axioms` in Lean | what this depends on |
| **biolib** | the library of named Statements and Derivations other proofs reuse | the shared results |
| **context** | where a claim holds: taxon, tissue, cell type, stage, condition (proposed, M2) | in mice, in liver |
| **generalize / specialise / transport** | proposed rules: many instances to a universal; universal to an instance; one species to another | from cases to rule; rule to case; mouse to human |
| **hole** | a derivation missing one premise. The missing premise is a hypothesis | the gap in the argument |
