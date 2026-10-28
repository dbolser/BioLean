import BioLean.Evidence

/-! The 40 context-required textbook claims (`data/m2/context_claims.json`, key `sample40`),
in design "evidence": the claim is bare, the context sits on the textbook evidence item.
Generated once from the JSON; CURIEs and kinds as Sonnet gave them, labels filled where missing. -/

namespace BioLean.M2.Evidence

def e_CHEBI_15377 : Entity .chemical := ⟨"CHEBI:15377", "water"⟩
def e_CHEBI_15379 : Entity .chemical := ⟨"CHEBI:15379", "oxygen"⟩
def e_CHEBI_16646 : Entity .chemical := ⟨"CHEBI:16646", "carbohydrate"⟩
def e_CHEBI_17234 : Entity .chemical := ⟨"CHEBI:17234", "glucose"⟩
def e_CHEBI_17716 : Entity .chemical := ⟨"CHEBI:17716", "lactose"⟩
def e_CHEBI_23888 : Entity .chemical := ⟨"CHEBI:23888", "drug"⟩
def e_CHEBI_27584 : Entity .chemical := ⟨"CHEBI:27584", "aldosterone"⟩
def e_CHEBI_29101 : Entity .chemical := ⟨"CHEBI:29101", "sodium ion"⟩
def e_CHEBI_29103 : Entity .chemical := ⟨"CHEBI:29103", "potassium ion"⟩
def e_CHEBI_33568 : Entity .chemical := ⟨"CHEBI:33568", "epinephrine"⟩
def e_CHEBI_35469 : Entity .chemical := ⟨"CHEBI:35469", "antidepressant"⟩
def e_CL_0000000 : Entity .cellType := ⟨"CL:0000000", "cell"⟩
def e_CL_0000232 : Entity .cellType := ⟨"CL:0000232", "erythrocyte"⟩
def e_CL_0000300 : Entity .cellType := ⟨"CL:0000300", "gamete"⟩
def e_CL_0000520 : Entity .cellType := ⟨"CL:0000520", "prokaryotic cell"⟩
def e_CL_0000586 : Entity .cellType := ⟨"CL:0000586", "germ cell"⟩
def e_CL_0000746 : Entity .cellType := ⟨"CL:0000746", "cardiac muscle cell"⟩
def e_CL_0001064 : Entity .cellType := ⟨"CL:0001064", "malignant cell"⟩
def e_GO_0000086 : Entity .process := ⟨"GO:0000086", "G2/M transition"⟩
def e_GO_0000271 : Entity .process := ⟨"GO:0000271", "polysaccharide biosynthetic process"⟩
def e_GO_0000723 : Entity .process := ⟨"GO:0000723", "telomere maintenance"⟩
def e_GO_0000910 : Entity .process := ⟨"GO:0000910", "cytokinesis"⟩
def e_GO_0005634 : Entity .component := ⟨"GO:0005634", "nucleus"⟩
def e_GO_0005694 : Entity .component := ⟨"GO:0005694", "chromosome"⟩
def e_GO_0005697 : Entity .component := ⟨"GO:0005697", "telomerase holoenzyme complex"⟩
def e_GO_0005737 : Entity .component := ⟨"GO:0005737", "cytoplasm"⟩
def e_GO_0005764 : Entity .component := ⟨"GO:0005764", "lysosome"⟩
def e_GO_0005794 : Entity .component := ⟨"GO:0005794", "Golgi apparatus"⟩
def e_GO_0005856 : Entity .component := ⟨"GO:0005856", "cytoskeleton"⟩
def e_GO_0005886 : Entity .component := ⟨"GO:0005886", "plasma membrane"⟩
def e_GO_0005902 : Entity .component := ⟨"GO:0005902", "microvillus"⟩
def e_GO_0005990 : Entity .process := ⟨"GO:0005990", "lactose catabolic process"⟩
def e_GO_0006096 : Entity .process := ⟨"GO:0006096", "glycolytic process"⟩
def e_GO_0006289 : Entity .process := ⟨"GO:0006289", "nucleotide-excision repair"⟩
def e_GO_0006351 : Entity .process := ⟨"GO:0006351", "DNA-templated transcription"⟩
def e_GO_0007095 : Entity .process := ⟨"GO:0007095", "mitotic G2 DNA damage checkpoint signaling"⟩
def e_GO_0007134 : Entity .process := ⟨"GO:0007134", "telophase I"⟩
def e_GO_0007136 : Entity .process := ⟨"GO:0007136", "prophase II"⟩
def e_GO_0007585 : Entity .process := ⟨"GO:0007585", "respiratory gaseous exchange by respiratory system"⟩
def e_GO_0007586 : Entity .process := ⟨"GO:0007586", "digestion"⟩
def e_GO_0009295 : Entity .component := ⟨"GO:0009295", "nucleoid"⟩
def e_GO_0009505 : Entity .component := ⟨"GO:0009505", "plant cell wall"⟩
def e_GO_0015979 : Entity .process := ⟨"GO:0015979", "photosynthesis"⟩
def e_GO_0016042 : Entity .process := ⟨"GO:0016042", "lipid catabolic process"⟩
def e_GO_0019661 : Entity .process := ⟨"GO:0019661", "glucose catabolic process to lactate via pyruvate"⟩
def e_GO_0019953 : Entity .process := ⟨"GO:0019953", "sexual reproduction"⟩
def e_GO_0022008 : Entity .process := ⟨"GO:0022008", "neurogenesis"⟩
def e_GO_0030261 : Entity .process := ⟨"GO:0030261", "chromosome condensation"⟩
def e_GO_0031468 : Entity .process := ⟨"GO:0031468", "nuclear envelope reformation"⟩
def e_GO_0032154 : Entity .component := ⟨"GO:0032154", "cleavage furrow"⟩
def e_GO_0043093 : Entity .process := ⟨"GO:0043093", "binary fission"⟩
def e_GO_0044557 : Entity .process := ⟨"GO:0044557", "relaxation of smooth muscle"⟩
def e_GO_0050892 : Entity .process := ⟨"GO:0050892", "intestinal absorption"⟩
def e_GO_0051301 : Entity .process := ⟨"GO:0051301", "cell division"⟩
def e_GO_0051321 : Entity .process := ⟨"GO:0051321", "meiosis"⟩
def e_GO_0060048 : Entity .process := ⟨"GO:0060048", "cardiac muscle contraction"⟩
def e_GO_0061337 : Entity .process := ⟨"GO:0061337", "cardiac conduction"⟩
def e_GO_0090332 : Entity .process := ⟨"GO:0090332", "stomatal closure"⟩
def e_GO_0098657 : Entity .process := ⟨"GO:0098657", "import into cell"⟩
def e_HP_0008069 : Entity .phenotype := ⟨"HP:0008069", "skin cancers"⟩
def e_HP_0012531 : Entity .phenotype := ⟨"HP:0012531", "pain"⟩
def e_NCBITaxon_2 : Entity .taxon := ⟨"NCBITaxon:2", "Bacteria"⟩
def e_NCBITaxon_2759 : Entity .taxon := ⟨"NCBITaxon:2759", "Eukaryota"⟩
def e_NCBITaxon_33090 : Entity .taxon := ⟨"NCBITaxon:33090", "Viridiplantae"⟩
def e_NCBITaxon_33208 : Entity .taxon := ⟨"NCBITaxon:33208", "Metazoa"⟩
def e_NCBITaxon_40674 : Entity .taxon := ⟨"NCBITaxon:40674", "Mammalia"⟩
def e_NCBITaxon_562 : Entity .taxon := ⟨"NCBITaxon:562", "Escherichia coli"⟩
def e_NCBITaxon_7742 : Entity .taxon := ⟨"NCBITaxon:7742", "Vertebrata"⟩
def e_NCBITaxon_9606 : Entity .taxon := ⟨"NCBITaxon:9606", "Homo sapiens"⟩
def e_NCIT_C14263 : Entity .taxon := ⟨"NCIT:C14263", "prokaryote"⟩
def e_PATO_0000956 : Entity .phenotype := ⟨"PATO:0000956", "sterile"⟩
def e_PATO_0001381 : Entity .phenotype := ⟨"PATO:0001381", "triploid"⟩
def e_PO_0025034 : Entity .anatomy := ⟨"PO:0025034", "leaf"⟩
def e_PR_000009054 : Entity .protein := ⟨"PR:000009054", "insulin"⟩
def e_PR_000022726 : Entity .protein := ⟨"PR:000022726", "FtsZ"⟩
def e_PR_P01160 : Entity .protein := ⟨"PR:P01160", "atrial natriuretic peptide"⟩
def e_PR_P01275 : Entity .protein := ⟨"PR:P01275", "glucagon"⟩
def e_SO_0001026 : Entity .gene := ⟨"SO:0001026", "genome"⟩
def e_UBERON_0000010 : Entity .anatomy := ⟨"UBERON:0000010", "peripheral nervous system"⟩
def e_UBERON_0000013 : Entity .anatomy := ⟨"UBERON:0000013", "sympathetic nervous system"⟩
def e_UBERON_0000178 : Entity .anatomy := ⟨"UBERON:0000178", "blood"⟩
def e_UBERON_0001004 : Entity .anatomy := ⟨"UBERON:0001004", "respiratory system"⟩
def e_UBERON_0001013 : Entity .anatomy := ⟨"UBERON:0001013", "adipose tissue"⟩
def e_UBERON_0001021 : Entity .anatomy := ⟨"UBERON:0001021", "nerve"⟩
def e_UBERON_0002081 : Entity .anatomy := ⟨"UBERON:0002081", "cardiac atrium"⟩
def e_UBERON_0002185 : Entity .anatomy := ⟨"UBERON:0002185", "bronchus"⟩
def e_UBERON_0002421 : Entity .anatomy := ⟨"UBERON:0002421", "hippocampus"⟩

