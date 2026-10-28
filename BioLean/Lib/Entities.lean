import BioLean.Ontology

/-!
# Grounded entities for the GLP-1 / appetite story

Every identifier below was checked against the local ontology, UniProt and HGNC
records (see `data/demo/grounding.json`).
-/

namespace BioLean.Lib

/-! ### Chemicals (ChEBI) -/

def semaglutide : Entity .chemical := ⟨"CHEBI:167574", "semaglutide"⟩
def liraglutide : Entity .chemical := ⟨"CHEBI:71193", "liraglutide"⟩
def sitagliptin : Entity .chemical := ⟨"CHEBI:40237", "sitagliptin"⟩
/-- GLP-1(7-36) amide, the active incretin. -/
def glp1 : Entity .chemical := ⟨"CHEBI:80270", "glucagon-like peptide 1"⟩

/-! ### Proteins (UniProt, human) -/

def GLP1R : Entity .protein := ⟨"UniProt:P43220", "GLP1R"⟩
def DPP4 : Entity .protein := ⟨"UniProt:P27487", "DPP4"⟩
def GCG : Entity .protein := ⟨"UniProt:P01275", "proglucagon (GCG)"⟩
def POMC : Entity .protein := ⟨"UniProt:P01189", "POMC"⟩

/-! ### Processes (GO) -/

def feedingBehavior : Entity .process := ⟨"GO:0007631", "feeding behavior"⟩
def gastricEmptying : Entity .process := ⟨"GO:0120060", "regulation of gastric emptying"⟩

/-! ### Phenotypes (HP) -/

def appetite : Entity .phenotype := ⟨"HP:0004396", "appetite (poor appetite phenotype)"⟩
def nausea : Entity .phenotype := ⟨"HP:0002018", "nausea"⟩
def bodyWeight : Entity .phenotype := ⟨"HP:0001513", "body weight (obesity phenotype)"⟩
def earlySatiety : Entity .phenotype := ⟨"HP:0033842", "early satiety"⟩

/-! ### Anatomy (UBERON) -/

def hypothalamus : Entity .anatomy := ⟨"UBERON:0001898", "hypothalamus"⟩
def areaPostrema : Entity .anatomy := ⟨"UBERON:0002162", "area postrema"⟩
def vagusNerve : Entity .anatomy := ⟨"UBERON:0001759", "vagus nerve"⟩

end BioLean.Lib
