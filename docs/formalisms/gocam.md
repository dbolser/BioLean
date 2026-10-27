# GO-CAM (plus GAF column 16) annotation of the chemiosmotic and NMN papers

## 1. The formalism

A GO-CAM model is a small OWL ABox: each **activity unit** is an individual of a GO molecular-function
class, `enabled_by` (RO:0002333) a gene product (UniProt) or a GO complex class, `part_of`
(BFO:0000050) a biological-process individual, `occurs_in` (BFO:0000066) a cellular-component (or
UBERON/CL) individual, with `has_input`/`has_output` (RO:0002233/RO:0002234) CHEBI individuals.
Activity units are chained by causal relations (`causally upstream of, positive effect` RO:0002304,
`directly positively regulates` RO:0002629, `provides input for` RO:0002413, etc.). Every edge is reified
with an OWL axiom annotation carrying `evidence` (an ECO-typed individual), `dc:source` (PMID),
contributor and date. Context lives in only three places: (i) the **model-level** `in_taxon`
(RO:0002162) and `rdfs:comment`, (ii) the **location** individuals (`occurs_in` chains to CL/UBERON),
(iii) for GAF, **column 16 annotation extensions** (`occurs_in(...)`, `has_input(...)`,
`part_of(...)`, `exists_during(...)`). Phenotypes (MP/HP), disease (MONDO), dose, duration, age, sex
and strain have **no slot**; they can only be smuggled into free-text `rdfs:comment`. Hypothesis vs
result is carried only by the ECO code (e.g. ECO:0000303 NAS vs ECO:0000314 IDA) and model state.

Prefix block assumed below (abridged):

```turtle
@prefix obo: <http://purl.obolibrary.org/obo/> .   # GO_, RO_, BFO_, ECO_, CHEBI_, NCBITaxon_, CL_, UBERON_
@prefix up:  <http://identifiers.org/uniprot/> .
@prefix lego: <http://geneontology.org/lego/> .     # lego:evidence
@prefix dc:  <http://purl.org/dc/elements/1.1/> .
@prefix :    <http://model.geneontology.org/biolean/> .
# Relation shorthands used:  enabled_by=RO:0002333  part_of=BFO:0000050  occurs_in=BFO:0000066
#   has_input=RO:0002233  has_output=RO:0002234  provides_input_for=RO:0002413
#   causally_upstream_of_pos=RO:0002304  causally_upstream_of_neg=RO:0002305  causally_upstream_of=RO:0002411
#   directly_pos_reg=RO:0002629  directly_neg_reg=RO:0002630  pos_reg=RO:0002213  neg_reg=RO:0002212
#   in_taxon=RO:0002162  is_small_molecule_inhibitor_of=RO:0012006  is_small_molecule_activator_of=RO:0012005
#   acts_upstream_of_or_within=RO:0002264  contributes_to=RO:0002326
```

All IDs were checked against OLS4 (GO, RO, ECO, CHEBI, NCBITaxon, CL, UBERON, MP, HP, MONDO, PATO,
EFO) or UniProt REST on 2026-10-26. Note: GO:0005753 / GO:0045320 (mito / chloroplast ATP synthase
complex) are **obsolete**; the generic GO:0045259 "proton-transporting ATP synthase complex" is used.

## 2. Per-paper annotations

### Mitchell 1961, PMID:13771349 (provenance: summary; hypothesis paper)

```turtle
:m13771349 a owl:Ontology ;
    obo:RO_0002162  obo:NCBITaxon_10116 ;           # in_taxon: none really; generic mitochondrion. Rat chosen arbitrarily.
    lego:modelstate "development" ;                 # only built-in hook for "not yet true"
    rdfs:comment "HYPOTHESIS (chemiosmotic). Provenance: secondary-source summary." ;
    dc:source "PMID:13771349" .

# AU1: respiratory chain electron transfer is itself proton-translocating (vectorial)
:au1 a obo:GO_0015078 ;                          # proton transmembrane transporter activity
    obo:RO_0002333 obo:GO_0045271 ;              # enabled_by respiratory chain complex I (class as stand-in)
    obo:BFO_0000050 :bp1 ;                       # part_of
    obo:BFO_0000066 :cc1 ;                       # occurs_in
    obo:RO_0002233 obo:CHEBI_15378 ;             # has_input hydron (matrix side - side not expressible)
    obo:RO_0002413 :au2 .                        # provides_input_for ATP synthase
:bp1 a obo:GO_0006119 .                          # oxidative phosphorylation
:cc1 a obo:GO_0005743 .                          # mitochondrial inner membrane

# AU2: reversible membrane ATPase uses the gradient to make ATP
:au2 a obo:GO_0046933 ;                          # proton-transporting ATP synthase activity, rotational mechanism (anachronistic: rotation is 1990s)
    obo:RO_0002333 obo:GO_0045259 ;              # enabled_by proton-transporting ATP synthase complex
    obo:BFO_0000050 :bp2 ;
    obo:BFO_0000066 :cc1 ;
    obo:RO_0002233 obo:CHEBI_456216 , obo:CHEBI_43474 , obo:CHEBI_15378 ;   # ADP, Pi, H+
    obo:RO_0002234 obo:CHEBI_30616 .             # has_output ATP
:bp2 a obo:GO_0015986 .                          # proton motive force-driven ATP synthesis

# AU3: same claim for photosynthetic phosphorylation
:au3 a obo:GO_0046933 ; obo:BFO_0000050 [ a obo:GO_0009777 ] ;   # photosynthetic phosphorylation
    obo:BFO_0000066 [ a obo:GO_0042651 ] .                          # thylakoid membrane

# Evidence (axiom annotation on each edge above)
[] a owl:Axiom ; owl:annotatedSource :au1 ; owl:annotatedProperty obo:RO_0002413 ; owl:annotatedTarget :au2 ;
   lego:evidence [ a obo:ECO_0000303 ; dc:source "PMID:13771349" ] .   # author statement w/o traceable support (NAS)

# Prediction: uncouplers act by making membrane H+-permeable  (stated as if a fact)
[] a owl:Axiom ; owl:annotatedSource obo:CHEBI_42017 ;       # 2,4-dinitrophenol
   owl:annotatedProperty obo:RO_0012006 ;                     # is_small_molecule_inhibitor_of
   owl:annotatedTarget :au2 ; lego:evidence [ a obo:ECO_0000303 ; dc:source "PMID:13771349" ] .
```