/-- Telomerase is present in human cells -/
def t_molbio_m45475_69 : Statement where
  id := "molbio-m45475-69"
  text := "Telomerase is present in human cells"
  claim := .rel .locatedIn e_GO_0005697 e_CL_0000000
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, taxa := [e_NCBITaxon_9606], note :=
    "Later research using HeLa cells (obtained from Henrietta Lacks) confirmed that telomerase is present in human cells." }]
/-- Epinephrine and norepinephrine accelerate breakdown of stored fat in adipose tissue -/
def t_the_body_s_systems_m45537_183 : Statement where
  id := "the-body-s-systems-m45537-183"
  text := "Epinephrine and norepinephrine accelerate breakdown of stored fat in adipose tissue"
  claim := .effect e_CHEBI_33568 .pos (.process e_GO_0016042)
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, anatomy := some e_UBERON_0001013, note :=
    "They also accelerate the breakdown of glucose in skeletal muscles and stored fats in adipose tissue, and redirect blood flow toward skeletal muscles and away from skin and viscera." }]
/-- The electrochemical signal causes the two atria to contract in unison -/
def t_the_body_s_systems_m45536_190 : Statement where
  id := "the-body-s-systems-m45536-190"
  text := "The electrochemical signal causes the two atria to contract in unison"
  claim := .effect e_GO_0061337 .pos (.process e_GO_0060048)
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, anatomy := some e_UBERON_0002081, note :=
    "The electrochemical signal causes the two atria to contract in unison; then the signal causes the ventricles to contract." }]
