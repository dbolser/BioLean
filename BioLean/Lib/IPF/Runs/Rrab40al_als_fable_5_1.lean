import BioLean.Lib.IPF.Common

/-! Rendered from `data/ipf/runs/rab40al-als-fable-5-1/curated.json` by `scripts/ipf/render.py`.
Do not edit by hand. Run `rab40al-als-fable-5-1`: scripted-offline:claude-fable-5-1, amyotrophic lateral sclerosis, genes RAB40AL. -/

namespace BioLean.Lib.IPF.Runs.Rrab40al_als_fable_5_1

open BioLean BioLean.Lib.IPF Derivation

def RAB40AL : Entity .protein := ⟨"UniProt:P0C0E4", "RAB40AL"⟩
def CUL5 : Entity .protein := ⟨"UniProt:Q93034", "CUL5"⟩
def ISCA1 : Entity .protein := ⟨"UniProt:Q9BUE6", "ISCA1"⟩
def FYCO1 : Entity .protein := ⟨"UniProt:Q9BQS8", "FYCO1"⟩
def SQSTM1 : Entity .protein := ⟨"UniProt:Q13501", "SQSTM1"⟩
def TARDBP : Entity .protein := ⟨"UniProt:Q13148", "TARDBP"⟩
def mitochondrion : Entity .component := ⟨"GO:0005739", "mitochondrion"⟩
def endosome : Entity .component := ⟨"GO:0005768", "endosome"⟩
def synapticVesicle : Entity .component := ⟨"GO:0008021", "synaptic vesicle"⟩
def growthCone : Entity .component := ⟨"GO:0030426", "growth cone"⟩
def axon : Entity .component := ⟨"GO:0030424", "axon"⟩
def distalAxon : Entity .component := ⟨"GO:0150034", "distal axon"⟩
def motorNeuron : Entity .cellType := ⟨"CL:0000100", "motor neuron"⟩
def ubProteinCatabolism : Entity .process := ⟨"GO:0006511", "ubiquitin-dependent protein catabolic process"⟩
def abnormalActinCytoskeleton : Entity .phenotype := ⟨"MP:0020849", "abnormal actin cytoskeleton morphology"⟩
def axonalDegeneration : Entity .phenotype := ⟨"HP:0040078", "Axonal degeneration"⟩
def fe4s4ClusterAssembly : Entity .process := ⟨"GO:0044572", "[4Fe-4S] cluster assembly"⟩
def ironSulfurCluster : Entity .chemical := ⟨"CHEBI:30408", "iron-sulfur cluster"⟩
def oxidativeStress : Entity .phenotype := ⟨"MP:0003674", "oxidative stress"⟩
def autophagosomeLocalization : Entity .process := ⟨"GO:0061906", "autophagosome localization"⟩
def als : Entity .disease := ⟨"MONDO:0004976", "amyotrophic lateral sclerosis"⟩
def growthConeActinAbnormal : Entity .phenotype := abnormalActinCytoskeleton.inCtx { component := growthCone }
def motorAxonDegeneration : Entity .phenotype := axonalDegeneration.inCtx { cellType := motorNeuron }
def mnOxidativeStress : Entity .phenotype := oxidativeStress.inCtx { cellType := motorNeuron }
def axonalAutophagosomeTransport : Entity .process := autophagosomeLocalization.inCtx { component := axon }
def distalAxonSQSTM1 : Entity .protein := SQSTM1.inCtx { cellType := motorNeuron, component := distalAxon }
def distalAxonTARDBP : Entity .protein := TARDBP.inCtx { cellType := motorNeuron, component := distalAxon }

/-- Run step H1.1: RAB40AL binds CUL5. -/
def S1 : Statement where
  id := "S1"
  text := "RAB40AL binds CUL5"
  claim := .rel ⟨.ro, 2436, false⟩ RAB40AL CUL5
  evidence := [
    { pmid := 0, year := 2026, ref := "STRING:RAB40AL-CUL5", kind := .curatedDb, note := "STRING links RAB40AL and CUL5 with combined score 0.99 (experimental 0.98, database 0.00, text-mining 0.22)." }
  ]

