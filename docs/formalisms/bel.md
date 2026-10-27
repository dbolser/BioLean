# BEL 2.x annotation of the chemiosmotic and NMN papers

**Formalism.** BEL (Biological Expression Language) 2.x is a line-based script. The unit of annotation is one
*statement*: `subject relation object`. Subject and object are terms built from functions: `a()` abundance,
`p()` protein, `complex()`, `bp()` biological process, `path()` pathology, `act()` activity, `tloc()`
translocation, `rxn()` reaction, `pmod()` modification, `loc()` location. Each term argument is `NS:ID!label`.
Relations include `increases`, `decreases`, `directlyIncreases`, `causesNoChange`, `association`,
`positiveCorrelation`, `negativeCorrelation`, `hasComponent`, `isA`, `rateLimitingStepOf`. Context lives
outside the statement, in a stack of `SET` annotations (`Citation`, `Evidence`, `Species`, `Anatomy`, `Cell`,
`Disease`, `CellLine`, plus any user annotation declared with `DEFINE ANNOTATION`). Every statement below the
`SET` lines inherits them until `UNSET`. BEL has no built-in way to say "this is a hypothesis", "this was
refuted", "dose = X", or "effect size = Y". It also cannot say that statement A argues against statement B. So
below I declare a few custom annotations (`Assertion`, `Dose`, `Duration`, `Age`, `Sex`, `Strain`, `System`,
`Quantity`, `Supports`, `Refutes`, `Provenance`) and say so. Those custom annotations are legal BEL. But they
are *opaque* to every BEL tool: no reasoner will treat `Refutes` as logic. IDs were checked with the OLS4 and
UniProt REST APIs on 2026-10-26. `?:unverified` marks an ID I could not confirm.

## Shared document header (applies to all papers below)

```bel
SET DOCUMENT Name = "BioLean formalism comparison: BEL"
SET DOCUMENT Version = "0.1"

DEFINE NAMESPACE CHEBI  AS URL "http://purl.obolibrary.org/obo/chebi.owl"
DEFINE NAMESPACE GO     AS URL "http://purl.obolibrary.org/obo/go.owl"
DEFINE NAMESPACE MGI    AS URL "http://www.informatics.jax.org"
DEFINE NAMESPACE HGNC   AS URL "https://www.genenames.org"
DEFINE NAMESPACE UP     AS URL "https://www.uniprot.org/uniprot"
DEFINE NAMESPACE MP     AS URL "http://purl.obolibrary.org/obo/mp.owl"
DEFINE NAMESPACE HP     AS URL "http://purl.obolibrary.org/obo/hp.owl"
DEFINE NAMESPACE MONDO  AS URL "http://purl.obolibrary.org/obo/mondo.owl"
# Local namespace for entities that exist only as hypotheses (no public ID can exist)
DEFINE NAMESPACE BIOLEAN AS LIST {"C~I high-energy intermediate", "electrochemical proton gradient",
    "anisotropic respiratory chain", "anisotropic membrane ATPase", "H+/O quotient",
    "membrane proton conductance", "membrane ion impermeability", "pseudohypoxic state",
    "nuclear-mitochondrial communication (PGC-1-independent)", "submitochondrial particle lumen"}

DEFINE ANNOTATION Species  AS URL "http://purl.obolibrary.org/obo/ncbitaxon.owl"
DEFINE ANNOTATION Anatomy  AS URL "http://purl.obolibrary.org/obo/uberon.owl"
DEFINE ANNOTATION Cell     AS URL "http://purl.obolibrary.org/obo/cl.owl"
DEFINE ANNOTATION CellStructure AS URL "http://purl.obolibrary.org/obo/go.owl"
DEFINE ANNOTATION Disease  AS URL "http://purl.obolibrary.org/obo/mondo.owl"
DEFINE ANNOTATION EvidenceCode AS URL "http://purl.obolibrary.org/obo/eco.owl"
# Custom annotations: legal BEL, but no BEL tool gives them meaning
DEFINE ANNOTATION Assertion  AS LIST {"Hypothesis", "Prediction", "ExperimentalResult", "AuthorConclusion"}
DEFINE ANNOTATION System     AS LIST {"in vivo", "in vitro", "ex vivo", "reconstituted", "clinical RCT"}
DEFINE ANNOTATION Strain     AS PATTERN ".*"
DEFINE ANNOTATION Age        AS PATTERN ".*"
DEFINE ANNOTATION Sex        AS LIST {"female", "male", "both", "not stated"}
DEFINE ANNOTATION Dose       AS PATTERN ".*"
DEFINE ANNOTATION Duration   AS PATTERN ".*"
DEFINE ANNOTATION Diet       AS PATTERN ".*"
DEFINE ANNOTATION Quantity   AS PATTERN ".*"
DEFINE ANNOTATION Supports   AS PATTERN ".*"   # free-text pointer to a hypothesis
DEFINE ANNOTATION Refutes    AS PATTERN ".*"
DEFINE ANNOTATION Provenance AS LIST {"abstract", "summary"}
```

Verified IDs used repeatedly: hydron CHEBI:15378, ATP CHEBI:15422, ADP CHEBI:16761, phosphate CHEBI:26020,
NAD(+) CHEBI:15846, nicotinamide mononucleotide CHEBI:50383, proton motive force-driven ATP synthesis GO:0015986,
proton motive force-driven mitochondrial ATP synthesis GO:0042776, oxidative phosphorylation GO:0006119,
photosynthetic phosphorylation GO:0009777, electron transport coupled proton transport GO:0015990, respiratory
electron transport chain GO:0022904, proton-transporting ATP synthase complex GO:0045259. Note: GO:0005753
(mitochondrial proton-transporting ATP synthase complex) and GO:0007568 (aging) are now **obsolete** in GO;
I avoided them.

## 1. Mitchell 1961, chemiosmotic hypothesis (PMID 13771349)