/-- In a hypotonic solution water enters the cell -/
def t_cell_structure_and_function_m45434_70 : Statement where
  id := "cell-structure-and-function-m45434-70"
  text := "In a hypotonic solution water enters the cell"
  claim := .rel ⟨.ro, 57, false⟩ e_GO_0098657 e_CHEBI_15377
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, condition := some "hypotonic solution", note :=
    "In a hypotonic solution, such as tap water, the extracellular fluid has a lower concentration of solutes than the fluid inside the cell, and water enters the cell." }]
/-- stomatal closure raises oxygen levels inside the leaf -/
def t_photosynthesis_m45448_120 : Statement where
  id := "photosynthesis-m45448-120"
  text := "stomatal closure raises oxygen levels inside the leaf"
  claim := .effect e_GO_0090332 .pos (.amount e_CHEBI_15379)
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, anatomy := some e_PO_0025034, note :=
    "Levels of carbon dioxide (a reactant) will fall, and levels of oxygen (a product) will rise." }]
/-- Glucagon causes release of glucose from the liver into the blood -/
def t_the_body_s_systems_m45537_201 : Statement where
  id := "the-body-s-systems-m45537-201"
  text := "Glucagon causes release of glucose from the liver into the blood"
  claim := .effect e_PR_P01275 .pos (.amount e_CHEBI_17234)
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, anatomy := some e_UBERON_0000178, note :=
    "Glucagon causes the release of glucose to the blood from the liver, and insulin facilitates the uptake of glucose by the body’s cells." }]