/-- Run step H1.2: RAB40AL, as substrate receptor of the ECS(RAB40AL) Cul5 ligase, is required for ubiquitin-dependent protein catabolism (of its substrates). -/
def S2 : Statement where
  id := "S2"
  text := "RAB40AL, as substrate receptor of the ECS(RAB40AL) Cul5 ligase, is required for ubiquitin-dependent protein catabolism (of its substrates)"
  claim := .effect RAB40AL .pos (.process ubProteinCatabolism)
  evidence := [
    { pmid := 0, year := 2026, ref := "P0C0E4", kind := .crossSpecies, note := "May act as substrate-recognition component of the ECS(RAB40) E3 ubiquitin ligase complex which mediates the ubiquitination and subsequent proteasomal degradation of target proteins (By similarity)" }
  ]

/-- Run step H1.4: abnormal actin cytoskeleton at the growth cone (the run: RhoA/actin imbalance) leads to motor axon degeneration (the run: distal motor axon retraction). Sign: the run's subject 'RhoA/actin imbalance' is an undirected change, grounded as the 'abnormal actin cytoskeleton morphology' phenotype. -/
def S3 : Statement where
  id := "S3"
  text := "abnormal actin cytoskeleton at the growth cone (the run: RhoA/actin imbalance) leads to motor axon degeneration (the run: distal motor axon retraction)"
  claim := .effect growthConeActinAbnormal .pos (.phenotype motorAxonDegeneration)
  evidence := []

/-- Run step H1.5: motor axon degeneration (the run: distal motor axon retraction) leads to ALS. -/
def S4 : Statement where
  id := "S4"
  text := "motor axon degeneration (the run: distal motor axon retraction) leads to ALS"
  claim := .effect motorAxonDegeneration .pos (.disease als)
  evidence := []

/-- Run step H2.1: RAB40AL binds ISCA1. -/
def S5 : Statement where
  id := "S5"
  text := "RAB40AL binds ISCA1"
  claim := .rel ⟨.ro, 2436, false⟩ RAB40AL ISCA1
  evidence := [
    { pmid := 0, year := 2026, ref := "STRING:RAB40AL-ISCA1", kind := .curatedDb, note := "STRING links RAB40AL and ISCA1 with combined score 0.96 (experimental 0.96, database 0.00, text-mining 0.00)." }
  ]