GAF equivalent (one line, column 16 extension):

```
UniProtKB  ?:unverified  -  involved_in  GO:0015986  PMID:13771349  NAS  -  P  ...  occurs_in(GO:0005743),has_input(CHEBI:15378)
```
(GAF needs a gene product in col 2; Mitchell names none, so col 2 is literally unfillable.)

Could not express:
- That the whole model is a **hypothesis/proposal**; NAS + modelstate "development" is a hack, not semantics.
- The **anisotropy/vectorial sidedness** (matrix vs intermembrane space); has_input CHEBI:15378 has no side.
- The proton **electrochemical gradient** as an entity (no CHEBI/GO class for "delta-p"; GO:0015985 is a process).
- The **prediction** structure ("if true, membrane must be ion-impermeable"); a predicted observation is not an activity.
- That it is a **rival** to Slater's chemical intermediate; GO-CAM has no "contradicts"/"alternative to" between models.
- A real gene product: no enabled_by UniProt for a 1961 hypothetical mechanism; GAF col 2 cannot be filled.

### Slater 1953, PMID:13111237 (provenance: summary; rival hypothesis paper)

```turtle
:m13111237 a owl:Ontology ;
    lego:modelstate "development" ;
    rdfs:comment "HYPOTHESIS (chemical coupling, C~I). Rival to PMID:13771349. Now refuted. Provenance: summary." ;
    dc:source "PMID:13111237" .

# AU1: respiratory chain carrier forms a high-energy non-phosphorylated intermediate C~I
:au1 a obo:GO_0022904 ;                          # respiratory electron transport chain (as MF stand-in; no MF for "form C~I")
    obo:RO_0002333 ?:unverified ;                # enabled_by the "carrier C" - hypothetical, no UniProt
    obo:RO_0002234 ?:unverified ;                # has_output "C~I" - no CHEBI entity exists (it never existed)
    obo:BFO_0000066 [ a obo:GO_0005743 ] ;
    obo:BFO_0000050 [ a obo:GO_0006119 ] ;
    obo:RO_0002413 :au2 .                        # provides_input_for (via C~I)

# AU2: C~I + Pi + ADP -> ATP (substrate-level-like phosphorylation)
:au2 a obo:GO_0006754 ;                          # ATP biosynthetic process (no MF term for the hypothetical transferase)
    obo:RO_0002333 ?:unverified ;                # hypothetical enzyme
    obo:RO_0002233 ?:unverified , obo:CHEBI_43474 , obo:CHEBI_456216 ;   # C~I, Pi, ADP
    obo:RO_0002234 obo:CHEBI_30616 .             # ATP

[] a owl:Axiom ; owl:annotatedSource :au1 ; owl:annotatedProperty obo:RO_0002413 ; owl:annotatedTarget :au2 ;
   lego:evidence [ a obo:ECO_0000303 ; dc:source "PMID:13111237" ] ;
   rdfs:comment "Analogy to glycolytic substrate-level phosphorylation (GAPDH 1,3-BPG)." .
```

Could not express:
- The core entity **C~I** - GO-CAM requires a CHEBI class or gene product; a hypothesised, never-found molecule has none.
- **Rivalry** with Mitchell 1961: no inter-model "alternative to" / "contradicted by" relation.
- **Refuted status**: GO-CAM simply deletes wrong models; there is no "this was believed, then disproved" history.
- **Argument by analogy** (to glycolysis); ECO:0000250 sequence similarity is about genes, not mechanisms.
- Would be **rejected by GO-CAM QC** (Minerva/ShEx validation): enabled_by must be a gene product or complex.

### Jagendorf & Uribe 1966, PMID:5220864 (provenance: summary; experimental result)

```turtle
:m5220864 a owl:Ontology ;
    obo:RO_0002162 obo:NCBITaxon_3562 ;          # in_taxon Spinacia oleracea
    lego:modelstate "production" ;
    rdfs:comment "In vitro, isolated thylakoids, DARK. Acid-base jump pH ~4 (succinate) -> pH ~8 with ADP+Pi. ATP yield scales with size of pH jump. Supports PMID:13771349." .

# AU1: chloroplast ATP synthase makes ATP driven by an imposed pH gradient, no light, no electron transport
:au1 a obo:GO_0046933 ;                          # proton-transporting ATP synthase activity, rotational mechanism
    obo:RO_0002333 up:P00825 ;                   # enabled_by ATPB_SPIOL (catalytic beta subunit as representative)
    obo:BFO_0000066 :cc ;                        # occurs_in
    obo:BFO_0000050 :bp ;                        # part_of
    obo:RO_0002233 obo:CHEBI_15378 , obo:CHEBI_456216 , obo:CHEBI_43474 ;   # H+, ADP, Pi
    obo:RO_0002234 obo:CHEBI_30616 .             # ATP
:cc a obo:GO_0009535 .                           # chloroplast thylakoid membrane
:bp a obo:GO_0015986 .                           # proton motive force-driven ATP synthesis

[] a owl:Axiom ; owl:annotatedSource :au1 ; owl:annotatedProperty obo:BFO_0000050 ; owl:annotatedTarget :bp ;
   lego:evidence [ a obo:ECO_0000314 ;           # direct assay evidence (IDA)
                   dc:source "PMID:5220864" ; rdfs:comment "pH 4->8 jump in the dark; ATP measured" ] .

# AU2: succinate as the permeant acid loading the lumen (has_input of the transport, not a regulator)
:au1 obo:RO_0002233 obo:CHEBI_30031 .            # succinate(2-) - stretching has_input; really a buffer
```