```bel
SET Citation = {"PubMed", "Nature", "13771349"}
SET Provenance = "summary"
SET Assertion = "Hypothesis"
SET EvidenceCode = "ECO:0000001"
SET Species = {"10116", "3562"}
SET Evidence = "the respiratory chain is arranged anisotropically in the mitochondrial membrane so that electron transfer translocates protons across it, generating an electrochemical proton gradient"

# H1: electron transfer pushes protons out of the matrix
bp(GO:0022904!"respiratory electron transport chain") directlyIncreases tloc(a(CHEBI:15378!hydron), fromLoc(GO:0005759!"mitochondrial matrix"), toLoc(GO:0005758!"mitochondrial intermembrane space"))
tloc(a(CHEBI:15378!hydron), fromLoc(GO:0005759!"mitochondrial matrix"), toLoc(GO:0005758!"mitochondrial intermembrane space")) increases a(BIOLEAN:"electrochemical proton gradient")

SET Evidence = "a reversible, anisotropic membrane ATPase uses that gradient to synthesise ATP from ADP and phosphate"
# H2: the gradient drives the ATPase backwards (ATP synthesis)
a(BIOLEAN:"electrochemical proton gradient") directlyIncreases act(complex(GO:0045259!"proton-transporting ATP synthase complex"))
act(complex(GO:0045259!"proton-transporting ATP synthase complex")) directlyIncreases rxn(reactants(a(CHEBI:16761!ADP), a(CHEBI:26020!phosphate)), products(a(CHEBI:15422!ATP)))
# H3: the claim in one line, as a process-level statement
bp(GO:0015990!"electron transport coupled proton transport") increases bp(GO:0006119!"oxidative phosphorylation")
a(BIOLEAN:"electrochemical proton gradient") increases bp(GO:0009777!"photosynthetic phosphorylation")

SET Assertion = "Prediction"
SET Evidence = "Predictions: the coupling membrane must be ion-impermeable; uncouplers act by making it proton-permeable."
# P1: an uncoupler raises proton conductance and so dissipates the gradient
# (no verified CHEBI class 'uncoupler'; 2,4-dinitrophenol used as the exemplar)
a(CHEBI:42017!"2,4-dinitrophenol") increases a(BIOLEAN:"membrane proton conductance")
a(BIOLEAN:"membrane proton conductance") decreases a(BIOLEAN:"electrochemical proton gradient")
# P2: membrane impermeability is required for coupling
a(BIOLEAN:"membrane ion impermeability") positiveCorrelation bp(GO:0006119!"oxidative phosphorylation")
UNSET ALL
```

Could not express:
- That these are a *hypothesis* and *predictions*, except via my custom `Assertion` annotation. BEL tools read
  them as asserted facts.
- That it is a rival to Slater's hypothesis (no relation between statements or between hypotheses).
- "Electrochemical proton gradient" as a real entity: no CHEBI/GO term for a gradient or for proton motive
  force (only for processes driven by it). I used a local namespace. A gradient is a *difference* between two
  locations, and BEL can only put an abundance in one location.
- "Necessary" vs "sufficient". BEL has `increases`, not "requires" or "is sufficient for".
- "Anisotropic" arrangement (membrane orientation / sidedness of the complex).
- Species: the hypothesis is general (mitochondria and chloroplasts). `Species` must list concrete taxa;
  I listed rat and spinach only as a stand-in.

## 2. Slater 1953, chemical-intermediate hypothesis (PMID 13111237)

```bel
SET Citation = {"PubMed", "Nature", "13111237"}
SET Provenance = "summary"
SET Assertion = "Hypothesis"
SET EvidenceCode = "ECO:0000001"
SET Evidence = "energy from electron transfer in the respiratory chain is conserved in a non-phosphorylated high-energy chemical intermediate (written C~I) formed between a carrier and a hypothetical compound, which then reacts with inorganic phosphate and ADP to yield ATP"

# S1: electron transfer makes the intermediate C~I
bp(GO:0022904!"respiratory electron transport chain") directlyIncreases a(BIOLEAN:"C~I high-energy intermediate")
# S2: C~I + Pi + ADP -> ATP (substrate-level style)
rxn(reactants(a(BIOLEAN:"C~I high-energy intermediate"), a(CHEBI:26020!phosphate), a(CHEBI:16761!ADP)), products(a(CHEBI:15422!ATP)))
a(BIOLEAN:"C~I high-energy intermediate") directlyIncreases rxn(reactants(a(CHEBI:16761!ADP), a(CHEBI:26020!phosphate)), products(a(CHEBI:15422!ATP)))
# S3: process-level form of the same claim
a(BIOLEAN:"C~I high-energy intermediate") increases bp(GO:0006119!"oxidative phosphorylation")

SET Assertion = "Prediction"
SET Evidence = "Implied by the hypothesis (secondary sources): uncouplers should act by hydrolysing C~I"
# Curator-implied prediction (not in the summary itself)
a(CHEBI:42017!"2,4-dinitrophenol") decreases a(BIOLEAN:"C~I high-energy intermediate")
UNSET ALL
```

Could not express:
- That C~I is *hypothetical* (it has never been isolated). It sits in a local namespace exactly like a real
  molecule would.
- "By analogy with glycolytic substrate-level phosphorylation": BEL has no analogy or reasoning relation.
- That S1-S3 and Mitchell's H1-H3 are *mutually exclusive* explanations of the same process. Both just sit in
  the graph as two paths to `bp(oxidative phosphorylation)`. A BEL graph happily holds both.
- The uncoupler line is my inference, not in the summary. BEL cannot mark "curator inference" except
  via ECO code / custom annotation.

## 3. Jagendorf & Uribe 1966, acid-bath ATP synthesis (PMID 5220864)

