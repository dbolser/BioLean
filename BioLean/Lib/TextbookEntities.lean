import BioLean.Ontology

/-! Entities for the textbook examples. CURIEs verified on OLS4, 2026-10-27. -/

namespace BioLean.Textbook

def gonad          : Entity .anatomy   := ⟨"UBERON:0000991", "gonad"⟩
def steroidogenesis : Entity .process  := ⟨"GO:0006694", "steroid biosynthetic process"⟩
def steroidHormone : Entity .chemical  := ⟨"CHEBI:26764", "steroid hormone"⟩
def glycolysis     : Entity .process   := ⟨"GO:0006096", "glycolytic process"⟩
def cytosol        : Entity .component := ⟨"GO:0005829", "cytosol"⟩
def cell           : Entity .cellType  := ⟨"CL:0000000", "cell"⟩
def ascendingColon : Entity .anatomy   := ⟨"UBERON:0001156", "ascending colon"⟩
def colon          : Entity .anatomy   := ⟨"UBERON:0001155", "colon"⟩
def largeIntestine : Entity .anatomy   := ⟨"UBERON:0000059", "large intestine"⟩
def nucleus        : Entity .component := ⟨"GO:0005634", "nucleus"⟩
def eukaryoticCell : Entity .cellType  := ⟨"CL:0000255", "eukaryotic cell"⟩
def hepatocyte     : Entity .cellType  := ⟨"CL:0000182", "hepatocyte"⟩
def prokaryoticCell : Entity .cellType := ⟨"CL:0000520", "prokaryotic cell"⟩
def heterocyst     : Entity .cellType  := ⟨"CL:0000724", "heterocyst"⟩

end BioLean.Textbook