GAF col 16 (classic form):

```
UniProtKB  P00825  atpB  -  involved_in  GO:0015986  PMID:5220864  IDA  -  P  ...  taxon:3562  ...  occurs_in(GO:0009535),has_input(CHEBI:15378)
```

Could not express:
- The **experimental manipulation** (imposed pH jump 4 -> 8, darkness); GO-CAM records the activity, not the perturbation.
- The **dose-response** (ATP yield vs size of pH jump; acid identity matters) - no quantity slot.
- **"Sufficiency"**: the key logical point is that a pH gradient *alone* suffices, i.e. no electron transport and no C~I needed. GO-CAM cannot say "X without Y".
- **Evidence for Mitchell / against Slater**: no supports/refutes link to the other models.
- **In vitro vs in vivo**: only implicit via ECO choice; IDA does not encode "isolated organelle".
- Gene product choice is arbitrary: the 1966 paper used a whole membrane, not a cloned protein.

### Mitchell & Moyle 1967, PMID:16742541 (provenance: real abstract; experimental result)

```turtle
:m16742541 a owl:Ontology ;
    obo:RO_0002162 obo:NCBITaxon_10116 ;         # in_taxon Rattus norvegicus
    lego:modelstate "production" ;
    rdfs:comment "Isolated rat liver mitochondria (in vitro suspension). Respiration pulses -> acid pulses outside. H+/2e- (->H+/O) ~4 succinate, ~6 beta-hydroxybutyrate; constant pH 5.5-8.5. Uncouplers raise H+ conductance, do NOT change initial H+/O." .

:cc  a obo:GO_0005743 .                          # mitochondrial inner membrane (abstract: 'M phase of the cristae membrane')
:loc a obo:CL_0000182 ; obo:BFO_0000050 [ a obo:UBERON_0002107 ] .   # hepatocyte part_of liver

# AU1: complex II -> ubiquinone, succinate span
:au1 a obo:GO_0008177 ;                          # succinate dehydrogenase (quinone) activity
    obo:RO_0002333 obo:GO_0045273 ;              # enabled_by respiratory chain complex II
    obo:RO_0002233 obo:CHEBI_30031 ;             # has_input succinate
    obo:BFO_0000050 [ a obo:GO_0006121 ] ;       # mitochondrial electron transport, succinate to ubiquinone
    obo:BFO_0000066 :cc ;
    obo:RO_0002413 :au3 .
# AU2: complex I, NADH span (beta-hydroxybutyrate -> NADH)
:au2 a obo:GO_0008137 ;                          # NADH dehydrogenase (ubiquinone) activity
    obo:RO_0002333 obo:GO_0045271 ;              # respiratory chain complex I
    obo:RO_0002233 obo:CHEBI_57945 ;             # NADH (upstream substrate CHEBI:10983 (R)-3-hydroxybutyrate)
    obo:BFO_0000050 [ a obo:GO_0006120 ] ;
    obo:BFO_0000066 :cc ;
    obo:RO_0002413 :au3 .
# AU3: respiration-driven proton translocation (the measured thing)
:au3 a obo:GO_0015078 ;                          # proton transmembrane transporter activity
    obo:RO_0002333 obo:GO_0045275 , obo:GO_0045277 ;   # complex III, IV ("loop 3", O2 side of rotenone/antimycin sites)
    obo:RO_0002233 obo:CHEBI_15378 ;
    obo:BFO_0000050 [ a obo:GO_1902600 ] ;       # proton transmembrane transport
    obo:BFO_0000050 [ a obo:GO_0042775 ] ;       # mitochondrial ATP synthesis coupled electron transport
    obo:BFO_0000066 :cc .

[] a owl:Axiom ; owl:annotatedSource :au1 ; owl:annotatedProperty obo:RO_0002413 ; owl:annotatedTarget :au3 ;
   lego:evidence [ a obo:ECO_0000314 ; dc:source "PMID:16742541" ;
                   rdfs:comment "H+/O ~4 succinate span; ~6 beta-hydroxybutyrate span (free text only)" ] .

# Inhibitors defining loop 3 boundaries (pharmacological evidence)
obo:CHEBI_28201 obo:RO_0012006 :au2 .            # rotenone is_small_molecule_inhibitor_of complex I activity
obo:CHEBI_2762  obo:RO_0012006 [ a obo:GO_0008121 ] .   # antimycin A -> quinol-cytochrome-c reductase activity (complex III)
[] lego:evidence [ a obo:ECO_0006054 ; dc:source "PMID:16742541" ] .   # pharmacological assay evidence (IPI-style)

# Uncouplers: DNP, FCCP, gramicidin increase M-phase H+ conductance (protonophore / channel)
:leak a obo:GO_1902600 ; obo:BFO_0000066 :cc ;    # proton transmembrane transport (non-enzymatic leak; no enabled_by allowed)
    obo:RO_0002305 [ a obo:GO_0015986 ] .         # causally upstream of, negative effect -> pmf-driven ATP synthesis
obo:CHEBI_42017  obo:RO_0012005 :leak .           # 2,4-dinitrophenol is_small_molecule_activator_of leak
obo:CHEBI_75458  obo:RO_0012005 :leak .           # FCCP
obo:CHEBI_749506 obo:RO_0012005 :leak .           # gramicidin
```

Could not express:
- **Stoichiometry** (H+/O = 4 and 6) and its **constancy across pH 5.5-8.5** - no numeric slot, only comment.
- The **negative result** that is the paper's punchline: "uncoupler-sensitive chemical intermediates do not exist". GO-CAM has no NOT in models (GAF has a NOT qualifier, but it needs a gene product and a GO term for C~I, neither exists).
- **Explicit refutation** of the Slater model (PMID:13111237).
- **Methodological caveats** (backlash, anion/cation artefacts change *apparent* H+/O) - not representable.
- **Uncoupler as protonophore**: a small molecule that *is* a transporter. GO-CAM needs a gene product as enabled_by; small molecules can only be regulators.
- Sidedness of H+ movement (in -> out).