```bel
SET Citation = {"PubMed", "Proc Natl Acad Sci U S A", "5220864"}
SET Provenance = "summary"
SET Species = "3562"
SET CellStructure = "GO:0009535"
SET System = "in vitro"
SET EvidenceCode = "ECO:0000181"
SET Assertion = "ExperimentalResult"
SET Supports = "Mitchell 1961 H2 (PMID 13771349)"
SET Refutes = "Slater 1953 S1-S3 (PMID 13111237)"
SET Evidence = "Isolated spinach chloroplast thylakoids were equilibrated in the dark at pH ~4 (succinate buffer), then rapidly shifted to pH ~8 in the presence of ADP and inorganic phosphate. ATP was synthesised in the dark"
SET Quantity = "internal pH ~4, external pH ~8; dark"

# R1: a lumen-acid / stroma-alkaline proton imbalance drives ATP synthesis, no light, no electron flow
composite(a(CHEBI:15378!hydron, loc(GO:0031977!"thylakoid lumen")), a(CHEBI:16761!ADP), a(CHEBI:26020!phosphate)) increases rxn(reactants(a(CHEBI:16761!ADP), a(CHEBI:26020!phosphate)), products(a(CHEBI:15422!ATP)))
# R2: efflux of protons lumen -> stroma drives ATP synthase
tloc(a(CHEBI:15378!hydron), fromLoc(GO:0031977!"thylakoid lumen"), toLoc(GO:0009570!"chloroplast stroma")) increases act(complex(GO:0045259!"proton-transporting ATP synthase complex"))
a(BIOLEAN:"electrochemical proton gradient") increases bp(GO:0009777!"photosynthetic phosphorylation")

SET Evidence = "with yield depending on the size of the pH jump and on the permeant acid used"
UNSET Quantity
# R3: dose-response on the pH jump (only as a correlation)
a(BIOLEAN:"electrochemical proton gradient") positiveCorrelation a(CHEBI:15422!ATP)
# R4: the permeant acid matters (succinate was the one named)
a(CHEBI:26806!succinate) increases a(CHEBI:15378!hydron, loc(GO:0031977!"thylakoid lumen"))

SET Assertion = "AuthorConclusion"
SET Evidence = "The authors conclude that a transmembrane pH gradient alone can drive ATP formation, as predicted by the chemiosmotic hypothesis."
a(BIOLEAN:"electrochemical proton gradient") increases bp(GO:0015986!"proton motive force-driven ATP synthesis")
UNSET ALL
```

Could not express:
- "pH 4 then pH 8". BEL has no numeric values; the pH values live in a free-text `Quantity` annotation.
- The *gradient* as a difference between lumen and stroma. `a(hydron, loc(lumen))` says "protons in the lumen",
  not "more protons in the lumen than outside".
- "Alone" / sufficiency: the key logical point (no electron transport, no C~I needed). BEL's `increases` cannot
  carry "sufficient" or "in the absence of X".
- The dark condition and the absence of electron flow as an experimental *control*.
- Support for Mitchell / refutation of Slater: only free-text `Supports` / `Refutes`, invisible to BEL
  reasoning.
- The yield-vs-pH-jump curve (quantity, not direction).

## 4. Mitchell & Moyle 1967, respiration-driven proton translocation (PMID 16742541)

```bel
SET Citation = {"PubMed", "Biochem J", "16742541"}
SET Provenance = "abstract"
SET Species = "10116"
SET Anatomy = "UBERON:0002107"
SET CellStructure = "GO:0005743"
SET System = "in vitro"
SET EvidenceCode = "ECO:0000181"
SET Assertion = "ExperimentalResult"
SET Supports = "Mitchell 1961 H1 (PMID 13771349)"
SET Refutes = "Slater 1953 S1 (PMID 13111237)"

SET Evidence = "Pulses of acidity of the outer aqueous phase of rat liver mitochondrial suspensions induced by pulses of respiration are due to the translocation of H(+) (or OH(-)) ions across the osmotic barrier (M phase) of the cristae membrane"
# R1: respiration pumps protons out (outer aqueous phase ~ suspension medium, mapped to GO extracellular region)
bp(GO:0022904!"respiratory electron transport chain") directlyIncreases tloc(a(CHEBI:15378!hydron), fromLoc(GO:0005759!"mitochondrial matrix"), toLoc(GO:0005576!"extracellular region"))

SET Evidence = "and cannot be attributed to the formation (with acid production) of a chemical intermediate that subsequently decomposes"
# R2: negative result against the chemical intermediate (best available: causesNoChange)
a(BIOLEAN:"C~I high-energy intermediate") causesNoChange a(CHEBI:15378!hydron, loc(GO:0005576!"extracellular region"))

SET Evidence = "The effective quantity of protons translocated per bivalent reducing equivalent passing through the succinate-oxidizing and beta-hydroxybutyrate-oxidizing spans of the respiratory chain are very close to 4 and 6 respectively."
SET Quantity = "H+/O = 4 (succinate span)"
a(CHEBI:26806!succinate) increases tloc(a(CHEBI:15378!hydron), fromLoc(GO:0005759!"mitochondrial matrix"), toLoc(GO:0005576!"extracellular region"))
SET Quantity = "H+/O = 6 (beta-hydroxybutyrate span)"
a(CHEBI:37054!"3-hydroxybutyrate") increases tloc(a(CHEBI:15378!hydron), fromLoc(GO:0005759!"mitochondrial matrix"), toLoc(GO:0005576!"extracellular region"))
UNSET Quantity

SET Evidence = "These quotients are constant between pH5.5 and 8.5 and are independent of changes in the ionic composition of the mitochondrial suspension medium"
SET Quantity = "pH 5.5-8.5"
# R3: negative result; H+/O ratio invariant to pH
a(CHEBI:15378!hydron, loc(GO:0005576!"extracellular region")) causesNoChange a(BIOLEAN:"H+/O quotient")
UNSET Quantity

SET Evidence = "Apparent changes in the H+/O quotients may also be induced by the presence of anions, such as succinate, malonate and phosphate, or by cations such as Na(+). These apparent changes of H+/O are due to an increase in the rate of the pH-driven decay of the acid pulses."
# Anions (malonate CHEBI:15792, phosphate) and Na+ (CHEBI:29101) cause *apparent* H+/O changes: an assay
# artefact, so no biological statement is made.

SET Evidence = "The uncoupling agents, 2,4-dinitrophenol, carbonyl cyanide p-trifluoromethoxyphenylhydrazone and gramicidin increase the effective proton conductance of the M phase ... but do not change the initial H+/O quotients"
# R4: uncouplers raise proton conductance (confirms Mitchell 1961 prediction P1).
# FCCP (CHEBI:75458) and gramicidin (CHEBI:749506) get the same two lines as DNP; omitted for space.
a(CHEBI:42017!"2,4-dinitrophenol") increases a(BIOLEAN:"membrane proton conductance")
# R5: ... but leave stoichiometry untouched (the decisive negative result)
a(CHEBI:42017!"2,4-dinitrophenol") causesNoChange a(BIOLEAN:"H+/O quotient")
a(BIOLEAN:"membrane proton conductance") decreases bp(GO:0006119!"oxidative phosphorylation")

SET Assertion = "AuthorConclusion"
SET Evidence = "the fact that the initial H+/O quotients are unchanged shows that uncoupler-sensitive chemical intermediates do not exist between the respiratory-chain system and the effective proton-translocating mechanism"
# Existence claim: BEL can only say C~I is not on the path
a(BIOLEAN:"C~I high-energy intermediate") causesNoChange bp(GO:0015990!"electron transport coupled proton transport")

SET Evidence = "Stoicheiometric acid-base changes associated with the activity of the regions of the respiratory chain on the oxygen side of the rotenone- and antimycin A-sensitive sites gives experimental support for a suggested configuration of loop 3."
SET Assertion = "Hypothesis"
# Loop 3 configuration: no BEL form. Rotenone (CHEBI:28201) and antimycin A (CHEBI:2762) mark sites on
# the chain here; they are landmarks, not tested effects, so no statement is made.
UNSET ALL
```

