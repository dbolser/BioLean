# Nanopublications (TriG) + SEPIO evidence lines

## 1. The formalism

A nanopublication is the smallest publishable, citable, signed unit of a scientific claim: one RDF dataset
in TriG with four named graphs. **Head** says which graph is which. **Assertion** holds the claim itself, as
RDF triples (here RO / GO / CHEBI class-level triples for mechanism, and Biolink-style association nodes
with qualifiers when context is part of what the claim means). **Provenance** says where the assertion
came from: PROV-O (`prov:wasDerivedFrom` the paper) plus a SEPIO layer that types the assertion
(`SEPIO:0000001` assertion, `SEPIO:0000432` hypothesis, `SEPIO:0000173` study finding) and hangs
**evidence lines** (`SEPIO:0000002`) off it, each with a direction (`SEPIO:0000403` supporting /
`SEPIO:0000404` disputing), evidence items and an ECO code. **Pubinfo** is about the nanopub itself (who
made it, when, licence, and the nanopub-native lifecycle links `npx:supersedes` / `npx:retracts`). So the
**unit of annotation is one nanopub = one assertion graph**. Context lives in three places, and choosing
which is the main design problem: inside the assertion (if it changes the truth of the claim: species,
disease model, direction), in provenance (how it was found: in vivo vs in vitro, assay, ECO, dose,
study design), or in pubinfo (who curated it). The controversy is built the nanopub way: nanopubs are
immutable, so one cannot edit Slater's nanopub to say it lost. Instead a *new* curation nanopub whose
**assertion** is about other nanopubs' assertion graphs ("this graph has a disputing evidence line whose
item is that graph") does the work. `npx:supersedes` is only for the same author replacing their own
nanopub; disagreement between authors is always a fresh assertion (SEPIO / CiTO / SIO).

### Conventions used below

- All blocks share this prefix set (stated once to save space; a real nanopub file repeats it).
- Nanopub IRIs are `https://w3id.org/biolean/np/RA<hash>`. The `RA…` part stands in for a Trusty URI hash;
  hashes and signatures (`npx:hasSignature…`) are elided, so these are unsigned drafts.
- `bl:` = local BioLean terms, used only where no ontology term exists (e.g. Slater's C~I, which by
  construction never had a CHEBI ID because it was never found).
- `?:unverified` is written literally where an ID could not be checked in OLS4, as the brief asks. It is
  not valid TriG; a real file would need a resolvable IRI there.
- Every OBO/SEPIO/ECO/SIO/Biolink ID below was looked up in the OLS4 API (2026-10-26). UniProt IDs were
  checked against rest.uniprot.org. np/npx/PROV/DCT/CiTO are W3C/SPAR/nanopub schema vocabularies, not in
  OLS; they are used as documented by their owners.
- Papers with `abstract_is_summary = true` get `bl:sourceKind bl:SecondarySummary` in provenance, and the
  ECO code is wrapped in `ECO:0000204` (author statement) logic: we did not read the result, we read
  someone's summary of it.

```trig
@prefix np:        <http://www.nanopub.org/nschema#> .
@prefix npx:       <http://purl.org/nanopub/x/> .
@prefix prov:      <http://www.w3.org/ns/prov#> .
@prefix dct:       <http://purl.org/dc/terms/> .
@prefix xsd:       <http://www.w3.org/2001/XMLSchema#> .
@prefix rdf:       <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix rdfs:      <http://www.w3.org/2000/01/rdf-schema#> .
@prefix cito:      <http://purl.org/spar/cito/> .
@prefix biolink:   <https://w3id.org/biolink/vocab/> .
@prefix SEPIO:     <http://purl.obolibrary.org/obo/SEPIO_> .
@prefix ECO:       <http://purl.obolibrary.org/obo/ECO_> .
@prefix GO:        <http://purl.obolibrary.org/obo/GO_> .
@prefix CHEBI:     <http://purl.obolibrary.org/obo/CHEBI_> .
@prefix RO:        <http://purl.obolibrary.org/obo/RO_> .
@prefix BFO:       <http://purl.obolibrary.org/obo/BFO_> .
@prefix NCBITaxon: <http://purl.obolibrary.org/obo/NCBITaxon_> .
@prefix UBERON:    <http://purl.obolibrary.org/obo/UBERON_> .
@prefix CL:        <http://purl.obolibrary.org/obo/CL_> .
@prefix HP:        <http://purl.obolibrary.org/obo/HP_> .
@prefix MP:        <http://purl.obolibrary.org/obo/MP_> .
@prefix MONDO:     <http://purl.obolibrary.org/obo/MONDO_> .
@prefix PATO:      <http://purl.obolibrary.org/obo/PATO_> .
@prefix OBI:       <http://purl.obolibrary.org/obo/OBI_> .
@prefix NCIT:      <http://purl.obolibrary.org/obo/NCIT_> .
@prefix EFO:       <http://www.ebi.ac.uk/efo/EFO_> .
@prefix SIO:       <http://semanticscience.org/resource/SIO_> .
@prefix UniProtKB: <http://purl.uniprot.org/uniprot/> .
@prefix pubmed:    <http://identifiers.org/pubmed/> .
@prefix bl:        <https://w3id.org/biolean/vocab/> .
@prefix bnp:       <https://w3id.org/biolean/np/> .
```

## 2. Per paper

### Slater 1953, Nature. PMID 13111237 (summary only)

Two nanopubs: the rival hypothesis itself, and its key structural commitment (a phosphate-free
high-energy intermediate). Typed as hypothesis, not result.

```trig
@prefix s53a: <https://w3id.org/biolean/np/RAslater1953a#> .
@prefix s53b: <https://w3id.org/biolean/np/RAslater1953b#> .

# --- nanopub 1: the chemical-coupling hypothesis -------------------------------------------
s53a:Head {
  bnp:RAslater1953a a np:Nanopublication ;
      np:hasAssertion s53a:assertion ; np:hasProvenance s53a:provenance ;
      np:hasPublicationInfo s53a:pubinfo .
}
s53a:assertion {
  # Electron transport is coupled to ATP synthesis THROUGH a chemical intermediate.
  bl:ChemicalHighEnergyIntermediate a rdfs:Class ;
      rdfs:label "C~I, non-phosphorylated high-energy intermediate (Slater)" .
  GO:0022900 RO:0002234 bl:ChemicalHighEnergyIntermediate .      # electron transport chain  has output  C~I
  GO:0006754 RO:0002233 bl:ChemicalHighEnergyIntermediate .      # ATP biosynthetic process  has input   C~I
  GO:0006754 RO:0002233 CHEBI:16761 , CHEBI:43474 .              #   ... has input ADP, hydrogenphosphate
  GO:0006754 RO:0002234 CHEBI:15422 .                            #   ... has output ATP
  GO:0006754 BFO:0000066 GO:0005743 .                            # occurs in mitochondrial inner membrane
}
s53a:provenance {
  s53a:assertion a SEPIO:0000432 , SIO:000284 ;                  # hypothesis (SEPIO) / hypothesis (SIO)
      prov:wasDerivedFrom pubmed:13111237 ;
      prov:wasAttributedTo bl:EC_Slater ;
      bl:sourceKind bl:SecondarySummary ;
      bl:argumentBy bl:AnalogyToSubstrateLevelPhosphorylation ;   # by analogy with glycolysis
      SEPIO:0000006 s53a:el1 .                                    # has_evidence_line
  s53a:el1 a SEPIO:0000002 ;                                      # evidence line
      SEPIO:0000183 SEPIO:0000403 ;                               # direction: supporting
      dct:type ECO:0000001 ;                                      # inference from background scientific knowledge
      SEPIO:0000084 GO:0006096 .                                  # evidence item: glycolytic process (the analogue)
}
s53a:pubinfo {
  bnp:RAslater1953a dct:created "2026-10-26T00:00:00Z"^^xsd:dateTime ;
      dct:creator bl:BioLeanCurator ;
      dct:license <https://creativecommons.org/licenses/by/4.0/> ;
      npx:hasNanopubType SEPIO:0000432 .
}

# --- nanopub 2: prediction that follows from it (falsifiable) ------------------------------
s53b:Head {
  bnp:RAslater1953b a np:Nanopublication ;
      np:hasAssertion s53b:assertion ; np:hasProvenance s53b:provenance ;
      np:hasPublicationInfo s53b:pubinfo .
}
s53b:assertion {
  # Prediction: uncouplers act by hydrolysing C~I, i.e. on a chemical, not on the membrane.
  CHEBI:42017 RO:0002212 bl:ChemicalHighEnergyIntermediate .     # 2,4-dinitrophenol negatively regulates C~I
}
s53b:provenance {
  s53b:assertion a SEPIO:0000432 ;
      bl:statementKind bl:Prediction ;
      prov:wasDerivedFrom bnp:RAslater1953a , pubmed:13111237 ;
      bl:sourceKind bl:SecondarySummary .
}
s53b:pubinfo {
  bnp:RAslater1953b dct:created "2026-10-26T00:00:00Z"^^xsd:dateTime ; dct:creator bl:BioLeanCurator .
}
```

Could not express:
- "C~I" has no identifier anywhere, because it was never isolated. A local `bl:` class is the only option,
  and it hides the key fact that the entity is hypothetical (OWL has no "putative class").
- The uncoupler prediction is really "Slater's camp later said…", not in the 1953 summary. I flagged it
  as a prediction but nanopubs cannot grade "implied by" vs "stated in".
- `RO:0002212` (negatively regulates) is process-to-process; a chemical destroying a chemical is a misuse.
  No RO predicate for "hydrolyses".
- "By analogy" as an argument type: no ECO or SEPIO term. Local `bl:` term.

### Mitchell 1961, Nature. PMID 13771349 (summary only)

Four nanopubs: the core hypothesis split into its two causal links, the membrane-location claim, and the
two predictions (impermeable membrane; uncouplers = proton conductors). Splitting matters: later papers
support different links.

```trig
@prefix m61a: <https://w3id.org/biolean/np/RAmitchell1961a#> .
@prefix m61b: <https://w3id.org/biolean/np/RAmitchell1961b#> .
@prefix m61c: <https://w3id.org/biolean/np/RAmitchell1961c#> .
@prefix m61d: <https://w3id.org/biolean/np/RAmitchell1961d#> .

# --- nanopub a: link 1, electron transport drives proton translocation -----------------------
m61a:Head { bnp:RAmitchell1961a a np:Nanopublication ; np:hasAssertion m61a:assertion ;
            np:hasProvenance m61a:provenance ; np:hasPublicationInfo m61a:pubinfo . }
m61a:assertion {
  GO:0022900 RO:0002304 GO:1902600 .     # electron transport chain  causally upstream of, positive effect  proton transmembrane transport
  GO:1902600 BFO:0000066 GO:0005743 .    # occurs in mitochondrial inner membrane
  GO:1902600 BFO:0000066 GO:0009535 .    # ... and in chloroplast thylakoid membrane (photosynthetic case)
}
m61a:provenance {
  m61a:assertion a SEPIO:0000432 , SIO:000284 ;
      prov:wasDerivedFrom pubmed:13771349 ; prov:wasAttributedTo bl:P_Mitchell ;
      bl:sourceKind bl:SecondarySummary ;
      SEPIO:0000006 [ a SEPIO:0000002 ; SEPIO:0000183 SEPIO:0000403 ; dct:type ECO:0000001 ] .
}
m61a:pubinfo { bnp:RAmitchell1961a dct:created "2026-10-26T00:00:00Z"^^xsd:dateTime ;
               dct:creator bl:BioLeanCurator ; npx:hasNanopubType SEPIO:0000432 . }

# --- nanopub b: link 2, the proton gradient drives ATP synthesis (no chemical intermediate) ---
m61b:Head { bnp:RAmitchell1961b a np:Nanopublication ; np:hasAssertion m61b:assertion ;
            np:hasProvenance m61b:provenance ; np:hasPublicationInfo m61b:pubinfo . }
m61b:assertion {
  GO:1902600 RO:0002304 GO:0015986 .     # proton transmembrane transport -> proton motive force-driven ATP synthesis
  GO:0015986 RO:0002233 CHEBI:16761 , CHEBI:43474 ; RO:0002234 CHEBI:15422 .   # ADP + Pi -> ATP
  GO:0045259 RO:0002215 GO:0015986 .     # proton-transporting ATP synthase complex  capable of  pmf-driven ATP synthesis
  GO:0006119 BFO:0000051 GO:1902600 , GO:0015986 .   # oxidative phosphorylation has part both steps
  GO:0009777 BFO:0000051 GO:1902600 , GO:0015986 .   # photosynthetic phosphorylation, same
}
m61b:provenance {
  m61b:assertion a SEPIO:0000432 ;
      prov:wasDerivedFrom pubmed:13771349 ; prov:wasAttributedTo bl:P_Mitchell ;
      bl:sourceKind bl:SecondarySummary ;
      bl:rivalOf bnp:RAslater1953a .     # see "Controversy layer" below for the SEPIO form of this
}
m61b:pubinfo { bnp:RAmitchell1961b dct:created "2026-10-26T00:00:00Z"^^xsd:dateTime ;
               dct:creator bl:BioLeanCurator ; npx:hasNanopubType SEPIO:0000432 . }

# --- nanopub c: prediction, the coupling membrane is proton-impermeable ----------------------
m61c:Head { bnp:RAmitchell1961c a np:Nanopublication ; np:hasAssertion m61c:assertion ;
            np:hasProvenance m61c:provenance ; np:hasPublicationInfo m61c:pubinfo . }
m61c:assertion {
  GO:0005743 RO:0000086 bl:LowProtonPermeability .   # mitochondrial inner membrane  has quality  low H+ permeability
  bl:LowProtonPermeability rdfs:subClassOf PATO:0001997 .  # framed as a decreased-amount quality (approximation)
}
m61c:provenance {
  m61c:assertion a SEPIO:0000432 ; bl:statementKind bl:Prediction ;
      prov:wasDerivedFrom bnp:RAmitchell1961b , pubmed:13771349 ; bl:sourceKind bl:SecondarySummary .
}
m61c:pubinfo { bnp:RAmitchell1961c dct:created "2026-10-26T00:00:00Z"^^xsd:dateTime ; dct:creator bl:BioLeanCurator . }

# --- nanopub d: prediction, uncouplers work by making the membrane proton-permeable ----------
m61d:Head { bnp:RAmitchell1961d a np:Nanopublication ; np:hasAssertion m61d:assertion ;
            np:hasProvenance m61d:provenance ; np:hasPublicationInfo m61d:pubinfo . }
m61d:assertion {
  CHEBI:42017 RO:0000087 GO:0017077 .    # 2,4-dinitrophenol has role ... oxidative phosphorylation uncoupler activity (see caveat)
  CHEBI:42017 RO:0002213 GO:1902600 .    # DNP positively regulates proton transmembrane transport (a leak)
}
m61d:provenance {
  m61d:assertion a SEPIO:0000432 ; bl:statementKind bl:Prediction ;
      prov:wasDerivedFrom bnp:RAmitchell1961b , pubmed:13771349 ; bl:sourceKind bl:SecondarySummary .
}
m61d:pubinfo { bnp:RAmitchell1961d dct:created "2026-10-26T00:00:00Z"^^xsd:dateTime ; dct:creator bl:BioLeanCurator . }
```