### Hinkle & Horstman 1971, PMID:4330063 (provenance: summary; experimental result)

```turtle
:m4330063 a owl:Ontology ;
    obo:RO_0002162 obo:NCBITaxon_9913 ;          # in_taxon Bos taurus (heart)
    lego:modelstate "production" ;
    rdfs:comment "Submitochondrial particles (inside-out inner-membrane vesicles), bovine heart, in vitro. Respiration on NADH or succinate -> H+ UPTAKE into vesicle (interior acidifies). Abolished by uncouplers." .

:cc a obo:GO_0005743 ;                           # mitochondrial inner membrane (as SMP; inversion not expressible)
    obo:BFO_0000050 [ a obo:UBERON_0000948 ] .   # part_of heart

:au1 a obo:GO_0008137 ; obo:RO_0002333 obo:GO_0045271 ;        # NADH dehydrogenase (ubiquinone) activity / complex I
    obo:RO_0002233 obo:CHEBI_57945 ; obo:BFO_0000066 :cc ; obo:RO_0002413 :au3 .
:au2 a obo:GO_0008177 ; obo:RO_0002333 obo:GO_0045273 ;        # SDH (quinone) / complex II
    obo:RO_0002233 obo:CHEBI_30031 ; obo:BFO_0000066 :cc ; obo:RO_0002413 :au3 .
:au3 a obo:GO_0015078 ;                                        # proton transmembrane transporter activity
    obo:RO_0002333 obo:GO_0045271 ;                            # complex I (and III/IV) as H+ pumps
    obo:RO_0002233 obo:CHEBI_15378 ;
    obo:BFO_0000050 [ a obo:GO_1902600 ] ; obo:BFO_0000066 :cc .

[] a owl:Axiom ; owl:annotatedSource :au3 ; owl:annotatedProperty obo:BFO_0000050 ;
   lego:evidence [ a obo:ECO_0000314 ; dc:source "PMID:4330063" ] .

obo:CHEBI_75458 obo:RO_0012005 :leak .            # FCCP activates leak ...
:leak a obo:GO_1902600 ; obo:RO_0002305 :au3 .    # ... which negates net H+ accumulation
[] lego:evidence [ a obo:ECO_0006054 ; dc:source "PMID:4330063" ] .
```

Could not express:
- **Inside-out topology** of SMPs, which is the whole point (uptake, not extrusion, proves vectorial pumping). GO CC has no "inverted vesicle" and no membrane-side relation on has_input.
- **Direction** (uptake vs release) of the proton flux.
- "Together with **later work** from the same lab" - a pointer to unnamed follow-up evidence; dc:source must be one PMID.
- Evidence **for Mitchell / against Slater** - no inter-model link.
- Which uncoupler(s) were used is not in the summary; I used FCCP as a placeholder (curator guess, which GO-CAM would hide).

### Racker & Stoeckenius 1974, PMID:4272126 (provenance: summary; reconstitution result)

```turtle
:m4272126 a owl:Ontology ;
    obo:RO_0002162 obo:NCBITaxon_2242 , obo:NCBITaxon_9913 ;   # TWO taxa in one model - legal syntax, breaks the one-model-one-organism convention
    lego:modelstate "production" ;
    rdfs:comment "Artificial phospholipid vesicles: H. halobium bacteriorhodopsin + bovine heart oligomycin-sensitive F1Fo ATPase. Light -> H+ uptake -> ATP. Abolished by uncouplers and oligomycin. No shared chemical intermediate possible." .

:ves a obo:GO_0012506 .                          # vesicle membrane (closest; it is a synthetic liposome, not a cell part)

# AU1: bacteriorhodopsin light-driven proton pump
:au1 a obo:GO_0015078 ;                          # proton transmembrane transporter activity
    obo:RO_0002333 up:P02945 ;                   # BACR_HALSA (bop)
    obo:RO_0002233 obo:CHEBI_15378 ;
    obo:BFO_0000066 :ves ;
    obo:RO_0002413 :au2 .                        # provides_input_for -> ATP synthase (via H+ gradient)
:au1b a obo:GO_0009881 ; obo:RO_0002333 up:P02945 ; obo:RO_0002629 :au1 .   # photoreceptor activity directly_pos_reg pumping

# AU2: mitochondrial ATP synthase driven by BR's gradient
:au2 a obo:GO_0046933 ;
    obo:RO_0002333 up:P00829 ;                   # ATPB_BOVIN (representative subunit of F1Fo)
    obo:RO_0002233 obo:CHEBI_456216 , obo:CHEBI_43474 , obo:CHEBI_15378 ;
    obo:RO_0002234 obo:CHEBI_30616 ;
    obo:BFO_0000050 [ a obo:GO_0015986 ] ;
    obo:BFO_0000066 :ves .

[] a owl:Axiom ; owl:annotatedSource :au1 ; owl:annotatedProperty obo:RO_0002413 ; owl:annotatedTarget :au2 ;
   lego:evidence [ a obo:ECO_0000003 ; dc:source "PMID:4272126" ] .    # reconstitution assay evidence

obo:CHEBI_25675 obo:RO_0012006 :au2 .            # oligomycin is_small_molecule_inhibitor_of ATP synthase
obo:CHEBI_75458 obo:RO_0012006 :au2 .            # uncoupler (identity not given in summary; FCCP placeholder)
[] lego:evidence [ a obo:ECO_0006054 ; dc:source "PMID:4272126" ] .
```

Could not express:
- The **logical inference** "unrelated organisms => no shared chemical intermediate => gradient is sufficient". This is an argument, not an activity; GO-CAM has nowhere to put it.
- **Cross-species chimeric system** as a design feature. Two in_taxon values are allowed syntactically but no GO tool treats a mixed-species model as meaningful.
- **Synthetic/artificial location** (liposome): GO CC is for natural cellular components only; GO:0012506 is a stretch.
- The fact that this **refutes Slater** and **confirms Mitchell**.
- Light as an input: no "has_input light" (light is not a CHEBI entity); hence the photoreceptor-activity workaround.