Could not express:
- H+/O = 4 and 6 as numbers. BEL has no numeric slot; I used `Quantity` free text. A ratio is also not an
  "abundance", so `a(BIOLEAN:"H+/O quotient")` is a hack.
- "Cannot be attributed to a chemical intermediate" and "do not exist". BEL has no negation or existence
  claims. `causesNoChange` on a hypothetical entity is the nearest, and reads oddly ("C~I has no effect").
- The *inference*: unchanged H+/O + raised conductance -> uncouplers act via conductance, not via C~I.
  BEL statements cannot have premises.
- Artefacts: "apparent" changes caused by anions/Na+ / backlash. BEL cannot say a measurement is an artefact.
  The anion/Na+ lines lose that they are about the *assay*, not the biology.
- Kinetics ("very fast electrically driven component of the decay").
- "Loop 3" configuration: a structural model, not expressible.
- Position on the chain ("oxygen side of the rotenone- and antimycin A-sensitive sites"). BEL has no way to
  name a segment of a pathway.

## 5. Hinkle & Horstman 1971, proton transport in submitochondrial particles (PMID 4330063)

```bel
SET Citation = {"PubMed", "J Biol Chem", "4330063"}
SET Provenance = "summary"
SET Species = "9913"
SET Anatomy = "UBERON:0000948"
SET CellStructure = "GO:0005743"
SET System = "in vitro"
SET EvidenceCode = "ECO:0000181"
SET Assertion = "ExperimentalResult"
SET Supports = "Mitchell 1961 H1 (PMID 13771349)"
SET Refutes = "Slater 1953 S1 (PMID 13111237)"

SET Evidence = "Submitochondrial particles from bovine heart, which are inside-out relative to intact mitochondria, take up protons during respiration (NADH or succinate oxidation), acidifying the vesicle interior"
# R1: inside-out membrane, so respiration moves protons INTO the particle (the opposite direction to
# intact mitochondria; this is the point of the experiment)
a(CHEBI:16908!NADH) increases tloc(a(CHEBI:15378!hydron), fromLoc(GO:0005576!"extracellular region"), toLoc(GO:0031983!"vesicle lumen"))
a(CHEBI:26806!succinate) increases tloc(a(CHEBI:15378!hydron), fromLoc(GO:0005576!"extracellular region"), toLoc(GO:0031983!"vesicle lumen"))
bp(GO:0022904!"respiratory electron transport chain") directlyIncreases a(CHEBI:15378!hydron, loc(GO:0031983!"vesicle lumen"))

SET Evidence = "the uptake is abolished by uncouplers"
# R2: uncoupler blocks it (the summary does not name the uncoupler)
a(?:unverified!"uncoupler (unnamed in summary)") decreases tloc(a(CHEBI:15378!hydron), fromLoc(GO:0005576!"extracellular region"), toLoc(GO:0031983!"vesicle lumen"))

SET Assertion = "AuthorConclusion"
SET Evidence = "this supports respiration-driven proton translocation as the energy-conserving step"
bp(GO:0015990!"electron transport coupled proton transport") increases bp(GO:0042776!"proton motive force-driven mitochondrial ATP synthesis")
UNSET ALL
```

Could not express:
- Membrane *sidedness* ("inside-out"). I had to fake it by swapping `fromLoc`/`toLoc` and using generic
  "vesicle lumen". The fact that the reversal is the evidence is lost.
- The uncoupler is not named in the summary; there is no verified CHEBI class for "uncoupler" role, so
  `?:unverified`.
- "Together with later work from the same lab": cross-paper evidence chaining. BEL citations are per statement
  and cannot cite a body of work.
- "Energy-conserving step" is a role, not a process; no GO term.

## 6. Racker & Stoeckenius 1974, bacteriorhodopsin + ATPase vesicles (PMID 4272126)

```bel
SET Citation = {"PubMed", "J Biol Chem", "4272126"}
SET Provenance = "summary"
# Two source organisms in one reconstituted system
SET Species = {"2242", "9913"}
SET System = "reconstituted"
SET EvidenceCode = "ECO:0000003"
SET Assertion = "ExperimentalResult"
SET Supports = "Mitchell 1961 H2 (PMID 13771349)"
SET Refutes = "Slater 1953 S1-S3 (PMID 13111237)"

SET Evidence = "Bacteriorhodopsin, the light-driven proton pump purified from Halobacterium halobium purple membrane, was reconstituted into phospholipid vesicles together with mitochondrial (bovine heart) F1F0 ATPase (oligomycin-sensitive ATPase). On illumination the vesicles took up protons and synthesised ATP from ADP and phosphate"
# R1: light-activated bacteriorhodopsin pumps protons into the vesicle
bp(GO:0071482!"cellular response to light stimulus") increases act(p(UP:P02945!Bacteriorhodopsin))
act(p(UP:P02945!Bacteriorhodopsin)) directlyIncreases tloc(a(CHEBI:15378!hydron), fromLoc(GO:0005576!"extracellular region"), toLoc(GO:0031983!"vesicle lumen"))
# R2: the two proteins share a membrane (a composite of two species' proteins)
composite(p(UP:P02945!Bacteriorhodopsin), complex(GO:0045259!"proton-transporting ATP synthase complex")) increases rxn(reactants(a(CHEBI:16761!ADP), a(CHEBI:26020!phosphate)), products(a(CHEBI:15422!ATP)))
# R3: the gradient is the link
tloc(a(CHEBI:15378!hydron), fromLoc(GO:0005576!"extracellular region"), toLoc(GO:0031983!"vesicle lumen")) increases act(complex(GO:0045259!"proton-transporting ATP synthase complex"))

SET Evidence = "ATP synthesis was abolished by uncouplers and by oligomycin"
a(CHEBI:25675!oligomycin) decreases act(complex(GO:0045259!"proton-transporting ATP synthase complex"))
a(?:unverified!"uncoupler (unnamed in summary)") decreases a(BIOLEAN:"electrochemical proton gradient")
a(BIOLEAN:"electrochemical proton gradient") increases bp(GO:0015986!"proton motive force-driven ATP synthesis")

SET Assertion = "AuthorConclusion"
SET Evidence = "Since the two proteins come from unrelated organisms and share no chemical intermediate, a proton gradient is sufficient to drive ATP synthesis."
a(BIOLEAN:"C~I high-energy intermediate") causesNoChange bp(GO:0015986!"proton motive force-driven ATP synthesis")
UNSET ALL
```

