import BioLean.Derivation
import BioLean.Lib.TextbookClaimsR2.CellStructureAndFunction
import BioLean.Lib.TextbookClaimsR2.HowCellsObtainEnergy
import BioLean.Lib.TextbookClaimsR3.CellStructureAndFunction
import BioLean.Lib.TextbookClaimsR3.HowCellsObtainEnergy
import BioLean.Lib.TextbookClaimsR3.MolecularBiology

/-!
# Prototype: grade terms as taxon expressions (program 05). NOT core.

What a core change for grade terms would look like, kept outside the core and self-contained.
Nothing in `BioLean/` imports this file. See `docs/programs/05-grade-terms.md` for the options.

* **New type** `TaxonExpr`: a clade, a union of clades (option b), or a clade minus clades
  (option c). A `Grade` names one and gives it an entity, so `Ctx` is unchanged: the context holds
  the grade's entity (GO's `NCBITaxon_Union:0000004` for prokaryote, `BLN:grade/...` otherwise).
* **New rule `mem`**: membership decided from the expression. With it, *narrowing needs no new
  rule*: grade to member is the core's is_a laws (`refineMono`, `relChain`, `notRelSub`) applied
  to a `mem` premise.
* **New rules for widening**: `unionIntro` (every part to the union; sound, because the union is
  exactly its parts) and `generalizeG` (induction to a grade, discounted by a new coverage
  measure `UMeasure`: three readings for a union, pruned bracketing for a complement).
* **Option e**: `refineIntro`, a member with the character is in the character class.
* **Not about grades**: `countSub`, a subclass inherits a `count`. The core has no rule that
  narrows a quantity claim, which hides several grade errors (cases P10, P11).

`GDeriv` wraps the core `Derivation` and restates three core is_a laws (`relChain`, `refineMono`,
`notRelSub`) over `GDeriv` premises; they are not new rules. Membership is decided against the imported NCBITaxon closure plus a local NCBI
lineage table for members outside it (`data/stress/05/lineage.tsv`). Every case prints a `ROW` line
for `scripts/stress/grade_cases.py`.
-/

namespace BioLean.Proto.TaxonUnion
open BioLean Rel Derivation BioLean.Textbook BioLean.Textbook.R2 BioLean.Textbook.R3

/-! ## Members and lineage (as in `BioLean/Stress/GradeTerms.lean`; a new file cannot import another) -/

def ecoli        : Entity .taxon := ⟨"NCBITaxon:562", "Escherichia coli"⟩
def vcholerae    : Entity .taxon := ⟨"NCBITaxon:666", "Vibrio cholerae"⟩
def gloeobacter  : Entity .taxon := ⟨"NCBITaxon:33072", "Gloeobacter violaceus"⟩
def synechocystis : Entity .taxon := ⟨"NCBITaxon:1148", "Synechocystis sp. PCC 6803"⟩
def hvol         : Entity .taxon := ⟨"NCBITaxon:2246", "Haloferax volcanii"⟩
def halo         : Entity .taxon := ⟨"NCBITaxon:2242", "Halobacterium salinarum"⟩
def sulfo        : Entity .taxon := ⟨"NCBITaxon:2285", "Sulfolobus acidocaldarius"⟩
def thermoplasma : Entity .taxon := ⟨"NCBITaxon:2303", "Thermoplasma acidophilum"⟩
def pfal         : Entity .taxon := ⟨"NCBITaxon:5833", "Plasmodium falciparum"⟩
def chlamy       : Entity .taxon := ⟨"NCBITaxon:3055", "Chlamydomonas reinhardtii"⟩
def euglena      : Entity .taxon := ⟨"NCBITaxon:3038", "Euglena"⟩
def paramecium   : Entity .taxon := ⟨"NCBITaxon:5884", "Paramecium"⟩
def ectocarpus   : Entity .taxon := ⟨"NCBITaxon:2880", "Ectocarpus siliculosus"⟩
/-- Outside the imported closure, like 18 other test members (`BioLean/Stress/GradeTerms.lean`). -/
theorem ectocarpus_unknown : Taxa.known ectocarpus = false := by decide
def yeast        : Entity .taxon := ⟨"NCBITaxon:4932", "Saccharomyces cerevisiae"⟩
def arabidopsis  : Entity .taxon := ⟨"NCBITaxon:3702", "Arabidopsis thaliana"⟩
def human        : Entity .taxon := ⟨"NCBITaxon:9606", "Homo sapiens"⟩
def amphimedon   : Entity .taxon := ⟨"NCBITaxon:400682", "Amphimedon queenslandica"⟩
def schmidtea    : Entity .taxon := ⟨"NCBITaxon:79327", "Schmidtea mediterranea"⟩
def octopus      : Entity .taxon := ⟨"NCBITaxon:6645", "Octopus vulgaris"⟩
def dmel         : Entity .taxon := ⟨"NCBITaxon:7227", "Drosophila melanogaster"⟩
def scyliorhinus : Entity .taxon := ⟨"NCBITaxon:7830", "Scyliorhinus canicula"⟩
def danio        : Entity .taxon := ⟨"NCBITaxon:7955", "Danio rerio"⟩
def anolis       : Entity .taxon := ⟨"NCBITaxon:28377", "Anolis carolinensis"⟩

-- grade building blocks (curies and labels checked on OLS4, `data/stress/05/curies_checked.tsv`)
def embryophyta  : Entity .taxon := ⟨"NCBITaxon:3193", "Embryophyta"⟩
def tetrapoda    : Entity .taxon := ⟨"NCBITaxon:32523", "Tetrapoda"⟩
def squamata     : Entity .taxon := ⟨"NCBITaxon:8509", "Squamata"⟩
def serpentes    : Entity .taxon := ⟨"NCBITaxon:8570", "Serpentes"⟩
def actinopterygii : Entity .taxon := ⟨"NCBITaxon:7898", "Actinopterygii"⟩
def chlorophyta  : Entity .taxon := ⟨"NCBITaxon:3041", "Chlorophyta"⟩
def rhodophyta   : Entity .taxon := ⟨"NCBITaxon:2763", "Rhodophyta"⟩
def phaeophyceae : Entity .taxon := ⟨"NCBITaxon:2870", "Phaeophyceae"⟩
def cyanobacteriota : Entity .taxon := ⟨"NCBITaxon:1117", "Cyanobacteriota"⟩
def openCirc : Entity .anatomy := ⟨"UBERON:0009054", "open circulatory system"⟩

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
  ("NCBITaxon:2049356", ["NCBITaxon:131567", "NCBITaxon:2759", "NCBITaxon:2611341", "NCBITaxon:2662611", "NCBITaxon:66288", "NCBITaxon:302780", "NCBITaxon:302781"])
]