/-- FtsZ is a tubulin-like protein component of the prokaryotic cytoskeleton. -/
def t_reproduction_at_the_cellular_level_m45463_67 : Statement where
  id := "reproduction-at-the-cellular-level-m45463-67"
  text := "FtsZ is a tubulin-like protein component of the prokaryotic cytoskeleton."
  claim := .rel .partOf e_PR_000022726 e_GO_0005856
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, taxa := [e_NCBITaxon_2], note :=
    "FtsZ: a tubulin-like protein component of the prokaryotic cytoskeleton that is important in prokaryotic cytokinesis (name origin: Filamenting temperature-sensitive mutant Z)" }]
/-- Increasing blood glucose causes the pancreas to release insulin -/
def t_the_body_s_systems_m45537_334 : Statement where
  id := "the-body-s-systems-m45537-334"
  text := "Increasing blood glucose causes the pancreas to release insulin"
  claim := .effect e_CHEBI_17234 .pos (.amount e_PR_000009054)
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, anatomy := some e_UBERON_0000178, note :=
    "When blood-glucose levels are increasing, the pancreas releases insulin, which stimulates uptake of glucose by cells." }]
/-- An increase in blood potassium stimulates aldosterone release -/
def t_the_body_s_systems_m45537_156 : Statement where
  id := "the-body-s-systems-m45537-156"
  text := "An increase in blood potassium stimulates aldosterone release"
  claim := .effect e_CHEBI_29103 .pos (.amount e_CHEBI_27584)
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, anatomy := some e_UBERON_0000178, note :=
    "Aldosterone release from the adrenal cortex is stimulated by a decrease in blood concentrations of sodium ions, blood volume, or blood pressure, or by an increase in blood potassium levels." }]
/-- The plant cell wall is external to the plasma membrane -/
def t_cell_structure_and_function_m45432_219 : Statement where
  id := "cell-structure-and-function-m45432-219"
  text := "The plant cell wall is external to the plasma membrane"
  claim := .rel ⟨.ro, 2220, false⟩ e_GO_0009505 e_GO_0005886
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, taxa := [e_NCBITaxon_33090], note :=
    "In b, the diagram of a plant cell, you see a structure external to the plasma membrane called the cell wall." }]
/-- The atrial hormone reduces blood Na+ concentration -/
def t_the_body_s_systems_m45537_229 : Statement where
  id := "the-body-s-systems-m45537-229"
  text := "The atrial hormone reduces blood Na+ concentration"
  claim := .effect e_PR_P01160 .neg (.amount e_CHEBI_29101)
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, anatomy := some e_UBERON_0000178, note :=
    "It causes a reduction in blood volume and blood pressure, and reduces the concentration of Na+ in the blood." }]
/-- Loss of microvilli prevents nutrient absorption in celiac patients -/
def t_cell_structure_and_function_m45432_25 : Statement where
  id := "cell-structure-and-function-m45432-25"
  text := "Loss of microvilli prevents nutrient absorption in celiac patients"
  claim := .effect e_GO_0005902 .pos (.process e_GO_0050892)
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, condition := some "celiac disease", note :=
    "The immune response damages microvilli, and thus, afflicted individuals cannot absorb nutrients." }]
/-- Binary fission is the process of prokaryotic cell division. -/
def t_reproduction_at_the_cellular_level_m45463_66 : Statement where
  id := "reproduction-at-the-cellular-level-m45463-66"
  text := "Binary fission is the process of prokaryotic cell division."
  claim := .rel .isA e_GO_0043093 e_GO_0051301
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, taxa := [e_NCBITaxon_2], note :=
    "binary fission: the process of prokaryotic cell division" }]