### Yoshino 2011, PMID:21982712 (provenance: real abstract; in vivo mouse + cells)

```turtle
:m21982712 a owl:Ontology ;
    obo:RO_0002162 obo:NCBITaxon_10090 ;         # Mus musculus
    lego:modelstate "production" ;
    rdfs:comment "HFD-induced and age-induced T2D mouse models. NMN (dose/route/duration not in abstract) restores NAD+, ameliorates glucose intolerance, improves hepatic insulin sensitivity, partly via SIRT1. NAMPT and NAD+ fall with HFD and with age in multiple organs." .

:hep a obo:CL_0000182 ; obo:BFO_0000050 [ a obo:UBERON_0002107 ] .    # hepatocyte part_of liver

# AU1: NAMPT makes NMN (salvage)
:au1 a obo:GO_0047280 ;                          # nicotinamide phosphoribosyltransferase activity
    obo:RO_0002333 up:Q99KQ4 ;                   # NAMPT_MOUSE
    obo:RO_0002234 obo:CHEBI_14649 ;             # has_output NMN(-)
    obo:BFO_0000050 [ a obo:GO_0034355 ] ;       # NAD+ biosynthetic process via the salvage pathway
    obo:BFO_0000066 :hep ;
    obo:RO_0002413 :au2 .
# AU2: NMNAT converts NMN to NAD+ (background knowledge, not shown in paper)
:au2 a obo:GO_0000309 ;                          # nicotinamide-nucleotide adenylyltransferase activity
    obo:RO_0002333 up:Q9EPA7 ;                   # NMNA1_MOUSE
    obo:RO_0002233 obo:CHEBI_14649 ; obo:RO_0002234 obo:CHEBI_15846 ;   # NMN -> NAD(+)
    obo:BFO_0000066 :hep .
[] lego:evidence [ a obo:ECO_0000306 ; dc:source "PMID:21982712" ] .   # inference from background knowledge

# AU3: NAD+ activates SIRT1 deacetylase
obo:CHEBI_15846 obo:RO_0012005 :au3 .            # is_small_molecule_activator_of
:au3 a obo:GO_0034979 ;                          # NAD-dependent protein lysine deacetylase activity
    obo:RO_0002333 up:Q923E4 ;                   # SIR1_MOUSE
    obo:BFO_0000066 :hep ;
    obo:RO_0002304 :bp_ins , :bp_ox , :bp_inf , :bp_circ .   # causally upstream of, positive effect ("partly through")
:bp_ins  a obo:GO_0032868 ; obo:BFO_0000066 :hep .   # response to insulin (hepatic insulin sensitivity)
:bp_ox   a obo:GO_0006979 .                          # response to oxidative stress (gene expression restored)
:bp_inf  a obo:GO_0006954 .                          # inflammatory response  (direction lost: NMN "restores" it)
:bp_circ a obo:GO_0007623 .                          # circadian rhythm

[] a owl:Axiom ; owl:annotatedSource :au3 ; owl:annotatedProperty obo:RO_0002304 ; owl:annotatedTarget :bp_ins ;
   lego:evidence [ a obo:ECO_0000315 ; dc:source "PMID:21982712" ;    # IMP (SIRT1 dependence, presumably KD/KO in hepatocytes)
                   rdfs:comment "partly SIRT1-dependent; system not specified in abstract" ] .

# AU4: NMN (exogenous) -> glucose homeostasis (organism level)
obo:CHEBI_14649 obo:RO_0012005 [ a obo:GO_0042593 ] .   # NMN is_small_molecule_activator_of glucose homeostasis
[] lego:evidence [ a obo:ECO_0007119 ; dc:source "PMID:21982712" ] .   # in vivo assay evidence used in manual assertion
```

GAF col 16 (how a GO curator would really capture the expression-change results):

```
UniProtKB  Q99KQ4  Nampt  -  acts_upstream_of_or_within  GO:0042593  PMID:21982712  IEP  -  P  ...  taxon:10090  ...  occurs_in(UBERON:0002107)
UniProtKB  Q923E4  Sirt1  -  acts_upstream_of_or_within_positive_effect  GO:0032868  PMID:21982712  IMP  -  P  ...  taxon:10090  ...  occurs_in(CL:0000182)
```

Could not express:
- The **disease models** (HFD-induced T2D: MONDO:0005148; diet EFO:0002757; age-induced T2D). GO-CAM has no disease or exposure slot.
- **Phenotypes**: glucose intolerance (MP:0005293) and its rescue (MP:0005292 improved glucose tolerance); lipid profile (MP:0001547). GO explicitly excludes phenotypes.
- **Direction of change on a quantity** (NAD+ and NAMPT *decrease* with HFD and age). Causal edges link activities; there is no "level of NAD+ decreased in condition X".
- **Age** as context: GO:0007568 "aging" is **obsolete**, and there is no age/stage slot.
- **Dose, route, duration** of NMN; nothing in the abstract, and nowhere to put it anyway.
- **"Partly"** through SIRT1 - no partial-mediation or effect-size semantics.
- **Treatment as intervention**: NMN as "is_small_molecule_activator_of glucose homeostasis" is a stretch; GO-CAM expects small-molecule regulators of a specific MF.

### Gomes 2013, PMID:24360282 (provenance: real abstract; in vivo mouse, aging)