/-- `x` is_a `T`: the imported closure, else the NCBI lineage table. Data, not core. -/
def memberOf (x T : String) : Bool :=
  x == T || Taxa.isA x T || ((ncbiLineage.lookup x).getD []).contains T

def isaTax (x T : Entity .taxon) (_h : memberOf x.curie T.curie = true := by decide) : Statement :=
  { id := s!"lineage:{x.curie}<{T.curie}", text := s!"{x.label} is_a {T.label}", claim := .rel isA x T,
    evidence := [{ pmid := 0, year := 2026, kind := .curatedDb, note := "NCBI Taxonomy, data/stress/05/lineage.tsv" }] }

theorem isA_any (k k' : Kind) : Rel.isA.accepts k k' = true := by cases k <;> cases k' <;> decide
theorem inTaxon_any (k : Kind) : Rel.inTaxon.accepts k .taxon = true := by cases k <;> decide

/-! ## The new type: taxon expressions and grades -/

inductive TaxonExpr
  | clade (t : Entity .taxon)
  | union (parts : List (Entity .taxon))
  | minus (base : Entity .taxon) (excl : List (Entity .taxon))
  deriving DecidableEq

namespace TaxonExpr
/-- Membership under a given is_a. `minus` needs "not is_a", which only a complete tree decides. -/
def memWith (isA : String → String → Bool) : TaxonExpr → String → Bool
  | clade t, x => isA x t.curie
  | union ps, x => ps.any (isA x ·.curie)
  | minus b es, x => isA x b.curie && !es.any (isA x ·.curie)
def mem (g : TaxonExpr) (x : String) : Bool := g.memWith memberOf x

/-- A union only gains members as the is_a data grows: adding lineage facts never removes one. -/
theorem union_mono {isA₁ isA₂ : String → String → Bool} (h : ∀ x y, isA₁ x y = true → isA₂ x y = true)
    (ps : List (Entity .taxon)) (x : String) (hx : (union ps).memWith isA₁ x = true) :
    (union ps).memWith isA₂ x = true := by
  simp only [memWith, List.any_eq_true] at hx ⊢
  obtain ⟨p, hp, hpx⟩ := hx
  exact ⟨p, hp, h _ _ hpx⟩
end TaxonExpr

structure Grade where
  name : String
  curie : String
  expr : TaxonExpr

def Grade.entity (g : Grade) : Entity .taxon := ⟨g.curie, g.name⟩
def Grade.mem (g : Grade) (x : String) : Bool := g.expr.mem x

/-- GO's union class (go-plus, `owl:unionOf (NCBITaxon:2, NCBITaxon:2157)`). -/
def prokaryote : Grade := ⟨"Prokaryota", "NCBITaxon_Union:0000004", .union [e_NCBITaxon_2, e_NCBITaxon_2157]⟩
/-- The same group as a complement: cellular organisms minus Eukaryota (CL's `never_in_taxon`). -/
def prokaryoteC : Grade := ⟨"prokaryote (complement)", "BLN:grade/cellular-minus-eukaryota",
  .minus Taxa.cellularOrganisms [Taxa.eukaryota]⟩
/-- Protist: Eukaryota minus animals, fungi and land plants (green algae stay protists). -/
def protist : Grade := ⟨"protist", "BLN:grade/protist", .minus Taxa.eukaryota [Taxa.metazoa, Taxa.fungi, embryophyta]⟩
/-- The variant of the program brief: minus all green plants (green algae leave). -/
def protistV : Grade := ⟨"protist (minus Viridiplantae)", "BLN:grade/protist-v",
  .minus Taxa.eukaryota [Taxa.metazoa, Taxa.fungi, Taxa.viridiplantae]⟩
def invertebrate : Grade := ⟨"invertebrate", "BLN:grade/invertebrate", .minus Taxa.metazoa [Taxa.vertebrata]⟩
def fish : Grade := ⟨"fish", "BLN:grade/fish", .minus Taxa.vertebrata [tetrapoda]⟩
def lizard : Grade := ⟨"lizard", "BLN:grade/lizard", .minus squamata [serpentes]⟩
/-- Algae as the book uses it (eukaryotic). The list is illustrative, not complete. -/
def algaeEuk : Grade := ⟨"algae (eukaryotic)", "BLN:grade/algae", .union [chlorophyta, rhodophyta, phaeophyceae]⟩
/-- Algae as ECOCORE:00000076 defines it: "includes cyanobacteria". -/
def algaeEcocore : Grade := ⟨"algae (ECOCORE)", "ECOCORE:00000076", .union [chlorophyta, rhodophyta, phaeophyceae, cyanobacteriota]⟩
/-- Algae as NCBI Taxonomy marks it: the 22 taxa carrying "algae" as an in-part name, NCBI's own
marker for a grade (`data/stress/05/ncbi_inpart.tsv`). All eukaryotes: no cyanobacteria. -/
def ncbiAlgaeParts : List (Entity .taxon) := [
  ⟨"NCBITaxon:569578", "PX clade"⟩,
  ⟨"NCBITaxon:304574", "Charophyceae"⟩,
  ⟨"NCBITaxon:304573", "Coleochaetophyceae"⟩,
  ⟨"NCBITaxon:131220", "Klebsormidiophyceae"⟩,
  ⟨"NCBITaxon:131213", "Chlorokybophyceae"⟩,
  ⟨"NCBITaxon:96475", "Mesostigmatophyceae"⟩,
  ⟨"NCBITaxon:82162", "Phaeothamniophyceae"⟩,
  ⟨"NCBITaxon:39119", "Dictyochophyceae"⟩,
  ⟨"NCBITaxon:38410", "Raphidophyceae"⟩,
  ⟨"NCBITaxon:38254", "Glaucocystophyceae"⟩,
  ⟨"NCBITaxon:29197", "Chlorarachniophyceae"⟩,
  ⟨"NCBITaxon:5747", "Eustigmatophyceae"⟩,
  ⟨"NCBITaxon:3041", "Chlorophyta"⟩,
  ⟨"NCBITaxon:3035", "Euglenida"⟩,
  ⟨"NCBITaxon:3027", "Cryptophyceae"⟩,
  ⟨"NCBITaxon:2870", "Phaeophyceae"⟩,
  ⟨"NCBITaxon:2864", "Dinophyceae"⟩,
  ⟨"NCBITaxon:2836", "Bacillariophyta"⟩,
  ⟨"NCBITaxon:2833", "Xanthophyceae"⟩,
  ⟨"NCBITaxon:2830", "Haptophyta"⟩,
  ⟨"NCBITaxon:2825", "Chrysophyceae"⟩,
  ⟨"NCBITaxon:2763", "Rhodophyta"⟩]
def algaeNCBI : Grade := ⟨"algae (NCBI in-part)", "BLN:grade/algae-ncbi", .union ncbiAlgaeParts⟩
/-- The book's m45434-86 list: plants, fungi, bacteria (and "some protists", left out: hedged). -/
def walled : Grade := ⟨"plants, fungi or bacteria", "BLN:grade/plants-fungi-bacteria",
  .union [Taxa.viridiplantae, Taxa.fungi, Taxa.bacteria]⟩

def grades : List Grade := [prokaryote, prokaryoteC, protist, protistV, invertebrate, fish, lizard, algaeEuk,
  algaeEcocore, algaeNCBI, walled]
/-- A grade's entity stands for its expression, so two grades must never share a curie. -/
theorem grade_curies_distinct : (grades.map (·.curie)).Nodup := by decide

/-! ## New coverage measures -/

open Ontology in
/-- Bracketing with excluded clades pruned from every children list: the complement's own tree. -/
def bracketingMinus (excl : List Code) (t : Code) (s : List Code) : Nat → ℚ
  | 0 => 0
  | n + 1 =>
    let cs := (children t).filter (!excl.contains ·)
    match cs.filter (fun c => s.any (isA · c)) with
    | [] => 0
    | [c] => bracketingMinus excl c s n / cs.length
    | cov => cov.length / cs.length

/-- Three readings of coverage for a union: the parts as children of a virtual node (bracketing's
own rule), the least-covered part, the mean over parts. -/
inductive UMeasure
  | virtualNode | minParts | meanParts
  deriving DecidableEq, Repr

def partCov (p : Entity .taxon) (taxa : List (Entity .taxon)) : ℚ :=
  Coverage.Measure.bracketing.eval p (taxa.filter (memberOf ·.curie p.curie))

def codes (ts : List (Entity .taxon)) : List Code := ts.filterMap (Curie.encode ·.curie)

def UMeasure.eval (m : UMeasure) (g : Grade) (taxa : List (Entity .taxon)) : ℚ :=
  match g.expr with
  | .clade t => Coverage.Measure.bracketing.eval t taxa
  | .minus b es => match Curie.encode b.curie with
    | some c => bracketingMinus (codes es) c (codes (taxa.filter (g.mem ·.curie))) Ontology.maxDepth
    | none => 0
  | .union ps =>
    let covs := ps.map (partCov · taxa)
    match m with
    | .virtualNode =>
      match ps.filter (fun p => taxa.any (memberOf ·.curie p.curie)) with
      | [] => 0
      | [p] => partCov p taxa / ps.length
      | cov => cov.length / ps.length
    | .minParts => covs.foldl min (covs.headD 0)
    | .meanParts => if ps.isEmpty then 0 else covs.sum / ps.length

/-- Clamp to `[0, 1]`, so `discount` needs no per-measure proof. -/
def clamp (w : ℚ) : ℚ := max 0 (min 1 w)
theorem clamp_nonneg (w : ℚ) : 0 ≤ clamp w := le_max_left _ _
theorem clamp_le_one (w : ℚ) : clamp w ≤ 1 := max_le zero_le_one (min_le_left _ _)

/-! ## The new derivation layer -/

inductive GDeriv : Claim → Type
  | core {c : Claim} (d : Derivation c) : GDeriv c
  /-- New. Membership decided from the grade's expression: `x is_a g`. Sound for a union; for a
  complement only if the is_a data is complete (closed world, case S01). -/
  | mem (g : Grade) (x : Entity .taxon) (h : g.mem x.curie = true := by decide) :
      GDeriv (.rel isA x g.entity (isA_any .taxon .taxon))
  /-- New. All parts to the union. Sound because the union is exactly its parts. -/
  | unionIntro {k : Kind} {a : Entity k} (p : Predicate k) (g : Grade) (parts : List (Entity .taxon))
      (d : (i : Fin parts.length) → GDeriv (p.claim (a.inCtx { taxon := some parts[i] })))
      (hg : g.expr = .union parts := by decide) : GDeriv (p.claim (a.inCtx { taxon := some g.entity }))
  /-- New. Induction to a grade from sampled members, discounted by `m`. -/
  | generalizeG {k : Kind} {a : Entity k} (p : Predicate k) (g : Grade) (m : UMeasure)
      (taxa : List (Entity .taxon))
      (d : (i : Fin taxa.length) → GDeriv (p.claim (a.inCtx { taxon := some taxa[i] })))
      (h : (!taxa.isEmpty && taxa.all (g.mem ·.curie)) = true := by decide) :
      GDeriv (p.claim (a.inCtx { taxon := some g.entity }))
  /-- New (option e). A member of `g` with `r f` is in the character class `g ⊓ ∃r.f`. -/
  | refineIntro {k : Kind} {r : Rel} {f : Entity k} {h : r.accepts .taxon k = true} (g : Grade)
      (x : Entity .taxon) (d : GDeriv (.rel r x f h)) (hm : g.mem x.curie = true := by decide) :
      GDeriv (.rel isA x (g.entity.refine r f h) (isA_any .taxon .taxon))
  /-- New, not about grades. A subclass inherits a count: `v is_a w`, every `w` has `n` parts, so
  every `v` has `n`. Sound for the universal reading of `count`. -/
  | countSub {k₁ k₂ : Kind} {w v : Entity k₁} {part : Entity k₂} {n : Nat} {h : Rel.isA.accepts k₁ k₁ = true}
      (vw : GDeriv (.rel isA v w h)) (d : GDeriv (.count w part n)) : GDeriv (.count v part n)
  -- the core's is_a laws over `GDeriv` premises (restated, not new)
  | relChain {k₁ k₂ k₃ : Kind} {a : Entity k₁} {b : Entity k₂} {c : Entity k₃} {r₁ r₂ r₃ : Rel}
      {h₁ : r₁.accepts k₁ k₂ = true} {h₂ : r₂.accepts k₂ k₃ = true}
      (ab : GDeriv (.rel r₁ a b h₁)) (bc : GDeriv (.rel r₂ b c h₂))
      (ok : RO.chainOK r₁ r₂ r₃ = true := by decide) (h₃ : r₃.accepts k₁ k₃ = true := by decide) :
      GDeriv (.rel r₃ a c h₃)
  | refineMono {k k' : Kind} {e : Entity k} {r : Rel} {f g : Entity k'} {h : Rel.isA.accepts k' k' = true}
      (fg : GDeriv (.rel Rel.isA f g h)) (hr : r.accepts k k' = true := by decide)
      (h' : Rel.isA.accepts k k = true := by decide) :
      GDeriv (.rel Rel.isA (e.refine r f hr) (e.refine r g hr) h')
  | notRelSub {k₁ k₂ k₃ : Kind} {a : Entity k₁} {b : Entity k₂} {c : Entity k₃} {r : Rel}
      {h₁ : Rel.isA.accepts k₁ k₂ = true} {h₂ : r.accepts k₂ k₃ = true}
      (ab : GDeriv (.rel Rel.isA a b h₁)) (bc : GDeriv (.notRel r b c h₂))
      (h₃ : r.accepts k₁ k₃ = true := by decide) : GDeriv (.notRel r a c h₃)

/-- A decided membership is data from NCBI: the weight of a lineage statement (curated data). -/
def memOp : Opinion := Opinion.ofReliability (4 / 5) (by norm_num) (by norm_num) .supports

def weakestAll : List Opinion → Opinion
  | [] => .vacuous
  | o :: os => os.foldl Opinion.weakest o

def GDeriv.opinion [EvidenceModel] : {c : Claim} → GDeriv c → Opinion
  | _, .core d => d.opinion
  | _, .mem .. => memOp
  | _, .unionIntro _ _ parts d _ => weakestAll ((List.finRange parts.length).map fun i => (d i).opinion)
  | _, .generalizeG _ g m taxa d _ =>
      (((List.finRange taxa.length).map fun i => (d i).opinion).foldl Opinion.fuse .vacuous).discount
        (clamp (m.eval g taxa)) (clamp_nonneg _) (clamp_le_one _)
  | _, .refineIntro _ _ d _ => d.opinion.weakest memOp
  | _, .countSub vw d => vw.opinion.weakest d.opinion
  | _, .relChain ab bc .. => ab.opinion.weakest bc.opinion
  | _, .refineMono fg .. => fg.opinion
  | _, .notRelSub ab bc .. => ab.opinion.weakest bc.opinion

/-! ## Narrowing, from `mem` and the is_a laws only -/

/-- A relation of `a ⊓ in_taxon g` holds of `a ⊓ in_taxon x` for a member `x`. -/
def narrowRel {k₁ k₂ : Kind} {a : Entity k₁} {r : Rel} {b : Entity k₂} {h : r.accepts k₁ k₂ = true}
    (g : Grade) (x : Entity .taxon) (d : GDeriv (.rel r (a.inCtx { taxon := some g.entity }) b h))
    (hm : g.mem x.curie = true := by decide) (ok : RO.chainOK isA r r = true := by decide) :
    GDeriv (.rel r (a.inCtx { taxon := some x }) b h) :=
  .relChain (.refineMono (e := a) (r := inTaxon) (hr := inTaxon_any k₁) (h' := isA_any k₁ k₁) (.mem g x hm)) d ok h

/-- A relation of the grade itself ("invertebrates have X") holds of a member. -/
def narrowSubj {k : Kind} {r : Rel} {b : Entity k} {h : r.accepts .taxon k = true} (g : Grade)
    (x : Entity .taxon) (d : GDeriv (.rel r g.entity b h)) (hm : g.mem x.curie = true := by decide)
    (ok : RO.chainOK isA r r = true := by decide) : GDeriv (.rel r x b h) :=
  .relChain (.mem g x hm) d ok h

/-- A count of `a ⊓ in_taxon g` holds of `a ⊓ in_taxon x` (needs the new `countSub`). -/
def narrowCount {k₁ k₂ : Kind} {a : Entity k₁} {part : Entity k₂} {n : Nat} (g : Grade) (x : Entity .taxon)
    (d : GDeriv (.count (a.inCtx { taxon := some g.entity }) part n)) (hm : g.mem x.curie = true := by decide) :
    GDeriv (.count (a.inCtx { taxon := some x }) part n) :=
  .countSub (.refineMono (e := a) (r := inTaxon) (hr := inTaxon_any k₁) (h' := isA_any k₁ k₁) (.mem g x hm)) d

/-- Lineage as a premise, for the status-quo clade with the new `countSub`. -/
def lin (x T : Entity .taxon) (h : memberOf x.curie T.curie = true := by decide) : GDeriv (.rel isA x T) :=
  .core (.lit (isaTax x T h))

def retax (s : Statement) (c : Claim) (tag : String) : Statement := { s with id := s!"{s.id}/{tag}", claim := c }

/-! ## Rows -/

structure Row where
  case : String
  option : String
  member : String
  obs : String
def row (c o : String) (x : Entity .taxon) (obs : String) : Row := ⟨c, o, x.label, obs⟩
def row0 (c o what obs : String) : Row := ⟨c, o, what, obs⟩
def concl {c : Claim} (d : GDeriv c) : String := s!"concl b={d.opinion.belief}"
/-- Silent because `x` is not in grade `g`, checked: a wrong membership prints `CHECK FAILED`. -/
def notInG (x : Entity .taxon) (g : Grade) : String :=
  if g.mem x.curie then "CHECK FAILED" else s!"silent: not in {g.name}"
def memRow (c o : String) (g : Grade) (x : Entity .taxon) : Row :=
  row c o x (if g.mem x.curie then s!"member of {g.name}" else s!"not a member of {g.name}")

/-! # Prokaryote as a union (option b) and as a complement (option c)

## G05-P01. molbio-m45476-20 "In prokaryotes, transcription occurs in the cytoplasm". Re-annotated
with the union. True of every member (E. coli, Halobacterium, Sulfolobus, H. volcanii); silent for
humans. `unionIntro` also rebuilds the union statement from the two split statements (option g). -/

abbrev P01 := R3.MolecularBiology.molbio_m45476_20
def P01b := retax P01 (.rel occursIn (e_GO_0006351.inCtx { taxon := some prokaryote.entity }) e_GO_0005737) "b"
def P01arch := retax P01 (.rel occursIn (e_GO_0006351.inCtx { taxon := some e_NCBITaxon_2157 }) e_GO_0005737) "g:Archaea"
def P01pred : Predicate .process := .rel occursIn e_GO_0005737
def P01_b (x : Entity .taxon) (h : prokaryote.mem x.curie = true := by decide) :=
  narrowRel prokaryote x (.core (.lit P01b)) h
def P01_intro : GDeriv (.rel occursIn (e_GO_0006351.inCtx { taxon := some prokaryote.entity }) e_GO_0005737) :=
  .unionIntro P01pred prokaryote [e_NCBITaxon_2, e_NCBITaxon_2157] (fun | 0 => .core (.lit P01) | 1 => .core (.lit P01arch))
def P01_intro_hvol := narrowRel prokaryote hvol P01_intro

theorem P01_b_hvol_b : (P01_b hvol).opinion.belief = 4/5 := by decide +kernel
theorem P01_intro_b : P01_intro_hvol.opinion.belief = 4/5 := by decide +kernel
/-- Union and complement agree on every test member: cellular organisms is exactly the three domains. -/
theorem P01_union_eq_complement :
    [ecoli, vcholerae, gloeobacter, synechocystis, hvol, halo, sulfo, thermoplasma, pfal, chlamy, yeast, human].all
      (fun x => prokaryote.mem x.curie == prokaryoteC.mem x.curie) = true := by decide

def P01_rows : List Row := [
  row "G05-P01" "b" ecoli (concl (P01_b ecoli)), row "G05-P01" "b" halo (concl (P01_b halo)),
  row "G05-P01" "b" sulfo (concl (P01_b sulfo)), row "G05-P01" "b" hvol (concl (P01_b hvol)),
  row "G05-P01" "b" human (notInG human prokaryote),
  row "G05-P01" "c" hvol (concl (narrowRel prokaryoteC hvol (.core (.lit (retax P01
    (.rel occursIn (e_GO_0006351.inCtx { taxon := some prokaryoteC.entity }) e_GO_0005737) "c"))))),
  row "G05-P01" "c" human (notInG human prokaryoteC),
  row "G05-P01" "g+b" hvol (concl P01_intro_hvol)]

/-! ## G05-P02. how-cells-obtain-energy-m45439-48 "... in the plasma membrane of prokaryotes".
With the union the claim reaches archaea (one membrane, Albers 2011) and stops at humans. -/

abbrev P02 := R3.HowCellsObtainEnergy.how_cells_obtain_energy_m45439_48
def P02b := retax P02 (.rel occursIn (e_GO_0022904.inCtx { taxon := some prokaryote.entity }) e_GO_0005886) "b"
def P02_b (x : Entity .taxon) (h : prokaryote.mem x.curie = true := by decide) :=
  narrowRel prokaryote x (.core (.lit P02b)) h
theorem P02_b_sulfo_b : (P02_b sulfo).opinion.belief = 4/5 := by decide +kernel
def P02_rows : List Row := [
  row "G05-P02" "b" ecoli (concl (P02_b ecoli)), row "G05-P02" "b" sulfo (concl (P02_b sulfo)),
  row "G05-P02" "b" halo (concl (P02_b halo)), row "G05-P02" "b" human (notInG human prokaryote)]

/-! ## G05-P09. cell-structure-and-function-m45432-224 "The chief component of prokaryotic cell walls is
peptidoglycan". Here "prokaryote" means bacterium: archaeal walls have none (Beveridge 1996). The
union, being right about membership, is wrong about the biology. -/

abbrev P09 := R2.CellStructureAndFunction.cell_structure_and_function_m45432_224
def P09b := retax P09 (.rel hasPart (e_GO_0005618.inCtx { taxon := some prokaryote.entity }) e_CHEBI_8005) "b"
def P09_b (x : Entity .taxon) (h : prokaryote.mem x.curie = true := by decide) :=
  narrowRel prokaryote x (.core (.lit P09b)) h
theorem P09_b_halo_b : (P09_b halo).opinion.belief = 4/5 := by decide +kernel
def P09_rows : List Row := [
  row "G05-P09" "b" ecoli (concl (P09_b ecoli)), row "G05-P09" "b" halo (concl (P09_b halo)),
  row "G05-P09" "b" hvol (concl (P09_b hvol))]

/-! ## G05-P10. molbio-m45475-124 "replication in prokaryotes starts from a single origin". Round 3:
`count (chromosome ⊓ in_taxon Bacteria) origin 1`. With the new `countSub` the claim narrows at last.
On Bacteria it is right for E. coli (Hawkins 2013: "Bacteria and some archaea replicate from single
origins"); on the union it is wrong for Sulfolobus (three, Lundgren 2004) and H. volcanii (four). -/

abbrev P10 := R3.MolecularBiology.molbio_m45475_124
def P10b := retax P10 (.count (e_GO_0005694.inCtx { taxon := some prokaryote.entity }) e_SO_0000296 1) "b"
def P10_a_ecoli : GDeriv (.count (e_GO_0005694.inCtx { taxon := some ecoli }) e_SO_0000296 1) :=
  .countSub (.refineMono (e := e_GO_0005694) (r := inTaxon) (lin ecoli e_NCBITaxon_2)) (.core (.lit P10))
def P10_b (x : Entity .taxon) (h : prokaryote.mem x.curie = true := by decide) :=
  narrowCount prokaryote x (.core (.lit P10b)) h
theorem P10_b_sulfo_b : (P10_b sulfo).opinion.belief = 4/5 := by decide +kernel
def P10_rows : List Row := [
  row "G05-P10" "a+count" ecoli (concl P10_a_ecoli),
  row "G05-P10" "b+count" sulfo (concl (P10_b sulfo)), row "G05-P10" "b+count" hvol (concl (P10_b hvol))]

/-! ## G05-P11. molbio-m45473-130 "Prokaryotes contain a single ... chromosome". Round 3 `count
Bacteria chromosome 1`, the taxon itself as subject. With `countSub`: right for Gloeobacter (a single
circular chromosome, Nakamura 2003), wrong for V. cholerae (two, Heidelberg 2000) even on Bacteria,
and wrong for H. volcanii on the union (a main and three smaller chromosomes, Hartman 2010). -/

abbrev P11 := R3.MolecularBiology.molbio_m45473_130
def P11b := retax P11 (.count prokaryote.entity e_GO_0005694 1) "b"
def P11_a (x : Entity .taxon) (h : memberOf x.curie e_NCBITaxon_2.curie = true := by decide) :
    GDeriv (.count x e_GO_0005694 1) := .countSub (lin x e_NCBITaxon_2 h) (.core (.lit P11))
def P11_b (x : Entity .taxon) (h : prokaryote.mem x.curie = true := by decide) :
    GDeriv (.count x e_GO_0005694 1) := .countSub (.mem prokaryote x h) (.core (.lit P11b))
theorem P11_a_vcholerae_b : (P11_a vcholerae).opinion.belief = 4/5 := by decide +kernel
def P11_rows : List Row := [
  row "G05-P11" "a+count" gloeobacter (concl (P11_a gloeobacter)),
  row "G05-P11" "a+count" vcholerae (concl (P11_a vcholerae)),
  row "G05-P11" "b+count" hvol (concl (P11_b hvol))]

/-! # Protist, invertebrate, fish as complements (option c); character classes (option e)

## G05-R01. cell-structure-and-function-m45432-241 "photosynthetic protists also have chloroplasts".
Option e: the subject is the character class `protist ⊓ capable_of photosynthesis`. A member enters
it only with its own photosynthesis statement (input data, marked synthetic). Plasmodium has none, so
it is rightly silent; under the protist-minus-Viridiplantae variant Chlamydomonas is not a protist. -/

def photosyntheticProtist (g : Grade) : Entity .taxon := g.entity.refine capableOf e_GO_0015979
def R01e (g : Grade) : Statement :=
  { id := s!"cell-structure-and-function-m45432-241/e:{g.curie}", text := "Like plant cells, photosynthetic protists also have chloroplasts.",
    claim := .rel hasPart (photosyntheticProtist g) e_GO_0009507,
    evidence := [{ pmid := 0, year := 2013, kind := .textbook }] }
/-- Synthetic input: `x` photosynthesises (Chlamydomonas, Euglena: Keeling 2010, Cholewa 2025). -/
def photo (x : Entity .taxon) : Statement :=
  { id := s!"photo:{x.curie}", text := s!"{x.label} carries out photosynthesis (input)", claim := .rel capableOf x e_GO_0015979,
    evidence := [{ pmid := 0, year := 2026, kind := .curatedDb }] }
def R01_e (g : Grade) (x : Entity .taxon) (h : g.mem x.curie = true := by decide) :
    GDeriv (.rel hasPart x e_GO_0009507) :=
  .relChain (.refineIntro g x (.core (.lit (photo x))) h) (.core (.lit (R01e g)))
theorem R01_e_euglena_b : (R01_e protist euglena).opinion.belief = 4/5 := by decide +kernel
theorem R01_v_chlamy_out : protistV.mem chlamy.curie = false ∧ protist.mem chlamy.curie = true := by decide
def R01_rows : List Row := [
  row "G05-R01" "e" chlamy (concl (R01_e protist chlamy)), row "G05-R01" "e" euglena (concl (R01_e protist euglena)),
  row "G05-R01" "e" pfal (if protist.mem pfal.curie then "silent: no photosynthesis statement" else "CHECK FAILED"),
  row "G05-R01" "e" human (notInG human protist),
  row "G05-R01" "e-v" chlamy (notInG chlamy protistV)]

/-! ## G05-R02. cell-structure-and-function-m45432-223 "Fungal and protist cells also have cell walls".
Protist half with the complement: right for Chlamydomonas (a glycoprotein wall, Goodenough 1985),
wrong for Euglena ("It has no cell wall", Cholewa 2025). -/

def R02c : Statement :=
  { id := "cell-structure-and-function-m45432-223/c:protist", text := "Fungal and protist cells also have cell walls.",
    claim := .rel hasPart protist.entity e_GO_0005618, evidence := [{ pmid := 0, year := 2013, kind := .textbook }] }
def R02_c (x : Entity .taxon) (h : protist.mem x.curie = true := by decide) := narrowSubj protist x (.core (.lit R02c)) h
theorem R02_c_euglena_b : (R02_c euglena).opinion.belief = 4/5 := by decide +kernel
def R02_rows : List Row := [
  row "G05-R02" "c" chlamy (concl (R02_c chlamy)), row "G05-R02" "c" euglena (concl (R02_c euglena)),
  row "G05-R02" "c" human (notInG human protist), row "G05-R02" "c" yeast (notInG yeast protist)]

/-! ## G05-R03. cell-structure-and-function-m45434-86 "Some organisms, such as plants, fungi, bacteria,
and some protists, have cell walls". The union of the three named clades (the hedged protists left
out). Round 2 kept only Viridiplantae; the union adds yeast and E. coli. -/

def R03b : Statement :=
  { id := "cell-structure-and-function-m45434-86/b", text := "plants, fungi, bacteria ... have cell walls",
    claim := .rel hasPart walled.entity e_GO_0005618, evidence := [{ pmid := 0, year := 2013, kind := .textbook }] }
def R03_b (x : Entity .taxon) (h : walled.mem x.curie = true := by decide) := narrowSubj walled x (.core (.lit R03b)) h
def R03_rows : List Row := [
  row "G05-R03" "b" arabidopsis (concl (R03_b arabidopsis)), row "G05-R03" "b" yeast (concl (R03_b yeast)),
  row "G05-R03" "b" ecoli (concl (R03_b ecoli)), row "G05-R03" "b" chlamy (concl (R03_b chlamy)),
  row "G05-R03" "b" pfal (notInG pfal walled), row "G05-R03" "b" thermoplasma (notInG thermoplasma walled)]

/-! ## G05-I01. the-body-s-systems-m45536-87 "Open circulatory systems are found in invertebrate
animals". Blocked in round 2. With the complement it is expressible, and the universal reading is
wrong for the octopus (closed, Le Pabic 2014) and the sponge (no blood vascular system,
Monahan-Earley 2013). The book means "some" ("found in invertebrate animals in which the circulatory
fluid bathes the internal organs directly"). With the hedge restored (option h, `I01h`) every member is
silent, which is right: from "some invertebrates" nothing follows for one member. The silence is
pinned by the rule check at the end of this file: no `GDeriv` rule takes a `quant` premise. -/

def I01c : Statement :=
  { id := "the-body-s-systems-m45536-87/c", text := "Open circulatory systems are found in invertebrate animals",
    claim := .rel hasPart invertebrate.entity openCirc, evidence := [{ pmid := 0, year := 2013, kind := .textbook }] }
def I01_c (x : Entity .taxon) (h : invertebrate.mem x.curie = true := by decide) :=
  narrowSubj invertebrate x (.core (.lit I01c)) h
/-- Option h: the same statement with the book's hedge restored. -/
def I01h : Statement := { I01c with id := "the-body-s-systems-m45536-87/c+some", claim := .quant .some I01c.claim }
theorem I01h_is_some : (match I01h.claim with | .quant .some _ => true | _ => false) = true := by decide
/-- A member of the grade, facing a `some` statement: silent, as no rule takes a `quant` premise. -/
def hedged (x : Entity .taxon) : String :=
  if invertebrate.mem x.curie && (match I01h.claim with | .quant .some _ => true | _ => false) then
    "silent: some does not narrow" else "CHECK FAILED"
theorem I01_c_octopus_b : (I01_c octopus).opinion.belief = 4/5 := by decide +kernel
def I01_rows : List Row := [
  row "G05-I01" "c" dmel (concl (I01_c dmel)), row "G05-I01" "c" octopus (concl (I01_c octopus)),
  row "G05-I01" "c" amphimedon (concl (I01_c amphimedon)), row "G05-I01" "c" scyliorhinus (notInG scyliorhinus invertebrate),
  row "G05-I01" "c+some" dmel (hedged dmel), row "G05-I01" "c+some" octopus (hedged octopus),
  row "G05-I01" "c+some" amphimedon (hedged amphimedon)]

/-! ## G05-F01, G05-F02. Fish and lizards: who is a member? "Fish" grounded as Actinopterygii (how the
round 2 grounder did it elsewhere) loses the shark; the complement keeps it ("teleost and
elasmobranch fishes", Bernal 2001). The sentences are hedged ("a few examples among"), so only
membership is tested. -/

def actinoG : Grade := ⟨"Actinopterygii", "NCBITaxon:7898", .clade actinopterygii⟩
theorem F_members : actinoG.mem scyliorhinus.curie = false ∧ fish.mem scyliorhinus.curie = true ∧
    fish.mem anolis.curie = false ∧ lizard.mem anolis.curie = true := by decide
def F_rows : List Row := [
  memRow "G05-F02" "a-actino" actinoG scyliorhinus, memRow "G05-F02" "a-actino" actinoG danio,
  memRow "G05-F02" "c" fish scyliorhinus, memRow "G05-F02" "c" fish danio, memRow "G05-F02" "c" fish anolis,
  memRow "G05-F02" "c" fish human, memRow "G05-F02" "c" lizard anolis,
  memRow "G05-F01" "c" fish scyliorhinus]

/-! ## G05-A04. Who is an alga? photosynthesis-m45448-18 separates "certain types of bacteria and
algae"; ECOCORE:00000076 "includes cyanobacteria"; NCBI's in-part list does not. ECOCORE disagrees
with the book on Synechocystis; NCBI's list agrees, and also counts Euglena. -/

theorem A04_members : algaeEcocore.mem synechocystis.curie = true ∧ algaeNCBI.mem synechocystis.curie = false ∧
    algaeEuk.mem synechocystis.curie = false ∧ algaeNCBI.mem euglena.curie = true ∧ algaeNCBI.mem pfal.curie = false := by decide
def A04_rows : List Row := [
  memRow "G05-A04" "b-euk" algaeEuk synechocystis, memRow "G05-A04" "b-ecocore" algaeEcocore synechocystis,
  memRow "G05-A04" "b-euk" algaeEuk chlamy, memRow "G05-A04" "b-euk" algaeEuk ectocarpus,
  memRow "G05-A04" "b-ecocore" algaeEcocore chlamy,
  memRow "G05-A04" "b-ncbi" algaeNCBI synechocystis, memRow "G05-A04" "b-ncbi" algaeNCBI chlamy,
  memRow "G05-A04" "b-ncbi" algaeNCBI ectocarpus, memRow "G05-A04" "b-ncbi" algaeNCBI euglena,
  memRow "G05-A04" "b-ncbi" algaeNCBI pfal]

/-! # Synthetic cases (marked synthetic)

## G05-S01 (synthetic). A complement needs a closed world. With a partial lineage for the sponge
(only "cellular organisms, Eukaryota" known), the complement calls it a protist; with the full
lineage it is not. A union never flips this way (`TaxonExpr.union_mono`). -/

def partialIsA (x T : String) : Bool :=
  x == T || (x == amphimedon.curie && (T == "NCBITaxon:131567" || T == "NCBITaxon:2759"))
theorem S01_complement_flips :
    protist.expr.memWith partialIsA amphimedon.curie = true ∧ protist.mem amphimedon.curie = false := by decide
theorem S01_union_fails_safe :
    (TaxonExpr.union [e_NCBITaxon_2, e_NCBITaxon_2157]).memWith (fun x T => x == T || T == "NCBITaxon:131567") hvol.curie = false := by
  decide
def S01_rows : List Row := [
  row "G05-S01" "c-partial" amphimedon (if protist.expr.memWith partialIsA amphimedon.curie then "member of protist" else "not a member of protist"),
  memRow "G05-S01" "c" protist amphimedon]

/-! ## G05-S04 (synthetic). Coverage over a union. Instances in E. coli, Halobacterium, Sulfolobus (the
known members). The core's cellular-organisms route gives 2/3 (two of three domains). For the union:
`virtualNode` gives 1 (both parts touched), `minParts` gives 0 (one bacterium brackets nothing),
`meanParts` gives 1/4. One sampled bacterium should not cover Bacteria, so only `minParts` and
`meanParts` keep bracketing's own rule. -/

def S04taxa : List (Entity .taxon) := [ecoli, halo, sulfo]
theorem S04_cov :
    UMeasure.virtualNode.eval prokaryote S04taxa = 1 ∧ UMeasure.minParts.eval prokaryote S04taxa = 0 ∧
    UMeasure.meanParts.eval prokaryote S04taxa = 1/4 ∧ partCov e_NCBITaxon_2157 S04taxa = 1/2 := by decide +kernel
def S04_rows : List Row := [
  row0 "G05-S04" "b" "virtualNode coverage" s!"{UMeasure.virtualNode.eval prokaryote S04taxa}",
  row0 "G05-S04" "b" "minParts coverage" s!"{UMeasure.minParts.eval prokaryote S04taxa}",
  row0 "G05-S04" "b" "meanParts coverage" s!"{UMeasure.meanParts.eval prokaryote S04taxa}"]

/-! ## G05-S05 (synthetic, proto half). Generalise "transcription occurs in the cytoplasm" from the
three instances to the union, then try to reach humans: refused (not a member). -/

def inst (t : Entity .taxon) : Statement :=
  { id := s!"S05/{t.curie}", text := s!"transcription occurs in the cytoplasm in {t.label}",
    claim := .rel occursIn (e_GO_0006351.inCtx { taxon := some t }) e_GO_0005737,
    evidence := [{ pmid := 0, year := 2013, kind := .textbook, taxon := some t }] }
def S05_gen (m : UMeasure) := GDeriv.generalizeG P01pred prokaryote m S04taxa (fun i => .core (.lit (inst S04taxa[i])))
theorem S05_gen_b : (S05_gen .virtualNode).opinion.belief = 12/13 ∧ (S05_gen .meanParts).opinion.belief = 3/13 ∧
    (S05_gen .minParts).opinion.belief = 0 := by decide +kernel
def S05_rows : List Row := [
  row0 "G05-S05" "b-virtualNode" "generalise to Prokaryota" (concl (S05_gen .virtualNode)),
  row0 "G05-S05" "b-meanParts" "generalise to Prokaryota" (concl (S05_gen .meanParts)),
  row0 "G05-S05" "b-minParts" "generalise to Prokaryota" (concl (S05_gen .minParts)),
  row "G05-S05" "b" human (notInG human prokaryote)]

/-! ## G05-S06 (synthetic). Coverage over a complement. Euglena and Paramecium (both in the imported
closure) generalised to protist: pruned bracketing gives 2/18, exactly bracketing at Eukaryota,
because the excluded clades sit below Eukaryota's own split (inside Opisthokonta and Viridiplantae).
Pruning only bites when a sample falls in a split that holds an excluded clade. -/

theorem S06_cov :
    UMeasure.meanParts.eval protist [euglena, paramecium] = 1/9 ∧
    Coverage.Measure.bracketing.eval Taxa.eukaryota [euglena, paramecium] = 1/9 := by decide +kernel
def S06_rows : List Row := [
  row0 "G05-S06" "c" "pruned bracketing, protist" s!"{UMeasure.meanParts.eval protist [euglena, paramecium]}",
  row0 "G05-S06" "a" "bracketing, Eukaryota" s!"{Coverage.Measure.bracketing.eval Taxa.eukaryota [euglena, paramecium]}"]

/-! ## G05-S07 (synthetic). Option e with a negative character: "prokaryote = cell without a nucleus"
(NCIT:C14263's definition). `Entity.refine` is `e ⊓ ∃r.f`, existential only, so the class cannot be
formed; BioLean can only state the negation about a named class (`notRel`, as round 2 does for
CL:0000520). -/
def S07_rows : List Row := [row0 "G05-S07" "e" "cell ⊓ ¬∃has_part.nucleus" "inexpressible: refine is existential only"]

/-! ## G05-S09 (synthetic). Is Schmidtea an invertebrate? The complement decides it from the lineage;
option f's open list is silent (`BioLean/Stress/GradeTerms.lean`). -/
theorem S09_member : invertebrate.mem schmidtea.curie = true := by decide
def S09_rows : List Row := [memRow "G05-S09" "c" invertebrate schmidtea]

/-! # Which `GDeriv` rules narrow which claims

The same check as in `BioLean/Stress/GradeTerms.lean`, on the prototype: `countSub` is the one rule
that narrows a count, and still no rule takes a `quant` premise (so option h stays silent). -/

open Lean Meta in
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
#eval show MetaM Unit from do
  let s ← ruleShapes ``GDeriv
  let countNarrowers := s.filterMap fun (c, ch, ps) =>
    if ch == some ``Claim.count && ps.any (·.1 == some ``Claim.count) && ps.any (·.2) then some c else none
  let quantTakers := s.filterMap fun (c, _, ps) => if ps.any (·.1 == some ``Claim.quant) then some c else none
  unless countNarrowers == [`countSub] && quantTakers == [] do
    throwError "GDeriv rules changed: count narrowers {countNarrowers}, quant takers {quantTakers}"
  IO.println "prototype: countSub is the only count-narrowing rule; no rule takes a quant premise"

/-! # All rows -/

def rows : List Row :=
  P01_rows ++ P02_rows ++ P09_rows ++ P10_rows ++ P11_rows ++ R01_rows ++ R02_rows ++ R03_rows ++ I01_rows ++
  F_rows ++ A04_rows ++ S01_rows ++ S04_rows ++ S05_rows ++ S06_rows ++ S07_rows ++ S09_rows

/-- Every checked silent row passed its check. -/
theorem rows_checked : (rows.filter (·.obs == "CHECK FAILED")).length = 0 := by decide +kernel
#guard rows.length = 74

#eval do
  for r in rows do
    IO.println s!"ROW\tProto.TaxonUnion\t{r.case}\t{r.option}\t{r.member}\t{r.obs}"

end BioLean.Proto.TaxonUnion
