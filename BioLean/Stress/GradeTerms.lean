import BioLean.Derivation
import BioLean.Lib.TextbookClaimsR2.CellStructureAndFunction
import BioLean.Lib.TextbookClaimsR2.HowCellsObtainEnergy
import BioLean.Lib.TextbookClaimsR2.MolecularBiology
import BioLean.Lib.TextbookClaimsR2.ReproductionAtTheCellularLevel
import BioLean.Lib.TextbookClaimsR3.CellStructureAndFunction
import BioLean.Lib.TextbookClaimsR3.HowCellsObtainEnergy
import BioLean.Lib.TextbookClaimsR3.MolecularBiology
import BioLean.Lib.TextbookClaimsR3.Photosynthesis
import BioLean.Lib.TextbookClaimsR3.TheBodySSystemsA

/-!
# Program 05 stress set: grade terms, on the current core

Grade terms (prokaryote, protist, algae, invertebrate, fish, broad "plants", "animal cell") name
groups that are not clades. This file runs the stress set of `docs/programs/05-grade-terms.md` on
the **current core only**: the compiled textbook statements (`BioLean/Lib/TextbookClaimsR2`, `R3`),
the existing derivation rules, and extra *statements* where an option needs only data (a CL bridge,
GO's union class, a split). Prototypes that change the core are in `BioLean/Proto/TaxonUnion.lean`.

A **member test** asks: given that taxon `x` is_a `T` (NCBI Taxonomy), does BioLean derive the
sentence for `x`? A derived conclusion is a real `Derivation`, its belief pinned by `decide +kernel`.
A silent one is pinned by the failing side condition. Every row is printed (`ROW` lines) and read by
`scripts/stress/grade_cases.py` into `data/stress/05/`.

Options run here (letters as in the program doc): **a** status quo (as compiled; `a-r2` is round 2
where the rounds differ), **a+** widest clade (cellular organisms), **a'** the right clade for the
sentence (`a-bact`, `a-embryo`, and CL's `replaced_by`), **b0** GO's union class
`NCBITaxon_Union:0000004` Prokaryota as a taxon with two membership statements (data only), **d** the
cell-type route (CL:0000520) with the book's own bridge sentence m45428-13 encoded (`d-euk` uses CL's
definitions of eukaryotic and fungal cell), **f** local grade entities with membership lists, **g** the
sentence split into one statement per clade. Every option here is the current core plus statements.
-/

namespace BioLean.Stress.GradeTerms
open BioLean Rel Derivation BioLean.Textbook BioLean.Textbook.R2 BioLean.Textbook.R3

/-! ## Test members (labels checked on OLS4, 2026-10-31: `data/stress/05/curies_checked.tsv`) -/

def ecoli        : Entity .taxon := ⟨"NCBITaxon:562", "Escherichia coli"⟩
def vcholerae    : Entity .taxon := ⟨"NCBITaxon:666", "Vibrio cholerae"⟩
def synechocystis : Entity .taxon := ⟨"NCBITaxon:1148", "Synechocystis sp. PCC 6803"⟩
def gloeobacter  : Entity .taxon := ⟨"NCBITaxon:33072", "Gloeobacter violaceus"⟩
def hvol         : Entity .taxon := ⟨"NCBITaxon:2246", "Haloferax volcanii"⟩
def halo         : Entity .taxon := ⟨"NCBITaxon:2242", "Halobacterium salinarum"⟩
def sulfo        : Entity .taxon := ⟨"NCBITaxon:2285", "Sulfolobus acidocaldarius"⟩
def thermoplasma : Entity .taxon := ⟨"NCBITaxon:2303", "Thermoplasma acidophilum"⟩
def msmithii     : Entity .taxon := ⟨"NCBITaxon:2173", "Methanobrevibacter smithii"⟩
def pfal         : Entity .taxon := ⟨"NCBITaxon:5833", "Plasmodium falciparum"⟩
def chlamy       : Entity .taxon := ⟨"NCBITaxon:3055", "Chlamydomonas reinhardtii"⟩
def tbrucei      : Entity .taxon := ⟨"NCBITaxon:5691", "Trypanosoma brucei"⟩
def euglena      : Entity .taxon := ⟨"NCBITaxon:3038", "Euglena"⟩
def paramecium   : Entity .taxon := ⟨"NCBITaxon:5884", "Paramecium"⟩
def yeast        : Entity .taxon := ⟨"NCBITaxon:4932", "Saccharomyces cerevisiae"⟩
def arabidopsis  : Entity .taxon := ⟨"NCBITaxon:3702", "Arabidopsis thaliana"⟩
def epifagus     : Entity .taxon := ⟨"NCBITaxon:4177", "Epifagus virginiana"⟩
def human        : Entity .taxon := ⟨"NCBITaxon:9606", "Homo sapiens"⟩
def schmidtea    : Entity .taxon := ⟨"NCBITaxon:79327", "Schmidtea mediterranea"⟩
def amphimedon   : Entity .taxon := ⟨"NCBITaxon:400682", "Amphimedon queenslandica"⟩
def octopus      : Entity .taxon := ⟨"NCBITaxon:6645", "Octopus vulgaris"⟩
def dmel         : Entity .taxon := ⟨"NCBITaxon:7227", "Drosophila melanogaster"⟩
def scyliorhinus : Entity .taxon := ⟨"NCBITaxon:7830", "Scyliorhinus canicula"⟩
def danio        : Entity .taxon := ⟨"NCBITaxon:7955", "Danio rerio"⟩
def anolis       : Entity .taxon := ⟨"NCBITaxon:28377", "Anolis carolinensis"⟩
/-- NCBI's scientific name; "Candidatus Thiomargarita magnifica" is its other name (Volland 2022). -/
def thiomargarita : Entity .taxon := ⟨"NCBITaxon:2022461", "Candidatus Thiomargarita sp. Lot2"⟩
/-- A fern genus; its sperm have centrioles (Mizukami 1966). Added in review for case C03. -/
def marsilea     : Entity .taxon := ⟨"NCBITaxon:13815", "Marsilea"⟩

/-- Which members the imported NCBITaxon closure (`BioLean/Ontology/IsA.lean`) knows. The rest need
the lineage table below: a vocabulary gap, the same for every option. -/
theorem known_members :
    [ecoli, halo, sulfo, euglena, paramecium, yeast, arabidopsis, human, dmel].all Taxa.known = true ∧
    [vcholerae, synechocystis, gloeobacter, hvol, thermoplasma, msmithii, pfal, chlamy, tbrucei,
      epifagus, schmidtea, amphimedon, octopus, scyliorhinus, danio, anolis, thiomargarita, marsilea].all (!Taxa.known ·) = true := by
  decide +kernel

/-- NCBI Taxonomy lineages (efetch 2026-10-31, `data/stress/05/lineage.tsv`): member, ancestors. -/
def ncbiLineage : List (String × List String) := [
  -- Escherichia coli
  ("NCBITaxon:562", ["NCBITaxon:131567", "NCBITaxon:2", "NCBITaxon:3379134", "NCBITaxon:1224", "NCBITaxon:1236", "NCBITaxon:91347", "NCBITaxon:543", "NCBITaxon:561"]),
  -- Haloferax volcanii
  ("NCBITaxon:2246", ["NCBITaxon:131567", "NCBITaxon:2157", "NCBITaxon:3366610", "NCBITaxon:28890", "NCBITaxon:2290931", "NCBITaxon:183963", "NCBITaxon:2235", "NCBITaxon:1644056", "NCBITaxon:2251"]),
  -- Halobacterium salinarum
  ("NCBITaxon:2242", ["NCBITaxon:131567", "NCBITaxon:2157", "NCBITaxon:3366610", "NCBITaxon:28890", "NCBITaxon:2290931", "NCBITaxon:183963", "NCBITaxon:2235", "NCBITaxon:2236", "NCBITaxon:2239"]),
  -- Sulfolobus acidocaldarius
  ("NCBITaxon:2285", ["NCBITaxon:131567", "NCBITaxon:2157", "NCBITaxon:1783275", "NCBITaxon:28889", "NCBITaxon:183924", "NCBITaxon:2281", "NCBITaxon:118883", "NCBITaxon:2284"]),
  -- Thermoplasma acidophilum
  ("NCBITaxon:2303", ["NCBITaxon:131567", "NCBITaxon:2157", "NCBITaxon:3366610", "NCBITaxon:2283796", "NCBITaxon:183967", "NCBITaxon:2301", "NCBITaxon:46659", "NCBITaxon:2302"]),
  -- Vibrio cholerae
  ("NCBITaxon:666", ["NCBITaxon:131567", "NCBITaxon:2", "NCBITaxon:3379134", "NCBITaxon:1224", "NCBITaxon:1236", "NCBITaxon:135623", "NCBITaxon:641", "NCBITaxon:662"]),
  -- Methanobrevibacter smithii
  ("NCBITaxon:2173", ["NCBITaxon:131567", "NCBITaxon:2157", "NCBITaxon:3366610", "NCBITaxon:28890", "NCBITaxon:2283794", "NCBITaxon:183925", "NCBITaxon:2158", "NCBITaxon:2159", "NCBITaxon:2172"]),
  -- Synechocystis sp. PCC 6803
  ("NCBITaxon:1148", ["NCBITaxon:131567", "NCBITaxon:2", "NCBITaxon:1783272", "NCBITaxon:1798711", "NCBITaxon:1117", "NCBITaxon:3028117", "NCBITaxon:1890424", "NCBITaxon:1890428", "NCBITaxon:1142", "NCBITaxon:2640012"]),
  -- Plasmodium falciparum
  ("NCBITaxon:5833", ["NCBITaxon:131567", "NCBITaxon:2759", "NCBITaxon:2698737", "NCBITaxon:33630", "NCBITaxon:5794", "NCBITaxon:422676", "NCBITaxon:5819", "NCBITaxon:1639119", "NCBITaxon:5820", "NCBITaxon:418107"]),
  -- Chlamydomonas reinhardtii
  ("NCBITaxon:3055", ["NCBITaxon:131567", "NCBITaxon:2759", "NCBITaxon:33090", "NCBITaxon:3041", "NCBITaxon:2692248", "NCBITaxon:3166", "NCBITaxon:2812636", "NCBITaxon:3042", "NCBITaxon:3051", "NCBITaxon:3052"]),
  -- Amphimedon queenslandica
  ("NCBITaxon:400682", ["NCBITaxon:131567", "NCBITaxon:2759", "NCBITaxon:33154", "NCBITaxon:33208", "NCBITaxon:6040", "NCBITaxon:6042", "NCBITaxon:1779146", "NCBITaxon:6049", "NCBITaxon:178475", "NCBITaxon:178513"]),
  -- Scyliorhinus canicula
  ("NCBITaxon:7830", ["NCBITaxon:131567", "NCBITaxon:2759", "NCBITaxon:33154", "NCBITaxon:33208", "NCBITaxon:6072", "NCBITaxon:33213", "NCBITaxon:33511", "NCBITaxon:7711", "NCBITaxon:89593", "NCBITaxon:7742", "NCBITaxon:7776", "NCBITaxon:7777", "NCBITaxon:7778", "NCBITaxon:119203", "NCBITaxon:119197", "NCBITaxon:119195", "NCBITaxon:30483", "NCBITaxon:7826", "NCBITaxon:7829"]),
  -- Anolis carolinensis
  ("NCBITaxon:28377", ["NCBITaxon:131567", "NCBITaxon:2759", "NCBITaxon:33154", "NCBITaxon:33208", "NCBITaxon:6072", "NCBITaxon:33213", "NCBITaxon:33511", "NCBITaxon:7711", "NCBITaxon:89593", "NCBITaxon:7742", "NCBITaxon:7776", "NCBITaxon:117570", "NCBITaxon:117571", "NCBITaxon:8287", "NCBITaxon:1338369", "NCBITaxon:32523", "NCBITaxon:32524", "NCBITaxon:8457", "NCBITaxon:32561", "NCBITaxon:8504", "NCBITaxon:8509", "NCBITaxon:1329961", "NCBITaxon:1329950", "NCBITaxon:1329912", "NCBITaxon:1329911", "NCBITaxon:8511", "NCBITaxon:3843548", "NCBITaxon:28376"]),
  -- Drosophila melanogaster
  ("NCBITaxon:7227", ["NCBITaxon:131567", "NCBITaxon:2759", "NCBITaxon:33154", "NCBITaxon:33208", "NCBITaxon:6072", "NCBITaxon:33213", "NCBITaxon:33317", "NCBITaxon:1206794", "NCBITaxon:88770", "NCBITaxon:6656", "NCBITaxon:197563", "NCBITaxon:197562", "NCBITaxon:3701028", "NCBITaxon:3701030", "NCBITaxon:6960", "NCBITaxon:50557", "NCBITaxon:85512", "NCBITaxon:7496", "NCBITaxon:33340", "NCBITaxon:3701061", "NCBITaxon:33392", "NCBITaxon:3701062", "NCBITaxon:3701063", "NCBITaxon:7147", "NCBITaxon:7203", "NCBITaxon:43733", "NCBITaxon:480118", "NCBITaxon:480117", "NCBITaxon:43738", "NCBITaxon:43741", "NCBITaxon:43746", "NCBITaxon:7214", "NCBITaxon:43845", "NCBITaxon:46877", "NCBITaxon:7215", "NCBITaxon:32341", "NCBITaxon:32346", "NCBITaxon:32351"]),
  -- Octopus vulgaris
  ("NCBITaxon:6645", ["NCBITaxon:131567", "NCBITaxon:2759", "NCBITaxon:33154", "NCBITaxon:33208", "NCBITaxon:6072", "NCBITaxon:33213", "NCBITaxon:33317", "NCBITaxon:2697495", "NCBITaxon:1206795", "NCBITaxon:6447", "NCBITaxon:6605", "NCBITaxon:6606", "NCBITaxon:215451", "NCBITaxon:6638", "NCBITaxon:6646", "NCBITaxon:6647", "NCBITaxon:6643"]),
  -- Gloeobacter violaceus
  ("NCBITaxon:33072", ["NCBITaxon:131567", "NCBITaxon:2", "NCBITaxon:1783272", "NCBITaxon:1798711", "NCBITaxon:1117", "NCBITaxon:3028117", "NCBITaxon:307595", "NCBITaxon:1890422", "NCBITaxon:33071"]),
  -- Trypanosoma brucei
  ("NCBITaxon:5691", ["NCBITaxon:131567", "NCBITaxon:2759", "NCBITaxon:2611352", "NCBITaxon:33682", "NCBITaxon:5653", "NCBITaxon:2704647", "NCBITaxon:2704949", "NCBITaxon:5654", "NCBITaxon:5690", "NCBITaxon:39700"]),
  -- Lumbricus terrestris
  ("NCBITaxon:6398", ["NCBITaxon:131567", "NCBITaxon:2759", "NCBITaxon:33154", "NCBITaxon:33208", "NCBITaxon:6072", "NCBITaxon:33213", "NCBITaxon:33317", "NCBITaxon:2697495", "NCBITaxon:1206795", "NCBITaxon:6340", "NCBITaxon:42113", "NCBITaxon:6381", "NCBITaxon:2803884", "NCBITaxon:6391", "NCBITaxon:6392", "NCBITaxon:1046325", "NCBITaxon:6397", "NCBITaxon:1050931"]),
  -- Schmidtea mediterranea
  ("NCBITaxon:79327", ["NCBITaxon:131567", "NCBITaxon:2759", "NCBITaxon:33154", "NCBITaxon:33208", "NCBITaxon:6072", "NCBITaxon:33213", "NCBITaxon:33317", "NCBITaxon:2697495", "NCBITaxon:1206795", "NCBITaxon:6157", "NCBITaxon:147100", "NCBITaxon:6159", "NCBITaxon:1292243", "NCBITaxon:1292253", "NCBITaxon:31262", "NCBITaxon:55270"]),
  -- Saccharomyces cerevisiae
  ("NCBITaxon:4932", ["NCBITaxon:131567", "NCBITaxon:2759", "NCBITaxon:33154", "NCBITaxon:4751", "NCBITaxon:451864", "NCBITaxon:4890", "NCBITaxon:716545", "NCBITaxon:147537", "NCBITaxon:4891", "NCBITaxon:4892", "NCBITaxon:4893", "NCBITaxon:4930"]),
  -- Homo sapiens
  ("NCBITaxon:9606", ["NCBITaxon:131567", "NCBITaxon:2759", "NCBITaxon:33154", "NCBITaxon:33208", "NCBITaxon:6072", "NCBITaxon:33213", "NCBITaxon:33511", "NCBITaxon:7711", "NCBITaxon:89593", "NCBITaxon:7742", "NCBITaxon:7776", "NCBITaxon:117570", "NCBITaxon:117571", "NCBITaxon:8287", "NCBITaxon:1338369", "NCBITaxon:32523", "NCBITaxon:32524", "NCBITaxon:40674", "NCBITaxon:32525", "NCBITaxon:9347", "NCBITaxon:1437010", "NCBITaxon:314146", "NCBITaxon:9443", "NCBITaxon:376913", "NCBITaxon:314293", "NCBITaxon:9526", "NCBITaxon:314295", "NCBITaxon:9604", "NCBITaxon:207598", "NCBITaxon:9605"]),
  -- Arabidopsis thaliana
  ("NCBITaxon:3702", ["NCBITaxon:131567", "NCBITaxon:2759", "NCBITaxon:33090", "NCBITaxon:35493", "NCBITaxon:131221", "NCBITaxon:3193", "NCBITaxon:58023", "NCBITaxon:78536", "NCBITaxon:58024", "NCBITaxon:3398", "NCBITaxon:1437183", "NCBITaxon:71240", "NCBITaxon:91827", "NCBITaxon:1437201", "NCBITaxon:71275", "NCBITaxon:91836", "NCBITaxon:3699", "NCBITaxon:3700", "NCBITaxon:980083", "NCBITaxon:3701"]),
  -- Danio rerio
  ("NCBITaxon:7955", ["NCBITaxon:131567", "NCBITaxon:2759", "NCBITaxon:33154", "NCBITaxon:33208", "NCBITaxon:6072", "NCBITaxon:33213", "NCBITaxon:33511", "NCBITaxon:7711", "NCBITaxon:89593", "NCBITaxon:7742", "NCBITaxon:7776", "NCBITaxon:117570", "NCBITaxon:117571", "NCBITaxon:7898", "NCBITaxon:186623", "NCBITaxon:41665", "NCBITaxon:32443", "NCBITaxon:1489341", "NCBITaxon:186625", "NCBITaxon:186634", "NCBITaxon:32519", "NCBITaxon:186626", "NCBITaxon:186627", "NCBITaxon:7952", "NCBITaxon:30727", "NCBITaxon:2743709", "NCBITaxon:2743711", "NCBITaxon:7954"]),
  -- Euglena gracilis
  ("NCBITaxon:3039", ["NCBITaxon:131567", "NCBITaxon:2759", "NCBITaxon:2611352", "NCBITaxon:33682", "NCBITaxon:3035", "NCBITaxon:2570567", "NCBITaxon:2704141", "NCBITaxon:86650", "NCBITaxon:1131320", "NCBITaxon:3038"]),
  -- Ectocarpus siliculosus
  ("NCBITaxon:2880", ["NCBITaxon:131567", "NCBITaxon:2759", "NCBITaxon:2698737", "NCBITaxon:33634", "NCBITaxon:2696291", "NCBITaxon:569578", "NCBITaxon:2870", "NCBITaxon:2877", "NCBITaxon:2878", "NCBITaxon:2879"]),
  -- Epifagus virginiana
  ("NCBITaxon:4177", ["NCBITaxon:131567", "NCBITaxon:2759", "NCBITaxon:33090", "NCBITaxon:35493", "NCBITaxon:131221", "NCBITaxon:3193", "NCBITaxon:58023", "NCBITaxon:78536", "NCBITaxon:58024", "NCBITaxon:3398", "NCBITaxon:1437183", "NCBITaxon:71240", "NCBITaxon:91827", "NCBITaxon:1437201", "NCBITaxon:71274", "NCBITaxon:91888", "NCBITaxon:4143", "NCBITaxon:91896", "NCBITaxon:216770", "NCBITaxon:4176"]),
  -- Candidatus Thiomargarita sp. Lot2
  ("NCBITaxon:2022461", ["NCBITaxon:131567", "NCBITaxon:2", "NCBITaxon:3379134", "NCBITaxon:1224", "NCBITaxon:1236", "NCBITaxon:72273", "NCBITaxon:135617", "NCBITaxon:90372"]),
  -- Monocercomonoides exilis
  ("NCBITaxon:2049356", ["NCBITaxon:131567", "NCBITaxon:2759", "NCBITaxon:2611341", "NCBITaxon:2662611", "NCBITaxon:66288", "NCBITaxon:302780", "NCBITaxon:302781"]),
  -- Marsilea
  ("NCBITaxon:13815", ["NCBITaxon:131567", "NCBITaxon:2759", "NCBITaxon:33090", "NCBITaxon:35493", "NCBITaxon:131221", "NCBITaxon:3193", "NCBITaxon:58023", "NCBITaxon:78536", "NCBITaxon:241806", "NCBITaxon:1521262", "NCBITaxon:74353", "NCBITaxon:13814"])
]

/-- `x` is_a `T`: the imported closure, else the NCBI lineage table. Data, not core. -/
def memberOf (x T : String) : Bool :=
  x == T || Taxa.isA x T || ((ncbiLineage.lookup x).getD []).contains T

/-- A lineage fact as an axiom. `decide` checks it, so a false lineage does not elaborate. -/
def isaTax (x T : Entity .taxon) (_h : memberOf x.curie T.curie = true := by decide) : Statement :=
  { id := s!"lineage:{x.curie}<{T.curie}", text := s!"{x.label} is_a {T.label}", claim := .rel isA x T,
    evidence := [{ pmid := 0, year := 2026, kind := .curatedDb, note := "NCBI Taxonomy, data/stress/05/lineage.tsv" }] }

def lin (x T : Entity .taxon) (h : memberOf x.curie T.curie = true := by decide) :
    Derivation (.rel isA x T) := .lit (isaTax x T h)

/-! ## Narrowing, built only from existing rules -/

theorem isA_any (k k' : Kind) : Rel.isA.accepts k k' = true := by cases k <;> cases k' <;> decide
theorem inTaxon_any (k : Kind) : Rel.inTaxon.accepts k .taxon = true := by cases k <;> decide

/-- `x is_a T` gives `a ⊓ in_taxon x is_a a ⊓ in_taxon T` (`refineMono`). -/
def refineTaxon {k : Kind} (a : Entity k) {x T : Entity .taxon} (xT : Derivation (.rel isA x T)) :
    Derivation (.rel isA (a.inCtx { taxon := some x }) (a.inCtx { taxon := some T }) (isA_any k k)) :=
  .refineMono (e := a) (r := inTaxon) (hr := inTaxon_any k) (h' := isA_any k k) xT

/-- A relation of `a ⊓ in_taxon T` holds of `a ⊓ in_taxon x` (`relChain`, is_a law). -/
def narrowRel {k₁ k₂ : Kind} {a : Entity k₁} {r : Rel} {b : Entity k₂} {h : r.accepts k₁ k₂ = true}
    {T : Entity .taxon} (x : Entity .taxon) (xT : Derivation (.rel isA x T))
    (d : Derivation (.rel r (a.inCtx { taxon := some T }) b h))
    (ok : RO.chainOK isA r r = true := by decide) : Derivation (.rel r (a.inCtx { taxon := some x }) b h) :=
  .relChain (refineTaxon a xT) d ok h

/-- A negation of `a ⊓ in_taxon T` holds of `a ⊓ in_taxon x` (`notRelSub`). -/
def narrowNot {k₁ k₂ : Kind} {a : Entity k₁} {r : Rel} {b : Entity k₂} {h : r.accepts k₁ k₂ = true}
    {T : Entity .taxon} (x : Entity .taxon) (xT : Derivation (.rel isA x T))
    (d : Derivation (.notRel r (a.inCtx { taxon := some T }) b h)) :
    Derivation (.notRel r (a.inCtx { taxon := some x }) b h) :=
  .notRelSub (refineTaxon a xT) d h

/-- A relation of the taxon `T` itself holds of a member `x`. -/
def narrowTaxon {k : Kind} {r : Rel} {b : Entity k} {h : r.accepts .taxon k = true} {T : Entity .taxon}
    (x : Entity .taxon) (xT : Derivation (.rel isA x T)) (d : Derivation (.rel r T b h))
    (ok : RO.chainOK isA r r = true := by decide) : Derivation (.rel r x b h) :=
  .relChain xT d ok h

/-- An effect of `a ⊓ in_taxon T` holds of `a ⊓ in_taxon x` (`isaInheritEffect`). -/
def narrowEffect {k : Kind} {a : Entity k} {s : Sign} {t : Target} {T : Entity .taxon}
    (x : Entity .taxon) (xT : Derivation (.rel isA x T)) (d : Derivation (.effect (a.inCtx { taxon := some T }) s t)) :
    Derivation (.effect (a.inCtx { taxon := some x }) s t) :=
  .isaInheritEffect (refineTaxon a xT) d

/-- A subclass inherits a relation (`relChain`, is_a law), with the relation fixed. -/
def inherit {k₁ k₂ : Kind} {a c : Entity k₁} {r : Rel} {b : Entity k₂} {h : r.accepts k₁ k₂ = true}
    {hac : isA.accepts k₁ k₁ = true} (ac : Derivation (.rel isA a c hac)) (d : Derivation (.rel r c b h))
    (ok : RO.chainOK isA r r = true := by decide) : Derivation (.rel r a b h) :=
  .relChain ac d ok h

/-- Drop a taxon context for free (`Entity.refineAxiom`), then inherit: how a context-free claim
reaches every taxon. -/
def toTaxon {k₁ k₂ : Kind} {a : Entity k₁} {r : Rel} {b : Entity k₂} {h : r.accepts k₁ k₂ = true}
    (x : Entity .taxon) (d : Derivation (.rel r a b h)) (ok : RO.chainOK isA r r = true := by decide) :
    Derivation (.rel r (a.inCtx { taxon := some x }) b h) :=
  .relChain (.lit (Entity.refineAxiom a inTaxon x (inTaxon_any k₁) (isA_any k₁ k₁))) d ok h

/-! ## Rows: what each option concludes for each member, printed for `grade_cases.py` -/

structure Row where
  case : String
  option : String
  member : String
  obs : String

def concl {c : Claim} (d : Derivation c) : String := s!"concl b={d.opinion.belief}"
/-- Silent because `x` is not a member of `T`, checked: a wrong lineage prints `CHECK FAILED`. -/
def notIn (x T : Entity .taxon) : String :=
  if memberOf x.curie T.curie then "CHECK FAILED" else s!"silent: not is_a {T.curie}"
def silent (why : String) : String := s!"silent: {why}"
def inexpr (why : String) : String := s!"inexpressible: {why}"

/-! ## Option data: the union class, the CL bridge, the widest clade

* **b0.** GO's `NCBITaxon_Union:0000004` "Prokaryota" is `owl:unionOf (NCBITaxon:2, NCBITaxon:2157)`
  (go-plus via OLS4, created 2008 for taxon constraints, Deegan 2010). As a taxon entity with two
  membership statements it needs no core change for narrowing.
* **d.** The book says it itself: m45428-13 "Bacterial and archaeal cells are classified as
  prokaryotic" (blocked in round 2 as ungrounded). Encoded as two is_a statements into CL:0000520. -/

def prokaryota : Entity .taxon := ⟨"NCBITaxon_Union:0000004", "Prokaryota"⟩

/-- The parts of GO's union classes used here (`data/stress/05/go_union_taxa.tsv`). -/
def unionParts : List (String × List String) :=
  [("NCBITaxon_Union:0000004", ["NCBITaxon:2", "NCBITaxon:2157"])]

def unionMember (part U : Entity .taxon)
    (_h : ((unionParts.lookup U.curie).getD []).contains part.curie = true := by decide) : Statement :=
  { id := s!"union:{part.curie}<{U.curie}", text := s!"{part.label} is_a {U.label}", claim := .rel isA part U,
    evidence := [{ pmid := 0, year := 2026, kind := .ontologyAxiom, note := "GO go-plus owl:unionOf, OLS4 2026-10-31" }] }

/-- `x is_a part is_a U`, by is_a transitivity. -/
def linU (x part U : Entity .taxon) (h : memberOf x.curie part.curie = true := by decide)
    (hu : ((unionParts.lookup U.curie).getD []).contains part.curie = true := by decide) :
    Derivation (.rel isA x U) :=
  .relChain (lin x part h) (.lit (unionMember part U hu)) (by decide) (by decide)

/-- m45428-13 as statements: a cell of a bacterium (archaeon) is a prokaryotic cell. -/
def bridge (T : Entity .taxon) : Statement :=
  { id := s!"cell-structure-and-function-m45428-13/{T.curie}",
    text := "Bacterial and archaeal cells are prokaryotic",
    claim := .rel isA (e_CL_0000000.inCtx { taxon := some T }) e_CL_0000520,
    evidence := [{ pmid := 0, year := 2013, kind := .textbook, note := "Animal cells, plant cells, fungal cells, and protist cells are classified as eukaryotic, whereas bacteria and archaea cells are classified as prokaryotic." }] }

/-- A cell of member `x` is a prokaryotic cell, through the bridge for its domain `T`. -/
def cellOf (x T : Entity .taxon) (h : memberOf x.curie T.curie = true := by decide) :
    Derivation (.rel isA (e_CL_0000000.inCtx { taxon := some x }) e_CL_0000520) :=
  .relChain (refineTaxon e_CL_0000000 (lin x T h)) (.lit (bridge T)) (by decide) (by decide)

/-- The same statement with another taxon in its context: option a+ or b0 re-annotation. -/
def retax (s : Statement) (c : Claim) (tag : String) : Statement := { s with id := s!"{s.id}/{tag}", claim := c }

/-- Silent because `x` is in no part of the union class `U`, checked. -/
def notInU (x U : Entity .taxon) : String :=
  if ((unionParts.lookup U.curie).getD []).any (memberOf x.curie ·) then "CHECK FAILED"
  else s!"silent: in no part of {U.curie}"
def row (c o : String) (x : Entity .taxon) (obs : String) : Row := ⟨c, o, x.label, obs⟩
def row0 (c o what obs : String) : Row := ⟨c, o, what, obs⟩

/-- An is_a edge of the imported closure (GO, CL, ...) as an axiom; `decide` checks it. -/
def isaOnt {k : Kind} (a b : Entity k) (_h : Ontology.isACurie a.curie b.curie = true := by decide) : Statement :=
  { id := s!"isa:{a.curie}<{b.curie}", text := s!"{a.label} is_a {b.label}", claim := .rel isA a b (isA_any k k),
    evidence := [{ pmid := 0, year := 2026, kind := .ontologyAxiom, note := "BioLean/Ontology/IsA.lean" }] }

/-! # Prokaryote: true of the union (Bacteria and Archaea)

## G05-P01. molbio-m45476-20 "In prokaryotes, transcription occurs in the cytoplasm"
Round 3: `transcription ⊓ in_taxon Bacteria occurs_in cytoplasm`. True of every prokaryote (no
nucleus, m45476-18). The eukaryote half is m45480-85, transcription in the nucleus. -/

abbrev P01 := R3.MolecularBiology.molbio_m45476_20
abbrev P01euk := R3.MolecularBiology.molbio_m45480_85
def P01w := retax P01 (.rel occursIn (e_GO_0006351.inCtx { taxon := some e_NCBITaxon_131567 }) e_GO_0005737) "a+"
def P01u := retax P01 (.rel occursIn (e_GO_0006351.inCtx { taxon := some prokaryota }) e_GO_0005737) "b0"
def P01arch := retax P01 (.rel occursIn (e_GO_0006351.inCtx { taxon := some e_NCBITaxon_2157 }) e_GO_0005737) "g:Archaea"

def P01_a_ecoli := narrowRel ecoli (lin ecoli e_NCBITaxon_2) (.lit P01)
def P01_a_human_nucleus := narrowRel human (lin human e_NCBITaxon_2759) (.lit P01euk)
def P01_w_ecoli := narrowRel ecoli (lin ecoli e_NCBITaxon_131567) (.lit P01w)
def P01_w_halo := narrowRel halo (lin halo e_NCBITaxon_131567) (.lit P01w)
def P01_w_human := narrowRel human (lin human e_NCBITaxon_131567) (.lit P01w)
def P01_u_ecoli := narrowRel ecoli (linU ecoli e_NCBITaxon_2 prokaryota) (.lit P01u)
def P01_u_halo := narrowRel halo (linU halo e_NCBITaxon_2157 prokaryota) (.lit P01u)
def P01_u_sulfo := narrowRel sulfo (linU sulfo e_NCBITaxon_2157 prokaryota) (.lit P01u)
def P01_u_hvol := narrowRel hvol (linU hvol e_NCBITaxon_2157 prokaryota) (.lit P01u)
def P01_g_halo := narrowRel halo (lin halo e_NCBITaxon_2157) (.lit P01arch)

theorem P01_a_ecoli_b : P01_a_ecoli.opinion.belief = 4/5 := by decide +kernel
theorem P01_a_archaea_silent :
    [halo, sulfo, hvol].all (fun x => !memberOf x.curie e_NCBITaxon_2.curie) = true := by decide
theorem P01_w_human_b : P01_w_human.opinion.belief = 4/5 := by decide +kernel
theorem P01_u_halo_b : P01_u_halo.opinion.belief = 4/5 := by decide +kernel
theorem P01_u_human_silent :
    (((unionParts.lookup prokaryota.curie).getD []).any (memberOf human.curie ·)) = false := by decide
theorem P01_g_halo_b : P01_g_halo.opinion.belief = 4/5 := by decide +kernel

def P01_rows : List Row := [
  row "G05-P01" "a" ecoli (concl P01_a_ecoli), row "G05-P01" "a" halo (notIn halo e_NCBITaxon_2),
  row "G05-P01" "a" sulfo (notIn sulfo e_NCBITaxon_2), row "G05-P01" "a" hvol (notIn hvol e_NCBITaxon_2),
  row "G05-P01" "a" human (notIn human e_NCBITaxon_2),
  row "G05-P01" "a+" ecoli (concl P01_w_ecoli), row "G05-P01" "a+" halo (concl P01_w_halo),
  row "G05-P01" "a+" human (concl P01_w_human),
  row "G05-P01" "b0" ecoli (concl P01_u_ecoli), row "G05-P01" "b0" halo (concl P01_u_halo),
  row "G05-P01" "b0" sulfo (concl P01_u_sulfo), row "G05-P01" "b0" hvol (concl P01_u_hvol),
  row "G05-P01" "b0" human (notInU human prokaryota),
  row "G05-P01" "g" ecoli (concl P01_a_ecoli), row "G05-P01" "g" halo (concl P01_g_halo),
  row "G05-P01" "g" human (if memberOf human.curie "NCBITaxon:2" || memberOf human.curie "NCBITaxon:2157" then "CHECK FAILED" else "silent: in neither split statement")]

/-! ## G05-P02. how-cells-obtain-energy-m45439-48 "The electron transport chain is ... in the plasma
membrane of prokaryotes". Round 3 Bacteria. The case behind the provisional decision: with
"cellular organisms" it reaches humans, whose chain is in the inner mitochondrial membrane (m45439-47). -/

abbrev P02 := R3.HowCellsObtainEnergy.how_cells_obtain_energy_m45439_48
abbrev P02euk := R3.HowCellsObtainEnergy.how_cells_obtain_energy_m45439_47
def P02w := retax P02 (.rel occursIn (e_GO_0022904.inCtx { taxon := some e_NCBITaxon_131567 }) e_GO_0005886) "a+"
def P02u := retax P02 (.rel occursIn (e_GO_0022904.inCtx { taxon := some prokaryota }) e_GO_0005886) "b0"

def P02_a_ecoli := narrowRel ecoli (lin ecoli e_NCBITaxon_2) (.lit P02)
def P02_a_human_mito := narrowRel human (lin human e_NCBITaxon_2759) (.lit P02euk)
def P02_w_human := narrowRel human (lin human e_NCBITaxon_131567) (.lit P02w)
def P02_w_sulfo := narrowRel sulfo (lin sulfo e_NCBITaxon_131567) (.lit P02w)
def P02_u_ecoli := narrowRel ecoli (linU ecoli e_NCBITaxon_2 prokaryota) (.lit P02u)
def P02_u_sulfo := narrowRel sulfo (linU sulfo e_NCBITaxon_2157 prokaryota) (.lit P02u)
def P02_u_halo := narrowRel halo (linU halo e_NCBITaxon_2157 prokaryota) (.lit P02u)

theorem P02_w_human_b : P02_w_human.opinion.belief = 4/5 := by decide +kernel
theorem P02_a_human_mito_b : P02_a_human_mito.opinion.belief = 4/5 := by decide +kernel
theorem P02_u_sulfo_b : P02_u_sulfo.opinion.belief = 4/5 := by decide +kernel

def P02_rows : List Row := [
  row "G05-P02" "a" ecoli (concl P02_a_ecoli), row "G05-P02" "a" sulfo (notIn sulfo e_NCBITaxon_2),
  row "G05-P02" "a" halo (notIn halo e_NCBITaxon_2), row "G05-P02" "a" human (notIn human e_NCBITaxon_2),
  row "G05-P02" "a+" ecoli (concl (narrowRel ecoli (lin ecoli e_NCBITaxon_131567) (.lit P02w))),
  row "G05-P02" "a+" sulfo (concl P02_w_sulfo), row "G05-P02" "a+" human (concl P02_w_human),
  row "G05-P02" "b0" ecoli (concl P02_u_ecoli), row "G05-P02" "b0" sulfo (concl P02_u_sulfo),
  row "G05-P02" "b0" halo (concl P02_u_halo), row "G05-P02" "b0" human (notInU human prokaryota)]

/-! ## G05-P03. molbio-m45479-20 "In prokaryotes ribosomes are located in the cytoplasm". Round 3 Bacteria. -/

abbrev P03 := R3.MolecularBiology.molbio_m45479_20
def P03u := retax P03 (.rel locatedIn (e_GO_0005840.inCtx { taxon := some prokaryota }) e_GO_0005737) "b0"
def P03_a_ecoli := narrowRel ecoli (lin ecoli e_NCBITaxon_2) (.lit P03)
def P03_u_halo := narrowRel halo (linU halo e_NCBITaxon_2157 prokaryota) (.lit P03u)
def P03_u_sulfo := narrowRel sulfo (linU sulfo e_NCBITaxon_2157 prokaryota) (.lit P03u)
theorem P03_u_halo_b : P03_u_halo.opinion.belief = 4/5 := by decide +kernel

def P03_rows : List Row := [
  row "G05-P03" "a" ecoli (concl P03_a_ecoli), row "G05-P03" "a" halo (notIn halo e_NCBITaxon_2),
  row "G05-P03" "a" sulfo (notIn sulfo e_NCBITaxon_2),
  row "G05-P03" "b0" ecoli (concl (narrowRel ecoli (linU ecoli e_NCBITaxon_2 prokaryota) (.lit P03u))),
  row "G05-P03" "b0" halo (concl P03_u_halo), row "G05-P03" "b0" sulfo (concl P03_u_sulfo)]

/-! ## The cell-type route (round 2 encodes "prokaryote" as CL:0000520)

Round 2 states prokaryote facts of the cell type `prokaryotic cell`. Nothing links an organism to it:
CL gives CL:0000520 only `never_in_taxon Eukaryota`, the closure has `prokaryotic cell is_a cell` and
no taxon, and the book's bridge sentence m45428-13 was blocked. So today every CL-route fact is
silent for every organism (option a). Option d adds the bridge. -/

theorem cl_no_taxon_link : Ontology.isACurie "CL:0000520" "NCBITaxon:2" = false ∧
    Ontology.isACurie "CL:0000520" "CL:0000000" = true := by decide

/-! ## G05-P04. reproduction-at-the-cellular-level-m45463-1 "Prokaryotes such as bacteria reproduce
by binary fission". Round 2: `prokaryotic cell capable_of GO:0043093`, whose label is
"FtsZ-dependent cytokinesis". Sulfolobus has no FtsZ (Lindås 2008); H. volcanii does (Liao 2021). -/

abbrev P04 := R2.ReproductionAtTheCellularLevel.reproduction_at_the_cellular_level_m45463_1
def P04_d_ecoli := inherit (cellOf ecoli e_NCBITaxon_2) (.lit P04)
def P04_d_hvol := inherit (cellOf hvol e_NCBITaxon_2157) (.lit P04)
def P04_d_sulfo := inherit (cellOf sulfo e_NCBITaxon_2157) (.lit P04)
theorem P04_d_sulfo_b : P04_d_sulfo.opinion.belief = 4/5 := by decide +kernel

def P04_rows : List Row := [
  row "G05-P04" "a" ecoli (silent "no taxon-to-CL:0000520 link"), row "G05-P04" "a" hvol (silent "no taxon-to-CL:0000520 link"),
  row "G05-P04" "a" sulfo (silent "no taxon-to-CL:0000520 link"),
  row "G05-P04" "d" ecoli (concl P04_d_ecoli), row "G05-P04" "d" hvol (concl P04_d_hvol),
  row "G05-P04" "d" sulfo (concl P04_d_sulfo)]

/-! ## G05-P05. molbio-m45476-18 "Prokaryotes lack a membrane-bound nucleus". Round 2 `notRel`. -/

abbrev P05 := R2.MolecularBiology.molbio_m45476_18
def P05_d_ecoli := Derivation.notRelSub (cellOf ecoli e_NCBITaxon_2) (.lit P05)
def P05_d_halo := Derivation.notRelSub (cellOf halo e_NCBITaxon_2157) (.lit P05)
def P05_d_sulfo := Derivation.notRelSub (cellOf sulfo e_NCBITaxon_2157) (.lit P05)
theorem P05_d_halo_b : P05_d_halo.opinion.belief = 4/5 := by decide +kernel

def P05_rows : List Row := [
  row "G05-P05" "a" ecoli (silent "no taxon-to-CL:0000520 link"), row "G05-P05" "a" halo (silent "no taxon-to-CL:0000520 link"),
  row "G05-P05" "a" sulfo (silent "no taxon-to-CL:0000520 link"),
  row "G05-P05" "d" ecoli (concl P05_d_ecoli), row "G05-P05" "d" halo (concl P05_d_halo),
  row "G05-P05" "d" sulfo (concl P05_d_sulfo)]

/-! ## G05-P06. cell-structure-and-function-m45429-56 "All prokaryotes have ribosomes". Round 2. -/

abbrev P06 := R2.CellStructureAndFunction.cell_structure_and_function_m45429_56
def P06_rows : List Row := [
  row "G05-P06" "a" ecoli (silent "no taxon-to-CL:0000520 link"), row "G05-P06" "a" halo (silent "no taxon-to-CL:0000520 link"),
  row "G05-P06" "d" ecoli (concl (inherit (cellOf ecoli e_NCBITaxon_2) (.lit P06))),
  row "G05-P06" "d" halo (concl (inherit (cellOf halo e_NCBITaxon_2157) (.lit P06)))]

/-! ## G05-P07. cell-structure-and-function-m45429-57 "All prokaryotes have a cell wall". Round 2.
Thermoplasma acidophilum has none (Darland 1970). An exception inside the grade, not a grade error. -/

abbrev P07 := R2.CellStructureAndFunction.cell_structure_and_function_m45429_57
def P07_d_thermoplasma := inherit (cellOf thermoplasma e_NCBITaxon_2157) (.lit P07)
theorem P07_d_thermoplasma_b : P07_d_thermoplasma.opinion.belief = 4/5 := by decide +kernel

def P07_rows : List Row := [
  row "G05-P07" "a" ecoli (silent "no taxon-to-CL:0000520 link"), row "G05-P07" "a" halo (silent "no taxon-to-CL:0000520 link"),
  row "G05-P07" "a" thermoplasma (silent "no taxon-to-CL:0000520 link"),
  row "G05-P07" "d" ecoli (concl (inherit (cellOf ecoli e_NCBITaxon_2) (.lit P07))),
  row "G05-P07" "d" halo (concl (inherit (cellOf halo e_NCBITaxon_2157) (.lit P07))),
  row "G05-P07" "d" thermoplasma (concl P07_d_thermoplasma)]

/-! ## G05-P08. cell-structure-and-function-m45429-29 "Some prokaryotes have flagella". Round 2
drops "some" and grounds flagellum as GO:0009288 bacterial-type flagellum. Archaea have the archaellum
(GO:0097589), a different structure (Jarrell 2012). Today the missing bridge hides both errors. -/

abbrev P08 := R2.CellStructureAndFunction.cell_structure_and_function_m45429_29
def P08_d_halo := inherit (cellOf halo e_NCBITaxon_2157) (.lit P08)
theorem P08_d_halo_b : P08_d_halo.opinion.belief = 4/5 := by decide +kernel
theorem P08_quantifier_dropped : (match P08.claim with | .quant _ _ => true | _ => false) = false := by decide

def P08_rows : List Row := [
  row "G05-P08" "a" ecoli (silent "no taxon-to-CL:0000520 link"), row "G05-P08" "a" halo (silent "no taxon-to-CL:0000520 link"),
  row "G05-P08" "d" ecoli (concl (inherit (cellOf ecoli e_NCBITaxon_2) (.lit P08))),
  row "G05-P08" "d" halo (concl P08_d_halo)]

/-! ## G05-P19. cell-structure-and-function-m45429-59 "All prokaryotes ... lack membrane-bound
organelles". Round 2 `¬(prokaryotic cell has_part intracellular membrane-bounded organelle)`.
Ca. Thiomargarita magnifica keeps its DNA and ribosomes in "organelles bound by bioenergetic
membranes" (Volland 2022). Through the bridge (option d) the core derives the opposite. A character
definition (option e, "no membrane-bound organelles") would instead move it out of the prokaryotes. -/

abbrev P19 := R2.CellStructureAndFunction.cell_structure_and_function_m45429_59
def P19_d_thiomargarita := Derivation.notRelSub (cellOf thiomargarita e_NCBITaxon_2) (.lit P19)
theorem P19_d_b : P19_d_thiomargarita.opinion.belief = 4/5 := by decide +kernel
def P19_rows : List Row := [
  row "G05-P19" "a" thiomargarita (silent "no taxon-to-CL:0000520 link"),
  row "G05-P19" "d" thiomargarita (concl P19_d_thiomargarita)]

/-! # Prokaryote meaning "bacterium"

## G05-P09. cell-structure-and-function-m45432-224 "The chief component of prokaryotic cell walls is
peptidoglycan". Round 2 drops the context: `cell wall has_part peptidoglycan`, for every cell wall.
Archaeal walls have no peptidoglycan (Beveridge 1996); nor do plant walls. Bacteria is the right
reading here (option a done properly); the union and the cell route are wrong for archaea. -/

abbrev P09 := R2.CellStructureAndFunction.cell_structure_and_function_m45432_224
def P09bact := retax P09 (.rel hasPart (e_GO_0005618.inCtx { taxon := some e_NCBITaxon_2 }) e_CHEBI_8005) "a:Bacteria"
def P09u := retax P09 (.rel hasPart (e_GO_0005618.inCtx { taxon := some prokaryota }) e_CHEBI_8005) "b0"

def P09_a_ecoli := toTaxon ecoli (.lit P09)
def P09_a_halo := toTaxon halo (.lit P09)
def P09_a_plantwall := inherit (.lit (isaOnt e_GO_0009505 e_GO_0005618)) (.lit P09)
def P09_bact_ecoli := narrowRel ecoli (lin ecoli e_NCBITaxon_2) (.lit P09bact)
def P09_u_halo := narrowRel halo (linU halo e_NCBITaxon_2157 prokaryota) (.lit P09u)
theorem P09_a_halo_b : P09_a_halo.opinion.belief = 4/5 := by decide +kernel
theorem P09_a_plantwall_b : P09_a_plantwall.opinion.belief = 4/5 := by decide +kernel
theorem P09_u_halo_b : P09_u_halo.opinion.belief = 4/5 := by decide +kernel

def P09_rows : List Row := [
  row "G05-P09" "a" ecoli (concl P09_a_ecoli), row "G05-P09" "a" halo (concl P09_a_halo),
  row0 "G05-P09" "a" "plant-type cell wall" (concl P09_a_plantwall),
  row "G05-P09" "a-bact" ecoli (concl P09_bact_ecoli), row "G05-P09" "a-bact" halo (notIn halo e_NCBITaxon_2),
  row0 "G05-P09" "a-bact" "plant-type cell wall" (silent "context Bacteria"),
  row "G05-P09" "b0" ecoli (concl (narrowRel ecoli (linU ecoli e_NCBITaxon_2 prokaryota) (.lit P09u))),
  row "G05-P09" "b0" halo (concl P09_u_halo)]

/-! ## G05-P10. molbio-m45475-124 "Replication in prokaryotes starts from a single origin of
replication". Round 3 `count (chromosome ⊓ in_taxon Bacteria) origin 1`. False for Sulfolobus
(three origins, Lundgren 2004) and H. volcanii (four, Hawkins 2013). **No rule narrows a `count`**:
`relChain` and the is_a laws take `rel` claims only. So every option is silent, right or wrong. -/

abbrev P10 := R3.MolecularBiology.molbio_m45475_124
/-- The claim is a `count`; `relChain`, `notRelSub` and `isaInheritEffect` take `rel`, `notRel`, `effect`. -/
theorem P10_is_count : (match P10.claim with | .count .. => true | _ => false) = true := by decide

def P10_rows : List Row := [
  row "G05-P10" "a" ecoli (silent "no rule narrows count"), row "G05-P10" "a" sulfo (silent "no rule narrows count"),
  row "G05-P10" "a" hvol (silent "no rule narrows count"),
  row "G05-P10" "b0" sulfo (silent "no rule narrows count")]

/-! ## G05-P11. molbio-m45473-130 "Prokaryotes have a single chromosome". Round 3 `count Bacteria
chromosome 1` (the book hedges in m45473-74, "most"). V. cholerae has two (Heidelberg 2000);
H. volcanii a main chromosome and three smaller ones (Hartman 2010). Silent for the same reason. -/

abbrev P11 := R3.MolecularBiology.molbio_m45473_130
def P11_rows : List Row := [
  row "G05-P11" "a" gloeobacter (silent "no rule narrows count"), row "G05-P11" "a" vcholerae (silent "no rule narrows count"),
  row "G05-P11" "b0" hvol (silent "no rule narrows count")]

/-! ## G05-P12. how-cells-obtain-energy-m45440-37 "Some bacteria and Archaea use anaerobic
respiration". Round 2 keeps only Archaea and drops "some": `Archaea capable_of anaerobic respiration`.
Sulfolobus acidocaldarius is "an aerobic thermoacidophilic crenarchaeon" (Chen 2005), and is in the
imported closure, so the pure core derives a claim that is false for it. For Halobacterium it is true:
strain NRC-1 grows on DMSO or TMAO "as the sole terminal electron acceptor" (Müller 2005). -/

abbrev P12 := R2.HowCellsObtainEnergy.how_cells_obtain_energy_m45440_37
def P12_a_sulfo := narrowTaxon sulfo (lin sulfo e_NCBITaxon_2157) (.lit P12)
def P12_a_halo := narrowTaxon halo (lin halo e_NCBITaxon_2157) (.lit P12)
theorem P12_a_sulfo_b : P12_a_sulfo.opinion.belief = 4/5 := by decide +kernel
theorem P12_sulfo_in_closure : Taxa.isA sulfo.curie e_NCBITaxon_2157.curie = true := by decide

def P12_rows : List Row := [
  row "G05-P12" "a" sulfo (concl P12_a_sulfo), row "G05-P12" "a" halo (concl P12_a_halo),
  row "G05-P12" "a" ecoli (notIn ecoli e_NCBITaxon_2157)]

/-! ## G05-P13. photosynthesis-m45453-64 "in photosynthetic prokaryotes photosynthesis occurs at
plasma membrane infoldings". Blocked in round 2 (ungrounded: "photosynthetic prokaryote" is a class
defined by a character). Here "prokaryote" rightly means bacterium. -/

def P13_rows : List Row := [
  row "G05-P13" "a" gloeobacter (inexpr "blocked: ungrounded_entity (character-defined group)"),
  row "G05-P13" "a" synechocystis (inexpr "blocked: ungrounded_entity (character-defined group)")]

/-! ## G05-P14. cell-structure-and-function-m45428-13 "Bacterial and archaeal cells are prokaryotic".
Blocked in round 2. It *is* expressible on the core: `bridge` above, two is_a statements. -/

theorem P14_bridge_b : (Derivation.lit (bridge e_NCBITaxon_2157)).opinion.belief = 4/5 := by decide +kernel
def P14_rows : List Row := [
  row0 "G05-P14" "a" "bridge statements" (silent "blocked in round 2: ungrounded_entity"),
  row0 "G05-P14" "d" "Bacteria cell is_a prokaryotic cell" (concl (Derivation.lit (bridge e_NCBITaxon_2))),
  row0 "G05-P14" "d" "Archaea cell is_a prokaryotic cell" (concl (Derivation.lit (bridge e_NCBITaxon_2157)))]

/-! ## G05-P15. molbio-m45476-17 "Prokaryotes include bacteria and archaea". Blocked. With GO's union
class it is two membership statements (b0). The converse, "every prokaryote is a bacterium or an
archaeon", is the covering half of the union and has no claim shape (see P16). -/

def P15_rows : List Row := [
  row0 "G05-P15" "a" "membership statements" (silent "blocked in round 2: ungrounded_entity"),
  row0 "G05-P15" "b0" "Bacteria is_a Prokaryota" (concl (Derivation.lit (unionMember e_NCBITaxon_2 prokaryota))),
  row0 "G05-P15" "b0" "Archaea is_a Prokaryota" (concl (Derivation.lit (unionMember e_NCBITaxon_2157 prokaryota)))]

/-! ## G05-P16. cell-structure-and-function-m45428-11 "All cells are either prokaryotic or eukaryotic".
A covering axiom, `cell ⊑ prokaryotic cell ⊔ eukaryotic cell`. No `Claim` constructor states a
disjunction. -/

def P16_rows : List Row := [row0 "G05-P16" "a" "covering axiom" (inexpr "no disjunction in Claim"),
  row0 "G05-P16" "b0" "covering axiom" (inexpr "no disjunction in Claim"),
  row0 "G05-P16" "d" "covering axiom" (inexpr "no disjunction in Claim")]

/-! ## G05-P17. how-cells-obtain-energy-m45438-62 "Both prokaryotes and eukaryotes carry out some form
of glycolysis". Round 3: `most (cellular organisms capable_of glycolysis)`; round 2 kept only
Eukaryota. Prokaryote ∪ eukaryote is a clade (cellular organisms), so the union collapses. `most`
does not narrow, so E. coli and Sulfolobus are silent. -/

abbrev P17r3 := R3.HowCellsObtainEnergy.how_cells_obtain_energy_m45438_62
abbrev P17r2 := R2.HowCellsObtainEnergy.how_cells_obtain_energy_m45438_62
theorem P17_most : (match P17r3.claim with | .quant .most _ => true | _ => false) = true := by decide

def P17_rows : List Row := [
  row "G05-P17" "a" ecoli (silent "most does not narrow"), row "G05-P17" "a" sulfo (silent "most does not narrow"),
  row "G05-P17" "a" human (silent "most does not narrow"),
  row "G05-P17" "a-r2" human (concl (narrowTaxon human (lin human e_NCBITaxon_2759) (.lit P17r2))),
  row "G05-P17" "a-r2" ecoli (notIn ecoli e_NCBITaxon_2759)]

/-! ## G05-P18. how-cells-obtain-energy-m45438-33 "Glycolysis takes place in the cytoplasm of most
prokaryotic and all eukaryotic cells". Round 2: `glycolysis occurs_in cytoplasm`, no context, no
quantifier: one claim cannot carry "most" for one part of a union and "all" for the other. Yet every
conclusion is right. Trypanosoma brucei runs most of glycolysis in glycosomes (Opperdoes 1977), and
the glycosome is part of the cytoplasm: in GO (GO:0020015 glycosome is_a peroxisome is_a microbody,
part_of GO:0005737 cytoplasm, defined as "including other subcellular structures") and in the book's
own glossary (m45432-361: cytoplasm "consisting of organelles suspended in the gel-like cytosol").
Corrected in review: the first run marked T. brucei a FAIL. -/

abbrev P18 := R2.HowCellsObtainEnergy.how_cells_obtain_energy_m45438_33
def P18_a_tbrucei := toTaxon tbrucei (.lit P18)
theorem P18_a_tbrucei_b : P18_a_tbrucei.opinion.belief = 4/5 := by decide +kernel
def P18_rows : List Row := [
  row "G05-P18" "a" tbrucei (concl P18_a_tbrucei), row "G05-P18" "a" human (concl (toTaxon human (.lit P18))),
  row "G05-P18" "a" ecoli (concl (toTaxon ecoli (.lit P18)))]

/-! # Protist (Eukaryota minus animals, plants and fungi: a grade)

## G05-R01. cell-structure-and-function-m45432-241 "Like plant cells, photosynthetic protists also
have chloroplasts". Round 3 `some (Eukaryota has_part chloroplast)`; round 2 the same without `some`.
"Photosynthetic protist" is defined by a character. Plasmodium has a plastid (the apicoplast) that does
not photosynthesise (Köhler 1997), not a chloroplast. -/

abbrev R01r3 := R3.CellStructureAndFunction.cell_structure_and_function_m45432_241
abbrev R01r2 := R2.CellStructureAndFunction.cell_structure_and_function_m45432_241
def R01_r2_human := narrowTaxon human (lin human e_NCBITaxon_2759) (.lit R01r2)
theorem R01_r2_human_b : R01_r2_human.opinion.belief = 4/5 := by decide +kernel
def R01_rows : List Row := [
  row "G05-R01" "a" chlamy (silent "some does not narrow"), row "G05-R01" "a" pfal (silent "some does not narrow"),
  row "G05-R01" "a" human (silent "some does not narrow"),
  row "G05-R01" "a-r2" chlamy (concl (narrowTaxon chlamy (lin chlamy e_NCBITaxon_2759) (.lit R01r2))),
  row "G05-R01" "a-r2" pfal (concl (narrowTaxon pfal (lin pfal e_NCBITaxon_2759) (.lit R01r2))),
  row "G05-R01" "a-r2" human (concl R01_r2_human)]

/-! ## G05-R02. cell-structure-and-function-m45432-223 "Fungal and protist cells also have cell walls".
Round 2 keeps the fungal half (`fungal cell has_part fungal-type cell wall`) and drops protists. Even
the fungal half is silent for yeast: CL defines fungal cell as `cell ⊓ in_taxon Fungi` (an
equivalence), but the is_a import keeps only named parents. Option d-euk adds that definition. -/

abbrev R02 := R2.CellStructureAndFunction.cell_structure_and_function_m45432_223
/-- CL:0000521's logical definition, one direction: a cell of a fungus is a fungal cell. -/
def fungalBridge : Statement :=
  { id := "CL:0000521-def", text := "Any cell that in taxon some Fungi.",
    claim := .rel isA (e_CL_0000000.inCtx { taxon := some Taxa.fungi }) e_CL_0000521,
    evidence := [{ pmid := 0, year := 2026, kind := .ontologyAxiom, note := "CL equivalentClass, OLS4 2026-10-31" }] }
def yeastCell : Derivation (.rel isA (e_CL_0000000.inCtx { taxon := some yeast }) e_CL_0000521) :=
  .relChain (refineTaxon e_CL_0000000 (lin yeast Taxa.fungi)) (.lit fungalBridge) (by decide) (by decide)
def R02_d_yeast := inherit yeastCell (.lit R02)
theorem R02_parents : (Ontology.parents ((Curie.encode "CL:0000521").getD ⟨0, 0⟩)).length = 1 := by decide
/-- Round 2 kept only the fungal half: the subject is CL:0000521, so no protist is reached. -/
theorem R02_fungal_only : R02.claim.subjectCurie = "CL:0000521" := by decide
def R02_rows : List Row := [
  row "G05-R02" "a" yeast (silent "no taxon-to-CL:0000521 link"), row "G05-R02" "a" chlamy (silent "protist half dropped"),
  row "G05-R02" "a" euglena (silent "protist half dropped"),
  row "G05-R02" "d-euk" yeast (concl R02_d_yeast)]

/-! ## G05-R03. cell-structure-and-function-m45434-86 "Some organisms, such as plants, fungi, bacteria,
and some protists, have cell walls". A union with a hedged member. Round 2 keeps only
`Viridiplantae has_part cell wall`. -/

abbrev R03 := R2.CellStructureAndFunction.cell_structure_and_function_m45434_86
def R03_rows : List Row := [
  row "G05-R03" "a" arabidopsis (concl (narrowTaxon arabidopsis (lin arabidopsis e_NCBITaxon_33090) (.lit R03))),
  row "G05-R03" "a" chlamy (concl (narrowTaxon chlamy (lin chlamy e_NCBITaxon_33090) (.lit R03))),
  row "G05-R03" "a" yeast (notIn yeast e_NCBITaxon_33090), row "G05-R03" "a" ecoli (notIn ecoli e_NCBITaxon_33090),
  row "G05-R03" "a" pfal (notIn pfal e_NCBITaxon_33090)]

/-! ## G05-R04. cell-structure-and-function-m45428-12 "Animal cells, plant cells, fungal cells, and
protist cells are classified as eukaryotic". Round 2 keeps `animal cell is_a eukaryotic cell` with
CL:0000548, which CL has obsoleted (replaced_by CL:0000000). The sentence follows from the clade alone:
CL:0000255 is defined as `cell ⊓ in_taxon Eukaryota`, so no grade is needed (option d-euk). -/

abbrev R04 := R2.CellStructureAndFunction.cell_structure_and_function_m45428_12
theorem R04_obsolete : Ontology.retired.lookup ⟨2, 548⟩ = some [⟨2, 0⟩] := by decide
def eukBridge : Statement :=
  { id := "CL:0000255-def", text := "Any cell that in taxon some Eukaryota.",
    claim := .rel isA (e_CL_0000000.inCtx { taxon := some e_NCBITaxon_2759 }) e_CL_0000255,
    evidence := [{ pmid := 0, year := 2026, kind := .ontologyAxiom, note := "CL equivalentClass, OLS4 2026-10-31" }] }
def eukCell (x : Entity .taxon) (h : memberOf x.curie e_NCBITaxon_2759.curie = true := by decide) :
    Derivation (.rel isA (e_CL_0000000.inCtx { taxon := some x }) e_CL_0000255) :=
  Derivation.relChain (refineTaxon e_CL_0000000 (lin x e_NCBITaxon_2759 h)) (.lit eukBridge) (by decide) (by decide)
def R04_rows : List Row := [
  row "G05-R04" "a" pfal (silent "protist dropped; animal cell term obsolete"),
  row "G05-R04" "a" yeast (silent "fungal cell dropped"), row "G05-R04" "a" human (silent "CL:0000548 obsolete, no edges"),
  row "G05-R04" "d-euk" pfal (concl (eukCell pfal)), row "G05-R04" "d-euk" yeast (concl (eukCell yeast)),
  row "G05-R04" "d-euk" human (concl (eukCell human))]

/-! ## G05-R05. reproduction-at-the-cellular-level-m45455-4 "Organisms as diverse as protists, plants,
and animals employ similar steps". "Similar" across a union: no claim shape. -/
def R05_rows : List Row := [row0 "G05-R05" "a" "-" (inexpr "similarity across groups")]

/-! # Algae (polyphyletic: green, red, brown algae, diatoms; ECOCORE adds cyanobacteria)

## G05-A01. cell-structure-and-function-m45432-230 "Chloroplasts ... can be found in eukaryotic cells
such as plants and algae". Round 2 `chloroplast located_in eukaryotic cell`. Right: "such as" only
illustrates, and dropping the grade is correct. -/

abbrev A01 := R2.CellStructureAndFunction.cell_structure_and_function_m45432_230
def A01_rows : List Row := [row0 "G05-A01" "a" "chloroplast" (concl (Derivation.lit A01))]

/-! ## G05-A02. photosynthesis-m45448-115 (from "Eukaryotic autotrophs, such as plants and algae, have
organelles called chloroplasts in which photosynthesis takes place"). Round 3 `photosynthesis ⊓
in_taxon Eukaryota occurs_in chloroplast`. The grade was replaced by the clade it sits in. For
Plasmodium the conclusion is about an empty class (it does not photosynthesise): vacuous, not false. -/

abbrev A02 := R3.Photosynthesis.photosynthesis_m45448_115
def A02_rows : List Row := [
  row "G05-A02" "a" chlamy (concl (narrowRel chlamy (lin chlamy e_NCBITaxon_2759) (.lit A02))),
  row "G05-A02" "a" arabidopsis (concl (narrowRel arabidopsis (lin arabidopsis e_NCBITaxon_2759) (.lit A02))),
  row "G05-A02" "a" euglena (concl (narrowRel euglena (lin euglena e_NCBITaxon_2759) (.lit A02))),
  row "G05-A02" "a" pfal (concl (narrowRel pfal (lin pfal e_NCBITaxon_2759) (.lit A02)))]

/-! ## G05-A03. photosynthesis-m45448-18 "some algae are autotrophs". Blocked (unsupported_ontology:
ECOCORE:00000076 algae, ECOCORE:00000023 autotroph).
## G05-A04. Who is an alga? ECOCORE:00000076 "includes cyanobacteria"; the book's "eukaryotic
autotrophs, such as plants and algae" (m45448-114) does not. Synechocystis is an alga in one, not
the other. No algae entity exists to test. -/
def A03_rows : List Row := [row0 "G05-A03" "a" "-" (inexpr "blocked: unsupported_ontology (ECOCORE)")]
def A04_rows : List Row := [row "G05-A04" "a" synechocystis (inexpr "no algae entity; vocabularies disagree on membership"),
  row "G05-A04" "a" chlamy (inexpr "no algae entity")]

/-! # Invertebrate (Metazoa minus Vertebrata: a grade)

## G05-I01. the-body-s-systems-m45536-87 "Open circulatory systems are found in invertebrate animals".
Blocked (ungrounded "invertebrate"). True only of some: arthropods (Handke 2013); cephalopods are
closed (Le Pabic 2014); sponges have no blood vascular system (Monahan-Earley 2013).
## G05-I02. the-body-s-systems-m45539-26 "Compared to invertebrates, vertebrate nervous systems are more
complex". A comparison against a grade: no claim shape. -/
def I01_rows : List Row := [row "G05-I01" "a" dmel (inexpr "blocked: ungrounded_entity (invertebrate)"),
  row "G05-I01" "a" octopus (inexpr "blocked: ungrounded_entity (invertebrate)"),
  row "G05-I01" "a" amphimedon (inexpr "blocked: ungrounded_entity (invertebrate)")]
def I02_rows : List Row := [row0 "G05-I02" "a" "-" (inexpr "comparison with a grade")]

/-! # Fish and lizards (paraphyletic)

## G05-F01. the-body-s-systems-m45534-71 "The countercurrent adaptation is found in dolphins, sharks,
bony fish, bees, and hummingbirds". Blocked. A union of five, each "some" (lamnid sharks only, Bernal 2001).
## G05-F02. the-cellular-basis-of-inheritance-m45467-82 "... a few examples among the flatworms,
crustaceans, amphibians, fish, and lizards". Blocked. "Fish" is Vertebrata minus Tetrapoda; NCBITaxon
has no node for it (nor for lizards), and "fish" grounded elsewhere as Actinopterygii loses the shark. -/
theorem shark_not_actinopterygii : memberOf scyliorhinus.curie "NCBITaxon:7898" = false ∧
    memberOf scyliorhinus.curie "NCBITaxon:7742" = true ∧ memberOf scyliorhinus.curie "NCBITaxon:32523" = false := by decide
def F01_rows : List Row := [row "G05-F01" "a" scyliorhinus (inexpr "blocked: ungrounded_entity")]
def F02_rows : List Row := [row "G05-F02" "a" danio (inexpr "blocked: has_quality; fish has no taxon"),
  row "G05-F02" "a" scyliorhinus (inexpr "blocked; as Actinopterygii the shark is excluded"),
  row "G05-F02" "a" anolis (inexpr "blocked; lizards has no taxon")]

/-! # "Plants" in the broad sense (Viridiplantae, which includes green algae)

## G05-L01. how-cells-obtain-energy-m45437-59 "Plants ... converting the energy of sunlight to
chemical energy". Round 3 `Viridiplantae capable_of photosynthesis`. Epifagus, a parasitic plant, has
lost photosynthesis (Wolfe 1992): a loss inside a clade, the program 01 problem, not a grade error. -/

abbrev L01 := R3.HowCellsObtainEnergy.how_cells_obtain_energy_m45437_59
def L01_a_epifagus := narrowTaxon epifagus (lin epifagus e_NCBITaxon_33090) (.lit L01)
theorem L01_a_epifagus_b : L01_a_epifagus.opinion.belief = 4/5 := by decide +kernel
def L01_rows : List Row := [
  row "G05-L01" "a" arabidopsis (concl (narrowTaxon arabidopsis (lin arabidopsis e_NCBITaxon_33090) (.lit L01))),
  row "G05-L01" "a" chlamy (concl (narrowTaxon chlamy (lin chlamy e_NCBITaxon_33090) (.lit L01))),
  row "G05-L01" "a" epifagus (concl L01_a_epifagus)]

/-! ## G05-L02. cell-structure-and-function-m45432-322 "Plant cells have a cell wall, chloroplasts and a
central vacuole". Round 3 `cell ⊓ in_taxon Viridiplantae has_part plant-type cell wall`. GO:0009505
is made of cellulose and pectin; the Chlamydomonas wall is glycoprotein, "devoid of cellulose"
(Poulhazan 2024). "Plant" here means land plant (Embryophyta, option a-embryo). -/

abbrev L02 := R3.CellStructureAndFunction.cell_structure_and_function_m45432_322
def L02e := retax L02 (.rel hasPart (e_CL_0000000.inCtx { taxon := some e_NCBITaxon_3193 }) e_GO_0009505) "a-embryo"
def L02_a_chlamy := narrowRel chlamy (lin chlamy e_NCBITaxon_33090) (.lit L02)
theorem L02_a_chlamy_b : L02_a_chlamy.opinion.belief = 4/5 := by decide +kernel
theorem L02_embryo_chlamy_silent : memberOf chlamy.curie e_NCBITaxon_3193.curie = false := by decide
def L02_rows : List Row := [
  row "G05-L02" "a" arabidopsis (concl (narrowRel arabidopsis (lin arabidopsis e_NCBITaxon_33090) (.lit L02))),
  row "G05-L02" "a" chlamy (concl L02_a_chlamy),
  row "G05-L02" "a-embryo" arabidopsis (concl (narrowRel arabidopsis (lin arabidopsis e_NCBITaxon_3193) (.lit L02e))),
  row "G05-L02" "a-embryo" chlamy (notIn chlamy e_NCBITaxon_3193)]

/-! ## G05-L03. how-cells-obtain-energy-m45437-11 "For the most part, photosynthesizing organisms like
plants produce these sugars". Round 3 `photosynthesis ⊓ in_taxon Viridiplantae has_output carbohydrate`.
"Plants" stands in for a character-defined group (photosynthesisers); cyanobacteria are lost. -/

abbrev L03 := R3.HowCellsObtainEnergy.how_cells_obtain_energy_m45437_11
def L03_rows : List Row := [
  row "G05-L03" "a" arabidopsis (concl (narrowRel arabidopsis (lin arabidopsis e_NCBITaxon_33090) (.lit L03))),
  row "G05-L03" "a" synechocystis (notIn synechocystis e_NCBITaxon_33090)]

/-! ## G05-L04. cell-structure-and-function-m45432-225 "The major organic molecule in the plant cell wall
is cellulose". Round 3 `plant-type cell wall ⊓ in_taxon Viridiplantae has_part (1->4)-beta-D-glucan`.
For Chlamydomonas (no plant-type wall) the narrowed claim is about an empty class: vacuous. -/

abbrev L04 := R3.CellStructureAndFunction.cell_structure_and_function_m45432_225
def L04_rows : List Row := [
  row "G05-L04" "a" arabidopsis (concl (narrowRel arabidopsis (lin arabidopsis e_NCBITaxon_33090) (.lit L04))),
  row "G05-L04" "a" chlamy (concl (narrowRel chlamy (lin chlamy e_NCBITaxon_33090) (.lit L04)))]

/-! # Cell kinds: "animal cell", "plant cell"

## G05-C01. cell-structure-and-function-m45432-318 "Animal cells have a centrosome and lysosomes".
Round 3 `cell ⊓ in_taxon Metazoa has_part centrosome`. Planarians lack centrosomes (Azimzadeh 2012):
a loss inside a clade (control). -/

abbrev C01 := R3.CellStructureAndFunction.cell_structure_and_function_m45432_318
def C01_a_schmidtea := narrowRel schmidtea (lin schmidtea e_NCBITaxon_33208) (.lit C01)
theorem C01_a_schmidtea_b : C01_a_schmidtea.opinion.belief = 4/5 := by decide +kernel
def C01_rows : List Row := [
  row "G05-C01" "a" human (concl (narrowRel human (lin human e_NCBITaxon_33208) (.lit C01))),
  row "G05-C01" "a" schmidtea (concl C01_a_schmidtea)]

/-! ## G05-C02. reproduction-at-the-cellular-level-m45461-91 "Animal cells lack cell walls". Round 2
`¬(CL:0000548 has_part cell wall)`, with the obsolete animal cell term, so silent for human cells.
CL's `replaced_by` is CL:0000000 "cell": applied, it says no cell has a wall, which clashes with
m45429-57 "All prokaryotes have a cell wall". -/

abbrev C02 := R2.ReproductionAtTheCellularLevel.reproduction_at_the_cellular_level_m45461_91
def C02repl := retax C02 (.notRel hasPart e_CL_0000000 e_GO_0005618) "replaced_by"
def C02_repl_prok := Derivation.notRelSub (.lit (isaOnt e_CL_0000520 e_CL_0000000)) (.lit C02repl)
def C02_clash : Opinion := Derivation.clash (.lit P07) C02_repl_prok
theorem C02_clash_contested : C02_clash.verdict = .contested := by decide +kernel
def C02_rows : List Row := [
  row "G05-C02" "a" human (silent "CL:0000548 obsolete, no edges"),
  row0 "G05-C02" "replaced_by" "prokaryotic cell" (concl C02_repl_prok),
  row0 "G05-C02" "replaced_by" "clash with m45429-57" s!"clash {repr C02_clash.verdict}"]

/-! ## G05-C03. cell-structure-and-function-m45432-75 "Plant cells lack centrioles". Round 3
`¬(cell ⊓ in_taxon Viridiplantae has_part centriole)`. Chlamydomonas has centrioles (basal bodies,
Dutcher 2003): broad "plants" again. Land plants (option a', Embryophyta) fix the Chlamydomonas row
but not the claim: the fern Marsilea makes centrioles in its sperm, "the basal bodies of which have
the typical cylindrical structure of centrioles" (Mizukami 1966). Added in review: the first run
said Embryophyta fixes C03 without running it. -/

abbrev C03 := R3.CellStructureAndFunction.cell_structure_and_function_m45432_75
def C03e := retax C03 (.notRel hasPart (e_CL_0000000.inCtx { taxon := some e_NCBITaxon_3193 }) e_GO_0005814) "a-embryo"
def C03_a_chlamy := narrowNot chlamy (lin chlamy e_NCBITaxon_33090) (.lit C03)
def C03_e_marsilea := narrowNot marsilea (lin marsilea e_NCBITaxon_3193) (.lit C03e)
theorem C03_a_chlamy_b : C03_a_chlamy.opinion.belief = 4/5 := by decide +kernel
theorem C03_e_marsilea_b : C03_e_marsilea.opinion.belief = 4/5 := by decide +kernel
theorem C03_embryo_chlamy_silent : memberOf chlamy.curie e_NCBITaxon_3193.curie = false := by decide
def C03_rows : List Row := [
  row "G05-C03" "a" arabidopsis (concl (narrowNot arabidopsis (lin arabidopsis e_NCBITaxon_33090) (.lit C03))),
  row "G05-C03" "a" chlamy (concl C03_a_chlamy),
  row "G05-C03" "a" marsilea (concl (narrowNot marsilea (lin marsilea e_NCBITaxon_33090) (.lit C03))),
  row "G05-C03" "a-embryo" arabidopsis (concl (narrowNot arabidopsis (lin arabidopsis e_NCBITaxon_3193) (.lit C03e))),
  row "G05-C03" "a-embryo" chlamy (notIn chlamy e_NCBITaxon_3193),
  row "G05-C03" "a-embryo" marsilea (concl C03_e_marsilea)]

/-! # Microbe and other character-defined groups

## G05-M01. cell-structure-and-function-m45432-253 "Microbes that produce vitamin K live inside the
human gut". Round 3 `some (Bacteria ⊓ located_in intestine produces vitamin K)`. Microbe as Bacteria
is right here (bacterial vitamin K2, Conly 1994). -/
abbrev M01 := R3.CellStructureAndFunction.cell_structure_and_function_m45432_253
def M01_rows : List Row := [row0 "G05-M01" "a" "statement" (concl (Derivation.lit M01)),
  row "G05-M01" "a" msmithii (silent "some does not narrow")]

/-! ## G05-M02. how-cells-obtain-energy-m45440-39 "These microorganisms [methanogens] are found in soil
and in the digestive tracts of ruminants". Round 2 `Methanobacteriota located_in digestive tract`.
Methanogen is a character; the phylum also holds the halophiles (Woese 1990: "the methanogens and their
phenotypically diverse relatives") and misses methanogens elsewhere (Evans 2015). Halobacterium is in
the imported closure, so the pure core derives it. -/
abbrev M02 := R2.HowCellsObtainEnergy.how_cells_obtain_energy_m45440_39
def M02_a_halo := narrowTaxon halo (lin halo e_NCBITaxon_28890) (.lit M02)
theorem M02_a_halo_b : M02_a_halo.opinion.belief = 4/5 := by decide +kernel
theorem M02_halo_in_closure : Taxa.isA halo.curie e_NCBITaxon_28890.curie = true := by decide
def M02_rows : List Row := [
  row "G05-M02" "a" msmithii (concl (narrowTaxon msmithii (lin msmithii e_NCBITaxon_28890) (.lit M02))),
  row "G05-M02" "a" halo (concl M02_a_halo),
  row "G05-M02" "a" hvol (concl (narrowTaxon hvol (lin hvol e_NCBITaxon_28890) (.lit M02)))]

/-! ## G05-M03. how-cells-obtain-energy-m45440-47 "Oxygen is a poison to these microorganisms [obligate
anaerobes]". Round 3 grounds the group as Clostridium (the book's own example, m45440-45). Right for the
genus; other obligate anaerobes are not reached (not tested: no checked member). -/
abbrev M03 := R3.HowCellsObtainEnergy.how_cells_obtain_energy_m45440_47
def M03_rows : List Row := [row0 "G05-M03" "a" "Clostridium" (concl (Derivation.lit M03))]

/-! # Synthetic cases on the core (marked synthetic)

## G05-S03 (synthetic). Overlapping grades double-count. One sentence split into two grades that
overlap (option g on "plants ... and some protists have cell walls", with a local protist entity):
Chlamydomonas is in both, so it gets two derivations from one sentence, and `both` fuses them as if
independent. `sharedAxioms` does not warn: the two statements have different ids. -/

def protistBLN : Entity .taxon := ⟨"BLN:protist", "protist (grade)"⟩
def S03plant : Statement := { R03 with id := "S03/plants" }
def S03protist : Statement :=
  { R03 with id := "S03/protists", claim := .rel hasPart protistBLN e_GO_0005618 }
def S03member : Statement :=
  { id := "S03/chlamy-in-protist", text := "Chlamydomonas is a protist (synthetic membership)",
    claim := .rel isA chlamy protistBLN, evidence := [{ pmid := 0, year := 2026, kind := .curatedDb }] }
def S03_both := Derivation.both (narrowTaxon chlamy (lin chlamy e_NCBITaxon_33090) (.lit S03plant))
  (narrowTaxon chlamy (.lit S03member) (.lit S03protist))
theorem S03_overcount : S03_both.opinion.belief = 8/9 := by decide +kernel
theorem S03_no_warning : S03_both.sharedAxioms = [] := by decide +kernel
def S03_rows : List Row := [row "G05-S03" "g" chlamy (concl S03_both)]

/-! ## G05-S05 (synthetic, core half). Generalise from prokaryote instances. Instances: "transcription
occurs in the cytoplasm" in E. coli, Halobacterium, Sulfolobus (each a textbook-strength statement).
To cellular organisms the sample is admissible and covers 2 of 3 children, so the claim reaches
humans. To the union class it is refused: `admissible` asks `Taxa.isA`, which does not know it. -/

def inst (t : Entity .taxon) : Statement :=
  { id := s!"S05/{t.curie}", text := s!"transcription occurs in the cytoplasm in {t.label}",
    claim := .rel occursIn (e_GO_0006351.inCtx { taxon := some t }) e_GO_0005737,
    evidence := [{ pmid := 0, year := 2013, kind := .textbook, taxon := some t }] }
def S05pred : Predicate .process := .rel occursIn e_GO_0005737
def S05taxa : List (Entity .taxon) := [ecoli, halo, sulfo]
def S05_cellular := Derivation.generalize S05pred {} e_NCBITaxon_131567 .bracketing S05taxa
  (fun i => .lit (inst S05taxa[i])) (by decide +kernel)
def S05_human := narrowRel human (lin human e_NCBITaxon_131567) S05_cellular
theorem S05_cellular_cov : Coverage.Measure.bracketing.eval e_NCBITaxon_131567 S05taxa = 2/3 := by decide +kernel
theorem S05_cellular_b : S05_cellular.opinion.belief = 8/13 ∧ S05_human.opinion.belief = 8/13 := by decide +kernel
theorem S05_union_refused : Coverage.admissible prokaryota S05taxa = false := by decide +kernel
theorem S05_archaea_cov : Coverage.Measure.bracketing.eval e_NCBITaxon_2157 [halo, sulfo] = 1/2 := by decide +kernel
def S05_rows : List Row := [
  row0 "G05-S05" "a" "generalise to cellular organisms" (concl S05_cellular),
  row "G05-S05" "a" human (concl S05_human),
  row0 "G05-S05" "b0" "generalise to Prokaryota" (silent "admissible = false: union unknown to Taxa.isA")]

/-! ## G05-S08 (synthetic). What the core's taxon checks do with a union class (b0). Narrowing works,
but every function that reads the imported tree is blind to it. -/

def S08stmt : Statement :=
  { P01u with evidence := [{ pmid := 0, year := 2013, kind := .textbook, taxon := some ecoli }] }
theorem S08_blind :
    Taxa.known prokaryota = false ∧ Curie.encode prokaryota.curie = none ∧
    Coverage.admissible prokaryota [ecoli] = false ∧ Taxa.siblings ecoli halo = true := by decide +kernel
-- the taxon lint reads curies with string splitting, which the kernel does not reduce: `#guard`
#guard S08stmt.taxonConsistent = false
#guard (inst ecoli).taxonConsistent = true
def S08_rows : List Row := [
  row0 "G05-S08" "b0" "Taxa.known Prokaryota" "false", row0 "G05-S08" "b0" "taxonConsistent (E. coli evidence)" "false",
  row0 "G05-S08" "b0" "generalize admissible" "false", row0 "G05-S08" "b0" "transport E. coli to Halobacterium" "allowed"]

/-! # Option f: local grade entities with explicit membership statements (data only)

A grade is a local entity; each listed clade gets one is_a statement into it (synthetic lists, the
clades checked on OLS4). Narrowing then runs on the core's is_a laws, as for b0. The list is open:
a clade left off is silent, and nothing says the list is complete.

## G05-R02 (f). "Fungal and protist cells also have cell walls", protist half. Right for Chlamydomonas
(Goodenough 1985), wrong for Euglena ("It has no cell wall", Cholewa 2025). -/

def protistF : Entity .taxon := ⟨"BLN:grade/protist", "protist (local grade)"⟩
def invertF  : Entity .taxon := ⟨"BLN:grade/invertebrate", "invertebrate (local grade)"⟩
def chlorophyta : Entity .taxon := ⟨"NCBITaxon:3041", "Chlorophyta"⟩
def euglenozoa  : Entity .taxon := ⟨"NCBITaxon:33682", "Euglenozoa"⟩
def apicomplexa : Entity .taxon := ⟨"NCBITaxon:5794", "Apicomplexa"⟩
def arthropoda  : Entity .taxon := ⟨"NCBITaxon:6656", "Arthropoda"⟩
def mollusca    : Entity .taxon := ⟨"NCBITaxon:6447", "Mollusca"⟩
def porifera    : Entity .taxon := ⟨"NCBITaxon:6040", "Porifera"⟩

/-- The membership lists. -/
def gradeLists : List (String × List String) :=
  [(protistF.curie, [chlorophyta.curie, euglenozoa.curie, apicomplexa.curie]),
   (invertF.curie, [arthropoda.curie, mollusca.curie, porifera.curie])]
def gradeMember (part G : Entity .taxon)
    (_h : ((gradeLists.lookup G.curie).getD []).contains part.curie = true := by decide) : Statement :=
  { id := s!"grade:{part.curie}<{G.curie}", text := s!"{part.label} is_a {G.label}", claim := .rel isA part G,
    evidence := [{ pmid := 0, year := 2026, kind := .curatedDb, note := "local grade membership list (synthetic)" }] }
def linF (x part G : Entity .taxon) (h : memberOf x.curie part.curie = true := by decide)
    (hg : ((gradeLists.lookup G.curie).getD []).contains part.curie = true := by decide) : Derivation (.rel isA x G) :=
  .relChain (lin x part h) (.lit (gradeMember part G hg)) (by decide) (by decide)
/-- Silent because no listed clade holds `x`, checked. -/
def notListed (x G : Entity .taxon) : String :=
  if ((gradeLists.lookup G.curie).getD []).any (memberOf x.curie ·) then "CHECK FAILED"
  else s!"silent: in no listed clade of {G.label}"

def R02f := retax R02 (.rel hasPart protistF e_GO_0005618) "f"
def R02_f_euglena := narrowTaxon euglena (linF euglena euglenozoa protistF) (.lit R02f)
theorem R02_f_euglena_b : R02_f_euglena.opinion.belief = 4/5 := by decide +kernel
def R02f_rows : List Row := [
  row "G05-R02" "f" chlamy (concl (narrowTaxon chlamy (linF chlamy chlorophyta protistF) (.lit R02f))),
  row "G05-R02" "f" euglena (concl R02_f_euglena), row "G05-R02" "f" human (notListed human protistF)]

/-! ## G05-I01 (f). "Open circulatory systems are found in invertebrate animals", read as universal.
Right for Drosophila (Handke 2013), wrong for the octopus (Le Pabic 2014) and the sponge
(Monahan-Earley 2013). The flatworm is an invertebrate but Platyhelminthes is not listed (case S09). -/

def I01f : Statement :=
  { id := "the-body-s-systems-m45536-87/f", text := "Open circulatory systems are found in invertebrate animals",
    claim := .rel hasPart invertF e_UBERON_0009054, evidence := [{ pmid := 0, year := 2013, kind := .textbook }] }
def I01_f_octopus := narrowTaxon octopus (linF octopus mollusca invertF) (.lit I01f)
theorem I01_f_octopus_b : I01_f_octopus.opinion.belief = 4/5 := by decide +kernel
def I01f_rows : List Row := [
  row "G05-I01" "f" dmel (concl (narrowTaxon dmel (linF dmel arthropoda invertF) (.lit I01f))),
  row "G05-I01" "f" octopus (concl I01_f_octopus),
  row "G05-I01" "f" amphimedon (concl (narrowTaxon amphimedon (linF amphimedon porifera invertF) (.lit I01f))),
  row "G05-I01" "f" scyliorhinus (notListed scyliorhinus invertF)]

/-! ## G05-S09 (synthetic). The open list: is Schmidtea an invertebrate? Under f, silent. -/
theorem S09_unlisted : ((gradeLists.lookup invertF.curie).getD []).any (memberOf schmidtea.curie ·) = false ∧
    memberOf schmidtea.curie Taxa.metazoa.curie = true ∧ memberOf schmidtea.curie Taxa.vertebrata.curie = false := by decide
def S09_rows : List Row := [row "G05-S09" "f" schmidtea (notListed schmidtea invertF)]

/-! ## G05-I03. the-body-s-systems-m45536-88, the same sentence's second half: "In open circulatory
systems the circulatory fluid bathes the internal organs directly". Round 3 drops "invertebrate" and
states it of open circulatory systems, which is right: UBERON:0009054 is defined that way. A grade
dropped because the claim is about a structure, not the group (like A01). -/

abbrev I03 := R3.TheBodySSystemsA.the_body_s_systems_m45536_88
def I03_rows : List Row := [row0 "G05-I03" "a" "statement" (concl (Derivation.lit I03))]

/-! # Which core rules narrow which claims (a pin on the rules themselves)

Many silent rows say "no rule narrows a count" or "`some` does not narrow". A theorem about one
statement's shape cannot pin that: a new core rule would not flip it. So read the constructors of
`Derivation` itself. A rule *narrows* claims of head `h` if it concludes an `h` claim from an `h`
premise plus an `is_a` premise (or a generic relation, as `relChain` has). If someone adds a rule
like the prototype's `countSub` to the core, the check below fails and the P10, P11, P17, R01, M01
rows must be re-run. Added in review. -/

open Lean Meta in
/-- For each constructor of `ind`: its name, the head of its conclusion's claim, and per premise the
head of its claim, with whether a `Claim.rel` premise is `is_a` or a generic relation. -/
def ruleShapes (ind : Name) : MetaM (List (Name × Option Name × List (Option Name × Bool))) := do
  let env ← getEnv
  let some (.inductInfo ii) := env.find? ind | throwError "no inductive {ind}"
  ii.ctors.mapM fun c => do
    let some ci := env.find? c | throwError "no constructor {c}"
    forallTelescope ci.type fun xs concl => do
      let prem ← xs.toList.filterMapM fun x => do
        let t ← inferType x
        forallTelescope t fun _ b => do
          if b.isAppOf ind then
            let cl := b.appArg!
            let isaOrVar := cl.isAppOf ``Claim.rel && cl.getAppNumArgs > 2 &&
              (let r := cl.getArg! 2; r.isFVar || r.isConstOf ``Rel.isA)
            return some (cl.getAppFn.constName?, isaOrVar)
          else return none
      return (c.componentsRev.head!, concl.appArg!.getAppFn.constName?, prem)

open Lean Meta in
/-- Rules that narrow claims of head `h` along is_a, and rules that take any `h` premise. -/
def narrowersAndTakers (ind h : Name) : MetaM (List Name × List Name) := do
  let s ← ruleShapes ind
  return (s.filterMap fun (c, ch, ps) =>
            if ch == some h && ps.any (·.1 == some h) && ps.any (·.2) then some c else none,
          s.filterMap fun (c, _, ps) => if ps.any (·.1 == some h) then some c else none)

open Lean Meta in
#eval show MetaM Unit from do
  let pinned : List (Name × List Name × List Name) := [
    (``Claim.rel, [`relChain, `refineMono], [`relChain, `fusionAdds, `notRelSub, `notRelObj, `refineMono, `isaInheritEffect]),
    (``Claim.notRel, [`notRelSub, `notRelObj], [`notRelSub, `notRelObj]),
    (``Claim.effect, [`isaInheritEffect], [`viaActivity, `viaAmount, `isaInheritEffect, `transport]),
    (``Claim.count, [], [`sequencesOver, `pigeonhole, `perSet, `fusionAdds]),
    (``Claim.measure, [], [`compareIntervals]),
    (``Claim.quant, [], [])]
  for (h, n, t) in pinned do
    let (n', t') ← narrowersAndTakers ``Derivation h
    unless n' == n && t' == t do
      throwError "core rules for {h} changed: narrowers {n'}, takers {t'}; pinned {n}, {t}"
  IO.println "core narrowing: rel, notRel, effect only; no rule narrows count or measure; no rule takes a quant premise"

/-! # All rows -/

def rows : List Row :=
  P01_rows ++ P02_rows ++ P03_rows ++ P04_rows ++ P05_rows ++ P06_rows ++ P07_rows ++ P08_rows ++ P19_rows ++ P09_rows ++
  P10_rows ++ P11_rows ++ P12_rows ++ P13_rows ++ P14_rows ++ P15_rows ++ P16_rows ++ P17_rows ++ P18_rows ++
  R01_rows ++ R02_rows ++ R03_rows ++ R04_rows ++ R05_rows ++ A01_rows ++ A02_rows ++ A03_rows ++ A04_rows ++
  I01_rows ++ I02_rows ++ F01_rows ++ F02_rows ++ L01_rows ++ L02_rows ++ L03_rows ++ L04_rows ++
  C01_rows ++ C02_rows ++ C03_rows ++ M01_rows ++ M02_rows ++ M03_rows ++ S03_rows ++ S05_rows ++ S08_rows ++
  R02f_rows ++ I01f_rows ++ S09_rows ++ I03_rows

/-- `some` and `most` claims are never narrowed: no rule takes a `quant` premise. -/
theorem hedged_do_not_narrow :
    (match R01r3.claim with | .quant .some _ => true | _ => false) = true ∧
    (match M01.claim with | .quant .some _ => true | _ => false) = true := by decide

/-- Every checked silent row passed its check. -/
theorem rows_checked : (rows.filter (·.obs == "CHECK FAILED")).length = 0 := by decide +kernel
#guard rows.length = 181

#eval do
  for r in rows do
    IO.println s!"ROW\tStress.GradeTerms\t{r.case}\t{r.option}\t{r.member}\t{r.obs}"

end BioLean.Stress.GradeTerms