```turtle
:m24360282 a owl:Ontology ;
    obo:RO_0002162 obo:NCBITaxon_10090 ;
    lego:modelstate "production" ;
    rdfs:comment "Aging mice (old vs young; ages not in abstract). Nuclear NAD+ declines -> HIF-1a stabilised under normoxia -> loss of mtDNA-encoded (not nuclear-encoded) OXPHOS subunits; PGC-1a/b-independent. SIRT1 deletion accelerates; raising NAD+ (NMN) in old mice restores mitochondrial function, SIRT1-dependent." .

:musc a obo:UBERON_0001134 .                     # skeletal muscle tissue (tissue not named in abstract; well known from paper)
:nuc  a obo:GO_0005634 .                         # nucleus

# AU1: NAD+ activates nuclear SIRT1
obo:CHEBI_15846 obo:RO_0012005 :au1 .
:au1 a obo:GO_0034979 ;                          # NAD-dependent protein lysine deacetylase activity
    obo:RO_0002333 up:Q923E4 ;                   # SIR1_MOUSE
    obo:BFO_0000066 :nuc ;
    obo:RO_0002630 :au2 .                        # directly negatively regulates HIF-1a (via VHL in paper; indirect really)
# AU2: HIF-1a transcription factor activity
:au2 a obo:GO_0003700 ;                          # DNA-binding transcription factor activity
    obo:RO_0002333 up:Q61221 ;                   # HIF1A_MOUSE
    obo:BFO_0000066 :nuc ;
    obo:BFO_0000050 [ a obo:GO_0031930 ] ;       # mitochondria-nucleus signaling pathway
    obo:RO_0002305 :bp_mt .                      # causally upstream of, negative effect
:bp_mt a obo:GO_0140053 ;                        # mitochondrial gene expression (mtDNA-encoded OXPHOS subunits, e.g. P00397 COX1_MOUSE)
    obo:RO_0002304 [ a obo:GO_0006119 ] .        # -> oxidative phosphorylation

[] a owl:Axiom ; owl:annotatedSource :au1 ; owl:annotatedProperty obo:RO_0002630 ; owl:annotatedTarget :au2 ;
   lego:evidence [ a obo:ECO_0001168 ; dc:source "PMID:24360282" ] .  # conditional knockout evidence (SIRT1 deletion)
[] a owl:Axiom ; owl:annotatedSource :au2 ; owl:annotatedProperty obo:RO_0002305 ; owl:annotatedTarget :bp_mt ;
   lego:evidence [ a obo:ECO_0000270 ; dc:source "PMID:24360282" ] .  # expression pattern evidence (IEP)

# AU3: NMN raises NAD+ in old mice -> OXPHOS restored, SIRT1-dependent
obo:CHEBI_14649 obo:RO_0012005 [ a obo:GO_0000309 ] .   # NMN feeds NMNAT (substrate, really has_input)
[] lego:evidence [ a obo:ECO_0007119 ; dc:source "PMID:24360282" ;
                   rdfs:comment "NMN in old mice; restores mito function to young level" ] .

# Negative/specificity: PGC-1a NOT required
# GAF NOT-qualified line (GO-CAM has no NOT):
#   UniProtKB O70343 Ppargc1a  NOT|involved_in  GO:0031930  PMID:24360282  IMP  ...  taxon:10090
```

Could not express:
- **Age as the independent variable** ("during aging"; old vs young). No age slot; GO:0007568 aging is obsolete.
- **Specificity contrasts**: loss of *mitochondrial-* but *not nuclear-*encoded subunits. Two expression facts with opposite truth values are hard; NOT exists only in GAF.
- **"Pseudohypoxia" / normoxic HIF-1a accumulation**: a protein-*level* change, not an activity. GO-CAM cannot say "HIF-1a stabilised under normoxia".
- **Reversibility** ("restores to that of a young mouse") - a comparison to a reference cohort.
- **Warburg parallel** - an analogy, not expressible.
- **Phenotype** (mitochondrial dysfunction MP:0006036) is outside GO.

### Mills 2016, PMID:28068222 (provenance: real abstract; in vivo mouse, 12-month oral NMN)

```turtle
:m28068222 a owl:Ontology ;
    obo:RO_0002162 obo:NCBITaxon_10090 ;
    lego:modelstate "production" ;
    rdfs:comment "Wild-type C57BL/6N, regular chow, normal aging; oral NMN for 12 months (dose not in abstract). No obvious toxicity. Suppressed age-associated weight gain; enhanced energy metabolism, physical activity, insulin sensitivity, plasma lipids, eye function. Prevented age-associated gene-expression changes; enhanced mitochondrial oxidative metabolism and mitonuclear protein imbalance in skeletal muscle." .
#   strain has no GO-CAM slot; nearest term EFO:0007732 is C57BL/6NJ (a different substrain) -> ?:unverified for C57BL/6N

:musc a obo:UBERON_0001134 .                     # skeletal muscle tissue

# AU1: orally given NMN is rapidly converted to NAD+ in tissues
:au1 a obo:GO_0000309 ;                          # nicotinamide-nucleotide adenylyltransferase activity
    obo:RO_0002333 up:Q9EPA7 ;                   # NMNA1_MOUSE (isoform not determined in paper)
    obo:RO_0002233 obo:CHEBI_14649 ; obo:RO_0002234 obo:CHEBI_15846 ;
    obo:BFO_0000050 [ a obo:GO_0034355 ] ;       # NAD+ biosynthesis via salvage
    obo:RO_0002304 :bp_ox , :bp_ins .
[] lego:evidence [ a obo:ECO_0007119 ; dc:source "PMID:28068222" ] .   # in vivo assay (tissue NAD+ after oral NMN)

:bp_ox  a obo:GO_0006119 ; obo:BFO_0000066 :musc .   # oxidative phosphorylation, in skeletal muscle
:bp_ins a obo:GO_0032868 .                           # response to insulin
[] a owl:Axiom ; owl:annotatedSource :au1 ; owl:annotatedProperty obo:RO_0002304 ; owl:annotatedTarget :bp_ox ;
   lego:evidence [ a obo:ECO_0007119 ; dc:source "PMID:28068222" ] .

# Organism-level outcomes - the only honest GO-CAM rendering is "NMN acts upstream of" broad BPs:
obo:CHEBI_14649 obo:RO_0012005 [ a obo:GO_0055088 ] .   # lipid homeostasis (plasma lipid profile)
obo:CHEBI_14649 obo:RO_0012005 [ a obo:GO_0007626 ] .   # locomotory behavior (physical activity)
[] lego:evidence [ a obo:ECO_0007119 ; dc:source "PMID:28068222" ] .
```