/-- People with defective nucleotide excision repair genes develop skin cancers early in life -/
def t_molbio_m45475_117 : Statement where
  id := "molbio-m45475-117"
  text := "People with defective nucleotide excision repair genes develop skin cancers early in life"
  claim := .effect e_GO_0006289 .neg (.phenotype e_HP_0008069)
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, taxa := [e_NCBITaxon_9606], condition := some "defective NER genes; early onset", note :=
    "Individuals with flaws in their nucleotide excision repair genes show extreme sensitivity to sunlight and develop skin cancers early in life." }]
/-- Insulin decreases blood-glucose levels -/
def t_the_body_s_systems_m45537_53 : Statement where
  id := "the-body-s-systems-m45537-53"
  text := "Insulin decreases blood-glucose levels"
  claim := .effect e_PR_000009054 .neg (.amount e_CHEBI_17234)
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, anatomy := some e_UBERON_0000178, note :=
    "They are then given a sugary drink, which stimulates the pancreas to produce insulin to decrease blood-glucose levels." }]
/-- Telomerase is active in some cancer cells -/
def t_molbio_m45475_67 : Statement where
  id := "molbio-m45475-67"
  text := "Telomerase is active in some cancer cells"
  claim := .rel .capableOf e_GO_0005697 e_GO_0000723
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, cellType := some e_CL_0001064, condition := some "some cancer cells", note :=
    "Telomerase is typically found to be active in germ cells, adult stem cells, and some cancer cells." }]
/-- Lactic acid fermentation occurs routinely in mammalian red blood cells -/
def t_how_cells_obtain_energy_m45440_11 : Statement where
  id := "how-cells-obtain-energy-m45440-11"
  text := "Lactic acid fermentation occurs routinely in mammalian red blood cells"
  claim := .rel .occursIn e_GO_0019661 e_CL_0000232
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, taxa := [e_NCBITaxon_40674], cellType := some e_CL_0000232, note :=
    "This occurs routinely in mammalian red blood cells and in skeletal muscle that has insufficient oxygen supply to allow aerobic respiration to continue (that is, in muscles used to the point of fatigue)." }]
/-- In some organisms nuclear envelopes form around the chromatids in telophase I -/
def t_the_cellular_basis_of_inheritance_m45466_103 : Statement where
  id := "the-cellular-basis-of-inheritance-m45466-103"
  text := "In some organisms nuclear envelopes form around the chromatids in telophase I"
  claim := .rel ⟨.ro, 2092, false⟩ e_GO_0031468 e_GO_0007134
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, note :=
    "In some organisms, the chromosomes decondense and nuclear envelopes form around the chromatids in telophase I." }]
/-- Animal respiratory systems facilitate gas exchange -/
def t_the_body_s_systems_m45536_175 : Statement where
  id := "the-body-s-systems-m45536-175"
  text := "Animal respiratory systems facilitate gas exchange"
  claim := .rel .capableOf e_UBERON_0001004 e_GO_0007585
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, taxa := [e_NCBITaxon_33208], note :=
    "Animal respiratory systems are designed to facilitate gas exchange." }]
/-- An electrical signal triggers atrial cardiac muscle cells to contract -/
def t_the_body_s_systems_m45536_212 : Statement where
  id := "the-body-s-systems-m45536-212"
  text := "An electrical signal triggers atrial cardiac muscle cells to contract"
  claim := .effect e_GO_0061337 .pos (.process e_GO_0060048)
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, anatomy := some e_UBERON_0002081, cellType := some e_CL_0000746, note :=
    "The heart receives an electrical signal triggering the cardiac muscle cells in the atria to contract." }]
/-- In a diploid-dominant organism such as an animal, meiotic cells participate only in sexual reproduction -/
def t_the_cellular_basis_of_inheritance_m45466_165 : Statement where
  id := "the-cellular-basis-of-inheritance-m45466-165"
  text := "In a diploid-dominant organism such as an animal, meiotic cells participate only in sexual reproduction"
  claim := .rel .partOf e_GO_0051321 e_GO_0019953
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, taxa := [e_NCBITaxon_33208], note :=
    "Cells produced by meiosis in a diploid-dominant organism such as an animal will only participate in sexual reproduction." }]
