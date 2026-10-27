# BioLean (current schema) as an annotation formalism

## 1. The formalism

BioLean annotations are Lean 4 source. The unit of annotation is a `Statement`: an `id`, a free-text
`text`, one `Claim`, and a list of `Evidence` items. A `Claim` is either
`.effect agent sign target` ("agent has a +/− effect on target") or
`.mediatedBy agent sign target mediator` ("that effect runs via mediator"). Agents are any
`Entity k` (a CURIE + label, indexed by a coarse `Kind`: chemical, protein, gene, process, function,
phenotype, disease, anatomy, cellType). Targets are `.activity` (protein only), `.amount`, `.process`,
`.phenotype` or `.site` (anatomy only). `Sign` is only `.pos` / `.neg`. Each `Evidence` carries
`pmid`, `year`, `kind` (metaAnalysis, rct, curatedDb, mechanistic, review, observational, inVitro,
textMined), `polarity` (`.supports` / `.refutes`) and a free-text `note`. **Context has no
structured home at all**: species, strain, age, tissue, dose, duration and sex can only go into
the `note` string (or be smuggled into the choice of a species-specific UniProt accession, or into a
`.site` mediator). Rival hypotheses are modelled the way the GLP-1 library does it (S9a/S9b):
competing `.mediatedBy` claims on the same agent and target, with papers attached as `.supports`
or `.refutes`. Below, papers whose text is a secondary-source summary are marked `[summary]` at the
start of the evidence `note`.