Could not express:
- **Duration (12 months), route (oral), dose**, chow diet, start age. Only free-text comment.
- **Strain** C57BL/6N (no slot; and EFO only has C57BL/6NJ).
- **"Prevented age-associated change"** - a counterfactual against an untreated aging trajectory. GO-CAM has no time course or control arm.
- **Phenotype battery**: body weight gain (MP:0010182 decreased susceptibility to weight gain), insulin sensitivity (MP:0002891), eye function, energy expenditure. All MP, all out of GO scope.
- **Negative safety result** ("no obvious toxicity") - no place for absence of an effect.
- **Translational claim** ("potential... in humans") - not a biological statement.

### Das 2018, PMID:29570999 (provenance: real abstract; in vivo mouse + cells)

```turtle
:m29570999 a owl:Ontology ;
    obo:RO_0002162 obo:NCBITaxon_10090 ;
    lego:modelstate "production" ;
    rdfs:comment "Elderly mice. NMN improves blood flow and endurance via SIRT1-dependent increase in capillary density; augmented by exercise or by H2S (DR mimetic, regulator of endothelial NAD+). Endothelial SIRT1 mediates pro-angiogenic signals secreted from myocytes." .

:ec a obo:CL_0000115 ; obo:BFO_0000050 [ a obo:UBERON_0001134 ] .   # endothelial cell part_of skeletal muscle tissue
:my a obo:CL_0000187 .                                             # muscle cell (myocyte; secretes signal)

# AU1: myocyte-secreted pro-angiogenic signal (identity not given in abstract)
:au1 a obo:GO_0003674 ;                          # molecular_function root - unknown signal
    obo:RO_0002333 ?:unverified ;                # unknown secreted factor
    obo:BFO_0000066 :my ;
    obo:RO_0002304 :au2 .
# AU2: endothelial SIRT1 deacetylase
obo:CHEBI_15846 obo:RO_0012005 :au2 .            # NAD+ activates SIRT1
obo:CHEBI_16136 obo:RO_0012005 :au2 .            # hydrogen sulfide raises endothelial NAD+ -> activates (indirect)
:au2 a obo:GO_0034979 ;
    obo:RO_0002333 up:Q923E4 ;                   # SIR1_MOUSE
    obo:BFO_0000066 :ec ;
    obo:RO_0002304 :bp_ang .
:bp_ang a obo:GO_0002040 ; obo:BFO_0000066 :ec .  # sprouting angiogenesis (capillary density)

[] a owl:Axiom ; owl:annotatedSource :au2 ; owl:annotatedProperty obo:RO_0002304 ; owl:annotatedTarget :bp_ang ;
   lego:evidence [ a obo:ECO_0001168 ; dc:source "PMID:29570999" ;   # conditional (endothelial) knockout evidence
                   rdfs:comment "SIRT1-dependent; endothelial-specific deletion implied by 'SIRT1 in endothelial cells'" ] .

# AU3: NMN treatment upstream of SIRT1 activation
obo:CHEBI_14649 obo:RO_0012005 :au2 .
[] lego:evidence [ a obo:ECO_0007119 ; dc:source "PMID:29570999" ] .
```

GAF col 16:

```
UniProtKB  Q923E4  Sirt1  -  acts_upstream_of_or_within_positive_effect  GO:0002040  PMID:29570999  IMP  -  P  ...  taxon:10090  ...  occurs_in(CL:0000115),occurs_in(UBERON:0001134)
```

Could not express:
- **Old age** of the mice; **endurance** (MP:0012107 enhanced exercise endurance) and **blood flow** - phenotypes.
- **Capillary density** (MP:0020330 increased capillary density) as the measured readout; GO only has the process (angiogenesis).
- **Synergy/augmentation** by exercise (EFO:0000483) or H2S - no interaction-effect semantics; exercise is not a molecule.
- **H2S as "DR mimetic"** - an analogy to dietary restriction, no slot.
- **Intercellular route** (myocyte -> endothelial cell) is expressible only if the signal is a named gene product; here it is not.
- **Translational claims** ("improving human performance") - not biology.

### Yoshino 2021, PMID:33888596 (provenance: real abstract; human RCT)

```turtle
:m33888596 a owl:Ontology ;
    obo:RO_0002162 obo:NCBITaxon_9606 ;          # Homo sapiens
    lego:modelstate "production" ;
    rdfs:comment "10-week randomized, placebo-controlled, double-blind trial (NCT03151239). Postmenopausal (EFO:0002721) women (PATO:0000383), prediabetes (MONDO:0006920), overweight/obese (HP:0025502 / MONDO:0011122). NMN (dose not in abstract) vs placebo. Clamp insulin-stimulated glucose disposal up; muscle p-AKT and p-mTOR up; PDGFRB and remodeling genes up. Placebo: no change." .

:musc a obo:UBERON_0001134 .                     # skeletal muscle tissue (biopsy)

# AU1: insulin receptor signaling in muscle, enhanced
:au1 a obo:GO_0004674 ;                          # protein serine/threonine kinase activity
    obo:RO_0002333 up:P31749 ;                   # AKT1_HUMAN (isoform not resolved by phospho-AKT antibody)
    obo:BFO_0000050 [ a obo:GO_0008286 ] ;       # insulin receptor signaling pathway
    obo:BFO_0000066 :musc ;
    obo:RO_0002304 :au2 .
:au2 a obo:GO_0004674 ;
    obo:RO_0002333 up:P42345 ;                   # MTOR_HUMAN
    obo:BFO_0000050 [ a obo:GO_0038202 ] ;       # TORC1 signaling (complex not resolved in abstract)
    obo:BFO_0000066 :musc .
:bp_ins a obo:GO_0032869 ; obo:BFO_0000066 :musc .   # cellular response to insulin stimulus (glucose disposal)

obo:CHEBI_14649 obo:RO_0012005 :au1 , :bp_ins .  # NMN is_small_molecule_activator_of (indirect!)
[] a owl:Axiom ; owl:annotatedSource obo:CHEBI_14649 ; owl:annotatedProperty obo:RO_0012005 ; owl:annotatedTarget :bp_ins ;
   lego:evidence [ a obo:ECO_0007121 ; dc:source "PMID:33888596" ;   # clinical study evidence used in manual assertion
                   rdfs:comment "RCT, NCT03151239; hyperinsulinemic-euglycemic clamp" ] .

# AU3: PDGFRB up-regulated (expression response)
:au3 a obo:GO_0005017 ;                          # platelet-derived growth factor receptor activity
    obo:RO_0002333 up:P09619 ;                   # PGFRB_HUMAN
    obo:BFO_0000050 [ a obo:GO_0048008 ] ;       # PDGF receptor signaling pathway
    obo:BFO_0000066 :musc .
[] lego:evidence [ a obo:ECO_0000270 ; dc:source "PMID:33888596" ] .   # expression pattern evidence (IEP)
```