Could not express:
- Bovine F1F0 subunits: I used the GO complex term (GO:0045259), not a `complex(p(...), p(...))` of bovine
  UniProt chains. That is the usual BEL move but loses which organism the complex came from. The
  bovine-specific GO term (GO:0005753) is obsolete.
- Which protein comes from which species. `Species` is per statement, so `{"2242","9913"}` says "one of these",
  not "bR from archaea, ATPase from cow". (UniProt P02945 is from strain NRC-1, NCBITaxon:64091; I used the
  species ID 2242 for the annotation.)
- The logic of the conclusion: "unrelated organisms, so no shared intermediate, so the gradient is sufficient".
  This is an argument by elimination, and it is the whole point of the paper. BEL has no place for it.
- "Light" as an input: no clean BEL term for a physical stimulus. I used a GO response process.
- Phospholipid vesicle / liposome as the setting: no GO term found for liposome; "vesicle lumen" is the
  closest.

## 7. Yoshino 2011, NMN in diet- and age-induced diabetic mice (PMID 21982712)

```bel
SET Citation = {"PubMed", "Cell Metab", "21982712"}
SET Provenance = "abstract"
SET Species = "10090"
SET System = "in vivo"
SET EvidenceCode = "ECO:0000178"
SET Assertion = "ExperimentalResult"
SET Disease = "MONDO:0005148"
SET Diet = "high-fat diet (EFO:0002757)"
SET Dose = "not stated in abstract"

SET Evidence = "NAMPT-mediated NAD(+) biosynthesis is severely compromised in metabolic organs by high-fat diet (HFD)"
# R1: HFD lowers NAMPT-driven NAD+ synthesis (diet has no BEL term; it is context, so it cannot be a subject)
act(p(MGI:1929865!Nampt), ma(GO:0047280!"nicotinamide phosphoribosyltransferase activity")) rateLimitingStepOf bp(GO:0009435!"NAD+ biosynthetic process")
path(MONDO:0005148!"type 2 diabetes mellitus") negativeCorrelation bp(GO:0009435!"NAD+ biosynthetic process")

SET Evidence = "NMN ... ameliorates glucose intolerance by restoring NAD(+) levels in HFD-induced T2D mice"
a(CHEBI:50383!"nicotinamide mononucleotide") increases a(CHEBI:15846!"NAD(+)")
a(CHEBI:15846!"NAD(+)") decreases path(MP:0005293!"impaired glucose tolerance")
a(CHEBI:50383!"nicotinamide mononucleotide") decreases path(MP:0005293!"impaired glucose tolerance")

SET Anatomy = "UBERON:0002107"
SET Evidence = "NMN also enhances hepatic insulin sensitivity and restores gene expression related to oxidative stress, inflammatory response, and circadian rhythm, partly through SIRT1 activation"
a(CHEBI:50383!"nicotinamide mononucleotide") decreases path(MP:0005331!"insulin resistance")
a(CHEBI:50383!"nicotinamide mononucleotide") increases act(p(MGI:2135607!Sirt1), ma(GO:0034979!"NAD-dependent protein lysine deacetylase activity"))
act(p(MGI:2135607!Sirt1)) association bp(GO:0006979!"response to oxidative stress")
act(p(MGI:2135607!Sirt1)) association bp(GO:0006954!"inflammatory response")
act(p(MGI:2135607!Sirt1)) association bp(GO:0007623!"circadian rhythm")
UNSET Anatomy

SET Disease = "MONDO:0005148"
SET Diet = "regular chow"
SET Age = "aged (age not stated in abstract)"
SET Evidence = "NAD(+) and NAMPT levels show significant decreases in multiple organs during aging, and NMN improves glucose intolerance and lipid profiles in age-induced T2D mice"
# 'aging' itself: GO:0007568 is obsolete; EFO:0022597 'aging' used only as an annotation value
p(MGI:1929865!Nampt) negativeCorrelation a(?:unverified!"age")
a(CHEBI:50383!"nicotinamide mononucleotide") decreases path(MP:0005293!"impaired glucose tolerance")
a(CHEBI:50383!"nicotinamide mononucleotide") decreases path(MP:0003949!"abnormal circulating lipid level")
UNSET ALL
```

Could not express:
- "HFD *lowers* NAD+ synthesis": diet is an exposure, not an abundance. BEL wants a subject term; I could only
  put the diet in a custom annotation, so the causal claim "HFD decreases NAD+" has no statement.
- "Restores" (back to control level): BEL only has direction, not "back to baseline".
- "Partly through SIRT1": partial mediation. BEL has no "mediated by" or fraction. The SIRT1 links to gene
  programs are only `association`.
- Gene-expression *sets* ("genes related to oxidative stress"): BEL cannot name a gene set without listing
  genes.
- Two disease models (diet-induced vs age-induced T2D) are both just MONDO:0005148; the model distinction
  lives in free text `Diet`/`Age`.
- Ageing as a cause: no live GO term, and age is not an abundance. `a(?:unverified!"age")` is a hack.
- Dose, route, duration, sex, strain: not in the abstract, so empty; BEL has no standard slot anyway.
- Lipid "profiles" (which lipids, which way).

## 8. Gomes 2013, declining NAD+ and pseudohypoxia in ageing (PMID 24360282)