Could not express:
- "Anisotropic" arrangement of the chain and the ATPase (sidedness, vectorial chemistry). GO has
  `GO:0005743` but nothing for "which face"; RO has `has target start/end location` (RO:0002338/0002339) but
  those need named compartments (matrix vs intermembrane space) and the 1961 paper did not have them.
- "Electrochemical gradient" as a thing: no GO/CHEBI class for proton motive force as an entity, only
  processes driven by it. So the gradient, the central object of the theory, is implicit.
- "Not by a chemical intermediate" is a negation. RDF triples cannot say "no C~I exists"; I had to push it
  to a `bl:rivalOf` link and the controversy layer.
- RO:0000087 `has role` expects a CHEBI role, but `GO:0017077` is a molecular function. The real meaning
  ("DNP is a protonophore") has no clean CHEBI role term found in OLS ("uncoupler" search gave nothing usable).
- Prediction vs hypothesis: SEPIO has `hypothesis` but no `prediction`; local `bl:Prediction`.

### Jagendorf & Uribe 1966, PNAS. PMID 5220864 (summary only)

Three nanopubs: the core result (an imposed pH gradient alone makes ATP, in the dark), the dose-response
on pH jump size, and the authors' own conclusion, kept separate from the result.

```trig
@prefix j66a: <https://w3id.org/biolean/np/RAjagendorf1966a#> .
@prefix j66b: <https://w3id.org/biolean/np/RAjagendorf1966b#> .
@prefix j66c: <https://w3id.org/biolean/np/RAjagendorf1966c#> .

# --- nanopub a: result, acid-base transition drives ATP synthesis in the dark ----------------
j66a:Head { bnp:RAjagendorf1966a a np:Nanopublication ; np:hasAssertion j66a:assertion ;
            np:hasProvenance j66a:provenance ; np:hasPublicationInfo j66a:pubinfo . }
j66a:assertion {
  j66a:finding a biolink:Association ;
      biolink:subject   bl:ImposedTransmembranePHGradient ;      # no ontology class for an imposed pH jump
      biolink:predicate RO:0002304 ;                             # causally upstream of, positive effect
      biolink:object    GO:0015986 ;                             # proton motive force-driven ATP synthesis
      biolink:species_context_qualifier  NCBITaxon:3562 ;        # Spinacia oleracea
      biolink:anatomical_context_qualifier GO:0009535 ;          # chloroplast thylakoid membrane
      bl:lightCondition bl:Dark ;                                # no light, so no photosynthetic electron transport
      bl:pHBefore "4.0"^^xsd:decimal ; bl:pHAfter "8.0"^^xsd:decimal ;
      bl:requiredInput CHEBI:16761 , CHEBI:43474 ;               # ADP, phosphate present at the jump
      biolink:knowledge_level "observation" ; biolink:agent_type "manual_agent" .
  bl:ImposedTransmembranePHGradient rdfs:subClassOf bl:TransmembraneProtonGradient .
}
j66a:provenance {
  j66a:assertion a SEPIO:0000173 ;                               # study finding
      prov:wasDerivedFrom pubmed:5220864 ; bl:sourceKind bl:SecondarySummary ;
      prov:wasGeneratedBy j66a:study .
  j66a:study a SEPIO:0000125 ; dct:type OBI:0001285 ;            # research study; in vitro design
      bl:material "isolated spinach thylakoids, dark, succinate buffer pH ~4 -> pH ~8" .
  j66a:assertion SEPIO:0000006 [ a SEPIO:0000002 ; SEPIO:0000183 SEPIO:0000403 ;
      dct:type ECO:0000002 ] .                                   # direct assay evidence (ATP measured)
}
j66a:pubinfo { bnp:RAjagendorf1966a dct:created "2026-10-26T00:00:00Z"^^xsd:dateTime ;
               dct:creator bl:BioLeanCurator ; npx:hasNanopubType SEPIO:0000173 . }

# --- nanopub b: result, yield depends on size of the pH jump and the permeant acid ----------
j66b:Head { bnp:RAjagendorf1966b a np:Nanopublication ; np:hasAssertion j66b:assertion ;
            np:hasProvenance j66b:provenance ; np:hasPublicationInfo j66b:pubinfo . }
j66b:assertion {
  j66b:finding a biolink:Association ;
      biolink:subject   bl:PHJumpMagnitude ;
      biolink:predicate RO:0019001 ;                             # positively regulates characteristic
      biolink:object    bl:ATPYield ;
      biolink:species_context_qualifier NCBITaxon:3562 ;
      bl:modulatedBy bl:PermeantAcidIdentity ;                   # yield also depends on which acid
      biolink:knowledge_level "observation" .
}
j66b:provenance {
  j66b:assertion a SEPIO:0000173 ; prov:wasDerivedFrom pubmed:5220864 ;
      bl:sourceKind bl:SecondarySummary ; prov:wasGeneratedBy j66a:study .
}
j66b:pubinfo { bnp:RAjagendorf1966b dct:created "2026-10-26T00:00:00Z"^^xsd:dateTime ; dct:creator bl:BioLeanCurator . }

# --- nanopub c: the authors' conclusion, linked as support for Mitchell link 2 ---------------
j66c:Head { bnp:RAjagendorf1966c a np:Nanopublication ; np:hasAssertion j66c:assertion ;
            np:hasProvenance j66c:provenance ; np:hasPublicationInfo j66c:pubinfo . }
j66c:assertion {
  # "A transmembrane pH gradient alone is sufficient to drive ATP formation."
  bl:TransmembraneProtonGradient bl:sufficientFor GO:0015986 .   # no RO "sufficient for"
  j66a:assertion SIO:000208 m61b:assertion .                     # is supporting evidence for (Mitchell link 2)
  j66a:assertion cito:supports m61b:assertion .                  # same, CiTO flavour (common in nanopubs)
}
j66c:provenance {
  j66c:assertion a SEPIO:0000001 ;                               # assertion (an inference, not a measurement)
      prov:wasDerivedFrom pubmed:5220864 , bnp:RAjagendorf1966a ;
      prov:wasAttributedTo bl:AT_Jagendorf ; bl:sourceKind bl:SecondarySummary ;
      SEPIO:0000006 [ a SEPIO:0000002 ; SEPIO:0000183 SEPIO:0000403 ; dct:type ECO:0006185 ;  # author inference
                      SEPIO:0000084 j66a:assertion ] .
}
j66c:pubinfo { bnp:RAjagendorf1966c dct:created "2026-10-26T00:00:00Z"^^xsd:dateTime ; dct:creator bl:BioLeanCurator . }
```

Could not express:
- "Sufficient" (a gradient ALONE drives it). RO has causal "upstream of" but no sufficiency/necessity
  predicate, so the logically key word of the paper is a local `bl:sufficientFor`.
- The perturbation itself (an imposed pH jump) is not an ontology class; nor is "dark" as an experimental
  condition (no light -> rules out electron transport). Both local.
- pH values are bare literals on local properties; no shared unit/quantity model in Biolink for this.
- That the evidence is against Slater (no C~I can form without electron transport) is an inference two
  steps away; it goes in the controversy layer, not in this paper's nanopubs.

### Mitchell & Moyle 1967, Biochem J. PMID 16742541 (real abstract)

Five nanopubs. This is the one paper that itself states a *negative* result against the rival
("cannot be attributed to … a chemical intermediate"), so it gets a direct disputing evidence line.