GAF (IEP style, the normal way GO handles "gene X went up after treatment"):

```
UniProtKB  P09619  PDGFRB  -  acts_upstream_of_or_within  GO:0007519  PMID:33888596  IEP  -  P  ...  taxon:9606  ...  occurs_in(UBERON:0001134),has_input(CHEBI:14649)
```
(GO:0007519 skeletal muscle tissue development as the "remodeling" stand-in; has_input(CHEBI:14649) misuses has_input to mean "in response to".)

Could not express:
- **Trial design**: randomized, placebo-controlled, double-blind, 10 weeks, NCT ID. ECO:0007121 says "clinical study" and nothing more.
- **Population**: postmenopausal, female, prediabetic, overweight/obese - none have a slot (comment only).
- **Placebo arm / null result** ("did not change after placebo") - no control-arm or NOT for a treatment.
- **Phosphorylation** as the readout (p-AKT, p-mTOR): GO-CAM can say the kinase activity is part of a pathway, not "its phospho-level rose".
- **Cross-species transfer**: abstract explicitly builds on rodent results; GO-CAM has no "translates from NCBITaxon:10090" link (only ECO:0000250 sequence-similarity ISS, which is for orthologs, not for findings).
- **Effect size** of clamp glucose disposal.

## 3. Fit table

| Aspect | Expressible? | How |
|---|---|---|
| Direction of effect | partial | Between activities: RO:0002304/RO:0002305, RO:0002629/RO:0002630. Not on *levels* (NAD+ down, HIF-1a protein up, p-AKT up); not on phenotypes. |
| Quantitative result | no | No numeric slot. H+/O = 4/6, pH-jump size, clamp effect size go in `rdfs:comment` only. |
| Species/strain | partial | Species: model-level `in_taxon` (RO:0002162) + UniProt taxon. Strain (C57BL/6N): no slot. Mixed-species models (Racker) syntactically legal but off-convention. |
| Age/stage | no | No age slot; GO:0007568 "aging" is obsolete. "Old vs young" only in comment. |
| Tissue/cell | yes | `occurs_in` CL/UBERON or GO CC; GAF col 16 `occurs_in(CL:...)`. This is GO-CAM's best context slot. |
| Disease model | no | MONDO/HFD/age-induced T2D have no slot; GO excludes disease. |
| Dose/duration | no | Nothing. Comment only. |
| Hypothesis vs result | partial | Only via ECO (ECO:0000303 NAS vs ECO:0000314 IDA) and `modelstate`. Neither means "proposed, untested". |
| Rival hypotheses | no | No inter-model "alternative to"/"contradicts". Slater's C~I has no CHEBI/UniProt, so his model fails validation outright. |
| Evidence type | yes | ECO class on every edge, with PMID. Rich (IDA, IMP, IEP, reconstitution ECO:0000003, clinical ECO:0007121, conditional KO ECO:0001168). |
| Cross-species transfer | no | ISS/ECO:0000250 is for orthologous genes, not for "mouse finding replicated in human". |
| Negative results | partial | GAF NOT qualifier exists (needs gene product + GO term). GO-CAM models have no NOT. "No intermediate exists" and "placebo no change" are unexpressible. |

## 4. Verdict

(a) For the chemiosmotic papers GO-CAM fits the *final, accepted* mechanism very well: respiratory complexes pumping H+ in the inner membrane, `provides_input_for` an ATP synthase, inhibited by rotenone/antimycin/oligomycin, is exactly what a GO-CAM is for. It is awkward for the *history*: Mitchell and Slater are models, not activities, and GO-CAM has no way to hold two rival models, mark one as a hypothesis, or let Jagendorf/Hinkle/Racker *support* one and *refute* the other. Slater's model is not just unflattering, it is invalid: its central molecule C~I and its enzyme have no identifiers, so it cannot pass GO-CAM validation. The papers' key logic is negative or about sufficiency ("no chemical intermediate exists", "a pH gradient alone suffices", "unrelated proteins share no intermediate"), and GO-CAM cannot state absence or sufficiency. Stoichiometry, sidedness of the membrane, and inside-out vesicles all collapse into free text.

(b) For the NMN papers the fit is poor, because the findings are mostly phenotypes in treated mice, and GO by design excludes phenotypes, disease, diet, dose, duration, age and sex. The mechanistic spine (NAMPT -> NMN -> NMNAT -> NAD+ -> SIRT1 -> process, in hepatocyte/endothelium/muscle, with KO evidence) is well represented and that part is genuinely useful. Everything that makes these papers *interesting* - HFD vs aged models, 12-month oral dosing, "prevents age-associated decline", RCT in postmenopausal prediabetic women, placebo no change, mouse-to-human transfer - ends up in `rdfs:comment` where no reasoner can see it. Using `is_small_molecule_activator_of` for a dietary supplement acting on a whole-body process is a convention abuse that real GO curators would reject. In short: GO-CAM is a good wiring diagram and a bad lab notebook; it needs to be paired with a phenotype/context formalism (e.g. Phenopackets, Biolink associations with qualifiers, or MP/HP-based annotation) to carry what these papers actually claim.