/-- Chromosomes are located in the nucleus of eukaryotic cells. -/
def t_reproduction_at_the_cellular_level_m45455_16 : Statement where
  id := "reproduction-at-the-cellular-level-m45455-16"
  text := "Chromosomes are located in the nucleus of eukaryotic cells."
  claim := .rel .locatedIn e_GO_0005694 e_GO_0005634
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, taxa := [e_NCBITaxon_2759], note :=
    "Each species of eukaryote has a characteristic number of chromosomes in the nuclei of its cells." }]
/-- Medications relieve pain in rheumatoid arthritis -/
def t_the_body_s_systems_m45538_197 : Statement where
  id := "the-body-s-systems-m45538-197"
  text := "Medications relieve pain in rheumatoid arthritis"
  claim := .effect e_CHEBI_23888 .neg (.phenotype e_HP_0012531)
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, condition := some "rheumatoid arthritis", note :=
    "If joint damage is more extensive, medications can be used to relieve pain and decrease inflammation." }]
/-- Photosynthesizing organisms (plants) produce sugars -/
def t_how_cells_obtain_energy_m45437_11 : Statement where
  id := "how-cells-obtain-energy-m45437-11"
  text := "Photosynthesizing organisms (plants) produce sugars"
  claim := .rel .hasOutput e_GO_0015979 e_CHEBI_16646
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, taxa := [e_NCBITaxon_33090], note :=
    "For the most part, photosynthesizing organisms like plants produce these sugars." }]
/-- Gametes are produced from diploid germ cells -/
def t_the_cellular_basis_of_inheritance_m45465_68 : Statement where
  id := "the-cellular-basis-of-inheritance-m45465-68"
  text := "Gametes are produced from diploid germ cells"
  claim := .rel ⟨.ro, 2202, false⟩ e_CL_0000300 e_CL_0000586
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, taxa := [e_NCBITaxon_33208], note :=
    "The gametes are produced from diploid germ cells, a special cell line that only produces gametes." }]
/-- Glucagon stimulates release of stored glucose from the liver into the bloodstream -/
def t_the_body_s_systems_m45537_337 : Statement where
  id := "the-body-s-systems-m45537-337"
  text := "Glucagon stimulates release of stored glucose from the liver into the bloodstream"
  claim := .effect e_PR_P01275 .pos (.amount e_CHEBI_17234)
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, anatomy := some e_UBERON_0000178, note :=
    "When blood-glucose levels are decreasing, the pancreas releases glucagon, which stimulates the release of stored glucose by the liver to the bloodstream." }]
/-- The vertebrate PNS is made up of peripheral sensory and motor nerves -/
def t_the_body_s_systems_m45539_28 : Statement where
  id := "the-body-s-systems-m45539-28"
  text := "The vertebrate PNS is made up of peripheral sensory and motor nerves"
  claim := .rel .hasPart e_UBERON_0000010 e_UBERON_0001021
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, taxa := [e_NCBITaxon_7742], note :=
    "While there is great diversity among different vertebrate nervous systems, they all share a basic structure: a CNS that contains a brain and spinal cord and a PNS made up of peripheral sensory and motor nerves." }]
/-- Sympathetic input causes bronchial muscle relaxation -/
def t_the_body_s_systems_m45536_61 : Statement where
  id := "the-body-s-systems-m45536-61"
  text := "Sympathetic input causes bronchial muscle relaxation"
  claim := .effect e_UBERON_0000013 .pos (.process e_GO_0044557)
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, anatomy := some e_UBERON_0002185, note :=
    "Bronchi are innervated by nerves of both the parasympathetic and sympathetic nervous systems that control muscle contraction (parasympathetic) or relaxation (sympathetic) in the bronchi and bronchioles, depending on the " }]