```trig
@prefix mm67a: <https://w3id.org/biolean/np/RAmitchellmoyle1967a#> .
@prefix mm67b: <https://w3id.org/biolean/np/RAmitchellmoyle1967b#> .
@prefix mm67c: <https://w3id.org/biolean/np/RAmitchellmoyle1967c#> .
@prefix mm67d: <https://w3id.org/biolean/np/RAmitchellmoyle1967d#> .
@prefix mm67e: <https://w3id.org/biolean/np/RAmitchellmoyle1967e#> .

# --- a: respiration pulses translocate H+ across the cristae membrane -------------------------
mm67a:Head { bnp:RAmitchellmoyle1967a a np:Nanopublication ; np:hasAssertion mm67a:assertion ;
             np:hasProvenance mm67a:provenance ; np:hasPublicationInfo mm67a:pubinfo . }
mm67a:assertion {
  mm67a:finding a biolink:Association ;
      biolink:subject GO:0022900 ; biolink:predicate RO:0002304 ; biolink:object GO:1902600 ;
      biolink:species_context_qualifier NCBITaxon:10116 ;        # Rattus norvegicus
      biolink:anatomical_context_qualifier UBERON:0002107 , GO:0005743 ;   # liver; mitochondrial inner membrane
      biolink:knowledge_level "observation" .
}
mm67a:provenance {
  mm67a:assertion a SEPIO:0000173 ; prov:wasDerivedFrom pubmed:16742541 ;
      prov:wasGeneratedBy mm67a:study .
  mm67a:study a SEPIO:0000125 ; dct:type OBI:0001285 ;           # in vitro (isolated mitochondria suspension)
      bl:method "O2 pulse, pH electrode on outer aqueous phase" .
  mm67a:assertion SEPIO:0000006 [ a SEPIO:0000002 ; SEPIO:0000183 SEPIO:0000403 ; dct:type ECO:0000134 ] .  # transport assay evidence
}
mm67a:pubinfo { bnp:RAmitchellmoyle1967a dct:created "2026-10-26T00:00:00Z"^^xsd:dateTime ; dct:creator bl:BioLeanCurator . }

# --- b: quantitative stoichiometry, ->H+/O = 4 (succinate) and 6 (beta-hydroxybutyrate) ------
mm67b:Head { bnp:RAmitchellmoyle1967b a np:Nanopublication ; np:hasAssertion mm67b:assertion ;
             np:hasProvenance mm67b:provenance ; np:hasPublicationInfo mm67b:pubinfo . }
mm67b:assertion {
  mm67b:succ a SIO:001018 ;                                       # ratio
      rdfs:label "->H+/O quotient, succinate-oxidising span" ;
      SIO:000628 CHEBI:15378 , CHEBI:26806 ;                      # refers to hydron, succinate
      SIO:000300 "4"^^xsd:decimal ;                               # has value (per 2 reducing equivalents)
      bl:validPHRange "5.5-8.5" .
  mm67b:bhb a SIO:001018 ;
      rdfs:label "->H+/O quotient, beta-hydroxybutyrate-oxidising span" ;
      SIO:000628 CHEBI:15378 , CHEBI:37054 ;                      # hydron, 3-hydroxybutyrate
      SIO:000300 "6"^^xsd:decimal ; bl:validPHRange "5.5-8.5" .
  bl:Context_ratLiverMito biolink:species_context_qualifier NCBITaxon:10116 ;
      biolink:anatomical_context_qualifier UBERON:0002107 .
  mm67b:succ bl:inContext bl:Context_ratLiverMito . mm67b:bhb bl:inContext bl:Context_ratLiverMito .
}
mm67b:provenance {
  mm67b:assertion a SEPIO:0000173 ; prov:wasDerivedFrom pubmed:16742541 ; prov:wasGeneratedBy mm67a:study ;
      SEPIO:0000006 [ a SEPIO:0000002 ; SEPIO:0000183 SEPIO:0000403 ; dct:type ECO:0000134 ] .
}
mm67b:pubinfo { bnp:RAmitchellmoyle1967b dct:created "2026-10-26T00:00:00Z"^^xsd:dateTime ; dct:creator bl:BioLeanCurator . }

# --- c: uncouplers raise proton conductance of the membrane ------------------------------------
mm67c:Head { bnp:RAmitchellmoyle1967c a np:Nanopublication ; np:hasAssertion mm67c:assertion ;
             np:hasProvenance mm67c:provenance ; np:hasPublicationInfo mm67c:pubinfo . }
mm67c:assertion {
  CHEBI:42017  RO:0002213 GO:1902600 .   # 2,4-dinitrophenol  positively regulates  proton transmembrane transport (back-leak)
  CHEBI:75458  RO:0002213 GO:1902600 .   # FCCP
  CHEBI:749506 RO:0002213 GO:1902600 .   # gramicidin
  bl:UncouplerConductanceIncrease bl:quantitativelyAccountsFor bl:Uncoupling .   # "accounts quantitatively"
}
mm67c:provenance {
  mm67c:assertion a SEPIO:0000173 ; prov:wasDerivedFrom pubmed:16742541 ; prov:wasGeneratedBy mm67a:study ;
      SEPIO:0000006 [ a SEPIO:0000002 ; SEPIO:0000183 SEPIO:0000403 ; dct:type ECO:0006053 ] .   # pharmacological assay evidence
}
mm67c:pubinfo { bnp:RAmitchellmoyle1967c dct:created "2026-10-26T00:00:00Z"^^xsd:dateTime ; dct:creator bl:BioLeanCurator . }

# --- d: negative result, uncouplers do NOT change initial ->H+/O, so no uncoupler-sensitive C~I --
mm67d:Head { bnp:RAmitchellmoyle1967d a np:Nanopublication ; np:hasAssertion mm67d:assertion ;
             np:hasProvenance mm67d:provenance ; np:hasPublicationInfo mm67d:pubinfo . }
mm67d:assertion {
  mm67d:null a biolink:Association ;
      biolink:subject CHEBI:42017 ; biolink:predicate RO:0002566 ;   # causally influences
      biolink:object  mm67b:succ ;                                   # the initial ->H+/O quotient
      biolink:negated true ;                                         # Biolink's only negation hook
      biolink:species_context_qualifier NCBITaxon:10116 .
  # the inference drawn from the null, in the same graph so it is signed together with it:
  mm67d:assertion SIO:000209 s53a:assertion .                        # is disputing evidence for (Slater)
  mm67d:assertion cito:disputes s53a:assertion .
}
mm67d:provenance {
  mm67d:assertion a SEPIO:0000173 ; prov:wasDerivedFrom pubmed:16742541 ; prov:wasGeneratedBy mm67a:study ;
      SEPIO:0000006 [ a SEPIO:0000002 ; SEPIO:0000183 SEPIO:0000404 ;   # DISPUTING
                      dct:type ECO:0006053 ; SEPIO:0000084 mm67a:assertion , mm67b:assertion ] .
}
mm67d:pubinfo { bnp:RAmitchellmoyle1967d dct:created "2026-10-26T00:00:00Z"^^xsd:dateTime ; dct:creator bl:BioLeanCurator . }

# --- e: methodological caveat, anions/cations cause only APPARENT changes in ->H+/O -----------
mm67e:Head { bnp:RAmitchellmoyle1967e a np:Nanopublication ; np:hasAssertion mm67e:assertion ;
             np:hasProvenance mm67e:provenance ; np:hasPublicationInfo mm67e:pubinfo . }
mm67e:assertion {
  CHEBI:26806 bl:causesArtefactIn mm67b:succ .   # succinate
  CHEBI:15792 bl:causesArtefactIn mm67b:succ .   # malonate(2-)
  CHEBI:26020 bl:causesArtefactIn mm67b:succ .   # phosphate
  CHEBI:29101 bl:causesArtefactIn mm67b:succ .   # sodium(1+)
  bl:causesArtefactIn rdfs:comment "raises rate of pH-driven decay of acid pulse; true quotient unchanged" .
}
mm67e:provenance {
  mm67e:assertion a SEPIO:0000173 ; prov:wasDerivedFrom pubmed:16742541 ; prov:wasGeneratedBy mm67a:study .
}
mm67e:pubinfo { bnp:RAmitchellmoyle1967e dct:created "2026-10-26T00:00:00Z"^^xsd:dateTime ; dct:creator bl:BioLeanCurator . }
```