```bel
SET Citation = {"PubMed", "Cell", "24360282"}
SET Provenance = "abstract"
SET Species = "10090"
SET System = "in vivo"
SET EvidenceCode = "ECO:0000178"
SET Assertion = "ExperimentalResult"
SET Age = "old vs young (ages not stated in abstract)"

SET Evidence = "during aging, there is a specific loss of mitochondrial, but not nuclear, encoded OXPHOS subunits"
# R1: mitochondrially encoded subunits fall; nuclear ones do not (negative result)
a(?:unverified!"age") decreases bp(GO:0140053!"mitochondrial gene expression")
a(?:unverified!"age") causesNoChange a(?:unverified!"nuclear-encoded OXPHOS subunits")

SET Evidence = "an alternate PGC-1alpha/beta-independent pathway of nuclear-mitochondrial communication that is induced by a decline in nuclear NAD(+) and the accumulation of HIF-1alpha under normoxic conditions"
# R2: low nuclear NAD+ -> less SIRT1 -> HIF-1a builds up -> mito-encoded OXPHOS down
a(CHEBI:15846!"NAD(+)", loc(GO:0005634!nucleus)) increases act(p(MGI:2135607!Sirt1), ma(GO:0034979!"NAD-dependent protein lysine deacetylase activity"))
act(p(MGI:2135607!Sirt1)) decreases p(MGI:106918!Hif1a)
p(MGI:106918!Hif1a) decreases bp(GO:0140053!"mitochondrial gene expression")
# R3: PGC-1a/b-independence (negative result about a mediator)
p(MGI:1342774!Ppargc1a) causesNoChange bp(GO:0140053!"mitochondrial gene expression")
p(MGI:2444934!Ppargc1b) causesNoChange bp(GO:0140053!"mitochondrial gene expression")

SET Evidence = "Deleting SIRT1 accelerates this process"
SET Strain = "Sirt1 knockout (tissue not stated in abstract)"
SET EvidenceCode = "ECO:0001091"
p(MGI:2135607!Sirt1) decreases path(MP:0006036!"abnormal mitochondrial physiology")
UNSET Strain

SET Evidence = "raising NAD(+) levels in old mice restores mitochondrial function to that of a young mouse in a SIRT1-dependent manner"
SET EvidenceCode = "ECO:0000178"
SET Dose = "NAD+ raised via NMN; dose not stated in abstract"
a(CHEBI:15846!"NAD(+)") decreases path(MP:0006036!"abnormal mitochondrial physiology")
a(CHEBI:15846!"NAD(+)") increases act(p(MGI:2135607!Sirt1))
act(p(MGI:2135607!Sirt1)) increases bp(GO:0006119!"oxidative phosphorylation")

SET Assertion = "AuthorConclusion"
SET Evidence = "a pseudohypoxic state that disrupts PGC-1alpha/beta-independent nuclear-mitochondrial communication contributes to the decline in mitochondrial function with age, a process that is apparently reversible"
path(BIOLEAN:"pseudohypoxic state") decreases bp(BIOLEAN:"nuclear-mitochondrial communication (PGC-1-independent)")
bp(BIOLEAN:"nuclear-mitochondrial communication (PGC-1-independent)") increases bp(GO:0006119!"oxidative phosphorylation")
UNSET ALL
```

Could not express:
- "Under normoxic conditions": oxygen level as a condition. I would need another custom annotation.
- "SIRT1-dependent": a *requirement* (the NAD+ effect is lost without SIRT1). BEL has no "requires"; the
  usual trick is two statements, and the dependency between them is lost.
- "Restores to that of a young mouse": comparison to a different group (young controls), not just direction.
- `p(Sirt1) decreases path(...)` reads as "more Sirt1, less pathology", which is the right direction but it
  hides that the evidence is a *deletion*. Knock-out vs over-expression is not part of the statement.
- "Nuclear-encoded OXPHOS subunits": a gene set, no ID.
- "Parallels to Warburg reprogramming": analogy, not expressible.
- How NAD+ was raised (NMN) is not in the abstract; recorded only as a note.

## 9. Mills 2016, 12-month NMN in normally ageing mice (PMID 28068222)

```bel
SET Citation = {"PubMed", "Cell Metab", "28068222"}
SET Provenance = "abstract"
SET Species = "10090"
SET Strain = "C57BL/6N wild type (EFO has only C57BL/6NJ, EFO:0007732; not the same substrain)"
SET Diet = "regular chow"
SET System = "in vivo"
SET Duration = "12 months"
SET Dose = "oral; amount not stated in abstract"
SET EvidenceCode = "ECO:0000178"
SET Assertion = "ExperimentalResult"
SET Age = "during normal aging (start age not stated in abstract)"

SET Evidence = "Orally administered NMN was quickly utilized to synthesize NAD+ in tissues."
a(CHEBI:50383!"nicotinamide mononucleotide") increases a(CHEBI:15846!"NAD(+)")
a(CHEBI:50383!"nicotinamide mononucleotide") increases bp(GO:0009435!"NAD+ biosynthetic process")

SET Evidence = "Without any obvious toxicity or deleterious effects, NMN suppressed age-associated body weight gain, enhanced energy metabolism, promoted physical activity, improved insulin sensitivity and plasma lipid profile, and ameliorated eye function and other pathophysiologies."
a(CHEBI:50383!"nicotinamide mononucleotide") decreases path(MP:0001260!"increased body weight")
a(CHEBI:50383!"nicotinamide mononucleotide") increases path(MP:0004889!"increased energy expenditure")
a(CHEBI:50383!"nicotinamide mononucleotide") increases bp(GO:0007626!"locomotory behavior")
a(CHEBI:50383!"nicotinamide mononucleotide") increases path(MP:0002891!"increased insulin sensitivity")
a(CHEBI:50383!"nicotinamide mononucleotide") decreases path(MP:0003949!"abnormal circulating lipid level")
a(CHEBI:50383!"nicotinamide mononucleotide") decreases path(MP:0005253!"abnormal eye physiology")
# Safety: a negative result about harms
a(CHEBI:50383!"nicotinamide mononucleotide") causesNoChange path(?:unverified!"toxicity")

SET Anatomy = "UBERON:0001134"
SET Evidence = "NMN prevented age-associated gene expression changes in key metabolic organs and enhanced mitochondrial oxidative metabolism and mitonuclear protein imbalance in skeletal muscle"
a(CHEBI:50383!"nicotinamide mononucleotide") increases bp(GO:0006119!"oxidative phosphorylation")
a(CHEBI:50383!"nicotinamide mononucleotide") increases bp(GO:0140053!"mitochondrial gene expression")
UNSET Anatomy

SET Assertion = "AuthorConclusion"
SET Species = "9606"
SET Evidence = "These effects of NMN highlight the preventive and therapeutic potential of NAD+ intermediates as effective anti-aging interventions in humans."
# Cross-species extrapolation: BEL can only re-state it under a human Species tag
a(CHEBI:50383!"nicotinamide mononucleotide") decreases path(?:unverified!"age-associated physiological decline")
UNSET ALL
```