/-- Run step H2.1: RAB40AL is located in the mitochondrion (the step's context). -/
def S6 : Statement where
  id := "S6"
  text := "RAB40AL is located in the mitochondrion (the step's context)"
  claim := .rel ⟨.ro, 1025, false⟩ RAB40AL mitochondrion
  evidence := [
    { pmid := 0, year := 2026, ref := "P0C0E4", kind := .curatedDb, note := "Location: Membrane, Cytoplasm, Mitochondrion" }
  ]

/-- Run step H2.2: RAB40AL, as the ECS(RAB40AL) Cul5 ligase, lowers ISCA1. -/
def S7 : Statement where
  id := "S7"
  text := "RAB40AL, as the ECS(RAB40AL) Cul5 ligase, lowers ISCA1"
  claim := .effect RAB40AL .neg (.amount ISCA1)
  evidence := []

/-- Run step H2.3: ISCA1 is required for [4Fe-4S] cluster assembly. -/
def S8 : Statement where
  id := "S8"
  text := "ISCA1 is required for [4Fe-4S] cluster assembly"
  claim := .effect ISCA1 .pos (.process fe4s4ClusterAssembly)
  evidence := []

/-- Bridge, not in the run: [4Fe-4S] cluster assembly makes iron-sulfur clusters. -/
def S9 : Statement where
  id := "S9"
  text := "[4Fe-4S] cluster assembly makes iron-sulfur clusters"
  claim := .effect fe4s4ClusterAssembly .pos (.amount ironSulfurCluster)
  evidence := [
    { pmid := 0, year := 2026, ref := "GO:0044572", kind := .textbook, note := "The incorporation of four iron atoms and four sulfur atoms into an iron-sulfur cluster." }
  ]

/-- Run step H2.4: Fe-S cluster deficiency leads to oxidative stress in motor neurons. Sign: inverted: the run's subject is Fe-S cluster deficiency. -/
def S10 : Statement where
  id := "S10"
  text := "Fe-S cluster deficiency leads to oxidative stress in motor neurons"
  claim := .effect ironSulfurCluster .neg (.phenotype mnOxidativeStress)
  evidence := []

/-- Run step H2.5: oxidative stress in motor neurons leads to ALS. -/
def S11 : Statement where
  id := "S11"
  text := "oxidative stress in motor neurons leads to ALS"
  claim := .effect mnOxidativeStress .pos (.disease als)
  evidence := []

/-- Run step H3.1: RAB40AL is located in the endosome (the run: associated with endosome compartments). -/
def S12 : Statement where
  id := "S12"
  text := "RAB40AL is located in the endosome (the run: associated with endosome compartments)"
  claim := .rel ⟨.ro, 1025, false⟩ RAB40AL endosome
  evidence := []

/-- Run step H3.1: RAB40AL is located in synaptic vesicles (the run: associated with synaptic-vesicle compartments). -/
def S13 : Statement where
  id := "S13"
  text := "RAB40AL is located in synaptic vesicles (the run: associated with synaptic-vesicle compartments)"
  claim := .rel ⟨.ro, 1025, false⟩ RAB40AL synapticVesicle
  evidence := []

/-- Run step H3.2: RAB40AL binds FYCO1. -/
def S14 : Statement where
  id := "S14"
  text := "RAB40AL binds FYCO1"
  claim := .rel ⟨.ro, 2436, false⟩ RAB40AL FYCO1
  evidence := [
    { pmid := 0, year := 2026, ref := "STRING:RAB40AL-FYCO1", kind := .textMined, note := "STRING links RAB40AL and FYCO1 with combined score 0.85 (experimental 0.00, database 0.00, text-mining 0.85)." }
  ]

/-- Run step H3.3: FYCO1 is required for axonal autophagosome transport. -/
def S15 : Statement where
  id := "S15"
  text := "FYCO1 is required for axonal autophagosome transport"
  claim := .effect FYCO1 .pos (.process axonalAutophagosomeTransport)
  evidence := []

/-- Run step H3.4: axonal autophagosome transport is required to clear p62 (SQSTM1) from the distal axon of motor neurons. Sign: the run's object is clearance of p62 (required_for, +); clearing p62 lowers its amount, so the effect on the amount is -. -/
def S16 : Statement where
  id := "S16"
  text := "axonal autophagosome transport is required to clear p62 (SQSTM1) from the distal axon of motor neurons"
  claim := .effect axonalAutophagosomeTransport .neg (.amount distalAxonSQSTM1)
  evidence := []

/-- Run step H3.4: axonal autophagosome transport is required to clear TDP-43 (TARDBP) from the distal axon of motor neurons. Sign: the run's object is clearance of TDP-43 (required_for, +); clearing TDP-43 lowers its amount, so the effect on the amount is -. -/
def S17 : Statement where
  id := "S17"
  text := "axonal autophagosome transport is required to clear TDP-43 (TARDBP) from the distal axon of motor neurons"
  claim := .effect axonalAutophagosomeTransport .neg (.amount distalAxonTARDBP)
  evidence := []

/-- Run step H3.5: stalled autophagosomes in the distal axon (loss of axonal autophagosome transport) lead to ALS. Sign: inverted: the run's subject is stalled autophagosomes, i.e. loss of their axonal transport. -/
def S18 : Statement where
  id := "S18"
  text := "stalled autophagosomes in the distal axon (loss of axonal autophagosome transport) lead to ALS"
  claim := .effect axonalAutophagosomeTransport .neg (.disease als)
  evidence := []

def statements : List Statement := [S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11, S12, S13, S14, S15, S16, S17, S18]

/-- H1, claim 1: Loss of the ECS(RAB40AL) Cul5 ligase stabilises a cytoskeletal substrate that distal motor axons cannot tolerate. -/
def h1c1a1 := viaAmount (lit S7) (viaProcess (lit S8) (viaAmount (lit S9) (viaPhenotype (lit S10) (lit S11))))

/-- H2, claim 1: RAB40AL at the mitochondrion controls ISCA1 turnover, and Fe-S cluster deficiency drives oxidative stress in motor neurons. -/
def h2c1a1 := viaAmount (lit S7) (viaProcess (lit S8) (viaAmount (lit S9) (viaPhenotype (lit S10) (lit S11))))

/-- H3, claim 1: RAB40AL positions autophagosomes in the axon through FYCO1, and its loss stalls cargo clearance distally. -/
def h3c1a1 := viaAmount (lit S7) (viaProcess (lit S8) (viaAmount (lit S9) (viaPhenotype (lit S10) (lit S11))))

def rows : List Lean.Json :=
  statements.map statementRow ++ [arm "H1" "c1a1" h1c1a1,
    arm "H2" "c1a1" h2c1a1,
    arm "H3" "c1a1" h3c1a1]

#eval printRows "rab40al-als-fable-5-1" rows

end BioLean.Lib.IPF.Runs.Rrab40al_als_fable_5_1