Could not express:
- The H+/O quotients: SIO can hold "ratio, value 4", but the *meaning* ("per bivalent reducing equivalent
  through the succinate span", "after extrapolating the decay") is prose in `rdfs:label`. No unit model.
- The null result needed `biolink:negated true`, which is a Biolink-only flag. RDF/OWL readers that do
  not know Biolink will read the triple as a positive claim. This is the sharpest danger in the formalism.
- "Accounts quantitatively for" (the conductance rise explains ALL the uncoupling): no predicate.
- Point 6 (support for "loop 3" configuration, rotenone/antimycin sites): needs Mitchell's loop model,
  which has no ontology. Skipped.
- The anion/cation caveat is a statement about the *measurement*, not the biology. Nanopubs have no slot
  for "artefact of method"; it ended up as a local predicate.

### Hinkle & Horstman 1971, JBC. PMID 4330063 (summary only)

Three nanopubs: proton uptake by inside-out particles (sidedness reversed), its abolition by uncoupler,
and the "together with later work" support claim, which I keep separate and weaker because the summary
leans on other papers.

```trig
@prefix hh71a: <https://w3id.org/biolean/np/RAhinkle1971a#> .
@prefix hh71b: <https://w3id.org/biolean/np/RAhinkle1971b#> .
@prefix hh71c: <https://w3id.org/biolean/np/RAhinkle1971c#> .

# --- a: respiration in inside-out submitochondrial particles moves H+ INTO the vesicle ---------
hh71a:Head { bnp:RAhinkle1971a a np:Nanopublication ; np:hasAssertion hh71a:assertion ;
             np:hasProvenance hh71a:provenance ; np:hasPublicationInfo hh71a:pubinfo . }
hh71a:assertion {
  hh71a:finding a biolink:Association ;
      biolink:subject GO:0022900 ; biolink:predicate RO:0002304 ; biolink:object GO:1902600 ;
      biolink:species_context_qualifier NCBITaxon:9913 ;          # Bos taurus
      biolink:anatomical_context_qualifier UBERON:0000948 , GO:0005743 ;   # heart; mitochondrial inner membrane
      bl:preparation bl:SubmitochondrialParticle_InsideOut ;
      bl:electronDonor CHEBI:16908 , CHEBI:26806 ;                # NADH, succinate
      bl:protonDirection bl:IntoVesicleLumen ;                    # = out of the matrix side in an intact organelle
      biolink:knowledge_level "observation" .
}
hh71a:provenance {
  hh71a:assertion a SEPIO:0000173 ; prov:wasDerivedFrom pubmed:4330063 ; bl:sourceKind bl:SecondarySummary ;
      prov:wasGeneratedBy [ a SEPIO:0000125 ; dct:type OBI:0001285 ] ;
      SEPIO:0000006 [ a SEPIO:0000002 ; SEPIO:0000183 SEPIO:0000403 ; dct:type ECO:0000134 ] .
}
hh71a:pubinfo { bnp:RAhinkle1971a dct:created "2026-10-26T00:00:00Z"^^xsd:dateTime ; dct:creator bl:BioLeanCurator . }

# --- b: uncouplers abolish the uptake -----------------------------------------------------------
hh71b:Head { bnp:RAhinkle1971b a np:Nanopublication ; np:hasAssertion hh71b:assertion ;
             np:hasProvenance hh71b:provenance ; np:hasPublicationInfo hh71b:pubinfo . }
hh71b:assertion {
  hh71b:finding a biolink:Association ;
      biolink:subject bl:Uncoupler ;                              # summary does not name the agent
      biolink:predicate RO:0002212 ;                              # negatively regulates
      biolink:object hh71a:finding ;                              # the net H+ uptake measured in (a)
      biolink:species_context_qualifier NCBITaxon:9913 ;
      bl:effectSize bl:Abolished .
  bl:Uncoupler rdfs:subClassOf [ a <http://www.w3.org/2002/07/owl#Restriction> ;
      <http://www.w3.org/2002/07/owl#onProperty> RO:0002327 ;               # enables
      <http://www.w3.org/2002/07/owl#someValuesFrom> GO:0017077 ] .         # oxidative phosphorylation uncoupler activity
}
hh71b:provenance {
  hh71b:assertion a SEPIO:0000173 ; prov:wasDerivedFrom pubmed:4330063 ; bl:sourceKind bl:SecondarySummary ;
      SEPIO:0000006 [ a SEPIO:0000002 ; SEPIO:0000183 SEPIO:0000403 ; dct:type ECO:0006053 ] .
}
hh71b:pubinfo { bnp:RAhinkle1971b dct:created "2026-10-26T00:00:00Z"^^xsd:dateTime ; dct:creator bl:BioLeanCurator . }

# --- c: support claim for Mitchell link 1, explicitly weaker -----------------------------------
hh71c:Head { bnp:RAhinkle1971c a np:Nanopublication ; np:hasAssertion hh71c:assertion ;
             np:hasProvenance hh71c:provenance ; np:hasPublicationInfo hh71c:pubinfo . }
hh71c:assertion {
  hh71a:assertion SIO:000208 m61a:assertion .                     # supports electron transport -> H+ translocation
}
hh71c:provenance {
  hh71c:assertion a SEPIO:0000001 ; prov:wasDerivedFrom pubmed:4330063 , bnp:RAhinkle1971a , bnp:RAhinkle1971b ;
      bl:sourceKind bl:SecondarySummary ;
      SEPIO:0000006 [ a SEPIO:0000002 ; SEPIO:0000183 SEPIO:0000403 ;
                      dct:type ECO:0006185 ;                      # author inference
                      SEPIO:0000429 "0.6"^^xsd:decimal ;          # evidence_line_strength_score (curator's, 0-1)
                      SEPIO:0000084 hh71a:assertion , hh71b:assertion ] .
}
hh71c:pubinfo { bnp:RAhinkle1971c dct:created "2026-10-26T00:00:00Z"^^xsd:dateTime ; dct:creator bl:BioLeanCurator . }
```

Could not express:
- Membrane sidedness (inside-out vs right-side-out) is the whole trick of the experiment. No ontology
  class for "inverted submitochondrial particle" or for "lumen of an inverted vesicle"; all local.
- Using the finding node of (a) as the *object* of (b) is legal RDF but not a Biolink-sanctioned pattern;
  Biolink objects are supposed to be named things, not other associations.
- "Together with later work from the same lab" is cross-paper evidence pooling. SEPIO can list several
  evidence items, but there is no PMID here for the later work, so it is just a weaker score.
- `SEPIO:0000429` takes a number but SEPIO does not define its scale. 0.6 is my number, not a standard.

### Racker & Stoeckenius 1974, JBC. PMID 4272126 (summary only)

Four nanopubs: light-driven H+ uptake by bacteriorhodopsin vesicles; light-driven ATP synthesis when the
mitochondrial ATPase is added; inhibitor controls; the sufficiency inference, which disputes Slater.

```trig
@prefix rs74a: <https://w3id.org/biolean/np/RAracker1974a#> .
@prefix rs74b: <https://w3id.org/biolean/np/RAracker1974b#> .
@prefix rs74c: <https://w3id.org/biolean/np/RAracker1974c#> .
@prefix rs74d: <https://w3id.org/biolean/np/RAracker1974d#> .

# --- a: bacteriorhodopsin in liposomes pumps protons in the light ------------------------------
rs74a:Head { bnp:RAracker1974a a np:Nanopublication ; np:hasAssertion rs74a:assertion ;
             np:hasProvenance rs74a:provenance ; np:hasPublicationInfo rs74a:pubinfo . }
rs74a:assertion {
  UniProtKB:P02945 RO:0002327 GO:0015454 .     # bacteriorhodopsin enables light-driven active monoatomic ion transmembrane transporter activity
  UniProtKB:P02945 RO:0002162 NCBITaxon:2242 . # in taxon Halobacterium salinarum (= H. halobium)
  GO:0015454 RO:0002313 CHEBI:15378 .          # transports hydron
  GO:0015454 BFO:0000066 bl:ReconstitutedProteoliposome .   # occurs in (artificial vesicle; no GO class)
}
rs74a:provenance {
  rs74a:assertion a SEPIO:0000173 ; prov:wasDerivedFrom pubmed:4272126 ; bl:sourceKind bl:SecondarySummary ;
      prov:wasGeneratedBy rs74a:study .
  rs74a:study a SEPIO:0000125 ; dct:type OBI:0001285 ;
      bl:components UniProtKB:P02945 , GO:0045259 , CHEBI:64482 .   # bR, F1F0 ATP synthase (bovine heart), phosphatidylcholine (lipid class assumed)
  rs74a:assertion SEPIO:0000006 [ a SEPIO:0000002 ; SEPIO:0000183 SEPIO:0000403 ; dct:type ECO:0000134 ] .
}
rs74a:pubinfo { bnp:RAracker1974a dct:created "2026-10-26T00:00:00Z"^^xsd:dateTime ; dct:creator bl:BioLeanCurator . }

# --- b: with mitochondrial ATPase added, light drives ATP synthesis -------------------------------
rs74b:Head { bnp:RAracker1974b a np:Nanopublication ; np:hasAssertion rs74b:assertion ;
             np:hasProvenance rs74b:provenance ; np:hasPublicationInfo rs74b:pubinfo . }
rs74b:assertion {
  rs74b:finding a biolink:Association ;
      biolink:subject GO:0015454 ; biolink:predicate RO:0002304 ; biolink:object GO:0015986 ;
      biolink:species_context_qualifier NCBITaxon:2242 , NCBITaxon:9913 ;   # two species in ONE system
      bl:subjectTaxon NCBITaxon:2242 ; bl:objectTaxon NCBITaxon:9913 ;      # which part is from which
      bl:condition bl:Illuminated ;
      biolink:knowledge_level "observation" .
}
rs74b:provenance {
  rs74b:assertion a SEPIO:0000173 ; prov:wasDerivedFrom pubmed:4272126 ; bl:sourceKind bl:SecondarySummary ;
      prov:wasGeneratedBy rs74a:study ;
      SEPIO:0000006 [ a SEPIO:0000002 ; SEPIO:0000183 SEPIO:0000403 ;
                      dct:type ECO:0005543 ] .   # biological system reconstruction evidence by experimental evidence from mixed species used in manual assertion
}
rs74b:pubinfo { bnp:RAracker1974b dct:created "2026-10-26T00:00:00Z"^^xsd:dateTime ; dct:creator bl:BioLeanCurator . }

# --- c: controls, uncouplers and oligomycin abolish ATP synthesis ---------------------------------
rs74c:Head { bnp:RAracker1974c a np:Nanopublication ; np:hasAssertion rs74c:assertion ;
             np:hasProvenance rs74c:provenance ; np:hasPublicationInfo rs74c:pubinfo . }
rs74c:assertion {
  CHEBI:25675 RO:0002212 GO:0015986 .     # oligomycin negatively regulates pmf-driven ATP synthesis
  bl:Uncoupler RO:0002212 GO:0015986 .    # (agent not named in summary)
  rs74c:assertion bl:scope rs74b:finding .   # i.e. in that reconstituted system
}
rs74c:provenance {
  rs74c:assertion a SEPIO:0000173 ; prov:wasDerivedFrom pubmed:4272126 ; bl:sourceKind bl:SecondarySummary ;
      SEPIO:0000006 [ a SEPIO:0000002 ; SEPIO:0000183 SEPIO:0000403 ; dct:type ECO:0006053 ] .
}
rs74c:pubinfo { bnp:RAracker1974c dct:created "2026-10-26T00:00:00Z"^^xsd:dateTime ; dct:creator bl:BioLeanCurator . }

# --- d: inference, no shared chemical intermediate possible => gradient is sufficient -------------
rs74d:Head { bnp:RAracker1974d a np:Nanopublication ; np:hasAssertion rs74d:assertion ;
             np:hasProvenance rs74d:provenance ; np:hasPublicationInfo rs74d:pubinfo . }
rs74d:assertion {
  bl:TransmembraneProtonGradient bl:sufficientFor GO:0015986 .
  rs74b:assertion SIO:000208 m61b:assertion .     # supports Mitchell link 2
  rs74b:assertion SIO:000209 s53a:assertion .     # disputes Slater
  rs74b:assertion cito:disputes s53a:assertion .
}
rs74d:provenance {
  rs74d:assertion a SEPIO:0000001 ;
      prov:wasDerivedFrom pubmed:4272126 , bnp:RAracker1974b , bnp:RAracker1974c ;
      bl:sourceKind bl:SecondarySummary ;
      SEPIO:0000006 [ a SEPIO:0000002 ; SEPIO:0000183 SEPIO:0000403 ; dct:type ECO:0006185 ;
                      SEPIO:0000084 rs74b:assertion , rs74c:assertion ] ;
      bl:argumentBy bl:NoSharedEvolutionaryOrigin .   # proteins from unrelated organisms
}
rs74d:pubinfo { bnp:RAracker1974d dct:created "2026-10-26T00:00:00Z"^^xsd:dateTime ; dct:creator bl:BioLeanCurator . }
```

Could not express:
- The mosaic: subject process from an archaeon, object process from cow, in one vesicle. Biolink's
  `species_context_qualifier` is one bag; "which half came from which species" is local.
- The core argument ("two unrelated proteins cannot share a chemical intermediate") is an argument from
  evolutionary unrelatedness. No ECO/SEPIO term for that style of reasoning.
- GO has no "light-driven proton pump activity"; I used its parent (monoatomic ion) plus `transports
  hydron`, which is two triples where biology has one concept.
- Liposome / proteoliposome is not a GO cellular component. Local `bl:` class.

### Controversy layer (curation nanopubs over the six papers above)

Nanopubs never change, so the controversy is three new nanopubs whose *assertions* are about other
nanopubs' assertion graphs: (1) the two hypotheses contradict each other; (2) an evidence summary for
each, with SEPIO supporting/disputing lines whose items are the result graphs; (3) a later version of the
summary that `npx:supersedes` the first after Racker 1974 is added. This is the nanopub-native
way to show "the field changed its mind" without editing anything.

```trig
@prefix cx1: <https://w3id.org/biolean/np/RAcontroversy1#> .
@prefix cx2: <https://w3id.org/biolean/np/RAcontroversy2#> .
@prefix cx3: <https://w3id.org/biolean/np/RAcontroversy3#> .

# --- 1: the rivalry itself -------------------------------------------------------------------------
cx1:Head { bnp:RAcontroversy1 a np:Nanopublication ; np:hasAssertion cx1:assertion ;
           np:hasProvenance cx1:provenance ; np:hasPublicationInfo cx1:pubinfo . }
cx1:assertion {
  m61b:assertion SEPIO:0000101 s53a:assertion .     # contradicts (chemiosmotic vs chemical coupling)
  s53a:assertion SEPIO:0000101 m61b:assertion .     # symmetric, stated both ways (SEPIO does not declare symmetry)
}
cx1:provenance { cx1:assertion prov:wasAttributedTo bl:BioLeanCurator ;
                 SEPIO:0000006 [ a SEPIO:0000002 ; dct:type ECO:0000305 ] . }   # curator inference used in manual assertion
cx1:pubinfo { bnp:RAcontroversy1 dct:created "2026-10-26T00:00:00Z"^^xsd:dateTime ; dct:creator bl:BioLeanCurator . }

# --- 2: evidence summary, version 1 (state of play c. 1971) ----------------------------------------
cx2:Head { bnp:RAcontroversy2 a np:Nanopublication ; np:hasAssertion cx2:assertion ;
           np:hasProvenance cx2:provenance ; np:hasPublicationInfo cx2:pubinfo . }
cx2:assertion {
  # Chemiosmotic coupling (Mitchell, both links)
  m61b:assertion SEPIO:0000007 cx2:forMitchell_pH ;           # has_supporting_evidence_line
                 SEPIO:0000007 cx2:forMitchell_stoich .
  m61a:assertion SEPIO:0000007 cx2:forMitchell_stoich , cx2:forMitchell_smp .
  cx2:forMitchell_pH     a SEPIO:0000002 ; SEPIO:0000183 SEPIO:0000403 ; SEPIO:0000084 j66a:assertion ;
                         dct:type ECO:0000002 ; SEPIO:0000429 "0.7"^^xsd:decimal .
  cx2:forMitchell_stoich a SEPIO:0000002 ; SEPIO:0000183 SEPIO:0000403 ;
                         SEPIO:0000084 mm67a:assertion , mm67b:assertion , mm67c:assertion ;
                         dct:type ECO:0000134 ; SEPIO:0000429 "0.8"^^xsd:decimal .
  cx2:forMitchell_smp    a SEPIO:0000002 ; SEPIO:0000183 SEPIO:0000403 ;
                         SEPIO:0000084 hh71a:assertion , hh71b:assertion ;
                         dct:type ECO:0000134 ; SEPIO:0000429 "0.6"^^xsd:decimal .

  # Chemical intermediate (Slater)
  s53a:assertion SEPIO:0000007 cx2:forSlater_analogy ;
                 SEPIO:0000008 cx2:againstSlater_pH , cx2:againstSlater_null ;   # has_disputing_evidence_line
                 SEPIO:0000009 cx2:slater_notFound .                            # has_inconclusive_evidence_line
  cx2:forSlater_analogy  a SEPIO:0000002 ; SEPIO:0000183 SEPIO:0000403 ; SEPIO:0000084 GO:0006096 ;
                         dct:type ECO:0000001 ; SEPIO:0000429 "0.3"^^xsd:decimal .
  cx2:againstSlater_pH   a SEPIO:0000002 ; SEPIO:0000183 SEPIO:0000404 ; SEPIO:0000084 j66a:assertion ;
                         dct:type ECO:0000002 ; SEPIO:0000429 "0.6"^^xsd:decimal ;
                         rdfs:comment "ATP made in the dark with no electron transport, so no C~I can have been made." .
  cx2:againstSlater_null a SEPIO:0000002 ; SEPIO:0000183 SEPIO:0000404 ; SEPIO:0000084 mm67d:assertion ;
                         dct:type ECO:0006053 ; SEPIO:0000429 "0.7"^^xsd:decimal .
  cx2:slater_notFound    a SEPIO:0000002 ; SEPIO:0000183 SEPIO:0000405 ;     # inconclusive
                         rdfs:comment "C~I never isolated despite searching; absence of evidence, no single PMID here." .
}
cx2:provenance { cx2:assertion prov:wasAttributedTo bl:BioLeanCurator ;
                 prov:wasDerivedFrom bnp:RAjagendorf1966a , bnp:RAmitchellmoyle1967d , bnp:RAhinkle1971a . }
cx2:pubinfo { bnp:RAcontroversy2 dct:created "2026-10-26T00:00:00Z"^^xsd:dateTime ; dct:creator bl:BioLeanCurator ;
              bl:asOfLiteratureDate "1971"^^xsd:gYear . }

# --- 3: evidence summary, version 2, adds Racker 1974 and SUPERSEDES version 1 -----------------------
cx3:Head { bnp:RAcontroversy3 a np:Nanopublication ; np:hasAssertion cx3:assertion ;
           np:hasProvenance cx3:provenance ; np:hasPublicationInfo cx3:pubinfo . }
cx3:assertion {
  # (all lines of cx2 restated here, since a superseding nanopub must be self-contained; elided for space)
  m61b:assertion SEPIO:0000007 cx3:forMitchell_reconst .
  s53a:assertion SEPIO:0000008 cx3:againstSlater_reconst .
  cx3:forMitchell_reconst  a SEPIO:0000002 ; SEPIO:0000183 SEPIO:0000403 ;
                           SEPIO:0000084 rs74b:assertion , rs74c:assertion ;
                           dct:type ECO:0005543 ; SEPIO:0000429 "0.9"^^xsd:decimal .
  cx3:againstSlater_reconst a SEPIO:0000002 ; SEPIO:0000183 SEPIO:0000404 ;
                           SEPIO:0000084 rs74d:assertion ;
                           dct:type ECO:0005543 ; SEPIO:0000429 "0.8"^^xsd:decimal .
}
cx3:provenance { cx3:assertion prov:wasAttributedTo bl:BioLeanCurator ;
                 prov:wasRevisionOf cx2:assertion ;
                 prov:wasDerivedFrom bnp:RAracker1974b , bnp:RAracker1974d . }
cx3:pubinfo {
  bnp:RAcontroversy3 npx:supersedes bnp:RAcontroversy2 ;     # same signer, so supersession is allowed
      dct:created "2026-10-26T00:00:00Z"^^xsd:dateTime ; dct:creator bl:BioLeanCurator ;
      bl:asOfLiteratureDate "1974"^^xsd:gYear .
}
```

Could not express:
- Who *won*. SEPIO lets me hang more and stronger lines on one side; it has no "accepted / rejected"
  status for a proposition, and no rule that turns lines into a verdict.
- Slater's camp never retracted, so `npx:retracts` is not usable: it needs the original signer.
  Disagreement across authors is only ever a new assertion.
- "C~I was looked for and never found" is absence of evidence with no single source; `inconclusive` is
  the closest direction and is too weak.
- `npx:supersedes` replaces the *whole* nanopub, so the new summary must restate every old line. Real
  incremental evidence accrual (add one line) is not native.

### Yoshino 2011, Cell Metab. PMID 21982712 (real abstract)

From here on the claims are phenotype-in-context, so every assertion is a Biolink association node with
qualifiers (Biolink 3/4 style: `biolink:affects` + `qualified_predicate` + aspect/direction qualifiers).
Doses and routes are not in the abstract, so they are not captured.

```trig
@prefix y11a: <https://w3id.org/biolean/np/RAyoshino2011a#> .
@prefix y11b: <https://w3id.org/biolean/np/RAyoshino2011b#> .
@prefix y11c: <https://w3id.org/biolean/np/RAyoshino2011c#> .
@prefix y11d: <https://w3id.org/biolean/np/RAyoshino2011d#> .
@prefix y11e: <https://w3id.org/biolean/np/RAyoshino2011e#> .

# --- a: high-fat diet lowers NAD+ (via NAMPT) in metabolic organs -------------------------------
y11a:Head { bnp:RAyoshino2011a a np:Nanopublication ; np:hasAssertion y11a:assertion ;
            np:hasProvenance y11a:provenance ; np:hasPublicationInfo y11a:pubinfo . }
y11a:assertion {
  y11a:finding a biolink:Association ;
      biolink:subject EFO:0002757 ;                                 # high fat diet
      biolink:predicate biolink:affects ;
      biolink:qualified_predicate biolink:causes ;
      biolink:object CHEBI:15846 ;                                  # NAD(+)
      biolink:object_aspect_qualifier "abundance" ;
      biolink:object_direction_qualifier "decreased" ;
      biolink:causal_mechanism_qualifier bl:ReducedNAMPTMediatedBiosynthesis ;   # via UniProtKB:Q99KQ4 / GO:0047280
      biolink:species_context_qualifier NCBITaxon:10090 ;
      biolink:anatomical_context_qualifier bl:MetabolicOrgans ;     # abstract does not name them
      biolink:knowledge_level "observation" .
  bl:ReducedNAMPTMediatedBiosynthesis RO:0002233 UniProtKB:Q99KQ4 .   # (local mechanism node) involves mouse Nampt
}
y11a:provenance {
  y11a:assertion a SEPIO:0000173 ; prov:wasDerivedFrom pubmed:21982712 ;
      prov:wasGeneratedBy y11a:study .
  y11a:study a SEPIO:0000125 ; dct:type OBI:0001199 .               # in vivo design
  y11a:assertion SEPIO:0000006 [ a SEPIO:0000002 ; SEPIO:0000183 SEPIO:0000403 ; dct:type ECO:0000005 ] .  # enzymatic activity assay evidence
}
y11a:pubinfo { bnp:RAyoshino2011a dct:created "2026-10-26T00:00:00Z"^^xsd:dateTime ; dct:creator bl:BioLeanCurator . }

# --- b: NMN ameliorates glucose intolerance in HFD-induced T2D mice, by restoring NAD+ ------------
y11b:Head { bnp:RAyoshino2011b a np:Nanopublication ; np:hasAssertion y11b:assertion ;
            np:hasProvenance y11b:provenance ; np:hasPublicationInfo y11b:pubinfo . }
y11b:assertion {
  y11b:finding a biolink:Association ;
      biolink:subject CHEBI:16171 ;                                 # NMN (zwitterion; ChEBI's parent NMN entry)
      biolink:predicate biolink:ameliorates_condition ;             # = RO:0003307
      biolink:object MP:0005293 ;                                   # impaired glucose tolerance
      biolink:species_context_qualifier NCBITaxon:10090 ;
      biolink:disease_context_qualifier MONDO:0005148 ;             # type 2 diabetes mellitus (diet-induced model)
      bl:modelInducedBy EFO:0002757 ;                               # high fat diet
      biolink:causal_mechanism_qualifier bl:RestorationOfNADLevels ;
      biolink:knowledge_level "observation" .
}
y11b:provenance {
  y11b:assertion a SEPIO:0000173 ; prov:wasDerivedFrom pubmed:21982712 ; prov:wasGeneratedBy y11a:study ;
      SEPIO:0000006 [ a SEPIO:0000002 ; SEPIO:0000183 SEPIO:0000403 ; dct:type ECO:0000059 ;   # experimental phenotypic evidence
                      SEPIO:0000084 OBI:0000721 ] .                 # evidence item: glucose tolerance test
}
y11b:pubinfo { bnp:RAyoshino2011b dct:created "2026-10-26T00:00:00Z"^^xsd:dateTime ; dct:creator bl:BioLeanCurator . }

# --- c: NMN raises hepatic insulin sensitivity, partly via SIRT1 -----------------------------------
y11c:Head { bnp:RAyoshino2011c a np:Nanopublication ; np:hasAssertion y11c:assertion ;
            np:hasProvenance y11c:provenance ; np:hasPublicationInfo y11c:pubinfo . }
y11c:assertion {
  y11c:finding a biolink:Association ;
      biolink:subject CHEBI:16171 ; biolink:predicate biolink:affects ;
      biolink:qualified_predicate biolink:causes ;
      biolink:object GO:0032869 ;                                   # cellular response to insulin stimulus
      biolink:object_direction_qualifier "increased" ;
      biolink:anatomical_context_qualifier UBERON:0002107 ;         # liver
      biolink:species_context_qualifier NCBITaxon:10090 ;
      biolink:disease_context_qualifier MONDO:0005148 ;
      bl:mediatedBy UniProtKB:Q923E4 ; bl:mediationDegree bl:Partial ;   # mouse Sirt1, "partly"
      biolink:knowledge_level "observation" .
}
y11c:provenance {
  y11c:assertion a SEPIO:0000173 ; prov:wasDerivedFrom pubmed:21982712 ; prov:wasGeneratedBy y11a:study ;
      SEPIO:0000006 [ a SEPIO:0000002 ; SEPIO:0000183 SEPIO:0000403 ; dct:type ECO:0000059 ] .
}
y11c:pubinfo { bnp:RAyoshino2011c dct:created "2026-10-26T00:00:00Z"^^xsd:dateTime ; dct:creator bl:BioLeanCurator . }

# --- d: NAD+ and NAMPT decline with age in multiple organs -----------------------------------------
y11d:Head { bnp:RAyoshino2011d a np:Nanopublication ; np:hasAssertion y11d:assertion ;
            np:hasProvenance y11d:provenance ; np:hasPublicationInfo y11d:pubinfo . }
y11d:assertion {
  y11d:nad a biolink:Association ;
      biolink:subject bl:Ageing ; biolink:predicate biolink:affects ; biolink:qualified_predicate biolink:causes ;
      biolink:object CHEBI:15846 ;
      biolink:object_aspect_qualifier "abundance" ; biolink:object_direction_qualifier "decreased" ;
      biolink:species_context_qualifier NCBITaxon:10090 ; biolink:knowledge_level "observation" .
  y11d:nampt a biolink:Association ;
      biolink:subject bl:Ageing ; biolink:predicate biolink:affects ; biolink:qualified_predicate biolink:causes ;
      biolink:object UniProtKB:Q99KQ4 ;
      biolink:object_aspect_qualifier "abundance" ; biolink:object_direction_qualifier "decreased" ;
      biolink:species_context_qualifier NCBITaxon:10090 ; biolink:knowledge_level "observation" .
}
y11d:provenance {
  y11d:assertion a SEPIO:0000173 ; prov:wasDerivedFrom pubmed:21982712 ;
      SEPIO:0000006 [ a SEPIO:0000002 ; SEPIO:0000183 SEPIO:0000403 ; dct:type ECO:0000010 ] .   # protein expression evidence
}
y11d:pubinfo { bnp:RAyoshino2011d dct:created "2026-10-26T00:00:00Z"^^xsd:dateTime ; dct:creator bl:BioLeanCurator . }

# --- e: NMN improves glucose intolerance and lipid profile in age-induced T2D mice ------------------
y11e:Head { bnp:RAyoshino2011e a np:Nanopublication ; np:hasAssertion y11e:assertion ;
            np:hasProvenance y11e:provenance ; np:hasPublicationInfo y11e:pubinfo . }
y11e:assertion {
  y11e:glucose a biolink:Association ;
      biolink:subject CHEBI:16171 ; biolink:predicate biolink:ameliorates_condition ; biolink:object MP:0005293 ;
      biolink:species_context_qualifier NCBITaxon:10090 ;
      biolink:disease_context_qualifier MONDO:0005148 ; bl:modelInducedBy bl:Ageing ;
      biolink:stage_qualifier PATO:0000308 ;                        # old (no numeric age in abstract)
      biolink:knowledge_level "observation" .
  y11e:lipid a biolink:Association ;
      biolink:subject CHEBI:16171 ; biolink:predicate biolink:affects ; biolink:qualified_predicate biolink:causes ;
      biolink:object GO:0055088 ;                                   # lipid homeostasis ("lipid profiles", direction = improved)
      biolink:object_direction_qualifier "increased" ;
      biolink:species_context_qualifier NCBITaxon:10090 ; biolink:stage_qualifier PATO:0000308 ;
      biolink:knowledge_level "observation" .
}
y11e:provenance {
  y11e:assertion a SEPIO:0000173 ; prov:wasDerivedFrom pubmed:21982712 ;
      SEPIO:0000006 [ a SEPIO:0000002 ; SEPIO:0000183 SEPIO:0000403 ; dct:type ECO:0000059 ] .
}
y11e:pubinfo { bnp:RAyoshino2011e dct:created "2026-10-26T00:00:00Z"^^xsd:dateTime ; dct:creator bl:BioLeanCurator . }
```

Could not express:
- "Ageing" as the cause of a change: there is no clean class for "the passage of time in an adult
  organism" as a Biolink subject. Local `bl:Ageing`; it is really a comparison of two age groups.
- "Partly through SIRT1": Biolink has `causal_mechanism_qualifier` (enum) but no "mediated by gene X,
  partially". Local `bl:mediatedBy` / `bl:mediationDegree`.
- "Restores gene expression related to oxidative stress, inflammation, circadian rhythm" (GO:0006979,
  GO:0006954, GO:0007623): "restores toward control" is a direction relative to two baselines (HFD vs
  chow). Biolink direction is only increased/decreased. Dropped rather than guessed.
- "Improved lipid profile" has no single direction; mapping it to "increased lipid homeostasis" is a fudge.
- "Metabolic organs" and "multiple organs" are unnamed in the abstract; a placeholder, not UBERON.

### Gomes 2013, Cell. PMID 24360282 (real abstract)

Five nanopubs. Note: the abstract never names NMN; it says "raising NAD+ levels". I annotate what the
abstract says (NAD+ raised) and do not upgrade it to "NMN" without the full text.

```trig
@prefix g13a: <https://w3id.org/biolean/np/RAgomes2013a#> .
@prefix g13b: <https://w3id.org/biolean/np/RAgomes2013b#> .
@prefix g13c: <https://w3id.org/biolean/np/RAgomes2013c#> .
@prefix g13d: <https://w3id.org/biolean/np/RAgomes2013d#> .
@prefix g13e: <https://w3id.org/biolean/np/RAgomes2013e#> .

# --- a: ageing selectively lowers mtDNA-encoded OXPHOS subunits ------------------------------------
g13a:Head { bnp:RAgomes2013a a np:Nanopublication ; np:hasAssertion g13a:assertion ;
            np:hasProvenance g13a:provenance ; np:hasPublicationInfo g13a:pubinfo . }
g13a:assertion {
  g13a:mt a biolink:Association ;
      biolink:subject bl:Ageing ; biolink:predicate biolink:affects ; biolink:qualified_predicate biolink:causes ;
      biolink:object bl:MitochondriallyEncodedOXPHOSSubunit ;     # no class for "mtDNA-encoded subunits of GO:0006119"
      biolink:object_aspect_qualifier "abundance" ; biolink:object_direction_qualifier "decreased" ;
      biolink:species_context_qualifier NCBITaxon:10090 ; biolink:knowledge_level "observation" .
  g13a:nuc a biolink:Association ;                                # the NEGATIVE half: nuclear-encoded unchanged
      biolink:subject bl:Ageing ; biolink:predicate biolink:affects ;
      biolink:object bl:NuclearEncodedOXPHOSSubunit ;
      biolink:negated true ;
      biolink:species_context_qualifier NCBITaxon:10090 ; biolink:knowledge_level "observation" .
}
g13a:provenance {
  g13a:assertion a SEPIO:0000173 ; prov:wasDerivedFrom pubmed:24360282 ;
      prov:wasGeneratedBy [ a SEPIO:0000125 ; dct:type OBI:0001199 ] ;
      SEPIO:0000006 [ a SEPIO:0000002 ; SEPIO:0000183 SEPIO:0000403 ; dct:type ECO:0000010 ] .
}
g13a:pubinfo { bnp:RAgomes2013a dct:created "2026-10-26T00:00:00Z"^^xsd:dateTime ; dct:creator bl:BioLeanCurator . }

# --- b: mechanism, falling nuclear NAD+ -> HIF-1a accumulates in normoxia (pseudohypoxia) ----------
g13b:Head { bnp:RAgomes2013b a np:Nanopublication ; np:hasAssertion g13b:assertion ;
            np:hasProvenance g13b:provenance ; np:hasPublicationInfo g13b:pubinfo . }
g13b:assertion {
  g13b:hif a biolink:Association ;
      biolink:subject CHEBI:15846 ; biolink:subject_aspect_qualifier "abundance" ;
      biolink:subject_direction_qualifier "decreased" ;             # (Biolink has subject_direction_qualifier too)
      biolink:predicate biolink:affects ; biolink:qualified_predicate biolink:causes ;
      biolink:object UniProtKB:Q61221 ;                             # mouse HIF-1-alpha
      biolink:object_aspect_qualifier "abundance" ; biolink:object_direction_qualifier "increased" ;
      bl:subcellularContextOfSubject GO:0005634 ;                   # nucleus
      bl:oxygenCondition bl:Normoxia ;
      bl:independentOf bl:PGC1alphaBeta ;                           # "PGC-1a/b-independent": a negative claim
      biolink:species_context_qualifier NCBITaxon:10090 ; biolink:knowledge_level "observation" .
  g13b:effect a biolink:Association ;
      biolink:subject UniProtKB:Q61221 ; biolink:predicate biolink:affects ; biolink:qualified_predicate biolink:causes ;
      biolink:object bl:MitochondriallyEncodedOXPHOSSubunit ;
      biolink:object_aspect_qualifier "abundance" ; biolink:object_direction_qualifier "decreased" ;
      biolink:species_context_qualifier NCBITaxon:10090 .
}
g13b:provenance {
  g13b:assertion a SEPIO:0000173 ; prov:wasDerivedFrom pubmed:24360282 ;
      SEPIO:0000006 [ a SEPIO:0000002 ; SEPIO:0000183 SEPIO:0000403 ; dct:type ECO:0006186 ] .  # combinatorial experimental and author inference ... single publication
}
g13b:pubinfo { bnp:RAgomes2013b dct:created "2026-10-26T00:00:00Z"^^xsd:dateTime ; dct:creator bl:BioLeanCurator . }

# --- c: SIRT1 deletion accelerates the decline -----------------------------------------------------
g13c:Head { bnp:RAgomes2013c a np:Nanopublication ; np:hasAssertion g13c:assertion ;
            np:hasProvenance g13c:provenance ; np:hasPublicationInfo g13c:pubinfo . }
g13c:assertion {
  g13c:ko a biolink:Association ;
      biolink:subject UniProtKB:Q923E4 ; biolink:subject_form_or_variant_qualifier "loss_of_function_variant_form" ;
      biolink:predicate biolink:affects ; biolink:qualified_predicate biolink:causes ;
      biolink:object bl:MitochondriallyEncodedOXPHOSSubunit ;
      biolink:object_aspect_qualifier "abundance" ; biolink:object_direction_qualifier "decreased" ;
      bl:rateModifier bl:Accelerates ;                              # faster age-dependent decline
      biolink:species_context_qualifier NCBITaxon:10090 ; biolink:knowledge_level "observation" .
}
g13c:provenance {
  g13c:assertion a SEPIO:0000173 ; prov:wasDerivedFrom pubmed:24360282 ;
      SEPIO:0000006 [ a SEPIO:0000002 ; SEPIO:0000183 SEPIO:0000403 ; dct:type ECO:0001091 ] .   # knockout phenotypic evidence
}
g13c:pubinfo { bnp:RAgomes2013c dct:created "2026-10-26T00:00:00Z"^^xsd:dateTime ; dct:creator bl:BioLeanCurator . }

# --- d: raising NAD+ in old mice restores mitochondrial function to young levels, SIRT1-dependent ---
g13d:Head { bnp:RAgomes2013d a np:Nanopublication ; np:hasAssertion g13d:assertion ;
            np:hasProvenance g13d:provenance ; np:hasPublicationInfo g13d:pubinfo . }
g13d:assertion {
  g13d:rescue a biolink:Association ;
      biolink:subject CHEBI:15846 ; biolink:subject_aspect_qualifier "abundance" ;
      biolink:subject_direction_qualifier "increased" ;             # intervention = raised NAD+ (agent unnamed)
      biolink:predicate biolink:ameliorates_condition ;
      biolink:object MP:0006036 ;                                   # abnormal mitochondrial physiology
      biolink:stage_qualifier PATO:0000308 ;                        # old
      bl:restoredTo bl:YoungMouseLevel ;
      bl:dependsOn UniProtKB:Q923E4 ;
      biolink:species_context_qualifier NCBITaxon:10090 ; biolink:knowledge_level "observation" .
}
g13d:provenance {
  g13d:assertion a SEPIO:0000173 ; prov:wasDerivedFrom pubmed:24360282 ;
      SEPIO:0000006 [ a SEPIO:0000002 ; SEPIO:0000183 SEPIO:0000403 ; dct:type ECO:0000059 ] .
}
g13d:pubinfo { bnp:RAgomes2013d dct:created "2026-10-26T00:00:00Z"^^xsd:dateTime ; dct:creator bl:BioLeanCurator . }

# --- e: the authors' model: pseudohypoxia contributes to age-related mitochondrial decline, reversibly -
g13e:Head { bnp:RAgomes2013e a np:Nanopublication ; np:hasAssertion g13e:assertion ;
            np:hasProvenance g13e:provenance ; np:hasPublicationInfo g13e:pubinfo . }
g13e:assertion {
  bl:Pseudohypoxia biolink:contributes_to MP:0006036 .
  bl:Pseudohypoxia rdfs:subClassOf GO:0071456 .                     # framed as an inappropriate cellular response to hypoxia
  bl:Pseudohypoxia bl:reversible true .
}
g13e:provenance {
  g13e:assertion a SEPIO:0000001 ; prov:wasDerivedFrom pubmed:24360282 , bnp:RAgomes2013a , bnp:RAgomes2013b , bnp:RAgomes2013d ;
      SEPIO:0000006 [ a SEPIO:0000002 ; SEPIO:0000183 SEPIO:0000403 ; dct:type ECO:0006185 ;   # author inference
                      SEPIO:0000084 g13a:assertion , g13b:assertion , g13d:assertion ] ;
      bl:hedge "apparently reversible" .
}
g13e:pubinfo { bnp:RAgomes2013e dct:created "2026-10-26T00:00:00Z"^^xsd:dateTime ; dct:creator bl:BioLeanCurator . }
```

Could not express:
- Tissue: the abstract names none, so the assertion has no anatomical context (that is honest, but means
  these claims silently read as "mouse, whole organism").
- "Restores to that of a young mouse" is a comparison to a third group. Biolink direction cannot point at
  a reference level; local `bl:restoredTo`.
- "PGC-1a/b-independent" is a negative mechanistic claim. `biolink:negated` negates a whole edge, not one
  mediator inside it.
- The intervention is "raised NAD+", i.e. a state, not a substance. Biolink's
  `subject_aspect_qualifier` + `subject_direction_qualifier` handle it, but an `ameliorates_condition`
  edge with a state as subject is off-label.
- "Hedges" ("apparently reversible", "contributes to") have no SEPIO or ECO slot; a free-text comment.

### Mills 2016, Cell Metab. PMID 28068222 (real abstract)

Six nanopubs. The abstract gives strain, diet, duration and route, so this is the richest context.
One shared study node carries them; each finding points at it.

```trig
@prefix mi16:  <https://w3id.org/biolean/np/RAmills2016study#> .
@prefix mi16a: <https://w3id.org/biolean/np/RAmills2016a#> .
@prefix mi16b: <https://w3id.org/biolean/np/RAmills2016b#> .
@prefix mi16c: <https://w3id.org/biolean/np/RAmills2016c#> .
@prefix mi16d: <https://w3id.org/biolean/np/RAmills2016d#> .
@prefix mi16e: <https://w3id.org/biolean/np/RAmills2016e#> .

# --- study nanopub: the design, so findings can cite it (nanopubs referencing nanopubs) -------------
mi16:Head { bnp:RAmills2016study a np:Nanopublication ; np:hasAssertion mi16:assertion ;
            np:hasProvenance mi16:provenance ; np:hasPublicationInfo mi16:pubinfo . }
mi16:assertion {
  mi16:study a SEPIO:0000125 ; dct:type OBI:0001199 ;                # research study; in vivo design
      bl:organism NCBITaxon:10090 ;
      bl:strain ?:unverified ;                                        # C57BL/6N: not in EFO (only C57BL/6NJ, EFO:0007732); MGI strain ID not checked
      bl:strainLabel "C57BL/6N" ;
      bl:genotype bl:WildType ;
      bl:diet bl:RegularChow ;
      bl:intervention CHEBI:16171 ;
      bl:route OBI:0000952 ;                                          # oral administration
      bl:duration "P12M"^^xsd:duration ;                              # 12 months
      bl:ageWindow bl:NormalAgeing .
}
mi16:provenance { mi16:assertion prov:wasDerivedFrom pubmed:28068222 . }
mi16:pubinfo { bnp:RAmills2016study dct:created "2026-10-26T00:00:00Z"^^xsd:dateTime ; dct:creator bl:BioLeanCurator . }

# --- a: oral NMN is rapidly converted to tissue NAD+ -------------------------------------------------
mi16a:Head { bnp:RAmills2016a a np:Nanopublication ; np:hasAssertion mi16a:assertion ;
             np:hasProvenance mi16a:provenance ; np:hasPublicationInfo mi16a:pubinfo . }
mi16a:assertion {
  mi16a:f a biolink:Association ;
      biolink:subject CHEBI:16171 ; biolink:predicate biolink:affects ; biolink:qualified_predicate biolink:causes ;
      biolink:object CHEBI:15846 ; biolink:object_aspect_qualifier "abundance" ;
      biolink:object_direction_qualifier "increased" ;
      biolink:species_context_qualifier NCBITaxon:10090 ; bl:kinetics bl:Rapid ;
      biolink:supporting_study_context mi16:study ; biolink:knowledge_level "observation" .
}
mi16a:provenance { mi16a:assertion a SEPIO:0000173 ; prov:wasDerivedFrom pubmed:28068222 , bnp:RAmills2016study ;
      SEPIO:0000006 [ a SEPIO:0000002 ; SEPIO:0000183 SEPIO:0000403 ; dct:type ECO:0000002 ] . }
mi16a:pubinfo { bnp:RAmills2016a dct:created "2026-10-26T00:00:00Z"^^xsd:dateTime ; dct:creator bl:BioLeanCurator . }

# --- b: NMN suppresses age-associated body-weight gain ----------------------------------------------
mi16b:Head { bnp:RAmills2016b a np:Nanopublication ; np:hasAssertion mi16b:assertion ;
             np:hasProvenance mi16b:provenance ; np:hasPublicationInfo mi16b:pubinfo . }
mi16b:assertion {
  mi16b:f a biolink:Association ;
      biolink:subject CHEBI:16171 ; biolink:predicate biolink:ameliorates_condition ;
      biolink:object MP:0001260 ;                                     # increased body weight
      bl:conditionCause bl:Ageing ;
      biolink:species_context_qualifier NCBITaxon:10090 ;
      biolink:supporting_study_context mi16:study ; biolink:knowledge_level "observation" .
}
mi16b:provenance { mi16b:assertion a SEPIO:0000173 ; prov:wasDerivedFrom pubmed:28068222 , bnp:RAmills2016study ;
      SEPIO:0000006 [ a SEPIO:0000002 ; SEPIO:0000183 SEPIO:0000403 ; dct:type ECO:0000059 ] . }
mi16b:pubinfo { bnp:RAmills2016b dct:created "2026-10-26T00:00:00Z"^^xsd:dateTime ; dct:creator bl:BioLeanCurator . }

# --- c: NMN raises energy metabolism, physical activity, insulin sensitivity; improves lipids ----------
mi16c:Head { bnp:RAmills2016c a np:Nanopublication ; np:hasAssertion mi16c:assertion ;
             np:hasProvenance mi16c:provenance ; np:hasPublicationInfo mi16c:pubinfo . }
mi16c:assertion {
  mi16c:energy a biolink:Association ; biolink:subject CHEBI:16171 ;
      biolink:predicate biolink:ameliorates_condition ; biolink:object MP:0004890 ;   # decreased energy expenditure
      biolink:species_context_qualifier NCBITaxon:10090 ; biolink:supporting_study_context mi16:study .
  mi16c:activity a biolink:Association ; biolink:subject CHEBI:16171 ;
      biolink:predicate biolink:ameliorates_condition ; biolink:object MP:0031392 ;   # hypoactivity
      biolink:species_context_qualifier NCBITaxon:10090 ; biolink:supporting_study_context mi16:study .
  mi16c:insulin a biolink:Association ; biolink:subject CHEBI:16171 ;
      biolink:predicate biolink:ameliorates_condition ; biolink:object MP:0005331 ;   # insulin resistance
      biolink:species_context_qualifier NCBITaxon:10090 ; biolink:supporting_study_context mi16:study .
  mi16c:lipid a biolink:Association ; biolink:subject CHEBI:16171 ;
      biolink:predicate biolink:affects ; biolink:object GO:0055088 ;                 # lipid homeostasis, "plasma lipid profile"
      biolink:object_direction_qualifier "increased" ;
      biolink:anatomical_context_qualifier UBERON:0001969 ;                           # blood plasma
      biolink:species_context_qualifier NCBITaxon:10090 ; biolink:supporting_study_context mi16:study .
}
mi16c:provenance { mi16c:assertion a SEPIO:0000173 ; prov:wasDerivedFrom pubmed:28068222 , bnp:RAmills2016study ;
      SEPIO:0000006 [ a SEPIO:0000002 ; SEPIO:0000183 SEPIO:0000403 ; dct:type ECO:0000059 ] . }
mi16c:pubinfo { bnp:RAmills2016c dct:created "2026-10-26T00:00:00Z"^^xsd:dateTime ; dct:creator bl:BioLeanCurator . }

# --- d: eye function, skeletal-muscle mitochondria, gene expression ------------------------------------
mi16d:Head { bnp:RAmills2016d a np:Nanopublication ; np:hasAssertion mi16d:assertion ;
             np:hasProvenance mi16d:provenance ; np:hasPublicationInfo mi16d:pubinfo . }
mi16d:assertion {
  mi16d:eye a biolink:Association ; biolink:subject CHEBI:16171 ;
      biolink:predicate biolink:ameliorates_condition ; biolink:object MP:0002090 ;   # abnormal vision ("eye function", unspecific)
      biolink:anatomical_context_qualifier UBERON:0000970 ;                           # eye
      biolink:species_context_qualifier NCBITaxon:10090 ; biolink:supporting_study_context mi16:study .
  mi16d:mito a biolink:Association ; biolink:subject CHEBI:16171 ;
      biolink:predicate biolink:affects ; biolink:qualified_predicate biolink:causes ;
      biolink:object GO:0006119 ; biolink:object_direction_qualifier "increased" ;   # oxidative phosphorylation
      biolink:anatomical_context_qualifier UBERON:0001134 ;                           # skeletal muscle tissue
      biolink:species_context_qualifier NCBITaxon:10090 ; biolink:supporting_study_context mi16:study .
  mi16d:expr a biolink:Association ; biolink:subject CHEBI:16171 ;
      biolink:predicate biolink:affects ; biolink:object bl:AgeAssociatedTranscriptomeChange ;
      bl:effect bl:Prevented ;
      biolink:anatomical_context_qualifier bl:KeyMetabolicOrgans ;
      biolink:species_context_qualifier NCBITaxon:10090 ; biolink:supporting_study_context mi16:study .
}
mi16d:provenance { mi16d:assertion a SEPIO:0000173 ; prov:wasDerivedFrom pubmed:28068222 , bnp:RAmills2016study ;
      SEPIO:0000006 [ a SEPIO:0000002 ; SEPIO:0000183 SEPIO:0000403 ; dct:type ECO:0000059 ] ,
                    [ a SEPIO:0000002 ; SEPIO:0000183 SEPIO:0000403 ; dct:type ECO:0000104 ] . }  # DNA to cDNA expression microarray evidence (assay type assumed)
mi16d:pubinfo { bnp:RAmills2016d dct:created "2026-10-26T00:00:00Z"^^xsd:dateTime ; dct:creator bl:BioLeanCurator . }

# --- e: negative result, no obvious toxicity -----------------------------------------------------------
mi16e:Head { bnp:RAmills2016e a np:Nanopublication ; np:hasAssertion mi16e:assertion ;
             np:hasProvenance mi16e:provenance ; np:hasPublicationInfo mi16e:pubinfo . }
mi16e:assertion {
  mi16e:f a biolink:Association ;
      biolink:subject CHEBI:16171 ; biolink:predicate biolink:causes ;
      biolink:object bl:AnyToxicOrDeleteriousEffect ;
      biolink:negated true ;
      bl:hedge "without any obvious toxicity" ;
      biolink:species_context_qualifier NCBITaxon:10090 ; biolink:supporting_study_context mi16:study .
}
mi16e:provenance { mi16e:assertion a SEPIO:0000173 ; prov:wasDerivedFrom pubmed:28068222 , bnp:RAmills2016study ;
      SEPIO:0000006 [ a SEPIO:0000002 ; SEPIO:0000183 SEPIO:0000403 ; dct:type ECO:0000059 ] . }
mi16e:pubinfo { bnp:RAmills2016e dct:created "2026-10-26T00:00:00Z"^^xsd:dateTime ; dct:creator bl:BioLeanCurator . }
```

Could not express:
- The strain: no OLS-resolvable C57BL/6N ID (EFO only has C57BL/6NJ, a different substrain). This is the
  kind of detail that matters for NMN reproducibility and the stack has no good home for it.
- "Prevented" age-associated changes is a counterfactual against untreated age-matched mice. Direction
  qualifiers cannot express "kept at baseline".
- "Mitonuclear protein imbalance" was "enhanced" per the abstract wording (likely meaning ameliorated);
  ambiguous text, not annotated.
- The no-toxicity claim is an absence-of-observation over an unbounded class. `negated` plus a
  local catch-all class is the only route and it is close to meaningless.
- Dose (mg/kg/day) is not in the abstract, and Biolink has no dose qualifier anyway; it would go in the
  study node as a local property.
- `biolink:supporting_study_context` is meant to point at a Biolink StudyContext; pointing it at a SEPIO
  research study in another nanopub is a mix of two models.

### Das 2018, Cell. PMID 29570999 (real abstract)

Five nanopubs: endothelial SIRT1 as mediator of myocyte signals; NMN -> capillary density (SIRT1-
dependent); NMN -> blood flow and endurance in old mice; synergy with exercise / H2S; H2S -> endothelial NAD+.

```trig
@prefix d18a: <https://w3id.org/biolean/np/RAdas2018a#> .
@prefix d18b: <https://w3id.org/biolean/np/RAdas2018b#> .
@prefix d18c: <https://w3id.org/biolean/np/RAdas2018c#> .
@prefix d18d: <https://w3id.org/biolean/np/RAdas2018d#> .
@prefix d18e: <https://w3id.org/biolean/np/RAdas2018e#> .

# --- a: endothelial SIRT1 mediates pro-angiogenic signals from myocytes ------------------------------
d18a:Head { bnp:RAdas2018a a np:Nanopublication ; np:hasAssertion d18a:assertion ;
            np:hasProvenance d18a:provenance ; np:hasPublicationInfo d18a:pubinfo . }
d18a:assertion {
  d18a:f a biolink:Association ;
      biolink:subject UniProtKB:Q923E4 ;                              # mouse Sirt1
      biolink:predicate RO:0002213 ;                                   # positively regulates
      biolink:object GO:0001525 ;                                      # angiogenesis
      biolink:anatomical_context_qualifier CL:0000115 ;                # endothelial cell (where SIRT1 acts)
      bl:signalSourceCell CL:0008002 ;                                 # skeletal muscle fiber ("myocytes"; exact cell type assumed)
      bl:role bl:Mediator ;
      biolink:species_context_qualifier NCBITaxon:10090 ; biolink:knowledge_level "observation" .
}
d18a:provenance { d18a:assertion a SEPIO:0000173 ; prov:wasDerivedFrom pubmed:29570999 ;
      SEPIO:0000006 [ a SEPIO:0000002 ; SEPIO:0000183 SEPIO:0000403 ; dct:type ECO:0001030 ] . }   # conditional knockout evidence (endothelial KO assumed from "SIRT1 in endothelial cells")
d18a:pubinfo { bnp:RAdas2018a dct:created "2026-10-26T00:00:00Z"^^xsd:dateTime ; dct:creator bl:BioLeanCurator . }

# --- b: NMN increases capillary density, SIRT1-dependently -------------------------------------------
d18b:Head { bnp:RAdas2018b a np:Nanopublication ; np:hasAssertion d18b:assertion ;
            np:hasProvenance d18b:provenance ; np:hasPublicationInfo d18b:pubinfo . }
d18b:assertion {
  d18b:f a biolink:Association ;
      biolink:subject CHEBI:16171 ; biolink:predicate biolink:ameliorates_condition ;
      biolink:object MP:0020329 ;                                      # decreased capillary density
      biolink:anatomical_context_qualifier UBERON:0001982 ;            # capillary
      biolink:stage_qualifier PATO:0000308 ;                           # old ("elderly mice")
      bl:dependsOn UniProtKB:Q923E4 ;
      biolink:species_context_qualifier NCBITaxon:10090 ; biolink:knowledge_level "observation" .
}
d18b:provenance { d18b:assertion a SEPIO:0000173 ; prov:wasDerivedFrom pubmed:29570999 ;
      prov:wasGeneratedBy [ a SEPIO:0000125 ; dct:type OBI:0001199 ] ;
      SEPIO:0000006 [ a SEPIO:0000002 ; SEPIO:0000183 SEPIO:0000403 ; dct:type ECO:0000059 ] . }
d18b:pubinfo { bnp:RAdas2018b dct:created "2026-10-26T00:00:00Z"^^xsd:dateTime ; dct:creator bl:BioLeanCurator . }

# --- c: NMN improves blood flow and endurance in old mice (via b) -------------------------------------
d18c:Head { bnp:RAdas2018c a np:Nanopublication ; np:hasAssertion d18c:assertion ;
            np:hasProvenance d18c:provenance ; np:hasPublicationInfo d18c:pubinfo . }
d18c:assertion {
  d18c:flow a biolink:Association ;
      biolink:subject CHEBI:16171 ; biolink:predicate biolink:affects ; biolink:qualified_predicate biolink:causes ;
      biolink:object GO:0008015 ; biolink:object_direction_qualifier "increased" ;   # blood circulation
      biolink:stage_qualifier PATO:0000308 ; biolink:species_context_qualifier NCBITaxon:10090 .
  d18c:endurance a biolink:Association ;
      biolink:subject CHEBI:16171 ; biolink:predicate biolink:ameliorates_condition ;
      biolink:object MP:0012106 ;                                       # impaired exercise endurance
      biolink:stage_qualifier PATO:0000308 ; biolink:species_context_qualifier NCBITaxon:10090 .
  d18c:flow bl:explainedBy d18b:f . d18c:endurance bl:explainedBy d18b:f .
}
d18c:provenance { d18c:assertion a SEPIO:0000173 ; prov:wasDerivedFrom pubmed:29570999 ;
      SEPIO:0000006 [ a SEPIO:0000002 ; SEPIO:0000183 SEPIO:0000403 ; dct:type ECO:0000059 ] . }
d18c:pubinfo { bnp:RAdas2018c dct:created "2026-10-26T00:00:00Z"^^xsd:dateTime ; dct:creator bl:BioLeanCurator . }

# --- d: the effect is augmented by exercise or by raising H2S ------------------------------------------
d18d:Head { bnp:RAdas2018d a np:Nanopublication ; np:hasAssertion d18d:assertion ;
            np:hasProvenance d18d:provenance ; np:hasPublicationInfo d18d:pubinfo . }
d18d:assertion {
  d18d:ex  a biolink:Association ; biolink:subject bl:Exercise ;   # no clean exposure class found (GO:0014823 "response to activity" is the organism's response, not the exposure)
      biolink:predicate bl:augmentsEffectOf ; biolink:object d18b:f ;
      biolink:species_context_qualifier NCBITaxon:10090 .
  d18d:h2s a biolink:Association ; biolink:subject CHEBI:16136 ;    # hydrogen sulfide
      biolink:subject_aspect_qualifier "abundance" ; biolink:subject_direction_qualifier "increased" ;
      biolink:predicate bl:augmentsEffectOf ; biolink:object d18b:f ;
      biolink:species_context_qualifier NCBITaxon:10090 .
  CHEBI:16136 RO:0000087 bl:DietaryRestrictionMimetic .            # "a DR mimetic": role not in CHEBI
}
d18d:provenance { d18d:assertion a SEPIO:0000173 ; prov:wasDerivedFrom pubmed:29570999 ;
      SEPIO:0000006 [ a SEPIO:0000002 ; SEPIO:0000183 SEPIO:0000403 ; dct:type ECO:0000059 ] . }
d18d:pubinfo { bnp:RAdas2018d dct:created "2026-10-26T00:00:00Z"^^xsd:dateTime ; dct:creator bl:BioLeanCurator . }

# --- e: H2S regulates endothelial NAD+ ----------------------------------------------------------------
d18e:Head { bnp:RAdas2018e a np:Nanopublication ; np:hasAssertion d18e:assertion ;
            np:hasProvenance d18e:provenance ; np:hasPublicationInfo d18e:pubinfo . }
d18e:assertion {
  d18e:f a biolink:Association ;
      biolink:subject CHEBI:16136 ; biolink:predicate biolink:regulates ;
      biolink:object CHEBI:15846 ; biolink:object_aspect_qualifier "abundance" ;   # direction not stated in abstract
      biolink:anatomical_context_qualifier CL:0000115 ;
      biolink:species_context_qualifier NCBITaxon:10090 .
}
d18e:provenance { d18e:assertion a SEPIO:0000173 ; prov:wasDerivedFrom pubmed:29570999 ;
      SEPIO:0000006 [ a SEPIO:0000002 ; SEPIO:0000183 SEPIO:0000403 ; dct:type ECO:0000059 ] ;
      bl:note "abstract states it as background ('a regulator of endothelial NAD+ levels'); may not be this paper's own finding" . }
d18e:pubinfo { bnp:RAdas2018e dct:created "2026-10-26T00:00:00Z"^^xsd:dateTime ; dct:creator bl:BioLeanCurator . }
```

Could not express:
- Synergy ("augmented by exercise") is an interaction between two interventions. No Biolink or RO
  predicate for "potentiates the effect of"; the object of the local predicate is another association.
- Cell-to-cell signalling (myocyte secretes, endothelium responds) needs two cell contexts on one edge.
  Biolink offers one anatomical context; the source cell is local.
- "Implications for human performance" (the abstract's cross-species leap) can be written as a hypothesis
  nanopub with `NCBITaxon:9606`, but nothing links it formally to the mouse evidence as an *extrapolation*.
  Left out rather than faked.
- Age of "elderly" mice: only PATO "old", no months.
- Whether a sentence is this paper's result or cited background (the H2S/NAD+ claim) is not
  distinguishable from the abstract; the formalism needs that decided up front.

### Yoshino 2021, Science. PMID 33888596 (real abstract; human RCT)

Four nanopubs: the trial design; the primary result (muscle insulin sensitivity up, placebo unchanged);
signalling and remodelling; then a cross-species curation nanopub that pools mouse and human evidence for
"NMN improves insulin sensitivity", which is where translation shows up in this formalism.

```trig
@prefix y21:  <https://w3id.org/biolean/np/RAyoshino2021trial#> .
@prefix y21a: <https://w3id.org/biolean/np/RAyoshino2021a#> .
@prefix y21b: <https://w3id.org/biolean/np/RAyoshino2021b#> .
@prefix xsp:  <https://w3id.org/biolean/np/RAcrossSpeciesInsulin#> .

# --- trial nanopub -------------------------------------------------------------------------------------
y21:Head { bnp:RAyoshino2021trial a np:Nanopublication ; np:hasAssertion y21:assertion ;
           np:hasProvenance y21:provenance ; np:hasPublicationInfo y21:pubinfo . }
y21:assertion {
  y21:trial a SEPIO:0000125 , NCIT:C46079 , NCIT:C15228 ;          # research study; randomized controlled clinical trial; double blind study
      dct:identifier "NCT03151239" ;
      bl:organism NCBITaxon:9606 ;
      bl:sex PATO:0000383 ;                                            # female
      bl:reproductiveStage EFO:0002721 ;                               # postmenopausal
      bl:inclusionCondition MONDO:0006920 , HP:0025502 , HP:0001513 ;  # prediabetes syndrome; overweight OR obesity
      bl:intervention CHEBI:16171 ; bl:comparator OBI:0000169 ;        # placebo role
      bl:duration "P10W"^^xsd:duration .
}
y21:provenance { y21:assertion prov:wasDerivedFrom pubmed:33888596 . }
y21:pubinfo { bnp:RAyoshino2021trial dct:created "2026-10-26T00:00:00Z"^^xsd:dateTime ; dct:creator bl:BioLeanCurator . }

# --- a: NMN increases insulin-stimulated glucose disposal (muscle insulin sensitivity); placebo does not ---
y21a:Head { bnp:RAyoshino2021a a np:Nanopublication ; np:hasAssertion y21a:assertion ;
            np:hasProvenance y21a:provenance ; np:hasPublicationInfo y21a:pubinfo . }
y21a:assertion {
  y21a:nmn a biolink:Association ;
      biolink:subject CHEBI:16171 ; biolink:predicate biolink:affects ; biolink:qualified_predicate biolink:causes ;
      biolink:object GO:0032869 ;                                       # cellular response to insulin stimulus
      biolink:object_direction_qualifier "increased" ;
      biolink:anatomical_context_qualifier UBERON:0001134 ;             # skeletal muscle tissue
      biolink:species_context_qualifier NCBITaxon:9606 ;
      biolink:sex_qualifier PATO:0000383 ;
      biolink:disease_context_qualifier MONDO:0006920 ;
      biolink:supporting_study_context y21:trial ;
      bl:measuredAs "insulin-stimulated glucose disposal, hyperinsulinemic-euglycemic clamp" ;   # no OBI/NCIT term found for the clamp
      biolink:knowledge_level "observation" .
  y21a:placebo a biolink:Association ;                                  # the control arm, as a negative edge
      biolink:subject bl:Placebo ; biolink:predicate biolink:affects ; biolink:object GO:0032869 ;
      biolink:negated true ; biolink:species_context_qualifier NCBITaxon:9606 ;
      biolink:supporting_study_context y21:trial .
}
y21a:provenance { y21a:assertion a SEPIO:0000173 ; prov:wasDerivedFrom pubmed:33888596 , bnp:RAyoshino2021trial ;
      SEPIO:0000006 [ a SEPIO:0000002 ; SEPIO:0000183 SEPIO:0000403 ; dct:type ECO:0007121 ] . }   # clinical study evidence used in manual assertion
y21a:pubinfo { bnp:RAyoshino2021a dct:created "2026-10-26T00:00:00Z"^^xsd:dateTime ; dct:creator bl:BioLeanCurator . }

# --- b: muscle insulin signalling (p-AKT, p-mTOR) up; PDGFRB and remodelling genes up ------------------
y21b:Head { bnp:RAyoshino2021b a np:Nanopublication ; np:hasAssertion y21b:assertion ;
            np:hasProvenance y21b:provenance ; np:hasPublicationInfo y21b:pubinfo . }
y21b:assertion {
  y21b:akt a biolink:ChemicalAffectsGeneAssociation ;
      biolink:subject CHEBI:16171 ; biolink:predicate biolink:affects ; biolink:qualified_predicate biolink:causes ;
      biolink:object UniProtKB:P31749 ;                                 # AKT1 (abstract says "AKT", isoform unspecified)
      biolink:object_aspect_qualifier "phosphorylation" ; biolink:object_direction_qualifier "increased" ;
      biolink:anatomical_context_qualifier UBERON:0001134 ; biolink:species_context_qualifier NCBITaxon:9606 ;
      biolink:supporting_study_context y21:trial .
  y21b:mtor a biolink:ChemicalAffectsGeneAssociation ;
      biolink:subject CHEBI:16171 ; biolink:predicate biolink:affects ; biolink:qualified_predicate biolink:causes ;
      biolink:object UniProtKB:P42345 ;                                 # MTOR
      biolink:object_aspect_qualifier "phosphorylation" ; biolink:object_direction_qualifier "increased" ;
      biolink:anatomical_context_qualifier UBERON:0001134 ; biolink:species_context_qualifier NCBITaxon:9606 ;
      biolink:supporting_study_context y21:trial .
  y21b:pdgfrb a biolink:ChemicalAffectsGeneAssociation ;
      biolink:subject CHEBI:16171 ; biolink:predicate biolink:affects ; biolink:qualified_predicate biolink:causes ;
      biolink:object UniProtKB:P09619 ;                                 # PDGFRB
      biolink:object_aspect_qualifier "expression" ; biolink:object_direction_qualifier "increased" ;
      biolink:anatomical_context_qualifier UBERON:0001134 ; biolink:species_context_qualifier NCBITaxon:9606 ;
      biolink:supporting_study_context y21:trial .
}
y21b:provenance { y21b:assertion a SEPIO:0000173 ; prov:wasDerivedFrom pubmed:33888596 , bnp:RAyoshino2021trial ;
      SEPIO:0000006 [ a SEPIO:0000002 ; SEPIO:0000183 SEPIO:0000403 ; dct:type ECO:0000112 ] ,   # qualitative western immunoblotting (assay assumed for phospho-proteins)
                    [ a SEPIO:0000002 ; SEPIO:0000183 SEPIO:0000403 ; dct:type ECO:0000295 ] . } # RNA-sequencing evidence (assay assumed)
y21b:pubinfo { bnp:RAyoshino2021b dct:created "2026-10-26T00:00:00Z"^^xsd:dateTime ; dct:creator bl:BioLeanCurator . }

# --- cross-species curation nanopub: does mouse evidence transfer to humans? ---------------------------
xsp:Head { bnp:RAcrossSpeciesInsulin a np:Nanopublication ; np:hasAssertion xsp:assertion ;
           np:hasProvenance xsp:provenance ; np:hasPublicationInfo xsp:pubinfo . }
xsp:assertion {
  xsp:claim a SEPIO:0000000 ;                                           # proposition (species-free on purpose)
      SEPIO:0000388 CHEBI:16171 ; SEPIO:0000028 biolink:affects ; SEPIO:0000027 GO:0032869 ;   # has_subject / predicate / object
      rdfs:comment "NMN increases insulin sensitivity in mammals" .
  xsp:claim SEPIO:0000007 xsp:mouseLiver , xsp:mouseAgeing , xsp:human .
  xsp:mouseLiver  a SEPIO:0000002 ; SEPIO:0000183 SEPIO:0000403 ; SEPIO:0000084 y11c:assertion ;
      dct:type ECO:0000059 ; SEPIO:0000429 "0.4"^^xsd:decimal ;
      rdfs:comment "mouse, HFD model, LIVER: different species, tissue and disease model from the human trial" .
  xsp:mouseAgeing a SEPIO:0000002 ; SEPIO:0000183 SEPIO:0000403 ; SEPIO:0000084 mi16c:assertion ;
      dct:type ECO:0000059 ; SEPIO:0000429 "0.4"^^xsd:decimal .
  xsp:human       a SEPIO:0000002 ; SEPIO:0000183 SEPIO:0000403 ; SEPIO:0000084 y21a:assertion ;
      dct:type ECO:0007121 ; SEPIO:0000429 "0.7"^^xsd:decimal ;
      rdfs:comment "human, women only, prediabetic, skeletal muscle, n small, 10 weeks" .
}
xsp:provenance { xsp:assertion prov:wasAttributedTo bl:BioLeanCurator ;
      SEPIO:0000006 [ a SEPIO:0000002 ; dct:type ECO:0000305 ] . }        # curator inference
xsp:pubinfo { bnp:RAcrossSpeciesInsulin dct:created "2026-10-26T00:00:00Z"^^xsd:dateTime ; dct:creator bl:BioLeanCurator . }
```

Could not express:
- The headline quantitative result (effect size, p-value, n) is not in the abstract; Biolink has
  `p_value` and `supporting_study_size` slots but nothing to fill them with here.
- "Increased after NMN but did not change after placebo" is a *between-arm* comparison. I had to split it
  into a positive and a negated edge; the contrast itself (the thing an RCT actually tests) is lost.
- Inclusion criteria are "prediabetes AND (overweight OR obese) AND postmenopausal AND female". RDF lists
  of objects read as AND; the OR has no home without OWL class expressions.
- Hyperinsulinemic-euglycemic clamp: not found in OBI or NCIT search. Free text.
- Cross-species transfer: SEPIO can pool mouse and human evidence lines under a species-free proposition,
  but has no notion of "this line is indirect because of species/tissue mismatch". The discount is only a
  number I made up plus a comment.

## 3. Fit table

All code blocks above, concatenated, parse as one TriG dataset with rdflib (49 nanopubs, 196 named
graphs, 1213 quads; `?:unverified` swapped for a dummy IRI only for the parse check).

| Aspect | Expressible? | How |
|---|---|---|
| direction of effect | yes | Biolink `object_direction_qualifier` / `subject_direction_qualifier` ("increased"/"decreased"); RO positively/negatively regulates for mechanism. Fails for "restored to baseline", "prevented", "improved profile". |
| quantitative result | partial | SIO ratio + `SIO:000300` has value (H+/O = 4, 6). No units model, no CI, and the meaning of the number lives in `rdfs:label`. |
| species/strain | partial | Species: `biolink:species_context_qualifier` + NCBITaxon, fine. Strain: no OLS-resolvable C57BL/6N ID; local property. Mixed-species systems (Racker) need local subject/object taxon. |
| age/stage | partial | `biolink:stage_qualifier PATO:0000308` (old). No numeric age; "ageing" as a cause is a local class. |
| tissue/cell | yes | `biolink:anatomical_context_qualifier` with UBERON / CL / GO CC. Only one context per edge, so source-cell vs target-cell signalling is local. |
| disease model | partial | `biolink:disease_context_qualifier` MONDO, but "HFD-induced" vs "age-induced" T2D needs a local `bl:modelInducedBy`. |
| dose/duration | partial | Duration as `xsd:duration` on a study node (local property). No Biolink dose qualifier; doses were not in the abstracts anyway. |
| hypothesis-vs-result | yes | The real strength. Provenance types the assertion graph: `SEPIO:0000432` hypothesis vs `SEPIO:0000173` study finding vs `SEPIO:0000001` assertion (inference); plus Biolink `knowledge_level`. "Prediction" needs a local term. |
| rival hypotheses | yes | Two hypothesis nanopubs + a curation nanopub with `SEPIO:0000101` contradicts. No verdict / accepted status. |
| evidence type | yes | ECO on each evidence line (`dct:type`), e.g. ECO:0000134 transport assay, ECO:0005543 mixed-species reconstruction, ECO:0007121 clinical study. Strength score `SEPIO:0000429` exists but has no defined scale. |
| cross-species transfer | partial | A species-free `SEPIO:0000000` proposition with mouse and human evidence lines under it. No term for "indirect because of species/tissue mismatch"; discount is a bare number. |
| negative results | partial | `biolink:negated true` (Biolink-only; a plain RDF reader sees a positive triple), or a `SEPIO:0000404` disputing line. "Not via X" (one mediator) and "no toxicity" (open class) are not expressible. |

## 4. Verdict

(a) For the chemiosmotic papers the nanopub + SEPIO stack is a genuinely good fit for the *argument*:
splitting Mitchell into link 1 and link 2, typing each graph as hypothesis or finding, and hanging
supporting and disputing evidence lines (with ECO) off each side makes the controversy explicit,
citable and machine-queryable, and immutability plus `npx:supersedes` models "state of play in 1971 vs
1974" very naturally. It is awkward for the *biology*: the central object, the proton gradient, has no
class (only processes driven by it), membrane sidedness and inverted vesicles have no terms, and the
key logical words of these papers ("sufficient", "alone", "no chemical intermediate") have no RO
predicate, so they end up as local `bl:` terms that no one else will understand. (b) For the NMN mouse
papers the Biolink association node carries species, tissue, disease model, stage and direction well,
and the nanopub's provenance graph cleanly separates in vivo / clinical / knockout evidence, but every
paper still needed local terms for ageing-as-cause, "restored to young", "prevented", "partly via SIRT1",
synergy, and strain, and the one negation hook (`biolink:negated`) is silently dangerous outside Biolink.
Bluntly: this formalism is excellent at *who claims what, on what evidence, against whom*, and mediocre
at *what exactly was measured, in what, compared with what*. It also costs roughly 15 lines of
boilerplate per claim, which is why real nanopub corpora are generated by scripts, not written by hand.