All IDs below were checked against OLS4 (ChEBI, GO, MP, HP, MONDO, UBERON, CL, PATO, EFO, NCIT,
NCBITaxon) or the UniProt REST API on 2026-10-26. `?:unverified` marks things with no ID found
(often because the thing is hypothetical, e.g. Slater's C~I).

### Shared entities (Lean)

```lean
import BioLean
namespace BioLean.Formalisms

/-! Chemicals (ChEBI) -/
def ATP      : Entity .chemical := ⟨"CHEBI:15422", "ATP"⟩
def ADP      : Entity .chemical := ⟨"CHEBI:16761", "ADP"⟩
def hydron   : Entity .chemical := ⟨"CHEBI:15378", "hydron (H+)"⟩
def DNP      : Entity .chemical := ⟨"CHEBI:42017", "2,4-dinitrophenol"⟩
def FCCP     : Entity .chemical := ⟨"CHEBI:75458", "carbonyl cyanide p-trifluoromethoxyphenylhydrazone"⟩
def gramicidin : Entity .chemical := ⟨"CHEBI:749506", "gramicidin"⟩
def oligomycin : Entity .chemical := ⟨"CHEBI:25675", "oligomycin"⟩
def succinate  : Entity .chemical := ⟨"CHEBI:26806", "succinate"⟩
def bHB      : Entity .chemical := ⟨"CHEBI:10983", "(R)-3-hydroxybutyrate"⟩
def NMN      : Entity .chemical := ⟨"CHEBI:16171", "nicotinamide mononucleotide (NMN)"⟩
def NADp     : Entity .chemical := ⟨"CHEBI:15846", "NAD(+)"⟩
def H2S      : Entity .chemical := ⟨"CHEBI:16136", "hydrogen sulfide"⟩
/-- Generic "uncouplers": no ChEBI role class found (GO:0017077 is an activity, not a chemical). -/
def uncoupler : Entity .chemical := ⟨"?:unverified", "uncoupling agent (class)"⟩
/-- Slater's hypothetical high-energy intermediate. It has no ID because it was never found. -/
def CsquiggleI : Entity .chemical := ⟨"?:unverified", "C~I, non-phosphorylated high-energy intermediate (hypothetical)"⟩

/-! Proteins (UniProt; accession fixes the species) -/
def bR        : Entity .protein := ⟨"UniProt:P02945", "bacteriorhodopsin (H. salinarum)"⟩
/-- Proxy: the beta subunit stands in for the whole F1Fo complex (GO:0005753), because
    `Kind` has no complex/cellular-component kind. -/
def ATPsynB   : Entity .protein := ⟨"UniProt:P00829", "ATP5F1B, F1Fo ATP synthase beta (bovine)"⟩
def NAMPT_m   : Entity .protein := ⟨"UniProt:Q99KQ4", "NAMPT (mouse)"⟩
def SIRT1_m   : Entity .protein := ⟨"UniProt:Q923E4", "SIRT1 (mouse)"⟩
def HIF1A_m   : Entity .protein := ⟨"UniProt:Q61221", "HIF-1alpha (mouse)"⟩
def PGC1A_m   : Entity .protein := ⟨"UniProt:O70343", "PGC-1alpha (mouse)"⟩
def AKT1_h    : Entity .protein := ⟨"UniProt:P31749", "AKT1 (human)"⟩
def MTOR_h    : Entity .protein := ⟨"UniProt:P42345", "mTOR (human)"⟩
def PDGFRB_h  : Entity .protein := ⟨"UniProt:P09619", "PDGFR-beta (human)"⟩

/-! Processes (GO BP) -/
def respChain   : Entity .process := ⟨"GO:0022904", "respiratory electron transport chain"⟩
def photoChain  : Entity .process := ⟨"GO:0009767", "photosynthetic electron transport chain"⟩
def oxphos      : Entity .process := ⟨"GO:0006119", "oxidative phosphorylation"⟩
def photophos   : Entity .process := ⟨"GO:0009777", "photosynthetic phosphorylation"⟩
def pmfATP      : Entity .process := ⟨"GO:0015986", "proton motive force-driven ATP synthesis"⟩
def pmfATPmito  : Entity .process := ⟨"GO:0042776", "proton motive force-driven mitochondrial ATP synthesis"⟩
def etProtonTx  : Entity .process := ⟨"GO:0015990", "electron transport coupled proton transport"⟩
def protonTx    : Entity .process := ⟨"GO:1902600", "proton transmembrane transport"⟩
def NADbiosyn   : Entity .process := ⟨"GO:0009435", "NAD+ biosynthetic process"⟩
def aging       : Entity .process := ⟨"GO:0007568", "aging"⟩
def mitoGeneExpr: Entity .process := ⟨"GO:0140053", "mitochondrial gene expression"⟩
def angiogenesis: Entity .process := ⟨"GO:0001525", "angiogenesis"⟩
def sproutAngio : Entity .process := ⟨"GO:0002040", "sprouting angiogenesis"⟩
def oxStressResp: Entity .process := ⟨"GO:0006979", "response to oxidative stress"⟩
def inflamResp  : Entity .process := ⟨"GO:0006954", "inflammatory response"⟩
def circadian   : Entity .process := ⟨"GO:0007623", "circadian rhythm"⟩
def insGlcImport: Entity .process := ⟨"GO:0044381", "glucose import in response to insulin stimulus"⟩
def insSignal   : Entity .process := ⟨"GO:0008286", "insulin receptor signaling pathway"⟩
def muscleAdapt : Entity .process := ⟨"GO:0043500", "muscle adaptation (proxy for 'muscle remodeling')"⟩

/-! Phenotypes / qualities (MP, HP, PATO). Note: MP labels already carry a direction. -/
def permeability    : Entity .phenotype := ⟨"PATO:0000970", "permeability"⟩
def impGlcTol       : Entity .phenotype := ⟨"MP:0005293", "impaired glucose tolerance"⟩
def incInsSens      : Entity .phenotype := ⟨"MP:0002891", "increased insulin sensitivity"⟩
def abnCircLipid    : Entity .phenotype := ⟨"MP:0003949", "abnormal circulating lipid level"⟩
def incBodyWeight   : Entity .phenotype := ⟨"MP:0001260", "increased body weight"⟩
def incEnergyExp    : Entity .phenotype := ⟨"MP:0004889", "increased energy expenditure"⟩
def hyperactivity   : Entity .phenotype := ⟨"MP:0001399", "hyperactivity (closest MP term to 'more physical activity')"⟩
def abnEyePhys      : Entity .phenotype := ⟨"MP:0005253", "abnormal eye physiology"⟩
def abnMitoPhys     : Entity .phenotype := ⟨"MP:0006036", "abnormal mitochondrial physiology"⟩
def decCapDensity   : Entity .phenotype := ⟨"MP:0020329", "decreased capillary density"⟩
def enhEndurance    : Entity .phenotype := ⟨"MP:0012107", "enhanced exercise endurance"⟩
def muscleBloodFlow : Entity .phenotype := ⟨"?:unverified", "skeletal muscle blood flow"⟩

/-! Diseases (MONDO) -/
def T2D         : Entity .disease := ⟨"MONDO:0005148", "type 2 diabetes mellitus"⟩
def prediabetes : Entity .disease := ⟨"MONDO:0006920", "prediabetes syndrome"⟩

/-! Anatomy (UBERON) and cell types (CL) -/
def liver       : Entity .anatomy := ⟨"UBERON:0002107", "liver"⟩
def skMuscle    : Entity .anatomy := ⟨"UBERON:0001134", "skeletal muscle tissue"⟩
def capillary   : Entity .anatomy := ⟨"UBERON:0001982", "capillary"⟩
def endothelial : Entity .cellType := ⟨"CL:0000115", "endothelial cell"⟩   -- no Target accepts .cellType
/-- GO cellular components forced into `.anatomy`: the type checker does not object, which is
    itself a weakness (Kind is not tied to the CURIE prefix). -/
def mitoInnerMem: Entity .anatomy := ⟨"GO:0005743", "mitochondrial inner membrane"⟩
def thylakoid   : Entity .anatomy := ⟨"GO:0009579", "thylakoid"⟩

/-! Things with no Kind at all, forced into the nearest one -/
/-- A diet is an exposure, not a chemical. EFO is outside the schema's listed ontologies. -/
def highFatDiet : Entity .chemical := ⟨"EFO:0002757", "high fat diet"⟩
/-- Light is a physical stimulus. -/
def light       : Entity .chemical := ⟨"NCIT:C17732", "visible light"⟩
```

Context IDs used only in "Could not express" and section 5: NCBITaxon:10090 (Mus musculus),
NCBITaxon:9606 (Homo sapiens), NCBITaxon:10116 (Rattus norvegicus), NCBITaxon:9913 (Bos taurus),
NCBITaxon:3562 (Spinacia oleracea), NCBITaxon:2242 (Halobacterium salinarum), EFO:0002721
(postmenopausal), HP:0025502 (Overweight), HP:0001513 (Obesity), ECO:0000181 (in vitro assay
evidence), ECO:0000178 (in vivo assay evidence), ECO:0000003 (reconstitution assay evidence),
ECO:0000204 (author statement). C57BL/6N has no NCBITaxon ID (`?:unverified`).

## 2. Per paper

How the controversy is laid out. The two rival hypotheses are two `Statement`s with the same
agent (`respChain`) and target (`oxphos`) but different mediators: `M1` (via proton translocation)
and `SL1` (via C~I). Each paper below defines its own `Evidence` values; the final evidence lists
of `M1` and `SL1` are assembled after the Racker paper. Nothing in the schema says `M1` and
`SL1` are rivals; that is only implied by them sharing an agent and target.

### Mitchell 1961, PMID 13771349 (hypothesis paper; `[summary]`)

```lean
/-- Mitchell's evidence item. There is no `EvidenceKind.hypothesis`; `.review` is the least-bad
    fit, and it makes a data-free proposal count as 0.6 belief. -/
def ev_mitchell61 : Evidence :=
  { pmid := 13771349, year := 1961, kind := .review, polarity := .supports,
    note := "[summary] HYPOTHESIS, no data. Electron transfer translocates protons across an anisotropic membrane; a reversible membrane ATPase uses the gradient to make ATP." }

/-- Main hypothesis: respiration drives phosphorylation via proton translocation.
    (Evidence list assembled below.) -/
def M1_claim : Claim := .mediatedBy respChain .pos (.process oxphos) (.process etProtonTx)

/-- Same hypothesis for photosynthesis. A second statement is needed, because one claim has one agent. -/
def M1b : Statement where
  id := "M1b"
  text := "photosynthetic phosphorylation is coupled to electron transfer via proton translocation"
  claim := .mediatedBy photoChain .pos (.process photophos) (.process etProtonTx)
  evidence := [ev_mitchell61]

/-- Prediction: respiration translocates protons across the membrane. -/
def M2 : Statement where
  id := "M2"
  text := "respiratory electron transport translocates protons"
  claim := .effect respChain .pos (.process protonTx)
  evidence := [{ ev_mitchell61 with note := "[summary] PREDICTION from the chemiosmotic hypothesis" }]

/-- The gradient drives ATP synthesis through the membrane ATPase. The 'gradient' has to be
    written as the chemical `hydron`; there is no entity for a transmembrane difference. -/
def M3 : Statement where
  id := "M3"
  text := "a transmembrane proton gradient drives ATP synthesis via the membrane ATPase"
  claim := .mediatedBy hydron .pos (.process pmfATP) (.activity ATPsynB)
  evidence := [{ ev_mitchell61 with note := "[summary] PREDICTION; ATPase must be reversible and anisotropic" }]

/-- Prediction: uncouplers act by making the membrane proton-permeable. Whose permeability
    (the inner membrane's) cannot be said. -/
def M4 : Statement where
  id := "M4"
  text := "uncouplers increase proton permeability of the coupling membrane"
  claim := .effect uncoupler .pos (.phenotype permeability)
  evidence := [{ ev_mitchell61 with note := "[summary] PREDICTION" }]

def M5 : Statement where
  id := "M5"
  text := "uncouplers inhibit oxidative phosphorylation"
  claim := .effect uncoupler .neg (.process oxphos)
  evidence := [{ ev_mitchell61 with note := "[summary] background fact restated in the hypothesis" }]
```

Could not express:
- That this paper is a hypothesis and M2-M4 are predictions, not results. `EvidenceKind` has no
  `hypothesis`/`prediction`, so the paper is weighted like a review (0.6) in the opinion calculus.
- "The coupling membrane must be ion-impermeable": a static property of a structure. No claim form
  for "X has quality Q"; `.phenotype permeability` has no bearer (inner membrane is a GO CC, no Kind).
- Anisotropy / vectorial direction (which side protons go to). `Sign` is only +/−.
- That the ATPase is reversible (bidirectional effect).
- Generality across mitochondria and chloroplasts: needed two statements (M1, M1b).
- The proton gradient itself: forced to write `hydron` (a chemical) as the agent.
- Species: none applies (general claim), but the protein `ATPsynB` is forced to be bovine.

### Slater 1953, PMID 13111237 (rival hypothesis; `[summary]`)

```lean
def ev_slater53 : Evidence :=
  { pmid := 13111237, year := 1953, kind := .review, polarity := .supports,
    note := "[summary] HYPOTHESIS, no data. Energy from electron transfer is held in a non-phosphorylated high-energy intermediate C~I, which reacts with Pi and ADP to give ATP." }

/-- Rival hypothesis: respiration drives phosphorylation via a chemical intermediate.
    (Evidence list assembled below.) -/
def SL1_claim : Claim := .mediatedBy respChain .pos (.process oxphos) (.amount CsquiggleI)

def SL2 : Statement where
  id := "SL2"
  text := "respiratory electron transport forms C~I"
  claim := .effect respChain .pos (.amount CsquiggleI)
  evidence := [ev_slater53]

def SL3 : Statement where
  id := "SL3"
  text := "C~I drives ATP formation from ADP and Pi"
  claim := .effect CsquiggleI .pos (.amount ATP)
  evidence := [ev_slater53]

/-- Slater's account implies uncouplers act by hydrolysing C~I. Implied, not stated in the summary. -/
def SL4 : Statement where
  id := "SL4"
  text := "uncouplers discharge C~I"
  claim := .effect uncoupler .neg (.amount CsquiggleI)
  evidence := [{ ev_slater53 with note := "[summary] IMPLIED by the chemical-coupling scheme, not stated in the summary" }]
```

Could not express:
- Hypothesis vs result (same gap as Mitchell).
- That C~I is hypothetical. It has to be an `Entity .chemical` with a made-up CURIE; the schema
  treats it like any real compound.
- That SL1 and M1 are mutually exclusive. They are two unrelated statements; fusion will happily
  give both high belief.
- The argument by analogy with glycolytic substrate-level phosphorylation.
- The reaction stoichiometry (C~I + Pi + ADP → ATP + C + I): no reaction/conversion claim, only
  signed effects.

### Jagendorf & Uribe 1966, PMID 5220864 (`[summary]`)

```lean
def ev_jagendorf66 (pol : Opinion.Polarity := .supports) (n : String) : Evidence :=
  { pmid := 5220864, year := 1966, kind := .inVitro, polarity := pol,
    note := s!"[summary] RESULT. Spinach (NCBITaxon:3562) thylakoids, dark, acid stage pH~4 then base stage pH~8 with ADP+Pi. {n}" }

/-- An imposed pH gradient alone drives ATP synthesis (no light, no electron transport). -/
def J1 : Statement where
  id := "J1"
  text := "an artificial transmembrane pH gradient drives ATP synthesis in thylakoids"
  claim := .effect hydron .pos (.process pmfATP)
  evidence := [ev_jagendorf66 (n := "ATP made in the dark after the pH jump")]

/-- The same finding with the site written in, by abusing the mediator slot (as GLP-1 S9c does).
    `thylakoid` is a GO CC forced into `.anatomy`. This does NOT mean "via the thylakoid". -/
def J1site : Statement where
  id := "J1site"
  text := "an artificial pH gradient drives ATP synthesis, at the thylakoid"
  claim := .mediatedBy hydron .pos (.process pmfATP) (.site thylakoid)
  evidence := [ev_jagendorf66 (n := "site encoded as mediator")]

/-- Dose-response: bigger pH jump, more ATP. Only the direction survives. -/
def J2 : Statement where
  id := "J2"
  text := "ATP yield increases with the size of the pH jump"
  claim := .effect hydron .pos (.amount ATP)
  evidence := [ev_jagendorf66 (n := "yield depends on size of pH jump and on the permeant acid")]

def ev_J_for_M3  : Evidence := ev_jagendorf66 (n := "gradient sufficient for ATP synthesis, as predicted")
def ev_J_for_M1  : Evidence := ev_jagendorf66 (n := "supports chemiosmotic coupling")
def ev_J_vs_SL1  : Evidence := ev_jagendorf66 .refutes "ATP made with no electron transport, so no C~I can have been formed by respiration/photosynthesis"
```

Could not express:
- The gradient as a quantity (a difference across a membrane, ΔpH ~4 units). `hydron` is a chemical
  amount with no compartment.
- Conditions: dark, acid stage then base stage, permeant acid (succinate) dependence, ADP+Pi present.
- Species and preparation (spinach, isolated thylakoids, in vitro): only in `note`.
- Quantitative dose-response (ATP yield vs pH jump size).
- "Sufficiency": the logical force (a gradient alone is enough) is stronger than "+ effect".
- How strongly this refutes SL1. Strictly, it shows the gradient route exists, not that C~I does not;
  `polarity := .refutes` cannot be graded.
- Being Mitchell's *predicted* test: no link from a result to the prediction it confirms (M3 vs J1).

### Mitchell & Moyle 1967, PMID 16742541 (real abstract)

```lean
def ev_mm67 (pol : Opinion.Polarity := .supports) (n : String) : Evidence :=
  { pmid := 16742541, year := 1967, kind := .inVitro, polarity := pol,
    note := s!"RESULT. Rat (NCBITaxon:10116) liver mitochondria, oxygen pulses, external pH electrode. {n}" }

/-- Respiration pulses translocate H+ across the cristae membrane. Confirms M2. -/
def MM1 : Statement where
  id := "MM1"
  text := "respiration translocates protons across the mitochondrial inner membrane"
  claim := .effect respChain .pos (.process protonTx)
  evidence := [ev_mm67 (n := "Pulses of acidity ... are due to the translocation of H(+) (or OH(-)) ions across the osmotic barrier")]

/-- The acid is NOT produced by forming and breaking a chemical intermediate. Refuted claim. -/
def MM2 : Statement where
  id := "MM2"
  text := "respiration-linked acid production is mediated by a chemical intermediate"
  claim := .mediatedBy respChain .pos (.amount hydron) (.amount CsquiggleI)
  evidence := [ev_mm67 .refutes "cannot be attributed to the formation (with acid production) of a chemical intermediate that subsequently decomposes"]

/-- H+/O = 4 (succinate span) and 6 (beta-hydroxybutyrate span). Only "+" can be written. -/
def MM3a : Statement where
  id := "MM3a"
  text := "succinate oxidation drives proton translocation (H+/O ~ 4)"
  claim := .effect succinate .pos (.process etProtonTx)
  evidence := [ev_mm67 (n := "->H+/O close to 4 for succinate; constant between pH 5.5 and 8.5")]

def MM3b : Statement where
  id := "MM3b"
  text := "beta-hydroxybutyrate oxidation drives proton translocation (H+/O ~ 6)"
  claim := .effect bHB .pos (.process etProtonTx)
  evidence := [ev_mm67 (n := "->H+/O close to 6 for beta-hydroxybutyrate")]

/-- Uncouplers raise the proton conductance of the inner membrane. Confirms M4. One agent per claim. -/
def MM4_DNP : Statement where
  id := "MM4_DNP"; text := "DNP increases inner-membrane proton conductance"
  claim := .effect DNP .pos (.phenotype permeability)
  evidence := [ev_mm67 (n := "increase the effective proton conductance of the M phase")]
def MM4_FCCP : Statement where
  id := "MM4_FCCP"; text := "FCCP increases inner-membrane proton conductance"
  claim := .effect FCCP .pos (.phenotype permeability)
  evidence := [ev_mm67 (n := "increase the effective proton conductance of the M phase")]
def MM4_gram : Statement where
  id := "MM4_gram"; text := "gramicidin increases inner-membrane proton conductance"
  claim := .effect gramicidin .pos (.phenotype permeability)
  evidence := [ev_mm67 (n := "increase the effective proton conductance of the M phase")]

/-- Null result: uncouplers do not change the initial H+/O. Best available: refute a "−" effect.
    This is weaker than "no effect": refuting `.neg` is still compatible with `.pos`. -/
def MM5 : Statement where
  id := "MM5"
  text := "DNP lowers the initial H+/O quotient"
  claim := .effect DNP .neg (.process etProtonTx)
  evidence := [ev_mm67 .refutes "do not change the initial ->H(+)/O quotients"]

/-- So uncouplers do not act on a chemical intermediate (refutes SL4). -/
def ev_MM_vs_SL4 : Evidence := ev_mm67 .refutes "uncoupler-sensitive chemical intermediates do not exist between the respiratory-chain system and the effective proton-translocating mechanism"
def ev_MM_vs_SL1 : Evidence := ev_mm67 .refutes "uncoupler-sensitive chemical intermediates do not exist"
def ev_MM_for_M1 : Evidence := ev_mm67 (n := "increase in proton conductance accounts quantitatively for uncoupling action")
def ev_MM_for_M2 : Evidence := ev_mm67 (n := "respiration-driven H+ translocation measured")
def ev_MM_for_M4 : Evidence := ev_mm67 (n := "uncouplers increase proton conductance")
```

Could not express:
- The stoichiometries H+/O ≈ 4 and ≈ 6 and that they are constant from pH 5.5 to 8.5.
- That MM3a/b are about *spans* of the respiratory chain fed by those substrates, not the
  substrates acting as agents.
- "Accounts quantitatively for their uncoupling action": a quantitative sufficiency argument.
- The methodological findings (apparent H+/O changes from backlash, anions, Na+): these are claims
  about measurement artefacts, with no claim form.
- The null result (H+/O unchanged) as a real "no effect" (`Sign` has no zero).
- The "loop 3" configuration (a structural/topological claim).
- Tissue/species (rat liver mitochondria), preparation (isolated organelle), pH range: only in `note`.
- One claim per agent: three uncouplers need three statements.

### Hinkle & Horstman 1971, PMID 4330063 (`[summary]`)

```lean
def ev_hinkle71 (pol : Opinion.Polarity := .supports) (n : String) : Evidence :=
  { pmid := 4330063, year := 1971, kind := .inVitro, polarity := pol,
    note := s!"[summary] RESULT. Bovine (NCBITaxon:9913) heart submitochondrial particles, inside-out. {n}" }

/-- Respiration (NADH or succinate oxidation) drives proton uptake into inside-out particles.
    Confirms M2 in a second species and the opposite membrane orientation. -/
def HH1 : Statement where
  id := "HH1"
  text := "respiration drives proton transport into inside-out submitochondrial particles"
  claim := .effect respChain .pos (.process protonTx)
  evidence := [ev_hinkle71 (n := "protons taken up during NADH or succinate oxidation, interior acidified")]

/-- Uncouplers abolish the net uptake. "Net accumulation inside" has no term; written as amount of H+. -/
def HH2 : Statement where
  id := "HH2"
  text := "uncouplers reduce respiration-driven proton accumulation"
  claim := .effect uncoupler .neg (.amount hydron)
  evidence := [ev_hinkle71 (n := "uptake abolished by uncouplers")]

def ev_HH_for_M1 : Evidence := ev_hinkle71 (n := "supports respiration-driven proton translocation as the energy-conserving step")
def ev_HH_for_M2 : Evidence := ev_hinkle71 (n := "proton uptake during respiration")
def ev_HH_vs_SL1 : Evidence := ev_hinkle71 .refutes "energy conserved as a proton gradient, not (per the brief) a chemical intermediate"
```

Could not express:
- Membrane orientation (inside-out): the same claim as MM1 but with protons moving the *other way*
  relative to the matrix. `Sign` cannot say which way across a membrane; HH1 and MM1 look identical.
- "Abolished" (to zero) vs "reduced": both are `.neg`.
- Two electron donors (NADH, succinate) under one claim.
- "Later work from the same lab" (artificial-gradient ATP synthesis in SMPs) cannot be cited: an
  `Evidence` needs a PMID and none is given.
- HH2 is clumsy: there is no "net amount inside compartment X" target, so `.amount hydron` stands in.

### Racker & Stoeckenius 1974, PMID 4272126 (`[summary]`)

```lean
def ev_racker74 (pol : Opinion.Polarity := .supports) (n : String) : Evidence :=
  { pmid := 4272126, year := 1974, kind := .inVitro, polarity := pol,
    note := s!"[summary] RESULT. Reconstituted phospholipid vesicles: bacteriorhodopsin (H. salinarum, NCBITaxon:2242) + bovine heart F1Fo ATPase (NCBITaxon:9913). {n}" }

def RS1 : Statement where
  id := "RS1"
  text := "light drives proton uptake by bacteriorhodopsin"
  claim := .mediatedBy light .pos (.process protonTx) (.activity bR)
  evidence := [ev_racker74 (n := "on illumination the vesicles took up protons")]

/-- The key result: light makes ATP via bR, with no shared electron carrier. -/
def RS2 : Statement where
  id := "RS2"
  text := "light drives ATP synthesis via bacteriorhodopsin in reconstituted vesicles"
  claim := .mediatedBy light .pos (.process pmfATP) (.activity bR)
  evidence := [ev_racker74 (n := "illuminated vesicles synthesised ATP from ADP and Pi")]

def RS3 : Statement where
  id := "RS3"
  text := "bacteriorhodopsin-driven ATP synthesis runs via proton transport"
  claim := .mediatedBy bR .pos (.process pmfATP) (.process protonTx)
  evidence := [ev_racker74 (n := "abolished by uncouplers")]

def RS4 : Statement where
  id := "RS4"
  text := "oligomycin inhibits ATP synthesis"
  claim := .effect oligomycin .neg (.process pmfATP)
  evidence := [ev_racker74 (n := "ATP synthesis abolished by oligomycin")]

def RS5 : Statement where
  id := "RS5"
  text := "uncouplers inhibit ATP synthesis"
  claim := .effect uncoupler .neg (.process pmfATP)
  evidence := [ev_racker74 (n := "ATP synthesis abolished by uncouplers")]

def ev_RS_for_M3 : Evidence := ev_racker74 (n := "a proton gradient is sufficient to drive ATP synthesis")
def ev_RS_for_M1 : Evidence := ev_racker74 (n := "coupling via protons between proteins from unrelated organisms")
def ev_RS_vs_SL1 : Evidence := ev_racker74 .refutes "the two proteins come from unrelated organisms and share no chemical intermediate"
```

Could not express:
- The chimeric system: two proteins from two species (archaeon + cow) in one artificial membrane.
  There is one implicit species per statement, and here even that is missing.
- Reconstitution as an evidence type (ECO:0000003). `EvidenceKind` collapses it into `.inVitro`.
- Light as an agent: forced into `Entity .chemical` with an NCIT ID; `Kind` has no stimulus.
- The F1Fo complex: only the beta subunit (`ATPsynB`) can stand in, and it is not even used in RS2-5
  because there is no way to say "bR and ATPase together".
- The "no shared intermediate, therefore a gradient is sufficient" inference: a logical argument
  across statements, not a claim.

### Assembling the controversy (after all six papers)

```lean
/-- Chemiosmotic coupling. -/
def M1 : Statement where
  id := "M1"
  text := "oxidative phosphorylation is coupled to respiration via proton translocation (Mitchell)"
  claim := M1_claim
  evidence := [ev_mitchell61, ev_J_for_M1, ev_MM_for_M1, ev_HH_for_M1, ev_RS_for_M1]

/-- Chemical coupling, the rival. Same agent and target as M1, different mediator. -/
def SL1 : Statement where
  id := "SL1"
  text := "oxidative phosphorylation is coupled to respiration via a high-energy chemical intermediate (Slater)"
  claim := SL1_claim
  evidence := [ev_slater53, ev_J_vs_SL1, ev_MM_vs_SL1, ev_HH_vs_SL1, ev_RS_vs_SL1]

/-- Mitchell's predictions, with their tests attached. Prediction and test are now
    indistinguishable items in one list. -/
def M2' : Statement := { M2 with evidence := M2.evidence ++ [ev_MM_for_M2, ev_HH_for_M2] }
def M3' : Statement := { M3 with evidence := M3.evidence ++ [ev_J_for_M3, ev_RS_for_M3] }
def M4' : Statement := { M4 with evidence := M4.evidence ++ [ev_MM_for_M4] }
def SL4' : Statement := { SL4 with evidence := SL4.evidence ++ [ev_MM_vs_SL4] }
```

With the standard `EvidenceModel`, `M1` fuses one `.review` and four `.inVitro` supports; `SL1`
fuses one `.review` support and four `.inVitro` refutations. So the arithmetic does come out with M1
believed and SL1 disbelieved, but only because the founding papers are wrongly counted as reviews
(which inflates both) and because nothing stops M1 and SL1 being believed together.

### Yoshino 2011, PMID 21982712 (real abstract; mice)

`EvidenceKind` has no "in vivo animal study"; the nearest is `.mechanistic` ("in vivo / ex vivo
mechanistic study"), used for all four mouse papers.

```lean
def ev_yoshino11 (n : String) : Evidence :=
  { pmid := 21982712, year := 2011, kind := .mechanistic, polarity := .supports,
    note := s!"RESULT. Mouse (NCBITaxon:10090). {n}" }

/-- HFD lowers NAMPT-mediated NAD+ biosynthesis. A diet has no Kind; forced into `.chemical`. -/
def Y11_1 : Statement where
  id := "Y11_1"
  text := "high-fat diet impairs NAMPT-mediated NAD+ biosynthesis in metabolic organs"
  claim := .mediatedBy highFatDiet .neg (.process NADbiosyn) (.activity NAMPT_m)
  evidence := [ev_yoshino11 "NAMPT-mediated NAD(+) biosynthesis is severely compromised in metabolic organs by high-fat diet (HFD)"]

/-- The headline: NMN improves glucose tolerance by restoring NAD+, in HFD-induced T2D mice.
    "Ameliorates impaired glucose tolerance" = `.neg` on an MP term that already means "worse". -/
def Y11_2 : Statement where
  id := "Y11_2"
  text := "NMN ameliorates glucose intolerance by restoring NAD+ (HFD-induced T2D mice)"
  claim := .mediatedBy NMN .neg (.phenotype impGlcTol) (.amount NADp)
  evidence := [ev_yoshino11 "HFD-induced T2D model. ameliorates glucose intolerance by restoring NAD(+) levels"]

/-- Hepatic insulin sensitivity. "Hepatic" can only be squeezed into a separate site statement. -/
def Y11_3 : Statement where
  id := "Y11_3"
  text := "NMN enhances hepatic insulin sensitivity"
  claim := .effect NMN .pos (.phenotype incInsSens)
  evidence := [ev_yoshino11 "liver. NMN also enhances hepatic insulin sensitivity"]

def Y11_3site : Statement where
  id := "Y11_3site"
  text := "NMN enhances insulin sensitivity, at the liver"
  claim := .mediatedBy NMN .pos (.phenotype incInsSens) (.site liver)
  evidence := [ev_yoshino11 "site encoded as mediator"]

/-- "Restores gene expression ... partly through SIRT1": one statement per pathway; sign is a guess,
    because "restores" means "back toward normal", not up or down. -/
def Y11_4 : Statement where
  id := "Y11_4"
  text := "NMN restores oxidative-stress-response gene expression, partly via SIRT1"
  claim := .mediatedBy NMN .pos (.process oxStressResp) (.activity SIRT1_m)
  evidence := [ev_yoshino11 "restores gene expression related to oxidative stress ... partly through SIRT1 activation"]
def Y11_5 : Statement where
  id := "Y11_5"
  text := "NMN restores inflammatory-response gene expression, partly via SIRT1"
  claim := .mediatedBy NMN .neg (.process inflamResp) (.activity SIRT1_m)
  evidence := [ev_yoshino11 "restores gene expression related to ... inflammatory response ... partly through SIRT1 activation"]
def Y11_6 : Statement where
  id := "Y11_6"
  text := "NMN restores circadian-rhythm gene expression, partly via SIRT1"
  claim := .mediatedBy NMN .pos (.process circadian) (.activity SIRT1_m)
  evidence := [ev_yoshino11 "restores gene expression related to ... circadian rhythm, partly through SIRT1 activation"]

/-- Aging lowers NAD+ and NAMPT. Here aging (a GO process) is the agent. -/
def Y11_7 : Statement where
  id := "Y11_7"
  text := "aging decreases NAD+ in multiple organs"
  claim := .effect aging .neg (.amount NADp)
  evidence := [ev_yoshino11 "NAD(+) and NAMPT levels show significant decreases in multiple organs during aging"]
def Y11_8 : Statement where
  id := "Y11_8"
  text := "aging decreases NAMPT in multiple organs"
  claim := .effect aging .neg (.amount NAMPT_m)
  evidence := [ev_yoshino11 "NAD(+) and NAMPT levels show significant decreases in multiple organs during aging"]

/-- Age-induced T2D: same claim shape as Y11_2, so it would silently merge with the HFD result. -/
def Y11_9 : Statement where
  id := "Y11_9"
  text := "NMN improves glucose intolerance and lipid profile in age-induced T2D mice"
  claim := .effect NMN .neg (.phenotype impGlcTol)
  evidence := [ev_yoshino11 "age-induced T2D model. NMN improves glucose intolerance and lipid profiles"]
def Y11_10 : Statement where
  id := "Y11_10"
  text := "NMN improves plasma lipid profile in age-induced T2D mice"
  claim := .effect NMN .neg (.phenotype abnCircLipid)
  evidence := [ev_yoshino11 "age-induced T2D model. improves ... lipid profiles"]
```

Could not express:
- Disease model as context: "HFD-induced T2D" vs "age-induced T2D". MONDO:0005148 can't be attached
  to a statement; the model is only in `note`. Y11_2 and Y11_9 are the same claim in two models.
- Species, strain, sex, age of the mice, NMN dose, route, duration: none in fields (dose/route are
  not in the abstract either).
- Diet as an exposure: `highFatDiet` has to pretend to be a chemical (EFO is not in the schema's
  ontology list).
- "Restores": a return to baseline, relative to a diseased state. `Sign` only has up/down, so
  Y11_4..6 encode a guessed direction.
- "Partly through SIRT1": partial mediation. `mediatedBy` is all-or-nothing.
- "In multiple organs": a set of tissues. One `.site` per statement at most, and only via the
  mediator slot.
- Direction double-counting: MP terms like "impaired glucose tolerance" already contain a direction,
  so `.neg` on them is a double negative ("less impaired").
- Effect sizes and significance.

### Gomes 2013, PMID 24360282 (real abstract; mice)

```lean
def ev_gomes13 (pol : Opinion.Polarity := .supports) (n : String) : Evidence :=
  { pmid := 24360282, year := 2013, kind := .mechanistic, polarity := pol,
    note := s!"RESULT. Mouse (NCBITaxon:10090), young vs old. {n}" }

/-- Aging specifically lowers mitochondrially-encoded OXPHOS subunits (not nuclear-encoded ones).
    GO:0140053 "mitochondrial gene expression" is the nearest process. -/
def G13_1 : Statement where
  id := "G13_1"
  text := "aging decreases mitochondrially encoded OXPHOS subunits"
  claim := .effect aging .neg (.process mitoGeneExpr)
  evidence := [ev_gomes13 (n := "specific loss of mitochondrial, but not nuclear, encoded OXPHOS subunits")]

/-- Mechanism: aging -> nuclear NAD+ decline -> HIF-1alpha accumulation -> loss of mito-encoded subunits. -/
def G13_2 : Statement where
  id := "G13_2"
  text := "nuclear NAD+ decline causes HIF-1alpha accumulation under normoxia"
  claim := .effect NADp .neg (.amount HIF1A_m)
  evidence := [ev_gomes13 (n := "decline in nuclear NAD(+) and the accumulation of HIF-1alpha under normoxic conditions")]

def G13_3 : Statement where
  id := "G13_3"
  text := "the age-related loss of mito-encoded OXPHOS runs via HIF-1alpha accumulation"
  claim := .mediatedBy aging .neg (.process mitoGeneExpr) (.amount HIF1A_m)
  evidence := [ev_gomes13 (n := "pseudohypoxic state ... induced by ... accumulation of HIF-1alpha")]

/-- The rival route, explicitly ruled out: PGC-1alpha/beta. Expressible as a refuted mediatedBy. -/
def G13_4 : Statement where
  id := "G13_4"
  text := "the age-related loss of mito-encoded OXPHOS runs via PGC-1alpha"
  claim := .mediatedBy aging .neg (.process mitoGeneExpr) (.activity PGC1A_m)
  evidence := [ev_gomes13 .refutes "an alternate PGC-1alpha/beta-independent pathway"]

/-- SIRT1 deletion accelerates the decline: genetic loss-of-function evidence that SIRT1 protects. -/
def G13_5 : Statement where
  id := "G13_5"
  text := "SIRT1 maintains mitochondrial gene expression"
  claim := .effect SIRT1_m .pos (.process mitoGeneExpr)
  evidence := [ev_gomes13 (n := "Deleting SIRT1 accelerates this process (knockout)")]

/-- Raising NAD+ (NMN, per the brief) restores mitochondrial function in old mice, SIRT1-dependently. -/
def G13_6 : Statement where
  id := "G13_6"
  text := "raising NAD+ in old mice restores mitochondrial function via SIRT1"
  claim := .mediatedBy NMN .pos (.process oxphos) (.activity SIRT1_m)
  evidence := [ev_gomes13 (n := "raising NAD(+) levels in old mice restores mitochondrial function to that of a young mouse in a SIRT1-dependent manner. Agent NMN per brief; abstract says only 'raising NAD+'")]

def G13_7 : Statement where
  id := "G13_7"
  text := "NMN raises NAD+ in old mice"
  claim := .effect NMN .pos (.amount NADp)
  evidence := [ev_gomes13 (n := "raising NAD(+) levels in old mice")]
```

Could not express:
- Age as context ("old mice", "young mouse" as the reference level). `aging` can be an agent, but the
  age of the animals in G13_6 cannot be stated.
- Compartment: *nuclear* NAD+ vs total NAD+. `.amount NADp` has no location.
- "Under normoxic conditions" (an environmental condition).
- "Mitochondrial but NOT nuclear encoded subunits": a contrast with a negative half. The negative
  half ("aging does not change nuclear-encoded subunits") has no clean form (no zero sign, no term).
- The perturbation type: SIRT1 knockout (G13_5) vs. NAD+ supplementation (G13_6). Evidence has no
  "genetic loss-of-function" field; the note carries it.
- "Restores to that of a young mouse": a quantitative, reference-relative claim.
- The full causal chain aging → NAD+ → HIF-1α → mito gene expression must be split into pairs.
  (BioLean's `Derivation` can chain signs, but the statements carry no shared context to check.)
- "Reversible": a claim about the process, not an effect.

### Mills 2016, PMID 28068222 (real abstract; mice)

```lean
def ev_mills16 (n : String) : Evidence :=
  { pmid := 28068222, year := 2016, kind := .mechanistic, polarity := .supports,
    note := s!"RESULT. Wild-type C57BL/6N mice (NCBITaxon:10090; strain ?:unverified), regular chow, oral NMN for 12 months during normal aging. {n}" }

def Mi16_1 : Statement where
  id := "Mi16_1"
  text := "oral NMN raises tissue NAD+"
  claim := .effect NMN .pos (.amount NADp)
  evidence := [ev_mills16 "Orally administered NMN was quickly utilized to synthesize NAD+ in tissues"]

/-- "Suppressed age-associated body weight gain": `.neg` on MP "increased body weight". -/
def Mi16_2 : Statement where
  id := "Mi16_2"
  text := "NMN suppresses age-associated body weight gain"
  claim := .effect NMN .neg (.phenotype incBodyWeight)
  evidence := [ev_mills16 "NMN suppressed age-associated body weight gain"]

def Mi16_3 : Statement where
  id := "Mi16_3"
  text := "NMN enhances energy metabolism"
  claim := .effect NMN .pos (.phenotype incEnergyExp)
  evidence := [ev_mills16 "enhanced energy metabolism (mapped to MP 'increased energy expenditure')"]

/-- "Promoted physical activity": the nearest MP term is "hyperactivity", which is pathological. -/
def Mi16_4 : Statement where
  id := "Mi16_4"
  text := "NMN promotes physical activity"
  claim := .effect NMN .pos (.phenotype hyperactivity)
  evidence := [ev_mills16 "promoted physical activity"]

def Mi16_5 : Statement where
  id := "Mi16_5"
  text := "NMN improves insulin sensitivity in aging mice"
  claim := .effect NMN .pos (.phenotype incInsSens)
  evidence := [ev_mills16 "improved insulin sensitivity"]

def Mi16_6 : Statement where
  id := "Mi16_6"
  text := "NMN improves plasma lipid profile in aging mice"
  claim := .effect NMN .neg (.phenotype abnCircLipid)
  evidence := [ev_mills16 "improved ... plasma lipid profile"]

def Mi16_7 : Statement where
  id := "Mi16_7"
  text := "NMN ameliorates age-associated decline in eye function"
  claim := .effect NMN .neg (.phenotype abnEyePhys)
  evidence := [ev_mills16 "ameliorated eye function"]

/-- Skeletal muscle mitochondria, with the tissue in the mediator slot. -/
def Mi16_8 : Statement where
  id := "Mi16_8"
  text := "NMN enhances mitochondrial oxidative metabolism in skeletal muscle"
  claim := .mediatedBy NMN .pos (.process oxphos) (.site skMuscle)
  evidence := [ev_mills16 "enhanced mitochondrial oxidative metabolism and mitonuclear protein imbalance in skeletal muscle"]

/-- "Prevented age-associated gene expression changes": the agent opposes aging's effect. -/
def Mi16_9 : Statement where
  id := "Mi16_9"
  text := "NMN prevents age-associated gene expression changes in metabolic organs"
  claim := .effect NMN .neg (.process aging)
  evidence := [ev_mills16 "NMN prevented age-associated gene expression changes in key metabolic organs (encoded crudely as NMN -| aging)"]
```

Could not express:
- Duration (12 months), age at start, route (oral, drinking water), dose (not in the abstract):
  no fields. All in `note`.
- Strain C57BL/6N and diet (regular chow), sex: no fields; strain has no NCBITaxon ID.
- The negative safety result ("without any obvious toxicity or deleterious effects"): there is no
  target "toxicity" in the schema's vocabulary, and a refuted "NMN → toxicity" would be weaker than
  "no toxicity observed".
- "Prevented age-associated change" (an interaction: NMN × aging on gene expression). Mi16_9 bends
  this into "NMN inhibits aging", which overclaims.
- "Mitonuclear protein imbalance": the abstract's wording is ambiguous, and no term found.
- The cross-paper link "consistent with these phenotypes" (molecular result explains phenotype).
- Good MP terms are "abnormal ..." terms; healthy improvements (more activity) map badly.

### Das 2018, PMID 29570999 (real abstract; mice)

```lean
def ev_das18 (n : String) : Evidence :=
  { pmid := 29570999, year := 2018, kind := .mechanistic, polarity := .supports,
    note := s!"RESULT. Mouse (NCBITaxon:10090), elderly. {n}" }

/-- Endothelial SIRT1 mediates pro-angiogenic signals from myocytes. "Endothelial" cannot be said:
    there is no Target for a cell type (CL:0000115 exists as an Entity but is unusable). -/
def D18_1 : Statement where
  id := "D18_1"
  text := "endothelial SIRT1 promotes angiogenesis in response to myocyte signals"
  claim := .effect SIRT1_m .pos (.process angiogenesis)
  evidence := [ev_das18 "SIRT1 in endothelial cells is a key mediator of pro-angiogenic signals secreted from myocytes"]

/-- NMN raises capillary density via SIRT1. `.neg` on "decreased capillary density". -/
def D18_2 : Statement where
  id := "D18_2"
  text := "NMN increases capillary density via SIRT1 in elderly mice"
  claim := .mediatedBy NMN .neg (.phenotype decCapDensity) (.activity SIRT1_m)
  evidence := [ev_das18 "promoting SIRT1-dependent increases in capillary density"]

/-- Endurance up, via more capillaries. Two-step mediation needs two statements. -/
def D18_3 : Statement where
  id := "D18_3"
  text := "NMN increases endurance in elderly mice via capillary density"
  claim := .mediatedBy NMN .pos (.phenotype enhEndurance) (.process sproutAngio)
  evidence := [ev_das18 "increases endurance in elderly mice by promoting SIRT1-dependent increases in capillary density"]

def D18_4 : Statement where
  id := "D18_4"
  text := "NMN improves blood flow in elderly mice"
  claim := .effect NMN .pos (.phenotype muscleBloodFlow)
  evidence := [ev_das18 "improves blood flow"]

/-- H2S raises endothelial NAD+. -/
def D18_5 : Statement where
  id := "D18_5"
  text := "hydrogen sulfide raises endothelial NAD+"
  claim := .effect H2S .pos (.amount NADp)
  evidence := [ev_das18 "hydrogen sulfide (H2S), a DR mimetic and regulator of endothelial NAD+ levels"]

/-- The NMN effect is augmented by H2S or exercise. Only a stand-alone H2S effect can be written. -/
def D18_6 : Statement where
  id := "D18_6"
  text := "H2S increases capillary density (augments NMN)"
  claim := .effect H2S .neg (.phenotype decCapDensity)
  evidence := [ev_das18 "an effect augmented by exercise or increasing the levels of hydrogen sulfide"]
```

Could not express:
- Cell type: SIRT1 *in endothelial cells*; NAD+ *in endothelium*; signals *from myocytes*. Target has
  `.site` for anatomy only, nothing for `.cellType`.
- Paracrine signalling between two cell types (myocyte → endothelial cell).
- Synergy/interaction: NMN effect "augmented by exercise or H2S". No interaction claim. Exercise
  has no Kind at all (not attempted).
- Age as context ("elderly mice") — only in `note`.
- "H2S is a DR mimetic": a functional-analogy claim.
- Two-step mediation (NMN → SIRT1 → capillary density → endurance) in one statement.
- Blood flow: no verified MP term for skeletal muscle blood flow (`?:unverified`).
- Quantities (how much more endurance, capillaries).

### Yoshino 2021, PMID 33888596 (real abstract; human RCT)

```lean
def ev_yoshino21 (n : String) : Evidence :=
  { pmid := 33888596, year := 2021, kind := .rct, polarity := .supports,
    note := s!"RESULT. 10-week randomized, placebo-controlled, double-blind trial (NCT03151239). Human (NCBITaxon:9606) postmenopausal (EFO:0002721) women with prediabetes (MONDO:0006920), overweight (HP:0025502) or obese (HP:0001513). {n}" }

/-- Insulin-stimulated glucose disposal (hyperinsulinemic-euglycemic clamp). -/
def Y21_1 : Statement where
  id := "Y21_1"
  text := "NMN increases insulin-stimulated glucose disposal in prediabetic women"
  claim := .effect NMN .pos (.process insGlcImport)
  evidence := [ev_yoshino21 "Insulin-stimulated glucose disposal ... increased after NMN supplementation but did not change after placebo"]

/-- Muscle insulin sensitivity, tissue via the mediator slot. -/
def Y21_2 : Statement where
  id := "Y21_2"
  text := "NMN increases skeletal muscle insulin sensitivity"
  claim := .mediatedBy NMN .pos (.phenotype incInsSens) (.site skMuscle)
  evidence := [ev_yoshino21 "NMN increases muscle insulin sensitivity"]

/-- Insulin signalling: phosphorylation of AKT and mTOR. "Phosphorylation" is written as activity. -/
def Y21_3 : Statement where
  id := "Y21_3"
  text := "NMN increases insulin-stimulated AKT phosphorylation in muscle"
  claim := .effect NMN .pos (.activity AKT1_h)
  evidence := [ev_yoshino21 "skeletal muscle insulin signaling [phosphorylation of protein kinase AKT ...] increased"]
def Y21_4 : Statement where
  id := "Y21_4"
  text := "NMN increases insulin-stimulated mTOR phosphorylation in muscle"
  claim := .effect NMN .pos (.activity MTOR_h)
  evidence := [ev_yoshino21 "... and mechanistic target of rapamycin (mTOR)] increased"]

def Y21_5 : Statement where
  id := "Y21_5"
  text := "NMN increases insulin signalling in muscle"
  claim := .effect NMN .pos (.process insSignal)
  evidence := [ev_yoshino21 "skeletal muscle insulin signaling ... increased"]

/-- Expression of PDGFRB (an mRNA/gene-expression result written as protein amount). -/
def Y21_6 : Statement where
  id := "Y21_6"
  text := "NMN up-regulates PDGFRB expression in muscle"
  claim := .effect NMN .pos (.amount PDGFRB_h)
  evidence := [ev_yoshino21 "NMN supplementation up-regulated the expression of platelet-derived growth factor receptor beta"]

def Y21_7 : Statement where
  id := "Y21_7"
  text := "NMN promotes muscle remodeling"
  claim := .effect NMN .pos (.process muscleAdapt)
  evidence := [ev_yoshino21 "other genes related to muscle remodeling"]
```

Could not express:
- Population (postmenopausal, prediabetic, overweight/obese women), n, sex: only in `note`.
  The disease and the menopausal state are context, not agent or target, and have no slot.
- Duration (10 weeks); dose (not in abstract).
- The placebo comparison and the null result in the placebo arm ("did not change after placebo").
- The species jump: Y21_1 has the same claim shape as the mouse results on `incInsSens`; Y21_2 and
  Mi16_5 differ only by the `.site` hack. If written identically, a human RCT and a mouse study fuse
  into one opinion, with no record that they are different species. Conversely, `SIRT1_m` and a human
  SIRT1 (Q96EB6) are different entities, so protein-level claims never meet across species.
- "Phosphorylation" (a PTM) vs "activity"; "expression" (mRNA) vs "amount" (protein).
- Measurement method (hyperinsulinemic-euglycemic clamp).
- Effect sizes, CIs, p-values.
- That "insulin sensitivity" is muscle-specific and hepatic insulin sensitivity was not the outcome.

### Check

All Lean in section 2 was concatenated into one scratch file outside the repo and checked with
`lake env lean` against the current BioLean build: it compiles with no errors. With
`EvidenceModel.standard`, `M1.opinion = ⟨b=0.846 d=0.000 u=0.153⟩` and
`SL1.opinion = ⟨b=0.230 d=0.615 u=0.153⟩`. Slater's data-free proposal alone keeps 0.23 belief
in a hypothesis that four experiments refute.

## 3. Fit table

| Aspect | Expressible? | How |
|---|---|---|
| Direction of effect | partial | `Sign` `.pos`/`.neg`. No "no effect", no "restores to normal", no vectorial (which side of a membrane) direction. MP terms already carry a direction ("impaired ..."), so signs become double negatives. |
| Quantitative result | no | Only `note` text (H+/O = 4 and 6, pH ranges, effect sizes). |
| Species/strain | partial | Only implicitly, via species-specific UniProt accessions (`SIRT1_m` vs human). Chemicals and GO processes carry no species. Strain only in `note`. |
| Age/stage | partial | `aging` (GO:0007568) can be an *agent*; "old mice" as context only in `note`. |
| Tissue/cell | partial | `.site` exists as a target, so tissue gets smuggled into the `mediatedBy` slot (as GLP-1 S9c does). No target or context for `.cellType` (CL) at all; GO cellular components have no `Kind`. |
| Disease model | no | `Entity .disease` exists, but no slot for "in HFD-induced T2D mice". |
| Dose/duration | no | `note` only. |
| Hypothesis vs result | no | No field. `EvidenceKind` has no `hypothesis`, so proposing papers must be mis-typed (here `.review`, worth 0.6). Predictions and their tests sit in the same evidence list. |
| Rival hypotheses | partial | Two `mediatedBy` statements with the same agent and target and different mediators, plus `.refutes` evidence. Rivalry/exclusivity is not recorded; both can be believed at once. Refuted rival routes (PGC-1α in Gomes) work well. |
| Evidence type | partial | 8 coarse kinds. In vivo mouse phenotyping must be `.mechanistic`; reconstitution, knockout and acid-bath experiments all collapse to `.inVitro`/`.mechanistic`. No ECO. |
| Cross-species transfer | no (and unsafe) | Nothing records species, so mouse and human evidence on the same chemical/phenotype claim fuse silently, and `Derivation.viaAmount` will chain a mouse `NMN → NAD+` with a human `NAD+ → ...`. Protein claims split by species instead and never meet (no orthology link). |
| Negative results | partial | `.refutes` on a signed claim. True nulls ("does not change H+/O", "no change with placebo", "no toxicity") cannot be stated: refuting `.neg` still allows `.pos`. |

## 4. Verdict

(a) Chemiosmotic papers. The core of this controversy fits BioLean's design surprisingly well:
two `mediatedBy` claims with one agent, one target and rival mediators, with later experiments
attached as `.supports` to one and `.refutes` to the other, and the fused opinions come out the
right way. But the schema cannot say that M1 and SL1 exclude each other, cannot tell a hypothesis
or prediction from a test (Mitchell 1961 and Slater 1953 have to masquerade as reviews), and its
`Sign` has no way to say "unchanged", which is exactly the shape of the most decisive result
(Mitchell & Moyle: uncouplers leave H+/O unchanged). The physics is awkward: a proton gradient is a
difference across a membrane, and the schema only offers "amount of hydron" with no compartment,
no membrane (GO CC has no `Kind`) and no orientation, so inside-out particles look the same as
intact mitochondria. Light, chimeric two-species vesicles and stoichiometries (H+/O = 4, 6) all
fall into the `note` string.

(b) NMN mouse papers. These fit worse, because their content is mostly context: who (strain, sex,
age), what model (HFD vs age-induced T2D), how much and how long (12 months, oral), and where (liver,
skeletal muscle, endothelial cells), and none of that has a field. The claim shape "NMN → phenotype"
is easy to write, but it strips away everything that makes the results comparable, so the 2011
HFD result, the 2016 aging result and the 2021 human RCT can collapse into one fused statement with
no record that one is human. Cell-type claims (endothelial SIRT1) cannot be written at all,
"restores"/"prevents age-associated change" has to be bent into up/down signs, and MP's
"abnormal/impaired" terms force double negatives. Cross-species use is actively unsafe: chemical
claims chain across species without warning, while protein claims never meet. The `.mechanistic`
evidence kind is also a poor label for in vivo phenotype studies.

## 5. Minimal extension

The gaps above reduce to six missing things: (1) a place for context, (2) kinds for membranes,
species and exposures, (3) a gradient target, (4) a true null, (5) hypothesis/prediction/rival
links, (6) a measured value. The smallest change that covers them is below: one new file
(`Context.lean`, 40 lines) and about 30 added lines across three existing files. No existing
constructor or field changes, so every current statement still compiles unchanged.

The key design choice: context goes *inside the claim*, as `Claim.inContext ctx c`, not on the
evidence. That makes a mouse claim and a human claim different claims, so they no longer fuse into
one opinion, and the existing `Derivation` rules (which only chain bare `.effect` claims) cannot
chain them by accident. Cross-species transfer then has to be an explicit, new derivation rule
(not proposed here). Rivals and predictions are id lists on `Statement`, which is the least
machinery that records the structure; a checker that warns when two rivals are both believed is a
one-line fold over them.

Tested: these changes were applied to a scratch copy of the repo (not this repo). `lake build
BioLean` and `lake build BioLeanLib` (including the GLP-1 library and Ozempic example) both succeed,
and the examples below compile against it. The weights for `.animal` (0.6) and `.reconstitution`
(0.7) are placeholders, like the existing ones.

### The change

```lean
import BioLean.Ontology

/-!
# Context

Where a claim holds. Every field is optional; an empty context means "no restriction stated".
-/

namespace BioLean

/-- The experimental system. -/
inductive System
  | inVivo | exVivo | inVitro | reconstituted
  deriving DecidableEq, Repr

structure Context where
  taxa      : List (Entity .taxon) := []      -- a list: reconstituted chimeras have two
  strain    : Option String := none            -- e.g. "C57BL/6N" (no NCBITaxon ID)
  sex       : Option String := none            -- PATO:0000383 female / PATO:0000384 male
  stage     : Option String := none            -- "aged", "12 months", "postmenopausal"
  anatomy   : Option (Entity .anatomy) := none
  cellType  : Option (Entity .cellType) := none
  component : Option (Entity .component) := none
  disease   : Option (Entity .disease) := none -- disease, or disease model, or population
  exposures : List (Entity .exposure) := []
  dose      : Option String := none
  duration  : Option String := none
  system    : Option System := none
  deriving Repr

instance : ToString Context where
  toString x :=
    let parts : List String :=
      (x.taxa.map toString) ++ (x.strain.toList) ++ (x.stage.toList) ++
      (x.anatomy.toList.map toString) ++ (x.cellType.toList.map toString) ++
      (x.component.toList.map toString) ++ (x.disease.toList.map toString) ++
      (x.exposures.map toString) ++ (x.dose.toList) ++ (x.duration.toList)
    ", ".intercalate parts

end BioLean
```

```diff
diff --git a/BioLean/Ontology.lean b/BioLean/Ontology.lean
index cea5091..42e445e 100644
--- a/BioLean/Ontology.lean
+++ b/BioLean/Ontology.lean
@@ -21,6 +21,9 @@ inductive Kind
   | disease    -- MONDO
   | anatomy    -- UBERON
   | cellType   -- CL
+  | component  -- GO cellular component
+  | taxon      -- NCBITaxon
+  | exposure   -- EFO / ECTO / XCO: diet, light, exercise, imposed pH jump
   deriving DecidableEq, Repr
 
 /-- A named, grounded thing of kind `k`. -/
diff --git a/BioLean/Claim.lean b/BioLean/Claim.lean
index 5af8ece..84605c4 100644
--- a/BioLean/Claim.lean
+++ b/BioLean/Claim.lean
@@ -1,4 +1,5 @@
 import BioLean.Ontology
+import BioLean.Context
 
 /-!
 # Claims
@@ -56,6 +57,8 @@ inductive Target
   | phenotype (p : Entity .phenotype)
   /-- An anatomical site at which an effect is exerted. -/
   | site (a : Entity .anatomy)
+  /-- An electrochemical gradient of `m` across a membrane `c` (e.g. Δp across GO:0005743). -/
+  | gradient (m : Entity .chemical) (c : Entity .component)
 
 instance : ToString Target where
   toString
@@ -64,6 +67,7 @@ instance : ToString Target where
     | .process p => s!"{p}"
     | .phenotype p => s!"{p}"
     | .site a => s!"site {a}"
+    | .gradient m c => s!"gradient of {m} across {c}"
 
 instance : Repr Target := ⟨fun t _ => toString t⟩
 
@@ -73,11 +77,19 @@ inductive Claim
   | effect {k : Kind} (agent : Entity k) (sign : Sign) (target : Target)
   /-- The `sign`ed effect of `agent` on `target` runs via `mediator`. -/
   | mediatedBy {k : Kind} (agent : Entity k) (sign : Sign) (target : Target) (mediator : Target)
-
-instance : ToString Claim where
-  toString
-    | .effect a s t => s!"{a} {s.arrow} {t}"
-    | .mediatedBy a s t m => s!"{a} {s.arrow} {t}  via  {m}"
+  /-- `agent` has no detectable effect on `target` (a true null, not a refuted sign). -/
+  | noEffect {k : Kind} (agent : Entity k) (target : Target)
+  /-- `c` holds in context `ctx`. Derivation rules only chain bare claims, so contextual claims
+  cannot be silently chained across species or tissues. -/
+  | inContext (ctx : Context) (c : Claim)
+
+def Claim.render : Claim → String
+  | .effect a s t => s!"{a} {s.arrow} {t}"
+  | .mediatedBy a s t m => s!"{a} {s.arrow} {t}  via  {m}"
+  | .noEffect a t => s!"{a} →0 {t}"
+  | .inContext x c => s!"{c.render}  [in {x}]"
+
+instance : ToString Claim := ⟨Claim.render⟩
 
 instance : Repr Claim := ⟨fun c _ => toString c⟩
 
diff --git a/BioLean/Evidence.lean b/BioLean/Evidence.lean
index 17b08d3..a5c8caa 100644
--- a/BioLean/Evidence.lean
+++ b/BioLean/Evidence.lean
@@ -25,6 +25,9 @@ inductive EvidenceKind
   | observational
   | inVitro
   | textMined       -- an automatically extracted relation (PubTator3, INDRA readers)
+  | hypothesis      -- the paper proposes the claim; records provenance, carries no weight
+  | animal          -- in vivo animal phenotype study (not necessarily mechanistic)
+  | reconstitution  -- purified components reassembled (ECO:0000003)
   deriving DecidableEq, Repr
 
 /-- One citation. -/
@@ -34,6 +37,8 @@ structure Evidence where
   kind : EvidenceKind
   polarity : Opinion.Polarity := .supports
   note : String := ""
+  /-- A measured value: (what, value, unit), e.g. ("H+/O", 4, "ratio"). -/
+  quantity : Option (String × ℚ × String) := none
   deriving Repr
 
 /-- A claim with its evidence: the axiom form of BioLean. -/
@@ -42,6 +47,10 @@ structure Statement where
   text : String
   claim : Claim
   evidence : List Evidence
+  /-- Ids of statements that cannot both be true with this one. -/
+  rivals : List String := []
+  /-- Ids of the hypotheses this statement was predicted from. -/
+  predictedBy : List String := []
 
 /-- How much one item of each evidence kind is worth. Values must lie in `[0, 1)`. -/
 class EvidenceModel where
@@ -60,6 +69,9 @@ instance EvidenceModel.standard : EvidenceModel where
     | .observational => 1 / 2
     | .inVitro => 1 / 2
     | .textMined => 3 / 10
+    | .hypothesis => 0
+    | .animal => 3 / 5
+    | .reconstitution => 7 / 10
   nonneg := by intro k; cases k <;> norm_num
   lt_one := by intro k; cases k <;> norm_num
 
```

### Examples rewritten in the extension

```lean
import BioLean

namespace BioLean.Formalisms.Ext

/-! Entities of the new kinds -/
def mouse   : Entity .taxon := ⟨"NCBITaxon:10090", "Mus musculus"⟩
def human   : Entity .taxon := ⟨"NCBITaxon:9606", "Homo sapiens"⟩
def rat     : Entity .taxon := ⟨"NCBITaxon:10116", "Rattus norvegicus"⟩
def cow     : Entity .taxon := ⟨"NCBITaxon:9913", "Bos taurus"⟩
def spinach : Entity .taxon := ⟨"NCBITaxon:3562", "Spinacia oleracea"⟩
def halo    : Entity .taxon := ⟨"NCBITaxon:2242", "Halobacterium salinarum"⟩
def mitoInnerMem : Entity .component := ⟨"GO:0005743", "mitochondrial inner membrane"⟩
def thylakoid    : Entity .component := ⟨"GO:0009579", "thylakoid"⟩
def highFatDiet  : Entity .exposure := ⟨"EFO:0002757", "high fat diet"⟩
def light        : Entity .exposure := ⟨"NCIT:C17732", "visible light"⟩
def phJump       : Entity .exposure := ⟨"?:unverified", "acid-base transition, pH ~4 to ~8, in the dark"⟩

/-! Unchanged entities (as in section 2) -/
def hydron    : Entity .chemical := ⟨"CHEBI:15378", "hydron (H+)"⟩
def DNP       : Entity .chemical := ⟨"CHEBI:42017", "2,4-dinitrophenol"⟩
def succinate : Entity .chemical := ⟨"CHEBI:26806", "succinate"⟩
def NMN       : Entity .chemical := ⟨"CHEBI:16171", "nicotinamide mononucleotide (NMN)"⟩
def NADp      : Entity .chemical := ⟨"CHEBI:15846", "NAD(+)"⟩
def CsquiggleI : Entity .chemical := ⟨"?:unverified", "C~I (hypothetical)"⟩
def bR        : Entity .protein := ⟨"UniProt:P02945", "bacteriorhodopsin (H. salinarum)"⟩
def respChain : Entity .process := ⟨"GO:0022904", "respiratory electron transport chain"⟩
def oxphos    : Entity .process := ⟨"GO:0006119", "oxidative phosphorylation"⟩
def pmfATP    : Entity .process := ⟨"GO:0015986", "proton motive force-driven ATP synthesis"⟩
def etProtonTx: Entity .process := ⟨"GO:0015990", "electron transport coupled proton transport"⟩
def insGlcImport : Entity .process := ⟨"GO:0044381", "glucose import in response to insulin stimulus"⟩
def impGlcTol : Entity .phenotype := ⟨"MP:0005293", "impaired glucose tolerance"⟩
def incInsSens: Entity .phenotype := ⟨"MP:0002891", "increased insulin sensitivity"⟩
def T2D       : Entity .disease := ⟨"MONDO:0005148", "type 2 diabetes mellitus"⟩
def prediabetes : Entity .disease := ⟨"MONDO:0006920", "prediabetes syndrome"⟩
def skMuscle  : Entity .anatomy := ⟨"UBERON:0001134", "skeletal muscle tissue"⟩

/-! ### Chemiosmotic controversy -/

/-- Mitchell. The gradient is now a real mediator, across a named membrane. -/
def M1 : Statement where
  id := "M1"
  text := "respiration drives oxidative phosphorylation via a proton gradient across the inner membrane"
  claim := .mediatedBy respChain .pos (.process oxphos) (.gradient hydron mitoInnerMem)
  rivals := ["SL1"]
  evidence := [
    { pmid := 13771349, year := 1961, kind := .hypothesis, note := "[summary] proposes chemiosmotic coupling" },
    { pmid := 5220864,  year := 1966, kind := .inVitro,        note := "[summary] spinach thylakoids, acid-bath ATP" },
    { pmid := 16742541, year := 1967, kind := .inVitro,        note := "rat liver mitochondria, H+ translocation" },
    { pmid := 4330063,  year := 1971, kind := .inVitro,        note := "[summary] bovine SMPs, H+ uptake" },
    { pmid := 4272126,  year := 1974, kind := .reconstitution, note := "[summary] bR + F1Fo vesicles make ATP in light" } ]

/-- Slater, the rival. -/
def SL1 : Statement where
  id := "SL1"
  text := "respiration drives oxidative phosphorylation via a high-energy chemical intermediate"
  claim := .mediatedBy respChain .pos (.process oxphos) (.amount CsquiggleI)
  rivals := ["M1"]
  evidence := [
    { pmid := 13111237, year := 1953, kind := .hypothesis, note := "[summary] proposes C~I" },
    { pmid := 5220864,  year := 1966, kind := .inVitro,        polarity := .refutes },
    { pmid := 16742541, year := 1967, kind := .inVitro,        polarity := .refutes },
    { pmid := 4330063,  year := 1971, kind := .inVitro,        polarity := .refutes },
    { pmid := 4272126,  year := 1974, kind := .reconstitution, polarity := .refutes } ]

/-- Jagendorf: an imposed gradient (exposure) is enough, in spinach thylakoids, in vitro. -/
def J1 : Statement where
  id := "J1"
  text := "an imposed pH gradient drives ATP synthesis in thylakoids, in the dark"
  claim := .inContext { taxa := [spinach], component := some thylakoid, exposures := [phJump],
                        system := some .inVitro }
            (.effect hydron .pos (.process pmfATP))
  predictedBy := ["M1"]
  evidence := [{ pmid := 5220864, year := 1966, kind := .inVitro, note := "[summary]" }]

/-- Mitchell & Moyle: a quantitative result and a true null. -/
def MM3a : Statement where
  id := "MM3a"
  text := "succinate-span respiration translocates ~4 H+ per O"
  claim := .inContext { taxa := [rat], component := some mitoInnerMem, system := some .inVitro }
            (.effect succinate .pos (.process etProtonTx))
  predictedBy := ["M1"]
  evidence := [{ pmid := 16742541, year := 1967, kind := .inVitro,
                 quantity := some ("H+/O", 4, "ratio"), note := "constant between pH 5.5 and 8.5" }]

def MM5 : Statement where
  id := "MM5"
  text := "DNP does not change the initial H+/O quotient"
  claim := .inContext { taxa := [rat], component := some mitoInnerMem, system := some .inVitro }
            (.noEffect DNP (.process etProtonTx))
  rivals := ["SL1"]   -- the null is what kills uncoupler-sensitive intermediates
  evidence := [{ pmid := 16742541, year := 1967, kind := .inVitro }]

/-- Racker & Stoeckenius: two species in one vesicle, light as an exposure. -/
def RS2 : Statement where
  id := "RS2"
  text := "light drives ATP synthesis via bacteriorhodopsin in reconstituted vesicles"
  claim := .inContext { taxa := [halo, cow], exposures := [light], system := some .reconstituted }
            (.mediatedBy bR .pos (.process pmfATP) (.gradient hydron ⟨"?:unverified", "proteoliposome membrane"⟩))
  predictedBy := ["M1"]
  evidence := [{ pmid := 4272126, year := 1974, kind := .reconstitution, note := "[summary]" }]

/-! ### NMN -/

def hfdT2Dmouse : Context :=
  { taxa := [mouse], disease := some T2D, exposures := [highFatDiet], system := some .inVivo }

def Y11_2 : Statement where
  id := "Y11_2"
  text := "NMN ameliorates glucose intolerance by restoring NAD+ in HFD-induced T2D mice"
  claim := .inContext hfdT2Dmouse (.mediatedBy NMN .neg (.phenotype impGlcTol) (.amount NADp))
  evidence := [{ pmid := 21982712, year := 2011, kind := .animal }]

def Y11_9 : Statement where
  id := "Y11_9"
  text := "NMN ameliorates glucose intolerance in age-induced T2D mice"
  claim := .inContext { taxa := [mouse], disease := some T2D, stage := some "aged", system := some .inVivo }
            (.effect NMN .neg (.phenotype impGlcTol))
  evidence := [{ pmid := 21982712, year := 2011, kind := .animal }]

def Mi16_1 : Statement where
  id := "Mi16_1"
  text := "oral NMN raises tissue NAD+ in aging mice"
  claim := .inContext { taxa := [mouse], strain := some "C57BL/6N", stage := some "aging, 12 months of treatment",
                        dose := some "oral (amount not in abstract)", duration := some "12 months", system := some .inVivo }
            (.effect NMN .pos (.amount NADp))
  evidence := [{ pmid := 28068222, year := 2016, kind := .animal }]

def Y21_2 : Statement where
  id := "Y21_2"
  text := "NMN increases skeletal muscle insulin sensitivity in prediabetic postmenopausal women"
  claim := .inContext { taxa := [human], sex := some "PATO:0000383", stage := some "postmenopausal (EFO:0002721)",
                        disease := some prediabetes, anatomy := some skMuscle, duration := some "10 weeks",
                        system := some .inVivo }
            (.effect NMN .pos (.phenotype incInsSens))
  evidence := [{ pmid := 33888596, year := 2021, kind := .rct,
                 note := "vs placebo; clamp-measured insulin-stimulated glucose disposal" }]

/-- The placebo arm, as a true null. -/
def Y21_placebo : Statement where
  id := "Y21_placebo"
  text := "placebo does not change insulin-stimulated glucose disposal"
  claim := .inContext { taxa := [human], disease := some prediabetes, duration := some "10 weeks", system := some .inVivo }
            (.noEffect (⟨"?:unverified", "placebo"⟩ : Entity .exposure) (.process insGlcImport))
  evidence := [{ pmid := 33888596, year := 2021, kind := .rct }]

end BioLean.Formalisms.Ext
```

Output against the extended build: `M1.opinion = ⟨b=0.842 d=0.000 u=0.157⟩` and
`SL1.opinion = ⟨b=0.000 d=0.842 u=0.157⟩`. The founding papers now record who proposed what but
carry no weight, so Slater's hypothesis no longer keeps belief from its own proposal. `Y21_2`
prints as `NMN →+ increased insulin sensitivity [in Homo sapiens, postmenopausal, skeletal muscle
tissue, prediabetes syndrome, 10 weeks]`.

What this extension still does not cover:
- Graded logical force (Jagendorf shows sufficiency, not that C~I is absent): `.refutes` stays binary.
- Interactions/synergy (NMN × exercise, NMN × aging): would need a `Claim.interaction` constructor.
- "Restores to baseline": still up/down; a `Sign.restores` would break the sign algebra.
- Orthology-based transfer (mouse SIRT1 → human SIRT1): needs a new `Derivation` rule.
- Vectorial direction across a membrane (inside-out SMPs): `gradient` has no orientation.