Could not express:
- "Suppressed age-associated *gain*": a change in a trajectory over time vs controls. BEL has direction only,
  so I flipped to "decreases increased body weight", which is clumsy (double negative).
- Phenotype terms are mostly "abnormal X" or "increased X". Putting them in `path()` and then using
  `increases`/`decreases` gives double polarity ("increases increased insulin sensitivity").
- "Without any obvious toxicity": a broad negative across all endpoints. `causesNoChange` on an unverified
  catch-all is a weak stand-in.
- Strain substrain: C57BL/6N has no ontology ID I could verify; free text.
- The human claim is a *speculation drawn from mouse data*. Tagging it `Species = 9606` makes it look like a
  human finding; only my custom `Assertion` hints otherwise.
- Dose arms, sex, start age: not in the abstract.
- "Mitonuclear protein imbalance" is ambiguous in the abstract (enhanced? reduced?); I left it out.

## 10. Das 2018, endothelial NAD+-H2S signalling and vascular ageing (PMID 29570999)

```bel
SET Citation = {"PubMed", "Cell", "29570999"}
SET Provenance = "abstract"
SET Species = "10090"
SET System = "in vivo"
SET EvidenceCode = "ECO:0000178"
SET Assertion = "ExperimentalResult"
SET Age = "elderly (age not stated in abstract)"
SET Dose = "not stated in abstract"

SET Cell = "CL:0000115"
SET Evidence = "SIRT1 in endothelial cells is a key mediator of pro-angiogenic signals secreted from myocytes"
act(p(MGI:2135607!Sirt1)) increases bp(GO:0001525!angiogenesis)
UNSET Cell

SET Anatomy = "UBERON:0001134"
SET Evidence = "Treatment of mice with the NAD+ booster nicotinamide mononucleotide (NMN) improves blood flow and increases endurance in elderly mice by promoting SIRT1-dependent increases in capillary density"
a(CHEBI:50383!"nicotinamide mononucleotide") increases a(CHEBI:15846!"NAD(+)")
a(CHEBI:50383!"nicotinamide mononucleotide") increases act(p(MGI:2135607!Sirt1))
act(p(MGI:2135607!Sirt1)) increases path(MP:0020330!"increased capillary density")
a(CHEBI:50383!"nicotinamide mononucleotide") increases path(MP:0020330!"increased capillary density")
a(CHEBI:50383!"nicotinamide mononucleotide") increases bp(GO:0008015!"blood circulation")
a(CHEBI:50383!"nicotinamide mononucleotide") increases path(MP:0012107!"enhanced exercise endurance")
path(MP:0020330!"increased capillary density") increases path(MP:0012107!"enhanced exercise endurance")

SET Evidence = "an effect augmented by exercise or increasing the levels of hydrogen sulfide (H2S), a DR mimetic and regulator of endothelial NAD+ levels"
a(CHEBI:16136!"hydrogen sulfide") increases a(CHEBI:15846!"NAD(+)", loc(?:unverified!"endothelial cell"))
# Synergy: BEL has no interaction term; the nearest is a composite
composite(a(CHEBI:50383!"nicotinamide mononucleotide"), a(CHEBI:16136!"hydrogen sulfide")) increases path(MP:0020330!"increased capillary density")
composite(a(CHEBI:50383!"nicotinamide mononucleotide"), bp(GO:0014850!"response to muscle activity")) increases path(MP:0020330!"increased capillary density")
UNSET ALL

SET Citation = {"PubMed", "Cell", "29570999"}
SET Assertion = "AuthorConclusion"
SET Species = "9606"
SET Evidence = "These findings have implications for improving blood flow to organs and tissues, increasing human performance, and reestablishing a virtuous cycle of mobility in the elderly."
a(CHEBI:50383!"nicotinamide mononucleotide") increases bp(GO:0008015!"blood circulation")
UNSET ALL
```

Could not express:
- "Augmented by exercise": an interaction / synergy. `composite()` means "these together", but BEL cannot say
  "more than either alone". Also `composite()` is formally for abundances; putting a `bp()` (exercise) inside
  stretches the spec.
- "Exercise" is an intervention; there is no good GO or CHEBI term. I used "response to muscle activity".
- "DR mimetic": a role / analogy to dietary restriction. Not expressible.
- "Pro-angiogenic signals secreted from myocytes": the signal molecules are not named in the abstract, so no
  `sec()` statement can be written. Cell-to-cell signalling across two cell types needs two `Cell`
  contexts in one statement, which BEL does not allow.
- `loc()` takes a cellular component, not a cell type, so "NAD+ in endothelial cells" cannot be written with
  CL:0000115 as a location (`?:unverified`).
- "SIRT1-dependent" again (requirement), and "virtuous cycle" (feedback loop as a concept).
- The human line is extrapolation, flagged only by the custom `Assertion`.

## 11. Yoshino 2021, NMN RCT in prediabetic women (PMID 33888596)

