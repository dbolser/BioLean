## Did it find the holes we found by hand?

No. G1 (organelle abundance) and G6 (the sugary drink) were not rediscovered, and none of the other six was either. The hand-found holes sit in sentences the formal vocabulary cannot hold yet: six of the eight are blocked outright (G1, G2, G4, G5, G7, G8), G3 is half blocked, and G6 was annotated so that its hole disappeared. Loading G1 would still not be enough: it needs a rule rather than a fact.

| case | textbook sentence | why the search cannot see it |
|---|---|---|
| G1 | `cell:m45432-155`, `-189`, `-203` (abundant Golgi, ribosomes, mitochondria) | not loaded: no constructor, blocked as `quantity` |
| G2 | `inherit:m45467-66` (tortoiseshell cat) | not loaded: blocked as `necessity` |
| G3 | `cell:m45432-260`, `-261`, `-262` (endosymbiosis) | `-260` not loaded; `-261`, `-262` are, and the search offers only "organelles derive from cyanobacteria", which is false in general (last row of the second table) |
| G4 | `molbio:m45475-117` (defective repair, skin cancer) | not loaded: `context_required` |
| G5 | `cell:m45429-66` (10 to 100 times the size) | not loaded: `quantity` |
| G6 | `body:m45537-52` (sugary drink) | loaded, but as "glucose raises insulin": the annotator replaced the drink by glucose, so the missing edge (drink raises glucose) never forms |
| G7 | `body:m45535-103` (villi) | not loaded: `compound_sentence` |
| G8 | `photo:m45448-30` (deer are heterotrophs) | not loaded: `unsupported_ontology` |

Two what-if runs on a scratch copy (nothing committed) show what the tool does once the sentences are in.
- **G6**, with the drink grounded to sucrose and `body:m45537-200` unblocked: the search proposes "sucrose raises the amount of glucose", an ordinary `viaAmount` hole, and it completes exactly that sentence. So the enumeration handles the G6 shape; the annotation hid it.
- **G1**, with two of the three sentences reloaded as `has part` (muscle cell has mitochondrion, immature red cell has ribosome): the search proposes "immature red cell is_a cell" (the plain existential, true but not the point) and a swarm of arbitrary-intermediate `has part` holes. It does not propose the demand rule, and cannot: G1 is a hole in the *rule set*, not in the facts. Abundance follows from "the organelle can do F" plus "the cell has a high demand for F" only if a rule says so. With that rule given, the same enumeration would propose the missing demand facts (muscle uses a lot of ATP) as holes. Finding the rule itself from the three sentences is rule induction (anti-unify the three), which is the next ILP step and not what this tool does.

What this measures: **the hand-found holes live exactly where the formal vocabulary stops.** Hole search at the level of facts works inside the formalised fragment; the interesting gaps are in what the constructors cannot hold yet. Phase 2 (re-annotation of the quantity and context claims) is what lets this tool reach them.

## The five best hypotheses, in my judgement

1. **The parasympathetic and sympathetic systems oppose each other** (rows 2 and 3). One idea explains six textbook sentences (heart rate, blood pressure, digestion, each way round). The search can only say it as "lowers the amount of", which is the wrong type, so the real finding is a schema gap: the book states antagonism at three effectors and we have no symmetric "opposes" relation to hold it once.
2. **LDL receptors lower cholesterol** (beyond the top 40). It is the mechanism step behind "familial hypercholesterolemia raises cholesterol". True, and the book gives the defect (receptor activity lowered) and the outcome (cholesterol raised) without the edge between them. This is the G6 shape, found without being looked for.
3. **Cyclooxygenase raises fever** (beyond the top 40). Same shape: "paracetamol lowers fever" is a theorem the moment this edge exists, through the COX inhibition the book already states.
4. **"Anti-inflammatory drug lowers inflammation"** (row 21), and its twin "DNA repair lowers thymine dimers". These are real inductions, not look-ups: two instances (aspirin, corticosteroid) generalise to the class. It is the generalise step (M4) done on a tiny scale, and it is sound here because the class is defined by the effect.
5. **p53, p21 and RB1 act through checkpoint signalling** (beyond the top 40). The same hole shape completes three separate sentences about three tumour suppressors. The book says what each does to the cell cycle and never says that checkpoints are the route.

Honourable mentions: "S phase precedes mitosis", "cellular respiration ends with the electron transport chain", "photosynthesis ends with the Calvin cycle" (process order, true, unstated).

## Things the search showed along the way

- **Obsolete terms in the grounding.** Four entities the facts use are obsolete in the ontologies: CL:0000548 (animal cell), GO:0000003 (reproduction), GO:0003896 (DNA primase activity), GO:0019661 (homolactic fermentation). 59 holes were dropped for this reason alone. This is a grounding check we did not have.
- **Split concepts.** "Thylakoid" and "chloroplast thylakoid" both appear as separate entities, so one piece of content is spread across two facts. The is_a hole repairs it (rows 33, 34 and 36).
- **Chain rules have no direction.** For every transitive or chain rule the search proposes both orders (`A ends with B` and `B ends with A`), and the book usually supports only one. 20 of the top 40 are judged rule-caveat artefacts, and many of those are the wrong-way or sibling twin of a good hole. 95 holes are confirmed by an ontology, which is the cheap and safe subset to import (task 1b).
- **Effect chains confuse three things.** Parthood read as causation (actin filament and cytoskeleton), a common cause read as a chain (depolarisation opens both channels), and feedback through ATP read as a one-way effect. These need a part-of rule, a "shared cause" check and a loop flag; none exists yet.
- **Holes at the class level overshoot.** For the is_a rules, a hole that states the property of the superclass ("endocrine gland produces insulin") claims more than the sentence it completes. Negatives are needed to prune these; the corpus has 27.

## Limits

- Sentences completed (the first sort key) rewards coincidence: a hole through an arbitrary intermediate completes two sentences just because two cells have ribosomes. Grouping alternatives helps (2,172 holes become 842 hypotheses) but does not cure it. The cure is a plausibility signal; the ontology check is the only one we have and it decides only `is_a` and `part_of` for GO, UBERON, CL and ChEBI (MONDO, NCBITaxon and PR holes stay undecided).
- Only single-premise holes. Two missing premises, or a missing rule, are out of reach (see G1).
- "Follows from nothing else" is checked one step over the closure; 12 instantiations were skipped because the other premise exists only because of the sentence itself.
- Effect holes are screened only by the Lean `Target` kinds, so many `viaAmount` holes with a non-molecular middle term remain (they are judged as artefacts, not removed).