/-- The nucleoid is the region of a prokaryotic cell containing the genome. -/
def t_reproduction_at_the_cellular_level_m45455_9 : Statement where
  id := "reproduction-at-the-cellular-level-m45455-9"
  text := "The nucleoid is the region of a prokaryotic cell containing the genome."
  claim := .rel .locatedIn e_SO_0001026 e_GO_0009295
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, taxa := [e_NCIT_C14263], note :=
    "The region in the cell containing this genetic material is called a nucleoid." }]
/-- In animals and some fungi cytokinesis separates cell contents by a cleavage furrow -/
def t_the_cellular_basis_of_inheritance_m45466_106 : Statement where
  id := "the-cellular-basis-of-inheritance-m45466-106"
  text := "In animals and some fungi cytokinesis separates cell contents by a cleavage furrow"
  claim := .rel .hasPart e_GO_0000910 e_GO_0032154
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, taxa := [e_NCBITaxon_33208], note :=
    "In nearly all species, cytokinesis separates the cell contents by either a cleavage furrow (in animals and some fungi), or a cell plate that will ultimately lead to formation of cell walls that separate the two daughter " }]
/-- In prophase II chromosomes condense again if they decondensed in telophase I -/
def t_the_cellular_basis_of_inheritance_m45466_119 : Statement where
  id := "the-cellular-basis-of-inheritance-m45466-119"
  text := "In prophase II chromosomes condense again if they decondensed in telophase I"
  claim := .rel ⟨.ro, 2092, false⟩ e_GO_0030261 e_GO_0007136
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, condition := some "chromosomes decondensed in telophase I", note :=
    "In prophase II, if the chromosomes decondensed in telophase I, they condense again." }]
/-- Mature mammalian red blood cells are capable only of glycolysis -/
def t_how_cells_obtain_energy_m45438_42 : Statement where
  id := "how-cells-obtain-energy-m45438-42"
  text := "Mature mammalian red blood cells are capable only of glycolysis"
  claim := .rel .capableOf e_CL_0000232 e_GO_0006096
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, taxa := [e_NCBITaxon_40674], note :=
    "For example, mature mammalian red blood cells are only capable of glycolysis, which is their sole source of ATP." }]
/-- Triploid animals are sterile -/
def t_the_cellular_basis_of_inheritance_m45467_83 : Statement where
  id := "the-cellular-basis-of-inheritance-m45467-83"
  text := "Triploid animals are sterile"
  claim := .effect e_PATO_0001381 .pos (.phenotype e_PATO_0000956)
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, taxa := [e_NCBITaxon_33208], note :=
    "Triploid animals are sterile because meiosis cannot proceed normally with an odd number of chromosome sets." }]
/-- In single-celled eukaryotes, lysosomes digest ingested food -/
def t_cell_structure_and_function_m45432_162 : Statement where
  id := "cell-structure-and-function-m45432-162"
  text := "In single-celled eukaryotes, lysosomes digest ingested food"
  claim := .rel .capableOf e_GO_0005764 e_GO_0007586
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, condition := some "single-celled eukaryotes", note :=
    "In single-celled eukaryotes, lysosomes are important for digestion of the food they ingest and the recycling of organelles." }]
/-- Lactose is a food source for E. coli -/
def t_molbio_m45480_30 : Statement where
  id := "molbio-m45480-30"
  text := "Lactose is a food source for E. coli"
  claim := .rel .hasInput e_GO_0005990 e_CHEBI_17716
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, taxa := [e_NCBITaxon_562], note :=
    "The lac operon is a stretch of DNA with three adjacent genes that code for proteins that participate in the absorption and metabolism of lactose, a food source for E. coli." }]
/-- In plant cells, the Golgi synthesises polysaccharides -/
def t_cell_structure_and_function_m45432_158 : Statement where
  id := "cell-structure-and-function-m45432-158"
  text := "In plant cells, the Golgi synthesises polysaccharides"
  claim := .rel .capableOf e_GO_0005794 e_GO_0000271
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, taxa := [e_NCBITaxon_33090], note :=
    "In plant cells, the Golgi has an additional role of synthesizing polysaccharides, some of which are incorporated into the cell wall and some of which are used in other parts of the cell." }]