```bel
SET Citation = {"PubMed", "Science", "33888596"}
SET Provenance = "abstract"
SET Species = "9606"
SET Sex = "female"
SET Age = "postmenopausal (EFO:0002721)"
SET Disease = {"MONDO:0006920", "HP:0025502", "HP:0001513"}
SET System = "clinical RCT"
SET Duration = "10 weeks"
SET Dose = "oral NMN; amount not stated in abstract"
SET EvidenceCode = "ECO:0000180"
SET Assertion = "ExperimentalResult"
SET Anatomy = "UBERON:0001134"

SET Evidence = "Insulin-stimulated glucose disposal, assessed by using the hyperinsulinemic-euglycemic clamp, and skeletal muscle insulin signaling [phosphorylation of protein kinase AKT and mechanistic target of rapamycin (mTOR)] increased after NMN supplementation"
a(CHEBI:50383!"nicotinamide mononucleotide") increases bp(GO:0032869!"cellular response to insulin stimulus")
a(CHEBI:50383!"nicotinamide mononucleotide") increases bp(GO:0008286!"insulin receptor signaling pathway")
a(CHEBI:50383!"nicotinamide mononucleotide") increases p(HGNC:391!AKT1, pmod(Ph))
a(CHEBI:50383!"nicotinamide mononucleotide") increases p(HGNC:3942!MTOR, pmod(Ph))

SET Evidence = "but did not change after placebo treatment"
# The control arm, as a negative result (placebo has no CHEBI ID)
a(?:unverified!"placebo") causesNoChange bp(GO:0032869!"cellular response to insulin stimulus")
a(?:unverified!"placebo") causesNoChange p(HGNC:391!AKT1, pmod(Ph))

SET Evidence = "NMN supplementation up-regulated the expression of platelet-derived growth factor receptor beta and other genes related to muscle remodeling"
a(CHEBI:50383!"nicotinamide mononucleotide") increases r(HGNC:8804!PDGFRB)
a(CHEBI:50383!"nicotinamide mononucleotide") increases bp(?:unverified!"skeletal muscle tissue remodeling")

SET Assertion = "AuthorConclusion"
SET Evidence = "These results demonstrate that NMN increases muscle insulin sensitivity, insulin signaling, and remodeling in women with prediabetes who are overweight or obese (clinicaltrial.gov NCT03151239)."
a(CHEBI:50383!"nicotinamide mononucleotide") decreases path(HP:0000855!"Insulin resistance")
UNSET ALL
```

Could not express:
- The trial design: randomized, placebo-controlled, double-blind, n per arm. ECO:0000180 is just "clinical
  study evidence"; no verified ECO term for RCT. NCT ID only in free text.
- "Increased after NMN but not after placebo" is a *between-group* contrast. BEL writes two separate
  statements and loses that the conclusion rests on the difference.
- Effect size, CI, p-value: no numeric slot.
- `Disease` holds three values that are really one cohort definition (prediabetic AND overweight-or-obese).
  BEL annotation sets mean "any of", not "all of".
- Phospho-sites: abstract gives none, so `pmod(Ph)` without residue. AKT1 is a guess at which AKT isoform.
- "Muscle remodeling": no GO term found (`?:unverified`).
- The NMN -> NAD+ step is assumed by the paper but not stated as measured in the abstract; I did not assert
  it.

## Fit table

| Aspect | Expressible? | How |
|---|---|---|
| Direction of effect | yes | Core of BEL: `increases` / `decreases` / `directlyIncreases` / `causesNoChange`. Clumsy with "abnormal X" / "increased X" phenotype terms (double polarity). |
| Quantitative result | no | No numeric slot. H+/O = 4 and 6, pH 4 -> 8, effect sizes, p-values only in free-text `Evidence` or a custom `Quantity` annotation. |
| Species / strain | partial | `SET Species` (NCBITaxon) is standard. Strain needs a custom annotation; one `Species` value per statement, so mixed-species systems (Racker) are ambiguous. |
| Age / stage | partial | Custom `Age` annotation only. Ageing as a *cause* has no term (GO "aging" is obsolete), and age is not an abundance. |
| Tissue / cell | yes | `SET Anatomy` (UBERON), `SET Cell` (CL), `loc()` for cellular components. Cannot have two cell types in one statement (myocyte -> endothelial signalling). |
| Disease model | partial | `SET Disease` (MONDO) names the disease, not the *model* (HFD vs ageing vs knockout). Multi-value sets mean OR, not AND. |
| Dose / duration | partial | Custom annotations (`Dose`, `Duration`), free text, not computable. |
| Hypothesis vs result | partial | No native support. A custom `Assertion` annotation tags it, but every BEL tool treats all statements as asserted fact. |
| Rival hypotheses | no | Two rival paths to the same `bp()` just coexist in one graph. No "contradicts", "alternative to", or mutual exclusion. |
| Evidence type | partial | ECO code via an annotation works, plus `Evidence` text. But ECO has no RCT term, and the logic of a decisive experiment (elimination) has no slot. |
| Cross-species transfer | no | Only by repeating a statement under a different `Species`, which makes an extrapolation look like a finding. No orthology link between `MGI:` and `HGNC:` terms in the statement itself. |
| Negative results | partial | `causesNoChange` covers "X does not change Y" (uncouplers vs H+/O, placebo, PGC-1). It cannot say "X does not exist" or "Y is not required". |

## Verdict

(a) For the chemiosmotic papers BEL is a poor fit: it can draw the arrows (respiration -> proton
translocation -> ATP synthase -> ATP), but the papers are about *which arrows exist*, and BEL has no way to
say that Slater's path and Mitchell's path are rivals, that an experiment refutes one, or that a gradient is
*sufficient*. The central objects are awkward too: a proton *gradient* is a difference between two
compartments, while BEL can only place an abundance in one compartment, and C~I (a hypothetical molecule)
looks exactly like a real one. The decisive numbers (H+/O = 4 and 6, pH 4 -> 8) and the elimination logic of
Racker's mixed-species vesicles end up in free text. `causesNoChange` handles some negative results well (the
uncouplers leave H+/O unchanged), which is the one bright spot. Everything that made these papers matter
lives in my custom annotations, which no BEL tool understands.

(b) For the NMN mouse papers BEL fits better, because they are mostly "intervention X changes readout Y in
tissue Z of species S", which is exactly the shape BEL was built for (it came out of pharma knowledge
curation). Species, tissue, cell and a disease label sit cleanly in standard `SET` annotations, and the
NMN -> NAD+ -> SIRT1 chains map well to `a()` / `act(p())`. It gets awkward fast on the things that matter
for judging these papers: dose, duration, age, strain, sex and diet are all free text; "SIRT1-dependent",
"partly through", and "augmented by exercise" (requirement, partial mediation, synergy) have no relation; and
phenotype terms in `path()` give clumsy double polarity. The worst gap is cross-species transfer: the
mouse-to-human claims (Mills, Das) and the human RCT (Yoshino 2021) can only be told apart by a `Species`
tag and a custom flag, so a BEL graph will happily merge a mouse speculation with a human result.