/-- In prokaryotes transcription occurs in the cytoplasm -/
def t_molbio_m45476_20 : Statement where
  id := "molbio-m45476-20"
  text := "In prokaryotes transcription occurs in the cytoplasm"
  claim := .rel .occursIn e_GO_0006351 e_GO_0005737
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, cellType := some e_CL_0000520, note :=
    "The prokaryotes, which include bacteria and archaea, lack membrane-bound nuclei and other organelles, and transcription occurs in the cytoplasm of the cell." }]
/-- Some antidepressant medications promote neurogenesis in the hippocampus -/
def t_the_body_s_systems_m45539_132 : Statement where
  id := "the-body-s-systems-m45539-132"
  text := "Some antidepressant medications promote neurogenesis in the hippocampus"
  claim := .effect e_CHEBI_35469 .pos (.process e_GO_0022008)
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, anatomy := some e_UBERON_0002421, note :=
    "Interestingly, both exercise and some antidepressant medications also promote neurogenesis in the hippocampus." }]
/-- Decreasing blood glucose causes the pancreas to release glucagon -/
def t_the_body_s_systems_m45537_336 : Statement where
  id := "the-body-s-systems-m45537-336"
  text := "Decreasing blood glucose causes the pancreas to release glucagon"
  claim := .effect e_CHEBI_17234 .neg (.amount e_PR_P01275)
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, anatomy := some e_UBERON_0000178, note :=
    "When blood-glucose levels are decreasing, the pancreas releases glucagon, which stimulates the release of stored glucose by the liver to the bloodstream." }]
/-- The G2 checkpoint blocks entry to the mitotic phase if certain conditions are not met. -/
def t_reproduction_at_the_cellular_level_m45461_141 : Statement where
  id := "reproduction-at-the-cellular-level-m45461-141"
  text := "The G2 checkpoint blocks entry to the mitotic phase if certain conditions are not met."
  claim := .effect e_GO_0007095 .neg (.process e_GO_0000086)
  evidence := [{ pmid := 0, year := 2013, kind := .textbook, condition := some "certain conditions not met", note :=
    "The G2 checkpoint bars the entry to the mitotic phase if certain conditions are not met." }]

/-- All 40, for counting. -/
def sample40 : List Statement := [t_molbio_m45475_69, t_the_body_s_systems_m45537_183, t_the_body_s_systems_m45536_190, t_cell_structure_and_function_m45434_70, t_photosynthesis_m45448_120, t_the_body_s_systems_m45537_201, t_reproduction_at_the_cellular_level_m45463_67, t_the_body_s_systems_m45537_334, t_the_body_s_systems_m45537_156, t_cell_structure_and_function_m45432_219, t_the_body_s_systems_m45537_229, t_cell_structure_and_function_m45432_25, t_reproduction_at_the_cellular_level_m45463_66, t_molbio_m45475_117, t_the_body_s_systems_m45537_53, t_molbio_m45475_67, t_how_cells_obtain_energy_m45440_11, t_the_cellular_basis_of_inheritance_m45466_103, t_the_body_s_systems_m45536_175, t_the_body_s_systems_m45536_212, t_the_cellular_basis_of_inheritance_m45466_165, t_reproduction_at_the_cellular_level_m45455_16, t_the_body_s_systems_m45538_197, t_how_cells_obtain_energy_m45437_11, t_the_cellular_basis_of_inheritance_m45465_68, t_the_body_s_systems_m45537_337, t_the_body_s_systems_m45539_28, t_the_body_s_systems_m45536_61, t_reproduction_at_the_cellular_level_m45455_9, t_the_cellular_basis_of_inheritance_m45466_106, t_the_cellular_basis_of_inheritance_m45466_119, t_how_cells_obtain_energy_m45438_42, t_the_cellular_basis_of_inheritance_m45467_83, t_cell_structure_and_function_m45432_162, t_molbio_m45480_30, t_cell_structure_and_function_m45432_158, t_molbio_m45476_20, t_the_body_s_systems_m45539_132, t_the_body_s_systems_m45537_336, t_reproduction_at_the_cellular_level_m45461_141]

end BioLean.M2.Evidence
